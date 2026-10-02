class_name HistoryScreen
extends BaseScreen
## Partiehistorie aus dem Hauptmenü (und über „Abschlussbericht öffnen“ am Spielende im Cockpit): Liste der abgeschlossenen Partien
## und ihr Abschlussbericht, lesbar ohne aktive Partie. Zurück schließt zuerst den Bericht (zur Liste), dann zum Hauptmenü.

var view: HistoryView = null

@onready var _host: Control = %HistoryHost


func _setup() -> void:
	view = HistoryView.new(context)
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.dialog_requested.connect(dialog_requested.emit)
	_host.add_child(view)
	var focus := context.history_focus
	context.history_focus = ""
	if focus != "":
		context.sync_history()  # scheiterte das Speichern beim Spielende, gibt es hier einen neuen Versuch
		if context.history.has(focus):
			view.open_report(focus)
		else:
			view.show_save_failed()


func handle_back() -> bool:
	if view != null and view.is_report_open():
		view.show_list()
		return true
	return false
