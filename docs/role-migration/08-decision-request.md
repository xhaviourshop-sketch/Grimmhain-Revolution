# 08 · Entscheidungsanfrage Rollenmigration

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · **Status:** offen, nichts ist entschieden

Nur echte Product-Owner-Entscheidungen. Bereits entschiedene Punkte aus [`../masterplan/DECISION-LOG.md`](../masterplan/DECISION-LOG.md) (DR-01 bis DR-14 und Folgeeinträge) werden nicht erneut gefragt, nur als Rahmen genannt. Empfehlungen sind Vorschläge.

**Aufbau**
- §1 Querschnittsentscheidungen RM-DR-001 bis RM-DR-016. Sie werden einmal entschieden und gelten für alle Rollen. Viele rollenspezifische Fragen erledigen sich dadurch.
- §2 Rollenentscheidungen RM-DR-101 bis RM-DR-158, je fehlender Rolle eine Sammelentscheidung mit allen Teilfragen aus [`04`](04-rule-conflicts.md). Nicht enthalten sind die drei Rollen mit Status `documented-only` (`siegreicher-wolf`, `die-gebundenen`, `dorfchronistin`), deren Standardauslegung in [`03`](03-remaining-roles-analysis.md) und im Dossier steht.

**„Blockiert Version 1.0“** bezieht sich auf die empfohlene Option B aus [`05`](05-v1-role-options.md) (25 Rollen). Bei Wahl von Option C blockieren zusätzlich die Entscheidungen zu `nachtwaechter`, `die-gebundenen` (keine eigene), `koenig-lykaon`, `der-weise` und `parasit`.

**Für die erste Charge K1** (`siegreicher-wolf`, `selbstmoerder`, `doppelspion`) sind genau diese Entscheidungen nötig: **RM-DR-007**, **RM-DR-016**, **RM-DR-138** (`selbstmoerder`), **RM-DR-155** (`doppelspion`). Siehe [`06`](06-implementation-batches.md) §3.

## Übersicht

| ID | Thema | Blockiert Charge | Blockiert 1.0 |
|---|---|---|---|
| RM-DR-001 | Einsätze und Zustände pro Person | K4 bis K16 | Ja |
| RM-DR-002 | Einheitliche Wolfsdefinition | K1 (nur `doppelspion`), K2, K3, K5, K7 und später | Ja |
| RM-DR-003 | Sitznachbarschaft und Richtung | K3, K9, K14 | Ja |
| RM-DR-004 | Begriff „Wolfsangriff“ | K4, K5, K6, K11 | Ja |
| RM-DR-005 | Durchdringung | K5, K11, K15 | Nein |
| RM-DR-006 | Rollen ohne Siegcode oder Siegtext | K9, K10, K11, K15 | Nein |
| RM-DR-007 | Dorf-/Wolfssieg bei lebenden Einzelsiegrollen | K1 | Ja |
| RM-DR-008 | Stimmbezogene Rollentexte | K14, K15 | Nein |
| RM-DR-009 | Zeitpunkt aller Todesreaktionen | K3, K4, K6, K9, K10, K12 | Ja |
| RM-DR-010 | Rollenblockierung | K8, K16 | Ja |
| RM-DR-011 | Wiederbelebung | K6, K10, K13 | Ja |
| RM-DR-012 | Nominierung durch den Korrupten Richter | K14 | Nein |
| RM-DR-013 | Totenkarten-Abhängigkeit | K13, K15 | Nein |
| RM-DR-014 | „einmalig“ und „erste Nacht“ | K2, K6, K7, K8, K11, K12, K15 | Ja |
| RM-DR-015 | Zufall mit Seed oder Spielleiterwahl | K3, K5, K7, K9, K11, K13 | Ja |
| RM-DR-016 | Obergrenze gleicher Sonderrollen | K1 und alle folgenden | Ja |

## 1. Querschnittsentscheidungen

## RM-DR-001 · Einsätze und Zustände pro Person

- **Betroffene Rollen:** alle Rollen mit begrenztem Einsatz, Zähler oder Rollenzustand (u. a. `loki`, `giftwolf`, `rachsuechtiger-wolf`, `maertyrerin`, `kutscher`, `hades`, `dorfschmied`, `kriegerin-des-lichts`).
- **Problem:** Legacy speichert Verbrauch und Zustände global pro Rollenname. Mehrere Kopien teilen sich einen Einsatz, ein Erbe übernimmt fremde Stände.
- **Belege:** `js/core/night.js:3-5` (`markOnceUsed`), `js/ui/core.js:339-359` (`resetOnceForInheritedRole`), [`04`](04-rule-conflicts.md) §2 Zeile 1. Godot: `Player.ability_uses`, DR-11 „vollständig zurückgesetzte Nutzungen“, DECISION-LOG Waldhexe „pro Person und Partie“.
- **Option A:** Jeder Einsatz, Zähler und Rollenzustand gehört der Person und der Rolleninstanz. Rollenwechsel startet mit frischen Einsätzen der neuen Rolle (wie DR-11). Wiederbelebung setzt nichts zurück (wie Waldhexe).
- **Option B:** Einsätze pro Rolle in der Partie (Legacy). Mehrere Kopien teilen sich den Einsatz.
- **Auswirkung:** A passt zum vorhandenen Kern und macht mehrere Kopien und Erbe testbar. B erzwingt globale Zähler neben `ability_uses` und widerspricht DR-11.
- **Empfehlung:** A.
- **Blockiert:** K4 bis K16. **Blockiert 1.0:** Ja.

## RM-DR-002 · Einheitliche Wolfsdefinition

- **Betroffene Rollen:** 24, u. a. `waldlaeufer`, `doktor`, `ritter`, `kopfgeldjaeger`, `doppelspion`, `nachtwaechter`, `spuerhund`, `detektiv`, `dorfschmied`, `daemonischer-wolf`.
- **Problem:** Legacy nutzt drei verschiedene Wolfsbegriffe (`isWolf` mit Fluch, Rollenfraktion, `WOLF_ROLES_SET`). Dieselbe Person ist je nach Rolle Wolf oder nicht.
- **Belege:** `js/ui/core.js:8-19`; [`04`](04-rule-conflicts.md) §2; Godot `InformationRules.determine_role` und DR-07.
- **Option A:** Zwei Begriffe mit klarer Trennung: **Wirkungen** (Tötungsziele, Zählungen für Sieg, Ritter, Schmiedwaffe, Waldläufer-Zahl) nutzen `counts_as_wolf`. **Informationen, die einer Person gezeigt werden** (Orakel, Doktor, Detektiv-Hinweis, Kopfgeldjäger-Liste) nutzen eine zentrale Informationsregel, die `appears_as` berücksichtigt (Erweiterung von `InformationRules`).
- **Option B:** Überall nur `counts_as_wolf` (Wahrheit). Erscheinungen wirken nur beim Orakel.
- **Option C:** Überall die Erscheinung.
- **Auswirkung:** A erhält Fehlinformation als Spieleffekt (DECISION-LOG) und ist eindeutig testbar. B vereinfacht, macht aber Trugbilderwolf und Dämonen-Fluch fast wirkungslos. C lässt Täuschung Siegbedingungen verändern.
- **Empfehlung:** A. Welche Rolle zu welcher Gruppe gehört, steht in den Rollenentscheidungen.
- **Blockiert:** K1 (`doppelspion`: Erscheinung), K2, K3, K5, K7 und später. **Blockiert 1.0:** Ja.

## RM-DR-003 · Sitznachbarschaft und Richtung

- **Betroffene Rollen:** `nachtwaechter`, `wahnsinniger-kutscher`, `ritter`, `faehrtenleser`, `detektiv`, `feuerteufel`, `pestbringerin`, `blutwolf`.
- **Problem:** Legacy hat zwei Nachbarbegriffe (direkter Sitz, nächster Lebender) und zwei entgegengesetzte „links“. Alle rechnen mit der Personen-ID als Sitzindex; Godot trennt `seat_order` von der ID und erlaubt Sitztausch.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 3; `godot/core/model/game_state.gd:22` (`seat_order` im Uhrzeigersinn).
- **Option A:** Eine Funktion `SeatNeighbors` über `seat_order`. Wirkungen auf Personen (Kutscher-Mitnahme, Brand, Seuche, Ritter-Ziel, Nachtwächter) treffen die **nächsten lebenden** Nachbarn; Zählungen über Tote (Blutwolf) nutzen die **direkten** Sitze. „Links“ ist die Richtung aus Sicht der Person, die zur Tischmitte schaut; die Zuordnung zur Bildschirmdarstellung wird am Gerät geprüft.
- **Option B:** Überall direkte Sitze, auch tote.
- **Option C:** Je Rolle wie Legacy.
- **Auswirkung:** A ist einheitlich und am Tisch erklärbar; B ist einfacher, aber tote Nachbarn schwächen Kutscher und Ritter; C übernimmt die Legacy-Widersprüche.
- **Empfehlung:** A. Die EN-Formulierung „living neighbours“ des Wahnsinnigen Kutschers und `07` Q1 stützen A.
- **Blockiert:** K3, K9, K14. **Blockiert 1.0:** Ja (`ritter`, `wahnsinniger-kutscher`).

## RM-DR-004 · Begriff „Wolfsangriff“

- **Betroffene Rollen:** 13, u. a. `dorfwache`, `der-weise`, `ritter`, `rudelvater`, `seuchenwolf`, `dorfschmied`, `schutzgeist`, `maertyrerin`, `besessener-wolf`.
- **Problem:** Viele Texte beziehen sich auf „Werwolfangriff“; Legacy unterscheidet Rudelkill, Zusatzopfer und Einzelkills von Wolfsrollen nicht.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 4; DR-05 legt für den Schutzengel bereits „nur Rudelangriff“ fest.
- **Option A:** „Wolfsangriff“ ist ausschließlich der Rudelangriff (`NIGHT_KILL`, Quelle Rudel) einschließlich weiterer Rudelopfer derselben Art (Rudelvater, Schicksalswolf). Einzelkills von Wolfsrollen (Rachsüchtiger Wolf, Giftwolf, Schwarze Witwe, Besessener Wolf) haben eigene Ursachen und sind keine Wolfsangriffe.
- **Option B:** Jeder Tod, dessen Quelle eine Wolfsrolle ist.
- **Auswirkung:** A setzt DR-05 konsequent fort und hält Schutzrollen einfach; B macht Schutzrollen stärker und verlangt für jede Wolfsrolle eine Einzelprüfung.
- **Empfehlung:** A, mit ausdrücklicher Ursachenliste je neuer Todesursache (Attribut `wolf_attack` im `KillEvent`).
- **Blockiert:** K4, K5, K6, K11. **Blockiert 1.0:** Ja (`dorfwache`, `ritter`, `besessener-wolf`).

## RM-DR-005 · Durchdringung von Schutz, Immunität und Schilden

- **Betroffene Rollen:** `seuchenwolf`, `rudelvater`, `verdammniswaechter`, `schicksalswolf` (auslösend); `dorfwache`, `der-weise`, `dorfschmied`, `nekromant`, `hades`, `kartenschlucker` (betroffen).
- **Problem:** Zwei Legacy-Regeln „ignoriert Schutz“ durchdringen unterschiedliche Abfangstufen; der Text sagt jeweils „alle“.
- **Belege:** `js/ui/core.js:126-143`; [`04`](04-rule-conflicts.md) §2 Zeile 5.
- **Option A:** Ein Attribut `pierces` am Angriff mit einer festen Liste: durchdringt Schutzengel, Waldhexenrettung, Dorfwache-Immunität und die Rettung des Weisen; nicht die persönlichen Schilde der Einzelsiegrollen, nicht Umlenkungen (Schattenwanderer, Voodoo), nicht Ersatzopfer (Märtyrerin).
- **Option B:** `pierces` durchdringt jede Abfangstufe.
- **Auswirkung:** A hält Einzelsiegrollen spielbar; B macht Durchdringung sehr stark und einfach zu erklären.
- **Empfehlung:** A.
- **Blockiert:** K5, K11, K15. **Blockiert 1.0:** Nein.

## RM-DR-006 · Rollen ohne Siegcode oder ohne Siegtext

- **Betroffene Rollen:** `prophet-des-untergangs`, `grabraeuber`, `die-ewigen` (Siegtext ohne Code); `feuerteufel`, `voodoo-priester`, `pestbringerin` (Einzelsiegfraktion ohne Siegtext; Pest hat Code); `rachsuechtiger-wolf` (Siegtext widerspricht Code).
- **Problem:** `07` Q4 ist offen; ohne Siegbedingung sind diese Rollen nicht vollständig automatisierbar.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 8; [`../godot-migration/07-open-questions.md`](../godot-migration/07-open-questions.md) Q4.
- **Option A:** Siegbedingungen jetzt je Rolle festlegen (in den Rollenentscheidungen).
- **Option B:** Bis zur Festlegung nur die vorhandene Spielleitererklärung `GmCorrection declare_winner`; Rolle gilt als `assisted`.
- **Option C:** Diese Rollen bleiben außerhalb von 1.0.
- **Auswirkung:** A vollständig, aber Regeldesign; B sofort spielbar; C reduziert Umfang. Keine der Rollen ist in den Optionen A bis C aus `05` enthalten.
- **Empfehlung:** C für 1.0, danach A je Charge.
- **Blockiert:** K9, K10, K11, K15. **Blockiert 1.0:** Nein.

## RM-DR-007 · Dorf- und Wolfssieg bei lebenden Einzelsiegrollen

- **Betroffene Rollen:** alle 13 fehlenden Einzelsiegrollen, zusätzlich der umgesetzte `manipulator`.
- **Problem:** Legacy lässt das Dorf gewinnen, sobald kein Wolf lebt, auch wenn Einzelsiegrollen leben (Ausnahme Doppelspion). Godot erzeugt heute ebenfalls den Dorfkandidaten bei null Wölfen; es ist nicht entschieden, ob das so bleiben soll.
- **Belege:** `js/ui/core.js:218-239`, `:287-337`; `godot/core/rules/win_rules.gd:18-37`; DR-02, DR-14.
- **Option A:** Wie heute: Dorf- und Wolfskandidat entstehen unabhängig von lebenden Einzelsiegrollen; Einzelsiegbedingungen erzeugen eigene Kandidaten; der Spielleiter bestätigt genau einen (DR-02).
- **Option B:** Der Dorfkandidat entsteht erst, wenn keine Einzelsiegrolle mit noch erreichbarer Siegbedingung lebt.
- **Option C:** Einzelsiegrollen blockieren nur den Dorfsieg, nicht den Wolfssieg.
- **Auswirkung:** A ändert nichts am Kern und bleibt DR-02-konform; B verlängert Partien und braucht je Rolle eine Definition „erreichbar“; C ist asymmetrisch.
- **Empfehlung:** A.
- **Blockiert:** K1. **Blockiert 1.0:** Ja.

## RM-DR-008 · Stimmbezogene Rollentexte ohne digitale Stimmen

- **Betroffene Rollen:** `korrupter-richter` („+1 Stimme“), `blutwolf` (Stimmgewicht), `hades` („Stimme ×3“), `nekromant` („Stimmen opfern“).
- **Problem:** Digitale Stimmabgabe und Stimmgewichte sind ausgeschlossen ([`../specs/vertical-slice/implementation-boundary.md`](../specs/vertical-slice/implementation-boundary.md) D).
- **Option A:** Die App zeigt den Stimmbonus nur als Hinweis für die physische Zählung (Legacy-Blutwolf „V<n>“); nichts wird gezählt.
- **Option B:** Rollentexte werden ohne Stimmbezug neu formuliert.
- **Option C:** Diese Rollen bleiben außerhalb von 1.0.
- **Auswirkung:** A erhält die Rollen mit minimalem Aufwand; B verändert die Rollen; C spart Aufwand.
- **Empfehlung:** C für 1.0, danach A.
- **Blockiert:** K14, K15. **Blockiert 1.0:** Nein.

## RM-DR-009 · Zeitpunkt aller Todesreaktionen und Todesfolgen

- **Betroffene Rollen:** `besessener-wolf`, `daemonischer-wolf`, `ritter`, `feuerteufel`, `schutzgeist`, `detektiv`, `seuchenwolf`, `loki`, `rotkaeppchen`, `parasit`, `schattenwanderer`.
- **Problem:** DR-09 regelt den Zeitpunkt nur für den Sensenträger. Legacy verarbeitet Reaktionen teils sofort, teils am Morgen, außerhalb einer Warteschlange.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 10; `godot/core/rules/kill_pipeline.gd` (Wolfskind- und Lehrling-Folgen sofort, Reaktionen eingereiht).
- **Option A:** Zwei Arten wie im Kern angelegt: **Todesfolgen ohne Entscheidung** (Liebeskummer, Kettentod, Ritter-Vergeltung, Seuchenwolf-Markierung) wirken sofort als Teil des Todes, vor der vorläufigen Siegprüfung. **Todesreaktionen mit Entscheidung** (Besessener Wolf, Dämonischer Wolf, Schutzgeist) laufen über die persistente Warteschlange mit dem Zeitpunkt aus DR-09.
- **Option B:** Alles über die Warteschlange, auch ohne Entscheidung.
- **Auswirkung:** A nutzt die bestehende Unterscheidung (Wolfskind/Lehrling sofort, Sensenträger eingereiht); B erzeugt zusätzliche Bestätigungsschritte ohne Spielwert.
- **Empfehlung:** A.
- **Blockiert:** K3, K4, K6, K9, K10, K12. **Blockiert 1.0:** Ja.

## RM-DR-010 · Rollenblockierung: Umfang und Wirkung

- **Betroffene Rollen:** `schattenhund`, `albtraumwolf`, `der-weise` (Debuff), `zeitwaechter`.
- **Problem:** Legacy blockiert nur Nachtschritte, filtert über Rollennamen (auch Solos) und nie Morgen- oder Todesreaktionen.
- **Belege:** `js/core/abilities.js:92-99`; [`04`](04-rule-conflicts.md) §2 Zeile 11.
- **Option A:** Eine Blockade verhindert nur aktive Nachtschritte der betroffenen Personen in der betroffenen Nacht; der Schritt entfällt protokolliert (`StepDropped`, neuer Grund). Filter nach Fraktion: nur Dorf.
- **Option B:** Wie A, aber alle Nicht-Wölfe (auch Einzelsiegrollen).
- **Option C:** Zusätzlich passive Fähigkeiten und Reaktionen der Nacht.
- **Auswirkung:** A ist am einfachsten zu erklären und passt zu „Dorf-Fähigkeiten“ im Schattenhund-Text; B entspricht Legacy; C ist schwer nachvollziehbar.
- **Empfehlung:** A.
- **Blockiert:** K8, K16. **Blockiert 1.0:** Ja (`schattenhund`).

## RM-DR-011 · Wiederbelebung: was bleibt, was verfällt

- **Betroffene Rollen:** `kutscher`, `dr-victor-frankenstein` (auslösend); `loki`, `rotkaeppchen`, `schattenwanderer`, `parasit`, `fenrir`, `seuchenwolf`, `todesprediger`, `giftwolf`, `schicksalswolf` (betroffen). Auch `GmCorrection revive`.
- **Problem:** Legacy behandelt Bindungen, Marker und Einsätze bei Wiederbelebung uneinheitlich; ein wiederbelebter Liebender stirbt erneut an Liebeskummer.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 12; DECISION-LOG „Wiederbelebung und Todesreaktion“, Waldhexe „Wiederbelebung setzt Tränke nicht zurück“.
- **Option A:** Wiederbelebung stellt nur das Leben her. Einsätze bleiben verbraucht, bereits eingereihte Reaktionen bleiben (entschieden). Bindungen, die durch den Tod ausgelöst oder beendet wurden (Liebespaar, Kette, Wirt), bleiben beendet; ein erneuter Tod löst sie nicht noch einmal aus. Marker mit Ablauf (Gift) enden mit dem Tod.
- **Option B:** Wiederbelebung stellt den Zustand vor dem Tod vollständig wieder her.
- **Auswirkung:** A ist eindeutig und passt zu den bestehenden Einträgen; B verlangt Schnappschüsse aller Rollenzustände und kann Kettentode erneut auslösen.
- **Empfehlung:** A.
- **Blockiert:** K6, K10, K13. **Blockiert 1.0:** Ja (`loki`).

## RM-DR-012 · Nominierung durch den Korrupten Richter

- **Betroffene Rollen:** `korrupter-richter`; Wechselwirkung mit `manipulator` und `spiegelwolf` (umgesetzt).
- **Problem:** Legacy markiert „nominiert“, ohne die Manipulator-Folge auszulösen; wer als Nominierender gilt, ist offen.
- **Belege:** [`02`](02-implemented-roles-audit.md) §4.10; [`dossiers/village-2.md`](dossiers/village-2.md#korrupter-richter); DR-03.
- **Option A:** Die Markierung ist eine normale Nominierung mit dem Richter als Nominierendem; sie zählt gegen sein Tageslimit und löst Manipulator-Tod und Spiegelung normal aus.
- **Option B:** Eigene Nominierungsquelle „Rolle“ ohne Nominierenden; Manipulator stirbt, Spiegelwolf spiegelt nicht.
- **Option C:** Nur eine Markierung ohne Nominierung.
- **Auswirkung:** A nutzt vorhandene Regeln ohne Sonderfall; B braucht ein neues Feld und einen Sonderfall in `ExecutionRules`; C verliert die Textwirkung.
- **Empfehlung:** A.
- **Blockiert:** K14. **Blockiert 1.0:** Nein.

## RM-DR-013 · Rollen mit Totenkarten-Abhängigkeit

- **Betroffene Rollen:** `kartenschlucker` (Kernmechanik), `kutscher`, `dr-victor-frankenstein` (Kartenbedingungen über Rollen-Tags).
- **Problem:** Totenkarten sind in Godot nicht umgesetzt; `07` Q3 (Automatisierungsgrad, Ziehungszeitpunkt) ist offen.
- **Belege:** `js/core/cards.js:573`; [`dossiers/solos-b.md`](dossiers/solos-b.md#kartenschlucker).
- **Option A:** Diese Rollen erst nach dem Totenkarten-Assistenten umsetzen.
- **Option B:** Ohne Kartenbezug umsetzen; der Kartenschlucker bleibt ausgeschlossen.
- **Empfehlung:** A.
- **Blockiert:** K13, K15. **Blockiert 1.0:** Nein.

## RM-DR-014 · Bedeutung von „einmalig“ und „erste Nacht“

- **Betroffene Rollen:** 14, u. a. `loki`, `die-gebundenen`, `schattenhund`, `koenig-lykaon`, `schicksalswolf`, `schattenwanderer`, `dorfchronistin`, `kriegerin-des-lichts`, `faehrtenleser`.
- **Problem:** Legacy `once:true` heißt „einmal pro Partie“, nicht „nur Nacht 1“; einige Handler prüfen zusätzlich `nightCount===1` und verbrauchen die Fähigkeit bei späterem Klick. Texte sagen teils „in der ersten Nacht“.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 13; DR-10/DR-11 entschieden „erste verfügbare Nacht“ für Wolfskind und Lehrling.
- **Option A:** Rollen, die zu Spielbeginn etwas festlegen (Loki, Gebundene, Chronistin, Schicksalswolf-Markierung, König Lykaon, Schattenwanderer): Schritt in der **ersten verfügbaren Nacht**, bis er erledigt ist (wie DR-10/DR-11). Freiwillige Einmalfähigkeiten („darf einmal“): Schritt jede Nacht mit ausdrücklichem Verzicht, bis genutzt.
- **Option B:** Strikt Nacht 1; wer dort nicht handelt, verliert die Fähigkeit.
- **Auswirkung:** A ist robust gegen spät eingesetzte Rollen (Erbe, Tausch) und passt zum Kern; B ist näher an einigen Texten.
- **Empfehlung:** A.
- **Blockiert:** K2, K6, K7, K8, K11, K12, K15. **Blockiert 1.0:** Ja (`loki`, `schattenhund`).

## RM-DR-015 · Zufall mit gespeichertem Seed oder Wahl durch den Spielleiter

- **Betroffene Rollen:** `kopfgeldjaeger`, `koenig`, `traumdeuter`, `spuerhund`, `verdammniswaechter`, `blutpriester`, `detektiv`, `dorfschmied`, `kutscher`, `pestbringerin`.
- **Problem:** Legacy nutzt `Math.random`, teils mit verzerrtem Mischen, und würfelt beim erneuten Öffnen neu. DR-08 hat beim Trugbilderwolf Zufall durch Spielleiterwahl ersetzt.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 14; `godot/core/util/seeded_rng.gd`; Orakel-Übersteuerung (`OverrideShownRole`).
- **Option A:** Zufall über `SeededRng`, erst bei Bestätigung übernommen (wie Lehrling); der Spielleiter darf ein gezeigtes Ergebnis mit Begründung übersteuern (wie Orakel).
- **Option B:** Der Spielleiter wählt immer (wie DR-08).
- **Option C:** Je Rolle.
- **Auswirkung:** A ist reproduzierbar und entlastet den Spielleiter; B ist maximal kontrollierbar, aber langsamer.
- **Empfehlung:** A.
- **Blockiert:** K3, K5, K7, K9, K11, K13. **Blockiert 1.0:** Ja (`kopfgeldjaeger`).

## RM-DR-016 · Obergrenze gleicher Sonderrollen je Partie

- **Betroffene Rollen:** alle neuen Rollen.
- **Problem:** Legacy erlaubt von fast jeder Rolle nur eine Kopie (`setup.html:793-798`: Werwolf 5, Dorfbewohner 10, Die Gebundenen 6, sonst 1). Godot kennt `max_copies`, setzt es aber nirgends; die 11 umgesetzten Rollen sind mit mehreren Kopien getestet.
- **Option A:** Neue Sonderrollen in 1.0 mit `max_copies = 1`; Ausnahmen ausdrücklich (z. B. `die-gebundenen`). Tests „mehrere Kopien“ entfallen dann für diese Rollen.
- **Option B:** Keine Obergrenze; jede Rolle braucht Mehrfachkopie-Tests.
- **Auswirkung:** A reduziert Testaufwand deutlich und entspricht Legacy; B ist flexibler.
- **Empfehlung:** A für 1.0.
- **Blockiert:** K1 und alle folgenden. **Blockiert 1.0:** Ja.

## 2. Rollenentscheidungen

Je Rolle eine Sammelentscheidung. Die Teilfragen stammen aus den Widerspruchstabellen in [`04`](04-rule-conflicts.md) §3 (Spalte PO = Ja) bzw., wo keine Tabelle existiert, aus den offenen Fragen des Dossiers. „Option A“ und „Option B“ entsprechen den Interpretationen A und B. Die Empfehlung ist ein Vorschlag aus der Code-Lektüre.

## RM-DR-101 · `loki`

- **Betroffene Rollen:** `loki`; Wechselwirkung laut Dossier: Schwarze Witwe (Pflichtpaar, liest Bindung), Dr. Victor Frankenstein/Kutscher (Wiederbelebung), Lehrling (Erbe), Nekromant/Kartenschlucker/Hades (Schilde in …
- **Problem:** Offen sind: Rivalen-Wirkung. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-1.md#loki); RM-C-082 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-009, RM-DR-011, RM-DR-014.
- **Teilfrage 1: Rivalen-Wirkung**
  - Option A: Rivalen = reiner Marker für Schwarze Witwe
  - Option B: Rivalen bekommen eigene Regel (z.B. Siegsperre)
  - Auswirkung: Balance: Hass-Option ist ohne Witwe eine Leerwahl; Umsetzung: Ohne Regel nur Marker; mit Regel WinRules-Erweiterung
  - Empfehlung: PO entscheidet; bis dahin Marker
- **Weitere offene Fragen (Dossier):** 1. Haben Rivalen eine eigene Wirkung (Q1-Vorschlag) oder bleiben sie Witwe-Marker? 2. Stirbt ein wiederbelebter Liebender erneut, wenn sein Partner tot ist? 3. Ist der Liebeskummer-Tod eine eigene Todesursache mit Reaktionen (Sensenträger) wie heute? 4. Darf Loki sich selbst wählen (Legacy: ja)?
- **Blockiert Charge:** K6. **Blockiert Version 1.0:** Ja.

## RM-DR-102 · `nachtwaechter`

- **Betroffene Rollen:** `nachtwaechter`; Wechselwirkung laut Dossier: alle Wolfs- und Solorollen; Dämonischer Wolf (`cursedWolfAura` zählt als Wolf), Wolfskind (verwandelt), Doppelspion (Solo, …
- **Problem:** Offen sind: Nachbarbegriff. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/village-1.md#nachtwaechter); RM-C-085 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-003.
- **Teilfrage 1: Nachbarbegriff**
  - Option A: nächster lebender Sitz
  - Option B: direkter Sitz
  - Auswirkung: Balance: leicht; Umsetzung: Sitznachbarschafts-Funktion
  - Empfehlung: nächster lebender (wie Code)
- **Weitere offene Fragen (Dossier):** 1. Zeitpunkt: nach vollständiger Morgenauflösung (nach allen Reaktionen) oder vor den Toten? 2. Nur wenn ein Wolf/Solo direkt oder nächster lebender Nachbar ist? 3. Zählt ein nur "als Wolf erscheinender" Spieler (Dämonischer-Wolf-Fluch)? 4. Wird angesagt, welche Seite (links/rechts) oder nur "Alarm"?
- **Blockiert Charge:** K3. **Blockiert Version 1.0:** Nein (Ja bei Option C).

## RM-DR-103 · `rattenfaenger`

- **Betroffene Rollen:** `rattenfaenger`; Wechselwirkung laut Dossier: Voodoo-Priester (hebt Verzauberung auf), Lehrling/Seelentauscher (Rollenwechsel), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (Doppelaktion), Die Ewigen (Solo-Erkennung), Wölfe/Dorf …
- **Problem:** Offen sind: Zählt er selbst; Verzauberung durch Puppe aufgehoben. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/solos-a.md#rattenfaenger); RM-C-041, RM-C-043 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-007.
- **Teilfrage 1: Zählt er selbst**
  - Option A: alle außer Rattenfänger
  - Option B: inkl. Rattenfänger (Selbstverzauberung nötig)
  - Auswirkung: Balance: B verschwendet eine Verzauberung; Umsetzung: Filter
  - Empfehlung: A (Code) + Text präzisieren
- **Teilfrage 2: Verzauberung durch Puppe aufgehoben**
  - Option A: beabsichtigte Interaktion
  - Option B: Altlast
  - Auswirkung: Balance: Voodoo kann Rattenfänger bremsen; Umsetzung: eigene Regel nötig
  - Empfehlung: streichen, falls nicht gewollt
- **Weitere offene Fragen (Dossier):** (1) Zählt der Rattenfänger selbst zu „allen lebenden Spielern"? (2) Sieg auch, wenn die Bedingung durch einen Tod eintritt? (3) Genau eine Aktion pro Nacht, 1 oder 2 Ziele, Selbstwahl erlaubt? (4) Gewinnt der Rattenfänger vor dem Dorf, wenn in derselben Auflösung der letzte Wolf und der letzte Unverzauberte sterben (DR-02: SL wählt aus Kandidaten)? (5) Soll die Voodoo-Puppe Verzauberung aufheben?
- **Blockiert Charge:** K9. **Blockiert Version 1.0:** Ja.

## RM-DR-104 · `die-ewigen`

- **Betroffene Rollen:** `die-ewigen`; Wechselwirkung laut Dossier: alle 14 Solo-Rollen (`roles:399-403`), insbesondere solche ohne Siegcode (Prophet, Feuerteufel, Voodoo, Grabräuber: 07 Q4); Lehrling/Seelentauscher (Solo-Rolle wechselt …
- **Problem:** Offen sind: Mitsieg; Info-Umfang; Siegseite der Ewigen. Legacy-Befund `not-found`.
- **Belege:** [Dossier](dossiers/village-1.md#die-ewigen); RM-C-087, RM-C-088, RM-C-089 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-006.
- **Teilfrage 1: Mitsieg**
  - Option A: Ewige gewinnen mit jedem gefundenen Solo, wenn dieser gewinnt
  - Option B: Ewige gewinnen mit dem Solo, den sie zuletzt/zuerst gefunden haben
  - Auswirkung: Balance: hoch (Dorfrolle wechselt faktisch Siegseite); Umsetzung: WinCandidate muss Mitsieger tragen; widerspricht "genau ein Kandidat"
  - Empfehlung: Regel festlegen, Mitsieg als Zusatz-Gewinner am Kandidaten
- **Teilfrage 2: Info-Umfang**
  - Option A: nur Ja/Nein
  - Option B: Ja + Rolle
  - Auswirkung: Balance: Rollenname ist Orakel-starke Info; Umsetzung: InfoRecord-Inhalt
  - Empfehlung: nur Ja/Nein
- **Teilfrage 3: Siegseite der Ewigen**
  - Option A: Ewige bleiben Dorf und gewinnen zusätzlich mit Solo
  - Option B: Ewige verlassen das Dorf, sobald Solo gefunden
  - Auswirkung: Balance: mittel; Umsetzung: Fraktionswechsel oder Zusatzsieg
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** 1. Wann gewinnen die Ewigen mit: mit jedem Solo, den sie je positiv geprüft haben, oder mit jedem Solo-Sieger überhaupt? 2. Müssen die Ewigen zum Siegzeitpunkt leben? 3. Nur Ja/Nein oder auch Rollenname? 4. Tote Ziele und Selbstprüfung erlaubt? 5. Verlieren die Ewigen mit dem Dorf, wenn sie einen Solo gefunden haben?
- **Blockiert Charge:** K9. **Blockiert Version 1.0:** Nein.

## RM-DR-105 · `spuerhund`

- **Betroffene Rollen:** `spuerhund`; Wechselwirkung laut Dossier: Wolfskind, Dämonischer Wolf (Fluch), Trugbilderwolf (Wolfsrolle), alle Solos, Lehrling/Seelentauscher (Rollenname …
- **Problem:** Offen sind: Wer wird falsche Spur. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-1.md#spuerhund); RM-C-090 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-015.
- **Teilfrage 1: Wer wird falsche Spur**
  - Option A: Zufall (SeededRng)
  - Option B: SL wählt
  - Auswirkung: Balance: Zufall kann Spürhund selbst oder echte Wölfe treffen (dann wirkungslos); Umsetzung: Rng-Aufruf vs. Prompt
  - Empfehlung: Zufall über lebende Nicht-Wolf/Nicht-Solo außer Spürhund, per SeededRng
- **Weitere offene Fragen (Dossier):** 1. Falsche Spur zufällig oder SL-Wahl? Aus welcher Menge (ohne Spürhund, ohne Wölfe/Solos, ohne bereits markierte)? 2. Bleibt die Markierung dauerhaft? Kumulativ? 3. Zählt ein Verfluchter (Dämonischer Wolf) als Wolf? 4. Selbstwahl unter den 3 erlaubt?
- **Blockiert Charge:** K7. **Blockiert Version 1.0:** Nein.

## RM-DR-106 · `rachsuechtiger-wolf`

- **Betroffene Rollen:** `rachsuechtiger-wolf`; Wechselwirkung laut Dossier: Werwolf (Rudel, synthetische Zeile), Doppelspion (Zielausschluss, Textbezug), Dämonischer Wolf (verfluchte Ziele), Schutzengel/Dorfwache, Seuchenwolf, Waldhexe, Verdammniswächter, Die Ewigen, Nachtwächter …
- **Problem:** Offen sind: Siegziel; Rhythmus; Zeitpunkt der ersten Nutzung. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-a.md#rachsuechtiger-wolf); RM-C-001, RM-C-002, RM-C-003 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-004, RM-DR-006.
- **Teilfrage 1: Siegziel**
  - Option A: Einzelsieg: gewinnt nur, wenn er als Letzter (oder mit Bedingung X) übrig ist
  - Option B: Rudelsieg wie Code
  - Auswirkung: Balance: A macht ihn zum Verräter im Rudel, B zu einem normalen Wolf mit Zusatzkill; Umsetzung: A: neue Siegbedingung, Fraktion "solo" trotz Wolfsrudel, Parität neu definieren
  - Empfehlung: A (Text), EN ergänzen
- **Teilfrage 2: Rhythmus**
  - Option A: fester Takt (Nacht 3, 6, 9)
  - Option B: Abklingzeit nach Nutzung
  - Auswirkung: Balance: A seltener und vorhersehbar; Umsetzung: Nachtschritt-Bedingung nach Nachtnummer vs. Zähler pro Person
  - Empfehlung: Abklingzeit (Code), Text präzisieren
- **Teilfrage 3: Zeitpunkt der ersten Nutzung**
  - Option A: erst ab Nacht 3
  - Option B: ab Nacht 1
  - Auswirkung: Balance: früher Rudelverlust in Nacht 1 möglich; Umsetzung: Startwert Zähler
  - Empfehlung: festlegen
- **Weitere offene Fragen (Dossier):** (1) Einzelsieg ja/nein, und wenn ja unter welcher Bedingung (letzter Lebender? letzter Wolf?) und zählt er vorher zur Wolfsparität? (2) Feste Nächte (3, 6, 9) oder Abklingzeit ab erster Nutzung? Erste Nutzung ab Nacht 1? (3) Wirkt Schutzengel-Schutz gegen seinen Angriff? (4) Ist sein Angriff ein "Wolfsangriff" für Seuchenwolf, Rudelvater, Ritter?
- **Blockiert Charge:** K11. **Blockiert Version 1.0:** Nein.

## RM-DR-107 · `koenig-lykaon`

- **Betroffene Rollen:** `koenig-lykaon`; Wechselwirkung laut Dossier: Trugbilderwolf, Wächter am Tor, Orakel, Lehrling (Erbe), Werwolf (synthetische Rudelzeile), Totenkarte …
- **Problem:** Offen sind: Scheinrolle des erzeugten Trugbilderwolfs; "Dorfbewohner". Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/wolves-a.md#koenig-lykaon); RM-C-004, RM-C-005 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-014.
- **Teilfrage 1: Scheinrolle des erzeugten Trugbilderwolfs**
  - Option A: Scheinrolle = alte Rolle der Person
  - Option B: SL wählt bei Verwandlung
  - Auswirkung: Balance: A passt zur Tarnzeile und ist logisch stark; Umsetzung: `appears_as` muss bei RoleTransition gesetzt werden
  - Empfehlung: A, mit SL-Korrektur
- **Teilfrage 2: "Dorfbewohner"**
  - Option A: nur Dorffraktion
  - Option B: jede Nicht-Wolf-Person
  - Auswirkung: Balance: B kann Solo-Rollen neutralisieren; Umsetzung: Zielfilter `faction==village` vs `!counts_as_wolf`
  - Empfehlung: festlegen
- **Weitere offene Fragen (Dossier):** (1) Welche Scheinrolle erhält der neue Trugbilderwolf? (2) Dürfen Solo-Rollen Ziel sein? (3) Muss der Verbündete gespeichert/angezeigt werden, oder reicht er als Ansage? (4) Verfällt die Fähigkeit, wenn Nacht 1 ohne Nutzung vergeht (Legacy ja)? (5) Tarnzeile der alten Rolle ja/nein, auch bei Wächter-Umleitung?
- **Blockiert Charge:** K12. **Blockiert Version 1.0:** Nein (Ja bei Option C).

## RM-DR-108 · `seuchenwolf`

- **Betroffene Rollen:** `seuchenwolf`; Wechselwirkung laut Dossier: Werwolf, Schutzengel, Schutzgeist, Dorfwache, Der Weise, Waldhexe, Nekromant, Kartenschlucker, Hades, Dorfschmied, Märtyrerin, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (gemeinsames …
- **Problem:** Offen sind: Umfang "alle Schutzeffekte"; Verbrauch; Welche Angriffe. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-a.md#seuchenwolf); RM-C-006, RM-C-007, RM-C-008 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004, RM-DR-005, RM-DR-009, RM-DR-011.
- **Teilfrage 1: Umfang "alle Schutzeffekte"**
  - Option A: wirklich alles, was einen Rudelkill verhindert
  - Option B: nur Schutzrollen (Schutzengel, Dorfwache, Der Weise), keine Schilde/Rettungen
  - Auswirkung: Balance: A deutlich stärker; Umsetzung: Liste der durchdrungenen Abfangregeln in KillPipeline festlegen
  - Empfehlung: Einheitliche Liste mit Rudelvater teilen
- **Teilfrage 2: Verbrauch**
  - Option A: nächster Angriff, auch wenn er scheitert
  - Option B: nächster erfolgreiche Kill
  - Auswirkung: Balance: A kann durch Hexe verpuffen; Umsetzung: Verbrauchszeitpunkt
  - Empfehlung: A (Text)
- **Teilfrage 3: Welche Angriffe**
  - Option A: nur Rudelangriff
  - Option B: jeder Wolfskill
  - Auswirkung: Balance: gering; Umsetzung: Ursachen-Attribut
  - Empfehlung: nur Rudelangriff
- **Weitere offene Fragen (Dossier):** (1) Welche Schutzarten durchdringt er (Liste)? (2) Verbraucht ein gescheiterter Angriff die Durchdringung? (3) Nur Rudelangriff oder jeder Wolfskill? (4) Stapeln sich zwei Seuchenwolf-Tode?
- **Blockiert Charge:** K11. **Blockiert Version 1.0:** Nein.

## RM-DR-109 · `schicksalswolf`

- **Betroffene Rollen:** `schicksalswolf`; Wechselwirkung laut Dossier: Werwolf (Rudelopfer, Deduplizierung), Schutzengel, Dorfwache, Der Weise, Märtyrerin, Zeitwächter (eingefrorene Nacht zählt nicht, `night:323-331` erhöht `nightCount` nicht), Frankenstein/Kutscher (Wiederbelebung), …
- **Problem:** Offen sind: Zeitfenster; Schutz gegen Zusatzopfer; Zählung der ersten drei Toten. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-a.md#schicksalswolf); RM-C-009, RM-C-010, RM-C-011 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004, RM-DR-005, RM-DR-011, RM-DR-014.
- **Teilfrage 1: Zeitfenster**
  - Option A: nur Nacht 4, danach verfallen
  - Option B: ab Nacht 4, einmal
  - Auswirkung: Balance: B lässt Wölfe auf Bonus warten; Umsetzung: Schrittbedingung
  - Empfehlung: A (Text)
- **Teilfrage 2: Schutz gegen Zusatzopfer**
  - Option A: wie Rudelangriff (Schutz wirkt)
  - Option B: eigener Kill ohne Schutz
  - Auswirkung: Balance: A schwächer; Umsetzung: Ursache/Quelle, Protections-Filter
  - Empfehlung: A
- **Teilfrage 3: Zählung der ersten drei Toten**
  - Option A: erste drei verschiedenen Toten der Partie
  - Option B: nur Tode nach Markierung
  - Auswirkung: Balance: gering; Umsetzung: Todesreihenfolge-Historie
  - Empfehlung: A mit Deduplizierung
- **Weitere offene Fragen (Dossier):** (1) Nur Nacht 4 oder ab Nacht 4? (2) Wirkt Schutz gegen Zusatzopfer? (3) Zählen Tode vor der Markierung und doppelte Tode? (4) Darf er sich selbst oder Wölfe markieren? (5) Verfällt die Fähigkeit, wenn Nacht 1 nicht markiert wird?
- **Blockiert Charge:** K11. **Blockiert Version 1.0:** Nein.

## RM-DR-110 · `schattenwanderer`

- **Betroffene Rollen:** `schattenwanderer`; Wechselwirkung laut Dossier: Rudelvater (Reihenfolge), Parasit, Nekromant/Kartenschlucker/Hades (Schilde beim Partner), Werwolf, Lynch/ExecutionRules, Frankenstein/Kutscher (Wiederbelebung), Dämonischer Wolf, Kopfgeldjäger, …
- **Problem:** Offen sind: „Stattdessen“ oder „beide sterben“; Umfang und Dauer. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/wolves-a.md#schattenwanderer).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-009, RM-DR-011, RM-DR-014.
- **Teilfrage 1: „Stattdessen“ oder „beide sterben“**
  - Option A: Stirbt einer der beiden, stirbt stattdessen der andere (Text „stattdessen“, Legacy-Umlenkung `core:118-124`)
  - Option B: Beide sterben (Begriff „Todeskette“)
  - Auswirkung: Balance: A ist ein Schutz für den Schattenwanderer, B eine Kettenfalle; Umsetzung: A: Umlenkung in der Abfangstufe; B: Kettentod als Todesfolge
  - Empfehlung: A (Text und Code stimmen überein)
- **Teilfrage 2: Umfang und Dauer**
  - Option A: Gilt für alle Todesursachen einmalig, danach ist die Bindung verbraucht
  - Option B: Gilt dauerhaft für jeden Tod
  - Auswirkung: Balance: B sehr stark; Umsetzung: Bindungsstatus mit Verbrauch
  - Empfehlung: A, Details im Dossier
- **Weitere offene Fragen (Dossier):** (1) "stattdessen" (Code) oder "beide sterben" (Begriff Todeskette)? (2) Gilt die Umlenkung für alle Ursachen inkl. Hinrichtung, und zählt eine umgelenkte Hinrichtung als erfolgt? (3) Einmalig oder dauerhaft (auch nach Wiederbelebung)? (4) Mit welcher Ursache/Quelle stirbt der Partner (eigene Ursache oder Original)? (5) Nur Nacht 1 oder jede Nacht bis zur Nutzung?
- **Blockiert Charge:** K6. **Blockiert Version 1.0:** Nein.

## RM-DR-111 · `giftwolf`

- **Betroffene Rollen:** `giftwolf`; Wechselwirkung laut Dossier: Rudelvater (keine Rettung), Ritter (Vergeltung), Schattenwanderer, Nekromant/Kartenschlucker/Hades (Schilde), Zeitwächter (Morgenzähler), Frankenstein/Kutscher (Wiederbelebung), Orakel (sieht …
- **Problem:** Offen sind: Zwei Ladungen in einer Nacht; "erfährt davon"; Zeitpunkt "zwei Tage später". Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/wolves-a.md#giftwolf); RM-C-012, RM-C-013, RM-C-014 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004, RM-DR-011.
- **Teilfrage 1: Zwei Ladungen in einer Nacht**
  - Option A: beide sofort erlaubt
  - Option B: max 1 pro Nacht
  - Auswirkung: Balance: A erlaubt Doppelschlag; Umsetzung: Schrittbedingung
  - Empfehlung: B (07)
- **Teilfrage 2: "erfährt davon"**
  - Option A: öffentlich/Ansage an Ziel in der Nacht
  - Option B: SL flüstert am Morgen
  - Auswirkung: Balance: Informationsvorteil fürs Ziel; Umsetzung: InfoRecord actor=Ziel
  - Empfehlung: A als Actor-Ereignis
- **Teilfrage 3: Zeitpunkt "zwei Tage später"**
  - Option A: Morgen von Tag N+1
  - Option B: Ende von Tag N+1
  - Auswirkung: Balance: gering; Umsetzung: Termin in `day_number`
  - Empfehlung: Code
- **Weitere offene Fragen (Dossier):** (1) Max 1 Ladung pro Nacht? (2) Wie erfährt das Ziel davon (Zeitpunkt, SL-Ansage)? (3) Endet das Gift bei Tod/Wiederbelebung des Ziels oder bei Heilung durch Waldhexe? (4) Ist das Gift ein "Wolfsangriff" (Rudelvater, Schutzengel, Dorfwache, Seuchenwolf)? (5) Ladungen pro Person oder pro Rolle?
- **Blockiert Charge:** K11. **Blockiert Version 1.0:** Nein.

## RM-DR-112 · `rudelvater`

- **Betroffene Rollen:** `rudelvater`; Wechselwirkung laut Dossier: Werwolf (Rudel), Seuchenwolf (gemeinsame Durchdringung), Giftwolf, Schattenwanderer, Nekromant/Kartenschlucker/Hades, Dorfwache, Der Weise, Dorfschmied, Voodoo-Priester, Märtyrerin, Albtraumwolf, Sensenträger, …
- **Problem:** Offen sind: Was ist "Wolfsangriff"; Was ist "Lynch"; "alle Schutzfähigkeiten"; Wer wählt wann. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/wolves-a.md#rudelvater); RM-C-015, RM-C-016, RM-C-017, RM-C-018 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004, RM-DR-005.
- **Teilfrage 1: Was ist "Wolfsangriff"**
  - Option A: jede Tötung durch eine Wolfsrolle
  - Option B: nur Rudel-/Wolfsnachtangriff
  - Auswirkung: Balance: A macht ihn verwundbarer; Umsetzung: Ursachen-Attribut `wolf_source`
  - Empfehlung: A oder Liste
- **Teilfrage 2: Was ist "Lynch"**
  - Option A: nur die Hinrichtung selbst
  - Option B: alles, was aus einer Hinrichtung folgt
  - Auswirkung: Balance: gering; Umsetzung: Ursachen-Attribut execution vs. execution_side
  - Empfehlung: nur Hinrichtung (Code)
- **Teilfrage 3: "alle Schutzfähigkeiten"**
  - Option A: wirklich alle Abfangregeln
  - Option B: nur Schutzrollen und Schilde
  - Auswirkung: Balance: gering; Umsetzung: gemeinsame Durchdringungsliste mit Seuchenwolf
  - Empfehlung: eine Liste für beide
- **Teilfrage 4: Wer wählt wann**
  - Option A: eigener Rudelschritt in der Nacht
  - Option B: Pick bei Morgenauflösung
  - Auswirkung: Balance: kein, aber Ablauf/Ansage; Umsetzung: zweiter Rudel-Prompt in StepQueue
  - Empfehlung: A
- **Weitere offene Fragen (Dossier):** (1) Was zählt als Wolfsangriff (Schwarze Witwe, Besessener Wolf, Spiegelwolf, Gift)? (2) Zählen Hinrichtungs-Nebentode als Lynch? (3) Zusatzopfer im Nachtschritt der Wölfe oder am Morgen durch den SL? (4) Zusatzopfer auch bei überlebtem Lynch? (5) Welche Abfangregeln ignoriert das Zusatzopfer (Liste gemeinsam mit Seuchenwolf)? (6) Rettung pro Person oder pro Rolle?
- **Blockiert Charge:** K11. **Blockiert Version 1.0:** Nein.

## RM-DR-113 · `schwarze-witwe`

- **Betroffene Rollen:** `schwarze-witwe`; Wechselwirkung laut Dossier: Loki (Pflicht, liefert Paare), Zeitwächter (Reihenfolge), Ritter (Vergeltung bei `BLACK_WIDOW`), Rudelvater/Nekromant/Kartenschlucker/Hades/Schattenwanderer/Parasit (Schilde in `applyKill`), Besessener Wolf (siehe …
- **Problem:** Offen sind: Loki "automatisch gewählt"; Zeitwächter-Einfrieren. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-b.md#schwarze-witwe); RM-C-019, RM-C-021 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004.
- **Teilfrage 1: Loki "automatisch gewählt"**
  - Option A: Loki wird beim Setup automatisch ins Rollenset gelegt
  - Option B: Loki ist Pflicht-Beirolle, SL muss sie wählen
  - Auswirkung: Balance: keine, solange Loki Pflicht ist; Umsetzung: Godot: `requires_roles` (`03:200`) als Validierung oder Auto-Ergänzung
  - Empfehlung: Pflichtpaar-Validierung behalten, Text auf "Benötigt Loki im Spiel" ändern
- **Teilfrage 2: Zeitwächter-Einfrieren**
  - Option A: Witwen-Wahl ist Nachtaktion, wird eingefroren
  - Option B: Witwen-Tod ist Tagesereignis, bleibt
  - Auswirkung: Balance: mittel; Zeitwächter kontert Witwe nicht; Umsetzung: Reihenfolge in DAWN
  - Empfehlung: mit Zeitwächter-Entscheidung Q1 gemeinsam festlegen
- **Weitere offene Fragen (Dossier):** 1. Wird Loki beim Setup automatisch ergänzt oder nur validiert? 2. Zählen Rivalen weiter als Ziel der Witwe, wenn Loki-Rivalen sonst keine Wirkung haben (07 Q1 Loki-Zeile)? 3. Friert der Zeitwächter die Witwen-Tode ein? 4. Darf die Witwe sich selbst oder Wölfe wählen (Code: ja)? 5. Soll ein zweiter Klick / eine zweite Witwe ein weiteres Paar markieren können oder überschreiben?
- **Blockiert Charge:** K6. **Blockiert Version 1.0:** Nein.

## RM-DR-114 · `der-weise`

- **Betroffene Rollen:** `der-weise`; Wechselwirkung laut Dossier: Werwolf, Rachsüchtiger Wolf, Schicksalswolf, Seuchenwolf, Rudelvater (Durchschlag), Schutzengel/Schutzgeist (Stapelung), Albtraumwolf (Blockade entfernt Ziel), Märtyrerin, Verdammniswächter (umgeht Rettung), Waldhexe; …
- **Problem:** Offen sind: Wer verliert Fähigkeiten; Dauer "Nächte und Tage"; Durchschlag; Passive Fähigkeiten im Debuff. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/village-1.md#der-weise); RM-C-093, RM-C-094, RM-C-096, RM-C-097 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-004, RM-DR-005, RM-DR-010.
- **Teilfrage 1: Wer verliert Fähigkeiten**
  - Option A: nur Dorf-Fraktion
  - Option B: alle Nicht-Wölfe
  - Auswirkung: Balance: Solos werden mitbestraft; Umsetzung: FactionQuery-Filter
  - Empfehlung: nur Dorf
- **Teilfrage 2: Dauer "Nächte und Tage"**
  - Option A: Sperre gilt auch für Tagfähigkeiten
  - Option B: nur Nächte
  - Auswirkung: Balance: gering bis mittel; Umsetzung: Tagesaktionen brauchen Blockprüfung
  - Empfehlung: Nacht und Tag
- **Teilfrage 3: Durchschlag**
  - Option A: Durchschlag tötet
  - Option B: Rettung greift trotzdem
  - Auswirkung: Balance: gering; Umsetzung: Filter in Protections
  - Empfehlung: wie Code
- **Teilfrage 4: Passive Fähigkeiten im Debuff**
  - Option A: auch passive (Nachtwächter, Kutscher)
  - Option B: nur aktive
  - Auswirkung: Balance: mittel; Umsetzung: Blockmarker in Reaktionen
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** 1. Zählt als "Werwolfangriff" auch Rachsüchtiger Wolf, Schicksalswolf-Extra, Rudelvater-Extra? 2. Durchschlag (Seuchenwolf/Rudelvater): tötet oder verbraucht die Rettung? 3. Debuff: nur Dorf-Fraktion oder alle Nicht-Wölfe? Auch passive Fähigkeiten und Tagesaktionen? 4. Zählweise: n Nächte und n Tage ab Lynch-Tag oder ab nächster Nacht? 5. Wird die Rettung angesagt oder bleibt sie still?
- **Blockiert Charge:** K8. **Blockiert Version 1.0:** Nein (Ja bei Option C).

## RM-DR-115 · `verdammniswaechter`

- **Betroffene Rollen:** `verdammniswaechter`; Wechselwirkung laut Dossier: Werwolf/Rudel (liefert Nachtopfer), Rachsüchtiger Wolf (Zusatzziel), Schutzengel/Dorfwache, Der Weise, Märtyrerin, Waldhexe, Voodoo-Priester, Nekromant, Kartenschlucker, Hades, Rudelvater, Ritter, …
- **Problem:** Offen sind: "umgeht alle Schutzfähigkeiten"; Todeszeitpunkt; Zufallskandidat. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-1.md#verdammniswaechter); RM-C-098, RM-C-099, RM-C-100 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-005, RM-DR-015.
- **Teilfrage 1: "umgeht alle Schutzfähigkeiten"**
  - Option A: wirklich alle (auch Schilde, Schutzengel)
  - Option B: nur Schutz gegen das Nachtopfer
  - Auswirkung: Balance: mittel; Umsetzung: KillPipeline-Option `ignore_protections` + Auslösung auch bei geschütztem Opfer
  - Empfehlung: A (07-Vorschlag)
- **Teilfrage 2: Todeszeitpunkt**
  - Option A: sofort
  - Option B: Morgen
  - Auswirkung: Balance: hoch (Hexe, spätere Rollen); Umsetzung: IMMEDIATE vs. Morgenkill
  - Empfehlung: Morgen (07)
- **Teilfrage 3: Zufallskandidat**
  - Option A: jeder andere Lebende
  - Option B: nur Nicht-Wölfe
  - Auswirkung: Balance: Pool ohne Wölfe schützt das Rudel; Umsetzung: Rng-Menge
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** 1. Tod sofort oder in der Morgenauflösung? 2. Umgeht das Urteil auch Schilde (Nekromant, Kartenschlucker, Hades, Rudelvater) und Schutzengel (auch wenn das Rudelziel geschützt war)? 3. Kandidatenmenge: alle anderen Lebenden, nur Nicht-Wölfe, ohne Verdammniswächter selbst? 4. Welches Nachtopfer bei mehreren Wolfszielen? 5. Pflichtschritt oder darf der Verdammniswächter verzichten?
- **Blockiert Charge:** K11. **Blockiert Version 1.0:** Nein.

## RM-DR-116 · `wahnsinniger-kutscher`

- **Betroffene Rollen:** `wahnsinniger-kutscher`; Wechselwirkung laut Dossier: Loki (Kette), Sensenträger/Besessener Wolf (Folgereaktionen), Rudelvater/Nekromant/Kartenschlucker/Hades/Parasit (Schilde), Henker (`finalizeLynch`), Feuerteufel/Voodoo-Priester/Kopfgeldjäger (ausgelassene …
- **Problem:** Offen sind: Nachbarbegriff. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-1.md#wahnsinniger-kutscher); RM-C-103 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-003.
- **Teilfrage 1: Nachbarbegriff**
  - Option A: direkte Sitze (DE, Code)
  - Option B: nächste Lebende (EN, 07)
  - Auswirkung: Balance: B tötet spät im Spiel zuverlässiger zwei; Umsetzung: gleiche Sitznachbarschafts-Funktion wie Nachtwächter
  - Empfehlung: PO; Texte angleichen
- **Weitere offene Fragen (Dossier):** 1. Direkte oder nächste lebende Nachbarn? 2. Schützt Schutzengel/Hexe oder ein Schild die Nachbarn? 3. Wirkt die Reaktion auch bei Tod durch GmCorrection-Hinrichtung (DECISION-LOG Z.131 legt nahe: ja)? 4. Todesursache der Nachbarn und des Kutschers festschreiben.
- **Blockiert Charge:** K3. **Blockiert Version 1.0:** Ja.

## RM-DR-117 · `korrupter-richter`

- **Betroffene Rollen:** `korrupter-richter`; Wechselwirkung laut Dossier: Manipulator, Spiegelwolf, Nominations-Limit, Albtraumwolf/Schattenhund/Zeitwächter/Der Weise (Blockaden), Hades (Stimme x3) und Blutwolf nur konzeptionell (weitere …
- **Problem:** Offen sind: +1 Stimme; Wer ist Nominierender?; Zählt gegen "einmal nominiert werden"?. Legacy-Befund `not-found`.
- **Belege:** [Dossier](dossiers/village-2.md#korrupter-richter); RM-C-105, RM-C-106, RM-C-107 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-008, RM-DR-012.
- **Teilfrage 1: +1 Stimme**
  - Option A: SL-Hinweis "zählt +1 Stimme" am nominierten Sitz
  - Option B: Rolle verliert "+1 Stimme", Text anpassen
  - Auswirkung: Balance: ohne Hinweis wirkungslos, Rolle nahezu leer; Umsetzung: A: nur Anzeige in Nomination-Ansicht; B: nur Text
  - Empfehlung: A (Hinweis + Protokoll)
- **Teilfrage 2: Wer ist Nominierender?**
  - Option A: Richter ist Nominierender (Spiegelwolf trifft Richter)
  - Option B: anonyme System-Nominierung (Spiegelwolf ohne Ziel)
  - Auswirkung: Balance: Spiegelwolf-Gefahr für Richter; Umsetzung: Nominations braucht Quelle `system`/`role`
  - Empfehlung: PO klärt
- **Teilfrage 3: Zählt gegen "einmal nominiert werden"?**
  - Option A: zählt
  - Option B: zählt nicht
  - Auswirkung: Balance: Richter kann reguläre Nominierung blockieren; Umsetzung: Nominations-Regeloption
  - Empfehlung: zählt als Nominierung
- **Weitere offene Fragen (Dossier):** (1) Ist der Richter der Nominierende (Spiegelwolf-Folge)? (2) Zählt die Richter-Nominierung für das Einmal-Limit von Nominierendem/Nominiertem? (3) Darf der Richter sich selbst markieren? (4) "+1 Stimme" als reiner SL-Hinweis oder Text streichen? (5) Pflicht oder optional pro Nacht (Legacy: optional)?
- **Blockiert Charge:** K14. **Blockiert Version 1.0:** Nein.

## RM-DR-118 · `maertyrerin`

- **Betroffene Rollen:** `maertyrerin`; Wechselwirkung laut Dossier: Werwolf/Rudel, Rudelvater (Extraopfer), Schicksalswolf, Dorfwache, Voodoo-Priester, Zeitwächter, Der Weise, Dorfschmied, Albtraumwolf, Nekromant (Schild), …
- **Problem:** Offen sind: Rettung vs. Zeitpunkt; Welches Opfer bei mehreren; Blockaden. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-2.md#maertyrerin); RM-C-108, RM-C-109, RM-C-111 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004.
- **Teilfrage 1: Rettung vs. Zeitpunkt**
  - Option A: Ersatzopfer für ein Nachtopfer (Code)
  - Option B: Opfer ohne garantierte Rettung (EN wörtlich)
  - Auswirkung: Balance: B macht die Rolle fast nutzlos; Umsetzung: A: Abfangregel in Morgenauflösung
  - Empfehlung: A, EN-Text angleichen
- **Teilfrage 2: Welches Opfer bei mehreren**
  - Option A: SL/Märtyrerin wählt eines
  - Option B: nur Rudelopfer
  - Auswirkung: Balance: Rudelvater-/Schicksalswolf-Nächte; Umsetzung: Auswahlprompt statt fester Index
  - Empfehlung: Auswahl unter Todeskandidaten
- **Teilfrage 3: Blockaden**
  - Option A: Reaktion ist blockierbar
  - Option B: nicht blockierbar
  - Auswirkung: Balance: gering; Umsetzung: Blockadeprüfung in Reaktion
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** (1) Gilt die Rettung (DE) und wird EN angepasst? (2) Bei mehreren Nachtopfern: wählt die Märtyrerin eines, oder nur das Rudelopfer? (3) Nur Rudelangriffe oder auch Sofort-Tode (Hexe, Hades, Verdammniswächter)? (4) Ist die Reaktion durch Albtraum/Schattenhund/Der-Weise-Debuff blockierbar? (5) Wird das Opfer nur angeboten, wenn der Tod nach Schutz tatsächlich eintritt?
- **Blockiert Charge:** K5. **Blockiert Version 1.0:** Nein.

## RM-DR-119 · `dorfwache`

- **Betroffene Rollen:** `dorfwache`; Wechselwirkung laut Dossier: Werwolf/Rudel, Seuchenwolf, Rudelvater, Giftwolf, Schicksalswolf, Rachsüchtiger Wolf, Schutzengel, Märtyrerin, Seelentauscher (Rollenwechsel in der …
- **Problem:** Offen sind: Giftwolf; Seuchenwolf/Rudelvater. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/village-2.md#dorfwache); RM-C-112, RM-C-113 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004, RM-DR-005.
- **Teilfrage 1: Giftwolf**
  - Option A: Giftwolf ist Werwolf → immun
  - Option B: nur Rudelangriff zählt
  - Auswirkung: Balance: Giftwolf-Ladung auf Dorfwache verschwendet oder tödlich; Umsetzung: Filter `is_wolf_attack` muss Giftwolf einordnen
  - Empfehlung: PO
- **Teilfrage 2: Seuchenwolf/Rudelvater**
  - Option A: Immunität ist "Schutz" → wird durchdrungen
  - Option B: Immunität ist Rolleneigenschaft → hält
  - Auswirkung: Balance: selten, aber spielentscheidend; Umsetzung: Kennzeichnung "ignoriert Immunität"
  - Empfehlung: Code (Text der Dorfwache ergänzen)
- **Weitere offene Fragen (Dossier):** (1) Ist die Dorfwache gegen Giftwolf-Giftpranken immun? (2) Durchdringen Seuchenwolf-Pierce und Rudelvater-Zweitangriff die Immunität (Legacy: ja)? (3) Verbraucht ein Rudelangriff auf die Dorfwache ihren Schutzengel-Schild? (4) Erfährt jemand, dass der Angriff abgewehrt wurde?
- **Blockiert Charge:** K5. **Blockiert Version 1.0:** Ja.

## RM-DR-120 · `pestbringerin`

- **Betroffene Rollen:** `pestbringerin`; Wechselwirkung laut Dossier: Zeitwächter (friert Ausbreitung ein), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (zweiter Einsatz pro Nacht), Die Ewigen, Wolfsparität (konkurrierender …
- **Problem:** Offen sind: Tödlichkeit; Häufigkeit; Siegbedingung; Ausbreitung. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/solos-a.md#pestbringerin); RM-C-044, RM-C-045, RM-C-046, RM-C-047 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-003, RM-DR-006, RM-DR-007, RM-DR-015.
- **Teilfrage 1: Tödlichkeit**
  - Option A: Code: Marker ohne Tod, Sieg bei Totalinfektion
  - Option B: Text: Seuche tötet (Zeitpunkt offen)
  - Auswirkung: Balance: A ist ein Siegrennen, B eine Tötungsrolle; Umsetzung: A einfach; B braucht verzögerte Tode
  - Empfehlung: A (07-Vorschlag), Text anpassen
- **Teilfrage 2: Häufigkeit**
  - Option A: Code
  - Option B: Text (jede Nacht neu)
  - Auswirkung: Balance: B beschleunigt Sieg stark; Umsetzung: Zähler
  - Empfehlung: Code
- **Teilfrage 3: Siegbedingung**
  - Option A: nur lebend
  - Option B: auch tot
  - Auswirkung: Balance: B erlaubt „posthumen" Sieg; Umsetzung: Kandidat nur bei lebender Pestbringerin
  - Empfehlung: lebend verlangen
- **Teilfrage 4: Ausbreitung**
  - Option A: direkte Sitze
  - Option B: nächste lebende Nachbarn
  - Auswirkung: Balance: Tote Nachbarn bremsen A; Umsetzung: Sitznachbarschaft + SeededRng
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** (1) Tötet die Seuche (Text) oder nicht (Code)? (2) Einsätze: 2 pro Partie oder jede Nacht? (3) Ausbreitung auf direkte Sitze oder nächste lebende Nachbarn, zufällig oder SL-Wahl? (4) Sieg nur, wenn die Pestbringerin lebt? Muss sie sich selbst infizieren? (5) Einsatzzähler pro Person oder global?
- **Blockiert Charge:** K9. **Blockiert Version 1.0:** Nein.

## RM-DR-121 · `prophet-des-untergangs`

- **Betroffene Rollen:** `prophet-des-untergangs`; Wechselwirkung laut Dossier: alle Tötungsrollen (Freischaltung), Kutscher/Frankenstein (Wiederbelebung), Lehrling/Seelentauscher (Erbe des globalen Zustands), Rotkäppchen (zwei Tötungen), Schilde (Nekromant, Hades, Kartenschlucker, Rudelvater), Die …
- **Problem:** Offen sind: Einzelsieg; Freischaltung dauerhaft; Selbstmarkierung. Legacy-Befund `not-found`.
- **Belege:** [Dossier](dossiers/solos-a.md#prophet-des-untergangs); RM-C-048, RM-C-049, RM-C-050 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-006, RM-DR-007, RM-DR-014.
- **Teilfrage 1: Einzelsieg**
  - Option A: Sieg als letzter Überlebender (bzw. letzte Nicht-Prophet-Person tot)
  - Option B: Sieg, sobald freigeschaltet und X weitere Tote
  - Auswirkung: Balance: Ohne Regel ist die Rolle faktisch Dorf-Hilfe; Umsetzung: neue Siegbedingung
  - Empfehlung: PO definieren (07 Q4 B: SL-Siegbutton bis dahin)
- **Teilfrage 2: Freischaltung dauerhaft**
  - Option A: dauerhaft
  - Option B: solange alle tot
  - Auswirkung: Balance: selten; Umsetzung: Status speichern
  - Empfehlung: dauerhaft
- **Teilfrage 3: Selbstmarkierung**
  - Option A: nur andere
  - Option B: beliebig
  - Auswirkung: Balance: Selbstmarkierung macht Freischaltung unmöglich; Umsetzung: Filter
  - Empfehlung: nur andere
- **Weitere offene Fragen (Dossier):** (1) Wann genau gewinnt der Prophet alleine? (2) Darf er sich selbst oder Tote markieren? Markieren nur in Nacht 1? (3) Bleibt die Freischaltung nach Wiederbelebung eines Markierten? (4) Soll die Prophet-Tötung von Schutzengel/Dorfwache geblockt werden? (5) Gewinnt das Dorf, wenn alle Wölfe tot sind, der freigeschaltete Prophet aber lebt?
- **Blockiert Charge:** K9. **Blockiert Version 1.0:** Nein.

## RM-DR-122 · `daemonischer-wolf`

- **Betroffene Rollen:** `daemonischer-wolf`; Wechselwirkung laut Dossier: Orakel, Blutpriester, Waldläufer, Doktor, Detektiv, Kopfgeldjäger, Ritter, Dorfschmied, Traumdeuter (alle `isWolf`-Leser); Seelentauscher und Wächter am Tor (löschen Fluch); Nekromant …
- **Problem:** Offen sind: Auslöser; Wirkung des Fluchs; Todespfade. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-b.md#daemonischer-wolf); RM-C-022, RM-C-023, RM-C-024 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-009.
- **Teilfrage 1: Auslöser**
  - Option A: Die Opfer des Rudels werden verflucht (dann sind sie aber tot)
  - Option B: Beim eigenen Tod verflucht er ein Opfer seiner Wahl
  - Auswirkung: Balance: hoch: laufender Fluch vs. einmaliger Todesfluch; Umsetzung: Nachtschritt vs. Todesreaktion
  - Empfehlung: Todesreaktion (Code) übernehmen, Text präzisieren
- **Teilfrage 2: Wirkung des Fluchs**
  - Option A: nur `appears_as` (Informationsrollen)
  - Option B: echter Fraktionswechsel für Parität
  - Auswirkung: Balance: sehr hoch: Dorf kann ohne echten Wolf nicht gewinnen; Umsetzung: Godot `appears_as` vs. `counts_as_wolf`
  - Empfehlung: nur `appears_as`
- **Teilfrage 3: Todespfade**
  - Option A: jeder Tod löst Fluch aus
  - Option B: nur Wolfsangriff und Lynch
  - Auswirkung: Balance: mittel; Umsetzung: Reaktion an KillPipeline für alle Ursachen
  - Empfehlung: jeder Tod
- **Weitere offene Fragen (Dossier):** 1. Auslöser: eigener Tod (Code) oder laufender Fluch auf Rudelopfer (Textwortlaut)? 2. Wirkung: nur Erscheinung für Informationsrollen oder echte Wolfszählung? 3. Löst jede Todesart den Fluch aus oder nur Nachtangriff und Lynch? 4. Ist der Fluch Pflicht oder darf verzichtet werden? 5. Welche Rollen sehen den Fluch (Orakel ja; Doktor, Waldläufer, Detektiv, Ritter, Schmied?)?
- **Blockiert Charge:** K12. **Blockiert Version 1.0:** Nein.

## RM-DR-123 · `schattenhund`

- **Betroffene Rollen:** `schattenhund`; Wechselwirkung laut Dossier: alle Dorf-Nachtrollen; Wolfskind und Lehrling (Begründung der Nacht-1-Sperre); Albtraumwolf, Zeitwächter, Der Weise (gleiche …
- **Problem:** Offen sind: Betroffene Rollen; Nacht 1; Nicht-Nachtschritt-Effekte. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-b.md#schattenhund); RM-C-025, RM-C-026, RM-C-027 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-010, RM-DR-014.
- **Teilfrage 1: Betroffene Rollen**
  - Option A: nur Fraktion Dorf
  - Option B: alle Nicht-Wölfe
  - Auswirkung: Balance: mittel: Solos werden mitblockiert; Umsetzung: Filter über Fraktion statt "nicht Wolf"
  - Empfehlung: nur Dorf
- **Teilfrage 2: Nacht 1**
  - Option A: Einsatz ab Nacht 1
  - Option B: ab Nacht 2
  - Auswirkung: Balance: gering; Umsetzung: Verfügbarkeitsbedingung des Schritts
  - Empfehlung: ab Nacht 2, Text ergänzen
- **Teilfrage 3: Nicht-Nachtschritt-Effekte**
  - Option A: nur Nachtschritte
  - Option B: auch Reaktionen/passive Effekte dieser Nacht
  - Auswirkung: Balance: mittel; Umsetzung: Blockade als Schritt-Status oder als globale Regel
  - Empfehlung: nur Nachtschritte, Text präzisieren
- **Weitere offene Fragen (Dossier):** 1. Nur Dorf oder alle Nicht-Wölfe? 2. Ab Nacht 1 oder ab Nacht 2? 3. Werden auch Morgenreaktionen (Märtyrerin, Schmiede-Waffe) und Todesreaktionen in dieser Nacht blockiert? 4. Teilen mehrere Schattenhunde einen Einsatz?
- **Blockiert Charge:** K8. **Blockiert Version 1.0:** Ja.

## RM-DR-124 · `besessener-wolf`

- **Betroffene Rollen:** `besessener-wolf`; Wechselwirkung laut Dossier: Loki (Liebeskummer-Pfad), Schwarze Witwe und Giftwolf (Morgen-Tode), Dämonischer Wolf (Reihenfolge), Rudelvater, Nekromant, Kartenschlucker, Hades, Schattenwanderer, Parasit …
- **Problem:** Offen sind: Schwelle "≥5 Spieler". Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/wolves-b.md#besessener-wolf); RM-C-028 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-004, RM-DR-009.
- **Teilfrage 1: Schwelle "≥5 Spieler"**
  - Option A: 5 Lebende inkl. ihm im Todesmoment
  - Option B: 5 Spieler bei Spielbeginn
  - Auswirkung: Balance: mittel im Endspiel; Umsetzung: Prüfzeitpunkt (Tod vs. Abarbeitung)
  - Empfehlung: lebende inkl. ihm im Todesmoment, keine Neuprüfung
- **Weitere offene Fragen (Dossier):** 1. Schwelle: 5 Lebende inkl. ihm im Todesmoment oder zum Abarbeitungszeitpunkt? 2. Ist die Mitnahme Pflicht oder darf verzichtet werden? 3. Dürfen Wölfe mitgerissen werden (Code: ja)? 4. Greifen Schilde gegen die Mitnahme (Code: ja)?
- **Blockiert Charge:** K4. **Blockiert Version 1.0:** Ja.

## RM-DR-125 · `fenrir`

- **Betroffene Rollen:** `fenrir`; Wechselwirkung laut Dossier: Ritter, Henker (LynchCount), Feuerteufel (Brand), Lehrling/Seelentauscher/Frankenstein (Rollenerwerb mit alter Stufe), alle …
- **Problem:** Offen sind: Umfang des Überlebens; Zählung; Ritter. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-b.md#fenrir); RM-C-029, RM-C-030, RM-C-031 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-011.
- **Teilfrage 1: Umfang des Überlebens**
  - Option A: jede Todesursache, einmal
  - Option B: nur Hinrichtung
  - Auswirkung: Balance: hoch: Nachtangriffe kann Wolf-Team nicht wählen, aber Witwe/Hexe/Hades sehr wohl; Umsetzung: Abfangregel in KillPipeline vs. ExecutionRules
  - Empfehlung: jede Ursache (Text)
- **Teilfrage 2: Zählung**
  - Option A: +1 am Morgen nach überlebter Nacht
  - Option B: +1 bei Nachtbeginn
  - Auswirkung: Balance: gering (eine Nacht früher Stufe 3); Umsetzung: Zeitpunkt DAWN vs. NIGHT_START
  - Empfehlung: +1 am Morgen, wenn Fenrir lebt
- **Teilfrage 3: Ritter**
  - Option A: Teil von "jeder Tod" (einmal)
  - Option B: Sonderimmunität
  - Auswirkung: Balance: mittel; Umsetzung: Ritter-Zielauswahl
  - Empfehlung: an Einmal-Schutz koppeln
- **Weitere offene Fragen (Dossier):** 1. Überlebt Fenrir jede Todesursache oder nur Hinrichtung? 2. Zählt die Stufe bei Nachtbeginn oder nach überlebter Nacht? 3. Ist Fenrir ab Stufe 3 für den Ritter immun, und wenn ja, dauerhaft oder als Teil des Einmal-Schutzes? 4. Zählt ein abgewehrter Lynch als Lynch (Henker, Log)? 5. Soll die Stufe für den SL sichtbar sein?
- **Blockiert Charge:** K4. **Blockiert Version 1.0:** Nein.

## RM-DR-126 · `kutscher`

- **Betroffene Rollen:** `kutscher`; Wechselwirkung laut Dossier: Wächter am Tor, Werwolf/Rudel, alle Rollen im Pool, Totenkarten (4 revive-Karten), Prophet des Untergangs (Ziele), Schicksalswolf (`FirstThreeDeadIds`), Seelentauscher/Lehrling …
- **Problem:** Offen sind: Rollen der Wiederbelebten; Wer wählt die Toten; Einmaligkeit. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-2.md#kutscher); RM-C-114, RM-C-115, RM-C-117 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-011, RM-DR-013, RM-DR-015.
- **Teilfrage 1: Rollen der Wiederbelebten**
  - Option A: echte Wiederbelebung, alte Rolle bleibt (außer Wolf)
  - Option B: "Nachbardorf" bringt neue Personen mit neuen Rollen (Code, Dialogtext)
  - Auswirkung: Balance: neue Solo-Rollen mitten im Spiel können Sieglage kippen; Umsetzung: Rollenpool, Fraktionszuordnung, Siegbedingungen neuer Solos
  - Empfehlung: PO; wenn Code: Pool auf Dorfrollen des Akts begrenzen
- **Teilfrage 2: Wer wählt die Toten**
  - Option A: Kutscher/SL wählt
  - Option B: Zufall (SeededRng)
  - Auswirkung: Balance: Wahl macht Rolle stärker; Umsetzung: Prompt vs. RNG
  - Empfehlung: PO
- **Teilfrage 3: Einmaligkeit**
  - Option A: einmal pro Partie
  - Option B: einmal pro Person
  - Auswirkung: Balance: Rollenerbe verdoppelt Effekt; Umsetzung: `ability_uses` pro Person
  - Empfehlung: einmal pro Person, Text ergänzen
- **Weitere offene Fragen (Dossier):** (1) Behalten Wiederbelebte ihre Rolle, oder kommen "neue Personen aus dem Nachbardorf" mit neuen Rollen? (2) Wer wählt die drei Toten: Zufall, Kutscher oder SL? (3) Aus welchem Pool kommen neue Rollen (nur Dorf, nur Akt)? (4) Wer wird Wolf: Zufall oder Wahl? (5) Einmal pro Partie oder pro Person, und setzt Rollenerbe den Verbrauch zurück? (6) Was passiert mit Totenkarten und Bindungen der Wiederbelebten? (7) Zählt die Schwelle 10 alle Toten (Legacy: ja)?
- **Blockiert Charge:** K13. **Blockiert Version 1.0:** Nein.

## RM-DR-127 · `seelentauscher`

- **Betroffene Rollen:** `seelentauscher`; Wechselwirkung laut Dossier: alle Rollen (tauschbar), insbesondere Wolfsrollen, Wächter am Tor, Wolfskind/Lehrling (Bindungen), Loki/Rotkäppchen/Parasit (Sitz-Bindungen), Dorfwache/Märtyrerin (Rollenprüfung am Morgen), Kutscher/Blutpriester …
- **Problem:** Offen sind: Was wandert mit; Toter erhält Wolfsrolle; Information der Betroffenen. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/village-2.md#seelentauscher); RM-C-119, RM-C-120, RM-C-121 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-014.
- **Teilfrage 1: Was wandert mit**
  - Option A: Rolle inkl. Rollenzustand (Verbrauch, Bindungen) wandert
  - Option B: nur Rollenname, Zustand bleibt
  - Auswirkung: Balance: Tausch von verbrauchten Rollen; Umsetzung: RoleTransition-Schnappschuss definiert
  - Empfehlung: PO
- **Teilfrage 2: Toter erhält Wolfsrolle**
  - Option A: erlaubt
  - Option B: Wächter-Prüfung auch für Tote
  - Auswirkung: Balance: gering (tot), relevant bei Wiederbelebung; Umsetzung: Wächter-Regel auf alle Rollenwechsel
  - Empfehlung: Wächter-Prüfung auch bei Wiederbelebung
- **Teilfrage 3: Information der Betroffenen**
  - Option A: Betroffene erfahren neue Rolle
  - Option B: geheim
  - Auswirkung: Balance: hoch (Spieler kennt eigene Rolle nicht); Umsetzung: InfoRecord an Betroffene
  - Empfehlung: A
- **Weitere offene Fragen (Dossier):** (1) Wandert der Rollenzustand (Verbrauch, Vorbild, Mentor, Schild) mit der Rolle oder bleibt er an der Person? (2) Erfahren die Getauschten ihre neue Rolle, und wann? (3) Darf der Seelentauscher sich selbst tauschen? (4) Gilt Wächter am Tor auch für tote Empfänger einer Wolfsrolle? (5) Bleiben Liebes-/Bindungsmarker am Sitz?
- **Blockiert Charge:** K12. **Blockiert Version 1.0:** Nein.

## RM-DR-128 · `blutpriester`

- **Betroffene Rollen:** `blutpriester`; Wechselwirkung laut Dossier: Rudelvater, Nekromant, Hades, Kartenschlucker, Parasit, Schattenwanderer (Todesabfang), Dämonischer Wolf (`cursedWolfAura` zählt als Wolf), Doppelspion (nicht Wolf), Sensenträger (Reaktion auf Opfer), Seelentauscher …
- **Problem:** Offen sind: Anzahl 0–3; Wer sieht das Ergebnis. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/village-2.md#blutpriester); RM-C-122, RM-C-123 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-014, RM-DR-015.
- **Teilfrage 1: Anzahl 0–3**
  - Option A: SL entscheidet
  - Option B: Anzahl aus Regel (z. B. Zufall oder Rolle des Opfers)
  - Auswirkung: Balance: SL-Willkür vs. Planbarkeit; Umsetzung: Prompt vs. RNG
  - Empfehlung: PO; Legacy (SL wählt) beibehalten ist einfach
- **Teilfrage 2: Wer sieht das Ergebnis**
  - Option A: öffentlich (aufdecken)
  - Option B: nur Blutpriester
  - Auswirkung: Balance: groß (öffentliche Wolfsnennung); Umsetzung: Ereignis-Sichtbarkeit public vs. actor
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** (1) Wer bestimmt die Anzahl 0 bis 3 (SL frei, Zufall, Regel)? (2) Ist die Aufdeckung öffentlich oder nur für den Blutpriester? (3) Zählen verfluchte Dorfbewohner (erscheinen als Wolf) und Trugbilderwolf-Erscheinung? (4) Verbraucht ein abgefangener Tod die Fähigkeit? (5) Darf er sich selbst opfern?
- **Blockiert Charge:** K7. **Blockiert Version 1.0:** Nein.

## RM-DR-129 · `traumdeuter`

- **Betroffene Rollen:** `traumdeuter`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (Fluch), Trugbilderwolf (Erscheinung), Doppelspion, Albtraumwolf/Schattenhund/Zeitwächter/Der Weise …
- **Problem:** Offen sind: Inhalt der Vision; Selbst in der Vision; Verfluchte als Wolf. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-2.md#traumdeuter); RM-C-125, RM-C-126, RM-C-127 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-015.
- **Teilfrage 1: Inhalt der Vision**
  - Option A: Code übernehmen, Text präzisieren
  - Option B: eigene Mechanik (Rollen/Zustände)
  - Auswirkung: Balance: Code: starke Info jede Nacht; Umsetzung: A: kleiner Aufwand; B: neue Spezifikation
  - Empfehlung: A mit Textanpassung
- **Teilfrage 2: Selbst in der Vision**
  - Option A: ausschließen
  - Option B: erlaubt
  - Auswirkung: Balance: Selbstnennung ist verschwendete Info; Umsetzung: Filter
  - Empfehlung: ausschließen
- **Teilfrage 3: Verfluchte als Wolf**
  - Option A: Erscheinung zählt (Fehlinformation)
  - Option B: nur echte Wölfe
  - Auswirkung: Balance: beeinflusst Dämonischen Wolf; Umsetzung: InformationRules.determine
  - Empfehlung: Erscheinung zählt
- **Weitere offene Fragen (Dossier):** (1) Code-Mechanik übernehmen und Text anpassen oder neue Mechanik? (2) Darf der Traumdeuter sich selbst in der Vision sehen? (3) Zählt Erscheinung (Fluch, Trugbild) oder wahre Fraktion? (4) Was, wenn weniger als 2 Nicht-Wölfe leben?
- **Blockiert Charge:** K7. **Blockiert Version 1.0:** Nein.

## RM-DR-130 · `henker`

- **Betroffene Rollen:** `henker`; Wechselwirkung laut Dossier: alle Lynch-Sonderzweige (Wahnsinniger Kutscher, Voodoo, Der Weise, Selbstmörder, Spiegelwolf, Dämonischer Wolf, Fenrir, Cerberus, Rudelvater), Rudelvater/Nekromant/Hades/Kartenschlucker/Parasit …
- **Problem:** Offen sind: Blockierter Lynch (Fenrir/Cerberus); Zählbasis; Henker tot. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/village-2.md#henker); RM-C-129, RM-C-130, RM-C-131 in [`04`](04-rule-conflicts.md).
- **Teilfrage 1: Blockierter Lynch (Fenrir/Cerberus)**
  - Option A: blockierter Lynch zählt als Lynch
  - Option B: zählt nicht (kein Tod)
  - Auswirkung: Balance: beeinflusst Aktivierung und Markierten; Umsetzung: ExecutionRules-Ergebnis "verhindert"
  - Empfehlung: PO bestätigen, 07 geht von A aus
- **Teilfrage 2: Zählbasis**
  - Option A: Vorgänge
  - Option B: nur Lynch-Tote
  - Auswirkung: Balance: Spiegelwolf/Voodoo-Tage; Umsetzung: Zähler-Definition
  - Empfehlung: Vorgänge, i18n anpassen
- **Teilfrage 3: Henker tot**
  - Option A: wirkt weiter
  - Option B: verfällt mit Henker
  - Auswirkung: Balance: gering; Umsetzung: Bindung Markierung↔Henker
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** (1) Zählt ein durch Fenrir/Cerberus verhinderter Lynch (Zählung und Vollstreckung)? (2) Zählen Lynch-Vorgänge oder nur Lynch-Tote? (3) Verfällt die Markierung, wenn am Folgetag nicht gelyncht wird, oder bleibt sie bis zum nächsten Lynch? (4) Wirkt die Markierung nach dem Tod des Henkers weiter? (5) Darf der Henker sich selbst markieren? (6) Ist die Markierung öffentlich?
- **Blockiert Charge:** K4. **Blockiert Version 1.0:** Nein.

## RM-DR-131 · `feuerteufel`

- **Betroffene Rollen:** `feuerteufel`; Wechselwirkung laut Dossier: Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Albtraumwolf (Blockade), Der Weise, Dorfschmied, Nekromant, Waldhexe, Märtyrerin, Voodoo-Priester, Dorfwache (Überleben/Entfernen aus Zielen), …
- **Problem:** Offen sind: Auslöser; Dauer der Markierung; Nachbarn; Feuerteufel als Nachbar; Siegbedingung. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/solos-a.md#feuerteufel); RM-C-051, RM-C-052, RM-C-053, RM-C-054, RM-C-055 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-003, RM-DR-006, RM-DR-007, RM-DR-009.
- **Teilfrage 1: Auslöser**
  - Option A: jeder tatsächliche Tod, jede Ursache
  - Option B: nur Wolfsangriff und Hinrichtung, aber nur bei Tod
  - Auswirkung: Balance: A stärker; Umsetzung: Todesreaktion in KillPipeline
  - Empfehlung: A oder B, jeweils nur bei Tod
- **Teilfrage 2: Dauer der Markierung**
  - Option A: bis Ziel stirbt
  - Option B: nur diese Nacht
  - Auswirkung: Balance: A viel stärker; Umsetzung: Statusmarker mit Ablauf
  - Empfehlung: PO
- **Teilfrage 3: Nachbarn**
  - Option A: direkte Sitze
  - Option B: nächste Lebende
  - Auswirkung: Balance: B tötet immer 2; Umsetzung: Sitznachbarschaft
  - Empfehlung: analog Wahnsinniger Kutscher
- **Teilfrage 4: Feuerteufel als Nachbar**
  - Option A: immer verschont
  - Option B: nie verschont
  - Auswirkung: Balance: –; Umsetzung: Filter
  - Empfehlung: einheitlich
- **Teilfrage 5: Siegbedingung**
  - Option A: Einzelsieg definieren
  - Option B: Fraktion ändern (Dorf-Chaos-Rolle)
  - Auswirkung: Balance: –; Umsetzung: WinRules
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** (1) Brand bei jedem Tod des Ziels oder nur Nacht/Hinrichtung? (2) Wie lange gilt die Markierung? (3) Direkte oder lebende Nachbarn? (4) Stirbt der Feuerteufel, wenn er Nachbar ist? (5) Welche Siegbedingung, oder gehört die Rolle nicht zur Einzelsiegfraktion? (6) Kettenbrand, wenn ein verbrannter Nachbar selbst markiert ist?
- **Blockiert Charge:** K9. **Blockiert Version 1.0:** Nein.

## RM-DR-132 · `voodoo-priester`

- **Betroffene Rollen:** `voodoo-priester`; Wechselwirkung laut Dossier: Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Waldhexe (Gift), Märtyrerin, Der Weise, Dorfschmied, Nekromant (Reihenfolge der Abfangregeln), Rattenfänger (Verzauberung), Feuerteufel (Brand …
- **Problem:** Offen sind: Ursachen der Umlenkung; Abklingzeit; Verzauberung löschen; Siegbedingung. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/solos-a.md#voodoo-priester); RM-C-056, RM-C-057, RM-C-058, RM-C-059 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-006, RM-DR-007.
- **Teilfrage 1: Ursachen der Umlenkung**
  - Option A: jede Todesursache
  - Option B: nur Angriffe (Wolf, Hinrichtung, Gift)
  - Auswirkung: Balance: A macht ihn sehr robust; Umsetzung: Umlenkungsregel mit Ursachenfilter in KillPipeline
  - Empfehlung: PO
- **Teilfrage 2: Abklingzeit**
  - Option A: Code übernehmen, Text ergänzen
  - Option B: keine Abklingzeit
  - Auswirkung: Balance: ohne Abklingzeit endloser Schutz; Umsetzung: Zähler
  - Empfehlung: Code
- **Teilfrage 3: Verzauberung löschen**
  - Option A: Altlast
  - Option B: gewollt
  - Auswirkung: Balance: Rattenfänger-Konter; Umsetzung: –
  - Empfehlung: streichen
- **Teilfrage 4: Siegbedingung**
  - Option A: Einzelsieg definieren
  - Option B: Fraktion ändern
  - Auswirkung: Balance: –; Umsetzung: WinRules
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier):** (1) Welche Todesursachen lenkt die Puppe um? (2) Abklingzeit übernehmen, wie lang, auch nach normalem Tod der Puppe? (3) Darf der Priester sich selbst die Puppe geben? (4) Verliert der Puppenträger Verzauberung? (5) Weiß der Puppenträger von der Puppe? (6) Siegbedingung oder Fraktionswechsel? (7) Umlenkung vor oder nach Märtyrerin/Der Weise/Schmied?
- **Blockiert Charge:** K10. **Blockiert Version 1.0:** Nein.

## RM-DR-133 · `blutwolf`

- **Betroffene Rollen:** `blutwolf`; Wechselwirkung laut Dossier: alle Tötungen neben dem Blutwolf; indirekt Korrupter Richter und Hades (gleiche …
- **Problem:** Offen sind: Umsetzung ohne Stimmsystem. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/wolves-b.md#blutwolf).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-003, RM-DR-008.
- **Teilfrage 1: Umsetzung ohne Stimmsystem**
  - Option A: Gewicht als Hinweis für die physische Zählung anzeigen (Legacy-Marker „V<n>“)
  - Option B: Rolle bis zu einem Stimmsystem zurückstellen
  - Auswirkung: Balance: –; Umsetzung: A: Sitznachbarschaft (RM-DR-003) und Anzeige
  - Empfehlung: siehe RM-DR-008
- **Weitere offene Fragen (Dossier):** 1. Reicht eine SL-Anzeige des Gewichts (ohne Stimmerfassung)? 2. Zählen tote Nachbarn, auch wenn später wiederbelebt (live berechnet)? 3. Gilt das Gewicht auch, wenn der Blutwolf tot ist und Tote abstimmen dürfen (Nekromant-Kontext)?
- **Blockiert Charge:** K14. **Blockiert Version 1.0:** Nein.

## RM-DR-134 · `albtraumwolf`

- **Betroffene Rollen:** `albtraumwolf`; Wechselwirkung laut Dossier: alle Nicht-Wolf-Nachtrollen mit tier > 2.1; Schattenhund/Zeitwächter/Der Weise (gleiche Blockadefamilie); Dämonischer Wolf (Verfluchte nicht wählbar); Rudel …
- **Problem:** Offen sind: Ziele; Umfang; Späte Wirkung. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/wolves-b.md#albtraumwolf); RM-C-033, RM-C-034, RM-C-036 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-010.
- **Teilfrage 1: Ziele**
  - Option A: nur Fraktion Dorf
  - Option B: alle Nicht-Wölfe
  - Auswirkung: Balance: mittel; Umsetzung: Zielfilter
  - Empfehlung: alle Nicht-Wölfe (Solos sind Gegner der Wölfe), Text anpassen
- **Teilfrage 2: Umfang**
  - Option A: nur die gewählte Person
  - Option B: alle Personen der Rolle
  - Auswirkung: Balance: mittel bei Mehrfachrollen; Umsetzung: Blockade pro Person vs. pro Rolle
  - Empfehlung: nur die Person
- **Teilfrage 3: Späte Wirkung**
  - Option A: Albtraumwolf handelt vor Dorfrollen
  - Option B: Blockade nur für spätere Schritte
  - Auswirkung: Balance: mittel: Schutzengel nie blockierbar; Umsetzung: Nachtreihenfolge
  - Empfehlung: tier vor Gruppe B verschieben oder Text präzisieren
- **Weitere offene Fragen (Dossier):** 1. Dürfen Solos blockiert werden? 2. Person oder ganze Rolle? 3. Soll der Albtraumwolf vor den Dorf-Schutzrollen handeln (tier), damit Schutzengel blockierbar ist? 4. Wirkt eine Blockade auch auf Morgen- und Todesreaktionen der Person?
- **Blockiert Charge:** K8. **Blockiert Version 1.0:** Nein.

## RM-DR-135 · `cerberus`

- **Betroffene Rollen:** `cerberus`; Wechselwirkung laut Dossier: Waldhexe (Trank), Henker (LynchCount), Feuerteufel (Brand beim Lynch), Kopfgeldjäger (Lynch eines Wolfs), Spiegelwolf/Voodoo/Der Weise (Reihenfolge der Lynch-Sonderzweige …
- **Problem:** Offen sind: Wahl oder Automatik; Hexengift. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/wolves-b.md#cerberus); RM-C-037, RM-C-038 in [`04`](04-rule-conflicts.md).
- **Teilfrage 1: Wahl oder Automatik**
  - Option A: Cerberus entscheidet (Prompt)
  - Option B: automatisch
  - Auswirkung: Balance: mittel: Wahl erlaubt Bluff/Aufsparen; Umsetzung: Prompt in ExecutionRules
  - Empfehlung: Prompt an SL "Cerberus wehrt ab?"
- **Teilfrage 2: Hexengift**
  - Option A: nur Lynch
  - Option B: jede Hinrichtung/gezielte Tötung
  - Auswirkung: Balance: mittel; Umsetzung: zusätzliche Abfangregel
  - Empfehlung: nur Lynch (Text)
- **Weitere offene Fragen (Dossier):** 1. Automatische Abwehr oder Wahl? 2. Auch gegen Hexengift oder andere gezielte Tötungen? 3. Zählt eine abgewehrte Lynchung für Henker/Log als Lynch? 4. Darf am selben Tag nach einer Abwehr erneut gelyncht werden? 5. Köpfe pro Nachtbeginn oder pro überlebter Nacht?
- **Blockiert Charge:** K4. **Blockiert Version 1.0:** Ja.

## RM-DR-136 · `ritter`

- **Betroffene Rollen:** `ritter`; Wechselwirkung laut Dossier: Dämonischer Wolf (Verfluchte), Fenrir, Rudelvater (Ersttod-Rettung, PACKFATHER_KILL), Schattenwanderer (Umlenkung), Zeitwächter, Waldhexe, Hades, Schwarze Witwe, Giftwolf, Feuerteufel, Kartenschlucker, Nekromant-Schild, …
- **Problem:** Offen sind: Welche Nachttode lösen aus; Verfluchter Dorfbewohner als Ziel; Fenrir ab Stufe 3. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-3.md#ritter); RM-C-132, RM-C-133, RM-C-134 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-003, RM-DR-004, RM-DR-009.
- **Teilfrage 1: Welche Nachttode lösen aus**
  - Option A: jeder Tod in der Nacht löst aus
  - Option B: nur Tode durch feindliche Nachtangriffe (Liste, ggf. erweitert um PACKFATHER_KILL)
  - Auswirkung: Balance: A stärkt das Dorf deutlich (auch Kettentode schlagen zurück); Umsetzung: Ursachen-Attribut `triggers_knight` in beiden Fällen nötig, nur Belegung unterscheidet sich
  - Empfehlung: B mit Ergänzung PACKFATHER_KILL und VOODOO_PUPPET, Text präzisieren
- **Teilfrage 2: Verfluchter Dorfbewohner als Ziel**
  - Option A: nur echte Wölfe
  - Option B: alles, was als Wolf zählt
  - Auswirkung: Balance: A schützt Verfluchte; Umsetzung: Ziel über `counts_as_wolf` statt `appears_as`
  - Empfehlung: hängt an Q1 Dämonischer Wolf; bei "nur Erscheinung" nur echte Wölfe
- **Teilfrage 3: Fenrir ab Stufe 3**
  - Option A: Fenrir-Immunität gilt auch gegen Ritter
  - Option B: Ritter trifft Fenrir normal
  - Auswirkung: Balance: gering; Umsetzung: Sonderregel im Zielfinder
  - Empfehlung: nach Fenrir-Entscheidung (07 Q1 Fenrir-Zeile) ausrichten
- **Weitere offene Fragen (Dossier):** 1. Löst jeder Tod in der Nacht aus oder nur eine Ursachenliste? Gehören PACKFATHER_KILL und VOODOO_PUPPET dazu? 2. Darf der Ritter einen nur verfluchten Dorfbewohner treffen? 3. Gleichstand links/rechts: welche Richtung (aus Sicht des Ritters), und soll der SL wählen? 4. Ist Fenrir ab Stufe 3 gegen den Ritter immun? 5. Wird die Vergeltung nach Wiederbelebung erneut verfügbar? 6. Wirkt die Rudelvater-Ersttod-Rettung gegen den Ritter-Schlag?
- **Blockiert Charge:** K3. **Blockiert Version 1.0:** Ja.

## RM-DR-137 · `rotkaeppchen`

- **Betroffene Rollen:** `rotkaeppchen`; Wechselwirkung laut Dossier: alle Rollen mit Nachtfähigkeit (Apfel), König/Frankenstein/Dorfschmied/Pestbringerin/Prophet (`APPLE_RESET_FLAGS`), Seelentauscher, Parasit, Kartenschlucker/Hades/Nekromant (Schilde), Ritter (Kettentod löst keine …
- **Problem:** Offen sind: Wölfe als Zuflucht; Apfel-Wirkung; Dauer der Kette; Ablehnung; Mehrfache Zuflucht beim Selben. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-3.md#rotkaeppchen); RM-C-135, RM-C-136, RM-C-137, RM-C-138, RM-C-139 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-009, RM-DR-011.
- **Teilfrage 1: Wölfe als Zuflucht**
  - Option A: jede andere lebende Person
  - Option B: nur Nicht-Wölfe
  - Auswirkung: Balance: A erlaubt Wolf-Apfel (Doppelkill?) und Wolf-Kette; Umsetzung: Zielfilter
  - Empfehlung: B (Code), Text ergänzen
- **Teilfrage 2: Apfel-Wirkung**
  - Option A: jede nächste Fähigkeit (auch Info) zweimal
  - Option B: nur Zielwahl-Fähigkeiten, sonst verfällt der Apfel
  - Auswirkung: Balance: A wertet Info-Rollen stark auf; Umsetzung: "repeat step" in StepQueue plus Verfall-Regel
  - Empfehlung: eigene Regel: Apfel verfällt nach der nächsten eigenen Nachtaktion, Info-Rollen erhalten die Info zweimal oder gar nicht (entscheiden)
- **Teilfrage 3: Dauer der Kette**
  - Option A: nur diese Nacht
  - Option B: bis zur nächsten gewährten Zuflucht
  - Auswirkung: Balance: A schwächt Risiko deutlich; Umsetzung: Bindungsobjekt mit Gültigkeit
  - Empfehlung: B (Code) festschreiben
- **Teilfrage 4: Ablehnung**
  - Option A: Ablehnung löst alte Kette
  - Option B: alte Kette bleibt
  - Auswirkung: Balance: gering; Umsetzung: Bindung beenden oder nicht
  - Empfehlung: entscheiden
- **Teilfrage 5: Mehrfache Zuflucht beim Selben**
  - Option A: jede Nacht ein anderer
  - Option B: beliebig
  - Auswirkung: Balance: A verhindert Dauer-Apfel beim selben Spieler; Umsetzung: Zielhistorie
  - Empfehlung: entscheiden
- **Weitere offene Fragen (Dossier):** 1. Dürfen Wölfe Zuflucht gewähren? 2. Wie lange gilt die Todeskette, und endet sie bei Ablehnung? 3. Entsteht die Kette nur bei gewährter Zuflucht? 4. Was bedeutet "doppelt" bei Info-Rollen und passiven Rollen, und verfällt ein ungenutzter Apfel? 5. Darf dieselbe Person mehrmals hintereinander gewählt werden? 6. Wirkt die Kette auch bei Hinrichtung am Tag (Legacy: ja)?
- **Blockiert Charge:** K10. **Blockiert Version 1.0:** Nein.

## RM-DR-138 · `selbstmoerder`

- **Betroffene Rollen:** `selbstmoerder`; Wechselwirkung laut Dossier: Feuerteufel (Brand vor Siegprüfung), Henker (Nebenhinrichtung), Voodoo (Puppe), alle Tötungsrollen (Totenzahl), Die …
- **Problem:** Offen sind: Zählbasis; Hinrichtungsarten. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/solos-a.md#selbstmoerder); RM-C-061, RM-C-062 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-007.
- **Teilfrage 1: Zählbasis**
  - Option A: vorher (Code/EN)
  - Option B: inklusive eigenem Tod
  - Auswirkung: Balance: B einen Tod früher; Umsetzung: Zählpunkt
  - Empfehlung: A, DE-Text präzisieren
- **Teilfrage 2: Hinrichtungsarten**
  - Option A: nur Hauptziel des Lynchs
  - Option B: auch Henker-Hinrichtung
  - Auswirkung: Balance: –; Umsetzung: ExecutionRules
  - Empfehlung: A
- **Weitere offene Fragen (Dossier):** (1) Zählt „5+ Tote" vor oder nach seinem Tod? (2) Zählt nur „LYNCH" oder auch Henker/SL-Hinrichtung (DECISION-LOG: SL-Hinrichtung ist `LYNCH`)? (3) Zählen wiederbelebte Personen als Tote (Legacy: nur aktueller Status)?
- **Blockiert Charge:** K1. **Blockiert Version 1.0:** Ja.

## RM-DR-139 · `kopfgeldjaeger`

- **Betroffene Rollen:** `kopfgeldjaeger`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (Verfluchte), Spiegelwolf/Fenrir/Cerberus (kein Tod beim Lynch), Der Weise, Lehrling/Seelentauscher, Schattenhund/Albtraumwolf/Zeitwächter (Blockade), Doppelspion (zählt als …
- **Problem:** Offen sind: Wiederholung; Selbst unter den drei; Aktivierung durch Erbe; Verfluchter als "Werwolf". Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/village-3.md#kopfgeldjaeger); RM-C-140, RM-C-141, RM-C-142, RM-C-143 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-015.
- **Teilfrage 1: Wiederholung**
  - Option A: eine Info pro Wolfs-Lynch (Zähler)
  - Option B: eine Info in der Nacht nach einem Wolfs-Lynch
  - Auswirkung: Balance: A minimal stärker; Umsetzung: Zähler statt bool
  - Empfehlung: A (Zähler), Texte angleichen
- **Teilfrage 2: Selbst unter den drei**
  - Option A: drei andere Spieler
  - Option B: beliebige lebende
  - Auswirkung: Balance: A gibt mehr Info; Umsetzung: Filter `id != actor`
  - Empfehlung: A
- **Teilfrage 3: Aktivierung durch Erbe**
  - Option A: nur Lynch aktiviert
  - Option B: Erbe startet aktiv
  - Auswirkung: Balance: B schenkt Info; Umsetzung: Rollenwechsel mit frischen Einsätzen ohne Aktivierung
  - Empfehlung: A
- **Teilfrage 4: Verfluchter als "Werwolf"**
  - Option A: nur echte Wölfe
  - Option B: Erscheinung zählt
  - Auswirkung: Balance: hängt an Q1; Umsetzung: `counts_as_wolf` vs `appears_as`
  - Empfehlung: nach Q1
- **Weitere offene Fragen (Dossier):** 1. Eine Info pro Wolfs-Lynch oder eine pro Nacht nach mindestens einem Wolfs-Lynch? 2. Darf der Kopfgeldjäger sich selbst unter den drei sehen? 3. Aktiviert ein Rollenerbe/Tausch sofort? 4. Aktiviert der Lynch eines verfluchten Dorfbewohners? 5. Verfällt die Info, wenn nicht genug Ziele leben, oder bleibt sie erhalten?
- **Blockiert Charge:** K7. **Blockiert Version 1.0:** Ja.

## RM-DR-140 · `koenig`

- **Betroffene Rollen:** `koenig`; Wechselwirkung laut Dossier: Wolfskind, Lehrling, Dämonischer Wolf (Verfluchte), Seelentauscher, Rotkäppchen (Apfel), Frankenstein/Kutscher (Wiederbelebung verändert …
- **Problem:** Offen sind: Häufigkeit; Wer wird gezeigt. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-3.md#koenig); RM-C-144, RM-C-145 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-015.
- **Teilfrage 1: Häufigkeit**
  - Option A: einmal im Spiel
  - Option B: jede Nacht, solange Bedingung gilt
  - Auswirkung: Balance: B ist in der Endphase sehr stark; Umsetzung: Einsatzzähler vs. Nachtbedingung
  - Empfehlung: 07-Vorschlag übernehmen oder A; Texte angleichen
- **Teilfrage 2: Wer wird gezeigt**
  - Option A: SL/Zufall wählt echten Dorf-Angehörigen (Fraktion aktuell)
  - Option B: rollenbasiert (Legacy)
  - Auswirkung: Balance: A verhindert Fehlinfo bei Wolfskind; Umsetzung: `faction` aktuell statt Katalog
  - Empfehlung: A, Zufall über SeededRng
- **Weitere offene Fragen (Dossier):** 1. Einmal im Spiel oder jede Nacht, solange Tote > Lebende? 2. Wählt der Zufall, der SL oder der König selbst? 3. Zählt die aktuelle Fraktion (verwandeltes Wolfskind = Wolf) oder die Startrolle? 4. Zählt ein Unentschieden (Tote = Lebende)? Legacy: nein. 5. Darf dieselbe Person mehrfach gezeigt werden?
- **Blockiert Charge:** K7. **Blockiert Version 1.0:** Nein.

## RM-DR-141 · `dr-victor-frankenstein`

- **Betroffene Rollen:** `dr-victor-frankenstein`; Wechselwirkung laut Dossier: Wächter am Tor, Loki (Liebende), Rotkäppchen (Apfel/Kette), Sensenträger (`hunterShot`/`hunterQueued`), Ritter, Lehrling/Seelentauscher (Erbe), Kutscher (zweite Wiederbelebungsrolle), Totenkarten `segen_08`, `wende_04`, …
- **Problem:** Offen sind: Rollenpool; Zustand des Wiederbelebten; Einmaligkeit bei Erbe; Totenkarten-Aktivierung nach Verbrauch. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/village-3.md#dr-victor-frankenstein); RM-C-147, RM-C-148, RM-C-149, RM-C-150 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-011, RM-DR-013.
- **Teilfrage 1: Rollenpool**
  - Option A: jede Rolle außer der bisherigen
  - Option B: nur nicht im Spiel befindliche Rollen
  - Auswirkung: Balance: Wolfsrolle stärkt ggf. Wölfe (Tag `creates-wolf`); Umsetzung: Katalogfilter, `max_copies`
  - Empfehlung: B mit ausdrücklich erlaubtem Dorfbewohner; Wolfsrollen nur nach Entscheidung
- **Teilfrage 2: Zustand des Wiederbelebten**
  - Option A: vollständiger Neustart des Sitzes (wie Kutscher)
  - Option B: Bindungen bleiben
  - Auswirkung: Balance: A verhindert Sofort-Tod durch Liebeskummer; Umsetzung: Wiederbelebungsmodell mit Reset-Liste
  - Empfehlung: A
- **Teilfrage 3: Einmaligkeit bei Erbe**
  - Option A: einmal pro Person
  - Option B: einmal pro Rolle im Spiel
  - Auswirkung: Balance: A erlaubt 2 Wiederbelebungen; Umsetzung: `ability_uses` pro Person
  - Empfehlung: A (Godot-Standard)
- **Teilfrage 4: Totenkarten-Aktivierung nach Verbrauch**
  - Option A: nur solange Wiederbelebung noch möglich
  - Option B: solange die Rolle lebt
  - Auswirkung: Balance: gering bis mittel; Umsetzung: Tag-Abfrage mit Verbrauchszustand
  - Empfehlung: A
- **Weitere offene Fragen (Dossier):** 1. Welche Rollen sind wählbar (nur nicht vergebene, auch Wolfs-/Solorollen, Dorfbewohner immer)? 2. Welche Marker/Bindungen verliert der Wiederbelebte (Liebe, Gift, Kette, Fluch)? 3. Einmal pro Person oder pro Rolle im Spiel (Erbe)? 4. Handelt die neue Rolle schon in derselben Nacht? 5. Wer erfährt die neue Rolle (nur SL und Wiederbelebter?), wird die Wiederbelebung öffentlich angesagt? 6. Bleiben Wiederbelebungs-Totenkarten nach Verbrauch aktiv? 7. Darf ein in dieser Nacht Gestorbener (erst am Morgen tot) Ziel sein? (Legacy: nein, Tode erst am Morgen.)
- **Blockiert Charge:** K13. **Blockiert Version 1.0:** Nein.

## RM-DR-142 · `nekromant`

- **Betroffene Rollen:** `nekromant`; Wechselwirkung laut Dossier: Werwolf-Rudel (Angriff als Auslöser), Schicksalswolf/Rudelvater (Zusatzziele, `PACKFATHER_KILL` durchbricht Schild), Dämonischer Wolf (`cursedWolfAura` zählt bei Benennung als Wolf, Nekromant selbst kann verflucht …
- **Problem:** Offen sind: Wen schützt der Schild; Umlenkung optional oder Pflicht; Ressource der Toten; Siegversuche; Übungs-Enthüllung. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/solos-b.md#nekromant); RM-C-066, RM-C-067, RM-C-068, RM-C-069, RM-C-070 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-005, RM-DR-007, RM-DR-008.
- **Teilfrage 1: Wen schützt der Schild**
  - Option A: globaler Schild für die nächste Tötung irgendwo
  - Option B: Schild nur für den Nekromanten, jede Todesart
  - Auswirkung: Balance: global: Nekromant kann Wolfskill auf beliebige Person verhindern (Dorf-nahe Macht), auch Lynch am Tag; Umsetzung: global braucht globalen Modifikator in der KillPipeline; selbst passt in Protections
  - Empfehlung: PO entscheidet; Text so oder so präzisieren
- **Teilfrage 2: Umlenkung optional oder Pflicht**
  - Option A: optional (Text)
  - Option B: Pflicht (Code)
  - Auswirkung: Balance: Pflicht zwingt Nekromanten, einen Mitspieler zu töten; Umsetzung: PendingPrompt mit "nicht umlenken"
  - Empfehlung: Text gilt: optional mit Verzicht
- **Teilfrage 3: Ressource der Toten**
  - Option A: ein gemeinsamer Vorrat "Stimme der Toten"
  - Option B: zwei getrennte Vorräte
  - Auswirkung: Balance: getrennt: doppelte Nutzung derselben Toten; Umsetzung: Statusmarker pro Toter: ein oder zwei Felder
  - Empfehlung: ein gemeinsamer Marker "geopfert"
- **Teilfrage 4: Siegversuche**
  - Option A: beliebig viele Versuche
  - Option B: ein Versuch pro Tag oder pro Spiel, evtl. mit Strafe
  - Auswirkung: Balance: unbegrenzt: Solo-Sieg praktisch sicher durch Durchprobieren; Umsetzung: Versuchszähler und Tagesaktion
  - Empfehlung: Begrenzung festlegen
- **Teilfrage 5: Übungs-Enthüllung**
  - Option A: streichen
  - Option B: als Regel übernehmen und Text ergänzen
  - Auswirkung: Balance: unklar, derzeit nur Hinweis; Umsetzung: eigener Tagesbefehl
  - Empfehlung: streichen, sofern keine Regelquelle existiert
- **Weitere offene Fragen (Dossier):** 1. Schützt der Schild jede Person oder nur den Nekromanten? Gilt er gegen Lynch? 2. Ist die Umlenkung optional? Darf auf Wölfe umgelenkt werden? Gelten Schutz/Der Weise für das Umlenkziel? 3. Gibt es einen gemeinsamen Vorrat "Stimme der Toten" für Schild und Umlenkung? 4. Wie oft darf der Nekromant einen Wolf benennen (pro Tag, pro Spiel), und hat ein Fehlversuch Folgen? Ist die Benennung öffentlich? 5. Zählt ein verfluchter Nicht-Wolf (`cursedWolfAura`) als korrekt benannter Werwolf? 6. Bleibt die Übungs-Enthüllung als Regel erhalten?
- **Blockiert Charge:** K15. **Blockiert Version 1.0:** Nein.

## RM-DR-143 · `kartenschlucker`

- **Betroffene Rollen:** `kartenschlucker`; Wechselwirkung laut Dossier: alle Rollen, die Tote erzeugen (mehr Tote = mehr Tauschgelegenheiten), Totenkarten-System (`cards`), Frankenstein/Kutscher (Wiederbelebung ermöglicht erneuten Tausch), Nekromant/Hades/Parasit/Rudelvater (Abfangregeln in …
- **Problem:** Offen sind: Zusatzkräfte Kill/Schild/Ansage; Wer darf tauschen. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/solos-b.md#kartenschlucker); RM-C-071, RM-C-072 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-005, RM-DR-007, RM-DR-013.
- **Teilfrage 1: Zusatzkräfte Kill/Schild/Ansage**
  - Option A: reine Sammelrolle (Text)
  - Option B: Sammelrolle mit Eskalationsstufen (Code)
  - Auswirkung: Balance: Code macht die Rolle ab 2 Stapeln zum Nachtmörder mit Schneeballeffekt (mehr Tote, mehr Tauschmöglichkeiten); Umsetzung: Code-Variante braucht Kill, Schild, Ansage zusätzlich
  - Empfehlung: PO entscheidet; bei Beibehaltung Text ergänzen
- **Teilfrage 2: Wer darf tauschen**
  - Option A: jeder Tote frei
  - Option B: nur Nicht-Wölfe oder nur einmal pro Person
  - Auswirkung: Balance: Wölfe können Solo-Sieg beschleunigen oder bewusst verhindern; Umsetzung: Regel im Totenkarten-Assistenten
  - Empfehlung: Text präzisieren
- **Weitere offene Fragen (Dossier):** 1. Bleiben Kill ab 2, Schild ab 5 und Ansage alle 3 Nächte erhalten? Kostet der Kill Stapel? 2. Darf jeder Tote (auch Wölfe) tauschen, und wie oft pro Person? 3. Ist der Schild passiv (ab 5 Stapeln immer) oder an den Nachtschritt gekoppelt? 4. Ist die Stapelzahl öffentlich (Ansage) oder geheim? 5. Gewinnt ein toter Kartenschlucker, wenn nach seinem Tod 10 Stapel erreicht würden (heute: keine Stapel nach Tod)?
- **Blockiert Charge:** K15. **Blockiert Version 1.0:** Nein.

## RM-DR-144 · `hades`

- **Betroffene Rollen:** `hades`; Wechselwirkung laut Dossier: jede tötende Rolle (Lichterquelle), Nekromant (Schild fängt Hades-Kill ab, Lichter trotzdem weg), Rudelvater (`PACKFATHER_KILL` durchbricht Barriere), Ritter (Vergeltung bei `HADES_KILL`, `core:431`), …
- **Problem:** Offen sind: Sieg automatisch oder eingelöst; Zählen eigene Kills; Stimme x3. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/solos-b.md#hades); RM-C-073, RM-C-074, RM-C-075 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-005, RM-DR-007, RM-DR-008.
- **Teilfrage 1: Sieg automatisch oder eingelöst**
  - Option A: Sieg sofort bei 10
  - Option B: Sieg nur durch bewusstes Einlösen (Lichter könnten vorher ausgegeben werden)
  - Auswirkung: Balance: Einlösen erlaubt Taktik (Lichter sparen/ausgeben); Umsetzung: eine Siegregel als WinCandidate
  - Empfehlung: Automatik bei 10 mit SL-Bestätigung, Button streichen
- **Teilfrage 2: Zählen eigene Kills**
  - Option A: jeder Tod zählt
  - Option B: nur Tode durch andere
  - Auswirkung: Balance: Kill kostet netto 1 statt 2; Umsetzung: Filter nach Quelle
  - Empfehlung: PO
- **Teilfrage 3: Stimme x3**
  - Option A: Kauf bleibt, SL wird erinnert
  - Option B: Kauf streichen
  - Auswirkung: Balance: Kauf ohne Anzeige ist wertlos; Umsetzung: dauerhafter Statusmarker mit Hinweis beim Tag
  - Empfehlung: Marker sichtbar machen
- **Weitere offene Fragen (Dossier):** 1. Sieg automatisch bei 10 oder nur durch Einlösen? 2. Geben eigene Hades-Kills Lichter? 3. Stimme x3 behalten (als SL-Hinweis) oder streichen? Ist der Kauf öffentlich? 4. Werden Lichter bei abgefangenem Kill erstattet? 5. Soll der Rollentext Preise und Fähigkeiten nennen?
- **Blockiert Charge:** K15. **Blockiert Version 1.0:** Nein.

## RM-DR-145 · `doktor`

- **Betroffene Rollen:** `doktor`; Wechselwirkung laut Dossier: Wolfskind, Lehrling, Seelentauscher, Dämonischer Wolf, alle Solo-Rollen, Doppelspion, Trugbilderwolf (Erscheinung vs. Fraktion), Rotkäppchen …
- **Problem:** Offen sind: Zwei Solo-Rollen; Verwandlung / Fluch. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-3.md#doktor); RM-C-151, RM-C-152 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002.
- **Teilfrage 1: Zwei Solo-Rollen**
  - Option A: Solos bilden kein Team (immer "verschieden", auch mit sich selbst)
  - Option B: "Solo" ist ein Team
  - Auswirkung: Balance: A verhindert Fehlschluss; Umsetzung: Vergleich über Siegpartei statt Fraktionskonstante
  - Empfehlung: A
- **Teilfrage 2: Verwandlung / Fluch**
  - Option A: aktuelle Fraktion
  - Option B: Katalogfraktion (Legacy)
  - Auswirkung: Balance: A macht den Doktor zum Verwandlungs-Detektor; Umsetzung: `faction` am Player (RoleTransition) statt Katalog
  - Empfehlung: A (Godot hat `faction` am Player)
- **Weitere offene Fragen (Dossier):** 1. Sind zwei Solo-Spieler "im selben Team"? 2. Zählt die aktuelle Fraktion (nach Verwandlung/Erbe) oder die Startrolle? 3. Zählt ein Trugbilderwolf mit seiner Scheinrolle oder als Wolf? 4. Darf der Doktor sich selbst testen?
- **Blockiert Charge:** K2. **Blockiert Version 1.0:** Ja.

## RM-DR-146 · `faehrtenleser`

- **Betroffene Rollen:** `faehrtenleser`; Wechselwirkung laut Dossier: alle Wolfsrollen, Fenrir, Dämonischer Wolf (Verfluchte), Wolfskind/Lehrling (Verwandlung), Doppelspion, Ritter (gemeinsame Richtungsdefinition), …
- **Problem:** Offen sind: Richtungsdefinition; Gleichstand; Fenrir Stufe 3. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-3.md#faehrtenleser); RM-C-154, RM-C-155, RM-C-156 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-003, RM-DR-014.
- **Teilfrage 1: Richtungsdefinition**
  - Option A: aus Sicht des Spielers am Tisch
  - Option B: aus Sicht des SL-Bildschirms
  - Auswirkung: Balance: Fehlinfo bei falscher Deutung; Umsetzung: Richtung relativ zu `seat_order` (Uhrzeigersinn) festlegen
  - Empfehlung: am Tisch prüfen und festschreiben
- **Teilfrage 2: Gleichstand**
  - Option A: fest links
  - Option B: beide Richtungen nennen / SL wählt
  - Auswirkung: Balance: gering; Umsetzung: Regel im Rechner
  - Empfehlung: entscheiden
- **Teilfrage 3: Fenrir Stufe 3**
  - Option A: gleiche Wolfsdefinition wie Ritter
  - Option B: unterschiedlich
  - Auswirkung: Balance: gering; Umsetzung: eine gemeinsame Zielfunktion
  - Empfehlung: angleichen
- **Weitere offene Fragen (Dossier):** 1. "Links" aus Sicht des Spielers oder des SL-Bildschirms, und entspricht der Uhrzeigersinn der App dem Tisch? 2. Gleichstand: fest eine Richtung oder beide nennen? 3. Zählen tote Sitze im Abstand mit (Legacy: ja)? 4. Wolfsdefinition: verfluchte Dorfbewohner, Fenrir Stufe 3? 5. Einsatz pro Person (frisch bei Erbe) oder pro Rolle?
- **Blockiert Charge:** K3. **Blockiert Version 1.0:** Nein.

## RM-DR-147 · `waldlaeufer`

- **Betroffene Rollen:** `waldlaeufer`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf, Wolfskind/Lehrling, Siegreicher Wolf (Zählweise), Doppelspion, Waldhexe/Hades (sofortige Nachttode vor dem …
- **Problem:** Offen sind: Häufigkeit; Verfluchte zählen. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/village-3.md#waldlaeufer); RM-C-157, RM-C-158 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002.
- **Teilfrage 1: Häufigkeit**
  - Option A: jede Nacht
  - Option B: einmal (z. B. Nacht 1)
  - Auswirkung: Balance: jede Nacht ist stark in Akt IV; Umsetzung: Schritt jede Nacht vs. Einmal-Einsatz
  - Empfehlung: entscheiden und in Text aufnehmen
- **Teilfrage 2: Verfluchte zählen**
  - Option A: nur `counts_as_wolf`
  - Option B: auch Erscheinung
  - Auswirkung: Balance: hängt an Q1; Umsetzung: Zählung über `counts_as_wolf`
  - Empfehlung: nach Q1
- **Weitere offene Fragen (Dossier):** 1. Jede Nacht oder einmal? 2. Zählen Verfluchte und verwandelte Sitze? 3. Zählt der Siegreiche Wolf einfach (Legacy) oder doppelt? 4. Zählen Nachtopfer, die erst am Morgen sterben, noch als lebend (Legacy: ja)?
- **Blockiert Charge:** K2. **Blockiert Version 1.0:** Ja.

## RM-DR-148 · `schutzgeist`

- **Betroffene Rollen:** `schutzgeist`; Wechselwirkung laut Dossier: Werwolf/Rudel (Angriff), Rachsüchtiger Wolf (Zusatzangriff), Seuchenwolf (Durchbohren ignoriert Schutz beim Pick, chunk:162) und Rudelvater (Zusatzopfer am Morgen ohne Schutzprüfung, night:269-280), Dämonischer Wolf …
- **Problem:** Offen sind: Dauer/Wirkung des Schilds; Schutzart; Zeitpunkt; Wolf-Meldung. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/village-4.md#schutzgeist); RM-C-159, RM-C-160, RM-C-161, RM-C-162 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-004, RM-DR-009.
- **Teilfrage 1: Dauer/Wirkung des Schilds**
  - Option A: Schild hält bis zum nächsten Wolfsangriff (auch spätere Nächte)
  - Option B: Schild gilt nur für die aktuelle Nacht, Schritt muss dann vor dem Rudel liegen
  - Auswirkung: Balance: A stärker, B ohne Umordnung wirkungslos; Umsetzung: A: dauerhafter Marker; B: Schrittposition vor Rudel
  - Empfehlung: A (deckt Alttext, macht Rolle spielbar)
- **Teilfrage 2: Schutzart**
  - Option A: nur Wolfsangriff
  - Option B: jeder Tod
  - Auswirkung: Balance: A schwächer; Umsetzung: A nutzt vorhandene Protections
  - Empfehlung: A
- **Teilfrage 3: Zeitpunkt**
  - Option A: frühestens nächste Nacht
  - Option B: sobald tot, auch dieselbe Nacht
  - Auswirkung: Balance: gering; Umsetzung: Schrittfreigabe mit Nachtindex
  - Empfehlung: A (Textwortlaut)
- **Teilfrage 4: Wolf-Meldung**
  - Option A: nur Tatsache, ohne Namen, echte Fraktion
  - Option B: mit Namen / nach Erscheinung (`appears_as`)
  - Auswirkung: Balance: Name wäre starke Info; Umsetzung: InfoRecord public, Quelle Wahrheit oder Erscheinung
  - Empfehlung: A ohne Namen, Wahrheit
- **Weitere offene Fragen (Dossier):** (1) Hält das Schild bis zum nächsten Wolfsangriff oder nur für eine Nacht? (2) Nur gegen Wolfsangriff oder gegen jeden Tod? (3) Darf sie in derselben Nacht handeln, in der sie stirbt? (4) Wird der gewählte Wolf mit Namen oder nur die Tatsache verkündet, und zählt die wahre Fraktion oder die Erscheinung (verfluchter Dorfbewohner)? (5) Nach Wiederbelebung und erneutem Tod erneut nutzbar?
- **Blockiert Charge:** K5. **Blockiert Version 1.0:** Nein.

## RM-DR-149 · `waechter-am-tor`

- **Betroffene Rollen:** `waechter-am-tor`; Wechselwirkung laut Dossier: Wolfskind, Lehrling, König Lykaon/Trugbilderwolf, Seelentauscher, Dr. Victor Frankenstein, Kutscher, Dämonischer Wolf (Regelfrage), Grabräuber …
- **Problem:** Offen sind: Gilt der Dämonische-Wolf-Fluch als "neu entstehender Werwolf"?. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/village-4.md#waechter-am-tor); RM-C-163 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002.
- **Teilfrage 1: Gilt der Dämonische-Wolf-Fluch als "neu entstehender Werwolf"?**
  - Option A: Fluch ist nur Erscheinung, Wächter irrelevant
  - Option B: Fluch erzeugt echten Wolf, Wächter muss abfangen
  - Auswirkung: Balance: bei B stärker für Dorf; Umsetzung: A: appears_as; B: zusätzlicher Abfangpunkt
  - Empfehlung: A (folgt 07-Vorschlag "nur Erscheinung")
- **Weitere offene Fragen (Dossier):** (1) Gilt der Dämonische-Wolf-Fluch als neuer Werwolf? (2) Erhält der umgewandelte Spieler öffentlich/privat eine Mitteilung? (3) Soll Lykaon bei Abfang seine Fähigkeit verbrauchen? (4) Soll die Rolle in Akt IV bleiben, obwohl dort keine Wolfsquelle existiert?
- **Blockiert Charge:** K12. **Blockiert Version 1.0:** Nein.

## RM-DR-150 · `zeitwaechter`

- **Betroffene Rollen:** `zeitwaechter`; Wechselwirkung laut Dossier: praktisch alle Nachtrollen; besonders Schwarze Witwe, Giftwolf, Märtyrerin, Voodoo-Priester, Rudelvater, Seuchenwolf, Waldhexe, Hades, Amalia, Kriegerin, Dorfschmied, Der Weise, Fenrir, Cerberus, Todesprediger, …
- **Problem:** Offen sind: Umfang des Abbruchs; Zeitpunkt der Entscheidung; Zähler; Wolfsrollen. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-4.md#zeitwaechter); RM-C-164, RM-C-165, RM-C-166, RM-C-167 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-010.
- **Teilfrage 1: Umfang des Abbruchs**
  - Option A: Gesamte Nacht wird zurückgerollt (Tode und Zustände)
  - Option B: Nur Tode dieser Nacht entfallen, Zustände bleiben
  - Auswirkung: Balance: A sehr stark, B stark; Umsetzung: A: Nacht-Transaktion mit Schnappschuss ab Nachtbeginn; B: alle Tode der Nacht aufschieben bis Morgen
  - Empfehlung: A mit Schnappschuss bei Nachtbeginn (RoleTransition-Schnappschuss-Idee) oder B nach 07
- **Teilfrage 2: Zeitpunkt der Entscheidung**
  - Option A: Entscheidung am Nachtanfang, dann läuft keine Aktion
  - Option B: Entscheidung am Nachtende, alles wird zurückgenommen
  - Auswirkung: Balance: A spart Zeit, B gibt Zeitwächter Zusatzwissen (sieht keine Nachtergebnisse, aber SL weiß sie); Umsetzung: A: Schritt vor tier 0.1; B: Rücknahme nötig
  - Empfehlung: A (einfacher, fairer)
- **Teilfrage 3: Zähler**
  - Option A: alle nachtabhängigen Zähler zurück
  - Option B: nur Nachtnummer
  - Auswirkung: Balance: Todesprediger, Schmied, Fenrir betroffen; Umsetzung: Zähler-Liste in Nacht-Transaktion
  - Empfehlung: A
- **Teilfrage 4: Wolfsrollen**
  - Option A: auch Wölfe
  - Option B: nur Nicht-Wölfe
  - Auswirkung: Balance: gering; Umsetzung: Blockadegrund pro Schritt
  - Empfehlung: A
- **Weitere offene Fragen (Dossier):** (1) Entscheidung am Nachtanfang oder -ende? (2) Werden nur Tode oder alle Zustände zurückgenommen? (3) Zählen Zähler (Nachtnummer, Schmied, Fenrir, Todesprediger) die Nacht? (4) Gilt der Abbruch auch für Wölfe und Solo-Rollen? (5) Öffentliche Ankündigung am Morgen?
- **Blockiert Charge:** K16. **Blockiert Version 1.0:** Nein.

## RM-DR-151 · `amalia`

- **Betroffene Rollen:** `amalia`; Wechselwirkung laut Dossier: alle Wolfsrollen (Schwelle), Dämonischer Wolf (Verfluchte zählen im Code mit), Doppelspion (zählt nicht), Nekromant (Globalschild verhindert Opfer), Zeitwächter (Opfer bleibt trotz …
- **Problem:** Offen sind: Zeitpunkt; Frage und Antwort; Schwelle. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-4.md#amalia); RM-C-168, RM-C-169, RM-C-170 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002.
- **Teilfrage 1: Zeitpunkt**
  - Option A: Tagesaktion (öffentlich, alle wach)
  - Option B: Nachtschritt, Frage wird am Morgen verkündet
  - Auswirkung: Balance: A: Frage wirkt sofort in Diskussion; Umsetzung: A: Tagesaktionswarteschlange; B: verzögertes Ereignis
  - Empfehlung: A
- **Teilfrage 2: Frage und Antwort**
  - Option A: SL beantwortet wahrheitsgemäß, App protokolliert Frage und Antwort
  - Option B: Frage rein mündlich, App nur Opfer
  - Auswirkung: Balance: A: nachvollziehbar; Umsetzung: A: PendingPrompt mit Freitext + Ja/Nein; InfoRecord
  - Empfehlung: A
- **Teilfrage 3: Schwelle**
  - Option A: >2 lebende echte Wölfe
  - Option B: >=2 (Alttext) oder inkl. toter ("im Spiel")
  - Auswirkung: Balance: Verfügbarkeit; Umsetzung: Zählung über Fraktion, ohne Erscheinung
  - Empfehlung: >2 lebende echte Wölfe
- **Weitere offene Fragen (Dossier):** (1) Tag oder Nacht? (2) Beantwortet der SL wahrheitsgemäß, und wird die Antwort in der App festgehalten? (3) Schwelle ">2" oder "2+", lebend oder "im Spiel"? (4) Zählen verfluchte Sitze als Werwölfe?
- **Blockiert Charge:** K14. **Blockiert Version 1.0:** Nein.

## RM-DR-152 · `kriegerin-des-lichts`

- **Betroffene Rollen:** `kriegerin-des-lichts`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (verfluchter Sitz: Wolf oder nicht?), Trugbilderwolf/Erscheinungsrollen, Doppelspion, Rudelvater (erste Sonderfähigkeitstötung überlebt, falls Treffer tötet), …
- **Problem:** Offen sind: Stirbt ein getroffener Wolf?; Wahrheitsquelle; Öffentlichkeit. Legacy-Befund `legacy-contradictory`.
- **Belege:** [Dossier](dossiers/village-4.md#kriegerin-des-lichts); RM-C-171, RM-C-172, RM-C-173 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-014.
- **Teilfrage 1: Stirbt ein getroffener Wolf?**
  - Option A: Angriff tötet den Wolf
  - Option B: Angriff ist nur Test, Wolf wird nur erkannt
  - Auswirkung: Balance: A sehr stark (sicherer Wolfskill mit Risiko); Umsetzung: A: KillPipeline-Ursache, Reaktionen
  - Empfehlung: Entscheidung nötig; 04 korrigieren
- **Teilfrage 2: Wahrheitsquelle**
  - Option A: App prüft Fraktion automatisch
  - Option B: SL entscheidet (kann Erscheinung berücksichtigen)
  - Auswirkung: Balance: A verhindert SL-Fehler; Umsetzung: A: Fraktion oder appears_as
  - Empfehlung: A mit Wahrheit, appears_as nur falls gewünscht
- **Teilfrage 3: Öffentlichkeit**
  - Option A: geheim an Kriegerin
  - Option B: öffentlich
  - Auswirkung: Balance: B starke Dorfinfo; Umsetzung: Sichtbarkeit actor vs public
  - Empfehlung: nach PO
- **Weitere offene Fragen (Dossier):** (1) Stirbt ein getroffener Wolf? (2) Prüft die App die Fraktion automatisch, und nach Wahrheit oder Erscheinung? (3) Ist das Ergebnis öffentlich? (4) Darf sie sich selbst wählen (Code: ja)?
- **Blockiert Charge:** K7. **Blockiert Version 1.0:** Nein.

## RM-DR-153 · `detektiv`

- **Betroffene Rollen:** `detektiv`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (Verfluchte lösen aus), Wolfskind/Lehrling (verwandelte Wölfe), Doppelspion (ausgenommen), Dorfschmied (Wolfstod durch Waffe), Fährtenleser …
- **Problem:** Offen sind: Muss der Detektiv leben?; Mindestens 2 lebende Wölfe; Hinweisinhalt; Richtung links/rechts. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/village-4.md#detektiv); RM-C-174, RM-C-175, RM-C-176, RM-C-177 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-003, RM-DR-009, RM-DR-015.
- **Teilfrage 1: Muss der Detektiv leben?**
  - Option A: nur lebend
  - Option B: auch tot
  - Auswirkung: Balance: B stärker; Umsetzung: Bedingung am Hook
  - Empfehlung: A (Code)
- **Teilfrage 2: Mindestens 2 lebende Wölfe**
  - Option A: ≥1 anderer lebender Wolf genügt
  - Option B: ≥2 (Code)
  - Auswirkung: Balance: bei A Hinweis auf letzten Wolf, sehr stark; Umsetzung: Schwelle
  - Empfehlung: nach PO
- **Teilfrage 3: Hinweisinhalt**
  - Option A: Hinweis bezieht sich auf den toten Wolf (Sitz des Toten als Anker)
  - Option B: Hinweis enttarnt Wolf w indirekt (Code)
  - Auswirkung: Balance: B deutlich stärker, A moderat; Umsetzung: Anker und Richtungsregel
  - Empfehlung: A, und Parität nur wenn wahr
- **Teilfrage 4: Richtung links/rechts**
  - Option A: einheitlich id-1
  - Option B: einheitlich id+1
  - Auswirkung: Balance: keine; Umsetzung: Sitznachbarschaft mit einer Konvention
  - Empfehlung: eine Konvention für alle Rollen
- **Weitere offene Fragen (Dossier):** (1) Muss der Detektiv leben? (2) Reicht ein verbleibender anderer Wolf? (3) Ist der Anker der tote Wolf oder ein zufälliger lebender Wolf (der dadurch enttarnt wird)? (4) Welche Hinweisarten gibt es, und müssen sie wahr sein? (5) Welche Richtung ist "links"? (6) Überspringen Nachbarn tote Sitze? (7) Lösen verfluchte Dorfbewohner aus?
- **Blockiert Charge:** K3. **Blockiert Version 1.0:** Nein.

## RM-DR-154 · `dorfschmied`

- **Betroffene Rollen:** `dorfschmied`; Wechselwirkung laut Dossier: Werwolf/Rudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater, Seuchenwolf, Schutzengel, Der Weise, Nekromant, Rudelvater (Erstrettung), Dämonischer Wolf, Detektiv (Hinweis bei Waffentod), Zeitwächter, Verdammniswächter …
- **Problem:** Offen sind: Welche Nächte zählen; Nur Nacht 6 oder ab Nacht 6; Welche Angriffe. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/village-4.md#dorfschmied); RM-C-178, RM-C-179, RM-C-180 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-004, RM-DR-005, RM-DR-015.
- **Teilfrage 1: Welche Nächte zählen**
  - Option A: globale Nachtnummer 6
  - Option B: eigene Schmiedenächte
  - Auswirkung: Balance: gering; Umsetzung: Zähler vs. Nachtnummer
  - Empfehlung: A (einfach, eindeutig)
- **Teilfrage 2: Nur Nacht 6 oder ab Nacht 6**
  - Option A: nur Nacht 6
  - Option B: ab Nacht 6
  - Auswirkung: Balance: A strenger; Umsetzung: Schrittfreigabe
  - Empfehlung: B (Code)
- **Teilfrage 3: Welche Angriffe**
  - Option A: alle Wolfsangriffe inkl. durchbohrend
  - Option B: durchbohrende ausgenommen
  - Auswirkung: Balance: gering; Umsetzung: Filter `is_wolf_attack`
  - Empfehlung: A (Code)
- **Weitere offene Fragen (Dossier):** (1) Globale Nachtnummer oder eigene Schmiedenächte? (2) Nur Nacht 6 oder ab Nacht 6? (3) Darf der Schmied sich selbst oder einen Wolf ausrüsten? (4) Schützt die Waffe auch vor durchbohrenden Angriffen und vor Sofort-Toden durch Wolfsrollen? (5) Wird das Waffenopfer öffentlich verkündet? (6) Kann der Waffenträger selbst das Zufallsopfer sein, wenn er Wolf ist?
- **Blockiert Charge:** K5. **Blockiert Version 1.0:** Nein.

## RM-DR-155 · `doppelspion`

- **Betroffene Rollen:** `doppelspion`; Wechselwirkung laut Dossier: Rachsüchtiger Wolf, Dämonischer Wolf (Fluch wirkungslos), Wolfskind/Lehrling (Wolfszählung), Orakel/Doktor/Spürhund (Erscheinung/Fraktion), Die Ewigen, …
- **Problem:** Offen sind: Muss er leben?; Parität; Verhältnis zum Dorfsieg. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/solos-a.md#doppelspion); RM-C-063, RM-C-064 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-002, RM-DR-007.
- **Teilfrage 1: Muss er leben?**
  - Option A: nur lebend (Code)
  - Option B: auch tot
  - Auswirkung: Balance: B macht ihn stärker; Umsetzung: WinCandidate
  - Empfehlung: A, Text präzisieren
- **Teilfrage 2: Parität**
  - Option A: Nicht-Wolf
  - Option B: neutral (zählt für keine Seite)
  - Auswirkung: Balance: A lässt Wölfe schwerer gewinnen; Umsetzung: `counts_as_wolf=false`
  - Empfehlung: A
- **Teilfrage 3: Verhältnis zum Dorfsieg**
  - Option A: Sein Kandidat ersetzt den Dorfkandidaten, wenn kein Wolf lebt und er lebt (Legacy `core:227-230`, `triggerWin("Doppelspion")` statt Dorf)
  - Option B: Dorf- und Doppelspion-Kandidat entstehen gemeinsam; der Spielleiter wählt (DR-02)
  - Auswirkung: Balance: A macht ihn zum echten Gegenspieler des Dorfs; B lässt den Spielleiter entscheiden; Umsetzung: A: `WinRules` unterdrückt den Dorfkandidaten; B: nur ein weiterer Kandidat
  - Empfehlung: A, weil der Text „gewinnt alleine“ sagt
- **Weitere offene Fragen (Dossier):** (1) Muss er für den Sieg leben? (2) Zählt er in der Parität als Nicht-Wolf? (3) Erscheint er dem Orakel als Wolf oder Doppelspion? (4) Darf das normale Rudel ihn angreifen? (5) Gewinnt das Dorf mit, wenn er gewinnt?
- **Blockiert Charge:** K1. **Blockiert Version 1.0:** Ja.

## RM-DR-156 · `grabraeuber`

- **Betroffene Rollen:** `grabraeuber`; Wechselwirkung laut Dossier: potenziell jede Rolle mit Nachtfähigkeit (Ziel des Diebstahls); Einmalrollen (bereits verbraucht?); Totenkarte `solo_05` (ähnliche …
- **Problem:** Offen sind: Was bedeutet "Fähigkeit stehlen"; Siegbedingung. Legacy-Befund `not-found`.
- **Belege:** [Dossier](dossiers/solos-b.md#grabraeuber); RM-C-076, RM-C-077 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-006, RM-DR-007, RM-DR-014.
- **Teilfrage 1: Was bedeutet "Fähigkeit stehlen"**
  - Option A: Grabräuber erhält dauerhaft die Nachtfähigkeit der toten Rolle (inkl. Nachtschritt)
  - Option B: einmalige Nutzung der Fähigkeit
  - Auswirkung: Balance: groß: je nach Zielrolle (z.B. Waldhexe, Hades) stark unterschiedlich; Umsetzung: Fähigkeitsübertragung ist ein neues System; Rollenwechsel (RoleTransition) passt nicht, da Rolle/Fraktion bleiben sollen
  - Empfehlung: PO; bis dahin manuell
- **Teilfrage 2: Siegbedingung**
  - Option A: erbt die Siegbedingung der bestohlenen Rolle
  - Option B: eigene Bedingung (z.B. letzter Überlebender)
  - Auswirkung: Balance: ohne Bedingung ist die Rolle nicht gewinnbar; Umsetzung: zusätzliche Siegbedingung
  - Empfehlung: PO legt fest (Q4)
- **Weitere offene Fragen (Dossier):** 1. Dauerhafte oder einmalige Nutzung der gestohlenen Fähigkeit? 2. Welche Rollen sind stehlbar (auch Wolfs- und Solofähigkeiten, passive Fähigkeiten, Siegbedingungen)? 3. Welche Siegbedingung hat der Grabräuber? 4. Übernimmt der Grabräuber Zähler/Zustände der toten Rolle (z.B. Hades-Lichter, verbrauchte Tränke)?
- **Blockiert Charge:** K15. **Blockiert Version 1.0:** Nein.

## RM-DR-157 · `parasit`

- **Betroffene Rollen:** `parasit`; Wechselwirkung laut Dossier: jede tötende Rolle (Immunität), Rudelvater (`PACKFATHER_KILL` durchbricht Immunität NICHT, da Parasit-Prüfung zuerst), Nekromant-Schild (kann den Kettentod abfangen), Manipulator (gleichzeitiger Final-3-Sieg), Henker …
- **Problem:** Offen sind: "Final 3" und Siegvorrang. Legacy-Befund `legacy-verified`.
- **Belege:** [Dossier](dossiers/solos-b.md#parasit); RM-C-078 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-007, RM-DR-009, RM-DR-011.
- **Teilfrage 1: "Final 3" und Siegvorrang**
  - Option A: Parasit gewinnt bei <=3 Lebenden immer (ggf. gemeinsam mit anderen)
  - Option B: wie Code, Team-Siege zuerst
  - Auswirkung: Balance: Code: Parasit + 2 Dorf ohne Wölfe => Dorfsieg; Parasit + 2 Wölfe => Wolfssieg; Umsetzung: Siegpriorität in WinRules (Q4)
  - Empfehlung: PO mit Q4
- **Weitere offene Fragen (Dossier):** 1. Gewinnt der Parasit bei 3 oder weniger Lebenden? Allein oder zusätzlich zu Dorf/Wölfen? 2. Ist der Parasit auch gegen Hinrichtung immun, und wie wird das am Tisch kommuniziert? 3. Dürfen mehrere Parasiten verschiedene Wirte haben? 4. Darf ein Wolf Wirt sein?
- **Blockiert Charge:** K10. **Blockiert Version 1.0:** Nein (Ja bei Option C).

## RM-DR-158 · `todesprediger`

- **Betroffene Rollen:** `todesprediger`; Wechselwirkung laut Dossier: alle tötenden Rollen; Zeitwächter (Frost, Nachtzählung), Lynch/Hinrichtung, Parasit-ähnliche Immunitäten und Schilde (verschieben Todeszeitpunkt), Frankenstein/Kutscher (Wiederbelebung und erneuter …
- **Problem:** Offen sind: Öffentlich oder geheim; Zeitpunkt der Vorhersage; Zählbasis Tag/Nacht. Legacy-Befund `legacy-broken`.
- **Belege:** [Dossier](dossiers/solos-b.md#todesprediger); RM-C-079, RM-C-080, RM-C-081 in [`04`](04-rule-conflicts.md).
- **Vorab zu entscheiden (Querschnitt):** RM-DR-007, RM-DR-011, RM-DR-014.
- **Teilfrage 1: Öffentlich oder geheim**
  - Option A: öffentliche Ankündigung
  - Option B: geheime Vorhersage beim SL
  - Auswirkung: Balance: öffentlich: Dorf/Wölfe können gezielt töten oder schonen; Umsetzung: Ereignis-Sichtbarkeit public vs gm
  - Empfehlung: PO
- **Teilfrage 2: Zeitpunkt der Vorhersage**
  - Option A: nur Nacht 1
  - Option B: jederzeit einmal
  - Auswirkung: Balance: spätes Vorhersagen ist deutlich leichter; Umsetzung: Schritt nur Nacht 1 oder dauerhaft
  - Empfehlung: Nacht 1 (sonst trivial)
- **Teilfrage 3: Zählbasis Tag/Nacht**
  - Option A: Tag N = Tag nach Nacht N, Morgentode zählen zur Nacht
  - Option B: Tag N wie im Protokoll angezeigt (= nach Nacht N-1)
  - Auswirkung: Balance: Überschneidung verdoppelt Trefferchance bei Morgentoden; Umsetzung: eindeutige `night_number`/`day_number` und Zuordnung jedes Todes zu genau einer Phase
  - Empfehlung: Tode der Morgenauflösung zählen zur Nacht; Anzeige und Vergleich dieselbe Zahl
- **Weitere offene Fragen (Dossier):** 1. Wird die Vorhersage öffentlich angekündigt oder geheim beim SL abgegeben? 2. Wann darf vorhergesagt werden (nur Nacht 1, jederzeit einmal)? Sind vergangene/aktuelle Zeitpunkte zulässig? 3. Wie sind "Tag N" und "Nacht N" definiert, und zu welcher Phase gehören Tode der Morgenauflösung? 4. Zählt ein Tod durch SL-Korrektur oder durch Totenkarten-Effekt? 5. Was passiert bei Wiederbelebung und erneutem Tod (neue Vorhersage)?
- **Blockiert Charge:** K15. **Blockiert Version 1.0:** Nein.
