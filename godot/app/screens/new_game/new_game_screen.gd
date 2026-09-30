class_name NewGameScreen
extends BaseScreen
## „Neue Partie“ als Setup-Wizard: Spieler → Rollen → Verteilung → Sitzordnung. Diese Ansicht ist
## nur der Host: Kopfzeile, Schrittanzeige und genau ein sichtbarer Schritt (PlayerStep, RoleStep,
## DistributionStep, SeatingStep). Welcher Schritt gilt und ob er erreichbar ist, entscheidet PlayerSetup
## (`go_to_step`); Schritte haben keine eigenen Screen-IDs und lassen sich nicht überspringen.
## Kein Schrittwechsel erzeugt einen Befehl, eine Partie oder einen GameState; nur „Partie starten“
## in der Sitzordnung startet über GameStart die Partie und öffnet danach das Cockpit.

const TITLE_KEYS := {
	&"players": "ui.setup.title",
	&"roles": "ui.setup.title.roles",
	&"distribution": "ui.setup.title.distribution",
	&"seating": "ui.setup.title.seating",
}

var _shown_step: StringName = &""
var _lexicon_layer: Control = null  ## offene Lexikon-Ebene (Rollenwahl), sonst null

@onready var _progress: WizardProgress = %WizardProgress
@onready var _player_step: PlayerStep = %PlayerStep
@onready var _role_step: RoleStep = %RoleStep
@onready var _distribution_step: DistributionStep = %DistributionStep
@onready var _seating_step: SeatingStep = %SeatingStep


func _setup() -> void:
	for step: Control in [_player_step, _role_step, _distribution_step, _seating_step]:
		step.connect(&"dialog_requested", dialog_requested.emit)
		step.connect(&"status_message_requested", status_message_requested.emit)
	_player_step.roles_requested.connect(_go_to.bind(&"roles"))
	_role_step.players_requested.connect(_go_to.bind(&"players"))
	_role_step.lexicon_requested.connect(open_lexicon)
	_distribution_step.roles_requested.connect(_go_to.bind(&"roles"))
	_distribution_step.seating_requested.connect(_go_to.bind(&"seating"))
	_seating_step.distribution_requested.connect(_go_to.bind(&"distribution"))
	_seating_step.start_requested.connect(_on_start_requested)
	_player_step.start(context.setup, context.groups)
	_role_step.start(context.setup)
	_distribution_step.start(context.setup)
	_seating_step.start(context.setup)
	context.setup.changed.connect(_on_setup_changed)
	_on_setup_changed(context.setup.view())


func default_focus() -> Control:
	return _current_step().call("default_focus") as Control


## Zurück, Escape und System-Zurück: erst der Schritt selbst (offener Modus, Auswahl),
## dann einen Schritt zurück; im Spielerschritt die Verlassen-Rückfrage wie bisher.
func handle_back() -> bool:
	if _lexicon_layer != null:
		close_lexicon()
		return true
	if bool(_current_step().call("handle_back")):
		return true
	match _shown_step:
		&"seating":
			_go_to(&"distribution")
			return true
		&"distribution":
			_go_to(&"roles")
			return true
		&"roles":
			_go_to(&"players")
			return true
	if not context.setup.needs_leave_confirmation():
		return false
	var request := DialogRequest.create("ui.setup.dialog.leave.title", "ui.setup.dialog.leave.message", "ui.setup.dialog.leave.discard", _discard_and_leave, true)
	request.cancel_key = "ui.setup.dialog.leave.continue"
	request.alternative_key = "ui.setup.dialog.leave.keep"
	request.on_alternative = navigate_requested.emit.bind(ScreenIds.MAIN_MENU)
	dialog_requested.emit(request)
	return true


## Lexikoneintrag als Ebene über dem Setup. Liest nur Übersetzungen und Katalog; Rollenwahl, Verteilung und
## Sitzordnung bleiben unverändert. Schließen und Zurück führen in denselben Setup-Zustand zurück.
func open_lexicon(role: StringName) -> void:
	close_lexicon()
	_lexicon_layer = RoleLexicon.layer(context.settings, role)
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


func _go_to(step: StringName) -> void:
	context.setup.go_to_step(step)


func _current_step() -> Control:
	match _shown_step:
		&"roles":
			return _role_step
		&"distribution":
			return _distribution_step
		&"seating":
			return _seating_step
	return _player_step


func _on_setup_changed(view: Dictionary) -> void:
	_progress.show_steps(view["steps"] as Array)
	var step := StringName(str(view["step"]))
	if step == _shown_step:
		return
	var first := _shown_step == &""
	_shown_step = step
	_player_step.visible = step == &"players"
	_role_step.visible = step == &"roles"
	_distribution_step.visible = step == &"distribution"
	_seating_step.visible = step == &"seating"
	header.title_key = TITLE_KEYS.get(step, "ui.setup.title")
	if not first and is_inside_tree():
		var target := default_focus()
		if target != null:
			_focus_later.call_deferred(target)


## Verzögerter Fokus nur, solange das Ziel noch angezeigt wird (nach dem Spielstart verlässt die
## Ansicht den Baum, bevor der Aufruf ausgeführt wird).
func _focus_later(target: Control) -> void:
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()


func _discard_and_leave() -> void:
	context.setup.reset()
	navigate_requested.emit(ScreenIds.MAIN_MENU)


func _on_start_requested() -> void:
	var result := GameStart.start(context.session, context.setup)
	if not bool(result["ok"]):
		_seating_step.show_start_failed(result["error"])
		return
	status_message_requested.emit("ui.setup.seating.toast.started")
	navigate_requested.emit(ScreenIds.COCKPIT)
