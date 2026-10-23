# using-skillet changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.1.9 - 2026-10-23

- Routes `create-formal-verification-skill`, `maintain-formal-verification-skill`, and `statechart` into the station list.

## 0.1.8 - 2026-10-20

- Routes `pr-security-review`, `supply-chain-harden`, and `mcp-server-review` into the station list.

## 0.1.7 - 2026-10-20

- Routes the eight new skills (`runner`, `eighty-six`, `relief`, `lineage`, `hone`, `ticket-rail`, `test-kitchen`, `diagnose-session`) into the station list.
- Added a compact Chains table, a rule to copy checklist steps into the todo verbatim and mark skipped ones "Skipped: <step>, <reason>", a "Skipped: <step>, <reason>" line for missing harness capabilities, and `mise` before any harness plan mode. Adapted from obra/superpowers (MIT) and pstack by Lauren Tan (MIT).
- Added a proportionality line (rigid skills always apply, heavy multi-agent skills are not for small obvious edits) and narrowed the "overkill" red-flag row without weakening the 1% invocation rule for process skills.
- Trimmed existing prose to keep the injected skill compact.

## 0.1.6 - 2026-09-24

- Routes `trim` for writing tests and pruning low-value ones.

## 0.1.5 - 2026-08-24

- Routes `brief` at a decision point: lead with the judgment, keep the basis auditable, and split recommendation from report.

## 0.1.4 - 2026-08-08

- The `brigade-work` routing entry now references the canonical Brigade process model (`docs/brigade-process-model.md`) instead of restating the loop.

## 0.1.3 - 2026-08-08

- Labeled the `brigade-work` route as provided by Brigade (wired in by `brigade init`), not shipped by skillet, and named the fallback when Brigade is absent: skip the route and verify directly per `check`.

## 0.1.2 - 2026-08-08

- The `brigade-work` route now shows the complete atomic verification form with `--target`, `--command`, and `--capture` arguments.

## 0.1.1 - 2026-07-09

- The `brigade-work` routing entry now describes closing the measured loop: brief at start, verify via `brigade work verify run` (or capture from a run receipt), outcome capture, and receipt export to MiseLedger when installed, so the next run gets an evidence brief with a measurable `brief_hit_rate` instead of only a handoff.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
