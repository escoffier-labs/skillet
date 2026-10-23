import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, readlinkSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

const script = resolve(dirname(fileURLToPath(import.meta.url)), "../scripts/statechart.mjs");
const chart = "stateDiagram-v2\n  [*] --> Idle\n  Idle --> Done : you finish\n";
const snapshot = (dir) => Object.fromEntries(
  readdirSync(dir).sort().map((name) => {
    const entry = join(dir, name);
    const stat = lstatSync(entry);
    return [name, stat.isSymbolicLink() ? { link: readlinkSync(entry) }
      : stat.isDirectory() ? { directory: snapshot(entry) }
        : { bytes: readFileSync(entry).toString("base64") }];
  }),
);
const run = (dir, args = []) => spawnSync(process.execPath, [script, "from-chart", "flow.mmd", ...args], {
  cwd: dir, encoding: "utf8", timeout: 15000,
  // Deliberately stop at tool discovery: these cases never run TLC or Java.
  env: { ...process.env, TLA2TOOLS: "", JAVA: "" },
});

for (const [kind, extensions] of [
  ["file", ["cfg"]], ["file", ["map.mjs"]], ["file", ["cfg", "map.mjs"]],
  ["directory", ["cfg"]], ["directory", ["map.mjs"]],
  ["dangling symlink", ["tla"]], ["dangling symlink", ["cfg"]], ["dangling symlink", ["map.mjs"]],
]) {
  test(`from-chart preserves ${extensions.join(" and ")} ${kind} entries without partial scaffolds`, () => {
    const dir = mkdtempSync(join(tmpdir(), "statechart-scaffold-"));
    try {
      writeFileSync(join(dir, "flow.mmd"), chart);
      writeFileSync(join(dir, "keep.txt"), "unrelated authored file\n");
      const name = extensions.length === 2 ? "Chosen" : "Flow";
      for (const ext of extensions) {
        const entry = join(dir, `${name}.${ext}`);
        if (kind === "dangling symlink") symlinkSync("missing-target", entry);
        else if (kind === "directory") {
          mkdirSync(entry);
          writeFileSync(join(entry, "keep.txt"), "authored directory contents\n");
        } else writeFileSync(entry, `authored ${ext}\n`);
      }
      const before = snapshot(dir);
      const result = run(dir, name === "Chosen" ? ["--module", name] : []);
      assert.equal(result.error, undefined);
      assert.deepEqual(snapshot(dir), before, "preserve every existing byte and create no partial output");
      assert.equal(result.status, 2, result.stdout + result.stderr);
      for (const ext of extensions) assert.ok(result.stderr.includes(`${name}.${ext}`), result.stderr);
      assert.match(result.stderr, /refus.*scaffold/i);
      assert.match(result.stderr, /--module.*scratch/i);
      assert.doesNotMatch(result.stderr, /Cannot find TLC/);
      assert.doesNotMatch(result.stdout, /Wrote /);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
}

test("from-chart reuses an existing model and preserves its authored config and mapping", () => {
  const dir = mkdtempSync(join(tmpdir(), "statechart-scaffold-"));
  try {
    writeFileSync(join(dir, "flow.mmd"), chart);
    writeFileSync(join(dir, "Flow.tla"), "---- MODULE Flow ----\nVARIABLE done\n====\n");
    writeFileSync(join(dir, "Flow.cfg"), "authored config\n");
    writeFileSync(join(dir, "Flow.map.mjs"), "// authored mapping\n");
    const before = snapshot(dir);
    const result = run(dir);
    assert.equal(result.error, undefined);
    assert.equal(result.status, 2, result.stdout + result.stderr);
    assert.match(result.stdout, /Kept Flow\.tla/);
    assert.match(result.stderr, /Cannot find TLC/);
    assert.deepEqual(snapshot(dir), before);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
