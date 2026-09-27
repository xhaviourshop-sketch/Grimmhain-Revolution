// Regressionstests für tools/check-asset-register.js
// Ausführen: node --test tests/check-asset-register.test.js
//
// Anlass (2026-09-27): Auf einem Windows-Checkout (`* text=auto` in .gitattributes)
// bekam die CSV CRLF-Zeilenenden; die Kopfzeile endete auf "bemerkung\r" und das
// Werkzeug meldete "Kopfzeile weicht ab". Ein UTF-8-BOM (Excel) wirkt genauso.

const test = require("node:test");
const assert = require("node:assert/strict");
const { COLUMNS, parseRegister, checkRegister, suggestRow } = require("../tools/check-asset-register.js");

const HEADER = COLUMNS.join(";");
const SHA = "a".repeat(64);

function row(overrides = {}) {
  const r = Object.fromEntries(COLUMNS.map((c) => [c, "x"]));
  Object.assign(r, {
    asset_id: "evidence-demo", datei: "docs/evidence/demo/01.png", sha256: SHA,
    status: "prüfartefakt", po_freigabe: "", bemerkung: "nur Dokumentation",
  }, overrides);
  return COLUMNS.map((c) => r[c]).join(";");
}

const hashes = (map) => (f) => (f in map ? map[f] : null);

test("LF: gültige Kopfzeile und Zeile ohne Befund", () => {
  const { rows, problems } = parseRegister(`${HEADER}\n${row()}\n`);
  assert.deepEqual(problems, []);
  assert.equal(rows.length, 1);
  assert.equal(rows[0].bemerkung, "nur Dokumentation");
});

test("CRLF (Windows-Checkout): Kopfzeile gilt, letzte Spalte ohne \\r", () => {
  const { rows, problems } = parseRegister(`${HEADER}\r\n${row()}\r\n`);
  assert.deepEqual(problems, []);
  assert.equal(rows[0].bemerkung, "nur Dokumentation");
});

test("UTF-8-BOM wird ausdrücklich gemeldet, Kopfzeile trotzdem erkannt", () => {
  const { rows, problems } = parseRegister(`\uFEFF${HEADER}\n${row()}\n`);
  assert.equal(problems.length, 1);
  assert.match(problems[0], /BOM/);
  assert.equal(rows.length, 1);
});

test("Windows-1252 statt UTF-8 wird gemeldet", () => {
  const latin1 = Buffer.from(`${HEADER}\n${row({ gruppe: "prüfartefakte" })}\n`, "latin1").toString("utf8");
  const { problems } = parseRegister(latin1);
  assert.ok(problems.some((p) => /kein gültiges UTF-8/.test(p)));
});

test("Kopfzeile: vertauschte Spalten werden mit Position gemeldet", () => {
  const cols = COLUMNS.slice();
  [cols[0], cols[1]] = [cols[1], cols[0]];
  const { problems } = parseRegister(`${cols.join(";")}\n${row()}\n`);
  assert.equal(problems.length, 1);
  assert.match(problems[0], /Kopfzeile weicht ab.*Spalte 1/);
});

test("Kopfzeile: fehlende Spalte wird gemeldet", () => {
  const { problems } = parseRegister(`${COLUMNS.slice(0, -1).join(";")}\n`);
  assert.match(problems[0], /19 statt 20 Spalten/);
});

test("Kopfzeile: unsichtbares Zeichen wird sichtbar gemacht", () => {
  const { problems } = parseRegister(`${HEADER.replace("gruppe", "grup\u200Bpe")}\n`);
  assert.match(problems[0], /\\u200b/);
});

test("Zelle mit unsichtbarem Zeichen wird gemeldet", () => {
  const { problems } = parseRegister(`${HEADER}\n${row({ gruppe: "prüf\u00A0artefakte" })}\n`);
  assert.equal(problems.length, 1);
  assert.match(problems[0], /Spalte "gruppe": unsichtbares Zeichen/);
});

test("Semikolon im Text verschiebt Spalten und wird gemeldet", () => {
  const { problems } = parseRegister(`${HEADER}\n${row({ bemerkung: "a; b" })}\n`);
  assert.match(problems[0], /21 statt 20 Spalten/);
});

test("Neuer Prüf-Screenshot ohne Registerzeile wird gemeldet, nicht still akzeptiert", () => {
  const { rows } = parseRegister(`${HEADER}\n${row()}\n`);
  const media = ["docs/evidence/demo/01.png", "docs/evidence/player-setup/09-new.png"];
  const { problems, unregistered } = checkRegister(rows, media, hashes({ "docs/evidence/demo/01.png": SHA }));
  assert.deepEqual(unregistered, ["docs/evidence/player-setup/09-new.png"]);
  assert.deepEqual(problems, ["Nicht registriert: docs/evidence/player-setup/09-new.png"]);
});

test("Veränderte Datei (SHA-256) wird gemeldet", () => {
  const { rows } = parseRegister(`${HEADER}\n${row()}\n`);
  const { problems } = checkRegister(rows, ["docs/evidence/demo/01.png"], hashes({ "docs/evidence/demo/01.png": "b".repeat(64) }));
  assert.match(problems[0], /SHA-256 passt nicht/);
});

test("prüfartefakt außerhalb der Evidence-Ordner ist unzulässig", () => {
  const { rows } = parseRegister(`${HEADER}\n${row({ datei: "assets/x.png" })}\n`);
  const { problems } = checkRegister(rows, ["assets/x.png"], hashes({ "assets/x.png": SHA }));
  assert.match(problems[0], /nur unter docs\/evidence\//);
});

test("Datei unter godot/ ohne Freigabe wird gemeldet", () => {
  const { rows } = parseRegister(`${HEADER}\n${row({ datei: "godot/assets/x.png", status: "ungeklärt" })}\n`);
  const { problems } = checkRegister(rows, ["godot/assets/x.png"], hashes({ "godot/assets/x.png": SHA }));
  assert.ok(problems.some((p) => /Godot-Projekt/.test(p)));
});

test("freigegeben verlangt PO-Eintrag und geklärte Lizenz", () => {
  const { rows } = parseRegister(`${HEADER}\n${row({ datei: "assets/x.png", status: "freigegeben", lizenzquelle: "ungeklärt" })}\n`);
  const { problems } = checkRegister(rows, ["assets/x.png"], hashes({ "assets/x.png": SHA }));
  assert.ok(problems.some((p) => /ohne Eintrag in po_freigabe/.test(p)));
  assert.ok(problems.some((p) => /ungeklärter Lizenzquelle/.test(p)));
});

test("Vorschlag für Prüf-Screenshot ist eine gültige, vollständige Zeile", () => {
  const line = suggestRow("docs/evidence/player-setup/09-new-1024x768-de.png", SHA, 123, "1024x768");
  const { rows, problems } = parseRegister(`${HEADER}\n${line}\n`);
  assert.deepEqual(problems, []);
  assert.equal(rows[0].status, "prüfartefakt");
  assert.equal(rows[0].asset_id, "evidence-player-setup-09-new-1024x768-de");
  const check = checkRegister(rows, [rows[0].datei], hashes({ [rows[0].datei]: SHA }));
  assert.deepEqual(check.problems, []);
});

test("Vorschlag für sonstige Medien bleibt ungeklärt und ist nicht prüfungsfähig", () => {
  const line = suggestRow("assets/new/thing.png", SHA, 1, "");
  const { rows } = parseRegister(`${HEADER}\n${line}\n`);
  assert.equal(rows[0].status, "ungeklärt");
  const check = checkRegister(rows, [rows[0].datei], hashes({ [rows[0].datei]: SHA }));
  assert.ok(check.problems.some((p) => /kebab-case/.test(p)), "TODO-Kennung muss auffallen");
});
