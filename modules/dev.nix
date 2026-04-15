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
      echo "Top 20 most-changed files in the last year. Optional: pass a string to filter by path."
      echo "Files that appear on both ,git-churn and ,git-bugs are highest-risk code."
      echo ""
      git log --format=format: --name-only --since="1 year ago" \
        | { [ -n "$1" ] && grep -F "$1" || cat; } \
        | sort | uniq -c | sort -nr | head -20
    '')
    (writeShellScriptBin ",git-contributors" ''
      echo "Contributors ranked by commit count."
      echo ""
      git shortlog -sn --no-merges
    '')
    (writeShellScriptBin ",git-bugs" ''
      echo "Top 20 files most associated with bug-fix commits. Optional: pass a string to filter by path."
      echo "Files that appear on both ,git-churn and ,git-bugs are highest-risk code."
      echo ""
      git log -i -E --grep="fix|bug|broken" --name-only --format="" \
        | { [ -n "$1" ] && grep -F "$1" || cat; } \
        | sort | uniq -c | sort -nr | head -20
    '')
    (writeShellScriptBin ",git-velocity" ''
      echo "Commit count by month over the full repo history."
      echo ""
      git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
    '')
    (writeShellScriptBin ",git-firefights" ''
      echo "Reverts, hotfixes, and rollbacks in the last year."
      echo ""
      git log --oneline --since="1 year ago" | grep -iE 'revert|hotfix|emergency|rollback'
    '')
  ];

  programs.keychain = {
    enable = true;
    keys = [ "personal_key" ];
  };
}
