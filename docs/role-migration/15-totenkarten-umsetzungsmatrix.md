# Totenreichkarten: Umsetzungsmatrix

Stand: 01.10.2026, Branch `feature/night-ui-expansion`. Erzeugt aus dem Katalog (`CardCatalog`), den Übersetzungsdateien und den Tests
(keine handgepflegte Liste). Quelle der Kartentexte: `docs/role-migration/14-totenkarten-arbeitsliste.md`. Entscheidungen:
`docs/masterplan/DECISION-LOG.md`, Abschnitt „Totenreichkarten und Kartenschlucker: Umsetzung (01.10.2026)“.

Spalten: **Regel/Kern** (Mechanikfamilie, in der die Wirkung im Regelkern umgesetzt ist), **Fenster** (`start` = vor der Tagesdiskussion,
`end` = nach der Hinrichtung), **UI** (Besonderheit der Bedienung; alle Karten nutzen Kartenfenster, Personenwahl, Optionen, Ja/Nein
und Bestätigen der Ansagekarte), **DE/EN** (Name, Text und Erklärung je Variante in beiden Sprachen vorhanden), **Tests** (Datei mit
einem Verhaltenstest zur Karte; zusätzlich laufen für jede Karte und Variante `cards_play_all`, `cards_invalid` und `cards_public`).

**Status „erledigt“ heißt:** Regel im Kern umgesetzt, über die Oberfläche bedienbar, DE/EN vorhanden, Verhaltenstest vorhanden. Es heißt
nicht „fehlerfrei in allen Kombinationen“ und ersetzt keine Prüfung am Tablet (siehe Abschnitt Grenzen).

| Karte | Name (DE) | Varianten | Kern | Fenster | Regel | UI | DE/EN | Tests | Status |
|---|---|---|---|---|---|---|---|---|---|
| `fluch_01` | Blinder Fleck | dorf/wolf | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `fluch_02` | Falsche Fährte | dorf/wolf | CardFxNight | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night | erledigt |
| `fluch_03` | Lähmung | dorf/wolf | CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_vote | erledigt |
| `fluch_04` | Verrat | dorf/wolf | CardFxNight, CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night, cards_vote | erledigt |
| `fluch_05` | Gebrochener Schild | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_guard | erledigt |
| `fluch_06` | Schwarzes Mal | dorf/wolf | CardFxTable | end+start | ja | Öffentliche Enthüllung | ja | cards_table | erledigt |
| `fluch_07` | Alptraum | dorf/wolf | CardFxNight, CardFxTable | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night, cards_table | erledigt |
| `fluch_08` | Kettenfluch | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_guard | erledigt |
| `fluch_09` | Verlorene Stimme | dorf/wolf | CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_vote | erledigt |
| `fluch_10` | Schlechtes Omen | dorf/wolf | CardFxNight, CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night, cards_vote | erledigt |
| `fluch_11` | Rabe des Unheils | dorf/wolf | CardFxTable | end+start | ja | Öffentliche Enthüllung | ja | cards_table | erledigt |
| `fluch_12` | Doppeltes Leid | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_guard | erledigt |
| `fluch_13` | Lähmungswelle | dorf/wolf | CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_vote | erledigt |
| `loki_01` | Spiegelwelt | neutral | CardFxVote | start | ja | Hinrichtung: Vorschau Person links | ja | cards_vote | erledigt |
| `loki_02` | Stille Abstimmung | neutral | CardFxVote | start | ja | Aufgabe am Tagesende (Frist) | ja | cards_vote | erledigt |
| `loki_03` | Zeitwarp | neutral | CardFxNight | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_decisions, cards_night | erledigt |
| `loki_04` | Doppelgänger | neutral | CardFxTable | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_table | erledigt |
| `loki_05` | Totenerwachen | neutral | CardFxDead | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_table | erledigt |
| `loki_06` | Rollenroulette | neutral | CardFxReturn | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_return | erledigt |
| `loki_07` | Totale Anarchie | neutral | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `loki_08` | Verhexte Nacht | neutral | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `loki_09` | Puppenspieler | neutral | CardFxTable | end+start | ja | Aufgabe: fünf Personen am Sitzkreis | ja | cards_table | erledigt |
| `loki_10` | Phoenix | neutral | CardFxReturn | end+start | ja | Würfel sichtbar, gespeichert | ja | cards_return, cards_ui | erledigt |
| `loki_11` | Stummfilm | neutral | CardFxTable | start | ja | Tagesregel mit Verstoßmeldung (Tod) | ja | cards_table, cards_ui | erledigt |
| `loki_12` | Kosmisches Gleichgewicht | neutral | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_guard | erledigt |
| `loki_13` | Verhexte Lynch | neutral | CardFxVote | start | ja | Hinrichtung: jede lebende Person wählbar | ja | cards_vote | erledigt |
| `schicksal_01` | Nebelhorn | neutral | CardFxTable | end+start | ja | Tagesregel mit Verstoßmeldung (Ausschluss) | ja | cards_table | erledigt |
| `schicksal_02` | Offene Bücher | neutral | CardFxTable | start | ja | Tagesregel (Anzeige) | ja | cards_report, cards_table | erledigt |
| `schicksal_03` | Amnestie | neutral | CardFxVote | start | ja | Hinrichtung entfällt (Hinweis) | ja | cards_ui, cards_vote | erledigt |
| `schicksal_04` | Großes Schweigen | neutral | CardFxTable | end+start | ja | Tagesregel (Anzeige) | ja | cards_table | erledigt |
| `schicksal_05` | Spiegel | neutral | CardFxVote | start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_vote | erledigt |
| `schicksal_06` | Zeitsprung | neutral | CardFxNight | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_decisions, cards_night | erledigt |
| `schicksal_07` | Gleichgewicht | neutral | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `schicksal_08` | Neuer Anfang | neutral | CardFxReturn | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_return | erledigt |
| `schicksal_09` | Stimmentausch | neutral | CardFxVote | end+start | ja | Hinrichtung: Vorschau Person links | ja | cards_vote | erledigt |
| `schicksal_10` | Anarchie | neutral | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `schicksal_11` | Kettenreaktion | neutral | CardFxVote | end+start | ja | Hinrichtung: zweitmeiste Stimmen wählen | ja | cards_combos, cards_vote | erledigt |
| `schicksal_12` | Totengericht | neutral | CardFxDead | end+start | ja | Totenregel: nur Tote nominieren | ja | cards_combos, cards_table | erledigt |
| `schicksal_13` | Stille Wahl | neutral | CardFxTable | start | ja | Tagesregel (Anzeige) | ja | cards_table | erledigt |
| `schicksal_14` | Richterstuhl | neutral | CardFxVote | start | ja | Hinrichtung: jede lebende Person wählbar | ja | cards_vote | erledigt |
| `segen_01` | Heilende Hand | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_guard | erledigt |
| `segen_02` | Flüsterwind | dorf/wolf | CardFxTable | start | ja | Frage mit Antwort der Spielleitung | ja | cards_table | erledigt |
| `segen_03` | Wachsame Augen | dorf/wolf | CardFxNight, CardFxVote | end+start | ja | Hinrichtung: Enthüllung und Entscheid des Dorfes | ja | cards_night, cards_vote | erledigt |
| `segen_04` | Stille Nacht | dorf/wolf | CardFxNight | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night | erledigt |
| `segen_05` | Wahre Stimme | dorf/wolf | CardFxVote | start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_vote | erledigt |
| `segen_06` | Schattenmantel | dorf/wolf | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability, cards_decisions | erledigt |
| `segen_07` | Blutpakt | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_guard | erledigt |
| `segen_08` | Zweites Leben | dorf/wolf | CardFxReturn | end+start | ja | Auswahl aus gespeichertem Angebot (bis drei) | ja | cards_return | erledigt |
| `segen_09` | Gerechter Zorn | dorf/wolf | CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_vote | erledigt |
| `segen_10` | Totenurteil | dorf/wolf | CardFxDead | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_table | erledigt |
| `segen_11` | Spiegelschutz | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_guard | erledigt |
| `segen_12` | Geisterhand | dorf/wolf | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability, cards_decisions | erledigt |
| `segen_13` | Schattenvorteil | dorf/wolf | CardFxNight | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night | erledigt |
| `segen_14` | Eiserner Wille | dorf/wolf | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability, cards_combos | erledigt |
| `solo_01` | Todesprojektion | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `solo_02` | Schwarze Prophezeiung | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_report, cards_solo | erledigt |
| `solo_03` | Racheschwur | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `solo_04` | Apokalyptischer Abgang | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `solo_05` | Vermächtnis der Einsamkeit | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `solo_06` | Geisterstimme | solo | CardFxSolo | end+start | ja | Rückkehr-Aufgabe, Nominierung durch Tote | ja | cards_combos, cards_solo | erledigt |
| `solo_07` | Martyrium | solo | CardFxSolo | end+start | ja | Hinrichtung entfällt (Wölfe) | ja | cards_solo | erledigt |
| `solo_08` | Stiller Zeuge | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `solo_09` | Chaosgeist | solo | CardFxSolo | start | ja | Würfel sichtbar, gespeichert | ja | cards_solo | erledigt |
| `solo_10` | Einsames Erbe | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `solo_11` | Richter aus dem Totenreich | solo | CardFxSolo | end+start | ja | Aufgabe nach der Hinrichtung | ja | cards_solo | erledigt |
| `solo_12` | Familienbande aus dem Totenreich | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `solo_13` | Das Totenreich Regiert | solo | CardFxDead | end+start | ja | Totenregel: nur Tote nominieren | ja | cards_solo | erledigt |
| `solo_14` | Verrat oder Verbrüderung | solo | CardFxSolo | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_solo | erledigt |
| `wende_01` | Letzter Atemzug | dorf/wolf | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `wende_02` | Verzweiflungsschrei | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_combos, cards_guard | erledigt |
| `wende_03` | Wendepunkt | dorf/wolf | CardFxNight, CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night, cards_vote | erledigt |
| `wende_04` | Wiedergeburt | dorf/wolf | CardFxReturn | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_return, cards_ui | erledigt |
| `wende_05` | Notanker | dorf/wolf | CardFxGuard | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_combos, cards_guard | erledigt |
| `wende_06` | Trotz | dorf/wolf | CardFxNight | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night | erledigt |
| `wende_07` | Befreiung | dorf/wolf | CardFxReturn | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_return | erledigt |
| `wende_08` | Auserwählt | dorf/wolf | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `wende_09` | Rückenwind | dorf/wolf | CardFxVote | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_vote | erledigt |
| `wende_10` | Schicksalsumkehr | dorf/wolf | CardFxAbility | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_ability | erledigt |
| `wende_11` | Schicksalswende | dorf/wolf | CardFxAbility, CardFxVote | end+start | ja | Hinrichtung: Vorschau zufälliger Wolf | ja | cards_ability, cards_vote | erledigt |
| `wende_12` | Geheimrat | dorf/wolf | CardFxNight | end+start | ja | Fenster, Eingaben, Anzeige allgemein | ja | cards_night | erledigt |

## Kartenschlucker (72. Rolle)

| Bereich | Stand | Nachweis |
|---|---|---|
| Spielaufbau | nur mit Totenreichkarten wählbar, keine Scheinrolle, Wahl in der Rollenwahl | `test_role_step`, `test_cards_foundation` |
| Nachtschritt | wird jede Nacht geweckt, wenn mindestens eine Aktion bezahlbar ist; Handzeichen als Buttons der Spielleitung | `test_swallower`, `test_cards_ui` |
| Stapel und Tausch | jeder zulässige Tausch gibt einen Stapel (verfügbar und gesamt getrennt), Stapel gehören zur Person | `test_cards_foundation`, `test_swallower` |
| Aktionen | Tötung (2), Schild (5), Sieg (10), nichts; ungültige Eingaben ohne Teiländerung | `test_swallower` |
| Schild | ein Schild je Person, bleibt bei Rollenwechsel, verhindert jeden Tod außer Spielleiterkorrekturen; ruht bei „Gebrochener Schild“ | `test_swallower`, `test_cards_guard` |
| Ansage | Nächte 3, 6, 9 …: öffentlich nur die Gesamtzahl | `test_swallower`, `test_cards_public` |
| Lexikon, Regelbuch | Rollenlexikon-Eintrag (DE/EN), Regelbuch Kapitel 13 | `test_ui_i18n`, `test_rulebook`, `test_role_lexicon_content` |
| Private Information | Guthaben, Gesamtzahl und Schild auf der privaten Karte des Schritts | `test_cards_ui` |
| Abschlussbericht | Sieg als Kandidat mit Bestätigung der Spielleitung wie jeder Einzelsieg | `test_swallower`, `test_cards_report` |

## Tests (Umfang und Grenzen)

- Verhaltenstests je Mechanikfamilie: `test_cards_guard`, `test_cards_night`, `test_cards_ability`, `test_cards_return`, `test_cards_vote`,
  `test_cards_table`, `test_cards_solo`, `test_swallower`, dazu `test_cards_decisions` (KS-106 bis KS-110) und `test_cards_combos`
  (Notanker mit Wolfskind und Lehrling, Wächter am Tor, Totengericht mit Geisterstimme, Wolfsschutz mit Kettenreaktion).
- Für jede der 119 Kartenvarianten: `test_cards_play_all` (Spielbarkeit, Replay, Laden, Folgezyklus), `test_cards_invalid` (falsche
  Eingaben ohne Zustandsänderung), `test_cards_public` (öffentliche Angaben nur aus der Positivliste).
- Zufallspartien: `test_role_interaction_fuzz` spielt jede zweite Partie mit Totenreichkarten, prüft Konsistenz, Speicherfähigkeit und
  Positivlisten und ist an feste Seeds gebunden (reproduzierbar); `test_resume_every_command` startet die App nach jedem Befehl neu.
- Oberfläche: `test_cards_ui` (Kartenfenster, Eingaben, Würfel, Handzeichen, Tagesregeln, Händigkeit, DE/EN),
  `test_cards_ui_games` (vollständige Partien mit 6, 12 und 24 Personen nur über Buttons, Replay und Fortsetzen).
- Laufzeitfehler (Skriptfehler) lassen jeden Test rot werden.

**Grenzen (ehrlich):** Es gibt keinen Beweis, dass alle Kombinationen fehlerfrei sind. Die Fuzz- und Simulationsläufe decken viele, aber
nicht alle Verschränkungen ab. Die Tests laufen headless; **es gab keine Prüfung auf einem Tablet, keine Touch-Prüfung, keine visuelle
und keine Audioabnahme.** Layouts sind gegen Rechteck- und Überdeckungsprüfungen in 1280x800 geprüft, nicht gegen echte Geräte.
