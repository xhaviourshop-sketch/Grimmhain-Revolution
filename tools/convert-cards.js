// convert-cards.js — Einmal-Konvertierung der Karten-Illustrationen PNG -> webp (q82),
// längste Kante auf 1400px begrenzt, Seitenverhältnis erhalten. PNG wird nach Erfolg gelöscht.
// Nur Bilddateien; keine Code-/Datenänderung. (Referenzen .png->.webp separat im Code.)
"use strict";
const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const DIRS = ["assets/cards/de", "assets/cards/en"];
const MAXEDGE = 1400, Q = 82;

(async () => {
  let before = 0, after = 0, n = 0;
  const fail = [];
  for (const dir of DIRS) {
    const root = path.join(__dirname, "..", dir);
    const pngs = fs.readdirSync(root).filter(f => /\.png$/i.test(f));
    for (const f of pngs) {
      const src = path.join(root, f);
      const out = path.join(root, f.replace(/\.png$/i, ".webp"));
      const sz = fs.statSync(src).size;
      try {
        await sharp(src)
          .resize({ width: MAXEDGE, height: MAXEDGE, fit: "inside", withoutEnlargement: true })
          .webp({ quality: Q })
          .toFile(out);
        const osz = fs.statSync(out).size;
        if (osz > 1000) { fs.unlinkSync(src); before += sz; after += osz; n++; }
        else { fs.unlinkSync(out); fail.push(f + " (output too small)"); }
      } catch (e) { fail.push(f + ": " + e.message); }
    }
  }
  console.log(`[convert-cards] ${n} Karten: ${(before / 1048576).toFixed(0)}MB PNG -> ${(after / 1048576).toFixed(1)}MB webp`);
  if (fail.length) { console.log("[convert-cards] FEHLER:", fail); process.exit(1); }
})();
