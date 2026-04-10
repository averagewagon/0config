{
  config,
  pkgs,
  lib,
  nixgl,
  ...
}:

{
  home.username = "jhen";
  home.homeDirectory = "/var/home/jhen";
  home.stateVersion = "25.11"; # Don't change without reading HM release notes

  programs.home-manager.enable = true;

  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
    vulkan.enable = true;
  };

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

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Joni Hendrickson";
        email = "contact@joni.site";
      };
      init.defaultBranch = "main";
    };
  };

  # GUI text editor
  programs.zed-editor = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.zed-editor;
    extensions = [
      "nix"
      "catppuccin-icons"
      "git-firefly"
    ];
    userSettings = {
      agent = {
        use_modifier_to_send = false;
        play_sound_when_agent_done = true;
      };
      collaboration_panel = {
        button = false;
      };
      agent_servers = {
        claude-acp = {
          type = "registry";
        };
      };
      extend_comment_on_newline = false;
      icon_theme = "Catppuccin Frappé";
      theme = "Gruvbox Dark Hard";
      buffer_font_features = {
        calt = false;
      };
      lsp = {
        rust-analyzer = {
          initialization_options = {
            cargo = {
              features = "all";
            };
          };
        };
      };
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

  # Add new machines here when I'm done configuring them and update other configs
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        # Phone (introducer, since its config isn't managed by Nix anyways)
        ginger = {
          id = "ROA5SZQ-OA33NRK-2NNBO5R-QVVW3FQ-DBFUWP6-XTQ4UKJ-M2D66T6-UAFPFAQ";
          introducer = true;
        };

        # DigitalOcean server
        sumac.id = "AY7LJTM-F5BRYPE-FDCXAGE-AJLP7TU-JW3PRMX-L6HX754-CK3MUGZ-KLEJWAB";

        # Laptop
        saffron.id = "T2F7ICT-EMNBQH6-TBDQ4DE-7X7J57J-QCGWIS2-VXBN4HB-LRGNZUZ-AFI5IQF";
      };
      folders."~/0everything" = {
        id = "0everything";
        devices = [
          "ginger"
          "sumac"
          "saffron"
        ];
      };
    };
  };

  # Generally, prefer Flatpak for isolated GUI apps, since it has some sandboxing
  services.flatpak = {
    enable = true;
    update = {
      auto.enable = true;
      onActivation = true;
    };
    packages = [
      {
        # Preferred browser (Firefox fork)
        appId = "io.gitlab.librewolf-community";
        origin = "flathub";
      }
      {
        # Keep Chromium around for the odd Firefox-incompatible website
        appId = "org.chromium.Chromium";
        origin = "flathub";
      }
      {
        # Password manager
        appId = "com.bitwarden.desktop";
        origin = "flathub";
      }
      {
        # Notes app - proprietary ;_;
        appId = "md.obsidian.Obsidian";
        origin = "flathub";
      }
      {
        # Chat app - Matrix client
        appId = "im.fluffychat.Fluffychat";
        origin = "flathub";
      }
      {
        # Chat app - Signal desktop
        appId = "org.signal.Signal";
        origin = "flathub";
      }
      {
        # Chat app - proprietary ;_;
        appId = "com.discordapp.Discord";
        origin = "flathub";
      }
      {
        # Pleasant e-reader
        appId = "com.github.johnfactotum.Foliate";
        origin = "flathub";
      }
      {
        # Office suite
        appId = "org.libreoffice.LibreOffice";
        origin = "flathub";
      }
      {
        # Streaming service aggregator
        appId = "com.stremio.Stremio";
        origin = "flathub";
      }
      {
        # Video player
        appId = "io.mpv.Mpv";
        origin = "flathub";
      }
      {
        # Flashcards
        appId = "net.ankiweb.Anki";
        origin = "flathub";
      }
      {
        # Basic image editing
        appId = "com.github.PintaProject.Pinta";
        origin = "flathub";
      }
    ];
    overrides = {
      # Librewolf needs camera access for video calls
      "io.gitlab.librewolf-community".Context.devices = [ "all" ];
      # Use GNOME keyring instead of plaintext password store
      "org.signal.Signal".Environment.SIGNAL_PASSWORD_STORE = "gnome-libsecret";
    };
  };
}
