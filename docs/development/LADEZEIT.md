# Ladezeit der Web-App

Stand 07.10.2026. Messung der Größen in `index.pck` (Godot-Web-Export) vor und nach der Verkleinerung. Die Datei `index.wasm` (39,5 MB) ist die Godot-Engine und lässt sich ohne eigenen Engine-Build nicht verkleinern; Vercel liefert `index.wasm`, `index.pck` und `index.js` bereits mit Brotli aus (`Content-Encoding: br`, geprüft mit `curl -I -H "Accept-Encoding: br"`).

## Ergebnis

| | Vorher | Nachher |
|---|---|---|
| `index.pck` | 45 333 176 Byte | 20 098 200 Byte |

## Die 20 größten Dateien im Paket vorher (Größe im Paket, Quelle)

| Byte im Paket | Datei |
|---|---|
| 2 879 164 | `assets/audio/musik-start.ogg` |
| 2 541 953 | `assets/audio/musik-nacht.ogg` |
| 2 174 118 | `assets/night/bg/scene-night-base.webp` (ungenutzt) |
| 2 020 778 | `assets/night/bg/village-night.webp` (verlustfrei importiert) |
| 1 487 840 | `assets/start/start-hintergrund.webp` (verlustfrei importiert) |
| 1 084 960 | `web/ladebild.webp` (nicht im Paket, eigene Datei) |
| 807 656 | `assets/brand/wortmarke.webp` |
| 711 386 | `assets/start/start-nebel.webp` |
| 631 382 | `assets/start/start-logo.webp` |
| 599 754 | `assets/village/village-day.webp` |
| 525 386 | `assets/village/village-night.webp` |
| 371 484 | `assets/village/crowd.webp` |
| 328 846 | `assets/ui/epic_button_mid.webp` |
| 320 484 | `assets/app/splash-grimmhain.png` |
| 320 364 | `assets/ui/epic_button_left.webp` |
| 308 896 | `assets/brand/siegel.webp` |
| 285 686 | `assets/ui/epic_button_right.webp` |
| 225 216 | `assets/ui/skin/bund_rivalen.webp` |
| 194 888 | `assets/app/app-symbol-512.png` |
| 189 216 | `assets/ui/skin/bund_liebende.webp` |

Nach Gruppen: Kartenbilder 12,2 MB (144 Dateien, beide Sprachen), `assets/night` 15,2 MB (Embleme, Rollenbilder, Kreise, Porträts, Hintergründe), Musik und Heulen 5,3 MB, Rest unter 3 MB je Ordner.

## Was geändert wurde

- Importeinstellung aller Bilder außer Karten von verlustfrei auf verlustbehaftet (Qualität 0,75 bis 0,85; Rollenbilder 0,55). Quelldateien bleiben unverändert, nur das Paket ist kleiner.
- Kartenbilder: Quelle unverändert, im Paket verlustbehaftet mit Qualität 0,4 (vorher 0,8). An drei Karten (Fenrir, Amalia, Rattenfänger) gegen die Quelle verglichen: PSNR 32 dB, SSIM 0,93 bis 0,94; in der 1:1-Ansicht nur minimal weichere Schriftkanten. Wer das zu sichtbar findet: Qualität in `godot/assets/cards/*/*.import` auf 0,5 erhöhen (Paket etwa 0,9 MB größer).
- Nicht verwendete Dateien vom Export ausgeschlossen: `scene-night-base.webp`, `scene-night-windows.png`, `assets/app/*` (Symbole für Installation, nicht zur Laufzeit gebraucht). Startbild der Engine (`boot_splash`) in `project.godot` abgeschaltet; die Web-Seite zeigt ihr eigenes Ladebild.
- Musik neu als Ogg Vorbis ohne eingebettetes Titelbild, Qualitätsstufe 0,5 (etwa 65 kbit/s, vorher 112 kbit/s). Heulen unverändert (80 bis 90 kbit/s, je 4 bis 5 s).
- Kartenbilder werden nicht beim Start geladen: `RoleCardImage` lädt jede Karte erst beim Anzeigen (`load` im Widget), kein Vorladen aller 72.

## Offen

- Der erste Start am PC hängt vor allem an `index.wasm` (Engine) und am Paket. Die Zeit wurde nicht im Browser gemessen, nur die Paketgröße.
- Musik wurde nicht abgehört; bei hörbarem Qualitätsverlust Stufe in `ffmpeg -c:a libvorbis -q:a` anheben (Originale in Git vor Commit 'perf: shrink web package').
