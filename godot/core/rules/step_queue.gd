class_name StepQueue
extends RefCounted
## Reihenfolge der Regelschritte (B-11): Nachtschritte nach Nachtplan und offene
## Reaktionen. Es gibt immer höchstens einen erwarteten nächsten Schritt.
##   Nacht:              nächster nicht erledigter Eintrag des Nachtplans
##   Morgenauflösung/Tag: erste offene Reaktion (Reaktionen aus der Nacht warten
##                        bis zur Morgenauflösung, DR-09)
## Schritt-IDs: "night:<Nacht>:<Index>:<Schritt>" bzw. "reaction:<Reaktions-ID>".
## Nachtschritte: persönliche Rollenschritte "<rolle>:<Personen-ID>" (nach Personen-ID)
## vor dem Rudelschritt "pack".

const PACK := &"pack"
const STATUS_PENDING := &"pending"
const STATUS_DONE := &"done"
const STATUS_SKIPPED := &"skipped"
const STEP_STATUSES: Array[StringName] = [STATUS_PENDING, STATUS_DONE, STATUS_SKIPPED]


static func personal_step_key(role_id: StringName, player_id: int) -> StringName:
	return StringName("%s:%d" % [role_id, player_id])


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
	RoleCatalog.SCHUTZENGEL: false,    # Pflichtauswahl (DR-05)
	KIND_REACTION: false,              # Pflichtreaktion, Verzicht ist eine Antwort (DR-09)
}


## Art eines Schritts aus seiner ID: "reaction", "pack" oder die Rolle eines persönlichen Schritts.
static func step_kind(step_id: String) -> StringName:
	if is_reaction_step(step_id):
		return KIND_REACTION
	var parts := step_id.split(":")
	return StringName(parts[3]) if parts.size() >= 4 and parts[0] == "night" else &""


static func is_skippable(step_id: String) -> bool:
	return SKIPPABLE_BY_KIND.get(step_kind(step_id), false)


## Nachtplan aus den zu Beginn der Nacht gültigen Rollen: persönliche Schritte lebender
## Schutzengel nach Personen-ID, danach der Rudelschritt, solange mindestens eine lebende
## Person als Wolf zählt (G-PH-6).
static func build_night_plan(s: GameState) -> Array[StringName]:
	var plan: Array[StringName] = []
	for id: int in s.alive_ids():
		if RoleCatalog.has_night_step(s.players[id].role_id):
			plan.append(personal_step_key(s.players[id].role_id, id))
	for id: int in s.alive_ids():
		if s.players[id].counts_as_wolf:
			plan.append(PACK)
			break
	return plan


## Beginnt den (bereits validierten) erwarteten Schritt und öffnet seinen Prompt.
static func begin(ctx: RuleContext, step_id: String) -> void:
	var s := ctx.state
	ctx.emit(GameEvent.STEP_BEGUN, Visibility.GM, {"step_id": step_id})
	var prompt := PendingPrompt.new()
	prompt.id = s.next_prompt_id
	s.next_prompt_id += 1
	prompt.kind = PendingPrompt.KIND_PICK_PLAYERS
	prompt.step_id = step_id
	prompt.min_count = 0
	prompt.max_count = 1
	prompt.allowed_ids = s.alive_ids()
	if is_reaction_step(step_id):
		# Pflichtreaktion: 0 Ziele = Verzicht (DR-09); nicht abbrechbar. Der Besitzer ist
		# nie Ziel seiner eigenen Reaktion, auch nicht nach einer Wiederbelebung.
		prompt.owner = PendingPrompt.OWNER_REACTION
		prompt.actor_id = s.reactions[0].owner_id
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.cancellable = false
	elif s.night_plan[s.next_night_step] == PACK:
		# Rudelschritt: 0 Ziele = ausdrücklich „kein Opfer“; jede lebende Person (rules-register §2).
		prompt.owner = PendingPrompt.OWNER_PACK
		prompt.actor_id = -1
		prompt.cancellable = true
	else:
		# Schutzengel: Pflichtauswahl genau einer anderen lebenden Person (DR-05).
		prompt.owner = PendingPrompt.OWNER_GUARD
		prompt.actor_id = step_actor(s.night_plan[s.next_night_step])
		prompt.allowed_ids.erase(prompt.actor_id)
		prompt.min_count = 1
		prompt.cancellable = true
	s.pending_prompt = prompt
	ctx.emit(GameEvent.PROMPT_OPENED, Visibility.GM, {"prompt": prompt.to_dict()})


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
	ctx.emit(GameEvent.PROMPT_CANCELLED, Visibility.GM, {"prompt_id": prompt.id, "step_id": prompt.step_id, "reason": reason})
