class_name RoleCatalog
extends RefCounted
## Rollen-Stammdaten: `dorfbewohner`, `werwolf` (A-06), die Vertical-Slice-Rollen `sensentraeger`, `schutzengel`, `waldhexe`, `das-orakel`, `trugbilderwolf`, `wolfskind`, `spiegelwolf`, `manipulator` und `lehrling` sowie aus dem Rollenaudit `siegreicher-wolf`, `doppelspion`, `selbstmoerder`, `dorfchronistin`, `die-gebundenen`, `waldlaeufer`, `doktor`, `wahnsinniger-kutscher`, `nachtwaechter`, `dorfwache`, `besessener-wolf`, `ritter`, `faehrtenleser`, `blutwolf`, `korrupter-richter`, `waechter-am-tor`, `spuerhund`, `parasit`, `schattenhund`, `albtraumwolf`, `giftwolf`, `rudelvater`, `seuchenwolf`, `fenrir`, `cerberus`, `henker` sowie die Informationsrollen `traumdeuter`, `kopfgeldjaeger`, `koenig`, `kriegerin-des-lichts`, `blutpriester`, `amalia`, `detektiv` und `die-ewigen` und die Schutzrollen `der-weise`, `maertyrerin`, `schutzgeist`, `dorfschmied` und `verdammniswaechter` und die Bindungsrollen `loki`, `schwarze-witwe`, `rotkaeppchen` und `schattenwanderer` sowie `daemonischer-wolf`, `koenig-lykaon`, `seelentauscher`, `kutscher` und `dr-victor-frankenstein` sowie `rattenfaenger`, `pestbringerin`, `prophet-des-untergangs` und `todesprediger` sowie `feuerteufel`, `voodoo-priester`, `nekromant` und `hades`.
## IDs nach DR-01: deutsches ASCII-kebab-case. Anzeigenamen sind nicht Teil des Kerns.
## Keine fest verdrahtete Rollenkomposition: Die Grundrollen haben keine Obergrenze,
## damit jede Personenzahl von 6 bis 24 allein mit ihnen spielbar ist. Spätere Rollen
## können `max_copies` setzen; wie viele Exemplare eine Partie tatsächlich nutzt,
## entscheidet die Rollenkomposition im Setup (Phase 2), nicht dieser Katalog.

const UNLIMITED := -1

const DORFBEWOHNER := &"dorfbewohner"
const WERWOLF := &"werwolf"
## Sensenträger / Reaper (rules-register.md §7, DR-09): Dorf, kein Nachtschritt,
## freiwillige Todesreaktion (Fluch auf eine lebende Person oder Verzicht).
const SENSENTRAEGER := &"sensentraeger"
## Schutzengel / Guardian Angel (rules-register.md §3, DR-05): Dorf, Nachtschritt vor
## dem Rudel, schützt eine andere lebende Person nur vor dem Wolfsangriff dieser Nacht.
const SCHUTZENGEL := &"schutzengel"
## Waldhexe / Forest Witch (rules-register.md §6, DR-06): Dorf, Nachtschritt nach dem
## Rudel, je ein Heil- und Gifttrank pro Person und Partie (WitchStep).
const WALDHEXE := &"waldhexe"
## Orakel / The Oracle (rules-register.md §4, DR-07): Dorf, Nachtschritt nach der
## Waldhexe, prüft eine andere lebende Person (OracleStep, InformationRules).
const ORAKEL := &"das-orakel"
## Trugbilderwolf / Decoy Wolf (rules-register.md §5, DR-08): Werwölfe, zählt als Wolf,
## kein eigener Schritt (Teil des Rudels). Seine Scheinrolle steht in `Player.appears_as`,
## wird beim Spielaufbau vom Spielleiter festgelegt und ist dort Pflicht.
const TRUGBILDERWOLF := &"trugbilderwolf"
## Wolfskind / Wolf Child (rules-register.md §8, DR-10): beginnt im Dorf, wählt in seiner
## ersten verfügbaren Nacht ein Vorbild und verwandelt sich bei dessen Tod (WolfChildRules).
const WOLFSKIND := &"wolfskind"
## Spiegelwolf / Mirror Wolf (rules-register.md §11, DR-13): Werwölfe, zählt als Wolf, Teil
## des Rudels; spiegelt einmal pro Person eine Hinrichtung auf die nominierende Person (ExecutionRules).
const SPIEGELWOLF := &"spiegelwolf"
## Manipulator (rules-register.md §10, DR-12): Einzelsieg, zählt nicht als Wolf, kein
## Nachtschritt; stirbt bei seiner Nominierung, gewinnt bei exakt drei Lebenden (WinRules).
const MANIPULATOR := &"manipulator"
## Lehrling / Apprentice (rules-register.md §9, DR-11): beginnt im Dorf, wählt verdeckt einen
## Meister aus drei Rollenoptionen und erbt dessen Rolle bei dessen Tod (ApprenticeRules).
const LEHRLING := &"lehrling"
## Siegreicher Wolf / Victorious Wolf (Rollentext, docs/role-migration/10-next-decisions.md):
## Werwölfe, zählt als Wolf, kein eigener Schritt (Teil des Rudels); zählt, solange er lebt,
## in der Wolfsparität wie zwei Wölfe (`parity_weight`, WinRules).
const SIEGREICHER_WOLF := &"siegreicher-wolf"
## Doppelspion / Double Agent (DECISION-LOG „Rollenaudit“, RM-DR-155): Einzelsieg, zählt nicht
## als Wolf, kein eigener Schritt (wacht mit dem Rudel nur als Ansage); gewinnt allein, wenn er
## lebt und kein Wolf mehr lebt; dann wird der Dorfsieg nicht vorgeschlagen (WinRules).
const DOPPELSPION := &"doppelspion"
## Selbstmörder / Death Seeker (DECISION-LOG „Rollenaudit“, RM-DR-138): Einzelsieg, zählt nicht als
## Wolf, kein Schritt; wird er hingerichtet (LYNCH), während mindestens 5 Personen tot sind, ist
## sein Sieg erfüllt (`GameState.death_seeker_wins`, KillPipeline) und wird fortan vorgeschlagen.
const SELBSTMOERDER := &"selbstmoerder"
## Dorfchronistin / Village Chronicler (DECISION-LOG „Rollenaudit“, RM-DR-014 = B, F-09): Dorf;
## persönlicher Informationsschritt nur in Nacht 1 (InfoSteps).
const DORFCHRONISTIN := &"dorfchronistin"
## Die Gebundenen / The Bound (DECISION-LOG „Rollenaudit“, RM-DR-014 = B, F-08): Dorf; ein
## gemeinsamer Informationsschritt aller Gebundenen nur in Nacht 1 (StepQueue.BOUND, InfoSteps).
const DIE_GEBUNDENEN := &"die-gebundenen"
## Priorität des gemeinsamen Schritts der Gebundenen (Legacy-Stufe 0.5).
## Waldläufer / Ranger (RM-DR-147): Dorf, Informationsschritt jede Nacht (InfoSteps).
const WALDLAEUFER := &"waldlaeufer"
## Doktor / Doctor (RM-DR-145): Dorf, Blutprobe zweier anderer Lebender jede Nacht (InfoSteps).
const DOKTOR := &"doktor"
## Wahnsinniger Kutscher / Mad Coachman (RM-DR-116): Dorf; wird er gelyncht, sterben seine nächsten
## lebenden Nachbarn mit (`COACHMAN_CRASH`, KillPipeline).
const WAHNSINNIGER_KUTSCHER := &"wahnsinniger-kutscher"
## Nachtwächter / Night Warden (RM-DR-102): Dorf; öffentliche Glocken bei Tagesbeginn (RulesEngine).
const NACHTWAECHTER := &"nachtwaechter"
## Dorfwache / Village Guard (RM-DR-119): Dorf; der Rudelangriff tötet sie nicht (KillPipeline).
const DORFWACHE := &"dorfwache"
## Besessener Wolf / Possessed Wolf (RM-DR-124): Wölfe; beim Tod mit mindestens 5 Lebenden (er
## eingeschlossen) Reaktion: eine andere lebende Person mitreißen oder verzichten.
const BESESSENER_WOLF := &"besessener-wolf"
const POSSESSED_MIN_LIVING := 5
## Ritter / Knight (RM-DR-136): Dorf; stirbt er durch Wolfsangriff, stirbt der nächste Wolf (KillPipeline).
const RITTER := &"ritter"
## Fährtenleser / Tracker (RM-DR-146): Dorf; einmal (je Leben) die Richtung des nächsten Wolfs (InfoSteps).
const FAEHRTENLESER := &"faehrtenleser"
## Blutwolf / Blood Wolf (RM-DR-133, RM-DR-008): Wölfe, Rudel; Stimmbonus nur als Hinweis (VoteHints).
const BLUTWOLF := &"blutwolf"
## Korrupter Richter / Corrupt Judge (RM-DR-117, RM-DR-012): Dorf; markiert nachts eine Person, die
## bei Tagesbeginn als von ihm nominiert gilt (verdeckt), +1 Stimme als Hinweis.
const KORRUPTER_RICHTER := &"korrupter-richter"
## Wächter am Tor / Gatewarden (RM-DR-149): Dorf; blockiert neu entstehende Wölfe (Gatewarden).
const WAECHTER_AM_TOR := &"waechter-am-tor"
## Spürhund / Scent Hound (RM-DR-105): Dorf; jede Nacht freiwillig drei Personen prüfen, ✗ kostet die Fähigkeit (InfoSteps).
const SPUERHUND := &"spuerhund"
## Parasit / Parasite (RM-DR-157): Einzelsieg; Wirt jede Nacht wählbar, mit lebendem Wirt unverwundbar,
## stirbt mit dem Wirt; Sieg bei höchstens drei Lebenden (KillPipeline, WinRules).
const PARASIT := &"parasit"
## Schattenhund / Shadow Hound (RM-DR-123): Wölfe; einmal je Leben alle Dorf-Nachtschritte einer Nacht blockieren.
const SCHATTENHUND := &"schattenhund"
## Albtraumwolf / Nightmare Wolf (RM-DR-134): Wölfe; jede Nacht freiwillig eine Person blockieren.
const ALBTRAUMWOLF := &"albtraumwolf"
## Giftwolf / Poison Wolf (RM-DR-111): Wölfe; zwei verzögerte, unaufhaltbare Vergiftungen je Leben.
const GIFTWOLF := &"giftwolf"
## Rudelvater / Packfather (RM-DR-112): Wölfe; überlebt einmal einen Tod außer Rudel/Lynch/Korrektur;
## sein Lynch gibt einen zusätzlichen, durchdringenden Rudelschritt in der nächsten Nacht.
const RUDELVATER := &"rudelvater"
## Seuchenwolf / Blight Wolf (RM-DR-108): Wölfe; nach seinem Tod durchdringt der nächste Rudelangriff Schutz.
const SEUCHENWOLF := &"seuchenwolf"
## Fenrir (RM-DR-125): Wölfe; Stufe je überlebter Nacht, ab Stufe 3 überlebt er einmal jeden Tod.
const FENRIR := &"fenrir"
## Cerberus (RM-DR-135): Wölfe; Köpfe je überlebter Nacht (max. 3), bei 3 kann er eine Hinrichtung abwehren.
const CERBERUS := &"cerberus"
const CERBERUS_MAX_HEADS := 3
const FENRIR_SHIELD_STAGE := 3
## Henker / Executioner (RM-DR-130): Dorf; ab 3 Hinrichtungen nachts markieren, Zusatztod bei der nächsten Hinrichtung.
const HENKER := &"henker"
const HANGMAN_MIN_EXECUTIONS := 3
## Traumdeuter / Dreamer (Rollenaudit I-01, I-05): Dorf; jede Nacht drei andere Lebende, mindestens ein Wolf (InfoSteps).
const TRAUMDEUTER := &"traumdeuter"
## Kopfgeldjäger / Bounty Hunter (I-04, I-06): Dorf; je Wolfs-Lynch eine Liste wie beim Traumdeuter (InfoSteps).
const KOPFGELDJAEGER := &"kopfgeldjaeger"
## König / King (I-03): Dorf; einmal je Leben, sobald mehr Tote als Lebende, eine Dorfperson mit Rolle (InfoSteps).
const KOENIG := &"koenig"
## Kriegerin des Lichts / Warrior of Light (I-07): Dorf; einmal je Leben Wolf? prüfen, bei Irrtum Tod am Morgen.
const KRIEGERIN := &"kriegerin-des-lichts"
## Blutpriester / Blood Priest (I-08, I-13): Dorf; einmal je Leben eine andere Person opfern, 0–3 Wölfe erfahren.
const BLUTPRIESTER := &"blutpriester"
## Amalia (I-09): Dorf; Tagesaktion bei mindestens drei lebenden Wölfen: Selbstopfer mit öffentlicher Antwort.
const AMALIA := &"amalia"
const AMALIA_MIN_WOLVES := 3
## Detektiv / Detective (I-10, I-14): Dorf; öffentlicher Richtungshinweis nach jedem Wolfstod (KillPipeline).
const DETEKTIV := &"detektiv"
## Die Ewigen / The Eternal Ones (I-11, I-12, I-15): Dorf; gemeinsame Prüfung „Einzelsieg?“, Mitsieg (WinRules).
const DIE_EWIGEN := &"die-ewigen"
## Der Weise / The Elder (Rollenaudit S-01, S-02, S-05, S-09): Dorf; überlebt einmal einen tödlichen Rudelangriff;
## sein Lynch lässt 0–3 Nächte und Tage alle Fähigkeiten der Dorfpersonen ruhen (SageCurse).
const DER_WEISE := &"der-weise"
const SAGE_MAX_CURSE := 3
## Märtyrerin / Martyr (S-03, S-14): Dorf; am Ende der Nacht Ersatzopfer für das erste Rudelopfer.
const MAERTYRERIN := &"maertyrerin"
## Schutzgeist / Guardian Spirit (S-04): Dorf; in der ersten Nacht nach ihrem Tod ein Schild vergeben.
const SCHUTZGEIST := &"schutzgeist"
## Dorfschmied / Village Blacksmith (S-06): Dorf; ab Nacht 6 eine Waffe vergeben (einmal je Leben).
const DORFSCHMIED := &"dorfschmied"
const SMITH_FIRST_NIGHT := 6
## Verdammniswächter / Doom Warden (S-07, S-08, S-13): Dorf; lenkt den ersten Rudelangriff wahlweise um.
const VERDAMMNISWAECHTER := &"verdammniswaechter"
## Loki (Rollenaudit B-01, B-02, B-05): Dorf; nur Nacht 1, freiwillig zwei Lebende als Liebende oder Rivalen (BondSteps).
const LOKI := &"loki"
## Schwarze Witwe / Black Widow (B-03, B-06): Wölfe; jede Nacht ein Ziel, lebendes Paar stirbt am Morgen.
const SCHWARZE_WITWE := &"schwarze-witwe"
## Rotkäppchen / Little Red Riding Hood (R-01 bis R-04): Dorf; Zuflucht, Apfel und Todeskette (BondSteps).
const ROTKAEPPCHEN := &"rotkaeppchen"
## Schattenwanderer / Shadowwalker (B-04, B-07): Wölfe; einmal je Leben verknüpfen, Tod wird umgelenkt.
const SCHATTENWANDERER := &"schattenwanderer"
## Dämonischer Wolf / Demonic Wolf (V-01, V-02, V-07): Wölfe; Todesreaktion: eine Person verfluchen (nur Rollenauskünfte).
const DAEMONISCHER_WOLF := &"daemonischer-wolf"
## König Lykaon / King Lycaon (V-03, V-08, V-09): Wölfe; macht eine Dorfperson zum Trugbilderwolf (BondSteps).
const KOENIG_LYKAON := &"koenig-lykaon"
const LYCAON_MAX_SKIPS := 3
## Seelentauscher / Soul Swapper (V-04 bis V-06): Dorf; tauscht einmal die Rollen zweier Personen (BondSteps).
const SEELENTAUSCHER := &"seelentauscher"
## Kutscher / Coachman (W-02, W-03): Dorf; ab 10 Toten einmal drei Tote wiederbeleben, einer wird Werwolf (BondSteps).
const KUTSCHER := &"kutscher"
const COACH_MIN_DEAD := 10
const COACH_REVIVALS := 3
## Dr. Victor Frankenstein (W-04): Dorf; einmal einen Toten mit einer freien Nicht-Wolf-Rolle wiederbeleben (BondSteps).
const FRANKENSTEIN := &"dr-victor-frankenstein"
## Rattenfänger / Pied Piper (E-01): Einzelsieg; jede Nacht 1–2 verzaubern, Sieg bei allen anderen verzaubert.
const RATTENFAENGER := &"rattenfaenger"
## Pestbringerin / Plague Bringer (E-02): Einzelsieg; jede Nacht infizieren, Ausbreitung am Morgen, Sieg bei Totalinfektion.
const PESTBRINGERIN := &"pestbringerin"
## Prophet des Untergangs / Prophet of Doom (E-03): Einzelsieg; drei markieren, dann töten, Sieg statt des Dorfes.
const PROPHET := &"prophet-des-untergangs"
const PROPHET_MARKS := 3
## Todesprediger / Death Prophet (E-04): Einzelsieg; geheime Vorhersage des eigenen Todes (BondSteps).
const TODESPREDIGER := &"todesprediger"
## Feuerteufel / Pyromaniac (E-05 bis E-11): Einzelsieg; eine Markierung, beim Tod des Ziels brennen dessen
## nächste lebende Nachbarn (Feuerteufel verschont); Mitsieg lebend (SoloRules, WinRules).
const FEUERTEUFEL := &"feuerteufel"
## Voodoo-Priester / Voodoo Priest (E-12 bis E-15, E-20 bis E-23): Einzelsieg; eine geheime Puppe stirbt statt seiner
## (KillPipeline); Sieg allein lebend bei höchstens drei Lebenden (WinRules).
const VOODOO := &"voodoo-priester"
const VOODOO_MAX_LIVING := 3
## Nekromant / Necromancer (E-16 bis E-19, E-24 bis E-26): Einzelsieg; drei Tote opfern für einen globalen Schild
## oder (nur als sterbendes Rudelopfer) für eine Umlenkung; einmal je Tag Wolf benennen, Treffer = Alleinsieg.
const NEKROMANT := &"nekromant"
const NECRO_SACRIFICE := 3
## Hades (E-28 bis E-31): Lichter aus jedem tatsächlichen Tod anderer; Tötung für 2, Barriere für 3; Alleinsieg lebend ab 10.
const HADES := &"hades"
const HADES_KILL_COST := 2
const HADES_BARRIER_COST := 3
const HADES_WIN_LIGHTS := 10
## Rollen, deren eigener Nachtschritt jede Nacht stattfindet und durch einen Apfel verdoppelt wird (R-02, R-04);
## ausgenommen Rollen mit nur einem Ergebnis (Richter, Parasit, Verdammniswächter, Rotkäppchen).
const APPLE_ROLES: Array[StringName] = [SCHUTZENGEL, ORAKEL, SPUERHUND, ALBTRAUMWOLF, HENKER, WALDLAEUFER, DOKTOR, TRAUMDEUTER, SCHWARZE_WITWE,
	RATTENFAENGER, PESTBRINGERIN, PROPHET, FEUERTEUFEL]  ## Prophet nur freigeschaltet (Tötung jede Nacht)
const BOUND_PRIORITY := 5
const ETERNAL_PRIORITY := 48  ## gemeinsamer Schritt der Ewigen (Legacy-Stufe 4.8)

## Alle begrenzten Einsätze in `Player.ability_uses` (G-ID-3), je höchstens einmal pro Person.
const ABILITY_USE_KEYS: Array[String] = ["sensentraeger:death_reaction", "waldhexe:heal", "waldhexe:poison", "spiegelwolf:mirror",
	"besessener-wolf:death_reaction", "ritter:death_reaction", "faehrtenleser:track", "spuerhund:lost",
	"schattenhund:block", "giftwolf:paw1", "giftwolf:paw2", "rudelvater:survive", "fenrir:survive",
	"koenig:learn", "kriegerin-des-lichts:attack", "blutpriester:sacrifice", "der-weise:survive", "schutzgeist:shield",
	"dorfschmied:weapon", "loki:bind", "schattenwanderer:link", "daemonischer-wolf:death_reaction", "koenig-lykaon:convert",
	"koenig-lykaon:skip1", "koenig-lykaon:skip2", "koenig-lykaon:skip3", "seelentauscher:swap", "kutscher:revive",
	"dr-victor-frankenstein:revive", "todesprediger:predict"]

## Nachtpriorität persönlicher Schritte (vertical-slice-flow.md §3, ×10 als Ganzzahl):
## Wolfskind 0.9 (nur mit Auswahlbedarf), Lehrling 1.1 (nur mit Auswahlbedarf), Schutzengel 1.3, Rudel 2.0, Waldhexe 3.4, Orakel 4.6. Gleiche Priorität: nach Personen-ID.
const PACK_PRIORITY := 20

const ROLES := {
	DORFBEWOHNER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFBEWOHNER},
	WERWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": WERWOLF},
	SCHUTZENGEL: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": SCHUTZENGEL, "night_priority": 13},
	WALDHEXE: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": WALDHEXE, "night_priority": 34},
	ORAKEL: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": ORAKEL, "night_priority": 46},
	WOLFSKIND: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": WOLFSKIND, "night_priority": 9},
	LEHRLING: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": LEHRLING, "night_priority": 11},
	MANIPULATOR: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": MANIPULATOR},
	SPIEGELWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SPIEGELWOLF},
	TRUGBILDERWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": TRUGBILDERWOLF, "requires_appearance": true},
	SENSENTRAEGER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": SENSENTRAEGER, "death_reaction": Reaction.KIND_CURSE},
	SIEGREICHER_WOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SIEGREICHER_WOLF, "parity_weight": 2},
	DOPPELSPION: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": DOPPELSPION},
	SELBSTMOERDER: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": SELBSTMOERDER},
	DORFCHRONISTIN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFCHRONISTIN, "night_priority": 3, "first_night_only": true},
	DIE_GEBUNDENEN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DIE_GEBUNDENEN},
	WALDLAEUFER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": WALDLAEUFER, "night_priority": 54},
	DOKTOR: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DOKTOR, "night_priority": 50},
	WAHNSINNIGER_KUTSCHER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": WAHNSINNIGER_KUTSCHER},
	NACHTWAECHTER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": NACHTWAECHTER},
	DORFWACHE: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFWACHE},
	BESESSENER_WOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": BESESSENER_WOLF, "death_reaction": Reaction.KIND_POSSESSED},
	RITTER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": RITTER},
	FAEHRTENLESER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": FAEHRTENLESER, "night_priority": 52},
	BLUTWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": BLUTWOLF},
	KORRUPTER_RICHTER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": KORRUPTER_RICHTER, "night_priority": 15},
	WAECHTER_AM_TOR: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": WAECHTER_AM_TOR},
	SPUERHUND: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": SPUERHUND, "night_priority": 68},
	PARASIT: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": PARASIT, "night_priority": 62},
	SCHATTENHUND: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SCHATTENHUND, "night_priority": 1},
	ALBTRAUMWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": ALBTRAUMWOLF, "night_priority": 2},
	GIFTWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": GIFTWOLF, "night_priority": 27},
	RUDELVATER: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": RUDELVATER},
	SEUCHENWOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SEUCHENWOLF},
	FENRIR: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": FENRIR},
	CERBERUS: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": CERBERUS},
	HENKER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": HENKER, "night_priority": 78},
	TRAUMDEUTER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": TRAUMDEUTER, "night_priority": 70},
	KOPFGELDJAEGER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": KOPFGELDJAEGER, "night_priority": 32},
	KOENIG: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": KOENIG, "night_priority": 44},
	KRIEGERIN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": KRIEGERIN, "night_priority": 60},
	BLUTPRIESTER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": BLUTPRIESTER, "night_priority": 82},
	AMALIA: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": AMALIA},
	DETEKTIV: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DETEKTIV},
	DIE_EWIGEN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DIE_EWIGEN},
	DER_WEISE: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DER_WEISE},
	MAERTYRERIN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": MAERTYRERIN, "night_priority": 90},
	SCHUTZGEIST: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": SCHUTZGEIST, "night_priority": 56},
	DORFSCHMIED: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": DORFSCHMIED, "night_priority": 17},
	VERDAMMNISWAECHTER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": VERDAMMNISWAECHTER, "night_priority": 23},
	LOKI: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": LOKI, "night_priority": 4, "first_night_only": true},
	SCHWARZE_WITWE: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SCHWARZE_WITWE, "night_priority": 28},
	ROTKAEPPCHEN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": ROTKAEPPCHEN, "night_priority": 74},
	SCHATTENWANDERER: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": SCHATTENWANDERER, "night_priority": 26},
	DAEMONISCHER_WOLF: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": DAEMONISCHER_WOLF, "death_reaction": Reaction.KIND_DEMON},
	KOENIG_LYKAON: {"faction": Faction.WOLVES, "counts_as_wolf": true, "appears_as": KOENIG_LYKAON, "night_priority": 24},
	SEELENTAUSCHER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": SEELENTAUSCHER, "night_priority": 80},
	KUTSCHER: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": KUTSCHER, "night_priority": 38},
	FRANKENSTEIN: {"faction": Faction.VILLAGE, "counts_as_wolf": false, "appears_as": FRANKENSTEIN, "night_priority": 36},
	RATTENFAENGER: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": RATTENFAENGER, "night_priority": 42},
	PESTBRINGERIN: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": PESTBRINGERIN, "night_priority": 72},
	PROPHET: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": PROPHET, "night_priority": 86},
	TODESPREDIGER: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": TODESPREDIGER, "night_priority": 66, "first_night_only": true},
	FEUERTEUFEL: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": FEUERTEUFEL, "night_priority": 76},
	VOODOO: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": VOODOO, "night_priority": 84},
	NEKROMANT: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": NEKROMANT, "night_priority": 30},
	HADES: {"faction": Faction.SOLO, "counts_as_wolf": false, "appears_as": HADES, "night_priority": 99},  ## Legacy-Stufe 9.9: zuletzt
}


static func has_role(role_id: StringName) -> bool:
	return ROLES.has(role_id)


static func faction_of(role_id: StringName) -> StringName:
	return ROLES[role_id]["faction"]


static func counts_as_wolf(role_id: StringName) -> bool:
	return ROLES[role_id]["counts_as_wolf"]


static func appears_as(role_id: StringName) -> StringName:
	return ROLES[role_id]["appears_as"]


## Art der Todesreaktion oder &"" ohne Reaktion.
static func death_reaction(role_id: StringName) -> StringName:
	return (ROLES[role_id] as Dictionary).get("death_reaction", &"")


## Nachtpriorität des eigenen Schritts jeder lebenden Person mit dieser Rolle
## (vergleichbar mit PACK_PRIORITY) oder 0 ohne eigenen Nachtschritt.
static func night_priority(role_id: StringName) -> int:
	return (ROLES[role_id] as Dictionary).get("night_priority", 0)


## true, wenn der persönliche Schritt der Rolle nur in Nacht 1 stattfindet (RM-DR-014 = B).
static func first_night_only(role_id: StringName) -> bool:
	return (ROLES[role_id] as Dictionary).get("first_night_only", false)


## true, wenn jede Instanz der Rolle eine vom Spielleiter festgelegte Scheinrolle braucht.
static func requires_appearance(role_id: StringName) -> bool:
	return (ROLES[role_id] as Dictionary).get("requires_appearance", false)


## Zulässige Scheinrolle: eine bekannte Rolle, die nicht als Wolf zählt
## (also weder `werwolf` noch `trugbilderwolf`); sie muss nicht in der Partie vorkommen.
static func is_valid_appearance(role_id: StringName) -> bool:
	return has_role(role_id) and not counts_as_wolf(role_id)


## Gewicht einer lebenden Person dieser Rolle in der Wolfsparität (G-SIEG-2), sonst 1.
## Nur für Rollen, die als Wolf zählen; Personenzählungen (DR-12) nutzen es nie.
static func parity_weight(role_id: StringName) -> int:
	return (ROLES[role_id] as Dictionary).get("parity_weight", 1)


## Höchstzahl je Partie oder UNLIMITED, wenn die Rolle keine eigene Grenze hat.
static func max_copies(role_id: StringName) -> int:
	return (ROLES[role_id] as Dictionary).get("max_copies", UNLIMITED)
