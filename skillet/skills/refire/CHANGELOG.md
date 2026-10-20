# refire changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Investigation gains: reproduce on the surface the user hit, a legitimacy test for the triggering state with a persisted-state hint, and a "say what you do not understand" step.
- Fix loop gains: sibling sweep, a cheap always-on signal, revert what a refuted hypothesis motivated, and a premise check at two failed fixes (the three-failure stop is unchanged).
- Added a "no root cause found" exit that allows labeled containment only.
- Added `references/` (root-cause-tracing, defense-in-depth, condition-based-waiting) and `scripts/find-polluter.sh` with deterministic `tests/test-find-polluter.sh`. Adapted from obra/superpowers (MIT) and pstack by Lauren Tan (MIT), in our own words.
- `find-polluter.sh` treats a check exit other than 0 (present) or 1 (absent) as a broken check and exits 2; the rerun hint is shell-quoted. SKILL.md and the tracing reference state the fresh-process limit and tell the agent to prove the check by hand first.
- Root-cause-tracing reference lists alternative causes (parallel interference, resource exhaustion, timing, environment) and requires evidence of shared persistent state before using the script; the script header says "ordered two-file reproduction" instead of "pair search".

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
