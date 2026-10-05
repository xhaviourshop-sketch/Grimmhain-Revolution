class_name ScreenMusic
extends Node
## Hintergrundmusik eines Bildschirms (Feedback 5): Schleife, leise eingeblendet. Plätze für die Dateien: `START` (Startbildschirm) und
## `LOADING` (Ladebildschirm, noch kein Bildschirm der App, siehe `docs/assets/`). Fehlt die Datei oder lässt sie sich nicht laden,
## entsteht kein Knoten und alles läuft wie bisher still. Kein Zufall, keine Wirkung auf den Spielzustand.

const START := "res://assets/audio/musik-start.ogg"
const LOADING := "res://assets/audio/musik-laden.ogg"
const QUIET_DB := -60.0
const PLAY_DB := -14.0  ## leise: Musik bleibt unter den Ansagen
const FADE_IN_SECONDS := 4.0

var _player: AudioStreamPlayer = null


## Hängt die Musik an `host`, wenn die Datei existiert; liefert den Knoten oder null.
static func attach(host: Node, path: String) -> ScreenMusic:
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream == null:
		return null
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var music := ScreenMusic.new()
	music.name = "ScreenMusic"
	music._player = AudioStreamPlayer.new()
	music._player.stream = stream
	music._player.volume_db = QUIET_DB
	music.add_child(music._player)
	host.add_child(music)
	music._player.play()
	music.create_tween().tween_property(music._player, "volume_db", PLAY_DB, FADE_IN_SECONDS)
	return music


func fade_out(seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(_player, "volume_db", QUIET_DB, seconds)
	tween.tween_callback(_player.stop)
