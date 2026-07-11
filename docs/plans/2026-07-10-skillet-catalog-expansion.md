# Skillet Catalog Expansion Plan

**Goal:** Make Skillet's portable catalog internally consistent, replace the fleet-specific SEO workflow, add dependency and performance workflows, and preserve two approved follow-up ideas in durable memory.

**Architecture:** Keep every installable skill as a top-level directory under `skillet/skills/` so existing harness discovery continues to work. Organize skills conceptually in documentation as `line`, `plating`, and `appliances`; do not introduce a runtime registry or nested skill layout. Extend the existing shell linter into the catalog contract and run it in GitHub Actions.

**Key technology:** Portable `SKILL.md` packages, Bash catalog checks, JSON skill metadata, GitHub Actions, Brigade verification receipts.

Execute task by task. Tick each checkbox after the command succeeds, and commit each completed task separately.

## File map

- `tests/lint-skills.sh`: structural and catalog-consistency test for every skill.
- `.github/workflows/lint-skills.yml`: CI entry point for the shipped linter.
- `skillet/skills/garnish/`: portable SEO audit-and-fix workflow replacing `seo-fleet`.
- `skillet/skills/stocktake/`: dependency and toolchain maintenance workflow.
- `skillet/skills/thermometer/`: profile-before-optimize workflow.
- `README.md`: accurate count, skill roster, and conceptual `line`/`plating`/`appliances` grouping.
- `skillet/skills/using-skillet/SKILL.md`: routing entries for every shipped skill.
- `.claude-plugin/marketplace.json`: complete marketplace description without stale skill omissions.
- `CHANGELOG.md`: migration note, new skills, catalog fixes, and repaired 0.5.1 release section.
- `.claude/memory-handoffs/`: review-gated durable note for `service` and `eighty-six`.

## Demi pass

Actual ask: implement the approved catalog replacement, additions, organization, consistency fixes, and future-work memory.

Smallest useful slice: three portable skill packages, one stronger existing linter, one CI workflow, corrected routing/docs, and one linted memory handoff.

Highest rung that holds: existing repository primitives and local changes.

Existing pattern to follow: `skillet/skills/special/` for a read-only/apply boundary, `skillet/skills/reduce/` for measured before/after work, and `tests/lint-skills.sh` for package validation.

Cut from scope: a new runtime registry, nested skill installation directories, automatic deployment, automatic dependency updates, and implementation of `service` or `eighty-six`.

Growth trigger: add another conceptual pack only when at least three skills share a distinct audience and trigger family.

Verification: `tests/lint-skills.sh`, run through `brigade work verify run` for the final receipt.

### Task 1: Turn the linter into the catalog contract

**Files:**
- Modify: `tests/lint-skills.sh`
- Create: `.github/workflows/lint-skills.yml`

- [x] Add a `check_catalog` function after `check_skill` that fails unless all of these hold:
  - every directory under `skillet/skills/` appears as `| **<id>** |` in `README.md`;
  - every skill appears as ``- `<id>` `` in `using-skillet/SKILL.md`;
  - the README badge count equals the number of skill directories;
  - `seo-fleet` is absent and `garnish`, `stocktake`, and `thermometer` exist;
  - `.github/workflows/lint-skills.yml` invokes `tests/lint-skills.sh`.

  Use this implementation:

```bash
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
    grep -Fq "| **$id** |" "$readme" || { echo "[fail] catalog: README missing $id"; return 1; }
    grep -Fq -- "- \`$id\`" "$routing" || { echo "[fail] catalog: using-skillet missing $id"; return 1; }
  done
  [ ! -d "$SKILLS_DIR/seo-fleet" ] || { echo "[fail] catalog: seo-fleet must be replaced by garnish"; return 1; }
  for id in garnish stocktake thermometer; do
    [ -d "$SKILLS_DIR/$id" ] || { echo "[fail] catalog: required skill $id missing"; return 1; }
  done
  [ -f "$workflow" ] && grep -Fq "tests/lint-skills.sh" "$workflow" || {
    echo "[fail] catalog: CI workflow missing linter invocation"; return 1;
  }
  echo "[ok] catalog ($count skills)"
}
```

- [x] Call `check_catalog || FAIL=1` only for the no-argument full-catalog path, after per-skill checks.
- [x] Run `tests/lint-skills.sh`; expect failure because `garnish`, `stocktake`, and `thermometer` do not exist and the README count is stale. This is the required RED run.
- [x] Create `.github/workflows/lint-skills.yml` with checkout and `tests/lint-skills.sh` on pushes and pull requests:

```yaml
name: Lint skills

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate skill packages and catalog
        run: tests/lint-skills.sh
```

- [x] Do not expect green yet; the production catalog changes in Tasks 2-5 satisfy the test.

### Task 2: Replace `seo-fleet` with portable `garnish`

**Files:**
- Delete: `skillet/skills/seo-fleet/`
- Create: `skillet/skills/garnish/SKILL.md`
- Create: `skillet/skills/garnish/skill.json`
- Create: `skillet/skills/garnish/CHANGELOG.md`

- [x] Remove `seo-fleet` and create `garnish` with frontmatter:

```yaml
---
name: garnish
description: Use when auditing or fixing discoverability metadata for a website before publication, including titles, descriptions, canonical URLs, robots policy, Open Graph, structured data, and sitemaps. Not for content strategy or keyword research.
---
```

- [x] The body must define two explicit modes. `AUDIT` is read-only and checks head metadata, indexing policy, sitemap/canonical agreement, per-page uniqueness, rendered output, and project-local policy. `FIX` runs only when requested, uses the site's existing framework and components, changes one finding at a time, and requires a rendered build plus re-audit before success claims.
- [x] The body must contain no personal handles, private fleet constants, fixed domains, fixed theme colors, or assumed framework. It must route prose through `plate` and verification through `check`.
- [x] Add `skill.json`:

```json
{
  "id": "garnish",
  "version": "0.1.0",
  "tests": ["bash ../../../tests/lint-skills.sh garnish"],
  "trust_level": "workspace"
}
```

- [x] Add a changelog recording the replacement and portable boundary.
- [x] Run `tests/lint-skills.sh garnish`; expect `[ok] garnish`.
- [x] Commit: `git add skillet/skills/garnish skillet/skills/seo-fleet && git commit -m "feat: replace seo fleet workflow with garnish"`.

### Task 3: Add `stocktake`

**Files:**
- Create: `skillet/skills/stocktake/SKILL.md`
- Create: `skillet/skills/stocktake/skill.json`
- Create: `skillet/skills/stocktake/CHANGELOG.md`

- [x] Create the skill with frontmatter:

```yaml
---
name: stocktake
description: Use when auditing, updating, or migrating project dependencies, runtimes, package managers, lockfiles, or toolchains. Requires reading authoritative release and migration notes, changing one compatibility boundary at a time, and verifying the resolved dependency graph.
---
```

- [x] Encode this workflow: define scope and target versions; inventory manifests, lockfiles, runtime pins, CI pins, and generated clients; establish a green baseline; read primary release/migration/security notes; choose the smallest safe upgrade batch; update declarations and resolved graph; migrate deprecated usage; run focused then full checks; review lockfile and transitive deltas; report deferred breaking upgrades. Never combine unrelated major upgrades, hand-edit lockfiles, or claim a vulnerability is fixed from the manifest alone.
- [x] Add standard `skill.json` at version `0.1.0`, workspace trust, and the per-skill linter command.
- [x] Add a changelog with the initial workflow.
- [x] Run `tests/lint-skills.sh stocktake`; expect `[ok] stocktake`.
- [x] Commit: `git add skillet/skills/stocktake && git commit -m "feat: add stocktake dependency workflow"`.

### Task 4: Add `thermometer`

**Files:**
- Create: `skillet/skills/thermometer/SKILL.md`
- Create: `skillet/skills/thermometer/skill.json`
- Create: `skillet/skills/thermometer/CHANGELOG.md`

- [x] Create the skill with frontmatter:

```yaml
---
name: thermometer
description: Use when investigating or improving performance, latency, throughput, memory use, CPU use, startup time, or bundle size. Establishes a repeatable baseline and profiles the measured bottleneck before any optimization.
---
```

- [x] Encode this workflow: pin the workload and environment; choose a user-visible metric and target; warm up and collect multiple baseline samples; profile before editing; form one bottleneck hypothesis; make one minimal change; repeat the same samples; compare median and spread; run correctness checks; keep only measured improvements; document the ceiling and next trigger. Stop when noise exceeds the claimed gain or the bottleneck is external. Never optimize from intuition, compare different workloads, report a single lucky run, or trade correctness/security for speed without explicit approval.
- [x] Add standard `skill.json` at version `0.1.0`, workspace trust, and the per-skill linter command.
- [x] Add a changelog with the initial workflow.
- [x] Run `tests/lint-skills.sh thermometer`; expect `[ok] thermometer`.
- [x] Commit: `git add skillet/skills/thermometer && git commit -m "feat: add thermometer performance workflow"`.

### Task 5: Reconcile routing, packs, manifests, and release history

**Files:**
- Modify: `README.md`
- Modify: `skillet/skills/using-skillet/SKILL.md`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `CHANGELOG.md`

- [x] Set the README badge to 32 skills: 30 current directories, minus `seo-fleet`, plus `garnish`, `stocktake`, and `thermometer`.
- [x] Keep top-level skill directories unchanged and divide the roster documentation into:
  - `line`: design, build, audit, review, release, and memory process skills;
  - `plating`: `plate`, `grill`, `reel-check`, `garnish`, and `publish-readiness`;
  - `appliances`: `graphtrail` and `brigade-handoffs`, with explicit external-tool requirements.
- [x] Give `garnish`, `stocktake`, `thermometer`, and `graphtrail` complete README rows. Remove every `seo-fleet` row and fleet-specific claim.
- [x] Add matching routes in `using-skillet`. Put `stocktake` and `thermometer` under Debug and verify, `garnish` under Writing and publishing, and `graphtrail` under a new Appliances section. Remove `seo-fleet`.
- [x] Update the marketplace description to name `garnish`, `stocktake`, `thermometer`, `graphtrail`, `review`, and `worktree`, and remove `seo-fleet`.
- [x] Repair changelog history by creating a `0.5.1 - 2026-06-29` section for the work already labeled as that release, leaving post-release GraphTrail/registry/evidence-loop work and this catalog expansion under `Unreleased`. Add an explicit breaking-change note: `seo-fleet` was replaced by portable `garnish`; fleet users should retain a repo-local policy skill. Add reference links for `0.5.1` while leaving tag publication to `release-cut`.
- [x] Run `tests/lint-skills.sh`; expect all 32 skills and `[ok] catalog (32 skills)`.
- [x] Commit: `git add README.md skillet/skills/using-skillet/SKILL.md .claude-plugin/marketplace.json CHANGELOG.md tests/lint-skills.sh .github/workflows/lint-skills.yml && git commit -m "feat: organize and validate the skill catalog"`.

### Task 6: Record the approved future skills in durable memory

**Files:**
- Create: `.claude/memory-handoffs/2026-07-10-2245-skillet-future-service-removal-skills.md`

- [x] Write a `research` handoff using `no-card` routing to `.learnings/FEATURE_REQUESTS.md`.
- [x] Record `service`: deploy and rollback gate with preflight, staged rollout, health checks, rollback criteria, and post-deploy verification. State that it should be built only after a repeated deployment workflow supplies concrete commands and stop conditions.
- [x] Record `eighty-six`: safe deprecation/removal workflow covering consumer discovery, migration window, staged deletion, absence verification, and rollback. State that it differs from `reduce`, which is local and behavior-preserving.
- [x] Record the naming preference: new public skills keep kitchen-themed names with literal trigger descriptions.
- [x] Run `brigade handoff lint --target .`; expect the new handoff `[ok]`.
- [x] Do not commit the ignored handoff; leave it in the review-gated inbox for memory-owner ingestion.

### Task 7: Final verification and review

**Files:**
- Modify: this plan only, to tick completed boxes.

- [x] Run `brigade work verify run --target . --command "tests/lint-skills.sh" --capture taste`; expect exit 0 and all 32 skills `[ok]` plus `[ok] catalog (32 skills)`.
- [x] Run `git diff --check`; expect no output and exit 0.
- [x] Run `git status --short`; reconcile every line. Only ignored/local Brigade and memory receipts may remain outside commits.
- [x] Inspect `git diff main...HEAD --stat` and `git diff main...HEAD` for fleet-specific personal constants, stale `seo-fleet` references, placeholder text, and unintended files.
- [x] Tick all completed plan boxes and commit the plan update: `git add docs/plans/2026-07-10-skillet-catalog-expansion.md && git commit -m "docs: complete skillet catalog plan"`.
- [x] Present Fire's four finish options without merging, pushing, or discarding automatically.
