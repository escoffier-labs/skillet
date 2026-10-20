# Condition-based waiting

Use when a test or script is flaky because it sleeps for a guessed duration, or when it times out only under load or in parallel.

**Principle:** wait for the thing you need to be true, not for a number of milliseconds you hope is enough. A fixed sleep passes on a fast machine and fails on a loaded one, and when it is too long it quietly slows every run.

## Convert a sleep

```
# before: guess
sleep 0.5
check_result

# after: poll the condition, with a deadline
wait_until 'result_ready' 5
check_result
```

A usable `wait_until` in any language has four parts:

1. A predicate that returns true when the needed state exists (event arrived, file written, count reached, status is ready).
2. A short poll interval (10 to 50 ms for in-process state, longer for remote calls).
3. A deadline that fails with a message naming what was awaited and its last observed value, not a bare "timed out".
4. A fresh read of the state on each poll. Caching the value before the loop makes the loop spin on stale data.

## Choosing the condition

| You are waiting for | Poll |
|---|---|
| An event or message | The event list for that type |
| A state transition | The state value, for the target state |
| A count | The length, for `>=` the number you need |
| A file or socket | Its existence or readiness |
| Several things | One predicate that combines them |

## When a fixed delay is correct

Only when the delay itself is the behavior under test (debounce, throttle, rate limit, expiry). Then:

- Derive the delay from the documented interval, not a guess, and wait for the condition first, then add the known interval.
- Comment why a fixed delay is right here.

## Common mistakes

- Polling with no deadline, so a real failure hangs the run.
- A tight loop with no pause, burning CPU and starving the thing being awaited.
- Reading state once before the loop.
- Raising the sleep when the test flakes. That is the same bug, longer.
