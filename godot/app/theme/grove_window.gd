class_name GroveWindow
extends RefCounted
## Gemeinsamer Baustein für alle Fenster (Feedback 5, Feedback 8): gekachelter Grund im Dornenrahmen (Theme, SkinWindowBox) und
## Hauptknöpfe mit Rubinstein. Die Fläche kommt aus dem Theme; `frame` setzt nur den Textabstand eines Fensters, `dress` tut das für alle
## bekannten Fensterflächen unter einem Knoten und markiert die Hauptknöpfe. Mehrfaches Anwenden ist unschädlich.

## Fensterflächen des Themes, die den Rahmen tragen (Rückfragen, Schubladen, gezeigte Karten, Rollenliste).
const FRAMED_VARIATIONS: Array[StringName] = [&"DialogPanel", &"DrawerPanel", &"ShowPanel"]
const INSET_DEFAULT := Vector4(48.0, 36.0, 48.0, 36.0)  ## Textabstand im Rahmen (links, oben, rechts, unten)
const INSET_SIDE := Vector4(36.0, 28.0, 36.0, 28.0)  ## Schubladen und große Lesefenster


## Dornenrahmen um `panel`; `inset` ist der Textabstand zum Rahmen.
static func frame(panel: PanelContainer, inset: Vector4 = INSET_DEFAULT) -> void:
	if panel.has_theme_stylebox_override(&"panel"):
		return
	var box := SkinArt.window_box()
	box.content_margin_left = inset.x
	box.content_margin_top = inset.y
	box.content_margin_right = inset.z
	box.content_margin_bottom = inset.w
	panel.add_theme_stylebox_override(&"panel", box)


## Rahmt alle Fensterflächen unter `root` (und `root` selbst) und zieht alle Knöpfe im Hain-Stil an.
static func dress(root: Node) -> void:
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	for node: Node in nodes:
		if node is PanelContainer and (node as PanelContainer).theme_type_variation in FRAMED_VARIATIONS:
			frame(node as PanelContainer, INSET_SIDE if (node as PanelContainer).theme_type_variation == &"DrawerPanel" else INSET_DEFAULT)
		elif node is RoleLexicon or node is RuleBook:
			frame(node as PanelContainer, INSET_SIDE)
		elif node is GrimmButton:
			_skin(node as GrimmButton)


static func _skin(button: GrimmButton) -> void:
	if button is GlyphButton or button is GameSeatToken or button.toggle_mode or button.alignment != HORIZONTAL_ALIGNMENT_CENTER or button.has_meta(&"grove_skinned"):
		return
	button.set_meta(&"grove_skinned", true)
	GroveSkin.skin_button(button, button.kind == GrimmButton.Kind.PRIMARY or button.kind == GrimmButton.Kind.DANGER)
