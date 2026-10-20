# Starting dimensions

Each finding: what happened, `path:line` citations (first and last when it spans lines), and the number with its source. Report only what the transcript shows.

## Plan adherence

Recover the plan the session agreed to: a design agreed in chat (assistant text before a human "yes" or "go ahead"), a spec or plan file written during the session, a todo list, or a numbered checklist in assistant text. Quote each step with its line.

Mark structural events between plan and execution: compactions, resumes, aborted turns, associated-session dispatches. Then for each step find the work that executed it, and report steps skipped, executed out of order, silently changed (quote both versions), invented (work no step covers), and drift right after a structural event (cite the event and the first divergent action). If no plan is recoverable, say so as the only finding and list the lines you checked.

## Repeated work

Extract each tool call as (line, turn, tool, key) where the key is the file path for reads and edits, the command text for shell calls, the description plus the first 80 characters of the prompt for dispatches, and the query for searches. Group by tool and key and report groups at or over these thresholds:

| Category | Threshold | Exempt |
|---|---|---|
| reads, searches | 3 | |
| edits | 2 | |
| shell commands | 2 | status checks and test runs |
| subagent dispatches | 2 with the same description | |

For each group, check what changed between repetitions (an edit, a compaction, a human correction). A re-read after an edit is not a finding; a re-read after a compaction is a finding attributed to the compaction; a re-read with nothing between is a finding on its own. Also look for re-derived decisions: a conclusion stated earlier, reached again. Quote both places.

## Cost and time

- **Tokens.** Use only the usage records and counter meanings established at discovery. Say whether each counter is incremental or cumulative before totalling, dedupe records that repeat per content block, and never turn a missing observation into zero. Report the five turns with the largest supported totals and the totals per associated session.
- **Wall-clock.** Use the evidenced timestamps. Report the five longest turns and any gap over ten minutes between consecutive events; say idle, waiting on a helper, or waiting on the user only when the records show it.
- **Largest tool results.** The ten largest, with tool and turn. Measure before extracting bounded content.
- **Compactions.** Count and locate them, with before/after counters if present and what the session was doing.
- **Associated sessions.** Count, usage, duration, and dispatching turn for each.
- Name the turns, helpers, tools, or repeats that dominate the totals, with numbers. Do not speculate about why a turn was expensive beyond what the transcript shows.

## Later dimensions, on demand

Stumbles (errors, retries, dead ends), skill timeline (which skills fired, when, and whether the body was followed), request conflicts (instructions that contradict each other), and output quality evidence.
