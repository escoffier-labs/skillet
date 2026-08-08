# check changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.1.2 - 2026-08-08

- The verify-with-capture section now names this skill's ownership of the evidence gate and references the canonical Brigade process model (`docs/brigade-process-model.md`) for the full loop. The atomic capture command form is unchanged.

## 0.1.1 - 2026-07-09

- Added a "Brigade-wired repos: verify with capture" section: route the proving command through `brigade work verify run --target . --command "<proving command>" --capture <skill-or-card-id>` so the exit code becomes a receipt the outcome ledger can score, then capture the outcome and export receipts to MiseLedger. Running the proving command raw still proves the claim but leaves Brigade dormant.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
