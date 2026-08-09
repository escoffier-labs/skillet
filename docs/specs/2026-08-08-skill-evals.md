# Skill eval manifests (A/B baseline)

**Issue:** [escoffier-labs/skillet#25](https://github.com/escoffier-labs/skillet/issues/25)
**Status:** design (implementation follows in the same PR after this doc lands)
**Source convention:** [Agent Skills: Evaluating skill output quality](https://agentskills.io/skill-creation/evaluating-skills)

## Problem

Skillet skills are load-bearing across the fleet, but none has a regression test that asks whether the skill still produces the behavior its `SKILL.md` claims. Today a skill edit is verified by vibes, a fresh-agent spot check documented in CONTRIBUTING, or the structural catalog linter (`tests/lint-skills.sh`). Structural lint proves packages are well-formed. It does not prove an agent following the skill outperforms an agent without it.

Issue #25 asks for the Agent Skills evaluation convention: per-skill `evals/evals.json`, a with-skill vs without-skill harness, graded results with quoted evidence, and an optional path into Brigade's outcome ledger.

## Goals

1. Adopt a per-skill eval manifest format aligned with agentskills.io (`evals/evals.json`).
2. Define an A/B harness contract: same prompt and files, once with the skill loaded and once without (baseline), then measure the delta.
3. Record graded results with per-assertion PASS/FAIL and quoted evidence.
4. Gate manifest validity in CI via the existing lint surface (or a sibling script it invokes), without requiring live LLM keys on every push.
5. Pilot on 1-2 skills so the format earns its keep before the catalog is flooded with empty eval stubs.
6. Document optional wiring to `brigade work verify run --capture` so eval outcomes can feed the outcome ledger when Brigade is present. Brigade is not required to author or structurally validate manifests.

## Non-goals

- Running live LLM A/B on every CI push. CI has no model keys and must stay deterministic.
- Requiring every skill to ship evals in the first cut. Absence is allowed; presence is validated.
- Building a full judge-model SDK or HTML report UI (out of scope for size/L first slice; comparable tools exist upstream).
- Replacing `tests/lint-skills.sh` catalog/structural checks, script unit tests, or the CONTRIBUTING fresh-agent test.
- Auto-improving skills from eval failures (the iteration loop is a human/agent workflow, not a CI bot).
- Committing large binary fixtures or private fleet content into `evals/files/`.

## Design overview

```
skillet/skills/<id>/
  SKILL.md
  skill.json
  CHANGELOG.md
  evals/                    # optional
    evals.json              # authored by hand
    files/                  # optional input fixtures (text only in pilot)
  scripts/ ...              # unchanged
  tests/ ...                # unchanged (deterministic script units)

tests/
  lint-skills.sh            # catalog + structure (existing)
  lint-evals.sh             # NEW: validate evals/evals.json when present
  run-skill-evals.sh        # NEW: dry-run / live A/B harness entrypoint
```

Live A/B runs write artifacts outside the skill package (gitignored workspace), never into `evals/`:

```
.skill-eval-workspace/<skill-id>/iteration-N/
  eval-<slug>/
    with_skill/
      outputs/
      timing.json
      grading.json
    without_skill/
      outputs/
      timing.json
      grading.json
  benchmark.json
```

## Target audience and operators

| Operator | What they do |
|---|---|
| Skill author | Adds `evals/evals.json` (+ optional `evals/files/`) when behavior is worth locking. |
| CI / `lint-skills.sh` | Structurally validates any present manifest; never calls a model. |
| Human or agent with keys | Runs `tests/run-skill-evals.sh --live` (or documents a manual subagent loop) to produce graded A/B artifacts. |
| Brigade-wired repo (optional) | Captures the dry-run or live exit via `brigade work verify run --capture skill-evals`. |

## `evals/evals.json` schema

Top-level object:

| Field | Type | Required | Notes |
|---|---|---|---|
| `skill_name` | string | yes | Must equal the skill directory name and `skill.json` `id`. |
| `schema_version` | string | yes | Skillet extension. Pilot value: `"skillet.evals.v1"`. Distinguishes our file from future upstream revisions. |
| `evals` | array | yes | At least one eval case when the file exists. |

Each element of `evals`:

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | integer or string | yes | Stable within the file. Integer IDs match the upstream examples; string slugs are allowed for readability (`"leak-private-ip"`). Harness normalizes directory names to `eval-<id>`. |
| `prompt` | string | yes | Realistic user message. Non-empty. |
| `expected_output` | string | yes | Human-readable success description. Non-empty. Not a brittle exact-match oracle. |
| `files` | string[] | no | Paths relative to the skill root (typically `evals/files/...`). Every listed path must exist. |
| `assertions` | string[] | yes (skillet.evals.v1) | Verifiable statements. Upstream treats these as optional until after the first run; Skillet requires at least one so CI can validate intent and dry-run grading shape. Prefer objective checks. |

### Example (abbreviated)

```json
{
  "schema_version": "skillet.evals.v1",
  "skill_name": "plate",
  "evals": [
    {
      "id": "scrub-private-ip",
      "prompt": "Scrub this draft before I post it:\n\nWe hit the API at 192.168.1.50 last night.",
      "expected_output": "A hit table that flags the private IP and proposes an RFC 5737 documentation-range replacement, waiting for confirmation before rewriting.",
      "files": [],
      "assertions": [
        "The output identifies a private IP address as a leak",
        "The proposed replacement uses an RFC 5737 or RFC 2544 documentation range, not an invented invalid IP",
        "The output does not silently rewrite the draft without asking for confirmation"
      ]
    }
  ]
}
```

### Assertion guidance

Good:

- `"The output quotes a proving command and its exit status"`
- `"The report includes a hit table with location and proposed replacement"`
- `"No Co-Authored-By trailer remains in the scrubbed commit message suggestion"`

Weak (reject in review, lint may warn later):

- `"The output is good"`
- `"Uses exactly the phrase 'Total Revenue: $X'"`

### Files and fixtures

- Prefer small UTF-8 text fixtures under `evals/files/`.
- No secrets, private hostnames, real emails, or absolute home paths that identify a person. Use documentation ranges and `example.com`.
- Fixture paths in `files` are relative to the skill directory, matching upstream examples.

## A/B harness

### Contract

For each eval case `E`:

1. **with_skill:** clean context; skill path available; prompt = `E.prompt`; input files staged; outputs to `with_skill/outputs/`.
2. **without_skill:** same prompt and files; no skill path (or skill content withheld); outputs to `without_skill/outputs/`.
3. Grade each side independently against `E.assertions` (+ `expected_output` as holistic context).
4. Aggregate into `benchmark.json` with pass-rate / timing / token means and a `delta` object.

Delta measurement (per iteration):

| Metric | Meaning |
|---|---|
| `delta.pass_rate` | `with_skill.mean - without_skill.mean` (positive = skill helps) |
| `delta.time_seconds` | Cost in wall time |
| `delta.tokens` | Cost in tokens |

A skill earns its context cost when pass-rate delta is clearly positive relative to token/time cost. Exact pass thresholds are not enforced in CI for the pilot; they are review signals for skill authors.

### Modes

| Mode | Command shape | Requires model? | CI? |
|---|---|---|---|
| **validate** (default) | `tests/lint-evals.sh` or `tests/run-skill-evals.sh --validate` | no | yes |
| **dry-run** | `tests/run-skill-evals.sh --dry-run [skill-id]` | no | yes (optional self-check) |
| **live** | `tests/run-skill-evals.sh --live [skill-id]` | yes | no (manual / nightly later) |

**validate:** JSON parse, schema fields, `skill_name` match, file path existence, non-empty prompts/assertions, unique ids.

**dry-run:** validate, then emit the structural A/B plan (which prompts would run, output dirs, assertion list) and a template `grading.json` / `benchmark.json` shape with empty or placeholder results. Exit 0 if manifests are valid. This proves the harness wiring without keys.

**live:** reserved for environments with agent/model access. The pilot implementation may stub `--live` with a clear error that documents the manual subagent procedure from the Agent Skills docs (spawn clean with-skill and without-skill runs, write timing/grading artifacts). A later PR can plug in a real runner; do not block the manifest format on that.

### Graded results with quoted evidence

`grading.json` per arm:

```json
{
  "assertion_results": [
    {
      "text": "The output identifies a private IP address as a leak",
      "passed": true,
      "evidence": "Hit table row 1: '192.168.1.50' flagged as private IP (RFC 1918)"
    }
  ],
  "summary": {
    "passed": 1,
    "failed": 0,
    "total": 1,
    "pass_rate": 1.0
  }
}
```

Rules:

- PASS requires concrete quoted or referenced evidence from the output.
- FAIL when the label is present but the substance is missing.
- Prefer scripts for mechanical assertions (file exists, JSON parses, grep hits); use an LLM judge only for qualitative assertions during live runs.

### Workspace and gitignore

Add `.skill-eval-workspace/` to `.gitignore`. Do not commit iteration artifacts. Authors may paste summary numbers into skill `CHANGELOG.md` when an eval run informed a change ("baseline A/B: pass_rate +0.5 on plate scrub-private-ip").

## Brigade / outcome ledger integration (optional)

When a repo is Brigade-wired (`.brigade/` present or `brigade status --target .` succeeds), operators may capture the structural or live eval command:

```bash
brigade work verify run --target . \
  --command "bash tests/run-skill-evals.sh --dry-run" \
  --capture skill-evals
```

Notes:

- This follows the evidence gate owned by `check` and the loop in `docs/brigade-process-model.md`.
- Capture id `skill-evals` is a convention for this surface; it is not a skillet skill id.
- Skillet CI and contributors without Brigade keep using the raw bash commands. No Brigade binary is required to merge eval manifests.
- Live A/B receipts are more useful for the ledger than dry-run receipts; dry-run capture still proves the gate path works.
- This machine / this PR does not require Brigade to be installed. Wiring is documented only.

## Rollout: pilot skills

Ship evals for exactly two pilots first:

| Skill | Why first |
|---|---|
| **plate** | Mechanical leak rules (private IPs, em dashes, Co-Authored-By) yield objective assertions and small text fixtures. Clear with/without delta expected. |
| **check** | Load-bearing evidence gate. Assertions can lock "quote the proving command" and "failed verify is the finding" without needing a whole product repo. |

Defer evals for the remaining catalog until the pilot format survives one real skill edit cycle. Do not add empty `evals/` directories to every skill.

Suggested first cases (to be authored in the implementation commit, not required for the design commit):

1. **plate / scrub-private-ip** — draft containing a private IP; expect flag + doc-range replacement + confirm-before-rewrite.
2. **plate / scrub-em-dash-and-trailer** — draft with an em dash and a Co-Authored-By line; expect both flagged.
3. **check / claim-without-evidence** — prompt that invites a "tests pass" claim with no run; expect the skill to refuse and demand a proving command.
4. **check / failed-verify-is-finding** — prompt where the proving command fails; expect report of failure, not silent repair.

## Lint / CI hooks

1. New script `tests/lint-evals.sh`:
   - Scan `skillet/skills/*/evals/evals.json`.
   - Validate schema (python3 stdlib `json` + field checks; no new runtime deps).
   - Exit 0 when no eval manifests exist (pilots not yet required for the whole catalog).
   - Exit non-zero on any invalid manifest.
2. `tests/lint-skills.sh` full-catalog path calls `lint-evals.sh` (or inlines an equivalent check) so `station.json`'s existing probe (`bash tests/lint-skills.sh` expecting `[ok] catalog (36 skills)`) still passes and eval validation rides along.
3. Emit a clear ok line, e.g. `[ok] evals (N manifests)`.
4. Per-skill lint (`tests/lint-skills.sh plate`) should validate that skill's evals if present.
5. Self-test fixtures in `check_linter_regressions` (or a sibling regression in `lint-evals.sh`): malformed JSON, wrong `skill_name`, missing fixture file, empty assertions.
6. `.github/workflows/lint-skills.yml` needs no new job if lint-skills invokes lint-evals; keep one workflow.

`skill.json` `tests` lists for pilot skills may add `bash ../../../tests/lint-evals.sh <id>` once the script exists. Not required if the catalog path already covers them.

## Implementation plan (post-design)

Ordered smallest useful slice:

1. Land this design doc (this commit).
2. Add schema validator `tests/lint-evals.sh` + dry-run harness `tests/run-skill-evals.sh`.
3. Wire validator into `tests/lint-skills.sh`.
4. Add `.skill-eval-workspace/` to `.gitignore`.
5. Author `evals/evals.json` (+ fixtures if needed) for `plate` and `check`.
6. Document live A/B procedure in harness `--help` / stderr for `--live`.
7. Verify with `bash tests/lint-skills.sh` (catalog ok + evals ok).
8. Push follow-up commits on the same PR.

## Open questions

1. **Integer vs string eval ids.** Upstream examples use integers; string slugs read better in directory names. Pilot allows both. Should we standardize on strings later?
2. **Assertions required?** Upstream delays assertions until after the first live run. Skillet requires them in `skillet.evals.v1` so CI validates intent. Revisit if authors find first-draft authoring too heavy.
3. **Live runner ownership.** Stay with documented manual/subagent runs, shell into an external tool (e.g. community `agent-skills-eval`), or build a thin skillet-native live mode later?
4. **Nightly live CI.** Once keys exist in a private runner, should live A/B become a scheduled workflow that posts summaries without blocking PRs?
5. **Pass-rate gate.** Should a future policy fail CI if a pilot skill's last committed benchmark delta falls below a threshold? (Recommend no until we have stable live runs.)
6. **Workspace location.** Sibling `<skill>-workspace/` (upstream) vs repo-root `.skill-eval-workspace/` (easier gitignore). Pilot chooses the latter; revisit if upstream tooling assumes the sibling layout.
7. **Promotion from dry-run to required evals.** When do we require evals for new skills in CONTRIBUTING? Suggest: after two successful pilot cycles, require evals for skills that ship `scripts/`, keep prose-only skills optional.

## Acceptance for the PR that implements this design

- Design doc merged or present on the PR branch.
- `tests/lint-evals.sh` validates manifests; wired from `tests/lint-skills.sh`.
- `tests/run-skill-evals.sh` supports `--validate` / `--dry-run`, and documents `--live`.
- Pilot manifests for `plate` and `check`.
- `bash tests/lint-skills.sh` prints catalog ok and evals ok.
- No live model dependency in CI.
- Brigade capture documented, not required.
