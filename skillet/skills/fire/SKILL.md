---
name: fire
version: 0.2.0
license: MIT
description: Use when a written implementation plan is ready to execute, when the user says "fire", "execute the plan", "build it", or hands over a plan file to implement. The step after recipe.
---

# fire

The expeditor calls "fire" and the line cooks the order: exactly as the ticket reads, station by station, nothing leaving the pass unchecked and nothing improvised on the line. This skill executes a written implementation plan task by task. The plan is the ticket; its checkboxes are the board.

## Preconditions

- A plan with discrete tasks exists ([recipe](../recipe/SKILL.md)'s output, or equivalent). No plan? Run recipe first; fire cooks what is written, it does not compose.
- Never on the default branch. Create a feature branch (`fire/<plan>-<date>`), or isolate in a worktree: prefer the harness's native worktree tool; fall back to `git worktree add` only without one, and verify the worktree directory is gitignored first.
- Green baseline. Run the suite before touching anything and read the output; on a failing baseline, stop and report, because you cannot tell new breakage from old.

## Read the ticket before firing

Read the entire plan critically against the actual code before executing anything. Stale line numbers, helpers the plan names that the code lacks, tasks that contradict each other: find them now, while the tree is clean, not mid-task with it half-changed. Surface concerns and get them resolved before task 1. A plan that references structure that does not exist is a planning gap that goes back to its author, not an invitation to improvise.

## Execution

Two modes, same discipline. Pick brigade mode when subagents are available and the plan has more than a couple of tasks; solo otherwise. A harness without subagent tools gets solo mode, and you say so once instead of inventing a dispatch call.

- **Brigade mode:** dispatch a fresh implementer subagent per task, one at a time, in plan order, under the [dispatch contract](../stations/references/dispatch-contract.md). Give it the full task text and the scene-setting context as files or prompt text; never make it read the plan file. Read its diff and test output between tasks before dispatching the next. Implementer-only is the default per task; reviewer passes per task are for high-risk work or when asked. The whole-branch review below is not optional.
- **Solo mode:** execute inline, treating each task boundary as a checkpoint: tests green, committed, boxes ticked, ledger line written, then the next.

Per task, either mode:

1. Follow the steps exactly, including the run-it-watch-it-fail steps. They are how you tell a broken step from a broken codebase.
2. Verify as the plan specifies and read the output. Evidence, not assertion.
3. Commit per task as the plan says.
4. Tick the task's checkboxes in the plan file. The plan is the live board; an executed plan with clean checkboxes is a board nobody can read.
5. Append the task's line to the [ledger](references/ledger.md).
6. Reality diverges from the plan? Classify it:
   - **Typo:** a moved line number or renamed local. Fix the plan's reference and continue.
   - **Ruling:** a non-destructive judgment call the plan does not settle (two reasonable names, an ambiguous edge case, which of two equivalent helpers). Decide, record a `Ruling:` line, and keep going. Rulings never cover a new dependency, a public name or interface, a schema or persisted format, a config key, spending, or any action that needs operator approval; those are structural or a stop.
   - **Structural:** a missing helper, absent module, or contradicted design. Stop the task, revert any partial change, and take it back to the plan's author. Never invent API surface the plan does not define.
   - **Pattern:** typos and rulings count too. The second deviation of the same shape (the same missing layer, the same wrong assumption about a data shape), however each was classified, means the plan is wrong, not unlucky. Stop and go back to the plan's author.
   - A blocked subagent gets something changed (more context, a smaller piece, a stronger model) before any redispatch. Never blind-retry.

## Rulings, not stalls

A question you can answer yourself is not a reason to stop. An unattended run that parks on "which name do you prefer?" costs hours and teaches nothing. Decide, write it down, and let the final review and the final message put it in front of the user.

A ruling carries the call, its basis, and the cost if wrong:

```text
Ruling: task 4 - kept the retry cap at 3 as in task 2 | basis: judgment (plan silent) | if wrong: one constant to change
```

Basis labels follow [pressure-test](../pressure-test/SKILL.md): `evidence` (inspected this session), `stated-constraint` (the plan's or user's own words), `judgment` (your best call, nothing verifiable behind it). Never let a judgment pass as evidence.

Stop and ask only for:

- an irreversible or destructive action (deleting data, dropping a table, rewriting shared history)
- a security-sensitive choice (auth, secrets, permissions, trust boundaries)
- a side effect outside the working tree (push, merge, publish, an external message)
- spending money or quota beyond what the plan states
- a plan so broken that every path is a guess

A ruling stays inside the plan: it never adds a dependency, a public name or interface, a schema or persisted format, a config key, or anything needing operator approval. Those go to the plan's author.

Also stop on a structural divergence or a pattern (above), a blocker you cannot resolve, or verification that fails twice on focused attempts. No "should I continue?" between tasks and no progress check-ins.

## Resume

After a compaction, crash, or fresh session, read the [ledger](references/ledger.md) first, then the plan's checkboxes, then `git log` since the branch point. The ledger says what finished and what was ruled; the commits confirm it. Continue at the first task with no ledger line. A ledger line without a matching commit is unfinished work: check the tree before trusting it.

## Final review

After the last task and before the finish, one whole-branch review catches what per-task checks cannot: drift between tasks, a ruling that aged badly, a hole in the seams.

1. Dispatch [review](../review/SKILL.md) once, fresh, on the strongest model available, against the merge-base diff (`git diff $(git merge-base <base> HEAD)..HEAD`). Attach the ledger's rulings and the plan's Review Focus section if it has one. Do not tell the reviewer what to ignore or how severe anything is.
2. Re-grade each finding by its effect on the user, not by the reviewer's label. Verify before acting.
3. Fix once: for each accepted finding, write a failing test first ([taste](../taste/SKILL.md)), then the fix, then the suite. One fix pass; what the pass cannot settle goes in the final message, not into a second review loop.
4. Record the review and its outcome in the ledger.

No subagent tools? Run the review checklist yourself from the merge-base diff and say the review was inline.

## The finish

After the final review:

1. Run the full suite one last time and read the output ([check](../check/SKILL.md)). Failing? Fix before offering anything.
2. Confirm the base branch: take the base recorded in the ledger header, check it against what the plan or user named, and verify it exists with `git rev-parse --verify <base>`. Never assume `main`, and never read the base from `git branch --show-current` (that is the feature branch).
3. Present exactly these options and wait:
   1. Merge back to the base branch locally (re-verify the suite on the merged result before calling it done)
   2. Push and open a pull request ([pass](../pass/SKILL.md) gates the filing)
   3. Keep the branch as-is

   On a detached HEAD, offer only two: push a new branch (and open a pull request through pass), or keep the work as-is with the commit hash named.
4. Discard is not on the menu. Offer it only when the user asks, and then show the branch, commits, and uncommitted files it deletes and require them to type `discard`.
5. Cleanup: remove a worktree only for option 1, only if fire created it, and only after stepping out of it. Options 2 and 3 keep the worktree alive for iteration. Never remove a workspace the harness manages. If `git worktree remove` refuses, never retry with `--force`: list the unsaved or untracked files it names and ask. Write the final message (below) before any cleanup: removing a worktree deletes its private git directory, and any ledger kept there.

## The final message

Lead with what shipped and the evidence. Then list, without trimming for length:

- **Rulings:** every `Ruling:` line from the ledger.
- **Deferred:** every minor finding or follow-up you chose not to fix, with why.
- **Review:** what the whole-branch review found and what was fixed.

## Rules

- The plan is the contract. Steps execute as written; disagreement with the plan is a conversation with its author, not a silent rewrite.
- Never skip a watch-it-fail step because the implementation "obviously" works, and never weaken a test to get to green.
- One implementer at a time. Tasks in one plan share state by design; parallel execution of independent work is [stations](../stations/SKILL.md)' job, not fire's.
- Checkbox state is part of the deliverable. Tick as you go, not in a batch at the end.
- Flagging a deviation in the final report is not the same as stopping at it. The author decides about structural changes before they are built, not after. A ruling is the opposite case: small, reversible, and listed, so deciding it yourself is the job.

## Common mistakes

- Executing on the default branch because the plan looked small.
- Skipping the critical read, then meeting the plan's stale assumptions mid-task with the tree half-changed.
- Silently inventing the helper the plan references but the code lacks, then calling it "honoring the plan's intent". That is design-by-improvisation; the plan author never saw the design.
- Leaving every checkbox unticked, so nobody, including the resumed session after a crash, can tell where execution stopped.
- Ending with "done" on the feature branch instead of the finish options.
- Parking an unattended run on a question you could have ruled on, or ruling on something destructive or external because stopping felt slow.
- Absorbing the second deviation of the same shape as "just a typo" or "just a ruling" instead of treating the plan as wrong.
- Using a ruling to add a dependency, rename a public interface, or change a persisted format, which only the plan's author may decide.
- Skipping the whole-branch review because every task passed its own checks.
- Retrying `git worktree remove --force` after a refusal, which deletes exactly the files the refusal protected.
- Pausing between tasks to ask whether to continue, when the instruction was to execute the plan.
