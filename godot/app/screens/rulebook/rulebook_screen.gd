class_name RulebookScreen
extends BaseScreen
## Allgemeines Regelbuch aus dem Hauptmenü: Inhaltsverzeichnis und Kapitel ohne Bezug zu einer Partie.
## Zurück schließt zuerst ein geöffnetes Kapitel (zum Verzeichnis), dann zum Hauptmenü.

var rulebook: RuleBook = null

@onready var _host: Control = %RulebookHost


func _setup() -> void:
	rulebook = RuleBook.new(context.settings, false)
	rulebook.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_host.add_child(rulebook)


func handle_back() -> bool:
	if rulebook != null and rulebook.is_chapter_open():
		rulebook.show_toc()
		return true
	return false
