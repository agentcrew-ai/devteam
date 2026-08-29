# Standards changelog

Every standards change is a version event: bump the affected file's frontmatter `version` and add an entry here. Consumers pin to a tag and read this to know what moved on upgrade. See [`../EXTENSION.md`](../EXTENSION.md) for the scrub gate that governs what may enter core.

## v0.3.0 — 2026-08-29 — Simplified Technical English folded into writing voice

Additive. `writing/voice.md` gains precision and density rules; nothing existing was removed or reworded, so a consumer pinned to v0.2.0 upgrades without edits.

- `writing/voice.md` — **v1.0.0 → v1.1.0.** Adopts the precision rules of [ASD-STE100 Simplified Technical English](https://www.asd-ste100.org/about_STE.html) — one word one meaning (and one thing one name), active voice with the actor named, one instruction per sentence for procedural text, a per-domain approved-term list kept in the overlay, and a ban on using one word as both noun and verb where the sentence parses two ways. Explicitly declines STE's closed ~900-word dictionary and its 20/25-word sentence caps as applied to analysis, with a section saying why: our writing has to argue and weigh, a maintenance manual does not. Adds four density rules — resolve your own references, one fact per paragraph stated once, borrowed jargon must earn its place, state the consequence or cut the paragraph — plus the rule underneath them, stop when the point is made. New Scope subsection grades how hard the precision rules bind by document type, from runbooks and agent-read order packets (hardest) to client-facing argument (lightest). Final-pass checklist expanded from six questions to ten.

## v0.2.0 — 2026-08-25 — writing voice, MCP server adoption, work intake

Three new standard families, all additive. Nothing existing changed, so a consumer pinned to v0.1.0 upgrades without edits.

- `writing/voice.md` — **new (v1.0.0).** How agent-drafted prose should read before a human sends it. Target voice, a word-swap table, the sentence constructions to avoid as recurring structure, and a scope boundary that puts prose humans read in and machine-parsed strings out. Specifies that the review pass reports and never rewrites, so the author writes the fix and the skill actually transfers.
- `tooling/mcp-servers.md` — **new (v1.0.0).** Adopting a Model Context Protocol server as an access-control decision before a configuration task. Identity model (per-person for attributed tools, scoped service account for unattended work, never a shared human login), config placement, the rule that a config file never holds a literal credential, verification that a listed server is actually running and acting as the expected identity, and revocation upstream rather than in config. Defers credential handling to `security/agent-secrets.md`.
- `workflow/work-intake.md` — **new (v1.0.0).** Where work comes from and what an agent owes the tracker while doing it. Every unit of work traces to a ticket; no ticket, no work. Two time-boxed exceptions (live-incident triage, feasibility spike). Work orders carry the ticket reference. Writes back at exactly three moments — start, blocker, completion — with a named object on the blocker, because a running commentary trains people to stop reading the board. Tool-agnostic; the tracker, key format, and status mapping are overlay concerns.

## v0.1.0 — 2026-06-28 — initial open-core extraction

First public cut, extracted from an internal devteam repo and sanitized to generic core. No entity-specific infrastructure, identities, secrets, or history.

- `api/conventions.md`, `data/schema-conventions.md`, `security/*`, `git/*`, `frappe/patterns.md`, `saleor/SALEOR_INTEGRATION.md`, `knowledge/meta-logging-and-vault-writes.md` — carried over, scrubbed of named orgs, hostnames, and per-machine paths.
- `ci-cd/pipeline-pattern.md` — **new.** Stack-agnostic delivery contract (six guarantees) plus a sanitized Buddy + Helm + Kubernetes reference. Replaces an infra-specific CI/CD standard whose concrete how-to now belongs in consumer overlays.
- `EXTENSION.md` — **new.** Overlay precedence model and the scrub gate for contributing generic improvements upstream.
