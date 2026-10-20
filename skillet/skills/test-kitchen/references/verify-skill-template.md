# Verify skill template

Fill every section from what the interview found. No placeholders survive into the written skill.

## Layout

```text
<skills-dir>/verify-<app>/
  SKILL.md
  features/
    README.md        index: one line per feature file
    <feature>.md     one per user-facing feature
  scripts/           optional, executable, invoked in the SKILL.md body
```

## SKILL.md skeleton

```markdown
---
name: verify-<app>
description: Use when you must prove a change works in the running <app> (<surface>) - launching it, driving <feature areas>, and capturing evidence.
---

# verify-<app>

## Launch
Command: `<exact command>`   Ready when: `<log line or prompt that means usable>`
Creates a fresh scratch data dir for this run (never wipe or reuse an existing one), runs migrations and seed data against it, uses local or sandbox backends only, and records the process ids it starts in `<scratch path>`.

## Doctor
`<one read-only command>` - prints process up, expected version or build, port owned by this run, auth valid. Run first and after any surprising result.

## Drive
<Recipes using this repo's real handles. One short recipe per common action.>

## Evidence
Save to `<path>`. Capture the action and the resulting state, not only the final screen. Verify side effects (files written, rows inserted, messages sent) alongside what is visible. Drive the real user path, not internal setters or test-only endpoints. Mocks only where a production boundary already isolates the external system. Verify what a dry-run mode skips by observing files, network, and git refs.

## Cleanup
Stop only the ids recorded at launch. Remove scratch state. Keep the evidence directory.

## Features
See `features/README.md`.
```

## Feature file shape

```markdown
# <Feature>

## Sub-features
- <short list>

## How to get to it (user point of view)
<Steps a user takes, with the visible labels.>

## Driving it
<Harness recipe with real selectors, commands, or prompts.>
End state that proves it works: <observable result>.

## Gotchas
- <Precondition the seed data lacks, timing, auth, or flaky edge. A journey that fails for a missing precondition reports failure and the reason lands here.>
```

## Rules for what you write

- Prefer stable handles over coordinates and tab order.
- Short-lived CLIs have no server to keep alive: launch means build or install once, then start each drive in its own isolated PTY or tmux session.
- A journey with external effects (sends a message or email, takes a payment, publishes, calls a production service) needs the operator's approval before the recipe runs, and runs against a sandbox where one exists.
- Two instances cannot share a data dir or port: say so, and refuse to drive an instance the run did not start.
- Any helper script is executable and its exact invocation is shown in the body. A helper the reader must reverse-engineer is not a helper.
