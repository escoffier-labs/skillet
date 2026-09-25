# trim changelog

## 0.1.1 - 2026-09-25

- Validation: a consolidated row that survives its mutation is repaired before landing; disable bytecode caches during mutation runs; run the full gate outside shell `&` jobs, which ignore SIGINT. All three came from landing the first trim batch on a real repo.

## 0.1.0 - 2026-09-24

- Added trim: authoring gate, audit mode, and subsystem campaign mode for test value, adapted from OpenClaw's MIT-licensed `test-audit` skill with Brigade and skillet tooling in place of OpenClaw-specific scripts.
- Pilot-driven clarifications (read-only audit of a 9-file outcome subsystem): read-only allows history reads and baseline test runs; `pending` evidence when a lane has no shell; sequential lanes without subagents; keepers outside scope and single parametrized rows; hard cases for superseded contracts, private-helper duplicates, and shared helpers tested from consumers; repo verification policy wins; collapsed `R` rows in the report.
