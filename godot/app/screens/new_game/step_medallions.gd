class_name StepMedallions
extends HBoxContainer
## Die drei Schrittmedaillons der Vorbereitung (Runde, Namen, Rollen): Ring im Hain-Stil mit Ziffer, der aktuelle Schritt in Blutrot,
## erledigte in Mondsilber mit Häkchen, offene gedämpft. Der Zustand hängt nie nur an der Farbe (Ziffer, Häkchen, Beschriftung für
## Bedienungshilfe). Tippen springt nur zu erreichbaren Schritten zurück oder vor; was erreichbar ist, entscheidet PlayerSetup.
## Reine Darstellung der Sicht `steps`.

signal step_requested(step: StringName)

var _buttons: Dictionary[StringName, StepMedallion] = {}


func _init() -> void:
	name = "StepMedallions"
	add_theme_constant_override(&"separation", 0)
	alignment = BoxContainer.ALIGNMENT_CENTER
	for i: int in SetupDraft.STEPS.size():
		var id := SetupDraft.STEPS[i]
		if i > 0:
			var link := Control.new()
			link.name = "Link_%d" % i
			link.custom_minimum_size = Vector2(ThemeTokens.SPACE_L, ThemeTokens.MEDALLION_SIZE)
			link.mouse_filter = Control.MOUSE_FILTER_IGNORE
			link.draw.connect(func() -> void:
				link.draw_line(Vector2(0.0, link.size.y * 0.5), Vector2(link.size.x, link.size.y * 0.5), ThemeTokens.MOON_SILVER_DIM, 2.0, true))
			add_child(link)
		var medallion := StepMedallion.new()
		medallion.name = "Step_%s" % String(id)
		medallion.setup(id, i + 1)
		medallion.pressed.connect(func() -> void: step_requested.emit(id))
		add_child(medallion)
		_buttons[id] = medallion


func show_steps(steps: Array) -> void:
	for entry: Variant in steps:
		var step: Dictionary = entry
		var medallion := _buttons.get(StringName(str(step["id"])), null) as StepMedallion
		if medallion != null:
			medallion.show_state(str(step["state"]), bool(step["reachable"]))


func medallion(step: StringName) -> StepMedallion:
	return _buttons.get(step, null)
