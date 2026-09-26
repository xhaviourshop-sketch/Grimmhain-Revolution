# NIGHT-REPORT — Phase 4: Zusammenfassung (Übernacht-Lauf)

Branch: `codex/night-abilities-audit` (von `4a93c0b`, abgezweigt von deinem
`codex/tablet-shell-phase1` @ `9bca92c`). Dein Branch ist **unberührt**, kein
Push, kein Merge. Jeder Schritt war `tsc --noEmit` + `npm run build` grün.

## Commits (in Reihenfolge)
1. `4a93c0b` chore(baseline) — uncommitteten Shell-Stand auf den Audit-Branch getragen.
2. `0764891` docs(audit) — Phase-1-Bug-Report + Phase-2-Fähigkeiten-Audit (read-only).
3. `8401a53` fix(mock) — Editor reflektiert jetzt ALLE 14 Flags (B3). *Verifiziert.*
4. `8d15359` fix(mock) — `openOptions` spammt das Protokoll nicht mehr (B7).
5. `6482898` feat(action) — ActionCenter: Info / Auswahl(entweder-oder) / Mehrfach-Ziel. *Verifiziert im Mock.*
6. `abb7ab3` feat(legacy) — `#overlay`-Dialoge → ActionCenter-`choice`. *Kompiliert/baut; Legacy-Laufzeit offen.*
7. `ba1fea8` feat(hud) — Tag/Nacht-Toggle in BottomBars (B2). *Verifiziert im Mock.*

## Was gebaut wurde (Details)

### Aktions-Modi im ActionCenter (Kern, Commit 5)
Das Aktions-Modell (`ActiveAction`) hat jetzt optionale Felder
`mode` (`target`|`info`|`choice`), `targetCount`, `chosenSeatIds`, `choices`
(backward-compatible). Der ActionCenter rendert den Fuß je nach Modus:
- **1 Ziel:** Pfeil-Selektor (wie bisher).
- **2+ Ziele:** Fortschritt „noch N" + gewählte Namen; Auswahl per Token-Tap (Adapter `selectPlayer` akkumuliert — exakt wie das Legacy-`startMulti`-`pickMode`).
- **Auswahl:** Entweder/Oder-Buttons → `pressDialogButton`.
- **Info:** „Weiter" → `confirmNightAction`.
Der Mock hat je einen Demo-Schritt (Doktor 2 Ziele, Waldhexe Auswahl, Hades Info),
damit jeder Modus testbar ist. **Verifiziert:** Rendern + Commit/Advance für alle
drei neuen Modi; „Retten" markiert Waldhexe `done`, „Weiter" markiert Hades `done`,
Doktor „noch 2 → noch 0" mit „Anna, Clara".

### Mock-Treue (Commits 3, 4)
- Editor reflektiert jeden Flag-Toggle (vorher 9 von 14 tot). Ring-Flags am Seat, `targeted` an der aktiven Wahl, der Rest im Round-Trip-Store. Keine Regeln.
- Optionen-Drawer öffnen spammt das Protokoll nicht mehr.

### Legacy-Dialoge (Commit 6)
`#overlay`-Dialoge (Loki Liebe/Hass, Waldhexe retten/verdammen, `startConfirm`
Ja/Nein, Info-Modals) werden read-only auf `mode="choice"` gemappt; der echte
Legacy-Button wird über `pressDialogButton` geklickt. **Offen:** Laufzeit-Test im
Legacy-Modus (der Mock kann keine Legacy-Dialoge erzeugen).

### Tag/Nacht (Commit 7)
Toggle in den Bottom-Leisten → `adapter.setPhase`. Vorher gab es KEINE UI dafür.

## Was offen ist (für morgen)

### Verifizierbar, aber noch nicht gebaut
- **Multi-Ziel im LEGACY:** Mechanisch funktioniert Mehrfach-Tap bereits (pickMode akkumuliert), aber `targetCount`/`chosenSeatIds` werden im Legacy-Snapshot NICHT gesetzt → kein „noch N"-Fortschritt im Legacy. Quelle wäre der Pickbar-Hint („noch N") — **fragiles String-Parsing** (s. unten).
- **Info-Ergebnisse im LEGACY:** Rollen wie Orakel/Doktor/Waldläufer zeigen ihr Ergebnis über `center()` (Toast) oder ein `#overlay`. Toasts (`center`) werden gar nicht gespiegelt → in React unsichtbar. Overlays kommen über Commit 6 durch.
- **1-Ziel-Führung:** Die erlaubten Sitze (`allow`-Prädikat) werden nicht hervorgehoben; man kann „daneben" tippen (No-op). Bräuchte ein `allowedSeatIds`-Feld im Snapshot.

### Aufräumen (klein)
- B8 `getProtocol()` bei jedem Render; B9 ActionCenter-Zielwechsel ignoriert `allow`; B11 toter Code in `boardLayout.ts` (`computeGeometry`/`DEFAULT_LAYOUT`/`minNeighborDist`); B12 `ActionPanel.tsx` (alt) jetzt komplett ungenutzt — könnte zugunsten des ActionCenter-`choice`-Pfads entfernt werden.
- **Kosmetik:** Im Mock zeigt der ActionCenter Instruktion + Beschreibung doppelt, weil die Mock-Step-Daten `entry.instruction := description` setzen. Im Legacy unterscheiden sich die beiden (Order-Text vs Pick-Hint) → dort kein Doppel. Optional: im Mock `entry.instruction` von `description` entkoppeln.

## Riskant / braucht deine Entscheidung (NICHT geraten)

1. **Legacy `goToNightStep` führt die Fähigkeit aus** (`onOrderClick` = Snapshot + Pick starten), während es im Mock nur den Glow bewegt (B5). Wenn du im React-Nachtfluss ein reines „Glow setzen, ohne auszuführen" willst, geht das im Legacy nicht ohne Logik-Eingriff. **Entscheidung:** Ist „Slot-Klick = Schritt ausführen" im Legacy ok? (Ich halte es für vertretbar.)
2. **Multi-Ziel-Anzahl im Legacy** steht nur als Text im Pickbar-Hint („noch N"). Robust auslesen = Parsing dieser Strings — fragil und sprachabhängig. **Entscheidung:** Soll ich das per Heuristik parsen (Risiko) ODER lieber eine schmale, additive Lese-Schnittstelle an der Legacy-Pickbar anlegen (sauberer, aber 1 Legacy-Datei wird angefasst — gegen die „nur lesen"-Regel)?
3. **`center()`-Toasts (Info-Ergebnisse)** werden nirgends gespiegelt. Soll ich `center` analog zum Overlay in den `domMirror` aufnehmen (additiv, Legacy-Scaffold) — oder bleibt Info-Ausgabe vorerst Legacy-intern?
4. **Hades-Sub-Menü** (Lichter kaufen) ist ein eigener, komplexer Flow — braucht eigene UI-Konzeption.
5. **Spezialfälle (?)** aus dem Abilities-Report (Schattenhund 0-Ziel, Märtyrerin Ja/Nein, Pestbringerin, Zeitwächter, Frankenstein-Folgeaktion) — Handler nicht einzeln verifiziert; vor Implementierung kurz gegen `abilities-roles-chunk.js` prüfen.

## Empfohlene Reihenfolge für morgen
1. **Entscheidung zu Punkt 2/3** (Legacy-Multi-Count + `center`-Mirror) — das schaltet die meisten verbleibenden Info-/Multi-Lücken frei.
2. **Legacy-Laufzeit-Test** der Dialog-`choice`-Verdrahtung (Commit 6) im `?adapter=legacy`-Modus, dann Multi-Ziel-Fortschritt im Legacy.
3. **`allowedSeatIds`** in den Snapshot (1-Ziel-Führung + Multi-`allow`).
4. **Aufräumen** B8/B9/B11/B12 + Mock-Instruktion-Doppel.
5. **Spezialrollen** einzeln (Hades, dann die (?)-Fälle).

## Zustand am Ende
- Branch `codex/night-abilities-audit`: 7 Commits, 3 Reports, Baum sauber.
- Branch `codex/tablet-shell-phase1`: unverändert bei `9bca92c`.
- Kein Push. `tsc --noEmit` + `npm run build` grün.
