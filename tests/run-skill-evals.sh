#!/usr/bin/env bash
# run-skill-evals.sh [--validate|--dry-run|--live] [skill-id]
#
# A/B eval harness entrypoint for skillet skills that ship evals/evals.json.
# See docs/specs/2026-08-08-skill-evals.md.
#
# Modes:
#   --validate  (default) structural validation via lint-evals.sh
#   --dry-run   validate, then emit the with_skill / without_skill plan and
#               placeholder artifact layout under .skill-eval-workspace/
#   --live      reserved for model-backed A/B runs; documents the procedure
#               and exits non-zero until a live runner is wired
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skillet/skills"
WORKSPACE_ROOT="$ROOT/.skill-eval-workspace"
MODE="validate"
SKILL_FILTER=""

usage() {
  cat <<'EOF'
Usage: tests/run-skill-evals.sh [--validate|--dry-run|--live] [skill-id]

  --validate   Validate eval manifests (default). No model required.
  --dry-run    Validate, then write a structural A/B plan under
               .skill-eval-workspace/<skill>/iteration-dry-run/.
  --live       Attempt a live with/without-skill A/B run. Not implemented in
               the pilot slice; prints the manual procedure and exits 2.

Optional Brigade capture (when Brigade is wired):

  brigade work verify run --target . \
    --command "bash tests/run-skill-evals.sh --dry-run" \
    --capture skill-evals
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --validate|--dry-run|--live)
      MODE="${1#--}"
      shift
      ;;
    -*)
      echo "[fail] unknown flag: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [ -n "$SKILL_FILTER" ]; then
        echo "[fail] only one skill-id is supported" >&2
        exit 1
      fi
      SKILL_FILTER="$1"
      shift
      ;;
  esac
done

validate() {
  if [ -n "$SKILL_FILTER" ]; then
    bash "$ROOT/tests/lint-evals.sh" "$SKILL_FILTER"
  else
    LINT_EVALS_SKIP_SELF_TESTS=1 bash "$ROOT/tests/lint-evals.sh"
  fi
}

dry_run_skill() {
  local skill_id="$1"
  local skill_dir="$SKILLS_DIR/$skill_id"
  local manifest="$skill_dir/evals/evals.json"
  local iteration_dir="$WORKSPACE_ROOT/$skill_id/iteration-dry-run"

  [ -f "$manifest" ] || return 0
  rm -rf "$iteration_dir"
  mkdir -p "$iteration_dir"

  python3 - "$manifest" "$skill_id" "$skill_dir" "$iteration_dir" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
skill_id = sys.argv[2]
skill_dir = Path(sys.argv[3])
iteration_dir = Path(sys.argv[4])
data = json.loads(manifest_path.read_text(encoding="utf-8"))

plan = {
    "mode": "dry-run",
    "skill_name": skill_id,
    "skill_path": str(skill_dir),
    "schema_version": data.get("schema_version"),
    "note": (
        "Dry-run only. No model was invoked. Live A/B requires spawning a clean "
        "agent twice per eval (with_skill and without_skill), writing outputs/, "
        "timing.json, and grading.json with quoted evidence per assertion."
    ),
    "evals": [],
}

for case in data["evals"]:
    case_id = case["id"]
    slug = f"eval-{case_id}"
    eval_dir = iteration_dir / slug
    for arm in ("with_skill", "without_skill"):
        arm_dir = eval_dir / arm
        (arm_dir / "outputs").mkdir(parents=True, exist_ok=True)
        timing = {"total_tokens": None, "duration_ms": None, "status": "not_run"}
        (arm_dir / "timing.json").write_text(json.dumps(timing, indent=2) + "\n", encoding="utf-8")
        grading = {
            "assertion_results": [
                {"text": assertion, "passed": None, "evidence": "not graded (dry-run)"}
                for assertion in case["assertions"]
            ],
            "summary": {
                "passed": 0,
                "failed": 0,
                "total": len(case["assertions"]),
                "pass_rate": None,
                "status": "not_run",
            },
        }
        (arm_dir / "grading.json").write_text(json.dumps(grading, indent=2) + "\n", encoding="utf-8")
        readme = arm_dir / "outputs" / "README.txt"
        readme.write_text(
            f"Placeholder outputs for {skill_id} / {slug} / {arm}.\n"
            f"Prompt would be:\n{case['prompt']}\n",
            encoding="utf-8",
        )

    plan["evals"].append(
        {
            "id": case_id,
            "slug": slug,
            "prompt": case["prompt"],
            "expected_output": case["expected_output"],
            "files": case.get("files") or [],
            "assertions": case["assertions"],
            "arms": {
                "with_skill": {
                    "skill_path": str(skill_dir),
                    "output_dir": str(eval_dir / "with_skill" / "outputs"),
                },
                "without_skill": {
                    "skill_path": None,
                    "output_dir": str(eval_dir / "without_skill" / "outputs"),
                },
            },
        }
    )

benchmark = {
    "mode": "dry-run",
    "run_summary": {
        "with_skill": {
            "pass_rate": {"mean": None, "stddev": None},
            "time_seconds": {"mean": None, "stddev": None},
            "tokens": {"mean": None, "stddev": None},
        },
        "without_skill": {
            "pass_rate": {"mean": None, "stddev": None},
            "time_seconds": {"mean": None, "stddev": None},
            "tokens": {"mean": None, "stddev": None},
        },
        "delta": {
            "pass_rate": None,
            "time_seconds": None,
            "tokens": None,
        },
    },
    "note": "Populate after a live A/B run. See docs/specs/2026-08-08-skill-evals.md.",
}
(iteration_dir / "benchmark.json").write_text(json.dumps(benchmark, indent=2) + "\n", encoding="utf-8")
(iteration_dir / "plan.json").write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")
print(f"[ok] dry-run plan {skill_id} -> {iteration_dir}")
PY
}

dry_run() {
  local id
  if [ -n "$SKILL_FILTER" ]; then
    dry_run_skill "$SKILL_FILTER" || return 1
    return 0
  fi
  for id in $(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort); do
    if [ -f "$SKILLS_DIR/$id/evals/evals.json" ]; then
      dry_run_skill "$id" || return 1
    fi
  done
}

live_stub() {
  cat <<'EOF' >&2
[fail] --live is not implemented in the pilot slice (no model keys in CI).

Manual live A/B procedure (from agentskills.io / docs/specs/2026-08-08-skill-evals.md):

1. Pick a skill with evals/evals.json (pilot: plate, check).
2. For each eval case, spawn a clean agent twice:
   - with_skill: provide the skill path, prompt, and files; save to
     .skill-eval-workspace/<skill>/iteration-N/eval-<id>/with_skill/outputs/
   - without_skill: same prompt and files, no skill path; save to without_skill/outputs/
3. Write timing.json (total_tokens, duration_ms) per arm.
4. Grade each assertion into grading.json with quoted evidence (PASS requires evidence).
5. Aggregate means and delta into benchmark.json.
6. Optionally capture via:
   brigade work verify run --target . \
     --command "bash tests/run-skill-evals.sh --dry-run <skill>" \
     --capture skill-evals

Until a live runner ships, use --dry-run to exercise the artifact layout.
EOF
  exit 2
}

case "$MODE" in
  validate)
    validate
    ;;
  dry-run)
    validate || exit $?
    dry_run
    ;;
  live)
    live_stub
    ;;
  *)
    echo "[fail] unknown mode: $MODE" >&2
    exit 1
    ;;
esac
