{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    gnumake
    vcs2l
    (python3.withPackages (ps: with ps; [ pyyaml ]))
    awscli
    podman
    podman-compose
    (pkgs.writeShellScriptBin "docker" ''
      exec podman "$@"
    '')
    pixi
    gh
    graphviz # Visualizing `dot` graphs
    jira-cli-go # Jira CLI
  ];

  home.file = {
    # Disable SELinux labeling for containers globally
    ".config/containers/containers.conf".text = ''
      [containers]
      label = false
    '';

    # Docker build mounts ~/.gitconfig but Home Manager writes to ~/.config/git/config
    ".gitconfig".text = ''
      [include]
        path = ~/.config/git/config
    '';

    # Use personal git identity for 0config repo even on work machine
    ".config/git/config-0config".text = ''
      [user]
        name = Joni Hendrickson
        email = contact@joni.site
    '';
  };

  programs = {
    git = {
      settings.user.email = "jonathan.hendrickson@bonsairobotics.ai";
      includes = [
        {
          condition = "gitdir:~/0config/";
          path = "~/.config/git/config-0config";
        }
      ];
    };

    # SSH alias for pushing to personal GitHub repos from work machine
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."github.com" = {
        identityFile = "~/.ssh/work_key";
        identitiesOnly = true;
      };
      matchBlocks."github-personal" = {
        hostname = "github.com";
        identityFile = "~/.ssh/personal_key";
        identitiesOnly = true;
      };
    };
  };

  dconf.settings."org/gnome/shell" = {
    favorite-apps = [
      "io.gitlab.librewolf-community.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Ptyxis.desktop"
      "dev.zed.Zed.desktop"
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
