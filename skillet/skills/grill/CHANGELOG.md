# grill changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.1.3 - 2026-10-20

- Run the scan script through an interpreter (`bash scripts/grill-scan.sh <file>`) so the instruction works on install routes that do not preserve the executable bit. Found by the new lint rule for bare script references; the rule and the finding are adapted from the obra/superpowers (MIT) release notes.

## 0.1.2 - 2026-08-08

- Added the shared Untrusted content section required for skills that ingest external data.

## 0.1.1 - 2026-08-08

- Added deterministic unit tests for `scripts/grill-scan.sh` under `tests/` (14 cases covering each scanner section, exit codes, and the fence-aware tilde check) and declared the test command in skill.json, per the repository script-test contract.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
