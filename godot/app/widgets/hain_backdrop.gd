class_name HainBackdrop
extends Control
## Nachthintergrund der Vorbereitung im Hain-Stil: das Dorfbild des Nachtbretts, stark abgedunkelt, mit Nebel und Randdämpfung. Reine
## Dekoration hinter allen Bedienflächen (kein Mausfang). Fehlt das Bild, bleibt die dunkle Fläche. Bei reduzierter Bewegung steht der Nebel still.

const ART := "bg/village-night.webp"

var _fog: ColorRect = null


func _init() -> void:
	name = "HainBackdrop"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true


func _ready() -> void:
	var base := ColorRect.new()
	base.name = "BackdropBase"
	base.color = ThemeTokens.NIGHT_BACKDROP
	_fill(base)
	var art := TextureRect.new()
	art.name = "BackdropArt"
	art.texture = NightArt.texture(ART)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fill(art)
	_fog = ColorRect.new()
	_fog.name = "BackdropFog"
	var fog := ShaderMaterial.new()
	fog.shader = load("res://app/theme/night_fog.gdshader") as Shader
	_fog.material = fog
	_fill(_fog)
	var shade := ColorRect.new()
	shade.name = "BackdropShade"
	shade.color = ThemeTokens.PREP_SHADE
	_fill(shade)
	var vignette := ColorRect.new()
	vignette.name = "BackdropVignette"
	var edge := ShaderMaterial.new()
	edge.shader = load("res://app/theme/night_vignette.gdshader") as Shader
	vignette.material = edge
	_fill(vignette)


## Nebel ziehen lassen (true) oder stehen lassen (reduzierte Bewegung).
func set_animated(animated: bool) -> void:
	if _fog != null:
		(_fog.material as ShaderMaterial).set_shader_parameter("animate", 1.0 if animated else 0.0)


func _fill(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(node)
