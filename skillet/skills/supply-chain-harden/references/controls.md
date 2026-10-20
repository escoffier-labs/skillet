# Control recipes

Detail for each control in SKILL.md section 3. Snippets use placeholders in angle brackets. Never paste a placeholder into a real file. Resolve it first.

## 1. Pin actions to commit SHAs

Find every external reference:

```bash
grep -rnE '^\s*-?\s*uses:' .github/workflows .github/actions 2>/dev/null | grep -v 'uses: \./'
```

Local `./` paths need no pin. A `docker://` reference pins by `@sha256:` digest instead.

Resolve one reference:

```bash
gh api repos/<owner>/<repo>/commits/<tag> --jq .sha
```

This returns the commit even when the tag is annotated. The `git/ref/tags/<tag>` endpoint returns a tag object SHA for annotated tags, and that SHA is the wrong value to pin. Check the tag exists upstream first. A 404 means stop and report.

If the file used a floating tag such as `v4`, find the exact release tag on the same commit so the comment can be precise:

```bash
gh api repos/<owner>/<repo>/tags --paginate --jq '.[] | select(.commit.sha == "<sha>") | .name'
```

Write the result as:

```yaml
- uses: <owner>/<repo>@<40-char-sha> # v1.2.3
```

Reusable workflows are pinned the same way: `<owner>/<repo>/.github/workflows/<file>.yml@<sha> # v1.2.3`. A branch ref like `@main` or `@master` is the worst case and goes first.

If `pinact` or `ratchet` is installed, either can do the rewrite. Review the diff, since they resolve through the same API. Otherwise script the loop with `gh api`. Zizmor's `unpinned-uses` and `ref-version-mismatch` audits confirm the result, and the online `impostor-commit` audit checks the SHA belongs to the upstream repo and not a fork.

## 2. Token permissions

Top level, once per workflow:

```yaml
permissions:
  contents: read
```

Then grant per job only what its steps do:

| Step does | Job needs |
|-----------|-----------|
| Comment on or label a PR or issue | `pull-requests: write` or `issues: write` |
| Create a release or push a tag | `contents: write` |
| Push to GHCR | `packages: write` |
| Request an OIDC token (trusted publishing, cloud auth) | `id-token: write` |
| Upload SARIF to code scanning | `security-events: write` |

A job-level `permissions:` block replaces the top level for that job, so list `contents: read` there too if the job checks out code. Never use `write-all`. Zizmor's `excessive-permissions` and `undocumented-permissions` audits flag the gaps. The first CI run after the change is the real test. A missing grant fails with `Resource not accessible by integration`.

## 3. Workflow injection and risky triggers

Script injection: an expression inside `run:` is pasted into the shell before it runs.

```yaml
# before
- run: echo "${{ github.event.pull_request.title }}"
# after
- run: echo "$PR_TITLE"
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
```

Attacker-controlled fields include PR and issue titles and bodies, branch names, commit messages, and review comments. Apply the same move to `actions/github-script` `script:` blocks. Zizmor's `template-injection` audit finds them.

Flag these in the report. Fix only when the fix is mechanical and does not change what the workflow does:

- `pull_request_target` or `workflow_run` together with a checkout of the PR head ref or SHA. This runs untrusted code with a privileged token. The safe split is an unprivileged `pull_request` job that builds and a separate privileged job that consumes only declared artifacts.
- A self-hosted runner on a public repository's PR triggers.
- `actions/checkout` with default `persist-credentials` in a job that later runs untrusted steps. Set `persist-credentials: false` unless the job pushes.
- `ACTIONS_ALLOW_UNSECURE_COMMANDS`, writes to `GITHUB_ENV` or `GITHUB_PATH` from untrusted input.

## 4. Updater

Skip if a Renovate config exists. Say so in the report and check that it covers `github-actions`.

```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    cooldown:
      default-days: 7
    groups:
      actions:
        patterns: ["*"]
  - package-ecosystem: npm          # one block per ecosystem found in preflight
    directory: /
    schedule:
      interval: weekly
    cooldown:
      default-days: 7
    groups:
      minor-and-patch:
        update-types: ["minor", "patch"]
```

Add a `docker` block per Dockerfile directory when control 7 applies, since Dependabot refreshes digest pins. Groups prevent a PR flood on the first run. Cooldown delays brand-new releases, which gives the community time to catch a compromised one. Zizmor's `dependabot-cooldown` audit checks for it. Confirm key names against current Dependabot docs, since options change.

## 5. CI scanners

Add one workflow, for example `.github/workflows/security.yml`, triggered on `pull_request` and `push` to the default branch, with `permissions: contents: read`. Pin every `uses:` to a SHA like any other action. Pin tool versions and verify download checksums.

- **zizmor**: install a pinned version (for example `pipx run zizmor==<version> .github/workflows`) or use its maintained action pinned by SHA. Online audits need `GH_TOKEN` or `GITHUB_TOKEN` in `env:`. Plain output needs only `contents: read`. SARIF upload to code scanning also needs `security-events: write`, which you add to that job alone.
- **gitleaks**: scan with a pinned release binary and its published checksum. Check the licensing terms of the maintained gitleaks action before using it, since organization-owned repositories may need a license. Checkout needs `fetch-depth: 0` for history scanning.
- **osv-scanner**: only where lockfiles exist. `osv-scanner scan source --recursive .` with a pinned version. Decide in the report whether it blocks or only reports. A new blocking job on a repo with existing CVEs fails every PR, so start it non-blocking if the baseline is not clean and list that as a follow-up.

`.gitleaks.toml` is added only to allowlist a proven false positive. Each entry names the rule, the path or regex, and a comment saying why it is safe. Never allowlist a real finding.

## 6. Publishing

npm trusted publishing replaces `NPM_TOKEN` with a short-lived OIDC credential and publishes provenance. Requirements to verify against current npm docs: a recent npm CLI, a GitHub-hosted runner, and a trusted publisher configured on the package page that names the owner, repository, and exact workflow file name.

```yaml
permissions:
  contents: read
jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: <checkout pinned>
      - uses: <setup-node pinned>
        with:
          node-version: <supported LTS>
          registry-url: https://registry.npmjs.org
      - run: npm ci
      - run: npm publish --provenance --access public
```

Do not set `NODE_AUTH_TOKEN` on the OIDC path. Order of operations:

1. Add the workflow change with `id-token: write` and `--provenance`.
2. Keep the token step until the operator confirms the trusted publisher is configured and a release published through OIDC.
3. Only then remove the token reference and tell the operator to revoke the secret.

If the registry configuration is missing, or the package is private, or the runner is self-hosted, keep the token path, add `--provenance` only where supported, and record the blocker. For other registries, use the equivalent trusted publishing flow if one exists, and report the rest as deferred.

## 7. Docker bases

```dockerfile
# before
FROM node:22-slim
# after
FROM node:22-slim@sha256:<digest> # node 22-slim
```

Resolve the digest with whichever is installed: `docker buildx imagetools inspect <image>:<tag>` or `crane digest <image>:<tag>`. Use the multi-arch index digest, not a single platform digest, unless the build is single-platform. Pin every stage, including `COPY --from=<image>`. A build that uses an `ARG` in `FROM` needs the default value pinned. Zizmor's `unpinned-images` audit covers workflow container images. Dependabot's `docker` ecosystem keeps digests fresh.

## 8. Ignore files

Append if absent, without reordering existing lines:

```gitignore
.env
.env.*
!.env.example
```

If a real `.env` file is already tracked, `.gitignore` will not untrack it. Stop, tell the operator, and treat any value in it as exposed. Do not print the file.

## 9. SECURITY.md

Public repos only. State the supported versions, a private reporting route, and a response expectation the maintainer can keep. The preferred route is GitHub private vulnerability reporting, which the maintainer enables in repository settings (Security tab). Verify with `gh api repos/<owner>/<repo>/private-vulnerability-reporting`. A 404 or `enabled: false` means list the setting as an operator follow-up and do not claim the route works. Never put a personal email address in the file without the maintainer providing it.

## 10. Lockfiles

Generate with the project's own package manager and the version its CI uses. Commit only the lockfile. Do not upgrade dependencies as a side effect. If generation changes resolved versions beyond what the manifest ranges already allowed, stop and report.
