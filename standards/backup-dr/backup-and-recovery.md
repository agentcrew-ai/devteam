---
version: 0.1.0
updated: 2026-07-11
breaking: false
---

# Backup & recovery (stack-agnostic)

This is the **contract** every stateful system must satisfy before it is considered durable, independent of database, object store, or orchestrator. It defines *what* a backup regime must guarantee, not *how* a specific tool does it. A concrete, fully-worked reference (logical dump → object storage on Kubernetes) is sketched at the end with every infra specific replaced by a placeholder — copy it into your overlay and fill in your own values. To back up a different system, write an overlay that satisfies this same contract; see [`EXTENSION.md`](../../EXTENSION.md).

The rule this exists to enforce: **redundancy is not backup.** Synchronous replication (RAID, DRBD, multi-node clustering, cloud block-store replication) protects against *hardware* loss — it faithfully copies logical destruction (corruption, an accidental mass-delete, a bad "rebuild/restore-from-scratch" operation) to every replica. A system with replication but no restorable point-in-time copies is **unprotected against its most common real failure modes.**

## The contract — seven guarantees

A backup regime is compliant when it guarantees all seven:

1. **Point-in-time, not just redundant.** There is at least one copy from which an *earlier* state can be restored — independent of the primary's replication. If the only "backup" is a same-engine copy on the same storage, that is not a backup.

2. **Automated and scheduled.** Backups run on a schedule with no human in the loop. The schedule and its target (RPO — how much data you can afford to lose) are explicit and documented.

3. **Failure is visible.** A missed or failed backup surfaces — via alerting, a retained failed-job state, or a monitored heartbeat. Silent failure is treated as a Sev incident waiting to happen; a backup nobody knows is broken is worse than none.

4. **Verified by restore — periodically, not once.** *An untested backup is not a backup.* Every backup path is proven by an actual restore into an isolated target, with an integrity check (record/object count, checksum, or app-level validation) that must match the source. This runs on a recurring cadence, not only at build time — restore paths rot silently as formats and tool versions drift.

5. **Least-privilege, secret-managed credentials.** The backup identity can write (and read for restore) backups and nothing else — scoped to its own destination, never an admin/root credential. Credentials live in a secret manager (sops, Vault, cloud KMS), never plaintext in manifests or images.

6. **Retention and lifecycle.** Retention is defined (how many copies, how long) and enforced automatically — old copies pruned, ideally tiered (e.g. daily → weekly → monthly). Unbounded growth and manual pruning are both non-compliant.

7. **Blast-radius independence, documented.** At least one copy must survive loss of the primary's *storage backend*, not just its compute. For every copy, document what shares fate with the primary: a copy on the same storage backend counts only as the **logical-corruption layer**, not disaster recovery. Target **≥2 independent layers** (e.g. logical backup on primary storage + an off-cluster/off-site copy). State the recovery-time expectation (RTO) for each.

**Restore runbook.** A written, findable restore procedure is part of the deliverable — the steps, the target, the credential, and the integrity check. Recovery improvised under pressure is how backups that "existed" still lose data.

## Reference implementation (sanitized) — logical dump → object storage on Kubernetes

Placeholders in `<angle-brackets>`; replace in your consumer overlay. This is *a* compliant path, not the only one.

- **Build boundary (guarantee ties to ci-cd standard).** The backup tool image (dump/restore CLI + object-store client + the backup script) is built at a single boundary and **pinned by digest** where it runs. Build in-CI or in-cluster (e.g. Kaniko); never hand-built. Tool versions freeze at the pinned digest even if the image's installs float.
- **Schedule.** A `CronJob` runs the backup off-peak. Per database/dataset it streams a **logical** export → compress → write a date-stamped object to `<object-store>/<bucket>/<dataset>/<YYYY-MM-DD>.<ext>`. Streaming (not buffering to disk) handles large, growing datasets.
- **Integrity gate in the job.** After upload, assert the object is non-trivial (size floor) and fail the job otherwise — so a broken dump can never masquerade as a good backup (guarantee 3/4).
- **Retention.** Prune objects older than `<N>` days as a best-effort step that does not fail an otherwise-good backup; enforce longer tiers via object-store lifecycle rules (guarantee 6).
- **Credentials.** A dedicated backup identity with a destination-scoped policy (write/read/list/delete on the one bucket only). Its keys and the source credentials come from secret-managed material, injected as env — never argv (keep them out of `ps`) (guarantee 5).
- **Hardening.** Run non-root, read-only root filesystem, drop all capabilities, seccomp `RuntimeDefault`.
- **Verified restore.** A recurring restore check (a scheduled Job, or a documented + calendared manual run) restores the latest object into a scratch target and compares record/object count to the live source, then tears the scratch target down (guarantee 4).
- **GitOps ownership.** The scheduled workload is declaratively managed (e.g. Argo/Flux) so it self-heals; secret material is applied out-of-band per your secrets convention.

## Anti-patterns (non-compliant)

- Treating replication/RAID/DRBD/multi-AZ as "we have backups." (Guarantee 1.)
- A backup that has never been restored, or was restore-tested once at setup and never again. (Guarantee 4.)
- Using an admin/root credential for the backup job. (Guarantee 5.)
- All copies on the same storage backend. (Guarantee 7.)
- Manual, ad-hoc, or laptop-run dumps as the system of record. (Guarantees 1–2.)
- No alerting on backup failure. (Guarantee 3.)
