class_name SetupRoleCatalog
extends RefCounted
## Lesender Adapter des Setups auf den Regelkatalog. Alle technischen Rollendaten (IDs,
## Fraktion, Wolfszählung, Nachtpriorität, Höchstzahl, Pflicht-Scheinrolle) kommen aus
## `RoleCatalog` und `Faction`; hier wird nichts davon wiederholt. Die Einzelsiegrolle
## erkennt der Adapter an der Katalog-Fraktion `Faction.SOLO`, nicht am Rollennamen.


## Rolle der Besetzungshinweise (PE-04): Kutscher, der erst ab zehn Toten wiederbelebt (W-03).
const COACH := RoleCatalog.KUTSCHER
## Rollen der Besetzungshinweise (PE-04): Einzelsieg bei höchstens drei Lebenden (Manipulator: genau drei), mehrere davon
## können gleichzeitig Kandidat werden (WinRules, Analyse R-07 C-3).
const SMALL_ROUND_SOLO_ROLES: Array[StringName] = [RoleCatalog.PARASIT, RoleCatalog.VOODOO, RoleCatalog.GRABRAEUBER, RoleCatalog.MANIPULATOR]


## Direkte Wiederbelebungsrolle: löst die Wiederbelebungsrunde aus (DI-01, Regelkern).
static func is_revival_role(role: StringName) -> bool:
	return RoleCatalog.is_revival_role(role)


## Rollen, die das Setup nirgends mehr anbietet (DA-90: jede Person bekommt eine besondere Rolle). Sie bleiben im Katalog, damit
## alte Spielstände laden.
const NOT_OFFERED: Array[StringName] = [RoleCatalog.DORFBEWOHNER]


static func is_offered(role: StringName) -> bool:
	return not NOT_OFFERED.has(role)


## Alle produktiven Rollen-IDs, kanonisch nach ID sortiert.
static func role_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: Variant in RoleCatalog.ROLES:
		out.append(StringName(id))
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


static func has_role(role: StringName) -> bool:
	return RoleCatalog.has_role(role)


static func faction_of(role: StringName) -> StringName:
	return RoleCatalog.faction_of(role)


static func counts_as_wolf(role: StringName) -> bool:
	return RoleCatalog.counts_as_wolf(role)


static func night_priority(role: StringName) -> int:
	return RoleCatalog.night_priority(role)


static func requires_appearance(role: StringName) -> bool:
	return RoleCatalog.requires_appearance(role)


static func max_copies(role: StringName) -> int:
	return RoleCatalog.max_copies(role)


static func is_village(role: StringName) -> bool:
	return RoleCatalog.faction_of(role) == Faction.VILLAGE


static func is_solo(role: StringName) -> bool:
	return RoleCatalog.faction_of(role) == Faction.SOLO


## Höchstzahl im Setup: Katalog-Grenze, sonst die Personenzahl (mehr Kopien passen nie).
static func copy_limit(role: StringName, persons: int) -> int:
	var limit := RoleCatalog.max_copies(role)
	return persons if limit == RoleCatalog.UNLIMITED else mini(limit, persons)


## Zulässige Scheinrollen (bekannt, zählt nicht als Wolf), kanonisch sortiert.
static func appearance_options() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in role_ids():
		if RoleCatalog.is_valid_appearance(id):
			out.append(id)
	return out
