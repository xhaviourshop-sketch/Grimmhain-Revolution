class_name SettingsScreen
extends BaseScreen
## Einstellungen: Sprache (Deutsch/Englisch), Bewegung reduzieren, Effekte, Musik, Bedienhand und
## Anzeige (alles auf einem Bildschirm, ohne Scrollen). Wirkt sofort auf AppSettings; der AppContext speichert jede Änderung dauerhaft. Scheitert das
## Speichern, gilt die Einstellung trotzdem für diese Sitzung und die Meldung sagt das statt „geändert“.

@onready var _german: GrimmButton = %LanguageGermanButton
@onready var _english: GrimmButton = %LanguageEnglishButton
@onready var _motion: GrimmToggle = %ReducedMotionToggle
@onready var _effects: GrimmToggle = %EffectsToggle
@onready var _music: GrimmToggle = %MusicToggle
@onready var _quieter: GrimmButton = %MusicQuieterButton
@onready var _louder: GrimmButton = %MusicLouderButton
@onready var _level: GrimmLabel = %MusicLevelLabel
@onready var _hand_right: GrimmButton = %HandRightButton
@onready var _hand_left: GrimmButton = %HandLeftButton
@onready var _display: PanelContainer = %DisplayCard
var _calls: GrimmToggle = null  ## „Ansagen anzeigen“ (DA-101)


func _setup() -> void:
	var settings := context.settings
	_german.set_pressed_no_signal(settings.language == "de")
	_english.set_pressed_no_signal(settings.language == "en")
	_motion.set_pressed_no_signal(settings.reduced_motion)
	_music.set_pressed_no_signal(settings.music_enabled)
	_music.toggled.connect(_on_music_toggled)
	_quieter.pressed.connect(_on_volume_step.bind(-1))
	_louder.pressed.connect(_on_volume_step.bind(1))
	_show_volume()
	_german.toggled.connect(_on_language_toggled.bind("de"))
	_english.toggled.connect(_on_language_toggled.bind("en"))
	_motion.toggled.connect(_on_motion_toggled)
	_effects.set_pressed_no_signal(settings.effects_enabled)
	_effects.toggled.connect(_on_effects_toggled)
	_show_hand(settings.left_handed)
	_hand_right.toggled.connect(_on_hand_toggled.bind(false))
	_hand_left.toggled.connect(_on_hand_toggled.bind(true))
	_build_display(settings)


## Anzeige: oben die Rollen-Vorschau (Feedback 7, nur hier erreichbar), darunter der Schalter „Ansagen anzeigen“ mit kurzem Hinweis.
func _build_display(settings: AppSettings) -> void:
	var column := _display.get_node("Column") as VBoxContainer
	var preview := GrimmButton.new()
	preview.name = "RolePreviewButton"
	preview.kind = GrimmButton.Kind.SECONDARY
	preview.text_key = "ui.preview.open"
	preview.pressed.connect(func() -> void: navigate_requested.emit(ScreenIds.ROLE_PREVIEW))
	column.add_child(preview)
	_calls = GrimmToggle.new()
	_calls.name = "ShowCallsToggle"
	_calls.text_key = "ui.settings.display.calls"
	_calls.set_pressed_no_signal(settings.show_calls)
	_calls.toggled.connect(func(on: bool) -> void:
		context.settings.set_show_calls(on)
		_report("ui.settings.toast.calls_on" if on else "ui.settings.toast.calls_off"))
	column.add_child(_calls)
	var hint := GrimmLabel.new()
	hint.theme_type_variation = &"MutedLabel"
	hint.text_key = "ui.settings.display.calls_hint"
	column.add_child(hint)


func _on_language_toggled(pressed: bool, code: String) -> void:
	if pressed and context.settings.set_language(code):
		_report("ui.settings.toast.language")


func _on_music_toggled(pressed: bool) -> void:
	context.settings.set_music_enabled(pressed)
	_show_volume()
	_report("ui.settings.toast.music_on" if pressed else "ui.settings.toast.music_off")


func _on_volume_step(step: int) -> void:
	context.settings.set_music_volume(context.settings.music_volume + step)
	_show_volume()
	_report("ui.settings.toast.music_volume")


## Stufe in Worten; bei Musik aus sind beide Knöpfe gesperrt, an den Enden je einer.
func _show_volume() -> void:
	var settings := context.settings
	_level.text_key = "ui.settings.audio.level.%d" % settings.music_volume if settings.music_enabled else "ui.settings.audio.level.off"
	_quieter.disabled = not settings.music_enabled or settings.music_volume <= AppSettings.MUSIC_VOLUME_MIN
	_louder.disabled = not settings.music_enabled or settings.music_volume >= AppSettings.MUSIC_VOLUME_MAX


func _on_motion_toggled(pressed: bool) -> void:
	context.settings.set_reduced_motion(pressed)
	_report("ui.settings.toast.motion_on" if pressed else "ui.settings.toast.motion_off")


func _on_effects_toggled(pressed: bool) -> void:
	context.settings.set_effects_enabled(pressed)
	_report("ui.settings.toast.effects_on" if pressed else "ui.settings.toast.effects_off")


## Nur das gedrückte Ende der Gruppe zählt; die Auswahl ändert allein AppSettings.left_handed (kein Spielbefehl).
func _on_hand_toggled(pressed: bool, left: bool) -> void:
	if not pressed:
		return
	context.settings.set_left_handed(left)
	_show_hand(left)
	_report("ui.settings.toast.hand_left" if left else "ui.settings.toast.hand_right")


func _show_hand(left: bool) -> void:
	_hand_right.set_pressed_no_signal(not left)
	_hand_left.set_pressed_no_signal(left)


func _report(success_key: String) -> void:
	status_message_requested.emit(success_key if context.settings_saved() else "ui.settings.toast.save_failed")
