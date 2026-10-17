---
name: team-board
description: The shared task board (scripts/board.sh) for a small team plus the agent - create tasks, claim them atomically with file leases, leave handoff notes and close tasks with evidence. Use whenever work is created, started, handed off or finished, or when anyone asks what is being worked on.
---

# Team board

The board is plain files under `board/` (committed, so everyone sees it). Run commands from the repo root.

```bash
scripts/board.sh new   "Login page" -f src/login.tsx,src/login.css -a "page loads and submits"
scripts/board.sh claim T-001 ana         # one winner; fails if any listed file is already leased
scripts/board.sh note  T-001 ana "uses /api/session; token in cookie"
scripts/board.sh done  T-001 ana "vitest 8 passed; sha 3f2a1c9"   # evidence is required
scripts/board.sh release T-001 ana       # give it back
scripts/board.sh show T-001
scripts/board.sh list
```

## Rules
1. One task = one owner = a set of files nobody else is editing. Two tasks that need the same
   file get merged or done one after the other.
2. Claim before you start. If `claim` fails, someone else has it or holds one of its files; do not work around it.
3. Edit only files your task lists. Need another file? `note` the owner's task and ask in Discord.
4. `done` requires evidence (test output, URL, commit SHA). No evidence, no done.
5. The owner name is the teammate's name from `team.json`, or `agent` for work you do yourself.
6. At the end of the event, `list` should show every task `done` or explicitly parked.
