# Sitzordnung · vierter Setup-Schritt

Stand: 27.09.2026 · Godot 4.7.2 · Projekt `godot/`

Nach der bestätigten Rollenverteilung legt der Spielleiter die Sitzordnung für 6 bis 24 Personen fest. Grundlage im Decision Log („Personen, Sitze und Darstellung“): Zustände haften an der stabilen Personen-ID, nicht am Sitzplatz; Sitzplätze lassen sich per Drag-and-drop tauschen. Das Ergebnis bleibt ein Entwurf im Speicher: kein `StartGame`, kein `GameState`, kein Befehl.

## Zustand und Invalidierung

`SetupDraft.seating` (`app/setup/seating_draft.gd`, `SeatingDraft`):
- `order: Array[int]`: Personen-IDs im Uhrzeigersinn ab Platz 1; entspricht später `seat_order` im StartGame
- `confirmed`, `invalidated` (`""`, `person_count_changed`, `setup_changed`)

Nur `PlayerSetup` verändert den Zustand. Die Personen, ihre Namen und die Verteilung bleiben unverändert an der Personen-ID; der Tausch ändert ausschließlich `order`.

| Ereignis | Reihenfolge | Bestätigung |
|---|---|---|
| Person hinzufügen | neue Person ans Ende | aufgehoben (`person_count_changed`, falls vorher bestätigt oder bereits ungültig) |
| Person entfernen | Person fällt weg, übrige behalten ihre relative Folge | wie oben |
| Name ändern | bleibt | aufgehoben (`setup_changed`), weil der Namensschritt neu bestätigt werden muss |
| Rollen oder Verteilung ändern, neu mischen | bleibt | aufgehoben (`setup_changed`) |
| Plätze tauschen | zwei Einträge getauscht | aufgehoben, Grund leer |
| Navigation, erneutes Öffnen, Sprachwechsel | bleibt | bleibt |

Der Schritt ist nur mit bestätigten Spielern, Rollen und Verteilung erreichbar (`players_not_confirmed`, `roles_not_confirmed`, `distribution_not_confirmed`, jeweils der früheste offene Schritt). Fällt eine Vorbedingung weg, springt der Wizard wie bisher auf den letzten erreichbaren Schritt zurück.

## Öffentliche API (`PlayerSetup`)

| Methode | Fehlercodes |
|---|---|
| `go_to_step(&"seating")` | `players_not_confirmed`, `roles_not_confirmed`, `distribution_not_confirmed` |
| `swap_seats(a, b)` | Vorbedingungen wie oben, `unknown_person`, `same_person`; bei Ablehnung unverändert |
| `confirm_seating()` | Vorbedingungen wie oben; wiederholt ohne Wirkung |

Sicht `view()["seating"]`: `seats` [`seat`, `person_id`, `name`], `person_count`, `confirmed`, `can_confirm`, `invalidated`, `ready` (alle vier Schritte bestätigt). `steps` enthält jetzt vier Einträge.

## Oberfläche

- **Einstieg:** In der Karte „Bereit für Sitzordnung“ der Verteilung steht „Weiter zur Sitzordnung“. Zurück, Escape und „Verteilung bearbeiten“ führen zur Verteilung.
- **Sitzkreis** (`seat_circle.gd`): Plätze als Ring um einen Tisch, Platz 1 oben links, im Uhrzeigersinn. Die Aufteilung auf obere Reihe, rechte Seite, untere Reihe und linke Seite wird aus Personenzahl und Fläche berechnet (`SeatCircle.layout`). Plätze sind mindestens 120 px breit und 56 px hoch, überlappen nie und lassen die Tischmitte frei. Beispiele: 6 Personen bei 1024×768 → 2/1/2/1; 24 bei 1024×768 → 7/5/7/5; 24 bei 1920×1080 → 9/3/9/3.
- **Platzsymbol** (`seat_token.gd`): „3 · Anna“ in Kompaktschrift (18 px), eine Zeile, lange Namen mit Auslassungszeichen. Nie eine Rolle, Scheinrolle oder Kopie.
- **Tauschen per Drag-and-drop:** Person auf einen anderen Platz ziehen. Während des Ziehens ist die Quelle abgeblendet, eine goldene Vorschau folgt dem Zeiger, das Ziel unter dem Zeiger ist hervorgehoben. Loslassen außerhalb eines Platzes bricht ab: nichts ändert sich, die Fußzeile meldet „Ziehen abgebrochen“.
- **Tauschen per Antippen:** erste Person antippen (goldene Markierung, Hinweis „Ausgewählt: Anna (Platz 3)…“ und „Auswahl aufheben“ in der Tischmitte), dann den Zielplatz. Dieselbe Person erneut, „Auswahl aufheben“ oder Zurück/Escape heben die Auswahl auf.
- **Rückmeldung:** Fußzeile „Ben und Hanna haben die Plätze getauscht.“, kurze Statusmeldung „Plätze getauscht“ ohne Namen oder Rollen.
- **Bestätigen:** „Sitzordnung bestätigen“ zeigt in der Tischmitte „Sitzordnung fertig“ und sperrt den Button. Der Entwurf (Personen, Rollen, Verteilung, Sitzordnung) ist vollständig.
- **Theme:** Variationen `SeatButton` (normal, schmaler Innenrand), `SeatSelectedButton` (Gold) und `SeatTargetButton` (angehobene Fläche, heller Goldrahmen); Mindesthöhe des Kreises `ThemeTokens.SEAT_CIRCLE_MIN_HEIGHT`.

## Tests und Screenshots

```bash
godot/tests/run_all.sh --filter=test_seating   # Modell und Oberfläche
xvfb-run -a -s "-screen 0 1920x1080x24" <godot-4.7.2> --path godot --rendering-driver opengl3 \
  --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- --only=seating
```

Unter Windows mit Bildschirm genügt `<godot-console-exe> --path godot --audio-driver Dummy -s res://tools/capture_ui_screenshots.gd -- --only=seating`.

| Testdatei | Inhalt |
|---|---|
| `tests/ui/test_seating_model.gd` | Startreihenfolge, Identität, Rolle und Name beim Tausch, 23 Tausche als Permutation, ungültige Tausche atomar, Schrittsperren, Bestätigen, Personen- und frühere Änderungen, Navigation, keine Rollen in der Sicht |
| `tests/ui/test_seating_step.gd` | Einstieg über die Karte, Tauschen und Abbrechen per Antippen, Drag-and-drop mit echten Mausereignissen, Zieh-Rückmeldung und Abbruch, Bestätigen/Zurück/erneut öffnen, Personenänderung, Geheimhaltung DE/EN, Layout 1024×768/1280×800/1920×1080 mit 6/12/24 Personen und langen Namen |

Prüf-Screenshots: `docs/evidence/seating-setup/`.

## Grenzen

- Touchbedienung ist nur über die Mausemulation von Godot abgedeckt, nicht auf einem Tablet geprüft.
- Nur Tauschen, kein Einfügen (Verschieben mit Nachrücken) und keine Drehung des ganzen Kreises.
- Bei vielen Plätzen werden sehr lange Namen gekürzt; der volle Name steht in der Auswahl.
- Kein `StartGame`: Die Abbildung auf `seat_order` sowie `roles`/`appearances` (siehe `role-setup.md`) folgt im nächsten Arbeitspaket.
