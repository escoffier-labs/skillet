<p align="center">
  <img src="docs/assets/skillet-social-preview.jpg" alt="skillet banner" width="900">
</p>

<h1 align="center">skillet</h1>

<p align="center">
  <strong>A skillet full of agent skills: production-tested workflows that audit, improve, and ship repos with AI coding agents.</strong>
</p>

<p align="center">
  <a href="https://skillet.escoffierlabs.dev"><strong>Website</strong></a> ·
  <a href="#install">Install</a> ·
  <a href="#the-skills">The skills</a> ·
  <a href="#why-not-something-else">Why not something else?</a>
</p>

<p align="center">
  <img src="https://shieldcn.dev/github/release/escoffier-labs/skillet.svg" alt="Latest release">
  <img src="https://shieldcn.dev/badge/skills-29-orange.svg" alt="29 skills">
  <img src="https://shieldcn.dev/badge/license-MIT-green.svg" alt="MIT license">
</p>

skillet is a roster of agent skills for AI coding agents like Claude Code, Codex, and any `SKILL.md`-compatible harness. It encodes the procedures that audit a repo, hunt bugs, sweep for security issues, plan and execute changes, and gate prose and releases before they go public, each one extracted from a real workflow that broke or burned time the manual way. Unlike a single mega-prompt or a hand-maintained `CLAUDE.md`, every skill is a self-contained file that auto-triggers when the work matches it, composes with the others through a shared report contract, and works the same across every harness instead of locking you into one tool.

Part of the [escoffier-labs](https://github.com/escoffier-labs) kitchen, alongside [brigade](https://github.com/escoffier-labs/brigade) (agent memory and handoffs) and the [solos-cookbook](https://github.com/escoffier-labs/solos-cookbook) (the patterns these skills came from).

## What it does

skillet gives an AI coding agent a roster of 29 production-tested skills for the work that surrounds writing code: repo auditing, bug hunting, security sweeps, build planning, test-first execution, prose and repo leak scrubbing, release cuts, and memory handoffs. Each skill is a plain `SKILL.md` file with a trigger description, so the right one fires when you ask naturally ("audit this repo", "is this safe to publish", "cut a release") instead of you remembering a command. The skills share one audit-report contract, so findings from the read-only auditors compose into a single leverage-sorted backlog that the execution skills then drive to done. Install them into Claude Code, Codex, or any `SKILL.md`-compatible harness, per-machine or per-repo, with no runtime dependency and no service to run.

## Install

### Any `npx skills`-compatible harness

```bash
npx skills add escoffier-labs/skillet
```

List the available skills without installing:

```bash
npx skills add escoffier-labs/skillet --list
```

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

## Try it in 60 seconds

```bash
# Any `npx skills`-compatible harness
npx skills add escoffier-labs/skillet --list   # see every skill without installing
npx skills add escoffier-labs/skillet          # install the roster
```

Then ask your agent naturally, or invoke a skill directly:

```
/line-check        # seven-station repo audit, leverage-sorted backlog
/security-sweep    # defensive security audit, each finding with its fix
/publish-readiness # leak scan before a repo goes public
```

Full install paths (Claude Code marketplace, raw `SKILL.md` copy, per-repo) are under [Install](#install).

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
| **worktree** | A clean station before service: sets up an isolated workspace for risky or parallel work, preferring the harness's native worktree tool and falling back to a git worktree. Detects existing isolation first so it never stacks a worktree on a worktree. Pairs with stations and fire. |
| **taste** | Test-first discipline that survives pressure: the failing test is written and watched failing before any implementation, especially when production is down and the instruction is "just make it work". Nothing leaves the kitchen untasted. |
| **demi** | Pre-build simplicity gate: starts with the smallest useful implementation that satisfies the request, fits the repo, and can be verified. Climbs the ladder before custom code (existing behavior, repo primitives, standard library, platform features, installed dependencies, then one local change), cuts speculative scaffolding, names the growth trigger that would justify more, and refuses to treat YAGNI as skimping on validation, security, accessibility, data-loss handling, compatibility shims, or checks. |
| **reduce** | Behavior-preserving simplification: boils the excess off code you just changed and concentrates the intent without altering what it does. Establishes a behavior lock (tests green before and after) before touching anything, refuses load-bearing redundancy and premature abstraction, applies one category per commit, and hands correctness or design issues to bug-hunt, security-sweep, or line-check. Applies by default, drops to a report when behavior cannot be locked. |
| **refire** | Root-cause-first debugging: when something misbehaves, find out why the plate came back before cooking it again. Reproduce, check what changed, check the contract, trace to the source, pin the bug with a failing test, then one minimal fix. Three failed fixes means question the architecture. |
| **review** | The second palate: dispatches a fresh reviewer with crafted context (the diff and the requirements, never your session history) to catch what you have gone nose-blind to. The independent pass that pass calls for; hands its findings to sendback. |
| **sendback** | Receiving review feedback with rigor instead of reflex: verify each claim against the codebase, YAGNI-gate the "should also support" items, stop on vague items instead of guessing, push back with evidence, and skip the performative "great point!" entirely. |
| **check** | The expeditor's look at every plate before it leaves: no claim of done, fixed, or passing without fresh verification evidence in the same reply. Subagent success reports are claims to verify, not evidence to relay, and a failing verification is a finding to report, never an invitation to make the command pass. |
| **stations** | The expeditor's fan-out for parallel agents: cluster failures by root cause before dispatching (a symptom list is not a work breakdown), check write sets for collisions, give each station a complete self-contained ticket, and taste the integrated result yourself. |
| **pressure-test** | Drives a plan or design to explicit decisions before anyone builds, one decision at a time, each pinned to its basis. Includes sous mode: going AFK? The agent makes the reversible calls in your place, tags each answer evidence/constraint/judgment, parks anything it can't take back, and leaves you an auditable transcript. |
| **plate** | The last look before prose goes public: scrubs a blog post, social draft, PR body, or commit message for internal hostnames, private IPs, leaked paths, and AI-authorship disclosures, applies your writing conventions, and previews every change before touching your voice. The per-artifact companion to publish-readiness. |
| **grill** | The hard look at a technical post before it faces a skeptical crowd (Hacker News, Lobsters): kills the effort-proving underdog voice, strips AI-slop and empty hedges, sources or flags every number and third-party claim, checks that a real fact is the right fact for the setup, and runs a comment pre-mortem so the obvious objections are answered before they land. Ships a scanner for the mechanical hits; hands off to plate for the leak scrub. |
| **reel-check** | plate for video: the last look before a rendered reel, screen-recording, or demo MP4 goes public. Scans the composition source (cue captions, title and outro cards, narration, DESIGN.md) for the burned-in leaks, then the recording footage itself for incidental ones (shell-prompt hostnames, URL bars, notifications) that no text scrub can catch. Scrub the source, re-render, then frame-verify the drawn pixels. Hands off to plate for caption prose. |
| **seo-fleet** | The SEO contract for an Astro site fleet whose page heads keep drifting: audits the head for title, description, canonical, Open Graph, and structured-data correctness, fixes what is wrong, and brings each site up to one shared fleet standard so pages index the way they should. |
| **pass** | The gate before a pull request leaves your hands: real-fix-not-bandaid, tested and green, one concern, self-reviewed diff, clean artifact, and a PR body the author approves before anything is filed. The chef's inspection at the pass. |
| **publish-readiness** | The gate before a repo goes public: working-tree and git-history leak scans, hygiene checks, and the full history-rewrite recipe for when something already leaked. |
| **release-cut** | Changelog roll-up, semver bump, tag, GitHub release, drafted announcement. Releases on request, never per feature. |
| **memory-handoff** | Ends a session by writing durable knowledge into a structured handoff a memory owner can review and file. Pairs with brigade, works standalone. |
| **skillify** | The meta-skill: turn a script, runbook, or repeated workflow into a new skill, with a fresh-agent test before you call it done. |
| **using-skillet** | The line check before service: the bootstrap that maps every skillet skill to its job and requires invoking the relevant one before any response. Injected at session start (via the plugin's SessionStart hook) so skills auto-trigger the way the audit trio and daily workflow expect. |

### Brigade

| Skill | What it does |
|-------|--------------|
| **brigade-handoffs** | Sets up and checks [brigade](https://github.com/escoffier-labs/brigade) handoff inboxes for repos and agent workspaces, writes linted local drafts, reviews the pending queue, and keeps canonical memory changes review-gated. |

## Usage

Ask naturally ("audit this repo", "is this safe to publish", "cut a release") or invoke directly:

```
/line-check
/security-sweep
/brigade-handoffs
/pressure-test   (add "answer your own questions, I'm going afk" for sous mode)
```

line-check, bug-hunt, and security-sweep are read-only by design. They produce reports and backlogs; **expedite** is the separate, opt-in step that applies the fixes, parking anything destructive or breaking for you to decide.

## Why not something else?

- **A single mega-prompt or one big `CLAUDE.md`** works until it bloats past the context budget and goes stale, and it loads every instruction on every turn whether the work matches or not. skillet is one self-contained file per job that triggers only when the work matches, so the audit procedure does not cost context while you are cutting a release.
- **Hand-rolling the procedure each session** means the gotcha you learned last month (the repo that published with hostnames in its history, the audit that produced a wall of unprioritized findings) is gone by the next session. Each skill encodes the procedure plus the hard-won gotchas so the floor stays raised.
- **A tool-locked agent framework** ties the workflow to one harness. skillet skills are plain `SKILL.md` files: they install into Claude Code, Codex, or any `SKILL.md`-compatible harness, per-machine or per-repo, the same way.
- **Native harness skill libraries** are great, and skillet is not a replacement for the harness. It is the roster of process skills you drop on top, with a shared report contract so the read-only auditors and the execution skills compose instead of each inventing its own format.

## What skillet is not

skillet is not an agent, a runtime, or a service. It does not:

- run anything on its own or install a daemon, scheduler, or background process
- ship a CLI or a binary; the skills are markdown the harness reads
- carry a runtime dependency or call out to the network on its own
- replace your harness, your model, or your editor
- apply changes from the read-only audit skills (line-check, bug-hunt, security-sweep, special); applying findings is the separate, opt-in **expedite** step
- cut releases automatically; **release-cut** runs on request, never per feature

The skills carry the procedure and the discipline. You stay in the loop for anything destructive, breaking, or public.

## Why these exist

Every skill here is extracted from a real workflow that broke or burned time the manual way: repos published with internal hostnames in the history, audits that produced walls of findings nobody prioritized, releases with mismatched versions, sessions whose hard-won knowledge died in the transcript. The skills encode the procedure plus the gotchas.

## Contributing

Bug reports, sharper skill triggers, and new skills are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the support scope and contribution path, [SECURITY.md](SECURITY.md) for reporting a vulnerability, and the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

MIT. See [LICENSE](LICENSE).
