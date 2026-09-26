# Regel-Migrationsmatrix · Arbeitsvorlage

Die vollständige Bestandsanalyse steht in `../godot-migration/04-rules-migration-matrix.md`. Diese Datei ist die verbindliche Freigabetabelle für Inhalte, die tatsächlich in Godot umgesetzt werden.

## Statuswerte

- `candidate`: für eine Charge vorgeschlagen
- `decision-needed`: Text, Code oder gewünschte Regel widersprechen sich
- `approved`: Regeltext und Verhalten durch Product Owner bestätigt
- `implemented`: Core-Verhalten vorhanden
- `verified`: Tests und echte Runde bestanden
- `manual-guide`: App führt den Spielleiter, automatisiert die Regel aber nicht
- `deferred`: nicht Teil des aktuellen Releases
- `rejected`: wird nicht übernommen

## Pflichtfelder pro Rolle

| ID | Anzeigename DE/EN | Fraktion | Charge | Legacy-Status | Verbindliche Regel | Nachtpriorität | Siegbezug | Automationsstatus | Tests | PO-Freigabe |
|---|---|---|---|---|---|---:|---|---|---|---|
| villager | Dorfbewohner / Villager | Dorf | Core | verifiziert | keine Nachtaktion | – | Dorf | approved | core victory | offen |
| werewolf | Werwolf / Werewolf | Wolf | Core | verifiziert | wählt nachts Opfer | Wolfsphase | Wolf | approved | attack, parity | offen |

## Auswahlverfahren für Vertical Slice

Die erste Charge muss zusammen folgende Mechaniken abdecken:

- [ ] Schutz vor Angriff
- [ ] Informationsgewinn
- [ ] gezielte Fehlinformation
- [ ] Wolfsangriff
- [ ] direkte oder verzögerte Todesursache
- [ ] Nominierungsreaktion
- [ ] Todeseffekt und Reaktionswarteschlange
- [ ] Rollen- oder Fraktionswechsel
- [ ] Solo-Sieg oder manuelle Siegerklärung
- [ ] mehrstufiger Prompt mit Abbruch und Wiederaufnahme

## Freigaberegel pro Rolle

Eine Rolle darf `verified` erst erhalten, wenn:

- [ ] stabiler technischer Schlüssel verwendet wird,
- [ ] DE- und EN-Regeltext dasselbe Verhalten beschreiben,
- [ ] normale und ungültige Ziele definiert sind,
- [ ] Konflikte mit Tod, Schutz, Blockierung und Rollenwechsel dokumentiert sind,
- [ ] Nachtpriorität und Dauer jedes Effekts feststehen,
- [ ] Save/Load und Undo während der Aktion getestet sind,
- [ ] Siegbezug geklärt ist,
- [ ] mindestens ein Szenariotest grün ist,
- [ ] Product Owner die Regel freigegeben hat.
