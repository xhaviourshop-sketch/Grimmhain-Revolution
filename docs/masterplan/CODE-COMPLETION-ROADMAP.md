# Grimmhain: Abschluss der Spielfunktionen

> Für Claude Code: Dies ist ein Abschlussplan, kein Auftrag, alle Pakete sofort zu implementieren. Nach Umfangsentscheidung in einer Sitzung mit `superpowers:executing-plans` paketweise ausführen. Keine parallelen Sitzungen im selben Worktree.

**Ziel:** Eine vollständig bedienbare, reproduzierbar getestete Offline-Partie mit dem vereinbarten Rollenbestand. Danach beginnt die Überarbeitung von Darstellung und Bedienkomfort.

**Architektur:** Bestehenden GDScript-Regelkern, GameSession, Projektionen und SaveService beibehalten. Funktionale Bedienung nutzt dieselben Befehle wie der Kern. Keine zweite Regelimplementierung in der Oberfläche.

**Technik:** Godot 4.7.2, typisiertes GDScript, versioniertes JSON, DE/EN, bestehende Headless-Suite und CI.

**Quellen:** `GRIMMHAIN-REVOLUTION-MASTERPLAN.md`, `docs/masterplan/DECISION-LOG.md`, `docs/ui/cockpit.md`, `docs/ui/save-resume.md`, `docs/content-drafts/INTEGRATION-STATUS.md` im Worktree `grimmhain-night-ui`.

**Belege:** Die Abschlussmatrix `CODE-COMPLETION-MATRIX.md` (Paket 1, 29.09.2026) ist die maßgebliche Übersicht. IDs wie `S-08` oder `R-02` verweisen dorthin. Diese Roadmap enthält keine Kalendertermine und keine Aussage „100 Prozent fertig“.

## Verifizierter Ausgangspunkt

- Am 29.09.2026 lokal geprüft: Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui`, Branch `feature/night-ui-expansion`, HEAD `23c7044`, sauber. Er enthält `origin/main`, `audit/all-72-roles` und `integration/cloud-to-local-20260927` vollständig (`git rev-list --count HEAD..<ref>` = 0 für alle drei).
- PR #3 am 29.09.2026 offen, `MERGEABLE`, alle CI-Prüfungen grün (Godot core tests, Asset register). Beim Arbeitsbeginn aktuellen GitHub-Stand erneut feststellen.
- Vollprüfung am 29.09.2026 in Paket 1 ausgeführt: 917 Tests. Lauf 1: 1 fehlgeschlagen (`test_prompt_coverage`, intermittierend, Befund B-01), Lauf 2: 0 fehlgeschlagen. Jeweils Import-Exit 0. Details in der Matrix.
- 71 Rollen implementiert; Kartenschlucker wartet auf Totenkartenregeln.
- Setup, Sitzordnung, Start, Nacht, Morgen, Tag, Hinrichtung, Sieg, Speichern und Undo sind bereits vorhanden. Bestehendes Verhalten überprüfen, nicht neu bauen.
- Schema 13 und Regelversion 0.12. Ältere Saves werden erkannt und erhalten, nicht automatisch migriert. *(Stand nach Paket 2: Schema 14, Regelversion 0.12.)*
- Rollen-zeigen-Modus und bestimmte Spezialkorrekturen sind funktionale Lücken. **Korrektur nach Untersuchung:** `ConfirmRoleShown` existiert im Code nicht, nur in der Spezifikation. Der Rollen-zeigen-Modus braucht daher einen neuen Kernbefehl, nicht nur eine Oberfläche (Matrix S-08).
- Ein Teil der Tests bedient Kartendaten über GameSession. Das beweist nicht für jede Rolle den tatsächlichen Weg über Buttons und Karten.
- Aktuelle Inhaltsentscheidungen DI-01 bis DI-08 sind integriert. Lexikon und übrige Führungstexte bleiben Entwürfe.

## Umfang und Reihenfolge

Erster Abschluss: **Offline-Funktionsstand mit 71 Rollen und 6 bis 24 Personen**. Dieser Zwischenstand ist keine Kürzung des Gesamtprodukts.

Danach folgen als eigene technische Pakete Kartenschlucker/Totenkarten, Smartphone-Clients, Netzwerk-Zweitanzeige und Plattformvorbereitung. Ein Abschluss von 71 Rollen darf nicht als Abschluss aller 72 Rollen bezeichnet werden. Online-Remote-Spiel bleibt gemäß Masterplan ein späteres Produkt mit eigener Spezifikation und Stop/Go; Steamworks hängt von verfügbaren SDKs und Zugängen ab.

Es gibt keine Tages- oder Wochenfrist. Ein Paket beginnt nach Erfüllung seiner Voraussetzungen und endet mit seinen Abnahmekriterien. Neue Anforderungen werden einsortiert, statt als angeblich bereits erledigt betrachtet zu werden.

Auch bei abgeschlossenem Offline-Funktionsstand entsteht später Code für Layout, Animationen, Audio und neue QoL-Funktionen. Ziel ist ein stabiler Funktionsstand, kein Versprechen, dass nie wieder Code geändert wird.

## Globale Vorgaben

- Keine sichtbaren Programme starten: kein Godot-Fenster, Editor, Browser, Screenshot-Werkzeug oder Fokuswechsel. Nur Headless-Prozesse.
- Bestehende Nutzer-Spielstände nicht verändern. Dateitests ausschließlich mit isolierten Testverzeichnissen.
- Kleine logische Korrekturen selbst entscheiden und als technische Ableitung dokumentieren. Grundlegende Fähigkeiten oder schwierige Regelkonflikte mit drei Auswahlantworten und Freitext klären.
- Regelkern, private Sicht, öffentliche Sicht und einzelne Spielerkarte getrennt halten.
- Keine Grafikproduktion und kein Layout-Umbau in diesem Auftrag. Neue funktionale Bedienelemente können vorläufig schlicht sein.
- Für spätere Gestaltung festhalten: 85 bis 90 Prozent Spielfeld, übrige Bedienung kompakt oder bei Bedarf eingeblendet. Dies gilt für die Standardansicht, nicht als Sperre für notwendige Informationskarten.
- Nach jeder korrigierten Lücke: reproduzierender Test, gezielte Prüfung, Commit. Vollsuite am Paketabschluss, nicht nach jedem Textschritt.
- Bei etwa 70 Prozent Kontext Übergabenotiz aktualisieren; bis 80 Prozent Komprimierung einplanen. Nicht behaupten, ein Prompt könne allein automatisch `/compact` auslösen.

## Prüfschwerpunkte

1. Abbruch oder Neustart während offener Auswahl: identische Fortsetzung ohne doppelten Effekt.
2. Rollenwechsel oder Tod während offener Aktion: veraltete Ziele und Karten verlieren ihre Gültigkeit.
3. Private Karten und öffentlich sichtbare Todeseffekte: nur ausdrücklich erlaubte Angaben gelangen an Spieler.
4. Wiederbelebung, Kettentod und Umlenkung: richtige Reihenfolge, keine Endlosschleife, Sieg erst im vorgesehenen Zustand.
5. Fehler beim Speichern oder Laden: letzter gültiger Stand erhalten, sichtbare Fehlermeldung, kein stiller Neustart.

## Paket 1: Abschlussmatrix und aktueller Stand

**Quellen:** Masterplan, Decision Log, `PROGRESS.md`, bestehende Unit-/UI-Tests.
**Ergebnis:** Neue Abschlussmatrix mit Anforderung, Implementierung, Testbeleg und Restlücke.

- [x] Aktuellen HEAD, Arbeitsverzeichnis, PR und Herkunft der Rollenfassung feststellen. Fremde Änderungen nicht überschreiben. *(Nachweis: Matrix, Kopf; `git rev-list`, `gh pr view 3`. Herkunft der Rollen: `audit/all-72-roles` vollständig enthalten. Inhaltsentwürfe aus `content/rolebook-and-guide` per Kopie, Commits nicht im Verlauf.)*
- [x] Für jeden im Umfang enthaltenen Bedienweg den vorhandenen Code und Testbeleg zuordnen. *(Nachweis: Matrix, Abschnitte „Funktionen“.)*
- [x] Alle 71 Rollen auflisten. *(Nachweis: Matrix, Rollenübersicht mit 72 IDs. Spalten: Kern, Bedienweg, Querbezüge, Save/Load und Undo, Spielerinformation, Restlücke. Nicht einzeln für alle Rollen erhoben: Verbrauch, Siegbezug; diese stehen in den Einzeltests und werden in Paket 3 je Familie ergänzt.)*
- [x] Veraltete Masterplan-Angaben vom aktuellen Stand unterscheiden. Historische Fortschrittsberichte nicht umschreiben. *(Nachweis: Matrix, „Widersprüche zwischen Dokumenten und Code“.)*
- [x] Offene Anforderungen aus dem Masterplan ausdrücklich als Abschlussumfang, späteres QoL oder separates System zuordnen. Keine Anforderung still streichen. *(Nachweis: Matrix, Spalte „Paket“; Abschnitt „Offene Produktentscheidungen“.)*
- [x] Einmal die Ausgangsprüfungen laufen lassen; rote Befunde vor weiterem Ausbau untersuchen. *(Ergebnis: Vollsuite 917 Tests; einmal rot, dann grün (B-01, Ursache offen). Assetregister, Rollendokumente, Inhaltsabdeckung, Prüfertests, `git diff --check` grün. Untersuchung von B-01 ist Vorprüfung in Paket 2.)*

**Abnahme:** Jede im Umfang enthaltene Anforderung hat einen Beleg oder ein nachfolgendes Paket. Unbekannte Lücken sind nicht grün.

**Stand: erledigt am 29.09.2026** (Matrix `CODE-COMPLETION-MATRIX.md`). Nicht als „Offline-Funktionsstand“ gewertet: Die Matrix hat offene Lücken, siehe „Nächstes Umsetzungspaket“.

## Paket 2: Alle bestehenden Befehle tatsächlich bedienbar machen

**Betroffene vorhandene Dateien:** `godot/app/session/game_session.gd`, `godot/app/session/prompt_view.gd`, `godot/app/screens/cockpit/cockpit_screen.gd`, `action_card.gd`, `cockpit_layers.gd`, `godot/content/i18n/ui.de.po`, `ui.en.po`.

- [x] **Vorprüfung B-01:** *(Erledigt: Ursache `Array.shuffle()` mit globalem Zufall im Test, Regressionstest und feste Erreichbarkeitsszenarien; Matrix B-01, Decision Log DA-30.)* `test_prompt_coverage` intermittierend rot („Rolle koenig erschien nie als Prompt“). Ursache eingrenzen (Wiederholungsläufe, vollständig und nach `--import`), bevor weitere Bedienwege darauf aufbauen. Kein Abschwächen des Tests.
- [x] *(Erledigt in Paket 2, Schema 14, DA-26 bis DA-28; Geräteabnahme offen)* Rollen-zeigen-Modus ergänzen (Matrix S-08): Kernbefehl `ConfirmRoleShown` und Zustand fehlen im Code und müssen neu entstehen (Spec `vertical-slice-flow.md` §2 und AS-A04). Person gezielt auswählen, nur zulässige Informationen zeigen (Rolle und Kurztext, beim Trugbilderwolf keine Scheinrolle, DI-08), bewusst schließen, private Ansicht wiederherstellen, nach Abbruch bei der ersten unbestätigten Person fortsetzen. Vorher klären: Schema 13 auf 14 (alte Saves erneut gesperrt) oder Bedienzustand in der App.
- [x] *(Erledigt in Paket 2, DA-29)* Spezialkorrekturen für Schutz, Rettung, Wolfskind und Lehrling über bestehende Kernbefehle erreichbar machen (Matrix N-06). Der Kern kennt `set_protection`, `remove_protection`, `set_rescue`, `remove_rescue`, `set_wolf_model`, `remove_wolf_model`, `transform_wolf_child`, `revert_wolf_child`, `set_apprentice_master`, `remove_apprentice_master`, `trigger_apprentice_inheritance`, `revert_apprentice_inheritance`; die Oberfläche bietet nur `kill, revive, set_role, status, execute, declare_winner`. Gründe, Warnung und Protokoll verwenden.
- [x] Prüfen, welche weiteren Korrekturen der Kern kennt, aber die Oberfläche nicht anbietet. *(Untersucht in Paket 1: die zwölf Arten oben; `set_witch_potion`, `set_mirror`, `set_ever_nominated`, `set_role_field` sind über „Status ändern“ erreichbar.)* Nur vom bestehenden Produktumfang gedeckte Lücken schließen.
- [x] Abbrechen, ungültiges Ziel, veraltete Auswahl, Undo und Reload für jeden neuen Bedienweg gezielt prüfen. *(`test_role_show`, `test_special_corrections`.)*
- [x] Tagesaktionen, Todesreaktionen, Siegbestätigung und private Hinweise auf vollständige Bedienbarkeit prüfen. *(Nachweis: `test_cockpit_day`, `test_notice_cards`, `test_full_round_ui`, Matrix N-02 bis N-04, N-09.)* ~~Offen: I-03 (offene Reaktion für Mitlesende erkennbar, Produktentscheidung).~~ *(I-03 entschieden durch PE-01 und am 29.09.2026 umgesetzt: neutrale Hinweiszeile, `test_public_reaction_hint`.)*

**Abnahme:** Kein vereinbarter Spielablauf braucht Konsole, direkte Zustandsmanipulation oder Entwicklerwissen. Ungültige Eingaben ändern Zustand und Ereignisverlauf nicht.

**Stand Matrix:** Offen sind S-08, N-06 und Q-04 (Vorprüfung). Alles andere in diesem Paket ist belegt.

## Paket 3: Rollen- und Interaktionsprüfung bis zur Bedienung

**Tests:** Bestehende `godot/tests/unit/test_role_interactions.gd`, `test_role_interaction_fuzz.gd`, `godot/tests/ui/test_target_selection.gd`, `test_notice_cards.gd` und passende rollenbezogene Tests erweitern, statt parallele Testsysteme einzuführen.

- [x] *(Paket 3: `test_role_buttons`, `test_role_passive_ui`, alle 71 Rollen)* Pro Rolle mindestens einen repräsentativen Ablauf durch echte UI-Handler/Buttons headless ausführen und das erwartete Ergebnis prüfen. Ein akzeptierter Befehl allein reicht nicht. *(Stand: 17 von 71 Rollen mit Button-Test, 41 nur über Kartendaten (`test_prompt_coverage`), 11 passiv ohne Bedienung, 2 über den Morgenbericht (Matrix R-02). Zu ergänzen: die 41 `K`-Rollen, gruppiert nach Prompt-Form, nicht als 41 Einzeltests.)*
- [x] *(Paket 3: `test_role_operation_kinds` und Invarianten im Treiber)* Gemeinsame Bedienarten parametrisiert prüfen: Einzelziel, Mehrfachziel, Ja/Nein, Rollenwahl, Zahlenwahl, Ablehnung, verpflichtende Auswahl und erlaubtes Überspringen.
- [x] *(Paket 3: Zuordnung in `11-role-audit-status.md` §4.2, acht neue Szenarien)* Für jede Mechanikfamilie konkurrierende Effekte prüfen: Schutz gegen passende Todesursache, Umlenkung gegen Immunität, Ketten gegen Wiederbelebung, Rollenwechsel gegen Ressourcen, Bindungen gegen Tod, Solo-Sieg gegen Fraktionssieg.
- [x] *(Paket 3; Fuzz zusätzlich unabhängig vom globalen Zufall)* Jede bekannte seltene Interaktion mit einem festen Szenario absichern. Fuzztests ergänzen diese Szenarien, ersetzen sie nicht.
- [x] *(Paket 3, Methode in `12-role-combination-analysis.md` §1)* Nicht wahllos 71 × 71 Paare erstellen. Zuerst mechanisch relevante Überschneidungen aus der Matrix ableiten; jedes ausgelassene Risiko begründen. *(Stand: 11 feste Szenarien in `test_role_interactions`, Rest nur Fuzz (Matrix N-11).)*
- [x] *(Restpaket 29.09.2026: `test_info_roles`, `test_random_pick`, Matrix R-06)* Zufallsknopf nach RM-DR-015.2 (entschieden) für König, Traumdeuter, Kopfgeldjäger, Blutpriester über den gespeicherten Generator ergänzen (Matrix R-06). *(Spielleitertexte der vier Rollen: OI-09, Paket 5.)*
- [x] *(Analyse: `docs/role-migration/12-role-combination-analysis.md`; Setup-Hinweise nach PE-04 umgesetzt am 29.09.2026, `test_setup_hints`, DA-47 bis DA-49)* Analyse unverträglicher Rollenkombinationen (vom Product Owner gewünscht, Setup-Regel vertagt; Matrix R-07). Erst Analyse, Regel nur nach Entscheidung.
- [x] *(Paket 3: Stimmhinweise, Matrix B-03)* Tatsächliche Fehler testgetrieben beheben. Keine Tests abschwächen, bis Grün erreicht ist.

**Abnahme:** Die Matrix hat für alle 71 Rollen und relevanten Interaktionsklassen nachvollziehbare Belege. Das bedeutet geprüfte Korrektheit, keine mathematische Bugfreiheitsgarantie.

## Paket 4: Wiederaufnahme, Geheimhaltung und Betriebsfehler

**Dateien:** `godot/app/session/save_service.gd`, `game_session.gd`, `cockpit_view.gd`, `morning_report.gd`; bestehende Tests `test_save_service`, `test_save_versions`, `test_corrupt_save`, `test_notices`.

- [x] *(Paket 4: `test_resume_scenarios`, `test_process_restart`)* Neustart bei offenem Prompt, offener Todesreaktion, privatem Hinweis, Morgenbericht und Siegkandidat prüfen. *(Neun Unterbrechungsstellen über Hauptmenü → „Fortsetzen“, dazu ein echter zweiter Godot-Prozess; erhalten/verworfen je Stelle in `docs/ui/save-resume.md`.)*
- [x] *(Paket 4: `test_resume_every_command`)* Gespeicherte Partie vor und nach Rollenwechsel, Wiederbelebung und Kettentod laden; Zustand, Ereignisse und zulässige nächste Aktion vergleichen. *(Neustart über die Datei nach jedem Befehl von sechs Mischpartien, auch Ressourcenverbrauch, Spielleiterkorrektur, Rollen- und Hinweisbestätigung.)*
- [x] *(Paket 4: `test_save_service`, Befund B-04 behoben)* Unterbrochenes Schreiben, fehlende Schreibrechte, defekte Hauptdatei und defektes Backup mit isolierten Testdaten simulieren. *(Schreibrechte über eine im Pfad stehende Datei und den Testanschluss `simulate_failure`, nicht über Kontorechte.)*
- [x] *(bestehend, in Paket 4 unverändert: `test_save_service`, `test_save_versions`)* Verhalten alter Schemaversionen beibehalten: verständliche Sperre, Datei erhalten. Migration ist kein stiller Zusatzauftrag.
- [x] *(Paket 4: Undo und Redo nach dem Fortsetzen in `test_resume_scenarios`; „Erneut speichern“ ist kein Spielbefehl)* Undo/Redo nach jeder neu ergänzten Bedienung prüfen. Redo nach Neustart bleibt nur dann Aufgabe, wenn die Abschlussmatrix es ausdrücklich verlangt. *(Matrix D-05: Spezifikation B-12 verlangt „über Neustart“, Umsetzung verwirft Wiederholen beim Neustart.)* *(Entschieden durch PE-03, 29.09.2026: Wiederholen entfällt beim Neustart; B-12 angepasst.)*
- [x] *(Paket 4: `test_output_positive_lists`, Matrix I-06; Inventar aller Ausgabewege in `docs/ui/cockpit.md`, Abschnitt „Geheimhaltung der Ausgabewege“)* Für öffentliche und personenbezogene Karten Positivlisten prüfen. Keine fremde Rolle, Scheinrolle, geheime Ursache, Schutzmarkierung oder andere private Hinweise durchreichen. *(Matrix I-04: Zeigekarte nur für Orakel, Hinweiskarten und Morgenbericht einzeln geprüft; zwölf weitere Informationsrollen offen.)*
- [x] *(Entschieden durch PE-02, 29.09.2026: eine `.bak` je Partie reicht; ein eigener Reparaturdialog ist nicht Teil der Entscheidung und nicht gebaut, Matrix D-04)* Checkpoint-Rotation und Reparaturdialog (Masterplan Phase 3) einordnen (Matrix D-04): heute eine `.bak`. Nutzerentscheidung, ob für den Offline-Abschluss nötig.
- [x] *(PE-01 umgesetzt am 29.09.2026: öffentliche Hinweiszeile neutral, `test_public_reaction_hint`, DA-46)* Offene Reaktion für Mitlesende erkennbar (Matrix I-03): Produktentscheidung, nicht still ändern. *(Paket 5a: nur Teil 1, die Hinweiszeile. Teil 2 siehe nächster Punkt.)*
- [ ] I-03 Teil 2: Die öffentliche Phase „Morgen“ bleibt bei offener Reaktion stehen, und statt des Morgenberichts erscheint eine verdeckte Karte; Mitlesende können daraus auf eine offene Reaktion schließen (Matrix I-03, DA-46 benennt die Grenze, gibt sie aber nicht frei). Eigener Auftrag: klären, ob Kernphase oder nur Darstellung angepasst wird; nicht still ändern.
- [x] *(bestehend: `test_death_effect_lines`, `test_death_effects`, Fuzz-Ausnahme `is_death_effect_exception`)* Öffentliche Todesreaktionen als erlaubte Ausnahme testen. Geheimhaltungstests dürfen diese Ausnahme nicht fälschlich verbieten.

**Abnahme:** Keine bekannte Datenverlustlücke, doppelte Aktion oder unerlaubte Informationsweitergabe. Fehler führen zu einem verständlichen und fortsetzbaren Zustand.

**Stand nach Paket 4 (29.09.2026):** Automatisierte Prüfungen abgeschlossen, Produktentscheidungen offen: Checkpoint-Rotation (D-04), Redo nach Neustart (D-05), offene Reaktion für Mitlesende (I-03). Keine vollständige Abnahme, keine Geräte- oder Touchabnahme. *(Restpaket: Warnung auch bei mobilem Zurück und Fensterschließen, B-06; R-06 umgesetzt. Offen aus Paket 3 bleibt die Setup-Regel zu R-07, Entscheidung.)*

**Stand nach PE-01 bis PE-04 (29.09.2026):** Die Produktentscheidungen D-04, D-05 (PE-02, PE-03, Ist-Stand ist Vorgabe), I-03 (PE-01) und R-07 (PE-04) sind entschieden und umgesetzt bzw. in den Vorgaben nachgezogen. Paket 4 ist damit automatisiert abgeschlossen; Geräte- und Touchabnahme bleiben offen. *(Berichtigt in Paket 5a: I-03 ist nur in Teil 1 umgesetzt, der Rückschluss aus Phase und Kartenfolge bleibt offen.)*

## Paket 5: Inhalte und Medienanschlüsse

**Quellen:** `docs/content-drafts/rolebook/`, `GUIDE-TEXTS.md`, `OPEN-ISSUES.md`, `INTEGRATION-STATUS.md`, DE-/EN-Übersetzungen und `godot/app/settings/app_settings.gd`.

- [x] Rollenlexikon gegen aktuellen Kern und Decision Log abgleichen. Veraltete Aussagen nicht blind übernehmen. *(Paket 5b: 26 Zellkorrekturen, Dokumentverweise entfernt, 15 Rollen mit gekennzeichneten offenen Punkten, DA-56, DA-58.)*
- [x] Für alle 71 Rollen eindeutige Fähigkeit, Ziele, Grenzen, Zeitpunkt und Spielleiteranweisung im Programm erreichbar machen. *(Paket 5b: Hauptmenü, Setup, Cockpit mit Kontexthilfe; `test_role_lexicon_content`, `test_role_lexicon_ui`; Matrix C-04, C-05 TEIL wegen redaktioneller Endabnahme und fehlendem allgemeinem Regelbuch.)*
- [x] PE-06 umsetzen: Phase „Alle Verzauberten“ nach jedem Aufruf des Rattenfängers als eigener Nachtplan-Eintrag (Ausfallregel, Tarnaufruf-Reihenfolge, private Karte, Ersatz des `piper_all`-Hinweises, Replay/Save-Load, Regelversion 0.13). *(Matrix N-12, DA-55.)*
- [ ] Fehlende DE-/EN-Schlüssel, Platzhalter und dynamische Rollennamen automatisch prüfen. Bedeutungsgleichheit zusätzlich gezielt redaktionell prüfen. *(Paket 5a: automatischer Teil erledigt, `tools/check-godot-i18n.js` mit 17 Regressionstests und CI-Workflow `godot-i18n.yml`, Matrix C-01, Q-07. Grenzen: 47 dynamische Vorlagen nur als Vorlage, Werte aus Variablen nicht statisch. Offen: redaktionelle Prüfung.)*
- [ ] Vorlesetext, öffentliche Ansage und private Spielerinformation konsequent getrennt halten.
- [ ] Vorhandene Einstellungen auf wirksame Funktionen prüfen. Ein Schalter ohne Wirkung zählt nicht als abgeschlossen. *(Untersucht: Sprache und „Bewegung reduzieren“ wirken, werden aber nicht gespeichert (Matrix D-09, Befund B-02). `left_handed` ist eine Variable ohne Schalter und Wirkung (D-10).)* Einstellungen dauerhaft speichern; Umfang von D-10 entscheiden lassen. *(Paket 5a: Sprache und „Bewegung reduzieren“ werden dauerhaft gespeichert und vor der ersten Ansicht angewendet, `test_settings_persistence`, Matrix D-09, DA-52. Der Linkshänderwert wird mitgespeichert, bleibt aber ohne Schalter und Wirkung; D-10 bleibt Entscheidung für Gestaltungsprojekt oder eigenen Auftrag.)*
- [ ] Medienanschlüsse nur so weit ergänzen, wie das bestätigte Produkt sie bereits benötigt: Ereignisse für Sound/Animation, stummes Verhalten bei fehlenden Medien, Abbruch ohne Einfluss auf Spielregeln. Keine große generische Effekt-Engine vorsorglich bauen.
- [ ] DI-09 exakt einmal auslösbar und ohne Datei gefahrlos prüfbar machen, sofern Audio-Technik zum gewählten Abschlussumfang gehört. Finale Tondatei bleibt Medienproduktion. *(Matrix X-05: nicht umgesetzt.)*

**Abnahme:** Die Partie ist ohne zusätzliche Grafik-, Audio- oder Videodateien vollständig leitbar. Fehlende Medien blockieren keinen Befehl und geben keine unbeabsichtigten Geheimnisse preis.

**Stand nach Paket 5a (29.09.2026):** Einstellungen dauerhaft (D-09), struktureller i18n-Prüfer in CI (C-01, Q-07), Inhaltsstand bereinigt: OI-12, OI-13, OI-17 mit DI-04 bis DI-07 verknüpft, OI-09-Texte an den Zufallsknopf angepasst, Integrationsliste für Paket 5b in `docs/content-drafts/INTEGRATION-STATUS.md`. Echte offene Inhaltsfragen: zwei (OPEN-ISSUES §5 Nr. 1 und 2). Paket 5b: Lexikon- und Spielleitungstexte ins Programm, sobald Anzeigeort und Freigabe feststehen.

**Stand nach Paket 5b (29.09.2026):** Rollenlexikon im Programm (C-04 TEIL), Kontexthilfe im Cockpit (C-05 TEIL), PE-05 umgesetzt, PE-06 entschieden und als Folgeauftrag beschrieben (N-12), Terminologie der Kurztexte angeglichen, GUIDE-TEXTS §3.3/§3.4 an den integrierten Wortlaut angeglichen. Vollsuite 1096 Tests. Offen: redaktionelle Endabnahme, allgemeines Regelbuch, Handlungszeilen (OI-18), I-03 Teil 2, D-10, X-05.

**Stand nach PE-06 (29.09.2026):** „Alle Verzauberten“ ist ein eigener Nachtschritt hinter dem Rattenfänger (Matrix N-12 AUTO, DA-60 bis DA-64, Regelversion 0.13). Neu offen: PE-07, ob tatsächlich keine Rolle außer den Gebundenen doppelt vorkommen darf (Setup-Grenzen).

**Stand nach PE-07 (30.09.2026):** PE-07 ist beantwortet (Option B) und umgesetzt: In der Startbesetzung kommt jede Rolle höchstens einmal vor, Die Gebundenen (1 bis Personenzahl) sind die einzige Ausnahme; gleiche Rollen, die erst im Spiel entstehen, bleiben unverändert. Regelversion 0.14, Schema 14 (Decision Log „PE-07-Umsetzung (30.09.2026)“, DA-65 bis DA-72). Fester Rollenvorschlag für 6 bis 24 Personen, Setup-Texte DE/EN, Entwurf über der Höchstzahl wird erklärt und nicht gekürzt, Weg von „Neue Partie“ bis zum ersten Tag über echte Buttons für 6, 13 und 24 Personen, Grabräuber mit gestohlenem Rattenfänger nachgewiesen. Vollsuite 1134 Tests, 0 fehlgeschlagen. Offen bleiben die Produktfragen in `NIGHT-QUESTIONS-2026-09-30.md` und ein Layoutbefund im Rollenschritt (1024×768, zwei Fehlerzeilen, vor PE-07 vorhanden).

**Stand Matrix:** Rollenname, Kurztext und neun Lexikonfelder je Rolle im Programm (`ui.role.*`, 796 Schlüssel je Sprache). Allgemeines Regelbuch (C-05) fehlt. Bedingung für Abschluss von C-04: redaktionelle Endabnahme.

## Paket 6: Technikabschluss und Übergabe an die Gestaltung

**CI:** `.github/workflows/godot-core-tests.yml`, `asset-register.yml`, vorhandene Dokument-/Inhaltsprüfer.

- [ ] Einen unabhängigen zweiten Prüfdurchgang des Diffs durchführen, ohne gleichzeitig am selben Worktree zu arbeiten.
- [ ] Verbindliche Regel-/Dokument-/Übersetzungsprüfer in CI aufnehmen, soweit bislang nur lokal ausgeführt. Keine redundante zweite CI-Suite. *(Matrix Q-03: nur lokal laufen `node tools/role-migration/check-role-docs.js`, `node --test tests/check-role-docs.test.js`, `python docs/content-drafts/check-coverage.py`. Der Godot-Workflow startet nur bei Änderungen unter `godot/**`.)* *(Paket 5a: Der Godot-i18n-Prüfer läuft in `godot-i18n.yml`; die übrigen genannten Prüfer bleiben lokal.)*
- [ ] Vollständige Headless-Suite, Register, Rollenprüfung, Inhaltsprüfung und `git diff --check` ausführen; Exit-Codes und Laufzeitfehler kontrollieren.
- [ ] Windows-Export und Exportvoraussetzungen für iPadOS/Android inventarisieren. Fehlende SDKs, Signierung und Mac-Gerätetests ausdrücklich als Plattformblocker ausweisen. Ein Headless-Lauf ersetzt keinen Tablet-Test. *(Matrix P-01 bis P-03: im Repository liegt kein `export_presets.cfg`; ob Godot-Exportvorlagen 4.7.2 installiert sind, ist noch nicht ermittelt.)*
- [ ] Kurzen manuellen Funktionstest vorbereiten: Setup, eine Nacht, private Karte, Morgen, Nominierung/Hinrichtung, Speicher-Wiederaufnahme, Undo und Sieg. Nur Nutzer startet Fenster, wenn der Bot pausiert ist.
- [ ] Nicht visuell prüfen können als offene Abnahme kennzeichnen, nicht als fertigen Tablet-Release verkaufen.
- [ ] PR #3 und Folgeänderungen nachvollziehbar integrieren. Ohne neuen Mergeauftrag PRs offen lassen; keine automatische Umgehung der bestehenden Abnahme.
- [ ] Abschlussbericht mit festem HEAD, Testbefunden, bekannten Grenzen und getrennten Listen für Spielfunktionsfehler, Gestaltung/QoL und spätere Systeme erstellen.

**Abnahme:** Null bekannte blockierende Fehler im vereinbarten Offline-Funktionsumfang, alle verpflichtenden automatischen Prüfungen grün, keine unzugeordneten Anforderungen. Nicht bestandene Punkte werden offen ausgewiesen.

## Paket 7: Übrige vereinbarte Offline-Funktionen

- [ ] Gespeicherte Gruppen und deren Wiederverwendung ergänzen. *(Untersucht: nicht vorhanden, Matrix S-02.)* Namen übernehmen, neue Personen-IDs je Partie, keine alte Rolle/Markierung übernehmen.
- [ ] Szenariobasierte Rollenwahl gegen gültige Rollen-IDs, Personenanzahl und bestätigte Kompositionsregeln validieren. Keine neuen Szenarioregeln erfinden. *(Untersucht: nicht vorhanden, Matrix S-04; Inhalt der Szenarien ist Nutzerentscheidung.)*
- [ ] Geführten und Expertenmodus funktional vervollständigen. Beide benutzen denselben Kern, dieselben Schutzprüfungen und dieselben Speicherpunkte. *(Matrix C-06, C-07: das Cockpit führt bereits; „Regelgrund“ und Expertenmodus fehlen, kein Modusbegriff im Code.)*
- [ ] Beispielrunde und Übungsmodus mit isolierten Spielständen ermöglichen. Eine Übungsrunde darf keine echte laufende Partie überschreiben. *(Matrix C-08: nicht vorhanden.)*
- [x] Chronik/Nachspielbericht aus vorhandenen Ereignissen erzeugen. Vor Spielende nur freigegebene Angaben exportieren; private Daten nur nach bewusster Wahl. *(Paket D, 30.09.2026: Abschlussbericht, Partiehistorie, Textexport; erweiterter öffentlicher Umfang offen als NQ-07; Geräteabnahme offen.)*
- [ ] Timer als Anwendungskomponente ohne Einfluss auf Regeln ergänzen. *(Matrix C-10: fehlt, kein Timer in `app/`.)* Neustartverhalten und Pause definieren; Zeitablauf führt nie eigenständig eine Hinrichtung aus.
- [ ] Sitzplatztausch nach Spielstart (`ReorderSeats`, Matrix S-06) einordnen. Er verändert Sitznachbarn im Regelkern; nur nach Nutzerentscheidung.

**Abnahme:** Jede entsprechende Masterplan-Anforderung ist funktional nachgewiesen oder mit einer ausdrücklichen Produktentscheidung zurückgestellt. Keine automatische Aufblähung durch neue Komfortideen.

## Paket 8: Totenkarten und die 72. Rolle

- [ ] Vorhandene Kartentexte und bisher bestätigte Regeln gezielt inventarisieren. Offene Entscheidungen mit Beispielen und drei Auswahlmöglichkeiten plus Freitext stellen.
- [ ] Ziehen, Kartenbesitz, Ausspielen, Verbrauch, Austausch und Karteninformationen eindeutig festlegen. Automatisierte Karten und lediglich vom Spielleiter geführte Karten kennzeichnen.
- [ ] Seeded-Ziehung, Zustandsmodell, Befehle und Speichern erst aus diesen Entscheidungen ableiten. Unbekannte Kartenwirkung nicht als umgesetzt darstellen.
- [ ] Kartenschlucker danach gemäß bestätigten Fähigkeiten implementieren, inklusive Austausch, Schwellen, Ressourcen, Tod, Rollenverlust, Undo und Save/Load.
- [ ] Karteneinflüsse auf Wiederbelebungsmodus, Nachtreihenfolge, Todespipeline, Sieg und Geheimhaltung testen.

**Abnahme:** 72 Rollen innerhalb der definierten Kartenmechanik geprüft. Ist eine Entscheidung noch offen, bleibt dieses Paket blockiert; unabhängige Pakete dürfen weiterlaufen.

## Paket 9: Smartphone-Clients und öffentliche Zweitanzeige

- [ ] Zuerst bestätigte Netzwerkarchitektur auf Godot/iPadOS/Android technisch prüfen. Den lokalen Host-Ansatz nicht ungeprüft als auf allen Tablets möglich voraussetzen.
- [ ] Lokalen Sitzungsbeitritt mit QR-Code, Einmalcode und Bestätigung durch die Spielleitung umsetzen. Gerätezuteilung an Personen-ID binden, nicht an Sitzplatz.
- [ ] Spielerprojektion separat vom Gesamtzustand erzeugen: eigene zulässige Rolle/Information, bewusste Rollenanzeige, neutrale Tagesansicht. Keine Daten anderer Spieler übertragen.
- [ ] Öffentliche Zweitanzeige ausschließlich aus freigegebener Projektion versorgen: Namen, Sitzordnung, lebendig/tot und erlaubte öffentliche Ansagen.
- [ ] Verbindungsabbruch, Wiederverbindung, Gerätewechsel und widerrufene Tokens testen. Alte Aktionen dürfen bei Reconnect nicht nachträglich angewendet werden.
- [ ] Jede Smartphone-Funktion muss über das Spielleiter-Tablet ersetzbar bleiben.
- [ ] Authentifizierung und Projektionen automatisiert negativ prüfen. Headless-Netzwerktests ohne sichtbare Browser durchführen.

**Abnahme:** Kein Geheimnisleck, kein fremder Gerätezugriff, keine doppelte Aktion. Echte Netzwerkabnahme auf Nutzergeräten bleibt zusätzlich erforderlich.

## Paket 10: Mediensteuerung und technische Plattformbasis

- [ ] Vorhandene Audio-Technik zuerst prüfen; danach Master/Musik/Ambiente/Cues/UI, wirksame Lautstärke/Stumm und persistente Einstellungen vervollständigen. *(Untersucht: keine Audio-Technik vorhanden, nur Platzhaltertext in den Einstellungen, Matrix X-01. Vorhanden sind die Anschlussstellen `events_applied`, `set_backdrop_art`, `set_portrait`, X-02.)*
- [ ] Ereigniscues für bestätigte Phasen und öffentliche Effekte bereitstellen. Private Informationen dürfen nicht durch öffentlichen Ton oder dessen Länge verraten werden, außer ausdrücklich bestätigter DI-09-Ausnahme.
- [ ] Untertitel, Skip, Reduced Motion und fehlende Medien behandeln; Regeln laufen unabhängig von Wiedergabe und Animationsdauer.
- [ ] Für iPadOS, Android und Windows reproduzierbare Exportkonfigurationen und technische Voraussetzungen festhalten. Credentials/Signierung nicht erfinden.
- [ ] Pause, Hintergrundwechsel, Rotation und Wiederaufnahme vorbereiten und auf echten Geräten überprüfen, sobald Nutzer und Infrastruktur verfügbar sind.
- [ ] Für spätere Steam-Veröffentlichung zunächst den Windows-Build prüfen. Steamworks nur bei bestätigtem Funktionsumfang und vorhandenem Zugang integrieren; kein spekulatives Plattformframework bauen.

**Abnahme:** Medien können später eingesetzt werden, ohne Regeln umzubauen. Automatisiert belegbare Export-/Laufzeitfunktionen sind geprüft; Signierung und Geräteabnahmen bleiben separat sichtbar.

## Paket 11: Gesamtabschluss vor dem Gestaltungsprojekt

- [ ] Abschlussmatrix erneut gegen den vollständigen Masterplan abgleichen, einschließlich Paketen 7 bis 10.
- [ ] Relevante Rollen-, Karten-, Client- und Dateisystemtests im gemeinsamen Integrationsstand ausführen.
- [ ] Kontrollierte Testpartien mit 6 und 24 Personen, Wiederbelebung, privaten Informationen, Todeseffekten, Geräteabbruch und Reload durchführen.
- [ ] Offene Produktentscheidungen, Plattformblocker und bewusst spätere Online-/Releasearbeiten getrennt ausweisen.
- [ ] Die tatsächlich erreichte Abschlussstufe nennen: Offline-Funktionsstand, vollständige vereinbarte Spielfunktionen oder auf Geräten abgenommen. Diese Stufen nicht vermischen.

**Abnahme:** Im eingefrorenen Umfang gibt es keine bekannten funktionalen Lücken oder blockierenden Fehler. Erst danach die umfangreiche Gestaltung als Hauptauftrag beginnen. Echte Gerätetests können weitere Codekorrekturen ergeben.

## Nächstes Umsetzungspaket (aus der Matrix, 29.09.2026)

**Paket 2: Alle bestehenden Befehle tatsächlich bedienbar machen.** Begründung der Reihenfolge:

1. S-08 ist die größte Lücke im vereinbarten Offline-Ablauf: Es gibt keine sichere Rollenkarte je Person am Tablet (Masterplan Phase 4), und sie braucht als einzige der Bedienlücken einen neuen Kernbefehl samt Speicherfrage. Je früher sie entschieden ist, desto weniger Folgearbeit an Speicherformat und Tests.
2. N-06 (Schutz-, Rettungs-, Wolfskind- und Lehrling-Korrekturen) benutzt vorhandene Kernbefehle und betrifft die Sicherheit der Spielleitung bei Fehlern am Tisch.
3. B-01 ist die Voraussetzung für jeden weiteren Rollenbedienweg: Der Coverage-Test ist die Grundlage von Paket 3. Ein intermittierend roter Test entwertet die Suite.
4. Pakete 3 bis 5 bauen auf den Bedienwegen auf. Paket 7 und 8 sind unabhängig und warten auf Entscheidungen.

Voraussetzungen vor Beginn: Schema-Frage (13 auf 14 oder App-Zustand) beantworten; bewusste Aktion des Rollenzeigens ohne Halten als technische Ableitung.

Weitere Bedingungen: siehe Paket 2 oben und Matrix S-08, N-06, Q-04.

## Arbeitsreihenfolge ohne Kalender

| Reihenfolge | Ziel |
|---|---|
| 1 | Aktuellen Stand und vollständige Restmatrix feststellen |
| 2 bis 5 | Bestehende Spielfunktionen, Tests, Sicherheit und Inhalte abschließen |
| 6 | Ersten Offline-Funktionsstand prüfen und sichern |
| 7 | Übrige vereinbarte Offline-Funktionen ergänzen |
| 8 | Kartenregeln entscheiden, Karten und Kartenschlucker abschließen |
| 9 | Clients und öffentliche Anzeige vervollständigen |
| 10 | Mediensteuerung und Plattformbasis fertigstellen |
| 11 | Vereinbarten Gesamtumfang prüfen und an Gestaltung übergeben |

Blockierte Pakete nicht künstlich als fertig markieren. Unabhängige Arbeit fortsetzen und den nächsten Auftrag aus dem tatsächlichen Abschlussbericht ableiten. Nicht alle Pakete ungeprüft als einzelnen Dauerauftrag starten.

## Danach

Eigenständiger Gestaltungsauftrag: Spielfeld mit 85 bis 90 Prozent Standardfläche, lesbare Personenplätze bis 24 Personen, kompakte Steuerung und sichere Informationskarten. Anschließend gezielte Animationen, Atmosphäre, Sound und echtes Tablet-Feedback. Regeländerungen nur bei gefundenen Fehlern oder ausdrücklichen neuen Produktentscheidungen.

## Rückmeldung je Claude-Auftrag

1. Branch, Worktree, Start- und End-HEAD, Push-/PR-Status.
2. Abgeschlossene Anforderungen mit Code- und Testbelegen.
3. Neue Fehler, Ursache und Regressionstest.
4. Selbst entschiedene Randfälle mit Begründung; echte Nutzerantworten getrennt.
5. Ausgeführte Prüfungen mit Zahlen und Exit-Codes; nicht ausgeführte Prüfungen ausdrücklich nennen.
6. Aktualisierte Abschlussmatrix und verbleibende Blocker.
7. Nächstes klar begrenztes Paket. Keine Aussage „fertig“, wenn nur Kern oder Kartendaten getestet sind.
