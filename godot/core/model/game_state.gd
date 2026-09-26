class_name GameState
extends RefCounted
## Vollständiger fachlicher Spielzustand. Wird nur von RulesEngine verändert,
## und zwar immer auf einer Kopie (RulesEngine.apply ist für den Aufrufer rein).
## Anzeige- und Zeitwerte gehören nicht hierher (03 §6.3).

const SCHEMA_VERSION := 2  ## 2: Nachtplan, Reaktionswarteschlange, vorläufiger Siegstatus
const RULES_VERSION := &"grimmhain-core-0.2"
## Reine Zählfelder, die nicht zum fachlichen Hash gehören (Befehls- und ID-Zähler).
const HASH_EXCLUDED_KEYS: Array[String] = ["command_count", "next_ids"]
const NO_TARGET := -1

var schema_version: int = SCHEMA_VERSION
var rules_version: StringName = RULES_VERSION
var round_id: String = ""
var rng: SeededRng = SeededRng.new(0)
var phase: StringName = Phase.SETUP
var day_step: StringName = Phase.DAY_NONE
var night_number: int = 0
var day_number: int = 0
var players: Dictionary[int, Player] = {}
var seat_order: Array[int] = []  ## Personen-IDs im Uhrzeigersinn ab Sitz 0
var pending_prompt: PendingPrompt = null
var pack_target_id: int = NO_TARGET  ## gewähltes Rudelopfer der laufenden Nacht
var night_plan: Array[StringName] = []  ## Schritte der laufenden Nacht in Reihenfolge
var next_night_step: int = 0            ## Index des nächsten nicht erledigten Nachtschritts
var reactions: Array[Reaction] = []     ## offene Reaktionen, erste = nächste
var provisional_win: Array = []         ## vorläufiger Siegstatus seit dem letzten Tod (DR-14)
var win_check_pending: bool = false     ## verbindliche Siegprüfung steht aus (DR-14)
var nominations: Array[Nomination] = []
var win_candidate: WinCandidate = null  ## offener Kandidat
var winner: WinCandidate = null         ## bestätigter Sieg
var command_count: int = 0              ## Anzahl angewandter Befehle
var next_event_index: int = 1
var next_prompt_id: int = 1
var next_candidate_id: int = 1
var next_death_order: int = 1
var next_reaction_id: int = 1


func is_started() -> bool:
	return not players.is_empty()


## Lebende Personen-IDs, aufsteigend sortiert.
func alive_ids() -> Array[int]:
	var ids: Array[int] = []
	for id: int in players:
		if players[id].alive:
			ids.append(id)
	ids.sort()
	return ids


## Sitzindex einer Person oder -1.
func seat_of(player_id: int) -> int:
	return seat_order.find(player_id)


func nominations_on_day(day: int) -> Array[Nomination]:
	var result: Array[Nomination] = []
	for n: Nomination in nominations:
		if n.day == day:
			result.append(n)
	return result


## Fachlicher Hash (AS-C07, AS-A02): SHA-256 über die kanonische JSON-Darstellung
## ohne reine Zählfelder. Ein abgebrochener Schritt hinterlässt so denselben Hash
## wie vor seinem Beginn. Replay- und Integritätsprüfung vergleichen den vollständigen Zustand.
func content_hash() -> String:
	var d := to_dict()
	for key: String in HASH_EXCLUDED_KEYS:
		d.erase(key)
	return CanonicalJson.sha256(d)


func duplicate_state() -> GameState:
	return GameState.from_dict(to_dict())


func to_dict() -> Dictionary:
	var ids: Array[int] = []
	ids.assign(players.keys())
	ids.sort()
	var player_list: Array = []
	for id: int in ids:
		player_list.append(players[id].to_dict())
	var nomination_list: Array = []
	for n: Nomination in nominations:
		nomination_list.append(n.to_dict())
	var reaction_list: Array = []
	for r: Reaction in reactions:
		reaction_list.append(r.to_dict())
	var plan: Array = []
	for step: StringName in night_plan:
		plan.append(String(step))
	return {
		"schema_version": schema_version,
		"rules_version": String(rules_version),
		"round_id": round_id,
		"rng": rng.to_dict(),
		"phase": String(phase),
		"day_step": String(day_step),
		"night_number": night_number,
		"day_number": day_number,
		"players": player_list,
		"seat_order": seat_order.duplicate(),
		"pending_prompt": pending_prompt.to_dict() if pending_prompt != null else null,
		"pack_target_id": pack_target_id,
		"night_plan": plan,
		"next_night_step": next_night_step,
		"reactions": reaction_list,
		"provisional_win": provisional_win.duplicate(true),
		"win_check_pending": win_check_pending,
		"nominations": nomination_list,
		"win_candidate": win_candidate.to_dict() if win_candidate != null else null,
		"winner": winner.to_dict() if winner != null else null,
		"command_count": command_count,
		"next_ids": {
			"event": next_event_index,
			"prompt": next_prompt_id,
			"candidate": next_candidate_id,
			"death_order": next_death_order,
			"reaction": next_reaction_id,
		},
	}


## Baut einen Zustand aus einem Dictionary. Liefert null bei struktureller Ungültigkeit.
static func from_dict(d: Dictionary) -> GameState:
	var s := GameState.new()
	s.schema_version = DictRead.get_int(d, "schema_version", -1)
	s.rules_version = StringName(DictRead.get_string(d, "rules_version"))
	if s.schema_version != SCHEMA_VERSION or s.rules_version != RULES_VERSION:
		return null
	s.round_id = DictRead.get_string(d, "round_id")
	s.rng = SeededRng.from_dict(DictRead.get_dict(d, "rng"))
	if s.rng == null:
		return null
	s.phase = StringName(DictRead.get_string(d, "phase"))
	s.day_step = StringName(DictRead.get_string(d, "day_step"))
	if not Phase.ALL.has(s.phase) or not Phase.ALL_DAY_STEPS.has(s.day_step):
		return null
	s.night_number = DictRead.get_int(d, "night_number")
	s.day_number = DictRead.get_int(d, "day_number")

	for item: Variant in DictRead.get_array(d, "players"):
		if not item is Dictionary:
			return null
		var p := Player.from_dict(item)
		if p == null or s.players.has(p.id):
			return null
		s.players[p.id] = p
	var order: Variant = DictRead.to_int_array(DictRead.get_array(d, "seat_order"))
	if order == null:
		return null
	s.seat_order = order
	var sorted_order := s.seat_order.duplicate()
	sorted_order.sort()
	var ids: Array[int] = []
	ids.assign(s.players.keys())
	ids.sort()
	if sorted_order != ids:
		return null

	if d.get("pending_prompt") is Dictionary:
		s.pending_prompt = PendingPrompt.from_dict(d["pending_prompt"])
		if s.pending_prompt == null:
			return null
	s.pack_target_id = DictRead.get_int(d, "pack_target_id", NO_TARGET)
	for step: Variant in DictRead.get_array(d, "night_plan"):
		if not (step is String or step is StringName):
			return null
		s.night_plan.append(StringName(step))
	s.next_night_step = DictRead.get_int(d, "next_night_step")
	if s.next_night_step < 0 or s.next_night_step > s.night_plan.size():
		return null
	for item: Variant in DictRead.get_array(d, "reactions"):
		if not item is Dictionary:
			return null
		var r := Reaction.from_dict(item)
		if r == null:
			return null
		s.reactions.append(r)
	s.provisional_win = DictRead.get_array(d, "provisional_win").duplicate(true)
	s.win_check_pending = DictRead.get_bool(d, "win_check_pending")
	for item: Variant in DictRead.get_array(d, "nominations"):
		if not item is Dictionary:
			return null
		s.nominations.append(Nomination.from_dict(item))
	if d.get("win_candidate") is Dictionary:
		s.win_candidate = WinCandidate.from_dict(d["win_candidate"])
	if d.get("winner") is Dictionary:
		s.winner = WinCandidate.from_dict(d["winner"])
	s.command_count = DictRead.get_int(d, "command_count")
	var next_ids := DictRead.get_dict(d, "next_ids")
	s.next_event_index = DictRead.get_int(next_ids, "event", 1)
	s.next_prompt_id = DictRead.get_int(next_ids, "prompt", 1)
	s.next_candidate_id = DictRead.get_int(next_ids, "candidate", 1)
	s.next_death_order = DictRead.get_int(next_ids, "death_order", 1)
	s.next_reaction_id = DictRead.get_int(next_ids, "reaction", 1)
	return s
