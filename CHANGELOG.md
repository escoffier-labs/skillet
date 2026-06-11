# Changelog

All notable changes to skillet are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **mise** - mise en place for building: turns an idea into a design the user approved and a written spec before any code. Reads context, proposes 2-3 approaches with a recommendation, presents a design scaled to its complexity, and hands off to the implementation plan. Composes with pressure-test for hardening the load-bearing decisions instead of duplicating its interrogation. First of skillet's process skills for the daily build loop.

## [0.1.0] - 2026-06-10

First public release: eleven production-tested skills for auditing, improving, and shipping repos with AI coding agents.

### Added

- **line-check** - seven-station repo audit that scores each station and delivers a backlog sorted by impact relative to effort. Brigade-aware.
- **bug-hunt** - correctness sweep across five lenses with mandatory adversarial verification; only bugs that survive a refutation attempt are reported.
- **security-sweep** - defensive security audit (secrets in tree and history, dependency CVEs, injection, authn/authz, exposure), each finding shipped with its remediation.
- **expedite** - drives an audit backlog to done in leverage order, one verified change per finding, parking anything destructive or breaking for you to decide. The execution partner to the audit trio.
- **pressure-test** - drives a plan to explicit decisions before anyone builds, each pinned to its basis. Sous mode makes the reversible calls when you go AFK and leaves an auditable, basis-tagged transcript.
- **plate** - per-artifact prose hygiene gate: scrubs outward-facing writing for internal hostnames, private IPs, leaked paths, and AI-authorship disclosures, and applies your writing conventions, previewing every change first.
- **pass** - the gate before a pull request leaves your hands: real-fix-not-bandaid, tested and green, one concern, self-reviewed diff, clean artifact, and a PR body you approve before it is filed.
- **publish-readiness** - the gate before a repo goes public: working-tree and git-history leak scans plus the full history-rewrite recipe for when something already leaked.
- **release-cut** - changelog roll-up, semver bump, tag, GitHub release, and a drafted announcement. Releases on request, never per feature.
- **memory-handoff** - ends a session by writing durable knowledge into a structured handoff a memory owner can review and file. Pairs with brigade, works standalone.
- **skillify** - turns a script, runbook, or repeated workflow into a new skill, with a fresh-agent test before you call it done.
- A shared audit report contract (`docs/audit-report-format.md`) so line-check, bug-hunt, and security-sweep findings compose into one leverage-sorted backlog.
- Claude Code plugin marketplace manifests and a content-guard pre-push hook.

[Unreleased]: https://github.com/escoffier-labs/skillet/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/escoffier-labs/skillet/releases/tag/v0.1.0
