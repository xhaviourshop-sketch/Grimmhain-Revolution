extends TestCase
## DA-106: Die Zahl oben links auf Markus' Rollenkarten ist die Nachtreihenfolge (Priorität = Kartenzahl mal 10).
## Rollen mit „X“ rufen nicht auf, außer den bedingten Aufrufen der Gebundenen und des Kutschers (unverändert).
## Blockaden (Schattenhund 0,7, Albtraumwolf 2,1) treffen nur Schritte, die in derselben Nacht nach ihnen kommen.

## Abschrift aller 72 Kartenbilder (`assets/cards/de`), unabhängig von RoleCatalog.CARD_NUMBERS: Zahl mal 10,
## "X" ohne Nachtzahl, "" ohne Zahl (Dorfbewohner).
const CARDS := {
	"albtraumwolf": 21, "amalia": 58, "besessener-wolf": "X", "blutpriester": 82, "blutwolf": "X", "cerberus": "X",
	"daemonischer-wolf": "X", "das-orakel": 46, "der-weise": "X", "detektiv": "X", "die-ewigen": 48, "die-gebundenen": "X",
	"doktor": 50, "doppelspion": "X", "dorfbewohner": "", "dorfchronistin": 3, "dorfschmied": 17, "dorfwache": "X",
	"dr-victor-frankenstein": 36, "faehrtenleser": 52, "fenrir": "X", "feuerteufel": 76, "giftwolf": 27, "grabraeuber": 64,
	"hades": 99, "henker": 78, "kartenschlucker": 40, "koenig": 44, "koenig-lykaon": 24, "kopfgeldjaeger": 32,
	"korrupter-richter": 15, "kriegerin-des-lichts": 60, "kutscher": "X", "lehrling": 11, "loki": 1, "maertyrerin": 90,
	"manipulator": "X", "nachtwaechter": "X", "nekromant": 30, "parasit": 62, "pestbringerin": 72, "prophet-des-untergangs": 86,
	"rachsuechtiger-wolf": 22, "rattenfaenger": 42, "ritter": "X", "rotkaeppchen": 74, "rudelvater": "X", "schattenhund": 7,
	"schattenwanderer": 26, "schicksalswolf": 25, "schutzengel": 13, "schutzgeist": 56, "schwarze-witwe": 28, "seelentauscher": 80,
	"selbstmoerder": "X", "sensentraeger": "X", "seuchenwolf": "X", "siegreicher-wolf": "X", "spiegelwolf": "X", "spuerhund": 68,
	"todesprediger": 66, "traumdeuter": 70, "trugbilderwolf": "X", "verdammniswaechter": 23, "voodoo-priester": 84,
	"waechter-am-tor": "X", "wahnsinniger-kutscher": "X", "waldhexe": 34, "waldlaeufer": 54, "werwolf": 20, "wolfskind": 9,
	"zeitwaechter": 95,
}
## Karte mit Zahl, aber ohne eigenen Schritt: Werwolf (Rudelschritt), Ewige (gemeinsamer Schritt), Amalia (Tagesaktion).
const NO_OWN_STEP := ["werwolf", "die-ewigen", "amalia"]
const X_CALLED := {"kutscher": 38}  ## Gebundene: gemeinsamer Schritt auf BOUND_PRIORITY (unten)


func test_every_role_follows_its_card_number() -> void:
	assert_eq(RoleCatalog.ROLES.size(), 72, "72 Rollen")
	assert_eq(CARDS.size(), 72, "72 Karten abgeschrieben")
	for role: String in CARDS:
		var id := StringName(role)
		assert_true(RoleCatalog.has_role(id), "%s im Katalog" % role)
		var card: Variant = CARDS[role]
		if card is int:
			assert_eq(int(RoleCatalog.CARD_NUMBERS.get(id, -1)), card, "%s: Tabelle = Karte" % role)
			assert_eq(RoleCatalog.night_priority(id), 0 if NO_OWN_STEP.has(role) else card, "%s: Priorität = Kartenzahl mal 10" % role)
		else:
			assert_false(RoleCatalog.CARD_NUMBERS.has(id), "%s: ohne Kartenzahl" % role)
			assert_eq(RoleCatalog.night_priority(id), int(X_CALLED.get(role, 0)), "%s: X ruft nicht auf (außer bedingt)" % role)
	assert_eq(RoleCatalog.PACK_PRIORITY, 20, "Rudel auf 2,0")
	assert_eq(RoleCatalog.ETERNAL_PRIORITY, 48, "Ewige auf 4,8")
	assert_eq(RoleCatalog.BOUND_PRIORITY, 5, "Gebundene bedingt auf 0,5")
	assert_eq(CallPolicy.slot_priority(&"zeitwaechter"), 95, "Zeitwächter ohne Vorzug")


func test_blocks_only_hit_later_steps() -> void:
	# 1 Schattenhund, 2 Dorfchronistin (0,3, vor ihm), 3 Schutzengel (1,3, nach ihm), 4–6 Dorf.
	var r := RulesEngine.replay([Fixtures.start_roles(["schattenhund", "dorfchronistin", "schutzengel", "dorfbewohner", "amalia", "detektiv"], 1), Command.start_night()] as Array[Command])
	assert_true(r.ok, "Start (%s)" % r.error)
	if not r.ok:
		return
	var s := r.state
	assert_eq(s.night_plan.slice(0, 3), [&"dorfchronistin:2", &"schattenhund:1", &"schutzengel:3"] as Array[StringName], "Reihenfolge nach Kartenzahl")
	s = apply_ok(s, Command.answer_choice(s.pending_prompt.id, "shown", true), "Chronistin handelt").state
	s = apply_ok(s, Command.begin_step(RulesEngine.next_step_id(s)), "Schattenhund").state
	var after := apply_ok(s, Command.answer_choice(s.pending_prompt.id, "use", true), "blockieren")
	assert_eq(String(after.state.night_step_status[0]), "done", "Chronistin vor der Blockade nicht betroffen")
	var dropped := events_of_type(after.events, "StepDropped")
	assert_true(not dropped.is_empty() and String(dropped[0].data["step_id"]).ends_with("schutzengel:3") and String(dropped[0].data["reason"]) == "blocked", "Schutzengel nach der Blockade entfällt")
