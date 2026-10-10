---
version: 1.0.0
updated: 2026-10-10
breaking: false
status: proposed
---

# Terraform conventions

How cloud infrastructure is declared with Terraform: repo layout, state, the identity Terraform runs as, secret inputs, and the guard that keeps a later change from destroying something that holds data. This standard governs **Terraform roots and modules**. Repo-resident secrets are [`security/sops-age.md`](../security/sops-age.md); runtime secret reads are [`security/agent-secrets.md`](../security/agent-secrets.md); backup of anything Terraform creates is [`backup-dr/`](../backup-dr/).

It assumes Terraform ≥ 1.6 and any provider. Examples use `azurerm` because its sovereign-cloud switch is the sharpest version of a rule that applies everywhere.

## Layout

```
terraform/
  envs/<env>/      one root module per environment; one state file each
  modules/<name>/  reusable modules; no provider or backend blocks
scripts/
  bootstrap.sh     one-time, re-runnable: what Terraform cannot create for itself
  tf.sh            the only way Terraform is run (sets identity, decrypts inputs)
  tf-plan-guard.sh plan + refuse deletes/replacements
secrets/<env>.sops.yaml   SOPS-encrypted secret inputs
```

- **One root per environment, never workspaces.** A directory per environment makes the blast radius of `apply` visible in the path.
- **Modules take inputs, roots take decisions.** Every CIDR, SKU, region and peer address is set in the root. Modules carry no environment-specific defaults.
- **Non-secret configuration lives in the root as `locals`, not in a `*.tfvars` file.** It is reviewed in the diff like any other code. `*.tfvars` stays gitignored so a real value never lands in one by accident.

## Providers and versions

- `required_version` and every provider pinned with `~>`, and `.terraform.lock.hcl` **committed**.
- **Cloud environment set explicitly on every provider and the backend** when the target is a sovereign or government cloud (`environment = "usgovernment"` for `azurerm`/`azuread`, the equivalent partition elsewhere). A resource created in the wrong cloud is a compliance defect, not a typo. The default is the commercial cloud, so omission is the failure.
- **Terraform does not register cloud resource providers or enable APIs.** Bootstrap does that once (`resource_provider_registrations = "none"` on `azurerm`). A plan that silently enables a service is a change nobody reviewed.

## State

- Remote backend in the same cloud and tenant the root manages, created by `bootstrap.sh`, never by Terraform itself.
- The state store has **versioning, soft delete, and a delete lock**, allows **identity-based auth only** (no shared keys or static access keys), and is reachable only by the Terraform identity and named humans.
- **State is a secret.** Any secret input passed to a resource (a VPN pre-shared key, a generated password) is stored in state in plaintext. Treat read access to state as read access to every secret it contains.
- Locking is the backend's native lock. Never `force-unlock` a lock you didn't create without confirming the other run is dead.

## Identity

- **Terraform runs as a dedicated non-human identity, always.** Not as a person, not even for the first apply. Humans run `scripts/tf.sh`, which authenticates as that identity.
- Prefer federated workload identity from CI; until CI exists, a **certificate** credential with ≤ 1-year expiry, private key held only in the password manager and materialised to a `mktemp -d` path for the duration of the run.
- **Least privilege that can't escalate.** Contributor-class rights on the scope it manages, plus the policy-writer role if it manages policy. If it must create role assignments, grant the role-assignment-writer role **with a condition restricting which roles it may assign** (data-plane and reader roles only). It never holds Owner, User Access Administrator, or unconditioned role-assignment rights.
- Directory/identity-plane configuration (conditional access, directory roles) is not in Terraform's identity's reach. It is managed by a separate identity and tool with its own review.

## Secret inputs

- Secret inputs are declared `sensitive = true` with no default, and supplied only as `TF_VAR_*` environment variables by `tf.sh`, decrypted from `secrets/<env>.sops.yaml` at run time.
- A flat secrets file encrypts **every value** (no `encrypted_regex`); it has no non-secret structure worth leaving readable.
- Never generate a secret with a Terraform resource whose value you then need outside Terraform. Generate it once, store it in SOPS, read it from there on both ends.

## Idempotency and the plan guard

A change made months later must not rebuild a VM, a gateway or a database, or drop data. Four layers, in order of how much they are relied on:

1. **The plan guard.** `tf-plan-guard.sh <env>` runs `plan -out`, reads `terraform show -json`, and exits non-zero if any resource change includes `delete` (which covers replace), unless that exact address is listed in `ALLOW_DESTROY`. Only a plan file that passed the guard is applied (`tf.sh <env> apply <plan>`). This is the control; the rest are backups for when someone bypasses it.
2. **`prevent_destroy`** on every stateful or address-bearing resource: networks, gateways, public IPs, key vaults, log workspaces, state stores, VMs, managed disks, databases.
3. **Cloud-side delete locks** on resource groups or accounts that hold data, owned by bootstrap or Terraform. Removing a lock is a deliberate, separate act.
4. **Shape resources so replacement is rare and cheap.** Static public IPs are their own resources so rebuilding what uses them keeps the address. VM data lives on separately declared disks. `ignore_changes` for attributes the platform mutates on its own, with a comment saying which and why.

## Drift and click-ops

- No portal changes without a matching change in the repo the same day: import the resource, or write the change and apply it so the plan returns to empty.
- `plan` against a quiet environment must show **no changes**. A non-empty plan with nobody changing anything is drift, investigated before the next apply.

## Review

- Every apply is preceded by a guarded plan whose summary line (`N to add, N to change, N to destroy`) is in the PR or change record.
- `terraform fmt -check` and `terraform validate` pass before review.

## Cross-references

- [`security/sops-age.md`](../security/sops-age.md): recipients, key custody, rekeying.
- [`security/agent-secrets.md`](../security/agent-secrets.md): how `tf.sh` obtains the identity credential and the SOPS key at run time.
- [`infra/helm.md`](helm.md): the workload layer that typically runs on what Terraform builds.
