# fleet-conductor changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Added worker control rules: standing orders pasted on every spawn with TIMEBOX, FORBIDDEN, and REPORT ticket fields; a single publisher; liveness judged by side effects; retry by failure mode with abandonment after two; fresh consolidated workers instead of chained resumes. Adapted from pstack by Lauren Tan (MIT).
- Added a verdict ledger keyed by PR plus head SHA where a new head voids the verdict, with `git patch-id` deciding whether a rebase kept it.
- Loosening a gate needs a conductor countersign that never substitutes for required human or forge approval. An existing PR or claimed fix switches the lane to verify mode. Queued is not merged.
- Templates live in `references/worker-control.md`; existing two-review and merge-evidence gates unchanged.

## 0.1.0 - 2026-08-23

- Added bounded lane, held-trigger, collision, draft-readiness, check, review, and merge-evidence contracts for multi-repository campaigns.
