# Confidence tiers and phrasing

Every claim in a lineage report sits in exactly one tier, and its phrasing must match the tier.

## Direct

An author wrote the reason: a PR body ("fixes pagination for accounts with over 1000 items"), a ticket, a code comment ("clamp to 100, upstream rejects larger values"), a design doc, a message from the author. Not "the code does X so the author must have wanted X."

Phrasing: confident, present tense, cited. "This exists because X (PR #123)."

## Supported

Several indirect pieces converge. No single source states it. For example the PR title says "improve performance", the ticket is labelled perf, and the surrounding commits all touch the same hot path.

Phrasing: confident but derived, with each piece cited. "The evidence points to X: A, B, C."

## Inferred

Your reading of the context. Nothing says it outright. Example: the fix merged the same day an incident was reported, so it was probably a hotfix.

Phrasing: hedged, chain explicit. "Given A and B, C seems likely because D."

## Speculative

A plausible hypothesis on thin evidence where other explanations fit equally well. Worth stating because the user may know which is right. "One possibility is X, but there is no direct evidence."

## Unknown

You looked and could not find out. This is a valid and useful result. Be specific: "Searched the PR history for the file since the first commit, the issue tracker for the threshold value, and the docs directory; none states a rationale." That beats "could not find out".

## Wording

Words that need an adjacent citation (Direct or Supported only): "because", "the reason is", "was designed to", "fixes", "the team decided".

Hedges for lower tiers: "appears to", "seems to", "likely", "is consistent with", "plausibly", "may have been".

Avoid: "obviously", "clearly", "of course", and "just" used to wave away uncertainty.

## Before finalizing

For each claim: does it have a citation, or has it moved to Inferred or Speculative? Does the phrasing match the tier? Did any claim use the code as evidence for its own intent? Is there an Unknown section? A report with no gaps is suspicious: either the evidence was unusually complete or something was swept under the rug.
