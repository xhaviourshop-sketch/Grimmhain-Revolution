# Assets und Audio · Bestandsaufnahme

**Stand:** 2026-09-26 · **Umfang:** alle 266 versionierten Mediendateien (Bild, Audio, Schrift) im Repository. Keine Datei wurde verändert, verschoben oder in das Godot-Projekt übernommen.
**Detailregister (eine Zeile je Datei):** [`../masterplan/asset-register.csv`](../masterplan/asset-register.csv) · **Regeln:** [`../masterplan/ASSET-REGISTER.md`](../masterplan/ASSET-REGISTER.md) · **Prüfung:** `node tools/check-asset-register.js`

Kennzeichnung: **[B]** Beobachtung aus Datei oder Code, **[S]** Schlussfolgerung, **[E]** Empfehlung.

---

## 1. Ergebnis in fünf Sätzen

1. Keine Mediendatei ist heute für eine Veröffentlichung freigegeben. Für 228 Dateien fehlt ein Herkunftsnachweis, 24 sind per C2PA als KI-Ausgabe von OpenAI belegt, die Nachtmusik ist bis zum Nachweis gesperrt (Masterplan Phase 0). „Nachweis fehlt“ heißt: Nutzung nicht freigegeben, nicht: rechtlich unzulässig. [B, Stand nach Korrektur 2026-09-27]
2. Für die Nachtmusik (60 min) liegt laut Nutzer kein belastbarer Lizenz- oder Herkunftsnachweis vor; sie ist nicht für eine Veröffentlichung freigegeben. Ein Ersatz ist Empfehlung. [B, Nutzer 2026-09-26]
3. Die vier Schriftdateien stehen laut ihrer eigenen Namenstabelle unter der SIL Open Font License 1.1. Es fehlt nur die mitzuliefernde Lizenzdatei. Das ist der einzige Bereich, der sich ohne Neuproduktion heilen lässt. [B]
4. Das Godot-Projekt enthält keine Mediendatei. Die Übernahme ist damit eine freie Entscheidung, keine Altlast. [B]
5. Für Version 1.0 ist bei Grafik und Audio praktisch eine Neuproduktion oder eine nachträgliche Herkunftsdokumentation nötig. Die vorhandenen Bilder taugen als Stil- und Maßreferenz. [S]

## 2. Methode

- Dateiliste: `git ls-files`, gefiltert auf Bild-, Audio-, Video- und Schriftendungen.
- Bilder: Maße aus PNG-/WebP-Header, PNG-Textblöcke, WebP-Chunks, Suche nach C2PA-/JUMBF-Manifesten und bekannten Werkzeugkennungen (OpenAI, ChatGPT, Midjourney, Firefly, Gemini, Suno u. a.). C2PA-Felder `claim_generator_info`, `softwareAgent`, `digitalSourceType` und `when` wurden direkt aus den Manifestbytes gelesen.
- Audio: ID3v2-Tags, erster MPEG-Frame (Bitrate, Abtastrate, Kanäle), Laufzeit aus Xing-/Info-Header.
- Schriften: `name`-Tabelle (Copyright, Lizenzbeschreibung, Lizenz-URL, Designer).
- Verwendung: Suche des Dateinamens bzw. des dynamisch gebildeten Pfads in `js/`, `css/`, den HTML-Seiten, `app/src/` und `godot/`.
- Doppelte Dateien: SHA-256-Vergleich.

**Grenzen.** Eine fehlende Kennung beweist keine menschliche Herkunft: Werkzeuge wie `tools/convert-cards.js` entfernen Metadaten. Umgekehrt beweist ein C2PA-Manifest die erzeugende Plattform, nicht den Tarif, den Prompt oder die zum Zeitpunkt geltenden Nutzungsbedingungen. Rechtliche Bewertung ist nicht Teil dieser Analyse.

## 3. Übersicht nach Gruppen

| Gruppe | Pfad | Dateien | Größe | Technik | Herkunft | Verwendet in | Status |
|---|---|---:|---:|---|---|---|---|
| Rollenkarten DE | `assets/cards/de/` | 73 | 11,3 MB | WebP 839×1400, Text eingebacken | laut `ROADMAP.md:204` ChatGPT + Gemini, in den Dateien nicht mehr belegbar | Legacy, React | ungeklärt |
| Rollenkarten EN | `assets/cards/en/` | 73 | 11,2 MB | wie DE | wie DE | React | ungeklärt |
| Archetyp-Porträts | `app/public/assets/portraits/` | 10 | 22,2 MB | PNG 1254×1254 | **C2PA: OpenAI Media Service API, `gpt-image` 2.0, 2026-06-14** | React | ki-nachgewiesen |
| Dorfplatz Tag/Nacht | `app/public/assets/bg/` | 2 | 0,9 MB | WebP 2560×1600 (entspricht Spezifikation) | keine Metadaten | React | ungeklärt |
| Statussiegel | `app/public/assets/markers/` | 15 | 0,3 MB | WebP mit Alpha, ca. 231×265, uneinheitlich | keine Metadaten | React | ungeklärt |
| UI-Bitmaps | `app/public/assets/ui/` | 45 | 28,6 MB | PNG/WebP gemischt, 7 Format-Doppelungen | keine Metadaten | React (29), unbenutzt (16) | ungeklärt |
| Legacy-Hintergründe | `assets/Tag.png`, `assets/Nacht.png` | 2 | 6,0 MB | PNG 1536×1024 bzw. 1536×832 | **C2PA: ChatGPT, GPT-4o** | Legacy | ki-nachgewiesen |
| App-Icons, Logo | `assets/icons/app/` | 6 | 2,4 MB | PNG 180–512 px, Logo 677×369 | 1× C2PA ChatGPT, Rest ohne Metadaten | Legacy | gemischt |
| Spiel-Icons | `assets/icons/game/` | 6 | 12,0 MB | PNG bis 1536×1024 | 5× C2PA ChatGPT | Legacy | gemischt |
| Setup-Hintergründe | `assets/icons/setup/` | 11 | 27,3 MB | PNG, 2× JPEG mit Endung `.png` | 6× C2PA ChatGPT | Legacy (4), unbenutzt (7) | gemischt |
| Schriften | `assets/fonts/` | 4 | 0,5 MB | TTF Cinzel Regular/Bold, IM Fell English Regular/Italic | **SIL OFL 1.1 laut Namenstabelle** | Legacy | lizenz-belegt-datei-fehlt |
| Audio | `assets/sounds/` | 10 | 58,9 MB | MP3, uneinheitlich 64–320 kbps, 44,1/48 kHz | keine | Legacy (Nachtmusik, `Ruhe.mp3`), sonst stumm oder unbenutzt | Nachtmusik **gesperrt**, 9 Sounds ungeklärt |
| Prüfartefakte | `docs/evidence/`, `docs/screenshots/` | 9 | 4,6 MB | PNG-Screenshots | eigene App | Dokumentation | prüfartefakt |
| **Summe** | | **266** | **186 MB** | | | | **0 freigegeben** |

## 4. Befunde im Einzelnen

### 4.1 KI-Herkunft [B]

- **24 Dateien mit C2PA-Manifest** (`digitalSourceType` = `trainedAlgorithmicMedia`):
  - 14 Legacy-Bilder (`assets/Tag.png`, `assets/Nacht.png`, 1 App-, 5 Spiel-, 6 Setup-Grafiken): Claim-Generator „ChatGPT", Software-Agent „GPT-4o". Das Manifest enthält kein Erstellungsdatum; das Signaturzertifikat gilt ab 2025-04-15.
  - 10 Archetyp-Porträts: Claim-Generator „OpenAI Media Service API", Software-Agent `gpt-image` Version 2.0, Aktion `c2pa.created` am 2026-06-14, zusätzlich `c2pa.watermarked`.
- **Rollenkarten (146 Dateien):** keine Metadaten. `ROADMAP.md:204` nennt ChatGPT und Gemini; die PNG-Master mit möglichen Manifesten sind laut `01-current-system-inventory.md` §6.1 gelöscht. [S] Die Herkunft ist nur noch durch Erinnerung und Kontoverläufe rekonstruierbar.
- **UI, Siegel, Dorfplatz (62 Dateien):** keine Metadaten. [S] Stilistisch aus derselben Produktionslinie wie die Porträts; ohne Beleg bleibt der Status „ungeklärt".
- Nicht gefunden: Midjourney, Firefly, Gemini-, Suno- oder ElevenLabs-Kennungen in Datei-Headern. `PLAN.md:29` nennt Midjourney als geplantes Werkzeug; ein Nachweis im Bestand fehlt.

### 4.2 Audio [B]

| Datei | Länge | Technik | Tags | Verwendung |
|---|---:|---|---|---|
| `Nachtmusik.mp3` | 60:05 min | 128 kbps, 44,1 kHz | nur Encoder `Lavf62.12.101` | Legacy-Nachtmusik (`js/core/night.js:149`) |
| `Ruhe.mp3` | 5,5 s | 128 kbps | Titel/Interpret „RUHE BITTE", Genre „jingle" | Timer-Endton (`js/ui/audio.js`) |
| `Selbstmörder.mp3` | 9,9 s | 128 kbps | Titel „Neue Aufnahme 66", Kommentar „online-audio-converter.com" | stumm (`queueSfxKey` No-op) |
| `Ritter.mp3` | 2,8 s | 64 kbps | „LAME in FL Studio 20", Jahr 2022, 120 BPM | stumm |
| `Amor.mp3`, `Bärenführer.mp3`, `Richter.mp3`, `Spiegel.mp3` | 3,4–11 s | 64–320 kbps, teils 48 kHz | nur Encoder | stumm |
| `Prophet 1.mp3`, `Prophet 2.mp3` | 8 s / 20 s | 96 / 64 kbps | „Prophet 2": Genre „Blues" | unbenutzt |

[S] „Neue Aufnahme 66" deutet auf eine eigene Sprachmemo-Aufnahme, „FL Studio 20" auf eine eigene Produktion. Das ist ein Hinweis, kein Nachweis. Der Nutzer hat am 2026-09-26 bestätigt, dass für die Nachtmusik kein belastbarer Nachweis vorliegt. Die übrigen neun Dateien sind `ungeklärt` (bis zur Korrektur vom 2026-09-27 ohne Beleg als `gesperrt` geführt).

[B] `INSTALL.md:105-108` nennt für die Nachtmusik 83 MB und einen `.gitignore`-Eintrag. Beides stimmt nicht: Die Datei ist mit 57,7 MB versioniert.

### 4.3 Schriften [B]

| Datei | Copyright laut Datei | Lizenz laut Datei | Hinweis |
|---|---|---|---|
| `Cinzel-Regular.ttf`, `Cinzel-Bold.ttf` | 2020 The Cinzel Project Authors (github.com/NDISCOVER/Cinzel), Natanael Gama | SIL OFL 1.1 | Version 2.000 |
| `IMFellEnglish-Regular.ttf`, `-Italic.ttf` | 2007 Igino Marini, **Reserved Font Name** „IM FELL English Roman/Italic" | SIL OFL 1.1 | Version 3.00 |

- Die OFL verlangt, den Lizenztext mit der Schrift weiterzugeben. `OFL.txt` fehlt für beide Familien. **Nachtrag 2026-09-27:** Lizenztexte aus den offiziellen Projektquellen liegen jetzt bei (`assets/fonts/OFL-*.txt`), Registerstatus `lizenz-belegt`; Details in [`FONTS.md`](FONTS.md).
- [S] Wegen des Reserved Font Name darf eine veränderte Fassung (z. B. Subset mit neuen Glyphen oder umbenannt) nicht unter „IM FELL" weitergegeben werden. Unverändert einbetten ist unkritisch.
- Außerhalb des Repositorys: `app/index.html:16-21` lädt Cinzel Decorative, `game.html:13-15` Cinzel und Fondamento vom Google-Fonts-CDN. Für eine Offline-App müssen diese lokal und mit Lizenzdatei vorliegen, oder entfallen.
- Eine Lesetextschrift für Bedientext fehlt (`05-visual-audio-direction.md` §2.3).

### 4.4 Technische Qualität und Ordnung [B]

- **Bytegleiche Doppelungen (4 Paare):** `cards/de/Hintergrund.webp` = `cards/en/Background.webp`; `cards/de/Rachsüchtiger_Wolf.webp` = `cards/en/Vengeful_Wolf.webp` (EN-Karte zeigt vermutlich DE-Text); `icons/app/start.png` = `icons/game/start.png`; `icons/setup/De_Setup3.png` = `En_Setup3.png`.
- **Falsche Endung:** `icons/setup/De_Setup1_new.png` und `Setup2_new.png` sind JPEG-Dateien (1920×1080).
- **Format-Doppelungen in `app/public/assets/ui/`:** 7 Motive liegen als PNG und WebP vor; jeweils nur eine Fassung wird referenziert.
- **Unbenutzt (25 Dateien):** 16 UI-Bitmaps (u. a. `emblem-*`, `Lynch_DE/EN`, `action-template-*`, WebP-Doppel), 7 Setup-Grafiken, 2 Prophet-Sounds. Liste: Spalte `verwendet_in` = `unbenutzt` im Register.
- **Fehlende Dateien, die der Code erwartet:** `action-frame-day.png`, `action-frame-night.png`, `tooltip-frame.png` (`app/src/assets/roleAssets.ts:12-13,20`).
- **Uneinheitliche Maße:** Statussiegel zwischen 229×263 und 234×267; Porträts 1254² statt spezifizierter 512²; Audio mit fünf verschiedenen Bitraten und zwei Abtastraten.
- **Eingebackener Text:** Rollenkarten, Lynch-Grafiken, Protokoll-Reiter und Setup-Hintergründe enthalten Schrift im Bild. Das widerspricht `docs/architecture/tablet-asset-spec.md` („Keine Texte in Bildern") und verhindert saubere Lokalisierung.
- **Repository-Last:** 186 MB Medien in normaler Git-Historie, davon 59 MB Audio und 27 MB Setup-Grafiken. [E] Für die Neuproduktion Quelldateien außerhalb von Git archivieren; nur Laufzeitexporte versionieren.

### 4.5 Markenabgrenzung [B]

Keine Datei trägt Namen, Symbole oder Texte aus Blood on the Clocktower (Befund aus `01-current-system-inventory.md` §6.2, für die Dateinamen erneut geprüft). Das Restrisiko liegt im Look-and-feel neuer Produktionen; die Begriffe und Formen aus `05-visual-audio-direction.md` §2.4 gelten für alle Aufträge.

## 5. Einordnung je Gruppe für das Godot-Projekt [E]

| Gruppe | Empfehlung | Begründung |
|---|---|---|
| Schriften Cinzel, IM Fell English | **übernehmen möglich** nach Product-Owner-Freigabe; Lizenztexte liegen seit 2026-09-27 bei | Lizenz aus Datei belegt; Bezugsquelle unbekannt (`FONTS.md`) |
| Dorfplatz Tag/Nacht | **Referenz**, Übernahme erst nach Herkunftsklärung | Maße passen, Herkunft fehlt |
| Statussiegel | **Referenz**, Übernahme erst nach Herkunftsklärung | Stil passt, Maße uneinheitlich |
| Archetyp-Porträts | **Platzhalter im Entwicklungsbuild** möglich, nicht im Release | KI-Herkunft belegt; Prompt, Tarif und PO-Freigabe fehlen |
| Rollenkarten | **Referenz für Motiv und Stil** | Text eingebacken, Herkunft nicht belegbar |
| UI-Bitmaps | **nicht übernehmen empfohlen** | Godot baut Rahmen als Theme/NinePatch (`05` §2.4) |
| Legacy-Hintergründe, Spiel- und Setup-Icons | **aussortieren empfohlen** | eingebackener Text, alter Stil (`05` §7) |
| Audio | **ersetzen empfohlen** | Nachweis fehlt, Nutzung nicht freigegeben, technisch uneinheitlich |

Die Übernahme selbst ist ein eigenes Arbeitspaket. Jede Übernahme setzt voraus, dass die Registerzeile auf `freigegeben` steht; `tools/check-asset-register.js` meldet jede Datei unter `godot/`, die das nicht erfüllt.

## 6. Offene Fragen an den Product Owner

1. **Rollenkarten, UI, Siegel, Dorfplatz:** Mit welchem Dienst und Konto wurden sie erstellt, und gibt es dort noch Verläufe, Prompts oder Rechnungen? Ohne diese Angaben bleiben 208 Dateien ungeklärt.
2. **Archetyp-Porträts (C2PA 2026-06-14):** Welcher Tarif (ChatGPT Plus/Team oder API) wurde genutzt? Prompts vorhanden?
3. **Kurze Sounds:** Sind `Ritter.mp3` (FL Studio) und `Selbstmörder.mp3` („Neue Aufnahme 66") eigene Aufnahmen? Falls ja, können sie als eigenes Werk eingetragen werden; für 1.0 werden sie trotzdem durch einheitliche Cues ersetzt.
4. **Bezugsquelle der Schriften:** Google Fonts oder GitHub-Repository der Projekte? (Nötig für die Registerzeile, nicht für die Lizenz selbst.)
5. **Q8 aus `07-open-questions.md`:** Soll Option B (KI für Platzhalter, Schlüsselassets beauftragt oder selbst erstellt) verbindlich werden? Weiterhin offen (Korrektur im Decision Log, 2026-09-27); der Produktionsplan rechnet mit Option B als Empfehlung.
