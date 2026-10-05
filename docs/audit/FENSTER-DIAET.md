# Fenster-Diät (Feedback iPad-Test, Teil 2)

Stand 2026-10-05, Branch `feat/feedback-2`. Grundsatz von Markus: Jedes Fenster, das nur ankündigt, fragt, ob es etwas sagen darf, oder nichts Neues enthält, fliegt raus. Die App sagt es direkt an. Behalten wird nur, was eine Entscheidung braucht oder echten Inhalt zeigt.

Erfasst sind alle Karten, Ebenen und Rückfragen, die die Spielleitung während einer Partie im Cockpit sieht (Code: `app/session/cockpit_view.gd`, `app/screens/cockpit/action_card.gd`, `cockpit_layers.gd`, `cockpit_screen.gd`).

## Entfernt

| Fenster | Wo | Grund |
|---|---|---|
| Verdeckte Karte „Nur für die Spielleitung“ mit „Anzeigen“ | Aktionskarte am Morgen und am Tag vor jedem geheimen Schritt (Reaktion, Hinweis, Kartenfenster, Siegentscheidung) | Fragt nur, ob sie etwas zeigen darf. Die Karte erscheint jetzt direkt. Ersetzt S-07 (DA-93). |
| Verdeckte Hinrichtungsprüfung („Diese Prüfung ist nur für die Spielleitung“) | Tageskarte nach „Hinrichtung prüfen“ | Gleicher Fall: die Vorschau steht sofort da. |
| „Nacht abschließen“ | Aktionskarte nach dem letzten Nachtschritt | Kein Inhalt. Nach dem letzten Schritt endet die Nacht von selbst. Ausgefallene oder übersprungene Schritte stehen im Morgenbericht unter „Für dich“ mit Rollenname und Grund. Tarnaufrufe nach dem letzten Schritt stehen oben auf der Morgenkarte. |
| „Mögliches Spielende“ mit Rückfrage „Sieg bestätigen?“ | Aktionskarte nach einem Tod, Hinrichtung oder Bindung | Die App prüft nach jeder Änderung selbst (Regelkern `WinRules`). Ist genau ein Sieg erreicht, kommt direkt der Siegbildschirm mit dem Gewinner-Team. |
| Ansagekarte „Ansagekarte zeigen“ | Morgenkarte, eigene Vollbild-Ebene | Enthielt dieselben Zeilen wie die Morgenkarte. |
| „Private Details …“ | Morgenkarte, Schublade | Der geheime Teil steht jetzt als „Für dich“ auf der Morgenkarte. |
| „Hinrichtung bestätigen?“ | Rückfrage nach „Hinrichten“ | Die Wahl ist schon getroffen, die Rückfrage brachte nichts Neues. Rückgängig bleibt möglich. |
| „Keine Hinrichtung heute?“ | Rückfrage nach „Keine Hinrichtung“ | Wie oben. |

## Behalten

| Fenster | Wo | Grund |
|---|---|---|
| Siegkarte „Mögliches Spielende“ | Aktionskarte | Nur noch, wenn mehrere Siege gleichzeitig möglich sind (Entscheidung nötig) oder der Sieg ohne eigene Handlung entstand (nach Rückgängig oder Laden; sonst würde Rückgängig sofort wieder beenden). Ein Tipp bestätigt, ohne Rückfrage. |
| „Nacht abschließen“ | Aktionskarte | Nur noch nach Rückgängig oder Laden am Nachtende, aus demselben Grund. |
| Morgenbericht | Aktionskarte | Echter Inhalt: „Fürs Dorf“ zum Vorlesen, „Für dich“ geheim. „Weiter zum Tag“ schaltet weiter. |
| Ansage eines Schritts ohne Vorschau („Weiter“) | Aktionskarte | Trägt den Vorlesetext der Rolle. |
| Hinweiskarte („Privater Hinweis“) mit „Karte zeigen“ | Aktionskarte und Vollbild | Nennt, wem die Karte zu zeigen ist; die gezeigte Karte ist der Inhalt. |
| „Karte zeigen“ (gezeigte Karte) | Vollbild | Inhalt für die handelnde Person. Neu im Grimmhain-Stil: dunkler Grund, Eisenrahmen mit Ornament nur an den Ecken, gotischer Titel, großer Text. |
| „Tag beenden“ | Aktionskarte | Schaltet zur Nacht und nennt die Nominierungen des Tages. |
| Rollenanzeige (Liste, Karte) | Vollbild | Inhalt für die Spielenden. |
| Kartenfenster der Totenreichkarten, Rückfragen „Karte tauschen?“ und „Kartenfenster schließen?“ | Aktionskarte, Rückfrage | Die Rückfragen erklären eine Regelfolge (Ersatzkarte sofort spielen, übrige Karten bleiben). |
| Rückgängig und Wiederholen | Rückfrage | Nennt, was zurückgenommen wird, und dass Gezeigtes bekannt bleibt. |
| Abbruch eines Schritts, Sieg ablehnen, Korrekturen | Rückfrage mit Begründung | Brauchen eine Eingabe. |
| Amalia (Ja/Nein) | Rückfrage | Entscheidung. |
| Partie verlassen, Partie verwerfen | Rückfrage | Verlassen schützt vor versehentlichem Tippen auf Zurück, Verwerfen ist endgültig. |
| Protokoll, Rollen je Person, Kartenübersicht, Spielleitung | Schublade | Nachschlagen, kein Ankündigungsfenster. |
| Sichtschutz | Vollbild | Bewusst ausgelöst. |

## Folgen

- Am Tag erscheinen geheime Karten offen. Wer das Tablet mitlesen lässt, nutzt den Sichtschutz oder „Verbergen“.
- Die Abzeichen am Sitzkreis bleiben tagsüber verborgen; ein Tipp auf eine Person zeigt sie 3 Sekunden (S-05).
