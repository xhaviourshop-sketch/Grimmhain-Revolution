class_name HainStyle
extends RefCounted
## Überzieht Bauteile der Vorbereitung mit dem Hain-Stil des Nachtbretts: Hauptknöpfe (Rubinstein; Knopf- und Kartenflächen kommen aus dem Theme),
## Eingabefelder und Beschriftungen in Mondsilber. Gold gibt es hier nicht (DA-89). Wirkt rekursiv und auch auf später
## eingehängte Kinder (`watch`), damit wiederverwendete Bauteile (Namensprüfliste, gespeicherte Gruppen) ohne eigene Umbauten passen.
## Jeder Knoten wird höchstens einmal behandelt; ohne Bilddatei bleibt der Theme-Stil stehen.

const META := &"hain_styled"
## Beschriftungen: Theme-Variation → Hain-Variation (Gold und Warnfarbe entfallen).
const LABELS := {
	&"SectionLabel": &"HainSectionLabel",
	&"HeadingLabel": &"HainHeadingLabel",
	&"MutedLabel": &"HainMutedLabel",
	&"CaptionLabel": &"HainCaptionLabel",
	&"WarningLabel": &"HainLabel",
	&"BadgeLabel": &"HainCaptionLabel",
	&"": &"HainLabel",
}


## Behandelt `root` samt allen Kindern und beobachtet spätere Kinder.
static func apply(root: Node) -> void:
	_style(root)
	if not root.has_meta(&"hain_watched"):
		root.set_meta(&"hain_watched", true)
		root.child_entered_tree.connect(func(child: Node) -> void: apply(child))
	for child: Node in root.get_children():
		apply(child)


static func _style(node: Node) -> void:
	if node.has_meta(META):
		return
	node.set_meta(META, true)
	if node is GrimmButton and (node.get_script() as Script).get_global_name() == &"GrimmButton":  # Unterklassen zeichnen selbst
		var button := node as GrimmButton
		if button.toggle_mode:
			return  # Listeneinträge (gespeicherte Gruppen) behalten die ruhige Theme-Fläche, die Wahl zeigt der gedrückte Zustand
		if button.theme_type_variation == &"" or button.kind in [GrimmButton.Kind.PRIMARY, GrimmButton.Kind.SECONDARY, GrimmButton.Kind.DANGER, GrimmButton.Kind.COMPACT]:
			GroveSkin.skin_button(button, button.kind == GrimmButton.Kind.PRIMARY)
			button.wrap = false
	elif node is Label:
		var label := node as Label
		if LABELS.has(label.theme_type_variation) and not label.has_meta(&"keep_style"):
			label.theme_type_variation = LABELS[label.theme_type_variation]
	elif node is LineEdit or node is TextEdit:
		(node as Control).theme_type_variation = &"HainLineEdit" if node is LineEdit else &"HainTextEdit"
