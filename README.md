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

### Daily workflow

| Skill | What it does |
|-------|--------------|
| **pressure-test** | Interrogates a plan or design until the important decisions are explicit, one question at a time. Includes sous mode: going AFK? The agent asks its own hard questions, answers them from evidence, and leaves you an auditable Q&A transcript. |
| **publish-readiness** | The gate before a repo goes public: working-tree and git-history leak scans, hygiene checks, and the full history-rewrite recipe for when something already leaked. |
| **release-cut** | Changelog roll-up, semver bump, tag, GitHub release, drafted announcement. Releases on request, never per feature. |
| **memory-handoff** | Ends a session by writing durable knowledge into a structured handoff a memory owner can review and file. Pairs with brigade, works standalone. |
| **skillify** | The meta-skill: turn a script, runbook, or repeated workflow into a new skill, with a fresh-agent test before you call it done. |

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
/pressure-test   (add "answer your own questions, I'm going afk" for sous mode)
```

line-check, bug-hunt, and security-sweep are read-only by design. They produce reports and backlogs; applying fixes is a separate step you stay in control of.

## Why these exist

Every skill here is extracted from a real workflow that broke or burned time the manual way: repos published with internal hostnames in the history, audits that produced walls of findings nobody prioritized, releases with mismatched versions, sessions whose hard-won knowledge died in the transcript. The skills encode the procedure plus the gotchas.

## License

MIT
