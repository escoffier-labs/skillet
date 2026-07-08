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

if [ "$#" -ge 1 ]; then
  check_skill "$SKILLS_DIR/$1" || FAIL=1
else
  for d in "$SKILLS_DIR"/*/; do
    check_skill "$d" || FAIL=1
  done
fi
exit $FAIL
