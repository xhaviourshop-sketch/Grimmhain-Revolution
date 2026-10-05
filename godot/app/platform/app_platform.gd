class_name AppPlatform
extends RefCounted
## Plattformabfragen der App an einer Stelle (später Android/iOS/Desktop/Steam, 03 §4.1).
## Tests können die Plattform überschreiben (`set_override`).

const DESKTOP := &"desktop"
const MOBILE := &"mobile"

static var _override: StringName = &""


static func set_override(kind: StringName) -> void:
	_override = kind


static func clear_override() -> void:
	_override = &""


static func is_mobile() -> bool:
	if _override != &"":
		return _override == MOBILE
	return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


## Beenden-Button nur auf Desktop; auf Mobilgeräten beendet das System die App, im Web friert `quit()` die Seite ein (UI-02, DA-93).
static func can_quit_from_menu() -> bool:
	if _override != &"":
		return _override != MOBILE
	return not is_mobile() and not OS.has_feature("web")


## Web/iPad: Godot schreibt Tastatureingaben über ein verstecktes Eingabefeld des Browsers und behält dessen Text, wenn ein Feld per Code geleert
## oder gesetzt wird. Ohne Abgleich hängt der nächste Tastendruck an den alten Text an („Timo“ + „J“ ergibt „TimoJ“). Setzt den Text dieses
## versteckten Felds auf `text` (Cursor ans Ende). Auf allen anderen Plattformen ohne Wirkung.
static func sync_keyboard_text(text: String) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("(function(t){document.querySelectorAll('input[type=text],textarea').forEach(function(e){e.value=t;if(e.style.display!=='none'){e.setSelectionRange(t.length,t.length);}});})(%s)" % JSON.stringify(text), true)


## Kennung des Builds für den Startbildschirm, z. B. „05.10. · 7d8e541“. `tools/export-web.js` schreibt `build_info.json` beim Export
## (nie von Hand, nicht im Repository); ohne Datei (Editor, Tests) gilt die Projektversion.
static func build_label() -> String:
	var path := "res://build_info.json"
	if FileAccess.file_exists(path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and str((data as Dictionary).get("hash", "")) != "":
			return "%s · %s" % [str((data as Dictionary).get("date", "")), str((data as Dictionary)["hash"])]
	return app_version()


## Zentrale Versionsquelle: `application/config/version` in project.godot.
static func app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


## Quelle des ersten Setup-Seeds: Systemzeit in Mikrosekunden gemischt mit dem
## Laufzeitzähler, auf den JSON-sicheren Bereich 1 … MAX_SAFE_INT gebracht. Wird nur beim
## ersten bewussten Verteilen gerufen; danach gilt ausschließlich der gespeicherte Seed.
static func initial_seed() -> int:
	var micros := int(Time.get_unix_time_from_system() * 1000000.0)
	var mixed: int = micros ^ (Time.get_ticks_usec() << 20)
	return posmod(mixed, CanonicalJson.MAX_SAFE_INT) + 1
