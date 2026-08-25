---
version: 1.0.0
updated: 2026-08-25
breaking: false
---

# Work Intake and Ticket Discipline

Where work comes from, and what an agent owes the tracker while doing it. This is the generic pattern. Which tracker you use, its workspace, and your cross-reference key belong in the consuming environment's overlay — **never** in this library.

## Principle

**Every unit of work traces to a ticket in the tracker.** No ticket, no work.

This is not bureaucracy. An agent can produce a week of output in an afternoon, and output nobody asked for is worse than no output — it consumes review time, it competes for attention with work that was actually prioritized, and it is invisible to everyone who isn't reading the terminal it happened in. The ticket is what makes agent work legible to people who weren't in the session.

The tracker is also the only place a blocker becomes someone else's problem. Work that stalls silently in a session stays stalled. Work that stalls against a ticket gets seen.

## Intake

Work starts from a ticket, not from a conversation.

When a request arrives outside the tracker — chat, a hallway conversation, an idea mid-session — the first step is a ticket, before any code is written. If the request is too vague to write a ticket for, it is too vague to start.

Two narrow exceptions, both time-boxed:

**Triage of a live incident.** Fix first, ticket immediately after, before the session ends.

**A spike to answer a feasibility question.** The output is an answer, not code you keep. Ticket it if the answer turns into work.

Neither exception permits finishing a feature and writing the ticket afterward to make the board look right.

## Work orders carry the ticket

Where agents coordinate through work orders, every work order references the ticket that authorized it. A work order without a ticket reference is not ready to dispatch.

This gives one traceable chain from request through planning to the lane that did the work, and it survives after the session context is gone.

## What the agent writes back, and when

Three moments, no more. The tracker is a shared surface, not a session log — a running commentary is worse than silence because it trains everyone to stop reading.

**On start.** Move the ticket to in-progress and note what is being attempted. This is what stops two people picking up the same ticket.

**On blocker.** Say what is blocking, what would unblock it, and who is needed. Name the person or the decision. "Blocked" with no object is not a status, it is a shrug. This is the highest-value write of the three and the one most often skipped.

**On completion.** What changed, where to see it (branch, PR, artifact), and anything the reviewer needs to know that isn't obvious from the diff. Move the status.

Between those moments, the session is the right place for progress. The ticket is not.

## Boundaries

**The tracker is not a scratchpad.** Do not create tickets to organize an agent's own subtasks. If the work needs decomposition, that lives in the work order or the session, not on a board other people read.

**Write as an identity that can be held accountable.** Which identity an agent acts as is governed by the MCP server adoption standard. Ticket writes are attributed writes, and attribution is the point.

**A shared tracker is production.** In an environment where the tracker is shared with a client or another team, agent write access carries the same weight as any other change to a shared system. Scope it deliberately.

## Overlay responsibilities

The consuming environment's overlay carries: which tracker is the system of record, the cross-reference key used to tie tickets to other systems, the ticket-ID format and the fact that it is an external reference rather than an internal key, which statuses map to start and completion, and who to name when raising a blocker.
