# Grimmhain: Abschluss der Spielfunktionen

> Für Claude Code: Dies ist ein Abschlussplan, kein Auftrag, alle Pakete sofort zu implementieren. Nach Umfangsentscheidung in einer Sitzung mit `superpowers:executing-plans` paketweise ausführen. Keine parallelen Sitzungen im selben Worktree.

**Ziel:** Eine vollständig bedienbare, reproduzierbar getestete Offline-Partie mit dem vereinbarten Rollenbestand. Danach beginnt die Überarbeitung von Darstellung und Bedienkomfort.

**Architektur:** Bestehenden GDScript-Regelkern, GameSession, Projektionen und SaveService beibehalten. Funktionale Bedienung nutzt dieselben Befehle wie der Kern. Keine zweite Regelimplementierung in der Oberfläche.

**Technik:** Godot 4.7.2, typisiertes GDScript, versioniertes JSON, DE/EN, bestehende Headless-Suite und CI.

**Quellen:** `GRIMMHAIN-REVOLUTION-MASTERPLAN.md`, `docs/masterplan/DECISION-LOG.md`, `docs/ui/cockpit.md`, `docs/ui/save-resume.md`, `docs/content-drafts/INTEGRATION-STATUS.md` im Worktree `grimmhain-night-ui`.

## Verifizierter Ausgangspunkt

- Am 29.09.2026 lokal geprüft: Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-night-ui`, Branch `feature/night-ui-expansion`, HEAD `23c7044`, sauber.
- PR #3 ist laut letztem Bericht noch nicht gemergt. Beim Arbeitsbeginn aktuellen GitHub-Stand erneut feststellen.
- Gemeldete Vollprüfung: 917 Tests grün. Für diesen Plan nicht erneut ausgeführt.
- 71 Rollen implementiert; Kartenschlucker wartet auf Totenkartenregeln.
- Setup, Sitzordnung, Start, Nacht, Morgen, Tag, Hinrichtung, Sieg, Speichern und Undo sind bereits vorhanden. Bestehendes Verhalten überprüfen, nicht neu bauen.
- Schema 13 und Regelversion 0.12. Ältere Saves werden erkannt und erhalten, nicht automatisch migriert.
- Rollen-zeigen-Modus und bestimmte Spezialkorrekturen sind funktionale Lücken.
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

- [ ] Aktuellen HEAD, Arbeitsverzeichnis, PR und Herkunft der Rollenfassung feststellen. Fremde Änderungen nicht überschreiben.
- [ ] Für jeden im Umfang enthaltenen Bedienweg den vorhandenen Code und Testbeleg zuordnen.
- [ ] Alle 71 Rollen auflisten: Normalablauf, Ziele, Verbrauch, Tages-/Nachtaktion, Reaktion, Siegbezug, private Information, Reload und Undo. Nicht anwendbare Fälle mit Begründung markieren.
- [ ] Veraltete Masterplan-Angaben vom aktuellen Stand unterscheiden. Historische Fortschrittsberichte nicht umschreiben.
- [ ] Offene Anforderungen aus dem Masterplan ausdrücklich als Abschlussumfang, späteres QoL oder separates System zuordnen. Keine Anforderung still streichen.
- [ ] Einmal die Ausgangsprüfungen laufen lassen; rote Befunde vor weiterem Ausbau untersuchen.

**Abnahme:** Jede im Umfang enthaltene Anforderung hat einen Beleg oder ein nachfolgendes Paket. Unbekannte Lücken sind nicht grün.

## Paket 2: Alle bestehenden Befehle tatsächlich bedienbar machen

**Betroffene vorhandene Dateien:** `godot/app/session/game_session.gd`, `godot/app/session/prompt_view.gd`, `godot/app/screens/cockpit/cockpit_screen.gd`, `action_card.gd`, `cockpit_layers.gd`, `godot/content/i18n/ui.de.po`, `ui.en.po`.

- [ ] Rollen-zeigen-Modus ergänzen: Person gezielt auswählen, nur zulässige Informationen zeigen, bewusst schließen, private Ansicht wiederherstellen. Bestehende `ConfirmRoleShown`-Regel und Trugbilderwolf-Ausnahme vor Implementierung lesen.
- [ ] Spezialkorrekturen für Schutz, Rettung, Wolfskind und Lehrling über bestehende Kernbefehle erreichbar machen. Gründe, Warnung und Protokoll verwenden.
- [ ] Prüfen, welche weiteren Korrekturen der Kern kennt, aber die Oberfläche nicht anbietet. Nur vom bestehenden Produktumfang gedeckte Lücken schließen.
- [ ] Abbrechen, ungültiges Ziel, veraltete Auswahl, Undo und Reload für jeden neuen Bedienweg gezielt prüfen.
- [ ] Tagesaktionen, Todesreaktionen, Siegbestätigung und private Hinweise auf vollständige Bedienbarkeit prüfen.

**Abnahme:** Kein vereinbarter Spielablauf braucht Konsole, direkte Zustandsmanipulation oder Entwicklerwissen. Ungültige Eingaben ändern Zustand und Ereignisverlauf nicht.

## Paket 3: Rollen- und Interaktionsprüfung bis zur Bedienung

**Tests:** Bestehende `godot/tests/unit/test_role_interactions.gd`, `test_role_interaction_fuzz.gd`, `godot/tests/ui/test_target_selection.gd`, `test_notice_cards.gd` und passende rollenbezogene Tests erweitern, statt parallele Testsysteme einzuführen.

- [ ] Pro Rolle mindestens einen repräsentativen Ablauf durch echte UI-Handler/Buttons headless ausführen und das erwartete Ergebnis prüfen. Ein akzeptierter Befehl allein reicht nicht.
- [ ] Gemeinsame Bedienarten parametrisiert prüfen: Einzelziel, Mehrfachziel, Ja/Nein, Rollenwahl, Zahlenwahl, Ablehnung, verpflichtende Auswahl und erlaubtes Überspringen.
- [ ] Für jede Mechanikfamilie konkurrierende Effekte prüfen: Schutz gegen passende Todesursache, Umlenkung gegen Immunität, Ketten gegen Wiederbelebung, Rollenwechsel gegen Ressourcen, Bindungen gegen Tod, Solo-Sieg gegen Fraktionssieg.
- [ ] Jede bekannte seltene Interaktion mit einem festen Szenario absichern. Fuzztests ergänzen diese Szenarien, ersetzen sie nicht.
- [ ] Nicht wahllos 71 × 71 Paare erstellen. Zuerst mechanisch relevante Überschneidungen aus der Matrix ableiten; jedes ausgelassene Risiko begründen.
- [ ] Tatsächliche Fehler testgetrieben beheben. Keine Tests abschwächen, bis Grün erreicht ist.

**Abnahme:** Die Matrix hat für alle 71 Rollen und relevanten Interaktionsklassen nachvollziehbare Belege. Das bedeutet geprüfte Korrektheit, keine mathematische Bugfreiheitsgarantie.

## Paket 4: Wiederaufnahme, Geheimhaltung und Betriebsfehler

**Dateien:** `godot/app/session/save_service.gd`, `game_session.gd`, `cockpit_view.gd`, `morning_report.gd`; bestehende Tests `test_save_service`, `test_save_versions`, `test_corrupt_save`, `test_notices`.

- [ ] Neustart bei offenem Prompt, offener Todesreaktion, privatem Hinweis, Morgenbericht und Siegkandidat prüfen.
- [ ] Gespeicherte Partie vor und nach Rollenwechsel, Wiederbelebung und Kettentod laden; Zustand, Ereignisse und zulässige nächste Aktion vergleichen.
- [ ] Unterbrochenes Schreiben, fehlende Schreibrechte, defekte Hauptdatei und defektes Backup mit isolierten Testdaten simulieren.
- [ ] Verhalten alter Schemaversionen beibehalten: verständliche Sperre, Datei erhalten. Migration ist kein stiller Zusatzauftrag.
- [ ] Undo/Redo nach jeder neu ergänzten Bedienung prüfen. Redo nach Neustart bleibt nur dann Aufgabe, wenn die Abschlussmatrix es ausdrücklich verlangt.
- [ ] Für öffentliche und personenbezogene Karten Positivlisten prüfen. Keine fremde Rolle, Scheinrolle, geheime Ursache, Schutzmarkierung oder andere private Hinweise durchreichen.
- [ ] Öffentliche Todesreaktionen als erlaubte Ausnahme testen. Geheimhaltungstests dürfen diese Ausnahme nicht fälschlich verbieten.

**Abnahme:** Keine bekannte Datenverlustlücke, doppelte Aktion oder unerlaubte Informationsweitergabe. Fehler führen zu einem verständlichen und fortsetzbaren Zustand.

## Paket 5: Inhalte und Medienanschlüsse

**Quellen:** `docs/content-drafts/rolebook/`, `GUIDE-TEXTS.md`, `OPEN-ISSUES.md`, `INTEGRATION-STATUS.md`, DE-/EN-Übersetzungen und `godot/app/settings/app_settings.gd`.

- [ ] Rollenlexikon gegen aktuellen Kern und Decision Log abgleichen. Veraltete Aussagen nicht blind übernehmen.
- [ ] Für alle 71 Rollen eindeutige Fähigkeit, Ziele, Grenzen, Zeitpunkt und Spielleiteranweisung im Programm erreichbar machen.
- [ ] Fehlende DE-/EN-Schlüssel, Platzhalter und dynamische Rollennamen automatisch prüfen. Bedeutungsgleichheit zusätzlich gezielt redaktionell prüfen.
- [ ] Vorlesetext, öffentliche Ansage und private Spielerinformation konsequent getrennt halten.
- [ ] Vorhandene Einstellungen auf wirksame Funktionen prüfen. Ein Schalter ohne Wirkung zählt nicht als abgeschlossen.
- [ ] Medienanschlüsse nur so weit ergänzen, wie das bestätigte Produkt sie bereits benötigt: Ereignisse für Sound/Animation, stummes Verhalten bei fehlenden Medien, Abbruch ohne Einfluss auf Spielregeln. Keine große generische Effekt-Engine vorsorglich bauen.
- [ ] DI-09 exakt einmal auslösbar und ohne Datei gefahrlos prüfbar machen, sofern Audio-Technik zum gewählten Abschlussumfang gehört. Finale Tondatei bleibt Medienproduktion.

**Abnahme:** Die Partie ist ohne zusätzliche Grafik-, Audio- oder Videodateien vollständig leitbar. Fehlende Medien blockieren keinen Befehl und geben keine unbeabsichtigten Geheimnisse preis.

## Paket 6: Technikabschluss und Übergabe an die Gestaltung

**CI:** `.github/workflows/godot-core-tests.yml`, `asset-register.yml`, vorhandene Dokument-/Inhaltsprüfer.

- [ ] Einen unabhängigen zweiten Prüfdurchgang des Diffs durchführen, ohne gleichzeitig am selben Worktree zu arbeiten.
- [ ] Verbindliche Regel-/Dokument-/Übersetzungsprüfer in CI aufnehmen, soweit bislang nur lokal ausgeführt. Keine redundante zweite CI-Suite.
- [ ] Vollständige Headless-Suite, Register, Rollenprüfung, Inhaltsprüfung und `git diff --check` ausführen; Exit-Codes und Laufzeitfehler kontrollieren.
- [ ] Windows-Export und Exportvoraussetzungen für iPadOS/Android inventarisieren. Fehlende SDKs, Signierung und Mac-Gerätetests ausdrücklich als Plattformblocker ausweisen. Ein Headless-Lauf ersetzt keinen Tablet-Test.
- [ ] Kurzen manuellen Funktionstest vorbereiten: Setup, eine Nacht, private Karte, Morgen, Nominierung/Hinrichtung, Speicher-Wiederaufnahme, Undo und Sieg. Nur Nutzer startet Fenster, wenn der Bot pausiert ist.
- [ ] Nicht visuell prüfen können als offene Abnahme kennzeichnen, nicht als fertigen Tablet-Release verkaufen.
- [ ] PR #3 und Folgeänderungen nachvollziehbar integrieren. Ohne neuen Mergeauftrag PRs offen lassen; keine automatische Umgehung der bestehenden Abnahme.
- [ ] Abschlussbericht mit festem HEAD, Testbefunden, bekannten Grenzen und getrennten Listen für Spielfunktionsfehler, Gestaltung/QoL und spätere Systeme erstellen.

**Abnahme:** Null bekannte blockierende Fehler im vereinbarten Offline-Funktionsumfang, alle verpflichtenden automatischen Prüfungen grün, keine unzugeordneten Anforderungen. Nicht bestandene Punkte werden offen ausgewiesen.

## Paket 7: Übrige vereinbarte Offline-Funktionen

- [ ] Gespeicherte Gruppen und deren Wiederverwendung ergänzen, sofern noch nicht vorhanden: Namen übernehmen, neue Personen-IDs je Partie, keine alte Rolle/Markierung übernehmen.
- [ ] Szenariobasierte Rollenwahl gegen gültige Rollen-IDs, Personenanzahl und bestätigte Kompositionsregeln validieren. Keine neuen Szenarioregeln erfinden.
- [ ] Geführten und Expertenmodus funktional vervollständigen. Beide benutzen denselben Kern, dieselben Schutzprüfungen und dieselben Speicherpunkte.
- [ ] Beispielrunde und Übungsmodus mit isolierten Spielständen ermöglichen. Eine Übungsrunde darf keine echte laufende Partie überschreiben.
- [ ] Chronik/Nachspielbericht aus vorhandenen Ereignissen erzeugen. Vor Spielende nur freigegebene Angaben exportieren; private Daten nur nach bewusster Wahl.
- [ ] Timer als Anwendungskomponente ohne Einfluss auf Regeln ergänzen, falls laut Matrix noch fehlend. Neustartverhalten und Pause definieren; Zeitablauf führt nie eigenständig eine Hinrichtung aus.

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

- [ ] Vorhandene Audio-Technik zuerst prüfen; danach Master/Musik/Ambiente/Cues/UI, wirksame Lautstärke/Stumm und persistente Einstellungen vervollständigen.
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
