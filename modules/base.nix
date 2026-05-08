{
  pkgs,
  lib,
  config,
  ...
}:

{
  config = {
    home.username = lib.mkDefault "jhen";
    home.homeDirectory = lib.mkDefault "/var/home/jhen";
    home.stateVersion = "25.11"; # Don't change without reading HM release notes

    news.display = "silent";

    programs.home-manager.enable = true;

    nix = {
      package = pkgs.nix;
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    nixpkgs.config.allowUnfreePredicate =
      pkg: builtins.elem (lib.getName pkg) config.allowedUnfreePackages;

    home.packages = with pkgs; [
      micro # Lightweight text editor
      bat # cat with highlighting
      htop # View running processes
      nix-your-shell # Make nix-shell/nix develop launch fish instead of bash
    ];

    programs = {
      neovim = {
        enable = true;
        defaultEditor = true;
        withRuby = false;
        withPython3 = false;
      };

      delta = {
        enable = true;
        enableGitIntegration = true;
        options.line-numbers = true;
      };

      git = {
        enable = true;
        lfs.enable = true;
        settings = {
          user = {
            name = lib.mkDefault "Joni Hendrickson";
            email = lib.mkDefault "contact@joni.site";
          };
          init.defaultBranch = "main";
          core.editor = "nvim";
        };
      };

      # Shell configuration with fish
      fish = {
        enable = true;
        generateCompletions = true;
        interactiveShellInit = ''
          fish_config theme choose base16-default
          fish_config prompt choose default
          # Make `nix develop` / `nix shell` launch fish instead of bash
          nix-your-shell fish | source
          # Prefix the prompt with "(nix)" when in a nix shell
          functions -c fish_prompt _default_fish_prompt
          function fish_prompt
            if set -q IN_NIX_SHELL
              set_color blue
              echo -n "(nix) "
              set_color normal
            end
            _default_fish_prompt
          end
          # Force nvim as editor
          set -gx EDITOR nvim
          set -gx VISUAL nvim
          # Colorful man pages in less
          set -gx GROFF_NO_SGR 1
          set -gx LESS_TERMCAP_mb (set_color -o red)
          set -gx LESS_TERMCAP_md (set_color -o cyan)
          set -gx LESS_TERMCAP_me (set_color normal)
          set -gx LESS_TERMCAP_se (set_color normal)
          set -gx LESS_TERMCAP_so (set_color -b white black)
          set -gx LESS_TERMCAP_ue (set_color normal)
          set -gx LESS_TERMCAP_us (set_color -o green)
        '';
      };

      # Bash stays as login shell; fish is launched for interactive sessions
      bash = {
        enable = true;
        initExtra = ''
          if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
        '';
      };
    };
  };

  # Unfree package allowlist. Each module can extend allowedUnfreePackages with
  # its own entries; the predicate here merges them all into a single check.
  # Have to do this to allow each module to define its own allowlist of
  # unfree packages without overwriting each other
  options.allowedUnfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
}
