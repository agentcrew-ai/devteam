---
version: 1.0.0
updated: 2026-06-18
breaking: false
---

# Meta-Logging & Programmatic Vault Writes

How any Claude surface — an MCP tool, an agent, a skill, a hook — writes into the project knowledge layer (`_0-meta/` append-only files) and, more broadly, into an Obsidian/PARA vault. This is **policy**: what a write surface is required to do and what it is forbidden to do. It does **not** specify an implementation — supply your own write surface in your overlay; this standard only constrains how it behaves.

This standard governs *programmatic* writes. A human editing a note by hand in Obsidian is out of scope.

## Principle

The knowledge layer is **append-only by construction, sandboxed by default.** A project's history (`_log.md`), its decisions (`_decisions.md`), and its reusable patterns (`_patterns.md`) are the durable record — they must never be silently rewritten, reordered, or truncated by an automated surface. New knowledge is *added* as a well-formed block; existing knowledge is *never* clobbered. And until a write surface has been proven safe against the real vault, it writes only to a sandbox — opening it to the live vault is a deliberate, gated event, never a default.

## The append-only meta files

Every project's `_0-meta/` directory holds these append-only files. A programmatic surface may **append** to them and nothing else — no rewrite, no replace, no truncate, no reorder.

| File | Holds | Block leader |
|------|-------|--------------|
| `_log.md` | Session/work-log entries | `## YYYY-MM-DD [— Title]` |
| `_decisions.md` | Directional/architectural/tradeoff decisions | `## YYYY-MM-DD — Title` |
| `_patterns.md` | Reusable patterns/memory worth propagating | `## YYYY-MM-DD — Title` |

`_next.md`, `_intention.md`, `_backlog.md` are **not** append-only — they are living documents a human (or a confirmed, diffed edit) revises. Do not treat them as appendable logs, and do not silently rewrite them either: frontmatter/intention changes are diffed and confirmed before write.

## Canonical block shapes

Every appended block is a single H2 section dated `YYYY-MM-DD`, followed by its fields, terminated by a `---` horizontal rule so the file stays a clean sequence of separated entries. Optional fields are **omitted entirely** when not supplied — never emitted blank.

**Decision** (`_decisions.md`):

```
## YYYY-MM-DD — <title>
**Decision:** <the decision>
**Rationale:** <why>                        (optional)
**Alternatives considered:** <what else>    (optional)
**Reversible?** Yes|No                       (optional)
---
```

**Log entry** (`_log.md`):

```
## YYYY-MM-DD [— <title>]

<free-form markdown body>

---
```

**Pattern / memory** (`_patterns.md`):

```
## YYYY-MM-DD — <title>
**Pattern.** <the reusable pattern>
**Why it matters.** <why>          (optional)
**How to apply.** <how>            (optional)
---
```

When no title is supplied, derive it from the first non-empty line of the content (trimmed, capped ~80 chars). Decision-vs-pattern is a real distinction: a *decision* is a choice that was made (goes to `_decisions.md`); a *pattern* is reusable guidance (goes to `_patterns.md`). Do not conflate them.

## Rules

- **Append-only files are append-only by construction, not by good intentions.** The write surface must make a rewrite/overwrite of `_log.md` / `_decisions.md` / `_patterns.md` *unreachable* — e.g. the only mutation exposed is "append a self-composed block," and any general `write_note`/replace primitive is not wired to these paths. A surface that *could* clobber them but promises not to is non-compliant.
- **Compose the block; never accept a raw blob to write verbatim.** The surface owns the heading, the date, the field structure, and the trailing rule. Callers supply content for the fields, not the formatting — that is what keeps every entry well-formed.
- **Sandboxed by default.** Programmatic writes are confined to a configured sandbox prefix (default `sandbox/`) via an explicit, env-gated switch (reference: `WILLPWR_ENFORCE_SANDBOX` / `WILLPWR_SANDBOX_PREFIX`). With enforcement on, any target outside the sandbox is refused *before any IO*. Path traversal (`..`) is rejected unconditionally, enforcement on or off.
- **Every write is dry-run-able.** The surface must support a `dry_run` that returns the exact block and resolved target it *would* write, touching nothing. This is the precondition for proving a write before trusting it.
- **Create-only means create-only.** A note-creation surface refuses to overwrite an existing note. New notes carry valid frontmatter (type/title/status-enum per the LID/conventions spec) and an auto-allocated, collision-checked LID.
- **Opening the sandbox to the live vault is a gated event.** Flipping enforcement off is deliberate and reviewed, with prerequisites met first: LID allocation must be collision-safe against a possibly-partial index (refuse allocation when the index is degraded/not ready), and create-surfaces must reject append-only meta paths so they can't be created with the wrong (frontmatter-fenced) shape. Until those guards exist, enforcement stays on.
- **Prove it against the real vault before trusting it.** A new or changed write surface is dogfooded against a real-vault sandbox (sandbox-deny on a live path, dry-run, live create, create-only guard, all three append writers, append-only-growth) before it is relied on. Clean up dogfood artifacts afterward — they consume real LIDs.

## Why this exists

The integration layer of a multi-project PM system is its append-only record. The failure mode this prevents is an automated surface "helpfully" rewriting a decisions log or a session history — destroying the one artifact that makes scaling past human memory possible. Append-only-by-construction + sandbox-by-default turns "please don't clobber the vault" from a hope into a property.
