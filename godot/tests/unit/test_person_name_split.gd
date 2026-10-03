extends TestCase
## Diktat: Mehrere Namen in einem Text werden an Komma, Semikolon, Zeilenumbruch und den ganzen Wörtern „und“/„and“ getrennt.


func test_split_spoken_names() -> void:
	assert_eq(PersonNameRules.split_spoken("Anna, Ben und Cara\nDora and Emil; Finn"), ["Anna", "Ben", "Cara", "Dora", "Emil", "Finn"] as Array[String], "alle Trenner")
	assert_eq(PersonNameRules.split_spoken("Sandra und Andreas"), ["Sandra", "Andreas"] as Array[String], "Wortteile wie „and“ in Namen trennen nicht")
	assert_eq(PersonNameRules.split_spoken("  Anna Maria  "), ["Anna Maria"] as Array[String], "zwei Wörter bleiben ein Name")
	assert_eq(PersonNameRules.split_spoken("Anna UND Ben AND Cara"), ["Anna", "Ben", "Cara"] as Array[String], "Groß-/Kleinschreibung egal")
	assert_eq(PersonNameRules.split_spoken(" , ; "), [] as Array[String], "nur Trenner ergeben nichts")
