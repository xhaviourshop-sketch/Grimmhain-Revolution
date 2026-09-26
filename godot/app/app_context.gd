class_name AppContext
extends RefCounted
## Gemeinsame Dienste der App, die die Shell jeder Ansicht übergibt (statt Autoloads):
## Einstellungen, Spielsitzung (Regelkern) und Setup-Entwurf (ohne Regelkern).

var settings: AppSettings
var session: GameSession
var setup: PlayerSetup  ## Setup-Entwurf „Neue Partie“, bleibt über Navigation und Sprachwechsel erhalten


func _init(p_settings: AppSettings = null, p_session: GameSession = null) -> void:
	settings = p_settings if p_settings != null else AppSettings.new()
	session = p_session if p_session != null else GameSession.new()
	setup = PlayerSetup.new()
