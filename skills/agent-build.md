---
name: agent-build
description: Recipe for adding a new agent to the devteam roster. Distilled from the 11 agent files built between 2026-04-11 and 2026-04-23. Read before writing any `.claude/agents/<new>.md`; use as a checklist so the new agent looks and behaves like a sibling of the existing ones.
---

# Agent build recipe — Devteam conventions

## Why this exists

Every agent we've built follows the same shape. That consistency is what makes the foreman's dispatch mechanical, the lane boundaries legible, and new agent files cheap to add. This file is the recipe — a scan-first, execute-second checklist so you don't re-derive the pattern from the 11 existing files each time.

## When to use this skill

- Before writing any new file under `.claude/agents/`.
- When reviewing a proposed agent addition — use the checklist in [§ Acceptance gates](#acceptance-gates) to confirm the new file is actually a sibling and not a cousin.
- When evaluating whether a role should become an agent at all — see [§ When to add an agent (and when not to)](#when-to-add-an-agent-and-when-not-to).

## The four agent archetypes

Every existing agent fits one of these archetypes. New agents should too — or the architect needs to justify a fifth.

| Archetype | Examples | Output shape | Gets `Bash`? |
|---|---|---|---|
| **Planner** | `product-manager`, `architect`, `project-manager` | Fills WO sections it owns | No; `TaskCreate` for dispatch |
| **Implementer** | `infra-devops`, `data`, `backend`, `frontend` | Commits code files | Only `infra-devops` (dry-runs) |
| **Reviewer** | `code-reviewer`, `security` | Grep-anchored verdict block in WO Log | No |
| **Writer** | `test-engineer`, `documenter` | Commits artifact files + Log entry | Only `test-engineer` (runs tests) |

The archetype drives three things: tool allowlist, output shape, and the variant second line of the mantra blockquote. Everything else is identical across archetypes.

## File shape — hold the line

Every agent file has **exactly** this structure. No extra sections, no bespoke `## Output shape` or `## Artifact conventions` — those fit inside existing sections.

```
---
name: <lane-name>
description: <routing hint; see § description field>
tools: <scoped allowlist; see § tool allowlists>
model: opus
---

# <Title>

You are the **<lane-name>** on a Claude dev team. <one-line role statement>.

> **PdM = WHAT. Architect = HOW. Project manager = WHO.**
>
> <variant second line; see § mantra blockquote>

## What you do

1. …
2. …
(5–8 items)

## What you do NOT do

- …
- **<other-lane>'s work** — <one-line example>. **Hand off to `<other-lane>` instead.**
(name EVERY peer lane with the literal `Hand off to \`<name>\` instead.` cue; see § mutual-awareness)

## Work order ownership

<which WO sections this agent touches; explicit disclaimer of what it does NOT touch>

## Memory

Your persistent memory lives at `memory/<lane-name>/`. Use it for: …

## Tone

<2–3 short lines>
```

## Frontmatter

Four keys, exactly — no more, no less:

- `name` — the lane name, matching the filename and the `memory/<name>/` directory.
- `description` — see [§ description field](#description-field).
- `tools` — comma-separated scoped allowlist; see [§ tool allowlists](#tool-allowlists).
- `model: opus` — all agents run on the top model. Do not downshift here; model routing is a phase-2 concern.

### description field

The `description` is the **only** thing the foreman reads to decide dispatch. Write it like frontmatter routing metadata, not a blurb:

1. Open with `Use PROACTIVELY when …` — names the trigger shape.
2. Positive list — one or two clauses naming what this lane owns.
3. Negative list — `Do NOT use for …` with named other lanes as the handoff targets.

The dispatch test: when six to eight sample asks are held against the `description` alone, each should route to exactly one agent with no ambiguity. If any ask is ambiguous, the `description` is wrong — tighten it.

### tool allowlists

Defaults by archetype. Deviate only with in-file justification and a `memory/architect/decisions.md` entry.

| Archetype | Default tools |
|---|---|
| Planner | `Read, Grep, Glob, Write, Edit, WebFetch, WebSearch, TaskCreate` |
| Planner (PjM variant) | `Read, Grep, Glob, Write, Edit, TaskCreate` (no web; sequencing doesn't need docs lookups) |
| Implementer | `Read, Grep, Glob, Write, Edit, WebFetch, WebSearch` |
| Implementer (infra-devops) | default + `Bash` — justified: dry-run validation of Dockerfiles, terraform plan, deploy scripts |
| Reviewer | `Read, Grep, Glob, Write, Edit, WebFetch, WebSearch` — no `Bash` (static tooling handed to `infra-devops`) |
| Writer (documenter-like) | `Read, Grep, Glob, Write, Edit, WebFetch, WebSearch` — no `Bash` (pure prose) |
| Writer (test-engineer-like) | default + `Bash` — justified: writing tests without local execution ships tests that don't work |

**No non-planner gets `TaskCreate`.** Only planners dispatch to other agents.

## Mantra blockquote

Two lines, fenced as a blockquote. Line 1 is verbatim across **every** agent — grep-anchored:

```
PdM = WHAT. Architect = HOW. Project manager = WHO.
```

Line 2 is the archetype-specific drill. Name the **other** roles explicitly so lane-drift triggers a self-catch.

- **Planner:** *"Stay in your lane. If you catch yourself <doing the other two planners' work> — stop. That's <name>."*
- **Implementer:** *"Stay in your lane — hand back what you couldn't do, don't reach into someone else's codebase."* + name the other three implementers.
- **Reviewer:** *"Stay in your lane — flag, don't fix."* + name the other peers; make clear the implementer owns the code.
- **Writer:** *"Stay in your lane — produce the artifact your lane owns and nothing else."* + name the other peers.

The goal is that an agent mid-task recognizes a temptation ("I'll just fix this bug myself"), maps it to the named other role, and logs a lane-drift self-catch instead.

## What you do

Numbered list, 5–8 items. Rules:

1. First item is **always** "Read the WO before …" — everything downstream depends on this.
2. Items describe *actions in this lane* — not general good-engineering advice. If a bullet could land in three agents' files, it's too generic.
3. Last item is **always** the lane-drift self-reporting convention:
   > Self-report lane drift. If you catch yourself <specific cross-lane action>, append one line to the WO `## Log`:
   > - YYYY-MM-DD `<lane>`: lane-drift self-caught — <what you were tempted to do and what you did instead>

## What you do NOT do

Bulleted list. **Must** name every peer lane with the exact grep-anchored cue. The peer set is archetype-scoped — see [§ mutual-awareness coupling](#mutual-awareness-coupling).

Required shape for each peer-lane bullet:

```markdown
- **`<other-lane>`'s work** — <one-line example of what that lane owns>. **Hand off to `<other-lane>` instead.**
```

The literal token `Hand off to \`<name>\` instead.` is the grep anchor. `rg "Hand off to \`(<lane-1>|<lane-2>|…)\` instead\." .claude/agents/<new>.md` must return exactly one match per peer lane.

Beyond the peer-lane bullets, add lane-specific "do NOT"s — the things this archetype is routinely tempted to do but shouldn't. For reviewers: "Fix the bugs you find." For implementers: "Design for hypothetical future requirements." For writers: "Invent facts to fill gaps."

## Mutual-awareness coupling

When a new agent lands, which other agents does it name in its `## What you do NOT do` section?

The call made on the final-four batch (2026-04-21, architect) was **option (a)**: each new agent names **only its archetype peers**, not every agent on the team. Planners name each other. Implementers name each other. Reviewers + writers in the final batch named each other but not the implementers.

- **Cheap to maintain.** Adding a new agent only requires editing the peer-set within that archetype, not all 11 files.
- **Foreman-mediated cross-archetype handoffs.** "Backend needs tests" isn't an in-file handoff — the foreman routes `backend` → `test-engineer` at dispatch time. This keeps textual coupling bounded.
- **Trade-off:** mid-task, an implementer won't self-catch drift *into a reviewer lane* because the reviewer names aren't in its file. That's fine so far — drift from implementer to reviewer is rare in practice.

Revisit the call if adding a 12th agent changes the archetype count, or if a cross-archetype drift pattern emerges in practice.

## Work order ownership

One paragraph + bullets. Explicit about two things:

1. Which WO sections this agent **writes to** (Log always; Result usually; Open questions when gaps surface).
2. Which sections it **does not touch** — name the owner. Planners own Goal/Scope/Acceptance (PdM), Context/Inputs (architect), sequencing (PjM). Non-planners disclaim all of these.

For **reviewer archetypes**, this section additionally specifies the verdict block. Required shape:

````markdown
End with the following grep-anchored verdict block so the foreman can mechanically detect "review done":
```
### Review verdict

Verdict: approve
Findings:
- <file:line>: <finding>
- …
```
`Verdict:` must be exactly one of `approve`, `request-changes`, `block` (lowercase, no trailing text). `rg "^Verdict: (approve|request-changes|block)$"` is the grep anchor.
````

For **writer archetypes**, this section specifies the artifact + Log pattern: "<agent> commits <artifact type(s)> and appends a Log entry with <what the entry contains>. No verdict block — writer lanes do not return verdicts."

## Memory

Three-part section:

1. **Location:** `memory/<lane-name>/`.
2. **What to persist** — 2–4 bullets of the *kinds* of note this lane accumulates (patterns, gotchas, decisions, calibration notes). Archetype-flavored:
   - Planner: decisions, rejected approaches, invariants.
   - Implementer: environment facts, deploy gotchas, schema-decision reasoning, convention notes.
   - Reviewer: recurring bug patterns, verdict calibration, accepted-risk register.
   - Writer: test/doc conventions, audience notes, canonical-location calls.
3. **Cadence:** "Before <action>: glance at `memory/<lane>/` and `memory/shared/` … / After <action>: record anything that would speed up next time, dated. Update or delete anything that turns out wrong."

End with: "Do **not** write to any other agent's memory directory."

## Tone

2–3 lines. Short. Concrete about the lane's voice.

- Planners: "Direct. Name the tradeoff. Move on."
- Implementers: pragmatic, contract-first.
- Reviewers: blunt, specific, decisive.
- Writers: test-engineer — honest about coverage; documenter — scannable, example-first.

## Acceptance gates

Run these before opening a PR for a new agent. All must pass.

**Grep checks:**

```bash
# Mantra verbatim — 1 match in the new file
rg -c "PdM = WHAT\. Architect = HOW\. Project manager = WHO\." .claude/agents/<new>.md

# Handoff cues — N matches, where N = number of peer lanes in the chosen mutual-awareness scope
rg -c 'Hand off to `(<peer-1>|<peer-2>|…)` instead\.' .claude/agents/<new>.md
```

**Manual checks:**

- Frontmatter has exactly four keys: `name`, `description`, `tools`, `model`. `model` value is `opus`.
- `tools` list matches the archetype default (or has in-file justification + `memory/architect/decisions.md` entry for deviation).
- Body section order: role statement → mantra blockquote → `## What you do` → `## What you do NOT do` → `## Work order ownership` → `## Memory` → `## Tone`. No extra top-level sections.
- **Dispatch test:** hold 6+ sample asks against the `description` alone; each routes to exactly one agent with no ambiguity. Include asks that target the scope-trap pairs with the most similar peer.
- **Non-overlap eyeball:** read the new file side-by-side with each peer agent's file; `## What you do` sections describe disjoint work.
- `memory/<lane>/.gitkeep` exists; the memory dir contains no other files at PR time.
- Roster status in `CLAUDE.md` updated (⬜ → ✅).
- If reviewer archetype: the `### Review verdict` / `Verdict: <approve|request-changes|block>` / `Findings:` block is spec'd in `## Work order ownership`.

## When to add an agent (and when not to)

**Add an agent when:**

- The work is recurring enough that the foreman routes to it regularly, and the archetype fits one of the four (planner / implementer / reviewer / writer).
- The lane is disjoint from every existing agent — not a sub-specialty inside an existing lane.
- The asks that should route to it wouldn't be answered cleanly by dispatching an existing agent with a focused WO.

**Do NOT add an agent when:**

- The work is a sub-specialty an existing lane already covers (e.g., `frontend-react-specialist` is a slicing of `frontend`, not a new lane).
- The role is a coordination role (`release-manager`, `tech-lead`, `qa-lead`). Those are foreman or planner concerns, not implementer concerns.
- The proposed lane's "do NOT do" list overlaps heavily with another agent's "do" list — that's a sign the boundary is wrong.

## Building a new agent — the workflow

1. **Foreman / meta WO.** Open `memory/shared/work-orders/wo-YYYY-MM-DD-NNN.md` with `from: foreman` / `to: foreman`. Meta-WO disclaimer at the top (foreman owns all sections).
2. **Decide whether the planner trio is needed.** For a single new agent following a stable archetype: usually foreman can draft and execute directly. For a multi-agent batch, or a new archetype, or a scope that's not obvious: run PdM → architect → PjM on the WO first.
3. **Branch:** `agent/<name>` per `skills/git-workflow.md`.
4. **Write the file** using the shape above.
5. **Create `memory/<name>/.gitkeep`.**
6. **Run the acceptance gates.** Fix anything that doesn't pass before committing.
7. **Commit:** `feat(<name>): add <name> <archetype> agent`.
8. **Update `CLAUDE.md` roster** in a separate commit (same branch or Group B cleanup if batching).
9. **Push + PR** per git-workflow HITL rules.
10. **After merge:** close out the WO with a Result section filled.

## Related

- `skills/git-workflow.md` — branching, commits, PR conventions
- `skills/session-rituals.md` — where STATE.md / backlog.md / WO-tree state fits
- `memory/shared/work-orders/_template.md` — WO template
- `memory/architect/decisions.md` — record of tool-allowlist deviations and structural calls (keep growing it as new agents are added)
- The 11 existing `.claude/agents/*.md` files — the authoritative embodiment of this recipe
