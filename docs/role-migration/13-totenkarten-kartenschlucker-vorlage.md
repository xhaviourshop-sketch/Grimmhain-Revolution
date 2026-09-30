# Totenkarten und Kartenschlucker: Entscheidungsvorlage

Stand: 30.09.2026, Branch `feature/night-ui-expansion`. Reine Vorbereitung: keine Kartenmechanik ist implementiert, keine Regel ist hier neu beschlossen. Diese Datei ist keine zweite Regelquelle. Verbindliche Regeln stehen im Decision Log, offene Entscheidungen mit ihren IDs in [`08-decision-request.md`](08-decision-request.md). Antworten der ersten Fragerunde gehören nach dem Beantworten in den Decision Log, nicht hierher.

**Nachtrag 30.09.2026 (zweite Runde):** Die Fragen 1 bis 5 dieser Vorlage sind beantwortet: 1A, 2C (ALLE Karten werden vor der Umsetzung gemeinsam überarbeitet), 3A (eingeschränkt: „Kartenschlucker im Spiel“ ist offen), 4B (Fähigkeiten bleiben vorgesehen, Details offen), 5A (Stapel bleiben beim Tod, Schild offen). Wortlaut, Herkunft und Offenes stehen im Decision Log („Totenkarten und Kartenschlucker, Entscheidungen vom 30.09.2026“). Die Abschnitte 5 bis 7 unten gelten damit **nicht mehr als Umsetzungsreihenfolge**: Es gibt keinen Kartentausch-Code vor der Kartenüberarbeitung. Die Arbeitsliste aller 80 Karten und die neue Fragerunde stehen in [`14-totenkarten-arbeitsliste.md`](14-totenkarten-arbeitsliste.md).

## 1. Was ist schon verbindlich?

| Regel | Quelle |
|---|---|
| Kutscher und Dr. Victor Frankenstein laufen ohne Kartenbezug. Kartenbedingungen (RM-DR-141.4) und der Kartenschlucker folgen mit dem Totenkarten-Assistenten. | Decision Log „Rollenaudit · Wiederbelebungsrollen“, W-01 = A (Zeile 439) |
| Wiederbelebung setzt begrenzte Einsätze zurück; Einmal-Fähigkeiten gelten je Person. Ein Wiederbelebter startet frisch. | Decision Log W-01 bis W-04, RM-DR-126.3, RM-DR-141.3 |
| Fünf-Tote-Hinweis: unabhängig von Karten, Entscheidung B vom 30.09.2026. | Decision Log „Fünf-Tote-Hinweis, Entscheidung B“ |
| Der Kartenschlucker ist die 72. Rolle. Er ist zurückgestellt, nicht im `RoleCatalog`, im Setup nicht wählbar. Die 71 anderen Rollen sind umgesetzt. | `11-role-audit-status.md` §0, Matrix R-03 |
| Rollentext (DE): „Erhält jedes Mal einen Stapel, wenn ein Toter seine Karte austauscht. Bei 10 Stapeln gewinnt er sofort.“ | `dossiers/solos-b.md` (Kartenschlucker) |
| Es gibt keine Kartenregeln und keine Dummy-Karten. Der Abschluss von 71 Rollen ist kein Abschluss von 72 Rollen. | `docs/ui/cockpit.md` Zeile 112, `CODE-COMPLETION-ROADMAP.md` Paket 8 |

Nur Legacy, nicht verbindlich: 80 Karten in 6 Kategorien (SEGEN 14, FLUCH 13, SCHICKSAL 14, SOLO 14, WENDE 12, LOKI 13), Vergabe an Nicht-Wölfe beim Start und an Wölfe beim Tod, Tausch einmal je Karte mit Sofort-Ausspielen der Ersatzkarte, Zusatzkräfte des Kartenschluckers (Tötung ab 2 Stapeln, Schild ab 5, Ansage alle 3 Nächte). Kein Karteneffekt ist im Legacy-Code automatisiert; etwa 40 Karten setzen ein Abstimmungssystem voraus, das es nicht gibt. Belege: `docs/godot-migration/01-current-system-inventory.md` §4.6, `js/core/cards.js`, `js/core/abilities-helpers.js:5-20,119-259`, `js/core/abilities-roles-chunk.js:222-237`, `js/ui/core.js:134,190-207,241`. Das Legacy-Verhalten widerspricht dem Rollentext (`legacy-contradictory`, RM-C-071, RM-C-072).

## 2. Welche Informationen fehlen wirklich?

1. Zeitpunkt der Ziehung und wer eine Karte bekommt (RM-DR-013, in `dossiers/inventory.md` als Q3 geführt; dort steht nur eine Empfehlung „Ziehung beim Tod“, keine Freigabe).
2. Wie weit Karten automatisch wirken oder nur gezeigt und vom Spielleiter ausgeführt werden.
3. Wer tauschen darf, wie oft, und ob der Tausch öffentlich ist (RM-DR-143.2, RM-DR-013).
4. Ob die Legacy-Zusatzkräfte des Kartenschluckers gelten und ob sein Stapel bekannt ist (RM-DR-143.1, dazu die Dossier-Fragen 1 bis 4 zu Kosten des Kills, Art des Schilds und Öffentlichkeit der Stapel).
5. Was mit den Stapeln geschieht, wenn der Kartenschlucker stirbt oder wiederbelebt wird (Dossier-Frage 5; Legacy: Stapel bleiben, ein Toter gewinnt nie).
6. Inhalt, nicht Regel: Die 80 Kartentexte gibt es nur auf Deutsch (EN: 46 von 80 Namen gemappt), ein Name ist doppelt („Anarchie“), und es ist nicht bestätigt, dass alle 80 in die neue Fassung übernommen werden. Das ist eine Aufgabe der Inhaltsprüfung, keine Spielregelfrage dieser Runde.
7. Später, hängt an Frage 2: die Kartenbedingung von Frankenstein und Kutscher (RM-DR-141.4). Sie wird in dieser Runde bewusst nicht gefragt.

## 3. Was braucht der Kartenschlucker davon?

Nur das Minimum, damit er spielbar ist: ein Ereignis „Karte getauscht“ (Punkt 3), eine Ziehung, die einem Toten eine Karte gibt (Punkt 1), die Stapelzahl mit Sieg bei 10 (Rollentext, kein Fragepunkt), die Antwort zu Zusatzkräften (Punkt 4) und das Verhalten bei Tod und Wiederbelebung (Punkt 5). Wie Karten wirken (Punkt 2) braucht er nur soweit, dass der Tausch einen Ablauf hat. Die Kartenwirkungen selbst braucht er nicht.

## 4. Welche umgesetzten Rollen sind betroffen?

Nach Quellenlage (keine erneute Rollenprüfung):

| Rolle | Betroffen durch | Quelle |
|---|---|---|
| `kutscher`, `dr-victor-frankenstein` | Wiederbelebte sterben erneut und bekommen dann wieder eine Karte (mehr Tauschgelegenheiten); Kartenbedingung 141.4 | RM-DR-141.4, RM-DR-143 Wechselwirkung |
| `hades`, `nekromant`, `parasit`, `rudelvater` | Ein Kartenschlucker-Schild wäre eine weitere Abfangregel in der Todespipeline (Legacy-Reihenfolge, Ausnahme `PACKFATHER_KILL`); nur relevant, wenn Zusatzkräfte gelten | RM-DR-143, `docs/godot-migration/01-current-system-inventory.md` §4 (Todespipeline) |
| Alle Rollen, die Tote erzeugen | Mehr Tote heißt mehr Tauschgelegenheiten | RM-DR-143 |
| Alle Solo-Rollen mit Sieg über Todesereignisse (`hades`, `todesprediger`) | Ziehen überwiegend SOLO-Karten beim Tod (Legacy); nur mit automatischen Karten relevant | `dossiers/solos-b.md` Punkt 8 |

Nicht betroffen ist alles, was nicht tot ist oder stirbt: Die Karten setzen erst mit einem Tod ein.

## 5. Kleinste vollständig spielbare Reihenfolge (nach den Antworten)

1. Kartenbestand und Kartenzustand je Person (Karte, gespielt) mit Ziehung über den gespeicherten Generator beim Tod, Anzeige und Markierung „gespielt“ am toten Sitz. Ändert das Speicherformat und braucht deshalb eine eigene Freigabe des Schemas.
2. Befehl und Ereignis „Karte tauschen“ mit den Grenzen aus Frage 3, samt Undo, Save/Load und Geheimhaltung.
3. Kartenschlucker in den Katalog: Stapel, Sieg bei 10 als Siegkandidat mit Spielleiterbestätigung, Verhalten bei Tod und Wiederbelebung. Setup, Lexikon und Regelbuch von 71 auf 72 Rollen.
4. Erst danach und nur bei Bedarf: Zusatzkräfte, Kartenbedingung 141.4, einzelne automatisierte Karten.

Nicht in der kleinsten Umsetzung: Kartenwirkungen, Abstimmungssystem, Kartenbilder, Übersetzung der 80 Texte.

## 6. Erste Fragerunde (einfaches Deutsch), beantwortet am 30.09.2026

Jede Frage: ein Beispiel vom Spieltisch, drei Möglichkeiten, dazu immer die freie Antwort D. Die Empfehlung ist ein Vorschlag, keine Entscheidung.

### Frage 1: Wann bekommt ein Toter seine Karte?

Beispiel: Anna wird in Nacht 2 getötet. Bekommt sie ihre Totenkarte erst jetzt, oder hatte sie die Karte schon seit Spielbeginn?

- **A (Empfehlung):** Jede Person bekommt ihre Karte in dem Moment, in dem sie stirbt. Auch Wölfe. Stirbt jemand nach einer Wiederbelebung noch einmal, kommt eine neue Karte.
- **B:** Wie in der alten Fassung: Dorfleute bekommen die Karte schon am Spielanfang, Wölfe erst beim Tod.
- **C:** Die App zieht keine Karte. Die Spielleitung wählt die Karte selbst aus und trägt sie ein.
- **D:** Eigene Antwort.

Auswirkung von A: Die Ziehung hängt am Todesereignis. Ein Zufallsgenerator entscheidet, gespeichert und wiederholbar. Niemand kennt seine Karte im Voraus. B braucht zusätzlich eine Ziehung beim Start und zwei getrennte Wege. C braucht keinen Zufall, aber mehr Handarbeit am Tisch.

### Frage 2: Was macht die App mit einer Karte?

Beispiel (erfundene Karte, nur zur Erklärung): Anna hat eine Karte, auf der steht „Zeige allen deine Rolle“. Führt die App das aus, oder zeigt sie nur den Text?

- **A (Empfehlung):** Die App zeigt die Karte an und merkt sich „gespielt“. Ausführen tut die Spielleitung am Tisch. Keine Karte ändert selbstständig das Spiel.
- **B:** Wenige einfache Karten führt die App selbst aus, die Auswahl legen wir in einer späteren Runde fest. Der Rest wie A.
- **C:** Alle Karten führt die App selbst aus.
- **D:** Eigene Antwort.

Auswirkung von A: Damit ist der Kartenschlucker sofort spielbar, und es gibt kein Risiko, dass eine Karte die Regeln unbemerkt verändert. Etwa 40 der 80 Karten bräuchten für C eine Abstimmung in der App, die es nicht gibt. C wäre ein sehr großes eigenes Vorhaben.

### Frage 3: Wer darf die Karte tauschen, und wie oft?

Beispiel: Ben (Wolf) ist tot und hat eine schlechte Karte. Darf er sie gegen eine neue tauschen, obwohl er weiß, dass der Kartenschlucker dadurch einen Stapel bekommt?

- **A (Empfehlung):** Jeder Tote darf, auch Wölfe, aber jede Karte nur einmal. Die neue Karte muss sofort gespielt werden und kann nicht wieder getauscht werden. Stirbt jemand nach einer Wiederbelebung erneut, gilt das für die neue Karte.
- **B:** Nur Tote, die keine Wölfe sind, dürfen tauschen.
- **C:** Jeder Tote darf nur ein einziges Mal im ganzen Spiel tauschen, auch nach einer Wiederbelebung.
- **D:** Eigene Antwort.

Auswirkung von A: Entspricht der alten Fassung und dem Rollentext („ein Toter“). Wölfe können dem Kartenschlucker helfen oder ihn bremsen, das ist gewollt spannend. B und C sind einfacher zu begrenzen und schützen vor einem sehr schnellen Sieg, sind aber neue Regeln, die im Text stehen müssten.

### Frage 4: Was kann der Kartenschlucker außer Sammeln, und wer weiß von seinen Stapeln?

Beispiel: Der Kartenschlucker hat 2 Stapel. In der alten Fassung darf er ab jetzt jede Nacht jemanden töten. Soll das so sein?

- **A (Empfehlung):** Nur sammeln und bei 10 Stapeln gewinnen, wie im Rollentext. Die Stapelzahl kennt nur die Spielleitung.
- **B:** Wie in der alten Fassung: Ab 2 Stapeln jede Nacht ein Opfer, alle 3 Nächte sagt die App dem ganzen Dorf die Stapelzahl an, ab 5 Stapeln ein Schild gegen einen Tod.
- **C:** Nur sammeln und bei 10 gewinnen, aber jeder Tausch und die Stapelzahl sind für alle sichtbar.
- **D:** Eigene Antwort.

Auswirkung von A: Kleinste Umsetzung, greift nicht in die Todesregeln ein, die anderen Rollen bleiben unberührt. B macht ihn ab 2 Stapeln zum Nachtmörder, verlangt Tötung, Schild und Ansage im Kern und Tests gegen Hades, Nekromant, Parasit und Rudelvater. C verrät allen sofort, wer der Kartenschlucker ist (nur er hat Stapel), das ist eine Geheimhaltungsfrage.

### Frage 5: Was passiert mit den Stapeln, wenn der Kartenschlucker stirbt?

Beispiel: Der Kartenschlucker hat 8 Stapel und wird in der Nacht getötet. Später wird er wiederbelebt. Hat er noch 8?

- **A (Empfehlung):** Die Stapel bleiben erhalten. Solange er tot ist, zählt er keine neuen Stapel und gewinnt nicht. Nach einer Wiederbelebung geht es bei 8 weiter.
- **B:** Mit dem Tod sind alle Stapel weg. Nach einer Wiederbelebung fängt er bei 0 an.
- **C:** Auch ein toter Kartenschlucker sammelt weiter, und wenn er 10 erreicht, gewinnt er trotzdem.
- **D:** Eigene Antwort.

Auswirkung von A: Entspricht der alten Fassung. B passt zur Entscheidung „Wiederbelebte starten frisch“ (W-01 bis W-04), muss aber ausdrücklich bestätigt werden, weil Stapel ein Zähler und kein „begrenzter Einsatz“ im Sinn der Wiederbelebungsregel ist. C würde einen Toten gewinnen lassen und widerspricht dem Sinn der Tauschregel aus Frage 3.

## 7. Auftrag nach den Antworten (überholt durch 2C, siehe Nachtrag oben)

Sind die Fragen 1 bis 5 beantwortet: Umsetzungsauftrag „Totenkarten-Grundlage und Kartenschlucker“ nach Abschnitt 5, Schritte 1 bis 3 mit Test je Schritt. Vorher nötig: Freigabe der Schemaänderung (Kartenzustand je Person). Nicht Teil: Karteneffekte, Frankenstein-Bedingung, Bilder, Übersetzung.
