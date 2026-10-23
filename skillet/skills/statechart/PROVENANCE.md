# Provenance

Adapted from [pstack in cursor/plugins](https://github.com/cursor/plugins/tree/8b3326d99fd4b993cb33a24dad8af03175c642c5/pstack/skills/statechart)
by Lauren Tan, copyright 2026, MIT License. The pinned Git revision is
`8b3326d99fd4b993cb33a24dad8af03175c642c5`. See [LICENSE](LICENSE).

The complete upstream `scripts/` directory is retained, including `model/`,
`test/statechart.test.mjs`, `test/sync.mmd`, and `test/upload.mmd`.

Local changes: the skill body is rewritten for Skillet's explicit invocation,
verification scope, executable mapping trust boundary, and receipt handling.
PNG rendering invokes installed `mmdc` instead of `npx -y`, reports a missing
renderer without installing anything, and checks that the output file exists.
The upstream renderer stand-ins now use `mmdc`. All upstream test cases remain.
Skillet adds an offline renderer regression file and a shell test wrapper.

Invocation stays explicit in the descriptions and procedure. Codex also receives
`agents/openai.yaml` with implicit invocation disabled. Claude-only frontmatter
is omitted because the shared package validator does not accept it. Skillet's
required `version` field remains in source metadata. Codex quick validation of a
translated copy omits that unsupported field without changing the procedure.
