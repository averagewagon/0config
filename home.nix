{
  config,
  pkgs,
  lib,
  ...
}:

{

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jhen";
  home.homeDirectory = "/var/home/jhen";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes. You should not change this
  # value, even if you update Home Manager. If you do want to update the value,
  # then make sure to first check the Home Manager release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  #JHM TODO: Enable vulkan for fixing zed
  # nixGL.vulkan.enable = true;

  #JHM Needed for distrobox to use experimental features
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  #JHM Unfree packages
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    #JHM My installed packages through Home Manager itself
    micro

    #JHM Language server for Nix
    nil
    nixd

    #JHM unfree packages
    claude-code

    #JHM wthings
    distrobox
    gnumake
    vcstool
    (python3.withPackages (ps: with ps; [ pyyaml ]))
    awscli
    podman
    podman-compose
    (pkgs.writeShellScriptBin "docker" ''
      exec podman "$@"
    '')

  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  #JHM Config required to disable SELinux labeling for containers globally
  # Removes SELinux isolation for my containers, but should also fix some
  # build perms issues, maybe
  home.file.".config/containers/containers.conf".text = ''
    [containers]
    label = false
  '';

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  #JHM Zed stuff
  # programs.zed-editor = {
  # enable = true;
  # extensions = [ "nix" "toml" "rust" ];
  # userSettings = {
  #   theme = {
  #     mode = "system";
  #     dark = "One Dark";
  #     light = "One Light";
  #   };
  # };
  # };

  #JHM Managing flatpak packages
  services.flatpak = {
    enable = true;

    packages = [
      {
        appId = "io.gitlab.librewolf-community";
        origin = "flathub";
      }
      {
        appId = "com.bitwarden.desktop";
        origin = "flathub";
      }
      {
        appId = "org.chromium.Chromium";
        origin = "flathub";
      }
      {
        appId = "md.obsidian.Obsidian";
        origin = "flathub";
      }
      {
        appId = "dev.zed.Zed";
        origin = "flathub";
      }
      {
        appId = "com.slack.Slack";
        origin = "flathub";
      }
    ];

    #JHM Grant Librewolf camera access
    overrides = {
      "io.gitlab.librewolf-community".Context = {
        devices = [ "all" ];
      };
    };

    #JHM Enabling auto-updates for flatpaks
    update = {
      auto.enable = true;
      onActivation = true;
    };
  };

  #JHM Managing Git
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Joni Hendrickson";
        #JHM TODO: Make a way to override this per-machine with
        # a config specific to work or personal
        email = "jonathan.hendrickson@bonsairobotics.ai";
      };
      init.defaultBranch = "main";
    };
  };

  #JHM Launches fish for interactive bash sessions, keeping bash as login shell
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

  #JHM Fish config
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_config theme choose base16-default
      fish_config prompt choose default
    '';
  };
}
