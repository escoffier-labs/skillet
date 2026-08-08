# using-skillet changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.1.1 - 2026-07-09

- The `brigade-work` routing entry now describes closing the measured loop: brief at start, verify via `brigade work verify run` (or capture from a run receipt), outcome capture, and receipt export to MiseLedger when installed, so the next run gets an evidence brief with a measurable `brief_hit_rate` instead of only a handoff.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
