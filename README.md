# skillet

A skillet full of agent skills. Production-tested workflows for auditing, improving, and shipping repos with AI coding agents.

Part of the [escoffier-labs](https://github.com/escoffier-labs) kitchen, alongside [brigade](https://github.com/escoffier-labs/brigade) (agent memory and handoffs) and the [solos-cookbook](https://github.com/escoffier-labs/solos-cookbook) (the patterns these skills came from).

## The skills

### The audit trio

Three skills, one report contract ([docs/audit-report-format.md](docs/audit-report-format.md)). Run any of them alone, or all three over time; the findings compose into a single leverage-sorted backlog.

| Skill | What it does |
|-------|--------------|
| **line-check** | The flagship. A chef's line check for your repo: walks seven stations (docs, agent-readiness, tests/CI, hygiene, structure, release hygiene, TODO mining), scores each, and delivers a backlog sorted by impact relative to effort. Brigade-aware: if the repo uses [brigade](https://github.com/escoffier-labs/brigade), its handoff and memory health get audited too. |
| **bug-hunt** | Correctness sweep across five lenses with mandatory adversarial verification. Only bugs that survive a refutation attempt make the report, each with a concrete trigger. |
| **security-sweep** | Defensive security audit: secrets (tree and history), dependency CVEs, injection surfaces, authn/authz, exposure. Every finding ships with its remediation. |

The trio is read-only by design. **expedite** is the step that closes the loop:

| Skill | What it does |
|-------|--------------|
| **expedite** | Takes an audit backlog and drives it to done: highest-leverage finding first, one focused change at a time, each one verified before the next, parking anything destructive or breaking for you to decide. The execution partner to the audit trio. |

### Daily workflow

| Skill | What it does |
|-------|--------------|
| **special** | The chef's special: walks the repo for what is possible rather than what is broken, and proposes net-new features grounded in evidence already in the code (unfinished work, asymmetries, adjacent capability, friction, ecosystem fit). Read-only, leverage-sorted, every proposal tied to a signal in the walk-in and cut if it is ungrounded or fights a stated non-goal. The opportunity-finding counterpart to the audit trio; a chosen special feeds mise. |
| **mise** | Mise en place for building: turns an idea into a design the user approved and a written spec, before any code. Reads the context, proposes 2-3 approaches with a recommendation, presents the design scaled to its complexity, and hands off to recipe. Composes with pressure-test for hardening the load-bearing decisions; [miseledger](https://github.com/escoffier-labs/miseledger) keeps the receipts. |
| **recipe** | Turns an approved spec into an implementation plan a zero-context engineer or fresh session can execute without you: a file map, bite-size test-first steps with the actual code, exact commands with expected output, and every decision pinned. The card the line cooks work from. |
| **fire** | Executes a written plan task by task, the way the line cooks a fired ticket: isolated branch, critical read of the plan against the code first, checkboxes ticked as the live worklist, structural divergences stopped and sent back instead of improvised, and a proper finish (merge, PR, keep, or discard). |
| **taste** | Test-first discipline that survives pressure: the failing test is written and watched failing before any implementation, especially when production is down and the instruction is "just make it work". Nothing leaves the kitchen untasted. |
| **demi** | Pre-build simplicity gate: starts with the smallest useful implementation that satisfies the request, fits the repo, and can be verified. Climbs the ladder before custom code (existing behavior, repo primitives, standard library, platform features, installed dependencies, then one local change), cuts speculative scaffolding, names the growth trigger that would justify more, and refuses to treat YAGNI as skimping on validation, security, accessibility, data-loss handling, compatibility shims, or checks. |
| **reduce** | Behavior-preserving simplification: boils the excess off code you just changed and concentrates the intent without altering what it does. Establishes a behavior lock (tests green before and after) before touching anything, refuses load-bearing redundancy and premature abstraction, applies one category per commit, and hands correctness or design issues to bug-hunt, security-sweep, or line-check. Applies by default, drops to a report when behavior cannot be locked. |
| **refire** | Root-cause-first debugging: when something misbehaves, find out why the plate came back before cooking it again. Reproduce, check what changed, check the contract, trace to the source, pin the bug with a failing test, then one minimal fix. Three failed fixes means question the architecture. |
| **sendback** | Receiving review feedback with rigor instead of reflex: verify each claim against the codebase, YAGNI-gate the "should also support" items, stop on vague items instead of guessing, push back with evidence, and skip the performative "great point!" entirely. |
| **check** | The expeditor's look at every plate before it leaves: no claim of done, fixed, or passing without fresh verification evidence in the same reply. Subagent success reports are claims to verify, not evidence to relay, and a failing verification is a finding to report, never an invitation to make the command pass. |
| **stations** | The expeditor's fan-out for parallel agents: cluster failures by root cause before dispatching (a symptom list is not a work breakdown), check write sets for collisions, give each station a complete self-contained ticket, and taste the integrated result yourself. |
| **pressure-test** | Drives a plan or design to explicit decisions before anyone builds, one decision at a time, each pinned to its basis. Includes sous mode: going AFK? The agent makes the reversible calls in your place, tags each answer evidence/constraint/judgment, parks anything it can't take back, and leaves you an auditable transcript. |
| **plate** | The last look before prose goes public: scrubs a blog post, social draft, PR body, or commit message for internal hostnames, private IPs, leaked paths, and AI-authorship disclosures, applies your writing conventions, and previews every change before touching your voice. The per-artifact companion to publish-readiness. |
| **pass** | The gate before a pull request leaves your hands: real-fix-not-bandaid, tested and green, one concern, self-reviewed diff, clean artifact, and a PR body the author approves before anything is filed. The chef's inspection at the pass. |
| **publish-readiness** | The gate before a repo goes public: working-tree and git-history leak scans, hygiene checks, and the full history-rewrite recipe for when something already leaked. |
| **release-cut** | Changelog roll-up, semver bump, tag, GitHub release, drafted announcement. Releases on request, never per feature. |
| **memory-handoff** | Ends a session by writing durable knowledge into a structured handoff a memory owner can review and file. Pairs with brigade, works standalone. |
| **skillify** | The meta-skill: turn a script, runbook, or repeated workflow into a new skill, with a fresh-agent test before you call it done. |

### Brigade

| Skill | What it does |
|-------|--------------|
| **brigade-handoffs** | Sets up and checks [brigade](https://github.com/escoffier-labs/brigade) handoff inboxes for repos and agent workspaces, writes linted local drafts, reviews the pending queue, and keeps canonical memory changes review-gated. |

## Install

### Claude Code (plugin marketplace)

```
/plugin marketplace add escoffier-labs/skillet
/plugin install skillet@skillet
```

### Any SKILL.md-compatible harness

The skills are plain `SKILL.md` files. Copy what you want into your harness's skills directory, for example:

```bash
git clone https://github.com/escoffier-labs/skillet
cp -r skillet/skillet/skills/line-check <your-skills-dir>/
```

### Per-repo

Drop individual skills into a repo's `.claude/skills/` to share them with everyone who works on that repo.

## Usage

Ask naturally ("audit this repo", "is this safe to publish", "cut a release") or invoke directly:

```
/line-check
/security-sweep
/brigade-handoffs
/pressure-test   (add "answer your own questions, I'm going afk" for sous mode)
```

line-check, bug-hunt, and security-sweep are read-only by design. They produce reports and backlogs; **expedite** is the separate, opt-in step that applies the fixes, parking anything destructive or breaking for you to decide.

## Why these exist

Every skill here is extracted from a real workflow that broke or burned time the manual way: repos published with internal hostnames in the history, audits that produced walls of findings nobody prioritized, releases with mismatched versions, sessions whose hard-won knowledge died in the transcript. The skills encode the procedure plus the gotchas.

## License

MIT
