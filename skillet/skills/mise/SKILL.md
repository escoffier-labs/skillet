---
name: mise
version: 0.2.0
license: MIT
description: Use before any creative or build work - a new feature, component, behavior change, or "let's build X" - when something non-trivial about what the user wants or why is still unsaid. Also use when the user says "let's design this", "brainstorm", or "spec this out", or the request describes a project rather than a one-line change.
---

# mise

Mise en place for building: everything designed and in its place before you cook. It turns an idea into a design someone approved, not the first plan that sounded right in the moment. For a project the deliverable is a written spec a separate session could implement without re-deciding anything important.

Your belief about what the user wants is usually thinner than it feels. People often have not finished working out what they want, and good questions help them think. When you understand the why, you make the hundred decisions they never mention the way they would have made them.

## What this owns, what it borrows

This skill owns the parts that turn an understood problem into a buildable design: generating real alternatives, recommending one, and shaping the choice into a spec. It does not re-invent interrogation. Pinning each decision that matters to an honest basis is [pressure-test](../pressure-test/SKILL.md)'s job. Pull pressure-test in when the decisions are genuinely contested, when the problem is fuzzy, or when the user hands off and goes AFK. Once a decision is pinned there, take it as settled here, do not relitigate it.

The split in one line: pressure-test closes the decisions, mise shapes them into a design and a spec.

## Size the work first

Before the full flow, decide how big this is, state the size in plain words, and let the user override.

| Size | What it looks like | What you do |
|---|---|---|
| Clear small change | Everything that matters is in the request ("rename this flag", "make the icon blue") | Do it now. No spec. Say what you did and any default you picked. |
| Medium change | A few decisions, one area of the code, one session | Agree the approach in chat: what you will build, what you will leave alone, the one or two calls that could go either way. Build after a yes. |
| Project | Several parts, new surface area, or work someone else will execute | The full flow below, ending in a written spec. |

When unsure between two sizes, take the larger. Anything touching a public interface, stored data, security, or an irreversible operation is at least medium. "Too simple to design" is where unexamined assumptions cost the most.

If a change grows mid-task, stop, say so, and step up a size. If a project is really several independent subsystems, say so, agree an order, and run the first piece through the full flow; each piece earns its own spec.

## Steps (project size)

1. **Read the context first.** Files, docs, recent commits, the surrounding code. Never spend a question on something the repo already answers.
2. **Open with intent.** Your first message does two things: one line saying that if they would rather skip the questions and have you start, they can say so (skipping the questions skips the interview, not the approval: state any significant how-it-gets-made choice in one plain line, draft from your marked guesses or run pressure-test in sous mode, and still get a yes before building at medium or project size), then one open question about their real situation. Ask about a moment or a concrete picture: "What's the moment you find yourself wishing this existed?" Open questions first, because their own words carry intent your options cannot. Offer a short menu only when they are stuck, and when they say "just guess", propose something concrete.
3. **Cover the ground.** Territory, not a script, and never read it out as questions: why now and what success looks like, goals and non-goals, prior art they loved or hated, the current state and what they have tried, the details they care about. One question per message, in plain language, anchored in specifics ("Walk me through the last time this bit you"). A guess they can correct often beats a question.
4. **Probe how it gets made.** Every project rests on choices of platform, language, libraries, or medium. Find out early which the user wants to own, which they hand to you, and what they already have. Where an existing codebase decides it, build on what it uses. State any default you pick aloud and record it in the spec as your call, never as something they agreed to. A default they never heard is one they could not reject.
5. **Play it back in short chunks.** As soon as you understand one part well enough to describe it, describe it back in a few short paragraphs, then return to questions about the next part. Mark every guess as a guess; only what they said goes in as theirs. End each chunk by asking what is wrong or missing.
6. **Write caller usage first (anything with an API).** Before types, modules, or file layout, write a short usage snippet and two real call sites showing how callers will use it. Derive the signatures from that usage. If the usage reads awkwardly, the shape is wrong.
7. **Propose 2-3 structurally distinct approaches.** Whole-shape alternatives, not point variations inside one shape (a different owner of state, a different seam, a different data model). Each with its trade-offs; lead with your recommendation and why. If you can only think of one, you have not looked hard enough. When a fork depends on feel or an observable fact (how it behaves, how fast it is, how it looks), build a throwaway prototype and observe it instead of arguing on paper. Build it in a scratch directory outside the source tree, label it throwaway, and never commit it.
8. **Screen the chosen design** against [references/design-red-flags.md](references/design-red-flags.md). Revise the shape for each flag it trips, or record why the flag is acceptable here.
9. **Present the design, scaled to its complexity.** A few sentences when straightforward, more when subtle. Cover architecture, the pieces and their boundaries, data flow, failure handling, and how it gets tested. Design for isolation: small units, one clear purpose each, testable alone. Confirm each section before the next.
10. **Write the spec** to `docs/specs/YYYY-MM-DD-<topic>.md` and commit it. Intent and why, goals and non-goals, constraints, the decisions as the user made them, the defaults you chose (marked as yours), and what is left to the builder.
11. **Builder check.** Dispatch one fresh subagent on a cheaper model with a flat brief: read the spec as the engineer who must plan and build it, with no way to ask the author, and return only the questions it would still need answered, each with why the answer changes what gets built, ranked by importance. It skips anything the spec leaves to the builder and anything it could reasonably decide itself. Sort its questions: answered already (put the answer in the spec), minor (settle it, mark it as your call), and the user's (only they can answer, and it changes what gets built). Bring the user's pile in one message, most important first, update the spec, and hand it over with a short list of the calls you made. That is the only round of questions the check produces. With no subagent tool, read the spec as that builder yourself.
12. **User reviews the written spec.** Ask them to read it and wait. If they want changes, make them.
13. **Hand off to [recipe](../recipe/SKILL.md).** That is the only skill you invoke next - not a build skill, not fire, not the code itself.

## Rules

- No code before an approved design at medium or project size. The approval is the user's yes to the described design, in the spec for a project and in chat for a medium change. The one exception is a throwaway prototype for a fork (step 7): it lives in a scratch directory outside the source tree, is never committed, and keeping anything it produced is a new request back through this gate. "Sounds good" to the idea does not cover a description you have not written.
- One question at a time, ending each message with a single question. The builder-check round (step 11) is the one exception: bring the user's pile in one message. Open first; multiple choice only when they are stuck or the choice is visual.
- Inspect before you ask. The repo and the conversation often already hold the answer.
- Always 2-3 structurally distinct approaches with a recommendation for a project or a medium change that has a real fork. One option is not a choice.
- Say your size, say your defaults. Silent choices are the ones nobody could reject.
- YAGNI. Cut every feature that does not serve the stated goal.
- Improve the code you must touch; never bolt on unrelated refactoring.
- The terminal state for a project is recipe. Stopping anywhere else means the design never became a plan.

## Common mistakes

- Running the full spec flow on a one-line change, or skipping the design on a project because it "looks simple".
- Opening with a menu of options, which steers, instead of an open question about their situation.
- Choosing the platform or language silently, then presenting the result as if they had agreed.
- Designing types and layout before writing how a caller will use the thing.
- Offering three approaches that are one shape with different knobs.
- Arguing on paper about something a ten-minute throwaway build would settle.
- Skipping the builder check, then handing recipe a spec with questions only the author could answer.
- Relitigating decisions pressure-test already pinned, or skipping pressure-test when the decisions are actually contested and coasting on momentum.
- Drifting into implementation before the user approved the design, then calling the approval a formality.
