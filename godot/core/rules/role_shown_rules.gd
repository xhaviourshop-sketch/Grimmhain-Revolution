class_name RoleShownRules
extends RefCounted
## Rollenanzeige (Spezifikation vertical-slice-flow.md §2): Fortschritt der Personen, die ihre Rolle gesehen haben.
## `ConfirmRoleShown(person_id)` wird nur bei bewusstem Schließen der Rollenkarte gesendet, nie beim bloßen Öffnen
## oder Abbrechen. Gespeichert wird die Rolle zum Zeitpunkt der Bestätigung: Wechselt die Rolle später (Korrektur,
## Tausch, Verwandlung, Wiederbelebung), gilt die Person wieder als unbestätigt und kann erneut bestätigen.
## Reine Darstellung: keine Spielressource, kein Zufall, keine Pflicht vor `StartNight`.
## Ein wiederholtes Nachlesen einer bereits bestätigten Rolle braucht keinen Befehl.


static func validate(s: GameState, p: Dictionary) -> StringName:
	if not DictRead.is_int_like(p.get("person_id")) or not s.players.has(int(p["person_id"])):
		return &"unknown_player"
	if is_current(s, int(p["person_id"])):
		return &"role_already_confirmed"
	return &""


static func confirm(ctx: RuleContext, p: Dictionary) -> void:
	var id := int(p["person_id"])
	var role: StringName = ctx.state.players[id].role_id
	ctx.state.roles_shown[id] = role
	ctx.emit(GameEvent.ROLE_SHOWN_CONFIRMED, Visibility.GM, {"person_id": id, "role_id": String(role)}, id)


## Die Person hat ihre aktuelle Rolle bereits bestätigt gesehen.
static func is_current(s: GameState, person_id: int) -> bool:
	return s.roles_shown.has(person_id) and s.roles_shown[person_id] == s.players[person_id].role_id


## Personen ohne gültige Bestätigung in Sitzreihenfolge (die erste ist der Fortsetzungspunkt der Rollenanzeige).
static func pending_ids(s: GameState) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.seat_order:
		if s.players.has(id) and not is_current(s, id):
			out.append(id)
	return out


static func to_dict(shown: Dictionary) -> Dictionary:
	var out := {}
	for id: int in shown:
		out[str(id)] = String(shown[id])
	return out


## Null bei unbekannter Person oder leerer Rolle.
static func from_dict(s: GameState, d: Dictionary) -> Variant:
	var out := {}
	for key: Variant in d:
		var id := String(key).to_int()
		var role := String(d[key])
		if str(id) != String(key) or not s.players.has(id) or role == "":
			return null
		out[id] = StringName(role)
	return out
