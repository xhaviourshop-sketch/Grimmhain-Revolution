class_name ThemeTokens
extends RefCounted
## Zentrale Design-Tokens der UI (einzige Quelle für Farben und Größen). Szenen enthalten
## keine Stilwerte; ThemeFactory baut daraus das Theme, Skripte lesen nur diese Konstanten.
## Richtung: dunkle Anthrazit- und Nachttöne, warmes Gold als Hervorhebung, gedämpftes Rot
## nur für Gefahr. Gold #C9A84C ist die Hausfarbe (05 §2.1). Kontraste in test_ui_theme.gd.
## Größen in logischen Pixeln (Basis 1280×800, Streckung `canvas_items`).

# --- Farben --------------------------------------------------------------------------------------
const BG_APP := Color("#0b0d14")            ## Grundfläche (Nacht-Anthrazit)
const BG_SURFACE := Color("#151924")        ## Karten, Kopfzeile
const BG_SURFACE_RAISED := Color("#1f2433")  ## Hover auf Flächen, Sekundärbutton gedrückt
const BG_OVERLAY := Color(0.02, 0.027, 0.059, 0.78)  ## Abdunklung hinter Dialogen
const BORDER_SUBTLE := Color("#2e3446")      ## ruhige Rahmen
const GOLD := Color("#c9a84c")               ## Primäraktion, Akzent
const GOLD_BRIGHT := Color("#e0c26e")        ## Hover der Primäraktion
const GOLD_DEEP := Color("#a8883a")          ## gedrückte Primäraktion
const DANGER := Color("#9b3a3a")             ## gedämpftes Rot, nur Gefahr/destruktiv
const DANGER_BRIGHT := Color("#ad4545")
const DANGER_DEEP := Color("#7c2d2d")
const DANGER_TEXT := Color("#ec9f97")        ## Fehlertext auf dunklen Flächen (lesbar, nicht grell)
const WARNING_TEXT := Color("#e0c26e")       ## Hinweistext (warmes Gold, zusätzlich immer mit Textpräfix)
const TEXT_PRIMARY := Color("#ece7dc")       ## warmes Weiß
const TEXT_MUTED := Color("#aaa393")         ## Sekundärtext
const TEXT_ON_GOLD := Color("#15110a")       ## Text auf Gold
const TEXT_DISABLED := Color("#6b675f")      ## deaktiviert (bewusst schwächer)
const FOCUS_RING := Color("#f3de9f")         ## Tastaturfokus
const DISABLED_FILL := Color("#181b23")
const DISABLED_BORDER := Color("#262a35")
const NIGHT_SURFACE := Color("#121a33")      ## Cockpit in der Nacht: tiefes Blau
const NIGHT_ACCENT := Color("#8fa8e0")       ## Mondlicht: Rahmen der Nachtflächen, handelnde Person
const DAY_SURFACE := Color("#2a2112")        ## Cockpit am Tag und Morgen: warmes Dämmerbraun
const DAY_ACCENT := Color("#e0b060")         ## Sonnengold: Rahmen der Tagflächen
const NIGHT_BACKDROP := Color("#0a1022")     ## Cockpit-Hintergrund in der Nacht (ruhig, blendet im Dunkeln nicht)
const DAY_BACKDROP := Color("#16120b")       ## Cockpit-Hintergrund am Morgen und Tag
const BOARD_NEUTRAL := Color("#10131c")      ## Spielbrett ohne Tageszeit (Spielende, keine Partie)
const BOARD_NIGHT := Color("#0e1530")        ## Spielbrett in der Nacht: tiefes Blau, heller als der Hintergrund
const MOON_SILVER := Color("#c5cddb")        ## Nachtbrett: Zeichen, Ränder und Schrift auf den Hain-Teilen (kein Gold auf dem Brett)
const MOON_SILVER_BRIGHT := Color("#e8edf6")  ## Mondsilber unter Finger, mit Fokus oder in Betrieb
const MOON_SILVER_DIM := Color("#7f8899")    ## Mondsilber gedämpft: erledigt, gesperrt
const BLOOD_RED := Color("#b3242d")          ## Nachtbrett: nur Aktives (Ring der aktiven Rolle, Verbergen an) und die Hauptaktion
const BLOOD_RED_HALO := Color(0.7, 0.14, 0.18, 0.55)  ## Schein um den Ring der aktiven Rolle
const TINT_RING_ACTIVE := Color(1.5, 0.42, 0.4)      ## Silberring der aktiven Rolle in Blutrot getönt
const TINT_RING_DONE := Color(0.62, 0.64, 0.7)       ## Ring und Symbol einer erledigten Rolle
const SCROLL_FADE := Color(0.03, 0.04, 0.07, 0.92)   ## Verlauf am unteren Rand eines scrollenden Kartentexts
const MOON_GLOW := Color(0.88, 0.94, 1.0)            ## heller Mondsilber-Schein: gewähltes Ziel, Scrollpfeil
const SEAT_SHIMMER := Color(0.72, 0.82, 1.0)         ## dezenter, kühler Schimmer wählbarer Plätze
const BLOOD_GLOW := Color(0.78, 0.08, 0.1)           ## blutroter Schein am Ring der handelnden Person
const TINT_SEAT_ACTOR := Color(1.0, 0.78, 0.78)      ## Silberring der handelnden Person leicht gerötet
const TINT_QUIET := Color(1, 1, 1, 0.72)             ## dezenter Hinweis („Gespeichert“)
const BOARD_DAY := Color("#1c160d")          ## Spielbrett am Morgen und Tag: dunkles Dämmerbraun

# --- Nachtbrett (P3): Tönungen und Flächen der Porträtplätze, Laschen und Leiste --------------------
const INVISIBLE := Color(0, 0, 0, 0)         ## unsichtbar (Text, den ein selbstzeichnendes Element nicht doppelt zeigen soll)
const EPIC_TEXT_OUTLINE := Color(0.04, 0.0, 0.0, 0.95)  ## epischer Knopf: dunkler Umriss der hellen Schrift
const EPIC_TEXT_SHADOW := Color(0.0, 0.0, 0.0, 0.8)    ## epischer Knopf: Schlagschatten der Schrift
const TINT_EPIC_DISABLED := Color(0.55, 0.55, 0.6)     ## epischer Knopf gesperrt
const TINT_NONE := Color(1, 1, 1, 1)         ## Bild unverändert
const TINT_DEAD := Color(0.5, 0.5, 0.55)     ## Porträt einer toten Person
const TINT_DISABLED := Color(0.62, 0.62, 0.66)  ## nicht wählbare Person oder gesperrte Lasche
const TINT_HOVER := Color(1.25, 1.2, 1.1)    ## Lasche unter Finger oder Zeiger
const TINT_ART_DONE := Color(0.8, 0.8, 0.84)  ## erledigter Schritt der Nachtleiste
const TINT_ART_OPEN := Color(1.3, 1.3, 1.3)  ## Rollensymbol der Nachtleiste, heller als das dunkle Medaillon
const PLATE_BG := Color(0.02, 0.03, 0.06, 0.66)   ## Namensschild unter dem Porträt
const NUMBER_BG := Color(0.03, 0.03, 0.05, 0.92)  ## Nummern-Abzeichen am Porträt
const CARD_BG := Color(0.03, 0.025, 0.05, 0.86)   ## Aktionskarte über dem Dorfplatz
const SHADE_EDGE := Color(0.012, 0.02, 0.05)      ## Randabdunklung des Hintergrundbilds

# --- Abstände, Radien, Rahmen --------------------------------------------------------------------
const SPACE_XS := 4
const BAR_GAP := 2                    ## Cockpit: Abstand zwischen Leisten und Brett sowie Innenrand der Leisten
const SPACE_S := 8
const SPACE_M := 16
const SPACE_L := 24
const SPACE_XL := 32
const RADIUS_S := 6
const RADIUS_M := 10
const RADIUS_L := 16
const BORDER_THIN := 1
const BORDER_THICK := 2
const FOCUS_WIDTH := 3

# --- Schrift (Engine-Standardschrift, Schriftentscheidung offen) --------------------------------
const FONT_CAPTION := 16
const FONT_COMPACT := 18              ## kompakte Buttons in Listenzeilen
const FONT_BODY := 20
const FONT_BUTTON := 22
const FONT_HEADING := 30
const FONT_SUBTITLE := 24
const FONT_TITLE := 64
const FONT_SHOW := 48                 ## gezeigte Karte: Ergebnis groß für die handelnde Person

# --- Bedienflächen und Layout --------------------------------------------------------------------
const TOUCH_MIN := 48                 ## Mindestgröße jeder Bedienfläche
const TOUCH_DRAG_DEADZONE := 16       ## Weg in Pixeln, ab dem ein Ziehen scrollt statt einen Knopf auszulösen
const BADGE_MIN := 24.0              ## kleinstes Zustandsabzeichen am Porträtplatz (Art Direction, Abschnitt 7)
const BUTTON_SECONDARY_HEIGHT := 56
const BUTTON_PRIMARY_HEIGHT := 64
const BUTTON_PRIMARY_MIN_WIDTH := 240
const SAFE_MARGIN := 16               ## Mindestrand zum Displayrand zusätzlich zur Safe Area
const SCREEN_PADDING := 24            ## Innenrand jeder Ansicht
const MENU_COLUMN_WIDTH := 480        ## Breite der Menüspalte (wächst auf breiten Fenstern nicht)
const CONTENT_MAX_WIDTH := 880        ## Textkarten auf breiten Fenstern
const TOOL_BUTTON_MIN_WIDTH := 96     ## Cockpit: Werkzeugleiste, auch kurze Beschriftungen („Log“) bleiben gut antippbar
const DRAWER_WIDTH := 520             ## Cockpit: Schublade für Protokoll und Spielleiterbereich
const SETUP_SIDE_WIDTH := 360        ## Spieler-Setup: Spalte für Eingabe, Import, Bearbeiten
const INPUT_HEIGHT := 56              ## Texteingabefelder
const IMPORT_TEXT_MIN_HEIGHT := 96    ## mehrzeiliges Importfeld
const GROUP_LIST_MIN_HEIGHT := 96     ## Liste gespeicherter Spielergruppen
const PERSON_NUMBER_WIDTH := 44       ## Listennummer in der Personenzeile
const ROLE_COUNT_WIDTH := 56          ## Anzahl zwischen Minus und Plus in der Rollenzeile
const ASSIGNMENT_STATE_WIDTH := 200   ## Spalte „zugewiesen“ bzw. Rolle und Scheinrolle in der Zuordnungszeile
const ROLE_LIST_MIN_HEIGHT := 240     ## Rollen- und Zuordnungsliste behalten mindestens so viel Höhe
const SEAT_CIRCLE_MIN_HEIGHT := 360   ## Sitzkreis: Mindesthöhe für zwei Reihen und die Tischmitte
const SCROLLBAR_WIDTH := 12
const TOAST_WIDTH := 420
const TOAST_BOTTOM_OFFSET := 88       ## Abstand der Statusmeldung vom unteren Rand (über einer Fußzeile)
const SWITCH_WIDTH := 64              ## Schaltersymbol (Bewegung reduzieren)
const SWITCH_HEIGHT := 32
const DIALOG_WIDTH := 560
const DIALOG_WIDE_WIDTH := 720       ## Dialog mit drei Aktionen
const DIALOG_LIST_RESERVED_HEIGHT := 300  ## Fensterhöhe für Titel, Text, Aktionen und Rand neben einer Auswahlliste
const WINDOW_MIN_WIDTH := 1024        ## Desktop-Mindestfenster (03 §8.2: 1024×640)
const WINDOW_MIN_HEIGHT := 640

# --- Vorbereitung „Neue Partie“ (Hain-Stil wie das Nachtbrett, kein Gold) ---------------------------------
const PREP_SHADE := Color(0.01, 0.014, 0.034, 0.7)   ## Abdunklung des Nachthintergrunds hinter der Vorbereitung
const PREP_CARD_TEXT := Color("#dde3ee")             ## Schrift auf den Hain-Karten (Mondsilber, etwas heller als MOON_SILVER)
const PREP_DASH_FILL := Color(0.043, 0.051, 0.078, 0.5)  ## Fläche der Marke „Rolle hinzufügen“
const MEDALLION_SIZE := 56            ## Schrittmedaillon oben (Tippfläche)
const COUNTER_BUTTON_SIZE := 72       ## Plus und Minus der Spielerzahl
const COUNTER_VALUE_FONT := 72        ## große Spielerzahl
const ACT_CARD_MIN_WIDTH := 260       ## Akt-Karte: schmalste Breite, zwei Spalten
const ACT_CARD_HEIGHT := 160
const TEAM_SYMBOL_SIZE := 48          ## Teamsymbol im Zähler
## Teamfarben der Rollenkacheln und Leistenmarken (Multiplikator auf das dunkle Namensschild `name_plate_short`, DA-91): gewählt volle Farbe,
## nicht gewählt entsättigt und dunkel.
const TEAM_PLATE_VILLAGE := Color(0.75, 1.45, 2.4)    ## kühles Mondblau
const TEAM_PLATE_WOLVES := Color(2.3, 0.5, 0.52)     ## dunkles Blutrot
const TEAM_PLATE_SOLO := Color(1.6, 1.0, 2.1)       ## gedämpftes Violett
## Glühen der gewählten Rollenkachel in Teamfarbe (Dorf Mondblau, Wölfe Blutrot, Einzelgänger Violett); Akt-Karte, Modus und Namensschild glühen rot.
## Startbildschirm (lebendiger Hintergrund): Mondschein, Wolfsaugen, ferner Schimmer, Nebelfarbe beim Zuziehen.
const START_MOON_GLOW := Color(0.72, 0.82, 1.0)
const START_EYES := Color(1.0, 0.14, 0.1)
const START_FLASH := Color(0.62, 0.72, 1.0)
const START_FOG_CLOSE := Color(0.1, 0.13, 0.2)
const START_SHADE := Color(0.01, 0.014, 0.03)
## Feuer der gewählten Akt-Karte nach Stufe I bis IV (`FireGlow`): Flammenfarbe außen, Kernfarbe nahe am Rahmen.
const FIRE_FLAME: Array[Color] = [Color(0.85, 0.2, 0.05), Color(0.95, 0.25, 0.04), Color(1.0, 0.3, 0.04), Color(1.0, 0.34, 0.05)]
const FIRE_CORE: Array[Color] = [Color(1.0, 0.55, 0.15), Color(1.0, 0.65, 0.2), Color(1.0, 0.75, 0.25), Color(1.0, 0.85, 0.4)]
const GLOW_VILLAGE := Color(0.35, 0.6, 1.0)
const GLOW_WOLVES := Color(0.82, 0.1, 0.14)
const GLOW_SOLO := Color(0.66, 0.4, 0.95)
const TEAM_PLATE_OFF := Color(0.72, 0.74, 0.8)       ## nicht gewählt
const NAME_PLATE_HEIGHT := 56         ## Namensschild (Tippfläche)
const NAME_PLATE_MIN_WIDTH := 196
const ROLE_CHIP_HEIGHT := 56          ## Rollenmarke in der Rollenübersicht
const ROLE_CHIP_ICON := 40
const ROLE_CHIP_MIN_WIDTH := 176
const PREP_SIDE_WIDTH := 320          ## Namensschritt: Spalte für Eingabe und Gruppen
const PREP_COUNT_COLUMN_WIDTH := 340   ## Runde: linke Spalte mit Spielerzahl und Teamzählern
const PREP_CONTENT_WIDTH := 1100      ## breitester Inhalt der Vorbereitung auf großen Fenstern
const FOOTER_HEIGHT := 72             ## Fußzeile mit Zurück und Weiter
const ROLE_BAR_MAX_HEIGHT := 260      ## Rollenleiste beim Zuordnen

# --- Bewegung ------------------------------------------------------------------------------------
const TRANSITION_SECONDS := 0.2       ## Einblenden neuer Ansichten
const TRANSITION_OFFSET := 12.0       ## kleine Positionsbewegung beim Einblenden
const TOAST_FADE_SECONDS := 0.15
const TOAST_VISIBLE_SECONDS := 2.5
const CARD_FADE_SECONDS := 0.15       ## Einblenden der Ansagekarte bei neuer Handlung
const BACKDROP_FADE_SECONDS := 0.3    ## Wechsel des Hintergrunds zwischen Nacht und Tag
