// Regressionstests für die CSV-Zeilentrennung in tools/role-migration/check-role-docs.js
// Ausführen: node --test tests/check-role-docs.test.js
//
// Anlass (2026-09-27): Auf einem Windows-Checkout (`* text=auto` in .gitattributes)
// bekam docs/role-migration/decision-status.csv CRLF-Zeilenenden; die Kopfzeile endete
// auf "hinweis\r" und das Werkzeug meldete "decision-status.csv: unerwarteter Kopf".

const test = require("node:test");
const assert = require("node:assert/strict");
const { csvLines } = require("../tools/role-migration/check-role-docs.js");

const HEADER = "id;teilfrage;rolle;status;quelle;hinweis";
const ROW = "RM-DR-001;nein;alle;E;DR-01;letzte Spalte";

test("LF: Kopfzeile und Datenzeile unverändert", () => {
  assert.deepEqual(csvLines(`${HEADER}\n${ROW}\n`), [HEADER, ROW]);
});

test("CRLF (Windows-Checkout): Kopfzeile gilt, letzte Spalte ohne \\r", () => {
  assert.deepEqual(csvLines(`${HEADER}\r\n${ROW}\r\n`), [HEADER, ROW]);
});

test("UTF-8-BOM: wie bisher durch trim() entfernt, Kopfzeile erkannt", () => {
  assert.deepEqual(csvLines(`﻿${HEADER}\n${ROW}\n`), [HEADER, ROW]);
});
