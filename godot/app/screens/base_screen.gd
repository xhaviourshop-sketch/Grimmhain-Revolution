class_name BaseScreen
extends Control
## Basis jeder Ansicht. Eine Ansicht kennt weder Router noch Shell: Sie meldet Wünsche über
## Signale und erhält die gemeinsamen Dienste über `setup(context)`. Hat die Szene eine
## Kopfzeile `%HeaderBar`, führt deren Zurück-Button über die zentrale Zurück-Logik der
## Shell (Signal `back_requested`) und erhält standardmäßig den Fokus.
## Ansichten richten sich in `_setup()` ein statt `_ready` zu überschreiben.

signal navigate_requested(screen_id: StringName)
signal back_requested
signal quit_requested
signal status_message_requested(text_key: String)

@export var screen_id: StringName = &""

var context: AppContext
var header: HeaderBar = null


## Wird vom Router vor dem Einhängen aufgerufen.
func setup(p_context: AppContext) -> void:
	context = p_context


func _ready() -> void:
	header = get_node_or_null("%HeaderBar") as HeaderBar
	if header != null:
		header.back_pressed.connect(back_requested.emit)
	_setup()


## Seitenspezifische Einrichtung.
func _setup() -> void:
	pass


## Control, das beim Anzeigen den Tastaturfokus erhält (oder null).
func default_focus() -> Control:
	return header.back_button() if header != null else null


## Zurück-Wunsch (Button, Escape, System-Zurück). true = von der Ansicht selbst erledigt.
func handle_back() -> bool:
	return false
