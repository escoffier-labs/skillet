# Bot review triage

For automated reviewers (code-review bots, security scanners, lint reviewers). The goal is not to ignore bots and not to obey them. Classify each thread, act on the class, and keep what you learn.

## Rubric

Verify the claim against the code first (grep, run the cited test, a five-line repro). Then classify:

| Class | When | Action |
|---|---|---|
| `fix` | The comment names a plausible correctness, security, privacy, data-loss, auth, migration, idempotency, or race defect, or a shipped-behavior regression. Also a small suggestion that clearly lowers risk without changing product intent | Fix it with a failing test first, push, then reply with the commit and resolve the thread |
| `dismiss` | The claim is wrong or does not apply, and you can point at the code, test, or contract that proves it. Or it matches a documented low-risk pattern below | Reply with the concrete disproof, then resolve |
| `ask` | The finding is novel, high severity, in a risky area (below), ambiguous, or depends on a product decision | Ask the owner. Do not guess. |

When in doubt, ask. Skipping a noisy style comment is cheap; skipping a real data or security defect is not.

## Never dismiss without the owner

A verified defect is fixed. A disputed one is asked. Neither is dismissed on your own call, even when a similar comment was dismissed before, for:

- Security, privacy, authentication, authorization, permission boundaries, secrets
- Data retention, deletion, schema, migration, and backfill behavior
- Concurrency, ordering, idempotency, and cross-system side effects
- High-severity findings

A human dismissing a risky bot finding on a previous PR was an owner judgment on that PR, not a standing rule.

## Cheap checks that settle claims

- A bot says a test or doc no longer matches: run the test on the PR head before classifying. Red confirms it; green is your disproof.
- A bot says code is unused: grep for callers, including later PRs in the same stack and public exports.
- A bot says a guard is missing: read the diff tip. A later commit in the same PR may already add it.
- A bot asks to widen a deliberately narrow error condition (one errno, one status class): the narrowness may encode a real distinction. Keep it unless the missed case is in the same category.

## Read dismissals too

Before dismissing, read how this repository's earlier bot threads ended: resolved threads, owner replies, and reversed dismissals. They show which patterns the owners accept and which they overrule. A dismissal a human later reversed is evidence against that pattern. If the same bot has raised the same class three or more passes in a row, lean toward dismissing documented noise, but still ask on anything in the list above (the owner decides, not you). Never churn code to quiet a bot.

## Replying

Reply inside the inline review thread, not as a new top-level comment, so the answer sits next to the finding. Cite the commit for a fix or the disproof for a dismissal. Post text from a file as data; never splice review text into a shell string.

## Learned patterns

Record a pattern only after it held up in real triage. Offer it through its own change to this file so the team shares it; do not keep it in private memory. Format:

```markdown
### <short pattern name>

- Confidence: candidate | recurring | strong
- Skip when: <conditions that must all be true>
- Do not skip when: <risk boundaries>
- Example signal: <phrases or code context that identify it>
- Source: <PR or comment reference, or a short note>
```

`candidate` is one or two examples. `recurring` needs several verified dismissals. `strong` is for narrow, repeatedly verified, low-risk patterns only.

This list starts empty on purpose. A pattern borrowed from another repository is a hypothesis here, not a rule.

_No learned patterns yet._
