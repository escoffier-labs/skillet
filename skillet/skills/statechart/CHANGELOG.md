# Changelog

## [0.1.0] - 2026-10-23

### Added

- Explicit-request statecharts, counterexample stories, model comparisons, and chart-to-model scaffolding from pinned pstack sources.
- Offline Node tests and installed-only PNG rendering with failure reporting.
- Codex invocation policy disables implicit selection. Existing task authority is preserved for product fixes.
- Package metadata, source provenance, and MIT attribution. Fresh-agent wording tests were not run in the implementation lane.

### Changed

- Refuse scaffold collisions before writing any file, including directories and dangling symlinks, while preserving existing-model reuse. Offline CLI regressions cover preservation and no partial output.
- Renderer failures suggest `PUPPETEER_EXECUTABLE_PATH` for an installed browser or omitting `--png`.
- Require Node.js 18.15 or later for tests. Generate charts from scratch copies while committed verification models stay at their verify skill's paths.
