class_name GuardRoles
extends RefCounted
## Schutzrollen (DECISION-LOG „Rollenaudit · Schutzrollen“, 28.09.2026):
##   Der Weise: Fluch nach seinem Lynch (S-01, S-05, S-09): 0–3 folgende Nächte und Tage ruhen alle
##     Fähigkeiten aller Dorfpersonen; ausgelöste Wirkungen entfallen endgültig. `silenced` ist die
##     einzige Abfrage dafür.
##   Schutzgeist: Schritt in der ersten Nacht nach ihrem Tod (Ausnahme zu G-PH-2).
##   Märtyrerin: Frage nur, wenn das erste Rudelopfer tatsächlich stürbe.
##   Verdammniswächter: Angebot aus lebenden Nicht-Wölfen außer Rudelopfer und ihm selbst.

const SAGE_USE_KEY := "der-weise:survive"
const GHOST_USE_KEY := "schutzgeist:shield"
const SMITH_USE_KEY := "dorfschmied:weapon"
## Rückgabewert von `KillPipeline.pack_protection` für Schutzengel, Waldhexenrettung und Dorfwache.
const REPEATABLE := &"repeatable"


## Nacht- bzw. Tagesnummer der laufenden Phase (Setup: 0).
static func _phase_number(s: GameState) -> int:
	if s.phase == Phase.NIGHT or s.phase == Phase.DAWN_RESOLUTION:
		return s.night_number
	return s.day_number if s.phase == Phase.DAY else 0


static func curse_active(s: GameState) -> bool:
	var n := _phase_number(s)
	return s.sage_curse_to > 0 and n >= s.sage_curse_from and n <= s.sage_curse_to


## true, wenn die Fähigkeiten dieser Person gerade durch den Fluch des Weisen ruhen (Fraktion Dorf).
static func silenced(s: GameState, id: int) -> bool:
	return s.players.has(id) and s.players[id].faction == Faction.VILLAGE and curse_active(s)


## Hinrichtung verlangt die Fluchdauer: der Tod träfe durch Lynch einen Weisen, dessen Fähigkeit nicht ruht.
static func needs_sage_decision(s: GameState, target_id: int) -> bool:
	if not s.players.has(target_id) or not s.players[target_id].alive:
		return false
	var r := ExecutionRules.preview(s, target_id, KillEvent.SOURCE_VILLAGE)
	var dying: Player = s.players.get(int(r["death_target_id"]))
	return String(r["cause"]) == String(KillEvent.CAUSE_LYNCH) and dying != null and dying.role_id == RoleCatalog.DER_WEISE and not silenced(s, dying.id)


## Fehlergrund für das Feld `sage_curse` einer Hinrichtung oder &"".
static func validate_curse_field(s: GameState, target_id: int, p: Dictionary) -> StringName:
	if not needs_sage_decision(s, target_id):
		return &""
	if not p.has("sage_curse"):
		return &"sage_curse_required"
	if not DictRead.is_int_like(p["sage_curse"]) or int(p["sage_curse"]) < 0 or int(p["sage_curse"]) > RoleCatalog.SAGE_MAX_CURSE:
		return &"invalid_sage_curse"
	return &""


## Fluch nach dem Lynch-Tod eines Weisen am Tag d: Nächte und Tage d+1 bis d+n (verlängert einen laufenden).
static func start_curse(ctx: RuleContext, sage_id: int, length: int) -> void:
	var s := ctx.state
	if length <= 0:
		return
	var first := s.day_number + 1
	if not (s.sage_curse_to > 0 and s.sage_curse_to >= s.day_number):
		s.sage_curse_from = first
	s.sage_curse_to = maxi(s.sage_curse_to, s.day_number + length)
	ctx.emit(GameEvent.SAGE_CURSED, Visibility.GM, {"sage_id": sage_id, "length": length, "from": s.sage_curse_from, "to": s.sage_curse_to})


## Schutzgeist: Nacht, in der die tote Person handelt (die erste nach ihrem Tod).
static func ghost_night(p: Player) -> int:
	return p.death.phase_number + 1 if p.death != null else -1


static func ghost_can_act(s: GameState, p: Player) -> bool:
	return not p.alive and p.role_id == RoleCatalog.SCHUTZGEIST and not p.ability_uses.has(GHOST_USE_KEY) and ghost_night(p) == s.night_number


static func smith_can_give(s: GameState, p: Player) -> bool:
	return p.alive and SoloRules.ability_role(s, p.id) == RoleCatalog.DORFSCHMIED and not p.ability_uses.has(SMITH_USE_KEY) and s.night_number >= RoleCatalog.SMITH_FIRST_NIGHT


## Erstes Rudelopfer dieser Nacht, wenn es lebt, sonst −1.
static func pack_victim(s: GameState) -> int:
	var v := s.pack_target_id
	return v if v != GameState.NO_TARGET and s.players.has(v) and s.players[v].alive else GameState.NO_TARGET


## Verdammniswächter: mögliche Angebote (lebend, kein Wolf, weder Rudelopfer noch er selbst), aufsteigend.
static func doom_pool(s: GameState, warden_id: int) -> Array[int]:
	var victim := pack_victim(s)
	return s.alive_ids().filter(func(id: int) -> bool: return id != victim and id != warden_id and not s.players[id].counts_as_wolf)


## Gültiges gespeichertes Angebot oder eine neue Ziehung über den gespeicherten Seed (einmal je Nacht).
static func doom_offer(s: GameState, warden_id: int) -> int:
	var pool := doom_pool(s, warden_id)
	if pool.is_empty():
		return GameState.NO_TARGET
	var stored := int(s.doom_offers.get(warden_id, GameState.NO_TARGET))
	if pool.has(stored):
		return stored
	var offer := pool[s.rng.next_int(0, pool.size() - 1)]
	s.doom_offers[warden_id] = offer
	return offer


## Märtyrerin: das erste Rudelopfer, wenn es ohne sie tatsächlich stürbe und noch niemand es rettet; sonst −1.
static func martyr_victim(s: GameState, martyr_id: int) -> int:
	var v := pack_victim(s)
	if v == GameState.NO_TARGET or v == martyr_id or s.martyr_saves.any(func(m: Dictionary) -> bool: return int(m["victim_id"]) == v):
		return GameState.NO_TARGET
	if StepQueue.is_marked(s, v) or s.wolf_poisons.any(func(e: Dictionary) -> bool: return int(e["target_id"]) == v and int(e["due_night"]) == s.night_number):
		return GameState.NO_TARGET  # stirbt vorher ohnehin
	if KillPipeline.pack_protection(s, v, s.plague_pierce_pending) != &"" or KillPipeline.survives_any_death(s, s.players[v]):
		return GameState.NO_TARGET
	return v


## Rettung dieser Nacht für `victim` durch eine lebende Märtyrerin oder −1.
static func martyr_for(s: GameState, victim: int) -> int:
	for m: Dictionary in s.martyr_saves:
		if int(m["victim_id"]) == victim and s.players[int(m["martyr_id"])].alive:
			return int(m["martyr_id"])
	return GameState.NO_TARGET
