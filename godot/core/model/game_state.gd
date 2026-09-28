class_name GameState
extends RefCounted
## Vollständiger fachlicher Spielzustand. Wird nur von RulesEngine verändert,
## und zwar immer auf einer Kopie (RulesEngine.apply ist für den Aufrufer rein).
## Anzeige- und Zeitwerte gehören nicht hierher (03 §6.3).

const SCHEMA_VERSION := 11  ## 2: Nachtplan, Reaktionen, vorläufiger Siegstatus; 3: Player.ability_uses; 4: Schutz, Schrittstatus; 5: Waldhexe (witch_actions, Prompt-Stufe); 6: Orakel (info_records, next_ids.info); 7: Trugbilderwolf (Pflicht-Scheinrolle, Setup appearances/role_entries); 8: Wolfskind (wolf_children); 9: Manipulator (ever_nominated, win_candidates, winner_id); 10: Lehrling (apprentices, next_ids.apprentice); 11: Rollenaudit (night_wolf_ids, death_seeker_wins, judge_marks, parasite_hosts, Wolfsrollen-Zustand, Informations-, Schutz-, Bindungs-, Verwandlungs-, Wiederbelebungs- und Einzelsiegrollen)
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
var judge_marks: Array = []  ## Markierungen der Korrupten Richter dieser Nacht [{judge_id, target_id}], nach judge_id
var parasite_hosts: Array = []  ## aktive Wirte der Parasiten [{parasite_id, host_id}], nach parasite_id
var village_blocked: bool = false   ## Schattenhund: alle Dorf-Nachtschritte dieser Nacht blockiert
var blocked_ids: Array[int] = []    ## Albtraumwolf: blockierte Personen dieser Nacht
var wolf_poisons: Array = []        ## Giftwolf: [{target_id, source_id, due_night}]
var pack_bonus_pending: bool = false  ## Rudelvater gelyncht: nächste Nacht zweiter Rudelschritt
var pack_extra_target_id: int = NO_TARGET  ## Opfer des zweiten Rudelschritts dieser Nacht
var plague_pierce_pending: bool = false  ## Seuchenwolf tot: nächster Rudelangriff durchdringt Schutz
var growth: Dictionary = {}          ## Fenrir-Stufe bzw. Cerberus-Köpfe je Person-ID
var executions_count: int = 0        ## bestätigte Hinrichtungen der Partie (Henker)
var hangman_marks: Array = []        ## Markierungen der Henker dieser Nacht [{hangman_id, target_id}]
var bounty_credits: Dictionary = {}  ## Kopfgeldjäger: offene Listen je Person-ID (je Wolfs-Lynch eine)
var death_marks: Array = []          ## Tode am Morgen aus Nachtschritten [{target_id, source_id, cause}] (Kriegerin, Blutpriester)
var detective_hints: Array = []      ## nachts entstandene Detektiv-Hinweise [{anchor_id, direction}], öffentlich am Morgen
var eternal_finds: Array[int] = []   ## Die Ewigen: mit Ja geprüfte Personen, aufsteigend
var sage_curse_from: int = 0         ## Fluch des Weisen: erste betroffene Nacht- bzw. Tagesnummer (0 = kein Fluch)
var sage_curse_to: int = 0           ## letzte betroffene Nacht- bzw. Tagesnummer
var shields: Array = []              ## Schilde des Schutzgeists [{holder_id, source_id, night}], wirksam ab night + 1
var weapons: Array = []              ## Waffen des Dorfschmieds [{holder_id, smith_id}]
var martyr_saves: Array = []         ## Märtyrerin dieser Nacht [{martyr_id, victim_id}]
var doom_offers: Dictionary = {}     ## Verdammniswächter: gezogenes Angebot dieser Nacht je Wächter-ID
var ghost_alerts: int = 0            ## Schutzgeist hat in dieser Nacht einen Wolf gewählt (Anzahl, öffentlich am Morgen)
var loki_pairs: Array = []           ## Paare des Loki [{loki_id, a, b, kind: love|rival, ended}]
var shadow_links: Array = []         ## aktive Verknüpfungen [{walker_id, partner_id}]
var red_chains: Array = []           ## Todesketten [{red_id, partner_id}], je Rotkäppchen höchstens eine
var apples: Dictionary = {}          ## Apfel je Person-ID: Nacht, in der er gilt
var apple_steps: Array[int] = []     ## Indizes der durch einen Apfel eingefügten Nachtschritte dieser Nacht
var revived_tonight: Array[int] = []  ## in dieser Nacht durch Rollen Wiederbelebte, öffentlich am Morgen
var charms: Array = []                ## Rattenfänger: [{piper_id, target_id}]
var infected: Array[int] = []         ## Pestbringerin: infizierte Personen, aufsteigend
var prophet_marks: Array = []         ## Prophet des Untergangs: [{prophet_id, target_id}]
var prophet_unlocked: Array[int] = []  ## dauerhaft freigeschaltete Propheten, aufsteigend
var prophecies: Array = []            ## Todesprediger: [{preacher_id, kind: night|day, number}]
var preacher_wins: Array[int] = []    ## Todesprediger mit erfüllter Vorhersage, aufsteigend
var fire_marks: Array = []             ## Feuerteufel: [{devil_id, target_id}], höchstens eine je Feuerteufel, nach devil_id
var voodoo_dolls: Array = []           ## Voodoo-Priester: [{priest_id, doll_id}], höchstens eine lebende Puppe je Priester, nach priest_id
var necro_sacrificed: Array[int] = []  ## Nekromant: geopferte Tote (gemeinsamer Vorrat, jede Person einmal), aufsteigend
var necro_shields: Array = []          ## Nekromant: aktive Schilde [{necro_id, night}] in Errichtungsreihenfolge; enden mit der nächsten Nacht
var necro_named: Dictionary = {}       ## Nekromant: Tag des letzten Benennens je Person-ID
var necro_wins: Array[int] = []        ## Nekromanten mit Treffer beim Benennen, aufsteigend
var pack_redirect_from: int = -1       ## Nekromant, der den Rudelangriff dieser Nacht umgelenkt hat (Kette, E-20)
var pack_extra_redirect_from: int = -1  ## dasselbe für das Zusatzopfer des Rudelvaters
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


func _growth_to_dict() -> Dictionary:
	return _int_keys_to_dict(growth)


static func _int_keys_to_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for id: int in d:
		out[str(id)] = d[id]
	return out


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
	var d := {
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
		"judge_marks": judge_marks.duplicate(true),
		"parasite_hosts": parasite_hosts.duplicate(true),
		"village_blocked": village_blocked,
		"blocked_ids": blocked_ids.duplicate(),
		"wolf_poisons": wolf_poisons.duplicate(true),
		"pack_bonus_pending": pack_bonus_pending,
		"pack_extra_target_id": pack_extra_target_id,
		"plague_pierce_pending": plague_pierce_pending,
		"growth": _growth_to_dict(),
		"executions_count": executions_count,
		"hangman_marks": hangman_marks.duplicate(true),
		"bounty_credits": _int_keys_to_dict(bounty_credits),
		"death_marks": death_marks.duplicate(true),
		"detective_hints": detective_hints.duplicate(true),
		"eternal_finds": eternal_finds.duplicate(),
		"sage_curse_from": sage_curse_from,
		"sage_curse_to": sage_curse_to,
		"shields": shields.duplicate(true),
		"weapons": weapons.duplicate(true),
		"martyr_saves": martyr_saves.duplicate(true),
		"doom_offers": _int_keys_to_dict(doom_offers),
		"ghost_alerts": ghost_alerts,
		"loki_pairs": loki_pairs.duplicate(true),
		"shadow_links": shadow_links.duplicate(true),
		"red_chains": red_chains.duplicate(true),
		"apples": _int_keys_to_dict(apples),
		"apple_steps": apple_steps.duplicate(),
		"revived_tonight": revived_tonight.duplicate(),
		"charms": charms.duplicate(true),
		"infected": infected.duplicate(),
		"prophet_marks": prophet_marks.duplicate(true),
		"prophet_unlocked": prophet_unlocked.duplicate(),
		"prophecies": prophecies.duplicate(true),
		"preacher_wins": preacher_wins.duplicate(),
		"fire_marks": fire_marks.duplicate(true),
		"voodoo_dolls": voodoo_dolls.duplicate(true),
		"necro_sacrificed": necro_sacrificed.duplicate(),
		"necro_shields": necro_shields.duplicate(true),
		"necro_named": _int_keys_to_dict(necro_named),
		"necro_wins": necro_wins.duplicate(),
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
	}	# Umlenkung eines Rudelangriffs durch einen Nekromanten: nur in der laufenden Nacht vorhanden (E-17, E-20).
	if pack_redirect_from != -1:
		d["pack_redirect_from"] = pack_redirect_from
	if pack_extra_redirect_from != -1:
		d["pack_extra_redirect_from"] = pack_extra_redirect_from
	return d


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
	for item: Variant in DictRead.get_array(d, "judge_marks"):
		if not item is Dictionary:
			return null
		var judge := DictRead.get_int(item, "judge_id", -1)
		var marked := DictRead.get_int(item, "target_id", -1)
		if not s.players.has(judge) or not s.players.has(marked):
			return null
		s.judge_marks.append({"judge_id": judge, "target_id": marked})
	for item: Variant in DictRead.get_array(d, "parasite_hosts"):
		if not item is Dictionary:
			return null
		var parasite := DictRead.get_int(item, "parasite_id", -1)
		var host := DictRead.get_int(item, "host_id", -1)
		if not s.players.has(parasite) or not s.players.has(host) or parasite == host:
			return null
		s.parasite_hosts.append({"parasite_id": parasite, "host_id": host})
	s.village_blocked = DictRead.get_bool(d, "village_blocked")
	s.pack_bonus_pending = DictRead.get_bool(d, "pack_bonus_pending")
	s.plague_pierce_pending = DictRead.get_bool(d, "plague_pierce_pending")
	s.pack_extra_target_id = DictRead.get_int(d, "pack_extra_target_id", NO_TARGET)
	if s.pack_extra_target_id != NO_TARGET and not s.players.has(s.pack_extra_target_id):
		return null
	var blocked: Variant = DictRead.to_int_array(DictRead.get_array(d, "blocked_ids"))
	if blocked == null:
		return null
	s.blocked_ids = blocked
	for id: int in s.blocked_ids:
		if not s.players.has(id):
			return null
	for item: Variant in DictRead.get_array(d, "wolf_poisons"):
		if not item is Dictionary:
			return null
		var poisoned := DictRead.get_int(item, "target_id", -1)
		var source := DictRead.get_int(item, "source_id", -1)
		var due := DictRead.get_int(item, "due_night", -1)
		if not s.players.has(poisoned) or not s.players.has(source) or due < 1:
			return null
		s.wolf_poisons.append({"target_id": poisoned, "source_id": source, "due_night": due})
	var growth := DictRead.get_dict(d, "growth")
	for key: Variant in growth:
		if not String(key).is_valid_int() or not s.players.has(String(key).to_int()) or not DictRead.is_int_like(growth[key]) or int(growth[key]) < 0:
			return null
		s.growth[String(key).to_int()] = int(growth[key])
	s.executions_count = DictRead.get_int(d, "executions_count")
	if s.executions_count < 0:
		return null
	for item: Variant in DictRead.get_array(d, "hangman_marks"):
		if not item is Dictionary:
			return null
		var hangman := DictRead.get_int(item, "hangman_id", -1)
		var marked_by_hangman := DictRead.get_int(item, "target_id", -1)
		if not s.players.has(hangman) or not s.players.has(marked_by_hangman):
			return null
		s.hangman_marks.append({"hangman_id": hangman, "target_id": marked_by_hangman})
	var credits := DictRead.get_dict(d, "bounty_credits")
	for key: Variant in credits:
		if not String(key).is_valid_int() or not s.players.has(String(key).to_int()) or not DictRead.is_int_like(credits[key]) or int(credits[key]) < 1:
			return null
		s.bounty_credits[String(key).to_int()] = int(credits[key])
	for item: Variant in DictRead.get_array(d, "death_marks"):
		if not item is Dictionary:
			return null
		var marked_target := DictRead.get_int(item, "target_id", -1)
		var marked_source := DictRead.get_int(item, "source_id", -1)
		var mark_cause := StringName(DictRead.get_string(item, "cause"))
		if not s.players.has(marked_target) or not s.players.has(marked_source) or not [KillEvent.CAUSE_WARRIOR_WRONG, KillEvent.CAUSE_BLOOD_SACRIFICE, KillEvent.CAUSE_BLACK_WIDOW, KillEvent.CAUSE_PROPHET_KILL].has(mark_cause):
			return null
		s.death_marks.append({"target_id": marked_target, "source_id": marked_source, "cause": String(mark_cause)})
	for item: Variant in DictRead.get_array(d, "detective_hints"):
		if not item is Dictionary:
			return null
		var anchor := DictRead.get_int(item, "anchor_id", -1)
		var direction := DictRead.get_string(item, "direction")
		if not s.players.has(anchor) or not ["left", "right", "equal"].has(direction):
			return null
		s.detective_hints.append({"anchor_id": anchor, "direction": direction})
	var finds: Variant = DictRead.to_int_array(DictRead.get_array(d, "eternal_finds"))
	if finds == null:
		return null
	s.eternal_finds = finds
	var sorted_finds := s.eternal_finds.duplicate()
	sorted_finds.sort()
	if sorted_finds != s.eternal_finds:
		return null
	for id: int in s.eternal_finds:
		if not s.players.has(id) or s.eternal_finds.count(id) > 1:
			return null
	s.sage_curse_from = DictRead.get_int(d, "sage_curse_from")
	s.sage_curse_to = DictRead.get_int(d, "sage_curse_to")
	if s.sage_curse_from < 0 or s.sage_curse_to < 0 or (s.sage_curse_to > 0 and s.sage_curse_from > s.sage_curse_to):
		return null
	for item: Variant in DictRead.get_array(d, "shields"):
		var holder := DictRead.get_int(item, "holder_id", -1) if item is Dictionary else -1
		var spirit := DictRead.get_int(item, "source_id", -1) if item is Dictionary else -1
		if not s.players.has(holder) or not s.players.has(spirit) or DictRead.get_int(item, "night", -1) < 0:
			return null
		s.shields.append({"holder_id": holder, "source_id": spirit, "night": DictRead.get_int(item, "night")})
	for item: Variant in DictRead.get_array(d, "weapons"):
		var bearer := DictRead.get_int(item, "holder_id", -1) if item is Dictionary else -1
		var smith := DictRead.get_int(item, "smith_id", -1) if item is Dictionary else -1
		if not s.players.has(bearer) or not s.players.has(smith):
			return null
		s.weapons.append({"holder_id": bearer, "smith_id": smith})
	for item: Variant in DictRead.get_array(d, "martyr_saves"):
		var martyr := DictRead.get_int(item, "martyr_id", -1) if item is Dictionary else -1
		var saved := DictRead.get_int(item, "victim_id", -1) if item is Dictionary else -1
		if not s.players.has(martyr) or not s.players.has(saved) or martyr == saved:
			return null
		s.martyr_saves.append({"martyr_id": martyr, "victim_id": saved})
	var offers := DictRead.get_dict(d, "doom_offers")
	for key: Variant in offers:
		if not String(key).is_valid_int() or not s.players.has(String(key).to_int()) or not DictRead.is_int_like(offers[key]) or not s.players.has(int(offers[key])):
			return null
		s.doom_offers[String(key).to_int()] = int(offers[key])
	s.ghost_alerts = DictRead.get_int(d, "ghost_alerts")
	if s.ghost_alerts < 0:
		return null
	for item: Variant in DictRead.get_array(d, "loki_pairs"):
		if not item is Dictionary:
			return null
		var pair := {"loki_id": DictRead.get_int(item, "loki_id", -1), "a": DictRead.get_int(item, "a", -1), "b": DictRead.get_int(item, "b", -1),
			"kind": DictRead.get_string(item, "kind"), "ended": DictRead.get_bool(item, "ended")}
		if not s.players.has(int(pair["loki_id"])) or not s.players.has(int(pair["a"])) or not s.players.has(int(pair["b"])) or pair["a"] == pair["b"] or not ["love", "rival"].has(pair["kind"]):
			return null
		s.loki_pairs.append(pair)
	for item: Variant in DictRead.get_array(d, "shadow_links"):
		var walker := DictRead.get_int(item, "walker_id", -1) if item is Dictionary else -1
		var linked := DictRead.get_int(item, "partner_id", -1) if item is Dictionary else -1
		if not s.players.has(walker) or not s.players.has(linked) or walker == linked:
			return null
		s.shadow_links.append({"walker_id": walker, "partner_id": linked})
	for item: Variant in DictRead.get_array(d, "red_chains"):
		var red := DictRead.get_int(item, "red_id", -1) if item is Dictionary else -1
		var chained := DictRead.get_int(item, "partner_id", -1) if item is Dictionary else -1
		if not s.players.has(red) or not s.players.has(chained) or red == chained:
			return null
		s.red_chains.append({"red_id": red, "partner_id": chained})
	var apple_map := DictRead.get_dict(d, "apples")
	for key: Variant in apple_map:
		if not String(key).is_valid_int() or not s.players.has(String(key).to_int()) or not DictRead.is_int_like(apple_map[key]) or int(apple_map[key]) < 1:
			return null
		s.apples[String(key).to_int()] = int(apple_map[key])
	var extra_steps: Variant = DictRead.to_int_array(DictRead.get_array(d, "apple_steps"))
	if extra_steps == null:
		return null
	s.apple_steps = extra_steps
	for i: int in s.apple_steps:
		if i < 1 or i >= s.night_plan.size() or s.night_plan[i] != s.night_plan[i - 1]:
			return null
	var revived: Variant = DictRead.to_int_array(DictRead.get_array(d, "revived_tonight"))
	if revived == null:
		return null
	s.revived_tonight = revived
	for id: int in s.revived_tonight:
		if not s.players.has(id):
			return null
	for item: Variant in DictRead.get_array(d, "charms"):
		var piper := DictRead.get_int(item, "piper_id", -1) if item is Dictionary else -1
		var charmed := DictRead.get_int(item, "target_id", -1) if item is Dictionary else -1
		if not s.players.has(piper) or not s.players.has(charmed) or piper == charmed:
			return null
		s.charms.append({"piper_id": piper, "target_id": charmed})
	for key: String in ["necro_sacrificed", "necro_wins"]:
		var necro_ids: Variant = DictRead.to_int_array(DictRead.get_array(d, key))
		if necro_ids == null:
			return null
		var sorted_ids: Array[int] = (necro_ids as Array[int]).duplicate()
		sorted_ids.sort()
		for i: int in sorted_ids.size():
			if not s.players.has(sorted_ids[i]) or (i > 0 and sorted_ids[i] == sorted_ids[i - 1]):
				return null
		if sorted_ids != necro_ids:
			return null
		s.set(key, necro_ids)
	for item: Variant in DictRead.get_array(d, "necro_shields"):
		var necro := DictRead.get_int(item, "necro_id", -1) if item is Dictionary else -1
		var night := DictRead.get_int(item, "night", -1) if item is Dictionary else -1
		if not s.players.has(necro) or night != s.night_number or night < 1:
			return null
		if not s.players[necro].alive or s.players[necro].role_id != RoleCatalog.NEKROMANT:
			return null  # E-27: nur ein lebender Nekromant hält einen Schild
		s.necro_shields.append({"necro_id": necro, "night": night})
	var named := DictRead.get_dict(d, "necro_named")
	for key: Variant in named:
		if not String(key).is_valid_int() or not s.players.has(String(key).to_int()) or not DictRead.is_int_like(named[key]) or int(named[key]) < 1 or int(named[key]) > s.day_number:
			return null
		s.necro_named[String(key).to_int()] = int(named[key])
	for key: String in ["pack_redirect_from", "pack_extra_redirect_from"]:
		var from := DictRead.get_int(d, key, -1)
		if from != -1 and (not s.players.has(from) or s.players[from].role_id != RoleCatalog.NEKROMANT):
			return null
		s.set(key, from)
	for item: Variant in DictRead.get_array(d, "voodoo_dolls"):
		var priest := DictRead.get_int(item, "priest_id", -1) if item is Dictionary else -1
		var doll := DictRead.get_int(item, "doll_id", -1) if item is Dictionary else -1
		# E-13, E-14, E-22: lebender Priester mit der Rolle, lebende andere Puppe, eine je Priester, aufsteigend.
		if not s.players.has(priest) or not s.players.has(doll) or priest == doll:
			return null
		if not s.players[priest].alive or s.players[priest].role_id != RoleCatalog.VOODOO or not s.players[doll].alive:
			return null
		if not s.voodoo_dolls.is_empty() and int(s.voodoo_dolls[-1]["priest_id"]) >= priest:
			return null
		s.voodoo_dolls.append({"priest_id": priest, "doll_id": doll})
	for item: Variant in DictRead.get_array(d, "fire_marks"):
		var devil := DictRead.get_int(item, "devil_id", -1) if item is Dictionary else -1
		var burning := DictRead.get_int(item, "target_id", -1) if item is Dictionary else -1
		# E-06, E-10: lebender Feuerteufel mit der Rolle, lebendes anderes Ziel, eine Markierung je Feuerteufel, aufsteigend.
		if not s.players.has(devil) or not s.players.has(burning) or devil == burning:
			return null
		if not s.players[devil].alive or s.players[devil].role_id != RoleCatalog.FEUERTEUFEL or not s.players[burning].alive:
			return null
		if not s.fire_marks.is_empty() and int(s.fire_marks[-1]["devil_id"]) >= devil:
			return null
		s.fire_marks.append({"devil_id": devil, "target_id": burning})
	for item: Variant in DictRead.get_array(d, "prophet_marks"):
		var prophet := DictRead.get_int(item, "prophet_id", -1) if item is Dictionary else -1
		var marked_one := DictRead.get_int(item, "target_id", -1) if item is Dictionary else -1
		if not s.players.has(prophet) or not s.players.has(marked_one) or prophet == marked_one:
			return null
		s.prophet_marks.append({"prophet_id": prophet, "target_id": marked_one})
	for item: Variant in DictRead.get_array(d, "prophecies"):
		if not item is Dictionary:
			return null
		var preacher := DictRead.get_int(item, "preacher_id", -1)
		var phase_kind := DictRead.get_string(item, "kind")
		var phase_no := DictRead.get_int(item, "number", -1)
		if not s.players.has(preacher) or not ["night", "day"].has(phase_kind) or phase_no < 1:
			return null
		s.prophecies.append({"preacher_id": preacher, "kind": phase_kind, "number": phase_no})
	for key: String in ["infected", "prophet_unlocked", "preacher_wins"]:
		var listed: Variant = DictRead.to_int_array(DictRead.get_array(d, key))
		if listed == null:
			return null
		var sorted_ids := (listed as Array).duplicate()
		sorted_ids.sort()
		if sorted_ids != listed:
			return null
		for id: int in listed:
			if not s.players.has(id) or (listed as Array).count(id) > 1:
				return null
		s.set(key, listed)
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
	if s.pending_prompt != null and InfoSteps.OWNERS.has(s.pending_prompt.owner) and not InfoSteps.matches_state(s, s.pending_prompt):
		return null
	if s.pending_prompt != null and BondSteps.OWNERS.has(s.pending_prompt.owner) and not BondSteps.matches_state(s, s.pending_prompt):
		return null
	if s.pending_prompt != null and s.pending_prompt.owner == PendingPrompt.OWNER_APPRENTICE and not ApprenticeRules.matches_state(s, s.pending_prompt):
		return null
	if not WinRules.state_is_consistent(s):
		return null
	return s
