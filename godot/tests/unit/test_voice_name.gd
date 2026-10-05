extends TestCase
## Namen per Sprache: der erkannte Text wird zum Namen bereinigt (Satzzeichen weg, Anfangsbuchstaben groß).


func test_clean_recognized_name() -> void:
	assert_eq(VoiceName.clean("timo."), "Timo", "Punkt weg, erster Buchstabe groß")
	assert_eq(VoiceName.clean("  jana,  "), "Jana", "Komma und Leerraum weg")
	assert_eq(VoiceName.clean("anna maria!"), "Anna Maria", "zwei Wörter bleiben ein Name")
	assert_eq(VoiceName.clean("Jörg-Peter"), "Jörg-Peter", "Umlaute und Bindestrich bleiben")
	assert_eq(VoiceName.clean("?!."), "", "nur Satzzeichen ergeben nichts")
	assert_eq(VoiceName.clean(""), "", "leerer Text")
