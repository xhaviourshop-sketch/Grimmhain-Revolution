---
name: grimmhain-tablet-ui
description: Use for Grimmhain Godot tablet screens, touch interaction, typography, layout, animation and visual review. Not web UI or standalone rules.
---

# Atmosphäre und Bedienbarkeit
- Konkrete Ansicht, Aufgabe des Spielleiters und sichtbares Abnahmekriterium bestimmen. Bestehende Art Direction nicht jedes Mal neu erfinden.
- Relevante Szene, Anwendungsschicht/ViewModel, `godot/app/theme/` und passenden Abschnitt aus `docs/ui/` lesen. Asset-Spezifikation nur bei betroffenen Medien laden.
- Native Controls/Container und vorhandene Widgets, Tokens, DE/EN-Texte verwenden. Keine CSS-/Browser-Lösung oder globale Theme-Überarbeitung für einen lokalen Fehler.
- Klare Komposition, konsistente Typografie, zurückhaltende Bewegung. Status und nächste Aktion müssen vor Ornament lesbar sein. Gute Assets ersetzen keine Informationshierarchie.
- Große getrennte Touch-Ziele, sichtbare Auswahl/Fokus, Bestätigung folgenreicher Aktionen. Hover darf keine Voraussetzung sein.
- 4:3 und breites Tabletformat, lange Namen und DE/EN-Text prüfen. Spielfeld bei 6/12/24 Personen auf Bedienbarkeit prüfen, nicht nur auf geometrisches Hineinpassen.
- Animationen zeigen freigegebene Ereignisse, verändern keine Regeln und verlieren beim Überspringen keine Zustände. Vorhandene reduzierte Bewegung respektieren.
- Öffentliche Ansichten nur aus freigegebenen Daten erzeugen. Geheimdaten nicht bloß mit einem Overlay überdecken.
- Import und betroffene Interaktions-/Geometrietests durchführen. Bei grafischem Zugriff Zielansicht in 1024×768 und 1280×800 samt Langtext, Dialogen und relevanten Zuständen ansehen; Screenshot nicht nur erzeugen.
- Ohne grafischen Lauf ausdrücklich „visuell nicht geprüft“ melden. Headless-Erfolg beweist keine Pixel-/Schriftqualität oder Touch-Bedienung. Leistung auf Zielgerät messen, keine FPS erfinden.
- Konkrete Befunde korrigieren; keine endlose kosmetische Schleife. Produktabnahme bleibt beim Nutzer.

Abschluss: erreichbare Szene/Startweg, geprüfte Größen/Zustände, echte Screenshotpfade, offene Geräteprüfung.
