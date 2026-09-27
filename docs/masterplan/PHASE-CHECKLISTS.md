# Operative Phasenchecklisten

## Vor Beginn jedes Claude-Auftrags

- [ ] Richtigen Phasenbranch prüfen.
- [ ] `GRIMMHAIN-REVOLUTION-MASTERPLAN.md` und relevante Spezifikation nennen.
- [ ] Einen einzelnen überprüfbaren Zweck formulieren.
- [ ] Erlaubte und verbotene Dateien angeben.
- [ ] Akzeptanzkriterien und konkrete Testbefehle angeben.
- [ ] Offene Regelentscheidungen auflisten; keine stillen Annahmen erlauben.
- [ ] Aktuellen sauberen Git-Status prüfen.

## Nach jedem Claude-Auftrag

- [ ] Diff auf unerwartete Dateien prüfen.
- [ ] Behauptete Tests selbst erneut ausführen.
- [ ] Negative und Abbruchfälle prüfen.
- [ ] Produktentscheidung und sichtbare Texte kontrollieren.
- [ ] Assetherkunft kontrollieren.
- [ ] Auf echtem Gerät prüfen, falls UI, Netzwerk oder Export betroffen ist.
- [ ] Dokumentation und Decision Log prüfen.
- [ ] Erst danach zusammenführen.

## Stop/Go-Gates

### Gate A · Core

Stand 27.09.2026 (main `1bc8016`): die vier Punkte sind automatisch getestet (headless, lokal und CI). Gate B bis E: nichts erfüllt, keine Tablet-Abnahme.

- [x] Deterministisches Replay. (`test_replay.gd`)
- [x] Save/Load-Hash identisch. (`test_save_load.gd`)
- [x] Sieg erst nach Bestätigung. (Szenario `as-c04-confirm-reject-win`)
- [x] Beschädigter Save wird erkannt. (`test_corrupt_save.gd`)

### Gate B · Vertical Slice

- [ ] Vollständige repräsentative Runde auf iPad.
- [ ] Wiederaufnahme nach erzwungenem App-Ende.
- [ ] Keine blockierende Animation.
- [ ] Spielleiter versteht jede Ansagekarte ohne Entwicklerhilfe.

### Gate C · Tablet-MVP

- [ ] Drei echte Runden im Flugmodus.
- [ ] Kein Datenverlust oder Geheimnisleck.
- [ ] Geführter und Expertenmodus geprüft.
- [ ] Legacy-App wird für die Testgruppe nicht mehr benötigt.

### Gate D · Lokale Clients

- [ ] Fremde Gerätezuordnung verhindert.
- [ ] Keine geheimen Felder in öffentlicher Projektion.
- [ ] Reconnect führt keine alte Aktion nachträglich aus.
- [ ] Tablet-Fallback deckt sämtliche Smartphoneaktionen ab.

### Gate E · Release

- [ ] Pilotmetriken erfüllt.
- [ ] Lizenz- und IP-Prüfung abgeschlossen.
- [ ] Alle Plattformbuilds signiert und archiviert.
- [ ] Keine offenen Releaseblocker.
