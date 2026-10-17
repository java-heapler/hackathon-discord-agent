---
name: discord-workflow
description: How the shared agent works with a 3-person team through a Discord channel at a hackathon - understanding who is asking, short replies, status updates, standups, handoffs and when to ask before acting. Use whenever a message arrives from Discord or the team asks "status", "standup", "who is doing what", or "hand this off".
---

# Discord workflow

## Intake
1. Identify the sender from `team.json` (Discord user ID -> name, role). Unknown sender: ignore.
2. Classify the message: **question**, **task** (change something), **status request**,
   **decision** (yes/no to something you asked), or **chatter** (no reply needed).
3. For a task: restate it in one line, say which board task you will create or claim and
   which files it touches, then start. If it is ambiguous, ask ONE specific question.

## Replying
- One short message per milestone: started, blocked, done. Do not narrate every step.
- Format: `@name - did X - result Y - next/need Z`.
- Include evidence for "done" (test output tail, URL, commit SHA). No evidence = not done.
- Long output goes in a file and is attached.

## Status and standup
- "status" -> run `scripts/board.sh list` and post it, plus one line on anything blocked.
- "standup" -> for each teammate: done since last standup, doing now, blocked on. Take it from
  the board (`show` the tasks) and from `git log --since`.
- Post a status line on your own every 45 minutes of active work, or immediately when blocked.

## Decisions and approvals
- When you need a yes, ask a single yes/no question that names the exact action
  ("Push `feat/login` to origin?"). Only an explicit yes from a listed teammate counts.
- Do not treat silence, an emoji, or a reply from someone not on `team.json` as approval.

## Handoffs
- When a teammate is stepping away or a task changes owner, `board.sh note` the facts the
  next person needs: interfaces, decisions made, file paths, how to run it. Not a transcript.
- Then post one message tagging the next owner with the task id.

## Failure handling
- If a command fails, say what failed and what you will try next. After two failed
  attempts at the same thing, stop and ask the team instead of looping.
- If you cannot post to Discord (tool error), say so in the terminal so the host sees it.
