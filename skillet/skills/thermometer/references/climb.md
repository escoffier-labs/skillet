# Climb mode

For a target that takes many iterations, such as "get this under 200 ms" or "halve the memory". Climb is the measure-and-fix loop run repeatedly, with a harness that is proven first and then frozen so iterations stay comparable. Adapted from pstack by Lauren Tan (MIT).

## Before the first iteration

1. **Pin the workload dimensions.** Input size, shape, concurrency, cache state, build mode, hardware. Write them down. Changing one mid-climb invalidates every earlier row.
2. **Prove the harness separates easy from target cases.** Run it on a trivial input and on the target input. If the two numbers do not differ the way the workload says they should, the harness cannot see the problem; fix the harness, not the code.
3. **Freeze it.** Commit or save the harness and its arguments. From now on only the code under test changes.
4. **Make it print error and work-done counts** next to the timing, and get the regression gate (tests plus any correctness checker) green on the baseline. See [distrust the number](distrust-the-number.md).
5. **Set the stop predicate:** the target met, or a stated number of iterations or time spent without a keep. Not "until it feels fast".

## Each iteration

1. One hypothesis, stated with its mechanism and expected effect (section 5 of the main procedure). Cheapest lever first.
2. One change.
3. Run the frozen harness with the standard sample count, and the regression gate.
4. **Keep** only if the gain exceeds run-to-run noise and the regression gate is green. Otherwise **revert in full** with `git restore -- <files this iteration touched>` (never `git reset --hard` or `git checkout .`, which also discard unrelated work), with no partial keeps and no "it might help later".
5. Stage named files only (`git add <path>`, never `git add -A`) and commit a kept change on its own.
6. Add a row to the decision log: iteration, hypothesis, median before and after, error and work-done counts, kept or reverted.

Correctness and simplicity outrank the number. A win that needs a fragile trick or a contract change goes back to the user instead of into the branch.

## Decision log row

```text
iter 4 | hypothesis: parse is 38% of time because it re-reads the schema per row | change: hoist schema load | before 412 ms (410-418) | after 301 ms (298-307) | errors 0 | rows 100000 | gate green | KEEP
```

## Stopping

Stop at the target, at the stop predicate, or when two consecutive hypotheses fail for the same reason (the profile has moved or the model of the system is wrong; profile again before the next iteration). Report the log, the kept changes, and the remaining headroom with its limiter.
