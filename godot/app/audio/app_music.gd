class_name AppMusic
extends Node
## Durchgehende Musik der ganzen App (Feedback 10): Startmusik in allen Menüs und der Vorbereitung ohne Neustart beim Bildschirmwechsel,
## Nachtmusik in der Nacht einer laufenden Partie (Kreuzblende), Stille am Tag, in der Morgendämmerung, am Spielende und bei „Musik“ aus.
## Ton startet erst nach der ersten Berührung (Browser-Regel); die Eingabe wird dabei nicht verbraucht. In der Nacht heult leise ein
## Wolf (links/rechts im Wechsel), wenn Dateien in `HOWL_DIR` liegen. Zufall nur über den eigenen Generator hier, nie über den
## gespeicherten der Partie. Keine Wirkung auf den Spielzustand. Ohne Dateien bleibt alles still.

const START_PATH := "res://assets/audio/musik-start.ogg"
const NIGHT_PATH := "res://assets/audio/musik-nacht.ogg"
const HOWL_DIR := "res://assets/audio/heulen/"
const HOWL_BUS := &"AppHowl"
const HOWL_EXTENSIONS: Array[String] = ["ogg", "wav", "mp3"]

const TRACK_NONE := &""
const TRACK_START := &"start"
const TRACK_NIGHT := &"night"

const SILENT_DB := -60.0
const VOLUME_DB: Array[float] = [-28.0, -21.0, -14.0, -10.0, -7.0]  ## Stufe 1 bis 5; Stufe 3 = bisheriger Wert, unter der Stimme
const HOWL_DB := -24.0
const HOWL_JITTER_DB := 3.0  ## Lautstärke schwankt leicht um HOWL_DB
const HOWL_FAR_DB := -8.0  ## Dateien mit „fern“ im Namen sind immer leiser
const HOWL_PITCH_MIN := 0.9
const HOWL_PITCH_MAX := 1.1
const HOWL_PAN := 0.8
const HOWL_MIN_SECONDS := 30.0
const HOWL_MAX_SECONDS := 90.0
const CROSSFADE_SECONDS := 3.5
const LEVEL_SECONDS := 0.3

## Liefert die Heulen als Array[AudioStream]. Standard: die Dateien aus HOWL_DIR (Tests setzen eigene).
var howl_source: Callable = Callable(self, "_load_howl_streams")

var _context: AppContext = null
var _screen: StringName = &""
var _phase: String = ""
var _unlocked := false
var _current: StringName = TRACK_NONE
var _players: Dictionary = {}  ## Titel -> AudioStreamPlayer
var _tweens: Dictionary = {}   ## Titel -> Tween
var _rng := RandomNumberGenerator.new()
var _howl_timer: Timer = null
var _howl_player: AudioStreamPlayer = null
var _howl_panner: AudioEffectPanner = null
var _howl_right := false
var _howl_count := 0
var _howl_last: AudioStream = null
var _howl_last_db := 0.0
var _howl_last_pitch := 1.0


func setup(context: AppContext, router: ScreenRouter) -> void:
	_context = context
	_rng.randomize()
	_screen = router.current_id()
	_phase = str(context.session.view().get("phase", ""))
	router.screen_changed.connect(_on_screen_changed)
	context.session.view_changed.connect(_on_view_changed)
	context.settings.changed.connect(_on_settings_changed)
	_howl_timer = Timer.new()
	_howl_timer.name = "HowlTimer"
	_howl_timer.one_shot = true
	_howl_timer.timeout.connect(_on_howl_timer)
	add_child(_howl_timer)


## Titel, der laut Bildschirm und Phase gehört (unabhängig von Musik an/aus und Berührung).
static func track_for(screen: StringName, phase: String) -> StringName:
	if screen == ScreenIds.COCKPIT and phase != "" and phase != String(Phase.SETUP):
		return TRACK_NIGHT if phase == String(Phase.NIGHT) else TRACK_NONE
	return TRACK_START


## Titel, der gerade hörbar sein soll (leer = Stille).
func current_track() -> StringName:
	return _current


## Der Ton ist durch eine erste Berührung freigegeben.
func is_unlocked() -> bool:
	return _unlocked


func howl_count() -> int:
	return _howl_count


## Lautstärke (dB) und Tonhöhe des zuletzt gespielten Heulens.
func last_howl_db() -> float:
	return _howl_last_db


func last_howl_pitch() -> float:
	return _howl_last_pitch


## Erste Berührung, Klick oder Taste: Ton freigeben, Eingabe bleibt unberührt.
func _input(event: InputEvent) -> void:
	if _unlocked:
		return
	if (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
			or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
			or (event is InputEventKey and (event as InputEventKey).pressed):
		unlock()


func unlock() -> void:
	if _unlocked:
		return
	_unlocked = true
	_apply()


func volume_db() -> float:
	var level := AppSettings.MUSIC_VOLUME_DEFAULT if _context == null else _context.settings.music_volume
	return VOLUME_DB[clampi(level, AppSettings.MUSIC_VOLUME_MIN, AppSettings.MUSIC_VOLUME_MAX) - 1]


func _wanted() -> StringName:
	if not _unlocked or _context == null or not _context.settings.music_enabled:
		return TRACK_NONE
	return track_for(_screen, _phase)


func _on_screen_changed(screen_id: StringName) -> void:
	_screen = screen_id
	_apply()


func _on_view_changed(view: Dictionary) -> void:
	_phase = str(view.get("phase", ""))
	_apply()


func _on_settings_changed(key: StringName) -> void:
	if key == &"music_enabled":
		_apply()
	elif key == &"music_volume" and _current != TRACK_NONE:
		_fade(_current, volume_db(), LEVEL_SECONDS)


## Tauscht die Musik nur bei echtem Titelwechsel; Rückgängig oder Laden mitten in einer Phase ändert nichts.
func _apply() -> void:
	var wanted := _wanted()
	if wanted == _current:
		return
	var previous := _current
	_current = wanted
	if previous != TRACK_NONE:
		_fade(previous, SILENT_DB, CROSSFADE_SECONDS, true)
	if wanted != TRACK_NONE:
		var player := _player_for(wanted)
		if player != null:
			if not player.playing:
				player.volume_db = SILENT_DB
				player.play()
			_fade(wanted, volume_db(), CROSSFADE_SECONDS)
	_schedule_howl()


func _player_for(track: StringName) -> AudioStreamPlayer:
	if _players.has(track):
		return _players[track] as AudioStreamPlayer
	var path := NIGHT_PATH if track == TRACK_NIGHT else START_PATH
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		return null
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true  # die .import-Dateien haben loop=false
	var player := AudioStreamPlayer.new()
	player.name = "Music_%s" % track
	player.stream = stream
	player.volume_db = SILENT_DB
	add_child(player)
	_players[track] = player
	return player


func _fade(track: StringName, target_db: float, seconds: float, stop_after := false) -> void:
	var player := _players.get(track) as AudioStreamPlayer
	if player == null:
		return
	var old := _tweens.get(track) as Tween
	if old != null and old.is_valid():
		old.kill()
	var tween := create_tween()
	_tweens[track] = tween
	tween.tween_property(player, "volume_db", target_db, seconds)
	if stop_after:
		tween.tween_callback(func() -> void:
			if _current != track:
				player.stop())


# --- Wolfsheulen ---------------------------------------------------------------------------------

func _schedule_howl() -> void:
	if _howl_timer == null:
		return
	if _current != TRACK_NIGHT:
		_howl_timer.stop()
	elif _howl_timer.is_stopped() and not _howl_streams().is_empty():
		_howl_timer.start(_rng.randf_range(HOWL_MIN_SECONDS, HOWL_MAX_SECONDS))


func _on_howl_timer() -> void:
	howl()
	_schedule_howl()


## Spielt ein zufälliges Heulen, nur in der Nachtmusik und nur, wenn Dateien da sind; wechselt die Seite. Liefert, ob gespielt wird.
func howl() -> bool:
	if _current != TRACK_NIGHT:
		return false
	var streams := _howl_streams()
	if streams.is_empty():
		return false
	_ensure_howl_bus()
	_howl_right = not _howl_right
	_howl_panner.pan = HOWL_PAN if _howl_right else -HOWL_PAN
	var pool := streams.duplicate()
	if pool.size() > 1:
		pool.erase(_howl_last)  # nie zweimal dieselbe Datei hintereinander
	var stream := pool[_rng.randi_range(0, pool.size() - 1)] as AudioStream
	_howl_last = stream
	_howl_last_db = HOWL_DB + _rng.randf_range(-HOWL_JITTER_DB, HOWL_JITTER_DB)
	if stream.resource_path.get_file().contains("fern"):
		_howl_last_db += HOWL_FAR_DB
	_howl_last_pitch = _rng.randf_range(HOWL_PITCH_MIN, HOWL_PITCH_MAX)
	_howl_player.stream = stream
	_howl_player.volume_db = _howl_last_db
	_howl_player.pitch_scale = _howl_last_pitch
	_howl_player.play()
	_howl_count += 1
	return true


func _howl_streams() -> Array[AudioStream]:
	var result: Array[AudioStream] = []
	var raw: Variant = howl_source.call()
	if raw is Array:
		for item: Variant in raw:
			if item is AudioStream:
				result.append(item as AudioStream)
	return result


## Dateien aus HOWL_DIR. `list_directory` kennt auch exportierte Ressourcen (Web); Endungen .import/.remap werden abgezogen.
func _load_howl_streams() -> Array[AudioStream]:
	var result: Array[AudioStream] = []
	var seen := {}
	for entry: String in ResourceLoader.list_directory(HOWL_DIR):
		var name := entry
		for suffix: String in [".import", ".remap"]:
			if name.ends_with(suffix):
				name = name.trim_suffix(suffix)
		if seen.has(name) or not HOWL_EXTENSIONS.has(name.get_extension().to_lower()):
			continue
		seen[name] = true
		var stream := load(HOWL_DIR + name) as AudioStream
		if stream != null:
			result.append(stream)
	return result


## Eigener Bus mit Schwenk (links/rechts), zur Laufzeit angelegt; keine Bus-Datei im Projekt.
func _ensure_howl_bus() -> void:
	if _howl_player != null:
		return
	var index := AudioServer.get_bus_index(HOWL_BUS)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, HOWL_BUS)
		AudioServer.add_bus_effect(index, AudioEffectPanner.new())
	_howl_panner = AudioServer.get_bus_effect(index, 0) as AudioEffectPanner
	_howl_player = AudioStreamPlayer.new()
	_howl_player.name = "HowlPlayer"
	_howl_player.bus = HOWL_BUS
	_howl_player.volume_db = HOWL_DB
	add_child(_howl_player)
