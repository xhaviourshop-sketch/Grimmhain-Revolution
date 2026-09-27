class_name RoleCatalog
extends RefCounted
## Rollen-Stammdaten: `dorfbewohner`, `werwolf` (A-06), die Vertical-Slice-Rollen `sensentraeger`, `schutzengel`, `waldhexe`, `das-orakel`, `trugbilderwolf`, `wolfskind`, `spiegelwolf`, `manipulator` und `lehrling` sowie aus dem Rollenaudit `siegreicher-wolf`, `doppelspion`, `selbstmoerder`, `dorfchronistin` und `die-gebundenen`.
## IDs nach DR-01: deutsches ASCII-kebab-case. Anzeigenamen sind nicht Teil des Kerns.
## Keine fest verdrahtete Rollenkomposition: Die Grundrollen haben keine Obergrenze,
## damit jede Personenzahl von 6 bis 24 allein mit ihnen spielbar ist. Spätere Rollen
## können `max_copies` setzen; wie viele Exemplare eine Partie tatsächlich nutzt,
## entscheidet die Rollenkomposition im Setup (Phase 2), nicht dieser Katalog.

const UNLIMITED := -1

const DORFBEWOHNER := &"dorfbewohner"
const WERWOLF := &"werwolf"
## Sensenträger / Reaper (rules-register.md §7, DR-09): Dorf, kein Nachtschritt,
## freiwillige Todesreaktion (Fluch auf eine lebende Person oder Verzicht).
const SENSENTRAEGER := &"sensentraeger"
## Schutzengel / Guardian Angel (rules-register.md §3, DR-05): Dorf, Nachtschritt vor
## dem Rudel, schützt eine andere lebende Person nur vor dem Wolfsangriff dieser Nacht.
const SCHUTZENGEL := &"schutzengel"
## Waldhexe / Forest Witch (rules-register.md §6, DR-06): Dorf, Nachtschritt nach dem
## Rudel, je ein Heil- und Gifttrank pro Person und Partie (WitchStep).
const WALDHEXE := &"waldhexe"
## Orakel / The Oracle (rules-register.md §4, DR-07): Dorf, Nachtschritt nach der
## Waldhexe, prüft eine andere lebende Person (OracleStep, InformationRules).
const ORAKEL := &"das-orakel"
## Trugbilderwolf / Decoy Wolf (rules-register.md §5, DR-08): Werwölfe, zählt als Wolf,
## kein eigener Schritt (Teil des Rudels). Seine Scheinrolle steht in `Player.appears_as`,
## wird beim Spielaufbau vom Spielleiter festgelegt und ist dort Pflicht.
const TRUGBILDERWOLF := &"trugbilderwolf"
## Wolfskind / Wolf Child (rules-register.md §8, DR-10): beginnt im Dorf, wählt in seiner
## ersten verfügbaren Nacht ein Vorbild und verwandelt sich bei dessen Tod (WolfChildRules).
const WOLFSKIND := &"wolfskind"
## Spiegelwolf / Mirror Wolf (rules-register.md §11, DR-13): Werwölfe, zählt als Wolf, Teil
## des Rudels; spiegelt einmal pro Person eine Hinrichtung auf die nominierende Person (ExecutionRules).
const SPIEGELWOLF := &"spiegelwolf"
## Manipulator (rules-register.md §10, DR-12): Einzelsieg, zählt nicht als Wolf, kein
## Nachtschritt; stirbt bei seiner Nominierung, gewinnt bei exakt drei Lebenden (WinRules).
const MANIPULATOR := &"manipulator"
## Lehrling / Apprentice (rules-register.md §9, DR-11): beginnt im Dorf, wählt verdeckt einen
## Meister aus drei Rollenoptionen und erbt dessen Rolle bei dessen Tod (ApprenticeRules).
const LEHRLING := &"lehrling"
## Siegreicher Wolf / Victorious Wolf (Rollentext, docs/role-migration/10-next-decisions.md):
## Werwölfe, zählt als Wolf, kein eigener Schritt (Teil des Rudels); zählt, solange er lebt,
## in der Wolfsparität wie zwei Wölfe (`parity_weight`, WinRules).
const SIEGREICHER_WOLF := &"siegreicher-wolf"
## Doppelspion / Double Agent (DECISION-LOG „Rollenaudit“, RM-DR-155): Einzelsieg, zählt nicht
## als Wolf, kein eigener Schritt (wacht mit dem Rudel nur als Ansage); gewinnt allein, wenn er
## lebt und kein Wolf mehr lebt; dann wird der Dorfsieg nicht vorgeschlagen (WinRules).
const DOPPELSPION := &"doppelspion"
## Selbstmörder / Death Seeker (DECISION-LOG „Rollenaudit“, RM-DR-138): Einzelsieg, zählt nicht als
## Wolf, kein Schritt; wird er hingerichtet (LYNCH), während mindestens 5 Personen tot sind, ist
## sein Sieg erfüllt (`GameState.death_seeker_wins`, KillPipeline) und wird fortan vorgeschlagen.
const SELBSTMOERDER := &"selbstmoerder"
## Dorfchronistin / Village Chronicler (DECISION-LOG „Rollenaudit“, RM-DR-014 = B, F-09): Dorf;
## persönlicher Informationsschritt nur in Nacht 1 (NightOneInfo).
const DORFCHRONISTIN := &"dorfchronistin"
## Die Gebundenen / The Bound (DECISION-LOG „Rollenaudit“, RM-DR-014 = B, F-08): Dorf; ein
## gemeinsamer Informationsschritt aller Gebundenen nur in Nacht 1 (StepQueue.BOUND, NightOneInfo).
const DIE_GEBUNDENEN := &"die-gebundenen"
## Priorität des gemeinsamen Schritts der Gebundenen (Legacy-Stufe 0.5).
const BOUND_PRIORITY := 5

## Alle begrenzten Einsätze in `Player.ability_uses` (G-ID-3), je höchstens einmal pro Person.
const ABILITY_USE_KEYS: Array[String] = ["sensentraeger:death_reaction", "waldhexe:heal", "waldhexe:poison", "spiegelwolf:mirror"]

## Nachtpriorität persönlicher Schritte (vertical-slice-flow.md §3, ×10 als Ganzzahl):
## Wolfskind 0.9 (nur mit Auswahlbedarf), Lehrling 1.1 (nur mit Auswahlbedarf), Schutzengel 1.3, Rudel 2.0, Waldhexe 3.4, Orakel 4.6. Gleiche Priorität: nach Personen-ID.
const PACK_PRIORITY := 20

const ROLES := {
	DORFBEWOHNER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFBEWOHNER},
	WERWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": WERWOLF},
	SCHUTZENGEL: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": SCHUTZENGEL, "night_priority": 13},
	WALDHEXE: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": WALDHEXE, "night_priority": 34},
	ORAKEL: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": ORAKEL, "night_priority": 46},
	WOLFSKIND: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": WOLFSKIND, "night_priority": 9},
	LEHRLING: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": LEHRLING, "night_priority": 11},
	MANIPULATOR: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": MANIPULATOR},
	SPIEGELWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SPIEGELWOLF},
	TRUGBILDERWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": TRUGBILDERWOLF, "requires_appearance": true},
	SENSENTRAEGER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": SENSENTRAEGER, "death_reaction": Reaction.KIND_CURSE},
	SIEGREICHER_WOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SIEGREICHER_WOLF, "parity_weight": 2},
	DOPPELSPION: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": DOPPELSPION},
	SELBSTMOERDER: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": SELBSTMOERDER},
	DORFCHRONISTIN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFCHRONISTIN, "night_priority": 3, "first_night_only": true},
	DIE_GEBUNDENEN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DIE_GEBUNDENEN},
}


static func has_role(role_id: StringName) -> bool:
	return ROLES.has(role_id)


static func faction_of(role_id: StringName) -> StringName:
	return ROLES[role_id]["faction"]


static func counts_as_wolf(role_id: StringName) -> bool:
	return ROLES[role_id]["counts_as_wolf"]


static func appears_as(role_id: StringName) -> StringName:
	return ROLES[role_id]["appears_as"]


## Art der Todesreaktion oder &"" ohne Reaktion.
static func death_reaction(role_id: StringName) -> StringName:
	return (ROLES[role_id] as Dictionary).get("death_reaction", &"")


## Nachtpriorität des eigenen Schritts jeder lebenden Person mit dieser Rolle
## (vergleichbar mit PACK_PRIORITY) oder 0 ohne eigenen Nachtschritt.
static func night_priority(role_id: StringName) -> int:
	return (ROLES[role_id] as Dictionary).get("night_priority", 0)


## true, wenn der persönliche Schritt der Rolle nur in Nacht 1 stattfindet (RM-DR-014 = B).
static func first_night_only(role_id: StringName) -> bool:
	return (ROLES[role_id] as Dictionary).get("first_night_only", false)


## true, wenn jede Instanz der Rolle eine vom Spielleiter festgelegte Scheinrolle braucht.
static func requires_appearance(role_id: StringName) -> bool:
	return (ROLES[role_id] as Dictionary).get("requires_appearance", false)


## Zulässige Scheinrolle: eine bekannte Rolle, die nicht als Wolf zählt
## (also weder `werwolf` noch `trugbilderwolf`); sie muss nicht in der Partie vorkommen.
static func is_valid_appearance(role_id: StringName) -> bool:
	return has_role(role_id) and not counts_as_wolf(role_id)


## Gewicht einer lebenden Person dieser Rolle in der Wolfsparität (G-SIEG-2), sonst 1.
## Nur für Rollen, die als Wolf zählen; Personenzählungen (DR-12) nutzen es nie.
static func parity_weight(role_id: StringName) -> int:
	return (ROLES[role_id] as Dictionary).get("parity_weight", 1)


## Höchstzahl je Partie oder UNLIMITED, wenn die Rolle keine eigene Grenze hat.
static func max_copies(role_id: StringName) -> int:
	return (ROLES[role_id] as Dictionary).get("max_copies", UNLIMITED)
