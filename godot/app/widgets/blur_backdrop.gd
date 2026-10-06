class_name BlurBackdrop
extends ColorRect
## Gemeinsamer Grund der Vollbildkarten (Karte zeigen, Rollenkarte): die Szene darunter, leicht unscharf und stark abgedunkelt, mit einem
## Hauch Nachtblau, statt einer flachen Farbe. Reine Dekoration ohne Mausfang. Liest die Bildschirmtextur (nur sichtbar mit echtem Renderer).

const SHADER := preload("res://app/widgets/blur_backdrop.gdshader")


func _init() -> void:
	name = "Dim"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("radius", ThemeTokens.CARD_BACKDROP_BLUR)
	mat.set_shader_parameter("darken", ThemeTokens.CARD_BACKDROP_LIGHT)
	mat.set_shader_parameter("tint", ThemeTokens.NIGHT_BACKDROP)
	material = mat
