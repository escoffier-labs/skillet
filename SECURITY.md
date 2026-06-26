# Security Policy

## Supported versions

skillet is a roster of agent skills (plain `SKILL.md` files), not a running service. Only the latest tagged release on the `main` branch receives fixes. Pin to a released tag if you need a known-good version.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security problems. Email **me@solomonneas.dev** with: <!-- content-guard: allow pii/email -->

- A short description of the issue.
- Steps to reproduce (or a minimal proof of concept).
- The skill and the tag or commit you tested against.
- Whether you would like to be credited in the release notes.

You should get an acknowledgment within 72 hours. If you do not, please follow up; the mail may have been filtered.

## In scope

- A skill that instructs an agent to leak secrets, exfiltrate data, or run destructive commands without the documented human-in-the-loop gate.
- A skill whose procedure causes an agent to write outside the repo it was pointed at, or to push, publish, or release without explicit operator approval.
- Prompt-injection or untrusted-content handling flaws in a skill that processes external input (for example the leak-scrub and audit skills).
- A skill that bypasses its own stated read-only or review-gated boundary (for example the audit trio applying changes, or release-cut tagging without a request).

## Skills execute through your agent

A skill is a set of instructions an AI coding agent follows. The agent runs commands on your machine with your permissions. Treat any skill as **only as trustworthy as the harness and the operator approvals around it**:

- The read-only audit skills (line-check, bug-hunt, security-sweep, special) report findings; **expedite** is the separate, opt-in step that applies fixes, and it parks anything destructive or breaking for you to decide.
- Publish and release skills (publish-readiness, release-cut, pass) gate on operator review and never push or tag without an explicit request.
- The real boundary is your harness's permission model and your review of what the agent is about to do. Read the skill before you let an agent act on it.

## Out of scope

- Bugs in `content-guard` itself; please report those upstream at <https://github.com/escoffier-labs/content-guard>.
- Bugs in Claude Code, Codex, OpenClaw, or any other harness; report those to their respective projects.
- Issues that require an attacker to already have write access to your machine, harness config, or repository.
- Content a user wrote and committed themselves. skillet provides procedures and guardrails, not perfect content review.

## Disclosure

We aim to ship a fix within 14 days of confirming a valid report. A coordinated disclosure timeline can be negotiated for issues that need longer.
