class_name StepQueue
extends RefCounted
## Reihenfolge der Regelschritte (B-11): Nachtschritte nach Nachtplan und offene
## Reaktionen. Es gibt immer höchstens einen erwarteten nächsten Schritt.
##   Nacht:              nächster nicht erledigter Eintrag des Nachtplans
##   Morgenauflösung/Tag: erste offene Reaktion (Reaktionen aus der Nacht warten
##                        bis zur Morgenauflösung, DR-09)
## Schritt-IDs: "night:<Nacht>:<Index>:<Schritt>" bzw. "reaction:<Reaktions-ID>".
## Nachtschritte: persönliche Rollenschritte "<rolle>:<Personen-ID>" und der Rudelschritt
## "pack", sortiert nach Nachtpriorität (RoleCatalog), bei gleicher Priorität nach
## Personen-ID: Wolfskind → Lehrling → Schutzengel → Rudel → Waldhexe → Orakel.
## Ein Grabräuber plant nach dem Diebstahl den Schritt der gestohlenen Rolle (SoloRules.ability_role).
## Der Nachtplan ist ein Snapshot bei StartNight: Rollenwechsel während der Nacht fügen
## keine Schritte hinzu. Ein persönlicher Schritt entfällt automatisch und protokolliert
## (`StepDropped`), wenn seine Person inzwischen tot ist, nicht mehr die geplante Rolle
## hat oder (Waldhexe) keine Entscheidung mehr treffen kann. Der Rudelschritt entfällt,
## wenn keine Person mehr lebt, die bei StartNight als Wolf zählte (`night_wolf_ids`).

const PACK := &"pack"
const PACK2 := &"pack2"  ## zweiter Rudelschritt nach dem Lynch eines Rudelvaters (RM-DR-112)
const BOUND := &"die-gebundenen"  ## gemeinsamer Schritt aller Gebundenen, nur Nacht 1
const ETERNAL := &"die-ewigen"  ## gemeinsamer Schritt aller Ewigen, jede Nacht (I-11)
const PIPER_ALL := &"piper-all"  ## „Alle Verzauberten“ direkt hinter dem Rattenfänger (PE-06)
const STATUS_PENDING := &"pending"
const STATUS_DONE := &"done"
const STATUS_SKIPPED := &"skipped"
const STEP_STATUSES: Array[StringName] = [STATUS_PENDING, STATUS_DONE, STATUS_SKIPPED]
const PIPER_ALL_ORDER := 1 << 30  ## Sortierschlüssel: hinter jedem Rattenfänger-Schritt derselben Priorität


static func personal_step_key(role_id: StringName, player_id: int) -> StringName:
	return StringName("%s:%d" % [role_id, player_id])


## Geplante Rolle eines persönlichen Nachtschritts oder &"" (Rudel).
static func step_role(key: StringName) -> StringName:
	var parts := String(key).split(":")
	return StringName(parts[0]) if parts.size() == 2 else &""


## Handelnde Person eines persönlichen Nachtschritts oder -1 (Rudel).
static func step_actor(key: StringName) -> int:
	var parts := String(key).split(":")
	return int(parts[1]) if parts.size() == 2 and parts[1].is_valid_int() else -1


static func night_step_id(s: GameState, index: int) -> String:
	return "night:%d:%d:%s" % [s.night_number, index, s.night_plan[index]]


static func reaction_step_id(r: Reaction) -> String:
	return "reaction:%d" % r.id


## Offene Reaktionen, die jetzt abgearbeitet werden müssen (Pflicht).
static func reactions_due(s: GameState) -> bool:
	return (s.phase == Phase.DAWN_RESOLUTION or s.phase == Phase.DAY) and not s.reactions.is_empty()


## Erwarteter nächster Schritt oder "" (auch wenn er bereits begonnen ist).
static func next_step_id(s: GameState) -> String:
	if s.phase == Phase.NIGHT:
		return night_step_id(s, s.next_night_step) if s.next_night_step < s.night_plan.size() else ""
	if reactions_due(s):
		return reaction_step_id(s.reactions[0])
	return ""


static func is_reaction_step(step_id: String) -> bool:
	return step_id.begins_with("reaction:")


## Schrittarten und ob `SkipStep` sie überspringen darf. Unbekannte Arten sind nie
## überspringbar. Pflichtentscheidungen (Schutzengel, Reaktionen) werden beantwortet,
## nicht übersprungen; `CancelPrompt` bleibt davon unberührt.
const KIND_REACTION := &"reaction"
const SKIPPABLE_BY_KIND := {
	PACK: true,                        # Rudel: kein Angriff, nur mit Grund
	PACK2: true,                       # zweiter Rudelschritt wie das Rudel
	RoleCatalog.SCHATTENHUND: false,   # Verzicht ist eine Antwort
	RoleCatalog.ALBTRAUMWOLF: false,   # Pflichtwahl einer anderen Person (kein Verzicht)
	RoleCatalog.GIFTWOLF: false,       # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.HENKER: false,         # Pflichtwahl (kein Verzicht)
	RoleCatalog.SCHUTZENGEL: false,    # Pflichtauswahl (DR-05)
	RoleCatalog.WALDHEXE: false,       # Verzicht auf beide Tränke ist eine Antwort im eigenen Prompt (DR-06)
	RoleCatalog.ORAKEL: false,         # Pflichtprüfung einer anderen lebenden Person (DR-07)
	RoleCatalog.WOLFSKIND: false,      # Pflichtwahl eines Vorbilds (DR-10)
	RoleCatalog.LEHRLING: false,       # Pflichtwahl eines Meisters (DR-11)
	RoleCatalog.DORFCHRONISTIN: false, # Pflichtinformation Nacht 1 (wie Orakel)
	BOUND: false,                      # Pflichtinformation Nacht 1 (wie Orakel)
	RoleCatalog.WALDLAEUFER: false,    # Pflichtinformation (wie Orakel)
	RoleCatalog.DOKTOR: false,         # Pflichtprüfung (wie Orakel)
	RoleCatalog.FAEHRTENLESER: false,  # Verzicht ist eine Antwort im Prompt
	RoleCatalog.KORRUPTER_RICHTER: false,  # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.SPUERHUND: false,      # Pflichtwahl genau dreier Personen (kein Verzicht)
	RoleCatalog.PARASIT: false,        # Behalten ist eine Antwort (0 Ziele)
	RoleCatalog.TRAUMDEUTER: false,    # Pflichtinformation (Spielleiter wählt drei Personen)
	RoleCatalog.KOPFGELDJAEGER: false, # Pflichtinformation je offener Liste
	RoleCatalog.KOENIG: false,         # Pflichtinformation
	RoleCatalog.KRIEGERIN: false,      # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.BLUTPRIESTER: false,   # Verzicht ist eine Antwort (0 Ziele)
	ETERNAL: false,                    # Pflichtprüfung der Ewigen
	PIPER_ALL: false,                  # Pflichtinformation nach jedem Aufruf des Rattenfängers (PE-06)
	RoleCatalog.DORFSCHMIED: false,    # „noch nicht“ ist eine Antwort (0 Ziele)
	RoleCatalog.SCHUTZGEIST: false,    # Pflichtwahl einer lebenden Person
	RoleCatalog.VERDAMMNISWAECHTER: false,  # Pflichturteil zwischen zwei Personen
	RoleCatalog.MAERTYRERIN: false,    # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.LOKI: false,           # Pflichtwahl genau zweier Personen (kein Verzicht)
	RoleCatalog.ROTKAEPPCHEN: false,   # Pflichtfrage nach Zuflucht
	RoleCatalog.SCHWARZE_WITWE: false, # Pflichtwahl
	RoleCatalog.SCHATTENWANDERER: false,  # „noch nicht“ ist eine Antwort (0 Ziele)
	RoleCatalog.KOENIG_LYKAON: false,  # Verschieben ist eine Antwort (0 Ziele) in Nacht 1 und 2, in Nacht 3 Pflicht
	RoleCatalog.SEELENTAUSCHER: false,  # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.KUTSCHER: false,       # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.FRANKENSTEIN: false,   # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.RATTENFAENGER: false,  # Pflichtwahl 1–2
	RoleCatalog.PESTBRINGERIN: false,  # Pflichtwahl
	RoleCatalog.PROPHET: false,        # Markieren Pflicht, Töten mit Verzicht (0 Ziele)
	RoleCatalog.TODESPREDIGER: false,  # Pflichtvorhersage
	RoleCatalog.FEUERTEUFEL: false,    # Pflichtwahl (dieselbe Person erneut = behalten)
	RoleCatalog.VOODOO: false,         # Pflichtwahl einer Person (kein Verzicht)
	RoleCatalog.NEKROMANT: false,      # Verzicht ist eine Antwort (0 Tote)
	RoleCatalog.HADES: false,          # Verzicht ist eine Antwort (0 Ziele, keine Barriere)
	RoleCatalog.GRABRAEUBER: false,    # Verzicht ist eine Antwort (0 Tote)
	RoleCatalog.SCHICKSALSWOLF: false,  # Markieren Pflicht, Zusatzopfer mit Verzicht (0 Ziele)
	RoleCatalog.RACHSUECHTIGER_WOLF: false,  # Verzicht ist eine Antwort (0 Ziele)
	RoleCatalog.ZEITWAECHTER: false,   # Nein ist eine Antwort
	RoleCatalog.KARTENSCHLUCKER: false,  # Nichtstun ist eine Antwort (Kopfschütteln)
	KIND_REACTION: false,              # Pflichtreaktion, kein Verzicht (DR-09, DA Nachtschritte neu)
}


## Art eines Schritts aus seiner ID: "reaction", "pack" oder die Rolle eines persönlichen Schritts.
static func step_kind(step_id: String) -> StringName:
	if is_reaction_step(step_id):
		return KIND_REACTION
	var parts := step_id.split(":")
	return StringName(parts[3]) if parts.size() >= 4 and parts[0] == "night" else &""


static func is_skippable(step_id: String) -> bool:
	return SKIPPABLE_BY_KIND.get(step_kind(step_id), false)


## Nachtplan aus den zu Beginn der Nacht gültigen Rollen (Snapshot): persönliche Schritte
## lebender Rolleninhaber und der Rudelschritt, solange mindestens eine lebende Person als
## Wolf zählt (G-PH-6), sortiert nach Nachtpriorität und Personen-ID. Waldhexen nur mit
## mindestens einem unverbrauchten Trank, Wolfskinder und Lehrlinge nur mit Auswahlbedarf.
static func build_night_plan(s: GameState) -> Array[StringName]:
	var entries: Array = []  # [Priorität, Personen-ID, Schritt]
	for pair: Array in SoloRules.night_role_pairs(s):  # Grabräuber: gestohlene Nachtfähigkeit (E-32); Totenreichkarten: zusätzliche Fähigkeit
		var id: int = pair[0]
		var p := s.players[id]
		var role: StringName = pair[1]
		if not RoleCatalog.has_night_step(role):
			continue
		var priority := RoleCatalog.night_priority(role)
		if role == RoleCatalog.WALDHEXE and not WitchStep.has_any_potion(p):
			continue
		if role == RoleCatalog.WOLFSKIND and not WolfChildRules.needs_model(s, id):
			continue
		if role == RoleCatalog.LEHRLING and not ApprenticeRules.needs_selection(s, id):
			continue
		if RoleCatalog.first_night_only(role) and s.night_number != 1:
			continue
		if role == RoleCatalog.FAEHRTENLESER and InfoSteps.tracker_used(p):
			continue
		if role == RoleCatalog.SCHATTENHUND and p.ability_uses.has("schattenhund:block"):
			continue
		if role == RoleCatalog.GIFTWOLF and p.ability_uses.has("giftwolf:paw2"):
			continue
		if role == RoleCatalog.HENKER and s.executions_count < RoleCatalog.HANGMAN_MIN_EXECUTIONS:
			continue
		if role == RoleCatalog.KOPFGELDJAEGER and int(s.bounty_credits.get(id, 0)) < 1:
			continue
		if role == RoleCatalog.KOENIG and (InfoSteps.used(p, InfoSteps.KING_USE_KEY) or not InfoSteps.king_condition(s)):
			continue
		if role == RoleCatalog.KRIEGERIN and InfoSteps.used(p, InfoSteps.WARRIOR_USE_KEY):
			continue
		if role == RoleCatalog.BLUTPRIESTER and InfoSteps.used(p, InfoSteps.BLOOD_USE_KEY):
			continue
		if role == RoleCatalog.DORFSCHMIED and not GuardRoles.smith_can_give(s, p):
			continue
		if role == RoleCatalog.SCHUTZGEIST:
			continue  # handelt nur tot (unten)
		if role == RoleCatalog.SCHATTENWANDERER and p.ability_uses.has("schattenwanderer:link"):
			continue
		if role == RoleCatalog.KOENIG_LYKAON and (p.ability_uses.has(BondSteps.LYCAON_USE_KEY) or s.night_number > RoleCatalog.LYCAON_LAST_NIGHT):
			continue
		if role == RoleCatalog.SEELENTAUSCHER and p.ability_uses.has(BondSteps.SWAP_USE_KEY):
			continue
		if (role == RoleCatalog.KUTSCHER or role == RoleCatalog.FRANKENSTEIN) and not BondSteps.can_revive(s, p, role):
			continue
		if role == RoleCatalog.PROPHET and not (SoloRules.prophet_marking(s, id) or s.prophet_unlocked.has(id)):
			continue
		if role == RoleCatalog.TODESPREDIGER and not SoloRules.prophecy_of(s, id).is_empty():
			continue
		if role == RoleCatalog.VOODOO and SoloRules.doll_of(s, id) != GameState.NO_TARGET:
			continue  # nur ohne lebende Puppe (E-13)
		if role == RoleCatalog.RACHSUECHTIGER_WOLF and not SoloRules.lone_night(s):
			continue  # nur jede dritte Nacht (DA-16)
		if role == RoleCatalog.ZEITWAECHTER and p.ability_uses.has(RulesEngine.TIME_USE_KEY):
			continue  # einmal je Leben (E-36)
		if role == RoleCatalog.KARTENSCHLUCKER and not SwallowerRules.has_decision(s, id):
			continue  # ohne bezahlbare Aktion nur Tarnaufruf (CallPolicy)
		if role == RoleCatalog.SCHICKSALSWOLF and not (SoloRules.fate_marking(s, id) or SoloRules.fate_killing(s, id)):
			continue  # nur Nacht 1 (markieren) und Nacht 4 (Zusatzopfer)
		if role == RoleCatalog.GRABRAEUBER and p.ability_uses.has(SoloRules.GRAVE_USE_KEY):
			continue  # nur einmal stehlen (E-32)
		if role == RoleCatalog.HADES and SoloRules.hades_light_count(s, id) < RoleCatalog.HADES_KILL_COST:
			continue  # ohne 2 Lichter nichts zu kaufen (E-30, E-31)
		if role == RoleCatalog.VERDAMMNISWAECHTER:
			priority = CardHooks.guard_priority(s, priority)  # braucht das Rudelopfer, auch wenn das Rudel als letztes ruft
		entries.append([priority, id, personal_step_key(role, id)])
	# Schutzgeist: Ausnahme zu G-PH-2, handelt in der ersten Nacht nach ihrem Tod (S-04).
	for id: int in s.players:
		if GuardRoles.ghost_can_act(s, s.players[id]):
			entries.append([RoleCatalog.night_priority(RoleCatalog.SCHUTZGEIST), id, personal_step_key(RoleCatalog.SCHUTZGEIST, id)])
	for id: int in s.alive_ids():
		if s.players[id].counts_as_wolf:
			var pack_slot := CardHooks.pack_slot(s)
			entries.append([pack_slot[0], pack_slot[1], PACK])
			if s.pack_bonus_pending:
				entries.append([pack_slot[0], int(pack_slot[1]) + 1, PACK2])
			break
	if s.night_number == 1 and not InfoSteps.living_bound(s).is_empty():
		entries.append([RoleCatalog.BOUND_PRIORITY, 0, BOUND])
	if not InfoSteps.living_eternal(s).is_empty():
		entries.append([RoleCatalog.ETERNAL_PRIORITY, 0, ETERNAL])
	# PE-06: nach jedem Aufruf des Rattenfängers (echter Schritt oder Tarnaufruf), hinter allen Rattenfänger-Schritten.
	# Auch ohne Verzauberte bei Nachtbeginn, weil der Rattenfänger in dieser Nacht die ersten verzaubern kann.
	if CallPolicy.called_roles(s).has(RoleCatalog.RATTENFAENGER) or entries.any(func(e: Array) -> bool: return step_role(e[2]) == RoleCatalog.RATTENFAENGER):
		entries.append([RoleCatalog.night_priority(RoleCatalog.RATTENFAENGER), PIPER_ALL_ORDER, PIPER_ALL])
	entries.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var plan: Array[StringName] = []
	for entry: Array in entries:
		plan.append(entry[2])
	return plan


## Grund, warum der Nachtschritt `index` entfällt, oder &"" wenn er auszuführen ist.
static func drop_reason(s: GameState, index: int) -> StringName:
	var reason := core_drop_reason(s, index)
	if reason != &"":
		return reason
	return &"card_blocked" if CardHooks.step_blocked(s, index) else &""


static func core_drop_reason(s: GameState, index: int) -> StringName:
	var key := s.night_plan[index]
	if key == PIPER_ALL:
		# PE-06: entfällt nur ohne Aufruf des Rattenfängers oder ohne lebende Verzauberte. Keine Fähigkeit, daher weder
		# Einfrieren (E-36) noch Blockade: Der Tarnaufruf des Rattenfängers wird auch dann angesagt (DI-02).
		if not piper_called(s):
			return &"not_called"
		return &"no_decision" if SoloRules.charmed_living(s).is_empty() else &""
	if s.night_frozen:
		return &"frozen"  # Zeitwächter (E-36): alle Nachtschritte dieser Nacht entfallen
	if key == BOUND:
		if InfoSteps.living_bound(s).is_empty():
			return &"no_decision"
		if s.village_blocked:
			return &"blocked"  # Blockade gemeinsamer Dorfschritte (RM-DR-010)
		return &"cursed" if GuardRoles.curse_active(s) else &""
	if key == ETERNAL:
		if InfoSteps.living_eternal(s).is_empty() or InfoSteps.eternal_targets(s).is_empty():
			return &"no_decision"
		if s.village_blocked or InfoSteps.awake_eternal(s).is_empty():
			return &"blocked"
		return &"cursed" if GuardRoles.curse_active(s) else &""
	if key == PACK or key == PACK2:
		if CardHooks.pack_suppressed(s):
			return &"card_sleep"  # Totenreichkarte: kein gemeinsames Rudelopfer in dieser Nacht
		# G-PH-6 mit Decision Log „Rollenaudit“ (F-10): Das Rudel dieser Nacht sind die Personen,
		# die bei StartNight als Wolf zählten; lebt keine von ihnen mehr, entfällt der Schritt.
		for id: int in s.night_wolf_ids:
			if s.players[id].alive:
				return &""
		return &"no_living_wolf"
	var actor := step_actor(key)
	if step_role(key) == RoleCatalog.SCHUTZGEIST:
		if not s.players.has(actor) or not GuardRoles.ghost_can_act(s, s.players[actor]) or s.alive_ids().is_empty():
			return &"no_decision"  # Pflichtwahl einer lebenden Person unmöglich
		if s.players[actor].faction == Faction.VILLAGE and s.village_blocked:
			return &"blocked"
		return &"cursed" if GuardRoles.silenced(s, actor) else &""
	if not s.players.has(actor) or not s.players[actor].alive:
		return &"actor_dead"
	# Vergiftete oder geopferte Personen wachen in dieser Nacht nicht mehr auf (Decision Log „Nachttode“).
	if is_marked(s, actor):
		return &"marked_for_death"
	# Blockade (RM-DR-010): nur aktive Nachtschritte von Dorfrollen; die Märtyrerin ist nicht blockierbar (S-03).
	if s.players[actor].faction == Faction.VILLAGE and (s.village_blocked or s.blocked_ids.has(actor)) and step_role(key) != RoleCatalog.MAERTYRERIN:
		return &"blocked"
	# Fluch des Weisen: alle Fähigkeiten der Dorfpersonen ruhen (S-01, S-05).
	if GuardRoles.silenced(s, actor):
		return &"cursed"
	# Nie die Fähigkeit einer inzwischen verlorenen Rolle ausführen (gilt für alle persönlichen Schritte).
	if not SoloRules.acts_as(s, actor, step_role(key)):
		return &"actor_role_changed"
	if step_role(key) == RoleCatalog.WALDHEXE and not WitchStep.has_decision(s, actor):
		return &"no_decision"
	if step_role(key) == RoleCatalog.WOLFSKIND and not WolfChildRules.needs_model(s, actor):
		return &"no_decision"  # Vorbild schon gesetzt oder verwandelt
	if step_role(key) == RoleCatalog.LEHRLING and not (ApprenticeRules.needs_selection(s, actor) and ApprenticeRules.can_select(s, actor)):
		return &"no_decision"  # schon gebunden oder weniger als drei andere Lebende
	if [RoleCatalog.ORAKEL, RoleCatalog.SCHUTZENGEL, RoleCatalog.WOLFSKIND, RoleCatalog.HENKER, RoleCatalog.ALBTRAUMWOLF].has(step_role(key)) and s.alive_ids().size() < 2:
		return &"no_decision"  # Pflichtwahl einer anderen lebenden Person unmöglich
	if step_role(key) == RoleCatalog.FAEHRTENLESER and InfoSteps.tracker_used(s.players[actor]):
		return &"no_decision"  # in diesem Leben schon genutzt
	if step_role(key) == RoleCatalog.DOKTOR and s.alive_ids().size() < 3:
		return &"no_decision"  # keine zwei anderen Lebenden
	if step_role(key) == RoleCatalog.SPUERHUND and not InfoSteps.hound_lost(s.players[actor]) and s.alive_ids().size() < InfoSteps.HOUND_PICKS + 1:
		return &"no_decision"  # die Karte verlangt genau drei andere Lebende
	if (step_role(key) == RoleCatalog.TRAUMDEUTER or step_role(key) == RoleCatalog.KOPFGELDJAEGER) and not InfoSteps.triple_possible(s, actor):
		return &"no_decision"  # keine drei anderen Lebenden mit mindestens einem Wolf
	if step_role(key) == RoleCatalog.KOPFGELDJAEGER and int(s.bounty_credits.get(actor, 0)) < 1:
		return &"no_decision"
	if step_role(key) == RoleCatalog.KOENIG and (InfoSteps.used(s.players[actor], InfoSteps.KING_USE_KEY) or not InfoSteps.king_condition(s) or InfoSteps.king_candidates(s, actor).is_empty()):
		return &"no_decision"
	if step_role(key) == RoleCatalog.KRIEGERIN and (InfoSteps.used(s.players[actor], InfoSteps.WARRIOR_USE_KEY) or s.alive_ids().size() < 2):
		return &"no_decision"
	if step_role(key) == RoleCatalog.BLUTPRIESTER and (InfoSteps.used(s.players[actor], InfoSteps.BLOOD_USE_KEY) or s.alive_ids().size() < 2):
		return &"no_decision"
	if step_role(key) == RoleCatalog.DORFSCHMIED and (not GuardRoles.smith_can_give(s, s.players[actor]) or s.alive_ids().size() < 2):
		return &"no_decision"
	if step_role(key) == RoleCatalog.VERDAMMNISWAECHTER and (GuardRoles.pack_victim(s) in [GameState.NO_TARGET, actor] or GuardRoles.doom_pool(s, actor).is_empty()):
		return &"no_decision"  # kein Rudelopfer, er selbst ist das Opfer (S-15) oder kein Angebot möglich
	if step_role(key) == RoleCatalog.MAERTYRERIN and GuardRoles.martyr_victim(s, actor) == GameState.NO_TARGET:
		return &"no_decision"  # das Rudelopfer stirbt nicht (oder ist sie selbst)
	if [RoleCatalog.ROTKAEPPCHEN, RoleCatalog.SCHWARZE_WITWE, RoleCatalog.SCHATTENWANDERER, RoleCatalog.LOKI].has(step_role(key)) and s.alive_ids().size() < 2:
		return &"no_decision"  # keine andere lebende Person
	if step_role(key) == RoleCatalog.SCHATTENWANDERER and s.players[actor].ability_uses.has("schattenwanderer:link"):
		return &"no_decision"
	if step_role(key) == RoleCatalog.KOENIG_LYKAON and (s.players[actor].ability_uses.has(BondSteps.LYCAON_USE_KEY) or s.night_number > RoleCatalog.LYCAON_LAST_NIGHT or BondSteps.lycaon_allies(s, actor).is_empty() or BondSteps.lycaon_targets(s).is_empty()):
		return &"no_decision"  # ohne lebenden Verbündeten zählt die Nacht nicht (V-09)
	if step_role(key) == RoleCatalog.SEELENTAUSCHER and s.players[actor].ability_uses.has(BondSteps.SWAP_USE_KEY):
		return &"no_decision"
	if (step_role(key) == RoleCatalog.KUTSCHER or step_role(key) == RoleCatalog.FRANKENSTEIN) and not BondSteps.can_revive(s, s.players[actor], step_role(key)):
		return &"no_decision"
	if step_role(key) == RoleCatalog.RATTENFAENGER and SoloRules.charm_targets(s, actor).is_empty():
		return &"no_decision"
	if step_role(key) == RoleCatalog.PESTBRINGERIN and SoloRules.pest_targets(s, actor).is_empty():
		return &"no_decision"
	if step_role(key) == RoleCatalog.FEUERTEUFEL and SoloRules.fire_targets(s, actor).is_empty():
		return &"no_decision"
	if step_role(key) == RoleCatalog.VOODOO and (SoloRules.doll_of(s, actor) != GameState.NO_TARGET or SoloRules.fire_targets(s, actor).is_empty()):
		return &"no_decision"
	if step_role(key) == RoleCatalog.NEKROMANT and SoloRules.necro_pool(s).size() < RoleCatalog.NECRO_SACRIFICE:
		return &"no_decision"
	if step_role(key) == RoleCatalog.HADES and not SoloRules.hades_has_decision(s, actor):
		return &"no_decision"
	if step_role(key) == RoleCatalog.RACHSUECHTIGER_WOLF and SoloRules.lone_targets(s, actor).is_empty():
		return &"no_decision"  # kein anderer lebender Wolf
	if step_role(key) == RoleCatalog.ZEITWAECHTER and s.players[actor].ability_uses.has(RulesEngine.TIME_USE_KEY):
		return &"no_decision"
	if step_role(key) == RoleCatalog.KARTENSCHLUCKER and not SwallowerRules.has_decision(s, actor):
		return &"no_decision"
	if step_role(key) == RoleCatalog.SCHICKSALSWOLF:
		if SoloRules.fate_marking(s, actor):
			return &"no_decision" if s.alive_ids().size() - 1 < RoleCatalog.FATE_MARKS else &""
		return &"" if SoloRules.fate_killing(s, actor) and s.alive_ids().size() >= 2 else &"no_decision"
	if step_role(key) == RoleCatalog.GRABRAEUBER and (s.players[actor].ability_uses.has(SoloRules.GRAVE_USE_KEY) or SoloRules.grave_targets(s, actor).is_empty()):
		return &"no_decision"
	if step_role(key) == RoleCatalog.PROPHET:
		if SoloRules.prophet_marking(s, actor):
			return &"no_decision" if s.alive_ids().size() - 1 < RoleCatalog.PROPHET_MARKS else &""
		return &"" if s.prophet_unlocked.has(actor) and s.alive_ids().size() >= 2 else &"no_decision"
	return &""


## Wurde der Rattenfänger in dieser Nacht aufgerufen? Nach der Aufrufpolitik (auch als Tarnaufruf) oder durch einen
## ausgeführten Rattenfänger-Schritt (Grabräuber mit gestohlener Fähigkeit).
static func piper_called(s: GameState) -> bool:
	if CallPolicy.called_roles(s).has(RoleCatalog.RATTENFAENGER):
		return true
	for j: int in s.night_plan.size():
		if step_role(s.night_plan[j]) == RoleCatalog.RATTENFAENGER and s.night_step_status[j] == STATUS_DONE:
			return true
	return false


## Todesmarkierung dieser Nacht: Gifttrank der Waldhexe oder Tod am Morgen aus einem Nachtschritt.
static func is_marked(s: GameState, id: int) -> bool:
	return WitchStep.is_marked(s, id) or s.death_marks.any(func(m: Dictionary) -> bool: return int(m["target_id"]) == id)


## Lässt nicht ausführbare Nachtschritte am Anfang der Warteschlange deterministisch
## entfallen (Status `skipped`, Ereignis `StepDropped`). Läuft nach jedem Befehl und vor
## dem ersten Schritt der Nacht, nie bei offenem Prompt.
static func drop_unactionable(ctx: RuleContext) -> void:
	var s := ctx.state
	if s.phase != Phase.NIGHT or s.pending_prompt != null:
		return
	while s.next_night_step < s.night_plan.size():
		var reason := drop_reason(s, s.next_night_step)
		if reason == &"":
			return
		var step_id := night_step_id(s, s.next_night_step)
		var key := s.night_plan[s.next_night_step]
		if reason == &"no_decision" and step_role(key) == RoleCatalog.KOPFGELDJAEGER and int(s.bounty_credits.get(step_actor(key), 0)) >= 1:
			InfoSteps.expire_bounty(ctx, step_actor(key))  # zu wenige Ziele: Liste verfällt mit Hinweis (I-04)
		s.night_step_status[s.next_night_step] = STATUS_SKIPPED
		s.next_night_step += 1
		ctx.emit(GameEvent.STEP_DROPPED, Visibility.GM, {"step_id": step_id, "reason": reason})


## Beginnt den (bereits validierten) erwarteten Schritt und öffnet seinen Prompt.
static func begin(ctx: RuleContext, step_id: String) -> void:
	var s := ctx.state
	ctx.emit(GameEvent.STEP_BEGUN, Visibility.GM, {"step_id": step_id})
	if not is_reaction_step(step_id):
		_apply_apple(ctx)
	var prompt := PendingPrompt.new()
	prompt.id = s.next_prompt_id
	s.next_prompt_id += 1
	prompt.kind = PendingPrompt.KIND_PICK_PLAYERS
	prompt.step_id = step_id
	prompt.min_count = 0
	prompt.max_count = 1
	prompt.allowed_ids = s.alive_ids()
	if is_reaction_step(step_id):
		# Pflichtreaktion (DA-Nachtschritte-neu: kein Verzicht, wo die Karte keinen vorsieht); nicht abbrechbar.
		# Nur ohne mögliches Ziel sind 0 Ziele erlaubt. Der Besitzer ist nie Ziel seiner eigenen Reaktion,
		# auch nicht nach einer Wiederbelebung.
		prompt.owner = PendingPrompt.OWNER_REACTION
		prompt.actor_id = s.reactions[0].owner_id
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.cancellable = false
		if s.reactions[0].kind == Reaction.KIND_KNIGHT:
			# Ritter bei Gleichstand: Pflichtwahl unter den jetzt gleich nahen Wölfen.
			prompt.allowed_ids = Seats.closest_wolves(s, prompt.actor_id)
		elif s.reactions[0].kind == Reaction.KIND_SMITH:
			# Schmiedewaffe: der Spielleiter wählt einen lebenden Wolf, der stirbt (S-06).
			prompt.allowed_ids = prompt.allowed_ids.filter(func(id: int) -> bool: return s.players[id].counts_as_wolf)
		prompt.min_count = 1 if not prompt.allowed_ids.is_empty() else 0
	elif step_kind(step_id) == RoleCatalog.WALDHEXE:
		# Waldhexe: mehrstufige, atomare Kette (WitchStep).
		WitchStep.open(s, prompt, step_actor(s.night_plan[s.next_night_step]))
	elif step_kind(step_id) == RoleCatalog.ORAKEL:
		# Orakel: Zielwahl, dann Bestätigung „Gezeigt“ (OracleStep).
		OracleStep.open(s, prompt, step_actor(s.night_plan[s.next_night_step]))
	elif step_kind(step_id) == RoleCatalog.LEHRLING:
		# Lehrling: Kandidaten, Option, Bestätigung (ApprenticeRules).
		ApprenticeRules.open(s, prompt, step_actor(s.night_plan[s.next_night_step]))
	elif s.night_plan[s.next_night_step] == BOUND:
		InfoSteps.open(s, prompt, PendingPrompt.OWNER_BOUND, -1)
	elif BondSteps.OWNERS.has(step_kind(step_id)):
		BondSteps.open(s, prompt, step_kind(step_id), step_actor(s.night_plan[s.next_night_step]))
	elif [RoleCatalog.RATTENFAENGER, RoleCatalog.PESTBRINGERIN, RoleCatalog.PROPHET, RoleCatalog.FEUERTEUFEL, RoleCatalog.VOODOO, RoleCatalog.SCHICKSALSWOLF, RoleCatalog.RACHSUECHTIGER_WOLF].has(step_kind(step_id)):
		var solo_actor := step_actor(s.night_plan[s.next_night_step])
		prompt.owner = step_kind(step_id)
		prompt.actor_id = solo_actor
		prompt.cancellable = true
		match step_kind(step_id):
			RoleCatalog.RATTENFAENGER:  # 1 oder 2 noch unverzauberte andere Lebende
				prompt.allowed_ids = SoloRules.charm_targets(s, solo_actor)
				prompt.min_count = 1
				prompt.max_count = mini(2, prompt.allowed_ids.size())
			RoleCatalog.PESTBRINGERIN:  # eine noch gesunde andere Lebende
				prompt.allowed_ids = SoloRules.pest_targets(s, solo_actor)
				prompt.min_count = 1
			RoleCatalog.PROPHET:  # Nacht 1: drei andere markieren; freigeschaltet: eine andere töten oder verzichten
				prompt.allowed_ids.erase(solo_actor)
				if SoloRules.prophet_marking(s, solo_actor):
					prompt.min_count = RoleCatalog.PROPHET_MARKS
					prompt.max_count = RoleCatalog.PROPHET_MARKS
			RoleCatalog.FEUERTEUFEL:  # jede Nacht genau eine andere Lebende markieren (die Karte nennt keinen Verzicht)
				prompt.allowed_ids = SoloRules.fire_targets(s, solo_actor)
				prompt.min_count = 1
			RoleCatalog.VOODOO:  # Puppe: genau eine andere Lebende (die Karte nennt keinen Verzicht)
				prompt.allowed_ids = SoloRules.fire_targets(s, solo_actor)
				prompt.min_count = 1
			RoleCatalog.RACHSUECHTIGER_WOLF:  # einen anderen lebenden Wolf reißen oder verzichten (DA-17)
				prompt.allowed_ids = SoloRules.lone_targets(s, solo_actor)
			RoleCatalog.SCHICKSALSWOLF:  # Nacht 1: genau drei andere markieren; Nacht 4: bis zu so viele Zusatzopfer
				prompt.allowed_ids = SoloRules.fire_targets(s, solo_actor)
				if SoloRules.fate_marking(s, solo_actor):
					prompt.min_count = RoleCatalog.FATE_MARKS
					prompt.max_count = RoleCatalog.FATE_MARKS
				else:
					prompt.max_count = mini(SoloRules.fate_bonus(s, solo_actor), prompt.allowed_ids.size())
	elif step_kind(step_id) == RoleCatalog.SCHWARZE_WITWE or step_kind(step_id) == RoleCatalog.SCHATTENWANDERER:
		# Witwe: Pflichtwahl einer anderen lebenden Person; Schattenwanderer: eine andere oder „noch nicht“.
		prompt.owner = step_kind(step_id)
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.min_count = 1 if step_kind(step_id) == RoleCatalog.SCHWARZE_WITWE else 0
		prompt.cancellable = true
	elif s.night_plan[s.next_night_step] == ETERNAL:
		InfoSteps.open(s, prompt, PendingPrompt.OWNER_ETERNAL, -1)
	elif s.night_plan[s.next_night_step] == PIPER_ALL:
		InfoSteps.open(s, prompt, PendingPrompt.OWNER_PIPER_ALL, -1)
	elif InfoSteps.OWNERS.has(step_kind(step_id)):
		InfoSteps.open(s, prompt, step_kind(step_id), step_actor(s.night_plan[s.next_night_step]))
	elif s.night_plan[s.next_night_step] == PACK2:
		# Zweiter Rudelschritt (Rudelvater): wie das Rudel, Opfer durchdringt Schutz.
		prompt.owner = PendingPrompt.OWNER_PACK2
		prompt.actor_id = -1
		prompt.cancellable = true
	elif step_kind(step_id) == RoleCatalog.SCHATTENHUND or step_kind(step_id) == RoleCatalog.ZEITWAECHTER:
		prompt.owner = PendingPrompt.OWNER_SHADOW if step_kind(step_id) == RoleCatalog.SCHATTENHUND else PendingPrompt.OWNER_TIME
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.stage = &"use"
		prompt.allowed_ids = []
		prompt.cancellable = true
	elif [RoleCatalog.DORFSCHMIED, RoleCatalog.SCHUTZGEIST, RoleCatalog.VERDAMMNISWAECHTER, RoleCatalog.MAERTYRERIN].has(step_kind(step_id)):
		var guard_actor := step_actor(s.night_plan[s.next_night_step])
		prompt.owner = step_kind(step_id)
		prompt.actor_id = guard_actor
		prompt.cancellable = true
		match step_kind(step_id):
			RoleCatalog.DORFSCHMIED:  # Waffe jetzt einer anderen lebenden Person geben oder noch nicht
				prompt.allowed_ids.erase(guard_actor)
			RoleCatalog.SCHUTZGEIST:  # Pflichtwahl einer lebenden Person
				prompt.min_count = 1
			RoleCatalog.VERDAMMNISWAECHTER:  # Rudelopfer oder gezogenes Angebot
				var offered := [GuardRoles.pack_victim(s), GuardRoles.doom_offer(s, guard_actor)]
				offered.sort()
				prompt.allowed_ids.assign(offered)
				prompt.min_count = 1
			RoleCatalog.MAERTYRERIN:  # sich für das Rudelopfer opfern oder nicht
				prompt.allowed_ids = [GuardRoles.martyr_victim(s, guard_actor)] as Array[int]
	elif step_kind(step_id) == RoleCatalog.KARTENSCHLUCKER:
		SwallowerRules.open(s, prompt, step_actor(s.night_plan[s.next_night_step]))
	elif step_kind(step_id) == RoleCatalog.HENKER:
		prompt.owner = PendingPrompt.OWNER_HANGMAN
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.min_count = 1  # Karte: „nach 3 Hinrichtungen markiert er jede Nacht ein Ziel“, kein Verzicht
		prompt.cancellable = true
	elif step_kind(step_id) == RoleCatalog.ALBTRAUMWOLF or step_kind(step_id) == RoleCatalog.GIFTWOLF:
		# Albtraumwolf blockiert jede Nacht genau eine andere Person (kein Verzicht); Giftwolf vergiftet freiwillig.
		prompt.owner = PendingPrompt.OWNER_NIGHTMARE if step_kind(step_id) == RoleCatalog.ALBTRAUMWOLF else PendingPrompt.OWNER_POISON_WOLF
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.min_count = 1 if step_kind(step_id) == RoleCatalog.ALBTRAUMWOLF else 0
		prompt.cancellable = true
	elif step_kind(step_id) == RoleCatalog.PARASIT:
		# Parasit: freiwillig einen anderen lebenden Wirt wählen; 0 Ziele = bisherigen Wirt behalten.
		prompt.owner = PendingPrompt.OWNER_PARASITE
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.cancellable = true
	elif step_kind(step_id) == RoleCatalog.KORRUPTER_RICHTER:
		# Korrupter Richter: freiwillig eine lebende Person markieren (auch sich selbst) oder verzichten.
		prompt.owner = PendingPrompt.OWNER_JUDGE
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.cancellable = true
	elif step_kind(step_id) == RoleCatalog.WOLFSKIND:
		# Wolfskind: Pflichtwahl genau einer anderen lebenden Person als Vorbild (DR-10).
		prompt.owner = PendingPrompt.OWNER_WOLF_CHILD
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.min_count = 1
		prompt.cancellable = true
	elif s.night_plan[s.next_night_step] == PACK:
		# Rudelschritt: die Wölfe töten jede Nacht ein Opfer, kein „Kein Opfer“; einigen sie sich nicht, tippt
		# der Spielleiter das Opfer an. Jede lebende Person ist wählbar (rules-register §2).
		prompt.owner = PendingPrompt.OWNER_PACK
		prompt.actor_id = -1
		prompt.min_count = 1
		prompt.cancellable = true
		CardHooks.shape_pack_prompt(s, prompt)
	else:
		# Schutzengel: Pflichtauswahl genau einer anderen lebenden Person (DR-05).
		prompt.owner = PendingPrompt.OWNER_GUARD
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.min_count = 1
		prompt.cancellable = true
	s.pending_prompt = prompt
	ctx.emit(GameEvent.PROMPT_OPENED, Visibility.GM, {"prompt": prompt.to_dict()})


## Apfel (Rotkäppchen, R-02/R-03): Beginnt der erste Jede-Nacht-Schritt einer Person mit gültigem Apfel,
## wird derselbe Schritt direkt danach ein zweites Mal eingeplant; der Apfel ist damit verbraucht.
static func _apply_apple(ctx: RuleContext) -> void:
	var s := ctx.state
	var index := s.next_night_step
	var key := s.night_plan[index]
	var actor := step_actor(key)
	if actor == -1 or s.apple_steps.has(index) or int(s.apples.get(actor, 0)) != s.night_number or not RoleCatalog.APPLE_ROLES.has(step_role(key)):
		return
	if step_role(key) == RoleCatalog.PROPHET and not s.prophet_unlocked.has(actor):
		return  # das Markieren in Nacht 1 ist kein Jede-Nacht-Schritt
	s.apples.erase(actor)
	for i: int in s.apple_steps.size():
		if s.apple_steps[i] > index:
			s.apple_steps[i] += 1
	s.night_plan.insert(index + 1, key)
	s.night_step_status.insert(index + 1, STATUS_PENDING)
	s.apple_steps.append(index + 1)
	s.apple_steps.sort()
	ctx.emit(GameEvent.APPLE_USED, Visibility.GM, {"player_id": actor, "step": String(key), "night": s.night_number})


## Überspringt den (bereits validierten, überspringbaren) erwarteten Nachtschritt.
static func skip(ctx: RuleContext, step_id: String, reason: String) -> void:
	var s := ctx.state
	if s.pending_prompt != null and s.pending_prompt.step_id == step_id:
		s.pending_prompt = null
	if s.night_plan[s.next_night_step] == PACK:
		s.pack_target_id = GameState.NO_TARGET
	s.night_step_status[s.next_night_step] = STATUS_SKIPPED
	s.next_night_step += 1
	ctx.emit(GameEvent.STEP_SKIPPED, Visibility.GM, {"step_id": step_id, "reason": reason})


## Bricht den offenen Prompt ab. Der Schritt gilt danach als nicht begonnen;
## bereits bestätigte Zustandsänderungen bleiben unberührt.
static func cancel_prompt(ctx: RuleContext, reason: String) -> void:
	var s := ctx.state
	var prompt := s.pending_prompt
	s.pending_prompt = null
	CardSteps.on_cancel(s, prompt)  # eine Aufgabe der Spielleitung (z. B. durch eine Korrektur unterbrochen) geht nicht verloren
	ctx.emit(GameEvent.PROMPT_CANCELLED, Visibility.GM, {"prompt_id": prompt.id, "step_id": prompt.step_id, "reason": reason})
