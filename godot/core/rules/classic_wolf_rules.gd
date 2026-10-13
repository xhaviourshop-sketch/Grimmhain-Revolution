class_name ClassicWolfRules
extends RefCounted
## Akt Classic (DA-108): Regel des Urwolfs, die über die Mechanik des Werwolfs hinausgeht. Der Urwolf zählt als Werwolf (Rudel) und
## kann einmal im Spiel das Rudelopfer statt des Todes in einen Werwolf verwandeln. Eigene Classic-Regel, nicht der Rudelvater des
## Grundspiels. Der Schritt steht im Nachtplan direkt hinter dem Rudelschritt.
## Wörtliche Lesart (docs/classic/rueckfragen-C.md): Die Verwandlung ersetzt das Fressen; Schutz und Heiltrank bleiben unberührt,
## weil nichts mehr angegriffen wird.

const USE_KEY := "classic-urwolf:turn"  ## in `Player.ability_uses`: einmal im Spiel verbraucht
const AFTER_PACK := 2  ## Sortierschlüssel hinter dem Rudelschritt (und hinter PACK2)


static func is_urwolf(p: Player) -> bool:
	return p != null and p.role_id == RoleCatalog.CLASSIC_URWOLF


## true, wenn der Urwolf lebt und seine Fähigkeit noch hat.
static func ready(p: Player) -> bool:
	return is_urwolf(p) and p.alive and not p.ability_uses.has(USE_KEY)


## Lebende Urwölfe mit unverbrauchter Fähigkeit, nach Personen-ID.
static func ready_ids(s: GameState) -> Array[int]:
	var out: Array[int] = []
	for id: int in s.alive_ids():
		if ready(s.players[id]):
			out.append(id)
	return out


## Verwandelbar ist das Rudelopfer dieser Nacht, wenn es lebt und kein Wolf ist.
static func victim(s: GameState) -> int:
	var id := s.pack_target_id
	if id == GameState.NO_TARGET or not s.players.has(id) or not s.players[id].alive or s.players[id].counts_as_wolf:
		return GameState.NO_TARGET
	return id


## Grund, warum der Schritt entfällt, oder &"".
static func drop_reason(s: GameState, actor: int) -> StringName:
	if not is_urwolf(s.players[actor]):
		return &"actor_role_changed"
	if not ready(s.players[actor]) or victim(s) == GameState.NO_TARGET:
		return &"no_decision"
	return &""


## Verwandelt das Rudelopfer in einen Classic-Werwolf; es stirbt nicht. Liefert die Person-ID oder NO_TARGET.
static func turn(ctx: RuleContext, urwolf_id: int) -> int:
	var s := ctx.state
	var target := victim(s)
	s.players[urwolf_id].ability_uses[USE_KEY] = 1
	if target == GameState.NO_TARGET:
		return target
	RoleTransition.change_role(s, target, RoleCatalog.CLASSIC_WERWOLF, &"", true)
	s.pack_target_id = GameState.NO_TARGET
	s.win_check_pending = true
	ctx.emit(GameEvent.WOLF_TURNED, Visibility.GM, {"urwolf_id": urwolf_id, "target_id": target, "night": s.night_number})
	return target
