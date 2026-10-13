class_name ClassicRules
extends RefCounted
## Regelstellen nur des Akts Classic (DA-108), die vom Grundspiel abweichen. Das Grundspiel kennt sie nicht; die Aufrufe im Kern
## fragen vorher den Classic-Parameter der Rolle ab (`RoleCatalog.param`). Entfernt man den Akt, entfällt diese Datei mit den Aufrufen.


## Ritter mit dem verrosteten Schwert: Wird er in der Nacht vom Rudel gefressen, infiziert er den nächsten lebenden Werwolf links von
## ihm (Sitzreihenfolge im Uhrzeigersinn, Sitz statt Personen-ID) mit Tetanus. Dieser stirbt in der folgenden Nacht, nach den Rudelopfern.
## Einmal je Leben. Der Eintrag liegt wie die Giftpranke in `wolf_poisons`; die Quelle ist der Ritter (siehe `is_tetanus`).
static func rusty_infect(ctx: RuleContext, knight: Player) -> void:
	var s := ctx.state
	var use_key := "ritter:death_reaction"
	if int(knight.ability_uses.get(use_key, 0)) >= 1:
		return
	var left: int = Seats.nearest_wolves(s, knight.id)["cw"]
	if left == GameState.NO_TARGET:
		return
	knight.ability_uses[use_key] = 1
	s.wolf_poisons.append({"target_id": left, "source_id": knight.id, "due_night": s.night_number + 1})
	ctx.emit(GameEvent.TETANUS_INFECTED, Visibility.GM, {"knight_id": knight.id, "target_id": left, "due_night": s.night_number + 1})


## true, wenn der Eintrag aus `wolf_poisons` eine Tetanus-Infektion des Classic-Ritters ist (Quelle trägt die Classic-Rolle).
static func is_tetanus(s: GameState, entry: Dictionary) -> bool:
	var source: Player = s.players.get(int(entry["source_id"]))
	return source != null and bool(RoleCatalog.param(source.role_id, "rusty", false))


static func poison_cause(s: GameState, entry: Dictionary) -> StringName:
	return KillEvent.CAUSE_TETANUS if is_tetanus(s, entry) else KillEvent.CAUSE_WOLF_POISON
