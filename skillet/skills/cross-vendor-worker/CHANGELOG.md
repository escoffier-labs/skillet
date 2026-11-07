# cross-vendor-worker changelog

## Unreleased

- Document OpenCode 2.2.6 background-job waiting, timeout and cancellation behavior, and worktree flag constraints from upstream release notes.

## 0.2.0 - 2026-11-03

- Renamed to cross-vendor-worker; added metadata.formerly and a temporary description suffix for old-name routing. No alias directory ships. Procedures are unchanged; kitchen metaphors now use plain English.

## 0.1.1 - 2026-10-20

- Trimmed the description from 568 to under 500 characters and removed the procedure summary ("dispatching that vendor's own CLI as a one-shot worker"), keeping only the triggers and the Brigade roster pointer. Descriptions that summarize the workflow get followed instead of the body (finding from obra/superpowers, MIT).

## 0.1.0 - 2026-07-12

- First release: one-shot cross-vendor worker dispatch over the user's own CLI logins (cursor-agent, grok, codex, claude, agy, ollama, opencode), with the verified headless flags and the silent-failure trap for each CLI, plus the write-disabled-chef orchestration pattern for opencode. Every incantation baseline-tested against live CLIs before it shipped; the companion write-up is the brigade.tools post "Sol Runs the Pass".
