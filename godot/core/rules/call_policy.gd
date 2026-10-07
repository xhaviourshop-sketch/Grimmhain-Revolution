class_name CallPolicy
extends RefCounted
## Aufrufpolitik der Nacht (DI-02, Antwort des Product Owners vom 29.09.2026). Reine Abfrage des
## Kernzustands, ohne Zustandsänderung und ohne Zufall. Sie trennt die Ansage („Rolle X erwacht“) von der
## tatsächlichen Fähigkeit: Tarnaufrufe lösen nie einen Schritt, eine Ziehung oder einen Verbrauch aus.
##
##   Runde ohne Wiederbelebung: aufgedeckte tote Rollen werden nicht mehr aufgerufen; jede Rolle, die noch
##     eine lebende Person hält (Startrolle oder aktuelle Rolle), wird aufgerufen, auch wenn ihre Fähigkeit
##     verbraucht, blockiert oder noch nicht aktiv ist.
##   Wiederbelebungsrunde: alle Rollen der Partie werden aufgerufen, auch die Rollen Toter, damit niemand
##     erfährt, wer lebt.
## Rollen ohne eigenen Nachtschritt (passive Rollen, Rudelmitglieder) bekommen keinen Aufruf; das Rudel und
## die Gruppen der Gebundenen und Ewigen sind eigene Schritte.
## Abgeleitet und noch zu bestätigen: Blockierte und noch nicht aktive Rollen werden ebenfalls aufgerufen;
## Rollen, die in der Partie nicht vorkommen, nicht.

const NO_LIMIT := 1000000


## Position einer Rolle in der Nachtreihenfolge (Nachtpriorität), -1 ohne eigenen Aufruf.
static func slot_priority(role_id: StringName) -> int:
	if role_id == RoleCatalog.DIE_GEBUNDENEN:
		return RoleCatalog.BOUND_PRIORITY
	if role_id == RoleCatalog.DIE_EWIGEN:
		return RoleCatalog.ETERNAL_PRIORITY
	if role_id == StepQueue.PIPER_ALL:
		return RoleCatalog.night_priority(RoleCatalog.RATTENFAENGER)  # PE-06: Platz des Rattenfängers, Tarnaufruf davor
	if not RoleCatalog.has_role(role_id):
		return -1
	var priority := RoleCatalog.night_priority(role_id)
	return priority if priority > 0 else -1


## Rollen, die in dieser Nacht aufgerufen werden (echte Schritte und Tarnaufrufe), nach Nachtposition und
## Rollen-ID sortiert.
static func called_roles(s: GameState) -> Array[StringName]:
	var set := {}
	for id: int in s.players:
		var p: Player = s.players[id]
		if not s.revival_round and not p.alive:
			continue
		for role: StringName in [p.role_id, p.original_role_id]:
			if slot_priority(role) >= 0:
				set[role] = true
	var out: Array[StringName] = []
	for role: Variant in set:
		out.append(StringName(role))
	out.sort_custom(func(a: StringName, b: StringName) -> bool:
		var pa := slot_priority(a)
		var pb := slot_priority(b)
		return pa < pb or (pa == pb and String(a) < String(b)))
	return out


## Rolle bzw. Gruppe eines Nachtplaneintrags; &"" für das Rudel.
static func entry_role(key: StringName) -> StringName:
	if key == StepQueue.PACK or key == StepQueue.PACK2:
		return &""
	if key == StepQueue.BOUND or key == StepQueue.ETERNAL or key == StepQueue.PIPER_ALL:
		return key
	return StepQueue.step_role(key)


static func entry_slot(key: StringName) -> int:
	if key == StepQueue.PACK or key == StepQueue.PACK2:
		return RoleCatalog.PACK_PRIORITY
	return slot_priority(entry_role(key))


## Tarnaufrufe, die vor dem aktuellen Schritt (bzw. vor dem Ende der Nacht) angesagt werden: aufzurufende
## Rollen zwischen dem zuletzt erledigten Schritt und dem nächsten echten Schritt, die selbst keinen offenen
## oder erledigten Schritt haben. Entfallene Schritte zählen als Tarnaufruf. Außerhalb der Nacht leer.
static func decoy_calls(s: GameState) -> Array[StringName]:
	var out: Array[StringName] = []
	if s.phase != Phase.NIGHT:
		return out
	var index := s.next_night_step
	var low := -1
	var covered := {}
	for j: int in s.night_plan.size():
		var role := entry_role(s.night_plan[j])
		if j >= index:
			covered[role] = true
		elif s.night_step_status[j] == StepQueue.STATUS_DONE:
			covered[role] = true
			low = entry_slot(s.night_plan[j])
	var high := entry_slot(s.night_plan[index]) if index < s.night_plan.size() else NO_LIMIT
	for role: StringName in called_roles(s):
		if covered.has(role):
			continue
		var slot := slot_priority(role)
		if slot > low and slot <= high:
			out.append(role)
	return out
