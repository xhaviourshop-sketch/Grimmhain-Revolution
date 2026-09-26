# 05 · Visual- und Audio-Direction

**Stand:** 2026-09-26 · Kennzeichnung: **[B]** Beobachtung, **[S]** Schlussfolgerung, **[E]** Empfehlung.

---

## 1. Leitbild

**„Dunkles Märchen, helle Bedienung."** Die Welt von Grimmhain ist ein verfluchtes Walddorf zwischen Kerzenlicht und Mondnebel. Die Bedienoberfläche liegt wie ein gut ausgeleuchtetes Pergament davor: ruhig, kontrastreich, eindeutig.

Drei Regeln, an denen jedes Asset und jeder Effekt gemessen wird [E]:

1. **Bedeutung vor Dekoration.** Ein Effekt existiert nur, wenn er ein Spielereignis kommuniziert (siehe Cue-Tabelle, Abschnitt 4). Dauerhaftes Ambiente ist leise und langsam.
2. **Nie im Weg.** Kein Effekt verzögert eine Eingabe, verdeckt Namen, Ziele oder die Ansagekarte. Eingaben sind während jeder Animation möglich; eine neue Eingabe beendet laufende Übergänge sofort.
3. **Geheimhaltung hat Vorrang.** Das Tablet steht oft sichtbar auf dem Tisch. Effekte dürfen **nicht verraten, wer betroffen ist**, solange der SL das nicht verkündet (z. B. kein Todesblitz auf einem Token, während Spieler zusehen könnten). Deshalb: auffällige Effekte im **Zentrum/Hintergrund**, betroffene Token nur dezent. Sprechende Cues optional stumm schaltbar.

---

## 2. Gestalterische Grundlagen

### 2.1 Farbe

Basis aus dem bestehenden Token-Set (`css/tokens.css`) [B], erweitert um Rollen für Godot [E]:

| Token | Wert | Verwendung |
|---|---|---|
| `bg.night` | `#05070F` | Grundfläche Nacht |
| `bg.day` | `#1B1610` (neu) | Grundfläche Tag (warmes Dunkelbraun statt Blau) |
| `panel` | `#080C1E` @ 92 % | Ansagekarte, Schubladen |
| `ink.primary` | `#E8ECFF` | Text auf dunkel (Kontrast zu `panel` > 12:1) |
| `ink.muted` | `#A9B0D6` | Sekundärtext (> 7:1) |
| `gold` | `#C9A84C` | Akzent, Rahmen, Primäraktion (Hausfarbe) |
| `faction.wolf` | `#C1121F` | Wolf; immer mit Wolfssymbol |
| `faction.village` | `#2A9D8F` | Dorf; mit Haussymbol |
| `faction.solo` | `#7B2D8B` | Solo; mit Sternsymbol |
| `state.good` / `warn` / `bad` | `#43E59B` / `#FFC857` / `#FF5D7A` | Rückmeldungen |
| `moon` | `#9DB4FF` (neu) | Nachtlicht, Schutz |
| `ember` | `#FF8A3D` (neu) | Kerzen, Morgengrauen, Feuer |

Faction-Farben reichen allein nicht für Farbschwache; Symbol und Muster sind Pflicht (siehe `02`, 5.4).

### 2.2 Licht und Stimmung

- **Nacht:** kalt, Mondlicht von oben links, tiefe Vignette, Nebel am unteren Rand, einzelne warme Kerzenpunkte auf Tokens (lebende Spieler).
- **Morgengrauen:** Übergang Blau → Violett → Bernstein über 2–3 s; Vögel/Wind leise.
- **Tag:** warmes, gedämpftes Licht, Pergament- und Holztöne, weniger Nebel, keine grellen Flächen (Dunkelraum-Tauglichkeit).
- **Tod:** Kerze des Tokens erlischt, Porträt entsättigt; kein Blut auf dem Brett.

### 2.3 Schrift [E]

| Rolle | Schrift | Hinweis |
|---|---|---|
| Titel, Rollennamen, Phasen | Cinzel (vorhanden, OFL) | nur Großbuchstaben-Wirkung, ≥ 20 sp |
| Vorlesetext | IM Fell English (vorhanden, OFL) **nur** für Zitate ≥ 24 sp | stimmungsvoll, aber bei Kleinschrift unruhig |
| Bedientext, Namen, Zahlen | eine gut lesbare OFL-Schrift, z. B. **Alegreya Sans** oder **Source Sans 3** | Hinting für kleine Größen, Ziffern tabellarisch |

OFL-Lizenztexte werden mit ausgeliefert (heute fehlend, siehe `01`, 6.2).

### 2.4 Formensprache

- Rahmen: dünne Goldlinie mit geschnitzten Eckornamenten; als **NinePatch** (Ecken fest, Kanten kachelbar), nicht als Vollbild (heute 1774×336-Leisten und 835×1488-Panels als Bitmaps, `app/public/assets/ui`).
- Token: runde Medaillons mit Kerzenfuß; Statussiegel als Wachssiegel am Rand (vorhandene `marker-*.webp` passen stilistisch).
- Ikonografie: eigene Symbole (Wolfskopf, Haus, Stern, Schild, Sanduhr, Siegel). **Keine** Übernahme oder Nachahmung von Blood-on-the-Clocktower-Elementen (Grimoire-Optik, Reminder-Token-Form, Nachtreihenfolge-Blatt, Begriffe wie Storyteller/Grimoire/Townsfolk/Minion/Demon/Fabled). Eigenständige Begriffe: **Spielleiter**, **Sitzkreis**, **Nachtleiste**, **Siegel**, **Ansagekarte**, **Akte**, **Totenkarten**.

---

## 3. Ambiente vs. Ereigniseffekte

| | Dauerhaftes Ambiente | Ereigniseffekt |
|---|---|---|
| Zweck | Stimmung, Phasenorientierung | Rückmeldung auf ein konkretes Ereignis |
| Auslöser | Phase (`phase_changed`) | Kern-Ereignis (`SeatDied`, `EffectAdded` …) |
| Dauer | endlos, Schleife | 0,3–2,5 s, einmalig |
| Intensität | niedrig, langsam (Perioden ≥ 6 s) | kurz, klar, dann vollständig verschwunden |
| Beispiele | Nebeldrift, Kerzenflackern, Mondlichtschwankung, Waldgeräusch, Nachtmusik | Schutzsiegel, Todes-Kerze, Morgengrauen-Wisch, Abstimmungsglocke |
| Abschaltbar | Schalter „Ambiente" | Schalter „Effekte" + „Bewegung reduzieren" |
| Beim Undo/Replay | läuft weiter | **wird nicht** erneut abgespielt |

Technisch: Ambiente hängt an der Phase im `CockpitView`; Ereigniseffekte ausschließlich an `Session.events_applied` über `FxDirector`/`AudioDirector` (siehe `03`, Abschnitt 3).

---

## 4. Cue-Tabelle (Animation + Audio)

Dauer = sichtbarer Kern; Eingaben sind immer sofort möglich. „Diskret" = Effekt am Token ist so subtil, dass Zuschauer ihn nicht aus der Ferne erkennen.

| Ereignis | Visuell [E] | Audio [E] | Dauer | Geheimhaltung |
|---|---|---|---|---|
| **Nachtbeginn** (`PhaseChanged→NIGHT`) | Himmel dunkelt von oben, Mond steigt am Rand, Nebel füllt unteren Rand, Kerzen der Tokens glimmen auf | Tiefer Glockenschlag, dann Nachtambiente (Wind, entfernte Eule) + Musik blendet ein | 2,0 s | öffentlich |
| **Rollenzug** (`StepStarted`) | Nachtleiste: Eintrag gleitet zur Mitte, goldener Rand; Ansagekarte blättert um (Pergament-Flip 250 ms); erlaubte Tokens heben sich leicht an | leises Seitenrascheln; optional sehr leiser Rollen-Leitton (1 s, kein Name) | 0,4 s | Rolle nur auf der Karte, nicht groß im Zentrum |
| **Ziel gewählt** | Token erhält pulsierenden Goldring (diskret) | kurzer Holzklick | 0,15 s | diskret |
| **Schutz** (`EffectAdded protected`) | Blaues Siegel prägt sich in den Token-Rand, kurzer Mondlicht-Schimmer **auf der Karte** | gläserner Glockenton, sehr leise | 0,6 s | diskret am Token |
| **Angriff / Wolfsziel** | Kratzspuren blitzen kurz auf der Ansagekarte auf (nicht am Token), Karte zittert 2 px | gedämpftes Knurren | 0,5 s | nie am Token |
| **Schutz greift** (`KillPrevented`) | Im Morgenbericht: Siegel zerspringt in Funken auf der privaten Spalte | Glasklirren weich | 0,8 s | nur privat |
| **Tod** (`SeatDied`) | Morgens beim Verkünden: Kerze des Tokens verlischt (Rauchfaden 1,5 s), Porträt entsättigt über 1 s, Name wird silbern; Zentrum: kurzer Schatten-Wisch | tiefer Gong + Ausatmen des Winds | 1,5 s | **erst beim Morgenbericht** abgespielt, nicht bei der Auflösung |
| **Folgetod / Reaktion** | Rote Fadenlinie zwischen verbundenen Tokens (Liebende, Rotkäppchen) zieht sich und reißt | gezupfte, reißende Saite | 1,0 s | beim Verkünden |
| **Morgengrauen** (`PhaseChanged→DAWN`) | Farbwisch Blau → Bernstein über den Himmel, Nebel zieht ab, Hähne/Vögel fern | Hahn fern, Vogelchor leise, Musik blendet aus | 2,5 s | öffentlich |
| **Diskussion** (Tag, Timer läuft) | Sanduhr in der Kopfzeile rieselt; letzte 10 s: Ring um Timer pulsiert warm | tickende Uhr nur letzte 10 s, Glocke bei 0 | fortlaufend | öffentlich |
| **Nominierung** | Wachssiegel „⚖" fällt auf Token, Token rückt 4 dp nach innen | Holzhammer, dumpf | 0,5 s | öffentlich |
| **Abstimmung / Entscheidung** | Zentrum: Waage neigt sich zur Entscheidung (bei Stimmzählung, Q2) oder Galgen-Silhouette blendet kurz ein (Direktwahl) | Trommelwirbel 1 s, dann Schlag | 1,5 s | öffentlich |
| **Hinrichtung vollzogen** | Wie Tod, zusätzlich Seil-Silhouette im Hintergrund | Menge murmelt, verstummt | 1,5 s | öffentlich |
| **Sonderrettung bei Hinrichtung** (Fenrir, Cerberus, Spiegelwolf) | Kette zerspringt im Zentrum | metallisches Reißen | 1,0 s | öffentlich |
| **Rollenwechsel / Wiederbelebung** | Porträt dreht sich wie eine Münze, neue Kerze entzündet sich | aufsteigender Chor-Hauch | 1,2 s | privat, außer SL verkündet |
| **Totenkarte** | Karte schwebt aus dem Grabfeld, dreht sich, Kategorie-Farbe glimmt | Kartenrascheln + Kategorie-Motiv (5 Varianten) | 1,0 s | wie Karteninhalt |
| **Spielende** | Vollbild-Tableau der Siegerfraktion (Wolfsmond, Dorfsonne, Solo-Stern), Konfetti aus Asche/Blättern, Chronik blendet ein | Fraktions-Fanfare (3 Varianten + Solo) | 4,0 s, überspringbar | öffentlich |
| **Undo** | Kurzes Zurückspulen-Flirren über der Ansagekarte | Band-Rückspul-Wisch, leise | 0,3 s | – |
| **Fehler/gesperrt** | Karte schüttelt 3 px, Grund erscheint als Zeile | tiefer Holzklopfer | 0,2 s | – |

**Audio-Busse [E]:** `Master` → `Music`, `Ambience`, `Cues`, `UI`. Ducking: `Cues` senkt `Music` um 6 dB für 1 s. Alle Busse einzeln regelbar; „Stumm im Spiel" als Schnellschalter in der Kopfzeile.

**Vorleseunterstützung (P2):** optionale gesprochene Ansagen per aufgenommener Stimme; nie Text-to-Speech als Pflicht.

---

## 5. Umsetzung in Godot

| Baustein [E] | Technik |
|---|---|
| Übergänge Phase | `Tween` auf `CanvasModulate`/Shader-Uniforms (Himmelsgradient), keine Vollbild-Videos |
| Nebel | 2–3 Parallax-Ebenen mit Noise-Textur, Shader-Scroll; keine Partikel |
| Kerzen | `GPUParticles2D` nur für Rauch beim Tod; Flackern per Shader (Sinus + Noise) auf einer Lichtmaske |
| Siegel/Marker | `AnimationPlayer` auf Sprite-Skalierung + Alpha |
| Morgengrauen | Gradient-Shader über Himmelsebene |
| Fadenlinien | `Line2D` mit animiertem `width`-Kurvenverlauf |
| Spielende | `CPUParticles2D` (portabler im Compatibility-Renderer), max. 200 Partikel |
| Bewegung reduzieren | `FxDirector` ersetzt jeden Cue durch 150-ms-Überblendung |

---

## 6. Performance-Budgets und Fallbacks

**Referenzgerät Untergrenze [E]:** Android-Tablet Mittelklasse 2021/22 (z. B. 4 GB RAM, Mali-G52/Adreno-610-Klasse, 1920×1200), Android 11+.

| Budget | Ziel | Messung |
|---|---|---|
| Bildrate | 60 fps im Cockpit, nie < 30 fps während Cues | Godot-Monitor, 10-min-Nachtlauf |
| Leerlauf | Wenn nichts animiert: **Low-Processor-Mode** (`OS.low_processor_usage_mode`), Ambiente auf 30 fps begrenzt | Akku: ≤ 12 % pro Stunde bei 50 % Helligkeit |
| Eingabe-Latenz | < 100 ms bis sichtbare Rückmeldung | Profiler |
| Draw Calls | < 150 im Cockpit bei 24 Spielern | Monitor |
| Partikel gleichzeitig | ≤ 300 | – |
| Texturspeicher | ≤ 256 MB | Monitor |
| APK/AAB-Größe | ≤ 150 MB (Musik als OGG, Porträts 512² WebP) | Build |
| Kaltstart bis Fortsetzen-Karte | ≤ 3 s | Stoppuhr |

**Fallback-Stufen (automatisch nach gemessener Bildrate, manuell übersteuerbar) [E]**

1. **Voll:** alle Cues, Nebel 3 Ebenen, Partikel.
2. **Reduziert:** Nebel 1 Ebene, keine Partikel (Rauch als Sprite-Animation), Ambiente 30 fps.
3. **Minimal:** statische Hintergründe, nur Farb-/Alpha-Übergänge ≤ 150 ms, keine Shader außer Gradient.

---

## 7. Asset-Produktionsliste

Priorität: **P0** = Platzhalter-MVP spielbar, **P1** = Version 1.0, **P2** = danach. Alle Namen ASCII-kebab-case. Herkunft jedes Assets wird im Assetregister `../masterplan/asset-register.csv` protokolliert (Werkzeug, Datum, Autor, Lizenz, Quelle); Ablauf und Wellen in `../assets/PRODUCTION-PLAN.md`.

| # | Asset | Anzahl | Spezifikation | Prio | Quelle |
|---|---|---|---|---|---|
| 1 | Hintergrund Dorfplatz Nacht/Tag | 2 (+1 Dämmerung) | 2560×1600 WebP q85, sicherer Bereich zentrale Ellipse 70×80 %, ohne Text | P0 | vorhanden (`app/public/assets/bg`), Dämmerung neu |
| 2 | Himmel-Ebene + Nebel-Ebenen | 1 + 3 | 2560×800 bzw. 2048×512 PNG mit Alpha, kachelbar horizontal | P1 | neu |
| 3 | Rollenporträts | 72 | 512×512 WebP q85, Motiv im Kreis ⌀ 460, Augenlinie 40 % | P1 (P0: 10 Archetypen) | 10 vorhanden (re-export), 62 neu |
| 4 | Rollenkarten DE/EN | 72 + Rückseite | vorhandene 839×1400 WebP; für 1.0 textfreie Master + Text im Code | P0 übernehmen, P1 textfrei | vorhanden (`assets/cards`) |
| 5 | Statussiegel | 15 → ~20 | 256×256 PNG-32, einheitliche Leinwand; neu: blockiert, verflucht, Schild einmal, Waffe, Ladung | P0 (15), P1 (neu) | vorhanden (`marker-*.webp`) |
| 6 | Token-Ringe | 6 | 512×512 PNG-32 (dorf, wolf, solo, tot, ziel, gewählt) | P1 | neu (P0: Code-gezeichnet) |
| 7 | UI-Rahmen NinePatch | ~8 | Ecke 64×64, Kante kachelbar, PNG-32 | P1 | aus vorhandenen UI-Bitmaps ableiten |
| 8 | Fraktions-/Phasensymbole | ~24 | SVG-Master, Import als 128² | P0 (einfach), P1 (final) | neu |
| 9 | Totenkarten-Illustrationen | 6 Kategoriemotive (P1), 80 Einzelmotive (P2) | 839×1400 wie Rollenkarten, ohne Text | P1/P2 | neu |
| 10 | Spielende-Tableaus | 4 (Wolf, Dorf, Solo, Unentschieden) | 2560×1600 WebP | P1 | neu |
| 11 | App-Icon, Splash | 1 + Adaptive Icon | 1024² Master, Android-Adaptive 432² Vorder-/Hintergrund | P0 | aus Logo neu |
| 12 | Musik Nacht | 1 Schleife 3–5 min | OGG Vorbis q5, nahtlose Schleife, −16 LUFS | P0 | vorhandene nur nach Lizenzklärung (Q8), sonst neu |
| 13 | Ambiente Nacht/Tag | 2 Schleifen 60–90 s | OGG, −24 LUFS | P1 | neu |
| 14 | Cues (Tabelle Abschnitt 4) | ~25 | OGG/WAV 48 kHz, −18 LUFS Spitze −1 dBTP, ≤ 2,5 s | P1 (P0: 5 Kern-Cues: Nacht, Tag, Tod, Bestätigen, Fehler) | neu |
| 15 | Fanfaren Spielende | 4 | OGG, 4–6 s | P1 | neu |
| 16 | Schriften | 3 Familien | TTF/OTF + OFL.txt | P0 | 2 vorhanden, Lesetextschrift neu |

**Aussortieren [E]:** `assets/Tag.png`, `assets/Nacht.png`, `assets/icons/game/*`, `assets/icons/setup/*`, alte SFX-MP3s, unbenutzte UI-Bitmaps (siehe `01`, 6.1).

**KI-Einsatz [E]:** Wenn weiter KI-Bilder genutzt werden, pro Asset Prompt, Werkzeug und Nachbearbeitung protokollieren; C2PA-Metadaten in Mastern behalten; für Steam offenlegen. Entscheidung in Q8.
