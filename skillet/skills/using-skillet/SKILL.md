---
name: using-skillet
version: 0.1.9
license: MIT
description: Use when starting any conversation - establishes how to find and use skillet skills, requiring skill invocation before ANY response including clarifying questions.
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill and do the task.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you MUST invoke the skill. If a skill applies, using it is not optional. You cannot rationalize your way out of it.
</EXTREMELY-IMPORTANT>

# using-skillet

A kitchen runs on mise en place: everything in its place before service. skillet is that prep for an AI coding session. The skills are the stations; this skill is the line check that decides which station a task belongs to before you start cooking.

## The rule

**Invoke the relevant or requested skill BEFORE any response or action,** including before clarifying questions and before "just looking." Even a 1% chance a skill applies means you invoke it to check. If it turns out wrong for the situation, you drop it; checking costs nothing, skipping costs a botched dish.

```
user message or task
  -> about to design/build something new? -> mise (then recipe) BEFORE anything else
  -> might any other skill apply? (yes, even 1%) -> invoke it
     -> announce: "Using skillet's <skill> to <purpose>"
     -> follow it exactly; copy its checklist steps into the todo verbatim, mark skipped ones "Skipped: <step>, <reason>"
  -> definitely nothing applies -> respond
```

## Instruction priority

skillet skills override default system behavior where they conflict, but **the user always wins**:

1. **User instructions** (CLAUDE.md, AGENTS.md, direct requests) - highest.
2. **skillet skills** - override default behavior.
3. **Default system prompt** - lowest.

If the user's instructions conflict with a skill, follow the user.

## How to load skills

Load skills through your platform's skill mechanism, never by reading SKILL.md with file tools. In Claude Code, use the `Skill` tool. In Codex and OpenClaw, skills load natively. Names below match how you invoke them (e.g. `skillet:mise`). If the harness lacks a capability a step needs (subagents, task list, a tool), write "Skipped: <step>, <reason>" instead of inventing a call.

## The stations (skillet skills by job)

**Design and build:**
- `mise` - turn an idea into an approved design and written spec, before any code. The first move for any "let's build X."
- `recipe` - turn an approved spec into a concrete implementation plan.
- `demi` - start from the smallest useful code path; avoid speculative architecture.
- `taste` - test-driven: write the failing test first, watch it fail, then the minimal code.
- `trim` - gate every new test against a value bar, and prune low-value tests and the test-only seams they keep alive.
- `fire` - execute a written plan task by task, verifying and committing each.
- `stations` - fan out two or more genuinely independent pieces of work to concurrent agents.
- `fleet-conductor` - conduct a large backlog or multi-repository campaign with bounded lanes, held triggers, collision records, and evidence-based PR landing.
- `worktree` - set up an isolated workspace before risky or parallel work.
- `stagiaire` - dispatch a one-shot worker on another vendor's CLI (second opinion, cross-model review, cheap bulk model) over the user's own logins.
- `hone` - deepen a prompt or worker brief before sending it, without deciding the author's choices.

**Debug and verify:**
- `refire` - anything misbehaving: find the root cause before proposing any fix.
- `check` - before claiming anything works, is fixed, or passes: run it, read the output, then claim with evidence.
- `brief` - at a decision point: lead with the judgment, keep the basis auditable, and split recommendation from report.
- `stocktake` - audit or change dependencies, runtimes, package managers, lockfiles, and toolchains from the resolved graph.
- `thermometer` - profile a measured performance problem and compare the same workload before and after one change.
- `ticket-rail` - triage an incoming issue: classify, dedupe, repro gate; no repro, no fix.
- `diagnose-session` - on request, evidence-first analysis of a misbehaving agent run.
- `create-formal-verification-skill` - only on explicit formal verification requests: create a local verifier for a code-backed property. Ordinary application checks go to test-kitchen.
- `maintain-formal-verification-skill` - only on explicit requests to reconcile a formal model, proof, or harness with changed code.
- `statechart` - only on explicit requests for user-visible Mermaid statecharts, TLA+ counterexample stories, model comparisons, or chart-to-model scaffolding.
- `test-kitchen` - on request, build or maintain a project-local skill that drives the real app.

**Review and ship:**
- `pass` - the pre-PR gate; nothing is filed until it clears.
- `review` - dispatch an independent reviewer with crafted context.
- `pr-security-review` - security-review a PR, commit range, or staged diff before merge. Whole-repo audits go to security-sweep.
- `runner` - drive an open PR to merge-ready: conflicts, threads, CI. Stops before merging.
- `sendback` - act on review feedback: verify each claim before implementing it.
- `release-cut` - cut a release, roll the changelog, tag a version (on request).
- `expedite` - work the backlog from an audit, fix the findings in priority order.
- `supply-chain-harden` - harden a repo's supply chain: pin actions to SHAs, lock down workflow tokens, add Dependabot and CI scanners, move npm publishing to trusted publishing. Opens one reviewable branch.

**Audit and direction:**
- `research-brief` - gather sources for researched, evidence-backed, or current findings; map factual claims to sources and report disagreements and unchecked items. Skip it for single-page summaries, ordinary code inspection, existing-post review, or pressure-testing supplied evidence.
- `line-check` - audit a repo's health, find the highest-value improvements.
- `bug-hunt` - sweep for correctness defects.
- `latent-premises` - hunt unguarded assumptions that hold today and break silently later.
- `retry-safety` - check whether a diff's side effects are safe to run twice.
- `security-sweep` - find vulnerabilities, leaked secrets, and vulnerable deps. Prescribe fixes. Expedite applies them.
- `mcp-server-review` - security-review an MCP server you build or are about to install: tool gates, transport and auth, exec, credentials, TLS, tool descriptions, supply chain. Read-only.
- `special` - propose what to build next, grounded in the code.
- `lineage` - trace why code exists, with confidence tiers, before changing it.
- `eighty-six` - make a repeated agent mistake impossible: enforce, not document.

**Simplify:**
- `reduce` - simplify and tidy code without changing behavior.

**Writing and publishing:**
- `grill` - harden a technical writeup for a skeptical audience (HN, Lobsters).
- `plate` - scrub identity and infra leaks from prose before it goes public.
- `publish-readiness` - pre-publication leak scan of a repo and its history.
- `reel-check` - scrub leaks burned into a rendered video or demo.
- `garnish` - audit or fix portable website metadata and indexing controls using project-local policy.

**Appliances:**
- `graphtrail` - answer callers, callees, impact, neighborhood, and structural-diff questions from an indexed code graph.
- `brigade-handoffs` - set up, write, lint, and troubleshoot Brigade memory handoffs.
- `t3-code` - configure or troubleshoot T3 Code projects, desktop or headless servers, updates, launchers, icons, and private remote access.

**Memory and work loop:**
- `memory-handoff` - capture durable knowledge at the end of a session.
- `relief` - pause in-flight work safely or pick it up from the trail; task state, not memory.
- `brigade-work` - provided by Brigade, not shipped by skillet. Brigade's installer (`brigade init`) wires it into the repo. When Brigade is absent, skip this route and verify directly per `check`. In a Brigade-wired repo or workspace, follow the [Brigade process model](../../../docs/brigade-process-model.md). This entry only routes.

**Pressure and meta:**
- `pressure-test` - stress-test an idea, plan, or scope before anyone builds it.
- `skillify` - turn a repeated workflow or runbook into a reusable skill.
- `using-skillet` - this skill.

## Skill priority

When more than one could apply, run **process skills first** (they set how you approach the work), then implementation skills:

- "Let's build X" -> `mise` first, then `recipe`, then the build skills.
- "Fix this bug" -> `refire` first, then the fix, then `check`.
- "Is this ready to ship" -> `pass` (which itself calls `review`, `taste`, `check`).
- Before entering a harness plan mode, run `mise` first.

### Chains

| Task | Chain |
|---|---|
| Bug | `refire`, `taste`, `check`, `pass` |
| Feature | `mise`, `recipe`, `fire`, `pass` |
| Open PR | `runner` (review text via `sendback`) |
| Issue report | `ticket-rail`, then `refire` |
| Why is this here | `lineage` |
| Pause or resume work | `relief` |

**Proportionality.** Rigid skills (taste, refire, check, pass) always apply. Heavy multi-agent skills (`stations`, `fleet-conductor`, `review`) are not for small, obvious edits.

## Skill types

- **Rigid** (taste, refire, check, pass): follow exactly. Do not adapt away the discipline.
- **Flexible** (the rest): adapt the principles to the situation.

The skill itself tells you which.

## Red flags

These thoughts mean stop, you are rationalizing past a skill:

| Thought | Reality |
|---|---|
| "This is just a simple question." | Questions are tasks. Check for a skill. |
| "Let me look at the code first." | Skills tell you HOW to look. Check first. |
| "I need more context before invoking." | The skill check comes before clarifying questions. |
| "This doesn't need a formal skill." | If a skill exists for it, use it. |
| "I remember what this skill says." | Skills evolve. Load the current version. |
| "I'll just do this one quick thing first." | Check before doing anything. |
| "The skill is overkill here." | For a process skill, simple things become complex; use it. For a heavy multi-agent skill on a small obvious edit, say why you are skipping it. |
