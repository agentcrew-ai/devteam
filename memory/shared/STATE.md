# STATE — devteam

_Single source of "where were we, where to pick up." Read this first every session (per `skills/session-rituals.md`)._

Last updated: 2026-08-29

## Current work

- **Branch `standards/infra-helm`** — Order 048 landed: `standards/infra/helm.md` at v1.0.0, opening the `infra/` lane. CHANGELOG entry added as v0.4.0, additive. `CLAUDE.md` now lists `standards/infra/` in the `infra-devops` required-reading line. **Committed locally, not pushed, not merged, not tagged** — the maintainer approves version bumps. Run note below.

### Order 048 run note — what the order assumed, what was actually true

The order came from task T-1X, which said to dispatch two agents in parallel against two archived work-order drafts to unblock a `standards-v1.1.0` tag. Three of those premises were dead.

**T-1V's premise is dead and the task can be closed.** T-1V waits on PR #10 in the archived repo merging. That PR is `CLOSED`, not merged, the repo behind it is archived and private, and the current public core was re-extracted from scratch rather than carried across. The two work-order drafts were never in this repo's history. Nothing can clear that blocker by merging, because there is nothing to merge.

**The SOPS half was already shipped under a different name.** `standards/security/sops-age.md` has been at v1.0.1 since the retroactive scrub. Authoring `security/sops.md` as the draft specified would have produced a duplicate. The lane is closed; the genuine gaps found while checking it are in `backlog.md` as one proposed minor bump to the existing file, not a second standard.

**The version number in the task was from a retired numbering line.** `standards-v1.1.0` never existed. The only tag in this repo is `v0.1.0`. The new standard lands under CHANGELOG v0.4.0.

**The draft was translated, not ported.** The Helm draft predates the public cut and is grounded in one specific cluster — node hostnames, cluster and service CIDRs, a named TLS vendor, a named cross-namespace propagation controller, three tenant names, a named CI vendor, and a dozen absolute paths inside a private infrastructure repo. Every one of those is material the `EXTENSION.md` scrub gate forbids in core. The standard keeps the shape of each rule and replaces each specific with a placeholder or a named pattern class: `values-<env>.yaml` rather than "environment-specific overrides", `runAsNonRoot`/`fsGroup`/`seccompProfile` rather than "appropriate security context", "a reflector-class controller" rather than the product. The draft also declared cross-cloud portability a non-goal because every consumer targeted the same cluster. That reasoning does not survive the repo going public, so the standard is Kubernetes-flavored and distribution-agnostic.

**Branch point differs from the order's instruction, deliberately.** The order said to branch off `develop`. `develop`'s CHANGELOG is at v0.1.0 while the live line is at v0.3.1 on `chore/public-scrub`, and `chore/public-scrub` contains every commit `develop` has. A v0.4.0 entry appended to `develop` would sit on top of v0.1.0 with the v0.2.0 and v0.3.x entries missing. `standards/infra-helm` branches from `chore/public-scrub` so the entry follows the version it claims to follow. This makes the branch-lineage problem below more urgent, not less.

- **Branch `standards/voice-and-mcp-adoption`** — Order 015 landed: `standards/writing/voice.md` v1.0.0 → v1.1.0, folding in ASD-STE100 Simplified Technical English plus four density rules that had been proposed and never versioned. CHANGELOG entry added as v0.3.0. **Committed locally, not pushed, not merged** — the maintainer approves version bumps. Run note below.

### Order 015 run note — what we took from STE, what we left

Source: <https://www.asd-ste100.org/about_STE.html> (Issue 9, Jan 2025: 53 writing rules in 9 sections, ~900-word approved dictionary, plus per-industry technical terminology).

**Taken.** One word one meaning — STE's central rule, and the one our standard only gestured at. Written both directions: a term means one thing throughout, and one thing carries one name. Active voice with the actor named, which STE treats as absolute and we had soft; passive now allowed only in descriptive text where the actor genuinely does not matter, and called a defect in anything procedural. One instruction per sentence, with STE's 20/25-word caps carried as a smell test for procedural text and its warning against dropping subjects/verbs/articles to hit the count. The approved-term list, which is STE's real contribution here — we already keep technical vocabulary deliberately, but leaving it to taste is what makes the rule unenforceable across authors and months, so the list is now an overlay artifact. The noun/verb ambiguity ban, scoped to cases where the sentence parses two ways rather than STE's full one-part-of-speech restriction. Noun stacks capped at three.

**Left.** The approved-vocabulary restriction itself. A closed 900-word dictionary works because a maintenance manual never weighs a tradeoff or persuades anyone; ours has to do both, and the restriction would remove the argument along with the padding. Also left: the sentence-length caps as applied to analysis. A paragraph reasoning about a tradeoff sometimes needs a long sentence, and chopping it into six short ones makes the argument harder to follow. Both exclusions are stated in the standard with the reasoning, so the next person to read STE does not re-litigate them.

**Why the split lands there.** STE was built for a reader executing a step, where ambiguity becomes an accident. Our documents split between readers executing and readers deciding. The new Scope table grades the precision rules by that axis — hardest on runbooks, build specs, and agent-read order packets; lightest on client-facing argument. The density rules run the other way and get stricter as documents get more persuasive, because that is where padding hides.

**Also versioned.** The four rules from the voice review that had never reached a version event: resolve your own references, one fact per paragraph stated once, borrowed jargon must earn its place, state the consequence or cut the paragraph. Underneath all four, the deeper one — stop when the point is made. Per the EXTENSION.md scrub gate, these are stated as rules with no provenance; the originating document and date stay out of core.

- **Branch `docs/team-guide`** (off `develop`) — adds `TEAM-GUIDE.md`, the team/org-scale adoption doc (stand up your own layer repo around the base team, load SME/context/project info, work as a team, contribute back). README updated to link it. **Committed locally, not yet pushed.** Next step: HITL-confirm push → open PR → target `develop`.

## Resume from here

1. **Reconcile branch lineage first, before anything is pushed.** `develop` is at CHANGELOG v0.1.0, `main` at v0.2.0, the scrub line at v0.3.1, and `standards/infra-helm` at v0.4.0 on top of the scrub line. Two different standards shipped as v0.2.0 on different branches. Decide the integration order, then push and PR in that order — pushing `standards/infra-helm` into a `develop` that lacks v0.2.0 through v0.3.1 produces a CHANGELOG with holes in it.
2. Review `standards/infra/helm.md` and approve or revise the v0.4.0 version bump. Nothing is pushed or tagged until then.
3. If `docs/team-guide` is unmerged: confirm push with the user, `git push -u origin docs/team-guide`, open PR into `develop`, squash-merge (docs branch).
4. Then decide the open items below.

## Open items / decisions for the user

- **Core repo is PUBLIC.** Visibility was flipped and a retroactive scrub audit was run against the working tree, every branch, and the full git history. No credentials, keys, tokens, private IPs, or private hostnames were found in tree or history. Adopting-team identifiers, one private task reference, and several dated internal rulings were found and removed on branch `chore/public-scrub`. Two residual items are recorded below and need a maintainer decision.
- **`develop` is behind `main` and behind the scrub line, and one version number is used twice.** PR #1 (`standards/backup-dr`, v0.2.0) merged straight to `main`, bypassing `develop`. Separately, the `chore/public-scrub` line carries its own v0.2.0 (writing voice, MCP servers, work intake) plus v0.3.0 and v0.3.1. So `develop` sits at v0.1.0, `main` at v0.2.0, the scrub line at v0.3.1, and **v0.2.0 names two different sets of changes depending on the branch.** Reconcile the lineage, pick which v0.2.0 keeps the number, and fix the flow so future work goes feature → develop → main.
- **backup-dr standard is still `PROPOSED`.** Not yet approved/adopted. Needs a version-event sign-off from the maintainer.
- **Commit author identity is a work email address on 12 of 14 commits**, across every branch and on tag `v0.1.0`. It is visible on every commit page of a public repo. Changing it means rewriting published history — a maintainer decision, not a code change.
- **PR #1's description is public and describes private infrastructure**, including a cross-reference to a pull request in a private repo. It is editable on GitHub without touching git history, but it is an outward-facing edit and needs an explicit go-ahead.
- **Stale merged branch.** `origin/standards/backup-dr` can be deleted (merged via PR #1).

## Watch out for

- STATE.md and backlog.md did not exist before 2026-07-14 — the previous session shipped the core-publish work without leaving a resume pointer. These are now created; keep them current per the ritual.
