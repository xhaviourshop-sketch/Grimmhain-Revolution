class_name WitchStep
extends RefCounted
## Nachtschritt der Waldhexe (rules-register.md §6, DR-06) als persistente, atomare
## Prompt-Kette. Beim Öffnen steht das aktuelle Rudelopfer im Prompt (`victim_id`,
## −1 = keins, nur die Personen-ID, keine Rolle). Stufen (`PendingPrompt.stage`):
##   heal           Heiltrank ja/nein (nur mit lebendem Rudelopfer und verfügbarem Heiltrank)
##   reveal         nach „ja“: Rolle des Opfers ist offengelegt, zur Kenntnis nehmen
##   poison         Gifttrank ja/nein (nur mit verfügbarem Gifttrank)
##   poison_target  Giftziel: jede lebende Person, auch die Waldhexe und das Rudelopfer
##   confirm        Zusammenfassung der Auswahl und finale Bestätigung
## Bis zur Bestätigung ändern Antworten nur `partial` und `stage` des Prompts; ein
## Abbruch verwirft alles. Erst `confirm` wendet in fester Reihenfolge an:
## Trankverbrauch und Rettung speichern → Giftziel über die KillPipeline töten →
## Schritt erledigt.

const HEAL := "heal"
const POISON := "poison"
const POTIONS: Array[String] = [HEAL, POISON]
const HEAL_USE_KEY := "waldhexe:heal"      ## Player.ability_uses, pro Person und Partie
const POISON_USE_KEY := "waldhexe:poison"

const STAGE_HEAL := &"heal"
const STAGE_REVEAL := &"reveal"
const STAGE_POISON := &"poison"
const STAGE_POISON_TARGET := &"poison_target"
const STAGE_CONFIRM := &"confirm"
const STAGES: Array[StringName] = [STAGE_HEAL, STAGE_REVEAL, STAGE_POISON, STAGE_POISON_TARGET, STAGE_CONFIRM]


# --- Tränke und Rudelopfer ---------------------------------------------------------------

static func potion_available(p: Player, potion: String) -> bool:
	return int(p.ability_uses.get(HEAL_USE_KEY if potion == HEAL else POISON_USE_KEY, 0)) == 0


## Markiert einen Trank als verfügbar (Eintrag entfernt) oder verbraucht (ein Einsatz).
static func set_potion_available(p: Player, potion: String, available: bool) -> void:
	var key := HEAL_USE_KEY if potion == HEAL else POISON_USE_KEY
	if available:
		p.ability_uses.erase(key)
	else:
		p.ability_uses[key] = 1


static func has_any_potion(p: Player) -> bool:
	return potion_available(p, HEAL) or potion_available(p, POISON)


## Heilbares Rudelopfer: die bestätigte Rudelwahl dieser Nacht, sofern die Person lebt.
static func victim_of(s: GameState) -> int:
	var id := s.pack_target_id
	return id if id != GameState.NO_TARGET and s.players.has(id) and s.players[id].alive else GameState.NO_TARGET


## true, wenn die lebende Waldhexe jetzt mindestens eine Entscheidung treffen kann.
static func has_decision(s: GameState, witch_id: int) -> bool:
	var p: Player = s.players.get(witch_id)
	if p == null or not p.alive:
		return false
	return (potion_available(p, HEAL) and victim_of(s) != GameState.NO_TARGET) or potion_available(p, POISON)


static func action_of(s: GameState, witch_id: int) -> WitchAction:
	for a: WitchAction in s.witch_actions:
		if a.witch_id == witch_id and a.night == s.night_number:
			return a
	return null


## true, wenn `player_id` in dieser Nacht vergiftet wurde (sicherer Tod am Morgen).
static func is_marked(s: GameState, player_id: int) -> bool:
	for a: WitchAction in s.witch_actions:
		if a.poison_used and a.poison_target_id == player_id and a.night == s.night_number:
			return true
	return false


## Morgenauflösung: Gifttode dieser Nacht nach Personen-ID der Waldhexe, über die normale
## Pipeline (Folgen, Reaktionen, Siegprüfung). Ein bereits totes Ziel wird ignoriert.
static func apply_poisons(ctx: RuleContext) -> void:
	var s := ctx.state
	for a: WitchAction in s.witch_actions:  # nach witch_id sortiert
		if a.poison_used and a.night == s.night_number:
			KillPipeline.request_kill(ctx, a.poison_target_id, KillEvent.CAUSE_WITCH_POISON, KillEvent.SOURCE_PLAYER, a.witch_id)


## Waldhexen-IDs, deren Rettung `target_id` in Nacht `night` gilt, aufsteigend.
static func rescuers_of(s: GameState, target_id: int, night: int) -> Array[int]:
	var ids: Array[int] = []
	for a: WitchAction in s.witch_actions:
		if a.saved_id == target_id and a.night == night:
			ids.append(a.witch_id)
	ids.sort()
	return ids


# --- Prompt-Kette ---------------------------------------------------------------------------

## Füllt einen neuen Prompt für den Schritt der Waldhexe `witch_id`.
static func open(s: GameState, prompt: PendingPrompt, witch_id: int) -> void:
	var witch := s.players[witch_id]
	var victim := victim_of(s)
	prompt.kind = PendingPrompt.KIND_WITCH_CHAIN
	prompt.owner = PendingPrompt.OWNER_WITCH
	prompt.actor_id = witch_id
	prompt.cancellable = true
	prompt.partial = {
		"victim_id": victim,
		"heal_offered": victim != GameState.NO_TARGET and potion_available(witch, HEAL),
		"poison_offered": potion_available(witch, POISON),
	}
	_enter_stage(s, prompt)


## Nächste offene Stufe allein aus den gespeicherten Teilantworten.
static func next_stage(partial: Dictionary) -> StringName:
	if DictRead.get_bool(partial, "heal_offered") and not partial.has("heal"):
		return STAGE_HEAL
	if DictRead.get_bool(partial, "heal") and not partial.has("role_seen"):
		return STAGE_REVEAL
	if DictRead.get_bool(partial, "poison_offered") and not partial.has("poison"):
		return STAGE_POISON
	if DictRead.get_bool(partial, "poison") and not partial.has("poison_target_id"):
		return STAGE_POISON_TARGET
	return STAGE_CONFIRM


## Ladeprüfung: Die gespeicherte Stufe passt zu den Teilantworten.
static func is_consistent(prompt: PendingPrompt) -> bool:
	var partial := prompt.partial
	if not DictRead.is_int_like(partial.get("victim_id")) or not partial.get("heal_offered") is bool or not partial.get("poison_offered") is bool:
		return false
	return prompt.kind == PendingPrompt.KIND_WITCH_CHAIN and prompt.stage == next_stage(partial)


## Ladeprüfung gegen den übrigen Zustand: Der Prompt gehört zum erwarteten Nachtschritt
## einer lebenden Waldhexe dieser Nacht, das gezeigte Opfer ist das aktuelle Rudelopfer,
## Auswahl und Giftziel passen zu den lebenden Personen.
static func matches_state(s: GameState, prompt: PendingPrompt) -> bool:
	if s.phase != Phase.NIGHT or s.next_night_step >= s.night_plan.size():
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step) or StepQueue.step_role(key) != RoleCatalog.WALDHEXE:
		return false
	var witch: Player = s.players.get(prompt.actor_id)
	if witch == null or StepQueue.step_actor(key) != witch.id or not witch.alive or SoloRules.ability_role(s, witch.id) != RoleCatalog.WALDHEXE:
		return false
	if DictRead.get_int(prompt.partial, "victim_id", -2) != victim_of(s):
		return false
	var alive := s.alive_ids()
	if prompt.partial.has("poison_target_id") and not alive.has(DictRead.get_int(prompt.partial, "poison_target_id", -1)):
		return false
	if prompt.stage == STAGE_POISON_TARGET:
		return prompt.allowed_ids == alive and prompt.min_count == 1 and prompt.max_count == 1
	return prompt.allowed_ids.is_empty()


static func _enter_stage(s: GameState, prompt: PendingPrompt) -> void:
	prompt.stage = next_stage(prompt.partial)
	if prompt.stage == STAGE_POISON_TARGET:
		prompt.allowed_ids = s.alive_ids()
		prompt.min_count = 1
		prompt.max_count = 1
	else:
		prompt.allowed_ids = []
		prompt.min_count = 0
		prompt.max_count = 0


## Prüft eine Antwort auf die aktuelle Stufe (nur lesend).
static func validate_answer(s: GameState, prompt: PendingPrompt, p: Dictionary) -> StringName:
	if DictRead.get_string(p, "stage") != String(prompt.stage):
		return &"stage_mismatch"
	if prompt.stage == STAGE_POISON_TARGET:
		if p.has("choice") or not p.get("targets") is Array:
			return &"invalid_answer"
		var targets: Variant = DictRead.to_int_array(p["targets"])
		if targets == null:
			return &"invalid_target"
		var list: Array[int] = targets
		if list.size() != 1:
			return &"invalid_target_count"
		if not prompt.allowed_ids.has(list[0]) or not s.players.has(list[0]) or not s.players[list[0]].alive:
			return &"invalid_target"
		return &""
	if p.has("targets") or not p.get("choice") is bool:
		return &"invalid_answer"
	# Offenlegung und Bestätigung kennen nur „ja“; zurück geht es per CancelPrompt.
	if (prompt.stage == STAGE_REVEAL or prompt.stage == STAGE_CONFIRM) and not bool(p["choice"]):
		return &"invalid_answer"
	if prompt.stage == STAGE_CONFIRM:
		var target := DictRead.get_int(prompt.partial, "poison_target_id", GameState.NO_TARGET)
		if target != GameState.NO_TARGET and not (s.players.has(target) and s.players[target].alive):
			return &"invalid_target"
	return &""


## Wendet eine (bereits validierte) Antwort an: Teilantwort speichern oder bestätigen.
static func answer(ctx: RuleContext, p: Dictionary) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	var answered := prompt.stage
	if answered == STAGE_CONFIRM:
		_confirm(ctx)
		return
	var recorded := {}
	match answered:
		STAGE_HEAL:
			prompt.partial["heal"] = bool(p["choice"])
			if bool(p["choice"]):
				# Rettet sie, erfährt sie zusätzlich die Rolle des Opfers (DR-06 d).
				prompt.partial["victim_role"] = String(s.players[int(prompt.partial["victim_id"])].role_id)
			recorded = {"choice": bool(p["choice"])}
		STAGE_REVEAL:
			prompt.partial["role_seen"] = true
			recorded = {"choice": true}
		STAGE_POISON:
			prompt.partial["poison"] = bool(p["choice"])
			recorded = {"choice": bool(p["choice"])}
		STAGE_POISON_TARGET:
			var target: int = (DictRead.to_int_array(p["targets"]) as Array[int])[0]
			prompt.partial["poison_target_id"] = target
			recorded = {"targets": [target]}
	_enter_stage(s, prompt)
	ctx.emit(GameEvent.PROMPT_STAGE_ANSWERED, Visibility.GM, {
		"prompt_id": prompt.id, "step_id": prompt.step_id, "stage": answered, "answer": recorded, "next_stage": prompt.stage,
	})


## Finale Bestätigung: alle gewählten Wirkungen in fester Reihenfolge.
static func _confirm(ctx: RuleContext) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	var partial := prompt.partial
	var witch := s.players[prompt.actor_id]
	ctx.emit(GameEvent.PROMPT_ANSWERED, Visibility.GM, {
		"prompt_id": prompt.id, "owner": prompt.owner, "stage": STAGE_CONFIRM, "decision": partial,
	})
	# 1. Trankverbrauch und Rettung speichern.
	var action := WitchAction.new()
	action.witch_id = witch.id
	action.night = s.night_number
	action.victim_id = DictRead.get_int(partial, "victim_id", GameState.NO_TARGET)
	action.heal_used = DictRead.get_bool(partial, "heal")
	action.saved_id = action.victim_id if action.heal_used else GameState.NO_TARGET
	action.poison_used = DictRead.get_bool(partial, "poison")
	action.poison_target_id = DictRead.get_int(partial, "poison_target_id", GameState.NO_TARGET)
	if action.heal_used:
		witch.ability_uses[HEAL_USE_KEY] = int(witch.ability_uses.get(HEAL_USE_KEY, 0)) + 1
	if action.poison_used:
		witch.ability_uses[POISON_USE_KEY] = int(witch.ability_uses.get(POISON_USE_KEY, 0)) + 1
	s.witch_actions.append(action)
	s.witch_actions.sort_custom(func(a: WitchAction, b: WitchAction) -> bool: return a.witch_id < b.witch_id)
	var data := action.to_dict()
	data["saved_role"] = DictRead.get_string(partial, "victim_role") if action.heal_used else ""
	ctx.emit(GameEvent.WITCH_ACTED, Visibility.GM, data)
	# 2. Gift ist eine Todesmarkierung (Decision Log „Nachttode“): Tod erst in der Morgenauflösung
	#    (`apply_poisons`), die Person verliert aber sofort ihre übrigen Nachtschritte (`is_marked`).
	# 3. Schritt erledigt.
	s.night_step_status[s.next_night_step] = StepQueue.STATUS_DONE
	s.next_night_step += 1
