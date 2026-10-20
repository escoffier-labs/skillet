# pr-security-review changelog

Earlier history lives in the repo-level CHANGELOG.md.

## 0.1.0 - 2026-10-20

- Initial release. Diff-scoped security review for a PR, commit range, or staged changes, with CI/CD, dependency, agent and LLM, SSRF, deserialization, crypto, and security-literal lenses on top of the OWASP checklist.
- Location-only secret handling (no code field that quotes secret-bearing lines), scanner recipes that read gitleaks, zizmor, actionlint, and osv-scanner output through projections, and explicit reviewer-safety rules for attacker-controlled PR text.
- Named to avoid the built-in /security-review command.
