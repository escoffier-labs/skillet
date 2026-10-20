# Analysis dimensions

Every finding needs a `path:line` citation (first and last line when it spans several), plus the figure and where it came from. Report what the transcript shows and stop there.

## 1. Did the work follow the plan?

Find the plan that was agreed. Candidates are an outline accepted in chat (assistant text just before the user agreed), a spec or plan file written during the run, a todo list, or a numbered list in assistant text. Quote every step with its line.

Note the moments that can break continuity: compactions, resumes, aborted turns, and dispatches to other sessions. Then walk the steps and sort the outcome into skipped, reordered, changed without announcement (quote the plan and the action side by side), invented (work that no step covers), and drift that begins right after a continuity break. With no recoverable plan, report that single fact and the places you looked.

## 2. Was anything done twice?

Build a list of tool calls: line, turn, tool, and a key (file path for reads and edits; full command for shell calls; description plus the first 80 characters of the prompt for dispatches; query text for searches). Group on tool plus key.

| Kind | Report at | Ignore |
|---|---|---|
| reads and searches | 3 or more | |
| edits | 2 or more | |
| shell commands | 2 or more | status checks and test runs |
| subagent dispatches | 2 or more with the same description | |

For each group ask what happened in between. A read after your own edit is expected. A read after a compaction belongs to the compaction. A read with no event in between is a finding by itself. Also quote cases where a conclusion reached earlier is derived again later.

## 3. Where did the tokens and time go?

- **Tokens.** Use the usage fields and counter semantics you established during discovery. State whether each counter is per message or running, remove duplicates where one message is split across several records, and never read a missing value as zero. Give the five largest supported turns and the per-session totals.
- **Time.** Use the recorded timestamps. Give the five longest turns and every gap over ten minutes; call a gap idle, waiting on a helper, or waiting on the user only when records say so.
- **Largest tool outputs.** List the ten biggest with tool and turn, measuring before extracting any text.
- **Compactions.** Count and locate them, give before and after figures where recorded, and say what the session was doing.
- **Helper sessions.** For each, usage, duration, and the turn that launched it.
- Name what dominates the totals with figures. Do not explain why a turn was costly beyond what the records show.

## Add on demand

Stumbles (errors, retries, dead ends), skill timeline (which skills loaded, when, and whether their body was followed), conflicting instructions, and output quality evidence.
