class_name RoleCopy
extends RefCounted
## Eine einzeln geführte Rollenkopie im Setup: nur für Rollen mit Pflicht-Scheinrolle
## (Katalog `requires_appearance`, derzeit Trugbilderwolf). Rolle und die vom Spielleiter
## ausdrücklich gewählte Scheinrolle bilden eine Einheit (DR-08), die gemeinsam verteilt,
## gemischt und getauscht wird. `copy_id` ist stabil und wird nie als Produkttext gezeigt.
## Entspricht später einem Eintrag `{role_id, appears_as}` in `role_entries` von StartGame.

const KEY_SEPARATOR := "#"

var copy_id: int = 0
var role_id: StringName = &""
var appears_as: StringName = &""   ## leer = noch nicht festgelegt; keine Vorbelegung


func _init(p_copy_id: int = 0, p_role_id: StringName = &"") -> void:
	copy_id = p_copy_id
	role_id = p_role_id


func is_configured() -> bool:
	return appears_as != &""


## Verteilungsschlüssel dieser Kopie, z. B. `trugbilderwolf#2`.
func key() -> StringName:
	return StringName("%s%s%d" % [String(role_id), KEY_SEPARATOR, copy_id])


## Rollen-ID eines Verteilungsschlüssels (Kopie oder einfache Rollen-ID).
static func role_of(entry_key: StringName) -> StringName:
	return StringName(String(entry_key).get_slice(KEY_SEPARATOR, 0))


static func is_copy_key(entry_key: StringName) -> bool:
	return String(entry_key).contains(KEY_SEPARATOR)
