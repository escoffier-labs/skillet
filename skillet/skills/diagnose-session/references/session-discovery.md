# Discovering session history

Resolve the session the user named using what this environment exposes, then verify. Your memory of storage layouts can suggest where to look; the files in front of you decide.

## Where to look, in order

1. **Brigade.** `brigade evidence search "<query>"` and any run receipts for the work. A hit can answer the question without opening a transcript. Cite ids.
2. **The harness's own session tools or `--help`,** if it exposes list, show, or export commands.
3. **Transcript files on disk.** Common homes are per-harness directories under the user's home (for example a `projects/<project-slug>/` tree of `.jsonl` files for Claude Code, or a dated `sessions/` tree for Codex). The slug is usually the project path with separators replaced. Confirm by listing the directory; do not trust the pattern blindly. Search **only the current project's** directory. If the store mixes projects (a dated tree, say), read each candidate's recorded working directory with a bounded field extraction and keep only files for this project before reading any content.
4. **Archives, indexes, or exports** the environment points at.

A path the user supplied and that opens needs no further search.

## Confirm identity

Recency alone is not confirmation. Match on the session id, working directory, timestamps, and conversation content: quote the first human prompt and its timestamp. Distinguish the requested session from its children (subagent transcripts, forked or resumed sessions) and from unrelated candidates, and list every candidate you rejected with the reason. If evidence cannot tell two apart, ask for one identifying fact.

## Establish record meanings before using them

From observed records or documentation, not from another harness's format:

- Which records are human messages versus injected text, system reminders, tool results, and a parent agent's dispatch. Match each tool call to its result.
- What the usage counters mean (incremental per message or cumulative), and whether one logical message is split across several records that repeat the same usage.
- Which records mark compactions, resumes, and aborted turns.
- The timestamp field and its unit.

Do not turn a missing field into zero. Record the sources, field meanings, supporting line numbers, associated sessions, rejected candidates, and open questions in the report so later readers do not repeat discovery.

If history is missing, inaccessible, or ambiguous, state the specific limitation and ask for the missing path, export, or identifying detail.
