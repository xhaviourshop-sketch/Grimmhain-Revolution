// Regression test for the automatic update of the web build (godot/web/shell.html + godot/web/service-worker.js).
// Run: node --test tests/web-update.test.js
// Needs playwright-core (npm i -g playwright-core) and a Chromium (env CHROME, else the newest one in the Playwright cache).
//
// Occasion (06.10.2026): after four deploys a desktop Chrome still showed the build of the first deploy. Godot's service worker served
// index.js/wasm/pck cache first for 24 hours (browsers only re-check a service worker once a day on their own), while index.html came
// fresh from the network, so the version check in the page saw "same build" and did nothing. The engine here is a stub that fetches
// pck and wasm and registers the service worker only after starting, like Godot's Engine; page and service worker are the real files.
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const os = require("os");
const path = require("path");
const http = require("http");

const root = path.resolve(__dirname, "..");
const fixtures = path.join(__dirname, "fixtures", "web-update");

function loadPlaywright() {
  const candidates = ["playwright-core", path.join(process.env.APPDATA || "", "npm", "node_modules", "playwright-core"), process.env.PLAYWRIGHT_CORE || ""];
  for (const c of candidates) {
    if (!c) continue;
    try { return require(c); } catch (e) { /* try next */ }
  }
  throw new Error("playwright-core not found: run `npm i -g playwright-core`");
}

function findChrome() {
  if (process.env.CHROME) return process.env.CHROME;
  const cache = path.join(process.env.LOCALAPPDATA || path.join(os.homedir(), "AppData", "Local"), "ms-playwright");
  const dirs = fs.existsSync(cache) ? fs.readdirSync(cache).filter((d) => /^chromium-\d+$/.test(d)).sort((a, b) => parseInt(b.slice(9), 10) - parseInt(a.slice(9), 10)) : [];
  for (const d of dirs) {
    const exe = path.join(cache, d, "chrome-win64", "chrome.exe");
    if (fs.existsSync(exe)) return exe;
  }
  throw new Error("no Chromium found: set CHROME or run `npx playwright-core install chromium`");
}

// A deploy: "new" = current shell.html and service-worker.js, "old" = the files of 8e5ea14 (Godot's patched service worker).
function writeDeploy(dir, kind, id) {
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  const config = JSON.stringify({ args: [], executable: "index", serviceWorker: "index.service.worker.js", ensureCrossOriginIsolationHeaders: true });
  const shell = fs.readFileSync(kind === "new" ? path.join(root, "godot", "web", "shell.html") : path.join(fixtures, "old-shell.html"), "utf8");
  const html = shell.replace(/\r\n/g, "\n").replace("$GODOT_PROJECT_NAME", "Grimmhain").replace("$GODOT_HEAD_INCLUDE", "").replace("$GODOT_SPLASH_CLASSES", "")
    .replace("$GODOT_SPLASH_COLOR", "#000").replace("$GODOT_SPLASH", "index.png").replace("$GODOT_URL", "index.js").replace("$GODOT_CONFIG", config)
    .replace("$GODOT_THREADS_ENABLED", "false").replace("___BUILD_ID___", id);
  fs.writeFileSync(path.join(dir, "index.html"), html);
  const sw = kind === "new"
    ? fs.readFileSync(path.join(root, "godot", "web", "service-worker.js"), "utf8").replace("___BUILD_ID___", id)
    : fs.readFileSync(path.join(fixtures, "old-service-worker.js"), "utf8").replace(/const CACHE_VERSION = '[^']*'/, `const CACHE_VERSION = '${id}'`);
  fs.writeFileSync(path.join(dir, "index.service.worker.js"), sw);
  fs.writeFileSync(path.join(dir, "version.json"), JSON.stringify({ id }));
  for (const f of ["index.offline.html", "index.icon.png", "index.apple-touch-icon.png", "index.audio.worklet.js", "index.audio.position.worklet.js", "index.png", "index.manifest.json"]) {
    fs.writeFileSync(path.join(dir, f), "static-" + f);
  }
  fs.writeFileSync(path.join(dir, "index.pck"), "pck-" + id);
  fs.writeFileSync(path.join(dir, "index.wasm"), "wasm-" + id);
  fs.writeFileSync(path.join(dir, "index.js"), `window.__indexJsId = '${id}';
window.Engine = class {
  constructor(config) { this.config = config; }
  static getMissingFeatures() { return []; }
  installServiceWorker() { return navigator.serviceWorker.register(this.config.serviceWorker); }
  async startGame() {
    window.__pck = await fetch('index.pck').then((r) => r.text());
    window.__wasm = await fetch('index.wasm').then((r) => r.text());
    window.__started = true;
    this.installServiceWorker();
  }
};
`);
}

// Static server with the cache headers of godot/web/vercel.json.
function startServer(state) {
  const noCache = new Set(["/", "/index.html", "/index.service.worker.js", "/index.manifest.json", "/index.offline.html"]);
  const server = http.createServer((req, res) => {
    if (state.offline) return req.socket.destroy();
    const urlPath = decodeURIComponent(req.url.split("?")[0]);
    const file = path.join(state.dir, urlPath === "/" ? "index.html" : urlPath);
    if (!fs.existsSync(file) || !fs.statSync(file).isFile()) { res.writeHead(404); return res.end(); }
    const types = { ".html": "text/html", ".js": "text/javascript", ".json": "application/json" };
    res.writeHead(200, {
      "Content-Type": types[path.extname(file)] || "application/octet-stream",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cache-Control": urlPath === "/version.json" ? "no-cache, no-store" : noCache.has(urlPath) ? "no-cache" : "public, max-age=0, must-revalidate",
    });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Opens the page like a user would and returns what actually started once the service worker has settled.
async function openApp(context, url) {
  const page = await context.newPage();
  let navigations = 0;
  page.on("framenavigated", (frame) => { if (frame === page.mainFrame()) navigations++; });
  await page.goto(url).catch(() => {});
  let result = null;
  for (let round = 0; round < 4; round++) { // an old page may start first and reload a moment later: take the state once no reload follows
    const seen = navigations;
    result = null;
    for (let i = 0; i < 75 && !result; i++) {
      result = await page.evaluate(() => (window.__started ? { indexJs: window.__indexJsId, pck: window.__pck, wasm: window.__wasm } : null)).catch(() => null);
      if (!result) await sleep(200);
    }
    assert.ok(result, "the app did not start within 15 s");
    await sleep(1500);
    if (navigations === seen) break;
  }
  for (let i = 0; i < 25; i++) { // wait until the freshly registered service worker is active and has its cache
    const settled = await page.evaluate(async () => {
      const reg = await navigator.serviceWorker.getRegistration();
      return !!(reg && reg.active && reg.active.state === "activated" && (await caches.keys()).length > 0);
    }).catch(() => false);
    if (settled) break;
    await sleep(200);
  }
  await sleep(500);
  await page.close();
  return { ...result, navigations };
}

async function visits(context, url, count) {
  for (let i = 0; i < count; i++) await openApp(context, url);
}

function expectBuild(result, id) {
  assert.equal(result.indexJs, id, "engine script of the old build");
  assert.equal(result.pck, "pck-" + id, "game data of the old build");
  assert.equal(result.wasm, "wasm-" + id, "engine binary of the old build");
}

test("web update: a new deploy shows up after opening once", async (t) => {
  const { chromium } = loadPlaywright();
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "grimmhain-web-update-"));
  const state = { dir: "", offline: false };
  const server = await startServer(state);
  const base = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch({ executablePath: findChrome(), headless: true });
  t.after(async () => { await browser.close(); server.close(); fs.rmSync(tmp, { recursive: true, force: true }); });

  const deploy = (name, kind, id) => { const dir = path.join(tmp, name); writeDeploy(dir, kind, id); state.dir = dir; };

  for (const start of ["/", "/index.html"]) {
    await t.test(`old Godot service worker, new deploy, start at ${start}`, { timeout: 120000 }, async () => {
      const context = await browser.newContext();
      deploy("old" + start.length, "old", "A-old");
      await visits(context, base + start, 3);
      deploy("new" + start.length, "new", "B-new");
      const first = await openApp(context, base + start);
      expectBuild(first, "B-new");
      assert.ok(first.navigations <= 2, `too many page loads: ${first.navigations}`);
      const second = await openApp(context, base + start);
      expectBuild(second, "B-new");
      assert.equal(second.navigations, 1, "reloaded again although up to date");
      await context.close();
    });

    await t.test(`new service worker, next deploy, start at ${start}`, { timeout: 120000 }, async () => {
      const context = await browser.newContext();
      deploy("b" + start.length, "new", "B-new");
      await visits(context, base + start, 3);
      deploy("c" + start.length, "new", "C-new");
      const first = await openApp(context, base + start);
      expectBuild(first, "C-new");
      assert.ok(first.navigations <= 2, `too many page loads: ${first.navigations}`);
      const second = await openApp(context, base + start);
      expectBuild(second, "C-new");
      assert.equal(second.navigations, 1, "reloaded again although up to date");
      await context.close();
    });
  }

  await t.test("offline: the last build keeps starting", { timeout: 120000 }, async () => {
    const context = await browser.newContext();
    deploy("offline", "new", "D-new");
    await visits(context, base + "/", 3);
    state.offline = true;
    for (const start of ["/", "/index.html"]) {
      const result = await openApp(context, base + start);
      expectBuild(result, "D-new");
      assert.equal(result.navigations, 1);
    }
    state.offline = false;
    await context.close();
  });
});
