class_name ReportText
extends RefCounted
## Setzt einen Abschlussbericht (GameReport, gespeichert in der Partiehistorie) in die aktuelle Sprache: als Zeilenliste für die
## Ansicht und als UTF-8-Text für den Export. Die Fassung bestimmt den Umfang: `PUBLIC` die am Tisch bekannten Angaben und, nach
## bestätigtem Spielende (`reveal`), alle Rollen zum Spielende, die Sieger und die Siegbedingung (NQ-07); `GM` alle Angaben für die
## Spielleitung. Ohne `reveal` (Siegbestätigung zurückgenommen) fehlt die Freigabe wieder. Geheime Ziele, Schutzmarkierungen, private
## Entscheidungen, Ursachen und Rollenwechselverläufe stehen nie in der öffentlichen Fassung. Nichts hier verändert einen Spielstand;
## kein rohes Wörterbuch wird ausgegeben.

const PUBLIC := "public"
const GM := "gm"


## Zeilen [{style: "title"|"heading"|"line"|"note", text}] der Fassung in der aktuellen Sprache.
static func lines(report: Dictionary, version: String, reveal: bool = true) -> Array[Dictionary]:
	var gm := version == GM
	var show_end := gm or reveal  ## Rollen, Sieger und Siegbedingung: für die Spielleitung immer, öffentlich nur nach bestätigtem Spielende
	var out: Array[Dictionary] = []
	out.append({"style": "title", "text": _t("ui.report.title.gm" if gm else "ui.report.title.public")})
	out.append({"style": "note", "text": _t("ui.report.note.gm" if gm else ("ui.report.note.public" if reveal else "ui.report.note.public_locked"))})
	out.append({"style": "line", "text": _t("ui.log.line.game_started", {"count": int(report.get("players", 0))})})  # dieselbe Formulierung wie im Protokoll; die Partie-ID ist kein Anzeigetext
	out.append({"style": "line", "text": _t("ui.report.participants", {"names": ", ".join(PackedStringArray(report.get("names", [])))})})
	out.append({"style": "line", "text": _t("ui.report.played", {"nights": int(report.get("nights", 0)), "days": int(report.get("days", 0))})})
	var winner: Dictionary = report.get("winner", {})
	if show_end:  # S-08: eine wieder geöffnete Partie nennt öffentlich keinen Sieger mehr
		out.append({"style": "line", "text": _t("ui.report.result", {"side": StringName(_side_key(str(winner.get("side", "none"))))})})
		var reason := str(winner.get("reason_key", ""))
		if reason != "":
			out.append({"style": "line", "text": _t("ui.report.win_reason", {"reason": StringName(_reason_key(reason))})})
		var people: Array = []
		people.append_array(winner.get("names", []))
		people.append_array(winner.get("co_names", []))
		people.append_array(winner.get("card_co_names", []))  # stille Mitsieger der Totenreichkarten
		if not people.is_empty():
			out.append({"style": "line", "text": _t("ui.report.winners", {"names": ", ".join(PackedStringArray(people))})})
		var roles: Array = report.get("roles", [])
		if not roles.is_empty():  # ältere oder unvollständige Berichte werden nicht ergänzt
			out.append({"style": "heading", "text": _t("ui.report.heading.roles")})
		for r: Dictionary in roles:
			var text := _t("ui.report.role_line", {"name": str(r.get("name", "")), "role": StringName(str(CockpitText.role_name(str(r.get("role_id", "")))))})
			if gm and str(r.get("original_role_id", "")) != str(r.get("role_id", "")):
				text += " " + _t("ui.report.role_original", {"role": StringName(str(CockpitText.role_name(str(r.get("original_role_id", "")))))})
			if not bool(r.get("alive", true)):
				text += " †"
			out.append({"style": "line", "text": text})
	out.append({"style": "heading", "text": _t("ui.report.heading.history")})
	var any := false
	for entry: Dictionary in _fold_executions(report.get("entries", []), gm):
		if not gm and str(entry.get("vis", "")) != PUBLIC:
			continue
		any = _entry(entry, out) or any
	if gm and int(report.get("other_events", 0)) > 0:
		out.append({"style": "note", "text": _t("ui.report.other_events", {"count": int(report["other_events"])})})
	if not any:
		out.append({"style": "line", "text": _t("ui.report.no_history")})
	return out


## UTF-8-Text der Fassung: Überschriften unterstrichen, jede Zeile eine Textzeile.
static func plain_text(report: Dictionary, version: String, reveal: bool = true) -> String:
	var parts: Array[String] = []
	for line: Dictionary in lines(report, version, reveal):
		var text := str(line["text"])
		match str(line["style"]):
			"title":
				parts.append(text)
				parts.append("=".repeat(text.length()))
			"heading":
				parts.append("")
				parts.append(text)
				parts.append("-".repeat(text.length()))
			_:
				parts.append(text)
	return "\n".join(parts) + "\n"


static func _entry(entry: Dictionary, out: Array[Dictionary]) -> bool:
	match str(entry.get("kind", "")):
		"night":
			out.append({"style": "heading", "text": _t("ui.report.night", {"number": int(entry["number"])})})
		"day":
			out.append({"style": "heading", "text": _t("ui.report.day", {"number": int(entry["number"])})})
		"morning":
			var lines: Array = CockpitText.morning_lines(entry.get("report", {}))
			for i: int in range(1, lines.size()):  # die Einleitung „Die Sonne geht auf“ entfällt im Bericht
				out.append({"style": "line", "text": _t(str(lines[i]["key"]), lines[i]["values"])})
		"nomination":
			out.append({"style": "line", "text": _t("ui.cockpit.card.day.nomination", {"nominator": str(entry["nominator"]), "nominee": str(entry["nominee"])})})
		"nomination_hidden":
			out.append({"style": "line", "text": _t("ui.cockpit.card.day.nomination_hidden", {"nominee": str(entry["nominee"])})})
		"judge_nominator":
			out.append({"style": "line", "text": _t("ui.report.judge_nominator", {"judge": str(entry["judge"]), "nominee": str(entry["nominee"])})})
		"execution":
			var role := str(entry.get("role_id", ""))
			var said := LogText.executed(str(entry["name"]))
			if role != "":  # die Rolle im selben Satz
				said = said.trim_suffix(".") + " (%s)." % _t(str(CockpitText.role_name(role)))
			out.append({"style": "line", "text": said})
		"execution_override":
			out.append({"style": "line", "text": _t("ui.report.execution_override", {"name": str(entry["name"])})})
		"execution_redirected":
			out.append({"style": "line", "text": _t("ui.report.execution_redirected", {"name": str(entry["name"]), "other": str(entry["other"])})})
		"no_execution":
			out.append({"style": "line", "text": LogText.no_execution()})
		"death":
			var role := str(entry.get("role_id", ""))
			if role == "":
				out.append({"style": "line", "text": LogText.died(str(entry["name"]))})
			else:
				out.append({"style": "line", "text": LogText.died(str(entry["name"]), role)})
		"death_cause":
			out.append({"style": "line", "text": _t("ui.morning.private.death", {"name": str(entry["name"]), "cause": _cause_key(str(entry["cause"])),
				"role": StringName(str(CockpitText.role_name(str(entry["role_id"]))))})})
		"revived":
			out.append({"style": "line", "text": LogText.revived(str(entry["name"]))})
		"effects":
			for e: Dictionary in entry.get("effects", []):
				var line := CockpitText.effect_line(e)
				out.append({"style": "line", "text": _t(str(line["key"]), line["values"])})
		"cards":
			for line: Dictionary in CockpitText.card_lines(entry.get("cards", [])):
				out.append({"style": "line", "text": _t(str(line["key"]), line["values"])})
		"night_private":
			for line: Dictionary in entry.get("lines", []):
				out.append({"style": "line", "text": _private_line(line)})
		"correction":
			var what := _correction_label(str(entry.get("what", "")))
			var name := str(entry.get("name", ""))
			out.append({"style": "line", "text": _t("ui.report.correction" if name != "" else "ui.report.correction_general", {"what": what, "name": name, "reason": str(entry.get("reason", ""))})})
		"win_rejected":
			var why := str(entry.get("reason", ""))
			if why == String(WinCandidate.STATUS_NOT_CHOSEN):  # technischer Ablehnungsgrund: kein Text der Spielleitung
				out.append({"style": "line", "text": _t("ui.report.win_not_chosen")})
			else:
				out.append({"style": "line", "text": _t("ui.report.win_rejected", {"reason": why})})
		"win":
			out.append({"style": "line", "text": _t("ui.report.win", {"side": StringName(_side_key(str(entry.get("side", "none"))))})})
		_:
			return false
	return true


## Eine Hinrichtung ist ein Satz: Tod und Todesursache derselben Person direkt danach (bis zur nächsten Überschrift) gehen in den
## Hinrichtungseintrag auf; dieser trägt dann die Rolle: öffentlich nur, wenn sie am Tisch angesagt wurde, in der Spielleiterfassung
## immer. Das gespeicherte Format bleibt.
static func _fold_executions(entries: Array, gm: bool) -> Array:
	var out: Array = []
	var dropped := {}
	for i: int in entries.size():
		if dropped.has(i):
			continue
		var entry: Dictionary = entries[i]
		if str(entry.get("kind", "")) == "execution":
			entry = entry.duplicate()
			var j := i + 1
			while j < entries.size() and not ["night", "day"].has(str((entries[j] as Dictionary).get("kind", ""))):
				var other: Dictionary = entries[j]
				if ["death", "death_cause"].has(str(other.get("kind", ""))) and str(other.get("name", "")) == str(entry["name"]):
					dropped[j] = true
					if str(other["kind"]) == ("death_cause" if gm else "death"):
						entry["role_id"] = str(other.get("role_id", ""))
				j += 1
		out.append(entry)
	return out


## Zeile des privaten Nachtberichts (Schlüssel und Werte wie im Cockpit-Morgenbereich).
static func _private_line(line: Dictionary) -> String:
	var values := {}
	if line.has("person"):
		values["name"] = str((line["person"] as Dictionary).get("name", ""))
	if line.has("target"):
		values["target"] = str((line["target"] as Dictionary).get("name", "")) if not (line["target"] as Dictionary).is_empty() else ""
	if line.has("role_id"):
		values["role"] = StringName(str(CockpitText.role_name(str(line["role_id"])))) if str(line["role_id"]) != "" else ""
	if line.has("cause"):
		values["cause"] = _cause_key(str(line["cause"]))
	if line.has("reason"):
		values["reason"] = CockpitText.drop_key(str(line["reason"]))
	if line.has("drop"):
		values["drop"] = CockpitText.drop_key(str(line["drop"]))
	return _t(str(line["key"]), values)


static func _correction_label(kind: String) -> String:
	var key := "ui.cockpit.gm.start.%s" % kind
	var text := str(TranslationServer.translate(key))
	return text.trim_suffix(" …").strip_edges() if text != key else _t("ui.report.correction_other")


## Ursache als Übersetzungsschlüssel; eine unbekannte Ursache zeigt nie ihren Namen.
static func _cause_key(cause: String) -> StringName:
	var key := "ui.cause.%s" % cause.to_lower()
	return StringName(key if CockpitText.has_key(key) else "ui.report.cause_other")


static func _side_key(side: String) -> String:
	return "ui.cockpit.win.kind.%s" % (side if ["village", "wolves", "solo", "none"].has(side) else "none")


static func _reason_key(reason: String) -> String:
	var key := "ui.cockpit.win.reason.%s" % reason
	return key if CockpitText.has_key(key) else "ui.cockpit.win.reason.generic"


## Text zu einem Schlüssel; StringName-Werte gelten als Übersetzungsschlüssel.
static func _t(key: String, values: Dictionary = {}) -> String:
	var text := str(TranslationServer.translate(key))
	if values.is_empty():
		return text
	var out := {}
	for k: Variant in values:
		var v: Variant = values[k]
		out[k] = str(TranslationServer.translate(String(v))) if v is StringName else v
	return text.format(out)
