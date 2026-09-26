class_name RoleCatalog
extends RefCounted
## Rollen-Stammdaten des Core-Slice. Nur `dorfbewohner` und `werwolf` (A-06).
## IDs nach DR-01: deutsches ASCII-kebab-case. Anzeigenamen sind nicht Teil des Kerns.
## Obergrenzen nach vertical-slice-flow.md §1.3 (Legacy setup.html).

const DORFBEWOHNER := &"dorfbewohner"
const WERWOLF := &"werwolf"

const ROLES := {
	DORFBEWOHNER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFBEWOHNER, "max_copies": 10},
	WERWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": WERWOLF, "max_copies": 5},
}


static func has_role(role_id: StringName) -> bool:
	return ROLES.has(role_id)


static func faction_of(role_id: StringName) -> StringName:
	return ROLES[role_id]["faction"]


static func counts_as_wolf(role_id: StringName) -> bool:
	return ROLES[role_id]["counts_as_wolf"]


static func appears_as(role_id: StringName) -> StringName:
	return ROLES[role_id]["appears_as"]


static func max_copies(role_id: StringName) -> int:
	return ROLES[role_id]["max_copies"]
