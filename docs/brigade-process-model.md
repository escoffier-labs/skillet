# Brigade process model (the loop)

The canonical definition of the Brigade work loop that skillet skills plug into: **brief -> work -> verify with capture -> handoff**. `using-skillet`, `check`, and `memory-handoff` each own one slice of it and inline only their slice. This document is the source of truth when their wording drifts, the same role the [audit report format](audit-report-format.md) plays for the audit skills.

The framing is a process model with named gates (Ralf Kneuper, *Software Processes and Life Cycle Models*, Springer, 2018, [doi:10.1007/978-3-319-98845-0](https://doi.org/10.1007/978-3-319-98845-0)): one definition of the loop, gates with explicit pass conditions and owners, and per-skill references instead of per-skill restatements. Three skills had described the loop in three different ways. One canonical definition prevents that wording from drifting again.

## Provider and fallback

- **Provider: the Brigade CLI** ([brigade](https://github.com/escoffier-labs/brigade), `pipx install brigade-cli`). `brigade init` wires a repo (`.brigade/` config and hooks) and injects the `brigade-work` skill, which ships from Brigade, not from this repo. Brigade owns the loop mechanics: session briefs, verify receipts, the outcome ledger, and handoff lint and ingestion.
- **Fallback: skillet standalone.** Without Brigade every skill still works: `check` runs the proving command raw and `memory-handoff` self-reviews instead of running `brigade handoff lint`. The discipline is identical. Without receipts, nothing feeds the next run's evidence brief.

## The loop

1. **Brief.** Before real work, read what the system already knows: `brigade work brief`, or the brief injected into the session. The brief carries constraints, open items, and, when the ledger has receipts, measured hit rates from prior runs.
2. **Work.** Do the task. Skillet's process skills govern how (mise -> recipe -> fire for building, refire for debugging, and so on). The loop does not care which skills do the work, only that the gates are honored.
3. **Verify with capture.** Every completion claim is proved by a fresh run of the proving command, routed through Brigade so the exit code becomes a receipt the outcome ledger can score:

   ```bash
   brigade work verify run --target . --command "<proving command>" --capture <skill-or-card-id>
   # or after a brigade run that changed code:
   brigade outcome capture <skill-or-card-id> --run-receipt latest
   ```

   When GraphTrail/MiseLedger are installed, receipts feed the next run:

   ```bash
   brigade receipts export miseledger --target . --new-only --import
   ```

4. **Handoff.** Before the session closes, durable knowledge goes into a structured memory handoff in the repo inbox, linted (`brigade handoff lint`) and review-gated by the memory owner.

## The gates

| Gate | Name | Guards against | Pass condition | Owner |
|---|---|---|---|---|
| G1 | Brief gate | Work starting uninformed | The brief has been read (or confirmed absent) before real work starts | `brigade-work` (Brigade-provided), routed by `using-skillet` |
| G2 | Evidence gate | Claims without proof | The proving command ran fresh, through `brigade work verify run --capture` when Brigade is wired, and the claim quotes its output | `check` |
| G3 | Handoff gate | Knowledge dying with the transcript | Durable knowledge is written as a linted handoff before the session closes | `memory-handoff` |

The gates are compliance points, not suggestions: a session that skips G2 has no claims to make, and one that skips G3 spent its discoveries. When Brigade is absent the gates still apply. Only the receipts disappear (see Provider and fallback).

## What each skill owns

- **`using-skillet`** routes to the loop. It names `brigade-work` in its station catalog and defers the loop definition here. It does not restate the gates.
- **`check`** owns G2: the iron law (no completion claim without fresh verification), the atomic capture form, and the rule that a failed verification is the finding.
- **`memory-handoff`** owns G3: handoff format, quality bar, routing sections, and lint.
- **`brigade-work`** (Brigade-provided, wired by `brigade init`) owns the loop mechanics end to end: briefs, receipts, the outcome ledger, and the measured `brief_hit_rate` that the next run's brief is built from.

## Changing the loop

Change it here, not in a skill. A skill that needs loop context links this document. A skill that restates the loop is a drift bug. Per-skill changelogs record when a skill's slice changed. This document records when the loop itself changed.
