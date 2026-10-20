# runner changelog

## 0.1.0 - 2026-10-20

- Added the skill: drive an open pull request to merge-ready with a declared mode, blockers worked in order (conflicts, review threads, CI) and batched into one push, CI failures classified before any retry, and a stop at merge-ready. Adapted from the babysit and shipping playbooks in pstack by Lauren Tan (MIT); skillet keeps its own merge gates and never merges on the strength of a merge-ready verdict.
