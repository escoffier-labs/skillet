# Defense in depth

Use after the root cause is fixed, when the bad value could have reached the failing code by more than one path.

A single check at one layer fixes the bug you saw. A later refactor, a different caller, or a test double can route around it. The goal is to make the whole class of bug hard to recreate, not only the instance.

## Four layers to consider

| Layer | Question | Example |
|---|---|---|
| Entry point | Can the public boundary reject this outright? | Reject an empty or nonexistent path when the object is created |
| Business logic | Does this operation make sense with this data? | Refuse to initialize a workspace without an owner |
| Environment guard | Is this dangerous in this context? | Refuse destructive file operations outside a temp directory while tests run |
| Diagnostics | If the other layers miss it, will the next failure explain itself? | Log the value, caller, and stack just before the risky call |

You rarely need all four. Pick the layers where a different code path could carry the same bad input, and skip the rest. A check that no path can reach is noise.

## Procedure

1. List every route the bad value could take to the failing line, from the trace.
2. For each route, ask which layer is the cheapest honest place to refuse it.
3. Add the check, with an error message that names the value and the rule.
4. Prove each check bites: write a test that bypasses the earlier layers and confirms the later one still fails loudly. A guard you have never seen fire is a guess.

## Cautions

- Validation is not a substitute for the origin fix. If you only add guards, you have hidden the producer of the bad state.
- Do not catch and ignore. A guard raises or returns an error the caller must handle.
- Keep messages free of secrets; name the field, not its value, when the field may hold a credential.
