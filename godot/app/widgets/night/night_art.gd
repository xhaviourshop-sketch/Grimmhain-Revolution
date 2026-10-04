class_name NightArt
extends RefCounted
## Bildquellen des Nachtbretts (P3). Alle Dateien liegen unter `res://assets/night/` und sind nur intern freigegeben (Register-Status
## `intern-freigegeben`, Veröffentlichung gesperrt). Texturen werden einmal geladen und zwischengespeichert. Fehlt eine Datei
## (z. B. vor dem Import), liefert `texture` null; alle Zeichner prüfen darauf und lassen das Bild dann weg, statt abzustürzen.
## Keine Texte in Bildern: Beschriftungen kommen immer aus der Übersetzung.

const ROOT := "res://assets/night/"
## Abzeichenarten, für die es ein Bild gibt (siehe NightBoardView.KINDS und „dead“).
const BADGE_KINDS: Array[String] = ["protected", "poisoned", "marked", "silenced", "special", "dead"]

static var _cache: Dictionary = {}


static func texture(relative_path: String) -> Texture2D:
	if _cache.has(relative_path):
		return _cache[relative_path]
	var path := ROOT + relative_path
	var tex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
	_cache[relative_path] = tex
	return tex


static func portrait(person_id: int) -> Texture2D:
	return texture("portraits/face-%02d.webp" % PortraitAssignment.face_number(person_id))


static func badge(kind: String) -> Texture2D:
	return texture("badges/badge-%s.png" % kind)


static func ring(name: String) -> Texture2D:
	return texture("frames/ring-%s.png" % name)


## Teamsymbol der Vorbereitung: `team` ist die Katalog-Fraktion (village, wolves, solo), Bild `team/team-<name>.png`.
static func team(team_id: StringName) -> Texture2D:
	return texture("team/team-%s.png" % String(team_id))


## Bildschlüssel einer Rolle: Gruppenschritte ohne eigenes Bild zeigen das Bild der zugehörigen Rolle („Alle Verzauberten“ den
## Rattenfänger, das Rudel den Werwolf).
static func image_key(role_id: String) -> String:
	if role_id == "piper-all":
		return "rattenfaenger"
	if role_id == "pack" or role_id == "pack2":
		return "werwolf"
	return role_id


## Rollensymbol der Nachtleiste (klein): immer das Silbersymbol. Fehlt es, steht vorerst das Kreisbild der Rolle entsättigt und
## abgedunkelt im Medaillon, damit die Leiste ruhig wirkt. Das gemalte Rollenbild gehört nur auf die große Aktionskarte (`role_art`).
static func role_symbol(role_id: String) -> Texture2D:
	var key := image_key(role_id)
	var emblem := texture("emblems/%s.png" % key)
	return emblem if emblem != null else _muted_circle(key)


static var _muted: Dictionary = {}
const MUTED_BRIGHTNESS := 0.85


static func _muted_circle(key: String) -> Texture2D:
	if _muted.has(key):
		return _muted[key]
	var source := texture("role-circle/%s.webp" % key)
	var result: Texture2D = null
	if source != null:
		var image := source.get_image()
		if image != null:
			if image.is_compressed():
				image.decompress()
			image.convert(Image.FORMAT_RGBA8)
			image.adjust_bcs(MUTED_BRIGHTNESS, 1.0, 0.0)
			result = ImageTexture.create_from_image(image)
	_muted[key] = result
	return result


## Rollenbild der Aktionskarte (vorläufig laut PILOT-STATUS) oder null.
static func role_art(role_id: String) -> Texture2D:
	return texture("role-art/%s.webp" % image_key(role_id))


## Ob die Datei eines Rollensymbols als Emblem (nicht als Kreisbild) vorliegt.
static func has_emblem(role_id: String) -> bool:
	return ResourceLoader.exists(ROOT + "emblems/%s.png" % role_id)
