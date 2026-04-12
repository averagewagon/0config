{
  description = "Home Manager configuration of jhen";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-flatpak,
      nixgl,
      ...
    }:
    let
      mkHome =
        {
          system ? "x86_64-linux",
          modules,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit nixgl; };
          inherit modules;
        };
    in
    {
      homeConfigurations = {
        "desktop" = mkHome {
          modules = [
            ./modules/base.nix
            ./modules/syncthing.nix
            ./modules/graphical.nix
            ./modules/personal.nix
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
        };
        "work" = mkHome {
          modules = [
            ./modules/base.nix
            ./modules/graphical.nix
            ./modules/work.nix
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
        };
        "server" = mkHome {
          modules = [
            ./modules/base.nix
            ./modules/syncthing.nix
          ];
        };
        "phone" = mkHome {
          system = "aarch64-linux";
          modules = [
            ./modules/base.nix
            {
              home.username = "droid";
              home.homeDirectory = "/home/droid";
            }
          ];
        };
      };
    };
}
