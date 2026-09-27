# Assetregister

Kein Asset gelangt in einen öffentlichen Build, solange Pflichtfelder fehlen.

## Register

Das vollständige Register liegt maschinenlesbar in [`asset-register.csv`](asset-register.csv): eine Zeile je versionierter Mediendatei, Trennzeichen Semikolon, UTF-8 (in Excel/LibreOffice direkt öffnbar). Bestandsaufnahme und Befunde: [`../assets/INVENTORY.md`](../assets/INVENTORY.md). Produktionsplan: [`../assets/PRODUCTION-PLAN.md`](../assets/PRODUCTION-PLAN.md).

Prüfung (Exit-Code 1 bei Befunden):

```bash
node tools/check-asset-register.js
```

Das Werkzeug meldet nicht registrierte Mediendateien, fehlende oder veränderte Dateien (SHA-256), leere Pflichtfelder, unbekannte Status, `freigegeben` ohne Product-Owner-Eintrag oder mit ungeklärter Lizenz, `prüfartefakt` außerhalb von `docs/evidence/` und `docs/screenshots/`, und jede Datei unter `godot/`, die nicht `freigegeben` ist. Formal prüft es: gültiges UTF-8 ohne BOM, exakte Kopfzeile, gleiche Spaltenzahl, keine unsichtbaren Zeichen in Zellen. LF- und CRLF-Zeilenenden sind beide gültig. Regressionstests: `node --test tests/check-asset-register.test.js`.

**Dateiformat beim Bearbeiten.** Am sichersten mit LibreOffice Calc (Zeichensatz UTF-8, Feldtrenner Semikolon, kein Texttrenner) oder einem Texteditor bearbeiten. Excel ist ungeeignet: „CSV UTF-8" fügt einen BOM ein, „CSV (Trennzeichen-getrennt)" speichert in Windows-1252 und zerstört Umlaute. Das Werkzeug meldet beides ausdrücklich. Semikolons im Text durch Kommas ersetzen.

### Neue Mediendateien registrieren (auch Prüf-Screenshots)

Es gibt keine Pfad-Ausnahme: Jede neue Mediendatei braucht eine Registerzeile im selben Commit, sonst wird die CI rot. Ablauf für jede Sitzung, die Bilder, Audio oder Schriften versioniert:

1. Datei anlegen und mit `git add` vormerken (das Werkzeug liest den Git-Index).
2. `node tools/check-asset-register.js --suggest` ausführen. Für Dateien unter `docs/evidence/` oder `docs/screenshots/` erscheint eine vollständige Zeile mit Status `prüfartefakt`; für alle anderen Pfade eine Zeile mit Status `ungeklärt` und `TODO`-Feldern.
3. Zeile prüfen: Erstellungsdatum und Herkunft konkret eintragen (bei Screenshots Datum und erzeugendes Werkzeug, z. B. `godot/tools/capture_ui_screenshots.gd`), `TODO`-Felder vollständig ersetzen.
4. Zeile in `docs/masterplan/asset-register.csv` einfügen, nach Spalte `datei` sortiert.
5. Wird ein vorhandener Screenshot neu erzeugt, ändert sich sein SHA-256: Zeile anpassen (neuer Hash, neue Größe), nicht löschen und neu anlegen.
6. `node tools/check-asset-register.js` muss grün sein, bevor committet wird.

`prüfartefakt` ist nur für eigene Screenshots der App gedacht. Fremdes Material, KI-Bilder oder Konzeptskizzen in `docs/` bekommen ihren tatsächlichen Status (`ungeklärt`, `ki-nachgewiesen` …).

| Status | Bedeutung | Darf in einen Build |
|---|---|---|
| `freigegeben` | Herkunft, Lizenz und Tarif belegt, Product Owner hat nach Sicht- oder Hörprüfung freigegeben (`po_freigabe` = Datum und Name) | ja |
| `ki-nachgewiesen` | KI-Herkunft per C2PA belegt; Tarif, Prompt, Bedingungen oder Freigabe fehlen | nein, höchstens Entwicklungsbuild |
| `lizenz-belegt` | Lizenz belegt und vorgeschriebener Lizenztext liegt bei; Product-Owner-Freigabe steht aus | nein, erst nach Freigabe |
| `lizenz-belegt-datei-fehlt` | Lizenz aus der Datei ablesbar, vorgeschriebener Lizenztext liegt nicht bei | nein |
| `ungeklärt` | Herkunftsnachweis fehlt; Nutzung nicht freigegeben (keine Aussage über rechtliche Zulässigkeit) | nein, solange nicht freigegeben |
| `gesperrt` | ausdrücklich gesperrt, mit Beleg für die Sperre (z. B. Masterplan Phase 0 für die Nachtmusik) | nein |
| `prüfartefakt` | eigener Screenshot für Dokumentation | nein, nie |

Nur der Product Owner setzt `freigegeben`. Claude trägt diesen Status nie selbst ein.

Stand 2026-09-27 (Werkzeugausgabe nach Sitzordnung): 308 Dateien, **0 freigegeben**, 228 ungeklärt, 24 ki-nachgewiesen, 1 gesperrt (Nachtmusik), 4 lizenz-belegt (Schriften, siehe `../assets/FONTS.md`), 51 prüfartefakt. Die neun kurzen Legacy-Sounds standen bis zur Korrektur vom 27.09. ohne Beleg auf `gesperrt`.

| Asset-ID | Datei | Zweck | Ersteller/Dienst | Erstellungsdatum | Tarif/Modell | Lizenzquelle | Bearbeitung | Releasefreigabe | Ersatz nötig |
|---|---|---|---|---|---|---|---|---|---|
| legacy-night-music | `assets/sounds/Nachtmusik.mp3` | Nachtmusik | unbekannt | unbekannt | unbekannt | **ungeklärt**; Nutzer 2026-09-26: kein belastbarer Lizenz- oder Herkunftsnachweis, nicht für Veröffentlichung freigegeben | unbekannt | gesperrt (Masterplan Phase 0) | Empfehlung (`music-night`, Produktionsplan §6.2) |

## Pflichtregeln

- [ ] Quelldatei und exportierte Laufzeitdatei getrennt archivieren.
- [ ] Prompt und verwendetes KI-Modell dokumentieren, wenn relevant.
- [ ] Kommerzielle Nutzungsbedingungen zum Erstellungsdatum sichern.
- [ ] Fremde Marken, Figuren und erkennbare Vorlagen ausschließen.
- [ ] Schriften zusammen mit vorgeschriebener Lizenzdatei speichern.
- [ ] Musik, Stimmen und Sounds auf Trainierungs-/Stimmrechte und Store-Regeln prüfen.
- [ ] Product-Owner-Freigabe nach Sicht- oder Hörprüfung eintragen.
- [ ] Reduced-Motion- oder stumme Alternative für zentrale Cues vorsehen.

## Produktionspriorität

1. UI-Symbole und lesbare Rollenmarker.
2. Hauptdorf Tag/Nacht und atmosphärische Ebenen.
3. Vertical-Slice-Porträts.
4. Schutz-, Angriff-, Tod-, Morgen- und Lynch-Cues.
5. Musik, Ambiente und Erzähler DE/EN.
6. restliche 1.0-Rollen und Szenariovarianten.
