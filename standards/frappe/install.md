---
version: 1.0.0
updated: 2026-10-17
breaking: false
---

# Frappe production install

How to stand up a new production Frappe site (ERPNext or any Frappe app) on virtual machines. This standard governs the **install and the host layout**. App code conventions are [`patterns.md`](patterns.md). Secrets handling is [`../security/sops-age.md`](../security/sops-age.md) and [`../security/agent-secrets.md`](../security/agent-secrets.md). Backups are [`../backup-dr/backup-and-recovery.md`](../backup-dr/backup-and-recovery.md). If the target is Kubernetes, this standard does not apply; use the official container images under [`../infra/helm.md`](../infra/helm.md).

Out of scope: upgrading or migrating an existing site. That is a per-site procedure and lives with the site.

## Install method: bench on the VM

A single production site on VMs is installed with **bench**, the Frappe CLI, directly on the host, then switched to production mode (`bench setup production`: nginx in front of gunicorn, supervisor or systemd for the workers and scheduler).

Bench is the default because it is what Frappe's own upgrade, migrate and restore procedures assume, so every runbook works unchanged. On one or two VMs a container stack adds a runtime, image pinning and compose upgrades and buys nothing back.

Use the official container images (frappe_docker) instead only when one of these is true, and record which one in the consumer's overlay:

- the target is a Kubernetes cluster, or
- the host runs many sites or tenants that need isolated, disposable environments.

## Database: MariaDB

ERPNext runs on **MariaDB**. Frappe Framework can run on PostgreSQL, but ERPNext's stock, accounting and report queries are written for MariaDB and are not supported on PostgreSQL in production. Do not choose PostgreSQL for an ERPNext site.

- Use the MariaDB release that Frappe's install documentation names for the target major version, and check it at install time. Pin the exact version in IaC or the bootstrap script.
- Server settings Frappe requires: `character-set-server = utf8mb4`, `collation-server = utf8mb4_unicode_ci`, `character-set-client-handshake = FALSE`. Size `innodb_buffer_pool_size` to roughly half the database host's RAM when MariaDB has its own host.

## Topology

The app tier (bench, gunicorn, nginx, Redis, workers, scheduler) and MariaDB may share a host or be split. Split them when the database needs its own memory, its own disk and backup schedule, or its own resize path. When split:

- MariaDB `root` stays local (unix socket). It is never granted from a remote host.
- A dedicated admin user, granted only from the app host, is what bench uses as `--db-root-username` for `new-site` and `restore`.
- The site database user is granted only from the app host.
- Port 3306 on the database host is closed to everything except the app host, by network policy (NSG, security group or firewall), not by MariaDB grants alone.
- Redis stays on the app host, bound to localhost.

## Disks and rebuilds

- The bench directory (code, `sites/`, public and private files) lives on a **data disk**, not the OS disk. On a split database host, the MariaDB datadir lives on its own data disk.
- IaC protects every data disk from destruction (for example Terraform `prevent_destroy`).
- The VM resource ignores changes to its bootstrap data, SSH key and image, so a template edit never rebuilds a running server. Upgrades happen on the box with bench.
- Snapshot the data disks before any upgrade or migrate.

## Versions

- Pin Frappe and each app to a **release tag**, not a moving branch such as `version-16`. Record the tags in IaC or the bootstrap script so a rebuild installs the same code.
- Install the Python, Node and Redis versions Frappe documents for that major version.

## Secrets

Generate these **before** install, store them in the secret manager the consumer uses, and inject them at install time:

- site `encryption_key`
- Administrator password
- database admin and site user passwords

Rules:

- **Set `encryption_key` before the site holds any data, and never rotate it.** Every encrypted field and stored password in the site depends on it. A database backup restored without it is unreadable, so it is backed up separately from the database dumps.
- Secrets reach the host at boot by pulling from a key vault with the VM's own identity. They are not written into cloud-init or user data, which end up in IaC state and instance metadata.
- Nothing secret appears in IaC outputs, logs or git, except in SOPS-encrypted files per `security/sops-age.md`.

## Network

- A site holding regulated data has no public IP. Users reach it over private networking (VPN or private link) only.
- nginx terminates TLS. A self-signed certificate is acceptable until go-live, and not after.
- SSH is key-only and restricted to the management network.

## Bootstrap

The bootstrap script (cloud-init or equivalent) is idempotent. Running it again on a host that already has a site detects the site and changes nothing. It never runs `bench new-site` against an existing site or `--force`.

## Ready for users

A new site is not ready for users until:

1. `bench doctor` reports the scheduler and workers running.
2. A login through nginx over HTTPS succeeds for the Administrator.
3. A backup has been taken **and restored** to a scratch site, per `backup-dr/backup-and-recovery.md`.
4. The `encryption_key` is confirmed present in the secret manager, separately from the backup.

## Anti-patterns

- Choosing PostgreSQL for ERPNext.
- Installing from a moving branch, so two rebuilds produce two different servers.
- Bench or the database on the OS disk.
- Remote `root` on MariaDB.
- Secrets in cloud-init user data.
- Going live on a site whose backup has never been restored.
