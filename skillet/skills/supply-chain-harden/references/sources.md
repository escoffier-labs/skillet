# Sources

Start from these when a recipe needs checking. They change, so confirm current behavior before relying on a detail.

- OpenSSF Scorecard checks (Pinned-Dependencies, Token-Permissions, Dangerous-Workflow, Dependency-Update-Tool, Packaging, Security-Policy, SAST, Vulnerabilities): https://github.com/ossf/scorecard/blob/main/docs/checks.md
- SLSA specification and build provenance levels: https://slsa.dev/spec/
- zizmor documentation and audit list: https://docs.zizmor.sh/
- GitHub Docs, Security hardening for GitHub Actions: https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions
- GitHub Docs, Automatic token authentication and `permissions`: https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication
- GitHub Docs, Dependabot options reference (`groups`, `cooldown`): https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference
- GitHub Docs, Privately reporting a security vulnerability: https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability
- npm Docs, Trusted publishing for npm packages: https://docs.npmjs.com/trusted-publishers (retrieved 2026-10-20 through PageForge, page last edited 2026-10-06). Basis for control 6: npm CLI 11.5.1 and Node 22.14.0 minimums, exact `repository.url` match, exact workflow filename, GitHub-hosted runners only, automatic provenance for public repositories and public packages only, no provenance for private repositories, the 2-day first-publish window, and the migration order (verify, restrict tokens, revoke).
- npm Docs, Generating provenance statements: https://docs.npmjs.com/generating-provenance-statements
- gitleaks: https://github.com/gitleaks/gitleaks
- OSV-Scanner: https://google.github.io/osv-scanner/
- actionlint: https://github.com/rhysd/actionlint

Tool flags in SKILL.md were checked with `--help` on zizmor 1.31.1, gitleaks 8.30.1, osv-scanner 2.7.0, and actionlint 1.7.12. Re-check on the installed version.
