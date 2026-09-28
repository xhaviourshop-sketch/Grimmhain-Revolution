class_name CockpitText
extends RefCounted
## Übersetzungsschlüssel des Cockpits. Spezifische Texte je Rolle und Stufe, sonst ein generischer
## Text je Antwortart. Welche Rollen eigene Texte haben, prüft test_cockpit_texts.
##   Rollenname          ui.role.<rolle>.name, Gruppen ui.cockpit.group.<gruppe>
##   Vorlesetext         ui.call.<rolle> (Rückfall ui.call.generic mit Rollenname)
##   Anweisung           ui.prompt.<besitzer>.<stufe> (Stufe „pick“ für einstufige Prompts),
##                       Rückfall ui.prompt.generic.<antwortart>
##   Teilantwort         ui.prompt.info.<feld> (Rückfall ui.prompt.info.generic)

const GROUPS := {"pack": "ui.cockpit.group.pack", "die-gebundenen": "ui.cockpit.group.bound", "die-ewigen": "ui.cockpit.group.eternal"}


static func key_part(id: String) -> String:
	return id.replace("-", "_")


static func has_key(key: String) -> bool:
	return TranslationServer.translate(key) != StringName(key)


## Rollen- oder Gruppenname als Schlüssel (StringName, damit GrimmLabel ihn übersetzt).
static func role_name(role_id: String) -> StringName:
	if GROUPS.has(role_id):
		return StringName(GROUPS[role_id])
	return StringName("ui.role.%s.name" % key_part(role_id))


static func call_key(role_id: String) -> String:
	var key := "ui.call.%s" % key_part(role_id)
	return key if has_key(key) else "ui.call.generic"


static func instruction_key(owner: String, stage: String, answer: String) -> String:
	var key := "ui.prompt.%s.%s" % [key_part(owner), stage if stage != "" else "pick"]
	return key if has_key(key) else "ui.prompt.generic.%s" % answer


## Beschriftung einer Aktion mit rollenspezifischer Variante, z. B. Loki „Liebende“ statt „Ja“:
## ui.cockpit.action.<aktion>.<besitzer>.<stufe>, sonst ui.cockpit.action.<aktion>.
static func action_key(action: String, owner: String, stage: String) -> String:
	var key := "ui.cockpit.action.%s.%s.%s" % [action, key_part(owner), stage if stage != "" else "pick"]
	return key if has_key(key) else "ui.cockpit.action.%s" % action


static func reaction_key(kind: String) -> String:
	var key := "ui.prompt.reaction.%s" % kind
	return key if has_key(key) else "ui.prompt.generic.targets"


static func info_key(field: String) -> String:
	var key := "ui.prompt.info.%s" % field
	return key if has_key(key) else "ui.prompt.info.generic"


## „3 · Anna“ aus einem Personeneintrag {seat, name} (Nutzerdaten, keine Übersetzung).
static func person(label: Dictionary) -> String:
	return "%d · %s" % [int(label.get("seat", 0)), str(label.get("name", ""))]


## Anzeigewert einer Info-Zeile {key, kind, value} als Text bzw. Schlüssel (StringName).
static func info_value(line: Dictionary) -> Variant:
	var value: Variant = line.get("value")
	match str(line.get("kind")):
		"role":
			return role_name(str(value))
		"person":
			return person(value) if value is Dictionary else StringName("ui.prompt.value.nobody")
		"persons":
			var names: Array = []
			for v: Variant in value:
				names.append(person(v))
			return ", ".join(names) if not names.is_empty() else StringName("ui.prompt.value.nobody")
		"bool":
			return StringName("ui.common.yes") if bool(value) else StringName("ui.common.no")
		"direction":
			return StringName("ui.prompt.direction.%s" % str(value))
	return str(value)


## Personen-IDs als „3 · Anna, 5 · Ben“ aus den öffentlichen Sitzdaten.
static func names_of(ids: Array, seats: Array) -> String:
	var names: Array = []
	for id: Variant in ids:
		for seat: Dictionary in seats:
			if int(seat["person_id"]) == int(id):
				names.append(person(seat))
	return ", ".join(names)
