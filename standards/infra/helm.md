---
version: 1.1.0
updated: 2026-08-29
breaking: false
---

# Helm chart conventions

How a workload is packaged as a Helm chart, versioned, configured per environment, and validated before it reaches a cluster. This standard governs the **chart**. The pipeline that builds and ships the artifact is [`ci-cd/pipeline-pattern.md`](../ci-cd/pipeline-pattern.md); secrets encrypted at rest in the repo are [`security/sops-age.md`](../security/sops-age.md).

Everything here assumes a Kubernetes target. It does not assume a particular distribution, ingress controller, registry, or GitOps controller. Where a rule depends on the class of tool you run, this standard names the class and leaves the product to your overlay.

## Principle

A chart is the deployable description of one workload, and it lives in that workload's repo. A reader who has the repo can tell what gets created, what changes per environment, and which build is running, without opening a console.

Three things follow from that, and they are the rules the rest of this document elaborates:

- **The chart is the only description.** No hand-applied manifest patches the chart's output.
- **Configuration is layered, not forked.** One baseline, one override file per environment, one runtime value for the build. There is no second chart for production.
- **No secret material is in the chart.** Not in `values.yaml`, not in an override file, not base64-encoded in a template.

## Chart layout

The chart lives with the app it deploys, under `helm/<app>/` in the app repo. There is no shared chart in an infrastructure repo, because a shared chart makes every app's deploy a change to somebody else's repo.

```
helm/<app>/
├── Chart.yaml
├── values.yaml                # baseline: every key the chart reads, with a safe default
├── values-<env>.yaml          # one per deployment target, overrides only
├── templates/
│   ├── _helpers.tpl           # name, fullname, and label helpers
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── NOTES.txt
└── .helmignore
```

Rules for `templates/`:

- One Kubernetes kind per file, named after the kind.
- Every template renders from a value. A template with a literal namespace, hostname, or image reference in it is a configuration bug that only shows up on the second environment.
- Put name and label construction in `_helpers.tpl` and call it. Repeating the label block in four templates guarantees the four drift.

## `Chart.yaml`

Use `apiVersion: v2`. Charts on `apiVersion: v1` predate Helm 3 dependency handling and are not accepted.

Required fields:

| Field | Rule |
|---|---|
| `apiVersion` | `v2` |
| `name` | The chart name. Matches the directory name and the app name. |
| `description` | One sentence saying what the workload does. |
| `type` | `application`, unless the chart exists only to be depended on, which makes it `library`. |
| `version` | The chart's own semver. See below. |
| `appVersion` | The application version the chart defaults to. Quote it — an unquoted `1.20` becomes a float and stops matching the tag it names. |

## Chart version and app version

These are two different numbers and conflating them makes a release history unreadable.

- **`version` is the chart's semver.** Bump it whenever a template, a default, or the chart's structure changes. Patch for a fix that changes no rendered field a consumer relies on, minor for a new value or a new resource with a safe default, major when an existing deployment needs a values change to keep working.
- **`appVersion` is the application's version.** It tracks the software, not the packaging. Changing `appVersion` alone is still a chart change, so bump `version` too — at least a patch.

Never ship two different chart contents under one `version`. The version is what a consumer pins to, and a mutable version makes the pin meaningless.

## Values: baseline, environment overrides, runtime

Three layers, each with a job. Later layers win.

**`values.yaml`** declares every key the chart reads and gives each one a default that is safe to deploy. A key that only appears in an override file will be undefined the first time somebody deploys without that file, and the template renders empty rather than failing. Put replica counts, resource requests and limits, probe paths, service ports, and feature toggles here. Development defaults belong here; production values do not.

**`values-<env>.yaml`** carries overrides only, never a copy of the baseline. Name it for the deployment target: `values-development.yaml`, `values-production.yaml`. This is where ingress hostnames, per-environment replica counts, resource ceilings, and environment-specific toggles live. If an override file is longer than the baseline, the baseline defaults are wrong.

**Runtime `--set`** carries exactly the values that are not known until the build runs. In practice that is the image tag and build metadata. Use a **named** value (`--set image.tag=...`), never an index into an array (`--set env[2].value=...`) — a null array element renders a manifest the API server rejects, and the index moves the next time somebody edits the list.

Anything that is knowable at commit time belongs in a file, in git, in the diff. `--set` is not a place to keep configuration.

## Image references

The baseline may carry a mutable tag, and the pipeline overrides it at deploy with the build's own identifier:

```sh
helm upgrade --install <app> helm/<app> \
  -f helm/<app>/values-<env>.yaml \
  -n <namespace> \
  --set image.tag=build-<build-id>
```

This pattern is compliant when the audit trail holds. What is running is recoverable from the release's rendered values plus the registry's record of which build produced that tag, and the registry restricts who can push to the repository path. Lose either half and you have a cluster running an image nobody can trace to a commit.

Two rules make it hold:

- **A mutable tag is never the deploy reference.** `latest` is a convenience pointer for a human pulling the image by hand. If a `helm upgrade` runs without an explicit `--set image.tag`, the deploy is not auditable and the pipeline should fail rather than proceed.
- **`imagePullPolicy: IfNotPresent`** with a build-specific tag. `Always` with an immutable tag is a wasted registry round trip on every pod start; `IfNotPresent` with a mutable tag serves stale bytes.

**Digest pinning is the forward direction for production.** Referencing `image: <registry>/<path>@sha256:<digest>` removes the registry-ACL dependency from the audit trail entirely, because the digest is the artifact. This standard recommends it and does not mandate it, because the tag-plus-runtime-override pattern above is auditable when its two conditions hold, and blocking on the stronger form buys nothing until they stop holding.

## Secrets

**No plaintext secret material appears in a chart or in any values file.** Not a password, not a token, not a TLS private key, not a connection string with credentials in it. This is not a style rule — a values file is committed, and a committed secret is a rotated secret.

Charts reference secrets, they do not contain them:

- Mount or inject by reference: `envFrom.secretRef`, `env.valueFrom.secretKeyRef`, or a volume from a Secret. The chart names the Secret; something else creates it.
- The Secret itself is encrypted at rest in the repo and decrypted at deploy time. See [`security/sops-age.md`](../security/sops-age.md) for the encryption pattern and [`ci-cd/pipeline-pattern.md`](../ci-cd/pipeline-pattern.md) guarantee 5 for the injection rule.
- Decrypted material never persists in the build workspace. The deploy step removes it before the action exits.

A chart that renders a `Secret` with `stringData` read from a values key is the same violation wearing a template. The value still had to be in the file.

## TLS certificates

Certificates reach a workload as a `kubernetes.io/tls` Secret that the ingress references by name. The chart names the Secret and does not create it.

Where one certificate serves several namespaces — a wildcard, most often — the pattern is:

1. The certificate lives as a `kubernetes.io/tls` Secret in **one dedicated namespace** that the environment owner controls.
2. A **reflector-class controller** copies it into each consuming namespace, driven by annotations on the source Secret that name which namespaces may receive it.
3. Each chart's ingress references the copy by name in its own namespace.

Naming the source namespace and the controller is an overlay concern. What this standard binds is the shape: one authoritative copy, propagation by a controller rather than by hand, and a chart that never holds certificate material.

Automated issuance — a controller that requests and renews certificates from an ACME or internal CA rather than propagating a purchased one — satisfies this section equally. The chart is unchanged either way, which is the point of referencing the Secret by name.

## Pod security

### Namespace admission

Every namespace a chart deploys into carries Pod Security Admission labels:

```yaml
pod-security.kubernetes.io/enforce: baseline
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/warn: restricted
```

Start at `enforce: baseline`. Run with `audit` and `warn` at `restricted` so the violations that stand between you and the stricter profile appear in the audit log without breaking anything. When the workloads in that namespace stop producing warnings, ratchet `enforce` to `restricted`.

Namespace labels are set by whoever provisions the namespace, which per [`ci-cd/pipeline-pattern.md`](../ci-cd/pipeline-pattern.md) guarantee 6 is the environment owner, not the chart. A chart that creates its own namespace is deploying with an identity broader than it should have.

### Pod security context

**New charts must set all three of these.** They are not defaults; a chart that omits them runs as root.

```yaml
podSecurityContext:
  runAsNonRoot: true
  fsGroup: <gid>
  seccompProfile:
    type: RuntimeDefault
```

- `runAsNonRoot: true` makes the kubelet refuse to start a container whose image runs as UID 0. Set `runAsUser` alongside it when the image does not declare a non-root user itself.
- `fsGroup` sets group ownership on mounted volumes, so a non-root process can write to its own persistent volume. Omitting it is the usual reason `runAsNonRoot` "breaks" an app that was fine as root.
- `seccompProfile: RuntimeDefault` applies the runtime's syscall filter. It is required by the `restricted` admission profile, so setting it now is what makes the ratchet above cheap later.

Recommended at the container level, and required if you intend to reach `restricted`:

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

**Existing charts should be audited against this section, not swept.** Add the fields when you next touch the chart, and verify the workload still starts. A bulk change that sets `runAsNonRoot` across charts nobody tested converts a security improvement into an outage.

## Required labels and annotations

Every resource a chart renders carries the standard label set, applied from `_helpers.tpl`:

| Label | Value |
|---|---|
| `app.kubernetes.io/name` | The chart name. |
| `app.kubernetes.io/instance` | The release name. |
| `app.kubernetes.io/version` | `.Chart.AppVersion`, quoted. |
| `app.kubernetes.io/component` | The role this resource plays: `web`, `worker`, `cache`. |
| `app.kubernetes.io/part-of` | The larger system this workload belongs to, when there is one. |
| `app.kubernetes.io/managed-by` | `Helm`. |
| `helm.sh/chart` | `<name>-<version>`. |

Add **one tenant label** whose key is a domain you control (`<your-domain>/tenant`) and whose value identifies the owning team or client. This is what makes a cluster-wide query answer "who owns this" and "what is this tenant running". Define the key once in your overlay so every chart uses the same one.

Annotations record the build rather than describing the resource. At minimum, annotate the Deployment with the source commit (`<your-domain>/source-commit`). Do not put secrets, hostnames of other environments, or free-text notes in annotations — they are copied onto every pod.

## GitOps wiring

Where a GitOps controller reconciles the cluster from git, the repository is laid out as an **app-of-apps**: one root application whose only job is to create the child applications.

```
<gitops-repo>/
├── applications/
│   ├── root.yaml              # the root; watches applications/
│   └── app-<workload>.yaml    # one child per workload
└── projects/
    └── <tenant>.yaml          # one project per tenant
```

- **One child application per workload**, in a file named `app-<workload>.yaml`, with the application named `<workload>`. The file name and the application name match so a `grep` for either finds both.
- **Scope each application to a tenant project**, not to a default catch-all. The project restricts which source repositories, destination namespaces, and resource kinds the applications inside it may use. That restriction is the blast-radius limit; an application in a wide-open project can deploy anything anywhere.
- **Manual sync is the default.** Auto-sync is an opt-in per application, appropriate for a development target and a deliberate decision for production. Whichever you choose, state it in the application manifest rather than leaving it to the controller's global default, because the global default is invisible from the repo.
- **Self-healing and pruning are separate switches from auto-sync.** Turning on pruning means the controller deletes resources that leave git. That is correct behaviour and it is also how a mis-scoped application deletes something it did not create.

The vocabulary above — root application, child application, project — describes the pattern class. Map it to whichever controller you run.

## Lint and validate before the cluster

Every pipeline runs both of these before the deploy step, and a failure in either stops the pipeline:

```sh
helm lint helm/<app> -f helm/<app>/values-<env>.yaml

helm template <release> helm/<app> \
  -f helm/<app>/values-<env>.yaml \
  | kubeconform -strict -summary -
```

`helm lint` catches chart structure and templating errors. It does not check whether the result is a valid Kubernetes object, which is why the second command exists: render the manifests and validate them against the API schemas with a schema validator such as `kubeconform`. Use `-strict` so an unknown field is an error rather than a shrug — a misspelled `readinessProbe` key is silently dropped by the API server otherwise, and you find out when the rollout does not gate on health.

Run both against **every** environment's values file, not just the default. Most chart breakage is a key that only production overrides.

Add a `values.schema.json` to the chart once the value surface stabilizes. It turns a bad override into a `helm lint` failure with a field name in it, instead of a rendered manifest that is wrong in a way you have to read to notice.

## Health probes

Every long-running workload declares both a readiness probe and a liveness probe, and they check different things:

- **Readiness** answers "should this pod receive traffic". Point it at an endpoint that fails when a dependency the request path needs is unavailable.
- **Liveness** answers "should this pod be killed and restarted". Point it at something that only fails when the process is genuinely stuck. A liveness probe that checks a database restarts every pod in the deployment during a database blip, which converts a degraded service into an outage.

### Set `timeoutSeconds` on every probe

`timeoutSeconds` defaults to **1 second**, and that default is wrong for anything that talks to a network or a disk. A healthy process misses a 1-second HTTP deadline routinely: the host is paging, a neighbouring container is saturating the disk, the runqueue is deep, a garbage collector paused the thread that answers. None of that means the application is broken. It means the kubelet did not get a reply in a second, which is a different fact.

**Set `timeoutSeconds` explicitly on every probe you declare, with a floor of 3 seconds.** Never leave it to the default. A probe that times out faster than the host's own worst-case scheduling latency is not measuring the application, it is measuring the node, and the failure it reports is a lie about which one broke.

Raise the floor where the check does real work. A probe that opens a database connection or reads from disk needs a timeout sized to that work under load, not to its median.

### Prefer a `startupProbe` to `initialDelaySeconds`

Use a `startupProbe` for any container whose cold start is slow or variable — a large image, a framework that compiles assets or runs migrations on boot, a container that must pull before it runs, anything whose first-boot time differs from its steady state.

`initialDelaySeconds` is a fixed guess at a variable number, so it is wrong in both directions and never right twice. Too short and liveness fires during a slow start, producing a crash loop that looks exactly like a broken image. Too long and every rollout eats the full delay even when the app was ready in two seconds.

A `startupProbe` has neither failure mode. It polls, it stops the moment the app answers, and the kubelet does not run readiness or liveness at all until it succeeds.

**Once a `startupProbe` exists, `initialDelaySeconds` on the other two probes is dead config. Remove it.** It governs nothing, and leaving it there tells the next reader that startup timing is handled somewhere it is not.

### State a probe's tolerance as a budget

`failureThreshold` x `periodSeconds` is a duration. Write the number down in seconds, in a comment, and pick it against the application's measured cold start or measured stall behaviour rather than against a round number.

"Thirty failures at five seconds is a 150-second startup budget" is reviewable — someone can say the app boots in 40 seconds and 150 is generous, or that it boots in 3 minutes and 150 will crash-loop it. "`failureThreshold: 30`" is not reviewable, because the reader has to do the multiplication before they can disagree with it.

### Liveness is strictly more forgiving than readiness

Failing readiness removes the pod from the Service endpoints. It is cheap, and it reverses itself the moment the pod answers again. Failing liveness kills the container, which is neither.

So liveness gets the longer timeout, the longer period, and the higher failure threshold. A chart where liveness is the stricter of the two has the consequences inverted: the destructive action fires first.

### A crash loop with no application error is a probe-tuning symptom

When a container restarts under host pressure and its own logs show no error — it was serving requests, then it was killed — read the probe configuration before reading the application code. That signature is a probe that reacted to the node, and the fix is in the chart. This is worth checking early, because the report that arrives will say the application is broken, and the pod's restart count will appear to agree.

**`/` is not a healthcheck path for a static site.** A site built by a static-site generator serves files, and the container's root path may return a 404 rather than a page: the index can be published under a path prefix, or the server can be configured with a document root that has no top-level `index.html`. A readiness probe on `/` then never passes, the rollout stalls, and the deployment looks like a chart problem when it is a path problem. Point the probe at a file the build produces every time and confirm it with a request against the running container before shipping the chart. This applies to any workload whose routes come from generated output rather than from a route table you wrote.

## Cross-references

- [`ci-cd/pipeline-pattern.md`](../ci-cd/pipeline-pattern.md) — the six delivery guarantees this chart pattern satisfies, and the deploy-identity and secret-injection rules it depends on.
- [`security/sops-age.md`](../security/sops-age.md) — how the Secrets a chart references are encrypted at rest and decrypted at deploy.
- [`security/agent-secrets.md`](../security/agent-secrets.md) — where secret *values* live when they are not in the repo at all.
- [`../EXTENSION.md`](../../EXTENSION.md) — how to add a stack-specific chart standard in your overlay without editing this file.
