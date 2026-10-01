class_name CardSteps
extends RefCounted
## Eingabeketten der Totenreichkarten als Prompt des Besitzers `card` (PendingPrompt.OWNER_CARD).
## Zwei Arten (`partial.mode`):
##   play   Eine Karte wird im Kartenfenster gespielt. `partial`: {mode, record, window, inputs, spec}. Die Wirkung wird erst
##          nach der letzten Eingabe angewandt; Abbruch (CancelPrompt) lässt die Karte unverändert beim Besitzer.
##   task   Spätere Entscheidung der Spielleitung zu einer Karte (z. B. Zusatzopfer). `partial`: {mode, task, inputs, spec};
##          nicht abbrechbar, weil die Entscheidung Teil der Kartenwirkung ist.
## Stufen einer Eingabe (`spec.stage`):
##   pick     Personen aus `allowed` (min bis max)         Antwort: targets
##   option   eine Option aus `options` (Text-IDs)           Antwort: option (Index)
##   ask      Ja/Nein                                       Antwort: choice
##   roll     Würfel werfen (gespeicherter Generator)       Antwort: roll = true; danach Stufe `confirm` mit den Würfen
##   confirm  Hinweis zur Kenntnis nehmen                   Antwort: choice = true
## `spec.key` benennt die Eingabe in `inputs`; die Karte entscheidet über die nächste Stufe (CardEffects.next_stage).

const MODE_PLAY := "play"
const MODE_TASK := "task"
const STAGE_PICK := &"pick"
const STAGE_OPTION := &"option"
const STAGE_ASK := &"ask"
const STAGE_ROLL := &"roll"
const STAGE_CONFIRM := &"confirm"
const STAGES: Array[StringName] = [STAGE_PICK, STAGE_OPTION, STAGE_ASK, STAGE_ROLL, STAGE_CONFIRM]


# --- Start ------------------------------------------------------------------------------------------------

## Beginnt das Spielen der Karte `rec` im offenen Fenster: erste Eingabestufe oder sofortige Wirkung.
static func start_play(ctx: RuleContext, rec: Dictionary) -> void:
	var window := CardRules.window_kind(ctx.state)
	var spec := CardEffects.next_stage(ctx.state, rec, window, {})
	if spec.is_empty():
		finish_play(ctx, rec, {})
	else:
		_open(ctx, MODE_PLAY, {"record": int(rec["id"]), "window": String(window), "inputs": {}, "spec": spec}, int(rec["owner"]), spec, true)


static func finish_play(ctx: RuleContext, rec: Dictionary, inputs: Dictionary) -> void:
	var s := ctx.state
	var window := CardRules.window_kind(s)
	rec["status"] = CardRules.STATUS_PLAYED
	rec["must_play"] = false
	ctx.emit(GameEvent.CARD_PLAYED, Visibility.GM, {"owner_id": int(rec["owner"]), "card_id": rec["card"], "variant": rec["variant"], "record_id": rec["id"],
		"window": String(window), "inputs": inputs.duplicate(true)})
	CardEffects.apply(ctx, rec, window, inputs)
	CardRules.advance(ctx)


## Öffnet eine ausstehende Aufgabe der Spielleitung als Prompt oder wendet sie sofort an, wenn keine Eingabe nötig ist.
static func open_task(ctx: RuleContext, task: Dictionary) -> void:
	var spec := CardEffects.task_stage(ctx.state, task, {})
	if spec.is_empty():
		CardEffects.task_apply(ctx, task, {})
		return
	_open(ctx, MODE_TASK, {"task": task.duplicate(true), "inputs": {}, "spec": spec}, int(task["owner"]), spec, false)


static func _open(ctx: RuleContext, mode: String, partial: Dictionary, actor_id: int, spec: Dictionary, cancellable: bool) -> void:
	var s := ctx.state
	var prompt := PendingPrompt.new()
	prompt.id = s.next_prompt_id
	s.next_prompt_id += 1
	prompt.kind = PendingPrompt.KIND_PICK_PLAYERS
	prompt.owner = PendingPrompt.OWNER_CARD
	prompt.actor_id = actor_id
	prompt.cancellable = cancellable
	_shape(prompt, spec)
	partial["mode"] = mode
	prompt.partial = partial
	s.pending_prompt = prompt
	ctx.emit(GameEvent.PROMPT_OPENED, Visibility.GM, {"prompt": prompt.to_dict()})


## Prompt-Felder aus der Stufenbeschreibung.
static func _shape(prompt: PendingPrompt, spec: Dictionary) -> void:
	prompt.stage = StringName(spec["stage"])
	prompt.step_id = ""
	prompt.allowed_ids = []
	prompt.min_count = 0
	prompt.max_count = 0
	if prompt.stage == STAGE_PICK:
		var ids: Variant = DictRead.to_int_array(DictRead.get_array(spec, "allowed"))
		prompt.allowed_ids = ids if ids != null else []
		prompt.min_count = DictRead.get_int(spec, "min", 1)
		prompt.max_count = DictRead.get_int(spec, "max", 1)


# --- Antworten ----------------------------------------------------------------------------------------------

static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	var spec: Dictionary = DictRead.get_dict(prompt.partial, "spec")
	match prompt.stage:
		STAGE_PICK:
			var targets: Variant = DictRead.to_int_array(DictRead.get_array(p, "targets"))
			if targets == null or not p.get("targets") is Array:
				return &"invalid_target"
			var list: Array[int] = targets
			if list.size() < prompt.min_count or list.size() > prompt.max_count:
				return &"invalid_target_count"
			var seen: Array[int] = []
			for t: int in list:
				if not prompt.allowed_ids.has(t) or seen.has(t) or not s.players.has(t):
					return &"invalid_target"
				seen.append(t)
			if not CardEffects.check_pick(s, spec, list):
				return &"invalid_target_mix"  # z. B. Puppenspieler: jede Fraktion muss vertreten sein
		STAGE_OPTION:
			if not DictRead.is_int_like(p.get("option")) or int(p["option"]) < 0 or int(p["option"]) >= DictRead.get_array(spec, "options").size():
				return &"invalid_option"
		STAGE_ASK:
			if not p.get("choice") is bool:
				return &"invalid_answer"
		STAGE_ROLL:
			if p.get("roll") != true:
				return &"invalid_answer"
		STAGE_CONFIRM:
			if p.get("choice") != true:
				return &"invalid_answer"
	return &""


static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	var partial: Dictionary = prompt.partial
	var spec: Dictionary = partial["spec"]
	var inputs: Dictionary = (partial["inputs"] as Dictionary).duplicate(true)
	var key := String(spec["key"])
	match prompt.stage:
		STAGE_PICK:
			inputs[key] = DictRead.to_int_array(DictRead.get_array(p, "targets"))
			# Einzelwahlen (`*_id`) liefern die Person, Mehrfachwahlen (`targets`) immer eine Liste, auch mit nur einer Person.
			if key.ends_with("_id") and (inputs[key] as Array).size() == 1:
				inputs[key] = (inputs[key] as Array)[0]
		STAGE_OPTION:
			inputs[key] = String(DictRead.get_array(spec, "options")[int(p["option"])])
		STAGE_ASK:
			inputs[key] = bool(p["choice"])
		STAGE_ROLL:
			var count := DictRead.get_int(spec, "count", 1)
			var dice: Array = []
			for i: int in count:
				dice.append(s.rng.next_int(1, 6))
			ctx.emit(GameEvent.CARD_DICE_ROLLED, Visibility.PUBLIC, {"dice": dice.duplicate(), "owner_id": prompt.actor_id})
			# Stufe „Würfe zur Kenntnis nehmen“: Würfe sind gespeichert, ein erneutes Öffnen würfelt nie neu.
			partial["rolled"] = dice
			prompt.stage = STAGE_CONFIRM
			partial["spec"] = spec.duplicate(true)
			(partial["spec"] as Dictionary)["stage"] = String(STAGE_CONFIRM)
			(partial["spec"] as Dictionary)["rolled"] = true
			return
		STAGE_CONFIRM:
			if bool(spec.get("rolled", false)):
				inputs[key] = (partial["rolled"] as Array).duplicate()
			else:
				inputs[key] = true
	s.pending_prompt = null
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {"prompt_id": prompt.id, "owner": prompt.owner, "stage": String(prompt.stage), "input": inputs.get(key)})
	if String(partial["mode"]) == MODE_PLAY:
		var rec := CardRules.record_by_id(s, int(partial["record"]))
		var window := StringName(partial["window"])
		var next := CardEffects.next_stage(s, rec, window, inputs)
		if next.is_empty():
			finish_play(ctx, rec, inputs)
		else:
			_open(ctx, MODE_PLAY, {"record": int(rec["id"]), "window": String(window), "inputs": inputs, "spec": next}, int(rec["owner"]), next, true)
	else:
		var task: Dictionary = (partial["task"] as Dictionary).duplicate(true)
		var next_task := CardEffects.task_stage(s, task, inputs)
		if next_task.is_empty():
			CardEffects.task_apply(ctx, task, inputs)
		else:
			_open(ctx, MODE_TASK, {"task": task, "inputs": inputs, "spec": next_task}, int(task["owner"]), next_task, false)
	# Eine Morgenauflösung wartet auf die Entscheidung; sie endet erst, wenn nichts mehr offen ist.
	if s.phase == Phase.DAWN_RESOLUTION:
		RulesEngine.finish_dawn_if_ready(ctx)


# --- Ladeprüfung -----------------------------------------------------------------------------------------

## Der Prompt passt zum Zustand: Karte oder Aufgabe, Fenster, Stufe und Eingaben stimmen mit dem überein, was der Kern jetzt erwartet.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if not s.death_cards or prompt.kind != PendingPrompt.KIND_PICK_PLAYERS or not STAGES.has(prompt.stage) or prompt.step_id != "":
		return false
	var partial := prompt.partial
	var spec: Dictionary = DictRead.get_dict(partial, "spec")
	var inputs: Dictionary = DictRead.get_dict(partial, "inputs")
	if not s.players.has(prompt.actor_id) or StringName(DictRead.get_string(spec, "stage")) != prompt.stage or not spec.has("key"):
		return false
	var rolled_stage := prompt.stage == STAGE_CONFIRM and bool(spec.get("rolled", false))
	if rolled_stage != partial.has("rolled"):
		return false
	var expected: Dictionary
	var mode := DictRead.get_string(partial, "mode")
	if mode == MODE_PLAY:
		var rec := CardRules.record_by_id(s, DictRead.get_int(partial, "record", -1))
		var window := StringName(DictRead.get_string(partial, "window"))
		if rec.is_empty() or rec["status"] != CardRules.STATUS_HELD or int(rec["owner"]) != prompt.actor_id or not CardRules.window_open(s) \
				or CardRules.window_kind(s) != window or CardRules.current_owner(s) != prompt.actor_id or not prompt.cancellable:
			return false
		expected = CardEffects.next_stage(s, rec, window, inputs)
	elif mode == MODE_TASK:
		var task: Dictionary = DictRead.get_dict(partial, "task")
		if task.is_empty() or prompt.cancellable or not CardEffects.is_task_kind(String(task.get("kind", ""))):
			return false
		expected = CardEffects.task_stage(s, task, inputs)
	else:
		return false
	if rolled_stage:
		expected = expected.duplicate(true)
		expected["stage"] = String(STAGE_CONFIRM)
		expected["rolled"] = true
	if CanonicalJson.stringify(expected) != CanonicalJson.stringify(spec):
		return false
	var shape := PendingPrompt.new()
	_shape(shape, spec)
	return prompt.allowed_ids == shape.allowed_ids and prompt.min_count == shape.min_count and prompt.max_count == shape.max_count


## Wird ein Aufgaben-Prompt unterbrochen (Spielleiterkorrektur), kehrt die Aufgabe an den Anfang der Warteschlange zurück.
static func on_cancel(s: GameState, prompt: PendingPrompt) -> void:
	if prompt.owner == PendingPrompt.OWNER_CARD and DictRead.get_string(prompt.partial, "mode") == MODE_TASK:
		(s.cardsys["tasks"] as Array).push_front((prompt.partial["task"] as Dictionary).duplicate(true))
