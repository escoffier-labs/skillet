# fire changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Rulings, not stalls: a non-destructive judgment call becomes a recorded ruling (basis label and cost if wrong) instead of a stop. Stops are limited to destructive or irreversible actions, security-sensitive choices, side effects outside the working tree, and a plan broken enough that every path is a guess. Two or more same-shape deviations now mean the plan is wrong. Adapted from obra/superpowers (MIT).
- Per-plan ledger in a git-ignored location as the resume point after compaction (`references/ledger.md`); checkboxes stay the live board.
- Final whole-branch review on the strongest available model against the merge-base diff, with findings re-graded by effect and fixed once, test first. The final message lists every ruling and deferred minor.
- Finish: removed "Discard the work" from the menu (offered only on request, typed confirmation, deletions listed); never `git worktree remove --force`, list unsaved files and ask; confirm the base branch before merging; two-option menu on detached HEAD.
- Brigade mode links the shared dispatch contract in stations.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
