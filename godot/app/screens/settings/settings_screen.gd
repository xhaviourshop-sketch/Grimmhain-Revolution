class_name SettingsScreen
extends BaseScreen
## Einstellungen: Sprache (Deutsch/Englisch), Bewegung reduzieren, Platzhalter für Audio und
## Anzeige. Wirkt sofort auf AppSettings; noch keine dauerhafte Speicherung.

@onready var _german: GrimmButton = %LanguageGermanButton
@onready var _english: GrimmButton = %LanguageEnglishButton
@onready var _motion: GrimmToggle = %ReducedMotionToggle


func _setup() -> void:
	var settings := context.settings
	_german.set_pressed_no_signal(settings.language == "de")
	_english.set_pressed_no_signal(settings.language == "en")
	_motion.set_pressed_no_signal(settings.reduced_motion)
	_german.toggled.connect(_on_language_toggled.bind("de"))
	_english.toggled.connect(_on_language_toggled.bind("en"))
	_motion.toggled.connect(_on_motion_toggled)


func _on_language_toggled(pressed: bool, code: String) -> void:
	if pressed and context.settings.set_language(code):
		status_message_requested.emit("ui.settings.toast.language")


func _on_motion_toggled(pressed: bool) -> void:
	context.settings.set_reduced_motion(pressed)
	status_message_requested.emit("ui.settings.toast.motion_on" if pressed else "ui.settings.toast.motion_off")
