# Schriften · Lizenz und Herkunft

**Stand:** 2026-09-27 · **Status im Register:** `lizenz-belegt` (Lizenztext liegt bei, Product-Owner-Freigabe steht aus). Keine Schrift ist in das Godot-Projekt übernommen; `godot/` nutzt weiter die Standardschrift der Engine (`docs/ui/README.md`, „Schrift").

## 1. Was belegt ist und was nicht

| | Cinzel Regular, Bold | IM FELL English Roman, Italic |
|---|---|---|
| Dateien | `assets/fonts/Cinzel-Regular.ttf`, `Cinzel-Bold.ttf` | `assets/fonts/IMFellEnglish-Regular.ttf`, `IMFellEnglish-Italic.ttf` |
| **Eingebettete Lizenzangabe** (name-Tabelle, ID 13/14) | „This Font Software is licensed under the SIL Open Font License, Version 1.1." · `https://scripts.sil.org/OFL` | „This Font Software is licensed under the SIL Open Font License, Version 1.1." · `http://scripts.sil.org/OFL` |
| Eingebettetes Copyright (ID 0) | „Copyright 2020 The Cinzel Project Authors (https://github.com/NDISCOVER/Cinzel)" | „© 2007 Igino Marini (www.iginomarini.com) With Reserved Font Name IM FELL English Roman" bzw. „… Italic" |
| Designer (ID 9) | Natanael Gama | Igino Marini |
| Version (ID 5) | Version 2.000 | 3.00 |
| **Heutige offizielle Referenzquelle** | Projekt-Repository `github.com/NDISCOVER/Cinzel` (geprüft am 2026-09-27, Commit `dd598495`), zusätzlich Google Fonts `github.com/google/fonts`, Ordner `ofl/cinzel` (dort als Quelle eingetragen: NDISCOVER/Cinzel) | Google Fonts `github.com/google/fonts`, Ordner `ofl/imfellenglish`; dort als Quelle eingetragen: `github.com/librefonts/imfellenglish` (Commit `4cc24726`, am 2026-09-27 geprüft). Die frühere Autorenseite `iginomarini.com/fell` führt heute zu einem anderen Angebot und enthält keinen Lizenztext. |
| **Beiliegender Lizenztext** | `assets/fonts/OFL-Cinzel.txt` = `OFL.txt` aus NDISCOVER/Cinzel, bytegleich (SHA-256 `a4662419…`) | `assets/fonts/OFL-IMFellEnglish.txt` = `OFL.txt` aus librefonts/imfellenglish (identisch mit google/fonts), einzige Änderung: CRLF → LF |
| Abgleich mit der Referenzdatei | gleiche Version und gleicher PostScript-Name, **nicht bytegleich**; unsere Datei enthält eine STAT-Tabelle, die Repository-Datei nicht | gleiche Version und gleicher PostScript-Name, **nicht bytegleich** (191 256 statt 194 992 Byte) |
| **Ursprüngliche Bezugsquelle** | **unbekannt** (Angabe im Arbeitsauftrag vom 2026-09-27; im Repository kein Beleg) | **unbekannt** (wie links) |

**Einordnung.** Die Lizenz ergibt sich aus der Schriftdatei selbst. Die OFL gilt für jede Kopie der Font Software, unabhängig davon, wo sie heruntergeladen wurde. Die unbekannte Bezugsquelle ist deshalb eine Dokumentationslücke, keine Lizenzlücke. Die Byte-Abweichung passt zu einer von Google Fonts ausgelieferten, aufbereiteten Fassung (bei Cinzel etwa eine aus der variablen Schrift erzeugte statische Datei). Das ist ein Hinweis, kein Beleg; eine Downloadhistorie wird nicht behauptet.

**Hinweis zum Copyright-Kopf von IM FELL.** Der offizielle `OFL.txt` nennt „Copyright (c) 2010, Igino Marini", die Schriftdatei „© 2007 … With Reserved Font Name IM FELL English Roman/Italic". Der Lizenztext wurde unverändert übernommen. Maßgeblich für den Reserved Font Name ist die Angabe in der Schriftdatei, die mit der Datei weitergegeben wird.

## 2. Pflichten aus der OFL 1.1 für Grimmhain

Zusammenfassung zur Orientierung, keine Rechtsberatung. Verbindlich ist der Lizenztext.

1. **Mitliefern:** Jede ausgelieferte Kopie der Schrift braucht Copyright-Hinweis und Lizenztext. In einer App genügt es, die Lizenztexte im Paket mitzuliefern und in einer Lizenzansicht in der App anzuzeigen (Masterplan Phase 9 „Lizenzseite").
2. **Nicht einzeln verkaufen:** Die Schrift darf in einem verkauften Produkt eingebettet sein, aber nicht für sich allein verkauft werden.
3. **Reserved Font Name:** Eine veränderte Fassung (Subset mit entfernten Glyphen, umgewandelte oder umbenannte Datei) darf nicht „IM FELL English" bzw. „Cinzel Decorative" heißen. Für Cinzel (Regular/Bold) ist im heutigen Projekt-`OFL.txt` nur „Cinzel Decorative" reserviert.
4. **Keine Werbung mit den Autorennamen** ohne deren Zustimmung.
5. **Godot-Import:** Der Import legt eine Cache-Fassung im Ordner `.godot/` an und bettet die Schrift beim Export ein. Nach verbreiteter Auslegung ist das keine Veränderung im Sinn der OFL; wird die Schrift beim Export gezielt auf einen Zeichensatz reduziert, gilt Punkt 3 vorsorglich.

## 3. Nicht im Repository, aber im Legacy-Code geladen

| Schrift | Wo | Stand |
|---|---|---|
| Cinzel Decorative (700, 900) | `app/index.html:16-21`, Google-Fonts-CDN | nicht lokal, nicht registriert; für eine Offline-App lokal mit Lizenztext bereitstellen oder weglassen |
| Cinzel (400, 700, 800), Fondamento | `game.html:13-15`, Google-Fonts-CDN | wie oben |

Das betrifft nur die Legacy-Web-App. Für Godot werden Schriften ausschließlich lokal eingebunden.

## 4. Lesetextschrift (offen)

`05-visual-audio-direction.md` §2.3 verlangt eine gut lesbare Schrift für Bedientext, Namen und Zahlen. Kandidaten, beide unter OFL 1.1 (Lizenzkopf am 2026-09-27 im jeweiligen Repository geprüft): **Source Sans 3** (`github.com/adobe-fonts/source-sans`, Reserved Font Name „Source“, „Source“ ist eine Marke von Adobe) und **Alegreya Sans** (`github.com/huertatipografica/Alegreya-Sans`, ohne Reserved Font Name). Die Auswahl trifft der Product Owner nach einem Lesbarkeitstest bei 14 bis 20 sp auf 1024×768. Bei der Übernahme gilt: Datei direkt aus dem Projekt-Repository laden, Commit und SHA-256 im Register notieren, `OFL.txt` wörtlich beilegen.

## 5. Weg zur Freigabe

1. Product Owner sieht Lizenztexte und diese Seite durch.
2. Product Owner trägt in den vier Registerzeilen `po_freigabe` (Datum, Name) ein und setzt den Status auf `freigegeben`. Claude setzt diesen Status nicht.
3. Erst danach können die Schriften in einem eigenen Arbeitspaket in `godot/` übernommen werden, zusammen mit den Lizenztexten und einem Test, der ihr Vorhandensein prüft (Vorbild: `test_no_unlicensed_fonts_embedded`).

## 6. Nutzung im internen Schriftmuster (2026-09-27)

`godot/asset_lab/font_specimen/` zeigt Cinzel und IM FELL English als interne Vorschau. Einschätzung vor der Nutzung:

- **Vertretbar für eine interne Vorschau:** Familie, Version und SIL OFL 1.1 stehen in den Dateien selbst; die Lizenztexte liegen bei. Die OFL erlaubt Nutzung und Weitergabe jeder Kopie.
- **Offener Zweifel zur Dateiidentität:** Die Dateien sind nicht bytegleich mit den heutigen Referenzdateien. Versionsgleichheit beweist nicht, dass es unveränderte Originaldateien sind. Konkrete Hinweise auf eine fehlerhafte Lizenzzuordnung gibt es nicht.
- **Keine Kopie ins Godot-Projekt:** Die Szene lädt die Dateien zur Laufzeit aus `assets/fonts/` und prüft vorher den SHA-256 gegen das Register. Der Registerstatus bleibt `lizenz-belegt`; die Vorschau ist keine Freigabe.
- **Beobachtung:** Cinzel stellt ß als „SS" dar (Kapitälchenschrift). Für Spielernamen ist das bei der Schriftwahl zu berücksichtigen. Screenshots: `docs/evidence/asset-lab/font-specimen/`.
