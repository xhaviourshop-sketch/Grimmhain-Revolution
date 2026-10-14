class_name LineGroups
extends RefCounted
## Gleiche Wirkungen zusammenfassen: Mehrere Zeilen {key, values: {name}} mit demselben Schlüssel werden eine Zeile mit der Pluralvariante
## `<key>.many` und `{names}` („Anna, Ben sind verzaubert“). Nur wenn die Pluralvariante existiert und die Zeile sonst keine Werte trägt;
## die Reihenfolge der ersten Treffer bleibt. Ein einzelner Eintrag bleibt unverändert (Einzahl).


static func merge(lines: Array) -> Array:
	var out: Array = []
	var slots := {}
	for line: Dictionary in lines:
		var key := str(line.get("key", ""))
		var values: Dictionary = line.get("values", {})
		if key == "" or values.size() != 1 or not values.has("name") or not CockpitText.has_key(key + ".many"):
			out.append(line)
			continue
		if not slots.has(key):
			slots[key] = out.size()
			out.append({"key": key, "values": {"name": str(values["name"])}, "_names": [str(values["name"])]})
			continue
		((out[int(slots[key])] as Dictionary)["_names"] as Array).append(str(values["name"]))
	for i: int in out.size():
		var entry: Dictionary = out[i]
		if not entry.has("_names"):
			continue
		var names: Array = entry["_names"]
		if names.size() > 1:
			out[i] = {"key": str(entry["key"]) + ".many", "values": {"names": ", ".join(names)}}
		else:
			out[i] = {"key": str(entry["key"]), "values": {"name": str(names[0])}}
	return out
