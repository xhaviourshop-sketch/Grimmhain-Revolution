/**
 * Copies the legacy game-logic scripts from the repo root (single source of
 * truth: ../js) into app/public/legacy/ so the React shell can load them as
 * classic scripts at runtime. The copies are build artifacts (gitignored) —
 * NEVER edit them; edit the originals in /js instead.
 *
 * Order matters and mirrors game.html <head>.
 */
import {
  copyFileSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  statSync,
  writeFileSync
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..", "..");
const outDir = resolve(here, "..", "public", "legacy");

/** load order identical to game.html (minus field-pixi/touch-tooltips: the
 *  React shell brings its own board + tooltips) */
export const LEGACY_FILES = [
  "js/core/i18n.js",
  "js/core/roles.js",
  "js/core/akte.js",
  "js/core/role-abilities.js",
  "js/core/cards.js",
  "js/core/state.js",
  "js/ui/core.js",
  "js/ui/audio.js",
  "js/ui/ui.js",
  "js/ui/field-viewmodel.js",
  "js/core/abilities-helpers.js",
  "js/core/abilities-roles-chunk.js",
  "js/core/abilities.js",
  "js/core/night.js",
  "js/ui/gamelog.js"
];

mkdirSync(outDir, { recursive: true });
for (const rel of LEGACY_FILES) {
  const src = join(repoRoot, rel);
  const dst = join(outDir, rel.replaceAll("/", "__"));
  copyFileSync(src, dst);
}
// manifest consumed by the runtime loader (keeps order in ONE place)
writeFileSync(
  join(outDir, "manifest.json"),
  JSON.stringify(LEGACY_FILES.map((f) => f.replaceAll("/", "__")), null, 2)
);
console.log(`[sync-legacy] ${LEGACY_FILES.length} Dateien -> app/public/legacy/`);

// ── second bundle: canonical vanilla preparation pages ──
// index.html + setup.html become the real entry (splash → dashboard → roles).
// They deal a round into localStorage (uw_custom_v16 + grimmhain_akt) and then
// hand off to the React board. Served from app/public/legacy-setup/, STRUCTURE-
// PRESERVING because the pages load js/assets by RELATIVE path (not flattened).
// Production vanilla is only read, copied and transformed-IN-COPY — never edited.
const prepDir = resolve(here, "..", "public", "legacy-setup");
// union of <script src> across index.html (4) + setup.html (5)
const PREP_JS = [
  "js/core/i18n.js",
  "js/core/roles.js",
  "js/core/akte.js",
  "js/core/cards.js",
  "js/core/state.js"
];
// asset dirs referenced by the pages' inline CSS / markup (fonts, backgrounds, logos)
const PREP_ASSET_DIRS = ["assets/fonts", "assets/icons/setup", "assets/icons/app"];
const PREP_PAGES = ["index.html", "setup.html"];
// where the bundled pages jump instead of game.html. Relative to /legacy-setup/
// so it resolves to the React app root in dev AND the file:// build. from=setup
// makes the board boot the freshly written localStorage round and skip the React
// setup screen.
const BOARD_URL = "../index.html?adapter=legacy&from=setup";

function copyDirRec(rel) {
  const srcDir = join(repoRoot, rel);
  const dstDir = join(prepDir, rel);
  mkdirSync(dstDir, { recursive: true });
  for (const entry of readdirSync(srcDir)) {
    const s = join(srcDir, entry);
    if (statSync(s).isDirectory()) copyDirRec(join(rel, entry));
    else copyFileSync(s, join(dstDir, entry));
  }
}

mkdirSync(prepDir, { recursive: true });
for (const rel of PREP_JS) {
  const dst = join(prepDir, rel);
  mkdirSync(dirname(dst), { recursive: true });
  copyFileSync(join(repoRoot, rel), dst);
}
for (const d of PREP_ASSET_DIRS) copyDirRec(d);
for (const page of PREP_PAGES) {
  const src = readFileSync(join(repoRoot, page), "utf8");
  // RISK-2 HARD GUARD: the nav target MUST exist in the source, else the bundled
  // page would silently dead-end at a non-existent game.html. Fail the build.
  if (!src.includes("game.html")) {
    throw new Error(
      `[sync-legacy] ${page}: navigation target 'game.html' not found — the ` +
        `vanilla source changed; fix the nav transform before bundling.`
    );
  }
  // 'setup.html' stays relative (same bundled dir); only 'game.html' → React board
  writeFileSync(join(prepDir, page), src.split("game.html").join(BOARD_URL));
}
console.log(`[sync-legacy] prep pages -> app/public/legacy-setup/ (${PREP_PAGES.join(", ")})`);

// ── role cards (de/en) for the ActionCenter card overlay ──
// served at /assets/cards/{de,en}/<file>.webp; structure-preserving copy from the
// repo's card assets. gitignored (≈22 MB), re-synced here on every dev/build.
const cardsSrc = join(repoRoot, "assets", "cards");
const cardsDst = resolve(here, "..", "public", "assets", "cards");
function copyTree(src, dst) {
  mkdirSync(dst, { recursive: true });
  for (const entry of readdirSync(src)) {
    const s = join(src, entry);
    const d = join(dst, entry);
    if (statSync(s).isDirectory()) copyTree(s, d);
    else copyFileSync(s, d);
  }
}
try {
  copyTree(cardsSrc, cardsDst);
  console.log("[sync-legacy] role cards -> app/public/assets/cards/ (de, en)");
} catch (e) {
  console.warn("[sync-legacy] role cards not copied:", e.message);
}
