#!/usr/bin/env node
// Brand check for GDScript (docs/brand/MARKE.md: kein Gold, Farben nur aus Theme-Tokens).
// Flags in godot/**/*.gd outside godot/app/theme/, godot/tests/, godot/tools/ and godot/asset_lab/:
//   - fixed color literals: Color("#..."), Color(r, g, b[, a]), Color8(...)
//   - the identifier GOLD (any GOLD_* constant) and the house gold hex #c9a84c
// Usage: node tools/check-brand.js <file.gd>...   |   node tools/check-brand.js --hook  (Claude Code PostToolUse, JSON on stdin)
// Prints only violations; exit 1 on violation (exit 2 with --hook so the message reaches Claude), 0 otherwise.
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const EXEMPT = ["godot/app/theme/", "godot/tests/", "godot/tools/", "godot/asset_lab/", "godot/addons/"];

function check(file) {
  const rel = path.relative(root, path.resolve(file)).split(path.sep).join("/");
  if (!rel.startsWith("godot/") || !rel.endsWith(".gd") || EXEMPT.some((e) => rel.startsWith(e)) || !fs.existsSync(file)) return [];
  const out = [];
  fs.readFileSync(file, "utf8").split(/\r?\n/).forEach((raw, i) => {
    const line = raw.replace(/\s##.*$|\s#.*$/, "").replace(/^\s*#.*$/, "");
    if (/\bColor8?\(\s*["'\d.]/.test(line)) out.push(`${rel}:${i + 1}: feste Farbe, Theme-Token (ThemeTokens.*) verwenden`);
    if (/\bGOLD\w*\b|#c9a84c/i.test(line) && !/^\s*#/.test(raw)) out.push(`${rel}:${i + 1}: Gold ist in der Marke ausgeschlossen (MARKE.md)`);
  });
  return out;
}

const args = process.argv.slice(2);
let files = args.filter((a) => a !== "--hook");
if (args.includes("--hook")) {
  let input = "";
  try { input = fs.readFileSync(0, "utf8"); } catch { process.exit(0); }
  try { const j = JSON.parse(input); const f = (j.tool_input || {}).file_path; files = f ? [f] : []; } catch { process.exit(0); }
}
const problems = files.flatMap(check);
if (problems.length) {
  console.error("Marken-Check:\n" + problems.join("\n"));
  process.exit(args.includes("--hook") ? 2 : 1);
}
