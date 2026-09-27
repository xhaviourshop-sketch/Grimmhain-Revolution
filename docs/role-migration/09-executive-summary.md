# 09 · Zusammenfassung Rollenmigration

**Stand:** 2026-09-26 · Basiscommit `4673b0b` · reine Planung, nichts entschieden, kein Code geändert

## 1. Aktueller Stand

Der Godot-Regelkern enthält **11 von 72 Rollen**, alle umgesetzt und durch grüne headless Tests belegt (351 Tests). Keine ist schon am Tablet spielbar: UI-Ablauf, Undo/Redo, Checkpoints, öffentliche Anzeige und lokalisierte Rollentexte fehlen noch für alle Rollen gleichermaßen. Die übrigen **61 Rollen** gibt es nur in der alten Web-App.

## 2. Zahlen

| | Anzahl |
|---|---:|
| Rollen insgesamt (nachgewiesen) | **72** (Dorf 39, Wölfe 19, Einzelsieg 14) |
| im Godot-Kern vollständig umgesetzt und getestet | 11 |
| teilweise umgesetzt | 0 |
| fehlend | 61 (davon 3 mit ausreichend klarer Regel, 58 mit offener Entscheidung) |
| Legacy-Befund „setzt Text um“ (`legacy-verified`) | 26 von 72 (19 der 61 fehlenden) |
| Legacy-Befund widersprüchlich (`legacy-contradictory`) | 28 von 72 (27 der 61) |
| Legacy-Befund defekt (`legacy-broken`) | 14 von 72 (11 der 61) |
| Kernmechanik fehlt im Legacy-Code (`not-found`) | 4 (`die-ewigen`, `prophet-des-untergangs`, `korrupter-richter`, `grabraeuber`) |
| belegte Widersprüche | 180 (`RM-C-001` bis `RM-C-180`), davon 156 mit Product-Owner-Bedarf |
| Product-Owner-Entscheidungen | 74 Einträge: 16 Querschnitt (`RM-DR-001` bis `-016`) und 58 Rollen (`RM-DR-101` bis `-158`) mit zusammen 160 Teilfragen |

„72“ ist durch Code, Texte, Akte, Karten und die ältere Matrix gleich belegt. Nur `ROADMAP.md` nennt „75+ Rollen“; das ist durch keine Quelle gedeckt. Zwölf migrierte Altnamen und die entfernte Rolle „Blinzelmädchen“ sind keine zusätzlichen Rollen ([`01`](01-canonical-role-catalog.md) §3).

## 3. Größte Risiken

**Die zehn größten Regelrisiken**

1. Drei verschiedene Wolfsbegriffe im Legacy-Code; über 20 Rollen hängen davon ab (RM-DR-002).
2. Einsätze gelten global pro Rollenname statt pro Person; Erbe und mehrere Kopien verhalten sich falsch (RM-DR-001).
3. „Wolfsangriff“ ist nicht definiert; Schutz-, Durchdringungs- und Vergeltungsrollen hängen daran (RM-DR-004).
4. Legacy prüft Schutz beim Zielen, Godot bei der Auflösung; Zusatzopfer und Schutzgeist verhalten sich dadurch anders als in der Web-App (RM-DR-004, RM-DR-005).
5. Fünf Stellen setzen einen Sieger; Einzelsiegrollen zählen als Dorfseite; vier Rollen ohne Siegcode (RM-DR-006, RM-DR-007).
6. „Links“ zeigt je nach Rolle in entgegengesetzte Richtungen; Nachbarschaft hängt an der Personen-ID statt an der Sitzfolge (RM-DR-003).
7. Seelentauscher erzeugt einen zweiten Wolf (Bug F4) und berührt Sieg und Fraktion (RM-DR-127).
8. Zeitwächter friert eine Nacht nur teilweise ein (RM-DR-150).
9. Vier Rollen beziehen sich auf Stimmen, die bewusst nicht digital erfasst werden (RM-DR-008).
10. Todesreaktionen laufen in Legacy außerhalb einer Warteschlange; ein Abbruch lässt die Morgenauflösung hängen, und „Neue Runde“ übernimmt alte Zustände ([`04`](04-rule-conflicts.md) X-02, X-03).

**Die zehn technisch schwierigsten Rollen**

| Rolle | Größe / Risiko | Grund |
|---|---|---|
| `zeitwaechter` | XL / kritisch | Rücknahme einer ganzen Nacht, setzt Undo/Redo voraus |
| `seelentauscher` | L / kritisch | Doppelwechsel von Rolle und Fraktion, Siegwirkung |
| `grabraeuber` | XL / hoch | Fähigkeit eines Toten übertragen; Regel nicht definiert |
| `kartenschlucker` | L / hoch | braucht Totenkarten-Modell |
| `nekromant` | L / hoch | globaler Schild, Pflicht-Umlenkung, Tagesbenennung |
| `voodoo-priester` | L / hoch | Umlenkung mehrerer Todesursachen mit Abklingzeit |
| `rotkaeppchen` | L / hoch | Kettentod plus „Fähigkeit doppelt“ für jede Rollenart |
| `dr-victor-frankenstein` | L / hoch | atomare Wiederbelebung mit Rollenwahl |
| `kutscher` | L / hoch | Mehrfach-Wiederbelebung, neue Rollen, ein neuer Wolf |
| `der-weise` | M / hoch | Einmalrettung, mehrtägige Blockade, sechs Widersprüche |

**Die zehn am einfachsten migrierbaren Rollen:** `siegreicher-wolf`, `waldlaeufer`, `dorfchronistin`, `die-gebundenen`, `dorfwache`, `selbstmoerder`, `doktor`, `nachtwaechter`, `traumdeuter`, `wahnsinniger-kutscher` (alle Größe S).

## 4. Empfohlener Umfang für Version 1.0

**Option B mit 25 Rollen** ([`05`](05-v1-role-options.md)): die 11 vorhandenen plus `siegreicher-wolf`, `besessener-wolf`, `dorfwache`, `waldlaeufer`, `doktor`, `ritter`, `wahnsinniger-kutscher`, `selbstmoerder`, `doppelspion`, `loki`, `kopfgeldjaeger`, `cerberus`, `schattenhund`, `rattenfaenger`. Dorf 14, Wölfe 7, Einzelsieg 4; keine Rolle mit hohem Risiko; keine Abhängigkeit von Totenkarten, Stimmen oder Wiederbelebung. Option A (20) ist die Minimalvariante, Option C (30) ergänzt fast den ganzen Akt I.

## 5. Erste Charge

**K1 · Sieg- und Zählregeln:** `siegreicher-wolf`, `selbstmoerder`, `doppelspion` ([`06`](06-implementation-batches.md) §3). Alle drei ändern nur die Siegprüfung, haben keinen Nachtschritt, sind vollständig automatisierbar und brauchen nur eine Erweiterung eines bereits gut getesteten Systems. Größe S bis M, Risiko niedrig.

## 6. Notwendige Entscheidungen

- **Für K1:** RM-DR-007 (Dorfsieg bei lebenden Einzelsiegrollen), RM-DR-016 (eine Kopie je Sonderrolle), RM-DR-138 (`selbstmoerder`), RM-DR-155 (`doppelspion`).
- **Für Option B insgesamt:** zusätzlich RM-DR-001 bis -004, -009, -010, -011, -014, -015 sowie die Rollenentscheidungen RM-DR-101, -103, -116, -119, -123, -124, -135, -136, -139, -145, -147.
- Alle Empfehlungen stehen in [`08`](08-decision-request.md); keine ist entschieden.

## 7. Realistischer nächster Schritt

1. Der Product Owner entscheidet die vier K1-Entscheidungen (und möglichst die Querschnittsentscheidungen für Option B).
2. Danach schreibt `Grimmhain-2` die Spezifikation der Charge K1 (Regelregister DE/EN, Akzeptanzszenarien, Umsetzungsgrenze) nach dem Muster von `docs/specs/vertical-slice/`, ohne Godot-Code.
3. Erst nach Freigabe dieser Spezifikation folgt die testgetriebene Umsetzung von K1 im Kern.

## 8. Spätere Änderungen an bestehenden Dokumenten (bewusst nicht vorgenommen)

| Datei | Vorgeschlagene Änderung | Grund |
|---|---|---|
| `ROADMAP.md` | „75+ Rollen“ → 72 | nicht belegbar |
| `godot/README.md` | Dateiverantwortung von `role_catalog.gd` auf alle 11 Rollen; EN-Name `waldhexe` „Witch of the Woods“ | veraltet bzw. abweichend vom Regelregister |
| `godot/core/rules/role_catalog.gd`, `godot/tests/unit/test_waldhexe.gd` (nur Kommentare) | „Forest Witch“ → „Witch of the Woods“ | Konsistenz; Produktions- und Testdateien durften hier nicht geändert werden |
| `docs/godot-migration/01-current-system-inventory.md` | F2 um sechs Wolfsrollen ergänzen; F7 „fünf Siegstellen“; `PackfatherBlockNextDay` „gelesen, nie gesetzt“ | [`04`](04-rule-conflicts.md) §6 |
| `docs/godot-migration/04-rules-migration-matrix.md` | 32 Einstufungen, A-13, A-47/A-57, A-64; Hinweis auf diese Planung | [`04`](04-rule-conflicts.md) §5 und §6 |
| `docs/godot-migration/07-open-questions.md` | Q4-Priorität als überholt markieren; Q1-Tabelle auf RM-DR verweisen | DECISION-LOG DR-02 |
| `docs/masterplan/DECISION-LOG.md` | Einträge nach den Entscheidungen RM-DR-### | erst nach Product-Owner-Entscheidung |
| `GRIMMHAIN-REVOLUTION-MASTERPLAN.md` Phase 0 | Checkbox „20 bis 30 Kandidaten auswählen“ erst nach Entscheidung zu [`05`](05-v1-role-options.md) abhaken | Auswahl ist nur vorgeschlagen |
| `docs/masterplan/CLAUDE-PROMPTS.md` | Prompt für die K1-Spezifikation ergänzen | Arbeitsvertrag |
| `NIGHT-REPORT-abilities.md`, `AUDIT.md`, `GRIMMHAIN_ANALYSE_2026-06-12.md` | als historisch kennzeichnen | mehrere Befunde behoben ([`04`](04-rule-conflicts.md) §6) |
