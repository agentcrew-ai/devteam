---
version: 1.0.0
updated: 2026-06-08
breaking: false
---

# Repo Secrets with SOPS + age

How secrets that must live in a repo (encrypted Kubernetes Secrets, dotenv files,
Helm values containing credentials) are encrypted at rest with
[SOPS](https://github.com/getsops/sops) and [age](https://github.com/FiloSottile/age),
and decrypted at deploy time. This governs **repo-resident** secrets; how *agents*
read live secrets at runtime is `security/agent-secrets.md`.

## Principle

Repo secrets are encrypted with age via SOPS. Only **named recipients** can
decrypt: the humans who maintain the repo, plus **one shared `&buddy` CI
recipient** so the pipeline can decrypt at deploy time. Plaintext secret material
never touches disk durably, git, or chat.

## The pattern

- **`.sops.yaml`** at the repo root lists the recipient public keys: each human's
  age public key, plus one `&buddy` anchor for the CI recipient.
- **`encrypted_regex: ^(data|stringData)$`** — encrypt only the secret-bearing
  fields of a manifest, leaving keys, metadata, and structure readable in the
  diff.
- **One `&buddy` recipient per repo, not per app** (decided 2026-06-03). A single
  repo-level CI age key encrypts all of that repo's apps; do not mint a key per
  app.

Example `.sops.yaml`:
```yaml
keys:
  - &john age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  - &buddy age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
creation_rules:
  - path_regex: \.sops\.ya?ml$
    encrypted_regex: ^(data|stringData)$
    key_groups:
      - age:
          - *john
          - *buddy
```

## Key custody

- The **`&buddy` private key** lives in the workspace-scoped Buddy variable
  **`DEPLOY_AGE_KEY`** (per `ci-cd/pipeline-pattern.md`).
- A **durable copy** of the `&buddy` key **and each human's age key** is backed up
  to the **1Password break-glass vault**. Never in git, never in chat.
- Buddy's encrypted variable store is an accepted at-rest home for the CI key
  (see the carve-out in `security/agent-secrets.md`).

## Working with encrypted files

- **Edit in place:** `sops <file>` (decrypts to an editor buffer, re-encrypts on
  save — no plaintext hits disk).
- **Apply to a cluster:** `sops -d <file> | kubectl apply -f -`. **Never** decrypt
  to a plaintext file on disk for `kubectl apply`.
- **Rekey on recipient change** (someone added/removed): update `.sops.yaml`, then
  re-encrypt every secret file to the new recipient set:
  ```sh
  find . -name '*.sops.y*ml' -not -name '.sops.yaml' \
    -exec sops updatekeys -y {} \;
  ```

## Pipeline-time decrypt

The deploy action runs on `dtzar/helm-kubectl`, which has **no sops binary**.
Fetch a **pinned** sops binary, decrypt with `$DEPLOY_AGE_KEY` to a tmp path,
consume it, and **`rm`** both the decrypted output and the key file before the
action exits:

```sh
SOPS_AGE_KEY="$DEPLOY_AGE_KEY" sops -d secrets.sops.yaml > /tmp/secret.yaml
kubectl apply -f /tmp/secret.yaml -n <ns>
rm -f /tmp/secret.yaml
```

Decrypted material is ephemeral to the build — it never persists in the workspace.

## Cross-references

- `ci-cd/pipeline-pattern.md` — where `DEPLOY_AGE_KEY` is declared and the two
  runtime-injection patterns that consume decrypted secrets.
- `security/agent-secrets.md` — runtime secret reads by agents, and the CI-store
  at-rest carve-out that reconciles with this standard.
