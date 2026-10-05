extends SceneTree
## Prüft die Rollen-Vorschau für alle Rollen ohne Oberfläche: je Rolle Haltepunkte (Bildschirme) und Lücke. Schreibt mit --doc=<Datei>
## die Liste der Lücken (docs/audit/VORSCHAU-LUECKEN.md).
##   godot --headless --path godot -s res://tools/preview_audit.gd -- [--doc=<Datei>]

const REASONS := {
	"start": "Die Partie lässt sich mit dieser Rolle und den Füllrollen nicht starten.",
	"unreached": "Keine Bildschirme erreicht (Partie endet vorher).",
	"night": "Der Nachtschritt der Rolle kommt in %d Nächten mit Standardantworten nicht vor (Bedingung nicht erreicht)." % RolePreview.MAX_NIGHTS,
}


func _initialize() -> void:
	TranslationServer.set_locale("de")
	var doc := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--doc="):
			doc = a.trim_prefix("--doc=")
	var gaps: Array[String] = []
	var complete := 0
	for role: StringName in RolePresentation.sorted_roles():
		var plan := RolePreview.plan(String(role))
		var kinds: Array = (plan["stops"] as Array).map(func(st: Dictionary) -> String: return str(st["kind"]))
		var gap := str(plan["gap"])
		print("%-28s %-10s %s" % [role, gap if gap != "" else "ok", ",".join(kinds)])
		if gap == "":
			complete += 1
		else:
			gaps.append("| %s (`%s`) | %s | %s |" % [tr(RolePresentation.name_key(role)), role, REASONS.get(gap, gap), ", ".join(kinds) if not kinds.is_empty() else "keine"])
	print("vollstaendig %d von %d" % [complete, RolePresentation.sorted_roles().size()])
	if doc != "":
		var lines: Array[String] = ["# Rollen-Vorschau: Lücken", "",
			"Stand 05.10.2026, Branch `feat/feedback-6-7`. Erzeugt mit `godot/tools/preview_audit.gd`. Die Vorschau baut je Rolle eine Partie mit 10 Personen (Rolle auf Platz 1, zwei Wölfe, wirkungsarme Dorfrollen) und spielt mit Standardantworten bis zu %d Nächte. Hier stehen die Rollen, deren Bildschirme sich so nicht vollständig aufbauen lassen; sie sind in der Rollenliste markiert. Die Vorschau zeigt für sie die erreichten Bildschirme." % RolePreview.MAX_NIGHTS,
			"", "Vollständig: %d von %d Rollen." % [complete, RolePresentation.sorted_roles().size()], "",
			"| Rolle | Grund | Erreichte Bildschirme |", "|---|---|---|"]
		lines.append_array(gaps)
		lines.append("")
		var f := FileAccess.open(doc, FileAccess.WRITE)
		f.store_string("\n".join(lines))
		f.close()
	quit(0)
