# 11 · Rollenaudit: Prüfstatus aller 72 Rollen

**Stand:** 2026-09-28 · Branch `audit/all-72-roles` (Basis `main` `f09cd08`) · dauerhaft gepflegte Übersicht.
Diese Datei ersetzt keine Nutzerentscheidung. Verbindlich bleiben `docs/masterplan/DECISION-LOG.md` und `docs/specs/vertical-slice/rules-register.md`.

## 0. Übergabe für die nächste Sitzung (Stand 28.09.2026)

- Branch `audit/all-72-roles`, Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-audit-72-roles`, gepusht.
- Letzter vollständiger Lauf: 601 Tests, 0 fehlgeschlagen, keine `SCRIPT ERROR`, Exit 0; `node tools/role-migration/check-role-docs.js` Exit 0. Zusätzlich einmalig 480 Fuzzpartien mit anderen Seeds ohne Invariantenverletzung.
- Prüfhinweis: Der Testrunner zählt einen Test als grün, wenn er nach mindestens einer Prüfung durch einen Laufzeitfehler abbricht. Deshalb ist jede `SCRIPT ERROR`-Zeile im Testlog ein Fehlschlag (so auch `.claude/skills/grimmhain-core/windows-checks.md`).
- Vorgehen je Charge: Fragen per Auswahl-Popup mit zitiertem Rollentext → Decision Log, `decision-status.csv`, `08` → Tests zuerst → Umsetzung → UI-Namen, Reihenfolge, UI-Testlisten → Rollenliste des Fuzztests → Migrationsdokumente (`promote_role.py`, Tabellen-Generator; Scratchpad-Hilfsskripte, bei Bedarf neu schreiben) → Commit und Push.
- Informationsrollen (Traumdeuter, König, Kopfgeldjäger, Kriegerin des Lichts, Blutpriester, Amalia, Detektiv, Die Ewigen) sind entschieden (I-01 bis I-15) und grün.
- Nächste offene Gruppen: Schutz (Der Weise, Märtyrerin, Schutzgeist, Dorfschmied, Verdammniswächter); Bindungen (Loki, Schwarze Witwe, Rotkäppchen, Schattenwanderer); Verwandlung (König Lykaon, Seelentauscher, Dämonischer Wolf); Wiederbelebung (Kutscher, Dr. Victor Frankenstein); Einzelsiege (Rattenfänger, Pestbringerin, Prophet des Untergangs, Feuerteufel, Voodoo-Priester, Nekromant, Kartenschlucker, Hades, Grabräuber, Todesprediger); Zeitwächter; Rachsüchtiger Wolf; Schicksalswolf.
- Offen außerhalb des Kerns: Zufallsknopf nach RM-DR-015.2 (Ziehung über den gespeicherten Seed) ist noch in keiner Rolle umgesetzt; König, Traumdeuter, Kopfgeldjäger und Blutpriester nutzen die Spielleiterwahl.
- Weiter offen außerhalb des Kerns: Analyse unverträglicher Rollenkombinationen (vom PO gewünscht, Setup-Regel vertagt); Tablet-Gegenprüfung „links = Uhrzeigersinn“; Sound bei 5 Toten nur mit Selbstmörder im Spiel.

## 1. Statusdefinition

| Status | Bedeutung |
|---|---|
| **GRÜN** | Verbindliche Regel eindeutig (Decision Log, Regelregister oder widerspruchsfreier Rollentext ohne offene Frage), im Godot-Regelkern umgesetzt, aussagekräftige headless Tests bestehen, relevante Wechselwirkungen geprüft (§4). Gilt nur für den Regelkern, nicht für Oberfläche, vollständige Runde oder Tablet. |
| **OFFEN** | Regel eindeutig, aber noch nicht oder nicht vollständig umgesetzt oder geprüft. |
| **BLOCKIERT** | Mindestens eine Regelfrage ist nicht vom Product Owner entschieden. Nicht umgesetzt; es wird kein Default erfunden. |

Ein Legacy-Befund (`legacy-verified` usw.) ist **kein** Godot-Nachweis. Rollentext und Legacy-Code sind keine automatische Autorität (Decision Log „Regeln“).

## 2. Zählung

<!-- check:audit-counts total=72 green=45 open=0 blocked=27 -->

| | Anzahl |
|---|---:|
| Rollen (`ALL_ROLES` in `js/core/roles.js`, 72 eindeutige IDs) | 72 |
| **GRÜN** | **45** |
| **OFFEN** | **0** |
| **BLOCKIERT** | **27** |

72/72 ist **nicht** erreicht. Die 27 blockierten Rollen warten auf Produktentscheidungen (Spalte „Offene Fragen“, Details in [`08-decision-request.md`](08-decision-request.md) und [`decision-status.csv`](decision-status.csv)); die als Nächstes nötigen Fragen stehen in §6.

## 3. Übersicht

Spalten: Regelquelle; entschiedene Mechanik; offene Fragen (nur nicht entschiedene `RM-DR`-Einträge; `RM-DR-001` ist entschieden); Godot = Regelkern; Tests = Nachweise unter `godot/tests/unit/`; Interaktionen = geprüfte Wechselwirkungen (grün) bzw. Abhängigkeiten laut Analyse (blockiert). Die Tabelle wurde aus [`01`](01-canonical-role-catalog.md) (IDs, Namen, Fraktion, Legacy-Befund), [`03`](03-remaining-roles-analysis.md) und [`decision-status.csv`](decision-status.csv) (offene Fragen) erzeugt und für die grünen Rollen von Hand ergänzt.

| # | ID | DE / EN | Fraktion | Regelquelle | Entschiedene Mechanik | Offene Fragen | Godot | Tests | Interaktionen | Status |
|---:|---|---|---|---|---|---|---|---|---|---|
| 1 | `loki` | Loki / Loki | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-101.1, RM-DR-009 | fehlt | – | [03](03-remaining-roles-analysis.md#loki) | **BLOCKIERT** |
| 2 | `nachtwaechter` | Nachtwächter / Night Warden | Dorf | Rollentext; RM-DR-003, 102.1 (Decision Log) | jeden Morgen öffentliche Glocken, wenn ein nächster lebender Nachbar nicht zum Dorf gehört | – | umgesetzt | test_seat_roles, fuzz | Wölfe, Einzelsieg, tote Plätze; Dämonischer Wolf folgt | **GRÜN** |
| 3 | `die-gebundenen` | Die Gebundenen / The Bound | Dorf | Rollentext; RM-DR-014 = B, F-08 (Decision Log „Rollenaudit“) | nur Nacht 1, gemeinsamer Schritt; jede lebende Gebundene erfährt die anderen lebenden | – | umgesetzt | test_die_gebundenen (8), fuzz | Chronistin, Wolfskind, Tod vor dem Schritt, 24 Personen, Schattenhund-Blockade (Regressionstest) | **GRÜN** |
| 4 | `waldhexe` | Waldhexe / Witch of the Woods | Dorf | DR-06, Einträge Waldhexe und Korrekturrunde | atomare Kette, je 1 Heil-/Gifttrank pro Person, Gift sofort, Rettung nur aktuelles Rudelopfer | – | umgesetzt | test_waldhexe (43), test_role_interactions, fuzz | Schutzengel, Sensenträger, Wolfskind, Lehrling, Trugbilderwolf | **GRÜN** |
| 5 | `rattenfaenger` | Rattenfänger / Pied Piper | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-broken` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-103.1, RM-DR-103.2 | fehlt | – | [03](03-remaining-roles-analysis.md#rattenfaenger) | **BLOCKIERT** |
| 6 | `sensentraeger` | Sensenträger / Reaper | Dorf | DR-09, Randfälle 26.09. | freiwillige Reaktion, Tag sofort, Nacht am Morgen, kein Selbstziel, einmal pro Person | – | umgesetzt | test_sensentraeger (21), test_reactions, test_role_interactions (Kette mit Erbe), fuzz | Lehrling, Wolfskind, Spiegelwolf, Schutz, DR-14 | **GRÜN** |
| 7 | `wolfskind` | Wolfskind / Wolf Child | Dorf | DR-10, Eintrag Wolfskind | Vorbildwahl 0.9, Verwandlung als Todesfolge vor Siegprüfung, Rudel ab Folgenacht | – | umgesetzt | test_wolfskind (24), test_role_interactions, fuzz | Lehrling, Spiegelwolf, Manipulator, Waldhexe, Sensenträger | **GRÜN** |
| 8 | `das-orakel` | Das Orakel / The Oracle | Dorf | DR-07, Eintrag Orakel | Pflichtschritt 4.6, Informationsmodell Wahrheit/ermittelt/gezeigt, Übersteuerung nur gezeigt | – | umgesetzt | test_orakel (28), fuzz | Trugbilderwolf, Wolfskind, Sonderwölfe, Lehrling | **GRÜN** |
| 9 | `die-ewigen` | Die Ewigen / The Eternal Ones | Dorf | Rollentext; RM-DR-104, I-11, I-12, I-15 (Decision Log „Rollenaudit · Informationsrollen“) | jede Nacht gemeinsamer Schritt, eine Person außerhalb der Ewigen: Einzelsieg ja/nein; Mitsieg aller Ewigen mit einer mit Ja geprüften Person | – | umgesetzt | test_info_roles, fuzz | Manipulator (Mitsieg), Schattenhund-Blockade; Doppelspion/Selbstmörder/Parasit über dieselbe Mitsiegregel (Fuzz, Ladeprüfung) | **GRÜN** |
| 10 | `spuerhund` | Spürhund / Scent Hound | Dorf | Rollentext, vom PO präzisiert; RM-DR-105.1 (Decision Log) | jede Nacht freiwillig 3 andere; ✓ bei Wolf/Solo, ✗ kostet die Fähigkeit (Aufruf bleibt) | – | umgesetzt | test_spuerhund_parasit, fuzz | Trugbilderwolf, Manipulator, Wiederbelebung; Dämonischer Wolf folgt | **GRÜN** |
| 11 | `schutzengel` | Schutzengel / Guardian Angel | Dorf | DR-05, Eintrag Schutzengel | Pflichtschritt 1.3, andere lebende Person, nur gegen Rudelangriff dieser Nacht, bleibt nach eigenem Tod | – | umgesetzt | test_schutzengel (29), test_role_interactions (Gift trotz Schutz), fuzz | Waldhexe, Sensenträger, Spiegelwolf, Wolfskind | **GRÜN** |
| 12 | `werwolf` | Werwolf / Werewolf | Wölfe | Register §2, G-PH-6 | Rudelschritt 2.0 solange ein Wolf lebt; Opfer jede lebende Person; überspringbar mit Grund; entfällt ohne lebenden Wolf (Audit-Fix) | – | umgesetzt | test_steps, test_replay, test_save_load, test_role_interactions (Rudel ohne Wolf), fuzz | Schutz, Rettung, Gift, Reaktion, Verwandlung, Erbe | **GRÜN** |
| 13 | `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | Wölfe | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-106.1, RM-DR-106.2, RM-DR-106.3, RM-DR-002 | fehlt | – | [03](03-remaining-roles-analysis.md#rachsuechtiger-wolf) | **BLOCKIERT** |
| 14 | `koenig-lykaon` | König Lykaon / King Lycaon | Wölfe | Rollentext `js/core/roles.js`; Legacy `legacy-verified` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-107.1, RM-DR-107.2, RM-DR-002 | fehlt | – | [03](03-remaining-roles-analysis.md#koenig-lykaon) | **BLOCKIERT** |
| 15 | `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | Wölfe | Rollentext DE/EN = Legacy-Code; Auslegung 10-next-decisions „Zur Kenntnis“ | zählt lebend in der Wolfsparität doppelt; nicht bei „kein Wolf lebt“ und nicht bei Personenzählungen | – | umgesetzt | test_siegreicher_wolf (10), fuzz | Lehrling, Manipulator, Orakel, Wiederbelebung, Rollenkorrektur | **GRÜN** |
| 16 | `seuchenwolf` | Seuchenwolf / Blight Wolf | Wölfe | Rollentext; RM-DR-108 (Decision Log) | nach seinem Tod durchdringt der nächste tatsächliche Rudelangriff Schutz | – | umgesetzt | test_wolf_specials, fuzz | Schutzengel, Dorfwache, Waldhexe | **GRÜN** |
| 17 | `schicksalswolf` | Schicksalswolf / Fate Wolf | Wölfe | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-109.1, RM-DR-109.2, RM-DR-109.3 | fehlt | – | [03](03-remaining-roles-analysis.md#schicksalswolf) | **BLOCKIERT** |
| 18 | `schattenwanderer` | Schattenwanderer / Shadowwalker | Wölfe | Rollentext `js/core/roles.js`; Legacy `legacy-verified` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-110.1, RM-DR-110.2, RM-DR-009 | fehlt | – | [03](03-remaining-roles-analysis.md#schattenwanderer) | **BLOCKIERT** |
| 19 | `giftwolf` | Giftwolf / Poison Wolf | Wölfe | Rollentext; RM-DR-111 (Decision Log) | zwei Giftpranken je Leben, eine pro Nacht; Tod nach N+2, sofortiger privater Hinweis, unaufhaltbar | – | umgesetzt | test_wolf_specials, fuzz | Schutzengel, früherer Tod, Parasit, Rudelvater | **GRÜN** |
| 20 | `rudelvater` | Rudelvater / Packfather | Wölfe | Rollentext; RM-DR-112 (Decision Log) | überlebt einmal Nicht-Rudel/Nicht-Lynch; nach Lynch zweiter, durchdringender Rudelschritt | – | umgesetzt | test_wolf_specials, fuzz | Waldhexe, Schutzengel, Dorfwache, Korrektur | **GRÜN** |
| 21 | `schwarze-witwe` | Schwarze Witwe / Black Widow | Wölfe | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-113.1, RM-DR-113.2 | fehlt | – | [03](03-remaining-roles-analysis.md#schwarze-witwe) | **BLOCKIERT** |
| 22 | `der-weise` | Der Weise / The Elder | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-broken` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-114.1, RM-DR-114.2, RM-DR-114.3, RM-DR-114.4, RM-DR-002 | fehlt | – | [03](03-remaining-roles-analysis.md#der-weise) | **BLOCKIERT** |
| 23 | `verdammniswaechter` | Verdammniswächter / Doom Warden | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-115.1, RM-DR-115.2, RM-DR-115.3, RM-DR-002 | fehlt | – | [03](03-remaining-roles-analysis.md#verdammniswaechter) | **BLOCKIERT** |
| 24 | `lehrling` | Lehrling / Apprentice | Dorf | DR-11, Präzisierung, Korrekturrunde 2/3, Eintrag Lehrling | verdeckte Wahl aus 3 Rollen, Erbe sofort mit frischen Einsätzen, aktive Fähigkeit ab Folgenacht | – | umgesetzt | test_lehrling (23), test_role_interactions, test_siegreicher_wolf, fuzz | jede Katalogrolle als Erbe | **GRÜN** |
| 25 | `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | Dorf | Rollentext; RM-DR-003, 116.1 (Decision Log) | bei Lynch sterben die nächsten lebenden Nachbarn (COACHMAN_CRASH); nicht bei Spiegelung | – | umgesetzt | test_seat_roles, fuzz | Spiegelwolf, Sensenträger, Sitzfolge, Spielleiter-Hinrichtung; Schilde folgen | **GRÜN** |
| 26 | `korrupter-richter` | Korrupter Richter / Corrupt Judge | Dorf | Rollentext; RM-DR-117, RM-DR-012 (Decision Log) | nachts freiwillig markieren (auch selbst); Tagesbeginn: verdeckte Nominierung durch ihn; +1 als Hinweis | – | umgesetzt | test_richter_waechter_blutwolf, fuzz | Manipulator, Spiegelwolf, Nominierungslimits | **GRÜN** |
| 27 | `maertyrerin` | Märtyrerin / Martyr | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-118.1, RM-DR-118.2, RM-DR-118.3 | fehlt | – | [03](03-remaining-roles-analysis.md#maertyrerin) | **BLOCKIERT** |
| 28 | `dorfwache` | Dorfwache / Village Guard | Dorf | Rollentext (widerspruchsfrei mit Legacy) | Rudelangriff tötet sie nicht; sonst normal | – | umgesetzt | test_seat_roles, fuzz | Schutzengel, Waldhexe, Lehrling; RM-DR-119 folgt mit Giftwolf/Seuchenwolf/Rudelvater | **GRÜN** |
| 29 | `pestbringerin` | Pestbringerin / Plague Bringer | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-120.1, RM-DR-120.2, RM-DR-120.3, RM-DR-120.4 | fehlt | – | [03](03-remaining-roles-analysis.md#pestbringerin) | **BLOCKIERT** |
| 30 | `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `not-found` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-121.1, RM-DR-121.2, RM-DR-121.3 | fehlt | – | [03](03-remaining-roles-analysis.md#prophet-des-untergangs) | **BLOCKIERT** |
| 31 | `spiegelwolf` | Spiegelwolf / Mirror Wolf | Wölfe | DR-13, Eintrag Spiegelwolf | erste Hinrichtung auf Nominierende umgelenkt, einmal pro Person | – | umgesetzt | test_spiegelwolf (20), test_role_interactions, fuzz | Wolfskind, Lehrling, Sensenträger, Schutz | **GRÜN** |
| 32 | `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | Wölfe | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-122.1, RM-DR-122.2, RM-DR-122.3, RM-DR-002, RM-DR-009 | fehlt | – | [03](03-remaining-roles-analysis.md#daemonischer-wolf) | **BLOCKIERT** |
| 33 | `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Wölfe | DR-08, Korrekturrunde 1, Eintrag Trugbilderwolf | Scheinrolle im Setup je Instanz, nie Wolfsrolle, Korrektur nur bestätigt | – | umgesetzt | test_trugbilderwolf (23), test_gm_role_field, fuzz | Orakel, Waldhexe, Lehrling | **GRÜN** |
| 34 | `schattenhund` | Schattenhund / Shadow Hound | Wölfe | Rollentext; RM-DR-123, RM-DR-010 (Decision Log) | einmal je Leben alle Dorf-Nachtschritte einer Nacht blockieren; handelt zuerst | – | umgesetzt | test_wolf_specials, fuzz | Schutzengel, Orakel, Waldläufer, Gebundene | **GRÜN** |
| 35 | `besessener-wolf` | Besessener Wolf / Possessed Wolf | Wölfe | Rollentext; RM-DR-124.1 (Decision Log „Rollenaudit · Wiederbelebung …“) | Mitnahme als Reaktion bei mindestens 5 Lebenden inkl. ihm; Verzicht möglich; einmal je Leben | – | umgesetzt | test_ritter_besessener_faehrtenleser, fuzz | Lynch, Rudel, Wiederbelebung, Parität; Schilde folgen | **GRÜN** |
| 36 | `fenrir` | Fenrir / Fenrir | Wölfe | Rollentext; RM-DR-125 (Decision Log) | Stufe je überlebter Nacht; ab 3 überlebt er einmal jeden Tod außer Korrektur | – | umgesetzt | test_fenrir_cerberus_henker, fuzz | Lynch, Ritter, Wiederbelebung | **GRÜN** |
| 37 | `kutscher` | Kutscher / Coachman | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-126.1, RM-DR-126.2, RM-DR-013 | fehlt | – | [03](03-remaining-roles-analysis.md#kutscher) | **BLOCKIERT** |
| 38 | `seelentauscher` | Seelentauscher / Soul Swapper | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-broken` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-127.1, RM-DR-127.2, RM-DR-127.3 | fehlt | – | [03](03-remaining-roles-analysis.md#seelentauscher) | **BLOCKIERT** |
| 39 | `blutpriester` | Blutpriester / Blood Priest | Dorf | Rollentext; RM-DR-128, I-08, I-13 (Decision Log „Rollenaudit · Informationsrollen“) | einmal je Leben: andere Lebende opfern (Tod am Morgen, wacht nicht mehr auf), Spielleiter nennt ihm 0–3 lebende Wölfe | – | umgesetzt | test_info_roles, fuzz | Schutzengel (wirkungslos), Rudelvater (überlebt), zweiter Blutpriester (Markierung) | **GRÜN** |
| 40 | `traumdeuter` | Traumdeuter / Dreamer | Dorf | Rollentext; RM-DR-129, I-01, I-02, I-05 (Decision Log „Rollenaudit · Informationsrollen“) | jede Nacht drei andere Lebende vom Spielleiter, Freigabe ab einem Wolf; Anzeige „mindestens ein Wolf“ | – | umgesetzt | test_info_roles, fuzz | Trugbilderwolf (wahre Wolfszählung); Dämonischer Wolf folgt | **GRÜN** |
| 41 | `henker` | Henker / Executioner | Dorf | Rollentext; RM-DR-130, RM-DR-138.2 (Decision Log) | ab 3 Hinrichtungen nachts markieren; Zusatztod bei der Hinrichtung des Folgetags | – | umgesetzt | test_fenrir_cerberus_henker, fuzz | Selbstmörder, Cerberus, Spiegelwolf | **GRÜN** |
| 42 | `feuerteufel` | Feuerteufel / Pyromaniac | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-broken` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-131.1, RM-DR-131.2, RM-DR-131.3, RM-DR-131.4, RM-DR-131.5, RM-DR-009 | fehlt | – | [03](03-remaining-roles-analysis.md#feuerteufel) | **BLOCKIERT** |
| 43 | `voodoo-priester` | Voodoo-Priester / Voodoo Priest | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-132.1, RM-DR-132.2, RM-DR-132.3, RM-DR-132.4 | fehlt | – | [03](03-remaining-roles-analysis.md#voodoo-priester) | **BLOCKIERT** |
| 44 | `blutwolf` | Blutwolf / Blood Wolf | Wölfe | Rollentext; RM-DR-133.1, RM-DR-008 (Decision Log) | Wolf im Rudel; Stimmbonus nur als Hinweis (+1 je direkt toten Nachbarplatz) | – | umgesetzt | test_richter_waechter_blutwolf, fuzz | Wiederbelebung, Sitzkreis; Anzeige folgt mit UI | **GRÜN** |
| 45 | `albtraumwolf` | Albtraumwolf / Nightmare Wolf | Wölfe | Rollentext; RM-DR-134, RM-DR-010 (Decision Log) | jede Nacht freiwillig eine Person blockieren; handelt zuerst | – | umgesetzt | test_wolf_specials, fuzz | Orakel, Gebundene, Dorf-Nachtschritte | **GRÜN** |
| 46 | `cerberus` | Cerberus / Cerberus | Wölfe | Rollentext; RM-DR-135 (Decision Log) | Köpfe je Nacht (max 3); bei 3 Hinrichtung mit Spielleiterfrage abwehrbar | – | umgesetzt | test_fenrir_cerberus_henker, fuzz | Henker-Zählung, Spielleiter-Hinrichtung | **GRÜN** |
| 47 | `ritter` | Ritter / Knight | Dorf | Rollentext; RM-DR-136.1 (Decision Log) | bei Tod durch Wolfsangriff stirbt der nächste Wolf (tote Plätze zählen); Gleichstand: Spielleiter wählt; einmal je Leben | – | umgesetzt | test_ritter_besessener_faehrtenleser, fuzz | Rudel, Gift, Lynch, Wiederbelebung; Verfluchte/Fenrir folgen | **GRÜN** |
| 48 | `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-137.1, RM-DR-137.2, RM-DR-137.3, RM-DR-137.4, RM-DR-137.5, RM-DR-009 | fehlt | – | [03](03-remaining-roles-analysis.md#rotkaeppchen) | **BLOCKIERT** |
| 49 | `selbstmoerder` | Selbstmörder / Death Seeker | Einzelsieg | Rollentext; RM-DR-138.1/.3/.4/.5, F-11 (Decision Log „Rollenaudit“) | Sieg erfüllt, wenn er bei mindestens 5 aktuell Toten hingerichtet wird (LYNCH, auch Spielleiter); wird danach immer wieder vorgeschlagen, auch nach Wiederbelebung | – | umgesetzt | test_selbstmoerder (13), fuzz | Spiegelwolf, Lehrling, Wiederbelebung, Dorfsieg, Kandidatenmenge; RM-DR-138.2 folgt mit Henker | **GRÜN** |
| 50 | `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter | Dorf | Rollentext; RM-DR-139, I-02, I-04, I-06 (Decision Log „Rollenaudit · Informationsrollen“) | je Lynch-Tod einer Wolfsperson eine Liste wie beim Traumdeuter; Verfall mit Hinweis ohne genug Ziele | – | umgesetzt | test_info_roles, fuzz | Albtraumwolf (Guthaben bleibt), Korrektur-Tod, Spiegelung/Cerberus (kein Lynch-Tod eines Wolfs), Rollenwechsel | **GRÜN** |
| 51 | `koenig` | König / King | Dorf | Rollentext; RM-DR-140, I-03 (Decision Log „Rollenaudit · Informationsrollen“) | einmal je Leben, sobald strikt mehr Tote als Lebende: eine andere lebende Dorfperson mit wahrer Rolle (Spielleiter wählt) | – | umgesetzt | test_info_roles, fuzz | Wiederbelebung, Trugbilderwolf/verwandeltes Wolfskind (nicht Dorf) | **GRÜN** |
| 52 | `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-broken` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-141.1, RM-DR-141.2, RM-DR-141.4, RM-DR-013 | fehlt | – | [03](03-remaining-roles-analysis.md#dr-victor-frankenstein) | **BLOCKIERT** |
| 53 | `nekromant` | Nekromant / Necromancer | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-142.1, RM-DR-142.2, RM-DR-142.3, RM-DR-142.4, RM-DR-142.5, RM-DR-002 | fehlt | – | [03](03-remaining-roles-analysis.md#nekromant) | **BLOCKIERT** |
| 54 | `kartenschlucker` | Kartenschlucker / The Collector | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-143.1, RM-DR-143.2, RM-DR-013 | fehlt | – | [03](03-remaining-roles-analysis.md#kartenschlucker) | **BLOCKIERT** |
| 55 | `hades` | Hades / Hades | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-verified` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-144.1, RM-DR-144.2, RM-DR-144.3 | fehlt | – | [03](03-remaining-roles-analysis.md#hades) | **BLOCKIERT** |
| 56 | `doktor` | Doktor / Doctor | Dorf | Rollentext; RM-DR-145.1 = B, 145.2 (Decision Log) | jede Nacht zwei andere Lebende; gleiche aktuelle Fraktion; Solo+Solo gleich; Trugbild wahre Fraktion | – | umgesetzt | test_waldlaeufer_doktor, fuzz | Trugbilderwolf, Wolfskind, Manipulator, Doppelspion; Dämonischer Wolf/Seelentauscher folgen | **GRÜN** |
| 57 | `faehrtenleser` | Fährtenleser / Tracker | Dorf | Rollentext; RM-DR-146.1/.2 (Decision Log) | jede Nacht Nutzungsfrage bis zur Nutzung; Richtung links (Uhrzeigersinn)/rechts/gleich weit | – | umgesetzt | test_ritter_besessener_faehrtenleser, fuzz | tote Plätze, Wiederbelebung; Tablet-Gegenprüfung der Richtung offen | **GRÜN** |
| 58 | `waldlaeufer` | Waldläufer / Ranger | Dorf | Rollentext; RM-DR-147.1/.2 (Decision Log „Rollenaudit · Waldläufer …“) | jede Nacht; Personen, die leben und als Wolf zählen, je einmal | – | umgesetzt | test_waldlaeufer_doktor, fuzz | Siegreicher Wolf, Wolfskind, Gift-Markierung; Dämonischer Wolf folgt | **GRÜN** |
| 59 | `schutzgeist` | Schutzgeist / Guardian Spirit | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-broken` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-148.1, RM-DR-148.2, RM-DR-148.3, RM-DR-148.4, RM-DR-002, RM-DR-009 | fehlt | – | [03](03-remaining-roles-analysis.md#schutzgeist) | **BLOCKIERT** |
| 60 | `dorfchronistin` | Dorfchronistin / Village Chronicler | Dorf | Rollentext; RM-DR-014 = B, F-09 (Decision Log „Rollenaudit“) | nur Nacht 1; Anzahl Personen mit Einzelsiegrolle, lebend und tot; jede Chronistin für sich | – | umgesetzt | test_dorfchronistin (8), fuzz | Manipulator, Doppelspion, Selbstmörder, Rollenkorrektur, Lehrling; Blockaden folgen | **GRÜN** |
| 61 | `waechter-am-tor` | Wächter am Tor / Gatewarden | Dorf | Rollentext; RM-DR-149 (Decision Log) | blockiert neue Wölfe (Wolfskind, Lehrling-Erbe) solange er lebt; Person wird Dorfbewohner, private Mitteilung | – | umgesetzt | test_richter_waechter_blutwolf, fuzz | Wolfskind, Lehrling, Korrekturen; Lykaon/Seelentauscher folgen | **GRÜN** |
| 62 | `zeitwaechter` | Zeitwächter / Time Warden | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-contradictory` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-150.1, RM-DR-150.2, RM-DR-150.3, RM-DR-150.4 | fehlt | – | [03](03-remaining-roles-analysis.md#zeitwaechter) | **BLOCKIERT** |
| 63 | `amalia` | Amalia / Amalia | Dorf | Rollentext; RM-DR-151, I-09 (Decision Log „Rollenaudit · Informationsrollen“) | Tagesaktion bei mindestens 3 lebenden Wölfen: öffentliche Ja/Nein-Antwort des Spielleiters, sie stirbt sofort | – | umgesetzt | test_info_roles, fuzz | Tod mit Folgen (Lehrling, Siegprüfung) über die KillPipeline | **GRÜN** |
| 64 | `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light | Dorf | Rollentext; RM-DR-152, I-07 (Decision Log „Rollenaudit · Informationsrollen“) | einmal je Leben andere Lebende prüfen, Ergebnis nur an sie; kein Wolf: sie stirbt am Morgen | – | umgesetzt | test_info_roles, fuzz | Todesmarkierung, Blockaden | **GRÜN** |
| 65 | `detektiv` | Detektiv / Detective | Dorf | Rollentext; RM-DR-153, I-10, I-14 (Decision Log „Rollenaudit · Informationsrollen“) | Wolfstod bei lebendem Detektiv und mindestens einem anderen Wolf: öffentlich Richtung vom Platz des Toten zum nächsten Wolf; nachts am Morgen | – | umgesetzt | test_info_roles, fuzz | Wolfskind (zählt nach Verwandlung), mehrere Detektive, Korrektur ohne Folgen; Ritter-Kette über Fuzz | **GRÜN** |
| 66 | `dorfschmied` | Dorfschmied / Village Blacksmith | Dorf | Rollentext `js/core/roles.js`; Legacy `legacy-verified` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-154.1, RM-DR-154.2, RM-DR-154.3, RM-DR-002 | fehlt | – | [03](03-remaining-roles-analysis.md#dorfschmied) | **BLOCKIERT** |
| 67 | `manipulator` | Manipulator / Manipulator | Einzelsieg | DR-12, Eintrag Manipulator | stirbt bei Nominierung, gewinnt bei genau 3 Lebenden ohne je nominiert | – | umgesetzt | test_manipulator (18), test_role_interactions, test_siegreicher_wolf, fuzz | Wolfskind, Lehrling, Siegreicher Wolf, Kandidatenmenge | **GRÜN** |
| 68 | `doppelspion` | Doppelspion / Double Agent | Einzelsieg | Rollentext; RM-DR-155.1–.5 (Decision Log „Rollenaudit“) | gewinnt allein, wenn er lebt und kein Wolf lebt; dann kein Dorfkandidat; Parität Nicht-Wolf; Rudel-Aufwachen nur Ansage | – | umgesetzt | test_doppelspion (11), fuzz | Manipulator, Lehrling, Orakel, Dorfsieg, Wiederbelebung; Rachsüchtiger Wolf folgt | **GRÜN** |
| 69 | `grabraeuber` | Grabräuber / Grave Robber | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `not-found` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-156.1, RM-DR-156.2 | fehlt | – | [03](03-remaining-roles-analysis.md#grabraeuber) | **BLOCKIERT** |
| 70 | `parasit` | Parasit / Parasite | Einzelsieg | Rollentext; RM-DR-157.1, RM-DR-011.2 (Decision Log) | Wirt wählbar; mit lebendem Wirt unverwundbar (außer Korrektur); stirbt mit dem Wirt; Sieg bei ≤3 Lebenden | – | umgesetzt | test_spuerhund_parasit, fuzz | Rudel, Lynch, Gift, Korrekturen, Kandidatenmenge | **GRÜN** |
| 71 | `todesprediger` | Todesprediger / Death Prophet | Einzelsieg | Rollentext `js/core/roles.js`; Legacy `legacy-broken` | nur Rahmenregeln (G-ID-3, DR-02, DR-14) | RM-DR-158.1, RM-DR-158.2, RM-DR-158.3 | fehlt | – | [03](03-remaining-roles-analysis.md#todesprediger) | **BLOCKIERT** |
| 72 | `dorfbewohner` | Dorfbewohner / Villager | Dorf | Register §1; Core-Slice Rollenanzahl | keine Fähigkeit, keine Obergrenze | – | umgesetzt | test_player_count_range, Szenarien as-c01–c04, test_role_interaction_fuzz | Parität, alle Siege | **GRÜN** |

## 4. Prüfung der Godot-Rollen und Wechselwirkungen

### 4.1 Ergebnis

- Ausgangslage `main` `f09cd08`: 456 Tests grün (Windows, Godot 4.7.2 Console, `--headless`).
- **Gefundener Fehler (behoben):** Der Rudelschritt entfiel nie, auch wenn während der Nacht der letzte Wolf starb (heute nur per Spielleiterkorrektur erreichbar, später auch durch Nachttötungen vor Priorität 2.0). G-PH-6 verlangt: kein Rudelschritt ohne lebende Person, die als Wolf zählt. Roter Test `test_role_interactions::test_pack_step_dropped_when_last_wolf_died_during_night`; Ursache `StepQueue.drop_reason` prüfte das Rudel nicht; Fix: der Schritt entfällt protokolliert mit Grund `no_living_wolf`.
- **Neu umgesetzt:** `siegreicher-wolf` (Paritätsgewicht 2, `RoleCatalog.parity_weight`, `WinRules.evaluate`). `reason_args.wolves` ist der Paritätswert; die Dorfbedingung zählt weiter lebende Wolfspersonen.
- **Gefundener Fehler (Informationsrollen, behoben):** Der gemeinsame Schritt der Gebundenen wurde vom Schattenhund nie blockiert, weil `StepQueue.drop_reason` vor der Blockadeprüfung zurückkehrte (unerreichbarer Code). RM-DR-010 verlangt die Blockade aller aktiven Dorf-Nachtschritte. Regressionstest `test_info_roles::test_shadow_hound_blocks_shared_village_steps`; Fix: Blockade vor dem Rückgabewert prüfen (gilt auch für den neuen Schritt der Ewigen).
- **Prüflücke im Testrunner (nicht behoben, dokumentiert):** Ein Laufzeitfehler nach mindestens einer Prüfung beendet den Test ohne Fehlschlag. Aufgefallen, als drei neue Tests vor der Umsetzung scheinbar grün liefen. Die Windows-Prüfanleitung wertet `SCRIPT ERROR` bereits als Fehler; der Exit-Code des Runners allein reicht nicht.
- Keine weiteren Abweichungen gefunden. Das ist kein Beweis vollständiger Fehlerfreiheit.

### 4.2 Geprüfte Wechselwirkungen

| Bereich | Nachweis |
|---|---|
| Alle Katalogrollen gemischt, 6–24 Personen, Mehrfachkopien, Abbruch offener Prompts, Überspringen, Nominierung, Hinrichtung, Spielleitertötung mit/ohne Folgen, Wiederbelebung, Siegbestätigung und -ablehnung, zufällige Spielleiterkorrekturen aller Arten (auch Rollenwechsel mitten in der Nacht) | `test_role_interaction_fuzz` (120 feste Zufallspartien; abgelehnte Zufallskorrekturen müssen Zustand und Ereignisse unverändert lassen, A-13; einmalig zusätzlich 4 × 120 Partien mit anderen Seeds ohne Invariantenverletzung). Invarianten nach jedem Befehl: verlustfreies Laden inklusive aller Ladeprüfungen; Save/Load über `StateCodec` alle 20 Befehle und am Ende; Replay bytegleich; keine Rollen-, Ursachen- oder Informationsfelder in öffentlichen Ereignissen; persönliche Schritte nur für lebende Rolleninhaber; kein doppelter Tod; Rollenfelder passend. Abdeckungsnachweis: jede Todesursache und jede relevante Ereignisart kommt vor. Gegenprobe: ein absichtlich eingebauter Rollenwechselfehler wird erkannt. |
| Ein Tod mit Wolfskind-Verwandlung, Lehrling-Erbe und Reaktion des Meisters; geerbte Reaktion sofort; Kandidat erst nach der Kette | `test_role_interactions::test_one_death_transforms_inherits_and_reacts_in_order` |
| Spiegelung trifft die nominierende Person mit Wolfskind und Lehrling; Wolfskind des Spiegelwolfs bleibt unverwandelt | `test_role_interactions::test_mirror_death_triggers_child_and_apprentice_of_nominator_only` |
| Nominierter Manipulator vererbt die Rolle ohne Nominierungsstatus; der Erbe gewinnt bei drei Lebenden | `test_role_interactions::test_nominated_manipulator_passes_role_to_unnominated_apprentice` |
| Schutz, Rudel und Gift auf dasselbe Vorbild: genau ein Tod (Gift), Verwandlung in der Nacht, Rudelangriff ignoriert | `test_role_interactions::test_protected_model_poisoned_transforms_once_at_night` |
| 24 Personen, alle Nachtrollen doppelt: Nachtplan nach Priorität und Personen-ID, Nacht 2 ohne erledigte Auswahlschritte, Save/Load nach jedem Befehl | `test_role_interactions::test_24_players_multiple_copies_night_plan_and_save_load` |
| Siegreicher Wolf mit Lehrling, Manipulator, Orakel, Wiederbelebung, Rollenkorrektur, Kopien | `test_siegreicher_wolf` |
| Informationsrollen mit Albtraumwolf, Schattenhund, Schutzengel, Rudelvater, Trugbilderwolf, Wolfskind, Wiederbelebung, Todesmarkierung und Mitsieg (Manipulator) | `test_info_roles` (21); Fuzz-Pflichtabdeckung aller neuen Ereignisse und Todesursachen |
| Einzelrollen und Paare aus dem Vertical Slice | bestehende Rollentests, siehe `godot/README.md` (Testtabelle) und [`02`](02-implemented-roles-audit.md) |

### 4.3 Bewusst nicht einzeln kombiniert (mit Begründung)

- **Paare ohne gemeinsamen Zustand oder Zeitpunkt**, z. B. Orakel × Manipulator, Schutzengel × Manipulator, Trugbilderwolf × Sensenträger: Die Rollen lesen oder schreiben keine gemeinsamen Daten. Ihr Zusammenspiel läuft nur über Tod und Siegprüfung, die der Fuzztest in gemischten Besetzungen abdeckt.
- **Rudelzusammensetzung:** Der Rudelschritt kennt keine Einzelpersonen. Welche Wolfsrolle lebt, beeinflusst nur die Existenz des Schritts und die Parität; beides ist über G-PH-6 und die Paritätstests abgedeckt.
- **Alle 12×12-Paare als eigene Tests:** nicht erzeugt. Paare mit gemeinsamem Datenfluss stehen oben oder in den Rollentests; der Rest ist durch Invarianten im Fuzztest geprüft, nicht durch erwartete Einzelergebnisse.
- **Noch ungeprüft:** echte Oberfläche, vollständige Runde am Tablet, Undo/Redo (im Kern nicht vorhanden), Randfall F-10 (§6).

## 5. Testnachweis

Windows, Godot `4.7.2.stable.official.ed1daf0bf` (Console-EXE), nur `--headless` (kein Fenster), Ablauf nach `.claude/skills/grimmhain-core/windows-checks.md`: Import ohne `SCRIPT ERROR`, `Parse Error` oder `Failed to load script`, danach `res://tests/run_tests.gd`. Letzter vollständiger Lauf: 601 Tests, 0 fehlgeschlagen, 0 Testdateien nicht ladbar, keine `SCRIPT ERROR`, Exit-Code 0. `node tools/role-migration/check-role-docs.js`: keine Fehler, Exit-Code 0.

## 6. Offene Fragen an den Product Owner (nächste Chargen)

Die frühere Frage RM-DR-017 („welche Rollen als Nächstes“) ist durch den Auftrag „alle 72 Rollen“ überholt. Jede Frage enthält ein Szenario, drei Optionen, eine Empfehlung; eine eigene Antwort ist immer möglich.

### F-01 · Doppelspion: muss er leben, um zu gewinnen? (RM-DR-155.1)
- **Szenario:** Ben (Doppelspion) wird in Nacht 2 gefressen. Am Tag 3 wird Anna, die letzte Werwölfin, hingerichtet. Clara und David (Dorf) leben.
- **A (Empfehlung):** Nur lebend. Ben ist tot, das Dorf gewinnt. (Legacy-Code; gleiche Bedingung wie beim Manipulator.)
- **B:** Auch tot. Ben gewinnt allein.
- **C:** Tot gewinnt er nicht allein, sondern gemeinsam mit dem Dorf.
- **Eigene Antwort** möglich.
- **Hängt ab:** `doppelspion`; neue Tests `test_doppelspion` (Sieg lebend/tot, Kopien, Lehrling-Erbe, Save/Load).

### F-02 · Doppelspion: wird das Dorf gleichzeitig als Sieger vorgeschlagen? (RM-DR-155.3)
- **Szenario:** Anna, die letzte Werwölfin, wird hingerichtet. Ben (Doppelspion), Clara und David leben.
- **A (Empfehlung):** Nur „Ben gewinnt allein“ wird vorgeschlagen, „Dorf gewinnt“ nicht. Ablehnen und ein eigener Sieger bleiben möglich.
- **B:** Beide werden vorgeschlagen, du wählst.
- **C:** Beide, „Ben“ ist als laut Rollentext zutreffend markiert.
- **Eigene Antwort** möglich.
- **Hängt ab:** `doppelspion`, `WinRules`, Tests der Kandidatenmenge.

### F-03 · Doppelspion: was erfahren die Werwölfe? (RM-DR-155.4)
- **Szenario:** Nacht 1. Anna und Emil (Werwölfe) werden geweckt, Ben (Doppelspion) wacht mit auf.
- **A (Empfehlung):** Keine Rollennennung; die Wölfe sehen eine weitere wache Person.
- **B:** Der Spielleiter sagt „Ben ist der Doppelspion“.
- **C:** Nur Ben öffnet die Augen; die Wölfe sehen ihn nicht.
- **Eigene Antwort** möglich.
- **Hängt ab:** `doppelspion` (Ansage und Hinweis im Rudelschritt, keine Siegwirkung).

### F-04 · Selbstmörder: welche Toten zählen für „5 Tote“? (RM-DR-138.1)
- **Szenario:** 10 Personen, 5 sind bereits tot. Carla (Selbstmörderin) wird hingerichtet.
- **A (Empfehlung):** Gezählt wird vor ihrem Tod: 5 Tote, Carla gewinnt.
- **B:** Ihr eigener Tod zählt mit; sie hätte schon bei 4 Toten vorher gewonnen.
- **C:** Die Schwelle hängt von der Personenzahl ab (z. B. ein Drittel), weil 5 Tote bei 6 und bei 24 Personen sehr Unterschiedliches bedeuten.
- **Eigene Antwort** möglich.
- **Hängt ab:** `selbstmoerder`; Tests Hinrichtung bei 4, 5 und 6 Toten, mit 6 und 24 Personen.

### F-05 · Selbstmörder: zählen Wiederbelebte als Tote? (RM-DR-138.3)
- **Szenario:** 5 Personen starben, eine davon wurde wiederbelebt. Carla wird hingerichtet.
- **A (Empfehlung):** Es zählen nur Personen, die bei der Hinrichtung tot sind: 4, kein Sieg.
- **B:** Jeder Todesfall der Partie zählt, auch doppelte Tode derselben Person.
- **C:** Jede Person, die mindestens einmal gestorben ist, zählt einmal: 5, Sieg.
- **Eigene Antwort** möglich.
- **Hängt ab:** `selbstmoerder`; Wiederbelebungstests.

### F-06 · Selbstmörder: was passiert mit einem abgelehnten Sieg? (RM-DR-138.4)
- **Szenario:** Carla erfüllt die Bedingung, du lehnst den Sieg ab und spielst weiter; danach stirbt eine weitere Person.
- **A (Empfehlung):** Der Sieg verfällt endgültig; nur eine erneute Hinrichtung derselben Person nach Wiederbelebung kann ihn wieder auslösen.
- **B:** Er wird nach jeder späteren Zustandsänderung erneut angeboten.
- **C:** Er bleibt als Hinweis sichtbar, entsteht aber nicht neu; du kannst ihn später per Spielleiterentscheidung erklären.
- **Eigene Antwort** möglich.
- **Hängt ab:** `selbstmoerder`, Kandidatenmenge.

### F-07 · „Einmalig“ und „in der ersten Nacht“ (RM-DR-014)
- **Szenario:** Die Dorfchronistin kommt per Lehrling-Erbe erst in Nacht 3 ins Spiel. Oder: In Nacht 1 fiel ihr Schritt wegen einer Blockade aus.
- **A (Empfehlung):** Schritt in der ersten verfügbaren Nacht der Person, bis er einmal erledigt ist (wie Wolfskind und Lehrling, DR-10/DR-11).
- **B:** Strikt nur Nacht 1 der Partie; wer dann nicht handelt, verliert die Fähigkeit.
- **C:** Die Information wird jede Nacht neu gegeben, solange die Person lebt.
- **Eigene Antwort** möglich.
- **Hängt ab:** `die-gebundenen`, `dorfchronistin`, `loki`, `schattenhund`, `koenig-lykaon`, `schicksalswolf`, `schattenwanderer`, `kriegerin-des-lichts`, `faehrtenleser` und weitere laut RM-DR-014.

### F-08 · Die Gebundenen: wen sehen sie?
- **Szenario:** 4 Gebundene, einer (Dieter) ist vor ihrem Schritt gestorben. Oder: nur noch eine Gebundene lebt.
- **A (Empfehlung):** Jede lebende Gebundene sieht alle anderen **lebenden** Gebundenen (Legacy); lebt nur eine, erfährt sie „keine anderen“, der Schritt gilt als erledigt.
- **B:** Sie sehen alle anderen Gebundenen, auch tote.
- **C:** Sie erfahren nur die Anzahl, nicht die Namen.
- **Eigene Antwort** möglich.
- **Hängt ab:** `die-gebundenen`; Tests Kopien, Tote, Erbe, Save/Load, Sichtbarkeit.

### F-09 · Dorfchronistin: was wird gezählt?
- **Szenario:** Im Spiel sind zwei Manipulatoren und ein Doppelspion; ein Manipulator ist bereits tot.
- **A (Empfehlung):** Anzahl der Personen mit Einzelsiegrolle zum Zeitpunkt des Schritts, lebend und tot: 3 (Legacy). Jede Chronistin erhält die Information für sich (G-ID-3).
- **B:** Nur lebende Personen mit Einzelsiegrolle: 2.
- **C:** Anzahl verschiedener Einzelsiegrollen: 2 (Manipulator, Doppelspion).
- **Eigene Antwort** möglich.
- **Hängt ab:** `dorfchronistin`; Tests Kopien, Tote, Rollenkorrektur vor dem Schritt.

### F-10 · Rudel, wenn nur ein erst in dieser Nacht verwandelter Wolf lebt
- **Szenario:** Nacht 3: Emil ist der einzige Werwolf. Vor dem Rudelschritt tötest du per Korrektur Emil und die Vorbild-Person des Wolfskinds Mia; Mia verwandelt sich. Sie zählt jetzt als Wolf, wacht laut Wolfskind-Eintrag aber erst ab der folgenden Nacht mit dem Rudel.
- **A (Empfehlung):** Der Rudelschritt entfällt, weil niemand mehr lebt, der zu Nachtbeginn zum Rudel gehörte (Nachtplan als Snapshot, wie bei persönlichen Schritten).
- **B:** Der Rudelschritt bleibt, weil eine lebende Person als Wolf zählt (wörtlich G-PH-6; heutiges Verhalten).
- **C:** Der Schritt bleibt; der Spielleiter entscheidet und überspringt ihn gegebenenfalls mit Begründung.
- **Eigene Antwort** möglich.
- **Hängt ab:** `werwolf`, `wolfskind` (nur dieser per Spielleiterkorrektur erreichbare Randfall; der Grün-Status beider Rollen gilt für alle übrigen Abläufe). A braucht einen gespeicherten Rudel-Snapshot (Schemaänderung).

## 7. Fortsetzung

1. Nach Antworten auf F-01 bis F-03: `doppelspion` testgetrieben umsetzen (Einzelsieg-Kandidat je Person, Parität als Nicht-Wolf nach RM-DR-155.2, Orakel nach DR-07), Rollenliste des Fuzztests erweitern.
2. Nach F-04 bis F-06: `selbstmoerder` (Moment-Sieg bei Hinrichtung über `ExecutionRules`).
3. Nach F-07 bis F-09: `die-gebundenen`, `dorfchronistin` (dafür ein allgemeineres Informationsmodell als das Orakel-`InfoRecord`, siehe [`02`](02-implemented-roles-audit.md) §4.5).
4. Danach die Chargen aus [`06-implementation-batches.md`](06-implementation-batches.md) in der Reihenfolge der Entscheidungen; je Charge: Tests zuerst, Umsetzung, Fuzz-Rollenliste, diese Übersicht, Commit.
