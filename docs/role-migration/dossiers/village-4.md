<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G8 Village 4: Legacy-Rollenprüfung

Geprüfte Rollen: schutzgeist, dorfchronistin, waechter-am-tor, zeitwaechter, amalia, kriegerin-des-lichts, detektiv, dorfschmied.
Stand Repository: /home/user/Grimmhain-Revolution (nur gelesen, nichts geändert).
Hinweis: Gedankenstriche (Em-Dashes) erscheinen nur innerhalb wörtlicher Zitate aus Code oder Rollentexten.

Pfadkürzel: roles = js/core/roles.js, chunk = js/core/abilities-roles-chunk.js, ab = js/core/abilities.js, night = js/core/night.js, core = js/ui/core.js, ui = js/ui/ui.js, state = js/core/state.js, gh = game.html, i18n = js/core/i18n.js, akte = js/core/akte.js, ra = js/core/role-abilities.js, doc04 = docs/godot-migration/04-rules-migration-matrix.md, doc01 = docs/godot-migration/01-current-system-inventory.md, doc07 = docs/godot-migration/07-open-questions.md.

Gemeinsame Grundlagen (für alle Rollen geprüft):
- `onOrderClick` (ab:71-125) hat keine Prüfung auf `state.dark`; Blockaden ab:94-99 (Schattenhund, Zeitwächter, Der-Weise-Debuff, Albtraum) gelten für alle Rollen außerhalb `WOLF_ROLES_SET`.
- `rebuildOrder` (night:22-128): `rig = rolesInGame()` enthält nur Rollen LEBENDER Sitze (night:6); `if(!rig.has(o.r))return` (night:58) filtert vor allen Sonderfällen; `once`-Rollen verschwinden nur über `isOnceUsed(o.r)` (night:60, night:4); passive Rollen ohne Zeile: night:96.
- `center(txt, ok)` (ui:43-53) ist ein einziges SL-Modal (`#overlay`); `ok` ändert nur den Titel. Es gibt keine technische Trennung öffentlich/geheim; "öffentlich" heißt: der SL liest vor.
- `window.t(key)` (i18n:652-655) gibt bei fehlendem Schlüssel den Schlüssel zurück, ersetzt KEINE Platzhalter; nur `window.tf` (i18n:657-664) ersetzt `{name}`/`{n}`. Die `||`-Fallbacks hinter `window.t(...)` werden daher praktisch nie benutzt.
- `isWolf` (core:8-19) zählt `WOLF_ROLES_SET`, `flags.werewolf` UND `meta.cursedWolfAura` (Dämonischer-Wolf-Fluch) als Wolf; Doppelspion, Manipulator, Parasit, Grabräuber, Todesprediger nie.
- Siegprüfung `checkWinConditions` (core:218-239): alle acht Rollen sind Dorf und gewinnen nur mit dem Dorf (keine Sonderbedingung gefunden).
- `clearRolesNewRound` (gh:512-529) setzt `SchmiedForgeNights` und `Used` zurück, aber NICHT `SchmiedWeaponGiven`, `ChroniclerShown`, `SchutzgeistAwaitingPick`, `TimekeeperFreezeMorning` (per Auflistung der `state.once.*`-Zuweisungen gh:505-527 geprüft). Neue Runde über diesen Knopf erbt diese Flags. Andere Setup-Wege nutzen `createState` (state:9-14) und sind sauber.
- `resetOnceForInheritedRole` (core:339-359) löscht nur `state.once[role+"Used"]` und einige Sonderflags; die tatsächlich benutzten Schlüssel `state.once.Used["role_<Rolle>"]` (night:5) sowie `SchmiedWeaponGiven`/`ChroniclerShown` bleiben. Erbt jemand (Lehrling, Seelentauscher) eine dieser Rollen, gilt der globale Verbrauch weiter.
- React (app/src): Für alle acht Rollen nur Bildzuordnung in app/src/roleCard.ts:14,77-84; Logik läuft über den Legacy-Adapter (app/src/adapter/legacy/legacyAdapter.ts:503,608 `onOrderClick`; domMirror.ts spiegelt `#overlay` generisch). Kein eigenes Regelverhalten.
- Keine Migrationsaliase in `migrateLegacyRoleIds` (state:16-40) für diese acht Rollen.
- Git-Historie ist flach (51 Commits), frühere Handler-Versionen nicht rekonstruierbar.

---

### schutzgeist
- DE-Name / EN-Name: Schutzgeist / Guardian Spirit (roles:196)
- Aliase/Altnamen (state.js migrateLegacyRoleIds, i18n, Bilder, sonstige Schreibweisen im Code): kein Alias in state:16-40. Bilder: assets/cards/de/Schutzgeist.webp, assets/cards/en/Guardian_Spirit.webp (gh:836, app/src/roleCard.ts:77). i18n-Schlüssel `schutzgeistWolf` (i18n:230/559), `schutzgeistNotActive` (i18n:283/607). Flag `state.once.SchutzgeistAwaitingPick`. tools/create_role_doc.py:247-249 enthält eine Alttextfassung.
- Legacy-ID (String in ALL_ROLES): "Schutzgeist" (roles:1, Position 59)
- Fraktion (getRoleFaction) und weitere Fraktionsbesonderheiten im Code: dorf (roles:405-409; weder in WOLF_ROLES_SET roles:391 noch SOLO_ROLES_SET roles:399). Keine Sonderbehandlung.
- Akte (akte.js): Akt II (akte:36)
- Nachtpriorität (ORDER_BASE tier, once) und Bedingungen für den Nachtschritt (night.js): tier 5.6, kein once (roles:40). Sonderfall night:91-92 verlangt toten Schutzgeist mit `SchutzgeistAwaitingPick`. Dieser Sonderfall ist unerreichbar, weil night:58 alle Rollen ohne lebenden Inhaber vorher verwirft (rig aus night:6). `onOrderClick` hätte die Ausnahme `allowNoLivingActor` (ab:78).
- Quelltextstellen (Liste pfad:zeilen Symbol – was dort passiert):
  - roles:40 ORDER_BASE – tier 5.6
  - roles:122 / roles:272 ROLE_DESCRIPTIONS / _EN – Rollentext
  - core:151 applyKill – setzt `SchutzgeistAwaitingPick=true` bei jedem Tod eines Sitzes mit Rolle Schutzgeist (jede Ursache)
  - night:58 rebuildOrder – verwirft Rolle, weil kein lebender Inhaber (Ursache F1)
  - night:91-92 rebuildOrder – toter Sonderfall
  - ab:78 onOrderClick – `allowNoLivingActor` für toten Schutzgeist
  - chunk:494-505 Handler "Schutzgeist" – Pick lebender Sitz, `protectedCount+1`, `protected=true`, öffentliche Meldung bei `isWolf`, Flag zurück auf false
  - chunk:162 Werwolf-Handler – Schutz wird nur beim Rudel-Pick geprüft und verbraucht
  - chunk:348-350 Rachsüchtiger Wolf – gleiche Schutzprüfung
  - night:145 onNightStart – setzt `protected`/`protectedCount` aller Sitze außer Der Weise zurück
  - night:514 resetMarksOnly – löscht Schutz
- Text DE (wörtlich): "Wählt in der Nacht nach ihrem Ableben einen Spieler. Dieser erhält ein Schutzschild. Hat sie einen Werwolf gewählt, erfährt das Dorf davon."
- Text EN (wörtlich): "On the night after their death, chooses a player. That player receives a shield. If she chose a werewolf, the village is told."
- DE/EN-Vergleich (semantisch gleich JA/NEIN + konkrete Unterschiede): JA. Nur Pronomenwechsel "their"/"she" im EN. Die in GRIMMHAIN_ANALYSE_2026-06-12.md:219 (E3) gemeldete fehlende Wolf-Offenbarung im EN ist inzwischen behoben (roles:272 enthält sie).
- Weitere Texte (role-abilities.js, i18n.js, Totenkarten-Bezug), falls abweichend: ra:31 identisch mit DE. i18n `schutzgeistWolf` "ÖFFENTLICH: Der Schutzgeist hat einen Werwolf gewählt!" nennt keinen Namen. Alttext tools/create_role_doc.py:248-249: EN "shields a chosen player from the next attack" (Dauer bis zum nächsten Angriff), DE nur "mit einem Schild". Keine Totenkarte mit Bezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Flag wird beim Tod gesetzt (core:151), unabhängig von Ursache und Tageszeit. Laut Handler ist ein Einsatz in jeder späteren Nacht möglich, auch in derselben Nacht bei Sofort-Tod vor tier 5.6 (z. B. Hexengift tier 3.4).
  2. Erreichbarkeit: Die Nachtzeile erscheint NIE (night:58 vor night:91-92). Auch der SL-Assistent (night:660-672) und React (goToNightStep, legacyAdapter.ts:601-609) arbeiten nur auf der gerenderten Liste. Die Fähigkeit ist im Legacy praktisch nicht auslösbar (bestätigt F1).
  3. Ziele (falls erreichbar): jeder lebende Sitz, auch Wölfe (chunk:504 `x=>!x.flags.dead`). Selbstwahl entfällt (sie ist tot). Tote Ziele nicht.
  4. Verbrauch: einmal pro Tod (Flag auf false, chunk:502). Nach Wiederbelebung und erneutem Tod erneut.
  5. Wirkung: `protected=true`, `protectedCount+1`. Schutz wirkt nur im Moment eines Rudel-Picks (chunk:162) bzw. Rachsüchtiger-Wolf-Picks (chunk:348). Da tier 5.6 nach Werwolf 2.0 und Rachsüchtiger Wolf 2.2 liegt und onNightStart (night:145) den Schutz zu Beginn der nächsten Nacht löscht, hat das Schild bei regelkonformer Reihenfolge KEINE Wirkung. Es schützt nicht vor Hexe, Hades, Morgentoden, Lynch.
  6. Sichtbarkeit: Wenn `isWolf(Ziel)` (inkl. `cursedWolfAura`), zeigt `center(...,true)` die Meldung ohne Namen; sonst keine Meldung.
  7. Mehrere Kopien: ein globales Flag; ein Pick verbraucht es für alle toten Schutzgeister.
  8. Zufall: keiner.
  9. Rollenwechsel: Flag hängt am Rollennamen zum Todeszeitpunkt; Rollenwechsel nach dem Tod (Seelentauscher tauscht auch Tote, chunk:754) nicht gesondert behandelt.
  10. Sieg: keine eigene Bedingung.
- React-Version: nein, nur Bild (app/src/roleCard.ts:77).
- Bisherige Doku (04-Status + Kernaussage, 07-Frage, DECISION-LOG, Berichte) und Prüfergebnis dazu: doc04:88 "fehlend (Bug F1)", "Nach eigenem Tod einmal einen Spieler schützen": Zeilen `chunk:494-505`, `core:151` bestätigt. doc01:262 F1 `night:58` vs `night:91-92` bestätigt. doc04:112 B-2 "widersprüchlich (F1)" bestätigt. doc07:45 Teil 2 "Schutzgeist nie aktiv" bestätigt. Ergänzung: auch nach Behebung von F1 ist das Schild wegen Reihenfolge (5.6 nach 2.0) und Reset (night:145) wirkungslos; das fehlt in 04/07. NIGHT-REPORT-abilities.md:35 (🟡) überholt. DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Dauer/Wirkung des Schilds | "erhält ein Schutzschild" | "receives a shield" | Schutz nur beim Wolfs-Pick, gelöscht bei Nachtbeginn; Schutzgeist agiert nach dem Rudel | Adapter | 04: "einmal einen Spieler schützen"; Alttext: "from the next attack" | Schild hält bis zum nächsten Wolfsangriff (auch spätere Nächte) | Schild gilt nur für die aktuelle Nacht, Schritt muss dann vor dem Rudel liegen | A stärker, B ohne Umordnung wirkungslos | A: dauerhafter Marker; B: Schrittposition vor Rudel | A (deckt Alttext, macht Rolle spielbar) | Ja |
| Schutzart | "Schutzschild" | "shield" | nur Rudelangriff (Werwolf, Rachsüchtiger) | Adapter | Godot-Protections nur gegen Rudel-NIGHT_KILL | nur Wolfsangriff | jeder Tod | A schwächer | A nutzt vorhandene Protections | A | Ja |
| Zeitpunkt | "in der Nacht nach ihrem Ableben" | "On the night after their death" | ab Setzen des Flags jederzeit, auch dieselbe Nacht | Adapter | – | frühestens nächste Nacht | sobald tot, auch dieselbe Nacht | gering | Schrittfreigabe mit Nachtindex | A (Textwortlaut) | Ja |
| Wolf-Meldung | "erfährt das Dorf davon" | "the village is told" | öffentlich ohne Namen; `isWolf` inkl. verfluchter Sitze | Adapter | – | nur Tatsache, ohne Namen, echte Fraktion | mit Namen / nach Erscheinung (`appears_as`) | Name wäre starke Info | InfoRecord public, Quelle Wahrheit oder Erscheinung | A ohne Namen, Wahrheit | Ja |

- Bugs:
  - B-SG-1, echter Bug: Codepfad night:6/night:58 vor night:91-92. Tatsächlich: toter Schutzgeist erhält keine Nachtzeile, Fähigkeit nie nutzbar. Erwartet: Nachtschritt nach dem Tod. Risiko: hoch (Rolle tot im Akt II). Regressionstest: Schutzgeist stirbt in Nacht 1, Nacht 2 enthält Schritt Schutzgeist.
  - B-SG-2, unklare Regel: chunk:494-505 + chunk:162 + night:145. Tatsächlich: Schild wirkt bei korrekter Reihenfolge nie. Erwartet: Schild schützt (Text). Risiko: mittel. Test: Schutzgeist schützt X in Nacht 2, Rudel wählt X (in Nacht 2 bzw. 3 je nach Entscheidung), X überlebt.
  - B-SG-3, technische Altlast: gh:512-529 setzt `SchutzgeistAwaitingPick` nicht zurück. Test: neue Runde, Flag ist false.
- Legacy-Status: legacy-broken. Code für die Fähigkeit existiert, aber F1 verhindert die Auslösung vollständig, und die Wirkung wäre wegen Reihenfolge/Reset null.
- Automationsvorschlag: automatic. Klarer Auslöser (eigener Tod), ein Ziel, deterministische Wirkung nach PO-Entscheidung.
- Mechanikfamilie primär + sekundär: Schutz; sekundär Todesreaktion (Aktivierung durch Tod) und Informationsrolle (öffentliche Wolfsmeldung)
- Benötigte vorhandene Godot-Systeme: StepQueue (Schritt für toten Akteur), PendingPrompt, Protections (neue Quelle), Reaktionswarteschlange oder Todes-Hook zum Freischalten, InfoRecord + Ereignis-Sichtbarkeit (public), appears_as (falls Meldung nach Erscheinung), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: dauerhafte Statusmarker (Schild mit Lebensdauer "bis zum nächsten Wolfsangriff", falls Interpretation A); Protections muss mehrere Quellen und Lebensdauer kennen.
- Abhängigkeiten von anderen Rollen: Werwolf/Rudel (Angriff), Rachsüchtiger Wolf (Zusatzangriff), Seuchenwolf (Durchbohren ignoriert Schutz beim Pick, chunk:162) und Rudelvater (Zusatzopfer am Morgen ohne Schutzprüfung, night:269-280), Dämonischer Wolf (verfluchter Sitz löst Wolfsmeldung aus), Dr. Victor Frankenstein (Wiederbelebung), Seelentauscher (Rollentausch mit Toten), Schutzengel (gleicher Schutzmechanismus).
- Komplexität (S/M/L/XL) und Fehlerrisiko: M / mittel. Einfacher Handler, aber Schrittfreigabe für Tote und Schilddauer sind neu.
- Offene Entscheidungen: (1) Hält das Schild bis zum nächsten Wolfsangriff oder nur für eine Nacht? (2) Nur gegen Wolfsangriff oder gegen jeden Tod? (3) Darf sie in derselben Nacht handeln, in der sie stirbt? (4) Wird der gewählte Wolf mit Namen oder nur die Tatsache verkündet, und zählt die wahre Fraktion oder die Erscheinung (verfluchter Dorfbewohner)? (5) Nach Wiederbelebung und erneutem Tod erneut nutzbar?
- Relevante Testgruppen:
  - Normalfall: Schutzgeist stirbt in Nacht 1, in Nacht 2 schützt er Dorfbewohner X, Rudel wählt X, X überlebt (nach Entscheidung A).
  - ungültiges Ziel: Auswahl eines toten Sitzes wird abgelehnt, kein Verbrauch.
  - tote Person: Schutzgeist selbst ist tot und Akteur; Schritt nur für tote Schutzgeister mit offenem Flag.
  - Selbstwahl: nicht relevant, weil der Akteur tot ist und nur Lebende gewählt werden.
  - mehrere Kopien: zwei tote Schutzgeister erhalten je einen eigenen Schritt (Legacy: ein gemeinsames Flag).
  - Wiederbelebung: Schutzgeist wird vor seinem Schritt wiederbelebt, Schritt entfällt; stirbt erneut, Schritt erneut.
  - Rollenwechsel: Seelentauscher tauscht Rolle des toten Schutzgeists weg, Schritt entfällt.
  - Save/Load: Speichern zwischen Tod und Schritt, Flag bleibt erhalten.
  - Replay: gleiche Befehle, gleicher Hash.
  - SL-Korrektur: Schild per GmCorrection entfernen/setzen.
  - Sichtbarkeit: Wolf gewählt erzeugt öffentliches Ereignis ohne Namen; Dorfbewohner gewählt erzeugt nur GM-Ereignis.
  - Schutz: Seuchenwolf-Durchbohren ignoriert Schild.
  - Todesreaktionen: Auslöser ist die eigene Todesreaktion (jede Ursache inkl. Hinrichtung).
  - Siegprüfung: nicht relevant, weil keine Siegbedingung; nur indirekt durch verhinderten Tod.
  - beschädigter Spielstand: Flag true ohne toten Schutzgeist wird beim Laden abgelehnt oder ignoriert.
- Belegsicherheit: hoch. Nicht verifiziert: Verhalten, falls ein SL den Schritt über einen anderen Weg (Konsole) auslöst.

---

### dorfchronistin
- DE-Name / EN-Name: Dorfchronistin / Village Chronicler (roles:197)
- Aliase/Altnamen: kein Alias in state:16-40. Im Code auch "Chronist" (ab:107, APPLE_RESET_FLAGS, falscher Schlüssel) und Flag `ChroniclerShown`; i18n `chroniclerSolos` (i18n:241/570). Bilder: Sonderfall `Dorfchronistin_DE.webp` (roles:413, gh:809, app/src/roleCard.ts:14), EN `Village_Chronicler_EN` (gh:837, roleCard.ts:78).
- Legacy-ID (String in ALL_ROLES): "Dorfchronistin" (roles:1, Position 60)
- Fraktion: dorf (roles:405-409). Zählt selbst Solo-Rollen über `getFaction` (night:9-11 delegiert auf getRoleFaction) bzw. `SOLO_WIN_ROLES`.
- Akte (akte.js): Akt III (akte:55)
- Nachtpriorität: tier 0.3, once:true (roles:6). Bedingung: lebende Chronistin (night:58, night:93). Das once-Kriterium `isOnceUsed("Dorfchronistin")` (night:60) wird nie wahr, weil der Handler `markOnceUsed` nicht aufruft.
- Quelltextstellen:
  - roles:6 ORDER_BASE – tier 0.3, once
  - roles:123 / roles:273 – Rollentexte
  - chunk:506-516 Handler "Dorfchronistin" – Einmal-Prüfung `ChroniclerShown`, Zählung, Meldung
  - night:4-5 isOnceUsed/markOnceUsed – prüft `Used["role_Dorfchronistin"]`, nie gesetzt
  - night:60 rebuildOrder – once-Filter greift nie
  - ab:103-112 APPLE_RESET_FLAGS – Schlüssel "Chronist" statt "Dorfchronistin"
  - gh:512-529 clearRolesNewRound – `ChroniclerShown` wird nicht zurückgesetzt
- Text DE (wörtlich): "Erfährt zu Beginn des Spiels, wie viele Solo-Rollen im Spiel sind."
- Text EN (wörtlich): "Learns at the start of the game how many solo roles are in play."
- DE/EN-Vergleich: JA, semantisch gleich (Zeitpunkt, Inhalt, Gegenstand identisch).
- Weitere Texte: ra:13 identisch. i18n `chroniclerSolos` "Solo-Rollen im Spiel: {n}" / "Solo roles in play: {n}", über `tf` korrekt ersetzt. Alttext tools/create_role_doc.py:251-253 gleich. Kein Totenkartenbezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt ab Nacht 1; wird er nicht genutzt, bleibt er in allen späteren Nächten verfügbar (kein Nacht-1-Zwang).
  2. Ziele: keine.
  3. Zählung: alle Sitze mit Rolle (auch TOTE) mit Fraktion solo, pro Sitz (Duplikate zählen mehrfach), aktuelle Rolle zum Klickzeitpunkt (chunk:508-512). Doppelspion zählt als Solo (SOLO_ROLES_SET roles:399-403).
  4. Verbrauch: `state.once.ChroniclerShown=true` global; zweiter Klick "Schon genutzt.".
  5. Nachtzeile: bleibt jede Nacht sichtbar, weil once-Filter nie greift (bestätigt Bug aus 04/07).
  6. Sichtbarkeit: `center(...,true)` SL-Modal, gedacht als geheime Info an die Chronistin.
  7. Mehrere Kopien: globales Flag, nur eine Chronistin erhält die Info.
  8. Zufall: keiner.
  9. Rollenwechsel: erbt jemand die Rolle, bleibt `ChroniclerShown` gesetzt (core:339-359 setzt es nicht zurück).
  10. Apfel-Buff (Rotkäppchen): ab:107 nutzt "Chronist", Rücksetzung greift nie; da der Handler keinen Pick nutzt, gibt es ohnehin keine Wiederholung (ab:113-116).
  11. Sieg: keiner.
- React-Version: nein, nur Bild (roleCard.ts:14,78).
- Bisherige Doku und Prüfergebnis: doc04:89 "verifiziert (Bug Einmal-Flag)", "Einmal Info; danach kein Nachtschritt mehr": bestätigt, Zeilen chunk:506-516 stimmen. doc04:122 B-12 Schlüsselfehler "Chronist" ab:107 bestätigt. doc07:45 "Dorfchronistin-Zeile bleibt" bestätigt. NIGHT-REPORT-abilities.md:55 (❌ Info-Anzeige in React) vermutlich überholt, da domMirror `#overlay` spiegelt (nicht im Browser verifiziert). DECISION-LOG: kein Eintrag.
- Widersprüche: keine echten Text/Code-Widersprüche. Kleine Unschärfe (kein Widerspruch): Tote werden mitgezählt, was bei Nutzung in Nacht 1 irrelevant ist.
- Bugs:
  - B-DC-1, echter Bug (kosmetisch): chunk:506-516 ruft `markOnceUsed` nicht auf, `once:true` in roles:6 wirkungslos. Tatsächlich: Zeile jede Nacht, Klick meldet "Schon genutzt.". Erwartet: Schritt nur einmal. Risiko: niedrig (SL-Verwirrung, SL-Assistent hält an). Test: Nacht 2 enthält keinen Chronistin-Schritt nach Nutzung in Nacht 1.
  - B-DC-2, technische Altlast: ab:107 Schlüssel "Chronist". Risiko: niedrig. Test: nicht nötig bei Neuimplementierung.
  - B-DC-3, technische Altlast: gh:512-529 setzt `ChroniclerShown` nicht zurück, neue Runde über "Rollen leeren" gibt keine Info mehr. Risiko: mittel im Legacy. Test: neue Runde, Info wieder verfügbar.
- Legacy-Status: legacy-verified. Die Kernfunktion (einmalige Solo-Zählung) funktioniert; die Fehler betreffen Zeilenanzeige und Rundenreset.
- Automationsvorschlag: automatic. Reine Zählung aus dem Zustand.
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Einmalfähigkeit
- Benötigte vorhandene Godot-Systeme: StepQueue (Nacht-1-Einmalschritt), InfoRecord (Wahrheit/gezeigt), Ereignis-Sichtbarkeit (actor), Fraktionsabfrage aus Rollendaten, StateCodec, Replay.
- Benötigte NEUE Systeme: keine.
- Abhängigkeiten von anderen Rollen: alle Solo-Rollen (SOLO_ROLES_SET), Doppelspion (zählt als Solo), Rollen mit Rollenwechsel in Nacht 1 vor tier 0.3 (Loki 0.1: kein Rollenwechsel) nicht relevant.
- Komplexität und Fehlerrisiko: S / niedrig. Eine Zählung, ein Einmalschritt.
- Offene Entscheidungen: (1) Nur in Nacht 1 oder später nachholbar? (2) Zählen Solo-Rollen pro Sitz (Duplikate) oder verschiedene Rollen? (3) Zählt der Doppelspion als Solo-Rolle (Code: ja)?
- Relevante Testgruppen:
  - Normalfall: 2 Solo-Rollen im Spiel, Chronistin erhält Info 2.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: tote Chronistin erhält keinen Schritt; tote Solo-Sitze werden gezählt (Legacy) bzw. nach Entscheidung.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Chronistinnen, beide oder nur eine erhalten Info (Entscheidung); Legacy nur eine.
  - Wiederbelebung: nicht relevant, weil nur Nacht-1-Schritt (außer Entscheidung "nachholbar").
  - Rollenwechsel: Lehrling erbt Chronistin, erhält keine zweite Info.
  - Save/Load: Speichern nach Info, nach Laden kein erneuter Schritt.
  - Replay: gleiche Zahl.
  - SL-Korrektur: Rollenkorrektur vor dem Schritt ändert die Zahl.
  - Sichtbarkeit: Ereignis nur actor/gm.
  - Schutz: nicht relevant, weil kein Kill.
  - Todesreaktionen: nicht relevant, weil kein Tod.
  - Siegprüfung: nicht relevant, weil keine Siegwirkung.
  - beschädigter Spielstand: Einmal-Flag gesetzt ohne Chronistin wird toleriert.
- Belegsicherheit: hoch.

---

### waechter-am-tor
- DE-Name / EN-Name: Wächter am Tor / Gatewarden (roles:198)
- Aliase/Altnamen: kein Alias. Im Code `gatewarden*` (core:31 `gatewardenBlocksNewWolves`, core:41 `applyRoleOrVillagerIfGatewardenWolf`), i18n `gatewardenRedirectVillager` (i18n:166/490) und unbenutzt `gatewardenBlock` (i18n:223/552). Tag `blocks-new-wolves` (roles:292, sonst nirgends ausgewertet). Bilder: assets/cards/de/Wächter_am_Tor.webp, EN Gatewarden.webp (gh:837, roleCard.ts:79).
- Legacy-ID (String in ALL_ROLES): "Wächter am Tor" (roles:1, Position 61)
- Fraktion: dorf (roles:405-409).
- Akte (akte.js): Akt IV (akte:78). Beobachtung: In Akt IV gibt es keine der abgefangenen Wolfsquellen (Lehrling, Wolfskind, König Lykaon, Seelentauscher, Frankenstein, Kutscher, Dämonischer Wolf fehlen, akte:74-85). Die Rolle ist dort wirkungslos; nur im Custom-Setup relevant.
- Nachtpriorität: kein ORDER_BASE-Eintrag; zusätzlich in der Passivliste night:96.
- Quelltextstellen:
  - core:31-33 gatewardenBlocksNewWolves – `some` lebender Wächter
  - core:41-56 applyRoleOrVillagerIfGatewardenWolf – Probe über `isWolf({role,flags:{werewolf},meta:seat.meta})`; bei Wolf und Wächter: Rolle Dorfbewohner, `werewolf=false`, `cursedWolfAura=false`, Meldung
  - chunk:84-86 Frankenstein – Abfang über core:41
  - chunk:385-386 König Lykaon (Trugbilderwolf) – Abfang über core:41
  - chunk:760-787 Seelentauscher – eigene Inline-Logik, Meldung chunk:786
  - chunk:847-853 Kutscher – Wolfsplatz wird Dorfbewohner, Meldung chunk:852
  - core:388 postDeathHooks Wolfskind – Abfang
  - core:389 postDeathHooks Lehrling – Abfang
  - night:289, night:501 Dämonischer Wolf – Fluch `cursedWolfAura=true`, KEIN Abfang
  - roles:124 / roles:274 – Texte
- Text DE (wörtlich): "Solange er lebt, werden neu entstehende Werwölfe blockiert (U+2014) der betroffene Spieler wird stattdessen zum Dorfbewohner."
- Text EN (wörtlich): "While alive, new werewolves are blocked (U+2014) the affected player becomes a Villager instead."
- DE/EN-Vergleich: JA, semantisch gleich ("neu entstehende" = "new").
- Weitere Texte: ra:37 identisch. Alttext tools/create_role_doc.py:255-257 gleich. i18n-Meldung EN nutzt "Gatewarden" konsistent. Kein Totenkartenbezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: passiv, geprüft im Moment jeder Verwandlung.
  2. Bedingung: mindestens ein lebender Wächter (mehrere Kopien egal).
  3. Wirkung: der betroffene Sitz erhält Rolle "Dorfbewohner", `werewolf=false`, `cursedWolfAura=false` (core:46-48). Bei Wolfskind zusätzlich `vorbild=false` (core:388). Lehrling ruft `resetOnceForInheritedRole` und `rebuildOrder` (core:389).
  4. Nicht abgefangen: Dämonischer-Wolf-Fluch (night:289, night:501), obwohl `isWolf` verfluchte Sitze als Wolf zählt (core:18); manuelle Rollenzuweisung durch den SL (gh:644); Grabräuber (nur SL-Hinweis, chunk:583-590).
  5. Randfall Probe: Die Probe nutzt `seat.meta`. Hat der Sitz noch `cursedWolfAura` (Frankenstein setzt meta nicht zurück, chunk:57-62), wird jede gewählte Rolle als Wolf erkannt und in Dorfbewohner umgewandelt; ohne Wächter setzt core:54 dann `werewolf=true` für eine Dorfrolle.
  6. Kutscher: bei Abfang bleibt die Erfolgsmeldung "3 wieder im Spiel (1 davon Wolf)." (chunk:860) falsch.
  7. König Lykaon: bei Abfang wird trotzdem eine Tarnzeile der alten Rolle angelegt (chunk:388) und die Fähigkeit verbraucht (chunk:389).
  8. Sichtbarkeit: SL-Modal `center(...,false)`.
  9. Stirbt der Wächter, werden spätere Verwandlungen wieder zu Wölfen; frühere Umwandlungen bleiben.
  10. Zufall: keiner in der Rolle (Kutscher selbst nutzt Math.random, chunk:840-857).
  11. Sieg: keine eigene Bedingung.
- React-Version: nein, nur Bild (roleCard.ts:79).
- Bisherige Doku und Prüfergebnis: doc04:90 "verifiziert", Liste der Wege (Lehrling, Wolfskind, Lykaon, Seelentauscher, Frankenstein, Kutscher): bestätigt, Zeilen core:31-56 stimmen. doc01:221 Fundstellen `core:41-56`, `core:387-389`, `chunk:85,385,763,847` bestätigt (Wolfskind/Lehrling tatsächlich core:388-389). doc04:36 Wolfskind-Hinweis bestätigt. Ergänzung: Dämonischer-Wolf-Fluch nicht abgefangen (hängt an doc07 Q1 "Dämonischer Wolf: Text"); `cursedWolfAura`-Probe-Randfall; Akt IV ohne Wolfsquellen. rules-register.md:256 "Wächter am Tor nicht im Slice". DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Gilt der Dämonische-Wolf-Fluch als "neu entstehender Werwolf"? | "neu entstehende Werwölfe" | "new werewolves" | nicht abgefangen, aber `isWolf` zählt Verfluchte als Wolf | Adapter | 04:61 Q1: Verfluchter "erscheint" nur | Fluch ist nur Erscheinung, Wächter irrelevant | Fluch erzeugt echten Wolf, Wächter muss abfangen | bei B stärker für Dorf | A: appears_as; B: zusätzlicher Abfangpunkt | A (folgt 07-Vorschlag "nur Erscheinung") | Ja |

- Bugs:
  - B-WT-1, echter Bug (Randfall): core:41-55 Probe mit `seat.meta` inkl. `cursedWolfAura`. Tatsächlich: verfluchter, wiederbelebter Sitz wird bei Frankenstein unabhängig von der gewählten Rolle zum Dorfbewohner (mit Wächter) bzw. erhält `werewolf=true` (ohne Wächter). Erwartet: nur Wolfsrollen werden abgefangen. Risiko: niedrig bis mittel. Test: verfluchter Toter wird als Seherin wiederbelebt, bleibt Seherin, kein Wolf.
  - B-WT-2, technische Altlast: chunk:860 Kutscher-Meldung nennt Wolf trotz Abfang. Risiko: niedrig (SL-Fehlinformation). Test: Meldung ohne Wolf bei aktivem Wächter.
  - B-WT-3, technische Altlast: Abfanglogik ist an sechs Stellen dupliziert (core:41, core:388, core:389, chunk:763-787, chunk:847-853). Risiko: mittel bei Erweiterung. Test: pro Verwandlungsweg ein Szenario.
- Legacy-Status: legacy-verified. Alle genannten Verwandlungswege sind abgefangen; offene Punkte sind Randfälle und eine Regelfrage.
- Automationsvorschlag: automatic. Reine Regel im zentralen Rollenwechsel.
- Mechanikfamilie primär + sekundär: globale Regeländerung; sekundär Rollenwechsel (Umleitung in Dorfbewohner)
- Benötigte vorhandene Godot-Systeme: RoleTransition (zentrale Abfangregel vor Übernahme), WolfChildBond, ApprenticeBond, appears_as (Abgrenzung Fluch), Ereignis-Sichtbarkeit (gm), GmCorrections, StateCodec, Replay.
- Benötigte NEUE Systeme: keine; RoleTransition braucht nur einen Abfang-Haken.
- Abhängigkeiten von anderen Rollen: Wolfskind, Lehrling, König Lykaon/Trugbilderwolf, Seelentauscher, Dr. Victor Frankenstein, Kutscher, Dämonischer Wolf (Regelfrage), Grabräuber (manuell).
- Komplexität und Fehlerrisiko: M / hoch. Einfache Regel, aber berührt jeden Verwandlungsweg; Fehler erzeugen falsche Wolfszahl und damit falsche Siege.
- Offene Entscheidungen: (1) Gilt der Dämonische-Wolf-Fluch als neuer Werwolf? (2) Erhält der umgewandelte Spieler öffentlich/privat eine Mitteilung? (3) Soll Lykaon bei Abfang seine Fähigkeit verbrauchen? (4) Soll die Rolle in Akt IV bleiben, obwohl dort keine Wolfsquelle existiert?
- Relevante Testgruppen:
  - Normalfall: Wächter lebt, Wolfskind-Vorbild stirbt, Wolfskind wird Dorfbewohner.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: toter Wächter blockiert nicht; Lehrling-Mentor-Wolf stirbt, Lehrling wird Wolf.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Wächter, einer stirbt, Blockade bleibt.
  - Wiederbelebung: Frankenstein belebt Toten als Werwolf, wird Dorfbewohner; Kutscher-Wolfsplatz wird Dorfbewohner.
  - Rollenwechsel: Seelentauscher tauscht Wolf und Dorfbewohner, der lebende Nicht-Wolf wird Dorfbewohner, der Wolf erhält die Dorfrolle.
  - Save/Load: Speichern vor Verwandlung, Laden, Verwandlung wird abgefangen.
  - Replay: identisch.
  - SL-Korrektur: manuelle Rollenkorrektur zu Werwolf per GmCorrection wird NICHT abgefangen (Entscheidung dokumentieren).
  - Sichtbarkeit: Umwandlungsereignis nur gm (bzw. actor nach Entscheidung).
  - Schutz: nicht relevant, weil kein Kill.
  - Todesreaktionen: Wächter stirbt in derselben Kette wie das Vorbild des Wolfskinds; Reihenfolge der Reaktionen entscheidet (Test mit fester Reihenfolge).
  - Siegprüfung: Abfang verhindert Wolfsparität.
  - beschädigter Spielstand: Sitz mit Rolle Dorfbewohner und `werewolf=true` wird erkannt.
- Belegsicherheit: hoch. Nicht verifiziert: ob weitere, nicht über Rollennamen auffindbare Wege `flags.werewolf=true` setzen (grep nach `werewolf=true` ergab nur die genannten Stellen).

---

### zeitwaechter
- DE-Name / EN-Name: Zeitwächter / Time Warden (roles:199)
- Aliase/Altnamen: kein Alias. Laufzeittexte EN nennen ihn "Timekeeper" (i18n:564-565, 608), Flag `TimekeeperFreezeMorning`, i18n `timekeeper*`. Bilder: assets/cards/de/Zeitwächter.webp, EN Time_Warden.webp (gh:838, roleCard.ts:80).
- Legacy-ID (String in ALL_ROLES): "Zeitwächter" (roles:1, Position 62)
- Fraktion: dorf (roles:405-409).
- Akte (akte.js): Akt III (akte:56)
- Nachtpriorität: tier 9.5, once:true (roles:59). Bedingung: lebender Zeitwächter (night:58, night:93), nicht verbraucht (night:60, über `markOnceUsed` chunk:520 korrekt).
- Quelltextstellen:
  - roles:59 ORDER_BASE
  - chunk:517-523 Handler – `TimekeeperFreezeMorning=true`, `markOnceUsed`, Meldung
  - ab:95 onOrderClick – blockiert jede spätere Nicht-Wolf-Rolle in dieser Nacht
  - night:323-331 resolveDayKills – bei Flag: Flag löschen, alle `targeted` löschen, postDeathHooks, `dark=false`, KEIN nightCount++, rebuildOrder, Meldung
  - night:176-275 onDayStart – läuft VOR resolveDayKills vollständig: MorningCount++ (night:191), Schwarze-Witwe-Tode (night:192-199), Giftwolf-Tode (night:200-212), OldDebuff/VoodooCooldown-- (night:232-233), Resets (night:234-237), Voodoo-Umlenkung (night:252-256), Märtyrerin-Dialog (night:257-265), Rudelvater-Zusatzopfer-Pick (night:269-280)
  - night:130-174 onNightStart – Fenrir-Stufe, Cerberus-Köpfe, Schmiedezähler usw. wurden schon erhöht
- Text DE (wörtlich): "Kann einmalig eine Nacht einfrieren (U+2014) alle Nachtaktionen dieser Nacht werden abgebrochen. Die Nacht gilt als nicht stattgefunden."
- Text EN (wörtlich): "Once per game, he may freeze a night (U+2014) all night actions are canceled. That night is treated as though it never happened."
- DE/EN-Vergleich: JA, semantisch gleich ("einmalig" = "Once per game"; "dieser Nacht" im EN implizit).
- Weitere Texte: ra:42 identisch. i18n `timekeeperMorningFreeze` "Diese Nacht wird beim Tagesbeginn eingefroren (keine Auflösung, keine Nachtzählung)." beschreibt das Codeverhalten, nicht den Rollentext. Alttext tools/create_role_doc.py:259-261 gleich. Totenkarte "Zeitwarp" (cards.js:404-408, loki_03) beschreibt eine ähnliche Nacht-Überspringung ("kein Tod, kein Angriff, kein Schutz"), nur als SL-Text.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt tier 9.5, also nach fast allen Rollen (nur Hades 9.9 danach). Kein Tag-Check in onOrderClick (ab:71); ob die Liste tagsüber anklickbar ist, nicht verifiziert. Ein Aktivieren am Tag würde die NÄCHSTE Morgenauflösung einfrieren und bis dahin alle Dorf/Solo-Klicks blockieren.
  2. Ziele: keine.
  3. Verbrauch: einmal pro Spiel global (`Used["role_Zeitwächter"]`), auch für mehrere Kopien.
  4. Was abgebrochen wird: nur (a) spätere Nicht-Wolf-Klicks dieser Nacht (ab:95) und (b) alle `targeted`-Opfer am Morgen (Rudel, Rachsüchtiger Wolf, Schicksalswolf-Zusatz), Gift-Ausbreitung und Pest-Check (night:332-333 werden übersprungen).
  5. Was NICHT abgebrochen wird: alle Sofort-Tode der Nacht (Hexe, Hades, Amalia, Kriegerin, Blutpriester, Prophet, Verdammniswächter), alle bereits gesetzten Zustände (Schutz, Rollenwechsel, Wiederbelebung, Schmiedewaffe vergeben, Einmal-Verbräuche), Schwarze-Witwe- und Giftwolf-Morgentode, Voodoo-Puppentod bei angegriffenem Priester, Märtyrerin-Opfer (Dialog erscheint vor der Einfrierprüfung und tötet sie bei Ja), Rudelvater-Zusatzopfer-Auswahl, alle Zähler (MorningCount, Fenrir, Cerberus, Schmied, Cooldowns).
  6. Wölfe: Wolfsrollen werden nicht blockiert (ab:95 `!isWolfRole`), ihre Ziele verfallen aber am Morgen.
  7. Nachtzähler: `nightCount` bleibt gleich (night:326 ohne Inkrement), die nächste Nacht trägt dieselbe Nummer. `_nightDeadSnapshot` bleibt liegen, `showNightDeathSummary` entfällt.
  8. Sichtbarkeit: SL-Modal bei Aktivierung und am Morgen (`center(...,true)`).
  9. Zufall: keiner.
  10. Schutz/Rettung: Der-Weise-Erstangriff und Schmiedewaffe werden nicht verbraucht (processOne läuft nicht).
  11. Rollenwechsel: Erbe (Lehrling/Seelentauscher) kann nicht erneut, weil `Used`-Schlüssel global bleibt.
  12. Sieg: postDeathHooks läuft (night:325), Siegprüfung auf dem Stand nach Sofort-Toden.
- React-Version: nein, nur Bild (roleCard.ts:80).
- Bisherige Doku und Prüfergebnis: doc04:91 "widersprüchlich", "Code: nur Wolfstode und Nachtzähler; Sofort-Tode bleiben": bestätigt und ergänzt (auch Witwe/Giftwolf/Märtyrerin/Voodoo laufen weiter, spätere Dorf/Solo-Schritte blockiert, Zähler außer nightCount laufen). Zeilen chunk:517-523 und night:323-331 stimmen. doc01:225 "greift nur teilweise" bestätigt. doc07:39 Q1 Vorschlag "Alle Tode dieser Nacht rückgängig" betrifft nur Tode, nicht Zustände (Schutz, Rollenwechsel, Verbräuche). doc04:116 B-6 "unklar" bestätigt. ROLE-FLOW-REPORT.md:54,97-99 (Rohschlüssel-Bug behoben): i18n-Schlüssel existieren jetzt (i18n:236/565), bestätigt. DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Umfang des Abbruchs | "alle Nachtaktionen dieser Nacht werden abgebrochen" | "all night actions are canceled" | nur Morgenopfer und spätere Dorf/Solo-Schritte; Sofort-Tode, Witwe, Giftwolf, Märtyrerin, Zustände bleiben | Adapter | 04/07: nur Wolfstode | Gesamte Nacht wird zurückgerollt (Tode und Zustände) | Nur Tode dieser Nacht entfallen, Zustände bleiben | A sehr stark, B stark | A: Nacht-Transaktion mit Schnappschuss ab Nachtbeginn; B: alle Tode der Nacht aufschieben bis Morgen | A mit Schnappschuss bei Nachtbeginn (RoleTransition-Schnappschuss-Idee) oder B nach 07 | Ja |
| Zeitpunkt der Entscheidung | "Kann ... eine Nacht einfrieren" | "may freeze a night" | Schritt ganz am Ende (9.5), nach allen Aktionen | Adapter | – | Entscheidung am Nachtanfang, dann läuft keine Aktion | Entscheidung am Nachtende, alles wird zurückgenommen | A spart Zeit, B gibt Zeitwächter Zusatzwissen (sieht keine Nachtergebnisse, aber SL weiß sie) | A: Schritt vor tier 0.1; B: Rücknahme nötig | A (einfacher, fairer) | Ja |
| Zähler | "Die Nacht gilt als nicht stattgefunden" | "treated as though it never happened" | nur nightCount bleibt; MorningCount, Fenrir, Cerberus, Schmied, Cooldowns laufen | Adapter | – | alle nachtabhängigen Zähler zurück | nur Nachtnummer | Todesprediger, Schmied, Fenrir betroffen | Zähler-Liste in Nacht-Transaktion | A | Ja |
| Wolfsrollen | "alle Nachtaktionen" | "all night actions" | Wölfe werden nicht blockiert | Adapter | 04 B-6 | auch Wölfe | nur Nicht-Wölfe | gering | Blockadegrund pro Schritt | A | Ja |

- Bugs:
  - B-ZW-1, unklare Regel (siehe Widerspruch): night:176-280 führt Morgeneffekte vor der Einfrierprüfung aus. Risiko: hoch (Tode trotz "eingefrorener" Nacht). Test: Schwarze Witwe markiert in eingefrorener Nacht, am Morgen stirbt niemand.
  - B-ZW-2, echter Bug: Märtyrerin-Dialog (night:257-265) erscheint vor der Einfrierprüfung; bei Ja stirbt die Märtyrerin für ein Opfer, das ohnehin nicht stirbt. Erwartet: kein Dialog bei eingefrorener Nacht. Risiko: mittel. Test: Zeitwächter aktiv, Märtyrerin lebt, Rudelopfer gesetzt, kein Opferdialog.
  - B-ZW-3, technische Altlast: gh:512-529 setzt `TimekeeperFreezeMorning` nicht zurück. Test: neue Runde, Flag false.
  - B-ZW-4, technische Altlast: EN-Laufzeitname "Timekeeper" statt Rollenname "Time Warden" (i18n:564-565, 608). Risiko: niedrig.
- Legacy-Status: legacy-contradictory. Code ist in sich lauffähig, setzt aber nur einen Teil des Textes um.
- Automationsvorschlag: assisted. Nach PO-Entscheidung automatisierbar, aber ein Nacht-Rollback berührt jede Rolle; SL-Bestätigung sinnvoll.
- Mechanikfamilie primär + sekundär: globale Regeländerung; sekundär Einmalfähigkeit
- Benötigte vorhandene Godot-Systeme: StepQueue (Schrittstatus blocked), PendingPrompt, KillPipeline (Tode der Nacht zurückhalten oder verwerfen), Reaktionswarteschlange (Reaktionen nicht auslösen), StateCodec, Replay, InfoRecord/Sichtbarkeit (public Meldung "Nacht eingefroren"), GmCorrections.
- Benötigte NEUE Systeme: globale Modifikatoren (Nacht eingefroren), Rollenblockierung (alle folgenden Schritte), Nacht-Transaktionsbegriff mit Schnappschuss und Zähler-Rücknahme (zeitlich verzögerte Effekte müssen ebenfalls verworfen werden: Witwe, Giftwolf).
- Abhängigkeiten von anderen Rollen: praktisch alle Nachtrollen; besonders Schwarze Witwe, Giftwolf, Märtyrerin, Voodoo-Priester, Rudelvater, Seuchenwolf, Waldhexe, Hades, Amalia, Kriegerin, Dorfschmied, Der Weise, Fenrir, Cerberus, Todesprediger, Schattenhund/Albtraumwolf/Der Weise (blockieren den Zeitwächter selbst).
- Komplexität und Fehlerrisiko: XL / kritisch. Berührt Nachtablauf, alle Sofort-Tode, Zähler und Reaktionen.
- Offene Entscheidungen: (1) Entscheidung am Nachtanfang oder -ende? (2) Werden nur Tode oder alle Zustände zurückgenommen? (3) Zählen Zähler (Nachtnummer, Schmied, Fenrir, Todesprediger) die Nacht? (4) Gilt der Abbruch auch für Wölfe und Solo-Rollen? (5) Öffentliche Ankündigung am Morgen?
- Relevante Testgruppen:
  - Normalfall: Zeitwächter friert Nacht 2 ein, Rudelopfer überlebt, Nachtnummer bleibt 2.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: toter Zeitwächter erhält keinen Schritt.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Zeitwächter, jeder einmal oder global einmal (Entscheidung).
  - Wiederbelebung: Frankenstein-Wiederbelebung in eingefrorener Nacht wird zurückgenommen oder bleibt (Entscheidung).
  - Rollenwechsel: Seelentauscher-Tausch in eingefrorener Nacht; Lehrling erbt unbenutzten Zeitwächter.
  - Save/Load: Speichern nach Aktivierung vor Morgen, Laden, Morgen friert ein.
  - Replay: identischer Hash inkl. Rücknahme.
  - SL-Korrektur: Einfrieren nachträglich per GmCorrection aufheben.
  - Sichtbarkeit: Morgenmeldung public, keine Opferinfos leaken.
  - Schutz: Schutzengel-Schutz verbraucht oder nicht (Entscheidung).
  - Todesreaktionen: Sensenträger-Reaktion eines Hexengifttoten in eingefrorener Nacht entfällt (nach Entscheidung).
  - Siegprüfung: Sofort-Tod in eingefrorener Nacht löst keinen Sieg aus (nach Entscheidung A).
  - beschädigter Spielstand: Einfrierflag am Tag ohne Zeitwächter wird verworfen.
- Belegsicherheit: hoch für die Codeanalyse. Nicht verifiziert: Sichtbarkeit/Anklickbarkeit der Nachtliste am Tag (CSS/Layout nicht im Browser geprüft).

---

### amalia
- DE-Name / EN-Name: Amalia / Amalia (roles:200)
- Aliase/Altnamen: kein Alias. i18n `amalia*` (i18n:285-290, 609-614). Todesursache `AMALIA_SACRIFICE` (chunk:546, Label ui:412). Bilder: assets/cards/de/Amalia.webp, EN Amalia.webp (gh:838, roleCard.ts:81).
- Legacy-ID (String in ALL_ROLES): "Amalia" (roles:1, Position 63)
- Fraktion: dorf (roles:405-409).
- Akte (akte.js): Akt IV (akte:76)
- Nachtpriorität: tier 5.8, kein once (roles:41). Bedingung: lebende Amalia (night:58, night:93). Die Wolfszahl wird erst im Handler geprüft, die Zeile erscheint jede Nacht.
- Quelltextstellen:
  - roles:41 ORDER_BASE
  - roles:126 / roles:276 – Texte
  - chunk:524-553 Handler – Wolfszahl `isWolf` lebend `<=2` blockiert; Bestätigungsdialog; bei "Opfern": `applyKill(me,"AMALIA_SACRIFICE")`, postDeathHooks
  - i18n:287-288, 290, 611-612, 614 – `amaliaPromptQuestion`, `amaliaPublicQuestion`, `amaliaButtonSubmitQuestion` existieren, werden aber nirgends benutzt (rg über js, html, app/src ohne Treffer außer i18n)
- Text DE (wörtlich): "Trägt den Willen Hestias in sich. Solange mehr als zwei Werwölfe im Spiel sind, kann sie sich opfern, um öffentlich eine Ja-/Nein-Frage zu stellen."
- Text EN (wörtlich): "Carries the will of Hestia. As long as more than two werewolves are in play, may sacrifice herself to publicly ask a yes/no question."
- DE/EN-Vergleich: JA, semantisch gleich (Schwelle "mehr als zwei" = "more than two", Opfer, öffentliche Ja/Nein-Frage).
- Weitere Texte: ra:4 identisch. Alttext tools/create_role_doc.py:263-265 abweichend: "(bei 2+ Wölfen)" / "while 2+ wolves live", also Schwelle mindestens zwei statt mehr als zwei. Kein Totenkartenbezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt tier 5.8 (bei geschlossenen Augen); kein Tag-Check in onOrderClick.
  2. Bedingung: lebende Wölfe nach `isWolf` (inkl. verfluchter Sitze, ohne Doppelspion) mehr als 2 (chunk:525-526).
  3. Ziele: keine; Akteur ist `seats.find` erste lebende Amalia (chunk:527).
  4. Wirkung: nur Tod `AMALIA_SACRIFICE` sofort in der Nacht, danach postDeathHooks (Reaktionen, Siegprüfung). Die Frage selbst wird nicht erfasst, nicht angezeigt, nicht beantwortet; der Dialogtext nennt sie nur ("Amalia opfern und öffentliche Ja/Nein-Frage stellen?"). Wer die Frage beantwortet (SL, wahrheitsgemäß?), ist nirgends geregelt.
  5. Verbrauch: implizit durch Tod; Abbrechen ohne Verbrauch.
  6. Schutz: `applyKill` kann durch Nekromant-Globalschild (core:127-133) blockiert werden; dann lebt Amalia, Schild ist verbraucht, keine Meldung zur Frage.
  7. Mehrere Kopien: nur die erste lebende Amalia kann geopfert werden, unabhängig davon, wer handelt.
  8. Zufall: keiner.
  9. Rollenwechsel: keine Sonderbehandlung.
  10. Sieg: Opfer kann Wolfsparität auslösen (postDeathHooks).
- React-Version: nein, nur Bild (roleCard.ts:81).
- Bisherige Doku und Prüfergebnis: doc04:92 "verifiziert", "Solange > 2 Wölfe leben: darf sich opfern (AMALIA_SACRIFICE)": Zeilen chunk:524-553 bestätigt. Widerlegt als "verifiziert": der Kern "öffentlich eine Ja-/Nein-Frage stellen" ist nicht modelliert, die vorbereiteten i18n-Schlüssel sind verwaist, und ein öffentlicher Akt als Nachtschritt ist zeitlich widersprüchlich. doc04:120 B-10 und doc04:175 (Ursache sacrifice) bestätigt. NIGHT-REPORT-abilities.md:47,119 (❌ Ja/Nein) bestätigt. DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Zeitpunkt | "öffentlich eine Ja-/Nein-Frage" (kein Zeitpunkt) | "publicly ask" | Nachtschritt tier 5.8 | Adapter | 04: Nachtrolle | Tagesaktion (öffentlich, alle wach) | Nachtschritt, Frage wird am Morgen verkündet | A: Frage wirkt sofort in Diskussion | A: Tagesaktionswarteschlange; B: verzögertes Ereignis | A | Ja |
| Frage und Antwort | "um öffentlich eine Ja-/Nein-Frage zu stellen" | gleich | Frage wird nicht erfasst; Schlüssel `amaliaPromptQuestion`/`amaliaPublicQuestion` unbenutzt | Adapter | 04: nicht erwähnt | SL beantwortet wahrheitsgemäß, App protokolliert Frage und Antwort | Frage rein mündlich, App nur Opfer | A: nachvollziehbar | A: PendingPrompt mit Freitext + Ja/Nein; InfoRecord | A | Ja |
| Schwelle | "mehr als zwei Werwölfe im Spiel" | "more than two werewolves are in play" | `>2` lebende `isWolf` inkl. Verfluchte | Adapter | Alttext tools/create_role_doc.py: "2+" | >2 lebende echte Wölfe | >=2 (Alttext) oder inkl. toter ("im Spiel") | Verfügbarkeit | Zählung über Fraktion, ohne Erscheinung | >2 lebende echte Wölfe | Ja |

- Bugs:
  - B-AM-1, unklare Regel/technische Altlast: chunk:524-553 ohne Fragenerfassung, i18n-Schlüssel verwaist. Risiko: mittel (SL muss improvisieren). Test: Opfer erzeugt öffentliches Ereignis mit Frage und Antwort.
  - B-AM-2, technische Altlast: chunk:527 `seats.find` statt handelndem Sitz. Risiko: niedrig (Duplikate selten). Test: zwei Amalias, die gewählte stirbt.
- Legacy-Status: legacy-contradictory. Das Opfer funktioniert, die öffentliche Frage ist nicht modelliert und als Nachtschritt zeitlich widersprüchlich.
- Automationsvorschlag: assisted. Die Frage ist sozial; App erfasst Opfer, Frage und SL-Antwort.
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Einmalfähigkeit (Selbstopfer)
- Benötigte vorhandene Godot-Systeme: PendingPrompt (Bestätigung, Frage, Antwort, abbrechbar), KillPipeline (Ursache Opfer), Reaktionswarteschlange, WinRules/WinCandidate, InfoRecord + Ereignis-Sichtbarkeit (public), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Tagesaktionswarteschlange (falls Tagesaktion); Freitext-Eingabe im Prompt.
- Abhängigkeiten von anderen Rollen: alle Wolfsrollen (Schwelle), Dämonischer Wolf (Verfluchte zählen im Code mit), Doppelspion (zählt nicht), Nekromant (Globalschild verhindert Opfer), Zeitwächter (Opfer bleibt trotz Einfrieren).
- Komplexität und Fehlerrisiko: M / mittel. Einfacher Tod, aber neue Tagesaktion und Freitext.
- Offene Entscheidungen: (1) Tag oder Nacht? (2) Beantwortet der SL wahrheitsgemäß, und wird die Antwort in der App festgehalten? (3) Schwelle ">2" oder "2+", lebend oder "im Spiel"? (4) Zählen verfluchte Sitze als Werwölfe?
- Relevante Testgruppen:
  - Normalfall: 3 Wölfe leben, Amalia opfert sich, stirbt, Frage und Antwort öffentlich protokolliert.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl; ungültige Bedingung: 2 Wölfe, Aktion abgelehnt.
  - tote Person: tote Amalia kann nicht opfern.
  - Selbstwahl: nicht relevant, weil die Aktion immer sie selbst betrifft.
  - mehrere Kopien: zwei Amalias, die handelnde stirbt.
  - Wiederbelebung: wiederbelebte Amalia darf erneut (Entscheidung).
  - Rollenwechsel: Lehrling erbt Amalia, darf opfern.
  - Save/Load: Speichern im offenen Prompt, Abbruch ohne Tod.
  - Replay: identisch.
  - SL-Korrektur: Opfer per GmCorrection rückgängig.
  - Sichtbarkeit: Frage und Antwort public, keine versteckten Rolleninfos.
  - Schutz: Schutzengel verhindert Opfer nicht; Nekromant-Schild nach Entscheidung.
  - Todesreaktionen: Amalias Tod löst Reaktionen aus (z. B. Rotkäppchen-Verbindung).
  - Siegprüfung: Opfer führt zu Wolfsparität, Sieg wird vorgeschlagen.
  - beschädigter Spielstand: gespeicherte Frage ohne Opfer wird abgelehnt.
- Belegsicherheit: hoch für Code; mittel für Zweck der verwaisten Schlüssel (Historie nicht verfügbar).

---

### kriegerin-des-lichts
- DE-Name / EN-Name: Kriegerin des Lichts / Warrior of Light (roles:201)
- Aliase/Altnamen: kein Alias. i18n `warrior*` (i18n:262-265, 586-589), Todesursache `WARRIOR_WRONG` (chunk:566, ui:412). Bilder: Kriegerin_des_Lichts.webp, EN Warrior_of_Light.webp (gh:839, roleCard.ts:82).
- Legacy-ID (String in ALL_ROLES): "Kriegerin des Lichts" (roles:1, Position 64)
- Fraktion: dorf (roles:405-409).
- Akte (akte.js): Akt IV (akte:77)
- Nachtpriorität: tier 6.0, once:true (roles:42). Bedingung: lebende Kriegerin, nicht verbraucht (`markOnceUsed` chunk:565-566, night:60).
- Quelltextstellen:
  - roles:42 ORDER_BASE
  - roles:127 / roles:277 – Texte
  - chunk:554-570 Handler – Pick lebender Sitz; SL-Dialog "Ist {name} ein Wolf?"; Ja: nur Meldung "Kriegerin: Ziel ist Wolf.", Verbrauch; Nein: `applyKill(me,"WARRIOR_WRONG")`, Verbrauch, postDeathHooks
- Text DE (wörtlich): "Greift einmalig nachts direkt an und wählt einen Spieler. Der Spielleiter sagt, ob dieser Spieler ein Wolf ist. Ist er keiner, stirbt sie selbst."
- Text EN (wörtlich): "Once per game, attacks directly at night and chooses a player. The moderator reveals if that player is a wolf. If not a wolf, she dies."
- DE/EN-Vergleich: weitgehend JA. Nuance: "sagt" (DE, Empfänger offen) vs. "reveals" (EN, legt eher öffentliche Offenlegung nahe). Sonst gleich (einmalig, nachts, ein Spieler, Selbsttod bei Nicht-Wolf).
- Weitere Texte: ra:22 identisch. Alttext tools/create_role_doc.py:267-269: "greift nachts an. Kein Wolf getroffen = sie stirbt selbst", ebenfalls ohne ausdrücklichen Wolfstod. Kein Totenkartenbezug.
- Legacy-Codeverhalten:
  1. Zeitpunkt: Nachtschritt tier 6.0, einmal pro Spiel.
  2. Ziele: jeder lebende Sitz inkl. sie selbst (chunk:569 `x=>!x.flags.dead`); tote nicht.
  3. Wahrheit: NICHT automatisch; der SL beantwortet "Ist X ein Wolf?" manuell (chunk:560-566). Keine Nutzung von `isWolf`.
  4. Treffer (Ja): Ziel wird NICHT getötet; nur SL-Meldung, Verbrauch, rebuildOrder.
  5. Fehlschlag (Nein): Kriegerin stirbt sofort (`WARRIOR_WRONG`), Reaktionen und Siegprüfung sofort.
  6. Verbrauch: global `Used["role_Kriegerin_des_Lichts"]`; Abbruch des Picks ohne Verbrauch.
  7. Mehrere Kopien: `me` = erste lebende Kriegerin (chunk:564), nicht zwingend die handelnde; Verbrauch global.
  8. Sichtbarkeit: SL-Modal; ob Ergebnis öffentlich ist, nicht geregelt.
  9. Schutz: Schutzengel-Schutz wirkt nicht (nur beim Wolfs-Pick); der Selbsttod kann nur durch den globalen Nekromant-Schild (core:127-133) verhindert werden.
  10. Zufall: keiner.
  11. Rollenwechsel: Erbe kann nicht erneut (globaler Verbrauch).
- React-Version: nein, nur Bild (roleCard.ts:82).
- Bisherige Doku und Prüfergebnis: doc04:93 "verifiziert", "Einmal: benennt Spieler; Wolf → er stirbt (SL-Antwort), sonst stirbt sie (WARRIOR_WRONG)": Zeilen chunk:554-570 bestätigt; Aussage "Wolf → er stirbt" WIDERLEGT (chunk:565 tötet niemanden). doc04:120 B-10 und doc04:176 bestätigt. NIGHT-REPORT-abilities.md:52 (🟡/❌) nicht mehr aussagekräftig. DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Stirbt ein getroffener Wolf? | "Greift ... direkt an" | "attacks directly" | Nein, nur Meldung | Adapter | 04: "Wolf → er stirbt" | Angriff tötet den Wolf | Angriff ist nur Test, Wolf wird nur erkannt | A sehr stark (sicherer Wolfskill mit Risiko) | A: KillPipeline-Ursache, Reaktionen | Entscheidung nötig; 04 korrigieren | Ja |
| Wahrheitsquelle | "Der Spielleiter sagt" | "moderator reveals" | SL antwortet frei | Adapter | – | App prüft Fraktion automatisch | SL entscheidet (kann Erscheinung berücksichtigen) | A verhindert SL-Fehler | A: Fraktion oder appears_as | A mit Wahrheit, appears_as nur falls gewünscht | Ja |
| Öffentlichkeit | "sagt" | "reveals" | SL-Modal | Adapter | – | geheim an Kriegerin | öffentlich | B starke Dorfinfo | Sichtbarkeit actor vs public | nach PO | Ja |

- Bugs:
  - B-KL-1, technische Altlast: chunk:564 `seats.find` statt handelnder Sitz. Risiko: niedrig. Test: zwei Kriegerinnen, die handelnde stirbt bei Fehlschlag.
  - Kein echter Bug in der Kernlogik belegt; der fehlende Wolfstod ist eine Regelfrage (kein Text sagt ausdrücklich, dass der Wolf stirbt).
- Legacy-Status: legacy-contradictory. Code ist lauffähig; Text ("greift an"), Code (kein Treffer-Tod) und Doku 04 ("er stirbt") widersprechen sich.
- Automationsvorschlag: assisted. Zielwahl und Fraktionsprüfung automatisch, Ergebnis mit SL-Bestätigung bis zur Entscheidung über Wahrheit/Erscheinung.
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Einmalfähigkeit und Tötung (eigener Tod, ggf. Wolfstod)
- Benötigte vorhandene Godot-Systeme: StepQueue, PendingPrompt (zweistufig: Ziel, Ergebnis), InfoRecord (Wahrheit/ermittelt/gezeigt), appears_as, KillPipeline (WARRIOR_WRONG, ggf. Treffer), Reaktionswarteschlange, WinRules/WinCandidate, Ereignis-Sichtbarkeit, StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: keine.
- Abhängigkeiten von anderen Rollen: alle Wolfsrollen, Dämonischer Wolf (verfluchter Sitz: Wolf oder nicht?), Trugbilderwolf/Erscheinungsrollen, Doppelspion, Rudelvater (erste Sonderfähigkeitstötung überlebt, falls Treffer tötet), Nekromant-Globalschild.
- Komplexität und Fehlerrisiko: S / mittel. Einfacher Ablauf, aber Regelentscheidung mit großer Balancewirkung.
- Offene Entscheidungen: (1) Stirbt ein getroffener Wolf? (2) Prüft die App die Fraktion automatisch, und nach Wahrheit oder Erscheinung? (3) Ist das Ergebnis öffentlich? (4) Darf sie sich selbst wählen (Code: ja)?
- Relevante Testgruppen:
  - Normalfall: Kriegerin wählt Werwolf, Ergebnis "Wolf", Kriegerin lebt, Fähigkeit verbraucht.
  - ungültiges Ziel: toter Sitz abgelehnt, kein Verbrauch.
  - tote Person: tote Kriegerin erhält keinen Schritt.
  - Selbstwahl: Kriegerin wählt sich selbst, kein Wolf, stirbt (Legacy) bzw. abgelehnt (Entscheidung).
  - mehrere Kopien: zwei Kriegerinnen, jede einmal (Entscheidung), handelnde stirbt.
  - Wiederbelebung: nach Fehlschlag wiederbelebte Kriegerin hat keinen Schritt mehr.
  - Rollenwechsel: Ziel wurde in derselben Nacht zum Wolf (Wolfskind), Ergebnis nach aktuellem Stand.
  - Save/Load: Speichern zwischen Ziel und Ergebnis.
  - Replay: identisch.
  - SL-Korrektur: falsches Ergebnis per GmCorrection korrigieren, Tod rückgängig.
  - Sichtbarkeit: Ergebnis nur actor/gm oder public nach Entscheidung.
  - Schutz: Schutzengel-Schutz hilft beim Selbsttod nicht (nur Wolfsangriff).
  - Todesreaktionen: Selbsttod löst Reaktionen sofort aus.
  - Siegprüfung: Selbsttod führt zu Wolfsparität.
  - beschädigter Spielstand: Verbrauch gesetzt ohne Ergebnisereignis wird toleriert.
- Belegsicherheit: hoch.

---

### detektiv
- DE-Name / EN-Name: Detektiv / Detective (roles:202)
- Aliase/Altnamen: kein Alias. i18n `detectiveClue*` (i18n:237-239, 566-568). Bilder: Detektiv.webp, EN Detective.webp (gh:839, roleCard.ts:83).
- Legacy-ID (String in ALL_ROLES): "Detektiv" (roles:1, Position 65)
- Fraktion: dorf (roles:405-409).
- Akte (akte.js): Akt III (akte:55)
- Nachtpriorität: kein ORDER_BASE-Eintrag, Passivliste night:96.
- Quelltextstellen:
  - core:35-39 grimmLivingRoleInRound – lebender Detektiv nötig
  - core:66-83 detectiveEmitPublicClue – Auslöser, Zufall, Hinweislogik, center + gameLog
  - core:152 applyKill – ruft Hinweis bei jedem Tod eines `isWolf`-Sitzes (außer Doppelspion) nach `dead=true`
  - i18n:237-239 / 566-568 – Hinweistexte mit `{name}`; Paritätstext ohne Bezugsperson
  - js/ui/gamelog.js:19 – 🔍 ist inzwischen in der Recap-Liste
- Text DE (wörtlich): "Nach dem Tod eines Wolfes wird öffentlich ein Hinweis auf einen anderen Wolf verkündet."
- Text EN (wörtlich): "After a wolf dies, a public clue about another wolf is revealed."
- DE/EN-Vergleich: JA, semantisch gleich.
- Weitere Texte: ra:8 identisch. Alttext tools/create_role_doc.py:271-273 gleich. i18n-Hinweise: DE/EN gleich; Codefallback (core:79) nennt beim Paritätshinweis den Namen, der i18n-Text nicht. Kein Totenkartenbezug.
- Legacy-Codeverhalten:
  1. Auslöser: jeder Tod eines `isWolf`-Sitzes über `applyKill` (jede Ursache: Nacht, Lynch, Hexe, Schmiedewaffe, Kettentode), inkl. verfluchter Dorfbewohner (`cursedWolfAura`) und verwandelter Sitze. Manuelle Tode über den "tot"-Chip umgehen applyKill (doc01 F6), dann kein Hinweis.
  2. Bedingungen: lebender Detektiv (im Text nicht verlangt); nach dem Tod mindestens 2 lebende Wölfe (core:70). Bleibt nur 1 Wolf übrig, gibt es keinen Hinweis, obwohl es "einen anderen Wolf" gäbe.
  3. Zufall: `w` = zufälliger lebender Wolf per Math.random (core:71).
  4. Hinweis: gibt es einen Wolf auf Sitz id-1 von `w` ("links"), sonst auf id+1 ("rechts"): "Ein anderer Wolf sitzt links/rechts neben {name}". Direkte Sitze, tote Sitze werden nicht übersprungen. Sonst Paritätshinweis "Ein anderer lebender Wolf hat eine andere Sitz-Parität", OHNE Prüfung, ob das stimmt (core:79).
  5. Anzeige: `window.t` statt `tf` (core:77-79), daher steht wörtlich "{name}" im Modal und im Protokoll (F11). Der Paritätstext der i18n nennt keinen Bezugssitz und ist dadurch inhaltsleer.
  6. Inhalt, wenn repariert: der Hinweis nennt `w` beim Namen und impliziert, dass `w` selbst ein Wolf ist ("ein ANDERER Wolf neben w"), also eine direkte Wolfsenttarnung.
  7. Richtung: Detektiv nutzt links = niedrigere Sitznummer (id-1), Fährtenleser (chunk:473-483) nutzt links = höhere Sitznummer (doc04:86). Widersprüchliche Konvention im Legacy.
  8. Sichtbarkeit: `center(hint,true)` und gameLog 🔍; bei mehreren Overlays in derselben Kette wird das Modal überschrieben (z. B. Schmiedewaffe: Hinweis aus applyKill night:386 wird direkt von der Schmiede-Meldung night:387 überdeckt; nur das Protokoll behält ihn).
  9. Mehrere Kopien: ein Hinweis pro Wolfstod, unabhängig von der Zahl der Detektive.
  10. Rollenwechsel/Wiederbelebung: Prüfung zum Todeszeitpunkt.
  11. Sieg: keine.
- React-Version: nein, nur Bild (roleCard.ts:83).
- Bisherige Doku und Prüfergebnis: doc04:94 "verifiziert (Bug F11)", "Bei Wolfstod mit ≥ 2 lebenden Wölfen: öffentlicher Hinweis zur Sitzlage (Seed)": Zeilen core:66-83 bestätigt, Bedingung ≥2 bestätigt (nach dem Tod gezählt). "Seed" ist Zielbild, Code nutzt Math.random. Status "verifiziert" zu optimistisch: {name}-Bug plus ungeprüfter Paritätshinweis verfälschen die Kernfunktion. doc01:272 F11 bestätigt (core:77-79, i18n:237,566; zusätzlich i18n:238-239, 567-568). doc01:136 Sitzposition = ID bestätigt. doc07:45 "Detektiv {name}" bestätigt. GRIMMHAIN_ANALYSE_2026-06-12.md:186 (🔍 nicht in Recap) inzwischen behoben (gamelog.js:19). doc02:229 Beispiel "Ein Wolf sitzt links neben Dora" übernimmt die Enttarnungswirkung. DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Muss der Detektiv leben? | kein Hinweis | kein Hinweis | ja | Adapter | 04: nicht erwähnt | nur lebend | auch tot | B stärker | Bedingung am Hook | A (Code) | Ja |
| Mindestens 2 lebende Wölfe | "Hinweis auf einen anderen Wolf" | "about another wolf" | nach Tod ≥2 lebende Wölfe | Adapter | 04: ≥2 | ≥1 anderer lebender Wolf genügt | ≥2 (Code) | bei A Hinweis auf letzten Wolf, sehr stark | Schwelle | nach PO | Ja |
| Hinweisinhalt | "ein Hinweis" | "a clue" | nennt zufälligen lebenden Wolf als Bezug (enttarnt ihn) oder unbelegte Parität | Adapter | 02: "links neben Dora" | Hinweis bezieht sich auf den toten Wolf (Sitz des Toten als Anker) | Hinweis enttarnt Wolf w indirekt (Code) | B deutlich stärker, A moderat | Anker und Richtungsregel | A, und Parität nur wenn wahr | Ja |
| Richtung links/rechts | – | – | links = id-1 | Adapter | Fährtenleser: links = höhere Nummer | einheitlich id-1 | einheitlich id+1 | keine | Sitznachbarschaft mit einer Konvention | eine Konvention für alle Rollen | Ja |

- Bugs:
  - B-DT-1, echter Bug: core:77-79 `window.t` statt `window.tf`. Tatsächlich: Anzeige "Ein anderer Wolf sitzt links neben {name}." Erwartet: Name eingesetzt. Risiko: hoch (Hinweis wertlos). Test: Wolfstod erzeugt Hinweistext ohne Platzhalter.
  - B-DT-2, echter Bug: core:79 Paritätshinweis wird ohne Prüfung ausgegeben und nennt (per i18n) keinen Bezug. Tatsächlich: kann falsch sein (alle anderen Wölfe gleiche Parität) und ist ohne Bezug inhaltsleer; bei ungerader Sitzzahl ist Parität im Kreis nicht eindeutig. Erwartet: öffentliche Hinweise sind wahr. Risiko: hoch (öffentliche Falschinformation). Test: Wölfe auf Sitz 2 und 4 nicht benachbart, Hinweis darf keine andere Parität behaupten.
  - B-DT-3, technische Altlast: Overlay-Überschreibung bei gleichzeitigen Meldungen (night:386-387, core:76-80). Risiko: mittel. Test: Schmiedewaffe tötet Wolf, Detektiv-Hinweis erscheint im öffentlichen Morgenbericht.
  - B-DT-4, unklare Regel: Richtungskonvention abweichend vom Fährtenleser. Test: gemeinsame Sitznachbarschaftsfunktion.
- Legacy-Status: legacy-broken. Der Hinweis wird ausgelöst, ist aber durch den Platzhalterfehler inhaltsleer bzw. beim Paritätsfall möglicherweise falsch.
- Automationsvorschlag: automatic. Auslöser und Hinweis sind aus dem Zustand berechenbar (mit SeededRng).
- Mechanikfamilie primär + sekundär: Informationsrolle; sekundär Todesreaktion, Sitzpositionsmechanik, Zufallsmechanik
- Benötigte vorhandene Godot-Systeme: Reaktionswarteschlange (auf Wolfstod), SeededRng, InfoRecord (Wahrheit/gezeigt), Ereignis-Sichtbarkeit (public), KillPipeline-Ereignisse, appears_as (Abgrenzung Fluch), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: Sitznachbarschaft (einheitliche Links/Rechts-Konvention, lebend/tot überspringen).
- Abhängigkeiten von anderen Rollen: alle Wolfsrollen, Dämonischer Wolf (Verfluchte lösen aus), Wolfskind/Lehrling (verwandelte Wölfe), Doppelspion (ausgenommen), Dorfschmied (Wolfstod durch Waffe), Fährtenleser (Richtungskonvention).
- Komplexität und Fehlerrisiko: M / hoch. Öffentliche Information mit Zufall und Sitzlogik; Fehler erzeugen öffentliche Falschinformation.
- Offene Entscheidungen: (1) Muss der Detektiv leben? (2) Reicht ein verbleibender anderer Wolf? (3) Ist der Anker der tote Wolf oder ein zufälliger lebender Wolf (der dadurch enttarnt wird)? (4) Welche Hinweisarten gibt es, und müssen sie wahr sein? (5) Welche Richtung ist "links"? (6) Überspringen Nachbarn tote Sitze? (7) Lösen verfluchte Dorfbewohner aus?
- Relevante Testgruppen:
  - Normalfall: 3 Wölfe, einer stirbt, öffentlicher wahrer Hinweis mit fester Seed.
  - ungültiges Ziel: nicht relevant, weil keine Zielwahl.
  - tote Person: toter Detektiv, kein Hinweis (Legacy); Nachbar tot, Überspringen nach Entscheidung.
  - Selbstwahl: nicht relevant, weil keine Zielwahl.
  - mehrere Kopien: zwei Detektive, nur ein Hinweis pro Wolfstod.
  - Wiederbelebung: wiederbelebter Wolf stirbt erneut, erneuter Hinweis.
  - Rollenwechsel: verwandeltes Wolfskind stirbt, Hinweis ausgelöst.
  - Save/Load: RNG-Zustand bleibt, gleicher Hinweis nach Laden.
  - Replay: bytegleicher Hinweis.
  - SL-Korrektur: GmCorrection-Tod eines Wolfs löst Hinweis aus bzw. nicht (Option "mit Folgen").
  - Sichtbarkeit: Hinweis public, ohne verdeckte Rollennamen.
  - Schutz: nicht relevant, weil kein Kill.
  - Todesreaktionen: mehrere Wolfstode in einer Kette erzeugen mehrere Hinweise in fester Reihenfolge.
  - Siegprüfung: letzter Wolf stirbt, Dorfsieg ohne Hinweis.
  - beschädigter Spielstand: RNG-Zustand fehlt, Laden abgelehnt.
- Belegsicherheit: hoch. Nicht verifiziert: tatsächliche Darstellung, wenn Nacht-Todesübersicht (ui:470-477) und Center-Modal gleichzeitig offen sind (nur Code gelesen).

---

### dorfschmied
- DE-Name / EN-Name: Dorfschmied / Village Blacksmith (roles:203)
- Aliase/Altnamen: kein Alias. EN-Laufzeittexte "Village Smith" (i18n:562-563, 615-616). Flags `SchmiedForgeNights`, `SchmiedWeaponGiven`, `meta.schmiedWeapon`; Ursache `SCHMIED_WEAPON` (night:386, ui:407). Bilder: Dorfschmied.webp, EN Village_Blacksmith.webp (gh:840, roleCard.ts:84).
- Legacy-ID (String in ALL_ROLES): "Dorfschmied" (roles:1, Position 66)
- Fraktion: dorf (roles:405-409).
- Akte (akte.js): Akt IV (akte:76)
- Nachtpriorität: tier 1.7, kein once (roles:14). Bedingung: lebender Schmied (night:58, night:93). Zeile erscheint jede Nacht; vor Zählerstand 6 nur Info.
- Quelltextstellen:
  - roles:14 ORDER_BASE
  - roles:129 / roles:279 – Texte
  - night:161-163 onNightStart – `SchmiedForgeNights=min(6,+1)`, wenn irgendein Schmied lebt
  - chunk:571-582 Handler – `<6`: Meldung "Nacht n von 6"; bereits vergeben: Meldung; sonst Pick lebender Sitz, `meta.schmiedWeapon=true`, `SchmiedWeaponGiven=true`
  - night:380-392 resolveDayKills/processOne – Waffe bei Nachtopfer: Waffe weg, zufälliger lebender `isWolf` per Math.random stirbt (`SCHMIED_WEAPON`), Opfer überlebt
  - ab:106 APPLE_RESET_FLAGS – Rotkäppchen-Apfel erlaubt zweite Waffe
  - gh:525 clearRolesNewRound – `SchmiedForgeNights=0`, `SchmiedWeaponGiven` nicht
- Text DE (wörtlich): "Schmiedet fünf Nächte lang an einer Waffe. In der sechsten Nacht kann er sie einem Spieler geben. Dieser wehrt einen Wolfsangriff ab und tötet dabei einen zufälligen Wolf."
- Text EN (wörtlich): "Forges a weapon over five nights. On the sixth night, he may give it to a player. That player repels one wolf attack and kills a random wolf in the process."
- DE/EN-Vergleich: JA, semantisch gleich (5 Nächte, sechste Nacht, ein Spieler, ein Angriff, zufälliger Wolf).
- Weitere Texte: ra:14 identisch. Alttext tools/create_role_doc.py:275-277 "Nacht 6: gibt Waffe weiter die einen Wolf tötet" ohne Abwehrteil. EN-Laufzeitname "Village Smith" statt "Village Blacksmith". Kein Totenkartenbezug.
- Legacy-Codeverhalten:
  1. Zähler: zählt Nächte, zu deren Beginn mindestens ein Schmied lebt (nicht globale Nachtnummer). Nacht 1 zählt nur, wenn `onNightStart` für Nacht 1 läuft: ja in game.html-Setup (gh:1126, gh:1178) und React (legacyAdapter.ts:678, 701); im Weg setup.html nach game.html wird `onNightStart` beim Laden nicht aufgerufen (setup.html:1152-1154 setzt nur `dark=true`; gh ruft es nur über Knopf gh:508), dann erst ab Nacht 7 verfügbar, sofern der SL nicht "Nacht starten" drückt (nicht im Browser verifiziert).
  2. Zeitpunkt: ab Zählerstand 6 in jeder späteren Nacht (Text: "In der sechsten Nacht"); tier 1.7 vor dem Rudel.
  3. Ziele: jeder lebende Sitz inkl. Schmied selbst und Wölfe; tote nicht.
  4. Verbrauch: global einmal (`SchmiedWeaponGiven`), auch für mehrere Schmiede; Waffe bleibt am Sitz bis zum ersten Nachtangriff, auch über Nächte, auch nach Tod des Schmieds.
  5. Wirkung: nur in der Morgenauflösung für `targeted`-Opfer (Rudel, Rachsüchtiger Wolf, Schicksalswolf-Zusatz, Rudelvater-Zusatz). Greift auch gegen Durchbohren (Seuchenwolf/Rudelvater), da vor der Ursachenwahl geprüft (night:381). Nicht gegen Sofort-Tode (Verdammniswächter, Hexe, Hades; vgl. GRIMMHAIN_ANALYSE_2026-06-12.md:183 L14) und nicht gegen Nekromant-Umlenkung (night:374).
  6. Reihenfolge: Schutzengel-Schutz wird beim Rudel-Pick zuerst verbraucht (chunk:162), dann gibt es kein `targeted` und die Waffe bleibt. Der-Weise-Erstangriff (night:359-364) und Nekromant-Abwehr (night:365-378) kommen vor der Waffe.
  7. Zufall: Math.random über alle lebenden `isWolf` (inkl. verfluchter Sitze, inkl. des Waffenträgers selbst, falls er Wolf ist).
  8. Todesursache: `SCHMIED_WEAPON`; Rudelvater überlebt den ersten Tod durch Sonderfähigkeit (core:111-117), Meldung "ein Wolf stirbt" erscheint trotzdem. Das Waffenopfer wird nicht in `killedTonight` aufgenommen, Dämonischer-Wolf-Fluch (processDemonCurses night:352) greift dafür nicht; der Waffenträger erhält `killedTonight=true`, obwohl er überlebt (night:380, vgl. F14).
  9. Sichtbarkeit: Vergabe als SL-Modal; Abwehr `center(...,true)`, danach von späteren Overlays überdeckbar.
  10. Zeitwächter: bei eingefrorener Nacht bleibt die Waffe erhalten.
  11. Rollenwechsel: Erbe kann keine zweite Waffe vergeben (globales Flag); Zähler läuft weiter, solange irgendein Schmied lebt.
  12. Sieg: Waffentod kann Dorfsieg auslösen (postDeathHooks in afterCurses night:350).
- React-Version: nein, nur Bild (roleCard.ts:84); React ruft `onNightStart` auch in Nacht 1 und beim Fortsetzen einer Nacht (legacyAdapter.ts:678, 701), was bei einem mitten in der Nacht gespeicherten Spiel den Zähler ein zweites Mal erhöhen würde (nur per Code gelesen).
- Bisherige Doku und Prüfergebnis: doc04:95 "verifiziert", "Ab 6 Nächten einmal Waffe vergeben; Inhaber wehrt einen Wolfsangriff ab, zufälliger Wolf stirbt": Zeilen chunk:571-582, night:161-163, night:381-392 bestätigt. Ergänzt: Zähler nur bei lebendem Schmied, Nacht-1-Zählung hängt am Startweg, Rudelvater kann Waffentod überleben, Opfer nicht in `killedTonight`. doc04:140 (Abfangregel nur Nachtauflösung) und doc04:164 bestätigt. doc03:327 (SeededRng für Schmied-Opfer) als Zielbild. DECISION-LOG: kein Eintrag.
- Widersprüche:

| Thema | DE-Text | EN-Text | Legacy-Code | React | Doku | Interpretation A | Interpretation B | Balance-Auswirkung | Implementierungsauswirkung | Empfehlung | PO-Entscheidung Ja/Nein |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Welche Nächte zählen | "Schmiedet fünf Nächte lang" | "over five nights" | nur Nächte mit lebendem Schmied, Nacht 1 je nach Startweg | Nacht 1 zählt | 04: "Ab 6 Nächten" | globale Nachtnummer 6 | eigene Schmiedenächte | gering | Zähler vs. Nachtnummer | A (einfach, eindeutig) | Ja |
| Nur Nacht 6 oder ab Nacht 6 | "In der sechsten Nacht" | "On the sixth night" | ab Nacht 6 jede Nacht | Adapter | 04: "Ab 6" | nur Nacht 6 | ab Nacht 6 | A strenger | Schrittfreigabe | B (Code) | Ja |
| Welche Angriffe | "einen Wolfsangriff" | "one wolf attack" | nur Morgenopfer über `targeted`, auch durchbohrende | Adapter | 04 C.1 | alle Wolfsangriffe inkl. durchbohrend | durchbohrende ausgenommen | gering | Filter `is_wolf_attack` | A (Code) | Ja |

- Bugs:
  - B-DS-1, echter Bug (Randfall): night:384-387 meldet "ein Wolf stirbt", auch wenn `applyKill` false liefert (Rudelvater-Erstrettung, Nekromant-Globalschild). Risiko: niedrig bis mittel (SL-Fehlinformation). Test: Waffe trifft Rudelvater, Meldung "Wolf überlebt".
  - B-DS-2, technische Altlast: Waffenopfer nicht in `killedTonight` (night:386), Dämonischer-Wolf-Fluch entfällt. Risiko: niedrig (Akt IV ohne Dämonischen Wolf). Test: Waffe tötet Dämonischen Wolf, Fluchschritt folgt.
  - B-DS-3, technische Altlast: `SchmiedWeaponGiven` wird in gh:512-529 nicht zurückgesetzt. Risiko: mittel im Legacy. Test: neue Runde, Waffe erneut vergebbar.
  - B-DS-4, unklare Regel: Zählerstart abhängig vom Startweg (setup.html vs. game.html/React). Test: Nacht 6 nach jedem Startweg erlaubt Vergabe.
- Legacy-Status: legacy-verified. Kernfunktion (Schmieden, Vergabe, Abwehr, zufälliger Wolfstod) funktioniert; Randfälle betreffen Meldung und Zählerstart.
- Automationsvorschlag: automatic. Zähler, Vergabe und Abwehr sind zustandsbasiert; Zufall über SeededRng.
- Mechanikfamilie primär + sekundär: Wolfsangriff-Modifikation; sekundär Tötung und Zufallsmechanik (auch Schutz)
- Benötigte vorhandene Godot-Systeme: StepQueue (Schritt mit Freigabebedingung), PendingPrompt, KillPipeline (Abfangregel vor NIGHT_KILL mit Filter Wolfsangriff), Protections (Reihenfolge zu Schutzengel), SeededRng, Reaktionswarteschlange (Tod des zufälligen Wolfs), WinRules, InfoRecord/Sichtbarkeit (gm, ggf. public), StateCodec, Replay, GmCorrections.
- Benötigte NEUE Systeme: dauerhafte Statusmarker (Waffe am Sitz über Nächte), Zähler für zeitlich verzögerte Freischaltung (Schmiedezähler).
- Abhängigkeiten von anderen Rollen: Werwolf/Rudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater, Seuchenwolf, Schutzengel, Der Weise, Nekromant, Rudelvater (Erstrettung), Dämonischer Wolf, Detektiv (Hinweis bei Waffentod), Zeitwächter, Verdammniswächter (umgeht Waffe), Rotkäppchen (Apfel: zweite Waffe).
- Komplexität und Fehlerrisiko: M / mittel. Mehrere Interaktionen in der Kill-Pipeline und Zufall.
- Offene Entscheidungen: (1) Globale Nachtnummer oder eigene Schmiedenächte? (2) Nur Nacht 6 oder ab Nacht 6? (3) Darf der Schmied sich selbst oder einen Wolf ausrüsten? (4) Schützt die Waffe auch vor durchbohrenden Angriffen und vor Sofort-Toden durch Wolfsrollen? (5) Wird das Waffenopfer öffentlich verkündet? (6) Kann der Waffenträger selbst das Zufallsopfer sein, wenn er Wolf ist?
- Relevante Testgruppen:
  - Normalfall: Nacht 6 Waffe an X, Nacht 7 Rudel wählt X, X lebt, ein Wolf (Seed) stirbt.
  - ungültiges Ziel: Vergabe vor Nacht 6 abgelehnt; toter Sitz abgelehnt.
  - tote Person: Schmied stirbt vor Nacht 6, Zähler stoppt (Legacy) bzw. Schritt entfällt; Waffe bleibt nach Tod des Schmieds beim Träger.
  - Selbstwahl: Schmied rüstet sich selbst aus, Abwehr funktioniert.
  - mehrere Kopien: zwei Schmiede, eine Waffe (Legacy) oder je eine (Entscheidung).
  - Wiederbelebung: Waffenträger stirbt anders und wird wiederbelebt, Waffe weg oder erhalten (Entscheidung).
  - Rollenwechsel: Lehrling erbt Schmied nach Vergabe, keine zweite Waffe.
  - Save/Load: Waffe und Zähler bleiben; RNG gleich.
  - Replay: identisches Zufallsopfer.
  - SL-Korrektur: Waffe per GmCorrection entfernen.
  - Sichtbarkeit: Vergabe nur gm/actor; Abwehr gm oder public (Entscheidung).
  - Schutz: Schutzengel und Waffe auf demselben Ziel, Reihenfolge festgelegt.
  - Todesreaktionen: Zufallsopfer ist Wolf mit Todesreaktion (Besessener Wolf), Reaktion folgt.
  - Siegprüfung: Zufallsopfer ist letzter Wolf, Dorfsieg.
  - beschädigter Spielstand: Waffe am toten Sitz, Zähler > 6 werden normalisiert.
- Belegsicherheit: hoch für Code; mittel für den Nacht-1-Startweg (nicht im Browser geprüft).

---

## Gruppenübergreifende Beobachtungen

1. Globale Einmal-Flags statt sitzbezogener Zustände: Zeitwächter, Kriegerin (`Used["role_..."]`), Dorfchronistin (`ChroniclerShown`), Dorfschmied (`SchmiedWeaponGiven`, `SchmiedForgeNights`), Schutzgeist (`SchutzgeistAwaitingPick`) speichern Verbrauch global pro Rollenname. Folgen: mehrere Kopien teilen sich den Verbrauch, Erben (Lehrling, Seelentauscher) können nicht erneut nutzen, weil `resetOnceForInheritedRole` (core:339-359) die tatsächlich benutzten Schlüssel nicht löscht. Godot sollte Verbrauch pro Person/Rolleninstanz führen und die PO-Frage "Erbe = frische Fähigkeit?" einmal zentral klären (ApprenticeBond regelt das für den Lehrling bereits teilweise).
2. `seats.find(...)` statt handelnder Sitz: Amalia (chunk:527) und Kriegerin (chunk:564) treffen bei Duplikaten die erste lebende Kopie.
3. `clearRolesNewRound` (gh:512-529) vergisst vier Flags dieser Gruppe (`SchmiedWeaponGiven`, `ChroniclerShown`, `SchutzgeistAwaitingPick`, `TimekeeperFreezeMorning`). FIX_REPORT.md:7 listet den Reset als erledigt, deckt diese Flags aber nicht ab.
4. `isWolf` inkl. `cursedWolfAura` wirkt in fast allen Rollen der Gruppe: Schutzgeist-Wolfsmeldung, Amalia-Schwelle, Detektiv-Auslöser und -Hinweis, Schmied-Zufallsopfer, Wächter-am-Tor-Probe. Die PO-Entscheidung zum Dämonischen Wolf (doc07 Q1, Vorschlag "nur Erscheinung") ändert das Verhalten all dieser Rollen; in Godot über `appears_as` statt Fraktion lösen.
5. Ein einziges `#overlay` für alle Meldungen: Meldungen in derselben synchronen Kette überschreiben sich (Detektiv-Hinweis vs. Schmied-Meldung). Godot sollte Hinweise als Ereignisse mit Sichtbarkeit sammeln und im Morgenbericht (doc02:85) ausgeben.
6. Sitzrichtung uneinheitlich: Detektiv links = id-1, Fährtenleser links = höhere Nummer (doc04:86). Eine gemeinsame Sitznachbarschaftsfunktion ist nötig.
7. Zufall: Math.random in Detektiv (core:71) und Schmied (night:385); beide müssen auf SeededRng.
8. Nachtreihenfolge vs. Schutz: Schutz wird beim Rudel-Pick (tier 2.0) geprüft und bei Nachtbeginn gelöscht. Jede Schutzquelle nach tier 2.0 (Schutzgeist 5.6) ist wirkungslos. Das betrifft die Godot-Entscheidung, ob Schutz beim Pick oder bei der Auflösung geprüft wird (doc07 Q1 Schutzengel: "Verbrauch erst bei Auflösung"); mit Prüfung bei Auflösung würde der Schutzgeist-Schutz für die laufende Nacht wirksam.
9. Fehler/Ungenauigkeiten in 04: A-59 Schutzgeist "fehlend" besser "legacy-broken", und F1-Fix allein reicht nicht (Reihenfolge/Reset). A-63 Amalia "verifiziert" übersieht die nicht modellierte Frage und den Tag/Nacht-Widerspruch. A-64 Kriegerin "Wolf → er stirbt" ist falsch, der Code tötet den Wolf nicht. A-65 Detektiv "verifiziert (Bug F11)" unterschätzt den ungeprüften Paritätshinweis und die Enttarnungswirkung. A-62 Zeitwächter "nur Wolfstode" ist zu eng beschrieben (Witwe, Giftwolf, Märtyrerin, Voodoo laufen weiter; spätere Dorf/Solo-Schritte werden blockiert). A-61 Wächter am Tor: Dämonischer-Wolf-Fluch fehlt in der Liste der (nicht) abgefangenen Wege.
10. Akt-Zuschnitt: Wächter am Tor (Akt IV) hat in seinem Akt keine einzige Wolfsquelle; Detektiv (Akt III) und Dorfschmied (Akt IV) treffen sich nur im Custom-Setup.
11. EN-Laufzeitnamen weichen von den offiziellen EN-Rollennamen ab: "Timekeeper" statt "Time Warden", "Village Smith" statt "Village Blacksmith". Pick-Prompts wie "  (U+2014) Schutzschild vergeben", "  (U+2014) Waffe übergeben", "  (U+2014) Ziel" haben keine EN-Übersetzung in `translateRuntimeText` (i18n:716ff, per grep geprüft).
12. Verwaiste i18n-Schlüssel: `amaliaPromptQuestion`, `amaliaPublicQuestion`, `amaliaButtonSubmitQuestion`, `gatewardenBlock`.
13. Alttexte in tools/create_role_doc.py:247-277 weichen teils ab (Schutzgeist "from the next attack", Amalia "2+ Wölfe"); sie sind keine autoritative Quelle, liefern aber Hinweise auf frühere Absicht.
