extends TestCase
## Anzeige-Timer (P3, DECISIONS.md „Einstellbarer Anzeige-Timer“): rein anzeigend, pausierbar, Restzeit speicherstandtauglich,
## keine Standarddauer, bei Ablauf nur Stillstand auf 0. Wertebereiche und ungültige Blöcke werden abgelehnt.


func test_nothing_is_set_by_default() -> void:
	var t := DisplayTimer.new()
	assert_false(t.is_set(), "keine Standarddauer")
	assert_eq(t.to_dict(), {}, "ohne Einstellung nichts zu speichern")
	t.switch_group(DisplayTimer.GROUP_DAY)
	t.start()
	assert_false(t.running, "ohne Dauer startet nichts")


func test_group_follows_the_phase() -> void:
	assert_eq(DisplayTimer.group_of_phase("NIGHT"), DisplayTimer.GROUP_NIGHT, "Nacht")
	assert_eq(DisplayTimer.group_of_phase("DAY"), DisplayTimer.GROUP_DAY, "Tag")
	assert_eq(DisplayTimer.group_of_phase("DAWN_RESOLUTION"), DisplayTimer.GROUP_DAY, "Morgen gehört zum Tag")
	assert_eq(DisplayTimer.group_of_phase("GAME_OVER"), &"", "Spielende ohne Timer")
	assert_eq(DisplayTimer.group_of_phase(""), &"", "ohne Partie")


func test_set_start_pause_resume_and_tick() -> void:
	var t := DisplayTimer.new()
	t.switch_group(DisplayTimer.GROUP_DAY)
	assert_true(t.set_duration(DisplayTimer.GROUP_DAY, 300), "Dauer eingestellt")
	assert_eq(t.remaining, 300.0, "Restzeit beginnt mit der Dauer")
	assert_false(t.running, "gestoppt, bis die Spielleitung startet")
	t.start()
	t.tick(10.0)
	assert_eq(t.remaining, 290.0, "10 Sekunden vergangen")
	t.pause()
	t.tick(50.0)
	assert_eq(t.remaining, 290.0, "pausiert: keine Zeit vergeht")
	t.toggle()
	assert_true(t.running, "wieder gestartet")
	t.tick(0.5)
	assert_eq(t.remaining, 289.5, "weiter ab dem Pausenstand")


func test_expiry_stops_at_zero_and_has_no_other_effect() -> void:
	var t := DisplayTimer.new()
	t.switch_group(DisplayTimer.GROUP_NIGHT)
	t.set_duration(DisplayTimer.GROUP_NIGHT, 5)
	t.start()
	var changes := [0]
	t.changed.connect(func() -> void: changes[0] += 1)
	t.tick(3.0)
	assert_eq(changes[0], 0, "kein Signal je Zeitschritt")
	t.tick(10.0)
	assert_eq(t.remaining, 0.0, "Anzeige bleibt auf 0")
	assert_false(t.running, "Timer steht")
	assert_true(t.is_expired(), "abgelaufen")
	assert_eq(changes[0], 1, "genau ein Signal beim Ablauf")
	t.tick(5.0)
	assert_eq(t.remaining, 0.0, "nie negativ")


func test_phase_change_resets_to_the_new_group_and_stops() -> void:
	var t := DisplayTimer.new()
	t.set_duration(DisplayTimer.GROUP_DAY, 600)
	t.set_duration(DisplayTimer.GROUP_NIGHT, 120)
	t.switch_group(DisplayTimer.GROUP_DAY)
	t.start()
	t.tick(100.0)
	t.switch_group(DisplayTimer.GROUP_DAY)
	assert_eq(t.remaining, 500.0, "gleiche Gruppe: unverändert")
	t.switch_group(DisplayTimer.GROUP_NIGHT)
	assert_eq(t.remaining, 120.0, "neue Gruppe beginnt mit ihrer Dauer")
	assert_false(t.running, "und steht still")


func test_duration_is_clamped_and_group_checked() -> void:
	var t := DisplayTimer.new()
	assert_false(t.set_duration(&"evening", 60), "unbekannte Gruppe abgelehnt")
	t.set_duration(DisplayTimer.GROUP_DAY, -50)
	assert_eq(int(t.durations["day"]), 0, "nicht negativ")
	t.set_duration(DisplayTimer.GROUP_DAY, DisplayTimer.MAX_SECONDS * 10)
	assert_eq(int(t.durations["day"]), DisplayTimer.MAX_SECONDS, "Obergrenze")
	t.adjust_duration(DisplayTimer.GROUP_NIGHT, DisplayTimer.STEP_SECONDS)
	assert_eq(int(t.durations["night"]), DisplayTimer.STEP_SECONDS, "Schritt von 0")


func test_format() -> void:
	assert_eq(DisplayTimer.format_seconds(0.0), "0:00", "null")
	assert_eq(DisplayTimer.format_seconds(65.0), "1:05", "Minuten und Sekunden")
	assert_eq(DisplayTimer.format_seconds(64.2), "1:05", "aufgerundet: angezeigt wird, was noch bleibt")
	assert_eq(DisplayTimer.format_seconds(3600.0), "1:00:00", "Stunde")
	assert_eq(DisplayTimer.format_seconds(-3.0), "0:00", "negativ zeigt 0")


func test_save_and_load_keep_remaining_time_and_pause_state() -> void:
	var t := DisplayTimer.new()
	t.switch_group(DisplayTimer.GROUP_DAY)
	t.set_duration(DisplayTimer.GROUP_DAY, 600)
	t.set_duration(DisplayTimer.GROUP_NIGHT, 90)
	t.start()
	t.tick(42.5)
	# durch JSON, wie in der Speicherdatei
	var text := JSON.stringify(t.to_dict())
	var parsed: Variant = JSON.parse_string(text)
	assert_true(parsed is Dictionary, "JSON lesbar")
	var loaded := DisplayTimer.new()
	assert_true(loaded.from_dict(parsed as Dictionary), "gültiger Block")
	assert_eq(loaded.remaining, 557.5, "Restzeit unverändert, kein Zeitsprung")
	assert_true(loaded.running, "Laufzustand erhalten")
	assert_eq(int(loaded.durations["day"]), 600, "Dauer Tag")
	assert_eq(int(loaded.durations["night"]), 90, "Dauer Nacht")
	assert_eq(loaded.group, DisplayTimer.GROUP_DAY, "Gruppe")
	t.pause()
	var paused := DisplayTimer.new()
	assert_true(paused.from_dict(JSON.parse_string(JSON.stringify(t.to_dict())) as Dictionary), "pausierter Block")
	assert_false(paused.running, "Pause bleibt erhalten")


func test_invalid_blocks_are_rejected_and_leave_the_timer_untouched() -> void:
	var good := {"timer": {"day": 600, "night": 0, "group": "day", "remaining": 100.0, "running": false}}
	var bad_blocks := [
		{"timer": "x"},
		{"timer": {"day": -1, "night": 0, "group": "day", "remaining": 1.0, "running": false}},
		{"timer": {"day": 10, "night": 0, "group": "day", "remaining": 11.0, "running": false}},
		{"timer": {"day": 10, "night": 0, "group": "day", "remaining": -1.0, "running": false}},
		{"timer": {"day": 10, "night": 0, "group": "evening", "remaining": 1.0, "running": false}},
		{"timer": {"day": 10, "night": 0, "group": "day", "remaining": 1.0, "running": "yes"}},
		{"timer": {"day": 1.5, "night": 0, "group": "day", "remaining": 1.0, "running": false}},
		{"timer": {"day": DisplayTimer.MAX_SECONDS + 1, "night": 0, "group": "", "remaining": 0.0, "running": false}},
		{"timer": {"day": 10, "night": 0, "group": "day", "remaining": INF, "running": false}},
		{"timer": {"day": 10, "night": 0, "group": "day"}},
	]
	for block: Dictionary in bad_blocks:
		var t := DisplayTimer.new()
		assert_true(t.from_dict(good), "Ausgangsblock gültig")
		assert_false(t.from_dict(block), "abgelehnt: %s" % JSON.stringify(block))
		assert_eq(t.remaining, 100.0, "Timer unverändert nach Ablehnung")
	var empty := DisplayTimer.new()
	empty.from_dict(good)
	assert_true(empty.from_dict({}), "Block ohne Timer ist gültig")
	assert_false(empty.is_set(), "und leert den Timer (ältere Datei)")


func test_a_loaded_zero_remaining_never_runs() -> void:
	var t := DisplayTimer.new()
	assert_true(t.from_dict({"timer": {"day": 10, "night": 0, "group": "day", "remaining": 0.0, "running": true}}), "gültig")
	assert_false(t.running, "abgelaufener Timer läuft nicht weiter")
