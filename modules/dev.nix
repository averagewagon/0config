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

    # Git diagnostic aliases (credit: Ally Piechowski)
    # https://piechowski.io/post/git-commands-before-reading-code/
    (writeShellScriptBin ",git-churn" ''
      if [ "$1" = "--help" ]; then
        echo "Top 20 most-changed files in the last year."
        echo "Files that appear on both ,git-churn and ,git-bugs are highest-risk code:"
        exit 0
      fi
      git log --format=format: --name-only --since="1 year ago" | sort | uniq -c | sort -nr | head -20
    '')
    (writeShellScriptBin ",git-contributors" ''
      if [ "$1" = "--help" ]; then
        echo "Contributors ranked by commit count."
        exit 0
      fi
      git shortlog -sn --no-merges
    '')
    (writeShellScriptBin ",git-bugs" ''
      if [ "$1" = "--help" ]; then
        echo "Top 20 files most associated with bug-fix commits."
        echo "Files that appear on both ,git-churn and ,git-bugs are highest-risk code:"
        exit 0
      fi
      git log -i -E --grep="fix|bug|broken" --name-only --format="" | sort | uniq -c | sort -nr | head -20
    '')
    (writeShellScriptBin ",git-velocity" ''
      if [ "$1" = "--help" ]; then
        echo "Commit count by month over the full repo history."
        exit 0
      fi
      git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
    '')
    (writeShellScriptBin ",git-firefights" ''
      if [ "$1" = "--help" ]; then
        echo "Reverts, hotfixes, and rollbacks in the last year."
        exit 0
      fi
      git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
    '')
  ];

  programs.keychain = {
    enable = true;
    keys = [ "personal_key" ];
  };
}
