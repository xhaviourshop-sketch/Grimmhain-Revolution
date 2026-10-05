class_name VoiceName
extends RefCounted
## Namen per Sprache erfassen (Web-Export): Web Speech API des Browsers über `JavaScriptBridge` (`webkitSpeechRecognition`, Sprache de-DE,
## bei englischer Oberfläche en-US). Ohne Unterstützung (Editor, Desktop, Browser ohne Spracherkennung) ist `supported()` falsch und die
## Oberfläche blendet das Mikrofon aus. Die Erkennung läuft im Browser; die App bekommt nur den erkannten Text. Tests können die
## Unterstützung überschreiben (`set_override`).

## Meldet das Ende einer Aufnahme: `name` ist der bereinigte Name (leer, wenn nichts erkannt wurde), `error` der Fehlercode des Browsers
## („not-allowed“ = Mikrofon verweigert, leer = kein Fehler).
signal finished(name: String, error: String)

const JS_SETUP := """
(function () {
	if (window.grimmhainVoice) { return; }
	var R = window.SpeechRecognition || window.webkitSpeechRecognition;
	window.grimmhainVoice = {
		supported: !!R,
		rec: null,
		start: function (lang, done) {
			var g = window.grimmhainVoice;
			if (g.rec) { try { g.rec.abort(); } catch (e) {} }
			var r = new R();
			var text = '', err = '';
			r.lang = lang; r.interimResults = false; r.maxAlternatives = 1; r.continuous = false;
			r.onresult = function (e) { if (e.results && e.results.length) { text = e.results[0][0].transcript; } };
			r.onerror = function (e) { err = e.error || 'error'; };
			r.onend = function () { if (g.rec === r) { g.rec = null; } done(text, err); };
			g.rec = r;
			try { r.start(); } catch (e) { g.rec = null; done('', 'start-failed'); }
		},
		stop: function () { var g = window.grimmhainVoice; if (g.rec) { try { g.rec.stop(); } catch (e) {} } }
	};
})();
"""

static var _override: int = -1  ## -1 = echt prüfen, 0 = nicht unterstützt, 1 = unterstützt (Tests, Screenshots)

var _callback: JavaScriptObject = null


static func set_override(value: int) -> void:
	_override = value


static func supported() -> bool:
	if _override != -1:
		return _override == 1
	if not OS.has_feature("web"):
		return false
	JavaScriptBridge.eval(JS_SETUP, true)
	return bool(JavaScriptBridge.eval("!!(window.grimmhainVoice && window.grimmhainVoice.supported)", true))


## Eine Aufnahme starten; das Ergebnis kommt über `finished`. Muss aus dem Antippen des Knopfs heraus aufgerufen werden (Browser verlangen eine Nutzergeste).
func start() -> void:
	if not OS.has_feature("web"):
		finished.emit("", "unsupported")
		return
	var voice := JavaScriptBridge.get_interface("grimmhainVoice")
	_callback = JavaScriptBridge.create_callback(_on_done)
	var lang := "en-US" if TranslationServer.get_locale().begins_with("en") else "de-DE"
	voice.call("start", lang, _callback)  # dynamischer Aufruf: JavaScriptObject kennt die Methoden der Seite nicht statisch


func stop() -> void:
	if OS.has_feature("web"):
		var voice := JavaScriptBridge.get_interface("grimmhainVoice")
		if voice != null:
			voice.call("stop")


func _on_done(args: Array) -> void:
	finished.emit(clean(str(args[0])), str(args[1]))


## Erkannten Text zum Namen bereinigen: Satzzeichen weg, Leerraum zusammengezogen, jedes Wort mit großem Anfangsbuchstaben.
## Buchstaben (auch mit Umlauten), Ziffern, Bindestrich und Apostroph bleiben; Wortgrenzen sind Leerzeichen.
static func clean(raw: String) -> String:
	var kept := ""
	for i: int in raw.length():
		var ch := raw.substr(i, 1)
		var code := raw.unicode_at(i)
		var is_letter := ch.to_lower() != ch.to_upper()
		var is_digit := code >= 48 and code <= 57
		if is_letter or is_digit or ch == "-" or ch == "'" or ch == "’":
			kept += ch
		else:
			kept += " " if ch.strip_edges().is_empty() or ch == "," or ch == "." or ch == ";" else ""
	var words: PackedStringArray = []
	for word: String in kept.split(" ", false):
		var trimmed := word.lstrip("-'’").rstrip("-'’")
		if not trimmed.is_empty():
			words.append(trimmed.substr(0, 1).to_upper() + trimmed.substr(1))
	return " ".join(words)
