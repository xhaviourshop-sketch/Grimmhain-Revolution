class_name ActionCard
extends VBoxContainer
## Ansagekarte des Cockpits (02 §6): baut für die nächste Handlung aus `CockpitView.next_action`
## Kontext, Vorlesetext („Sag jetzt“), Anweisung („Tu jetzt“), Auswahl und Aktionen. Ein Baustein
## für alle Prompt-Arten (Personen, Ja/Nein, Bestätigen, Option, Zeitpunkt). Reine Darstellung:
## Jede Aktion wird über `requested(action, payload)` gemeldet; die Ansicht sendet den Befehl.
##
## Geheime Karten (`secret`) zeigt die Karte außerhalb der Nacht verdeckt, bis `revealed` gesetzt
## ist. Verdeckt entstehen keine Knoten mit geheimem Inhalt.

signal requested(action: StringName, payload: Dictionary)

var _busy: bool = false
var _last_next: Dictionary = {}
var _last_context: Dictionary = {}
var _fade: Tween = null
var _shown_kind: String = ""


## Sprachwechsel: Karte mit denselben Daten neu aufbauen (zusammengesetzte Texte).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _last_next.is_empty() and is_inside_tree():
		render.call_deferred(_last_next, _last_context)


## Baut die Karte neu. `context` = {phase, seats, selection, revealed, night_number, day_number}.
func render(next: Dictionary, context: Dictionary) -> void:
	_last_next = next
	_last_context = context
	_busy = false
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var kind := str(next.get("kind", "none"))
	if str(context.get("error_key", "")) != "":
		_text(str(context["error_key"]), {}, &"ErrorLabel").name = "ErrorLabel"
	if bool(next.get("secret", false)) and not bool(context.get("revealed", false)) and str(context.get("phase")) != "NIGHT":
		_covered(kind)
		return
	_fade_in(kind + str(next.get("prompt_id", "")) + str(next.get("stage", "")) + str(next.get("step_id", "")), bool(context.get("reduced_motion", false)))
	match kind:
		"start_night":
			_start_night(next, context)
		"begin_step":
			_begin_step(next, context)
		"prompt":
			_prompt(next, context)
		"notice":
			_notice(next)
		"end_night":
			_end_night(next)
		"morning":
			_morning(next)
		"gm":
			_gm(context)
		"day":
			_day(next, context)
		"end_day":
			_end_day(next, context)
		"win_decision":
			_win_decision(next)
		"game_over":
			_game_over(next)
		"no_game":
			_heading("ui.cockpit.instruction.heading")
			_text("ui.cockpit.instruction.no_game", {}, &"MutedLabel")
		_:
			_heading("ui.cockpit.card.none")


## Kurzes Einblenden bei einer neuen Handlung (nicht bei Auswahländerungen derselben Karte). Abbrechbar:
## ein neues Rendern beendet das laufende Einblenden; bei reduzierter Bewegung kein Einblenden.
func _fade_in(identity: String, reduced: bool) -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	modulate.a = 1.0
	if identity == _shown_kind or reduced or not is_inside_tree():
		_shown_kind = identity
		return
	_shown_kind = identity
	modulate.a = 0.0
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 1.0, ThemeTokens.CARD_FADE_SECONDS)


## Sperrt alle Aktionen bis zum nächsten `render` (Schutz gegen Mehrfachtippen).
func lock() -> void:
	_busy = true
	for b: Node in find_children("*", "BaseButton", true, false):
		(b as BaseButton).disabled = true


# --- Kartenarten ------------------------------------------------------------------------------------

func _covered(kind: String) -> void:
	_heading("ui.cockpit.secret.heading")
	_text("ui.cockpit.secret.%s" % ("win" if kind == "win_decision" else "step"), {}, &"MutedLabel")
	_actions([_button("RevealButton", "ui.cockpit.secret.reveal", GrimmButton.Kind.PRIMARY, &"reveal")])


func _start_night(next: Dictionary, context: Dictionary) -> void:
	_heading("ui.cockpit.card.start_night.heading", {"number": int(context.get("night_number", 0)) + 1})
	_read_aloud("ui.call.night_falls_revival" if bool(next.get("revival_round", false)) else "ui.call.night_falls", {})
	_text("ui.cockpit.card.start_night.do" if bool(next.get("first")) else "ui.cockpit.card.start_night.do_next")
	var buttons: Array[Control] = [_button("StartNightButton", "ui.cockpit.action.start_night", GrimmButton.Kind.PRIMARY, &"start_night")]
	if bool(next.get("first")):
		# Optional, keine Voraussetzung für die erste Nacht: Rollen gezielt zeigen.
		buttons.append(_button("ShowRolesButton", "ui.cockpit.action.show_roles", GrimmButton.Kind.SECONDARY, &"show_roles"))
	_actions(buttons)


## Tarnaufrufe (DI-02): Rollen, die vor dem nächsten echten Schritt nur angesagt werden. Sie führen nichts aus.
func _decoys(next: Dictionary) -> void:
	var roles: Array = next.get("decoys", [])
	if roles.is_empty():
		return
	_caption("ui.cockpit.card.decoys.caption")
	_text("ui.cockpit.card.decoys.hint", {}, &"MutedLabel")
	for role: Variant in roles:
		_text(CockpitText.call_key(str(role)), {"role": CockpitText.role_name(str(role))}, &"ReadAloudLabel").name = "DecoyCall_%s" % CockpitText.key_part(str(role))


## Hinweis an betroffene Personen (DI-04, DI-06, DI-07): zeigen, dann als gezeigt bestätigen.
func _notice(next: Dictionary) -> void:
	_caption("ui.cockpit.card.notice.caption", {"count": int(next.get("open", 1))})
	_heading("ui.cockpit.card.notice.heading")
	var names: Array = (next.get("viewers", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
	_text("ui.cockpit.card.notice.for", {"names": ", ".join(names)}, &"MutedLabel")
	_text("ui.cockpit.card.notice.do")
	_actions([
		_button("ShowNoticeButton", "ui.cockpit.action.show_notice", GrimmButton.Kind.PRIMARY, &"show_notice"),
		_button("AckNoticeButton", "ui.cockpit.action.ack_notice", GrimmButton.Kind.SECONDARY, &"ack_notice", {"notice_id": int(next.get("notice_id", -1))}),
	])


func _begin_step(next: Dictionary, context: Dictionary) -> void:
	var role := str(next.get("role_id"))
	_decoys(next)
	if str(next.get("step_kind")) == "reaction":
		_caption("ui.cockpit.card.reaction.caption", {"count": int(next.get("reactions_open", 1))})
	else:
		_caption("ui.cockpit.card.step.caption", {"index": int(next.get("index", 0)), "total": int(next.get("total", 0))})
	_heading("ui.cockpit.card.role_title", {"role": CockpitText.role_name(role)})
	var actors := CockpitText.names_of(next.get("actor_ids", []), context.get("seats", []))
	_text("ui.cockpit.card.actors", {"names": actors if actors != "" else "–"}, &"MutedLabel")
	if role != str(next.get("own_role_id", role)) and str(next.get("own_role_id", "")) != "":
		_text("ui.cockpit.card.borrowed_ability", {"role": CockpitText.role_name(str(next["own_role_id"]))}, &"WarningLabel")
	if bool(next.get("repeat", false)):
		_text("ui.cockpit.card.repeat", {}, &"WarningLabel")
	if str(next.get("step_kind")) != "reaction":
		_read_aloud(CockpitText.call_key(role), {"role": CockpitText.role_name(role)})
	var buttons: Array[Control] = [_button("BeginStepButton", "ui.cockpit.action.begin_step", GrimmButton.Kind.PRIMARY, &"begin_step")]
	if bool(next.get("skippable", false)):
		buttons.append(_button("SkipStepButton", "ui.cockpit.action.skip_step", GrimmButton.Kind.SECONDARY, &"skip_step"))
	_actions(buttons)


func _prompt(next: Dictionary, context: Dictionary) -> void:
	var role := str(next.get("role_id"))
	var answer := str(next.get("answer"))
	var anonymous := bool(next.get("anonymous_asker", false))
	_decoys(next)
	_caption("ui.cockpit.card.prompt.caption")
	# DI-05: Die Frage an die gefragte Person nennt weder Rolle noch die fragende Person.
	if anonymous:
		_heading("ui.cockpit.card.red_grant.heading")
	else:
		_heading("ui.cockpit.card.role_title", {"role": CockpitText.role_name(role)})
	var actors := CockpitText.names_of(next.get("actor_ids", []), context.get("seats", []))
	if actors != "":
		_text("ui.cockpit.card.asked" if anonymous else "ui.cockpit.card.actors", {"names": actors}, &"MutedLabel")
	for line: Dictionary in next.get("info", []):
		if anonymous:
			break
		_text("ui.cockpit.card.info_line", {"label": StringName(CockpitText.info_key(str(line["key"]))), "value": CockpitText.info_value(line)}, &"WarningLabel")
	var instruction := CockpitText.reaction_key(str(next.get("reaction_kind"))) if str(next.get("owner")) == "reaction" \
		else CockpitText.instruction_key(str(next.get("owner")), str(next.get("stage")), answer)
	_text(instruction, {"min": int(next.get("min", 0)), "max": int(next.get("max", 0))})
	var buttons: Array[Control] = []
	match answer:
		"targets":
			_targets_part(next, context, buttons)
		"choice":
			var owner := str(next.get("owner"))
			var stage := str(next.get("stage"))
			buttons.append(_button("YesButton", CockpitText.action_key("yes", owner, stage), GrimmButton.Kind.PRIMARY, &"choice", {"choice": true}))
			buttons.append(_button("NoButton", CockpitText.action_key("no", owner, stage), GrimmButton.Kind.SECONDARY, &"choice", {"choice": false}))
		"ack":
			buttons.append(_button("AckButton", "ui.cockpit.action.ack.%s" % str(next.get("stage")), GrimmButton.Kind.PRIMARY, &"choice", {"choice": true}))
		"option":
			var options: Array = next.get("options", [])
			for i: int in options.size():
				var b := _button("OptionButton_%d" % i, "ui.cockpit.action.option", GrimmButton.Kind.SECONDARY, &"option", {"index": i})
				b.format_values = {"number": i + 1, "role": CockpitText.role_name(str(options[i]))}
				buttons.append(b)
		"prediction":
			_prediction_part(next, context, buttons)
	if not (next.get("show", []) as Array).is_empty():
		buttons.append(_button("ShowCardButton", "ui.cockpit.action.show_card", GrimmButton.Kind.SECONDARY, &"show_card"))
	if bool(next.get("can_override_shown", false)):
		buttons.append(_button("OverrideShownButton", "ui.cockpit.action.override_shown", GrimmButton.Kind.SECONDARY, &"override_shown"))
	if bool(next.get("cancellable", false)):
		buttons.append(_button("CancelPromptButton", "ui.cockpit.action.cancel_prompt", GrimmButton.Kind.SECONDARY, &"cancel_prompt"))
	_actions(buttons)


func _targets_part(next: Dictionary, context: Dictionary, buttons: Array[Control]) -> void:
	var selection: Array = context.get("selection", [])
	var counts: Array = next.get("counts", [])
	var error := str(context.get("selection_error", ""))
	# Zulässige Anzahl und Sperrgrund stammen aus dem Regelkern (counts, check_targets).
	_text("ui.cockpit.card.selection.counts", {"counts": CockpitText.count_list(counts)}, &"MutedLabel").name = "SelectionRuleLabel"
	if selection.is_empty():
		_text("ui.cockpit.card.selection.none", {}, &"MutedLabel").name = "SelectionLabel"
	else:
		_text("ui.cockpit.card.selection.some", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel").name = "SelectionLabel"
	if not selection.is_empty() and error != "":
		var key := "ui.cockpit.card.selection.blocked.%s" % error
		_text(key if CockpitText.has_key(key) else "ui.cockpit.card.selection.blocked.generic", {"counts": CockpitText.count_list(counts)}, &"WarningLabel").name = "SelectionBlockedLabel"
	var confirm := _button("ConfirmTargetsButton", "ui.cockpit.action.confirm_targets", GrimmButton.Kind.PRIMARY, &"confirm_targets")
	confirm.disabled = selection.is_empty() or error != ""
	buttons.append(confirm)
	if counts.has(0):
		buttons.append(_button("DeclineButton", CockpitText.action_key("decline", str(next.get("owner")), str(next.get("stage"))), GrimmButton.Kind.SECONDARY, &"decline"))
	if not selection.is_empty():
		buttons.append(_button("ClearSelectionButton", "ui.cockpit.action.clear_selection", GrimmButton.Kind.SECONDARY, &"clear_selection"))


func _prediction_part(next: Dictionary, context: Dictionary, buttons: Array[Control]) -> void:
	var minimum: Dictionary = next.get("prediction_min", {})
	var kind := str(context.get("prediction_kind", "night"))
	var number := maxi(int(context.get("prediction_number", 0)), int(minimum.get(kind, 1)))
	_text("ui.cockpit.card.prediction.value", {"when": StringName("ui.cockpit.card.prediction.%s" % kind), "number": number}, &"SectionLabel")
	buttons.append(_button("PredictionNightButton", "ui.cockpit.card.prediction.night", GrimmButton.Kind.SECONDARY, &"prediction_kind", {"kind": "night"}))
	buttons.append(_button("PredictionDayButton", "ui.cockpit.card.prediction.day", GrimmButton.Kind.SECONDARY, &"prediction_kind", {"kind": "day"}))
	buttons.append(_button("PredictionMinusButton", "ui.cockpit.card.prediction.minus", GrimmButton.Kind.SECONDARY, &"prediction_number", {"number": maxi(number - 1, int(minimum.get(kind, 1)))}))
	buttons.append(_button("PredictionPlusButton", "ui.cockpit.card.prediction.plus", GrimmButton.Kind.SECONDARY, &"prediction_number", {"number": number + 1}))
	buttons.append(_button("ConfirmPredictionButton", "ui.cockpit.action.confirm_prediction", GrimmButton.Kind.PRIMARY, &"prediction", {"kind": kind, "number": number}))


func _end_night(next: Dictionary) -> void:
	_decoys(next)
	_heading("ui.cockpit.card.end_night.heading")
	if int(next.get("skipped", 0)) > 0:
		_text("ui.cockpit.card.end_night.skipped", {"count": int(next["skipped"])}, &"WarningLabel")
	_text("ui.cockpit.card.end_night.do")
	_actions([_button("EndNightButton", "ui.cockpit.action.end_night", GrimmButton.Kind.PRIMARY, &"end_night")])


## Morgenbericht: Vorlesetext aus dem öffentlichen Teil, zeigbare Ansagekarte, private Details.
func _morning(next: Dictionary) -> void:
	_caption("ui.cockpit.card.morning.caption", {"number": int(next.get("night_number", 0))})
	_heading("ui.cockpit.card.morning.heading")
	_caption("ui.cockpit.card.say_now")
	for line: Dictionary in CockpitText.morning_lines(next.get("public", {})):
		_text(str(line["key"]), line["values"], &"ReadAloudLabel")
	_actions([
		_button("ContinueDayButton", "ui.cockpit.action.continue_day", GrimmButton.Kind.PRIMARY, &"continue_day"),
		_button("ShowAnnouncementButton", "ui.cockpit.action.show_announcement", GrimmButton.Kind.SECONDARY, &"show_announcement"),
		_button("MorningDetailsButton", "ui.cockpit.action.morning_details", GrimmButton.Kind.SECONDARY, &"morning_details"),
	])


## Tag: Nominierungen (öffentlich), heutige Tode, Aktionen. Unterzustände der Bedienung kommen aus
## `context.day_mode` (Nominierung in zwei Schritten, Hinrichtung wählen, verdeckte Prüfung).
func _day(next: Dictionary, context: Dictionary) -> void:
	match str(context.get("day_mode", "")):
		"nominate_from", "nominate_to":
			_day_nominate(context)
			return
		"execute":
			_day_pick(context, "ui.cockpit.card.day.execute.heading", "ui.cockpit.card.day.execute.do", "ConfirmExecutionTargetButton", "ui.cockpit.action.check_execution", &"check_execution")
			return
		"name_wolf":
			_day_pick(context, "ui.cockpit.card.day.name_wolf.heading", "ui.cockpit.card.day.name_wolf.do", "ConfirmNameWolfButton", "ui.cockpit.action.confirm_name_wolf", &"confirm_name_wolf")
			return
		"execution_check":
			_execution_check(context)
			return
	_heading("ui.cockpit.card.day.heading", {"number": int(context.get("day_number", 0))})
	_day_public(next, context)
	_text("ui.cockpit.card.day.do", {}, &"MutedLabel")
	var execute := _button("ExecuteButton", "ui.cockpit.action.execute", GrimmButton.Kind.PRIMARY, &"start_execute")
	execute.disabled = (next.get("execution_candidates", []) as Array).is_empty()
	_actions([
		_button("NominateButton", "ui.cockpit.action.nominate", GrimmButton.Kind.SECONDARY, &"start_nominate"),
		execute,
		_button("NoExecutionButton", "ui.cockpit.action.no_execution", GrimmButton.Kind.SECONDARY, &"no_execution"),
	])


func _day_public(next: Dictionary, context: Dictionary) -> void:
	var nominations: Array = next.get("nominations", [])
	if nominations.is_empty():
		_text("ui.cockpit.card.day.no_nominations", {}, &"MutedLabel")
	else:
		_caption("ui.cockpit.card.day.nominations")
		var seats: Array = context.get("seats", [])
		for n: Dictionary in nominations:
			var nominee := CockpitText.names_of([int(n["nominee_id"])], seats)
			if int(n["nominator_id"]) == -1:
				_text("ui.cockpit.card.day.nomination_hidden", {"nominee": nominee}, &"SectionLabel")
			else:
				_text("ui.cockpit.card.day.nomination", {"nominator": CockpitText.names_of([int(n["nominator_id"])], seats), "nominee": nominee}, &"SectionLabel")
	var deaths: Array = context.get("day_deaths", [])
	var effects: Array = context.get("day_effects", [])
	if not deaths.is_empty() or not effects.is_empty():
		_caption("ui.cockpit.card.say_now")
	if not deaths.is_empty():
		_text("ui.cockpit.card.day.deaths", {"names": CockpitText.spoken_names(deaths)}, &"ReadAloudLabel")
	for e: Dictionary in effects:
		var line := CockpitText.effect_line(e)
		_text(str(line["key"]), line["values"], &"ReadAloudLabel")


func _day_nominate(context: Dictionary) -> void:
	var seats: Array = context.get("seats", [])
	var from := int(context.get("nominator", -1))
	_heading("ui.cockpit.card.day.nominate.heading")
	if str(context.get("day_mode")) == "nominate_from":
		_text("ui.cockpit.card.day.nominate.from", {}, &"SectionLabel")
		_actions([_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])
		return
	_text("ui.cockpit.card.day.nominate.to", {"nominator": CockpitText.names_of([from], seats)}, &"SectionLabel")
	var selection: Array = context.get("selection", [])
	if not selection.is_empty():
		_text("ui.cockpit.card.day.nominate.summary", {"nominator": CockpitText.names_of([from], seats), "nominee": CockpitText.names_of(selection, seats)}, &"SectionLabel")
	var confirm := _button("ConfirmNominationButton", "ui.cockpit.action.confirm_nomination", GrimmButton.Kind.PRIMARY, &"confirm_nomination")
	confirm.disabled = selection.is_empty()
	_actions([confirm, _button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])


func _day_pick(context: Dictionary, heading: String, instruction: String, confirm_name: String, confirm_key: String, action: StringName) -> void:
	_heading(heading)
	_text(instruction, {}, &"MutedLabel")
	var selection: Array = context.get("selection", [])
	if selection.is_empty():
		_text("ui.cockpit.card.selection.none", {}, &"MutedLabel")
	else:
		_text("ui.cockpit.card.selection.some", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel")
	var confirm := _button(confirm_name, confirm_key, GrimmButton.Kind.PRIMARY, action)
	confirm.disabled = selection.is_empty()
	_actions([confirm, _button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])


## Verdeckte Prüfung jeder Hinrichtung: Vorschau des Regelkerns und seine Pflichtfragen. Verdeckt,
## bis die Spielleitung aufdeckt, damit ihr Auftauchen nichts über die Rolle verrät.
func _execution_check(context: Dictionary) -> void:
	var seats: Array = context.get("seats", [])
	var preview: Dictionary = context.get("preview", {})
	var target := CockpitText.names_of([int(preview.get("target_id", -1))], seats)
	_heading("ui.cockpit.card.day.check.heading", {"name": target})
	if not bool(context.get("revealed", false)):
		_text("ui.cockpit.card.day.check.covered", {}, &"MutedLabel")
		_actions([_button("RevealButton", "ui.cockpit.secret.reveal", GrimmButton.Kind.PRIMARY, &"reveal"),
			_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])
		return
	var extra: Dictionary = context.get("exec_extra", {})
	var ready := true
	var buttons: Array[Control] = []
	if bool(preview.get("redirected", false)):
		_text("ui.cockpit.card.day.check.redirected", {"name": CockpitText.names_of([int(preview["death_target_id"])], seats)}, &"WarningLabel")
	elif not bool(preview.get("needs_cerberus", false)) and not bool(preview.get("needs_sage", false)):
		_text("ui.cockpit.card.day.check.plain", {"name": target}, &"MutedLabel")
	if bool(preview.get("needs_cerberus", false)):
		_text("ui.cockpit.card.day.check.cerberus", {}, &"WarningLabel")
		ready = ready and extra.has("cerberus_defend")
		for choice: bool in [true, false]:
			var b := _button("CerberusDefend%s" % ("Yes" if choice else "No"), "ui.cockpit.action.cerberus.%s" % ("yes" if choice else "no"),
				GrimmButton.Kind.SECONDARY, &"exec_extra", {"field": "cerberus_defend", "value": choice})
			if extra.get("cerberus_defend") == choice:
				b.kind = GrimmButton.Kind.PRIMARY
			buttons.append(b)
	if bool(preview.get("needs_sage", false)):
		_text("ui.cockpit.card.day.check.sage", {"max": int(preview.get("sage_max", 0))}, &"WarningLabel")
		ready = ready and extra.has("sage_curse")
		for n: int in int(preview.get("sage_max", 0)) + 1:
			var b := _button("SageCurse%d" % n, "ui.cockpit.action.sage_curse", GrimmButton.Kind.SECONDARY, &"exec_extra", {"field": "sage_curse", "value": n})
			b.format_values = {"count": n}
			if extra.has("sage_curse") and int(extra["sage_curse"]) == n:
				b.kind = GrimmButton.Kind.PRIMARY
			buttons.append(b)
	var confirm := _button("ConfirmExecutionButton", "ui.cockpit.action.confirm_execution", GrimmButton.Kind.PRIMARY, &"confirm_execution")
	confirm.disabled = not ready
	buttons.append(confirm)
	buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
	_actions(buttons)


## Geführte Spielleiterkorrektur: Person wählen, Pflichtangaben, dann Rückfrage mit Begründung.
func _gm(context: Dictionary) -> void:
	var mode := str(context.get("gm_mode", ""))
	_heading("ui.cockpit.card.gm.heading", {"kind": StringName("ui.gm.kind.%s" % mode)})
	_text("ui.cockpit.card.gm.warning", {}, &"WarningLabel")
	var buttons: Array[Control] = []
	if mode == "declare_winner":
		_text("ui.cockpit.card.gm.winner", {}, &"MutedLabel")
		for kind: String in ["village", "wolves", "solo", "none"]:
			buttons.append(_button("GmWinner_%s" % kind, "ui.cockpit.win.kind.%s" % kind, GrimmButton.Kind.SECONDARY, &"gm_winner", {"kind": kind}))
		buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
		_actions(buttons)
		return
	_text("ui.cockpit.card.gm.pick_dead" if mode == "revive" else "ui.cockpit.card.gm.pick_alive", {}, &"MutedLabel")
	var selection: Array = context.get("selection", [])
	if not selection.is_empty():
		_text("ui.cockpit.card.selection.some", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel")
	var ready := not selection.is_empty()
	if mode == "kill":
		var effects: Variant = context.get("gm_effects")
		for choice: bool in [true, false]:
			var b := _button("GmEffects%s" % ("Yes" if choice else "No"), "ui.cockpit.card.gm.effects.%s" % ("yes" if choice else "no"),
				GrimmButton.Kind.PRIMARY if effects is bool and effects == choice else GrimmButton.Kind.SECONDARY, &"gm_effects", {"value": choice})
			buttons.append(b)
		ready = ready and effects is bool
	if mode == "status":
		# Jeder Wert ist ein eigener Button „Feld: aktuell → neu“; die Wahl führt direkt zur Rückfrage.
		var fields: Array = context.get("status_fields", [])
		for i: int in fields.size():
			var f: Dictionary = fields[i]
			var b := _button("GmField_%s" % str(f["field"]), "ui.cockpit.card.gm.field", GrimmButton.Kind.SECONDARY, &"gm_field", {"index": i})
			var now: Variant = f["current"]
			b.format_values = {"field": StringName("ui.gm.field.%s" % str(f["field"])),
				"from": StringName("ui.common.yes" if now == true else "ui.common.no") if str(f["type"]) == "bool" else CockpitText.role_name(str(now)),
				"to": StringName("ui.common.no" if now == true else "ui.common.yes") if str(f["type"]) == "bool" else StringName("ui.cockpit.card.gm.choose")}
			buttons.append(b)
		buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
		_actions(buttons)
		return
	if mode == "set_role":
		var role := str(context.get("gm_role", ""))
		if role != "":
			_text("ui.cockpit.card.gm.new_role", {"role": CockpitText.role_name(role)}, &"SectionLabel")
		buttons.append(_button("GmChooseRoleButton", "ui.cockpit.card.gm.choose_role", GrimmButton.Kind.SECONDARY, &"gm_choose_role"))
		ready = ready and role != ""
	var confirm := _button("GmConfirmButton", "ui.cockpit.card.gm.confirm", GrimmButton.Kind.DANGER, &"gm_confirm")
	confirm.disabled = not ready
	buttons.append(confirm)
	buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
	_actions(buttons)


func _end_day(next: Dictionary, context: Dictionary) -> void:
	_heading("ui.cockpit.card.end_day.heading", {"number": int(context.get("day_number", 0))})
	_day_public(next, context)
	_text("ui.cockpit.card.end_day.do", {}, &"MutedLabel")
	_actions([_button("EndDayButton", "ui.cockpit.action.end_day", GrimmButton.Kind.PRIMARY, &"end_day")])


func _win_decision(next: Dictionary) -> void:
	_heading("ui.cockpit.card.win.heading")
	_text("ui.cockpit.card.win.do", {}, &"MutedLabel")
	var buttons: Array[Control] = []
	for c: Dictionary in next.get("candidates", []):
		_text("ui.cockpit.card.win.candidate", {"side": StringName("ui.cockpit.win.kind.%s" % str(c["kind"])),
			"reason": StringName(_reason_key(str(c["reason_key"]))), "names": ", ".join(c.get("beneficiaries", []))}, &"SectionLabel")
		var b := _button("ConfirmWinButton_%d" % int(c["id"]), "ui.cockpit.action.confirm_win", GrimmButton.Kind.PRIMARY, &"confirm_win", {"candidate_id": int(c["id"])})
		b.format_values = {"side": StringName("ui.cockpit.win.kind.%s" % str(c["kind"]))}
		buttons.append(b)
	buttons.append(_button("RejectWinButton", "ui.cockpit.action.reject_win", GrimmButton.Kind.SECONDARY, &"reject_win"))
	_actions(buttons)


func _game_over(next: Dictionary) -> void:
	_heading("ui.cockpit.card.game_over.heading")
	var winner: Dictionary = next.get("winner", {})
	if not winner.is_empty():
		_text("ui.cockpit.card.win.candidate", {"side": StringName("ui.cockpit.win.kind.%s" % str(winner["kind"])),
			"reason": StringName(_reason_key(str(winner["reason_key"]))), "names": ", ".join(winner.get("beneficiaries", []))}, &"SectionLabel")


func _reason_key(reason: String) -> String:
	var key := "ui.cockpit.win.reason.%s" % reason
	return key if CockpitText.has_key(key) else "ui.cockpit.win.reason.generic"


# --- Bausteine --------------------------------------------------------------------------------------

func _heading(key: String, values: Dictionary = {}) -> GrimmLabel:
	return _text(key, values, &"HeadingLabel")


func _caption(key: String, values: Dictionary = {}) -> GrimmLabel:
	return _text(key, values, &"CaptionLabel")


func _read_aloud(key: String, values: Dictionary) -> void:
	_caption("ui.cockpit.card.say_now")
	_text(key, values, &"ReadAloudLabel")


func _text(key: String, values: Dictionary = {}, variation: StringName = &"") -> GrimmLabel:
	var label := GrimmLabel.new()
	label.format_values = values
	label.text_key = key
	if variation != &"":
		label.theme_type_variation = variation
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)
	return label


func _button(node_name: String, key: String, kind: GrimmButton.Kind, action: StringName, payload: Dictionary = {}) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = kind
	b.text_key = key
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(_emit.bind(action, payload, b))
	return b


func _actions(buttons: Array[Control]) -> void:
	var box := VBoxContainer.new()
	box.name = "Actions"
	box.add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)
	for b: Control in buttons:
		box.add_child(b)
	add_child(box)


## Ein Tippen zählt nur auf einem Button der aktuellen Karte, solange sie nicht gesperrt ist.
func _emit(action: StringName, payload: Dictionary, source: BaseButton) -> void:
	if _busy or source.disabled or source.is_queued_for_deletion() or not is_ancestor_of(source):
		return
	requested.emit(action, payload)
