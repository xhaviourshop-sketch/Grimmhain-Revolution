class_name NewGameScreen
extends BaseScreen
## „Neue Partie“ als Vorbereitung in genau drei Schritten (Runde → Namen → Rollen) mit drei Medaillons oben, im Hain-Stil des Nachtbretts
## (abgedunkelter Nachthintergrund, Mondsilber, Blutrot nur für Aktives, kein Gold). Diese Ansicht ist nur der Host: Kopfzeile, Medaillons,
## genau ein sichtbarer Schritt (RoundStep, NamesStep, RolesStep) und die Fußzeile mit „Zurück“ und „Weiter“ (im letzten Schritt „Spiel
## starten“). Keine Bestätigungsknöpfe zwischen den Schritten; Zurück verliert nichts. Welcher Schritt gilt und ob er erreichbar ist,
## entscheidet PlayerSetup (`go_to_step`). Kein Schrittwechsel erzeugt einen Befehl oder einen GameState; nur „Spiel starten“ startet über
## GameStart die Partie und öffnet danach das Cockpit. Rückfragen zeigt ein eigener Dialog im Hain-Stil.

const TITLE_KEY := "ui.prep.title"
const FOOTER_BUTTON_MIN_WIDTH := 190  ## breit genug, dass kurze Texte frei von den Dornen-Enden stehen

var _shown_step: StringName = &""
var _steps: Dictionary[StringName, PrepStep] = {}
var _header_extras: Dictionary[StringName, Control] = {}  ## Kopfzeilen-Elemente der Schritte (z. B. Reiter der Rollen), nur beim eigenen Schritt sichtbar
var _medallions: StepMedallions = null
var _backdrop: HainBackdrop = null
var _dialog: ConfirmDialog = null
var _back: GrimmButton = null
var _hint: GrimmLabel = null
var _next: GrimmButton = null
var _lexicon_layer: Control = null  ## offene Lexikon-Ebene (Rollenwahl), sonst null

@onready var _content: VBoxContainer = %Content
@onready var _footer: HBoxContainer = %Footer


func _setup() -> void:
	_backdrop = HainBackdrop.new()
	add_child(_backdrop)
	move_child(_backdrop, 0)
	_backdrop.set_animated(not context.settings.reduced_motion)
	context.settings.changed.connect(_on_settings_changed)
	header.back_button().kind = GrimmButton.Kind.COMPACT
	GroveSkin.skin_back_button(header.back_button())
	header.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	header.title_key = TITLE_KEY
	(header.find_child("TitleLabel", true, false) as GrimmLabel).wrap = false  # der Titel bricht nie um, die Reiter nehmen den Rest
	_medallions = StepMedallions.new()
	_medallions.step_requested.connect(_on_medallion)
	(header.find_child("Actions", true, false) as Control).add_child(_medallions)
	header.back_button().set_meta(HainStyle.META, true)  # die Platte trägt den Pfeil, der Text bleibt unsichtbar
	HainStyle.apply(header)
	_build_steps()
	_build_footer()
	_dialog = (load("res://app/widgets/confirm_dialog/confirm_dialog.tscn") as PackedScene).instantiate() as ConfirmDialog
	_dialog.name = "PrepDialog"
	add_child(_dialog)
	HainStyle.apply(_dialog)
	context.setup.changed.connect(_on_setup_changed)
	_on_setup_changed(context.setup.view())


func default_focus() -> Control:
	return _current_step().default_focus()


## Zurück, Escape und System-Zurück: erst Dialog, Lexikon und der Schritt selbst (offener Modus, Rollenleiste, Zuordnung), dann einen
## Schritt zurück; im ersten Schritt die Verlassen-Rückfrage, sobald Namen erfasst sind.
func handle_back() -> bool:
	if _dialog.is_open():
		_dialog.cancel()
		return true
	if _lexicon_layer != null:
		close_lexicon()
		return true
	if _current_step().handle_back():
		return true
	match _shown_step:
		&"roles":
			_go_to(&"names")
			return true
		&"names":
			_go_to(&"round")
			return true
	if not context.setup.needs_leave_confirmation():
		return false
	var request := DialogRequest.create("ui.prep.leave.title", "ui.prep.leave.message", "ui.prep.leave.discard", _discard_and_leave, true)
	request.cancel_key = "ui.prep.leave.continue"
	request.alternative_key = "ui.prep.leave.keep"
	request.on_alternative = navigate_requested.emit.bind(ScreenIds.MAIN_MENU)
	_dialog.open_request(request)
	return true


## Lexikoneintrag als Ebene über der Vorbereitung. Liest nur Übersetzungen und Katalog; Schritte und Entwurf bleiben unverändert.
## Schließen und Zurück führen in denselben Zustand zurück.
func open_lexicon(role: StringName) -> void:
	close_lexicon()
	_lexicon_layer = RoleLexicon.layer(context.settings, role)
	GroveWindow.dress(_lexicon_layer)
	add_child(_lexicon_layer)
	var lexicon := _lexicon_layer.find_child("RoleLexicon", true, false) as RoleLexicon
	lexicon.close_requested.connect(close_lexicon)
	var close := _lexicon_layer.find_child("CloseLayerButton", true, false) as Control
	close.grab_focus()


func close_lexicon() -> void:
	if _lexicon_layer == null:
		return
	remove_child(_lexicon_layer)
	_lexicon_layer.queue_free()
	_lexicon_layer = null
	var target := default_focus()
	if target != null and target.is_visible_in_tree():
		target.grab_focus()


func lexicon_layer() -> Control:
	return _lexicon_layer


func dialog() -> ConfirmDialog:
	return _dialog


## Ein Dialog dieser Ansicht ist offen (die Shell verwirft dann weitere Anfragen, etwa zum Beenden).
func dialog_open() -> bool:
	return _dialog != null and _dialog.is_open()


func step(id: StringName) -> PrepStep:
	return _steps.get(id, null)


func shown_step() -> StringName:
	return _shown_step


# --- Aufbau ----------------------------------------------------------------------------------------------

func _build_steps() -> void:
	var round_step := RoundStep.new()
	round_step.animated = not context.settings.reduced_motion
	var names_step := NamesStep.new()
	var roles_step := RolesStep.new()
	_steps = {&"round": round_step, &"names": names_step, &"roles": roles_step}
	for id: StringName in _steps:
		var prep: PrepStep = _steps[id]
		_content.add_child(prep)
		prep.visible = false
		prep.dialog_requested.connect(_dialog_requested)
		prep.status_message_requested.connect(status_message_requested.emit)
		prep.footer_changed.connect(_refresh_footer.bind(id))
		prep.lexicon_requested.connect(open_lexicon)
	round_step.start(context.setup)
	names_step.start(context.setup, context.groups)
	roles_step.start(context.setup)
	var actions := header.find_child("Actions", true, false) as Control
	for id: StringName in _steps:
		var extra := _steps[id].header_extra()
		if extra != null:
			_header_extras[id] = extra
			actions.add_child(extra)
			actions.move_child(extra, 0)
	round_step.next_requested.connect(_go_to.bind(&"names"))
	names_step.next_requested.connect(_go_to.bind(&"roles"))
	roles_step.start_requested.connect(_on_start_requested)


func _build_footer() -> void:
	_back = GrimmButton.new()
	_back.name = "BackStepButton"
	_back.kind = GrimmButton.Kind.SECONDARY
	_back.text_key = "ui.common.back"
	_back.custom_minimum_size.x = FOOTER_BUTTON_MIN_WIDTH
	_back.pressed.connect(_on_back_pressed)
	_footer.add_child(_back)
	_hint = GrimmLabel.new()
	_hint.name = "FooterHint"
	_hint.theme_type_variation = &"HainMutedLabel"
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer.add_child(_hint)
	_next = GrimmButton.new()
	_next.name = "NextButton"
	_next.kind = GrimmButton.Kind.PRIMARY
	_next.text_key = "ui.prep.next"
	_next.custom_minimum_size.x = FOOTER_BUTTON_MIN_WIDTH
	_next.pressed.connect(_on_next_pressed)
	_footer.add_child(_next)
	HainStyle.apply(_footer)
	_footer.custom_minimum_size.y = ThemeTokens.FOOTER_HEIGHT


func _current_step() -> PrepStep:
	return _steps.get(_shown_step, _steps[&"round"])


func _dialog_requested(request: DialogRequest) -> void:
	_dialog.open_request(request)


func _go_to(step_id: StringName) -> void:
	context.setup.go_to_step(step_id)


func _on_medallion(step_id: StringName) -> void:
	_go_to(step_id)


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_next_pressed() -> void:
	if not _next.disabled:
		_current_step().activate_next()


func _on_settings_changed(key: StringName) -> void:
	if key == &"reduced_motion" and _backdrop != null:
		_backdrop.set_animated(not context.settings.reduced_motion)
		(_steps[&"round"] as RoundStep).animated = not context.settings.reduced_motion


func _on_setup_changed(view: Dictionary) -> void:
	_medallions.show_steps(view["steps"] as Array)
	var step_id := StringName(str(view["step"]))
	if step_id == _shown_step:
		return
	var first := _shown_step == &""
	_shown_step = step_id
	for id: StringName in _steps:
		_steps[id].visible = id == step_id
		if _header_extras.has(id):
			_header_extras[id].visible = id == step_id
	_steps[step_id].entered()
	_back.visible = step_id != &"round"
	_refresh_footer(step_id)
	if not first and is_inside_tree():
		var target := default_focus()
		if target != null:
			_focus_later.call_deferred(target)


## Fußzeile des angezeigten Schritts: Beschriftung und Zustand von „Weiter“, Hinweis (Fehler in Rosé, sonst gedämpft).
func _refresh_footer(step_id: StringName) -> void:
	if step_id != _shown_step:
		return
	var footer := _current_step().footer()
	_next.text_key = str(footer["next_key"])
	_next.disabled = not bool(footer["next_enabled"])
	var hint_key := str(footer["hint_key"])
	_hint.theme_type_variation = &"ErrorLabel" if bool(footer["hint_error"]) else &"HainMutedLabel"
	_hint.format_values = footer["hint_values"]
	_hint.text_key = hint_key


## Verzögerter Fokus nur, solange das Ziel noch angezeigt wird (nach dem Spielstart verlässt die Ansicht den Baum, bevor der Aufruf läuft).
func _focus_later(target: Control) -> void:
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()


func _discard_and_leave() -> void:
	context.setup.reset()
	navigate_requested.emit(ScreenIds.MAIN_MENU)


func _on_start_requested() -> void:
	var result := GameStart.start(context.session, context.setup)
	if not bool(result["ok"]):
		var error := StringName(result["error"])
		var reason := "other"
		if error == &"game_already_started":
			reason = "game_already_started"
		elif ["too_few_persons", "too_many_persons", "names_incomplete", "distribution_incomplete"].has(String(error)) or String(error).begins_with("too_") or String(error).begins_with("missing_"):
			reason = "setup_incomplete"
		_hint.theme_type_variation = &"ErrorLabel"
		_hint.format_values = {"code": String(error)}
		_hint.text_key = "ui.setup.seating.status.start_failed.%s" % reason
		return
	status_message_requested.emit("ui.setup.seating.toast.started")
	navigate_requested.emit(ScreenIds.COCKPIT)
