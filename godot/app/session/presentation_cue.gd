class_name PresentationCue
extends RefCounted
## Darstellungshinweise (kein Regelbestandteil, keine Spielwirkung): reine Auswertung eines Zustands. Bisher nur DI-09, der
## Hinweis bei fünf Toten. Er bezieht sich auf ein Erreichen von fünf Toten in einer öffentlichen Phase (Tag, Morgenauflösung
## oder Spielende; Tode der Nacht werden erst mit der Morgenauflösung öffentlich). Berechtigt ist ein Erreichen nur, wenn in
## genau diesem Zustand eine lebende Person die Rolle Selbstmörder hat (NQ-01; auch eine geerbte Rolle zählt, eine tote Person
## nicht). Ein nicht berechtigtes Erreichen verbraucht den Hinweis nicht (Entscheidung B); nach einer Auslösung gibt es keine
## weitere (GameSession führt das). Der Hinweis trägt weder Namen noch Rolle: Er enthält nur seine Kennung.

const FIVE_DEAD := &"five_dead"
const THRESHOLD := 5


static func dead_count(s: GameState) -> int:
	return s.players.size() - s.alive_ids().size()


## Erstmals mindestens fünf Tote in einer öffentlichen Phase (nicht Aufbau, nicht Nacht).
static func five_dead_reached(s: GameState) -> bool:
	return [Phase.DAWN_RESOLUTION, Phase.DAY, Phase.GAME_OVER].has(s.phase) and dead_count(s) >= THRESHOLD


## Eine lebende Person hat aktuell die Rolle Selbstmörder.
static func five_dead_eligible(s: GameState) -> bool:
	for id: int in s.alive_ids():
		if s.players[id].role_id == RoleCatalog.SELBSTMOERDER:
			return true
	return false


## Eine Person, die im neuen Zustand lebt und Selbstmörder ist, war es im Zustand davor nicht (Rollenübernahme oder Korrektur).
## Eine Wiederbelebung ohne Rollenwechsel zählt nicht.
static func death_seeker_gained(before: GameState, after: GameState) -> bool:
	for id: int in after.alive_ids():
		if after.players[id].role_id == RoleCatalog.SELBSTMOERDER and (not before.players.has(id) or before.players[id].role_id != RoleCatalog.SELBSTMOERDER):
			return true
	return false
