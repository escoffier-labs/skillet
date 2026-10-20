# Sources

Retrieved 2026-10-20. Cite these by name. Re-check the edition before quoting a category number, because OWASP revises its lists.

- **OWASP Top 10:2025** (web application risks, current edition at retrieval): https://owasp.org/Top10/2025/ . Categories used in [lenses.md](lenses.md): A01 Broken Access Control, A02 Security Misconfiguration, A03 Software Supply Chain Failures, A04 Cryptographic Failures, A05 Injection, A07 Authentication Failures, A08 Software or Data Integrity Failures.
- **OWASP Top 10 for LLM Applications 2025**: https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/ . Index page: https://genai.owasp.org/llm-top-10/ . Used for the agent and LLM lens: LLM01 Prompt Injection, LLM05 Improper Output Handling, LLM06 Excessive Agency.
- **GitHub Actions security hardening and secure use reference**: https://docs.github.com/en/actions/reference/security/secure-use . Basis for the CI/CD lens: script injection, third-party action pinning, minimal `GITHUB_TOKEN` permissions, untrusted input.
- **zizmor**, static analyzer for GitHub Actions: https://docs.zizmor.sh/
- **actionlint**, workflow linter: https://github.com/rhysd/actionlint
- **gitleaks**, secret scanner: https://github.com/gitleaks/gitleaks
- **osv-scanner**, lockfile vulnerability scanner: https://github.com/google/osv-scanner
- **claude-code-security-review** by Anthropic (MIT license): https://github.com/anthropics/claude-code-security-review . Informed the structure of a diff-scoped review with explicit false-positive filtering and per-finding confidence. No text is copied.

Findings carry a location and secret type, never the offending line, because a quoted line can leak the secret into the report. The location-only rule exists for that reason.
