class_name DialogRequest
extends RefCounted
## Eine Rückfrage an ConfirmDialog: Texte nur als Übersetzungsschlüssel (Nachricht mit
## Platzhaltern aus `message_values`), bis zu drei Aktionen mit eigenen Rückrufen.
##   cancel       sichere Vorgabe, links, erhält den Fokus; auch Escape und System-Zurück
##   alternative  optionale mittlere Aktion (z. B. „Entwurf behalten“)
##   confirm      rechts, abgesetzt; mit `confirm_danger` rot (destruktiv); leerer
##                `confirm_key` = keine Bestätigungsaktion (reine Auswahl)
##   options      optionale Auswahlliste (DialogOption) über den Aktionen, scrollbar; eine
##                gewählte Option schließt den Dialog und ruft ihren Rückruf
##   input        mit `input_placeholder_key` ein Pflicht-Textfeld (z. B. Begründung): Bestätigen
##                ist erst mit nicht leerem Text möglich und ruft `on_confirm_text(text)`

var title_key: String = ""
var message_key: String = ""
var message_values: Dictionary = {}
var title_values: Dictionary = {}  ## Platzhalter im Titel (z. B. Listennummer); nie eine Rolle
var confirm_key: String = ""
var cancel_key: String = "ui.common.cancel"
var alternative_key: String = ""
var confirm_danger: bool = false
var on_confirm: Callable = Callable()
var on_cancel: Callable = Callable()
var on_alternative: Callable = Callable()
var options: Array[DialogOption] = []
var input_placeholder_key: String = ""
var on_confirm_text: Callable = Callable()


## Rückfrage mit Pflicht-Textfeld; `on_text` erhält den getrimmten Text.
static func with_input(p_title_key: String, p_message_key: String, p_confirm_key: String, p_placeholder_key: String, p_on_text: Callable, p_danger: bool = false) -> DialogRequest:
	var r := create(p_title_key, p_message_key, p_confirm_key, Callable(), p_danger)
	r.input_placeholder_key = p_placeholder_key
	r.on_confirm_text = p_on_text
	return r


static func create(p_title_key: String, p_message_key: String, p_confirm_key: String, p_on_confirm: Callable = Callable(), p_danger: bool = false) -> DialogRequest:
	var r := DialogRequest.new()
	r.title_key = p_title_key
	r.message_key = p_message_key
	r.confirm_key = p_confirm_key
	r.on_confirm = p_on_confirm
	r.confirm_danger = p_danger
	return r
