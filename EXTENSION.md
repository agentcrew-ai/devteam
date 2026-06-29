# Extending devteam — the overlay & contribution contract

devteam core is **generic and public**. Your organization's standards, stacks, agents, and private context live in an **overlay** that layers on top of core *without editing it*. This file defines exactly how that layering works, what is safe to contribute back to core, and how to add a new stack (Docker, bare-metal installs, a different CI tool) the project's way.

The whole model in one sentence: **pin core as a read-only dependency, layer your own files beside it, and only ever send *generic* improvements back upstream.**

## The three moves

### 1. Consume core (pin it)

Add core as a git submodule at `.devteam/`, pinned to a tagged release so your agents and standards don't move underneath you. Full mechanics are in [`skills/project-bootstrap.md`](skills/project-bootstrap.md). Core is **read-only** from inside a consumer — never commit into `.devteam/`.

### 2. Layer your own (the overlay)

Your additions live **outside** `.devteam/`, in an overlay that mirrors core's directory shape. The overlay is either the consuming repo itself or a dedicated private "entity layer" repo that other repos consume in turn.

```
your-repo/
├── .devteam/                    # core submodule — pinned, read-only
│   ├── .claude/agents/          # core's generic roster
│   ├── skills/
│   └── standards/
└── .devteam-overlay/            # YOUR layer — additive + overrides, never touches core
    ├── .claude/agents/          # new roles, or overrides of a core agent's lane
    ├── skills/
    ├── standards/               # new stacks (docker, bare-metal, your CI tool) or overrides
    └── context/                 # entity-private: memory, work-orders, decisions — NEVER goes to core
```

### 3. Contribute generic improvements back (the scrub gate)

If your overlay produces something **generic** — a new stack standard, a sharper pattern, a missing agent role — send it up so every consumer gets stronger. This is gated; see [the scrub gate](#the-scrub-gate-what-may-go-upstream) below. Entity-specific material **never** goes up — it stays in your overlay's `context/`.

## Precedence — how core and overlay combine

A consumer resolves each file **by relative path**, overlay winning:

- **Overlay path not present in core → it ADDS.** A `standards/ci-cd/docker-compose.md` that core doesn't ship becomes a new standard for your projects.
- **Overlay path also present in core → it OVERRIDES.** A `.claude/agents/backend.md` in your overlay replaces core's `backend.md` lane for your projects.

This is the same precedence Claude Code already uses when a project-level `.claude/agents/` entry shadows a user-level one — generalized to standards and skills. When you override rather than add, prefer overriding the *smallest* unit (one standard, one agent) so you keep inheriting core's improvements everywhere else.

## What is core (generic) vs. overlay (entity)

The boundary is the entire point. If something names your infrastructure, your clients, your secrets, or your internal history, it is overlay — never core.

| Belongs in **core** (public, generic) | Belongs in **overlay** (private, entity-tied) |
|---|---|
| Role definitions, lane boundaries, the WHAT/HOW/WHO mantra | Which agent your team routes a given domain to |
| A *pattern* for a stack (the contract a CI pipeline must satisfy) | Your registry hostnames, cluster names, namespace names, push identities |
| Tool-agnostic conventions (branching, schema, secrets handling) | 1Password/vault item names, secret values, age-key locations |
| A worked **reference example** with all specifics replaced by placeholders | Dated internal rulings, decision logs, work-orders, STATE/backlog |
| Skills (session rituals, project bootstrap, agent build) | Client names, project names, employee names, per-machine paths |

## Adding a new stack (worked example)

Say a downstream team deploys with plain **Docker Compose** on a single host instead of the Buddy + Helm + Kubernetes reference core ships.

1. Read core's generic CI/CD **pattern** standard — the part that states the contract every delivery path must satisfy (build boundary, image provenance, secret injection rule, push-to-deploy, ownership split). The contract is stack-agnostic on purpose.
2. Write `.devteam-overlay/standards/ci-cd/docker-compose.md` that satisfies that contract for Docker Compose. Follow the same frontmatter + versioning shape core uses.
3. Point your consuming repos' `infra-devops` lane at the overlay standard. Because the overlay adds (core ships no `docker-compose.md`), nothing in core changes.
4. **If it's genuinely generic** — true for any team using Docker Compose, with zero entity specifics — run it through the scrub gate and PR it to core so it ships for everyone. **If it bakes in your host, your registry, your paths** — it stays in your overlay.

The same recipe adds new **agents** (a `ml-engineer.md` role), new **skills**, or a different CI tool entirely. Core defines the contract; overlays satisfy it however the team deploys.

## The scrub gate — what may go upstream

Before any overlay file is PR'd into core, it must pass **every** check. If any fails, it stays in your overlay.

- [ ] **No infrastructure specifics** — no hostnames, cluster names, namespace names, registry URLs, IPs, or DNS.
- [ ] **No identities** — no org names, push identities, employee names, client names, project names.
- [ ] **No secrets or secret *locations*** — no values, no vault/1Password item names, no key file paths. Variable *names* used as illustration are fine (`$DEPLOY_TOKEN`); pointers to where the real value lives are not.
- [ ] **No per-machine paths** — no `/Users/<name>/...`; use `~/...` or `<repo>/...`.
- [ ] **No internal history** — no dated rulings, decision-log references, work-order IDs, or "we learned this on <date>" provenance. State the rule, not the war story.
- [ ] **Generalized, with specifics as placeholders** — a concrete reference example is welcome *if* every specific is a placeholder (`<your-org>`, `<registry>`, `<cluster>`, `<namespace>`).
- [ ] **Versioned** — frontmatter `version` bump + a `standards/CHANGELOG.md` entry, per core's enforcement gate. A change without a version bump is rejected on principle, not merged.

A maintainer reviews the PR against this list. The gate exists so the public core can grow from real-world use without ever leaking the entity context that made the lesson concrete.

## Related

- [`skills/project-bootstrap.md`](skills/project-bootstrap.md) — submodule wiring, agent-discovery symlinks, per-project state layout, upgrade path.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — PR flow, branch rules, and the version-bump requirement the scrub gate references.
- [`standards/CHANGELOG.md`](standards/CHANGELOG.md) — the authoritative record of what changed between core releases.
