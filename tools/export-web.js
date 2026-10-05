#!/usr/bin/env node
// Web export with build identification and forced updates.
// 1. writes godot/build_info.json (date, short commit hash, id) so the start screen shows the build, removed again afterwards
// 2. runs the Godot web export (preset "Web", target see godot/export_presets.cfg)
// 3. stamps the build id into index.html, writes version.json, lets the service worker take over at once (skipWaiting, claim)
// 4. copies godot/web/vercel.json (no-cache for html, service worker, manifest, version.json) next to the export
// Usage: node tools/export-web.js        Godot binary: GODOT_BIN, else the pinned Windows console build in Downloads, else `godot`.
const { execSync, spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const project = path.join(root, "godot");
const out = "C:/Users/Marku/Downloads/Grimmhain-iPad-Web";
const sh = (c) => execSync(c, { cwd: root, encoding: "utf8" }).trim();

const hash = sh("git rev-parse --short=7 HEAD");
const dirty = sh("git status --porcelain --untracked-files=no") !== "";
const now = new Date();
const p2 = (n) => String(n).padStart(2, "0");
const date = `${p2(now.getDate())}.${p2(now.getMonth() + 1)}.`;
const shownHash = dirty ? hash + "*" : hash;
const id = `${now.getFullYear()}${p2(now.getMonth() + 1)}${p2(now.getDate())}${p2(now.getHours())}${p2(now.getMinutes())}-${shownHash}`;
const infoPath = path.join(project, "build_info.json");

function godotBin() {
  if (process.env.GODOT_BIN) return process.env.GODOT_BIN;
  const win = path.join(process.env.USERPROFILE || "", "Downloads", "Godot_v4.7.2-stable_win64.exe", "Godot_v4.7.2-stable_win64_console.exe");
  return fs.existsSync(win) ? win : "godot";
}

fs.writeFileSync(infoPath, JSON.stringify({ date, hash: shownHash, id }));
try {
  const r = spawnSync(godotBin(), ["--headless", "--path", project, "--export-release", "Web"], { encoding: "utf8", maxBuffer: 1 << 28 });
  const log = (r.stdout || "") + (r.stderr || "");
  if (r.status !== 0 || /ERROR:/.test(log)) {
    console.error(log.split(/\r?\n/).filter((l) => /ERROR/.test(l)).slice(0, 5).join("\n") || "export failed");
    process.exit(1);
  }
} finally {
  fs.rmSync(infoPath, { force: true });
}

const htmlPath = path.join(out, "index.html");
let html = fs.readFileSync(htmlPath, "utf8");
if (!html.includes("___BUILD_ID___")) { console.error("index.html lacks the ___BUILD_ID___ placeholder (web/shell.html)"); process.exit(1); }
fs.writeFileSync(htmlPath, html.replace("___BUILD_ID___", id));
fs.writeFileSync(path.join(out, "version.json"), JSON.stringify({ id, date, hash: shownHash }));

const swPath = path.join(out, "index.service.worker.js");
let sw = fs.readFileSync(swPath, "utf8");
const a = "event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));";
const b = "self.addEventListener('activate', (event) => {";
if (!sw.includes(a) || !sw.includes(b)) { console.error("service worker template changed, patch needs an update"); process.exit(1); }
sw = sw.replace(a, "self.skipWaiting();\n\t" + a).replace(b, b + "\n\tevent.waitUntil(self.clients.claim());");
fs.writeFileSync(swPath, sw);
fs.copyFileSync(path.join(project, "web", "vercel.json"), path.join(out, "vercel.json"));
// Optional loading screen background: godot/assets/ui/ladebild.png is shown by web/shell.html while the game loads (no file, no change).
const loadingImage = path.join(project, "assets", "ui", "ladebild.png");
fs.rmSync(path.join(out, "ladebild.png"), { force: true });
if (fs.existsSync(loadingImage)) fs.copyFileSync(loadingImage, path.join(out, "ladebild.png"));
console.log(`export ok: ${id}  pck ${fs.statSync(path.join(out, "index.pck")).size} bytes`);
