# The fire ledger

One file per plan. It is the resume point after a compaction, a crash, or a hand-off to a fresh session. The plan's checkboxes stay the live board; the ledger adds the proof and the rulings the checkboxes cannot hold.

## Where it lives

Somewhere git ignores and a branch switch will not touch. Default: `$(git rev-parse --git-common-dir)/fire/<branch>/<plan-slug>.md` (create the directories first). The common git directory is shared by every worktree of the repository and is never part of a worktree's tree, so the file never shows in `git status`, is never committed, and survives `git worktree remove`.

`git check-ignore` applies only to a custom in-tree path. If you must keep the ledger in the tree, use a path that check-ignore confirms is ignored, such as a scratch directory already listed in `.gitignore` or `.git/info/exclude` (add the entry there, not to the tracked `.gitignore`).

Never put it in the plan file, a tracked file, or a memory-handoff inbox.

## Format

The first line names the plan, so a stale file from another plan is obvious:

```text
Plan: docs/plans/2026-10-20-export-csv.md (branch fire/export-csv-2026-10-20, base main)
Task 1 | a1b2c3d | npm test -- export | 14 passed
Task 2 | b2c3d4e^..c3d4e5f | npm test -- export | 19 passed
Ruling: task 3 - quoted all fields, not only those with commas | basis: judgment (plan silent) | if wrong: one flag in the writer
Task 3 | d4e5f6a | npm test | 212 passed
Review | <merge-base>..HEAD | 2 findings accepted, 1 declined | fixed in e5f6a7b
```

- **Header:** the plan, the branch, and the base branch, written at the start. The finish reads the base from here.
- **Task line:** task number, the commits (a single SHA, a list, or `<first>^..<last>`; never `X..X`, which is empty), the proving command, its result. One line, written when the task's checkboxes are ticked.
- **Ruling line:** the call, the basis label (`evidence`, `stated-constraint`, or `judgment`), and the cost if wrong. Written the moment the call is made, before the task line it belongs to.
- **Review line:** written after the final review with the outcome and the fix commit.

Append only. Never rewrite an earlier line; correct it with a new line that says what changed.

## Using it

- Write the file before task 1 (header line only, including the base branch).
- On resume, read it before touching anything. The first task with no line is next. A line with no matching commit means the work did not land; check the tree.
- At the end, copy every `Ruling:` line into the final message verbatim.
