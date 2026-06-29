---
name: recovery
description: Recovery playbook for when something has been pushed to devteam that should not have been — consumer prompt history, app-specific integration docs, direct commits to main, a new standards/<topic>/ directory without CHANGELOG + version bump. Covers undo, migrate-to-consumer-repo, and (when applicable) redo-as-legit-WO. Read this if you got an "umm that doesn't belong here" message from a maintainer, or if you realize mid-session you put content in the wrong place.
---

# Recovery — un-doing a wrong push to devteam

## Why this exists

devteam is a library consumed by other projects as a git submodule. The boundary between "devteam content" and "consumer content" is the difference between a reusable convention and one project's specifics. When that boundary breaks — usually because someone learning the system pushed consumer content into devteam itself — the fix is mechanical but worth writing down so it goes the same way every time.

This skill exists for the *recovery* case. If you're still pre-push, just don't do the thing — read [`project-bootstrap.md`](project-bootstrap.md) and put the content in the consumer repo where it belongs.

## When to use this skill

- A maintainer (or the foreman) flagged a commit on `main` that violates the repo rules (direct push, no CHANGELOG, new `standards/<topic>/` without version bump, consumer content under `memory/` or `standards/`).
- You realize you've been writing consumer-project content (prompt history, app-specific docs, source code) into `.devteam/` from inside a consumer session.
- You opened a feature branch on devteam to do something that, in retrospect, should have happened in a consumer repo.
- You pushed a tag or release that bundles content that doesn't belong in the library surface.

## The decision tree

Before touching anything, classify what was pushed:

```
Was the content pushed to devteam?
├── No → stop. Use project-bootstrap.md. You don't need this skill.
└── Yes
    ├── Is the content a reusable cross-project convention (a real standard, a new agent, a new skill)?
    │   ├── Yes, but pushed wrong (direct to main, no CHANGELOG, no version bump)
    │   │   → § Path A: Revert + redo as a legit WO
    │   └── No — it's consumer-specific (prompt history, app-specific docs, source code, per-app integration guide)
    │       → § Path B: Revert + migrate to the consumer repo
    └── Mixed? Some reusable, some not?
        → § Path C: Split — revert everything, migrate the consumer-specific part, redo the reusable part properly
```

If you're unsure whether something is "reusable" vs. "consumer-specific": ask the foreman. Default to consumer-specific if the file names a specific app, path, team, or bench. A standard never names one app.

## Path A — Revert and redo as a legit WO

Use when the *content* belongs in devteam but the *delivery* was wrong (direct push, missing CHANGELOG, missing version bump).

1. **Revert the offending commit on a branch.** Never force-push `main`; cut a revert branch instead.
   ```bash
   git checkout -b chore/revert-<short-description> origin/main
   git revert <sha>
   git push -u origin chore/revert-<short-description>
   gh pr create --title "Revert: <subject>" --body "Reverts <sha>. See WO <wo-id>. Redo will land via proper PR with CHANGELOG + version bump."
   ```
2. **Open a fresh WO** in `memory/shared/work-orders/` that frames the work as a real change request — what's the standard / agent / skill being added, what's the version impact, what's the CHANGELOG line, what's the consumer-side adoption story.
3. **Land the WO via the normal flow**: feature branch → CHANGELOG entry → frontmatter `version` bump on the affected file → PR → review → squash-merge → tag (if it's a standards release).
4. **Verify consumer pins** are aware: at minimum, mention the new tag in `STATE.md` and the backlog so future adoption WOs pick it up.

The redo is *not* a copy-paste of the original push. It's a re-authoring through the right gates. Reviewers will catch the missing context the original push skipped.

## Path B — Revert and migrate to the consumer repo

Use when the content is consumer-specific and never should have been in devteam.

1. **Set up the consumer repo first** if it doesn't exist yet. Follow [`project-bootstrap.md`](project-bootstrap.md):
   - Create a new repo for the consumer project.
   - Add devteam as a submodule at `.devteam/`, pin to the latest standards tag.
   - Wire the consumer's `CLAUDE.md`, `.claude/settings.json`, and per-project `memory/` layout.
2. **Copy the misplaced content from devteam into the consumer repo at its correct location:**
   - Prompt history / session transcripts → consumer's `memory/shared/prompt-history.md` (or wherever the consumer wants to keep them).
   - App-specific integration docs (paths, bench setup, app names) → consumer's `docs/` directory.
   - Source code, schemas, migrations → wherever the consumer's stack normally puts them.
   - Per-agent memory generated from consumer sessions → consumer's `memory/<agent>/`.
   Use `git show <sha>:<path>` to extract the file content cleanly from the offending commit on devteam.
3. **Revert the offending commit in devteam on a branch.** Same mechanics as Path A step 1 — never force-push `main`.
4. **Commit the migrated content in the consumer repo** with a clear message linking back to the devteam revert PR and the WO that tracked the migration.
5. **Confirm both sides land together.** The devteam revert PR and the consumer-side migration commit should be referenced in the migration WO's Result section so the audit trail is complete.

The point of Path B: the content isn't being destroyed, it's being moved to where it can be useful. A consumer's prompt history is genuinely valuable *in the consumer's repo* — it's the recipe for rebuilding that consumer's app from scratch.

## Path C — Split

Use when the offending commit mixed reusable patterns with consumer specifics.

1. **Revert the whole offending commit in devteam** (same as Path A / B step 1). It's easier to start from clean main and re-introduce just the reusable part than to surgically edit the original commit.
2. **Migrate the consumer-specific portion** to the consumer repo (Path B steps 1–4).
3. **Re-author the reusable portion** as a fresh WO + standards change (Path A steps 2–4). The new version is usually much shorter than the original because the consumer specifics are stripped out — that's correct.

## Things to avoid during recovery

- **Don't force-push `main`** to erase history. Use `git revert` on a branch and a PR. History stays auditable; the bad commit is undone by a new commit, not by rewriting the past.
- **Don't delete the offending content without migrating it first.** Even if it doesn't belong in devteam, the consumer probably wants it. Extract it from the bad commit into the consumer repo *before* the devteam revert PR merges.
- **Don't skip the WO.** Recovery is real work, with real handoffs (the contributor, the maintainer, the consumer-repo setup). A WO records what was done and why so the next person who makes the same mistake has a paper trail to copy from.
- **Don't merge the revert PR before the contributor has been looped in.** The point of the recovery flow is education as much as cleanup. The contributor should understand *why* their content is moving, so the same thing doesn't happen on the next push.
- **Don't reuse the original commit's `git author`.** The revert is a maintainer action; let `git revert` set authorship to whoever runs it. The original contributor's authorship is preserved in the reverted commit itself.

## Common variants

- **Direct push to `main` with content that's otherwise fine.** Still revert and redo via PR — the rule isn't "good content makes a direct push okay," it's "direct pushes never happen." Path A.
- **A new `standards/<topic>/` directory that's clearly app-specific** (paths, app names, bench setup). The directory name suggests it's a standard, but the body is documentation. Path B — it's consumer docs, not a standard.
- **A new `standards/<topic>/` directory that's genuinely reusable** but missing CHANGELOG / version bump / PR. Path A — same content, redone through the gates.
- **PR opened but with no CHANGELOG entry / version bump on a standards change.** Don't revert from main (it never landed). The reviewer requests changes; the PR author adds CHANGELOG + version bump in a new commit on the same branch. Recovery isn't needed — normal PR review caught it.

## After the recovery

- Update the devteam **`STATE.md`** to mark the incident closed and the revert PR / migration PR merged.
- Update the devteam **backlog** if the incident surfaces a process gap (e.g., "no branch protection on main" is the gap that lets direct pushes through; that's a follow-up, not a one-off).
- If the contributor was a new collaborator, point them to the [first-time-here entry in the README](../README.md#first-time-here-read-these-in-order) and [`project-bootstrap.md`](project-bootstrap.md) so the second push goes right.

## Related

- [`project-bootstrap.md`](project-bootstrap.md) — the playbook for consuming devteam correctly from a consumer repo. Prevents the situation this skill recovers from.
- [`git-workflow.md`](git-workflow.md) — branch / commit / PR / revert conventions.
- [`session-rituals.md`](session-rituals.md) — start- / mid- / end-of-session rituals; updating STATE after a recovery falls under end-of-session.
- [`../CLAUDE.md`](../CLAUDE.md) — the underlying rules (no direct pushes, standards changes require CHANGELOG + version bump).
