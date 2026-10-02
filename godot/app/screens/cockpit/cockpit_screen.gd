class_name CockpitScreen
extends BaseScreen
## Spielleiter-Cockpit (02 §4.1), spielbrettzentriert, als Nachtbrett (P3): Der Dorfplatz füllt das ganze Fenster, die Porträtplätze
## der laufenden Partie liegen auf einer Ellipse, in der freien Tischmitte steht die Aktionskarte (Rollenbild, Anweisung, Zielwahl;
## ihr Text scrollt, ihre Nebenaktionen stehen im festen Bereich, die Hauptaktion unten rechts als „Nächster Schritt“). Oben die
## Nachtreihenfolge-Leiste, links die Protokoll-Lasche, rechts die Optionen-Lasche (Werkzeuge, Timer), unten links Phase und
## Anzeige-Timer. Protokoll, privater Bereich, Lexikon, Korrekturen usw. öffnen als Ebene.
## Liest nur Sichten der Anwendungsschicht (GameSession.cockpit_view, board_marks, night_order) und sendet Befehle über deren
## Bausteine; eigene Zustände sind nur flüchtige Bedienzustände (Auswahl, aufgedeckte Karte, Verbergen, Menü).
##
## Geheimhaltung:
##   - Sitzkreis und Phasenanzeige zeigen nie Rollen. Zustandsabzeichen, Statusringe, handelnde Person, Nachtleiste und Rollenbild
##     der Karte sind für die Spielleitung gedacht und verschwinden mit „Verbergen“ (nur Namen, Porträts, tot oder lebendig).
##   - Geheime Karten (Schritte, Prompts, Siegkandidaten) erscheinen außerhalb der Nacht verdeckt
##     und erst nach „Anzeigen“; mit der nächsten Handlung sind sie wieder verdeckt.
##   - Rollen, Protokoll und die gezeigte Karte entstehen erst beim Öffnen als eigene Ebene und
##     werden beim Schließen, beim Sichtschutz und beim Verlassen der Ansicht entfernt.

const BAR_SIDE := 128.0         ## Abstand der Nachtleiste zum Fensterrand (Laschen und Eckinfo daneben)
const BAR_MAX_WIDTH := 840.0
const TOP_MARGIN := 6.0
const RING_SIDE := 58.0         ## Randabstand des Sitzkreises (Platz für Laschen)
const BOTTOM_MARGIN := 68.0     ## unter dem Sitzkreis liegt das Dock (Rückgängig, Nächster Schritt) und die Phasen-Kartusche
const DOCK_MARGIN := 8.0
const TAB_WIDTH := 52.0
const TAB_MAX_HEIGHT := 320.0
const WIDE_ASPECT := 1.5        ## ab diesem Seitenverhältnis (16:10) ist die Leiste voll sichtbar, darunter (4:3) eingeklappt
const MENU_WIDTH := 300.0
const PLATE_MARGIN := 12.0
const PLATE_TEXTURE_MARGIN := Vector2(18.0, 14.0)
const CORNER_WIDTH := 176.0
const PLATE_SIZE := Vector2(200.0, 52.0)
const PLAZA_CENTER_UV := Vector2(0.508, 0.508)  ## Mitte des Dorfplatzes im Hintergrundbild (Nachtszene v2)
const BACKDROP_OVERSCAN := 1.05                 ## etwas größer als „cover“, damit sich die Platzmitte auf die Ringmitte schieben lässt

var _view: Dictionary = {}
var _next_id: String = ""
var _selection: Array = []
var _random: Variant = null  ## Zufallsvorschlag (Personen) der offenen Spielleiterwahl; nur bis zur nächsten Änderung
var _revealed_id: String = ""
var _prediction := {"kind": "night", "number": 0}
var _error_key: String = ""
var _covered: bool = false
var _hidden: bool = false  ## „Verbergen“: nur Namen, Porträts, tot oder lebendig (nur Bedienzustand, nie gespeichert)
var _bar_expanded: bool = false  ## Nachtleiste auf 4:3 ausgeklappt (Überlagerung, nur Bedienzustand)
var _layer: Control = null
var _layer_kind: StringName = &""
var _morning_done_day: int = -1  ## Tag, dessen Morgenbericht die Spielleitung weitergeschaltet hat (nur Bedienzustand)
## Bedienzustand am Tag: "" | nominate_from | nominate_to | execute | execution_check | name_wolf
var _day_mode: String = ""
var _nominator: int = -1
var _necromancer: int = -1
var _card_effect: int = -1  ## Tagesregel einer Karte, für die ein Verstoß gemeldet wird (nur Bedienzustand)
var _preview: Dictionary = {}
var _exec_extra: Dictionary = {}
var _check_revealed: bool = false
var _gm_execute: bool = false  ## Prüfkarte gehört zu einer Hinrichtung ohne Nominierung (Korrektur)
## Geführte Korrektur: "" | kill | revive | set_role | execute | declare_winner
var _gm_mode: String = ""
var _gm_effects: Variant = null
var _gm_role: String = ""
var _role_card_person: int = -1  ## Person der offenen Rollenkarte (nur Bedienzustand, keine Rolle)
var _timer_labels: Dictionary = {}  ## Wertanzeigen der Timer-Dauern im Menü ("day", "night")

@onready var _layout: Control = %Layout
@onready var _badge: Control = %NoGameBadge
@onready var _phase_area: PanelContainer = %PhaseArea
@onready var _phase: GrimmLabel = %PhaseValueLabel
@onready var _round: GrimmLabel = %RoundLabel
@onready var _alive: GrimmLabel = %AliveLabel
@onready var _save_row: Control = %SaveRow  ## Speicherstand unten in der Mitte, zwischen Phase und Dock
@onready var _save_status: GrimmLabel = %SaveStatusLabel
@onready var _retry_save: GrimmButton = %RetrySaveButton  ## nur nach einem Speicherfehler; ein Versuch je Tippen
@onready var _warnings: GrimmLabel = %WarningsLabel
@onready var _ring: GameSeatRing = %SeatRing
@onready var _card: ActionCard = %ActionCard
@onready var _overlay_host: Control = %OverlayHost
@onready var _backdrop: Panel = %Backdrop
@onready var _backdrop_art: TextureRect = %BackdropArt  ## Dorfplatz bei Nacht (Fenster abgedunkelt), mit Fensterschein und Randdämpfung
@onready var _backdrop_fog: ColorRect = %BackdropFog  ## ziehender Nebel über dem Hintergrund, hinter allen Bedienflächen
@onready var _backdrop_shade: ColorRect = %BackdropShade
@onready var _order_bar: NightOrderBar = %OrderBar
@onready var _corner: Control = %CornerInfo
@onready var _status_strip: Control = %StatusStrip
@onready var _hidden_label: GrimmLabel = %HiddenLabel
@onready var _log_tab: NightTab = %LogButton
@onready var _options_tab: NightTab = %OptionsButton
@onready var _hide_button: GlyphButton = %HideButton
@onready var _cover_button: GlyphButton = %CoverButton
@onready var _timer_button: TimerButton = %TimerButton
@onready var _dock: Control = %ActionsArea
@onready var _dock_undo: GrimmButton = %DockUndoButton
@onready var _next_host: Control = %NextHost
@onready var _tools_menu: PanelContainer = %ToolsMenu
@onready var _menu_column: VBoxContainer = %MenuColumn

var _backdrop_phase: String = ""
var _backdrop_tween: Tween = null


func _setup() -> void:
	header.back_button().kind = GrimmButton.Kind.COMPACT  # schmale Kopfleiste: mehr Fläche für das Brett
	(header.find_child("TitleLabel", true, false) as Control).visible = false  # nur der Zurück-Knopf steht in der Ecke
	header.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_backdrop_art.texture = NightArt.texture("bg/scene-night-base.webp")
	_style_backdrop()
	_card.primary_host = _next_host
	_card.info_host = _make_info_corner()
	_next_host.child_entered_tree.connect(_skin_primary)
	_apply_handedness()
	context.settings.changed.connect(_on_settings_changed)
	context.session.view_changed.connect(_on_session_changed)
	context.session.command_rejected.connect(_on_rejected)
	context.session.state_replaced.connect(_on_state_replaced)
	context.saves.status_changed.connect(_on_save_status)
	context.timer.changed.connect(_refresh_timer)
	_retry_save.pressed.connect(context.autosave)
	_ring.seat_tapped.connect(_on_seat_tapped)
	_card.requested.connect(_on_card_requested)
	for tool: GrimmButton in [%PrivateButton, %RolesButton, %GmButton, %LexiconButton, %RulebookButton]:
		tool.custom_minimum_size.x = MENU_WIDTH - 2.0 * ThemeTokens.SPACE_S
	(%LogButton as GrimmButton).pressed.connect(open_layer.bind(&"log"))
	(%PrivateButton as GrimmButton).pressed.connect(open_layer.bind(&"private"))
	(%RolesButton as GrimmButton).pressed.connect(open_layer.bind(&"roles"))
	(%CoverButton as GrimmButton).pressed.connect(cover)
	(%GmButton as GrimmButton).pressed.connect(open_layer.bind(&"gm"))
	(%LexiconButton as GrimmButton).pressed.connect(open_lexicon.bind(&""))  # allgemeines Lexikon, auch ohne Partie
	(%RulebookButton as GrimmButton).pressed.connect(open_rulebook)  # allgemeines Regelbuch, auch ohne Partie
	_options_tab.pressed.connect(_toggle_menu)
	_hide_button.toggled.connect(_on_hide_toggled)
	_dock_undo.pressed.connect(_ask_undo)
	_timer_button.pressed.connect(_on_timer_pressed)
	_order_bar.expand_toggled.connect(_on_order_toggled)
	_build_menu_extras()
	_style_plate()
	_style_card()
	resized.connect(_arrange)
	_refresh()
	_arrange()


## Zurück: offene Ebene schließen, Sichtschutz aufheben oder (mit laufender Partie) nachfragen.
func handle_back() -> bool:
	if _tools_menu.visible:
		_tools_menu.visible = false
		return true
	if _layer != null:
		close_layer()
		return true
	if _covered:
		uncover()
		return true
	if bool(_view.get("has_game", false)):
		var r := DialogRequest.create("ui.cockpit.leave.title", "ui.cockpit.leave.message", "ui.cockpit.leave.confirm",
			func() -> void: navigate_requested.emit(ScreenIds.MAIN_MENU))
		dialog_requested.emit(r)
		return true
	return false


func default_focus() -> Control:
	var first := _card.action_buttons()  # in Bauart-Reihenfolge: Hauptaktion zuerst, unabhängig von der Bedienhand
	return first[0] as Control if not first.is_empty() else super.default_focus()


# --- Sicht -------------------------------------------------------------------------------------------

## Jede Zustandsänderung (angenommener Befehl, Laden, Korrektur) verwirft die Auswahl: Sie könnte
## sich auf einen veralteten Zustand beziehen, auch wenn derselbe Prompt offen bleibt.
func _on_session_changed(_v: Dictionary) -> void:
	_error_key = ""
	_selection.clear()
	_random = null
	_discard_role_card()
	_refresh()


## Rückgängig/Wiederholen ersetzt den Zustand: offene Tages- und Korrekturbedienung (Auswahl,
## Vorschau des alten Zustands) verfällt.
func _on_state_replaced() -> void:
	_reset_day_mode()
	_reset_gm_mode()
	_discard_role_card()
	_render()


func _refresh() -> void:
	_view = context.session.cockpit_view()
	var active := bool(_view.get("has_game", false))
	_badge.visible = not active
	for tool: String in ["LogButton", "PrivateButton", "RolesButton", "GmButton", "CoverButton", "HideButton"]:
		(find_child(tool, true, false) as BaseButton).disabled = not active
	var next: Dictionary = _view.get("next", {})
	var identity := _identity(next)
	if identity != _next_id:
		_next_id = identity
		_selection.clear()
		_random = null
		_revealed_id = ""
		_prediction = {"kind": "night", "number": 0}
	_update_status(active)
	_ring.show_seats(_view.get("seats", []))
	_ring.set_marks(context.session.board_marks() if active else {})
	_ring.set_secrets_visible(not _hidden)
	_update_order(active)
	_dock_undo.disabled = not (active and context.session.can_undo())
	_hidden_label.visible = active and _hidden
	_arrange()
	_render()


## Nachtreihenfolge: nur in der Nacht, nur für die Spielleitung (bei „Verbergen“ aus).
func _update_order(active: bool) -> void:
	var in_night := active and str(_view.get("phase", "")) == "NIGHT"
	var order: Array = context.session.night_order() if in_night else []
	_order_bar.show_order(order, _bar_is_full(), _bar_collapsible())
	_order_bar.visible = in_night and not _hidden and not order.is_empty()


func _bar_collapsible() -> bool:
	return size.y > 0.0 and size.x / size.y < WIDE_ASPECT


func _bar_is_full() -> bool:
	return not _bar_collapsible() or _bar_expanded


func _on_order_toggled(expanded: bool) -> void:
	_bar_expanded = expanded
	_update_order(bool(_view.get("has_game", false)))
	_arrange()


func _on_hide_toggled(on: bool) -> void:
	_hidden = on
	_refresh()


## Speicheranzeige: „gespeichert“ nur nach bestätigtem Schreiben, sonst deutlich als Fehler.
func _on_save_status(status: Dictionary) -> void:
	_show_save_status(status)
	if not bool(status.get("ok", false)):
		status_message_requested.emit("ui.cockpit.save.failed")


func _show_save_status(status: Dictionary) -> void:
	if status.is_empty() or str(status.get("round_id", "")) != context.session.round_id():
		_save_status.text_key = ""
		_retry_save.visible = false
		_arrange()
		return
	var ok := bool(status.get("ok", false))
	_retry_save.visible = not ok
	_save_status.theme_type_variation = &"CaptionLabel" if ok else &"ErrorCaptionLabel"
	_save_status.text_key = "ui.cockpit.save.ok" if ok else "ui.cockpit.save.error"
	_arrange()  # die Zeile wird mit dem Wiederholen-Knopf höher


## Anschlussstelle für spätere Hintergrundebenen je Tageszeit: Bild über der Grundfarbe.
func set_backdrop_art(texture: Texture2D) -> void:
	_backdrop_art.texture = texture


## Hintergrund je Tageszeit; kurzer Übergang, bei reduzierter Bewegung sofort. Ein neuer Wechsel
## bricht einen laufenden Übergang ab.
func _update_backdrop(phase: String) -> void:
	var group := "night" if phase == "NIGHT" else ("day" if phase in ["DAY", "DAWN_RESOLUTION"] else "")
	if group == _backdrop_phase:
		return
	_backdrop_phase = group
	_backdrop.theme_type_variation = &"NightBackdrop" if group == "night" else (&"DayBackdrop" if group == "day" else &"AppBackground")
	if _backdrop_tween != null and _backdrop_tween.is_valid():
		_backdrop_tween.kill()
	if context.settings.reduced_motion or not is_inside_tree():
		_backdrop.modulate.a = 1.0
		return
	_backdrop.modulate.a = 0.0
	_backdrop_tween = create_tween()
	_backdrop_tween.tween_property(_backdrop, "modulate:a", 1.0, ThemeTokens.BACKDROP_FADE_SECONDS)


## Abdunklung und Randdämpfung des Dorfplatzes als eigene Ebene (Abnahme 1): Das Bild bleibt unverändert, die Ebenen darüber dämpfen
## warme Reflexe auf dem Pflaster und die Ränder. Shader in `res://app/theme/`.
func _style_backdrop() -> void:
	var art := ShaderMaterial.new()
	art.shader = load("res://app/theme/night_backdrop.gdshader") as Shader
	art.set_shader_parameter("id_map", NightArt.texture("bg/scene-night-windows.png"))
	_backdrop_art.material = art
	var fog := ShaderMaterial.new()
	fog.shader = load("res://app/theme/night_fog.gdshader") as Shader
	_backdrop_fog.material = fog
	_apply_motion_setting()
	var shade := ShaderMaterial.new()
	shade.shader = load("res://app/theme/night_vignette.gdshader") as Shader
	_backdrop_shade.material = shade
	_backdrop_shade.color = ThemeTokens.TINT_NONE


func _update_status(active: bool) -> void:
	_update_backdrop(str(_view.get("phase", "")) if active else "")
	_show_save_status(context.saves.last_status if active else {})
	var phase := str(_view.get("phase", ""))
	_phase.text_key = "ui.phase.%s" % phase.to_lower() if active else "ui.phase.none"
	if active:
		context.timer.switch_group(DisplayTimer.group_of_phase(phase))
		var progress: Dictionary = _view.get("night_progress", {})
		if phase == "NIGHT":
			_round.format_values = {"number": int(_view["night_number"]), "done": int(progress.get("done", 0)), "total": int(progress.get("total", 0))}
			_round.text_key = "ui.cockpit.round.night"
		elif phase in ["DAY", "DAWN_RESOLUTION"]:
			_round.format_values = {"number": int(_view["day_number"]) if phase == "DAY" else int(_view["night_number"])}
			_round.text_key = "ui.cockpit.round.day" if phase == "DAY" else "ui.cockpit.round.dawn"
		else:
			_round.text_key = ""
		_alive.format_values = {"alive": int(_view["alive_count"]), "total": int(_view["player_count"])}
		_alive.text_key = "ui.cockpit.alive"
	else:
		_round.text_key = ""
		_alive.text_key = ""
	_refresh_timer()
	var warnings: Array = _view.get("warnings", [])
	_warnings.visible = not warnings.is_empty()
	if not warnings.is_empty():
		_warnings.format_values = (warnings[0] as Dictionary).get("values", {})
		_warnings.text_key = str((warnings[0] as Dictionary)["key"])


# --- Anordnung ------------------------------------------------------------------------------------------

## Höhe über dem Sitzkreis: in der Nacht Platz für die Nachtleiste (auf 4:3 für den Chip), sonst nur der schmale Streifen.
func _top_reserved() -> float:
	var night := str(_view.get("phase", "")) == "NIGHT"
	var chip_h := NightOrderBar.CHIP_SIZE.y
	if not night or _bar_collapsible():
		return TOP_MARGIN + chip_h + 4.0
	return TOP_MARGIN + NightOrderBar.FULL_HEIGHT + 4.0


## Setzt alle Bedienelemente des Bretts an ihren Platz: Leiste oben, Laschen und Randknöpfe seitlich, Phase und Dock unten in den
## Ecken (mit Linkshändermodus vertauscht), Sitzkreis in der restlichen Fläche. Läuft bei jeder Größen- und Zustandsänderung.
func _arrange() -> void:
	if not is_node_ready():
		return
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var left_handed := context.settings.left_handed
	var full := _bar_is_full()
	var bar_w := minf(w - 2.0 * BAR_SIDE, BAR_MAX_WIDTH) if full else NightOrderBar.CHIP_SIZE.x
	var bar_h := NightOrderBar.FULL_HEIGHT if full else NightOrderBar.CHIP_SIZE.y
	_order_bar.size = Vector2(bar_w, bar_h)
	_order_bar.position = Vector2((w - bar_w) * 0.5, TOP_MARGIN)
	var reserved := _top_reserved()
	_ring.position = Vector2(RING_SIDE, reserved)
	_ring.size = Vector2(maxf(w - 2.0 * RING_SIDE, 1.0), maxf(h - reserved - BOTTOM_MARGIN, 1.0))
	_corner.custom_minimum_size.x = CORNER_WIDTH
	_corner.size = _corner.get_combined_minimum_size()
	_corner.position = Vector2(TOP_MARGIN, TOP_MARGIN)
	_badge.size = _badge.get_combined_minimum_size()
	_badge.position = Vector2(w - _badge.size.x - TOP_MARGIN, TOP_MARGIN)
	_status_strip.size = Vector2(minf(w - 2.0 * BAR_SIDE, BAR_MAX_WIDTH), _status_strip.get_combined_minimum_size().y)
	_status_strip.position = Vector2((w - _status_strip.size.x) * 0.5, TOP_MARGIN + 16.0)  # dort, wo sonst die Nachtleiste steht
	var tab_h := minf(TAB_MAX_HEIGHT, h * 0.42)
	var tab_y := h * 0.5 + 20.0 - tab_h * 0.5
	_log_tab.size = Vector2(TAB_WIDTH, tab_h)
	_log_tab.position = Vector2(0.0, tab_y)
	_options_tab.size = Vector2(TAB_WIDTH, tab_h)
	_options_tab.position = Vector2(w - TAB_WIDTH, tab_y)
	var knob := Vector2(ThemeTokens.TOUCH_MIN, ThemeTokens.TOUCH_MIN)
	_hide_button.size = knob
	_hide_button.position = Vector2(w - knob.x - 2.0, tab_y + tab_h + 6.0)
	_cover_button.size = knob
	_cover_button.position = Vector2(w - knob.x - 2.0, tab_y + tab_h + 6.0 + knob.y + 4.0)
	_phase_area.custom_minimum_size = PLATE_SIZE
	_dock_undo.custom_minimum_size = GroveSkin.BUTTON_SIZE_SECONDARY
	_dock.size = _dock.get_combined_minimum_size()
	_phase_area.size = _phase_area.get_combined_minimum_size()
	var dock_x := DOCK_MARGIN if left_handed else w - DOCK_MARGIN - _dock.size.x
	var plate_x := w - DOCK_MARGIN - _phase_area.size.x if left_handed else DOCK_MARGIN
	_dock.position = Vector2(dock_x, h - DOCK_MARGIN - _dock.size.y)
	_phase_area.position = Vector2(plate_x, h - DOCK_MARGIN - _phase_area.size.y)
	var free_left := (_dock.position.x + _dock.size.x if left_handed else _phase_area.position.x + _phase_area.size.x) + PLATE_MARGIN
	var free_right := (_phase_area.position.x if left_handed else _dock.position.x) - PLATE_MARGIN
	_save_row.size = Vector2(maxf(free_right - free_left, 1.0), 0.0)
	var row_height := maxf(_save_row.get_combined_minimum_size().y, float(ThemeTokens.TOUCH_MIN) if _retry_save.visible else 0.0)  # Mindesthöhe aktualisiert sich erst im nächsten Bild
	_save_row.size = Vector2(_save_row.size.x, row_height)
	_save_row.position = Vector2(free_left, h - DOCK_MARGIN - _save_row.size.y)
	_tools_menu.size = _tools_menu.get_combined_minimum_size()
	_tools_menu.position = Vector2(w - TAB_WIDTH - _tools_menu.size.x - 4.0, clampf(tab_y, TOP_MARGIN, maxf(TOP_MARGIN, h - _tools_menu.size.y - TOP_MARGIN)))
	_place_backdrop_art(_ring.position + _ring.size * 0.5)


## Hintergrundbild füllt das Fenster ohne Verzerrung und ohne leere Ränder (cover mit kleiner Überdeckung); die Platzmitte liegt auf der
## Mitte des Spielerrings, soweit das Bild es zulässt.
func _place_backdrop_art(ring_center: Vector2) -> void:
	var texture := _backdrop_art.texture
	if texture == null:
		return
	var view := size
	var image := Vector2(texture.get_size())
	var scale := maxf(view.x / image.x, view.y / image.y) * BACKDROP_OVERSCAN
	var art_size := image * scale
	var wanted := ring_center - PLAZA_CENTER_UV * art_size
	_backdrop_art.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_backdrop_art.size = art_size
	_backdrop_art.position = Vector2(clampf(wanted.x, view.x - art_size.x, 0.0), clampf(wanted.y, view.y - art_size.y, 0.0))


## „i“-Ecke der Aktionskarte: eine Ebene über der Karte (PanelContainer legt alle Kinder übereinander), der Knopf oben rechts.
func _make_info_corner() -> Control:
	var corner := Control.new()
	corner.name = "InfoCorner"
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(%InstructionCard as Control).add_child(corner)
	return corner


## Aktionskarte im Hain-Rahmen (P5): dehnbarer Kartenrahmen statt der flachen Fläche; ohne Bild bleibt der Theme-Stil.
func _style_card() -> void:
	var box := GroveSkin.card_box()
	if box != null:
		(%InstructionCard as PanelContainer).add_theme_stylebox_override("panel", box)


## Phasen-Kartusche unten: kleiner Rahmen aus dem Leistenbild (Mockup V3), Innenabstand für Phase und Timer. Die Rahmenbilder sind
## in Anzeigegröße gebaut, weil 9-Slice-Ränder in Bildpunkten gezeichnet werden.
func _style_plate() -> void:
	var texture := NightArt.texture("ui/plate-frame.png")
	if texture != null:
		var box := StyleBoxTexture.new()
		box.texture = texture
		box.texture_margin_left = PLATE_TEXTURE_MARGIN.x
		box.texture_margin_right = PLATE_TEXTURE_MARGIN.x
		box.texture_margin_top = PLATE_TEXTURE_MARGIN.y
		box.texture_margin_bottom = PLATE_TEXTURE_MARGIN.y
		box.content_margin_left = PLATE_MARGIN + 2.0
		box.content_margin_right = PLATE_MARGIN
		box.content_margin_top = 4.0
		box.content_margin_bottom = 4.0
		_phase_area.add_theme_stylebox_override("panel", box)
	GroveSkin.skin_button(_dock_undo, false)


## Hauptaktion im Dock: ganzes Bild des roten Knopfs, Beschriftung und Zustand bleiben die des Buttons.
func _skin_primary(node: Node) -> void:
	var button := node as GrimmButton
	if button == null:
		return
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.wrap = false
	GroveSkin.skin_button(button, true)


# --- Optionen und Timer ------------------------------------------------------------------------------------

func _toggle_menu() -> void:
	if _tools_menu.visible:
		_tools_menu.visible = false
		return
	_arrange()
	_tools_menu.visible = true
	_arrange()


func _input(event: InputEvent) -> void:
	if not _tools_menu.visible:
		return
	var press := event as InputEventMouseButton
	if press != null and press.pressed and not _tools_menu.get_global_rect().has_point(press.global_position) \
			and not _options_tab.get_global_rect().has_point(press.global_position):
		_tools_menu.visible = false


## Timer-Abschnitt und Schalter im Optionenmenü; die Werkzeugknöpfe stehen schon in der Szene.
func _build_menu_extras() -> void:
	_menu_column.add_child(_section_label("ui.cockpit.menu.timer"))
	for group: String in ["day", "night"]:
		_menu_column.add_child(_timer_row(group))
	var reset := _menu_button("TimerResetButton", "ui.cockpit.menu.timer_reset")
	reset.pressed.connect(_on_timer_reset)
	_menu_column.add_child(reset)
	var night_toggle := GrimmToggle.new()
	night_toggle.name = "NightTimerToggle"
	night_toggle.text_key = "ui.cockpit.menu.night_timer"
	night_toggle.set_pressed_no_signal(context.settings.show_night_timer)
	night_toggle.toggled.connect(func(on: bool) -> void:
		context.settings.set_show_night_timer(on)
		_refresh_timer())
	_menu_column.add_child(night_toggle)
	var settings := _menu_button("SettingsButton", "ui.cockpit.menu.settings")
	settings.pressed.connect(func() -> void: navigate_requested.emit(ScreenIds.SETTINGS))
	_menu_column.add_child(settings)
	_refresh_timer()


func _section_label(key: String) -> GrimmLabel:
	var label := GrimmLabel.new()
	label.text_key = key
	label.theme_type_variation = &"CaptionLabel"
	return label


func _menu_button(node_name: String, key: String, width: float = 0.0) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.text_key = key
	b.kind = GrimmButton.Kind.COMPACT
	b.wrap = false
	b.custom_minimum_size.x = maxf(width, ThemeTokens.TOUCH_MIN) if width > 0.0 else MENU_WIDTH - 2.0 * ThemeTokens.SPACE_S
	return b


## Eine Dauerzeile: Name der Phasengruppe, Minus, Wert, Plus und +5 (Minuten).
func _timer_row(group: String) -> Control:
	var column := VBoxContainer.new()
	column.name = "Timer_%s" % group
	var title := GrimmLabel.new()
	title.text_key = "ui.cockpit.menu.timer_%s" % group
	title.theme_type_variation = &"MutedLabel"
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ThemeTokens.SPACE_XS)
	var minus := _menu_button("Timer%sMinusButton" % group.capitalize(), "ui.cockpit.menu.minus", float(ThemeTokens.TOUCH_MIN))
	minus.pressed.connect(_on_timer_adjust.bind(group, -DisplayTimer.STEP_SECONDS))
	row.add_child(minus)
	var value := GrimmLabel.new()
	value.name = "Timer%sValueLabel" % group.capitalize()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.wrap = false
	_timer_labels[group] = value
	row.add_child(value)
	var plus := _menu_button("Timer%sPlusButton" % group.capitalize(), "ui.cockpit.menu.plus", float(ThemeTokens.TOUCH_MIN))
	plus.pressed.connect(_on_timer_adjust.bind(group, DisplayTimer.STEP_SECONDS))
	row.add_child(plus)
	var plus5 := _menu_button("Timer%sPlusFiveButton" % group.capitalize(), "ui.cockpit.menu.plus_five", float(ThemeTokens.TOUCH_MIN))
	plus5.pressed.connect(_on_timer_adjust.bind(group, 5 * DisplayTimer.STEP_SECONDS))
	row.add_child(plus5)
	column.add_child(row)
	return column


func _on_timer_adjust(group: String, delta_seconds: int) -> void:
	context.timer.adjust_duration(StringName(group), delta_seconds)
	context.autosave()


func _on_timer_reset() -> void:
	context.timer.reset()
	context.autosave()


## Tippen auf die Anzeige: mit eingestellter Dauer starten oder pausieren, sonst das Menü mit den Einstellungen öffnen.
func _on_timer_pressed() -> void:
	if context.timer.is_set():
		context.timer.toggle()
		context.autosave()
	elif not _tools_menu.visible:
		_toggle_menu()


## Anzeige und Menüwerte nachführen. Die Anzeige erscheint nur mit laufender Partie in Tag oder Nacht (Nacht abschaltbar).
func _refresh_timer() -> void:
	if not is_node_ready():
		return
	var t := context.timer
	var active := bool(_view.get("has_game", false)) and t.group != &""
	_timer_button.visible = active and (t.group != DisplayTimer.GROUP_NIGHT or context.settings.show_night_timer)
	_timer_button.show_time(t.remaining, t.running, t.is_set(), t.is_expired())
	_timer_button.tooltip_text = tr("ui.cockpit.timer.tooltip_pause") if t.running else tr("ui.cockpit.timer.tooltip_start")
	for group: String in _timer_labels:
		var label := _timer_labels[group] as GrimmLabel
		var seconds := int(t.durations.get(group, 0))
		if seconds > 0:
			label.format_values = {"time": DisplayTimer.format_seconds(float(seconds))}
			label.text_key = "ui.cockpit.menu.timer_value"
		else:
			label.format_values = {}
			label.text_key = "ui.cockpit.menu.timer_off"


## Der Timer läuft mit der Anzeige: je Frame vergeht die Frame-Zeit. Reine Anzeige, kein Befehl.
func _process(delta: float) -> void:
	if context != null and context.timer.running:
		context.timer.tick(delta)
		_timer_button.show_time(context.timer.remaining, context.timer.running, context.timer.is_set(), context.timer.is_expired())


func _render() -> void:
	var next: Dictionary = _view.get("next", {})
	var phase := str(_view.get("phase", ""))
	var visible_secret := not bool(next.get("secret", false)) or phase == "NIGHT" or _revealed_id == _next_id
	if not bool(_view.get("has_game", false)):
		_card.render({"kind": "no_game"}, {})
		_ring.clear_marking()
		_card.role_art().show_role("")
		return
	var kind := str(next.get("kind"))
	if _gm_mode != "":
		next = {"kind": "gm", "secret": false}
		kind = "gm"
		_mark_gm_mode()
	elif (kind == "day" or kind == "card_window") and _morning_pending():
		next = {"kind": "morning", "secret": false, "public": context.session.morning_report().get("public", {}),
			"night_number": int(_view.get("night_number", 0))}
		kind = "morning"
	if kind == "gm":
		pass
	elif kind == "day" and _day_mode != "":
		_mark_day_mode(next)
	elif kind == "prompt" and str(next.get("answer")) == "targets" and visible_secret:
		_ring.set_marking(true, next.get("allowed_ids", []), _selection, next.get("actor_ids", []))
	elif (kind == "prompt" or kind == "begin_step") and visible_secret:
		_ring.set_marking(false, [], [], next.get("actor_ids", []))
	else:
		_ring.clear_marking()
	# Ob die Auswahl bestätigt werden kann, entscheidet der Regelkern (Prüfung ohne Senden).
	var selection_error := ""
	if kind == "prompt" and str(next.get("answer")) == "targets" and not _selection.is_empty():
		selection_error = String(context.session.check_targets(_selection))
	_card.role_art().show_role(_card_role(next, kind, phase, visible_secret))
	_card.render(next, {
		"phase": phase, "seats": _view.get("seats", []), "selection": _selection, "selection_error": selection_error,
		"random_active": _random != null and _same_set(_selection, _random),
		"random_available": bool(next.get("random", false)) and context.session.random_proposal() != null,
		"revealed": _check_revealed if _day_mode == "execution_check" else _revealed_id == _next_id,
		"night_number": int(_view.get("night_number", 0)), "prediction_kind": _prediction["kind"],
		"prediction_number": _prediction["number"], "error_key": _error_key,
		"gm_mode": _gm_mode, "gm_effects": _gm_effects, "gm_role": _gm_role,
		"status_fields": context.session.status_fields(int(_selection[0])) if _gm_mode == "status" and not _selection.is_empty() else [],
		"day_number": int(_view.get("day_number", 0)), "day_mode": _day_mode, "nominator": _nominator,
		"preview": _preview, "exec_extra": _exec_extra, "day_deaths": context.session.day_deaths() if bool(_view.get("has_game")) else [],
		"day_effects": context.session.day_effects() if bool(_view.get("has_game")) else [],
		"day_cards": context.session.day_cards() if bool(_view.get("has_game")) else [],
		"reduced_motion": context.settings.reduced_motion,
	})
	_arrange()  # die Hauptaktion im Dock wechselt mit der Karte: Dock und Phasenplatte neu setzen
	_restore_focus()


## Rolle für das Rollenbild der Karte: nur in der Nacht, bei einer Rollenhandlung, solange nicht verborgen und die Karte sichtbar ist.
## Nie bei der anonymen Frage (DI-05) und nie bei Karten der Totenreichkarten.
func _card_role(next: Dictionary, kind: String, phase: String, visible_secret: bool) -> String:
	if _hidden or not visible_secret or phase != "NIGHT" or _gm_mode != "":
		return ""
	if kind != "begin_step" and kind != "prompt":
		return ""
	if str(next.get("owner", "")) == "card" or bool(next.get("anonymous_asker", false)):
		return ""
	return str(next.get("role_id", ""))


## Ringmarkierung im Tagesmodus: wer im aktuellen Schritt antippbar ist (nur Lebende, bei der
## Hinrichtung nur heute Nominierte). Die Regelprüfung selbst bleibt beim Regelkern.
func _mark_day_mode(next: Dictionary) -> void:
	var alive: Array = (_view.get("seats", []) as Array).filter(func(s: Dictionary) -> bool: return bool(s["alive"])).map(func(s: Dictionary) -> int: return int(s["person_id"]))
	match _day_mode:
		"nominate_from":
			_ring.set_marking(true, next.get("nominator_ids", alive), [], [])
		"nominate_to":
			_ring.set_marking(true, alive.filter(func(id: int) -> bool: return id != _nominator), _selection, [_nominator])
		"execute":
			_ring.set_marking(true, next.get("execution_candidates", []), _selection, [])
		"name_wolf":
			_ring.set_marking(true, alive.filter(func(id: int) -> bool: return id != _necromancer), _selection, [])
		"card_report":
			_ring.set_marking(true, alive, _selection, [])
		"execution_check":
			# Kettenreaktion: die Person mit den zweitmeisten Stimmen wird am Sitzkreis gewählt.
			if bool(_preview.get("card_runner_up", false)) and not _exec_extra.has("runner_up_id"):
				_ring.set_marking(true, alive.filter(func(id: int) -> bool: return id != int(_preview.get("target_id", -1))), _selection, [])
			else:
				_ring.set_marking(false, [], [], [])


func _mark_gm_mode() -> void:
	var ids: Array = []
	for seat: Dictionary in _view.get("seats", []):
		if bool(seat["alive"]) != (_gm_mode == "revive"):
			ids.append(int(seat["person_id"]))
	_ring.set_marking(_gm_mode != "declare_winner", ids, _selection, [])


func _reset_gm_mode() -> void:
	_gm_mode = ""
	_gm_effects = null
	_gm_role = ""
	_gm_execute = false


func _reset_day_mode() -> void:
	_day_mode = ""
	_nominator = -1
	_necromancer = -1
	_preview = {}
	_exec_extra = {}
	_card_effect = -1
	_check_revealed = false
	_selection.clear()


## Nach einer Handlung ist der Button unter dem Fokus ersetzt: Fokus auf die erste Aktion der neuen
## Karte (Tastatur, Controller), solange kein Dialog und keine Ebene offen ist.
func _restore_focus() -> void:
	_apply_focus.call_deferred()


func _apply_focus() -> void:
	if _layer != null or not is_inside_tree():
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and owner.is_visible_in_tree() and not owner.is_queued_for_deletion() and owner != header.back_button():
		return
	var target := default_focus()
	if target != null and target.is_inside_tree() and target.is_visible_in_tree():
		target.grab_focus()


## Der Morgenbericht steht vor den Tagesaktionen, bis die Spielleitung weiterschaltet oder am Tag
## schon etwas geschehen ist (Nominierung, Entscheidung).
func _morning_pending() -> bool:
	var day := int(_view.get("day_number", 0))
	return _morning_done_day != day and str(_view.get("day_step", "")) == "DISCUSSION" 		and (_view.get("next", {}).get("nominations", []) as Array).is_empty() and not context.session.morning_report().is_empty()


## Kennung der nächsten Handlung: wechselt sie, verfallen Auswahl und Aufdecken.
func _identity(next: Dictionary) -> String:
	match str(next.get("kind")):
		"prompt":
			return "prompt:%d:%s" % [int(next.get("prompt_id", 0)), str(next.get("stage"))]
		"begin_step":
			return "step:%s" % str(next.get("step_id"))
		"notice":
			return "notice:%d" % int(next.get("notice_id", 0))
		"win_decision":
			return "win:%s" % str((next.get("candidates", []) as Array).map(func(c: Dictionary) -> int: return int(c["id"])))
		"card_window":
			return "card:%d:%d" % [int(next.get("owner_id", -1)), int((next.get("card", {}) as Dictionary).get("record_id", -1))]
	return str(next.get("kind"))


## Bedienhand (NQ-04): Der Sitzkreis wird nie gespiegelt (Sitzfolge und Nachbarn bleiben). Nur die Hauptaktion im festen
## Aktionsbereich der Ansagekarte wechselt das Ende (rechts bzw. links). Buttons werden umgereiht, nicht neu erzeugt:
## Auswahl, offene Karte und Signalverbindungen bleiben unberührt.
func _apply_handedness() -> void:
	_card.set_left_handed(context.settings.left_handed)
	_arrange()


func _on_settings_changed(key: StringName) -> void:
	if key == &"left_handed":
		_apply_handedness()
	elif key == &"show_night_timer":
		_refresh_timer()
	elif key == &"reduced_motion":
		_apply_motion_setting()


## Fensterschein und Nebel stehen still, wenn reduzierte Bewegung eingestellt ist.
func _apply_motion_setting() -> void:
	var animate := 0.0 if context.settings.reduced_motion else 1.0
	(_backdrop_art.material as ShaderMaterial).set_shader_parameter("animate", animate)
	(_backdrop_fog.material as ShaderMaterial).set_shader_parameter("animate", animate)


# --- Bedienung --------------------------------------------------------------------------------------

func _same_set(a: Array, b: Variant) -> bool:
	if not b is Array or a.size() != (b as Array).size():
		return false
	return a.all(func(x: Variant) -> bool: return (b as Array).has(x))


func _on_seat_tapped(person_id: int) -> void:
	var next: Dictionary = _view.get("next", {})
	if _gm_mode != "" and _gm_mode != "declare_winner":
		_selection = [] if _selection.has(person_id) else [person_id]
		_render()
		return
	if str(next.get("kind")) == "day" and _day_mode != "":
		match _day_mode:
			"nominate_from":
				_nominator = person_id
				_day_mode = "nominate_to"
				_selection.clear()
			"nominate_to", "execute", "name_wolf", "card_report":
				_selection = [] if _selection.has(person_id) else [person_id]
			"execution_check":
				if bool(_preview.get("card_runner_up", false)) and not _exec_extra.has("runner_up_id"):
					_selection = [] if _selection.has(person_id) else [person_id]
		_render()
		return
	if str(next.get("kind")) != "prompt" or str(next.get("answer")) != "targets":
		return
	var high := int(next.get("max", 0))
	if _selection.has(person_id):
		_selection.erase(person_id)
	elif high == 1:
		_selection = [person_id]
	elif _selection.size() < high:
		_selection.append(person_id)
	else:
		status_message_requested.emit("ui.cockpit.status.selection_full")
		return
	_random = null  # manuelle Änderung: ab jetzt eine Spielleiterwahl, keine Zufallsziehung
	_render()


func _on_card_requested(action: StringName, payload: Dictionary) -> void:
	var s := context.session
	match action:
		&"help":
			open_lexicon(StringName(str(payload.get("role_id", ""))))
		&"cycle_target":
			_cycle_target(int(payload["direction"]))
		&"open_report":
			context.history_focus = s.round_id()  # Abschlussbericht der beendeten Partie in der Historienansicht öffnen
			navigate_requested.emit(ScreenIds.HISTORY)
		&"reveal":
			if _day_mode == "execution_check":
				_check_revealed = true
			else:
				_revealed_id = _next_id
			_render()
		&"start_nominate":
			_reset_day_mode()
			_day_mode = "nominate_from"
			_render()
		&"start_execute":
			_reset_day_mode()
			_day_mode = "execute"
			_render()
		&"cancel_mode":
			_reset_day_mode()
			_reset_gm_mode()
			_render()
		&"gm_effects":
			_gm_effects = bool(payload["value"])
			_render()
		&"gm_choose_role":
			_ask_gm_role()
		&"gm_winner":
			_ask_correction({"kind": "declare_winner", "winner_kind": str(payload["kind"])})
		&"gm_confirm":
			_confirm_gm_mode()
		&"gm_field":
			_ask_status_field(int(payload["index"]))
		&"confirm_nomination":
			var nominee := int(_selection[0])
			var from := _nominator
			_reset_day_mode()
			_submit(s.nominate.bind(from, nominee))
		&"check_execution":
			var target := int(_selection[0])
			_reset_day_mode()
			_preview = s.execution_preview(target)
			_day_mode = "execution_check"
			_render()
		&"exec_extra":
			_exec_extra[str(payload["field"])] = payload["value"]
			_render()
		&"exec_runner_up":
			_exec_extra["runner_up_id"] = int(payload["id"])
			_selection.clear()
			_render()
		&"roll":
			_submit(s.answer_roll)
		&"card_play":
			_submit(s.card_act.bind(int(payload["owner_id"]), "play"))
		&"card_keep":
			_submit(s.card_act.bind(int(payload["owner_id"]), "keep"))
		&"card_exchange":
			var owner_id := int(payload["owner_id"])
			dialog_requested.emit(DialogRequest.create("ui.cards.dialog.exchange.title", "ui.cards.dialog.exchange.message", "ui.cards.dialog.exchange.confirm",
				func() -> void: _submit(s.card_act.bind(owner_id, "exchange")), true))
		&"card_close":
			dialog_requested.emit(DialogRequest.create("ui.cards.dialog.close.title", "ui.cards.dialog.close.message", "ui.cards.dialog.close.confirm",
				func() -> void: _submit(s.card_close_window)))
		&"card_show":
			open_layer(&"card")
		&"card_overview":
			open_layer(&"cards")
		&"card_report":
			_reset_day_mode()
			_card_effect = int(payload["effect_id"])
			_day_mode = "card_report"
			_render()
		&"confirm_card_report":
			var effect_id := _card_effect
			var person_id := int(_selection[0])
			_reset_day_mode()
			_submit(s.card_table_action.bind(effect_id, person_id))
		&"confirm_execution" when _gm_execute:
			var payload_gm := {"kind": "execute", "target_id": int(_preview.get("target_id", -1))}
			payload_gm.merge(_exec_extra)
			_reset_day_mode()
			_reset_gm_mode()
			_ask_correction(payload_gm)
		&"confirm_execution" when bool(_preview.get("card_reveal", false)) and not bool(_preview.get("card_revealed", false)):
			# Wachsame Augen: erst wird die Rolle öffentlich enthüllt, danach entscheidet das Dorf. Der Tag bleibt dabei offen.
			var reveal_target := int(_preview.get("target_id", -1))
			_submit(s.decide_execution.bind(reveal_target, {"card_reveal": true}))
			_preview = s.execution_preview(reveal_target)
			_exec_extra = {}
			_render()
		&"confirm_execution":
			var target := int(_preview.get("target_id", -1))
			var extra := _exec_extra.duplicate()
			var r := DialogRequest.create("ui.cockpit.dialog.execute.title", "ui.cockpit.dialog.execute.message", "ui.cockpit.dialog.execute.confirm",
				func() -> void:
					_reset_day_mode()
					_submit(s.decide_execution.bind(target, extra)), true)
			r.message_values = {"name": CockpitText.names_of([target], _view.get("seats", []))}
			dialog_requested.emit(r)
		&"no_execution":
			dialog_requested.emit(DialogRequest.create("ui.cockpit.dialog.no_execution.title", "ui.cockpit.dialog.no_execution.message",
				"ui.cockpit.dialog.no_execution.confirm", func() -> void:
					_reset_day_mode()
					_submit(s.decide_execution.bind(-1))))
		&"confirm_name_wolf":
			var necro := _necromancer
			var named := int(_selection[0])
			_reset_day_mode()
			_submit(s.name_wolf.bind(necro, named))
			status_message_requested.emit("ui.cockpit.status.saved_secretly")
		&"end_day":
			_submit(s.end_day)
		&"start_night":
			_submit(s.start_night)
		&"begin_step":
			_submit(s.begin_next_step)
		&"show_notice":
			open_layer(&"notice")
		&"show_roles":
			open_layer(&"roles")
		&"ack_notice":
			close_layer()
			_submit(s.ack_notice.bind(int(payload["notice_id"])))
		&"skip_step":
			_ask_reason("ui.cockpit.dialog.skip.title", "ui.cockpit.dialog.skip.message", "ui.cockpit.dialog.skip.confirm",
				func(reason: String) -> void: _submit(s.skip_next_step.bind(reason)))
		&"cancel_prompt":
			_ask_reason("ui.cockpit.dialog.cancel.title", "ui.cockpit.dialog.cancel.message", "ui.cockpit.dialog.cancel.confirm",
				func(reason: String) -> void: _submit(s.cancel_prompt.bind(reason)))
		&"confirm_targets":
			if _random != null and _same_set(_selection, _random):
				_submit(s.answer_random.bind((_random as Array).duplicate()))
			else:
				_submit(s.answer_targets.bind(_selection.duplicate()))
		&"random_targets":
			_random = s.random_proposal()
			_selection = (_random as Array).duplicate() if _random != null else []
			_render()
		&"decline":
			_submit(s.answer_targets.bind([]))
		&"clear_selection":
			_selection.clear()
			_random = null
			_render()
		&"choice":
			_submit(s.answer_choice.bind(bool(payload["choice"])))
		&"option":
			_submit(s.answer_option.bind(int(payload["index"])))
		&"prediction_kind":
			_prediction["kind"] = str(payload["kind"])
			_prediction["number"] = 0
			_render()
		&"prediction_number":
			_prediction["number"] = int(payload["number"])
			_render()
		&"prediction":
			_submit(s.answer_prediction.bind(str(payload["kind"]), int(payload["number"])))
		&"show_card":
			open_layer(&"show")
		&"continue_day":
			_morning_done_day = int(_view.get("day_number", 0))
			_render()
		&"show_announcement":
			open_layer(&"announcement")
		&"morning_details":
			open_layer(&"morning")
		&"override_shown":
			_ask_override()
		&"end_night":
			_submit(s.end_night)
		&"confirm_win":
			var r := DialogRequest.create("ui.cockpit.dialog.confirm_win.title", "ui.cockpit.dialog.confirm_win.message", "ui.cockpit.dialog.confirm_win.confirm",
				func() -> void: _submit(s.confirm_win.bind(int(payload["candidate_id"]))))
			dialog_requested.emit(r)
		&"reject_win":
			_ask_reason("ui.cockpit.dialog.reject_win.title", "ui.cockpit.dialog.reject_win.message", "ui.cockpit.dialog.reject_win.confirm",
				func(reason: String) -> void: _submit(s.reject_win.bind(reason)))


## Sendet genau einen Befehl; die Karte ist bis zur neuen Sicht gesperrt (Mehrfachtippen).
## Pfeile am Zielplatz: zur nächsten oder vorherigen wählbaren Person (Sitzreihenfolge), wie das Antippen dieses Platzes.
func _cycle_target(direction: int) -> void:
	var next: Dictionary = _view.get("next", {})
	var allowed: Array = next.get("allowed_ids", [])
	if allowed.size() < 2 or int(next.get("max", 0)) != 1:
		return
	var ordered: Array = []
	for seat: Dictionary in _view.get("seats", []):
		if allowed.has(int(seat["person_id"])):
			ordered.append(int(seat["person_id"]))
	var index := ordered.find(int(_selection[0])) if not _selection.is_empty() else -1
	var target: int = int(ordered[posmod(index + direction, ordered.size())]) if index >= 0 else int(ordered[0] if direction > 0 else ordered[-1])
	_selection = [target]
	_random = null
	_render()


func _submit(action: Callable) -> void:
	_card.lock()
	var result: CommandResult = action.call()
	if result == null or not result.ok:
		_render()


func _on_rejected(error: StringName) -> void:
	var key := "ui.cockpit.error.%s" % String(error)
	_error_key = key if CockpitText.has_key(key) else "ui.cockpit.error.generic"
	status_message_requested.emit(_error_key)


func _ask_reason(title_key: String, message_key: String, confirm_key: String, on_text: Callable) -> void:
	dialog_requested.emit(DialogRequest.with_input(title_key, message_key, confirm_key, "ui.cockpit.dialog.reason_placeholder", on_text))


func _ask_override() -> void:
	var request := DialogRequest.create("ui.cockpit.dialog.override.title", "ui.cockpit.dialog.override.message", "")
	for role: StringName in RolePresentation.sorted_roles():
		var option := DialogOption.new()
		option.node_name = "Role_%s" % CockpitText.key_part(String(role))
		option.text_key = RolePresentation.name_key(role)
		option.on_select = func() -> void:
			_ask_reason.call_deferred("ui.cockpit.dialog.override_reason.title", "ui.cockpit.dialog.override_reason.message", "ui.cockpit.dialog.override_reason.confirm",
				func(reason: String) -> void: _submit(context.session.override_shown_role.bind(String(role), reason)))
		request.options.append(option)
	dialog_requested.emit(request)


# --- Ebenen: Protokoll, privater Bereich, gezeigte Karte, Sichtschutz -------------------------------

## Öffnet genau eine Ebene; ihr Inhalt entsteht erst jetzt aus der Anwendungsschicht.
func open_layer(kind: StringName) -> void:
	close_layer()
	if not bool(_view.get("has_game", false)):
		return
	match kind:
		&"private":
			_layer = CockpitLayers.private_drawer(context.session.private_seats(), context.session.secret_day_actions(), context.session.vote_hints())
		&"gm":
			var undo := context.session.undo_info()
			_layer = CockpitLayers.gm_drawer({"undo": undo, "redo": context.session.redo_info(),
				"day": str((_view.get("next", {}) as Dictionary).get("kind")) == "day",
				"last_change": context.session.last_command_events().filter(func(e: Dictionary) -> bool: return str(e["type"]) != "PromptCancelled")
					if str(undo.get("type", "")) == "GmCorrection" else []}, _view.get("seats", []))
		&"log":
			_layer = CockpitLayers.log_drawer(context.session.event_log(), _view.get("seats", []))
		&"show":
			var next: Dictionary = _view.get("next", {})
			_layer = CockpitLayers.show_card(str(next.get("role_id", "")), next.get("show", []))
			_layout.visible = false  # die gezeigte Karte ersetzt das Cockpit vollständig
		&"roles":
			_layer = CockpitLayers.role_list(context.session.role_show_list())
			_layout.visible = false  # die neutrale Liste ersetzt das Cockpit vollständig
		&"notice":
			var notice: Dictionary = _view.get("next", {})
			if str(notice.get("kind")) == "notice":
				_layer = CockpitLayers.notice_card(notice)
				_layout.visible = false  # die Hinweiskarte ersetzt das Cockpit vollständig
		&"card":
			var window: Dictionary = _view.get("next", {})
			if str(window.get("kind")) == "card_window":
				_layer = CockpitLayers.card_face(window.get("card", {}), window.get("owner", {}))
				_layout.visible = false  # die gezeigte Karte ersetzt das Cockpit vollständig
		&"cards":
			_layer = CockpitLayers.cards_drawer(context.session.card_overview(), context.session.card_swallowers())
		&"announcement":
			var report := context.session.morning_report()
			_layer = CockpitLayers.announcement(int(report.get("night_number", 0)), report.get("public", {}))
			_layout.visible = false
		&"morning":
			_layer = CockpitLayers.morning_drawer(context.session.morning_report(), _view.get("seats", []))
	if _layer == null:
		_layout.visible = true
		return
	_layer_kind = kind
	_overlay_host.add_child(_layer)
	var close := _layer.find_child("CloseLayerButton", true, false) as BaseButton
	if close != null:
		close.pressed.connect(close_layer)
		close.grab_focus()
	for b: Node in _layer.find_children("GmKind_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_start_gm_mode.bind(str(b.get_meta("gm_kind"))))
	for pair: Array in [["UndoButton", _ask_undo], ["RedoButton", _ask_redo], ["LeaveGameButton", _leave_game], ["DiscardGameButton", _ask_discard_game]]:
		var node := _layer.find_child(pair[0], true, false) as BaseButton
		if node != null:
			node.pressed.connect(pair[1])
	for b: Node in _layer.find_children("RolePerson_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_open_role_card.bind(int(b.get_meta("person_id")), false))
	_wire_role_card()
	for b: Node in _layer.find_children("SecretAction_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_on_secret_action.bind(str(b.get_meta("action")), int(b.get_meta("player_id"))))


# --- Rollenanzeige ------------------------------------------------------------------------------------------
# Liste (neutral) → Vorderseite (neutral, nur Name) → Rolle nach bewusster Aktion → Schließen zurück zur Liste. Nur „Gesehen“
# sendet ConfirmRoleShown. Die Karte mit Rolle entsteht erst beim Zeigen und wird bei jedem Zustandswechsel, Undo, Laden,
# Sichtschutz und Verlassen der Ansicht verworfen; die Liste schließt nie in einen privaten Bereich.

## Öffnet die Karte einer Person; `revealed` erst nach der bewussten Aktion.
func _open_role_card(person_id: int, revealed: bool) -> void:
	var card := context.session.role_show_card(person_id) if revealed else {}
	if not revealed:
		for entry: Dictionary in context.session.role_show_list().get("persons", []):
			if int(entry["person_id"]) == person_id:
				card = entry
	if card.is_empty():
		open_layer.call_deferred(&"roles")
		return
	close_layer()
	_layer = CockpitLayers.role_card(card, revealed)
	_layer_kind = &"role_card"
	_role_card_person = person_id
	_layout.visible = false
	_overlay_host.add_child(_layer)
	_wire_role_card()
	var first := _layer.find_children("*", "BaseButton", true, false)
	if not first.is_empty():
		(first[0] as Control).grab_focus()


func _wire_role_card() -> void:
	if _layer == null or _layer.name != "RoleCardLayer":
		return
	var reveal := _layer.find_child("RevealRoleButton", true, false) as BaseButton
	if reveal != null:
		reveal.pressed.connect(func() -> void: _open_role_card.call_deferred(_role_card_person, true))
	for button_name: String in ["CancelRoleButton", "CloseRoleButton", "CloseWithoutConfirmButton"]:
		var b := _layer.find_child(button_name, true, false) as BaseButton
		if b != null:
			b.pressed.connect(open_layer.bind(&"roles"), CONNECT_DEFERRED)
	var confirm := _layer.find_child("ConfirmRoleButton", true, false) as BaseButton
	if confirm != null:
		confirm.pressed.connect(_confirm_role.bind(_role_card_person), CONNECT_DEFERRED)


func _confirm_role(person_id: int) -> void:
	var result := context.session.confirm_role_shown(person_id)
	if not result.ok:
		open_layer(&"roles")  # bei Annahme erledigt das der Sichtwechsel (_discard_role_card)


## Zustandswechsel: eine offene Rollenkarte könnte veraltete Geheimnisse zeigen, deshalb zurück zur frisch gebauten neutralen Liste.
func _discard_role_card() -> void:
	if _layer_kind == &"role_card" or _layer_kind == &"roles":
		open_layer.call_deferred(&"roles")
		_layer_kind = &"roles"
		if _layer != null:
			_overlay_host.remove_child(_layer)
			_layer.queue_free()
			_layer = null


# --- Spielleitung: Korrekturen, Rückgängig, Partie beenden ---------------------------------------

func _start_gm_mode(kind: String) -> void:
	close_layer()
	_reset_day_mode()
	_reset_gm_mode()
	if kind == "execute":
		# Hinrichtung ohne Nominierung: jede lebende Person, dann dieselbe Prüfkarte wie am Tag.
		_gm_execute = true
	_gm_mode = kind
	_render()


func _confirm_gm_mode() -> void:
	var target := int(_selection[0]) if not _selection.is_empty() else -1
	match _gm_mode:
		"kill":
			_ask_correction({"kind": "kill", "target_id": target, "trigger_effects": bool(_gm_effects)})
		"revive":
			_ask_correction({"kind": "revive", "target_id": target})
		"set_role":
			_ask_correction({"kind": "set_role", "target_id": target, "role_id": _gm_role})
		"execute":
			_gm_mode = ""
			_preview = context.session.execution_preview(target)
			_day_mode = "execution_check"
			_check_revealed = true  # die Spielleitung hat die Korrektur bewusst geöffnet
			_render()


## „Status ändern“: Wert umschalten (bool) oder Rolle wählen (Scheinrolle), dann Rückfrage mit Begründung.
func _ask_status_field(index: int) -> void:
	var fields := context.session.status_fields(int(_selection[0]))
	if index >= fields.size():
		return
	var f: Dictionary = fields[index]
	var payload: Dictionary = (f["fields"] as Dictionary).duplicate()
	payload["kind"] = str(f["kind"])
	if str(f["type"]) == "action":
		_ask_correction(payload, TranslationServer.translate("ui.cockpit.dialog.gm.detail_from").format({"state": CockpitText.state_text(f.get("state", {}))}))
		return
	if str(f["type"]) == "pick":
		_ask_pick(payload, f)
		return
	if str(f["type"]) == "bool":
		payload[str(f["value_key"])] = not bool(f["current"])
		_ask_correction(payload)
		return
	var request := DialogRequest.create("ui.cockpit.dialog.gm_role.title", "ui.cockpit.dialog.gm_role.message", "")
	for role: StringName in RolePresentation.sorted_roles():
		var option := DialogOption.new()
		option.node_name = "Role_%s" % CockpitText.key_part(String(role))
		option.text_key = RolePresentation.name_key(role)
		option.on_select = func() -> void:
			var p := payload.duplicate()
			p[str(f["value_key"])] = String(role)
			_ask_correction.call_deferred(p)
		request.options.append(option)
	dialog_requested.emit(request)


func _ask_gm_role() -> void:
	var request := DialogRequest.create("ui.cockpit.dialog.gm_role.title", "ui.cockpit.dialog.gm_role.message", "")
	for role: StringName in RolePresentation.sorted_roles():
		var option := DialogOption.new()
		option.node_name = "Role_%s" % CockpitText.key_part(String(role))
		option.text_key = RolePresentation.name_key(role)
		option.on_select = func() -> void:
			_gm_role = String(role)
			_render()
		request.options.append(option)
	dialog_requested.emit(request)


## Zielwahl einer Spezialkorrektur: nur Personen, die der Regelkern als Ziel annimmt (`pick_ids`). Die Wahl gilt nur für den
## Zustand, in dem sie geöffnet wurde; ein Zustandswechsel dazwischen verwirft sie.
func _ask_pick(payload: Dictionary, field: Dictionary) -> void:
	var revision := context.session.state_hash()
	var request := DialogRequest.create("ui.cockpit.dialog.pick.title", "ui.cockpit.dialog.pick.message", "")
	request.message_values = {"what": StringName("ui.gm.kind.%s" % str(payload["kind"])),
		"person": CockpitText.names_of([int((field["fields"] as Dictionary).values()[0])], _view.get("seats", []))}
	for id: Variant in field["pick_ids"]:
		var seat := int(id)
		var option := DialogOption.new()
		option.node_name = "Pick_%d" % seat
		option.text_key = "ui.cockpit.roles.person"
		for entry: Dictionary in _view.get("seats", []):
			if int(entry["person_id"]) == seat:
				option.values = {"seat": int(entry["seat"]), "name": str(entry["name"])}
		option.on_select = func() -> void:
			if context.session.state_hash() != revision:
				status_message_requested.emit("ui.cockpit.status.stale_selection")
				_render()
				return
			var p := payload.duplicate()
			p[str(field["pick_key"])] = seat
			_ask_correction.call_deferred(p, TranslationServer.translate("ui.cockpit.dialog.gm.detail_to").format({"state": CockpitText.state_text(field.get("state", {})),
				"target": CockpitText.names_of([seat], _view.get("seats", []))}), revision)
		request.options.append(option)
	dialog_requested.emit(request)


## Warnung mit Pflichtbegründung; erst dann geht die Korrektur an den Regelkern. Danach zeigt die
## Ebene „Spielleitung“, was sich geändert hat. `detail` nennt Person und Wert (Spezialkorrekturen), `revision` den Zustand,
## für den die Rückfrage gilt (ein Zustandswechsel verwirft sie).
func _ask_correction(payload: Dictionary, detail: String = "", revision: String = "") -> void:
	revision = revision if revision != "" else context.session.state_hash()
	var subject := ""
	for key: String in ["guardian_id", "witch_id", "child_id", "apprentice_id"]:
		if payload.has(key):
			subject = CockpitText.names_of([int(payload[key])], _view.get("seats", []))
	var request := DialogRequest.with_input("ui.cockpit.dialog.gm.title", "ui.cockpit.dialog.gm.message" if subject == "" else "ui.cockpit.dialog.gm.message_detail",
		"ui.cockpit.dialog.gm.confirm", "ui.cockpit.dialog.reason_placeholder", func(reason: String) -> void:
			if context.session.state_hash() != revision:
				status_message_requested.emit("ui.cockpit.status.stale_selection")
				_render()
				return
			var p := payload.duplicate()
			p["reason"] = reason
			_reset_gm_mode()
			_reset_day_mode()
			_card.lock()
			var result := context.session.gm_correction(p)
			if result.ok:
				status_message_requested.emit("ui.cockpit.status.corrected")
				open_layer(&"gm")
			else:
				_render(), true)
	request.message_values = {"what": StringName("ui.gm.kind.%s" % str(payload["kind"])), "person": subject, "detail": detail}
	dialog_requested.emit(request)


func _ask_undo() -> void:
	var label := CockpitText.command_label(context.session.undo_info())
	var r := DialogRequest.create("ui.cockpit.dialog.undo.title", "ui.cockpit.dialog.undo.message", "ui.cockpit.dialog.undo.confirm", func() -> void:
		close_layer()
		if context.session.undo():
			status_message_requested.emit("ui.cockpit.status.undone"))
	r.message_values = {"what": CockpitLayers._format(label)}
	close_layer()
	dialog_requested.emit(r)


func _ask_redo() -> void:
	var label := CockpitText.command_label(context.session.redo_info())
	var r := DialogRequest.create("ui.cockpit.dialog.redo.title", "ui.cockpit.dialog.redo.message", "ui.cockpit.dialog.redo.confirm", func() -> void:
		if context.session.redo():
			status_message_requested.emit("ui.cockpit.status.redone"))
	r.message_values = {"what": CockpitLayers._format(label)}
	close_layer()
	dialog_requested.emit(r)


func _leave_game() -> void:
	close_layer()
	navigate_requested.emit(ScreenIds.MAIN_MENU)


## Beenden und verwerfen: Rückfrage (rot); die Dateien werden nur umbenannt, die Sitzung geleert.
func _ask_discard_game() -> void:
	close_layer()
	dialog_requested.emit(DialogRequest.create("ui.cockpit.dialog.discard.title", "ui.cockpit.dialog.discard.message", "ui.cockpit.dialog.discard.confirm",
		func() -> void:
			context.saves.discard(context.session.round_id())
			context.session.reset()
			status_message_requested.emit("ui.continue.status.discarded")
			navigate_requested.emit(ScreenIds.MAIN_MENU), true))


## Geheime Tagesaktionen aus dem privaten Bereich (Amalia, Nekromant). Der Bereich schließt zuerst.
func _on_secret_action(action: String, player_id: int) -> void:
	close_layer()
	match action:
		"amalia":
			var r := DialogRequest.create("ui.cockpit.dialog.amalia.title", "ui.cockpit.dialog.amalia.message", "ui.cockpit.dialog.amalia.yes",
				func() -> void: _submit(context.session.amalia_sacrifice.bind(player_id, true)))
			r.alternative_key = "ui.cockpit.dialog.amalia.no"
			r.on_alternative = func() -> void: _submit(context.session.amalia_sacrifice.bind(player_id, false))
			dialog_requested.emit(r)
		"name_wolf":
			_reset_day_mode()
			_necromancer = player_id
			_day_mode = "name_wolf"
			_render()


func close_layer() -> void:
	_tools_menu.visible = false
	if _layer_kind == &"roles" or _layer_kind == &"role_card":
		_revealed_id = ""  # nach der Rollenanzeige bleibt keine geheime Karte des Cockpits aufgedeckt
	if _layer != null:
		_overlay_host.remove_child(_layer)
		_layer.queue_free()
	_layer = null
	_layer_kind = &""
	_layout.visible = not _covered


## Rollenlexikon als Ebene (Werkzeug oder Kontexthilfe der privaten Karte). Liest nur Übersetzungen und Katalog: kein
## Befehl, kein Zufall, keine Ressource. Die Auswahl der offenen Karte bleibt erhalten, solange sich der Zustand nicht
## ändert (eine Änderung verwirft sie wie immer über `_on_session_changed`). Sichtschutz und Zurück schließen die Ebene.
func open_lexicon(role: StringName) -> void:
	close_layer()
	_layer = RoleLexicon.layer(context.settings, role)
	_layer_kind = &"lexicon"
	_overlay_host.add_child(_layer)
	var lexicon := _layer.find_child("RoleLexicon", true, false) as RoleLexicon
	lexicon.close_requested.connect(close_layer)
	(_layer.find_child("CloseLayerButton", true, false) as Control).grab_focus()


## Allgemeines Regelbuch als Ebene (Werkzeug „Regelbuch“). Wie das Lexikon: liest nur Übersetzungen, sendet keinen Befehl, zieht
## keinen Zufall, verbraucht nichts und lässt die offene Auswahl unberührt; Sichtschutz und Zurück schließen die Ebene.
func open_rulebook() -> void:
	close_layer()
	_layer = RuleBook.layer(context.settings)
	_layer_kind = &"rulebook"
	_overlay_host.add_child(_layer)
	var book := _layer.find_child("RuleBook", true, false) as RuleBook
	book.close_requested.connect(close_layer)
	(_layer.find_child("CloseLayerButton", true, false) as Control).grab_focus()


func layer_kind() -> StringName:
	return _layer_kind


## Sichtschutz: entfernt alle Ebenen, verdeckt Karten wieder und blendet das Cockpit aus.
func cover() -> void:
	if not bool(_view.get("has_game", false)):
		return
	close_layer()
	_revealed_id = ""
	_covered = true
	_layout.visible = false
	_layer = CockpitLayers.cover_panel()
	_layer_kind = &"cover"
	_overlay_host.add_child(_layer)
	var resume := _layer.find_child("UncoverButton", true, false) as BaseButton
	resume.pressed.connect(uncover)
	resume.grab_focus()


func uncover() -> void:
	_covered = false
	close_layer()
	_render()


func is_covered() -> bool:
	return _covered


func _exit_tree() -> void:
	close_layer()
	if context != null and context.timer.running:
		context.autosave()  # die Restzeit läuft nur mit der Anzeige: beim Verlassen den Stand festhalten
