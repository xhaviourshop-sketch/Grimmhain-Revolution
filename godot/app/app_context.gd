class_name AppContext
extends RefCounted
## Gemeinsame Dienste der App, die die Shell jeder Ansicht übergibt (statt Autoloads):
## Einstellungen, Spielsitzung (Regelkern), Setup-Entwurf (ohne Regelkern) und Spielstände.
## Nach jedem angenommenen Befehl wird die Partie automatisch gespeichert (Checkpoint).

var settings: AppSettings
var session: GameSession
var setup: PlayerSetup  ## Setup-Entwurf „Neue Partie“, bleibt über Navigation und Sprachwechsel erhalten
var saves: SaveService


func _init(p_settings: AppSettings = null, p_session: GameSession = null) -> void:
	settings = p_settings if p_settings != null else AppSettings.new()
	session = p_session if p_session != null else GameSession.new()
	setup = PlayerSetup.new()
	saves = SaveService.new()
	session.events_applied.connect(_on_events_applied)
	session.state_replaced.connect(autosave)


func _on_events_applied(_events: Array[GameEvent]) -> void:
	autosave()


## Speichert die laufende Partie; Ergebnis wie SaveService.save. Ohne Partie nichts.
func autosave() -> Dictionary:
	if session.round_id() == "":
		return {}
	return saves.save(session.round_id(), session.save_text(), session.summary())


## Lädt eine gespeicherte Partie in die Sitzung. Ergebnis wie SaveService.load_game, bei Erfolg
## zusätzlich ohne Fehler übernommen.
func resume(round_id: String) -> Dictionary:
	var loaded := saves.load_game(round_id)
	if not bool(loaded["ok"]):
		return loaded
	var error := session.load_text(str(loaded["core"]))
	if error != &"":
		return {"ok": false, "error": String(error)}
	return loaded
