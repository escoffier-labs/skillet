# reduce changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Added a two-axis reader-load test (layers to trace, state to hold) and the 30-second question; a refactor whose reader load did not drop is reverted. Adapted from pstack by Lauren Tan (MIT).
- Comments are treated as symptoms: a workaround comment is reported and routed to its root cause, a "do not change this" comment is reported as an unencoded constraint (apply mode may add a characterization test), and reduce stays behavior-preserving.
- Renames now require grepping for the old name in strings, prose, config, and back-references.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
