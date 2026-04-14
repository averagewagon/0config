{
  pkgs,
  ...
}:

{
  allowedUnfreePackages = [ "claude-code" ];

  home.packages = with pkgs; [
    nil # Nix language server
    nixd # Nix language server
    claude-code # Proprietary AI coding agent ;_;
  ];

  programs.keychain = {
    enable = true;
    keys = [ "personal_key" ];
  };
}
