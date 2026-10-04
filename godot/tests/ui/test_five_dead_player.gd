extends UiTestCase
## Audioanschluss des Fünf-Tote-Hinweises (DI-09) in der App-Shell: Ohne Tondatei bleibt er stumm und die Partie voll bedienbar;
## mit einem Ton (hier im Speicher erzeugt, keine Datei) wird genau einmal abgespielt; Neuzeichnen der Ansicht spielt nichts ab;
## nichts davon ändert den Spielzustand. Es liegt bewusst keine Tondatei bei.

const SM := "selbstmoerder"


func _roles() -> Array:
	return ["werwolf", "blutwolf", SM] + Fixtures.village_fillers(9)


func _day(shell: Control) -> GameSession:
	var s := session_of(shell) as GameSession
	assert_true(s.submit(Fixtures.start_roles(_roles(), 1)).ok, "Start")
	assert_true(s.submit(Command.start_night()).ok, "Nacht 1")
	assert_true(s.submit(Command.skip_step("night:1:0:pack", "kein Opfer")).ok, "ruhige Nacht")
	assert_true(s.submit(Command.end_night()).ok, "Tag 1")
	return s


func _kill(s: GameSession, id: int) -> void:
	assert_true(s.submit(CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": false}, "Test")).ok, "%d getötet" % id)


func _tone() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(32000)  # vier Sekunden Stille: der Ton läuft lange genug, damit der Test nicht vom Zeitpunkt abhängt
	samples.fill(128)
	wav.data = samples
	return wav


func test_no_sound_file_ships_and_the_hint_stays_silent_but_the_game_stays_operable() -> void:
	var path: String = AudioCuePlayer.CUE_FILES[PresentationCue.FIVE_DEAD]
	assert_false(ResourceLoader.exists(path) or FileAccess.file_exists(path), "keine Tondatei im Projekt (Produktion und Herkunft stehen aus)")
	var shell := await spawn_shell()
	if shell == null:
		return
	var player := shell.call("get_cue_player") as AudioCuePlayer
	assert_true(player != null, "Audioanschluss in der Shell")
	var s := _day(shell)
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	for id: int in [4, 5, 6, 9]:
		_kill(s, id)
	assert_eq(player.handled, [] as Array[Dictionary], "vier Tote: nichts behandelt")
	_kill(s, 10)
	assert_eq(player.handled, [{"cue": "five_dead", "status": AudioCuePlayer.STATUS_SILENT}] as Array[Dictionary], "genau ein Hinweis, stumm, nur mit Kennung")
	assert_false(player.is_playing(), "nichts spielt")
	await frames(3)
	# Ansicht neu aufbauen und wechseln: keine erneute Wiedergabe.
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	await frames(3)
	assert_eq(player.handled.size(), 1, "Neuzeichnen meldet nichts erneut")
	# Weiterspielen über echte Buttons ist ohne Ton möglich.
	var before := (s.commands() as Array).size()
	assert_true(s.submit(Command.decide_execution(-1)).ok, "Tag ohne Hinrichtung")
	await frames(2)
	assert_eq((s.commands() as Array).size(), before + 1, "Partie bedienbar")
	assert_eq(current_id(shell), &"cockpit", "Cockpit bleibt offen")


func test_with_a_tone_it_plays_exactly_once_and_changes_nothing_else() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var player := shell.call("get_cue_player") as AudioCuePlayer
	var tone := _tone()
	var asked: Array = []
	player.resolver = func(cue: StringName) -> AudioStream:
		asked.append(String(cue))
		return tone
	var s := _day(shell)
	var reference := GameSession.new()
	for c: Command in s.commands():
		reference.submit(c)
	for id: int in [4, 5, 6, 9, 10, 11]:
		_kill(s, id)
		reference.submit(CorrectionFixtures.gm("kill", {"target_id": id, "trigger_effects": false}, "Test"))
	assert_eq(asked, ["five_dead"], "der Ton wird genau einmal angefordert")
	assert_eq(player.handled, [{"cue": "five_dead", "status": AudioCuePlayer.STATUS_PLAYING}] as Array[Dictionary], "genau einmal abgespielt")
	assert_true(player.is_playing(), "Wiedergabe läuft")
	assert_eq(s.state_hash(), reference.state_hash(), "Zustand wie ohne Audioanschluss")
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	await frames(3)
	assert_eq(asked.size(), 1, "kein zweiter Abruf beim Neuzeichnen")
	# Speichern und Laden: keine erneute automatische Wiedergabe.
	assert_eq(s.load_text(s.save_text()), &"", "geladen")
	await frames(2)
	assert_eq(asked.size(), 1, "Laden spielt nichts ab")
	assert_true(s.undo(), "Rückgängig")
	assert_true(s.redo(), "Wiederholen")
	assert_eq(asked.size(), 1, "Rückgängig und Wiederholen spielen nichts ab")


func test_hint_is_not_given_without_a_living_death_seeker_and_carries_no_identity() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var player := shell.call("get_cue_player") as AudioCuePlayer
	var s := _day(shell)
	_kill(s, 3)  # der Selbstmörder ist tot
	for id: int in [4, 5, 6, 9]:
		_kill(s, id)
	assert_eq(player.handled, [] as Array[Dictionary], "fünf Tote ohne lebenden Selbstmörder: kein Hinweis")
	# Die Kennung ist alles, was der Anschluss je erhält (keine Namen, keine Rolle).
	for entry: Dictionary in player.handled:
		assert_eq(entry.keys(), ["cue", "status"], "nur Kennung und Ergebnis")
