class_name AudioCuePlayer
extends Node
## Audioanschluss für Darstellungshinweise (GameSession.cue_requested). Ohne Tondatei oder bei einem nicht ladbaren Ton bleibt er
## stumm: Die Partie bleibt vollständig bedienbar und es gibt keinen Fehler. Es liegt bewusst keine Tondatei bei (Produktion und
## Herkunftsnachweis stehen aus); sie gehört nach `CUE_FILES`, sobald sie freigegeben ist. Kein Zufall, keine Wirkung auf den
## Spielzustand. Jeder Hinweis wird genau einmal behandelt; ein erneutes Zeichnen der Ansicht spielt nichts ab.

const CUE_FILES := {PresentationCue.FIVE_DEAD: "res://assets/audio/cues/five_dead.ogg"}
const STATUS_SILENT := "silent"    ## keine Tondatei oder nicht ladbar
const STATUS_PLAYING := "playing"
const MAX_HANDLED := 20

## Liefert den Ton zu einer Kennung oder null. Standard: die Datei aus CUE_FILES, falls vorhanden (Tests setzen eigene Töne).
var resolver: Callable = Callable(self, "_stream_from_file")
## Zuletzt behandelte Hinweise [{cue, status}], nur Kennung und Ergebnis, nie Namen oder Rollen.
var handled: Array[Dictionary] = []

var _player: AudioStreamPlayer = null
var _session: GameSession = null


func setup(context: AppContext) -> void:
	_session = context.session
	_session.cue_requested.connect(_on_cue)


func is_playing() -> bool:
	return _player != null and _player.playing


func _on_cue(cue: StringName) -> void:
	var stream := resolver.call(cue) as AudioStream
	var status := STATUS_SILENT
	if stream != null:
		if _player == null:
			_player = AudioStreamPlayer.new()
			_player.name = "CuePlayer"
			add_child(_player)
		_player.stream = stream
		_player.play()
		status = STATUS_PLAYING
	handled.append({"cue": String(cue), "status": status})
	if handled.size() > MAX_HANDLED:
		handled.pop_front()


func _stream_from_file(cue: StringName) -> AudioStream:
	var path := str(CUE_FILES.get(cue, ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream
