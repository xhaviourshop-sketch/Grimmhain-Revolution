# Vertical Slice · Rollenauswahl

**Stand:** 2026-09-26 · **Status:** freigegeben; alle Regelfragen sind entschieden (`decision-request.md`, `../../masterplan/DECISION-LOG.md`)
**Grundlagen:** `../../../GRIMMHAIN-REVOLUTION-MASTERPLAN.md`, `../../masterplan/DECISION-LOG.md`, `../../masterplan/RULE-MIGRATION-MATRIX.md`, `../../godot-migration/04-rules-migration-matrix.md` (Abschnitt A), `../../godot-migration/07-open-questions.md`

Pfadangaben in dieser Datei sind relativ zu `docs/specs/vertical-slice/`. Zeilennummern beziehen sich auf Commit `c5a9e98` und dienen nur als Suchhilfe; maßgeblich ist der Symbolname.

---

## 1. Ergebnis

Der Vertical Slice verwendet **11 bestehende Rollen**. Keine Rolle wurde erfunden. Alle stammen aus `ALL_ROLES` in `../../../js/core/roles.js`.

| # | Technische ID | DE / EN | Fraktion (Sieg) | Hauptzweck im Slice | Legacy-Status laut `04` |
|---|---|---|---|---|---|
| 1 | `dorfbewohner` | Dorfbewohner / Villager | Dorf | Grundfall, Auffüllrolle, Paritätsrechnung | verifiziert (A-72) |
| 2 | `werwolf` | Werwolf / Werewolf | Werwölfe | Wolfsangriff | verifiziert, Bug F2 (A-12) |
| 3 | `schutzengel` | Schutzengel / Guardian Angel | Dorf | Schutz | widersprüchlich: Zeitpunkt (A-11) |
| 4 | `das-orakel` | Das Orakel / The Oracle | Dorf | Information | verifiziert (A-8) |
| 5 | `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Werwölfe | gezielte Fehlinformation (vom Spielleiter gewählte Scheinrolle) | verifiziert (A-33), Zufall durch DR-08 ersetzt |
| 6 | `waldhexe` | Waldhexe / Witch of the Woods | Dorf | mehrstufige Aktion, Rettung, Sofort-Tod | verifiziert (A-4), Text mehrdeutig |
| 7 | `sensentraeger` | Sensenträger / Reaper | Dorf | Todeseffekt, Reaktionswarteschlange | verifiziert, Zeitpunkt unklar (A-6) |
| 8 | `wolfskind` | Wolfskind / Wolf Child | Dorf → Werwölfe | Fraktionswechsel durch fremden Tod | verifiziert (A-7) |
| 9 | `lehrling` | Lehrling / Apprentice | Dorf → geerbte Rolle | verdeckte Bindung, echter Rollenwechsel | neu geregelt durch DR-11, Bug F5 behoben (A-24) |
| 10 | `manipulator` | Manipulator / Manipulator | Einzelsieg | Nominierungsreaktion, Solo-Sieg | widersprüchlich, Richter-Bug (A-67) |
| 11 | `spiegelwolf` | Spiegelwolf / Mirror Wolf | Werwölfe | Hinrichtungsreaktion auf gespeicherte Nominierende | verifiziert (A-31) |

Die technische ID folgt DR-01 (deutsches ASCII-kebab-case, `../../masterplan/DECISION-LOG.md`) und dem Schema aus `../../godot-migration/03-godot-architecture.md` §5.1.

## 2. Abdeckung der Pflichtmechaniken

Pflichtliste aus Prompt 1 und `../../masterplan/RULE-MIGRATION-MATRIX.md` („Auswahlverfahren für Vertical Slice").

| Mechanik | Primär abgedeckt durch | Zusätzlich berührt durch |
|---|---|---|
| Schutz vor Angriff | `schutzengel` | `waldhexe` (Rettung) |
| Informationsgewinn | `das-orakel` | `waldhexe` (sieht Wolfsopfer) |
| gezielte Fehlinformation | `trugbilderwolf` (erscheint dem Orakel mit der vom Spielleiter gewählten Scheinrolle, DR-08) | – |
| Wolfsangriff | `werwolf` (Rudelschritt inkl. `trugbilderwolf`, `spiegelwolf`, verwandeltes `wolfskind`) | – |
| direkte oder verzögerte Todesursache | `werwolf` (Tod am Morgen) | `waldhexe` (Gift sofort), `manipulator` (Tod bei Nominierung), `spiegelwolf` (Tod des Nominierenden) |
| Nominierungsreaktion | `manipulator` (stirbt bei Nominierung) | `spiegelwolf` (nutzt gespeicherte Nominierende) |
| Todeseffekt und Reaktionswarteschlange | `sensentraeger` | `wolfskind` und `lehrling` (reagieren auf fremden Tod) |
| Rollen- oder Fraktionswechsel | `lehrling` (Rolle über verdeckte Bindung, DR-11), `wolfskind` (Fraktion) | – |
| Solo-Sieg oder manuelle Siegerklärung | `manipulator` | generische Siegbestätigung durch den Spielleiter |
| mehrstufiger Prompt mit Abbruch und Wiederaufnahme | `waldhexe` (Opfer sehen → retten? → vergiften? → Ziel → bestätigen) | `lehrling` (Spielleiter wählt drei Personen → Lehrling wählt eine Rolle), `sensentraeger` (verfluchen? → Ziel) |
| Zufall mit gespeichertem Seed | Rollenverteilung | Anzeigereihenfolge gleicher Rollen im Lehrling-Schritt |

Jede Pflichtmechanik ist durch mindestens eine Rolle abgedeckt. Fehlinformation hängt allein am Trugbilderwolf; nach DR-08 wählt der Spielleiter die Scheinrolle, die Mechanik bleibt erhalten.

## 3. Begründung je Rolle

### 3.1 `dorfbewohner`
Ohne Fähigkeit. Nötig als Auffüllrolle (ohne Obergrenze; die Legacy-Grenze 10 aus `../../../setup.html` gilt nach `../../masterplan/DECISION-LOG.md` vom 26.09.2026 nicht) und als neutrale Referenz für Paritäts- und Siegtests. Einzige Dorfrolle, die Prompt 2 bereits im Core-Slice verlangt.

### 3.2 `werwolf`
Kern jeder Partie. Deckt Wolfsangriff, Tod am Morgen (`NIGHT_KILL`) und die Paritätsprüfung ab. Legacy: `Werwolf`-Handler in `../../../js/core/abilities-roles-chunk.js`, Morgenauflösung `resolveDayKills` in `../../../js/core/night.js`, Parität `checkWinConditions` und `countLivingWolfPower` in `../../../js/ui/core.js`. Der Legacy-Fehler F2 (keine Wolfszeile, wenn kein „Werwolf" lebt; `WOLF_KILL_ROLES` in `rebuildOrder`, `night.js`) wird laut `../../godot-migration/07-open-questions.md` Q1 Teil 2 ohne Rückfrage behoben.

### 3.3 `schutzengel`
Einfachste Schutzrolle mit klarer Nachtpriorität vor den Wölfen (`ORDER_BASE` Tier 1.3). Macht den Unterschied zwischen **Zielwahl** und **Auflösung** sichtbar, weil Legacy den Schutz bereits beim Antippen des Wolfsziels verbraucht (`Werwolf`-Handler, `abilities-roles-chunk.js`). Genau diese Klasse von Fehlern soll das Command-/Event-Modell verhindern. Entschieden in DR-05: Schutz nur in dieser Nacht, Anwendung erst in der Morgenauflösung.

### 3.4 `das-orakel`
Reine Informationsrolle ohne Zustandsänderung. Prüft die Trennung von Wahrheit, ermittelter und gezeigter Information und die Projektion „nur für den Handelnden". Legacy: `"Das Orakel"`-Handler in `abilities-roles-chunk.js`. Entschieden in DR-07: Sonderwölfe erscheinen als „Werwolf", Selbstprüfung verboten.

### 3.5 `trugbilderwolf`
Einzige bestehende Rolle, deren Kernmechanik Fehlinformation gegenüber einer Informationsrolle ist, ohne weitere Sondermechanik. Legacy nutzt Zufall (`Math.random` im Orakel-Handler); nach DR-08 wählt stattdessen der Spielleiter die Scheinrolle, sie wird gespeichert und bei jeder Prüfung wiederverwendet. Wacht mit dem Rudel (`WOLF_KILL_ROLES` in `night.js`).

### 3.6 `waldhexe`
Bekannte Klassikerrolle mit echter Mehrstufigkeit und zwei Einmal-Fähigkeiten. Prüft persistente Teilantworten, Abbruch ohne Teilwirkung und Einmal-Nutzung **pro Sitz** statt global (`state.once.WaldhexeL`/`WaldhexeD`). Löst als einzige Slice-Rolle einen **Sofort-Tod in der Nacht** aus (`witchDeadlyFatePick` in `../../../js/core/abilities-helpers.js`, Ursache `WITCH_POISON`). Legacy-Ablauf: `Waldhexe`-Handler in `abilities-roles-chunk.js` und `hexeAskDeath` in `abilities-helpers.js`. Entschieden in DR-06: je ein Heil- und Gifttrank, beide in einer Nacht erlaubt, Gift sofort, Name vor der Entscheidung, Rolle erst nach Rettung.

### 3.7 `sensentraeger`
Standardfall eines Todeseffekts mit Spielerentscheidung. Legacy hält die Warteschlange bereits im Zustand (`state.once.hunterQueue`, `window.__queueHunterOnDeath` und `processQueue` in `../../../game.html`), verarbeitet sie aber nur am Tag. Damit eignet sich die Rolle, die persistente `reaction_queue` aus `03` §5.2 zu beweisen. Entschieden in DR-09: freiwillig; nach Tod am Tag sofort, nach Tod in der Nacht in der Morgenauflösung.

### 3.8 `wolfskind`
Fraktionswechsel Dorf → Werwölfe, ausgelöst durch den Tod einer **anderen** Person. Verändert Paritätsrechnung und Orakel-Ergebnis während der laufenden Partie. Legacy: `Wolfskind`-Handler (`abilities-roles-chunk.js`), Verwandlung in `postDeathHooks` (`../../../js/ui/core.js`) über `flags.werewolf`. Entschieden in DR-10: keine Selbstwahl; nach der Verwandlung Rudel ab der folgenden Nacht.

### 3.9 `lehrling`
Einzige einfache Rolle mit **echtem Rollenwechsel**. Nach DR-11 wählt der Spielleiter drei Personen, der Lehrling sieht nur deren Rollen und wählt eine; die zugehörige Person bleibt ihm verborgen. Stirbt sie, während der Lehrling lebt, erbt er die Rolle mit zurückgesetzten Einsätzen ab der folgenden Nacht. Prüft damit gleichzeitig geheime Bindungen, projektionssichere Anzeige (nur Rollen, keine Identitäten), Zählung von Einsätzen pro Person (`resetOnceForInheritedRole` in `../../../js/ui/core.js`) und verzögerte Aktivierung. Der Legacy-Fehler F5 (toter Lehrling erbt, `postDeathHooks`) wird behoben.

### 3.10 `manipulator`
Deckt gleichzeitig **Nominierungsreaktion** und **Solo-Sieg** ab und nutzt dafür nur die ohnehin zu speichernde Nominierung. Legacy: Nominierungs-Chip in `openPop` (`../../../game.html`, `ManipulatorWasNominated`), Sieg in `checkWinConditions` (`../../../js/ui/core.js`). Der Richter-Bug entfällt im Slice, weil `korrupter-richter` nicht enthalten ist. Entschieden in DR-12 (genau drei Lebende) und DR-02 (bei gleichzeitigen Siegen entscheidet der Spielleiter).

### 3.11 `spiegelwolf`
Begründet, warum Nominierende gespeichert werden: Bei der ersten Hinrichtung stirbt statt ihm die nominierende Person. Legacy fragt den Nominierenden erst bei der Hinrichtung ab (`doLynchFlow`, `night.js`, Schlüssel `mirrorWolfWhoNominated`); im neuen Modell liegt er bereits aus `Nominate` vor. Entschieden in DR-13: ohne gespeicherte Nominierung keine Spiegelung, der Spiegelwolf stirbt normal.

## 4. Bewusst nicht gewählte naheliegende Kandidaten

| Rolle | Grund |
|---|---|
| `dorfwache`, `der-weise` | Schutz bereits durch Schutzengel abgedeckt; Der Weise hat Bug F10 und einen Lynch-Dialog, der den Slice verbreitert |
| `spuerhund` | Fehlinformation ist dort Nebenwirkung einer komplexeren Informationsmechanik |
| `loki`, `schwarze-witwe` | Kettentode und Rivalen-Widerspruch (Q1) vergrößern die Entscheidungsliste deutlich |
| `selbstmoerder` | Solo-Sieg bereits durch Manipulator abgedeckt |
| `korrupter-richter`, `blutwolf` | setzen Stimmgewichte voraus; digitale Stimmen sind laut `DECISION-LOG.md` ausgeschlossen |
| `dr-victor-frankenstein` | ideal für mehrstufige Prompts, aber Wiederbelebung und Rollenwahl gehören laut Masterplan erst in Phase 3 |
| `waechter-am-tor` | würde Wolfskind- und Lehrling-Verwandlungen blockieren; erst mit der zentralen Rollenwechsel-Funktion in Phase 3 |

## 5. Weg zu Version 1.0

Version 1.0 zielt auf 20 bis 30 Rollen (`DECISION-LOG.md`, Abschnitt Regeln). Die 11 Slice-Rollen sind als erste Charge gedacht. Weitere Chargen folgen nach Masterplan Phase 7 nach Mechanikfamilien (Information, Schutz/Umlenkung, Tod/Rollenwechsel, Solo-Siege). Diese Datei legt **keine** weiteren 1.0-Rollen fest.
