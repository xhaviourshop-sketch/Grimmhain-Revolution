# Entscheidungen

Nur wichtige Architektur-, Produkt-, Daten- oder Sicherheitsentscheidungen mit Begründung aufnehmen.

## 2026-10-01: Einstellbarer Anzeige-Timer für Tagphase und Diskussion

**Entscheidung (Markus, 01.10.2026):** Die Spielleitung kann für die Tagphase und die Diskussion einen Timer einstellen. Er ist rein anzeigend, hat keine Auswirkung auf Regeln, ist pausierbar und speicherstandtauglich. Umsetzung gehört zum Paket P3 der visuellen Roadmap, nicht zu Auftrag 1 (P0 + P1).

**Warum:** Die Spielleitung braucht am Tisch einen sichtbaren Zeitrahmen, ohne dass die App Regeln durchsetzt oder Spielzustand verändert.

**Folgen und Grenzen:**
- Ablauf oder Pause des Timers löst keinen Befehl und kein Regelereignis aus und verbraucht den gespeicherten Regelzufall nicht.
- Gespeichert wird die Restzeit samt Pausenzustand (keine Uhrzeit der Wanduhr), damit Laden und Fortsetzen ohne Zeitsprung möglich sind. Ob das in den bestehenden Spielstand (Schema 15) oder in einen eigenen Zustand außerhalb des Regelkerns gehört, wird bei P3 am Code entschieden; der Regelkern bleibt unabhängig von Szenen und UI.
- Nicht entschieden und nicht erfunden: Standarddauer und Signal bei Ablauf (Ton, Hinweis). Die Nachtphase ist entschieden (siehe Ergänzung).

**Konflikt mit älterem Eintrag:** `docs/masterplan/DECISION-LOG.md` („Totenreichkarten und Kartenschlucker: Umsetzung“, Tischregeln) sagt „Die App hat keinen Timer“. Das gilt weiter für die Durchsetzung von Tischregeln (Nebelhorn, Stummfilm, Totengericht): Diese bleiben Meldungen der Spielleitung. Der Anzeige-Timer ersetzt sie nicht. Vorschlag: den Satz im Decision Log um diesen Verweis ergänzen (dort noch nicht geändert).

## 2026-10-01: Platzporträt wählt die Spielleitung beim Einrichten

**Entscheidung (Markus, 01.10.2026):** Beim Einrichten wählt die Spielleitung pro Person ein Porträt aus einer Auswahl. Ist Alter oder Geschlecht angegeben, schlägt die App passende Porträts vor. Platzporträts sind öffentlich und dürfen nie die Rolle verraten.

**Warum:** Der Dorfplatz zeigt alle Personen öffentlich; das Bild soll die reale Person am Tisch wiedererkennbar machen und darf keine geheime Information tragen.

**Folgen und Grenzen:**
- Die Auswahl enthält nur neutrale Porträts. `Solo_*.png`, `Wolf_Male.png` und Rollenbilder sind nie Platzporträts.
- Das gewählte Porträt gehört zur Personen-ID (nicht zum Sitzplatz) und wird gespeichert. Rollenwechsel ändern es nicht.
- Angaben zu Alter und Geschlecht sind freiwillig und dienen nur dem Vorschlag, nicht den Regeln.
- Umfang der Auswahl, Speicherort im Zustand und Setup-Oberfläche werden in P3 oder im Setup-Paket am Code festgelegt, nicht hier erfunden.

**Ergänzung zur Timer-Entscheidung (Markus, 01.10.2026):** Der Timer läuft auch in der Nacht. Er lässt sich über die Optionen abschalten („Nacht-Timer anzeigen“). Rein anzeigend, ohne Regelwirkung, wie oben.

## 2026-10-01: Abnahme 1 des visuellen Nachtbretts, Entscheidungen

**Entscheidungen (Markus, 01.10.2026), Abnahme 1 erteilt:**
1. **Aktionskarte:** Variante A (Rollenbild mit Zielauswahl, „i“ für Details). Bestätigt wird über „Nächster Schritt“, die Karte hat keinen eigenen Bestätigen-Knopf.
2. **Platzporträts:** G2-Serie (ChatGPT, 01.10.2026) mit leichter Abdunklung in Godot. `Village_*.png` werden nicht als Platzporträts genutzt.
3. **Nachtreihenfolge-Leiste:** Auf 4:3 einklappbar (Chip mit aktiver Rolle und Pfeilen), ab 16:10 voll sichtbar.
4. **Timer:** auch in der Nacht, abschaltbar (siehe Ergänzung oben).
5. **Sichtbarkeit:** Das Tablet sieht nur die Spielleitung. Statusringe und Rollenleiste dürfen auf dem Brett offen erscheinen. „Verbergen“ blendet auf Knopfdruck alles Geheime aus und zeigt nur Öffentliches (Namen, Porträts, tot oder lebendig). Eine öffentliche Zweitansicht bleibt ein späteres Thema.
6. **Layoutvorlage:** `Spielfeld.png` und `Full UI.png` aus „Grimmhain Assets“ sind verbindlich, G1 ist der Nachthintergrund.

**Warum:** Das Mockup V2 (`docs/assets/p1-mockup/`, Screenshots im Übergabeordner `mockup-v2/`) zeigte, dass diese Variante auf 24 Plätzen lesbar bleibt und zur eigenen Vorlage passt.

**Folgen:** Die Regel „Verbergen zeigt nur Öffentliches“ muss P3 mit den bestehenden öffentlichen Sichten (`cockpit_view.gd`) umsetzen, nicht mit einer zweiten Regelquelle. Das Roadmap-Ziel „Geheimnisse nicht durch Highlight verraten“ gilt für den Verbergen-Zustand und für eine spätere öffentliche Zweitansicht, nicht für die offene Spielleitungsansicht.

## 2026-10-01: Stil der Rollensymbole für alle 72 Rollen

**Entscheidung (Markus, 01.10.2026):** Der Stil des Probeblatts `P2-04-role-emblems-probe-v1.png` gilt für alle 72 Rollensymbole: rundes Medaillon, dunkler Metallrand mit vier Rautenzieren, monochromes Silber auf dunklem Grund, ein Emblem statt einer Szene. Das Symbol 6 (Wolf mit Zipfelmütze, Wolfskind) wird nicht verwendet und neu erzeugt.

**Warum:** Der Stil passt zu den Medaillons in `Full UI.png` und bleibt bei 40 px lesbar. Er löst die Übergangslösung mit Kartenausschnitten ab.

**Folgen:** Die restlichen Symbole entstehen in Blättern zu je 12 (Schätzung in `docs/assets/P2-GRAFIKLISTE.md`). Die Motive leitet Markus aus den Rollen ab. Bis zur Lieferung zeigt die Leiste das Kreisbild aus `night-icons-circle/`. Die Bilder bleiben Kandidaten ohne Veröffentlichungsfreigabe.

## 2026-10-01: Selbst erstellte KI-Bilder als interne Laufzeitassets (Status `intern-freigegeben`)

**Entscheidung (Markus, 01.10.2026, Auftrag P3):** Markus bestätigt, alle Grafiken des Nachtbretts selbst per KI erstellt zu haben. Sie dürfen als Laufzeitassets in `godot/assets/night/` liegen, solange sie nur intern genutzt werden (Entwicklung, eigene Tests). Eine Veröffentlichung bleibt gesperrt.

**Prüfung der Regeln:** Bisher durfte unter `godot/` nur Material mit Status `freigegeben` liegen (Prüfwerkzeug, `ASSET-REGISTER.md`), und der Decision Log nannte OpenAI-Porträts und Legacy-UI-Grafiken ausdrücklich „nicht nach Godot kopiert, Nutzung nicht freigegeben“. Beides beschreibt den Zustand ohne Herkunftsbestätigung, kein Verbot gegen eine Entscheidung des Product Owners. `freigegeben` wäre falsch, weil Dienst, Modell, Tarif, Prompt und Nutzungsbedingungen nicht belegt sind.

**Folgen:**
- Neuer Registerstatus `intern-freigegeben`: bestätigte Eigenerstellung, interne Nutzung, Veröffentlichung gesperrt. Er verlangt einen Eintrag in `po_freigabe`. Das Prüfwerkzeug erlaubt ihn unter `godot/`, mit `--release` ist jede solche Datei ein Befund. Die Releasecheckliste führt diese Prüfung.
- Die 202 Dateien unter `godot/assets/night/` tragen diesen Status. Alle anderen Bilder (Mockups, Kandidaten in `docs/`) bleiben `ungeklärt`.
- Ersetzt für diese Dateien die Aussage „werden nicht nach Godot kopiert“ im Decision Log. Nicht entschieden: wann daraus `freigegeben` wird (Nutzungsbedingungen des Dienstes zum Erstellungsdatum, Prompts, Rechteprüfung für den Store).

