# security-sweep changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.1.2 - 2026-10-20

- Secret scans now report locations only (rule, file, line, commit). Replaced the `git log --all -p | grep` recipe, which printed every matched secret into the transcript, with a gitleaks JSON field projection and location-only git fallbacks. Notes that the gitleaks `Message` field is not redacted and that commit messages need their own `git log --grep` pass. Tested against a throwaway repo with planted tokens.
- The gitleaks block sets an exit and signal trap so the report is removed even when a scan fails or is interrupted, and the tree fallback uses `git grep --untracked`.

## 0.1.1 - 2026-08-08

- Added the shared Untrusted content section required for skills that ingest external data.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
