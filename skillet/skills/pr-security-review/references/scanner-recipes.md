# Scanner recipes

All recipes read the change through `git show` and write output outside the repository. None of them runs code from the PR. Set these once:

```bash
BASE=$(git merge-base origin/main HEAD)     # from SKILL.md step 1
TIP=HEAD                                    # or refs/review/pr-<n>
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

```bash
gitleaks git --log-opts="$BASE..$TIP" --redact --no-banner \
  --report-format json --report-path "$WORK/gitleaks.json" . > /dev/null 2>&1
jq -c '.[] | {RuleID, File, StartLine, Commit: .Commit[0:8]}' "$WORK/gitleaks.json"
```

Exit code 1 means leaks were found. For staged changes use `gitleaks git --staged` with the same report options.

Never print `Match`, `Secret`, `Message`, `Description`, or the raw file. Never run without the report path (the default prints findings to the terminal).

Gitleaks can also surface a secret through the commit `Message` field, so check commit messages with a hash-only search:

```bash
git log -i -E --grep='(api[_-]?key|secret|passw(or)?d|token|BEGIN [A-Z ]*PRIVATE KEY)' \
  --format=%h "$BASE..$TIP"
```

This prints short hashes only. Open a hit with `git show -s --format=%s <hash>` just long enough to judge it, and report the hash and secret type and leave out the text.

If gitleaks is missing, list candidate files without printing any matched text, and read them yourself with the masking rules from SKILL.md:

```bash
git diff --name-only -i -G'(api[_-]?key|secret|passw(or)?d|token|BEGIN [A-Z ]*PRIVATE KEY)' "$BASE" "$TIP"
```

Report such a fallback under "Not checked" as a weaker scan.

## GitHub Actions (zizmor and actionlint)

```bash
extract .github/workflows .github/actions
zizmor --offline --format json "$WORK/tree" > "$WORK/zizmor.json" 2> "$WORK/zizmor.err"
jq -c '.[] | {id: .ident, severity: .determinations.severity,
     confidence: .determinations.confidence,
     line: (.locations[0].concrete.location.start_point.row + 1)}' "$WORK/zizmor.json"
actionlint -format '{{json .}}' "$WORK"/tree/.github/workflows/*.yml
```

- zizmor exits non-zero when it finds issues. That is a result.
- `--offline` skips audits that call the GitHub API (for example known-vulnerable action versions and impostor commits). Say so in "Not checked" unless you ran it with a token on the online path.
- zizmor locations are zero-based rows, hence the plus one.
- Scanner output is a lead. Confirm each hit against the lens rules in [lenses.md](lenses.md) before it becomes a finding.

## Dependencies (osv-scanner)

```bash
extract package-lock.json yarn.lock pnpm-lock.yaml poetry.lock uv.lock Pipfile.lock \
        requirements.txt go.mod Cargo.lock Gemfile.lock composer.lock
for f in $(cd "$WORK/tree" && find . -type f | sed 's|^\./||'); do
  osv-scanner scan source -L "$WORK/tree/$f" --format json 2> /dev/null |
    jq -r --arg f "$f" '.results[]?.packages[]? |
      .package as $p | .vulnerabilities[]? | [$f, $p.name, $p.version, .id] | @tsv'
done | sort -u > "$WORK/osv-head.tsv"
```

Repeat with the base side (`git show "$BASE:$f"`) into `osv-base.tsv`, then `comm -13 "$WORK/osv-base.tsv" "$WORK/osv-head.tsv"` lists only advisories the diff introduced. Advisories already on the base are notes and stay out of the findings.

osv-scanner sends package names and versions to a public vulnerability service unless run offline. That is acceptable for public repositories. For a private repository, use `--offline-vulnerabilities` with a downloaded database or skip it and list it under "Not checked".

A lockfile with no advisory hits still needs the manual checks in the dependency lens: typosquats, install scripts, maintainer and age, and lockfile drift. Advisories do not cover those.

## Clean up

```bash
rm -rf "$WORK"
```
