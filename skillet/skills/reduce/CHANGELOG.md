# reduce changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Added a two-axis reader-load test (layers to trace, state to hold) and the 30-second question; a refactor whose reader load did not drop is reverted. Adapted from pstack by Lauren Tan (MIT).
- Comments are treated as symptoms: a workaround comment is fixed at the root, a "do not change this" comment moves into a test, type, or lint.
- Renames now require grepping for the old name in strings, prose, config, and back-references.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
