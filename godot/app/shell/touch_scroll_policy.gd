class_name TouchScrollPolicy
extends Node
## Touch-Scrollen global: Jede ScrollContainer-Fläche lässt sich mit dem Finger irgendwo ziehen, auch über Knöpfen
## und Karten. Godot reicht ein Ziehen nur dann an den ScrollContainer weiter, wenn die berührte Fläche den Klick
## nicht selbst verbraucht (mouse_filter STOP). Darum werden alle verbrauchenden Flächen innerhalb eines
## ScrollContainers auf PASS gestellt: Der Knopf reagiert weiter auf Tippen, das Ziehen erreicht den Container und
## bricht beim Überschreiten der Totzone ein angefangenes Tippen ab (Godot: NOTIFICATION_SCROLL_BEGIN).
## Der Container gleitet nach dem Loslassen von selbst weiter. Gilt für neue wie vorhandene Knoten, ohne
## Eingriffe in einzelne Ansichten und ohne Plattformcode.

## Eingabeelemente mit eigener Ziehgeste bleiben unverändert.
const _OWN_DRAG: Array[String] = ["ScrollBar", "Slider", "TextEdit", "LineEdit", "ItemList", "Tree"]


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_visit(get_parent())


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func _visit(node: Node) -> void:
	_on_node_added(node)
	for child: Node in node.get_children():
		_visit(child)


func _on_node_added(node: Node) -> void:
	if node is ScrollContainer:
		(node as ScrollContainer).scroll_deadzone = ThemeTokens.TOUCH_DRAG_DEADZONE
	if node is Control and is_inside_scroll(node):
		adopt(node as Control)


## Stellt eine verbrauchende Fläche auf PASS (Eingabeelemente mit eigener Ziehgeste ausgenommen).
static func adopt(control: Control) -> void:
	if control.mouse_filter != Control.MOUSE_FILTER_STOP:
		return
	for own: String in _OWN_DRAG:
		if control.is_class(own):
			return
	control.mouse_filter = Control.MOUSE_FILTER_PASS


static func is_inside_scroll(node: Node) -> bool:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false
