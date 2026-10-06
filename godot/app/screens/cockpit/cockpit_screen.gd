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

const BAR_SIDE := 88.0          ## Abstand der Nachtleiste zum Fensterrand (Zurück-Platte und Laschen daneben)
const BAR_MAX_WIDTH := 980.0
const TOP_MARGIN := 6.0
const RING_SIDE := 58.0         ## Randabstand des Sitzkreises (Platz für Laschen)
const BOTTOM_MARGIN := 68.0     ## unter dem Sitzkreis liegt das Dock (Rückgängig, Nächster Schritt) und die Phasen-Kartusche
const DOCK_MARGIN := 8.0
const TAB_WIDTH := 52.0
const TAB_MAX_HEIGHT := 320.0
const WIDE_ASPECT := 1.5        ## ab diesem Seitenverhältnis (16:10) ist die Leiste voll sichtbar, darunter (4:3) eingeklappt
const MENU_WIDTH := 300.0
const PLATE_MARGIN := 12.0
const CORNER_WIDTH := 176.0
const PLATE_SIZE := Vector2(200.0, 52.0)
const PLAZA_CENTER_UV := Vector2(0.508, 0.508)  ## Mitte des Dorfplatzes im Hintergrundbild (Nachtszene v2)
const BACKDROP_OVERSCAN := 1.05                 ## etwas größer als „cover“, damit sich die Platzmitte auf die Ringmitte schieben lässt

static var double_tap_msec: int = 400  ## Sperre für die eben übernommene Person (feste Anzahl gilt sofort); Tests schalten sie ab

var _view: Dictionary = {}
var _next_id: String = ""
var _selection: Array = []
var _random: Variant = null  ## Zufallsvorschlag (Personen) der offenen Spielleiterwahl; nur bis zur nächsten Änderung
var _loki_mode: Variant = null  ## Loki: gewählte Art der Bindung (true = Liebende) vor der Wahl der zwei Personen (nur Bedienzustand)
var _committed_seat: int = -1  ## zuletzt automatisch übernommene Person (Schutz vor Doppeltippen)
var _committed_until: int = 0
var _call_step: String = ""  ## Schritt, dessen Ansage die Karte noch zeigt (der Schritt beginnt mit der ersten Handlung, die Ansage bleibt stehen)
var _after_close: Callable = Callable()  ## Handlung nach dem Schließen der gezeigten Karte (Hinweis bestätigen, Auskunft erledigen)
var _prediction := {"kind": "night", "number": 0}
var _error_key: String = ""
var _covered: bool = false
## Rollenbild auf der Aktionskarte: aus seit der Nachtschablone (Markus 05.10.2026: die Nachtkarte zeigt kein Rollenbild; Titel und Hilfe
## nennen die Fähigkeit). Auf `true` setzen, um es wiederzubringen.
const ROLE_ART_ON_CARD := false
const MINI_CARD_SHARE := 0.38  ## Mini-Nachtkarte: Anteil an der Bildschirmbreite (DA-101)
const MINI_CARD_MIN_WIDTH := 360.0  ## schmaler schrumpfen Name, Rolle und Aktion zu stark
const DAY_CARD_SHARE := 0.46  ## Tageskarte nach Inhalt: breit genug für drei Knöpfe, schmal genug für die Nominierungsbänder
const DAY_CARD_MIN_WIDTH := 400.0
const STRIP_MAX_WIDTH := 820.0  ## Tagesleiste oben: Anklagen und Verteidigungszeile, klein und durchscheinend; die Mitte bleibt für die Bänder frei
const STRIP_MAX_HEIGHT := 82.0  ## höher darf sie nicht werden: darunter beginnen die obersten Porträts
const STRIP_UNDO_WIDTH := 100.0  ## „Rückgängig“ im Dock ist neben der Tagesleiste schmaler
const STRIP_VERTICAL := 14.0
const STRIP_SIDE := 34.0  ## Innenabstand links und rechts: Platz für die Dornenenden der gemalten Zeile
## Befehle, nach denen es nichts zurückzunehmen gibt, was die Spielleitung gewählt hätte: das Dock zeigt „Rückgängig“ erst nach einer Auswahl.
const NO_CHOICE_COMMANDS: Array[StringName] = [Command.START_NIGHT, Command.BEGIN_STEP]
const PEEK_MSEC := 3000  ## so lange bleiben die Abzeichen einer angetippten Person am Tag sichtbar
var _peek_id: int = 0
var _peek_until: int = 0
var _hidden: bool = false  ## „Verbergen“: nur Namen, Porträts, tot oder lebendig (nur Bedienzustand, nie gespeichert)
var _bar_expanded: bool = false  ## Nachtleiste auf 4:3 ausgeklappt (Überlagerung, nur Bedienzustand)
var _layer: Control = null
var _layer_kind: StringName = &""
var _morning_done_day: int = -1  ## Tag, dessen Morgenbericht die Spielleitung weitergeschaltet hat (nur Bedienzustand)
var _dawn_decoys: Array = []  ## Tarnaufrufe nach dem letzten Nachtschritt; die Morgenkarte nennt sie zuerst (nur Bedienzustand)
## Bedienzustand am Tag: "" | nominate_from | nominate_to | execute | execution_check | name_wolf
var _day_mode: String = ""
var _nominator: int = -1
var _necromancer: int = -1
var _card_effect: int = -1  ## Tagesregel einer Karte, für die ein Verstoß gemeldet wird (nur Bedienzustand)
var _preview: Dictionary = {}
var _exec_extra: Dictionary = {}
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
var _day_bar: HBoxContainer = null  ## Nebenknöpfe der Tagesleiste, unten in der Lücke zwischen Timer und Rückgängig

var _backdrop_phase: String = ""
var _backdrop_tween: Tween = null


func _setup() -> void:
	header.back_button().kind = GrimmButton.Kind.COMPACT  # schmale Kopfleiste: mehr Fläche für das Brett
	GroveSkin.skin_back_button(header.back_button())
	header.add_theme_stylebox_override("panel", StyleBoxEmpty.new())  # die Platte ist der Rahmen, keine dunkle Kopfzeile dahinter
	(header.find_child("TitleLabel", true, false) as Control).visible = false  # nur der Zurück-Knopf steht in der Ecke
	header.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_backdrop_art.texture = NightArt.texture("bg/scene-night-base.webp")
	_style_backdrop()
	_day_bar = HBoxContainer.new()
	_day_bar.name = "DayBar"
	_day_bar.add_theme_constant_override(&"separation", 4)
	_day_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_layout.add_child(_day_bar)
	_card.secondary_host = _day_bar
	_ring.center().resized.connect(_place_card)  # die Leiste oben misst ihren Ort an der Ringmitte
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
	_card.undo_changed.connect(_update_dock_undo)
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
	if str(_effective(next).get("owner")) != "loki":
		_loki_mode = null
	var identity := _identity(next)
	if identity != _next_id:
		_next_id = identity
		_selection.clear()
		_random = null
		_prediction = {"kind": "night", "number": 0}
	_update_status(active)
	_ring.show_seats(_view.get("seats", []))
	_apply_marks(active)
	_ring.set_secrets_visible(not _hidden)
	_update_order(active)
	_update_dock_undo()
	_hidden_label.visible = active and _hidden
	_arrange()
	_render()  # setzt auch die Sichtbarkeit der Karte


## „Rückgängig“ im Dock: nur einmal sichtbar (nicht, solange die Karte ihren Knopf zeigt) und erst nach einer Auswahl.
func _update_dock_undo() -> void:
	var can := bool(_view.get("has_game", false)) and context.session.can_undo()
	var chosen := false
	if can:
		var commands := context.session.commands()
		chosen = not commands.is_empty() and not NO_CHOICE_COMMANDS.has(commands.back().type)
	_dock_undo.disabled = not can
	_dock_undo.visible = chosen and not _card.undo_visible()
	_arrange()


## Abzeichen am Sitzkreis (S-05, DA-93): in der Nacht alle, tagsüber verborgen; ein Tipp auf eine Person blendet ihre Abzeichen kurz ein.
func _apply_marks(active: bool) -> void:
	var marks: Dictionary = context.session.board_marks() if active else {}
	if active and str(_view.get("phase", "")) != "NIGHT":
		var shown := {}
		if _peek_id > 0 and Time.get_ticks_msec() < _peek_until and marks.has(_peek_id):
			shown[_peek_id] = marks[_peek_id]
		marks = shown
	_ring.set_marks(marks)


func _peek_marks(person_id: int) -> void:
	_peek_id = person_id
	_peek_until = Time.get_ticks_msec() + PEEK_MSEC
	_apply_marks(bool(_view.get("has_game", false)))
	get_tree().create_timer(PEEK_MSEC / 1000.0 + 0.05).timeout.connect(func() -> void:
		if is_inside_tree():
			_apply_marks(bool(_view.get("has_game", false))))


## Nachtreihenfolge: nur in der Nacht, nur für die Spielleitung (bei „Verbergen“ aus).
func _update_order(active: bool) -> void:
	var in_night := active and str(_view.get("phase", "")) == "NIGHT"
	var order: Array = context.session.night_order() if in_night else []
	order = _order_for_card(order, _view.get("next", {}))
	_order_bar.show_order(order, _bar_is_full(), _bar_collapsible())
	var anonymous := bool(_effective(_view.get("next", {})).get("anonymous_asker", false))  # S-04 (DA-93): die Leiste verriete die Rolle der Fragenden
	_order_bar.visible = in_night and not _hidden and not order.is_empty() and not anonymous


## Ein Hinweis (DI-04, DI-06, DI-07) gehört zur Rolle, die ihn auslöst (Loki, Rattenfänger, Pestbringerin): Die Leiste zeigt diese Rolle als aktiv,
## damit Leiste und Karte denselben Schritt nennen. Nur Darstellung, die Reihenfolge der Nacht bleibt unberührt.
func _order_for_card(order: Array, next: Dictionary) -> Array:
	if str(next.get("kind")) != "notice":
		return order
	var role := CockpitText.help_role(next)
	if role == "" or not order.any(func(e: Dictionary) -> bool: return str(e["role_id"]) == role):
		return order
	var out: Array = []
	for entry: Dictionary in order:
		var copy := entry.duplicate()
		if str(entry["role_id"]) == role:
			copy["state"] = "active"
		elif str(entry["state"]) == "active":
			copy["state"] = "upcoming"
		out.append(copy)
	return out


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
	_save_status.self_modulate = ThemeTokens.TINT_QUIET if ok else ThemeTokens.TINT_NONE
	_save_row.alignment = FlowContainer.ALIGNMENT_BEGIN if ok else FlowContainer.ALIGNMENT_CENTER
	_arrange()  # die Zeile wird mit dem Wiederholen-Knopf höher
	if not ok:
		_arrange.call_deferred()  # Mindesthöhe der Zeile gilt erst nach dem Breitenwechsel; dann erst passt die Höhe


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
	_round.visible = _round.text_key != ""  # ohne Text bliebe von der gemalten Zeile ein leerer Winzling
	_alive.visible = _alive.text_key != ""
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
	if _day_bar_shown():  # mehr Platz für die Knöpfe in der Lücke daneben: „Rückgängig“ so klein wie sie
		if _dock_undo.kind != GrimmButton.Kind.COMPACT:
			_dock_undo.kind = GrimmButton.Kind.COMPACT
			ActionCard.tighten_button(_dock_undo)
		_dock_undo.custom_minimum_size = Vector2(STRIP_UNDO_WIDTH, ActionCard.STRIP_BUTTON_HEIGHT)
	elif _dock_undo.kind == GrimmButton.Kind.COMPACT:
		ActionCard.loosen_button(_dock_undo)
		_dock_undo.kind = GrimmButton.Kind.SECONDARY
		GroveSkin.skin_button(_dock_undo, false)
	_dock.size = _dock.get_combined_minimum_size()
	_phase_area.size = _phase_area.get_combined_minimum_size()
	var dock_x := DOCK_MARGIN if left_handed else w - DOCK_MARGIN - _dock.size.x
	var plate_x := w - DOCK_MARGIN - _phase_area.size.x if left_handed else DOCK_MARGIN
	_dock.position = Vector2(dock_x, h - DOCK_MARGIN - _dock.size.y)
	_phase_area.position = Vector2(plate_x, h - DOCK_MARGIN - _phase_area.size.y)
	var free_left := (_dock.position.x + _dock.size.x if left_handed else _phase_area.position.x + _phase_area.size.x) + PLATE_MARGIN
	var free_right := (_phase_area.position.x if left_handed else _dock.position.x) - PLATE_MARGIN
	if _retry_save.visible:
		free_left -= PLATE_MARGIN - 4.0  # Fehlerzeile braucht die Breite, damit Text und Knopf in einer Zeile bleiben
	_save_row.size = Vector2(maxf(free_right - free_left, 1.0), 0.0)
	var row_height := float(ThemeTokens.TOUCH_MIN) if _retry_save.visible else _save_row.get_combined_minimum_size().y  # Mindesthöhe aktualisiert sich erst im nächsten Bild (nach dem Wechsel der Breite wäre sie veraltet)
	_save_row.size = Vector2(_save_row.size.x, row_height)
	if _retry_save.visible:
		_save_row.position = Vector2(free_left, h - DOCK_MARGIN - _save_row.size.y)  # Fehler: breit und deutlich neben dem Dock
	else:
		# „Gespeichert“: kleiner, ruhiger Hinweis an fester Stelle, linksbündig über der Kartusche
		_save_row.size = Vector2(_phase_area.size.x, _save_row.get_combined_minimum_size().y)
		_save_row.position = Vector2(_phase_area.position.x + 4.0, _phase_area.position.y - _save_row.size.y - 2.0)
	_arrange_day_bar(free_left, free_right, h)
	_tools_menu.size = _tools_menu.get_combined_minimum_size()
	_tools_menu.position = Vector2(w - TAB_WIDTH - _tools_menu.size.x - 4.0, clampf(tab_y, TOP_MARGIN, maxf(TOP_MARGIN, h - _tools_menu.size.y - TOP_MARGIN)))
	_place_backdrop_art(_ring.position + _ring.size * 0.5)
	_place_card()


func _day_bar_shown() -> bool:
	return _card.is_strip() and _day_bar.get_child_count() > 0 and not _hidden


## Nebenknöpfe der Tagesleiste: in der freien Lücke unten zwischen Timer und Rückgängig, auf Höhe des Docks.
func _arrange_day_bar(free_left: float, free_right: float, h: float) -> void:
	_day_bar.visible = _day_bar_shown()
	var wanted := _day_bar.get_combined_minimum_size()
	var left := free_left - PLATE_MARGIN + 6.0  # die Lücke ist schmal: der Abstand zu Timer und Rückgängig darf kleiner sein
	var right := free_right + PLATE_MARGIN - 6.0
	var width := maxf(minf(wanted.x, right - left), 1.0)
	var spare := (right - left) - wanted.x  # ist Platz übrig (z. B. ein einzelner Knopf), bekommt der Text mehr Rand zu den Dornen
	if spare > 1.0:
		for b: Node in _day_bar.get_children():
			if b is Control and not b.is_queued_for_deletion():
				(b as Control).custom_minimum_size.x = maxf((b as Control).custom_minimum_size.x, (b as Control).get_minimum_size().x + minf(spare / float(_day_bar.get_child_count()), ActionCard.STRIP_BUTTON_PAD))
	_day_bar.size = Vector2(width, wanted.y)
	_day_bar.position = Vector2(left + (right - left - width) * 0.5, h - DOCK_MARGIN - wanted.y - (56.0 - wanted.y) * 0.5)


## Mini-Nachtkarte (DA-101, Feedback 8: mittig auf dem Dorfplatz) und Tageskarte nach Inhalt: schmal, in der Mitte der freien Ringmitte,
## so hoch wie ihr Inhalt; sie verdeckt keinen Sitz und lässt die Nominierungsbänder erkennbar. Alle anderen Karten füllen die freie Mitte.
func _place_card() -> void:
	var panel := %InstructionCard as PanelContainer
	if not _card.is_compact():
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		return
	if _card.is_strip():
		_place_strip(panel)
		return
	var day := _card.is_day_card()
	_card.set_max_height(_ring.center().size.y)  # die Karte liegt ganz in der freien Ringmitte: sonst kleiner, nie höher
	var width := minf(maxf(size.x * (DAY_CARD_SHARE if day else MINI_CARD_SHARE), DAY_CARD_MIN_WIDTH if day else MINI_CARD_MIN_WIDTH), _ring.center().size.x)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH  # wächst mit dem Inhalt nach oben und unten
	panel.size.y = 0.0  # auf die Mindesthöhe zurück: gleiche Ränder setzen die Größe nicht neu


## Tagesleiste: schmal und durchscheinend oben in der Mitte über den obersten Porträts. Die Ringmitte bleibt frei, alle Bänder sind zu sehen.
func _place_strip(panel: PanelContainer) -> void:
	_card.set_max_height(STRIP_MAX_HEIGHT)
	var width := minf(size.x - 2.0 * BAR_SIDE, STRIP_MAX_WIDTH)
	var origin := _ring.position + _ring.center().position  # Ringmitte in Bildschirmkoordinaten (die Karte hängt an ihr)
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = (size.x - width) * 0.5 - origin.x
	panel.offset_right = panel.offset_left + width
	panel.offset_top = TOP_MARGIN - origin.y
	panel.offset_bottom = panel.offset_top
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical = Control.GROW_DIRECTION_END  # wächst mit dem Inhalt nach unten
	panel.size.y = 0.0


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


## Aktionskarte: Dornenrahmen und Tafel kommen aus dem Theme (`NightCardPanel`, gemalte Haut); nur der Spielbeginn zeigt keinen Rahmen.
func _style_card() -> void:
	var panel := %InstructionCard as PanelContainer
	if _card.is_bare():
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	elif _card.is_strip():
		var row := SkinArt.row_box(ThemeTokens.TINT_STRIP)  # gemalte Listenzeile, durchscheinend
		row.content_margin_left = STRIP_SIDE
		row.content_margin_right = STRIP_SIDE
		row.content_margin_top = STRIP_VERTICAL  # die gemalte Zeile ist nur zu rund zwei Dritteln Fläche: Innenabstand, damit der Text darin sitzt
		row.content_margin_bottom = STRIP_VERTICAL
		panel.add_theme_stylebox_override("panel", row)
	else:
		panel.remove_theme_stylebox_override("panel")


## Phase und Timer unten links: die Phase auf einer gemalten Zeile (Listenzeile der Haut), daneben der Timer als gemalter Knopf; keine
## eigene Platte dahinter. Statuszeile oben links ebenfalls auf der gemalten Zeile, damit sie auf dem Pflaster lesbar bleibt.
func _style_plate() -> void:
	_phase_area.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	(_phase_area.get_child(0) as BoxContainer).add_theme_constant_override("separation", ThemeTokens.SPACE_XS)
	(%PhaseValueLabel as Control).add_theme_font_size_override("font_size", ThemeTokens.FONT_COMPACT)  # passt neben den Timer, ohne die Speicherzeile daneben zu verdrängen
	_row_plate(%PhaseValueLabel as Label, 26.0, 2.0)
	_row_plate(_hidden_label, 34.0, 3.0)  # Hinweis „Verbergen“ liegt auf dem Pflaster: gemalte Zeile als Grund
	GroveSkin.skin_button(_dock_undo, false)
	for label: GrimmLabel in [%RoundLabel, %AliveLabel]:
		label.wrap = false  # eine Zeile auf der gemalten Zeile; die Ecke wächst mit dem Text
		label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # jede Zeile so breit wie ihr Text
		_row_plate(label, 34.0, 3.0)  # genug Abstand zu den Dornenenden der Zeile


## Gemalte Zeile als Grund eines Labels (Haut, `SkinArt.row_box`), mit Innenabstand für den Text.
func _row_plate(label: Label, side: float, vertical: float) -> void:
	var back := SkinArt.row_box()
	back.content_margin_left = side
	back.content_margin_right = side
	back.content_margin_top = vertical
	back.content_margin_bottom = vertical
	label.add_theme_stylebox_override("normal", back)


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
	# Eine verankerte Karte wächst von selbst mit ihrem Inhalt, schrumpft aber nie wieder (kurz zu hoher Inhalt beim Umbau ließ sie als Streifen stehen).
	var panel := %InstructionCard as Control
	if _card.is_compact() and panel.size.y > panel.get_combined_minimum_size().y + 1.0:
		_place_card()
	if context != null and context.timer.running:
		context.timer.tick(delta)
		_timer_button.show_time(context.timer.remaining, context.timer.running, context.timer.is_set(), context.timer.is_expired())


## Namen der Personen mit dem roten Opfer-Zeichen am Sitzkreis (nur Nacht, nicht bei „Verbergen“): erklärt das Zeichen auf der Karte.
func _victim_names(phase: String) -> String:
	if _hidden or phase != "NIGHT" or not bool(_view.get("has_game", false)):
		return ""
	var ids: Array = []
	var marks: Dictionary = context.session.board_marks()
	for id: Variant in marks:
		if (marks[id] as Array).has(&"marked") or (marks[id] as Array).has("marked"):
			ids.append(id)
	return CockpitText.names_of(ids, _view.get("seats", []))


## „Verbergen“: keine Rolle, Aktion oder Ergebnis in der Mitte (die Hauptaktion bleibt im Dock). Ein Fenster ohne Inhalt wird nie gezeigt,
## sonst stünde eine leere Tafel im Bild.
func _update_card_visibility() -> void:
	var active := bool(_view.get("has_game", false))
	(%InstructionCard as Control).visible = not (active and _hidden) and _card.has_content()


func _render() -> void:
	var next: Dictionary = _view.get("next", {})
	var phase := str(_view.get("phase", ""))
	if not bool(_view.get("has_game", false)):
		_card.render({"kind": "no_game"}, {})
		_update_card_visibility()
		_ring.clear_marking()
		_card.role_art().show_role("")
		return
	var kind := str(next.get("kind"))
	if _gm_mode != "":
		next = {"kind": "gm", "secret": false}
		kind = "gm"
		_mark_gm_mode()
	elif (kind == "day" or kind == "card_window") and _morning_pending():
		var report := context.session.morning_report()
		next = {"kind": "morning", "secret": false, "public": report.get("public", {}), "private": report.get("private", []),
			"night_number": int(_view.get("night_number", 0)), "decoys": _dawn_decoys}
		kind = "morning"
	var eff := _effective(next)
	if kind == "prompt" or kind == "begin_step":
		if kind == "begin_step" and not (next.get("preview", {}) as Dictionary).is_empty():
			_call_step = str(next.get("step_id", ""))
	else:
		_call_step = ""
	if kind == "gm":
		pass
	elif kind == "day" and _day_mode != "":
		_mark_day_mode(next)
	elif str(eff.get("kind")) == "prompt" and str(eff.get("answer")) == "targets":
		_ring.set_marking(true, eff.get("allowed_ids", []), _selection, eff.get("actor_ids", []))
	elif kind == "prompt" or kind == "begin_step":
		_ring.set_marking(false, [], [], next.get("actor_ids", []))
	else:
		_ring.clear_marking()
	_ring.set_hunt(_hunt_ids(eff, kind), not context.settings.reduced_motion)
	# Ob die Auswahl bestätigt werden kann, entscheidet der Regelkern (Prüfung ohne Senden).
	var selection_error := ""
	if kind == "prompt" and str(next.get("answer")) == "targets" and not _selection.is_empty():
		selection_error = String(context.session.check_targets(_selection))
	_card.role_art().show_role(_card_role(next, kind, phase) if ROLE_ART_ON_CARD else "")
	_card.render(next, {
		"phase": phase, "seats": _view.get("seats", []), "selection": _selection, "selection_error": selection_error,
		"random_active": _random != null and _same_set(_selection, _random),
		"random_available": bool(next.get("random", false)) and context.session.random_proposal() != null,
		"night_number": int(_view.get("night_number", 0)), "prediction_kind": _prediction["kind"],
		"prediction_number": _prediction["number"], "error_key": _error_key,
		"pre_choice": _loki_mode, "call_step": _call_step,
		"gm_mode": _gm_mode, "gm_effects": _gm_effects, "gm_role": _gm_role,
		"status_fields": context.session.status_fields(int(_selection[0])) if _gm_mode == "status" and not _selection.is_empty() else [],
		"day_number": int(_view.get("day_number", 0)), "day_mode": _day_mode, "nominator": _nominator,
		"preview": _preview, "exec_extra": _exec_extra, "day_deaths": context.session.day_deaths() if bool(_view.get("has_game")) else [],
		"day_effects": context.session.day_effects() if bool(_view.get("has_game")) else [],
		"day_cards": context.session.day_cards() if bool(_view.get("has_game")) else [],
		"reduced_motion": context.settings.reduced_motion,
		"warnings": context.session.night_warnings(next, _selection) if bool(_view.get("has_game")) else [],
		"show_calls": context.settings.show_calls,
		"victim_names": _victim_names(phase),
	})
	_style_card()  # ohne Text (Spielbeginn) verschwindet der Kartenrahmen, nur der große Knopf bleibt
	_update_card_visibility()
	_place_card()
	_arrange()  # die Hauptaktion im Dock wechselt mit der Karte: Dock und Phasenplatte neu setzen
	_arrange.call_deferred()  # Mindestgrößen von Dock und Tagesleiste stimmen erst im nächsten Bild
	_restore_focus()


## Rolle für das Rollenbild der Karte: nur in der Nacht, bei einer Rollenhandlung, solange nicht verborgen und die Karte sichtbar ist.
## Nie bei der anonymen Frage (DI-05) und nie bei Karten der Totenreichkarten.
func _card_role(next: Dictionary, kind: String, phase: String) -> String:
	if _hidden or phase != "NIGHT" or _gm_mode != "":
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
			_ring.set_locked(_seat_ids_where("nominated_someone_today"))  # Korrupter Richter bleibt verdeckt: sein Sitz trägt dieses Merkmal nicht
		"nominate_to":
			var nominated := _seat_ids_where("nominated_today")  # jede Person wird pro Tag nur einmal nominiert: still ausgegraut
			_ring.set_marking(true, alive.filter(func(id: int) -> bool: return id != _nominator and not nominated.has(id)), _selection, [_nominator])
			_ring.set_locked(nominated)
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
			elif _gm_execute:
				_ring.set_marking(false, [], [], [])
			else:
				_ring.set_marking(true, next.get("execution_candidates", []) if not bool(_preview.get("card_revealed", false)) else [], [int(_preview.get("target_id", -1))], [])


## Personen mit gesetztem öffentlichem Sitzmerkmal.
func _seat_ids_where(flag: String) -> Array:
	return (_view.get("seats", []) as Array).filter(func(s: Dictionary) -> bool: return bool(s.get(flag, false))).map(func(s: Dictionary) -> int: return int(s["person_id"]))


## Hinrichtung vorbereiten: Die Prüfung des Regelkerns läuft sofort, ihr Ergebnis steht in der Karte (kein eigener Schritt).
func _select_execution_target(person_id: int) -> void:
	_reset_day_mode()
	_preview = context.session.execution_preview(person_id)
	_day_mode = "execution_check"
	_render()


## Die Zielperson darf gewechselt werden, solange nichts enthüllt oder abgefragt wurde und es keine Spielleiterkorrektur ist.
func _can_switch_execution_target(next: Dictionary, person_id: int) -> bool:
	var candidates: Array = next.get("execution_candidates", [])
	return not _gm_execute and not bool(_preview.get("card_revealed", false)) and int(_preview.get("target_id", -1)) != person_id and candidates.has(person_id)


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
	elif key == &"show_calls":
		_render()


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
	if person_id == _committed_seat and Time.get_ticks_msec() < _committed_until:
		return  # Doppeltippen auf die eben übernommene Person wählt nicht schon im nächsten Schritt
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
			"execute":
				_select_execution_target(person_id)
				return
			"nominate_to", "name_wolf", "card_report":
				_selection = [] if _selection.has(person_id) else [person_id]
			"execution_check":
				if bool(_preview.get("card_runner_up", false)) and not _exec_extra.has("runner_up_id"):
					_selection = [] if _selection.has(person_id) else [person_id]
				elif _can_switch_execution_target(next, person_id):
					_select_execution_target(person_id)
					return
		_render()
		return
	if str(next.get("kind")) == "day" and _gm_mode == "" and (next.get("execution_candidates", []) as Array).has(person_id):
		_select_execution_target(person_id)  # Hinrichtung in zwei Tipps: Person antippen, dann „Hinrichten“
		return
	var eff := _effective(next)
	if str(eff.get("kind")) != "prompt" or str(eff.get("answer")) != "targets":
		if str(_view.get("phase", "")) != "NIGHT":
			_peek_marks(person_id)  # S-05: tagsüber zeigt ein Tipp die Abzeichen der Person kurz
		return
	if str(eff.get("owner")) == "loki" and str(eff.get("stage")) == "targets" and _loki_mode == null:
		return  # Loki: erst Liebende oder Rivalen, dann die zwei Personen
	if str(next.get("kind")) == "begin_step":
		if not _ensure_begun():
			return
		next = _view.get("next", {})
		eff = next
	var high := int(eff.get("max", 0))
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
	if CockpitText.auto_commit(eff) and _selection.size() == high and String(context.session.check_targets(_selection)) == "":
		_commit_selection(eff)  # feste Anzahl erreicht: sofort übernommen, 3 Sekunden rückgängig
		return
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
			_reset_day_mode()
			_submit(s.decide_execution.bind(target, extra))
		&"no_execution":
			_reset_day_mode()
			_submit(s.decide_execution.bind(-1))
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
			var notice_id := int(payload.get("notice_id", -1))
			open_layer(&"notice")
			_after_close = func() -> void:
				if _answer_chain([s.ack_notice.bind(notice_id)], false):
					_card.show_undo()
		&"show_roles":
			open_layer(&"roles")
		&"undo_last":
			_card.hide_undo()
			if s.undo():
				status_message_requested.emit("ui.cockpit.status.undone")
		&"loki_mode":
			_loki_mode = bool(payload["choice"])
			_render()
		&"cancel_prompt":
			_ask_reason("ui.cockpit.dialog.cancel.title", "ui.cockpit.dialog.cancel.message", "ui.cockpit.dialog.cancel.confirm",
				func(reason: String) -> void: _submit(s.cancel_prompt.bind(reason)))
		&"confirm_targets":
			if _random != null and _same_set(_selection, _random):
				_answer_chain([s.answer_random.bind((_random as Array).duplicate())])
			else:
				_answer_chain([s.answer_targets.bind(_selection.duplicate())])
		&"random_targets":
			if not _ensure_begun():
				return
			_random = s.random_proposal()
			_selection = (_random as Array).duplicate() if _random != null else []
			_render()
		&"decline":
			_answer_chain([s.answer_targets.bind([])])
		&"clear_selection":
			_selection.clear()
			_random = null
			_render()
		&"choice":
			_answer_chain([s.answer_choice.bind(bool(payload["choice"]))])
		&"option":
			_answer_chain([s.answer_option.bind(int(payload["index"]))])
		&"prediction_kind":
			_prediction["kind"] = str(payload["kind"])
			_prediction["number"] = 0
			_render()
		&"prediction_number":
			_prediction["number"] = int(payload["number"])
			_render()
		&"prediction":
			_answer_chain([s.answer_prediction.bind(str(payload["kind"]), int(payload["number"]))])
		&"show_card":
			# „Karte zeigen“ genau einmal: Das Schließen der gezeigten Karte erledigt die Auskunft (kein zweites „Gezeigt“).
			if not _ensure_begun():
				return
			var ack := str(_view.get("next", {}).get("answer")) == "ack"
			open_layer(&"show")
			if ack:
				_after_close = func() -> void: _answer_chain([s.answer_choice.bind(true)])
		&"continue_day":
			_morning_done_day = int(_view.get("day_number", 0))
			_render()
		&"override_shown":
			_ask_override()
		&"end_night":
			_dawn_decoys = []  # die Karte „Nacht abschließen“ hat die Tarnaufrufe schon genannt
			_submit(s.end_night)
		&"confirm_win":
			_submit(s.confirm_win.bind(int(payload["candidate_id"])))
		&"reject_win":
			_ask_reason("ui.cockpit.dialog.reject_win.title", "ui.cockpit.dialog.reject_win.message", "ui.cockpit.dialog.reject_win.confirm",
				func(reason: String) -> void: _submit(s.reject_win.bind(reason)))


## Das Gesicht der nächsten Handlung: bei einem Schritt mit Vorschau der Prompt, den sein Beginn öffnen würde.
## Feuerring im Sitzkreis: beim Rudelschritt alle Wölfe der Nacht, bei König Lykaon (Stufe „ally“) alle wählbaren Wölfe.
func _hunt_ids(eff: Dictionary, kind: String) -> Array:
	if kind != "prompt" and kind != "begin_step":
		return []
	if str(eff.get("role_id")) == String(CockpitView.GROUP_PACK):
		return eff.get("actor_ids", [])
	if str(eff.get("owner")) == "koenig-lykaon" and str(eff.get("stage")) == "ally":
		return eff.get("allowed_ids", [])
	return []


func _effective(next: Dictionary) -> Dictionary:
	if str(next.get("kind")) == "begin_step" and not (next.get("preview", {}) as Dictionary).is_empty():
		return next["preview"]
	return next


## Beginnt den angekündigten Schritt, wenn die Karte seinen Prompt nur als Vorschau zeigt (die erste Handlung beginnt ihn).
func _ensure_begun() -> bool:
	if str(_view.get("next", {}).get("kind")) != "begin_step":
		return true
	var r: CommandResult = context.session.begin_next_step()
	return r != null and r.ok


## Wahl übernehmen (feste Anzahl erreicht); bei Loki geht die gewählte Art der Bindung gleich mit.
func _commit_selection(eff: Dictionary) -> void:
	var s := context.session
	var picks := _selection.duplicate()
	_committed_seat = int(picks.back())
	_committed_until = Time.get_ticks_msec() + double_tap_msec
	var actions: Array[Callable] = [s.answer_targets.bind(picks)]
	if str(eff.get("owner")) == "loki" and str(eff.get("stage")) == "targets":
		actions.append(s.answer_choice.bind(bool(_loki_mode)))
		_loki_mode = null
	_answer_chain(actions)


## Antwort auf einen Prompt: der Schritt beginnt bei Bedarf, die Befehle der Kette gehen nacheinander an den Kern. Eine Zusammenfassung
## der Waldhexe wird gleich mitbestätigt (jede Antwort gilt sofort). Danach 3 Sekunden „Rückgängig“ (`with_undo`).
func _answer_chain(actions: Array[Callable], with_undo: bool = true) -> bool:
	if not _ensure_begun():
		_render()
		return false
	_card.lock()
	for a: Callable in actions:
		var result: CommandResult = a.call()
		if result == null or not result.ok:
			_render()
			return false
	var guard := 0
	while _witch_summary_open() and guard < 3:
		guard += 1
		var confirmed: CommandResult = context.session.answer_choice(true)
		if confirmed == null or not confirmed.ok:
			break
	if with_undo:
		_card.show_undo()
	_auto_advance()
	return true


func _witch_summary_open() -> bool:
	var next: Dictionary = context.session.cockpit_view().get("next", {})
	return str(next.get("kind")) == "prompt" and str(next.get("owner")) == "waldhexe" and str(next.get("stage")) == "confirm"


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
		return
	_auto_advance()


## Fenster-Diät (Markus 05.10.2026): Nach einer Handlung der Spielleitung sagt die App direkt an, statt nachzufragen. Sind alle
## Nachtschritte erledigt, endet die Nacht (Tarnaufrufe danach wandern auf die Morgenkarte); ist genau ein Sieg erreicht, gilt er.
## Nur nach eigenen Befehlen, nie nach Rückgängig oder Laden: dort bleiben die Karten „Nacht abschließen“ und „Mögliches Spielende“.
func _auto_advance() -> void:
	var s := context.session
	for guard: int in 3:
		var next: Dictionary = s.cockpit_view().get("next", {})
		var result: CommandResult = null
		match str(next.get("kind")):
			"end_night":
				_dawn_decoys = next.get("decoys", [])
				result = s.end_night()
			"win_decision" when (next.get("candidates", []) as Array).size() == 1:
				result = s.confirm_win(int((next["candidates"] as Array)[0]["id"]))
		if result == null or not result.ok:
			return


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
			_layer = CockpitLayers.log_drawer(context.session.log_lines())
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
	if _layer == null:
		_layout.visible = true
		return
	_layer_kind = kind
	_card.set_hint_suspended(true)
	GroveWindow.dress(_layer)
	_overlay_host.add_child(_layer)
	var close := _layer.find_child("CloseLayerButton", true, false) as BaseButton
	if close != null:
		close.pressed.connect(_on_layer_close_pressed)
		close.grab_focus()
	for b: Node in _layer.find_children("GmKind_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_start_gm_mode.bind(str(b.get_meta("gm_kind"))))
	for pair: Array in [["UndoButton", _ask_undo], ["RedoButton", _ask_redo], ["LeaveGameButton", _leave_game], ["DiscardGameButton", _ask_discard_game]]:
		var node := _layer.find_child(pair[0], true, false) as BaseButton
		if node != null:
			node.pressed.connect(pair[1])
	for b: Node in _layer.find_children("RolePerson_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_open_role_card.bind(int(b.get_meta("person_id"))))
	_wire_role_card()
	for b: Node in _layer.find_children("SecretAction_*", "BaseButton", true, false):
		(b as BaseButton).pressed.connect(_on_secret_action.bind(str(b.get_meta("action")), int(b.get_meta("player_id"))))


# --- Rollenanzeige ------------------------------------------------------------------------------------------
# Liste (neutral, nur Namen) → Person antippen → großes Kartenbild → Antippen schließt zurück zur Liste und gilt als „gesehen“
# (ConfirmRoleShown, nur beim ersten Mal). Die Karte mit Rolle entsteht erst beim Antippen und wird bei jedem Zustandswechsel, Undo, Laden,
# Sichtschutz und Verlassen der Ansicht verworfen; die Liste schließt nie in einen privaten Bereich.

## Öffnet die Karte einer Person: das große Bild ihrer Rollenkarte, erst nach dem Antippen der Person gebaut.
func _open_role_card(person_id: int) -> void:
	var card := context.session.role_show_card(person_id)
	if card.is_empty():
		open_layer.call_deferred(&"roles")
		return
	close_layer()
	_layer = CockpitLayers.role_card(card)
	_layer_kind = &"role_card"
	_role_card_person = person_id
	_layout.visible = false
	GroveWindow.dress(_layer)
	_overlay_host.add_child(_layer)
	_wire_role_card()
	var first := _layer.find_children("*", "BaseButton", true, false)
	if not first.is_empty():
		(first[0] as Control).grab_focus()


## Ein Tipp auf die Karte schließt sie: `ConfirmRoleButton` meldet dabei „gesehen“, `CloseRoleButton` (schon gesehen) schließt nur.
func _wire_role_card() -> void:
	if _layer == null or _layer.name != "RoleCardLayer":
		return
	var close := _layer.find_child("CloseRoleButton", true, false) as BaseButton
	if close != null:
		close.pressed.connect(open_layer.bind(&"roles"), CONNECT_DEFERRED)
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
		option.text_key = "ui.cockpit.card.target.plain"
		for entry: Dictionary in _view.get("seats", []):
			if int(entry["person_id"]) == seat:
				option.values = {"name": str(entry["name"])}
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


## Schließen über den Knopf der Ebene: Eine gezeigte Auskunft oder ein gezeigter Hinweis ist damit erledigt (`_after_close`);
## jedes andere Schließen (Zurück, neue Ebene, Zustandswechsel) verwirft die Handlung.
func _on_layer_close_pressed() -> void:
	var after := _after_close
	_after_close = Callable()
	close_layer()
	if after.is_valid():
		after.call()


func close_layer() -> void:
	_after_close = Callable()
	_tools_menu.visible = false
	if _layer != null:
		_overlay_host.remove_child(_layer)
		_layer.queue_free()
	_layer = null
	_layer_kind = &""
	_card.set_hint_suspended(false)
	_layout.visible = not _covered


## Rollenlexikon als Ebene (Werkzeug oder Kontexthilfe der privaten Karte). Liest nur Übersetzungen und Katalog: kein
## Befehl, kein Zufall, keine Ressource. Die Auswahl der offenen Karte bleibt erhalten, solange sich der Zustand nicht
## ändert (eine Änderung verwirft sie wie immer über `_on_session_changed`). Sichtschutz und Zurück schließen die Ebene.
func open_lexicon(role: StringName) -> void:
	close_layer()
	_layer = RoleLexicon.layer(context.settings, role)
	_layer_kind = &"lexicon"
	GroveWindow.dress(_layer)
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
	GroveWindow.dress(_layer)
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
	_covered = true
	_layout.visible = false
	_layer = CockpitLayers.cover_panel()
	_layer_kind = &"cover"
	GroveWindow.dress(_layer)
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
