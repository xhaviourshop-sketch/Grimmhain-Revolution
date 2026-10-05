---
name: grimmhain-asset
description: Use when adding or changing a Grimmhain image asset - check, crop, convert to WebP, register, brand check.
---

# Bild-Asset aufnehmen
Marke: `docs/brand/MARKE.md` (kein Gold, kein Text im Bild, echte Transparenz, Ornamente nur an den Enden). Register: `docs/masterplan/ASSET-REGISTER.md`. Details zur Produktion: Skill `grimmhain-assets`.

1. Bild ansehen (Read): Format, Größe, Alpha (echte Transparenz außen), keine Halo-Kanten, kein Gold, kein Text.
2. Zuschneiden und konvertieren mit den vorhandenen Skripten `tools/build_*.py` (Muster: `tools/build_grove_ui.py`); WebP nur, wo das Register es für diese Klasse vorsieht, UI-Rahmen mit Alpha bleiben PNG. Originale unverändert nach Downloads.
3. Ablage unter `godot/assets/<bereich>/`, danach `godot --headless --path godot --import`.
4. Registerzeile mit Quelle, Status, Lizenz/Herkunft ergänzen. `node tools/check-asset-register.js` muss grün sein.
5. Marken-Check: Pixel prüfen (kein Goldton), im Code nur Theme-Tokens (`node tools/check-brand.js <datei.gd>`).
6. Einbindung per Screenshot belegen (Skill `grimmhain-screens`); keine Tests für Aussehen.
