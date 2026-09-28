class_name BondRules
extends RefCounted
## Wirkungen der Bindungen (DECISION-LOG „Rollenaudit · Bindungsrollen“, 28.09.2026):
##   Loki-Paare: Liebeskummer sofort als Todesfolge (nicht, wenn der Partner in dieser Nacht ohnehin
##     todesmarkiert ist); Rivalen nur Marker für die Schwarze Witwe. Ein Tod beendet das Paar (RM-DR-011.2).
##   Rotkäppchens Todeskette: stirbt eine Seite, stirbt die andere sofort mit; die Kette endet.
##   Schattenwanderer: ein tatsächlicher Tod (keine Spielleiterkorrektur) trifft stattdessen die andere Seite.
## Bindungen wirken auch im Fluch des Weisen (B-08).


## Lebende Partner von `id` in nicht beendeten Loki-Paaren (Liebe oder Rivalität), aufsteigend.
static func living_partners(s: GameState, id: int) -> Array[int]:
	var out: Array[int] = []
	if not s.players.has(id) or not s.players[id].alive:
		return out
	for pair: Dictionary in s.loki_pairs:
		if bool(pair["ended"]):
			continue
		var other := int(pair["b"]) if int(pair["a"]) == id else (int(pair["a"]) if int(pair["b"]) == id else -1)
		if other != -1 and s.players[other].alive and not out.has(other):
			out.append(other)
	out.sort()
	return out


## Verknüpfte Person, die statt `target_id` stirbt, oder −1; verbraucht die Verknüpfung.
static func shadow_partner(s: GameState, target_id: int, source_kind: StringName, chain: Array[int] = []) -> int:
	if source_kind == KillEvent.SOURCE_GM:
		return GameState.NO_TARGET
	for i: int in s.shadow_links.size():
		var link: Dictionary = s.shadow_links[i]
		var other := int(link["partner_id"]) if int(link["walker_id"]) == target_id else (int(link["walker_id"]) if int(link["partner_id"]) == target_id else -1)
		# E-20: nie zurück zu einer Person, die in dieser Kette schon betroffen war (Verknüpfung bleibt dann ungenutzt).
		if other != -1 and s.players[other].alive and not chain.has(other):
			s.shadow_links.remove_at(i)
			return other
	return GameState.NO_TARGET


## Tod von `target`: Bindungen enden; mit Todesfolgen sterben Liebende und Kettenpartner sofort mit.
static func on_death(ctx: RuleContext, target: Player, trigger_effects: bool) -> void:
	var s := ctx.state
	var heartbroken: Array[int] = []
	for pair: Dictionary in s.loki_pairs:
		if bool(pair["ended"]) or (int(pair["a"]) != target.id and int(pair["b"]) != target.id):
			continue
		pair["ended"] = true
		var other := int(pair["b"]) if int(pair["a"]) == target.id else int(pair["a"])
		if pair["kind"] == "love" and s.players[other].alive and not s.death_marks.any(func(m: Dictionary) -> bool: return int(m["target_id"]) == other):
			heartbroken.append(other)
	var chained: Array[int] = []
	var kept: Array = []
	for c: Dictionary in s.red_chains:
		var other := int(c["partner_id"]) if int(c["red_id"]) == target.id else (int(c["red_id"]) if int(c["partner_id"]) == target.id else -1)
		if other == -1:
			kept.append(c)
		elif s.players[other].alive:
			chained.append(other)
	s.red_chains = kept
	s.shadow_links = s.shadow_links.filter(func(l: Dictionary) -> bool: return int(l["walker_id"]) != target.id and int(l["partner_id"]) != target.id)
	if not trigger_effects:
		return
	for id: int in heartbroken:
		KillPipeline.request_kill(ctx, id, KillEvent.CAUSE_LOVER_HEARTBREAK, KillEvent.SOURCE_PLAYER, target.id)
	for id: int in chained:
		KillPipeline.request_kill(ctx, id, KillEvent.CAUSE_RED_CHAIN, KillEvent.SOURCE_PLAYER, target.id)
