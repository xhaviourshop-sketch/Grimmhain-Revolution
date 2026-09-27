# 00 · Methode, Quellen und Statusmodell

**Stand:** 2026-09-26 · **Branch:** `claude/happy-bell-dhgkod` · **Basiscommit:** `4673b0b` (= `origin/main` zum Arbeitsbeginn, per `git fetch origin` und `git merge-base` geprüft)
**Art:** reine Dokumentation und Analyse. Kein Produktionscode, keine Spielregel, keine UI-, Asset-, Audio- oder Projektdatei wurde geändert.

## 1. Zweck und Dokumente

Diese Planung beantwortet, welche Rollen es gibt, welche im Godot-Kern umgesetzt sind, was die übrigen tun, wo Text, Legacy-Code und Dokumentation sich widersprechen, welche Rollen sich für Version 1.0 eignen, in welcher Reihenfolge und in welchen Chargen die übrigen umgesetzt werden und welche Entscheidungen der Product Owner treffen muss.

| Datei | Inhalt |
|---|---|
| [`01-canonical-role-catalog.md`](01-canonical-role-catalog.md) | kanonische Liste aller 72 Rollen, Aliase, Legacy-Texte |
| [`02-implemented-roles-audit.md`](02-implemented-roles-audit.md) | Audit der 11 Godot-Rollen |
| [`03-remaining-roles-analysis.md`](03-remaining-roles-analysis.md) | Analyse der 61 fehlenden Rollen |
| [`04-rule-conflicts.md`](04-rule-conflicts.md) | Widersprüche (`RM-C-###`), Legacy-Bugs, Abweichungen zu älteren Dokumenten |
| [`05-v1-role-options.md`](05-v1-role-options.md) | Optionen mit 20, 25 und 30 Rollen, Empfehlung |
| [`06-implementation-batches.md`](06-implementation-batches.md) | 16 Chargen, erste Charge im Detail |
| [`07-test-strategy.md`](07-test-strategy.md) | Testgruppen je Rolle, Kombinationsmatrix, Golden-Szenarien |
| [`08-decision-request.md`](08-decision-request.md) | Entscheidungen `RM-DR-###` |
| [`09-executive-summary.md`](09-executive-summary.md) | Kurzfassung |
| [`dossiers/`](dossiers/) | Belegdossiers: vollständige Code-Lektüre je Rollengruppe |
| `../../tools/role-migration/check-role-docs.js` | Konsistenzprüfung dieser Dokumente (nur lesend) |

## 2. Vorgehen

1. **Ausgangspunkt:** `git fetch origin`; Branch zeigt auf `origin/main` (`4673b0b`). Legacy-Dateien (`js/`, `game.html`, `app/`) sind seit dem Stand der älteren Analyse (`2109445`) unverändert (`git diff 2109445 HEAD -- js game.html app` leer), Zeilenangaben der älteren Dokumente sind daher vergleichbar.
2. **Gelesen:** `CLAUDE.md` (eine `AGENTS.md` existiert nicht), Masterplan, `DECISION-LOG.md`, `RULE-MIGRATION-MATRIX.md`, `TEST-MATRIX.md`, `CLAUDE-PROMPTS.md`, alle Dokumente unter `docs/specs/vertical-slice/` und `docs/godot-migration/` (01 bis 07 gezielt nach Rollen), `godot/README.md`, `godot/core/rules/role_catalog.gd` sowie die Rollenregeln und Rollentests unter `godot/core/` und `godot/tests/unit/`.
3. **Rollenbestand:** `ALL_ROLES` und alle Rollen-Stammdaten aus `js/core/roles.js` per Skript geladen und gegen jede andere Rollenliste abgeglichen (Akte, i18n, `role-abilities.js`, Setup-Grenzen, Kartenbilder, React-Adapter, Godot-Katalog, Werkzeuge, Totenkarten, Dokumente). Ergebnis: [`dossiers/inventory.md`](dossiers/inventory.md).
4. **Legacy-Verhalten je Rolle:** Die 61 fehlenden Rollen wurden in acht Gruppen parallel per Code-Lektüre geprüft (Nacht-Handler, Morgenauflösung, Hinrichtung, `applyKill` und Todesfolgen, Siegprüfung, Nachtreihenfolge, Blockaden, React-Adapter, ältere Berichte). Jede Gruppe folgt einer festen Vorlage mit Pflichtfeldern (Namen, Aliase, Fraktion, Akte, Priorität, Fundstellen, wörtliche Texte DE und EN, DE/EN-Vergleich, Schritt-für-Schritt-Verhalten, React, Prüfung der bisherigen Doku, Widerspruchstabelle, Bugs, Status, Automation, Mechanik, Systeme, Abhängigkeiten, Größe und Risiko, offene Fragen, Testgruppen, Belegsicherheit). Die Rohbefunde stehen unverändert in [`dossiers/`](dossiers/).
5. **Stichproben durch die Hauptsitzung** (selbst im Code nachgeprüft, alle bestätigt): F2 fehlende Rudelzeile (`js/core/night.js:50-55`), F5 toter Lehrling erbt (`js/ui/core.js:389`), Schutzengel-Verbrauch beim Antippen (`js/core/abilities-roles-chunk.js:157-162`), Rattenfänger-Sieg nur aus dem Handler (`checkFluteWin`, `js/ui/core.js:275`, Aufrufe nur `abilities-roles-chunk.js:659,670`), Kriegerin tötet getroffenen Wolf nicht (`abilities-roles-chunk.js:554-570`), Nachtwächter-Ausgabe nur No-op-Sound (`night.js:535-560`, `js/ui/audio.js:12`), Seelentauscher F4 über `isWolf` mit veraltetem `flags.werewolf` (`abilities-roles-chunk.js:774-783`, `js/ui/core.js:8-19`), Todesprediger-Zählung über `MorningCount` (`js/ui/core.js:153-160`, `night.js:191`).
6. **Godot-Stand:** RoleCatalog, Kernsysteme und Tests gelesen; vollständiger Testlauf `godot/tests/run_all.sh` (Godot 4.7.2) mit 351 grünen Tests.
7. **Verdichtung:** Einstufungen (Status, Automation, primäre Mechanik, Größe, Risiko, Charge, 1.0-Option) hat die Hauptsitzung je Rolle festgelegt; Widerspruchstabellen und offene Fragen wurden maschinell aus den Dossiers in `04` und `08` übernommen und mit IDs versehen, ohne Inhalte zu verändern.

## 3. Statusmodelle

Es werden ausschließlich diese Werte verwendet. Jede Rolle hat genau einen **Migrationsstatus** (Stand im Godot-Kern) und genau einen **Legacy-Befund** (Stand der alten Web-App).

### 3.1 Migrationsstatus

| Wert | Bedeutung |
|---|---|
| `implemented-and-tested` | Rolle im `RoleCatalog`, Regeln im Kern umgesetzt, eigene oder gleichwertige headless Tests grün |
| `implemented-partial` | Teile im Kern vorhanden, Kernverhalten unvollständig oder ungetestet |
| `documented-only` | nicht im Kern; Regel ausreichend belegt, Standardauslegung ohne blockierende Product-Owner-Frage beschrieben |
| `decision-required` | nicht im Kern; mindestens eine Product-Owner-Entscheidung blockiert eine verbindliche Regel |
| `deferred` | durch eine bereits getroffene Entscheidung aus dem aktuellen Plan genommen |

### 3.2 Legacy-Befund

| Wert | Bedeutung |
|---|---|
| `legacy-verified` | Code setzt den Rollentext nachvollziehbar um; Abweichungen nur in nicht beschriebenen Details |
| `legacy-contradictory` | Text, Code oder Dokumentation widersprechen sich, ohne dass der Code die Kernfunktion offensichtlich zerstört |
| `legacy-broken` | ein belegter Codefehler verhindert oder verfälscht die Kernfunktion |
| `not-found` | der Text verspricht eine Kernmechanik, die im Code nicht existiert |

### 3.3 Automation

| Wert | Bedeutung |
|---|---|
| `automatic` | Kern berechnet und wendet alles an; Eingaben sind nur die Zielwahl der handelnden Person |
| `assisted` | Kern führt, prüft und protokolliert; eine Spielleitereingabe ist Teil der Regel (Tischfrage, freie Zahl, Bestätigung einer großen Wirkung) |
| `manual-only` | nur Hinweis und Notiz, keine Regelwirkung |
| `unknown` | nicht bestimmbar, solange die Regel offen ist |

Bei den 61 fehlenden Rollen ist der Automationswert das **Ziel nach Klärung** der Entscheidungen, nicht der heutige Zustand.

### 3.4 Größe und Risiko

Relative Größen statt Tagen: **S** (eine Regel, kein neues System), **M** (neue Regel mit Einbindung in ein vorhandenes System), **L** (neues Teilsystem oder mehrere Wechselwirkungen), **XL** (berührt den Nachtablauf oder den Zustand aller Rollen). Risiko: **niedrig**, **mittel**, **hoch**, **kritisch** (Fehler verfälscht Sieg, Fraktion oder den gesamten Nachtverlauf). Schätzungen stützen sich auf die in den Dossiers benannten Wechselwirkungen, nicht auf Messungen.

## 4. Kennzeichnung der Aussagen

In den Dokumenten wird unterschieden: **Rollentext** (wörtlich aus `js/core/roles.js`), **Legacy-Code** (mit Pfad und Zeilen), **React-Version** (`app/src/**`), **bisherige Dokumentation**, **Godot-Kern**, **Empfehlung** und **unentschieden**. Wörtliche Rollentexte in [`01`](01-canonical-role-catalog.md) §4 sind unverändert; in den Dossiers ist ein Gedankenstrich als `(U+2014)` geschrieben.

## 5. Rollenanzahl und Abweichungen

**Nachweisbare Zahl: 72.** Belege in [`01`](01-canonical-role-catalog.md) §1 und [`dossiers/inventory.md`](dossiers/inventory.md).

| Quelle | Zahl | Einordnung |
|---|---:|---|
| `ALL_ROLES`, `ROLE_DESCRIPTIONS`, `ROLE_NAMES_EN`, `ROLE_DESCRIPTIONS_EN`, `ROLE_ABILITIES` | je 72 | deckungsgleich |
| Vereinigung der Akte I bis IV | 72 | „72/72 abgedeckt“ in `js/core/akte.js:3` stimmt |
| Kartenbilder DE / EN | je 73 Dateien | 72 Rollen plus Rückseite |
| `CARD_MAP_EN` (`game.html`, `app/src/roleCard.ts`) | 71 | Mapping-Lücke `Rachsüchtiger Wolf`, keine fehlende Rolle |
| `ORDER_BASE` | 50 | Rollen mit Nachtzeile, Teilmenge |
| Fähigkeits-Handler | 49 | Teilmenge |
| `WOLF_ROLES_SET` / `SOLO_WIN_ROLES` | 19 / 14 | Fraktionen, Dorf 39 |
| Godot `RoleCatalog.ROLES` | 11 | umgesetzt |
| `ROADMAP.md` | „75+“ | nicht belegbar |

Keine Rolle wurde zusammengeführt. Altnamen (13 migrierte, darunter die entfernte Rolle `Blinzelmädchen`), nicht migrierte Altnamen (`Mogli`, `Busfahrer`), ein falscher Schlüssel (`Chronist`) und abweichende EN-Namen sind in [`01`](01-canonical-role-catalog.md) §3 aufgelöst.

## 6. Grenzen der Analyse

- **Keine Laufzeitprüfung der Legacy-App.** Alle Legacy-Aussagen stammen aus Code-Lektüre. Abläufe mit Abbruch, Überlagerung von Dialogen und React-Spiegelung (z. B. Frankenstein-Dropdown) sind aus dem Codefluss abgeleitet; die Dossiers markieren das unter „Belegsicherheit“.
- **Stichproben statt Vollprüfung der Dossiers.** Die Hauptsitzung hat acht folgenreiche Befunde selbst nachgeprüft (§2 Punkt 5), nicht jede Zeilenangabe.
- **Tischgeometrie ungeprüft.** Ob „links“ in der App der linken Hand einer Person am Tisch entspricht, lässt sich ohne Gerät nicht prüfen (RM-DR-003).
- **Godot-Tests inhaltlich stichprobenartig.** Aussage „getestet“ stützt sich auf den grünen Lauf und die Testnamen.
- **Totenkarten** wurden nur so weit gelesen, wie Rollen sie berühren; ihre 80 Effekte sind nicht Gegenstand dieser Planung.
- **Keine Aufwandsschätzung in Tagen.** Größen sind relativ (§3.4).
- **Ältere Berichte** (`AUDIT.md`, `GRIMMHAIN_ANALYSE_2026-06-12.md`, `NIGHT-REPORT-*.md`, `ROLE-FLOW-REPORT.md`, `SPECIAL-ROLE-FLOW-REPORT.md`, `FIX_REPORT.md`) wurden nach Rollennamen durchsucht und nur als Hinweisquelle genutzt; mehrere ihrer Befunde sind inzwischen behoben ([`04`](04-rule-conflicts.md) §6).

## 7. Aussagekraft der vorhandenen Prüfungen

| Prüfung | Ergebnis am Basiscommit | Aussagekraft |
|---|---|---|
| `godot/tests/run_all.sh` | 351 Tests, 0 fehlgeschlagen, Exit 0 | echte Verhaltenstests des Godot-Kerns und der UI-Grundlage; betrifft nur die 11 umgesetzten Rollen |
| `node tests/smoke.js` (`npm test`) | „smoke: OK“, Exit 0 | prüft nur Textvorkommen in Legacy-Dateien, kein Verhalten |
| `node tools/compare-i18n.js` | 0 fehlende Schlüssel DE/EN, Exit 0 | prüft nur Schlüsselgleichheit im Legacy-i18n, nicht Inhalt oder Rollentexte |
| `node tools/role-migration/check-role-docs.js` | siehe Abschlussbericht | prüft nur Konsistenz dieser Dokumente untereinander und gegen `ALL_ROLES`/`RoleCatalog` |
| GitHub-CI `godot-core-tests.yml` | läuft nur bei Änderungen unter `godot/` | durch diese Dokumentänderungen nicht ausgelöst |
