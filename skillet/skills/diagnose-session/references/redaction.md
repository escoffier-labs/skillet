# Making a transcript excerpt safe to share

Work on a copy. Show the user the replacement log and the list of files before anything leaves the machine.

## What gets replaced

| Kind of content | Replace with | Notes |
|---|---|---|
| Email addresses | `<EMAIL-n>` | any address-shaped string |
| Names of people and handles | `<PERSON-n>` | full name or handle; generic roles such as "the reviewer" stay |
| Organization, account, tenant, workspace ids | `<ORG-n>` | including UUIDs next to those labels |
| Credentials | `<SECRET-n>` | keys, tokens, passwords, bearer strings, private keys, and values assigned to names like `API_KEY`, `*_TOKEN`, `PASSWORD`, `Authorization` |
| Private hosts and addresses | `<HOST-n>` | internal hostnames and URLs, IPv4 and IPv6 addresses; public package and docs domains stay |
| Paths under a home directory | `~/...` | drop the account segment |
| Repository names and remotes | `<REPO-n>` | unless the user marked the repository public |
| Terms the user marks proprietary | `<PROPRIETARY-n>` | whole word, any case |

Number placeholders so the same value always maps to the same token.

## What stays

Session ids, tool and skill names, model ids, versions, and line numbers. Without them a finding cannot be checked. Keep command and result structure that a reader needs to verify a claim, and mark each substitution inside a quotation so a reader knows it was edited.

## When redaction removes the evidence

If scrubbing a value erases the support for a finding, note the finding and the limitation instead of keeping the value. If a string is hard to classify, ask the user rather than inventing a broader rule.

## Check your own work

Re-scan the redacted copy for every row above as if you were someone outside the project, fix what slipped through, and only then show the log. Tell the user that scrubbing can miss things and that they should read every file before sharing.
