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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-flatpak,
      nixgl,
      treefmt-nix,
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

      treefmtEval =
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.prettier.enable = true;
        };
    in
    {
      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system: (treefmtEval system).config.build.wrapper
      );

      homeConfigurations = {
        "laptop" = mkHome {
          modules = [
            ./modules/base.nix
            ./modules/dev.nix
            ./modules/syncthing.nix
            ./modules/graphical.nix
            ./modules/personal.nix
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
        };
        "work" = mkHome {
          modules = [
            ./modules/base.nix
            ./modules/dev.nix
            ./modules/graphical.nix
            ./modules/work.nix
            nix-flatpak.homeManagerModules.nix-flatpak
          ];
        };
        "server" = mkHome {
          modules = [
            ./modules/base.nix
            ./modules/dev.nix
            ./modules/syncthing.nix
            { home.homeDirectory = "/home/jhen"; }
          ];
        };
        "webserver" = mkHome {
          modules = [
            ./modules/base.nix
            ./modules/webserver.nix
            { home.homeDirectory = "/home/jhen"; }
          ];
        };
        "phone" = mkHome {
          system = "aarch64-linux";
          modules = [
            ./modules/base.nix
            ./modules/dev.nix
            {
              home.username = "droid";
              home.homeDirectory = "/home/droid";
            }
          ];
        };
      };
    };
}
