# Grimmhain Revolution: Arbeitsvertrag

Regeln, Testregeln und Verweise. Erklärungen: `docs/development/` (`CLAUDE-STACK.md`, `CLAUDE-SKILLS.md`, `CLAUDE-CLOUD.md`).

## Quellen
- Aktive Entwicklung: `godot/`, typisiertes GDScript, Tablet zuerst. HTML/JS/React ist Legacy, nur bei konkretem Bedarf.
- Engine-Pin: `godot/tools/godot-version.txt`. Kein eigenmächtiger Versionswechsel.
- Produktentscheidungen: `docs/masterplan/DECISION-LOG.md`; Regeln: `docs/specs/vertical-slice/`; Gesamtplan: `GRIMMHAIN-REVOLUTION-MASTERPLAN.md`. Nur relevante Abschnitte laden.
- Stand und Übergabe: `PROGRESS.md` (oben: Stand in 10 Zeilen). Umsetzung/Testbefehle: `godot/README.md`. UI: `docs/ui/`. Medien: `docs/assets/`, `docs/masterplan/ASSET-REGISTER.md`.
- Alle Texte und Assets folgen `docs/brand/MARKE.md`.
- Empfehlungen, Legacy-Verhalten und Berichte sind keine Nutzerfreigaben. Widersprüche benennen; entschiedene Fragen nicht neu eröffnen.

## Arbeitsweise
- Pro Auftrag eine neue Sitzung; Übergabe über PROGRESS.md (oben: Stand in 10 Zeilen).
- Zu Beginn `git status --short`, Branch und HEAD feststellen; Auftrag und betroffene Dateien eingrenzen.
- Breite Suchen über Explore-Hilfsagenten. Sonst `rg` und begrenzte Ausschnitte; keine ganzen Logs oder Dateibäume in den Chat.
- Aufträge über 30 Minuten erst als Plan vorlegen.
- Nach 2 gescheiterten Versuchen am selben Problem anhalten und melden.
- Ein Umsetzungsauftrag autorisiert erforderliche lokale Änderungen. Bei offenen Spielregeln oder erheblicher Umfangsänderung gezielt nachfragen.
- Standard: ein Agent. Weitere nur bei ausdrücklich beauftragter Parallelität; delegierte Suche nicht selbst wiederholen.
- Skills nur bei passender Aufgabe laden: `docs/development/CLAUDE-SKILLS.md`.
- Kein Commit, Push, Merge oder Kauf ohne Auftrag. Fremde und uncommittete Änderungen erhalten, besonders `godot/project.godot`.

## Qualitätsgrenzen
- Regelkern bleibt unabhängig von Szenen, UI, Audio und Dateizugriff. Vorhandene Befehle, Ereignisse und Anwendungsschicht nutzen; keine zweite Regelimplementierung in der UI.
- Personen-ID ist Identität, Sitzplatz nur Anordnung. Zufall nur über den gespeicherten Generator. Öffentliche Ansichten und Audio verraten keine geheimen Ereignisse.
- Verhaltensänderungen mit aussagekräftigen Tests, Bugs mit reproduzierendem Regressionstest. Headless-grün ist keine visuelle oder Tablet-Abnahme.
- DE/EN-Lokalisierung und Theme-Tokens verwenden. Medien nur mit dokumentiertem Status; Budget ist keine Kauf- oder Releasefreigabe.
- Keine Rollenbeschränkungen aus Bequemlichkeit erfinden. Entscheidungslücken nicht mit plausiblen Defaults verdecken.

## Testregeln (verbindlich, Markus 01.10.2026)
1. Während der Arbeit nur Tests der direkt geänderten Dateien (`tools/test-changed`), leise über `tools/test-quiet`. Nie die komplette Suite zwischendurch.
2. Komplette Suite höchstens einmal pro Auftrag, am Ende, nur wenn `core/`, Speichern/Laden oder Befehle geändert wurden. Bei reiner UI- oder Grafikarbeit keine.
3. Fuzz (`test_role_interaction_fuzz`) nur bei Regelkernänderung oder vor einem Merge nach main.
4. Keine Tests für Positionen, Abstände oder Aussehen (Screenshot).
5. Neue Tests nur für echte Logik, die still kaputtgehen kann (Speichern, Geheimhaltung, Regeln); höchstens ein kleiner Test pro neuer Funktion.
6. Lange Läufe im Hintergrund, einmal auf das Ende warten; kein wiederholtes Nachschauen.
7. Im Bericht angeben, welche Tests liefen und warum.
8. „Nur wenn grün“ vor Merge/Push: Vollsuite auf dem finalen Stand vor dem Push; nach rotem Lauf und Fix wiederholen.
- Bekannte Fehler nicht ignorieren, Tests nie abschwächen. Grünen unveränderten Stand nicht nachtesten. Nach ausreichender Prüfung abschließen, keine weitere Audit-Runde.

## Prüfungen
- Godot Windows: `.claude/skills/grimmhain-core/windows-checks.md`; Linux/WSL: `godot/tests/run_all.sh`.
- Medien: `node tools/check-asset-register.js`; i18n: `node tools/check-godot-i18n.js`.
- Legacy: `node tests/smoke.js`, `node tools/compare-i18n.js` nur bei Legacy-Änderungen.
- Abschluss: `git diff --check`, Diff prüfen, Ergebnisse und ausgelassene Prüfungen ehrlich nennen.

## Git und Übergabe
- Cloud-Branches nicht automatisch integrieren; drei Claude-Berichte gegen echte Commitstände abgleichen.
- Abschluss: Ergebnis, Branch/HEAD, Dateien, Prüfungen mit Exit-Code, offene Punkte, nächster Schritt.
- Übergabedateien (Berichte, Bilder, Archive) standardmäßig nach `C:/Users/Marku/Downloads/` (Unterordner bei mehreren), dort verlinken; nichts ungefragt überschreiben. Projektdateien bleiben im Repo.
