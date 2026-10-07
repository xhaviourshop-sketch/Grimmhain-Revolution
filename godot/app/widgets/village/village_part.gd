class_name VillagePart
extends Control
## Gemeinsame Grundlage der drei Dorf-Ebenen (Licht, Bewegung, Leben). `NightAmbience` setzt den Stand, die Ebene reagiert in `_refresh`.
## Rein kosmetisch: nichts im Spielstand, eigener Zufall, fängt keine Eingaben ab. Die Ebene liegt hinter allen Bedienflächen.

var map: VillageMap = null
var night: bool = false           ## Nachtphase (sonst Tag oder keine Partie)
var day: bool = false             ## Tagphase
var enabled: bool = true          ## Einstellung „Effekte“
var reduced: bool = false         ## Einstellung „Bewegung reduzieren“: nichts bewegt sich, Ebenen stehen still
var wolf: bool = false            ## Wolfsschritt läuft
var act_level: int = 1            ## Akt I bis IV der Partie
var dead_count: int = 0           ## Tote der Partie (für verlöschende Fenster)
var rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	rng.randomize()


## Stand übernommen; `animated` false heißt sofort (erste Anzeige, reduzierte Bewegung). Unterklassen überschreiben.
func _refresh(_animated: bool) -> void:
	pass


## Fläche oder Sitzplätze haben sich geändert: Positionen neu berechnen. Unterklassen überschreiben.
func _relayout() -> void:
	pass
