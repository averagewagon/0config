{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    (config.lib.nixGL.wrap subsurface) # Dive log software
  ];

  dconf.settings."org/gnome/shell" = {
    favorite-apps = [
      "io.gitlab.librewolf-community.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Ptyxis.desktop"
      "dev.zed.Zed.desktop"
      "im.fluffychat.Fluffychat.desktop"
      "org.signal.Signal.desktop"
      "com.discordapp.Discord.desktop"
      "com.stremio.Stremio.desktop"
      "net.ankiweb.Anki.desktop"
      "subsurface.desktop"
      "com.bitwarden.desktop.desktop"
      "md.obsidian.Obsidian.desktop"
    ];
  };

  services.flatpak.packages = [
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
      # Streaming service aggregator
      appId = "com.stremio.Stremio";
      origin = "flathub";
    }
    {
      # Flashcards
      appId = "net.ankiweb.Anki";
      origin = "flathub";
    }
  ];

  services.flatpak.overrides = {
    # Use GNOME keyring instead of plaintext password store
    "org.signal.Signal".Environment.SIGNAL_PASSWORD_STORE = "gnome-libsecret";
  };
}
