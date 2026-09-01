# Spec: skill-refresh

Date: 2026-08-31
Status: approved

## Problem

Installed skillet-core copies can match each other across harnesses and still be wrong. `brigade skills fleet status` reports unregistered copies as `unknown`, so it is not a content audit. Blind sync from skillet origin can overwrite live policy patches.

## Skill

- Name: `skill-refresh`
- Home: `skillet/skills/skill-refresh/`
- Install: user harness skill dirs after merge
- Not: `skillify` (new skills), `stocktake` (package deps), harness-specific skill scaffolding

## Procedure the skill encodes

1. Inventory owned harness skill roots.
2. Pin sources of truth: the skillet git checkout, canonical `AGENTS.md`, and `~/.brigade/roster.toml` (cite disagreement, do not bake seats).
3. Hash-compare skillet-core SKILL.md files.
4. Fact-grep retired tools, barred models, down lanes.
5. Classify each id: `sync` / `keep-local-patch` / `install-missing` / `retire` / `leave`.
6. Report. Apply only after the report, unless the user already approved a named apply set.

`brigade skills fleet|sync|install|diff` are wrappers, not the whole audit. Fleet `unknown` is not current.

## Protected local patches

- `graphtrail` compatibility bodies that already route through `brigade code`. Do not restore retired GraphTrail MCP instructions over them.
- Harness-only `seo-fleet` copies. Skillet replaced that skill with `garnish`. Do not delete the harness copy, and do not add `seo-fleet` to the skillet repo.

Operator-specific first applies (install missing stations, rewrite private fleet skills, retire dead local skills) stay on the machine. They are not part of this repository change.
