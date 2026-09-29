class_name RoleStep
extends VBoxContainer
## Wizard-Schritt 2 „Rollen“: Rollenpool für genau die bestätigte Personenzahl zusammenstellen.
## Linke Spalte: Zähler, freie bzw. zu viele Plätze, Fraktionszusammenfassung, Fehler,
## Vorschlag und Zurücksetzen. Rechts: scrollbare Rollenliste nach Fraktion gruppiert.
## Fußzeile: Zurück zu Spielern, Status, Rollen bestätigen. Alle Daten und Regeln kommen aus
## PlayerSetup (Validierung) und SetupRoleCatalog (Fraktion); die Zeilen werden einmal gebaut
## und bei Änderungen nur aktualisiert. Unter einer Rolle mit Pflicht-Scheinrolle liegt ihr
## geheimer Scheinrollen-Bereich (DecoySection); er schließt, sobald der Schritt verlassen wird.

signal dialog_requested(request: DialogRequest)
signal status_message_requested(text_key: String)
signal players_requested  ## „Zurück zu Spielern“

const ROW_SCENE := preload("res://app/screens/new_game/role_row.tscn")
const DECOY_SCENE := preload("res://app/screens/new_game/decoy_section.tscn")

var _setup: PlayerSetup = null
var _rows: Dictionary[StringName, RoleRow] = {}
var _decoy_sections: Array[DecoySection] = []
var _last_view: Dictionary = {}

@onready var _selection: GrimmLabel = %RoleSelectionCountLabel
@onready var _remaining: GrimmLabel = %RemainingLabel
@onready var _factions: GrimmLabel = %FactionSummaryLabel
@onready var _issues: GrimmLabel = %RoleIssuesLabel
@onready var _invalidated: GrimmLabel = %RoleInvalidatedLabel
@onready var _suggestion_state: GrimmLabel = %SuggestionStateLabel
@onready var _suggest: GrimmButton = %SuggestButton
@onready var _reset: GrimmButton = %ResetRolesButton
@onready var _revival: GrimmLabel = %RevivalRoundLabel  ## DI-01: aus der Rollenwahl abgeleitet, nur Anzeige
## PE-04: nicht blockierende Besetzungshinweise, je Hinweis eine eigene Zeile
@onready var _hint_labels: Dictionary[String, GrimmLabel] = {
	String(RolePoolDraft.HINT_COACH_SMALL_ROUND): %CoachHintLabel,
	String(RolePoolDraft.HINT_SIMULTANEOUS_SOLO_WINS): %SoloWinsHintLabel,
}
@onready var _scroll: ScrollContainer = %RoleScroll
@onready var _list: VBoxContainer = %RoleList
@onready var _back: GrimmButton = %BackToPlayersButton
@onready var _status: GrimmLabel = %RoleStatusLabel
@onready var _confirm: GrimmButton = %ConfirmRolesButton


## Wird vom Host einmal nach `_ready` aufgerufen.
func start(setup: PlayerSetup) -> void:
	_setup = setup
	(%RoleSideColumn as Control).custom_minimum_size.x = ThemeTokens.SETUP_SIDE_WIDTH
	_scroll.custom_minimum_size.y = ThemeTokens.ROLE_LIST_MIN_HEIGHT
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_build_rows()
	_suggest.pressed.connect(_on_suggest_pressed)
	_reset.pressed.connect(_on_reset_pressed)
	_back.pressed.connect(players_requested.emit)
	_confirm.pressed.connect(_on_confirm_pressed)
	_setup.changed.connect(_render)
	visibility_changed.connect(_on_visibility_changed)
	_render(_setup.view())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready() and not _last_view.is_empty():
		_render(_last_view)


func default_focus() -> Control:
	return _confirm if not _confirm.disabled else _suggest


func handle_back() -> bool:
	return false


## Gruppenüberschriften und Zeilen einmalig in Oberflächenreihenfolge.
func _build_rows() -> void:
	var current_faction := &""
	for role: StringName in RolePresentation.sorted_roles():
		var faction := SetupRoleCatalog.faction_of(role)
		if faction != current_faction:
			current_faction = faction
			var heading := GrimmLabel.new()
			heading.name = "FactionHeading_%s" % String(faction)
			heading.theme_type_variation = &"SectionLabel"
			heading.text_key = RolePresentation.faction_key(faction)
			_list.add_child(heading)
		var row := ROW_SCENE.instantiate() as RoleRow
		_list.add_child(row)
		row.show_role(role)
		row.change_requested.connect(_on_change_requested)
		_rows[role] = row
		if SetupRoleCatalog.requires_appearance(role):
			var section := DECOY_SCENE.instantiate() as DecoySection
			_list.add_child(section)
			section.start(_setup, role)
			section.dialog_requested.connect(dialog_requested.emit)
			_decoy_sections.append(section)


func _render(view: Dictionary) -> void:
	_revival.text_key = "ui.setup.roles.revival_round.on" if bool((view["roles"] as Dictionary).get("revival_round", false)) else "ui.setup.roles.revival_round.off"
	_last_view = view
	var roles: Dictionary = view["roles"]
	var hints: Array = roles.get("hints", [])
	for hint: String in _hint_labels:
		_hint_labels[hint].visible = hints.has(hint)
		_hint_labels[hint].text_key = "ui.setup.roles.hint.%s" % hint if hints.has(hint) else ""
	var counts: Dictionary = roles["counts"]
	for role: StringName in _rows:
		var key := String(role)
		_rows[role].show_count(int(counts[key]), bool(roles["can_decrease"][key]), bool(roles["can_increase"][key]))
	for section: DecoySection in _decoy_sections:
		section.render(roles)
	var persons := int(roles["persons"])
	var total := int(roles["total"])
	var free := int(roles["free"])
	_selection.format_values = {"count": total, "persons": persons}
	_selection.text_key = "ui.setup.roles.selected"
	if free > 0:
		_remaining.format_values = {"count": free}
		_remaining.text_key = "ui.setup.roles.free"
	elif free < 0:
		_remaining.format_values = {"count": -free}
		_remaining.text_key = "ui.setup.roles.too_many"
	else:
		_remaining.text_key = "ui.setup.roles.exact"
	_remaining.theme_type_variation = &"MutedLabel" if free == 0 else &"WarningLabel"
	var factions: Dictionary = roles["factions"]
	_factions.format_values = {"village": factions.get(String(Faction.VILLAGE), 0), "wolves": factions.get(String(Faction.WOLVES), 0), "solo": factions.get(String(Faction.SOLO), 0)}
	_factions.text_key = "ui.setup.roles.factions"
	_render_issues(roles)
	_suggestion_state.visible = bool(roles["is_suggestion"])
	_suggestion_state.text_key = "ui.setup.roles.is_suggestion" if bool(roles["is_suggestion"]) else ""
	_reset.disabled = bool(roles["is_empty"])
	_confirm.disabled = not bool(roles["can_confirm"])
	if bool(roles["confirmed"]):
		_status.text_key = "ui.setup.roles.status.confirmed"
	elif bool(roles["valid"]):
		_status.text_key = "ui.setup.roles.status.ready"
	else:
		_status.text_key = "ui.setup.roles.status.invalid"


## Fehlerliste (ohne die schon im Zähler sichtbaren Summenfehler) und Invalidierungsgrund.
func _render_issues(roles: Dictionary) -> void:
	var names: Array[String] = []
	for issue: Variant in roles["issues"]:
		if str(issue) != "too_few_roles" and str(issue) != "too_many_roles":
			names.append(tr("ui.setup.roles.issue.%s" % str(issue)))
	var show_issues := not names.is_empty() and not bool(roles["is_empty"])
	_issues.visible = show_issues
	_issues.format_values = {"issues": ", ".join(names)}
	_issues.text_key = "ui.setup.roles.issues" if show_issues else ""
	var reason := str(roles["invalidated"])
	_invalidated.visible = reason != "" and not bool(roles["confirmed"])
	_invalidated.text_key = "ui.setup.roles.invalidated.%s" % reason if _invalidated.visible else ""


## Minus auf einer Rolle, deren letzte Kopie schon eine Scheinrolle hat: erst nachfragen,
## welche Kopie samt Auswahl entfällt.
func _on_change_requested(role: StringName, delta: int) -> void:
	var result := _setup.change_role_count(role, delta)
	if result.ok or result.error != &"confirmation_required" or not result.details.has("copy_id"):
		return
	for section: DecoySection in _decoy_sections:
		if section.decoy_role == role:
			dialog_requested.emit(section.removal_request(int(result.details["copy_id"]), int(result.details["number"])))


## Beim Verlassen des Schritts schließen sich die geheimen Bereiche.
func _on_visibility_changed() -> void:
	if not visible:
		for section: DecoySection in _decoy_sections:
			section.close()


func _on_suggest_pressed() -> void:
	var result := _setup.apply_suggestion()
	if result.ok or result.error != &"confirmation_required":
		return
	var request := DialogRequest.create("ui.setup.dialog.suggest.title", "ui.setup.dialog.suggest.message", "ui.setup.dialog.suggest.confirm", _apply_suggestion_forced)
	request.message_values = {"count": _last_view["roles"]["total"], "persons": _last_view["roles"]["persons"]}
	dialog_requested.emit(request)


func _apply_suggestion_forced() -> void:
	_setup.apply_suggestion(true)
	_suggest.grab_focus()


func _on_reset_pressed() -> void:
	if _reset.disabled:
		return
	var request := DialogRequest.create("ui.setup.dialog.reset_roles.title", "ui.setup.dialog.reset_roles.message", "ui.setup.dialog.reset_roles.confirm", _reset_roles, true)
	dialog_requested.emit(request)


func _reset_roles() -> void:
	_setup.reset_roles()
	_suggest.grab_focus()


func _on_confirm_pressed() -> void:
	if _confirm.disabled:
		return
	var result := _setup.confirm_roles()
	if result.ok:
		status_message_requested.emit("ui.setup.roles.toast.confirmed")
