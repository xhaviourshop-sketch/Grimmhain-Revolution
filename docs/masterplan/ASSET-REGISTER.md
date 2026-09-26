# Assetregister

Kein Asset gelangt in einen öffentlichen Build, solange Pflichtfelder fehlen.

## Register

Das vollständige Register liegt maschinenlesbar in [`asset-register.csv`](asset-register.csv): eine Zeile je versionierter Mediendatei, Trennzeichen Semikolon, UTF-8 (in Excel/LibreOffice direkt öffnbar). Bestandsaufnahme und Befunde: [`../assets/INVENTORY.md`](../assets/INVENTORY.md). Produktionsplan: [`../assets/PRODUCTION-PLAN.md`](../assets/PRODUCTION-PLAN.md).

Prüfung (Exit-Code 1 bei Befunden):

```bash
node tools/check-asset-register.js
```

Das Werkzeug meldet nicht registrierte Mediendateien, fehlende oder veränderte Dateien (SHA-256), leere Pflichtfelder, unbekannte Status, `freigegeben` ohne Product-Owner-Eintrag oder mit ungeklärter Lizenz, und jede Datei unter `godot/`, die nicht `freigegeben` ist.

| Status | Bedeutung | Darf in einen Build |
|---|---|---|
| `freigegeben` | Herkunft, Lizenz und Tarif belegt, Product Owner hat nach Sicht- oder Hörprüfung freigegeben (`po_freigabe` = Datum und Name) | ja |
| `ki-nachgewiesen` | KI-Herkunft per C2PA belegt; Tarif, Prompt, Bedingungen oder Freigabe fehlen | nein, höchstens Entwicklungsbuild |
| `lizenz-belegt-datei-fehlt` | Lizenz aus der Datei ablesbar, vorgeschriebener Lizenztext liegt nicht bei | nein |
| `ungeklärt` | keine belastbare Herkunft | nein |
| `gesperrt` | ausdrücklich gesperrt | nein |
| `prüfartefakt` | eigener Screenshot für Dokumentation | nein, nie |

Nur der Product Owner setzt `freigegeben`. Claude trägt diesen Status nie selbst ein.

Stand 2026-09-26: 266 Dateien, **0 freigegeben**, 219 ungeklärt, 24 ki-nachgewiesen, 10 gesperrt, 4 lizenz-belegt-datei-fehlt, 9 prüfartefakt.

| Asset-ID | Datei | Zweck | Ersteller/Dienst | Erstellungsdatum | Tarif/Modell | Lizenzquelle | Bearbeitung | Releasefreigabe | Ersatz nötig |
|---|---|---|---|---|---|---|---|---|---|
| legacy-night-music | `assets/sounds/Nachtmusik.mp3` | Nachtmusik | unbekannt | unbekannt | unbekannt | **ungeklärt**; Product Owner 2026-09-26: kein belastbarer Lizenz- oder Herkunftsnachweis | unbekannt | gesperrt | ja (`music-night`, Produktionsplan §6.2) |

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
