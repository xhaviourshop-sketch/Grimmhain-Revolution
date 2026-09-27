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
| dorfbewohner | Dorfbewohner / Villager | Dorf | Core | verifiziert | keine Nachtaktion (Regelregister §1) | – | Dorf | implemented | `test_player_count_range.gd`, Szenarien `as-c01` bis `as-c04` | bestätigt 2026-09-26 |
| werwolf | Werwolf / Werewolf | Wolf | Core | verifiziert | wählt nachts Opfer (Regelregister §2) | Wolfsphase (20) | Wolf | implemented | `test_steps.gd`, `test_replay.gd`, `test_save_load.gd`, Szenarien `as-c01` bis `as-c03`, `as-c10` | bestätigt 2026-09-26 |
| schutzengel | Schutzengel / Guardian Angel | Dorf | Vertical Slice | Legacy-Bug (Verbrauch beim Antippen) | Regelregister §3, DR-05 | 13 | Dorf | implemented | `test_schutzengel.gd` (29) | DR-05, bestätigt 2026-09-26 |
| waldhexe | Waldhexe / Witch of the Woods | Dorf | Vertical Slice | verifiziert, Text mehrdeutig | Regelregister §6, DR-06 | 34 | Dorf | implemented | `test_waldhexe.gd` (43) | DR-06, bestätigt 2026-09-26 |
| das-orakel | Das Orakel / The Oracle | Dorf | Vertical Slice | verifiziert | Regelregister §4, DR-07 | 46 | Dorf | implemented | `test_orakel.gd` (28) | DR-07, bestätigt 2026-09-26 |
| trugbilderwolf | Trugbilderwolf / Decoy Wolf | Wolf | Vertical Slice | verifiziert (Zufall durch DR-08 ersetzt) | Regelregister §5, DR-08 | Wolfsphase (Rudel) | Wolf | implemented | `test_trugbilderwolf.gd` (23), `test_gm_role_field.gd` | DR-08, bestätigt 2026-09-26 |
| sensentraeger | Sensenträger / Reaper | Dorf | Vertical Slice | widersprüchlich (Zeitpunkt) | Regelregister §7, DR-09 | – (Todesreaktion) | Dorf | implemented | `test_sensentraeger.gd` (21), `test_reactions.gd` (9) | DR-09, bestätigt 2026-09-26 |
| wolfskind | Wolfskind / Wolf Child | Dorf, verwandelt Wolf | Vertical Slice | verifiziert | Regelregister §8, DR-10 | 9 | Dorf bzw. Wolf | implemented | `test_wolfskind.gd` (24) | DR-10, bestätigt 2026-09-26 |
| lehrling | Lehrling / Apprentice | Dorf, nach Erbe die der Rolle | Vertical Slice | Legacy-Bug F5 | Regelregister §9, DR-11 und Korrekturrunden | 11 | nach geerbter Rolle | implemented | `test_lehrling.gd` (23) | DR-11, bestätigt 2026-09-26 |
| manipulator | Manipulator / Manipulator | Einzelsieg | Vertical Slice | Legacy-Bug (Richter-Nominierung) | Regelregister §10, DR-12 | – | Einzelsieg bei exakt drei Lebenden | implemented | `test_manipulator.gd` (18) | DR-12, bestätigt 2026-09-26 |
| spiegelwolf | Spiegelwolf / Mirror Wolf | Wolf | Vertical Slice | verifiziert | Regelregister §11, DR-13 | Wolfsphase (Rudel) | Wolf | implemented | `test_spiegelwolf.gd` (20) | DR-13, bestätigt 2026-09-26 |

Stand 2026-09-26 (Basiscommit `4673b0b`): Alle 11 Rollen sind im Regelkern umgesetzt und durch headless Tests belegt (351 Tests grün). Keine Rolle ist `verified`, weil eine echte Runde und Undo/Redo noch fehlen. Nachweis je Rolle: `../role-migration/02-implemented-roles-audit.md`. Planung der übrigen 61 Rollen, Widersprüche, 1.0-Optionen, Chargen und offene Entscheidungen: `../role-migration/` (Einstieg `09-executive-summary.md`).

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
