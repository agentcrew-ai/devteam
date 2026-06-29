---
version: 1.1.0
updated: 2026-06-09
breaking: false
---

# Agent Secrets Access

How autonomous agents (Claude Code sessions, CI pipelines, cron jobs) obtain
secrets at runtime without a human in the loop and without secrets ever touching
the repo, chat, or a synced plaintext file. This is the generic pattern; the
instance-specific values (which token, which vault, which item IDs) belong in the
consuming environment's own config — **never** in this library.

## Principle

Agents read secrets from a **password manager at runtime via a scoped service
account** — they never hold long-lived copies. Authentication to the manager is
**injected at launch**, so reads inside the agent context are prompt-free. The
service account is **deliberately narrow**: it can see exactly one dedicated
vault and nothing else.

## The pattern

1. **One scoped service account, one dedicated vault.** Provision a service
   account whose only grant is a single vault reserved for agent-readable
   secrets. The account is barred from personal/human vaults by design — that
   blast-radius limit is a feature, not a gap.

2. **Launcher-injected token.** The session/pipeline launcher injects the
   service-account token into the environment at start (env var). Reads in that
   context are then prompt-free — no interactive unlock, no Touch ID. Never write
   the token to a file or commit it.

3. **Read at runtime, never persist.** Resolve secrets at the point of use
   (`op read`, `vault kv get`, equivalent). Do not cache secret *values* in
   files, env dumps, logs, or chat. Move the *item*, reference the *path* —
   never transcribe the value.

   > **Scope — Decision (approved 2026-06-09, RULING 3).**
   > "Read at runtime, never persist" governs **long-lived agents** (Claude Code
   > sessions, cron jobs). A **CI/CD platform's encrypted variable store** (e.g.
   > Buddy encrypted vars, the age key for SOPS decrypt) **is an accepted at-rest
   > location for deploy-time secrets** — the pipeline is the build boundary, not
   > a long-lived agent. See `ci-cd/pipeline-pattern.md` and
   > `security/sops-age.md` for that contract. This carve-out reconciles the two
   > standards rather than contradicting them.

4. **Migrate-on-demand when the SA can't read it.** When a needed secret isn't in
   the agent-readable vault, the read failure is the signal: surface it to the
   human, then **move the item** into the dedicated vault (an operation that runs
   as the human, costing one interactive auth), and retry. Move secrets in **as
   they're needed** — do not bulk-migrate a personal vault into the shared one.

## Rules

- **Reference secrets by a stable identifier, not a human-readable display
  title.** Display titles contain spaces and punctuation (e.g. parentheses) that
  break secret-reference parsers — `op read "op://vault/My Key (prod)/field"`
  fails where the same item read by its UUID succeeds. Use the item's stable ID
  in any non-interactive reference; reserve the display title for human-facing
  `get`/inspection commands.
- **Never copy a secret value into a commit, a file, a log, or chat.** Move the
  item between vaults; reference it by path. The value stays in the manager.
- **Keep the service account's grant minimal.** One vault. Expand the vault's
  contents on demand (rule 4) rather than widening the account's reach.
- **Launcher token is not a stored credential.** It is injected per session and
  lives only in process env. It is never persisted, synced, or committed.

## Out of scope for this library

Instance specifics — the service-account token's identity, the dedicated vault's
name, individual item IDs, and the concrete `move` invocation — are environment
config. They live in the consuming environment's own context files and secret
store, not here. This standard defines the *shape*; the environment supplies the
*values*.
