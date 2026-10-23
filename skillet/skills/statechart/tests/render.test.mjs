import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const script = resolve(dirname(fileURLToPath(import.meta.url)), "../scripts/statechart.mjs");

// Only the renderer boundary is under test. This Java stand-in returns a fixed
// state graph, not a TLC verification result. Real TLC cases stay upstream.
for (const mode of ["installed", "missing", "failed", "no-output"]) {
  test(`--png with ${mode} mmdc stays offline and reports only written PNGs`, () => {
    const dir = mkdtempSync(join(tmpdir(), "statechart-render-"));
    try {
      const bin = join(dir, "bin");
      mkdirSync(bin);
      const executable = (name, body) => writeFileSync(join(bin, name), `#!${process.execPath}\n${body}\n`, { mode: 0o755 });
      executable("java", `
import fs from "node:fs";
const args = process.argv.slice(2);
const dump = args.indexOf("-dump");
if (dump !== -1) fs.writeFileSync(args[dump + 2], 'strict digraph DiskGraph {\\n1 [label="/\\\\\\\\ on = FALSE",style = filled]\\n2 [label="/\\\\\\\\ on = TRUE"]\\n1 -> 2 [label="On"];\\n2 -> 1 [label="Off"];\\n}\\n');
console.log("Model checking completed.");
`);
      executable("npx", `import fs from "node:fs"; fs.writeFileSync("install-attempt", "npx"); process.exit(99);`);
      if (mode !== "missing") executable("mmdc", `
import fs from "node:fs";
const args = process.argv.slice(2);
fs.writeFileSync("renderer-args.json", JSON.stringify(args));
if (${JSON.stringify(mode)} === "failed") { console.error("renderer failed"); process.exit(1); }
if (${JSON.stringify(mode)} !== "no-output") fs.writeFileSync(args[args.indexOf("-o") + 1], "rendered by installed mmdc");
`);
      // Extensions let Node load the stand-ins as ESM even on Node 18/20.
      writeFileSync(join(bin, "package.json"), '{"type":"module"}\n');
      writeFileSync(join(dir, "tla2tools.jar"), "test stand-in, not TLC");
      writeFileSync(join(dir, "Lamp.tla"), "---- MODULE Lamp ----\nVARIABLE on\nInit == on = FALSE\nOn == on' = TRUE\nOff == on' = FALSE\nSpec == Init /\\ [][On \\/ Off]_on\n====\n");
      writeFileSync(join(dir, "Lamp.cfg"), "SPECIFICATION Spec\n");
      writeFileSync(join(dir, "Lamp.map.mjs"), 'export const state = v => v.on ? "On" : "Off";\nexport const step = () => "you flip the switch";\n');
      const run = spawnSync(process.execPath, [script, "from-spec", "Lamp.tla", "--png"], {
        cwd: dir, encoding: "utf8", timeout: 15000,
        env: { ...process.env, PATH: bin, JAVA: join(bin, "java"), TLA2TOOLS: join(dir, "tla2tools.jar") },
      });
      assert.equal(run.error, undefined);
      assert.equal(existsSync(join(dir, "install-attempt")), false, "must never invoke a package installer");
      assert.equal(run.status, mode === "installed" ? 0 : 2, run.stdout + run.stderr);
      const out = join(dir, "Lamp-statechart");
      for (const name of ["chart.mmd", "stories.md", "summary.json"]) assert.ok(existsSync(join(out, name)), `${name}: ${run.stderr}`);
      assert.equal(existsSync(join(out, "chart.png")), mode === "installed");
      if (mode === "installed") {
        const args = JSON.parse(readFileSync(join(dir, "renderer-args.json"), "utf8"));
        assert.ok(args[args.indexOf("-i") + 1].endsWith("chart.mmd"));
        assert.ok(args[args.indexOf("-o") + 1].endsWith("chart.png"));
        assert.match(run.stdout, /Wrote chart\.mmd, chart\.png, stories\.md, summary\.json/);
        assert.equal(run.stderr, "");
      } else {
        assert.doesNotMatch(run.stdout, /Wrote .*chart\.png/);
        assert.match(run.stderr, /could not render Lamp-statechart\/chart\.mmd:/);
        if (mode === "missing") assert.match(run.stderr, /mmdc.*not installed.*no packages were installed/i);
        if (mode === "failed") assert.match(run.stderr, /renderer failed/);
        if (mode === "no-output") assert.match(run.stderr, /did not write.*chart\.png/);
      }
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
}
