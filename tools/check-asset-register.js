// Prüft das maschinenlesbare Assetregister docs/masterplan/asset-register.csv
// gegen die Mediendateien im Git-Index.
//
// Nutzung (aus dem Repo-Wurzelordner):  node tools/check-asset-register.js
// Exit-Code 0 = Register vollständig und konsistent, 1 = Befunde (werden aufgelistet).
//
// Regeln (Quelle: docs/masterplan/ASSET-REGISTER.md):
//  1. Jede versionierte Mediendatei hat genau eine Registerzeile.
//  2. Jede Registerzeile verweist auf eine vorhandene Datei, deren SHA-256 passt
//     (eine ausgetauschte Datei braucht eine neue Prüfung).
//  3. Pflichtfelder sind gefüllt, der Status stammt aus der erlaubten Liste.
//  4. Status "freigegeben" verlangt eine eingetragene Product-Owner-Freigabe und
//     eine geklärte Lizenzquelle.
//  5. Im Godot-Projekt (godot/) liegt nur, was "freigegeben" ist.

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { execFileSync } = require("child_process");

const ROOT = path.join(__dirname, "..");
const REGISTER = path.join(ROOT, "docs", "masterplan", "asset-register.csv");
const MEDIA = /\.(png|jpe?g|webp|gif|svg|ico|mp3|ogg|wav|m4a|flac|mp4|mov|webm|ttf|otf|woff2?)$/i;

const COLUMNS = [
  "asset_id", "datei", "gruppe", "art", "format", "technik", "bytes", "sha256", "verwendet_in",
  "ersteller_dienst", "modell", "erstellungsdatum", "tarif", "lizenzquelle", "herkunftsnachweis",
  "bearbeitung", "status", "po_freigabe", "ersatz_noetig", "bemerkung",
];
const REQUIRED = [
  "asset_id", "datei", "gruppe", "art", "format", "sha256", "verwendet_in", "ersteller_dienst",
  "erstellungsdatum", "lizenzquelle", "herkunftsnachweis", "bearbeitung", "status", "ersatz_noetig",
];
const STATUS = new Set([
  "freigegeben",               // alle Nachweise vorhanden, PO hat nach Sicht-/Hörprüfung freigegeben
  "ki-nachgewiesen",           // KI-Herkunft per C2PA belegt, Bedingungen/Prompt/PO-Freigabe fehlen
  "lizenz-belegt-datei-fehlt", // Lizenz aus der Datei ablesbar, Lizenztext liegt nicht bei
  "ungeklärt",                 // keine belastbare Herkunft
  "gesperrt",                  // ausdrücklich gesperrt, darf in keinen Build
  "prüfartefakt",              // eigener Screenshot für Dokumentation, nie in Builds
]);
const ASSET_ID = /^[a-z0-9]+(-[a-z0-9]+)*$/;

function trackedMedia() {
  const out = execFileSync("git", ["-c", "core.quotepath=off", "ls-files", "-z"], { cwd: ROOT });
  return out.toString("utf8").split("\0").filter((f) => f && MEDIA.test(f));
}

function readRegister() {
  const lines = fs.readFileSync(REGISTER, "utf8").split("\n").filter((l) => l.trim() !== "");
  const header = lines[0].split(";");
  const problems = [];
  if (header.join(";") !== COLUMNS.join(";")) {
    problems.push(`Kopfzeile weicht ab. Erwartet: ${COLUMNS.join(";")}`);
  }
  const rows = lines.slice(1).map((line, i) => {
    const cells = line.split(";");
    if (cells.length !== COLUMNS.length) {
      problems.push(`Zeile ${i + 2}: ${cells.length} statt ${COLUMNS.length} Spalten (Semikolon im Text?)`);
    }
    const row = { _line: i + 2 };
    COLUMNS.forEach((c, k) => { row[c] = (cells[k] || "").trim(); });
    return row;
  });
  return { rows, problems };
}

function main() {
  const { rows, problems } = readRegister();
  const media = trackedMedia();
  const byFile = new Map();
  const ids = new Map();

  for (const row of rows) {
    const where = `Zeile ${row._line} (${row.datei || "ohne Datei"})`;
    for (const c of REQUIRED) if (!row[c]) problems.push(`${where}: Pflichtfeld "${c}" leer`);
    if (row.asset_id && !ASSET_ID.test(row.asset_id)) problems.push(`${where}: asset_id "${row.asset_id}" ist nicht ASCII-kebab-case`);
    if (ids.has(row.asset_id)) problems.push(`${where}: asset_id "${row.asset_id}" doppelt (auch Zeile ${ids.get(row.asset_id)})`);
    ids.set(row.asset_id, row._line);
    if (byFile.has(row.datei)) problems.push(`${where}: Datei doppelt registriert`);
    byFile.set(row.datei, row);
    if (row.status && !STATUS.has(row.status)) problems.push(`${where}: unbekannter Status "${row.status}"`);

    if (row.status === "freigegeben") {
      if (!row.po_freigabe) problems.push(`${where}: "freigegeben" ohne Eintrag in po_freigabe`);
      if (/ungeklärt|unbekannt/i.test(row.lizenzquelle)) problems.push(`${where}: "freigegeben" mit ungeklärter Lizenzquelle`);
    }
    if (row.datei.startsWith("godot/") && row.status !== "freigegeben") {
      problems.push(`${where}: liegt im Godot-Projekt, Status ist aber "${row.status}"`);
    }

    const abs = path.join(ROOT, row.datei);
    if (!fs.existsSync(abs)) {
      problems.push(`${where}: Datei fehlt`);
      continue;
    }
    const sha = crypto.createHash("sha256").update(fs.readFileSync(abs)).digest("hex");
    if (row.sha256 && sha !== row.sha256) problems.push(`${where}: SHA-256 passt nicht, Datei wurde verändert und muss neu geprüft werden`);
  }

  for (const f of media) {
    if (!byFile.has(f)) problems.push(`Nicht registriert: ${f}`);
  }

  const counts = {};
  for (const row of rows) counts[row.status] = (counts[row.status] || 0) + 1;
  process.stdout.write(`Registerzeilen: ${rows.length}, versionierte Mediendateien: ${media.length}\n`);
  process.stdout.write(`Status: ${Object.entries(counts).map(([k, v]) => `${k} ${v}`).join(", ")}\n`);

  if (problems.length) {
    process.stdout.write(`\n${problems.length} Befund(e):\n- ${problems.join("\n- ")}\n`);
    process.exit(1);
  }
  process.stdout.write("Register vollständig und konsistent.\n");
}

main();
