# Grimmhain: Abschlussmatrix der Spielfunktionen

**Stand:** 29.09.2026 · Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui` · Branch `feature/night-ui-expansion` · Ausgangs-HEAD `23c7044` (PR #3 offen) · Godot `4.7.2.stable.official.ed1daf0bf` · Schema 13, Regelversion 0.12

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
| S-08 | Rollenübergabe an Spieler („Rollen zeigen“): neutrale Karte, bewusste Aktion, Rolle nur für die Person, schließen, `ConfirmRoleShown`, Fortsetzung bei der ersten unbestätigten Person | Offline | FEHLT | `ConfirmRoleShown` existiert in keinem `.gd`, nur in Spec (`vertical-slice-flow.md` §2, B-11) und Doku. Das Cockpit zeigt Rollen nur dem Spielleiter (privater Bereich) | keiner (AS-A04 hat keinen Test) | Befehl und Zustand im Kern, Rollenkarte, Abbruch-Fortsetzung, Trugbilderwolf: Karte trägt keine Scheinrolle (DI-08) | **P2** | Schema-Bump 13 auf 14 würde alte Saves erneut sperren; oder Bedienzustand nur in der App. Bewusste Aktion statt Halten (Halten ist ohne Gerät nicht prüfbar) als technische Ableitung. Kurze Nutzerbestätigung zu Schema |

### Spielablauf

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| N-01 | Nacht: Plan, `BeginStep`, Prompt-Karte für alle Antwortarten, Überspringen mit Begründung, Abbruch | Offline | AUTO | `core/rules/step_queue.gd`, `app/session/prompt_view.gd`, `screens/cockpit/action_card.gd` | `test_cockpit_model`, `test_cockpit_screen`, `test_full_round_ui`, `test_steps`, `test_gm_open_prompt` | Buttonweg je Rolle nicht einzeln belegt (siehe R-02) | P3 | - |
| N-02 | Morgenauflösung, offene Reaktionen, Morgenbericht öffentlich/privat getrennt | Offline | AUTO | `app/session/morning_report.gd`, `core/model/reaction.gd` | `test_morning_report`, `test_reactions`, `test_cockpit_screen` | Mitlesende erkennen offene Reaktion (siehe I-03) | P4 | siehe I-03 |
| N-03 | Tag: Nominierung Quelle→Ziel, Hinrichtung mit verdeckter Prüfkarte, Tagesaktionen; keine digitale Stimme | Offline | AUTO | `app/session/cockpit_view.gd`, `core/rules/execution_rules.gd` | `test_cockpit_day`, `test_gm_execute`, Szenarien `as-c11`, `as-c12`, `dr-03` | keine | - | - |
| N-04 | Sieg: Kandidaten erkennen, Spielleiter bestätigt oder lehnt ab | Offline | AUTO | `core/rules/win_rules.gd`, `action_card.gd` | `test_win_status`, `test_win_finalize_guard`, `test_cockpit_day::test_win_candidate_is_covered_then_confirmed`, `test_full_round_ui` | keine | - | - |
| N-05 | Spielleiterkorrekturen in der Oberfläche: Person töten, wiederbeleben, Rolle ändern, Status (Nominierung, Tränke, Spiegelung, Scheinrolle), Hinrichtung ohne Nominierung, Sieger erklären | Offline | AUTO | `core/rules/gm_corrections.gd`, `cockpit_layers.gd`, `cockpit_screen.gd` | `test_cockpit_gm`, `test_gm_correction`, `test_gm_role_field` | keine für diese Arten | - | - |
| N-06 | Korrekturen Schutz, Rettung, Wolfskind, Lehrling in der Oberfläche | Offline | TEIL | Kern kennt 11 Arten (`gm_corrections.gd`: `set_protection`, `set_rescue`, `set_wolf_model`, `set_apprentice_master` u. a.); Oberfläche bietet `kill, revive, set_role, status, execute, declare_winner` (`cockpit_layers.gd:190`) | Kern: `test_gm_correction`; UI: keiner (`cockpit.md` nennt die Lücke selbst) | Bedienung mit Grund, Warnung, Protokoll; Abbruch offener Prompt; Undo/Reload | **P2** | keine Entscheidung; Kernbefehle bestehen |
| N-07 | Aufrufpolitik und Tarnaufrufe (DI-02) | Offline | AUTO | `core/rules/call_policy.gd` | `test_call_policy`, `test_call_presentation` | keine | - | - |
| N-08 | Öffentliche Ansage von Todeseffekten mit Rolle zum Ereigniszeitpunkt (DI-03) | Offline | AUTO | `GameEvent DeathEffect`, `morning_report.gd` | `test_death_effects`, `test_death_effect_lines` | keine | - | - |
| N-09 | Private Hinweiskarten: Loki, Rattenfänger, Pestbringerin, Rotkäppchen, Trugbilderwolf (DI-04 bis DI-08) | Offline | AUTO | `core/rules/notice_rules.gd`, `AckNotice`, `cockpit_layers.gd` | `test_notices`, `test_notice_cards` | keine | - | - |
| N-10 | Rollenaufdeckung beim Tod nur in Runden ohne Wiederbelebung | Offline | AUTO | `SeatDied.role_id`, `morning_report.gd` | `test_morning_report` | keine | - | - |
| N-11 | Rollen mit Schutz-, Wiederbelebungs-, Umlenkungswirkung gegeneinander (Todespipeline, Ketten, Reihenfolge) | Offline | NACHWEIS | `core/rules/kill_pipeline.gd`, `protections.gd`, `role_transition.gd` | `test_role_interactions` (11 feste Szenarien), `test_role_interaction_fuzz`, Familien-Unit-Tests | Feste Szenarien nur für 11 Kombinationen; übrige Wechselwirkungen nur vom Fuzz-Generator abgedeckt | P3 | - |

### Rollen

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| R-01 | 71 Rollen im Regelkern | Offline | AUTO | `core/rules/role_catalog.gd` (71 Einträge), Regeldateien | je Rolle ein Einzeltest plus `test_role_interaction_fuzz` (alle 71) | keine | - | - |
| R-02 | Alle 71 Rollen über die Oberfläche bedienbar (Buttonweg) | Offline | NACHWEIS | `action_card.gd` für alle Antwortarten | Button-Tests: 17 Rollen; Kartendaten-Test `test_prompt_coverage` (142 Partien): 41 Rollen; passiv: 11; Morgenbericht: 2 (siehe Rollentabelle) | Buttonweg für 41 Rollen nicht einzeln belegt; Test ist zusätzlich intermittierend rot (B-01) | **P3** | - |
| R-03 | Kartenschlucker (72. Rolle) | Karten | BLOCKIERT | nicht im `RoleCatalog`, im Setup nicht wählbar | keiner | Totenkartenmodell (RM-DR-013, RM-DR-143.1/.2) | P8 | **Nutzerentscheidung:** Kartenregeln (drei Auswahlfragen plus Freitext, siehe P8) |
| R-04 | Totenkarten / Totenkarten-Assistent (Ziehen, Besitz, Tausch, Verbrauch) | Karten | BLOCKIERT | keiner; `docs/ui/cockpit.md`: „Totenreichkarten sind nicht definiert“ | keiner | gesamtes Kartenmodell | P8 | **Nutzerentscheidung**, gleiche wie R-03 |
| R-05 | Frankenstein: Totenkarten-Bedingung | Karten | BLOCKIERT | Wiederbelebung bedienbar; Bedingung RM-DR-141.4 wird nicht geprüft; privater Bereich weist darauf hin | `test_revival_roles` (Wiederbelebung) | Bedingung fehlt | P8 | hängt an R-04 |
| R-06 | Zufallsknopf nach RM-DR-015.2 (König, Traumdeuter, Kopfgeldjäger, Blutpriester) | Offline | TEIL | Spielleiterwahl vorhanden; `decision-status.csv` RM-DR-015.2 = E („Spielleiter wählt oder Zufallsknopf“); `docs/role-migration/11-role-audit-status.md` §0: „in keiner Rolle umgesetzt“ | Spielleiterwahl über `test_info_roles` | Zufallsknopf über gespeicherten Generator | P3 | entschieden; Zufall nur über gespeicherten Seed |
| R-07 | Analyse unverträglicher Rollenkombinationen (vom Product Owner gewünscht, Setup-Regel vertagt) | Offline | FEHLT | keiner | keiner | Analyse und ggf. Setup-Warnung | P3 | **Nutzerentscheidung**, ob und als welche Setup-Regel |
| R-08 | Regel-Linter (fehlende IDs, Texte, Nachtprioritäten, Tests) | Offline | TEIL | `test_role_model::test_presentation_has_every_role_in_both_languages`, `test_ui_i18n`, `tools/role-migration/check-role-docs.js` (nur lokal) | siehe Q-03 | Ein Prüfer für Nachtpriorität gegen Test je Rolle fehlt | P6 | - |

### Informationsschutz

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| I-01 | Cockpit-Sichten ohne Rollen; geheime Ebenen entstehen erst beim Öffnen, verschwinden beim Schließen/Sichtschutz | Offline | AUTO | `cockpit_view.gd`, `cockpit_layers.gd` | `test_cockpit_screen` (`_assert_no_roles`), `test_cockpit_model` | keine | - | - |
| I-02 | Öffentliche Ereignisse ohne Rollen-, Ursachen- und Informationsdaten | Offline | AUTO | `core/model/visibility.gd` | Fuzz-Invariante in `test_role_interaction_fuzz`, `test_death_effect_lines`, `test_morning_report` | keine | - | - |
| I-03 | Offene Reaktion für Mitlesende nicht erkennbar | Offline | BLOCKIERT | Kern bleibt in „Morgengrauen“, Hinweiszeile nennt offene Reaktionen (`cockpit.md`, „Grenzen (Review 29.09.2026, nicht entschieden)“) | dokumentiert, kein Test | Verbergen bräuchte eine Änderung am Phasen-/Anzeigekonzept | P4 | **Nutzerentscheidung:** akzeptieren oder verbergen |
| I-04 | Zeigekarte für Informationsrollen zeigt nur Positivliste | Offline | NACHWEIS | `cockpit_layers.gd` (gezeigte Karte) | Positivliste einzeln geprüft nur für Orakel (`test_cockpit_screen`), Hinweiskarten (`test_notice_cards`), Morgen (`test_morning_report`) | 12 weitere Informationsrollen ohne eigenen Positivlisten-Test der Zeigekarte | P4 | - |
| I-05 | Einzelne Spielerkarte je Person (Rolle, Nachtaktion) getrennt vom Gesamtzustand | Clients | FEHLT | keine Projektion pro Person außer Cockpit-Sicht und Hinweiskarte | keiner | Spielerprojektion (Masterplan Phase 5) | P9 | siehe L-02 |

### Speichern, Wiederaufnahme, Undo

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| D-01 | Speichern nach jedem Befehl, atomar (`.tmp`, `.bak`), Fortsetzen mitten im Prompt, bei offener Reaktion | Offline | AUTO | `app/session/save_service.gd` | `test_save_service` (unterbrochenes Schreiben an jedem Schritt), `test_save_load`, `test_replay` | keine (Speicherort/Rechte am Gerät: siehe D-08) | - | - |
| D-02 | Fehlerfälle: beschädigte Datei, beschädigtes Backup, unvollständige `.tmp`, Sicherung wird nie überschrieben | Offline | AUTO | `save_service.gd` (Umbenennen statt Löschen) | `test_save_service`, `test_corrupt_save` | keine | - | - |
| D-03 | Ältere Schema-/Regelversionen: Sperre, Datei erhalten, keine Migration | Offline | AUTO | `StateCodec`, `save_service.gd` | `test_save_versions`, `test_save_service` | keine (Absicht) | - | - |
| D-04 | Checkpoint-Rotation über eine Sicherung hinaus, Reparaturdialog | Offline | TEIL | eine `.bak`; automatischer Rückfall auf Backup mit Hinweis | `test_save_service` | Rotation mehrerer Stände und Reparaturdialog (Masterplan Phase 3) | P4 | **Nutzerentscheidung:** für den Offline-Abschluss nötig oder späteres QoL |
| D-05 | Undo/Redo mit Klartext, über Replay; Undo nach Neustart | Offline | AUTO | `game_session.gd` (Replay), `cockpit_layers.gd` | `test_undo` (7 Tests), `test_cockpit_day::test_undo_drops_open_execution_check` | Wiederholen nach Neustart entfällt (in `save-resume.md` dokumentiert; Spec B-12 verlangt es) | P4 | **Nutzerentscheidung:** Redo nach Neustart verlangt oder nicht |
| D-06 | Persistente Ereignisse und lesbare Rundenchronik | Offline | TEIL | Befehle gespeichert, Ereignisse per Replay; Protokollebene im Cockpit (privat) | `test_cockpit_screen` (Protokoll) | keine öffentliche Rundenchronik, kein Export (siehe C-09) | P7 | - |
| D-07 | Speicherfehler sichtbar, kein stiller Neustart | Offline | AUTO | Statusanzeige „Fehler: nicht gespeichert“ | `test_save_service`, `test_cockpit_screen` | keine | - | - |
| D-08 | Speicherort, Schreibrechte, App-Beendigung durch das System | Plattform | GERÄT | `user://saves` | nur isolierte Testverzeichnisse `user://test-saves-*` | echtes Gerät | P10 | Gerät |
| D-09 | Einstellungen dauerhaft (Sprache, Bewegung reduzieren) | Offline | FEHLT | `app/settings/app_settings.gd`: kein `ConfigFile`, kein Dateizugriff (Suche `ConfigFile\|user://` in `app/`: nur `save_service.gd`) | keiner | Beim Neustart gehen beide Einstellungen verloren | P5 | keine Entscheidung |
| D-10 | Einstellung „Linkshänder“ | Offline | TEIL | `AppSettings.left_handed` (Variable), Kommentar „noch ohne Wirkung“; kein Schalter in `settings_screen`, `.po` nennt „folgen später“ | keiner | Schalter ohne Wirkung zählt nicht (Roadmap P5) | P5 | **Nutzerentscheidung:** Umfang jetzt oder zum Gestaltungsprojekt |

### Inhalte, Texte, Modi

| ID | Funktion/Anforderung | Stufe | Status | Implementierungsbeleg | Testbeleg | Konkrete Restlücke | Paket | Voraussetzung / Entscheidung |
|---|---|---|---|---|---|---|---|---|
| C-01 | DE/EN: gleiche Schlüsselmenge, keine Literaltexte, Sprachwechsel | Offline | AUTO | `content/i18n/ui.de.po`, `ui.en.po` (je 1085 Schlüssel) | `test_ui_i18n` (6 Tests) | Bedeutungsgleichheit ungeprüft | P5 | redaktionelle Prüfung |
| C-02 | Rollenname und Kurztext je Rolle (71 mal 2) | Offline | AUTO | `ui.role.<id>.name/.short` | `test_role_model::test_presentation_has_every_role_in_both_languages` | Kurztext ist keine Regelbeschreibung | - | - |
| C-03 | Vorlesetext und Anweisung je Nachtrolle | Offline | AUTO | `ui.call.*` (51), `ui.prompt.*` (115) | `test_prompt_coverage` (eigene Anweisung statt generischem Rückfall je Kombination) | keine | - | - |
| C-04 | Rollenlexikon im Programm: Fähigkeit, Ziele, Grenzen, Zeitpunkt, Spielleiteranweisung für 71 Rollen | Offline | FEHLT | Suche `lexikon`, `Lexikon`, `glossary`: kein Treffer im Programm. Entwürfe: `docs/content-drafts/rolebook/` (71 Einträge) | `docs/content-drafts/check-coverage.py`: OK (nur lokal) | Programmanschluss und Abgleich mit Kern; Entwürfe sind nicht freigegeben (`INTEGRATION-STATUS.md`) | P5 | **Nutzerentscheidung:** redaktionelle Freigabe der Texte |
| C-05 | Regelbuch und kontextbezogene Hilfe | Offline | FEHLT | nur Entwurf `GUIDE-TEXTS.md` | `check-coverage.py` (Entwurf) | Programmanschluss | P5 | Freigabe wie C-04 |
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
| Q-04 | Stabile, deterministische Testsuite | Offline | TEIL | Coverage-Test mit festen Seeds | `test_prompt_coverage`: rot in 1 von 2 Vollläufen (B-01), 7 von 7 isolierten Läufen grün | Ursache des Nichtdeterminismus unbekannt | P2 (Vorprüfung) | - |
| Q-05 | Kontrollierte Testpartien mit 6 und 24 Personen inkl. Wiederbelebung, Reload, Abbruch | Offline | TEIL | Fuzz (6 bis 24), `test_prompt_coverage` (6 bis 24) | Fuzz und Coverage headless | keine gemeinsame Abnahmepartie am Gerät | P11 | Gerät |
| Q-06 | Pilot mit fünf externen Spielleitern, zehn Runden | Plattform | SPÄTER | keiner | keiner | Masterplan Phase 8 | - | - |

## Rollenübersicht (alle 72 Rollen-IDs)

**Legende.** *Kern:* Einzeltest in `godot/tests/unit/` (Namen ohne `test_`); zusätzlich läuft jede Rolle im Fuzztest (Save/Load per `StateCodec`, Replay, Geheimhaltungs-Invarianten nach jedem Befehl). *Bedienweg:* `B` = Button-/Screen-Test (`test_full_round_ui`, `test_cockpit_screen`, `test_target_selection`, `test_cockpit_day`, `test_notice_cards`), `K` = nur Kartendaten über `GameSession` (`test_prompt_coverage`), `A` = passiv oder ohne Fähigkeit, keine Bedienung nötig, `M` = automatisch im Morgenbericht. *Querbezüge:* Anzahl weiterer Unit-Testdateien, die die Rolle nennen (Indikator, kein Beweis). *Undo:* „generisch“ heißt: Rückgängig ist Replay der verkürzten Befehlsfolge (`test_undo`), für die Rolle nicht einzeln getestet. *Spielerinformation:* „Positivliste“ = UI-Test prüft, dass nur Erlaubtes angezeigt wird; „Kern-Test“ = Informationsmodell im Kern getestet, Anzeige nicht einzeln.

Alle 71 implementierten Rollen: Kern ja, Save/Load per Fuzz ja. Die Spalte „Restlücke“ nennt nur, was über diese Regel hinaus fehlt. Gemeinsame Lücke aller Rollen: Rollenübergabe an Spieler (S-08) fehlt, ebenso Lexikon (C-04).

| Rolle | Kern (Einzeltest, zusätzlich Fuzz) | Bedienweg | Querbezüge (Unit-Tests) | Save/Load, Undo | Spielerinformation | Restlücke |
|---|---|---|---|---|---|---|
| `dorfbewohner` | ja (`scenarios`, `steps`) | A (passiv) | ja (48) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `werwolf` | ja (`scenarios`, `wolf_specials`) | B (Nacht/Rudel) | ja (48) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `schutzengel` | ja (`schutzengel`) | B | ja (23) | Fuzz-Invariante J; Undo rollenspezifisch getestet | keine | Korrektur des Schutzes hat keine Oberfläche |
| `waldhexe` | ja (`waldhexe`) | B | ja (15) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Kern-Test, UI-Positivliste nicht einzeln | Korrektur der Rettung hat keine Oberfläche |
| `das-orakel` | ja (`orakel`) | B | ja (16) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Positivliste (UI-Test) | - |
| `trugbilderwolf` | ja (`trugbilderwolf`) | B (Setup, Rudel) | ja (8) | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `wolfskind` | ja (`wolfskind`) | K | ja (12) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Korrektur (Vorbild, Verwandlung) hat keine Oberfläche |
| `spiegelwolf` | ja (`spiegelwolf`) | B (Hinrichtung) | ja (6) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `manipulator` | ja (`manipulator`) | K | ja (12) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `lehrling` | ja (`lehrling`) | K | ja (10) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Korrektur (Bindung, Erbe) hat keine Oberfläche |
| `sensentraeger` | ja (`sensentraeger`, `reactions`) | B (Reaktion) | ja (13) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `siegreicher-wolf` | ja (`siegreicher_wolf`) | A (passiv) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `doppelspion` | ja (`doppelspion`) | A (passiv) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `selbstmoerder` | ja (`selbstmoerder`) | A (passiv) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `dorfchronistin` | ja (`dorfchronistin`) | K | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg nicht einzeln belegt |
| `die-gebundenen` | ja (`die_gebundenen`) | K | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg nicht einzeln belegt |
| `waldlaeufer` | ja (`waldlaeufer_doktor`) | K | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg nicht einzeln belegt |
| `doktor` | ja (`waldlaeufer_doktor`) | K | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg nicht einzeln belegt |
| `wahnsinniger-kutscher` | ja (`death_effects`, `seat_roles`) | A (passiv) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `nachtwaechter` | ja (`seat_roles`) | M (Morgenbericht, test_morning_report) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg n. a. (automatisch) |
| `dorfwache` | ja (`seat_roles`) | A (passiv) | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `ritter` | ja (`ritter_besessener_faehrtenleser`) | K | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `faehrtenleser` | ja (`ritter_besessener_faehrtenleser`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg nicht einzeln belegt |
| `besessener-wolf` | ja (`ritter_besessener_faehrtenleser`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `korrupter-richter` | ja (`richter_waechter_blutwolf`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Zweite Nominierung am Tag erst vom Kern abgelehnt (Oberfläche darf nichts verraten) |
| `waechter-am-tor` | ja (`richter_waechter_blutwolf`) | A (passiv) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `blutwolf` | ja (`richter_waechter_blutwolf`) | A (passiv) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `spuerhund` | ja (`spuerhund_parasit`) | B (Auswahl) | mager (1) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Kern-Test, UI-Positivliste nicht einzeln | - |
| `parasit` | ja (`spuerhund_parasit`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `schattenhund` | ja (`wolf_specials`) | K | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `albtraumwolf` | ja (`wolf_specials`) | K | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `giftwolf` | ja (`wolf_specials`) | K | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `rudelvater` | ja (`wolf_specials`) | A (passiv) | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `seuchenwolf` | ja (`wolf_specials`) | A (passiv) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `fenrir` | ja (`fenrir_cerberus_henker`) | A (passiv) | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `cerberus` | ja (`fenrir_cerberus_henker`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `henker` | ja (`fenrir_cerberus_henker`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `traumdeuter` | ja (`info_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2) |
| `kopfgeldjaeger` | ja (`info_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2) |
| `koenig` | ja (`info_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2); Coverage-Test rot in 1 von 2 Vollläufen (B-01) |
| `kriegerin-des-lichts` | ja (`info_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg nicht einzeln belegt |
| `blutpriester` | ja (`info_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Spielleiterwahl statt Zufallsknopf (RM-DR-015.2) |
| `amalia` | ja (`info_roles`) | B (Tagesaktion) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `detektiv` | ja (`info_roles`) | M (Morgenbericht; UI-Nachweis fehlt) | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg n. a. (automatisch) |
| `die-ewigen` | ja (`info_roles`) | K | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | Kern-Test, UI-Positivliste nicht einzeln | Buttonweg nicht einzeln belegt |
| `der-weise` | ja (`protection_roles`) | B (Hinrichtung) | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `maertyrerin` | ja (`protection_roles`) | K | ja (3) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `schutzgeist` | ja (`protection_roles`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `dorfschmied` | ja (`protection_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `verdammniswaechter` | ja (`protection_roles`) | K | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `loki` | ja (`bond_roles`, `notices`) | B (Auswahl, Hinweiskarte) | ja (3) | Fuzz-Invariante J; Undo rollenspezifisch getestet | Positivliste (UI-Test) | - |
| `rotkaeppchen` | ja (`bond_roles`, `notices`) | B (Hinweiskarte); Prompt K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `schwarze-witwe` | ja (`bond_roles`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `schattenwanderer` | ja (`bond_roles`) | K | mager (2) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `seelentauscher` | ja (`transform_roles`) | B (Auswahl) | ja (7) | Fuzz-Invariante J; Undo rollenspezifisch getestet | keine | - |
| `daemonischer-wolf` | ja (`transform_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `koenig-lykaon` | ja (`transform_roles`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `kutscher` | ja (`revival_roles`) | B | ja (4) | Fuzz-Invariante J; Undo rollenspezifisch getestet | keine | - |
| `dr-victor-frankenstein` | ja (`revival_roles`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Totenkarten-Bedingung RM-DR-141.4 offen |
| `rattenfaenger` | ja (`solo_roles_a`, `notices`) | B (Hinweiskarte); Prompt K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `pestbringerin` | ja (`solo_roles_a`, `notices`) | B (Hinweiskarte); Prompt K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | Positivliste (UI-Test) | - |
| `prophet-des-untergangs` | ja (`solo_roles_a`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `todesprediger` | ja (`solo_roles_a`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `feuerteufel` | ja (`fire_devil`) | K | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `voodoo-priester` | ja (`voodoo_priest`) | K | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `nekromant` | ja (`necromancer`) | B (Tagesaktion); Nacht K | ja (4) | Fuzz-Invariante J; Undo generisch (Replay) | keine | - |
| `hades` | ja (`hades`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `grabraeuber` | ja (`grave_robber`) | K | mager (1) | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `schicksalswolf` | ja (`fate_wolf`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `rachsuechtiger-wolf` | ja (`lone_wolf_and_time_warden`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `zeitwaechter` | ja (`lone_wolf_and_time_warden`) | K | nur Fuzz | Fuzz-Invariante J; Undo generisch (Replay) | keine | Buttonweg nicht einzeln belegt |
| `kartenschlucker` | nein | nein | nein | nein | nein | Blockiert: Totenkartenmodell (RM-DR-013, RM-DR-143.1/.2); nicht im Katalog |

**Zählung:** 17 Rollen mit Button-Test, 41 nur über Kartendaten, 11 passiv, 2 über Morgenbericht, 1 blockiert (Kartenschlucker). Summe 72.

## Befunde

**Bekannte Fehler (mit Beleg)**

| ID | Befund | Beleg | Einordnung |
|---|---|---|---|
| B-01 | `test_prompt_coverage::test_all_prompt_kinds_are_operable_through_the_card` schlug im ersten Vollauf fehl („Rolle koenig erschien nie als Prompt“), im zweiten Vollauf und in 7 isolierten Läufen grün | Lauf 1 (Vollauf direkt nach `--import`): 917 Tests, 1 fehlgeschlagen; Lauf 2: 917 Tests, 0 fehlgeschlagen; isoliert (`--filter=prompt_coverage`) 7 von 7 grün (2 plus 5) | intermittierender Fehler in der Prüfung, nicht im Spielverhalten belegt. Die Seeds sind fest, eine Zeit- oder Zufallsquelle im Pfad wurde per `rg` nicht gefunden. Ursache **ungeklärt**. Der erste Lauf folgte direkt auf `--import`. Verdacht, nicht Beleg. Wird in P2 als Vorprüfung mit Wiederholungsläufen untersucht |
| B-02 | Einstellungen (Sprache, Bewegung) gehen beim Neustart verloren | `app_settings.gd` ohne Dateizugriff | echter Funktionsmangel (D-09) |

**Fehlende Nachweise statt bekannter Fehler**

- Buttonweg für 41 Rollen (R-02).
- Positivlisten der Zeigekarte für 12 Informationsrollen (I-04).
- Übersetzungs-Bedeutungsgleichheit (C-01).
- Rollenspezifisches Undo außer für 7 Rollen (Rollentabelle).
- Deckungslücke der Wechselwirkungen (N-11).

**Widersprüche zwischen Dokumenten und Code**

- `CODE-COMPLETION-ROADMAP.md` Paket 2 spricht von der „bestehenden `ConfirmRoleShown`-Regel“. Im Code gibt es weder Befehl noch Zustand, nur Spezifikation (`vertical-slice-flow.md` §2, `implementation-boundary.md` B-11). Paket 2 muss den Kernbefehl neu bauen, nicht nur eine Oberfläche ergänzen (S-08).
- `implementation-boundary.md` B-11 listet `BeginDay` und `ReorderSeats`. `BeginDay` ist als Bedienzustand des Morgenberichts gelöst (`cockpit.md`, Entscheidungstabelle), `ReorderSeats` fehlt (S-06).
- Masterplan Kopfzeile „Status: … keine spielbare Partie (Nacht/Tag) über die Oberfläche“ stammt vom Stand 27.09.2026 und ist überholt (Nacht, Morgen, Tag, Sieg bedienbar, `test_full_round_ui`). Historische Angaben wurden nicht umgeschrieben.
- Die Inhaltsentwürfe aus `content/rolebook-and-guide` (`cde16f5`) sind per Kopie in diesem Branch. Die Commits selbst liegen nicht im Verlauf: `git rev-list --count HEAD..origin/content/rolebook-and-guide` = 10. Kein Merge, nur Kenntnisnahme.

## Offene Produktentscheidungen (aus der Matrix)

Nicht beantwortet, nicht durch diesen Auftrag entschieden:

1. Sitzplatztausch während der Partie (S-06).
2. Schema-Anhebung für Rollenübergabe (S-08), oder Bedienzustand nur in der App.
3. Offene Reaktion für Mitlesende verbergen (I-03).
4. Redo nach Neustart und Checkpoint-Rotation für den Offline-Abschluss (D-04, D-05).
5. Freigabe der Rollenlexikon- und Guide-Texte (C-04, C-05).
6. Inhalt von Szenarien, Beispielrunde, Definition Expertenmodus, Timer-Vorgaben (S-04, C-07, C-08, C-10).
7. Kartenregeln (R-03 bis R-05, P8).
8. Endgültige Rollenauswahl 20 bis 30 für Version 1.0 gegenüber 71 implementierten Rollen (Decision Log, „nicht blockierende Punkte“).
9. Unverträgliche Rollenkombinationen als Setup-Regel (R-07).
10. Linkshänder-Schalter jetzt oder im Gestaltungsprojekt (D-10).
