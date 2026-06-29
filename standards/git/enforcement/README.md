# Enforcement appendix — Git Branching & PR-Flow

Implementation detail for the [`branching-and-pr-flow.md`](../branching-and-pr-flow.md)
standard. The standard is the policy; this is how it's wired on a machine. The
policy binds regardless of whether any of this is installed.

`standards/git/enforcement/` is the **source of truth** for these scripts.
Installed copies (below) are deploy targets — keep them in sync from here.

## Layers (priority order)

Server-side branch protection is **unavailable** on private repos under a free
GitHub organization plan — the API returns HTTP 403.
So the local + agent-side layers carry the weight.

### 1. Claude Code `PreToolUse` deny hook — `guard-prod-push.sh` (primary)

Denies any `git push` / `git merge` / `gh pr merge` from an **agent session**
that would reach the repo's prod branch (resolved dynamically from `origin/HEAD`,
per the session `cwd`). Fail-closed where the target can't be proven safe. This
is the only layer that enforces "agents NEVER push/merge to prod."

Install (user-level — covers every repo in every session):
```bash
cp standards/git/enforcement/guard-prod-push.sh ~/.claude/hooks/guard-prod-push.sh
chmod +x ~/.claude/hooks/guard-prod-push.sh
```
Then add to the `PreToolUse` array in `~/.claude/settings.json` (and/or the
devteam project `.claude/settings.json` so adopting repos inherit it), appending
alongside any existing entry — do not replace it:
```json
{
  "matcher": "Bash",
  "hooks": [
    { "type": "command", "command": "~/.claude/hooks/guard-prod-push.sh" }
  ]
}
```
Hook contract: exit `0` + stdout JSON `hookSpecificOutput.permissionDecision:"deny"`.
Plain `exit 0` with no JSON = "no opinion" → normal permission flow, so all
non-prod git work is untouched.

### 2. Local `pre-push` hook — `pre-push` (human guard)

Aborts the **human's** direct push to prod (the gap layer 1 doesn't cover —
layer 1 only governs agent sessions).

Shared install via global `core.hooksPath` (covers all repos, no per-repo setup):
```bash
# AUDIT FIRST — core.hooksPath replaces per-repo .git/hooks globally:
find ~/Development -maxdepth 3 -path '*/.git/hooks/*' -type f ! -name '*.sample'
# If that's empty (no Husky/lefthook/pre-commit), it's safe to set:
mkdir -p ~/.config/git/hooks
cp standards/git/enforcement/pre-push ~/.config/git/hooks/pre-push
chmod +x ~/.config/git/hooks/pre-push
git config --global core.hooksPath ~/.config/git/hooks
```
Per-repo fallback (for any repo that has its own `.git/hooks`):
```bash
cp standards/git/enforcement/pre-push .git/hooks/pre-push && chmod +x .git/hooks/pre-push
```

### 3. GitHub branch protection / ruleset (server-side backstop, where allowed)

Attempt it; on the expected 403 (free private-repo tier) record "unavailable on
plan" and rely on layers 1–2. Resolve prod dynamically:
```bash
PROD="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
PROD="${PROD:-main}"
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# Ruleset form (preferred):
gh api -X POST "repos/$REPO/rulesets" --input - <<JSON
{
  "name": "prod-protected",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/$PROD"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "required_review_thread_resolution": false
      }
    }
  ]
}
JSON
```

## Rollout

1. **Layer 1 first** (today) — highest leverage, no platform dependency, the
   only enforcement of the agent rule. User-level, then mirror to project.
2. **Layer 2 second** — after the per-repo hooks audit above.
3. **Layer 3 opportunistic** — expect a 403 on free org private repos; revisit
   on plan upgrade or if a repo goes public.
