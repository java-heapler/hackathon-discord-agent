# hackathon-discord-agent

A shared coding agent for a team of three, driven from a Discord channel.
It uses Anthropic's Discord channel plugin for Claude Code (the bridge to Discord) and adds
what a small team needs on top: operating rules, a task board that prevents teammates
and the agent editing the same files, and a pre-demo checklist.

One person (the **host**) runs the agent on their computer. The other two talk to it in Discord.

## What is in here
| Path | What it does |
|---|---|
| `CLAUDE.md` | Rules the agent follows: who it listens to, how it replies, what it must ask before doing |
| `.claude/skills/discord-workflow` | Message handling, status, standup, handoffs |
| `.claude/skills/team-board` | How to use the task board |
| `.claude/skills/demo-ready` | Live-deploy proof, quick security pass, demo path |
| `scripts/board.sh` | Shared task board (plain files; atomic claims; file leases) |
| `scripts/test_board.sh` | Self-check for the board |
| `scripts/start.sh` | Starts Claude Code with the Discord channel on |
| `team.example.json` | Roster template (copy to `team.json`) |

## Requirements
- Claude Code installed and logged in with a claude.ai account or a Console API key.
  Channels are a **research preview**: the `--channels` flag may change. On Team/Enterprise
  an org Owner must enable channels first.
- [Bun](https://bun.sh) (the plugin is a Bun script): `bun --version` must work.
- A Discord server you can add a bot to.

## Setup (the host does this once, about 15 minutes)

### 1. Create the Discord bot
1. Open https://discord.com/developers/applications and click **New Application**.
2. In **Bot**, create the bot user, click **Reset Token**, and copy the token. Treat it like a password and never commit or post it.
3. In **Bot > Privileged Gateway Intents**, turn on **Message Content Intent**.
4. In **OAuth2 > URL Generator**, tick scope `bot` and permissions: View Channels, Send Messages,
   Send Messages in Threads, Read Message History, Attach Files, Add Reactions.
5. Open the generated URL and add the bot to your team's server.
6. Make a private channel (for example `#team-agent`) that only the three of you can see.

### 2. Get this repo and the roster
```bash
git clone <this repo's URL> hackathon-discord-agent
cd hackathon-discord-agent
cp team.example.json team.json
```
Edit `team.json`: put each teammate's name, role and Discord username. The Discord user ID is optional but safer (usernames can change). To find an ID, in Discord go to
Settings > Advanced > turn on Developer Mode, then right-click the person > **Copy User ID**.
`team.json` is gitignored.

### 3. Install the plugin and save the bot token
Start Claude Code in this folder and run, one at a time:
```
/plugin install discord@claude-plugins-official
/discord:configure <your-bot-token>
```
If it says the marketplace is not found: `/plugin marketplace add anthropics/claude-plugins-official`, then retry.
Choose the **user** scope when asked. The token is saved to `~/.claude/channels/discord/.env` on your machine.
Then exit Claude Code.

### 4. Start the agent
```bash
scripts/start.sh
```
This runs `claude --channels plugin:discord@claude-plugins-official`. Leave the terminal open.
The bot only answers while this is running.

### 5. Pair and lock down access (all three people)
Each teammate sends the bot a direct message on Discord. The bot replies with a pairing code.
The host enters each code in the Claude Code session:
```
/discord:access pair <code>
```
After all three are paired:
```
/discord:access policy allowlist
```
Only paired people can steer the agent now; everyone else is silently ignored. Anyone on the list
can steer it, so pair only teammates you trust.

Not confirmed: the docs describe pairing by direct message. How to opt in a shared server channel is not covered there.
Check `/discord:access` help in your session and the plugin README:
https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/discord

### 6. Check the board works
```bash
bash scripts/test_board.sh        # prints "all board checks passed"
```

## Using it
Talk to the bot in Discord in plain language:
- `@bot I'm taking the login page` -> it creates and claims a board task under your name.
- `@bot status` -> it posts the board and anything blocked.
- `@bot standup` -> done / doing / blocked per person.
- `@bot are we demo ready?` -> it runs the `demo-ready` checklist and reports evidence.

It will ask for an explicit yes before deploying, pushing to `main`, deleting things or spending money.

## Limits you should know about
- **One agent, one machine.** It works on the host's files. If the host closes the lid or the terminal, the bot goes quiet.
- **Permission prompts stall it.** If the agent needs approval for a command and nobody is at the host's terminal, it waits.
  `.claude/settings.json` pre-approves the board script and basic git commands. Add safe commands your stack needs.
  `--dangerously-skip-permissions` removes prompts but is risky; use it only in a throwaway environment.
- **Allowlisted teammates can steer the agent** and, if the plugin relays permissions, approve its actions.
- **Usage costs tokens.** Long unattended runs add up, so watch it.
- **Do not paste secrets in Discord.** The agent is told not to repeat them, but chat history is still chat history.

## Credits and licensing
The Discord bridge is Anthropic's official plugin (not part of this repo). `scripts/board.sh` and the skills here are original to this repo.
Licensed under the MIT License (see `LICENSE`).
