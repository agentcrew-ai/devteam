# Adopting the dev team as a team

This is the guide for a **team or organization** standing up the dev team across its own projects — not just wiring the roster into one repo. If all you want is to add the roster to a single repo, [`ONBOARDING.md`](ONBOARDING.md) is the faster page; come back here when you have more than one repo or more than one person.

The model in one line: **the base team is generic and shared by everyone; your team wraps it in a layer that carries your context, your SMEs, and your standards — and the generic lessons you learn flow back so the base gets stronger for the next team.**

## 1. What the base team is

The base team (this repo, `devteam`) is a reusable roster of **11 Claude Code subagents** plus a set of **enforcement-gated engineering standards**. The roster is the three planners — **product-manager (WHAT)**, **architect (HOW)**, **project-manager (WHO)** — four implementer lanes (**backend, frontend, data, infra-devops**), three reviewer lanes (**code-reviewer, security, test-engineer**), and a **documenter**. They never share chat context; they coordinate through **work orders** — files on disk that pass a task from one lane to the next. The full operating rules (the mantra, foreman triage, HITL checkpoints, WO format) live in [`CLAUDE.md`](CLAUDE.md).

Everything in the base team is **generic on purpose**. It names no client, no cluster, no stack you happen to run, no decision your team made last quarter. That is what lets every team share it. It is also what makes it useless on its own for real work — a generic architect doesn't know your Moqui quirks, and a generic infra lane doesn't know your registry. The knowledge that makes the team valuable *to your team* is exactly the knowledge that can't live in the base. That knowledge goes in **your layer**.

## 2. Stand up your team's layer repo

Your team's layer is a **separate git repo** — call it `devteam-<yourteam>` (e.g. `devteam-lww`). It does two things: it **pins the base team** as a read-only submodule, and it **holds your team's overlay** — your SME agents, your stack standards, and your private context. Every one of your projects then consumes *the layer*, not the base directly. Set your context once; every project inherits it.

> **Shared layer vs. per-repo overlay.** You can skip the layer repo and drop the base team straight into one project with a small overlay folder beside it (that's the single-repo path in [`ONBOARDING.md`](ONBOARDING.md) + [`EXTENSION.md`](EXTENSION.md)). That's fine for one repo or a spike. The moment you have a second repo, the per-repo approach starts **duplicating your context and drifting** — the exact failure this system exists to prevent. A team with more than one repo should stand up the shared layer. Start per-repo only if you're truly single-repo today, and graduate when you aren't.

### The layer repo's shape

```
devteam-lww/                     # YOUR team's layer repo
├── .devteam/                    # base team — pinned submodule, READ-ONLY from here
│   ├── .claude/agents/          #   the 11 generic agents
│   ├── skills/
│   └── standards/               #   generic, versioned standards
├── .claude/agents/              # OVERLAY: your SME agents + overrides of a base lane
├── skills/                      # OVERLAY: your team's skills (optional)
├── standards/                   # OVERLAY: your stacks (Moqui, your CI tool) + overrides
├── context/                     # PRIVATE: memory, decisions, who-owns-what — NEVER upstreamed
└── CLAUDE.md                    # your team's operating instructions; imports .devteam/CLAUDE.md
```

The overlay **mirrors the base's directory shape**, and precedence is resolved **by relative path, overlay winning** — this is the same rule Claude Code already uses when a project agent shadows a user-level one, generalized to standards and skills:

- **A path the base doesn't have → it ADDS.** `standards/moqui/` becomes a new standard for your projects.
- **A path the base also has → it OVERRIDES.** `.claude/agents/backend.md` in your overlay replaces the base's backend lane *for your team only*. Override the **smallest** unit you can (one agent, one standard) so you keep inheriting base improvements everywhere else.

The full precedence and boundary rules are in [`EXTENSION.md`](EXTENSION.md) — read it once before you add anything to the overlay.

### Creating the layer repo

Run from an empty new repo (`devteam-lww`):

```bash
# 1. Pin the base team as a read-only submodule at .devteam
git submodule add <base-team-remote> .devteam
git submodule update --init --recursive
( cd .devteam && git fetch --tags && git checkout <latest-tag> )   # pin to a tag, never a moving branch
git add .gitmodules .devteam && git commit -m "chore: pin base team to <latest-tag>"

# 2. Scaffold your overlay dirs
mkdir -p .claude/agents skills standards context/work-orders

# 3. Write your team CLAUDE.md (see next section) and commit
```

Pin to a **tag**, never to `develop` — tags carry the promoted, hardened standards; the changelog tells you exactly what moves when you bump. Find the latest with `git tag --sort=-creatordate` inside `.devteam`. The full submodule + agent-discovery mechanics are the authoritative playbook in [`skills/project-bootstrap.md`](skills/project-bootstrap.md); this guide is the team-scale wrapper around it.

### How a project consumes the layer

Each of your projects (`lww-www`, `cmp`, …) adds **the layer** as its submodule — the layer brings the base along nested inside it. Agent discovery still works the way Claude Code requires: symlink each agent into the project's `.claude/agents/`, **preferring the overlay's version and falling back to the base's**:

```bash
# from a project root, with the layer submoduled at .devteam-lww
mkdir -p .claude/agents
for base in .devteam-lww/.devteam/.claude/agents/*.md; do
  name=$(basename "$base")
  if [ -f ".devteam-lww/.claude/agents/$name" ]; then
    ln -sf "../../.devteam-lww/.claude/agents/$name" ".claude/agents/$name"   # overlay wins
  else
    ln -sf "../../.devteam-lww/.devteam/.claude/agents/$name" ".claude/agents/$name"
  fi
done
# then symlink any overlay-only SME agents that have no base counterpart
for ov in .devteam-lww/.claude/agents/*.md; do
  name=$(basename "$ov")
  [ -e ".claude/agents/$name" ] || ln -sf "../../.devteam-lww/.claude/agents/$name" ".claude/agents/$name"
done
git add .claude/agents && git commit -m "chore: wire layer agents into .claude/agents for discovery"
```

Re-run that loop whenever you bump the layer pin, so new or renamed agents stay in sync. Symlinks are relative and committed, so they reconstitute on any machine after `git submodule update --init`. Agent discovery happens at **session start** — restart a session opened before this step.

## 3. Load your SME, context, and project info

This is where your layer earns its keep. Three kinds of knowledge, three homes:

**SME roles → overlay agents (`.claude/agents/`).** When a domain needs expertise the generic lanes don't have, add an SME agent (a `moqui-engineer.md`, a `saleor-specialist.md`) or **override** a base lane with a version that knows your stack. Follow the agent format and the build discipline in [`skills/agent-build.md`](skills/agent-build.md): a scoped tool allowlist, its own memory dir, a pinned model, non-overlapping lane boundaries. Keep the WHAT/HOW/WHO mantra intact — an SME implementer is still an implementer, not a second architect.

**Your stacks and rulings → overlay standards (`standards/`).** A standard is a *reusable cross-project convention* — how your team does Moqui migrations, which CI tool you deploy with, your naming rules. It gets the same treatment as a base standard: frontmatter `version`, a `standards/CHANGELOG.md` entry in your layer, `breaking: true` when a consumer must change to comply. Your agents read these the same way they read the base's — the architect reads all standards when writing a WO's Context; infra-devops reads the security + CI standards before wiring a pipeline. When your standard covers a stack the base doesn't ship, satisfy the base's generic **contract** for that class of thing (the CI/CD pattern standard states the contract every delivery path must meet) rather than inventing from scratch — see the worked example in [`EXTENSION.md`](EXTENSION.md#adding-a-new-stack-worked-example).

**Private project info → `context/` (never leaves your layer).** Client and project names, cluster/registry/namespace names, secret *locations* (never values), decision logs, work orders, who-owns-what, STATE/backlog for the layer itself. This is the material the base team must never contain. It stays in your layer's `context/` and is **never** eligible to be upstreamed. The boundary table in [`EXTENSION.md`](EXTENSION.md#what-is-core-generic-vs-overlay-entity) is the definitive "core vs. overlay" test — when unsure which side a fact belongs on, that table decides.

**Wire it together in your layer's `CLAUDE.md`.** It imports the base's operating rules and adds only what's yours:

```markdown
## Dev team — operating instructions
The base team lives in `.devteam/`. All rules in `.devteam/CLAUDE.md` apply — the mantra,
foreman triage, work-order rules, HITL checkpoints, standards enforcement.

## This team
<who we are, what we build, our repos, our stacks>

## Our layer
- Overlay agents: `.claude/agents/` (SME roles + overrides)
- Overlay standards: `standards/` (our stacks)
- Private context / state: `context/`

## Triage overrides
<domains that route to a specific SME agent for us — keep short>
```

Only override where your team genuinely differs from base-native behavior; inherit everything else.

## 4. Work as a team

Day-to-day, a session is driven by the **foreman** (the main Claude Code session) who triages each ask and routes it to the right lane — never by pasting chat history between agents, always by passing a **work-order path**. The triage heuristic, the HITL checkpoints (when to pause for a human decision vs. run the chain end-to-end), and the WO format are all in [`CLAUDE.md`](CLAUDE.md); the WO template is in `memory/shared/work-orders/_template.md`. The one thing to internalize: **the mantra keeps lanes clean** — if the product-manager starts picking a stack, or the architect starts writing user stories, or the project-manager starts making scope calls, stop and re-route. Non-overlapping ownership is what keeps handoffs tight enough to survive a black-box agent boundary.

Because all resume-state lives in git (STATE.md, backlog.md, work orders — see [`skills/session-rituals.md`](skills/session-rituals.md)), any teammate on any machine with repo access picks up exactly where the last session left off. That is the point of the file-on-disk discipline: the team is portable, not tied to one person's session. For a team, that portability is the collaboration model — there is no shared live session; there is shared git state.

## 5. Contribute back and expand the base

The system improves in **both** directions, and this is a standing duty, not a nice-to-have:

- **Top-down:** base standards and agents flow down to every team through the pin.
- **Bottom-up:** when your team's work reveals a **gap** (no standard covers this), a **better method** than the current standard, or a missing agent role that is **generic** — you propose it back to the base so every team gets it.

The gate is what keeps the public base clean: an overlay file may be upstreamed **only if it is generic** — no infrastructure specifics, no identities (org/client/employee/project names), no secrets or secret locations, no per-machine paths, no internal history ("we learned this on <date>"), and it must be **versioned** (frontmatter bump + `CHANGELOG.md` entry). The full checklist is [the scrub gate in `EXTENSION.md`](EXTENSION.md#the-scrub-gate--what-may-go-upstream), and the PR flow is in [`CONTRIBUTING.md`](CONTRIBUTING.md). State the rule, not the war story: the lesson goes up, the context that made it concrete stays in your `context/`.

**How a contributor (yes, an LWW engineer) expands the base:** open a feature branch on the base repo, add or edit the generic file with its version bump + changelog entry, run it through the scrub-gate checklist yourself, and open a PR. A maintainer reviews it against the same checklist and — for a standards change — treats the version bump as the approval event. Entity-specific material never makes this trip; if the scrub gate strips so much that nothing generic is left, it was overlay material, and it stays in your layer. Net: every team is both a **consumer** of the base and a **scout** improving it.

## Where to go next

- [`ONBOARDING.md`](ONBOARDING.md) — the fast single-repo adoption (start here if you're truly one repo)
- [`EXTENSION.md`](EXTENSION.md) — the overlay precedence model, the core-vs-overlay boundary, and the scrub gate, in full
- [`skills/project-bootstrap.md`](skills/project-bootstrap.md) — the authoritative submodule + agent-discovery + upgrade mechanics
- [`skills/agent-build.md`](skills/agent-build.md) — how to author an SME agent that fits the roster
- [`CLAUDE.md`](CLAUDE.md) — the operating rules every session runs under: mantra, triage, HITL, work orders
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — PR flow and the version-event rule for standards
