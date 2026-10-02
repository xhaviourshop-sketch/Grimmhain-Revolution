class_name ExecutionRules
extends RefCounted
## Zentrale Hinrichtungsauflösung (DR-03, DR-13). Reguläres `DecideExecution` und
## `GmCorrection execute` nutzen dieselbe reine Vorschau und dieselbe Ausführung; getötet
## wird ausschließlich über die KillPipeline. Die Umleitung wird nicht gespeichert, nur
## ihr Verbrauch (`Player.ability_uses`) und ihre Ereignisse.
##
## Spiegelwolf: Die erste bestätigte Hinrichtung (Ursache LYNCH) wird auf die Person
## umgeleitet, die ihn an diesem Tag nominiert hat, sofern sie lebt. Diese stirbt mit
## `SPIEGELWOLF_RETALIATE`, Quelle Spiegelwolf; er überlebt, die Spiegelung ist verbraucht.
## Selbstnominierung: Todesziel ist er selbst, genau ein Tod, keine zweite Prüfung.
## Sonst (verbraucht, keine passende Nominierung, nominierende Person tot oder unbekannt)
## stirbt er normal mit `LYNCH` und verbraucht nichts.

const MIRROR_USE_KEY := "spiegelwolf:mirror"  ## Player.ability_uses, einmal pro Person und Partie
const REASON_MIRRORED := "mirrored"
const REASON_NOT_MIRROR_WOLF := "not_mirror_wolf"
const REASON_MIRROR_USED := "mirror_used"
const REASON_NO_NOMINATION := "no_nomination"
const REASON_NOMINATOR_DEAD := "nominator_dead"


static func mirror_available(p: Player) -> bool:
	return int(p.ability_uses.get(MIRROR_USE_KEY, 0)) == 0


## Reine Vorschau der Hinrichtung von `target_id` (ändert nichts). Felder: target_id,
## death_target_id, cause, source_kind, source_id, redirected, nominator_id, reason.
static func preview(s: GameState, target_id: int, source_kind: StringName) -> Dictionary:
	var cards := s.death_cards and source_kind != KillEvent.SOURCE_GM
	# Stimmenkarten (Stimmentausch, Spiegelwelt): die Stimmen zählen für die Person links; sie ist dann das Ziel der Hinrichtung.
	var effective := CardLynch.vote_target(s, target_id) if cards else target_id
	var result := {
		"target_id": target_id, "death_target_id": effective, "cause": String(KillEvent.CAUSE_LYNCH),
		"source_kind": String(source_kind), "source_id": -1, "redirected": false, "nominator_id": -1,
		"reason": REASON_NOT_MIRROR_WOLF, "random_wolf": false, "card_reason": "shifted" if effective != target_id else "",
	}
	var target: Player = s.players.get(effective)
	if target != null and target.role_id == RoleCatalog.SPIEGELWOLF:
		if not mirror_available(target):
			result["reason"] = REASON_MIRROR_USED
		else:
			var nominator := -1
			for n: Nomination in s.nominations_on_day(s.day_number):
				if n.nominee_id == effective:
					nominator = n.nominator_id
					break
			if nominator == -1:
				result["reason"] = REASON_NO_NOMINATION
			else:
				result["nominator_id"] = nominator
				if not s.players.has(nominator) or not s.players[nominator].alive:
					result["reason"] = REASON_NOMINATOR_DEAD
				else:
					result["death_target_id"] = nominator
					result["cause"] = String(KillEvent.CAUSE_SPIEGELWOLF_RETALIATE)
					result["source_kind"] = String(KillEvent.SOURCE_PLAYER)
					result["source_id"] = effective
					result["redirected"] = true
					result["reason"] = REASON_MIRRORED
	if cards:
		var red := CardLynch.redirect(s, target_id, int(result["death_target_id"]), bool(result["redirected"]))
		result["death_target_id"] = red["death_target_id"]
		result["random_wolf"] = red["random_wolf"]
		if String(red["reason"]) != "":
			result["card_reason"] = red["reason"]
	return result


## true, wenn die Hinrichtung von `target_id` eine Entscheidung „abwehren?“ verlangt (Cerberus mit 3 Köpfen).
static func needs_cerberus_decision(s: GameState, target_id: int) -> bool:
	var p: Player = s.players.get(target_id)
	return p != null and p.alive and p.role_id == RoleCatalog.CERBERUS and int(s.growth.get(target_id, 0)) >= RoleCatalog.CERBERUS_MAX_HEADS


## Führt die (bereits bestätigte) Hinrichtung nach der Vorschau aus. Zählt jede Hinrichtung (Henker),
## lässt Cerberus bei Wunsch abwehren und vollzieht danach Henker-Markierungen.
static func execute(ctx: RuleContext, target_id: int, source_kind: StringName, cerberus_defend: bool = false, sage_curse: int = 0, payload: Dictionary = {}) -> void:
	var s := ctx.state
	var cards := s.death_cards and source_kind != KillEvent.SOURCE_GM
	# Verhinderung durch eine Karte (Verzweiflungsschrei, Gerechter Zorn): keine Hinrichtung, kein Tod, kein Ersatz.
	if cards and CardLynch.prevented(ctx, int(preview(s, target_id, source_kind)["death_target_id"])):
		return
	s.executions_count += 1
	if cerberus_defend and needs_cerberus_decision(s, target_id):
		s.growth[target_id] = 0
		ctx.emit(GameEvent.EXECUTION_DEFENDED, Visibility.GM, {"target_id": target_id, "by": String(RoleCatalog.CERBERUS), "day": s.day_number})
		_hangman_extras(ctx)
		return
	var sage := GuardRoles.needs_sage_decision(s, target_id)  # vor dem Verbrauch einer Spiegelung
	var r := preview(s, target_id, source_kind)
	var target: Player = s.players[target_id]
	if bool(r["redirected"]):
		target.ability_uses[MIRROR_USE_KEY] = 1
		ctx.emit(GameEvent.EXECUTION_REDIRECTED, Visibility.GM, {
			"target_id": target_id, "death_target_id": r["death_target_id"], "nominator_id": r["nominator_id"],
			"mirror_wolf_id": target_id, "mirror_used": true,
		})
	elif target.role_id == RoleCatalog.SPIEGELWOLF:
		ctx.emit(GameEvent.MIRROR_NOT_TRIGGERED, Visibility.GM, {
			"target_id": target_id, "nominator_id": r["nominator_id"], "reason": r["reason"],
		})
	var death_id := int(r["death_target_id"])
	if bool(r.get("random_wolf", false)):
		# Schicksalswende (Dorf): das Urteil trifft einen zufälligen Wolf (gespeicherter Generator).
		var wolf := CardEffects.random_of(s, CardEffects.living_of_variant(s, CardCatalog.WOLF))
		for e: Dictionary in CardLynch.for_today(s, "lynch_redirect_wolf"):
			CardEffects.remove_effect(s, int(e["id"]))
		ctx.emit(GameEvent.CARD_EFFECT_NOTE, Visibility.GM, {"card_id": "wende_11", "execution_target_id": target_id, "redirected_to": wolf})
		death_id = wolf
	if cards and String(r.get("card_reason", "")) == "swap_nominator":
		for e: Dictionary in CardLynch.for_today(s, "lynch_swap_nominator"):
			CardEffects.remove_effect(s, int(e["id"]))
	var record := KillPipeline.request_kill(ctx, death_id, StringName(r["cause"]), StringName(r["source_kind"]), int(r["source_id"]))
	if sage and record != null:
		GuardRoles.start_curse(ctx, record.target_id, sage_curse)
	if cards:
		CardLynch.after_execution(ctx, payload, record)
	_hangman_extras(ctx)


## Henker (RM-DR-130): Markierte sterben bei der Hinrichtung des Tages mit, wenn ihr Henker jetzt lebt.
static func _hangman_extras(ctx: RuleContext) -> void:
	var s := ctx.state
	var marks := s.hangman_marks.duplicate()
	s.hangman_marks.clear()
	for mark: Dictionary in marks:
		var hangman: Player = s.players[int(mark["hangman_id"])]
		if hangman.alive and SoloRules.has_ability(s, hangman.id, RoleCatalog.HENKER) and not GuardRoles.silenced(s, hangman.id):
			KillPipeline.request_kill(ctx, int(mark["target_id"]), KillEvent.CAUSE_HANGMAN_EXTRA, KillEvent.SOURCE_PLAYER, hangman.id)
