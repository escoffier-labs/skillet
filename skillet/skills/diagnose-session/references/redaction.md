# Redaction before sharing

Redact a copy, never the original. Share nothing until the user has seen the redaction log and the file list.

| Category | Placeholder | Catch |
|---|---|---|
| Email addresses | `<EMAIL-n>` | anything shaped like an email |
| People | `<PERSON-n>` | given names, surnames, handles, git author names; role words stay |
| Account or org ids | `<ORG-n>` | ids labelled account, org, owner, tenant, workspace, team |
| Secrets | `<SECRET-n>` | API keys, tokens, passwords, bearer strings, private keys, anything assigned to a variable named like `*_KEY`, `*_TOKEN`, `*_SECRET`, `PASSWORD`, `Authorization` |
| Hosts and addresses | `<HOST-n>` | non-public hostnames, IPv4 and IPv6 addresses, internal URLs |
| Home paths | `~` | any absolute path under a home directory; remove the account segment |
| Repositories | `<REPO-n>` | repository names, slugs, remote URLs unless the user lists them as public |
| Proprietary terms | `<PROPRIETARY-n>` | each term the user supplies, whole-word, case-insensitive |

Keep session ids, tool names, skill names, model ids, versions, and line numbers: the evidence is useless without them. Keep safe command and result structure so findings stay checkable. Mark substitutions inside quotations as redactions.

If redaction removes a finding's support, record the finding and the limitation; do not retain a sensitive value to satisfy an evidence check. Ambiguous classification goes back to the user, not into a broader rule.

After redacting, run a second pass over the output as if you were a stranger: grep the copy for the categories above and fix misses before showing the log. Scrubbing can miss things; tell the user to review every file before sharing.
