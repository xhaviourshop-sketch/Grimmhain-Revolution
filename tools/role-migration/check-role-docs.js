#!/usr/bin/env node
// Konsistenzprüfung für docs/role-migration/ (nur lesen, ändert keine Datei).
//
// Aufruf aus dem Repository-Wurzelordner:
//   node tools/role-migration/check-role-docs.js
// Exit-Code 0 = keine Fehler, 1 = mindestens ein Fehler.
//
// Geprüft wird:
//  1. Kanonischer Katalog (01) enthält jede Rolle aus ALL_ROLES (js/core/roles.js) genau einmal,
//     IDs entsprechen dem Schema aus DR-01 (deutsches ASCII-kebab-case).
//  2. Die 11 Godot-Rollen aus RoleCatalog.ROLES sind in 01 und 02 als implemented-and-tested markiert.
//  3. 03 enthält für jede nicht umgesetzte Rolle genau einen Abschnitt, 02 für jede umgesetzte.
//  4. Rollenlisten (Zeilen „**Rollen …:**“) in 05 und 06 nennen nur Katalog-IDs, ohne Duplikate,
//     und die angegebene Anzahl stimmt. In 06 kommt jede nicht umgesetzte Rolle in genau einer Charge vor.
//  5. Entscheidungs-IDs RM-DR-### in 08 sind eindeutig; alle in anderen Dokumenten zitierten existieren.
//  6. Konflikt-IDs RM-C-### (erste Tabellenspalte in 04) sind eindeutig; zitierte existieren.
//  7. Statuswerte in Backticks stammen aus dem definierten Statusmodell.
//  8. Relative Markdown-Links zeigen auf existierende Dateien.
//  9. Rollenzahlen in 01 (Summenzeile) stimmen mit dem Katalog überein.
// 10. In Backticks zitierte Repository-Pfade (auch in dossiers/) existieren.
// 11. decision-status.csv: gültige IDs und Status, „entschieden“ nur mit Quelle, deckungsgleich mit
//     den Einträgen und Teilfragen in 08; Statustabelle in 08 stimmt; Fragerunde in 10 enthält nur
//     Produktentscheidungen, und jede offene Produktentscheidung ist in 10 genannt.

"use strict";

// Zeilen einer CSV-Datei, unabhängig von LF/CRLF (Windows-Checkout mit `* text=auto`).
// trim() entfernt wie bisher auch ein führendes UTF-8-BOM.
function csvLines(text) {
  return text.trim().split(/\r?\n/);
}

// Beim Laden per require (Regressionstest) nur die Hilfsfunktion bereitstellen, keine Prüfung starten.
if (require.main !== module) {
  module.exports = { csvLines };
  return;
}

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..", "..");
const DOCS = path.join(ROOT, "docs", "role-migration");
const errors = [];
const notes = [];
const err = (m) => errors.push(m);

function read(rel) {
  return fs.readFileSync(path.join(ROOT, rel), "utf8");
}

function slug(name) {
  return name
    .toLowerCase()
    .replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss")
    .replace(/\./g, "")
    .replace(/\s+/g, "-");
}

// --- Quellen ---------------------------------------------------------------
const rolesJs = read("js/core/roles.js");
const allRoles = JSON.parse(rolesJs.match(/const ALL_ROLES=(\[[^\]]*\])/)[1]);
const legacyIds = allRoles.map(slug);

const catalogGd = read("godot/core/rules/role_catalog.gd");
const constToId = {};
for (const m of catalogGd.matchAll(/^const ([A-Z_]+) := &"([a-z-]+)"/gm)) constToId[m[1]] = m[2];
const rolesBlock = catalogGd.slice(catalogGd.indexOf("const ROLES := {"));
const godotIds = [...rolesBlock.slice(0, rolesBlock.indexOf("\n}")).matchAll(/^\t([A-Z_]+): \{/gm)].map((m) => constToId[m[1]]);

const STATUS = [
  "implemented-and-tested", "implemented-partial", "documented-only",
  "legacy-verified", "legacy-contradictory", "legacy-broken",
  "decision-required", "not-found", "deferred",
];
const AUTOMATION = ["automatic", "assisted", "manual-only", "unknown"];

const docFiles = fs.readdirSync(DOCS).filter((f) => f.endsWith(".md")).sort();
const docs = Object.fromEntries(docFiles.map((f) => [f, fs.readFileSync(path.join(DOCS, f), "utf8")]));
const need = (prefix) => {
  const f = docFiles.find((x) => x.startsWith(prefix));
  if (!f) err(`Dokument ${prefix}-*.md fehlt`);
  return f ? docs[f] : "";
};

// --- 1. Katalog --------------------------------------------------------------
const cat = need("01");
const rows = [...cat.matchAll(/^\| (\d+) \| `([a-z0-9-]+)` \| ([^|]+) \|/gm)];
const catIds = rows.map((m) => m[2]);
const catNames = Object.fromEntries(rows.map((m) => [m[2], m[3].trim()]));
const dup = catIds.filter((id, i) => catIds.indexOf(id) !== i);
if (dup.length) err(`01: doppelte IDs im Katalog: ${[...new Set(dup)].join(", ")}`);
for (const id of legacyIds) if (!catIds.includes(id)) err(`01: Legacy-Rolle fehlt im Katalog: ${id}`);
for (const id of catIds) if (!legacyIds.includes(id)) err(`01: Katalog-ID ohne Legacy-Rolle: ${id}`);
for (const id of catIds) if (!/^[a-z]+(-[a-z]+)*$/.test(id)) err(`01: ID verletzt DR-01: ${id}`);
allRoles.forEach((n) => {
  const id = slug(n);
  if (catNames[id] && !catNames[id].includes(n)) err(`01: Anzeigename von ${id} enthält nicht den Legacy-Namen „${n}“`);
});
const nums = rows.map((m) => Number(m[1]));
if (nums.some((n, i) => n !== i + 1)) err("01: laufende Nummern im Katalog nicht fortlaufend");
notes.push(`Katalog: ${catIds.length} Rollen, ALL_ROLES: ${allRoles.length}, RoleCatalog (Godot): ${godotIds.length}`);

const sumLine = cat.match(/<!-- check:counts total=(\d+) implemented=(\d+) remaining=(\d+) -->/);
if (!sumLine) err("01: Zählmarke <!-- check:counts ... --> fehlt");
else {
  const [total, impl, rem] = sumLine.slice(1).map(Number);
  if (total !== catIds.length) err(`01: total=${total}, Katalog hat ${catIds.length}`);
  if (impl !== godotIds.length) err(`01: implemented=${impl}, RoleCatalog hat ${godotIds.length}`);
  if (rem !== catIds.length - godotIds.length) err(`01: remaining=${rem} passt nicht`);
}

// --- 2. Godot-Rollen korrekt markiert ------------------------------------------
for (const id of godotIds) {
  if (!catIds.includes(id)) err(`Godot-Rolle ${id} fehlt im Katalog`);
  const row = cat.split("\n").find((l) => l.startsWith("| ") && l.includes(`| \`${id}\` |`));
  if (row && !row.includes("`implemented-and-tested`")) err(`01: ${id} ist im RoleCatalog, aber nicht als implemented-and-tested markiert`);
}
for (const id of catIds.filter((x) => !godotIds.includes(x))) {
  const row = cat.split("\n").find((l) => l.startsWith("| ") && l.includes(`| \`${id}\` |`));
  if (row && /`implemented-(and-tested|partial)`/.test(row)) err(`01: ${id} ist nicht im RoleCatalog, aber als implementiert markiert`);
}
const audit = need("02");
for (const id of godotIds) {
  const row = audit.split("\n").find((l) => l.startsWith("| ") && l.includes(`| \`${id}\` |`));
  if (!row) err(`02: Übersichtszeile für ${id} fehlt`);
  else if (!row.includes("`implemented-and-tested`")) err(`02: ${id} nicht als implemented-and-tested markiert`);
  if (!new RegExp("^### \\d+\\.\\d+ `" + id + "`$", "m").test(audit)) err(`02: Abschnitt für ${id} fehlt`);
}
const remaining = catIds.filter((x) => !godotIds.includes(x));

// --- 3. Detailabschnitte in 03 -------------------------------------------------
const rem = need("03");
for (const id of catIds) {
  const n = [...rem.matchAll(new RegExp("^### `" + id + "`", "gm"))].length;
  if (remaining.includes(id) && n !== 1) err(`03: Abschnitt für ${id} kommt ${n}-mal vor (erwartet 1)`);
  if (godotIds.includes(id) && n !== 0) err(`03: umgesetzte Rolle ${id} hat einen Abschnitt`);
}

// --- 4. Rollenlisten in 05 und 06 ---------------------------------------------
function roleLists(text, file) {
  const out = [];
  for (const m of text.matchAll(/^\*\*Rollen ([^*:]+?)(?: \((\d+)\))?:\*\* (.+)$/gm)) {
    const ids = [...m[3].matchAll(/`([a-z0-9-]+)`/g)].map((x) => x[1]);
    const label = m[1].trim();
    for (const id of ids) if (!catIds.includes(id)) err(`${file}: „${label}“ nennt unbekannte Rolle ${id}`);
    const d = ids.filter((id, i) => ids.indexOf(id) !== i);
    if (d.length) err(`${file}: „${label}“ enthält Duplikate: ${d.join(", ")}`);
    if (m[2] && Number(m[2]) !== ids.length) err(`${file}: „${label}“ gibt ${m[2]} an, nennt ${ids.length}`);
    out.push({ label, ids });
  }
  return out;
}
const f05 = docFiles.find((x) => x.startsWith("05"));
const opts = f05 ? roleLists(docs[f05], f05) : [];
for (const [name, size] of [["Option A", 20], ["Option B", 25], ["Option C", 30]]) {
  const o = opts.find((x) => x.label === name);
  if (!o) err(`05: Rollenliste „${name}“ fehlt`);
  else {
    if (o.ids.length !== size) err(`05: ${name} hat ${o.ids.length} statt ${size} Rollen`);
    for (const id of godotIds) if (!o.ids.includes(id)) err(`05: ${name} enthält die umgesetzte Rolle ${id} nicht`);
  }
}
const oa = opts.find((x) => x.label === "Option A");
const ob = opts.find((x) => x.label === "Option B");
const oc = opts.find((x) => x.label === "Option C");
if (oa && ob && oa.ids.some((id) => !ob.ids.includes(id))) err("05: Option A ist keine Teilmenge von Option B");
if (ob && oc && ob.ids.some((id) => !oc.ids.includes(id))) err("05: Option B ist keine Teilmenge von Option C");

const f06 = docFiles.find((x) => x.startsWith("06"));
const batches = f06 ? roleLists(docs[f06], f06).filter((x) => x.label.startsWith("Charge")) : [];
if (f06 && !batches.length) err("06: keine Chargen-Rollenlisten gefunden");
const seen = {};
for (const b of batches) for (const id of b.ids) {
  if (godotIds.includes(id)) err(`06: ${b.label} enthält bereits umgesetzte Rolle ${id}`);
  (seen[id] = seen[id] || []).push(b.label);
}
for (const id of remaining) {
  if (!seen[id]) err(`06: nicht umgesetzte Rolle ${id} ist keiner Charge zugeordnet`);
  else if (seen[id].length > 1) err(`06: ${id} steht in mehreren Chargen: ${seen[id].join(", ")}`);
}
notes.push(`Chargen: ${batches.length}, zugeordnete Rollen: ${Object.keys(seen).length}/${remaining.length}`);

// --- 5./6. Entscheidungs- und Konflikt-IDs ------------------------------------
function idCheck(prefix, docPrefix, re, headRe) {
  const d = need(docPrefix);
  const defs = [...d.matchAll(headRe)].map((m) => m[1]);
  const dd = defs.filter((x, i) => defs.indexOf(x) !== i);
  if (dd.length) err(`${docPrefix}: doppelte ${prefix}-IDs: ${[...new Set(dd)].join(", ")}`);
  for (const [f, t] of Object.entries(docs)) {
    for (const m of t.matchAll(re)) if (!defs.includes(m[0])) err(`${f}: zitiert unbekannte ID ${m[0]}`);
  }
  return defs;
}
const drs = idCheck("RM-DR", "08", /RM-DR-\d{3}/g, /^## (RM-DR-\d{3})\b/gm);
const cs = idCheck("RM-C", "04", /RM-C-\d{3}/g, /^\| (RM-C-\d{3}) \|/gm);
notes.push(`Entscheidungen: ${drs.length}, Konflikte: ${cs.length}`);

// --- 6b. Entscheidungsstatus (decision-status.csv, Konsolidierung) --------------
// Jede Zeile: id;teilfrage;rolle;status;quelle;hinweis. Status-Kürzel: E P T S Q.
const STATUS_NAMES = { E: "entschieden", P: "produktentscheidung", T: "technisch", S: "später", Q: "quellenprüfung" };
const csvPath = path.join(DOCS, "decision-status.csv");
const csvRows = [];
if (!fs.existsSync(csvPath)) err("decision-status.csv fehlt");
else {
  const lines = csvLines(fs.readFileSync(csvPath, "utf8"));
  if (lines[0] !== "id;teilfrage;rolle;status;quelle;hinweis") err("decision-status.csv: unerwarteter Kopf");
  for (const line of lines.slice(1)) {
    const cells = [];
    let cur = "", q = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (q) { if (ch === '"' && line[i + 1] === '"') { cur += '"'; i++; } else if (ch === '"') q = false; else cur += ch; }
      else if (ch === '"') q = true; else if (ch === ";") { cells.push(cur); cur = ""; } else cur += ch;
    }
    cells.push(cur);
    const [id, sub, role, status, src] = cells;
    if (!/^RM-DR-\d{3}(\.\d+)?$/.test(id)) err(`decision-status.csv: ungültige ID ${id}`);
    if (!STATUS_NAMES[status]) err(`decision-status.csv: ${id} hat unbekannten Status ${status}`);
    if (status === "E" && !src) err(`decision-status.csv: ${id} ist „entschieden“ ohne Quelle`);
    if ((sub === "ja") !== id.includes(".")) err(`decision-status.csv: ${id} Spalte teilfrage passt nicht zur ID`);
    csvRows.push({ id, sub: sub === "ja", role, status });
  }
  const dupCsv = csvRows.map((r) => r.id).filter((x, i, a) => a.indexOf(x) !== i);
  if (dupCsv.length) err(`decision-status.csv: doppelte IDs ${dupCsv.join(", ")}`);
  const csvIds = new Set(csvRows.map((r) => r.id));
  const entryIds = new Set(csvRows.map((r) => r.id.split(".")[0]));
  for (const d of drs) if (!entryIds.has(d)) err(`decision-status.csv: Eintrag ${d} aus 08 fehlt`);
  for (const d of entryIds) if (!drs.includes(d)) err(`decision-status.csv: ${d} hat keinen Abschnitt in 08`);
  // Teilfragen in 08: „- **RM-DR-155.3 · Titel** · Status: <name>…“
  const t08 = need("08");
  const subs08 = [...t08.matchAll(/^- \*\*(RM-DR-\d{3}\.\d+) · [^\n]*?\*\* · Status: ([a-zäöüß]+)/gm)];
  for (const m of subs08) {
    const row = csvRows.find((r) => r.id === m[1]);
    if (!row) err(`08: Teilfrage ${m[1]} fehlt in decision-status.csv`);
    else if (STATUS_NAMES[row.status] !== m[2]) err(`08: ${m[1]} Status „${m[2]}“, CSV „${STATUS_NAMES[row.status]}“`);
  }
  const roleSubsCsv = csvRows.filter((r) => r.sub && Number(r.id.slice(6, 9)) >= 100).map((r) => r.id);
  for (const id of roleSubsCsv) if (!subs08.some((m) => m[1] === id)) err(`08: Teilfrage ${id} aus decision-status.csv fehlt in 08`);
  // Zitierte Unter-IDs existieren
  for (const [f, t] of Object.entries(docs)) {
    for (const m of t.matchAll(/RM-DR-\d{3}\.\d+/g)) if (!csvIds.has(m[0])) err(`${f}: zitiert unbekannte Teilfrage ${m[0]}`);
  }
  // Statustabelle in 08 stimmt mit der CSV überein
  const PRIO = { P: 5, Q: 4, S: 3, T: 2, E: 1 };
  const entries = {};
  for (const r of csvRows) {
    const e = r.id.split(".")[0];
    if (!entries[e] || PRIO[r.status] > PRIO[entries[e]]) entries[e] = r.status;
  }
  const countE = {}, countQ = {};
  for (const s of Object.values(entries)) countE[s] = (countE[s] || 0) + 1;
  for (const r of csvRows) countQ[r.status] = (countQ[r.status] || 0) + 1;
  const tbl = t08.slice(t08.indexOf("<!-- check:decision-status -->"));
  if (!t08.includes("<!-- check:decision-status -->")) err("08: Marke <!-- check:decision-status --> fehlt");
  for (const [k, name] of Object.entries(STATUS_NAMES)) {
    const m = tbl.match(new RegExp("^\\| " + name + " \\| (\\d+) \\| (\\d+) \\|", "m"));
    if (!m) err(`08: Statuszeile „${name}“ fehlt`);
    else if (Number(m[1]) !== (countE[k] || 0) || Number(m[2]) !== (countQ[k] || 0)) err(`08: Statuszeile „${name}“ ${m[1]}/${m[2]}, CSV ${countE[k] || 0}/${countQ[k] || 0}`);
  }
  const tot = tbl.match(/^\| \*\*gesamt\*\* \| \*\*(\d+)\*\* \| \*\*(\d+)\*\* \|/m);
  if (!tot || Number(tot[1]) !== Object.keys(entries).length || Number(tot[2]) !== csvRows.length) err("08: Gesamtzeile der Statustabelle passt nicht zur CSV");
  // Erste Fragerunde in 10
  const f10 = docFiles.find((x) => x.startsWith("10"));
  if (!f10) err("10-next-decisions.md fehlt");
  else {
    const t10 = docs[f10];
    const mk = t10.match(/<!-- check:next-round ([^>]+) -->/);
    if (!mk) err("10: Marke <!-- check:next-round … --> fehlt");
    else {
      const ids = mk[1].trim().split(/\s+/);
      for (const id of ids) {
        const row = csvRows.find((r) => r.id === id) || csvRows.find((r) => r.id === id && !r.sub);
        if (!row) err(`10: ${id} nicht in decision-status.csv`);
        else if (row.status !== "P") err(`10: ${id} steht in der Fragerunde, ist aber nicht „produktentscheidung“`);
        if (!new RegExp("^### " + id.replace(/\./g, "\\.") + " · ", "m").test(t10)) err(`10: Abschnitt für ${id} fehlt`);
      }
      for (const r of csvRows.filter((x) => x.status === "P")) {
        if (!ids.includes(r.id) && !t10.includes(r.id)) err(`10: offene Produktentscheidung ${r.id} weder in der Fragerunde noch unter „Später“ genannt`);
      }
      notes.push(`nächste Fragerunde: ${ids.length} Fragen`);
    }
  }
  notes.push(`Entscheidungsstatus: ${Object.keys(entries).length} Einträge, ${csvRows.length} Fragen`);
}

// --- 7. Statuswerte ---------------------------------------------------------
for (const [f, t] of Object.entries(docs)) {
  for (const m of t.matchAll(/`((?:implemented|legacy|documented|decision|not|deferred)[a-z-]*)`/g)) {
    if (!STATUS.includes(m[1])) err(`${f}: unbekannter Statuswert \`${m[1]}\``);
  }
  for (const m of t.matchAll(/`(automatic|assisted|manual-only|unknown|manual|auto)`/g)) {
    if (!AUTOMATION.includes(m[1])) err(`${f}: unbekannter Automationswert \`${m[1]}\``);
  }
}

// --- 8. Links -----------------------------------------------------------------
for (const [f, t] of Object.entries(docs)) {
  for (const m of t.matchAll(/\]\(([^)\s]+)\)/g)) {
    const target = m[1].split("#")[0];
    if (!target || /^[a-z]+:/.test(target)) continue;
    if (!fs.existsSync(path.resolve(DOCS, target))) err(`${f}: Link zeigt ins Leere: ${m[1]}`);
  }
}

// --- 10. Zitierte Repository-Pfade in Backticks --------------------------------
// Prüft Hauptdokumente und Dossiers: `js/...`, `godot/...`, `docs/...`, `app/...`,
// `tools/...`, `tests/...`, `assets/...` sowie Wurzeldateien (*.md, *.html).
const dossierDir = path.join(DOCS, "dossiers");
const pathDocs = { ...docs };
if (fs.existsSync(dossierDir)) {
  for (const f of fs.readdirSync(dossierDir).filter((x) => x.endsWith(".md"))) {
    pathDocs["dossiers/" + f] = fs.readFileSync(path.join(dossierDir, f), "utf8");
  }
}
const BARE_DIRS = ["docs/masterplan", "docs/godot-migration", "docs/specs/vertical-slice", "docs/role-migration"];
// Zitierte Dateien der Parallelarbeit (UI-Branch, neuerer main) werden nur lesend per git geprüft.
const OTHER_REFS = ["origin/main", "origin/claude/sleepy-babbage-u2o0i2"];
const { execFileSync } = require("child_process");
const gitHas = (ref, rel) => {
  try { execFileSync("git", ["-C", ROOT, "cat-file", "-e", `${ref}:${rel}`], { stdio: "ignore" }); return true; } catch (e) { return false; }
};
const foundInRefs = new Set();
let checkedPaths = 0;
for (const [f, t] of Object.entries(pathDocs)) {
  for (const m of t.matchAll(/`((?:js|godot|docs|app|tools|tests|assets)\/[^`\s:*]+|[A-Za-z0-9_.-]+\.(?:md|html))(?::[\d,\- ]+)?`/g)) {
    const rel = m[1].replace(/\/$/, "");
    if (/[<>{}]/.test(rel)) continue; // Muster wie `core/roles/<role-id>.gd`
    checkedPaths++;
    const candidates = [path.join(ROOT, rel), path.resolve(path.dirname(path.join(DOCS, f)), rel)];
    // Kurzform ohne Ordner (z. B. `DECISION-LOG.md`): in den Dokumentordnern suchen.
    if (!rel.includes("/")) for (const d of BARE_DIRS) candidates.push(path.join(ROOT, d, rel));
    if (candidates.some((c) => fs.existsSync(c))) continue;
    // Nicht im Arbeitsbaum: nur lesend in den Referenzen der Parallelarbeit suchen.
    const ref = rel.includes("/") ? OTHER_REFS.find((r) => gitHas(r, rel)) : null;
    if (ref) { foundInRefs.add(`${rel} (${ref})`); continue; }
    err(`${f}: zitierter Pfad existiert nicht: ${rel}`);
  }
}
notes.push(`zitierte Repository-Pfade geprüft: ${checkedPaths}`);
for (const x of foundInRefs) notes.push(`nur außerhalb des Arbeitsbaums vorhanden: ${x}`);

// --- Ausgabe ------------------------------------------------------------------
for (const n of notes) console.log("info  " + n);
for (const e of errors) console.log("FEHLER " + e);
console.log(errors.length ? `${errors.length} Fehler` : "OK: keine Fehler");
process.exit(errors.length ? 1 : 0);
