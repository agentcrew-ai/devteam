# STATE — devteam

_Single source of "where were we, where to pick up." Read this first every session (per `skills/session-rituals.md`)._

Last updated: 2026-07-14

## Current work

- **Branch `docs/team-guide`** (off `develop`) — adds `TEAM-GUIDE.md`, the team/org-scale adoption doc (stand up your own layer repo around the base team, load SME/context/project info, work as a team, contribute back). README updated to link it. **Committed locally, not yet pushed.** Next step: HITL-confirm push → open PR → target `develop`.

## Resume from here

1. If `docs/team-guide` is unmerged: confirm push with the user, `git push -u origin docs/team-guide`, open PR into `develop`, squash-merge (docs branch).
2. Then decide the two open items below.

## Open items / decisions for the user

- **Core repo is PRIVATE.** `agentcrew-ai/devteam` is `private: true` — John believed it was public. Handoff to the LWW team is blocked until this is resolved: either flip core to public (requires a scrub-confirm that core is clean of private context) or grant LWW read access. This is overdue task **T-1T** ("Share AI Dev Team onboarding with team"). **Do not flip visibility without explicit go-ahead** — it's a one-way outward-facing action.
- **`develop` is behind `main`.** PR #1 (`standards/backup-dr`, v0.2.0) merged straight to `main`, bypassing `develop`. `develop` lacks the backup-dr standard. Reconcile: merge/rebase `main` → `develop` so the integration branch isn't stale, and fix the flow so future work goes feature → develop → main.
- **backup-dr standard is still `PROPOSED`.** Not yet approved/adopted. Needs John's version-event sign-off.
- **Stale merged branch.** `origin/standards/backup-dr` can be deleted (merged via PR #1).

## Watch out for

- STATE.md and backlog.md did not exist before 2026-07-14 — the previous session shipped the core-publish work without leaving a resume pointer. These are now created; keep them current per the ritual.
