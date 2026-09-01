---
name: skill-refresh
version: 0.1.0
license: MIT
description: Use when auditing, refreshing, or syncing installed agent skills across harnesses; when skills look stale, skillet copies drifted, fleet status looks clean but the catalog is old, or the user says "refresh skills", "skill audit", "sync skillet", or runs /skill-refresh. Classifies each skill id, reports, then applies only after the report. Not for creating a new skill (skillify) or package dependencies (stocktake).
---

# skill-refresh

Installed copies can match each other and still be wrong. This skill audits owned SKILL.md trees against skillet, AGENTS.md, and the live roster, classifies every id, and applies only after that report.

**Core principle:** 3-way merge, not one-way sync. Live policy patches, skillet catalog expansion, and AGENTS.md facts can each be the current side.

## Sources of truth

Read these before classifying anything:

1. Skillet catalog: the git checkout that contains `skillet/skills/` (commonly `~/repos/skillet`). If `git status -sb` shows behind origin, extra clones or worktrees, or uncommitted skill edits, name them. Do not sync from a dirty or secondary checkout.
2. Skill-facing policy: the machine's canonical `AGENTS.md` (commonly `~/.codex/AGENTS.md`).
3. Dispatch roster: `~/.brigade/roster.toml`. If AGENTS.md and the roster disagree, say so. Do not bake a seat name into a skill.

`brigade skills fleet status` is a registry view. Copies it marks `unknown` were never imported; that is not proof they are current. Wrap `brigade skills fleet|diff|install|sync` for registry-backed ids. Hash-compare disk copies for the rest.

## Owned roots

```
~/.grok/skills
~/.claude/skills
~/.codex/skills
~/.cursor/skills
~/.openclaw/workspace/.grok/skills
~/.openclaw/workspace/.claude/skills
~/.openclaw/workspace/skills
~/.agents/skills
```

Skip vendor trees (Grok bundled skills, marketplace plugin caches, `node_modules`). Claude's skillet plugin cache at `~/.claude/plugins/cache/skillet/` is a snapshot, not a source of truth.

## Classify

For each skill id, pick one:

| Class | When |
|---|---|
| `sync` | Live copy is an older skillet-core body with no local policy patch. Copy from skillet. |
| `keep-local-patch` | Live body matches current AGENTS.md and skillet origin does not. Leave live. Say whether skillet should take the patch later. |
| `install-missing` | Skillet or an approved custom skill is absent from a harness that already runs its siblings. |
| `retire` | The procedure points at deleted paths, a retired product, or a skill that fights a canonical skillet station. Replace with a stub that still triggers and tells the agent to stop. |
| `leave` | Current, harness-private and still used, or out of the requested scope. |

Protected patches (do not `sync` skillet origin over these):

- `graphtrail` 0.2.0: Brigade Code Graph through `brigade code`. Never restore GraphTrail MCP tools or `graphtrail sync`.
- `seo-fleet` on harness copies: fleet SEO contract. Skillet replaced it with `garnish`. Do not delete the harness copy, and do not add `seo-fleet` to the skillet repo.

Fact-grep live SKILL.md files for retired GraphTrail/MiseLedger app or MCP use, barred GPT-5.5 / GPT-5.3 Spark, default Cursor cloud / `composer-2.5` volume, `--model fable` on worker seats, and instructions to edit `MEMORY.md` directly. A hit is not automatically `retire`; classify against AGENTS.md.

## Report then apply

Report first:

```markdown
# skill-refresh: <date>
Mode: AUDIT | APPLY
Skillet: <commit> <ahead/behind origin>
Roster vs AGENTS.md: <agree | disagreement>

## Classification
| id | class | why | action |

## Protected patches
## Deferred
```

Apply only after the user accepts that report, or when they already approved a named apply set in this session. Never `sync --write` across all harnesses in one shot.

When applying `sync` or `install-missing`, copy the whole skill directory (`SKILL.md`, `skill.json`, `CHANGELOG.md`, `references/`, `scripts/`). After catalog changes, keep `using-skillet` honest: name installed stations, do not advertise skills that are not on disk for that harness.

## Common mistakes

- Treating `brigade skills fleet` `unknown` or `stale=0` as a clean bill of health.
- Syncing skillet origin `graphtrail` over the `brigade code` wrapper.
- Dropping harness `seo-fleet` because skillet 0.6.0 replaced it with `garnish`.
- Listing uninstalled stations in `using-skillet`.
- Baking Cursor/composer seat names instead of citing AGENTS.md and the roster.
- Refreshing the OpenClaw unique dump in the same pass as skillet-core without an explicit janitor scope.
