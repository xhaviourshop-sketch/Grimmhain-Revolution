# 03 · Godot-4-Architektur

**Stand:** 2026-09-26 · Kennzeichnung: **[B]** Beobachtung, **[S]** Schlussfolgerung, **[E]** Empfehlung.
Codeausschnitte in diesem Dokument sind **Spezifikation** (Signaturen, Datenformen), keine Implementierung.

---

## 1. Leitentscheidungen

| # | Entscheidung [E] | Begründung | Bewusst vermieden |
|---|---|---|---|
| D1 | **Godot 4.x, eine gepinnte stabile Version** für die gesamte MVP-Phase (zum Projektstart aktuellste 4.x-Stable, Upgrade nur an Stop/Go-Punkten) | Reproduzierbare Builds, keine Export-Überraschungen | Beta-/Dev-Builds |
| D2 | **GDScript mit statischer Typisierung** überall (`@warning` „untyped" als Fehler) | Auftrag; Typen fangen Fehler früh; gute Editorunterstützung | C#, GDExtension im Kern |
| D3 | **Regelkern als reine GDScript-Klassen (`RefCounted`), ohne Nodes, ohne Szenenbaum, ohne Zeit, ohne I/O** | Deterministisch, headless testbar, später auf Server lauffähig | Regeln in Szenen-Skripten |
| D4 | **Befehl → Ereignisse → Zustand** (Command/Event mit Snapshots), aber kein vollständiges Event-Sourcing-Framework | Undo, Replay, Crash-Recovery und Netzwerk nutzen dieselben Befehle | CQRS-Frameworks, Reducer-Bibliotheken |
| D5 | **Offene Eingaben als Teil des Zustands** (`PendingPrompt`) | Behebt Frankenstein-Klasse von Fehlern: nichts wird angewandt, bevor alle Eingaben da sind; Reload-sicher | UI-Callbacks, die Regeln fortsetzen |
| D6 | **Rollenverhalten als je ein GDScript pro Rolle** mit festen Hooks; Rollen-Stammdaten als `Resource` | 72 Rollen sind zu verschieden für eine generische Effekt-DSL; Hooks halten sie vergleichbar | Eigene Regelsprache, Daten-getriebene Effekt-Graphen |
| D7 | **Savegames als versioniertes JSON** in `user://`, atomar geschrieben | Lesbar, diff-bar, netzwerktauglich; Godot-`Resource`-Dateien können Skripte laden und sind als Import-Format unsicher | `.tres`-Savegames, SQLite im MVP |
| D8 | **Gesäter Zufall im Zustand** (`RandomNumberGenerator` mit `seed` und `state`) | Replay und Tests liefern identische Ergebnisse | `randi()` global |
| D9 | **Compatibility-Renderer** (OpenGL ES 3 / WebGL 2) für das Tablet-MVP | 2D-App, breiteste Geräteabdeckung, geringerer Akkuverbrauch auf älteren Tablets | Forward+ im MVP |
| D10 | **Übersetzung über Godot `TranslationServer`** mit CSV/PO-Dateien und Schlüsseln | Standardweg, Pluralformen, keine Laufzeit-Substring-Ersetzung | Übernahme von `translateRuntimeText` |

---

## 2. Projektstruktur

```
grimmhain/                         Godot-Projekt (neuer Ordner im Repo, z. B. /godot)
├─ project.godot
├─ core/                           REGELKERN – keine Nodes, keine Autoload-Zugriffe, kein OS/Time/FileAccess
│  ├─ model/                       game_state.gd, seat.gd, effect.gd, pending_prompt.gd, reaction.gd
│  ├─ rules/                       engine.gd (Befehlsverarbeitung), phase_machine.gd, kill_pipeline.gd,
│  │                               night_order.gd, win_rules.gd, faction_query.gd, role_change.gd
│  ├─ roles/                       role_behavior.gd (Basis) + 72 Dateien: werwolf.gd, das_orakel.gd ...
│  ├─ cards/                       death_card_def.gd, death_card_draw.gd
│  ├─ commands/                    command.gd + konkrete Befehle (start_night.gd, answer_prompt.gd ...)
│  ├─ events/                      event.gd + konkrete Ereignisse (seat_died.gd, effect_added.gd ...)
│  ├─ serialization/               state_codec.gd, migrations/ (v1_to_v2.gd ...)
│  └─ util/                        seeded_rng.gd, ids.gd
├─ content/                        DATEN (Resources, keine Logik)
│  ├─ roles/*.tres                 RoleDef je Rolle (id, faction, tags, order_tier, limits, assets)
│  ├─ acts/*.tres                  ActDef (Akt I–IV, Custom)
│  ├─ death_cards/*.tres           DeathCardDef (80)
│  └─ i18n/                        roles.csv, cards.csv, ui.csv, calls.csv (DE, EN)
├─ app/                            PRÄSENTATION (Szenen)
│  ├─ autoload/                    session.gd, save_service.gd, settings.gd, audio_director.gd,
│  │                               fx_director.gd, platform.gd
│  ├─ screens/                     start/, setup/, cockpit/, reveal/, game_end/
│  ├─ widgets/                     seat_ring/, seat_token/, announce_card/, night_rail/, drawers/
│  ├─ theme/                       grimmhain_theme.tres, fonts/, ninepatch/
│  └─ fx/                          shaders/, particles/, transitions/
├─ assets/                         importierte Bilder/Audio (ASCII-kebab-case)
├─ net/                            (später) Transport, Projektionen, Lobby
├─ tests/                          unit/, scenarios/*.json, golden/ (Legacy-Referenzergebnisse)
└─ tools/                          legacy_import.gd, content_lint.gd, asset_check.gd
```

**Abhängigkeitsregel (per Lint in CI geprüft) [E]:** `core/` darf nichts aus `app/`, `net/` oder Autoloads referenzieren. `content/` enthält nur Daten. `app/` spricht mit `core/` ausschließlich über `Session`.

---

## 3. Schichten und ihre Verträge

```
┌───────────────────────────── app/ (Szenen, Widgets, FX, Audio) ─────────────────────────────┐
│  liest: Session.view (ViewModel, unveränderlich)    sendet: Session.submit(Command)          │
│  reagiert auf: Session.events_applied(events)  → FxDirector / AudioDirector / Widgets        │
└──────────────────────────────────────────────┬───────────────────────────────────────────────┘
                                               │
┌──────────────────────────── Session (Autoload, dünn) ────────────────────────────────────────┐
│  hält Engine + GameState, ruft SaveService, verwaltet Undo/Redo-Stapel, baut ViewModels      │
└──────────────────────────────────────────────┬───────────────────────────────────────────────┘
                                               │
┌───────────────────────────── core/ (rein, deterministisch) ──────────────────────────────────┐
│  Engine.apply(state, command) -> Result { new_state, events[], error? }                      │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

- **Präsentation** kennt keine Regeln. Sie zeigt `ViewModel`s an und übersetzt Eingaben in Befehle.
- **Audio/VFX** reagieren nur auf **Ereignisse**, nie auf Zustandsvergleiche. Damit sind Effekte automatisch Feedback für Spielereignisse (Auftrag) und beim Replay/Undo abschaltbar.
- **Persistenz** kennt nur den Codec, nicht die Regeln.
- **Netzwerk (später)** transportiert Befehle und Projektionen, siehe Abschnitt 9.

---

## 4. Autoloads, Szenen, Signals

### 4.1 Autoloads (bewusst wenige) [E]

| Autoload | Aufgabe | Signals |
|---|---|---|
| `Session` | Aktive Runde: `submit(cmd)`, `undo()`, `redo()`, `view()`, `load_round(id)` | `events_applied(events: Array[Event])`, `view_changed(view: CockpitView)`, `save_status_changed(status)` |
| `SaveService` | Atomares Schreiben, Rotation, Wiederherstellung, Export/Import | `save_failed(reason)` |
| `Settings` | Geräte- und Nutzerpräferenzen (nicht Teil des Spielstands) | `changed(key)` |
| `AudioDirector` | Busse, Ambient-Schichten, Cue-Abspielung nach Ereignistyp | – |
| `FxDirector` | Übersetzt Ereignisse in Animations-/Partikel-Aufträge an registrierte Widgets | – |
| `Platform` | Abstraktion für Android/Desktop/Steam (Keep-screen-on, Vibration, Achievements später) | – |

### 4.2 Szenen [E]

| Szene | Inhalt |
|---|---|
| `screens/start/start.tscn` | Fortsetzen-Karte, Neue Runde, Einstellungen |
| `screens/setup/setup_wizard.tscn` | 5 Schritte als Unterszenen, eigener Setup-Zustand (noch keine Engine) |
| `screens/reveal/reveal.tscn` | Übergabe-Modus Rollen zeigen (Projektion ohne Geheimdaten anderer) |
| `screens/cockpit/cockpit.tscn` | Kopfzeile, `NightRail`, `SeatRing`, `AnnounceCard`, Schubladen, Modal-Host |
| `widgets/seat_ring/seat_ring.tscn` | Layout-Berechnung (Ellipse, Kollisionsvermeidung), N×`SeatToken` |
| `widgets/seat_token/seat_token.tscn` | Porträt, Ring, Statussiegel, Name, Nummer, FX-Anker |
| `widgets/announce_card/announce_card.tscn` | Drei Zonen + Fußzeile, rendert `PromptView`/`StepView` |
| `screens/game_end/game_end.tscn` | Sieger, Auslöser, Chronik |

### 4.3 Zustandsmaschinen

**Spielphase (im Kern, `phase_machine.gd`)**

```
SETUP ─start_game→ NIGHT ─end_night→ DAWN_RESOLUTION ─(Reaktionen leer)→ DAY
DAY ─end_day→ NIGHT          jede Phase ─win_detected→ GAME_OVER
DAWN_RESOLUTION / DAY / NIGHT können jederzeit einen PendingPrompt tragen (blockierend)
```

- `NIGHT` hat Unterzustand `step_index` in der berechneten `NightPlan`-Liste.
- `DAY` hat Unterzustände `DISCUSSION`, `NOMINATION`, `EXECUTION_DECIDED`, `AFTERMATH`.
- Übergänge sind **nur** über Befehle möglich. Ein offener `PendingPrompt` blockiert Phasenwechsel (heute nur in React: `GameScreen.tsx:238`).

**UI-Zustand (in `app/`, nicht gespeichert außer offener Schublade)**: `Idle`, `SelectingTargets`, `ConfirmingCorrection`, `ShieldActive`, `DrawerOpen`.

---

## 5. Datenmodell

### 5.1 Identitäten [E]

- `RoleId` = `StringName` in ASCII-kebab-case, transliteriert wie in `docs/architecture/tablet-asset-spec.md`: `werwolf`, `das-orakel`, `rachsuechtiger-wolf`, `dr-victor-frankenstein`.
- Mapping Legacy-String → `RoleId` in `core/util/ids.gd` (einschließlich der 13 Altnamen aus `state:18`).
- `SeatId` = stabile Ganzzahl, **unabhängig von der Sitzposition**. Nachbarschaft kommt aus `GameState.seat_order: PackedInt32Array`.
- `EffectId`, `PromptId` = fortlaufende Zähler im Zustand (deterministisch).

### 5.2 Zustand (Kernklassen)

```gdscript
class_name GameState extends RefCounted
var schema_version: int = 1
var rules_version: StringName = &"grimmhain-1.0"     # eingefroren pro Runde
var round_id: String                                  # UUID bei Rundenstart
var rng: SeededRng                                    # seed + state, serialisierbar
var phase: Phase                                      # enum + Unterzustand
var night_number: int                                 # 1-basiert; getrennt von...
var day_number: int                                   # ...Morgenzähler (heute MorningCount)
var seats: Dictionary[int, Seat]
var seat_order: PackedInt32Array                      # Nachbarschaft
var effects: Array[Effect]                            # alle laufenden Zustände mit Quelle/Dauer
var role_memory: Dictionary                           # rollen-/sitzbezogene Daten, typisiert pro Rolle
var night_plan: NightPlan                             # berechnete Schritte der laufenden Nacht
var pending_prompt: PendingPrompt                     # null oder genau eine offene Eingabe
var reaction_queue: Array[Reaction]                   # abzuarbeitende Todes-/Lynchfolgen
var death_cards: Dictionary[int, DeathCardSlot]       # seat_id -> {card_id, state}
var day: DayState                                     # Nominierungen, Stimmen (falls aktiviert)
var winner: WinResult                                 # null oder {kind, role_id, seat_ids, reason_key}
var next_ids: Dictionary                              # Zähler für Effect/Prompt/Event
```

```gdscript
class_name Seat extends RefCounted
var id: int
var name: String
var role_id: StringName
var original_role_id: StringName     # für Chronik und Rollenwechsel-Logik
var alive: bool = true
var death: DeathRecord               # null oder {cause, source_seat, night/day, order_index}
var converted_to_wolf: bool          # ersetzt flags.werewolf für Verwandlungen
var ability_uses: Dictionary         # {ability_key: count}  -> Einmal-Nutzung pro Sitz, nicht global
```

```gdscript
class_name Effect extends RefCounted
var id: int
var kind: StringName          # &"protected", &"charmed", &"poisoned", &"lover", &"puppet", &"blocked",
                              # &"hangman_mark", &"burn_mark", &"cursed_wolf_aura", &"shield_once" ...
var target_seat: int
var source_seat: int          # wer hat es verursacht (-1 = System/Totenkarte)
var source_role: StringName
var expires: Expiry           # {at: DAWN|NIGHT_START|DAY_END|NEVER|ON_TRIGGER, phase_number}
var data: Dictionary          # kleine, typisierte Nutzdaten (z. B. partner_seat)
```

[S] Damit werden die heute verstreuten `flags.*`/`meta.*` (siehe `01`, 4.1) zu einer einzigen Liste. Rücksetzen bei Nacht-/Tagesbeginn wird **eine** Funktion `expire_effects(trigger)` statt Code in `onNightStart`/`onDayStart`.

### 5.3 Rollen

```gdscript
class_name RoleDef extends Resource          # content/roles/<id>.tres
@export var id: StringName
@export var faction: Faction                 # VILLAGE | WOLF | SOLO  (Siegzugehörigkeit)
@export var appears_as: Faction              # was Informationsrollen sehen (Trugbilder etc.)
@export var tags: PackedStringArray          # "revive", "role-return", "death-trigger-transform", "info" ...
@export var night_tier: float = -1.0         # -1 = keine Nachtaktion (heute ORDER_BASE)
@export var once_per_game: bool
@export var max_copies: int = 1              # Werwolf 5, Dorfbewohner 10, Die Gebundenen 6
@export var requires_roles: Array[StringName]# z. B. schwarze-witwe -> [loki]
@export var behavior: Script                 # core/roles/<id>.gd
@export var portrait: Texture2D              # nur Präsentation, vom Kern ignoriert
@export var automation_status: StringName    # verified | partial | manual  (siehe 04)
```

```gdscript
class_name RoleBehavior extends RefCounted   # core/roles/role_behavior.gd, alle Hooks optional
func night_step(ctx: RuleContext, seat: Seat) -> StepSpec          # Prompt-Beschreibung oder null
func resolve_step(ctx: RuleContext, seat: Seat, answer: PromptAnswer) -> void
func is_night_step_available(ctx: RuleContext, seat: Seat) -> bool # Henker ab 3 Lynchs, Kutscher ab 10 Toten ...
func intercept_kill(ctx: RuleContext, attempt: KillAttempt) -> KillDecision  # Schilde, Umlenkung
func on_death(ctx: RuleContext, seat: Seat, record: DeathRecord) -> void     # Reaktionen einreihen
func on_execution(ctx: RuleContext, seat: Seat) -> ExecutionOutcome          # Fenrir, Cerberus, Spiegelwolf ...
func check_win(ctx: RuleContext) -> WinResult                                # Solo-Siege
```

`RuleContext` stellt Abfragen (`alive_seats()`, `neighbors(seat, living_only)`, `counts_as_wolf(seat)`, `appears_as(seat)`), den `SeededRng` und Emitter für Ereignisse bereit. Rollen verändern den Zustand **nur** über Kontext-Operationen (`add_effect`, `request_kill`, `change_role`, `enqueue_reaction`), damit jedes Ereignis protokolliert wird.

### 5.4 Tötungs-Pipeline (ersetzt `applyKill` und verstreute Schutzprüfungen)

```
request_kill(target, cause, source)
  1. Ziel tot? -> abbrechen
  2. Abfangregeln in FESTER, dokumentierter Reihenfolge (Tabelle in 04, Abschnitt C):
       Umlenkung (Schattenwanderer, Voodoo-Puppe) -> Immunität (Parasit, Dorfwache)
       -> Schutz-Effekte mit Ursachenfilter (Schutzengel, Schmied-Waffe, Der Weise)
       -> Einmal-Schilde (Rudelvater, Nekromant, Kartenschlucker, Hades)
     Jede Regel liefert ALLOW | PREVENT(reason) | REDIRECT(new_target)
  3. Tod anwenden -> DeathRecord
  4. Folgetode (Liebende, Parasit, Rotkäppchen) -> rekursiv über request_kill mit eigener Ursache
  5. on_death-Hooks -> Reaktionen in reaction_queue (Sensenträger, Besessener, Dämonischer ...)
  6. Totenkarte zuweisen
  7. Sieg prüfen (EINE Funktion, erster Sieger gewinnt, kein Überschreiben)
```

Jede Ursache (`KillCause`-Enum mit den 28 Legacy-Ursachen) trägt Attribute wie `is_wolf_attack`, `is_night`, `is_execution`, `pierces_protection`. Schutzregeln filtern über diese Attribute statt über String-Listen (heute z. B. `core:431`).

### 5.5 Offene Eingaben

```gdscript
class_name PendingPrompt extends RefCounted
var id: int
var kind: StringName            # &"pick_seats", &"choose_option", &"confirm_info", &"pick_role", &"enter_text"
var owner: StringName           # Rolle/Reaktion, die fragt
var actor_seat: int
var min_count: int; var max_count: int
var allowed_seats: PackedInt32Array   # vom Kern berechnet, UI zeigt nur an
var options: Array[StringName]        # Schlüssel, nicht Texte
var info: Dictionary                  # Ergebnisdaten zur Anzeige (z. B. {seat: 7, appears_as: WOLF})
var partial: Dictionary               # bereits gegebene Teilantworten bei mehrstufigen Prompts
var cancellable: bool
```

Mehrstufige Aktionen (Frankenstein: Toten wählen → Rolle wählen → bestätigen) sind **eine** Prompt-Kette. Erst die letzte Antwort erzeugt Ereignisse. Abbrechen löscht den Prompt, der Zustand bleibt unverändert.

### 5.6 Befehle und Ereignisse

**Befehle** (Absicht des SL, serialisierbar):
`StartGame(setup)`, `StartNight`, `BeginStep(index)`, `AnswerPrompt(prompt_id, answer)`, `SkipStep(reason)`, `CancelPrompt`, `EndNight`, `Nominate(seat)`, `DecideExecution(seat|none)`, `EndDay`, `PlayDeathCard(seat)`, `ResolveDeathCard(seat, done)`, `GmCorrection(kind, payload, reason)`.

**Ereignisse** (was passiert ist, Grundlage für Protokoll, Audio, VFX):
`PhaseChanged`, `StepStarted`, `StepSkipped{reason}`, `EffectAdded`, `EffectExpired`, `KillPrevented{by}`, `KillRedirected{to}`, `SeatDied{cause}`, `SeatRevived`, `RoleChanged{from,to,by}`, `InfoRevealed{to_actor, data}`, `ReactionQueued`, `PublicAnnouncement{key,args}`, `DeathCardAssigned`, `WinDetected{result}`, `GmCorrected{reason}`.

Jedes Ereignis hat `visibility`: `GM_ONLY` | `PUBLIC` | `ACTOR(seat)`. Daraus entstehen Morgenbericht, Chronik und später Netzwerk-Projektionen.

### 5.7 Ereignisprotokoll

- `GameLog` = Liste aller Ereignisse mit Befehlsindex; Teil des Spielstands (heute im RAM, `js/ui/gamelog.js`).
- Anzeige filtert nach Sichtbarkeit und Kategorie; Rohdaten gehen nie verloren.
- Texte werden erst bei Anzeige aus Schlüssel + Argumenten erzeugt (Sprachwechsel ändert Protokoll mit).

---

## 6. Savegame, Versionierung, Undo/Redo, Crash-Recovery

### 6.1 Dateiformat [E]

```json
{
  "format": "grimmhain-save",
  "schema_version": 1,
  "rules_version": "grimmhain-1.0",
  "app_version": "0.3.0",
  "round_id": "…",
  "created_at": "2026-…", "updated_at": "2026-…",
  "initial": { "setup": { … }, "seed": 123456789 },
  "commands": [ { "i": 0, "type": "StartGame", … }, … ],
  "checkpoints": [ { "after_command": 40, "state": { … } } ],
  "state": { … aktueller Zustand … },
  "state_hash": "sha256:…"
}
```

- Ablage: `user://rounds/<round_id>/round.json`, Liste in `user://rounds/index.json`.
- **Atomar:** schreiben nach `round.json.tmp`, `flush`, dann umbenennen; die letzten 3 Stände als `round.json.1..3` rotieren.
- Speichern nach **jedem** angewandten Befehl (Datenmenge gering: ~24 Sitze, < 1000 Befehle pro Runde).
- **Speichern ist rein.** Keine Regelfolgen beim Speichern (Gegenteil zu `state:76-119`).

### 6.2 Versionierung

- `schema_version` → Migrationskette `core/serialization/migrations/vN_to_vN+1.gd`, jede mit Fixture-Test.
- `rules_version` ist pro Runde eingefroren. Eine App-Aktualisierung darf eine laufende Runde nicht mit neuen Regeln fortsetzen; der Kern hält alte Regelversionen, solange Runden sie verwenden, oder bietet „Runde mit neuer Regelversion neu starten" an.
- Legacy-Import (optional, Frage Q10 in `07`): `tools/legacy_import.gd` liest `uw_custom_v16`-JSON, mappt Rollennamen und Flags auf Seats/Effects; nur Setup-Daten (Namen, Rollen, Sitzfolge), nicht laufende Auflösungen.

### 6.3 Undo/Redo

- Undo-Einheit = **ein Befehl** des SL (nicht einzelne Ereignisse).
- Umsetzung: Zustand nach Befehl `k` = Checkpoint `c ≤ k` + erneute Anwendung der Befehle `c+1..k`. Checkpoints alle 20 Befehle und an jedem Phasenwechsel.
- Undo entfernt den letzten Befehl aus dem aktiven Stapel und legt ihn auf den Redo-Stapel. Ein neuer Befehl leert Redo.
- Voraussetzung: vollständiger Determinismus (gesäter Zufall, keine Zeitabhängigkeit). Zeitwerte (Timer) sind **nicht** Teil der Regelzustände.
- Die UI zeigt vor dem Undo den Klartext des Befehls und seiner Hauptfolgen (aus den Ereignissen).
- **Sieg rückgängig machen** ist erlaubt (Korrektur). Ereignisse mit Audio/VFX werden beim Undo nicht erneut abgespielt.

### 6.4 Crash-Recovery

- Beim Start: jüngste gültige Datei laden (Hash prüfen), bei Fehler auf Rotation zurückfallen, bei Totalausfall Replay aus `initial` + `commands`.
- **Unterbrechungszettel** aus den letzten 3 Ereignissen und dem offenen Prompt.
- Fehlerhafte Dateien werden nie überschrieben, sondern nach `user://rounds/<id>/corrupt-<zeit>.json` verschoben und im UI gemeldet.
- `NOTIFICATION_APPLICATION_PAUSED` / `WM_CLOSE_REQUEST` erzwingen einen Flush.

---

## 7. Determinismus und Tests

| Maßnahme [E] | Zweck |
|---|---|
| `SeededRng` im Zustand; alle Zufallsentscheidungen (Verteilung, Kutscher, Schmied-Opfer, Totenkarten, Gift-Ausbreitung, Detektiv) nutzen ihn | Replay, Tests |
| Keine Iteration über `Dictionary` ohne Sortierung, wo die Reihenfolge Folgen hat | Plattformgleichheit |
| Keine Gleitkomma-Regeln außer `night_tier` (nur Sortierung) | Plattformgleichheit |
| Unit-Tests pro Rolle (gdUnit4 oder GUT, headless `godot --headless`) | Regelabsicherung |
| **Szenario-Tests als JSON** (`tests/scenarios/*.json`: Setup, Seed, Befehle, erwartete Ereignisse/Endzustand) | Lesbar für Nicht-Programmierer, auch als Bug-Report nutzbar |
| **Golden-Tests gegen Legacy** für als *verifiziert* markierte Regeln: dieselben Szenarien in der Web-App per Puppeteer (bereits Abhängigkeit in `package.json`) ausführen, Ergebnis vergleichen | Nachweis „gleiche Regeln" |
| Property-Test: zufällige Befehlsfolgen → Undo aller Befehle = Ausgangszustand; Save/Load = identischer Hash | Robustheit |
| CI: headless Tests + Content-Lint (jede `RoleDef` hat Behavior, Texte DE/EN, Asset-Pfade) | Regressionen |

---

## 8. Plattformstrategie

### 8.1 Android-Tablet (MVP)

- Export „Gradle Build", Querformat erzwungen (`display/window/handheld/orientation = sensor_landscape`), Portrait später als eigenes Layout.
- Basisauflösung 1280×800, Stretch-Modus `canvas_items`, Aspekt `expand`; Layouts mit Anchors/Containern statt fester Pixel.
- Texturen: ETC2/ASTC über Import-Voreinstellung; Porträts 512², Hintergründe 2560×1600 (siehe `05`).
- Sicherheitsbereiche über `DisplayServer.get_display_safe_area()`.
- Referenzgeräte: ein Mittelklasse-Android-Tablet der Jahre 2021–2022 als Leistungsuntergrenze, ein aktuelles Gerät; iPad folgt (Export benötigt macOS/Xcode, siehe Q7).

### 8.2 Desktop (1.0+)

- Gleiche Szenen; Eingabe über Maus + Tastaturkürzel (Leertaste = Primäraktion, Z/Y = Undo/Redo, 1–9 = Sitzwahl).
- Fenster frei skalierbar, Mindestgröße 1024×640.
- Optionaler **zweiter Bildschirm** als öffentliche Anzeige (zweites `Window` mit Projektion `PUBLIC`).

### 8.3 Steam (später)

- Integration nur über `Platform`-Autoload mit einer Steam-Implementierung (GodotSteam als GDExtension), sodass Android-Builds keine Steam-Abhängigkeit haben.
- Achievements, Cloud-Saves (die JSON-Dateien aus 6.1), Rich Presence. Keine Spielregel darf von Steam abhängen.
- Store-Anforderungen: KI-Inhalte offenlegen (siehe `01`, 6.2), Lizenzen der Schriften/Audio dokumentiert.

---

## 9. Späteres Netzwerk (nicht im MVP, aber vorbereitet)

- **Autorität:** Das SL-Gerät bleibt Host und einzige Regelinstanz. Clients senden Wünsche, der Host erzeugt Befehle.
- **Projektionen:** `project(state, events, viewer) -> ViewModel` mit Positivliste pro Betrachter (`GM`, `PUBLIC`, `SEAT(n)`). Dieselbe Funktion bedient Übergabe-Modus, Zweitbildschirm und später Spielergeräte.
- **Transport:** Godot High-Level Multiplayer (ENet/WebSocket) im LAN zuerst; Online später über einen schlanken Relay-Dienst. Der Kern bleibt unverändert, weil Befehle und Ereignisse bereits serialisierbar sind.
- **Headless-Server:** möglich, weil `core/` keine Nodes braucht.

---

## 10. Vermiedene Überkomplexität [E]

| Versuchung | Warum nicht |
|---|---|
| Generische Effekt-/Regel-DSL für alle 72 Rollen | Rollen sind heterogen; eine DSL wird selbst zur fehleranfälligen Engine. Hooks + Tests reichen |
| ECS oder eigenes Framework | 24 Sitze, wenige hundert Befehle: kein Leistungsproblem |
| Vollständiges Event-Sourcing mit Projektionen für jedes Widget | Ein ViewModel pro Screen genügt; Ereignisse dienen Protokoll, FX und Netz |
| Datenbank (SQLite) | JSON-Dateien reichen für Runden und Gruppen |
| Mehrere Renderer/Qualitätsstufen im MVP | Eine Stufe + „Effekte reduziert"-Schalter |
| Portierung der React-Adapter-Schicht | Sie existiert nur, um versteckten DOM auszulesen; in Godot nicht nötig |
| Online-Vorbereitung über Projektionen hinaus | Kein Lobby-/Accountcode vor bestätigtem Bedarf |
| Automatisierung aller 80 Totenkarten | Erst Produktentscheidung Q3; heute manuell |

---

## 11. Abbildung Legacy → Godot (Kurzreferenz)

| Legacy [B] | Godot-Modul [E] |
|---|---|
| `roles.js` `ALL_ROLES`, `ORDER_BASE`, Sets, Texte | `content/roles/*.tres`, `content/i18n/roles.csv` |
| `abilities-roles-chunk.js`, `abilities.js`, `abilities-helpers.js` | `core/roles/<id>.gd` |
| `night.js` `rebuildOrder` | `core/rules/night_order.gd` (ohne DOM) |
| `night.js` `onNightStart`/`onDayStart`/`resolveDayKills` | `core/rules/phase_machine.gd` + `kill_pipeline.gd` |
| `night.js` `doLynchFlow`/`finalizeLynch` | `core/rules/execution.gd` + `on_execution`-Hooks |
| `js/ui/core.js` `applyKill`, `postDeathHooks` | `core/rules/kill_pipeline.gd` |
| `js/ui/core.js` `isWolf`, `getFaction` | `core/rules/faction_query.gd` |
| `js/ui/core.js` Siegprüfungen | `core/rules/win_rules.gd` + `check_win`-Hooks |
| `cards.js` | `content/death_cards/*.tres`, `core/cards/death_card_draw.gd` |
| `state.js` | `core/model/*`, `core/serialization/*`, `SaveService` |
| `i18n.js` | `content/i18n/*.csv` + `TranslationServer` |
| `gamelog.js` | Ereignisprotokoll im Zustand + `app/widgets/drawers/log_drawer` |
| `audio.js` | `AudioDirector` |
| SL-Assistent (`night:586-733`) | `NightPlan.step_index` im Zustand + `AnnounceCard` |
