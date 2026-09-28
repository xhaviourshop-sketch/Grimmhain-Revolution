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
	match kind:
		"start_night":
			_start_night(next, context)
		"begin_step":
			_begin_step(next, context)
		"prompt":
			_prompt(next, context)
		"end_night":
			_end_night(next)
		"morning":
			_morning(next)
		"win_decision":
			_win_decision(next)
		"game_over":
			_game_over(next)
		"no_game":
			_heading("ui.cockpit.instruction.heading")
			_text("ui.cockpit.instruction.no_game", {}, &"MutedLabel")
		_:
			_heading("ui.cockpit.card.none")


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
	_read_aloud("ui.call.night_falls", {})
	_text("ui.cockpit.card.start_night.do" if bool(next.get("first")) else "ui.cockpit.card.start_night.do_next")
	_actions([_button("StartNightButton", "ui.cockpit.action.start_night", GrimmButton.Kind.PRIMARY, &"start_night")])


func _begin_step(next: Dictionary, context: Dictionary) -> void:
	var role := str(next.get("role_id"))
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
	_caption("ui.cockpit.card.prompt.caption")
	_heading("ui.cockpit.card.role_title", {"role": CockpitText.role_name(role)})
	var actors := CockpitText.names_of(next.get("actor_ids", []), context.get("seats", []))
	if actors != "":
		_text("ui.cockpit.card.actors", {"names": actors}, &"MutedLabel")
	for line: Dictionary in next.get("info", []):
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
	var low := int(next.get("min", 0))
	var high := int(next.get("max", 0))
	if selection.is_empty():
		_text("ui.cockpit.card.selection.none", {}, &"MutedLabel")
	else:
		_text("ui.cockpit.card.selection.some", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel")
	var confirm := _button("ConfirmTargetsButton", "ui.cockpit.action.confirm_targets", GrimmButton.Kind.PRIMARY, &"confirm_targets")
	confirm.disabled = selection.is_empty() or selection.size() < low or selection.size() > high
	buttons.append(confirm)
	if low == 0:
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
