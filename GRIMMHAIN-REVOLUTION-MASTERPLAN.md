# Grimmhain Revolution · Verbindlicher Masterplan

## Aktuelle Arbeitsreihenfolge: Spielfunktionen vor Gestaltung

**Planungsupdate vom 29.09.2026:** Die technische Umsetzung wird ohne feste Tages- oder Wochenfrist in überprüfbaren Arbeitspaketen abgeschlossen. Aktuelle operative Roadmap: [CODE-COMPLETION-ROADMAP.md](docs/masterplan/CODE-COMPLETION-ROADMAP.md). Diese Reihenfolge ersetzt Kalenderannahmen und frühere nächste Schritte für die weitere Planung; Produktumfang und Abnahmeanforderungen dieses Masterplans bleiben erhalten.

Der erste Meilenstein ist die vollständig bedienbare Offline-Partie. Danach folgen übrige Offline-Funktionen, Totenkarten/Kartenschlucker, lokale Clients und öffentliche Anzeige sowie Mediensteuerung und Plattformbasis. Blockierte Regelentscheidungen werden nicht als erledigt markiert. Finale Grafik, Atmosphäre und umfangreiche Layout-/QoL-Überarbeitung folgen als eigenes Gestaltungsprojekt; dessen Standardansicht soll 85 bis 90 Prozent Spielfeldfläche bieten.

**Stand auseinanderhalten:** Dieser Checkout steht auf main `8197ee6`. Der neuere Funktionsstand liegt im Worktree `grimmhain-night-ui`, Branch `feature/night-ui-expansion`, zuletzt lokal geprüft `23c7044`. Die dafür gemeldeten 917 Tests sind kein Nachweis für den älteren main und keine Tablet-Abnahme. Der nächste Auftrag prüft den aktuellen Stand und erstellt die vollständige Restmatrix, bevor weitere Funktionspakete umgesetzt werden.

**KONFLIKT (main/branch), Markus entscheidet:** Die beiden Absätze zum Repositorystand (main-Fassung oben, Branch-Fassung unten) beschreiben denselben Punkt zu verschiedenen Zeitpunkten und stimmen nach dem Merge nicht mehr; beide bleiben stehen.

**Stand auseinanderhalten:** `main` steht auf `8197ee6` (nach PR #2). Der neuere Funktionsstand liegt im Branch `feature/night-ui-expansion` (PR #3, offen, zuletzt geprüft `23c7044`) und enthält `main`, den Rollenaudit und die Cloud-Integration vollständig. Die Abschlussmatrix [CODE-COMPLETION-MATRIX.md](docs/masterplan/CODE-COMPLETION-MATRIX.md) vom 29.09.2026 belegt den Ist-Stand je Anforderung. Die dort ausgeführte Vollsuite (917 Tests) war einmal rot (intermittierender Prüfungsfehler, Befund B-01) und einmal grün; das ist kein Nachweis für `main` und keine Tablet-Abnahme.

**Stand:** 26. September 2026; Umsetzungsstand aktualisiert 27. September 2026 (main `1bc8016`)

**Status:** Produktrichtung bestätigt; Analyse abgeschlossen. Umsetzung begonnen: Regelkern mit 11 Rollen (Phase 1) implementiert und automatisch getestet; Setup-Oberfläche für Spieler, Rollen, Verteilung und Sitzordnung (Teil von Phase 2) implementiert, automatisch getestet und grafisch skriptgesteuert geprüft. Spielstart (`StartGame`) aus dem bestätigten Setup umgesetzt und automatisch getestet (PR #2). Keine Tablet-Abnahme, keine spielbare Partie (Nacht/Tag) über die Oberfläche.

**Stufen im Umsetzungsstand:** *implementiert* (Code vorhanden) · *automatisch getestet* (headless Godot-Suite, lokal und CI: 438 Tests grün) · *grafisch geprüft* (lokal mit echtem Renderer, skriptgesteuert über echte Buttons, keine Handbedienung) · *Tablet-abgenommen* (von Hand auf dem Zielgerät; bisher für keinen Punkt erfolgt). Ein Haken bedeutet: Punkt im Wortlaut erfüllt.

**Primärziel:** Hochwertige, offlinefähige Spielleiter-App für physische Social-Deduction-Runden auf Tablets

**Technik:** Godot 4.x, GDScript, lokale Webclients für Smartphones und öffentliche Anzeige
**Planungsgrundlagen:** `docs/godot-migration/01` bis `07`, `GRIMMHAIN-ANALYSE-UND-ROADMAP-2026-09-15.md`, bestätigte Entscheidungen in `docs/masterplan/DECISION-LOG.md`

> Dieser Plan ist die verbindliche Arbeitsreihenfolge. Keine Phase wird übersprungen. Jede Checkbox wird erst nach nachgewiesener Abnahme markiert.

## 1. Produktversprechen

Grimmhain hilft dem Spielleiter, eine physische Runde sicher, schnell und atmosphärisch zu führen. Das Tablet kennt den vollständigen Zustand, zeigt genau den nächsten notwendigen Schritt und verhindert versehentliche Geheimnisoffenlegung. Diskussion und Abstimmung bleiben am Tisch. Smartphones und ein öffentlicher Bildschirm ergänzen die Runde, sind aber keine Voraussetzung für den Spielbetrieb.

### Erfolgskriterien für Version 1.0

- [ ] Eine Partie mit 6 bis 24 Personen lässt sich vollständig offline leiten.
- [ ] 20 bis 30 geprüfte Rollen besitzen eindeutige DE-/EN-Texte, Tests und dokumentierte Randfälle.
- [ ] Kein bestätigter Fehler kann Spielstand verlieren, geheime Informationen offenlegen oder ein falsches spielentscheidendes Ergebnis erzeugen.
- [ ] Nach App-Absturz, leerem Akku oder Netzwerkausfall lässt sich die Runde am letzten bestätigten Schritt fortsetzen.
- [ ] Alle Aktionen sind protokolliert und kontrolliert rückgängig beziehungsweise wiederholbar.
- [ ] Der Spielleiter kann jede automatische Entscheidung mit Warnung und Protokolleintrag überschreiben.
- [ ] iPadOS, Android-Tablets ab der später gemessenen Mindestklasse und Windows sind getestet.
- [ ] Öffentliche Anzeige und Smartphoneclients erhalten technisch nur freigegebene Daten.
- [ ] Schrift, Bild, Musik, Sprache und Effekte besitzen dokumentierte kommerzielle Nutzungsrechte.
- [ ] Mindestens fünf externe Spielleiter haben zusammen mindestens zehn vollständige Runden durchgeführt; mindestens vier wollen Grimmhain erneut einsetzen.

## 2. Harte Produktgrenzen

### Version 1.0 enthält

- Tablet-Cockpit im Querformat, 6 bis 24 Personen, fester Sitzkreis und Drag-and-drop.
- Geführten Modus und Expertenmodus.
- Setup mit automatischer, manueller und szenariobasierter Rollenvergabe.
- Drei Fraktionsarten: Dorf, Werwölfe und Einzelsiegrollen.
- Physische Nominierung und Abstimmung; digital gespeichert werden Nominierende, Nominierte und die bestätigte Todesart.
- Tag-/Nachtfluss, Ereigniswarteschlange, Schutz, Tod, Rollenwechsel, Wiederbelebung und Siegprüfung.
- Versionierte Spielstände, automatische Checkpoints, Undo/Redo und Ereignisprotokoll.
- Persönliche Smartphoneansicht per QR-Code für Rolle, Nachtaktion und Rollenlexikon.
- Gefilterte öffentliche Browseransicht für Smart-TV oder zweiten Rechner.
- Deutsch und Englisch sowie vorbereitete Übersetzungsstruktur.
- Regelbuch, kontextbezogene Hilfe, Beispielrunde und Übungsmodus.
- 2.5D-Präsentation mit Tag/Nacht, Licht, Nebel, adaptivem Audio und kurzen Ereigniseffekten.

### Version 1.0 enthält nicht

- Vollständiges Online-Remote-Spiel, Matchmaking, Benutzerkonten oder Sprachchat.
- Verpflichtende Smartphone-Nutzung.
- Digitale Stimmabgabe oder digitale Stimmzählung.
- Vollständigen visuellen Rollen-/Szenarioeditor.
- Steam Workshop oder offenen Community-Marktplatz.
- Weiterentwicklung der Legacy-Web-App über kritische Fehlerbehebungen hinaus.

## 3. Nachgewiesener Ausgangszustand

Die Cloud-Analyse vom 26. September hat den Legacy-Code vollständig inventarisiert.

| Befund | Konsequenz |
|---|---|
| 72 Rollen: 41 entsprechend Text, 19 widersprüchlich, 9 nicht umgesetzt, 3 unklar | Kein automatisches Portieren; jede 1.0-Rolle benötigt eine Regelentscheidung und Tests. |
| Zwei widersprüchliche Siegprüfungen und sechs Solorollen ohne Siegcode | Eine einzige neue Sieg-Pipeline; unbekannte Solo-Siege werden vor Aufnahme entschieden. |
| Schutzgeist, Seelentauscher und Lehrling enthalten bestätigte Fehler | Legacy-Verhalten ist keine automatische Wahrheit. |
| 20 direkte `Math.random`-Aufrufe | Gespeicherter Seed und deterministischer Zufallsdienst ab dem ersten Core-Slice. |
| 5-Schritt-Undo ist wirkungslos, faktisch existiert nur ein RAM-Snapshot | Ereignisbasierte Befehle, persistente Checkpoints und echtes Undo/Redo werden früh gebaut. |
| 80 Totenkarten besitzen keine automatisierten Effekte | Zunächst geführter Assistent; Automatisierung erst nach Pilotdaten. |
| Tagphase kennt keine Abstimmung oder Gleichstandsregel | Entspricht der bestätigten physischen Abstimmung; digitale Stimmen werden nicht ergänzt. |
| React umschließt eine globale Legacy-Engine über verstecktes DOM | Keine Code-Migration dieser Kopplung; nur Regeln und nachgewiesenes Verhalten dienen als Referenz. |
| Nachtmusik ohne Herkunft, fehlende Schrift-Lizenzdateien, KI-Metadaten in Bildern | Ungeklärte Assets bleiben Platzhalter und dürfen nicht in Release-Builds. |
| Bestehende Smoke-/i18n-Checks prüfen nur Textvorkommen und Schlüssel | Neue Tests müssen Verhalten, Replay, Save/Load, Geheimhaltung und Gerätefluss prüfen. |

## 4. Zielarchitektur

```text
Godot Tablet/PC
├── Domain Core (ohne Szenen und UI)
│   ├── GameState + versioniertes Schema
│   ├── Commands → Validation → Events
│   ├── PhaseMachine + PromptQueue
│   ├── KillPipeline + EffectResolver
│   ├── WinResolver
│   ├── SeededRng
│   └── Save/Replay/Undo
├── Application Layer
│   ├── SessionController
│   ├── PublicProjectionBuilder
│   ├── PlayerProjectionBuilder
│   └── LocalNetworkGateway
├── Tablet UI
│   ├── Setup
│   ├── GameMasterCockpit
│   ├── SecurePresentationCard
│   ├── Log/Undo/Correction
│   └── Accessibility/Settings
├── Presentation
│   ├── 2.5D Village
│   ├── Day/Night/Weather/VFX
│   └── Music/Ambience/Voice/Cues
└── Local Web Clients
    ├── Player Client
    └── Public Display
```

### Unverhandelbare Architekturregeln

1. Domain-Core lädt keine Szene, spielt kein Audio und greift nicht auf Netzwerk oder Dateisystem zu.
2. Ausschließlich bestätigte Commands verändern den Zustand; daraus entstehen unveränderliche Events.
3. Mehrstufige Aktionen liegen als persistente offene Prompts im Spielstand.
4. Zufall läuft ausschließlich über `SeededRng`; Seed und Ziehposition werden gespeichert.
5. Personen-ID, Sitzposition, Rolle, Fraktion und öffentliche Erscheinung sind getrennte Werte.
6. Geheime Projektionen werden serverseitig erzeugt. Clients bekommen niemals den Gesamtzustand.
7. Save/Load, Replay und Undo benutzen dieselben Commands und Events.
8. Inhalte verwenden stabile technische IDs; Anzeigenamen sind lokalisierte Texte.
9. Jede Rolle deklariert Automationsstatus, Regelnachweis, Nachtpriorität und Tests.
10. Legacy-Code wird gelesen, aber nicht in den neuen Kern eingebettet.

## 5. Entwicklungsphasen

## Phase 0 · Entscheidungen und reproduzierbare Arbeitsbasis

**Ziel:** Die offenen Regeln der ersten Rollencharge und die Werkzeugkette festziehen.

- [ ] Cloud-Analyse auf `main` übernehmen und als unveränderliche Baseline markieren.
- [x] Godot-Version anhand stabiler 4.x-Version und Exportunterstützung festlegen; Version in `godot/README.md` und CI pinnen. *(Stand 27.09.2026: 4.7.2-stable in `godot/tools/godot-version.txt`, README und CI.)*
- [ ] Entwicklungswerkzeuge inventarisieren: Godot, Git, Android SDK/JDK, Xcode auf MacBook, Browser-Testgeräte.
- [ ] iPad-Modell, Betriebssystemstände und späteres Android-Referenzgerät im Testregister erfassen.
- [ ] `07-open-questions.md` mit dem bestätigten Decision Log abgleichen.
- [ ] 20 bis 30 Kandidaten für 1.0 auswählen; erste 8 bis 12 für den Vertical Slice markieren. *(Stand 27.09.2026: 11 Vertical-Slice-Rollen implementiert; Auswahl für 1.0 nicht freigegeben, Optionen in `docs/role-migration/05-v1-role-options.md`.)*
- [ ] Für diese Rollen jede widersprüchliche Zeile der Migrationsmatrix entscheiden.
- [x] Nachtmusik bis zum Herkunftsnachweis sperren. *(Stand 27.09.2026: Status `gesperrt` im Assetregister.)*
- [x] `ASSET-REGISTER.md` für alle künftig verwendeten Assets verpflichtend machen. *(Stand 27.09.2026: `tools/check-asset-register.js` und CI „Asset register“ bei jedem Push.)*
- [ ] Branch `phase/00-foundation` anlegen.

**Gate:** Keine offene Regelentscheidung blockiert den Vertical Slice. Toolchain kann ein leeres Godot-Projekt headless starten und für mindestens eine vorhandene Plattform exportieren.

## Phase 1 · Deterministischer Regelkern

**Ziel:** Eine UI-freie Partie Werwolf gegen Dorf ist reproduzierbar spielbar.

- [x] Projekt unter `godot/` anlegen; statisch typisiertes GDScript verwenden.
- [ ] `GameState`, `Player`, `SeatOrder`, `RoleAssignment`, `Faction`, `Effect`, `Prompt` und `GameEvent` definieren. *(Stand 27.09.2026: `GameState`, `Player`, `Faction`, `PendingPrompt`, `GameEvent` implementiert; eigene `SeatOrder`-, `RoleAssignment`- und `Effect`-Typen fehlen.)*
- [x] Command-Bus für `StartGame`, `StartNight`, `SubmitAction`, `ResolveMorning`, `Nominate`, `ExecutePlayer`, `StartNight` und `DeclareWinner` bauen. *(Stand 27.09.2026: implementiert und automatisch getestet als `StartGame`, `StartNight`, `AnswerPrompt`, `EndNight`, `Nominate`, `DecideExecution`, `ConfirmWin`/`RejectWin`; die Oberfläche sendet `StartGame` über „Partie starten“ (PR #2), weitere Befehle noch nicht.)*
- [x] Phasenmaschine für Setup, Nacht, Morgenbericht, Tag und Spielende implementieren. *(Stand 27.09.2026: `phase_machine.gd`, über Szenario- und Schrittests automatisch getestet.)*
- [x] Gespeicherten Seed und `SeededRng` implementieren. *(Stand 27.09.2026: automatisch getestet, `test_seeded_rng.gd`.)*
- [x] Grundlegende Kill-Pipeline mit Ursache, Quelle, Ziel, Zeitpunkt und Abfangstatus implementieren. *(Stand 27.09.2026: `kill_pipeline.gd`, `KillEvent`, automatisch getestet.)*
- [x] Eine einzige Siegprüfung für Dorf und Werwölfe implementieren; Ergebnis verlangt Spielleiterbestätigung. *(Stand 27.09.2026: `win_rules.gd`, Szenarien `as-c01` bis `as-c04`.)*
- [ ] JSON-Codec mit `schema_version`, `rules_version`, atomischem Schreiben und vorherigem Backup implementieren. *(Stand 27.09.2026: Codec mit `schema_version`/`rules_version` implementiert und getestet; atomisches Schreiben in eine Datei und Backup fehlen.)*
- [x] Headless-Test-Runner und Szenarioformat erstellen.
- [x] Tests für Wolfsparität, Tod des letzten Wolfs, identischen Replay, Save/Load-Hash und beschädigten Spielstand schreiben.

**Gate:** Dieselbe Command-Liste mit gleichem Seed erzeugt bytegleich dieselbe Eventliste. Save/Load verändert den fachlichen Hash nicht.

## Phase 2 · Vertical Slice auf dem Tablet

**Ziel:** Setup → erste Nacht → Morgen → Tag → Nominierung → Hinrichtung → neue Nacht funktioniert auf einem echten iPad.

- [ ] Start-, Setup- und Wiederaufnahmescreen bauen. *(Stand 27.09.2026: Start und Setup (Spieler, Rollen, Verteilung, Sitzordnung) implementiert, automatisch getestet, grafisch geprüft; Wiederaufnahme fehlt; nicht Tablet-abgenommen.)*
- [ ] Namen einzeln erfassen, gespeicherte Gruppe anbieten und 6 bis 24 Personen validieren. *(Stand 27.09.2026: Einzelerfassung, Textimport und 6-bis-24-Prüfung implementiert, automatisch getestet, grafisch geprüft; gespeicherte Gruppe fehlt; nicht Tablet-abgenommen.)*
- [x] Sitzkreis mit stabiler Personen-ID und Drag-and-drop der Sitzreihenfolge bauen. *(Stand 27.09.2026: Setup-Schritt Sitzordnung implementiert, automatisch getestet, grafisch geprüft; Drag-and-drop nur mit Maus bzw. simulierten Mausereignissen, nicht Tablet-abgenommen; siehe `docs/ui/seating-setup.md`.)*
- [ ] Cockpit mit Phase, Runde, Timer, nächstem Schritt, Warnungen, Log und Undo bauen.
- [ ] Sichere Ansagekarte mit privaten, vorlesbaren und zeigbaren Bereichen bauen.
- [ ] Tag- und Nacht-Theme mit vorläufigen, lizenzklaren Assets erstellen.
- [ ] Rollencharge mit Schutz, Information, Angriff, Nominierungsreaktion, Todeseffekt und Fehlinformation implementieren. *(Stand 27.09.2026: 11 Rollen im Regelkern implementiert und automatisch getestet; in der Oberfläche nur Rollenwahl und Verteilung, keine Nacht- oder Tagführung.)*
- [ ] Nominierung `Quelle → Ziel` und getrennte Buttons für Lynch, Nachtangriff und andere Todesursachen bauen.
- [ ] Checkpoint nach jeder bestätigten Aktion und Wiederaufnahme nach Prozessabbruch testen.
- [ ] Reduced-Motion-, Untertitel- und Lautstärkeregelung von Anfang an verdrahten.

**Gate:** Eine vollständige repräsentative Runde läuft auf dem iPad ohne Entwicklerkonsole. Kein Effekt blockiert eine Eingabe; kein Abbruch verliert einen bestätigten Schritt.

## Phase 3 · Regelkorrektheit, Undo und Spielleitersicherheit

**Ziel:** Komplexe Effekte können nicht zu halben oder unsichtbaren Zuständen führen.

- [ ] Effektprioritäten und persistente Reaktionswarteschlange implementieren.
- [ ] Schutz, Umlenkung, Immunität, verzögerter Tod, Kettentod, Rollenwechsel und Wiederbelebung zentralisieren.
- [ ] Mehrstufige Prompts abbrechbar machen; Abbruch muss den vorherigen Hash wiederherstellen.
- [ ] Undo/Redo als Command-Gruppen mit Klartextbeschreibung implementieren. *(Stand 29.09.2026: Wiederholen entfällt beim Neustart, Decision Log PE-03; Rückgängig über einen Neustart bleibt.)*
- [ ] Manuelle Spielleiterkorrektur durch dieselbe Pipeline führen.
- [ ] ~~Automatische Rotation von Checkpoints~~ und Reparaturdialog für beschädigte Saves bauen. *(Ersetzt durch Decision Log PE-02, 29.09.2026: eine Sicherung `.bak` je Partie reicht für den Offline-Abschluss, mehrere Stände frühestens als spätere Komfortfunktion. Beschädigte Dateien fallen heute automatisch mit Hinweis auf die Sicherung zurück, `docs/ui/save-resume.md`.)*
- [ ] Ereignisprotokoll persistent machen und als lesbare Rundenchronik projizieren.
- [ ] Golden Tests nur für verifiziertes Legacy-Verhalten erstellen; bekannte Bugs ausdrücklich als korrigierte Abweichung testen.
- [ ] Regel-Linter für fehlende IDs, Texte, Nachtprioritäten und Tests einführen.

**Gate:** Undo aller Commands führt zum Ausgangszustand; Redo reproduziert denselben Endzustand. Jede mehrstufige Aktion überlebt Neustart oder lässt sich ohne Teilwirkung abbrechen. *(Redo gilt innerhalb einer laufenden Sitzung; über einen Neustart wird es nicht verlangt, Decision Log PE-03.)*

## Phase 4 · Tablet-MVP und geführte Spielleitung

**Ziel:** Eine echte Gruppe kann ohne Entwicklerhilfe eine vollständige Runde spielen.

- [ ] 17 bis 20 priorisierte Rollen vollständig automatisieren; weitere Inhalte nur klar als manuell geführt anbieten.
- [ ] Automatische, manuelle und szenariobasierte Rollenwahl implementieren. *(Stand 27.09.2026: Vorschlag, manuelle Rollenwahl sowie zufällige und manuelle Verteilung implementiert, automatisch getestet, grafisch geprüft; szenariobasierte Wahl fehlt. Stand 30.09.2026, PE-07: In der Startbesetzung kommt jede Rolle höchstens einmal vor, Die Gebundenen (1 bis Personenzahl) sind die einzige Ausnahme; der automatische Vorschlag ist eine feste Liste je Personenzahl von 6 bis 24 (Wolfsrollen 1/2/3/4/5 ab 6/9/13/18/22 Personen, genau ein Manipulator, Dorfrollen in fester Reihenfolge, Regelversion 0.14). Gleiche Rollen, die erst im Spiel durch Verwandlung, Erbe, Tausch, Diebstahl oder Korrektur entstehen, sind nicht neu geregelt. Details: `docs/masterplan/DECISION-LOG.md`, Abschnitt „PE-07-Umsetzung (30.09.2026)“.)*
- [ ] Geführten Modus mit nächster Aktion, Regelgrund und Vorlesetext fertigstellen.
- [ ] Expertenmodus mit kompaktem Ablauf und direkter Korrektur fertigstellen.
- [ ] Rollenanzeige ohne Smartphone als sichere Tablet-Karte ermöglichen.
- [ ] Morgenbericht in privaten und öffentlichen Teil trennen.
- [ ] Totenkarten zunächst als geführten Assistenten behandeln; Ziehung und Zufall reproduzierbar machen.
- [ ] Regelbuch, Rollenlexikon, Beispielrunde und Übungsmodus erstellen.
- [ ] Drei interne vollständige Runden im Flugmodus durchführen und Probleme protokollieren.

**Gate:** Drei vollständige Runden ohne Spielstandsverlust, geheime Offenlegung oder falsche automatische Entscheidung. Der Spielleiter bevorzugt den Godot-MVP gegenüber der Web-App.

## Phase 5 · Lokale Clients und Geheimhaltung

**Ziel:** Smartphones und öffentliche Anzeige ergänzen die Runde ohne Internet und ohne Geheimnisleck.

- [ ] Lokalen HTTP-/WebSocket-Dienst mit Sitzungs- und Geräteauthentifizierung bauen.
- [ ] Spielerbeitritt per Sitzungs-QR-Code und individuellem Einmalcode implementieren.
- [ ] Gerätezuordnung durch den Spielleiter bestätigen, sperren, übertragen und erneuern können.
- [ ] Spielerprojektion auf eigene Rolle, erlaubte Nachtaktion und Lexikon begrenzen.
- [ ] Tagsüber neutrale Dorfbewohneransicht; Rolle nur nach bewusster Aktion sichtbar.
- [ ] Sichere Re-Synchronisierung ohne Ausführung veralteter Offline-Aktionen implementieren.
- [ ] Öffentliche Projektion für Sitzkreis, Lebend/Tot, Phase, Timer, öffentliche Rollen, Ansagen und Ereignisse bauen.
- [ ] Negativtests erstellen, die in Netzwerkantworten nach fremden Rollen, Zielen und Effekten suchen.
- [ ] Hotspot-/WLAN-Hilfe und vollständigen Tablet-Fallback dokumentieren.

**Gate:** Manipulierte Clientanfragen verändern keinen unerlaubten Zustand. Öffentlicher Client erhält in automatisierten Tests keinerlei geheime Felder.

## Phase 6 · Visuelle und akustische Qualität

**Ziel:** Grimmhain wirkt lebendig, ohne die Spielleitung zu verlangsamen.

- [ ] Visuelle Bibel mit Farbwerten, Typografie, Rahmenregeln, Symbolsprache und Referenzscreens freigeben.
- [ ] 2.5D-Dorf in getrennten Ebenen für Himmel, Architektur, Vordergrund, Licht, Nebel und Partikel produzieren.
- [ ] Tages- und Nachtzustand sowie Übergänge implementieren.
- [ ] Cue-System für Nachtbeginn, Schutz, Angriff, Tod, Morgen, Nominierung, Hinrichtung und Spielende bauen.
- [ ] Adaptive Musik, Ambiente, Effekte und je eine DE-/EN-Erzählerstimme integrieren.
- [ ] Jeder Cue bekommt Priorität, Maximallänge, Skip-Regel, Reduced-Motion-Alternative und Audio-Fallback.
- [ ] Qualitätsstufen für schwächere Geräte implementieren.
- [ ] Finale Porträts, Icons und zentralen Audioinhalt gegen Assetregister prüfen.
- [ ] Verständlichkeits- und Atmosphärentests mit Effekten an/aus durchführen.

**Gate:** Stabile Ziel-Framerate auf Referenzgeräten; UI reagiert innerhalb von 100 ms; Effekte verraten keine geheimen Ziele und sind jederzeit überspringbar.

## Phase 7 · Inhalt auf Version-1.0-Umfang

**Ziel:** 20 bis 30 Rollen und die vorgesehenen Szenarien sind vollständig geprüft.

- [ ] Rollen nach Mechanikfamilien in Chargen umsetzen: Information, Schutz/Umlenkung, Tod/Rollenwechsel, Solo-Siege.
- [ ] Pro Rolle Normalfall, ungültiges Ziel, konkurrierender Effekt, Reload, Undo und Siegbezug testen.
- [ ] DE-/EN-Texte redaktionell prüfen; keine Laufzeit-Substring-Übersetzung verwenden.
- [ ] Mindestens drei Szenarien mit eigener Rollenliste, Regeln, Kulisse, Audio und Ansagen erstellen.
- [ ] Totenkarten-Assistent in DE/EN fertigstellen; Automatisierung nur für nachweislich lohnende Karten ergänzen.
- [ ] Nachspielbericht mit Gewinnern, Rollen, Wendepunkten und exportierbarer Chronik bauen.

**Gate:** Jede enthaltene Rolle besitzt einen freigegebenen Regeltext, mindestens ein Szenario, vollständige Tests und einen klaren Automationsstatus.

## Phase 8 · Plattformhärtung und Pilot

**Ziel:** Das Produkt funktioniert auf realen Geräten und in fremden Händen.

- [ ] Builds für iPadOS, Android und Windows reproduzierbar erzeugen.
- [ ] Mindestanforderungen anhand gemessener Daten festlegen.
- [ ] Matrix aus iPad, iPhone 14/15 als Client, Windows-PC, MacBook, Smart-TV und mindestens einem schwächeren Android-Tablet testen.
- [ ] Installation, lokale Netzwerkberechtigung, Hintergrundwechsel, Sperrbildschirm, Rotation, wenig Speicher und Akkuverlust testen.
- [ ] Fünf externe Spielleiter onboarden und mindestens zehn Runden protokollieren.
- [ ] Fehler nach Schweregrad behandeln; spielentscheidende, Datenverlust- und Geheimnisfehler blockieren den Release.
- [ ] Early-Access-Entscheidung anhand Pilotdaten treffen.

**Gate:** Pilotkriterien und Release-Checkliste erfüllt oder Umfang bewusst reduziert.

## Phase 9 · Veröffentlichung

**Ziel:** Rechtlich, technisch und redaktionell belastbare Version 1.0.

- [ ] Marken- und Ähnlichkeitsprüfung durchführen.
- [ ] Lizenznachweise für jedes ausgelieferte Asset abschließen.
- [ ] Datenschutztext für lokale Namen/Fotos und optionale externe KI-Dienste erstellen.
- [ ] Storetexte, Screenshots, Trailer, Alterskennzeichnung und Supportweg vorbereiten.
- [ ] Preis anhand Tests und Marktvergleich festlegen.
- [ ] Android-Store, Apple App Store, direkter APK- und Windows-Download vorbereiten.
- [ ] Signierte Release-Artefakte, Checksummen und Rollback-Version archivieren.

## Phase 10 · Steam und spätere Online-Version

- [ ] Windows-Cockpit und öffentliche Zweitanzeige für einen PC optimieren.
- [ ] Steamworks hinter einer austauschbaren Plattform-Schnittstelle anbinden.
- [ ] Steam Cloud nur für Einstellungen, Gruppen und abgeschlossene Historien prüfen; aktive Partie bleibt lokal autoritativ.
- [ ] Workshop erst nach stabilem, validiertem Paketformat evaluieren.
- [ ] Remote-Spiel separat spezifizieren: Bedrohungsmodell, Konten, Relay, Moderation, Datenschutz, Betriebskosten und Sprachkommunikation.
- [ ] Online-Implementierung nur nach eigenem Stop/Go und nach bewiesenem lokalem Produkt beginnen.

## 6. Zeit- und Kapazitätsmodell

Die Cloud-Analyse schätzt 78 bis 128 Entwicklungstage plus Pilot für einen breiten Umfang. Bei 14 bis 30 Stunden pro Woche wird in überprüfbaren Slices geplant, ohne künstliches Veröffentlichungsdatum.

| Abschnitt | Grobe Spanne | Ergebnis |
|---|---:|---|
| Phase 0–1 | 2–4 Wochen | belastbarer Regelkern |
| Phase 2–3 | 4–7 Wochen | sicherer Vertical Slice |
| Phase 4 | 3–5 Wochen | spielbares Tablet-MVP |
| Phase 5–6 | 5–9 Wochen | Clients und Präsentationsqualität |
| Phase 7 | 5–9 Wochen | 1.0-Inhalt |
| Phase 8–9 | 4–8 Wochen plus Storewartezeit | Pilot und Veröffentlichung |

Diese Spannen sind Planungswerte, keine Zusage. Nach jedem Gate werden sie anhand realer Geschwindigkeit neu berechnet.

## 7. Risikoregister

| Risiko | Wirkung | Gegenmaßnahme | Stop-Kriterium |
|---|---|---|---|
| Unklare oder widersprüchliche Rollen | falsche Regeln | Regelregister vor Implementierung | Rolle bleibt deaktiviert |
| Scope aus 72 Rollen und 80 Karten | endloser Umbau | 20–30 Rollen für 1.0, Chargen und Gates | keine neue Charge vor Abnahme |
| Geheimnisleck an Clients/TV | Partie zerstört | serverseitige Projektionen und Negativtests | Releaseblocker |
| Save-/Undo-Fehler | Runde unbrauchbar | Eventmodell, atomische Saves, Replaytests | Releaseblocker |
| Schwache Tabletleistung | schlechte Bedienung | 2.5D, Budgets, Qualitätsstufen | Effekte reduzieren |
| Ungeklärte Assetrechte | kein Verkauf möglich | Provenance ab Erstellung, Ersatz früh planen | Asset nicht ausliefern |
| KI erzeugt inkonsistenten Code | technische Schulden | kleine Prompts, Tests, Phase-Branches, Review | Auftrag zurückweisen |
| iOS-/Android-Netzwerkrestriktionen | Clients verbinden nicht | früher technischer Spike auf realen Geräten | Architektur vor UI-Skalierung ändern |
| Eigene Fotos und Namen | Datenschutzrisiko | lokal, Einwilligung, Löschfunktion | keine Cloudübertragung ohne Opt-in |
| Online-Scope verdrängt Kernprodukt | Kosten und Verzögerung | separate Phase nach 1.0 | kein Online-Code vor Stop/Go |

## 8. Budgetrahmen bis 500 €

Geld wird erst nach einem funktionierenden Vertical Slice eingesetzt. Details stehen in `docs/masterplan/BUDGET.md`.

Priorität:

1. rechtssichere Kernmusik und wichtige Sound-Cues,
2. Erzählerstimmen DE/EN,
3. konsistente Schlüsselillustrationen oder Nachbearbeitung,
4. notwendige Store-/Entwicklergebühren,
5. Testhardware nur bei echter Abdeckungslücke.

## 9. Claude-Arbeitsvertrag

Jeder Auftrag muss enthalten:

1. einen einzigen überprüfbaren Zweck,
2. erlaubte und verbotene Dateien,
3. verbindliche Architektur- und Produktentscheidungen,
4. konkrete Tests mit erwartetem Ergebnis,
5. Dokumentations- und Commit-Anforderung,
6. Stop-Bedingungen bei offenen Regeln,
7. Abschlussbericht mit Änderungen, Beweisen und verbleibenden Risiken.

Claude darf keine Rolle erfinden, keinen unbekannten Assetstatus als freigegeben markieren, keine Phase überspringen und keinen Test entfernen, um einen Build grün zu machen.

## 10. Start am Sonntag um 08:00 Uhr

1. In Claude Code Web das Repository `Grimmhain-Revolution`, Branch `main`, auswählen.
2. Den ersten Prompt aus `docs/masterplan/CLAUDE-PROMPTS.md` verwenden.
3. Claude soll nur die Entscheidungs- und Regelspezifikation erstellen; noch keinen Godot-Produktionscode.
4. Ergebnis auf eigenem Claude-Branch prüfen.
5. Offene Regelkonflikte entscheiden und in `DECISION-LOG.md` eintragen.
6. Erst danach Prompt 2 für Toolchain und Godot-Grundgerüst starten.

## 11. Definition of Done für jede Aufgabe

- [ ] Akzeptanzkriterien vollständig erfüllt.
- [ ] Aussagekräftige Tests zuerst fehlgeschlagen und danach bestanden.
- [ ] Keine bestehenden Tests entfernt oder abgeschwächt.
- [ ] Headless-Testlauf grün.
- [ ] Betroffener Plattformbuild erfolgreich.
- [ ] Manuelle Prüfung auf echtem Gerät dokumentiert, wenn UI oder Plattform betroffen ist.
- [ ] DE-/EN-Texte vollständig, wenn sichtbarer Inhalt betroffen ist.
- [ ] Barrierefreiheit und Geheimhaltung geprüft.
- [ ] Assetherkunft ergänzt, wenn Medien betroffen sind.
- [ ] Dokumentation und Entscheidungslog aktualisiert.
- [ ] Kleiner, verständlicher Commit auf dem Phasenbranch.
- [ ] Keine unerklärten Änderungen außerhalb des Auftrags.

## 12. Verbindliche Begleitdokumente

- `docs/masterplan/DECISION-LOG.md` – bestätigte Produkt- und Regelentscheidungen
- `docs/masterplan/RULE-MIGRATION-MATRIX.md` – Status aller für 1.0 gewählten Rollen
- `docs/masterplan/CLAUDE-PROMPTS.md` – direkt verwendbare Arbeitsaufträge
- `docs/masterplan/PHASE-CHECKLISTS.md` – operative Abnahme je Phase
- `docs/masterplan/TEST-MATRIX.md` – Testebenen, Geräte und kritische Szenarien
- `docs/masterplan/ASSET-REGISTER.md` – Herkunft, Lizenz, Freigabe und Ersatzstatus
- `docs/masterplan/BUDGET.md` – Ausgabengates und Kostenrahmen
- `docs/masterplan/RELEASE-CHECKLIST.md` – Pilot-, Store-, Rechts- und Releaseprüfung
