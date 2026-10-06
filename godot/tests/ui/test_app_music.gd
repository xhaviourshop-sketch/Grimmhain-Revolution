extends UiTestCase
## Musiksteuerung der App (AppMusic): Titelwahl nach Bildschirm und Phase, durchgehende Startmusik in den Menüs, Stille bei „Musik“ aus,
## Heulen nur mit Dateien und ohne Wirkung auf den Spielzustand. Geprüft wird die Zustandsabfrage, nicht der Ton.


func _tone() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	var samples := PackedByteArray()
	samples.resize(8000)
	samples.fill(128)
	wav.data = samples
	return wav


func test_track_follows_screen_and_phase() -> void:
	assert_eq(AppMusic.track_for(ScreenIds.START, ""), AppMusic.TRACK_START, "Start")
	assert_eq(AppMusic.track_for(ScreenIds.NEW_GAME, ""), AppMusic.TRACK_START, "Vorbereitung")
	assert_eq(AppMusic.track_for(ScreenIds.MAIN_MENU, "NIGHT"), AppMusic.TRACK_START, "Hauptmenü mitten in der Nacht: Startmusik")
	assert_eq(AppMusic.track_for(ScreenIds.COCKPIT, "SETUP"), AppMusic.TRACK_START, "Aufstellung")
	assert_eq(AppMusic.track_for(ScreenIds.COCKPIT, "NIGHT"), AppMusic.TRACK_NIGHT, "Nacht")
	for phase: String in ["DAWN_RESOLUTION", "DAY", "GAME_OVER"]:
		assert_eq(AppMusic.track_for(ScreenIds.COCKPIT, phase), AppMusic.TRACK_NONE, "%s: Stille" % phase)


func test_menus_keep_one_track_and_music_off_is_silent() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var music := shell.call("get_music") as AppMusic
	var settings := (shell.call("get_app_context") as AppContext).settings
	assert_eq(music.current_track(), AppMusic.TRACK_NONE, "vor der ersten Berührung still")
	music.unlock()
	assert_eq(music.current_track(), AppMusic.TRACK_START, "nach der Berührung Startmusik")
	for id: StringName in [&"main_menu", &"new_game", &"main_menu", &"settings"]:
		await navigate(shell, id)
		assert_eq(music.current_track(), AppMusic.TRACK_START, "%s: weiter Startmusik" % id)
	settings.set_music_enabled(false)
	assert_eq(music.current_track(), AppMusic.TRACK_NONE, "Musik aus: still")
	settings.set_music_enabled(true)
	assert_eq(music.current_track(), AppMusic.TRACK_START, "Musik an: wieder da")


func test_howl_needs_files_and_leaves_the_game_untouched() -> void:
	var shell := await spawn_shell()
	if shell == null:
		return
	var music := shell.call("get_music") as AppMusic
	var s := session_of(shell) as GameSession
	assert_true(s.submit(Fixtures.start_roles(["werwolf", "blutwolf"] + Fixtures.village_fillers(10), 1)).ok, "Start")
	assert_true(s.submit(Command.start_night()).ok, "Nacht 1")
	music.unlock()
	await navigate(shell, &"main_menu")
	await navigate(shell, &"cockpit")
	assert_eq(music.current_track(), AppMusic.TRACK_NIGHT, "Nachtmusik im Cockpit")
	assert_false(music.howl(), "ohne Heulen-Dateien kein Abspielen")
	music.howl_source = func() -> Array[AudioStream]: return [_tone()] as Array[AudioStream]
	var before := s.state_hash()
	assert_true(music.howl(), "mit Datei wird abgespielt")
	assert_true(music.howl(), "zweites Heulen")
	assert_eq(music.howl_count(), 2, "gezählt")
	assert_eq(s.state_hash(), before, "Zustand und Generator der Partie unverändert")
