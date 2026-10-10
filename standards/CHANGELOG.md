# Standards changelog

Every standards change is a version event: bump the affected file's frontmatter `version` and add an entry here. Consumers pin to a tag and read this to know what moved on upgrade. See [`../EXTENSION.md`](../EXTENSION.md) for the scrub gate that governs what may enter core.

_v0.6.0 and v0.7.0 were drafted in parallel as v0.2.0 and v0.3.0 on a branch cut from `main`; they were renumbered when that branch merged into `develop` on 2026-10-06 so release labels stay monotonic. Only `v0.1.0` had been tagged, so no published label moved._

## v0.9.0 — 2026-10-10 — Terraform conventions (PROPOSED)

Additive. One new standard in the existing `infra/` lane; nothing existing changed, so a consumer pinned to v0.8.0 upgrades without edits.

- `infra/terraform.md` — **new (v1.0.0, proposed).** Repo layout (one root per environment, modules without provider/backend blocks, non-secret config as root `locals` rather than `*.tfvars`). Providers pinned with the lockfile committed, the cloud environment set explicitly on every provider and backend for sovereign targets, and resource-provider registration left to bootstrap. Remote state with versioning, soft delete, a delete lock and identity-only auth, and the rule that state is a secret because secret inputs land in it. Terraform always runs as a dedicated non-human identity (federated from CI, or a ≤1-year certificate held in the password manager until CI exists) with role-assignment rights only under a condition limiting which roles it may grant. Secret inputs are `sensitive` variables fed from a SOPS file by a wrapper script. Idempotency as four layers led by a plan guard that refuses any plan containing a delete or replace unless the address is named, backed by `prevent_destroy`, cloud delete locks, and resource shapes that make replacement rare. Same-day reconciliation of any portal change, and a quiet `plan` must be empty.

## v0.8.0 — 2026-10-06 — ship by default below prod

- `git/branching-and-pr-flow.md` — **v1.0.0 → v1.1.0.** Adds a "Ship by default" section: agents commit and push every working change, and open *and* self-merge `feature/*` → `develop` without waiting for a human. Review before the merge is automated (review agent plus cheap tests or build); its result is accepted, so build breakers get fixed and everything else is logged as follow-up work instead of blocking. Trivial conflicts are resolved; design conflicts and red builds leave the branch pushed and unmerged and get reported. Prod (and environment-promotion branches like `stage`/`prod`) is unchanged and stays human-gated, and a repo whose own agent instructions say "humans merge" keeps that rule. The "PRs are the default merge path" rule is reworded to match: PRs into `develop` are still preferred, but the agent merges them itself. Surfaced from a real gap: finished work was piling up on local feature branches nobody was authorized to push or merge, so tasks never left in-progress. Non-breaking for consumers (the prod gate and enforcement layers are untouched); the Rules section was reflowed to one line per paragraph.

## v0.7.0 — 2026-07-14 — CI↔VCS integration onboarding as a first-class precondition

- `ci-cd/pipeline-pattern.md` (0.1.0 → 0.2.0) — **revised.** Codifies the onboarding precondition that a pipeline can only build a repo the CI tool can *reach*: before authoring a pipeline, verify the CI tool's VCS integration is authorized for the repo's org/namespace; if it can't, the environment owner installs/authorizes it (a tool-hosted git mirror is a fallback, not the default). Adds a new "Onboarding a repo to the CI tool" subsection, folds the CI↔VCS integration into guarantee 6's environment-owner list, and adds an anti-pattern against re-deriving repo reachability per pipeline. Surfaced from a real recurring gap: this precondition was undocumented, so sessions repeatedly re-derived "how does the CI tool reach this repo?" from scratch — sometimes wrongly assuming a mirror was required — burning a session each time. Non-breaking (additive; entity specifics stay in consumer overlays).

## v0.6.0 — 2026-07-11 — add backup & recovery standard

- `backup-dr/backup-and-recovery.md` — **new.** Stack-agnostic backup/DR contract (seven guarantees) plus a sanitized "logical dump → object storage on Kubernetes" reference. Codifies the rule "redundancy is not backup" and requires restore-verification on a recurring cadence, least-privilege secret-managed credentials, retention, and documented blast-radius independence. Surfaced from a real gap: a production CouchDB (Obsidian LiveSync backend) was found running with synchronous block-replication but **zero backups** — replication was masquerading as durability. Non-breaking (additive).
## v0.5.0 — 2026-08-29 — probe defaults for slow-booting containers

Additive. `infra/helm.md` gains concrete probe rules; nothing existing was removed or reworded, so a consumer pinned to v0.4.0 upgrades without edits.

- `infra/helm.md` — **v1.0.0 → v1.1.0.** The `## Health probes` section grows from three paragraphs to six subsections. `timeoutSeconds` must be set explicitly on every probe with a floor of 3 seconds, because the Kubernetes default of 1 second is missed routinely by a healthy process on a host under I/O or scheduling pressure — a probe that times out faster than the node's worst-case scheduling latency reports the node's state as the application's. A `startupProbe` is now preferred over `initialDelaySeconds` for any container whose cold start is slow or variable, since a fixed delay is a guess at a variable number and is wrong in both directions; and once a `startupProbe` exists, `initialDelaySeconds` on readiness and liveness is dead config that must be removed. A probe's tolerance is stated as the budget it actually is, `failureThreshold` × `periodSeconds` in seconds, chosen against measured cold start rather than a round number, so a reviewer can disagree with it without doing arithmetic. Liveness must be strictly more forgiving than readiness, because readiness removing a pod from a Service is cheap and reversible while liveness killing it is neither. Adds the diagnostic that a crash loop under host pressure with no application error in the logs is a probe-tuning symptom, not an application bug — read the chart before the code.

## v0.4.0 — 2026-08-29 — Helm chart conventions

Additive. One new standard in a new lane; nothing existing changed, so a consumer pinned to v0.3.1 upgrades without edits.

- `infra/helm.md` — **new (v1.0.0).** How a workload is packaged as a Helm chart, versioned, configured per environment, and validated before it reaches a cluster. Chart lives with the app; `apiVersion: v2` and the required `Chart.yaml` fields; chart `version` versus `appVersion` as two different numbers with separate bump rules; the three configuration layers (`values.yaml` baseline that declares every key with a safe default, `values-<env>.yaml` carrying overrides only, runtime `--set` for what the build alone knows) with named values rather than array indices. Documents the mutable-tag-plus-runtime-override image pattern and the two conditions that make its audit trail hold, and recommends digest pinning for production as the forward direction rather than mandating it. Hard ban on secret material in charts and values files, with the reference pattern and a cross-reference to `security/sops-age.md`. TLS as a `kubernetes.io/tls` Secret held in one dedicated namespace and propagated by a reflector-class controller, described as a shape with the controller left to the overlay. Pod Security Admission labels starting at `enforce: baseline` with `audit`/`warn` at `restricted` so the ratchet is cheap, and `runAsNonRoot`, `fsGroup`, `seccompProfile` mandated for new charts with an audit recommendation for existing ones rather than a sweep. Standard label set plus one overlay-defined tenant label. GitOps as an app-of-apps root with per-tenant project scoping, `app-<workload>.yaml` child naming, and manual sync as the default. A lint-and-validate gate (`helm lint`, then `helm template` piped to a schema validator such as `kubeconform` with `-strict`) run against every environment's values file. Probe guidance separating readiness from liveness, including the trap that `/` is not a healthcheck path for a static site.

The lane is `infra/`, not `helm/`, so future infrastructure conventions slot in beside it.

`CLAUDE.md` § How agents use standards now lists `standards/infra/` in the `infra-devops` required-reading line.

## v0.3.1 — 2026-08-29 — retroactive scrub of the public core

Patch. Three standards had entity-specific material that the scrub gate in [`../EXTENSION.md`](../EXTENSION.md) already forbids but that predated it being applied retroactively. Nothing behavioural changed, so a consumer pinned to v0.3.0 upgrades without edits.

- `security/sops-age.md` — **v1.0.0 → v1.0.1.** The example `.sops.yaml` used a maintainer's first name as a key anchor; it is now `&maintainer`. The break-glass backup destination named a specific password manager; it now names the class of tool. Removed a dated internal ruling from the one-recipient-per-repo rule — the rule stands on its own without the war story.
- `security/agent-secrets.md` — **v1.1.0 → v1.1.1.** Removed the dated approval and internal ruling number from the CI-store carve-out. The carve-out is unchanged.
- `knowledge/meta-logging-and-vault-writes.md` — **v1.0.0 → v1.0.1.** The sandbox switch was illustrated with a product-specific environment-variable prefix; it now uses `<PREFIX>`. Replaced an unexplained private cross-reference key name with the generic term "identifier".

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
