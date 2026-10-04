class_name PrepStep
extends VBoxContainer
## Gemeinsame Basis der drei Schritte der Vorbereitung (Runde, Namen, Rollen). Ein Schritt stellt nur dar und ruft PlayerSetup auf;
## Kopfzeile, Medaillons und Fußzeile (Zurück, Weiter) gehören dem Host (NewGameScreen). Der Host fragt `footer()` nach der
## Beschriftung des Weiter-Knopfs und dem Hinweis und ruft `activate_next()` beim Tippen auf.

signal footer_changed
signal dialog_requested(request: DialogRequest)
signal status_message_requested(text_key: String)
signal lexicon_requested(role: StringName)

var _setup: PlayerSetup = null


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", ThemeTokens.SPACE_M)


## Fußzeile: {next_key, next_enabled, next_primary, hint_key, hint_values, hint_error}. Der Hinweis erklärt, warum Weiter gesperrt ist.
func footer() -> Dictionary:
	return {"next_key": "ui.prep.next", "next_enabled": false, "next_primary": true, "hint_key": "", "hint_values": {}, "hint_error": false}


func activate_next() -> void:
	pass


## Control, das beim Anzeigen den Tastaturfokus erhält.
func default_focus() -> Control:
	return null


## Zurück, Escape und System-Zurück: ein offener Unterzustand des Schritts schließt zuerst. false = nichts offen, der Host geht einen Schritt zurück.
func handle_back() -> bool:
	return false


## Der Host zeigt den Schritt an (nach dem Wechsel); hier Zustand auffrischen.
func entered() -> void:
	pass
