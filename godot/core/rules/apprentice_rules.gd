class_name ApprenticeRules
extends RefCounted
## Lehrling / Apprentice (rules-register.md §9, DR-11): Mentorwahl, Bindung, Erbe.
## Auswahlbedarf ist zustandsbasiert: lebend, Rolle `lehrling`, ohne aktive Bindung. Jede
## solche Person erhält in ihrer ersten verfügbaren Nacht einen eigenen, nicht
## überspringbaren Schritt (Nachtpriorität 1.1), auch nach einem späteren Rollenwechsel.
## Einstufiger Prompt (DA-Nachtschritte-neu, Kartentext „wählt einen Mentor“): Der Spielleiter
## tippt für den Lehrling genau eine andere lebende Person als Mentor an; die Bindung gilt sofort.
## Ein Abbruch verwirft alles (kein Datensatz).
## Erbe: Stirbt der Mentor, übernimmt der Lehrling dessen Rolle. Unmittelbare Todesfolge in der
## KillPipeline (nach Wolfskind-Verwandlungen, vor der Todesreaktion des Meisters): Jeder lebende
## gebundene Lehrling des Toten übernimmt dessen aktuelle Rolle, stabil nach Personen-ID. Aktive
## Nachtfähigkeiten gelten erst ab der nächsten Nacht, weil der Nachtplan ein Snapshot ist.

const STAGE_MASTER := &"master"
const STAGES: Array[StringName] = [STAGE_MASTER]


## Aktive Bindung der Person oder null.
static func active_of(s: GameState, apprentice_id: int) -> ApprenticeBond:
	for b: ApprenticeBond in s.apprentices:
		if b.apprentice_id == apprentice_id and b.status == ApprenticeBond.STATUS_BOUND:
			return b
	return null


## Jüngster Datensatz der Person oder null.
static func latest_of(s: GameState, apprentice_id: int) -> ApprenticeBond:
	var found: ApprenticeBond = null
	for b: ApprenticeBond in s.apprentices:
		if b.apprentice_id == apprentice_id:
			found = b
	return found


## true, wenn die Person jetzt einen Meister wählen muss.
static func needs_selection(s: GameState, apprentice_id: int) -> bool:
	var p: Player = s.players.get(apprentice_id)
	return p != null and p.alive and p.role_id == RoleCatalog.LEHRLING and active_of(s, apprentice_id) == null


## Mindestens eine andere lebende Person als Mentor.
static func can_select(s: GameState, apprentice_id: int) -> bool:
	var others := s.alive_ids()
	others.erase(apprentice_id)
	return not others.is_empty()


## Beendet eine aktive Bindung (Tod des Lehrlings, Rollenwechsel, Korrektur).
static func end_active(s: GameState, apprentice_id: int, status: StringName) -> ApprenticeBond:
	var b := active_of(s, apprentice_id)
	if b != null:
		b.status = status
	return b


# --- Prompt ------------------------------------------------------------------------------------

static func open(s: GameState, prompt: PendingPrompt, apprentice_id: int) -> void:
	prompt.kind = PendingPrompt.KIND_APPRENTICE_CHAIN
	prompt.owner = PendingPrompt.OWNER_APPRENTICE
	prompt.actor_id = apprentice_id
	prompt.cancellable = true
	prompt.partial = {}
	prompt.stage = STAGE_MASTER
	prompt.allowed_ids = s.alive_ids()
	prompt.allowed_ids.erase(apprentice_id)
	prompt.min_count = 1
	prompt.max_count = 1


static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if p.has("choice") or p.has("option") or not p.get("targets") is Array:
		return &"invalid_answer"
	var targets: Variant = DictRead.to_int_array(p["targets"])
	if targets == null:
		return &"invalid_target"
	var list: Array[int] = targets
	if list.size() != 1:
		return &"invalid_target_count"
	# Nur eine zum Zeitpunkt der Antwort lebende andere Person.
	var t := list[0]
	if t == prompt.actor_id or not prompt.allowed_ids.has(t) or not s.players.has(t) or not s.players[t].alive:
		return &"invalid_target"
	return &""


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	var master_id: int = DictRead.to_int_array(p["targets"])[0]
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": STAGE_MASTER, "targets": [master_id]})
	var b := ApprenticeBond.new()
	b.apprentice_id = prompt.actor_id
	b.master_id = master_id
	b.options.append(String(s.players[master_id].role_id))
	b.option_person_ids.append(master_id)
	b.chosen_index = 0
	_add(ctx, b)
	ctx.emit(GameEvent.APPRENTICE_BOUND, Visibility.GM, b.to_dict())
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


## Neuer aktiver Datensatz (Nachtschritt oder Spielleiterkorrektur).
static func _add(ctx: RuleContext, b: ApprenticeBond) -> void:
	var s := ctx.state
	b.id = s.next_apprentice_id
	s.next_apprentice_id += 1
	b.status = ApprenticeBond.STATUS_BOUND
	b.bound_night = s.night_number
	b.bound_command = ctx.command_index
	s.apprentices.append(b)


## Spielleiterkorrektur: Bindung setzen oder ändern. Eine bestehende aktive Bindung wird
## ersetzt (`removed`); die neue hat genau eine Option, die aktuelle Rolle des Meisters.
static func set_master(ctx: RuleContext, apprentice_id: int, master_id: int) -> ApprenticeBond:
	end_active(ctx.state, apprentice_id, ApprenticeBond.STATUS_REMOVED)
	var b := ApprenticeBond.new()
	b.apprentice_id = apprentice_id
	b.master_id = master_id
	b.options.append(String(ctx.state.players[master_id].role_id))
	b.option_person_ids.append(master_id)
	b.chosen_index = 0
	_add(ctx, b)
	return b


# --- Tod und Erbe ------------------------------------------------------------------------------

## Tod des Lehrlings: Eine aktive Bindung verfällt endgültig (unabhängig von Todesfolgen).
static func on_own_death(s: GameState, dead_id: int) -> void:
	end_active(s, dead_id, ApprenticeBond.STATUS_EXPIRED)


## Unmittelbare Todesfolge beim Tod eines Meisters: alle lebenden gebundenen Lehrlinge erben,
## stabil nach Personen-ID.
static func on_master_death(ctx: RuleContext, record: KillEvent) -> void:
	var heirs: Array[ApprenticeBond] = []
	for b: ApprenticeBond in ctx.state.apprentices:
		if b.status == ApprenticeBond.STATUS_BOUND and b.master_id == record.target_id:
			heirs.append(b)
	heirs.sort_custom(func(a: ApprenticeBond, c: ApprenticeBond) -> bool: return a.apprentice_id < c.apprentice_id)
	for b: ApprenticeBond in heirs:
		var heir: Player = ctx.state.players.get(b.apprentice_id)
		if heir != null and heir.alive and heir.role_id == RoleCatalog.LEHRLING and not GuardRoles.silenced(ctx.state, heir.id):
			inherit(ctx, b, record.order_index, "master_death")


## Übernimmt die aktuelle Rolle des Meisters (bei Rollen mit Scheinrolle auch dessen
## Erscheinung). Einsätze der neuen Rolle beginnen frisch; ein verwandeltes Wolfskind wird
## unverwandelt ohne Vorbild geerbt.
static func inherit(ctx: RuleContext, b: ApprenticeBond, trigger_order: int, source: String) -> void:
	var s := ctx.state
	var heir := s.players[b.apprentice_id]
	var master := s.players[b.master_id]
	var from := heir.role_id
	b.snapshot = RoleTransition.snapshot_of(heir)
	b.status = ApprenticeBond.STATUS_INHERITED
	b.inherit_order = trigger_order
	b.inherit_command = ctx.command_index
	# Wächter am Tor: ein Erbe einer Wolfsrolle durch Tod des Meisters wird blockiert (nicht per Korrektur).
	if source == "master_death" and RoleCatalog.counts_as_wolf(master.role_id) and Gatewarden.active(s):
		b.inherited_role = RoleCatalog.DORFBEWOHNER
		Gatewarden.block(ctx, heir.id, master.role_id, "apprentice")
		return
	b.inherited_role = master.role_id
	RoleTransition.change_role(s, heir.id, master.role_id, master.appears_as, true)
	s.win_check_pending = true
	ctx.emit(GameEvent.ROLE_CHANGED, Visibility.GM, {
		"player_id": heir.id, "from": from, "to": master.role_id, "appears_as": heir.appears_as,
		"by": source, "master_id": master.id, "bond_id": b.id, "trigger_order": trigger_order,
	})


## Spielleiterkorrektur: Erbe exakt zurücknehmen; die Bindung wird wieder aktiv.
static func revert(s: GameState, b: ApprenticeBond) -> void:
	RoleTransition.restore(s, b.apprentice_id, b.snapshot)
	b.status = ApprenticeBond.STATUS_BOUND
	b.inherited_role = &""
	b.inherit_order = -1
	b.inherit_command = -1
	b.snapshot = {}


# --- Ladeprüfung -------------------------------------------------------------------------------

## Datensätze passen zu Personen und Rollen; höchstens eine aktive Bindung je Person.
static func state_is_consistent(s: GameState) -> bool:
	var active := {}
	var last_id := 0
	for b: ApprenticeBond in s.apprentices:
		if b.id <= last_id or b.id >= s.next_apprentice_id:
			return false
		last_id = b.id
		var heir: Player = s.players.get(b.apprentice_id)
		if heir == null or not s.players.has(b.master_id) or b.bound_night > s.night_number:
			return false
		for i: int in b.options.size():
			var person := b.option_person_ids[i]
			if not RoleCatalog.has_role(StringName(b.options[i])) or person == b.apprentice_id or not s.players.has(person):
				return false
			if b.option_person_ids.count(person) != 1 or (i > 0 and b.options[i - 1] > b.options[i]):
				return false
		match b.status:
			ApprenticeBond.STATUS_BOUND:
				if active.has(b.apprentice_id) or not heir.alive or heir.role_id != RoleCatalog.LEHRLING:
					return false
				active[b.apprentice_id] = true
			ApprenticeBond.STATUS_INHERITED:
				if not RoleCatalog.has_role(b.inherited_role) or not snapshot_is_valid(b.snapshot):
					return false
	return true


## Vor dem Erbe war die Person Lehrling; der Schnappschuss enthält genau die Rollenfelder.
static func snapshot_is_valid(snapshot: Dictionary) -> bool:
	if snapshot.size() != ApprenticeBond.SNAPSHOT_KEYS.size():
		return false
	for key: String in ApprenticeBond.SNAPSHOT_KEYS:
		if not snapshot.has(key):
			return false
	var role := StringName(str(snapshot["role_id"]))
	if role != RoleCatalog.LEHRLING or str(snapshot["faction"]) != String(RoleCatalog.faction_of(role)):
		return false
	if not snapshot["counts_as_wolf"] is bool or bool(snapshot["counts_as_wolf"]) != RoleCatalog.counts_as_wolf(role):
		return false
	if not snapshot["appears_as"] is String or not RoleCatalog.has_role(StringName(snapshot["appears_as"])) or not snapshot["ability_uses"] is Dictionary:
		return false
	var uses: Dictionary = snapshot["ability_uses"]
	for key: Variant in uses:
		if not RoleCatalog.ABILITY_USE_KEYS.has(String(key)) or not DictRead.is_int_like(uses[key]) or int(uses[key]) < 0 or int(uses[key]) > 1:
			return false
	return true


## Ein offener Auswahl-Prompt gehört zum erwarteten Schritt eines Lehrlings mit Auswahlbedarf.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if s.phase != Phase.NIGHT or s.next_night_step >= s.night_plan.size() or prompt.kind != PendingPrompt.KIND_APPRENTICE_CHAIN:
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step) or StepQueue.step_role(key) != RoleCatalog.LEHRLING:
		return false
	if StepQueue.step_actor(key) != prompt.actor_id or not needs_selection(s, prompt.actor_id) or not prompt.cancellable:
		return false
	var allowed := s.alive_ids()
	allowed.erase(prompt.actor_id)
	return prompt.stage == STAGE_MASTER and prompt.partial.is_empty() and prompt.allowed_ids == allowed and prompt.min_count == 1 and prompt.max_count == 1
