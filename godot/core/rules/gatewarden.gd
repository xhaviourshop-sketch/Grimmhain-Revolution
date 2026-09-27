class_name Gatewarden
extends RefCounted
## Wächter am Tor (DECISION-LOG „Rollenaudit · … Wächter am Tor …“, RM-DR-149): Solange ein
## Wächter lebt, wird jede Person, die während der Partie zum Wolf würde (Wolfskind-Verwandlung,
## Lehrling-Erbe einer Wolfsrolle), stattdessen Dorfbewohner. Spielleiterkorrekturen sind
## ausgenommen. Die Person erfährt es privat (actor), der Spielleiter mit Einzelheiten.


static func active(s: GameState) -> bool:
	for id: int in s.alive_ids():
		if s.players[id].role_id == RoleCatalog.WAECHTER_AM_TOR:
			return true
	return false


## Macht `player_id` zum Dorfbewohner (frische Einsätze) statt zum Wolf und protokolliert es.
static func block(ctx: RuleContext, player_id: int, would_be: StringName, source: String) -> void:
	var s := ctx.state
	var from := s.players[player_id].role_id
	RoleTransition.change_role(s, player_id, RoleCatalog.DORFBEWOHNER, &"", true)
	s.win_check_pending = true
	ctx.emit(GameEvent.NEW_WOLF_BLOCKED, Visibility.GM, {"player_id": player_id, "from": from, "would_be": would_be, "source": source})
	ctx.emit(GameEvent.NEW_WOLF_BLOCKED_NOTICE, Visibility.ACTOR, {"role_id": String(RoleCatalog.DORFBEWOHNER)}, player_id)
