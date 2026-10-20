# stations changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Added `references/dispatch-contract.md` shared with fire: model and effort on every dispatch, DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT with detail in a file, no worker-spawned workers, controller never pre-judges a reviewer, fix-round limits. Adapted from obra/superpowers (MIT).
- Added a race shape (first pass, rank all, best of, declared before dispatch) beside partition. Adapted from pstack by Lauren Tan (MIT).
- Triage now asks whether one codemod does all N edits, tells each worker to write its own result file instead of sharing a write target, and drops any result missing its required evidence. Independent workers dispatch in one message.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
