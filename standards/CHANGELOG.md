# Standards changelog

Every standards change is a version event: bump the affected file's frontmatter `version` and add an entry here. Consumers pin to a tag and read this to know what moved on upgrade. See [`../EXTENSION.md`](../EXTENSION.md) for the scrub gate that governs what may enter core.

## v0.1.0 — 2026-06-28 — initial open-core extraction

First public cut, extracted from an internal devteam repo and sanitized to generic core. No entity-specific infrastructure, identities, secrets, or history.

- `api/conventions.md`, `data/schema-conventions.md`, `security/*`, `git/*`, `frappe/patterns.md`, `saleor/SALEOR_INTEGRATION.md`, `knowledge/meta-logging-and-vault-writes.md` — carried over, scrubbed of named orgs, hostnames, and per-machine paths.
- `ci-cd/pipeline-pattern.md` — **new.** Stack-agnostic delivery contract (six guarantees) plus a sanitized Buddy + Helm + Kubernetes reference. Replaces an infra-specific CI/CD standard whose concrete how-to now belongs in consumer overlays.
- `EXTENSION.md` — **new.** Overlay precedence model and the scrub gate for contributing generic improvements upstream.
