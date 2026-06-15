# Changelog

All notable changes to skillet are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **brigade-handoffs** - sets up and checks Brigade handoff inboxes for repos and agent workspaces, writes linted local drafts, reviews the pending queue, and keeps canonical memory changes review-gated.
- **reduce** - behavior-preserving code simplification for the code you just changed: establishes a behavior lock (find or write characterization tests, baseline-verify green) before touching anything, then boils off the excess one category at a time and re-runs the same verification after each change, on the rule that there is no applied simplification without behavior-preservation evidence. Targets nested control flow, dead code, genuine duplication, and clever-dense code; refuses premature abstraction, DRY past readability, and the removal of load-bearing redundancy (validation, defensive checks, logging, retries, compat shims). Tidies but does not redesign: design-level changes go to a report, never auto-applied. Applies by default for changed code with tests, drops to report mode when behavior cannot be locked, defaults scope to the git diff, commits one category at a time, and hands correctness to bug-hunt, security to security-sweep, and repo-wide quality to line-check.

## [0.2.0] - 2026-06-12

The process-skill release: eight new skills covering the full build loop, from idea to executed plan, with the daily disciplines alongside. The chain is mise -> recipe -> fire, and every new skill was baseline-tested against a fresh agent before it shipped.

### Added

- **mise** - mise en place for building: turns an idea into a design the user approved and a written spec before any code. Reads context, proposes 2-3 approaches with a recommendation, presents a design scaled to its complexity, and hands off to recipe. Composes with pressure-test for hardening the load-bearing decisions instead of duplicating its interrogation. First of skillet's process skills for the daily build loop.
- **recipe** - turns an approved spec into an implementation plan a zero-context engineer or fresh session can execute alone: reads the code first, maps the file structure, decomposes into bite-size test-first checkbox steps carrying the actual code and exact commands with expected output, pins every decision, and self-reviews for spec coverage and placeholders before handing off to execution. Completes the mise-to-recipe chain.
- **fire** - executes a written plan task by task: isolated branch or worktree, critical read of the plan against the actual code before task 1, brigade mode (fresh implementer subagent per task) or solo mode with the same discipline, checkboxes ticked as the live worklist, structural divergences stopped and returned to the plan's author instead of improvised, and a four-option finish (merge, PR via pass, keep, discard) with worktree cleanup rules. Completes the mise-recipe-fire chain.
- **taste** - test-first discipline built to survive exactly the moments it gets skipped: the failing test is written and watched failing before any implementation code, "don't gold-plate" is a scope instruction not a testing waiver, manual smoke tests don't count, and code written before its test gets deleted and rebuilt from the test.
- **refire** - root-cause-first debugging: read the whole error, reproduce, check what changed and what the documented contract says, trace the bad value to its source, then pin the bug with a failing test before one minimal fix. Three failed fixes triggers an architecture conversation instead of a fourth attempt.
- **sendback** - review-feedback reception with technical rigor: every claim verified against the codebase before implementation, a clarity gate that stops guessed interpretations of vague items, a YAGNI gate that greps for callers before adopting speculative API surface, evidence-based pushback, and a ban on performative agreement and gratitude openers.
- **stations** - the expeditor's fan-out for parallel subagents: triage clusters failures by root cause before any dispatch, shared-cause clusters go to one station, write sets are checked for collisions (serialize or isolate in worktrees), every station gets a complete self-contained ticket with constraints and an output contract, and the integrated full-suite verification stays with the coordinator.
- **check** - evidence before claims: no "done", "fixed", or "passing" without the proving command run fresh and its output quoted in the same reply. Treats subagent success reports as claims to verify against the diff and a run of your own, treats a failing verification as the finding (manufacturing fixtures to force an exit 0 is fabricating evidence), and ends with a mechanical pre-send checklist (git status reconciled, every file touched during verification disclosed). Verification note: baseline-failed and verified on small models, where coordinators relayed fabricated reports and laundered evidence; capable models passed the baseline unaided. The skill raises the floor; it does not make a small model a safe coordinator.

### Changed

- **expedite**, **pass**, and **mise** state their process discipline inline (test-first, root-cause tracing, verification, plan handoff) instead of referencing external skills, and now cross-link the new in-house skills where one applies.
- The README's mise entry links miseledger directly, and the marketplace plugin description enumerates the full roster.

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

[Unreleased]: https://github.com/escoffier-labs/skillet/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/escoffier-labs/skillet/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/escoffier-labs/skillet/releases/tag/v0.1.0
