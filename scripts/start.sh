#!/usr/bin/env bash
# Start the shared agent with the Discord channel enabled. Run this in the repo root,
# on the ONE machine that hosts the agent. Leave the terminal open.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v claude >/dev/null || { echo "install Claude Code first: https://code.claude.com/docs/en/quickstart" >&2; exit 1; }
command -v bun    >/dev/null || { echo "install Bun first: https://bun.sh/docs/installation" >&2; exit 1; }
[ -f team.json ] || { echo "create team.json first:  cp team.example.json team.json  (then edit)" >&2; exit 1; }
[ -f "$HOME/.claude/channels/discord/.env" ] || [ -n "${DISCORD_BOT_TOKEN:-}" ] || {
  echo "no Discord bot token yet. In Claude Code run:  /discord:configure <token>" >&2; exit 1; }

# keep the Mac awake while the agent runs (no-op elsewhere)
if command -v caffeinate >/dev/null; then wrap=(caffeinate -i); else wrap=(); fi
exec "${wrap[@]}" claude --channels plugin:discord@claude-plugins-official
