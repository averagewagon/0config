{
  config,
  pkgs,
  nixgl,
  ...
}:

{
  # Needed to wrap anything GPU-accelerated, e.g. Zed, Subsurface
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
    vulkan.enable = true;
  };

  # Consistent cursor across GTK and Qt apps on Wayland
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  # Qt app theming - use Adwaita Dark to match GNOME dark mode
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  home.packages = with pkgs; [
    adwaita-qt # Adwaita theme for Qt5 apps
    adwaita-qt6 # Adwaita theme for Qt6 apps
  ];

  # GUI text editor
  programs.zed-editor = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.zed-editor;
    extensions = [
      "nix"
      "catppuccin-icons"
      "git-firefly"
      "TOML"
      "Dockerfile"
      "xml"
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

  # GNOME Extensions
  programs.gnome-shell = {
    enable = true;
    extensions = [
      { package = pkgs.gnomeExtensions.dash-to-dock; } # Mouseover dock on the bottom of the screen
      { package = pkgs.gnomeExtensions.clipboard-indicator; } # Clipboard history
      { package = pkgs.gnomeExtensions.vitals; } # System resource usage
    ];
  };

  # Configuring GNOME
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/background" = {
        picture-uri = "file:///var/home/jhen/0everything/0media/images/backgrounds/space-background-contrast.png";
        picture-uri-dark = "file:///var/home/jhen/0everything/0media/images/backgrounds/space-background-contrast.png";
        picture-options = "zoom";
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        show-battery-percentage = true;
      };
      "org/gnome/desktop/privacy" = {
        report-technical-problems = false;
      };
      "org/gnome/system/location" = {
        enabled = true;
      };
      # favorite-apps is set per-profile (personal.nix, work.nix)
      "org/gnome/shell/extensions/dash-to-dock" = {
        show-icons-notifications-counter = false;
        show-dock-urgent-notify = false;
        dock-fixed = false;
        autohide = true;
        intellihide = false;
      };
      "org/gnome/shell/extensions/vitals" = {
        icon-style = 1;
        show-battery = true;
        storage-path = "/var/home";
        hot-sensors = [
          "_processor_usage_"
          "_memory_usage_"
          "_storage_used_"
          "__network-rx_max__"
        ];
      };
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = false;
        night-light-schedule-from = 20.0;
        night-light-schedule-to = 4.0;
      };
    };
  };

  # Configuring default GNOME applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Librewolf as default browser
      "text/html" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/http" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/https" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/about" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/unknown" = "io.gitlab.librewolf-community.desktop";
      "application/xhtml+xml" = "io.gitlab.librewolf-community.desktop";

      # mpv for video/audio
      "video/mp4" = "io.mpv.Mpv.desktop";
      "video/x-matroska" = "io.mpv.Mpv.desktop";
      "video/webm" = "io.mpv.Mpv.desktop";
      "audio/mpeg" = "io.mpv.Mpv.desktop";
      "audio/flac" = "io.mpv.Mpv.desktop";
      "audio/ogg" = "io.mpv.Mpv.desktop";

      # Foliate for ebooks
      "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";

      # Loupe for images
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
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
        # Video player
        appId = "io.mpv.Mpv";
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
    };
  };
}
