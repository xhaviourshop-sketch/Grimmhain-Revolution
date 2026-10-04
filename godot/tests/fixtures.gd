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


## Wirkungsarme Füllrollen für Tests, die nur „Wolf“ oder „Dorf“ als Mengenangabe brauchen (PE-07: jede Rolle
## höchstens einmal, `dorfbewohner` und `werwolf` je einmal). Reihenfolge = zunehmende Nebenwirkung:
## Dorf: kein Nachtschritt, keine Todesreaktion; `wahnsinniger-kutscher` wirkt nur bei Hinrichtung, `detektiv` nur nach dem Tod eines Wolfs.
## Wolf: `blutwolf` nur Stimmhinweis, `rudelvater` schützt sich einmal vor Nachttod, `seuchenwolf` wirkt erst bei seinem Tod.
## Wer eine Rolle sonst braucht, listet sie ausdrücklich; die Füller ersetzen keine Sonderrolle.
const VILLAGE_FILLERS: Array[String] = ["dorfbewohner", "amalia", "detektiv", "wahnsinniger-kutscher", "waechter-am-tor", "der-weise",
	"nachtwaechter", "ritter", "dorfwache"]
const WOLF_FILLERS: Array[String] = ["werwolf", "blutwolf", "rudelvater", "seuchenwolf", "cerberus", "fenrir"]

## Weitere verschiedene Dorfrollen mit Nachtschritten oder Reaktionen. Nur für Personen, die vor der Nacht tot sind oder
## nie aufgerufen werden (große Runden für Kutscher-Tests); sie dürfen keine Testaussage tragen.
const EXTRA_VILLAGE: Array[String] = ["koenig", "kriegerin-des-lichts", "blutpriester", "maertyrerin", "schutzgeist", "dorfschmied",
	"verdammniswaechter", "rotkaeppchen", "kopfgeldjaeger", "faehrtenleser", "waldlaeufer", "traumdeuter", "henker"]


static func extra_village(count: int, skip: Array = []) -> Array:
	return _fillers(EXTRA_VILLAGE, count, skip)


## Die ersten `count` Füllrollen des Dorfs, ohne die Rollen in `skip` (schon anderweitig vergeben).
## Über die wirkungsarmen Füller hinaus (Dorf: 9, Wolf: 6) folgen weitere verschiedene Rollen des Katalogs in Katalogreihenfolge
## (mit Nachtschritten und Reaktionen), damit große Partien bis 24 Personen gültig besetzt werden können.
static func village_fillers(count: int, skip: Array = []) -> Array:
	return _fillers(_extended(VILLAGE_FILLERS, Faction.VILLAGE), count, skip)


static func wolf_fillers(count: int, skip: Array = []) -> Array:
	return _fillers(_extended(WOLF_FILLERS, Faction.WOLVES), count, skip)


## Füller, danach alle übrigen Katalogrollen der Seite (ohne Trugbilderwolf: verlangt eine Scheinrolle im Start).
static func _extended(base: Array[String], faction: StringName) -> Array[String]:
	var out: Array[String] = base.duplicate()
	if faction == Faction.VILLAGE:
		for role: String in EXTRA_VILLAGE:
			if not out.has(role):
				out.append(role)
	for id: StringName in RoleCatalog.ROLES:
		if RoleCatalog.faction_of(id) == faction and not RoleCatalog.requires_appearance(id) and not out.has(String(id)):
			out.append(String(id))
	return out


static func _first_free(pool: Array, taken: Array) -> String:
	for role: String in pool:
		if not taken.has(role):
			return role
	assert(false, "kein freier Füller")
	return ""


static func _fillers(pool: Array, count: int, skip: Array) -> Array:
	var out: Array = []
	for role: String in pool:
		if out.size() == count:
			break
		if not skip.has(role):
			out.append(role)
	assert(out.size() == count, "nicht genug Füllrollen")
	return out


## Rollenliste für `count` Personen: `wolf_ids` (Personen-IDs) erhalten Wolfsfüller, alle anderen Dorffüller.
## `specials` (Personen-ID als Text → Rolle) setzt einzelne Rollen fest; sie zählen nicht als Füller.
static func filled_roles(count: int, wolf_ids: Array[int], specials: Dictionary = {}) -> Dictionary:
	var roles := {}
	var used: Array = specials.values()
	var wolves := 0
	var villagers := 0
	for i: int in count:
		var key := str(i + 1)
		if specials.has(key):
			roles[key] = specials[key]
		elif wolf_ids.has(i + 1):
			roles[key] = wolf_fillers(wolves + 1, used)[wolves]
			wolves += 1
		else:
			roles[key] = village_fillers(villagers + 1, used)[villagers]
			villagers += 1
	return roles


## Manuelle Rollenzuordnung. `wolf_ids` erhalten Wolfsfüller (Werwolf, Blutwolf, …), alle anderen Dorffüller
## (Dorfbewohner, Amalia, …); jede Rolle kommt höchstens einmal vor (PE-07).
static func start_manual(count: int, wolf_ids: Array[int], seed_value: int = 1, seat_order: Array[int] = []) -> Command:
	return Command.start_game({
		"round_id": "test-round",
		"seed": seed_value,
		"assignment": "manual",
		"players": players(count),
		"seat_order": seat_order if not seat_order.is_empty() else identity_order(count),
		"roles": filled_roles(count, wolf_ids),
	})


static func start_random(count: int, wolves: int, seed_value: int) -> Command:
	var pool: Array = wolf_fillers(wolves)
	pool.append_array(village_fillers(count - wolves))
	return Command.start_game({
		"round_id": "test-round",
		"seed": seed_value,
		"assignment": "random",
		"players": players(count),
		"seat_order": identity_order(count),
		"role_pool": pool,
	})


## Gültige Startbesetzung mit lauter verschiedenen Rollen (PE-07), Person i + 1 erhält Eintrag i.
## Ein Werwolf, ein Dorfbewohner, danach feste Sonderrollen; reicht für 6 bis 24 Personen.
const UNIQUE_ORDER: Array[String] = ["werwolf", "dorfbewohner", "das-orakel", "waldhexe", "schutzengel", "blutwolf", "doktor",
	"waldlaeufer", "dorfwache", "ritter", "detektiv", "nachtwaechter", "faehrtenleser", "der-weise", "spiegelwolf", "manipulator",
	"sensentraeger", "lehrling", "wolfskind", "traumdeuter", "besessener-wolf", "wahnsinniger-kutscher", "dorfchronistin", "henker"]


static func unique_roles(count: int) -> Array:
	return UNIQUE_ORDER.slice(0, count)


## Startbesetzung für Tests mit derselben Rolle mehrfach im Spiel (PE-07). Der Start selbst ist zulässig: die zweite und
## jede weitere Kopie beginnt als Füller derselben Seite. Danach setzt je eine Spielleiterkorrektur „Rolle setzen“ die Kopie;
## so entstehen gleiche Rollen auch im Spiel (Verwandlung, Erbe, Diebstahl, Korrektur; nicht neu geregelt).
## Ergebnis: StartGame, danach die Korrekturen. `Die Gebundenen` bleiben mehrfach im Start.
## `appearances` (Personen-ID als Text → Scheinrolle) gilt für Trugbilderwölfe: im Start für Erstbesitzer, in der Korrektur für Kopien.
static func start_with_copies(roles: Array, seed_value: int = 1, appearances: Dictionary = {}) -> Array[Command]:
	var used: Array = []
	var start_roles_list: Array = []
	var copies: Dictionary = {}
	for i: int in roles.size():
		var role := String(roles[i])
		if used.has(role) and role != "die-gebundenen":
			var wolf := RoleCatalog.counts_as_wolf(StringName(role))
			var placeholder := _first_free(_extended(WOLF_FILLERS, Faction.WOLVES) if wolf else _extended(VILLAGE_FILLERS, Faction.VILLAGE), roles + start_roles_list)
			start_roles_list.append(placeholder)
			copies[i + 1] = role
		else:
			start_roles_list.append(role)
		used.append(role)
	var first := start_roles(start_roles_list, seed_value)
	var start_appearances := {}
	for key: Variant in appearances:
		if not copies.has(int(key)):
			start_appearances[key] = appearances[key]
	if not start_appearances.is_empty():
		var payload := first.payload.duplicate(true)
		payload["appearances"] = start_appearances
		first = Command.start_game(payload)
	var out: Array[Command] = [first]
	for id: int in copies:
		var fields := {"target_id": id, "role_id": copies[id]}
		if RoleCatalog.requires_appearance(StringName(copies[id])):
			fields["appears_as"] = appearances.get(str(id), "waldhexe")
		out.append(CorrectionFixtures.gm("set_role", fields, "Test: Kopie der Rolle"))
	return out



## Füllplätze in Tests: jedes weitere „dorfbewohner“ oder „werwolf“ (PE-07: nur einmal beim Start) wird durch den nächsten freien
## wirkungsarmen Füller derselben Seite ersetzt (Dorf: Amalia, Detektiv, …; Wolf: Blutwolf, …). Alle anderen Einträge bleiben
## unverändert. Der Wächter am Tor wird übersprungen, wenn die Besetzung Rollen enthält, die zum Wolf werden können.
static func legalize(roles: Array) -> Array:
	var becomes_wolf := ["wolfskind", "lehrling", "koenig-lykaon", "kutscher", "seelentauscher"]
	var blocked := false
	for role: Variant in roles:
		blocked = blocked or becomes_wolf.has(String(role))
	var out: Array = []
	var seen := {}
	for role: Variant in roles:
		var id := String(role)
		if (id == "dorfbewohner" or id == "werwolf") and seen.has(id):
			var pool: Array = _extended(WOLF_FILLERS, Faction.WOLVES) if id == "werwolf" else _extended(VILLAGE_FILLERS, Faction.VILLAGE)
			var taken: Array = roles + out
			if blocked:
				taken.append("waechter-am-tor")
			id = _first_free(pool, taken)
		seen[id] = true
		out.append(id)
	return out


## Setup-Zählungen mit Füllplätzen (PE-07): „dorfbewohner“ oder „werwolf“ mit Anzahl n > 1 wird zu je einer Kopie dieser Rolle
## plus n − 1 verschiedenen wirkungsarmen Füllern derselben Seite. Alle anderen Einträge (auch Die Gebundenen) bleiben unverändert.
static func legal_counts(counts: Dictionary) -> Dictionary:
	var taken: Array = []
	for role: Variant in counts:
		if int(counts[role]) > 0:
			taken.append(String(role))
	var out := {}
	for role: Variant in counts:
		var id := String(role)
		var n := int(counts[role])
		if (id == "dorfbewohner" or id == "werwolf") and n > 1:
			out[id] = 1
			var extra := village_fillers(n - 1, taken) if id == "dorfbewohner" else wolf_fillers(n - 1, taken)
			for filler: String in extra:
				out[filler] = 1
				taken.append(filler)
		else:
			out[id] = counts[role]
	return out


## Wie `start_with_copies`, gefolgt von den weiteren Befehlen; `rest` sind die Befehle danach.
static func with_copies(roles: Array, rest: Array[Command], seed_value: int = 1, appearances: Dictionary = {}) -> Array[Command]:
	var out := start_with_copies(roles, seed_value, appearances)
	out.append_array(rest)
	return out


## Dorfrollen ohne Todesfolge, Nachtschritt oder Hinweis: Ihr Tod verändert in einem Test nichts außer der Zahl der Lebenden.
const INERT_ROLES: Array[StringName] = [&"dorfbewohner", &"amalia", &"detektiv", &"nachtwaechter", &"waechter-am-tor", &"wahnsinniger-kutscher"]


## Rudelopfer ohne Bedeutung für den Test. Seit der Entscheidung „Werwölfe töten jede Nacht ein Opfer“ gibt es kein „Kein Opfer“ mehr:
## gewählt wird unter `allowed` die Person mit der höchsten ID und einer wirkungslosen Rolle (`INERT_ROLES`),
## sonst die höchste Person ohne Wolfszählung, sonst die letzte.
static func fodder(s: GameState, allowed: Array) -> int:
	return last_villager(s, allowed)


## Rudelopfer am Ende der Sitzordnung: höchste ID unter `allowed` mit wirkungsloser Rolle, sonst ohne Wolfszählung (Totenreich-Tests nutzen die
## hinteren Plätze nie).
static func last_villager(s: GameState, allowed: Array) -> int:
	var best := -1
	for id: int in allowed:
		if INERT_ROLES.has(s.players[id].role_id) and id > best:
			best = id
	if best != -1:
		return best
	for id: int in allowed:
		if not s.players[id].counts_as_wolf and id > best:
			best = id
	return best if best != -1 else int(allowed[allowed.size() - 1])


## Rudelopfer, der in `answers` (Schlüssel "<rolle>:<id>…" und Ziellisten, auch verschachtelt) nicht vorkommt: höchste wirkungslose Person.
static func quiet_victim(s: GameState, allowed: Array, answers: Dictionary = {}) -> int:
	var avoid: Array = []
	for key: Variant in answers:
		var parts := String(key).split(":")
		if parts.size() >= 2 and parts[1].split("@")[0].is_valid_int():
			avoid.append(int(parts[1].split("@")[0]))
		_collect_ids(answers[key], avoid)
	var pool := allowed.filter(func(id: int) -> bool: return not avoid.has(id) and INERT_ROLES.has(s.players[id].role_id))
	if pool.is_empty():
		pool = allowed.filter(func(id: int) -> bool: return not avoid.has(id) and not s.players[id].counts_as_wolf)
	return fodder(s, pool if not pool.is_empty() else allowed)


static func _collect_ids(value: Variant, out: Array) -> void:
	if value is Array:
		for item: Variant in value:
			_collect_ids(item, out)
	elif value is int and not value is bool:
		out.append(value)


## Mindestantwort auf einen Prompt ohne Bedeutung für den Test: `min_count` Personen, bei Pflichtwahlen zuerst `fodder`.
## Prompts ohne Mindestzahl (Verzicht erlaubt) bekommen eine leere Auswahl.
static func pass_targets(s: GameState, p: PendingPrompt) -> Array:
	var out: Array = []
	if p.min_count <= 0 or p.allowed_ids.is_empty():
		return out
	if p.owner == &"feuerteufel":  # dieselbe Person erneut markieren = Markierung behalten
		var kept := SoloRules.fire_mark_of(s, p.actor_id)
		if p.allowed_ids.has(kept):
			return [kept]
	out.append(fodder(s, p.allowed_ids))
	for id: int in p.allowed_ids:
		if out.size() >= p.min_count:
			break
		if not out.has(id):
			out.append(id)
	return out


## Wendet Befehle nacheinander an und bricht beim ersten abgelehnten ab (dann null).
static func play(commands: Array[Command]) -> GameState:
	var result := RulesEngine.replay(commands)
	return result.state if result.ok else null


## Start mit freier Rollenliste: roles[i] gehört Person i + 1.
static func start_roles(roles: Array, seed_value: int = 1) -> Command:
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
	return Command.start_game(payload)


## Standardbesetzung für Reaktionstests: 1, 2 Wölfe (Werwolf, Blutwolf); 3 Sensenträger; 4–6 Dorffüller.
static func start_reaper_game(seed_value: int = 1) -> Command:
	return start_roles(["werwolf", "blutwolf", "sensentraeger", "dorfbewohner", "amalia", "detektiv"], seed_value)

