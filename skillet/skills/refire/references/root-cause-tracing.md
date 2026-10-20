# Root-cause tracing

Use when the error shows up deep in a call stack and the crash site is clearly not where the bad thing began. The fix belongs at the origin, not where it surfaced.

## The method

1. **Write down the symptom at the crash site.** The exact value or state that is wrong there ("`cwd` is the empty string", "the record has no owner").
2. **Ask what produced that value.** Name the immediate caller and the argument it passed.
3. **Repeat one frame up.** At each frame ask: did this layer create the bad value, or receive it? Stop only when you reach a layer that invented it.
4. **Confirm with the artifact, not the theory.** At the suspected origin, log or assert the value and rerun. If it is already bad there, keep climbing. If it is fine there, the corruption happened between the two frames you just checked.
5. **Fix at the origin.** Then add checks at the layers in between if the value could have entered another way (see [defense-in-depth.md](defense-in-depth.md)).

## When the stack is not enough

If the trace does not show who called, or the failure happens in a callee you do not control, record the stack at the point of use and run once:

- Log the value, the working directory, the environment variables that matter, and a captured stack, just before the dangerous operation.
- Log before the operation, not after it fails; the failing call may never return.
- In test runs, write to stderr or a file. Loggers are often silenced under a test harness.
- Never log secrets. Log whether a variable is set and its length, not its value.

## Many tests, one polluter

When a test passes alone and fails in the suite, something earlier left state behind. Bisect by file: `bash scripts/find-polluter.sh '<test command using "$1">' '<check command that succeeds when the state is dirty>' <test files...>` runs each file alone and names the first one that dirties the state.

## Stop signs

- You are fixing the line that threw. Ask why the input was allowed to get there.
- The origin is a default value (`""`, `0`, `null`) that was meant to be replaced before use. A default that can reach production use is the bug.
- Two frames each blame the other. Compare what each layer promises in its docs; one of them is breaking its contract.
