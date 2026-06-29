---
version: 0.1.0
updated: 2026-06-28
breaking: false
---

# CI/CD delivery pattern (stack-agnostic)

This is the **contract** every delivery path must satisfy, independent of which CI tool, registry, or runtime you use. It defines *what* a pipeline must guarantee, not *how* a specific tool does it. A concrete, fully-worked reference (Buddy + Helm + Kubernetes) is sketched at the end with every infra specific replaced by a placeholder — copy it into your overlay and fill in your own values. To add a different stack (Docker Compose, bare-metal, a serverless target), write an overlay standard that satisfies this same contract; see [`EXTENSION.md`](../../EXTENSION.md).

## The contract — six guarantees

A delivery path is compliant when it guarantees all six:

1. **A single build boundary.** There is exactly one place where source becomes a deployable artifact (an image, a bundle, a package). Builds happen *there* — never on a developer's machine, never by hand. The boundary is auditable and reproducible from the repo alone.

2. **Artifact provenance.** Every artifact is tagged with the exact build that produced it (commit/execution id), pushed to a known registry, and immutable. `latest` is a convenience pointer, never the deploy reference.

3. **Push-to-deploy, not click-to-deploy.** Deployment is triggered by a push to a designated branch, reading pipeline-as-code from the repo. Console/GUI edits to a pipeline are non-authoritative and get overwritten by the next sync. Manual API "run this" triggers are a smell — they skip the source checkout the build depends on.

4. **A deploy identity scoped to the smallest blast radius.** The credential the pipeline deploys with is scoped to exactly the target it deploys to (one namespace, one project, one environment) — never a cluster-admin or org-wide token. Anything the scoped identity *cannot* do is provisioned ahead of time by whoever owns the environment.

5. **Secrets injected at deploy time, never baked into the artifact.** Secret *values* live in the CI tool's encrypted variable store or a secrets manager, are injected when the workload starts, and are authoritative over any in-repo defaults. Decrypted material never persists in the build workspace — it is removed before the action exits. In-repo config holds dev/local defaults only.

6. **An explicit ownership split.** The repo states what the *environment owner* provides (the namespace/project, the deploy identity, base networking, TLS) versus what the *app team* provides (the build definition, the deploy manifest/chart, the per-env values, the pipeline file). No step assumes a human will "just do it in the console."

## Environment promotion

- A push to the **integration branch** (`develop`) deploys the dev/stage environment.
- Production is **PR-gated**: `develop` → prod branch via reviewed PR. No prod deploy on a raw push to the prod branch.
- Branch flow itself follows [`git/branching-and-pr-flow.md`](../git/branching-and-pr-flow.md); this standard only binds *which branch triggers which environment*.

## Anti-patterns (each one burned a real session)

- **Local `docker build && docker push` or hand-`kubectl apply`** of a workload — breaks guarantees 1 and 3.
- **A pipeline definition the CI tool reads from outside the repo** (a "remote" definition) when the tool also supports in-repo pipeline-as-code — the remote form routinely fails to trigger and needs write-back access the deploy identity shouldn't have. Prefer the in-repo, auto-synced form.
- **Index-based array overrides for build metadata** (`--set env[N].value=`) — a null array element produces a manifest the orchestrator rejects. Use a *named* value.
- **Instance values committed into the standard** — pipeline ids, namespace names, item UUIDs, repo hashes are consuming-repo config. The standard defines shape; the repo holds values.

## Reference implementation (sanitized) — Buddy + Helm + Kubernetes

A concrete path that satisfies the contract. Every specific is a placeholder — `<ci-tool>`, `<registry>`, `<cluster>`, `<namespace>`, `<tenant>`, `<app>`, `<your-org>`. Lift this into your overlay (e.g. `.devteam-overlay/standards/ci-cd/<your-stack>.md`) and fill in real values there — real hostnames, identities, and vault item names are **entity** and never belong in core.

Four actions in sequence:

1. **Build** the image from the app's `Dockerfile`.
2. **Push** to `<registry>/<tenant>/<app>:build-$EXECUTION_ID` and `:latest` (paths lowercase — OCI rejects uppercase).
3. **Deploy** on a helm+kubectl action: assemble an ephemeral kubeconfig from CI variables, then `helm upgrade --install <app> helm/<app> -f values-production.yaml -n <namespace> --set image.tag=build-$EXECUTION_ID`. Run **without** `--create-namespace` — the deploy identity is namespace-scoped and the namespace is pre-provisioned (guarantee 4).
4. **Notify** the team channel on success/failure.

Variable contract (names illustrative; *values* live in the CI tool's encrypted store per [`security/agent-secrets.md`](../security/agent-secrets.md)):

| Variable | Scope | Purpose |
|---|---|---|
| `REGISTRY_USER` / `REGISTRY_PASS` | project | registry push creds |
| `DEPLOY_SA_TOKEN` | project | namespace-scoped deploy identity |
| `CLUSTER_CA` / `CLUSTER_HOST` | workspace | ephemeral kubeconfig inputs |
| `DEPLOY_AGE_KEY` | workspace | only when the chart needs deploy-time SOPS decrypt (see [`security/sops-age.md`](../security/sops-age.md)) |

The chart lives **with the app** (`helm/<app>/` + `values-production.yaml` in the app repo); there is no shared chart in the infra repo. Decrypt secrets to a tmp file, build a Secret via `--from-env-file`, reference it through the chart's `envFrom`, and `rm` the decrypted file before the action exits.
