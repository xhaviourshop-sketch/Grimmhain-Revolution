class_name AppSettings
extends RefCounted
## Geräte- und Bedienpräferenzen (nicht Teil des Spielstands, 03 §4.1). Dauerhaft gespeichert über
## SettingsStore (AppContext.use_settings_store). Sprache wird sofort am TranslationServer gesetzt; alle
## Änderungen werden über `changed` gemeldet, damit die Shell Texte und Übergänge aktualisiert.

signal changed(key: StringName)

const LANGUAGES: Array[String] = ["de", "en"]
const DEFAULT_LANGUAGE := "de"

var language: String = DEFAULT_LANGUAGE
var reduced_motion: bool = false  ## schaltet Bildschirmübergänge und Einblendungen ab
var left_handed: bool = false     ## Bedienseite: true = Ansagekarte und Werkzeuge des Cockpits links vom Sitzkreis (NQ-04)
var show_night_timer: bool = true  ## Anzeige-Timer auch in der Nacht zeigen (DECISIONS.md, Ergänzung zur Timer-Entscheidung); nur Anzeige
var show_calls: bool = false  ## „Ansagen anzeigen“ (DA-101): Vorlesesatz klein auf der Nachtkarte; Standard aus, der Spielleiter spricht frei

var music_enabled: bool = true  ## „Musik“: Hintergrundmusik der Bildschirme; Standard an, auch für alte Stände ohne das Feld


## Setzt die Sprache. Nur unterstützte Sprachen; liefert false bei Ablehnung.
func set_language(code: String) -> bool:
	if not LANGUAGES.has(code):
		return false
	language = code
	TranslationServer.set_locale(code)
	changed.emit(&"language")
	return true


func set_reduced_motion(value: bool) -> void:
	if reduced_motion == value:
		return
	reduced_motion = value
	changed.emit(&"reduced_motion")


func set_left_handed(value: bool) -> void:
	if left_handed == value:
		return
	left_handed = value
	changed.emit(&"left_handed")


func set_show_night_timer(value: bool) -> void:
	if show_night_timer == value:
		return
	show_night_timer = value
	changed.emit(&"show_night_timer")


func set_show_calls(value: bool) -> void:
	if show_calls == value:
		return
	show_calls = value
	changed.emit(&"show_calls")


func set_music_enabled(value: bool) -> void:
	if music_enabled == value:
		return
	music_enabled = value
	changed.emit(&"music_enabled")


## Wendet die aktuelle Sprache an (App-Start).
func apply() -> void:
	TranslationServer.set_locale(language)
