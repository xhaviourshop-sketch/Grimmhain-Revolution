extends TestCase
## Classic-Partie: Regelbuch und Totenreichkarten nennen die Namen des Charakterbogens, nie die der Grundspiel-Mechanik; die
## Tetanus-Infektion des Ritters erscheint nicht als Gift. Grundspiel-Partien bleiben unverändert.

const MECHANICS: Array[StringName] = [RoleCatalog.ORAKEL, RoleCatalog.SCHUTZENGEL, RoleCatalog.WALDHEXE, RoleCatalog.LOKI,
	RoleCatalog.SENSENTRAEGER, RoleCatalog.DER_WEISE, RoleCatalog.DIE_GEBUNDENEN, RoleCatalog.RATTENFAENGER]
const CLASSIC_CAST: Array = ["classic-ritter", "classic-werwolf", "classic-seherin", "classic-dorfbewohner", "classic-dorfbewohner",
	"classic-dorfbewohner"]


func _texts() -> Array[String]:
	var out: Array[String] = []
	for key: String in ["ui.rulebook.c02.b06", "ui.rulebook.c05.b07", "ui.rulebook.c06.b01", "ui.rulebook.c06.b02", "ui.rulebook.c06.b08",
			"ui.card.segen_06.wolf.text", "ui.card.segen_06.wolf.guide", "ui.card.segen_13.wolf.guide", "ui.card.fluch_02.dorf.guide"]:
		var own := key.replace("ui.rulebook.", "ui.rulebook.classic.") if key.begins_with("ui.rulebook.") else ""
		out.append(String(TranslationServer.translate(ClassicNames.key(key, own))))
	return out


func _stem(role: StringName) -> String:
	var name_text := String(TranslationServer.translate(CockpitText.role_name(String(role))))
	for article: String in ["Das ", "Der ", "Die ", "The "]:
		if name_text.begins_with(article):
			return name_text.trim_prefix(article)
	return name_text


func test_classic_game_shows_sheet_names_and_base_game_stays_unchanged() -> void:
	TranslationServer.set_locale("de")
	var classic := RulesEngine.replay([Fixtures.start_roles(CLASSIC_CAST)])
	assert_true(classic.ok, "Start %s" % classic.error)
	ClassicNames.active = ClassicNames.detect(classic.state)
	assert_true(ClassicNames.active, "Classic-Partie erkannt")
	var joined := " ".join(_texts())
	for mech: StringName in MECHANICS:
		assert_false(joined.contains(_stem(mech)), "Grundspiel-Name %s fehlt im Classic-Text" % mech)
	assert_true(joined.contains("Seherin") and joined.contains("Hexe"), "Namen des Bogens stehen da")
	ClassicNames.active = ClassicNames.detect(RulesEngine.replay([Fixtures.start_roles(["werwolf", "orakel", "dorfbewohner", "dorfbewohner"])]).state)
	assert_false(ClassicNames.active, "Grundspiel-Partie ist nicht Classic")
	assert_true(" ".join(_texts()).contains("Waldhexe"), "Grundspiel zeigt den alten Text")


func test_tetanus_is_not_shown_as_poison() -> void:
	var r := RulesEngine.replay([Fixtures.start_roles(CLASSIC_CAST)])
	var s := r.state
	var knight_id := 0
	for p: Player in s.players.values():
		if p.role_id == RoleCatalog.CLASSIC_RITTER:
			knight_id = p.id
	var target := 0
	for p: Player in s.players.values():
		if p.id != knight_id and target == 0:
			target = p.id
	s.wolf_poisons.append({"target_id": target, "source_id": knight_id, "due_night": 1})
	var kinds: Array = NightBoardView.marks(s).get(target, [])
	assert_false(kinds.has("poisoned"), "Tetanus ist kein Gift")
	assert_true(kinds.has("special"), "Tetanus erscheint als Infektion")
