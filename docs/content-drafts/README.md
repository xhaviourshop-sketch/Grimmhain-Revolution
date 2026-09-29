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
| [`GUIDE-TEXTS.md`](GUIDE-TEXTS.md) | Allgemeine Texte für Nachtbeginn, Morgen, Diskussion, Nominierung, Hinrichtung, Spielende; je Rolle Texte in den drei Kategorien `[SL-PRIVAT]`, `[PERSON-PRIVAT]`, `[ÖFFENTLICH]`; §4 prüft auf Informationsweitergabe |
| [`TERMINOLOGY.md`](TERMINOLOGY.md) | Einheitliche DE/EN-Begriffe |
| [`OPEN-ISSUES.md`](OPEN-ISSUES.md) | 19 Punkte, nach Klassen geprüft, mit Belegen und priorisierter Entscheidungsliste |
| [`check-coverage.py`](check-coverage.py) | Vollständigkeits- und Paritätsprüfung, siehe Abschnitt 5 |

Aufbau eines Rolleneintrags: stabile Rollen-ID, Name und Fraktion, kurze Fähigkeit, Zeitpunkt und Nutzungslimit, Zielbeschränkungen, wichtige Ausnahmen, Siegbedingung, zwei Beispiele, Hinweis für die Spielleitung, Quellenangabe. Jede Zeile steht in DE und EN nebeneinander.

## 3. Status

- **Rollen mit Entwurf:** 71 von 71 implementierten Rollen. Keine fehlt, keine doppelt (Prüfung Abschnitt 5).
- **Regelgrundlage:** Alle Rollen sind im Audit-Stand grün (`11-role-audit-status.md` §2: 71 grün, 1 blockiert). Grün gilt nur für den Regelkern, nicht für Oberfläche oder Tablet.
- **Nicht vom Product Owner einzeln ausgewählt:** Schicksalswolf (DA-11 bis DA-15), Rachsüchtiger Wolf (Rhythmus und Angriff, DA-16 bis DA-18), Zeitwächter (Einzelheiten, DA-19), Hades und Grabräuber (DA-01 bis DA-09) Der Siegreiche Wolf folgt einem widerspruchsfreien Rollentext ohne Einzelbestätigung (Hinweis OI-03, kein Konflikt).
- **17 Rolleneinträge tragen einen Verweis auf einen Punkt in `OPEN-ISSUES.md`** (Suche nach `OI-` in `rolebook/`). 3 davon hängen an einer offenen Produktentscheidung (`der-weise` OI-11 b, `trugbilderwolf` OI-19, `schattenhund` und `albtraumwolf` OI-01). Für `loki`, `rotkaeppchen`, `rattenfaenger` und `pestbringerin` liegt eine Antwort des Product Owners vom 29.09.2026 vor (Chat, noch nicht im Decision Log). Die übrigen 9 tragen einen Hinweis auf spätere Erweiterung, Integration oder ein aufgelöstes Thema (OI-02, OI-03, OI-05, OI-06, OI-07, OI-09, OI-15).
- **Entwurfsannahmen ohne Quelle** sind als solche benannt: das Aufrufmuster für Rollen mit eigenem Schritt (OI-01) und der Bedienablauf von Fragen am Tisch (OI-18). Die Ansage des Schutzgeists enthält keinen Rollennamen (OI-11 a); der fehlende öffentliche Hinweis auf den Fluch des Weisen entspricht dem Regelkern (OI-11 b).
- **Fachliche Überarbeitung 29.09.2026:** Die Liste offener Punkte wurde gegen Decision Log, Regelkern und Tests geprüft und neu klassifiziert (`OPEN-ISSUES.md` §1 und §2). Alle 71 Rolleneinträge wurden DE gegen EN auf Bedeutung geprüft, besonders Pflicht und Freiwilligkeit, je Leben und je Partie, Zielbeschränkungen, Todeszeitpunkt, Schutz und Umlenkung, Rollenwechsel und Wiederbelebung, Alleinsieg und Mitsieg. Öffentliche Texte wurden auf Informationsweitergabe geprüft (`GUIDE-TEXTS.md` §4).
- **Verbleibende Übersetzungsrisiken:** (1) Das Wortfeld "Warden" (Night, Doom, Time Warden) neben Guardian Angel, Guardian Spirit, Village Guard und Gatewarden ist im EN leicht zu verwechseln. (2) "Der Weise / The Elder" verschiebt die Bedeutung (weise gegen älter, Legacy-Name). (3) "Fluch / curse" trägt drei verschiedene Wirkungen (Sensenträger, Dämonischer Wolf, Weiser) und ist nur mit Rollennamen eindeutig. (4) Fachbegriffe ohne etablierte EN-Entsprechung müssen mit einer Muttersprachlerin abgestimmt werden: Ersatzopfer (substitute victim), Durchdringen (pierces protection), Todesmarkierung (death marker), Einsatz (use, charge). (5) Neutrale Pronomen: Die Entwürfe nutzen im EN "themself/their", `ui.en.po` nutzt "his/her". (6) Mehrdeutige DE-Wörter: "Nachbar" (nächste lebende Person) gegen "direkt benachbarter Platz" (Blutwolf), "Team" (Doktor), "Opfer" (Rudelopfer gegen Opferung durch Blutpriester und Nekromant), "Schild" gegen "Schutz".
- **Freigabe:** Alle Inhalte bleiben bis zur Prüfung des gemeinsamen App-Stands unfreigegeben.
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
- **Kurztexte in `ui.*.po`:** Keine Regelabweichung. Eine Angleichung nach TERMINOLOGY §4 (Wortwahl Hinrichtung, einheitliches EN, neutrale Pronomen) ist Stilarbeit.
- **Regelregister:** Die überholten Stellen aus OI-05 mit Vermerken versehen.
- **Freigabe:** Kein Text ist freigegeben. Vor Übernahme braucht jeder Text eine Entscheidung des Product Owners und eine redaktionelle Prüfung.

## 7. Übernahmestatus für die UI (Stand der Prüfung, nicht freigegeben)

**Nach Prüfung des gemeinsamen App-Stands übernehmbar:** die allgemeinen Texte (`GUIDE-TEXTS.md` §2), die `[SL-PRIVAT]`-Zeilen (§3.1), die `[PERSON-PRIVAT]`-Zeilen der Informationsrollen mit entschiedener Regel (Orakel, Chronistin, Gebundene, Waldläufer, Doktor, Traumdeuter, Kopfgeldjäger, König, Kriegerin, Blutpriester, Ewige, Spürhund, Seelentauscher, Kutscher, Frankenstein, Wächter am Tor, Giftwolf, Grabräuber), die `[ÖFFENTLICH]`-Wirkungen (§3.4) außer den unten genannten, und die Rollenlexikon-Einträge ohne Verweis auf eine offene Produktentscheidung.

**Zurückzuhalten:** (1) Aufruf- und Einschlaftexte (§3.3) bis zur Aufrufpolitik (OI-01). (2) Die Scheinrollenzeile von `trugbilderwolf` (OI-19). Die PERSON-PRIVAT-Zeilen von `loki`, `rotkaeppchen`, `rattenfaenger` und `pestbringerin` folgen den Chat-Antworten und brauchen vor der Übernahme den Decision-Log-Eintrag. (3) Die Ansage von `der-weise` (OI-11 b) und der Ton bei fünf Toten (OI-07). (4) Alle Texte mit "links" und "rechts" (`faehrtenleser`, `detektiv`, `{direction}`) bis zur Tablet-Prüfung (OI-06). (5) `kutscher` und `dr-victor-frankenstein` bis zum Totenkarten-System (OI-02). (6) Einträge mit abgeleiteten Präzisierungen (Schicksalswolf, Einzelheiten von Rachsüchtigem Wolf und Zeitwächter, Hades, Grabräuber) nur mit sichtbarer Kennzeichnung "abgeleitet". (7) Die PERSON-PRIVAT-Zeile von `koenig-lykaon` hat keine dokumentierte Entscheidung (OI-15).
