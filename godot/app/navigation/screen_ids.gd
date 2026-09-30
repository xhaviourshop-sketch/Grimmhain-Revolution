class_name ScreenIds
extends RefCounted
## Stabile IDs aller Ansichten, ihre Szenen und die Zurück-Beziehung (einzige Quelle).
## Zurück führt immer zur Elternansicht; der Start hat keine (dort: Beenden-Rückfrage).

const START := &"start"
const MAIN_MENU := &"main_menu"
const NEW_GAME := &"new_game"
const CONTINUE := &"continue"
const SETTINGS := &"settings"
const COCKPIT := &"cockpit"
const LEXICON := &"lexicon"
const RULEBOOK := &"rulebook"
const HISTORY := &"history"

const _SCENES := {
	START: "res://app/screens/start/start_screen.tscn",
	MAIN_MENU: "res://app/screens/main_menu/main_menu_screen.tscn",
	NEW_GAME: "res://app/screens/new_game/new_game_screen.tscn",
	CONTINUE: "res://app/screens/continue/continue_screen.tscn",
	SETTINGS: "res://app/screens/settings/settings_screen.tscn",
	COCKPIT: "res://app/screens/cockpit/cockpit_screen.tscn",
	LEXICON: "res://app/screens/lexicon/lexicon_screen.tscn",
	RULEBOOK: "res://app/screens/rulebook/rulebook_screen.tscn",
	HISTORY: "res://app/screens/history/history_screen.tscn",
}

const _PARENTS := {
	START: &"",
	MAIN_MENU: START,
	NEW_GAME: MAIN_MENU,
	CONTINUE: MAIN_MENU,
	SETTINGS: MAIN_MENU,
	COCKPIT: MAIN_MENU,
	LEXICON: MAIN_MENU,
	RULEBOOK: MAIN_MENU,
	HISTORY: MAIN_MENU,
}


static func all() -> Array[StringName]:
	return [START, MAIN_MENU, NEW_GAME, CONTINUE, SETTINGS, COCKPIT, LEXICON, RULEBOOK, HISTORY]


static func has(id: StringName) -> bool:
	return _SCENES.has(id)


## Szenenpfad oder "" für unbekannte IDs.
static func scene_path(id: StringName) -> String:
	return str(_SCENES.get(id, ""))


## Elternansicht für Zurück oder &"" (Wurzel oder unbekannt).
static func parent_of(id: StringName) -> StringName:
	return StringName(_PARENTS.get(id, &""))
