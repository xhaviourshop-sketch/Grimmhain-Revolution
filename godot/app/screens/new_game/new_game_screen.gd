class_name NewGameScreen
extends BaseScreen
## Platzhalter: Die Einrichtung (Namen, Rollen, Sitzordnung) folgt im nächsten Arbeitspaket.
## Keine Spielerdaten, keine Setup-Logik.


func _setup() -> void:
	(%Card as Control).custom_minimum_size.x = ThemeTokens.CONTENT_MAX_WIDTH
