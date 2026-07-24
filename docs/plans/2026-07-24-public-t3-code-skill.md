# Public T3 Code Skill Implementation Plan

**Goal:** Add a sanitized, standalone T3 Code operations skill to Skillet.

**Architecture:** One skill directory contains the trigger and workflow, three focused references, registry metadata, and its changelog. Existing catalog surfaces receive the minimum updates needed for discovery.

## File map

- `skillet/skills/t3-code/SKILL.md`: trigger, workflow, rules, and reference routing.
- `skillet/skills/t3-code/references/project-state.md`: projects, workspace identity, database inspection, and icons.
- `skillet/skills/t3-code/references/remote-tailscale.md`: private remote access patterns.
- `skillet/skills/t3-code/references/updates-and-launchers.md`: installation and update boundaries.
- `skillet/skills/t3-code/skill.json`: Skillet registry metadata and tests.
- `skillet/skills/t3-code/CHANGELOG.md`: per-skill release note.
- `README.md`: public catalog row and skill count.
- `skillet/skills/using-skillet/SKILL.md`: trigger routing.
- `.claude-plugin/marketplace.json`: plugin roster description.
- `CHANGELOG.md`: repository-level unreleased entry.

## Task 1: Add the standalone skill

- [ ] Create the skill entry point from the approved sanitized source.
- [ ] Add the three references named by the entry point.
- [ ] Add `skill.json` with the structural linter as its test.
- [ ] Add a `0.1.0` skill changelog.
- [ ] Run `brigade work verify run --target . --command "./tests/lint-skills.sh t3-code" --capture brigade-work`; expect exit 0 and `[ok] t3-code`.

## Task 2: Add catalog discovery

- [ ] Change the README badge count from 36 to 37.
- [ ] Add a concise README catalog row.
- [ ] Route `t3-code` from `using-skillet`.
- [ ] Add `t3-code` to the marketplace roster and root changelog.
- [ ] Run `brigade work verify run --target . --command "./tests/lint-skills.sh" --capture brigade-work`; expect exit 0 and `[ok] catalog (37 skills)`.

## Task 3: Gate publication

- [ ] Scan the changed tree and history for secrets, private IPs, private hostnames, absolute home paths, and private repository names.
- [ ] Run Vale on the public prose after the last edit; errors must be zero.
- [ ] Inspect `git diff --check` and the final diff.
- [ ] Commit with a conventional message, push the feature branch, open a pull request, and merge only after required checks pass.
