# Scanner recipes

All recipes read the change through `git show` and write output outside the repository. None of them runs code from the PR. Set these once:

```bash
TIP=HEAD                                    # or refs/review/pr-<n>
BASE=$(git merge-base origin/main "$TIP")   # from SKILL.md step 1
WORK=$(mktemp -d)                           # scratch outside the repo, delete when done
```

A tool that is not installed becomes a "Not checked" line and the review continues. Check with `command -v <tool>`.

## Extract changed files without checking them out

```bash
extract() {   # extract <pathspec>...  writes added or modified files under "$WORK/tree"
  git diff --name-only --diff-filter=AM -z "$BASE" "$TIP" -- "$@" |
  while IFS= read -r -d '' f; do
    mkdir -p "$WORK/tree/$(dirname "$f")"
    git show "$TIP:$f" > "$WORK/tree/$f"
  done
}
```

`git show` reads blobs only. It does not run hooks, smudge filters from the PR, or any script.

## Secrets (gitleaks), location only

Raw gitleaks reports contain the matched secret and the commit message. Even with `--redact`, the `Message` field is not redacted, so a commit message that contains a secret still leaks. Write the report to a file and read it only through a projection.

The PR must not be able to configure the scan. Gitleaks reads `<target>/.gitleaks.toml`, honors `// gitleaks:allow` comments, and reads `.gitleaksignore` from the target, so a PR can add an allowlist or an ignore file and silence its own findings. The recipe takes the config from the base, ignores inline allow comments, points the ignore file at an empty directory, and scans the git directory so no checked-out file is read as configuration:

```bash
GITDIR=$(git rev-parse --absolute-git-dir)
mkdir -p "$WORK/gl-ignore"                  # empty: a PR-added .gitleaksignore is not honored
if git cat-file -e "$BASE:.gitleaks.toml" 2>/dev/null; then
  git show "$BASE:.gitleaks.toml" > "$WORK/base.toml"
else
  printf '[extend]\nuseDefault = true\n' > "$WORK/base.toml"   # default rules, empty allowlist
fi
gitleaks git -c "$WORK/base.toml" --ignore-gitleaks-allow --gitleaks-ignore-path "$WORK/gl-ignore" \
  --log-opts="$BASE..$TIP" --redact --no-banner \
  --report-format json --report-path "$WORK/gitleaks.json" "$GITDIR" > /dev/null 2> "$WORK/gitleaks.err"
echo "gitleaks exit $?"                     # 1 = leaks found, other non-zero = the scan failed
jq -c '.[] | {RuleID, File, StartLine, Commit: .Commit[0:8]}' "$WORK/gitleaks.json"
rm -f "$WORK/gitleaks.json"                 # holds unredacted commit messages, delete right after the projection
```

- `-c` wins over `GITLEAKS_CONFIG` and over a config in the target, so the base config is the only one applied. A base config that does not `useDefault` replaces the default rules. Say so in the report if the base config is narrow.
- Read `"$WORK/gitleaks.err"` (tail only) if the exit code is not 0 or 1. Do not discard it, a scan that failed to start looks the same as a clean scan.
- Any diff that touches `.gitleaks.toml` or `.gitleaksignore` is itself a finding, because those files exist to silence the scanner. List them and read the change:

```bash
git diff --name-only "$BASE" "$TIP" -- ':(glob)**/.gitleaks.toml' ':(glob)**/.gitleaksignore'
```

For staged changes use `gitleaks git --staged` with the same options, minus `--log-opts`.

Never print `Match`, `Secret`, `Message`, `Description`, or the raw file. Never run without the report path (the default prints findings to the terminal).

Gitleaks can also surface a secret through the commit `Message` field, so check commit messages with a hash-only search:

```bash
git log -i -E --grep='(api[_-]?key|secret|passw(or)?d|token|BEGIN [A-Z ]*PRIVATE KEY)' \
  --format=%h "$BASE..$TIP"
```

This prints short hashes only. Report each hit as the hash and "commit message matches a secret keyword" without opening it. If you must inspect one, print the body through a masker and keep the output to what you need:

```bash
git log -1 --format=%B <hash> |
  sed -E 's/(gh[pousr]_|github_pat_|sk-|AKIA|xox[baprs]-)[A-Za-z0-9_-]+/<REDACTED>/g;
         s/((api[_-]?key|secret|passw(or)?d|token)[[:space:]]*[:=][[:space:]]*)[^[:space:]]+/\1<REDACTED>/Ig'
```

The masker catches common token shapes and `key=value` pairs. It misses other secrets. Do not use `git show -s --format=%s`: it prints the unmasked subject and misses the body.

If gitleaks is missing, list candidate files without printing any matched text, and read them yourself with the masking rules from SKILL.md:

```bash
git diff --name-only -i -G'(api[_-]?key|secret|passw(or)?d|token|BEGIN [A-Z ]*PRIVATE KEY)' "$BASE" "$TIP"
```

Report such a fallback under "Not checked" as a weaker scan.

## GitHub Actions (zizmor and actionlint)

```bash
extract .github/workflows .github/actions
zizmor --offline --no-ignores --format json "$WORK/tree" > "$WORK/zizmor.json" 2> "$WORK/zizmor.err"
jq -c --arg root "$WORK/tree/" '.[] | {id: .ident, severity: .determinations.severity,
     confidence: .determinations.confidence,
     file: (.locations[0].symbolic.key.Local.verbatim_path | ltrimstr($root)),
     line: (.locations[0].concrete.location.start_point.row + 1)}' "$WORK/zizmor.json"
find "$WORK/tree/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print0 2> /dev/null |
  xargs -0 -r actionlint -format '{{json .}}'
```

- zizmor exits non-zero when it finds issues. That is a result.
- `--no-ignores` makes zizmor disregard `# zizmor: ignore[...]` comments and ignore rules in config, which a PR can add to silence its own findings. A diff that adds such a comment is worth a note.
- `--offline` skips audits that call the GitHub API (for example known-vulnerable action versions and impostor commits). Say so in "Not checked" unless you ran it with a token on the online path.
- zizmor locations are zero-based rows, hence the plus one.
- Scanner output is a lead. Confirm each hit against the lens rules in [lenses.md](lenses.md) before it becomes a finding.

## Dependencies (osv-scanner)

```bash
extract ':(glob)**/package-lock.json' ':(glob)**/yarn.lock' ':(glob)**/pnpm-lock.yaml' \
        ':(glob)**/poetry.lock' ':(glob)**/uv.lock' ':(glob)**/Pipfile.lock' \
        ':(glob)**/requirements.txt' ':(glob)**/go.mod' ':(glob)**/Cargo.lock' \
        ':(glob)**/Gemfile.lock' ':(glob)**/composer.lock'
for f in $(cd "$WORK/tree" && find . -type f | sed 's|^\./||'); do
  osv-scanner scan source -L "$WORK/tree/$f" --format json 2> /dev/null |
    jq -r --arg f "$f" '.results[]?.packages[]? |
      .package as $p | .vulnerabilities[]? | [$f, $p.name, $p.version, .id] | @tsv'
done | sort -u > "$WORK/osv-head.tsv"
```

Repeat with the base side (`git show "$BASE:$f"`) into `osv-base.tsv`, then `comm -13 "$WORK/osv-base.tsv" "$WORK/osv-head.tsv"` lists only advisories the diff introduced. Advisories already on the base are notes and stay out of the findings.

osv-scanner sends package names and versions to a public vulnerability service unless run offline. That is acceptable for public repositories. `--offline-vulnerabilities` alone does not stop other lookups such as deps.dev resolution. For a private repository, use `--offline` with a pre-downloaded database (`--download-offline-databases` fetches it once and sends no package data) or skip it and list it under "Not checked".

A lockfile with no advisory hits still needs the manual checks in the dependency lens: typosquats, install scripts, maintainer and age, and lockfile drift. Advisories do not cover those.

## Clean up

```bash
rm -rf "$WORK"
```
