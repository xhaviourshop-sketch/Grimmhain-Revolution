class_name ActionCard
extends VBoxContainer
## Ansagekarte des Cockpits (02 §6): baut für die nächste Handlung aus `CockpitView.next_action`
## Kontext, Vorlesetext („Sag jetzt“), Anweisung („Tu jetzt“), Auswahl und Aktionen. Ein Baustein
## für alle Prompt-Arten (Personen, Ja/Nein, Bestätigen, Option, Zeitpunkt). Reine Darstellung:
## Jede Aktion wird über `requested(action, payload)` gemeldet; die Ansicht sendet den Befehl.
##
## Geheime Karten (`secret`) zeigt die Karte außerhalb der Nacht verdeckt, bis `revealed` gesetzt
## ist. Verdeckt entstehen keine Knoten mit geheimem Inhalt.
##
## Nacht-Schablone (DA Nachtschritte neu): Titel (die Fähigkeit in 1 Satz), darunter höchstens 1 Satz Hilfe; Ansage und Aktion stehen auf
## demselben Bildschirm (ein Schritt ohne Prompt-Vorschau zeigt nur „Weiter“). Eine feste Anzahl wird vom Cockpit sofort übernommen
## (`CockpitText.auto_commit`), dann zeigt die Karte 3 Sekunden „Rückgängig“ (`show_undo`). Verzichten gibt es nur, wo die Karte es
## vorsieht (ein Knopf, „Nicht heute“). Karte zeigen genau einmal: Das Schließen der gezeigten Karte erledigt den Schritt.
##
## Aufbau: oben `Scroll` mit dem Text (`Content`), darunter der feste Bereich `Actions` mit allen Aktionsbuttons.
## Langer Text scrollt, die Aktionen bleiben immer sichtbar. Die Bedienhand bestimmt die Seite der Hauptaktion
## (rechts: Hauptaktion am rechten Ende, links: am linken); der Inhalt bleibt unverändert.

signal requested(action: StringName, payload: Dictionary)

var _busy: bool = false
var _last_next: Dictionary = {}
var _last_context: Dictionary = {}
var _fade: Tween = null
var _shown_kind: String = ""
var _content: VBoxContainer = null
var _actions_box: HFlowContainer = null
var _left_handed: bool = false
var _art: RoleCardArt = null  ## Rollenbild (nur im Cockpit gesetzt, sonst unsichtbar)
var _scroll: ScrollContainer = null  ## Textbereich der Karte
var _hint: ScrollHint = null  ## „mehr“-Hinweis, nur wenn der Text trotz kleinster Schrift scrollt
var _fit_step: int = 0  ## zuletzt nötiger Anpassungsschritt; die nächste Karte beginnt dort (weniger Flackern)
var _fit_index: int = 0  ## Schritt der laufenden Textanpassung
var _fit_wait: int = 0  ## Bilder bis zur nächsten Prüfung
var _slot: TargetSlot = null  ## Zielplatz (nur im Cockpit, bei Personenwahl): gewählte Person mit Pfeilen
var _lower: BoxContainer = null  ## Zielplatz und Aktionen: nebeneinander auf breiter Karte (mehr Platz für den Text), sonst untereinander
## Dockplatz der Hauptaktion (Cockpit, P3): Ist er gesetzt, steht der erste Button der Art PRIMARY dort („Nächster Schritt“ unten
## am Rand) statt im Aktionsbereich der Karte. Ohne Dockplatz (eigenständige Karte, Tests) bleibt alles im Aktionsbereich.
var primary_host: Control = null
## Eckplatz des „i“ (Cockpit): Ist er gesetzt, steht die Kontexthilfe der Rolle als runder Knopf mit „i“ oben rechts auf der Karte.
var info_host: Control = null
var _primary: GrimmButton = null
var _info: GrimmButton = null
var _undo_bar: HBoxContainer = null  ## „Übernommen. Rückgängig“ für wenige Sekunden nach einer sofort übernommenen Auswahl
var _undo_button: GrimmButton = null
var _undo_serial: int = 0  ## unterscheidet das laufende vom früheren Einblenden (der Ablauf des alten Timers blendet nichts aus)
var _bare: bool = false  ## Karte ohne Text: nur der große Knopf „Spiel beginnen“ (der Cockpit-Rahmen blendet den Kartenrahmen aus)

const ACTION_MIN_WIDTH := 184.0  ## Aktionen laufen in Reihen; schmaler würden umbrochene Beschriftungen unlesbar
const SIDE_BY_SIDE_WIDTH := 560.0  ## ab dieser Kartenbreite stehen Zielplatz und Nebenaktionen in einer Zeile
## Schritte der Textanpassung (Schriftfaktor, Breite des Rollenbilds): erst kleinere Schrift, dann zusätzlich ein kleineres Rollenbild (mehr Textbreite), danach Scrollen
const FIT_STEPS: Array[Vector2] = [Vector2(1.0, 104.0), Vector2(0.92, 104.0), Vector2(0.84, 88.0), Vector2(0.76, 76.0), Vector2(0.7, 64.0)]
const FIT_MIN_FONT := 15  ## kleinste Schrift des Kartentexts (logische Einheiten)
const BEGIN_BUTTON_SIZE := Vector2(460.0, 96.0)  ## „Spiel beginnen“: großer Hauptknopf statt der Startkarte (epischer Knopf, `EpicButton`)
const CARD_ACTION_MIN_WIDTH := 140.0  ## Nebenaktionen im Cockpit (Schrift kleiner), damit zwei nebeneinander passen
const UNDO_SECONDS := 3.0  ## so lange bleibt „Rückgängig“ nach einer sofort übernommenen Auswahl sichtbar
## Gruppenrufe: Die Namen der Beteiligten stehen auf der Karte (Rudel, Gebundene, Ewige, Verzauberte).
const GROUP_ROLES: Array[String] = ["pack", "die-gebundenen", "die-ewigen", "piper-all"]
## Gruppenrufe ohne geheime Auskunft: ein Bildschirm mit Namen und „Weiter“, kein „Karte zeigen“ (die Beteiligten sehen einander).
const OPEN_GROUP_OWNERS: Array[String] = ["die-gebundenen", "piper-all"]


func _init() -> void:
	var head := HBoxContainer.new()
	head.name = "Head"
	head.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(head)
	_art = RoleCardArt.new()
	_art.visible = false
	_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_art)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(scroll)
	_scroll = scroll
	_hint = ScrollHint.new()
	_hint.bind(scroll)
	add_child(_hint)
	scroll.resized.connect(_fit_text)
	_content = VBoxContainer.new()
	_content.name = "Content"
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	_slot = TargetSlot.new()
	_slot.visible = false
	_slot.stepped.connect(func(direction: int) -> void: requested.emit(&"cycle_target", {"direction": direction}))
	_undo_bar = HBoxContainer.new()
	_undo_bar.name = "UndoBar"
	_undo_bar.visible = false
	_undo_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # volle Breite, einzeilig: Text links, „Rückgängig“ rechts
	_undo_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	_undo_bar.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	var undo_label := GrimmLabel.new()
	undo_label.name = "UndoLabel"
	undo_label.text_key = "ui.night.undo.done"
	undo_label.theme_type_variation = &"MutedLabel"
	undo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo_label.wrap = false
	undo_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_undo_bar.add_child(undo_label)
	_undo_button = GrimmButton.new()
	_undo_button.name = "UndoBarButton"
	_undo_button.kind = GrimmButton.Kind.COMPACT
	_undo_button.custom_minimum_size.x = 140.0  # sonst bricht der Text Zeichen für Zeichen um und die Leiste wird hoch
	_undo_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_undo_button.text_key = "ui.night.undo.button"
	_undo_button.pressed.connect(func() -> void:
		if _undo_bar.visible and not _undo_button.disabled:
			hide_undo()
			requested.emit(&"undo_last", {}))
	_undo_bar.add_child(_undo_button)
	add_child(_undo_bar)
	_lower = BoxContainer.new()
	_lower.name = "Lower"
	_lower.vertical = true
	_lower.add_theme_constant_override(&"separation", ThemeTokens.SPACE_S)
	add_child(_lower)
	_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lower.add_child(_slot)
	_actions_box = HFlowContainer.new()
	_actions_box.name = "Actions"
	_actions_box.add_theme_constant_override(&"h_separation", ThemeTokens.SPACE_S)
	_actions_box.add_theme_constant_override(&"v_separation", ThemeTokens.SPACE_S)
	_actions_box.alignment = FlowContainer.ALIGNMENT_END
	_actions_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions_box.size_flags_stretch_ratio = 1.0
	_lower.add_child(_actions_box)
	resized.connect(func() -> void: _lower.vertical = size.x < SIDE_BY_SIDE_WIDTH)


## Sprachwechsel: Karte mit denselben Daten neu aufbauen (zusammengesetzte Texte).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _last_next.is_empty() and is_inside_tree():
		render.call_deferred(_last_next, _last_context)


## Baut die Karte neu. `context` = {phase, seats, selection, revealed, night_number, day_number}.
func render(next: Dictionary, context: Dictionary) -> void:
	_last_next = next
	_last_context = context
	_busy = false
	_fit_text.call_deferred()
	if _primary != null and is_instance_valid(_primary):
		if _primary.get_parent() != null:
			_primary.get_parent().remove_child(_primary)
		_primary.queue_free()
	_primary = null
	if _info != null and is_instance_valid(_info):
		if _info.get_parent() != null:
			_info.get_parent().remove_child(_info)
		_info.queue_free()
	_info = null
	_slot.visible = false
	_bare = false
	_content.size_flags_vertical = Control.SIZE_FILL
	_content.alignment = BoxContainer.ALIGNMENT_BEGIN
	for arrow: Node in _slot.find_children("*", "BaseButton", true, false):
		(arrow as BaseButton).disabled = false  # `lock` sperrt auch den Zielplatz bis zur nächsten Karte
	_undo_button.disabled = false
	for box: Node in [_content, _actions_box]:
		for child: Node in box.get_children():
			box.remove_child(child)
			child.queue_free()
	var kind := str(next.get("kind", "none"))
	if str(context.get("error_key", "")) != "":
		_text(str(context["error_key"]), {}, &"ErrorLabel").name = "ErrorLabel"
	if bool(next.get("secret", false)) and not bool(context.get("revealed", false)) and str(context.get("phase")) != "NIGHT":
		_covered(kind)
		return
	_fade_in(kind + str(next.get("prompt_id", "")) + str(next.get("stage", "")) + str(next.get("step_id", "")), bool(context.get("reduced_motion", false)))
	match kind:
		"start_night":
			_start_night(next, context)
		"begin_step":
			_begin_step(next, context)
		"prompt":
			_prompt(next, context)
		"notice":
			_notice(next)
		"end_night":
			_end_night(next)
		"morning":
			_morning(next)
		"gm":
			_gm(context)
		"card_window":
			_card_window(next, context)
		"day":
			_day(next, context)
		"end_day":
			_end_day(next, context)
		"win_decision":
			_win_decision(next)
		"game_over":
			_game_over(next)
		"no_game":
			_heading("ui.cockpit.instruction.heading")
			_text("ui.cockpit.instruction.no_game", {}, &"MutedLabel")
		_:
			_heading("ui.cockpit.card.none")


## Der Text unter „Sag jetzt“ und die Anweisung sind immer vollständig sichtbar: Die Karte füllt schon die ganze freie Tischmitte (sie darf
## keinen Platz verdecken), deshalb wird zuerst die Schrift schrittweise bis `FIT_MIN_FONT` verkleinert; erst wenn das nicht reicht, scrollt
## der Text, mit sichtbarem Hinweis (`ScrollHint`).
func _fit_text() -> void:
	if _scroll == null or _content == null or not is_inside_tree():
		return
	_fit_index = _fit_step
	_fit_apply()
	_fit_wait = 2  # zwei Bilder, bis Layout und Scrollleiste den neuen Stand zeigen
	set_process(true)


## Schrittweise ohne `await` (die Karte kann zwischendurch verschwinden): `_process` prüft nach jedem Schritt, ob der Text noch scrollt.
func _process(_delta: float) -> void:
	if _scroll == null or not is_instance_valid(_scroll):
		set_process(false)
		return
	_fit_wait -= 1
	if _fit_wait > 0:
		return
	var bar := _scroll.get_v_scroll_bar()
	if bar.max_value - bar.page <= 1.0 or _fit_index >= FIT_STEPS.size() - 1:
		set_process(false)  # passt, oder die kleinste Schrift ist erreicht (dann scrollt der Text mit Hinweis)
		return
	_fit_index += 1
	_fit_apply()
	_fit_wait = 2


func _fit_apply() -> void:
	_fit_step = _fit_index
	var step := FIT_STEPS[_fit_index]
	_art.custom_minimum_size = Vector2(step.y, step.y / RoleCardArt.FRAME_ASPECT)
	var tight := _fit_index >= 3  # letzte Schritte: auch die Abstände zwischen den Zeilen und zum Aktionsbereich schrumpfen
	_content.add_theme_constant_override(&"separation", 1 if tight else 4)
	_lower.add_theme_constant_override(&"separation", 2 if tight else ThemeTokens.SPACE_S)
	for label: Node in _content.find_children("*", "Label", true, false):
		if not label.has_meta(&"base_font"):
			label.set_meta(&"base_font", (label as Label).get_theme_font_size(&"font_size"))
		var base: int = label.get_meta(&"base_font")
		(label as Label).add_theme_font_size_override(&"font_size", base if step.x >= 1.0 else maxi(mini(base, FIT_MIN_FONT), roundi(float(base) * step.x)))


## Kurzes Einblenden bei einer neuen Handlung (nicht bei Auswahländerungen derselben Karte). Abbrechbar:
## ein neues Rendern beendet das laufende Einblenden; bei reduzierter Bewegung kein Einblenden.
func _fade_in(identity: String, reduced: bool) -> void:
	if identity != _shown_kind:
		_fit_step = 0  # neue Karte: wieder mit der größten Schrift beginnen
	if _fade != null and _fade.is_valid():
		_fade.kill()
	modulate.a = 1.0
	if identity == _shown_kind or reduced or not is_inside_tree():
		_shown_kind = identity
		return
	_shown_kind = identity
	modulate.a = 0.0
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 1.0, ThemeTokens.CARD_FADE_SECONDS)


## Bedienhand (Einstellung): setzt die Seite der Hauptaktion im festen Aktionsbereich. Ändert weder Inhalt noch Reihenfolge der Texte.
func set_left_handed(left: bool) -> void:
	if left == _left_handed:
		return
	_left_handed = left
	_apply_hand(true)


## Aktionsbuttons in Bauart-Reihenfolge (Hauptaktion zuerst), die auch die Tab-Reihenfolge der Linkshänder bleibt.
func action_buttons() -> Array[BaseButton]:
	var out: Array[BaseButton] = []
	for b: Node in _actions_box.get_children():
		if b is BaseButton and not b.is_queued_for_deletion():
			out.append(b as BaseButton)
	if not _left_handed:
		out.reverse()
	if _primary != null and is_instance_valid(_primary) and not _primary.is_queued_for_deletion():
		out.push_front(_primary)
	return out


## Rollenbild der Karte; die Ansicht setzt die Rolle (nur Nacht, nicht verborgen).
func role_art() -> RoleCardArt:
	return _art


## Hauptaktion im Dockplatz (oder null).
func primary_button() -> GrimmButton:
	return _primary if _primary != null and is_instance_valid(_primary) and not _primary.is_queued_for_deletion() else null


## Rechtshänder: Hauptaktion am rechten Ende, also Reihenfolge der Bauart umgekehrt; Linkshänder: wie gebaut.
func _apply_hand(reorder: bool) -> void:
	_actions_box.alignment = FlowContainer.ALIGNMENT_BEGIN if _left_handed else FlowContainer.ALIGNMENT_END
	if reorder:
		var children := _actions_box.get_children()
		children.reverse()
		for i: int in children.size():
			_actions_box.move_child(children[i], i)


## Sperrt alle Aktionen bis zum nächsten `render` (Schutz gegen Mehrfachtippen).
func lock() -> void:
	_busy = true
	for b: Node in find_children("*", "BaseButton", true, false):
		if b != _undo_button:
			(b as BaseButton).disabled = true
	if _primary != null and is_instance_valid(_primary):
		_primary.disabled = true
	if _info != null and is_instance_valid(_info):
		_info.disabled = true


## Blendet „Übernommen. Rückgängig“ für `UNDO_SECONDS` ein; ein erneutes Einblenden startet die Zeit neu.
func show_undo(seconds: float = UNDO_SECONDS) -> void:
	_undo_serial += 1
	var serial := _undo_serial
	_undo_bar.visible = true
	_undo_button.disabled = false
	if not is_inside_tree():
		return
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if serial == _undo_serial:
			hide_undo())


func hide_undo() -> void:
	_undo_serial += 1
	if _undo_bar != null:
		_undo_bar.visible = false


func undo_visible() -> bool:
	return _undo_bar != null and _undo_bar.visible


# --- Kartenarten ------------------------------------------------------------------------------------

## Verdeckte Karte (S-07, DA-93): ein einheitlicher Text für jede Art, der nichts über den Inhalt verrät.
func _covered(_kind: String) -> void:
	_heading("ui.cockpit.secret.heading")
	_text("ui.cockpit.secret.step", {}, &"MutedLabel")
	_actions([_button("RevealButton", "ui.cockpit.secret.reveal", GrimmButton.Kind.PRIMARY, &"reveal")])


## Wahr, solange die Karte nur den großen Knopf „Spiel beginnen“ zeigt.
func is_bare() -> bool:
	return _bare


## Spielbeginn: kein Textkasten, nur der große epische Knopf (Lava pulsiert). Rollen zeigen bleibt als Nebenknopf darunter.
func _begin_game() -> void:
	_bare = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	var big := _button("StartNightButton", "ui.cockpit.action.begin_game", GrimmButton.Kind.PRIMARY, &"start_night")
	big.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	big.custom_minimum_size = BEGIN_BUTTON_SIZE
	EpicButton.apply(big, not bool(_last_context.get("reduced_motion", false)))
	_content.add_child(big)
	_primary = big  # Hauptaktion der Karte (Fokus, Tests), steht aber mittig statt im Dock
	_actions([_button("ShowRolesButton", "ui.cockpit.action.show_roles", GrimmButton.Kind.SECONDARY, &"show_roles")])


func _start_night(next: Dictionary, context: Dictionary) -> void:
	if bool(next.get("first")) and not bool(next.get("revival_round", false)):
		_begin_game()
		return
	_heading("ui.cockpit.card.start_night.heading", {"number": int(context.get("night_number", 0)) + 1})
	_read_aloud("ui.call.night_falls_revival" if bool(next.get("revival_round", false)) else "ui.call.night_falls", {})
	_text("ui.cockpit.card.start_night.do" if bool(next.get("first")) else "ui.cockpit.card.start_night.do_next")
	var buttons: Array[Control] = [_button("StartNightButton", "ui.cockpit.action.start_night", GrimmButton.Kind.PRIMARY, &"start_night")]
	if bool(next.get("first")):
		# Optional, keine Voraussetzung für die erste Nacht: Rollen gezielt zeigen.
		buttons.append(_button("ShowRolesButton", "ui.cockpit.action.show_roles", GrimmButton.Kind.SECONDARY, &"show_roles"))
	_actions(buttons)


## Tarnaufrufe (DI-02): Rollen, die vor dem nächsten echten Schritt nur angesagt werden. Sie führen nichts aus; die Karte nennt sie
## in einer Zeile.
func _decoys(next: Dictionary) -> void:
	var roles: Array = next.get("decoys", [])
	if roles.is_empty():
		return
	var names: Array = roles.map(func(role: Variant) -> String: return tr(CockpitText.role_name(str(role))))
	_text("ui.night.decoys", {"roles": ", ".join(names)}, &"MutedLabel").name = "DecoyLine"


## Hinweis an betroffene Personen (DI-04, DI-06, DI-07): „Karte zeigen“ genau einmal; das Schließen der Karte bestätigt den Hinweis.
func _notice(next: Dictionary) -> void:
	var names: Array = (next.get("viewers", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
	_heading("ui.night.notice.title", {"names": ", ".join(names)}).name = "NoticeTitle"
	_text("ui.night.notice.help", {}, &"MutedLabel")
	var buttons: Array[Control] = [_button("ShowNoticeButton", "ui.cockpit.action.show_notice", GrimmButton.Kind.PRIMARY, &"show_notice", {"notice_id": int(next.get("notice_id", -1))})]
	_help(next, buttons)
	_actions(buttons)


## Ein Schritt, der einen Prompt öffnet, zeigt Ansage und Aktion auf einem Bildschirm (Vorschau des Prompts); `BeginStep` sendet das
## Cockpit mit der ersten Handlung. Nur ein Schritt ohne Prompt (er entfällt oder endet sofort) hat die Karte mit „Weiter“.
func _begin_step(next: Dictionary, context: Dictionary) -> void:
	var preview: Dictionary = next.get("preview", {})
	if not preview.is_empty():
		var merged := preview.duplicate()
		merged["decoys"] = next.get("decoys", [])
		merged["needs_begin"] = true
		merged["step_kind"] = next.get("step_kind", "")
		merged["repeat"] = next.get("repeat", false)
		merged["own_role_id"] = next.get("own_role_id", merged.get("role_id", ""))
		_prompt(merged, context)
		return
	var role := str(next.get("role_id"))
	_decoys(next)
	_heading("ui.cockpit.card.role_title", {"role": CockpitText.role_name(role)})
	if role != str(next.get("own_role_id", role)) and str(next.get("own_role_id", "")) != "":
		_text("ui.cockpit.card.borrowed_ability", {"role": CockpitText.role_name(str(next["own_role_id"]))}, &"WarningLabel")
	if str(next.get("step_kind")) != "reaction":
		_text(CockpitText.call_key(role), {"role": CockpitText.role_name(role)}, &"ReadAloudLabel")
	var buttons: Array[Control] = [_button("BeginStepButton", "ui.cockpit.action.begin_step", GrimmButton.Kind.PRIMARY, &"begin_step")]
	_help(next, buttons)
	_actions(buttons)


func _prompt(next: Dictionary, context: Dictionary) -> void:
	if str(next.get("owner")) == "card":
		_card_prompt(next, context)
	else:
		_night_prompt(next, context)


## Nacht-Schablone eines Rollenprompts (auch Reaktionen, Kartenschlucker und die erste Stufe eines noch nicht begonnenen Schritts).
func _night_prompt(next: Dictionary, context: Dictionary) -> void:
	var role := str(next.get("role_id"))
	var owner := str(next.get("owner"))
	var stage := str(next.get("stage"))
	var answer := str(next.get("answer"))
	var anonymous := bool(next.get("anonymous_asker", false))
	# Loki entscheidet zuerst Liebende oder Rivalen, dann folgen die zwei Personen (die Antwort geht gemeinsam an den Kern).
	var pre_mode := owner == "loki" and stage == "targets" and context.get("pre_choice") == null
	var texts := next.duplicate()
	if pre_mode:
		texts["stage"] = "mode"
	_decoys(next)
	_heading(CockpitText.night_title_key(texts), {"role": CockpitText.role_name(role)}).name = "NightTitle"
	_text(CockpitText.night_help_key(texts), {}, &"MutedLabel").name = "NightHelp"
	if anonymous:  # Zuflucht: die gefragte Person steht auf der Karte, die fragende Person und die Rolle nicht
		_text("ui.night.rotkaeppchen.grant.asked", {"names": CockpitText.names_of(next.get("actor_ids", []), context.get("seats", []))}, &"SectionLabel").name = "AskedName"
		_text("ui.night.rotkaeppchen.grant.hint", {}, &"MutedLabel").name = "RefugeHint"
	if GROUP_ROLES.has(role) and not anonymous:
		var group := CockpitText.names_of(next.get("actor_ids", []), context.get("seats", []))
		if group != "":
			_text("ui.night.names", {"names": group}, &"SectionLabel").name = "GroupNames"
	if role != str(next.get("own_role_id", role)) and str(next.get("own_role_id", "")) != "":
		_text("ui.cockpit.card.borrowed_ability", {"role": CockpitText.role_name(str(next["own_role_id"]))}, &"WarningLabel")
	if bool(next.get("repeat", false)):
		_text("ui.cockpit.card.repeat", {}, &"WarningLabel")
	for line: Dictionary in next.get("info", []):
		if anonymous:
			break
		_text("ui.cockpit.card.info_line", {"label": StringName(CockpitText.info_key(str(line["key"]))), "value": CockpitText.info_value(line)}, &"WarningLabel")
	if str(context.get("call_step", "")) != "" and str(next.get("step_id", "")) == str(context.get("call_step")) and owner != "reaction" and role != "":
		_text(CockpitText.call_key(role), {"role": CockpitText.role_name(role)}, &"ReadAloudLabel").name = "CallLine"
	if owner == "kartenschlucker":
		_swallower_status(next)
	var buttons: Array[Control] = []
	if pre_mode:
		# Beide Antworten stehen in der Karte (nicht die erste im Dock unten rechts).
		buttons.append(_button("YesButton", CockpitText.action_key("yes", owner, "mode"), GrimmButton.Kind.SECONDARY, &"loki_mode", {"choice": true}))
		buttons.append(_button("NoButton", CockpitText.action_key("no", owner, "mode"), GrimmButton.Kind.SECONDARY, &"loki_mode", {"choice": false}))
		_help(next, buttons)
		_actions(buttons)
		return
	match answer:
		"targets":
			_night_targets_part(next, context, buttons)
		"choice":
			buttons.append(_button("YesButton", CockpitText.action_key("yes", owner, stage), GrimmButton.Kind.PRIMARY, &"choice", {"choice": true}))
			buttons.append(_button("NoButton", CockpitText.action_key("no", owner, stage), GrimmButton.Kind.SECONDARY, &"choice", {"choice": false}))
		"ack":
			if not (next.get("show", []) as Array).is_empty() and not OPEN_GROUP_OWNERS.has(owner):
				buttons.append(_button("ShowCardButton", "ui.cockpit.action.show_card", GrimmButton.Kind.PRIMARY, &"show_card"))
			else:
				buttons.append(_button("AckButton", "ui.night.action.next", GrimmButton.Kind.PRIMARY, &"choice", {"choice": true}))
		"option":
			var options: Array = next.get("options", [])
			var option_kind := str(next.get("option_kind", ""))
			for i: int in options.size():
				if option_kind != "" and option_kind != "role":
					# Handzeichen des Kartenschluckers: eigene Beschriftung je Option.
					buttons.append(_button("OptionButton_%d" % i, CockpitText.card_option_key(option_kind, str(options[i])), GrimmButton.Kind.SECONDARY, &"option", {"index": i}))
					continue
				var b := _button("OptionButton_%d" % i, "ui.cockpit.action.option", GrimmButton.Kind.SECONDARY, &"option", {"index": i})
				b.format_values = {"number": i + 1, "role": CockpitText.role_name(str(options[i]))}
				buttons.append(b)
		"prediction":
			_prediction_part(next, context, buttons)
	if bool(next.get("can_override_shown", false)):
		buttons.append(_button("OverrideShownButton", "ui.cockpit.action.override_shown", GrimmButton.Kind.SECONDARY, &"override_shown"))
	_help(next, buttons)
	_actions(buttons)


## Auswahl der Nacht-Schablone: eine feste Anzahl wird sofort übernommen (kein Bestätigen), sonst „Weiter“. Antippen einer
## gewählten Person wählt sie ab. Verzichten nur, wenn der Kern die Anzahl 0 zulässt.
func _night_targets_part(next: Dictionary, context: Dictionary, buttons: Array[Control]) -> void:
	var selection: Array = context.get("selection", [])
	var counts: Array = next.get("counts", [])
	var error := str(context.get("selection_error", ""))
	var auto := CockpitText.auto_commit(next)
	if not selection.is_empty() and not auto:
		_text("ui.night.selected", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel").name = "SelectionLabel"
	if not selection.is_empty() and error != "":
		var key := "ui.cockpit.card.selection.blocked.%s" % error
		_text(key if CockpitText.has_key(key) else "ui.cockpit.card.selection.blocked.generic", {"counts": CockpitText.count_list(counts)}, &"WarningLabel").name = "SelectionBlockedLabel"
	if not auto:
		_show_slot(next, context, selection)
	var random_active := bool(context.get("random_active", false))
	if random_active:
		# Vorschlag der Zufallsziehung; übernommen wird er erst mit „Weiter“ (RM-DR-015.2).
		_text("ui.cockpit.card.random.proposal", {}, &"MutedLabel").name = "RandomProposalLabel"
	if not auto:
		var confirm := _button("ConfirmTargetsButton", "ui.cockpit.action.confirm_targets", GrimmButton.Kind.PRIMARY, &"confirm_targets")
		confirm.disabled = (selection.is_empty() and not random_active) or error != ""
		buttons.append(confirm)
	if bool(next.get("random", false)):
		var random := _button("RandomTargetsButton", "ui.cockpit.action.random_targets", GrimmButton.Kind.SECONDARY, &"random_targets")
		random.disabled = not bool(context.get("random_available", false))
		buttons.append(random)
		if random.disabled:
			_text("ui.cockpit.card.random.none", {}, &"MutedLabel").name = "RandomUnavailableLabel"
	if counts.has(0):
		buttons.append(_button("DeclineButton", CockpitText.action_key("decline", str(next.get("owner")), str(next.get("stage"))), GrimmButton.Kind.SECONDARY, &"decline"))


## Eingabekette einer Totenreichkarte (Kartenfenster-Aufgaben): unverändert die Karte „Tu jetzt“ mit Bestätigen.
func _card_prompt(next: Dictionary, context: Dictionary) -> void:
	var role := str(next.get("role_id"))
	var answer := str(next.get("answer"))
	_decoys(next)
	_caption("ui.cockpit.card.prompt.caption")
	_card_prompt_head(next)
	var actors := CockpitText.names_of(next.get("actor_ids", []), context.get("seats", []))
	if actors != "":
		_text("ui.cockpit.card.actors", {"names": actors}, &"MutedLabel")
	_text(CockpitText.card_instruction_key(next), {"min": int(next.get("min", 0)), "max": int(next.get("max", 0))})
	if not (next.get("dice", []) as Array).is_empty():
		_dice(next.get("dice", []))
	var buttons: Array[Control] = []
	match answer:
		"targets":
			_targets_part(next, context, buttons)
		"choice":
			var owner := str(next.get("owner"))
			var stage := str(next.get("stage"))
			buttons.append(_button("YesButton", CockpitText.action_key("yes", owner, stage), GrimmButton.Kind.PRIMARY, &"choice", {"choice": true}))
			buttons.append(_button("NoButton", CockpitText.action_key("no", owner, stage), GrimmButton.Kind.SECONDARY, &"choice", {"choice": false}))
		"ack":
			buttons.append(_button("AckButton", "ui.cockpit.action.ack.%s" % str(next.get("stage")), GrimmButton.Kind.PRIMARY, &"choice", {"choice": true}))
		"option":
			var options: Array = next.get("options", [])
			var option_kind := str(next.get("option_kind", ""))
			for i: int in options.size():
				if option_kind != "" and option_kind != "role":
					buttons.append(_button("OptionButton_%d" % i, CockpitText.card_option_key(option_kind, str(options[i])), GrimmButton.Kind.SECONDARY, &"option", {"index": i}))
					continue
				var b := _button("OptionButton_%d" % i, "ui.cockpit.action.option", GrimmButton.Kind.SECONDARY, &"option", {"index": i})
				b.format_values = {"number": i + 1, "role": CockpitText.role_name(str(options[i]))}
				buttons.append(b)
		"roll":
			var roll := _button("RollButton", "ui.cards.action.roll", GrimmButton.Kind.PRIMARY, &"roll")
			roll.format_values = {"count": int(next.get("dice_count", 1))}
			buttons.append(roll)
		"prediction":
			_prediction_part(next, context, buttons)
	if bool(next.get("cancellable", false)):
		# Kurze Beschriftung, damit sie neben einem zweiten Knopf einzeilig bleibt; Bedienungshilfe und Tooltip tragen den vollen Text.
		var cancel := _button("CancelPromptButton", "ui.cockpit.action.cancel_prompt.short", GrimmButton.Kind.SECONDARY, &"cancel_prompt")
		cancel.tooltip_text = tr("ui.cockpit.action.cancel_prompt")
		cancel.accessibility_name = cancel.tooltip_text
		buttons.append(cancel)
	_help(next, buttons)
	_actions(buttons)


func _targets_part(next: Dictionary, context: Dictionary, buttons: Array[Control]) -> void:
	var selection: Array = context.get("selection", [])
	var counts: Array = next.get("counts", [])
	var error := str(context.get("selection_error", ""))
	# Zulässige Anzahl und Sperrgrund stammen aus dem Regelkern (counts, check_targets).
	_text("ui.cockpit.card.selection.counts", {"counts": CockpitText.count_list(counts)}, &"MutedLabel").name = "SelectionRuleLabel"
	if selection.is_empty():
		_text("ui.cockpit.card.selection.none", {}, &"MutedLabel").name = "SelectionLabel"
	else:
		_text("ui.cockpit.card.selection.some", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel").name = "SelectionLabel"
	if not selection.is_empty() and error != "":
		var key := "ui.cockpit.card.selection.blocked.%s" % error
		_text(key if CockpitText.has_key(key) else "ui.cockpit.card.selection.blocked.generic", {"counts": CockpitText.count_list(counts)}, &"WarningLabel").name = "SelectionBlockedLabel"
	_show_slot(next, context, selection)
	var random_active := bool(context.get("random_active", false))
	if random_active:
		# Vorschlag der Zufallsziehung; übernommen wird er erst mit „Auswahl bestätigen“ (RM-DR-015.2).
		_text("ui.cockpit.card.random.proposal", {}, &"MutedLabel").name = "RandomProposalLabel"
	var confirm := _button("ConfirmTargetsButton", "ui.cockpit.action.confirm_targets", GrimmButton.Kind.PRIMARY, &"confirm_targets")
	confirm.disabled = (selection.is_empty() and not random_active) or error != ""
	buttons.append(confirm)
	if bool(next.get("random", false)):
		var random := _button("RandomTargetsButton", "ui.cockpit.action.random_targets", GrimmButton.Kind.SECONDARY, &"random_targets")
		random.disabled = not bool(context.get("random_available", false))
		buttons.append(random)
		if random.disabled:
			_text("ui.cockpit.card.random.none", {}, &"MutedLabel").name = "RandomUnavailableLabel"
	if counts.has(0):
		buttons.append(_button("DeclineButton", CockpitText.action_key("decline", str(next.get("owner")), str(next.get("stage"))), GrimmButton.Kind.SECONDARY, &"decline"))
	if not selection.is_empty():
		buttons.append(_button("ClearSelectionButton", "ui.cockpit.action.clear_selection", GrimmButton.Kind.SECONDARY, &"clear_selection"))


## Zielplatz im festen Bereich der Karte: gewählte Person (Einzelwahl) bzw. Namensliste (Mehrfachwahl). Nur im Cockpit (mit Dockplatz).
func _show_slot(next: Dictionary, context: Dictionary, selection: Array) -> void:
	if primary_host == null:
		return
	var seats: Array = context.get("seats", [])
	var single := int(next.get("max", 0)) == 1
	var chosen := {}
	if single and not selection.is_empty():
		for seat: Variant in seats:
			if int((seat as Dictionary)["person_id"]) == int(selection[0]):
				chosen = seat
	var names := "" if single else (CockpitText.names_of(selection, seats) if not selection.is_empty() else tr("ui.cockpit.card.target.none"))
	_slot.show_selection(chosen, names, single and (next.get("allowed_ids", []) as Array).size() > 1)
	_slot.visible = true


func _prediction_part(next: Dictionary, context: Dictionary, buttons: Array[Control]) -> void:
	var minimum: Dictionary = next.get("prediction_min", {})
	var kind := str(context.get("prediction_kind", "night"))
	var number := maxi(int(context.get("prediction_number", 0)), int(minimum.get(kind, 1)))
	_text("ui.cockpit.card.prediction.value", {"when": StringName("ui.cockpit.card.prediction.%s" % kind), "number": number}, &"SectionLabel")
	buttons.append(_button("PredictionNightButton", "ui.cockpit.card.prediction.night", GrimmButton.Kind.SECONDARY, &"prediction_kind", {"kind": "night"}))
	buttons.append(_button("PredictionDayButton", "ui.cockpit.card.prediction.day", GrimmButton.Kind.SECONDARY, &"prediction_kind", {"kind": "day"}))
	buttons.append(_button("PredictionMinusButton", "ui.cockpit.card.prediction.minus", GrimmButton.Kind.SECONDARY, &"prediction_number", {"number": maxi(number - 1, int(minimum.get(kind, 1)))}))
	buttons.append(_button("PredictionPlusButton", "ui.cockpit.card.prediction.plus", GrimmButton.Kind.SECONDARY, &"prediction_number", {"number": number + 1}))
	buttons.append(_button("ConfirmPredictionButton", "ui.cockpit.action.confirm_prediction", GrimmButton.Kind.PRIMARY, &"prediction", {"kind": kind, "number": number}))


func _end_night(next: Dictionary) -> void:
	_decoys(next)
	_heading("ui.cockpit.card.end_night.heading")
	if int(next.get("skipped", 0)) > 0:
		_text("ui.cockpit.card.end_night.skipped", {"count": int(next["skipped"])}, &"WarningLabel")
	_text("ui.cockpit.card.end_night.do")
	_actions([_button("EndNightButton", "ui.cockpit.action.end_night", GrimmButton.Kind.PRIMARY, &"end_night")])


## Morgenbericht: Vorlesetext aus dem öffentlichen Teil, zeigbare Ansagekarte, private Details.
func _morning(next: Dictionary) -> void:
	_caption("ui.cockpit.card.morning.caption", {"number": int(next.get("night_number", 0))})
	_heading("ui.cockpit.card.morning.heading")
	_caption("ui.cockpit.card.say_now")
	for line: Dictionary in CockpitText.morning_lines(next.get("public", {})):
		_text(str(line["key"]), line["values"], &"ReadAloudLabel")
	_actions([
		_button("ContinueDayButton", "ui.cockpit.action.continue_day", GrimmButton.Kind.PRIMARY, &"continue_day"),
		_button("ShowAnnouncementButton", "ui.cockpit.action.show_announcement", GrimmButton.Kind.SECONDARY, &"show_announcement"),
		_button("MorningDetailsButton", "ui.cockpit.action.morning_details", GrimmButton.Kind.SECONDARY, &"morning_details"),
	])


## Tag: Nominierungen (öffentlich), heutige Tode, Aktionen. Unterzustände der Bedienung kommen aus
## `context.day_mode` (Nominierung in zwei Schritten, Hinrichtung wählen, verdeckte Prüfung).
func _day(next: Dictionary, context: Dictionary) -> void:
	match str(context.get("day_mode", "")):
		"nominate_from", "nominate_to":
			_day_nominate(context)
			return
		"execute":
			_day_pick(context, "ui.cockpit.card.day.execute.heading", "ui.cockpit.card.day.execute.do", "ConfirmExecutionTargetButton", "ui.cockpit.action.check_execution", &"check_execution")
			return
		"name_wolf":
			_day_pick(context, "ui.cockpit.card.day.name_wolf.heading", "ui.cockpit.card.day.name_wolf.do", "ConfirmNameWolfButton", "ui.cockpit.action.confirm_name_wolf", &"confirm_name_wolf")
			return
		"card_report":
			_day_pick(context, "ui.cards.report.heading", "ui.cards.report.do", "ConfirmCardReportButton", "ui.cards.action.confirm_report", &"confirm_card_report")
			return
		"execution_check":
			_execution_check(context)
			return
	_heading("ui.cockpit.card.day.heading", {"number": int(context.get("day_number", 0))})
	_day_public(next, context)
	var extra_buttons: Array[Control] = []
	_card_rules(next.get("card_rules", []), extra_buttons)
	if bool(next.get("execution_cancelled", false)):
		_text("ui.cards.exec.cancelled", {}, &"WarningLabel").name = "ExecutionCancelledLabel"
	if bool(next.get("dead_nominate", false)):
		_text("ui.cards.exec.dead_nominate", {}, &"WarningLabel").name = "DeadNominateLabel"
	_text("ui.cockpit.card.day.do", {}, &"MutedLabel")
	var execute := _button("ExecuteButton", "ui.cockpit.action.execute", GrimmButton.Kind.PRIMARY, &"start_execute")
	execute.disabled = (next.get("execution_candidates", []) as Array).is_empty() or bool(next.get("execution_cancelled", false))
	var day_buttons: Array[Control] = [
		_button("NominateButton", "ui.cockpit.action.nominate", GrimmButton.Kind.SECONDARY, &"start_nominate"),
		execute,
		_button("NoExecutionButton", "ui.cockpit.action.no_execution", GrimmButton.Kind.SECONDARY, &"no_execution"),
	]
	day_buttons.append_array(extra_buttons)
	if bool(next.get("cards", false)):
		day_buttons.append(_button("CardOverviewButton", "ui.cards.action.overview", GrimmButton.Kind.COMPACT, &"card_overview"))
	_actions(day_buttons)


func _day_public(next: Dictionary, context: Dictionary) -> void:
	var nominations: Array = next.get("nominations", [])
	if nominations.is_empty():
		_text("ui.cockpit.card.day.no_nominations", {}, &"MutedLabel")
	else:
		_caption("ui.cockpit.card.day.nominations")
		var seats: Array = context.get("seats", [])
		for n: Dictionary in nominations:
			var nominee := CockpitText.names_of([int(n["nominee_id"])], seats)
			if int(n["nominator_id"]) == -1:
				_text("ui.cockpit.card.day.nomination_hidden", {"nominee": nominee}, &"SectionLabel")
			else:
				_text("ui.cockpit.card.day.nomination", {"nominator": CockpitText.names_of([int(n["nominator_id"])], seats), "nominee": nominee}, &"SectionLabel")
	var deaths: Array = context.get("day_deaths", [])
	var effects: Array = context.get("day_effects", [])
	if not deaths.is_empty() or not effects.is_empty():
		_caption("ui.cockpit.card.say_now")
	if not deaths.is_empty():
		_text("ui.cockpit.card.day.deaths", {"names": CockpitText.spoken_names(deaths)}, &"ReadAloudLabel")
	for e: Dictionary in effects:
		var line := CockpitText.effect_line(e)
		_text(str(line["key"]), line["values"], &"ReadAloudLabel")
	var card_lines: Array = CockpitText.card_lines(context.get("day_cards", []))
	if not card_lines.is_empty() and deaths.is_empty() and effects.is_empty():
		_caption("ui.cockpit.card.say_now")
	for line: Dictionary in card_lines:
		_text(str(line["key"]), line["values"], &"ReadAloudLabel")


func _day_nominate(context: Dictionary) -> void:
	var seats: Array = context.get("seats", [])
	var from := int(context.get("nominator", -1))
	_heading("ui.cockpit.card.day.nominate.heading")
	if str(context.get("day_mode")) == "nominate_from":
		_text("ui.cockpit.card.day.nominate.from", {}, &"SectionLabel")
		_actions([_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])
		return
	_text("ui.cockpit.card.day.nominate.to", {"nominator": CockpitText.names_of([from], seats)}, &"SectionLabel")
	var selection: Array = context.get("selection", [])
	if not selection.is_empty():
		_text("ui.cockpit.card.day.nominate.summary", {"nominator": CockpitText.names_of([from], seats), "nominee": CockpitText.names_of(selection, seats)}, &"SectionLabel")
	var confirm := _button("ConfirmNominationButton", "ui.cockpit.action.confirm_nomination", GrimmButton.Kind.PRIMARY, &"confirm_nomination")
	confirm.disabled = selection.is_empty()
	_actions([confirm, _button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])


func _day_pick(context: Dictionary, heading: String, instruction: String, confirm_name: String, confirm_key: String, action: StringName) -> void:
	_heading(heading)
	_text(instruction, {}, &"MutedLabel")
	var selection: Array = context.get("selection", [])
	if selection.is_empty():
		_text("ui.cockpit.card.selection.none", {}, &"MutedLabel")
	else:
		_text("ui.cockpit.card.selection.some", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel")
	var confirm := _button(confirm_name, confirm_key, GrimmButton.Kind.PRIMARY, action)
	confirm.disabled = selection.is_empty()
	_actions([confirm, _button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])


## Verdeckte Prüfung jeder Hinrichtung: Vorschau des Regelkerns und seine Pflichtfragen. Verdeckt,
## bis die Spielleitung aufdeckt, damit ihr Auftauchen nichts über die Rolle verrät.
func _execution_check(context: Dictionary) -> void:
	var seats: Array = context.get("seats", [])
	var preview: Dictionary = context.get("preview", {})
	var target := CockpitText.names_of([int(preview.get("target_id", -1))], seats)
	_heading("ui.cockpit.card.day.check.heading", {"name": target})
	if not bool(context.get("revealed", false)):
		_text("ui.cockpit.card.day.check.covered", {}, &"MutedLabel")
		_actions([_button("RevealButton", "ui.cockpit.secret.reveal", GrimmButton.Kind.PRIMARY, &"reveal"),
			_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode")])
		return
	var extra: Dictionary = context.get("exec_extra", {})
	var ready := true
	var buttons: Array[Control] = []
	if bool(preview.get("redirected", false)):
		_text("ui.cockpit.card.day.check.redirected", {"name": CockpitText.names_of([int(preview["death_target_id"])], seats)}, &"WarningLabel")
	elif not bool(preview.get("needs_cerberus", false)) and not bool(preview.get("needs_sage", false)) and not _card_exec_notes(preview, seats):
		_text("ui.cockpit.card.day.check.plain", {"name": target}, &"MutedLabel")
	if bool(preview.get("needs_cerberus", false)):
		_text("ui.cockpit.card.day.check.cerberus", {}, &"WarningLabel")
		ready = ready and extra.has("cerberus_defend")
		for choice: bool in [true, false]:
			var b := _button("CerberusDefend%s" % ("Yes" if choice else "No"), "ui.cockpit.action.cerberus.%s" % ("yes" if choice else "no"),
				GrimmButton.Kind.SECONDARY, &"exec_extra", {"field": "cerberus_defend", "value": choice})
			if extra.get("cerberus_defend") == choice:
				b.kind = GrimmButton.Kind.PRIMARY
			buttons.append(b)
	if bool(preview.get("needs_sage", false)):
		_text("ui.cockpit.card.day.check.sage", {"max": int(preview.get("sage_max", 0))}, &"WarningLabel")
		ready = ready and extra.has("sage_curse")
		for n: int in int(preview.get("sage_max", 0)) + 1:
			var b := _button("SageCurse%d" % n, "ui.cockpit.action.sage_curse", GrimmButton.Kind.SECONDARY, &"exec_extra", {"field": "sage_curse", "value": n})
			b.format_values = {"count": n}
			if extra.has("sage_curse") and int(extra["sage_curse"]) == n:
				b.kind = GrimmButton.Kind.PRIMARY
			buttons.append(b)
	# Totenreichkarten: Enthüllung vor dem Vollzug (Wachsame Augen) und Entscheid des Dorfes, zweitmeiste Stimmen (Kettenreaktion).
	var confirm_key := "ui.cockpit.action.confirm_execution"
	if bool(preview.get("card_reveal", false)):
		if not bool(preview.get("card_revealed", false)):
			_text("ui.cards.exec.reveal", {}, &"WarningLabel").name = "CardRevealLabel"
			confirm_key = "ui.cards.action.reveal_role"
		else:
			_text("ui.cards.exec.village_decides", {}, &"WarningLabel").name = "VillageDecidesLabel"
			ready = ready and extra.has("village_confirms")
			for choice: bool in [true, false]:
				var b := _button("VillageConfirms%s" % ("Yes" if choice else "No"), "ui.cards.action.village.%s" % ("yes" if choice else "no"),
					GrimmButton.Kind.PRIMARY if extra.get("village_confirms") == choice else GrimmButton.Kind.SECONDARY, &"exec_extra", {"field": "village_confirms", "value": choice})
				buttons.append(b)
	if bool(preview.get("card_runner_up", false)) and (not bool(preview.get("card_reveal", false)) or bool(preview.get("card_revealed", false))):
		var picked: Array = context.get("selection", [])
		if extra.has("runner_up_id"):
			_text("ui.cards.exec.runner_up_set", {"name": CockpitText.names_of([int(extra["runner_up_id"])], seats) if int(extra["runner_up_id"]) != -1 else "–"}, &"SectionLabel").name = "RunnerUpLabel"
		else:
			_text("ui.cards.exec.runner_up", {}, &"WarningLabel").name = "RunnerUpPrompt"
			ready = false
			var take := _button("TakeRunnerUpButton", "ui.cards.action.take_runner_up", GrimmButton.Kind.PRIMARY, &"exec_runner_up", {"id": int(picked[0]) if not picked.is_empty() else -1})
			take.disabled = picked.is_empty()
			buttons.append(take)
			buttons.append(_button("NoRunnerUpButton", "ui.cards.action.no_runner_up", GrimmButton.Kind.SECONDARY, &"exec_runner_up", {"id": -1}))
	var confirm := _button("ConfirmExecutionButton", confirm_key, GrimmButton.Kind.PRIMARY, &"confirm_execution")
	confirm.disabled = not ready
	buttons.append(confirm)
	buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
	_actions(buttons)


## Hinweise zu Kartenwirkungen auf die Hinrichtung; gibt zurück, ob mindestens einer angezeigt wurde.
func _card_exec_notes(preview: Dictionary, seats: Array) -> bool:
	var shown := false
	if bool(preview.get("card_shifted", false)):
		_text("ui.cards.exec.shifted", {"name": CockpitText.names_of([int(preview["death_target_id"])], seats)}, &"WarningLabel").name = "ShiftedLabel"
		shown = true
	if bool(preview.get("card_random_wolf", false)):
		_text("ui.cards.exec.random_wolf", {}, &"WarningLabel").name = "RandomWolfLabel"
		shown = true
	return shown


## Geführte Spielleiterkorrektur: Person wählen, Pflichtangaben, dann Rückfrage mit Begründung.
func _gm(context: Dictionary) -> void:
	var mode := str(context.get("gm_mode", ""))
	_heading("ui.cockpit.card.gm.heading", {"kind": StringName("ui.gm.kind.%s" % mode)})
	_text("ui.cockpit.card.gm.warning", {}, &"WarningLabel")
	var buttons: Array[Control] = []
	if mode == "declare_winner":
		_text("ui.cockpit.card.gm.winner", {}, &"MutedLabel")
		for kind: String in ["village", "wolves", "solo", "none"]:
			buttons.append(_button("GmWinner_%s" % kind, "ui.cockpit.win.kind.%s" % kind, GrimmButton.Kind.SECONDARY, &"gm_winner", {"kind": kind}))
		buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
		_actions(buttons)
		return
	_text("ui.cockpit.card.gm.pick_dead" if mode == "revive" else "ui.cockpit.card.gm.pick_alive", {}, &"MutedLabel")
	var selection: Array = context.get("selection", [])
	if not selection.is_empty():
		_text("ui.cockpit.card.selection.some", {"names": CockpitText.names_of(selection, context.get("seats", []))}, &"SectionLabel")
	var ready := not selection.is_empty()
	if mode == "kill":
		var effects: Variant = context.get("gm_effects")
		for choice: bool in [true, false]:
			var b := _button("GmEffects%s" % ("Yes" if choice else "No"), "ui.cockpit.card.gm.effects.%s" % ("yes" if choice else "no"),
				GrimmButton.Kind.PRIMARY if effects is bool and effects == choice else GrimmButton.Kind.SECONDARY, &"gm_effects", {"value": choice})
			buttons.append(b)
		ready = ready and effects is bool
	if mode == "status":
		# Jeder Wert ist ein eigener Button „Feld: aktuell → neu“; die Wahl führt direkt zur Rückfrage.
		var fields: Array = context.get("status_fields", [])
		for i: int in fields.size():
			var f: Dictionary = fields[i]
			if str(f["type"]) == "action" or str(f["type"]) == "pick":
				# Spezialkorrektur: Art der Korrektur und bisheriger Wert der Person; „…“ = zuerst ein Ziel wählen.
				var special := _button("GmField_%s" % str(f["field"]), "ui.cockpit.card.gm.action_pick" if str(f["type"]) == "pick" else "ui.cockpit.card.gm.action",
					GrimmButton.Kind.SECONDARY, &"gm_field", {"index": i})
				special.format_values = {"kind": StringName("ui.gm.kind.%s" % str(f["kind"])), "state": CockpitText.state_text(f.get("state", {}))}
				buttons.append(special)
				continue
			var b := _button("GmField_%s" % str(f["field"]), "ui.cockpit.card.gm.field", GrimmButton.Kind.SECONDARY, &"gm_field", {"index": i})
			var now: Variant = f["current"]
			b.format_values = {"field": StringName("ui.gm.field.%s" % str(f["field"])),
				"from": StringName("ui.common.yes" if now == true else "ui.common.no") if str(f["type"]) == "bool" else CockpitText.role_name(str(now)),
				"to": StringName("ui.common.no" if now == true else "ui.common.yes") if str(f["type"]) == "bool" else StringName("ui.cockpit.card.gm.choose")}
			buttons.append(b)
		buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
		_actions(buttons)
		return
	if mode == "set_role":
		var role := str(context.get("gm_role", ""))
		if role != "":
			_text("ui.cockpit.card.gm.new_role", {"role": CockpitText.role_name(role)}, &"SectionLabel")
		buttons.append(_button("GmChooseRoleButton", "ui.cockpit.card.gm.choose_role", GrimmButton.Kind.SECONDARY, &"gm_choose_role"))
		ready = ready and role != ""
	var confirm := _button("GmConfirmButton", "ui.cockpit.card.gm.confirm", GrimmButton.Kind.DANGER, &"gm_confirm")
	confirm.disabled = not ready
	buttons.append(confirm)
	buttons.append(_button("CancelModeButton", "ui.common.cancel", GrimmButton.Kind.SECONDARY, &"cancel_mode"))
	_actions(buttons)


func _end_day(next: Dictionary, context: Dictionary) -> void:
	_heading("ui.cockpit.card.end_day.heading", {"number": int(context.get("day_number", 0))})
	_day_public(next, context)
	_text("ui.cockpit.card.end_day.do", {}, &"MutedLabel")
	_actions([_button("EndDayButton", "ui.cockpit.action.end_day", GrimmButton.Kind.PRIMARY, &"end_day")])


func _win_decision(next: Dictionary) -> void:
	_heading("ui.cockpit.card.win.heading")
	_text("ui.cockpit.card.win.do", {}, &"MutedLabel")
	var buttons: Array[Control] = []
	for c: Dictionary in next.get("candidates", []):
		_text("ui.cockpit.card.win.candidate", {"side": StringName("ui.cockpit.win.kind.%s" % str(c["kind"])),
			"reason": StringName(_reason_key(str(c["reason_key"]))), "names": ", ".join(c.get("beneficiaries", []))}, &"SectionLabel")
		var b := _button("ConfirmWinButton_%d" % int(c["id"]), "ui.cockpit.action.confirm_win", GrimmButton.Kind.PRIMARY, &"confirm_win", {"candidate_id": int(c["id"])})
		b.format_values = {"side": StringName("ui.cockpit.win.kind.%s" % str(c["kind"]))}
		buttons.append(b)
	buttons.append(_button("RejectWinButton", "ui.cockpit.action.reject_win", GrimmButton.Kind.SECONDARY, &"reject_win"))
	_actions(buttons)


func _game_over(next: Dictionary) -> void:
	_heading("ui.cockpit.card.game_over.heading")
	var winner: Dictionary = next.get("winner", {})
	if not winner.is_empty():
		_text("ui.cockpit.card.win.candidate", {"side": StringName("ui.cockpit.win.kind.%s" % str(winner["kind"])),
			"reason": StringName(_reason_key(str(winner["reason_key"]))), "names": ", ".join(winner.get("beneficiaries", []))}, &"SectionLabel")
	var buttons: Array[Control] = [_button("OpenReportButton", "ui.cockpit.action.open_report", GrimmButton.Kind.PRIMARY, &"open_report")]
	_actions(buttons)


func _reason_key(reason: String) -> String:
	var key := "ui.cockpit.win.reason.%s" % reason
	return key if CockpitText.has_key(key) else "ui.cockpit.win.reason.generic"


# --- Bausteine --------------------------------------------------------------------------------------

## Kontexthilfe (private Spielleiterkarte): allgemeiner Lexikoneintrag der Rolle der aktuellen Handlung. Entsteht nur auf
## einer aufgedeckten bzw. nächtlichen Karte (verdeckt gibt es keine Knoten) und nie auf gezeigten Ebenen.
func _help(next: Dictionary, buttons: Array[Control]) -> void:
	var role := CockpitText.help_role(next)
	if role == "":
		return
	if info_host == null:
		buttons.append(_button("ContextHelpButton", "ui.cockpit.action.help", GrimmButton.Kind.COMPACT, &"help", {"role_id": role}))
		return
	var info := GlyphButton.new()
	info.name = "ContextHelpButton"
	info.glyph = "info"
	info.text_key = "ui.cockpit.action.help"
	info.tooltip_text = tr("ui.cockpit.action.help")
	info.pressed.connect(_emit.bind(&"help", {"role_id": role}, info))
	_info = info
	info_host.add_child(info)
	info.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	info.offset_left = -float(ThemeTokens.TOUCH_MIN) - 6.0
	info.offset_right = -6.0
	info.offset_top = 6.0
	info.offset_bottom = 6.0 + float(ThemeTokens.TOUCH_MIN)


## Der Titel oben auf der Karte lässt rechts Platz für den runden „i“-Knopf (Cockpit), damit er nie überdeckt wird.
func _heading(key: String, values: Dictionary = {}) -> GrimmLabel:
	var first := _content.get_child_count() <= 1
	var label := _text(key, values, &"HeadingLabel")
	if info_host != null and first:
		var box := MarginContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override(&"margin_right", ThemeTokens.TOUCH_MIN + 12)
		_content.add_child(box)
		_content.move_child(box, label.get_index())
		_content.remove_child(label)
		box.add_child(label)
	return label


func _caption(key: String, values: Dictionary = {}) -> GrimmLabel:
	return _text(key, values, &"CaptionLabel")


func _read_aloud(key: String, values: Dictionary) -> void:
	_caption("ui.cockpit.card.say_now")
	_text(key, values, &"ReadAloudLabel")


func _text(key: String, values: Dictionary = {}, variation: StringName = &"") -> GrimmLabel:
	var label := GrimmLabel.new()
	label.format_values = values
	label.text_key = key
	if variation != &"":
		label.theme_type_variation = variation
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(label)
	return label


func _button(node_name: String, key: String, kind: GrimmButton.Kind, action: StringName, payload: Dictionary = {}) -> GrimmButton:
	var b := GrimmButton.new()
	b.name = node_name
	b.kind = kind
	b.text_key = key
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary_host != null:
		# Cockpit (Nachtbrett, P5): Hauptaktion rot, Nebenaktionen dunkel, beide im Hain-Rahmen; Nebenaktionen zwei je Reihe.
		b.custom_minimum_size = Vector2(CARD_ACTION_MIN_WIDTH, ThemeTokens.TOUCH_MIN)
		GroveSkin.skin_button(b, kind == GrimmButton.Kind.PRIMARY)
		if kind != GrimmButton.Kind.PRIMARY:
			b.custom_minimum_size.y = ThemeTokens.TOUCH_MIN  # Nebenaktionen auf der Karte: 48 hoch, zwei Zeilen Schrift passen; spart Platz für den Text
	else:
		b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, ACTION_MIN_WIDTH)
	b.pressed.connect(_emit.bind(action, payload, b))
	return b


func _actions(buttons: Array[Control]) -> void:
	for b: Control in buttons:
		if primary_host != null and _primary == null and b is GrimmButton and (b as GrimmButton).kind == GrimmButton.Kind.PRIMARY:
			_primary = b as GrimmButton
			primary_host.add_child(b)
			continue
		_actions_box.add_child(b)
	_apply_hand(not _left_handed)


## Ein Tippen zählt nur auf einem Button der aktuellen Karte, solange sie nicht gesperrt ist.
func _emit(action: StringName, payload: Dictionary, source: BaseButton) -> void:
	if _busy or source.disabled or source.is_queued_for_deletion() or not (is_ancestor_of(source) or source == _primary or source == _info):
		return
	requested.emit(action, payload)


# --- Totenreichkarten ---------------------------------------------------------------------------------

## Kartenfläche: Name der Karte und ihr Text zum Vorlesen oder Zeigen.
func _card_face(card: Dictionary) -> void:
	if card.is_empty():
		return
	var title := _text(str(card["name_key"]), {}, &"SectionLabel")
	title.name = "CardNameLabel"
	if str(card.get("text_key", "")) != "":
		_text(str(card["text_key"]), {}, &"ReadAloudLabel").name = "CardTextLabel"


## Kopf einer Karteneingabe: Karte oder Aufgabe, handelnde Person, Kartentext (nur beim Spielen).
func _card_prompt_head(next: Dictionary) -> void:
	var card: Dictionary = next.get("card", {})
	var task := str(next.get("task_kind", ""))
	if task != "":
		_heading("ui.card.task.%s.heading" % task if CockpitText.has_key("ui.card.task.%s.heading" % task) else "ui.cards.task.heading")
		if not card.is_empty():
			_text(str(card["name_key"]), {}, &"CaptionLabel").name = "CardNameLabel"
		if next.has("victim") and str(next.get("victim_role", "")) != "":
			_text("ui.cards.pack_victim", {"name": CockpitText.person(next["victim"]), "role": CockpitText.role_name(str(next["victim_role"]))}, &"WarningLabel").name = "PackVictimLabel"
	else:
		_heading("ui.cards.prompt.heading")
		_card_face(card)


## Würfel mit den gespeicherten Würfen (sichtbar gezeichnet, zusätzlich als Zahl).
func _dice(values: Array) -> void:
	var row := DiceRow.new()
	row.show_dice(values)
	_content.add_child(row)
	_text("ui.cards.dice.result", {"dice": ", ".join(values.map(func(v: Variant) -> String: return str(int(v))))}, &"SectionLabel").name = "DiceResultLabel"


## Guthaben des Kartenschluckers (nur Spielleitung): verfügbare und insgesamt gesammelte Stapel, Schild.
func _swallower_status(next: Dictionary) -> void:
	var info: Dictionary = next.get("swallower", {})
	if info.is_empty():
		return
	_text("ui.cards.swallower.status", {"balance": int(info["balance"]), "total": int(info["total"]),
		"shield": StringName("ui.common.yes" if bool(info["shield"]) else "ui.common.no")}, &"WarningLabel").name = "SwallowerStatusLabel"


## Kartenfenster: die gefragte tote Person mit ihrer Originalkarte. Spielen, aufbewahren, tauschen (nur mit lebendem
## Kartenschlucker), Karte zeigen, Überblick oder das Fenster schließen. Verdeckt, bis die Spielleitung aufdeckt.
func _card_window(next: Dictionary, _context: Dictionary) -> void:
	var card: Dictionary = next.get("card", {})
	var owner: Dictionary = next.get("owner", {})
	_caption("ui.cards.window.caption.%s" % str(next.get("window", "start")))
	_heading("ui.cards.window.heading", {"name": CockpitText.person(owner)})
	var waiting: Array = (next.get("waiting", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
	if not waiting.is_empty():
		_text("ui.cards.window.waiting", {"names": ", ".join(waiting)}, &"MutedLabel").name = "WaitingLabel"
	_card_face(card)
	if bool(next.get("must_play", false)):
		_text("ui.cards.window.must_play", {}, &"WarningLabel").name = "MustPlayLabel"
	if not bool(next.get("can_play", false)):
		_text("ui.cards.window.not_playable", {}, &"MutedLabel").name = "NotPlayableLabel"
	var owner_id := int(next.get("owner_id", -1))
	var play := _button("CardPlayButton", "ui.cards.action.play", GrimmButton.Kind.PRIMARY, &"card_play", {"owner_id": owner_id})
	play.disabled = not bool(next.get("can_play", false))
	var keep := _button("CardKeepButton", "ui.cards.action.keep", GrimmButton.Kind.SECONDARY, &"card_keep", {"owner_id": owner_id})
	keep.disabled = not bool(next.get("can_keep", true))
	var buttons: Array[Control] = [play, keep]
	if bool(next.get("swallower_alive", false)):
		var exchange := _button("CardExchangeButton", "ui.cards.action.exchange", GrimmButton.Kind.SECONDARY, &"card_exchange", {"owner_id": owner_id})
		exchange.disabled = not bool(next.get("can_exchange", false))
		buttons.append(exchange)
	# Kartentext und Erklärung scrollen; alle Aktionen stehen im festen Bereich darunter, nie hinter langem Text.
	_text(str(card.get("guide_key", "")), {}, &"MutedLabel").name = "CardGuideLabel"
	var preselected: Array = (next.get("preselected", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
	if not preselected.is_empty():
		_text("ui.cards.window.preselected", {"names": ", ".join(preselected)}, &"WarningLabel").name = "PreselectedLabel"
	var close := _button("CardCloseWindowButton", "ui.cards.action.close_window", GrimmButton.Kind.SECONDARY, &"card_close")
	close.disabled = not bool(next.get("can_close", true))
	buttons.append_array([_button("CardShowButton", "ui.cards.action.show", GrimmButton.Kind.SECONDARY, &"card_show"),
		_button("CardOverviewButton", "ui.cards.action.overview", GrimmButton.Kind.COMPACT, &"card_overview"), close])
	_actions(buttons)


## Öffentliche Tagesregeln durch Karten (Nebelhorn, Stummfilm, Totengericht, ...): Name, Text und, wo vorgesehen, Button zum Melden
## eines Verstoßes. Zeigt nur öffentliche Regeln, keine versteckten Wirkungen.
func _card_rules(rules: Array, buttons: Array[Control]) -> void:
	if rules.is_empty():
		return
	_caption("ui.cards.rules.caption")
	for r: Dictionary in rules:
		var name_label := _text(str(r["name_key"]), {}, &"SectionLabel")
		name_label.name = "CardRuleName_%d" % int(r["effect_id"])
		_text(str(r["text_key"]), {}, &"MutedLabel").name = "CardRuleText_%d" % int(r["effect_id"])
		var excluded: Array = (r.get("excluded", []) as Array).map(func(v: Variant) -> String: return CockpitText.person(v))
		if not excluded.is_empty():
			_text("ui.cards.rules.excluded", {"names": ", ".join(excluded)}, &"WarningLabel")
		if bool(r.get("reportable", false)):
			buttons.append(_button("CardReportButton_%d" % int(r["effect_id"]), "ui.cards.action.report.%s" % str(r["kind"]), GrimmButton.Kind.SECONDARY, &"card_report", {"effect_id": int(r["effect_id"])}))
