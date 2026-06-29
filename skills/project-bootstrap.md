---
name: project-bootstrap
description: How to drop the devteam roster + standards into a *consumer* project (not the devteam repo itself). Covers submodule setup, consumer-side CLAUDE.md wiring, where per-project state lives, how standards flow through, and the upgrade path. Read first thing whenever a session opens in a repo that is NOT the devteam repo.
---

# Project bootstrap — using the devteam in another project

## Why this exists

Everything in the devteam repo assumes we're working on the devteam itself. Lane descriptions say "*this devteam project*", STATE.md tracks building-the-devteam work, WOs live under `memory/shared/work-orders/` relative to the devteam root. That stops making sense the moment the devteam is a dependency of some other project (a Frappe app, a web service, a client codebase). This skill is the playbook for that case.

Target scenario: a **consumer project** wants Claude Code with the full 11-agent roster, the enforcement-gated standards, and the WO-driven workflow — without forking devteam or copy-pasting its contents.

## When to use this skill

- Before the first session in a new consumer project (setup).
- Every session thereafter, at the start, in place of `skills/session-rituals.md` — the session ritual inside the consumer project differs slightly from the devteam-native ritual.
- When the consumer project wants to pull in a new devteam release (upgrade).
- When an agent's lane text seems to be describing the devteam repo rather than the consumer codebase — that's a sign the wiring in step 3 below is off.

## The wiring — devteam as a submodule

The consumer project adds devteam as a git submodule at `.devteam/`. This gives the consumer:

- A checked-in, pinned version of the devteam's agent files and skills.
- A single knob (`git submodule update --remote .devteam`) to upgrade.
- A clean boundary between devteam's files (read-only for the consumer) and the consumer's own files.

### Initial setup

From the consumer project root:

```bash
git submodule add git@github.com:<your-org>/devteam.git .devteam
git submodule update --init --recursive
git add .gitmodules .devteam
git commit -m "chore: add devteam as submodule at .devteam"
```

Then pin to a tagged release so your agents don't silently move underneath you:

```bash
cd .devteam
git fetch --tags
git checkout <latest-tag>   # check: git tag --sort=-creatordate (e.g. v0.1.0)
cd ..
git add .devteam
git commit -m "chore: pin devteam to <latest-tag>"
```

The consumer now has `.devteam/` containing a frozen snapshot of devteam's roster, skills, and standards.

### Wiring the consumer's CLAUDE.md

Claude Code reads the consumer project's root `CLAUDE.md`, not the devteam's. The consumer's `CLAUDE.md` must:

1. **Import the mantra and foreman triage** — reference the devteam's `CLAUDE.md` so you don't fork it:

   ```markdown
   ## Dev team — operating instructions

   The Claude dev team for this project lives in `.devteam/`. See:

   - `.devteam/CLAUDE.md` — mantra, foreman triage, WO rules, session rituals, standards enforcement
   - `.devteam/.claude/agents/` — the 11 agent files (made discoverable by **symlinking** them into the consumer's `.claude/agents/`; see "Wiring agent discovery" below)
   - `.devteam/skills/` — shared skills (agent-build, git-workflow, session-rituals, project-bootstrap, this file)
   - `.devteam/standards/` — enforcement-gated org-wide standards this project consumes

   All rules in `.devteam/CLAUDE.md` apply here. This file only overrides where the consumer project differs from devteam-native work.
   ```

2. **Name the consumer repo's own identity** — what is the project, who uses it, what stack.

3. **Name the per-project state files** — where STATE / backlog / WOs live *in the consumer*. Default layout (see next section).

4. **Any project-specific triage overrides** — if this project has a domain that routes to a specific agent more often, note it. Keep this short.

### Wiring agent discovery (symlinks — this is the load-bearing step)

Claude Code discovers subagents **only** from `.claude/agents/*.md` (project) and `~/.claude/agents/` (user). It does **NOT** discover agents via `additionalDirectories` — that setting is a *filesystem-access permission*, not an agent-discovery path. (An earlier version of this skill said otherwise; that was wrong and left the roster uninvocable.)

So the consumer must surface the submodule's agents by **symlinking each one into `.claude/agents/`**. Run this from the consumer root (idempotent — safe to re-run, and re-run it whenever you bump the devteam pin so new/renamed agents stay in sync):

```bash
mkdir -p .claude/agents
for f in .devteam/.claude/agents/*.md; do
  ln -sf "../../.devteam/.claude/agents/$(basename "$f")" ".claude/agents/$(basename "$f")"
done
git add .claude/agents
git commit -m "chore: symlink devteam agents into .claude/agents for discovery"
```

The symlinks are **relative** and **committed**, so they reconstitute on any machine after `git submodule update --init`. Agent discovery happens at **session start**, so a session open during this step must restart to see the roster.

### Wiring `.claude/settings.json` in the consumer

`additionalDirectories: [".devteam"]` is optional — useful only if agents need to read paths the working-directory boundary would otherwise block. Since `.devteam/` is inside the repo, it's usually unnecessary; add it only if you hit an access block:

```json
{
  "permissions": {
    "additionalDirectories": [".devteam"]
  }
}
```

If the consumer wants the devteam's automation hooks (`gh pr create` and `gh pr merge` reminders), copy them from `.devteam/.claude/settings.json` into the consumer's `.claude/settings.json`. **Do not symlink settings.json itself** — it's read per-path at session start; a symlink to the submodule would put devteam's hook paths in effect for the consumer, which is probably not what you want. (Symlinking the *agent files* into `.claude/agents/`, above, is correct and different.)

## Per-project state layout

State files live **in the consumer repo**, not inside `.devteam/`. The submodule is a library; the project under development is the consumer. Layout:

```
consumer-project/
├── .devteam/                          # submodule — pinned, read-only for the consumer
│   ├── .claude/agents/                # 11 agent files
│   ├── skills/                        # shared skills (this file included)
│   ├── standards/                     # enforcement-gated standards
│   └── CLAUDE.md                      # devteam operating instructions (imported by consumer)
├── .claude/
│   ├── agents/                        # symlinks → ../../.devteam/.claude/agents/*.md (discovery) + any consumer-specific agents
│   └── settings.json                  # hooks (+ additionalDirectories only if needed)
├── memory/
│   ├── shared/
│   │   ├── STATE.md                   # THIS project's current work, not devteam's
│   │   ├── backlog.md                 # THIS project's backlog
│   │   └── work-orders/               # THIS project's WOs (new IDs starting fresh)
│   ├── product-manager/               # per-agent memory dirs — populated as agents run
│   ├── architect/
│   ├── project-manager/
│   ├── infra-devops/
│   ├── data/
│   ├── backend/
│   ├── frontend/
│   ├── code-reviewer/
│   ├── test-engineer/
│   ├── security/
│   └── documenter/
├── CLAUDE.md                          # consumer's own; references .devteam/CLAUDE.md
└── [consumer project source files]
```

The memory directories at the consumer root are **per-project**. Notes an agent writes about the consumer codebase (schema patterns, API conventions, review calibration, etc.) live here, not inside `.devteam/`. Never commit to the submodule from inside a consumer project.

## Standards — how they flow through

`.devteam/standards/` is the authoritative org-wide convention registry. The consumer project inherits it by reference; no copy.

**The contract each agent honors in the consumer:**

- `data` — reads `.devteam/standards/data/` and `.devteam/standards/frappe/` before drafting any schema or migration
- `backend` — reads `.devteam/standards/api/` and `.devteam/standards/security/` before implementing any endpoint or service
- `architect` — reads all of `.devteam/standards/` when producing the Context section of a WO; surfaces conflicts between proposed design and existing standards
- `infra-devops` — reads `.devteam/standards/security/` before wiring any deploy pipeline or secrets config

The consumer project itself **does not edit files in `.devteam/standards/`**. If the consumer's work reveals a standard that should be updated, that's an upstream contribution — see [Upgrading](#upgrading) below.

### When a consumer's proposed design conflicts with a standard

Two paths:

1. **Comply with the standard.** Default. Architect's Context calls out the conflict and the design adapts.
2. **Request a standard change.** The consumer opens a WO *against the devteam repo*, not against itself. The change lands in devteam via the devteam's own WO → PR → merge flow, the standards version bumps, a new tag gets cut, and the consumer pulls it in via the upgrade flow below.

Never silently diverge. If a consumer project is shipping code that contradicts a devteam standard, either the standard is wrong (fix upstream) or the code is wrong (fix downstream). There is no third option.

## Session rituals — consumer variant

The start-of-session ritual from `.devteam/skills/session-rituals.md` applies with one modification: the foreman reads **both** state surfaces.

1. `git status` / `git fetch` — in the consumer repo.
2. Read `.devteam/CLAUDE.md` **and** the consumer's root `CLAUDE.md` — both are in effect.
3. Read `memory/shared/STATE.md` — this is the consumer's state.
4. Read `memory/shared/backlog.md` — consumer's backlog.
5. Check `.devteam/` pin: `cd .devteam && git log -1 --oneline && cd ..`. If the pin has moved unexpectedly (e.g., somebody else updated it in a commit), surface that in the session greeting.
6. List active WOs under `memory/shared/work-orders/`.
7. Greet the user with a 3-sentence "where we are" summary including the devteam pin, and wait for direction.

Mid-session and end-of-session rituals are unchanged — state updates go to the consumer's STATE.md.

## Upgrading `.devteam`

When the devteam releases new standards, agents, or skills, the consumer pulls them in:

```bash
cd .devteam
git fetch --tags
git checkout <new-tag>       # e.g., v0.2.0
cd ..
git add .devteam
git commit -m "chore: upgrade devteam to <new-tag>"
```

Then — and this is the part that's easy to skip — **open an adoption WO** in the consumer's `memory/shared/work-orders/`:

```markdown
title: Adopt devteam <new-tag>

Goal: the consumer project complies with any breaking changes in the
new release, consumes any new standards, and uses any new agents.

Scope — In:
- Read the devteam CHANGELOG between old-tag and new-tag
- For every `breaking: true` standard change: find and fix any code
  that currently violates it
- For every new standard: confirm the relevant lanes are reading it
  (no code change unless a violation exists)
- For every new agent: decide whether the consumer needs it in its
  triage table

Scope — Out: speculative refactors beyond what the breaking flags require
```

The adoption WO runs through the consumer's normal foreman/planner/implementer flow. Compliance with a breaking standard is a real piece of work; don't absorb it silently.

## What does NOT belong in the devteam submodule

The cleanest mental model: **`.devteam/` is read-only from inside a consumer project, always.** If you find yourself wanting to write something into it, that's the signal you're putting consumer content in the wrong place. Concretely:

- **Consumer prompt history, session transcripts, or chat exports** → live in the consumer's `memory/shared/` (or wherever the consumer wants them), never in `.devteam/memory/`. Even if devteam's memory directory layout looks inviting, those slots are for the devteam roster's own calibration across consumers.
- **App-specific how-to docs** (named paths, named bench, named app) → live in the consumer's `docs/` or wherever the consumer keeps docs. They are not standards. A standard is a *reusable cross-project convention*; a "how to set up Saleor in `my_app`" guide is documentation for `my_app`.
- **Consumer source code, schemas, migrations, fixtures, or app-specific agents** → live in the consumer repo. devteam has no application surface.
- **A new `standards/<topic>/` directory invented from inside a consumer session** → don't add it from the consumer. If the consumer's work reveals a genuinely reusable cross-project pattern, open a WO against the devteam repo (see [When a consumer's proposed design conflicts with a standard](#when-a-consumers-proposed-design-conflicts-with-a-standard)), let the change land via devteam's normal PR + CHANGELOG + version-bump + tag flow, then upgrade the consumer's pin.

If you've already pushed something into devteam that shouldn't be there, see [`recovery.md`](recovery.md) — the playbook for migrating misplaced content out of devteam and into the consumer repo where it belongs.

## When NOT to use this skill

- You're working on the devteam itself — use `.devteam/skills/session-rituals.md` instead (which, from the devteam's own root, is just `skills/session-rituals.md`).
- You're doing a one-off experiment that will be deleted — submoduling is overkill for a throwaway.
- The consumer project already has its own Claude Code agent system — don't bolt a second one on. Merge or migrate, don't compose.

## Common pitfalls

- **Committing into `.devteam/`.** The submodule is pinned and read-only from the consumer's perspective. If you end up with a dirty submodule working tree inside a consumer, you're editing something that belongs in devteam itself — push that change upstream and pin forward.
- **Per-project WOs numbered continuing from devteam.** Start the consumer's WO numbering fresh (`wo-YYYY-MM-DD-001` in the consumer). IDs are scoped to the repo they live in.
- **Agent memory leaking across projects.** Each consumer has its own `memory/<lane>/` directory. Don't symlink to somewhere global; the point of per-project memory is per-project calibration.
- **Auto-memory (off-repo) carrying devteam context into a consumer session.** The Claude Code auto-memory is per-CWD — so starting a session in the consumer gets the consumer's auto-memory, not the devteam's. If the paths collide or you share a CWD, rename one. Portability-critical state should be in-repo regardless; see `.devteam/skills/session-rituals.md`.
- **Updating `.devteam/` without an adoption WO.** A silent submodule bump can drag in a breaking standard change. The adoption WO is the forcing function that prevents this.

## Related

- `.devteam/CLAUDE.md` — the mantra, foreman triage, WO rules this skill inherits
- `.devteam/skills/session-rituals.md` — the session ritual this one modifies
- `.devteam/skills/git-workflow.md` — branch / commit / PR conventions (apply to the consumer repo)
- `.devteam/skills/agent-build.md` — use if the consumer needs a project-specific agent on top of the 11 (should be rare)
- `.devteam/standards/CHANGELOG.md` — authoritative list of what changed between devteam tags; consult before every upgrade
