class_name NightBoardView
extends RefCounted
## Geheime Brettdaten für die Spielleitung (P3, DECISIONS.md „Abnahme 1“, Punkt 5): Zustandsabzeichen je Person und die
## Nachtreihenfolge-Leiste. Beides verrät Rollen und Wirkungen und gehört deshalb NICHT in die öffentliche Cockpit-Sicht
## (`CockpitView.build`), sondern in eigene Abfragen der Anwendungsschicht. Die Oberfläche zeigt sie nur, solange „Verbergen“
## aus ist. Reines Lesen des Kernzustands: keine Regel, kein Zufall, keine Zustandsänderung.

## Abzeichenarten in fester Reihenfolge. Die Zuordnung der Kernzustände ist eine Darstellungsentscheidung (nicht Regel):
##   protected  Schutz dieser Nacht (Schutzengel), Schild (Schutzgeist), Barriere (Hades), Schild des Nekromanten
##   poisoned   Giftwolf-Vergiftung, Gifttrank der Waldhexe dieser Nacht
##   marked     Opfer des Rudels, Markierung durch Richter, Henker, Feuerteufel, Prophet, Tod am Morgen
##   silenced   in dieser Nacht blockiert (Albtraumwolf)
##   special    verzaubert (Rattenfänger), infiziert, Parasitenwirt, Voodoo-Puppe, Loki-Paar
const KINDS: Array[StringName] = [&"protected", &"poisoned", &"marked", &"silenced", &"special"]


## Abzeichen je lebender Person: Personen-ID → Liste der Arten (in KINDS-Reihenfolge). Personen ohne Abzeichen fehlen.
static func marks(s: GameState) -> Dictionary:
	if not s.is_started():
		return {}
	var by_kind := {}
	for kind: StringName in KINDS:
		by_kind[kind] = {}
	for p: Protection in s.protections:
		_add(by_kind, &"protected", p.target_id)
	for sh: Variant in s.shields:
		_add(by_kind, &"protected", int((sh as Dictionary).get("holder_id", -1)))
	for id: int in s.hades_barriers:
		_add(by_kind, &"protected", id)
	for ns: Variant in s.necro_shields:
		_add(by_kind, &"protected", int((ns as Dictionary).get("necro_id", -1)))
	for w: Variant in s.wolf_poisons:
		_add(by_kind, &"poisoned", int((w as Dictionary).get("target_id", -1)))
	for wa: WitchAction in s.witch_actions:
		if wa.poison_used and wa.night == s.night_number:
			_add(by_kind, &"poisoned", wa.poison_target_id)
	_add(by_kind, &"marked", s.pack_target_id)
	_add(by_kind, &"marked", s.pack_extra_target_id)
	for list: Array in [s.judge_marks, s.hangman_marks, s.fire_marks, s.prophet_marks, s.death_marks]:
		for m: Variant in list:
			_add(by_kind, &"marked", int((m as Dictionary).get("target_id", -1)))
	for id: int in s.blocked_ids:
		_add(by_kind, &"silenced", id)
	for c: Variant in s.charms:
		_add(by_kind, &"special", int((c as Dictionary).get("target_id", -1)))
	for id: int in s.infected:
		_add(by_kind, &"special", id)
	for h: Variant in s.parasite_hosts:
		_add(by_kind, &"special", int((h as Dictionary).get("host_id", -1)))
	for d: Variant in s.voodoo_dolls:
		_add(by_kind, &"special", int((d as Dictionary).get("doll_id", -1)))
	for pair: Variant in s.loki_pairs:
		var entry: Dictionary = pair
		if not bool(entry.get("ended", false)):
			_add(by_kind, &"special", int(entry.get("a", -1)))
			_add(by_kind, &"special", int(entry.get("b", -1)))
	var out := {}
	for id: int in s.seat_order:
		if not s.players[id].alive:
			continue
		var kinds: Array = []
		for kind: StringName in KINDS:
			if (by_kind[kind] as Dictionary).has(id):
				kinds.append(String(kind))
		if not kinds.is_empty():
			out[id] = kinds
	return out


static func _add(by_kind: Dictionary, kind: StringName, person_id: int) -> void:
	if person_id > 0:
		(by_kind[kind] as Dictionary)[person_id] = true


## Nachtreihenfolge der laufenden Nacht für die Leiste: Rollen in Aufrufreihenfolge mit Zustand "done", "active" oder "upcoming".
## Echte Schritte und Tarnaufrufe stehen gleich in der Leiste (die Spielleitung liest sie so vor); das Rudel erscheint als
## Werwolf, mehrere Schritte derselben Rolle als ein Eintrag. Leer außerhalb der Nacht.
static func night_order(s: GameState) -> Array:
	if s.phase != Phase.NIGHT:
		return []
	var entries := {}  # role_id → {"role_id", "slot", "state"}
	for j: int in s.night_plan.size():
		var key := s.night_plan[j]
		var role := CallPolicy.entry_role(key)
		var role_id := String(role) if role != &"" else String(RoleCatalog.WERWOLF)
		var state := "upcoming"
		if s.night_step_status[j] != StepQueue.STATUS_PENDING:
			state = "done"
		elif j == s.next_night_step:
			state = "active"
		_merge(entries, role_id, CallPolicy.entry_slot(key), state)
	var current_slot := CallPolicy.entry_slot(s.night_plan[s.next_night_step]) if s.next_night_step < s.night_plan.size() else CallPolicy.NO_LIMIT
	for role: StringName in CallPolicy.called_roles(s):
		if entries.has(String(role)):
			continue
		var slot := CallPolicy.slot_priority(role)
		_merge(entries, String(role), slot, "done" if slot < current_slot else "upcoming")
	var out: Array = entries.values()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["slot"]) < int(b["slot"]) or (int(a["slot"]) == int(b["slot"]) and str(a["role_id"]) < str(b["role_id"])))
	return out


## Zustand je Rolle: aktiv vor offen vor erledigt (ein offener Schritt derselben Rolle hält den Eintrag offen).
static func _merge(entries: Dictionary, role_id: String, slot: int, state: String) -> void:
	if not entries.has(role_id):
		entries[role_id] = {"role_id": role_id, "slot": slot, "state": state}
		return
	var order := ["done", "upcoming", "active"]
	var entry: Dictionary = entries[role_id]
	if order.find(state) > order.find(str(entry["state"])):
		entry["state"] = state
	entry["slot"] = mini(int(entry["slot"]), slot)
