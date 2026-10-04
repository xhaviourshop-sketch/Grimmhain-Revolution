# Grimmhain Revolution: Arbeitsvertrag

## Ziel und Quellen
- Aktive Neuentwicklung: `godot/`, typisiertes GDScript, Tablet zuerst; später PC/Steam und Online. HTML/JS/React sind Legacy und nur bei konkretem Bedarf zu untersuchen.
- Engine-Pin: `godot/tools/godot-version.txt`. Kein eigenmächtiger Versionswechsel.
- Produktentscheidungen: `docs/masterplan/DECISION-LOG.md`; konkrete Regeln: `docs/specs/vertical-slice/`; Gesamtplan: `GRIMMHAIN-REVOLUTION-MASTERPLAN.md`. Nur relevante Abschnitte laden.
- Umsetzung/Testbefehle: `godot/README.md`; UI: `docs/ui/`; Medien: `docs/assets/` und `docs/masterplan/ASSET-REGISTER.md`.
- Empfehlungen, Legacy-Verhalten und Implementierungsberichte sind keine Nutzerfreigaben. Widersprüche benennen; bereits entschiedene Fragen nicht erneut eröffnen.

Alle Texte und Assets folgen docs/brand/MARKE.md.

## Arbeitsweise und Kontextbudget
- Zu Beginn `git status --short`, Branch und HEAD feststellen. Danach Auftrag und betroffene Dateien eingrenzen. Keine automatische Vollanalyse aller Dokumente oder Nachbarprojekte.
- Ein Umsetzungsauftrag autorisiert erforderliche lokale Änderungen. Nicht jeden Schritt erneut bestätigen lassen. Bei offenen Spielregeln/erheblichen Umfangsänderungen gezielt nachfragen; unabhängige Arbeit fortsetzen.
- `rg` und begrenzte Ausschnitte nutzen. Bekannte Dateien nur bei Änderung oder neuer konkreter Frage erneut lesen. Keine ganzen Logs, Dateibäume oder Dossiers in den Chat kopieren.
- Eine abgegrenzte Aufgabe pro Abschnitt. Vorhandenen Plan fortsetzen; nicht mehrere Planungsframeworks laden. Kleiner Fix braucht keinen neuen Masterplan.
- Standard: ein Agent. Weitere Agenten nur bei ausdrücklich beauftragter Parallelität mit getrennten Aufgaben/Dateien. Delegierte Arbeit nicht parallel selbst wiederholen.
- Lange Testausgaben in temporäre Logs schreiben; Zusammenfassung und Fehler lesen. Keine Fehler ausblenden. Grüne Prüfungen nur bei Änderungen oder neuem Risiko wiederholen.
- Kein routinemäßiges `/clear`, Modellwechsel oder Tool-Umschalten während zusammenhängender Arbeit. Bei Themenwechsel/knappem Kontext zuerst Übergabe sichern, dann neue Sitzung oder `/compact`.

## Skills bei passenden Aufgaben automatisch verwenden
Beschreibung verfügbar halten; vollständigen Skill nur bei Bedarf laden. Kein vollständiger Stack pro Nachricht.

| Aufgabe | Skill |
|---|---|
| GDScript-Regeln, Rollen, Speichern, Replay, Core-Tests | `grimmhain-core` |
| Godot-Tablet-UI, Layout, visuelle Qualität, Animation | `grimmhain-tablet-ui` |
| Grafik, Audio, Assetproduktion, Herkunftsnachweise | `grimmhain-assets` |
| Abschluss, Wiederaufnahme, Cloud-Berichte übernehmen | `grimmhain-handoff` |
| Unerklärter Fehler oder roter Test | vorhandener `systematic-debugging`, gezielt |

Installierte Fachskills zusätzlich nur beim konkreten Bedarf laden:

| Anlass | Fachskill |
|---|---|
| Nichttriviale GDScript-Implementierung, Typen-/Lifecycle-/Signalproblem | `godot-gdscript` |
| Control-/Container-Layout, Theme oder Fokus einer Godot-Ansicht | `godot-ui-control` |
| AnimationPlayer, Tween oder animierter Phasen-/Dialogübergang | `godot-animation` |
| Audio-Busse, Wiedergabe, Stumm/Lautstärke oder Musikübergang | `godot-audio` |
| Reproduzierbares Leistungsproblem oder beauftragte Performanceprüfung | `performance-optimization` |
| Erste Grafikserie, ausdrückliche Stiländerung oder Stilbruch | `art-bible` |
| Konkrete Abschluss-/Abnahmeprüfung | `verify-and-stop` |

Normalfall: ein Grimmhain-Skill plus der nötige Fachskill, keine Kette aller verwandten Skills. Bereits geladene Anleitungen nicht erneut lesen. Referenzen nur zur konkreten Frage öffnen. Statusfragen brauchen keinen Fachskill.
Die Fachskills sind allgemeine Anleitungen: bestehende Architektur/Tests/Briefings haben Vorrang. Keine Node-Beispiele in den Regelkern, keine zusätzliche Testarchitektur, keine zweite Art Bible. Engine-neutrale Beispiele auf Godot prüfen. Kosmetischer Audio-Zufall darf weder den Regelgenerator verbrauchen noch den Core verändern. Verweise auf fremde Agents/Commands installieren oder starten nichts automatisch.
`verify-and-stop` nutzt nur noch gültige Nachweise für denselben relevanten Zustand; erforderliche Tests nach Änderungen bleiben Pflicht. Nicht zusätzlich einen konkurrierenden Verifikationsworkflow laden.

Vorhandene `writing-plans`/`executing-plans` nur für tatsächlich komplexe Planung bzw. beauftragte Planausführung; `docs-write-concisely` für größere redaktionelle Aufgaben. Keine automatische Delegation aus generischen Workflows ableiten. `frontend-design`/Playwright sind für Web-Aufgaben, kein Ersatz für Godot-UI-Prüfungen.

## Qualitätsgrenzen
- Regelkern bleibt unabhängig von Szenen, UI, Audio und Dateizugriff. Vorhandene Befehle/Ereignisse und Anwendungsschicht verwenden; keine zweite Regelimplementierung in der UI.
- Personen-ID ist Identität, Sitzplatz nur Anordnung. Zufall ausschließlich über den gespeicherten Generator. Öffentliche Ansichten/Audio dürfen keine geheimen Ereignisse verraten.
- Verhaltensänderungen mit aussagekräftigen Tests, Bugs mit reproduzierendem Regressionstest. Headless-grün ist keine visuelle oder Tablet-Abnahme.
- DE/EN-Lokalisierung und Theme-Tokens verwenden. Medien mit dokumentiertem Status einbinden; Budget ist keine Kauf- oder Releasefreigabe.
- Keine Rollenbeschränkungen aus Bequemlichkeit erfinden. Entscheidungslücken nicht durch vermeintlich plausible Defaults verdecken.

## Passende Prüfungen
- Godot Linux/WSL: `bash godot/tests/run_all.sh`, gezielt etwa `--filter=replay`; Windows: `.claude/skills/grimmhain-core/windows-checks.md`.
- Medien: `node tools/check-asset-register.js`; zusätzliche Prüfer/Regressionstests nur, wenn im Checkout vorhanden.
- Legacy: `node tests/smoke.js` und `node tools/compare-i18n.js` nur bei entsprechenden Änderungen. Diese prüfen keine Godot-Spielregeln.
- Abschluss: `git diff --check`, beauftragten Diff prüfen, Ergebnisse und ausgelassene Prüfungen ehrlich nennen.

## Git und Übergabe
- Fremde/uncommittete Änderungen erhalten, insbesondere Editoränderungen an `godot/project.godot` nicht beiläufig normalisieren.
- Kein Commit, Push, Merge oder Kauf ohne Auftrag. Cloud-Branches nicht automatisch integrieren. Drei Claude-Berichte gegen tatsächliche Commitstände abgleichen.
- Abschluss: Ergebnis, Branch/HEAD, Dateien, Prüfungen mit Exit-Code, echte offene Punkte, nächster Schritt. Details bei Fehlern, Regelentscheidungen oder ausdrücklichem Wunsch.
- Ausführliche Setup-Hinweise: `docs/development/CLAUDE-STACK.md`, nur bei Bedarf lesen.

## Testregeln (verbindlich, Markus 01.10.2026)
1. Während der Arbeit nur die Tests der direkt geänderten Dateien ausführen. Nie die komplette Suite zwischendurch.
2. Komplette Suite höchstens einmal pro Auftrag, ganz am Ende, und nur wenn Regelkern (`core/`), Speichern/Laden oder Befehle geändert wurden. Bei reiner Oberflächen- oder Grafikarbeit: keine komplette Suite.
3. Der Fuzz-Test (`test_role_interaction_fuzz`) läuft nur bei Änderungen am Regelkern oder vor einem Merge nach main.
4. Keine neuen Tests für Positionen, Abstände oder Aussehen. Das wird per Screenshot geprüft.
5. Neue Tests nur für echte Logik, die still kaputtgehen kann (Speichern, Geheimhaltung, Regeln). Höchstens ein kleiner Test pro neuer Funktion, außer Markus verlangt mehr.
6. Lange Testläufe im Hintergrund starten und einmal auf das Ende warten. Kein wiederholtes Nachschauen oder Neu-Starten von Wartebefehlen.
7. Im Bericht immer angeben: welche Tests liefen und warum.
8. „Nur wenn grün“ vor Merge oder Push heißt: Die Vollsuite läuft auf dem finalen Stand VOR dem Push grün. Gezielte Tests nach einem Fix ersetzen das nicht; nach einem roten Lauf und Fix die Vollsuite vor dem Push wiederholen.
- Weiter gültig: Bekannte Fehler nicht ignorieren und Tests nie abschwächen, um Läufe zu sparen. Unveränderten grünen Stand nicht nachtesten, nur weil CI ebenfalls läuft; erforderliche CI bleibt aktiv. Nach ausreichender Prüfung abschließen, keine weitere Audit-Runde. Diese Regeln auch in künftige Arbeits- und Übergabeprompts übernehmen; ältere pauschale Testvorgaben (z. B. DE/EN-, Auflösungs- oder Fuzz-Matrizen) sind dadurch eingegrenzt.

## Ausgabedateien: Nutzerentscheidung vom 01.10.2026
- Roadmaps, Berichte, Bilder, Archive und andere zur Übergabe erzeugte Dateien standardmäßig unter C:/Users/Marku/Downloads/ ablegen, bei mehreren zusammengehörigen Dateien in einem verständlich benannten Unterordner. Im Abschluss direkt auf die Datei in Downloads verlinken. Projektcode und notwendige versionierte Projektdateien bleiben im jeweiligen Repository; bei gewünschten Übergabedokumenten eine Kopie in Downloads bereitstellen. Bestehende Downloads nicht ungefragt überschreiben.

## Cloud-Sitzungen
- Godot kommt aus `tools/cloud/setup-godot.sh` (SessionStart-Hook in `.claude/settings.json`, nur bei `CLAUDE_CODE_REMOTE`): Godot 4.7.2 headless mit Prüfsumme nach `~/.local/godot`, Befehl `godot`, einmal `--import`. Fehlt `godot`, das Skript manuell starten.
- Testregeln wie oben (Abschnitt Testregeln), Linux-Befehle aus `godot/README.md`.
- Kein Web-Export und kein Vercel-Deploy aus der Cloud.
- Screenshots headless nach `docs/screenshots/cloud/`.
- Immer eigener Branch, nie direkt auf `main`.
