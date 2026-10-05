class_name DiceRow
extends HBoxContainer
## Sichtbare virtuelle Würfel (Phoenix, Chaosgeist): jede Würfelfläche zeigt die Augen gezeichnet und zusätzlich als Zahl,
## damit das Ergebnis auch ohne Bild lesbar ist. Reine Darstellung: Die Würfe stammen aus dem Prompt des Regelkerns
## (gespeichert, nie neu gewürfelt); die Oberfläche würfelt nie selbst.

const FACE_SIZE := 88.0
const PIP_RADIUS := 7.0

## Augenmuster je Wert in einem 3×3-Raster (Spalte, Zeile).
const PIPS := {
	1: [Vector2i(1, 1)],
	2: [Vector2i(0, 0), Vector2i(2, 2)],
	3: [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)],
	4: [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(2, 2)],
	5: [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(2, 2)],
	6: [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(2, 2)],
}


func _init() -> void:
	name = "DiceRow"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)


## Zeigt die Würfe; ein leerer Wurf (noch nicht gewürfelt) zeigt nichts.
func show_dice(values: Array) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	for i: int in values.size():
		var face := DiceFace.new()
		face.value = clampi(int(values[i]), 1, 6)
		face.tooltip_text = str(face.value)
		face.name = "Die_%d" % i
		add_child(face)


class DiceFace extends Control:
	var value: int = 1

	func _init() -> void:
		custom_minimum_size = Vector2(DiceRow.FACE_SIZE, DiceRow.FACE_SIZE)
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Würfelfläche: dunkle Tafel aus dem Skin (kein Kasten); die Augen sind mondsilbern.
		var face := SkinArt.texture("tafel_grund")
		if face != null:
			draw_texture_rect(face, Rect2(Vector2.ZERO, size), false)
		var pad := size.x * 0.22
		var step := (size.x - pad * 2.0) / 2.0
		for cell: Vector2i in DiceRow.PIPS[value]:
			draw_circle(Vector2(pad + cell.x * step, pad + cell.y * step), DiceRow.PIP_RADIUS, ThemeTokens.MOON_SILVER_BRIGHT)
		# Zahl zusätzlich als Text (Lesbarkeit ohne Bild, Screenreader über den Tooltip).
		draw_string(ThemeDB.fallback_font, Vector2(size.x - 22.0, size.y - 8.0), str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeTokens.FONT_CAPTION, ThemeTokens.MOON_SILVER)
