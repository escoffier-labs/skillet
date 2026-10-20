# Diagnose-only mode

For "why was this slow", "what is eating memory in this process", "what happened during that stall", where the output is a cause and not a patch. Adapted from pstack by Lauren Tan (MIT).

1. **Get the real artifact.** A trace, profile, heap snapshot, flame graph, query log, or live signal captured from the actual run. Not a reconstruction, not a guess from the code. If none exists and the symptom is reproducible, capture one; if it is not reproducible, say what to capture next time and stop.
2. **Put it in a queryable form.** Load it into something you can ask questions of: a SQLite table with a row per sample, frame, or node; `jq` over JSON; the profiler's own query tool. Raw dumps are for tools, not eyes.
3. **Walk the hot path.** Largest self time, then largest inclusive time, then who calls it. Reduce to the one or two entries that explain most of the total, with their share.
4. **Attribute to source.** Map each hot entry to a file and function. A frame with no source mapping is not yet a diagnosis: resolve symbols (debug info, source maps, symbol server) or state plainly that symbols are missing and what is needed to get them.
5. **Prove the mechanism if cheap.** Add temporary, uncommitted instrumentation (a counter, a timer, or a log at the suspected line) and show it fires as often or as long as the profile claims. Remove it before the report, and confirm with `git status` that the tree is clean. A mechanism you inferred from names is a hypothesis.
6. **Report** the cause with its share of the total, the source location, the evidence (artifact, query, instrumentation output), and what remains unexplained. The only code change in this mode is that temporary instrumentation; hand the cause to the measure-and-fix procedure.
