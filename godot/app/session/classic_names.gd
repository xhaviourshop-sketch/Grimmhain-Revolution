class_name ClassicNames
extends RefCounted
## Anzeigeschalter für Classic-Partien: Läuft eine Partie mit Classic-Rollen, zeigen Regelbuch und Totenreichkarten die Namen des
## Charakterbogens statt der Grundspiel-Namen. Reine Anzeige: Die Textvarianten stehen in den Übersetzungen unter `<Schlüssel>.classic`;
## fehlt eine, gilt der normale Text. Der Schalter folgt dem Zustand der Sitzung (GameSession) und verändert keinen Spielstand.

static var active: bool = false


## true, wenn mindestens eine Person eine Classic-Startrolle hat.
static func detect(s: GameState) -> bool:
	if not s.is_started():
		return false
	for p: Player in s.players.values():
		if RoleCatalog.is_classic(p.original_role_id):
			return true
	return false


## Schlüssel der Classic-Variante, wenn die Partie Classic ist und die Variante existiert, sonst der Schlüssel selbst.
static func key(base: String) -> String:
	if not active:
		return base
	var variant := base + ".classic"
	return variant if TranslationServer.translate(variant) != StringName(variant) else base
