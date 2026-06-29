---
id: wo-YYYY-MM-DD-NNN
title: Adopt devteam into <consumer-project-name>
from: user
to: foreman
status: draft            # draft | assigned | in-progress | complete | blocked
created: YYYY-MM-DD
parent: null
kind: adoption           # marker — this WO uses the adoption template, not the generic one
---

> **This is the adoption-WO template.** Use it the first time devteam is wired into a consumer project. The generic WO template (`_template.md`) is for ongoing work; this one is for the one-time setup that gets the consumer to the point where it can use the generic template.
>
> Replace every `<placeholder>` with the consumer project's actuals, then walk through Acceptance criteria top-to-bottom. The foreman owns this WO end-to-end since it predates any agent dispatch in the consumer.

## Goal

The consumer project `<consumer-name>` can run a full Claude Code session against devteam's 11-agent roster, enforce devteam's standards, and produce a green hello-world dry-run that proves the wiring is correct end-to-end.

## Context

- devteam repo: `git@github.com:agentcrew-ai/devteam.git`
- Target devteam tag to pin: `<e.g., v0.1.0>` (check `standards/CHANGELOG.md` and `git tag --sort=-creatordate` for the latest)
- Consumer project stack: `<e.g., Frappe / Saleor / React+Postgres>` — affects which standards apply and which dry-run fixture is appropriate
- Consumer project's existing CLAUDE.md state: `<none | exists but minimal | exists and is comprehensive>` — drives whether we replace or extend

## Inputs

- Read: `.devteam/skills/project-bootstrap.md` (the playbook this WO operationalizes)
- Read: `.devteam/CLAUDE.md` (the operating instructions the consumer will inherit)
- Read: `.devteam/standards/CHANGELOG.md` (so the pin choice is informed)
- Optional: any existing consumer-project Claude config you want to merge or replace

## Scope

**In:**
- Add devteam as submodule at `.devteam/`, pinned to the target tag
- Author/update the consumer's root `CLAUDE.md` to import devteam's operating instructions, name the project, and identify state-file locations
- Configure `.claude/settings.json` with `additionalDirectories: [".devteam"]` and (optionally) copy the PR-open/PR-merge hooks
- Create the per-project state skeleton: `memory/shared/STATE.md` (seeded with the resume pointer "adoption WO in flight"), `memory/shared/backlog.md` (empty + header), `memory/shared/work-orders/` (with this WO and `_template.md` copied from devteam)
- Create empty per-agent memory directories: `memory/{product-manager,architect,project-manager,infra-devops,data,backend,frontend,code-reviewer,test-engineer,security,documenter}/`
- Run a hello-world dry-run appropriate to the consumer's stack (Frappe → `dryrun/hello-world-frappe` analog; web service → a single endpoint; data pipeline → a single ETL step) to verify dispatch + WO mechanics work
- Confirm at least one standards file is being honored by an agent in the consumer (e.g., `backend` reads `standards/api/` before writing the first endpoint)

**Out:**
- Building the consumer project's actual features (that's the *next* WO)
- Editing files inside `.devteam/` (never; upstream contributions go to the devteam repo via its own PR flow)
- Onboarding additional collaborators (separate concern; handle via repo settings)
- Migrating from an existing Claude agent system to devteam (a full migration is its own WO, much bigger than adoption from scratch)

## Acceptance criteria

- [ ] `.devteam/` submodule exists, pinned to the chosen tag, and `git submodule status` shows clean
- [ ] `cat CLAUDE.md` shows the consumer's CLAUDE.md, with a "Dev team — operating instructions" section referencing `.devteam/CLAUDE.md`
- [ ] `cat .claude/settings.json` includes `permissions.additionalDirectories: [".devteam"]`
- [ ] `memory/shared/{STATE.md, backlog.md, work-orders/}` all exist and are non-empty (header + this WO at minimum)
- [ ] All 11 per-agent memory directories exist at the consumer root
- [ ] A dry-run WO has been dispatched end-to-end, all assigned lanes have populated their Result sections, and the verdict block (code-reviewer + security if applicable) is `approve` or `request-changes` (a blocking finding is NOT a failure of adoption — it's a successful surfacing of a real issue)
- [ ] One concrete piece of evidence that a standards file was consulted: a citation in any agent's Log section, e.g., "data: read `.devteam/standards/data/naming.md` before drafting schema"
- [ ] Consumer's start-of-session ritual (per `.devteam/skills/project-bootstrap.md` § Session rituals) runs cleanly: foreman reads both CLAUDE.mds, reads consumer's STATE/backlog, lists active WOs, surfaces the devteam pin in the greeting

## Open questions

<Use this section for things the foreman needs the user to resolve before proceeding. Examples:
- Which standards tag to pin?
- Where in the consumer repo should state files live if the default `memory/shared/` collides with existing content?
- Is the consumer's stack covered by an existing standards lane, or do we need a new standards directory upstream first?>

---

## Log

- YYYY-MM-DD foreman: created from `_template-adoption.md`

## Result

<Filled when adoption is complete. Include:
- The pinned tag.
- The dry-run WO ID and its outcome.
- Any deviations from the playbook (and why).
- Any standards-gap findings that should be filed upstream against devteam.
- The handoff sentence for the next session — what the consumer is now ready to work on.>
