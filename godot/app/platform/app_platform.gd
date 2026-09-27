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


## Quelle des ersten Setup-Seeds: Systemzeit in Mikrosekunden gemischt mit dem
## Laufzeitzähler, auf den JSON-sicheren Bereich 1 … MAX_SAFE_INT gebracht. Wird nur beim
## ersten bewussten Verteilen gerufen; danach gilt ausschließlich der gespeicherte Seed.
static func initial_seed() -> int:
	var micros := int(Time.get_unix_time_from_system() * 1000000.0)
	var mixed: int = micros ^ (Time.get_ticks_usec() << 20)
	return posmod(mixed, CanonicalJson.MAX_SAFE_INT) + 1
