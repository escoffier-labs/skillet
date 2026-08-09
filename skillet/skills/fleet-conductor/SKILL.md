---
name: fleet-conductor
version: 0.1.0
license: MIT
description: Use when orchestrating large parallel work across codex, Cursor cloud agents, and Claude - burn-downs, backlog sweeps, multi-repo campaigns. The frontier session conducts (triggers, decisions, relays) and never implements; every expensive lane has a cheaper substitute. Triggers on "burn down the backlog", "spin up agents", "use up quota", "conduct the fleet".
---

# fleet-conductor

A burn-down across a fleet is not one cook working faster; it is a conductor keeping every seat busy while spending frontier tokens only where nothing cheaper can decide. This skill orchestrates large parallel campaigns across Codex, Cursor cloud agents, Claude subagents, and the operator's other lanes. The conductor (this session, on the frontier model) spends tokens on exactly three things: dispatch triggers, irreversible decisions, and relaying reports. Everything else has a cheaper seat.

**Core principle:** if you are about to read a diff, run a test, rebase a branch, or write more than a paragraph of code or prose, stop - that is a dispatch.

For fan-out within one repo and write-set collision checks inside a session, see [stations](../stations/SKILL.md). For one-shot cross-vendor CLI dispatches without a fleet campaign, see [stagiaire](../stagiaire/SKILL.md).

## Seat ladder (cheapest lane that can do the job wins)

| Work | Seat | How |
|---|---|---|
| Mechanical implementation, tests, docs | Cursor cloud, composer-2.5 | POST api.cursor.com/v0/agents (API key from your credential store) |
| Judgment implementation, cross-file features | Cursor cloud, cursor-grok-4.5-high | same |
| Implementation on expiring OpenAI quota | codex cloud | `codex cloud exec --env <repo>`; returns UNAPPLIED diffs |
| PR landing / merge shepherding | codex sol thread (operator-started) | standing shepherd prompt; loops ready→CI→review→merge |
| Bulk annotation, changelog rollups, pre-review triage | codex luna thread | near-free; comments only, never merges |
| Review sweeps of merged work | kimi k3 (+k2.7 second lens) | regression-issue filings, capped |
| Work needing LOCAL state (receipts, rollouts, clipboards) | Claude subagent via Agent tool | background, and NOT on the frontier model unless cross-file judgment is unavoidable |
| Decisions, collisions, releases | conductor + operator | never delegated |

## Prompt contract (every dispatch)

Self-contained fixed scope: the issue list IS the scope; agent reads the GitHub issue for spec ("read the issue with gh; this summary only routes you"). Append the standing guardrails footer: 2 attempts per item then skip-with-comment; **a blocked item never dams the queue**; infrastructure failure stops only that repo's items; terminal state per item is {merged-with-review, PR-open-green, skipped-commented}; timebox; capture outcomes + [Memory Handoff](../memory-handoff/SKILL.md); stop at terminal - never self-extend scope.

## Collision rules (learned the hard way)

- Same-file siblings never run concurrently: hold dependent issues, dispatch each on its sibling's MERGE (not PR-open). Track helds explicitly; fire each as a single call on its trigger.
- One local brigade-run lane per repo (run.lock); cloud VMs are exempt (isolated clones).
- One worker per branch - including across machines. A wedged session's claims stay held ~1 hour before takeover.
- Two agents in one repo: instruct "keep shared-surface touchpoints minimal; another agent works #N concurrently".

## Landing loop (shepherd's algorithm)

Cursor cloud PRs arrive as DRAFTS: `gh pr ready` first. Then: wait CI (ignore external stuck checks like CodeRabbit; required set = the Actions checks) → review diff against linked issue (scope, tests, no secrets/leaks - public repos) → squash-merge → DIRTY merges get one rebase in a fresh worktree (changelog/roadmap conflicts = union of both entries; regenerate parser-checked generated files from the branch, never hand-edit) → verify merges via `gh pr view --json state,mergeCommit`, not exit codes.

Codex cloud tasks: `codex cloud list` → `diff` (review) → `apply` in a fresh worktree → targeted tests via the repo's verify wrapper → PR with `Fixes #N` + Codex trailer → remove worktree.

Agents sometimes finish WITHOUT opening their PR: check `gh api repos/<r>/branches` for orphaned `cursor/*` branches and open the PRs manually. Failed campaigns often leave real work in local branches - push and dispatch "finisher" agents FROM those branches instead of redoing from scratch.

## Cadence

1. Inventory ground truth from GitHub (PRs/issues), never from agent self-reports.
2. Dispatch everything independent at once; hold same-file siblings.
3. Landing capacity scales with production - a wave of PRs without a shepherd is a pile, not progress.
4. On each completion report: fire held triggers, re-inventory, relay to operator in one paragraph.
5. Escalate to operator only: release cuts, scope changes, approach collisions between two valid PRs, anything destructive.

## Quota triage

Match work to the quota that expires first. Deadlines ranked by expiry; volume goes to 2x/promo/near-free lanes (composer, grok, luna); frontier-session tokens are the scarcest resource in the fleet - see the model routing table in your harness docs (for example AGENTS.md) for current seat benchmarks.

## Common mistakes

- Implementing on the frontier because "it is faster than dispatching." That is the conductor leaving the podium to chop onions.
- Trusting agent completion reports instead of re-inventoring GitHub. Reports are claims; the issue and PR list is ground truth.
- Dispatching same-file siblings on PR-open instead of MERGE. You get merge conflicts and two half-fixes that each looked green alone.
- Landing a wave of PRs without a shepherd. Open PRs are inventory, not shipped work.
- Redoing work from scratch when a failed campaign left real diffs on a local branch. Push the branch and dispatch a finisher from there.
