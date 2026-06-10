# Audit report format (the spine)

The canonical contract shared by `line-check`, `bug-hunt`, and `security-sweep`. Each skill inlines the short version of this contract so it works standalone; this document is the source of truth when they drift.

The point of the contract: findings from any of the three skills compose into one backlog. Run line-check today and security-sweep next week, and the results sort into a single prioritized list without translation.

## Severity scale

| Severity | Meaning | Examples |
|----------|---------|----------|
| critical | Active harm or imminent loss. Fix before anything else ships. | Leaked credential, data-destroying bug, exploitable injection |
| high | Will bite soon or blocks adoption. Fix this week. | Broken quickstart, missing license on a public repo, crash on common input |
| medium | Real cost, not urgent. Schedule it. | No CI, stale docs, untested critical path |
| low | Friction or polish. Batch with nearby work. | Inconsistent naming, minor dead code, missing badge |
| info | Worth knowing, no action required. | Observations, metrics, things done well |

## Finding schema

Every finding, regardless of which skill produced it:

```markdown
### [SEVERITY] Short imperative title
- **Station/Lens:** which audit dimension produced this
- **Where:** file:line, directory, or "repo-wide"
- **What:** one or two sentences, concrete, no hedging
- **Why it matters:** the consequence if ignored
- **Fix:** the specific action, with commands or a sketch when short
- **Effort:** S (under 30 min) / M (under half a day) / L (multi-day)
```

Rules:
- One finding per discrete problem. No "and also" findings.
- "Where" must be checkable. A reviewer should be able to jump there and see it.
- "Fix" is an action, never "consider improving X".
- Findings the skill could not verify get downgraded one severity and marked `(unverified)` in the title.

## Report layout

```markdown
# <skill-name> report: <repo> (<date>)

## Verdict
One paragraph: overall state, the single most important thing to do, and
whether the repo is healthy / needs work / on fire.

## Scorecard
| Station/Lens | Score (0-5) | Summary |
(one row per dimension the skill covers)

## Findings
(grouped by severity, descending; finding schema above)

## Backlog
Top findings re-sorted by leverage: impact relative to effort. Numbered,
each entry one line: `N. [SEVERITY/EFFORT] title (station)`.
Cheap high-impact items float to the top regardless of severity.

## Not checked
What the audit skipped and why (no silent gaps).
```

## Scorecard scoring

- 5: exemplary, steal patterns from this
- 4: solid, minor polish available
- 3: functional with real gaps
- 2: significant problems, schedule work
- 1: broken or absent
- 0: actively harmful as-is

## Composition

When multiple skill reports exist for the same repo, merge backlogs by
sorting on (impact/effort leverage, then severity). Findings with the same
"Where" and overlapping "What" are duplicates; keep the higher severity one
and note the other skill confirmed it.
