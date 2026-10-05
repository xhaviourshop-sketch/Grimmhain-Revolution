class_name RoleCardImage
extends TextureRect
## Gemaltes Bild der Rollenkarte (`assets/cards/<de|en>/<rolle>.webp`, Hochformat), Sprache nach der aktuellen Sprache der App.
## Kein Text: Das Bild zeigt Name und Fähigkeit selbst. Fehlt das Bild einer Rolle, steht an seinem Platz das Rollensymbol.
## Die Größe gibt der Container vor (Seitenverhältnis bleibt erhalten, nichts wird beschnitten).

const MIN_HEIGHT := 160.0

var role_id: String = "":
	set(value):
		role_id = value
		_refresh()


func _init() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(0.0, MIN_HEIGHT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh()


## Pfad des Kartenbilds dieser Rolle in der aktuellen Sprache.
static func path_for(id: String) -> String:
	var lang := "en" if TranslationServer.get_locale().begins_with("en") else "de"
	return "res://assets/cards/%s/%s.webp" % [lang, id.replace("-", "_")]


func _refresh() -> void:
	if role_id == "":
		texture = null
		return
	var path := path_for(role_id)
	texture = load(path) as Texture2D if ResourceLoader.exists(path) else NightArt.role_symbol(role_id)
