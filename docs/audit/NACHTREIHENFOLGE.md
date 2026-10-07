# Nachtreihenfolge: Kartenzahlen gegen App

**Umgesetzt mit DA-106 (07.10.2026):** Kartenzahl gilt; Loki, Schattenhund, Albtraumwolf, Kartenschlucker und Zeitwächter (bisher als allererster Schritt vorgezogen) folgen jetzt ihrer Karte, Amalia und die X-Rollen bleiben wie unten beschrieben.

**Geändert mit DA-107 (07.10.2026):** Der Zeitwächter ist wieder der allererste Nachtschritt (vor Loki), dokumentierte Ausnahme in `CARD_NUMBERS`; seine Karte zeigt noch 9,5.

Stand 06.10.2026, nur geprüft, nichts geändert. Die Zahl oben links auf den Rollenkarten (`godot/assets/cards/de|en`, DE und EN gleich) ist die Nachtreihenfolge von Markus, `X` heißt: kein Nachtaufruf. Die App ruft nachts nach `night_priority` in `godot/core/rules/role_catalog.gd` auf (aufsteigend, Rudel 20, Gebundene 5, Ewige 48; `StepQueue`). Verglichen wurde Zahl mal 10 mit dieser Priorität.

Ergebnis: **7 Abweichungen**. Bei 43 von 47 Rollen mit Zahl und Nachtaufruf stimmt die Priorität genau mit der Kartenzahl mal 10 überein.

| Rolle | Zahl auf Karte | Position in der App | Position nach Karte | Art |
|---|---|---|---|---|
| Loki | 0,1 | 4 von 49 (Wert 4) | 1 von 48 | Wert weicht ab |
| Schattenhund | 0,7 | 1 von 49 (Wert 1) | 3 von 48 | Wert weicht ab |
| Albtraumwolf | 2,1 | 2 von 49 (Wert 2) | 10 von 48 | Wert weicht ab |
| Kartenschlucker | 4,0 | 32 von 49 (Wert 58) | 22 von 48 | Wert weicht ab |
| Amalia | 5,8 | kein Nachtaufruf | 31 von 48 | Zahl auf Karte, in der App kein Nachtaufruf |
| Die Gebundenen | X | 5 von 49 (Wert 5) | keine Position (X) | X auf Karte, in der App nachts aufgerufen |
| Kutscher | X | 23 von 49 (Wert 38) | keine Position (X) | X auf Karte, in der App nachts aufgerufen |

## Hinweise
- Anfang der Nacht in der App: Schattenhund (1), Albtraumwolf (2), Dorfchronistin (3), Loki (4), dann Wolfskind (9). Nach den Karten: Loki (0,1), Dorfchronistin (0,3), Wolfskind (0,9) usw. mit Schattenhund (0,7) dazwischen und der Albtraumwolf (2,1) erst direkt nach dem Rudel (2,0).
- Kartenschlucker: Karte 4,0 (zwischen Dr. Victor Frankenstein 3,6 und Rattenfänger 4,2), App Priorität 58 (hinter Doktor 50 bis Waldläufer 54, vor Kriegerin des Lichts 60).
- Amalia hat auf der Karte 5,8, die App hat keinen Nachtschritt für sie.
- Die Gebundenen (App: Nacht 1, Priorität 5) und der Kutscher (App: Priorität 38) tragen auf der Karte ein `X`.
- Nicht verglichen: `Dorfbewohner` (keine Zahl auf der Karte, kein Nachtaufruf in der App).

## Wie geprüft
Zahlen aller 72 Karten (DE und EN) vom Bild gelesen, Prioritäten aus `role_catalog.gd` gelesen (49 Nachtschritte inklusive Rudel, Gebundene, Ewige). Die Zahlen auf Karten und die App-Werte wurden nicht verändert. Entscheidung, welche Seite gilt, liegt bei Markus.
