# Backlog — devteam

_Running "later" list: ideas and deferred items. Not active work (that's `STATE.md`)._

## Documentation / adoption

- **Fold the layer-consumption symlink loop into `project-bootstrap.md`.** `TEAM-GUIDE.md` §2 introduces a consumer→shared-layer symlink loop (overlay-wins-over-base fallback). `project-bootstrap.md` currently only documents consuming the base directly. Absorb the nested-layer precedence loop there so there's one authoritative mechanics doc. (Gap surfaced while writing TEAM-GUIDE, 2026-07-14.)
- **Provide a starter template / bootstrap skill for a team layer repo** (a `team-layer-bootstrap` skill or a template skeleton: overlay dirs, stub `CLAUDE.md`, an example SME agent). Raised as the "scaffold + doc" option; deferred in favor of shipping the doc first.

## Standards — forward direction called out but not written

Four items the Helm and secrets standards name as the target end state without mandating them. Each is its own version event when it lands.

- **Secret decryption inside the GitOps controller.** A GitOps controller reconciling from git cannot natively decrypt SOPS-encrypted Secrets, so encrypted Secrets stay outside the controller's management and get applied by the pipeline instead. Evaluate a decryption plugin once a consumer's secret count makes hand-applied Secrets a real drift source, then write the pattern into `security/sops-age.md`.
- **Digest pinning for production images.** `infra/helm.md` recommends `@sha256:` references for production and does not mandate them, because the tag-plus-runtime-override pattern is auditable while its two conditions hold. Revisit mandating it if a consumer's registry ACLs or values history stop carrying the audit trail.
- **Automated certificate issuance.** `infra/helm.md` describes propagating one purchased certificate from a dedicated namespace. A controller that requests and renews from an ACME or internal CA satisfies the same section, but the standard does not yet describe choosing between them or migrating from one to the other.
- **Infrastructure-as-code conventions.** The `infra/` lane holds only `helm.md`. Declarative provisioning and configuration management (the Terraform-class and Ansible-class tools) have no standard. The lane was named `infra/` rather than `helm/` so these slot in beside it.

## Standards — gaps found in `security/sops-age.md`

Found while checking the archived SOPS work order against the shipped standard. All are additions to the existing file, not a second file; together they are one minor bump.

- **Pre-commit hook is neither mandated nor shipped.** The standard has no defense against a plaintext secret reaching a commit in the first place. Mandate a hook and ship a copy-pasteable `.pre-commit-config.yaml` snippet using `gitleaks`.
- **No rotation policy.** The standard covers rekeying when the recipient set changes and says nothing about when to rotate the underlying secrets. Codify trigger-based rotation — departure, suspected compromise, key age — rather than a scheduled cadence nobody honours.
- **Offboarding stops at rekeying.** Removing a recipient and running `sops updatekeys` does not invalidate anything that recipient already decrypted. State the rotation trigger that follows a departure.
- **No `.gitignore` guidance** for decrypted-on-disk artifacts, and no stated review expectation that a PR touching an encrypted file gets a security pass.
- **Internal tension in the current text.** The standard says never decrypt to a plaintext file on disk, then the pipeline-time example does exactly that to a tmp path and removes it. Both are right; the rule needs the tmp-path carve-out written into it so a reader does not have to reconcile them.
- **No cross-reference to `infra/helm.md`.** The Helm standard links to `sops-age.md`; the reciprocal link is missing.

## Process / hygiene

- Reconcile `develop` behind `main` (backup-dr merged straight to main) — see STATE.md open items.
- Approve or revise the `PROPOSED` backup-dr standard (version event, maintainer's call).
- Delete merged `origin/standards/backup-dr` branch.
- **Branch lineage is three-way split.** `develop` is at CHANGELOG v0.1.0, `main` at v0.2.0, and the `chore/public-scrub` line at v0.3.1. Two different standards shipped as v0.2.0 on different branches (backup-dr on `main`, writing voice on the scrub line). Reconcile the lineage and the duplicated version number before the next tag.
