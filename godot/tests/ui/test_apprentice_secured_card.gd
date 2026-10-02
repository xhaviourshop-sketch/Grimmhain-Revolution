extends UiTestCase
## AUDIT-2026-10-02 S-03 (vertical-slice-flow.md §3): Die Karte des Lehrlings nennt keine Personen und keine Rollen der
## Optionen auf der offenen Aktionskarte. Die Rollen der drei Optionen stehen nur auf der gesicherten Karte (`show`), die das
## Cockpit vollständig ersetzt. Kandidaten (Personen) erscheinen nirgends.

const UiGame := preload("res://tests/ui/ui_game.gd")
const ROLES := ["lehrling", "werwolf", "schutzengel", "das-orakel", "waldhexe", "dorfbewohner", "amalia"]


func _option_stage() -> GameSession:
	var s := UiGame.session(ROLES)
	assert_true(s.start_night().ok, "Nacht 1")
	var reached := UiGame.run_until(s, func(n: Dictionary) -> bool: return str(n.get("owner")) == "lehrling" and str(n.get("stage")) == "option", {"lehrling/candidates": [3, 4, 5]})
	assert_true(reached, "Optionsstufe des Lehrlings erreicht")
	return s


func test_prompt_data_hides_candidates_and_puts_roles_on_the_secured_card() -> void:
	var next := UiGame.next_of(_option_stage())
	for line: Dictionary in next.get("info", []):
		assert_ne(str(line["key"]), "candidates", "keine Kandidaten in den Infozeilen")
	var show: Array = next.get("show", [])
	assert_eq(show.size(), 1, "eine gesicherte Zeile")
	if show.size() == 1:
		assert_eq(str(show[0]["key"]), "options", "gesicherte Zeile: Optionen")
		assert_eq((show[0]["value"] as Array).size(), 3, "drei Optionen")
	assert_eq((next.get("options", []) as Array).size(), 3, "drei Antwortknöpfe bleiben")


func test_open_action_card_shows_option_numbers_without_role_names() -> void:
	var next := UiGame.next_of(_option_stage())
	var card := ActionCard.new()
	tree.root.add_child(card)
	_spawned.append(card)
	card.render(next, {"phase": "NIGHT", "seats": [], "selection": [], "revealed": true})
	var buttons: Array = card.find_children("OptionButton_*", "GrimmButton", true, false)
	assert_eq(buttons.size(), 3, "drei Optionsknöpfe")
	for b: Node in buttons:
		assert_false((b as GrimmButton).format_values.has("role"), "Knopf nennt keine Rolle")


func test_secured_card_lists_the_option_roles() -> void:
	var next := UiGame.next_of(_option_stage())
	var layer := CockpitLayers.show_card("lehrling", next["show"])
	assert_true(layer != null, "gesicherte Karte entsteht")
	if layer == null:
		return
	tree.root.add_child(layer)
	_spawned.append(layer)
	var texts: Array[String] = []
	for c: Control in text_controls(layer):
		texts.append(text_of(c))
	assert_true("\n".join(texts).contains("1: "), "nummerierte Optionen auf der gesicherten Karte: %s" % str(texts))
