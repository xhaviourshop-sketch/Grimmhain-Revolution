<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G5 Dorf 1 · Legacy-Rollenprüfung

Rollen: loki, nachtwaechter, die-gebundenen, die-ewigen, spuerhund, der-weise, verdammniswaechter, wahnsinniger-kutscher.
Stand: 2026-09-26, nur gelesen. Pfadkürzel wie im Brief (`roles`, `chunk`, `ab`, `help`, `night`, `core`, `ui`, `state`, `gh`).
Hinweis: Geviertstriche erscheinen nur innerhalb wörtlicher Zitate aus dem Code.

Allgemeine Mechanik, die für alle Nachtrollen dieser Gruppe gilt (einmal belegt, unten nur referenziert):
- Nachtzeile erscheint nur, wenn die Rolle von einem lebenden Sitz gehalten wird (`night:43` `rolesInGame`, `night:88-94` `hasAliveRole`), nicht als `once` verbraucht ist (`night:59` `isOnceUsed`) und nicht im Passiv-Set steht (`night:96` `passive`).
- `once:true` heißt in Legacy "einmal pro Partie", NICHT "nur Nacht 1": die Zeile bleibt jede Nacht sichtbar, bis `markOnceUsed` gesetzt ist (`night:3-5`).
- Blockaden für alle Rollen außerhalb `WOLF_ROLES_SET` (also alle 8 Rollen hier, alle sind Dorf): Schattenhund, Zeitwächter, Der-Weise-Debuff `OldDebuff`, Albtraum (`ab:93-99` `onOrderClick`). Passive Rollen (Nachtwächter, Der Weise, Wahnsinniger Kutscher) laufen nicht über `onOrderClick` und sind davon nie betroffen.
- `onOrderClick` ermittelt Akteure per `filter` (`ab:72`), die Handler selbst prüfen aber nicht, WER handelt; Mehrfachkopien teilen sich eine Zeile.
- Rotkäppchen-Apfel (`ab:101-122`) lässt eine Fähigkeit nach der ersten Auswahl erneut laufen (betrifft Spürhund, Die Ewigen; Loki scheitert beim zweiten Lauf an `isOnceUsed`).
- `state.ui.ghostCasting` wird nirgends auf `true` gesetzt (rg nach Zuweisungen: nur Resets in `ui:341`, `state:71`), die Ausnahmen in `isOnceUsed`/`markOnceUsed` (`night:4-5`) sind toter Code.
- `applyKill` (`core:102-216`) prüft `flags.protected` NICHT. Schutzengel/Dorfwache wirken ausschließlich im Werwolf-Pick (`chunk:162`) und beim Rachsüchtigen Wolf (`chunk:348-353`): ein geschütztes Ziel wird gar nicht erst `targeted`, der Schutz wird beim Pick verbraucht. In `applyKill` wirken nur: Parasit, Rudelvater-Erstrettung, Schattenwanderer-Tausch, Nekromant-Immunität, Kartenschlucker-Schild, Hades-Barriere (`core:104-143`).
- Godot: `godot/` enthält zu keiner der 8 Rollen Code oder Tests (rg nach Namen/IDs in `godot/`, `tests/`: keine Treffer).

---

### loki
- DE-Name / EN-Name: Loki / Loki (`roles:138`)
- Aliase/Altnamen (state.js migrateLegacyRoleIds, i18n, Bilder, sonstige Schreibweisen im Code): `Amor` → `Loki` (`state:18`, inkl. `once.Used.role_Amor` → `role_Loki` `state:29-36`); Bilder `Loki_DE.webp` (`roles:412`, `gh:808`), `Loki_EN.webp` (`gh:814`, `app/src/roleCard.ts:13,20`); Zustände `flags.inlove`, `flags.rival`, `meta.loverId`, `meta.rivalId`; Todesursache `LOVER_HEARTBREAK` (Label "💔 Loki" `ui:410`, Log `gh:2419`); SFX-Schlüssel `sfxLovers` (No-op); Tags `["chain-reaction","vote-manipulation"]` (`roles:296`, `vote-manipulation` hat keine Codewirkung). Achtung: Totenkarten-Kategorie `LOKI` in `cards.js` ist ein Kartentyp, kein Rollenbezug.
- Legacy-ID (String in ALL_ROLES): `"Loki"` (`roles:1`, Index 0)
- Fraktion (getRoleFaction) und weitere Fraktionsbesonderheiten im Code: `dorf` (`roles:405-409`, nicht in WOLF/SOLO-Set). Akte-Liste führt Loki unter "DORF".
- Akte (akte.js): Akt I, II, III, IV (`akte.js:17,37,58,79`).
- Nachtpriorität (ORDER_BASE tier, once) und Bedingungen für den Nachtschritt (night.js): tier 0.1, `once:true` (`roles:5`). Zeile solange lebender Loki existiert und `role_Loki` nicht verbraucht ist, also jede Nacht bis zur Nutzung, nicht nur Nacht 1 (`night:59`, `night:92`). Blockaden `ab:94-99`.
- Quelltextstellen (Liste pfad:zeilen Symbol – was dort passiert):
  - `chunk:131-140` `abilities.Loki` – Overlay "Liebe/Hass", danach `startMulti` 2 lebende Sitze; setzt `inlove`/`loverId` bzw. `rival`/`rivalId` beidseitig, `markOnceUsed("Loki")`.
  - `ui:340` `startMulti` – verhindert Doppelwahl desselben Sitzes.
  - `core:361-386` `postDeathHooks` – Liebeskummer-Fixpunktschleife, nur wenn `isOnceUsed("Loki")`; tötet lebenden Partner mit `LOVER_HEARTBREAK`, beidseitige ID-Prüfung.
  - `chunk:449-460` `abilities["Schwarze Witwe"]` – einzige Wirkung der Rivalen; liest `loverId`/`rivalId`.
  - `setup.html:1111-1117`, `gh:1194-1199` – Pflichtpaar Witwe → Loki.
  - `night:510-531` `resetMarksOnly` – löscht Liebe/Rivalen; `gh:512-518` `clearRolesNewRound` setzt `inlove`/`rival`/`rivalId` zurück, aber NICHT `meta.loverId`.
  - `gh:292-293` Chips `inlove`/`rival` (manuell, ohne `loverId`).
- Text DE (wörtlich): `Eros und Eris leihen dir ihre Kraft. Verbinde einmalig zwei Seelen als unzertrennliche Liebende (U+2014) oder verfluche zwei als ewige Rivalen.` (`roles:64`)
- Text EN (wörtlich): `Once per game: bind two souls as inseparable lovers (U+2014) or curse two players as eternal rivals.` (`roles:213`)
- DE/EN-Vergleich (semantisch gleich JA/NEIN + konkrete Unterschiede): JA. "einmalig" = "Once per game"; Ziele je zwei; Rivalen als Fluch in beiden. EN lässt nur den Flavor-Satz "Eros und Eris leihen dir ihre Kraft" weg.
- Weitere Texte (role-abilities.js, i18n.js, Totenkarten-Bezug), falls abweichend: `role-abilities.js:25` identisch. i18n: `loverHeartbreakCenter` (`i18n:187/511`), Laufzeitübersetzung "Liebe ❤ oder Hass 💔 ?" (`i18n:768-770`). Kein Totenkarten-Rollenbezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nacht, erster Schritt (0.1), jede Nacht verfügbar bis zur Nutzung.
  2. SL wählt Modus Liebe oder Hass (Doppelklick durch `lokiChoiceLocked` gesperrt, `chunk:136-138`).
  3. Ziele: genau 2 verschiedene lebende Sitze (`x=>!x.flags.dead`); Selbstwahl erlaubt; Wölfe/Solos erlaubt; tote Ziele nicht wählbar.
  4. Verbrauch erst nach vollständiger Zweierwahl (`markOnceUsed` im Callback). Abbruch vor der zweiten Wahl verbraucht nichts.
  5. Liebe: beim Tod eines Liebenden stirbt der andere in `postDeathHooks` mit `LOVER_HEARTBREAK`, kettenfähig (do/while). Wirkt bei jeder Todesursache, sobald `postDeathHooks` läuft (Nacht: `night:350`, Lynch, Sofortkills).
  6. Kette nur, wenn `isOnceUsed("Loki")` global wahr ist; manuell per Chip gesetzte Liebende (ohne `loverId`) lösen nie aus.
  7. Rivalen: kein eigener Effekt; nur Schwarze Witwe kann ein Rivalenpaar finden (`chunk:454`).
  8. Sichtbarkeit: keine Ansage im Code; Marker auf dem Feld (SL-Ansicht).
  9. Mehrere Kopien: Max 1 (`gh:866`, `setup.html:796`); `once`-Schlüssel global, eine zweite Kopie (z.B. via Lehrling/Frankenstein) könnte nie handeln, weil `role_Loki` global verbraucht ist (`core:339-359` `resetOnceForInheritedRole` löscht nur `LokiUsed`, nicht `Used.role_Loki`).
  10. Zufall: keiner.
  11. Wiederbelebung: Frankenstein belässt `inlove`/`loverId` (`chunk:57-61`) → ist der Partner noch tot, stirbt der Wiederbelebte beim nächsten `postDeathHooks` erneut an Liebeskummer (zweite Schleife `core:378-383`). Kutscher-Wiederbelebung setzt Flags/Meta zurück (`chunk:849-850`) → Bindung einseitig gelöst.
  12. Schutz: Liebeskummer geht über `applyKill`, Schutzengel wirkt nicht; `applyKill`-Schilde (Nekromant, Kartenschlucker, Hades, Rudelvater) wirken.
  13. Sieg: keine Liebenden-Siegbedingung im Code (Text verspricht keine).
- React-Version: kein eigenes Verhalten; Dialog über `domMirror.ts` gespiegelt; `PlayerEditor.tsx:44` Chip "❤ verliebt" (nur Flag), Kartenbild `roleCard.ts:13,20`.
- Bisherige Doku (04-Status + Kernaussage, 07-Frage, DECISION-LOG, Berichte) und Prüfergebnis dazu:
  - 04 Zeile 1: "widersprüchlich", `chunk:131-140`, Kette `core:365-386`. Bestätigt (Zeilen stimmen; Kette `core:365-385`). Ergänzung: `once` gilt nicht nur für Nacht 1; Wiederbelebungs-Interaktion; veraltetes `loverId` nach neuer Runde.
  - 04 C-3: "Liebende nur wenn Loki genutzt, manuelle Liebende ohne Kette" bestätigt (`core:367`, Chip setzt kein `loverId`).
  - 07 Q1: "Rivalen ohne Wirkung (nur Witwe)" bestätigt.
  - DECISION-LOG: keine Loki-Entscheidung.
  - NIGHT-REPORT-abilities.md:44 (React zeigte Dialog nicht, ❌): heute durch `domMirror.ts:49-60` überholt (nicht im Browser verifiziert).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Rivalen-Wirkung | "verfluche zwei als ewige Rivalen" | "curse two players as eternal rivals" | kein Effekt außer Witwe-Ziel (`chunk:454`) | wie Legacy | 07 Q1 Vorschlag: nie gemeinsam gewinnen oder Option entfernen | Rivalen = reiner Marker für Schwarze Witwe | Rivalen bekommen eigene Regel (z.B. Siegsperre) | Hass-Option ist ohne Witwe eine Leerwahl | Ohne Regel nur Marker; mit Regel WinRules-Erweiterung | PO entscheidet; bis dahin Marker | Ja |
| Nacht-1 vs. einmal | "einmalig" | "Once per game" | jede Nacht bis Nutzung (`night:59`) | wie Legacy | 04: "einmal" | einmal pro Partie, beliebige Nacht | nur Nacht 1 | gering | Schritt-Bedingung | Code = Text, beibehalten | Nein |

- Bugs:
  - B-LOKI-1 (technische Altlast / echter Bug für Schwarze Witwe): `gh:512-518` `clearRolesNewRound` setzt `meta.loverId` nicht zurück (nur `rivalId`). Tatsächlich: nach "Neue Runde" bleibt `loverId` stehen; Schwarze Witwe (`chunk:453`) findet dann ein Paar über veraltetes `loverId`, auch ohne Loki-Nutzung in dieser Runde. Erwartet: neue Runde ohne Bindungen. Risiko mittel (nur mit Witwe). Test: Runde 1 Loki verliebt A,B → Neue Runde → Witwe wählt A → darf kein Paar finden.
  - B-LOKI-2 (unklare Regel): Frankenstein-Wiederbelebung eines an Liebeskummer Gestorbenen führt zum erneuten Tod beim nächsten `postDeathHooks` (`chunk:57`, `core:378-383`). Erwartet laut Text offen. Test: A,B verliebt, A stirbt, B stirbt mit; Frankenstein belebt B → nächste Todesverarbeitung: B stirbt erneut (Legacy) vs. Bindung gelöst (Entscheidung).
  - B-LOKI-3 (technische Altlast): Kette hängt an globalem `isOnceUsed("Loki")` (`core:367`); der Button "resetOnce" (`gh:558`, `Used={}`) schaltet die Kette mitten im Spiel ab und gibt Loki eine zweite Nutzung. Test: Save mit Liebenden → Once-Reset → Tod A → B muss trotzdem sterben (Godot: Bindung ist Zustand, nicht Einsatzzähler).
- Legacy-Status: legacy-contradictory. Liebeskette funktioniert wie beschrieben; die Rivalen-Option verspricht einen Fluch ohne eigene Wirkung (Text/Code-Lücke, kein Defekt).
- Automationsvorschlag: automatic. Wahl wird vom SL eingegeben, Bindung und Liebeskummer-Kette sind deterministisch.
- Mechanikfamilie primär + sekundär: Verknüpfte Personen; sekundär Einmalfähigkeit, Todesreaktion.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (Modus + 2 Ziele, abbrechbar), KillPipeline (Folgetod als Kette), Reaktionswarteschlange, Ereignis-Sichtbarkeit (gm), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Liebes-/Bindungsmodell (Paar-Bindung mit Typ love/rival, analog WolfChildBond/ApprenticeBond, inkl. Verhalten bei Wiederbelebung); dauerhafte Statusmarker für Rivalen.
- Abhängigkeiten von anderen Rollen: Schwarze Witwe (Pflichtpaar, liest Bindung), Dr. Victor Frankenstein/Kutscher (Wiederbelebung), Lehrling (Erbe), Nekromant/Kartenschlucker/Hades (Schilde in `applyKill`).
- Komplexität (S/M/L/XL) und Fehlerrisiko: M / mittel. Kettenfixpunkt und Wiederbelebung sind die Fehlerquellen.
- Offene Entscheidungen:
  1. Haben Rivalen eine eigene Wirkung (Q1-Vorschlag) oder bleiben sie Witwe-Marker?
  2. Stirbt ein wiederbelebter Liebender erneut, wenn sein Partner tot ist?
  3. Ist der Liebeskummer-Tod eine eigene Todesursache mit Reaktionen (Sensenträger) wie heute?
  4. Darf Loki sich selbst wählen (Legacy: ja)?
- Relevante Testgruppen:
  - Normalfall: Liebe A,B; A stirbt nachts → B stirbt in derselben Auflösung, Ursache LOVER_HEARTBREAK.
  - ungültiges Ziel: denselben Sitz zweimal → zweite Wahl ignoriert.
  - tote Person: tote Sitze nicht wählbar.
  - Selbstwahl: Loki + C verliebt → zulässig; Loki stirbt → C stirbt.
  - mehrere Kopien: zweite Loki-Kopie via Erbe → heute nie aktiv; Soll klären.
  - Wiederbelebung: siehe B-LOKI-2.
  - Rollenwechsel: Seelentauscher tauscht Rolle eines Liebenden → Bindung bleibt an Person.
  - Save/Load: Save nach Bindung, Load, Tod A → B stirbt.
  - Replay: bytegleich mit Bindung und Kette.
  - SL-Korrektur: Bindung per Korrektur lösen → keine Kette.
  - Sichtbarkeit: Bindung nur gm/actor, Tod öffentlich (DR-04).
  - Schutz: B von Schutzengel geschützt → stirbt trotzdem (Legacy).
  - Todesreaktionen: B ist Sensenträger → Reaktion nach Liebeskummer.
  - Siegprüfung: Kette macht Wolfsparität → Sieg erst nach Kette (DR-14).
  - beschädigter Spielstand: `loverId` zeigt auf fehlende ID → keine Kette, kein Absturz.
- Belegsicherheit: hoch für Code; nicht im Browser verifiziert, ob React-Overlay-Spiegelung den Dialog vollständig bedient.

### nachtwaechter
- DE-Name / EN-Name: Nachtwächter / Night Warden (`roles:139`)
- Aliase/Altnamen: `Bärenführer` → `Nachtwächter` (`state:18`); Funktion `doBearPing`, Flags `state._allowBearPing`, `state._bearPingDone` (letzteres nie gelesen), SFX `sfxBear` (laut `GRIMMHAIN_ANALYSE_2026-06-12.md:69` früher `Bärenführer.mp3`); Bilder `Nachtwächter.webp`, `Night_Warden.webp` (`gh:814`, `roleCard.ts:21`).
- Legacy-ID: `"Nachtwächter"` (`roles:1`, Index 1)
- Fraktion: `dorf`.
- Akte: Akt I (`akte.js:18`).
- Nachtpriorität und Bedingungen: nicht in ORDER_BASE; zusätzlich im Passiv-Set (`night:96`). Kein Nachtschritt.
- Quelltextstellen:
  - `night:189-190` `onDayStart` – `_allowBearPing=true`.
  - `core:400` `postDeathHooks` – ruft `doBearPing()` bei jedem Durchlauf.
  - `night:535-560` `doBearPing` – einmal pro Morgen (Flag), erster lebender Nachtwächter (`seats.find`), nächster LEBENDER Nachbar links/rechts (`nextAlive` überspringt Tote), Treffer bei `isWolf` oder `SOLO_WIN_ROLES` → `queueSfxKey("sfxBear")`.
  - `js/ui/audio.js:12` `queueSfxKey` – No-op seit 2026-06-12.
- Text DE (wörtlich): `Bewacht die Grenzen und spürt, wenn ein Nachbar nicht ins Dorf gehört. Es ertönen öffentlich die Alarmglocken.` (`roles:65`)
- Text EN (wörtlich): `Guards the borders and senses when a neighbor doesn't belong to the village. The alarm bells ring publicly.` (`roles:214`)
- DE/EN-Vergleich: JA. Beide ohne Zeitpunkt, beide "öffentlich", beide "ein Nachbar".
- Weitere Texte: `role-abilities.js:27` identisch. Keine i18n-Meldung für den Alarm vorhanden.
- Legacy-Codeverhalten:
  1. Zeitpunkt: beim ersten `postDeathHooks` nach `onDayStart`, praktisch am Ende der Morgenauflösung (`night:350` `afterCurses`). Ausnahme: gibt es Witwen- oder Giftwolf-Morgentode, läuft `postDeathHooks` schon dort (`night:197`, `night:208-210`) und der Alarm wird VOR den Wolfstoden ausgewertet.
  2. Unabhängig davon, ob in der Nacht jemand starb.
  3. Nachbarn: nächster lebender Sitz je Richtung (Index = `id-1`).
  4. Treffer: `isWolf` (inkl. `flags.werewolf`, `cursedWolfAura`) oder Solo-Rolle per Name.
  5. Wirkung: nur `queueSfxKey("sfxBear")`, das ein No-op ist. Keine Ansage, kein Log, kein Center-Text. Öffentlich passiert nichts.
  6. Blockaden (Debuff, Schattenhund) wirken nicht (passiv).
  7. Mehrere Kopien: `seats.find` → nur der erste lebende Nachtwächter (Max 1).
  8. Zufall: keiner.
  9. Tot: kein Alarm.
- React-Version: kein eigenes Verhalten (rg ohne Treffer außer Kartenbild).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 2: "fehlend", `night:535-560`, "löst nur SFX aus (No-op)". Bestätigt. Präzisierung zum Akzeptanzkriterium "Morgens nach Toten": Legacy prüft jeden Morgen, nicht nur nach Toten, und nimmt den nächsten lebenden Nachbarn.
  - 01 §2 (`01-current-system-inventory.md:136`) zählt `doBearPing` zu `(id-1±1) mod n`: ungenau, `doBearPing` überspringt Tote.
  - 07 Z.103 "Nachtwächter ohne Wirkung": bestätigt.
  - AUDIT.md:143,160 (fehlende Alarm.mp3) und `GRIMMHAIN_ANALYSE_2026-06-12.md:126` ("Ping ignoriert verwandelte Wölfe") sind überholt: heute `isWolf` (`night:557`), SFX absichtlich stumm.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Öffentlicher Alarm | "Es ertönen öffentlich die Alarmglocken" | "ring publicly" | kein sichtbarer Effekt (No-op) | keiner | 04: fehlend | Öffentliches Ereignis jeden Morgen bei Treffer | nur SL-Hinweis, SL läutet | Rolle ist heute wirkungslos | PUBLIC-Ereignis + Anzeige | A, als öffentliches Ereignis | Nein (Text eindeutig) |
| Nachbarbegriff | "ein Nachbar" | "a neighbor" | nächster lebender Nachbar | keiner | 04: "lebender Nachbar" | nächster lebender Sitz | direkter Sitz | leicht | Sitznachbarschafts-Funktion | nächster lebender (wie Code) | Ja |
| Solo zählt | "nicht ins Dorf gehört" | "doesn't belong to the village" | Wolf ODER Solo | keiner | 04: Wolf oder Solo | Solo zählt | nur Wolf | mittel | Fraktionsabfrage | Solo zählt (Code und Text decken sich) | Nein |

- Bugs:
  - B-NW-1 (technische Altlast mit Funktionsverlust): `night:559` + `audio.js:12`: einzige Ausgabe ist ein stummgeschalteter SFX. Tatsächlich: Rolle hat keine beobachtbare Wirkung. Erwartet: öffentlicher Alarm. Risiko hoch für Spielgefühl. Test: Nachbar ist Wolf, Morgen → Ereignis `night_warden_alarm` mit Sichtbarkeit public.
  - B-NW-2 (unklare Regel): Auswertung schon beim Witwen-/Giftwolf-Morgentod (`night:197`, `night:208-210`) vor den Wolfstoden; Ergebnis kann von der Todesreihenfolge abhängen. Test: Witwen-Tod und Wolfstod am selben Morgen, Nachbar stirbt durch Wolf → Alarm ja/nein festlegen.
- Legacy-Status: legacy-broken. Die Erkennung existiert, aber die einzige Ausgabe (SFX) ist ein No-op; die Kernfunktion "öffentlicher Alarm" findet nie statt. (Nicht not-found, weil die Mechanik im Code vorhanden ist.)
- Automationsvorschlag: automatic. Rein zustandsbasiert berechenbar.
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Sitzpositionsmechanik, passive Dorfrolle.
- Benötigte vorhandene Godot-Systeme: Ereignis-Sichtbarkeit (public), InfoRecord, Phasenübergang Morgen, Replay, StateCodec.
- Benötigte NEUE Systeme: Sitznachbarschaft (nächster lebender Nachbar nach Sitzreihenfolge, nicht nach ID; DECISION-LOG Z.31-32: Sitze tauschbar).
- Abhängigkeiten von anderen Rollen: alle Wolfs- und Solorollen; Dämonischer Wolf (`cursedWolfAura` zählt als Wolf), Wolfskind (verwandelt), Doppelspion (Solo, Nicht-Wolf).
- Komplexität und Fehlerrisiko: S / niedrig. Offen ist nur der Zeitpunkt.
- Offene Entscheidungen:
  1. Zeitpunkt: nach vollständiger Morgenauflösung (nach allen Reaktionen) oder vor den Toten?
  2. Nur wenn ein Wolf/Solo direkt oder nächster lebender Nachbar ist?
  3. Zählt ein nur "als Wolf erscheinender" Spieler (Dämonischer-Wolf-Fluch)?
  4. Wird angesagt, welche Seite (links/rechts) oder nur "Alarm"?
- Relevante Testgruppen:
  - Normalfall: Nachbar rechts Werwolf → ein Public-Ereignis am Morgen.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: direkter Nachbar tot, übernächster Wolf → Alarm (Legacy).
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Nachtwächter → heute nur erster; Soll je Kopie.
  - Wiederbelebung: toter Nachtwächter wiederbelebt → ab nächstem Morgen aktiv.
  - Rollenwechsel: Nachbar wird Wolf (Wolfskind) → nächster Morgen Alarm.
  - Save/Load: Save zwischen Nachtende und Morgen → Alarm genau einmal.
  - Replay: Alarm-Ereignis bytegleich.
  - SL-Korrektur: Korrektur eines Nachbarn → Alarm neu berechnen oder nicht (festlegen).
  - Sichtbarkeit: Ereignis public, Identität der Nachbarn nicht öffentlich.
  - Schutz: nicht relevant, weil keine Tötung.
  - Todesreaktionen: nicht relevant, außer Zeitpunkt nach Reaktionen.
  - Siegprüfung: nicht relevant.
  - beschädigter Spielstand: fehlende Sitze → kein Absturz.
- Belegsicherheit: hoch.

### die-gebundenen
- DE-Name / EN-Name: Die Gebundenen / The Bound (`roles:140`)
- Aliase/Altnamen: i18n `gebundenFirstNight`, `noLivingBound` (`i18n:195,302,524,626`), Laufzeitübersetzung `i18n:773,873`; Bilder `Die_Gebundenen.webp`, `The_Bound.webp` (`gh:814`, `roleCard.ts:22`).
- Legacy-ID: `"Die Gebundenen"` (`roles:1`, Index 2)
- Fraktion: `dorf`. Einzige Rolle der Gruppe mit mehreren Kopien: max 6 (`gh:866`, `setup.html:796`).
- Akte: Akt I (`akte.js:16`).
- Nachtpriorität und Bedingungen: tier 0.5, `once:true` (`roles:7`); Zeile solange ein Gebundener lebt und `role_Die_Gebundenen` unverbraucht ist.
- Quelltextstellen:
  - `chunk:142-155` `abilities["Die Gebundenen"]` – listet alle LEBENDEN Sitze mit Rolle "Die Gebundenen" per `center`, dann `markOnceUsed`.
  - `ab:72` – Akteure per `filter`, gemeinsame Zeile für alle Kopien.
- Text DE (wörtlich): `Wacht in der ersten Nacht auf und lernt alle anderen Gebundenen kennen.` (`roles:66`)
- Text EN (wörtlich): `Wake in night 1 and learn all other Bound players.` (`roles:215`)
- DE/EN-Vergleich: JA. Zeitpunkt Nacht 1, Ziel alle anderen Gebundenen in beiden. (DE Singular "Wacht", EN Plural-Imperativ: ohne Bedeutungsunterschied.)
- Weitere Texte: `role-abilities.js:10` identisch. Meldung sagt immer "Erste Nacht" (`i18n:302`), auch wenn der Schritt in einer späteren Nacht läuft.
- Legacy-Codeverhalten:
  1. Zeitpunkt: tier 0.5, einmal pro Partie; nicht auf Nacht 1 begrenzt (klickt der SL in Nacht 1 nicht, erscheint die Zeile in Nacht 2 erneut).
  2. Ziele: keine Wahl; Anzeige aller lebenden Gebundenen einschließlich der Akteure selbst.
  3. Tote Gebundene werden nicht angezeigt; lebt keiner: "Keine lebenden Gebundenen" ohne Verbrauch.
  4. Verbrauch: `markOnceUsed` nach Anzeige.
  5. Keine Zustandsänderung, kein Sieg, kein Zufall.
  6. Blockaden `ab:94-99` gelten (Schattenhund, Debuff, Albtraum) und verbrauchen NICHT.
  7. Sichtbarkeit: SL-Center-Anzeige (SL zeigt/ruft auf).
- React-Version: kein eigenes Verhalten.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 3: "verifiziert", `chunk:142-155`. Bestätigt, Zeilen stimmen. Ergänzung: nicht streng Nacht 1, tote Gebundene fehlen.
  - 01 `:223` "Handler nehmen seats.find(role) an": trifft auf diesen Handler NICHT zu (er nutzt `filter`).
  - NIGHT-REPORT-abilities.md:56 (React-Anzeige ❌): durch `domMirror.ts` vermutlich überholt, nicht verifiziert.
- Widersprüche: keine belegten Widersprüche. (Grenzfall "erste Nacht" vs. "einmal pro Partie" siehe Offene Entscheidungen.)
- Bugs:
  - B-GEB-1 (technische Altlast): Anzeige-Text "Erste Nacht" (`i18n:302`) bei verspätetem Aufruf falsch. Risiko niedrig. Test: Schritt in Nacht 1 übersprungen → Soll: Schritt entfällt ab Nacht 2 (oder Text korrekt).
- Legacy-Status: legacy-verified. Code zeigt die Gebundenen einmalig an; Abweichungen nur bei SL-Versäumnis.
- Automationsvorschlag: automatic.
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Einmalfähigkeit.
- Benötigte vorhandene Godot-Systeme: StepQueue (nur Nacht 1), InfoRecord, Ereignis-Sichtbarkeit (actor), StateCodec, Replay.
- Benötigte NEUE Systeme: keine; falls `max_copies` in Godot noch fehlt, Mehrfachrollen in RoleDef (in `03` bereits vorgesehen, `03:199`).
- Abhängigkeiten von anderen Rollen: Schattenhund/Albtraumwolf (Blockade in Nacht 1), Lehrling (erbt "Die Gebundenen" nach Nacht 1: sieht nie jemanden).
- Komplexität und Fehlerrisiko: S / niedrig.
- Offene Entscheidungen:
  1. Strikt nur Nacht 1 (entfällt danach) oder nachholbar?
  2. Sehen Gebundene auch bereits tote Gebundene?
  3. Was passiert bei nur einem Gebundenen (Schritt entfällt oder "du bist allein")?
  4. Wird die Blockade in Nacht 1 (Schattenhund) verbraucht, ohne Info?
- Relevante Testgruppen:
  - Normalfall: 3 Gebundene → ein Info-Record mit 3 IDs, Sichtbarkeit actor.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: ein Gebundener vor Nacht 1 tot (Setup-Korrektur) → nicht gelistet (Legacy).
  - Selbstwahl: nicht relevant.
  - mehrere Kopien: 6 Kopien → ein gemeinsamer Schritt.
  - Wiederbelebung: nicht relevant nach Nacht 1.
  - Rollenwechsel: Lehrling erbt die Rolle → kein Schritt mehr.
  - Save/Load: Save vor/nach dem Schritt → Schritt genau einmal.
  - Replay: bytegleich.
  - SL-Korrektur: Rolle nachträglich auf Gebundene gesetzt → kein neuer Schritt.
  - Sichtbarkeit: Namen nur actor/gm.
  - Schutz: nicht relevant.
  - Todesreaktionen: nicht relevant.
  - Siegprüfung: nicht relevant.
  - beschädigter Spielstand: `once.Used` fehlt → Schritt einmal.
- Belegsicherheit: hoch.

### die-ewigen
- DE-Name / EN-Name: Die Ewigen / The Eternal Ones (`roles:146`)
- Aliase/Altnamen: i18n `eternalsYes`, `eternalsNo` (`i18n:228-229,557-558`); Bilder `Die_Ewigen.webp`, `The_Eternal_Ones.webp` (`gh:816`, `roleCard.ts:28`).
- Legacy-ID: `"Die Ewigen"` (`roles:1`, Index 8)
- Fraktion: `dorf`. Max 1 Kopie (`gh:863-867`), obwohl Name und Text im Plural stehen.
- Akte: Akt II (`akte.js:36`).
- Nachtpriorität und Bedingungen: tier 4.8, nicht once (`roles:36`); jede Nacht, wenn lebend. Früher im Passiv-Set (Bericht L7), heute entfernt (Kommentar `night:95`, Set `night:96` ohne Ewige). Blockaden `ab:94-99`.
- Quelltextstellen:
  - `chunk:253-260` `abilities["Die Ewigen"]` – `pick` OHNE Filter; `SOLO_WIN_ROLES.has(t.role)` → "✅ JA" + Rollenname, sonst "❌ Nein".
  - `roles:399-403` `SOLO_ROLES_SET` – Grundlage der Prüfung.
  - Siegcode: keiner (rg "Ewig"/"eternal" in `core.js`, `gh`: kein Siegbezug).
- Text DE (wörtlich): `Prüfen jede Nacht ob ein Spieler eine Solo-Siegbedingung hat (U+2014) und gewinnen gemeinsam mit ihm.` (`roles:72`)
- Text EN (wörtlich): `Each night check whether a player has a solo win condition (U+2014) and win together with them.` (`roles:221`)
- DE/EN-Vergleich: JA. Häufigkeit (jede Nacht), Ziel (ein Spieler), Mitsieg in beiden.
- Weitere Texte: `role-abilities.js:9` identisch.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht, tier 4.8.
  2. Ziel: beliebiger Sitz, auch tote Sitze und die Ewigen selbst (`pick` ohne `allow`, `ui:325`).
  3. Ergebnis: bei Solo-Rolle "✅ JA" PLUS der exakte Rollenname (`chunk:256`); sonst "❌ Nein".
  4. Prüfung nach Rollenname, nicht nach Fraktionszustand (z.B. Rachsüchtiger Wolf zählt nicht als Solo).
  5. Kein Zustand gespeichert, kein Verbrauch, kein Zufall, keine Mitsieg-Logik.
  6. Mehrfachnutzung pro Nacht möglich (Zeile erneut klicken).
- React-Version: kein eigenes Verhalten.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 9: "fehlend", `chunk:253-260` "nur Prüfung", "gewinnen gemeinsam fehlt". Bestätigt. Ergänzung: Ergebnis enthüllt den Rollennamen; tote Ziele erlaubt.
  - 04 D-5 und 07 Q4: Mitsieg fehlt, bestätigt.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` L7 ("unerreichbar, im Passiv-Filter"): widerlegt für den heutigen Stand (`night:95-96`).
  - DECISION-LOG DR-02/Siegkandidaten (Z.206): Mitsieg ist dort nicht vorgesehen (genau ein Kandidat wird bestätigt).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Mitsieg | "gewinnen gemeinsam mit ihm" | "win together with them" | nicht vorhanden | nicht vorhanden | 04 fehlend, 07 Q4 | Ewige gewinnen mit jedem gefundenen Solo, wenn dieser gewinnt | Ewige gewinnen mit dem Solo, den sie zuletzt/zuerst gefunden haben | hoch (Dorfrolle wechselt faktisch Siegseite) | WinCandidate muss Mitsieger tragen; widerspricht "genau ein Kandidat" | Regel festlegen, Mitsieg als Zusatz-Gewinner am Kandidaten | Ja |
| Info-Umfang | "prüfen ob ... Solo-Siegbedingung" | "check whether" | zeigt Ja + Rollennamen | wie Legacy | nicht erwähnt | nur Ja/Nein | Ja + Rolle | Rollenname ist Orakel-starke Info | InfoRecord-Inhalt | nur Ja/Nein | Ja |
| Siegseite der Ewigen | Dorf-Akte, Fraktion dorf | dito | `getRoleFaction` = dorf, zählt in Parität als Nicht-Wolf | wie Legacy | – | Ewige bleiben Dorf und gewinnen zusätzlich mit Solo | Ewige verlassen das Dorf, sobald Solo gefunden | mittel | Fraktionswechsel oder Zusatzsieg | PO | Ja |

- Bugs:
  - B-EW-1 (unklare Regel): tote Sitze und Selbstwahl erlaubt (`chunk:253` ohne `allow`). Test: Ewige wählen Toten → Soll festlegen (Legacy: erlaubt).
  - B-EW-2 (echter Bug gegenüber Text): Info enthält Rollennamen (`chunk:256`), Text verspricht nur die Prüfung. Risiko mittel (Informationsleck). Test: Ziel Hades → Ergebnis enthält nur `true`.
- Legacy-Status: not-found. Die Prüfung existiert, aber die definierende Mechanik "gewinnen gemeinsam" existiert im Code nicht.
- Automationsvorschlag: assisted. Info automatisch; Mitsieg erst nach PO-Regel, bis dahin SL bestätigt.
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Einzelsieg (Mitsieg mit Solo).
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt, InfoRecord, WinRules/WinCandidate, Ereignis-Sichtbarkeit, StateCodec, Replay.
- Benötigte NEUE Systeme: zusätzliche Siegbedingungen (Mitsieg-Kandidaten); Besuchs-/Zielhistorie (welche Solos wurden gefunden), falls der Mitsieg an einen gefundenen Solo gebunden wird.
- Abhängigkeiten von anderen Rollen: alle 14 Solo-Rollen (`roles:399-403`), insbesondere solche ohne Siegcode (Prophet, Feuerteufel, Voodoo, Grabräuber: 07 Q4); Lehrling/Seelentauscher (Solo-Rolle wechselt Person).
- Komplexität und Fehlerrisiko: M / mittel. Info trivial, Mitsieg berührt WinRules.
- Offene Entscheidungen:
  1. Wann gewinnen die Ewigen mit: mit jedem Solo, den sie je positiv geprüft haben, oder mit jedem Solo-Sieger überhaupt?
  2. Müssen die Ewigen zum Siegzeitpunkt leben?
  3. Nur Ja/Nein oder auch Rollenname?
  4. Tote Ziele und Selbstprüfung erlaubt?
  5. Verlieren die Ewigen mit dem Dorf, wenn sie einen Solo gefunden haben?
- Relevante Testgruppen:
  - Normalfall: Ziel Pestbringerin → InfoRecord true; Ziel Dorfbewohner → false.
  - ungültiges Ziel: Selbstwahl → nach Entscheidung abgelehnt.
  - tote Person: toter Solo → nach Entscheidung.
  - Selbstwahl: siehe oben.
  - mehrere Kopien: nicht relevant (max 1), außer Erbe.
  - Wiederbelebung: nicht relevant.
  - Rollenwechsel: Lehrling erbt Solo nach Prüfung → Mitsieg-Bindung festlegen.
  - Save/Load: gefundene Solos bleiben erhalten.
  - Replay: bytegleich.
  - SL-Korrektur: Prüfergebnis korrigieren.
  - Sichtbarkeit: Ergebnis actor.
  - Schutz: nicht relevant.
  - Todesreaktionen: nicht relevant.
  - Siegprüfung: Solo gewinnt → Kandidat enthält Ewige als Mitsieger.
  - beschädigter Spielstand: gefundene Solo-ID fehlt → kein Mitsieg, kein Absturz.
- Belegsicherheit: hoch für Code; Mitsieg-Regel nicht bestimmbar.

### spuerhund
- DE-Name / EN-Name: Spürhund / Scent Hound (`roles:147`)
- Aliase/Altnamen: `Fuchs` → `Spürhund` (`state:18`, `once.FuchsRetired` wird gelöscht `state:22`); `meta.fakeWolfSignal` = "falsche Spur"; i18n `scentTrailFound`, `scentTrailNone` (`i18n:242-243,515-516`); Bilder `Spürhund.webp`, `Scent_Hound.webp` (`gh:817`, `roleCard.ts:29`).
- Legacy-ID: `"Spürhund"` (`roles:1`, Index 9)
- Fraktion: `dorf`.
- Akte: Akt I (`akte.js:17`).
- Nachtpriorität und Bedingungen: tier 6.8, nicht once (`roles:46`); jede Nacht bei lebendem Spürhund. Blockaden `ab:94-99`.
- Quelltextstellen:
  - `chunk:262-287` `abilities.Spürhund` – `startMulti` 3 lebende Sitze; Treffer, wenn ein Gewählter `meta.fakeWolfSignal` hat oder `getFaction(role)` wolf/solo ist; sonst `Math.random` über ALLE Lebenden → `fakeWolfSignal=true`.
  - `night:9-11` `getFaction` → `getRoleFaction` (nur Rollenname, `roles:405-409`).
  - rg `fakeWolfSignal`: nur `chunk:267,279`; nie zurückgesetzt (außer Kutscher-Wiederbelebung ersetzt `meta`, `chunk:850`).
- Text DE (wörtlich): `Wähle 3 Spieler. ✅ wenn einer Wolf, Solo oder falsche Spur ist (U+2014) sonst ❌. Bei ❌ wird heimlich ein Spieler als falsche Spur markiert.` (`roles:73`)
- Text EN (wörtlich): `Choose 3 players. ✅ if one is a wolf, solo, or false lead (U+2014) otherwise ❌. On ❌, a random player is secretly marked as a false lead.` (`roles:222`)
- DE/EN-Vergleich: NEIN (gering). EN sagt "a random player", DE nur "ein Spieler" (Auswahlverfahren offen, z.B. SL-Wahl). Sonst gleich (3 Ziele, Kriterien, geheim).
- Weitere Texte: `role-abilities.js:34` identisch. Ergebnis-Texte "✅ Eine Spur führt zu einem Wolf oder etwas anderem …" (`i18n:242`) unterscheiden nicht zwischen Wolf/Solo/falscher Spur (passt zum Text).
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht, tier 6.8.
  2. Ziele: genau 3 verschiedene lebende Sitze; Selbstwahl erlaubt; tote nicht wählbar.
  3. Treffer-Kriterium: Rollenname in WOLF_ROLES_SET oder SOLO-Set, oder falsche Spur. NICHT `isWolf`: verwandeltes Wolfskind (`flags.werewolf`, Rolle bleibt "Wolfskind", `core:387-388`) und Verfluchte (`cursedWolfAura`) gelten als Dorf.
  4. Bei ❌: zufälliger lebender Sitz (`Math.random`, `chunk:276`), inkl. Spürhund selbst, der drei Gewählten, echter Wölfe; bereits markierte können erneut gezogen werden.
  5. Falsche Spur ist dauerhaft und kumulativ (jede ❌-Nacht eine weitere).
  6. Sichtbarkeit: Ergebnis per SL-Center; Markierung geheim, ohne Anzeige, wer markiert wurde (SL sieht es nicht; kein Marker in `ui:109` `markerList`, nicht verifiziert für Pixi-Feld).
  7. Mehrfachnutzung pro Nacht möglich (Zeile erneut anklicken), jede ❌ markiert erneut.
  8. Mehrere Kopien: max 1.
- React-Version: kein eigenes Verhalten.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 10: "verifiziert", "Math.random, Golden nicht möglich". Teilweise widerlegt: Kriterium weicht bei verwandelten Wölfen vom autoritativen `isWolf` ab (Konvention in `CLAUDE.md`: Wolf-Zugehörigkeit nur über `isWolf`); Markierung kumulativ und trifft auch Wölfe/Spürhund selbst.
  - ROLE-FLOW-REPORT.md:22 "funktioniert": bestätigt für den Normalfall.
  - `GRIMMHAIN_ANALYSE_2026-06-12.md:219` E3 (EN ohne falsche Spur): überholt, EN enthält sie heute (`roles:222`).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Wer wird falsche Spur | "ein Spieler" | "a random player" | Zufall über alle Lebenden | wie Legacy | 04: zufälliger Spieler (Seed) | Zufall (SeededRng) | SL wählt | Zufall kann Spürhund selbst oder echte Wölfe treffen (dann wirkungslos) | Rng-Aufruf vs. Prompt | Zufall über lebende Nicht-Wolf/Nicht-Solo außer Spürhund, per SeededRng | Ja |
| Was ist "Wolf" | "Wolf" | "wolf" | Rollenname-Fraktion | wie Legacy | 04 verifiziert | wie `isWolf` (inkl. verwandelte) | nur Rollenname | verwandeltes Wolfskind unsichtbar | FactionQuery statt Rollenname | `isWolf`-Äquivalent | Nein (Konvention) |

- Bugs:
  - B-SH-1 (echter Bug gemessen an Konvention `CLAUDE.md` "Wolf-Zugehörigkeit NUR über WOLF_ROLES_SET + flags.werewolf"): `chunk:268` nutzt `getFaction(s.role)` statt `isWolf`. Tatsächlich: verwandeltes Wolfskind ergibt ❌. Erwartet: ✅. Risiko mittel. Test: Wolfskind mit totem Vorbild (`flags.werewolf=true`) unter 3 Zielen → true.
  - B-SH-2 (unklare Regel): Markierung kann Spürhund selbst, bereits markierte oder echte Wölfe treffen (`chunk:274-276`). Test mit festem Seed: Ergebnis-ID deterministisch und aus erlaubter Menge.
  - B-SH-3 (technische Altlast): `Math.random` statt Seed; erneutes Öffnen würfelt neu. Test: Replay bytegleich.
- Legacy-Status: legacy-contradictory. Normalfall setzt den Text um; die Wolf-Definition weicht vom autoritativen `isWolf` ab und die Markierungsregel ist offen (DE/EN verschieden).
- Automationsvorschlag: automatic (mit SeededRng).
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Fehlinformation, Zufallsmechanik.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (3 Ziele), SeededRng, InfoRecord, appears_as (falls Erscheinung zählen soll), StateCodec, Replay.
- Benötigte NEUE Systeme: dauerhafte Statusmarker (falsche Spur, pro Person, Quelle Spürhund).
- Abhängigkeiten von anderen Rollen: Wolfskind, Dämonischer Wolf (Fluch), Trugbilderwolf (Wolfsrolle), alle Solos, Lehrling/Seelentauscher (Rollenname wechselt).
- Komplexität und Fehlerrisiko: M / mittel.
- Offene Entscheidungen:
  1. Falsche Spur zufällig oder SL-Wahl? Aus welcher Menge (ohne Spürhund, ohne Wölfe/Solos, ohne bereits markierte)?
  2. Bleibt die Markierung dauerhaft? Kumulativ?
  3. Zählt ein Verfluchter (Dämonischer Wolf) als Wolf?
  4. Selbstwahl unter den 3 erlaubt?
- Relevante Testgruppen:
  - Normalfall: Ziele enthalten Werwolf → true, keine Markierung.
  - ungültiges Ziel: nur 2 Ziele bestätigt → abgelehnt.
  - tote Person: tote Sitze nicht wählbar.
  - Selbstwahl: nach Entscheidung.
  - mehrere Kopien: nicht relevant (max 1).
  - Wiederbelebung: markierte Person stirbt und wird wiederbelebt → Markierung bleibt/fällt (festlegen; Legacy: Frankenstein behält, Kutscher löscht).
  - Rollenwechsel: Wolfskind verwandelt → true (B-SH-1).
  - Save/Load: Markierung und Rng-Zustand überleben.
  - Replay: gleicher Seed → gleiche markierte ID.
  - SL-Korrektur: Markierung entfernen.
  - Sichtbarkeit: Ergebnis actor, Markierung gm.
  - Schutz: nicht relevant.
  - Todesreaktionen: nicht relevant.
  - Siegprüfung: nicht relevant.
  - beschädigter Spielstand: Markierung auf fehlender ID → ignoriert.
- Belegsicherheit: hoch für Handler; Anzeige der Markierung im Pixi-Feld nicht verifiziert.

### der-weise
- DE-Name / EN-Name: Der Weise / The Elder (`roles:152`)
- Aliase/Altnamen: `Der Alte` → `Der Weise` (`state:18`), `once.DerAlteFirstAttackUsed` → `DerWeiseFirstAttackUsed` (`state:27-28`); `once.OldDebuff` (Debuff-Zähler); i18n `elderLynchDaysQuestion`, `elderLynchDayOne`, `elderLynchDaysN`, `oldDebuff` (`i18n:221,252-254,550,576-578`), "Der Weise wurde gelyncht" (`i18n:792,857`); Bilder `Der_Weise.webp`, `The_Elder.webp` (`gh:821`, `roleCard.ts:40`).
- Legacy-ID: `"Der Weise"` (`roles:1`, Index 21)
- Fraktion: `dorf`.
- Akte: Akt I-IV (`akte.js:16,37,58,79`).
- Nachtpriorität und Bedingungen: nicht in ORDER_BASE, im Passiv-Set (`night:96`). Wirkt in der Morgenauflösung und im Lynch.
- Quelltextstellen:
  - `night:354-364` `resolveDayKills.processOne` – erster Eintrag des Weisen in `nightTargets` ohne Durchschlag (Seuchenwolf/Rudelvater) setzt globales `once.DerWeiseFirstAttackUsed`, löscht `targeted`, kein Tod, keine Meldung.
  - `night:334` – blockierte (`blockedTonight`) Ziele werden vorher entfernt.
  - `night:450-473` `doLynchFlow` Zweig "Der Weise" – SL wählt 1/2/3 → `once.OldDebuff=days`, `applyKill(target,"LYNCH")`, Kopfgeldjäger bei `isWolf`, `finalizeLynch`, `postDeathHooks`.
  - `ab:96` `onOrderClick` – solange `OldDebuff>0`: jede Nachtzeile außerhalb `WOLF_ROLES_SET` gesperrt.
  - `night:232` `onDayStart` – `OldDebuff--` je Morgen.
  - `night:145` `onNightStart` – Der Weise behält `flags.protected` und `protectedCount` über Nächte (`keepP`), alle anderen verlieren Schutz.
  - `gh:450` `savePop`, `gh:646` `selectRole` – Rollenwechsel auf "Der Weise" setzt `flags.protected=true`.
  - `chunk:162` `abilities.Werwolf` – geschütztes Ziel: Schutz verbraucht, nicht `targeted`.
  - `app/src/adapter/legacy/legacyAdapter.ts:572` `setPlayerRole`, `:666-667` `startGame` – React setzt `flags.protected=true` für jeden Weisen.
  - `gh:522-525` `clearRolesNewRound` – setzt `DerWeiseFirstAttackUsed=false`, `OldDebuff=0`.
- Text DE (wörtlich): `Du überlebst dank deines Wissens und deiner Vorbereitung den ersten Werwolfangriff. Sollte das Dorf dich jedoch lynchen, verlieren diese 1–3 Nächte und Tage lang ihre Fähigkeiten.` (`roles:78`)
- Text EN (wörtlich): `Thanks to your knowledge and preparation, you survive the first werewolf attack. However, if the village lynches you, they lose their abilities for 1–3 nights and days.` (`roles:227`)
- DE/EN-Vergleich: JA. Erster Werwolfangriff, Lynch durch Dorf, 1-3 Nächte und Tage, "diese"/"they" = das Dorf.
- Weitere Texte: `role-abilities.js:7` identisch. SL-Frage "Wie viele Tage verlieren die Dorfbewohner ihre Fähigkeiten?" (`i18n:252`) nennt nur Tage.
- Legacy-Codeverhalten:
  1. Erstangriff: der erste Morgen, an dem der Weise in `nightTargets` steht (Werwolf-Ziel, Ziel des Rachsüchtigen Wolfs, Schicksalswolf-Extra, manueller 🎯-Chip), rettet ihn einmal pro Partie. Stille Rettung, keine Anzeige.
  2. Durchschlag: Seuchenwolf-Pierce oder Rudelvater-Extra (`night:358`) töten ihn, ohne die Rettung zu verbrauchen.
  3. Sofortkills (Waldhexe-Gift, Verdammniswächter, Hades usw.) laufen über `applyKill` und ignorieren die Rettung.
  4. Flag global (`once.DerWeiseFirstAttackUsed`), nicht pro Person: eine zweite Weise-Kopie (Erbe/Frankenstein) hätte keine Rettung mehr; max 1 Kopie im Setup.
  5. Doppelschutz (F10): Wird die Rolle per Popup/Rollenwähler (Selbstverteilung: `setup.html:1139-1149` setzt bei `random=false` keine Rollen, der SL vergibt sie in `game.html`) oder in React gesetzt, trägt der Weise zusätzlich `flags.protected`; der erste Werwolf-Pick verbraucht diesen Schutz (kein `targeted`), der zweite Angriff verbraucht dann `DerWeiseFirstAttackUsed` → zwei überlebte Angriffe. Bei Zufallsverteilung (`random=true`) nur einer.
  6. Schutz-Persistenz: `keepP` (`night:145`) gilt für JEDEN Schutz auf dem Weisen, auch Schutzengel (`chunk:159`) und Schutzgeist (`chunk:498`); `protectedCount` akkumuliert über Nächte → beliebig viele gestapelte Rettungen.
  7. Lynch: SL wählt 1, 2 oder 3; Weise stirbt mit `LYNCH`; `OldDebuff=n`.
  8. Debuff-Wirkung: sperrt in `onOrderClick` alle Nachtzeilen, deren Rollenname nicht in WOLF_ROLES_SET liegt: Dorf UND Solo, auch eine verwandelte Dorf-Rolle mit `flags.werewolf`. Werwolf-Rudelzeile und Wolfsrollen bleiben aktiv. Passive Fähigkeiten (Nachtwächter, Kutscher-Lynch, Sensenträger-Reaktion) und Tag-Buttons (z.B. Nekromant `gh:531-557`) sind nicht gesperrt.
  9. Dauer: Lynch am Tag D, Zähler n; jede `onDayStart` zählt −1 → genau n Nächte gesperrt; "Tage" sind faktisch nicht betroffen.
  10. Zufall: keiner (SL wählt die Dauer).
  11. Sichtbarkeit: Debuff-Meldung bei Klick auf gesperrte Zeile (SL); Lynch-Dialog SL.
  12. Sieg: normale Siegprüfung über `applyKill`.
- React-Version: JA, eigene Daten: `legacyAdapter.ts:666-667` setzt beim Spielstart jedem Weisen `flags.protected=true` ("savePop parity"), `:572` beim Rollenwechsel. Folge: in React immer Doppelrettung (siehe Bug).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 22: "widersprüchlich (Bug F10)", `night:359-364`, Lynch `night:450-473`. Bestätigt, Zeilen stimmen. Ergänzungen: React-Startpfad immer betroffen; Schutzengel-Persistenz; Debuff sperrt auch Solos und nur Nächte.
  - 01 F10 (`gh:450,646`, `night:145`, `night:359-364`): bestätigt.
  - 04 B-6 (Debuff "für Nicht-Wölfe inkl. Solos", `ab:94-99`): bestätigt (`ab:96`).
  - 07 Q1: "per Popup doppelt, Text (Bug beheben)": bestätigt.
  - DECISION-LOG DR-05: Schutzengel-Schutz gilt nur eine Nacht und wird erst morgens angewandt → Legacy `keepP` widerspricht (Schutz auf dem Weisen hält über Nächte).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` L5 (Weise-Pfad zählt LynchCount/Henker): bestätigt, `finalizeLynch` läuft (`night:463`).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Anzahl Rettungen | "den ersten Werwolfangriff" | "the first werewolf attack" | 1 (Zufallsverteilung) oder 2 (Popup/React) | immer 2 | 04/07: Bug | genau einmal | – | Weiser deutlich zu stark | Rettung als eigene Schutzregel, kein `flags.protected` | genau einmal | Nein |
| Wer verliert Fähigkeiten | "das Dorf ... diese" | "the village ... they" | alle Nicht-WOLF_ROLES_SET-Zeilen inkl. Solo | wie Legacy | 04 B-6: inkl. Solos | nur Dorf-Fraktion | alle Nicht-Wölfe | Solos werden mitbestraft | FactionQuery-Filter | nur Dorf | Ja |
| Dauer "Nächte und Tage" | "1–3 Nächte und Tage" | "1–3 nights and days" | nur n Nächte (Nachtzeilen) | wie Legacy | – | Sperre gilt auch für Tagfähigkeiten | nur Nächte | gering bis mittel | Tagesaktionen brauchen Blockprüfung | Nacht und Tag | Ja |
| Wer wählt 1-3 | "1–3" | "1–3" | SL wählt | wie Legacy | 04: SL wählt | SL | Zufall | gering | Prompt vs. Rng | SL (wie Code) | Nein |
| Durchschlag | "ersten Werwolfangriff" | "first werewolf attack" | Seuchenwolf/Rudelvater töten ohne Verbrauch | wie Legacy | – | Durchschlag tötet | Rettung greift trotzdem | gering | Filter in Protections | wie Code | Ja |
| Passive Fähigkeiten im Debuff | "ihre Fähigkeiten" | "their abilities" | nur Nachtzeilen gesperrt | wie Legacy | – | auch passive (Nachtwächter, Kutscher) | nur aktive | mittel | Blockmarker in Reaktionen | PO | Ja |

- Bugs:
  - B-WE-1 (echter Bug, F10): `gh:450`, `gh:646`, `legacyAdapter.ts:572,666-667` + `night:145` + `chunk:162` + `night:359-364`. Tatsächlich: zwei überlebte Wolfsangriffe bei Popup-Vergabe und in React immer. Erwartet: genau einer. Risiko hoch. Test: Weiser, zwei Nächte Wolfsziel → Nacht 1 überlebt, Nacht 2 stirbt; unabhängig vom Vergabeweg.
  - B-WE-2 (echter Bug gegenüber DR-05): `night:145` `keepP` hält jeden Schutz auf dem Weisen über Nächte und stapelt `protectedCount`. Tatsächlich: Schutzengel-Schutz aus Nacht 1 rettet in Nacht 5. Erwartet: Schutz nur für die Nacht. Risiko mittel. Test: Schutzengel schützt Weisen N1, keine Attacke; N2 Angriff (Rettung schon verbraucht) → stirbt.
  - B-WE-3 (unklare Regel): Debuff sperrt Solos und nur Nachtzeilen (`ab:93-96`). Test: Debuff aktiv → Pestbringerin-Schritt nach Entscheidung erlaubt/gesperrt; Tagesaktion nach Entscheidung.
  - B-WE-4 (technische Altlast): globales Flag statt pro Person (`night:359-360`). Test: zwei Weise (Erbe) → jeder eigene Rettung (nach Entscheidung).
- Legacy-Status: legacy-broken. Ein belegter Codefehler (Doppelschutz über `flags.protected`, in React immer aktiv; dazu Schutz-Persistenz) verfälscht die Kernfunktion "überlebt den ersten Werwolfangriff".
- Automationsvorschlag: automatic (Rettung und Debuff-Zähler); Dauerwahl als SL-Prompt.
- Mechanikfamilie primär + sekundär: Wolfsangriff-Modifikation; sekundär Hinrichtungsreaktion, globale Regeländerung.
- Benötigte vorhandene Godot-Systeme: Protections (Filter: nur Rudel-NIGHT_KILL, einmalig), KillPipeline, ExecutionRules (Hinrichtungsreaktion), PendingPrompt (1-3), StepQueue (Schritte überspringen mit Grund), Ereignis-Sichtbarkeit, GmCorrections, StateCodec, Replay.
- Benötigte NEUE Systeme: Rollenblockierung (Fraktionsfilter), zeitlich verzögerte Effekte / globale Modifikatoren (Zähler über n Nächte/Tage); ggf. Tagesaktionswarteschlange mit Blockprüfung, falls "Tage" gelten.
- Abhängigkeiten von anderen Rollen: Werwolf, Rachsüchtiger Wolf, Schicksalswolf, Seuchenwolf, Rudelvater (Durchschlag), Schutzengel/Schutzgeist (Stapelung), Albtraumwolf (Blockade entfernt Ziel), Märtyrerin, Verdammniswächter (umgeht Rettung), Waldhexe; Debuff betrifft alle Nicht-Wolf-Rollen.
- Komplexität und Fehlerrisiko: M / hoch. Viele Interaktionen, Legacy-Verhalten hängt vom Vergabeweg ab.
- Offene Entscheidungen:
  1. Zählt als "Werwolfangriff" auch Rachsüchtiger Wolf, Schicksalswolf-Extra, Rudelvater-Extra?
  2. Durchschlag (Seuchenwolf/Rudelvater): tötet oder verbraucht die Rettung?
  3. Debuff: nur Dorf-Fraktion oder alle Nicht-Wölfe? Auch passive Fähigkeiten und Tagesaktionen?
  4. Zählweise: n Nächte und n Tage ab Lynch-Tag oder ab nächster Nacht?
  5. Wird die Rettung angesagt oder bleibt sie still?
- Relevante Testgruppen:
  - Normalfall: Wolfsziel Weiser N1 → lebt; N2 → stirbt.
  - ungültiges Ziel: nicht relevant (keine Zielwahl), Dauer außerhalb 1-3 → abgelehnt.
  - tote Person: nicht relevant.
  - Selbstwahl: nicht relevant.
  - mehrere Kopien: zwei Weise → Rettung je Person (Entscheidung).
  - Wiederbelebung: Weiser wiederbelebt → Rettung bleibt verbraucht (festlegen).
  - Rollenwechsel: Lehrling erbt Weisen → frische Rettung (DR-11 "zurückgesetzte Nutzungen").
  - Save/Load: Save nach Rettung → Load → zweiter Angriff tötet.
  - Replay: bytegleich inkl. Debuff-Zähler.
  - SL-Korrektur: Hinrichtung des Weisen per Korrektur → Debuff-Prompt läuft (DR-Vertical-Slice Z.131).
  - Sichtbarkeit: Rettung gm, Debuff public (Dorf muss es wissen).
  - Schutz: Schutzengel + Rudelangriff → nur ein verhinderter Angriff, Rettung bleibt oder nicht (festlegen).
  - Todesreaktionen: gelynchter Weiser + Liebender → Kette, Debuff gilt.
  - Siegprüfung: Lynch des Weisen macht Parität → Sieg vor Debuff-Relevanz.
  - beschädigter Spielstand: `OldDebuff` negativ/fehlend → 0.
- Belegsicherheit: hoch. Nicht im Browser verifiziert, ob React-Pfad heute alle Spielstarts über `startGame` führt.

### verdammniswaechter
- DE-Name / EN-Name: Verdammniswächter / Doom Warden (`roles:153`)
- Aliase/Altnamen: i18n `doomGuardianChoice`, `doomGuardianDies` (`i18n:259,305,583,629`); Todesursache `VERDAMMNISWAECHTER` (Label `ui:413`); Bilder `Verdammniswächter.webp`, `Doom_Warden.webp` (`gh:822`, `roleCard.ts:41`).
- Legacy-ID: `"Verdammniswächter"` (`roles:1`, Index 22)
- Fraktion: `dorf` (nicht in WOLF_ROLES_SET), steht aber in der Wolfsphase (tier 2.3). Akte führen ihn als DORF (`akte.js:35,78`).
- Akte: Akt II, Akt IV.
- Nachtpriorität und Bedingungen: tier 2.3, nicht once (`roles:19`); jede Nacht bei lebendem Verdammniswächter; Zeile mit Dorf-Icon (`night:98-100`). Blockaden `ab:94-99` gelten (Nicht-Wolf).
- Quelltextstellen:
  - `chunk:726-736` `abilities["Verdammniswächter"]` – `v=seats.find(targeted && !dead)`; Pool = lebende Nicht-Wölfe (`isWolf`) außer v; `rnd` per `Math.random`; zwei Knöpfe: b1 tötet v, b2 tötet rnd und hebt `v.targeted` auf; beide `applyKill(...,"VERDAMMNISWAECHTER")` sofort + `postDeathHooks`.
  - `chunk:162` – geschütztes Wolfsziel wird nie `targeted` → Verdammniswächter meldet "Kein Opfer gesetzt".
  - `core:104-143` – `applyKill`-Schilde greifen trotz "umgeht alle Schutzfähigkeiten".
  - `core:430-431` `applyRitterRetaliationFromNight` – `VERDAMMNISWAECHTER` nicht in `nightCauses`.
  - `core:401-406` `postDeathHooks` – Totenpopup sofort in der Nacht (nicht `_inNightResolution`).
- Text DE (wörtlich): `Jede Nacht: Wähle 1 von 2 Spielern (U+2014) entweder das Nachtopfer stirbt oder ein zufällig angebotener anderer Spieler stirbt stattdessen. Dieses Urteil umgeht alle Schutzfähigkeiten.` (`roles:79`)
- Text EN (wörtlich): `Each night: chooses 1 of 2 players (U+2014) either the night victim dies or a randomly offered player dies instead. This verdict bypasses all protection abilities.` (`roles:228`)
- DE/EN-Vergleich: JA (geringfügig). DE "anderer Spieler", EN "a randomly offered player ... instead" (das "anderer" steckt in "instead"). DE Imperativ, EN dritte Person: ohne Bedeutungsunterschied.
- Weitere Texte: `role-abilities.js:36` ABWEICHEND: der Satz "Dieses Urteil umgeht alle Schutzfähigkeiten." fehlt (sichtbar im Rollenwähler `gh:684`).
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht, tier 2.3, nach Werwolf (2.0), Albtraumwolf (2.1), Rachsüchtigem Wolf (2.2); spätere Wolfsziele (Lykaon, Schicksalswolf) werden nicht berücksichtigt.
  2. "Nachtopfer" = erster Sitz nach Sitzreihenfolge mit `targeted`. Bei mehreren Zielen (Rachsüchtiger Wolf zielt auf einen Wolf) kann das Ziel des Rachsüchtigen Wolfs gewählt werden; b2 hebt nur dieses eine Ziel auf.
  3. Ohne Ziel (auch wenn Schutzengel/Dorfwache das Wolfsziel verhindert hat): "Kein Opfer gesetzt", keine Wirkung.
  4. Zufallskandidat: lebender Nicht-Wolf (`isWolf`, also auch Verfluchte ausgeschlossen), Solos und der Verdammniswächter selbst möglich; `Math.random` bei jedem Öffnen → Neuwürfeln durch erneutes Anklicken möglich.
  5. Kein "Nichts tun"-Knopf; Verzicht nur durch Nicht-Anklicken der Zeile.
  6. Wirkung: sofortiger Tod mit `VERDAMMNISWAECHTER`, nicht am Morgen. Folgen: spätere Nachtrollen sehen den Toten (Waldhexe kann nicht mehr retten; ein getöteter Zufallskandidat verliert seinen eigenen Nachtschritt); Todespopup erscheint sofort; Liebeskummer, Sensenträger-Queue laufen sofort.
  7. Umgangene Schutzmechanismen: Weiser-Rettung, Märtyrerin, Voodoo-Umlenkung, Nekromant-Umlenkung, Schmied-Waffe, Waldhexe-Heilung (alle nur in Morgenauflösung/anderen Pfaden). NICHT umgangen: Nekromant-Immunität, Kartenschlucker-Schild, Hades-Barriere, Rudelvater-Erstrettung, Parasit-Wirt, Schattenwanderer-Tausch (`applyKill`).
  8. Ritter, der durch b1 stirbt, rächt sich nicht (Ursache nicht in `nightCauses`, `core:431`); Seuchenwolf-Pierce-Reset zählt nur `NIGHT_KILL` (`night:338`).
  9. Mehrere Kopien: max 1; Handler unabhängig vom Akteur.
  10. Sichtbarkeit: Dialog SL; Tod öffentlich wie jeder Tod.
- React-Version: kein eigenes Verhalten; Dialog über `domMirror.ts` (SPECIAL-ROLE-FLOW-REPORT.md:80-90 "funktioniert").
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 23: "widersprüchlich", `chunk:726-736`, "umgeht alle Schutzfähigkeiten vs. applyKill-Schilde; tötet sofort statt am Morgen". Bestätigt, Zeilen stimmen. Ergänzungen: Schutzengel verhindert das Auslösen ganz; Pool ohne Wölfe; Neuwürfeln; Mehrfachziel-Auswahl.
  - 04 B-10: Sofort-Tod bestätigt.
  - 07 Q1 Vorschlag "Tod am Morgen, ignoriert Schutz und Schilde": Code weicht in beiden Punkten ab (bestätigt).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` L14 (umgeht Weisen und Schmied): bestätigt.
  - SPECIAL-ROLE-FLOW-REPORT.md:87 "Tod am Morgen korrekt": bezieht sich auf die Morgengrauen-Anzeige (`night:350` Snapshot), der Tod passiert im Zustand sofort. Aussage irreführend.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| "umgeht alle Schutzfähigkeiten" | alle | all | umgeht Auflösungs-Schutz, nicht `applyKill`-Schilde; Schutzengel verhindert Auslösen | wie Legacy | 04/07 | wirklich alle (auch Schilde, Schutzengel) | nur Schutz gegen das Nachtopfer | mittel | KillPipeline-Option `ignore_protections` + Auslösung auch bei geschütztem Opfer | A (07-Vorschlag) | Ja |
| Todeszeitpunkt | nicht genannt ("stirbt") | nicht genannt | sofort | wie Legacy | 07: am Morgen | sofort | Morgen | hoch (Hexe, spätere Rollen) | IMMEDIATE vs. Morgenkill | Morgen (07) | Ja |
| Zufallskandidat | "anderer Spieler" | "randomly offered player" | nur Nicht-Wölfe, inkl. Solo und sich selbst | wie Legacy | nicht erwähnt | jeder andere Lebende | nur Nicht-Wölfe | Pool ohne Wölfe schützt das Rudel | Rng-Menge | PO | Ja |
| role-abilities-Text | – | – | Satz fehlt (`role-abilities.js:36`) | – | – | – | – | – | Textquelle vereinheitlichen | Satz ergänzen oder Regel ändern | Nein |
| Fraktion vs. Phase | Dorf | Dorf | Dorf, aber tier 2.3 in Wolfsphase | wie Legacy | 04: D | Dorfrolle mit eigenem Schritt nach Rudel | Wolfsnahe Rolle | gering | nur Schrittpriorität | Dorf, Priorität nach Rudel | Nein |

- Bugs:
  - B-VW-1 (technische Altlast): `Math.random` beim Öffnen (`chunk:729`), Neuwürfeln durch erneutes Öffnen. Test: gleicher Seed → gleicher Kandidat; Abbruch verbraucht keinen Rng (wie Lehrling).
  - B-VW-2 (unklare Regel / Bug-Risiko): `seats.find(targeted)` wählt bei mehreren Zielen das nach Sitz erste (`chunk:727`). Test: Werwolf-Ziel Sitz 5, Rachsüchtiger-Wolf-Ziel Sitz 2 → Nachtopfer muss das Rudelziel sein.
  - B-VW-3 (unklare Regel): Ritter-Vergeltung und Seuchenwolf-Reset ignorieren die Ursache (`core:431`, `night:338`). Test: Ritter als Nachtopfer, b1 → Vergeltung ja/nein festlegen.
- Legacy-Status: legacy-contradictory. Code funktioniert als Zwei-Knopf-Urteil, widerspricht aber Text (Schutzumfang, Zeitpunkt, Kandidatenmenge) ohne offensichtlichen Defekt.
- Automationsvorschlag: assisted, bis Q1 entschieden ist; danach automatic mit SeededRng.
- Mechanikfamilie primär + sekundär: Zielumleitung; sekundär Tötung, Zufallsmechanik.
- Benötigte vorhandene Godot-Systeme: StepQueue (nach Rudel), PendingPrompt (2 Optionen, abbrechbar), SeededRng, KillPipeline, Protections, Reaktionswarteschlange, InfoRecord, StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: keines zwingend; KillPipeline braucht eine Option "ignoriert alle Schutzeffekte und Schilde" und ggf. zeitlich verzögerte Effekte, falls der Tod am Morgen erfolgt.
- Abhängigkeiten von anderen Rollen: Werwolf/Rudel (liefert Nachtopfer), Rachsüchtiger Wolf (Zusatzziel), Schutzengel/Dorfwache, Der Weise, Märtyrerin, Waldhexe, Voodoo-Priester, Nekromant, Kartenschlucker, Hades, Rudelvater, Ritter, Seuchenwolf.
- Komplexität und Fehlerrisiko: M / hoch. Zeitpunkt- und Schutzfragen verändern viele andere Rollen.
- Offene Entscheidungen:
  1. Tod sofort oder in der Morgenauflösung?
  2. Umgeht das Urteil auch Schilde (Nekromant, Kartenschlucker, Hades, Rudelvater) und Schutzengel (auch wenn das Rudelziel geschützt war)?
  3. Kandidatenmenge: alle anderen Lebenden, nur Nicht-Wölfe, ohne Verdammniswächter selbst?
  4. Welches Nachtopfer bei mehreren Wolfszielen?
  5. Pflichtschritt oder darf der Verdammniswächter verzichten?
- Relevante Testgruppen:
  - Normalfall: Rudelziel A, Kandidat B (Seed), Wahl B → B tot, A lebt.
  - ungültiges Ziel: kein Rudelziel → Schritt ohne Wirkung.
  - tote Person: Kandidat muss lebend sein.
  - Selbstwahl: Kandidat = Verdammniswächter → nach Entscheidung.
  - mehrere Kopien: nicht relevant (max 1).
  - Wiederbelebung: Frankenstein belebt das Urteilsopfer → normal.
  - Rollenwechsel: nicht relevant.
  - Save/Load: Save mit offenem Prompt → gleicher Kandidat nach Load.
  - Replay: Kandidat bytegleich.
  - SL-Korrektur: Urteil zurücknehmen.
  - Sichtbarkeit: Kandidat actor/gm, Tod public.
  - Schutz: Schutzengel auf A, Rudel zielt A → Urteil möglich/nicht (Entscheidung); Kartenschlucker mit Schild als Kandidat → stirbt/nicht.
  - Todesreaktionen: Kandidat Sensenträger → Reaktion zum festgelegten Zeitpunkt.
  - Siegprüfung: Urteilstod erzeugt Parität → Kandidatenmenge erst nach Reaktionen.
  - beschädigter Spielstand: Nachtopfer-ID fehlt → Schritt entfällt.
- Belegsicherheit: hoch.

### wahnsinniger-kutscher
- DE-Name / EN-Name: Wahnsinniger Kutscher / Mad Coachman (`roles:155`)
- Aliase/Altnamen: Todesursache `BUSDRIVER_LYNCH` (Label "🃏 Wahnsinniger Kutscher" `ui:403`, Log `gh:2423`, `logBusdriverLynch` `i18n:140,464`); SFX `sfxWahnsinniger` (No-op); Bild `Wahnsinniger Kutscher.webp` mit Leerzeichen (`roles:414`, `gh:810`, `roleCard.ts:15`), `Mad_Coachman.webp` (`gh:823`). Namensnähe zu `"Kutscher"` (Wiederbelebungsrolle, EN "Coachman") ist eine Verwechslungsgefahr.
- Legacy-ID: `"Wahnsinniger Kutscher"` (`roles:1`, Index 24)
- Fraktion: `dorf`.
- Akte: Akt III (`akte.js:56`).
- Nachtpriorität und Bedingungen: nicht in ORDER_BASE, im Passiv-Set (`night:96`). Nur Lynch-Reaktion.
- Quelltextstellen:
  - `night:425-439` `doLynchFlow` Zweig – direkte Sitze `(id-1±1) mod n`; `applyKill(...,"BUSDRIVER_LYNCH")` für links, rechts, dann Kutscher selbst, jeweils nur wenn lebend; `finalizeLynch(target,{log:false})`; `postDeathHooks`.
  - `night:404-419` `finalizeLynch` – LynchCount, Henker-Markierte.
  - `gh:2410-2427` Log-Wrapper von `applyKill` – loggt auch den Kutscher selbst als "starb als Nachbar des Wahnsinnigen Kutschers".
- Text DE (wörtlich): `Wird er gelyncht, sterben beide direkten Nachbarn mit ihm.` (`roles:81`)
- Text EN (wörtlich): `If lynched, both living neighbors die with him.` (`roles:230`)
- DE/EN-Vergleich: NEIN. DE "direkten Nachbarn" (Sitz daneben, auch wenn tot), EN "living neighbors" (nächste lebende Nachbarn). Bei einem toten direkten Nachbarn stirbt nach DE niemand auf dieser Seite, nach EN der nächste Lebende.
- Weitere Texte: `role-abilities.js:38` identisch mit DE.
- Legacy-Codeverhalten:
  1. Auslöser: nur `doLynchFlow` mit Ziel "Wahnsinniger Kutscher"; dieser Zweig steht vor allen anderen Lynch-Sonderzweigen (Voodoo, Brand, Fenrir, ...). Manueller Tod-Chip (`gh:429`) oder andere Todesarten lösen nichts aus.
  2. Nachbarn: direkte Sitze per Index; tote direkte Nachbarn werden übersprungen, kein Weiterwandern.
  3. Reihenfolge: links, rechts, Kutscher; alle mit `BUSDRIVER_LYNCH`, auch der Kutscher selbst (nicht `LYNCH`).
  4. Schutz: Schutzengel wirkt nicht (`applyKill`); `applyKill`-Schilde wirken (z.B. Rudelvater überlebt den ersten Sondertod, Nekromant-Immunität wird vom ersten Getroffenen verbraucht).
  5. Nicht behandelt im Zweig: Voodoo-Puppen-Cooldown (Kutscher als Puppe), Kopfgeldjäger-Aktivierung bei `isWolf(target)` (z.B. per Wolf-Chip), Brand-Ausbreitung (durch direkte Nachbartode faktisch ähnlich, aber inkl. Feuerteufel-Nachbar).
  6. `finalizeLynch` läuft: LynchCount und Henker-Markierte korrekt.
  7. Mehrere Kopien: max 1; zwei nebeneinander gelynchte Kutscher gibt es nicht (ein Lynch).
  8. Zufall: keiner.
  9. Sichtbarkeit: Tode öffentlich; SFX stumm.
  10. Sieg: `applyKill` → `checkWinConditions` nach jedem der drei Tode einzeln (Zwischenstände können Sieg auslösen, bevor der Kutscher selbst tot ist).
- React-Version: kein eigenes Verhalten; Lynch über legacy `doLynchFlow` (`legacyAdapter.ts:683-685`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 25: "widersprüchlich", `night:425-439`, DE direkt vs. EN lebend. Bestätigt, Zeilen stimmen. Hinweis: Code folgt DE.
  - 04 E-3 (Kutscher zuerst, `finalizeLynch` in jedem Zweig): bestätigt.
  - 07 Q1 Vorschlag "lebende Nachbarn": offen.
  - 01 `:136` Sitz = ID: bestätigt für diesen Zweig. DECISION-LOG Z.31-32: Zustände an Personen-ID, Sitze tauschbar → Godot muss Nachbarn aus Sitzreihenfolge bestimmen.
  - DECISION-LOG Z.203 "Eine Hinrichtung ist immer `LYNCH`": Legacy nutzt `BUSDRIVER_LYNCH` für den Kutscher selbst (Abweichung).
  - `GRIMMHAIN_ANALYSE_2026-06-12.md` L5 (Kutscher ohne LynchCount/Henker): widerlegt für den heutigen Stand (`night:436`).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Nachbarbegriff | direkte Nachbarn | living neighbors | direkte Sitze, tote übersprungen | wie Legacy | 07: lebende Nachbarn | direkte Sitze (DE, Code) | nächste Lebende (EN, 07) | B tötet spät im Spiel zuverlässiger zwei | gleiche Sitznachbarschafts-Funktion wie Nachtwächter | PO; Texte angleichen | Ja |
| Todesursache Kutscher | "gelyncht" | "lynched" | `BUSDRIVER_LYNCH` | wie Legacy | DECISION-LOG: Hinrichtung immer LYNCH | Kutscher `LYNCH`, Nachbarn eigene Ursache | alle eine Ursache | gering (Reaktionen, die auf LYNCH prüfen) | Ursachenmodell | Kutscher `LYNCH`, Nachbarn `MAD_COACHMAN_NEIGHBOR` | Nein |

- Bugs:
  - B-MK-1 (technische Altlast, sichtbar): Kutscher selbst wird mit `BUSDRIVER_LYNCH` getötet (`night:432`) und im Protokoll als "starb als Nachbar des Wahnsinnigen Kutschers" geführt (`gh:2423`), obwohl `finalizeLynch` das Lynch-Log unterdrückt (`night:436`). Test: Kutscher-Lynch → Kutscher Ursache LYNCH, Nachbarn Nachbar-Ursache, genau ein Lynch-Eintrag.
  - B-MK-2 (unklare Regel): Zweig ignoriert Voodoo-Puppe und Kopfgeldjäger-Aktivierung (`night:425-439` vs. `night:499`). Test: Kutscher mit Wolf-Flag gelyncht → Kopfgeldjäger aktiv (festlegen).
  - B-MK-3 (unklare Regel): Siegprüfung nach jedem Einzeltod (`core:213`) statt nach der ganzen Hinrichtung (DR-14). Test: Lynch, bei dem erst der Tod beider Nachbarn plus Kutscher die Parität ergibt → genau eine Siegprüfung nach allen Toden und Reaktionen.
- Legacy-Status: legacy-contradictory. Code setzt den DE-Text um, EN-Text und 07-Vorschlag widersprechen; kein Defekt der Kernfunktion.
- Automationsvorschlag: automatic.
- Mechanikfamilie primär + sekundär: Hinrichtungsreaktion; sekundär Sitzpositionsmechanik, Tötung.
- Benötigte vorhandene Godot-Systeme: ExecutionRules (Hinrichtungsreaktion wie Spiegelwolf-Umlenkung), KillPipeline, Reaktionswarteschlange, WinRules/WinCandidate (DR-14), Nominations (nicht nötig, aber Hinrichtung setzt sie voraus), Ereignis-Sichtbarkeit, GmCorrections, StateCodec, Replay.
- Benötigte NEUE Systeme: Sitznachbarschaft (direkt oder nächster Lebender, nach Sitzreihenfolge).
- Abhängigkeiten von anderen Rollen: Loki (Kette), Sensenträger/Besessener Wolf (Folgereaktionen), Rudelvater/Nekromant/Kartenschlucker/Hades/Parasit (Schilde), Henker (`finalizeLynch`), Feuerteufel/Voodoo-Priester/Kopfgeldjäger (ausgelassene Sonderzweige).
- Komplexität und Fehlerrisiko: S / mittel. Einfach, aber Nachbarschaft und Ursachenmodell müssen stimmen.
- Offene Entscheidungen:
  1. Direkte oder nächste lebende Nachbarn?
  2. Schützt Schutzengel/Hexe oder ein Schild die Nachbarn?
  3. Wirkt die Reaktion auch bei Tod durch GmCorrection-Hinrichtung (DECISION-LOG Z.131 legt nahe: ja)?
  4. Todesursache der Nachbarn und des Kutschers festschreiben.
- Relevante Testgruppen:
  - Normalfall: Kutscher Sitz 4 gelyncht → Sitze 3, 5 und 4 tot.
  - ungültiges Ziel: nicht relevant (keine Zielwahl).
  - tote Person: Sitz 3 tot → nur 5 und 4 (DE) bzw. 2, 5, 4 (EN).
  - Selbstwahl: nicht relevant.
  - mehrere Kopien: nicht relevant (max 1).
  - Wiederbelebung: nicht relevant.
  - Rollenwechsel: Kutscher-Rolle geerbt → Reaktion an neuer Person.
  - Save/Load: Save nach Hinrichtung vor Reaktionen → gleiche Tode.
  - Replay: bytegleich.
  - SL-Korrektur: Hinrichtung per Korrektur → Reaktion läuft.
  - Sichtbarkeit: alle drei Tode public, Ursachen privat (DR-04).
  - Schutz: Nachbar mit Kartenschlucker-Schild → nach Entscheidung.
  - Todesreaktionen: Nachbar Sensenträger → Reaktion nach allen drei Toden.
  - Siegprüfung: Parität erst nach allen Toden (DR-14).
  - beschädigter Spielstand: Sitzliste mit 2 Personen → links = rechts, kein Doppeltod.
- Belegsicherheit: hoch.

---

## Gruppenübergreifende Beobachtungen

1. Uneinheitliche Wolf-/Solo-Abfrage innerhalb der Gruppe: Nachtwächter nutzt `isWolf` + Solo-Name (`night:557-558`), Spürhund nur `getRoleFaction(role)` (`chunk:268`), Die Ewigen nur Solo-Name (`chunk:255`), Verdammniswächter `isWolf` (`chunk:728`), Der-Weise-Debuff nur `WOLF_ROLES_SET` per Rollenname (`ab:93-96`). Folge: verwandeltes Wolfskind ist für den Nachtwächter ein Wolf, für den Spürhund nicht, und wird vom Debuff wie ein Dorfbewohner gesperrt. Godot sollte eine einzige FactionQuery (Wahrheit vs. Erscheinung, `appears_as`) für alle nutzen.
2. Sitznachbarschaft kommt in zwei Varianten vor: nächster lebender Nachbar (Nachtwächter `night:546-553`) und direkter Sitz (Wahnsinniger Kutscher `night:427-429`). Beide rechnen `id-1` als Sitzindex. Mit tauschbaren Sitzen (DECISION-LOG Z.31-32) wird ein gemeinsames Sitznachbarschaftsmodul gebraucht, das beide Varianten anbietet. 01 `:136` ordnet `doBearPing` fälschlich der Direktvariante zu.
3. Schutz liegt in Legacy an drei Stellen: im Werwolf-Pick (`chunk:162`, Verbrauch beim Zielen), in der Morgenauflösung (`night:354-399`, Weiser/Nekromant/Schmied) und in `applyKill` (Schilde). Daraus folgen F10 (Doppelrettung Weiser) und der unscharfe Verdammniswächter-Satz "umgeht alle Schutzfähigkeiten". Godot-Protections (nur gegen Rudel-NIGHT_KILL, Anwendung morgens, DR-05) lösen beides, wenn die Weiser-Rettung eine eigene Einmal-Regel wird und kein `flags.protected` ist.
4. Globale `once`-Schlüssel statt personengebundener Nutzungen: `role_Loki`, `role_Die_Gebundenen`, `DerWeiseFirstAttackUsed` sind global; eine geerbte oder neu vergebene Kopie hat keine eigene Nutzung (Widerspruch zu DR-11 "vollständig zurückgesetzte Nutzungen").
5. `once:true` in ORDER_BASE bedeutet "einmal pro Partie", nicht "Nacht 1" (Loki, Die Gebundenen). Für die Gebundenen ist das eine Abweichung vom Text, für Loki nicht.
6. Math.random in dieser Gruppe: Spürhund (`chunk:276`) und Verdammniswächter (`chunk:729`); bei beiden würfelt erneutes Öffnen neu. Keine weiteren Zufallsaufrufe in den Handlern dieser Gruppe.
7. Zwei Rollen haben in Legacy keine beobachtbare bzw. keine vollständige Wirkung: Nachtwächter (Ausgabe ist ein stummer SFX) und Die Ewigen (kein Mitsieg). Beide sind in Akt I bzw. II.
8. Fehler bzw. Präzisierungen in 04: Zeile 2 Akzeptanzkriterium "nach Toten" ist ungenau (jeder Morgen); Zeile 10 Spürhund "verifiziert" ist zu optimistisch (Wolf-Definition, kumulative Markierung); Zeile 22 nennt nicht, dass der React-Startpfad (`legacyAdapter.ts:666-667`) F10 immer auslöst und dass `keepP` jeden Schutz auf dem Weisen konserviert; Zeile 23 nennt nicht, dass ein geschütztes Rudelziel den Verdammniswächter gar nicht erst auslöst. Die übrigen Zeilenangaben der 8 Zeilen stimmen.
9. Überholte Aussagen in Altberichten: `GRIMMHAIN_ANALYSE_2026-06-12.md` L7 (Ewige unerreichbar), L5 (Kutscher ohne `finalizeLynch`), E3 (Spürhund-EN ohne falsche Spur) und AUDIT.md (fehlende Alarm-Datei) beschreiben nicht mehr den aktuellen Code.
10. Neue Runde (`gh:512-518`) setzt `meta.loverId` nicht zurück; relevant für Loki/Schwarze Witwe. `resetMarksOnly` (`night:510-531`) macht es richtig.
11. React hat für diese Gruppe genau eine eigene Regel-Datenstelle: `flags.protected` für den Weisen (`legacyAdapter.ts:572,666-667`). Alles andere läuft über die Legacy-Globals.
