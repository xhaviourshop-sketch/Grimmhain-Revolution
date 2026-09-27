class_name WizardProgress
extends HFlowContainer
## Schrittanzeige des Setup-Wizards: „Schritt 2 von 3: Rollen“ und je Schritt ein Textchip
## „1. Spieler · erledigt“. Zustand steht immer als Text im Chip (nicht nur als Farbe); der
## aktuelle Schritt ist zusätzlich hervorgehoben. Reine Darstellung der Sicht `steps`.
## Fließlayout: bei langen Texten oder schmalen Fenstern rutschen Chips in die nächste Zeile.

const STATE_VARIATIONS := {
	"done": &"MutedLabel",
	"open": &"CaptionLabel",
	"invalid": &"WarningLabel",
}

var _steps: Array = []

@onready var _step_label: GrimmLabel = %StepLabel


func _ready() -> void:
	add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_L)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_render()


func show_steps(steps: Array) -> void:
	_steps = steps.duplicate(true)
	_render()


func _render() -> void:
	for entry: Variant in _steps:
		var step: Dictionary = entry
		var id := str(step["id"])
		var name := tr("ui.setup.wizard.step.%s" % id)
		var chip := get_node_or_null("StepChip_%s" % id) as GrimmLabel
		if chip == null:
			continue
		chip.format_values = {"number": step["number"], "name": name, "state": tr("ui.setup.wizard.state.%s" % str(step["state"]))}
		chip.text_key = "ui.setup.wizard.chip"
		chip.theme_type_variation = &"BadgeLabel" if bool(step["current"]) else STATE_VARIATIONS.get(str(step["state"]), &"CaptionLabel")
		if bool(step["current"]):
			_step_label.format_values = {"current": step["number"], "total": _steps.size(), "name": name}
			_step_label.text_key = "ui.setup.wizard.progress"
