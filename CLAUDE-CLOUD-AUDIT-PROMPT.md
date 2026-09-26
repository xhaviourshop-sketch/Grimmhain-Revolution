# Grimmhain Revolution: Bestandsanalyse und Godot-Migrationsplan

Du arbeitest im Repository `Grimmhain-Revolution`. Der vorhandene HTML/JavaScript-Stand ist die funktionale Referenz des bereits entwickelten Spiels. Ziel ist eine hochwertige, atmosphärische Spielleiter-App, die zuerst auf Tablets läuft und später als PC-/Steam-Version mit Online-Funktionen ausgebaut werden kann.

## Auftrag

Analysiere den gesamten aktuellen Stand gründlich. Erstelle anschließend eine umsetzbare technische und gestalterische Spezifikation für den Rework in Godot 4.x mit GDScript.

Beginne in diesem Auftrag **noch nicht mit der Godot-Implementierung**. Verändere keine bestehende Spiellogik und lösche keine Dateien. Deine Ergebnisse sollen die belastbare Grundlage für die anschließende Migration sein.

## Verbindliche Quellen

1. Lies zuerst `CLAUDE.md` und alle projektrelevanten Dokumentationen.
2. Nutze `GRIMMHAIN-ANALYSE-UND-ROADMAP-2026-09-15.md` als vorhandene Produktanalyse, prüfe deren Aussagen aber gegen den tatsächlichen Code.
3. Untersuche insbesondere Regeln, Rollen, Phasenablauf, Nachtaktionen, Abstimmungen, Zustände, Persistenz, Audio, Internationalisierung, Tests und bestehende Assets.

## Zielbild

- Tablet ist das primäre Gerät des Spielleiters: Touch-first, große sichere Ziele, Querformat, offline spielbar, schnelle Bedienung in einer laufenden Runde.
- Der Spielleiter bekommt zu jedem Zeitpunkt eine eindeutige nächste Aktion, hochwertige Textboxen und Hilfen für Ansagen.
- Nacht, Tag, Tod, Schutz, Abstimmung und Rollenfähigkeiten werden durch gezielte Animationen, Licht, Partikel, Audio und klare Zustandswechsel lebendig.
- Effekte dürfen die Bedienbarkeit, Lesbarkeit oder Geschwindigkeit nicht beeinträchtigen.
- Die Architektur soll später PC, Steam und Online-Synchronisation ermöglichen, ohne die Spielregeln erneut schreiben zu müssen.
- Das Spiel muss deterministisch, speicherbar, wiederaufnehmbar und gut testbar sein.

## Erzeuge diese Dokumente

Lege den Ordner `docs/godot-migration/` an und erstelle:

1. `01-current-system-inventory.md`
   - Verzeichnis- und Modulübersicht
   - tatsächlich implementierte Funktionen
   - Datenmodelle und Zustandsflüsse
   - Regeln und Sonderfälle mit Fundstellen
   - Assets mit Qualität, Format, Lizenz-/Herkunftsrisiken und Wiederverwendbarkeit
   - technische Schulden, Fehlerquellen und tote/duplizierte Teile

2. `02-product-and-ux-spec.md`
   - Zielgruppen und Kernaufgaben des Spielleiters
   - vollständiger Ablauf von Setup bis Spielende
   - Screen-Landkarte und Navigationsmodell
   - Tablet-Bedienregeln, Touch-Zielgrößen, Lesbarkeit und Barrierefreiheit
   - konkrete Quality-of-Life-Funktionen, priorisiert nach Nutzen
   - Ansagekarten und Informationshierarchie: Was ist passiert? Was muss gesagt werden? Was ist als Nächstes zu tun?

3. `03-godot-architecture.md`
   - empfohlene Godot-4-Projektstruktur
   - Trennung von regelreinem Core, Präsentation, Persistenz, Audio/VFX und späterem Netzwerk
   - Szenen, Autoloads, Resources, Signals und Zustandsmaschinen
   - konkretes Datenmodell für Spieler, Rollen, Effekte, Phasen, Aktionen und Ereignisprotokoll
   - Savegame-Versionierung, Undo/Redo und Crash-Recovery
   - Strategie für Android-Tablet, Desktop und spätere Steam-Integration
   - begründete Entscheidungen sowie vermiedene Überkomplexität

4. `04-rules-migration-matrix.md`
   - tabellarische Zuordnung jeder vorhandenen Regel/Funktion zur aktuellen Implementierung und zum künftigen Godot-Modul
   - Status: verifiziert, unklar, widersprüchlich oder fehlend
   - Akzeptanzkriterium und vorgeschlagener Test pro Eintrag
   - offene Fragen nur dort, wo der Code keine belastbare Antwort liefert

5. `05-visual-audio-direction.md`
   - umsetzbare Art Direction im düsteren Werwolf-/Gothic-Stil
   - klare Trennung zwischen dauerhaftem Ambiente und kurzen bedeutungsvollen Ereigniseffekten
   - Animations- und Audio-Cues für Nachtbeginn, Rollenzug, Schutz, Angriff, Tod, Morgengrauen, Diskussion, Nominierung, Abstimmung und Spielende
   - Performance-Budgets und Fallbacks für typische Tablets
   - Asset-Produktionsliste mit Priorität und technischen Spezifikationen
   - keine Abhängigkeit von markenrechtlich geschütztem Blood-on-the-Clocktower-Material

6. `06-execution-roadmap.md`
   - inkrementelle vertikale Slices statt Big-Bang-Neubau
   - Phasen, Abhängigkeiten, konkrete Deliverables, Akzeptanzkriterien und Tests
   - zuerst ein spielbarer Kernablauf mit Platzhaltergrafik, danach Präsentationsqualität
   - klare Definition eines Tablet-MVP, einer hochwertigen Version 1.0 und einer späteren Steam-/Online-Ausbaustufe
   - Risiken, Gegenmaßnahmen und sinnvolle Stop/Go-Prüfpunkte
   - der nächste einzelne Arbeitsschritt, der nach dieser Analyse ausgeführt werden soll

7. `07-open-questions.md`
   - nur Entscheidungen, die wirklich vom Product Owner benötigt werden
   - je Frage: Kontext, 2 bis 3 Optionen, konkrete Auswirkung und deine Empfehlung

## Qualitätsmaßstab

- Belege Aussagen mit relativen Dateipfaden und, wo sinnvoll, Symbol- oder Funktionsnamen.
- Erfinde keine vorhandenen Funktionen oder Regeln.
- Kennzeichne Beobachtung, Schlussfolgerung und Empfehlung eindeutig.
- Bleibe konkret genug, dass ein anderer Entwickler die Migration ohne erneute Grundlagenanalyse beginnen kann.
- Plane Effekte als Feedback für Spielereignisse, nicht als bloße Dekoration.
- Bewahre die vorhandene funktionale Spieltiefe. Die Migration ist erfolgreich, wenn dieselben Regeln reproduzierbar laufen und die Bedienung deutlich sicherer und atmosphärischer wird.

## Abschluss

Führe geeignete vorhandene Read-only-Checks aus. Nenne die untersuchten Bereiche, die erstellten Dateien, wesentliche Risiken und den empfohlenen nächsten Arbeitsschritt. Implementiere in diesem Auftrag keinen Godot-Code.
