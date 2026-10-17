#!/usr/bin/env bash
# Self-check for board.sh: ids, claim races, file leases, evidence rule, release.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
export BOARD; BOARD="$(mktemp -d)"
trap 'rm -rf "$BOARD"' EXIT
b="$here/board.sh"
ok() { echo "ok - $1"; }
fail() { echo "FAIL - $1" >&2; exit 1; }

[ "$("$b" new "Login page" -f src/login.ts -a "page loads")" = "T-001" ] || fail "first id"
[ "$("$b" new "API route" -f src/api.ts)" = "T-002" ] || fail "second id"
ok "ids allocate in order"

# 6 people claim T-001 at once: exactly one must win
wins=0
for who in a b c d e f; do ("$b" claim T-001 "$who" >/dev/null 2>&1 && echo won >"$BOARD/win.$who") & done
wait
wins=$(ls "$BOARD"/win.* 2>/dev/null | wc -l | tr -d ' ')
[ "$wins" = "1" ] || fail "expected exactly 1 winner, got $wins"
ok "exactly one concurrent claim wins"

# a task whose file is leased cannot be claimed
"$b" new "Also login" -f src/login.ts >/dev/null          # T-003 needs the leased file
if "$b" claim T-003 zed >/dev/null 2>&1; then fail "claimed a leased file"; fi
[ "$("$b" list | grep -c ' todo ')" -ge 2 ] || fail "failed claim must leave task todo"
ok "file lease blocks overlapping claim and rolls back"

owner=$(ls "$BOARD"/win.* | sed 's/.*win\.//')
if "$b" done T-001 "$owner" "" >/dev/null 2>&1; then fail "done without evidence"; fi
if "$b" done T-001 nobody "tests pass" >/dev/null 2>&1; then fail "done by non-owner"; fi
"$b" done T-001 "$owner" "tests pass; sha abc123" >/dev/null
"$b" claim T-003 zed >/dev/null || fail "lease should be free after done"
ok "done needs evidence + owner, and frees the lease"

"$b" release T-003 zed >/dev/null
"$b" list | grep -q 'T-003 *todo' || fail "release returns to todo"
ok "release works"
echo "all board checks passed"
