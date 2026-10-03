# 09 · Zusammenfassung Rollenmigration

**Stand:** Analyse 2026-09-26 (Basis `4673b0b`), konsolidiert 2026-09-27 gegen `origin/main` `5eb5f2a`, Antworten vom 3. Oktober 2026 eingetragen · Planung; entschieden ist nur, was mit Decision-Log-Quelle genannt ist; kein Code geändert

## 1. Aktueller Stand

- Der Godot-**Regelkern** enthält **11 von 72 Rollen**. Ihr Verhalten ist durch automatisierte headless Tests belegt (351 Tests am Basiscommit).
- Das ist **keine** Produktabnahme:
  - Über die Oberfläche in `main` ist keine Rolle bedienbar; es gibt dort nur die Erfassung der Spielernamen.
  - Eine vollständige Runde über die Oberfläche wurde nicht gespielt.
  - Kein Test lief auf einem Tablet.
  - Ein Rollen-Setup entsteht parallel bei Grimmhain-1, ist aber noch nicht in `main`.
  - Geltungsbereich je Rolle: [`02`](02-implemented-roles-audit.md) §1a.
- Die übrigen **61 Rollen** gibt es nur in der alten Web-App.
- Die Optionen A/B/C für Version 1.0 sind Vorschläge und nicht freigegeben.

## 2. Zahlen

| | Anzahl |
|---|---:|
| Rollen insgesamt (nachgewiesen) | **72** (Dorf 39, Wölfe 19, Einzelsieg 14) |
| im Regelkern umgesetzt und durch headless Tests belegt | 11 |
| davon über die Oberfläche bedienbar / in voller Runde geprüft / auf Tablet geprüft | 0 / 0 / 0 |
| im Regelkern teilweise umgesetzt | 0 |
| fehlend | 61 (davon 3 mit ausreichend klarer Regel, 58 mit offener Frage) |
| Legacy-Befund `legacy-verified` / `legacy-contradictory` / `legacy-broken` / `not-found` | 26 / 28 / 14 / 4 von 72 (19 / 27 / 11 / 4 der 61) |
| belegte Widersprüche | 180 (`RM-C-001` bis `RM-C-180`), davon 156 mit Product-Owner-Bezug |
| Entscheidungseinträge nach Konsolidierung | 75 (2 entschieden, 3 Produktentscheidung, 1 technisch, 65 später, 4 Quellenprüfung) |
| Fragen nach Konsolidierung | 188 (12 entschieden, 7 Produktentscheidung, 3 technisch, 162 später, 4 Quellenprüfung) |
| davon jetzt zu beantworten | **4** ([`10`](10-next-decisions.md)) |

„72“ ist durch Code, Texte, Akte, Karten und die ältere Matrix gleich belegt. Nur `ROADMAP.md` nennt „75+ Rollen“; das ist durch keine Quelle gedeckt. Zwölf migrierte Altnamen und die entfernte Rolle „Blinzelmädchen“ sind keine zusätzlichen Rollen ([`01`](01-canonical-role-catalog.md) §3).

## 3. Größte Risiken

**Die zehn größten Regelrisiken bei der weiteren Migration**

1. Drei verschiedene Wolfsbegriffe im alten Code. Für Siegprüfung und Orakel ist der Godot-Begriff festgelegt (G-SIEG-1/2, DR-07); für andere Zählungen und Wirkungen ist er offen (RM-DR-002.3).
2. Einsätze gelten im alten Code global pro Rollenname. Für Godot ist das entschieden (G-ID-3); jede portierte Rolle muss davon bewusst abweichen, statt Legacy zu kopieren.
3. „Wolfsangriff“ ist nicht definiert; Schutz-, Durchdringungs- und Vergeltungsrollen hängen daran (RM-DR-004).
4. Der alte Code prüft Schutz beim Zielen, Godot bei der Auflösung. Zusatzopfer und Schutzgeist verhalten sich dadurch anders als in der Web-App (RM-DR-004, RM-DR-005).
5. Im alten Code setzen fünf Stellen einen Sieger. In Godot gilt eine Kandidatenmenge (entschieden); vier Rollen haben aber keine Siegbedingung (RM-DR-006).
6. „Links“ zeigt je nach Rolle in entgegengesetzte Richtungen; Nachbarschaft hängt an der Personen-ID statt an der Sitzfolge (RM-DR-003, Gerätecheck RM-DR-146.1).
7. Seelentauscher erzeugt einen zweiten Wolf (Bug F4) und berührt Sieg und Fraktion (RM-DR-127).
8. Zeitwächter friert eine Nacht nur teilweise ein (RM-DR-150).
9. Vier Rollen beziehen sich auf Stimmen, die bewusst nicht digital erfasst werden (RM-DR-008).
10. Todesreaktionen laufen im alten Code außerhalb einer Warteschlange; ein Abbruch lässt die Morgenauflösung hängen, und „Neue Runde“ übernimmt alte Zustände ([`04`](04-rule-conflicts.md) X-02, X-03).

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

**Die zehn am einfachsten migrierbaren Rollen:** `siegreicher-wolf`, `waldlaeufer`, `dorfchronistin`, `die-gebundenen`, `dorfwache`, `selbstmoerder`, `doktor`, `nachtwaechter`, `traumdeuter`, `wahnsinniger-kutscher` (alle Größe S). „Einfach“ heißt klein im Regelkern; `selbstmoerder` ist als Rolle klein, führt aber ein neues Siegkonzept ein ([`06`](06-implementation-batches.md) §3.5).

## 4. Umfang für Version 1.0 (Vorschlag)

Empfohlen ist weiterhin **Option B mit 25 Rollen** ([`05`](05-v1-role-options.md)); sie ist nicht freigegeben. Korrigiert ist die Risikoaussage: Keine Rolle in B hat einzeln ein hohes Risiko, aber B verlangt drei neue Grundsysteme aus Chargen mit hohem Risiko (Bindungsmodell für `loki`, Rollenblockierung für `schattenhund`, Statusmarker für `rattenfaenger`), siehe [`05`](05-v1-role-options.md) §5a.

## 5. Nächste Einheit

Entschieden am 3. Oktober 2026 (RM-DR-017 = C): **K1a = `siegreicher-wolf` und `doppelspion`**, **K1b = `selbstmoerder`**, getrennt spezifiziert unter [`../specs/k1a-siegreicher-wolf-doppelspion/`](../specs/k1a-siegreicher-wolf-doppelspion/rules-register.md) und [`../specs/k1b-selbstmoerder/`](../specs/k1b-selbstmoerder/rules-register.md). Größe K1a M, Risiko mittel; K1 gesamt M bis L (Schätzung, [`06`](06-implementation-batches.md) §3.5).

## 6. Notwendige Entscheidungen

RM-DR-017, RM-DR-155.1, .3, .4 und RM-DR-138.1, .3, .4 sind entschieden. Die Folgefragen RM-DR-138.6, .7 und RM-DR-155.6 sind ebenfalls entschieden (Ergänzung vom 3. Oktober 2026). Für K1 ist keine Produktfrage mehr offen: K1a und K1b: **bereit zur Umsetzung, wartet auf Grimmhain-1**.

## 7. Realistischer nächster Schritt

1. Abstimmung mit Grimmhain-1 über die Katalogerweiterung ([`06`](06-implementation-batches.md) §3.7).
2. Danach testgetriebene Umsetzung im Kern, zuerst K1a.

## 8. Spätere Änderungen an bestehenden Dokumenten (bewusst nicht vorgenommen)

| Datei | Vorgeschlagene Änderung | Grund |
|---|---|---|
| `ROADMAP.md` | „75+ Rollen“ → 72 | nicht belegbar |
| `godot/README.md` | Dateiverantwortung von `role_catalog.gd` auf alle 11 Rollen; EN-Name `waldhexe` „Witch of the Woods“ | veraltet bzw. abweichend vom Regelregister |
| `godot/core/rules/role_catalog.gd`, `godot/tests/unit/test_waldhexe.gd` (nur Kommentare) | „Forest Witch“ → „Witch of the Woods“ | Konsistenz; Produktions- und Testdateien durften hier nicht geändert werden |
| `docs/godot-migration/01-current-system-inventory.md` | F2 um sechs Wolfsrollen ergänzen; F7 „fünf Siegstellen“; `PackfatherBlockNextDay` „gelesen, nie gesetzt“ | [`04`](04-rule-conflicts.md) §6 |
| `docs/godot-migration/04-rules-migration-matrix.md` | 32 Einstufungen, A-13, A-47/A-57, A-64; Hinweis auf diese Planung | [`04`](04-rule-conflicts.md) §5 und §6 |
| `docs/godot-migration/07-open-questions.md` | Q4-Priorität als überholt markieren; Q1-Tabelle auf RM-DR verweisen | DECISION-LOG DR-02 |
| `docs/masterplan/DECISION-LOG.md` | weitere Einträge nach den Entscheidungen RM-DR-### (K1 eingetragen am 3. Oktober 2026) | erst nach Product-Owner-Entscheidung |
| `GRIMMHAIN-REVOLUTION-MASTERPLAN.md` Phase 0 | Checkbox „20 bis 30 Kandidaten auswählen“ erst nach Entscheidung zu [`05`](05-v1-role-options.md) abhaken | Auswahl ist nur vorgeschlagen |
| `docs/masterplan/CLAUDE-PROMPTS.md` | Prompt für die Umsetzung von K1a und K1b ergänzen, sobald die Spezifikationen freigegeben sind | Arbeitsvertrag |
| `NIGHT-REPORT-abilities.md`, `AUDIT.md`, `GRIMMHAIN_ANALYSE_2026-06-12.md` | als historisch kennzeichnen | mehrere Befunde behoben ([`04`](04-rule-conflicts.md) §6) |
| `godot/tests/ui/test_role_model.gd` (Branch `claude/sleepy-babbage-u2o0i2`, Grimmhain-1) | feste Zahl „exakt elf produktive Rollen“ vor der ersten neuen Rolle anpassen oder aus dem Katalog ableiten | sonst rot, sobald eine Rolle in den `RoleCatalog` kommt ([`06`](06-implementation-batches.md) §3.7) |
| `godot/content/i18n/ui.*.po`, `RolePresentation.ROLE_ORDER` (Grimmhain-1) | Namen, Kurztexte und Reihenfolge je neuer Rolle | Rollen-Setup zeigt sonst Rohschlüssel bzw. Reihenfolge nach ID |
| `docs/masterplan/RULE-MIGRATION-MATRIX.md` | Spalte „Automationsstatus“ um einen Hinweis ergänzen, dass „implemented“ nur den Regelkern meint | Geltungsbereich ([`02`](02-implemented-roles-audit.md) §1a); Datei liegt jetzt außerhalb des erlaubten Bereichs |
