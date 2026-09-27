// Prüft das maschinenlesbare Assetregister docs/masterplan/asset-register.csv
// gegen die Mediendateien im Git-Index.
//
// Nutzung (aus dem Repo-Wurzelordner):
//   node tools/check-asset-register.js            Prüfung, Exit-Code 1 bei Befunden
//   node tools/check-asset-register.js --suggest  zusätzlich Registerzeilen-Vorschläge
//                                                 für nicht registrierte Dateien ausgeben
// Regressionstests: node --test tests/check-asset-register.test.js
//
// Regeln (Quelle: docs/masterplan/ASSET-REGISTER.md):
//  1. Jede versionierte Mediendatei hat genau eine Registerzeile. Es gibt keine
//     Ausnahme für Pfade: auch Prüf-Screenshots brauchen eine eigene Zeile.
//  2. Jede Registerzeile verweist auf eine vorhandene Datei, deren SHA-256 passt
//     (eine ausgetauschte Datei braucht eine neue Prüfung).
//  3. Die Datei ist UTF-8 ohne BOM, die Kopfzeile stimmt exakt, jede Zeile hat
//     gleich viele Spalten, Zellen enthalten keine unsichtbaren Steuerzeichen.
//     Zeilenenden LF und CRLF sind beide gültig (Windows-Checkout mit text=auto).
//  4. Pflichtfelder sind gefüllt, der Status stammt aus der erlaubten Liste.
//  5. Status "freigegeben" verlangt eine eingetragene Product-Owner-Freigabe und
//     eine geklärte Lizenzquelle.
//  6. Im Godot-Projekt (godot/) liegt nur, was "freigegeben" ist.

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { execFileSync } = require("child_process");

const ROOT = path.join(__dirname, "..");
const REGISTER = path.join(ROOT, "docs", "masterplan", "asset-register.csv");
const MEDIA = /\.(png|jpe?g|webp|gif|svg|ico|mp3|ogg|wav|m4a|flac|mp4|mov|webm|ttf|otf|woff2?)$/i;
const EVIDENCE_DIRS = ["docs/evidence/", "docs/screenshots/"];

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
const BOM = "\uFEFF";
// Steuerzeichen und unsichtbare Formatzeichen (Zero-Width, BOM mitten im Text, bidirektionale Marken).
const INVISIBLE = /[\u0000-\u0008\u000B-\u001F\u007F\u00A0\u200B-\u200F\u2028-\u202F\u2060-\u2064\uFEFF]/;

function visible(s) {
  return JSON.stringify(s).replace(/[\u0080-\uFFFF]/g, (c) => `\\u${c.charCodeAt(0).toString(16).padStart(4, "0")}`);
}

// Zerlegt den Registertext. Liefert Zeilen und Formatbefunde; wirft nie.
function parseRegister(text) {
  const problems = [];
  if (text.startsWith(BOM)) {
    problems.push("Datei beginnt mit einem UTF-8-BOM. Bitte als \"CSV UTF-8 ohne BOM\" speichern (Excel fügt ihn beim Speichern als \"CSV UTF-8\" ein).");
    text = text.slice(1);
  }
  if (text.includes("\uFFFD")) {
    problems.push("Datei ist kein gültiges UTF-8 (Ersatzzeichen U+FFFD gefunden). Vermutlich in Windows-1252 gespeichert; Umlaute prüfen und als UTF-8 ohne BOM speichern.");
  }
  const lines = text.split(/\r?\n/).filter((l) => l.trim() !== "");
  if (lines.length === 0) return { rows: [], problems: problems.concat("Register ist leer.") };

  const header = lines[0].split(";");
  if (header.join(";") !== COLUMNS.join(";")) {
    const detail = [];
    if (header.length !== COLUMNS.length) detail.push(`${header.length} statt ${COLUMNS.length} Spalten`);
    const i = COLUMNS.findIndex((c, k) => header[k] !== c);
    if (i >= 0) detail.push(`Spalte ${i + 1}: erwartet ${visible(COLUMNS[i])}, gefunden ${visible(header[i] === undefined ? "" : header[i])}`);
    problems.push(`Kopfzeile weicht ab (${detail.join("; ")}). Erwartet: ${COLUMNS.join(";")}`);
  }

  const rows = lines.slice(1).map((line, i) => {
    const lineNo = i + 2;
    const cells = line.split(";");
    if (cells.length !== COLUMNS.length) {
      problems.push(`Zeile ${lineNo}: ${cells.length} statt ${COLUMNS.length} Spalten (Semikolon im Text?)`);
    }
    const row = { _line: lineNo };
    COLUMNS.forEach((c, k) => {
      const cell = cells[k] || "";
      if (INVISIBLE.test(cell)) problems.push(`Zeile ${lineNo}, Spalte "${c}": unsichtbares Zeichen in ${visible(cell)}`);
      row[c] = cell.trim();
    });
    return row;
  });
  return { rows, problems };
}

// Prüft Registerzeilen gegen die Mediendateien.
//   media:  Liste versionierter Mediendateipfade (relativ, "/" als Trenner)
//   hashOf: Pfad -> SHA-256 (hex) oder null, wenn die Datei fehlt
function checkRegister(rows, media, hashOf) {
  const problems = [];
  const byFile = new Map();
  const ids = new Map();

  for (const row of rows) {
    const where = `Zeile ${row._line} (${row.datei || "ohne Datei"})`;
    for (const c of REQUIRED) if (!row[c]) problems.push(`${where}: Pflichtfeld "${c}" leer`);
    if (row.asset_id && !ASSET_ID.test(row.asset_id)) problems.push(`${where}: asset_id "${row.asset_id}" ist nicht ASCII-kebab-case`);
    if (row.asset_id && ids.has(row.asset_id)) problems.push(`${where}: asset_id "${row.asset_id}" doppelt (auch Zeile ${ids.get(row.asset_id)})`);
    ids.set(row.asset_id, row._line);
    if (byFile.has(row.datei)) problems.push(`${where}: Datei doppelt registriert`);
    byFile.set(row.datei, row);
    if (row.status && !STATUS.has(row.status)) problems.push(`${where}: unbekannter Status "${row.status}"`);

    if (row.status === "freigegeben") {
      if (!row.po_freigabe) problems.push(`${where}: "freigegeben" ohne Eintrag in po_freigabe`);
      if (/ungeklärt|unbekannt/i.test(row.lizenzquelle)) problems.push(`${where}: "freigegeben" mit ungeklärter Lizenzquelle`);
    }
    if (row.status === "prüfartefakt" && !EVIDENCE_DIRS.some((d) => row.datei.startsWith(d))) {
      problems.push(`${where}: "prüfartefakt" ist nur unter ${EVIDENCE_DIRS.join(" oder ")} zulässig`);
    }
    if (row.datei.startsWith("godot/") && row.status !== "freigegeben") {
      problems.push(`${where}: liegt im Godot-Projekt, Status ist aber "${row.status}"`);
    }

    const sha = hashOf(row.datei);
    if (sha === null) {
      problems.push(`${where}: Datei fehlt`);
    } else if (row.sha256 && sha !== row.sha256) {
      problems.push(`${where}: SHA-256 passt nicht, Datei wurde verändert und muss neu geprüft werden`);
    }
  }

  const unregistered = media.filter((f) => !byFile.has(f));
  for (const f of unregistered) problems.push(`Nicht registriert: ${f}`);
  return { problems, unregistered };
}

// Registerzeilen-Vorschlag für eine nicht registrierte Datei. Prüf-Screenshots werden
// als "prüfartefakt" vorbefüllt, alles andere als "ungeklärt" mit Lücken, die ein Mensch füllt.
function suggestRow(file, sha, bytes, technik) {
  const base = path.posix.basename(file).replace(/\.[^.]+$/, "");
  const slug = base.toLowerCase().normalize("NFKD").replace(/[^\x00-\x7f]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const ext = path.posix.extname(file).slice(1).toUpperCase();
  const evidence = EVIDENCE_DIRS.some((d) => file.startsWith(d));
  const row = Object.fromEntries(COLUMNS.map((c) => [c, ""]));
  Object.assign(row, { datei: file, format: ext, technik, bytes: String(bytes), sha256: sha, art: "bild" });
  if (evidence) {
    Object.assign(row, {
      asset_id: `evidence-${path.posix.basename(path.posix.dirname(file))}-${slug}`, gruppe: "prüfartefakte",
      verwendet_in: "dokumentation", ersteller_dienst: "Projekt (automatisierter Godot-Screenshot, godot/tools/capture_ui_screenshots.gd)",
      modell: "-", erstellungsdatum: "siehe Git-Historie", tarif: "-", lizenzquelle: "eigenes Werk",
      herkunftsnachweis: "Git-Historie und README im Screenshot-Ordner", bearbeitung: "keine",
      status: "prüfartefakt", ersatz_noetig: "nein", bemerkung: "nur Dokumentation, nie in Builds",
    });
  } else {
    Object.assign(row, {
      asset_id: `TODO-${slug}`, gruppe: "TODO", verwendet_in: "TODO", ersteller_dienst: "TODO", modell: "TODO",
      erstellungsdatum: "TODO", tarif: "TODO", lizenzquelle: "ungeklärt", herkunftsnachweis: "TODO",
      bearbeitung: "TODO", status: "ungeklärt", ersatz_noetig: "prüfen",
    });
  }
  return COLUMNS.map((c) => row[c]).join(";");
}

function imageSize(buf) {
  if (buf.length > 24 && buf.readUInt32BE(0) === 0x89504e47) return `${buf.readUInt32BE(16)}x${buf.readUInt32BE(20)}`;
  return "";
}

function trackedMedia() {
  const out = execFileSync("git", ["-c", "core.quotepath=off", "ls-files", "-z"], { cwd: ROOT });
  return out.toString("utf8").split("\0").filter((f) => f && MEDIA.test(f));
}

function hashFile(rel) {
  const abs = path.join(ROOT, rel);
  if (!fs.existsSync(abs)) return null;
  return crypto.createHash("sha256").update(fs.readFileSync(abs)).digest("hex");
}

function main(argv) {
  const { rows, problems: formatProblems } = parseRegister(fs.readFileSync(REGISTER, "utf8"));
  const media = trackedMedia();
  const { problems, unregistered } = checkRegister(rows, media, hashFile);
  const all = formatProblems.concat(problems);

  const counts = {};
  for (const row of rows) counts[row.status] = (counts[row.status] || 0) + 1;
  process.stdout.write(`Registerzeilen: ${rows.length}, versionierte Mediendateien: ${media.length}\n`);
  process.stdout.write(`Status: ${Object.entries(counts).map(([k, v]) => `${k} ${v}`).join(", ")}\n`);

  if (argv.includes("--suggest") && unregistered.length) {
    process.stdout.write("\nVorschläge (prüfen, ergänzen, dann in asset-register.csv einfügen und nach Pfad sortieren):\n");
    for (const f of unregistered) {
      const buf = fs.readFileSync(path.join(ROOT, f));
      process.stdout.write(suggestRow(f, hashFile(f), buf.length, imageSize(buf)) + "\n");
    }
  }

  if (all.length) {
    process.stdout.write(`\n${all.length} Befund(e):\n- ${all.join("\n- ")}\n`);
    if (unregistered.length && !argv.includes("--suggest")) {
      process.stdout.write("\nTipp: node tools/check-asset-register.js --suggest erzeugt Zeilenvorschläge.\n");
    }
    return 1;
  }
  process.stdout.write("Register vollständig und konsistent.\n");
  return 0;
}

module.exports = { COLUMNS, STATUS, parseRegister, checkRegister, suggestRow };

if (require.main === module) {
  process.exit(main(process.argv.slice(2)));
}
