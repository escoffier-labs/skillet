# False-positive filtering

Run every candidate finding through this list before it reaches the report. A dropped candidate costs nothing. A noisy report costs the reader's trust.

## Drop when

- **Test fixtures and mocks.** Credentials, hashes, or vulnerable-looking strings in test directories that visibly use dummy values and are never loaded by production code. Confirm with a quick look at imports before dropping it.
- **Documented example values.** Placeholders in docs, READMEs, and sample config (`your-api-key-here`, `changeme`, the vendor's published example keys). A real-looking value that is not a published example is not a placeholder.
- **Input already validated upstream.** A framework schema, middleware, ORM parameter binding, or type-level constraint already constrains the value before the sink. Cite where.
- **Output already encoded.** The templating layer escapes by default and the diff does not opt out.
- **Constant input.** The "tainted" value comes from a constant, an enum, or server-side config an attacker does not control.
- **Unreachable code.** Dead branch, code behind a flag that is off and not settable by an attacker, or a path only reachable by an already-privileged operator.
- **Local-only tooling.** A dev script or build helper that runs only on the author's machine with the author's own input. Still check that CI does not run it.
- **Pre-existing and untouched.** The diff neither introduced nor newly exposed the issue. Move to Notes.
- **Generic best-practice nits.** Missing header on an internal-only service, theoretical timing differences with no secret comparison, and similar low-value items. Keep at most one low or info line if the reader would want it.
- **Scanner noise.** High-entropy strings that are hashes, UUIDs, build IDs, or lockfile integrity values. Rule hits inside vendored or generated files that the repo does not own.

## Keep when

- Validation exists but covers a different field, a different route, or a different code path than the changed one.
- The mitigation lives in config you cannot see. Keep it as `(unverified)`, one severity lower.
- A fixture or example value is real, reused elsewhere, or loaded by production code.
- The flagged file is a workflow, hook, or install script. Execution context outranks file location.

## Record the drops

Under "Not checked" or "Notes", one line per class of candidate you dropped and why, without repeating any secret value. The reader can then see the filter along with the result.
