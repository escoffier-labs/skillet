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
Renderer failures suggest an installed browser via `PUPPETEER_EXECUTABLE_PATH`
or omitting `--png`.
The higher-level `from-chart` route checks all scaffold destination entries with
`lstat` before generation when the model is missing. Existing configs, mappings,
directories, and dangling links are preserved without partial scaffolds. Existing
models are still reused. Direct `chart-to-tla.mjs` replacement behavior is unchanged.
The upstream renderer stand-ins now use `mmdc`. All upstream test cases remain.
Skillet adds offline renderer and scaffold regression files and a shell test wrapper
requiring Node.js 18.15 or later.

Invocation stays explicit in the descriptions and procedure. Codex also receives
`agents/openai.yaml` with implicit invocation disabled. Claude-only frontmatter
is omitted because the shared package validator does not accept it. Skillet's
required `version` field remains in source metadata. Codex quick validation of a
translated copy omits that unsupported field without changing the procedure.
