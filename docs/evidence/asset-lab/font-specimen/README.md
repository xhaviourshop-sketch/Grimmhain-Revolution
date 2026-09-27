# Prüf-Screenshots · Schriftmuster

Prüfartefakte, keine Produktionsassets. Erzeugt am 27.09.2026 in der Cloud-Umgebung mit Godot 4.7.2-stable unter Xvfb (Mesa llvmpipe, Compatibility-Renderer) durch `godot/asset_lab/font_specimen/check_font_specimen.gd -- --shots`. Logische Größe = Bildgröße, ohne Skalierung. Die gezeigten Schriften Cinzel und IM FELL English haben im Register den Status `lizenz-belegt` (Lizenztext liegt bei, nicht freigegeben); die Bilder sind eine interne Vorschau, keine Stilentscheidung.

| Datei | Inhalt | Größe |
|---|---|---|
| `01-titles-card-1024x768.png` | „Grimmhain", „Die Nacht beginnt", Beispielkarte mit Name, fiktiver Information und Aktionsbutton; Cinzel links, IM FELL English rechts | 1024×768 |
| `01-titles-card-1280x800.png` | wie oben | 1280×800 |
| `02-explanation-1024x768.png` | Erklärung DE und EN bei 20 px in Standardschrift, IM FELL English, Cinzel | 1024×768 |
| `02-explanation-1280x800.png` | wie oben | 1280×800 |
| `03-sizes-names-1024x768.png` | „Mäßig trübe Nächte" in 16, 20, 24, 30 px; fünf lange Namen mit Umlauten, ß, ç, ë | 1024×768 |
| `03-sizes-names-1280x800.png` | wie oben | 1280×800 |

Automatische Prüfung beim Erzeugen: 6 Ansichten, 0 Befunde (kein abgeschnittener Text, keine Seite braucht Scrollen).

Beim Ansehen aufgefallen, ohne Bewertung als Stilentscheidung:
- **Cinzel zeigt ß als „SS"**: „Großkreutz" erscheint als GROSSKREUTZ, „Straßenmeister" als STRASSENMEISTER. Cinzel hat nur Versalien und Kapitälchen; eingegebene Namen sehen damit anders aus als getippt.
- Cinzel-Fließtext in Kapitälchen braucht deutlich mehr Zeilen (Erklärung DE: 5 Zeilen gegenüber 4 bei IM FELL English in derselben Spaltenbreite) und liest sich langsamer.
- IM FELL English wirkt bei 16 px klein und unruhig; ab 20 px gut lesbar.
- Die Standardschrift (Open Sans SemiBold, in Godot eingebaut) ist bei allen Größen am klarsten, wirkt aber neutral.

Die Bilder ersetzen keine Prüfung auf einem echten Tablet im gedimmten Raum.

Neu erzeugen: siehe `godot/asset_lab/README.md`.
