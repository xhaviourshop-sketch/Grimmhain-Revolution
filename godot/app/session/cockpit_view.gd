class_name CockpitView
extends RefCounted
## Liest den Spielstand für das Cockpit und liefert nur einfache Werte (Dictionary, Array, int,
## String). Keine Regel: Phase, nächster Schritt, Prompt und Kandidaten kommen unverändert aus dem
## Regelkern (StepQueue, PendingPrompt, WinCandidate). Die Sicht ist in zwei Teile getrennt:
##   build()          Sitzkreis und Ablauf ohne Rollen. Karten mit geheimem Inhalt tragen
##                    `secret = true`; die Oberfläche zeigt sie außerhalb der Nacht erst nach
##                    einer bewussten Aktion.
##   private_seats()  Rollen je Person, nur für den ausdrücklich geöffneten Spielleiterbereich.

const GROUP_PACK := &"pack"
const GROUP_BOUND := &"die-gebundenen"
const GROUP_ETERNAL := &"die-ewigen"

## Rollen, deren Regel noch an einem nicht entschiedenen System hängt (Totenkarten, RM-DR-013).
## Nur im privaten Bereich als Hinweis, weil die Nennung die Rolle verrät.
const OPEN_DEPENDENCIES := {
	&"dr-victor-frankenstein": "ui.cockpit.private.dependency.dead_cards",
}


## Öffentliche Cockpit-Sicht (ohne Rollen im Sitzkreis).
static func build(s: GameState) -> Dictionary:
	if not s.is_started():
		return {"has_game": false}
	return {
		"has_game": true,
		"phase": String(s.phase),
		"day_step": String(s.day_step),
		"night_number": s.night_number,
		"day_number": s.day_number,
		"seats": seats(s),
		"alive_count": s.alive_ids().size(),
		"player_count": s.players.size(),
		"night_progress": night_progress(s),
		"revival_round": s.revival_round,
		"next": next_action(s),
		"warnings": warnings(s),
	}


## Sitzkreis in Sitzreihenfolge: Personen-ID, Platz (ab 1), Name, lebend, heute nominiert.
## Nominierungen sind öffentlich (DR-03); eine Richter-Nominierung nennt keinen Nominierenden.
static func seats(s: GameState) -> Array:
	var nominated := {}
	var nominators := {}
	if s.phase == Phase.DAY:
		for n: Nomination in s.nominations_on_day(s.day_number):
			nominated[n.nominee_id] = true
			if not n.by_judge:
				nominators[n.nominator_id] = true
	var out: Array = []
	for i: int in s.seat_order.size():
		var id := s.seat_order[i]
		var p := s.players[id]
		out.append({
			"person_id": id,
			"seat": i + 1,
			"name": p.name,
			"alive": p.alive,
			"nominated_today": nominated.has(id),
			"nominated_someone_today": nominators.has(id),
		})
	return out


static func night_progress(s: GameState) -> Dictionary:
	if s.phase != Phase.NIGHT:
		return {"done": 0, "total": 0}
	return {"done": s.next_night_step, "total": s.night_plan.size()}


## Nächste erforderliche Handlung in derselben Rangfolge wie die Phasenmaschine:
## Spielende → offener Siegkandidat → offener Prompt → erwarteter Schritt → Phasenwechsel.
static func next_action(s: GameState) -> Dictionary:
	if s.phase == Phase.GAME_OVER:
		return {"kind": "game_over", "secret": false, "winner": _candidate(s, s.winner()) if s.winner() != null else {}}
	var open := s.open_candidates()
	if not open.is_empty():
		var list: Array = []
		for c: WinCandidate in open:
			list.append(_candidate(s, c))
		return {"kind": "win_decision", "secret": true, "candidates": list}
	if s.pending_prompt != null:
		var prompt := PromptView.build(s, s.pending_prompt)
		prompt["kind"] = "prompt"
		prompt["secret"] = true
		# Tarnaufrufe vor dem Schritt (DI-02); nur beim frischen Prompt, nicht in jeder Stufe.
		prompt["decoys"] = _decoys(s) if s.pending_prompt.partial.is_empty() else []
		return prompt
	if not s.notices.is_empty():
		return notice_card(s)
	var step_id := RulesEngine.next_step_id(s)
	if step_id != "":
		return step_announcement(s, step_id)
	match s.phase:
		Phase.SETUP:
			return {"kind": "start_night", "secret": false, "first": true, "revival_round": s.revival_round}
		Phase.NIGHT:
			return {"kind": "end_night", "secret": false, "skipped": _skipped_count(s), "decoys": _decoys(s)}
		Phase.DAY:
			if s.day_step == Phase.DAY_ENDED:
				return {"kind": "start_night", "secret": false, "first": false, "revival_round": s.revival_round}
			if s.day_step == Phase.DAY_EXECUTION_DECIDED:
				return {"kind": "end_day", "secret": false, "nominations": nominations_today(s)}
			return {"kind": "day", "secret": false, "day_step": String(s.day_step), "nominations": nominations_today(s),
				"execution_candidates": _execution_candidates(s)}
	return {"kind": "none", "secret": false}


## Ankündigung des erwarteten, noch nicht begonnenen Schritts (Nachtschritt oder Reaktion).
static func step_announcement(s: GameState, step_id: String) -> Dictionary:
	var out := {"kind": "begin_step", "secret": true, "step_id": step_id, "skippable": StepQueue.is_skippable(step_id), "decoys": _decoys(s)}
	if StepQueue.is_reaction_step(step_id):
		var r := s.reactions[0]
		out["step_kind"] = "reaction"
		out["reaction_kind"] = String(r.kind)
		out["role_id"] = String(s.players[r.owner_id].role_id)
		out["actor_ids"] = [r.owner_id]
		out["reactions_open"] = s.reactions.size()
		return out
	var key := s.night_plan[s.next_night_step]
	out["step_kind"] = String(StepQueue.step_kind(step_id))
	out["index"] = s.next_night_step + 1
	out["total"] = s.night_plan.size()
	out["repeat"] = s.apple_steps.has(s.next_night_step)
	match key:
		StepQueue.PACK, StepQueue.PACK2:
			out["role_id"] = String(GROUP_PACK)
			out["actor_ids"] = s.night_wolf_ids.filter(func(id: int) -> bool: return s.players[id].alive)
		StepQueue.BOUND:
			out["role_id"] = String(GROUP_BOUND)
			out["actor_ids"] = InfoSteps.living_bound(s)
		StepQueue.ETERNAL:
			out["role_id"] = String(GROUP_ETERNAL)
			out["actor_ids"] = InfoSteps.living_eternal(s)
		_:
			var actor := StepQueue.step_actor(key)
			out["role_id"] = String(StepQueue.step_role(key))
			out["actor_ids"] = [actor]
			# Grabräuber: gestohlene Fähigkeit einer anderen Rolle (nur privat sichtbar).
			out["own_role_id"] = String(s.players[actor].role_id)
	return out


## Tarnaufrufe (DI-02) als Rollen-IDs: Rollen, die vor dem nächsten echten Schritt angesagt werden, ohne dass sie
## etwas ausführen. Die Auswahl trifft allein `CallPolicy` im Regelkern.
static func _decoys(s: GameState) -> Array:
	var out: Array = []
	for role: StringName in CallPolicy.decoy_calls(s):
		out.append(String(role))
	return out


## Erster offener privater Hinweis (DI-04, DI-06, DI-07) als Karte für die betroffenen Personen. Der Kartentext
## enthält nur, was die Betrachter erfahren dürfen: den eigenen Partner (Loki), die Liste aller Verzauberten
## (sie erkennen einander) bzw. den eigenen Zustand; nie Rollen anderer Personen.
static func notice_card(s: GameState) -> Dictionary:
	var n: Dictionary = s.notices[0]
	var viewers: Array = n["viewer_ids"]
	var viewer_labels: Array = []
	for id: Variant in viewers:
		viewer_labels.append(PromptView.person_label(s, int(id)))
	var text_key := ""
	var values := {}
	match str(n["kind"]):
		NoticeRules.LOKI_BOND:
			text_key = "ui.notice.loki_bond.%s" % str((n["data"] as Dictionary)["bond"])
			values = {"partner": PromptView.person_label(s, int((n["data"] as Dictionary)["partner_id"]))}
		NoticeRules.PIPER_NEW:
			text_key = "ui.notice.piper_new"
		NoticeRules.PIPER_ALL:
			text_key = "ui.notice.piper_all"
			values = {"names": viewer_labels}
		NoticeRules.PEST_INFECTED:
			text_key = "ui.notice.pest_infected"
	return {"kind": "notice", "secret": true, "notice_id": int(n["id"]), "notice_kind": str(n["kind"]), "open": s.notices.size(),
		"viewers": viewer_labels, "group": viewers.size() > 1, "text_key": text_key, "values": values}


## Heute nominierte, lebende Personen: reguläre Hinrichtungsziele (DR-03).
static func _execution_candidates(s: GameState) -> Array:
	var out: Array = []
	for n: Nomination in s.nominations_on_day(s.day_number):
		if s.players[n.nominee_id].alive and not out.has(n.nominee_id):
			out.append(n.nominee_id)
	return out


static func nominations_today(s: GameState) -> Array:
	var out: Array = []
	for n: Nomination in s.nominations_on_day(s.day_number):
		out.append({"nominator_id": -1 if n.by_judge else n.nominator_id, "nominee_id": n.nominee_id})
	return out


## Hinweise ohne Geheimnis: offene Reaktionen (Anzahl), übersprungene Nachtschritte, Tote ohne Rolle.
static func warnings(s: GameState) -> Array:
	var out: Array = []
	if StepQueue.reactions_due(s):
		out.append({"key": "ui.cockpit.warning.reactions_open", "values": {"count": s.reactions.size()}})
	if s.phase == Phase.NIGHT and s.next_night_step >= s.night_plan.size() and _skipped_count(s) > 0:
		out.append({"key": "ui.cockpit.warning.steps_skipped", "values": {"count": _skipped_count(s)}})
	if s.alive_ids().is_empty():
		out.append({"key": "ui.cockpit.warning.nobody_alive", "values": {}})
	return out


## Privater Spielleiterbereich: Rolle, Fraktion und Zusatzhinweise je Person (Sitzreihenfolge).
static func private_seats(s: GameState) -> Array:
	var out: Array = []
	for i: int in s.seat_order.size():
		var p := s.players[s.seat_order[i]]
		var notes: Array = []
		if p.role_id != p.original_role_id:
			notes.append({"key": "ui.cockpit.private.original_role", "role_id": String(p.original_role_id)})
		if p.appears_as != p.role_id and RoleCatalog.requires_appearance(p.role_id):
			notes.append({"key": "ui.cockpit.private.appears_as", "role_id": String(p.appears_as)})
		if OPEN_DEPENDENCIES.has(p.role_id):
			notes.append({"key": OPEN_DEPENDENCIES[p.role_id], "role_id": ""})
		out.append({
			"person_id": p.id,
			"seat": i + 1,
			"name": p.name,
			"alive": p.alive,
			"role_id": String(p.role_id),
			"faction": String(p.faction),
			"counts_as_wolf": p.counts_as_wolf,
			"notes": notes,
		})
	return out


## Vorschau der Hinrichtung von `target_id` aus ExecutionRules (Spiegelung) und die Pflichtfelder
## des Befehls (Cerberus-Abwehr, Fluchdauer des Weisen). Geheim: nennt die tatsächlich sterbende Person.
static func execution_preview(s: GameState, target_id: int) -> Dictionary:
	if not s.players.has(target_id):
		return {}
	var r := ExecutionRules.preview(s, target_id, KillEvent.SOURCE_VILLAGE)
	var dying := int(r["death_target_id"])
	return {
		"target_id": target_id,
		"death_target_id": dying,
		"redirected": bool(r["redirected"]),
		"needs_cerberus": ExecutionRules.needs_cerberus_decision(s, target_id),
		"needs_sage": GuardRoles.needs_sage_decision(s, target_id),
		"sage_max": RoleCatalog.SAGE_MAX_CURSE,
		"secret": bool(r["redirected"]) or ExecutionRules.needs_cerberus_decision(s, target_id) or GuardRoles.needs_sage_decision(s, target_id),
	}


## Tagesaktionen, die an einer Rolle hängen und deshalb nur im privaten Bereich erscheinen:
## Amalia (Selbstopfer mit Ja/Nein-Antwort) und Nekromant (Wolf benennen). Ob sie gelten,
## entscheidet der Regelkern beim Senden.
static func secret_day_actions(s: GameState) -> Array:
	var out: Array = []
	if s.phase != Phase.DAY or s.day_step == Phase.DAY_ENDED or s.pending_prompt != null:
		return out
	for id: int in s.seat_order:
		var p := s.players[id]
		if not p.alive:
			continue
		if p.role_id == RoleCatalog.AMALIA:
			out.append({"action": "amalia", "player_id": id, "name": p.name, "seat": s.seat_of(id) + 1})
		elif p.role_id == RoleCatalog.NEKROMANT and int(s.necro_named.get(id, 0)) != s.day_number:
			out.append({"action": "name_wolf", "player_id": id, "name": p.name, "seat": s.seat_of(id) + 1})
	return out


## Lesbare Beschreibung eines Befehls im Zustand `before` (vor dem Befehl): Art, betroffene Personen
## und bei Antworten die Rolle und Stufe des Prompts. Nur für den Spielleiterbereich.
static func command_info(before: GameState, c: Command) -> Dictionary:
	var p := c.payload
	var info := {"type": String(c.type), "role_id": "", "stage": "", "persons": [], "kind": ""}
	var person := func(key: String) -> void:
		if p.has(key) and DictRead.is_int_like(p[key]) and before.players.has(int(p[key])):
			(info["persons"] as Array).append(PromptView.person_label(before, int(p[key])))
	match c.type:
		Command.ANSWER_PROMPT, Command.CANCEL_PROMPT, Command.OVERRIDE_SHOWN_ROLE:
			if before.pending_prompt != null:
				info["role_id"] = PromptView.role_of(before, before.pending_prompt)
				info["stage"] = String(before.pending_prompt.stage)
		Command.BEGIN_STEP, Command.SKIP_STEP:
			var step := DictRead.get_string(p, "step_id")
			info["role_id"] = MorningReport._step_role(step)
		Command.NOMINATE:
			person.call("nominator_id")
			person.call("nominee_id")
		Command.DECIDE_EXECUTION, Command.GM_CORRECTION:
			person.call("target_id")
			info["kind"] = DictRead.get_string(p, "kind")
		Command.AMALIA_SACRIFICE, Command.NAME_WOLF:
			person.call("player_id")
		Command.CONFIRM_ROLE_SHOWN:
			person.call("person_id")
	return info


## Einfach korrigierbare Werte einer Person für „Status ändern“ (GmCorrections): je Eintrag die
## Korrekturart, die Felder des Befehls ohne Wert, der aktuelle Wert und die Art des neuen Werts
## (bool = umschalten, role = Rollenwahl). Nur für den privaten Korrekturablauf (verrät die Rolle).
static func status_fields(s: GameState, id: int) -> Array:
	if not s.players.has(id):
		return []
	var p := s.players[id]
	var out: Array = []
	out.append({"field": "ever_nominated", "kind": "set_ever_nominated", "fields": {"target_id": id}, "value_key": "value",
		"current": p.ever_nominated, "type": "bool"})
	if p.role_id == RoleCatalog.WALDHEXE:
		for potion: String in WitchStep.POTIONS:
			out.append({"field": "potion_%s" % potion, "kind": "set_witch_potion", "fields": {"witch_id": id, "potion": potion},
				"value_key": "available", "current": WitchStep.potion_available(p, potion), "type": "bool"})
	if p.role_id == RoleCatalog.SPIEGELWOLF:
		out.append({"field": "mirror", "kind": "set_mirror", "fields": {"target_id": id}, "value_key": "available",
			"current": ExecutionRules.mirror_available(p), "type": "bool"})
	if RoleCatalog.requires_appearance(p.role_id):
		out.append({"field": "appears_as", "kind": "set_role_field", "fields": {"target_id": id, "field": "appears_as"}, "value_key": "value",
			"current": String(p.appears_as), "type": "role"})
	out.append_array(special_fields(s, id))
	return out


## Spezialkorrekturen der Person (Schutz, Rettung, Wolfskind, Lehrling). Angeboten wird nur, was der Regelkern jetzt annimmt:
## Jede Korrektur wird mit `RulesEngine.check` vorgeprüft (keine zweite Regel in der Oberfläche). Eintrag: `type` "action"
## (sofort, mit Rückfrage) oder "pick" (zuerst ein Ziel aus `pick_ids` wählen, `pick_key` ist das Payload-Feld) und `state`
## (bisheriger Wert der Person als {key, values}, nur für die Anzeige).
const SPECIAL_KINDS: Array = [
	[GmCorrections.SET_PROTECTION, "guardian_id", true, "protection"],
	[GmCorrections.REMOVE_PROTECTION, "guardian_id", false, "protection"],
	[GmCorrections.SET_RESCUE, "witch_id", false, "rescue"],
	[GmCorrections.REMOVE_RESCUE, "witch_id", false, "rescue"],
	[GmCorrections.SET_WOLF_MODEL, "child_id", true, "wolf_child"],
	[GmCorrections.REMOVE_WOLF_MODEL, "child_id", false, "wolf_child"],
	[GmCorrections.TRANSFORM_WOLF_CHILD, "child_id", false, "wolf_child"],
	[GmCorrections.REVERT_WOLF_CHILD, "child_id", false, "wolf_child"],
	[GmCorrections.SET_APPRENTICE_MASTER, "apprentice_id", true, "apprentice"],
	[GmCorrections.REMOVE_APPRENTICE_MASTER, "apprentice_id", false, "apprentice"],
	[GmCorrections.TRIGGER_APPRENTICE_INHERITANCE, "apprentice_id", false, "apprentice"],
	[GmCorrections.REVERT_APPRENTICE_INHERITANCE, "apprentice_id", false, "apprentice"],
]


static func special_fields(s: GameState, id: int) -> Array:
	var out: Array = []
	if not s.players.has(id):
		return out
	for spec: Array in SPECIAL_KINDS:
		var kind: String = spec[0]
		var fields := {str(spec[1]): id}
		if kind == GmCorrections.SET_RESCUE:
			fields["target_id"] = s.pack_target_id  # gerettet werden kann nur das aktuelle Rudelopfer
		var entry := {"field": kind, "kind": kind, "fields": fields, "state": _special_state(s, id, str(spec[3])), "type": "action"}
		if bool(spec[2]):
			var ids: Array = []
			for target: int in s.alive_ids():
				var probe := fields.duplicate()
				probe["target_id"] = target
				if _accepted(s, kind, probe):
					ids.append(target)
			if ids.is_empty():
				continue
			entry["type"] = "pick"
			entry["pick_key"] = "target_id"
			entry["pick_ids"] = ids
		elif not _accepted(s, kind, fields):
			continue
		out.append(entry)
	return out


static func _accepted(s: GameState, kind: String, fields: Dictionary) -> bool:
	var payload := fields.duplicate()
	payload["kind"] = kind
	payload["reason"] = "Vorprüfung"
	payload["confirmed"] = true
	return RulesEngine.check(s, Command.gm_correction(payload)) == &""


## Bisheriger Wert der Person zur Familie der Korrektur: {key, values}; Werte sind Personenlabels, Schlüssel oder Wahrheitswerte.
static func _special_state(s: GameState, id: int, family: String) -> Dictionary:
	var nobody := StringName("ui.gm.state.nobody")
	match family:
		"protection":
			var current := Protections.of_guardian(s, id)
			if current == null:
				return {"key": "ui.gm.state.protection_none", "values": {}}
			return {"key": "ui.gm.state.protection_set", "values": {"target": PromptView.person_label(s, current.target_id)}}
		"rescue":
			var action := WitchStep.action_of(s, id)
			if action == null or action.saved_id == GameState.NO_TARGET:
				return {"key": "ui.gm.state.rescue_none", "values": {}}
			return {"key": "ui.gm.state.rescue_set", "values": {"target": PromptView.person_label(s, action.saved_id)}}
		"wolf_child":
			var bond := WolfChildRules.bond_of(s, id)
			if bond == null:
				return {"key": "ui.gm.state.wolf_child", "values": {"model": nobody, "transformed": false}}
			return {"key": "ui.gm.state.wolf_child", "values": {"model": PromptView.person_label(s, bond.model_id) if bond.model_id != GameState.NO_TARGET else nobody,
				"transformed": bond.transformed}}
		"apprentice":
			var active := ApprenticeRules.active_of(s, id)
			var latest := ApprenticeRules.latest_of(s, id)
			return {"key": "ui.gm.state.apprentice", "values": {"master": PromptView.person_label(s, active.master_id) if active != null else nobody,
				"inherited": latest != null and latest.status == ApprenticeBond.STATUS_INHERITED}}
	return {}


## Stimmhinweise (RM-DR-008) für den privaten Bereich: Stimmen zählt die Spielleitung physisch, der Regelkern nennt nur Boni
## (Blutwolf, Korrupter Richter). Verrät Rollen und darf nie auf eine öffentliche Karte.
static func vote_hints(s: GameState) -> Array:
	var out: Array = []
	for h: Dictionary in VoteHints.hints(s):
		var entry := PromptView.person_label(s, int(h["player_id"]))
		entry["bonus"] = int(h["bonus"])
		entry["source_role"] = str(h["source_role"])
		out.append(entry)
	return out


## Rollenanzeige, neutrale Liste: Personen in Sitzreihenfolge mit Bestätigungsstand, ohne jede Rolle. `next_id` ist die
## erste Person ohne gültige Bestätigung (Fortsetzungspunkt), -1 wenn alle bestätigt sind.
static func role_show_list(s: GameState) -> Dictionary:
	var persons: Array = []
	var confirmed := 0
	for i: int in s.seat_order.size():
		var id := s.seat_order[i]
		var done := RoleShownRules.is_current(s, id)
		confirmed += 1 if done else 0
		persons.append({"person_id": id, "seat": i + 1, "name": s.players[id].name, "confirmed": done})
	var pending := RoleShownRules.pending_ids(s)
	return {"persons": persons, "next_id": pending[0] if not pending.is_empty() else -1, "confirmed_count": confirmed, "total": persons.size()}


## Rollenanzeige, Karte einer Person: ausschließlich diese Person mit ihrer wahren Rolle (bei Rollen mit Scheinrolle nie
## die Scheinrolle, DI-08) und dem Bestätigungsstand. Leer bei unbekannter Person. Wird erst nach der bewussten Aktion gebaut.
static func role_show_card(s: GameState, person_id: int) -> Dictionary:
	if not s.players.has(person_id):
		return {}
	var p := s.players[person_id]
	return {"person_id": person_id, "seat": s.seat_of(person_id) + 1, "name": p.name, "role_id": String(p.role_id),
		"confirmed": RoleShownRules.is_current(s, person_id)}


static func _skipped_count(s: GameState) -> int:
	var n := 0
	for status: StringName in s.night_step_status:
		if status == StepQueue.STATUS_SKIPPED:
			n += 1
	return n


static func _candidate(s: GameState, c: WinCandidate) -> Dictionary:
	var names := func(ids: Array[int]) -> Array:
		var out: Array = []
		for id: int in ids:
			out.append(s.players[id].name if s.players.has(id) else str(id))
		return out
	return {
		"id": c.id,
		"kind": String(c.kind),
		"reason_key": String(c.reason_key),
		"reason_args": c.reason_args.duplicate(true),
		"beneficiaries": names.call(c.beneficiary_ids),
		"co_winners": names.call(c.co_winner_ids),
		"status": String(c.status),
	}
