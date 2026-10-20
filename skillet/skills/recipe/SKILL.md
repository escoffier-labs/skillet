---
name: recipe
version: 0.2.0
license: MIT
description: Use when an approved spec or design needs to become an implementation plan, after mise and before any code. Also use when the user says "write the plan", "plan this out", or the work will be executed later, by someone else, or in a fresh session.
---

# recipe

A recipe card is written so a cook who has never seen the dish can plate it exactly: exact pan, exact minutes, steps in order. "Season to taste" is how the same dish comes out different every night. This skill turns an approved spec into that card: an implementation plan a fresh agent session can execute with you unavailable for questions.

**A plan records decisions. It is not a transcript of the code.** Assume the implementer is a capable engineer who writes idiomatic code in the project's language once they know the exact interface and the exact test. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. The plan carries those. DRY, YAGNI, test-first, frequent commits.

## Preconditions

- An approved design or spec exists ([mise](../mise/SKILL.md)'s output, or equivalent). No spec? Run mise first. Recipe shapes decided work; it does not decide.
- One plan per subsystem. If the spec spans several independent subsystems, say so and split before going deep; each plan must produce working, testable software on its own.

## Steps

1. **Read the code you are planning against.** The files the spec touches, one neighboring module that shows the house pattern, the test layout. A plan written from memory or a description of the codebase hedges ("if main returns the code, leave it; otherwise wrap it"), and every hedge is a decision forwarded to the implementer.
2. **Map the file structure.** Before any tasks: every file the plan creates or modifies, and the one responsibility each holds. Prefer small focused files with clear boundaries; in an existing codebase, follow its patterns instead of restructuring. This map locks the decomposition. A file whose purpose needs "and" probably wants splitting.
3. **Write the header** (see Plan header). The spec travels with the plan.
4. **Decompose into tasks, each task into steps.** A task is the smallest unit that carries its own test cycle and is worth a reviewer's gate: fold setup, scaffolding, config, and docs into the task whose deliverable needs them, and split only where a reviewer could reject one task while approving its neighbor. A step is one action with a checkable result, written as a checkbox (`- [ ]`): write the failing test, run it and watch it fail, implement, run to green, commit. Every task names its exact file paths up front.
5. **Pin every decision.** Exit-code orderings, edge-case behavior, naming, where a helper lives: decided in the plan, with the reason when it is not obvious. A plan that says "your call", "adapt to taste", or ends with an open-questions section has pushed design onto the person with the least context. A decision that genuinely cannot be made yet goes back to [pressure-test](../pressure-test/SKILL.md) or the spec's author now, not into the plan.
6. **Self-review**, then fix inline (see Self-review).
7. **Save to `docs/plans/YYYY-MM-DD-<topic>.md`, commit, and hand off** (see Handoff). The plan, not memory of this conversation, is the source of truth.

## Plan header

Every plan opens with:

- **Goal:** one sentence.
- **Architecture:** two or three sentences.
- **Tech:** the key libraries and tools.
- **Spec:** the path to the spec this plan implements. Executors read both.
- **Global Constraints:** the spec's project-wide requirements (version floors, dependency limits, naming and copy rules, platform), one line each, with exact values copied from the spec. Every task implicitly includes them.
- **Review Focus:** up to five inputs or edge cases the spec implies but no task's tests exercise yet, most likely to bite a user first. One line each: the input or condition, and the behavior a reasonable person would expect. The spec says what the software must do, not everything it will meet, and its silence on an input is not permission for that input to break. Then add the test that pins each line to the task that owns the code. An empty list means you checked, not that you skipped.
- An instruction to workers to execute task by task, tracking the checkboxes.

## Task format

````markdown
### Task N: <component>

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/test_file.py`

**Interfaces:**
- Consumes: <what this task uses from earlier tasks, exact signatures>
- Produces: <what later tasks rely on: names, parameter and return types>

**You see:** <for a user-visible task: what the user observes when it works, e.g. the CLI line printed or the screen state>

- [ ] Write the failing test `test_specific_behavior`: assert `function("spec-literal-input") == "spec-literal-output"`
- [ ] Run it, watch it fail: `pytest tests/exact/path/test_file.py::test_specific_behavior -v` - expect FAIL, "function not defined"
- [ ] Implement `function(input: str) -> str` in `exact/path/to/file.py`
- [ ] Run to green: same command - expect PASS
- [ ] Commit: `git add -A && git commit -m "feat: <effect>"`
````

The Interfaces block matters because an implementer may see only their own task. It is how they learn the names and types the neighboring tasks use. Omit **You see** for internal tasks; keep it for anything a user can observe.

## What a step contains

A step is done when the implementer can write exactly one reasonable thing from it. The requirement is unambiguous, not complete. Each kind of step carries what makes it unambiguous and nothing more:

- **Test step:** the test's name and its assertions, as code, with the spec's literal values in them.
- **Code step:** the exact signature (name, parameters, return type), the file, and the values the spec pins. The implementer writes the body. A body appears only where the signature and tests do not determine the algorithm, or for exact copy the spec fixes.
- **Verification step:** the exact command and the output that means it passed.
- **Reference to another task:** point at that task's Interfaces block; do not repeat its code.

**Transcribe switch.** When a cheap worker will execute a task, mark it `transcribe` and give the full code body. Cheap workers copy; they do not decide. Everything else stays decision-level. Say in the plan which tasks are marked and why.

## No placeholders

The opposite failure to a transcript is a line that decides nothing. Each of these in a plan is a plan failure, not a shortcut:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "handle edge cases" without the cases and the handling
- "Write tests for the above" without the test name and assertions
- "Similar to Task N" instead of naming the signature and values; tasks get read out of order
- A step that says what to do without the exact command or the signature to do it with
- A name, type, or function referenced but defined in no task

## Self-review

With fresh eyes, check the plan against the spec, then fix inline:

- **Spec coverage:** every requirement in the spec points to a task that implements it.
- **Step scan:** each step lets the implementer write exactly one reasonable thing, and carries no more. A line that decides nothing is a gap; a body that signature plus tests already determine (outside a `transcribe` task) is a transcript. Fix both.
- **Consistency:** names, signatures, and types in later tasks match where earlier tasks defined them, and each Consumes line has a matching Produces.
- **Review Focus:** each input class the spec implies is either covered by a task's tests or listed in the header with its test added.
- **Proportion:** compare the plan's length to the spec's. A plan several times longer is a transcript of the program. If code blocks are most of the document, strip bodies down to signatures, test names, and assertions, then recheck that every step is still unambiguous.

## Handoff

Save and commit the plan, then give the user the path and ask them to read it before anything executes. Wait for that read.

Recommend an execution mode with a one-sentence reason drawn from the plan, and let the user override: **solo** (one session runs every task, then a fresh whole-branch review; cheapest, suits few or tightly coupled tasks) or **subagent** (a fresh worker and reviewer per task; more thorough, suits many tasks with clean interfaces or costly mistakes). If the user already named a mode, keep it and ask only whether the plan captures what they want. Then hand off to [fire](../fire/SKILL.md).

## Rules

- Exact paths, signatures, commands, and expected output on every step. Bodies only where they decide something or the task is marked `transcribe`.
- The implementer makes no design decisions. If writing a step surfaces an undecided question, decide it in the plan or take it back upstream; never forward it.
- Test-first inside every task that changes behavior. The failing run is a step of its own, not an assumption.
- Don't relitigate the spec. Decisions mise and pressure-test pinned arrive here settled; the plan implements them.
- Scale ceremony to the work: a one-task plan still gets the header, the file map, and real signatures in its steps. What it skips is task count, not rigor.

## Common mistakes

- Writing the program into the plan. Planning turns into implementing, the plan runs several times longer than the spec, and the implementer re-derives it anyway.
- Describing tests in prose ("test that add is idempotent") instead of naming the test and its assertions with the spec's values.
- Steps without run commands or expected output, so the executor cannot tell a broken step from a broken codebase.
- Component-sized "steps" that hide ten decisions, instead of single actions with a checkable result.
- An "open questions" or "decide while building" section. That is the tell the planning was not finished.
- Hedged structure: "put it in store.py, or a new helpers module if you prefer". The file map exists to settle exactly this.
- Skipping Review Focus, so every implementer ships the same crash on the one input nobody named.
- Writing the plan for yourself-tomorrow instead of a reader with no access to this conversation.
