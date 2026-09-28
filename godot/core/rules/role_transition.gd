class_name RoleTransition
extends RefCounted
## Zentraler Rollenwechsel einer Person (Spielleiterkorrektur `set_role`, Erbe des Lehrlings).
## Setzt `role_id`, `faction`, `counts_as_wolf` und `appears_as` gemeinsam und hält den
## rollengebundenen Zustand konsistent:
##   Wolfskind: Datensatz beim Wechsel weg entfernt, beim Wechsel hin neu und unverwandelt
##   Lehrling:  aktive Bindung beim Wechsel weg als `removed` beendet
##   `ability_uses`: mit `fresh_uses` beginnen alle Einsätze der neuen Rolle unverbraucht
## `original_role_id` und `ever_nominated` bleiben unverändert.


## `appearance` ist nur bei Rollen mit Pflicht-Scheinrolle maßgeblich (Trugbilderwolf).
static func change_role(s: GameState, player_id: int, role: StringName, appearance: StringName = &"", fresh_uses: bool = false) -> void:
	var p := s.players[player_id]
	var previous := p.role_id
	p.role_id = role
	p.faction = RoleCatalog.faction_of(role)
	p.counts_as_wolf = RoleCatalog.counts_as_wolf(role)
	p.appears_as = appearance if RoleCatalog.requires_appearance(role) else RoleCatalog.appears_as(role)
	if fresh_uses:
		for key: String in p.ability_uses.keys():
			if key.begins_with("%s:" % role):
				p.ability_uses.erase(key)
	s.growth.erase(player_id)  # Fenrir-Stufe und Cerberus-Köpfe hängen an der Rolle
	s.bounty_credits.erase(player_id)  # offene Listen gehören dem bisherigen Kopfgeldjäger
	p.cursed = false  # neue Rolle, neue Erscheinung (V-07)
	WolfChildRules.remove_bond(s, player_id)
	if role == RoleCatalog.WOLFSKIND:
		WolfChildRules.create_bond(s, player_id)
	if previous == RoleCatalog.LEHRLING and role != RoleCatalog.LEHRLING:
		ApprenticeRules.end_active(s, player_id, ApprenticeBond.STATUS_REMOVED)
	if role != RoleCatalog.FEUERTEUFEL:
		SoloRules.drop_fire_mark(s, player_id)  # Markierung erlischt mit der Rolle (RM-DR-131.7)


## Wiederbelebung (Decision Log „Rollenaudit · Wiederbelebung …“): lebt wieder, Todesdatensatz weg, alle
## begrenzten Einsätze frisch; Nominierungsstatus, Bindungen und eingereihte Reaktionen bleiben.
static func revive(s: GameState, player_id: int) -> void:
	var p := s.players[player_id]
	p.alive = true
	p.death = null
	p.ability_uses.clear()
	s.growth.erase(player_id)  # Fenrir-Stufe und Cerberus-Köpfe beginnen neu
	s.win_check_pending = true


## Stellt einen gespeicherten Rollenzustand exakt wieder her (Rücknahme eines Erbes).
static func restore(s: GameState, player_id: int, snapshot: Dictionary) -> void:
	var p := s.players[player_id]
	p.role_id = StringName(DictRead.get_string(snapshot, "role_id"))
	p.faction = StringName(DictRead.get_string(snapshot, "faction"))
	p.counts_as_wolf = DictRead.get_bool(snapshot, "counts_as_wolf")
	p.appears_as = StringName(DictRead.get_string(snapshot, "appears_as"))
	p.ability_uses = DictRead.get_dict(snapshot, "ability_uses").duplicate()
	WolfChildRules.remove_bond(s, player_id)
	if p.role_id != RoleCatalog.FEUERTEUFEL:
		SoloRules.drop_fire_mark(s, player_id)


static func snapshot_of(p: Player) -> Dictionary:
	return {
		"role_id": String(p.role_id),
		"faction": String(p.faction),
		"counts_as_wolf": p.counts_as_wolf,
		"appears_as": String(p.appears_as),
		"ability_uses": p.ability_uses.duplicate(),
	}
