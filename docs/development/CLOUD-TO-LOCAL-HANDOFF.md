# Grimmhain: Übergabe Claude Web an Claude Code lokal

Stand geprüft: 27.09.2026. Dies ist eine Integrationsübergabe, keine Abnahme aller Spielregeln und kein bereits erfolgter Merge.

## 0. Ergebnis der lokalen Integration (27.09.2026)

Die Abschnitte 1 bis 7 beschreiben den Auftrag vor der Integration. Dieser Abschnitt ist der aktuelle Stand. Abweichend von §2 und §4.A lagen CLAUDE.md, Skills, `docs/development/` und die Editor-Neuspeicherung von `godot/project.godot` bereits auf `main` (`cb7c394`); nichts musste kopiert werden.

- Worktree: `C:/Users/Marku/Desktop/Grimmhain/grimmhain-integration-20260927`, Branch `integration/cloud-to-local-20260927` ab `main` `cb7c394`. Nicht gepusht, nicht nach `main` gemergt.
- Integriert (Fetch am 27.09.: keine neueren Commits): Assets `55ad4d5`, UI `53a3c7d`, Rollenplanung `fc38043`. Alle drei Merges ohne Konflikt; keine Datei gelöscht.
- Integrationskorrekturen:
  - `tools/role-migration/check-role-docs.js`: CSV-Zeilen über `csvLines()` (`/\r?\n/`) statt `split("\n")`; Regressionstest `tests/check-role-docs.test.js` (LF, CRLF, BOM) war vorher rot.
  - `docs/masterplan/asset-register.csv`: 19 Rollen-Setup-Screenshots ergänzt, 8 Spieler-Setup-Zeilen (Hash, Größe, Datum laut Screenshot-README) aktualisiert; alle 27 Dateien stimmen mit `docs/evidence/role-setup/asset-handoff.md` überein; Status `prüfartefakt`, keine Freigabe. Zählzeile in `ASSET-REGISTER.md` auf Werkzeugausgabe gebracht.
  - Dokumentkonsistenz: Scheinrolle des Trugbilderwolfs wählt der Spielleiter (DR-08), alter Übergabehinweis zu `7837809` als historisch markiert; `implemented` in `RULE-MIGRATION-MATRIX.md` ist reiner Regelkernstatus.
- Schriftmuster: Die vier SHA-256-Werte in `font_specimen.gd`, die Dateien unter `assets/fonts/` und das Register stimmen überein. Die Demo lädt `../assets/fonts` außerhalb des Godot-Projekts; sie funktioniert nur aus dem Repository, nicht im Export. Keine Schriftfreigabe; Cinzel-ß bleibt offene Gestaltungsfrage.

### Lokale Prüfungen (Windows, Godot `4.7.2.stable.official.ed1daf0bf` = Pin)

| Prüfung | Ergebnis |
|---|---|
| Godot-Import (`windows-checks.md`) | Exit 0 |
| Godot-Suite `res://tests/run_tests.gd` | 438 Tests, 0 fehlgeschlagen, 0 nicht ladbar, Exit 0 |
| `node tools/check-asset-register.js` | 299 Zeilen / 299 Dateien, Exit 0 |
| `node --test tests/check-asset-register.test.js tests/check-role-docs.test.js` | 20 Tests, 0 fehlgeschlagen, Exit 0 |
| `node tools/role-migration/check-role-docs.js` (CRLF-Checkout) | keine Fehler, Exit 0 (vor Korrektur: „unerwarteter Kopf“, Exit 1) |
| Schriftmuster `check_font_specimen.gd` headless | 6 Ansichten, 0 Befunde, Exit 0 |
| `git diff --check main HEAD` | 2 Befunde: Leerzeichen am Zeilenende in `assets/fonts/OFL-Cinzel.txt:22` und `OFL-IMFellEnglish.txt:21` (wörtliche Lizenztexte, bewusst nicht geändert) |

Grafisch (lokaler Bildschirm, OpenGL 3.3 Compatibility, AMD Radeon RX 6700 XT): App mit `--path godot --quit-after 600` gestartet, Exit 0, keine Fehler im Log. Setup-Ablauf mit `godot/tools/capture_ui_screenshots.gd -- --out=<Scratchpad>` gefahren (skriptgesteuert über echte Buttons, keine Handbedienung): 32 Aufnahmen, 0 Fehler; Stichproben Rollenwahl, fehlende Scheinrolle, verborgene Verteilung, „Bereit für Sitzordnung“ entsprechen den Cloud-Aufnahmen. Registrierte Screenshots wurden nicht neu erzeugt. Keine Tablet- oder Touchprüfung.

### Offen

- Blockierend für die Übernahme nach `main`: keine bekannten Prüffehler. Offen ist nur die Nutzerentscheidung, den Branch zu mergen und zu pushen.
- Später: Tablet-/Touchabnahme des Setups (auch `emulate_mouse_from_touch` nach Editor-Neuspeicherung); vier Fragen aus `docs/role-migration/10-next-decisions.md`; Test auf exakt elf Rollen vor Katalogerweiterung; Exportweg für Schriften; „Scheinrollen festgelegt: 1 von 2“ bricht bei 1024×768 um (bekannt, belassen); `StartGame`/Sitzordnung fehlt.

## 1. Eindeutiger Ausgangsstand

Repo: `C:/Users/Marku/Desktop/Grimmhain/Grimmhain - Revolution`.
Remote: `https://github.com/xhaviourshop-sketch/Grimmhain-Revolution`.
Lokales main und origin/main: `5eb5f2a` nach Fetch.

| Sitzung | Remote-Branch | Erwarteter HEAD | Inhalt |
|---|---|---|---|
| Grimmhain-1 | `claude/sleepy-babbage-u2o0i2` | `53a3c7d` | Rollenpool/Verteilung, DR-08-Korrektur: explizite Scheinrolle je Rollenkopie, Screenshots |
| Grimmhain-2 | `claude/happy-bell-dhgkod` | `fc38043` | Rollenbestandsaufnahme, konsolidierte Entscheidungen, Dokumentationsprüfer |
| Grimmhain-3 | `claude/wizardly-maxwell-kay292` | `55ad4d5` | Assetregister/CI, korrigierte Freigabeaussagen, isolierte Schriftmuster-Demo |

Grimmhain-3 verwechselt in seinem Bericht Chatnummern: sleepy-babbage und die Theme-/Setup-Arbeit gehören zu Grimmhain-1. Branch/Commit sind maßgeblich. Grimmhain-2 bewertete noch den älteren UI-Stand 7837809; die dort erwähnte zufällige Scheinrolle ist im aktuellen UI-Branch korrigiert.

Originalberichte: `cloud-reports/2026-09-27/grimmhain-1.txt`, `grimmhain-2.txt`, `grimmhain-3.txt`. Nur bei konkretem Nachschlagebedarf vollständig lesen.

## 2. Lokal unbedingt erhalten

Uncommittet vorhanden: überarbeitete Root-CLAUDE.md, elf Projekt-Skills unter `.claude/skills/`, Setup-/Auswahlberichte und Quellen/Lizenzen unter `docs/development/`.

`godot/project.godot` enthält eine separate lokale Editoränderung. Nicht überschreiben, stagen oder in die Cloud-Integration aufnehmen. Im Diff stehen u. a. entfernte explizite Einstellungen für Touch-Mausemulation und Sprachfallback; deshalb nicht pauschal als bedeutungsloses Formatieren abtun. Bestehender SHA-256: `65D80861B9184ADF20490663C8EC17811459035EF4174B372B0392BD5ED07521`.

Neu vorhanden sind außerdem Root-`DECISIONS.md` und `LESSONS.md` mit leeren Vorlagen. Entstehung nicht belegt, kompatibel mit dem bereits dokumentierten globalen Dokumentations-Hook. Erhalten; nicht als fachliche Entscheidungsquelle verwenden. Verbindliche Entscheidungen stehen unter `docs/masterplan/DECISION-LOG.md`.

## 3. Was tatsächlich verifiziert wurde

- Remote-HEADs nach Fetch stimmen mit den Berichten überein.
- Paarweiser Vergleich der gegenüber main geänderten Dateipfade: keine Überschneidungen zwischen den drei Cloud-Branches. Das ist kein Beweis für semantische Konfliktfreiheit.
- [UI-Branch Godot-CI](https://github.com/xhaviourshop-sketch/Grimmhain-Revolution/actions/runs/36299937570): success, HEAD 53a3c7d. Bericht nennt 438 Tests.
- [Asset-Branch Godot-CI](https://github.com/xhaviourshop-sketch/Grimmhain-Revolution/actions/runs/36300019187): success, HEAD 55ad4d5.
- [Asset-Branch Register-CI](https://github.com/xhaviourshop-sketch/Grimmhain-Revolution/actions/runs/36300019179): success, HEAD 55ad4d5. Die im Bericht noch offene CI ist damit geklärt.
- Für Grimmhain-2 lieferte die Branch-Abfrage keine CI-Läufe. Sein Dokumentprüfer muss lokal ausgeführt werden.
- Auf dem bisherigen lokalen main liefen zuvor 387 Godot-Tests grün. Der kombinierte Stand wurde hier nicht gebaut oder getestet.

## 4. Konkrete Integrationsarbeiten

### A. Reihenfolge und Arbeitsverzeichnis

Zuerst frischen Branch in getrenntem Git-Worktree von 5eb5f2a erstellen. Das schmutzige aktuelle Arbeitsverzeichnis bleibt unangetastet. Darin die explizit genannten drei Commitstände integrieren:
1. Asset-Branch 55ad4d5: Registerkorrektur/CI und Demo.
2. UI-Branch 53a3c7d: fertiges Rollen-Setup mit Scheinrollenkorrektur.
3. Rollen-Dokumentation fc38043.

Bei inzwischen fortgeschrittenen Remotes Abweichung melden und erst den Unterschied prüfen. Nicht blind neue Arbeit integrieren. Fehlgeschlagene Mergeversuche nicht mit pauschalem ours/theirs lösen.

Die aktuellen lokalen Claude-Anweisungen/elf Skills/Setup-Dokumente müssen explizit in den neuen Worktree übernommen werden, weil ein Worktree uncommittete Dateien nicht mitnimmt. Nur diese benannten Bereiche kopieren; keine .claude/settings.local.json, Credentials, globalen Einstellungen oder project.godot. Die installierten Skills werden durch skill-sources.lock.json und die jeweiligen Hashes identifiziert.

### B. Assetregister: 27 UI-Prüfartefakte

`docs/evidence/role-setup/asset-handoff.md` listet 19 neue und acht geänderte PNG-Dateien mit Hash/Größe. Am kombinierten Stand echte Dateien nachprüfen. 19 Einträge ergänzen, acht aktualisieren, Status Prüfartefakt und Herkunft beibehalten. Keine pauschale Freigabe produktiver Medien.

Asset-Branch allein: laut Bericht 280 Mediendateien. Kombiniert werden bei unverändertem Umfang 299 erwartet. Tatsächlichen Scan verwenden; Zahl nicht im Prüfer festschreiben. Grün im UI-Godot-Workflow beweist noch kein vollständiges Register.

### C. Windows-CRLF im Rollen-Dokumentprüfer

Bestätigter Quellbefund in `tools/role-migration/check-role-docs.js`:
`readFileSync(...).trim().split("\n")`, danach exakter Vergleich der ersten Zeile mit `id;teilfrage;rolle;status;quelle;hinweis`.

Die aus Git gelesene echte CSV wurde mit der gleichen Kopfzeilenlogik geprüft: LF akzeptiert, CRLF abgelehnt. Die Asset-Branch-.gitattributes fixiert nur asset-register.csv, nicht decision-status.csv.

Auf dem integrierten Stand einen kleinen Regressionstest für LF/CRLF ergänzen, Fehler nachstellen und Parser gezielt robust machen. Keine Umgehung durch Abschalten der Prüfung. BOM-Verhalten bewusst beibehalten/dokumentieren; keine unnötige CSV-Framework-Neuentwicklung.

### D. Dokumentation und Schriftmuster

- Den alten Hinweis auf zufällige Scheinrollen in der Rollen-Analyse als historischen Stand kennzeichnen; DR-08 selbst nicht ändern.
- Status „implemented“ in RULE-MIGRATION-MATRIX eindeutig als Regelkernstatus einordnen, nicht volle UI-/Geräteabnahme.
- Schriftmuster ist eine isolierte Repo-Demo: `godot/asset_lab/font_specimen/font_specimen.tscn`, F6. Kein exportierbares Tablet-Muster. Der vorgeschlagene direkte Tablet-Test ist erst nach geeignetem Exportweg möglich.
- Font-Hashes stehen im Demo-Code als übernommene Werte aus dem Register, es wird nicht bei jedem Start das Register selbst neu gelesen. Bei Integration Konsistenz dieser Werte mit Dateien/Register prüfen. Keine Releasefreigabe ableiten.
- Keine Schriftfreigabe, Q8-Entscheidung oder neue Kaufgenehmigung aus den Berichten ableiten. Cinzel-ß-Befund bleibt eine offene Gestaltungsfrage.

## 5. Prüfungen des kombinierten Standes

Windows-Godot vorhanden unter:
`C:/Users/Marku/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.
Gepinnte Version 4.7.2-stable gegen Repository prüfen. Native Anleitung: `.claude/skills/grimmhain-core/windows-checks.md`; keine Linux-EXE unter Windows starten.

Nach den Integrationskorrekturen:
- Godot-Import und vollständiger vorhandener Runner; mindestens die berichteten 438 Tests bei unverändertem Testumfang erwarten, nicht eine feste Zahl erzwingen.
- `node tools/check-asset-register.js`.
- `node --test tests/check-asset-register.test.js`.
- `node tools/role-migration/check-role-docs.js` sowie neuer LF/CRLF-Regressionstest.
- Schriftmuster-Layoutprüfung: Godot headless mit `--path godot -s res://asset_lab/font_specimen/check_font_specimen.gd`.
- `git diff --check` und Diff auf unbeabsichtigte Core-/Konfigurationsänderungen prüfen.
- Grafischen Appstart getrennt prüfen, sofern verfügbar; Headless/Layoutprüfung nicht als Tablet-Test darstellen. Keine Screenshots grundlos neu erzeugen und dadurch registrierte Dateien verändern.

Neue Prüffehler nach Ursache untersuchen. Bestehende fachliche Tests nicht zum Grünmachen abschwächen. Die Rollenprüfung nutzt teilweise Remote-Refs für historische Quellenpfade: ein Fehler wegen fehlender Ref ist nicht automatisch ein Inhaltsfehler.

## 6. Was nicht in diesen Integrationsauftrag gehört

Keine neuen Rollen, keine neue Sieglogik, kein StartGame-/Sitzordnungsfeature, kein AudioDirector, keine Produktionsgrafik, kein Storeexport. Zuerst einen gemeinsam geprüften Ausgangsstand herstellen.

Die vier Fragen aus `docs/role-migration/10-next-decisions.md` bleiben offen: nächste Rollencharge, Lebendbedingung Doppelspion, konkurrierender Dorfsieg, nächtliche Information der Wölfe. Diese blockieren neue Rollenspezifikationen, nicht die Integration.

Der UI-Test erwartet derzeit exakt elf Rollen. Vor späterer Katalogerweiterung muss dieser Vertrag zusammen mit Präsentationsreihenfolge/DE/EN angepasst werden; jetzt nichts daran lockern.

## 7. Abschluss der lokalen Integration

Kompakter Bericht: Integrationsbranch/-pfad, übernommene Commitstände, zusätzliche Korrekturen, echte Prüfergebnisse/Exit-Codes, nicht geprüfte Geräte/UI, offene Entscheidungen und ein nächster Auftrag. Keine erneute komplette Bestandsaufnahme. Empfohlener Folgefokus nach grüner Integration: Setup-Sitzordnung gemäß bestehendem Plan; noch keine Rolle ohne Entscheidungen beginnen.
