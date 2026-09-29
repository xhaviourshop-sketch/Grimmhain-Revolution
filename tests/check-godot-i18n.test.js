// Regressionstests für tools/check-godot-i18n.js
// Ausführen: node --test tests/check-godot-i18n.test.js
//
// Anlass (Paket 5a, 2026-09-29): Der Godot-Test test_ui_i18n.gd las PO-Dateien zeilenweise und prüfte weder
// doppelte Schlüssel noch Platzhalter; compare-i18n.js betrifft nur die Legacy-Web-App. Die Fixtures sind klein
// und bilden die im Projekt tatsächlich verwendeten Formen nach (mehrzeiliger Kopf, \n im Text, {name}).

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");
const { parsePo, placeholders, checkCatalogs, scanSources, checkSources, roleIds, checkRoles, templateRegex, run } =
  require("../tools/check-godot-i18n.js");

const TOOL = path.join(__dirname, "..", "tools", "check-godot-i18n.js");
const FILES = { de: "ui.de.po", en: "ui.en.po" };

function po(lang, body) {
  return `# Kommentar\nmsgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Language: ${lang}\\n"\n\n${body}`;
}

function check(deBody, enBody) {
  return checkCatalogs({ de: { file: FILES.de, text: po("de", deBody) }, en: { file: FILES.en, text: po("en", enBody) } });
}

test("gültige mehrzeilige Übersetzung, Kopf und Escapes werden korrekt gelesen", () => {
  const { entries, header, problems } = parsePo(po("de",
    'msgid "ui.a"\nmsgstr ""\n"Erste Zeile\\n"\n"zweite \\"Zeile\\" mit \\\\ und \\t"\n\nmsgid "ui.b"\nmsgstr "B"\n'), "x.po");
  assert.deepEqual(problems, []);
  assert.match(header.msgstr, /Language: de\n/);
  assert.equal(entries.length, 2);
  assert.equal(entries[0].msgstr, 'Erste Zeile\nzweite "Zeile" mit \\ und \t');
  assert.equal(entries[0].line, 7);
});

test("CRLF und BOM werden wie LF gelesen", () => {
  const text = "\uFEFF" + po("de", 'msgid "ui.a"\nmsgstr "A"\n').replace(/\n/g, "\r\n");
  const { entries, problems } = parsePo(text, "x.po");
  assert.deepEqual(problems, []);
  assert.equal(entries[0].msgstr, "A");
});

test("identische Kataloge ohne Befund", () => {
  const body = 'msgid "ui.a"\nmsgstr "Hallo {name}"\n';
  assert.deepEqual(check(body, body.replace("Hallo", "Hello")).problems, []);
});

test("fehlender Schlüssel mit Fundstelle", () => {
  const { problems } = check('msgid "ui.a"\nmsgstr "A"\n\nmsgid "ui.b"\nmsgstr "B"\n', 'msgid "ui.a"\nmsgstr "A"\n');
  assert.equal(problems.length, 1);
  assert.match(problems[0], /^ui\.en\.po: Schlüssel ui\.b fehlt \(vorhanden in ui\.de\.po:10\)/);
});

test("doppelter Schlüssel mit beiden Zeilen", () => {
  const body = 'msgid "ui.a"\nmsgstr "A"\n\nmsgid "ui.a"\nmsgstr "A2"\n';
  const { problems } = check(body, 'msgid "ui.a"\nmsgstr "A"\n');
  assert.deepEqual(problems, ["ui.de.po:10: doppelter Schlüssel ui.a (zuerst Zeile 7)"]);
});

test("leere und fuzzy Übersetzung sind Befunde", () => {
  const { problems } = check('msgid "ui.a"\nmsgstr ""\n\n#, fuzzy\nmsgid "ui.b"\nmsgstr "B"\n',
    'msgid "ui.a"\nmsgstr "A"\n\nmsgid "ui.b"\nmsgstr "B"\n');
  assert.equal(problems.length, 2);
  assert.match(problems[0], /ui\.de\.po:7: leere Übersetzung für ui\.a/);
  assert.match(problems[1], /ui\.de\.po:11: "fuzzy" markiert/);
});

test("fehlender oder falsch benannter Platzhalter", () => {
  const de = 'msgid "ui.a"\nmsgstr "{name} wählt {target}"\n\nmsgid "ui.b"\nmsgstr "Runde {number}"\n';
  const en = 'msgid "ui.a"\nmsgstr "{name} chooses"\n\nmsgid "ui.b"\nmsgstr "Round {nummer}"\n';
  const { problems } = check(de, en);
  assert.equal(problems.length, 2);
  assert.match(problems[0], /ui\.en\.po:7: Platzhalter von ui\.a weichen ab: de \{name\},\{target\} \/ en \{name\}/);
  assert.match(problems[1], /ui\.en\.po:10: Platzhalter von ui\.b weichen ab/);
});

test("%-Formate: Anzahl und Typ müssen übereinstimmen, %% ist ein Literal", () => {
  const { problems } = check('msgid "ui.a"\nmsgstr "%s hat %d"\n\nmsgid "ui.b"\nmsgstr "100 %% sicher"\n',
    'msgid "ui.a"\nmsgstr "%s has %s"\n\nmsgid "ui.b"\nmsgstr "100 %% sure"\n');
  assert.equal(problems.length, 1);
  assert.match(problems[0], /%-Formate von ui\.a weichen ab: de \[s,d\] \/ en \[s,s\]/);
});

test("Literale, die keine Platzhalter sind", () => {
  assert.deepEqual(placeholders("{} { x } {1-2} 50 % Chance, 100%% und \\{ohne} {name}"), { named: ["name", "ohne"], percent: [] });
  assert.deepEqual(placeholders("Zeile\n{entries}"), { named: ["entries"], percent: [] });
  assert.deepEqual(placeholders("{0} und %-5.2f"), { named: ["0"], percent: ["f"] });
});

test("PO-Syntaxfehler: unbekannte Escape, offenes Anführungszeichen, verwaiste Zeile", () => {
  const { problems } = parsePo('msgid "ui.a"\nmsgstr "A\\q"\n\nmsgid "ui.b\nmsgstr "B"\n\n"lose"\n', "x.po");
  assert.deepEqual(problems, [
    "x.po:2: unbekannte Escape-Sequenz \\q",
    'x.po:4: Zeichenkette nicht korrekt in Anführungszeichen: "ui.b',
    "x.po:7: Fortsetzungszeile ohne Eintrag",
  ]);
});

test("Kopf: falsche Sprache und fehlender Kopf", () => {
  const wrong = checkCatalogs({ de: { file: "d", text: po("en", 'msgid "ui.a"\nmsgstr "A"\n') }, en: { file: "e", text: 'msgid "ui.a"\nmsgstr "A"\n' } });
  assert.deepEqual(wrong.problems, ['d:2: Kopf "Language" ist nicht de', 'e: Kopf (msgid "") fehlt']);
});

test("Schlüssel außerhalb des Schemas", () => {
  const { problems } = check('msgid "Hallo Welt"\nmsgstr "A"\n', 'msgid "Hallo Welt"\nmsgstr "A"\n');
  assert.equal(problems.length, 2);
  assert.match(problems[0], /außerhalb des Schemas/);
});

test("Quelltext: fehlender Schlüssel, .format()-Platzhalter und dynamische Vorlagen", () => {
  const { maps } = check('msgid "ui.a"\nmsgstr "{name}: {role}"\n\nmsgid "ui.phase.day"\nmsgstr "Tag"\n',
    'msgid "ui.a"\nmsgstr "{name}: {role}"\n\nmsgid "ui.phase.day"\nmsgstr "Day"\n');
  const sources = [{ file: "app/x.gd", text: [
    'var a := tr("ui.a").format({"name": n,',
    '\t"role": TranslationServer.translate(role_name(r))})',
    'var b := tr("ui.a").format({"name": n})',
    'var c := "ui.missing.key"',
    'var d := "ui.phase.%s" % phase',
    'var e := "ui.gone.%s" % x',
    'var f := tr("ui.setup.error." + String(err))',
    'var g := "user://settings.json"',
  ].join("\n") }, { file: "app/y.tscn", text: 'text_key = "ui.a"\n' }];
  const scan = scanSources(sources);
  assert.equal(scan.refs.length, 4);
  assert.equal(scan.formats.length, 2);
  const { problems, templateReport } = checkSources(scan, maps, FILES);
  assert.deepEqual(problems, [
    "app/x.gd:4: Schlüssel ui.missing.key fehlt in ui.de.po",
    "app/x.gd:4: Schlüssel ui.missing.key fehlt in ui.en.po",
    "app/x.gd:3: .format() für ui.a liefert {role} nicht (de)",
    "app/x.gd:3: .format() für ui.a liefert {role} nicht (en)",
    "app/x.gd:6: dynamische Vorlage ui.gone.%s passt auf keinen Schlüssel in ui.de.po",
    "app/x.gd:6: dynamische Vorlage ui.gone.%s passt auf keinen Schlüssel in ui.en.po",
    "app/x.gd:7: dynamische Vorlage ui.setup.error. passt auf keinen Schlüssel in ui.de.po",
    "app/x.gd:7: dynamische Vorlage ui.setup.error. passt auf keinen Schlüssel in ui.en.po",
  ]);
  assert.equal(templateReport.find((t) => t.template === "ui.phase.%s").matches.de, 1);
});

test("Vorlagen des Projekts: Mittelteil, mehrere Teile und Suffix", () => {
  assert.ok(templateRegex("ui.role.%s.name").test("ui.role.das_orakel.name"));
  assert.ok(!templateRegex("ui.role.%s.name").test("ui.role.x.short"));
  assert.ok(templateRegex("ui.cockpit.action.%s.%s.%s").test("ui.cockpit.action.a.b.c"));
  assert.ok(templateRegex("ui.setup.distribution.mode.%s_hint").test("ui.setup.distribution.mode.manual_hint"));
  assert.ok(templateRegex("ui.setup.error.").test("ui.setup.error.too_many"));
});

test("Rollengruppe: jede ID aus dem Katalog braucht Name und Kurzname (Bindestrich → Unterstrich)", () => {
  const ids = roleIds('const UNLIMITED := -1\nconst ORAKEL := &"das-orakel"\nconst WERWOLF := &"werwolf"\n  const X := &"eingerueckt"\n');
  assert.deepEqual(ids, ["das-orakel", "werwolf"]);
  const { maps } = check('msgid "ui.role.das_orakel.name"\nmsgstr "Orakel"\n\nmsgid "ui.role.das_orakel.short"\nmsgstr "O"\n',
    'msgid "ui.role.das_orakel.name"\nmsgstr "Oracle"\n\nmsgid "ui.role.das_orakel.short"\nmsgstr "O"\n');
  const problems = checkRoles(ids, maps, FILES);
  assert.equal(problems.length, 4);
  assert.match(problems[0], /Rolle werwolf: ui\.role\.werwolf\.name fehlt in ui\.de\.po/);
});

test("echtes Repository: produktive Übersetzungen ohne Befund", () => {
  const { all, maps, ids } = run();
  assert.deepEqual(all, []);
  assert.ok(maps.de.size > 1000, `Schlüssel ${maps.de.size}`);
  assert.ok(ids.length >= 70, `Rollen ${ids.length}`);
});

test("Kommandozeile: Exit 1 mit Fundstelle bei echtem Fehler, Exit 0 ohne", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "grimmhain-i18n-"));
  try {
    const write = (rel, text) => {
      fs.mkdirSync(path.dirname(path.join(root, rel)), { recursive: true });
      fs.writeFileSync(path.join(root, rel), text);
    };
    write("godot/content/i18n/ui.de.po", po("de", 'msgid "ui.a"\nmsgstr "Hallo {name}"\n'));
    write("godot/content/i18n/ui.en.po", po("en", 'msgid "ui.a"\nmsgstr "Hello {name}"\n'));
    write("godot/app/x.gd", 'var a := "ui.a"\n');
    write("godot/core/rules/role_catalog.gd", "const UNLIMITED := -1\n");
    let out = "";
    let code = 0;
    try {
      execFileSync(process.execPath, [TOOL, "--root", root], { encoding: "utf8" });
    } catch (e) {
      code = e.status;
      out = e.stdout;
    }
    assert.equal(code, 1, "ohne Rollen-IDs ist das Muster veraltet → Befund");
    assert.match(out, /keine Rollen-IDs gefunden/);
    write("godot/core/rules/role_catalog.gd", 'const WERWOLF := &"werwolf"\n');
    write("godot/content/i18n/ui.de.po", po("de", 'msgid "ui.a"\nmsgstr "Hallo {name}"\n\nmsgid "ui.role.werwolf.name"\nmsgstr "W"\n\nmsgid "ui.role.werwolf.short"\nmsgstr "W"\n'));
    write("godot/content/i18n/ui.en.po", po("en", 'msgid "ui.a"\nmsgstr "Hello {nam}"\n\nmsgid "ui.role.werwolf.name"\nmsgstr "W"\n\nmsgid "ui.role.werwolf.short"\nmsgstr "W"\n'));
    try {
      execFileSync(process.execPath, [TOOL, "--root", root], { encoding: "utf8" });
      code = 0;
    } catch (e) {
      code = e.status;
      out = e.stdout;
    }
    assert.equal(code, 1);
    assert.match(out, /godot\/content\/i18n\/ui\.en\.po:7: Platzhalter von ui\.a weichen ab/);
    write("godot/content/i18n/ui.en.po", po("en", 'msgid "ui.a"\nmsgstr "Hello {name}"\n\nmsgid "ui.role.werwolf.name"\nmsgstr "W"\n\nmsgid "ui.role.werwolf.short"\nmsgstr "W"\n'));
    out = execFileSync(process.execPath, [TOOL, "--root", root], { encoding: "utf8" });
    assert.match(out, /strukturell konsistent/);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
