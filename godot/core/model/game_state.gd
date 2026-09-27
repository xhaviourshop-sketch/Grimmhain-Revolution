class_name GameState
extends RefCounted
## Vollständiger fachlicher Spielzustand. Wird nur von RulesEngine verändert,
## und zwar immer auf einer Kopie (RulesEngine.apply ist für den Aufrufer rein).
## Anzeige- und Zeitwerte gehören nicht hierher (03 §6.3).

const SCHEMA_VERSION := 11  ## 2: Nachtplan, Reaktionen, vorläufiger Siegstatus; 3: Player.ability_uses; 4: Schutz, Schrittstatus; 5: Waldhexe (witch_actions, Prompt-Stufe); 6: Orakel (info_records, next_ids.info); 7: Trugbilderwolf (Pflicht-Scheinrolle, Setup appearances/role_entries); 8: Wolfskind (wolf_children); 9: Manipulator (ever_nominated, win_candidates, winner_id); 10: Lehrling (apprentices, next_ids.apprentice); 11: Rollenaudit (night_wolf_ids, death_seeker_wins)
const RULES_VERSION := &"grimmhain-core-0.11"
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
var night_step_status: Array[StringName] = []  ## je Nachtschritt: pending | done | skipped
var night_wolf_ids: Array[int] = []  ## wer bei StartNight als Wolf zählte (Rudel dieser Nacht), aufsteigend
var protections: Array[Protection] = []  ## bestätigte Schutzwahlen der laufenden Nacht
var witch_actions: Array[WitchAction] = []  ## bestätigte Waldhexen-Entscheidungen der laufenden Nacht
var info_records: Array[InfoRecord] = []    ## abgeschlossene Informationen der Partie (Orakel)
var wolf_children: Array[WolfChildBond] = []  ## je aktuellem Wolfskind: Vorbild und Verwandlung
var apprentices: Array[ApprenticeBond] = []   ## alle Bindungen von Lehrlingen (einzige Quelle), nach ID
var reactions: Array[Reaction] = []     ## offene Reaktionen, erste = nächste
var provisional_win: Array = []         ## vorläufiger Siegstatus seit dem letzten Tod (DR-14)
var win_check_pending: bool = false     ## verbindliche Siegprüfung steht aus (DR-14)
var nominations: Array[Nomination] = []
var win_candidates: Array[WinCandidate] = []  ## alle Siegkandidaten der Partie (einzige Quelle); offene haben Status `open`
var death_seeker_wins: Array[int] = []  ## Selbstmörder mit erfüllter Siegbedingung bei ihrer Hinrichtung, aufsteigend
var winner_id: int = -1                 ## ID des bestätigten Kandidaten oder −1
var command_count: int = 0              ## Anzahl angewandter Befehle
var next_event_index: int = 1
var next_prompt_id: int = 1
var next_candidate_id: int = 1
var next_death_order: int = 1
var next_reaction_id: int = 1
var next_info_id: int = 1
var next_apprentice_id: int = 1


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


## Offene Siegkandidaten in Erkennungsreihenfolge.
func open_candidates() -> Array[WinCandidate]:
	var out: Array[WinCandidate] = []
	for c: WinCandidate in win_candidates:
		if c.status == WinCandidate.STATUS_OPEN:
			out.append(c)
	return out


func candidate_by_id(candidate_id: int) -> WinCandidate:
	for c: WinCandidate in win_candidates:
		if c.id == candidate_id:
			return c
	return null


## Bestätigter Sieger oder null.
func winner() -> WinCandidate:
	return candidate_by_id(winner_id) if winner_id != -1 else null


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
	var candidate_list: Array = []
	for c: WinCandidate in win_candidates:
		candidate_list.append(c.to_dict())
	var plan: Array = []
	for step: StringName in night_plan:
		plan.append(String(step))
	var status_list: Array = []
	for status: StringName in night_step_status:
		status_list.append(String(status))
	var protection_list: Array = []
	for p: Protection in protections:
		protection_list.append(p.to_dict())
	var witch_list: Array = []
	for a: WitchAction in witch_actions:
		witch_list.append(a.to_dict())
	var wolf_list: Array = []
	for b: WolfChildBond in wolf_children:
		wolf_list.append(b.to_dict())
	var info_list: Array = []
	for r: InfoRecord in info_records:
		info_list.append(r.to_dict())
	var apprentice_list: Array = []
	for b: ApprenticeBond in apprentices:
		apprentice_list.append(b.to_dict())
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
		"night_wolf_ids": night_wolf_ids.duplicate(),
		"next_night_step": next_night_step,
		"night_step_status": status_list,
		"protections": protection_list,
		"witch_actions": witch_list,
		"info_records": info_list,
		"wolf_children": wolf_list,
		"apprentices": apprentice_list,
		"reactions": reaction_list,
		"provisional_win": provisional_win.duplicate(true),
		"win_check_pending": win_check_pending,
		"nominations": nomination_list,
		"win_candidates": candidate_list,
		"winner_id": winner_id,
		"death_seeker_wins": death_seeker_wins.duplicate(),
		"command_count": command_count,
		"next_ids": {
			"event": next_event_index,
			"prompt": next_prompt_id,
			"candidate": next_candidate_id,
			"death_order": next_death_order,
			"reaction": next_reaction_id,
			"info": next_info_id,
			"apprentice": next_apprentice_id,
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
	for status: Variant in DictRead.get_array(d, "night_step_status"):
		if not StepQueue.STEP_STATUSES.has(StringName(str(status))):
			return null
		s.night_step_status.append(StringName(str(status)))
	if s.night_step_status.size() != s.night_plan.size():
		return null
	var wolf_ids: Variant = DictRead.to_int_array(DictRead.get_array(d, "night_wolf_ids"))
	if wolf_ids == null:
		return null
	s.night_wolf_ids = wolf_ids
	var sorted_wolves := s.night_wolf_ids.duplicate()
	sorted_wolves.sort()
	if sorted_wolves != s.night_wolf_ids:
		return null
	for id: int in s.night_wolf_ids:
		if not s.players.has(id) or s.night_wolf_ids.count(id) > 1:
			return null
	for item: Variant in DictRead.get_array(d, "protections"):
		if not item is Dictionary:
			return null
		var protection := Protection.from_dict(item)
		if protection == null:
			return null
		s.protections.append(protection)
	for item: Variant in DictRead.get_array(d, "witch_actions"):
		if not item is Dictionary:
			return null
		var action := WitchAction.from_dict(item)
		if action == null:
			return null
		s.witch_actions.append(action)
	for item: Variant in DictRead.get_array(d, "info_records"):
		if not item is Dictionary:
			return null
		var record := InfoRecord.from_dict(item)
		if record == null or not s.players.has(record.oracle_id) or not s.players.has(record.target_id):
			return null
		s.info_records.append(record)
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
		var nomination := Nomination.from_dict(item)
		# Nominierungen verweisen nur auf bekannte Personen und vergangene oder laufende Tage.
		if not s.players.has(nomination.nominator_id) or not s.players.has(nomination.nominee_id) or nomination.day < 1 or nomination.day > s.day_number:
			return null
		s.nominations.append(nomination)
	# Todesquelle einer Person muss eine bekannte Person sein.
	for id: int in s.players:
		var death := s.players[id].death
		if death != null and death.source_kind == KillEvent.SOURCE_PLAYER and not s.players.has(death.source_id):
			return null
	for item: Variant in DictRead.get_array(d, "win_candidates"):
		if not item is Dictionary:
			return null
		var candidate := WinCandidate.from_dict(item)
		if candidate == null:
			return null
		s.win_candidates.append(candidate)
	s.winner_id = DictRead.get_int(d, "winner_id", -1)
	var seekers: Variant = DictRead.to_int_array(DictRead.get_array(d, "death_seeker_wins"))
	if seekers == null:
		return null
	s.death_seeker_wins = seekers
	var sorted_seekers := s.death_seeker_wins.duplicate()
	sorted_seekers.sort()
	if sorted_seekers != s.death_seeker_wins:
		return null
	for id: int in s.death_seeker_wins:
		if not s.players.has(id) or s.death_seeker_wins.count(id) > 1:
			return null
	for item: Variant in DictRead.get_array(d, "wolf_children"):
		if not item is Dictionary:
			return null
		var bond := WolfChildBond.from_dict(item)
		if bond == null:
			return null
		s.wolf_children.append(bond)
	if not WolfChildRules.state_is_consistent(s):
		return null
	if s.pending_prompt != null and s.pending_prompt.owner == PendingPrompt.OWNER_WOLF_CHILD and not WolfChildRules.matches_prompt(s, s.pending_prompt):
		return null
	for item: Variant in DictRead.get_array(d, "apprentices"):
		if not item is Dictionary:
			return null
		var apprentice := ApprenticeBond.from_dict(item)
		if apprentice == null:
			return null
		s.apprentices.append(apprentice)
	# Ein Waldhexen- oder Orakel-Prompt muss zum übrigen Zustand passen (matches_state).
	if s.pending_prompt != null and s.pending_prompt.owner == PendingPrompt.OWNER_WITCH and not WitchStep.matches_state(s, s.pending_prompt):
		return null
	if s.pending_prompt != null and s.pending_prompt.owner == PendingPrompt.OWNER_ORACLE and not OracleStep.matches_state(s, s.pending_prompt):
		return null
	s.command_count = DictRead.get_int(d, "command_count")
	var next_ids := DictRead.get_dict(d, "next_ids")
	s.next_event_index = DictRead.get_int(next_ids, "event", 1)
	s.next_prompt_id = DictRead.get_int(next_ids, "prompt", 1)
	s.next_candidate_id = DictRead.get_int(next_ids, "candidate", 1)
	s.next_death_order = DictRead.get_int(next_ids, "death_order", 1)
	s.next_reaction_id = DictRead.get_int(next_ids, "reaction", 1)
	s.next_info_id = DictRead.get_int(next_ids, "info", 1)
	s.next_apprentice_id = DictRead.get_int(next_ids, "apprentice", 1)
	# Bindungen und ein offener Auswahl-Prompt des Lehrlings müssen zum übrigen Zustand passen.
	if not ApprenticeRules.state_is_consistent(s):
		return null
	if s.pending_prompt != null and s.pending_prompt.owner == PendingPrompt.OWNER_APPRENTICE and not ApprenticeRules.matches_state(s, s.pending_prompt):
		return null
	if not WinRules.state_is_consistent(s):
		return null
	return s
