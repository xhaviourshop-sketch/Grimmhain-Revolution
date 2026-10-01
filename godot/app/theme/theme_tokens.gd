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
const BOARD_DAY := Color("#1c160d")          ## Spielbrett am Morgen und Tag: dunkles Dämmerbraun

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

# --- Bewegung ------------------------------------------------------------------------------------
const TRANSITION_SECONDS := 0.2       ## Einblenden neuer Ansichten
const TRANSITION_OFFSET := 12.0       ## kleine Positionsbewegung beim Einblenden
const TOAST_FADE_SECONDS := 0.15
const TOAST_VISIBLE_SECONDS := 2.5
const CARD_FADE_SECONDS := 0.15       ## Einblenden der Ansagekarte bei neuer Handlung
const BACKDROP_FADE_SECONDS := 0.3    ## Wechsel des Hintergrunds zwischen Nacht und Tag
