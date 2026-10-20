# mise changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.2.0 - 2026-10-20

- Replaced "every task, no exceptions, however small" with a size table (clear small change done now, medium change agreed in chat, project gets the full spec); the chosen size is stated.
- Intent-first opening: offer to skip questions, ask one open question about the real situation, menus only when stuck. Ground to cover, a "how it gets made" probe, and short play-back chunks with guesses marked.
- Caller usage is written before types or layout for anything with an API; approaches must be structurally distinct; fork decisions that depend on feel or an observable fact are settled with a throwaway prototype.
- Chosen design is screened against the new `references/design-red-flags.md`.
- Self-review replaced by a one-pass builder check: a fresh subagent on a cheaper model returns only the questions it would still need answered.
- Description rewritten to triggers only.
- Adapted from obra/superpowers brainstorming v7.0.0 (MIT) and pstack architect by Lauren Tan (MIT).
- Review fixes: larger-size tie-breaker, skipping questions still needs approval at medium and project size, prototype exception to the no-code rule with a scratch directory outside the source tree, builder-check round named as the one exception to one-question-per-message. README row updated.

## 0.1.0 - 2026-07-08

- Added skill.json metadata (tests, changelog) for the Brigade skill registry.
