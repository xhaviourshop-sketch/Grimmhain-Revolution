class_name RoleDistribution
extends RefCounted
## Deterministische Verteilung und Scheinrollen. Einzige Zufallsquelle ist `SeededRng` mit
## einem gespeicherten Seed; keine globale Zufallsfunktion, keine Uhr. Gleiche Personen-IDs,
## gleicher Pool und gleicher Seed ergeben immer dieselbe Zuordnung.
##
## Zufällige Verteilung: Personen-IDs aufsteigend sortieren, den kanonischen Pool mit
## SeededRng(effektiver Seed) mischen (Fisher-Yates), dann paarweise zuordnen. Das Ergebnis
## hängt an der Personen-ID, nicht an Listenposition, Name oder Sprache.
## Neu mischen: effektiver Seed = Basis-Seed für Zählerstand 0, sonst mix(Basis, Zähler).
## Scheinrolle: SeededRng(mix(effektiver Seed, APPEARANCE_SALT + Personen-ID)) wählt eine
## der kanonisch sortierten zulässigen Scheinrollen (bekannt, zählt nicht als Wolf).

const MAX_SEED := CanonicalJson.MAX_SAFE_INT   ## Seeds bleiben JSON-sicher (StartGame-Grenze)
const MIX_FACTOR := 2654435761                  ## Knuth: multiplikatives Hashing
const APPEARANCE_SALT := 1000003


static func mix(seed_value: int, salt: int) -> int:
	return posmod(seed_value + salt * MIX_FACTOR, MAX_SEED)


static func effective_seed(base_seed: int, shuffle_count: int) -> int:
	return base_seed if shuffle_count == 0 else mix(base_seed, shuffle_count)


static func is_valid_seed(value: int) -> bool:
	return value >= 0 and value <= MAX_SEED


static func random_assignment(person_ids: Array[int], pool: Array[StringName], seed_value: int) -> Dictionary[int, StringName]:
	var ids := person_ids.duplicate()
	ids.sort()
	var shuffled := SeededRng.new(seed_value).shuffled(pool)
	var out: Dictionary[int, StringName] = {}
	for i: int in ids.size():
		out[ids[i]] = StringName(shuffled[i])
	return out


static func appearance_for(person_id: int, seed_value: int) -> StringName:
	var options := SetupRoleCatalog.appearance_options()
	var rng := SeededRng.new(mix(seed_value, APPEARANCE_SALT + person_id))
	return options[rng.next_int(0, options.size() - 1)]


## Scheinrollen für alle Personen, deren Rolle eine Pflicht-Scheinrolle braucht.
static func appearances_for(assignment: Dictionary[int, StringName], seed_value: int) -> Dictionary[int, StringName]:
	var out: Dictionary[int, StringName] = {}
	for person: int in assignment:
		if SetupRoleCatalog.requires_appearance(assignment[person]):
			out[person] = appearance_for(person, seed_value)
	return out
