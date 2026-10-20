# taste changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.1 - 2026-10-20

- Step 4 now runs the project's own suite even when the task named one file, reports every failure by name including ones not caused by the change, and states that scope bounds the deliverable, not the verification. Adapted from obra/superpowers (MIT).
- Added the revert-the-fix red/green check for regression tests written against a fix that already exists.

## 0.2.0 - 2026-09-24

- RED step now runs trim's authoring gate; added self-derived expectations, behavior-implementing mocks, and per-layer regression replays to common mistakes.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
