extends "res://tests/ui/role_ui_case.gd"
## R-02 (Paket 3): Bedienweg jeder aktiven Rolle über echte Controls. Jede Fähigkeit wird über die Aktionskarte, die
## Sitzplatz-Handler und den Dialog ausgelöst (Treiber `role_ui_case.gd`); geprüft werden danach Ereignisse und Zustand
## aus dem Regelkern. Vorbereitung (Start, Tote per Spielleiterkorrektur ohne Folgen) nutzt Kernbefehle; die geprüfte
## Interaktion selbst nie. Personen: 1, 2, 3 … mit roles[0], roles[1] …, Sitzreihenfolge = ID. Alle Partien sind fest
## (Seed 7, keine Zufallswahl im Test), damit Abdeckung nicht vom Überleben abhängt.

const W := "werwolf"
const D := "dorfbewohner"


func _villagers(n: int) -> Array:
	var out: Array = []
	for i: int in n:
		out.append(D)
	return out


func _data(type: String, index: int = 0) -> Dictionary:
	var list := events(type)
	return (list[index] as Dictionary)["data"] if list.size() > index else {}


# --- Informationsrollen ---------------------------------------------------------------------------------------

func test_dorfchronistin_shows_solo_count() -> void:
	if not await start(["dorfchronistin", W, "rattenfaenger"] + _villagers(4)):
		return
	if await run({}, until_prompt("dorfchronistin", "shown")):
		await tap_button("ShowCardButton")
		var layer := find_node(screen(), "ShowLayer")
		assert_true(layer != null, "Zeigekarte für die Chronistin")
		await tap_button("CloseLayerButton", layer)  # Schließen der gezeigten Karte erledigt die Auskunft
	assert_eq(int(_data("ChronicleRevealed").get("solo_count", -1)), 1, "eine Einzelsiegperson")


func test_die_gebundenen_see_each_other() -> void:
	if not await start(["die-gebundenen", W, "die-gebundenen"] + _villagers(4)):
		return
	await run({}, until_event("BoundRevealed"))
	var shown := events("BoundRevealed")
	assert_eq(shown.size(), 2, "beide Gebundene erhalten die Information")
	assert_eq((shown[0]["data"] as Dictionary)["other_bound_ids"], [3], "Person 1 sieht Person 3")


func test_waldlaeufer_counts_wolves() -> void:
	if not await start(["waldlaeufer", W, W] + _villagers(4)):
		return
	await run({}, until_event("RangerRevealed"))
	assert_eq(int(_data("RangerRevealed").get("wolf_count", -1)), 2, "zwei Wölfe")


func test_doktor_compares_two_people() -> void:
	if not await start(["doktor", W] + _villagers(5)):
		return
	await run({"doktor/targets": [2, 3]}, until_event("DoctorRevealed"))
	assert_eq(_data("DoctorRevealed").get("target_ids"), [2, 3], "gewählte Personen")
	assert_eq(_data("DoctorRevealed").get("same_team"), false, "Wolf und Dorf nicht im selben Team")


func test_faehrtenleser_uses_tracking_once() -> void:
	if not await start(["faehrtenleser", W] + _villagers(5)):
		return
	await run({"faehrtenleser/use": true}, until_event("TrackerRevealed"))
	assert_true(has_event("TrackerRevealed"), "Richtung gezeigt")
	await run({}, until_night_end())
	assert_true(InfoSteps.tracker_used(state().players[1]), "Fähigkeit verbraucht")


func test_traumdeuter_names_three_with_a_wolf() -> void:
	if not await start(["traumdeuter", W] + _villagers(5)):
		return
	await run({"traumdeuter/targets": [2, 3, 4]}, until_event("DreamRevealed"))
	var ids: Array = _data("DreamRevealed").get("target_ids", [])
	ids.sort()
	assert_eq(ids, [2, 3, 4], "drei Namen")


func test_kopfgeldjaeger_list_after_wolf_lynch() -> void:
	if not await start(["kopfgeldjaeger", W, W] + _villagers(5)):
		return
	await run({"day1": {"nominate": [4, 2], "execute": 2}, "kopfgeldjaeger/targets": [3, 4, 5]}, until_event("BountyRevealed"))
	assert_false(alive(2), "Wolf 2 gehängt")
	var ids: Array = _data("BountyRevealed").get("target_ids", [])
	ids.sort()
	assert_eq(ids, [3, 4, 5], "Liste in Nacht 2")


func test_koenig_learns_a_village_role() -> void:
	if not await start(["koenig", W, "schutzengel"] + _villagers(5), [4, 5, 6, 7, 8]):
		return
	await run({"koenig/targets": [3], "schutzengel/": [1]}, until_event("KingRevealed"))
	assert_eq(int(_data("KingRevealed").get("target_id", -1)), 3, "Person 3")
	assert_eq(str(_data("KingRevealed").get("role_id")), "schutzengel", "wahre Rolle")


func test_kriegerin_wrong_attack_costs_her_life() -> void:
	if not await start(["kriegerin-des-lichts", W] + _villagers(5)):
		return
	await run({"kriegerin-des-lichts/targets": [3]}, until_event("WarriorRevealed"))
	assert_eq(_data("WarriorRevealed").get("is_wolf"), false, "kein Wolf")
	await run({}, until_kind("day"))
	assert_false(alive(1), "Irrtum: Kriegerin stirbt am Morgen")


func test_blutpriester_sacrifices_and_names_wolves() -> void:
	if not await start(["blutpriester", W] + _villagers(5)):
		return
	await run({"blutpriester/targets": [3], "blutpriester/reveal": [2]}, until_event("BloodRevealed"))
	assert_eq(_data("BloodRevealed").get("revealed_ids"), [2], "genannter Wolf")
	await run({}, until_kind("day"))
	assert_false(alive(3), "Opfer stirbt am Morgen")


func test_die_ewigen_check_for_solo() -> void:
	if not await start(["die-ewigen", W, "rattenfaenger"] + _villagers(4)):
		return
	await run({"die-ewigen/targets": [3]}, until_event("EternalRevealed"))
	assert_eq(_data("EternalRevealed").get("solo"), true, "Rattenfänger ist Einzelsieg")


# --- Wolfsrollen mit eigenem Schritt ----------------------------------------------------------------------

func test_albtraumwolf_blocks_one_person() -> void:
	if not await start([W, "albtraumwolf", "das-orakel"] + _villagers(4)):
		return
	await run({"albtraumwolf/": [3]}, until_night_end())
	assert_eq(int(_data("NightBlocked").get("target_id", -1)), 3, "Orakel blockiert")
	assert_false(has_event("InfoRevealed"), "blockiertes Orakel erfährt nichts")


func test_schattenhund_blocks_village_steps() -> void:
	if not await start([W, "schattenhund", "das-orakel"] + _villagers(4)):
		return
	await run({"schattenhund/use": true}, until_night_end())
	assert_eq(str(_data("NightBlocked").get("by")), "schattenhund", "Blockade")
	assert_false(has_event("InfoRevealed"), "Dorfschritt entfällt")


func test_giftwolf_poisons_with_delay() -> void:
	if not await start([W, "giftwolf"] + _villagers(5)):
		return
	await run({"giftwolf/": [3]}, until_event("WolfPoisoned"))
	assert_eq(int(_data("WolfPoisoned").get("due_night", -1)), 3, "Tod in Nacht 3")
	await run({}, until_kind("day"))
	assert_true(alive(3), "noch lebend nach Nacht 1")


func test_schwarze_witwe_strikes_the_lovers() -> void:
	if not await start([W, "schwarze-witwe", "loki"] + _villagers(4)):
		return
	await run({"loki/targets": [4, 5], "loki/mode": true, "schwarze-witwe/": [4], "pack/": [4]}, until_event("WidowStruck"))
	assert_eq(_data("WidowStruck").get("partner_ids"), [5], "Paar gefunden")
	await run({}, until_kind("day"))
	assert_false(alive(4) or alive(5), "Paar stirbt am Morgen")


func test_schattenwanderer_links_a_person() -> void:
	if not await start([W, "schattenwanderer"] + _villagers(5)):
		return
	await run({"schattenwanderer/": [3]}, until_event("ShadowLinked"))
	assert_eq(int(_data("ShadowLinked").get("partner_id", -1)), 3, "Verknüpfung")


func test_koenig_lykaon_converts_a_villager() -> void:
	if not await start(["koenig-lykaon", W, "das-orakel"] + _villagers(5)):
		return
	await run({"koenig-lykaon/ally": [2], "koenig-lykaon/targets": [3]}, until_event("LycaonConverted"))
	assert_eq(state().players[3].role_id, &"trugbilderwolf", "3 wird Trugbilderwolf")
	assert_eq(state().players[3].appears_as, &"das-orakel", "Scheinrolle = alte Rolle")


func test_schicksalswolf_marks_three() -> void:
	if not await start([W, "schicksalswolf"] + _villagers(5)):
		return
	await run({"schicksalswolf/": [3, 4, 5]}, until_event("FateMarked"))
	var ids: Array = _data("FateMarked").get("target_ids", [])
	ids.sort()
	assert_eq(ids, [3, 4, 5], "drei Markierungen")


func test_rachsuechtiger_wolf_strikes_in_night_three() -> void:
	if not await start([W, "rachsuechtiger-wolf", W] + _villagers(5)):
		return
	quiet_nights = true
	await run({"rachsuechtiger-wolf/": [3]}, until_event("LoneWolfStruck"))
	assert_eq(int(_data("LoneWolfStruck").get("target_id", -1)), 3, "anderer Wolf gerissen")
	assert_eq(int(_data("LoneWolfStruck").get("night", -1)), 3, "in Nacht 3")
	await run({}, until_kind("day"))
	assert_false(alive(3), "Tod am Morgen")


# --- Dorf- und Schutzrollen mit eigenem Schritt -----------------------------------------------------------

func test_korrupter_richter_marks_a_hidden_nomination() -> void:
	if not await start(["korrupter-richter", W] + _villagers(5)):
		return
	await run({"korrupter-richter/": [3]}, until_kind("day"))
	assert_eq(int(_data("JudgeMarked").get("target_id", -1)), 3, "Markierung")
	var noms: Array = next().get("nominations", [])
	assert_true(noms.any(func(n: Dictionary) -> bool: return int(n["nominee_id"]) == 3 and int(n["nominator_id"]) == -1), "verdeckte Nominierung ohne Nominierenden")


func test_parasit_attaches_to_a_host() -> void:
	if not await start(["parasit", W] + _villagers(5)):
		return
	await run({"parasit/": [3]}, until_event("ParasiteAttached"))
	assert_eq(int(_data("ParasiteAttached").get("host_id", -1)), 3, "Wirt 3")


func test_henker_marks_after_three_executions() -> void:
	if not await start(["henker", W] + _villagers(8)):
		return
	quiet_nights = true  # lange Szenarien: das Rudelopfer wird morgens wiederbelebt (Vorbereitung)
	var plan := {"day1": {"nominate": [9, 3], "execute": 3}, "day2": {"nominate": [9, 4], "execute": 4}, "day3": {"nominate": [9, 5], "execute": 5},
		"henker/": [6], "pack/": [8], "day4": {"nominate": [9, 7], "execute": 7}}
	await run(plan, until_event("HangmanMarked"))
	assert_eq(int(_data("HangmanMarked").get("target_id", -1)), 6, "Markierung")
	await run(plan, until_kind("end_day"))
	assert_false(alive(7), "Hinrichtung 7")
	assert_false(alive(6), "Zusatztod der Markierung")


func test_maertyrerin_takes_the_pack_victim_place() -> void:
	if not await start(["maertyrerin", W] + _villagers(5)):
		return
	await run({"pack/": [3], "maertyrerin/": [3]}, until_kind("day"))
	assert_eq(int(_data("MartyrChosen").get("victim_id", -1)), 3, "opfert sich für 3")
	assert_true(alive(3), "Rudelopfer lebt")
	assert_false(alive(1), "Märtyrerin stirbt")


func test_schutzgeist_gives_a_shield_after_death() -> void:
	if not await start(["schutzgeist", W] + _villagers(5), [1]):
		return
	await run({"schutzgeist/": [3]}, until_event("ShieldGiven"))
	assert_eq(int(_data("ShieldGiven").get("holder_id", -1)), 3, "Schild an 3")


func test_verdammniswaechter_redirects_the_pack() -> void:
	if not await start(["verdammniswaechter", W] + _villagers(5)):
		return
	await run({"pack/": [3]}, until_prompt("verdammniswaechter"))
	var offer: Array = (next()["allowed_ids"] as Array).filter(func(id: int) -> bool: return id != 3)
	assert_eq(offer.size(), 1, "Urteil zwischen Opfer und Angebot")
	await answer(offer)
	await run({}, until_kind("day"))
	assert_eq(int(_data("DoomJudged").get("chosen_id", -1)), int(offer[0]), "Urteil protokolliert")
	assert_true(alive(3), "ursprüngliches Opfer lebt")
	assert_false(alive(int(offer[0])), "gewählte Person stirbt")


func test_dorfschmied_gives_weapon_in_night_six() -> void:
	if not await start(["dorfschmied", W] + _villagers(8)):
		return
	await run({"dorfschmied/": [4]}, until_event("WeaponGiven"))
	assert_eq(int(_data("WeaponGiven").get("holder_id", -1)), 4, "Waffe an 4")
	assert_eq(int(_data("WeaponGiven").get("night", -1)), 6, "ab Nacht 6")


func test_wolfskind_chooses_a_model() -> void:
	if not await start(["wolfskind", W] + _villagers(5)):
		return
	await run({"wolfskind/": [3], "pack/": null}, until_event("WolfChildBound"))
	assert_eq(int(_data("WolfChildBound").get("model_id", -1)), 3, "Vorbild 3")
	await run({"day1": {"nominate": [4, 3], "execute": 3}}, until_kind("end_day"))
	assert_true(state().players[1].counts_as_wolf, "Vorbild tot: Wolfskind verwandelt")


func test_lehrling_chooses_the_master_directly() -> void:
	# DA Nachtschritte neu: eine Stufe, eine Person, eine feste Anzahl gilt sofort.
	if not await start(["lehrling", W, "schutzengel", "das-orakel", "waldhexe"] + _villagers(2)):
		return
	await run({"lehrling/master": [4], "schutzengel/": [6], "das-orakel/target": [6]}, until_event("ApprenticeBound"))
	var bond := ApprenticeRules.active_of(state(), 1)
	assert_true(bond != null and bond.master_id == 4, "Meister ist die gewählte Person")
	assert_true(live("ConfirmTargetsButton") == null, "kein Bestätigen")


func test_zeitwaechter_freezes_the_night() -> void:
	if not await start(["zeitwaechter", W, "das-orakel"] + _villagers(4)):
		return
	await run({"zeitwaechter/use": true}, until_kind("day"))
	assert_true(has_event("NightFreezeUsed"), "Nacht eingefroren")
	assert_false(has_event("InfoRevealed"), "keine Nachtschritte, Zeitwächter zuerst (DA-107)")
	assert_true(has_event("NightFrozen"), "öffentliche Ansage am Morgen")


func test_dr_frankenstein_revives_with_free_role() -> void:
	if not await start(["dr-victor-frankenstein", W, "das-orakel"] + _villagers(5), [4]):
		return
	await run({"dr-victor-frankenstein/targets": [4], "dr-victor-frankenstein/role": {"option": 0}, "das-orakel/target": [2]}, until_kind("day"))
	assert_eq(int(_data("RevivedByRole").get("player_id", -1)), 4, "4 wiederbelebt")
	assert_true(alive(4), "lebt am Morgen")


func test_rotkaeppchen_asks_for_refuge() -> void:
	if not await start(["rotkaeppchen", W] + _villagers(5)):
		return
	await run({"rotkaeppchen/targets": [3], "rotkaeppchen/grant": true}, until_event("RedRefuge"))
	assert_eq(_data("RedRefuge").get("granted"), true, "Zuflucht gewährt")
	assert_eq(int(_data("RedRefuge").get("target_id", -1)), 3, "bei Person 3")


# --- Einzelsiegrollen mit eigenem Schritt -----------------------------------------------------------------

func test_rattenfaenger_charms_two() -> void:
	if not await start(["rattenfaenger", W] + _villagers(5)):
		return
	await run({"rattenfaenger/": [3, 4]}, until_event("Charmed"))
	var ids: Array = _data("Charmed").get("target_ids", [])
	ids.sort()
	assert_eq(ids, [3, 4], "zwei Verzauberte")


func test_pestbringerin_infects() -> void:
	if not await start(["pestbringerin", W] + _villagers(5)):
		return
	await run({"pestbringerin/": [3]}, until_event("Infected"))
	assert_eq(int(_data("Infected").get("target_id", -1)), 3, "Infektion")


func test_prophet_marks_three() -> void:
	if not await start(["prophet-des-untergangs", W] + _villagers(5)):
		return
	await run({"prophet-des-untergangs/": [3, 4, 5]}, until_event("ProphetMarked"))
	var ids: Array = _data("ProphetMarked").get("target_ids", [])
	ids.sort()
	assert_eq(ids, [3, 4, 5], "drei Markierungen")


func test_todesprediger_prediction_through_buttons() -> void:
	if not await start(["todesprediger", W] + _villagers(5)):
		return
	await run({"todesprediger/prediction": {"prediction": ["day", 3]}}, until_event("ProphecySet"))
	var p := _data("ProphecySet")
	assert_eq(str(p.get("kind")), "day", "Art Tag")
	assert_eq(int(p.get("number", -1)), 3, "Zahl über Plus eingestellt")


func test_feuerteufel_marks() -> void:
	if not await start(["feuerteufel", W] + _villagers(5)):
		return
	await run({"feuerteufel/": [3]}, until_event("FireMarked"))
	assert_eq(int(_data("FireMarked").get("target_id", -1)), 3, "Markierung 3")


func test_voodoo_gives_doll() -> void:
	if not await start(["voodoo-priester", W] + _villagers(5)):
		return
	await run({"voodoo-priester/": [3]}, until_event("VoodooDollGiven"))
	assert_eq(int(_data("VoodooDollGiven").get("doll_id", -1)), 3, "Puppe 3")


func test_nekromant_builds_shield_from_three_dead() -> void:
	if not await start(["nekromant", W] + _villagers(6), [4, 5, 6]):
		return
	await run({"nekromant/targets": [4, 5, 6]}, until_event("NecroShield"))
	var ids: Array = _data("NecroShield").get("dead_ids", [])
	ids.sort()
	assert_eq(ids, [4, 5, 6], "drei Tote geopfert")


func test_hades_kills_after_two_lights() -> void:
	if not await start(["hades", W] + _villagers(8)):
		return
	var plan := {"day1": {"nominate": [9, 3], "execute": 3}, "day2": {"nominate": [9, 4], "execute": 4}, "hades/targets": [5], "hades/barrier": false}
	await run(plan, until_event("HadesActed"))
	assert_eq(int(_data("HadesActed").get("target_id", -1)), 5, "Tötung für zwei Lichter")
	await run(plan, until_kind("day"))
	assert_false(alive(5), "Ziel stirbt")


func test_grabraeuber_steals_a_dead_ability() -> void:
	if not await start(["grabraeuber", W, "das-orakel"] + _villagers(4), [3]):
		return
	await run({"grabraeuber/targets": [3]}, until_event("GraveRobbed"))
	assert_eq(str(_data("GraveRobbed").get("role_id")), "das-orakel", "Orakelfähigkeit gestohlen")


# --- Todesreaktionen ---------------------------------------------------------------------------------------

func test_ritter_tie_choice_through_the_card() -> void:
	if not await start([D, W, "amalia", "ritter", "detektiv", "blutwolf", "wahnsinniger-kutscher", "waechter-am-tor"]):
		return
	await run({"pack/": [4], "reaction/knight": [6]}, until_kind("day"))
	assert_false(alive(4), "Ritter tot")
	assert_false(alive(6), "gewählter Wolf stirbt")
	assert_true(alive(2), "anderer Wolf lebt")


func test_besessener_wolf_drags_someone_along() -> void:
	if not await start([W, "besessener-wolf"] + _villagers(5)):
		return
	await run({"day1": {"nominate": [3, 2], "execute": 2}, "reaction/possessed": [4]}, until_kind("end_day"))
	assert_false(alive(2), "Besessener gehängt")
	assert_false(alive(4), "mitgerissen")


func test_daemonischer_wolf_curses_on_death() -> void:
	if not await start([W, "daemonischer-wolf"] + _villagers(5)):
		return
	await run({"day1": {"nominate": [3, 2], "execute": 2}, "reaction/demon": [4]}, until_event("DemonCursed"))
	assert_eq(int(_data("DemonCursed").get("target_id", -1)), 4, "Fluch auf 4")


func test_cerberus_defends_execution_with_three_heads() -> void:
	if not await start([W, "cerberus"] + _villagers(6)):
		return
	await run({"day3": {"nominate": [3, 2], "execute": 2, "cerberus": true}},
		until_day(3, "end_day"))
	assert_eq(int(_data("ExecutionDefended").get("day", -1)), 3, "Hinrichtung an Tag 3 abgewehrt")
	assert_true(alive(2), "Cerberus lebt")


func test_manipulator_dies_when_nominated() -> void:
	if not await start(["manipulator", W] + _villagers(5)):
		return
	await run({"day1": {"nominate": [3, 1]}}, func(_n: Dictionary) -> bool: return not alive(1))
	assert_false(alive(1), "stirbt bei der Nominierung")
