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
  for key in name description license; do
    if ! printf '%s\n' "$fm" | grep -q "^$key:"; then
      echo "[fail] $id: frontmatter missing '$key:'"; return 1
    fi
  done
  local fname
  fname="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
  if [ "$fname" != "$id" ]; then
    echo "[fail] $id: frontmatter name '$fname' != dir name"; return 1
  fi
  if [ "${#fname}" -gt 64 ] || ! printf '%s' "$fname" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    echo "[fail] $id: frontmatter name must be a 1-64 character lowercase identifier"; return 1
  fi
  local license
  license="$(printf '%s\n' "$fm" | sed -n 's/^license:[[:space:]]*//p' | head -1)"
  if ! python3 - "$md" <<'PY'
import json
import re
import sys

lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
try:
    end = lines.index("---", 1)
except ValueError:
    raise SystemExit(1)

raw = ""
for line in lines[1:end]:
    if line.startswith("description:"):
        raw = line.split(":", 1)[1].strip()
        break

try:
    if raw.startswith('"'):
        description = json.loads(raw)
    elif raw.startswith("'") and raw.endswith("'"):
        description = raw[1:-1].replace("''", "'")
    else:
        description = re.split(r"\s+#", raw, maxsplit=1)[0].rstrip()
except (ValueError, json.JSONDecodeError):
    raise SystemExit(1)

if not isinstance(description, str) or not 1 <= len(description) <= 1024:
    raise SystemExit(1)
PY
  then
    echo "[fail] $id: frontmatter description must be 1-1024 characters"; return 1
  fi
  if [ "$license" != "MIT" ]; then
    echo "[fail] $id: frontmatter license must declare repository license MIT"; return 1
  fi
  if [ ! -f "$sj" ]; then
    echo "[fail] $id: skill.json missing"; return 1
  fi
  if ! python3 - "$sj" "$dir" "$id" <<'PY'
import json, os, sys
import re
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
version = m.get("version")
assert isinstance(version, str) and re.fullmatch(r"\d+\.\d+\.\d+", version), "version missing or invalid"
tl = m.get("trust_level")
assert tl in ("unreviewed", "workspace", "team", "public"), f"trust_level missing or invalid: {tl!r}"
PY
  then
    echo "[fail] $id: skill.json invalid"; return 1
  fi
  if command -v brigade >/dev/null 2>&1; then
    if ! brigade skills lint "$dir" >/dev/null 2>&1; then
      echo "[fail] $id: brigade skills lint failed"; return 1
    fi
  fi
  if [ "$id" = "t3-code" ]; then
    grep -Fq "references/multi-machine.md" "$md" || {
      echo "[fail] t3-code: multi-machine reference is not routed"; return 1
    }
    [ -f "$dir/references/multi-machine.md" ] || {
      echo "[fail] t3-code: multi-machine reference missing"; return 1
    }
    grep -Fq "Local-only SSH forward" "$dir/references/multi-machine.md" || {
      echo "[fail] t3-code: SSH tunnel fallback missing"; return 1
    }
    grep -Fq "Save and pair each environment" "$dir/references/multi-machine.md" || {
      echo "[fail] t3-code: saved environment workflow missing"; return 1
    }
    grep -Fq "Persist the SSH tunnel" "$dir/references/multi-machine.md" || {
      echo "[fail] t3-code: persistent SSH tunnel workflow missing"; return 1
    }
    grep -Fq "Remote loopback service" "$dir/references/multi-machine.md" || {
      echo "[fail] t3-code: remote loopback service missing"; return 1
    }
    grep -Fq "loginctl enable-linger" "$dir/references/multi-machine.md" || {
      echo "[fail] t3-code: logout persistence action missing"; return 1
    }
    grep -Fq "references/windows-remote.md" "$md" || {
      echo "[fail] t3-code: Windows reference is not routed"; return 1
    }
    [ -f "$dir/references/windows-remote.md" ] || {
      echo "[fail] t3-code: Windows reference missing"; return 1
    }
    grep -Fq "# Windows Remote Host" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows remote-host workflow missing"; return 1
    }
    grep -Fq "New-ScheduledTask" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows Scheduled Task example missing"; return 1
    }
    grep -Fq '$env:COMPUTERNAME' "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows task principal guidance missing"; return 1
    }
    grep -Fq "Get-NetTCPConnection" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows listener verification missing"; return 1
    }
    grep -Fq "Do not stop every Node.js process" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows child-process safety guidance missing"; return 1
    }
    grep -Fq "AddSeconds(60)" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows Tailscale startup wait missing"; return 1
    }
    grep -Fq "Export-ScheduledTask" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: existing Windows task backup missing"; return 1
    }
    grep -Fq "curl --connect-timeout" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: controller-side direct TCP probe missing"; return 1
    }
    grep -Fq "BatchMode=yes" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows SSH fallback preflight missing"; return 1
    }
    if grep -Fq "curl --connect-timeout 5 --verbose" "$dir/references/windows-remote.md"; then
      echo "[fail] t3-code: Windows probe may print sensitive response content"; return 1
    fi
    grep -Fq "ssh-keygen -lf" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows SSH fingerprint verification missing"; return 1
    }
    grep -Fq "ssh-keyscan -t ed25519" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows SSH key-type comparison is ambiguous"; return 1
    }
    grep -Fq "yyyyMMdd-HHmmss" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows task backup is not timestamped"; return 1
    }
    grep -Fq "windows-user@windows-host" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: Windows tunnel target is ambiguous"; return 1
    }
    grep -Fq "https://t3.codes/download" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: official installer page missing"; return 1
    }
    grep -Fq "https://github.com/pingdotgg/t3code/releases" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: official release source missing"; return 1
    }
    grep -Fq "npx t3@latest" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: stable npm channel missing"; return 1
    }
    grep -Fq "npx t3@nightly" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: nightly npm channel missing"; return 1
    }
    grep -Fq "npm view t3 dist-tags --json" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: runtime channel discovery missing"; return 1
    }
    grep -Fq "select(.prerelease)" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: latest GitHub nightly discovery missing"; return 1
    }
    grep -Fq "npx --yes t3@latest serve" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: stable headless command missing"; return 1
    }
    grep -Fq "npx --yes t3@nightly serve" "$dir/references/updates-and-launchers.md" || {
      echo "[fail] t3-code: nightly headless command missing"; return 1
    }
    grep -Fq "winget install T3Tools.T3Code" "$dir/references/windows-remote.md" || {
      echo "[fail] t3-code: official Windows installer command missing"; return 1
    }
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
  if ! python3 - "$ROOT/station.json" "$count" <<'PY'
import json, sys
path, count = sys.argv[1], int(sys.argv[2])
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
assert surface.get("probe_contains") == [f"[ok] catalog ({count} skills)"]
PY
  then
    echo "[fail] catalog: station.json invalid"
    return 1
  fi
  echo "[ok] catalog ($count skills)"
}

check_linter_regressions() {
  local tmp valid invalid description_1024 description_1025
  tmp="$(mktemp -d)"
  valid="$tmp/skillet/skills/valid-length"
  invalid="$tmp/skillet/skills/invalid-length"
  mkdir -p "$tmp/tests" "$valid" "$invalid"
  cp "$0" "$tmp/tests/lint-skills.sh"

  description_1024="$(python3 -c 'print("x" * 1024, end="")')"
  description_1025="${description_1024}x"
  printf '%s\n' '---' 'name: valid-length' "description: \"$description_1024\"" 'license: MIT' '---' >"$valid/SKILL.md"
  printf '%s\n' '---' 'name: invalid-length' "description: $description_1025" 'license: MIT' '---' >"$invalid/SKILL.md"
  printf '%s\n' '{"id":"valid-length","version":"0.1.0","tests":["true"],"trust_level":"workspace"}' >"$valid/skill.json"
  printf '%s\n' '{"id":"invalid-length","version":"0.1.0","tests":["true"],"trust_level":"workspace"}' >"$invalid/skill.json"
  : >"$valid/CHANGELOG.md"
  : >"$invalid/CHANGELOG.md"

  if ! PATH=/usr/bin:/bin bash "$tmp/tests/lint-skills.sh" valid-length >/dev/null 2>&1; then
    echo "[fail] self-test: parsed 1024-character description was rejected"
    rm -rf "$tmp"
    return 1
  fi
  if PATH=/usr/bin:/bin bash "$tmp/tests/lint-skills.sh" invalid-length >/dev/null 2>&1; then
    echo "[fail] self-test: parsed 1025-character description was accepted"
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
  echo "[ok] linter regression boundaries"
}

if [ "$#" -ge 1 ]; then
  check_skill "$SKILLS_DIR/$1" || FAIL=1
else
  check_linter_regressions || FAIL=1
  for d in "$SKILLS_DIR"/*/; do
    check_skill "$d" || FAIL=1
  done
  check_catalog || FAIL=1
fi
exit $FAIL
