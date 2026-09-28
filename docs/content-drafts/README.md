# Inhaltsentwürfe: Rollenlexikon und Spielleitertexte

**Status:** Entwurf. Nichts hier ist automatisch freigegebener Produktionsinhalt. Es gibt keine Aufnahme, keine Einbindung in `godot/`, keine Änderung an Regeln, Entscheidungen oder Übersetzungsdateien.
**Bearbeitung:** 29.09.2026, Branch `content/rolebook-and-guide`, Worktree `C:/Users/Marku/Desktop/Grimmhain/grimmhain-content-drafts`.

## 1. Quelle

| Angabe | Wert |
|---|---|
| Regelquelle | Branch `audit/all-72-roles`, gesicherter Stand (lokal und `origin` gleich) |
| Quell-Commit | `312f5bbbbec4c218754b35a0043b51e79d80bcf5` |
| Commit-Betreff | `docs(roles): promote fate wolf, lone wolf and time warden; record E-35, E-36, DA-11 to DA-20` |
| Rollenliste | `godot/core/rules/role_catalog.gd`, Konstante `ROLES`: 71 Einträge (39 Dorf, 19 Werwölfe, 13 Einzelsieg) |
| Zurückgestellt | `kartenschlucker` (72. Rolle der Legacy-Liste), blockiert wegen Totenkarten (OI-02) |

Bei neueren Commits auf dem Audit-Branch, im Regelkern oder im UI-Branch gilt die Abgleichsliste in Abschnitt 6.

## 2. Umfang und Dateien

| Datei | Inhalt |
|---|---|
| [`rolebook/01-village-information.md`](rolebook/01-village-information.md) | 17 Rollen: Dorfbewohner, Orakel, Chronistin, Gebundene, Waldläufer, Doktor, Fährtenleser, Spürhund, Traumdeuter, Kopfgeldjäger, König, Kriegerin des Lichts, Blutpriester, Amalia, Detektiv, Die Ewigen, Nachtwächter |
| [`rolebook/02-village-protection.md`](rolebook/02-village-protection.md) | 12 Rollen: Schutzengel, Waldhexe, Der Weise, Märtyrerin, Schutzgeist, Dorfschmied, Verdammniswächter, Dorfwache, Ritter, Wächter am Tor, Zeitwächter, Sensenträger |
| [`rolebook/03-village-bonds-and-changes.md`](rolebook/03-village-bonds-and-changes.md) | 10 Rollen: Wolfskind, Lehrling, Loki, Rotkäppchen, Seelentauscher, Kutscher, Dr. Victor Frankenstein, Wahnsinniger Kutscher, Henker, Korrupter Richter |
| [`rolebook/04-wolves-pack.md`](rolebook/04-wolves-pack.md) | 10 Rollen: Werwolf, Trugbilderwolf, Spiegelwolf, Siegreicher Wolf, Besessener Wolf, Blutwolf, Seuchenwolf, Rudelvater, Fenrir, Cerberus |
| [`rolebook/05-wolves-special.md`](rolebook/05-wolves-special.md) | 9 Rollen: Schattenhund, Albtraumwolf, Giftwolf, Schwarze Witwe, Schattenwanderer, Dämonischer Wolf, König Lykaon, Rachsüchtiger Wolf, Schicksalswolf |
| [`rolebook/06-solo-1.md`](rolebook/06-solo-1.md) | 7 Rollen: Manipulator, Doppelspion, Selbstmörder, Parasit, Rattenfänger, Pestbringerin, Todesprediger |
| [`rolebook/07-solo-2.md`](rolebook/07-solo-2.md) | 6 Rollen: Prophet des Untergangs, Feuerteufel, Voodoo-Priester, Nekromant, Hades, Grabräuber |
| [`GUIDE-TEXTS.md`](GUIDE-TEXTS.md) | Allgemeine Texte für Nachtbeginn, Morgen, Diskussion, Nominierung, Hinrichtung, Spielende; je Rolle Texte in den drei Kategorien `[SL-PRIVAT]`, `[PERSON-PRIVAT]`, `[ÖFFENTLICH]` |
| [`TERMINOLOGY.md`](TERMINOLOGY.md) | Einheitliche DE/EN-Begriffe |
| [`OPEN-ISSUES.md`](OPEN-ISSUES.md) | 19 offene Punkte und Quellenkonflikte mit Quellenstellen |
| [`check-coverage.py`](check-coverage.py) | Vollständigkeits- und Paritätsprüfung, siehe Abschnitt 5 |

Aufbau eines Rolleneintrags: stabile Rollen-ID, Name und Fraktion, kurze Fähigkeit, Zeitpunkt und Nutzungslimit, Zielbeschränkungen, wichtige Ausnahmen, Siegbedingung, zwei Beispiele, Hinweis für die Spielleitung, Quellenangabe. Jede Zeile steht in DE und EN nebeneinander.

## 3. Status

- **Rollen mit Entwurf:** 71 von 71 implementierten Rollen. Keine fehlt, keine doppelt (Prüfung Abschnitt 5).
- **Regelgrundlage:** Alle Rollen sind im Audit-Stand grün (`11-role-audit-status.md` §2: 71 grün, 1 blockiert). Grün gilt nur für den Regelkern, nicht für Oberfläche oder Tablet.
- **Nicht vom Product Owner einzeln ausgewählt:** Schicksalswolf (DA-11 bis DA-15), Rachsüchtiger Wolf (Rhythmus und Angriff, DA-16 bis DA-18), Zeitwächter (Einzelheiten, DA-19), Hades und Grabräuber (DA-01 bis DA-09) sowie Siegreicher Wolf (Auslegung des Rollentexts, OI-03).
- **22 Rolleneinträge tragen einen Verweis auf einen offenen Punkt** (Suche nach `OI-` in `rolebook/`). Bei 18 davon fehlt eine Regelinformation oder es liegt ein Konflikt vor (OI-01 bis OI-03, OI-07, OI-08, OI-10 bis OI-15, OI-17, OI-19); die übrigen 4 (Fährtenleser, Detektiv, König, Sensenträger) tragen nur einen Hinweis (OI-05, OI-06, OI-09).
- **Entwurfsannahmen ohne Quelle** sind als solche benannt: die Namensnennung des Schutzgeists in der öffentlichen Ansage und der fehlende öffentliche Hinweis auf den Fluch des Weisen (OI-11), das Aufrufmuster für Rollen mit eigenem Schritt (OI-01).
- **Nicht geprüft:** Lesbarkeit der Karten auf dem Tablet, Übersetzungsqualität durch eine Muttersprachlerin oder einen Muttersprachler, Länge in der echten UI. Die Karten wurden nur auf 140 Zeichen je Sprache begrenzt.

## 4. Kurzformen der Quellen

| Kürzel | Fundstelle |
|---|---|
| `DR-nn` | `docs/masterplan/DECISION-LOG.md`, Abschnitte "Vertical Slice · Detailfragen und Rollenentscheidungen" |
| `RM-DR-nnn` | Entscheidungs-ID aus `docs/role-migration/decision-status.csv` und dem Decision Log |
| `F-nn`, `I-nn`, `S-nn`, `B-nn`, `R-nn`, `V-nn`, `W-nn`, `E-nn` | Fragen-IDs der Rollenaudit-Einträge im Decision Log (Fragen der Chargen: Querschnitt, Information, Schutz, Bindung, Rotkäppchen, Verwandlung, Wiederbelebung, Einzelsieg) |
| `DA-nn` | Vom Decision Log als technisch oder fachlich abgeleitet unter delegierter Autorisierung gekennzeichnet, keine Auswahl des Product Owners |
| `G-...` | Grundregeln in `docs/specs/vertical-slice/rules-register.md` §0 |
| `OI-nn` | [`OPEN-ISSUES.md`](OPEN-ISSUES.md) dieses Ordners |

Bei Widerspruch zwischen Quellen gilt der jüngere datierte Eintrag im Decision Log (siehe dessen Kopfzeile). Wo das Regelregister ältere Formulierungen ohne Vermerk trägt, folgen die Entwürfe dem Decision Log (OI-05).

## 5. Prüfungen

Aus dem Repository-Wurzelverzeichnis des Worktrees:

```
python docs/content-drafts/check-coverage.py
git diff --check
```

`check-coverage.py` liest die Rollen-IDs aus `godot/core/rules/role_catalog.gd` (nur lesend) und prüft:

1. jede Katalogrolle hat genau einen Eintrag im Rollenlexikon, keine unbekannte ID;
2. jeder Eintrag hat alle acht Tabellenzeilen mit gefüllten DE- und EN-Zellen und eine Quellenzeile;
3. Zahlen einer Zeile stimmen in DE und EN überein;
4. `GUIDE-TEXTS.md` hat je Rolle genau eine Zeile in jeder der vier Rollentabellen;
5. keine Gedankenstriche und keine internen Begriffe wie "Lynch" in den Entwurfstexten.

Die Bedeutungsgleichheit von DE und EN wurde zusätzlich Zeile für Zeile gelesen und ist damit nicht automatisiert bewiesen.

## 6. Was später abgeglichen werden muss

- **Regelstand:** Jede Änderung am Audit-Branch, am Regelkern (`godot/core/`) oder am Decision Log seit `312f5bb` gegen `rolebook/` prüfen, besonders Entscheidungen zu Totenkarten, Kartenschlucker, Zufallsknopf und Setup-Regeln.
- **UI-Stand:** Sobald der UI-Branch Rollenkarten, Ansagekarten und Lexikonansichten liefert: Kartenlänge, Schlüsselnamen, Zeilenumbrüche und Platzhalter prüfen, dann Texte in `godot/content/i18n/ui.*.po` überführen (Schlüsselbildung mit Unterstrich oder Bindestrich klären, OI-04).
- **Sprechertext:** `docs/assets/NARRATOR-SCRIPT.md` hat eigene Schlüssel und einen eigenen Stand. GUIDE-TEXTS §2 übernimmt dessen Zeilen wörtlich, ergänzt aber Namensteile. Beide Dateien nach Entscheidung von OI-01 und OI-18 zusammenführen.
- **Kurztexte in `ui.*.po`:** Abweichende Begriffe nach TERMINOLOGY §4 angleichen (Rudelangriff, Hinrichtung, neutrale Pronomen).
- **Regelregister:** Die überholten Stellen aus OI-05 mit Vermerken versehen.
- **Freigabe:** Kein Text ist freigegeben. Vor Übernahme braucht jeder Text eine Entscheidung des Product Owners und eine redaktionelle Prüfung.
