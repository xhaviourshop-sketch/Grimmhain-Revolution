class_name InformationRules
extends RefCounted
## Einzige Regel für das Ergebnis von Informationsrollen (G-INF-1, DR-07, DR-08).
## Getrennte Werte: Wahrheit (`role_id`), ermittelt (diese Regel), gezeigt (ermittelt,
## solange der Spielleiter nicht übersteuert). Die Waldhexe nutzt dieses Modell nicht,
## sie erfährt nach einer Rettung immer die tatsächliche Rolle.


## Regelgemäß ermitteltes Ergebnis für eine geprüfte Person, in dieser Priorität:
##   1. besondere gespeicherte Erscheinung: `appears_as` weicht von `role_id` ab
##      (Katalog-Erscheinung einer Rolle oder Scheinrolle per Korrektur, später Trugbilderwolf)
##   2. `werwolf`, wenn die Person als Wolf zählt (Sonderwölfe erscheinen als Werwolf, DR-07)
##   3. sonst die tatsächliche Rolle
## `appears_as` wird beim Spielaufbau und bei `set_role` mit der Katalog-Erscheinung
## belegt, die derzeit für jede Rolle gleich der Rolle ist; dann greift Stufe 2 oder 3.
## Mit `seer` (die fragende Person): Hat ihre Rolle den Classic-Parameter `true_role` (Seherin: „wahre Identität“), zeigt die Auskunft
## die tatsächliche Rolle auch bei Wölfen und Sonderwölfen. Mit `s` gilt das auch für einen Grabräuber, der die Classic-Seherin gestohlen hat.
static func determine_role(target: Player, seer: Player = null, s: GameState = null) -> StringName:
	if target.cursed:
		return RoleCatalog.WERWOLF  # Fluch des Dämonischen Wolfs (V-02): nur Rollenauskünfte
	if seer != null and (RoleCatalog.param(seer.role_id, "true_role", false) or (s != null and _stole_true_role(s, seer))):
		return target.role_id
	if target.appears_as != &"" and target.appears_as != target.role_id:
		return target.appears_as
	if target.counts_as_wolf:
		return RoleCatalog.WERWOLF
	return target.role_id


## true, wenn die Person als Grabräuber eine Rolle mit `true_role` (Classic-Seherin) gestohlen hat.
static func _stole_true_role(s: GameState, seer: Player) -> bool:
	for theft: Dictionary in s.grave_thefts:
		if int(theft["robber_id"]) == seer.id:
			var victim: Player = s.players.get(int(theft["target_id"]))
			return victim != null and RoleCatalog.param(victim.role_id, "true_role", false)
	return false
