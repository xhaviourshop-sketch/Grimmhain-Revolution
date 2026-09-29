class_name PromptView
extends RefCounted
## Beschreibt den offenen Prompt des Regelkerns für die Aktionskarte, nur mit einfachen Werten.
## Keine Regel: zulässige Personen, Anzahl, Abbrechbarkeit, Stufe und Teilantworten stammen
## unverändert aus `PendingPrompt`; ob eine Antwort gilt, entscheidet allein der Regelkern.
##
## Antwortarten (`answer`), abgeleitet aus Besitzer und Stufe:
##   targets     Personen aus `allowed_ids`; zulässige Anzahlen in `counts` (aus dem Regelkern,
##               z. B. [0, 2] für „keiner oder zwei“; 0 = Verzicht)
##   choice      Ja/Nein
##   ack         nur Bestätigen (Gezeigt, Zur Kenntnis, Zusammenfassung bestätigen)
##   option      eine Option aus `options` (Rollen-IDs)
##   prediction  Zeitpunkt (Nacht/Tag und Nummer) für den Todesprediger
##
## `info` listet Teilantworten und Ergebnisse als Zeilen {key, kind, value}; `kind` sagt der
## Oberfläche, wie der Wert zu zeigen ist (person, persons, role, bool, number, direction, text).
## `show` ist die Positivliste für die Karte, die der handelnden Person gezeigt wird: nur die
## Werte, die sie laut Regel erfährt (entspricht dem ACTOR-Ereignis), nie Wahrheit oder Quelle.

const CHOICE_STAGES: Array[StringName] = [&"heal", &"poison", &"use", &"mode", &"grant", &"barrier"]
const ACK_STAGES: Array[StringName] = [&"confirm", &"shown"]
const OPTION_STAGES: Array[StringName] = [&"option", &"role"]

## Teilantworten, die nur der Wiederaufnahme dienen und nichts zeigen.
const HIDDEN_KEYS: Array[String] = ["rng_after", "options", "heal_offered", "poison_offered", "override_reason", "role_seen", "chosen_index", "option_person_ids"]
const ROLE_KEYS: Array[String] = ["role_id", "victim_role", "truth_role", "determined_role", "shown_role"]

## Zeigbare Teilantworten je Besitzer (in der Stufe „Gezeigt“ bzw. bei der Waldhexe „reveal“).
const SHOW_KEYS := {
	&"das-orakel": ["target_id", "shown_role"],
	&"waldhexe": ["victim_id", "victim_role"],
	&"dorfchronistin": ["solo_count"],
	&"waldlaeufer": ["wolf_count"],
	&"die-gebundenen": ["bound_ids"],
	&"doktor": ["target_ids", "same_team"],
	&"faehrtenleser": ["direction"],
	&"spuerhund": ["target_ids", "hit", "lost"],
	&"traumdeuter": ["target_ids"],
	&"kopfgeldjaeger": ["target_ids"],
	&"koenig": ["target_id", "role_id"],
	&"kriegerin-des-lichts": ["target_id", "is_wolf"],
	&"blutpriester": ["revealed_ids"],
	&"die-ewigen": ["target_id", "solo"],
}


static func build(s: GameState, p: PendingPrompt) -> Dictionary:
	var answer := answer_type(p.owner, p.stage)
	var out := {
		"prompt_id": p.id,
		"owner": String(p.owner),
		"stage": String(p.stage),
		"step_id": p.step_id,
		"answer": answer,
		"actor_ids": actor_ids(s, p),
		"role_id": role_of(s, p),
		"min": p.min_count,
		"max": p.max_count,
		"allowed_ids": p.allowed_ids.duplicate(),
		"counts": RulesEngine.target_counts(s) if answer == "targets" else [],
		"cancellable": p.cancellable,
		"info": info_lines(s, p),
		"show": show_lines(s, p),
		"options": [],
		"reaction_kind": "",
	}
	if answer == "option":
		for role: Variant in DictRead.get_array(p.partial, "options"):
			out["options"].append(str(role))
	if p.owner == PendingPrompt.OWNER_REACTION and not s.reactions.is_empty():
		out["reaction_kind"] = String(s.reactions[0].kind)
	if p.owner == PendingPrompt.OWNER_ORACLE and p.stage == OracleStep.STAGE_SHOWN:
		out["can_override_shown"] = true
	if answer == "prediction":
		out["prediction_min"] = {"night": s.night_number + 1, "day": s.night_number}
	return out


static func answer_type(owner: StringName, stage: StringName) -> String:
	if stage == &"prediction":
		return "prediction"
	if OPTION_STAGES.has(stage):
		return "option"
	if CHOICE_STAGES.has(stage):
		return "choice"
	if ACK_STAGES.has(stage):
		return "ack"
	# „reveal“: bei der Waldhexe Kenntnisnahme der Opferrolle, beim Blutpriester Personenauswahl.
	if stage == &"reveal":
		return "ack" if owner == PendingPrompt.OWNER_WITCH else "targets"
	return "targets"


## Handelnde Personen: die Person des Prompts, bei Gruppenschritten alle Beteiligten.
static func actor_ids(s: GameState, p: PendingPrompt) -> Array:
	if p.actor_id != -1:
		return [p.actor_id]
	match p.owner:
		PendingPrompt.OWNER_PACK, PendingPrompt.OWNER_PACK2:
			return s.night_wolf_ids.filter(func(id: int) -> bool: return s.players[id].alive)
		PendingPrompt.OWNER_BOUND:
			return InfoSteps.living_bound(s)
		PendingPrompt.OWNER_ETERNAL:
			return InfoSteps.awake_eternal(s)
	return []


## Rolle, deren Fähigkeit der Prompt bedient (für Titel und Texte); Rudel und Gruppen eigene IDs.
static func role_of(s: GameState, p: PendingPrompt) -> String:
	match p.owner:
		PendingPrompt.OWNER_PACK, PendingPrompt.OWNER_PACK2:
			return String(CockpitView.GROUP_PACK)
		PendingPrompt.OWNER_REACTION:
			return String(s.players[p.actor_id].role_id) if s.players.has(p.actor_id) else ""
	return String(p.owner)


static func info_lines(s: GameState, p: PendingPrompt) -> Array:
	var out: Array = []
	# Traumdeuter und Kopfgeldjäger: Die Spielleitung wählt drei Personen mit mindestens einem Wolf
	# (I-01). Hinweis, wer unter den Wählbaren als Wolf zählt; die Prüfung bleibt im Regelkern.
	if InfoSteps.TRIPLE_OWNERS.has(p.owner) and p.stage == InfoSteps.STAGE_TARGETS:
		out.append(_line(s, "wolves_available_ids", p.allowed_ids.filter(func(id: int) -> bool: return s.players[id].counts_as_wolf)))
	var keys := p.partial.keys()
	keys.sort()
	for k: Variant in keys:
		var key := str(k)
		if HIDDEN_KEYS.has(key):
			continue
		var value: Variant = p.partial[k]
		out.append(_line(s, key, value))
	return out


## Positivliste für die gezeigte Karte; leer, wenn in dieser Stufe nichts zu zeigen ist.
static func show_lines(s: GameState, p: PendingPrompt) -> Array:
	var shown_stage := p.stage == &"shown" or (p.owner == PendingPrompt.OWNER_WITCH and p.stage == &"reveal")
	if not shown_stage or not SHOW_KEYS.has(p.owner):
		return []
	var out: Array = []
	for key: String in SHOW_KEYS[p.owner]:
		if p.partial.has(key):
			out.append(_line(s, key, p.partial[key]))
	return out


static func _line(s: GameState, key: String, value: Variant) -> Dictionary:
	if ROLE_KEYS.has(key):
		return {"key": key, "kind": "role", "value": str(value)}
	if key.ends_with("_ids"):
		var names: Array = []
		for id: Variant in (value as Array if value is Array else []):
			names.append(person_label(s, int(id)))
		return {"key": key, "kind": "persons", "value": names}
	if key.ends_with("_id"):
		return {"key": key, "kind": "person", "value": person_label(s, int(value)) if int(value) != GameState.NO_TARGET else ""}
	if value is bool:
		return {"key": key, "kind": "bool", "value": value}
	if key == "direction":
		return {"key": key, "kind": "direction", "value": str(value)}
	if value is int or value is float:
		return {"key": key, "kind": "number", "value": int(value)}
	return {"key": key, "kind": "text", "value": str(value)}


## „Platz 3 · Anna“ als Daten; die Oberfläche setzt den Text zusammen.
static func person_label(s: GameState, id: int) -> Dictionary:
	if not s.players.has(id):
		return {"person_id": id, "seat": 0, "name": ""}
	return {"person_id": id, "seat": s.seat_of(id) + 1, "name": s.players[id].name}
