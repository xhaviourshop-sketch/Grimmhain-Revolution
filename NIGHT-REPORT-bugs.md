# NIGHT-REPORT — Phase 1: Bug- & Logik-Analyse (React-Shell + Adapter)

Stand: Branch `codex/night-abilities-audit` (von `4a93c0b`). Read-only-Analyse.
Quelle der Wahrheit für Spielregeln: `../Grimmhain/js/**` (Vanilla, nicht angefasst).

Legende Priorität: **KRITISCH** (blockiert echtes Spiel) · **MITTEL** (funktioniert, aber irreführend/lückenhaft) · **KLEIN** (Politur/Aufräumen).

---

## KRITISCH

### B1 — Legacy-Picks, Multi-Pick-Fortschritt und Dialoge haben keine React-UI
- **Datei:** `app/src/screens/GameScreen.tsx:74` (`showActionPanel = false`), `:122–140` (ActionPanel/DialogPanel hinter dem Flag).
- **Symptom:** Im Legacy-Modus laufen alle Nacht-Fähigkeiten über `startPick`/`startMulti`/`#overlay` (Vanilla `js/ui/ui.js:325,340`, `js/core/night.js`, `abilities-roles-chunk.js`). Die React-UI zeigt davon **nichts**: keinen Pick-Prompt („Tippe einen Sitz"), keinen Multi-Pick-Zähler („noch N"), keine Entweder/Oder-Dialoge (Loki Liebe/Hass, Waldhexe retten/verdammen, `startConfirm` Ja/Nein), keine Info-Modals.
- **Ursache:** Der neue `ActionCenter` ersetzt die Mitte, deckt aber nur „aktive Rolle + 1 Ziel" ab. `ActionPanel` (Pick-Prompt + Hint) und `DialogPanel` (`#overlay`-Mirror) existieren und sind komplett an den Adapter verdrahtet (`snap.activeAction`, `snap.dialog`, `pressDialogButton`), werden aber nie gemountet.
- **Wichtig:** Der Pick-MECHANISMUS funktioniert bereits — `startMulti` nutzt dasselbe `pickMode` und akkumuliert über wiederholte `pickMode.onSeat` (ui.js:340), und der Adapter `selectPlayer` ruft genau das (`legacyAdapter.ts` `selectPlayer` → `pm.onSeat(seat)`). Es fehlt nur die ANZEIGE/Führung.
- **Fix-Vorschlag:** `DialogPanel` mounten, wenn `snap.dialog != null`; Pick-Prompt + `pick.hint` (inkl. „noch N") im `ActionCenter` oder einem schlanken Overlay anzeigen. Additiv, alles über den Adapter. (Phase 3 baut den verifizierbaren Mock-Teil; das Legacy-Mirror-Parsing für Multi-Count ist fragil → s. B6 / Summary.)

### B2 — Kein Tag/Nacht-Umschalter in der UI
- **Datei:** `app/src/screens/GameScreen.tsx:77` (`showPhaseControls = false`).
- **Symptom:** `adapter.setPhase("day"|"night")` wird von keiner gemounteten Komponente aufgerufen. `BottomBars` und `NightOrder` bieten nur Undo/Confirm. Man kann aus der UI heraus **nicht** die Nacht starten/beenden oder zum Tag wechseln.
- **Ursache:** `PhaseControls` (einzige `setPhase`-Quelle) ist hinter `showPhaseControls=false`.
- **Fix-Vorschlag:** Tag/Nacht-Toggle additiv (z. B. in `BottomBars` neben dem Timer) → `adapter.setPhase(...)`. Legacy `setPhase` ruft korrekt `onNightStart`/`onDayStart` (`legacyAdapter.ts`).

---

## MITTEL

### B3 — Mock `setPlayerFlag` verwirft 9 von 14 Editor-Flags still
- **Datei:** `app/src/adapter/mockAdapter.ts` (`setPlayerFlag`, `switch` nur `dead`/`poisoned`/`protected`/`hmark`).
- **Symptom:** Editor-Chips für `nominated`, `deadVoteStripped`, `burned`, `charmed`, `inlove`, `rival`, `puppet`, `vorbild`, `werewolf` tun im Mock nichts → wirkt kaputt. (Im Legacy wirken sie voll inkl. Nebenwirkungen.)
- **Ursache:** Mock modelliert nur die ring-relevanten Flags.
- **Fix-Vorschlag:** Mock-Seat einen vollständigen `flags`-Record geben und in `setPlayerFlag` alle 14 schreiben (reine Bool-Speicherung, keine Regeln). Dann reflektiert der Editor jeden Toggle. (Phase 3, verifizierbar.)

### B4 — `silenced` im Mock nicht setzbar
- **Datei:** `app/src/adapter/types.ts` (`PlayerFlag` ohne `silenced`), `mockAdapter.ts` (`flags.silenced` immer `false`).
- **Symptom:** `ring-silenced` erscheint im Mock nie. Legacy speist `silenced` aus `state.once.TotenratFuehrerSilenced` (`legacyAdapter.ts`), kein Chip.
- **Ursache:** „silenced" ist im Vanilla ein Once-Listen-Zustand, kein Editor-Chip.
- **Fix-Vorschlag:** Dokumentiert lassen; optional ein Mock-Test-Toggle. Keine echte Regel.

### B5 — Legacy `goToNightStep` STARTET die Fähigkeit, statt nur den Glow zu setzen
- **Datei:** `app/src/adapter/legacy/legacyAdapter.ts` (`goToNightStep` → `w.onOrderClick(role)`), Vanilla `js/core/abilities.js:71` (`onOrderClick` macht `snapshot()` + startet Actor-Pick).
- **Symptom:** Klick auf einen Nachtreihenfolge-Slot im Legacy-Modus **führt die Rolle aus** (Snapshot + Pick startet). Im Mock bewegt derselbe Klick nur den Glow (setzt `activeIndex`). → Inkonsistente Semantik Mock vs Legacy; `index`-Parameter wird im Legacy ignoriert.
- **Ursache:** Legacy hat keinen reinen „set active index" — `onOrderClick` ist der einzige Einstieg und ist zugleich der Ausführungs-Trigger.
- **Fix-Vorschlag:** Nicht raten. Dokumentiert: Wenn ein reines „Glow setzen ohne Ausführen" gewünscht ist, braucht es eine Markus-Entscheidung (Legacy bietet das nicht ohne Logik-Eingriff). Aktuell ist „Slot-Klick = Schritt ausführen" im Legacy vertretbar.

### B6 — `ActionCenter`-Ziel zeigt nur 1 Ziel; Multi-Pick-Fortschritt unsichtbar
- **Datei:** `app/src/components/ActionCenter.tsx` (`target = seats.find(s => s.targeted)`).
- **Symptom:** Bei einem Legacy-Multi-Pick (`startMulti` akkumuliert in `chosen`, setzt `flags.targeted` erst bei `done`) zeigt das Panel „kein Ziel" und keinen „noch N"-Fortschritt.
- **Ursache:** Multi-Pick-Zustand lebt nur in der Legacy-Pickbar (Mirror `pick.hint`), wird nicht durchgereicht.
- **Fix-Vorschlag:** `pick.hint` anzeigen; bzw. echte Multi-Ziel-UI (Phase 3 Mock-Teil + dokumentierte Legacy-Lücke).

---

## KLEIN

### B7 — Mock `openOptions` spammt das Protokoll
- **Datei:** `app/src/adapter/mockAdapter.ts` (`openOptions` pusht jedes Mal „⚙ Optionen geöffnet").
- **Symptom:** Jedes Öffnen des Optionen-Drawers hängt einen Log-Eintrag an → das Protokoll füllt sich mit Rauschen.
- **Fix-Vorschlag:** Log-Push entfernen (oder nur einmalig).

### B8 — `getProtocol()` bei jedem Render
- **Datei:** `app/src/screens/GameScreen.tsx:144` (`entries={adapter.getProtocol()}`).
- **Symptom:** Legacy mappt die Einträge bei jedem Render neu (neues Array). Harmlos, aber unnötig.
- **Fix-Vorschlag:** Nur wenn Drawer offen, oder memoisieren. Niedrige Priorität.

### B9 — `ActionCenter`-Zielwechsel ignoriert die Legacy-`allow`-Bedingung
- **Datei:** `app/src/components/ActionCenter.tsx` (`pool = seats.filter(s => !s.dead)`).
- **Symptom:** Die Pfeile durchlaufen ALLE lebenden Sitze. Bei einem Legacy-Pick mit engerem `allow` (nicht-selbst, nur Tote, …) führt `selectPlayer` auf einen unerlaubten Sitz zu `onSeat`→`allow`-Fail→No-op; das Panel kann ein veraltetes Ziel zeigen.
- **Fix-Vorschlag:** Niedrige Priorität; im Mock keine `allow`. Bei echter Multi-UI die erlaubten Sitze aus der Snapshot-Aktion ableiten (braucht Adapter-Feld → Entscheidung).

### B10 — Mock kann 0-Ziel/Info-Rollen nicht ausdrücken
- **Datei:** `app/src/adapter/mockAdapter.ts` (`confirmNightAction` verlangt für Nicht-Decoy ein `targetSeatId`).
- **Symptom:** Eine Info-only-Rolle (kein Ziel) wäre im Mock nicht bestätigbar. (Mock hat aktuell keine solche Rolle.)
- **Fix-Vorschlag:** Phase 3 erweitert das Mock-Aktionsmodell um `mode: info | choice | target(n)`.

---

## DEAD/UNUSED (kein Fehler, Aufräum-Kandidaten)

- **B11** — `computeGeometry`, `DEFAULT_LAYOUT`, `minNeighborDist` in `app/src/pixi/boardLayout.ts` sind ungenutzt, seit `DomBoard` eine eigene, spielerzahl-unabhängige Ring-Mathematik nutzt. Nur `seatPosition` + Typ `BoardGeometry` bleiben. (Außerhalb dieses Auftrags; nicht angefasst.)
- **B12** — `app/src/components/ActionPanel.tsx` (`ActionPanel` + `DialogPanel`) ist vollständig an den Adapter verdrahtet, aber nie gemountet (siehe B1). „Fertig, aber dunkel."

---

## Konsistenz Status-Flags → Snapshot → UI (geprüft, ok)

- `SeatView` trägt `dead/poisoned/protected/silenced/marked` + `flags`-Record (`types.ts`).
- Legacy füllt diese read-only aus `state.seats[].flags` + `once.TotenratFuehrerSilenced` (`legacyAdapter.ts`).
- `DomBoard.ringFor` liest genau diese Felder; `dead` überschreibt alle Ringe. Mapping konsistent.
- Einzige Lücke: `silenced` im Mock (B4) und die nicht-persistierten Editor-Flags (B3).

## Nacht-Flow / Index-Identität (geprüft, ok)

- `NightOrder` nutzt `key={`${i}-${e.role}`}` und `onStep(i, role)` → `goToNightStep(role, index)`. Index ist im Mock autoritativ (löst das Duplikat-Rollen-Problem). Legacy-Order hat je Rolle genau einen Slot (`ORDER_BASE`), daher dort kein Duplikat. Kein Off-by-one gefunden.
- `confirmNightAction`/`undo` Mock konsistent; Legacy blockt korrekt bei laufendem Pick/Dialog.
