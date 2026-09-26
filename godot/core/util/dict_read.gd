class_name DictRead
extends RefCounted
## Typsichere Lesezugriffe auf Dictionaries aus JSON oder Befehlsnutzdaten.
## Falsche Typen liefern den Ersatzwert statt eines Laufzeitfehlers.


static func is_int_like(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		var f: float = value
		return is_finite(f) and f == floorf(f)
	return false


static func get_int(d: Dictionary, key: String, fallback: int = 0) -> int:
	var v: Variant = d.get(key, fallback)
	return int(v) if is_int_like(v) else fallback


static func get_string(d: Dictionary, key: String, fallback: String = "") -> String:
	var v: Variant = d.get(key, fallback)
	return String(v) if (v is String or v is StringName) else fallback


static func get_bool(d: Dictionary, key: String, fallback: bool = false) -> bool:
	var v: Variant = d.get(key, fallback)
	return v if v is bool else fallback


static func get_dict(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key)
	return v if v is Dictionary else {}


static func get_array(d: Dictionary, key: String) -> Array:
	var v: Variant = d.get(key)
	return v if v is Array else []


## Liefert die Ganzzahlen eines Arrays oder null, wenn ein Element keine Ganzzahl ist.
static func to_int_array(values: Array) -> Variant:
	var out: Array[int] = []
	for v: Variant in values:
		if not is_int_like(v):
			return null
		out.append(int(v))
	return out
