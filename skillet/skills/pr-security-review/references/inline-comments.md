# Inline PR comment format

Use only when the user asks to post the review to the PR. Posting is outward-facing and visible to the author and other readers, so ask first unless the user already authorized posting on this PR. Post nothing from an unconfirmed finding set.

## One finding, one comment

```markdown
**[HIGH] Short imperative title** (confidence: high)

What: one or two sentences with the traced path (source path:line to sink path:line).
Why it matters: what an attacker gains.
Fix: specific remediation.
```

Attach it to the first changed line of the sink when the sink is in the diff. When the sink is outside the diff, attach it to the changed source line and name the sink file and line in the text.

## Rules

- Same secret rules as the report. Say "a GitHub token appears here", never the value or any part of it. Recommend rotation in the comment, because the PR history and notifications may already have exposed it.
- Do not paste code that holds a secret, internal hostnames, private paths, or environment details into a public PR.
- Do not include exploit strings. Name the class of input.
- No emoji, no praise filler, no "as an AI". Plain sentences.
- Summarize the verdict in one top-level review comment: verdict word, count of findings by severity, and the "Not checked" list.
- A comment is not a review decision. Do not approve, request changes, or merge unless the user asks for that specific action.
- Post in a single batch. Re-posting after every thought spams the author and may hit rate limits.
