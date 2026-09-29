class_name LexiconScreen
extends BaseScreen
## Rollenlexikon aus dem Hauptmenü: allgemeine Einträge aller Katalogrollen ohne Bezug zu einer Partie.
## Zurück schließt zuerst einen geöffneten Eintrag (zur Liste), dann zum Hauptmenü.

var lexicon: RoleLexicon = null

@onready var _host: Control = %LexiconHost


func _setup() -> void:
	lexicon = RoleLexicon.new(context.settings, false)
	lexicon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_host.add_child(lexicon)


func handle_back() -> bool:
	if lexicon != null and lexicon.is_entry_open():
		lexicon.show_list()
		return true
	return false
