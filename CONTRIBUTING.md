# Contributing to devteam core

devteam core is **generic and public**. The bar for landing something here is: *would this help any team running Claude Code, with zero of your organization's specifics attached?* If not, it belongs in your overlay, not core — see [`EXTENSION.md`](EXTENSION.md).

## Branch & PR flow

- Never push directly to the production branch. Every change is a feature branch → PR.
- Branching follows [`standards/git/branching-and-pr-flow.md`](standards/git/branching-and-pr-flow.md): `feature/<slug>` → `develop` → prod.
- One logical change per commit; conventional commit messages; specific file paths (never `git add -A` blindly).

## Standards changes are version events

Any change under `standards/` requires **both**:
1. A frontmatter `version` bump on the affected file (and `breaking: true` if a consumer pinned to the prior tag could break).
2. A matching entry in [`standards/CHANGELOG.md`](standards/CHANGELOG.md).

A standards PR without a version bump + changelog entry is rejected on principle — consumers pin to tags and rely on the changelog to know what moves on upgrade. This is the whole point of the enforcement gate.

## The scrub gate — contributing from a downstream overlay

If your private overlay produced something generic worth upstreaming (a new stack standard, a sharper pattern, a missing agent role), it must pass **every** check before it can enter core. The full checklist lives in [`EXTENSION.md`](EXTENSION.md#the-scrub-gate--what-may-go-upstream); in brief:

- No infrastructure specifics (hostnames, clusters, namespaces, registries, IPs).
- No identities (org names, push identities, employee or client names, project names).
- No secrets or secret *locations* (values, vault/secret-manager item names, key paths). Illustrative variable *names* are fine.
- No per-machine paths (`/Users/<name>/...` → `~/...` or `<repo>/...`).
- No internal history (dated rulings, decision-log refs, work-order ids, "we learned this on <date>" provenance). State the rule, not the war story.
- Concrete examples allowed only with every specific as a placeholder (`<your-org>`, `<registry>`, `<cluster>`).
- Versioned per the rule above.

A maintainer reviews each PR against this list. The gate is what lets core grow from real-world use without ever leaking the entity context that made the lesson concrete.

## What does NOT belong in core

Application code, schemas, migrations, fixtures; consumer prompt history or transcripts; app-specific how-to docs; anything that names one org, one cluster, or one client. All of that is overlay material. If you're tempted to add it here, you want your overlay (or a consumer repo with core as a submodule) — see [`EXTENSION.md`](EXTENSION.md) and [`skills/project-bootstrap.md`](skills/project-bootstrap.md).
