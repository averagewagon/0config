{ config, pkgs,  ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jhen";
  home.homeDirectory = "/var/home/jhen";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  #JHM Enable vulkan
  nixGL.vulkan.enable = true;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

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
    # zed-editor
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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jhen/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  #JHM Fish shell stuff

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
        { appId = "com.bitwarden.desktop"; origin = "flathub"; }
        { appId = "io.gitlab.librewolf-community"; origin = "flathub"; }
        { appId = "org.chromium.Chromium"; origin = "flathub"; }
        { appId = "md.obsidian.Obsidian"; origin = "flathub"; }
        { appId = "dev.zed.Zed"; origin = "flathub"; }
    ];

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
        name  = "Joni Hendrickson";
        #JHM TODO: Make a way to override this per-machine with
        # a config specific to work or personal
        email = "jonathan.hendrickson@bonsairobotics.ai";
      };
      init.defaultBranch = "main";
    };
  };
}
