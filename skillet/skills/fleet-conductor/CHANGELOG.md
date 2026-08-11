# fleet-conductor changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.1.0 - 2026-08-11

- Added the fleet-conductor skill: campaign triage, bounded lane assignment, collision and held-trigger tracking, draft-until-gates landing loop, required-vs-optional check handling, and merge verification from GitHub `MERGED` + `mergeCommit` + `mergedAt`.
- Includes the shared Untrusted content section; listed in `EXTERNAL_CONTENT_SKILLS`.
- Baseline-tested against a fresh agent before it shipped (trigger description fires on campaign/landing-loop prompts; single-PR prompts stay on pass).
