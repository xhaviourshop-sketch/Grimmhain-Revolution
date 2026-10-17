# Audit ehrlich, 17.10.2026

Stand: Branch `ux-texte` = `b69354f`, Prüfzeit 14:19 bis 14:51 (45-Minuten-Grenze eingehalten). Nur gelesen und gemessen, nichts geändert außer dieser Datei.
Einstufung: **verifiziert** (heute selbst per Code, Test oder Messung belegt), **nur behauptet** (steht in einem Bericht, heute nicht belegt), **offen** (bekannt ungelöst oder nie geprüft), **kaputt** (nachweislich falsch).
Risiko für Sonntag: ROT / GELB / GRÜN.

## Ampel Sonntag: GELB, mit einem roten Punkt

Der Code ist in sich gesund: Die Vollsuite ist heute grün (1550/0), alle 91 Rollen haben Texte und Karten. ROT ist der Punkt, dass **niemand das Spiel je auf einem iPad in Safari gespielt hat**. Ausgerechnet dort schaltet sich der Leicht-Modus automatisch ein, und den hat noch keiner gesehen. Dazu fehlt der Produktion die Speicher-Korrektur.

## Top 10

| # | Befund | Einstufung | Risiko |
|---|---|---|---|
| 1 | Kein einziger Lauf auf echtem iPad/Safari, auch keine Generalprobe (EVENT-ANALYSE:11, :116; MORGEN-BERICHT:52) | offen | ROT |
| 2 | Der Leicht-Modus schaltet sich auf Touch-Geräten automatisch ein (Auflösung, Shader aus) und wurde nie auf einem Gerät gesehen (PROGRESS:100, :147, :1173) | offen | ROT |
| 3 | Die Produktion `grimmhain-ipad-test` läuft auf `24b58f5` **ohne** Speicher-Korrektur `03583a2` (Nachtbild etwa +4 MB/min, gemessen in Chrome) | verifiziert | GELB |
| 4 | Die Produktion läuft auf einem Commit, der nicht auf `main` liegt (`24b58f5` nur auf `hotfix-freeze`; `main` = `019d70a`) | verifiziert | GELB |
| 5 | Die Vorschau `grimmhain-classic-preview` läuft auf `b69354f` (alles aus ux-texte und nacht-regeln). PROGRESS verzeichnet diesen Deploy nirgends | verifiziert | GELB |
| 6 | Neue Partie Classic: Bei 1024x768 muss man scrollen (Akt-Karte 110 px Überhang, Rollenwahl mit 8 Personen). Seit dem Bericht ist keine Änderung an `round_step.gd`/`act_card.gd` erfolgt | offen (nicht behoben) | GELB |
| 7 | Optionsfenster bei 1024x768 unten abgeschnitten (PROGRESS:172), kein Fix-Commit; heute nicht selbst nachgemessen | offen | GELB |
| 8 | Vermuteter Regelfehler: Liebespaar plus Notanker. `win_rules.gd:129` zählt den aufgeschobenen Toten als lebend, also gibt es Wolfssieg statt Liebespaar-Sieg | offen (Code bestätigt, ungetestet) | GRÜN (sehr selten) |
| 9 | Drei offene Regelfragen ohne Entscheidung: Notanker-Vollstreckung, Weißer Wolf ohne Dorf (Spiel endet nie), Morgenkarte in Wiederbelebungsrunden verrät Rollen | offen | GELB |
| 10 | Arbeit liegt außerhalb von ux-texte: Namen tauschen per Ziehen (`block-e-dragdrop` 19987c8) ist nirgends eingearbeitet | verifiziert | GRÜN |

## 1 Git

| Nr | Befund | Fundort / Beleg | Einstufung | Risiko |
|---|---|---|---|---|
| G1 | `main` = `019d70a` (07.10.). ux-texte und nacht-regeln = `b69354f`, 105 Commits vor main, 0 dahinter | `git rev-list --count` | verifiziert | GELB |
| G2 | `hotfix-freeze` = `f045c84`, 2 Commits vor main. Der Fix `24b58f5` steckt als `5c4e0cb` in ux-texte (gleicher Patch laut `git cherry`). Der PROGRESS-Eintrag f045c84 fehlt in ux-texte | `git cherry -v ux-texte hotfix-freeze` | verifiziert | GRÜN |
| G3 | `classic-akt` (bfbd8b8) ist komplett in ux-texte enthalten | `merge-base --is-ancestor` | verifiziert | GRÜN |
| G4 | `block-d-touch` (Ritter-Tippfix b1d30db) ist als gleicher Patch in ux-texte enthalten. Nur der PROGRESS-Eintrag 7116cdc fehlt | `git cherry` | verifiziert | GRÜN |
| G5 | `block-e-dragdrop` 19987c8 „Namen tauschen per Ziehen“ (names_step.gd +48, player_setup.gd +16, Test +60) ist **nicht** in ux-texte und nicht in main | `git cherry` mit `+` | verifiziert | GRÜN |
| G6 | `content/rolebook-and-guide`: 10 Doku-Commits (29.09.) nirgends eingearbeitet | `git log ux-texte..` | verifiziert | GRÜN |
| G7 | 13 Zweige nicht in main gemergt, 129 gemergt; 51 Worktrees unter `.claude/worktrees`. Alle ohne geänderte versionierte Dateien, nur unversionierte `.uid`/Skripte (z. B. `capture_feedback9_c.gd`) | `git -C <wt> status` | verifiziert | GRÜN |
| G8 | Unversioniert im Hauptordner: `.agents/`, `.codex/`, `.playwright-mcp/`, `AGENTS.md`, `Claude outputs/`, `Grimmhain-Visual-Roadmap/`, `docs/audit/EVENT-ANALYSE.md`, zwei `.uid`, `tools/__pycache__/` | `git status --short` | verifiziert | GRÜN |
| G9 | PROGRESS:24 sagt „ux-texte unverändert“, laut Reflog wurde ux-texte am 16.10. per Fast-Forward auf nacht-regeln gesetzt | `git reflog ux-texte` | kaputt (Doku veraltet) | GRÜN |

## 2 Live-Stand (version.json, heute gelesen)

| Nr | Befund | Beleg | Einstufung | Risiko |
|---|---|---|---|---|
| L1 | `grimmhain-ipad-test` (Produktion): `202610141539-24b58f5` | curl version.json | verifiziert | GELB |
| L2 | `grimmhain-classic-preview`: `202610161155-b69354f` (= HEAD ux-texte), index.pck 23 494 708 Byte | curl, HEAD | verifiziert | GELB |
| L3 | `grimmhain.vercel.app` ist kein Godot-Spiel: Next.js-Seite, `/` leitet auf `/de` um, `version.json` liefert 404 | curl | verifiziert | GRÜN |
| L4 | **Nicht in Produktion:** Speicher-Fix 03583a2, Leicht-Modus 3ae142c/14e89a5/d964272, Classic-Akt, Ritter-Fix, UX-Texte, alle 8 Regel-Fixes vom 16.10. (8b7ef22 … 7e27ecd), Karten hochkant 3d38c19 | `git branch --contains` | verifiziert | GELB |
| L5 | PROGRESS:66 nennt als Vorschau-Alias `14e89a5`, live ist `b69354f`. Der Deploy vom 16.10. 11:55 ist nirgends protokolliert | curl gegen PROGRESS | kaputt (Doku) | GELB |
| L6 | Bypass-Token in Vercel `grimmhain-ipad-test` durch `vercel curl` angelegt, Entfernen offen (PROGRESS:91) | PROGRESS | nur behauptet | GRÜN |
| L7 | Vercel-Aufräumliste (PROGRESS:40–89) ist nur ein Vorschlag, nicht ausgeführt | PROGRESS | offen | GRÜN |

## 3 Liegengelassenes im Code

| Nr | Befund | Fundort | Einstufung | Risiko |
|---|---|---|---|---|
| C1 | 0 TODO/FIXME/HACK/XXX in `godot/`, keine auskommentierten Codeblöcke | rg über godot/**/*.gd, .tscn | verifiziert | GRÜN |
| C2 | Leerer Haken im Regelkern: `on_window_closed` macht nur `pass`, wird aber aufgerufen | `core/rules/card_effects.gd:313`, Aufruf `card_rules.gd:297` | offen | GRÜN |
| C3 | Toter Zweig `if record.cause == CAUSE_LYNCH: pass` | `core/rules/card_fx_solo.gd:230` | offen | GRÜN |
| C4 | 13 Rollen haben im Lexikon einen Eintrag „noch nicht umgesetzt“ (`ui.role.*.lex.open`): faehrtenleser, blutpriester, detektiv, der_weise, zeitwaechter, kutscher, dr_victor_frankenstein, schwarze_witwe, rachsuechtiger_wolf, schicksalswolf, selbstmoerder, hades, grabraeuber | `content/i18n/ui.de.po`, `role_presentation.gd:55` | offen (Inhalt nicht einzeln geprüft) | GELB |
| C5 | Rollenbilder und Porträts als „vorläufig“ markiert | `role_card_art.gd:3`, `portrait_assignment.gd:3` | offen | GRÜN |
| C6 | Asset-Register rot: 14 Mediendateien nicht registriert (z. B. `docs/ux/img/tag-vorher.png`, `urwolf.png`); 224 Einträge „ungeklärt“ | `node tools/check-asset-register.js` Exit 1 | kaputt | GRÜN |
| C7 | Keine übersprungenen Tests im Code. Der Fuzz (3 Tests) läuft nur mit `--merge` | `tools/test-full:15` | verifiziert | GRÜN |

## 4 Rollen (72 Basis, 19 Classic)

Messung per Skript (Katalog `core/rules/role_catalog.gd` ROLES/CLASSIC_ROLES, `ui.de.po`/`ui.en.po`, `assets/cards/de|en`, Testdateien mit Rollen-ID):

| Nr | Befund | Beleg | Einstufung | Risiko |
|---|---|---|---|---|
| R1 | Genau 72 Basis- und 19 Classic-Rollen im Katalog | Skript | verifiziert | GRÜN |
| R2 | Alle 91 haben einen Namen auf Deutsch und Englisch und eine Karte DE und EN (91 Bilder je Sprache), 0 Lücken | Skript | verifiziert | GRÜN |
| R3 | Alle 91 kommen in mindestens 2 Testdateien vor. Am dünnsten: classic-selbstmoerder, classic-wildes-kind, classic-baerenfuehrer (je 2), classic-weisser-wolf, -fuchs, -floetenspieler (je 3), daemonischer-wolf, schicksalswolf (je 4) | Skript | verifiziert (Erwähnung, nicht Tiefe) | GELB |
| R4 | Classic-Rollen sind Parameter auf Basis-Mechaniken (z. B. Seherin = Orakel + `true_role`, Jäger = Sensenträger + `optional_shot`). Jeder Parameter wird im Kern gelesen (`bear` rules_engine:1017, `fox` info_steps, `rusty` classic_rules, `curse_forever` guard_roles, `lone_any` solo_rules) | rg | verifiziert | GRÜN |
| R5 | Oberflächlich nach Absicht: Das Mädchen ist mechanisch nur ein Dorfbewohner, Spionieren gibt es nur als Hinweis (FAEHIGKEITEN.md:21) | Doku + Katalog | verifiziert (bewusste Abweichung) | GRÜN |
| R6 | Englischer Rollenname „The Vile Wolve Father“ (Tippfehler), 6 Stellen | `ui.en.po:9279, 9735, 9762 …` | kaputt | GRÜN |
| R7 | Englische Knöpfe mit 3 Wörtern, gegen die Regel 1–2 Wörter: „Use healing potion“, „Do not heal“ (2), „Read the rule“, „Open final report“ | `ui.en.po:2001, 3214, 6039` | kaputt | GRÜN |
| R8 | Fähigkeit pro Rolle in der Tiefe **nicht** einzeln gelesen (Rollen-Agent durch Netzfehler abgebrochen). Belegt sind nur Existenz, Texte, Karten, Testerwähnung und Classic-Parameter | – | offen | GELB |

## 5 Regelkern

| Nr | Befund | Fundort | Einstufung | Risiko |
|---|---|---|---|---|
| K1 | Siegprüfung: verbindlich erst nach der ganzen Todeskette und ohne offene Abfragen; gleichzeitige Siege wählt die Spielleitung | `win_rules.gd:222-261`, `rules_engine.gd:26`; Tests `test_win_finalize_guard`, `test_role_interactions:592` | verifiziert | GRÜN |
| K2 | Todesketten rekursiv, ein bereits totes Ziel wird übergangen (KILL_IGNORED), Kette durch die Personenzahl begrenzt | `kill_pipeline.gd:19-127` | verifiziert (Code + Tests) | GRÜN |
| K3 | **Notanker** (`wende_05`): Vollstreckung ohne Todesfolgen (kein Jägerschuss, kein Liebestod). Entscheidung KS-79 offen | `card_hooks.gd:173-181` | offen | GELB |
| K4 | Notanker plus Schild oder Wiederbelebung vor dem Fälligkeitstag: Der Tod wird trotzdem vollstreckt oder durch den Schild verhindert, ungeregelt | `card_hooks.gd`, `kill_pipeline.gd:28-45` | offen, ungetestet | GRÜN |
| K5 | **Weißer Wolf ohne Dorf**: Leben nur er und weitere Wölfe, gewinnt niemand, das Spiel läuft weiter | `win_rules.gd:70-74`, `test_classic_bogen.gd:82` | offen (Entscheidung) | GELB |
| K6 | **Wiederbelebungsrunden**: Die Morgenkarte nennt Rolle und Ursache der Toten, obwohl DI-01 das verbirgt. Tests wurden an die Karte angepasst (b1b68c3), die Regel nicht entschieden | PROGRESS:34 | offen | GELB |
| K7 | Wiederbelebung setzt `ability_uses` zurück (Tränke usw. wieder frisch), wie im Decision Log | `role_transition.gd:46-53`, mehrere Tests | verifiziert | GRÜN |
| K8 | Liebespaar + Notanker: `mixed_lovers_last` verlangt zusätzlich `state.alive_ids().size() == 2` und zählt damit den aufgeschobenen Toten als lebend, gegen die Regel in `win_rules.gd:23` | `win_rules.gd:129` (heute gelesen) | offen (vermuteter Fehler, kein Test) | GRÜN |
| K9 | Nur noch Personen mit aufgeschobenem Tod leben: Dorf- **und** Wolfssieg werden gleichzeitig Kandidat | `win_rules.gd:241-261` | offen, ungetestet | GRÜN |
| K10 | Per Totenreichkarte verliehene Classic-Seherin sieht weiter nach Orakel-Art | PROGRESS:33 | offen | GRÜN |
| K11 | Alle tot und eine Puppenspieler-Aufgabe (`loki_09`) offen: Die Aufgabe wartet | PROGRESS:22 | offen | GRÜN |
| K12 | Entscheidungen vom 16.10. (Liebespaar 008d0e3, Grabräuber 7e27ecd) stehen nicht im DECISION-LOG | DECISION-LOG | offen | GRÜN |

## 6 Oberfläche

| Nr | Befund | Beleg | Einstufung | Risiko |
|---|---|---|---|---|
| U1 | Knopftexte in gemalten Leisten: heute `capture_button_fit.gd` bei 1024x768 DE, 108 Knöpfe geprüft, 0 Funde | Lauf heute, Exit 0 | verifiziert (nur Leisten, nur DE, nur 1024x768) | GRÜN |
| U2 | „Rückgängig“ im Tag-Dock bei 1024x768: sitzt im Rahmen, kein Überstand | Screenshot heute `audit-cockpit-tag-undo-1024x768-de.png` | verifiziert | GRÜN |
| U3 | Nicht vermessen: Randlaschen, Kartenfenster, Rollen-Ebenen, Tagesdialoge, Knöpfe in Fenstern ohne Leiste | PROGRESS:164, :170 | offen | GELB |
| U4 | Optionsfenster bei 1024x768 unten abgeschnitten; das Messwerkzeug hat Protokoll und Optionen heute nicht geöffnet (kein Bild) | PROGRESS:172 | offen | GELB |
| U5 | Classic, Neue Partie: Scrollen nötig (B-02 110 px, B-03 Kartentext ragt heraus, B-04 Rollenwahl 8 Personen). Keine Änderung an den Dateien seit 3d92a99 | `git log` auf `round_step.gd`/`act_card.gd` leer | offen | GELB |
| U6 | Karten hochkant gedreht (3d38c19), live in der Vorschau. Oben ist rechts, entgegen dem Wortlaut des Auftrags. Kein echter Touch geprüft | PROGRESS:148-153 | nur behauptet | GELB |
| U7 | Protokoll und Optionen im BotC-Stil: nicht begonnen | PROGRESS:171 | offen | GRÜN |
| U8 | Spracheingabe: Zwischenergebnisse plus Stopp nach 600 ms (f0a84e3). Wartezeit nie gemessen, Safari braucht vermutlich Netz | PROGRESS:176, EVENT-ANALYSE:71 | nur behauptet | GELB |
| U9 | Hochformat: Tippflächen schrumpfen (48 px werden zu 36 pt bei 768x1024). Entscheidung offen | PROGRESS:184 | offen | GELB |
| U10 | Rückgängig nach automatischem Nachtende nimmt zuerst nur das Nachtende zurück (B-05), Entscheidung offen | MORGEN-BERICHT:26 | offen | GELB |

## 7 Leistung iPad

| Nr | Befund | Beleg | Einstufung | Risiko |
|---|---|---|---|---|
| P1 | Kein Messwert stammt von einem iPad. Alles ist Chrome auf Windows oder headless mit Software-GL | PROGRESS:147, :1173 | verifiziert (dass nicht gemessen) | ROT |
| P2 | Speicher im Nachtbild: 4 MB/min vor, 0,7 MB/min nach 03583a2 (Chrome, 240 s) | MORGEN-BERICHT:22 | nur behauptet (heute nicht nachgemessen) | GELB |
| P3 | 03583a2 in Produktion: **nein** (nur ux-texte, nacht-fixes, nacht-regeln; live 24b58f5). In der Vorschau: ja | `git branch --contains`, version.json | verifiziert | GELB |
| P4 | Leicht-Modus: Code vorhanden (`app/platform/perf_mode.gd`), automatisch per `is_touchscreen_available()`. Fix gegen weißen Hintergrund d964272 ist in der Vorschau, aber nie auf einem Gerät gesehen | rg, ancestry | offen | ROT |
| P5 | Messfeld: Code vorhanden (`app/widgets/perf_overlay.gd`, eingebunden `app_shell.gd:76`), nie mit echtem Dreifinger-Tipp geöffnet | PROGRESS:1216 | offen | GELB |
| P6 | Ladezeit: etwa 5 s bis spielbereit, Chrome am PC; Start auf dem iPad nie gemessen | MORGEN-BERICHT:36, EVENT-ANALYSE:57 | nur behauptet | GELB |

## 8 Tests

| Nr | Befund | Beleg | Einstufung | Risiko |
|---|---|---|---|---|
| T1 | `node tools/test-full` (ohne Fuzz) heute auf b69354f: **1550 Tests, 0 fehlgeschlagen, 0 nicht ladbar**, 177 Dateien, 350 s, Exit 0 | Lauf heute | verifiziert | GRÜN |
| T2 | Fuzz (3 Tests) heute nicht gelaufen. Letzter Lauf mit Fuzz laut PROGRESS:24: 1550/3 rot, vor dem Testfix b1b68c3 | – | nur behauptet | GELB |
| T3 | `test_cockpit_polish::test_card_fades_in…` galt als zeitabhängig rot (PROGRESS:99), heute grün | T1 | verifiziert (wackelig) | GRÜN |
| T4 | 178 Testdateien, 1553 Testfunktionen. Der Runner wertet einen Test ohne jede Prüfung als rot (`run_tests.gd:72-74`), leere Tests sind also unmöglich | Agent + Code | verifiziert | GRÜN |
| T5 | Schwache Prüfungen: 1 nie fehlschlagend (`test_core_purity.gd:37` `assert_true(true)`, nur Füllung); 86 Tests mit genau einer Prüfung, davon 2 nur „existiert/sichtbar“ (z. B. `test_role_lexicon_ui.gd:245`, `test_role_preview.gd:154`) | Agent-Stichprobe | verifiziert (Stichprobe) | GRÜN |
| T6 | `tools/test-changed` übersieht Änderungen an Testhelfern (`test-map.json`: `godot/tests/` = []) und an Szenario-JSON; Kernänderungen starten nie die UI-Tests | `tools/test-map.json` | verifiziert | GELB |
| T7 | `test_cards_closing.gd:77` bricht die 24-Seed-Schleife beim ersten leeren Eintrag ab | Code | offen | GRÜN |
| T8 | Headless-grün sagt nichts über Safari, Touch und Aussehen | CLAUDE.md, P1 | verifiziert | ROT (siehe Top 1) |

## 9 Frühere „nicht geprüft“-Hinweise und heutiger Stand

| Nr | Hinweis (Quelle) | Heute | Einstufung | Risiko |
|---|---|---|---|---|
| N1 | iPad/Safari (MORGEN:52, PROGRESS:100, :147, :153, :161, :172, :177, :179, :185, FENSTER-OPTIK:31) | weiter ungeprüft | offen | ROT |
| N2 | Echte Touch-Hardware, Mehrfinger, gedrehte Karte per Touch (MORGEN:53, PROGRESS:153, :185) | ungeprüft | offen | GELB |
| N3 | Echte Bildschirmsperre und Hintergrund-Tab (MORGEN:54) | ungeprüft | offen | GELB |
| N4 | Hörbarkeit der Musik (MORGEN:55) | ungeprüft | offen | GRÜN |
| N5 | Classic im Browser über mehrere volle Runden (MORGEN:56) | ungeprüft | offen | GELB |
| N6 | Sichtprüfung aller Classic-Fenster, Hochformat (MORGEN:57) | ungeprüft | offen | GELB |
| N7 | Drei 404 im lokalen Classic-Export (ladebild, siegel, wortmarke; MORGEN:58) | auf der Vorschau nicht nachgeprüft | offen | GELB |
| N8 | Nachtaktionen, Hexe, Jäger, Tag-Abstimmung und Spielende per Touch (PROGRESS:185; UX-AUDIT:77) | ungeprüft | offen | GELB |
| N9 | Wartezeit der Spracheingabe mit echtem Mikrofon (PROGRESS:176) | ungeprüft | offen | GELB |
| N10 | Screenshots „Karte zeigen“ Hexe/Seherin (PROGRESS:138, :152) | fehlen | offen | GRÜN |
| N11 | Orakel-Absturz „nicht nachgestellt, Ursache unbekannt“ (EVENT-ANALYSE:55) | keine spätere Klärung gefunden | offen | GELB |
| N12 | Vollsuite nach UX-Texten und F-17 bis F-24 (PROGRESS:177, :179) | heute erledigt durch T1 | verifiziert | GRÜN |
| N13 | Urheber der 11 Classic-Kreisbilder unbekannt (PROGRESS:208) | offen | offen | GRÜN |
| N14 | Sichtschutz-Bild nicht angeschlossen; Bilder für Scrollbalken und Lautstärkeregler fehlen (FENSTER-OPTIK:56, :70-77) | nicht nachgeprüft | nur behauptet | GRÜN |
| N15 | HOTFIX.md:3, :11 sagen „nicht deployt“, live ist 24b58f5 | veraltet | kaputt (Doku) | GRÜN |
| N16 | MORGEN-BERICHT B-07 (Liebespaar-Sieg offen) | durch 008d0e3 erledigt, Bericht veraltet | kaputt (Doku) | GRÜN |

## Nicht erreicht (Zeitgrenze / Ausfall)

- Fähigkeiten nicht Rolle für Rolle im Code gelesen (R8). Der Rollen-Agent brach durch einen Netzfehler ab. Ersatz: Skript für Existenz, Texte, Karten und Testerwähnung.
- Optionsfenster bei 1024x768 nicht selbst aufgenommen (U4). Englisch und 1180x820 nicht vermessen.
- Fuzz nicht gelaufen (T2).
- Keine Messung im Browser gegen die Live-Seiten: weder Speicher noch Ladezeit noch Konsole.
- Vercel-Einstellungen (Bypass-Token, Aufräumen) nicht angesehen; nur `version.json` und Header gelesen.
- Inhalt der 13 Lexikon-Einträge „noch nicht umgesetzt“ nicht einzeln mit dem Code abgeglichen.
