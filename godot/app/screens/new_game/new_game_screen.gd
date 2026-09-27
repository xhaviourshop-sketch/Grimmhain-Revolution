class_name NewGameScreen
extends BaseScreen
## „Neue Partie“ als Setup-Wizard: Spieler → Rollen → Verteilung. Diese Ansicht ist nur der
## Host: Kopfzeile, Schrittanzeige und genau ein sichtbarer Schritt (PlayerStep, RoleStep,
## DistributionStep). Welcher Schritt gilt und ob er erreichbar ist, entscheidet PlayerSetup
## (`go_to_step`); Schritte haben keine eigenen Screen-IDs und lassen sich nicht überspringen.
## Kein Schrittwechsel erzeugt einen Befehl, eine Partie oder einen GameState.

const TITLE_KEYS := {
	&"players": "ui.setup.title",
	&"roles": "ui.setup.title.roles",
	&"distribution": "ui.setup.title.distribution",
}

var _shown_step: StringName = &""

@onready var _progress: WizardProgress = %WizardProgress
@onready var _player_step: PlayerStep = %PlayerStep
@onready var _role_step: RoleStep = %RoleStep
@onready var _distribution_step: DistributionStep = %DistributionStep


func _setup() -> void:
	for step: Control in [_player_step, _role_step, _distribution_step]:
		step.connect(&"dialog_requested", dialog_requested.emit)
		step.connect(&"status_message_requested", status_message_requested.emit)
	_player_step.roles_requested.connect(_go_to.bind(&"roles"))
	_role_step.players_requested.connect(_go_to.bind(&"players"))
	_distribution_step.roles_requested.connect(_go_to.bind(&"roles"))
	_player_step.start(context.setup)
	_role_step.start(context.setup)
	_distribution_step.start(context.setup)
	context.setup.changed.connect(_on_setup_changed)
	_on_setup_changed(context.setup.view())


func default_focus() -> Control:
	return _current_step().call("default_focus") as Control


## Zurück, Escape und System-Zurück: erst der Schritt selbst (offener Modus, Auswahl),
## dann einen Schritt zurück; im Spielerschritt die Verlassen-Rückfrage wie bisher.
func handle_back() -> bool:
	if bool(_current_step().call("handle_back")):
		return true
	match _shown_step:
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


func _go_to(step: StringName) -> void:
	context.setup.go_to_step(step)


func _current_step() -> Control:
	match _shown_step:
		&"roles":
			return _role_step
		&"distribution":
			return _distribution_step
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
	header.title_key = TITLE_KEYS.get(step, "ui.setup.title")
	if not first and is_inside_tree():
		var target := default_focus()
		if target != null:
			target.grab_focus.call_deferred()


func _discard_and_leave() -> void:
	context.setup.reset()
	navigate_requested.emit(ScreenIds.MAIN_MENU)
