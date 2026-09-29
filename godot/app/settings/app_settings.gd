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
var left_handed: bool = false     ## Grundlage für spätere Spiegelung; noch ohne Wirkung


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


## Wendet die aktuelle Sprache an (App-Start).
func apply() -> void:
	TranslationServer.set_locale(language)
