# 08 · Entscheidungsanfrage Rollenmigration

**Stand:** Analyse 2026-09-26 (Basis `4673b0b`), **konsolidiert 2026-09-27** gegen `origin/main` `5eb5f2a`. Zwischen beiden Commits haben sich Regelkern (`godot/core/`), Regeltests (`godot/tests/unit/`), Spezifikationen (`docs/specs/`) und die Regelabschnitte des `DECISION-LOG.md` nicht geändert; neu ist dort nur ein Eintrag zu Nachtmusik und Assetregister.

**Wichtig:** Nichts in diesem Dokument ist durch den Product Owner entschieden, außer wo ausdrücklich eine bestehende Quelle genannt ist. Empfehlungen sind Vorschläge. Bestehender Code allein gilt nicht als Freigabe.

**Kurzfassung für die nächste Runde:** [`10-next-decisions.md`](10-next-decisions.md). Dieses Dokument bleibt die vollständige Referenz.

## Status der Einträge (Konsolidierung)

Jeder Eintrag und jede Teilfrage hat genau einen Status. Die maschinenlesbare Zuordnung mit Quelle steht in [`decision-status.csv`](decision-status.csv) und wird von `tools/role-migration/check-role-docs.js` gegen dieses Dokument geprüft. IDs wurden nicht geändert; Teilfragen tragen jetzt Unter-IDs (`RM-DR-155.3`).

| Status | Bedeutung |
|---|---|
| **entschieden** | durch eine bestehende verbindliche Quelle beantwortet (Quelle genannt); kein Blocker mehr |
| **produktentscheidung** | echte neue Frage an den Product Owner |
| **technisch** | Umsetzung innerhalb bestehender Regeln; entscheidet die Spezifikation oder Implementierung |
| **später** | erst relevant, wenn eine bestimmte spätere Rolle umgesetzt wird |
| **quellenprüfung** | Quellen widersprechen sich oder sind ohne weitere Prüfung (z. B. am Gerät) nicht belastbar |

Ein Eintrag mit mehreren Teilfragen erhält den dringlichsten Status seiner Teilfragen (Reihenfolge: produktentscheidung, quellenprüfung, später, technisch, entschieden).

<!-- check:decision-status -->
| Status | Einträge | Fragen (Einträge ohne Teilfragen plus Teilfragen) |
|---|---:|---:|
| entschieden | 58 | 147 |
| produktentscheidung | 0 | 0 |
| technisch | 2 | 3 |
| später | 14 | 37 |
| quellenprüfung | 1 | 1 |
| **gesamt** | **75** | **188** |

Gegenüber der ersten Fassung (74 Einträge, 160 Teilfragen): neu sind RM-DR-017 (Umfang der nächsten Einheit), Unterteilungen von RM-DR-002, -009, -011, -015, -016 sowie die Teilfragen RM-DR-138.3 bis .5 und RM-DR-155.4 bis .5. Die frühere Aussage, K1 werde durch RM-DR-007 und RM-DR-016 blockiert, ist zurückgenommen: RM-DR-007 ist entschieden, RM-DR-016 ist für K1 nicht nötig.

### Durch bestehende Quellen bereits beantwortet

| Eintrag / Teilfrage | Antwort | Quelle |
|---|---|---|
| RM-DR-001 | Einsätze zählen je Person und Rolle; geerbte Rollen beginnen mit frischen Einsätzen; Wiederbelebung setzt nichts zurück | `rules-register.md` G-ID-3; DECISION-LOG Lehrling, Waldhexe, Spiegelwolf |
| RM-DR-002.1 | Informationsrollen mit Rollenergebnis: Erscheinung, sonst `werwolf` bei Wolfszählung, sonst Rolle | DR-07; DECISION-LOG „Orakel · Informationsmodell“ |
| RM-DR-002.2 | Siegprüfung zählt `counts_as_wolf`, nicht die Erscheinung | G-SIEG-1, G-SIEG-2, G-ID-2 |
| RM-DR-007 | alle gleichzeitig erfüllten Siegbedingungen bilden eine Kandidatenmenge ohne Priorität; Spielleiter bestätigt einen oder lehnt alle ab; Prüfung erst nach allen Reaktionen; niemand lebt → kein automatischer Sieger | G-SIEG-1 bis G-SIEG-6; DR-02; DR-14; DECISION-LOG „Manipulator und Kandidatenmenge“ |
| RM-DR-009.1 | Todesfolgen mit Entscheidung: persistente Reaktion, am Tag sofort, nachts in der Morgenauflösung | G-TOD-4; DR-09 |
| RM-DR-011.1 | eingereihte Reaktion bleibt nach Wiederbelebung; Tränke und Spiegelung werden nicht zurückgesetzt; kein zweites Erbe; totes Wolfskind verwandelt sich nicht | DECISION-LOG Randfälle, Waldhexe, Spiegelwolf, Lehrling, Wolfskind |
| RM-DR-015.1 | jede Zufallsentscheidung läuft über den gespeicherten Seed | G-RNG-1 |
| RM-DR-126.3, RM-DR-141.3 | Einmal-Fähigkeiten gelten je Person und Rolle | G-ID-3 |
| RM-DR-145.2 | „Team“ ist die aktuelle Siegfraktion der Person | G-ID-2; DR-10; DECISION-LOG Lehrling (Fraktion wechselt sofort) |
| RM-DR-155.2 | Einzelsiegrollen zählen in der Wolfsparität als Nicht-Wölfe | G-SIEG-2 |
| RM-DR-138.5 | Stirbt der Selbstmörder durch eine Spiegelung, ist das keine Hinrichtung des Selbstmörders (Ursache `SPIEGELWOLF_RETALIATE`, hingerichtet ist der Spiegelwolf) | G-TOD-3; DECISION-LOG Spiegelwolf |
| Teil von RM-DR-138.2 | eine Hinrichtung per Spielleiterkorrektur bleibt eine Hinrichtung (`LYNCH`) | DECISION-LOG Korrekturrunde Regelkern 4 |
| Teil von RM-DR-157.1 | keine feste Siegpriorität zwischen Einzelsieg und Fraktionen | DR-02 |
| Teil von RM-DR-008 | keine digitale Stimmabgabe, keine Stimmgewichte | `implementation-boundary.md` D |

### Benannte Widersprüche zwischen verbindlichen Quellen und Rollentexten

- `rules-register.md` G-PH-2 („nur lebende Rolleninhaber erhalten einen wirksamen Schritt“) widerspricht dem Text des Schutzgeists (handelt nach dem eigenen Tod). Bei Umsetzung von `schutzgeist` ausdrücklich als Ausnahme entscheiden (RM-DR-148.3).
- DR-08 legt die Scheinrolle eines Trugbilderwolfs „beim Spielaufbau“ fest; `koenig-lykaon` und die Totenkarte „Schicksalswende“ erzeugen Trugbilderwölfe während der Partie. Lücke, keine Kollision mit dem heutigen Kern (RM-DR-107.1).
- `docs/godot-migration/07-open-questions.md` Q4 schlägt „Solo vor Wölfen vor Dorf“ vor; DR-02 hat Option C (Spielleiter entscheidet) gewählt. Q4 ist in diesem Punkt überholt.

## 1. Querschnittsentscheidungen

## RM-DR-001 · Einsätze und Zustände pro Person

- **Status:** entschieden (G-ID-3; DECISION-LOG Lehrling, Waldhexe, Spiegelwolf). Kein Blocker.
- **Betroffene Rollen:** alle Rollen mit begrenztem Einsatz, Zähler oder Rollenzustand (u. a. `loki`, `giftwolf`, `rachsuechtiger-wolf`, `maertyrerin`, `kutscher`, `hades`, `dorfschmied`, `kriegerin-des-lichts`).
- **Problem:** Legacy speichert Verbrauch und Zustände global pro Rollenname. Mehrere Kopien teilen sich einen Einsatz, ein Erbe übernimmt fremde Stände.
- **Belege:** `js/core/night.js:3-5` (`markOnceUsed`), `js/ui/core.js:339-359` (`resetOnceForInheritedRole`), [`04`](04-rule-conflicts.md) §2 Zeile 1. Godot: `Player.ability_uses`, DR-11 „vollständig zurückgesetzte Nutzungen“, DECISION-LOG Waldhexe „pro Person und Partie“.
- **Option A:** Jeder Einsatz, Zähler und Rollenzustand gehört der Person und der Rolleninstanz. Rollenwechsel startet mit frischen Einsätzen der neuen Rolle (wie DR-11). Wiederbelebung setzt nichts zurück (wie Waldhexe).
- **Option B:** Einsätze pro Rolle in der Partie (Legacy). Mehrere Kopien teilen sich den Einsatz.
- **Auswirkung:** A passt zum vorhandenen Kern und macht mehrere Kopien und Erbe testbar. B erzwingt globale Zähler neben `ability_uses` und widerspricht DR-11.
- **Empfehlung:** A.
- **Relevant für Chargen:** K4 bis K16. **Relevant für Option B (nicht freigegeben):** Ja. Da entschieden, kein Blocker mehr.

## RM-DR-002 · Einheitliche Wolfsdefinition

- **Status:** RM-DR-002.1 entschieden (DR-07), RM-DR-002.2 entschieden (G-SIEG-1/2), RM-DR-002.3 (Zählungen und Wirkungen außerhalb des Orakel-Modells) später ab K2.
- **Betroffene Rollen:** 24, u. a. `waldlaeufer`, `doktor`, `ritter`, `kopfgeldjaeger`, `doppelspion`, `nachtwaechter`, `spuerhund`, `detektiv`, `dorfschmied`, `daemonischer-wolf`.
- **Problem:** Legacy nutzt drei verschiedene Wolfsbegriffe (`isWolf` mit Fluch, Rollenfraktion, `WOLF_ROLES_SET`). Dieselbe Person ist je nach Rolle Wolf oder nicht.
- **Belege:** `js/ui/core.js:8-19`; [`04`](04-rule-conflicts.md) §2; Godot `InformationRules.determine_role` und DR-07.
- **Option A:** Zwei Begriffe mit klarer Trennung: **Wirkungen** (Tötungsziele, Zählungen für Sieg, Ritter, Schmiedwaffe, Waldläufer-Zahl) nutzen `counts_as_wolf`. **Informationen, die einer Person gezeigt werden** (Orakel, Doktor, Detektiv-Hinweis, Kopfgeldjäger-Liste) nutzen eine zentrale Informationsregel, die `appears_as` berücksichtigt (Erweiterung von `InformationRules`).
- **Option B:** Überall nur `counts_as_wolf` (Wahrheit). Erscheinungen wirken nur beim Orakel.
- **Option C:** Überall die Erscheinung.
- **Auswirkung:** A erhält Fehlinformation als Spieleffekt (DECISION-LOG) und ist eindeutig testbar. B vereinfacht, macht aber Trugbilderwolf und Dämonen-Fluch fast wirkungslos. C lässt Täuschung Siegbedingungen verändern.
- **Empfehlung:** A. Welche Rolle zu welcher Gruppe gehört, steht in den Rollenentscheidungen.
- **Relevant für Chargen:** K2, K3, K5, K7 und später (für `doppelspion` beantwortet RM-DR-002.1 die Erscheinung). **Relevant für Option B (nicht freigegeben):** Ja.

## RM-DR-003 · Sitznachbarschaft und Richtung

- **Status:** später (K3). G-ID-1 legt nur die Trennung von Person und Sitz fest.
- **Betroffene Rollen:** `nachtwaechter`, `wahnsinniger-kutscher`, `ritter`, `faehrtenleser`, `detektiv`, `feuerteufel`, `pestbringerin`, `blutwolf`.
- **Problem:** Legacy hat zwei Nachbarbegriffe (direkter Sitz, nächster Lebender) und zwei entgegengesetzte „links“. Alle rechnen mit der Personen-ID als Sitzindex; Godot trennt `seat_order` von der ID und erlaubt Sitztausch.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 3; `godot/core/model/game_state.gd:22` (`seat_order` im Uhrzeigersinn).
- **Option A:** Eine Funktion `SeatNeighbors` über `seat_order`. Wirkungen auf Personen (Kutscher-Mitnahme, Brand, Seuche, Ritter-Ziel, Nachtwächter) treffen die **nächsten lebenden** Nachbarn; Zählungen über Tote (Blutwolf) nutzen die **direkten** Sitze. „Links“ ist die Richtung aus Sicht der Person, die zur Tischmitte schaut; die Zuordnung zur Bildschirmdarstellung wird am Gerät geprüft.
- **Option B:** Überall direkte Sitze, auch tote.
- **Option C:** Je Rolle wie Legacy.
- **Auswirkung:** A ist einheitlich und am Tisch erklärbar; B ist einfacher, aber tote Nachbarn schwächen Kutscher und Ritter; C übernimmt die Legacy-Widersprüche.
- **Empfehlung:** A. Die EN-Formulierung „living neighbours“ des Wahnsinnigen Kutschers und `07` Q1 stützen A.
- **Relevant für Chargen:** K3, K9, K14. **Relevant für Option B (nicht freigegeben):** Ja (`ritter`, `wahnsinniger-kutscher`).

## RM-DR-004 · Begriff „Wolfsangriff“

- **Status:** später (K4, K5, K11). DR-05 regelt nur den Schutzengel.
- **Betroffene Rollen:** 13, u. a. `dorfwache`, `der-weise`, `ritter`, `rudelvater`, `seuchenwolf`, `dorfschmied`, `schutzgeist`, `maertyrerin`, `besessener-wolf`.
- **Problem:** Viele Texte beziehen sich auf „Werwolfangriff“; Legacy unterscheidet Rudelkill, Zusatzopfer und Einzelkills von Wolfsrollen nicht.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 4; DR-05 legt für den Schutzengel bereits „nur Rudelangriff“ fest.
- **Option A:** „Wolfsangriff“ ist ausschließlich der Rudelangriff (`NIGHT_KILL`, Quelle Rudel) einschließlich weiterer Rudelopfer derselben Art (Rudelvater, Schicksalswolf). Einzelkills von Wolfsrollen (Rachsüchtiger Wolf, Giftwolf, Schwarze Witwe, Besessener Wolf) haben eigene Ursachen und sind keine Wolfsangriffe.
- **Option B:** Jeder Tod, dessen Quelle eine Wolfsrolle ist.
- **Auswirkung:** A setzt DR-05 konsequent fort und hält Schutzrollen einfach; B macht Schutzrollen stärker und verlangt für jede Wolfsrolle eine Einzelprüfung.
- **Empfehlung:** A, mit ausdrücklicher Ursachenliste je neuer Todesursache (Attribut `wolf_attack` im `KillEvent`).
- **Relevant für Chargen:** K4, K5, K6, K11. **Relevant für Option B (nicht freigegeben):** Ja (`dorfwache`, `ritter`, `besessener-wolf`).

## RM-DR-005 · Durchdringung von Schutz, Immunität und Schilden

- **Status:** später (K5, K11).
- **Betroffene Rollen:** `seuchenwolf`, `rudelvater`, `verdammniswaechter`, `schicksalswolf` (auslösend); `dorfwache`, `der-weise`, `dorfschmied`, `nekromant`, `hades`, `kartenschlucker` (betroffen).
- **Problem:** Zwei Legacy-Regeln „ignoriert Schutz“ durchdringen unterschiedliche Abfangstufen; der Text sagt jeweils „alle“.
- **Belege:** `js/ui/core.js:126-143`; [`04`](04-rule-conflicts.md) §2 Zeile 5.
- **Option A:** Ein Attribut `pierces` am Angriff mit einer festen Liste: durchdringt Schutzengel, Waldhexenrettung, Dorfwache-Immunität und die Rettung des Weisen; nicht die persönlichen Schilde der Einzelsiegrollen, nicht Umlenkungen (Schattenwanderer, Voodoo), nicht Ersatzopfer (Märtyrerin).
- **Option B:** `pierces` durchdringt jede Abfangstufe.
- **Auswirkung:** A hält Einzelsiegrollen spielbar; B macht Durchdringung sehr stark und einfach zu erklären.
- **Empfehlung:** A.
- **Relevant für Chargen:** K5, K11, K15. **Relevant für Option B (nicht freigegeben):** Nein.

## RM-DR-006 · Rollen ohne Siegcode oder ohne Siegtext

- **Status:** später (K9 bis K15); `07` Q4 bleibt offen.
- **Betroffene Rollen:** `prophet-des-untergangs`, `grabraeuber`, `die-ewigen` (Siegtext ohne Code); `feuerteufel`, `voodoo-priester`, `pestbringerin` (Einzelsiegfraktion ohne Siegtext; Pest hat Code); `rachsuechtiger-wolf` (Siegtext widerspricht Code).
- **Problem:** `07` Q4 ist offen; ohne Siegbedingung sind diese Rollen nicht vollständig automatisierbar.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 8; [`../godot-migration/07-open-questions.md`](../godot-migration/07-open-questions.md) Q4.
- **Option A:** Siegbedingungen jetzt je Rolle festlegen (in den Rollenentscheidungen).
- **Option B:** Bis zur Festlegung nur die vorhandene Spielleitererklärung `GmCorrection declare_winner`; Rolle gilt als `assisted`.
- **Option C:** Diese Rollen bleiben außerhalb von 1.0.
- **Auswirkung:** A vollständig, aber Regeldesign; B sofort spielbar; C reduziert Umfang. Keine der Rollen ist in den Optionen A bis C aus `05` enthalten.
- **Empfehlung:** C für 1.0, danach A je Charge.
- **Relevant für Chargen:** K9, K10, K11, K15. **Relevant für Option B (nicht freigegeben):** Nein.

## RM-DR-007 · Dorf- und Wolfssieg bei lebenden Einzelsiegrollen

- **Status:** entschieden. Die hier gestellte Grundfrage (Option A) ist bereits durch G-SIEG-1 bis G-SIEG-6, DR-02, DR-14 und den DECISION-LOG-Eintrag „Manipulator und Kandidatenmenge“ festgelegt. Offen ist nur eine rollenspezifische Ausnahme beim Doppelspion, geführt als RM-DR-155.3. Die Optionen B und C unten sind damit keine offene Wahl mehr, sondern würden eine bestehende Entscheidung ändern.
- **Betroffene Rollen:** alle 13 fehlenden Einzelsiegrollen, zusätzlich der umgesetzte `manipulator`.
- **Problem:** Legacy lässt das Dorf gewinnen, sobald kein Wolf lebt, auch wenn Einzelsiegrollen leben (Ausnahme Doppelspion). Godot erzeugt heute ebenfalls den Dorfkandidaten bei null Wölfen; es ist nicht entschieden, ob das so bleiben soll.
- **Belege:** `js/ui/core.js:218-239`, `:287-337`; `godot/core/rules/win_rules.gd:18-37`; DR-02, DR-14.
- **Option A:** Wie heute: Dorf- und Wolfskandidat entstehen unabhängig von lebenden Einzelsiegrollen; Einzelsiegbedingungen erzeugen eigene Kandidaten; der Spielleiter bestätigt genau einen (DR-02).
- **Option B:** Der Dorfkandidat entsteht erst, wenn keine Einzelsiegrolle mit noch erreichbarer Siegbedingung lebt.
- **Option C:** Einzelsiegrollen blockieren nur den Dorfsieg, nicht den Wolfssieg.
- **Auswirkung:** A ändert nichts am Kern und bleibt DR-02-konform; B verlängert Partien und braucht je Rolle eine Definition „erreichbar“; C ist asymmetrisch.
- **Empfehlung:** A.
- **Relevant für Chargen:** früher als K1-Blocker geführt; da entschieden, kein Blocker mehr.

## RM-DR-008 · Stimmbezogene Rollentexte ohne digitale Stimmen

- **Status:** später (K14, K15). Digitale Stimmen und Stimmgewichte sind bereits ausgeschlossen (`implementation-boundary.md` D).
- **Betroffene Rollen:** `korrupter-richter` („+1 Stimme“), `blutwolf` (Stimmgewicht), `hades` („Stimme ×3“), `nekromant` („Stimmen opfern“).
- **Problem:** Digitale Stimmabgabe und Stimmgewichte sind ausgeschlossen ([`../specs/vertical-slice/implementation-boundary.md`](../specs/vertical-slice/implementation-boundary.md) D).
- **Option A:** Die App zeigt den Stimmbonus nur als Hinweis für die physische Zählung (Legacy-Blutwolf „V<n>“); nichts wird gezählt.
- **Option B:** Rollentexte werden ohne Stimmbezug neu formuliert.
- **Option C:** Diese Rollen bleiben außerhalb von 1.0.
- **Auswirkung:** A erhält die Rollen mit minimalem Aufwand; B verändert die Rollen; C spart Aufwand.
- **Empfehlung:** C für 1.0, danach A.
- **Relevant für Chargen:** K14, K15. **Relevant für Option B (nicht freigegeben):** Nein.

## RM-DR-009 · Zeitpunkt aller Todesreaktionen und Todesfolgen

- **Status:** RM-DR-009.1 (Reaktionen mit Entscheidung) entschieden durch G-TOD-4 und DR-09; RM-DR-009.2 (Folgen ohne Entscheidung) technisch nach dem Vorbild Wolfskind und Lehrling.
- **Betroffene Rollen:** `besessener-wolf`, `daemonischer-wolf`, `ritter`, `feuerteufel`, `schutzgeist`, `detektiv`, `seuchenwolf`, `loki`, `rotkaeppchen`, `parasit`, `schattenwanderer`.
- **Problem:** DR-09 regelt den Zeitpunkt nur für den Sensenträger. Legacy verarbeitet Reaktionen teils sofort, teils am Morgen, außerhalb einer Warteschlange.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 10; `godot/core/rules/kill_pipeline.gd` (Wolfskind- und Lehrling-Folgen sofort, Reaktionen eingereiht).
- **Option A:** Zwei Arten wie im Kern angelegt: **Todesfolgen ohne Entscheidung** (Liebeskummer, Kettentod, Ritter-Vergeltung, Seuchenwolf-Markierung) wirken sofort als Teil des Todes, vor der vorläufigen Siegprüfung. **Todesreaktionen mit Entscheidung** (Besessener Wolf, Dämonischer Wolf, Schutzgeist) laufen über die persistente Warteschlange mit dem Zeitpunkt aus DR-09.
- **Option B:** Alles über die Warteschlange, auch ohne Entscheidung.
- **Auswirkung:** A nutzt die bestehende Unterscheidung (Wolfskind/Lehrling sofort, Sensenträger eingereiht); B erzeugt zusätzliche Bestätigungsschritte ohne Spielwert.
- **Empfehlung:** A.
- **Relevant für Chargen:** K3, K4, K6, K9, K10, K12. **Relevant für Option B (nicht freigegeben):** Ja.

## RM-DR-010 · Rollenblockierung: Umfang und Wirkung

- **Status:** später (K8).
- **Betroffene Rollen:** `schattenhund`, `albtraumwolf`, `der-weise` (Debuff), `zeitwaechter`.
- **Problem:** Legacy blockiert nur Nachtschritte, filtert über Rollennamen (auch Solos) und nie Morgen- oder Todesreaktionen.
- **Belege:** `js/core/abilities.js:92-99`; [`04`](04-rule-conflicts.md) §2 Zeile 11.
- **Option A:** Eine Blockade verhindert nur aktive Nachtschritte der betroffenen Personen in der betroffenen Nacht; der Schritt entfällt protokolliert (`StepDropped`, neuer Grund). Filter nach Fraktion: nur Dorf.
- **Option B:** Wie A, aber alle Nicht-Wölfe (auch Einzelsiegrollen).
- **Option C:** Zusätzlich passive Fähigkeiten und Reaktionen der Nacht.
- **Auswirkung:** A ist am einfachsten zu erklären und passt zu „Dorf-Fähigkeiten“ im Schattenhund-Text; B entspricht Legacy; C ist schwer nachvollziehbar.
- **Empfehlung:** A.
- **Relevant für Chargen:** K8, K16. **Relevant für Option B (nicht freigegeben):** Ja (`schattenhund`).

## RM-DR-011 · Wiederbelebung: was bleibt, was verfällt

- **Status:** RM-DR-011.1 entschieden (DECISION-LOG: Reaktion bleibt, Tränke und Spiegelung nicht zurückgesetzt, kein zweites Erbe, Wolfskind); RM-DR-011.2 (Bindungen und Marker) später (K6, K10, K13).
- **Betroffene Rollen:** `kutscher`, `dr-victor-frankenstein` (auslösend); `loki`, `rotkaeppchen`, `schattenwanderer`, `parasit`, `fenrir`, `seuchenwolf`, `todesprediger`, `giftwolf`, `schicksalswolf` (betroffen). Auch `GmCorrection revive`.
- **Problem:** Legacy behandelt Bindungen, Marker und Einsätze bei Wiederbelebung uneinheitlich; ein wiederbelebter Liebender stirbt erneut an Liebeskummer.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 12; DECISION-LOG „Wiederbelebung und Todesreaktion“, Waldhexe „Wiederbelebung setzt Tränke nicht zurück“.
- **Option A:** Wiederbelebung stellt nur das Leben her. Einsätze bleiben verbraucht, bereits eingereihte Reaktionen bleiben (entschieden). Bindungen, die durch den Tod ausgelöst oder beendet wurden (Liebespaar, Kette, Wirt), bleiben beendet; ein erneuter Tod löst sie nicht noch einmal aus. Marker mit Ablauf (Gift) enden mit dem Tod.
- **Option B:** Wiederbelebung stellt den Zustand vor dem Tod vollständig wieder her.
- **Auswirkung:** A ist eindeutig und passt zu den bestehenden Einträgen; B verlangt Schnappschüsse aller Rollenzustände und kann Kettentode erneut auslösen.
- **Empfehlung:** A.
- **Relevant für Chargen:** K6, K10, K13. **Relevant für Option B (nicht freigegeben):** Ja (`loki`).

## RM-DR-012 · Nominierung durch den Korrupten Richter

- **Status:** später (K14).
- **Betroffene Rollen:** `korrupter-richter`; Wechselwirkung mit `manipulator` und `spiegelwolf` (umgesetzt).
- **Problem:** Legacy markiert „nominiert“, ohne die Manipulator-Folge auszulösen; wer als Nominierender gilt, ist offen.
- **Belege:** [`02`](02-implemented-roles-audit.md) §4.10; [`dossiers/village-2.md`](dossiers/village-2.md#korrupter-richter); DR-03.
- **Option A:** Die Markierung ist eine normale Nominierung mit dem Richter als Nominierendem; sie zählt gegen sein Tageslimit und löst Manipulator-Tod und Spiegelung normal aus.
- **Option B:** Eigene Nominierungsquelle „Rolle“ ohne Nominierenden; Manipulator stirbt, Spiegelwolf spiegelt nicht.
- **Option C:** Nur eine Markierung ohne Nominierung.
- **Auswirkung:** A nutzt vorhandene Regeln ohne Sonderfall; B braucht ein neues Feld und einen Sonderfall in `ExecutionRules`; C verliert die Textwirkung.
- **Empfehlung:** A.
- **Relevant für Chargen:** K14. **Relevant für Option B (nicht freigegeben):** Nein.

## RM-DR-013 · Rollen mit Totenkarten-Abhängigkeit

- **Status:** entschieden für Kutscher und Frankenstein (ohne Karten, DECISION-LOG Rollenaudit Wiederbelebungsrollen 28.09.2026); Totenkarten-Assistent und Kartenschlucker später (K15).
- **Betroffene Rollen:** `kartenschlucker` (Kernmechanik), `kutscher`, `dr-victor-frankenstein` (Kartenbedingungen über Rollen-Tags).
- **Problem:** Totenkarten sind in Godot nicht umgesetzt; `07` Q3 (Automatisierungsgrad, Ziehungszeitpunkt) ist offen.
- **Belege:** `js/core/cards.js:573`; [`dossiers/solos-b.md`](dossiers/solos-b.md#kartenschlucker).
- **Option A:** Diese Rollen erst nach dem Totenkarten-Assistenten umsetzen.
- **Option B:** Ohne Kartenbezug umsetzen; der Kartenschlucker bleibt ausgeschlossen.
- **Empfehlung:** A.
- **Relevant für Chargen:** K13, K15. **Relevant für Option B (nicht freigegeben):** Nein.

## RM-DR-014 · Bedeutung von „einmalig“ und „erste Nacht“

- **Status:** entschieden (Option B, strikt Nacht 1; DECISION-LOG Rollenaudit 27.09.2026). Vorher: später. Für Wolfskind und Lehrling bereits entschieden (DR-10, DR-11: erste verfügbare Nacht).
- **Betroffene Rollen:** 14, u. a. `loki`, `die-gebundenen`, `schattenhund`, `koenig-lykaon`, `schicksalswolf`, `schattenwanderer`, `dorfchronistin`, `kriegerin-des-lichts`, `faehrtenleser`.
- **Problem:** Legacy `once:true` heißt „einmal pro Partie“, nicht „nur Nacht 1“; einige Handler prüfen zusätzlich `nightCount===1` und verbrauchen die Fähigkeit bei späterem Klick. Texte sagen teils „in der ersten Nacht“.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 13; DR-10/DR-11 entschieden „erste verfügbare Nacht“ für Wolfskind und Lehrling.
- **Option A:** Rollen, die zu Spielbeginn etwas festlegen (Loki, Gebundene, Chronistin, Schicksalswolf-Markierung, König Lykaon, Schattenwanderer): Schritt in der **ersten verfügbaren Nacht**, bis er erledigt ist (wie DR-10/DR-11). Freiwillige Einmalfähigkeiten („darf einmal“): Schritt jede Nacht mit ausdrücklichem Verzicht, bis genutzt.
- **Option B:** Strikt Nacht 1; wer dort nicht handelt, verliert die Fähigkeit.
- **Auswirkung:** A ist robust gegen spät eingesetzte Rollen (Erbe, Tausch) und passt zum Kern; B ist näher an einigen Texten.
- **Empfehlung:** A.
- **Relevant für Chargen:** K2, K6, K7, K8, K11, K12, K15. **Relevant für Option B (nicht freigegeben):** Ja (`loki`, `schattenhund`).

## RM-DR-015 · Zufall mit gespeichertem Seed oder Wahl durch den Spielleiter

- **Status:** RM-DR-015.1 entschieden (G-RNG-1: Zufall immer über gespeicherten Seed); RM-DR-015.2 (ob eine Rolle Zufall oder Spielleiterwahl nutzt) später je Rolle.
- **Betroffene Rollen:** `kopfgeldjaeger`, `koenig`, `traumdeuter`, `spuerhund`, `verdammniswaechter`, `blutpriester`, `detektiv`, `dorfschmied`, `kutscher`, `pestbringerin`.
- **Problem:** Legacy nutzt `Math.random`, teils mit verzerrtem Mischen, und würfelt beim erneuten Öffnen neu. DR-08 hat beim Trugbilderwolf Zufall durch Spielleiterwahl ersetzt.
- **Belege:** [`04`](04-rule-conflicts.md) §2 Zeile 14; `godot/core/util/seeded_rng.gd`; Orakel-Übersteuerung (`OverrideShownRole`).
- **Option A:** Zufall über `SeededRng`, erst bei Bestätigung übernommen (wie Lehrling); der Spielleiter darf ein gezeigtes Ergebnis mit Begründung übersteuern (wie Orakel).
- **Option B:** Der Spielleiter wählt immer (wie DR-08).
- **Option C:** Je Rolle.
- **Auswirkung:** A ist reproduzierbar und entlastet den Spielleiter; B ist maximal kontrollierbar, aber langsamer.
- **Empfehlung:** A.
- **Relevant für Chargen:** K3, K5, K7, K9, K11, K13. **Relevant für Option B (nicht freigegeben):** Ja (`kopfgeldjaeger`).

## RM-DR-016 · Rollenkopien: Setup, Partie und Zustand je Person

- **Status:** RM-DR-016.1 später (nur falls eine einzelne Rolle aus Spielgründen eine Grenze braucht); RM-DR-016.2 technisch. **Kein Blocker für K1.**
- **Korrektur (2026-09-27):** Die frühere Empfehlung „`max_copies = 1` für alle neuen Sonderrollen, damit Mehrfachkopie-Tests entfallen“ ist zurückgezogen. Sie war mit geringerem Testaufwand begründet, und dieser Effekt tritt nicht ein (siehe unten).
- **Drei getrennte Ebenen:**
  1. **Setup (RM-DR-016.1):** Wie viele Kopien einer Rolle der Spielleiter verteilen darf. Festgelegt ist: keine feste Rollenkomposition im Katalog, einzelne spätere Rollen dürfen eine eigene Obergrenze erhalten (DECISION-LOG „Core-Slice · Rollenanzahl der Grundrollen“). Eine globale Grenze ist nicht entschieden. Die Setup-Oberfläche von Grimmhain-1 liest `max_copies` aus dem Katalog (Branch `claude/sleepy-babbage-u2o0i2`, noch nicht in `main`); jede Grenze wäre dort sofort sichtbar.
  2. **Während der Partie (RM-DR-016.2):** Mehrere Personen mit derselben Rolle entstehen auch ohne Setup-Kopien: der Lehrling erbt die Rolle seines Meisters, während der Meister tot ist, aber nach einer Wiederbelebung wieder lebt; `GmCorrection set_role` kann jede Rolle vergeben; später Seelentauscher, Frankenstein, Kutscher. Eine Setup-Grenze verhindert das nicht.
  3. **Zustand je Person:** bereits entschieden (G-ID-3).
- **Auswirkung auf den Aufwand:** Weil Ebene 2 immer möglich ist, braucht jede Rolle mit Zustand oder Siegbedingung ohnehin ein definiertes Verhalten und Tests für zwei gleichzeitige Personen dieser Rolle. Eine Setup-Grenze spart diese Tests nicht; sie senkt nur die Wahrscheinlichkeit des Falls am Tisch.
- **Empfehlung:** keine globale Obergrenze beschließen. Eine Grenze nur für eine konkrete Rolle vorschlagen, wenn Spielbalance oder Tischablauf es verlangen, und dann in der Rollenentscheidung begründen. Für `siegreicher-wolf`, `doppelspion` und `selbstmoerder` ist keine Grenze nötig; ihr Verhalten mit mehreren Personen folgt aus G-ID-3 und G-SIEG-3 („je Person ein Kandidat“).

## RM-DR-017 · Umfang der nächsten Rollenspezifikation

- **Status:** produktentscheidung (neu).
- **Problem:** Die Optionen A/B/C in [`05`](05-v1-role-options.md) sind nicht freigegeben. Bevor Grimmhain-2 eine Spezifikation schreibt, muss feststehen, welche Rollen sie umfasst.
- **Option A:** `siegreicher-wolf` und `doppelspion`.
- **Option B:** nur `siegreicher-wolf`.
- **Option C:** `siegreicher-wolf`, `doppelspion` und `selbstmoerder` (die bisherige Charge K1).
- **Auswirkung:** A braucht zusätzlich RM-DR-155.1, .3 und .4; B braucht keine weitere Antwort; C braucht zusätzlich RM-DR-138.1, .3 und .4 und führt einen neuen Siegtyp ein, der vom Zeitpunkt der Hinrichtung abhängt.
- **Empfehlung:** A. Begründung in [`06`](06-implementation-batches.md) §3.1.
- **Blockiert:** jede weitere Rollenspezifikation.

## 2. Rollenentscheidungen

Je Rolle eine Sammelentscheidung mit Unter-IDs. Die Teilfragen stammen aus den Widerspruchstabellen in [`04`](04-rule-conflicts.md) §3 (Spalte PO = Ja) bzw., wo keine Tabelle existiert, aus den offenen Fragen des Dossiers. „Option A“ und „Option B“ entsprechen den Interpretationen A und B. Die Empfehlung ist ein Vorschlag aus der Code-Lektüre. Jede Teilfrage trägt ihren Status; „später“ nennt die Charge, ab der sie gebraucht wird. „In Option“ nennt die kleinste Option aus `05`, in der die Rolle vorkommt; das ist keine Freigabe.

## RM-DR-101 · `loki`

- **Status des Eintrags:** später (ab Charge K6).
- **Betroffene Rollen:** `loki`; Wechselwirkung laut Dossier: Schwarze Witwe (Pflichtpaar, liest Bindung), Dr. Victor Frankenstein/Kutscher (Wiederbelebung), Lehrling (Erbe), Nekromant/Kartenschlucker/Hades (Schilde in …
- **Belege:** [Dossier](dossiers/village-1.md#loki); RM-C-082 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-009, RM-DR-011, RM-DR-014.
- **RM-DR-101.1 · Rivalen-Wirkung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: Rivalen = reiner Marker für Schwarze Witwe
  - Option B: Rivalen bekommen eigene Regel (z.B. Siegsperre)
  - Auswirkung: Balance: Hass-Option ist ohne Witwe eine Leerwahl; Umsetzung: Ohne Regel nur Marker; mit Regel WinRules-Erweiterung
  - Empfehlung: PO entscheidet; bis dahin Marker
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Haben Rivalen eine eigene Wirkung (Q1-Vorschlag) oder bleiben sie Witwe-Marker? 2. Stirbt ein wiederbelebter Liebender erneut, wenn sein Partner tot ist? 3. Ist der Liebeskummer-Tod eine eigene Todesursache mit Reaktionen (Sensenträger) wie heute? 4. Darf Loki sich selbst wählen (Legacy: ja)?
- **Charge:** K6. **In Option (nicht freigegeben):** B.

## RM-DR-102 · `nachtwaechter`

- **Status des Eintrags:** später (ab Charge K3).
- **Betroffene Rollen:** `nachtwaechter`; Wechselwirkung laut Dossier: alle Wolfs- und Solorollen; Dämonischer Wolf (`cursedWolfAura` zählt als Wolf), Wolfskind (verwandelt), Doppelspion (Solo, …
- **Belege:** [Dossier](dossiers/village-1.md#nachtwaechter); RM-C-085 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-003.
- **RM-DR-102.1 · Nachbarbegriff** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 2 27.09.2026
  - Option A: nächster lebender Sitz
  - Option B: direkter Sitz
  - Auswirkung: Balance: leicht; Umsetzung: Sitznachbarschafts-Funktion
  - Empfehlung: nächster lebender (wie Code)
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Zeitpunkt: nach vollständiger Morgenauflösung (nach allen Reaktionen) oder vor den Toten? 2. Nur wenn ein Wolf/Solo direkt oder nächster lebender Nachbar ist? 3. Zählt ein nur "als Wolf erscheinender" Spieler (Dämonischer-Wolf-Fluch)? 4. Wird angesagt, welche Seite (links/rechts) oder nur "Alarm"?
- **Charge:** K3. **In Option (nicht freigegeben):** C.

## RM-DR-103 · `rattenfaenger`

- **Status des Eintrags:** quellenprüfung.
- **Betroffene Rollen:** `rattenfaenger`; Wechselwirkung laut Dossier: Voodoo-Priester (hebt Verzauberung auf), Lehrling/Seelentauscher (Rollenwechsel), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (Doppelaktion), Die Ewigen (Solo-Erkennung), Wölfe/Dorf …
- **Belege:** [Dossier](dossiers/solos-a.md#rattenfaenger); RM-C-041, RM-C-043 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-007.
- **RM-DR-103.1 · Zählt er selbst** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: alle außer Rattenfänger
  - Option B: inkl. Rattenfänger (Selbstverzauberung nötig)
  - Auswirkung: Balance: B verschwendet eine Verzauberung; Umsetzung: Filter
  - Empfehlung: A (Code) + Text präzisieren
- **RM-DR-103.2 · Verzauberung durch Puppe aufgehoben** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: beabsichtigte Interaktion
  - Option B: Altlast
  - Auswirkung: Balance: Voodoo kann Rattenfänger bremsen; Umsetzung: eigene Regel nötig
  - Empfehlung: streichen, falls nicht gewollt
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Zählt der Rattenfänger selbst zu „allen lebenden Spielern"? (2) Sieg auch, wenn die Bedingung durch einen Tod eintritt? (3) Genau eine Aktion pro Nacht, 1 oder 2 Ziele, Selbstwahl erlaubt? (4) Gewinnt der Rattenfänger vor dem Dorf, wenn in derselben Auflösung der letzte Wolf und der letzte Unverzauberte sterben (DR-02: SL wählt aus Kandidaten)? (5) Soll die Voodoo-Puppe Verzauberung aufheben?
- **Charge:** K9. **In Option (nicht freigegeben):** B.

## RM-DR-104 · `die-ewigen`

- **Status des Eintrags:** später (ab Charge K9).
- **Betroffene Rollen:** `die-ewigen`; Wechselwirkung laut Dossier: alle 14 Solo-Rollen (`roles:399-403`), insbesondere solche ohne Siegcode (Prophet, Feuerteufel, Voodoo, Grabräuber: 07 Q4); Lehrling/Seelentauscher (Solo-Rolle wechselt …
- **Belege:** [Dossier](dossiers/village-1.md#die-ewigen); RM-C-087, RM-C-088, RM-C-089 in [`04`](04-rule-conflicts.md). Legacy-Befund `not-found`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-006.
- **RM-DR-104.1 · Mitsieg** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: Ewige gewinnen mit jedem gefundenen Solo, wenn dieser gewinnt
  - Option B: Ewige gewinnen mit dem Solo, den sie zuletzt/zuerst gefunden haben
  - Auswirkung: Balance: hoch (Dorfrolle wechselt faktisch Siegseite); Umsetzung: WinCandidate muss Mitsieger tragen; widerspricht "genau ein Kandidat"
  - Empfehlung: Regel festlegen, Mitsieg als Zusatz-Gewinner am Kandidaten
- **RM-DR-104.2 · Info-Umfang** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: nur Ja/Nein
  - Option B: Ja + Rolle
  - Auswirkung: Balance: Rollenname ist Orakel-starke Info; Umsetzung: InfoRecord-Inhalt
  - Empfehlung: nur Ja/Nein
- **RM-DR-104.3 · Siegseite der Ewigen** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: Ewige bleiben Dorf und gewinnen zusätzlich mit Solo
  - Option B: Ewige verlassen das Dorf, sobald Solo gefunden
  - Auswirkung: Balance: mittel; Umsetzung: Fraktionswechsel oder Zusatzsieg
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Wann gewinnen die Ewigen mit: mit jedem Solo, den sie je positiv geprüft haben, oder mit jedem Solo-Sieger überhaupt? 2. Müssen die Ewigen zum Siegzeitpunkt leben? 3. Nur Ja/Nein oder auch Rollenname? 4. Tote Ziele und Selbstprüfung erlaubt? 5. Verlieren die Ewigen mit dem Dorf, wenn sie einen Solo gefunden haben?
- **Charge:** K9. **In Option (nicht freigegeben):** keiner.

## RM-DR-105 · `spuerhund`

- **Status des Eintrags:** später (ab Charge K7).
- **Betroffene Rollen:** `spuerhund`; Wechselwirkung laut Dossier: Wolfskind, Dämonischer Wolf (Fluch), Trugbilderwolf (Wolfsrolle), alle Solos, Lehrling/Seelentauscher (Rollenname …
- **Belege:** [Dossier](dossiers/village-1.md#spuerhund); RM-C-090 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-015.
- **RM-DR-105.1 · Wer wird falsche Spur** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 5 28.09.2026
  - Option A: Zufall (SeededRng)
  - Option B: SL wählt
  - Auswirkung: Balance: Zufall kann Spürhund selbst oder echte Wölfe treffen (dann wirkungslos); Umsetzung: Rng-Aufruf vs. Prompt
  - Empfehlung: Zufall über lebende Nicht-Wolf/Nicht-Solo außer Spürhund, per SeededRng
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Falsche Spur zufällig oder SL-Wahl? Aus welcher Menge (ohne Spürhund, ohne Wölfe/Solos, ohne bereits markierte)? 2. Bleibt die Markierung dauerhaft? Kumulativ? 3. Zählt ein Verfluchter (Dämonischer Wolf) als Wolf? 4. Selbstwahl unter den 3 erlaubt?
- **Charge:** K7. **In Option (nicht freigegeben):** keiner.

## RM-DR-106 · `rachsuechtiger-wolf`

- **Status des Eintrags:** später (ab Charge K11).
- **Betroffene Rollen:** `rachsuechtiger-wolf`; Wechselwirkung laut Dossier: Werwolf (Rudel, synthetische Zeile), Doppelspion (Zielausschluss, Textbezug), Dämonischer Wolf (verfluchte Ziele), Schutzengel/Dorfwache, Seuchenwolf, Waldhexe, Verdammniswächter, Die Ewigen, Nachtwächter …
- **Belege:** [Dossier](dossiers/wolves-a.md#rachsuechtiger-wolf); RM-C-001, RM-C-002, RM-C-003 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-004, RM-DR-006.
- **RM-DR-106.1 · Siegziel** · Status: später (K11)
  - Option A: Einzelsieg: gewinnt nur, wenn er als Letzter (oder mit Bedingung X) übrig ist
  - Option B: Rudelsieg wie Code
  - Auswirkung: Balance: A macht ihn zum Verräter im Rudel, B zu einem normalen Wolf mit Zusatzkill; Umsetzung: A: neue Siegbedingung, Fraktion "solo" trotz Wolfsrudel, Parität neu definieren
  - Empfehlung: A (Text), EN ergänzen
- **RM-DR-106.2 · Rhythmus** · Status: später (K11)
  - Option A: fester Takt (Nacht 3, 6, 9)
  - Option B: Abklingzeit nach Nutzung
  - Auswirkung: Balance: A seltener und vorhersehbar; Umsetzung: Nachtschritt-Bedingung nach Nachtnummer vs. Zähler pro Person
  - Empfehlung: Abklingzeit (Code), Text präzisieren
- **RM-DR-106.3 · Zeitpunkt der ersten Nutzung** · Status: später (K11)
  - Option A: erst ab Nacht 3
  - Option B: ab Nacht 1
  - Auswirkung: Balance: früher Rudelverlust in Nacht 1 möglich; Umsetzung: Startwert Zähler
  - Empfehlung: festlegen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Einzelsieg ja/nein, und wenn ja unter welcher Bedingung (letzter Lebender? letzter Wolf?) und zählt er vorher zur Wolfsparität? (2) Feste Nächte (3, 6, 9) oder Abklingzeit ab erster Nutzung? Erste Nutzung ab Nacht 1? (3) Wirkt Schutzengel-Schutz gegen seinen Angriff? (4) Ist sein Angriff ein "Wolfsangriff" für Seuchenwolf, Rudelvater, Ritter?
- **Charge:** K11. **In Option (nicht freigegeben):** keiner.

## RM-DR-107 · `koenig-lykaon`

- **Status des Eintrags:** später (ab Charge K12).
- **Betroffene Rollen:** `koenig-lykaon`; Wechselwirkung laut Dossier: Trugbilderwolf, Wächter am Tor, Orakel, Lehrling (Erbe), Werwolf (synthetische Rudelzeile), Totenkarte …
- **Belege:** [Dossier](dossiers/wolves-a.md#koenig-lykaon); RM-C-004, RM-C-005 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-014.
- **RM-DR-107.1 · Scheinrolle des erzeugten Trugbilderwolfs** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: Scheinrolle = alte Rolle der Person
  - Option B: SL wählt bei Verwandlung
  - Auswirkung: Balance: A passt zur Tarnzeile und ist logisch stark; Umsetzung: `appears_as` muss bei RoleTransition gesetzt werden
  - Empfehlung: A, mit SL-Korrektur
- **RM-DR-107.2 · "Dorfbewohner"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: nur Dorffraktion
  - Option B: jede Nicht-Wolf-Person
  - Auswirkung: Balance: B kann Solo-Rollen neutralisieren; Umsetzung: Zielfilter `faction==village` vs `!counts_as_wolf`
  - Empfehlung: festlegen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Welche Scheinrolle erhält der neue Trugbilderwolf? (2) Dürfen Solo-Rollen Ziel sein? (3) Muss der Verbündete gespeichert/angezeigt werden, oder reicht er als Ansage? (4) Verfällt die Fähigkeit, wenn Nacht 1 ohne Nutzung vergeht (Legacy ja)? (5) Tarnzeile der alten Rolle ja/nein, auch bei Wächter-Umleitung?
- **Charge:** K12. **In Option (nicht freigegeben):** C.

## RM-DR-108 · `seuchenwolf`

- **Status des Eintrags:** später (ab Charge K11).
- **Betroffene Rollen:** `seuchenwolf`; Wechselwirkung laut Dossier: Werwolf, Schutzengel, Schutzgeist, Dorfwache, Der Weise, Waldhexe, Nekromant, Kartenschlucker, Hades, Dorfschmied, Märtyrerin, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (gemeinsames …
- **Belege:** [Dossier](dossiers/wolves-a.md#seuchenwolf); RM-C-006, RM-C-007, RM-C-008 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-004, RM-DR-005, RM-DR-009, RM-DR-011.
- **RM-DR-108.1 · Umfang "alle Schutzeffekte"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: wirklich alles, was einen Rudelkill verhindert
  - Option B: nur Schutzrollen (Schutzengel, Dorfwache, Der Weise), keine Schilde/Rettungen
  - Auswirkung: Balance: A deutlich stärker; Umsetzung: Liste der durchdrungenen Abfangregeln in KillPipeline festlegen
  - Empfehlung: Einheitliche Liste mit Rudelvater teilen
- **RM-DR-108.2 · Verbrauch** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: nächster Angriff, auch wenn er scheitert
  - Option B: nächster erfolgreiche Kill
  - Auswirkung: Balance: A kann durch Hexe verpuffen; Umsetzung: Verbrauchszeitpunkt
  - Empfehlung: A (Text)
- **RM-DR-108.3 · Welche Angriffe** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: nur Rudelangriff
  - Option B: jeder Wolfskill
  - Auswirkung: Balance: gering; Umsetzung: Ursachen-Attribut
  - Empfehlung: nur Rudelangriff
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Welche Schutzarten durchdringt er (Liste)? (2) Verbraucht ein gescheiterter Angriff die Durchdringung? (3) Nur Rudelangriff oder jeder Wolfskill? (4) Stapeln sich zwei Seuchenwolf-Tode?
- **Charge:** K11. **In Option (nicht freigegeben):** keiner.

## RM-DR-109 · `schicksalswolf`

- **Status des Eintrags:** später (ab Charge K11).
- **Betroffene Rollen:** `schicksalswolf`; Wechselwirkung laut Dossier: Werwolf (Rudelopfer, Deduplizierung), Schutzengel, Dorfwache, Der Weise, Märtyrerin, Zeitwächter (eingefrorene Nacht zählt nicht, `night:323-331` erhöht `nightCount` nicht), Frankenstein/Kutscher (Wiederbelebung), …
- **Belege:** [Dossier](dossiers/wolves-a.md#schicksalswolf); RM-C-009, RM-C-010, RM-C-011 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-004, RM-DR-005, RM-DR-011, RM-DR-014.
- **RM-DR-109.1 · Zeitfenster** · Status: später (K11)
  - Option A: nur Nacht 4, danach verfallen
  - Option B: ab Nacht 4, einmal
  - Auswirkung: Balance: B lässt Wölfe auf Bonus warten; Umsetzung: Schrittbedingung
  - Empfehlung: A (Text)
- **RM-DR-109.2 · Schutz gegen Zusatzopfer** · Status: später (K11)
  - Option A: wie Rudelangriff (Schutz wirkt)
  - Option B: eigener Kill ohne Schutz
  - Auswirkung: Balance: A schwächer; Umsetzung: Ursache/Quelle, Protections-Filter
  - Empfehlung: A
- **RM-DR-109.3 · Zählung der ersten drei Toten** · Status: später (K11)
  - Option A: erste drei verschiedenen Toten der Partie
  - Option B: nur Tode nach Markierung
  - Auswirkung: Balance: gering; Umsetzung: Todesreihenfolge-Historie
  - Empfehlung: A mit Deduplizierung
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Nur Nacht 4 oder ab Nacht 4? (2) Wirkt Schutz gegen Zusatzopfer? (3) Zählen Tode vor der Markierung und doppelte Tode? (4) Darf er sich selbst oder Wölfe markieren? (5) Verfällt die Fähigkeit, wenn Nacht 1 nicht markiert wird?
- **Charge:** K11. **In Option (nicht freigegeben):** keiner.

## RM-DR-110 · `schattenwanderer`

- **Status des Eintrags:** später (ab Charge K6).
- **Betroffene Rollen:** `schattenwanderer`; Wechselwirkung laut Dossier: Rudelvater (Reihenfolge), Parasit, Nekromant/Kartenschlucker/Hades (Schilde beim Partner), Werwolf, Lynch/ExecutionRules, Frankenstein/Kutscher (Wiederbelebung), Dämonischer Wolf, Kopfgeldjäger, …
- **Belege:** [Dossier](dossiers/wolves-a.md#schattenwanderer). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-009, RM-DR-011, RM-DR-014.
- **RM-DR-110.1 · „Stattdessen“ oder „beide sterben“** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: Stirbt einer der beiden, stirbt stattdessen der andere (Text „stattdessen“, Legacy-Umlenkung `core:118-124`)
  - Option B: Beide sterben (Begriff „Todeskette“)
  - Auswirkung: Balance: A ist ein Schutz für den Schattenwanderer, B eine Kettenfalle; Umsetzung: A: Umlenkung in der Abfangstufe; B: Kettentod als Todesfolge
  - Empfehlung: A (Text und Code stimmen überein)
- **RM-DR-110.2 · Umfang und Dauer** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: Gilt für alle Todesursachen einmalig, danach ist die Bindung verbraucht
  - Option B: Gilt dauerhaft für jeden Tod
  - Auswirkung: Balance: B sehr stark; Umsetzung: Bindungsstatus mit Verbrauch
  - Empfehlung: A, Details im Dossier
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) "stattdessen" (Code) oder "beide sterben" (Begriff Todeskette)? (2) Gilt die Umlenkung für alle Ursachen inkl. Hinrichtung, und zählt eine umgelenkte Hinrichtung als erfolgt? (3) Einmalig oder dauerhaft (auch nach Wiederbelebung)? (4) Mit welcher Ursache/Quelle stirbt der Partner (eigene Ursache oder Original)? (5) Nur Nacht 1 oder jede Nacht bis zur Nutzung?
- **Charge:** K6. **In Option (nicht freigegeben):** keiner.

## RM-DR-111 · `giftwolf`

- **Status des Eintrags:** später (ab Charge K11).
- **Betroffene Rollen:** `giftwolf`; Wechselwirkung laut Dossier: Rudelvater (keine Rettung), Ritter (Vergeltung), Schattenwanderer, Nekromant/Kartenschlucker/Hades (Schilde), Zeitwächter (Morgenzähler), Frankenstein/Kutscher (Wiederbelebung), Orakel (sieht …
- **Belege:** [Dossier](dossiers/wolves-a.md#giftwolf); RM-C-012, RM-C-013, RM-C-014 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-004, RM-DR-011.
- **RM-DR-111.1 · Zwei Ladungen in einer Nacht** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: beide sofort erlaubt
  - Option B: max 1 pro Nacht
  - Auswirkung: Balance: A erlaubt Doppelschlag; Umsetzung: Schrittbedingung
  - Empfehlung: B (07)
- **RM-DR-111.2 · "erfährt davon"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: öffentlich/Ansage an Ziel in der Nacht
  - Option B: SL flüstert am Morgen
  - Auswirkung: Balance: Informationsvorteil fürs Ziel; Umsetzung: InfoRecord actor=Ziel
  - Empfehlung: A als Actor-Ereignis
- **RM-DR-111.3 · Zeitpunkt "zwei Tage später"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: Morgen von Tag N+1
  - Option B: Ende von Tag N+1
  - Auswirkung: Balance: gering; Umsetzung: Termin in `day_number`
  - Empfehlung: Code
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Max 1 Ladung pro Nacht? (2) Wie erfährt das Ziel davon (Zeitpunkt, SL-Ansage)? (3) Endet das Gift bei Tod/Wiederbelebung des Ziels oder bei Heilung durch Waldhexe? (4) Ist das Gift ein "Wolfsangriff" (Rudelvater, Schutzengel, Dorfwache, Seuchenwolf)? (5) Ladungen pro Person oder pro Rolle?
- **Charge:** K11. **In Option (nicht freigegeben):** keiner.

## RM-DR-112 · `rudelvater`

- **Status des Eintrags:** später (ab Charge K11).
- **Betroffene Rollen:** `rudelvater`; Wechselwirkung laut Dossier: Werwolf (Rudel), Seuchenwolf (gemeinsame Durchdringung), Giftwolf, Schattenwanderer, Nekromant/Kartenschlucker/Hades, Dorfwache, Der Weise, Dorfschmied, Voodoo-Priester, Märtyrerin, Albtraumwolf, Sensenträger, …
- **Belege:** [Dossier](dossiers/wolves-a.md#rudelvater); RM-C-015, RM-C-016, RM-C-017, RM-C-018 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-004, RM-DR-005.
- **RM-DR-112.1 · Was ist "Wolfsangriff"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: jede Tötung durch eine Wolfsrolle
  - Option B: nur Rudel-/Wolfsnachtangriff
  - Auswirkung: Balance: A macht ihn verwundbarer; Umsetzung: Ursachen-Attribut `wolf_source`
  - Empfehlung: A oder Liste
- **RM-DR-112.2 · Was ist "Lynch"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: nur die Hinrichtung selbst
  - Option B: alles, was aus einer Hinrichtung folgt
  - Auswirkung: Balance: gering; Umsetzung: Ursachen-Attribut execution vs. execution_side
  - Empfehlung: nur Hinrichtung (Code)
- **RM-DR-112.3 · "alle Schutzfähigkeiten"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: wirklich alle Abfangregeln
  - Option B: nur Schutzrollen und Schilde
  - Auswirkung: Balance: gering; Umsetzung: gemeinsame Durchdringungsliste mit Seuchenwolf
  - Empfehlung: eine Liste für beide
- **RM-DR-112.4 · Wer wählt wann** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: eigener Rudelschritt in der Nacht
  - Option B: Pick bei Morgenauflösung
  - Auswirkung: Balance: kein, aber Ablauf/Ansage; Umsetzung: zweiter Rudel-Prompt in StepQueue
  - Empfehlung: A
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Was zählt als Wolfsangriff (Schwarze Witwe, Besessener Wolf, Spiegelwolf, Gift)? (2) Zählen Hinrichtungs-Nebentode als Lynch? (3) Zusatzopfer im Nachtschritt der Wölfe oder am Morgen durch den SL? (4) Zusatzopfer auch bei überlebtem Lynch? (5) Welche Abfangregeln ignoriert das Zusatzopfer (Liste gemeinsam mit Seuchenwolf)? (6) Rettung pro Person oder pro Rolle?
- **Charge:** K11. **In Option (nicht freigegeben):** keiner.

## RM-DR-113 · `schwarze-witwe`

- **Status des Eintrags:** später (ab Charge K6).
- **Betroffene Rollen:** `schwarze-witwe`; Wechselwirkung laut Dossier: Loki (Pflicht, liefert Paare), Zeitwächter (Reihenfolge), Ritter (Vergeltung bei `BLACK_WIDOW`), Rudelvater/Nekromant/Kartenschlucker/Hades/Schattenwanderer/Parasit (Schilde in `applyKill`), Besessener Wolf (siehe …
- **Belege:** [Dossier](dossiers/wolves-b.md#schwarze-witwe); RM-C-019, RM-C-021 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-004.
- **RM-DR-113.1 · Loki "automatisch gewählt"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: Loki wird beim Setup automatisch ins Rollenset gelegt
  - Option B: Loki ist Pflicht-Beirolle, SL muss sie wählen
  - Auswirkung: Balance: keine, solange Loki Pflicht ist; Umsetzung: Godot: `requires_roles` (`03:200`) als Validierung oder Auto-Ergänzung
  - Empfehlung: Pflichtpaar-Validierung behalten, Text auf "Benötigt Loki im Spiel" ändern
- **RM-DR-113.2 · Zeitwächter-Einfrieren** · Status: später (mit RM-DR-150 Zeitwächter; Wirkung der Witwe sonst entschieden, DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026)
  - Option A: Witwen-Wahl ist Nachtaktion, wird eingefroren
  - Option B: Witwen-Tod ist Tagesereignis, bleibt
  - Auswirkung: Balance: mittel; Zeitwächter kontert Witwe nicht; Umsetzung: Reihenfolge in DAWN
  - Empfehlung: mit Zeitwächter-Entscheidung Q1 gemeinsam festlegen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Wird Loki beim Setup automatisch ergänzt oder nur validiert? 2. Zählen Rivalen weiter als Ziel der Witwe, wenn Loki-Rivalen sonst keine Wirkung haben (07 Q1 Loki-Zeile)? 3. Friert der Zeitwächter die Witwen-Tode ein? 4. Darf die Witwe sich selbst oder Wölfe wählen (Code: ja)? 5. Soll ein zweiter Klick / eine zweite Witwe ein weiteres Paar markieren können oder überschreiben?
- **Charge:** K6. **In Option (nicht freigegeben):** keiner.

## RM-DR-114 · `der-weise`

- **Status des Eintrags:** später (ab Charge K8).
- **Betroffene Rollen:** `der-weise`; Wechselwirkung laut Dossier: Werwolf, Rachsüchtiger Wolf, Schicksalswolf, Seuchenwolf, Rudelvater (Durchschlag), Schutzengel/Schutzgeist (Stapelung), Albtraumwolf (Blockade entfernt Ziel), Märtyrerin, Verdammniswächter (umgeht Rettung), Waldhexe; …
- **Belege:** [Dossier](dossiers/village-1.md#der-weise); RM-C-093, RM-C-094, RM-C-096, RM-C-097 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-004, RM-DR-005, RM-DR-010.
- **RM-DR-114.1 · Wer verliert Fähigkeiten** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: nur Dorf-Fraktion
  - Option B: alle Nicht-Wölfe
  - Auswirkung: Balance: Solos werden mitbestraft; Umsetzung: FactionQuery-Filter
  - Empfehlung: nur Dorf
- **RM-DR-114.2 · Dauer "Nächte und Tage"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: Sperre gilt auch für Tagfähigkeiten
  - Option B: nur Nächte
  - Auswirkung: Balance: gering bis mittel; Umsetzung: Tagesaktionen brauchen Blockprüfung
  - Empfehlung: Nacht und Tag
- **RM-DR-114.3 · Durchschlag** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: Durchschlag tötet
  - Option B: Rettung greift trotzdem
  - Auswirkung: Balance: gering; Umsetzung: Filter in Protections
  - Empfehlung: wie Code
- **RM-DR-114.4 · Passive Fähigkeiten im Debuff** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: auch passive (Nachtwächter, Kutscher)
  - Option B: nur aktive
  - Auswirkung: Balance: mittel; Umsetzung: Blockmarker in Reaktionen
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Zählt als "Werwolfangriff" auch Rachsüchtiger Wolf, Schicksalswolf-Extra, Rudelvater-Extra? 2. Durchschlag (Seuchenwolf/Rudelvater): tötet oder verbraucht die Rettung? 3. Debuff: nur Dorf-Fraktion oder alle Nicht-Wölfe? Auch passive Fähigkeiten und Tagesaktionen? 4. Zählweise: n Nächte und n Tage ab Lynch-Tag oder ab nächster Nacht? 5. Wird die Rettung angesagt oder bleibt sie still?
- **Charge:** K8. **In Option (nicht freigegeben):** C.

## RM-DR-115 · `verdammniswaechter`

- **Status des Eintrags:** später (ab Charge K11).
- **Betroffene Rollen:** `verdammniswaechter`; Wechselwirkung laut Dossier: Werwolf/Rudel (liefert Nachtopfer), Rachsüchtiger Wolf (Zusatzziel), Schutzengel/Dorfwache, Der Weise, Märtyrerin, Waldhexe, Voodoo-Priester, Nekromant, Kartenschlucker, Hades, Rudelvater, Ritter, …
- **Belege:** [Dossier](dossiers/village-1.md#verdammniswaechter); RM-C-098, RM-C-099, RM-C-100 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-005, RM-DR-015.
- **RM-DR-115.1 · "umgeht alle Schutzfähigkeiten"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: wirklich alle (auch Schilde, Schutzengel)
  - Option B: nur Schutz gegen das Nachtopfer
  - Auswirkung: Balance: mittel; Umsetzung: KillPipeline-Option `ignore_protections` + Auslösung auch bei geschütztem Opfer
  - Empfehlung: A (07-Vorschlag)
- **RM-DR-115.2 · Todeszeitpunkt** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: sofort
  - Option B: Morgen
  - Auswirkung: Balance: hoch (Hexe, spätere Rollen); Umsetzung: IMMEDIATE vs. Morgenkill
  - Empfehlung: Morgen (07)
- **RM-DR-115.3 · Zufallskandidat** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: jeder andere Lebende
  - Option B: nur Nicht-Wölfe
  - Auswirkung: Balance: Pool ohne Wölfe schützt das Rudel; Umsetzung: Rng-Menge
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Tod sofort oder in der Morgenauflösung? 2. Umgeht das Urteil auch Schilde (Nekromant, Kartenschlucker, Hades, Rudelvater) und Schutzengel (auch wenn das Rudelziel geschützt war)? 3. Kandidatenmenge: alle anderen Lebenden, nur Nicht-Wölfe, ohne Verdammniswächter selbst? 4. Welches Nachtopfer bei mehreren Wolfszielen? 5. Pflichtschritt oder darf der Verdammniswächter verzichten?
- **Charge:** K11. **In Option (nicht freigegeben):** keiner.

## RM-DR-116 · `wahnsinniger-kutscher`

- **Status des Eintrags:** später (ab Charge K3).
- **Betroffene Rollen:** `wahnsinniger-kutscher`; Wechselwirkung laut Dossier: Loki (Kette), Sensenträger/Besessener Wolf (Folgereaktionen), Rudelvater/Nekromant/Kartenschlucker/Hades/Parasit (Schilde), Henker (`finalizeLynch`), Feuerteufel/Voodoo-Priester/Kopfgeldjäger (ausgelassene …
- **Belege:** [Dossier](dossiers/village-1.md#wahnsinniger-kutscher); RM-C-103 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-003.
- **RM-DR-116.1 · Nachbarbegriff** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 2 27.09.2026
  - Option A: direkte Sitze (DE, Code)
  - Option B: nächste Lebende (EN, 07)
  - Auswirkung: Balance: B tötet spät im Spiel zuverlässiger zwei; Umsetzung: gleiche Sitznachbarschafts-Funktion wie Nachtwächter
  - Empfehlung: PO; Texte angleichen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Direkte oder nächste lebende Nachbarn? 2. Schützt Schutzengel/Hexe oder ein Schild die Nachbarn? 3. Wirkt die Reaktion auch bei Tod durch GmCorrection-Hinrichtung (DECISION-LOG Z.131 legt nahe: ja)? 4. Todesursache der Nachbarn und des Kutschers festschreiben.
- **Charge:** K3. **In Option (nicht freigegeben):** A.

## RM-DR-117 · `korrupter-richter`

- **Status des Eintrags:** später (ab Charge K14).
- **Betroffene Rollen:** `korrupter-richter`; Wechselwirkung laut Dossier: Manipulator, Spiegelwolf, Nominations-Limit, Albtraumwolf/Schattenhund/Zeitwächter/Der Weise (Blockaden), Hades (Stimme x3) und Blutwolf nur konzeptionell (weitere …
- **Belege:** [Dossier](dossiers/village-2.md#korrupter-richter); RM-C-105, RM-C-106, RM-C-107 in [`04`](04-rule-conflicts.md). Legacy-Befund `not-found`.
- **Querschnittsbezug:** RM-DR-008, RM-DR-012.
- **RM-DR-117.1 · +1 Stimme** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 5 28.09.2026
  - Option A: SL-Hinweis "zählt +1 Stimme" am nominierten Sitz
  - Option B: Rolle verliert "+1 Stimme", Text anpassen
  - Auswirkung: Balance: ohne Hinweis wirkungslos, Rolle nahezu leer; Umsetzung: A: nur Anzeige in Nomination-Ansicht; B: nur Text
  - Empfehlung: A (Hinweis + Protokoll)
- **RM-DR-117.2 · Wer ist Nominierender?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 5 28.09.2026
  - Option A: Richter ist Nominierender (Spiegelwolf trifft Richter)
  - Option B: anonyme System-Nominierung (Spiegelwolf ohne Ziel)
  - Auswirkung: Balance: Spiegelwolf-Gefahr für Richter; Umsetzung: Nominations braucht Quelle `system`/`role`
  - Empfehlung: PO klärt
- **RM-DR-117.3 · Zählt gegen "einmal nominiert werden"?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 5 28.09.2026
  - Option A: zählt
  - Option B: zählt nicht
  - Auswirkung: Balance: Richter kann reguläre Nominierung blockieren; Umsetzung: Nominations-Regeloption
  - Empfehlung: zählt als Nominierung
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Ist der Richter der Nominierende (Spiegelwolf-Folge)? (2) Zählt die Richter-Nominierung für das Einmal-Limit von Nominierendem/Nominiertem? (3) Darf der Richter sich selbst markieren? (4) "+1 Stimme" als reiner SL-Hinweis oder Text streichen? (5) Pflicht oder optional pro Nacht (Legacy: optional)?
- **Charge:** K14. **In Option (nicht freigegeben):** keiner.

## RM-DR-118 · `maertyrerin`

- **Status des Eintrags:** später (ab Charge K5).
- **Betroffene Rollen:** `maertyrerin`; Wechselwirkung laut Dossier: Werwolf/Rudel, Rudelvater (Extraopfer), Schicksalswolf, Dorfwache, Voodoo-Priester, Zeitwächter, Der Weise, Dorfschmied, Albtraumwolf, Nekromant (Schild), …
- **Belege:** [Dossier](dossiers/village-2.md#maertyrerin); RM-C-108, RM-C-109, RM-C-111 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-004.
- **RM-DR-118.1 · Rettung vs. Zeitpunkt** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: Ersatzopfer für ein Nachtopfer (Code)
  - Option B: Opfer ohne garantierte Rettung (EN wörtlich)
  - Auswirkung: Balance: B macht die Rolle fast nutzlos; Umsetzung: A: Abfangregel in Morgenauflösung
  - Empfehlung: A, EN-Text angleichen
- **RM-DR-118.2 · Welches Opfer bei mehreren** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: SL/Märtyrerin wählt eines
  - Option B: nur Rudelopfer
  - Auswirkung: Balance: Rudelvater-/Schicksalswolf-Nächte; Umsetzung: Auswahlprompt statt fester Index
  - Empfehlung: Auswahl unter Todeskandidaten
- **RM-DR-118.3 · Blockaden** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: Reaktion ist blockierbar
  - Option B: nicht blockierbar
  - Auswirkung: Balance: gering; Umsetzung: Blockadeprüfung in Reaktion
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Gilt die Rettung (DE) und wird EN angepasst? (2) Bei mehreren Nachtopfern: wählt die Märtyrerin eines, oder nur das Rudelopfer? (3) Nur Rudelangriffe oder auch Sofort-Tode (Hexe, Hades, Verdammniswächter)? (4) Ist die Reaktion durch Albtraum/Schattenhund/Der-Weise-Debuff blockierbar? (5) Wird das Opfer nur angeboten, wenn der Tod nach Schutz tatsächlich eintritt?
- **Charge:** K5. **In Option (nicht freigegeben):** keiner.

## RM-DR-119 · `dorfwache`

- **Status des Eintrags:** später (ab Charge K5).
- **Betroffene Rollen:** `dorfwache`; Wechselwirkung laut Dossier: Werwolf/Rudel, Seuchenwolf, Rudelvater, Giftwolf, Schicksalswolf, Rachsüchtiger Wolf, Schutzengel, Märtyrerin, Seelentauscher (Rollenwechsel in der …
- **Belege:** [Dossier](dossiers/village-2.md#dorfwache); RM-C-112, RM-C-113 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-004, RM-DR-005.
- **RM-DR-119.1 · Giftwolf** · Status: später (K5)
  - Option A: Giftwolf ist Werwolf → immun
  - Option B: nur Rudelangriff zählt
  - Auswirkung: Balance: Giftwolf-Ladung auf Dorfwache verschwendet oder tödlich; Umsetzung: Filter `is_wolf_attack` muss Giftwolf einordnen
  - Empfehlung: PO
- **RM-DR-119.2 · Seuchenwolf/Rudelvater** · Status: später (K5)
  - Option A: Immunität ist "Schutz" → wird durchdrungen
  - Option B: Immunität ist Rolleneigenschaft → hält
  - Auswirkung: Balance: selten, aber spielentscheidend; Umsetzung: Kennzeichnung "ignoriert Immunität"
  - Empfehlung: Code (Text der Dorfwache ergänzen)
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Ist die Dorfwache gegen Giftwolf-Giftpranken immun? (2) Durchdringen Seuchenwolf-Pierce und Rudelvater-Zweitangriff die Immunität (Legacy: ja)? (3) Verbraucht ein Rudelangriff auf die Dorfwache ihren Schutzengel-Schild? (4) Erfährt jemand, dass der Angriff abgewehrt wurde?
- **Charge:** K5. **In Option (nicht freigegeben):** A.

## RM-DR-120 · `pestbringerin`

- **Status des Eintrags:** später (ab Charge K9).
- **Betroffene Rollen:** `pestbringerin`; Wechselwirkung laut Dossier: Zeitwächter (friert Ausbreitung ein), Kutscher/Frankenstein (Wiederbelebung löscht Marker), Rotkäppchen (zweiter Einsatz pro Nacht), Die Ewigen, Wolfsparität (konkurrierender …
- **Belege:** [Dossier](dossiers/solos-a.md#pestbringerin); RM-C-044, RM-C-045, RM-C-046, RM-C-047 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-003, RM-DR-006, RM-DR-007, RM-DR-015.
- **RM-DR-120.1 · Tödlichkeit** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: Code: Marker ohne Tod, Sieg bei Totalinfektion
  - Option B: Text: Seuche tötet (Zeitpunkt offen)
  - Auswirkung: Balance: A ist ein Siegrennen, B eine Tötungsrolle; Umsetzung: A einfach; B braucht verzögerte Tode
  - Empfehlung: A (07-Vorschlag), Text anpassen
- **RM-DR-120.2 · Häufigkeit** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: Code
  - Option B: Text (jede Nacht neu)
  - Auswirkung: Balance: B beschleunigt Sieg stark; Umsetzung: Zähler
  - Empfehlung: Code
- **RM-DR-120.3 · Siegbedingung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: nur lebend
  - Option B: auch tot
  - Auswirkung: Balance: B erlaubt „posthumen" Sieg; Umsetzung: Kandidat nur bei lebender Pestbringerin
  - Empfehlung: lebend verlangen
- **RM-DR-120.4 · Ausbreitung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: direkte Sitze
  - Option B: nächste lebende Nachbarn
  - Auswirkung: Balance: Tote Nachbarn bremsen A; Umsetzung: Sitznachbarschaft + SeededRng
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Tötet die Seuche (Text) oder nicht (Code)? (2) Einsätze: 2 pro Partie oder jede Nacht? (3) Ausbreitung auf direkte Sitze oder nächste lebende Nachbarn, zufällig oder SL-Wahl? (4) Sieg nur, wenn die Pestbringerin lebt? Muss sie sich selbst infizieren? (5) Einsatzzähler pro Person oder global?
- **Charge:** K9. **In Option (nicht freigegeben):** keiner.

## RM-DR-121 · `prophet-des-untergangs`

- **Status des Eintrags:** später (ab Charge K9).
- **Betroffene Rollen:** `prophet-des-untergangs`; Wechselwirkung laut Dossier: alle Tötungsrollen (Freischaltung), Kutscher/Frankenstein (Wiederbelebung), Lehrling/Seelentauscher (Erbe des globalen Zustands), Rotkäppchen (zwei Tötungen), Schilde (Nekromant, Hades, Kartenschlucker, Rudelvater), Die …
- **Belege:** [Dossier](dossiers/solos-a.md#prophet-des-untergangs); RM-C-048, RM-C-049, RM-C-050 in [`04`](04-rule-conflicts.md). Legacy-Befund `not-found`.
- **Querschnittsbezug:** RM-DR-006, RM-DR-007, RM-DR-014.
- **RM-DR-121.1 · Einzelsieg** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: Sieg als letzter Überlebender (bzw. letzte Nicht-Prophet-Person tot)
  - Option B: Sieg, sobald freigeschaltet und X weitere Tote
  - Auswirkung: Balance: Ohne Regel ist die Rolle faktisch Dorf-Hilfe; Umsetzung: neue Siegbedingung
  - Empfehlung: PO definieren (07 Q4 B: SL-Siegbutton bis dahin)
- **RM-DR-121.2 · Freischaltung dauerhaft** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: dauerhaft
  - Option B: solange alle tot
  - Auswirkung: Balance: selten; Umsetzung: Status speichern
  - Empfehlung: dauerhaft
- **RM-DR-121.3 · Selbstmarkierung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: nur andere
  - Option B: beliebig
  - Auswirkung: Balance: Selbstmarkierung macht Freischaltung unmöglich; Umsetzung: Filter
  - Empfehlung: nur andere
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Wann genau gewinnt der Prophet alleine? (2) Darf er sich selbst oder Tote markieren? Markieren nur in Nacht 1? (3) Bleibt die Freischaltung nach Wiederbelebung eines Markierten? (4) Soll die Prophet-Tötung von Schutzengel/Dorfwache geblockt werden? (5) Gewinnt das Dorf, wenn alle Wölfe tot sind, der freigeschaltete Prophet aber lebt?
- **Charge:** K9. **In Option (nicht freigegeben):** keiner.

## RM-DR-122 · `daemonischer-wolf`

- **Status des Eintrags:** später (ab Charge K12).
- **Betroffene Rollen:** `daemonischer-wolf`; Wechselwirkung laut Dossier: Orakel, Blutpriester, Waldläufer, Doktor, Detektiv, Kopfgeldjäger, Ritter, Dorfschmied, Traumdeuter (alle `isWolf`-Leser); Seelentauscher und Wächter am Tor (löschen Fluch); Nekromant …
- **Belege:** [Dossier](dossiers/wolves-b.md#daemonischer-wolf); RM-C-022, RM-C-023, RM-C-024 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-009.
- **RM-DR-122.1 · Auslöser** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: Die Opfer des Rudels werden verflucht (dann sind sie aber tot)
  - Option B: Beim eigenen Tod verflucht er ein Opfer seiner Wahl
  - Auswirkung: Balance: hoch: laufender Fluch vs. einmaliger Todesfluch; Umsetzung: Nachtschritt vs. Todesreaktion
  - Empfehlung: Todesreaktion (Code) übernehmen, Text präzisieren
- **RM-DR-122.2 · Wirkung des Fluchs** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: nur `appears_as` (Informationsrollen)
  - Option B: echter Fraktionswechsel für Parität
  - Auswirkung: Balance: sehr hoch: Dorf kann ohne echten Wolf nicht gewinnen; Umsetzung: Godot `appears_as` vs. `counts_as_wolf`
  - Empfehlung: nur `appears_as`
- **RM-DR-122.3 · Todespfade** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: jeder Tod löst Fluch aus
  - Option B: nur Wolfsangriff und Lynch
  - Auswirkung: Balance: mittel; Umsetzung: Reaktion an KillPipeline für alle Ursachen
  - Empfehlung: jeder Tod
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Auslöser: eigener Tod (Code) oder laufender Fluch auf Rudelopfer (Textwortlaut)? 2. Wirkung: nur Erscheinung für Informationsrollen oder echte Wolfszählung? 3. Löst jede Todesart den Fluch aus oder nur Nachtangriff und Lynch? 4. Ist der Fluch Pflicht oder darf verzichtet werden? 5. Welche Rollen sehen den Fluch (Orakel ja; Doktor, Waldläufer, Detektiv, Ritter, Schmied?)?
- **Charge:** K12. **In Option (nicht freigegeben):** keiner.

## RM-DR-123 · `schattenhund`

- **Status des Eintrags:** später (ab Charge K8).
- **Betroffene Rollen:** `schattenhund`; Wechselwirkung laut Dossier: alle Dorf-Nachtrollen; Wolfskind und Lehrling (Begründung der Nacht-1-Sperre); Albtraumwolf, Zeitwächter, Der Weise (gleiche …
- **Belege:** [Dossier](dossiers/wolves-b.md#schattenhund); RM-C-025, RM-C-026, RM-C-027 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-010, RM-DR-014.
- **RM-DR-123.1 · Betroffene Rollen** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: nur Fraktion Dorf
  - Option B: alle Nicht-Wölfe
  - Auswirkung: Balance: mittel: Solos werden mitblockiert; Umsetzung: Filter über Fraktion statt "nicht Wolf"
  - Empfehlung: nur Dorf
- **RM-DR-123.2 · Nacht 1** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: Einsatz ab Nacht 1
  - Option B: ab Nacht 2
  - Auswirkung: Balance: gering; Umsetzung: Verfügbarkeitsbedingung des Schritts
  - Empfehlung: ab Nacht 2, Text ergänzen
- **RM-DR-123.3 · Nicht-Nachtschritt-Effekte** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: nur Nachtschritte
  - Option B: auch Reaktionen/passive Effekte dieser Nacht
  - Auswirkung: Balance: mittel; Umsetzung: Blockade als Schritt-Status oder als globale Regel
  - Empfehlung: nur Nachtschritte, Text präzisieren
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Nur Dorf oder alle Nicht-Wölfe? 2. Ab Nacht 1 oder ab Nacht 2? 3. Werden auch Morgenreaktionen (Märtyrerin, Schmiede-Waffe) und Todesreaktionen in dieser Nacht blockiert? 4. Teilen mehrere Schattenhunde einen Einsatz?
- **Charge:** K8. **In Option (nicht freigegeben):** B.

## RM-DR-124 · `besessener-wolf`

- **Status des Eintrags:** später (ab Charge K4).
- **Betroffene Rollen:** `besessener-wolf`; Wechselwirkung laut Dossier: Loki (Liebeskummer-Pfad), Schwarze Witwe und Giftwolf (Morgen-Tode), Dämonischer Wolf (Reihenfolge), Rudelvater, Nekromant, Kartenschlucker, Hades, Schattenwanderer, Parasit …
- **Belege:** [Dossier](dossiers/wolves-b.md#besessener-wolf); RM-C-028 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-004, RM-DR-009.
- **RM-DR-124.1 · Schwelle "≥5 Spieler"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 3 27.09.2026
  - Option A: 5 Lebende inkl. ihm im Todesmoment
  - Option B: 5 Spieler bei Spielbeginn
  - Auswirkung: Balance: mittel im Endspiel; Umsetzung: Prüfzeitpunkt (Tod vs. Abarbeitung)
  - Empfehlung: lebende inkl. ihm im Todesmoment, keine Neuprüfung
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Schwelle: 5 Lebende inkl. ihm im Todesmoment oder zum Abarbeitungszeitpunkt? 2. Ist die Mitnahme Pflicht oder darf verzichtet werden? 3. Dürfen Wölfe mitgerissen werden (Code: ja)? 4. Greifen Schilde gegen die Mitnahme (Code: ja)?
- **Charge:** K4. **In Option (nicht freigegeben):** A.

## RM-DR-125 · `fenrir`

- **Status des Eintrags:** später (ab Charge K4).
- **Betroffene Rollen:** `fenrir`; Wechselwirkung laut Dossier: Ritter, Henker (LynchCount), Feuerteufel (Brand), Lehrling/Seelentauscher/Frankenstein (Rollenerwerb mit alter Stufe), alle …
- **Belege:** [Dossier](dossiers/wolves-b.md#fenrir); RM-C-029, RM-C-030, RM-C-031 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-011.
- **RM-DR-125.1 · Umfang des Überlebens** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: jede Todesursache, einmal
  - Option B: nur Hinrichtung
  - Auswirkung: Balance: hoch: Nachtangriffe kann Wolf-Team nicht wählen, aber Witwe/Hexe/Hades sehr wohl; Umsetzung: Abfangregel in KillPipeline vs. ExecutionRules
  - Empfehlung: jede Ursache (Text)
- **RM-DR-125.2 · Zählung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: +1 am Morgen nach überlebter Nacht
  - Option B: +1 bei Nachtbeginn
  - Auswirkung: Balance: gering (eine Nacht früher Stufe 3); Umsetzung: Zeitpunkt DAWN vs. NIGHT_START
  - Empfehlung: +1 am Morgen, wenn Fenrir lebt
- **RM-DR-125.3 · Ritter** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: Teil von "jeder Tod" (einmal)
  - Option B: Sonderimmunität
  - Auswirkung: Balance: mittel; Umsetzung: Ritter-Zielauswahl
  - Empfehlung: an Einmal-Schutz koppeln
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Überlebt Fenrir jede Todesursache oder nur Hinrichtung? 2. Zählt die Stufe bei Nachtbeginn oder nach überlebter Nacht? 3. Ist Fenrir ab Stufe 3 für den Ritter immun, und wenn ja, dauerhaft oder als Teil des Einmal-Schutzes? 4. Zählt ein abgewehrter Lynch als Lynch (Henker, Log)? 5. Soll die Stufe für den SL sichtbar sein?
- **Charge:** K4. **In Option (nicht freigegeben):** keiner.

## RM-DR-126 · `kutscher`

- **Status des Eintrags:** später (ab Charge K13).
- **Betroffene Rollen:** `kutscher`; Wechselwirkung laut Dossier: Wächter am Tor, Werwolf/Rudel, alle Rollen im Pool, Totenkarten (4 revive-Karten), Prophet des Untergangs (Ziele), Schicksalswolf (`FirstThreeDeadIds`), Seelentauscher/Lehrling …
- **Belege:** [Dossier](dossiers/village-2.md#kutscher); RM-C-114, RM-C-115, RM-C-117 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-011, RM-DR-013, RM-DR-015.
- **RM-DR-126.1 · Rollen der Wiederbelebten** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wiederbelebungsrollen 28.09.2026
  - Option A: echte Wiederbelebung, alte Rolle bleibt (außer Wolf)
  - Option B: "Nachbardorf" bringt neue Personen mit neuen Rollen (Code, Dialogtext)
  - Auswirkung: Balance: neue Solo-Rollen mitten im Spiel können Sieglage kippen; Umsetzung: Rollenpool, Fraktionszuordnung, Siegbedingungen neuer Solos
  - Empfehlung: PO; wenn Code: Pool auf Dorfrollen des Akts begrenzen
- **RM-DR-126.2 · Wer wählt die Toten** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wiederbelebungsrollen 28.09.2026
  - Option A: Kutscher/SL wählt
  - Option B: Zufall (SeededRng)
  - Auswirkung: Balance: Wahl macht Rolle stärker; Umsetzung: Prompt vs. RNG
  - Empfehlung: PO
- **RM-DR-126.3 · Einmaligkeit** · Status: entschieden; Quelle: rules-register G-ID-3; Einmal-Fähigkeiten pro Person und Rolle
  - Option A: einmal pro Partie
  - Option B: einmal pro Person
  - Auswirkung: Balance: Rollenerbe verdoppelt Effekt; Umsetzung: `ability_uses` pro Person
  - Empfehlung: einmal pro Person, Text ergänzen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Behalten Wiederbelebte ihre Rolle, oder kommen "neue Personen aus dem Nachbardorf" mit neuen Rollen? (2) Wer wählt die drei Toten: Zufall, Kutscher oder SL? (3) Aus welchem Pool kommen neue Rollen (nur Dorf, nur Akt)? (4) Wer wird Wolf: Zufall oder Wahl? (5) Einmal pro Partie oder pro Person, und setzt Rollenerbe den Verbrauch zurück? (6) Was passiert mit Totenkarten und Bindungen der Wiederbelebten? (7) Zählt die Schwelle 10 alle Toten (Legacy: ja)?
- **Charge:** K13. **In Option (nicht freigegeben):** keiner.

## RM-DR-127 · `seelentauscher`

- **Status des Eintrags:** später (ab Charge K12).
- **Betroffene Rollen:** `seelentauscher`; Wechselwirkung laut Dossier: alle Rollen (tauschbar), insbesondere Wolfsrollen, Wächter am Tor, Wolfskind/Lehrling (Bindungen), Loki/Rotkäppchen/Parasit (Sitz-Bindungen), Dorfwache/Märtyrerin (Rollenprüfung am Morgen), Kutscher/Blutpriester …
- **Belege:** [Dossier](dossiers/village-2.md#seelentauscher); RM-C-119, RM-C-120, RM-C-121 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-014.
- **RM-DR-127.1 · Was wandert mit** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: Rolle inkl. Rollenzustand (Verbrauch, Bindungen) wandert
  - Option B: nur Rollenname, Zustand bleibt
  - Auswirkung: Balance: Tausch von verbrauchten Rollen; Umsetzung: RoleTransition-Schnappschuss definiert
  - Empfehlung: PO
- **RM-DR-127.2 · Toter erhält Wolfsrolle** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: erlaubt
  - Option B: Wächter-Prüfung auch für Tote
  - Auswirkung: Balance: gering (tot), relevant bei Wiederbelebung; Umsetzung: Wächter-Regel auf alle Rollenwechsel
  - Empfehlung: Wächter-Prüfung auch bei Wiederbelebung
- **RM-DR-127.3 · Information der Betroffenen** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Verwandlungsrollen 28.09.2026
  - Option A: Betroffene erfahren neue Rolle
  - Option B: geheim
  - Auswirkung: Balance: hoch (Spieler kennt eigene Rolle nicht); Umsetzung: InfoRecord an Betroffene
  - Empfehlung: A
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Wandert der Rollenzustand (Verbrauch, Vorbild, Mentor, Schild) mit der Rolle oder bleibt er an der Person? (2) Erfahren die Getauschten ihre neue Rolle, und wann? (3) Darf der Seelentauscher sich selbst tauschen? (4) Gilt Wächter am Tor auch für tote Empfänger einer Wolfsrolle? (5) Bleiben Liebes-/Bindungsmarker am Sitz?
- **Charge:** K12. **In Option (nicht freigegeben):** keiner.

## RM-DR-128 · `blutpriester`

- **Status des Eintrags:** später (ab Charge K7).
- **Betroffene Rollen:** `blutpriester`; Wechselwirkung laut Dossier: Rudelvater, Nekromant, Hades, Kartenschlucker, Parasit, Schattenwanderer (Todesabfang), Dämonischer Wolf (`cursedWolfAura` zählt als Wolf), Doppelspion (nicht Wolf), Sensenträger (Reaktion auf Opfer), Seelentauscher …
- **Belege:** [Dossier](dossiers/village-2.md#blutpriester); RM-C-122, RM-C-123 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-014, RM-DR-015.
- **RM-DR-128.1 · Anzahl 0–3** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: SL entscheidet
  - Option B: Anzahl aus Regel (z. B. Zufall oder Rolle des Opfers)
  - Auswirkung: Balance: SL-Willkür vs. Planbarkeit; Umsetzung: Prompt vs. RNG
  - Empfehlung: PO; Legacy (SL wählt) beibehalten ist einfach
- **RM-DR-128.2 · Wer sieht das Ergebnis** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: öffentlich (aufdecken)
  - Option B: nur Blutpriester
  - Auswirkung: Balance: groß (öffentliche Wolfsnennung); Umsetzung: Ereignis-Sichtbarkeit public vs. actor
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Wer bestimmt die Anzahl 0 bis 3 (SL frei, Zufall, Regel)? (2) Ist die Aufdeckung öffentlich oder nur für den Blutpriester? (3) Zählen verfluchte Dorfbewohner (erscheinen als Wolf) und Trugbilderwolf-Erscheinung? (4) Verbraucht ein abgefangener Tod die Fähigkeit? (5) Darf er sich selbst opfern?
- **Charge:** K7. **In Option (nicht freigegeben):** keiner.

## RM-DR-129 · `traumdeuter`

- **Status des Eintrags:** später (ab Charge K7).
- **Betroffene Rollen:** `traumdeuter`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (Fluch), Trugbilderwolf (Erscheinung), Doppelspion, Albtraumwolf/Schattenhund/Zeitwächter/Der Weise …
- **Belege:** [Dossier](dossiers/village-2.md#traumdeuter); RM-C-125, RM-C-126, RM-C-127 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-015.
- **RM-DR-129.1 · Inhalt der Vision** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: Code übernehmen, Text präzisieren
  - Option B: eigene Mechanik (Rollen/Zustände)
  - Auswirkung: Balance: Code: starke Info jede Nacht; Umsetzung: A: kleiner Aufwand; B: neue Spezifikation
  - Empfehlung: A mit Textanpassung
- **RM-DR-129.2 · Selbst in der Vision** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: ausschließen
  - Option B: erlaubt
  - Auswirkung: Balance: Selbstnennung ist verschwendete Info; Umsetzung: Filter
  - Empfehlung: ausschließen
- **RM-DR-129.3 · Verfluchte als Wolf** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: Erscheinung zählt (Fehlinformation)
  - Option B: nur echte Wölfe
  - Auswirkung: Balance: beeinflusst Dämonischen Wolf; Umsetzung: InformationRules.determine
  - Empfehlung: Erscheinung zählt
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Code-Mechanik übernehmen und Text anpassen oder neue Mechanik? (2) Darf der Traumdeuter sich selbst in der Vision sehen? (3) Zählt Erscheinung (Fluch, Trugbild) oder wahre Fraktion? (4) Was, wenn weniger als 2 Nicht-Wölfe leben?
- **Charge:** K7. **In Option (nicht freigegeben):** keiner.

## RM-DR-130 · `henker`

- **Status des Eintrags:** später (ab Charge K4).
- **Betroffene Rollen:** `henker`; Wechselwirkung laut Dossier: alle Lynch-Sonderzweige (Wahnsinniger Kutscher, Voodoo, Der Weise, Selbstmörder, Spiegelwolf, Dämonischer Wolf, Fenrir, Cerberus, Rudelvater), Rudelvater/Nekromant/Hades/Kartenschlucker/Parasit …
- **Belege:** [Dossier](dossiers/village-2.md#henker); RM-C-129, RM-C-130, RM-C-131 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **RM-DR-130.1 · Blockierter Lynch (Fenrir/Cerberus)** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: blockierter Lynch zählt als Lynch
  - Option B: zählt nicht (kein Tod)
  - Auswirkung: Balance: beeinflusst Aktivierung und Markierten; Umsetzung: ExecutionRules-Ergebnis "verhindert"
  - Empfehlung: PO bestätigen, 07 geht von A aus
- **RM-DR-130.2 · Zählbasis** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: Vorgänge
  - Option B: nur Lynch-Tote
  - Auswirkung: Balance: Spiegelwolf/Voodoo-Tage; Umsetzung: Zähler-Definition
  - Empfehlung: Vorgänge, i18n anpassen
- **RM-DR-130.3 · Henker tot** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: wirkt weiter
  - Option B: verfällt mit Henker
  - Auswirkung: Balance: gering; Umsetzung: Bindung Markierung↔Henker
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Zählt ein durch Fenrir/Cerberus verhinderter Lynch (Zählung und Vollstreckung)? (2) Zählen Lynch-Vorgänge oder nur Lynch-Tote? (3) Verfällt die Markierung, wenn am Folgetag nicht gelyncht wird, oder bleibt sie bis zum nächsten Lynch? (4) Wirkt die Markierung nach dem Tod des Henkers weiter? (5) Darf der Henker sich selbst markieren? (6) Ist die Markierung öffentlich?
- **Charge:** K4. **In Option (nicht freigegeben):** keiner.

## RM-DR-131 · `feuerteufel`

- **Status des Eintrags:** später (ab Charge K9).
- **Betroffene Rollen:** `feuerteufel`; Wechselwirkung laut Dossier: Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Albtraumwolf (Blockade), Der Weise, Dorfschmied, Nekromant, Waldhexe, Märtyrerin, Voodoo-Priester, Dorfwache (Überleben/Entfernen aus Zielen), …
- **Belege:** [Dossier](dossiers/solos-a.md#feuerteufel); RM-C-051, RM-C-052, RM-C-053, RM-C-054, RM-C-055 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-003, RM-DR-006, RM-DR-007, RM-DR-009.
- **RM-DR-131.1 · Auslöser** · Status: später (K9)
  - Option A: jeder tatsächliche Tod, jede Ursache
  - Option B: nur Wolfsangriff und Hinrichtung, aber nur bei Tod
  - Auswirkung: Balance: A stärker; Umsetzung: Todesreaktion in KillPipeline
  - Empfehlung: A oder B, jeweils nur bei Tod
- **RM-DR-131.2 · Dauer der Markierung** · Status: später (K9)
  - Option A: bis Ziel stirbt
  - Option B: nur diese Nacht
  - Auswirkung: Balance: A viel stärker; Umsetzung: Statusmarker mit Ablauf
  - Empfehlung: PO
- **RM-DR-131.3 · Nachbarn** · Status: später (K9)
  - Option A: direkte Sitze
  - Option B: nächste Lebende
  - Auswirkung: Balance: B tötet immer 2; Umsetzung: Sitznachbarschaft
  - Empfehlung: analog Wahnsinniger Kutscher
- **RM-DR-131.4 · Feuerteufel als Nachbar** · Status: später (K9)
  - Option A: immer verschont
  - Option B: nie verschont
  - Auswirkung: Balance: –; Umsetzung: Filter
  - Empfehlung: einheitlich
- **RM-DR-131.5 · Siegbedingung** · Status: später (K9)
  - Option A: Einzelsieg definieren
  - Option B: Fraktion ändern (Dorf-Chaos-Rolle)
  - Auswirkung: Balance: –; Umsetzung: WinRules
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Brand bei jedem Tod des Ziels oder nur Nacht/Hinrichtung? (2) Wie lange gilt die Markierung? (3) Direkte oder lebende Nachbarn? (4) Stirbt der Feuerteufel, wenn er Nachbar ist? (5) Welche Siegbedingung, oder gehört die Rolle nicht zur Einzelsiegfraktion? (6) Kettenbrand, wenn ein verbrannter Nachbar selbst markiert ist?
- **Charge:** K9. **In Option (nicht freigegeben):** keiner.

## RM-DR-132 · `voodoo-priester`

- **Status des Eintrags:** quellenprüfung.
- **Betroffene Rollen:** `voodoo-priester`; Wechselwirkung laut Dossier: Wolfsrudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater (Nachtziele), Waldhexe (Gift), Märtyrerin, Der Weise, Dorfschmied, Nekromant (Reihenfolge der Abfangregeln), Rattenfänger (Verzauberung), Feuerteufel (Brand …
- **Belege:** [Dossier](dossiers/solos-a.md#voodoo-priester); RM-C-056, RM-C-057, RM-C-058, RM-C-059 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-006, RM-DR-007.
- **RM-DR-132.1 · Ursachen der Umlenkung** · Status: später (K10)
  - Option A: jede Todesursache
  - Option B: nur Angriffe (Wolf, Hinrichtung, Gift)
  - Auswirkung: Balance: A macht ihn sehr robust; Umsetzung: Umlenkungsregel mit Ursachenfilter in KillPipeline
  - Empfehlung: PO
- **RM-DR-132.2 · Abklingzeit** · Status: später (K10)
  - Option A: Code übernehmen, Text ergänzen
  - Option B: keine Abklingzeit
  - Auswirkung: Balance: ohne Abklingzeit endloser Schutz; Umsetzung: Zähler
  - Empfehlung: Code
- **RM-DR-132.3 · Verzauberung löschen** · Status: quellenprüfung; ob die Legacy-Wechselwirkung beabsichtigt ist, ist aus Quellen nicht belegbar
  - Option A: Altlast
  - Option B: gewollt
  - Auswirkung: Balance: Rattenfänger-Konter; Umsetzung: –
  - Empfehlung: streichen
- **RM-DR-132.4 · Siegbedingung** · Status: später (K10)
  - Option A: Einzelsieg definieren
  - Option B: Fraktion ändern
  - Auswirkung: Balance: –; Umsetzung: WinRules
  - Empfehlung: PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Welche Todesursachen lenkt die Puppe um? (2) Abklingzeit übernehmen, wie lang, auch nach normalem Tod der Puppe? (3) Darf der Priester sich selbst die Puppe geben? (4) Verliert der Puppenträger Verzauberung? (5) Weiß der Puppenträger von der Puppe? (6) Siegbedingung oder Fraktionswechsel? (7) Umlenkung vor oder nach Märtyrerin/Der Weise/Schmied?
- **Charge:** K10. **In Option (nicht freigegeben):** keiner.

## RM-DR-133 · `blutwolf`

- **Status des Eintrags:** später (ab Charge K14).
- **Betroffene Rollen:** `blutwolf`; Wechselwirkung laut Dossier: alle Tötungen neben dem Blutwolf; indirekt Korrupter Richter und Hades (gleiche …
- **Belege:** [Dossier](dossiers/wolves-b.md#blutwolf). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-003, RM-DR-008.
- **RM-DR-133.1 · Umsetzung ohne Stimmsystem** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 5 28.09.2026
  - Option A: Gewicht als Hinweis für die physische Zählung anzeigen (Legacy-Marker „V<n>“)
  - Option B: Rolle bis zu einem Stimmsystem zurückstellen
  - Auswirkung: Balance: –; Umsetzung: A: Sitznachbarschaft (RM-DR-003) und Anzeige
  - Empfehlung: siehe RM-DR-008
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Reicht eine SL-Anzeige des Gewichts (ohne Stimmerfassung)? 2. Zählen tote Nachbarn, auch wenn später wiederbelebt (live berechnet)? 3. Gilt das Gewicht auch, wenn der Blutwolf tot ist und Tote abstimmen dürfen (Nekromant-Kontext)?
- **Charge:** K14. **In Option (nicht freigegeben):** keiner.

## RM-DR-134 · `albtraumwolf`

- **Status des Eintrags:** später (ab Charge K8).
- **Betroffene Rollen:** `albtraumwolf`; Wechselwirkung laut Dossier: alle Nicht-Wolf-Nachtrollen mit tier > 2.1; Schattenhund/Zeitwächter/Der Weise (gleiche Blockadefamilie); Dämonischer Wolf (Verfluchte nicht wählbar); Rudel …
- **Belege:** [Dossier](dossiers/wolves-b.md#albtraumwolf); RM-C-033, RM-C-034, RM-C-036 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-010.
- **RM-DR-134.1 · Ziele** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: nur Fraktion Dorf
  - Option B: alle Nicht-Wölfe
  - Auswirkung: Balance: mittel; Umsetzung: Zielfilter
  - Empfehlung: alle Nicht-Wölfe (Solos sind Gegner der Wölfe), Text anpassen
- **RM-DR-134.2 · Umfang** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: nur die gewählte Person
  - Option B: alle Personen der Rolle
  - Auswirkung: Balance: mittel bei Mehrfachrollen; Umsetzung: Blockade pro Person vs. pro Rolle
  - Empfehlung: nur die Person
- **RM-DR-134.3 · Späte Wirkung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wolfsrollen 28.09.2026
  - Option A: Albtraumwolf handelt vor Dorfrollen
  - Option B: Blockade nur für spätere Schritte
  - Auswirkung: Balance: mittel: Schutzengel nie blockierbar; Umsetzung: Nachtreihenfolge
  - Empfehlung: tier vor Gruppe B verschieben oder Text präzisieren
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Dürfen Solos blockiert werden? 2. Person oder ganze Rolle? 3. Soll der Albtraumwolf vor den Dorf-Schutzrollen handeln (tier), damit Schutzengel blockierbar ist? 4. Wirkt eine Blockade auch auf Morgen- und Todesreaktionen der Person?
- **Charge:** K8. **In Option (nicht freigegeben):** keiner.

## RM-DR-135 · `cerberus`

- **Status des Eintrags:** später (ab Charge K4).
- **Betroffene Rollen:** `cerberus`; Wechselwirkung laut Dossier: Waldhexe (Trank), Henker (LynchCount), Feuerteufel (Brand beim Lynch), Kopfgeldjäger (Lynch eines Wolfs), Spiegelwolf/Voodoo/Der Weise (Reihenfolge der Lynch-Sonderzweige …
- **Belege:** [Dossier](dossiers/wolves-b.md#cerberus); RM-C-037, RM-C-038 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **RM-DR-135.1 · Wahl oder Automatik** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: Cerberus entscheidet (Prompt)
  - Option B: automatisch
  - Auswirkung: Balance: mittel: Wahl erlaubt Bluff/Aufsparen; Umsetzung: Prompt in ExecutionRules
  - Empfehlung: Prompt an SL "Cerberus wehrt ab?"
- **RM-DR-135.2 · Hexengift** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: nur Lynch
  - Option B: jede Hinrichtung/gezielte Tötung
  - Auswirkung: Balance: mittel; Umsetzung: zusätzliche Abfangregel
  - Empfehlung: nur Lynch (Text)
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Automatische Abwehr oder Wahl? 2. Auch gegen Hexengift oder andere gezielte Tötungen? 3. Zählt eine abgewehrte Lynchung für Henker/Log als Lynch? 4. Darf am selben Tag nach einer Abwehr erneut gelyncht werden? 5. Köpfe pro Nachtbeginn oder pro überlebter Nacht?
- **Charge:** K4. **In Option (nicht freigegeben):** B.

## RM-DR-136 · `ritter`

- **Status des Eintrags:** später (ab Charge K3).
- **Betroffene Rollen:** `ritter`; Wechselwirkung laut Dossier: Dämonischer Wolf (Verfluchte), Fenrir, Rudelvater (Ersttod-Rettung, PACKFATHER_KILL), Schattenwanderer (Umlenkung), Zeitwächter, Waldhexe, Hades, Schwarze Witwe, Giftwolf, Feuerteufel, Kartenschlucker, Nekromant-Schild, …
- **Belege:** [Dossier](dossiers/village-3.md#ritter); RM-C-132, RM-C-133, RM-C-134 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-003, RM-DR-004, RM-DR-009.
- **RM-DR-136.1 · Welche Nachttode lösen aus** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 3 27.09.2026
  - Option A: jeder Tod in der Nacht löst aus
  - Option B: nur Tode durch feindliche Nachtangriffe (Liste, ggf. erweitert um PACKFATHER_KILL)
  - Auswirkung: Balance: A stärkt das Dorf deutlich (auch Kettentode schlagen zurück); Umsetzung: Ursachen-Attribut `triggers_knight` in beiden Fällen nötig, nur Belegung unterscheidet sich
  - Empfehlung: B mit Ergänzung PACKFATHER_KILL und VOODOO_PUPPET, Text präzisieren
- **RM-DR-136.2 · Verfluchter Dorfbewohner als Ziel** · Status: später (K3)
  - Option A: nur echte Wölfe
  - Option B: alles, was als Wolf zählt
  - Auswirkung: Balance: A schützt Verfluchte; Umsetzung: Ziel über `counts_as_wolf` statt `appears_as`
  - Empfehlung: hängt an Q1 Dämonischer Wolf; bei "nur Erscheinung" nur echte Wölfe
- **RM-DR-136.3 · Fenrir ab Stufe 3** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: Fenrir-Immunität gilt auch gegen Ritter
  - Option B: Ritter trifft Fenrir normal
  - Auswirkung: Balance: gering; Umsetzung: Sonderregel im Zielfinder
  - Empfehlung: nach Fenrir-Entscheidung (07 Q1 Fenrir-Zeile) ausrichten
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Löst jeder Tod in der Nacht aus oder nur eine Ursachenliste? Gehören PACKFATHER_KILL und VOODOO_PUPPET dazu? 2. Darf der Ritter einen nur verfluchten Dorfbewohner treffen? 3. Gleichstand links/rechts: welche Richtung (aus Sicht des Ritters), und soll der SL wählen? 4. Ist Fenrir ab Stufe 3 gegen den Ritter immun? 5. Wird die Vergeltung nach Wiederbelebung erneut verfügbar? 6. Wirkt die Rudelvater-Ersttod-Rettung gegen den Ritter-Schlag?
- **Charge:** K3. **In Option (nicht freigegeben):** A.

## RM-DR-137 · `rotkaeppchen`

- **Status des Eintrags:** später (ab Charge K10).
- **Betroffene Rollen:** `rotkaeppchen`; Wechselwirkung laut Dossier: alle Rollen mit Nachtfähigkeit (Apfel), König/Frankenstein/Dorfschmied/Pestbringerin/Prophet (`APPLE_RESET_FLAGS`), Seelentauscher, Parasit, Kartenschlucker/Hades/Nekromant (Schilde), Ritter (Kettentod löst keine …
- **Belege:** [Dossier](dossiers/village-3.md#rotkaeppchen); RM-C-135, RM-C-136, RM-C-137, RM-C-138, RM-C-139 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-009, RM-DR-011.
- **RM-DR-137.1 · Wölfe als Zuflucht** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: jede andere lebende Person
  - Option B: nur Nicht-Wölfe
  - Auswirkung: Balance: A erlaubt Wolf-Apfel (Doppelkill?) und Wolf-Kette; Umsetzung: Zielfilter
  - Empfehlung: B (Code), Text ergänzen
- **RM-DR-137.2 · Apfel-Wirkung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: jede nächste Fähigkeit (auch Info) zweimal
  - Option B: nur Zielwahl-Fähigkeiten, sonst verfällt der Apfel
  - Auswirkung: Balance: A wertet Info-Rollen stark auf; Umsetzung: "repeat step" in StepQueue plus Verfall-Regel
  - Empfehlung: eigene Regel: Apfel verfällt nach der nächsten eigenen Nachtaktion, Info-Rollen erhalten die Info zweimal oder gar nicht (entscheiden)
- **RM-DR-137.3 · Dauer der Kette** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: nur diese Nacht
  - Option B: bis zur nächsten gewährten Zuflucht
  - Auswirkung: Balance: A schwächt Risiko deutlich; Umsetzung: Bindungsobjekt mit Gültigkeit
  - Empfehlung: B (Code) festschreiben
- **RM-DR-137.4 · Ablehnung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: Ablehnung löst alte Kette
  - Option B: alte Kette bleibt
  - Auswirkung: Balance: gering; Umsetzung: Bindung beenden oder nicht
  - Empfehlung: entscheiden
- **RM-DR-137.5 · Mehrfache Zuflucht beim Selben** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Bindungsrollen 28.09.2026
  - Option A: jede Nacht ein anderer
  - Option B: beliebig
  - Auswirkung: Balance: A verhindert Dauer-Apfel beim selben Spieler; Umsetzung: Zielhistorie
  - Empfehlung: entscheiden
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Dürfen Wölfe Zuflucht gewähren? 2. Wie lange gilt die Todeskette, und endet sie bei Ablehnung? 3. Entsteht die Kette nur bei gewährter Zuflucht? 4. Was bedeutet "doppelt" bei Info-Rollen und passiven Rollen, und verfällt ein ungenutzter Apfel? 5. Darf dieselbe Person mehrmals hintereinander gewählt werden? 6. Wirkt die Kette auch bei Hinrichtung am Tag (Legacy: ja)?
- **Charge:** K10. **In Option (nicht freigegeben):** keiner.

## RM-DR-138 · `selbstmoerder`

- **Status des Eintrags:** produktentscheidung.
- **Betroffene Rollen:** `selbstmoerder`; Wechselwirkung laut Dossier: Feuerteufel (Brand vor Siegprüfung), Henker (Nebenhinrichtung), Voodoo (Puppe), alle Tötungsrollen (Totenzahl), Die …
- **Belege:** [Dossier](dossiers/solos-a.md#selbstmoerder); RM-C-061, RM-C-062 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-007.
- **RM-DR-138.1 · Zählbasis** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit 27.09.2026; Selbstmörder: Zählbasis
  - Option A: vorher (Code/EN)
  - Option B: inklusive eigenem Tod
  - Auswirkung: Balance: B einen Tod früher; Umsetzung: Zählpunkt
  - Empfehlung: A, DE-Text präzisieren
- **RM-DR-138.2 · Hinrichtungsarten** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: nur Hauptziel des Lynchs
  - Option B: auch Henker-Hinrichtung
  - Auswirkung: Balance: –; Umsetzung: ExecutionRules
  - Empfehlung: A
- **RM-DR-138.3 · Wer zählt als tot, wenn Personen wiederbelebt wurden?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit 27.09.2026; neu: wer zählt als tot (Wiederbelebung)
  - Option A: alle Personen, die zum Zeitpunkt der Hinrichtung tot sind (Legacy zählt tote Sitze)
  - Option B: alle Todesfälle der Partie, auch wenn die Person inzwischen wieder lebt
  - Auswirkung: Balance: B macht den Sieg nach Wiederbelebungen leichter; Umsetzung: A: Zählung aus dem Zustand; B: Zählung aus dem Todesprotokoll
  - Empfehlung: A (entspricht Legacy und Text „sobald 5+ Tote sind“)
- **RM-DR-138.4 · Was geschieht mit einem abgelehnten Selbstmörder-Kandidaten?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit 27.09.2026; neu: abgelehnter Kandidat
  - Option A: Er verfällt endgültig; nur eine erneute Hinrichtung derselben Person (nach Wiederbelebung) kann ihn wieder auslösen
  - Option B: Er wird nach jeder späteren Zustandsänderung erneut angeboten
  - Option C: Er bleibt als Hinweis sichtbar, entsteht aber nicht neu; der Spielleiter kann später per `declare_winner` entscheiden
  - Auswirkung: Balance: B würde die Partie nach jedem weiteren Tod erneut unterbrechen; Umsetzung: Der Sieg hängt am Moment der Hinrichtung; ohne Regel würde die heutige Prüfung ihn nach jedem Tod neu erzeugen
  - Empfehlung: A. Ein Moment-Sieg, den der Spielleiter ablehnt, ist erledigt; die allgemeine Regel „erneut nur nach relevanter Zustandsänderung“ (AS-C04) passt auf Zustandsbedingungen, nicht auf ein vergangenes Ereignis
- **RM-DR-138.5 · Stirbt der Selbstmörder durch eine Spiegelung, zählt das als Hinrichtung?** · Status: entschieden; Quelle: rules-register G-TOD-3; DECISION-LOG Spiegelwolf; Tod durch Spiegelung ist keine Hinrichtung des Selbstmörders
  - Option A: nein (bestehende Regeln)
  - Option B: –
  - Auswirkung: Balance: –; Umsetzung: –
  - Empfehlung: entschieden: Ursache `SPIEGELWOLF_RETALIATE`, hingerichtet ist der Spiegelwolf
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Zählt „5+ Tote" vor oder nach seinem Tod? (2) Zählt nur „LYNCH" oder auch Henker/SL-Hinrichtung (DECISION-LOG: SL-Hinrichtung ist `LYNCH`)? (3) Zählen wiederbelebte Personen als Tote (Legacy: nur aktueller Status)?
- **Charge:** K1. **In Option (nicht freigegeben):** A.

## RM-DR-139 · `kopfgeldjaeger`

- **Status des Eintrags:** später (ab Charge K7).
- **Betroffene Rollen:** `kopfgeldjaeger`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (Verfluchte), Spiegelwolf/Fenrir/Cerberus (kein Tod beim Lynch), Der Weise, Lehrling/Seelentauscher, Schattenhund/Albtraumwolf/Zeitwächter (Blockade), Doppelspion (zählt als …
- **Belege:** [Dossier](dossiers/village-3.md#kopfgeldjaeger); RM-C-140, RM-C-141, RM-C-142, RM-C-143 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-015.
- **RM-DR-139.1 · Wiederholung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: eine Info pro Wolfs-Lynch (Zähler)
  - Option B: eine Info in der Nacht nach einem Wolfs-Lynch
  - Auswirkung: Balance: A minimal stärker; Umsetzung: Zähler statt bool
  - Empfehlung: A (Zähler), Texte angleichen
- **RM-DR-139.2 · Selbst unter den drei** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: drei andere Spieler
  - Option B: beliebige lebende
  - Auswirkung: Balance: A gibt mehr Info; Umsetzung: Filter `id != actor`
  - Empfehlung: A
- **RM-DR-139.3 · Aktivierung durch Erbe** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: nur Lynch aktiviert
  - Option B: Erbe startet aktiv
  - Auswirkung: Balance: B schenkt Info; Umsetzung: Rollenwechsel mit frischen Einsätzen ohne Aktivierung
  - Empfehlung: A
- **RM-DR-139.4 · Verfluchter als "Werwolf"** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: nur echte Wölfe
  - Option B: Erscheinung zählt
  - Auswirkung: Balance: hängt an Q1; Umsetzung: `counts_as_wolf` vs `appears_as`
  - Empfehlung: nach Q1
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Eine Info pro Wolfs-Lynch oder eine pro Nacht nach mindestens einem Wolfs-Lynch? 2. Darf der Kopfgeldjäger sich selbst unter den drei sehen? 3. Aktiviert ein Rollenerbe/Tausch sofort? 4. Aktiviert der Lynch eines verfluchten Dorfbewohners? 5. Verfällt die Info, wenn nicht genug Ziele leben, oder bleibt sie erhalten?
- **Charge:** K7. **In Option (nicht freigegeben):** B.

## RM-DR-140 · `koenig`

- **Status des Eintrags:** später (ab Charge K7).
- **Betroffene Rollen:** `koenig`; Wechselwirkung laut Dossier: Wolfskind, Lehrling, Dämonischer Wolf (Verfluchte), Seelentauscher, Rotkäppchen (Apfel), Frankenstein/Kutscher (Wiederbelebung verändert …
- **Belege:** [Dossier](dossiers/village-3.md#koenig); RM-C-144, RM-C-145 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-015.
- **RM-DR-140.1 · Häufigkeit** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: einmal im Spiel
  - Option B: jede Nacht, solange Bedingung gilt
  - Auswirkung: Balance: B ist in der Endphase sehr stark; Umsetzung: Einsatzzähler vs. Nachtbedingung
  - Empfehlung: 07-Vorschlag übernehmen oder A; Texte angleichen
- **RM-DR-140.2 · Wer wird gezeigt** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: SL/Zufall wählt echten Dorf-Angehörigen (Fraktion aktuell)
  - Option B: rollenbasiert (Legacy)
  - Auswirkung: Balance: A verhindert Fehlinfo bei Wolfskind; Umsetzung: `faction` aktuell statt Katalog
  - Empfehlung: A, Zufall über SeededRng
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Einmal im Spiel oder jede Nacht, solange Tote > Lebende? 2. Wählt der Zufall, der SL oder der König selbst? 3. Zählt die aktuelle Fraktion (verwandeltes Wolfskind = Wolf) oder die Startrolle? 4. Zählt ein Unentschieden (Tote = Lebende)? Legacy: nein. 5. Darf dieselbe Person mehrfach gezeigt werden?
- **Charge:** K7. **In Option (nicht freigegeben):** keiner.

## RM-DR-141 · `dr-victor-frankenstein`

- **Status des Eintrags:** später (ab Charge K13).
- **Betroffene Rollen:** `dr-victor-frankenstein`; Wechselwirkung laut Dossier: Wächter am Tor, Loki (Liebende), Rotkäppchen (Apfel/Kette), Sensenträger (`hunterShot`/`hunterQueued`), Ritter, Lehrling/Seelentauscher (Erbe), Kutscher (zweite Wiederbelebungsrolle), Totenkarten `segen_08`, `wende_04`, …
- **Belege:** [Dossier](dossiers/village-3.md#dr-victor-frankenstein); RM-C-147, RM-C-148, RM-C-149, RM-C-150 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-011, RM-DR-013.
- **RM-DR-141.1 · Rollenpool** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wiederbelebungsrollen 28.09.2026
  - Option A: jede Rolle außer der bisherigen
  - Option B: nur nicht im Spiel befindliche Rollen
  - Auswirkung: Balance: Wolfsrolle stärkt ggf. Wölfe (Tag `creates-wolf`); Umsetzung: Katalogfilter, `max_copies`
  - Empfehlung: B mit ausdrücklich erlaubtem Dorfbewohner; Wolfsrollen nur nach Entscheidung
- **RM-DR-141.2 · Zustand des Wiederbelebten** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Wiederbelebungsrollen 28.09.2026
  - Option A: vollständiger Neustart des Sitzes (wie Kutscher)
  - Option B: Bindungen bleiben
  - Auswirkung: Balance: A verhindert Sofort-Tod durch Liebeskummer; Umsetzung: Wiederbelebungsmodell mit Reset-Liste
  - Empfehlung: A
- **RM-DR-141.3 · Einmaligkeit bei Erbe** · Status: entschieden; Quelle: rules-register G-ID-3; Einmal-Fähigkeiten pro Person und Rolle
  - Option A: einmal pro Person
  - Option B: einmal pro Rolle im Spiel
  - Auswirkung: Balance: A erlaubt 2 Wiederbelebungen; Umsetzung: `ability_uses` pro Person
  - Empfehlung: A (Godot-Standard)
- **RM-DR-141.4 · Totenkarten-Aktivierung nach Verbrauch** · Status: später (mit dem Totenkarten-Assistenten, W-01)
  - Option A: nur solange Wiederbelebung noch möglich
  - Option B: solange die Rolle lebt
  - Auswirkung: Balance: gering bis mittel; Umsetzung: Tag-Abfrage mit Verbrauchszustand
  - Empfehlung: A
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Welche Rollen sind wählbar (nur nicht vergebene, auch Wolfs-/Solorollen, Dorfbewohner immer)? 2. Welche Marker/Bindungen verliert der Wiederbelebte (Liebe, Gift, Kette, Fluch)? 3. Einmal pro Person oder pro Rolle im Spiel (Erbe)? 4. Handelt die neue Rolle schon in derselben Nacht? 5. Wer erfährt die neue Rolle (nur SL und Wiederbelebter?), wird die Wiederbelebung öffentlich angesagt? 6. Bleiben Wiederbelebungs-Totenkarten nach Verbrauch aktiv? 7. Darf ein in dieser Nacht Gestorbener (erst am Morgen tot) Ziel sein? (Legacy: nein, Tode erst am Morgen.)
- **Charge:** K13. **In Option (nicht freigegeben):** keiner.

## RM-DR-142 · `nekromant`

- **Status des Eintrags:** später (ab Charge K15).
- **Betroffene Rollen:** `nekromant`; Wechselwirkung laut Dossier: Werwolf-Rudel (Angriff als Auslöser), Schicksalswolf/Rudelvater (Zusatzziele, `PACKFATHER_KILL` durchbricht Schild), Dämonischer Wolf (`cursedWolfAura` zählt bei Benennung als Wolf, Nekromant selbst kann verflucht …
- **Belege:** [Dossier](dossiers/solos-b.md#nekromant); RM-C-066, RM-C-067, RM-C-068, RM-C-069, RM-C-070 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-005, RM-DR-007, RM-DR-008.
- **RM-DR-142.1 · Wen schützt der Schild** · Status: später (K15)
  - Option A: globaler Schild für die nächste Tötung irgendwo
  - Option B: Schild nur für den Nekromanten, jede Todesart
  - Auswirkung: Balance: global: Nekromant kann Wolfskill auf beliebige Person verhindern (Dorf-nahe Macht), auch Lynch am Tag; Umsetzung: global braucht globalen Modifikator in der KillPipeline; selbst passt in Protections
  - Empfehlung: PO entscheidet; Text so oder so präzisieren
- **RM-DR-142.2 · Umlenkung optional oder Pflicht** · Status: später (K15)
  - Option A: optional (Text)
  - Option B: Pflicht (Code)
  - Auswirkung: Balance: Pflicht zwingt Nekromanten, einen Mitspieler zu töten; Umsetzung: PendingPrompt mit "nicht umlenken"
  - Empfehlung: Text gilt: optional mit Verzicht
- **RM-DR-142.3 · Ressource der Toten** · Status: später (K15)
  - Option A: ein gemeinsamer Vorrat "Stimme der Toten"
  - Option B: zwei getrennte Vorräte
  - Auswirkung: Balance: getrennt: doppelte Nutzung derselben Toten; Umsetzung: Statusmarker pro Toter: ein oder zwei Felder
  - Empfehlung: ein gemeinsamer Marker "geopfert"
- **RM-DR-142.4 · Siegversuche** · Status: später (K15)
  - Option A: beliebig viele Versuche
  - Option B: ein Versuch pro Tag oder pro Spiel, evtl. mit Strafe
  - Auswirkung: Balance: unbegrenzt: Solo-Sieg praktisch sicher durch Durchprobieren; Umsetzung: Versuchszähler und Tagesaktion
  - Empfehlung: Begrenzung festlegen
- **RM-DR-142.5 · Übungs-Enthüllung** · Status: später (K15)
  - Option A: streichen
  - Option B: als Regel übernehmen und Text ergänzen
  - Auswirkung: Balance: unklar, derzeit nur Hinweis; Umsetzung: eigener Tagesbefehl
  - Empfehlung: streichen, sofern keine Regelquelle existiert
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Schützt der Schild jede Person oder nur den Nekromanten? Gilt er gegen Lynch? 2. Ist die Umlenkung optional? Darf auf Wölfe umgelenkt werden? Gelten Schutz/Der Weise für das Umlenkziel? 3. Gibt es einen gemeinsamen Vorrat "Stimme der Toten" für Schild und Umlenkung? 4. Wie oft darf der Nekromant einen Wolf benennen (pro Tag, pro Spiel), und hat ein Fehlversuch Folgen? Ist die Benennung öffentlich? 5. Zählt ein verfluchter Nicht-Wolf (`cursedWolfAura`) als korrekt benannter Werwolf? 6. Bleibt die Übungs-Enthüllung als Regel erhalten?
- **Charge:** K15. **In Option (nicht freigegeben):** keiner.

## RM-DR-143 · `kartenschlucker`

- **Status des Eintrags:** später (ab Charge K15).
- **Betroffene Rollen:** `kartenschlucker`; Wechselwirkung laut Dossier: alle Rollen, die Tote erzeugen (mehr Tote = mehr Tauschgelegenheiten), Totenkarten-System (`cards`), Frankenstein/Kutscher (Wiederbelebung ermöglicht erneuten Tausch), Nekromant/Hades/Parasit/Rudelvater (Abfangregeln in …
- **Belege:** [Dossier](dossiers/solos-b.md#kartenschlucker); RM-C-071, RM-C-072 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-005, RM-DR-007, RM-DR-013.
- **RM-DR-143.1 · Zusatzkräfte Kill/Schild/Ansage** · Status: später (K15)
  - Option A: reine Sammelrolle (Text)
  - Option B: Sammelrolle mit Eskalationsstufen (Code)
  - Auswirkung: Balance: Code macht die Rolle ab 2 Stapeln zum Nachtmörder mit Schneeballeffekt (mehr Tote, mehr Tauschmöglichkeiten); Umsetzung: Code-Variante braucht Kill, Schild, Ansage zusätzlich
  - Empfehlung: PO entscheidet; bei Beibehaltung Text ergänzen
- **RM-DR-143.2 · Wer darf tauschen** · Status: später (K15)
  - Option A: jeder Tote frei
  - Option B: nur Nicht-Wölfe oder nur einmal pro Person
  - Auswirkung: Balance: Wölfe können Solo-Sieg beschleunigen oder bewusst verhindern; Umsetzung: Regel im Totenkarten-Assistenten
  - Empfehlung: Text präzisieren
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Bleiben Kill ab 2, Schild ab 5 und Ansage alle 3 Nächte erhalten? Kostet der Kill Stapel? 2. Darf jeder Tote (auch Wölfe) tauschen, und wie oft pro Person? 3. Ist der Schild passiv (ab 5 Stapeln immer) oder an den Nachtschritt gekoppelt? 4. Ist die Stapelzahl öffentlich (Ansage) oder geheim? 5. Gewinnt ein toter Kartenschlucker, wenn nach seinem Tod 10 Stapel erreicht würden (heute: keine Stapel nach Tod)?
- **Charge:** K15. **In Option (nicht freigegeben):** keiner.

## RM-DR-144 · `hades`

- **Status des Eintrags:** später (ab Charge K15).
- **Betroffene Rollen:** `hades`; Wechselwirkung laut Dossier: jede tötende Rolle (Lichterquelle), Nekromant (Schild fängt Hades-Kill ab, Lichter trotzdem weg), Rudelvater (`PACKFATHER_KILL` durchbricht Barriere), Ritter (Vergeltung bei `HADES_KILL`, `core:431`), …
- **Belege:** [Dossier](dossiers/solos-b.md#hades); RM-C-073, RM-C-074, RM-C-075 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-005, RM-DR-007, RM-DR-008.
- **RM-DR-144.1 · Sieg automatisch oder eingelöst** · Status: später (K15)
  - Option A: Sieg sofort bei 10
  - Option B: Sieg nur durch bewusstes Einlösen (Lichter könnten vorher ausgegeben werden)
  - Auswirkung: Balance: Einlösen erlaubt Taktik (Lichter sparen/ausgeben); Umsetzung: eine Siegregel als WinCandidate
  - Empfehlung: Automatik bei 10 mit SL-Bestätigung, Button streichen
- **RM-DR-144.2 · Zählen eigene Kills** · Status: später (K15)
  - Option A: jeder Tod zählt
  - Option B: nur Tode durch andere
  - Auswirkung: Balance: Kill kostet netto 1 statt 2; Umsetzung: Filter nach Quelle
  - Empfehlung: PO
- **RM-DR-144.3 · Stimme x3** · Status: später (K15)
  - Option A: Kauf bleibt, SL wird erinnert
  - Option B: Kauf streichen
  - Auswirkung: Balance: Kauf ohne Anzeige ist wertlos; Umsetzung: dauerhafter Statusmarker mit Hinweis beim Tag
  - Empfehlung: Marker sichtbar machen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Sieg automatisch bei 10 oder nur durch Einlösen? 2. Geben eigene Hades-Kills Lichter? 3. Stimme x3 behalten (als SL-Hinweis) oder streichen? Ist der Kauf öffentlich? 4. Werden Lichter bei abgefangenem Kill erstattet? 5. Soll der Rollentext Preise und Fähigkeiten nennen?
- **Charge:** K15. **In Option (nicht freigegeben):** keiner.

## RM-DR-145 · `doktor`

- **Status des Eintrags:** später (ab Charge K2).
- **Betroffene Rollen:** `doktor`; Wechselwirkung laut Dossier: Wolfskind, Lehrling, Seelentauscher, Dämonischer Wolf, alle Solo-Rollen, Doppelspion, Trugbilderwolf (Erscheinung vs. Fraktion), Rotkäppchen …
- **Belege:** [Dossier](dossiers/village-3.md#doktor); RM-C-151, RM-C-152 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002.
- **RM-DR-145.1 · Zwei Solo-Rollen** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 2 27.09.2026
  - Option A: Solos bilden kein Team (immer "verschieden", auch mit sich selbst)
  - Option B: "Solo" ist ein Team
  - Auswirkung: Balance: A verhindert Fehlschluss; Umsetzung: Vergleich über Siegpartei statt Fraktionskonstante
  - Empfehlung: A
- **RM-DR-145.2 · Verwandlung / Fluch** · Status: entschieden; Quelle: rules-register G-ID-2; DR-10; DECISION-LOG Lehrling (Fraktion wechselt sofort); Siegfraktion ist ein aktueller Personenwert
  - Option A: aktuelle Fraktion
  - Option B: Katalogfraktion (Legacy)
  - Auswirkung: Balance: A macht den Doktor zum Verwandlungs-Detektor; Umsetzung: `faction` am Player (RoleTransition) statt Katalog
  - Empfehlung: A (Godot hat `faction` am Player)
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Sind zwei Solo-Spieler "im selben Team"? 2. Zählt die aktuelle Fraktion (nach Verwandlung/Erbe) oder die Startrolle? 3. Zählt ein Trugbilderwolf mit seiner Scheinrolle oder als Wolf? 4. Darf der Doktor sich selbst testen?
- **Charge:** K2. **In Option (nicht freigegeben):** A.

## RM-DR-146 · `faehrtenleser`

- **Status des Eintrags:** quellenprüfung.
- **Betroffene Rollen:** `faehrtenleser`; Wechselwirkung laut Dossier: alle Wolfsrollen, Fenrir, Dämonischer Wolf (Verfluchte), Wolfskind/Lehrling (Verwandlung), Doppelspion, Ritter (gemeinsame Richtungsdefinition), …
- **Belege:** [Dossier](dossiers/village-3.md#faehrtenleser); RM-C-154, RM-C-155, RM-C-156 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-003, RM-DR-014.
- **RM-DR-146.1 · Richtungsdefinition** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 3 27.09.2026; „links“ am Tisch gegenüber Bildschirm ist ohne Gerät nicht prüfbar
  - Option A: aus Sicht des Spielers am Tisch
  - Option B: aus Sicht des SL-Bildschirms
  - Auswirkung: Balance: Fehlinfo bei falscher Deutung; Umsetzung: Richtung relativ zu `seat_order` (Uhrzeigersinn) festlegen
  - Empfehlung: am Tisch prüfen und festschreiben
- **RM-DR-146.2 · Gleichstand** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 3 27.09.2026
  - Option A: fest links
  - Option B: beide Richtungen nennen / SL wählt
  - Auswirkung: Balance: gering; Umsetzung: Regel im Rechner
  - Empfehlung: entscheiden
- **RM-DR-146.3 · Fenrir Stufe 3** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Hinrichtungsrollen 28.09.2026
  - Option A: gleiche Wolfsdefinition wie Ritter
  - Option B: unterschiedlich
  - Auswirkung: Balance: gering; Umsetzung: eine gemeinsame Zielfunktion
  - Empfehlung: angleichen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. "Links" aus Sicht des Spielers oder des SL-Bildschirms, und entspricht der Uhrzeigersinn der App dem Tisch? 2. Gleichstand: fest eine Richtung oder beide nennen? 3. Zählen tote Sitze im Abstand mit (Legacy: ja)? 4. Wolfsdefinition: verfluchte Dorfbewohner, Fenrir Stufe 3? 5. Einsatz pro Person (frisch bei Erbe) oder pro Rolle?
- **Charge:** K3. **In Option (nicht freigegeben):** keiner.

## RM-DR-147 · `waldlaeufer`

- **Status des Eintrags:** später (ab Charge K2).
- **Betroffene Rollen:** `waldlaeufer`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf, Wolfskind/Lehrling, Siegreicher Wolf (Zählweise), Doppelspion, Waldhexe/Hades (sofortige Nachttode vor dem …
- **Belege:** [Dossier](dossiers/village-3.md#waldlaeufer); RM-C-157, RM-C-158 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-002.
- **RM-DR-147.1 · Häufigkeit** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 2 27.09.2026
  - Option A: jede Nacht
  - Option B: einmal (z. B. Nacht 1)
  - Auswirkung: Balance: jede Nacht ist stark in Akt IV; Umsetzung: Schritt jede Nacht vs. Einmal-Einsatz
  - Empfehlung: entscheiden und in Text aufnehmen
- **RM-DR-147.2 · Verfluchte zählen** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 2 27.09.2026
  - Option A: nur `counts_as_wolf`
  - Option B: auch Erscheinung
  - Auswirkung: Balance: hängt an Q1; Umsetzung: Zählung über `counts_as_wolf`
  - Empfehlung: nach Q1
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Jede Nacht oder einmal? 2. Zählen Verfluchte und verwandelte Sitze? 3. Zählt der Siegreiche Wolf einfach (Legacy) oder doppelt? 4. Zählen Nachtopfer, die erst am Morgen sterben, noch als lebend (Legacy: ja)?
- **Charge:** K2. **In Option (nicht freigegeben):** A.

## RM-DR-148 · `schutzgeist`

- **Status des Eintrags:** später (ab Charge K5).
- **Betroffene Rollen:** `schutzgeist`; Wechselwirkung laut Dossier: Werwolf/Rudel (Angriff), Rachsüchtiger Wolf (Zusatzangriff), Seuchenwolf (Durchbohren ignoriert Schutz beim Pick, chunk:162) und Rudelvater (Zusatzopfer am Morgen ohne Schutzprüfung, night:269-280), Dämonischer Wolf …
- **Belege:** [Dossier](dossiers/village-4.md#schutzgeist); RM-C-159, RM-C-160, RM-C-161, RM-C-162 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-004, RM-DR-009.
- **RM-DR-148.1 · Dauer/Wirkung des Schilds** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: Schild hält bis zum nächsten Wolfsangriff (auch spätere Nächte)
  - Option B: Schild gilt nur für die aktuelle Nacht, Schritt muss dann vor dem Rudel liegen
  - Auswirkung: Balance: A stärker, B ohne Umordnung wirkungslos; Umsetzung: A: dauerhafter Marker; B: Schrittposition vor Rudel
  - Empfehlung: A (deckt Alttext, macht Rolle spielbar)
- **RM-DR-148.2 · Schutzart** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: nur Wolfsangriff
  - Option B: jeder Tod
  - Auswirkung: Balance: A schwächer; Umsetzung: A nutzt vorhandene Protections
  - Empfehlung: A
- **RM-DR-148.3 · Zeitpunkt** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: frühestens nächste Nacht
  - Option B: sobald tot, auch dieselbe Nacht
  - Auswirkung: Balance: gering; Umsetzung: Schrittfreigabe mit Nachtindex
  - Empfehlung: A (Textwortlaut)
- **RM-DR-148.4 · Wolf-Meldung** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: nur Tatsache, ohne Namen, echte Fraktion
  - Option B: mit Namen / nach Erscheinung (`appears_as`)
  - Auswirkung: Balance: Name wäre starke Info; Umsetzung: InfoRecord public, Quelle Wahrheit oder Erscheinung
  - Empfehlung: A ohne Namen, Wahrheit
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Hält das Schild bis zum nächsten Wolfsangriff oder nur für eine Nacht? (2) Nur gegen Wolfsangriff oder gegen jeden Tod? (3) Darf sie in derselben Nacht handeln, in der sie stirbt? (4) Wird der gewählte Wolf mit Namen oder nur die Tatsache verkündet, und zählt die wahre Fraktion oder die Erscheinung (verfluchter Dorfbewohner)? (5) Nach Wiederbelebung und erneutem Tod erneut nutzbar?
- **Charge:** K5. **In Option (nicht freigegeben):** keiner.

## RM-DR-149 · `waechter-am-tor`

- **Status des Eintrags:** später (ab Charge K12).
- **Betroffene Rollen:** `waechter-am-tor`; Wechselwirkung laut Dossier: Wolfskind, Lehrling, König Lykaon/Trugbilderwolf, Seelentauscher, Dr. Victor Frankenstein, Kutscher, Dämonischer Wolf (Regelfrage), Grabräuber …
- **Belege:** [Dossier](dossiers/village-4.md#waechter-am-tor); RM-C-163 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-002.
- **RM-DR-149.1 · Gilt der Dämonische-Wolf-Fluch als "neu entstehender Werwolf"?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 5 28.09.2026
  - Option A: Fluch ist nur Erscheinung, Wächter irrelevant
  - Option B: Fluch erzeugt echten Wolf, Wächter muss abfangen
  - Auswirkung: Balance: bei B stärker für Dorf; Umsetzung: A: appears_as; B: zusätzlicher Abfangpunkt
  - Empfehlung: A (folgt 07-Vorschlag "nur Erscheinung")
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Gilt der Dämonische-Wolf-Fluch als neuer Werwolf? (2) Erhält der umgewandelte Spieler öffentlich/privat eine Mitteilung? (3) Soll Lykaon bei Abfang seine Fähigkeit verbrauchen? (4) Soll die Rolle in Akt IV bleiben, obwohl dort keine Wolfsquelle existiert?
- **Charge:** K12. **In Option (nicht freigegeben):** keiner.

## RM-DR-150 · `zeitwaechter`

- **Status des Eintrags:** später (ab Charge K16).
- **Betroffene Rollen:** `zeitwaechter`; Wechselwirkung laut Dossier: praktisch alle Nachtrollen; besonders Schwarze Witwe, Giftwolf, Märtyrerin, Voodoo-Priester, Rudelvater, Seuchenwolf, Waldhexe, Hades, Amalia, Kriegerin, Dorfschmied, Der Weise, Fenrir, Cerberus, Todesprediger, …
- **Belege:** [Dossier](dossiers/village-4.md#zeitwaechter); RM-C-164, RM-C-165, RM-C-166, RM-C-167 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-010.
- **RM-DR-150.1 · Umfang des Abbruchs** · Status: später (K16)
  - Option A: Gesamte Nacht wird zurückgerollt (Tode und Zustände)
  - Option B: Nur Tode dieser Nacht entfallen, Zustände bleiben
  - Auswirkung: Balance: A sehr stark, B stark; Umsetzung: A: Nacht-Transaktion mit Schnappschuss ab Nachtbeginn; B: alle Tode der Nacht aufschieben bis Morgen
  - Empfehlung: A mit Schnappschuss bei Nachtbeginn (RoleTransition-Schnappschuss-Idee) oder B nach 07
- **RM-DR-150.2 · Zeitpunkt der Entscheidung** · Status: später (K16)
  - Option A: Entscheidung am Nachtanfang, dann läuft keine Aktion
  - Option B: Entscheidung am Nachtende, alles wird zurückgenommen
  - Auswirkung: Balance: A spart Zeit, B gibt Zeitwächter Zusatzwissen (sieht keine Nachtergebnisse, aber SL weiß sie); Umsetzung: A: Schritt vor tier 0.1; B: Rücknahme nötig
  - Empfehlung: A (einfacher, fairer)
- **RM-DR-150.3 · Zähler** · Status: später (K16)
  - Option A: alle nachtabhängigen Zähler zurück
  - Option B: nur Nachtnummer
  - Auswirkung: Balance: Todesprediger, Schmied, Fenrir betroffen; Umsetzung: Zähler-Liste in Nacht-Transaktion
  - Empfehlung: A
- **RM-DR-150.4 · Wolfsrollen** · Status: später (K16)
  - Option A: auch Wölfe
  - Option B: nur Nicht-Wölfe
  - Auswirkung: Balance: gering; Umsetzung: Blockadegrund pro Schritt
  - Empfehlung: A
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Entscheidung am Nachtanfang oder -ende? (2) Werden nur Tode oder alle Zustände zurückgenommen? (3) Zählen Zähler (Nachtnummer, Schmied, Fenrir, Todesprediger) die Nacht? (4) Gilt der Abbruch auch für Wölfe und Solo-Rollen? (5) Öffentliche Ankündigung am Morgen?
- **Charge:** K16. **In Option (nicht freigegeben):** keiner.

## RM-DR-151 · `amalia`

- **Status des Eintrags:** später (ab Charge K14).
- **Betroffene Rollen:** `amalia`; Wechselwirkung laut Dossier: alle Wolfsrollen (Schwelle), Dämonischer Wolf (Verfluchte zählen im Code mit), Doppelspion (zählt nicht), Nekromant (Globalschild verhindert Opfer), Zeitwächter (Opfer bleibt trotz …
- **Belege:** [Dossier](dossiers/village-4.md#amalia); RM-C-168, RM-C-169, RM-C-170 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002.
- **RM-DR-151.1 · Zeitpunkt** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: Tagesaktion (öffentlich, alle wach)
  - Option B: Nachtschritt, Frage wird am Morgen verkündet
  - Auswirkung: Balance: A: Frage wirkt sofort in Diskussion; Umsetzung: A: Tagesaktionswarteschlange; B: verzögertes Ereignis
  - Empfehlung: A
- **RM-DR-151.2 · Frage und Antwort** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: SL beantwortet wahrheitsgemäß, App protokolliert Frage und Antwort
  - Option B: Frage rein mündlich, App nur Opfer
  - Auswirkung: Balance: A: nachvollziehbar; Umsetzung: A: PendingPrompt mit Freitext + Ja/Nein; InfoRecord
  - Empfehlung: A
- **RM-DR-151.3 · Schwelle** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: >2 lebende echte Wölfe
  - Option B: >=2 (Alttext) oder inkl. toter ("im Spiel")
  - Auswirkung: Balance: Verfügbarkeit; Umsetzung: Zählung über Fraktion, ohne Erscheinung
  - Empfehlung: >2 lebende echte Wölfe
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Tag oder Nacht? (2) Beantwortet der SL wahrheitsgemäß, und wird die Antwort in der App festgehalten? (3) Schwelle ">2" oder "2+", lebend oder "im Spiel"? (4) Zählen verfluchte Sitze als Werwölfe?
- **Charge:** K14. **In Option (nicht freigegeben):** keiner.

## RM-DR-152 · `kriegerin-des-lichts`

- **Status des Eintrags:** später (ab Charge K7).
- **Betroffene Rollen:** `kriegerin-des-lichts`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (verfluchter Sitz: Wolf oder nicht?), Trugbilderwolf/Erscheinungsrollen, Doppelspion, Rudelvater (erste Sonderfähigkeitstötung überlebt, falls Treffer tötet), …
- **Belege:** [Dossier](dossiers/village-4.md#kriegerin-des-lichts); RM-C-171, RM-C-172, RM-C-173 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-contradictory`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-014.
- **RM-DR-152.1 · Stirbt ein getroffener Wolf?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: Angriff tötet den Wolf
  - Option B: Angriff ist nur Test, Wolf wird nur erkannt
  - Auswirkung: Balance: A sehr stark (sicherer Wolfskill mit Risiko); Umsetzung: A: KillPipeline-Ursache, Reaktionen
  - Empfehlung: Entscheidung nötig; 04 korrigieren
- **RM-DR-152.2 · Wahrheitsquelle** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: App prüft Fraktion automatisch
  - Option B: SL entscheidet (kann Erscheinung berücksichtigen)
  - Auswirkung: Balance: A verhindert SL-Fehler; Umsetzung: A: Fraktion oder appears_as
  - Empfehlung: A mit Wahrheit, appears_as nur falls gewünscht
- **RM-DR-152.3 · Öffentlichkeit** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: geheim an Kriegerin
  - Option B: öffentlich
  - Auswirkung: Balance: B starke Dorfinfo; Umsetzung: Sichtbarkeit actor vs public
  - Empfehlung: nach PO
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Stirbt ein getroffener Wolf? (2) Prüft die App die Fraktion automatisch, und nach Wahrheit oder Erscheinung? (3) Ist das Ergebnis öffentlich? (4) Darf sie sich selbst wählen (Code: ja)?
- **Charge:** K7. **In Option (nicht freigegeben):** keiner.

## RM-DR-153 · `detektiv`

- **Status des Eintrags:** quellenprüfung.
- **Betroffene Rollen:** `detektiv`; Wechselwirkung laut Dossier: alle Wolfsrollen, Dämonischer Wolf (Verfluchte lösen aus), Wolfskind/Lehrling (verwandelte Wölfe), Doppelspion (ausgenommen), Dorfschmied (Wolfstod durch Waffe), Fährtenleser …
- **Belege:** [Dossier](dossiers/village-4.md#detektiv); RM-C-174, RM-C-175, RM-C-176, RM-C-177 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-003, RM-DR-009, RM-DR-015.
- **RM-DR-153.1 · Muss der Detektiv leben?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: nur lebend
  - Option B: auch tot
  - Auswirkung: Balance: B stärker; Umsetzung: Bedingung am Hook
  - Empfehlung: A (Code)
- **RM-DR-153.2 · Mindestens 2 lebende Wölfe** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: ≥1 anderer lebender Wolf genügt
  - Option B: ≥2 (Code)
  - Auswirkung: Balance: bei A Hinweis auf letzten Wolf, sehr stark; Umsetzung: Schwelle
  - Empfehlung: nach PO
- **RM-DR-153.3 · Hinweisinhalt** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Informationsrollen 28.09.2026
  - Option A: Hinweis bezieht sich auf den toten Wolf (Sitz des Toten als Anker)
  - Option B: Hinweis enttarnt Wolf w indirekt (Code)
  - Auswirkung: Balance: B deutlich stärker, A moderat; Umsetzung: Anker und Richtungsregel
  - Empfehlung: A, und Parität nur wenn wahr
- **RM-DR-153.4 · Richtung links/rechts** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 3 27.09.2026; Richtungskonvention; zusätzlich widersprüchlich zu Fährtenleser und Ritter
  - Option A: einheitlich id-1
  - Option B: einheitlich id+1
  - Auswirkung: Balance: keine; Umsetzung: Sitznachbarschaft mit einer Konvention
  - Empfehlung: eine Konvention für alle Rollen
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Muss der Detektiv leben? (2) Reicht ein verbleibender anderer Wolf? (3) Ist der Anker der tote Wolf oder ein zufälliger lebender Wolf (der dadurch enttarnt wird)? (4) Welche Hinweisarten gibt es, und müssen sie wahr sein? (5) Welche Richtung ist "links"? (6) Überspringen Nachbarn tote Sitze? (7) Lösen verfluchte Dorfbewohner aus?
- **Charge:** K3. **In Option (nicht freigegeben):** keiner.

## RM-DR-154 · `dorfschmied`

- **Status des Eintrags:** später (ab Charge K5).
- **Betroffene Rollen:** `dorfschmied`; Wechselwirkung laut Dossier: Werwolf/Rudel, Rachsüchtiger Wolf, Schicksalswolf, Rudelvater, Seuchenwolf, Schutzengel, Der Weise, Nekromant, Rudelvater (Erstrettung), Dämonischer Wolf, Detektiv (Hinweis bei Waffentod), Zeitwächter, Verdammniswächter …
- **Belege:** [Dossier](dossiers/village-4.md#dorfschmied); RM-C-178, RM-C-179, RM-C-180 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-004, RM-DR-005, RM-DR-015.
- **RM-DR-154.1 · Welche Nächte zählen** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: globale Nachtnummer 6
  - Option B: eigene Schmiedenächte
  - Auswirkung: Balance: gering; Umsetzung: Zähler vs. Nachtnummer
  - Empfehlung: A (einfach, eindeutig)
- **RM-DR-154.2 · Nur Nacht 6 oder ab Nacht 6** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: nur Nacht 6
  - Option B: ab Nacht 6
  - Auswirkung: Balance: A strenger; Umsetzung: Schrittfreigabe
  - Empfehlung: B (Code)
- **RM-DR-154.3 · Welche Angriffe** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Schutzrollen 28.09.2026
  - Option A: alle Wolfsangriffe inkl. durchbohrend
  - Option B: durchbohrende ausgenommen
  - Auswirkung: Balance: gering; Umsetzung: Filter `is_wolf_attack`
  - Empfehlung: A (Code)
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Globale Nachtnummer oder eigene Schmiedenächte? (2) Nur Nacht 6 oder ab Nacht 6? (3) Darf der Schmied sich selbst oder einen Wolf ausrüsten? (4) Schützt die Waffe auch vor durchbohrenden Angriffen und vor Sofort-Toden durch Wolfsrollen? (5) Wird das Waffenopfer öffentlich verkündet? (6) Kann der Waffenträger selbst das Zufallsopfer sein, wenn er Wolf ist?
- **Charge:** K5. **In Option (nicht freigegeben):** keiner.

## RM-DR-155 · `doppelspion`

- **Status des Eintrags:** produktentscheidung.
- **Betroffene Rollen:** `doppelspion`; Wechselwirkung laut Dossier: Rachsüchtiger Wolf, Dämonischer Wolf (Fluch wirkungslos), Wolfskind/Lehrling (Wolfszählung), Orakel/Doktor/Spürhund (Erscheinung/Fraktion), Die Ewigen, …
- **Belege:** [Dossier](dossiers/solos-a.md#doppelspion); RM-C-063, RM-C-064 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-002, RM-DR-007.
- **RM-DR-155.1 · Muss er leben?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit 27.09.2026; Doppelspion: muss er leben
  - Option A: nur lebend (Code)
  - Option B: auch tot
  - Auswirkung: Balance: B macht ihn stärker; Umsetzung: WinCandidate
  - Empfehlung: A, Text präzisieren
- **RM-DR-155.2 · Parität** · Status: entschieden; Quelle: rules-register G-SIEG-2: Einzelsiegrollen zählen als Nicht-Wölfe
  - Option A: Nicht-Wolf
  - Option B: neutral (zählt für keine Seite)
  - Auswirkung: Balance: A lässt Wölfe schwerer gewinnen; Umsetzung: `counts_as_wolf=false`
  - Empfehlung: A
- **RM-DR-155.3 · Verhältnis zum Dorfsieg: welche anderen Kandidaten werden gleichzeitig angeboten?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit 27.09.2026; Doppelspion: gleichzeitige Kandidaten
  - Option A: Lebt mindestens ein Doppelspion, wenn kein Wolf mehr lebt, wird der Dorfkandidat nicht angeboten; nur Doppelspion-Kandidaten (je Person) entstehen. Rollenspezifische Ausnahme zu G-SIEG-1/G-SIEG-3; Legacy `core:227-230` verhält sich so
  - Option B: Dorf- und Doppelspion-Kandidat entstehen gemeinsam; der Spielleiter wählt nach dem Rollentext (bestehende Regel G-SIEG-3 ohne Ausnahme)
  - Option C: wie B, die App kennzeichnet den Doppelspion-Kandidaten als die nach Rollentext zutreffende Wahl
  - Auswirkung: Balance: A setzt die Rolle einheitlich durch; B und C hängen vom Spielleiter ab; Umsetzung: A: `WinRules` unterdrückt einen Kandidaten (neue Ausnahme, eigene Tests); B: nur ein weiterer Kandidat; C: B plus Kennzeichnung
  - Empfehlung: A. Der Text „gewinnt alleine, wenn alle Werwölfe tot sind“ beschreibt genau den Fall, in dem sonst das Dorf gewinnt; B würde bei jedem solchen Ende eine fehleranfällige Wahl verlangen. Der Spielleiter kann über `RejectWin` und `declare_winner` weiterhin anders entscheiden (G-GM-1). Wer bei Bestätigung gewinnt, ist davon unabhängig schon festgelegt: nur die begünstigte Person des Kandidaten
- **RM-DR-155.4 · Was erfahren die Werwölfe über den Doppelspion, wenn er mit ihnen aufwacht?** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit 27.09.2026; neu: was erfahren die Wölfe
  - Option A: Der Spielleiter nennt keine Rolle; die Wölfe sehen eine weitere wache Person und können ihn für einen Wolf halten
  - Option B: Der Spielleiter stellt ihn den Wölfen als Doppelspion vor
  - Option C: Er wacht nur zum Beobachten auf; die Wölfe sehen ihn nicht
  - Auswirkung: Balance: A macht ihn zum echten Spion; B schwächt ihn stark; C widerspricht „gemeinsam aufwachen“; Umsetzung: nur Ansagetext und Hinweis im Rudelschritt, keine Kernlogik
  - Empfehlung: A (geringe Belegsicherheit: der Rollentext regelt es nicht, die Legacy-App hat nur eine Tischregel)
- **RM-DR-155.5 · Nimmt er an der gespeicherten Rudelwahl teil?** · Status: technisch; Quelle: rules-register §2: nur Wölfe wählen das Rudelopfer; Hinweis im Rudelschritt, keine Teilnahme an der gespeicherten Wahl
  - Option A: nein: gespeichert wird nur die Wahl der Wölfe (Regelregister §2); die App zeigt im Rudelschritt einen Hinweis, dass er wach ist
  - Option B: –
  - Auswirkung: Balance: –; Umsetzung: Hinweis im Rudelschritt
  - Empfehlung: A (technisch)
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** (1) Muss er für den Sieg leben? (2) Zählt er in der Parität als Nicht-Wolf? (3) Erscheint er dem Orakel als Wolf oder Doppelspion? (4) Darf das normale Rudel ihn angreifen? (5) Gewinnt das Dorf mit, wenn er gewinnt?
- **Charge:** K1. **In Option (nicht freigegeben):** A.

## RM-DR-156 · `grabraeuber`

- **Status des Eintrags:** später (ab Charge K15).
- **Betroffene Rollen:** `grabraeuber`; Wechselwirkung laut Dossier: potenziell jede Rolle mit Nachtfähigkeit (Ziel des Diebstahls); Einmalrollen (bereits verbraucht?); Totenkarte `solo_05` (ähnliche …
- **Belege:** [Dossier](dossiers/solos-b.md#grabraeuber); RM-C-076, RM-C-077 in [`04`](04-rule-conflicts.md). Legacy-Befund `not-found`.
- **Querschnittsbezug:** RM-DR-006, RM-DR-007, RM-DR-014.
- **RM-DR-156.1 · Was bedeutet "Fähigkeit stehlen"** · Status: später (K15)
  - Option A: Grabräuber erhält dauerhaft die Nachtfähigkeit der toten Rolle (inkl. Nachtschritt)
  - Option B: einmalige Nutzung der Fähigkeit
  - Auswirkung: Balance: groß: je nach Zielrolle (z.B. Waldhexe, Hades) stark unterschiedlich; Umsetzung: Fähigkeitsübertragung ist ein neues System; Rollenwechsel (RoleTransition) passt nicht, da Rolle/Fraktion bleiben sollen
  - Empfehlung: PO; bis dahin manuell
- **RM-DR-156.2 · Siegbedingung** · Status: später (K15)
  - Option A: erbt die Siegbedingung der bestohlenen Rolle
  - Option B: eigene Bedingung (z.B. letzter Überlebender)
  - Auswirkung: Balance: ohne Bedingung ist die Rolle nicht gewinnbar; Umsetzung: zusätzliche Siegbedingung
  - Empfehlung: PO legt fest (Q4)
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Dauerhafte oder einmalige Nutzung der gestohlenen Fähigkeit? 2. Welche Rollen sind stehlbar (auch Wolfs- und Solofähigkeiten, passive Fähigkeiten, Siegbedingungen)? 3. Welche Siegbedingung hat der Grabräuber? 4. Übernimmt der Grabräuber Zähler/Zustände der toten Rolle (z.B. Hades-Lichter, verbrauchte Tränke)?
- **Charge:** K15. **In Option (nicht freigegeben):** keiner.

## RM-DR-157 · `parasit`

- **Status des Eintrags:** später (ab Charge K10).
- **Betroffene Rollen:** `parasit`; Wechselwirkung laut Dossier: jede tötende Rolle (Immunität), Rudelvater (`PACKFATHER_KILL` durchbricht Immunität NICHT, da Parasit-Prüfung zuerst), Nekromant-Schild (kann den Kettentod abfangen), Manipulator (gleichzeitiger Final-3-Sieg), Henker …
- **Belege:** [Dossier](dossiers/solos-b.md#parasit); RM-C-078 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-verified`.
- **Querschnittsbezug:** RM-DR-007, RM-DR-009, RM-DR-011.
- **RM-DR-157.1 · "Final 3" und Siegvorrang** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Runde 5 28.09.2026
  - Option A: Parasit gewinnt bei <=3 Lebenden immer (ggf. gemeinsam mit anderen)
  - Option B: wie Code, Team-Siege zuerst
  - Auswirkung: Balance: Code: Parasit + 2 Dorf ohne Wölfe => Dorfsieg; Parasit + 2 Wölfe => Wolfssieg; Umsetzung: Siegpriorität in WinRules (Q4)
  - Empfehlung: PO mit Q4
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Gewinnt der Parasit bei 3 oder weniger Lebenden? Allein oder zusätzlich zu Dorf/Wölfen? 2. Ist der Parasit auch gegen Hinrichtung immun, und wie wird das am Tisch kommuniziert? 3. Dürfen mehrere Parasiten verschiedene Wirte haben? 4. Darf ein Wolf Wirt sein?
- **Charge:** K10. **In Option (nicht freigegeben):** C.

## RM-DR-158 · `todesprediger`

- **Status des Eintrags:** später (ab Charge K15).
- **Betroffene Rollen:** `todesprediger`; Wechselwirkung laut Dossier: alle tötenden Rollen; Zeitwächter (Frost, Nachtzählung), Lynch/Hinrichtung, Parasit-ähnliche Immunitäten und Schilde (verschieben Todeszeitpunkt), Frankenstein/Kutscher (Wiederbelebung und erneuter …
- **Belege:** [Dossier](dossiers/solos-b.md#todesprediger); RM-C-079, RM-C-080, RM-C-081 in [`04`](04-rule-conflicts.md). Legacy-Befund `legacy-broken`.
- **Querschnittsbezug:** RM-DR-007, RM-DR-011, RM-DR-014.
- **RM-DR-158.1 · Öffentlich oder geheim** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: öffentliche Ankündigung
  - Option B: geheime Vorhersage beim SL
  - Auswirkung: Balance: öffentlich: Dorf/Wölfe können gezielt töten oder schonen; Umsetzung: Ereignis-Sichtbarkeit public vs gm
  - Empfehlung: PO
- **RM-DR-158.2 · Zeitpunkt der Vorhersage** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: nur Nacht 1
  - Option B: jederzeit einmal
  - Auswirkung: Balance: spätes Vorhersagen ist deutlich leichter; Umsetzung: Schritt nur Nacht 1 oder dauerhaft
  - Empfehlung: Nacht 1 (sonst trivial)
- **RM-DR-158.3 · Zählbasis Tag/Nacht** · Status: entschieden; Quelle: DECISION-LOG Rollenaudit Einzelsiegrollen Teil 1 28.09.2026
  - Option A: Tag N = Tag nach Nacht N, Morgentode zählen zur Nacht
  - Option B: Tag N wie im Protokoll angezeigt (= nach Nacht N-1)
  - Auswirkung: Balance: Überschneidung verdoppelt Trefferchance bei Morgentoden; Umsetzung: eindeutige `night_number`/`day_number` und Zuordnung jedes Todes zu genau einer Phase
  - Empfehlung: Tode der Morgenauflösung zählen zur Nacht; Anzeige und Vergleich dieselbe Zahl
- **Weitere offene Fragen (Dossier, noch ohne eigene Unter-ID):** 1. Wird die Vorhersage öffentlich angekündigt oder geheim beim SL abgegeben? 2. Wann darf vorhergesagt werden (nur Nacht 1, jederzeit einmal)? Sind vergangene/aktuelle Zeitpunkte zulässig? 3. Wie sind "Tag N" und "Nacht N" definiert, und zu welcher Phase gehören Tode der Morgenauflösung? 4. Zählt ein Tod durch SL-Korrektur oder durch Totenkarten-Effekt? 5. Was passiert bei Wiederbelebung und erneutem Tod (neue Vorhersage)?
- **Charge:** K15. **In Option (nicht freigegeben):** keiner.
