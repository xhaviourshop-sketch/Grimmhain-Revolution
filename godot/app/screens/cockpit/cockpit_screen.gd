class_name CockpitScreen
extends BaseScreen
## Spielleiter-Cockpit (02 §4.1): Phasenleiste, Sitzkreis der laufenden Partie, Ansagekarte mit
## der nächsten Handlung und Werkzeuge (Protokoll, privater Spielleiterbereich, Sichtschutz).
## Liest nur Sichten der Anwendungsschicht (GameSession.cockpit_view) und sendet Befehle über deren
## Bausteine; eigene Zustände sind nur flüchtige Bedienzustände (Auswahl, aufgedeckte Karte).
##
## Geheimhaltung:
##   - Sitzkreis und Phasenleiste zeigen nie Rollen.
##   - Geheime Karten (Schritte, Prompts, Siegkandidaten) erscheinen außerhalb der Nacht verdeckt
##     und erst nach „Anzeigen“; mit der nächsten Handlung sind sie wieder verdeckt.
##   - Rollen, Protokoll und die gezeigte Karte entstehen erst beim Öffnen als eigene Ebene und
##     werden beim Schließen, beim Sichtschutz und beim Verlassen der Ansicht entfernt.

const GROUP_CARD_WIDTH_BREAKPOINT := 1600.0

var _view: Dictionary = {}
var _next_id: String = ""
var _selection: Array = []
var _revealed_id: String = ""
var _prediction := {"kind": "night", "number": 0}
var _error_key: String = ""
var _covered: bool = false
var _layer: Control = null
var _layer_kind: StringName = &""
var _morning_done_day: int = -1  ## Tag, dessen Morgenbericht die Spielleitung weitergeschaltet hat (nur Bedienzustand)
## Bedienzustand am Tag: "" | nominate_from | nominate_to | execute | execution_check | name_wolf
var _day_mode: String = ""
var _nominator: int = -1
var _necromancer: int = -1
var _preview: Dictionary = {}
var _exec_extra: Dictionary = {}
var _check_revealed: bool = false
var _gm_execute: bool = false  ## Prüfkarte gehört zu einer Hinrichtung ohne Nominierung (Korrektur)
## Geführte Korrektur: "" | kill | revive | set_role | execute | declare_winner
var _gm_mode: String = ""
var _gm_effects: Variant = null
var _gm_role: String = ""
var _role_card_person: int = -1  ## Person der offenen Rollenkarte (nur Bedienzustand, keine Rolle)

@onready var _layout: Control = %Layout
@onready var _badge: Control = %NoGameBadge
@onready var _phase_area: PanelContainer = %PhaseArea
@onready var _phase: GrimmLabel = %PhaseValueLabel
@onready var _round: GrimmLabel = %RoundLabel
@onready var _alive: GrimmLabel = %AliveLabel
@onready var _save_status: GrimmLabel = %SaveStatusLabel
@onready var _warnings: GrimmLabel = %WarningsLabel
@onready var _ring: GameSeatRing = %SeatRing
@onready var _center_phase: GrimmLabel = %CenterPhaseLabel
@onready var _center_hint: GrimmLabel = %CenterHintLabel
@onready var _card: ActionCard = %ActionCard
@onready var _side: Control = %SideColumn
@onready var _overlay_host: Control = %OverlayHost
@onready var _backdrop: Panel = %Backdrop
@onready var _backdrop_art: TextureRect = %BackdropArt  ## Anschlussstelle für spätere Hintergrundbilder (leer)

var _backdrop_phase: String = ""
var _backdrop_tween: Tween = null


func _setup() -> void:
	_update_side_width()
	resized.connect(_update_side_width)
	context.session.view_changed.connect(_on_session_changed)
	context.session.command_rejected.connect(_on_rejected)
	context.session.state_replaced.connect(_on_state_replaced)
	context.saves.status_changed.connect(_on_save_status)
	_ring.seat_tapped.connect(_on_seat_tapped)
	_card.requested.connect(_on_card_requested)
	(%LogButton as GrimmButton).pressed.connect(open_layer.bind(&"log"))
	(%PrivateButton as GrimmButton).pressed.connect(open_layer.bind(&"private"))
	(%RolesButton as GrimmButton).pressed.connect(open_layer.bind(&"roles"))
	(%CoverButton as GrimmButton).pressed.connect(cover)
	(%GmButton as GrimmButton).pressed.connect(open_layer.bind(&"gm"))
	_refresh()


## Zurück: offene Ebene schließen, Sichtschutz aufheben oder (mit laufender Partie) nachfragen.
func handle_back() -> bool:
	if _layer != null:
		close_layer()
		return true
	if _covered:
		uncover()
		return true
	if bool(_view.get("has_game", false)):
		var r := DialogRequest.create("ui.cockpit.leave.title", "ui.cockpit.leave.message", "ui.cockpit.leave.confirm",
			func() -> void: navigate_requested.emit(ScreenIds.MAIN_MENU))
		dialog_requested.emit(r)
		return true
	return false


func default_focus() -> Control:
	var first := _card.find_children("*", "BaseButton", true, false)
	return first[0] as Control if not first.is_empty() else super.default_focus()


# --- Sicht -------------------------------------------------------------------------------------------

## Jede Zustandsänderung (angenommener Befehl, Laden, Korrektur) verwirft die Auswahl: Sie könnte
## sich auf einen veralteten Zustand beziehen, auch wenn derselbe Prompt offen bleibt.
func _on_session_changed(_v: Dictionary) -> void:
	_error_key = ""
	_selection.clear()
	_discard_role_card()
	_refresh()


## Rückgängig/Wiederholen ersetzt den Zustand: offene Tages- und Korrekturbedienung (Auswahl,
## Vorschau des alten Zustands) verfällt.
func _on_state_replaced() -> void:
	_reset_day_mode()
	_reset_gm_mode()
	_discard_role_card()
	_render()


func _refresh() -> void:
	_view = context.session.cockpit_view()
	var active := bool(_view.get("has_game", false))
	_badge.visible = not active
	for tool: String in ["LogButton", "PrivateButton", "RolesButton", "GmButton", "CoverButton"]:
		(find_child(tool, true, false) as BaseButton).disabled = not active
	var next: Dictionary = _view.get("next", {})
	var identity := _identity(next)
	if identity != _next_id:
		_next_id = identity
		_selection.clear()
		_revealed_id = ""
		_prediction = {"kind": "night", "number": 0}
	_update_status(active)
	_ring.show_seats(_view.get("seats", []))
	_render()


## Speicheranzeige: „gespeichert“ nur nach bestätigtem Schreiben, sonst deutlich als Fehler.
func _on_save_status(status: Dictionary) -> void:
	_show_save_status(status)
	if not bool(status.get("ok", false)):
		status_message_requested.emit("ui.cockpit.save.failed")


func _show_save_status(status: Dictionary) -> void:
	if status.is_empty() or str(status.get("round_id", "")) != context.session.round_id():
		_save_status.text_key = ""
		return
	var ok := bool(status.get("ok", false))
	_save_status.theme_type_variation = &"CaptionLabel" if ok else &"ErrorCaptionLabel"
	_save_status.text_key = "ui.cockpit.save.ok" if ok else "ui.cockpit.save.error"


## Anschlussstelle für spätere Hintergrundebenen je Tageszeit: Bild über der Grundfarbe, bis dahin leer.
func set_backdrop_art(texture: Texture2D) -> void:
	_backdrop_art.texture = texture


## Hintergrund je Tageszeit; kurzer Übergang, bei reduzierter Bewegung sofort. Ein neuer Wechsel
## bricht einen laufenden Übergang ab.
func _update_backdrop(phase: String) -> void:
	var group := "night" if phase == "NIGHT" else ("day" if phase in ["DAY", "DAWN_RESOLUTION"] else "")
	if group == _backdrop_phase:
		return
	_backdrop_phase = group
	_backdrop.theme_type_variation = &"NightBackdrop" if group == "night" else (&"DayBackdrop" if group == "day" else &"AppBackground")
	if _backdrop_tween != null and _backdrop_tween.is_valid():
		_backdrop_tween.kill()
	if context.settings.reduced_motion or not is_inside_tree():
		_backdrop.modulate.a = 1.0
		return
	_backdrop.modulate.a = 0.0
	_backdrop_tween = create_tween()
	_backdrop_tween.tween_property(_backdrop, "modulate:a", 1.0, ThemeTokens.BACKDROP_FADE_SECONDS)


func _update_status(active: bool) -> void:
	_update_backdrop(str(_view.get("phase", "")) if active else "")
	_show_save_status(context.saves.last_status if active else {})
	var phase := str(_view.get("phase", ""))
	_phase.text_key = "ui.phase.%s" % phase.to_lower() if active else "ui.phase.none"
	_phase_area.theme_type_variation = &"NightPanel" if phase == "NIGHT" else (&"DayPanel" if phase in ["DAY", "DAWN_RESOLUTION"] else &"HeaderPanel")
	if active:
		var progress: Dictionary = _view.get("night_progress", {})
		if phase == "NIGHT":
			_round.format_values = {"number": int(_view["night_number"]), "done": int(progress.get("done", 0)), "total": int(progress.get("total", 0))}
			_round.text_key = "ui.cockpit.round.night"
		elif phase in ["DAY", "DAWN_RESOLUTION"]:
			_round.format_values = {"number": int(_view["day_number"]) if phase == "DAY" else int(_view["night_number"])}
			_round.text_key = "ui.cockpit.round.day" if phase == "DAY" else "ui.cockpit.round.dawn"
		else:
			_round.text_key = ""
		_alive.format_values = {"alive": int(_view["alive_count"]), "total": int(_view["player_count"])}
		_alive.text_key = "ui.cockpit.alive"
		_center_phase.text_key = "ui.phase.%s" % phase.to_lower()
		_center_hint.text_key = ""
	else:
		_round.text_key = ""
		_alive.text_key = ""
		_center_phase.text_key = ""
		_center_hint.text_key = "ui.cockpit.seats.placeholder"
	var warnings: Array = _view.get("warnings", [])
	_warnings.visible = not warnings.is_empty()
	if not warnings.is_empty():
		_warnings.format_values = (warnings[0] as Dictionary).get("values", {})
		_warnings.text_key = str((warnings[0] as Dictionary)["key"])


func _render() -> void:
	var next: Dictionary = _view.get("next", {})
	var phase := str(_view.get("phase", ""))
	var visible_secret := not bool(next.get("secret", false)) or phase == "NIGHT" or _revealed_id == _next_id
	if not bool(_view.get("has_game", false)):
		_card.render({"kind": "no_game"}, {})
		_ring.clear_marking()
		return
	var kind := str(next.get("kind"))
	if _gm_mode != "":
		next = {"kind": "gm", "secret": false}
		kind = "gm"
		_mark_gm_mode()
	elif kind == "day" and _morning_pending():
		next = {"kind": "morning", "secret": false, "public": context.session.morning_report().get("public", {}),
			"night_number": int(_view.get("night_number", 0))}
		kind = "morning"
	if kind == "gm":
		pass
	elif kind == "day" and _day_mode != "":
		_mark_day_mode(next)
	elif kind == "prompt" and str(next.get("answer")) == "targets" and visible_secret:
		_ring.set_marking(true, next.get("allowed_ids", []), _selection, next.get("actor_ids", []))
	elif (kind == "prompt" or kind == "begin_step") and visible_secret:
		_ring.set_marking(false, [], [], next.get("actor_ids", []))
	else:
		_ring.clear_marking()
	# Ob die Auswahl bestätigt werden kann, entscheidet der Regelkern (Prüfung ohne Senden).
	var selection_error := ""
	if kind == "prompt" and str(next.get("answer")) == "targets" and not _selection.is_empty():
		selection_error = String(context.session.check_targets(_selection))
	_card.render(next, {
		"phase": phase, "seats": _view.get("seats", []), "selection": _selection, "selection_error": selection_error,
		"revealed": _check_revealed if _day_mode == "execution_check" else _revealed_id == _next_id,
		"night_number": int(_view.get("night_number", 0)), "prediction_kind": _prediction["kind"],
		"prediction_number": _prediction["number"], "error_key": _error_key,
		"gm_mode": _gm_mode, "gm_effects": _gm_effects, "gm_role": _gm_role,
		"status_fields": context.session.status_fields(int(_selection[0])) if _gm_mode == "status" and not _selection.is_empty() else [],
		"day_number": int(_view.get("day_number", 0)), "day_mode": _day_mode, "nominator": _nominator,
		"preview": _preview, "exec_extra": _exec_extra, "day_deaths": context.session.day_deaths() if bool(_view.get("has_game")) else [],
		"day_effects": context.session.day_effects() if bool(_view.get("has_game")) else [],
		"reduced_motion": context.settings.reduced_motion,
	})
	_restore_focus()


## Ringmarkierung im Tagesmodus: wer im aktuellen Schritt antippbar ist (nur Lebende, bei der
## Hinrichtung nur heute Nominierte). Die Regelprüfung selbst bleibt beim Regelkern.
func _mark_day_mode(next: Dictionary) -> void:
	var alive: Array = (_view.get("seats", []) as Array).filter(func(s: Dictionary) -> bool: return bool(s["alive"])).map(func(s: Dictionary) -> int: return int(s["person_id"]))
	match _day_mode:
		"nominate_from":
			_ring.set_marking(true, alive, [], [])
		"nominate_to":
			_ring.set_marking(true, alive.filter(func(id: int) -> bool: return id != _nominator), _selection, [_nominator])
		"execute":
			_ring.set_marking(true, next.get("execution_candidates", []), _selection, [])
		"name_wolf":
			_ring.set_marking(true, alive.filter(func(id: int) -> bool: return id != _necromancer), _selection, [])
		"execution_check":
			_ring.set_marking(false, [], [], [])


func _mark_gm_mode() -> void:
	var ids: Array = []
	for seat: Dictionary in _view.get("seats", []):
		if bool(seat["alive"]) != (_gm_mode == "revive"):
			ids.append(int(seat["person_id"]))
	_ring.set_marking(_gm_mode != "declare_winner", ids, _selection, [])


func _reset_gm_mode() -> void:
	_gm_mode = ""
	_gm_effects = null
	_gm_role = ""
	_gm_execute = false


func _reset_day_mode() -> void:
	_day_mode = ""
	_nominator = -1
	_necromancer = -1
	_preview = {}
	_exec_extra = {}
	_check_revealed = false
	_selection.clear()


## Nach einer Handlung ist der Button unter dem Fokus ersetzt: Fokus auf die erste Aktion der neuen
## Karte (Tastatur, Controller), solange kein Dialog und keine Ebene offen ist.
func _restore_focus() -> void:
	_apply_focus.call_deferred()


func _apply_focus() -> void:
	if _layer != null or not is_inside_tree():
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and owner.is_visible_in_tree() and not owner.is_queued_for_deletion():
		return
	var target := default_focus()
	if target != null and target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


## Der Morgenbericht steht vor den Tagesaktionen, bis die Spielleitung weiterschaltet oder am Tag
## schon etwas geschehen ist (Nominierung, Entscheidung).
func _morning_pending() -> bool:
	var day := int(_view.get("day_number", 0))
	return _morning_done_day != day and str(_view.get("day_step", "")) == "DISCUSSION" 		and (_view.get("next", {}).get("nominations", []) as Array).is_empty() and not context.session.morning_report().is_empty()


## Kennung der nächsten Handlung: wechselt sie, verfallen Auswahl und Aufdecken.
func _identity(next: Dictionary) -> String:
	match str(next.get("kind")):
		"prompt":
			return "prompt:%d:%s" % [int(next.get("prompt_id", 0)), str(next.get("stage"))]
		"begin_step":
			return "step:%s" % str(next.get("step_id"))
		"notice":
			return "notice:%d" % int(next.get("notice_id", 0))
		"win_decision":
			return "win:%s" % str((next.get("candidates", []) as Array).map(func(c: Dictionary) -> int: return int(c["id"])))
	return str(next.get("kind"))


func _update_side_width() -> void:
	if _side != null:
		_side.custom_minimum_size.x = ThemeTokens.SIDE_COLUMN_WIDE_WIDTH if size.x >= GROUP_CARD_WIDTH_BREAKPOINT else ThemeTokens.SIDE_COLUMN_WIDTH


# --- Bedienung --------------------------------------------------------------------------------------

func _on_seat_tapped(person_id: int) -> void:
	var next: Dictionary = _view.get("next", {})
	if _gm_mode != "" and _gm_mode != "declare_winner":
		_selection = [] if _selection.has(person_id) else [person_id]
		_render()
		return
	if str(next.get("kind")) == "day" and _day_mode != "":
		match _day_mode:
			"nominate_from":
				_nominator = person_id
				_day_mode = "nominate_to"
				_selection.clear()
			"nominate_to", "execute", "name_wolf":
				_selection = [] if _selection.has(person_id) else [person_id]
		_render()
		return
	if str(next.get("kind")) != "prompt" or str(next.get("answer")) != "targets":
		return
	var high := int(next.get("max", 0))
	if _selection.has(person_id):
		_selection.erase(person_id)
	elif high == 1:
		_selection = [person_id]
	elif _selection.size() < high:
		_selection.append(person_id)
	else:
		status_message_requested.emit("ui.cockpit.status.selection_full")
		return
	_render()


func _on_card_requested(action: StringName, payload: Dictionary) -> void:
	var s := context.session
	match action:
		&"reveal":
			if _day_mode == "execution_check":
				_check_revealed = true
			else:
				_revealed_id = _next_id
			_render()
		&"start_nominate":
			_reset_day_mode()
			_day_mode = "nominate_from"
			_render()
		&"start_execute":
			_reset_day_mode()
			_day_mode = "execute"
			_render()
		&"cancel_mode":
			_reset_day_mode()
			_reset_gm_mode()
			_render()
		&"gm_effects":
			_gm_effects = bool(payload["value"])
			_render()
		&"gm_choose_role":
			_ask_gm_role()
		&"gm_winner":
			_ask_correction({"kind": "declare_winner", "winner_kind": str(payload["kind"])})
		&"gm_confirm":
			_confirm_gm_mode()
		&"gm_field":
			_ask_status_field(int(payload["index"]))
		&"confirm_nomination":
			var nominee := int(_selection[0])
			var from := _nominator
			_reset_day_mode()
			_submit(s.nominate.bind(from, nominee))
		&"check_execution":
			var target := int(_selection[0])
			_reset_day_mode()
			_preview = s.execution_preview(target)
			_day_mode = "execution_check"
			_render()
		&"exec_extra":
			_exec_extra[str(payload["field"])] = payload["value"]
			_render()
		&"confirm_execution" when _gm_execute:
			var payload_gm := {"kind": "execute", "target_id": int(_preview.get("target_id", -1))}
			payload_gm.merge(_exec_extra)
			_reset_day_mode()
			_reset_gm_mode()
			_ask_correction(payload_gm)
		&"confirm_execution":
			var target := int(_preview.get("target_id", -1))
			var extra := _exec_extra.duplicate()
			var r := DialogRequest.create("ui.cockpit.dialog.execute.title", "ui.cockpit.dialog.execute.message", "ui.cockpit.dialog.execute.confirm",
				func() -> void:
					_reset_day_mode()
					_submit(s.decide_execution.bind(target, extra)), true)
			r.message_values = {"name": CockpitText.names_of([target], _view.get("seats", []))}
			dialog_requested.emit(r)
		&"no_execution":
			dialog_requested.emit(DialogRequest.create("ui.cockpit.dialog.no_execution.title", "ui.cockpit.dialog.no_execution.message",
				"ui.cockpit.dialog.no_execution.confirm", func() -> void:
					_reset_day_mode()
					_submit(s.decide_execution.bind(-1))))
		&"confirm_name_wolf":
			var necro := _necromancer
			var named := int(_selection[0])
			_reset_day_mode()
			_submit(s.name_wolf.bind(necro, named))
			status_message_requested.emit("ui.cockpit.status.saved_secretly")
		&"end_day":
			_submit(s.end_day)
		&"start_night":
			_submit(s.start_night)
		&"begin_step":
			_submit(s.begin_next_step)
		&"show_notice":
			open_layer(&"notice")
		&"show_roles":
			open_layer(&"roles")
		&"ack_notice":
			close_layer()
			_submit(s.ack_notice.bind(int(payload["notice_id"])))
		&"skip_step":
			_ask_reason("ui.cockpit.dialog.skip.title", "ui.cockpit.dialog.skip.message", "ui.cockpit.dialog.skip.confirm",
				func(reason: String) -> void: _submit(s.skip_next_step.bind(reason)))
		&"cancel_prompt":
			_ask_reason("ui.cockpit.dialog.cancel.title", "ui.cockpit.dialog.cancel.message", "ui.cockpit.dialog.cancel.confirm",
				func(reason: String) -> void: _submit(s.cancel_prompt.bind(reason)))
		&"confirm_targets":
			_submit(s.answer_targets.bind(_selection.duplicate()))
		&"decline":
			_submit(s.answer_targets.bind([]))
		&"clear_selection":
			_selection.clear()
			_render()
		&"choice":
			_submit(s.answer_choice.bind(bool(payload["choice"])))
		&"option":
			_submit(s.answer_option.bind(int(payload["index"])))
		&"prediction_kind":
			_prediction["kind"] = str(payload["kind"])
			_prediction["number"] = 0
			_render()
		&"prediction_number":
			_prediction["number"] = int(payload["number"])
			_render()
		&"prediction":
			_submit(s.answer_prediction.bind(str(payload["kind"]), int(payload["number"])))
		&"show_card":
			open_layer(&"show")
		&"continue_day":
			_morning_done_day = int(_view.get("day_number", 0))
			_render()
		&"show_announcement":
			open_layer(&"announcement")
		&"morning_details":
			open_layer(&"morning")
		&"override_shown":
			_ask_override()
		&"end_night":
			_submit(s.end_night)
		&"confirm_win":
			var r := DialogRequest.create("ui.cockpit.dialog.confirm_win.title", "ui.cockpit.dialog.confirm_win.message", "ui.cockpit.dialog.confirm_win.confirm",
				func() -> void: _submit(s.confirm_win.bind(int(payload["candidate_id"]))))
			dialog_requested.emit(r)
		&"reject_win":
			_ask_reason("ui.cockpit.dialog.reject_win.title", "ui.cockpit.dialog.reject_win.message", "ui.cockpit.dialog.reject_win.confirm",
				func(reason: String) -> void: _submit(s.reject_win.bind(reason)))


## Sendet genau einen Befehl; die Karte ist bis zur neuen Sicht gesperrt (Mehrfachtippen).
func _submit(action: Callable) -> void:
	_card.lock()
	var result: CommandResult = action.call()
	if result == null or not result.ok:
		_render()


func _on_rejected(error: StringName) -> void:
	var key := "ui.cockpit.error.%s" % String(error)
	_error_key = key if CockpitText.has_key(key) else "ui.cockpit.error.generic"
	status_message_requested.emit(_error_key)


func _ask_reason(title_key: String, message_key: String, confirm_key: String, on_text: Callable) -> void:
	dialog_requested.emit(DialogRequest.with_input(title_key, message_key, confirm_key, "ui.cockpit.dialog.reason_placeholder", on_text))


func _ask_override() -> void:
	var request := DialogRequest.create("ui.cockpit.dialog.override.title", "ui.cockpit.dialog.override.message", "")
	for role: StringName in RolePresentation.sorted_roles():
		var option := DialogOption.new()
		option.node_name = "Role_%s" % CockpitText.key_part(String(role))
		option.text_key = RolePresentation.name_key(role)
		option.on_select = func() -> void:
			_ask_reason.call_deferred("ui.cockpit.dialog.override_reason.title", "ui.cockpit.dialog.override_reason.message", "ui.cockpit.dialog.override_reason.confirm",
				func(reason: String) -> void: _submit(context.session.override_shown_role.bind(String(role), reason)))
		request.options.append(option)
	dialog_requested.emit(request)


# --- Ebenen: Protokoll, privater Bereich, gezeigte Karte, Sichtschutz -------------------------------

## Öffnet genau eine Ebene; ihr Inhalt entsteht erst jetzt aus der Anwendungsschicht.
func open_layer(kind: StringName) -> void:
	close_layer()
	if not bool(_view.get("has_game", false)):
		return
	match kind:
		&"private":
			_layer = CockpitLayers.private_drawer(context.session.private_seats(), context.session.secret_day_actions())
		&"gm":
			var undo := context.session.undo_info()
			_layer = CockpitLayers.gm_drawer({"undo": undo, "redo": context.session.redo_info(),
				"day": str((_view.get("next", {}) as Dictionary).get("kind")) == "day",
				"last_change": context.session.last_command_events().filter(func(e: Dictionary) -> bool: return str(e["type"]) != "PromptCancelled")
					if str(undo.get("type", "")) == "GmCorrection" else []}, _view.get("seats", []))
		&"log":
			_layer = CockpitLayers.log_drawer(context.session.event_log(), _view.get("seats", []))
		&"show":
			var next: Dictionary = _view.get("next", {})
			_layer = CockpitLayers.show_card(str(next.get("role_id", "")), next.get("show", []))
			_layout.visible = false  # die gezeigte Karte ersetzt das Cockpit vollständig
		&"roles":
			_layer = CockpitLayers.role_list(context.session.role_show_list())
			_layout.visible = false  # die neutrale Liste ersetzt das Cockpit vollständig
		&"notice":
			var notice: Dictionary = _view.get("next", {})
			if str(notice.get("kind")) == "notice":
				_layer = CockpitLayers.notice_card(notice)
				_layout.visible = false  # die Hinweiskarte ersetzt das Cockpit vollständig
		&"announcement":
			var report := context.session.morning_report()
			_layer = CockpitLayers.announcement(int(report.get("night_number", 0)), report.get("public", {}))
			_layout.visible = false
		&"morning":
			_layer = CockpitLayers.morning_drawer(context.session.morning_report(), _view.get("seats", []))
	if _layer == null:
		_layout.visible = true
		return
	_layer_kind = kind
	_overlay_host.add_child(_layer)
	var close := _layer.find_child("CloseLayerButton", true, false) as BaseButton
	if close != null:
		close.pressed.connect(close_layer)
		close.grab_focus()
	for b: Node in _layer.find_children("GmKind_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_start_gm_mode.bind(str(b.get_meta("gm_kind"))))
	for pair: Array in [["UndoButton", _ask_undo], ["RedoButton", _ask_redo], ["LeaveGameButton", _leave_game], ["DiscardGameButton", _ask_discard_game]]:
		var node := _layer.find_child(pair[0], true, false) as BaseButton
		if node != null:
			node.pressed.connect(pair[1])
	for b: Node in _layer.find_children("RolePerson_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_open_role_card.bind(int(b.get_meta("person_id")), false))
	_wire_role_card()
	for b: Node in _layer.find_children("SecretAction_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_on_secret_action.bind(str(b.get_meta("action")), int(b.get_meta("player_id"))))


# --- Rollenanzeige ------------------------------------------------------------------------------------------
# Liste (neutral) → Vorderseite (neutral, nur Name) → Rolle nach bewusster Aktion → Schließen zurück zur Liste. Nur „Gesehen“
# sendet ConfirmRoleShown. Die Karte mit Rolle entsteht erst beim Zeigen und wird bei jedem Zustandswechsel, Undo, Laden,
# Sichtschutz und Verlassen der Ansicht verworfen; die Liste schließt nie in einen privaten Bereich.

## Öffnet die Karte einer Person; `revealed` erst nach der bewussten Aktion.
func _open_role_card(person_id: int, revealed: bool) -> void:
	var card := context.session.role_show_card(person_id) if revealed else {}
	if not revealed:
		for entry: Dictionary in context.session.role_show_list().get("persons", []):
			if int(entry["person_id"]) == person_id:
				card = entry
	if card.is_empty():
		open_layer.call_deferred(&"roles")
		return
	close_layer()
	_layer = CockpitLayers.role_card(card, revealed)
	_layer_kind = &"role_card"
	_role_card_person = person_id
	_layout.visible = false
	_overlay_host.add_child(_layer)
	_wire_role_card()
	var first := _layer.find_children("*", "BaseButton", true, false)
	if not first.is_empty():
		(first[0] as Control).grab_focus()


func _wire_role_card() -> void:
	if _layer == null or _layer.name != "RoleCardLayer":
		return
	var reveal := _layer.find_child("RevealRoleButton", true, false) as BaseButton
	if reveal != null:
		reveal.pressed.connect(func() -> void: _open_role_card.call_deferred(_role_card_person, true))
	for button_name: String in ["CancelRoleButton", "CloseRoleButton", "CloseWithoutConfirmButton"]:
		var b := _layer.find_child(button_name, true, false) as BaseButton
		if b != null:
			b.pressed.connect(open_layer.bind(&"roles"), CONNECT_DEFERRED)
	var confirm := _layer.find_child("ConfirmRoleButton", true, false) as BaseButton
	if confirm != null:
		confirm.pressed.connect(_confirm_role.bind(_role_card_person), CONNECT_DEFERRED)


func _confirm_role(person_id: int) -> void:
	var result := context.session.confirm_role_shown(person_id)
	if not result.ok:
		open_layer(&"roles")  # bei Annahme erledigt das der Sichtwechsel (_discard_role_card)


## Zustandswechsel: eine offene Rollenkarte könnte veraltete Geheimnisse zeigen, deshalb zurück zur frisch gebauten neutralen Liste.
func _discard_role_card() -> void:
	if _layer_kind == &"role_card" or _layer_kind == &"roles":
		open_layer.call_deferred(&"roles")
		_layer_kind = &"roles"
		if _layer != null:
			_overlay_host.remove_child(_layer)
			_layer.queue_free()
			_layer = null


# --- Spielleitung: Korrekturen, Rückgängig, Partie beenden ---------------------------------------

func _start_gm_mode(kind: String) -> void:
	close_layer()
	_reset_day_mode()
	_reset_gm_mode()
	if kind == "execute":
		# Hinrichtung ohne Nominierung: jede lebende Person, dann dieselbe Prüfkarte wie am Tag.
		_gm_execute = true
	_gm_mode = kind
	_render()


func _confirm_gm_mode() -> void:
	var target := int(_selection[0]) if not _selection.is_empty() else -1
	match _gm_mode:
		"kill":
			_ask_correction({"kind": "kill", "target_id": target, "trigger_effects": bool(_gm_effects)})
		"revive":
			_ask_correction({"kind": "revive", "target_id": target})
		"set_role":
			_ask_correction({"kind": "set_role", "target_id": target, "role_id": _gm_role})
		"execute":
			_gm_mode = ""
			_preview = context.session.execution_preview(target)
			_day_mode = "execution_check"
			_check_revealed = true  # die Spielleitung hat die Korrektur bewusst geöffnet
			_render()


## „Status ändern“: Wert umschalten (bool) oder Rolle wählen (Scheinrolle), dann Rückfrage mit Begründung.
func _ask_status_field(index: int) -> void:
	var fields := context.session.status_fields(int(_selection[0]))
	if index >= fields.size():
		return
	var f: Dictionary = fields[index]
	var payload: Dictionary = (f["fields"] as Dictionary).duplicate()
	payload["kind"] = str(f["kind"])
	if str(f["type"]) == "action":
		_ask_correction(payload, TranslationServer.translate("ui.cockpit.dialog.gm.detail_from").format({"state": CockpitText.state_text(f.get("state", {}))}))
		return
	if str(f["type"]) == "pick":
		_ask_pick(payload, f)
		return
	if str(f["type"]) == "bool":
		payload[str(f["value_key"])] = not bool(f["current"])
		_ask_correction(payload)
		return
	var request := DialogRequest.create("ui.cockpit.dialog.gm_role.title", "ui.cockpit.dialog.gm_role.message", "")
	for role: StringName in RolePresentation.sorted_roles():
		var option := DialogOption.new()
		option.node_name = "Role_%s" % CockpitText.key_part(String(role))
		option.text_key = RolePresentation.name_key(role)
		option.on_select = func() -> void:
			var p := payload.duplicate()
			p[str(f["value_key"])] = String(role)
			_ask_correction.call_deferred(p)
		request.options.append(option)
	dialog_requested.emit(request)


func _ask_gm_role() -> void:
	var request := DialogRequest.create("ui.cockpit.dialog.gm_role.title", "ui.cockpit.dialog.gm_role.message", "")
	for role: StringName in RolePresentation.sorted_roles():
		var option := DialogOption.new()
		option.node_name = "Role_%s" % CockpitText.key_part(String(role))
		option.text_key = RolePresentation.name_key(role)
		option.on_select = func() -> void:
			_gm_role = String(role)
			_render()
		request.options.append(option)
	dialog_requested.emit(request)


## Zielwahl einer Spezialkorrektur: nur Personen, die der Regelkern als Ziel annimmt (`pick_ids`). Die Wahl gilt nur für den
## Zustand, in dem sie geöffnet wurde; ein Zustandswechsel dazwischen verwirft sie.
func _ask_pick(payload: Dictionary, field: Dictionary) -> void:
	var revision := context.session.state_hash()
	var request := DialogRequest.create("ui.cockpit.dialog.pick.title", "ui.cockpit.dialog.pick.message", "")
	request.message_values = {"what": StringName("ui.gm.kind.%s" % str(payload["kind"])),
		"person": CockpitText.names_of([int((field["fields"] as Dictionary).values()[0])], _view.get("seats", []))}
	for id: Variant in field["pick_ids"]:
		var seat := int(id)
		var option := DialogOption.new()
		option.node_name = "Pick_%d" % seat
		option.text_key = "ui.cockpit.roles.person"
		for entry: Dictionary in _view.get("seats", []):
			if int(entry["person_id"]) == seat:
				option.values = {"seat": int(entry["seat"]), "name": str(entry["name"])}
		option.on_select = func() -> void:
			if context.session.state_hash() != revision:
				status_message_requested.emit("ui.cockpit.status.stale_selection")
				_render()
				return
			var p := payload.duplicate()
			p[str(field["pick_key"])] = seat
			_ask_correction.call_deferred(p, TranslationServer.translate("ui.cockpit.dialog.gm.detail_to").format({"state": CockpitText.state_text(field.get("state", {})),
				"target": CockpitText.names_of([seat], _view.get("seats", []))}), revision)
		request.options.append(option)
	dialog_requested.emit(request)


## Warnung mit Pflichtbegründung; erst dann geht die Korrektur an den Regelkern. Danach zeigt die
## Ebene „Spielleitung“, was sich geändert hat. `detail` nennt Person und Wert (Spezialkorrekturen), `revision` den Zustand,
## für den die Rückfrage gilt (ein Zustandswechsel verwirft sie).
func _ask_correction(payload: Dictionary, detail: String = "", revision: String = "") -> void:
	revision = revision if revision != "" else context.session.state_hash()
	var subject := ""
	for key: String in ["guardian_id", "witch_id", "child_id", "apprentice_id"]:
		if payload.has(key):
			subject = CockpitText.names_of([int(payload[key])], _view.get("seats", []))
	var request := DialogRequest.with_input("ui.cockpit.dialog.gm.title", "ui.cockpit.dialog.gm.message" if subject == "" else "ui.cockpit.dialog.gm.message_detail",
		"ui.cockpit.dialog.gm.confirm", "ui.cockpit.dialog.reason_placeholder", func(reason: String) -> void:
			if context.session.state_hash() != revision:
				status_message_requested.emit("ui.cockpit.status.stale_selection")
				_render()
				return
			var p := payload.duplicate()
			p["reason"] = reason
			_reset_gm_mode()
			_reset_day_mode()
			_card.lock()
			var result := context.session.gm_correction(p)
			if result.ok:
				status_message_requested.emit("ui.cockpit.status.corrected")
				open_layer(&"gm")
			else:
				_render(), true)
	request.message_values = {"what": StringName("ui.gm.kind.%s" % str(payload["kind"])), "person": subject, "detail": detail}
	dialog_requested.emit(request)


func _ask_undo() -> void:
	var label := CockpitText.command_label(context.session.undo_info())
	var r := DialogRequest.create("ui.cockpit.dialog.undo.title", "ui.cockpit.dialog.undo.message", "ui.cockpit.dialog.undo.confirm", func() -> void:
		close_layer()
		if context.session.undo():
			status_message_requested.emit("ui.cockpit.status.undone"))
	r.message_values = {"what": CockpitLayers._format(label)}
	close_layer()
	dialog_requested.emit(r)


func _ask_redo() -> void:
	var label := CockpitText.command_label(context.session.redo_info())
	var r := DialogRequest.create("ui.cockpit.dialog.redo.title", "ui.cockpit.dialog.redo.message", "ui.cockpit.dialog.redo.confirm", func() -> void:
		if context.session.redo():
			status_message_requested.emit("ui.cockpit.status.redone"))
	r.message_values = {"what": CockpitLayers._format(label)}
	close_layer()
	dialog_requested.emit(r)


func _leave_game() -> void:
	close_layer()
	navigate_requested.emit(ScreenIds.MAIN_MENU)


## Beenden und verwerfen: Rückfrage (rot); die Dateien werden nur umbenannt, die Sitzung geleert.
func _ask_discard_game() -> void:
	close_layer()
	dialog_requested.emit(DialogRequest.create("ui.cockpit.dialog.discard.title", "ui.cockpit.dialog.discard.message", "ui.cockpit.dialog.discard.confirm",
		func() -> void:
			context.saves.discard(context.session.round_id())
			context.session.reset()
			status_message_requested.emit("ui.continue.status.discarded")
			navigate_requested.emit(ScreenIds.MAIN_MENU), true))


## Geheime Tagesaktionen aus dem privaten Bereich (Amalia, Nekromant). Der Bereich schließt zuerst.
func _on_secret_action(action: String, player_id: int) -> void:
	close_layer()
	match action:
		"amalia":
			var r := DialogRequest.create("ui.cockpit.dialog.amalia.title", "ui.cockpit.dialog.amalia.message", "ui.cockpit.dialog.amalia.yes",
				func() -> void: _submit(context.session.amalia_sacrifice.bind(player_id, true)))
			r.alternative_key = "ui.cockpit.dialog.amalia.no"
			r.on_alternative = func() -> void: _submit(context.session.amalia_sacrifice.bind(player_id, false))
			dialog_requested.emit(r)
		"name_wolf":
			_reset_day_mode()
			_necromancer = player_id
			_day_mode = "name_wolf"
			_render()


func close_layer() -> void:
	if _layer_kind == &"roles" or _layer_kind == &"role_card":
		_revealed_id = ""  # nach der Rollenanzeige bleibt keine geheime Karte des Cockpits aufgedeckt
	if _layer != null:
		_overlay_host.remove_child(_layer)
		_layer.queue_free()
	_layer = null
	_layer_kind = &""
	_layout.visible = not _covered


func layer_kind() -> StringName:
	return _layer_kind


## Sichtschutz: entfernt alle Ebenen, verdeckt Karten wieder und blendet das Cockpit aus.
func cover() -> void:
	if not bool(_view.get("has_game", false)):
		return
	close_layer()
	_revealed_id = ""
	_covered = true
	_layout.visible = false
	_layer = CockpitLayers.cover_panel()
	_layer_kind = &"cover"
	_overlay_host.add_child(_layer)
	var resume := _layer.find_child("UncoverButton", true, false) as BaseButton
	resume.pressed.connect(uncover)
	resume.grab_focus()


func uncover() -> void:
	_covered = false
	close_layer()
	_render()


func is_covered() -> bool:
	return _covered


func _exit_tree() -> void:
	close_layer()
