class_name OracleStep
extends RefCounted
## Nachtschritt des Orakels (rules-register.md §4, DR-07) als persistenter Prompt:
##   target  genau eine andere lebende Person wählen; dabei werden Wahrheit, ermitteltes
##           Ergebnis (InformationRules) und das zu zeigende Ergebnis im Prompt gespeichert
##   shown   „Gezeigt“ bestätigen; davor darf der Spielleiter per OverrideShownRole nur
##           das gezeigte Ergebnis übersteuern (Bestätigung und Begründung Pflicht)
## Erst „Gezeigt“ erzeugt den InfoRecord, das GM-Audit `InfoRecorded` und das Ereignis
## `InfoRevealed` für das Orakel, das nur das gezeigte Ergebnis enthält. Ein Abbruch
## verwirft Zielwahl und alle Werte. Keine Zufallsziehung.

const STAGE_TARGET := &"target"
const STAGE_SHOWN := &"shown"
const STAGES: Array[StringName] = [STAGE_TARGET, STAGE_SHOWN]


static func open(s: GameState, prompt: PendingPrompt, oracle_id: int) -> void:
	prompt.kind = PendingPrompt.KIND_ORACLE_CHECK
	prompt.owner = PendingPrompt.OWNER_ORACLE
	prompt.actor_id = oracle_id
	prompt.cancellable = true
	prompt.partial = {}
	_enter_target(s, prompt)


static func _enter_target(s: GameState, prompt: PendingPrompt) -> void:
	prompt.stage = STAGE_TARGET
	prompt.allowed_ids = s.alive_ids()
	prompt.allowed_ids.erase(prompt.actor_id)  # keine Selbstprüfung (DR-07)
	prompt.min_count = 1
	prompt.max_count = 1


# --- Antworten --------------------------------------------------------------------------------

static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if prompt.stage == STAGE_TARGET:
		if p.has("choice") or not p.get("targets") is Array:
			return &"invalid_answer"
		var targets: Variant = DictRead.to_int_array(p["targets"])
		if targets == null:
			return &"invalid_target"
		var list: Array[int] = targets
		if list.size() != 1:
			return &"invalid_target_count"
		var t := list[0]
		# Nur zum Zeitpunkt der Antwort lebende andere Personen.
		if t == prompt.actor_id or not prompt.allowed_ids.has(t) or not s.players.has(t) or not s.players[t].alive:
			return &"invalid_target"
		return &""
	if p.has("targets") or not (p.get("choice") is bool and bool(p["choice"])):
		return &"invalid_answer"  # „Gezeigt“ kennt nur Ja; zurück per CancelPrompt
	if CardHooks.false_info_pending(s, prompt.actor_id) and not DictRead.get_bool(prompt.partial, "overridden"):
		return &"false_info_required"  # Falsche Fährte (Dorf): erst die falsche Auskunft per Übersteuerung festlegen
	return &""


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	if prompt.stage == STAGE_SHOWN:
		_confirm(ctx)
		return
	var target := s.players[(DictRead.to_int_array(p["targets"]) as Array[int])[0]]
	var determined := InformationRules.determine_role(target)
	var cloaked := CardHooks.oracle_cloak(ctx, target)  # Schattenmantel / Schattenvorteil (Totenreichkarten)
	prompt.partial = {
		"target_id": target.id,
		"truth_role": String(target.role_id),
		"determined_role": String(determined),
		"shown_role": String(cloaked if cloaked != &"" else determined),
		"overridden": cloaked != &"" and cloaked != determined,
		"override_reason": "card" if cloaked != &"" and cloaked != determined else "",
	}
	prompt.stage = STAGE_SHOWN
	prompt.allowed_ids = []
	prompt.min_count = 0
	prompt.max_count = 0
	ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
		"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": STAGE_TARGET, "answer": {"targets": [target.id]}, "next_stage": STAGE_SHOWN,
	})


static func _confirm(ctx: RuleContext) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	var partial := prompt.partial
	CardHooks.consume_false_info(s, prompt.actor_id)
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": STAGE_SHOWN})
	var record := InfoRecord.new()
	record.id = s.next_info_id
	s.next_info_id += 1
	record.oracle_id = prompt.actor_id
	record.target_id = DictRead.get_int(partial, "target_id")
	record.night = s.night_number
	record.truth_role = StringName(DictRead.get_string(partial, "truth_role"))
	record.determined_role = StringName(DictRead.get_string(partial, "determined_role"))
	record.shown_role = StringName(DictRead.get_string(partial, "shown_role"))
	record.overridden = DictRead.get_bool(partial, "overridden")
	record.override_reason = DictRead.get_string(partial, "override_reason")
	record.command_index = ctx.command_index
	s.info_records.append(record)
	# Vollständiger Datensatz nur für den Spielleiter; das Orakel erhält ausschließlich das Gezeigte.
	ctx.emit(GameEvent.INFO_RECORDED, Visibility.GM, {"info": record.to_dict()})
	ctx.emit(GameEvent.INFO_REVEALED, Visibility.ACTOR, {
		"info_id": record.id, "night": record.night, "target_id": record.target_id, "shown_role": record.shown_role,
	}, record.oracle_id)
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1


# --- Übersteuerung des gezeigten Ergebnisses ---------------------------------------------------

## Nur bei offenem Orakel-Prompt in der Stufe „Gezeigt“. Bricht den Prompt nicht ab.
static func validate_override(s: GameState, p: Dictionary) -> StringName:
	var prompt := s.pending_prompt
	if not DictRead.is_int_like(p.get("prompt_id")) or int(p["prompt_id"]) != prompt.id:
		return &"prompt_mismatch"
	if prompt.owner != PendingPrompt.OWNER_ORACLE:
		return &"not_overridable"
	if prompt.stage != STAGE_SHOWN:
		return &"stage_mismatch"
	if not (p.get("confirmed") is bool and bool(p["confirmed"])):
		return &"confirmation_required"
	if DictRead.get_string(p, "reason").strip_edges() == "":
		return &"reason_required"
	var role := StringName(DictRead.get_string(p, "shown_role"))
	if not RoleCatalog.has_role(role):
		return &"unknown_role"
	if String(role) == DictRead.get_string(prompt.partial, "shown_role"):
		return &"no_change"
	return &""


## Ändert nur `shown_role`; Wahrheit und ermitteltes Ergebnis bleiben unverändert.
static func apply_override(ctx: RuleContext, p: Dictionary) -> void:
	var prompt := ctx.state.pending_prompt
	var old := DictRead.get_string(prompt.partial, "shown_role")
	var shown := DictRead.get_string(p, "shown_role")
	var reason := DictRead.get_string(p, "reason").strip_edges()
	var overridden := shown != DictRead.get_string(prompt.partial, "determined_role")
	prompt.partial["shown_role"] = shown
	prompt.partial["overridden"] = overridden
	prompt.partial["override_reason"] = reason if overridden else ""
	ctx.emit(GameEvent.INFO_OVERRIDDEN, Visibility.GM, {
		"prompt_id": prompt.id, "step_id": prompt.step_id, "old_shown_role": old, "new_shown_role": shown, "reason": reason,
	})


# --- Ladeprüfung -----------------------------------------------------------------------------

## Der Prompt gehört zum erwarteten Orakelschritt dieser Nacht, und gespeicherte Werte
## entsprechen dem aktuellen Zielzustand und der Informationsregel.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if s.phase != Phase.NIGHT or s.next_night_step >= s.night_plan.size() or prompt.kind != PendingPrompt.KIND_ORACLE_CHECK:
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step) or StepQueue.step_role(key) != RoleCatalog.ORAKEL:
		return false
	var oracle: Player = s.players.get(prompt.actor_id)
	if oracle == null or StepQueue.step_actor(key) != oracle.id or not oracle.alive or not SoloRules.acts_as(s, oracle.id, RoleCatalog.ORAKEL):
		return false
	if prompt.stage == STAGE_TARGET:
		var allowed := s.alive_ids()
		allowed.erase(oracle.id)
		return prompt.partial.is_empty() and prompt.allowed_ids == allowed and prompt.min_count == 1 and prompt.max_count == 1
	if prompt.stage != STAGE_SHOWN or not prompt.allowed_ids.is_empty():
		return false
	var partial := prompt.partial
	var target: Player = s.players.get(DictRead.get_int(partial, "target_id", -1))
	if target == null or target.id == oracle.id or not target.alive:
		return false
	if DictRead.get_string(partial, "truth_role") != String(target.role_id):
		return false
	var determined := DictRead.get_string(partial, "determined_role")
	if determined != String(InformationRules.determine_role(target)):
		return false
	var shown := StringName(DictRead.get_string(partial, "shown_role"))
	if not RoleCatalog.has_role(shown) or not partial.get("overridden") is bool or not partial.get("override_reason") is String:
		return false
	var overridden := bool(partial["overridden"])
	return overridden == (String(shown) != determined) and (not overridden or String(partial["override_reason"]).strip_edges() != "")
