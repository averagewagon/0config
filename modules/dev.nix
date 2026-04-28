{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nil # Nix language server
    nixd # Other Nix language server
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
      echo "Contributors ranked by commit count. Optional: pass a date to filter, e.g. '2026-01-01'."
      echo ""
      if [ -n "$1" ]; then
        git shortlog -sn --no-merges --since="$1"
      else
        git shortlog -sn --no-merges
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
      echo "Reverts, hotfixes, and rollbacks. Optional: pass a date, e.g. '2026-01-01' (default: 1 year ago)."
      echo ""
      git log --oneline --since="''${1:-1 year ago}" | grep -iE 'revert|hotfix|emergency|rollback'
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
