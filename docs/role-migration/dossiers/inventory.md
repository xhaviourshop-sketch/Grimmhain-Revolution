<!-- Belegdossier zu docs/role-migration. Erstellt am 2026-09-26 durch Code-Lektüre (Basiscommit 4673b0b), siehe ../00-method-and-sources.md §2. -->

> **Belegdossier.** Rohbefund der Code-Lektüre für die in der Überschrift genannte Rollengruppe. Pfadkürzel: `roles` = `js/core/roles.js`, `chunk` = `js/core/abilities-roles-chunk.js`, `ab` = `js/core/abilities.js`, `help` = `js/core/abilities-helpers.js`, `night` = `js/core/night.js`, `core` = `js/ui/core.js`, `ui` = `js/ui/ui.js`, `state` = `js/core/state.js`, `gh` = `game.html`. Zeilenangaben gelten für Commit `4673b0b`. Gedankenstriche in wörtlichen Zitaten sind als `(U+2014)` wiedergegeben. Statuswerte und Entscheidungs-IDs sind in `01` bis `08` verbindlich; weicht ein Dossier ab, gilt das Hauptdokument.

# G9 Rollen-Inventar: Wie viele Grimmhain-Rollen gibt es wirklich?

Stand: 2026-09-26, Basiscommit `4673b0b` (flacher Klon, nur 50 Commits Historie, daher keine Git-Archäologie vor `c07c2d9` möglich). Nur gelesen, nichts im Repository verändert.

Methode: `js/core/roles.js` per Node-`vm` geladen (ALL_ROLES, ROLE_NAMES_EN, WOLF/SOLO, ORDER_BASE als echte Laufzeitwerte), alle anderen Listen per Skript (String-Literale, Array-/Objekt-Literale mit mindestens 3 Rollennamen, Levenshtein-Abstand 1 bis 2 zu Rollennamen, Liste klassischer Altnamen) gegen ALL_ROLES abgeglichen, Treffer manuell geprüft.

Referenz (bereits bestätigt, erneut nachgerechnet):

| Quelle | Wert | Beleg |
|---|---:|---|
| `ALL_ROLES` | 72 Einträge, 72 eindeutig | `js/core/roles.js:1` |
| `ROLE_DESCRIPTIONS` / `ROLE_NAMES_EN` / `ROLE_DESCRIPTIONS_EN` | je 72 Schlüssel, deckungsgleich mit ALL_ROLES | `js/core/roles.js:63`, `:137`, `:212` |
| `WOLF_ROLES_SET` | 19 | `js/core/roles.js:391-396` |
| `SOLO_WIN_ROLES` | 14 | `js/core/roles.js:399-403` |
| Dorf (Rest, `getRoleFaction`) | 39 | `js/core/roles.js:405-409` |
| `ORDER_BASE` | 50, alle in ALL_ROLES | `js/core/roles.js:3-62` |
| Fähigkeits-Handler (`GRIMM_ABILITIES_ROLES` + 2 Nachträge) | 49 (47 + Rotkäppchen + Hades), alle in ALL_ROLES | `js/core/abilities-roles-chunk.js:2`, `js/core/abilities.js:7`, `:27` |

Ergänzend: Die 22 Rollen ohne ORDER-Eintrag sind 15 passive Rollen aus `passive` (`js/core/night.js:96`) plus 7 ohne eigene Zeile (Spiegelwolf, Dämonischer Wolf, Trugbilderwolf, Besessener Wolf, Fenrir, Blutwolf, Dorfbewohner; Wölfe laufen über die Werwolf-/`WOLF_KILL_ROLES`-Zeile, `js/core/night.js:50-55`). Einzige ORDER-Rolle ohne Handler ist Märtyrerin, sie wird direkt in `js/core/night.js:257` behandelt.

---

## 1. `js/core/state.js`: Migration und Reststate alter Rollen

### 1a. `migrateLegacyRoleIds` (`js/core/state.js:16-45`, Karte in Zeile 18)

13 Altnamen, alle Ziele sind gültige ALL_ROLES-Namen. Aufgerufen über `migrateState` (`js/core/state.js:50`) aus `game.html:371` und `app/src/adapter/legacy/legacyEnv.ts:126`.

| Altname | wird zu | Art | Zusatz-Migration |
|---|---|---|---|
| Amor | Loki | Umbenennung | - |
| Hexe | Waldhexe | Umbenennung | `HexeL/HexeD` nach `WaldhexeL/D` (`:24-26`) |
| Jäger | Sensenträger | Umbenennung | - |
| Seherin | Das Orakel | Umbenennung | - |
| Flötenspieler | Rattenfänger | Umbenennung | - |
| Weißer Werwolf | Rachsüchtiger Wolf | Umbenennung | - |
| Der Alte | Der Weise | Umbenennung | `DerAlteFirstAttackUsed` nach `DerWeiseFirstAttackUsed` (`:27-28`) |
| Engel | Schutzengel | Umbenennung | - |
| **Blinzelmädchen** | **Dorfbewohner** | **entfernte Rolle ohne Nachfolger** | - |
| Bärenführer | Nachtwächter | Umbenennung | - |
| Fuchs | Spürhund | Umbenennung | `FuchsRetired` gelöscht (`:22`) |
| Urwolf | König Lykaon | Umbenennung | `UrwolfUsed` gelöscht (`:23`), zusätzlich `usedKey("Urwolf")` in `js/ui/core.js:350` |
| Totenrat-Führer | Nekromant | Umbenennung | Reststate-Felder bleiben unter altem Namen, s. 1b |

Zusätzlich werden `once.Used`-Schlüssel, `BlockedRolesTonight` und `TeamWinner`-Texte umgeschrieben (`js/core/state.js:29-43`).

**Blinzelmädchen:** Ja, das ist eine entfernte Rolle. Es ist der einzige Eintrag, der auf die generische Rolle `Dorfbewohner` statt auf eine thematische Nachfolgerin abgebildet wird. Das Wort kommt im gesamten Repo nur in `js/core/state.js:18` und in `docs/role-migration/02-implemented-roles-audit.md:53` vor (dort ausdrücklich „den entfernten Altnamen `Blinzelmädchen`"). Keine Karte, keine Beschreibung, kein Handler. Git-Historie reicht wegen flachem Klon nicht zurück (`git log -S` endet an der Klon-Wurzel `c07c2d9`).

**Nicht in der Migrationskarte, aber als Altname belegt:**
- `Mogli` / „Wildes Kind": Nur als Feldname erhalten (`MogliVorbildId`, `MogliUsed`), benutzt vom heutigen Wolfskind (`js/core/abilities-roles-chunk.js:714`, `js/ui/core.js:345`, `:388`, `js/core/state.js:57`, `:66`, `game.html:523`). Ein alter Spielstand mit Rollenstring `Mogli` würde NICHT migriert (Indiz, kein Beweis, dass `Mogli` je als Rollenstring existierte).
- `Busfahrer`: Siehe Punkt 10 / Tools. Nicht migriert.

### 1b. Reststate-Felder alter Rollen in `createState` / `migrateState`

| Feld | Stelle | Heute benutzt von | Status |
|---|---|---|---|
| `once.TotenratFuehrerSilenced`, `TotenratFuehrerRevealed`, `TotenratFuehrerUsedDeflect` | `js/core/state.js:10`, `:68-69` | Nekromant (`js/core/night.js:237`, `:365-371`, `game.html:533`, `:543`, `js/ui/field-viewmodel.js:72`) | lebendig, nur Altname im Feldnamen |
| `once.TotenratDeathImmunityPending` | nicht in createState | Nekromant (`js/core/abilities-roles-chunk.js:194`, `js/core/night.js:141`, `js/ui/core.js:127`) | lebendig |
| `once.MogliVorbildId` | `js/core/state.js:10`, `:66` | Wolfskind | lebendig, Altname |
| `once.ghost: {copiedRole, active}` | `js/core/state.js:10`, `:65` | nirgends gelesen (nur state.js) | **toter Reststate** |
| `ui.ghostCasting` | `js/core/state.js:71` | Geister-Ausführung von Fähigkeiten (`js/core/night.js:4-5`, `js/core/abilities.js:78`, Waldhexe/Frankenstein im Chunk) | lebendig, keine Rolle |
| `once.OldDebuff` | `js/core/state.js:10`, `:64` | Der Weise (Lynch-Debuff, `js/core/night.js:232`, `:458`, `js/core/abilities.js:96`) | lebendig, Altname „Der Alte" |
| `meta.hunterQueued/hunterShot` | `js/core/state.js:5` | Sensenträger (Altname „Jäger/Hunter") | lebendig |
| `pending.judgeAsk` | `js/core/state.js:10`, `:72` | laut `docs/godot-migration/01-current-system-inventory.md:290` nie gelesen | vermutlich tot |

Keine dieser Felder erzeugt eine zusätzliche Rolle.

---

## 2. `js/core/akte.js`: Rollen je Akt

| Akt | Einträge | eindeutig | Dorf / Wolf / Solo | ungültig | Beleg |
|---|---:|---:|---|---|---|
| akt1 „Howl of the Hollow" | 17 | 17 | 12 / 3 / 2 | 0 | `js/core/akte.js:14-23` |
| akt2 „Veins of the Old Forest" | 27 | 27 | 15 / 7 / 5 | 0 | `js/core/akte.js:32-44` |
| akt3 „The Looking-Glass Choir" | 26 | 26 | 14 / 7 / 5 | 0 | `js/core/akte.js:53-65` |
| akt4 „Ash Crown of Grimmhain" | 27 | 27 | 14 / 9 / 4 | 0 | `js/core/akte.js:74-85` |
| custom | `null` = alle ALL_ROLES | - | - | - | `js/core/akte.js:94`, `:100-104` |

Die Fraktionszählung stimmt mit den Kommentaren in der Datei überein (nachgerechnet mit WOLF/SOLO aus roles.js).

- Summe der Akt-Einträge 97, Vereinigung **72**: Die Behauptung „72/72 Rollen vollständig abgedeckt" (`js/core/akte.js:3`) ist **korrekt**.
- **Rollen in keinem Akt (nur Custom): keine.**
- Mehrfach vertreten (13): Dorfbewohner, Der Weise, Sensenträger, Loki, Werwolf, Rachsüchtiger Wolf (je akt1-4); Waldhexe (1,2); Verdammniswächter (2,4); Lehrling (2,3); König (3,4); Albtraumwolf (3,4); Prophet des Untergangs (3,4); Kartenschlucker (3,4).
- Die eingebaute Validierung (`js/core/akte.js:123-144`) meldet 0 Probleme (per vm ausgeführt).
- Weitere „72"-Texte: `js/core/akte.js:91-92` („Alle 72 Rollen"), `:103`, `index.html:309` (Button-Titel).

---

## 3. `js/core/i18n.js`

- i18n.js hat **keine eigene Rollenliste**. Rollennamen/-texte kommen aus `ROLE_NAMES_EN` / `ROLE_DESCRIPTIONS_EN` in roles.js (`getRoleName` `js/core/i18n.js:700-706`, `getRoleDescription` `:708-714`, Laufzeit-Übersetzung `:806-809`).
- Keine Rollennamen außerhalb ALL_ROLES in Werten. Altnamen leben nur in **Schlüsselnamen** weiter (Werte sagen korrekt Nekromant / Rachsüchtiger Wolf / Der Weise):

| Schlüsselgruppe | Altrolle | heutige Rolle | Beleg |
|---|---|---|---|
| `totenrat*`, `shieldTotenrat*` (ca. 20 Schlüssel je Sprache) | Totenrat-Führer | Nekromant | `js/core/i18n.js:157-184`, `:255-256`, EN `:481-508`, `:579-580` |
| `whiteWolf*`, `noWhiteWolfActive` | Weißer Werwolf | Rachsüchtiger Wolf | EN `js/core/i18n.js:530-533` |
| `hunterCurse*`, `logHunterShot` | Jäger | Sensenträger | Schlüsselnamen |
| `witch*`, `logWitchPoison` | Hexe | Waldhexe | Schlüsselnamen |
| `oldDebuff` | Der Alte | Der Weise | `js/core/i18n.js:550` |

- EN-Namensabweichungen in Texten (keine neue Rolle, aber inkonsistent zu `ROLE_NAMES_EN`):
  - `js/core/i18n.js:958`: „seen by the **Seer**" (ROLE_NAMES_EN: „The Oracle").
  - `js/core/i18n.js:459`: `logWitchPoison` „by the **Witch**" (ROLE_NAMES_EN: „Witch of the Woods").
- Fallback-Texte mit „Totenrat" nur, wenn `t()` fehlt: `js/core/night.js:369`, `:373`.

---

## 4. `js/core/role-abilities.js`

`ROLE_ABILITIES` (`js/core/role-abilities.js:2-78`): **72 Schlüssel, 0 Duplikate, 0 fremde Namen, 0 fehlende** gegenüber ALL_ROLES.

---

## 5. Web-Layer: `js/ui/*.js`, `game.html`, `setup.html`, `index.html`

### 5a. Rollen-Strings außerhalb ALL_ROLES

| String | Stelle | Bedeutung | Bewertung |
|---|---|---|---|
| `"Chronist"` | `js/core/abilities.js:107` (`APPLE_RESET_FLAGS`) | gemeint: Dorfchronistin (Flag `ChroniclerShown`, gesetzt in `js/core/abilities-roles-chunk.js:507`, `:514`) | **Tippfehler/Alias, Bug**: Schlüssel trifft nie, Rotkäppchen-Apfel setzt Dorfchronistin nicht zurück (auch in `docs/godot-migration/04-rules-migration-matrix.md:122` notiert) |
| `"Totenrat-Führer"` | `game.html:889`, `game.html:1019` | 15. Eintrag in SOLO-Fallback-Sets | Altname; nur aktiv, falls `window.SOLO_WIN_ROLES` fehlt. Sets enthalten sonst alle 14 SOLO-Rollen |
| `"Urwolf"` | `js/ui/core.js:350` | `usedKey("Urwolf")` beim Zurücksetzen von König Lykaon | Altname-Aufräumcode, harmlos |
| Altnamen-Karte | `js/core/state.js:18` | s. Punkt 1 | gewollt |

Gezielte Suche (Wortgrenzen) nach Amor, Hexe, Jäger, Seherin, Flötenspieler, Weißer Werwolf, Der Alte, Engel, Blinzelmädchen, Bärenführer, Fuchs, Urwolf, Totenrat-Führer, Mogli, Wildes Kind, Dieb, Bürgermeister, Heiler, Gaukler in `js/`, `game.html`, `setup.html`, `index.html`, `sw.js`, `manifest.json`:
- Außer den oben genannten Stellen und `js/core/state.js:18` **keine Treffer**. Dieb, Bürgermeister, Heiler, Gaukler, Wildes Kind, Mogli (als Rollenstring) kommen im Web-Code gar nicht vor.
- `index.html` enthält keine Rollennamen.

### 5b. Weitere Inline-Rollenlisten im Web-Layer (Abgleich mit Referenz)

| Liste | Stelle | Umfang | Abweichung |
|---|---|---:|---|
| `WOLF` in `renderSetupOverview` | `game.html:888` | 19 | identisch mit WOLF_ROLES_SET, aber hart kopiert (verstößt gegen Konvention „keine Inline-Listen") |
| `WOLF_ROLES_SET` (lokal, überschattet) | `game.html:1018` | 19 | identisch, hart kopiert |
| SOLO-Fallbacks | `game.html:889`, `:1019` | 15 | + `Totenrat-Führer` |
| `CARD_MAP_EN` | `game.html:813-843` | **71** | **fehlt: Rachsüchtiger Wolf** (EN fällt auf DE-Karte zurück) |
| `CARD_MAP_DE_EXCEPTIONS` | `game.html:807-812` | 4 | wie `_RP_IMG_EXCEPTIONS` in roles.js |
| `WOLF_KILL_ROLES` | `js/core/night.js:50` | 10 | Teilmenge; Ursache von F2 |
| `passive` | `js/core/night.js:96` | 15 | alle ohne ORDER-Eintrag, konsistent |
| Revive-Fallback | `js/core/night.js:31` | 4 | Frankenstein, Kutscher, Lehrling, Wolfskind |
| `GRIMM_ROLE_TAGS` | `js/core/roles.js:287-298` | 10 | alle gültig |
| `getRoleMax` / `getRoleMaxCopies` | `setup.html:793-798`, `game.html:863-868` | 3 | s. Punkt 6 |

`js/ui/*.js` (core, ui, field-viewmodel, field-pixi, audio, gamelog, touch-tooltips) enthalten keine eigenständigen Rollenlisten.

---

## 6. `setup.html`: Obergrenzen, Pflichtpaare, Zufallsverteilung

| Regel | Inhalt | Beleg |
|---|---|---|
| Max. Kopien | Werwolf 5, Dorfbewohner 10, Die Gebundenen 6, **alle anderen 69 Rollen 1** | `setup.html:793-798`; identische Kopie `game.html:863-868` |
| Klick-Logik | Klick zählt hoch, über Max wieder auf 0; kein Hochzählen, wenn Summe = Spielerzahl | `setup.html:930-940` |
| Rollenpool | nur Rollen des gewählten Akts (`getAktRollen`, Default akt1) | `setup.html:876-887`, Akt-Wechsel filtert Auswahl `setup.html:1076-1083` |
| Weiter-Button | nur wenn Summe gewählter Rollen = Spielerzahl | `setup.html:853-861` |
| **Pflichtpaar** | Schwarze Witwe nur mit Loki im Pool (sonst Abbruch mit Warnung) | `setup.html:1111-1117`; ebenso `game.html:1194-1201` |
| Weitere Pflichten | keine (kein Mindest-Wolf, keine Fraktionsbalance, keine Gebundenen-Mindestzahl) | ganze Datei |
| Zufallsverteilung | Fisher-Yates-Mischung der gewählten Rollenliste, danach Sitz i erhält `roles[i]` | `setup.html:1119-1124`, `:1142-1149` |
| Wolf-Flag | `flags.werewolf = WOLF_SET.has(r)` nur bei Zufallsverteilung | `setup.html:1148` |
| Selbst verteilen | Rollen werden nicht gesetzt, SL vergibt in game.html | `setup.html:1099-1101`, `:1142` |
| Fraktion | `getFaction` über WOLF_SET/SOLO_SET aus roles.js | `setup.html:722-723`, `:800-804` |

Abweichung game.html-Setup-Modal: Chips über **alle 72** Rollen ohne Akt-Filter (`game.html:1020-1026`), Rollen-Picker dagegen Akt-gefiltert (`game.html:707-716`). Eigene Zufallsmischung `game.html:1146`.

Godot weicht bewusst ab: keine Obergrenze für Grundrollen (`docs/masterplan/DECISION-LOG.md:99-101`, `godot/core/rules/role_catalog.gd:5-10`).

---

## 7. Rollenkarten `assets/cards/**`

| Ordner | Dateien | Rollenkarten | Extra | Beleg |
|---|---:|---:|---|---|
| `assets/cards/de` | 73 WebP | 72 | `Hintergrund.webp` (Rückseite) | `ls` |
| `assets/cards/en` | 73 WebP | 72 | `Background.webp` (Rückseite) | `ls` |

- DE über `roleToImagePath` (`js/core/roles.js:411-420`) und über `getRoleCardPath` (`game.html:845-852`, ersetzt nur Leerzeichen, Bindestrich über Ausnahme): **alle 72 vorhanden, keine fehlend, keine überzählig** außer Rückseite.
- DE-Sonderfälle: `Loki_DE.webp`, `Dorfchronistin_DE.webp`, `Wahnsinniger Kutscher.webp` (mit Leerzeichen), `Voodoo_Priester.webp`.
- EN: `CARD_MAP_EN` hat nur 71 Einträge; `Vengeful_Wolf.webp` liegt vor, wird aber nie referenziert. `Rachsüchtiger_Wolf.webp` und `Vengeful_Wolf.webp` sind byte-identisch (md5 `3102adfb...`), ebenso Hintergrund/Background.
- EN-Namen vs. Dateinamen: Rachsüchtiger Wolf = „Lone Wolf" (Name) vs. `Vengeful_Wolf` (Datei); Rudelvater „Packfather" vs. `Pack_Father`; Doppelspion „Double Agent" vs. `Doppelspion.webp`; Dorfchronistin `Village_Chronicler_EN`; Loki `Loki_EN`.
- `assets/portraits/manifest.json` ist leer (`[]`), keine Rollenporträts. `app/public/assets/portraits` enthält 10 Archetypen-PNGs (keine Rollen).
- Sound-Altnamen: `assets/sounds/Amor.mp3`, `assets/sounds/Bärenführer.mp3` (Altnamen von Loki/Nachtwächter), heute unreferenziert, da Rollen-SFX deaktiviert (`js/ui/audio.js:8-12`).

---

## 8. React-Version `app/src/**`

| Datei | Rolleninhalt | Anzahl | Abweichung |
|---|---|---:|---|
| `app/src/roleCard.ts:12-17` | `CARD_MAP_DE_EXCEPTIONS` | 4 | identisch mit game.html |
| `app/src/roleCard.ts:19-92` | `CARD_MAP_EN` (laut Kommentar „VERBATIM" aus game.html) | **71** | fehlt Rachsüchtiger Wolf (im Kommentar `:6` dokumentiert) |
| `app/src/adapter/legacy/legacyAdapter.ts:590-599` | `listRoles()` = `getAktRollen("custom")` | 72 (Laufzeit) | keine eigene Liste |
| `app/src/adapter/legacy/legacyAdapter.ts:638-652` | `getRolePool(aktId)` | Laufzeit | keine eigene Liste; im UI nirgends aufgerufen |

- **Keine eigene Rollenliste, keine eigenen Rollendaten**; Fraktion/Name kommen aus `getRoleFaction`/`getRoleName`, Legacy-JS wird per `app/scripts/sync-legacy.mjs:28-39` übernommen.
- Rollenspezifische Stellen (Spiegelung von Legacy-Seiteneffekten, kein neues Regelwerk):
  - Manipulator + Nominierung ruft `applyKill(..., "MANIPULATOR_NOMINATED")` (`legacyAdapter.ts:544-553`, gespiegelt aus openPop-Chip).
  - Der Weise erhält `flags.protected` bei Rollenwechsel (`legacyAdapter.ts:572`, wie `game.html:450`, `:646`) und bei `startGame` (`legacyAdapter.ts:667`). Letzteres gibt es in `setup.html` nicht, also **kleine Verhaltensabweichung**; `startGame` wird im UI aber nicht aufgerufen.
  - Nekromant-Marker (`legacyAdapter.ts:347`, `:371`), Werwolf-Schritt-Erkennung (`app/src/screens/GameScreen.tsx:328`).
- Fazit: kein eigenes Regelverhalten im engeren Sinn, Rollenmenge = 72 aus Legacy.

---

## 9. Godot-Kern

`RoleCatalog.ROLES` (`godot/core/rules/role_catalog.gd:50-62`): **genau 11 IDs**, alle entsprechen dem kebab-case-Slug einer ALL_ROLES-Rolle (DR-01):

| ID | Legacy-Name | Fraktion | Wolf | Nachtpriorität | Beleg |
|---|---|---|---|---:|---|
| `dorfbewohner` | Dorfbewohner | village | nein | - | `:51` |
| `werwolf` | Werwolf | wolves | ja | Rudel 20 | `:52` |
| `schutzengel` | Schutzengel | village | nein | 13 | `:53` |
| `waldhexe` | Waldhexe | village | nein | 34 | `:54` |
| `das-orakel` | Das Orakel | village | nein | 46 | `:55` |
| `wolfskind` | Wolfskind | village (verwandelt wolves) | nein | 9 | `:56` |
| `lehrling` | Lehrling | village | nein | 11 | `:57` |
| `manipulator` | Manipulator | solo | nein | - | `:58` |
| `spiegelwolf` | Spiegelwolf | wolves | ja | Rudel | `:59` |
| `trugbilderwolf` | Trugbilderwolf | wolves | ja | Rudel | `:60` |
| `sensentraeger` | Sensenträger | village | nein | Reaktion | `:61` |

- `godot/content/**` enthält nur `i18n/ui.de.po` und `ui.en.po`, **keine Rolleninhalte**. `godot/app` referenziert keine Rollen-IDs.
- **Test-only-IDs:** Keine im Katalog. `test-sensentraeger` existiert nur noch als **absichtlich ungültiger Eingabewert** in Negativtests: `godot/tests/unit/test_trugbilderwolf.gd:123`, `:290`, `godot/tests/unit/test_orakel.gd:291`. Entfernung dokumentiert in `godot/README.md:254` (Umsetzungsentscheidung 13) und `docs/role-migration/02-implemented-roles-audit.md:18`.
- EN-Anzeigename Waldhexe im Godot-Umfeld „Forest Witch" (`godot/core/rules/role_catalog.gd:20`, `godot/README.md:190`) vs. Legacy „Witch of the Woods".

---

## 10. Dokumente und Tools

### 10a. Rollenzahlen in `*.md`

| Behauptung | Stellen | stimmt? |
|---|---|---|
| **72 Rollen** | `CLAUDE.md` (Dateistruktur), `AUDIT.md` (4x), `GRIMMHAIN-ANALYSE-UND-ROADMAP-2026-09-15.md` (5x), `GRIMMHAIN-REVOLUTION-MASTERPLAN.md` (2x, u.a. `:304`), `docs/architecture/tablet-asset-spec.md`, `docs/godot-migration/01-current-system-inventory.md:39`, `:215` u.a., `03-godot-architecture.md` (2x), `06-execution-roadmap.md` (2x), `07-open-questions.md:101` | ja |
| **„75+ Rollen"** | `ROADMAP.md:45`, `ROADMAP.md:153`, `ROADMAP.md:265` | **nein**, einzige Quelle mit mehr als 72; bereits als widersprüchlich markiert in `docs/godot-migration/01-current-system-inventory.md:304` |
| 73 Karten je Sprache (72 + Rückseite) | `docs/godot-migration/01-current-system-inventory.md:235` | ja |
| 17 (Akt I) + 55 übrige = 72 | `docs/godot-migration/07-open-questions.md:99`, `06-execution-roadmap.md:21` | ja |
| 11 Godot-Rollen | `docs/role-migration/02-implemented-roles-audit.md` (mehrfach), `godot/README.md:186-196` | ja |
| 20 bis 30 Rollen für 1.0 | `docs/masterplan/DECISION-LOG.md:21`, `:87`, Masterplan `:238` | Zielwert, keine Bestandszahl |
| 19 Wolfsrollen | `GRIMMHAIN_ANALYSE_2026-06-12.md:29` | ja |
| 50 ORDER-Einträge, 22 ohne Eintrag | `docs/godot-migration/01-current-system-inventory.md:179` | ja |
| Matrix `04`: 72 Rollenzeilen (41 verifiziert, 19 widersprüchlich, 3 unklar, 9 fehlend), Namen und IDs deckungsgleich mit ALL_ROLES | `docs/godot-migration/04-rules-migration-matrix.md` | ja (nachgerechnet) |
| „Etwa 15 Rollen weichen ab" vs. „19 widersprüchlich, 3 unklar" | `01-current-system-inventory.md:310` vs. `07-open-questions.md:11` | interne Unschärfe, Matrix bestätigt 19 + 3 |

Keine Quelle nennt 70, 71, 73 oder 74 Rollen.

### 10b. In Doku genannte Namen außerhalb ALL_ROLES

| Name | Stellen | Einordnung |
|---|---|---|
| Totenrat-Führer | `SPECIAL-ROLE-FLOW-REPORT.md:46`, `:125`, `GRIMMHAIN_ANALYSE_2026-06-12.md:42`, `PLAN.md:44`, `AUDIT.md:135` | Altname von Nekromant; `AUDIT.md:135` (UI keyt auf alten String) ist **veraltet**, `game.html:532` prüft heute `"Nekromant"` |
| Amor, Bärenführer | `GRIMMHAIN_ANALYSE_2026-06-12.md:69`, `AUDIT.md:143`, `:173` | nur als Sound-Dateinamen |
| Blinzelmädchen | `docs/role-migration/02-implemented-roles-audit.md:53` | entfernte Rolle |
| Chronist | `docs/godot-migration/04-rules-migration-matrix.md:122` | dokumentiert den Schlüsselfehler |
| Bürgermeister | `docs/godot-migration/01-current-system-inventory.md:96`, `04-rules-migration-matrix.md:212` | als „existiert nicht" genannt, keine Rolle |
| Hexe | `docs/specs/vertical-slice/*.md` (12x), `07-open-questions.md:37` | Kurzform für Waldhexe |
| Orakel (ohne „Das") | 66 Stellen, z.B. `godot/README.md:67-69` | Kurzform für Das Orakel |
| „Grabrauber" | `docs/godot-migration/01-current-system-inventory.md:290` | nur Feldname `GrabrauberStolenRole` |

### 10c. Tools (weitere Rollenlisten außerhalb der App)

| Datei | Inhalt | Abweichung |
|---|---|---|
| `tools/create_role_doc.py:13ff` | 72 Rollen-Tupel (DE, EN, Tier, Texte) | **`"Busfahrer"` statt „Wahnsinniger Kutscher"** (`tools/create_role_doc.py:83-85`, Beschreibung = Kutscher-Nachbarn-Mechanik): Altname/Alias, sonst deckungsgleich |
| `tools/fix_v42_night_order.py:15ff` | 51 Rollen (50 ORDER + Doppelspion mit „X") | Teilmenge, keine fremden Namen; Ziel ist externe Datei `C:/Users/Marku/Downloads/...` |
| `tools/update_night_order_html.py:68ff` | DE- und EN-Tierlisten | EN-Aliase abweichend von ROLE_NAMES_EN: „Vengeful Wolf", „King Lykaon", „Shadow Wanderer", „Forest Witch", „Card Swallower", „Protective Spirit", „Dream Reader" (neben den offiziellen Namen) |

---

## 11. Totenkarten `js/core/cards.js` (80 Karten, 80 eindeutige IDs; keine davon zählt als Rolle)

Karten, die Rollen tauschen, vergeben, zurückbringen oder eine Rolle namentlich nennen:

| ID | Name | Wirkung auf Rollen | Beleg |
|---|---|---|---|
| `schicksal_08` | Neuer Anfang | zwei lebende Spieler erhalten eine **neue Rolle innerhalb ihrer Fraktion** | `js/core/cards.js:158` |
| `loki_06` | Rollenroulette | **tauscht Rollen** zweier zufälliger lebender Spieler derselben Fraktion | `js/core/cards.js:424-425` |
| `solo_01` | Todesprojektion | Solo übernimmt **Rolle und Fraktion** eines gelynchten Spielers | `js/core/cards.js:480` |
| `solo_06` | Geisterstimme | Wiederbelebung mit **neuer Solo-Rolle** | `js/core/cards.js:510` |
| `wende_11` | Schicksalswende | nennt **König Lykaon** und **Trugbilderwolf**: ein Wolf erhält die Fähigkeit, einen Spieler in einen Trugbilderwolf zu verwandeln | `js/core/cards.js:375` |
| `segen_08` | Zweites Leben | Toter kehrt mit ursprünglicher Rolle zurück | `js/core/cards.js:60-62` |
| `wende_04` | Wiedergeburt | Toter kehrt mit ursprünglicher Fähigkeit zurück | `js/core/cards.js:324-326` |
| `wende_07` | Befreiung | Toter kehrt mit halber Fähigkeit zurück | `js/core/cards.js:346-348` |
| `segen_03`, `fluch_06` | Wachsame Augen, Schwarzes Mal | Rollen werden offenbart (keine Änderung) | `js/core/cards.js:25`, `:241-242` |

Revive-Karten sind über Rollen-Tags an Frankenstein, Kutscher, Lehrling, Wolfskind gekoppelt (`js/core/cards.js:573`, `js/core/roles.js:287-298`). `loki_01` „Spiegelwelt" (`js/core/cards.js:394`) ist trotz Namensähnlichkeit keine Rolle. Keine Karte führt eine Rolle außerhalb ALL_ROLES ein.

---

## 12. Migrationsdokumente

### 12a. Bug-Liste F1 bis F15 (`docs/godot-migration/01-current-system-inventory.md:262-276`)

| F | Betroffene Rolle(n) | Kurzbeschreibung | Fundstelle laut Doku |
|---|---|---|---|
| F1 | Schutzgeist | kann nie handeln, tote Rollen werden vor dem Sonderfall gefiltert | `night:58` vs. `night:91-92` |
| F2 | Wölfe außerhalb `WOLF_KILL_ROLES` (Siegreicher Wolf, Giftwolf, verwandeltes Wolfskind u.a.) | keine Wolfs-Tötungszeile, wenn nur solche Wölfe leben | `night:50-55` |
| F3 | Albtraumwolf | Blockade rettet das Opfer auch vor den Wölfen | `night:334` |
| F4 | Seelentauscher | kann zwei Wölfe erzeugen (veraltetes `flags.werewolf`) | `chunk:782-783` |
| F5 | Lehrling | toter Lehrling erbt trotzdem | `core:389` |
| F6 | alle (manueller Tod) | „tot"-Chip umgeht `applyKill` | `gh:429` |
| F7 | Siegprüfung allgemein | zwei Siegprüfer mit verschiedener Logik, `triggerWin` überschreibt | `core:218-239`, `core:287-337`, `core:85-100` |
| F8 | Prophet des Untergangs (`prophetProgressCheck`), Undo, Phasenanzeige | lesen `window.state` (undefiniert) | `gh:371`, `gh:1874-1875`, `gh:2047`, `gh:2251-2315` |
| F9 | Dr. Victor Frankenstein | Rollen-`select` im React-Dialog nicht bedienbar, Wiederbelebung vor Bestätigung | `chunk:54-103`, `domMirror.ts:57-59` |
| F10 | Der Weise | doppelt geschützt, wenn per Popup gesetzt | `gh:450,646`, `night:145`, `night:359-364` |
| F11 | Detektiv | zeigt wörtlich `{name}` (`t()` statt `tf()`) | `core:77-79`, `js/core/i18n.js:237,566` |
| F12 | Besessener Wolf | i18n-Schlüssel `besessenerWolfDrag` undefiniert | `night:312` |
| F13 | Blutwolf | `showBlutwolfInfo` aufgerufen, nicht definiert | `night:350` |
| F14 | Dämonischer Wolf, Seuchenwolf | `killedTonight` enthält Überlebende | `night:374,394` |
| F15 | Cerberus, Fenrir (Folge: Henker, LynchCount) | Lynchrettung überspringt `finalizeLynch` | `night:448-449` |

Ergänzend nicht in F1-F15, aber hier gefunden: `"Chronist"`-Schlüssel (`js/core/abilities.js:107`), `CARD_MAP_EN` ohne Rachsüchtiger Wolf (`game.html:813-843`, `app/src/roleCard.ts:19-92`).

### 12b. Offene Fragen Q1 bis Q10 (`docs/godot-migration/07-open-questions.md`)

| Q | Zeile | Kurzinhalt | Empfehlung |
|---|---|---|---|
| Q1 | `:9` | Rollentext vs. Legacy-Code bei Widerspruch (19 widersprüchlich, 3 unklar; Tabelle mit 18 Rollen plus Reaktionszeile, Teil 2 Bugliste) | C: pro Rolle entscheiden |
| Q2 | `:49` | Stimmabgabe in der App? (Blutwolf, Hades, Korrupter Richter, ca. 40 Karten) | A im MVP, B in 1.0 |
| Q3 | `:63` | Automatisierungsgrad und Zeitpunkt Totenkarten | A, Ziehung beim Tod |
| Q4 | `:79` | Fehlende Solo-Siege (Prophet, Feuerteufel, Voodoo-Priester, Grabräuber, Die Ewigen, Rachsüchtiger Wolf) und Siegpriorität | B: generischer „Sieg erklären"-Button |
| Q5 | `:95` | Rollenumfang Tablet-MVP (Akt I 17 / Akt I+II ca. 40 / alle 72) | A: Akt I |
| Q6 | `:107` | Sprachen zum MVP | A: nur Deutsch |
| Q7 | `:120` | Zielgeräte | A: Android zuerst |
| Q8 | `:132` | Herkunft/Lizenz der Assets | B: gemischt |
| Q9 | `:148` | Web-App während Migration | B: nur kritische Fehler |
| Q10 | `:160` | Import alter Web-Spielstände | A: kein Import (macht `migrateLegacyRoleIds` für Godot bedeutungslos) |

### 12c. `docs/masterplan/DECISION-LOG.md`: rollenrelevante Entscheidungen

| ID / Abschnitt | Zeile | Kurzinhalt |
|---|---|---|
| Regeln | `:18-21` | Rollen einzeln bewerten; Text und Legacy keine automatische Autorität; Bugs nicht portieren; **1.0 = 20 bis 30 geprüfte Rollen** |
| Offene Punkte | `:87` | finale Auswahl der 20 bis 30 Rollen |
| DR-01 | `:91-93` | Rollen-IDs deutsches ASCII-kebab-case (`das-orakel`) |
| DR-03 | `:95-97` | Nominierungsregeln (relevant für Manipulator, Spiegelwolf) |
| Core-Slice Grundrollen | `:99-101` | 6-24 Personen nur mit dorfbewohner/werwolf, **keine Obergrenze** (Legacy-Grenzen 5/10 verworfen) |
| DR-02 | `:105` | gleichzeitige Siege: SL entscheidet |
| DR-04 | `:106` | Rolle beim Tod aufdecken per Setup-Option |
| DR-05 Schutzengel | `:107` | andere Person je Nacht, nur gegen Wolfsangriff, Auflösung am Morgen |
| DR-06 Waldhexe | `:108` | je 1 Heil- und Gifttrank, beide in einer Nacht erlaubt |
| DR-07 Orakel | `:109` | Sonderwölfe erscheinen als Werwolf, keine Selbstprüfung |
| DR-08 Trugbilderwolf | `:110` | SL wählt gezeigte falsche Rolle |
| DR-09 Sensenträger | `:111` | darf verzichten; Tag sofort, Nacht bei Morgenauflösung |
| DR-10 Wolfskind | `:112` | kein Selbst-Vorbild; Rudel ab Folgenacht |
| DR-11 Lehrling | `:113` | 3 Rollenoptionen, Erbe bei Tod, Wolfskind-Sonderfall |
| DR-12 Manipulator | `:114` | Einzelsieg bei genau drei Lebenden |
| DR-13 Spiegelwolf | `:115` | ohne Nominierung keine Spiegelung |
| DR-14 | `:116` | vorläufiger Siegstatus nach jedem Tod, Reaktionen zuerst |
| Präzisierungen DR-08/DR-11 | `:118-122` | Lehrling-Wirkung, Trugbilderwolf-Scheinrolle (teils ersetzt) |
| Korrekturrunde Regelkern 1-5 | `:124-132` | Trugbilderwolf-Korrektur, Lehrling sofortige Wirkung, Hinrichtung ohne Nominierung, Prompts bei Korrektur |
| Randfälle Rudel/Wiederbelebung 1-3 | `:134-138` | u.a. Sensenträger kein Selbstziel |
| Schutzengel bestätigte Aktionen | `:140-144` | Pflichtauswahl, kein SkipStep |
| Waldhexe Produktionsrolle | `:146-153` | Prompt-Kette, Tränke pro Person |
| Korrekturrunde Waldhexe/Nachtplan 1-4 | `:155-162` | tatsächliche Rolle nach Rettung, Nachtplan-Snapshot |
| Orakel Produktionsrolle | `:164-171` | truth/determined/shown-Modell |
| Trugbilderwolf Produktionsrolle | `:173-179` | Scheinrolle im Setup, `role_entries` |
| Wolfskind Produktionsrolle | `:181-188` | Verwandlung, Priorität 0.9 |
| Spiegelwolf Produktionsrolle | `:190-199` | Hinrichtungsspiegelung einmal pro Person |
| Manipulator und Kandidatenmenge | `:201-206` | `ever_nominated`, Siegkandidaten ohne Priorität |
| Lehrling Produktionsrolle | `:208-219` | verdeckte Auswahl, Erbe, `RoleTransition` |

Keine Entscheidung fügt eine Rolle hinzu, entfernt eine oder ändert die Gesamtzahl; alle betreffen die 11 Godot-Rollen bzw. den 1.0-Zielumfang.

---

## Nachweisbare Rollenzahl

**72.** Begründung:
1. `ALL_ROLES` (`js/core/roles.js:1`) hat 72 eindeutige Namen; alle Rollen-Stammdaten derselben Datei (DE-Texte, EN-Namen, EN-Texte) haben exakt dieselben 72 Schlüssel; Fraktionen 19 + 14 + 39 = 72.
2. Jede unabhängige Nebenquelle bestätigt dieselbe Menge ohne Zusatz: `ROLE_ABILITIES` 72/72, Akte-Vereinigung 72/72, DE-Kartenbilder 72 (+ Rückseite), EN-Kartenbilder 72 (+ Rückseite), Migrationsmatrix `04` 72 Zeilen mit identischen Namen und IDs, `tools/create_role_doc.py` 72 Tupel (eines unter Altnamen).
3. Alle 49 Fähigkeits-Handler, 50 ORDER-Einträge, 19/14 Fraktionslisten, Akt-Listen und Godot-IDs sind Teilmengen der 72. Keine Quelle führt eine 73. aktive Rolle ein.

### Aliase, entfernte Rollen, Duplikate, Tippfehler

| Typ | Name | Stelle | heutige Rolle |
|---|---|---|---|
| entfernte Rolle | Blinzelmädchen | `js/core/state.js:18` | (Dorfbewohner als Ersatz) |
| Altname migriert | Amor, Hexe, Jäger, Seherin, Flötenspieler, Weißer Werwolf, Der Alte, Engel, Bärenführer, Fuchs, Urwolf, Totenrat-Führer | `js/core/state.js:18` | Loki, Waldhexe, Sensenträger, Das Orakel, Rattenfänger, Rachsüchtiger Wolf, Der Weise, Schutzengel, Nachtwächter, Spürhund, König Lykaon, Nekromant |
| Altname nicht migriert | Mogli (nur Feldnamen) | `js/core/state.js:10`, `:57`, `:66` u.a. | Wolfskind |
| Altname nicht migriert | Busfahrer | `tools/create_role_doc.py:83` | Wahnsinniger Kutscher |
| Altname im Code | Totenrat-Führer in SOLO-Fallbacks | `game.html:889`, `:1019` | Nekromant |
| Altname im Code | Urwolf (`usedKey`) | `js/ui/core.js:350` | König Lykaon |
| **Tippfehler / falscher Schlüssel (Bug)** | Chronist | `js/core/abilities.js:107` | Dorfchronistin |
| Altnamen in i18n-Schlüsseln | totenrat*, whiteWolf*, hunter*, witch*, oldDebuff | `js/core/i18n.js` | Nekromant, Rachsüchtiger Wolf, Sensenträger, Waldhexe, Der Weise |
| EN-Alias in Texten | Seer, Witch | `js/core/i18n.js:958`, `:459` | The Oracle, Witch of the Woods |
| EN-Alias in Dateien/Tools | Vengeful Wolf (vs. Lone Wolf), Pack_Father, Doppelspion (EN-Karte), Forest Witch, King Lykaon, Shadow Wanderer, Card Swallower, Protective Spirit, Dream Reader | `assets/cards/en`, `tools/update_night_order_html.py`, `godot/README.md:190` | jeweilige Rolle |
| Altnamen als Assets | Amor.mp3, Bärenführer.mp3 | `assets/sounds/` | Loki, Nachtwächter (unreferenziert) |
| Duplikate | keine in ALL_ROLES; einzige Inhaltsduplikate sind die byte-gleichen Karten Rachsüchtiger_Wolf/Vengeful_Wolf und Hintergrund/Background | `assets/cards/**` | - |
| verwechslungsgefährdet, aber eigenständig | Kutscher / Wahnsinniger Kutscher; König / König Lykaon; Schutzengel / Schutzgeist; Todesprediger („Death Prophet") / Prophet des Untergangs („Prophet of Doom"); Nachtwächter / Dorfwache / Wächter am Tor / Zeitwächter / Verdammniswächter | `js/core/roles.js:1` | je eigene Beschreibung, eigene Karte |

### Behauptet irgendeine Quelle mehr oder weniger als 72?

- **Mehr:** Ja, nur `ROADMAP.md:45`, `:153`, `:265` mit „75+ Rollen". Nicht belegbar; alle Code- und Asset-Quellen ergeben 72.
- **Weniger (als Gesamtbestand):** Keine. Kleinere Zahlen sind ausdrücklich Teilmengen: 71 in `CARD_MAP_EN` (`game.html:813-843`, `app/src/roleCard.ts:19-92`, fehlender Eintrag Rachsüchtiger Wolf, faktisch ein Mapping-Loch), 50 ORDER, 49 Handler, 11 Godot-Rollen, 17-27 je Akt, 20-30 als 1.0-Ziel.
- 73 erscheint nur als Dateizahl je Kartenordner (72 + Rückseite), nicht als Rollenzahl.
