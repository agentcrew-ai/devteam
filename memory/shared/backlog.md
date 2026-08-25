# Backlog — devteam

_Running "later" list: ideas and deferred items. Not active work (that's `STATE.md`)._

## Documentation / adoption

- **Fold the layer-consumption symlink loop into `project-bootstrap.md`.** `TEAM-GUIDE.md` §2 introduces a consumer→shared-layer symlink loop (overlay-wins-over-base fallback). `project-bootstrap.md` currently only documents consuming the base directly. Absorb the nested-layer precedence loop there so there's one authoritative mechanics doc. (Gap surfaced while writing TEAM-GUIDE, 2026-07-14.)
- **Provide a starter template / bootstrap skill for a team layer repo** (a `team-layer-bootstrap` skill or a template skeleton: overlay dirs, stub `CLAUDE.md`, an example SME agent). John floated this as the "scaffold + doc" option; deferred in favor of shipping the doc first.

## Process / hygiene

- Reconcile `develop` behind `main` (backup-dr merged straight to main) — see STATE.md open items.
- Approve or revise the `PROPOSED` backup-dr standard (version event, John's call).
- Delete merged `origin/standards/backup-dr` branch.
