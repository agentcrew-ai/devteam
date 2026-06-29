---
name: git-workflow
description: Devteam project conventions for branching, commits, PRs, and reviews. Any agent or the foreman performing git operations should read this file before acting on the repo.
---

# Git Workflow — Devteam conventions

## Why this exists

Every change flows through a branch and a PR. No direct commits to the production branch (`main`/`master`) — work lands on `base_branch` (default `develop`) via PR, and `develop` promotes to prod via its own PR. This gives us:

- Clean history (one logical change per branch)
- Per-component blast radius
- A natural place for `code-reviewer` / `security` agents to weigh in
- Cheap revert if something regresses

## Where you operate (repo-agnostic)

This skill governs git flow in **whatever repo the work executes in**, not just devteam. Read the WO's frontmatter first:

- **`kind: project`** — `cd` into the WO's `repo` and do all git/file work *there*. Never branch or commit in devteam for project work; only the WO's Log/Result is written back to devteam. Follow the target repo's own branching standard (`standards/git/branching-and-pr-flow.md`) — its `prod_branch` may be `main` or `master`; check, don't assume.
- **`kind: meta`** — the work *is* devteam (roster, standards, skills). Operate in the devteam tree, using the conventions below.

In both cases, **branch from the WO's `base_branch` (default `develop`)**, never from the production branch.

## Branch naming

Branch from the WO's `base_branch` (default `develop`) unless you're explicitly stacking on an in-flight branch. The patterns below are devteam's (`kind: meta`) conventions; for `kind: project` work, defer to the target repo's branching standard.

| Purpose | Pattern | Example |
|---|---|---|
| New agent | `agent/<name>` | `agent/project-manager` |
| Update an existing agent | `agent/<name>-<short-desc>` | `agent/architect-add-tradeoffs` |
| New skill | `skill/<name>` | `skill/git-workflow` |
| Work-order-driven implementation | `wo/<wo-id>` | `wo/2026-04-11-001` |
| Bug fix | `fix/<short-desc>` | `fix/pdm-scope-drift` |
| Docs | `docs/<short-desc>` | `docs/roster-update` |
| Chore / tooling / infra | `chore/<short-desc>` | `chore/gitignore` |

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <subject>

<body — optional, the "why" not the "what">
```

**Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`

**Scopes** (project-specific):
- Agent name: `feat(architect): ...`, `fix(product-manager): ...`
- `workflow` — for CLAUDE.md, mantra, HITL rules, foreman behavior
- `wo` — for work order template or live WO changes
- `skill` — for skill files

**Subject rules:**
- Imperative mood ("add" not "added")
- Lowercase first word
- No trailing period
- Under 72 chars
- Describe intent, not the diff

**Body:**
- Only when the why isn't obvious from the diff
- Wrap at 72 chars
- Reference related WOs by ID if applicable

## PRs

One PR per branch. PR title = the main commit subject (or a clear roll-up if multiple commits).

### Description template

```markdown
## What
<one paragraph>

## Why
<one paragraph — motivation, user ask, or WO reference>

## How (only if non-obvious)
<bullets>

## Test plan
- [ ] ...

## Related
- WO: wo-YYYY-MM-DD-NNN (if applicable)
```

### Before opening a PR

- All committed files are intentional (no `.DS_Store`, no secrets, no accidental large files)
- Branch is up to date with `base_branch` (rebase preferred for clean history)
- `CLAUDE.md` roster status is updated if an agent was added / retired

### Merging

- **Squash merge** for agent / skill / docs branches (one logical unit → one commit on main)
- **Regular merge** for WO-driven implementation branches (preserves incremental history when useful)
- Delete the branch after merge

## HITL for git operations

Git actions that affect shared state are the kind of thing the foreman pauses for per `CLAUDE.md`'s decision-gated HITL rule.

**Always confirm with the user before:**
- `git push` (even to a feature branch — first push of a branch is a shared-state action)
- `gh pr create`
- `gh pr merge`
- Any destructive op (`reset --hard`, `push --force`, `branch -D`, `clean -fd`, etc.)

**Don't need to confirm (local, reversible):**
- `git init`, `git branch`, `git checkout`, `git switch`
- `git add`, `git commit`
- Read-only ops (`status`, `log`, `diff`, `ls-remote`)
- `git pull` / rebase from `base_branch` to stay current

## Code review loop

When a PR touches code (not just docs / agent prompts / skills), the **code-reviewer** agent should be invoked with the PR diff before the user is asked to approve the merge.

Security-sensitive changes (auth, secrets, network, dependencies) additionally get the **security** agent.

### Automation — nudge hooks (v1.1, 2026-04-23)

Project-level hooks in `.claude/settings.json` nudge the foreman toward the right dispatch at the right moment. They do **not** auto-dispatch subagents (Claude Code hook primitives don't cleanly support that yet); they surface a `systemMessage` reminder so the foreman is less likely to forget.

- **PostToolUse / `Bash(gh pr create:*)`** → reminds to dispatch `code-reviewer` on the diff and `security` if the PR touches auth / secrets / network / dependencies.
- **PostToolUse / `Bash(gh pr merge:*)`** → reminds to close out the WO tree (status + Result sections), rewrite `STATE.md` post-merge, and commit housekeeping on a `chore/` branch rather than directly on `main`.

The foreman still consciously dispatches — HITL on the merge itself stays untouched. Hooks are advisory; they catch the routine misses, not the judgment calls.

To disable temporarily: `/hooks` in the CLI and toggle off, or remove the entries from `.claude/settings.json` on a branch.

## Who does what

| Action | Who |
|---|---|
| Branch + commit during work | The working agent (or foreman on its behalf) |
| Push a branch | Foreman, after HITL confirmation |
| Open a PR | Foreman, after HITL confirmation |
| Review a PR | `code-reviewer` agent (+ `security` if relevant) |
| Merge | User, or foreman after explicit user approval |

## Quick reference for the foreman

When starting work on a new component:
0. Read the WO frontmatter — note `kind`, `repo`, `base_branch`. For `kind: project`, `cd` into `repo` first; for `kind: meta`, stay in devteam.
1. `git checkout <base_branch> && git pull` (default `base_branch` is `develop`)
2. `git checkout -b <branch-using-naming-convention>`
3. Do the work (edit files, possibly dispatch to subagents)
4. `git add <specific files>` — never `git add -A`
5. `git commit -m "<conventional commit subject>"`
6. **Pause → confirm push with user**
7. `git push -u origin <branch>`
8. **Pause → confirm PR creation with user**
9. `gh pr create` with the description template
10. Dispatch `code-reviewer` (if code changes)
11. **Pause → wait for user approval to merge**
