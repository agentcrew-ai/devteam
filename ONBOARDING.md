# Adopting devteam in your project

This is the short, teammate-facing version of how to pull the **devteam** Claude Code roster + standards into one of your own projects. The authoritative, detailed playbook is [`skills/project-bootstrap.md`](skills/project-bootstrap.md) — read it once before your first adoption. This page gets you oriented and unblocked fast.

## What you're adopting

devteam is a reusable roster of **11 Claude Code subagents** (product-manager, architect, project-manager, four implementer lanes, three reviewer lanes, documenter) plus a set of **enforcement-gated org-wide standards** (`standards/`). You consume it as a **git submodule** pinned to a release tag — you never fork it or copy its contents. Agents coordinate through **work orders**, not shared chat context.

The deal: your project gets specialized roles, a clean PdM→architect→PjM planning chain, and standards that are set once and stay set — and in return you keep devteam read-only from your side and push any standards improvements back upstream (never diverge silently).

## The 6-step adoption

Run these from your **consumer project root** (not from inside devteam). Full detail + the agent-discovery symlink loop are in [`skills/project-bootstrap.md`](skills/project-bootstrap.md) — don't skip it, the symlink step is load-bearing.

1. **Add the submodule:** `git submodule add git@github.com:agentcrew-ai/devteam.git .devteam` then `git submodule update --init --recursive`.
2. **Pin to the latest release tag** (`cd .devteam && git fetch --tags && git checkout <LATEST_TAG> && cd ..`, then commit the pin). **Pin to a tag, never to a moving branch** — see "Which tag" below.
3. **Symlink the agents into discovery:** Claude Code only discovers agents from `.claude/agents/*.md`. Run the symlink loop in `project-bootstrap.md` so the roster is invocable. Re-run it whenever you bump the pin.
4. **Wire your consumer `CLAUDE.md`** to import `.devteam/CLAUDE.md` (mantra, foreman triage, WO rules, standards enforcement) and add your project's own identity + state-file locations.
5. **Set up per-project state** under your repo's `memory/` (`STATE.md`, `backlog.md`, `work-orders/`, per-lane memory dirs) — **never inside `.devteam/`**.
6. **Open an adoption work order** in your repo's `memory/shared/work-orders/` to track the rollout (and again every time you upgrade the pin).

## Which tag to pin to

Pin to the **latest release tag** — check `git tag --sort=-creatordate` in the submodule, or the [releases page](https://github.com/agentcrew-ai/devteam). Tags carry the hardened, promoted standards; `develop` may be ahead but is not a stable adoption target.

When devteam cuts a new release, upgrade with `git submodule update --remote`-style retargeting to the new tag and **open an adoption WO** — a new release can carry a `breaking: true` standard change you must comply with. The upgrade flow + adoption-WO template are in `project-bootstrap.md`.

## The one hard rule: `.devteam/` is read-only from your side

Never commit into the submodule from a consumer project. If you find yourself wanting to write something into `.devteam/`, it belongs in *your* repo instead:

| Don't put in `.devteam/` | Put it here |
|---|---|
| Your prompt history, transcripts, session notes | your repo's `memory/` |
| App-specific how-to docs (named app/paths/bench) | your repo's `docs/` |
| Your source, schemas, migrations, fixtures | your repo |
| A new `standards/<topic>/` you invented locally | open a WO **against devteam**; let it land via PR + CHANGELOG + version bump + tag, then bump your pin |

If you already pushed something into devteam that shouldn't be there, [`skills/recovery.md`](skills/recovery.md) is the migrate-it-out playbook.

## Standards flow down, improvements flow up

Your agents **read** `.devteam/standards/` (each lane reads the standards relevant to it) but never edit them. If your work reveals a gap or a better method, that's a **bottom-up contribution**: open a WO against the devteam repo proposing the change with a version bump — a maintainer approves the version event. This is how the standards improve in both directions. The detail is in `CLAUDE.md` → "Report up."

## Questions / problems

- Full playbook: [`skills/project-bootstrap.md`](skills/project-bootstrap.md)
- Operating rules + the WHAT/HOW/WHO mantra: [`CLAUDE.md`](CLAUDE.md)
- Git flow (feature → develop → prod, never push to prod directly): [`skills/git-workflow.md`](skills/git-workflow.md)
- Open an issue or ping a maintainer for write access, release timing, or anything that smells like it needs a standards decision.
