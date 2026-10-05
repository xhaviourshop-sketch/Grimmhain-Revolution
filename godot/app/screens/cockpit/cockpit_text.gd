class_name CockpitText
extends RefCounted
## Übersetzungsschlüssel des Cockpits. Spezifische Texte je Rolle und Stufe, sonst ein generischer
## Text je Antwortart. Welche Rollen eigene Texte haben, prüft test_cockpit_texts.
##   Rollenname          ui.role.<rolle>.name, Gruppen ui.cockpit.group.<gruppe>
##   Vorlesetext         ui.call.<rolle> (Rückfall ui.call.generic mit Rollenname)
##   Titel und Hilfe    ui.night.<besitzer>.<stufe>.title / .help (Stufe „pick“ für einstufige Prompts),
##                       Rückfall ui.night.generic.title bzw. ui.night.generic.help.<antwortart>
##   Teilantwort         ui.prompt.info.<feld> (Rückfall ui.prompt.info.generic)

const GROUPS := {"pack": "ui.cockpit.group.pack", "die-gebundenen": "ui.cockpit.group.bound", "die-ewigen": "ui.cockpit.group.eternal", "piper-all": "ui.cockpit.group.piper_all", "reaction": "ui.cockpit.group.reaction"}


static func key_part(id: String) -> String:
	return id.replace("-", "_")


static func has_key(key: String) -> bool:
	return TranslationServer.translate(key) != StringName(key)


## Rollen- oder Gruppenname als Schlüssel (StringName, damit GrimmLabel ihn übersetzt).
static func role_name(role_id: String) -> StringName:
	if GROUPS.has(role_id):
		return StringName(GROUPS[role_id])
	return StringName("ui.role.%s.name" % key_part(role_id))


## Rolle der Kontexthilfe zur aktuellen Handlung (Schritt, Prompt, Hinweis) oder "" ohne passenden Lexikoneintrag. Das
## Rudel verweist auf den Werwolf, „Alle Verzauberten“ auf den Rattenfänger; bei der anonymen Frage an die von
## Rotkäppchen gefragte Person gilt der Prompt-Besitzer.
const NOTICE_HELP := {"loki_bond": "loki", "piper_new": "rattenfaenger", "pest_infected": "pestbringerin"}


static func help_role(next: Dictionary) -> String:
	var role := ""
	match str(next.get("kind")):
		"begin_step", "prompt":
			role = str(next.get("role_id", ""))
			if role == "":
				role = str(next.get("owner", ""))
			if role == str(CockpitView.GROUP_PACK):
				role = String(RoleCatalog.WERWOLF)
			elif role == str(CockpitView.GROUP_PIPER_ALL):
				role = String(RoleCatalog.RATTENFAENGER)
		"notice":
			role = str(NOTICE_HELP.get(str(next.get("notice_kind", "")), ""))
	return role if RoleCatalog.has_role(StringName(role)) else ""


static func call_key(role_id: String) -> String:
	var key := "ui.call.%s" % key_part(role_id)
	return key if has_key(key) else "ui.call.generic"


## Titel und Hilfe der Nacht-Schablone: ui.night.<besitzer>.<stufe>.title und .help (Stufe „pick“ für einstufige Prompts, bei
## Reaktionen Besitzer „reaction“ und Stufe = Art). Den Titel nennt `night_title_key`, die Hilfe `night_help_key`; ohne Eintrag
## der Rollenname bzw. der Hilfetext je Antwortart.
static func night_base(next: Dictionary) -> String:
	var owner := str(next.get("owner", ""))
	var stage := str(next.get("reaction_kind", "")) if owner == "reaction" else str(next.get("stage", ""))
	return "ui.night.%s.%s" % [key_part(owner), stage if stage != "" else "pick"]


static func night_title_key(next: Dictionary) -> String:
	var key := night_base(next) + ".title"
	return key if has_key(key) else "ui.night.generic.title"


## Regelzeilen der Rolle (bis zu 3, ohne Bedienwörter) unter dem Titel der Nachtkarte: `ui.night.rules.<rolle>`. Ersetzt die Hilfe der Stufe,
## sobald die Rolle Zeilen hat.
static func night_rules_key(role: String) -> String:
	var key := "ui.night.rules.%s" % ("werwolf" if role == "pack" else key_part(role))  # der Rudelschritt zeigt die Regeln des Werwolfs
	return key if has_key(key) else ""


static func night_help_key(next: Dictionary) -> String:
	var key := night_base(next) + ".help"
	return key if has_key(key) else "ui.night.generic.help.%s" % str(next.get("answer", "targets"))


## Beschriftung einer Aktion mit rollenspezifischer Variante, z. B. Loki „Liebende“ statt „Ja“:
## ui.cockpit.action.<aktion>.<besitzer>.<stufe>, sonst ui.cockpit.action.<aktion>.
static func action_key(action: String, owner: String, stage: String) -> String:
	var key := "ui.cockpit.action.%s.%s.%s" % [action, key_part(owner), stage if stage != "" else "pick"]
	return key if has_key(key) else "ui.cockpit.action.%s" % action


## Anweisung einer Karteneingabe: kartenspezifisch (`ui.card.<id>.input.<eingabe>`), sonst allgemein je Eingabe
## (`ui.card.input.<eingabe>`), bei Aufgaben zuerst `ui.card.task.<art>.<eingabe>`, zuletzt der Rückfall je Antwortart.
static func card_instruction_key(next: Dictionary) -> String:
	var input := str(next.get("input_key", ""))
	var card_id := str((next.get("card", {}) as Dictionary).get("card_id", ""))
	var task := str(next.get("task_kind", ""))
	var stage := str(next.get("stage", ""))
	for key: String in ["ui.card.task.%s.%s" % [task, input], "ui.card.%s.input.%s" % [card_id, input], "ui.card.input.%s.%s" % [input, stage], "ui.card.input.%s" % input]:
		if task == "" and key.begins_with("ui.card.task."):
			continue
		if has_key(key):
			return key
	return "ui.prompt.generic.%s" % str(next.get("answer", "targets"))


## Beschriftung einer Option einer Karteneingabe: Rollen mit Namen, sonst `ui.card.option.<art>.<wert>`.
static func card_option_key(kind: String, value: String) -> String:
	if kind == "role":
		return role_name(value)
	return "ui.card.option.%s.%s" % [kind, value]


## Vorlesezeilen öffentlicher Kartenereignisse [{key, values}]: Karte mit ihrem Text, dazu die genannten Personen und Zahlen.
static func card_lines(public_cards: Array) -> Array:
	var out: Array = []
	for c: Dictionary in public_cards:
		var card_id := str(c.get("card_id", ""))
		var card_name: Variant = StringName(CardCatalog.name_key(StringName(card_id))) if CardCatalog.CARDS.has(StringName(card_id)) else ""
		match str(c["kind"]):
			"announced":
				var variant := StringName(str(c["variant"]))
				out.append({"key": "ui.card.public.played", "values": {"card": card_name}})
				if CardCatalog.CARDS.has(StringName(card_id)):
					out.append({"key": CardCatalog.text_key(StringName(card_id), variant), "values": {}})
				var values: Dictionary = c.get("values", {})
				var keys := values.keys()
				keys.sort()
				for k: Variant in keys:
					var line := _card_value_line(str(k), values[k])
					if not line.is_empty():
						out.append(line)
			"role_revealed":
				out.append({"key": "ui.card.public.role_revealed", "values": {"name": str((c["person"] as Dictionary).get("name", "")), "role": role_name(str(c["role_id"])), "card": card_name}})
			"revived":
				out.append({"key": "ui.card.public.revived", "values": {"name": str((c["person"] as Dictionary).get("name", ""))}})
			"question":
				out.append({"key": "ui.card.public.question", "values": {"asker": str((c["asker"] as Dictionary).get("name", "")), "subject": str((c["subject"] as Dictionary).get("name", "")),
					"answer": StringName("ui.common.yes" if bool(c["answer"]) else "ui.common.no")}})
			"marker":
				out.append({"key": "ui.card.public.marker", "values": {"name": str((c["person"] as Dictionary).get("name", ""))}})
			"excluded":
				out.append({"key": "ui.card.public.excluded", "values": {"name": str((c["person"] as Dictionary).get("name", ""))}})
			"dice":
				out.append({"key": "ui.card.public.dice", "values": {"name": str((c["person"] as Dictionary).get("name", "")), "dice": ", ".join((c["dice"] as Array).map(func(v: Variant) -> String: return str(int(v))))}})
			"swallower":
				out.append({"key": "ui.card.public.swallower", "values": {"total": int(c["total"])}})
			"night_skipped":
				out.append({"key": "ui.card.public.night_skipped", "values": {"night": int(c["night"])}})
	return out


## Zeile zu einem Wert einer Ansage: Personen (`*_id`, `*_ids`) mit Beschriftung, Zahlen und Wahrheitswerte; unbekannte Arten entfallen.
static func _card_value_line(key: String, value: Variant) -> Dictionary:
	var label_key := "ui.card.public.value.%s" % key
	if not has_key(label_key):
		return {}
	if value is Array:
		if (value as Array).is_empty():
			return {"key": label_key, "values": {"value": StringName("ui.prompt.value.nobody")}}
		return {"key": label_key, "values": {"value": spoken_names(value)}}
	if value is Dictionary:
		return {"key": label_key, "values": {"value": str((value as Dictionary).get("name", "")) if not (value as Dictionary).is_empty() else StringName("ui.prompt.value.nobody")}}
	if value is bool:
		return {"key": label_key, "values": {"value": StringName("ui.common.yes" if value else "ui.common.no")}}
	if value is String and has_key("ui.card.option.value.%s" % value):
		return {"key": label_key, "values": {"value": StringName("ui.card.option.value.%s" % value)}}
	return {"key": label_key, "values": {"value": str(value)}}


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
		"roles":
			var numbered: Array = []
			for i: int in (value as Array).size():
				numbered.append("%d: %s" % [i + 1, TranslationServer.translate(role_name(str((value as Array)[i])))])
			return ", ".join(numbered)
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
	for e: Dictionary in pub.get("effects", []):
		out.append(effect_line(e))
	out.append_array(card_lines(pub.get("cards", [])))
	return out


## Angesagter Todeseffekt (DI-03) als {key, values}: Effekt und Rolle zum Ereigniszeitpunkt, Namen ohne Platznummer.
## Liebeskummer, Kette und Verknüpfung nennen die Rolle, von der der Effekt stammt (PE-05).
static func effect_line(e: Dictionary) -> Dictionary:
	var role := str(e.get("role_id", ""))
	return {"key": "ui.effect.%s" % str(e["effect"]), "values": {
		"name": str((e.get("source", {}) as Dictionary).get("name", "")),
		"role": role_name(role) if role != "" else "",
		"target": spoken_names(e.get("targets", [])),
		"replaced": str((e.get("replaced", {}) as Dictionary).get("name", ""))}}


## Werte einer Hinweiskarte (DI-04, DI-06, DI-07): Personen als „3 · Anna“, Listen als kommagetrennter Text.
static func notice_values(values: Dictionary) -> Dictionary:
	var out := {}
	for k: Variant in values:
		var v: Variant = values[k]
		if v is Dictionary:
			out[k] = person(v)
		elif v is Array:
			out[k] = ", ".join((v as Array).map(func(x: Variant) -> String: return person(x)))
		else:
			out[k] = v
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


## Feste Auswahl wird sofort übernommen („genau 2“, „genau 3“, 0 oder alle, eine Person mit Verzicht); dann gibt es kein Bestätigen.
## Anzahlbereiche (1 bis 2), Zufallsvorschläge (müssen bestätigt werden, RM-DR-015.2) und Karteneingaben bestätigt die Spielleitung.
static func auto_commit(next: Dictionary) -> bool:
	if str(next.get("answer")) != "targets" or str(next.get("owner")) == "card" or bool(next.get("random", false)):
		return false
	var high := int(next.get("max", 0))
	var counts: Array = next.get("counts", [])
	return high >= 1 and not counts.is_empty() and counts.all(func(c: Variant) -> bool: return int(c) == 0 or int(c) == high)


## Zulässige Anzahlen als Text: [2] → „2“, [0, 3] → „0 oder 3“, [1, 2, 3] → „1 bis 3“.
static func count_list(counts: Array) -> String:
	if counts.size() >= 3 and int(counts.back()) - int(counts[0]) == counts.size() - 1:
		return TranslationServer.translate("ui.cockpit.card.selection.range").format({"from": int(counts[0]), "to": int(counts.back())})
	var parts: Array = counts.map(func(n: Variant) -> String: return str(int(n)))
	return (" %s " % TranslationServer.translate("ui.cockpit.card.selection.or")).join(parts)


## „SeatDied“ → „seat_died“ (Schlüsselteil aus einem Ereignis- oder Befehlstyp).
static func snake(type: String) -> String:
	var out := ""
	for i: int in type.length():
		var ch := type[i]
		out += ("_" if i > 0 and ch == ch.to_upper() and ch != ch.to_lower() else "") + ch.to_lower()
	return out


## Beschreibung eines Befehls (CockpitView.command_info) als {key, values} für Rückgängig/Wiederholen.
static func command_label(info: Dictionary) -> Dictionary:
	if info.is_empty():
		return {"key": "ui.gm.command.none", "values": {}}
	var type := str(info["type"])
	var part := snake(type)
	var names: Array = []
	for p: Dictionary in info.get("persons", []):
		names.append(person(p))
	if part == "answer_prompt" and str(info.get("stage", "")) == "":
		part = "answer_prompt_single"
	var key := "ui.gm.command.%s" % part
	return {"key": key if has_key(key) else "ui.gm.command.generic", "values": {
		"type": type, "role": role_name(str(info["role_id"])) if str(info.get("role_id", "")) != "" else "",
		"stage": StringName("ui.gm.stage.%s" % str(info["stage"])) if has_key("ui.gm.stage.%s" % str(info.get("stage", ""))) else str(info.get("stage", "")), "names": ", ".join(names) if not names.is_empty() else "–",
		"kind": StringName("ui.gm.kind.%s" % str(info["kind"])) if str(info.get("kind", "")) != "" else ""}}


## Bisheriger Wert einer Spezialkorrektur ({key, values}) als Text: Personenlabels als „3 · Anna“, Schlüssel und Wahrheitswerte übersetzt.
static func state_text(state: Dictionary) -> String:
	if state.is_empty():
		return ""
	var values := {}
	for k: Variant in (state["values"] as Dictionary):
		var v: Variant = (state["values"] as Dictionary)[k]
		if v is Dictionary:
			values[k] = person(v)
		elif v is bool:
			values[k] = TranslationServer.translate("ui.common.yes" if v else "ui.common.no")
		elif v is StringName:
			values[k] = TranslationServer.translate(v)
		else:
			values[k] = str(v)
	return TranslationServer.translate(str(state["key"])).format(values)


## Personen-IDs als „3 · Anna, 5 · Ben“ aus den öffentlichen Sitzdaten.
static func names_of(ids: Array, seats: Array) -> String:
	var names: Array = []
	for id: Variant in ids:
		for seat: Dictionary in seats:
			if int(seat["person_id"]) == int(id):
				names.append(person(seat))
	return ", ".join(names)
