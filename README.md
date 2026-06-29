# devteam

A reusable, open-core roster of **Claude Code subagents** plus **enforcement-gated engineering standards** that drops into any project as a git submodule.

Eleven specialized agents — product manager, architect, project manager, four implementer lanes (backend, frontend, data, infra-devops), three reviewer lanes (code-reviewer, security, test-engineer), and a documenter — coordinate through **work orders** (files on disk), never by sharing conversation context. Each agent is a black box with a scoped tool allowlist, its own persistent memory directory, and a pinned model.

The standards (`standards/`) are versioned and enforcement-gated: every change is a version bump plus a `CHANGELOG.md` entry, so a consumer pinned to a tag knows exactly what moves when they upgrade.

## Open-core model

This repository is the **generic, public core**. Your organization's private context — client names, infrastructure, secrets, internal decisions — never lives here. Instead you **layer an overlay** on top of pinned core: additive files (a new stack standard, a new agent role) or overrides (your team's version of a lane), with private context kept entirely in your overlay. Generic improvements flow *back* to core through a scrub gate so every consumer gets stronger.

The full layering and contribution contract is in **[`EXTENSION.md`](EXTENSION.md)** — read it before adding anything.

## The core mantra

> **Product manager = WHAT. Architect = HOW. Project manager = WHO.**

Non-overlapping ownership keeps work orders clean and context tight.

## Adopt it

Read **[`skills/project-bootstrap.md`](skills/project-bootstrap.md)** for the full path. In short:

1. Add core as a submodule at `.devteam/`, pinned to a release tag.
2. Symlink the agent files into `.claude/agents/` for discovery.
3. Wire your project's `CLAUDE.md` to import core's operating instructions.
4. Layer your own standards/agents/context per [`EXTENSION.md`](EXTENSION.md).

## Layout

```
devteam/
├── .claude/agents/  # 11 agent definitions
├── skills/          # session rituals, project bootstrap, agent build, git workflow, recovery
├── standards/       # enforcement-gated, versioned conventions (api, data, security, git, ci-cd, ...)
├── EXTENSION.md     # the overlay + contribution contract
├── CONTRIBUTING.md  # PR flow + the scrub gate for upstreaming
└── LICENSE          # MIT
```

## Contributing

Never push directly to the production branch — every change is a feature branch + PR. Standards changes require a frontmatter `version` bump and a `CHANGELOG.md` entry. Downstream consumers proposing a generic improvement: run it through the scrub gate in [`EXTENSION.md`](EXTENSION.md) first. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

MIT — see [`LICENSE`](LICENSE).
