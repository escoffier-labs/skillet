# Dispatch contract

Rules for any controller that sends work to subagents or brigade workers: [stations](../SKILL.md) fan-outs, [fire](../../fire/SKILL.md) brigade mode, fleet lanes. Adapted from obra/superpowers (MIT) and pstack by Lauren Tan (MIT).

## Every dispatch

- **Name the model and the effort.** An omitted model inherits the controller's top tier, so a swarm of readers quietly runs at the most expensive setting. Pick per task: a small mechanical edit gets a cheap tier; a review or a tangled change gets the strongest. Use whatever model set the operator's policy permits.
- **Hand over files, not pasted blobs.** Write the brief and the diff to files and give the paths. A long diff pasted into a prompt gets truncated or skimmed.
- **Dispatch independent workers in one message,** so they run concurrently. Sequential dispatch of independent work is the slow path.
- **No subagent tools in this harness?** Say so once and run the work inline. Never invent a dispatch call.

## What workers return

One status word, with the detail in a report file the controller reads:

| Status | Meaning | Controller does |
|---|---|---|
| DONE | Finished, evidence attached | Read the report and the diff, then verify |
| DONE_WITH_CONCERNS | Finished, but something smells | Read the concerns before accepting; decide each |
| BLOCKED | Cannot proceed | Change something (context, scope, model), then redispatch |
| NEEDS_CONTEXT | A fact is missing | Supply it, then redispatch |

A report without the evidence the ticket required (the verification command and its output, the SHAs, the diff) is dropped. A gap never counts as a pass.

## Who may dispatch

Implementers and reviewers never dispatch helpers. One worker is one flat pass. Fan-out belongs to the controller, who can see all the write sets; a worker that spawns its own workers breaks the collision check silently.

## Reviewers

- The controller never tells a reviewer what to ignore and never pre-rates severity. A defect the plan mandated is reported, not waved through.
- The review is read-only: no checkout, reset, or staging in the working tree under review.
- Treat the author's report as unverified. The reviewer reads the actual diff.

## Fix rounds

This rule is for stations fan-outs. [fire](../../fire/SKILL.md) and [fleet-conductor](../../fleet-conductor/SKILL.md) set their own caps (fire's blocked-task and failed-verification stops, fleet-conductor's two attempts per lane), and theirs take precedence.

In a stations fan-out, resume the same worker for fix rounds one through three: it has the context. After three, a fresh and stronger worker takes over with the full history in a file. Five rounds is the cap; after that the task goes back to a human or its plan's author, because the plan or the split is probably wrong.
