class_name PerfMode
extends RefCounted
## Leicht-Modus für schwache Touch-Geräte (iPad/Safari): weniger Zierwerk, kleinere Renderfläche. Auf dem PC (Maus) bleibt alles wie es ist.
## An: Touch-Gerät, übersteuerbar mit `?leicht=1` / `?leicht=0` (Web) oder Umgebungsvariable `GRIMMHAIN_LEICHT` (Desktop). Die Renderauflösung
## begrenzt `web/shell.html` (Pixelverhältnis höchstens 1), weil die Engine sie beim Start liest.
## Zum Messen schaltet `?aus=fledermaus,leben,feuer,schatten,partikel` (Web) oder `GRIMMHAIN_AUS` einzelne Teile ab; nur zur Fehlersuche.

## Teile, die im Leicht-Modus aus sind (Messung 15.10., siehe PROGRESS.md).
## Kein Bildratenlimit: `Engine.max_fps` wartet im Web-Export aktiv (Hauptthread 100 % ausgelastet, gemessen), das Gerät würde nur heißer.
const LIGHT_OFF: Array[StringName] = [&"schatten"]  ## ganzflächige Shader-Durchgänge (Vignette, Nebel, Lichttönung, Kartenhintergrund)

static var _light: int = -1  ## -1 unbekannt, 0 aus, 1 an
static var _off: Array[StringName] = []
static var _off_read: bool = false


static func _query(key: String) -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('%s') || ''" % key, true))
	return OS.get_environment("GRIMMHAIN_" + key.to_upper())


static func light() -> bool:
	if _light < 0:
		if OS.has_feature("web"):  # entschieden von web/shell.html, damit Auflösung und Rest übereinstimmen
			_light = 1 if bool(JavaScriptBridge.eval("!!window.grimmhainLight", true)) else 0
		else:
			match _query("leicht"):
				"1":
					_light = 1
				"0":
					_light = 0
				_:
					_light = 1 if DisplayServer.is_touchscreen_available() else 0
	return _light == 1


## Ob dieser Zierwerk abgeschaltet ist (Leicht-Modus oder Messschalter `aus`).
static func off(part: StringName) -> bool:
	if not _off_read:
		_off_read = true
		for p: String in _query("aus").split(",", false):
			_off.append(StringName(p))
	return _off.has(part) or (light() and LIGHT_OFF.has(part))
