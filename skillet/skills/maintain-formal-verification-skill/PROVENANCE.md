# Provenance

Adapted from [pstack in cursor/plugins](https://github.com/cursor/plugins/tree/8b3326d99fd4b993cb33a24dad8af03175c642c5/pstack/skills/maintain-formal-verification-skill)
by Lauren Tan, copyright 2026, MIT License. The pinned Git revision is
`8b3326d99fd4b993cb33a24dad8af03175c642c5`. See [LICENSE](LICENSE).

The procedure is rewritten for Skillet with an explicit-request trigger,
verification-only editing scope, dependency authorization, receipt handling,
and an untrusted-content boundary. No upstream executable code is added here.

Invocation stays explicit in the descriptions and procedure. Codex also receives
`agents/openai.yaml` with implicit invocation disabled. Claude-only frontmatter
is omitted because the shared package validator does not accept it. Skillet's
required `version` field remains in source metadata. Codex quick validation of a
translated copy omits that unsupported field without changing the procedure.
