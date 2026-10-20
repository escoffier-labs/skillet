# Testing a skill

Writing a skill is test-driven development applied to instructions: watch it fail, write the minimum, watch it pass, close loopholes. Method adapted from obra/superpowers (MIT), rewritten for skillet.

## 1. Baseline (RED)

Run a realistic task on a fresh agent with no skill present. Record:

- the choices it made
- every excuse, verbatim
- which pressure triggered each violation

If the control shows no failure, stop. There is nothing to fix and guidance only adds tokens.

## 2. Pressure scenarios

For a discipline skill (a rule agents skip when it costs them), a plain question proves nothing. Stack three or more pressures in one scenario so the rule has to compete:

| Pressure | Example |
|---|---|
| Time | "CI is blocking everyone, ship in ten minutes" |
| Sunk cost | "You already wrote 200 lines; deleting them is wasteful" |
| Authority | "The lead said skip the check this once" |
| Exhaustion | The task is the fifth in a long session |
| Plausible shortcut | A fix that looks done and is cheap to claim |

Force a concrete choice ("which do you do, A or B?") so the agent acts instead of describing what it would do.

## 3. Write the minimum (GREEN)

Address the recorded excuses and nothing else. Re-run the same scenarios with the skill. The agent should comply. Match the form to the failure (see the table in SKILL.md).

## 4. Close loopholes (REFACTOR)

A new excuse appears: add its counter to the rationalization table and the red-flag list, then re-run. Typical loopholes to close explicitly:

- "I'm following the spirit, not the letter." State that the letter is the spirit.
- "This case is different because..." Add the case to the table with its reality.
- Reordering steps so the check happens later. Say the order matters and why.

## 5. Micro-test the wording

Full scenarios are slow. Check the wording first:

1. **One fresh sample per call.** A single-shot subagent or a raw model call, with a clean context. The system or opening context is the realistic surface the guidance lives in (the whole skill or prompt template, not the guidance in isolation). The user message is a task that tempts the failure.
2. **Always run a no-guidance control.** No failure in the control means nothing to fix.
3. **Five or more reps per variant.** One sample is an anecdote.
4. **Read every flagged match.** Score with a script if you like, but quoted counter-examples and template echoes count as hits and inflate both the failure and the success rate.
5. **Treat variance as a result.** When wording binds, reps converge on one shape. Five different readings across five reps means the form is loose; tighten it before adding words.

Micro-tests check wording. They do not replace pressure scenarios for a discipline skill.

## 6. Test by skill type

| Type | Test with |
|---|---|
| Discipline (rules) | Pressure scenarios, then loophole closing |
| Technique (how-to) | A new case the skill did not use as an example; can the agent apply it? Also a case with a missing input |
| Pattern (mental model) | Cases where it applies and cases that look similar but should not trigger it |
| Reference (docs, APIs) | Retrieval: can the agent find and correctly use the thing, including an item that is not in the skill? |

## 7. Trigger test

The description decides whether the skill loads. With the skill installed, give a fresh agent the natural phrasing a user would use, without naming the skill. Confirm the skill loads before the first edit or action. Run it for a case that should not trigger as well. A miss is a description bug: add the user's words and the situation's symptoms, not process detail.

## 8. Before shipping

- Links resolve and referenced files exist.
- The repo lint passes.
- The changelog entry says what baseline you tested against.
