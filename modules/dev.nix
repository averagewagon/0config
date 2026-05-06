{
  pkgs,
  ...
}:

{
  # Documentation
  programs.man = {
    enable = true;
    generateCaches = true;
  };
  programs.info.enable = true;

  home.packages = with pkgs; [
    nil # Nix language server
    nixd # Other Nix language server
    nixfmt # Official RFC 166 Nix formatter
    nix.man # Manpages for nix, nix-shell, nix.conf, etc.
    statix # Nix linter
    prettier # Markdown/JSON/YAML/etc formatter
    distrobox # Virtual machines for dev
    jq # JSON processor

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
      echo "Contributors ranked by commit count. Optional: pass a date to filter, e.g. '2026-01-01', and/or a path."
      echo ""
      args=(-sn --no-merges)
      [ -n "''${1:-}" ] && args+=(--since="$1")
      if [ -n "''${2:-}" ]; then
        git shortlog "''${args[@]}" HEAD -- "$2"
      else
        git shortlog "''${args[@]}" HEAD
      fi
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
      echo "Commit count by month. Optional: pass a date to limit history, e.g. '2025-01-01'."
      echo ""
      if [ -n "$1" ]; then
        git log --since="$1" --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
      else
        git log --format='%ad' --date=format:'%Y-%m' | sort | uniq -c
      fi
    '')
    (writeShellScriptBin ",git-firefights" ''
      echo "Reverts, hotfixes, and rollbacks. Optional: pass a date (default: 1 year ago) and/or a path."
      echo ""
      since=''${1:-1 year ago}
      if [ -n "''${2:-}" ]; then
        git log --oneline --since="$since" -- "$2"
      else
        git log --oneline --since="$since"
      fi | grep -iE 'revert|hotfix|emergency|rollback'
    '')

    (writeShellScriptBin ",git-file-churn" ''
      echo "Stats for a single file: commits, distinct authors, first/last touched, commits/month."
      echo "Use to assess how active or stable a file is over time."
      echo ""
      [ $# -eq 1 ] || { echo "usage: ,git-file-churn <path>" >&2; exit 1; }
      path=$1
      commits=$(git log --follow --format=%H -- "$path" | wc -l)
      if [ "$commits" -eq 0 ]; then
        echo "no commits touching $path"
        exit 0
      fi
      authors=$(git log --follow --format=%aN -- "$path" | sort -u | wc -l)
      first=$(git log --follow --format=%ad --date=short --reverse -- "$path" | head -1)
      last=$(git log --follow --format=%ad --date=short -- "$path" | head -1)
      months=$(( ( $(date -d "$last" +%s) - $(date -d "$first" +%s) ) / 2629800 + 1 ))
      rate=$(awk -v c="$commits" -v m="$months" 'BEGIN { printf "%.2f", c/m }')
      printf "commits:        %s\n" "$commits"
      printf "authors:        %s\n" "$authors"
      printf "first touched:  %s\n" "$first"
      printf "last touched:   %s\n" "$last"
      printf "commits/month:  %s\n" "$rate"
    '')

    (writeShellScriptBin ",git-file-cochange" ''
      echo "Top 20 files most often committed alongside the given file."
      echo "Files high on this list often share concerns or get touched together for the same reason."
      echo ""
      [ $# -eq 1 ] || { echo "usage: ,git-file-cochange <path>" >&2; exit 1; }
      path=$1
      shas=$(git log --follow --format=%H -- "$path")
      [ -n "$shas" ] || { echo "no commits touching $path"; exit 0; }
      echo "$shas" \
        | xargs -n 50 git show --name-only --format= \
        | grep -v '^$' \
        | grep -vFx "$path" \
        | sort | uniq -c | sort -nr | head -20
    '')

    (writeShellScriptBin ",git-file-recent" ''
      echo "Last N commits touching the file (default 20). Shows date, sha, author, subject."
      echo ""
      [ $# -ge 1 ] || { echo "usage: ,git-file-recent <path> [n]" >&2; exit 1; }
      path=$1
      n=''${2:-20}
      git log --follow --date=short --pretty=format:'%ad %h %an: %s' -n "$n" -- "$path"
      echo ""
    '')

    (writeShellScriptBin ",git-line-log" ''
      echo "Commit history for specific lines in a file (one line per commit, no diff)."
      echo "Useful for spotting whether a region is stable, recently rewritten, or thrashed."
      echo ""
      [ $# -eq 2 ] || { echo "usage: ,git-line-log <path> <start>[:<end>]" >&2; exit 1; }
      path=$1
      range=$2
      case "$range" in
        *:*) start=''${range%:*}; end=''${range#*:} ;;
        *)   start=$range; end=$range ;;
      esac
      git log -L "$start,$end:$path" --date=short --pretty=format:'%ad %h %an: %s' -s
      echo ""
    '')

    (writeShellScriptBin ",git-line-blame" ''
      echo "Blame summary: % of lines per author and median line age. Optional line range."
      echo "Old + concentrated lines are stable; young + scattered lines are in flux."
      echo ""
      [ $# -ge 1 ] || { echo "usage: ,git-line-blame <path> [start[:end]]" >&2; exit 1; }
      path=$1
      range_args=()
      if [ $# -ge 2 ]; then
        range=$2
        case "$range" in
          *:*) start=''${range%:*}; end=''${range#*:} ;;
          *)   start=$range; end=$range ;;
        esac
        range_args=(-L "$start,$end")
      fi
      blame=$(git blame --line-porcelain "''${range_args[@]}" -- "$path")
      [ -n "$blame" ] || { echo "no blame output for $path"; exit 0; }
      echo "$blame" | awk '
        /^author / { author = substr($0, 8) }
        /^author-time / { by_author[author]++; total++ }
        END { for (a in by_author) printf "%6.1f%%  %s\n", 100*by_author[a]/total, a }
      ' | sort -nr
      echo ""
      echo "$blame" | awk '/^author-time / { print $2 }' | sort -n \
        | awk -v now="$(date +%s)" '
          { a[NR]=$1 }
          END {
            if (NR == 0) exit
            m = (NR % 2) ? a[(NR+1)/2] : (a[NR/2]+a[NR/2+1])/2
            days = int((now - m) / 86400)
            printf "median line age: %d days\n", days
          }'
    '')

    # Conventional Commits cheatsheet
    (writeShellScriptBin ",coco" ''
      echo "feat! fix! build chore ci docs style refactor perf test | todo"
    '')

    # Update DNS records on DNSimple
    (writeShellScriptBin ",dnsimple-set" ''
      set -euo pipefail

      echo "Idempotent DNS upsert at DNSimple. Args: <zone> <name> <type> <content>."
      echo "Reads DNSIMPLE_TOKEN and DNSIMPLE_ACCOUNT_ID from env, prompts if unset."
      echo ""

      [ $# -eq 4 ] || { echo "usage: ,dnsimple-set <zone> <name> <type> <content>" >&2; exit 1; }
      zone=$1 name=$2 type=$3 content=$4

      [ -n "''${DNSIMPLE_TOKEN:-}" ] || { read -rsp "DNSimple API token: " DNSIMPLE_TOKEN; echo; }
      [ -n "''${DNSIMPLE_ACCOUNT_ID:-}" ] || read -rp "DNSimple account ID: " DNSIMPLE_ACCOUNT_ID

      api="https://api.dnsimple.com/v2/$DNSIMPLE_ACCOUNT_ID/zones/$zone/records"
      auth="Authorization: Bearer $DNSIMPLE_TOKEN"
      ac="Accept: application/json"
      ct="Content-Type: application/json"

      matches=$(curl -fsS -H "$auth" -H "$ac" "$api?type=$type" \
        | jq -c --arg n "$name" --arg t "$type" \
            '[.data[] | select(.name == $n and .type == $t)]')
      count=$(echo "$matches" | jq 'length')

      if [ "$count" -gt 1 ]; then
        echo "ERROR: $count $type records found for name='$name' in $zone, refusing to guess" >&2
        echo "$matches" | jq -r '.[] | "  id=\(.id) content=\(.content)"' >&2
        exit 1
      fi

      body=$(jq -nc --arg n "$name" --arg t "$type" --arg c "$content" '{name:$n,type:$t,content:$c}')
      fqdn=''${name:+$name.}$zone

      if [ "$count" -eq 1 ]; then
        id=$(echo "$matches" | jq -r '.[0].id')
        curl -fsS -X PATCH -H "$auth" -H "$ac" -H "$ct" -d "$body" "$api/$id" >/dev/null
        echo "updated $type $fqdn -> $content"
      else
        curl -fsS -X POST -H "$auth" -H "$ac" -H "$ct" -d "$body" "$api" >/dev/null
        echo "created $type $fqdn -> $content"
      fi
    '')
  ];

  home.file.".prettierrc.yaml".text = ''
    proseWrap: always
    printWidth: 100
  '';
}
