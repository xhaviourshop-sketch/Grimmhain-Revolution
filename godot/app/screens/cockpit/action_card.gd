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
		"card_window":
			_card_window(next, context)
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
	_text("ui.cockpit.secret.%s" % ("win" if kind == "win_decision" else ("card" if kind == "card_window" else "step")), {}, &"MutedLabel")
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
	var buttons: Array[Control] = [
		_button("ShowNoticeButton", "ui.cockpit.action.show_notice", GrimmButton.Kind.PRIMARY, &"show_notice"),
		_button("AckNoticeButton", "ui.cockpit.action.ack_notice", GrimmButton.Kind.SECONDARY, &"ack_notice", {"notice_id": int(next.get("notice_id", -1))}),
	]
	_help(next, buttons)
	_actions(buttons)


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
	_help(next, buttons)
	_actions(buttons)


func _prompt(next: Dictionary, context: Dictionary) -> void:
	var role := str(next.get("role_id"))
	var answer := str(next.get("answer"))
	var anonymous := bool(next.get("anonymous_asker", false))
	var is_card := str(next.get("owner")) == "card"
	_decoys(next)
	_caption("ui.cockpit.card.prompt.caption")
	# DI-05: Die Frage an die gefragte Person nennt weder Rolle noch die fragende Person.
	if anonymous:
		_heading("ui.cockpit.card.red_grant.heading")
	elif is_card:
		_card_prompt_head(next)
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
		else (CockpitText.card_instruction_key(next) if is_card else CockpitText.instruction_key(str(next.get("owner")), str(next.get("stage")), answer))
	_text(instruction, {"min": int(next.get("min", 0)), "max": int(next.get("max", 0))})
	if str(next.get("owner")) == "kartenschlucker":
		_swallower_status(next)
	if is_card and not (next.get("dice", []) as Array).is_empty():
		_dice(next.get("dice", []))
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
			var option_kind := str(next.get("option_kind", ""))
			for i: int in options.size():
				if option_kind != "" and option_kind != "role":
					# Karteneingaben und Handzeichen des Kartenschluckers: eigene Beschriftung je Option.
					buttons.append(_button("OptionButton_%d" % i, CockpitText.card_option_key(option_kind, str(options[i])), GrimmButton.Kind.SECONDARY, &"option", {"index": i}))
					continue
				var b := _button("OptionButton_%d" % i, "ui.cockpit.action.option", GrimmButton.Kind.SECONDARY, &"option", {"index": i})
				b.format_values = {"number": i + 1, "role": CockpitText.role_name(str(options[i]))}
				buttons.append(b)
		"roll":
			var roll := _button("RollButton", "ui.cards.action.roll", GrimmButton.Kind.PRIMARY, &"roll")
			roll.format_values = {"count": int(next.get("dice_count", 1))}
			buttons.append(roll)
		"prediction":
			_prediction_part(next, context, buttons)
	if not (next.get("show", []) as Array).is_empty():
		buttons.append(_button("ShowCardButton", "ui.cockpit.action.show_card", GrimmButton.Kind.SECONDARY, &"show_card"))
	if bool(next.get("can_override_shown", false)):
		buttons.append(_button("OverrideShownButton", "ui.cockpit.action.override_shown", GrimmButton.Kind.SECONDARY, &"override_shown"))
	if bool(next.get("cancellable", false)):
		buttons.append(_button("CancelPromptButton", "ui.cockpit.action.cancel_prompt", GrimmButton.Kind.SECONDARY, &"cancel_prompt"))
	_help(next, buttons)
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
	var random_active := bool(context.get("random_active", false))
	if random_active:
		# Vorschlag der Zufallsziehung; übernommen wird er erst mit „Auswahl bestätigen“ (RM-DR-015.2).
		_text("ui.cockpit.card.random.proposal", {}, &"MutedLabel").name = "RandomProposalLabel"
	var confirm := _button("ConfirmTargetsButton", "ui.cockpit.action.confirm_targets", GrimmButton.Kind.PRIMARY, &"confirm_targets")
	confirm.disabled = (selection.is_empty() and not random_active) or error != ""
	buttons.append(confirm)
	if bool(next.get("random", false)):
		var random := _button("RandomTargetsButton", "ui.cockpit.action.random_targets", GrimmButton.Kind.SECONDARY, &"random_targets")
		random.disabled = not bool(context.get("random_available", false))
		buttons.append(random)
		if random.disabled:
			_text("ui.cockpit.card.random.none", {}, &"MutedLabel").name = "RandomUnavailableLabel"
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
		"card_report":
			_day_pick(context, "ui.cards.report.heading", "ui.cards.report.do", "ConfirmCardReportButton", "ui.cards.action.confirm_report", &"confirm_card_report")
			return
		"execution_check":
			_execution_check(context)
			return
	_heading("ui.cockpit.card.day.heading", {"number": int(context.get("day_number", 0))})
	_day_public(next, context)
	var extra_buttons: Array[Control] = []
	_card_rules(next.get("card_rules", []), extra_buttons)
	if bool(next.get("execution_cancelled", false)):
		_text("ui.cards.exec.cancelled", {}, &"WarningLabel").name = "ExecutionCancelledLabel"
	if bool(next.get("dead_nominate", false)):
		_text("ui.cards.exec.dead_nominate", {}, &"WarningLabel").name = "DeadNominateLabel"
	_text("ui.cockpit.card.day.do", {}, &"MutedLabel")
	var execute := _button("ExecuteButton", "ui.cockpit.action.execute", GrimmButton.Kind.PRIMARY, &"start_execute")
	execute.disabled = (next.get("execution_candidates", []) as Array).is_empty() or bool(next.get("execution_cancelled", false))
	var day_buttons: Array[Control] = [
		_button("NominateButton", "ui.cockpit.action.nominate", GrimmButton.Kind.SECONDARY, &"start_nominate"),
		execute,
		_button("NoExecutionButton", "ui.cockpit.action.no_execution", GrimmButton.Kind.SECONDARY, &"no_execution"),
	]
	day_buttons.append_array(extra_buttons)
	if bool(next.get("cards", false)):
		day_buttons.append(_button("CardOverviewButton", "ui.cards.action.overview", GrimmButton.Kind.COMPACT, &"card_overview"))
	_actions(day_buttons)


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
	var card_lines: Array = CockpitText.card_lines(context.get("day_cards", []))
	if not card_lines.is_empty() and deaths.is_empty() and effects.is_empty():
		_caption("ui.cockpit.card.say_now")
	for line: Dictionary in card_lines:
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
	elif not bool(preview.get("needs_cerberus", false)) and not bool(preview.get("needs_sage", false)) and not _card_exec_notes(preview, seats):
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
	# Totenreichkarten: Enthüllung vor dem Vollzug (Wachsame Augen) und Entscheid des Dorfes, zweitmeiste Stimmen (Kettenreaktion).
	var confirm_key := "ui.cockpit.action.confirm_execution"
	if bool(preview.get("card_reveal", false)):
		if not bool(preview.get("card_revealed", false)):
			_text("ui.cards.exec.reveal", {}, &"WarningLabel").name = "CardRevealLabel"
			confirm_key = "ui.cards.action.reveal_role"
		else:
			_text("ui.cards.exec.village_decides", {}, &"WarningLabel").name = "VillageDecidesLabel"
			ready = ready and extra.has("village_confirms")
			for choice: bool in [true, false]:
				var b := _button("VillageConfirms%s" % ("Yes" if choice else "No"), "ui.cards.action.village.%s" % ("yes" if choice else "no"),
					GrimmButton.Kind.PRIMARY if extra.get("village_confirms") == choice else GrimmButton.Kind.SECONDARY, &"exec_extra", {"field": "village_confirms", "value": choice})
				buttons.append(b)
	if bool(preview.get("card_runner_up", false)) and (not bool(preview.get("card_reveal", false)) or bool(preview.get("card_revealed", false))):
		var picked: Array = context.get("selection", [])
		if extra.has("runner_up_id"):
			_text("ui.cards.exec.runner_up_set", {"name": CockpitText.names_of([int(extra["runner_up_id"])], seats) if int(extra["runner_up_id"]) != -1 else "–"}, &"SectionLabel").name = "RunnerUpLabel"
		else:
			_text("ui.cards.exec.runner_up", {}, &"WarningLabel").name = "RunnerUpPrompt"
			ready = false
			var take := _button("TakeRunnerUpButton", "ui.cards.action.take_runner_up", GrimmButton.Kind.PRIMARY, &"exec_runner_up", {"id": int(picked[0]) if not picked.is_empty() else -1})
			take.disabled = picked.is_empty()
			buttons.append(take)
			buttons.append(_button("NoRunnerUpButton", "ui.cards.action.no_runner_up", GrimmButton.Kind.SECONDARY, &"exec_runner_up", {"id": -1}))
	var confirm := _button("ConfirmExecutionButton", confirm_key, GrimmButton.Kind.PRIMARY, &"confirm_execution")
	confirm.disabled = not ready
	buttons.append(confirm)
	buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
	_actions(buttons)


## Hinweise zu Kartenwirkungen auf die Hinrichtung; gibt zurück, ob mindestens einer angezeigt wurde.
func _card_exec_notes(preview: Dictionary, seats: Array) -> bool:
	var shown := false
	if bool(preview.get("card_shifted", false)):
		_text("ui.cards.exec.shifted", {"name": CockpitText.names_of([int(preview["death_target_id"])], seats)}, &"WarningLabel").name = "ShiftedLabel"
		shown = true
	if bool(preview.get("card_random_wolf", false)):
		_text("ui.cards.exec.random_wolf", {}, &"WarningLabel").name = "RandomWolfLabel"
		shown = true
	return shown


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
			if str(f["type"]) == "action" or str(f["type"]) == "pick":
				# Spezialkorrektur: Art der Korrektur und bisheriger Wert der Person; „…“ = zuerst ein Ziel wählen.
				var special := _button("GmField_%s" % str(f["field"]), "ui.cockpit.card.gm.action_pick" if str(f["type"]) == "pick" else "ui.cockpit.card.gm.action",
					GrimmButton.Kind.SECONDARY, &"gm_field", {"index": i})
				special.format_values = {"kind": StringName("ui.gm.kind.%s" % str(f["kind"])), "state": CockpitText.state_text(f.get("state", {}))}
				buttons.append(special)
				continue
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
	var buttons: Array[Control] = [_button("OpenReportButton", "ui.cockpit.action.open_report", GrimmButton.Kind.PRIMARY, &"open_report")]
	_actions(buttons)


func _reason_key(reason: String) -> String:
	var key := "ui.cockpit.win.reason.%s" % reason
	return key if CockpitText.has_key(key) else "ui.cockpit.win.reason.generic"


# --- Bausteine --------------------------------------------------------------------------------------

## Kontexthilfe (private Spielleiterkarte): allgemeiner Lexikoneintrag der Rolle der aktuellen Handlung. Entsteht nur auf
## einer aufgedeckten bzw. nächtlichen Karte (verdeckt gibt es keine Knoten) und nie auf gezeigten Ebenen.
func _help(next: Dictionary, buttons: Array[Control]) -> void:
	var role := CockpitText.help_role(next)
	if role != "":
		buttons.append(_button("ContextHelpButton", "ui.cockpit.action.help", GrimmButton.Kind.COMPACT, &"help", {"role_id": role}))


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


# --- Totenreichkarten ---------------------------------------------------------------------------------

## Kartenfläche: Name der Karte und ihr Text zum Vorlesen oder Zeigen.
func _card_face(card: Dictionary) -> void:
	if card.is_empty():
		return
	var title := _text(str(card["name_key"]), {}, &"SectionLabel")
	title.name = "CardNameLabel"
	if str(card.get("text_key", "")) != "":
		_text(str(card["text_key"]), {}, &"ReadAloudLabel").name = "CardTextLabel"


## Kopf einer Karteneingabe: Karte oder Aufgabe, handelnde Person, Kartentext (nur beim Spielen).
func _card_prompt_head(next: Dictionary) -> void:
	var card: Dictionary = next.get("card", {})
	var task := str(next.get("task_kind", ""))
	if task != "":
		_heading("ui.card.task.%s.heading" % task if CockpitText.has_key("ui.card.task.%s.heading" % task) else "ui.cards.task.heading")
		if not card.is_empty():
			_text(str(card["name_key"]), {}, &"CaptionLabel").name = "CardNameLabel"
		if next.has("victim") and str(next.get("victim_role", "")) != "":
			_text("ui.cards.pack_victim", {"name": CockpitText.person(next["victim"]), "role": CockpitText.role_name(str(next["victim_role"]))}, &"WarningLabel").name = "PackVictimLabel"
	else:
		_heading("ui.cards.prompt.heading")
		_card_face(card)


## Würfel mit den gespeicherten Würfen (sichtbar gezeichnet, zusätzlich als Zahl).
func _dice(values: Array) -> void:
	var row := DiceRow.new()
	row.show_dice(values)
	add_child(row)
	_text("ui.cards.dice.result", {"dice": ", ".join(values.map(func(v: Variant) -> String: return str(int(v))))}, &"SectionLabel").name = "DiceResultLabel"


## Guthaben des Kartenschluckers (nur Spielleitung): verfügbare und insgesamt gesammelte Stapel, Schild.
func _swallower_status(next: Dictionary) -> void:
	var info: Dictionary = next.get("swallower", {})
	if info.is_empty():
		return
	_text("ui.cards.swallower.status", {"balance": int(info["balance"]), "total": int(info["total"]),
		"shield": StringName("ui.common.yes" if bool(info["shield"]) else "ui.common.no")}, &"WarningLabel").name = "SwallowerStatusLabel"


## Kartenfenster: die gefragte tote Person mit ihrer Originalkarte. Spielen, aufbewahren, tauschen (nur mit lebendem
## Kartenschlucker), Karte zeigen, Überblick oder das Fenster schließen. Verdeckt, bis die Spielleitung aufdeckt.
func _card_window(next: Dictionary, _context: Dictionary) -> void:
	var card: Dictionary = next.get("card", {})
	var owner: Dictionary = next.get("owner", {})
	_caption("ui.cards.window.caption.%s" % str(next.get("window", "start")))
	_heading("ui.cards.window.heading", {"name": CockpitText.person(owner)})
	var waiting: Array = (next.get("waiting", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
	if not waiting.is_empty():
		_text("ui.cards.window.waiting", {"names": ", ".join(waiting)}, &"MutedLabel").name = "WaitingLabel"
	_card_face(card)
	_text(str(card.get("guide_key", "")), {}, &"MutedLabel").name = "CardGuideLabel"
	var preselected: Array = (next.get("preselected", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
	if not preselected.is_empty():
		_text("ui.cards.window.preselected", {"names": ", ".join(preselected)}, &"WarningLabel").name = "PreselectedLabel"
	if bool(next.get("must_play", false)):
		_text("ui.cards.window.must_play", {}, &"WarningLabel").name = "MustPlayLabel"
	var owner_id := int(next.get("owner_id", -1))
	var play := _button("CardPlayButton", "ui.cards.action.play", GrimmButton.Kind.PRIMARY, &"card_play", {"owner_id": owner_id})
	play.disabled = not bool(next.get("can_play", false))
	var keep := _button("CardKeepButton", "ui.cards.action.keep", GrimmButton.Kind.SECONDARY, &"card_keep", {"owner_id": owner_id})
	keep.disabled = not bool(next.get("can_keep", true))
	var buttons: Array[Control] = [play, keep]
	if not bool(next.get("can_play", false)):
		_text("ui.cards.window.not_playable", {}, &"MutedLabel").name = "NotPlayableLabel"
	if bool(next.get("swallower_alive", false)):
		var exchange := _button("CardExchangeButton", "ui.cards.action.exchange", GrimmButton.Kind.SECONDARY, &"card_exchange", {"owner_id": owner_id})
		exchange.disabled = not bool(next.get("can_exchange", false))
		buttons.append(exchange)
	buttons.append(_button("CardShowButton", "ui.cards.action.show", GrimmButton.Kind.SECONDARY, &"card_show"))
	buttons.append(_button("CardOverviewButton", "ui.cards.action.overview", GrimmButton.Kind.COMPACT, &"card_overview"))
	var close := _button("CardCloseWindowButton", "ui.cards.action.close_window", GrimmButton.Kind.SECONDARY, &"card_close")
	close.disabled = not bool(next.get("can_close", true))
	buttons.append(close)
	_actions(buttons)


## Öffentliche Tagesregeln durch Karten (Nebelhorn, Stummfilm, Totengericht, ...): Name, Text und, wo vorgesehen, Button zum Melden
## eines Verstoßes. Zeigt nur öffentliche Regeln, keine versteckten Wirkungen.
func _card_rules(rules: Array, buttons: Array[Control]) -> void:
	if rules.is_empty():
		return
	_caption("ui.cards.rules.caption")
	for r: Dictionary in rules:
		var name_label := _text(str(r["name_key"]), {}, &"SectionLabel")
		name_label.name = "CardRuleName_%d" % int(r["effect_id"])
		_text(str(r["text_key"]), {}, &"MutedLabel").name = "CardRuleText_%d" % int(r["effect_id"])
		var excluded: Array = (r.get("excluded", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
		if not excluded.is_empty():
			_text("ui.cards.rules.excluded", {"names": ", ".join(excluded)}, &"WarningLabel")
		if bool(r.get("reportable", false)):
			buttons.append(_button("CardReportButton_%d" % int(r["effect_id"]), "ui.cards.action.report.%s" % str(r["kind"]), GrimmButton.Kind.SECONDARY, &"card_report", {"effect_id": int(r["effect_id"])}))
