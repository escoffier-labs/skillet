# Worker control

Templates behind the rules in [fleet-conductor](../SKILL.md). Control-plane ideas adapted from pstack by Lauren Tan (MIT). Keep state in the campaign log and GitHub; do not add a second state store.

## Standing orders

Write them once, store them with the campaign record, and paste them verbatim at the top of every spawn and every resume. A worker that has seen them in a previous turn has not seen them in this one.

```text
STANDING ORDERS (verbatim, every spawn)
- Work only the named lane. Touch nothing outside write_set.
- Stop and report when the repository contradicts the ticket, the write set would grow, or two attempts fail.
- Do not spawn helpers. One flat pass.
- Do not change a gate: no raised budget, allowlist entry, skipped or disabled check.
- Return the REPORT format exactly. A report without its evidence counts as not done.
```

## Extra ticket fields

Added to the bounded lane record:

```text
TIMEBOX: <wall time or step budget; no new side effect inside it means stalled>
FORBIDDEN: <named actions, e.g. push to shared branches, open or ready a PR, comment on issues, merge, edit CI config>
REPORT: status word (DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT), actual diff, commands run with output, branch and PR URL, blockers
```

Name FORBIDDEN actions concretely. "Read-only" is interpreted loosely; "do not run `git push`, `gh pr create`, `gh pr ready`, `gh pr merge`, or `gh issue comment`" is not.

## Verdict ledger

One row per PR and head SHA. A new head voids the row.

```text
pr: <owner/repo>#<n>
head_sha:
verdict: confirmed | insufficient | inconclusive | changes-requested | approved
reviewer + model:
patch_id: <git patch-id --stable of the reviewed diff>
checked_at:
voided_by: <new head SHA, or empty>
```

After a rebase or a push to the PR:

```bash
git diff <base>...<old_head> | git patch-id --stable
git diff <base>...<new_head> | git patch-id --stable
```

Identical ids: the content did not change, so the old verdict may be marked carried-over with the new head SHA and the reason. Different ids, or an unresolved conflict that was touched during the rebase: re-review. When in doubt, re-review.

## Liveness by side effects

Never message a worker to ask if it is alive; a resume costs a turn, pollutes its context, and a hung worker will not answer. Read instead:

1. The branch: did it advance (`git ls-remote`, `gh api` for the ref)?
2. The PR: state, new commits, new comments, check runs.
3. The ledger and receipts the worker was told to write.

No new side effect inside TIMEBOX: mark the lane stalled, record the observation time and what was checked, and apply retry-by-failure-mode.

## Retry by failure mode

| Failure mode | Change before redispatch |
|---|---|
| Missing context | Add the file, spec line, or contract it lacked |
| Scope too big | Split the lane; each piece gets its own record |
| Wrong scope or collision | Fix the write set or serialize; record the collision |
| Flaky check | One fresh run; an identical second failure is real |
| Plan or ticket contradicts the repo | Back to the operator or ticket author; do not retry |
| Tool or environment error | Fix the environment, then redispatch once |

Two failures in the same mode: abandon the lane, record the evidence, move on. Consolidate scope into one fresh worker rather than chaining resumes.

## Gate loosening countersign

Record before allowing: who asked, which gate, what it was and what it becomes, why, the evidence, and the conductor's name. The countersign checks a worker is not lowering its own bar. It does not replace a required human approval, branch protection, or forge-enforced review, and it never counts as one.
