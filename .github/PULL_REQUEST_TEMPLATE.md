<!--
Thanks for sending a patch. Keep this short; delete sections that do not apply.
See CONTRIBUTING.md for what lands easily and what needs an issue first.
-->

## What and why

<!-- One or two sentences on the change and the friction it removes. -->

Closes #

## Type of change

- [ ] Bug fix (a skill misfires, fails to trigger, or has a broken example)
- [ ] Sharper trigger for an existing skill
- [ ] New skill (opened an issue first per CONTRIBUTING.md)
- [ ] Docs (README skill table, audit report contract, install instructions)

## Checklist

- [ ] For a new or changed skill, I ran the fresh-agent test (a clean session triggers it from the description and reaches the intended outcome)
- [ ] Updated the `Unreleased` section of `CHANGELOG.md` for any user-visible effect
- [ ] Updated the README skill table if a skill was added, renamed, or changed
- [ ] No PII: no personal details, hostnames, IPs, account names, tokens, or unredacted absolute paths in skill instructions, examples, or this PR (ran `content-guard` over changed files; the pre-push hook will flag leaks otherwise)
- [ ] Conventional commit messages, no AI co-authorship trailers
