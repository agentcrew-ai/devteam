---
id: wo-YYYY-MM-DD-NNN
title: <short descriptive title>
from: <agent or "user">
to: <agent>
status: draft            # draft | assigned | in-progress | complete | blocked
created: YYYY-MM-DD
parent: null             # or wo-... if this WO depends on another
kind: project            # project | meta   (meta = devteam building devteam)
repo: <short-name>       # the repo the work EXECUTES in. meta WOs: repo: devteam
prod_branch: main        # this repo's production branch (main | master — check, don't assume)
base_branch: develop     # branch new work forks FROM
work_branch: feature/<slug>   # branch the work lands ON
worktree: null           # set by the scheduler when isolated; null = runs in the repo's primary tree
---

> **Execution location is declared, never inherited.** This WO file is the *ledger* and lives in devteam; the *work* happens in `repo` at `work_branch`. An implementer must `cd` into `repo` (or its assigned `worktree`) before any git/file operation, and writes back only its Log and Result here. The only WOs that execute inside devteam are `kind: meta` ones. If a `kind: project` WO would have you editing devteam to do the work, the WO is wrong — stop and flag it.

## Goal
<PdM owns. One sentence, user-visible. What "done" feels like to the user.
No tech jargon. No implementation details.>

## Context
<Architect owns. Digested technical background — prior decisions, constraints,
what the architect already figured out. NOT chat history.>

## Inputs
<Architect owns.>
- Files to read: `path/a.ts`, `path/b.ts`
- Interfaces/contracts: <inline if tiny; otherwise point to a file>
- Prior work orders: <wo-ids if chained>

## Scope
<PdM owns.>
**In:**
- ...

**Out:**
- ...

## Acceptance criteria
<PdM owns the user-facing ones. Architect may add technical ones.>
- [ ] Observable outcome 1
- [ ] Observable outcome 2

## Open questions
<Any agent can append. Flag things that need user or upstream resolution before proceeding.>

---

## Log
<Appended by each agent as work progresses. Never rewrite prior entries.>
- YYYY-MM-DD <agent>: created
- YYYY-MM-DD <agent>: <action>

## Result
<Filled by the receiving implementation agent when done.
What was built, files touched, deviations from plan, what the next agent needs to know.>
