---
name: demo-ready
description: Pre-demo checklist for a hackathon team - prove the deploy is live with a marker string, run a quick security pass, rehearse the demo path and write the fallback. Use when the team says "demo", "submit", "ship it", "are we ready", or in the last two hours of the event.
---

# Demo ready

Work through this in order and post the results to the team channel. Do not say "ready" until every item has evidence.

## 1. It is actually live
- The latest commit is pushed and CI (if any) is green: show the run status.
- The deploy really happened, and the live URL serves the NEW code. Pick a string only the
  new build contains and fetch the live URL to find it. A green build alone is not proof.
- Nothing of yours is left uncommitted (`git status` is clean).

## 2. Quick security pass (15 minutes, not an audit)
- No secrets in the repo or git history: search for `sk-`, `AKIA`, `BEGIN PRIVATE KEY`,
  `password=`, and check `.env` is ignored.
- Every endpoint that changes data requires the right user; user input is validated
  and never put straight into a query or shell command.
- No debug mode, default passwords or open admin pages on the live site.
- Anything found: post it with severity and the fix; fix the critical ones before the demo.

## 3. Demo path
- Write the 3-minute path as numbered steps in `DEMO.md`: who clicks what, what they should see.
- Run it end to end on the live URL once, and record the result.
- Write the fallback in `DEMO.md`: what to show if the network, the API or the model is down
  (a screen recording, saved responses, or a local build).

## 4. Hand over
- Post the live URL, the repo URL, `DEMO.md`, and who presents which part.
- Park anything unfinished as a `todo` on the board with a one-line reason.
