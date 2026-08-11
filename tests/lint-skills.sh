#!/usr/bin/env bash
# lint-skills.sh [skill-id]
# Structural test for skillet skills, declared in each skill.json's `tests`
# list. Validates SKILL.md + skill.json and runs `brigade skills lint`.
# With no argument it checks every skill; exits non-zero if any fail.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skillet/skills"
FAIL=0

# Boundary markers found by the 2026-07-25 audit. Keep these declarations near
# the lint configuration so new read-only surfaces are added in one place.
READ_ONLY_SKILLS=(
  line-check
  bug-hunt
  security-sweep
  special
  latent-premises
  retry-safety
)
AUDIT_ONLY_SECTIONS=(
  garnish:AUDIT
)
FIX_APPLICATION_PATTERN='(?i)\b(?:apply|implement|execute|perform|make|edit|modify|change|patch|correct|remediate|repair|resolve|write)\b.{0,80}\b(?:fix|fixes|remediation|remediations|recommendation|recommendations|patch|patches|change|changes|edit|edits|file|files|finding|findings)\b'

# Skills that fetch or ingest external content must declare the shared
# Untrusted content section. Keep the roster next to the other boundary lists;
# the contract text lives in docs/untrusted-content.md.
EXTERNAL_CONTENT_SKILLS=(
  grill
  plate
  publish-readiness
  review
  sendback
  security-sweep
  brigade-handoffs
  reel-check
  stocktake
  fleet-conductor
)

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
  local frontmatter_result frontmatter_version
  if ! frontmatter_result="$(python3 - "$md" "$id" 2>&1 <<'PY'
import re
import sys

path, skill_id = sys.argv[1:]


def fail(msg):
    print(f"{path}: {msg}", file=sys.stderr)
    raise SystemExit(1)


_PLAIN_NULL = {"", "~", "null", "Null", "NULL"}
_PLAIN_BOOL = {"true", "True", "TRUE", "false", "False", "FALSE"}
_INT_RE = re.compile(r"^[+-]?(?:0|[1-9][0-9_]*|0o[0-7_]+|0x[0-9A-Fa-f_]+)$")
_FLOAT_RE = re.compile(
    r"^[+-]?(?:\.[0-9_]+|[0-9][0-9_]*(?:\.[0-9_]*)?)"
    r"(?:[eE][+-]?[0-9]+)?$"
)
_SPECIAL_FLOATS = {
    ".inf", ".Inf", ".INF", "+.inf", "+.Inf", "+.INF",
    "-.inf", "-.Inf", "-.INF", ".nan", ".NaN", ".NAN",
}
_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):[ \t]*(.*)$")


def resolve_plain(text):
    if text in _PLAIN_NULL:
        return None
    if text in _PLAIN_BOOL:
        return text in ("true", "True", "TRUE")
    if _INT_RE.match(text):
        return 0
    if _FLOAT_RE.match(text) or text in _SPECIAL_FLOATS:
        return 0.0
    return text


def parse_double_quoted(raw, lineno):
    out = []
    i = 1
    n = len(raw)
    while i < n:
        ch = raw[i]
        if ch == "\\":
            if i + 1 >= n:
                fail(f"frontmatter line {lineno}: dangling escape in double-quoted scalar")
            esc = raw[i + 1]
            mapping = {
                "0": "\0", "a": "\a", "b": "\b", "t": "\t", "n": "\n",
                "v": "\v", "f": "\f", "r": "\r", "e": "\x1b", " ": " ",
                '"': '"', "/": "/", "\\": "\\", "N": "\u0085",
                "_": "\u00a0", "L": "\u2028", "P": "\u2029",
            }
            if esc in mapping:
                out.append(mapping[esc])
                i += 2
                continue
            if esc in {"x", "u", "U"}:
                width = {"x": 2, "u": 4, "U": 8}[esc]
                if i + width + 1 >= n:
                    fail(f"frontmatter line {lineno}: bad \\{esc} escape in double-quoted scalar")
                hexpart = raw[i + 2:i + 2 + width]
                if not re.fullmatch(rf"[0-9A-Fa-f]{{{width}}}", hexpart):
                    fail(f"frontmatter line {lineno}: bad \\{esc} escape in double-quoted scalar")
                out.append(chr(int(hexpart, 16)))
                i += 2 + width
                continue
            fail(f"frontmatter line {lineno}: unknown escape \\{esc} in double-quoted scalar")
        if ch == '"':
            return "".join(out), i + 1
        out.append(ch)
        i += 1
    fail(f"frontmatter line {lineno}: double-quoted scalar is not terminated")


def parse_single_quoted(raw, lineno):
    out = []
    i = 1
    n = len(raw)
    while i < n:
        ch = raw[i]
        if ch == "'":
            if i + 1 < n and raw[i + 1] == "'":
                out.append("'")
                i += 2
                continue
            return "".join(out), i + 1
        out.append(ch)
        i += 1
    fail(f"frontmatter line {lineno}: single-quoted scalar is not terminated")


def parse_block_scalar(indicator, fm, idx, lineno, key_indent):
    mode = indicator[0]
    chomp = "clip"
    explicit_indent = None
    saw_chomp = False
    saw_indent = False
    rest = indicator[1:]
    j = 0
    while j < len(rest):
        c = rest[j]
        if c == "-":
            if saw_chomp:
                fail(f"frontmatter line {lineno}: duplicate block chomp indicator")
            chomp = "strip"; j += 1
            saw_chomp = True
        elif c == "+":
            if saw_chomp:
                fail(f"frontmatter line {lineno}: duplicate block chomp indicator")
            chomp = "keep"; j += 1
            saw_chomp = True
        elif c.isdigit():
            if c == "0" or saw_indent:
                fail(f"frontmatter line {lineno}: invalid block indentation indicator")
            explicit_indent = int(c); j += 1
            saw_indent = True
        elif c in " \t":
            j += 1
        elif c == "#":
            break
        else:
            fail(f"frontmatter line {lineno}: bad block scalar indicator {indicator!r}")
    tail = rest[j:].strip()
    if tail and not tail.startswith("#"):
        fail(f"frontmatter line {lineno}: trailing content after block scalar indicator")
    block_lines = []
    k = idx + 1
    while k < len(fm):
        ln = fm[k]
        if ln.strip() == "":
            block_lines.append(ln); k += 1; continue
        indent = len(ln) - len(ln.lstrip(" "))
        if indent <= key_indent:
            break
        block_lines.append(ln); k += 1
    if not block_lines or all(b.strip() == "" for b in block_lines):
        fail(f"frontmatter line {lineno}: block scalar has no content")
    first_nonblank = next(b for b in block_lines if b.strip() != "")
    content_indent = explicit_indent if explicit_indent else (
        len(first_nonblank) - len(first_nonblank.lstrip(" ")))
    if content_indent <= key_indent:
        fail(f"frontmatter line {lineno}: block scalar indent not deeper than key")
    stripped = []
    for b in block_lines:
        if b.strip() == "":
            stripped.append("")
        else:
            if len(b) < content_indent:
                fail(f"frontmatter line {lineno}: block scalar line under-indented")
            stripped.append(b[content_indent:])
    if mode == "|":
        joined = "\n".join(stripped)
    else:
        out = []
        pending = []
        for s in stripped:
            if s == "":
                if pending:
                    out.append(" ".join(pending)); pending = []
                out.append("")
            else:
                pending.append(s)
        if pending:
            out.append(" ".join(pending))
        joined = "\n".join(out)
        joined = re.sub(r"\n{2,}", lambda m: "\n" * (len(m.group(0)) - 1), joined)
    if chomp == "strip":
        joined = joined.rstrip("\n")
    elif chomp == "clip":
        joined = joined.rstrip("\n") + "\n"
    return joined, k - idx


def parse_value(rest, fm, idx, lineno, key_indent):
    if rest == "" or rest.startswith("#"):
        return None, 1
    if rest[0] == '"':
        value, endpos = parse_double_quoted(rest, lineno)
        tail = rest[endpos:].strip()
        if tail and not tail.startswith("#"):
            fail(f"frontmatter line {lineno}: trailing content after double-quoted scalar")
        return value, 1
    if rest[0] == "'":
        value, endpos = parse_single_quoted(rest, lineno)
        tail = rest[endpos:].strip()
        if tail and not tail.startswith("#"):
            fail(f"frontmatter line {lineno}: trailing content after single-quoted scalar")
        return value, 1
    if rest[0] in "|>":
        return parse_block_scalar(rest, fm, idx, lineno, key_indent)
    if rest[0] in "[{":
        fail(f"frontmatter line {lineno}: flow {rest[0]} collections are not supported")
    plain = rest
    cmatch = re.search(r"[ \t]#", plain)
    if cmatch:
        plain = plain[:cmatch.start()]
    plain = plain.rstrip()
    if plain == "":
        return None, 1
    if re.search(r":[ \t]", plain) or plain.endswith(":"):
        fail(f"frontmatter line {lineno}: plain scalar contains a mapping indicator (: )")
    for opener, closer in (("[", "]"), ("{", "}")):
        if plain.count(opener) != plain.count(closer):
            fail(f"frontmatter line {lineno}: unmatched {opener}{closer} in plain scalar")
    return resolve_plain(plain), 1


raw = open(path, encoding="utf-8").read()
lines = raw.split("\n")
if lines and lines[-1] == "":
    lines = lines[:-1]
if not lines or lines[0] != "---":
    fail("SKILL.md does not open with frontmatter")
end = None
for i in range(1, len(lines)):
    if lines[i] == "---":
        end = i; break
if end is None:
    fail("frontmatter is not terminated")
fm = lines[1:end]
metadata = {}
i = 0
while i < len(fm):
    line = fm[i]
    lineno = i + 2
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        i += 1; continue
    indent = len(line) - len(line.lstrip(" "))
    if indent != 0:
        fail(f"frontmatter line {lineno}: unexpected indentation")
    m = _KEY_RE.match(line)
    if not m:
        fail(f"frontmatter line {lineno} is not a key:value mapping")
    key = m.group(1); rest = m.group(2)
    if key in metadata:
        fail(f"frontmatter duplicate key {key!r}")
    value, consumed = parse_value(rest, fm, i, lineno, indent)
    metadata[key] = value
    i += consumed

if not isinstance(metadata, dict):
    fail("frontmatter must be a YAML mapping")
for key in ("name", "description", "license", "version"):
    if key not in metadata:
        fail(f"frontmatter missing {key!r}")
    if not isinstance(metadata[key], str):
        fail(f"frontmatter {key!r} must be a string")
name = metadata["name"]
if name != skill_id:
    fail(f"frontmatter name {name!r} != dir name")
if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) or len(name) > 64:
    fail("frontmatter name must be a 1-64 character lowercase identifier")
if not 1 <= len(metadata["description"]) <= 1024:
    fail("frontmatter description must be 1-1024 characters")
if metadata["license"] != "MIT":
    fail("frontmatter license must declare repository license MIT")
if not re.fullmatch(r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)", metadata["version"]):
    fail("frontmatter version must use x.y.z semver")
print(metadata["version"])
PY
)"; then
    echo "[fail] $frontmatter_result"; return 1
  fi
  frontmatter_version="$frontmatter_result"
  if [ ! -f "$sj" ]; then
    echo "[fail] $id: skill.json missing"; return 1
  fi
  if ! python3 - "$sj" "$dir" "$id" "$frontmatter_version" <<'PY'
import json, os, sys
import re
sj, d, sid, frontmatter_version = sys.argv[1:]
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
assert isinstance(version, str) and re.fullmatch(
    r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)", version
), "version missing or invalid"
assert version == frontmatter_version, (
    f"skill.json version {version!r} != SKILL.md version {frontmatter_version!r}"
)
tl = m.get("trust_level")
assert tl in ("unreviewed", "workspace", "team", "public"), f"trust_level missing or invalid: {tl!r}"
PY
  then
    echo "[fail] $id: skill.json invalid"; return 1
  fi
  if command -v brigade >/dev/null 2>&1; then
    local brigade_output brigade_tmp
    if ! brigade_output="$(brigade skills lint "$dir" 2>&1)"; then
      if ! printf '%s\n' "$brigade_output" |
        grep -Fxq 'error: unknown frontmatter field: version'; then
        echo "[fail] $id: brigade skills lint failed"; return 1
      fi
      brigade_tmp="$(mktemp -d)"
      mkdir -p "$brigade_tmp/$id"
      cp -a "$dir"/. "$brigade_tmp/$id/"
      sed -i '/^version:/d' "$brigade_tmp/$id/SKILL.md"
      if ! brigade skills lint "$brigade_tmp/$id" >/dev/null 2>&1; then
        rm -rf "$brigade_tmp"
        echo "[fail] $id: brigade skills lint failed after removing unsupported version field"
        return 1
      fi
      rm -rf "$brigade_tmp"
    fi
  fi
  # Script-test contract: a skill that ships executable helper scripts under
  # scripts/ must prove them with deterministic unit tests (executable
  # tests/test-* files, plain shell, no model in the loop). The linter runs
  # them from the skill directory, so CI executes them on every push.
  local script_count=0
  if [ -d "$dir/scripts" ]; then
    script_count="$(find "$dir/scripts" -maxdepth 1 -type f -perm -u+x | wc -l | tr -d ' ')"
  fi
  if [ "$script_count" -gt 0 ]; then
    if [ ! -d "$dir/tests" ]; then
      echo "[fail] $id: scripts/ ships executable scripts but tests/ is missing"
      return 1
    fi
    local test_files=() test_file test_output
    while IFS= read -r test_file; do
      test_files+=("$test_file")
    done < <(find "$dir/tests" -maxdepth 1 -type f -name 'test-*' -perm -u+x | sort)
    if [ "${#test_files[@]}" -eq 0 ]; then
      echo "[fail] $id: tests/ has no executable test-* unit tests for its scripts"
      return 1
    fi
    for test_file in "${test_files[@]}"; do
      if ! test_output="$(cd "$dir" && bash "$test_file" 2>&1)"; then
        echo "[fail] $id: unit test ${test_file##*/} failed"
        printf '%s\n' "$test_output" | sed 's/^/    /'
        return 1
      fi
    done
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
  if [ -f "$dir/evals/evals.json" ]; then
    bash "$ROOT/tests/lint-evals.sh" "$id" || return 1
  fi
  echo "[ok] $id"
}

check_catalog() {
  local readme="$ROOT/README.md"
  local routing="$SKILLS_DIR/using-skillet/SKILL.md"
  local workflow="$ROOT/.github/workflows/lint-skills.yml"
  local count badge id catalog_error
  count="$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  badge="$(sed -n 's/.*badge\/skills-\([0-9][0-9]*\)-orange.*/\1/p' "$readme" | head -1)"
  if [ "$badge" != "$count" ]; then
    echo "[fail] catalog: README badge says ${badge:-missing}, found $count skills"
    return 1
  fi
  if ! catalog_error="$(python3 - "$SKILLS_DIR" "$readme" "$routing" 2>&1 <<'PY'
import pathlib
import re
import sys

skills_dir, readme_path, routing_path = map(pathlib.Path, sys.argv[1:])
local_ids = {path.name for path in skills_dir.iterdir() if path.is_dir()}
external_routing_ids = {"brigade-work"}

catalog_ids = set()
in_skill_table = False
for line in readme_path.read_text(encoding="utf-8").splitlines():
    if line == "| Skill | What it does |":
        in_skill_table = True; continue
    if in_skill_table and not line.startswith("|"):
        in_skill_table = False; continue
    if in_skill_table:
        if re.fullmatch(r"\|[-: ]+\|[-: ]+\|", line):
            continue
        match = re.fullmatch(r"\| \*\*([a-z0-9]+(?:-[a-z0-9]+)*)\*\* \|.*", line)
        if not match:
            print(f"README skill catalog contains an unparseable row: {line}")
            raise SystemExit(1)
        catalog_ids.add(match.group(1))

routing_ids = set()
in_routing_catalog = False
for line in routing_path.read_text(encoding="utf-8").splitlines():
    if line == "## The stations (skillet skills by job)":
        in_routing_catalog = True
        continue
    if in_routing_catalog and line == "## Skill priority":
        in_routing_catalog = False
        continue
    if in_routing_catalog and line.startswith("- "):
        match = re.fullmatch(r"- `([a-z0-9]+(?:-[a-z0-9]+)*)` - .+", line)
        if not match:
            print(f"using-skillet routing catalog contains an unparseable entry: {line}")
            raise SystemExit(1)
        routing_ids.add(match.group(1))

def render(ids):
    return ", ".join(sorted(ids))

missing_from_readme = local_ids - catalog_ids
unknown_in_readme = catalog_ids - local_ids
missing_from_routing = local_ids - routing_ids
unknown_in_routing = routing_ids - local_ids - external_routing_ids
if missing_from_readme:
    print(f"README missing: {render(missing_from_readme)}")
elif unknown_in_readme:
    print(f"README contains unknown skills: {render(unknown_in_readme)}")
elif missing_from_routing:
    print(f"using-skillet missing: {render(missing_from_routing)}")
elif unknown_in_routing:
    print(f"using-skillet contains unknown skills: {render(unknown_in_routing)}")
else:
    raise SystemExit(0)
raise SystemExit(1)
PY
)"; then
    echo "[fail] catalog: $catalog_error"
    return 1
  fi
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

check_workflow_skill_references() {
  local workflow_error
  if ! workflow_error="$(python3 - "$SKILLS_DIR" "$ROOT/README.md" 2>&1 <<'PY'
import pathlib
import re
import sys

skills_dir, readme_path = map(pathlib.Path, sys.argv[1:])
local_ids = {path.name for path in skills_dir.iterdir() if path.is_dir()}
workflow_rows = {"Audit", "Ship", "Execute", "Remember"}
seen_rows = set()

for line in readme_path.read_text(encoding="utf-8").splitlines():
    columns = [column.strip() for column in line.strip().strip("|").split("|")]
    if len(columns) != 3:
        continue
    row_name = columns[0].strip("* ")
    if row_name not in workflow_rows:
        continue
    seen_rows.add(row_name)
    for entry in columns[2].split(","):
        match = re.match(r"\s*([a-z0-9]+(?:-[a-z0-9]+)*)\b", entry)
        if not match:
            print(f"{row_name}: cannot parse workflow skill from {entry!r}")
            raise SystemExit(1)
        skill_id = match.group(1)
        if skill_id not in local_ids:
            print(f"{row_name}: workflow skill {skill_id!r} does not resolve to skillet/skills")
            raise SystemExit(1)

missing_rows = workflow_rows - seen_rows
if missing_rows:
    print(f"workflow rows missing: {', '.join(sorted(missing_rows))}")
    raise SystemExit(1)
PY
)"; then
    echo "[fail] workflow: $workflow_error"
    return 1
  fi
  echo "[ok] workflow skill references"
}

check_skill_boundaries() {
  local id section marker boundary_error

  for id in "${READ_ONLY_SKILLS[@]}"; do
    if ! boundary_error="$(python3 - "$SKILLS_DIR/$id/SKILL.md" "$FIX_APPLICATION_PATTERN" 2>&1 <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
if not re.search(r"\*\*Read-only", text):
    print("read-only boundary marker missing")
    raise SystemExit(1)
for match in re.finditer(sys.argv[2], text):
    prefix = text[max(0, match.start() - 40):match.start()]
    if re.search(r"(?i)\b(?:do not|never|must not|cannot|can't|without)\b[^.!?\n]*$", prefix):
        continue
    print("read-only skill contains fix-application language")
    raise SystemExit(1)
PY
)"; then
      echo "[fail] $id: $boundary_error"
      return 1
    fi
  done

  for marker in "${AUDIT_ONLY_SECTIONS[@]}"; do
    id="${marker%%:*}"
    section="${marker#*:}"
    if ! boundary_error="$(python3 - "$SKILLS_DIR/$id/SKILL.md" "$section" "$FIX_APPLICATION_PATTERN" 2>&1 <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
section = re.escape(sys.argv[2])
match = re.search(rf"(?ms)^## {section}\s*$\n(.*?)(?=^## |\Z)", text)
if not match:
    print(f"{sys.argv[2]} boundary marker missing")
    raise SystemExit(1)
audit_section = match.group(1)
for application in re.finditer(sys.argv[3], audit_section):
    prefix = audit_section[max(0, application.start() - 40):application.start()]
    if re.search(r"(?i)\b(?:do not|never|must not|cannot|can't|without)\b[^.!?\n]*$", prefix):
        continue
    print(f"{sys.argv[2]} section contains fix-application language")
    raise SystemExit(1)
PY
)"; then
      echo "[fail] $id: $boundary_error"
      return 1
    fi
  done
  echo "[ok] skill boundaries"
}

check_untrusted_content_contract() {
  local id boundary_error

  for id in "${EXTERNAL_CONTENT_SKILLS[@]}"; do
    if ! boundary_error="$(python3 - "$SKILLS_DIR/$id/SKILL.md" 2>&1 <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r"(?ms)^## Untrusted content\s*$\n(.*?)(?=^## |\Z)", text)
if not match:
    print("Untrusted content section missing")
    raise SystemExit(1)
section = match.group(1)
checks = [
    (r"(?i)\bas data\b", "missing 'as data' bullet"),
    (r"(?i)\bnot instructions\b", "missing 'not instructions' bullet"),
    (r"(?i)\bquote\b", "missing quote guidance"),
    (r"(?i)\bdo not execute\b|\bdon't execute\b", "missing do-not-execute guidance"),
    (r"(?i)\bescalat", "missing escalation path"),
]
for pattern, message in checks:
    if not re.search(pattern, section):
        print(message)
        raise SystemExit(1)
PY
)"; then
      echo "[fail] $id: $boundary_error"
      return 1
    fi
  done
  echo "[ok] untrusted content contract"
}

# fleet-conductor must keep three check classes distinct: required, optional
# repository-owned, and optional external. Collapsing "not required" into
# "optional-external" mislabels repository CI and weakens the landing contract.
check_fleet_conductor_checks_contract() {
  local md="$SKILLS_DIR/fleet-conductor/SKILL.md"
  local contract_error
  if [ ! -f "$md" ]; then
    echo "[fail] fleet-conductor: SKILL.md missing for checks contract"
    return 1
  fi
  if ! contract_error="$(python3 - "$md" 2>&1 <<'PY'
import re
import sys

text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r"(?ms)^## Checks\s*$\n(.*?)(?=^## |\Z)", text)
if not match:
    print("Checks section missing")
    raise SystemExit(1)
section = match.group(1)
if re.search(r"(?i)anything not required is optional-external", section):
    print("collapses non-required checks into optional-external")
    raise SystemExit(1)
if re.search(r"(?i)optional-external for this land", section):
    print("labels non-required checks as optional-external for this land")
    raise SystemExit(1)
required = [
    (r"(?i)branch protection|ruleset", "missing required-check discovery from branch protection/rulesets"),
    (r"(?i)gh pr checks.*--required|--required", "missing gh pr checks --required for required class"),
    (r"(?i)empty.*--required|`--required`.*observation|observation.*(?:not|never).*(?:green|pass)", "missing empty --required observation-not-pass rule"),
    (r"(?i)repository-owned|first-party", "missing repository-owned / first-party check class"),
    (r"(?i)first-party evidence", "missing first-party evidence wording for repository-owned checks"),
    (r"(?i)never call them (?:optional-)?external|do not call them (?:optional-)?external|not call them (?:optional-)?external|never (?:call|label).*(?:optional-)?external", "missing ban on calling repository-owned checks external"),
    (r"(?i)explicit operator decision", "missing explicit operator decision for repository-owned waivers"),
    (r"(?i)failing.*pending.*missing.*skipped|pending.*missing.*skipped", "missing failing/pending/missing/skipped waiver coverage"),
    (r"(?i)optional external|third-party", "missing optional external third-party check class"),
    (r"(?i)unavailable|pending|skipped", "missing naming of unavailable/pending/skipped external results"),
    (r"(?i)operator.*(?:care|cares|cared).*hold|stuck.*hold|stays a hold", "missing operator-cared stuck-check hold"),
]
for pattern, message in required:
    if not re.search(pattern, section):
        print(message)
        raise SystemExit(1)
# Landing table must not collapse repository-owned vs external checks.
landing = re.search(r"(?ms)^### Landing\s*$\n(.*?)(?=^### |\Z)", text)
if not landing:
    print("Landing output table missing")
    raise SystemExit(1)
table = landing.group(1)
if re.search(r"(?i)Optional checks noted", table) and not re.search(
    r"(?i)Repository-owned|Optional external", table
):
    print("Landing table collapses optional checks into one column")
    raise SystemExit(1)
if not re.search(r"(?i)Repository-owned", table):
    print("Landing table missing repository-owned column")
    raise SystemExit(1)
if not re.search(r"(?i)Optional external", table):
    print("Landing table missing optional external column")
    raise SystemExit(1)
PY
)"; then
    echo "[fail] fleet-conductor checks contract: $contract_error"
    return 1
  fi
  echo "[ok] fleet-conductor checks contract"
}

check_brigade_verify_commands() {
  local command_error
  if ! command_error="$(python3 - "$SKILLS_DIR" 2>&1 <<'PY'
import pathlib
import shlex
import sys

for path in sorted(pathlib.Path(sys.argv[1]).glob("*/SKILL.md")):
    in_fence = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence or "brigade work verify run" not in line:
            continue
        command = line.removeprefix("$ ").strip()
        try:
            tokens = shlex.split(command)
        except ValueError as error:
            print(f"{path.parent.name}: invalid Brigade verify command: {error}")
            raise SystemExit(1)
        if tokens[:4] != ["brigade", "work", "verify", "run"]:
            print(f"{path.parent.name}: invalid Brigade verify command form")
            raise SystemExit(1)
        try:
            capture_index = tokens.index("--capture")
        except ValueError:
            capture_index = -1
        if capture_index < 0 or capture_index + 1 >= len(tokens) or tokens[capture_index + 1].startswith("-"):
            print(f"{path.parent.name}: Brigade verify command must include atomic --capture")
            raise SystemExit(1)
PY
)"; then
    echo "[fail] command form: $command_error"
    return 1
  fi
  echo "[ok] Brigade verify command forms"
}

check_linter_regressions() {
  local tmp valid invalid fixture description_1024 description_1025 regression_failures=0
  tmp="$(mktemp -d)"
  valid="$tmp/skillet/skills/valid-length"
  invalid="$tmp/skillet/skills/invalid-length"
  mkdir -p "$tmp/tests" "$valid" "$invalid"
  cp "$0" "$tmp/tests/lint-skills.sh"

  description_1024="$(python3 -c 'print("x" * 1024, end="")')"
  description_1025="${description_1024}x"
  printf '%s\n' '---' 'name: valid-length' 'version: 0.1.0' "description: \"$description_1024\"" 'license: MIT' '---' >"$valid/SKILL.md"
  printf '%s\n' '---' 'name: invalid-length' 'version: 0.1.0' "description: $description_1025" 'license: MIT' '---' >"$invalid/SKILL.md"
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
  printf '%s\n' '---' 'name: valid-length' 'version: 0.1.0' "description: 'single ''quoted'' scalar'" 'license: MIT' '---' >"$valid/SKILL.md"
  PATH=/usr/bin:/bin bash "$tmp/tests/lint-skills.sh" valid-length >/dev/null 2>&1 || {
    echo "[fail] self-test: single-quoted YAML scalar was rejected"; rm -rf "$tmp"; return 1
  }
  printf '%s\n' '---' 'name: valid-length' 'version: 0.1.0' 'description: "double \x41 \U00000042 scalar"' 'license: MIT' '---' >"$valid/SKILL.md"
  PATH=/usr/bin:/bin bash "$tmp/tests/lint-skills.sh" valid-length >/dev/null 2>&1 || {
    echo "[fail] self-test: double-quoted YAML escapes were rejected"; rm -rf "$tmp"; return 1
  }
  printf '%s\n' '---' 'name: valid-length' 'version: 0.1.0' 'description: |-' '  literal' '  scalar' 'license: MIT' '---' >"$valid/SKILL.md"
  PATH=/usr/bin:/bin bash "$tmp/tests/lint-skills.sh" valid-length >/dev/null 2>&1 || {
    echo "[fail] self-test: literal YAML scalar was rejected"; rm -rf "$tmp"; return 1
  }
  printf '%s\n' '---' 'name: valid-length' 'version: 0.1.0' 'description: >-' '  folded' '  scalar' 'license: MIT' '---' >"$valid/SKILL.md"
  PATH=/usr/bin:/bin bash "$tmp/tests/lint-skills.sh" valid-length >/dev/null 2>&1 || {
    echo "[fail] self-test: folded YAML scalar was rejected"; rm -rf "$tmp"; return 1
  }

  assert_fixture_rejected() {
    local label="$1" fixture="$2" skill="${3:-}" expected="${4:-}" output
    local args=()
    if [ -n "$skill" ]; then
      args=("$skill")
    fi
    if output="$(LINT_SKILLS_SKIP_SELF_TESTS=1 PATH=/usr/bin:/bin bash "$fixture/tests/lint-skills.sh" "${args[@]}" 2>&1)"; then
      echo "[fail] self-test: $label violation was accepted"
      regression_failures=1
    elif [ -n "$expected" ] && ! printf '%s\n' "$output" | grep -Fq "$expected"; then
      echo "[fail] self-test: $label diagnostic did not name $expected"
      regression_failures=1
    fi
  }

  fixture="$tmp/yaml-malformed"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/^description:/a malformed: [unterminated' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "malformed YAML frontmatter" "$fixture" line-check "skillet/skills/line-check/SKILL.md"

  fixture="$tmp/yaml-folded-overlength"
  cp -a "$ROOT"/. "$fixture"
  sed -i 's/^description:.*/description: >-/' "$fixture/skillet/skills/line-check/SKILL.md"
  sed -i "/^description: >-$/a\\  $description_1025" "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "overlong folded YAML description" "$fixture" line-check

  fixture="$tmp/yaml-implicit-number"
  cp -a "$ROOT"/. "$fixture"
  sed -i 's/^description:.*/description: 0x10/' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "implicit numeric YAML description" "$fixture" line-check

  fixture="$tmp/yaml-invalid-block"
  cp -a "$ROOT"/. "$fixture"
  sed -i 's/^description:.*/description: |--/' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "invalid YAML block indicator" "$fixture" line-check

  fixture="$tmp/readme-catalog-phantom"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/| \*\*memory-handoff\*\* |/a | **phantom-skill** | Deliberate fixture for reverse catalog validation. |' "$fixture/README.md"
  assert_fixture_rejected "phantom README catalog entry" "$fixture"

  fixture="$tmp/routing-catalog-phantom"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/- `memory-handoff`/a - `phantom-skill` - deliberate fixture for reverse catalog validation.' "$fixture/skillet/skills/using-skillet/SKILL.md"
  assert_fixture_rejected "phantom routing catalog entry" "$fixture"

  fixture="$tmp/readme-catalog-malformed"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/| \*\*memory-handoff\*\* |/a | **Phantom Skill** | Deliberate malformed catalog row. |' "$fixture/README.md"
  assert_fixture_rejected "malformed README catalog row" "$fixture"

  fixture="$tmp/untrusted-content-missing"
  cp -a "$ROOT"/. "$fixture"
  python3 - "$fixture/skillet/skills/grill/SKILL.md" <<'PY'
from pathlib import Path
import re
import sys
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text, n = re.subn(
    r"(?ms)^## Untrusted content\s*$\n.*?(?=^## |\Z)",
    "",
    text,
    count=1,
)
assert n == 1, "expected Untrusted content section to strip"
path.write_text(text, encoding="utf-8")
PY
  assert_fixture_rejected "missing untrusted content section" "$fixture" "" "Untrusted content section missing"

  fixture="$tmp/read-only-application"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/\*\*Read-only\.\*\* Never modify the repo during an audit\./a Apply each finding\047s fix directly before reporting it.' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "read-only fix-application language" "$fixture"

  fixture="$tmp/read-only-application-evasion"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/\*\*Read-only\.\*\* Never modify the repo during an audit\./a Make the fixes directly, edit files to correct findings, and apply patches.' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "read-only mutation vocabulary" "$fixture"

  fixture="$tmp/audit-only-application"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/^## AUDIT$/a Apply fixes directly while auditing.' "$fixture/skillet/skills/garnish/SKILL.md"
  assert_fixture_rejected "audit-only fix-application language" "$fixture"

  fixture="$tmp/verify-without-capture"
  cp -a "$ROOT"/. "$fixture"
  sed -i 's/brigade work verify run --target \. --command "<proving command>" --capture <skill-or-card-id>/brigade work verify run --target . --command "<proving command>"/' "$fixture/skillet/skills/check/SKILL.md"
  assert_fixture_rejected "Brigade verify command without atomic capture" "$fixture"

  fixture="$tmp/workflow-phantom"
  cp -a "$ROOT"/. "$fixture"
  sed -i 's/recipe, taste, stocktake, thermometer, reduce/recipe, taste, stocktake, thermometer, reduce, ghost-workflow-skill/' "$fixture/README.md"
  assert_fixture_rejected "unresolved workflow skill ID" "$fixture"

  fixture="$tmp/version-missing"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/^version:/d' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "missing frontmatter version" "$fixture" line-check

  fixture="$tmp/version-invalid"
  cp -a "$ROOT"/. "$fixture"
  sed -i '/^name: line-check$/a version: v1.0' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "invalid frontmatter semver" "$fixture" line-check

  fixture="$tmp/version-mismatch"
  cp -a "$ROOT"/. "$fixture"
  sed -i 's/^version: 0.1.0$/version: 0.2.0/' "$fixture/skillet/skills/line-check/SKILL.md"
  assert_fixture_rejected "frontmatter and skill.json version mismatch" "$fixture" line-check

  fixture="$tmp/script-tests-missing"
  cp -a "$ROOT"/. "$fixture"
  rm -rf "$fixture/skillet/skills/grill/tests"
  assert_fixture_rejected "script package without tests/ directory" "$fixture" grill "tests/ is missing"

  fixture="$tmp/script-tests-empty"
  cp -a "$ROOT"/. "$fixture"
  rm "$fixture/skillet/skills/grill/tests"/test-*
  printf 'not a test file\n' >"$fixture/skillet/skills/grill/tests/README.md"
  assert_fixture_rejected "script package without executable test-* files" "$fixture" grill "no executable test-* unit tests"

  fixture="$tmp/script-tests-failing"
  cp -a "$ROOT"/. "$fixture"
  printf '%s\n' '#!/usr/bin/env bash' 'echo deliberate failure; exit 1' \
    >"$fixture/skillet/skills/grill/tests/test-deliberate-failure.sh"
  chmod +x "$fixture/skillet/skills/grill/tests/test-deliberate-failure.sh"
  assert_fixture_rejected "failing script unit test" "$fixture" grill "unit test test-deliberate-failure.sh failed"

  fixture="$tmp/brigade-unrelated-failure"
  cp -a "$ROOT"/. "$fixture"
  mkdir -p "$fixture/bin"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'target="${!#}"' \
    'if grep -q "^version:" "$target/SKILL.md"; then' \
    '  echo "error: unknown frontmatter field: version"' \
    'fi' \
    'echo "fatal: validator crashed"' \
    'exit 1' >"$fixture/bin/brigade"
  chmod +x "$fixture/bin/brigade"
  if LINT_SKILLS_SKIP_SELF_TESTS=1 PATH="$fixture/bin:/usr/bin:/bin" \
    bash "$fixture/tests/lint-skills.sh" line-check >/dev/null 2>&1; then
    echo "[fail] self-test: unrelated Brigade validator failure was masked"
    regression_failures=1
  fi

  fixture="$tmp/fleet-conductor-collapse-external"
  cp -a "$ROOT"/. "$fixture"
  python3 - "$fixture/skillet/skills/fleet-conductor/SKILL.md" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old = (
    "Compare the full list to the required list: anything not required "
    "is optional-external for this land."
)
# Force the collapse wording even after the live skill is repaired.
needle = "## Checks\n"
if needle not in text:
    raise SystemExit("Checks section missing in fixture source")
# Replace the entire Checks section body with a deliberately collapsed one.
import re
collapsed = """## Checks

Distinguish repository-required checks from optional external checks.

- Discover required checks from `gh pr checks <n> --required`. Those must pass.
- Compare the full list to the required list: anything not required is optional-external for this land.
- Optional external checks may be slow; ignore them when stuck.

"""
text, n = re.subn(
    r"(?ms)^## Checks\s*$\n.*?(?=^## |\Z)",
    collapsed,
    text,
    count=1,
)
assert n == 1, "expected Checks section to replace"
path.write_text(text, encoding="utf-8")
PY
  assert_fixture_rejected \
    "fleet-conductor non-required collapse into optional-external" \
    "$fixture" \
    "" \
    "collapses non-required checks into optional-external"

  fixture="$tmp/fleet-conductor-collapse-landing-table"
  cp -a "$ROOT"/. "$fixture"
  python3 - "$fixture/skillet/skills/fleet-conductor/SKILL.md" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
checks_before = re.search(r"(?ms)^## Checks\s*$\n.*?(?=^## |\Z)", text)
assert checks_before, "Checks section missing in fixture source"
header = "| PR | Draft? | Gates 1-8 | Required checks | Repository-owned (not required) | Optional external | Ready? |"
divider = "|----|--------|-----------|-----------------|---------------------------------|-------------------|--------|"
assert text.count(header) == 1, "expected Landing table header to replace"
assert text.count(divider) == 1, "expected Landing table divider to replace"
text = text.replace(
    header,
    "| PR | Draft? | Gates 1-8 | Required checks | Optional checks noted | Ready? |",
)
text = text.replace(
    divider,
    "|----|--------|-----------|-----------------|----------------------|--------|",
)
checks_after = re.search(r"(?ms)^## Checks\s*$\n.*?(?=^## |\Z)", text)
assert checks_after and checks_after.group(0) == checks_before.group(0), (
    "Landing-only fixture changed the Checks section"
)
path.write_text(text, encoding="utf-8")
PY
  assert_fixture_rejected \
    "fleet-conductor Landing table check-class collapse" \
    "$fixture" \
    "" \
    "Landing table collapses optional checks into one column"

  rm -rf "$tmp"
  if [ "$regression_failures" -ne 0 ]; then
    return 1
  fi
  echo "[ok] linter regression boundaries"
}

if [ "${1:-}" = "--fleet-conductor-checks-contract" ]; then
  check_fleet_conductor_checks_contract || FAIL=1
elif [ "$#" -ge 1 ]; then
  check_skill "$SKILLS_DIR/$1" || FAIL=1
else
  if [ "${LINT_SKILLS_SKIP_SELF_TESTS:-0}" != "1" ]; then
    check_linter_regressions || FAIL=1
  fi
  for d in "$SKILLS_DIR"/*/; do
    check_skill "$d" || FAIL=1
  done
  check_catalog || FAIL=1
  check_workflow_skill_references || FAIL=1
  check_skill_boundaries || FAIL=1
  check_untrusted_content_contract || FAIL=1
  check_fleet_conductor_checks_contract || FAIL=1
  check_brigade_verify_commands || FAIL=1
  LINT_EVALS_SKIP_SELF_TESTS="${LINT_SKILLS_SKIP_SELF_TESTS:-0}" \
    bash "$ROOT/tests/lint-evals.sh" || FAIL=1
fi
exit $FAIL
