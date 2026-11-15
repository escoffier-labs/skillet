---
name: graphtrail
version: 0.1.1
license: MIT
description: Compatibility skill for structural code questions in an indexed repo. Use Brigade Code Graph through `brigade code` for callers, callees, impact, affected tests, context, cycles, and graph diffs. Never call the retired application or MCP server directly.
---

# Brigade Code Graph

The `graphtrail` skill id remains as a compatibility alias for existing harness profiles. The supported agent-facing surface is Brigade Code Graph through the `brigade code` command family.

## Start and freshness

Run commands from the repository root.

```bash
brigade code doctor . --json
brigade code sync .
```

Sync before a structural claim when the repository changed after the latest index. The graph is derived state and can be rebuilt.

## Choose the query by the question

- Who calls a symbol: `brigade code callers '<symbol>' --json`
- What a symbol calls: `brigade code callees '<symbol>' --json`
- Transitive blast radius: `brigade code impact '<symbol>' --depth 3 --json`
- Tests attributed to changed files: `brigade code affected <file>... --json`
- Symbol lookup: `brigade code search '<query>' --json`
- File dependencies: `brigade code neighbors <path> --json`
- Task orientation: `brigade code context '<task>' --personalized --markdown`
- Dependency cycles: `brigade code cycles --json`
- Structural comparison: `brigade code diff --before <db> --after <db> --json`

Use `rg` for strings, comments, log text, and arbitrary patterns. Use `ast-grep` for syntax-shaped patterns. Use Brigade Code Graph for resolved relationships between symbols and files.

## Reporting contract

Paste actual impacted symbols and attributed tests into the work reasoning before a non-trivial edit. An empty result means no static relationship was found. It does not prove that dynamic dispatch, reflection, generated code, or runtime configuration has no dependency.

Do not invoke the retired executable, direct MCP tools, or application repository commands. If `brigade code` is unavailable, name that check as skipped and continue with source inspection.

Raw graph diffs can count line shifts as edge churn. Read line-insensitive counts as well as raw counts. Supported Brigade verification and run receipts may attach graph deltas. Missing engine support or an uncovered file is a skipped graph check, never proof of no impact. Follow the repository's verification policy for receipt and scoring limits.

## Brigade 0.31 engine compatibility

New indexes use `.brigade/code-graph/code-graph.db`. Existing legacy indexes
stay in place, and the new location wins when both exist. Check
`brigade code doctor . --json` before assuming an index is missing.

The canonical engine names are `brigade-code-graph` and `brigade-evidence`.
Prefer `BRIGADE_CODE_GRAPH_DB` for an explicit database path. Conflicting
old and new database variables are refused. Use `brigade receipts export
evidence` and `brigade work import context --from-evidence` for the evidence
loop. Older command spellings remain supported aliases.
