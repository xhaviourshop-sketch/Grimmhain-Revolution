class_name WolfChildRules
extends RefCounted
## Wolfskind (rules-register.md §8, DR-10): Vorbildwahl, Verwandlung, Ladeprüfung.
## Auswahlbedarf ist zustandsbasiert: lebend, Rolle `wolfskind`, unverwandelt, ohne Vorbild.
## Die Verwandlung ist eine unmittelbare Todesfolge ohne Entscheidung: Sie geschieht in der
## KillPipeline direkt nach dem Tod des Vorbilds und vor der vorläufigen Siegprüfung.


static func bond_of(s: GameState, child_id: int) -> WolfChildBond:
	for b: WolfChildBond in s.wolf_children:
		if b.child_id == child_id:
			return b
	return null


## true, wenn die Person jetzt ein Vorbild wählen muss.
static func needs_model(s: GameState, child_id: int) -> bool:
	var p: Player = s.players.get(child_id)
	var b := bond_of(s, child_id)
	return p != null and p.alive and p.role_id == RoleCatalog.WOLFSKIND and b != null and not b.transformed and b.model_id == -1


## Neuer, unverwandelter Zustand ohne Vorbild (Spielaufbau, `set_role`).
static func create_bond(s: GameState, child_id: int) -> void:
	remove_bond(s, child_id)
	var b := WolfChildBond.new()
	b.child_id = child_id
	s.wolf_children.append(b)
	s.wolf_children.sort_custom(func(a: WolfChildBond, c: WolfChildBond) -> bool: return a.child_id < c.child_id)
	set_fields(s.players[child_id], false)


static func remove_bond(s: GameState, child_id: int) -> void:
	var b := bond_of(s, child_id)
	if b != null:
		s.wolf_children.erase(b)


## Rollenfelder passend zum Verwandlungszustand; `role_id` bleibt `wolfskind`.
static func set_fields(p: Player, transformed: bool) -> void:
	p.faction = Faction.WOLVES if transformed else Faction.VILLAGE
	p.counts_as_wolf = transformed
	p.appears_as = RoleCatalog.WERWOLF if transformed else RoleCatalog.WOLFSKIND


static func fields_match(p: Player, transformed: bool) -> bool:
	return p.faction == (Faction.WOLVES if transformed else Faction.VILLAGE) and p.counts_as_wolf == transformed \
		and p.appears_as == (RoleCatalog.WERWOLF if transformed else RoleCatalog.WOLFSKIND)


## Bestätigte Vorbildwahl im eigenen Nachtschritt.
static func bind(ctx: RuleContext, child_id: int, model_id: int) -> void:
	var s := ctx.state
	var b := bond_of(s, child_id)
	b.model_id = model_id
	b.bound_night = s.night_number
	b.bound_command = ctx.command_index
	ctx.emit(GameEvent.WOLF_CHILD_BOUND, Visibility.GM, {"child_id": child_id, "model_id": model_id, "night": s.night_number})


## Verwandelt atomar: Fraktion, Wolfszählung und Erscheinung gemeinsam.
static func transform(ctx: RuleContext, b: WolfChildBond, trigger_order: int, source: String) -> void:
	b.transformed = true
	b.transform_order = trigger_order
	b.transform_command = ctx.command_index
	set_fields(ctx.state.players[b.child_id], true)
	ctx.emit(GameEvent.WOLF_CHILD_TRANSFORMED, Visibility.GM, {
		"child_id": b.child_id, "model_id": b.model_id, "trigger_order": trigger_order, "source": source,
	})


static func revert(b: WolfChildBond, p: Player) -> void:
	b.transformed = false
	b.transform_order = -1
	b.transform_command = -1
	set_fields(p, false)


## Unmittelbare Todesfolge: Alle lebenden, unverwandelten Wolfskinder mit diesem Vorbild
## verwandeln sich, stabil nach Personen-ID. Tote Wolfskinder werden ausgelassen und
## verwandeln sich für diesen Tod auch später nicht.
static func on_death(ctx: RuleContext, record: KillEvent) -> void:
	var s := ctx.state
	var blocked: Array[int] = []
	for b: WolfChildBond in s.wolf_children:  # nach child_id sortiert
		var child: Player = s.players.get(b.child_id)
		if b.model_id == record.target_id and not b.transformed and child != null and child.alive and child.role_id == RoleCatalog.WOLFSKIND and not GuardRoles.silenced(s, child.id):
			if Gatewarden.active(s):
				blocked.append(b.child_id)
			else:
				transform(ctx, b, record.order_index, "model_death")
	# Wächter am Tor: nach der Schleife, weil der Rollenwechsel den Wolfskind-Datensatz entfernt.
	for id: int in blocked:
		Gatewarden.block(ctx, id, RoleCatalog.WERWOLF, "wolf_child")


# --- Ladeprüfung ---------------------------------------------------------------------------------

## Genau ein Datensatz je aktuellem Wolfskind, gültiges Vorbild, Rollenfelder passend.
static func state_is_consistent(s: GameState) -> bool:
	var seen := {}
	for b: WolfChildBond in s.wolf_children:
		var p: Player = s.players.get(b.child_id)
		if seen.has(b.child_id) or p == null or p.role_id != RoleCatalog.WOLFSKIND:
			return false
		seen[b.child_id] = true
		if b.model_id != -1 and (not s.players.has(b.model_id) or b.model_id == b.child_id):
			return false
		if b.bound_night > s.night_number or not fields_match(p, b.transformed):
			return false
	for id: int in s.players:
		if s.players[id].role_id == RoleCatalog.WOLFSKIND and not seen.has(id):
			return false
	return true


## Ein offener Auswahl-Prompt gehört zum erwarteten Schritt eines Wolfskinds mit Auswahlbedarf.
static func matches_prompt(s: GameState, prompt: PendingPrompt) -> bool:
	if s.phase != Phase.NIGHT or s.next_night_step >= s.night_plan.size():
		return false
	var key := s.night_plan[s.next_night_step]
	if prompt.step_id != StepQueue.night_step_id(s, s.next_night_step) or StepQueue.step_role(key) != RoleCatalog.WOLFSKIND:
		return false
	if StepQueue.step_actor(key) != prompt.actor_id or not needs_model(s, prompt.actor_id):
		return false
	var allowed := s.alive_ids()
	allowed.erase(prompt.actor_id)
	return prompt.kind == PendingPrompt.KIND_PICK_PLAYERS and prompt.stage == &"" and prompt.partial.is_empty() \
		and prompt.allowed_ids == allowed and prompt.min_count == 1 and prompt.max_count == 1
