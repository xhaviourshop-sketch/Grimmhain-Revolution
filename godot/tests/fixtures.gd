class_name Fixtures
extends RefCounted
## Gemeinsame Testdaten: Personen A, B, C … mit stabilen IDs 1, 2, 3 …

const NAMES := "ABCDEFGHIJKLMNOPQRSTUVWX"


static func players(count: int) -> Array:
	var result: Array = []
	for i: int in count:
		result.append({"id": i + 1, "name": NAMES[i] if i < NAMES.length() else "P%d" % (i + 1)})
	return result


static func identity_order(count: int) -> Array[int]:
	var order: Array[int] = []
	for i: int in count:
		order.append(i + 1)
	return order


## Manuelle Rollenzuordnung. `wolf_ids` erhalten `werwolf`, alle anderen `dorfbewohner`.
static func start_manual(count: int, wolf_ids: Array[int], seed_value: int = 1, seat_order: Array[int] = []) -> Command:
	var roles := {}
	for i: int in count:
		roles[str(i + 1)] = "werwolf" if wolf_ids.has(i + 1) else "dorfbewohner"
	return Command.start_game({
		"round_id": "test-round",
		"seed": seed_value,
		"assignment": "manual",
		"players": players(count),
		"seat_order": seat_order if not seat_order.is_empty() else identity_order(count),
		"roles": roles,
	})


static func start_random(count: int, wolves: int, seed_value: int) -> Command:
	var pool: Array = []
	for i: int in count:
		pool.append("werwolf" if i < wolves else "dorfbewohner")
	return Command.start_game({
		"round_id": "test-round",
		"seed": seed_value,
		"assignment": "random",
		"players": players(count),
		"seat_order": identity_order(count),
		"role_pool": pool,
	})


## Wendet Befehle nacheinander an und bricht beim ersten abgelehnten ab (dann null).
static func play(commands: Array[Command]) -> GameState:
	var result := RulesEngine.replay(commands)
	return result.state if result.ok else null


## Start mit freier Rollenliste: roles[i] gehört Person i + 1.
## test_mode erlaubt reine Testrollen wie `test-sensentraeger`.
static func start_roles(roles: Array, seed_value: int = 1, test_mode: bool = false) -> Command:
	var map := {}
	for i: int in roles.size():
		map[str(i + 1)] = roles[i]
	var payload := {
		"round_id": "test-round",
		"seed": seed_value,
		"assignment": "manual",
		"players": players(roles.size()),
		"seat_order": identity_order(roles.size()),
		"roles": map,
	}
	if test_mode:
		payload["test_mode"] = true
	return Command.start_game(payload)


## Standardbesetzung für Reaktionstests: 1, 2 Werwölfe; 3 Test-Sensenträger; 4–6 Dorfbewohner.
static func start_reaper_game(seed_value: int = 1) -> Command:
	return start_roles(["werwolf", "werwolf", "test-sensentraeger", "dorfbewohner", "dorfbewohner", "dorfbewohner"], seed_value, true)

