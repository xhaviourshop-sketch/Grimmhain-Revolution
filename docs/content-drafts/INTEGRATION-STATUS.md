# Integrationsstand der Inhaltsentwürfe (PR #3)

Stand: 29.09.2026, Branch `feature/night-ui-expansion`. Übernommen aus `content/rolebook-and-guide` (Stand `cde16f5`). **Dieser Ordner enthält weiterhin Entwürfe.** Nur die hier ausdrücklich genannten Punkte sind in Regelkern, Oberfläche und `godot/content/i18n/ui.*.po` integriert. Alles andere (Rollenlexikon, Guide-Texte, Terminologie) bleibt unfreigegeben; die Dateien wurden nicht an den neuen Stand angepasst und können überholte technische Aussagen enthalten.

## Integriert (Nutzerantworten vom 29.09.2026, Decision Log "Inhaltsentscheidungen")

| DI | Inhalt | Umsetzung |
|---|---|---|
| DI-01 | Wiederbelebungsrunde statt frei wählbarer Rollenaufdeckung | `GameState.revival_round` (aus `RoleCatalog.REVIVAL_ROLES`), Schema 13, Regelversion 0.12; Setup zeigt den Modus an (`RevivalRoundLabel`); Tests `test_revival_round`, `test_game_start_step` |
| DI-02 | Aufrufpolitik | `CallPolicy` (reine Kernabfrage), Tarnaufrufe auf den Karten, `ui.call.night_falls_revival`; Tests `test_call_policy`, `test_call_presentation` |
| DI-03 | Todeseffekte werden angesagt | öffentliches Ereignis `DeathEffect`, Morgenbericht und Tageskarte, `ui.effect.*`; Tests `test_death_effects`, `test_death_effect_lines` |
| DI-04 | Loki | `notices` (`loki_bond`), Hinweiskarten `ui.notice.loki_bond.*` |
| DI-05 | Rotkäppchen | Karte der gefragten Person ohne Rolle und ohne fragende Person, `ui.prompt.rotkaeppchen.grant` |
| DI-06 | Rattenfänger | `notices` (`piper_new`, `piper_all`), `ui.notice.piper_*` |
| DI-07 | Pestbringerin | `notices` (`pest_infected`), auch nach der Ausbreitung, `ui.notice.pest_infected` |
| DI-08 | Trugbilderwolf | keine Karte trägt die Scheinrolle; nur der private Spielleiterbereich nennt sie (Test `test_notice_cards`) |
| DI-09 | Ton bei fünf Toten | bestätigt, weiterhin nicht umgesetzt (Audio) |

## Abweichungen von den Entwurfsannahmen in `DECISIONS-TO-INTEGRATE.md`

Die Übergabedatei entstand vor PR #3. Folgende Aussagen sind überholt oder wurden anders gelöst:

- **DI-01 "Kern kennt die Option bisher nicht":** Falsch. `reveal_role_on_death` war Teil des Kernzustands (Schema 12) und ist jetzt entfernt; der Kern lehnt die alte Angabe ab (`reveal_option_removed`).
- **DI-01 "Setup warnt bei indirekten Trägern":** Entfällt. Ohne direkte Wiederbelebungsrolle in der Besetzung kann Erbe, Tausch oder Diebstahl keine Wiederbelebung erreichen; die Warnung wäre nie sichtbar.
- **DI-04, DI-06, DI-07 "private Ereignisse (`actor`)":** Umgesetzt als Zustand `notices` mit Befehl `AckNotice`, damit Neustart, Rückgängig und Replay dieselbe Karte zeigen. Die bestehenden ACTOR-Ereignisse (zum Beispiel `LycaonNotice`) bleiben unverändert.
- **DI-03 Rolle bei Liebeskummer, Kette, Verknüpfung:** Technisch ohne Rolle umgesetzt (Mindestangabe, DA-23); der Fluch des Weisen nennt seine Länge nicht. Keine Antwort des Product Owners: welche Rolle hier zu nennen wäre, ist offen (`OPEN-ISSUES.md` §5 Nr. 1).
- **DI-06 zweite Phase in Nächten ohne neu Verzauberte:** Technisch gibt es keine (die Karten entstehen nur mit einer Verzauberung). Keine Antwort des Product Owners (`OPEN-ISSUES.md` §5 Nr. 2).
- **Guide-Texte §3.3 und §3.4:** Die integrierten Zeilen stehen in `ui.*.po` (`ui.call.*`, `ui.effect.*`, `ui.notice.*`) und weichen im Wortlaut ab. Die Guide-Datei bleibt Entwurf.

## Noch nicht integriert

Rollenlexikon-Texte, Guide-Texte für die übrigen Rollen, Terminologieangleichung der Kurztexte, Totenreichkarten (nicht definiert), Ton bei fünf Toten, Smartphone- und Audio-Ausgabe, die abgeleiteten Randfälle in `OPEN-ISSUES.md` §5.

## Integrationsliste für Paket 5b (Stand 29.09.2026, Paket 5a)

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
- Phase „Alle Verzauberten“ in Nächten ohne neu Verzauberte (§5 Nr. 2).
- Zur Bestätigung statt als neue Frage: DA-21, DA-22, DA-23 (Fluchlänge), DA-24, DA-43.
- Später, nicht für 5b: DI-09 „in der Partie“ (Audio), Totenreichkarten (OI-02).

**D. Technische Integration ins Programm (Paket 5b):**
- Anzeigeort für Lexikon- und Spielleitungstexte festlegen und die freigegebenen Texte als `ui.*`-Schlüssel in beide PO-Dateien übernehmen; `node tools/check-godot-i18n.js` muss grün bleiben.
- Handlungszeilen für Nicht-Slice-Rollen (OI-18) nur nach geklärtem Bedienablauf.
