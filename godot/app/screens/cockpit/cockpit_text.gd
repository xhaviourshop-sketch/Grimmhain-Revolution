class_name CockpitText
extends RefCounted
## Übersetzungsschlüssel des Cockpits. Spezifische Texte je Rolle und Stufe, sonst ein generischer
## Text je Antwortart. Welche Rollen eigene Texte haben, prüft test_cockpit_texts.
##   Rollenname          ui.role.<rolle>.name, Gruppen ui.cockpit.group.<gruppe>
##   Vorlesetext         ui.call.<rolle> (Rückfall ui.call.generic mit Rollenname)
##   Anweisung           ui.prompt.<besitzer>.<stufe> (Stufe „pick“ für einstufige Prompts),
##                       Rückfall ui.prompt.generic.<antwortart>
##   Teilantwort         ui.prompt.info.<feld> (Rückfall ui.prompt.info.generic)

const GROUPS := {"pack": "ui.cockpit.group.pack", "die-gebundenen": "ui.cockpit.group.bound", "die-ewigen": "ui.cockpit.group.eternal", "reaction": "ui.cockpit.group.reaction"}


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


## Vorlesezeilen des öffentlichen Morgenberichts [{key, values}] (nur Werte der Positivliste).
## Namen ohne Platznummer, mit Rolle nur, wenn der Bericht sie enthält (Setup-Option).
static func morning_lines(pub: Dictionary) -> Array:
	var out: Array = [{"key": "ui.morning.read.intro", "values": {}}]
	var deaths: Array = pub.get("deaths", [])
	if deaths.is_empty():
		out.append({"key": "ui.morning.read.nobody", "values": {}})
	else:
		out.append({"key": "ui.morning.read.deaths_one" if deaths.size() == 1 else "ui.morning.read.deaths_many", "values": {"names": spoken_names(deaths)}})
	var revived: Array = pub.get("revived", [])
	if not revived.is_empty():
		out.append({"key": "ui.morning.read.revived", "values": {"names": spoken_names(revived)}})
	for n: Dictionary in pub.get("notices", []):
		var values := {}
		if n.has("person"):
			values["name"] = str((n["person"] as Dictionary).get("name", ""))
		if n.has("direction"):
			values["direction"] = StringName("ui.prompt.direction.%s" % str(n["direction"]))
		out.append({"key": str(n["key"]), "values": values})
	return out


## „Anna, Ben (Werwolf)“: Rolle nur, wenn der Eintrag eine öffentliche Rolle trägt.
static func spoken_names(people: Array) -> String:
	var names: Array = []
	for p: Dictionary in people:
		var role := str(p.get("role_id", ""))
		if role == "":
			names.append(str(p["name"]))
		else:
			names.append(TranslationServer.translate("ui.morning.name_with_role").format({"name": str(p["name"]), "role": TranslationServer.translate(role_name(role))}))
	return ", ".join(names)


## Personen-IDs als „3 · Anna, 5 · Ben“ aus den öffentlichen Sitzdaten.
static func names_of(ids: Array, seats: Array) -> String:
	var names: Array = []
	for id: Variant in ids:
		for seat: Dictionary in seats:
			if int(seat["person_id"]) == int(id):
				names.append(person(seat))
	return ", ".join(names)
