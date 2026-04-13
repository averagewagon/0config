{
  pkgs,
  ...
}:

{
  programs.git.settings.user.email = "jonathan.hendrickson@bonsairobotics.ai";

  allowedUnfreePackages = [ "foxglove-studio" ];

  home.packages = with pkgs; [
    distrobox
    gnumake
    vcs2l
    (python3.withPackages (ps: with ps; [ pyyaml ]))
    awscli
    podman
    podman-compose
    (pkgs.writeShellScriptBin "docker" ''
      exec podman "$@"
    '')
    foxglove-studio
    pixi
  ];

  # Disable SELinux labeling for containers globally
  home.file.".config/containers/containers.conf".text = ''
    [containers]
    label = false
  '';

  # SSH alias for pushing to personal GitHub repos from work machine
  programs.ssh = {
    enable = true;
    matchBlocks."github-personal" = {
      hostname = "github.com";
      identityFile = "~/.ssh/personal_key";
      identitiesOnly = true;
    };
  };

  # Use personal git identity for 0config repo even on work machine
  home.file.".config/git/config-0config".text = ''
    [user]
      name = Joni Hendrickson
      email = contact@joni.site
  '';
  programs.git.settings.includeIf."gitdir:~/0config/" = {
    path = "~/.config/git/config-0config";
  };

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
