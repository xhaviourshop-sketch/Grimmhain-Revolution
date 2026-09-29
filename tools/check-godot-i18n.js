// Prüft die produktiv verwendeten Godot-Übersetzungen godot/content/i18n/ui.de.po und ui.en.po
// auf strukturelle Fehler. Beweist Struktur, nicht Bedeutungsgleichheit oder Übersetzungsqualität.
//
// Nutzung (aus dem Repo-Wurzelordner):
//   node tools/check-godot-i18n.js                 Prüfung, Exit-Code 1 bei Befunden
//   node tools/check-godot-i18n.js --root <ordner>  andere Wurzel (Regressionstests mit Fixtures)
// Regressionstests: node --test tests/check-godot-i18n.test.js
//
// Geprüft:
//  1. PO-Syntax: mehrzeilige Texte, Escapes (\n \t \" \\ ...), Kommentare, msgctxt; unbekannte Escapes,
//     offene Anführungszeichen und Zeilen außerhalb eines Eintrags sind Befunde.
//  2. Kopf (msgid ""): UTF-8 und Sprache passend zur Datei.
//  3. Je Sprache: doppelte Schlüssel, leere Übersetzungen, als "fuzzy" markierte Einträge (Godot lädt sie
//     nicht), Plural-Einträge (im Projekt nicht verwendet), Schlüssel außerhalb des Schemas app.*/ui.*.
//  4. DE gegen EN: fehlende Schlüssel, abweichende benannte Platzhalter {name}, abweichende Folge von
//     %-Formaten (%s, %d, ...; %% ist ein Literal).
//  5. Quelltext godot/app (*.gd, *.tscn): jeder wörtliche Schlüssel "ui.x.y" existiert in beiden Sprachen.
//     Direkte Aufrufe tr("ui.x").format({"a": ...}) liefern jeden Platzhalter, den DE oder EN verwendet.
//  6. Bekannte dynamische Gruppe Rollen: für jede Rollen-ID aus godot/core/rules/role_catalog.gd existieren
//     ui.role.<id>.name und ui.role.<id>.short (Bindestrich wird zu Unterstrich, wie RolePresentation).
//
// Grenzen (werden bei jedem Lauf benannt, nicht als vollständig behauptet):
//  - Dynamisch zusammengesetzte Schlüssel ("ui.phase.%s", "ui.setup.error." + x) sind nur als Vorlage
//    prüfbar: Mindestens ein passender Schlüssel muss existieren; ob jeder zur Laufzeit erzeugte Wert
//    einen Schlüssel hat, kann nur ein Laufzeittest belegen (Ausnahme: Rollen, Punkt 6).
//  - Platzhalterwerte, die nicht als wörtliches Dictionary direkt an .format() hängen (format_values,
//    Variablen), sind nicht statisch prüfbar.

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const PO_FILES = { de: "godot/content/i18n/ui.de.po", en: "godot/content/i18n/ui.en.po" };
const SOURCE_DIR = "godot/app";
const ROLE_CATALOG = "godot/core/rules/role_catalog.gd";
const KEY_SCHEMA = /^(app|ui)\.[a-z0-9_]+(\.[a-z0-9_]+)*$/;
const ESCAPES = { n: "\n", t: "\t", r: "\r", '"': '"', "\\": "\\", a: "\x07", b: "\b", f: "\f", v: "\v" };

// --- PO-Parser -------------------------------------------------------------------------------------

function unquote(raw, file, lineNo, problems) {
  const s = raw.trim();
  if (s.length < 2 || s[0] !== '"' || s[s.length - 1] !== '"') {
    problems.push(`${file}:${lineNo}: Zeichenkette nicht korrekt in Anführungszeichen: ${s}`);
    return "";
  }
  let out = "";
  const body = s.slice(1, -1);
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    if (c === '"') {
      problems.push(`${file}:${lineNo}: unmaskiertes Anführungszeichen`);
      continue;
    }
    if (c !== "\\") {
      out += c;
      continue;
    }
    const n = body[++i];
    if (n in ESCAPES) {
      out += ESCAPES[n];
    } else if (n === "x" && /^[0-9a-fA-F]{2}$/.test(body.slice(i + 1, i + 3))) {
      out += String.fromCharCode(parseInt(body.slice(i + 1, i + 3), 16));
      i += 2;
    } else if (/[0-7]/.test(n || "")) {
      const oct = body.slice(i).match(/^[0-7]{1,3}/)[0];
      out += String.fromCharCode(parseInt(oct, 8));
      i += oct.length - 1;
    } else {
      problems.push(`${file}:${lineNo}: unbekannte Escape-Sequenz \\${n === undefined ? "" : n}`);
    }
  }
  return out;
}

// Liefert {entries, header, problems}. entries: [{msgid, msgstr, msgctxt, line, flags, plural}]
function parsePo(text, file = "<po>") {
  const problems = [];
  const entries = [];
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
  const lines = text.split(/\r?\n/);
  let cur = null;
  let field = null;
  let flags = [];
  const finish = () => {
    if (cur && cur.msgid !== undefined) {
      if (cur.msgstr === undefined) problems.push(`${file}:${cur.line}: Eintrag ohne msgstr`);
      entries.push(cur);
    }
    cur = null;
    field = null;
  };
  lines.forEach((raw, idx) => {
    const lineNo = idx + 1;
    const line = raw.trim();
    if (line === "") {
      finish();
      return;
    }
    if (line.startsWith("#")) {
      if (cur && cur.msgid !== undefined && cur.msgstr !== undefined) finish();
      if (line.startsWith("#,")) flags.push(...line.slice(2).split(",").map((f) => f.trim()).filter(Boolean));
      return;
    }
    const m = line.match(/^(msgctxt|msgid_plural|msgid|msgstr(?:\[\d+\])?)\s+(.*)$/);
    if (m) {
      const [, kw, rest] = m;
      if (kw === "msgctxt" || (kw === "msgid" && (!cur || cur.msgstr !== undefined))) {
        if (cur && cur.msgstr !== undefined) finish();
        if (!cur) {
          cur = { line: lineNo, flags, plural: false };
          flags = [];
        }
      }
      if (!cur) {
        problems.push(`${file}:${lineNo}: ${kw} ohne vorheriges msgid`);
        return;
      }
      const value = unquote(rest, file, lineNo, problems);
      if (kw === "msgctxt") cur.msgctxt = value;
      else if (kw === "msgid") {
        cur.msgid = value;
        cur.line = cur.msgctxt === undefined ? lineNo : cur.line;
      } else if (kw === "msgid_plural") cur.plural = true;
      else cur.msgstr = (cur.msgstr === undefined ? "" : cur.msgstr) + (kw === "msgstr" ? value : "");
      field = kw;
      if (kw.startsWith("msgstr[")) cur.plural = true;
      return;
    }
    if (line.startsWith('"')) {
      if (!cur || !field) {
        problems.push(`${file}:${lineNo}: Fortsetzungszeile ohne Eintrag`);
        return;
      }
      const value = unquote(line, file, lineNo, problems);
      if (field === "msgctxt") cur.msgctxt += value;
      else if (field === "msgid") cur.msgid += value;
      else if (field === "msgstr") cur.msgstr += value;
      return;
    }
    problems.push(`${file}:${lineNo}: unbekannte Zeile: ${line}`);
  });
  finish();
  const headerIdx = entries.findIndex((e) => e.msgid === "" && e.msgctxt === undefined);
  const header = headerIdx >= 0 ? entries.splice(headerIdx, 1)[0] : null;
  return { entries, header, problems };
}

// --- Platzhalter -----------------------------------------------------------------------------------

// Benannte Platzhalter {name} oder {0} (String.format) als sortierte Menge; %-Formate als Folge.
// Nicht als Platzhalter gelten: {} { x } {1-2}, %% und ein Prozentzeichen ohne Formatbuchstaben.
function placeholders(text) {
  const named = [...new Set([...text.matchAll(/\{([A-Za-z_][A-Za-z0-9_]*|\d+)\}/g)].map((m) => m[1]))].sort();
  const percent = [...text.matchAll(/%(%|[-+0]*(?:\d+|\*)?(?:\.(?:\d+|\*))?[sdifcxXo])/g)]
    .map((m) => m[1])
    .filter((f) => f !== "%")
    .map((f) => f[f.length - 1]);
  return { named, percent };
}

// --- Kataloge --------------------------------------------------------------------------------------

function entryKey(e) {
  return e.msgctxt === undefined ? e.msgid : `${e.msgctxt}\u0004${e.msgid}`;
}

// catalogs: {de: {file, text}, en: {file, text}} → {problems, maps: {de: Map, en: Map}}
function checkCatalogs(catalogs) {
  const problems = [];
  const maps = {};
  for (const [lang, { file, text }] of Object.entries(catalogs)) {
    const parsed = parsePo(text, file);
    problems.push(...parsed.problems);
    const map = new Map();
    if (!parsed.header) {
      problems.push(`${file}: Kopf (msgid "") fehlt`);
    } else {
      if (!/charset=UTF-8/i.test(parsed.header.msgstr || "")) problems.push(`${file}:${parsed.header.line}: Kopf ohne charset=UTF-8`);
      const language = (parsed.header.msgstr || "").match(/^Language:\s*(\S+)/m);
      if (!language || language[1] !== lang) problems.push(`${file}:${parsed.header.line}: Kopf "Language" ist nicht ${lang}`);
    }
    for (const e of parsed.entries) {
      const key = entryKey(e);
      const where = `${file}:${e.line}`;
      if (map.has(key)) {
        problems.push(`${where}: doppelter Schlüssel ${e.msgid} (zuerst Zeile ${map.get(key).line})`);
        continue;
      }
      map.set(key, e);
      if (!KEY_SCHEMA.test(e.msgid)) problems.push(`${where}: Schlüssel außerhalb des Schemas app.*/ui.*: ${JSON.stringify(e.msgid)}`);
      if (e.msgctxt !== undefined) problems.push(`${where}: msgctxt wird im Projekt nicht verwendet (${e.msgid})`);
      if (e.plural) problems.push(`${where}: Plural-Eintrag wird im Projekt nicht verwendet (${e.msgid})`);
      if (e.flags.includes("fuzzy")) problems.push(`${where}: "fuzzy" markiert, Godot lädt diesen Eintrag nicht (${e.msgid})`);
      if ((e.msgstr || "").trim() === "") problems.push(`${where}: leere Übersetzung für ${e.msgid}`);
    }
    maps[lang] = map;
  }
  const langs = Object.keys(maps);
  for (const lang of langs) {
    for (const other of langs) {
      if (lang === other) continue;
      for (const [key, e] of maps[lang]) {
        if (!maps[other].has(key)) problems.push(`${catalogs[other].file}: Schlüssel ${e.msgid} fehlt (vorhanden in ${catalogs[lang].file}:${e.line})`);
      }
    }
  }
  if (langs.length === 2) {
    const [a, b] = langs;
    for (const [key, ea] of maps[a]) {
      const eb = maps[b].get(key);
      if (!eb) continue;
      const pa = placeholders(ea.msgstr || "");
      const pb = placeholders(eb.msgstr || "");
      if (pa.named.join(",") !== pb.named.join(",")) {
        problems.push(`${catalogs[b].file}:${eb.line}: Platzhalter von ${ea.msgid} weichen ab: ${a} {${pa.named.join("},{")}} / ${b} {${pb.named.join("},{")}}`);
      }
      if (pa.percent.join(",") !== pb.percent.join(",")) {
        problems.push(`${catalogs[b].file}:${eb.line}: %-Formate von ${ea.msgid} weichen ab: ${a} [${pa.percent.join(",")}] / ${b} [${pb.percent.join(",")}]`);
      }
    }
  }
  return { problems, maps };
}

// --- Quelltext -------------------------------------------------------------------------------------

const LITERAL = /"((?:app|ui)\.[a-z0-9_.%]*)"/g;
const FORMAT_CALL = /(?:\btr|TranslationServer\.translate)\(\s*"((?:app|ui)\.[a-z0-9_.]+)"\s*\)\s*\.format\(\s*\{([^{}]*)\}/g;

function lineOf(text, index) {
  return text.slice(0, index).split("\n").length;
}

// sources: [{file, text}] → {refs: [{key, file, line}], templates: [{template, file, line}], formats: [{key, provided, file, line}]}
function scanSources(sources) {
  const refs = [];
  const templates = [];
  const formats = [];
  for (const { file, text } of sources) {
    for (const m of text.matchAll(LITERAL)) {
      const literal = m[1];
      const line = lineOf(text, m.index);
      if (literal.includes("%") || literal.endsWith(".")) templates.push({ template: literal, file, line });
      else if (KEY_SCHEMA.test(literal) && literal.includes(".")) refs.push({ key: literal, file, line });
    }
    for (const m of text.matchAll(FORMAT_CALL)) {
      const provided = [...m[2].matchAll(/"([A-Za-z_][A-Za-z0-9_]*)"\s*:/g)].map((k) => k[1]);
      formats.push({ key: m[1], provided, file, line: lineOf(text, m.index) });
    }
  }
  return { refs, templates, formats };
}

function templateRegex(template) {
  const parts = template.split(/%[sd]/).map((p) => p.replace(/\./g, "\\."));
  let src = parts.join("[a-z0-9_]+");
  if (template.endsWith(".")) src += "[a-z0-9_]+(?:\\.[a-z0-9_]+)*";
  return new RegExp(`^${src}$`);
}

// maps: {de: Map, en: Map} (aus checkCatalogs) → {problems, templateReport}
function checkSources(scan, maps, files) {
  const problems = [];
  for (const r of scan.refs) {
    for (const [lang, map] of Object.entries(maps)) {
      if (!map.has(r.key)) problems.push(`${r.file}:${r.line}: Schlüssel ${r.key} fehlt in ${files[lang]}`);
    }
  }
  for (const f of scan.formats) {
    for (const [lang, map] of Object.entries(maps)) {
      const e = map.get(f.key);
      if (!e) continue;
      const missing = placeholders(e.msgstr || "").named.filter((p) => !f.provided.includes(p));
      if (missing.length) problems.push(`${f.file}:${f.line}: .format() für ${f.key} liefert {${missing.join("},{")}} nicht (${lang})`);
    }
  }
  const seen = new Map();
  for (const t of scan.templates) {
    if (!seen.has(t.template)) seen.set(t.template, { template: t.template, where: `${t.file}:${t.line}`, matches: {} });
  }
  for (const entry of seen.values()) {
    const re = templateRegex(entry.template);
    for (const [lang, map] of Object.entries(maps)) {
      entry.matches[lang] = [...map.keys()].filter((k) => re.test(k)).length;
      if (entry.matches[lang] === 0) problems.push(`${entry.where}: dynamische Vorlage ${entry.template} passt auf keinen Schlüssel in ${files[lang]}`);
    }
  }
  return { problems, templateReport: [...seen.values()] };
}

// Rollen-IDs aus role_catalog.gd: `const NAME := &"rollen-id"`.
function roleIds(catalogText) {
  return [...catalogText.matchAll(/^const [A-Z_]+ := &"([a-z0-9-]+)"/gm)].map((m) => m[1]);
}

function checkRoles(ids, maps, files) {
  const problems = [];
  for (const id of ids) {
    const part = id.replace(/-/g, "_");
    for (const suffix of ["name", "short"]) {
      const key = `ui.role.${part}.${suffix}`;
      for (const [lang, map] of Object.entries(maps)) {
        if (!map.has(key)) problems.push(`${ROLE_CATALOG}: Rolle ${id}: ${key} fehlt in ${files[lang]}`);
      }
    }
  }
  return problems;
}

// --- Hauptprogramm ---------------------------------------------------------------------------------

function listSources(root, dir) {
  const out = [];
  for (const entry of fs.readdirSync(path.join(root, dir), { withFileTypes: true })) {
    const rel = `${dir}/${entry.name}`;
    if (entry.isDirectory()) out.push(...listSources(root, rel));
    else if (/\.(gd|tscn)$/.test(entry.name)) out.push(rel);
  }
  return out.sort();
}

function run(root = ROOT) {
  const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");
  const catalogs = Object.fromEntries(Object.entries(PO_FILES).map(([lang, file]) => [lang, { file, text: read(file) }]));
  const { problems, maps } = checkCatalogs(catalogs);
  const scan = scanSources(listSources(root, SOURCE_DIR).map((file) => ({ file, text: read(file) })));
  const src = checkSources(scan, maps, PO_FILES);
  const ids = roleIds(read(ROLE_CATALOG));
  const all = [...problems, ...src.problems, ...checkRoles(ids, maps, PO_FILES)];
  if (ids.length === 0) all.push(`${ROLE_CATALOG}: keine Rollen-IDs gefunden (Muster veraltet?)`);
  return { all, maps, scan, src, ids };
}

function main(argv) {
  const rootArg = argv.indexOf("--root");
  const { all, maps, scan, src, ids } = run(rootArg >= 0 ? path.resolve(argv[rootArg + 1]) : ROOT);
  const out = process.stdout;
  out.write(`Schlüssel: de ${maps.de.size}, en ${maps.en.size}\n`);
  out.write(`Quelltext ${SOURCE_DIR}: ${scan.refs.length} wörtliche Schlüssel, ${scan.formats.length} direkte .format()-Aufrufe geprüft\n`);
  out.write(`Rollen: ${ids.length} IDs mit Name und Kurzname geprüft\n`);
  out.write(`Nicht statisch vollständig prüfbar: ${src.templateReport.length} dynamische Vorlagen (je mindestens ein Schlüssel vorhanden):\n`);
  for (const t of src.templateReport) out.write(`  ${t.template}  (${t.matches.de} Schlüssel)  ${t.where}\n`);
  out.write(`Nicht statisch prüfbar: Platzhalterwerte aus Variablen oder format_values.\n`);
  if (all.length) {
    out.write(`\n${all.length} Befund(e):\n- ${all.join("\n- ")}\n`);
    return 1;
  }
  out.write("Übersetzungen strukturell konsistent.\n");
  return 0;
}

module.exports = { parsePo, placeholders, checkCatalogs, scanSources, checkSources, roleIds, checkRoles, templateRegex, run };

if (require.main === module) {
  process.exit(main(process.argv.slice(2)));
}
