<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G6 Dorf-Gruppe 2: Legacy-Rollenprüfung

Geprüfte Rollen: korrupter-richter, maertyrerin, dorfwache, kutscher, seelentauscher, blutpriester, traumdeuter, henker.
Stand des Repos: Arbeitsbaum ohne Änderungen, nur gelesen. Zeilenangaben gegen den aktuellen Stand geprüft.
Pfadkürzel wie im Auftrag (`roles`, `chunk`, `ab`, `help`, `night`, `core`, `ui`, `state`, `gh`).

Hinweis zu wörtlichen Rollentexten: Sie sind unverändert zitiert und können deshalb Gedankenstriche aus dem Original enthalten.

Allgemein geltende Befunde (werden unten pro Rolle referenziert):
- Keine der acht Rollen hat einen Eintrag in `state.js:16-45` `migrateLegacyRoleIds` (keine Altnamen).
- Keine der acht Rollen steht in `WOLF_ROLES_SET` (`roles:391-397`) oder `SOLO_ROLES_SET` (`roles:399-403`), also `getRoleFaction` (`roles:405-409`) = `"dorf"`.
- `role-abilities.js` enthält für alle acht Rollen exakt denselben DE-Text wie `ROLE_DESCRIPTIONS` (per Skript Zeichen für Zeichen verglichen); genutzt nur in `gh:684` (Rollenkarten-Popup).
- Bilder: `assets/cards/de/<Name mit _>.webp` über `roles:417` `roleToImagePath`; EN-Bilder über `gh:822-829` `CARD_MAP_EN` bzw. `app/src/roleCard.ts:44-59` (Corrupt_Judge, Martyr, Village_Guard, Coachman, Soul_Swapper, Blood_Priest, Dreamer, Executioner). Alle Dateien existieren in `assets/cards/de` und `assets/cards/en`.
- React: `app/src` enthält für keine der acht Rollen eigenes Regelverhalten; nur Bildzuordnung (`roleCard.ts`), Flag-Durchreichung (`adapter/legacy/legacyAdapter.ts:365,383,388,399` für `nominated`/`hmark`), Chip-Labels (`components/PlayerEditor.tsx:28,54`, `MarkerLegend.tsx:17,38`) und ein Kommentar zur Märtyrerin-Kopfzeile (`components/ActionCenter.tsx:192`).
- `state.ui.ghostCasting` (lässt `isOnceUsed` immer false liefern, `night:4`) wird nirgends auf true gesetzt (rg über js, game.html, app/src): toter Code.

---

### korrupter-richter
- DE-Name / EN-Name: Korrupter Richter / Corrupt Judge (`roles:156`).
- Aliase/Altnamen: keine in `migrateLegacyRoleIds`. Bild-Keys `Korrupter_Richter.webp` (DE), `Corrupt_Judge` (`gh:823`, `app/src/roleCard.ts:44`). Handler-Prompt kurz "Richter  (U+2014) markiere 1" (`chunk:722`). SFX-Key `sfxJudge` (`night:213-215`, No-op).
- Legacy-ID: `"Korrupter Richter"` (`roles:1`).
- Fraktion: `dorf` (nicht in Wolf-/Solo-Set). Keine weiteren Fraktionsbesonderheiten.
- Akte: Akt II (`akte.js:35`).
- Nachtpriorität: `ORDER_BASE` tier 1.5, kein `once` (`roles:13`). Bedingungen in `night:22-128` `rebuildOrder`: nur allgemeine (Rolle lebt, `hasAliveRole`, `night:92`); keine Sonderbedingung; nicht im Passiv-Set (`night:96`). Blockaden in `ab:94-99` greifen (Schattenhund, Zeitwächter, Der-Weise-Debuff, Albtraum).
- Quelltextstellen:
  - `chunk:720-725` `"Korrupter Richter"`: Ja/Nein-Dialog "Heute markieren?"; Ja → `pick` beliebige lebende Person → `s.flags.nominated=true; state.pending.judgeAsk=true`; Nein → `state.pending.judgeAsk=false`.
  - `night:145` `onNightStart`: setzt bei jeder Nacht `flags.nominated=false` für alle (vor dem Richter-Schritt).
  - `night:213-215` `onDayStart`: wenn irgendein Sitz `nominated` ist → `queueSfxKey("sfxJudge")` (No-op laut CLAUDE.md).
  - `night:506-510` `resetNightState` und `night:519` `resetMarksOnly`: löschen `nominated`.
  - `state:71-72` `migrateState`: Defaults `ui.judgeAsk`, `pending.judgeAsk`; `judgeAsk` wird nirgends gelesen (rg).
  - `ui:109` `markerList`: Marker "⚖" bei `flags.nominated`.
  - `gh:429` Chip-Handler: Manipulator stirbt nur, wenn "nominiert" per Chip gesetzt wird (`ManipulatorWasNominated`, `applyKill(...,"MANIPULATOR_NOMINATED")`); gleiches in `app/src/adapter/legacy/legacyAdapter.ts:543-544`.
  - `night:421-503` `doLynchFlow`: liest `flags.nominated` nicht.
- Text DE (wörtlich): "Kann einen Spieler für den Tag markieren; dieser ist automatisch mit +1 Stimme nominiert." (`roles:82`)
- Text EN (wörtlich): "Can mark a player for the day; they are automatically nominated with +1 vote." (`roles:231`)
- DE/EN-Vergleich: semantisch gleich JA (Markierung für den Tag, automatische Nominierung, +1 Stimme; kein Unterschied in Zeitpunkt/Häufigkeit/Ziel).
- Weitere Texte: `role-abilities.js:21` identisch. Dialogtexte "Heute markieren?", "Ja", "Nein", "Richter  (U+2014) markiere 1" hart kodiert DE; "Heute markieren?" und "markiere 1" haben Laufzeit-Übersetzung (`i18n.js:755,821,850`), direkte `mb.textContent`-Zuweisung umgeht aber laut `GRIMMHAIN_ANALYSE_2026-06-12.md` H die Laufzeitübersetzung (für diesen Dialog nicht selbst im Browser geprüft). Kein Totenkarten-Bezug (rg `cards.js`).
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht als Schritt vor den Wölfen (tier 1.5); keine Begrenzung pro Partie.
  2. Optional: Nein-Knopf verzichtet.
  3. Ziel: eine lebende Person, Selbstwahl erlaubt (Filter nur `!x.flags.dead`), tote Ziele ausgeschlossen.
  4. Wirkung: nur `flags.nominated=true`. Keine Stimme, kein Stimmgewicht, keine Verknüpfung mit dem Lynch (`doLynchFlow` wählt direkt).
  5. Dauer: bleibt über den Tag bis zur nächsten `onNightStart` (`night:145`) oder manuellem Reset.
  6. Sichtbarkeit: Marker "⚖" am Sitz auf dem SL-Bildschirm; keine separate öffentliche Ansage.
  7. Mehrere Kopien: ein Nachtorder-Eintrag pro Rollenname; jeder Klick setzt eine weitere Markierung (alte werden nicht gelöscht).
  8. Zufall: keiner (kein Math.random).
  9. Manipulator: Richter-Nominierung setzt weder `ManipulatorWasNominated` noch tötet sie ihn (nur der Chip-Pfad `gh:429` tut das).
  10. Spiegelwolf: Nominierenden fragt `night:487` manuell ab; die Richter-Nominierung hat keine Quelle.
  11. Rollenwechsel/Wiederbelebung/Sieg: keine eigene Interaktion.
- React-Version: kein eigenes Verhalten; reicht `nominated` durch (`legacyAdapter.ts:365,388`), Manipulator-Chip-Nebenwirkung gespiegelt (`legacyAdapter.ts:543-544`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 26: "fehlend", `chunk:720-725`, "+1 Stimme nicht umgesetzt (kein Stimmsystem); Manipulator-Effekt fehlt (Bug)". Bestätigt (Zeilen stimmen).
  - 07 Q2: Stimmabgabe; Empfehlung A im MVP. 07 Q1 Teil 2 listet "Manipulator bei Richter-Nominierung" als Bug. DECISION-LOG: "Stimmen werden nicht digital gespeichert" und "Nominierung speichert Nominierende und Nominierte". Damit ist Q2 faktisch entschieden (Option A): "+1 Stimme" kann nur ein SL-Hinweis sein.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` H: Richter-Dialog hart kodiert (`chunk:718` damals, heute 720-725). Bestätigt.
  - NIGHT-REPORT-abilities.md:31 "1 Ziel, 🟡": bestätigt (Ja/Nein vor dem Ziel fehlt in der Beschreibung).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| +1 Stimme | "mit +1 Stimme nominiert" | "+1 vote" | nur Flag, keine Stimme | nur Flag | 04 fehlend; DECISION-LOG: Stimmen physisch | SL-Hinweis "zählt +1 Stimme" am nominierten Sitz | Rolle verliert "+1 Stimme", Text anpassen | ohne Hinweis wirkungslos, Rolle nahezu leer | A: nur Anzeige in Nomination-Ansicht; B: nur Text | A (Hinweis + Protokoll) | Ja |
| Wer ist Nominierender? | nicht genannt | nicht genannt | keine Quelle | – | DECISION-LOG: Nominierende werden gespeichert | Richter ist Nominierender (Spiegelwolf trifft Richter) | anonyme System-Nominierung (Spiegelwolf ohne Ziel) | Spiegelwolf-Gefahr für Richter | Nominations braucht Quelle `system`/`role` | PO klärt | Ja |
| Zählt gegen "einmal nominiert werden"? | – | – | kein Limit | – | DECISION-LOG Limit 1 | zählt | zählt nicht | Richter kann reguläre Nominierung blockieren | Nominations-Regeloption | zählt als Nominierung | Ja |

- Bugs:
  - B-KR-1, echter Bug: Codepfad `chunk:722` setzt `flags.nominated` direkt; `gh:429` (einziger Manipulator-Trigger) wird umgangen. Tatsächlich: Manipulator bleibt am Leben und behält Siegchance (`core:234-235`). Erwartet laut Manipulator-Text ("The moment he is nominated, he dies immediately", `roles:280`) und 07 Q1 Teil 2: Tod. Risiko mittel (falscher Einzelsieg). Regressionstest: Richter markiert Manipulator → Manipulator stirbt mit `MANIPULATOR_NOMINATED`, `ever_nominated=true`.
  - B-KR-2, technische Altlast: `state.pending.judgeAsk`/`state.ui.judgeAsk` werden geschrieben, nie gelesen (`chunk:722-723`, `state:71-72`). Risiko niedrig. Test: nicht nötig, beim Port weglassen.
  - B-KR-3, technische Altlast: hart kodierte DE-Dialogtexte (`chunk:721-722`). Risiko niedrig. Test: EN-Lokalisierung des Richter-Prompts.
- Legacy-Status: not-found. Die versprochene Kernmechanik "+1 Stimme" existiert im Code nicht; vorhanden ist nur ein Nominierungs-Marker ohne Wirkung auf den Lynch, zusätzlich Manipulator-Bug.
- Automationsvorschlag: assisted. Markierung und Nominierungsdatensatz automatisch; Stimmzählung bleibt laut DECISION-LOG physisch, App zeigt nur "+1".
- Mechanikfamilie primär + sekundär: primär Nominierungsreaktion (setzt Nominierung); sekundär Tagfähigkeit (Wirkung am Tag, ausgelöst nachts).
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (Ja/Nein + Ziel, abbrechbar), Nominations (inkl. `ever_nominated`, Manipulator-Tod über KillPipeline), Ereignis-Sichtbarkeit (öffentliche Nominierung), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Nominierungsquelle "Rolle/System" im Nominations-Modell (nachweislich nötig, weil Spiegelwolf und Nominierungslimit eine Quelle brauchen); Anzeige eines Stimmbonus (kein Stimmsystem, nur Hinweis-Modifikator am Tag). Kein volles Stimmsystem.
- Abhängigkeiten: Manipulator, Spiegelwolf, Nominations-Limit, Albtraumwolf/Schattenhund/Zeitwächter/Der Weise (Blockaden), Hades (Stimme x3) und Blutwolf nur konzeptionell (weitere Stimmrollen).
- Komplexität / Fehlerrisiko: S / mittel (einfach, aber Kopplung an Nominations- und Manipulator-Regeln).
- Offene Entscheidungen: (1) Ist der Richter der Nominierende (Spiegelwolf-Folge)? (2) Zählt die Richter-Nominierung für das Einmal-Limit von Nominierendem/Nominiertem? (3) Darf der Richter sich selbst markieren? (4) "+1 Stimme" als reiner SL-Hinweis oder Text streichen? (5) Pflicht oder optional pro Nacht (Legacy: optional)?
- Relevante Testgruppen:
  - Normalfall: Richter markiert B in Nacht 1 → Tag 1: B nominiert, Hinweis "+1", Ereignis öffentlich.
  - Ungültiges Ziel: toter Spieler als Ziel → `invalid_target`.
  - Tote Person: Richter tot → kein Schritt.
  - Selbstwahl: Richter wählt sich selbst → nach PO-Entscheidung erlaubt/abgelehnt (Legacy erlaubt).
  - Mehrere Kopien: zwei Richter → je ein Schritt, zwei Nominierungen.
  - Wiederbelebung: nicht relevant, weil keine Richter-spezifische Nachwirkung.
  - Rollenwechsel: Seelentauscher gibt Richter-Rolle weiter → neuer Träger erhält ab nächster Nacht den Schritt.
  - Save/Load: Speichern nach Markierung vor Tagesbeginn → Nominierung bleibt erhalten.
  - Replay: Nominierung aus Befehl reproduzierbar, gleicher Hash.
  - SL-Korrektur: SL entfernt Richter-Nominierung per GmCorrection → Protokoll.
  - Sichtbarkeit: Nominierung öffentlich, Richterrolle nicht offengelegt.
  - Schutz: nicht relevant, weil kein Tod.
  - Todesreaktionen: Manipulator als Ziel → stirbt sofort (B-KR-1).
  - Siegprüfung: Manipulator vom Richter nominiert → nie Siegkandidat.
  - Beschädigter Spielstand: Nominierung auf unbekannte Person-ID → Laden abgelehnt.
- Belegsicherheit: hoch für Code; mittel für EN-Laufzeitübersetzung des Dialogs (nicht im Browser geprüft).

### maertyrerin
- DE-Name / EN-Name: Märtyrerin / Martyr (`roles:157`).
- Aliase/Altnamen: keine in `migrateLegacyRoleIds`. State-Schlüssel `once.MaertyUsed` (Schreibweise ohne "r" nach "Mae"). Bild `Märtyrerin.webp` / `Martyr` (`gh:824`, `roleCard.ts:45`). Laufzeitübersetzung "Märtyrerin" → "Martyr" (`i18n.js:802`).
- Legacy-ID: `"Märtyrerin"` (`roles:1`).
- Fraktion: `dorf`.
- Akte: Akt II (`akte.js:37`).
- Nachtpriorität: `ORDER_BASE` tier 9.0, kein `once` (`roles:58`). Keine Sonderbedingung in `rebuildOrder`, nicht passiv (`night:96`) → Zeile erscheint jede Nacht, solange sie lebt, auch nach Verbrauch. Es gibt keinen Handler in `chunk`, `help` oder `ab` (rg): Klick zeigt "Keine Fähigkeit" (`ab:100`). Die echte Mechanik läuft in `onDayStart`.
- Quelltextstellen:
  - `night:257-265` `onDayStart` → `continueResolveDay`: `martyr = seats.find(role==="Märtyrerin" && !dead && !once.MaertyUsed)`; bei vorhandenem Nachtziel Dialog mit `nightTargets[0]`; "Opfern" → `applyKill(martyr,"MARTYR_SACRIFICE")`, `v.flags.targeted=false`, `MaertyUsed=true`, `resolveDayKills(nightTargets ohne v)`; "Nein" → `resolveDayKills(nightTargets)`.
  - `night:237-256`: vorher werden Schicksalswolf-Extras, Rudelvater-Extraopfer, Dorfwache-Filter und Voodoo-Umlenkung angewendet.
  - `night:322-331` `resolveDayKills`: Zeitwächter-Einfrieren wird erst danach geprüft.
  - `night:334` `resolveDayKills`: Albtraum-Filter `meta.blockedTonight` erst danach.
  - `ui:406` Todesursachen-Label, `gh:2420` Logtext, `i18n.js:137,461` `logMartyrSacrifice`, `i18n.js:251,575` `martyrSacrifice`.
  - `gh:522,558` Reset setzt `MaertyUsed=false`; `state:65` Default.
  - `core:339-359` `resetOnceForInheritedRole`: kein Eintrag für Märtyrerin.
- Text DE (wörtlich): "Kann sich selbst opfern, um das Nachtopfer zu retten." (`roles:83`)
- Text EN (wörtlich): "Can sacrifice herself before the night victim is announced." (`roles:232`)
- DE/EN-Vergleich: semantisch gleich NEIN. DE nennt den Zweck (Nachtopfer retten), aber keinen Zeitpunkt. EN nennt einen Zeitpunkt ("before the night victim is announced"), aber nicht, dass das Opfer gerettet wird. Beide nennen keine Einmaligkeit.
- Weitere Texte: `role-abilities.js:26` identisch mit DE. Dialogtitel über `getRoleName`, Knopf `martyrSacrifice` "Opfern"/"Sacrifice", Knopf "Nein" über `t("no")`. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Morgenauflösung (`onDayStart`), nicht als Nachtschritt; der Nachtschritt-Eintrag tier 9.0 ist funktionslos.
  2. Bedingung: lebende Märtyrerin, `MaertyUsed` false, mindestens ein Eintrag in `nightTargets` (Wolfsziele mit `flags.targeted`, Schicksalswolf-Extras, Rudelvater-Extra), nach Dorfwache- und Voodoo-Filter.
  3. Ziel: immer nur `nightTargets[0]`; weitere Nachtziele sind nicht wählbar und sterben regulär. Sofort-Tode der Nacht (Waldhexe, Hades, Blutpriester, Verdammniswächter) sind nicht in `nightTargets` und nicht rettbar.
  4. Wirkung: Märtyrerin stirbt sofort (`MARTYR_SACRIFICE`), Opfer verliert `targeted`, `MaertyUsed=true` (einmal pro Partie, global für alle Kopien).
  5. Selbst als Opfer: Ist `nightTargets[0]` die Märtyrerin selbst, stirbt sie mit Ursache `MARTYR_SACRIFICE` statt `NIGHT_KILL` (Randfall).
  6. Das angezeigte Opfer kann ohnehin überleben (Der Weise erster Angriff `night:359-364`, Schmiedewaffe `night:381-392`, Albtraum-Blockade `night:334`, Nekromant-Umlenkung), die Märtyrerin opfert sich dann umsonst.
  7. Blockaden (Schattenhund, Albtraum, Der-Weise-Debuff) werden nicht geprüft, weil `onOrderClick` nicht beteiligt ist.
  8. Zeitwächter: Dialog erscheint vor der Einfrier-Prüfung (siehe Bug B-MA-1).
  9. Nekromant-Schild (`core:127-133`) würde den Opfertod abfangen: Märtyrerin überlebt, Opfer trotzdem gerettet, `MaertyUsed=true`.
  10. Sichtbarkeit: Dialog nur für SL; Tod erscheint im Morgengrauen-Überblick (`night:350`, `afterCurses` → `showNightDeathSummary`) und im Log (`gh:2420`).
  11. Mehrere Kopien: `seats.find` nimmt die erste lebende; `MaertyUsed` ist global, also insgesamt nur ein Opfer pro Partie.
  12. Zufall: keiner.
  13. Rollenwechsel: `MaertyUsed` wird beim Erben nicht zurückgesetzt (`core:339-359`), neuer Träger ist verbraucht, wenn die Vorgängerin schon geopfert hat.
- React-Version: kein eigenes Verhalten; `ActionCenter.tsx:192` zeigt nur die handelnde Rolle als Kopfzeile.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 27: "verifiziert", `night:257-265`, "Einmal: am Morgen statt des ersten Opfers sterben", "Nachtzeile entfällt". Zeilen bestätigt. Status nur teilweise haltbar: EN-Text widerspricht DE, Zeitwächter-Reihenfolge fehlerhaft (ergänzt).
  - 04 C.1: "Märtyrerin | Reaktion vor Auflösung | verifiziert": bestätigt als Reihenfolge, ergänzt um Zeitwächter-Problem.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` L13 ("rettet alle Nachtopfer, `resolveDayKills([])`"): widerlegt für den heutigen Stand; `night:262` rettet nur das angezeigte Opfer (Kommentar im Code).
  - `SPECIAL-ROLE-FLOW-REPORT.md:14-27`: funktioniert, einmalig, Undo ok, fehlt im Recap. Recap-Lücke nicht erneut geprüft.
  - `ROLE-FLOW-REPORT.md:55`: "Keine Nachtreihen-Stufe" ist ungenau; es gibt eine Stufe 9.0 ohne Handler (widerlegt/präzisiert).
  - NIGHT-REPORT-abilities.md:48 "(?)": jetzt geklärt (Ja/Nein am Morgen).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Rettung vs. Zeitpunkt | rettet das Nachtopfer | opfert sich vor der Ansage, Rettung nicht genannt | Morgen, rettet nur `nightTargets[0]` | wie Legacy | 04 verifiziert | Ersatzopfer für ein Nachtopfer (Code) | Opfer ohne garantierte Rettung (EN wörtlich) | B macht die Rolle fast nutzlos | A: Abfangregel in Morgenauflösung | A, EN-Text angleichen | Ja |
| Welches Opfer bei mehreren | "das Nachtopfer" | "the night victim" | nur erstes Ziel | – | 04 "des ersten Opfers" | SL/Märtyrerin wählt eines | nur Rudelopfer | Rudelvater-/Schicksalswolf-Nächte | Auswahlprompt statt fester Index | Auswahl unter Todeskandidaten | Ja |
| Einmaligkeit | nicht genannt | nicht genannt | einmal pro Partie, global | – | 04 "Einmal" | einmal (Tod ist ohnehin endgültig) | – | gering | `ability_uses` pro Person statt global | pro Person | Nein (folgt aus Tod) |
| Blockaden | – | – | ignoriert Albtraum/Schattenhund/Der Weise | – | – | Reaktion ist blockierbar | nicht blockierbar | gering | Blockadeprüfung in Reaktion | PO | Ja |

- Bugs:
  - B-MA-1, echter Bug: `night:257-265` läuft vor `night:323-330` (Zeitwächter-Einfrieren). Tatsächlich: In einer eingefrorenen Nacht wird der Opferdialog angeboten und die Märtyrerin stirbt real, obwohl danach alle Nachtziele verworfen werden. Erwartet laut Zeitwächter-Text ("That night is treated as though it never happened", `roles:275`): kein Tod. Risiko mittel (unnötiger Tod, selten). Regressionstest: Zeitwächter friert Nacht ein, Wolf zielt auf B, Märtyrerin lebt → kein Opferdialog, niemand stirbt.
  - B-MA-2, unklare Regel: angebotenes Opfer kann ohnehin überleben (Der Weise, Schmiedewaffe, Albtraum-F3, Nekromant). Codepfad `night:257` vor `night:334-392`. Erwartet: Dialog nur für Personen, die tatsächlich sterben würden (Interpretation). Risiko niedrig. Test: Wolf zielt auf Der Weise (erster Angriff) → kein Opferangebot.
  - B-MA-3, technische Altlast: Nachtorder-Zeile tier 9.0 ohne Handler, zeigt "Keine Fähigkeit" (`roles:58`, `ab:100`). Risiko niedrig (SL-Verwirrung). Test: Nachtplan enthält keinen Märtyrerin-Schritt.
  - B-MA-4, unklare Regel: Märtyrerin als eigenes erstes Ziel stirbt mit falscher Ursache `MARTYR_SACRIFICE`. Risiko niedrig. Test: Wolf zielt auf Märtyrerin → kein Opferangebot, Ursache `NIGHT_KILL`.
- Legacy-Status: legacy-contradictory. Kernfunktion (einmaliges Ersatzopfer am Morgen) funktioniert; DE und EN widersprechen sich, Zeitwächter-Reihenfolge ist fehlerhaft, verfälscht die Kernfunktion aber nur im Randfall.
- Automationsvorschlag: assisted. Die App erkennt Todeskandidaten und bietet das Opfer an; die Entscheidung trifft die Märtyrerin (Ja/Nein am Tablet).
- Mechanikfamilie primär + sekundär: primär Schutz (Ersatzopfer); sekundär Einmalfähigkeit.
- Benötigte vorhandene Godot-Systeme: KillPipeline (Abfangstatus in `kill_event`), PendingPrompt (Ja/Nein + ggf. Opferwahl), Reaktionswarteschlange bzw. Morgenauflösung (`DAWN_RESOLUTION`), `ability_uses`, WinRules, StateCodec, Replay, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Ersatzopfer-Abfangregel in der Morgenauflösung (vor der Todesverarbeitung, nach Schutz/Zeitwächter). Keine weiteren.
- Abhängigkeiten: Werwolf/Rudel, Rudelvater (Extraopfer), Schicksalswolf, Dorfwache, Voodoo-Priester, Zeitwächter, Der Weise, Dorfschmied, Albtraumwolf, Nekromant (Schild), Schutzengel.
- Komplexität / Fehlerrisiko: M / mittel (Reihenfolge in der Morgenauflösung ist fehleranfällig).
- Offene Entscheidungen: (1) Gilt die Rettung (DE) und wird EN angepasst? (2) Bei mehreren Nachtopfern: wählt die Märtyrerin eines, oder nur das Rudelopfer? (3) Nur Rudelangriffe oder auch Sofort-Tode (Hexe, Hades, Verdammniswächter)? (4) Ist die Reaktion durch Albtraum/Schattenhund/Der-Weise-Debuff blockierbar? (5) Wird das Opfer nur angeboten, wenn der Tod nach Schutz tatsächlich eintritt?
- Relevante Testgruppen:
  - Normalfall: Wolf tötet B, Märtyrerin opfert sich → Märtyrerin tot (`MARTYR_SACRIFICE`), B lebt, Verbrauch gesetzt.
  - Ungültiges Ziel: Auswahl einer Person, die kein Todeskandidat ist → `invalid_target`.
  - Tote Person: Märtyrerin tot → kein Angebot.
  - Selbstwahl: Märtyrerin ist selbst Rudelopfer → kein Angebot, Ursache `NIGHT_KILL`.
  - Mehrere Kopien: zwei Märtyrerinnen → je eigene Verbrauchszählung (nach PO), Reihenfolge nach Personen-ID.
  - Wiederbelebung: geopferte Märtyrerin wiederbelebt → Verbrauch bleibt (PO bestätigen).
  - Rollenwechsel: Seelentauscher gibt verbrauchte Märtyrerin weiter → Verbrauch pro Person, neuer Träger unverbraucht (PO).
  - Save/Load: Speichern mit offenem Opfer-Prompt → Laden stellt Prompt wieder her.
  - Replay: Opferung reproduzierbar.
  - SL-Korrektur: SL macht Opferung rückgängig → beide Zustände korrekt, Protokoll.
  - Sichtbarkeit: Morgenansage zeigt Tod der Märtyrerin, nicht die Rettung (PO).
  - Schutz: Opfer vom Schutzengel geschützt → kein Angebot.
  - Todesreaktionen: Märtyrerin stirbt, Sensenträger nicht betroffen; Opfer ist Sensenträger → keine Reaktion.
  - Siegprüfung: Opferung führt zu Parität → Siegkandidat nach Morgenauflösung.
  - Beschädigter Spielstand: Verbrauchszähler > 1 → Laden abgelehnt.
  - Zusatz Zeitwächter: eingefrorene Nacht → kein Angebot (B-MA-1).
- Belegsicherheit: hoch (Code vollständig gelesen); Recap-Lücke aus Bericht nicht erneut geprüft.

### dorfwache
- DE-Name / EN-Name: Dorfwache / Village Guard (`roles:158`).
- Aliase/Altnamen: keine. Bild `Dorfwache.webp` / `Village_Guard` (`gh:824`, `roleCard.ts:46`).
- Legacy-ID: `"Dorfwache"` (`roles:1`).
- Fraktion: `dorf`.
- Akte: Akt IV (`akte.js:76`).
- Nachtpriorität: nicht in `ORDER_BASE`; zusätzlich im Passiv-Set `night:96`. Kein Nachtschritt.
- Quelltextstellen:
  - `chunk:162` `Werwolf`-Handler: ohne Seuchenwolf-Pierce wird bei Ziel `role==="Dorfwache"` (oder geschützt) `protectedCount` um 1 gesenkt und kein `targeted` gesetzt; bisherige Ziele werden dann auch nicht gelöscht.
  - `chunk:348` `Rachsüchtiger Wolf`: gleiche Behandlung (nur relevant, wenn die Dorfwache als Wolf gilt, z. B. mit `cursedWolfAura`).
  - `night:251` `continueResolveDay`: ohne Pierce werden Dorfwachen aus `nightTargets` entfernt, außer `meta.packfatherPierce`. Wirkt auch auf manuell gesetzte `targeted`-Chips und Schicksalswolf-Extras (`night:240-244`).
  - Nicht geschützt gegen: Giftwolf (`chunk:436-446`, Tod über `night:201-209` `GIFTWOLF_DELAY`), Rudelvater-Extra (`night:269-280`, `PACKFATHER_KILL`), Seuchenwolf-Pierce, Verdammniswächter, Waldhexe, Hades, Lynch.
- Text DE (wörtlich): "Stirbt nicht, wenn er nachts Ziel der Werwölfe wird." (`roles:84`)
- Text EN (wörtlich): "Does not die when targeted by werewolves at night." (`roles:233`)
- DE/EN-Vergleich: semantisch gleich JA.
- Weitere Texte: `role-abilities.js:15` identisch. Kein Totenkarten-Bezug (rg `cards.js`).
- Legacy-Codeverhalten:
  1. Passiv, dauerhaft, unbegrenzt oft.
  2. Rudelangriff auf die Dorfwache: Angriff wird bereits beim Anklicken verworfen, SL sieht kein Ziel; Morgenfilter als zweite Sicherung.
  3. Nebenwirkung: `protectedCount` wird dekrementiert, d. h. ein Schutzengel-Schild auf der Dorfwache wird verbraucht, obwohl die Dorfwache ohnehin immun ist.
  4. Ausnahmen: Seuchenwolf-Pierce (`SeuchenwolfNextAttackPierces`) und Rudelvater-Zweitangriff töten die Dorfwache. Giftwolf-Giftpranken töten sie zwei Tage später.
  5. Keine Ansage/Sichtbarkeit; der Angriff "verpufft" still.
  6. Mehrere Kopien: rollenbasiert, alle Kopien immun.
  7. Zufall: keiner.
  8. Rollenwechsel: Prüfung liest die aktuelle Rolle zur Morgenauflösung; tauscht der Seelentauscher (tier 8.0, nach den Wölfen) die Dorfwache-Rolle auf das Rudelopfer, überlebt dieses (Randfall, `night:251` liest `s.role`).
  9. Märtyrerin: Dorfwache wird vorher gefiltert, erhält kein Opferangebot.
- React-Version: kein eigenes Verhalten (nur Bildzuordnung).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 28: "verifiziert", `chunk:162,348`, `night:251`, "Immun gegen Wolfsangriffe (nicht gegen Pierce/Rudelvater)". Zeilen bestätigt; ergänzt: Giftwolf tötet sie, Schild-Verbrauch.
  - 04 C.1 "Schutzengel/Dorfwache (nur Wolfsangriff) ... widersprüchlich (Zeitpunkt)": bestätigt, der Verbrauch passiert beim Anklicken, nicht in der Auflösung.
  - `docs/godot-migration/03-godot-architecture.md:225` ordnet Dorfwache unter "Immunität" ein: passend.
  - NIGHT-REPORT-abilities.md:64 "passiv ✅": bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Giftwolf | "Ziel der Werwölfe" | "targeted by werewolves" | Giftwolf tötet (GIFTWOLF_DELAY) | – | 04 nicht erwähnt | Giftwolf ist Werwolf → immun | nur Rudelangriff zählt | Giftwolf-Ladung auf Dorfwache verschwendet oder tödlich | Filter `is_wolf_attack` muss Giftwolf einordnen | PO | Ja |
| Seuchenwolf/Rudelvater | keine Ausnahme genannt | keine Ausnahme | beide durchdringen | – | 04 "nicht gegen Pierce/Rudelvater" | Immunität ist "Schutz" → wird durchdrungen | Immunität ist Rolleneigenschaft → hält | selten, aber spielentscheidend | Kennzeichnung "ignoriert Immunität" | Code (Text der Dorfwache ergänzen) | Ja |

- Bugs:
  - B-DW-1, technische Altlast: `chunk:162` verbraucht `protectedCount` bei Dorfwache-Ziel. Tatsächlich: Schutzengel-Schild geht verloren. Erwartet: Immunität verbraucht keinen fremden Schutz. Risiko niedrig. Test: Schutzengel schützt Dorfwache, Rudel wählt Dorfwache → Schutz bleibt/Verbrauch nach PO, Dorfwache lebt.
  - B-DW-2, technische Altlast: bei Dorfwache-Wahl bleibt ein früher gesetztes `targeted` anderer Sitze bestehen (else-Zweig nicht erreicht, `chunk:162`). Risiko niedrig (Fehlklick-Folge). Test: Rudel wählt erst A, dann Dorfwache → Rudelwahl ist die Dorfwache, A stirbt nicht.
- Legacy-Status: legacy-verified. Rudelangriffe töten die Dorfwache nachvollziehbar nicht; Randfälle (Giftwolf, Pierce) sind Regelfragen, keine Fehlfunktion.
- Automationsvorschlag: automatic. Rein passive Immunität in der KillPipeline.
- Mechanikfamilie primär + sekundär: primär passive Dorfrolle; sekundär Schutz (Immunität gegen Wolfsangriff).
- Benötigte vorhandene Godot-Systeme: KillPipeline (Ursache `NIGHT_KILL`, Abfangstatus), Protections-Filter `is_wolf_attack` bzw. Ursachenfilter, InfoRecord nicht nötig, StateCodec, Replay.
- Benötigte NEUE Systeme: Immunitätsregel mit Ursachenfilter und "durchdringt Immunität"-Kennzeichen am Angriff (Seuchenwolf, Rudelvater). Protections deckt heute nur Schutzengel ab.
- Abhängigkeiten: Werwolf/Rudel, Seuchenwolf, Rudelvater, Giftwolf, Schicksalswolf, Rachsüchtiger Wolf, Schutzengel, Märtyrerin, Seelentauscher (Rollenwechsel in der Nacht).
- Komplexität / Fehlerrisiko: S / niedrig.
- Offene Entscheidungen: (1) Ist die Dorfwache gegen Giftwolf-Giftpranken immun? (2) Durchdringen Seuchenwolf-Pierce und Rudelvater-Zweitangriff die Immunität (Legacy: ja)? (3) Verbraucht ein Rudelangriff auf die Dorfwache ihren Schutzengel-Schild? (4) Erfährt jemand, dass der Angriff abgewehrt wurde?
- Relevante Testgruppen:
  - Normalfall: Rudel wählt Dorfwache → Morgen: niemand stirbt.
  - Ungültiges Ziel: nicht relevant, weil die Dorfwache kein Ziel wählt.
  - Tote Person: tote Dorfwache → keine Wirkung (nicht angreifbar).
  - Selbstwahl: nicht relevant, weil passiv.
  - Mehrere Kopien: zwei Dorfwachen, Rudel wählt eine → überlebt.
  - Wiederbelebung: wiederbelebte Dorfwache (Frankenstein/Kutscher) → wieder immun.
  - Rollenwechsel: Seelentauscher tauscht Dorfwache auf das Rudelopfer nach dem Rudelschritt → Ergebnis nach PO (Legacy: Opfer überlebt).
  - Save/Load: nicht relevant, weil kein eigener Zustand.
  - Replay: Rudelangriff auf Dorfwache reproduzierbar ohne Tod.
  - SL-Korrektur: SL erzwingt Tod per GmCorrection → stirbt mit `GM_CORRECTION`.
  - Sichtbarkeit: Abwehr nur im SL-Protokoll.
  - Schutz: Schutzengel + Dorfwache → Verbrauch nach PO.
  - Todesreaktionen: nicht relevant, weil keine eigene Reaktion.
  - Siegprüfung: Dorfwache überlebt Angriff → Parität unverändert.
  - Beschädigter Spielstand: nicht relevant, weil kein eigener Zustand.
  - Zusatz: Seuchenwolf-Pierce aktiv → Dorfwache stirbt; Rudelvater-Extra auf Dorfwache → stirbt; Giftwolf → stirbt nach 2 Tagen (Legacy).
- Belegsicherheit: hoch.

### kutscher
- DE-Name / EN-Name: Kutscher / Coachman (`roles:167`).
- Aliase/Altnamen: keine in `migrateLegacyRoleIds`. i18n `kutscherTitle` "Kutscher"/"Coachman" (`i18n.js:313,637`). Nicht zu verwechseln mit "Wahnsinniger Kutscher" (eigene Rolle). Bild `Kutscher.webp` / `Coachman` (`gh:828`, `roleCard.ts:55`). State `once.KutscherUsed`.
- Legacy-ID: `"Kutscher"` (`roles:1`).
- Fraktion: `dorf`. Rollen-Tags `["revive","dead-interaction","creates-wolf"]` (`roles:289`).
- Akte: Akt II (`akte.js:35`).
- Nachtpriorität: tier 3.8, kein `once` (`roles:31`). Bedingung `night:83`: Zeile nur bei `deadCount >= 10` und `!once.KutscherUsed`; plus Kutscher lebt (`night:92`).
- Quelltextstellen:
  - `chunk:833-864` `Kutscher`: prüft `dead.length<10`; Ja/Nein "Nachbardorf um Hilfe bitten?"; Ja: 3 zufällige Tote (`Math.random`, `chunk:840-843`), `wolfIndex` zufällig (`chunk:844`), Rollenpool `ALL_ROLES` ohne Wolfsrollen und ohne bereits vergebene Rollen (`chunk:846`), Flags/Meta komplett neu (`chunk:849-850`), einer wird `Werwolf` mit `flags.werewolf=true` oder bei Wächter am Tor `Dorfbewohner` (`chunk:851-854`), die zwei anderen erhalten eine zufällige Rolle aus dem Pool (`chunk:855-857`); `KutscherUsed=true`.
  - `night:29-40` `rebuildOrder`: Totenkarten-Hinweis "Tote halten die Augen geschlossen", solange eine lebende Rolle mit Tag `revive` existiert (auch vor 10 Toten).
  - `core:358` `resetOnceForInheritedRole`: löscht `KutscherUsed` beim Erben der Rolle.
  - `cards.js:62,326,348,450` (`segen_08` Zweites Leben, `wende_04` Wiedergeburt, `wende_07` Befreiung, `loki_10` Phoenix) und `cards.js:573-622`: diese Totenkarten sind nur aktiv, wenn eine lebende Rolle mit Tag `revive`/`role-return`/`death-trigger-transform` existiert; `help:133,217` Hinweistext nennt Kutscher.
  - `gh:522,558`, `state:64` Defaults/Reset.
- Text DE (wörtlich): "Wenn mindestens 10 Spieler tot sind, kann er drei Tote wiederbeleben (U+2014) einer davon wird Wolf." (`roles:93`)
- Text EN (wörtlich): "With 10+ dead: revives 3 dead players (U+2014) one of them becomes a wolf." (`roles:242`)
- DE/EN-Vergleich: semantisch gleich NEIN (geringfügig). DE "kann" = optional; EN "revives" klingt verpflichtend/automatisch. Schwelle (10), Anzahl (3) und Wolf (1) gleich. Beide sagen nichts über Einmaligkeit, Auswahl der Toten oder neue Rollen.
- Weitere Texte: `role-abilities.js:23` identisch. `kutscherRevived` "3 wieder im Spiel (1 davon Wolf)." wird auch angezeigt, wenn Wächter am Tor den Wolf blockiert hat (dann 0 Wölfe). Totenkarten-Bezug siehe oben.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt tier 3.8, sobald mindestens 10 Tote (alle Fraktionen) und Kutscher lebt.
  2. Optional (Nein), einmal pro Partie (global `KutscherUsed`, alle Kopien teilen sich den Verbrauch).
  3. Auswahl der Toten: zufällig durch den Code, weder Kutscher noch SL wählen.
  4. Rollen: Die Wiederbelebten behalten NICHT ihre Rolle. Einer wird Werwolf, zwei erhalten zufällige Nicht-Wolf-Rollen, die noch keinem Sitz gehören; der Pool enthält auch Solo-Rollen (z. B. Hades, Nekromant, Pestbringerin) und Akt-fremde Rollen, weil `ALL_ROLES` statt Akt-Rollen genutzt wird.
  5. Zustand: alle Flags/Meta zurückgesetzt (Liebe, Gift, Marker, `deathProcessed`, Sensenträger-Merker). Totenkarten-Eintrag des Sitzes bleibt bestehen (`state.once.totenkarten[id]`).
  6. Todesursache: keine; Wiederbelebung erzeugt kein Log (kein `gameLog.add`).
  7. Sichtbarkeit: `center(...)` für den SL; keine Information, wer der Wolf ist, außer im Sitz-Zustand.
  8. Wächter am Tor: der Wolfsplatz wird Dorfbewohner.
  9. `resetOnceForInheritedRole` für die neuen Rollen wird nicht aufgerufen; Siegprüfung nur indirekt über `save()` → `checkTeamWin` (`state:118`).
  10. Zufall: `Math.random` in `chunk:842,844,855`.
  11. Rollenwechsel: Erbt jemand die Kutscher-Rolle (Seelentauscher, Lehrling), wird `KutscherUsed` gelöscht → Fähigkeit erneut nutzbar (`core:358`).
- React-Version: kein eigenes Verhalten (nur Bildzuordnung).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 37: "verifiziert", `chunk:833-864`, `night:83`, "3 zufällige Tote zurück, einer wird Werwolf, andere erhalten freie Nicht-Wolf-Rollen (Seed)". Zeilen und Verhalten bestätigt. Status "verifiziert" widerlegt: Text sagt nichts von neuen Rollen oder Zufallsauswahl; das ist ein Text/Code-Unterschied.
  - 04 B-5: Bedingung "Kutscher ≥ 10 Tote" bestätigt (`night:83`).
  - 04 Zeile 61 Wächter am Tor: Kutscher-Pfad bestätigt (`chunk:847,852`).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` L8 (Unikat-Rollen dupliziert, Inline-Wolfsliste, `/wolf/i`): für heutigen Stand widerlegt/behoben (`chunk:845-846` Unikat-Filter, `WOLF_ROLES_SET`).
  - NIGHT-REPORT-abilities.md:43 "3 Ziele (?)": präzisiert: keine Ziele, Zufall.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Rollen der Wiederbelebten | "drei Tote wiederbeleben" | "revives 3 dead players" | neue Zufallsrollen, inkl. Solo | – | 04 verifiziert | echte Wiederbelebung, alte Rolle bleibt (außer Wolf) | "Nachbardorf" bringt neue Personen mit neuen Rollen (Code, Dialogtext) | neue Solo-Rollen mitten im Spiel können Sieglage kippen | Rollenpool, Fraktionszuordnung, Siegbedingungen neuer Solos | PO; wenn Code: Pool auf Dorfrollen des Akts begrenzen | Ja |
| Wer wählt die Toten | "kann er ... wiederbeleben" | "revives" | Zufall | – | 04 "zufällige" | Kutscher/SL wählt | Zufall (SeededRng) | Wahl macht Rolle stärker | Prompt vs. RNG | PO | Ja |
| Optional | "kann" | "revives" | optional | – | – | optional | automatisch bei 10 Toten | gering | Ja/Nein-Prompt | optional (DE, Code) | Nein |
| Einmaligkeit | nicht genannt | nicht genannt | einmal, global; nach Rollenerbe erneut | – | 04 "einmal" | einmal pro Partie | einmal pro Person | Rollenerbe verdoppelt Effekt | `ability_uses` pro Person | einmal pro Person, Text ergänzen | Ja |

- Bugs:
  - B-KU-1, unklare Regel: Rollenpool `ALL_ROLES` (`chunk:846`) enthält Solo- und Akt-fremde Rollen. Tatsächlich: Wiederbelebter kann z. B. Hades oder Pestbringerin werden. Erwartet laut Text: nicht spezifiziert. Risiko mittel (Solo-Sieg durch Zufall). Test: Seed fest, Akt II → neue Rollen nur aus erlaubtem Pool.
  - B-KU-2, technische Altlast: Meldung `kutscherRevived` "1 davon Wolf" auch bei Wächter-am-Tor-Blockade (`chunk:860`). Risiko niedrig. Test: Wächter am Tor lebt → Meldung ohne Wolf.
  - B-KU-3, unklare Regel: `KutscherUsed` wird beim Rollenerbe gelöscht (`core:358`), bei Blutpriester/Seelentauscher dagegen faktisch nicht (siehe dort). Uneinheitlich. Risiko niedrig. Test: Seelentauscher gibt verbrauchten Kutscher weiter → Verhalten nach PO.
  - B-KU-4, technische Altlast: Totenkarten-Eintrag und `FirstThreeDeadIds`/Prophet-Ziele bleiben nach Wiederbelebung unverändert; Wiederbelebung ohne Log. Risiko niedrig. Test: Wiederbelebung erzeugt Ereignis `REVIVE` mit Quelle Kutscher.
- Legacy-Status: legacy-contradictory. Code ist funktional (keine Fehlfunktion der Kernmechanik gefunden), weicht aber in Rollenvergabe und Auswahlverfahren vom Text ab; 04 "verifiziert" ist zu optimistisch.
- Automationsvorschlag: assisted. Bedingung und Verbrauch automatisch; Auswahl/Rollen hängen an PO-Entscheidung, Ergebnis braucht SL-Bestätigung wegen großer Wirkung.
- Mechanikfamilie primär + sekundär: primär Wiederbelebung; sekundär Rollenwechsel (neue Rollen, einer wird Wolf) und Zufallsmechanik.
- Benötigte vorhandene Godot-Systeme: StepQueue (bedingter Schritt), PendingPrompt, SeededRng, RoleTransition (Rollenzuweisung mit Schnappschuss, Wächter-am-Tor-Umleitung), WinRules/WinCandidate, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Wiederbelebungsmodell (Tod aufheben, Status/Bindungen zurücksetzen, Totenkarten-Status, Ereignis `REVIVE`), Rollenpool-Regel (Akt/Fraktion) für neu vergebene Rollen, Totenkarten-Effektmodell für die revive-gebundenen Karten.
- Abhängigkeiten: Wächter am Tor, Werwolf/Rudel, alle Rollen im Pool, Totenkarten (4 revive-Karten), Prophet des Untergangs (Ziele), Schicksalswolf (`FirstThreeDeadIds`), Seelentauscher/Lehrling (Rollenerbe).
- Komplexität / Fehlerrisiko: L / hoch (Wiederbelebung + Rollenvergabe + Wolfserzeugung + Zufall).
- Offene Entscheidungen: (1) Behalten Wiederbelebte ihre Rolle, oder kommen "neue Personen aus dem Nachbardorf" mit neuen Rollen? (2) Wer wählt die drei Toten: Zufall, Kutscher oder SL? (3) Aus welchem Pool kommen neue Rollen (nur Dorf, nur Akt)? (4) Wer wird Wolf: Zufall oder Wahl? (5) Einmal pro Partie oder pro Person, und setzt Rollenerbe den Verbrauch zurück? (6) Was passiert mit Totenkarten und Bindungen der Wiederbelebten? (7) Zählt die Schwelle 10 alle Toten (Legacy: ja)?
- Relevante Testgruppen:
  - Normalfall: 10 Tote, Kutscher lebt, Ja → 3 leben wieder, genau einer zählt als Wolf, Verbrauch gesetzt.
  - Ungültiges Ziel: 9 Tote → kein Schritt; manipulierter Befehl → `step_not_available`.
  - Tote Person: Kutscher tot → kein Schritt.
  - Selbstwahl: nicht relevant, weil der Kutscher lebt und nicht wiederbelebt werden kann.
  - Mehrere Kopien: zwei Kutscher → Verbrauch nach PO (Legacy global).
  - Wiederbelebung: wiederbelebte Person stirbt erneut → neue Todesursache, Totenkarte nach Regel.
  - Rollenwechsel: Wächter am Tor lebt → Wolfsplatz wird Dorfbewohner.
  - Save/Load: gleicher Seed → gleiche Auswahl nach Laden.
  - Replay: Zufallsauswahl deterministisch aus SeededRng.
  - SL-Korrektur: SL ändert zugewiesene Rolle → Protokoll.
  - Sichtbarkeit: Wolfsidentität nur SL/Wölfe, Wiederbelebung öffentlich.
  - Schutz: nicht relevant, weil kein Tod verursacht wird.
  - Todesreaktionen: wiederbelebter Sensenträger (falls Rolle behalten) → Reaktion bei erneutem Tod nach Regel.
  - Siegprüfung: Wiederbelebung verändert Parität → Kandidaten neu berechnet; neue Solo-Rolle → Siegregeln aktiv.
  - Beschädigter Spielstand: Wiederbelebter ohne Rolle → Laden abgelehnt.
- Belegsicherheit: hoch für Code; mittel für Totenkarten-Wirkung (Karteninhalte nicht im Detail geprüft).

### seelentauscher
- DE-Name / EN-Name: Seelentauscher / Soul Swapper (`roles:168`). Abweichend in i18n-Dialogtexten "Soul Shifter" (`i18n.js:544,623`).
- Aliase/Altnamen: keine in `migrateLegacyRoleIds`. i18n-Schlüssel `soulShifter*`. Bild `Seelentauscher.webp` / `Soul_Swapper` (`gh:828`, `roleCard.ts:56`). State `once.Used.role_Seelentauscher` (über `markOnceUsed`), zusätzlich toter Schlüssel `once.SeelentauscherUsed` (`gh:523`, `core:355`).
- Legacy-ID: `"Seelentauscher"` (`roles:1`).
- Fraktion: `dorf`.
- Akte: Akt II (`akte.js:34`).
- Nachtpriorität: tier 8.0, `once:true` (`roles:53`). `night:60`: Zeile verschwindet nach `isOnceUsed`. Keine weitere Bedingung.
- Quelltextstellen:
  - `chunk:737-796` `Seelentauscher`: `isOnceUsed`-Prüfung; Ja/Nein; `startMulti` 2 Sitze mit beliebiger Rolle (`x=>!!x.role`, tot oder lebend); Wolfserkennung `aGetsWolf`/`bGetsWolf` nur für Lebende (`chunk:761-762`); Wächter-am-Tor-Zweige (`chunk:764-776`); Standardtausch (`chunk:779-783`); `resetOnceForInheritedRole` für beide neuen Rollen (`chunk:788-789`); `markOnceUsed` (`chunk:790`).
  - `ui:340` `startMulti`: verhindert doppelte Wahl desselben Sitzes.
  - `core:8-19` `isWolf`: berücksichtigt `flags.werewolf` und `meta.cursedWolfAura` zusätzlich zur Rolle.
  - `core:339-359` `resetOnceForInheritedRole`.
  - `night:3-5` `isOnceUsed`/`markOnceUsed`.
- Text DE (wörtlich): "Tauscht einmalig die Rollen zweier Spieler unabhängig davon, ob lebendig oder tot." (`roles:94`)
- Text EN (wörtlich): "Once swaps the roles of two players, regardless of whether they are alive or dead." (`roles:243`)
- DE/EN-Vergleich: semantisch gleich JA.
- Weitere Texte: `role-abilities.js:32` identisch. Name im Dialog EN "Soul Shifter" statt "Soul Swapper" (technische Altlast). Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt tier 8.0 (nach Rudel, Henker; vor Blutpriester), optional, einmal pro Partie (global pro Rollenname).
  2. Ziele: genau 2 verschiedene Sitze mit Rolle, lebend oder tot, Selbstwahl erlaubt.
  3. Wirkung: nur `role` wird getauscht; alle Flags/Meta bleiben am Sitz (Liebe, Marker, `cursedWolfAura`, `cerbHeads`, Gift).
  4. `flags.werewolf` wird nach dem Tausch per `isWolf(sitz)` neu gesetzt; `isWolf` liest dabei das alte `flags.werewolf` desselben Sitzes → ein ehemaliger Wolfssitz bleibt Wolf (Bug F4, bestätigt).
  5. Tote, die eine Wolfsrolle erhalten, werden nicht auf Wächter am Tor geprüft (`!a.flags.dead`), erhalten die Wolfsrolle.
  6. Wächter am Tor: ein Lebender, der neu Wolf würde, wird Dorfbewohner; die Wolfsrolle geht dabei verloren.
  7. Einmaligkeit nach Rollenweitergabe: `resetOnceForInheritedRole("Seelentauscher")` löscht nur `once.SeelentauscherUsed`, `markOnceUsed` schreibt aber `once.Used.role_Seelentauscher` → wirkungslos; der neue Seelentauscher-Träger kann nicht mehr tauschen. Gleiches für geerbte Blutpriester-Rolle.
  8. Bezüge anderer Rollen bleiben am Sitz, nicht an der Rolle: `MogliVorbildId`, `LehrlingMentorId`, `ProphetTargets`, Rotkäppchen-`rkLink`, Parasit-Wirt.
  9. Sichtbarkeit: keine Meldung an die Betroffenen, kein Log.
  10. Mehrere Kopien: ein Verbrauch für alle Kopien (Rollenname-Schlüssel).
  11. Zufall: keiner.
  12. Siegprüfung: nur über `save()` → `checkTeamWin`.
  13. Apfel-Buff (Rotkäppchen): zweiter Lauf scheitert an `isOnceUsed` (`ab:117-118`), also kein Doppeltausch.
- React-Version: kein eigenes Verhalten (nur Bildzuordnung).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 38: "widersprüchlich (Bug F4)", `chunk:737-796`, "Wolfsstatus folgt der neuen Rolle, nicht dem alten Flag". Bestätigt; Zeilen stimmen.
  - 01 F4 `chunk:782-783` "kann zwei Wölfe erzeugen (veraltetes flags.werewolf)": bestätigt. Beleg: Setup setzt `flags.werewolf=true` für Wolfsrollen (`setup.html:1148`, `gh:449,645,1162`); nach Tausch Werwolf↔Dorfbewohner ist `a.flags.werewolf` weiterhin true (`chunk:782`), `b` wird Werwolf. Ergänzt: gleicher Fehler auch im Wächter-am-Tor-Zweig `chunk:778` (ehemaliger Wolfssitz bleibt Wolf, obwohl er Dorfbewohner-Rolle erhält).
  - 04 Zeile 61 (Wächter am Tor inkl. Seelentauscher): bestätigt.
  - 07 Q1 Teil 2: "Seelentauscher zwei Wölfe" als Bug ohne Rückfrage.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Wolfsstatus nach Tausch | Rollen werden getauscht | same | alter Wolfssitz bleibt Wolf (F4) | – | 04/07: Bug | Status folgt Rolle | – | Wolfsverdopplung | RoleTransition leitet Fraktion aus Rolle ab | A (Bugfix) | Nein |
| Was wandert mit | nur "Rollen" | "roles" | nur `role`, Zustände bleiben am Sitz | – | – | Rolle inkl. Rollenzustand (Verbrauch, Bindungen) wandert | nur Rollenname, Zustand bleibt | Tausch von verbrauchten Rollen | RoleTransition-Schnappschuss definiert | PO | Ja |
| Toter erhält Wolfsrolle | "lebendig oder tot" | same | Toter wird Wolf ohne Wächter-Prüfung | – | – | erlaubt | Wächter-Prüfung auch für Tote | gering (tot), relevant bei Wiederbelebung | Wächter-Regel auf alle Rollenwechsel | Wächter-Prüfung auch bei Wiederbelebung | Ja |
| Information der Betroffenen | nicht genannt | nicht genannt | keine | – | – | Betroffene erfahren neue Rolle | geheim | hoch (Spieler kennt eigene Rolle nicht) | InfoRecord an Betroffene | A | Ja |

- Bugs:
  - B-ST-1, echter Bug (F4): `chunk:778,782-783`. Tatsächlich: Tausch Werwolf↔Dorfbewohner ergibt zwei Wölfe (`isWolf` liest veraltetes `flags.werewolf`). Erwartet: genau ein Wolf. Risiko kritisch (Siegparität). Test S-ROLE-38: Werwolf A ↔ Dorfbewohner B → A zählt nicht als Wolf, B zählt als Wolf.
  - B-ST-2, technische Altlast: `resetOnceForInheritedRole` für "Seelentauscher"/"Blutpriester" löscht `…Used`-Schlüssel, die `isOnceUsed` nicht liest (`core:355-356` vs. `night:4-5`). Folge: Verbrauch geerbter Einmalrollen bleibt bestehen, anders als beim Kutscher (`core:358`). Risiko mittel (uneinheitliche Einmaligkeit). Test: Seelentauscher gibt verbrauchten Blutpriester weiter → Verhalten nach PO (pro Person).
  - B-ST-3, technische Altlast: Dialogname "Soul Shifter" ≠ Rollenname "Soul Swapper" (`i18n.js:544,623` vs. `roles:168`). Risiko niedrig. Test: EN-Namenskonsistenz.
- Legacy-Status: legacy-broken. Der belegte Fehler F4 verfälscht die Kernfunktion (Rollentausch mit Wolfsrolle erzeugt einen zusätzlichen Wolf).
- Automationsvorschlag: assisted. Tausch automatisch über RoleTransition; SL bestätigt, Betroffene werden informiert.
- Mechanikfamilie primär + sekundär: primär Rollenwechsel; sekundär Einmalfähigkeit und Fraktionswechsel.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (Mehrfachwahl 2, abbrechbar), RoleTransition (Schnappschuss, Wächter-Umleitung), InfoRecord (Mitteilung an Betroffene), WinRules, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit, WolfChildBond/ApprenticeBond (Bindungen bei Rollenwechsel).
- Benötigte NEUE Systeme: Regel "Rollenzustand wandert mit" (Verbrauchszähler/Bindungen je Rolle vs. je Person) als Teil von RoleTransition; kein eigenes neues System, sofern RoleTransition zwei gleichzeitige Wechsel atomar kann (nicht verifiziert).
- Abhängigkeiten: alle Rollen (tauschbar), insbesondere Wolfsrollen, Wächter am Tor, Wolfskind/Lehrling (Bindungen), Loki/Rotkäppchen/Parasit (Sitz-Bindungen), Dorfwache/Märtyrerin (Rollenprüfung am Morgen), Kutscher/Blutpriester (Einmaligkeit).
- Komplexität / Fehlerrisiko: L / kritisch (Fraktions- und Siegauswirkung, viele Querbezüge).
- Offene Entscheidungen: (1) Wandert der Rollenzustand (Verbrauch, Vorbild, Mentor, Schild) mit der Rolle oder bleibt er an der Person? (2) Erfahren die Getauschten ihre neue Rolle, und wann? (3) Darf der Seelentauscher sich selbst tauschen? (4) Gilt Wächter am Tor auch für tote Empfänger einer Wolfsrolle? (5) Bleiben Liebes-/Bindungsmarker am Sitz?
- Relevante Testgruppen:
  - Normalfall: Orakel ↔ Dorfbewohner → Rollen getauscht, Fraktion unverändert.
  - Ungültiges Ziel: zweimal dieselbe Person → `invalid_target`; Person ohne Rolle → abgelehnt.
  - Tote Person: toter Werwolf ↔ lebender Dorfbewohner → Lebender wird Wolf, Toter Dorfbewohner.
  - Selbstwahl: Seelentauscher ↔ Orakel → nach PO; neuer Seelentauscher-Träger hat Verbrauch nach PO.
  - Mehrere Kopien: zwei Seelentauscher → Verbrauch je Person (PO).
  - Wiederbelebung: toter Empfänger einer Wolfsrolle wird wiederbelebt → Wächter-Prüfung.
  - Rollenwechsel: Werwolf ↔ Dorfbewohner → genau ein Wolf (F4).
  - Save/Load: Speichern nach Tausch → Rollen und Fraktionen nach Laden gleich.
  - Replay: Tausch reproduzierbar, gleicher Hash.
  - SL-Korrektur: SL macht Tausch rückgängig → Schnappschuss wiederhergestellt.
  - Sichtbarkeit: Tausch nicht öffentlich, Info an Betroffene (PO).
  - Schutz: nicht relevant, weil kein Tod (außer Dorfwache-Tausch nach Rudelwahl, siehe Dorfwache).
  - Todesreaktionen: getauschter Sensenträger stirbt später → Reaktion gehört neuem Träger.
  - Siegprüfung: Tausch letzter Wolfsrolle auf Toten → Dorf-Siegkandidat.
  - Beschädigter Spielstand: Fraktion passt nicht zur Rolle → Laden abgelehnt.
- Belegsicherheit: hoch für F4 und Einmaligkeitslogik (Code vollständig verfolgt); Querbezüge zu Wolfskind/Lehrling nur gelesen, nicht durchgespielt.

### blutpriester
- DE-Name / EN-Name: Blutpriester / Blood Priest (`roles:169`).
- Aliase/Altnamen: keine in `migrateLegacyRoleIds`. Bild `Blutpriester.webp` / `Blood_Priest` (`gh:828`, `roleCard.ts:57`). State `once.Used.role_Blutpriester`; toter Schlüssel `once.BlutpriesterUsed` (`gh:523`, `core:356`).
- Legacy-ID: `"Blutpriester"` (`roles:1`).
- Fraktion: `dorf`.
- Akte: Akt II (`akte.js:34`).
- Nachtpriorität: tier 8.2, `once:true` (`roles:54`); `night:60` blendet nach Verbrauch aus. Keine weitere Bedingung.
- Quelltextstellen:
  - `chunk:703` `"Blutpriester"`: `isOnceUsed`; `pick` lebende Person (Selbstwahl erlaubt); `applyKill(s,"BLOODPRIEST_SACRIFICE")`, `markOnceUsed`, `save`, `draw`, `rebuildOrder`, `postDeathHooks`; danach Overlay "SL: Wie viele Wölfe aufdecken?" mit 0/1/2/3; Wahl → lebende Wölfe (`isWolf`) per `sort(()=>Math.random()-0.5)` gemischt, erste k angezeigt über `center(..., true)`.
  - `core:361-416` `postDeathHooks` → `showDeathPopup` (`ui:479-482`) öffnet dasselbe `#overlay`, das der Blutpriester sofort überschreibt.
  - `ui:413`, `gh:2425`, `i18n.js:142,466` (Log), `i18n.js:185,509` `logBloodpriestResult`, `i18n.js:778,879` Laufzeitübersetzung "Wie viele Wölfe aufdecken?".
- Text DE (wörtlich): "Opfert jemanden und deckt 0–3 Werwölfe auf." (`roles:95`)
- Text EN (wörtlich): "Sacrifices someone and reveals 0–3 werewolves." (`roles:244`)
- DE/EN-Vergleich: semantisch gleich JA.
- Weitere Texte: `role-abilities.js:5` identisch. Prompt "Blutpriester  (U+2014) opfere 1" hart kodiert, "opfere 1" übersetzt (`i18n.js:832`). Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt tier 8.2, optional nur durch Nichtklicken (kein Nein-Knopf; Pick-Abbruch möglich), einmal pro Partie (global pro Rollenname).
  2. Ziel: eine lebende Person, Selbstwahl erlaubt, jede Fraktion.
  3. Wirkung: sofortiger Tod `BLOODPRIEST_SACRIFICE` in der Nacht; Schutzengel wirkt nicht (applyKill prüft `protected` nicht); Rudelvater-Erstrettung, Nekromant-Schild, Hades-Barriere, Kartenschlucker-Schild, Parasit und Schattenwanderer greifen (`core:106-143`); Verbrauch auch, wenn der Tod abgefangen wird.
  4. Anzahl aufgedeckter Wölfe: frei vom SL gewählt (0 bis 3), unabhängig vom Opfer; welche Wölfe: Zufall (`Math.random`, verzerrtes Sort-Mischen). Zählt `cursedWolfAura`-Sitze als Wölfe, Doppelspion nicht.
  5. Ist das Opfer ein Wolf, ist es danach tot und nicht mehr im Pool.
  6. Sichtbarkeit: Ergebnis per `center` für den SL; ob öffentlich angesagt wird, regelt der Code nicht. Ergebnis wird nicht gespeichert und nicht geloggt (nur der Tod).
  7. Mehrere Kopien: ein Verbrauch für alle.
  8. Rollenwechsel: geerbte Rolle nach Verbrauch nicht erneut nutzbar (siehe seelentauscher B-ST-2).
  9. Siegprüfung: `applyKill` → `checkWinConditions`; `save` → `checkTeamWin`.
- React-Version: kein eigenes Verhalten (nur Bildzuordnung).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 39: "verifiziert", `chunk:703`, "Opfert einen Spieler (BLOODPRIEST_SACRIFICE), SL enthüllt 0–3 Wölfe (Code: zufällig)". Bestätigt; präzisiert: Anzahl wählt SL, Auswahl zufällig.
  - 04 B-10 (Sofort-Tode, inkl. Blutpriester): bestätigt.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` H (`chunk:700`, hart kodiert): bestätigt (heute `chunk:703`).
  - NIGHT-REPORT-abilities.md:51 "1 Ziel → Info, 🟡/❌": bestätigt.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Anzahl 0–3 | "0–3 Werwölfe" | "0–3 werewolves" | SL wählt frei | – | 04 "SL enthüllt" | SL entscheidet | Anzahl aus Regel (z. B. Zufall oder Rolle des Opfers) | SL-Willkür vs. Planbarkeit | Prompt vs. RNG | PO; Legacy (SL wählt) beibehalten ist einfach | Ja |
| Wer sieht das Ergebnis | "deckt ... auf" | "reveals" | nur SL-Anzeige | – | – | öffentlich (aufdecken) | nur Blutpriester | groß (öffentliche Wolfsnennung) | Ereignis-Sichtbarkeit public vs. actor | PO | Ja |
| Opfer: Pflicht? | "Opfert jemanden" | "Sacrifices someone" | Pick optional | – | – | Opfer Voraussetzung für Aufdeckung (Code) | – | – | – | Code | Nein |

- Bugs:
  - B-BP-1, technische Altlast: `chunk:703` ruft `postDeathHooks()` vor dem Öffnen des eigenen Overlays; `showDeathPopup` (`ui:479-482`) wird dadurch sofort überschrieben (Todes-Popup verschwindet). Risiko niedrig (SL verliert Hinweis). Test: Opfer-Tod erscheint im Protokoll und in der Morgenübersicht.
  - B-BP-2, unklare Regel: Verbrauch auch bei abgefangenem Tod (Rudelvater, Schilde). Risiko niedrig. Test: Opfer ist Rudelvater (unverbraucht) → überlebt; Verbrauch nach PO.
  - B-BP-3, technische Altlast: verzerrtes Mischen `sort(()=>Math.random()-0.5)`; kein Seed. Risiko niedrig. Test: SeededRng-Auswahl reproduzierbar.
- Legacy-Status: legacy-verified. Opfer und Aufdeckung von 0 bis 3 Wölfen sind nachvollziehbar umgesetzt; offene Punkte sind Regelpräzisierungen.
- Automationsvorschlag: assisted. Tod automatisch; Anzahl durch SL, Auswahl per SeededRng, Ergebnis als InfoRecord.
- Mechanikfamilie primär + sekundär: primär Informationsrolle; sekundär Tötung und Einmalfähigkeit (plus Zufallsmechanik).
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (Ziel, dann Anzahl), KillPipeline (Sofort-Tod in der Nacht), SeededRng, InfoRecord (Wahrheit/ermittelt/gezeigt), Ereignis-Sichtbarkeit, `ability_uses`, WinRules, StateCodec, Replay.
- Benötigte NEUE Systeme: keine nachweislich (Sofort-Tod in der Nacht und Reaktionszeitpunkt sind Teil von KillPipeline/Reaktionswarteschlange, 04 B-10).
- Abhängigkeiten: Rudelvater, Nekromant, Hades, Kartenschlucker, Parasit, Schattenwanderer (Todesabfang), Dämonischer Wolf (`cursedWolfAura` zählt als Wolf), Doppelspion (nicht Wolf), Sensenträger (Reaktion auf Opfer), Seelentauscher (Einmaligkeit).
- Komplexität / Fehlerrisiko: M / mittel.
- Offene Entscheidungen: (1) Wer bestimmt die Anzahl 0 bis 3 (SL frei, Zufall, Regel)? (2) Ist die Aufdeckung öffentlich oder nur für den Blutpriester? (3) Zählen verfluchte Dorfbewohner (erscheinen als Wolf) und Trugbilderwolf-Erscheinung? (4) Verbraucht ein abgefangener Tod die Fähigkeit? (5) Darf er sich selbst opfern?
- Relevante Testgruppen:
  - Normalfall: Blutpriester opfert Dorfbewohner B, SL wählt 2 → B tot, zwei lebende Wölfe als InfoRecord.
  - Ungültiges Ziel: toter Spieler → `invalid_target`.
  - Tote Person: Blutpriester tot → kein Schritt.
  - Selbstwahl: Blutpriester opfert sich → nach PO (Legacy erlaubt, Aufdeckung erfolgt trotzdem).
  - Mehrere Kopien: zwei Blutpriester → Verbrauch je Person (PO).
  - Wiederbelebung: Opfer wiederbelebt → Verbrauch bleibt.
  - Rollenwechsel: Seelentauscher gibt unverbrauchten Blutpriester weiter → neuer Träger kann nutzen.
  - Save/Load: Speichern zwischen Opfer und Anzahlwahl → offener Prompt nach Laden.
  - Replay: gleiche Seeds → gleiche aufgedeckte Wölfe.
  - SL-Korrektur: SL korrigiert gezeigte Namen → nur `shown` ändert sich, Wahrheit bleibt.
  - Sichtbarkeit: Ergebnis gemäß PO (public oder actor).
  - Schutz: Opfer geschützt (Schutzengel) → stirbt trotzdem (Legacy); Nekromant-Schild aktiv → überlebt.
  - Todesreaktionen: Opfer ist Sensenträger → Reaktion am Morgen.
  - Siegprüfung: Opfer ist letzter Wolf → Dorf-Siegkandidat.
  - Beschädigter Spielstand: InfoRecord mit mehr als 3 Namen → Laden abgelehnt.
- Belegsicherheit: hoch für Code; Overlay-Überschreibung aus Codefluss abgeleitet, nicht im Browser beobachtet.

### traumdeuter
- DE-Name / EN-Name: Traumdeuter / Dreamer (`roles:170`).
- Aliase/Altnamen: keine. Bild `Traumdeuter.webp` / `Dreamer` (`gh:829`, `roleCard.ts:58`). i18n `traumdeuterHint`.
- Legacy-ID: `"Traumdeuter"` (`roles:1`).
- Fraktion: `dorf`.
- Akte: Akt III (`akte.js:55`).
- Nachtpriorität: tier 7.0, kein `once` (`roles:47`). Keine Sonderbedingung.
- Quelltextstellen:
  - `chunk:831` `Traumdeuter`: `alive`; `wolves = alive.filter(isWolf)`; `nonwolves = alive.filter(!isWolf)`; bei 0 Wölfen oder < 2 Nicht-Wölfen Meldung `notEnoughTargets`; sonst 1 zufälliger Wolf + 2 zufällige Nicht-Wölfe (`Math.random`), gemischt per `sort(()=>Math.random()-0.5)`, Anzeige per `center(names + "\n(Genau 1 ist Werwolf)", true)`.
  - `i18n.js:186,510` `traumdeuterHint`, `i18n.js:189,513` `notEnoughTargets`.
- Text DE (wörtlich): "Erhält Visionen über Rollen oder Zustände von Spielern." (`roles:96`)
- Text EN (wörtlich): "Receives visions about roles or states of players." (`roles:245`)
- DE/EN-Vergleich: semantisch gleich JA.
- Weitere Texte: `role-abilities.js:35` identisch. Hinweistext DE "(Genau 1 ist Werwolf)" / EN "(Exactly 1 is a werewolf)" gleich. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht (tier 7.0), unbegrenzt.
  2. Keine Zielwahl; die App wählt vollständig zufällig.
  3. Ergebnis: drei Namen, genau einer davon gilt nach `isWolf` als Wolf. Der Traumdeuter selbst kann unter den zwei Nicht-Wölfen erscheinen (nicht ausgeschlossen).
  4. `isWolf` zählt `cursedWolfAura` (Dämonischer Wolf) als Wolf, Trugbilderwolf ist Wolf, Doppelspion/Manipulator/Parasit/Grabräuber/Todesprediger nicht.
  5. Sichtbarkeit: SL-Anzeige über `center`, nicht gespeichert, nicht geloggt.
  6. Mehrere Kopien: jeder Klick erzeugt eine neue Vision.
  7. Zufall: `Math.random` dreifach.
  8. Keine Interaktion mit Schutz, Wiederbelebung, Sieg.
- React-Version: kein eigenes Verhalten (nur Bildzuordnung).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 40: "unklar", `chunk:831`, "Code: 3 Namen, genau 1 Wolf (wie Kopfgeldjäger)". Zeile bestätigt. Vergleich mit Kopfgeldjäger nicht selbst geprüft.
  - 07 Q1 Teil 1: "eigene Mechanik festlegen oder Code übernehmen und Text anpassen": offen.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` E2 (Orakel-EN = Traumdeuter-EN): behoben (`roles:220` hat eigenen Text).
  - NIGHT-REPORT-abilities.md:58 "Info ❌": bestätigt (Info-Anzeige).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Inhalt der Vision | "Visionen über Rollen oder Zustände" | "visions about roles or states" | 3 Namen, genau 1 Wolf, zufällig | – | 04 unklar, 07 Q1 offen | Code übernehmen, Text präzisieren | eigene Mechanik (Rollen/Zustände) | Code: starke Info jede Nacht | A: kleiner Aufwand; B: neue Spezifikation | A mit Textanpassung | Ja |
| Selbst in der Vision | – | – | möglich | – | – | ausschließen | erlaubt | Selbstnennung ist verschwendete Info | Filter | ausschließen | Ja |
| Verfluchte als Wolf | – | – | ja (`cursedWolfAura`) | – | – | Erscheinung zählt (Fehlinformation) | nur echte Wölfe | beeinflusst Dämonischen Wolf | InformationRules.determine | Erscheinung zählt | Ja |

- Bugs:
  - B-TD-1, unklare Regel: Traumdeuter kann sich selbst sehen (`chunk:831`). Risiko niedrig. Test: Vision enthält nie den Traumdeuter (falls PO so entscheidet).
  - B-TD-2, technische Altlast: Ergebnis nicht gespeichert, verzerrtes Mischen, kein Seed. Risiko mittel für Replay. Test: InfoRecord gespeichert, gleiche Seeds → gleiche Namen.
- Legacy-Status: legacy-contradictory. Der Text ist vage, der Code liefert eine konkrete, andere Mechanik (Wolf unter drei); 04 "unklar" ist inhaltlich gleichbedeutend.
- Automationsvorschlag: automatic (bei Übernahme des Codes: Auswahl per SeededRng, Anzeige an Traumdeuter); sonst unknown.
- Mechanikfamilie primär + sekundär: primär Informationsrolle; sekundär Zufallsmechanik.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (Anzeige/Bestätigung "gezeigt"), SeededRng, InfoRecord, appears_as/InformationRules, Ereignis-Sichtbarkeit (actor), StateCodec, Replay.
- Benötigte NEUE Systeme: keine.
- Abhängigkeiten: alle Wolfsrollen, Dämonischer Wolf (Fluch), Trugbilderwolf (Erscheinung), Doppelspion, Albtraumwolf/Schattenhund/Zeitwächter/Der Weise (Blockaden).
- Komplexität / Fehlerrisiko: S / niedrig (bei Code-Übernahme).
- Offene Entscheidungen: (1) Code-Mechanik übernehmen und Text anpassen oder neue Mechanik? (2) Darf der Traumdeuter sich selbst in der Vision sehen? (3) Zählt Erscheinung (Fluch, Trugbild) oder wahre Fraktion? (4) Was, wenn weniger als 2 Nicht-Wölfe leben?
- Relevante Testgruppen:
  - Normalfall: 2 Wölfe, 6 Dorf → 3 Namen, genau einer Wolf, InfoRecord gespeichert.
  - Ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - Tote Person: Tote erscheinen nie; Traumdeuter tot → kein Schritt.
  - Selbstwahl: Traumdeuter nie in eigener Vision (PO).
  - Mehrere Kopien: zwei Traumdeuter → zwei unabhängige Visionen.
  - Wiederbelebung: nicht relevant, weil kein Zustand.
  - Rollenwechsel: neuer Träger erhält ab nächster Nacht Visionen.
  - Save/Load: Vision nach Laden identisch.
  - Replay: gleiche Seeds → gleiche Namen und Reihenfolge.
  - SL-Korrektur: SL ändert gezeigte Namen → `shown` getrennt von Wahrheit.
  - Sichtbarkeit: nur actor/gm.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant.
  - Siegprüfung: nicht relevant.
  - Beschädigter Spielstand: InfoRecord mit 0 Wölfen → Laden abgelehnt.
  - Zusatz: keine lebenden Wölfe oder < 2 Nicht-Wölfe → Hinweis statt Vision.
- Belegsicherheit: hoch.

### henker
- DE-Name / EN-Name: Henker / Executioner (`roles:171`).
- Aliase/Altnamen: keine. Flag `hmark`, Chip "🪃 Henker-Ziel" (`gh:303`, `i18n.js:68,392`), Marker "🪓" (`ui:109`), Ursache `HANGMAN_EXECUTION` (`ui:404`). Bild `Henker.webp` / `Executioner` (`gh:829`, `roleCard.ts:59`).
- Legacy-ID: `"Henker"` (`roles:1`).
- Fraktion: `dorf`.
- Akte: Akt III (`akte.js:57`).
- Nachtpriorität: tier 7.8, kein `once` (`roles:52`). Bedingung `night:59`: Zeile nur bei `once.LynchCount >= 3` (Default 0 über `state:64`).
- Quelltextstellen:
  - `chunk:832` `Henker`: bei `LynchCount<3` Meldung `henkerNotActive`; sonst `pick` lebende Person (Selbstwahl erlaubt), löscht alle `hmark`, setzt `hmark` auf Ziel.
  - `night:404-419` `finalizeLynch`: `LynchCount++`; alle lebenden `hmark`-Sitze außer dem Gelynchten sterben mit `HANGMAN_EXECUTION`; danach alle `hmark` gelöscht.
  - `night:421-503` `doLynchFlow`: `finalizeLynch` in den Zweigen Wahnsinniger Kutscher (`night:436`), Voodoo (`night:442`), Der Weise (`night:463`), Selbstmörder (`night:478`), Spiegelwolf (`night:492`), Standard vor Dämonischem Wolf (`night:500`). NICHT bei Fenrir (`night:448`) und Cerberus (`night:449`).
  - `night:145` `onNightStart` und `night:506-510` `resetNightState` löschen `hmark` nicht; `night:512-529` `resetMarksOnly` löscht es.
  - `gh:2409-2431` Log-Patch: `HANGMAN_EXECUTION` hat keinen Logtext, erscheint als "starb (HANGMAN_EXECUTION)".
- Text DE (wörtlich): "Wird nach drei Lynchungen aktiv. Markiert nächtlich ein Ziel, das zusätzlich nach Lynchung stirbt." (`roles:97`)
- Text EN (wörtlich): "Activates after three lynchings. Each night marks a target who dies additionally after the next lynch." (`roles:246`)
- DE/EN-Vergleich: semantisch gleich NEIN (geringfügig). EN präzisiert "after the next lynch"; DE sagt nur "nach Lynchung" (offen, ob nächste oder irgendeine). Aktivierung (3 Lynchungen) und Häufigkeit (jede Nacht) gleich.
- Weitere Texte: `role-abilities.js:18` identisch. `henkerNotActive` sagt "3 Lynch-Tote nötig", Code zählt Lynch-Vorgänge (auch ohne Tod des Gelynchten, z. B. Spiegelwolf, Voodoo). Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Aktivierung: ab `LynchCount >= 3`, d. h. in der Nacht nach dem dritten abgeschlossenen Lynch; gezählt werden alle `finalizeLynch`-Aufrufe, unabhängig davon, ob der Henker schon im Spiel war.
  2. Jede Nacht optional eine Markierung (Pick abbrechbar); neue Markierung ersetzt die alte (global über alle Sitze).
  3. Ziel: lebende Person, Selbstwahl erlaubt.
  4. Wirkung: beim nächsten Lynch stirbt die markierte Person zusätzlich (`HANGMAN_EXECUTION`), es sei denn, sie ist selbst der Gelynchte; Markierung wird danach gelöscht.
  5. Persistenz: gibt es keinen Lynch, bleibt die Markierung über weitere Nächte bestehen.
  6. Henker tot: Markierung bleibt wirksam und wird beim nächsten Lynch vollstreckt; keine neue Markierung (Zeile weg).
  7. Fenrir/Cerberus-Lynchrettung: kein `finalizeLynch` → Markierung wird nicht vollstreckt, `LynchCount` steigt nicht (F15).
  8. Schutz: `applyKill` → Rudelvater-Erstrettung, Nekromant-Schild, Hades-Barriere, Kartenschlucker-Schild, Parasit greifen; Schutzengel nicht.
  9. Sichtbarkeit: Marker am Sitz (SL-Bildschirm); Tod im Log generisch.
  10. Mehrere Kopien: gemeinsame Markierung (jede Wahl löscht alle anderen).
  11. Zufall: keiner.
  12. Siegprüfung: über `applyKill`/`postDeathHooks`.
- React-Version: kein eigenes Verhalten; `hmark` wird durchgereicht (`legacyAdapter.ts:383,399`), Chip in `PlayerEditor.tsx:54`, Lynch delegiert (`GameAdapter.ts:103`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 41: "verifiziert", `chunk:832`, `night:404-419`, "Ab dem 3. Lynch nachts 1 markieren; beim nächsten Lynch stirbt der Markierte mit". Bestätigt, Zeilen stimmen.
  - 04 E-3/E-4 und 01 F15 (Cerberus/Fenrir überspringen `finalizeLynch`): bestätigt (`night:448-449`).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` L5 (Kutscher-, Voodoo-, Spiegelwolf-, Dämon-Pfad ohne LynchCount/Henker): für heutigen Stand widerlegt/behoben, nur Fenrir/Cerberus bleiben.
  - 07 Q1 Teil 2: "Cerberus/Fenrir überspringen Lynchzählung" als Bug ohne Rückfrage.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Welcher Lynch | "nach Lynchung" | "after the next lynch" | nächster Lynch, Markierung bleibt bis dahin | – | 04 "beim nächsten Lynch" | nächster Lynch (EN, Code) | nur Lynch des folgenden Tages, sonst verfällt | gering | Verfall ja/nein | A | Nein |
| Blockierter Lynch (Fenrir/Cerberus) | – | – | kein Zählen, keine Vollstreckung | – | 01 F15 als Bug, 07 Teil 2 | blockierter Lynch zählt als Lynch | zählt nicht (kein Tod) | beeinflusst Aktivierung und Markierten | ExecutionRules-Ergebnis "verhindert" | PO bestätigen, 07 geht von A aus | Ja |
| Zählbasis | "drei Lynchungen" | "three lynchings" | Lynch-Vorgänge; i18n sagt "Lynch-Tote" | – | – | Vorgänge | nur Lynch-Tote | Spiegelwolf/Voodoo-Tage | Zähler-Definition | Vorgänge, i18n anpassen | Ja |
| Henker tot | – | – | Markierung wirkt weiter | – | – | wirkt weiter | verfällt mit Henker | gering | Bindung Markierung↔Henker | PO | Ja |

- Bugs:
  - B-HE-1, unklare Regel (F15): `night:448-449` ohne `finalizeLynch`. Tatsächlich: bei Fenrir/Cerberus-Rettung keine Zählung, keine Henker-Vollstreckung. Erwartet laut 07 Teil 2: Zählung/Vollstreckung; laut Text offen. Risiko mittel. Test: Henker markiert C, Cerberus mit 3 Köpfen wird gelyncht → Ergebnis gemäß PO, `LynchCount` gemäß PO.
  - B-HE-2, technische Altlast: `henkerNotActive` "3 Lynch-Tote" vs. Zählung von Lynch-Vorgängen (`i18n.js:227,556`, `night:414`). Risiko niedrig. Test: Spiegelwolf-Lynch zählt als Lynch.
  - B-HE-3, technische Altlast: kein Logtext für `HANGMAN_EXECUTION` (`gh:2413-2427`); Chip-Emoji 🪃 vs. Marker 🪓. Risiko niedrig. Test: Protokolleintrag mit Ursache Henker.
- Legacy-Status: legacy-verified. Aktivierung nach 3 Lynchungen, nächtliche Markierung und Zusatztod beim nächsten Lynch sind nachvollziehbar umgesetzt; F15 ist ein Randfall mit offener Regel.
- Automationsvorschlag: automatic. Markierung per Prompt, Vollstreckung automatisch in ExecutionRules.
- Mechanikfamilie primär + sekundär: primär Hinrichtungsreaktion; sekundär Tötung (verzögert).
- Benötigte vorhandene Godot-Systeme: StepQueue (bedingter Schritt), PendingPrompt, ExecutionRules (Folgetod nach Hinrichtung), KillPipeline, Reaktionswarteschlange (Folgereaktionen des Markierten), WinRules, StateCodec, Replay, GmCorrections, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: dauerhafter Statusmarker mit Besitzer (Henker-Markierung bis zum nächsten Lynch), Lynch-Zähler im Spielstand (zeitlich verzögerter Effekt an Hinrichtung gekoppelt).
- Abhängigkeiten: alle Lynch-Sonderzweige (Wahnsinniger Kutscher, Voodoo, Der Weise, Selbstmörder, Spiegelwolf, Dämonischer Wolf, Fenrir, Cerberus, Rudelvater), Rudelvater/Nekromant/Hades/Kartenschlucker/Parasit (Todesabfang).
- Komplexität / Fehlerrisiko: M / mittel (Kopplung an alle Hinrichtungszweige).
- Offene Entscheidungen: (1) Zählt ein durch Fenrir/Cerberus verhinderter Lynch (Zählung und Vollstreckung)? (2) Zählen Lynch-Vorgänge oder nur Lynch-Tote? (3) Verfällt die Markierung, wenn am Folgetag nicht gelyncht wird, oder bleibt sie bis zum nächsten Lynch? (4) Wirkt die Markierung nach dem Tod des Henkers weiter? (5) Darf der Henker sich selbst markieren? (6) Ist die Markierung öffentlich?
- Relevante Testgruppen:
  - Normalfall: 3 Lynchs, Henker markiert C, Tag: A gelyncht → A und C tot (`HANGMAN_EXECUTION`).
  - Ungültiges Ziel: toter Spieler → `invalid_target`; vor 3 Lynchs → kein Schritt.
  - Tote Person: Henker tot nach Markierung → Verhalten nach PO (Legacy: wirkt).
  - Selbstwahl: Henker markiert sich selbst → nach PO (Legacy erlaubt).
  - Mehrere Kopien: zwei Henker → getrennte Markierungen nach PO (Legacy: eine gemeinsame).
  - Wiederbelebung: markierte Person stirbt vor dem Lynch und wird wiederbelebt → Markierung nach PO.
  - Rollenwechsel: Henker-Rolle geht per Seelentauscher weiter → Zähler bleibt global, neuer Träger aktiv.
  - Save/Load: Speichern mit aktiver Markierung → nach Laden vorhanden.
  - Replay: Vollstreckung reproduzierbar.
  - SL-Korrektur: SL entfernt Markierung → keine Vollstreckung, Protokoll.
  - Sichtbarkeit: Markierung nur SL (PO).
  - Schutz: markierter Rudelvater (unverbraucht) → überlebt Henker-Tod (Legacy).
  - Todesreaktionen: markierter Sensenträger stirbt durch Henker → Reaktion sofort am Tag.
  - Siegprüfung: Henker-Tod erzeugt Parität → Kandidat nach der Hinrichtung.
  - Beschädigter Spielstand: Markierung auf unbekannte Person → Laden abgelehnt.
  - Zusatz: markierte Person ist der Gelynchte → genau ein Tod; Cerberus-Lynch (F15) nach PO.
- Belegsicherheit: hoch.

## Gruppenübergreifende Beobachtungen

1. Globale Einmaligkeit statt pro Person: `markOnceUsed`/`isOnceUsed` (`night:3-5`) speichert den Verbrauch pro Rollenname (`once.Used.role_<Name>`); Märtyrerin (`MaertyUsed`) und Kutscher (`KutscherUsed`) nutzen eigene globale Schlüssel. Mehrere Kopien teilen sich damit einen Verbrauch. Godot hat bereits `ability_uses` pro Person; der PO sollte einmal generell entscheiden, dass Verbrauch pro Person gilt.
2. `resetOnceForInheritedRole` (`core:339-359`) ist uneinheitlich: für Kutscher wirksam (`KutscherUsed`), für Seelentauscher und Blutpriester wirkungslos (löscht `SeelentauscherUsed`/`BlutpriesterUsed`, die `isOnceUsed` nicht liest), für Märtyrerin nicht vorhanden. Das ist in 04 nicht erwähnt. Für RoleTransition muss festgelegt werden, ob Rollenzustand mit der Rolle oder mit der Person wandert.
3. Rollenprüfungen zum Zeitpunkt der Morgenauflösung (`night:251` Dorfwache, `night:257` Märtyrerin, `night:253` Voodoo) lesen die aktuelle Rolle. Da der Seelentauscher (tier 8.0) nach dem Rudel handelt, kann ein Tausch nach der Rudelwahl die Abwehr verändern. In 04 nicht erwähnt.
4. Zufall ohne Seed in drei Rollen: Blutpriester (`chunk:703`), Traumdeuter (`chunk:831`), Kutscher (`chunk:842,844,855`). Zweimal verzerrtes Mischen per `sort(()=>Math.random()-0.5)`. Informationsergebnisse (Blutpriester, Traumdeuter) werden nicht gespeichert, damit nicht replayfähig; Godot braucht SeededRng + InfoRecord.
5. Stimm-/Nominierungsbezug: Korrupter Richter ("+1 Stimme") und Henker (Lynch-Zählung) hängen an Tagesabläufen, die die Legacy-App nur als Direktwahl kennt (`doLynchFlow`). DECISION-LOG legt fest, dass Stimmen physisch bleiben und Nominierungen mit Nominierenden gespeichert werden; damit fehlt für den Richter nur eine Nominierungsquelle "Rolle".
6. Fehler/Ungenauigkeiten in 04:
   - Zeile 27 Märtyrerin "verifiziert": EN-Text widerspricht (keine Rettung genannt), Zeitwächter-Reihenfolge fehlerhaft (B-MA-1). Besser "widersprüchlich".
   - Zeile 37 Kutscher "verifiziert": Text sagt nichts über neue Zufallsrollen (inkl. Solo) und Zufallsauswahl. Besser "widersprüchlich".
   - Zeile 28 Dorfwache: Giftwolf-Tod und Schild-Verbrauch fehlen als Randfälle.
   - Zeile 38 Seelentauscher: F4 betrifft auch den Wächter-am-Tor-Zweig (`chunk:778`), nicht nur `chunk:782-783`.
   - Alle Zeilenangaben der acht Rollen in 04 stimmen mit dem aktuellen Code überein.
7. Frühere Berichte sind teilweise überholt: `GRIMMHAIN_ANALYSE_2026-06-12.md` L5 (Lynch-Sonderpfade), L8 (Kutscher-Duplikate), L13 (Märtyrerin rettet alle) und E2 (Orakel-EN) sind im heutigen Code behoben; offen bleibt nur F15 (Fenrir/Cerberus).
8. Hart kodierte DE-Dialogtexte und UI-Überschreibungen: Richter- und Blutpriester-Dialoge schreiben direkt in `#overlay`; der Blutpriester überschreibt dabei das eben geöffnete Todes-Popup (`postDeathHooks` vor eigenem Overlay). Für Godot irrelevant, zeigt aber, dass Prompt-Reihenfolge (Todesfolgen vor Informationsanzeige) explizit modelliert werden muss.
9. EN-Rollennamen inkonsistent: "Soul Swapper" (Rollenname) vs. "Soul Shifter" (Dialoge). Henker-Chip-Emoji 🪃 vs. Sitzmarker 🪓.
10. Märtyrerin hat einen Nachtorder-Eintrag ohne Handler (tier 9.0); Dorfwache steht korrekt nicht in `ORDER_BASE`. Beim Godot-Nachtplan sollte die Märtyrerin keinen Nachtschritt erhalten, sondern eine Morgen-Abfangregel.
