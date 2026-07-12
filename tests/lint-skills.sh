#!/usr/bin/env bash
# lint-skills.sh [skill-id]
# Structural test for skillet skills, declared in each skill.json's `tests`
# list. Validates SKILL.md + skill.json and runs `brigade skills lint`.
# With no argument it checks every skill; exits non-zero if any fail.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skillet/skills"
FAIL=0

check_skill() {
  local dir="$1" id
  id="$(basename "$dir")"
  local md="$dir/SKILL.md" sj="$dir/skill.json"

  if [ ! -f "$md" ]; then
    echo "[fail] $id: SKILL.md missing"; return 1
  fi
  if [ "$(head -1 "$md")" != "---" ]; then
    echo "[fail] $id: SKILL.md does not start with YAML frontmatter"; return 1
  fi
  local fm
  fm="$(awk '/^---$/{n++; next} n==1{print}' "$md")"
  for key in name description; do
    if ! printf '%s\n' "$fm" | grep -q "^$key:"; then
      echo "[fail] $id: frontmatter missing '$key:'"; return 1
    fi
  done
  local fname
  fname="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
  if [ "$fname" != "$id" ]; then
    echo "[fail] $id: frontmatter name '$fname' != dir name"; return 1
  fi
  if [ ! -f "$sj" ]; then
    echo "[fail] $id: skill.json missing"; return 1
  fi
  if ! python3 - "$sj" "$dir" "$id" <<'PY'
import json, os, sys
sj, d, sid = sys.argv[1], sys.argv[2], sys.argv[3]
m = json.load(open(sj))
assert m.get("id") == sid, f"skill.json id {m.get('id')!r} != {sid!r}"
clp = m.get("changelog_path")
if clp:
    assert os.path.isfile(os.path.join(d, clp)), f"changelog_path {clp!r} does not resolve"
else:
    assert os.path.isfile(os.path.join(d, "CHANGELOG.md")), "no CHANGELOG.md in skill dir"
tests = m.get("tests")
assert isinstance(tests, list) and tests, "tests list missing or empty"
tl = m.get("trust_level")
assert tl in (None, "unreviewed", "workspace", "team", "public"), f"bad trust_level {tl!r}"
PY
  then
    echo "[fail] $id: skill.json invalid"; return 1
  fi
  if command -v brigade >/dev/null 2>&1; then
    if ! brigade skills lint "$dir" >/dev/null 2>&1; then
      echo "[fail] $id: brigade skills lint failed"; return 1
    fi
  fi
  echo "[ok] $id"
}

check_catalog() {
  local readme="$ROOT/README.md"
  local routing="$SKILLS_DIR/using-skillet/SKILL.md"
  local workflow="$ROOT/.github/workflows/lint-skills.yml"
  local count badge id
  count="$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  badge="$(sed -n 's/.*badge\/skills-\([0-9][0-9]*\)-orange.*/\1/p' "$readme" | head -1)"
  if [ "$badge" != "$count" ]; then
    echo "[fail] catalog: README badge says ${badge:-missing}, found $count skills"
    return 1
  fi
  for id in $(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort); do
    grep -Fq "| **$id** |" "$readme" || {
      echo "[fail] catalog: README missing $id"
      return 1
    }
    grep -Fq -- "- \`$id\`" "$routing" || {
      echo "[fail] catalog: using-skillet missing $id"
      return 1
    }
  done
  [ ! -d "$SKILLS_DIR/seo-fleet" ] || {
    echo "[fail] catalog: seo-fleet must be replaced by garnish"
    return 1
  }
  for id in garnish stocktake thermometer; do
    [ -d "$SKILLS_DIR/$id" ] || {
      echo "[fail] catalog: required skill $id missing"
      return 1
    }
  done
  if [ ! -f "$workflow" ] || ! grep -Fq "tests/lint-skills.sh" "$workflow"; then
    echo "[fail] catalog: CI workflow missing linter invocation"
    return 1
  fi
  if ! python3 - "$ROOT/station.json" <<'PY'
import json, sys
path = sys.argv[1]
manifest = json.load(open(path))
assert manifest.get("schema") == "brigade.station.v1"
assert manifest.get("name") == "skillet"
assert manifest.get("station") == "skills"
assert manifest.get("lifecycle") == "active"
tools = manifest.get("tools")
assert isinstance(tools, list) and len(tools) == 1
tool = tools[0]
assert tool.get("name") == "skillet"
assert tool.get("kind") == "skill-roster"
assert tool.get("install") == ["npx", "skills", "add", "escoffier-labs/skillet"]
surfaces = tool.get("surfaces")
assert isinstance(surfaces, list) and len(surfaces) == 1
surface = surfaces[0]
assert surface.get("kind") == "verify-exit"
assert surface.get("probe") == ["bash", "tests/lint-skills.sh"]
PY
  then
    echo "[fail] catalog: station.json invalid"
    return 1
  fi
  echo "[ok] catalog ($count skills)"
}

if [ "$#" -ge 1 ]; then
  check_skill "$SKILLS_DIR/$1" || FAIL=1
else
  for d in "$SKILLS_DIR"/*/; do
    check_skill "$d" || FAIL=1
  done
  check_catalog || FAIL=1
fi
exit $FAIL
