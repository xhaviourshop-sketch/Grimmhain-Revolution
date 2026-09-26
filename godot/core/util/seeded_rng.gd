class_name SeededRng
extends RefCounted
## Einzige Zufallsquelle des Regelkerns (Masterplan §4 Regel 4).
## Seed und interner Zustand werden als Dezimal-Strings gespeichert, weil JSON
## 64-Bit-Ganzzahlen nicht verlustfrei darstellt. `draws` zählt die Ziehposition.

var seed_value: int = 0
var draws: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(p_seed: int = 0) -> void:
	seed_value = p_seed
	_rng.seed = p_seed


func next_int(from: int, to: int) -> int:
	draws += 1
	return _rng.randi_range(from, to)


## Gibt eine gemischte Kopie zurück (Fisher-Yates); die Eingabe bleibt unverändert.
func shuffled(items: Array) -> Array:
	var out := items.duplicate()
	for i: int in range(out.size() - 1, 0, -1):
		var j := next_int(0, i)
		var tmp: Variant = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


func to_dict() -> Dictionary:
	return {"seed": str(seed_value), "state": str(_rng.state), "draws": draws}


static func from_dict(d: Dictionary) -> SeededRng:
	var seed_text := DictRead.get_string(d, "seed")
	var state_text := DictRead.get_string(d, "state")
	if not seed_text.is_valid_int() or not state_text.is_valid_int():
		return null
	var rng := SeededRng.new(seed_text.to_int())
	rng._rng.state = state_text.to_int()
	rng.draws = DictRead.get_int(d, "draws", -1)
	if rng.draws < 0:
		return null
	return rng
