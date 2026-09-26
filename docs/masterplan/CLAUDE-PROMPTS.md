# Claude-Code-Prompts

Jeden Prompt in einer neuen Claude-Code-Cloud-Sitzung auf dem angegebenen Branch verwenden. Claude darf nicht mehrere Prompts selbstständig verbinden.

## Prompt 1 · Sonntag 08:00 · Regeln und Vertical Slice festziehen

```text
Arbeite im Repository Grimmhain-Revolution auf einem neuen Branch von main.

Lies zuerst vollständig:
- GRIMMHAIN-REVOLUTION-MASTERPLAN.md
- docs/masterplan/DECISION-LOG.md
- docs/masterplan/RULE-MIGRATION-MATRIX.md
- docs/godot-migration/01-current-system-inventory.md
- docs/godot-migration/04-rules-migration-matrix.md
- docs/godot-migration/07-open-questions.md

Ziel dieses Auftrags ist ausschließlich eine verbindliche Spezifikation für den ersten Godot-Vertical-Slice. Schreibe noch keinen Godot-Produktionscode und ändere keine Legacy-Spiellogik.

Erstelle unter docs/specs/vertical-slice/:
1. role-selection.md: Wähle 8 bis 12 bestehende Rollen, die gemeinsam Schutz, Information, Fehlinformation, Wolfsangriff, Nominierungsreaktion, Todeseffekt, Rollenwechsel, mehrstufige Aktion und Solo-Sieg abdecken. Begründe jede Auswahl. Version 1.0 zielt später auf 20 bis 30 Rollen.
2. rules-register.md: Formuliere für jede ausgewählte Rolle einen eindeutigen verbindlichen DE-Regeltext, einen semantisch gleichen EN-Text, Fraktion, Nachtpriorität, gültige Ziele, Dauer, Auflösung, Konflikte, Siegbezug und manuelle Übersteuerung. Erfinde keine Entscheidung. Markiere Konflikte als DECISION REQUIRED mit Text-, Code- und Empfehlungsspalte.
3. vertical-slice-flow.md: Beschreibe Setup → Rollenanzeige → erste Nacht → Morgenbericht → Tag → physische Nominierung/Abstimmung → Spielleiter bestätigt Lynch/Kill → nächste Nacht → möglicher Sieg. Stimmen werden nicht digital erfasst. Gespeichert werden Nominierende, Nominierte und die bestätigte Todesaktion.
4. acceptance-scenarios.md: Definiere konkrete Given/When/Then-Szenarien einschließlich Save/Load, Undo, App-Abbruch, gleichem Seed, Sitztausch und falscher Information.
5. implementation-boundary.md: Liste exakt auf, was der folgende Core-Slice implementiert und was bewusst später kommt.
6. decision-request.md: Nur tatsächlich blockierende Product-Owner-Entscheidungen, jeweils mit 2–3 Optionen, Auswirkung und Empfehlung.

Verbindliche Regeln:
- Tablet ist die einzige Zustandsautorität.
- Spielzustand hängt an stabiler Personen-ID, nicht am Sitzplatz.
- Bestehende Bugs sind keine Referenz.
- Keine digitale Stimmabgabe oder Stimmzählung.
- Geheime, ermittelte und tatsächlich gezeigte Information sind getrennt.
- Alle Zufallsentscheidungen müssen später mit gespeichertem Seed reproduzierbar sein.
- Offene mehrstufige Aktionen müssen später persistierbar sein.
- Verweise mit relativen Pfaden und Symbolnamen belegen.

Führe node tests/smoke.js und node tools/compare-i18n.js aus, benenne aber ausdrücklich deren begrenzte Aussagekraft. Abschlussbericht: erstellte Dateien, gewählte Rollen, offene Entscheidungen, Risiken und der exakt nächste Auftrag. Committe und pushe nur die Dokumente auf deinen Branch.
```

## Prompt 2 · Toolchain und Headless-Core-Skelett

Erst verwenden, nachdem `decision-request.md` entschieden und eingepflegt wurde.

```text
Implementiere ausschließlich Phase 1 aus GRIMMHAIN-REVOLUTION-MASTERPLAN.md auf einem neuen Phasenbranch. Lies zuvor die freigegebene Vertical-Slice-Spezifikation und docs/godot-migration/03-godot-architecture.md.

Lege godot/ als Godot-4.x-GDScript-Projekt an. Der Domain-Core darf keine Szenen, Nodes, UI, Audio-, Netzwerk- oder Dateisystemzugriffe besitzen. Schreibe zuerst fehlschlagende headless Tests für: Wolfsparität, Tod des letzten Wolfs, identisches Replay mit gleichem Seed, Save/Load mit identischem fachlichem Hash und Erkennung einer beschädigten Save-Datei. Implementiere danach nur den minimalen Core, der diese Tests erfüllt.

Pflichtbestandteile: stabile Player-ID getrennt von Sitzposition, GameState, Commands, Events, PhaseMachine, Prompt-Grundmodell, KillEvent mit Ursache/Quelle/Ziel, SeededRng, WinCandidate mit Spielleiterbestätigung und versionierter JSON-Codec. Keine Rollen außer Dorfbewohner und Werwolf. Keine UI. Keine Assets.

Dokumentiere exakte Godot-Version, Testbefehle und Dateiverantwortung. Führe alle Tests headless aus. Committe in kleinen fachlichen Commits. Stoppe bei jeder Regelannahme, die der freigegebenen Spezifikation widerspricht.
```

## Prompt-Schablone für spätere Arbeitspakete

```text
Zweck: [ein überprüfbares Ergebnis]
Branch: [phase/NN-name]
Lies: [Masterplan + konkrete Spezifikation]
Erlaubte Dateien: [exakte Pfade]
Verboten: [angrenzende Bereiche]
Vorbedingungen: [freigegebene Entscheidungen]
Akzeptanzkriterien: [beobachtbar]
Tests zuerst: [exakte Fälle und Befehle]
Geräteprüfung: [Gerät und Ablauf]
Dokumentation: [zu aktualisierende Dateien]
Commit: [kleine fachliche Commits]
Stoppe wenn: [fehlende Regel, Lizenz, Geheimhaltungs- oder Architekturkonflikt]
Abschlussbericht: Änderungen, Testbeweise, Gerätebeweis, Risiken, nächster einzelner Schritt.
```
