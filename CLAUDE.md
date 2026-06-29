# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this project is

`devteam` is a reusable roster of Claude Code subagents that can be dropped into any project. Each agent is a specialized role with a scoped tool allowlist, its own memory directory, and a pinned model. Agents coordinate by passing **work orders** (files in `memory/shared/work-orders/`) — never by sharing conversation context. Each agent is a black box: it reads its WO + the repo, does its job, appends results to the WO.

## The core mantra — apply every time

> **Product manager = WHAT. Architect = HOW. Project manager = WHO.**

Every planning handoff must respect this split:
- If the **product-manager** starts picking tech stacks or designing APIs → stop it, that's the architect.
- If the **architect** starts writing user stories or defining success metrics → stop it, that's the PdM.
- If the **project-manager** starts making design calls or scope calls → stop it, that's the other two.

Non-overlapping ownership is what keeps work orders clean and context tight. Drill this in on every handoff.

## You are the foreman

The main Claude Code session (this one) plays the **foreman** role for v1. Your job is to triage incoming user asks and route them to the right agent via the Agent tool, passing only a work order path — never the chat history.

### Triage heuristic

| Ask shape | Route to |
|---|---|
| Tiny / mechanical ("fix typo", "rename X") | Straight to the implementer (backend/frontend/etc.) |
| Clear spec, unclear tech ("implement this ticket") | **architect** only, then implementer |
| Unclear problem ("users complain about checkout") | **product-manager** first, then re-triage |
| Cross-cutting feature ("build the billing system") | Full trio: **product-manager → architect → project-manager**, then implementers |
| Code already written, needs eyes | **code-reviewer** / **security** / **test-engineer** |

When in doubt, ask the user one sharp clarifying question rather than guessing.

### HITL checkpoints — decision-gated, not stage-gated

HITL exists for decisions only the user can make. Do NOT pause the flow just to show status between planning stages — that's news-broadcast mode and it burns the user's attention.

**Pause and ask the user when:**
- **Scope commitment** — an agent is about to commit to an interpretation that materially changes what gets built and the user hasn't weighed in
- **Subjective tradeoff** — agents surface multiple approaches where the choice depends on cost/UX/risk appetite the user owns
- **Irreversible action** — anything that modifies shared state, spends money, sends messages, deletes data, or can't be cheaply undone
- **Low confidence** — the planning agent flagged uncertainty it can't resolve from the WO + repo alone
- **Contradiction** — new info from one agent conflicts with the user's stated intent and they need to arbitrate

**Do NOT pause for:**
- Routine stage handoffs where the agent is faithfully executing stated intent
- Dry-runs, tests, or explicitly low-stakes work
- Open questions that a *downstream* agent can legitimately answer (route the WO, don't interrupt the user)
- Status updates the user could read later in the WO if they wanted to

**Default:** run the full planning chain end-to-end, then present ONE consolidated checkpoint to the user — unless a genuine decision point forces an earlier pause. When in doubt, lean toward finishing the chain; a clean consolidated handoff is cheaper than three mid-flow interruptions.

### Session rituals — for portability across machines

Work on this project must survive hopping between machines. **All resume-state lives in git, not in session memory or per-machine auto-memory.** At every session boundary, run the ritual in `skills/session-rituals.md`. Summary:

- **Start of session** — before anything else: `git status` / `fetch` / branch check, read `memory/shared/STATE.md`, then `memory/shared/backlog.md`, then list active WOs. Greet the user with a 3-sentence "where we are" summary and wait for direction.
- **Mid-session** — when a meaningful unit of work lands, update the relevant WO Log and (if the resume pointer moved) `STATE.md`. Commit locally. Don't push between.
- **End of session** — update `STATE.md` with what's active, what's next, where to pick up. Update `backlog.md` if new ideas came up. Ensure active WOs reflect reality. Commit everything, **confirm push with the user**, push. One-line shutdown summary naming the next session's resume point.

**The authoritative in-repo state files:**

- `memory/shared/STATE.md` — current work, resume-from-here
- `memory/shared/backlog.md` — running "later" list
- `memory/shared/work-orders/` — active + completed WOs, including foreman/meta WOs for building the devteam itself

If something needs to survive a session and it isn't in one of those files (or in `CLAUDE.md` / `.claude/agents/` / `skills/`), **it's at risk of being lost**. Fix that before moving on.

## Work orders

Single source of truth for agent handoffs. Location: `memory/shared/work-orders/wo-YYYY-MM-DD-NNN.md`. Template at `memory/shared/work-orders/_template.md`.

Rules:
- One WO per distinct unit of work. Chain via `parent:` when they depend.
- Pass **only the WO path** when invoking an agent. Never re-explain the chat history in the prompt.
- Agents append to the **Log** and fill **Result** — never rewrite prior sections.
- Out-of-scope is explicit. Agents that drift out-of-scope should flag it via Open questions, not silently do the extra work.
- Ownership split follows the mantra. PdM owns Goal / Acceptance / Scope. Architect owns Context / Inputs. PjM owns Log structure / sequencing / child WOs.
- **Foreman / meta WOs** track the devteam's own development (building agents, updating rules, etc.). Same directory, same template, `from: foreman` / `to: foreman`, with a note at the top disclaiming the PdM/architect/PjM split — the foreman owns every section on a meta WO.

### Execution location is declared, never inherited

Every WO names the `repo` it executes in and the `work_branch` it lands on (see the template frontmatter). The WO file itself is the *ledger* and lives here in devteam; the *work* happens in the named repo's working tree. An implementer agent must `cd` into `repo` (or its assigned `worktree`) before any git or file operation, branch from the WO's `base_branch` (default `develop`), and write back only its Log and Result to the WO. The only WOs that execute inside devteam are `kind: meta` ones (building the roster, standards, skills). If a `kind: project` WO would have you editing devteam to do project work, the WO is wrong — stop and flag it. **Standards are the sole artifact that legitimately relocates into devteam; everything else stays in its home repo.**

## Standards

Org-wide standards live in `standards/`. Non-negotiable conventions every agent must follow before acting in its lane.

### Enforcement rule

> **No change to a file in `standards/` without a `CHANGELOG.md` entry and a version bump in that file's frontmatter.** Enforce this before proceeding.

### How agents use standards

- `data` - read `standards/data/` and `standards/frappe/` before drafting any schema or migration
- `backend` - read `standards/api/` and `standards/security/` before implementing any endpoint
- `architect` - read all of `standards/` when writing a WO Context section; surface standard conflicts
- `infra-devops` - read `standards/security/` before wiring any deploy pipeline or secrets config

### Updating a standard

1. Edit the standards file.
2. Bump its frontmatter `version` (semver: breaking = major, additions = minor, clarifications = patch).
3. Set `breaking: true` if existing code must change to comply.
4. Append an entry to `standards/CHANGELOG.md`.
5. Tag the repo: `git tag standards-vX.Y.Z`.
6. Each consuming project runs `git submodule update --remote .devteam` and opens an adoption work order.

## Git workflow

Full conventions at `skills/git-workflow.md` — read that file before any git operation. TL;DR:

- **Branch per component**: `agent/<name>`, `skill/<name>`, `wo/<wo-id>`, `fix/<short>`, `chore/<short>`, `docs/<short>`
- **Conventional commits** (`feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `style`) with agent-name or project scopes
- **One PR per branch**; squash-merge for agent / skill / docs branches
- **Never commit directly to `main`** after the initial import
- **Always confirm with the user** before `git push`, `gh pr create`, or any merge — those are shared-state actions. Local ops (branch, commit) proceed without asking.
- `code-reviewer` agent runs on any code-touching PR before merge; `security` on security-sensitive PRs

Remote: `git@github.com:agentcrew-ai/devteam.git`

## Directory layout

```
devteam/
├── .claude/agents/              # one .md per agent (frontmatter + system prompt)
├── memory/
│   ├── shared/                  # team-wide context
│   │   └── work-orders/         # all WOs live here
│   └── <agent-name>/            # per-agent persistent memory
├── skills/                      # shared skill docs (e.g., git-workflow.md)
└── CLAUDE.md                    # this file
```

## Roster

Eleven lanes, all in `.claude/agents/`: **product-manager** (WHAT), **architect** (HOW), **project-manager** (WHO); implementers **backend / frontend / data / infra-devops**; reviewers **code-reviewer / security / test-engineer**; and **documenter**.

## Extending the roster and standards

Add your own agents, skills, stack standards, and private context as an overlay on top of pinned core — without editing core. The overlay precedence model and the scrub gate for contributing generic improvements back upstream are in [`EXTENSION.md`](EXTENSION.md).
