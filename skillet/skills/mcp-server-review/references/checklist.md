# MCP server review checklist

Grep recipes per lens. They find candidates and nothing more. Read the surrounding code and trace the argument before you report anything. Run them from the server's source root and exclude `node_modules`, `.venv`, `dist`, and `vendor` unless you are reviewing dependencies.

```bash
EXCL='--exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=dist --exclude-dir=vendor --exclude-dir=.git'
```

## 1. Tool inventory and gates

Enumerate every tool first. The registration call differs by SDK.

```bash
# TypeScript / JavaScript SDK
grep -rnE "server\.tool\(|\.registerTool\(|setRequestHandler\(\s*CallToolRequestSchema|name:\s*['\"][a-z_]+['\"]" $EXCL --include='*.ts' --include='*.js' --include='*.mjs' .
# Python SDK (FastMCP and low level)
grep -rnE "@(mcp|server|app)\.tool|@mcp\.tool|call_tool\(|Tool\(\s*name=" $EXCL --include='*.py' .
# Go, Rust, other
grep -rnE "AddTool\(|NewTool\(|#\[tool\]|tool_router" $EXCL .
```

Then classify each hit and fill the table:

| Tool | Resource | Class (read / write / destructive / exec / egress) | Gate | Dry-run |
|------|----------|-----|------|---------|

Gate-consistency recipes:

```bash
# Which tools take a confirm-style parameter at all
grep -rnE "confirm|dry_?run|force|allow_?destructive|require_?approval" $EXCL .
# Destructive verbs in tool names or handlers
grep -rniE "delete|remove|drop|purge|truncate|destroy|kill|reset|wipe|disable|toggle|overwrite" $EXCL --include='*.ts' --include='*.js' --include='*.py' .
# Writes: find every file or API mutation, then map back to a tool
grep -rnE "writeFile|appendFile|fs\.(rm|unlink|rename)|open\([^)]*['\"][wa]|shutil\.(rmtree|move)|os\.(remove|unlink)|\.(post|put|patch|delete)\(" $EXCL .
```

Questions to answer for each resource: do all tools that write it share one gate? Is the confirm parameter actually read by the handler? Is a destructive tool hidden behind a disabled-by-default tier or allowlist? Does a dry-run return the planned change without performing it?

## 2. Transport and auth

```bash
# Transport in use
grep -rnE "StdioServerTransport|StreamableHTTPServerTransport|SSEServerTransport|stdio_server|streamable_http|sse_app|http\.createServer|express\(\)|FastAPI\(|uvicorn\.run|app\.listen" $EXCL .
# Bind address and defaults
grep -rnE "0\.0\.0\.0|::\b|INADDR_ANY|host\s*[:=]\s*['\"]?(0\.0\.0\.0|::)|\.listen\(" $EXCL .
grep -rnE "127\.0\.0\.1|localhost|loopback" $EXCL .
# Auth and token comparison
grep -rniE "authorization|bearer|jwt|oauth|api[_-]?key|x-api-key" $EXCL .
grep -rnE "timingSafeEqual|compare_digest|hmac\.Equal|ConstantTimeCompare" $EXCL .
grep -rnE "token\s*(===|==|!==|!=)|(===|==)\s*(req|request)\S*token" $EXCL .
# Host and Origin validation, CORS, size limits
grep -rniE "origin|host header|allowedHosts|allowed_hosts|cors|dns.?rebind" $EXCL .
grep -rniE "limit:|bodyLimit|max_?(body|request|content)_?(size|length)|maxBodyLength|content-length" $EXCL .
```

Check by reading, not grep alone:

- The default bind value when no config is set, and the code path taken when a wildcard is configured without auth.
- That the token compare is constant time and that an empty configured token cannot match an empty header.
- That Host and Origin are checked on every request, including the SSE or session endpoints.
- That the server never forwards an incoming `Authorization` header upstream and rejects tokens whose audience is not this server.

## 3. Process execution

```bash
# Node
grep -rnE "child_process|\bexec\(|execSync\(|spawn\(|spawnSync\(|execFile\(|execFileSync\(|shell:\s*true" $EXCL --include='*.ts' --include='*.js' --include='*.mjs' .
# Python
grep -rnE "subprocess\.|os\.system|os\.popen|shell\s*=\s*True|\beval\(|\bexec\(|asyncio\.create_subprocess_shell" $EXCL --include='*.py' .
# Go, Rust, others
grep -rnE "exec\.Command\(|sh -c|bash -c|std::process::Command|Runtime\.getRuntime\(\)\.exec|ProcessBuilder" $EXCL .
# Template strings fed to a shell
grep -rnE "(exec|execSync|system|popen)\(\s*[\`f\"'][^)]*(\\$\{|%s|\{[a-z_]+\})" $EXCL .
```

For each hit that survives, trace the argument:

- Shell string with interpolated tool input: finding. Fix with `execFile` or an argv array.
- Argv array but the user value can begin with `-`: argument injection. Look for `--` before positional user values, or a validation pattern.
- Executable name taken from input, or `PATH` resolved at call time: pin an absolute path or an allowlist.

File tools:

```bash
grep -rnE "path\.(join|resolve)\(|os\.path\.(join|abspath)|readFile|read_text|open\(" $EXCL .
grep -rnE "realpath|realpathSync|resolve\(\)\.is_relative_to|startsWith\(" $EXCL .
```

Confirm the resolved path (after symlinks) is checked against an allowed root, and that `..`, absolute paths, and encoded separators are handled.

## 4. Credentials

```bash
# How secrets load
grep -rnE "process\.env\.|os\.environ|getenv\(|dotenv|readFileSync\([^)]*(token|key|secret|cred)|keyring|vault|secretmanager" $EXCL .
# Hardcoded candidates (report location and type only, never the value)
grep -rniE "(api[_-]?key|secret|token|passwd|password)\s*[:=]\s*['\"][A-Za-z0-9_\-]{12,}" $EXCL .
# Secrets reaching logs or errors
grep -rnE "console\.(log|error|warn)|logger\.|logging\.|print\(" $EXCL . | grep -iE "token|key|secret|auth|header|config|env"
grep -rnE "catch\s*\(|except\s+\w*" -A4 $EXCL . | grep -iE "headers|config|url|request|env"
```

Check that error responses built from upstream failures do not echo request headers, full URLs with query tokens, or response bodies. Check that the README or manifest lists the upstream permissions required, and that the token examples ask for the narrowest scope.

## 5. TLS and network

```bash
grep -rnE "NODE_TLS_REJECT_UNAUTHORIZED|rejectUnauthorized\s*:\s*false|strictSSL\s*:\s*false|InsecureSkipVerify|danger_accept_invalid_certs" $EXCL .
grep -rnE "verify\s*=\s*False|ssl\s*=\s*False|CERT_NONE|check_hostname\s*=\s*False|urllib3\.disable_warnings" $EXCL .
```

A process-wide setting (an env var assignment at startup, a global agent, `verify=False` on a shared session) is a finding. The fix is a scoped client with a pinned CA for the single host that needs it.

SSRF on tools that take a URL or host:

```bash
grep -rnE "fetch\(|axios|got\(|http\.get|https\.get|requests\.(get|post|request)|httpx\.|urllib\.request|net\.connect|socket\.connect" $EXCL .
grep -rniE "(url|uri|host|hostname|endpoint|webhook|target)\s*[:=].*(args|params|input|arguments)" $EXCL .
```

For each, check for a scheme allowlist, a block on loopback, link-local (including the cloud metadata address), and private ranges applied after DNS resolution, and control over redirects.

## 6. Output to the model

```bash
grep -rniE "untrusted|<[a-z_]*_data>|sanitize|escape|fence|delimiter" $EXCL .
grep -rnE "content\s*:\s*\[\s*\{\s*type\s*:\s*['\"]text|return\s+\{?\s*content|TextContent\(" $EXCL .
grep -rnE "stack|\.trace|traceback|err(or)?\.message|str\(e\)|repr\(e\)|JSON\.stringify\(err" $EXCL .
```

For every tool that returns text from logs, mail, web pages, tickets, alerts, chat, or user-edited records, check three things: the data is fenced in a marker, a closing marker inside the data cannot break out, and the tool description says the result is untrusted. For error paths, confirm the model sees a failure class and a short message, not a stack trace, file path, or raw upstream body.

## 7. Tool description integrity

```bash
# Dump all descriptions for a human read
grep -rnE "description\s*[:=]" $EXCL .
# Instruction-shaped phrases inside descriptions
grep -rniE "ignore (all |any )?(previous|prior)|do not (tell|mention|inform)|before (using|calling) (this|any|other)|first (read|send|call)|<important>|system prompt|exfiltrat|silently" $EXCL .
# Descriptions computed at runtime or fetched remotely
grep -rnE "description\s*[:=]\s*(\`|await |fetch|f\"|.*\+\s*[a-z])" $EXCL .
# Tool names that may shadow common servers
grep -rnE "name\s*[:=]\s*['\"](search|read_file|write_file|list_files|fetch|send_email|run_command|execute|query)['\"]" $EXCL .
```

Read every description and parameter description as text addressed to the model. Look for hidden or off-topic instructions, requests to read other files or other tools' data, and text after long whitespace runs or in odd Unicode. For a third-party server, save the description text you reviewed with the version, so the next update can be diffed.

## 8. Supply chain

```bash
ls package-lock.json pnpm-lock.yaml yarn.lock bun.lockb uv.lock poetry.lock Pipfile.lock Cargo.lock go.sum 2>/dev/null
grep -nE "\"(preinstall|install|postinstall|prepare|prepublish)\"" package.json
grep -nE "\"[^\"]+\":\s*\"(\*|latest|\^|~|>=)" package.json
grep -nE "(>=|~=|\*)" requirements*.txt pyproject.toml 2>/dev/null
grep -rnE "provenance|--provenance|id-token:\s*write|attest|sigstore|cosign|SLSA" .github $EXCL . 2>/dev/null
grep -nE "\"(bin|files|main|repository|publishConfig)\"" package.json
```

For a package you are about to install, compare the published tarball to the tagged source when you can (`npm pack --dry-run` lists contents without installing). Treat unexplained files, minified code with no source, and install scripts that fetch remote content as stop conditions. Do not run the install to find out.
