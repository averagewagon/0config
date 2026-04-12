{
  ...
}:

{
  programs.git.settings.user.email = "jonathan.hendrickson@bonsairobotics.ai";

  dconf.settings."org/gnome/shell" = {
    favorite-apps = [
      "io.gitlab.librewolf-community.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Ptyxis.desktop"
      "dev.zed.Zed.desktop"
      "com.bitwarden.desktop.desktop"
      "md.obsidian.Obsidian.desktop"
      "com.slack.Slack.desktop"
    ];
  };

  services.flatpak.packages = [
    {
      appId = "com.slack.Slack";
      origin = "flathub";
    }
  ];
}
