extends TestCase
## Lebenszyklus der Anwendungsobjekte: AppContext und seine Dienste dürfen keinen Referenzkreis bilden, sonst bleiben sie samt
## ihren Skripten bis zum Programmende erhalten (Warnung „resources still in use at exit“ nach jedem Lauf mit Oberfläche).
## Ursache war ein Lambda mit `self` als Signalverbindung der Sitzung.


func test_app_context_is_freed_when_the_last_reference_goes() -> void:
	var context := AppContext.new()
	var probe: WeakRef = weakref(context)
	var session_probe: WeakRef = weakref(context.session)
	assert_true(context.session.submit(Fixtures.start_roles(Fixtures.unique_roles(6), 1)).ok, "Sitzung nutzt alle Verbindungen (Start)")
	assert_true(context.session.submit(Command.start_night()).ok, "Sitzung nutzt alle Verbindungen (Nacht)")
	context = null
	assert_true(probe.get_ref() == null, "AppContext wird freigegeben (kein Referenzkreis über Signalverbindungen)")
	assert_true(session_probe.get_ref() == null, "die Sitzung des Kontexts wird mit freigegeben")


func test_session_with_listeners_is_freed() -> void:
	var session := GameSession.new()
	var heard: Array = []
	session.cue_requested.connect(func(cue: StringName) -> void: heard.append(cue))  # Lambda ohne self: kein Kreis
	var probe: WeakRef = weakref(session)
	assert_true(session.submit(Fixtures.start_roles(Fixtures.unique_roles(6), 1)).ok, "Start")
	session = null
	assert_true(probe.get_ref() == null, "GameSession wird freigegeben")
