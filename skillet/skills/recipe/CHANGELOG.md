# recipe changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Plans now record decisions, not a transcript of the code: each step names the test and its assertions with the spec's literal values, the signature, the file, and the exact command and expected result. Bodies appear only where signature plus tests do not determine the algorithm, or for tasks marked `transcribe` for a cheap worker.
- Replaced the "questionable taste" framing with a capable-reader framing; a step is one action with a checkable result.
- Plan header gains Spec, Global Constraints, and Review Focus; each task gains an Interfaces block (Consumes / Produces) and an optional "You see" line for user-visible tasks.
- Self-review adds a proportion check (plan length versus spec length).
- Handoff: the user reads the saved plan first, and the plan recommends solo or subagent execution in fire with a one-sentence reason.
- Adapted from obra/superpowers writing-plans (MIT) and pstack's multi-phase-plan playbook by Lauren Tan (MIT).

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
