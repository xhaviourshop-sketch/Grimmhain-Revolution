# Grimmhain: Abschlussmatrix der Spielfunktionen

**Stand:** 29.09.2026 · Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui` · Branch `feature/night-ui-expansion` · Ausgangs-HEAD `23c7044` (PR #3 offen) · Godot `4.7.2.stable.official.ed1daf0bf` · Schema 13, Regelversion 0.12

**Aktualisierung nach Paket 2 (29.09.2026):** Schema 14, Regelversion 0.12 unverändert. B-01 behoben (Testlebenszyklus), S-08 und N-06 umgesetzt und headless nachgewiesen, Vollsuite 956 Tests. Betroffene Zeilen sind unten gekennzeichnet; historische Angaben zum Ausgangsstand bleiben stehen.

**Aktualisierung nach Paket 3 (29.09.2026):** R-02 alle 71 Rollen über echte Controls nachgewiesen (`test_role_buttons`, `test_role_passive_ui`, Bedienarten in `test_role_operation_kinds`), N-11 um acht feste Szenarien ergänzt, R-07 analysiert (`docs/role-migration/12-role-combination-analysis.md`), I-04 Positivlisten aller zwölf Informationsrollen geprüft. Ein Fehler behoben: Stimmhinweise (RM-DR-008) wurden nicht angezeigt. Headless, keine Geräteabnahme.

**Aktualisierung nach Paket 4 (29.09.2026):** Wiederaufnahme über den echten Bedienweg (`test_resume_scenarios`, neun Unterbrechungsstellen), Neustart nach jedem Befehl gemischter Partien (`test_resume_every_command`) und echter Prozessneustart (`test_process_restart`). Zwei Fehler behoben (B-04 Datenverlust bei zwei aufeinanderfolgenden Speicherfehlern, B-05 falsche Zusage „ist gespeichert“ beim Beenden), Button „Erneut speichern“, Positivlisten für Speicherübersicht, Statusmeldungen und öffentliche Cockpit-Sicht (I-06). Schema 14, Regelversion 0.12 unverändert. Vollsuite 1048 Tests. Offen bleiben die Produktentscheidungen D-04, D-05, I-03 sowie R-06 und die Setup-Regel zu R-07.

**Aktualisierung nach dem Restpaket (29.09.2026):** Paket 4 bleibt „automatisierte Prüfungen abgeschlossen, Produktentscheidungen offen“ (D-04, D-05, I-03), keine vollständige Abnahme. R-06 umgesetzt und nachgewiesen. B-06 behoben (mobiles Zurück und Desktop-Fensterschließen umgingen die Warnung bei ungespeichertem Stand). Vollsuite 1059 Tests.

**Aktualisierung nach den Produktentscheidungen PE-01 bis PE-04 (29.09.2026):** I-03 umgesetzt (öffentliche Hinweiszeile neutral, `test_public_reaction_hint`), R-07 um die beiden beschlossenen Setup-Hinweise ergänzt (`test_setup_hints`), D-04 und D-05 durch PE-02 und PE-03 entschieden (Ist-Stand ist die Vorgabe), gesperrter Zufallsknopf zusätzlich über die Oberfläche geprüft (`test_random_pick::test_disabled_random_button_without_admissible_result`). Schema 14, Regelversion 0.12 unverändert. Vollsuite 1072 Tests. Keine Geräteabnahme.

**Aktualisierung nach Paket 5a (29.09.2026):** D-09 umgesetzt (Geräteeinstellungen dauerhaft in `user://settings.json`, `test_settings_persistence`), B-02 behoben. C-01 und R-08 um den strukturellen DE/EN-Prüfer `tools/check-godot-i18n.js` mit eigenem CI-Workflow ergänzt (Q-07). I-03 von AUTO auf TEIL berichtigt: Die Hinweiszeile ist neutral, der Rückschluss aus der öffentlichen Phase „Morgen“ und der Kartenfolge bleibt offen. D-10 unverändert offen (gespeicherter Wert ohne Wirkung). Schema 14, Regelversion 0.12 unverändert. Vollsuite 1081 Tests. Keine Geräteabnahme.

**Aktualisierung nach Paket 5b (29.09.2026):** C-04 von FEHLT auf TEIL: Rollenlexikon für alle 71 Katalogrollen im Programm (Hauptmenü, Setup, Cockpit), DE/EN, gegen bestätigte Regeln geprüft, redaktionelle Endabnahme ausstehend, 15 Rollen mit gekennzeichneten offenen Punkten. C-05 von FEHLT auf TEIL: kontextbezogene Hilfe zur aktuellen Handlung umgesetzt, allgemeines Regelbuch und Handlungszeilen (OI-18) fehlen. N-08 um PE-05 ergänzt (Quellrolle bei Liebeskummer, Kette, Verknüpfung). Neu N-12 (PE-06, entschieden, nicht umgesetzt). C-01 um die vollständige Prüfung der Lexikonschlüssel ergänzt. Schema 14, Regelversion 0.12 (DA-54). Vollsuite 1096 Tests. Keine Geräteabnahme.

Diese Matrix ist Paket 1 von `CODE-COMPLETION-ROADMAP.md`. Sie ordnet jede noch relevante funktionale Anforderung des Masterplans einem Code-, Test- und Paketbeleg zu. Sie implementiert nichts und ändert keine Regel.

## Wie diese Matrix zu lesen ist

**Belegregel.** Code und ausgeführte Tests stehen über Dokumentation. Wo Dokumente und Code sich widersprechen, steht der Widerspruch unter „Befunde“. „Nicht gefunden“ bedeutet hier: mit `rg` in `godot/app`, `godot/core`, `godot/content` und den Tests gesucht, nichts gefunden. Erst nach dieser Suche steht `FEHLT`.

**Status** (genau eine Stufe je Zeile):

| Kürzel | Bedeutung |
|---|---|
| `AUTO` | Implementiert und automatisch nachgewiesen |
| `NACHWEIS` | Implementiert, Nachweis unvollständig |
| `TEIL` | Teilweise implementiert |
| `FEHLT` | Nicht implementiert (nach Untersuchung) |
| `BLOCKIERT` | Durch Regelentscheidung blockiert |
| `GERÄT` | Geräte- oder Infrastrukturprüfung ausstehend |
| `SPÄTER` | Ausdrücklich später vorgesehen |

**Abschlussstufe:** Offline, Karten, Clients, Plattform, Online (späteres Online-Spiel).

**Pakete:** P2 bis P11 verweisen auf `CODE-COMPLETION-ROADMAP.md`. „P1“ ist dieses Dokument. `neu` heißt: Die Roadmap hatte diese Anforderung nicht namentlich; sie wurde in das genannte Paket einsortiert.

**Grenzen der Belege.**

- Alle Tests laufen headless. Sie beweisen weder Darstellung noch Touch noch Tablet-Verhalten. `GERÄT` bleibt für jede Bedienfläche offen, bis Nutzerinnen oder Nutzer sie am Gerät abnehmen.
- Ein Test, der Kartendaten an `GameSession` gibt (`test_prompt_coverage`), beweist keinen Buttonweg. In der Rollentabelle steht deshalb `K` (Kartendaten) getrennt von `B` (Button-Test).
- Rot oder grün eines Tests sagt nichts über Regeln, die nie getestet wurden.

## Matrix der Funktionen

### Setup und Start

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| S-01 | 6 bis 24 Personen: Namen einzeln und per Textimport, Validierung | Offline | AUTO | `app/setup/player_setup.gd`, `person_name_rules.gd`, `screens/new_game/player_step.gd` | `test_setup_model`, `test_setup_screen`, `test_player_count_range` (Unit) | Tablet-Eingabe (Bildschirmtastatur) ungeprüft | P11 | Gerät |
| S-02 | Gespeicherte Gruppe anbieten und wiederverwenden | Offline | FEHLT | Suche `saved_group`, `Gruppe`, `roster` in `app/`: kein Treffer; kein `user://`-Pfad außer `saves` | keiner | Speichern, Auswählen, neue Personen-IDs je Partie, keine alte Rolle/Markierung übernehmen | P7 | keine Entscheidung nötig; Datenformat wird technische Ableitung |
| S-03 | Rollenwahl: Vorschlag, manuell, zufällige/manuelle Verteilung, Scheinrolle des Trugbilderwolfs | Offline | AUTO | `app/setup/role_suggestion.gd`, `role_distribution.gd`, `decoy_section.gd` | `test_role_model`, `test_distribution_model/_step`, `test_decoy_model/_step` | keine | - | - |
| S-04 | Szenariobasierte Rollenwahl (Rollenliste, Regeln je Szenario) | Offline | FEHLT | Suche `scenario`, `szenario` in `app/`, `core/`, `.po`: kein Treffer | keiner | Szenariodefinitionen und ihre Validierung gegen Rollen-IDs, Personenzahl, Kompositionsregeln | P7 | **Nutzerentscheidung:** Inhalt der Szenarien (Rollenlisten). Keine Szenarioregeln erfinden |
| S-05 | Sitzordnung im Kreis, Tausch per Drag-and-drop/Antippen, Zustand an Personen-ID | Offline | AUTO | `app/setup/seating_draft.gd`, `seating_step.gd`, `widgets/seat_ring/` | `test_seating_model`, `test_seating_step`, `test_player_identity` (Unit) | Touch nur mit simulierten Mausereignissen | P11 | Gerät |
| S-06 | Sitzplatztausch nach Spielstart (`ReorderSeats`, AS-S03) | Offline | FEHLT | `core/commands/command.gd` kennt den Befehl nicht; Spec `implementation-boundary.md` B-11 | keiner | Befehl, Regelkern-Wirkung auf Sitznachbarn (Kutscher, Wächter, Nachtwächter, Doktor), UI | P7 (neu) | **Nutzerentscheidung:** Ist Tausch während der Partie gewollt? Er verschiebt die Nachbarn im Regelkern |
| S-07 | `StartGame` aus bestätigtem Setup; Wiederbelebungsrunde abgeleitet (DI-01) | Offline | AUTO | `app/session/game_start.gd`, `core/rules/rules_engine.gd` | `test_game_start_model/_step`, `test_revival_round` | keine | - | - |
| S-08 | **Erledigt in Paket 2 (Schema 14, `roles_shown`, `role_shown_rules.gd`, Ebenen in `cockpit_layers.gd`; Nachweis `test_role_shown`, `test_role_show`); Geräte- und Touchabnahme offen (GERÄT).** Rollenübergabe an Spieler („Rollen zeigen“): neutrale Karte, bewusste Aktion, Rolle nur für die Person, schließen, `ConfirmRoleShown`, Fortsetzung bei der ersten unbestätigten Person | Offline | AUTO | `ConfirmRoleShown` existiert in keinem `.gd`, nur in Spec (`vertical-slice-flow.md` §2, B-11) und Doku. Das Cockpit zeigt Rollen nur dem Spielleiter (privater Bereich) | keiner (AS-A04 hat keinen Test) | Befehl und Zustand im Kern, Rollenkarte, Abbruch-Fortsetzung, Trugbilderwolf: Karte trägt keine Scheinrolle (DI-08) | **P2** | Schema-Bump 13 auf 14 würde alte Saves erneut sperren; oder Bedienzustand nur in der App. Bewusste Aktion statt Halten (Halten ist ohne Gerät nicht prüfbar) als technische Ableitung. Kurze Nutzerbestätigung zu Schema |

### Spielablauf

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| N-01 | Nacht: Plan, `BeginStep`, Prompt-Karte für alle Antwortarten, Überspringen mit Begründung, Abbruch | Offline | AUTO | `core/rules/step_queue.gd`, `app/session/prompt_view.gd`, `screens/cockpit/action_card.gd` | `test_cockpit_model`, `test_cockpit_screen`, `test_full_round_ui`, `test_steps`, `test_gm_open_prompt` | Buttonweg je Rolle nicht einzeln belegt (siehe R-02) | P3 | - |
| N-02 | Morgenauflösung, offene Reaktionen, Morgenbericht öffentlich/privat getrennt | Offline | AUTO | `app/session/morning_report.gd`, `core/model/reaction.gd` | `test_morning_report`, `test_reactions`, `test_cockpit_screen`, `test_public_reaction_hint` | Hinweiszeile neutral (PE-01, siehe I-03); Phase „Morgen“ und verdeckte Karte bleiben als Rückschlussweg | P4 | - |
| N-03 | Tag: Nominierung Quelle→Ziel, Hinrichtung mit verdeckter Prüfkarte, Tagesaktionen; keine digitale Stimme | Offline | AUTO | `app/session/cockpit_view.gd`, `core/rules/execution_rules.gd` | `test_cockpit_day`, `test_gm_execute`, Szenarien `as-c11`, `as-c12`, `dr-03` | keine | - | - |
| N-04 | Sieg: Kandidaten erkennen, Spielleiter bestätigt oder lehnt ab | Offline | AUTO | `core/rules/win_rules.gd`, `action_card.gd` | `test_win_status`, `test_win_finalize_guard`, `test_cockpit_day::test_win_candidate_is_covered_then_confirmed`, `test_full_round_ui` | keine | - | - |
| N-05 | Spielleiterkorrekturen in der Oberfläche: Person töten, wiederbeleben, Rolle ändern, Status (Nominierung, Tränke, Spiegelung, Scheinrolle), Hinrichtung ohne Nominierung, Sieger erklären | Offline | AUTO | `core/rules/gm_corrections.gd`, `cockpit_layers.gd`, `cockpit_screen.gd` | `test_cockpit_gm`, `test_gm_correction`, `test_gm_role_field` | keine für diese Arten | - | - |
| N-06 | **Erledigt in Paket 2 (12 Arten über „Status ändern“, `cockpit_view.special_fields`; Nachweis `test_special_corrections`); Geräteabnahme offen.** Korrekturen Schutz, Rettung, Wolfskind, Lehrling in der Oberfläche | Offline | AUTO | Kern kennt 11 Arten (`gm_corrections.gd`: `set_protection`, `set_rescue`, `set_wolf_model`, `set_apprentice_master` u. a.); Oberfläche bietet `kill, revive, set_role, status, execute, declare_winner` (`cockpit_layers.gd:190`) | Kern: `test_gm_correction`; UI: keiner (`cockpit.md` nennt die Lücke selbst) | Bedienung mit Grund, Warnung, Protokoll; Abbruch offener Prompt; Undo/Reload | **P2** | keine Entscheidung; Kernbefehle bestehen |
| N-07 | Aufrufpolitik und Tarnaufrufe (DI-02) | Offline | AUTO | `core/rules/call_policy.gd` | `test_call_policy`, `test_call_presentation` | keine | - | - |
| N-08 | Öffentliche Ansage von Todeseffekten mit Rolle zum Ereigniszeitpunkt (DI-03); bei Liebeskummer, Kette und Verknüpfung die Quellrolle (PE-05, Paket 5b) | Offline | AUTO | `GameEvent DeathEffect`, `KillPipeline.PUBLIC_EFFECTS`, `morning_report.gd` | `test_death_effects`, `test_death_effect_lines` | Länge des Fluchs des Weisen nicht genannt (DA-23, zu bestätigen) | - | - |
| N-09 | Private Hinweiskarten: Loki, Rattenfänger, Pestbringerin, Rotkäppchen, Trugbilderwolf (DI-04 bis DI-08) | Offline | AUTO | `core/rules/notice_rules.gd`, `AckNotice`, `cockpit_layers.gd` | `test_notices`, `test_notice_cards` | keine | - | - |
| N-10 | Rollenaufdeckung beim Tod nur in Runden ohne Wiederbelebung | Offline | AUTO | `SeatDied.role_id`, `morning_report.gd` | `test_morning_report` | keine | - | - |
| N-12 | Schritt „Alle Verzauberten“ nach jedem Aufruf des Rattenfängers, auch Tarnaufruf, solange es lebende Verzauberte gibt (PE-06) | Offline | AUTO | eigener Nachtschritt `piper-all` (`StepQueue`, `CallPolicy`, `InfoSteps`), Hinweis `piper_new` davor, private Karte der Spielleitung, Regelversion 0.13 (DA-60 bis DA-64) | `test_piper_all` (Reihenfolge, Tarnaufruf, Ausfall, Einfrieren, Blockade, Speichern/Laden, veraltete Bestätigung), `test_piper_all_ui` (Bedienweg, Tarnaufruf, Doppeltippen), `test_resume_scenarios` (Neustart an fünf Stellen, Rückgängig/Wiederholen) | keine Geräteabnahme; Grabräuber mit gestohlenem Rattenfänger nur abgeleitet, nicht eigens getestet | - | PE-07 (Mehrfachrollen) offen, betrifft Setup |
| N-11 | **Ergänzt in Paket 3.** Rollen mit Schutz-, Wiederbelebungs-, Umlenkungswirkung gegeneinander (Todespipeline, Ketten, Reihenfolge) | Offline | AUTO | `core/rules/kill_pipeline.gd`, `protections.gd`, `role_transition.gd` | `test_role_interactions` (19, davon 8 neu: Puppe als Dorfwache, gegenseitige Verknüpfung, Wirt mit Puppe, vier Siegkandidaten, öffentliche Todesrolle, Liebeskummer vor Reaktion mit Laden, Kutscher setzt Einsätze zurück, Seelentausch mit Scheinrolle), Familien-Unit-Tests (Zuordnung `docs/role-migration/11-role-audit-status.md` §4.2), Fuzz unabhängig vom globalen Zufall | Keine bekannte ungeprüfte Mechanikfamilie; keine Garantie für alle Paare | P3 erledigt | - |

### Rollen

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| R-01 | 71 Rollen im Regelkern | Offline | AUTO | `core/rules/role_catalog.gd` (71 Einträge), Regeldateien | je Rolle ein Einzeltest plus `test_role_interaction_fuzz` (alle 71) | keine | - | - |
| R-02 | **Nachgewiesen in Paket 3.** Alle 71 Rollen über die Oberfläche bedienbar (Buttonweg) | Offline | AUTO | `action_card.gd` für alle Antwortarten, Treiber `tests/ui/role_ui_case.gd` (nur Sitzplätze, Kartenbuttons, Dialog) | 45 aktive Rollen je ein festes Szenario mit Ereignis- und Zustandsprüfung (`test_role_buttons`); 12 passive und Morgenbericht-Rollen über ihren Auslöser (`test_role_passive_ui`); frühere Button-Tests für 14 weitere; Bedienarten, Abbruch, Doppeltippen, Undo, Rollenwechsel (`test_role_operation_kinds`); Invarianten Überspringen/Verzicht/Abbrechen bei jeder Karte | Geräte- und Touchabnahme (GERÄT); Zufallsknopf R-06 | **P3** erledigt | - |
| R-03 | Kartenschlucker (72. Rolle) | Karten | BLOCKIERT | nicht im `RoleCatalog`, im Setup nicht wählbar | keiner | Totenkartenmodell (RM-DR-013, RM-DR-143.1/.2) | P8 | **Nutzerentscheidung:** Kartenregeln (drei Auswahlfragen plus Freitext, siehe P8) |
| R-04 | Totenkarten / Totenkarten-Assistent (Ziehen, Besitz, Tausch, Verbrauch) | Karten | BLOCKIERT | keiner; `docs/ui/cockpit.md`: „Totenreichkarten sind nicht definiert“ | keiner | gesamtes Kartenmodell | P8 | **Nutzerentscheidung**, gleiche wie R-03 |
| R-05 | Frankenstein: Totenkarten-Bedingung | Karten | BLOCKIERT | Wiederbelebung bedienbar; Bedingung RM-DR-141.4 wird nicht geprüft; privater Bereich weist darauf hin | `test_revival_roles` (Wiederbelebung) | Bedingung fehlt | P8 | hängt an R-04 |
| R-06 | **Umgesetzt im Restpaket (29.09.2026).** Zufallsknopf nach RM-DR-015.2 (König, Traumdeuter, Kopfgeldjäger, Blutpriester-Aufdeckung) | Offline | AUTO | `InfoSteps.random_choice` (Vorschlag aus Kopie des gespeicherten Generators, alle zulässigen Ergebnisse stabil aufgezählt, eine Ziehung), `Command.answer_random` (Kern zieht erneut, nur exakt dieses Ergebnis gilt, übernimmt den Generatorfortschritt), Button „Zufällig auswählen“ | `test_info_roles` (zulässiger Raum, eine Ziehung, Gleichverteilung, manipuliert/veraltet abgelehnt, nicht für andere Rollen und die Opferwahl), `test_random_pick` (je Rolle Buttonweg, Doppeltippen, Vorschau ohne Wirkung, manuelle Änderung ohne Ziehung, Laden, Replay, Rückgängig, Abbrechen, keine öffentlichen Daten); manuelle Wahl `test_role_buttons` | Geräte- und Touchabnahme; Spielleitertexte der vier Rollen (OI-09, Paket 5) | P3 erledigt | entschieden (RM-DR-015.2), technische Ableitungen DA-42 bis DA-45 |
| R-07 | **Analysiert in Paket 3, Setup-Hinweise nach PE-04 umgesetzt (29.09.2026).** Unverträgliche Rollenkombinationen: nicht blockierende Hinweise im Rollenschritt | Offline | AUTO | `docs/role-migration/12-role-combination-analysis.md`; `RolePoolDraft.hints`, `RoleStep` (`CoachHintLabel`, `SoloWinsHintLabel`) | feste Szenarien D-1 bis D-9; `test_setup_hints` (Schwelle 12/13, Kontrollbesetzungen, beide Hinweise, sofortige Aktualisierung, StartGame unverändert), `test_role_step::test_role_step_layout` | Nur die beiden beschlossenen Hinweise (C-1 Kutscher unter 13 Personen, C-3 mindestens zwei aus Parasit/Voodoo-Priester/Grabräuber/Manipulator); C-2 und C-4 ohne Hinweis. Keine Geräteabnahme | P3 | - |
| R-08 | Regel-Linter (fehlende IDs, Texte, Nachtprioritäten, Tests) | Offline | TEIL | `test_role_model::test_presentation_has_every_role_in_both_languages`, `test_ui_i18n`, `tools/check-godot-i18n.js` (Rollen-IDs aus `role_catalog.gd` gegen `ui.role.<id>.name/.short`, CI), `tools/role-migration/check-role-docs.js` (nur lokal) | siehe Q-03 | Ein Prüfer für Nachtpriorität gegen Test je Rolle fehlt | P6 | - |

### Informationsschutz

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| I-01 | Cockpit-Sichten ohne Rollen; geheime Ebenen entstehen erst beim Öffnen, verschwinden beim Schließen/Sichtschutz | Offline | AUTO | `cockpit_view.gd`, `cockpit_layers.gd` | `test_cockpit_screen` (`_assert_no_roles`), `test_cockpit_model` | keine | - | - |
| I-02 | Öffentliche Ereignisse ohne Rollen-, Ursachen- und Informationsdaten | Offline | AUTO | `core/model/visibility.gd` | Fuzz-Invariante in `test_role_interaction_fuzz`, `test_death_effect_lines`, `test_morning_report` | keine | - | - |
| I-03 | Offene Reaktion für Mitlesende nicht erkennbar | Offline | TEIL | **Teil 1 umgesetzt nach PE-01 (29.09.2026), Status in Paket 5a von AUTO auf TEIL berichtigt:** `CockpitView.warnings` ohne Anzahl, Art oder Besitzer; außerhalb der Nacht bei jeder verdeckten Karte (Reaktion, Prompt, Siegentscheidung, Hinweis) derselbe Text je Phase (`cockpit.md`) | `test_public_reaction_hint` (drei unterschiedliche Reaktionen gleich, Tagestext, Siegentscheidung ohne Reaktion gleich, private Karte vollständig, DI-03-Ansage, Laden und Rückgängig, Label DE/EN) | **Offen (Teil 2):** Die öffentliche Phase bleibt „Morgen“, solange eine Reaktion offen ist (der Kern verlässt die Morgenauflösung erst danach), und statt des Morgenberichts erscheint eine verdeckte Karte. Mitlesende können daraus auf eine offene Reaktion schließen. DA-46 dokumentiert diese Grenze; sie ist keine ausdrückliche Nutzerfreigabe. Behebung verlangt eine Änderung an öffentlicher Phase oder Kartenfolge (eigener Auftrag, Kern und UI). Handlungen am Tisch und Bedienzeit bleiben ohnehin erkennbar | P4 (Rest) | Umfang der Behebung klären (Kernphase oder nur Darstellung) |
| I-04 | **Nachgewiesen in Paket 3.** Zeigekarte für Informationsrollen zeigt nur Positivliste | Offline | AUTO | `cockpit_layers.gd` (gezeigte Karte) | Orakel (`test_cockpit_screen`), zwölf weitere Informationsrollen (`test_role_operation_kinds::test_show_cards_contain_only_the_positive_list`: nur Personen und Rollen aus `show`), Hinweiskarten, Morgen | - | P3 erledigt | - |
| I-06 | **Nachgewiesen in Paket 4.** Positivlisten weiterer Ausgabewege: Speicher-/Fortsetzen-Übersicht (Zusammenfassung, Listeneintrag, Dateihülle), Statusmeldungen (nur feste Schlüssel ohne Platzhalter), öffentliche Cockpit-Sicht und Sitzplätze nach Laden und Rückgängig | Offline | AUTO | `GameSession.summary`, `SaveService.list`, `ToastHost.show_message(text_key)`, `CockpitView.build` | `test_output_positive_lists` (Testdaten: Scheinrolle, Loki-Bindung und Hinweise, Schutz, Angriff); Neustart öffnet keine private Ebene (`test_resume_scenarios`) | Spielleiterbereich und Protokoll zeigen bewusst alles (nur nach ausdrücklichem Öffnen, I-01); kein Export (C-09) | - | - |
| I-05 | Einzelne Spielerkarte je Person (Rolle, Nachtaktion) getrennt vom Gesamtzustand | Clients | FEHLT | keine Projektion pro Person außer Cockpit-Sicht und Hinweiskarte | keiner | Spielerprojektion (Masterplan Phase 5) | P9 | siehe L-02 |

### Speichern, Wiederaufnahme, Undo

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| D-01 | Speichern nach jedem Befehl, atomar (`.tmp`, `.bak`), Fortsetzen mitten im Prompt, bei offener Reaktion | Offline | AUTO | `app/session/save_service.gd` | `test_save_service` (unterbrochenes Schreiben an jedem Schritt), `test_save_load`, `test_replay`; **Paket 4:** `test_resume_scenarios` (neun Unterbrechungsstellen über den Fortsetzen-Bildschirm), `test_resume_every_command` (Neustart nach jedem Befehl, sechs Mischpartien), `test_process_restart` (zweiter Godot-Prozess) | keine (Speicherort/Rechte am Gerät: siehe D-08) | - | - |
| D-02 | Fehlerfälle: beschädigte Datei, beschädigtes Backup, unvollständige `.tmp`, Sicherung wird nie überschrieben; **Paket 4:** zwei aufeinanderfolgende Fehler (B-04), nicht anlegbares Verzeichnis, wiederholtes Laden | Offline | AUTO | `save_service.gd` (Umbenennen statt Löschen, offene `.tmp` vor dem Schreiben einsetzen) | `test_save_service`, `test_corrupt_save` | keine | - | - |
| D-03 | Ältere Schema-/Regelversionen: Sperre, Datei erhalten, keine Migration | Offline | AUTO | `StateCodec`, `save_service.gd` | `test_save_versions`, `test_save_service` | keine (Absicht) | - | - |
| D-04 | Checkpoint-Rotation über eine Sicherung hinaus, Reparaturdialog | Offline | AUTO | eine `.bak` je Partie; automatischer Rückfall auf die Sicherung mit Hinweis. **Entschieden durch PE-02 (29.09.2026): eine Sicherung reicht**, mehrere Stände frühestens als spätere Komfortfunktion | `test_save_service` | Rotation: keine (PE-02). Ein eigener Reparaturdialog ist nicht Teil von PE-02 und nicht gebaut; beschädigte Dateien fallen automatisch mit Hinweis auf die Sicherung zurück. Geräteprüfung des Speicherorts gesondert | P4 | Reparaturdialog nur auf ausdrücklichen Wunsch |
| D-05 | Undo/Redo mit Klartext, über Replay; Undo nach Neustart | Offline | AUTO | `game_session.gd` (Replay), `cockpit_layers.gd` | `test_undo` (7 Tests), `test_cockpit_day::test_undo_drops_open_execution_check` | **Entschieden durch PE-03 (29.09.2026): Wiederholen entfällt beim Neustart** (Spec B-12 entsprechend angepasst) | P4 | - |
| D-06 | Persistente Ereignisse und lesbare Rundenchronik | Offline | TEIL | Befehle gespeichert, Ereignisse per Replay; Protokollebene im Cockpit (privat) | `test_cockpit_screen` (Protokoll) | keine öffentliche Rundenchronik, kein Export (siehe C-09) | P7 | - |
| D-07 | Speicherfehler sichtbar, kein stiller Neustart; **Paket 4:** „Erneut speichern“ (ein Versuch je Tippen), Warnung beim Beenden, Rückfallmeldung nennt den älteren Stand; **Restpaket:** Warnung auch bei mobilem System-Zurück und Desktop-Fensterschließen (B-06) | Offline | AUTO | Statusanzeige „Fehler: nicht gespeichert“, `RetrySaveButton`, `AppShell.request_quit` | `test_save_service`, `test_cockpit_screen` | keine | - | - |
| D-08 | Speicherort, Schreibrechte, App-Beendigung durch das System | Plattform | GERÄT | `user://saves` | nur isolierte Testverzeichnisse `user://test-saves-*` | echtes Gerät | P10 | Gerät |
| D-09 | **Umgesetzt in Paket 5a (29.09.2026).** Einstellungen dauerhaft (Sprache, Bewegung reduzieren) | Offline | AUTO | `app/settings/settings_store.gd` (`user://settings.json`, getrennt von `user://saves`; `.tmp` prüfen, `.bak`, Rückfall auf `.bak`), `AppContext.use_settings_store`, Laden in `AppShell._enter_tree` vor der ersten Ansicht, Fehlermeldung im Einstellungsscreen | `test_settings_persistence` (9 Tests: Erststart, echte Controls, neue App-Instanz, Sprache vor erster Ansicht, ungültige Werte einzeln, defekte Datei, Laden ohne Schreiben, Schreibfehler an vier Stellen, Partie unberührt) | echtes Gerät (Speicherort, Rechte, siehe D-08) | P10 (Gerät) | - |
| D-10 | Einstellung „Linkshänder“ | Offline | TEIL | `AppSettings.left_handed` (Variable), Kommentar „noch ohne Wirkung“; kein Schalter in `settings_screen`, `.po` nennt „folgen später“. Seit Paket 5a wird der Wert mitgespeichert; das ist kein Linkshändermodus | `test_settings_persistence` (nur Speichern des Werts) | Schalter ohne Wirkung zählt nicht (Roadmap P5) | P5 | **Nutzerentscheidung:** Umfang jetzt oder zum Gestaltungsprojekt |

### Inhalte, Texte, Modi

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| C-01 | DE/EN: gleiche Schlüsselmenge, keine Literaltexte, Sprachwechsel; **Paket 5a:** Duplikate, leere und fuzzy Einträge, Platzhalter, Schlüssel im Quelltext, Rollengruppe | Offline | AUTO | `content/i18n/ui.de.po`, `ui.en.po` (je 1830 Schlüssel); `tools/check-godot-i18n.js` (seit Paket 5b auch jedes Lexikon-Pflichtfeld je Katalogrolle, keine Einträge für unbekannte Rollen oder Felder) | `test_ui_i18n` (6 Tests); `node --test tests/check-godot-i18n.test.js` (18 Tests), Prüfer Exit 0; `test_role_lexicon_content` | Bedeutungsgleichheit ungeprüft; 49 dynamische Schlüsselvorlagen nur als Vorlage prüfbar (mindestens ein Treffer), Platzhalterwerte aus Variablen/`format_values` nicht statisch prüfbar | P5 | redaktionelle Prüfung |
| C-02 | Rollenname und Kurztext je Rolle (71 mal 2) | Offline | AUTO | `ui.role.<id>.name/.short` | `test_role_model::test_presentation_has_every_role_in_both_languages` | Kurztext ist keine Regelbeschreibung | - | - |
| C-03 | Vorlesetext und Anweisung je Nachtrolle | Offline | AUTO | `ui.call.*` (51), `ui.prompt.*` (115) | `test_prompt_coverage` (eigene Anweisung statt generischem Rückfall je Kombination) | keine | - | - |
| C-04 | Rollenlexikon im Programm: Fähigkeit, Ziele, Grenzen, Zeitpunkt, Spielleiteranweisung für 71 Rollen | Offline | TEIL | **Integriert in Paket 5b (29.09.2026):** `app/widgets/role_lexicon/role_lexicon.gd` (Suche, Fraktionsfilter, leerer Zustand, scrollbarer Eintrag, Sprachknopf), Ansicht `lexicon` (Hauptmenü), Ebene im Setup (Knopf „Regeln“ je Rollenzeile) und im Cockpit (Werkzeug „Lexikon“); Texte `ui.role.<rolle>.lex.*` (9 Felder je Rolle, `open` bei 14 Rollen, Rattenfänger seit PE-06 ohne offenen Punkt), gegen Decision Log, Kern und Tests geprüft (DA-56, DA-58) | `test_role_lexicon_content` (parametrisiert über `RoleCatalog.ROLES`, DE/EN gerendert), `test_role_lexicon_ui`, Prüfer `check-godot-i18n.js`, `check-coverage.py` OK | redaktionelle Endabnahme ausstehend; offene Punkte je Rolle im Feld „Noch nicht geklärt oder umgesetzt“ (`INTEGRATION-STATUS.md`); keine Geräte- oder Touchabnahme | P5 | **Nutzerentscheidung:** redaktionelle Endabnahme der Texte |
| C-05 | Regelbuch und kontextbezogene Hilfe | Offline | TEIL | **Kontexthilfe in Paket 5b:** „Regel nachlesen“ auf der privaten Cockpitkarte (Schritt, Prompt, Hinweis) öffnet den allgemeinen Eintrag der handelnden Rolle; Auswahl bleibt, kein Befehl (DA-57). GUIDE-TEXTS §3.3/§3.4 an `ui.call.*`/`ui.effect.*` angeglichen | `test_role_lexicon_ui` (offene Auswahl, Fingerabdruck von Befehlen, Protokoll und Zustand, Sichtschutz, gezeigte Karte, verdeckte Karte) | allgemeines Regelbuch (Ablauf, Phasen, Sieg) fehlt im Programm; Handlungszeilen für Nicht-Slice-Rollen (OI-18); `GUIDE-TEXTS.md` bleibt Entwurf | P5 | Freigabe wie C-04 |
| C-06 | Geführter Modus (nächste Aktion, Regelgrund, Vorlesetext) | Offline | NACHWEIS | Cockpit führt (nächste Handlung, Vorlesetext, Anweisung); ein „Regelgrund“ und ein Modusbegriff existieren nicht | Cockpit-Tests | „Regelgrund“ je Schritt fehlt; kein Moduswechsel | P7 | **Nutzerentscheidung:** was „Regelgrund“ konkret zeigt |
| C-07 | Expertenmodus (kompakter Ablauf, direkte Korrektur) | Offline | FEHLT | Suche `expert`, `Experte`: kein Treffer | keiner | Modus, gleicher Kern und gleiche Schutzprüfungen | P7 | **Nutzerentscheidung:** was kompakter Ablauf bedeutet (sichtbares Verhalten) |
| C-08 | Beispielrunde und Übungsmodus (isolierter Spielstand) | Offline | FEHLT | Suche `practice`, `Übung`, `tutorial`: kein Treffer | keiner | Modus, isolierter Speicherort, kein Überschreiben laufender Partien | P7 | Inhalt der Beispielrunde: **Nutzerentscheidung** |
| C-09 | Nachspielbericht, lokale Historie (Gewinner, Rollen, Dauer, Runden), Chronik-Export | Offline | FEHLT | Suche `chronicle`, `recap`, `history`, `export`: nur Protokollebene (privat) | keiner | Bericht mit freigegebenen Angaben; private Daten nur nach bewusster Wahl | P7 | - |
| C-10 | Timer als Anwendungskomponente (Phasenleiste), ohne Regeleinfluss | Offline | FEHLT | Suche `Timer` in `app/`: nur `toast_host` | keiner | Komponente, Pause, Neustartverhalten; nie automatische Hinrichtung | P7 | **Nutzerentscheidung:** Standarddauern (Vorgaben) |

### Medienanschlüsse (ohne finale Medien)

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| X-01 | Audio: Busse (Master, Musik, Ambiente, Cues, UI), Lautstärke, Stumm, dauerhaft | Offline | FEHLT | Suche `AudioServer`, `AudioStream`: kein Treffer; Einstellungen zeigen Platzhalter („Lautstärke und Klänge folgen“) | keiner | gesamte Audio-Technik | P10 | - |
| X-02 | Anschlussstellen für Effekte und Bilder | Offline | NACHWEIS | `GameSession.events_applied`, `CockpitScreen.set_backdrop_art`, `GameSeatToken.set_portrait` | `test_cockpit_polish` (Anschlussstellen) | kein Verbraucher (bewusst) | P5 | - |
| X-03 | Bewegung reduzieren wirksam | Offline | AUTO | Tween-Übergänge 0,3 s und 0,15 s, abschaltbar | `test_cockpit_polish` | keine | - | - |
| X-04 | Untertitel und Überspringen von Effekten | Offline | FEHLT | kein Untertitelmodul | keiner | erst mit Medien sinnvoll | P10 | - |
| X-05 | DI-09: Ton bei fünf Toten, genau einmal, ohne Datei prüfbar | Offline | FEHLT | in `INTEGRATION-STATUS.md` „bestätigt, weiterhin nicht umgesetzt (Audio)“ | keiner | Ereignisvertrag und Einmaligkeit; Tondatei bleibt Medienproduktion | P5 | entschieden (DI-09) |
| X-06 | Herkunftsnachweise der Medien | Offline | NACHWEIS | `docs/masterplan/asset-register.csv`: 313 Zeilen, Status `ungeklärt` 228, `ki-nachgewiesen` 24, `lizenz-belegt` 4, `gesperrt` 1, `prüfartefakt` 56 | `node tools/check-asset-register.js` grün (CI) | Register ist vollständig und konsistent, die Rechte sind es nicht | P10 | extern: Nachweise |

### Clients, Plattform, Online

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| L-01 | Lokaler Sitzungsdienst mit QR-Beitritt, Einmalcode, Gerätebestätigung | Clients | FEHLT | Suche `HTTPServer`, `TCPServer`, `WebSocket`, `ENet`: kein Treffer | keiner | Machbarkeit auf iPadOS/Android, Dienst, Authentifizierung | P9 | Nutzergeräte; Machbarkeitsprüfung zuerst |
| L-02 | Smartphone-Client: eigene Rolle, Nachtaktion, Lexikon, neutrale Tagesansicht | Clients | FEHLT | keiner | keiner | Projektion pro Person | P9 | hängt an L-01, C-04 |
| L-03 | Öffentliche Zweitanzeige (Browser/Smart-TV) aus freigegebener Projektion | Clients | FEHLT | keiner (nur öffentliche Cockpit-Sicht auf dem Tablet) | keiner | Projektion und Client | P9 | hängt an L-01 |
| L-04 | Negativtests gegen Geheimnisleck und Fremdzugriff im Netz | Clients | FEHLT | kein Netz | keiner | Reconnect, widerrufene Tokens, alte Aktionen | P9 | - |
| P-01 | Windows-Export und Exportkonfiguration | Plattform | FEHLT | kein `export_presets.cfg` im Repository (`git ls-files godot`); `PC-Test-starten.cmd` startet das Projekt aus Godot heraus | keiner | reproduzierbare Exportkonfiguration | P10 | Godot-Exportvorlagen 4.7.2 installiert? Noch nicht ermittelt |
| P-02 | Android-Export | Plattform | GERÄT | keiner | keiner | SDK, JDK, Signierung, Referenzgerät (Decision Log: Referenztablet offen) | P10 | extern: SDK, Gerät |
| P-03 | iPadOS-Export | Plattform | GERÄT | keiner | keiner | Xcode, Mac, Apple-Zugang, iPad-Modell (Decision Log: offen) | P10 | extern: Mac, Apple-Konto |
| P-04 | Tablet-Abnahme: Touch, Lesbarkeit im Dunkeln, Layout bei 24 Personen, Schriftbild | Plattform | GERÄT | `docs/ui/cockpit.md` „Manuell testen“, `docs/ui/pc-test-pr3.md` | headless Layout-Tests bei 1024×768, 1280×800, 1920×1080 (`test_cockpit_screen`) | alle Darstellungsfragen | P6 | Nutzer prüft am Gerät, wenn der Bot pausiert |
| P-05 | Pause, Hintergrundwechsel, Rotation, Akkuverlust | Plattform | GERÄT | keiner | keiner | echtes Gerät | P10 | Gerät |
| P-06 | Steam (Steamworks, Cloud) | Online | SPÄTER | keiner | keiner | Masterplan Phase 10 | - | SDK-Zugang |
| O-01 | Online-Remote-Spiel | Online | SPÄTER | keiner | keiner | eigene Spezifikation, Stop/Go (Decision Log) | - | - |

### Qualität und CI

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| Q-01 | Headless-Suite in CI (Godot 4.7.2 gepinnt) | Offline | AUTO | `.github/workflows/godot-core-tests.yml` (nur bei Änderungen unter `godot/**`) | CI-Lauf auf `23c7044` grün (29.09.2026, beide Läufe) | Auslösung nur mit `godot/`-Änderung | - | - |
| Q-02 | Assetregister in CI | Offline | AUTO | `.github/workflows/asset-register.yml` | `node --test tests/check-asset-register.test.js`, `node tools/check-asset-register.js` | keine | - | - |
| Q-03 | Rollendokumente, Inhaltsabdeckung, Prüfertests in CI | Offline | NACHWEIS | `tools/role-migration/check-role-docs.js`, `docs/content-drafts/check-coverage.py`, `tests/check-role-docs.test.js` | lokal grün (siehe Ausgangsprüfungen); in keinem Workflow | Kein CI-Job | P6 | - |
| Q-07 | **Neu in Paket 5a.** Godot-Übersetzungen strukturell in CI | Offline | AUTO | `.github/workflows/godot-i18n.yml` (Pfade: `godot/content/i18n/**`, `godot/app/**`, `role_catalog.gd`, Prüfer, Prüfertests, Workflow) | `node --test tests/check-godot-i18n.test.js`, `node tools/check-godot-i18n.js` | CI-Lauf nach Push abzuwarten | - | - |
| Q-04 | **Erledigt in Paket 2 (B-01).** Stabile, deterministische Testsuite | Offline | AUTO | Coverage-Test mit festen Seeds | `test_prompt_coverage`: rot in 1 von 2 Vollläufen (B-01), 7 von 7 isolierten Läufen grün | Ursache des Nichtdeterminismus unbekannt | P2 (Vorprüfung) | - |
| Q-05 | Kontrollierte Testpartien mit 6 und 24 Personen inkl. Wiederbelebung, Reload, Abbruch | Offline | TEIL | Fuzz (6 bis 24), `test_prompt_coverage` (6 bis 24) | Fuzz und Coverage headless | keine gemeinsame Abnahmepartie am Gerät | P11 | Gerät |
| Q-06 | Pilot mit fünf externen Spielleitern, zehn Runden | Plattform | SPÄTER | keiner | keiner | Masterplan Phase 8 | - | - |

## Rollenübersicht (alle 72 Rollen-IDs)

**Legende.** *Kern:* Einzeltest in `godot/tests/unit/` (Namen ohne `test_`); zusätzlich läuft jede Rolle im Fuzztest (Save/Load per `StateCodec`, Replay, Geheimhaltungs-Invarianten nach jedem Befehl). *Bedienweg:* `B` = Button-/Screen-Test (`test_full_round_ui`, `test_cockpit_screen`, `test_target_selection`, `test_cockpit_day`, `test_notice_cards`), `K` = nur Kartendaten über `GameSession` (`test_prompt_coverage`), `A` = passiv oder ohne Fähigkeit, keine Bedienung nötig, `M` = automatisch im Morgenbericht. *Querbezüge:* Anzahl weiterer Unit-Testdateien, die die Rolle nennen (Indikator, kein Beweis). *Undo:* „generisch“ heißt: Rückgängig ist Replay der verkürzten Befehlsfolge (`test_undo`), für die Rolle nicht einzeln getestet. *Spielerinformation:* „Positivliste“ = UI-Test prüft, dass nur Erlaubtes angezeigt wird; „Kern-Test“ = Informationsmodell im Kern getestet, Anzeige nicht einzeln.

Alle 71 implementierten Rollen: Kern ja, Save/Load per Fuzz ja. Die Spalte „Restlücke“ nennt nur, was über diese Regel hinaus fehlt. Gemeinsame Lücke aller Rollen: Rollenübergabe an Spieler (S-08) fehlt. Das Lexikon (C-04) ist seit Paket 5b im Programm, die redaktionelle Endabnahme steht aus.

| Rolle | Kern (Einzeltest, zusätzlich Fuzz) | Bedienweg | Querbezüge (Unit-Tests) | Save/Load, Undo | Spielerinformation | Restlücke |
|---|---|---|---|---|---|---|
| `dorfbewohner` | ja (`scenarios`, `steps`) | A (passiv) | ja (48) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `werwolf` | ja (`scenarios`, `wolf_specials`) | B (Nacht/Rudel) | ja (48) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `schutzengel` | ja (`schutzengel`) | B | ja (23) | Fuzz-Invariante J; Undo rollenspezifisch getestet | keine | Korrektur des Schutzes: Oberfläche seit Paket 2 (`test_special_corrections`) |
| `waldhexe` | ja (`waldhexe`) | B | ja (15) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Kern-Test, UI-Positivliste nicht einzeln | Korrektur der Rettung und des Tranks: Oberfläche seit Paket 2 |
| `das-orakel` | ja (`orakel`) | B | ja (16) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Positivliste (UI-Test) | - |
| `trugbilderwolf` | ja (`trugbilderwolf`) | B (Setup, Rudel) | ja (8) | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `wolfskind` | ja (`wolfskind`) | B (`test_role_buttons`, Paket 3) | ja (12) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Korrektur (Vorbild, Verwandlung): Oberfläche seit Paket 2 |
| `spiegelwolf` | ja (`spiegelwolf`) | B (Hinrichtung) | ja (6) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `manipulator` | ja (`manipulator`) | B (`test_role_buttons`, Paket 3) | ja (12) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `lehrling` | ja (`lehrling`) | B (`test_role_buttons`, Paket 3) | ja (10) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Korrektur (Bindung, Erbe): Oberfläche seit Paket 2 |
| `sensentraeger` | ja (`sensentraeger`, `reactions`) | B (Reaktion) | ja (13) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `siegreicher-wolf` | ja (`siegreicher_wolf`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_siegreicher_wolf_counts_double_for_parity` | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `doppelspion` | ja (`doppelspion`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_doppelspion_wins_alone_when_no_wolf_lives` | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `selbstmoerder` | ja (`selbstmoerder`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_selbstmoerder_fulfilled_by_execution_with_five_dead` | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `dorfchronistin` | ja (`dorfchronistin`) | B (`test_role_buttons`, Paket 3) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `die-gebundenen` | ja (`die_gebundenen`) | B (`test_role_buttons`, Paket 3) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `waldlaeufer` | ja (`waldlaeufer_doktor`) | B (`test_role_buttons`, Paket 3) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `doktor` | ja (`waldlaeufer_doktor`) | B (`test_role_buttons`, Paket 3) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `wahnsinniger-kutscher` | ja (`death_effects`, `seat_roles`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_wahnsinniger_kutscher_takes_neighbours_on_lynch` | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `nachtwaechter` | ja (`seat_roles`) | M (Morgenbericht, test_morning_report); Auslöser über Buttons: `test_role_passive_ui::test_nachtwaechter_bells_in_announcement_card` | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `dorfwache` | ja (`seat_roles`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_dorfwache_survives_pack_attack` | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `ritter` | ja (`ritter_besessener_faehrtenleser`) | B (`test_role_buttons`, Paket 3) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `faehrtenleser` | ja (`ritter_besessener_faehrtenleser`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `besessener-wolf` | ja (`ritter_besessener_faehrtenleser`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `korrupter-richter` | ja (`richter_waechter_blutwolf`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Zweite Nominierung am Tag erst vom Kern abgelehnt (Oberfläche darf nichts verraten); Stimmhinweis seit Paket 3 im privaten Bereich |
| `waechter-am-tor` | ja (`richter_waechter_blutwolf`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_waechter_am_tor_blocks_new_wolf` | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `blutwolf` | ja (`richter_waechter_blutwolf`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_blutwolf_vote_bonus_visible_only_in_private_area` | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `spuerhund` | ja (`spuerhund_parasit`) | B (Auswahl) | mager (1) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Kern-Test, UI-Positivliste nicht einzeln | - |
| `parasit` | ja (`spuerhund_parasit`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `schattenhund` | ja (`wolf_specials`) | B (`test_role_buttons`, Paket 3) | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `albtraumwolf` | ja (`wolf_specials`) | B (`test_role_buttons`, Paket 3) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `giftwolf` | ja (`wolf_specials`) | B (`test_role_buttons`, Paket 3) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `rudelvater` | ja (`wolf_specials`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_rudelvater_lynch_gives_second_pack_step` | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `seuchenwolf` | ja (`wolf_specials`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_seuchenwolf_death_lets_next_attack_pierce_protection` | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `fenrir` | ja (`fenrir_cerberus_henker`) | A (passiv); Auslöser über Buttons: `test_role_passive_ui::test_fenrir_survives_death_from_stage_three` | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `cerberus` | ja (`fenrir_cerberus_henker`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `henker` | ja (`fenrir_cerberus_henker`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `traumdeuter` | ja (`info_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2) |
| `kopfgeldjaeger` | ja (`info_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2) |
| `koenig` | ja (`info_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2) |
| `kriegerin-des-lichts` | ja (`info_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `blutpriester` | ja (`info_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2) |
| `amalia` | ja (`info_roles`) | B (Tagesaktion) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `detektiv` | ja (`info_roles`) | M (Morgenbericht; UI-Nachweis fehlt); Auslöser über Buttons: `test_role_passive_ui::test_detektiv_hint_in_public_morning_card` | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `die-ewigen` | ja (`info_roles`) | B (`test_role_buttons`, Paket 3) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | - |
| `der-weise` | ja (`protection_roles`) | B (Hinrichtung) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `maertyrerin` | ja (`protection_roles`) | B (`test_role_buttons`, Paket 3) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `schutzgeist` | ja (`protection_roles`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `dorfschmied` | ja (`protection_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `verdammniswaechter` | ja (`protection_roles`) | B (`test_role_buttons`, Paket 3) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `loki` | ja (`bond_roles`, `notices`) | B (Auswahl, Hinweiskarte) | ja (3) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Positivliste (UI-Test) | - |
| `rotkaeppchen` | ja (`bond_roles`, `notices`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `schwarze-witwe` | ja (`bond_roles`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `schattenwanderer` | ja (`bond_roles`) | B (`test_role_buttons`, Paket 3) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `seelentauscher` | ja (`transform_roles`) | B (Auswahl) | ja (7) | Fuzz-Invariante J; Undo rollenspezifisch getestet | keine | - |
| `daemonischer-wolf` | ja (`transform_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `koenig-lykaon` | ja (`transform_roles`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `kutscher` | ja (`revival_roles`) | B | ja (4) | Fuzz-Invariante J; Undo rollenspezifisch getestet | keine | - |
| `dr-victor-frankenstein` | ja (`revival_roles`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Totenkarten-Bedingung RM-DR-141.4 offen |
| `rattenfaenger` | ja (`solo_roles_a`, `notices`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `pestbringerin` | ja (`solo_roles_a`, `notices`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `prophet-des-untergangs` | ja (`solo_roles_a`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `todesprediger` | ja (`solo_roles_a`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `feuerteufel` | ja (`fire_devil`) | B (`test_role_buttons`, Paket 3) | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `voodoo-priester` | ja (`voodoo_priest`) | B (`test_role_buttons`, Paket 3) | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `nekromant` | ja (`necromancer`) | B (`test_role_buttons`, Paket 3) | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `hades` | ja (`hades`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `grabraeuber` | ja (`grave_robber`) | B (`test_role_buttons`, Paket 3) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `schicksalswolf` | ja (`fate_wolf`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `rachsuechtiger-wolf` | ja (`lone_wolf_and_time_warden`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `zeitwaechter` | ja (`lone_wolf_and_time_warden`) | B (`test_role_buttons`, Paket 3) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `kartenschlucker` | nein | nein | nein | nein | nein | Blockiert: Totenkartenmodell (RM-DR-013, RM-DR-143.1/.2); nicht im Katalog |

**Zählung (Ausgangsstand Paket 1):** 17 Rollen mit Button-Test, 41 nur über Kartendaten, 11 passiv, 2 über Morgenbericht, 1 blockiert (Kartenschlucker). Summe 72.

**Zählung nach Paket 3:** 71 Rollen mit Bedienweg über echte Controls (davon 45 neu in `test_role_buttons`, 12 passive bzw. Morgenbericht-Rollen über ihren Auslöser in `test_role_passive_ui`; `dorfbewohner` über `test_full_round_ui`), 1 blockiert (Kartenschlucker). Nicht enthalten: Geräte- und Touchabnahme.

## Befunde

**Bekannte Fehler (mit Beleg)**

| ID | Befund | Beleg | Einordnung |
|---|---|---|---|
| B-01 | **BEHOBEN in Paket 2 (Ursache belegt, siehe unten).** `test_prompt_coverage::test_all_prompt_kinds_are_operable_through_the_card` schlug im ersten Vollauf fehl („Rolle koenig erschien nie als Prompt“), im zweiten Vollauf und in 7 isolierten Läufen grün | Lauf 1 (Vollauf direkt nach `--import`): 917 Tests, 1 fehlgeschlagen; Lauf 2: 917 Tests, 0 fehlgeschlagen; isoliert (`--filter=prompt_coverage`) 7 von 7 grün (2 plus 5) | intermittierender Fehler in der Prüfung, nicht im Spielverhalten belegt. Die Seeds sind fest, eine Zeit- oder Zufallsquelle im Pfad wurde per `rg` nicht gefunden. Ursache **ungeklärt**. Der erste Lauf folgte direkt auf `--import`. Verdacht, nicht Beleg. Wird in P2 als Vorprüfung mit Wiederholungsläufen untersucht. **Untersuchungsergebnis P2:** `Array.shuffle()` (Sitzordnung und Zielwahl im Test) nutzt den beim Start zufällig gesetzten globalen Generator; die frühere `rg`-Suche prüfte nur `randi`/`randf`. Dadurch war jede Partie von Lauf zu Lauf verschieden (Fokuspartie König: 23 von 40 globalen Seeds ohne König-Prompt). Der König ist nur bei mehr Toten als Lebenden aktiv und hing am Überleben. Mit dem alten `shuffle()` reproduziert der neue Regressionstest den Fehler („Rolle kutscher erschien nie als Prompt“); mit dem seedbaren Mischen sind Partien unabhängig vom globalen Seed identisch. Ein Importzusammenhang war nicht ursächlich. Kein Spielfehler. Korrektur nur im Test, Pflichtabdeckung erhalten und um zwölf feste Erreichbarkeitsszenarien ergänzt |
| B-03 | **BEHOBEN in Paket 3.** Stimmhinweise des Regelkerns (`VoteHints`: Blutwolf, Korrupter Richter, RM-DR-008) wurden berechnet, aber nirgends angezeigt | `rg VoteHints godot/app` ohne Treffer; roter Test `test_role_passive_ui::test_blutwolf_vote_bonus_visible_only_in_private_area` | Bedienlücke; Anzeige nur im privaten Spielleiterbereich ergänzt |
| B-04 | **BEHOBEN in Paket 4.** Nach einem abgebrochenen Speichern (Fehler beim Sichern oder Einsetzen) lag der neueste vollständige Stand nur in `.tmp`. Scheiterte das nächste Speichern bei der Prüfung, wurde diese `.tmp` gelöscht; der Neustart lud die ältere Sicherung | roter Test `test_save_service::test_failure_after_interrupted_save_keeps_the_newest_complete_state` (geladen Stand N-1 statt N) | Datenverlust eines vollständigen Stands; Korrektur: offene vollständige `.tmp` vor dem Schreiben einsetzen (DA-35) |
| B-05 | **BEHOBEN in Paket 4.** Die Beenden-Rückfrage sagte „Eine laufende Partie ist gespeichert“, auch wenn das letzte Speichern fehlschlug; nach dem letzten Befehl (Spielende) gab es keinen Weg, erneut zu speichern; die Rückfallmeldung sagte nicht, dass ein älterer Stand geladen wurde | rote Tests `test_quit_dialog_warns_when_the_running_game_is_not_saved`, `test_retry_save_button_after_failure_without_automatic_loop`, `test_backup_recovery_message_names_the_older_state` | falsche Erfolgsaussage und Bedienlücke; Korrektur DA-36 bis DA-38 |
| B-06 | **BEHOBEN im Restpaket.** Die Warnung bei ungespeichertem Stand griff nur im Desktop-Dialog: System-Zurück in der Wurzel beendete Mobilgeräte sofort, und Desktop-Fensterschließen (X, Alt+F4) beendete wegen `auto_accept_quit` ohne jede Rückfrage | rote Tests `test_mobile_back_at_root_warns_when_unsaved`, `test_window_close_request_warns_only_when_unsaved` | Umgehung der Warnung; Korrektur DA-40, DA-41 |
| B-02 | **BEHOBEN in Paket 5a.** Einstellungen (Sprache, Bewegung) gingen beim Neustart verloren | `app_settings.gd` ohne Dateizugriff; rote Tests in `test_settings_persistence` (Klasse `SettingsStore` fehlte) | echter Funktionsmangel (D-09); Korrektur DA-52 |

**Fehlende Nachweise statt bekannter Fehler**

- *(Erledigt in Paket 3.)* Buttonweg für 41 Rollen (R-02).
- *(Erledigt in Paket 3.)* Positivlisten der Zeigekarte für 12 Informationsrollen (I-04).
- Übersetzungs-Bedeutungsgleichheit (C-01).
- Rollenspezifisches Undo außer für 7 Rollen (Rollentabelle).
- *(Ergänzt in Paket 3, acht feste Szenarien.)* Deckungslücke der Wechselwirkungen (N-11).

**Widersprüche zwischen Dokumenten und Code**

- *(Erledigt in Paket 2: Befehl und Zustand entstanden neu.)* `CODE-COMPLETION-ROADMAP.md` Paket 2 spricht von der „bestehenden `ConfirmRoleShown`-Regel“. Im Code gibt es weder Befehl noch Zustand, nur Spezifikation (`vertical-slice-flow.md` §2, `implementation-boundary.md` B-11). Paket 2 muss den Kernbefehl neu bauen, nicht nur eine Oberfläche ergänzen (S-08).
- `implementation-boundary.md` B-11 listet `BeginDay` und `ReorderSeats`. `BeginDay` ist als Bedienzustand des Morgenberichts gelöst (`cockpit.md`, Entscheidungstabelle), `ReorderSeats` fehlt (S-06).
- Masterplan Kopfzeile „Status: … keine spielbare Partie (Nacht/Tag) über die Oberfläche“ stammt vom Stand 27.09.2026 und ist überholt (Nacht, Morgen, Tag, Sieg bedienbar, `test_full_round_ui`). Historische Angaben wurden nicht umgeschrieben.
- Die Inhaltsentwürfe aus `content/rolebook-and-guide` (`cde16f5`) sind per Kopie in diesem Branch. Die Commits selbst liegen nicht im Verlauf: `git rev-list --count HEAD..origin/content/rolebook-and-guide` = 10. Kein Merge, nur Kenntnisnahme.

## Offene Produktentscheidungen (aus der Matrix)

Nicht beantwortet, nicht durch diesen Auftrag entschieden:

1. Sitzplatztausch während der Partie (S-06).
2. *(Technisch entschieden in Paket 2, DA-27: Schema 14, keine Migration.)* Schema-Anhebung für Rollenübergabe (S-08), oder Bedienzustand nur in der App.
3. *(Entschieden am 29.09.2026: „Neutral statt Anzahl“, Decision Log PE-01; Hinweiszeile umgesetzt am 29.09.2026, DA-46.)* Offene Reaktion für Mitlesende verbergen (I-03). **Offen bleibt Teil 2:** Rückschluss aus der öffentlichen Phase „Morgen“ und der verdeckten Karte (siehe I-03). DA-46 beschreibt die Grenze, gibt sie aber nicht frei.
4. *(Entschieden am 29.09.2026: eine Sicherung reicht; Wiederholen entfällt beim Neustart, Decision Log PE-02, PE-03; Vorgaben nachgezogen, DA-51.)* Redo nach Neustart und Checkpoint-Rotation für den Offline-Abschluss (D-04, D-05).
5. Redaktionelle Endabnahme der integrierten Rollenlexikon-Texte und Freigabe der Guide-Texte (C-04, C-05). Offene Punkte je Rolle stehen im Lexikon und in `docs/content-drafts/INTEGRATION-STATUS.md`.
6. Inhalt von Szenarien, Beispielrunde, Definition Expertenmodus, Timer-Vorgaben (S-04, C-07, C-08, C-10).
7. Kartenregeln (R-03 bis R-05, P8).
8. Endgültige Rollenauswahl 20 bis 30 für Version 1.0 gegenüber 71 implementierten Rollen (Decision Log, „nicht blockierende Punkte“).
9. *(Entschieden am 29.09.2026: nicht blockierender Hinweis im Setup, Decision Log PE-04; umgesetzt am 29.09.2026, DA-47 bis DA-49.)* Unverträgliche Rollenkombinationen als Setup-Regel (R-07).
10. Linkshänder-Schalter jetzt oder im Gestaltungsprojekt (D-10).

**Aktualisierung nach PE-06 (29.09.2026):** N-12 von FEHLT auf AUTO: „Alle Verzauberten“ ist ein eigener Nachtschritt hinter dem Rattenfänger, auch nach einem Tarnaufruf, mit Ausfallregel, privater Karte, Speichern/Fortsetzen und Rückgängig. Der Hinweis `piper_all` entfällt, das Lexikon nennt keine Lücke mehr (14 Rollen mit offenen Punkten). Regelversion 0.13, Schema 14 (DA-63). Offen: PE-07 (Antwort „keine Rolle doppelt außer den Gebundenen“ widerspricht dem Katalog). Keine Geräteabnahme.
