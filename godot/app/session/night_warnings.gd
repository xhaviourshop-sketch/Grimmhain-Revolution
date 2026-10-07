class_name NightWarnings
extends RefCounted
## Warnungen der Mini-Nachtkarte (DA-101): kurze rote Zeilen, nur wenn für den aktuellen Schritt etwas Besonderes gilt. Reine Abfrage
## des Kernzustands über vorhandene Regelabfragen (Schutz, Bindungen, Verbrauch, Blockade); keine eigene Regel, kein Zustandswechsel.
## Jede Warnung ist {key, values}; Texte zentral in i18n (`ui.warn.*`). Liste aller Warnungen: docs/audit/NACHT-WARNUNGEN.md.
##   blocked    vor diesem Schritt entfiel ein Schritt durch Blockade (Albtraumwolf bzw. Schattenhund)
##   repeat     zweiter Durchgang durch den Apfel des Rotkäppchens
##   borrowed   Grabräuber handelt mit einer gestohlenen Fähigkeit
##   protected  ein mögliches Rudelopfer wäre geschützt (`KillPipeline.pack_protection`)
##   lovers     ein mögliches Opfer eines Angriffs ist Liebende(r) eines Loki-Paars
##   cursed     eine mögliche Person einer Auskunft ist verflucht (Auskünfte zeigen „Werwolf“)
## „Mögliche“ Personen: die gewählten, solange noch keine gewählt ist alle wählbaren (bei fester Anzahl gilt ein Tipp sofort, die Warnung muss
## also vorher stehen). „Letzte Nutzung“ gibt es nicht: alle begrenzten Fähigkeiten sind einmalig, die Zeile stünde bei jeder Nutzung.

const MAX_LINES := 3

## Angriffe, bei denen die gewählte Person stirbt: Bindungen der Liebenden sind dann wichtig.
const ATTACKS: Array[String] = ["pack:pick", "pack2:pick", "kriegerin-des-lichts:targets", "giftwolf:pick", "waldhexe:poison_target",
	"kartenschlucker:target", "rachsuechtiger-wolf:pick", "schicksalswolf:pick"]
## Auskünfte über die gewählte Person, die ein Fluch verfälscht.
const INFOS: Array[String] = ["das-orakel:target", "koenig:targets", "kriegerin-des-lichts:targets", "doktor:targets", "spuerhund:targets", "die-ewigen:targets"]


## Warnungen für die Karte `next` (Prompt, Schritt mit Vorschau oder Hinweis) bei der aktuellen Auswahl, höchstens `MAX_LINES`.
static func build(s: GameState, next: Dictionary, selection: Array) -> Array:
	var out: Array = []
	if s.phase != Phase.NIGHT and s.phase != Phase.DAY:
		return out
	var view := next
	if str(next.get("kind")) == "begin_step" and not (next.get("preview", {}) as Dictionary).is_empty():
		view = (next["preview"] as Dictionary).duplicate()
		view["repeat"] = next.get("repeat", false)
		view["own_role_id"] = next.get("own_role_id", "")
	var kind := str(next.get("kind"))
	if kind != "begin_step" and kind != "prompt":
		return out
	var owner := str(view.get("owner", ""))
	var combo := "%s:%s" % [owner, str(view.get("stage", "pick")) if str(view.get("stage", "")) != "" else "pick"]
	var actors: Array = view.get("actor_ids", next.get("actor_ids", []))
	var actor := int(actors[0]) if actors.size() == 1 else -1
	if s.phase == Phase.NIGHT:
		out.append_array(_blocked(s))
	if bool(view.get("repeat", next.get("repeat", false))) and actor != -1:
		out.append({"key": "ui.warn.repeat", "values": {"name": _name(s, actor)}})
	var own := str(view.get("own_role_id", next.get("own_role_id", "")))
	var role := str(view.get("role_id", next.get("role_id", "")))
	if own != "" and role != "" and own != role and actor != -1:
		out.append({"key": "ui.warn.borrowed", "values": {"name": _name(s, actor), "role": CockpitText.role_name(role)}})
	var candidates: Array = selection if not selection.is_empty() else (view.get("allowed_ids", []) if str(view.get("answer", "")) == "targets" else [])
	var paired := {}
	for id: Variant in candidates:
		var target := int(id)
		if not s.players.has(target):
			continue
		if (combo == "pack:pick" or combo == "pack2:pick") and KillPipeline.pack_protection(s, target, s.plague_pierce_pending) != &"":
			out.append({"key": "ui.warn.protected", "values": {"name": _name(s, target)}})
		if ATTACKS.has(combo):
			for partner: int in _lovers(s, target):
				var pair_key := "%d-%d" % [mini(target, partner), maxi(target, partner)]
				if not paired.has(pair_key):
					paired[pair_key] = true
					out.append({"key": "ui.warn.lovers", "values": {"a": _name(s, target), "b": _name(s, partner)}})
		if INFOS.has(combo) and s.players[target].cursed:
			out.append({"key": "ui.warn.cursed", "values": {"name": _name(s, target)}})
	return out.slice(0, MAX_LINES)


## Warnungsarten, die bei der Rolle auftreten können (Rollen-Vorschau „Sonderfall“, docs/audit/NACHT-WARNUNGEN.md); ohne `repeat`, das jede
## Rolle mit Nachtschritt treffen kann.
static func kinds_for_role(role: String) -> Array[String]:
	var out: Array[String] = []
	var id := StringName(role)
	if SetupRoleCatalog.faction_of(id) == Faction.VILLAGE and SetupRoleCatalog.has_night_step(id) and id != RoleCatalog.MAERTYRERIN:
		out.append("blocked")
	if role == String(RoleCatalog.WERWOLF):
		out.append("protected")
	for combo: String in ATTACKS:
		if _combo_role(combo) == role and not out.has("lovers"):
			out.append("lovers")
	for combo: String in INFOS:
		if _combo_role(combo) == role and not out.has("cursed"):
			out.append("cursed")
	return out


static func _combo_role(combo: String) -> String:
	var owner := combo.get_slice(":", 0)
	return String(RoleCatalog.WERWOLF) if owner == "pack" or owner == "pack2" else owner


## Entfallene Schritte durch Blockade seit dem letzten erledigten Schritt (sie stehen auf dieser Karte als Tarnaufruf).
static func _blocked(s: GameState) -> Array:
	var out: Array = []
	var first := 0
	for j: int in mini(s.next_night_step, s.night_step_status.size()):
		if s.night_step_status[j] == StepQueue.STATUS_DONE:
			first = j + 1
	for j: int in range(first, mini(s.next_night_step, s.night_plan.size())):
		if s.night_step_status[j] != StepQueue.STATUS_SKIPPED or StepQueue.drop_reason(s, j) != &"blocked":
			continue
		var actor := StepQueue.step_actor(s.night_plan[j])
		if not s.players.has(actor):
			continue
		var blocker := RoleCatalog.SCHATTENHUND if s.village_blocked else RoleCatalog.ALBTRAUMWOLF
		out.append({"key": "ui.warn.blocked", "values": {"role": CockpitText.role_name(String(blocker)), "name": _name(s, actor)}})
	return out


## Lebende Liebende von `id` (Loki-Paare der Art „love“).
static func _lovers(s: GameState, id: int) -> Array[int]:
	var out: Array[int] = []
	for partner: int in BondRules.living_partners(s, id):
		for pair: Dictionary in s.loki_pairs:
			if not bool(pair["ended"]) and str(pair["kind"]) == "love" and [int(pair["a"]), int(pair["b"])].has(id) and [int(pair["a"]), int(pair["b"])].has(partner):
				out.append(partner)
				break
	return out


static func _name(s: GameState, id: int) -> String:
	return s.players[id].name if s.players.has(id) else ""
