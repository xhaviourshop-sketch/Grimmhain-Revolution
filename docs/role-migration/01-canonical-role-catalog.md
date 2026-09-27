# 01 · Kanonischer Rollenkatalog

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · nur Analyse
**Statuswerte:** ausschließlich nach [`00-method-and-sources.md`](00-method-and-sources.md) §3. **IDs:** DR-01 (deutsches ASCII-kebab-case), abgeleitet aus dem Legacy-Namen (ä→ae, ö→oe, ü→ue, ß→ss, Punkt entfällt, Leerzeichen→Bindestrich). Die 11 Godot-IDs folgen exakt diesem Schema.

## 1. Nachgewiesene Gesamtzahl

Es gibt **72 Rollen**. `ALL_ROLES` in `js/core/roles.js:1` enthält 72 eindeutige Namen; `ROLE_DESCRIPTIONS`, `ROLE_NAMES_EN`, `ROLE_DESCRIPTIONS_EN`, `ROLE_ABILITIES` (`js/core/role-abilities.js`), die Vereinigung der vier Akte (`js/core/akte.js`), die Kartenbilder (je 72 plus Rückseite unter `assets/cards/de` und `assets/cards/en`) und die 72 Zeilen von [`../godot-migration/04-rules-migration-matrix.md`](../godot-migration/04-rules-migration-matrix.md) enthalten dieselbe Menge. Einzige Quelle mit anderer Zahl: `ROADMAP.md` (Zeilen 45, 153, 265) nennt „75+ Rollen“; das ist durch keine Code-, Daten- oder Assetquelle belegt. Details: [`00-method-and-sources.md`](00-method-and-sources.md) §5 und [`dossiers/inventory.md`](dossiers/inventory.md).

| Kennzahl | Wert |
|---|---:|
| Rollen gesamt | 72 |
| Dorf / Wölfe / Einzelsieg (`getRoleFaction`) | 39 / 19 / 14 |
| im Godot-Kern umgesetzt und getestet (`implemented-and-tested`) | 11 |
| teilweise umgesetzt (`implemented-partial`) | 0 |
| fehlend, Regel ausreichend klar (`documented-only`) | 3 |
| fehlend, Entscheidung nötig (`decision-required`) | 58 |
| Legacy-Befund `legacy-verified` (alle 72) | 26 |
| Legacy-Befund `legacy-contradictory` (alle 72) | 28 |
| Legacy-Befund `legacy-broken` (alle 72) | 14 |
| Legacy-Befund `not-found` (alle 72) | 4 |
| Legacy-Befund `legacy-verified` (nur 61 fehlende) | 19 |
| Legacy-Befund `legacy-contradictory` (nur 61 fehlende) | 27 |
| Legacy-Befund `legacy-broken` (nur 61 fehlende) | 11 |
| Legacy-Befund `not-found` (nur 61 fehlende) | 4 |

<!-- check:counts total=72 implemented=11 remaining=61 -->

Die Legacy-Befunde weichen bewusst von der älteren Matrix `docs/godot-migration/04-rules-migration-matrix.md` ab (dort 41 verifiziert, 19 widersprüchlich, 3 unklar, 9 fehlend). Gründe je Rolle stehen in [`04-rule-conflicts.md`](04-rule-conflicts.md) §5.

## 2. Haupttabelle

Spalten: Godot = Migrationsstatus; Legacy = Befund des Legacy-Codes; Auto = Automationsziel; Größe/Risiko = relative Umsetzungsgröße und Fehlerrisiko; Charge = Implementierungscharge aus [`06`](06-implementation-batches.md) (`–` = bereits umgesetzt); 1.0 = kleinste Option aus [`05`](05-v1-role-options.md), in der die Rolle enthalten ist (`–` = in keiner Option). Nachtpriorität = `ORDER_BASE`-Tier der Legacy-App (`once` = Legacy-Einmalzeile), nicht die Godot-Priorität.

| # | ID | DE / EN | Fraktion | Akte | Nachtpriorität (Legacy) | Godot | Legacy | Auto | Mechanik (primär) | Größe / Risiko | Charge | 1.0 | Detail |
|---:|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `loki` | Loki / Loki | Dorf | I, II, III, IV | 0.1 (once) | `decision-required` | `legacy-contradictory` | `automatic` | Verknüpfte Personen | M / mittel | K6 | B | [03](03-remaining-roles-analysis.md#loki) · [Dossier](dossiers/village-1.md#loki) |
| 2 | `nachtwaechter` | Nachtwächter / Night Warden | Dorf | I | – | `decision-required` | `legacy-broken` | `automatic` | Informationsrolle | S / niedrig | K3 | C | [03](03-remaining-roles-analysis.md#nachtwaechter) · [Dossier](dossiers/village-1.md#nachtwaechter) |
| 3 | `die-gebundenen` | Die Gebundenen / The Bound | Dorf | I | 0.5 (once) | `documented-only` | `legacy-verified` | `automatic` | Informationsrolle | S / niedrig | K2 | C | [03](03-remaining-roles-analysis.md#die-gebundenen) · [Dossier](dossiers/village-1.md#die-gebundenen) |
| 4 | `waldhexe` | Waldhexe / Witch of the Woods | Dorf | I, II | 3.4 | `implemented-and-tested` | `legacy-verified` | `automatic` | mehrstufige Nachtfähigkeit | L / hoch | – | Basis | [02](02-implemented-roles-audit.md) |
| 5 | `rattenfaenger` | Rattenfänger / Pied Piper | Einzelsieg | I | 4.2 | `decision-required` | `legacy-broken` | `automatic` | Einzelsieg | M / mittel | K9 | B | [03](03-remaining-roles-analysis.md#rattenfaenger) · [Dossier](dossiers/solos-a.md#rattenfaenger) |
| 6 | `sensentraeger` | Sensenträger / Reaper | Dorf | I, II, III, IV | – | `implemented-and-tested` | `legacy-contradictory` | `automatic` | Todesreaktion | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 7 | `wolfskind` | Wolfskind / Wolf Child | Dorf | I | 0.9 (once) | `implemented-and-tested` | `legacy-verified` | `automatic` | Fraktionswechsel | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 8 | `das-orakel` | Das Orakel / The Oracle | Dorf | I | 4.6 | `implemented-and-tested` | `legacy-verified` | `automatic` | Informationsrolle | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 9 | `die-ewigen` | Die Ewigen / The Eternal Ones | Dorf | II | 4.8 | `decision-required` | `not-found` | `assisted` | Informationsrolle | M / mittel | K9 | – | [03](03-remaining-roles-analysis.md#die-ewigen) · [Dossier](dossiers/village-1.md#die-ewigen) |
| 10 | `spuerhund` | Spürhund / Scent Hound | Dorf | I | 6.8 | `decision-required` | `legacy-contradictory` | `automatic` | Informationsrolle | M / mittel | K7 | – | [03](03-remaining-roles-analysis.md#spuerhund) · [Dossier](dossiers/village-1.md#spuerhund) |
| 11 | `schutzengel` | Schutzengel / Guardian Angel | Dorf | I | 1.3 | `implemented-and-tested` | `legacy-broken` | `automatic` | Schutz | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 12 | `werwolf` | Werwolf / Werewolf | Wölfe | I, II, III, IV | 2.0 | `implemented-and-tested` | `legacy-verified` | `automatic` | Tötung | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 13 | `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | Wölfe | I, II, III, IV | 2.2 | `decision-required` | `legacy-contradictory` | `assisted` | Tötung | M / hoch | K11 | – | [03](03-remaining-roles-analysis.md#rachsuechtiger-wolf) · [Dossier](dossiers/wolves-a.md#rachsuechtiger-wolf) |
| 14 | `koenig-lykaon` | König Lykaon / King Lycaon | Wölfe | I | 2.4 (once) | `decision-required` | `legacy-verified` | `automatic` | Rollenwechsel | M / mittel | K12 | C | [03](03-remaining-roles-analysis.md#koenig-lykaon) · [Dossier](dossiers/wolves-a.md#koenig-lykaon) |
| 15 | `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | Wölfe | IV | – | `documented-only` | `legacy-verified` | `automatic` | sonstige Spezialmechanik | S / niedrig | K1 | A | [03](03-remaining-roles-analysis.md#siegreicher-wolf) · [Dossier](dossiers/wolves-a.md#siegreicher-wolf) |
| 16 | `seuchenwolf` | Seuchenwolf / Blight Wolf | Wölfe | IV | – | `decision-required` | `legacy-contradictory` | `automatic` | Wolfsangriff-Modifikation | M / mittel | K11 | – | [03](03-remaining-roles-analysis.md#seuchenwolf) · [Dossier](dossiers/wolves-a.md#seuchenwolf) |
| 17 | `schicksalswolf` | Schicksalswolf / Fate Wolf | Wölfe | IV | 2.5 | `decision-required` | `legacy-contradictory` | `automatic` | Tötung | M / mittel | K11 | – | [03](03-remaining-roles-analysis.md#schicksalswolf) · [Dossier](dossiers/wolves-a.md#schicksalswolf) |
| 18 | `schattenwanderer` | Schattenwanderer / Shadowwalker | Wölfe | II | 2.6 (once) | `decision-required` | `legacy-verified` | `automatic` | Verknüpfte Personen | M / hoch | K6 | – | [03](03-remaining-roles-analysis.md#schattenwanderer) · [Dossier](dossiers/wolves-a.md#schattenwanderer) |
| 19 | `giftwolf` | Giftwolf / Poison Wolf | Wölfe | II | 2.7 | `decision-required` | `legacy-verified` | `automatic` | Tötung | M / mittel | K11 | – | [03](03-remaining-roles-analysis.md#giftwolf) · [Dossier](dossiers/wolves-a.md#giftwolf) |
| 20 | `rudelvater` | Rudelvater / Packfather | Wölfe | II | – | `decision-required` | `legacy-verified` | `automatic` | Wolfsangriff-Modifikation | M / mittel | K11 | – | [03](03-remaining-roles-analysis.md#rudelvater) · [Dossier](dossiers/wolves-a.md#rudelvater) |
| 21 | `schwarze-witwe` | Schwarze Witwe / Black Widow | Wölfe | IV | 2.8 | `decision-required` | `legacy-contradictory` | `automatic` | Verknüpfte Personen | M / mittel | K6 | – | [03](03-remaining-roles-analysis.md#schwarze-witwe) · [Dossier](dossiers/wolves-b.md#schwarze-witwe) |
| 22 | `der-weise` | Der Weise / The Elder | Dorf | I, II, III, IV | – | `decision-required` | `legacy-broken` | `automatic` | Wolfsangriff-Modifikation | M / hoch | K8 | C | [03](03-remaining-roles-analysis.md#der-weise) · [Dossier](dossiers/village-1.md#der-weise) |
| 23 | `verdammniswaechter` | Verdammniswächter / Doom Warden | Dorf | II, IV | 2.3 | `decision-required` | `legacy-contradictory` | `assisted` | Zielumleitung | M / hoch | K11 | – | [03](03-remaining-roles-analysis.md#verdammniswaechter) · [Dossier](dossiers/village-1.md#verdammniswaechter) |
| 24 | `lehrling` | Lehrling / Apprentice | Dorf | II, III | 1.1 (once) | `implemented-and-tested` | `legacy-broken` | `automatic` | Rollenwechsel | L / hoch | – | Basis | [02](02-implemented-roles-audit.md) |
| 25 | `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | Dorf | III | – | `decision-required` | `legacy-contradictory` | `automatic` | Hinrichtungsreaktion | S / mittel | K3 | A | [03](03-remaining-roles-analysis.md#wahnsinniger-kutscher) · [Dossier](dossiers/village-1.md#wahnsinniger-kutscher) |
| 26 | `korrupter-richter` | Korrupter Richter / Corrupt Judge | Dorf | II | 1.5 | `decision-required` | `not-found` | `assisted` | Nominierungsreaktion | S / mittel | K14 | – | [03](03-remaining-roles-analysis.md#korrupter-richter) · [Dossier](dossiers/village-2.md#korrupter-richter) |
| 27 | `maertyrerin` | Märtyrerin / Martyr | Dorf | II | 9.0 | `decision-required` | `legacy-contradictory` | `assisted` | Schutz | M / mittel | K5 | – | [03](03-remaining-roles-analysis.md#maertyrerin) · [Dossier](dossiers/village-2.md#maertyrerin) |
| 28 | `dorfwache` | Dorfwache / Village Guard | Dorf | IV | – | `decision-required` | `legacy-verified` | `automatic` | passive Dorfrolle | S / niedrig | K5 | A | [03](03-remaining-roles-analysis.md#dorfwache) · [Dossier](dossiers/village-2.md#dorfwache) |
| 29 | `pestbringerin` | Pestbringerin / Plague Bringer | Einzelsieg | II | 7.2 | `decision-required` | `legacy-contradictory` | `automatic` | Einzelsieg | M / mittel | K9 | – | [03](03-remaining-roles-analysis.md#pestbringerin) · [Dossier](dossiers/solos-a.md#pestbringerin) |
| 30 | `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | Einzelsieg | III, IV | 8.6 | `decision-required` | `not-found` | `assisted` | Tötung | M / mittel | K9 | – | [03](03-remaining-roles-analysis.md#prophet-des-untergangs) · [Dossier](dossiers/solos-a.md#prophet-des-untergangs) |
| 31 | `spiegelwolf` | Spiegelwolf / Mirror Wolf | Wölfe | III | – | `implemented-and-tested` | `legacy-verified` | `automatic` | Hinrichtungsreaktion | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 32 | `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | Wölfe | II | – | `decision-required` | `legacy-contradictory` | `automatic` | Todesreaktion | M / hoch | K12 | – | [03](03-remaining-roles-analysis.md#daemonischer-wolf) · [Dossier](dossiers/wolves-b.md#daemonischer-wolf) |
| 33 | `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Wölfe | III | – | `implemented-and-tested` | `legacy-verified` | `automatic` | Fehlinformation | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 34 | `schattenhund` | Schattenhund / Shadow Hound | Wölfe | III | 0.7 (once) | `decision-required` | `legacy-contradictory` | `automatic` | globale Regeländerung | S / mittel | K8 | B | [03](03-remaining-roles-analysis.md#schattenhund) · [Dossier](dossiers/wolves-b.md#schattenhund) |
| 35 | `besessener-wolf` | Besessener Wolf / Possessed Wolf | Wölfe | III | – | `decision-required` | `legacy-broken` | `automatic` | Todesreaktion | M / mittel | K4 | A | [03](03-remaining-roles-analysis.md#besessener-wolf) · [Dossier](dossiers/wolves-b.md#besessener-wolf) |
| 36 | `fenrir` | Fenrir / Fenrir | Wölfe | IV | – | `decision-required` | `legacy-contradictory` | `automatic` | Hinrichtungsreaktion | M / mittel | K4 | – | [03](03-remaining-roles-analysis.md#fenrir) · [Dossier](dossiers/wolves-b.md#fenrir) |
| 37 | `kutscher` | Kutscher / Coachman | Dorf | II | 3.8 | `decision-required` | `legacy-contradictory` | `assisted` | Wiederbelebung | L / hoch | K13 | – | [03](03-remaining-roles-analysis.md#kutscher) · [Dossier](dossiers/village-2.md#kutscher) |
| 38 | `seelentauscher` | Seelentauscher / Soul Swapper | Dorf | II | 8.0 (once) | `decision-required` | `legacy-broken` | `assisted` | Rollenwechsel | L / kritisch | K12 | – | [03](03-remaining-roles-analysis.md#seelentauscher) · [Dossier](dossiers/village-2.md#seelentauscher) |
| 39 | `blutpriester` | Blutpriester / Blood Priest | Dorf | II | 8.2 (once) | `decision-required` | `legacy-verified` | `assisted` | Informationsrolle | M / mittel | K7 | – | [03](03-remaining-roles-analysis.md#blutpriester) · [Dossier](dossiers/village-2.md#blutpriester) |
| 40 | `traumdeuter` | Traumdeuter / Dreamer | Dorf | III | 7.0 | `decision-required` | `legacy-contradictory` | `automatic` | Informationsrolle | S / niedrig | K7 | – | [03](03-remaining-roles-analysis.md#traumdeuter) · [Dossier](dossiers/village-2.md#traumdeuter) |
| 41 | `henker` | Henker / Executioner | Dorf | III | 7.8 | `decision-required` | `legacy-verified` | `automatic` | Hinrichtungsreaktion | M / mittel | K4 | – | [03](03-remaining-roles-analysis.md#henker) · [Dossier](dossiers/village-2.md#henker) |
| 42 | `feuerteufel` | Feuerteufel / Pyromaniac | Einzelsieg | IV | 7.6 | `decision-required` | `legacy-broken` | `automatic` | Todesreaktion | M / hoch | K9 | – | [03](03-remaining-roles-analysis.md#feuerteufel) · [Dossier](dossiers/solos-a.md#feuerteufel) |
| 43 | `voodoo-priester` | Voodoo-Priester / Voodoo Priest | Einzelsieg | II | 8.4 | `decision-required` | `legacy-contradictory` | `automatic` | Zielumleitung | L / hoch | K10 | – | [03](03-remaining-roles-analysis.md#voodoo-priester) · [Dossier](dossiers/solos-a.md#voodoo-priester) |
| 44 | `blutwolf` | Blutwolf / Blood Wolf | Wölfe | II | – | `decision-required` | `legacy-verified` | `assisted` | sonstige Spezialmechanik | S / niedrig | K14 | – | [03](03-remaining-roles-analysis.md#blutwolf) · [Dossier](dossiers/wolves-b.md#blutwolf) |
| 45 | `albtraumwolf` | Albtraumwolf / Nightmare Wolf | Wölfe | III, IV | 2.1 | `decision-required` | `legacy-broken` | `automatic` | sonstige Spezialmechanik | S / mittel | K8 | – | [03](03-remaining-roles-analysis.md#albtraumwolf) · [Dossier](dossiers/wolves-b.md#albtraumwolf) |
| 46 | `cerberus` | Cerberus / Cerberus | Wölfe | IV | – | `decision-required` | `legacy-contradictory` | `automatic` | Hinrichtungsreaktion | S / mittel | K4 | B | [03](03-remaining-roles-analysis.md#cerberus) · [Dossier](dossiers/wolves-b.md#cerberus) |
| 47 | `ritter` | Ritter / Knight | Dorf | I | – | `decision-required` | `legacy-contradictory` | `automatic` | Todesreaktion | M / mittel | K3 | A | [03](03-remaining-roles-analysis.md#ritter) · [Dossier](dossiers/village-3.md#ritter) |
| 48 | `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | Dorf | III | 7.4 | `decision-required` | `legacy-contradictory` | `assisted` | Verknüpfte Personen | L / hoch | K10 | – | [03](03-remaining-roles-analysis.md#rotkaeppchen) · [Dossier](dossiers/village-3.md#rotkaeppchen) |
| 49 | `selbstmoerder` | Selbstmörder / Death Seeker | Einzelsieg | I | – | `decision-required` | `legacy-verified` | `automatic` | Einzelsieg | S / niedrig | K1 | A | [03](03-remaining-roles-analysis.md#selbstmoerder) · [Dossier](dossiers/solos-a.md#selbstmoerder) |
| 50 | `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter | Dorf | IV | 3.2 | `decision-required` | `legacy-verified` | `automatic` | Informationsrolle | M / mittel | K7 | B | [03](03-remaining-roles-analysis.md#kopfgeldjaeger) · [Dossier](dossiers/village-3.md#kopfgeldjaeger) |
| 51 | `koenig` | König / King | Dorf | III, IV | 4.4 | `decision-required` | `legacy-contradictory` | `automatic` | Informationsrolle | S / mittel | K7 | – | [03](03-remaining-roles-analysis.md#koenig) · [Dossier](dossiers/village-3.md#koenig) |
| 52 | `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | Dorf | II | 3.6 | `decision-required` | `legacy-broken` | `assisted` | Wiederbelebung | L / hoch | K13 | – | [03](03-remaining-roles-analysis.md#dr-victor-frankenstein) · [Dossier](dossiers/village-3.md#dr-victor-frankenstein) |
| 53 | `nekromant` | Nekromant / Necromancer | Einzelsieg | II | 3.0 | `decision-required` | `legacy-contradictory` | `assisted` | Schutz | L / hoch | K15 | – | [03](03-remaining-roles-analysis.md#nekromant) · [Dossier](dossiers/solos-b.md#nekromant) |
| 54 | `kartenschlucker` | Kartenschlucker / The Collector | Einzelsieg | III, IV | 4.0 | `decision-required` | `legacy-contradictory` | `assisted` | Totenkarten-Interaktion | L / hoch | K15 | – | [03](03-remaining-roles-analysis.md#kartenschlucker) · [Dossier](dossiers/solos-b.md#kartenschlucker) |
| 55 | `hades` | Hades / Hades | Einzelsieg | IV | 9.9 | `decision-required` | `legacy-verified` | `assisted` | Einzelsieg | M / mittel | K15 | – | [03](03-remaining-roles-analysis.md#hades) · [Dossier](dossiers/solos-b.md#hades) |
| 56 | `doktor` | Doktor / Doctor | Dorf | IV | 5.0 | `decision-required` | `legacy-contradictory` | `automatic` | Informationsrolle | S / niedrig | K2 | A | [03](03-remaining-roles-analysis.md#doktor) · [Dossier](dossiers/village-3.md#doktor) |
| 57 | `faehrtenleser` | Fährtenleser / Tracker | Dorf | III | 5.2 | `decision-required` | `legacy-contradictory` | `assisted` | Informationsrolle | S / mittel | K3 | – | [03](03-remaining-roles-analysis.md#faehrtenleser) · [Dossier](dossiers/village-3.md#faehrtenleser) |
| 58 | `waldlaeufer` | Waldläufer / Ranger | Dorf | IV | 5.4 | `decision-required` | `legacy-verified` | `automatic` | Informationsrolle | S / niedrig | K2 | A | [03](03-remaining-roles-analysis.md#waldlaeufer) · [Dossier](dossiers/village-3.md#waldlaeufer) |
| 59 | `schutzgeist` | Schutzgeist / Guardian Spirit | Dorf | II | 5.6 | `decision-required` | `legacy-broken` | `automatic` | Schutz | M / mittel | K5 | – | [03](03-remaining-roles-analysis.md#schutzgeist) · [Dossier](dossiers/village-4.md#schutzgeist) |
| 60 | `dorfchronistin` | Dorfchronistin / Village Chronicler | Dorf | III | 0.3 (once) | `documented-only` | `legacy-verified` | `automatic` | Informationsrolle | S / niedrig | K2 | – | [03](03-remaining-roles-analysis.md#dorfchronistin) · [Dossier](dossiers/village-4.md#dorfchronistin) |
| 61 | `waechter-am-tor` | Wächter am Tor / Gatewarden | Dorf | IV | – | `decision-required` | `legacy-verified` | `automatic` | globale Regeländerung | M / hoch | K12 | – | [03](03-remaining-roles-analysis.md#waechter-am-tor) · [Dossier](dossiers/village-4.md#waechter-am-tor) |
| 62 | `zeitwaechter` | Zeitwächter / Time Warden | Dorf | III | 9.5 (once) | `decision-required` | `legacy-contradictory` | `assisted` | globale Regeländerung | XL / kritisch | K16 | – | [03](03-remaining-roles-analysis.md#zeitwaechter) · [Dossier](dossiers/village-4.md#zeitwaechter) |
| 63 | `amalia` | Amalia / Amalia | Dorf | IV | 5.8 | `decision-required` | `legacy-contradictory` | `assisted` | Informationsrolle | M / mittel | K14 | – | [03](03-remaining-roles-analysis.md#amalia) · [Dossier](dossiers/village-4.md#amalia) |
| 64 | `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light | Dorf | IV | 6.0 (once) | `decision-required` | `legacy-contradictory` | `assisted` | Informationsrolle | S / mittel | K7 | – | [03](03-remaining-roles-analysis.md#kriegerin-des-lichts) · [Dossier](dossiers/village-4.md#kriegerin-des-lichts) |
| 65 | `detektiv` | Detektiv / Detective | Dorf | III | – | `decision-required` | `legacy-broken` | `automatic` | Informationsrolle | M / hoch | K3 | – | [03](03-remaining-roles-analysis.md#detektiv) · [Dossier](dossiers/village-4.md#detektiv) |
| 66 | `dorfschmied` | Dorfschmied / Village Blacksmith | Dorf | IV | 1.7 | `decision-required` | `legacy-verified` | `automatic` | Wolfsangriff-Modifikation | M / mittel | K5 | – | [03](03-remaining-roles-analysis.md#dorfschmied) · [Dossier](dossiers/village-4.md#dorfschmied) |
| 67 | `manipulator` | Manipulator / Manipulator | Einzelsieg | III | – | `implemented-and-tested` | `legacy-broken` | `automatic` | Nominierungsreaktion | M / mittel | – | Basis | [02](02-implemented-roles-audit.md) |
| 68 | `doppelspion` | Doppelspion / Double Agent | Einzelsieg | III | – | `decision-required` | `legacy-verified` | `automatic` | Einzelsieg | S / mittel | K1 | A | [03](03-remaining-roles-analysis.md#doppelspion) · [Dossier](dossiers/solos-a.md#doppelspion) |
| 69 | `grabraeuber` | Grabräuber / Grave Robber | Einzelsieg | II | 6.4 (once) | `decision-required` | `not-found` | `manual-only` | Einmalfähigkeit | XL / hoch | K15 | – | [03](03-remaining-roles-analysis.md#grabraeuber) · [Dossier](dossiers/solos-b.md#grabraeuber) |
| 70 | `parasit` | Parasit / Parasite | Einzelsieg | III | 6.2 | `decision-required` | `legacy-verified` | `automatic` | Verknüpfte Personen | M / mittel | K10 | C | [03](03-remaining-roles-analysis.md#parasit) · [Dossier](dossiers/solos-b.md#parasit) |
| 71 | `todesprediger` | Todesprediger / Death Prophet | Einzelsieg | II | 6.6 (once) | `decision-required` | `legacy-broken` | `automatic` | Einzelsieg | M / mittel | K15 | – | [03](03-remaining-roles-analysis.md#todesprediger) · [Dossier](dossiers/solos-b.md#todesprediger) |
| 72 | `dorfbewohner` | Dorfbewohner / Villager | Dorf | I, II, III, IV | – | `implemented-and-tested` | `legacy-verified` | `automatic` | passive Dorfrolle | S / niedrig | – | Basis | [02](02-implemented-roles-audit.md) |

## 3. Aliase, Altnamen, entfernte Rollen und Duplikate

Keine Rolle wurde zusammengeführt. Die folgenden Namen sind **keine** zusätzlichen Rollen.

| Name | Art | Heutige Rolle | Beleg |
|---|---|---|---|
| Amor | Altname, migriert | `loki` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Hexe | Altname, migriert | `waldhexe` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Jäger | Altname, migriert | `sensentraeger` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Seherin | Altname, migriert | `das-orakel` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Flötenspieler | Altname, migriert | `rattenfaenger` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Weißer Werwolf | Altname, migriert | `rachsuechtiger-wolf` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Der Alte | Altname, migriert | `der-weise` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Engel | Altname, migriert | `schutzengel` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Bärenführer | Altname, migriert | `nachtwaechter` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Fuchs | Altname, migriert | `spuerhund` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Urwolf | Altname, migriert; zusätzlich `usedKey("Urwolf")` in `js/ui/core.js:350` | `koenig-lykaon` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Totenrat-Führer | Altname, migriert; lebt in Zustandsfeldern und i18n-Schlüsseln (`totenrat*`) sowie in SOLO-Fallbacklisten `game.html:889`, `:1019` weiter | `nekromant` | `js/core/state.js:18` (`migrateLegacyRoleIds`) |
| Blinzelmädchen | **entfernte Rolle** ohne Nachfolger; wird auf Dorfbewohner abgebildet | `dorfbewohner` (Ersatz, keine Nachfolge) | `js/core/state.js:18`; sonst nirgends im Repository |
| Mogli | Altname nur in Zustandsfeldern (`MogliVorbildId`, `MogliUsed`); als Rollenstring nicht migriert | `wolfskind` | `js/core/state.js:10`, `js/ui/core.js:388` |
| Busfahrer | Altname in einem Werkzeug, nicht migriert | `wahnsinniger-kutscher` | `tools/create_role_doc.py:83` |
| Chronist | falscher Schlüssel (Bug): Rotkäppchen-Apfel setzt die Dorfchronistin nie zurück | `dorfchronistin` | `js/core/abilities.js:107` |
| Seer, Witch | abweichende EN-Kurznamen in Texten | `das-orakel`, `waldhexe` | `js/core/i18n.js:958`, `:459` |
| Forest Witch | abweichender EN-Name im Godot-Umfeld (Legacy und Regelregister: „Witch of the Woods“) | `waldhexe` | `godot/core/rules/role_catalog.gd:20`, `godot/README.md:190` |
| Revenge Wolf, Vengeful Wolf | abweichender EN-Name im Doppelspion-Text bzw. Kartendateiname (offiziell „Lone Wolf“) | `rachsuechtiger-wolf` | `js/core/roles.js` (`ROLE_DESCRIPTIONS_EN` Doppelspion), `assets/cards/en/Vengeful_Wolf.webp` |
| Pack Leader, Shadow Wanderer, Soul Shifter, Timekeeper, Village Smith, Plague Bearer | abweichende EN-Laufzeitnamen in Dialogen | `rudelvater`, `schattenwanderer`, `seelentauscher`, `zeitwaechter`, `dorfschmied`, `pestbringerin` | Dossiers |

**Verwechslungsgefahr, aber eigenständige Rollen:** `kutscher` / `wahnsinniger-kutscher`; `koenig` / `koenig-lykaon`; `schutzengel` / `schutzgeist`; `todesprediger` / `prophet-des-untergangs`; `nachtwaechter` / `dorfwache` / `waechter-am-tor` / `zeitwaechter` / `verdammniswaechter`. Jede hat eigenen Text, eigene Karte und eigenen Code.

**Duplikate:** keine in `ALL_ROLES`. Inhaltsgleich sind nur die Kartendateien `Rachsüchtiger_Wolf.webp`/`Vengeful_Wolf.webp` und die Rückseiten.

**Totenkarten** (`js/core/cards.js`) tauschen oder vergeben Rollen (z. B. „Rollenroulette“, „Neuer Anfang“, „Geisterstimme“), führen aber keine Rolle außerhalb der 72 ein.

## 4. Anhang: Legacy-Rollentexte DE und EN (wörtlich)

Quelle: `ROLE_DESCRIPTIONS` und `ROLE_DESCRIPTIONS_EN` in `js/core/roles.js`. Die Texte sind unverändert zitiert und **keine** verbindlichen Regeln. Ob DE und EN semantisch gleich sind, steht je Rolle in [`03`](03-remaining-roles-analysis.md) bzw. [`02`](02-implemented-roles-audit.md); verbindliche Texte der 11 umgesetzten Rollen stehen im Regelregister [`../specs/vertical-slice/rules-register.md`](../specs/vertical-slice/rules-register.md).

| ID | DE | EN |
|---|---|---|
| `loki` | Loki | Once per game: bind two souls as inseparable lovers — or curse two players as eternal rivals. |
| `nachtwaechter` | Night Warden | Guards the borders and senses when a neighbor doesn't belong to the village. The alarm bells ring publicly. |
| `die-gebundenen` | The Bound | Wake in night 1 and learn all other Bound players. |
| `waldhexe` | Witch of the Woods | Each night sees the fate of the victim and decides: once per game you can spare them or doom another player instead. |
| `rattenfaenger` | Pied Piper | Charms players each night. Wins when all living players are charmed. |
| `sensentraeger` | Reaper | Upon death: harvests one final soul of his choice. |
| `wolfskind` | Wolf Child | At the start of the game, choose an enemy. If they die, your animal blood awakens and you count as a werewolf from then on. |
| `das-orakel` | The Oracle | Look into your orb and learn the role of one player. |
| `die-ewigen` | The Eternal Ones | Each night check whether a player has a solo win condition — and win together with them. |
| `spuerhund` | Scent Hound | Choose 3 players. ✅ if one is a wolf, solo, or false lead — otherwise ❌. On ❌, a random player is secretly marked as a false lead. |
| `schutzengel` | Guardian Angel | Each night, choose a player and protect them from the next werewolf attack. |
| `werwolf` | Werewolf | Each night kills a victim together. |
| `rachsuechtiger-wolf` | Lone Wolf | Everyone is your enemy. In addition to the werewolves, you wake up every third night and may kill another werewolf. |
| `koenig-lykaon` | King Lycaon | In the first night, choose an allied wolf. Together you decide which villager is worthy of becoming one of you. That villager then becomes a Decoy Wolf. |
| `siegreicher-wolf` | Victorious Wolf | As long as they live, counts as two werewolves toward the win condition. |
| `seuchenwolf` | Blight Wolf | After their death, the next wolf attack pierces all protection effects. |
| `schicksalswolf` | Fate Wolf | At the start of the game, choose three players. For each of them among the first three dead, you gain a kill ability in night 4. |
| `schattenwanderer` | Shadowwalker | Creates a death link with another player. If one of you dies, the other dies instead — and vice versa. |
| `giftwolf` | Poison Wolf | May twice per game attack a target with poison claws. The target is informed and dies two days later. |
| `rudelvater` | Packfather | Survives the first death not caused by a wolf attack or lynch. If lynched, the werewolves receive a second target the following night; this second attack ignores all protection. |
| `schwarze-witwe` | Black Widow | Loki is chosen automatically. Each night, choose a player. If you find a lover or rival, both die. |
| `der-weise` | The Elder | Thanks to your knowledge and preparation, you survive the first werewolf attack. However, if the village lynches you, they lose their abilities for 1–3 nights and days. |
| `verdammniswaechter` | Doom Warden | Each night: chooses 1 of 2 players — either the night victim dies or a randomly offered player dies instead. This verdict bypasses all protection abilities. |
| `lehrling` | Apprentice | Chooses a mentor and takes over their role upon their death. |
| `wahnsinniger-kutscher` | Mad Coachman | If lynched, both living neighbors die with him. |
| `korrupter-richter` | Corrupt Judge | Can mark a player for the day; they are automatically nominated with +1 vote. |
| `maertyrerin` | Martyr | Can sacrifice herself before the night victim is announced. |
| `dorfwache` | Village Guard | Does not die when targeted by werewolves at night. |
| `pestbringerin` | Plague Bringer | Each night spreads a lethal plague that keeps spreading. |
| `prophet-des-untergangs` | Prophet of Doom | Marks three players. When all are dead, gains the ability to kill each night — and wins alone. |
| `spiegelwolf` | Mirror Wolf | On first lynch, the nominator dies instead of him. |
| `daemonischer-wolf` | Demonic Wolf | Curses victims so they appear as werewolves. |
| `trugbilderwolf` | Decoy Wolf | Deceives the Oracle with a random non-wolf role. |
| `schattenhund` | Shadow Hound | Can once block all village abilities for one night. |
| `besessener-wolf` | Possessed Wolf | Upon death (with ≥5 players), drags another player to their death. |
| `fenrir` | Fenrir | Grows more powerful with each survived night. From stage 3, survives any death once. |
| `kutscher` | Coachman | With 10+ dead: revives 3 dead players — one of them becomes a wolf. |
| `seelentauscher` | Soul Swapper | Once swaps the roles of two players, regardless of whether they are alive or dead. |
| `blutpriester` | Blood Priest | Sacrifices someone and reveals 0–3 werewolves. |
| `traumdeuter` | Dreamer | Receives visions about roles or states of players. |
| `henker` | Executioner | Activates after three lynchings. Each night marks a target who dies additionally after the next lynch. |
| `feuerteufel` | Pyromaniac | Chooses a target; when the target dies, neighbors burn as well. |
| `voodoo-priester` | Voodoo Priest | Gives a voodoo doll to a player. If he would die, the doll holder dies instead. |
| `blutwolf` | Blood Wolf | Their vote counts +1 for each directly adjacent dead neighbor. |
| `albtraumwolf` | Nightmare Wolf | Each night, blocks the ability of one villager. |
| `cerberus` | Cerberus | Builds up to 3 heads; at 3 heads, can block a lynch. |
| `ritter` | Knight | Upon dying at night, kills the nearest werewolf. |
| `rotkaeppchen` | Little Red Riding Hood | Each night she seeks refuge with another player. If he grants it, he receives an apple: his next ability is executed twice. The two are also bound by a death chain — if one dies, the other dies with them. |
| `selbstmoerder` | Death Seeker | Wins if lynched when >=5 players are already dead. |
| `kopfgeldjaeger` | Bounty Hunter | Once a werewolf has been lynched, learns three names — one of them is a werewolf. |
| `koenig` | King | When more players are dead than alive: learns one living villager's identity. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein | Once revives a dead player who receives a brand new role. |
| `nekromant` | Necromancer | With at least three dead players, he may spend three votes at night to raise a shield that prevents the next death of any kind; if unused, it expires when the next night begins. If attacked at night, he may instead sacrifice three dead players and redirect the kill. Wins alone if he correctly names a living werewolf during the day. |
| `kartenschlucker` | The Collector | Gains a stack each time a dead player exchanges their cards. At 10 stacks, wins immediately. |
| `hades` | Hades | Collects life lights from the dead. Buys abilities and wins at 10 lights. |
| `doktor` | Doctor | Each night takes blood samples from two players and learns whether they belong to the same team. |
| `faehrtenleser` | Tracker | Wakes up every night and may once per game learn in which direction the nearest wolf sits: left or right. |
| `waldlaeufer` | Ranger | Learns how many living werewolves are in the game. |
| `schutzgeist` | Guardian Spirit | On the night after their death, chooses a player. That player receives a shield. If she chose a werewolf, the village is told. |
| `dorfchronistin` | Village Chronicler | Learns at the start of the game how many solo roles are in play. |
| `waechter-am-tor` | Gatewarden | While alive, new werewolves are blocked — the affected player becomes a Villager instead. |
| `zeitwaechter` | Time Warden | Once per game, he may freeze a night — all night actions are canceled. That night is treated as though it never happened. |
| `amalia` | Amalia | Carries the will of Hestia. As long as more than two werewolves are in play, may sacrifice herself to publicly ask a yes/no question. |
| `kriegerin-des-lichts` | Warrior of Light | Once per game, attacks directly at night and chooses a player. The moderator reveals if that player is a wolf. If not a wolf, she dies. |
| `detektiv` | Detective | After a wolf dies, a public clue about another wolf is revealed. |
| `dorfschmied` | Village Blacksmith | Forges a weapon over five nights. On the sixth night, he may give it to a player. That player repels one wolf attack and kills a random wolf in the process. |
| `manipulator` | Manipulator | Wins if he reaches the final three without ever being nominated. The moment he is nominated, he dies immediately. |
| `doppelspion` | Double Agent | Wakes up together with the werewolves. Wins alone when all werewolves are dead. The Revenge Wolf's attack has no effect on him. |
| `grabraeuber` | Grave Robber | May once steal the ability of a dead player. Wins alone. |
| `parasit` | Parasite | Wakes each night and may attach himself to a living player. He only dies when his host dies. Wins if he reaches the final three. |
| `todesprediger` | Death Prophet | Predicts the exact night or day of his own death. If he is correct, he wins alone. |
| `dorfbewohner` | Villager | Has no active night ability. |
