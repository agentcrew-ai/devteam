---
version: 1.0.0
updated: 2026-08-25
breaking: false
---

# Writing Voice

How agent-drafted prose should read before a human sends it. This is the generic standard. The instance-specific parts (which file you paste the rule into, who approves a version bump, which review skill path) belong in the consuming environment's overlay — **never** in this library.

## Principle

An agent drafts fast, but it drafts in a recognizable accent: hedged, padded, abstract nouns standing in for verbs, every paragraph shaped as bold claim then explanation then dramatic closing line. That accent is harmless in a scratch note and damaging in anything a client, a stakeholder, or a colleague reads.

The target voice is a technically deep executive explaining a complicated project to another smart person. Plain, direct business English. Decisive, conversational, practical. Say what is known, what is not, and what still needs confirming.

**Cutting corporate vocabulary must never cost technical precision.** Every fact, number, hostname, date, decision, risk, and recommendation survives the edit.

## Rules

### Use the simplest accurate word

| Instead of | Write |
|---|---|
| disposition list | server plan |
| approval gate | approval |
| gated on | waiting on, blocked by |
| tractable | manageable |
| authoritative source | system of record |
| diarise | put on the calendar |
| re-baseline | review again, reassess |
| independently actionable | can be approved separately |
| materially reduces risk | reduces the risk |
| the largest schedule risk | the biggest thing that could delay us |

Prefer verbs to abstract nouns. "If we register this as a Standard Change, we won't need a separate approval for every server" beats "Registration of the Standard Change removes the requirement for individual approvals."

### Keep genuine technical terms

Specialized vocabulary stays exactly as it is. The target is corporate and agent vocabulary, not technical vocabulary. Acronyms, product names, protocol names, schema terms, and infrastructure nouns are not jargon just because a general reader would need to look them up.

### Don't lean on these as a recurring structure

Occasional use is fine. Repetition is the tell.

"This is X, not Y." / "The headline is..." / "The good news is..." / "The honest framing is..." / "What this unlocks..." / "Where this lands..." / "This is the fastest (cheapest, largest)..." / "That is a legitimate position..." / "This gets decided on evidence, not guessed..." / "It is worth naming..." / "The failure mode is..." / "The key takeaway is..."

Go easy on em dashes; commas, parentheses, and periods usually do the job. Vary paragraph shape so it isn't always claim, explanation, closer.

### Don't sell decisions

State the facts, the recommendation, the consequence, and what needs deciding. If the facts already make the case, stop writing.

Keep strong human lines that sound like an operator talking, rather than sanding them smooth. "Two, not nine, on purpose." "We never migrate something we could have deleted." "Finding that out now is cheap. Finding it out at 3am Sunday with billing down isn't."

## Scope

Applies to prose a human reads: pull-request descriptions, commit message bodies, documentation, chat and email drafts, client-facing deliverables, and code comments that explain reasoning.

Does not apply to code identifiers, log messages, error strings, config keys, or anything a machine parses. Commit subject lines follow imperative-mood convention rather than this standard; the body is prose and does apply.

## Review

Drafting and reviewing are separate passes, and the reviewer **does not rewrite**. It reports each issue as original phrase, why it reads unnatural, and a direction. The author writes the fix.

This is deliberate. A reviewer that hands back a finished sentence gets pasted in unread, and the author ends up sounding like the tool. Making the author write the fix is what transfers the skill.

Consuming environments provide the review pass as an agent skill. The skill's path and invocation live in the overlay.

## Final pass

Before sending anything substantial:

1. Would an experienced practitioner actually say this out loud?
2. Is there a simpler word that means the same thing?
3. Is this sentence carrying information, or just sounding authoritative?
4. Am I repeating a construction I used two paragraphs ago?
5. Could this be half as long without losing anything?
6. Did I strip out real technical precision by accident?
