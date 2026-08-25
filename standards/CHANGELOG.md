# Standards changelog

Every standards change is a version event: bump the affected file's frontmatter `version` and add an entry here. Consumers pin to a tag and read this to know what moved on upgrade. See [`../EXTENSION.md`](../EXTENSION.md) for the scrub gate that governs what may enter core.

## v0.2.0 — 2026-08-25 — writing voice and MCP server adoption

Two new standard families, both additive. Nothing existing changed, so a consumer pinned to v0.1.0 upgrades without edits.

- `writing/voice.md` — **new (v1.0.0).** How agent-drafted prose should read before a human sends it. Target voice, a word-swap table, the sentence constructions to avoid as recurring structure, and a scope boundary that puts prose humans read in and machine-parsed strings out. Specifies that the review pass reports and never rewrites, so the author writes the fix and the skill actually transfers.
- `tooling/mcp-servers.md` — **new (v1.0.0).** Adopting a Model Context Protocol server as an access-control decision before a configuration task. Identity model (per-person for attributed tools, scoped service account for unattended work, never a shared human login), config placement, the rule that a config file never holds a literal credential, verification that a listed server is actually running and acting as the expected identity, and revocation upstream rather than in config. Defers credential handling to `security/agent-secrets.md`.

## v0.1.0 — 2026-06-28 — initial open-core extraction

First public cut, extracted from an internal devteam repo and sanitized to generic core. No entity-specific infrastructure, identities, secrets, or history.

- `api/conventions.md`, `data/schema-conventions.md`, `security/*`, `git/*`, `frappe/patterns.md`, `saleor/SALEOR_INTEGRATION.md`, `knowledge/meta-logging-and-vault-writes.md` — carried over, scrubbed of named orgs, hostnames, and per-machine paths.
- `ci-cd/pipeline-pattern.md` — **new.** Stack-agnostic delivery contract (six guarantees) plus a sanitized Buddy + Helm + Kubernetes reference. Replaces an infra-specific CI/CD standard whose concrete how-to now belongs in consumer overlays.
- `EXTENSION.md` — **new.** Overlay precedence model and the scrub gate for contributing generic improvements upstream.
