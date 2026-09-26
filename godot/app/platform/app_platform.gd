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


## Beenden-Button nur auf Desktop; auf Mobilgeräten beendet das System die App.
static func can_quit_from_menu() -> bool:
	return not is_mobile()


## Zentrale Versionsquelle: `application/config/version` in project.godot.
static func app_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
