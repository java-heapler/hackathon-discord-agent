#!/usr/bin/env bash
# board.sh - tiny shared task board for a small team. Plain files, bash + awk only.
#
#   board.sh new   "<title>" [-f path1,path2] [-a "acceptance"]
#   board.sh claim T-001 <owner>         atomic claim + exclusive file leases
#   board.sh note  T-001 <owner> "<handoff note>"
#   board.sh done  T-001 <owner> "<evidence>"   evidence is required
#   board.sh release T-001 <owner>       give the task back (todo), free leases
#   board.sh show  T-001
#   board.sh list
#
# State lives in $BOARD (default ./board). Claims use `mkdir`, which the OS
# guarantees has exactly one winner, so two people claiming at once cannot both win.
set -euo pipefail

B="${BOARD:-board}"
T="$B/tasks"; L="$B/locks"; I="$B/ids"
mkdir -p "$T" "$L/files" "$I"

die() { echo "board: $*" >&2; exit 1; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
path_of() { [ -f "$T/$1.md" ] || die "no task $1"; echo "$T/$1.md"; }

get() { # file key
  awk -v k="$2" 'index($0, k": ")==1 { print substr($0, length(k)+3); exit }' "$1"
}
put() { # file key value  (rewrite one "key: value" line, atomic via rename)
  awk -v k="$2" -v v="$3" 'index($0, k": ")==1 { print k": "v; next } { print }' "$1" > "$1.tmp.$$" \
    && mv "$1.tmp.$$" "$1"
}
touch_updated() { put "$1" updated "$(now)"; }
lease_name() { echo "$1" | tr '/' '_'; }

cmd="${1:-list}"; shift || true

case "$cmd" in
new)
  title="${1:-}"; [ -n "$title" ] || die 'usage: new "<title>" [-f files] [-a acceptance]'
  shift
  files=""; acceptance=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -f) files="${2:-}"; shift 2 ;;
      -a) acceptance="${2:-}"; shift 2 ;;
      *) die "unknown option $1" ;;
    esac
  done
  n=1
  until mkdir "$I/$n" 2>/dev/null; do n=$((n + 1)); done   # atomic id allocation
  id=$(printf 'T-%03d' "$n")
  {
    echo "id: $id"
    echo "title: $title"
    echo "status: todo"
    echo "owner: "
    echo "files: $files"
    echo "acceptance: $acceptance"
    echo "evidence: "
    echo "updated: $(now)"
    echo "---"
  } > "$T/$id.md"
  echo "$id"
  ;;

claim)
  id="${1:-}"; owner="${2:-}"; [ -n "$id" ] && [ -n "$owner" ] || die "usage: claim T-NNN <owner>"
  f=$(path_of "$id")
  [ "$(get "$f" status)" = "todo" ] || die "$id is $(get "$f" status), not todo"
  mkdir "$L/$id.claim" 2>/dev/null || die "$id was just claimed by someone else"
  taken=()
  IFS=',' read -r -a flist <<< "$(get "$f" files)"
  for p in "${flist[@]:-}"; do
    p="${p// /}"; [ -n "$p" ] || continue
    if mkdir "$L/files/$(lease_name "$p")" 2>/dev/null; then
      echo "$id $owner" > "$L/files/$(lease_name "$p")/owner"; taken+=("$p")
    else
      holder=$(cat "$L/files/$(lease_name "$p")/owner" 2>/dev/null || echo "someone")
      for q in "${taken[@]:-}"; do [ -n "$q" ] && rm -rf "$L/files/$(lease_name "$q")"; done
      rmdir "$L/$id.claim" 2>/dev/null || true
      die "file $p is leased by $holder; claim rolled back"
    fi
  done
  echo "$owner" > "$L/$id.claim/owner"
  put "$f" status doing; put "$f" owner "$owner"; touch_updated "$f"
  echo "$id claimed by $owner"
  ;;

note)
  id="${1:-}"; owner="${2:-}"; text="${3:-}"; [ -n "$text" ] || die 'usage: note T-NNN <owner> "<note>"'
  f=$(path_of "$id")
  echo "- $(now) $owner: $text" >> "$f"; touch_updated "$f"
  echo "noted on $id"
  ;;

done)
  id="${1:-}"; owner="${2:-}"; evidence="${3:-}"
  [ -n "$evidence" ] || die 'done needs evidence, e.g. "pytest 12 passed; sha abc123"'
  f=$(path_of "$id")
  [ "$(get "$f" owner)" = "$owner" ] || die "$id is owned by $(get "$f" owner), not $owner"
  put "$f" status done; put "$f" evidence "$evidence"; touch_updated "$f"
  for p in $(get "$f" files | tr ',' ' '); do rm -rf "$L/files/$(lease_name "$p")"; done
  echo "$id done"
  ;;

release)
  id="${1:-}"; owner="${2:-}"
  f=$(path_of "$id")
  [ "$(get "$f" owner)" = "$owner" ] || die "$id is owned by $(get "$f" owner), not $owner"
  put "$f" status todo; put "$f" owner ""; touch_updated "$f"
  rm -rf "$L/$id.claim"
  for p in $(get "$f" files | tr ',' ' '); do rm -rf "$L/files/$(lease_name "$p")"; done
  echo "$id released"
  ;;

show)
  cat "$(path_of "${1:-}")"
  ;;

list)
  printf '%-7s %-8s %-10s %s\n' ID STATUS OWNER TITLE
  for f in "$T"/T-*.md; do
    [ -f "$f" ] || continue
    printf '%-7s %-8s %-10s %s\n' "$(get "$f" id)" "$(get "$f" status)" "$(get "$f" owner)" "$(get "$f" title)"
  done
  ;;

*) die "unknown command '$cmd' (new|claim|note|done|release|show|list)" ;;
esac
