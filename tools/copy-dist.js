// copy-dist.js — schlanker "Build" ohne Bundler: kopiert NUR die Laufzeit-Assets nach dist/.
// dist/ ist der Capacitor-webDir (der Repo-Root ist unsauber: node_modules, .git, tools, tests,
// android/, ios/ ...). Quell-Dateien werden NICHT verändert; dist/ ist ein reines Artefakt.
//
// Offline-Härtung: in der KOPIE von game.html wird der Google-Fonts-Loader neutralisiert
// (lokale Schrift via grimm-file-protocol), damit zur Laufzeit kein CDN/Netz angefasst wird.
// Die Quell-game.html bleibt unverändert.
"use strict";
const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const dist = path.join(root, "dist");

// Whitelist der Laufzeit-Assets (alles andere bleibt draußen)
const ITEMS = ["index.html", "setup.html", "game.html", "manifest.json", "sw.js", "css", "js", "assets"];

fs.rmSync(dist, { recursive: true, force: true });
fs.mkdirSync(dist, { recursive: true });

const copied = [];
for (const it of ITEMS) {
  const src = path.join(root, it);
  if (fs.existsSync(src)) { fs.cpSync(src, path.join(dist, it), { recursive: true }); copied.push(it); }
}

// --- Offline-Härtung der dist-game.html (Quelle bleibt unangetastet) ---
// Ersetzt den protokollabhängigen Google-Fonts-Block durch reinen Lokal-Schrift-Modus.
const gameHtmlPath = path.join(dist, "game.html");
if (fs.existsSync(gameHtmlPath)) {
  let html = fs.readFileSync(gameHtmlPath, "utf8");
  const before = html;
  // Der gesamte IIFE-Block, der bei http/https Google-Fonts per document.write lädt
  // und nur bei file:// lokale Schrift aktiviert -> ersetzen durch: immer lokale Schrift.
  html = html.replace(
    /\(function \(\) \{\s*var p = location\.protocol;[\s\S]*?\}\)\(\);/,
    "/* offline build: immer lokale Schrift, kein CDN */\n  document.documentElement.classList.add('grimm-file-protocol');"
  );
  if (html !== before) {
    fs.writeFileSync(gameHtmlPath, html, "utf8");
    console.log("[copy-dist] game.html: Google-Fonts-Loader für Offline neutralisiert (Quelle unverändert).");
  } else {
    console.warn("[copy-dist] WARN: Google-Fonts-Block in game.html nicht gefunden (Muster prüfen).");
  }
}

console.log("[copy-dist] dist/ enthält:", copied.join(", "));
