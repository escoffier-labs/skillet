---
name: graphtrail
description: Use when answering structural code questions in an indexed repo - who calls this, what does this call, what breaks if I change it, what changed between two versions. Reach for it BEFORE grep whenever the question is about relationships between symbols rather than text. Triggers include "who calls", "what uses", "blast radius", "impact of changing", "callers of", "what depends on", and reviewing a diff's structural effect.
---

# graphtrail

GraphTrail keeps a SQLite code graph (symbols, imports, call edges) per repo, synced incrementally and queryable through 9 MCP tools. The point of this skill: for structural questions, the graph answers in one call what grep answers in five speculative ones, and the graph knows about relationships grep cannot see (cross-file call resolution through imports, transitive impact, before/after structure).

## When to use which tool

- **"Who calls X?"** -> `callers`. **"What does X call?"** -> `callees`. Exact answers from resolved call edges, including cross-file calls resolved through imports. grep finds the string `X(`; the graph finds the actual callers of THIS `X`.
- **"What breaks if I change X?"** -> `impact` with `--depth` for transitive reach. This is the blast-radius question; hop counts tell you how direct the dependency is.
- **"Where is symbol X?"** -> `search` (qualified-name aware, path-filterable). Faster and more precise than grep for symbol lookup; use grep when you want arbitrary text, comments, or strings.
- **"What is around this file?"** -> `file_neighbors` (imports in, imports out, co-change candidates) and `context` for an orientation brief before editing unfamiliar code.
- **"What changed structurally?"** -> `diff` with two DB snapshots (`--before`/`--after`). Reports added/removed/changed symbols (body-hash exact: a body edit with unchanged signature is detected) and call-edge changes, with line-insensitive edge counts alongside raw ones. Brigade attaches these deltas to verify receipts automatically.
- **"Which repos are indexed?"** -> `repos`; per-repo numbers -> `stats`.

## Freshness

The graph re-syncs on a 15-minute timer, at session start (hook), and on demand: query tools accept `refresh: true` to run an incremental sync before answering. Sync is incremental and cheap; a no-op pass is sub-second. Use `refresh: true` when you just wrote code and are about to ask about it.

## When NOT to use it

- Text questions: strings, comments, TODO hunts, log messages. That is grep/ripgrep.
- Pattern-shaped syntax questions ("find every `foo(_, None)` call shape"): that is ast-grep, which matches tree structure by example. The three lanes are exact-graph (graphtrail), tree-pattern (ast-grep), and text (grep). Pick by question shape.
- Repos with no `.graphtrail/` index: check `repos` first; index one with `graphtrail sync <root>` if it should be covered.

## Honest limits

- Call edges include the call line, so raw added/removed edge counts churn on pure line shifts; the diff's line-insensitive counts exist for exactly this. Read both.
- Dynamic dispatch, reflection, and metaprogrammed calls are not in the graph. An empty `callers` result means no STATIC callers.
- The graph is derived state, rebuildable by rescan. When in doubt about staleness, `refresh: true` or `graphtrail sync`.
