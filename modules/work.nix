{
  pkgs,
  ...
}:

{
  programs.git.settings.user.email = "jonathan.hendrickson@bonsairobotics.ai";

  home.packages = with pkgs; [
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

  # Disable SELinux labeling for containers globally
  home.file.".config/containers/containers.conf".text = ''
    [containers]
    label = false
  '';

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
