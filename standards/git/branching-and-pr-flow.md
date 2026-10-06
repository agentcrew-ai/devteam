---
version: 1.1.0
updated: 2026-10-06
breaking: false
---

# Git Branching & Pull-Request Flow

The branching model and merge discipline every repo under `~/Development/`
follows. This is **policy** — what is required and what is forbidden. The
step-by-step "how" (branch-naming tables, commit format, PR template, the
foreman's HITL checklist) lives in the `git-workflow` skill; this standard does
**not** duplicate it. When the skill and this standard disagree, **this standard
wins** and the skill is the bug.

## Principle

Production is reached **only through review.** Every change lands on the prod
branch via a reviewed pull request, opened from a short-lived topic branch that
was integrated first. No change reaches prod by a path a human did not approve.
The flow is what is standardized — not the branch names a given repo happens to
use.

## The pattern

Three tiers, work flowing one direction:
`feature/<slug>` (all work) → `develop` (integration) → `main`/prod (PR-only).

1. **`feature/<slug>` — all real work.** One branch per feature or release,
   branched from `develop`. Never pile unrelated work onto a single branch. In
   the devteam/standards repo the established equivalent is `standards/<topic>`
   (alongside the `agent/`, `skill/`, `fix/`, `docs/`, `chore/`, and `wo/`
   prefixes) — all valid topic-branch forms, treated identically.

2. **`develop` — shared integration target.** Topic branches land here first. If
   a repo has no `develop`, create it off the prod branch before starting
   feature work.

3. **`main` (prod) — PR-only.** Receives changes exclusively via reviewed PR.
   Prod is `main` on most repos and `master` where that is already the default —
   do not rename existing prod branches. When unsure which branch is prod:
   `git symbolic-ref refs/remotes/origin/HEAD`.

## Rules

- **`main`/prod is PR-only — always.** No direct commit, no push to prod, no direct or fast-forward merge from a local branch into prod. Cutting a branch from `main` and fast-forwarding it back into `main` is exactly the violation this standard forbids.
- **Agents and Claude Code sessions must NEVER merge or push to the prod branch.** This is absolute. An agent may *open* a PR; a human merges it, or explicitly instructs the merge within that session. An agent never runs `git push origin main`, `gh pr merge` against prod, or any equivalent on its own initiative. If the only way to land a change is to touch prod directly — stop and surface it.
- **PRs are the default merge path everywhere.** Into prod they are mandatory, no exception. Into `develop` they are preferred, and the agent that did the work opens *and* merges them itself (see "Ship by default" below). Where a repo has no PR flow, a direct `--no-ff` merge into `develop` is allowed. The prod gate is never negotiable.
- **One topic branch per feature or release.** Don't stack unrelated changes.
- **Create `develop` before feature work if it's missing** — off prod, as the first step.
- **Don't rename prod branches.** The standard governs the flow, not the name.

## Ship by default (added in 1.1.0)

Finished work that sits on a local branch is lost work. It can't be reviewed, deployed, or found by the next session, and it rots into merge conflicts. So below prod, agents ship without asking.

- **Commit and push after every working change.** Never end a session, or a turn of real work, with uncommitted or unpushed changes. Check the diff for credentials before every commit; a suspected secret stops the commit and gets reported, never pushed.
- **Merge `feature/*` → `develop` yourself** as soon as it works: open the PR and self-merge it, or merge directly with `--no-ff` where the repo has no PR flow. Don't wait for a human to review or merge into `develop`. Git can always revert.
- **Review is automated and its result is accepted.** Before the merge, run an automated review of the diff (a code-review agent, plus the repo's tests or build when they are cheap). Fix anything that breaks the build or the feature. Log everything else (style, polish, refactors) as follow-up work and merge anyway. A review never blocks a merge on style.
- **The bar is that it works.** Rough code that ships now and gets refactored later beats polished code that never leaves the branch.
- **Conflicts and red builds are the exception.** Resolve trivial conflicts (both sides added independent lines, a changelog, a list). On a conflict that needs a design choice, or a build that fails, push the branch, leave it unmerged, and report it to the repo owner. Never force-push and never delete a branch that isn't fully merged.
- **Prod stays deliberate.** `develop` → prod (and any further environment-promotion branches, such as `stage` → `prod`) is a human decision or an explicit instruction in that session. Ship-by-default never reaches prod.
- **A repo's own agent instructions win.** If a repo's `CLAUDE.md` (or equivalent) says humans merge, agents push the branch and open the PR, and stop there. If merging to `develop` deploys to a live environment, the repo should say so in that file, so a session knows what a merge triggers.

## Enforcement

This policy is binding whether or not any tooling enforces it — the behavioral
rule is the floor. Because server-side branch protection is unavailable on some
of our repos (private repos on a free organization plan cannot enable it), the
enforcement weight sits on the local and agent-side layers, applied in this
order of priority:

1. **Claude Code `PreToolUse` deny hook** (primary). A hook in `settings.json`
   intercepts every Bash tool call, resolves the session repo's prod branch
   dynamically from `origin/HEAD`, and **denies** any `git push`, `git merge`,
   or `gh pr merge` that would reach prod — fail-closed where the target can't
   be proven safe. This makes "agents NEVER push or merge to prod" physically
   unreachable in an agent session, regardless of the prompt. It is a true
   pre-execution deny, complementing — not duplicating — the advisory
   post-action nudges in the `git-workflow` skill.

2. **Local `pre-push` hook** (human guard). A shared hook, wired via global
   `core.hooksPath` (with a per-repo fallback), aborts any push whose
   destination ref is the repo's prod branch. It catches the human's accidental
   direct push, which the agent hook does not cover.

3. **GitHub branch protection / ruleset** (server-side backstop, where allowed).
   On repos whose plan permits it, require a PR + ≥1 approving review and block
   direct pushes and force-pushes to prod. Where the platform refuses it (free
   private-repo tier), record it as unavailable and rely on layers 1–2.

All three resolve the prod branch dynamically — never hardcoded — so `main` and
`master` repos are covered identically. The scripts and exact install steps are
an implementation appendix in `standards/git/enforcement/` (`README.md` plus the
`pre-push` and `guard-prod-push.sh` scripts); they are deliberately kept out of
this policy file.
