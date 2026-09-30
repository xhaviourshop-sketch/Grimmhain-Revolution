<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G4 Solos B: Nekromant, Kartenschlucker, Hades, Grabräuber, Parasit, Todesprediger

Stand: 2026-09-26, nur lesend geprüft. Pfad-Kürzel wie im Auftrag (`roles`, `chunk`, `ab`, `help`, `night`, `core`, `ui`, `state`, `gh`). Zusätzlich `cards` = js/core/cards.js, `ra` = js/core/role-abilities.js, `i18n` = js/core/i18n.js, `akte` = js/core/akte.js, `fvm` = js/ui/field-viewmodel.js, `adapter` = app/src/adapter/legacy/legacyAdapter.ts.

Gemeinsame Grundlagen (für alle sechs Rollen geprüft):
- Alle sechs stehen in `SOLO_ROLES_SET` / `window.SOLO_WIN_ROLES` (`roles:399-403`), `getRoleFaction` liefert "solo" (`roles:405-409`). Keine steht in `WOLF_ROLES_SET` (`roles:391-396`).
- `isWolf` (`core:8-19`) schließt Parasit, Grabräuber, Todesprediger (sowie Doppelspion, Manipulator) hart aus (`core:13`), auch wenn `flags.werewolf` oder `meta.cursedWolfAura` gesetzt ist. Nekromant, Kartenschlucker und Hades stehen NICHT in dieser Ausschlussliste: ein vom Dämonischen Wolf verfluchter (`cursedWolfAura`) Nekromant/Hades/Kartenschlucker zählt als Wolf.
- Totenkarten: Beim Tod zieht jeder Sitz über `applyKill` eine Karte, falls keine ungespielte vorhanden (`core:190-207`); Solo-Rollen ziehen mit Gewichten SOLO 80 / SCHICKSAL 10 / LOKI 10 (`cards:650-671`, `zieheZufallsKarte`, Math.random `cards:667`), Label "Solo-Effekt" (`help:290-295`, `deathCardFactionLabel`). Keine Kartenwirkung ist automatisiert.
- Manueller Tod über den "tot"-Chip im Sitz-Popup (`gh:427-429`) umgeht `applyKill` vollständig (F6): keine Hades-Lichter, kein Todesprediger-Sieg, kein Parasit-Kettentod, kein Schildverbrauch.
- Nachtschritt-Blockaden (`ab:93-99`, `onOrderClick`): Schattenhund, Zeitwächter-Frost, Weiser-Debuff (`OldDebuff`) und Albtraum (`BlockedRolesTonight`, `meta.blockedTonight`) blockieren alle Nicht-Wolf-Rollen, also auch alle sechs. Der Albtraumwolf darf jede Nicht-Wolf-Person blockieren (`chunk:288-302`, Prädikat `!isWolf(x)`), also auch Solos.
- React (app/src): nur Adapter/Bilder, keine eigene Regelmechanik für diese Rollen (Belege je Rolle).
- Godot (godot/README.md): keine der sechs Rollen ist implementiert (`role_catalog.gd` enthält nur dorfbewohner, werwolf, sensentraeger, schutzengel, waldhexe, das-orakel u.a. Produktionsrollen der Vertikalscheibe).

---

### nekromant
- DE-Name / EN-Name: Nekromant / Necromancer (`roles:183`).
- Aliase/Altnamen: "Totenrat-Führer" wird beim Laden zu "Nekromant" migriert (`state:18`, `migrateLegacyRoleIds`, inkl. `Used`-Schlüssel und `TeamWinner`-String `state:30-37`). State-Schlüssel tragen weiter den Altnamen: `TotenratFuehrerSilenced`, `TotenratFuehrerRevealed`, `TotenratFuehrerUsedDeflect` (`state:68-69`), `TotenratDeathImmunityPending` (`chunk:194`, `core:127`, `night:141`). i18n-Schlüssel `totenrat*`/`shieldTotenrat*` (`i18n:157-184`, `i18n:255-256`, EN `i18n:481-508`, `i18n:579-580`). Button-IDs `totenratRevealBtn`, `totenratNameWolfBtn` (`gh:98`). Fallback-Prompts "Totenrat - 3 Tote ..." in `night:369,373` (nur ohne i18n sichtbar). Toter Setup-Code mit Altname in Fallback-Sets (`gh:889`, `gh:1019`, laut 01 unerreichbar). Bild: `assets/cards/de/Nekromant.webp`, EN `assets/cards/en/Necromancer.webp` (`gh:834`, `app/src/roleCard.ts:71`). React-Legende nennt "Totenrat" (`app/src/components/MarkerLegend.tsx:28,49`).
- Legacy-ID: "Nekromant" (ALL_ROLES Index 52, `roles:1`).
- Fraktion: solo (`roles:399-409`). Besonderheit: nicht im `isWolf`-Ausschluss (`core:13`), kann also per `cursedWolfAura` als Wolf zählen. Rollen-Tags `["solo-win","vote-manipulation","dead-interaction"]` (`roles:293`), von keiner Logik gelesen (nur Revive-Tags werden verwendet, `cards:573`).
- Akte: Akt II "Veins of the Old Forest" (`akte:43`).
- Nachtpriorität: tier 3.0, nicht once (`roles:26`). Nachtschritt erscheint jede Nacht, solange ein Nekromant lebt (`night:58,93`); keine weitere Bedingung (auch bei weniger als 3 Toten, dann Meldung im Handler).
- Quelltextstellen:
  - `roles:109` / `roles:258` Texte DE/EN; `ra:70` Codex-Text DE.
  - `chunk:163-207` Handler "Nekromant": prüft >=3 Tote (`:164-168`) und >=3 Tote ohne `deadVoteStripped` (`:169-173`), Overlay mit Bestätigen/Abbrechen, `startMulti` 3 Tote ohne Stimmentzug (`:190`), setzt `flags.deadVoteStripped=true` je Toter (`:192`) und `state.once.TotenratDeathImmunityPending=true` (`:194`).
  - `core:126-133` `applyKill`: globaler Schild blockiert den nächsten Tod JEDER Person, außer Ursache `PACKFATHER_KILL`; verbraucht sich dabei.
  - `night:141-144` `onNightStart`: Schild verfällt mit Beginn der nächsten Nacht.
  - `night:237` `onDayStart`: `TotenratFuehrerUsedDeflect=false` vor der Morgenauflösung.
  - `night:365-379` `resolveDayKills/processOne`: Ist ein Nachtziel der Nekromant und gibt es >=3 Tote, die nicht in `TotenratFuehrerSilenced` stehen, wird zwingend `startMulti` (3 Tote) und danach `startPick` (Umlenkziel, lebend, nicht der Nekromant) geöffnet; Umlenkziel stirbt mit `NIGHT_KILL`.
  - `gh:531-546` Tagesbutton "Wölfe enthüllen" (Übung): SL wählt alle vermuteten Wölfe; falsch => `TotenratFuehrerRevealed=true`, Meldung "die Wölfe wissen, wer du bist".
  - `gh:547-556` Tagesbutton "Wolf benennen": beliebig lebende Person außer sich; `isWolf(pick)` => `triggerWin("Nekromant")`, sonst Meldung, ohne Folgen und ohne Versuchszähler.
  - `ui:293-300` `afterFieldRender`: beide Buttons nur am Tag und nur mit lebendem Nekromant; Enthüllen-Button verschwindet nach `TotenratFuehrerRevealed`.
  - `fvm:61-72` ViewModel-Felder `hasLivingNekromant`, `nekromantRevealed`.
  - `ui:109` `markerList`: Tote zeigen Stimm-Chip (🗳 bzw. 🚫 nach `deadVoteStripped`) nur solange ein Nekromant lebt.
  - `gh:275` Chip `deadVoteStripped` manuell setzbar; `gh:516,524` Reset in `clearRolesNewRound`.
  - `adapter:338-382` React: `silenced` aus `TotenratFuehrerSilenced`, `vote`/`silenced`-Icons aus `deadVoteStripped`, `revealed`-Icon.
- Text DE (wörtlich, `roles:109`): "Mit mindestens drei Toten kann er nachts drei Stimmen opfern und ein Schild errichten, das die nächste Tötung (beliebig) verhindert; ungenutzt verfällt es mit der nächsten Nacht. Wird er nachts angegriffen, kann er alternativ drei Tote wählen und den Kill umlenken. Gewinnt allein, wenn er am Tag einen lebenden Werwolf korrekt benennt."
- Text EN (wörtlich, `roles:258`): "With at least three dead players, he may spend three votes at night to raise a shield that prevents the next death of any kind; if unused, it expires when the next night begins. If attacked at night, he may instead sacrifice three dead players and redirect the kill. Wins alone if he correctly names a living werewolf during the day."
- DE/EN-Vergleich: semantisch gleich NEIN (geringe, aber reale Unterschiede): (1) DE "die nächste Tötung (beliebig)" vs EN "the next death of any kind": DE spricht von Tötung, EN von Tod; beide lassen offen, ob der Schild nur den Nekromanten oder jede Person schützt. (2) DE "drei Tote wählen" vs EN "sacrifice three dead players": EN impliziert ein Opfer/Verbrauch der Toten, DE nur eine Wahl. (3) Zeitpunkt, Zahl 3, "am Tag", "lebenden Werwolf", "allein" sind gleich.
- Weitere Texte: `ra:70` (Codex, im Rollenwähler angezeigt `gh:684`) weicht ab: ohne "(beliebig)" und ohne Verfall "ungenutzt verfällt es mit der nächsten Nacht". i18n-Laufzeittexte präzisieren den Code: "Totale Immunität gegen die nächste Tötung" (`i18n:164,169`), Verfall mit Beginn der nächsten Nacht (`i18n:172`). Die Übungs-Enthüllung ("Wölfe enthüllen", `i18n:119,181-184`) steht in keinem Rollentext. Totenkarten: kein direkter Bezug; der Stimmentzug wirkt auf dieselben "Stimmen der Toten", auf die sich Stimm-Karten beziehen (z.B. `cards:182` Tote leiten den Tag), aber ohne Code-Verknüpfung.
- Legacy-Codeverhalten:
  1. Zeitpunkt Schild: jede Nacht als eigener Schritt (tier 3.0, nach der Wolfsphase). Voraussetzung >=3 Tote insgesamt UND >=3 Tote ohne `deadVoteStripped` (`chunk:164-173`).
  2. Ziele Schild: genau 3 tote Sitze ohne Stimmentzug (`chunk:190`); lebende und bereits entzogene nicht wählbar. Selbstwahl nicht möglich (Nekromant lebt).
  3. Wirkung Schild: globales Flag `TotenratDeathImmunityPending`; blockiert in `applyKill` den nächsten Tod irgendeiner Person und jeder Ursache außer `PACKFATHER_KILL` (`core:127-133`), auch Lynch am Folgetag. Er wird vor Kartenschlucker-Schild und Hades-Barriere geprüft, aber nach Parasit-Immunität, Rudelvater und Schattenwanderer (`core:106-125`).
  4. Mehrfachnutzung Schild: keine Nachtgrenze; der Handler kann mehrfach aufgerufen werden, jeder Aufruf entzieht 3 weitere Stimmen, der Schild stapelt aber nicht (boolesch).
  5. Verfall: bei `onNightStart` (`night:141-144`), also Schild aus Nacht N gilt bis zum Beginn von Nacht N+1 (inkl. Morgen und Tag N).
  6. Umlenkung: nur in der Morgenauflösung für Ziele mit `flags.targeted` bzw. Schicksalswolf-/Rudelvater-Zusatzziele (`night:239-248`, `night:365`), nicht für Sofort-Tode (Hexe, Hades, Kartenschlucker usw.). Einmal pro Nacht global (`TotenratFuehrerUsedDeflect`, Reset `night:237`).
  7. Umlenkung ist Pflicht: Sobald >=3 "nicht stillgelegte" Tote existieren, öffnet sich zwingend die Mehrfachauswahl; es gibt keine Option "nicht umlenken". Abbrechen über die Pick-Leiste (`ui:315`, `startMulti` ohne `onCancel` `ui:340`) beendet die Kette `processOne` ohne `runRest`: restliche Nachtziele, Brandausbreitung, Dämonenfluch, `afterCurses` (Tag setzen, `nightCount+1`) laufen nicht.
  8. Umlenkungsressource: die 3 Toten landen in `TotenratFuehrerSilenced` (`night:370`), NICHT in `deadVoteStripped`. Beide Listen sind unabhängig: dieselben Toten können für Schild und Umlenkung je einmal verwendet werden; Legacy-Marker zeigen nur `deadVoteStripped` (`ui:109`), React zeigt zusätzlich `silenced` aus der Umlenkungsliste (`adapter:340-382`).
  9. Umlenkziel: beliebige lebende Person außer dem Nekromanten, auch Wölfe (`night:376`); direkt `applyKill(redir,"NIGHT_KILL")`, ohne die Prüfungen aus `processOne` (Der Weise, Schmied-Waffe, Dorfwache-Filter). Schutzengel-Schutz greift nicht, da dieser nur im Werwolf-Handler beim Zielen wirkt (`chunk:162`). Ein aktiver Nekromant-Schild blockiert den umgelenkten Tod (`core:127`). `redir` wird auch bei geblocktem Tod in `killedTonight` aufgenommen (vgl. F14).
  10. Sieg: am Tag Button "Wolf benennen" (`gh:547-556`); Treffer, wenn `isWolf(pick)` (inkl. `flags.werewolf`, `cursedWolfAura`; Doppelspion zählt nicht). Unbegrenzte Versuche, Fehlversuch ohne Konsequenz; `triggerWin` ohne Guard, Button selbst prüft `TeamWinner` (`gh:549`).
  11. Übungs-Enthüllung (`gh:531-546`): nicht im Rollentext; Fehlschlag setzt nur `TotenratFuehrerRevealed` (Button verschwindet, React-Icon "revealed"), keine weitere Regelwirkung.
  12. Sichtbarkeit: alle Meldungen über `center()` auf dem SL-Gerät; keine öffentliche Ansage vorgesehen.
  13. Mehrere Kopien: Schild und Umlenkungssperre sind global; `gh:532,548` nutzen `seats.find` (erster lebender Nekromant); zweiter Nekromant kann in derselben Nacht nicht umlenken.
  14. Zufall: kein Math.random in den Nekromant-Pfaden.
  15. Rollenwechsel/Wiederbelebung: Kutscher kann die Rolle zufällig an Wiederbelebte vergeben (`chunk:845-857`), `deadVoteStripped` wird dabei zurückgesetzt (`chunk:849`); globale Listen bleiben.
- React-Version: kein eigenes Verhalten. Nur Marker-Ableitung (`adapter:338-382`), Legende (`MarkerLegend.tsx:27-28`), Bildkarte (`roleCard.ts:71`), Auswahl-Prädikat für tote Ziele (`adapter:420`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 53 (`04:82`): "widersprüchlich"; Zeilen `chunk:163-207`, `core:127-133`, `night:365-379`, `gh:547-556` BESTÄTIGT. Kernaussagen "Schild gegen nächsten Tod beliebiger Person", "Pflicht-Umlenkung", "Sieg ohne Einschränkung" BESTÄTIGT. ERGÄNZT: getrennte Ressourcenlisten (Punkt 8), Abbruch bricht Morgenauflösung (Punkt 7), Umlenkziel umgeht Schutzprüfungen (Punkt 9), Übungs-Enthüllung ohne Textgrundlage.
  - 04 C (`04:136`) "Nekromant-Schild global, außer PACKFATHER_KILL" BESTÄTIGT; `04:140` "Nekromant-Umlenkung ... verifiziert" nur teilweise: Mechanik vorhanden, aber Pflicht und ohne Abbruchpfad.
  - 07 Q1 (`07:37`): Vorschlag "Schild nur für sich selbst; Umlenkung optional" offen.
  - 01 (`01:154,169`) Reihenfolge der Abfangregeln BESTÄTIGT.
  - AUDIT.md:135 "Totenrat-Buttons toter Pfad" WIDERLEGT (inzwischen behoben: `fvm:61`, `ui:293-300`, `gh:532,548` keyen auf "Nekromant"); GRIMMHAIN_ANALYSE_2026-06-12 A5 (DE-Texte "Totenrat-Führer") inzwischen erledigt: i18n nennt "Nekromant" (`i18n:157-184`).
  - SPECIAL-ROLE-FLOW-REPORT.md §2: Schildpfad "funktioniert" BESTÄTIGT; Umlenkung dort nicht getestet.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Wen schützt der Schild | "nächste Tötung (beliebig)" | "next death of any kind" | jede Person, jede Ursache außer PACKFATHER_KILL (`core:127-133`) | keine Logik | 04: widersprüchlich; 07: Vorschlag nur selbst | globaler Schild für die nächste Tötung irgendwo | Schild nur für den Nekromanten, jede Todesart | global: Nekromant kann Wolfskill auf beliebige Person verhindern (Dorf-nahe Macht), auch Lynch am Tag | global braucht globalen Modifikator in der KillPipeline; selbst passt in Protections | PO entscheidet; Text so oder so präzisieren | Ja |
| Umlenkung optional oder Pflicht | "kann ... alternativ" | "may instead" | zwingend bei >=3 freien Toten, kein Ablehnen, Abbruch hängt Auflösung auf (`night:365-379`, `ui:340`) | keine Logik | 04: Pflicht-Umlenkung | optional (Text) | Pflicht (Code) | Pflicht zwingt Nekromanten, einen Mitspieler zu töten | PendingPrompt mit "nicht umlenken" | Text gilt: optional mit Verzicht | Ja |
| Ressource der Toten | Schild: "drei Stimmen opfern"; Umlenkung: "drei Tote wählen" | "spend three votes" / "sacrifice three dead players" | zwei getrennte Listen (`deadVoteStripped` vs `TotenratFuehrerSilenced`), gegenseitig nicht ausschließend | zeigt beide Listen, verschieden benannt | nicht dokumentiert | ein gemeinsamer Vorrat "Stimme der Toten" | zwei getrennte Vorräte | getrennt: doppelte Nutzung derselben Toten | Statusmarker pro Toter: ein oder zwei Felder | ein gemeinsamer Marker "geopfert" | Ja |
| Siegversuche | "korrekt benennt" | "correctly names" | unbegrenzt, Fehlversuch folgenlos (`gh:547-556`) | keine Logik | 04: "ohne Einschränkung" | beliebig viele Versuche | ein Versuch pro Tag oder pro Spiel, evtl. mit Strafe | unbegrenzt: Solo-Sieg praktisch sicher durch Durchprobieren | Versuchszähler und Tagesaktion | Begrenzung festlegen | Ja |
| Übungs-Enthüllung | nicht erwähnt | nicht erwähnt | Button mit Folge "Wölfe wissen, wer du bist" (`gh:531-546`) | Marker "revealed" | nicht in 04 | streichen | als Regel übernehmen und Text ergänzen | unklar, derzeit nur Hinweis | eigener Tagesbefehl | streichen, sofern keine Regelquelle existiert | Ja |

- Bugs:
  1. Einstufung: echter Bug. Codepfad: `night:368-377` mit `ui:315,340`. Tatsächlich: Abbruch der Pflicht-Mehrfachauswahl (oder des Umlenkziels) beendet `processOne` ohne Fortsetzung; weitere Nachtziele sterben nicht, `afterCurses` läuft nicht (kein `state.dark=false`, kein `nightCount+1`); erneutes "Tag starten" erhöht `MorningCount` ein zweites Mal (`night:191`). Erwartet: Abbruch = "nicht umlenken", Auflösung läuft weiter. Risiko: hoch (Spielstand inkonsistent, Todesprediger/Giftwolf-Zählung verschoben). Regressionstest: Nekromant ist Wolfsziel, 3 Tote vorhanden, zweites Nachtziel vorhanden; Prompt abbrechen => Nekromant stirbt oder Verzicht, zweites Ziel stirbt, Tag beginnt genau einmal.
  2. Einstufung: unklare Regel. Codepfad: `night:373-375`. Tatsächlich: Umlenkziel stirbt ohne Der-Weise-, Schmied-, Dorfwache-Prüfung und unabhängig von Schutzengel-Schutz. Erwartet: nicht definiert. Risiko: mittel. Regressionstest: Umlenkung auf geschützte Person/Der Weise; Ergebnis gemäß PO-Regel.
  3. Einstufung: technische Altlast. Codepfad: `night:374` (`killedTonight.push` auch wenn `applyKill` false liefert, vgl. F14). Risiko: niedrig. Test: aktiver Schild + Umlenkung => Umlenkziel lebt und erscheint nicht in der Todesliste.
  4. Einstufung: unklare Regel/technische Altlast. Codepfad: `chunk:163-207`. Handler ohne Nachtgrenze; Mehrfachaufruf verbraucht weitere Stimmen ohne Zusatznutzen. Risiko: niedrig. Test: zweiter Aufruf in derselben Nacht ist gesperrt oder verbraucht nichts.
- Legacy-Status: legacy-contradictory. Begründung: Schild, Umlenkung und Sieg sind implementiert und funktionieren im Normalfall; Text und Code widersprechen sich in Optionalität der Umlenkung, Reichweite des Schildes, Ressourcenmodell und Versuchsgrenze. Der Abbruch-Bug betrifft nur den Nebenpfad.
- Automationsvorschlag: assisted. Schild, Verfall, Umlenkungsangebot und Wolfsprüfung sind deterministisch automatisierbar; Benennung am Tag braucht einen SL-Befehl, Sieg per WinCandidate mit SL-Bestätigung.
- Mechanikfamilie: primär Schutz; sekundär Zielumleitung, Einzelsieg, Tagfähigkeit, globale Regeländerung.
- Benötigte vorhandene Godot-Systeme: KillPipeline (Abfangstufe für globalen Schild), StepQueue (Nachtschritt), PendingPrompt (Auswahl 3 Tote, Umlenkziel, abbrechbar), WinRules/WinCandidate, InfoRecord (Benennungsergebnis), GmCorrections, StateCodec, Replay, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: dauerhafte Statusmarker an toten Personen (Stimme geopfert), globale Modifikatoren (Schild bis Beginn nächster Nacht, zeitlich verzögerter Verfall), Zielumleitung für Nacht-Rudelangriff (vorhanden nur für Hinrichtung, Spiegelwolf), Tagesaktionswarteschlange (Benennung), zusätzliche Siegbedingung.
- Abhängigkeiten: Werwolf-Rudel (Angriff als Auslöser), Schicksalswolf/Rudelvater (Zusatzziele, `PACKFATHER_KILL` durchbricht Schild), Dämonischer Wolf (`cursedWolfAura` zählt bei Benennung als Wolf, Nekromant selbst kann verflucht werden), Doppelspion (zählt nicht als Wolf), Parasit/Rudelvater/Schattenwanderer (vor dem Schild geprüft), Kartenschlucker/Hades (eigene Schilde nach dem Nekromant-Schild), Der Weise/Schmied/Schutzengel (Umlenkziel), Kutscher/Frankenstein (Wiederbelebung setzt `deadVoteStripped` zurück).
- Komplexität und Fehlerrisiko: L, hoch. Globaler Schild im Kill-Pfad, mehrstufiger Pflicht-/Optionalprompt in der Morgenauflösung, zwei Ressourcenlisten, Tages-Siegbefehl.
- Offene Entscheidungen:
  1. Schützt der Schild jede Person oder nur den Nekromanten? Gilt er gegen Lynch?
  2. Ist die Umlenkung optional? Darf auf Wölfe umgelenkt werden? Gelten Schutz/Der Weise für das Umlenkziel?
  3. Gibt es einen gemeinsamen Vorrat "Stimme der Toten" für Schild und Umlenkung?
  4. Wie oft darf der Nekromant einen Wolf benennen (pro Tag, pro Spiel), und hat ein Fehlversuch Folgen? Ist die Benennung öffentlich?
  5. Zählt ein verfluchter Nicht-Wolf (`cursedWolfAura`) als korrekt benannter Werwolf?
  6. Bleibt die Übungs-Enthüllung als Regel erhalten?
- Relevante Testgruppen:
  - Normalfall: 3 Tote, Schild aktiv, Wolfsangriff auf Dorfbewohner => kein Tod, Schild verbraucht.
  - ungültiges Ziel: Auswahl eines lebenden Sitzes oder eines Toten mit entzogener Stimme wird abgelehnt.
  - tote Person: Umlenkziel darf nicht tot sein; toter Nekromant hat keinen Nachtschritt und keine Tagesbuttons.
  - Selbstwahl: Umlenkung auf sich selbst abgelehnt; Benennung von sich selbst abgelehnt (`gh:551`).
  - mehrere Kopien: zwei Nekromanten, beide angegriffen => Verhalten gemäß PO (heute nur einer lenkt um).
  - Wiederbelebung: wiederbelebter Toter verliert Stimmentzug-Marker (`chunk:849`); Schild wird nicht durch Wiederbelebung verbraucht.
  - Rollenwechsel: Kutscher vergibt Nekromant an Wiederbelebten => globale Listen bleiben gültig.
  - Save/Load: Schild aktiv, speichern/laden => Schild weiter aktiv, verfällt bei nächster Nacht.
  - Replay: gleiche Befehlsfolge ergibt gleichen Schildverbrauch und gleiche Umlenkung.
  - SL-Korrektur: SL entfernt Schild oder setzt Stimmentzug zurück, mit Protokoll.
  - Sichtbarkeit: Schildaktivierung und Umlenkung nur gm-sichtbar; Tod des Umlenkziels öffentlich als Nachttod.
  - Schutz: Schild vs `PACKFATHER_KILL` (durchbricht), Schild vs Hades-Barriere (Nekromant-Schild zuerst verbraucht).
  - Todesreaktionen: Umlenkziel ist Sensenträger => Reaktion wird ausgelöst.
  - Siegprüfung: Benennung eines Wolfs => WinCandidate Nekromant; Benennung Doppelspion => kein Sieg.
  - beschädigter Spielstand: `TotenratFuehrerSilenced` fehlt oder ist kein Array (`night:370` würde werfen, wenn `undefined`; Default in `state:68`).
- Belegsicherheit: hoch für Schild, Verfall, Umlenkung, Sieg. Nicht verifiziert: tatsächliches Verhalten im Browser beim Abbruch (nur Codelesung); ob `center()`-Meldungen die Pick-Leiste verdecken.

---

### kartenschlucker

> **Hinweis 30.09.2026:** Dieser Abschnitt ist die Legacy-Analyse und bleibt als historische Quelle unverändert. Die aktuelle Regel steht im Decision Log („Kartenschlucker, Grundregeln“). Ersetzt sind insbesondere: „Bei 10 Stapeln gewinnt er sofort“, die kostenlose Tötung ab 2 Stapeln und der jede Nacht neu gesetzte Schild ab 5 Stapeln (Legacy-Punkte 5 und 6 unten und die Dossier-Fragen 1 bis 5 sind entschieden oder neu gefasst).

- DE-Name / EN-Name: Kartenschlucker / The Collector (`roles:184`).
- Aliase/Altnamen: keine Migration in `state:18`. i18n-Laufzeitübersetzung für Hinweis (`i18n:784`, `i18n:1063`). Bilder `assets/cards/de/Kartenschlucker.webp`, EN `assets/cards/en/The_Collector.webp` (`gh:835`, `roleCard.ts:72`). Todesursache `KARTENSCHLUCKER_KILL` (`chunk:228`, Label `ui:414`).
- Legacy-ID: "Kartenschlucker" (ALL_ROLES Index 53).
- Fraktion: solo (`roles:399-409`). Nicht im `isWolf`-Ausschluss (`core:13`). Tags `["solo-win","dead-interaction"]` (`roles:294`), ungenutzt.
- Akte: Akt III "The Looking-Glass Choir" (`akte:64`) UND Akt IV "Ash Crown of Grimmhain" (`akte:84`).
- Nachtpriorität: tier 4.0, nicht once (`roles:32`). Nachtschritt jede Nacht bei lebendem Kartenschlucker (`night:58,93`). Nicht in der Passiv-Liste (`night:96`).
- Quelltextstellen:
  - `roles:110` / `roles:259` Texte; `ra:68` Codex.
  - `help:77` `isKartenschluckerAktiv` (lebender Kartenschlucker).
  - `help:119,169-190` `showTodesscreen`: bei lebendem Kartenschlucker zusätzlicher Button "Neue Karte verlangen": `KartenschluckerStapel+1` (`help:176`), neue Zufallskarte (`help:177-178`), Siegprüfung (`help:180`), `showNeueKarte`.
  - `help:196-259` `showNeueKarte`: neue Karte muss sofort ausgespielt werden (nur Button "Verstanden"), Siegprüfung `help:248`.
  - `chunk:222-237` Nacht-Handler: zählt `KartenschluckerNightCount` einmal pro Nacht (`:224`), Siegprüfung (`:225`), ab 2 Stapeln Kill-Pick (`:226-233`, Ziel beliebig lebend inkl. selbst), alle 3 gezählten Nächte öffentliche Ansage (`:234`), ab 5 Stapeln `KartenschluckerShield=true` (`:235`).
  - `night:160` Reset `_kartenschluckerNightProcessed` bei Nachtbeginn; `night:235` Reset `KartenschluckerKilledTonight` bei Tagbeginn.
  - `core:134-138` `applyKill`: Schild absorbiert Tod des Kartenschluckers (außer `PACKFATHER_KILL`).
  - `core:241-247` `checkKartenschluckerWin` (>=10 Stapel, lebend); Aufruf in `checkTeamWin` `core:335` (nach jedem `save()`), nicht in `checkWinConditions`.
  - `help:9,47`, `cards:794,816`, `state:67-68`, `gh:524` Initialisierung/Reset.
- Text DE (wörtlich, `roles:110`): "Erhält jedes Mal einen Stapel, wenn ein Toter seine Karte austauscht. Bei 10 Stapeln gewinnt er sofort."
- Text EN (wörtlich, `roles:259`): "Gains a stack each time a dead player exchanges their cards. At 10 stacks, wins immediately."
- DE/EN-Vergleich: semantisch gleich JA im Kern (Auslöser Tausch, +1, Sieg bei 10 sofort). Unterschied nur Numerus: DE "seine Karte" (eine), EN "their cards" (Plural); inhaltlich ohne Folge, da jeder Tote eine Karte hat. EN-Name "The Collector" ist keine Übersetzung von "Kartenschlucker".
- Weitere Texte: `ra:68` "wenn ein Toter ihre Karten austauscht" (Grammatikfehler, Plural; T8 aus GRIMMHAIN_ANALYSE_2026-06-12 in `roles:110` behoben, in `ra:68` nicht). Laufzeittext `i18n:198` / `i18n:527` Ansage "Das Dorf erfährt: Kartenschlucker hat {n} Stapel." sowie Hinweis im Totenkarten-Dialog (`help:188`) stehen in keinem Rollentext. Totenkarten-Bezug: Kernmechanik hängt vollständig am Totenkarten-Dialog (`help:100-259`); Kartenziehung zufällig (`cards:630-747`).
- Legacy-Codeverhalten:
  1. Stapel: nur wenn ein toter Spieler im Totenkarten-Dialog (vom SL über den Button am toten Sitz geöffnet) "Neue Karte verlangen" wählt, solange ein Kartenschlucker lebt (`help:169-176`). Einfaches Ausspielen gibt keinen Stapel (Kommentar `help:175`).
  2. Pro Karte höchstens ein Tausch: die Ersatzkarte bietet nur "Verstanden" (`help:237-252`). Wird ein Toter wiederbelebt und stirbt erneut, erhält er neu eine Karte und kann erneut tauschen (`core:197-205`).
  3. Wölfe: erhalten beim Spielstart keine Karte (`help:12`), aber beim Tod über `applyKill` (`core:197-205`), können also ebenfalls tauschen.
  4. Sieg: `>=10` Stapel bei lebendem Kartenschlucker, geprüft direkt nach Tausch (`help:180`), nach Ausspielen (`help:248`), im Nachtschritt (`chunk:225`) und bei jedem `save()` über `checkTeamWin` (`core:335`, aber erst nach den Team-Siegprüfungen). Toter Kartenschlucker gewinnt nie; Stapel bleiben erhalten.
  5. Nicht im Text: ab 2 Stapeln jede Nacht ein Kill (Ursache `KARTENSCHLUCKER_KILL`, sofort, ohne Stapelkosten), Ziel jede lebende Person einschließlich des Kartenschluckers selbst (`chunk:227-232`); einmal pro Nacht (`KartenschluckerKilledTonight`).
  6. Nicht im Text: ab 5 Stapeln setzt jeder Nachtschritt `KartenschluckerShield=true`; der Schild absorbiert einen Tod des Kartenschluckers jeder Ursache außer `PACKFATHER_KILL`, auch Lynch (`core:134-138`). Da er bei jedem Nachtschritt neu gesetzt wird, entspricht er einem Leben pro Nacht-Tag-Zyklus, aber nur, wenn der SL den Schritt aufruft (blockiert per Albtraum => kein Schild).
  7. Nicht im Text: öffentliche Ansage der Stapelzahl in jeder dritten Nacht, in der der SL den Schritt aufruft (`chunk:224,234`); `KartenschluckerNightCount` zählt nur aufgerufene Nächte.
  8. Sichtbarkeit: Stapelzahl nur über die Ansage öffentlich; Tausch findet im Totenkarten-Dialog statt (SL-Gerät).
  9. Mehrere Kopien: Stapel, Schild und Killsperre sind global in `state.once`; `help:77` und `core:243` prüfen "irgendein lebender Kartenschlucker"; Schild wirkt auf jeden Sitz mit Rolle Kartenschlucker.
  10. Zufall: Ersatzkarte über `zieheZufallsKarte` mit Math.random (`cards:667`, `cards:731`, Fallbacks `cards:726,743,745`).
  11. Schutz/Rettung: Kill wird durch Nekromant-Schild, Parasit-Immunität, Rudelvater, Hades-Barriere usw. in `applyKill` abgefangen; Schutzengel wirkt nicht (nur Rudelangriff).
- React-Version: kein eigenes Verhalten; nur Bildkarte (`roleCard.ts:72`). `legacy-bridge.js:46` spiegelt den Reset.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 54 (`04:83`) "widersprüchlich", Zeilen `chunk:222-237`, `help:176`, `core:134-138,241-247` BESTÄTIGT; Kernaussage (Kill ab 2, Schild ab 5 jede Nacht, Ansage alle 3 Nächte) BESTÄTIGT. ERGÄNZT: Selbstkill möglich, Kill ohne Stapelkosten, Schild und Ansage hängen am Aufruf des Nachtschritts, Wölfe können ebenfalls tauschen.
  - 04 C `04:137` BESTÄTIGT; 04 F-5 `04:226` "verifiziert" BESTÄTIGT (Tausch funktioniert).
  - 01 §4.5 (`01:192`) "Kartenschlucker nur in checkTeamWin" BESTÄTIGT, mit Ergänzung: zusätzlich direkte Aufrufe `help:180,248`, `chunk:225`.
  - 07 Q1 (`07:38`) offen; Q3 (Totenkarten-Automatik) ist Voraussetzung.
  - NIGHT-REPORT-abilities.md:109 "Kartenschlucker passiv" WIDERLEGT: aktiver Nachtschritt mit Kill-Pick (`chunk:226-233`), nicht in Passiv-Liste (`night:96`).
  - AUDIT.md:77 Zeilenangaben veraltet (`core.js:228` jetzt `core:241-247`).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Zusatzkräfte Kill/Schild/Ansage | nur Stapel und Sieg | nur Stapel und Sieg | Kill ab 2 jede Nacht, Schild ab 5, Ansage jede 3. Nacht (`chunk:222-237`) | keine | 04: widersprüchlich; 07: offen | reine Sammelrolle (Text) | Sammelrolle mit Eskalationsstufen (Code) | Code macht die Rolle ab 2 Stapeln zum Nachtmörder mit Schneeballeffekt (mehr Tote, mehr Tauschmöglichkeiten) | Code-Variante braucht Kill, Schild, Ansage zusätzlich | PO entscheidet; bei Beibehaltung Text ergänzen | Ja |
| Wer darf tauschen | "ein Toter" | "a dead player" | jeder Tote inkl. Wölfe, einmal je Karte, freiwillig (`help:169-184`) | keine | nicht dokumentiert | jeder Tote frei | nur Nicht-Wölfe oder nur einmal pro Person | Wölfe können Solo-Sieg beschleunigen oder bewusst verhindern | Regel im Totenkarten-Assistenten | Text präzisieren | Ja |

- Bugs:
  1. Einstufung: unklare Regel. Codepfad `chunk:232`. Tatsächlich: Kill-Pick erlaubt den Kartenschlucker selbst. Erwartet: nicht definiert. Risiko: niedrig. Test: Selbstwahl beim Kill abgelehnt oder erlaubt gemäß PO.
  2. Einstufung: technische Altlast. Codepfad `chunk:224-235`. Schild-Neuaufbau und Ansage sind an den manuellen Aufruf des Nachtschritts gekoppelt; bei Albtraum-Blockade (`ab:97-99`) oder vergessenem Aufruf fehlen sie. Risiko: mittel. Test: 5 Stapel, Nachtschritt blockiert => Schild-Verhalten gemäß PO (passiv oder nicht).
  3. Einstufung: technische Altlast. Codepfad `core:287-335`. Sieg bei >=10 über `checkTeamWin` wird erst nach Team-Siegen geprüft; direkte Aufrufe in `help:180` haben keine Priorität gegenüber gleichzeitigen Team-Siegen (Q4 Siegpriorität). Risiko: niedrig.
- Legacy-Status: legacy-contradictory. Begründung: Textmechanik (Stapel pro Tausch, Sieg bei 10) ist korrekt umgesetzt; der Code enthält drei wesentliche, im Text fehlende Kräfte.
- Automationsvorschlag: assisted. Stapelzählung und Sieg sind automatisierbar, setzen aber einen Totenkarten-Assistenten mit Tauschbefehl voraus (Q3); Kill-Ziel und Tauschentscheidung sind Eingaben.
- Mechanikfamilie: primär Totenkarten-Interaktion; sekundär Einzelsieg, Tötung, Schutz, Zufallsmechanik.
- Benötigte vorhandene Godot-Systeme: KillPipeline (Kill, Schild als Abfangstufe), StepQueue, PendingPrompt, SeededRng (Ersatzkarte), WinRules/WinCandidate, Ereignis-Sichtbarkeit (öffentliche Ansage), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Totenkarten-Effektmodell (mindestens Ziehen, Tauschen, Ausspielen, Zustand je Toter), Ressourcenzähler als dauerhafter Statusmarker, zusätzliche Siegbedingung; bei Beibehaltung der Code-Kräfte: persönlicher, jede Nacht erneuerter Schild.
- Abhängigkeiten: alle Rollen, die Tote erzeugen (mehr Tote = mehr Tauschgelegenheiten), Totenkarten-System (`cards`), Frankenstein/Kutscher (Wiederbelebung ermöglicht erneuten Tausch), Nekromant/Hades/Parasit/Rudelvater (Abfangregeln in `applyKill` vor bzw. nach dem Schild), Albtraumwolf/Schattenhund/Zeitwächter (blockieren den Nachtschritt).
- Komplexität und Fehlerrisiko: L, hoch. Abhängig von einem in Godot nicht existierenden Totenkarten-System; Zusatzkräfte mit Schneeballeffekt; Siegprüfung an mehreren Stellen.
- Offene Entscheidungen:
  1. Bleiben Kill ab 2, Schild ab 5 und Ansage alle 3 Nächte erhalten? Kostet der Kill Stapel?
  2. Darf jeder Tote (auch Wölfe) tauschen, und wie oft pro Person?
  3. Ist der Schild passiv (ab 5 Stapeln immer) oder an den Nachtschritt gekoppelt?
  4. Ist die Stapelzahl öffentlich (Ansage) oder geheim?
  5. Gewinnt ein toter Kartenschlucker, wenn nach seinem Tod 10 Stapel erreicht würden (heute: keine Stapel nach Tod)?
- Relevante Testgruppen:
  - Normalfall: Toter tauscht => +1 Stapel, Ersatzkarte muss sofort gespielt werden.
  - ungültiges Ziel: Kill auf tote Person abgelehnt.
  - tote Person: toter Kartenschlucker => kein Tauschbutton, keine Stapel, kein Sieg.
  - Selbstwahl: Kill auf sich selbst gemäß PO.
  - mehrere Kopien: zwei Kartenschlucker teilen den Stapel; ein toter und ein lebender => Tausch weiter möglich.
  - Wiederbelebung: wiederbelebter und erneut gestorbener Toter kann erneut tauschen.
  - Rollenwechsel: Rolle per Kutscher vergeben => vorhandener globaler Stapel zählt sofort.
  - Save/Load: Stapelstand, Schild, `KartenschluckerNightCount` bleiben erhalten.
  - Replay: Ersatzkarte mit gleichem Seed identisch.
  - SL-Korrektur: Stapel manuell korrigieren mit Protokoll.
  - Sichtbarkeit: Ansage public, Tausch gm.
  - Schutz: 5 Stapel, Lynch => Schild absorbiert; `PACKFATHER_KILL` => kein Schutz.
  - Todesreaktionen: Kill auf Sensenträger löst Reaktion aus.
  - Siegprüfung: 10. Tausch => sofortiger WinCandidate; gleichzeitige Wolfsparität => Priorität gemäß Q4.
  - beschädigter Spielstand: `KartenschluckerStapel` fehlt oder ist kein Number => auf 0 normalisiert (`help:47`, `cards:816`).
- Belegsicherheit: hoch. Nicht verifiziert: ob die Ansage (`center`) und der gleichzeitig geöffnete Kill-Pick im Browser kollidieren (Code öffnet beide synchron, `chunk:227,234`).

---

### hades
- DE-Name / EN-Name: Hades / Hades (`roles:185`).
- Aliase/Altnamen: keine Migration. Bilder `assets/cards/de/Hades.webp`, `assets/cards/en/Hades.webp` (`gh:835`, `roleCard.ts:73`). Todesursache `HADES_KILL` (`ab:37`, Label `ui:408`, Ritter-Vergeltungsliste `core:431`).
- Legacy-ID: "Hades" (ALL_ROLES Index 54).
- Fraktion: solo. Nicht im `isWolf`-Ausschluss (`core:13`). Tags `["solo-win","dead-interaction"]` (`roles:295`), ungenutzt.
- Akte: Akt IV (`akte:84`).
- Nachtpriorität: tier 9.9, nicht once, letzte Position (`roles:60`). Nachtschritt jede Nacht bei lebendem Hades.
- Quelltextstellen:
  - `roles:111` / `roles:260`; `ra:67`.
  - `ab:27-58` Handler "Hades": Menü je Lichterstand: Kill (>=2, einmal pro Nacht), Barriere (>=3, wenn keine aktiv), Stimme x3 (>=5, einmalig), Sieg einlösen (>=10), Nichts tun.
  - `core:139-143` `applyKill`: Barriere absorbiert Tod des Hades (außer `PACKFATHER_KILL`).
  - `core:208-211` `applyKill`: jeder erfolgreiche Tod, solange ein Hades lebt, gibt +1 Licht, danach `checkHadesWin`.
  - `core:249-258` `checkHadesWin` (>=10, lebend, kein `TeamWinner`).
  - `ui:18` `voteWeight`: Hades mit `HadesVoteBonus` = 3; Funktion wird nirgends aufgerufen (rg: einzige Fundstelle).
  - `night:236` Reset `HadesKilledTonight` bei Tagbeginn.
  - `chunk:845` Kutscher schließt bereits vergebene Rollen aus ("revive must not duplicate e.g. Hades").
  - `state:69`, `gh:524` Initialisierung/Reset.
- Text DE (wörtlich, `roles:111`): "Sammelt Lebenslichter von Toten. Kauft Fähigkeiten und gewinnt bei 10 Lichtern."
- Text EN (wörtlich, `roles:260`): "Collects life lights from the dead. Buys abilities and wins at 10 lights."
- DE/EN-Vergleich: semantisch gleich JA (geprüft: Quelle "von Toten"/"from the dead", "Kauft Fähigkeiten"/"Buys abilities", Zahl 10). Beide nennen weder Preise noch Fähigkeiten.
- Weitere Texte: `ra:67` identisch zu DE. Menütexte (`i18n:306-311`, EN `i18n:630-635`) definieren die Preise 2/3/5/10, die in keinem Rollentext stehen. Kein Totenkarten-Bezug außer: Tote durch Totenkarten-Effekte laufen nur manuell (keine Karte automatisiert), geben also keine Lichter, sofern der SL nicht `applyKill`-Pfade nutzt.
- Legacy-Codeverhalten:
  1. Lichter: +1 bei jedem erfolgreichen `applyKill` irgendeiner Person, solange irgendein Hades lebt (`core:208-211`), unabhängig von Ursache, auch für eigene Hades-Kills (Nettokosten Kill = 1) und Kettentode. Tod des Hades selbst gibt kein Licht (Flag `dead` wird vorher gesetzt). Abgefangene Tode (Schilde, Immunität) geben kein Licht. Manueller Tod-Chip gibt kein Licht.
  2. Kill (2 Lichter): einmal pro Nacht (`HadesKilledTonight`), Ziel jede lebende Person außer Rolle Hades (`ab:37`), sofortiger Tod `HADES_KILL`; Lichter werden auch bei abgefangenem Tod abgezogen.
  3. Barriere (3 Lichter): nur kaufbar, wenn keine aktiv; absorbiert den nächsten Tod eines Hades jeder Ursache außer `PACKFATHER_KILL`, auch Lynch (`core:139-143`); nach Verbrauch erneut kaufbar; kein Verfall.
  4. Stimme x3 (5 Lichter): einmal pro Spiel (`HadesVoteBonus` nie zurückgesetzt außer bei neuer Runde); ohne jede Wirkung und ohne Anzeige, da `voteWeight` nirgends aufgerufen wird und der Wert nicht dargestellt wird.
  5. Sieg: automatisch in `applyKill`, sobald Kontostand >=10 bei lebendem Hades und noch kein Sieger (`core:210,249-258`), vor `checkWinConditions`. Der Button "Sieg einlösen" (`ab:50-54`) ist dadurch nur erreichbar, wenn `checkHadesWin` wegen bestehendem `TeamWinner` nicht gegriffen hat oder der Stand geladen/manuell gesetzt wurde; er ruft `triggerWin` ohne Guard und überschreibt einen bestehenden Sieger.
  6. Mehrfachnutzung: in einer Nacht Kill, Barriere und Stimmbonus kombinierbar (Menü mehrfach aufrufbar).
  7. Sichtbarkeit: Lichterstand im Dialogtitel (`ab:31`), nur SL; keine öffentliche Ansage.
  8. Mehrere Kopien: Lichter, Barriere, Bonus global; `ab:52` `seats.find` erster Hades; Kutscher vergibt keine doppelte Hades-Rolle (`chunk:845`).
  9. Zufall: kein Math.random.
  10. Wiederbelebung/Rollenwechsel: Lichter bleiben global erhalten; eine per Frankenstein neu vergebene Hades-Rolle erbt den Stand.
- React-Version: kein eigenes Verhalten; nur Anzeige des Dialogtitels mit Lichterzahl (`app/src/components/ActionCenter.tsx:193`, `app/src/styles/tokens.css:1415`) und Bildkarte.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 55 (`04:84`) "verifiziert (Stimmbonus fehlend)", Zeilen `ab:27-58`, `core:139-143,208-211,249-258` BESTÄTIGT; "Sieg 10 (auch automatisch)" BESTÄTIGT. ERGÄNZT: Stimmbonus ist nicht nur ohne Wirkung, sondern auch unsichtbar; Einlöse-Button kann bestehenden Sieger überschreiben; eigene Kills geben Lichter.
  - 01 `01:195` (`triggerWin` überschreibt, `ab:52`) BESTÄTIGT.
  - 07 Q2 (`07:51`) Hades x3 hängt an Stimmsystem; DECISION-LOG (`DECISION-LOG.md:23`) "Stimmen werden nicht digital gespeichert" => Stimmbonus bleibt SL-Handarbeit.
  - 07 Q1 Zeile "Reaktionen auf Sofort-Tode" (`07:43`) betrifft den Hades-Kill.
  - SPECIAL-ROLE-FLOW-REPORT.md §4 "funktioniert" BESTÄTIGT für den Einlösepfad, allerdings nur mit vorab gesetztem `HadesLichter=10` getestet (im normalen Spiel greift vorher der Automatiksieg).
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Sieg automatisch oder eingelöst | "gewinnt bei 10 Lichtern" | "wins at 10 lights" | beides: Automatik (`core:210`) und Einlöse-Button, der 10 Lichter kostet (`ab:50-54`) | nur Titel | 04: "auch automatisch" | Sieg sofort bei 10 | Sieg nur durch bewusstes Einlösen (Lichter könnten vorher ausgegeben werden) | Einlösen erlaubt Taktik (Lichter sparen/ausgeben) | eine Siegregel als WinCandidate | Automatik bei 10 mit SL-Bestätigung, Button streichen | Ja |
| Zählen eigene Kills | "Sammelt Lebenslichter von Toten" | "from the dead" | jeder Tod inkl. eigener Kills (`core:209-210`) | keine | nicht dokumentiert | jeder Tod zählt | nur Tode durch andere | Kill kostet netto 1 statt 2 | Filter nach Quelle | PO | Ja |
| Stimme x3 | nicht erwähnt (nur "Kauft Fähigkeiten") | nicht erwähnt | Flag ohne Wirkung und ohne Anzeige | keine | 04: "Stimmbonus fehlend"; DECISION-LOG: Stimmen physisch | Kauf bleibt, SL wird erinnert | Kauf streichen | Kauf ohne Anzeige ist wertlos | dauerhafter Statusmarker mit Hinweis beim Tag | Marker sichtbar machen | Ja |

- Bugs:
  1. Einstufung: echter Bug. Codepfad `ui:18` (unbenutzt), `ab:45-47`. Tatsächlich: gekaufter Stimmbonus verbraucht 5 Lichter und ist nirgends sichtbar. Erwartet: Bonus wirkt oder wird dem SL angezeigt. Risiko: mittel (Spieler zahlt für nichts). Test: Bonus kaufen => Marker/Hinweis am Hades-Sitz am Tag.
  2. Einstufung: echter Bug (Randfall). Codepfad `ab:50-52` mit `core:85-100`. Tatsächlich: Einlösen ruft `triggerWin` ohne `TeamWinner`-Guard und überschreibt einen bereits entschiedenen Sieg. Erwartet: kein zweiter Sieger. Risiko: niedrig. Test: `TeamWinner` gesetzt, Lichter >=10, Einlösen => abgelehnt.
  3. Einstufung: unklare Regel. Codepfad `ab:37`: Lichter werden auch abgezogen, wenn der Tod durch Schild/Immunität abgefangen wird. Risiko: niedrig. Test gemäß PO.
- Legacy-Status: legacy-verified. Begründung: Der knappe Text (Lichter von Toten, Fähigkeiten kaufen, Sieg bei 10) ist nachvollziehbar umgesetzt; Preise und Fähigkeiten sind nur im Code definiert. Der wirkungslose Stimmbonus und der doppelte Siegpfad sind Nebenfunktionen, nicht die Kernfunktion.
- Automationsvorschlag: assisted. Lichter, Kill, Barriere und Sieg automatisch; Stimmbonus nur als Hinweis (Stimmen physisch laut DECISION-LOG).
- Mechanikfamilie: primär Einzelsieg; sekundär Tötung, Schutz, sonstige Spezialmechanik (Lichter-Ökonomie).
- Benötigte vorhandene Godot-Systeme: KillPipeline (Tod-Ereignis als Lichterquelle, Barriere als Abfangstufe, `HADES_KILL`), StepQueue, PendingPrompt (mehrstufiges Kaufmenü, abbrechbar), WinRules/WinCandidate, Reaktionswarteschlange (Folgen des Sofort-Kills), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Ressourcenzähler als dauerhafter Statusmarker, persönlicher Schild mit Kaufbedingung, dauerhafter Statusmarker "Stimme x3" (Anzeige, kein Stimmsystem), zusätzliche Siegbedingung.
- Abhängigkeiten: jede tötende Rolle (Lichterquelle), Nekromant (Schild fängt Hades-Kill ab, Lichter trotzdem weg), Rudelvater (`PACKFATHER_KILL` durchbricht Barriere), Ritter (Vergeltung bei `HADES_KILL`, `core:431`), Kutscher/Frankenstein (Rollenvergabe), Totenkarten mit Stimmbezug.
- Komplexität und Fehlerrisiko: M, mittel. Klare Ökonomie, aber globaler Todeszähler und Wechselwirkung mit allen Abfangregeln.
- Offene Entscheidungen:
  1. Sieg automatisch bei 10 oder nur durch Einlösen?
  2. Geben eigene Hades-Kills Lichter?
  3. Stimme x3 behalten (als SL-Hinweis) oder streichen? Ist der Kauf öffentlich?
  4. Werden Lichter bei abgefangenem Kill erstattet?
  5. Soll der Rollentext Preise und Fähigkeiten nennen?
- Relevante Testgruppen:
  - Normalfall: drei Tode => 3 Lichter; Barriere kaufen => 0 Lichter, Barriere aktiv.
  - ungültiges Ziel: Kill auf tote Person oder auf Hades abgelehnt.
  - tote Person: toter Hades => keine Lichter mehr, kein Nachtschritt.
  - Selbstwahl: Kill auf sich selbst abgelehnt (`ab:37`).
  - mehrere Kopien: zwei Hades teilen Konto; einer tot => Zählung läuft weiter.
  - Wiederbelebung: wiederbelebter Hades behält Konto.
  - Rollenwechsel: Hades-Rolle wird neu vergeben => Konto übernommen oder zurückgesetzt gemäß PO.
  - Save/Load: Konto, Barriere, Bonus, `HadesKilledTonight` erhalten.
  - Replay: identischer Lichterverlauf.
  - SL-Korrektur: Lichter manuell setzen mit Protokoll; manueller Tod mit/ohne Folgen gibt Licht gemäß Regel.
  - Sichtbarkeit: Lichterstand gm; Hades-Kill public als Nachttod.
  - Schutz: Barriere vs Lynch (absorbiert), vs `PACKFATHER_KILL` (nicht).
  - Todesreaktionen: Hades-Kill auf Sensenträger/Ritter-Nachbar.
  - Siegprüfung: 10. Licht durch Wolfsangriff am Morgen => Hades-Kandidat vor Wolfsparität (heute Hades zuerst, `core:210` vor `core:213`).
  - beschädigter Spielstand: `HadesLichter` negativ oder kein Number.
- Belegsicherheit: hoch. Nicht verifiziert: ob irgendwo außerhalb von `js/`, `game.html`, `app/` Stimmen gewichtet werden (rg über das ganze Repo fand nur die Definition `ui:18`).

---

### grabraeuber
- DE-Name / EN-Name: Grabräuber / Grave Robber (`roles:206`).
- Aliase/Altnamen: State-Schlüssel ohne Umlaut `GrabrauberStolenRole` (`chunk:587`); Einmal-Schlüssel `Used["role_Grabräuber"]` (`night:3-5`). i18n `graverobberStolen` (`i18n:293`, EN `i18n:617`). Bilder `assets/cards/de/Grabräuber.webp`, `assets/cards/en/Grave_Robber.webp` (`gh:841`, `roleCard.ts:87`).
- Legacy-ID: "Grabräuber" (ALL_ROLES Index 68).
- Fraktion: solo; im `isWolf`-Ausschluss (`core:13`), kann nie als Wolf zählen.
- Akte: Akt II (`akte:43`).
- Nachtpriorität: tier 6.4, once (`roles:44`). Nachtschritt, solange lebend und `isOnceUsed("Grabräuber")` falsch (`night:60`).
- Quelltextstellen:
  - `roles:132` / `roles:282`; `ra:66`.
  - `chunk:583-591` Handler: bei bereits genutzt Meldung; sonst `pick` eines toten Sitzes mit Rolle, `markOnceUsed`, `state.once.GrabrauberStolenRole=t.role`, Meldung "Fähigkeit von {role} gestohlen - SL setzt um".
  - `GrabrauberStolenRole` wird nirgends gelesen (rg; bestätigt `01:290`).
  - Kein Eintrag in `checkWinConditions`/`checkTeamWin` (`core:218-337`), kein Siegcode im Repo.
  - `gh:558` "Einmal-Fähigkeiten zurücksetzen" leert `Used` und macht den Diebstahl erneut verfügbar; `gh:522` `clearRolesNewRound` leert `Used`, aber nicht `GrabrauberStolenRole`.
- Text DE (wörtlich, `roles:132`): "Kann einmalig die Fähigkeit eines toten Spielers stehlen. Gewinnt alleine."
- Text EN (wörtlich, `roles:282`): "May once steal the ability of a dead player. Wins alone."
- DE/EN-Vergleich: semantisch gleich JA (einmalig/once, Fähigkeit eines toten Spielers, gewinnt alleine). Beide nennen keine Siegbedingung.
- Weitere Texte: `ra:66` identisch. Laufzeittext `i18n:293` "SL setzt um" legt die Umsetzung in SL-Hand. Totenkarten: kein Bezug; beachte Totenkarte `solo_05` (`cards:501-504`), die eine Fähigkeit samt Siegbedingung vererbt (ähnliches Konzept, unverbunden).
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt ab Nacht 1 bis zur Nutzung; ohne Tote ist kein Ziel wählbar, Abbrechen verbraucht nichts.
  2. Ziel: jeder tote Sitz mit Rolle (`chunk:590`), auch Wölfe und Solos, auch Rollen mit bereits verbrauchter Einmalfähigkeit; lebende nicht.
  3. Verbrauch: einmal (`markOnceUsed`), Zeile verschwindet danach (`night:60`).
  4. Wirkung: nur Notiz `GrabrauberStolenRole` und Hinweis an den SL; keine Fähigkeitsübertragung, kein zusätzlicher Nachtschritt, keine Rollen- oder Fraktionsänderung, keine Weitergabe von Zählern.
  5. Sieg: nicht implementiert und im Text nicht definiert.
  6. Sichtbarkeit: SL-Meldung.
  7. Mehrere Kopien: Einmalflag ist rollenweit, nicht pro Sitz; ein zweiter Grabräuber hat nach der Nutzung des ersten keinen Schritt mehr.
  8. Zufall: keiner.
- React-Version: kein eigenes Verhalten; nur Bildkarte (`roleCard.ts:87`).
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 69 (`04:98`) "fehlend", `chunk:583-591` BESTÄTIGT; "heute nur Info; Solo-Sieg fehlt" BESTÄTIGT.
  - 04 D-5 (`04:197`), 07 Q4 (`07:81`), 01 (`01:97`) "kein Siegcode" BESTÄTIGT.
  - 01 `01:290` "`GrabrauberStolenRole` nie gelesen" BESTÄTIGT.
  - NIGHT-REPORT-abilities.md:101 "1 Ziel (1x)" BESTÄTIGT.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Was bedeutet "Fähigkeit stehlen" | "Fähigkeit ... stehlen" | "steal the ability" | nur Notiz, SL setzt um (`chunk:587-589`) | keine | 04: fehlend | Grabräuber erhält dauerhaft die Nachtfähigkeit der toten Rolle (inkl. Nachtschritt) | einmalige Nutzung der Fähigkeit | groß: je nach Zielrolle (z.B. Waldhexe, Hades) stark unterschiedlich | Fähigkeitsübertragung ist ein neues System; Rollenwechsel (RoleTransition) passt nicht, da Rolle/Fraktion bleiben sollen | PO; bis dahin manuell | Ja |
| Siegbedingung | "Gewinnt alleine" ohne Bedingung | "Wins alone" | keine | keine | 04/07 Q4: fehlend | erbt die Siegbedingung der bestohlenen Rolle | eigene Bedingung (z.B. letzter Überlebender) | ohne Bedingung ist die Rolle nicht gewinnbar | zusätzliche Siegbedingung | PO legt fest (Q4) | Ja |

- Bugs:
  1. Einstufung: unklare Regel (keine Siegbedingung definiert). Codepfad: fehlt in `core:218-337`. Risiko: hoch für Spielbarkeit. Test: nach PO-Festlegung Sieg-Kandidat.
  2. Einstufung: technische Altlast. `GrabrauberStolenRole` geschrieben, nie gelesen, nicht bei neuer Runde zurückgesetzt (`gh:521-525`). Risiko: niedrig.
- Legacy-Status: not-found. Begründung: Der Text verspricht das Stehlen einer Fähigkeit und einen Solo-Sieg; der Code speichert nur den Rollennamen, überträgt keine Fähigkeit und enthält keinen Siegcode.
- Automationsvorschlag: manual-only (bis zur PO-Festlegung). Danach je nach Regel assisted.
- Mechanikfamilie: primär Einmalfähigkeit; sekundär Einzelsieg, sonstige Spezialmechanik (Fähigkeitsübertragung).
- Benötigte vorhandene Godot-Systeme: StepQueue (einmaliger Schritt), PendingPrompt (tote Ziele), Player `ability_uses` (Einmalnutzung), InfoRecord (gestohlene Rolle), GmCorrections, StateCodec, Replay.
- Benötigte NEUE Systeme: Fähigkeitsübertragung/-kopie (Rolle bleibt, Fähigkeit wird zusätzlich ausgeführt; kein Punkt der Vorgabeliste, daher "sonstige"), zusätzliche Siegbedingung; ggf. zusätzlicher Nachtschritt für geerbte Fähigkeit.
- Abhängigkeiten: potenziell jede Rolle mit Nachtfähigkeit (Ziel des Diebstahls); Einmalrollen (bereits verbraucht?); Totenkarte `solo_05` (ähnliche Vererbung).
- Komplexität und Fehlerrisiko: M als SL-Assistenz (Notiz + Hinweis), XL bei echter Fähigkeitsübertragung; Risiko mittel (assistiert) bzw. kritisch (automatisch, da Wechselwirkung mit allen Rollen).
- Offene Entscheidungen:
  1. Dauerhafte oder einmalige Nutzung der gestohlenen Fähigkeit?
  2. Welche Rollen sind stehlbar (auch Wolfs- und Solofähigkeiten, passive Fähigkeiten, Siegbedingungen)?
  3. Welche Siegbedingung hat der Grabräuber?
  4. Übernimmt der Grabräuber Zähler/Zustände der toten Rolle (z.B. Hades-Lichter, verbrauchte Tränke)?
- Relevante Testgruppen:
  - Normalfall: toter Sitz gewählt => Notiz, Schritt verschwindet.
  - ungültiges Ziel: lebender Sitz oder Toter ohne Rolle abgelehnt.
  - tote Person: toter Grabräuber hat keinen Schritt.
  - Selbstwahl: nicht relevant, weil der Grabräuber lebt und nur Tote wählbar sind.
  - mehrere Kopien: zweiter Grabräuber nach Nutzung des ersten gemäß PO (heute gesperrt).
  - Wiederbelebung: bestohlener Toter wird wiederbelebt => Folge gemäß PO.
  - Rollenwechsel: nicht relevant bis PO-Regel (heute keine Übertragung).
  - Save/Load: Einmalflag und gestohlene Rolle bleiben erhalten.
  - Replay: identische Notiz.
  - SL-Korrektur: Einmalflag zurücksetzen mit Protokoll (heute globaler Reset `gh:558`).
  - Sichtbarkeit: Diebstahl gm, nicht public.
  - Schutz: nicht relevant, weil keine Schutzwirkung.
  - Todesreaktionen: nicht relevant (heute).
  - Siegprüfung: nach Q4.
  - beschädigter Spielstand: `GrabrauberStolenRole` mit unbekannter Rolle.
- Belegsicherheit: hoch (Fehlen per rg über gesamtes Repo ohne Markdown und node_modules bestätigt).

---

### parasit
- DE-Name / EN-Name: Parasit / Parasite (`roles:207`).
- Aliase/Altnamen: keine Migration. Meta-Feld `meta.parasiteHostId` (`chunk:594`, `core:107,163`); Ursache `PARASITE_HOST` (`core:164`, Label `ui:411`). Bilder `assets/cards/de/Parasit.webp`, `assets/cards/en/Parasite.webp` (`gh:841`, `roleCard.ts:88`). Früherer Fehler E1 (EN-Schlüssel "Parasite" statt "Parasit", GRIMMHAIN_ANALYSE_2026-06-12:217) ist behoben: `roles:283` nutzt "Parasit".
- Legacy-ID: "Parasit" (ALL_ROLES Index 69).
- Fraktion: solo; im `isWolf`-Ausschluss (`core:13`).
- Akte: Akt III (`akte:63`).
- Nachtpriorität: tier 6.2, nicht once (`roles:43`). Nachtschritt jede Nacht bei lebendem Parasit.
- Quelltextstellen:
  - `roles:133` / `roles:283`; `ra:71`.
  - `chunk:592-598` Handler: `pick` lebende Person, nicht Rolle Parasit; setzt `parasiteHostId` für ALLE Parasit-Sitze.
  - `core:106-110` `applyKill`: Parasit mit lebendem Wirt ist gegen jede Ursache außer `PARASITE_HOST` immun (`return false`).
  - `core:161-167` `applyKill`: stirbt ein Wirt, sterben alle lebenden Parasiten dieses Wirts (`PARASITE_HOST`).
  - `core:236-237` `checkWinConditions`: lebt ein Parasit und leben genau 3 Personen => `triggerWin("Parasit")`, nach Dorf- und Wolfsprüfung.
  - Nicht in `checkTeamWin` (`core:287-337`).
  - Lynch: `night:499-500` ruft `applyKill(target,"LYNCH")` und danach `finalizeLynch` unabhängig vom Ergebnis.
- Text DE (wörtlich, `roles:133`): "Wacht jede Nacht auf und kann sich an einen lebenden Spieler heften. Er stirbt nur, wenn sein Wirt stirbt. Gewinnt, wenn er die Final 3 erreicht."
- Text EN (wörtlich, `roles:283`): "Wakes each night and may attach himself to a living player. He only dies when his host dies. Wins if he reaches the final three."
- DE/EN-Vergleich: semantisch gleich JA (geprüft: jede Nacht, optional "kann/may", lebender Spieler, stirbt nur mit Wirt, Final 3). Keiner der Texte sagt "alleine".
- Weitere Texte: `ra:71` identisch. Laufzeit `i18n:294`. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: jede Nacht (tier 6.2, nach Wolfsphase, vor Sofort-Kills von Pestbringerin/Feuerteufel usw., nach Waldhexe 3.4 und Kartenschlucker 4.0); Wirtwechsel jede Nacht möglich, Abbrechen behält den alten Wirt.
  2. Ziel: lebend, nicht Rolle Parasit; Wölfe erlaubt.
  3. Immunität: solange `parasiteHostId` auf einen lebenden Sitz zeigt, scheitert jeder Tod des Parasiten (Wolf, Lynch, Hexe, Hades, Kartenschlucker, `PACKFATHER_KILL`, Henker) still (`core:109`), ohne Meldung. Ohne Wirt (vor der ersten Wahl) stirbt er normal.
  4. Lynch mit lebendem Wirt: Parasit überlebt, aber `finalizeLynch` protokolliert "wurde gelyncht", erhöht `LynchCount` und richtet Henker-Markierte hin (`night:499-500`, `night:404-418`).
  5. Kettentod: Wirt stirbt => Parasit stirbt mit `PARASITE_HOST` (`core:161-167`); dieser Kettentod durchläuft Nekromant-Schild, Rudelvater-Rettung usw. normal.
  6. Sieg: nur in `checkWinConditions` (nach jedem erfolgreichen `applyKill`), exakt 3 Lebende (nicht "3 oder weniger"); Dorfsieg (keine Wölfe) und Wolfsparität haben Vorrang (`core:227-233`). Sprung von 4 auf 2 Lebende (z.B. Wirt + Parasit sterben gemeinsam) verfehlt die Prüfung. Manipulator-Sieg im selben Aufruf wird durch den Parasit-Sieg überschrieben (`core:234-237`, `triggerWin` ohne Guard).
  7. Sichtbarkeit: Wirtwahl nur SL.
  8. Mehrere Kopien: alle Parasiten teilen denselben Wirt (`chunk:594`), Kettentod betrifft alle (`core:162-165`); Sieg nutzt `alive.find` (erster).
  9. Zufall: keiner.
- React-Version: kein eigenes Verhalten; nur Bildkarte.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 70 (`04:99`) "verifiziert", Zeilen BESTÄTIGT. ERGÄNZT: stiller Lynch-Fehlschlag mit falschem Protokoll, exakte 3-Personen-Prüfung, Dorf/Wolf-Vorrang, gemeinsamer Wirt bei mehreren Kopien.
  - 04 C `04:133` Parasit-Immunität BESTÄTIGT.
  - 01 `01:191` (nur `checkWinConditions`) BESTÄTIGT; `01:195` (Manipulator => Parasit überschreibt) BESTÄTIGT.
  - GRIMMHAIN_ANALYSE_2026-06-12:22-23 (Wolfsieg ohne `return`) WIDERLEGT für den aktuellen Stand: `core:233` hat `return`.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| "Final 3" und Siegvorrang | "Gewinnt, wenn er die Final 3 erreicht" | "reaches the final three" | genau 3 Lebende, nur wenn weder Dorf- noch Wolfssieg vorliegt (`core:227-237`) | keine | 04: verifiziert | Parasit gewinnt bei <=3 Lebenden immer (ggf. gemeinsam mit anderen) | wie Code, Team-Siege zuerst | Code: Parasit + 2 Dorf ohne Wölfe => Dorfsieg; Parasit + 2 Wölfe => Wolfssieg | Siegpriorität in WinRules (Q4) | PO mit Q4 | Ja |

- Bugs:
  1. Einstufung: echter Bug. Codepfad `night:499-500` + `core:106-110`. Tatsächlich: Lynch eines Parasiten mit lebendem Wirt scheitert still, trotzdem Protokoll "wurde gelyncht", `LynchCount+1`, Henker-Hinrichtungen. Erwartet: Lynch als wirkungslos erkannt (Meldung an SL, kein "gelyncht"-Eintrag). Risiko: mittel (SL glaubt, der Parasit sei tot). Test: Parasit mit Wirt lynchen => lebt, Protokoll "Hinrichtung ohne Wirkung".
  2. Einstufung: unklare Regel. Codepfad `core:237` (`alive.length===3`). Sprung von 4 auf 2 verfehlt den Sieg. Risiko: mittel. Test: 4 Lebende, Wirt und Parasit sterben in einer Kette => kein bzw. definierter Sieg.
  3. Einstufung: echter Bug (bekannt, F7). Codepfad `core:234-237`. Manipulator- und Parasit-Sieg im selben Aufruf: zweiter `triggerWin` überschreibt. Risiko: niedrig. Test: 3 Lebende mit Manipulator und Parasit => ein definierter Sieger oder Mitsieg.
- Legacy-Status: legacy-verified. Begründung: Wirtwahl, Immunität, Kettentod und Sieg bei drei Lebenden setzen den Text nachvollziehbar um; Lücken betreffen Randfälle (Lynch-Protokoll, Siegpriorität).
- Automationsvorschlag: automatic (Wirtwahl als Eingabe, Immunität, Kettentod und Siegkandidat vollautomatisch mit SL-Bestätigung).
- Mechanikfamilie: primär Verknüpfte Personen; sekundär Schutz, Todesreaktion, Einzelsieg.
- Benötigte vorhandene Godot-Systeme: KillPipeline (Immunitätsstufe, Kettentod als Folgetod), StepQueue, PendingPrompt, Reaktionswarteschlange (Kettentod), WinRules/WinCandidate, ExecutionRules (Hinrichtung ohne Wirkung), StateCodec, Replay, Ereignis-Sichtbarkeit.
- Benötigte NEUE Systeme: Bindungsmodell Parasit-Wirt (Verknüpfte Personen, pro Nacht änderbar), zusätzliche Siegbedingung (Final 3).
- Abhängigkeiten: jede tötende Rolle (Immunität), Rudelvater (`PACKFATHER_KILL` durchbricht Immunität NICHT, da Parasit-Prüfung zuerst), Nekromant-Schild (kann den Kettentod abfangen), Manipulator (gleichzeitiger Final-3-Sieg), Henker (`finalizeLynch`), Rotkäppchen/Schattenwanderer (weitere Ketten).
- Komplexität und Fehlerrisiko: M, mittel. Einfache Bindung, aber Eingriff an der ersten Stelle der Kill-Pipeline und Siegpriorität.
- Offene Entscheidungen:
  1. Gewinnt der Parasit bei 3 oder weniger Lebenden? Allein oder zusätzlich zu Dorf/Wölfen?
  2. Ist der Parasit auch gegen Hinrichtung immun, und wie wird das am Tisch kommuniziert?
  3. Dürfen mehrere Parasiten verschiedene Wirte haben?
  4. Darf ein Wolf Wirt sein?
- Relevante Testgruppen:
  - Normalfall: Wirt gewählt, Wolfsangriff auf Parasit => überlebt; Wirt stirbt => Parasit stirbt.
  - ungültiges Ziel: tote Person oder anderer Parasit als Wirt abgelehnt.
  - tote Person: toter Parasit hat keinen Schritt; toter Wirt => Parasit ohne Schutz.
  - Selbstwahl: abgelehnt (`chunk:597`).
  - mehrere Kopien: zwei Parasiten, ein Wirt => beide sterben mit dem Wirt.
  - Wiederbelebung: Wirt wiederbelebt => Parasit bleibt tot; Parasit wiederbelebt mit altem, totem Wirt => ohne Schutz.
  - Rollenwechsel: Wirt wechselt Rolle => Bindung bleibt.
  - Save/Load: `parasiteHostId` bleibt erhalten; neue Runde setzt es nicht zurück (`gh:517` merged `meta`), prüfen.
  - Replay: identische Immunitätsentscheidungen.
  - SL-Korrektur: SL tötet Parasit mit lebendem Wirt per Korrektur => definierte Wirkung.
  - Sichtbarkeit: Wirtwahl gm; gescheiterter Lynch public als "überlebt" gemäß PO.
  - Schutz: `PACKFATHER_KILL` auf Parasit mit Wirt => überlebt (heute).
  - Todesreaktionen: Wirt ist Sensenträger => Reaktion und Kettentod in definierter Reihenfolge.
  - Siegprüfung: 3 Lebende Parasit + Wolf + Dorf => Parasit; Parasit + 2 Dorf => Dorf (heute).
  - beschädigter Spielstand: `parasiteHostId` zeigt auf nicht existierende ID => keine Immunität.
- Belegsicherheit: hoch. Nicht verifiziert: Verhalten von `clearRolesNewRound` für `meta.parasiteHostId` im Browser (Code `gh:517` überschreibt `meta` per `Object.assign` mit Teilobjekt, das `parasiteHostId` nicht enthält, das Feld bleibt also erhalten; ohne Rolle Parasit aber wirkungslos).

---

### todesprediger
- DE-Name / EN-Name: Todesprediger / Death Prophet (`roles:208`).
- Aliase/Altnamen: keine Migration. i18n-Schlüssel `deathProphet*` (`i18n:295-298`, EN `i18n:619-622`). State `TodespredigerPrediction` (`chunk:628`, `core:153`). Bilder `assets/cards/de/Todesprediger.webp`, `assets/cards/en/Death_Prophet.webp` (`gh:842`, `roleCard.ts:89`). Namensnähe zu "Prophet des Untergangs" (eigene Rolle) beachten.
- Legacy-ID: "Todesprediger" (ALL_ROLES Index 70).
- Fraktion: solo; im `isWolf`-Ausschluss (`core:13`).
- Akte: Akt II (`akte:42`).
- Nachtpriorität: tier 6.6, once (`roles:45`). Da der Handler nie `markOnceUsed` aufruft, bleibt `isOnceUsed("Todesprediger")` falsch und der Schritt erscheint jede Nacht, solange der Todesprediger lebt (`night:60`).
- Quelltextstellen:
  - `roles:134` / `roles:284`; `ra:76`.
  - `chunk:599-644` Handler: bei vorhandener Vorhersage Meldung; sonst Texteingabe, Regex `(night|day|nacht|tag)\s*(\d+)` (`:621`), speichert `{t:"night"|"day", n}` (`:628`); keine Plausibilitätsprüfung (Vergangenheit, 0).
  - `core:153-159` `applyKill`: stirbt der Todesprediger mit Vorhersage, Treffer bei `night` und `state.nightCount===n` oder `day` und `state.once.MorningCount===n` => `triggerWin("Todesprediger")`.
  - Zähler: `nightCount` startet bei 1 (`setup.html:1154`), wird erst am Ende der Morgenauflösung erhöht (`night:350`, `afterCurses`); `MorningCount` wird zu Beginn von `onDayStart` erhöht (`night:191`), also VOR der Morgenauflösung (`night:239-282`, `resolveDayKills`).
  - Anzeige: Spielprotokoll labelt Tag-Einträge mit `nightCount` (`js/ui/gamelog.js:21-24,38`); Phasenzähler ebenso (`gh:1874-1876`), liest aber `window.state` (F8, meist undefiniert).
  - `gh:525` Reset `TodespredigerPrediction=null`, `MorningCount=0` bei neuer Runde.
- Text DE (wörtlich, `roles:134`): "Kündigt an, in welcher Nacht oder an welchem Tag er sterben wird. Liegt er richtig, gewinnt er alleine."
- Text EN (wörtlich, `roles:284`): "Predicts the exact night or day of his own death. If he is correct, he wins alone."
- DE/EN-Vergleich: semantisch gleich NEIN (leichte Unterschiede): (1) DE "Kündigt an" kann eine öffentliche Ankündigung bedeuten, EN "Predicts" ist neutral. (2) EN betont "exact", DE nicht. Beide nennen keinen Zeitpunkt der Vorhersage (Nacht 1?) und keine Zählbasis. Siegteil gleich.
- Weitere Texte: `ra:76` identisch zu DE. Eingabeaufforderung `i18n:298` erwartet "night N"/"day N" ohne Erklärung der Zählung. Kein Totenkarten-Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: beim ersten Aufruf des Nachtschritts (beliebige Nacht), einmal; danach nur Meldung "Vorhersage steht"; Schritt bleibt sichtbar.
  2. Eingabe: freier Text, DE/EN-Schlüsselwörter; keine Prüfung gegen aktuelle Nacht (vergangene Zeitpunkte möglich).
  3. Sieg: nur bei Tod über `applyKill`; Vergleich Nacht mit `nightCount`, Tag mit `MorningCount`.
  4. Zählbasis-Überschneidung: Tode der Morgenauflösung nach Nacht N (Wolfsangriff usw.) geschehen bei `nightCount=N` UND `MorningCount=N`; sowohl "night N" als auch "day N" treffen.
  5. Sofort-Tode während Nacht N (Hexe, Hades, Kartenschlucker) geschehen bei `nightCount=N`, `MorningCount=N-1`; treffen "night N" und "day N-1".
  6. Lynch am Tag nach Nacht N: `MorningCount=N`, `nightCount=N+1`; im Protokoll als "Tag N+1" gelabelt (`gamelog.js:21-24`), trifft aber nur "day N".
  7. Sichtbarkeit: Vorhersage nur SL; keine öffentliche Ankündigung.
  8. Mehrere Kopien: eine globale Vorhersage für alle Todesprediger; der erste, der eingibt, legt sie fest.
  9. Zufall: keiner.
  10. Manueller Tod-Chip (F6) und Zeitwächter-Frost (Nacht zählt nicht, `night:323-330`) beeinflussen die Zählung; bei Frost wird `nightCount` nicht erhöht.
- React-Version: kein eigenes Verhalten; nur Bildkarte.
- Bisherige Doku und Prüfergebnis:
  - 04 Zeile 71 (`04:100`) "verifiziert" mit Verweis auf D-3: Zeilen `chunk:599-644`, `core:153-159` BESTÄTIGT. Status "verifiziert" WIDERLEGT: die Zählbasis ist nicht nur unklar, sondern überschneidend (Punkt 4) und zur Protokollanzeige um eins versetzt (Punkt 6).
  - 04 D-3 (`04:195`) "unklar (Zählbasis)" BESTÄTIGT und präzisiert; 04 B-9 (`04:119`) Zeilenangaben `night:339`/`night:194` veraltet (aktuell `night:350` für `nightCount`, `night:191` für `MorningCount`).
  - FIX_REPORT.md:7 (Reset `TodespredigerPrediction`, `MorningCount`) BESTÄTIGT (`gh:525`).
  - NIGHT-REPORT-abilities.md:107 "Info/Eingabe, 1. Nacht" teilweise WIDERLEGT: Code erzwingt keine erste Nacht.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Öffentlich oder geheim | "Kündigt an" | "Predicts" | geheim, nur SL | keine | nicht dokumentiert | öffentliche Ankündigung | geheime Vorhersage beim SL | öffentlich: Dorf/Wölfe können gezielt töten oder schonen | Ereignis-Sichtbarkeit public vs gm | PO | Ja |
| Zeitpunkt der Vorhersage | nicht genannt | nicht genannt | beliebige Nacht, einmal | keine | NIGHT-REPORT: 1. Nacht | nur Nacht 1 | jederzeit einmal | spätes Vorhersagen ist deutlich leichter | Schritt nur Nacht 1 oder dauerhaft | Nacht 1 (sonst trivial) | Ja |
| Zählbasis Tag/Nacht | "in welcher Nacht oder an welchem Tag" | "exact night or day" | Nacht = `nightCount`, Tag = `MorningCount`, überschneidend | keine | 04 D-3 unklar | Tag N = Tag nach Nacht N, Morgentode zählen zur Nacht | Tag N wie im Protokoll angezeigt (= nach Nacht N-1) | Überschneidung verdoppelt Trefferchance bei Morgentoden | eindeutige `night_number`/`day_number` und Zuordnung jedes Todes zu genau einer Phase | Tode der Morgenauflösung zählen zur Nacht; Anzeige und Vergleich dieselbe Zahl | Ja |

- Bugs:
  1. Einstufung: echter Bug. Codepfad `night:191` (MorningCount vor Auflösung) mit `core:156-157`. Tatsächlich: Ein Tod in der Morgenauflösung nach Nacht N erfüllt "night N" und "day N" gleichzeitig. Erwartet: jeder Tod gehört zu genau einer Phase. Risiko: hoch (falscher Solo-Sieg). Regressionstest: Vorhersage "day 1", Wolfsangriff in Nacht 1 => kein Sieg; Vorhersage "night 1" => Sieg.
  2. Einstufung: echter Bug. Codepfad `core:157` vs `js/ui/gamelog.js:21-24` (und `gh:1874-1876`). Tatsächlich: Der erste Tag nach Nacht 1 wird als "Tag 2" gelabelt, der Vergleich nutzt `MorningCount=1`. Erwartet: angezeigte und verglichene Tageszahl identisch. Risiko: hoch (SL gibt angezeigte Zahl ein, Treffer bleibt aus). Test: Protokoll zeigt "Tag N", Vorhersage "day N", Lynch an diesem Tag => Sieg.
  3. Einstufung: technische Altlast. Codepfad `chunk:599-644` ohne `markOnceUsed` bei `roles:45` once:true. Schritt bleibt jede Nacht sichtbar. Risiko: niedrig. Test: nach Vorhersage kein Nachtschritt mehr.
  4. Einstufung: unklare Regel. Codepfad `chunk:621-628`: vergangene oder aktuelle Zeitpunkte akzeptiert. Risiko: mittel. Test: Vorhersage für bereits vergangene Nacht abgelehnt.
- Legacy-Status: legacy-broken. Begründung: Die Kernfunktion (Sieg bei korrekt vorhergesagtem Todeszeitpunkt) wird für Tagesvorhersagen durch die überlappende Zählung und den Versatz zur angezeigten Tagesnummer verfälscht (Bugs 1 und 2, beide mit Zeilenbeleg). Nachtvorhersagen funktionieren.
- Automationsvorschlag: automatic (nach PO-Festlegung der Zählbasis): Vorhersage als Eingabe, Treffer beim Todesereignis deterministisch, WinCandidate mit SL-Bestätigung.
- Mechanikfamilie: primär Einzelsieg; sekundär Einmalfähigkeit.
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (Eingabe Phase + Zahl, abbrechbar), KillPipeline (Todesereignis mit Phase), WinRules/WinCandidate, Ereignis-Sichtbarkeit, InfoRecord, StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: zusätzliche Siegbedingung; dauerhafter Statusmarker (gespeicherte Vorhersage). Voraussetzung: eindeutige Phasenzuordnung jedes Todes (Teil des Phasenmodells, B-9).
- Abhängigkeiten: alle tötenden Rollen; Zeitwächter (Frost, Nachtzählung), Lynch/Hinrichtung, Parasit-ähnliche Immunitäten und Schilde (verschieben Todeszeitpunkt), Frankenstein/Kutscher (Wiederbelebung und erneuter Tod).
- Komplexität und Fehlerrisiko: S (Logik) bis M (mit Phasenmodell), Risiko mittel: einfache Regel, aber vollständig von der Phasenzählung abhängig.
- Offene Entscheidungen:
  1. Wird die Vorhersage öffentlich angekündigt oder geheim beim SL abgegeben?
  2. Wann darf vorhergesagt werden (nur Nacht 1, jederzeit einmal)? Sind vergangene/aktuelle Zeitpunkte zulässig?
  3. Wie sind "Tag N" und "Nacht N" definiert, und zu welcher Phase gehören Tode der Morgenauflösung?
  4. Zählt ein Tod durch SL-Korrektur oder durch Totenkarten-Effekt?
  5. Was passiert bei Wiederbelebung und erneutem Tod (neue Vorhersage)?
- Relevante Testgruppen:
  - Normalfall: Vorhersage "night 2", Wolfsangriff Nacht 2 => Sieg.
  - ungültiges Ziel: ungültige Eingabe ("morgen", "night -1", "night 0") abgelehnt.
  - tote Person: toter Todesprediger hat keinen Schritt; Tod ohne Vorhersage => kein Sieg.
  - Selbstwahl: nicht relevant, weil keine Personenwahl.
  - mehrere Kopien: zwei Todesprediger mit je eigener Vorhersage gemäß PO (heute eine globale).
  - Wiederbelebung: wiederbelebter Todesprediger stirbt erneut zum vorhergesagten Zeitpunkt => Sieg gemäß PO.
  - Rollenwechsel: Rolle nach Vorhersage verloren => kein Sieg.
  - Save/Load: Vorhersage und beide Zähler bleiben erhalten.
  - Replay: identischer Sieg-Zeitpunkt.
  - SL-Korrektur: Tod per GmCorrection mit/ohne Folgen => Sieg nur mit Folgen.
  - Sichtbarkeit: Vorhersage gm oder public gemäß PO.
  - Schutz: vorhergesagte Nacht, Angriff durch Schutz verhindert => kein Sieg.
  - Todesreaktionen: Tod durch Sensenträger-Reaktion am Tag => Tageszählung.
  - Siegprüfung: Tod in Morgenauflösung Nacht 1 mit Vorhersage "day 1" => kein Sieg (Regression Bug 1).
  - beschädigter Spielstand: `TodespredigerPrediction` mit ungültigem `t` oder `n` als String.
- Belegsicherheit: hoch für Zählerpositionen und Vergleich. Mittel für die angezeigte Tagesnummer: der Phasenzähler liest `window.state` (F8) und zeigt im Normalbetrieb vermutlich dauerhaft "Tag 1"; die Protokoll-Labels (`gamelog.js`) sind die belastbare Anzeigequelle.

---

## Gruppenübergreifende Beobachtungen

1. Globale statt sitzgebundene Zustände: Nekromant-Schild und -Umlenkungssperre, Kartenschlucker-Stapel/-Schild/-Killsperre, Hades-Lichter/-Barriere/-Bonus, Grabräuber-Einmalflag und Todesprediger-Vorhersage liegen in `state.once` und gelten rollen-, nicht personenbezogen. Mehrere Kopien teilen sie; Rollenwechsel übernimmt fremde Stände. Godot sollte diese Zustände an die Person (Player) binden.
2. Drei Solo-Schilde in `applyKill` (`core:127-143`) mit identischer Ausnahme `PACKFATHER_KILL`, aber unterschiedlicher Reichweite (Nekromant global, Kartenschlucker/Hades persönlich) und fester Reihenfolge nach Parasit/Rudelvater/Schattenwanderer. Die Parasit-Immunität kennt diese Ausnahme nicht. Empfehlung: eine einheitliche Abfangstufe in der KillPipeline mit expliziter Priorität.
3. `isWolf`-Ausschlussliste (`core:13`) ist inkonsistent: Parasit, Grabräuber, Todesprediger sind gegen `cursedWolfAura`/`flags.werewolf` immun, Nekromant, Kartenschlucker, Hades nicht. Das beeinflusst Wolfsparität und die Nekromant-Benennung. Nicht in 04 dokumentiert.
4. Siegprüfung zersplittert: Hades in `applyKill` vor `checkWinConditions`; Parasit nur in `checkWinConditions`; Kartenschlucker nur in `checkTeamWin` plus Direktaufrufe; Todesprediger in `applyKill`; Nekromant über Tagesbutton; Grabräuber gar nicht. Nur `checkHadesWin`, `checkKartenschluckerWin`, `checkWinConditions` und der Nekromant-Button prüfen `TeamWinner`; `triggerWin` selbst nicht (`core:85-100`), daher überschreiben Hades-Einlösen, Todesprediger und Parasit (nach Manipulator) bestehende Sieger. Passt zu 07 Q4 und DECISION-LOG "Mögliche Siege werden erkannt, aber erst durch den Spielleiter bestätigt" (WinCandidate).
5. Stimmbezug ohne Stimmsystem: Nekromant ("Stimmen opfern", Tote-Stimm-Marker nur bei lebendem Nekromant, `ui:109`) und Hades (x3, `ui:18` unbenutzt) beziehen sich auf Stimmen, die laut DECISION-LOG nicht digital gezählt werden. Beide brauchen in Godot nur Statusmarker plus SL-Hinweis, kein Stimmsystem.
6. Pick-Abbruch ohne Fortsetzung: `startPick`/`startMulti` geben kein `onCancel` weiter (`ui:325,340`). In der Morgenauflösung (Nekromant-Umlenkung) führt das zu hängender Auflösung. Godot-PendingPrompt mit Abbruchsemantik deckt das ab, muss aber für Pflichtprompts in der Auflösung einen definierten Abbruchpfad haben.
7. Fehler/Veraltetes in 04 und Berichten: 04 Zeile 71 (Todesprediger) "verifiziert" ist zu optimistisch (Zählbugs); 04 B-9 Zeilenangaben veraltet (`night:339`/`night:194` jetzt `night:350`/`night:191`); NIGHT-REPORT-abilities.md:109 "Kartenschlucker passiv" falsch; AUDIT.md:135 (Totenrat-Buttons tot) und GRIMMHAIN_ANALYSE_2026-06-12 A5/E1 sowie A1 (fehlendes `return` bei Wolfsieg) sind inzwischen behoben; AUDIT.md:77 Zeilenangabe veraltet. 04 Zeile 53 nennt den Abbruch-Bug und die getrennten Ressourcenlisten nicht.
8. Totenkarten-Abhängigkeit: Nur der Kartenschlucker hängt mechanisch am Totenkarten-System; Hades-Lichter und Todesprediger-Sieg hängen am Todesereignis. Alle sechs Solos ziehen beim Tod überwiegend SOLO-Karten (`cards:650-671`). Ohne Totenkarten-Assistent (07 Q3) ist der Kartenschlucker in Godot nicht spielbar.
9. Kein automatisierter Test und keine Godot-Implementierung für eine der sechs Rollen (rg über `tests/` und `godot/` ohne Treffer).
10. Rollen-Tags `solo-win`, `vote-manipulation`, `dead-interaction` (`roles:293-295`) werden von keiner Logik ausgewertet; nur die Revive-Tags werden für Totenkarten-Bedingungen genutzt (`cards:573`, `night:29-31`).
