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
- **DI-03 Rolle bei Liebeskummer, Kette, Verknüpfung:** Entschieden ohne Rolle (Mindestangabe); der Fluch des Weisen nennt seine Länge nicht.
- **DI-06 zweite Phase in Nächten ohne neu Verzauberte:** Es gibt keine (die Karten entstehen nur mit einer Verzauberung).
- **Guide-Texte §3.3 und §3.4:** Die integrierten Zeilen stehen in `ui.*.po` (`ui.call.*`, `ui.effect.*`, `ui.notice.*`) und weichen im Wortlaut ab. Die Guide-Datei bleibt Entwurf.

## Noch nicht integriert

Rollenlexikon-Texte, Guide-Texte für die übrigen Rollen, Terminologieangleichung der Kurztexte, Totenreichkarten (nicht definiert), Ton bei fünf Toten, Smartphone- und Audio-Ausgabe, die abgeleiteten Randfälle in `OPEN-ISSUES.md` §5.
