---
version: 1.1.0
updated: 2026-08-29
breaking: false
---

# Writing Voice

How agent-drafted prose should read before a human sends it. This is the generic standard. The instance-specific parts (which file you paste the rule into, who approves a version bump, which review skill path) belong in the consuming environment's overlay — **never** in this library.

## Principle

An agent drafts fast, but it drafts in a recognizable accent: hedged, padded, abstract nouns standing in for verbs, every paragraph shaped as bold claim then explanation then dramatic closing line. That accent is harmless in a scratch note and damaging in anything a client, a stakeholder, or a colleague reads.

The target voice is a technically deep executive explaining a complicated project to another smart person. Plain, direct business English. Decisive, conversational, practical. Say what is known, what is not, and what still needs confirming.

**Cutting corporate vocabulary must never cost technical precision.** Every fact, number, hostname, date, decision, risk, and recommendation survives the edit.

Several rules below are borrowed from [ASD-STE100 Simplified Technical English](https://www.asd-ste100.org/about_STE.html), the controlled language aerospace and defence have used for maintenance documentation since 1986. STE was built so a reader with limited English could follow a procedure without guessing, and its discipline around ambiguity is decades ahead of anything we would invent ourselves. We take its precision rules and leave its vocabulary restriction — see [What we do not take from STE](#what-we-do-not-take-from-ste).

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

### One word, one meaning

Within a single document, a term means one thing in every sentence. This is STE's central rule and the one worth the most to us.

If "service" means a systemd unit in paragraph two, it cannot mean a business offering in paragraph six. If "environment" means a deployment target, it cannot also mean a shell's variables. Pick the meaning the document needs most, and rename the other one.

The same rule runs the other way: one thing gets one name. Don't call it the "job runner" in the overview, the "worker" in the sequence diagram, and the "executor" in the config table. A reader who has to work out that three names are one component has stopped reading for content and started reading for translation.

Where two meanings genuinely both belong in the document, qualify both every time they appear — "the systemd service" and "the customer service" — rather than relying on context to disambiguate.

### Active voice, and name the actor

Write who does what. "Argo CD syncs the manifest" beats "the manifest is synced."

Passive voice is allowed in one case: descriptive text where the actor is genuinely unknown or genuinely does not matter to the reader. "The certificate was issued in March" is fine when nobody cares which CA issued it. It is not fine when the reader's next question is *by whom*.

In anything procedural, passive voice is a defect. A step that says "the config is backed up" does not tell the operator whether that is their job or something that already happened. Say "Back up the config" or "The pipeline backs up the config."

Watch for the disguised passive — an abstract noun standing in for the actor. "Approval is required before deployment" hides the two facts the reader needs: who approves, and who deploys.

### One instruction per sentence

For procedural text — runbooks, build steps, setup guides, order packets, machine-read instructions — one sentence carries one action. Compound steps get split, not comma-spliced.

STE caps procedural sentences near 20 words and descriptive sentences near 25. Treat those as a smell test rather than a hard limit: a 40-word instruction is almost always two instructions wearing one sentence, and splitting it costs nothing. Applying the same cap to analytical prose is not appropriate — see the exclusions below.

Do not hit the limit by dropping words. Removing the subject, the verb, or the article to shorten a step makes it shorter and more ambiguous, which is the wrong trade. Split the sentence instead.

Keep noun stacks short. Three words is the working ceiling; "deploy pipeline secret injection failure mode" is a parsing exercise, not a phrase.

### Keep genuine technical terms — and write the list down

Specialized vocabulary stays exactly as it is. The target is corporate and agent vocabulary, not technical vocabulary. Acronyms, product names, protocol names, schema terms, and infrastructure nouns are not jargon just because a general reader would need to look them up.

STE's contribution here is the discipline of recording that vocabulary rather than leaving it to each author's taste. A project keeps an **approved-term list** in its overlay: the technical nouns and verbs this domain uses, each with its one meaning, plus the near-synonyms that are not to be used for them. Ten to thirty entries covers most projects. The list is what makes "one word, one meaning" enforceable across authors and across months, instead of a rule everyone agrees with and nobody applies the same way.

Put the list where drafting agents read it. A term list nobody loads is decoration.

### Don't use one word as both noun and verb where it can be misread

STE assigns each dictionary word a single part of speech, because a word that is both a noun and a verb creates a sentence that parses two ways. We do not need the full restriction, but we do need the outcome.

"Test the backup" and "run the backup test" are clear. "Backup test failures increased" is not — the reader cannot tell whether backups are failing or the test is. Reach for a different word for one of the two roles, or add the article and verb that force a single reading.

The common offenders in our writing: build, deploy, release, log, monitor, cache, mount, alert, request, run, backup. When one appears twice in a paragraph in two different roles, rewrite one of them.

### Resolve your own references

A document either resolves a reference or carries it. Citing a draft by name, a section number in a document the reader does not have, or a filename they cannot open is not a reference — it is a note to yourself left in the shipped text.

If the reader needs it, include it: the link, the quoted paragraph, the actual number. If they do not need it, cut the citation. "As covered in the architecture draft" earns its place only when the reader can open the architecture draft from where they are standing.

This applies hardest to anything crossing an organizational boundary. Internal shorthand survives inside the team and dies on the way out.

### One fact per paragraph, stated once

A paragraph makes one point. Once it is made, the paragraph is over.

The tell is escalating jargon across consecutive sentences — each sentence restating the previous one at a higher level of abstraction, each one sounding more authoritative and carrying less. When you find a paragraph doing that, keep the sentence with the most concrete content and delete the rest.

### Borrowed jargon must earn its place

Terms native to the reader's domain stay. Terms imported from a domain the reader is not in get translated, or defined once on first use and then used consistently.

An infrastructure engineer reading about their own cluster does not need "reconciliation loop" explained. A finance stakeholder reading a status update on the same system does. The test is not whether the term is precise — it is whether this reader already owns it.

Definitions are a budget, not a free action. If a document needs five of them, it is aimed at the wrong reader and needs a different draft, not a glossary.

### State the consequence, or cut the paragraph

Every design or status paragraph says what it buys, or what breaks without it. A paragraph that describes a mechanism and stops is decoration, however accurate it is.

"We put the queue in front of the writer" is half a sentence. "We put the queue in front of the writer so a database restart drops zero events instead of everything in flight" is the whole one.

### Stop when the point is made

Most padding is not filler. It is a sentence explaining something the previous sentence already established.

After drafting, read consecutive sentence pairs and ask whether the second one adds a fact. If it restates, illustrates something already obvious, or reassures the reader that the first sentence was important, delete it. This single pass removes more agent accent than any word-swap table.

### Don't lean on these as a recurring structure

Occasional use is fine. Repetition is the tell.

"This is X, not Y." / "The headline is..." / "The good news is..." / "The honest framing is..." / "What this unlocks..." / "Where this lands..." / "This is the fastest (cheapest, largest)..." / "That is a legitimate position..." / "This gets decided on evidence, not guessed..." / "It is worth naming..." / "The failure mode is..." / "The key takeaway is..."

Go easy on em dashes; commas, parentheses, and periods usually do the job. Vary paragraph shape so it isn't always claim, explanation, closer.

### Don't sell decisions

State the facts, the recommendation, the consequence, and what needs deciding. If the facts already make the case, stop writing.

Keep strong human lines that sound like an operator talking, rather than sanding them smooth. "Two, not nine, on purpose." "We never migrate something we could have deleted." "Finding that out now is cheap. Finding it out at 3am Sunday with billing down isn't."

## What we do not take from STE

STE was designed for maintenance procedures, not for prose an executive reads. Applied whole, it would strip the nuance and argument out of exactly the documents that exist to carry them. A design review is not a maintenance manual.

Two parts of the specification are deliberately out of scope:

- **The approved-vocabulary restriction.** STE's dictionary is roughly 900 general words, and a writer may not use a word that is not in it. That works because a maintenance manual never has to weigh a tradeoff or persuade anyone. Our writing does both. We keep the *principle* — one word, one meaning, recorded per domain — and drop the closed dictionary.
- **Sentence-length caps on analysis.** The 20/25-word ceilings belong to procedures. A paragraph reasoning about a tradeoff sometimes needs a long sentence, and chopping it into six short ones makes the argument harder to follow, not easier. The caps apply where the reader is executing, not where the reader is deciding.

## Scope

Applies to prose a human reads: pull-request descriptions, commit message bodies, documentation, chat and email drafts, client-facing deliverables, and code comments that explain reasoning.

Does not apply to code identifiers, log messages, error strings, config keys, or anything a machine parses. Commit subject lines follow imperative-mood convention rather than this standard; the body is prose and does apply.

### Where the precision rules bind hardest

The STE-derived rules — one word one meaning, active voice with a named actor, one instruction per sentence, the approved-term list — scale with how directly the text drives action.

| Document | How hard the precision rules bind |
|---|---|
| Runbooks, build specs, setup guides | Hardest. Ambiguity here becomes an outage. |
| Order packets and work orders, anything an agent reads and acts on | Hardest. A machine cannot recover a meaning from context the way a colleague can. |
| Commit message bodies, PR descriptions | Hard. Short, procedural, read later by someone without the context. |
| Design reviews, architecture proposals | Lighter. One-word-one-meaning still binds; sentence caps do not. |
| Client status updates, anything making a case | Lightest. Voice, argument, and consequence matter more than mechanical uniformity. |

The rules against padding — one fact per paragraph, state the consequence, stop when the point is made — bind everywhere and get *stricter* as documents get more persuasive. Those are the documents where padding hides.

## Review

Drafting and reviewing are separate passes, and the reviewer **does not rewrite**. It reports each issue as original phrase, why it reads unnatural, and a direction. The author writes the fix.

This is deliberate. A reviewer that hands back a finished sentence gets pasted in unread, and the author ends up sounding like the tool. Making the author write the fix is what transfers the skill.

Consuming environments provide the review pass as an agent skill. The skill's path and invocation live in the overlay.

## Final pass

Before sending anything substantial:

1. Would an experienced practitioner actually say this out loud?
2. Is there a simpler word that means the same thing?
3. Does every term mean exactly one thing throughout, and does every component have exactly one name?
4. Does each sentence say who does the thing?
5. Is this sentence carrying information, or repeating what the last one already said?
6. Can the reader resolve every reference from where they are standing?
7. Does each design paragraph say what it buys or what breaks without it?
8. Am I repeating a construction I used two paragraphs ago?
9. Could this be half as long without losing anything?
10. Did I strip out real technical precision by accident?
