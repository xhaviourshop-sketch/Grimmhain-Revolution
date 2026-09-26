class_name RoleCatalog
extends RefCounted
## Rollen-Stammdaten des Core-Slice. Nur `dorfbewohner` und `werwolf` (A-06).
## IDs nach DR-01: deutsches ASCII-kebab-case. Anzeigenamen sind nicht Teil des Kerns.
## Keine fest verdrahtete Rollenkomposition: Die Grundrollen haben keine Obergrenze,
## damit jede Personenzahl von 6 bis 24 allein mit ihnen spielbar ist. Spätere Rollen
## können `max_copies` setzen; wie viele Exemplare eine Partie tatsächlich nutzt,
## entscheidet die Rollenkomposition im Setup (Phase 2), nicht dieser Katalog.

const UNLIMITED := -1

const DORFBEWOHNER := &"dorfbewohner"
const WERWOLF := &"werwolf"

const ROLES := {
	DORFBEWOHNER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFBEWOHNER},
	WERWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": WERWOLF},
}


static func has_role(role_id: StringName) -> bool:
	return ROLES.has(role_id)


static func faction_of(role_id: StringName) -> StringName:
	return ROLES[role_id]["faction"]


static func counts_as_wolf(role_id: StringName) -> bool:
	return ROLES[role_id]["counts_as_wolf"]


static func appears_as(role_id: StringName) -> StringName:
	return ROLES[role_id]["appears_as"]


## Höchstzahl je Partie oder UNLIMITED, wenn die Rolle keine eigene Grenze hat.
static func max_copies(role_id: StringName) -> int:
	return (ROLES[role_id] as Dictionary).get("max_copies", UNLIMITED)
