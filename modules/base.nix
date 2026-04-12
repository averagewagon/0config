{
  pkgs,
  lib,
  ...
}:

{
  home.username = lib.mkDefault "jhen";
  home.homeDirectory = lib.mkDefault "/var/home/jhen";
  home.stateVersion = "25.11"; # Don't change without reading HM release notes

  programs.home-manager.enable = true;

  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Any unfree ;_; packages have to be specified here
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  home.packages = with pkgs; [
    micro # Lightweight text editor
    nil # Nix language server
    nixd # Nix language server
    claude-code # Proprietary AI coding agent ;_;
  ];

  programs.keychain = {
    enable = true;
    keys = [ "personal_key" ];
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = lib.mkDefault "Joni Hendrickson";
        email = lib.mkDefault "contact@joni.site";
      };
      init.defaultBranch = "main";
    };
  };

  # Shell configuration with fish
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_config theme choose base16-default
      fish_config prompt choose default
    '';
  };

  # Bash stays as login shell; fish is launched for interactive sessions
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };
}
