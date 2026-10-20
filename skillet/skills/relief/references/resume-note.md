# Resume note template

Write for an agent that has never seen this session. Keep it under a page. Point at paths and commits; do not paste diffs.

```markdown
# Resume: <slug>

Written: <date, time> by <agent or session label>
Branch: <local branch>   Base: <base branch and SHA>   Checkpoint: <wip commit SHA or "none">
PR: <url or "none">

## Intent
<What the user asked for, in their words where possible, and the outcome that ends the task.>

## Progress
- Done and verified: <item> (proof: <command or artifact>)
- Done, not verified: <item>
- In progress when stopped: <item>

## State
<Tree clean or dirty, what is staged, running processes or workers you started and whether they are cancelled, branch relation to base, test status as last run.>

## Next step
<The single first action on resume, concrete enough to run.>

## Key files
- <path> - <why it matters>

## Gotchas
- <Thing that will cost the next worker time: a flaky test, an ordering trap, a decision already made and why.>

## Not mine to decide
- <Open question that belongs to the user.>
```

Rules: no secrets, tokens, or private hostnames in the note. Mark anything you did not verify as unverified. A claim without proof belongs under "Done, not verified".

If the session also produced durable knowledge (an architecture decision, a root cause, a setup gotcha), write that as a real memory handoff separately.
