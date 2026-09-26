class_name CanonicalJson
extends RefCounted
## Kanonische JSON-Darstellung: sortierte Schlüssel, ganzzahlige Zahlen ohne
## Nachkommastellen, StringName als String. Grundlage für Hashes, Replay-Vergleich
## und Spielstände. JSON liefert Zahlen als float zurück; `normalize` macht daraus
## wieder int, damit Hin- und Rückweg bytegleich sind.

const MAX_SAFE_INT := 9007199254740991  # 2^53 - 1, größte in JSON sicher darstellbare Ganzzahl


static func stringify(value: Variant) -> String:
	return JSON.stringify(normalize(value), "", true, false)


static func sha256(value: Variant) -> String:
	return "sha256:" + stringify(value).sha256_text()


static func normalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var f: float = value
			if is_finite(f) and f == floorf(f) and absf(f) <= float(MAX_SAFE_INT):
				return int(f)
			return f
		TYPE_STRING_NAME:
			return String(value)
		TYPE_DICTIONARY:
			var out := {}
			var src: Dictionary = value
			for key: Variant in src:
				out[String(key) if (key is String or key is StringName) else str(key)] = normalize(src[key])
			return out
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_STRING_ARRAY:
			var list: Array = []
			for item: Variant in value:
				list.append(normalize(item))
			return list
	return value
