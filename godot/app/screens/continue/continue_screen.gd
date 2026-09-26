class_name ContinueScreen
extends BaseScreen
## Platzhalter: leerer Zustand „Kein Spielstand vorhanden“ und Bereich `%SaveSlotList` für
## spätere Spielstandkarten. Noch kein Dateisystem, kein Autosave.


func _setup() -> void:
	(%Card as Control).custom_minimum_size.x = ThemeTokens.CONTENT_MAX_WIDTH
