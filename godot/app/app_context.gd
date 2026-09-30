class_name AppContext
extends RefCounted
## Gemeinsame Dienste der App, die die Shell jeder Ansicht übergibt (statt Autoloads):
## Einstellungen, Spielsitzung (Regelkern), Setup-Entwurf (ohne Regelkern) und Spielstände.
## Einstellungen werden nur mit `use_settings_store` dauerhaft gespeichert (die Shell tut das beim echten Start).
## Nach jedem angenommenen Befehl wird die Partie automatisch gespeichert (Checkpoint).

var settings: AppSettings
var session: GameSession
var setup: PlayerSetup  ## Setup-Entwurf „Neue Partie“, bleibt über Navigation und Sprachwechsel erhalten
var saves: SaveService
var groups: GroupStore  ## gespeicherte Spielergruppen; ohne Pfad nur im Speicher (die Shell setzt beim echten Start den Pfad)
var settings_store: SettingsStore = null  ## null = Einstellungen nur im Speicher (Tests, Screenshot-Werkzeug)


func _init(p_settings: AppSettings = null, p_session: GameSession = null) -> void:
	settings = p_settings if p_settings != null else AppSettings.new()
	session = p_session if p_session != null else GameSession.new()
	setup = PlayerSetup.new()
	saves = SaveService.new()
	groups = GroupStore.new()
	session.events_applied.connect(_on_events_applied)
	session.state_replaced.connect(autosave)


## Einstellungen dauerhaft machen: gespeicherte Werte laden und anwenden, danach jede Änderung speichern.
## Laden meldet keine Änderungen und schreibt nichts. Ergebnis wie SettingsStore.load_into.
func use_settings_store(store: SettingsStore) -> Dictionary:
	settings_store = store
	var status := store.load_into(settings)
	settings.apply()
	settings.changed.connect(_on_settings_changed)
	return status


## false, wenn das letzte Speichern der Einstellungen fehlgeschlagen ist (die Einstellung gilt trotzdem).
func settings_saved() -> bool:
	return settings_store == null or bool(settings_store.last_status.get("ok", true))


func _on_settings_changed(_key: StringName) -> void:
	settings_store.save(settings)


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
