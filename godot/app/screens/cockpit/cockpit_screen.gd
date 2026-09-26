class_name CockpitScreen
extends BaseScreen
## Struktureller Platzhalter des Spielleiter-Cockpits (02 §4.1): Kopfzeile, Phasenbereich,
## Ansagekarte, Sitzkreisbereich, Aktionsbereich. Liest nur die Sicht der Anwendungsschicht;
## ohne Partie zeigt es deutlich „Keine Partie aktiv“ und keine Rollen- oder Spielinformation.

@onready var _badge: Control = %NoGameBadge
@onready var _phase: GrimmLabel = %PhaseValueLabel
@onready var _instruction: GrimmLabel = %InstructionLabel


func _setup() -> void:
	(%SideColumn as Control).custom_minimum_size.x = ThemeTokens.SIDE_COLUMN_WIDTH
	context.session.view_changed.connect(_refresh)
	_refresh(context.session.view())


func _refresh(view: Dictionary) -> void:
	var active := bool(view.get("has_game", false))
	_badge.visible = not active
	_phase.text_key = "ui.phase.%s" % str(view.get("phase", "")).to_lower() if active else "ui.phase.none"
	_instruction.text_key = "ui.cockpit.instruction.active" if active else "ui.cockpit.instruction.no_game"
