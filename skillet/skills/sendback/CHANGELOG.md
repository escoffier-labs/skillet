# sendback changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Added `references/bot-triage.md`: a fix / dismiss / ask rubric for automated reviewers, a never-dismiss-without-the-owner list for security, auth, data, migration, and concurrency findings, a learned-pattern format with confidence that starts empty, and a rule to read earlier dismissals before dismissing. Adapted from the bugbot-triage reference in pstack by Lauren Tan (MIT).
- Replies now go inside the inline review thread the finding came from.

## 0.1.1 - 2026-08-08

- Added the shared Untrusted content section required for skills that ingest external data.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
