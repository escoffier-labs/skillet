# relief changelog

## 0.1.0 - 2026-10-20

- Added the skill: pause in-flight work at a safe boundary with a local wip checkpoint (named files, never on the default branch, never pushed) and an untracked resume note; pick up by finding the trail, reading the latest messages first, rebuilding state from git, choosing a verdict, and verifying inherited claims on the real artifact. Adapted from the pause-safely and session-pickup playbooks in pstack by Lauren Tan (MIT); the resume note stays out of the memory-handoff inbox.
