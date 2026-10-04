extends UiTestCase
## AUDIT-2026-10-02 S-03 (vertical-slice-flow.md §3), nach DA Nachtschritte neu: Der Lehrling wählt seinen Meister direkt (eine Stufe,
## eine Person). Seine Karte nennt keine Rollen und zeigt nichts Geheimes: keine Infozeilen, keine gesicherte Karte, keine Optionsknöpfe.

const UiGame := preload("res://tests/ui/ui_game.gd")
const ROLES := ["lehrling", "werwolf", "schutzengel", "das-orakel", "waldhexe", "dorfbewohner", "amalia"]


func _master_stage() -> GameSession:
	var s := UiGame.session(ROLES)
	assert_true(s.start_night().ok, "Nacht 1")
	var reached := UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("owner")) == "lehrling", {"schutzengel/": [6], "pack/": [7]})
	assert_true(reached, "Wahl des Lehrlings erreicht")
	return s


func test_prompt_data_has_nothing_secret_and_no_option_stage() -> void:
	var next := UiGame.next_of(_master_stage())
	assert_eq(str(next.get("stage")), "master", "eine Stufe: der Meister")
	assert_eq(str(next.get("answer")), "targets", "Antwort: eine Person")
	assert_eq(next.get("counts"), [1], "genau eine Person")
	assert_true((next.get("info", []) as Array).is_empty(), "keine Infozeilen")
	assert_true((next.get("show", []) as Array).is_empty(), "keine gesicherte Karte")
	assert_true((next.get("options", []) as Array).is_empty(), "keine Rollenoptionen")
	assert_false((next.get("allowed_ids", []) as Array).has(1), "nie der Lehrling selbst")


func test_open_action_card_names_no_roles_and_has_no_option_buttons() -> void:
	var next := UiGame.next_of(_master_stage())
	var card := ActionCard.new()
	tree.root.add_child(card)
	_spawned.append(card)
	card.render(next, {"phase": "NIGHT", "seats": [], "selection": [], "revealed": true})
	assert_eq(card.find_children("OptionButton_*", "GrimmButton", true, false).size(), 0, "keine Optionsknöpfe")
	assert_eq(card.find_children("ConfirmTargetsButton", "GrimmButton", true, false).size(), 0, "eine feste Anzahl gilt sofort")
