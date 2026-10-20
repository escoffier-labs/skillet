---
name: refire
version: 0.2.0
license: MIT
description: Use when anything misbehaves - a failing test, a production bug, a build break, flaky or unexpected behavior - before proposing or attempting any fix. Especially under pressure ("CI is blocking everyone", "just get it green") and after a previous fix didn't hold.
---

# refire

A plate comes back to the kitchen. The line's instinct is to fire the same dish again, faster; the chef's job is to find out why it came back first, because a refire of the same mistake comes back twice and now the diner is angrier. This skill is the chef's version of debugging: no fix until the cause of the sendback is known.

**Core principle:** no fixes without root cause first. A fix that makes the symptom disappear without explaining it is not a fix, it is a scheduled second incident. **Violating the letter of this process is violating its spirit.**

## Find out why it came back

Before any fix, in order:

1. **Read the error, all of it.** The full traceback, the line numbers, the actual message. It frequently names the cause outright.
2. **Reproduce it, on the surface the user hit.** Trigger it reliably with the smallest input you can, through the real entry point (their CLI, their browser, their config), not a stand-in that merely resembles it. A repro on a different surface proves a different bug. Ask the human only with a stated reason ("I need the config from the failing machine because X"). Cannot reproduce? Gather more evidence; do not guess.
3. **Check what changed.** `git log` and `git diff` around when it broke: recent commits, new dependencies, config or environment drift. Most bugs are young.
4. **Check the documented contract.** Schema docs, interface comments, the spec. The difference between the documented behavior and the actual behavior usually points straight at the cause, and the fix must satisfy the contract, not just the failing test.
5. **Trace to the source.** Where does the bad value originate? Who called this with it? Walk up the stack until the origin; the fix lands there, not at the crash site. In a multi-component system, instrument each boundary (what enters, what exits) and run once to see which layer breaks, rather than theorizing across all of them.
6. **Compare against what works.** Find the nearest working sibling (same pattern, same codebase) and list every difference, including the ones that "can't matter".
7. **Ask whether the triggering state is legitimate.** If the system can reach that state through normal use, the code that broke on it is the fault. If the state should never exist, a guard only hides the bug; the producer of the state is the target. Fails only after a restart, or on one machine? Suspect persisted state first: config, cache, lockfile, serialized data, leftover files.
8. **Say what you do not understand.** Write it plainly: "I do not understand why X happens when Y." An honest gap sends you back to step 5; a fluent explanation over a gap becomes the hypothesis you then "confirm".

Traced-origin techniques live in [references/root-cause-tracing.md](references/root-cause-tracing.md). Flaky timing: [references/condition-based-waiting.md](references/condition-based-waiting.md). A test that passes alone and fails in the suite: this skill's find-polluter script (run it by its path from the project root, `bash <path-to-skill>/scripts/find-polluter.sh`; its header has the usage). It runs each file in a fresh process, so it only sees state that outlives the process (files, database rows, sockets). Before trusting it, create the dirty state by hand once and confirm your check command reports it (exit 0) and reports clean when it is gone (exit 1). In-process leaks (globals, unrestored mocks) need the in-process suite bisected by halving the file list instead.

## Then fix it, once

1. **State the hypothesis.** "X is the root cause because Y", written, specific. If you cannot finish that sentence, return to investigation; do not pretend.
2. **Pin it with a failing test first.** The test reproduces the bug and asserts the violated contract, not just the absence of the crash. This is [taste](../taste/SKILL.md)'s loop applied to a bug; a fix without a test that failed is a fix that cannot prove itself and a regression nobody will catch.
3. **One minimal change.** Test the hypothesis with the smallest change that fixes the cause. One variable. No bundled cleanups, no "while I'm here".
4. **Verify and read the output.** The pinned test passes, the whole suite stays green, the original symptom is actually gone, re-triggered on the surface from step 2.
5. **Sweep for siblings.** Search for the same fault pattern elsewhere (same call, same assumption, same missing check) and fix or list each hit. Where the bad value could enter by other paths, see [references/defense-in-depth.md](references/defense-in-depth.md).
6. **Leave a cheap always-on signal** if the deciding fact took a deep dig: a log line, a metric, an assertion, a clearer error. The next occurrence should announce its cause.

If the fix did not work: stop, do not stack a second fix on top. **Revert it, and anything else the refuted hypothesis motivated** (extra guards, config tweaks, logging you added to chase it); keeping them hides what the real fix does. New evidence, new hypothesis, back to investigation.

**At two failed fixes, run the premise check.** Write the single premise both fixes assumed ("the cache is the only writer", "this runs after init"), and an observation that would look different if that premise were false. Test it directly before attempting fix three. Two misses that share a premise are one miss repeated.

**After three failed fixes, stop fixing entirely**: three misses on one bug means the architecture or the pattern is wrong, and that conversation happens with the user before attempt four.

## When no root cause turns up

Sometimes the investigation ends without a cause. Say so: "no root cause found", then list what was ruled out and what could not be observed. Containment is allowed only labeled as containment, never as the fix: a bounded retry, a timeout, a clearer error message, monitoring. Add the always-on signal from step 6 so the next occurrence carries evidence, and hand the open question to the user. A named unknown is a finding; a guessed cause is a defect.

## Rationalizations, all of them wrong

| Excuse | Reality |
|--------|---------|
| "Quick fix now, investigate later" | Later never comes; the mask becomes load-bearing. |
| "CI is blocking everyone, no time for process" | Investigation on a reproduced bug takes minutes. Thrashing takes hours and ships masks. |
| "Just try X and see" | Guess-and-check is how one bug becomes three. |
| "It's probably X" | Probably is not a hypothesis with a because. |
| "The test passes now, ship it" | Green that you cannot explain is the most dangerous color. |
| "Several candidate fixes at once, to be safe" | Now you cannot tell which one worked or what the others broke. |
| "Too simple to need the process" | Simple bugs have causes too, and the process is fast on them. |
| "One more attempt" (after two failures) | Third miss means the question is wrong, not the answer. |

## Red flags - stop and return to investigation

Proposing fixes before reproducing. A fix at the crash site when the bad value came from upstream. Catching-and-ignoring, widening a timeout, or `default=`-ing an error away to get green. A fix with no new failing test attached. Explaining the fix without being able to explain the bug. Any sentence starting "I don't fully understand it, but this works". A repro on a different surface than the one the user hit. A hypothesis that was refuted but whose side changes are still in the tree.

## Common mistakes

- Silencing the symptom (swallow the exception, loosen the assertion, skip the test) and calling CI green a fix.
- Fixing the right cause but skipping the pinning test, so the contract that broke still has no guard and the next regression sails through.
- Never opening the docs or schema, so the "fix" satisfies the failing test while quietly violating the documented contract.
- Stacking fix on fix without reverting the misses, then being unable to say which change did what.
- Treating a correct guess as a validated hypothesis. Luck is not process; it just hasn't cost you yet.
- Debugging a stand-in (a unit test, a different OS or config) and reporting the user's failure fixed.
- Skipping the "what changed recently" check and reverse-engineering from first principles what `git log` would have said in ten seconds.
