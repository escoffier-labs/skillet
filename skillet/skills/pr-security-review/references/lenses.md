# Lens checklists

Per-lens questions for a diff. Every item still needs the input-to-sink trace from SKILL.md before it becomes a finding. Category names follow OWASP Top 10:2025 and the OWASP Top 10 for LLM Applications 2025 (see [sources.md](sources.md)).

## Injection (A05)

- New string concatenation or template literals building SQL, shell commands, LDAP filters, or NoSQL queries from a request field. Parameterized calls are fine.
- `eval`, `exec`, `os.system`, `subprocess(..., shell=True)`, `child_process.exec`, `Function(...)` with any non-constant argument.
- HTML or template output without the framework's escaping: raw-HTML sinks, `|safe`, triple braces, unescaped attribute values.
- Header, log, or email construction from user input (CRLF injection).
- Regexes built from user input (ReDoS and injection both).

## AuthN and session (A07)

- Credentials, API keys, or tokens in code (location and type only in the report).
- New login, reset, or token endpoints without rate limiting or lockout.
- Session ID not rotated on login, cookies missing `HttpOnly`, `Secure`, or `SameSite`.
- JWT with no expiry, `alg: none` accepted, signature not verified, or a weak shared secret.
- Password storage with a fast hash or no salt. Constant-time comparison missing on secret checks.
- An auth bypass toggle (debug flag, "skip auth in dev") that can be set in production.

## AuthZ (A01)

- A new route, handler, RPC, or GraphQL field with no authorization check. Read the router and middleware as well as the handler.
- Lookups by an ID taken from the request with no ownership or tenant check (IDOR).
- Role checks done client-side only, or on the list endpoint but not the detail or export endpoint.
- Mass assignment: request body bound straight onto a model that has role, owner, or price fields.
- Authenticated is not authorized. A logged-in user reaching another user's data is a finding.

## Secrets and data exposure (A04, A02)

- Credentials in code, config, fixtures that look live, or `.env` files added to the diff. Check commit messages and branch names too.
- Tokens, passwords, session IDs, or PII written to logs, error messages, analytics events, or API responses.
- New fields serialized to the client that were previously internal.
- Sensitive data stored or sent without encryption in transit or at rest.

## Configuration (A02)

- Debug or verbose-error modes enabled outside development.
- CORS with a wildcard origin, or a reflected origin combined with credentials.
- Security headers removed or weakened (CSP, HSTS, frame options).
- Default credentials, open admin ports, binding to all interfaces by default.
- TLS verification disabled (`verify=False`, `rejectUnauthorized: false`, `InsecureSkipVerify`).

## CI/CD changes (A03, A08)

Applies to new or edited files under `.github/workflows/`, composite actions, and other CI config. A fork PR can change the workflow that runs against it, so judge triggers by who controls the code that runs.

- `pull_request_target` or `workflow_run` that checks out and runs the PR head. The base context has secrets and a write token. Running fork code there is the classic pwn request.
- `${{ github.event.* }}`, `github.head_ref`, PR title, body, branch name, or commit message interpolated inside a `run:` or `script:` block (script injection). Safe form: pass through an `env:` variable and quote it in the shell.
- Actions referenced by tag or branch instead of a full commit SHA, especially third-party ones.
- `permissions:` widened (`write-all`, `contents: write`, `id-token: write`, `packages: write`) or the workflow-level default removed.
- `runs-on: self-hosted` on a workflow that fork PRs can trigger.
- Secrets passed to steps that run untrusted code, secrets exposed with `secrets: inherit`, or echoed into logs.
- Artifacts or caches written by an untrusted run and consumed by a trusted one (cache poisoning).
- `actions/checkout` with `persist-credentials` left on in a job that runs untrusted code.
- Run `zizmor` and `actionlint` if installed (see [scanner-recipes.md](scanner-recipes.md)).

## Dependency changes (A03)

- Every new package in a manifest or lockfile diff: is the name one edit away from a popular package (typosquat)? Is it new, unmaintained, or published by a single new maintainer?
- Install-time execution: `preinstall`, `postinstall`, `setup.py` code, build scripts, `cmdclass`.
- A package source changed to a git URL, tarball URL, or alternate registry.
- Version ranges widened to `*` or `latest`, or pins removed.
- Lockfile drift: lockfile changed with no manifest change, resolved URLs or integrity hashes changed for an unchanged version, or a manifest change with no lockfile update.
- Run `osv-scanner` on changed lockfiles if installed. Compare base and head so only newly introduced advisories count.

## Agent and LLM surfaces (OWASP LLM01, LLM05, LLM06)

- A prompt assembled from untrusted input (user text, web pages, issue bodies, tool results) without a clear separation from instructions.
- A new tool, function, or MCP tool the model can call. Does it have an allowlist, argument validation, a confirmation gate for destructive or outbound actions, and least-privilege credentials?
- Model output passed to a shell, SQL engine, `eval`, file path, URL fetch, or HTML sink without the same validation any user input would get.
- Retrieved or fetched content that can carry instructions into a session that holds tools or secrets.
- Secrets or system prompts placed in context that is returned to the user or logged.
- Agent permission files, hooks, or settings changed to broaden what the agent may run unattended.

## SSRF, deserialization, path traversal

- A server-side fetch of a URL, host, or redirect target from user input. Check for scheme and host allowlists, blocking of loopback, link-local, and private ranges, and redirect handling.
- Unsafe deserializers on external data: `pickle`, `yaml.load` without a safe loader, Java object streams, `unserialize`, `Marshal.load`, untyped `JSON.parse` revivers that instantiate classes.
- File paths built from user input with `..`, absolute paths, or symlinks reaching outside the intended directory. Check archive extraction (zip slip) and upload names.

## Crypto misuse (A04)

- Home-made crypto, ECB mode, static or reused IVs and nonces, hardcoded keys.
- MD5 or SHA-1 for passwords or signatures.
- `Math.random`, `rand()`, or time-seeded values for tokens, IDs, or reset links.
- Missing integrity check on encrypted data. Comparison of MACs with a non-constant-time operator.

## Security-relevant literals

Treat a changed literal on a security path as non-trivial even when it is one line.

- Timeouts and token lifetimes lengthened. Rate limits raised or removed. Lockout thresholds raised.
- Auth, CSRF, or validation toggles flipped. Feature flags that gate a security control.
- Allowlists and denylists widened. Size or depth caps raised. Retry counts changed on auth paths.
- Ports, bind addresses, and trusted-proxy settings.
