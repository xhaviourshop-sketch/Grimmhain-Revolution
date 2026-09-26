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
static func determine_role(target: Player) -> StringName:
	if target.appears_as != &"" and target.appears_as != target.role_id:
		return target.appears_as
	if target.counts_as_wolf:
		return RoleCatalog.WERWOLF
	return target.role_id
