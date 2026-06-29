---
name: session-rituals
description: Start-of-session, mid-session, and end-of-session rituals for the devteam foreman. Ensures any Claude session on any machine can resume work from git + repo state alone. Read at the start of every session.
---

# Session rituals

## Why this exists

The user must be able to hit any machine with GitHub access and the right credentials and pick up exactly where work was left off. That means **all resume-state must live in git** — not in a Claude session, not in Claude's per-machine auto-memory, not in user-local files outside the repo. These rituals keep that contract tight.

**The authoritative in-repo state files:**

- `memory/shared/STATE.md` — current work, resume-from-here notes
- `memory/shared/backlog.md` — running "later" list (ideas, deferred items)
- `memory/shared/work-orders/` — active + completed WOs, including foreman/meta WOs
- `CLAUDE.md` — project rules, mantra, triage heuristic, HITL, session rituals reference
- `.claude/agents/` — agent definitions
- `skills/` — git workflow, these rituals, future shared skills

If it's not in one of those locations, it probably won't survive a machine handoff. When in doubt, write it down in the right place *before* moving on.

---

## Start of session (foreman)

When a new Claude Code session opens in the devteam repo, BEFORE doing anything else, before even greeting the user:

1. **Check git state** — `git status`, `git log --oneline -10`, `git branch --show-current`
   - Uncommitted changes? Might be from a prior session that crashed. Do NOT blow them away. Read them to figure out what the previous session was mid-way through.
   - On a feature branch? You're mid-work on something — find the matching WO.
2. **Sync with origin** — `git fetch origin`. If on `main` and behind, `git pull --ff-only`. If on a feature branch, check whether it's behind `main` and decide whether to rebase now or flag it.
3. **Read `memory/shared/STATE.md`** — single source of "where were we, where to pick up"
4. **Read `memory/shared/backlog.md`** — what's on deck
5. **List active WOs** — glance through `memory/shared/work-orders/*.md` for anything with `status: in-progress` or `assigned`
6. **Greet the user** with a 3-sentence summary in roughly this shape:
   > *"Last session ended with [X]. Active work: [Y, or 'clean']. Next on deck per STATE.md: [Z]. What do you want to do?"*
7. **Wait for direction.** Do not start dispatching agents until the user confirms, unless STATE.md says to auto-resume a specific thing.

## Mid-session (during work)

Every time a meaningful unit of work lands — a commit, a dispatched agent returning, a WO advancing a stage — do the bookkeeping:

1. **Update the relevant WO** — append to Log, update `status:` frontmatter if changed
2. **Update `STATE.md`** if and only if the "resume from here" picture changed — don't rewrite it for every tiny step, only when the next-session pickup point has moved
3. **Commit locally** per git-workflow — one logical unit per commit, conventional commit message, specific file paths (never `git add -A`)
4. **Do NOT push** between these. Batch pushes at natural pause points or during shutdown.
5. If a new idea or deferred item comes up mid-work, **add it to `backlog.md` immediately** — don't rely on memory.

## End of session (shutdown)

Before the user calls it a day OR before closing the tab:

1. **Commit anything staged but uncommitted** — never leave work dangling. If work isn't at a clean commit point, stage what exists anyway and commit with a clear `wip:` marker in the body, or use `git stash` and note it in STATE.md.
2. **Update `memory/shared/STATE.md`** with:
   - What was just completed
   - What's currently active (mid-flight, if any) and EXACTLY where to pick up — branch name, WO id, which section of which file, what the next keystroke would be
   - What's next on deck
   - Any open questions waiting on the user
   - Any "watch out for" notes from today's session
3. **Update `memory/shared/backlog.md`** if new ideas surfaced
4. **Ensure all active WOs reflect reality** — statuses accurate, Logs current
5. **Push everything — after HITL confirm with the user** (per `skills/git-workflow.md`)
   - On `main`: push main
   - On a feature branch with an open task: push to preserve state, do NOT merge yet
6. **One-line shutdown summary to the user**: *"Pushed [X]. Next session starts by reading STATE.md — resume point is [Y]."*

## Resume from another machine

If you're starting a session on a different machine than the last one:

1. `git clone git@github.com:<your-org>/devteam.git` (if not already cloned)
2. `cd devteam && git pull --ff-only`
3. Run the **Start of session** ritual above
4. `memory/shared/STATE.md` should tell you everything you need. If it doesn't — if there's something you can't figure out from the files alone — **that's a bug in the previous session's shutdown**. Fix STATE.md (and possibly the shutdown ritual) before continuing, so the next handoff is cleaner.

## What this protects against

- Losing the thread between sessions
- Duplicate work across machines
- Orphaned branches / forgotten WOs
- "I know I was doing something important but I can't remember what" at session start
- State living only in a Claude session's transient memory or per-machine auto-memory
- The user having to re-explain context at every resume
