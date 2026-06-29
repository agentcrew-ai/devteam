#!/usr/bin/env bash
# guard-prod-push.sh — Claude Code PreToolUse deny hook.
# DENIES any Bash command that would push or merge into the repo's prod branch.
# Agents may OPEN a PR; a human merges. This is absolute per the
# Git Branching & PR-Flow standard. Resolves prod dynamically from the repo
# at the session's cwd (main on most repos, master on some).
#
# Contract: PreToolUse. Emit deny via stdout JSON + exit 0. Anything else
# (exit 0, no JSON) = no opinion -> normal permission flow.

set -uo pipefail

input="$(cat 2>/dev/null)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
[ "$tool" = "Bash" ] || exit 0

cmd="$(printf '%s' "$input"  | jq -r '.tool_input.command // empty' 2>/dev/null)"
cwd="$(printf '%s' "$input"  | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0
[ -n "$cwd" ] || cwd="$PWD"

# Resolve THIS repo's prod branch (cwd may be any subdir under ~/Development).
prod="$(git -C "$cwd" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
[ -n "$prod" ] || prod="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)"
[ -n "$prod" ] || prod="main"

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# Normalize whitespace for matching.
c="$(printf '%s' "$cmd" | tr '\n' ' ' | tr -s ' ')"

# --- gh pr merge: deny if it targets prod, OR if branch is unspecified ---
# (unspecified == merges the PR for the *current* branch; fail closed.)
if printf '%s' "$c" | grep -Eq '(^|[;&|]| )gh +pr +merge( |$)'; then
  if printf '%s' "$c" | grep -Eq -- "(^|[[:space:]])${prod}([[:space:]]|$)"; then
    deny "Blocked: 'gh pr merge' targeting prod branch '$prod'. Prod is PR-only and only a human merges. Leave the PR open; ask the user to merge."
  fi
  deny "Blocked: 'gh pr merge' — agents must never merge to prod. A human merges. If this is a non-prod merge, the user should run it."
fi

# --- git push: deny if any token resolves to prod, or push targets HEAD while on prod ---
if printf '%s' "$c" | grep -Eq '(^|[;&|]| )git +push( |$)'; then
  if printf '%s' "$c" | grep -Eq -- "(^|[[:space:]:])${prod}([[:space:]:]|$)"; then
    deny "Blocked: 'git push' to prod branch '$prod'. Prod is PR-only; agents never push to prod. Push your topic branch and open a PR."
  fi
  if [ "$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "$prod" ] \
     && ! printf '%s' "$c" | grep -Eq -- '[[:space:]]HEAD:'; then
    if ! printf '%s' "$c" | grep -Eq -- '[[:space:]]origin[[:space:]]+[A-Za-z0-9._/-]+'; then
      deny "Blocked: 'git push' with no ref while checked out on prod '$prod' would push prod. Switch to a topic branch first."
    fi
  fi
fi

# --- git merge INTO prod (run while on prod) ---
if printf '%s' "$c" | grep -Eq '(^|[;&|]| )git +merge( |$)'; then
  if [ "$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "$prod" ]; then
    deny "Blocked: 'git merge' while checked out on prod '$prod'. Prod only receives changes via reviewed PR, merged by a human."
  fi
fi

exit 0   # not a prod-affecting push/merge -> no opinion
