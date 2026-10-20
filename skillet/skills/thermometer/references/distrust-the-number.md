# Distrust the number

A measurement is a claim until it survives these questions. Run them on any baseline or after number before it goes in a report. Adapted from pstack by Lauren Tan (MIT). "Inconclusive" is an allowed answer to any of them, and is better than a confident wrong number.

1. **What limits it, and why is it not double?** Name the limiter from the profile (CPU, lock, I/O wait, network, memory bandwidth, a single thread). If you cannot say why the number is not twice as good, you do not yet know what it measures.
2. **Is it tuned like production?** Build mode, flags, cache and pool sizes, data volume, concurrency, and hardware class match what users run. A tuned side against an untuned side is not a comparison.
3. **Physical limits.** Compare against the floor: disk or network bandwidth, memory speed, clock and core count, a no-op baseline of the same harness. A result near the floor has no headroom; a result beyond it is a bug in the measurement.
4. **Errors in the timed region.** Count them. A run that fails fast looks fast. Print the error count next to the timing, and expect zero.
5. **Reproduce with alternating runs.** Run before, after, before, after (not five of one then five of the other) so drift, thermal throttling, and noisy neighbors hit both sides equally. A difference that flips with order is noise.
6. **End-to-end relevance.** Is the thing you sped up a large enough share of the user-visible total to matter? A 50% win on 2% of the request is a 1% win.
7. **Work actually inside the timed region.** Check that the timer covers the work and only the work: no setup counted, no lazy work escaping the timer, no result discarded so the optimizer deleted the loop, no cached answer returned instead of computed. Print a work-done count (rows processed, bytes written) beside the time.

Keep the run count, spread, limiter, and work-done count with the number in the report.
