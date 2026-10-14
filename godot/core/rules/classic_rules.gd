class_name ClassicRules
extends RefCounted
## Regelstellen nur des Akts Classic (DA-108), die vom Grundspiel abweichen. Das Grundspiel kennt sie nicht; die Aufrufe im Kern
## fragen vorher den Classic-Parameter der Rolle ab (`RoleCatalog.param`). Entfernt man den Akt, entfällt diese Datei mit den Aufrufen.


## Ritter mit dem verrosteten Schwert: Wird er in der Nacht vom Rudel gefressen, wählt die Spielleitung in der Morgenphase Links oder
## Rechts; der nächste lebende Wolf in dieser Richtung stirbt (Kreis läuft rund, Sitzreihenfolge im Uhrzeigersinn = links). Hier die
## wählbaren Wölfe: links (Uhrzeigersinn), rechts, ohne Doppelte; leer ohne lebenden Wolf. Die Tetanus-Infektion früherer Fassungen
## entsteht nicht mehr; geladene alte Stände mit Eintrag in `wolf_poisons` behalten die Wirkung (siehe `is_tetanus`).
static func rusty_choices(s: GameState, knight_id: int) -> Array[int]:
	var w := Seats.nearest_wolves(s, knight_id)
	var out: Array[int] = []
	for key: String in ["cw", "ccw"]:
		if int(w[key]) != GameState.NO_TARGET and not out.has(int(w[key])):
			out.append(int(w[key]))
	return out


## true, wenn der Eintrag aus `wolf_poisons` eine Tetanus-Infektion des Classic-Ritters ist (Quelle trägt die Classic-Rolle).
static func is_tetanus(s: GameState, entry: Dictionary) -> bool:
	var source: Player = s.players.get(int(entry["source_id"]))
	return source != null and bool(RoleCatalog.param(source.role_id, "rusty", false))


static func poison_cause(s: GameState, entry: Dictionary) -> StringName:
	return KillEvent.CAUSE_TETANUS if is_tetanus(s, entry) else KillEvent.CAUSE_WOLF_POISON
