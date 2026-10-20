# review changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Range pin now uses `git merge-base` against the default branch (or a recorded task-start commit) instead of `HEAD~1`, and says why `HEAD~1` and a bare `origin/main` are wrong.
- Reviewer prompt gains: read-only, no helper agents, author report as unverified claim, reasonable-user judgment for unnamed behavior graded by effect, severity calibration, and a "Declined to judge" list before the verdict. Adapted from obra/superpowers (MIT).
- Trigger description rewritten to state when to use the skill, not the process.

## 0.1.1 - 2026-08-08

- Added the shared Untrusted content section required for skills that ingest external data.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
