# merge-ready changelog

## 0.2.1 - 2026-11-04

- Point the filing-a-PR exclusion at `superpowers:finishing-a-development-branch`. The `pass` skill it named was retired on 2026-11-03.

## 0.2.0 - 2026-11-03

- Renamed to merge-ready; added metadata.formerly and a temporary description suffix for old-name routing. No alias directory ships. Procedures are unchanged; kitchen metaphors now use plain English.

## 0.1.0 - 2026-10-20

- Added the skill: drive an open pull request to merge-ready with a declared mode, blockers worked in order (conflicts, review threads, CI) and batched into one push, CI failures classified before any retry, and a stop at merge-ready. Adapted from the babysit and shipping playbooks in pstack by Lauren Tan (MIT); skillet keeps its own merge gates and never merges on the strength of a merge-ready verdict.
