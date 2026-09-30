# Integrationsstand der Inhaltsentwürfe (PR #3)

Stand: 29.09.2026, Branch `feature/night-ui-expansion`. Übernommen aus `content/rolebook-and-guide` (Stand `cde16f5`). **Dieser Ordner enthält weiterhin Entwürfe.** Nur die hier ausdrücklich genannten Punkte sind in Regelkern, Oberfläche und `godot/content/i18n/ui.*.po` integriert. Alles andere (Rollenlexikon, Guide-Texte, Terminologie) bleibt unfreigegeben; die Dateien wurden nicht an den neuen Stand angepasst und können überholte technische Aussagen enthalten.

## Stand nach Paket 5b (29.09.2026): Rollenlexikon und Kontexthilfe

Die vier Stufen werden getrennt geführt. Eine höhere Stufe ist keine Freigabe der nächsten.

| Stufe | Umfang | Nachweis |
|---|---|---|
| **Gegen bestätigte Regeln geprüft** | Alle 71 Einträge in `rolebook/*.md` gegen Decision Log (DI-01 bis DI-09, PE-01 bis PE-06, DA-Ableitungen), Kern und Tests. 26 Zellen korrigiert (Dokumentverweise und Codenamen entfernt; Loki-Aufruf nach DI-02; Rotkäppchen-Karte und Fluch des Weisen nach DA-23/DA-25; Zufallsknopf-Beschriftungen; PE-05). Mechanisch geprüft: IDs = Katalog, Namen = `ui.role.*.name`, Fraktion, Wolfszählung, Nachtstufe = `night_priority`. | Decision Log DA-56, DA-58; `check-coverage.py` OK |
| **Im Programm integriert** | `ui.role.<rolle>.lex.<feld>` in DE/EN für alle 71 Katalogrollen (9 Pflichtfelder, `open` bei 14 Rollen, Rattenfänger seit PE-06 ohne offenen Punkt); Anzeige im Hauptmenü, im Setup und im Cockpit mit Kontexthilfe. Kurztexte terminologisch angeglichen (Rudelangriff, Hinrichtung, neutrale englische Pronomen). GUIDE-TEXTS §3.3/§3.4 an `ui.call.*`, `ui.effect.*`, `ui.morning.notice.*` angeglichen. | `test_role_lexicon_content`, `test_role_lexicon_ui`, `check-godot-i18n.js` |
| **Redaktionelle Endabnahme ausstehend** | Wortlaut aller Lexikonfelder und der angeglichenen Kurztexte; die Entwürfe bleiben Entwürfe, maßgeblich für das Programm ist `ui.*.po`. Keine Release-Abnahme. | Product Owner |
| **Regelinhalt ungeklärt oder nicht umgesetzt** | Im Programm je Rolle im Feld „Noch nicht geklärt oder umgesetzt“ (Zeile „Offen / Open“ im Entwurf), Liste unten. | `ui.role.*.lex.open` |

**Offene Punkte je Rolle (Feld `open`):**

| Rolle | Art | Punkt | Fundstelle |
|---|---|---|---|
| `faehrtenleser`, `detektiv` | Geräteprüfung | „links“ = Uhrzeigersinn am Tablet ungeprüft | OI-06; `rolebook/01-village-information.md` |
| `blutpriester` | technisch abgeleitet | Verteilung des Zufallsvorschlags | DA-43; `rolebook/01-village-information.md` |
| `der-weise` | technisch abgeleitet | Länge des Fluchs nicht angesagt | DA-23; `rolebook/02-village-protection.md` |
| `rotkaeppchen` | entschieden (NQ-06, 30.09.2026), im Lexikon umgesetzt | kein offener Punkt mehr: gefragte Person unauffällig antippen, anonyme Frage auf dem Tablet zeigen (Decision Log DA-84) | OI-18; `rolebook/03-village-bonds-and-changes.md` (Entwurfsstand) |
| `kutscher`, `dr-victor-frankenstein` | nicht festgelegt | Totenreichkarten, Kartenbedingung | OI-02; `rolebook/03-village-bonds-and-changes.md` |
| `schwarze-witwe` | vertagt | Setup-Pflicht „Loki im Spiel“ | `rolebook/05-wolves-special.md` |
| `schicksalswolf`, `rachsuechtiger-wolf`, `zeitwaechter`, `hades`, `grabraeuber` | technisch abgeleitet | Einzelheiten DA-01 bis DA-19 | Decision Log; `rolebook/02` (Zeitwächter), `05`, `07` |
| `selbstmoerder` | Hinweis technisch umgesetzt, kein Ton | „in der Partie“ ist entschieden (NQ-01: lebende Person mit der Rolle, auch geerbt); Hinweis mit stummem Fallback (DA-86), keine Tondatei | DI-09, X-05; `rolebook/06-solo-1.md` |

Kartenschlucker hat keinen Eintrag und ist keine spielbare Rolle (fehlende Kartenmechanik, Paket 8).

## Integriert (Nutzerantworten vom 29.09.2026, Decision Log "Inhaltsentscheidungen")

| DI | Inhalt | Umsetzung |
|---|---|---|
| DI-01 | Wiederbelebungsrunde statt frei wählbarer Rollenaufdeckung | `GameState.revival_round` (aus `RoleCatalog.REVIVAL_ROLES`), Schema 13, Regelversion 0.12; Setup zeigt den Modus an (`RevivalRoundLabel`); Tests `test_revival_round`, `test_game_start_step` |
| DI-02 | Aufrufpolitik | `CallPolicy` (reine Kernabfrage), Tarnaufrufe auf den Karten, `ui.call.night_falls_revival`; Tests `test_call_policy`, `test_call_presentation` |
| DI-03 | Todeseffekte werden angesagt | öffentliches Ereignis `DeathEffect`, Morgenbericht und Tageskarte, `ui.effect.*`; Tests `test_death_effects`, `test_death_effect_lines` |
| DI-04 | Loki | `notices` (`loki_bond`), Hinweiskarten `ui.notice.loki_bond.*` |
| DI-05 | Rotkäppchen | Karte der gefragten Person ohne Rolle und ohne fragende Person, `ui.prompt.rotkaeppchen.grant` |
| DI-06, PE-06 | Rattenfänger | Hinweis `piper_new` (`ui.notice.piper_new`), Nachtschritt `piper-all` (`ui.call.piper_all`, `ui.prompt.piper_all.shown`, `ui.cockpit.group.piper_all`) |
| DI-07 | Pestbringerin | `notices` (`pest_infected`), auch nach der Ausbreitung, `ui.notice.pest_infected` |
| DI-08 | Trugbilderwolf | keine Karte trägt die Scheinrolle; nur der private Spielleiterbereich nennt sie (Test `test_notice_cards`) |
| DI-09 | Ton bei fünf Toten | bestätigt; seit 30.09.2026 als technischer Hinweis mit stummem Fallback umgesetzt (NQ-01, DA-86), Tondatei fehlt (Medienproduktion) |

## Abweichungen von den Entwurfsannahmen in `DECISIONS-TO-INTEGRATE.md`

Die Übergabedatei entstand vor PR #3. Folgende Aussagen sind überholt oder wurden anders gelöst:

- **DI-01 "Kern kennt die Option bisher nicht":** Falsch. `reveal_role_on_death` war Teil des Kernzustands (Schema 12) und ist jetzt entfernt; der Kern lehnt die alte Angabe ab (`reveal_option_removed`).
- **DI-01 "Setup warnt bei indirekten Trägern":** Entfällt. Ohne direkte Wiederbelebungsrolle in der Besetzung kann Erbe, Tausch oder Diebstahl keine Wiederbelebung erreichen; die Warnung wäre nie sichtbar.
- **DI-04, DI-06, DI-07 "private Ereignisse (`actor`)":** Umgesetzt als Zustand `notices` mit Befehl `AckNotice`, damit Neustart, Rückgängig und Replay dieselbe Karte zeigen. Die bestehenden ACTOR-Ereignisse (zum Beispiel `LycaonNotice`) bleiben unverändert.
- **DI-03 Rolle bei Liebeskummer, Kette, Verknüpfung:** Beantwortet am 29.09.2026 (PE-05): die Rolle, von der der Effekt stammt; umgesetzt in Paket 5b. Der Fluch des Weisen nennt seine Länge weiter nicht (DA-23, zu bestätigen).
- **DI-06 zweite Phase in Nächten ohne neu Verzauberte:** Beantwortet am 29.09.2026 (PE-06): nach jedem Aufruf des Rattenfängers, auch Tarnaufruf. Umgesetzt als eigener Nachtschritt (DA-60 bis DA-64, Matrix N-12); der Lückenhinweis im Lexikon ist entfernt.
- **Guide-Texte §3.3 und §3.4:** Seit Paket 5b an den integrierten Wortlaut in `ui.*.po` angeglichen (`ui.call.*`, `ui.effect.*`, `ui.morning.notice.*`). Die Guide-Datei bleibt Entwurf.

## Noch nicht integriert

Guide-Texte außerhalb von §3.3/§3.4 (Anweisungen §3.1 und private Texte §3.2, Handlungszeilen OI-18), ein allgemeines Regelbuch, Totenreichkarten (nicht definiert), Ton bei fünf Toten, Smartphone- und Audio-Ausgabe, die abgeleiteten Randfälle in `OPEN-ISSUES.md` §5 Nr. 3 bis 7. *(Rollenlexikon und Terminologie der Kurztexte: integriert in Paket 5b, siehe oben.)*

## Integrationsliste für Paket 5b (Stand 29.09.2026, Paket 5a; erledigt in Paket 5b außer den markierten Resten)

Vorbereitung, keine Freigabe. Die Entwürfe bleiben unfreigegeben, bis der Product Owner sie abnimmt.

**A. Durch aktuelle Entscheidungen gedeckt (Inhalt steht fest, Wortlaut kann übernommen werden):**
- Spielleitungszeilen der vier Zufallsrollen (`rolebook/01-village-information.md`: `traumdeuter`, `kopfgeldjaeger`, `koenig`, `blutpriester`), angepasst an RM-DR-015.2 und DA-42 bis DA-45 (OI-09). Die Blutpriester-Verteilung ist als DA-43 gekennzeichnet.
- Einträge mit K2-Befund in `OPEN-ISSUES.md` (OI-03, OI-08, OI-10, OI-11, OI-14, OI-15, OI-19) und die Hinweise zu DI-04 bis DI-08.
- Ansagen zu Todeseffekten, Aufrufen und Hinweisen: bereits in `ui.*.po` (`ui.effect.*`, `ui.call.*`, `ui.notice.*`); maßgeblich ist der integrierte Wortlaut, nicht GUIDE-TEXTS §3.3 und §3.4.

**B. Redaktionell zu überarbeiten (keine Regelfrage):**
- Terminologie der Kurztexte in `ui.*.po` angleichen (OI-04, `TERMINOLOGY.md` §4), EN einheitlich („wolf attack“/„werewolf attack“, neutrale Pronomen).
- GUIDE-TEXTS §3.3 und §3.4 an den integrierten Wortlaut angleichen oder als überholt kennzeichnen.
- Rollenlexikon-Einträge, die sich auf den Quell-Commit `312f5bb` stützen, gegen den aktuellen Kern prüfen (Roadmap Paket 5, erster Punkt).
- Kutscher-Hinweis: Die Setup-Meldung gilt `kutscher` (DA-47, redaktionelle Korrektur des Namens aus PE-04 anhand der Mechanik), nicht `wahnsinniger-kutscher`.

**C. Echte neue Regelfragen (nur diese an den Product Owner):**
- Rolle in den Ansagen zu Liebeskummer, Kette und Verknüpfung (`OPEN-ISSUES.md` §5 Nr. 1).
- Zur Bestätigung statt als neue Frage: DA-21, DA-22, DA-23 (Fluchlänge), DA-24, DA-43.
- Später, nicht für 5b: DI-09 „in der Partie“ (Audio), Totenreichkarten (OI-02).

**D. Technische Integration ins Programm (Paket 5b):**
- Anzeigeort für Lexikon- und Spielleitungstexte festlegen und die freigegebenen Texte als `ui.*`-Schlüssel in beide PO-Dateien übernehmen; `node tools/check-godot-i18n.js` muss grün bleiben.
- Handlungszeilen für Nicht-Slice-Rollen (OI-18) nur nach geklärtem Bedienablauf.
