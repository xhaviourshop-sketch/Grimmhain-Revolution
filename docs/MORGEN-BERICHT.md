# Morgen-Bericht Nachtlauf 15.10.2026

Stand: Branch `nacht-fixes` (von `classic-akt`, Commit bfbd8b8). Kein Deploy, kein Merge, kein Push. `classic-akt` und `main` sind unverändert. Auf `nacht-fixes` liegen drei Commits (zwei Testdateien, eine Korrektur) und dieser Bericht.

Belege (Bilder, Protokolle, Skripte): `C:/Users/Marku/Downloads/Grimmhain/Screenshots/Nachtlauf-15-10/` und `C:/Users/Marku/Downloads/Grimmhain/Vorbereitung/nachtlauf-skripte/`.

## 1. Ampel

| Phase | Ampel | In einem Satz |
|---|---|---|
| 1 Volle Prüfung classic-akt | GRÜN | `node tools/test-full --merge` mit Fuzz: 1514 Tests, 0 fehlgeschlagen, Exit 0, nichts zu sortieren. |
| 2 Dauertest Produktion | GELB | 37 Minuten, 7 Partien, 5 davon bis zum Spielende (36 volle Runden), keine Fehlermeldung, kein Absturz; aber der Speicher wächst im Nachtbild (jetzt auf nacht-fixes behoben). |
| 3 Rollen-Durchlauf Classic | GELB | Regeln grün (30 Fälle auf Deutsch und Englisch, kein Regelfehler); gelb wegen drei Anzeigefehlern in "Neue Partie" (Classic-Karte und Rollenwahl brauchen Scrollen). |
| 4 Gegenprobe Absturz | GRÜN | 5 Minuten Nacht ohne Eingriff, Fortsetzen mitten in der Nacht, 15 Minuten angehaltene Seite und eine Stunde Leerlauf: auf Produktion und Classic kein Hängen, kein Fehler, Bedienung und Musik laufen danach weiter. |

## 2. Befunde

Schweregrad: Absturz, falsche Regel, Anzeige, Kleinigkeit.

| Nr | Was | Wo | Schweregrad | Produktion betroffen | Auf nacht-fixes korrigiert | Test |
|---|---|---|---|---|---|---|
| B-01 | Im Nachtbild wächst der Speicher der Seite stetig, etwa 4 MB pro Minute (im Menü 0). Ursache: Der Puls der handelnden Person und der Feuerring zeichnen jedes Bild neu; im Web legt jedes Neuzeichnen neue Zeichenpuffer an, deren Kennungen wachsen. Mit "Bewegung reduzieren" wächst nichts. Hochgerechnet 240 MB pro Stunde. | `godot/app/widgets/seat_ring/game_seat_token.gd` | Absturz (nur auf Dauer, bei sehr langen Sitzungen auf dem iPad) | ja (gemessen: 12 auf 25 MB in 5 Minuten; im Dauertest 10 auf 121 MB in 35 Minuten) | ja, Commit 03583a2: Puls zeichnet höchstens 15-mal pro Sekunde; Wachstum danach 0,7 MB pro Minute (gleiche Messung, 240 s) | ja, `test_seat_pulse_redraws_at_a_limited_rate` |
| B-02 | Neue Partie, Schritt "Welchen Akt": Die Classic-Karte (fünfte Karte) steht unter dem Rand, man muss scrollen. Überhang 110 px bei 1024x768, 32 px bei 1180x820. Verstößt gegen "NIE scrollen müssen". | `godot/app/screens/new_game/round_step.gd`, Aktkarten | Anzeige | nein (Classic nur auf classic-akt) | nein (Layout-Entscheidung nötig, siehe unten) | nein, Messung per Skript im Bericht |
| B-03 | Die Classic-Karte selbst ist kleiner als die anderen: Die Punktzeile liegt über dem Untertitel, "Bis zu 24 Personen" ragt über den Kartenrand. | `godot/app/screens/new_game/act_card.gd` | Anzeige | nein | nein | nein |
| B-04 | Rollenwahl bei Classic mit 8 Personen: Die Zeile "Einzelgänger" (Selbstmörder, Flötenspieler) liegt unter dem Rand, man muss scrollen. In Akt I (Produktion) passt alles. | `round_step.gd`, Rollenschritt | Anzeige | nein | nein | nein |
| B-05 | Fehlklick im letzten Nachtschritt: Die Nacht endet nach dem Tipp von selbst. Das erste "Rückgängig" nimmt nur das Nachtende zurück (Karte "Nacht abschließen"), erst das zweite die falsche Wahl. | Cockpit, Rückgängig | Kleinigkeit | ja (gleicher Ablauf) | nein (Bedienentscheidung) | ja, `test_undo_after_a_wrong_pick_reopens_the_question` hält den Ablauf fest |
| B-06 | Englische Knöpfe mit drei Wörtern: "Read the rule", "Do not heal", "Use healing potion", "Open final report". Regel: Knöpfe 1 bis 2 Wörter (Deutsch passt). | Sprachdatei Englisch | Kleinigkeit | ja | nein | nein |
| B-07 | Liebende gewinnen nicht gemeinsam: Wolf und Dorfbewohner als Liebespaar, die allein übrig bleiben, gelten als Wolfssieg. Der Charakterbogen nennt keinen Sieg der Liebenden; Auftrag fragte danach. Frage an Markus. | Regelkern, Siegprüfung | falsche Regel (offene Entscheidung) | nein (nur Classic-Amor) | nein | nein |
| B-08 | Englischer Rollenname "The Vile Wolve Father" (Urwolf): "Wolve" ist vermutlich ein Tippfehler des Bogens, im Spiel übernommen. | Sprachdatei Englisch | Kleinigkeit | nein | nein | nein |
| B-09 | `docs/classic/FAEHIGKEITEN.md` sagt beim Urwolf "einmal im ganzen Spiel Ja oder Nein". Das Spiel fragt jede Nacht neu, bis er einmal verwandelt hat (ein "Nicht jetzt" verbraucht nichts). Das Verhalten passt zum Bogen, der Text der Doku ist missverständlich. | Doku | Kleinigkeit | nein | nein | ja, `test_urwolf_declining_does_not_use_up_the_power` hält das Verhalten fest |

Kein Befund war ein Regelfehler im Code: Hexe (heilen, vergiften, beides), Jäger (Schuss, kein Schuss, nach Hinrichtung, nach Gift, nach Weißem Wolf), Ritter (ein Wolf, zwei Wölfe mit Links und Rechts, drei Wölfe, toter Wolf wird übersprungen, keine Wirkung bei Hinrichtung, Rettung, Schutz und Weißem Wolf), Amor (Liebe, Hass, sich selbst), Flötenspieler (1, 2, Einzelsieg), Urwolf, Weißer Wolf (nur gerade Nächte, Einzelsieg), Seherin (wahre Rolle), Brüder und Schwestern, Alte, Engel gegen Gift sowie die Siege (Dorf, Wölfe, Weißer Wolf, zwei Kandidaten mit Bestätigen und Ablehnen), Rückgängig, Speichern und Fortsetzen verhalten sich wie in `docs/classic/FAEHIGKEITEN.md`. Die Fenstertexte stehen in beiden Sprachen, ohne Programmtext.

### Zahlen

- Phase 2, Produktion (Build 24b58f5, Chrome, 1180x820, Touch): 37 Minuten, 7 Partien, davon 5 bis zum Spielende (8, 6, 1, 9 und 12 Runden), 14 Hinrichtungen, 0 Konsolenfehler, 0 Seitenabstürze. Eine Partie hing nur, weil mein blinder Spielroboter ein Fenster nicht traf (kein App-Fehler); der Rest lief ohne Hänger. Laden: Ereignis "geladen" nach 0,3 s, Spielbereit nach etwa 5 s (wasm 9,3 MB nach 4,0 s, Spielstand-Paket 18,6 MB nach 5,0 s).
- Fortsetzen mitten in der Nacht (Produktion): Seite neu geladen, "Partie fortsetzen", gleicher Stand (7 von 7 Befehlen), danach 240 s ohne Eingriff, keine Fehler, Tipp danach angenommen. Das ist genau der Fall des Hotfix 24b58f5. Classic lokal: gleiches Ergebnis (4 von 4 Befehlen).
- 5 Minuten Nacht ohne Eingriff: Produktion und Classic, alle 20 Bildproben verschieden (das Bild lebt), keine Fehler, Bedienung danach da.
- Angehaltene Seite (JavaScript 15 Minuten gestoppt, wie ein schlafendes Gerät): Produktion und Classic danach Bild lebt, Musik (Audio-Kontext) läuft, Tipp wird angenommen, keine Fehler.
- Eine Stunde Leerlauf in der Nacht (61 Minuten ohne Eingriff, danach Tipp): Produktion und Classic ohne Fehler, Bild lebt, Musik läuft weiter (Audio-Kontext zählt mit), Tipp danach angenommen, Speicher flach bei 10 bis 11 MB (in dieser Nachtstufe pulst keine Person, daher kein Wachstum). Das Einfrieren der Seite (Chrome-Zustand "frozen") griff nicht, die Seite antwortete weiter; der Lauf zählt deshalb als Leerlauf, der Schlaf ist durch das 15-Minuten-Anhalten abgedeckt.

## 3. Empfehlung

1. Vor Sonntag in die Produktion: nur die Speicher-Korrektur 03583a2 (eine Datei, ein Test, gemessen 4 auf 0,7 MB pro Minute), nach Freigabe und einem Blick aufs Nachtbild; die Produktion ist sonst stabil (Hotfix 24b58f5 hält: Fortsetzen, Nacht ohne Eingriff und Schlaf ohne Fehler).
2. Nur in die Classic-Vorschau: die Tests aus `test_nacht_classic_roles.gd`; die Anzeigefehler B-02 bis B-04 vorher entscheiden (Akt-Karten kleiner oder zwei Spalten mit weniger Text), sonst muss man dort scrollen.
3. Entscheidung von Markus nötig: B-07 (gewinnen Liebende gemeinsam?), B-05 (soll ein Rückgängig bei automatischem Nachtende gleich die Wahl zurücknehmen?).
4. Kann warten: B-06 (englische Knöpfe kürzen), B-08, B-09.
5. Merge und Deploy nur auf Auftrag; vorher auf dem finalen Stand einmal `node tools/test-full --merge`.

## 4. Nicht geprüft

- iPad und Safari (Chrome auf Windows ersetzt sie nicht; der Speicher auf dem iPad kann sich anders verhalten).
- Echte Touch-Hardware (nur Touch-Emulation mit Touch-Ereignissen).
- Echter Hintergrund-Tab: Chrome im Testlauf meldet die Seite immer als sichtbar. Ersatz: JavaScript 15 Minuten angehalten (wie Gerät im Schlaf) und eine Stunde Leerlauf. Echte Bildschirmsperre und Gerätschlaf fehlen.
- Hörbarkeit der Musik: gemessen wurde nur, dass der Audio-Kontext läuft und weiterzählt.
- Classic im Browser über mehrere volle Runden: Mein blinder Spielroboter blieb bei den Classic-Fenstern hängen (Knöpfe liegen anders als in Akt I). Die Classic-Abläufe sind dafür in Godot über den Bedienweg geprüft; im Browser nur Start, erste Nachtschritte, Fortsetzen, Leerlauf und angehaltene Seite.
- Sichtprüfung aller Classic-Fenster (geprüft wurden Texte und Knöpfe, keine Pixel). Hochformat.
- Lokaler Classic-Export hat ladebild, siegel und wortmarke nicht kopiert (drei 404 im Testlauf); der Weg über `tools/export-web.js` wurde nicht benutzt, weil er in den Auslieferungsordner schreibt.
