# Spielvorbereitung neu denken: Analyse und Konzept

Stand: 03.10.2026. Nur Analyse und Konzept, es wurde kein Code geändert. Alle Bilder liegen in
`C:/Users/Marku/Downloads/Grimmhain-Vorbereitung/` (1024x768, Dateinamen unten). Nichts hier ist eine
Produktentscheidung; offene Punkte stehen in Abschnitt 6.

## 1. Heutiger Ablauf in Godot (Neue Partie bis Nachtbrett)

Beispiel: 13 Personen, Namen per Komma-Text, Vorschlag übernommen. Jeder Schritt ist ein eigener Bildschirm,
jeder braucht eine eigene Bestätigung.

| Nr. | Bildschirm | Was man tut | Bild |
|---|---|---|---|
| 0 | Start, Hauptmenü | "Eintreten", dann "Neue Partie" (7 Menüpunkte) | `01-start.png`, `02-hauptmenue.png` |
| 1 | Spieler (Schritt 1/4) | Namen tippen oder diktieren, Prüfliste, "Alle hinzufügen", "Spieler bestätigen", "Weiter zu den Rollen" | `03-spieler-leer.png`, `04-spieler-pruefliste.png`, `05-spieler-voll.png`, `06-spieler-bestaetigt.png` |
| 2 | Rollen (Schritt 2/4) | Liste mit 72 Rollen und Plus/Minus, "Vorschlag verwenden", "Rollen bestätigen" | `07-rollen-leer.png`, `08-rollen-vorschlag.png`, `09-rollen-vorschlag-zusammenfassung.png` |
| 3 | Verteilung (Schritt 3/4) | "Zufällig" oder "Manuell", "Zufällig verteilen", "Verteilung bestätigen", "Weiter zur Sitzordnung" | `10-verteilung.png`, `11-verteilung-fertig.png`, `12-sitzordnung.png` |
| 4 | Sitzordnung (Schritt 4/4) | Plätze tauschen, "Sitzordnung bestätigen", "Partie starten" | `13-sitzordnung-schritt.png`, `14-sitzordnung-bestaetigt.png` |
| 5 | Nachtbrett | "Nacht beginnen" | `15-nachtbrett.png` |

Mindestens 12 Tipps bis zum Nachtbrett (Neue Partie, Namen, Alle hinzufügen, Spieler bestätigen, Weiter,
Vorschlag, Rollen bestätigen, Zufällig verteilen, Verteilung bestätigen, Weiter, Sitzordnung bestätigen,
Partie starten), davon vier reine Bestätigungen.

Beobachtete Schwächen (am Bild belegt):

- Vier getrennte Bestätigungen plus "Weiter"-Knöpfe. Die Rückwärts-Logik (Änderung hebt Bestätigung auf) ist
  technisch richtig, der Spielleiter spürt sie als Hürde.
- Fachbegriffe in der Oberfläche: "Seed 1773565165349913 · Mischung 0" und "Modus Zufällig" (`12-sitzordnung.png`),
  "Einzelsieg", "Scheinrolle", "Totenreichkarten", "Wiederbelebung", "Nur einmal zu Spielbeginn". Die
  Blocker-Texte der Rollenwahl sind seit DA-88 in einfacher Sprache.
- Die Rollenwahl startet leer (0 von 13) und zeigt 72 Rollen als lange Liste; ohne "Vorschlag verwenden" gibt es
  keinen Anhaltspunkt.
- Layout: Beim Öffnen der Rollenwahl ist die linke Spalte schon halb gescrollt, die Zusammenfassung oben ist
  abgeschnitten (`07-rollen-leer.png`). In Schritt 3 ist die ganze Seite um etwa 66 px nach oben verschoben, die
  Kopfzeile fehlt (`12-sitzordnung.png`).
- Stilbruch: Die Vorbereitung ist flach (dunkle Karten, Goldknöpfe), das Nachtbrett ist ein Hain-Bild mit Wurzel-
  und Mondsilberrahmen (`15-nachtbrett.png`). Auf dem Nachtbrett ist Gold bewusst ausgeschlossen
  (`ThemeTokens.MOON_SILVER`, `BLOOD_RED`), die Vorbereitung nutzt Gold als Hauptfarbe.
- Zufällige Rollenverteilung als eigener Schritt, obwohl die Spielleitung die Rollen später ohnehin über
  "Rollen zeigen" an die Personen weitergibt.

## 2. Was die Vorbilder konkret besser machen

### BotC-react (`Desktop/Blood on the Clocktower/Botc-react`)

Bilder: `v-botc-01-start.png` bis `v-botc-04-rollen.png`, Originalbild `botc-setup2.png` im Projektordner.

- Drei Schritte statt vier: Skript und Spielerzahl, Namen, Rollen. Danach direkt "Start" (rotes Siegel), keine
  Bestätigungsrunde und keine eigene Verteilung. Beim Start werden die Rollen gemischt und den Plätzen zugewiesen
  (`SetupScreen.tsx`, Funktion `start`).
- Spielerzahl zuerst, mit großem Plus/Minus. Aus der Zahl folgen sofort die Rollenzahlen je Team
  (`TOKEN_LIMITS`: zum Beispiel 7 Personen = 5 Dorf, 0, 1, 1) als vier große Zähler.
- Skript als vier Bildkacheln statt Liste (`v-botc-02-skript-spielerzahl.png`).
- Namen sind vorbelegt ("Spieler 1" bis "Spieler 9") in einem Raster genau so groß wie die Spielerzahl
  (`v-botc-03-namen.png`). Man kann ohne Tippen weitergehen.
- Rollen je Team als Raster großer Rundmarken mit Zähler "0 / 5" und Häkchen, wenn das Team voll ist. Gesperrte
  Rollen sind ausgegraut, statt Fehlermeldungen zu zeigen.
- Warnungen sind nicht blockierend ("Spielleiter-Check vor dem Start"); blockiert wird nur, solange ein Team nicht
  voll ist (`allFilled`).
- "Demo laden" startet in einem Tipp eine fertige 12er-Runde.
- Nicht übernehmen: Namensdiktat über die Web Speech API (steht ausdrücklich nicht auf dem Plan) und feste
  Bildschirmvorlagen mit Klickflächen über einem Hintergrundbild (nicht responsiv).

### Grimmhain-Werwolf (`Desktop/Grimmhain/Grimmhain-Werwolf/Grimmhain`)

Bilder: `v-werwolf-01-index.png` bis `v-werwolf-06-rollen.png`.

- Eingangsbildschirm mit nur drei Entscheidungen: Spielerzahl (Plus/Minus), Akt I bis IV oder Custom, Sprache
  (`v-werwolf-03-nach-start.png`).
- Ein Akt ist ein fertiges, kuratiertes Rollen-Set mit Schwierigkeit und Untertitel ("Klassisches Werwolf,
  Einsteiger", "Blut, Flüche, Verwandlung, Fortgeschritten"; `js/core/akte.js`, 72 von 72 Rollen verteilt). Die
  Rollenwahl zeigt danach nur die Rollen dieses Aktes, mit Fragezeichen für die Kurzerklärung je Rolle
  (`v-werwolf-06-rollen.png`).
- Namen in einem einzigen großen Textfeld, getrennt durch Komma, Zähler "0 / 12 Namen" und "Mischen"
  (`v-werwolf-04-namen.png`). Das bestätigt die Idee der Prüfliste für Diktat.
- Drei Schritte (Namen, Rollen, Übersicht nach Dorf, Wolf, Einzelsieg), "Selber verteilen" nur als Zusatzknopf.
- Schwächen, die man nicht übernimmt: Rollenwahl startet auch hier leer (0 / 12), Textwand im Rahmen, kleine
  Knöpfe.

### Gemeinsame Erkenntnis

Beide Vorbilder fragen zuerst nach Spielerzahl und Set, füllen den Rest vor und lassen den Spielleiter nur noch
korrigieren. Godot fragt heute zuerst nach allen Details und füllt erst auf Wunsch ("Vorschlag verwenden").

## 3. Vorschlag: neuer Ablauf in drei Bildschirmen

Grundsatz: Alles ist vorbelegt und änderbar. Blockiert wird nur, was das Spiel wirklich nicht starten kann, und
dann mit einem Satz Erklärung und einem Knopf "Für mich ergänzen". Keine Zwischenbestätigungen; die
bestehende Invalidierungslogik bleibt im Hintergrund (Setup-Entwurf), nur die Knöpfe entfallen.

### Bildschirm 1: Wer spielt mit?

```
+------------------------------------------------------------+
| <  Neue Partie                              1 2 3          |
|                                                            |
|   Spieler       [ - ]   13   [ + ]        [Gruppe laden]   |
|                                                            |
|   [1 Anna ] [2 Ben  ] [3 Cara ] [4 Dora ] [5 Emil ]        |
|   [6 Finn ] [7 Gerd ] [8 Hanna] [9 Ida  ] [10 Jonas]       |
|   [11 Klara] [12 Lukas] [13 Spieler 13]                    |
|                                                            |
|   [ Namen sprechen oder einfügen ]  (Komma, "und", Zeile)  |
|                                                [ Weiter ] |
+------------------------------------------------------------+
```

- Spielerzahl zuerst (6 bis 24, große Plus/Minus-Flächen, mindestens 56 px). Es entstehen genau so viele Namensfelder.
- Felder sind mit "Spieler 3" vorbelegt, antippen öffnet die System-Tastatur mit dem iOS-Diktier-Mikrofon.
- Das Feld "Namen sprechen oder einfügen" nimmt einen Text mit mehreren Namen, teilt ihn auf und zeigt die
  Prüfliste (heute schon gebaut, `NameReviewCard`). "Alle hinzufügen" füllt die Felder der Reihe nach.
- Weiter ist immer aktiv, solange die Zahl stimmt. Keine eigene Bestätigung.

### Bildschirm 2: Besetzung

```
+------------------------------------------------------------+
| <  Besetzung                                   1 [2] 3     |
|  [ Einsteiger ] [ Klassisch ] [ Fortgeschritten ] [ Eigene ]|
|   Dorf 9  |  Wölfe 3  |  Eine Rolle für sich allein 1   OK  |
|                                                            |
|  DORF           [Dorfbew.] [Schutzengel] [Orakel] [..]     |
|  WÖLFE          [Werwolf]  [Spiegelwolf] [Trugbilderw.]    |
|  FÜR SICH       [Manipulator]                              |
|  (große Rundmarken, Zähler als Siegel, Tippen = +1,        |
|   lang drücken oder "-" = -1, "?" = Kurzerklärung)         |
|                                      [ Zurück ] [ Weiter ] |
+------------------------------------------------------------+
```

- Oben fertige Sets (Abschnitt 4). Ein Set belegt sofort die komplette Besetzung für die gewählte Spielerzahl vor.
- Die Ampelzeile zeigt Dorf, Wölfe und "Rolle, die allein gewinnt" mit einem Haken. Fehlt etwas, steht dort ein Satz
  (heutige Texte aus DA-88) und der Knopf "Für mich ergänzen".
- Rollen als Raster großer Rundmarken (Touch, 72 Rollen nach Fraktion in Abschnitten mit Scrollen per Finger),
  statt einer langen Liste mit Plus/Minus. Rollen mit Zusatzoptionen (Trugbilderwolf: Scheinrolle ist vorbelegt;
  Totenreichkarten) öffnen ein kleines Fenster mit einem Satz Erklärung.
- Nicht blockierend bleiben die Hinweise (zum Beispiel Kutscher unter 13 Personen), in einem eigenen Streifen.

### Bildschirm 3: Sitzordnung und Start

```
+------------------------------------------------------------+
| <  Sitzordnung                                  1 2 [3]    |
|          (1)(2)(3)(4)(5)                                   |
|        (13)   Rollen sind zugeteilt,   (6)                 |
|        (12)   niemand sieht sie.       (7)                 |
|          (11)(10)(9)(8)                                    |
|   [ Neu mischen ]  [ Selber verteilen ]       [ Starten ]  |
+------------------------------------------------------------+
```

- Die Rollen werden beim Aufruf einmal zufällig zugeteilt (gleicher gespeicherter Generator wie heute) und
  bleiben verborgen. "Neu mischen" und "Selber verteilen" liegen als Nebenknöpfe darunter.
- Die Sitzordnung ist der Ring aus dem Nachtbrett (`PortraitRingLayout`), Plätze tauschen per Ziehen oder zwei Tipps.
- "Starten" ist der einzige große Knopf und führt direkt zum Nachtbrett. Seed, Mischung und Modus werden nur in
  einem Entwickler-/Detailbereich gezeigt.

Ergebnis: 3 Bildschirme statt 5, höchstens 6 bis 7 Tipps statt 12, keine reine Bestätigung mehr.

## 4. Fertige Rollen-Sets nach Spielerzahl

Vorschlag (noch keine Entscheidung): Ein Set ist eine benannte Rollenmenge plus die vorhandene Heuristik
(`RoleSuggestion`: Wolfszahl 1/2/3/4/5 ab 6/9/13/18/22 Personen, ein Manipulator, Rest Dorf), eingeschränkt auf die
Rollen des Sets. Jede Rolle kommt höchstens einmal vor (Startbesetzung, PE-07).

| Set | Zielgruppe | Rollenmenge (Quelle) |
|---|---|---|
| Einsteiger | erste Runden, 6 bis 12 | die Rollen des Werwolf-Projekts Akt I (12 Dorf, 3 Wolf, 2 allein; `akte.js`), im Katalog prüfen |
| Klassisch | 8 bis 16 | heutiger Vorschlag (`VILLAGE_ORDER`, `WOLF_ORDER`) |
| Fortgeschritten | 12 bis 24 | Akt II bis IV (Blut, Flüche, Verwandlung), Rollen im Katalog prüfen |
| Eigene | alle | Rastervorbelegung leer wie heute |

Für jede Spielerzahl von 6 bis 24 wäre pro Set genau eine feste Besetzung gespeichert und per Test gegen den
Regelkern prüfbar (wie `test_role_suggestion::test_every_proposal_is_a_valid_start_for_the_core`). Der
Vorschlag bleibt eine Starthilfe, keine garantiert ausgewogene Besetzung.

## 5. Optik im Hain-Stil

Gleiche Bauteile und Farben wie das Nachtbrett, damit Vorbereitung und Spiel wie ein Produkt wirken.

- Hintergrund: `godot/assets/night/bg/village-night.webp` mit dunkler Fläche und Nebel
  (`night_fog.gdshader`, `night_vignette.gdshader`) statt flachem Anthrazit.
- Rahmen und Knöpfe: `godot/assets/ui/hain/` (`button_primary.png`, `button_secondary.png`, `card_frame.png`,
  `cartouche.png`, `name_plate_long.png`, `role_medallion.png`, `seat_frame.png`, `side_tab.png`, `back_plate.png`) und
  `godot/assets/night/ui/` (`bar-frame.png`, `role-frame.png`, `slot-active.png`, `slot-done.png`).
- Farben: Mondsilber für Schrift und Ränder (`MOON_SILVER`, `MOON_SILVER_BRIGHT` bei Fokus, `MOON_SILVER_DIM` für
  erledigt), Blutrot nur für die eine aktive Hauptaktion ("Weiter", "Starten", `BLOOD_RED`, `BLOOD_GLOW`), kein
  Gold. Wurzel- und Rankenornamente als Eck- und Trennteile.
- Schritte 1 bis 3 als drei kleine Medaillons (aktiv blutrot, erledigt mondsilber), keine Textleiste.
- Rollenmarken: `role_medallion.png` mit `role-art` oder Silbersymbol, Zähler als kleines Siegel.
- Alle Maße weiter über `ThemeTokens` (Touch mindestens 48 px, große Flächen 56 bis 64 px), Text in DE/EN.

## 6. Offene Entscheidungen für Markus

1. Neue Sets (Einsteiger, Klassisch, Fortgeschritten): Welche Rollen gehören zu welchem Set? Die Akte des
   Werwolf-Projekts sind ein Ausgangspunkt, aber nicht freigegeben.
2. Sind Namen wie "Spieler 3" als Vorbelegung erlaubt? Heute müssen Namen eingegeben werden.
3. Darf die Verteilung als eigener Schritt entfallen und beim Aufruf der Sitzordnung automatisch passieren?
4. Bleiben die drei Pflichtprüfungen (Dorf, Wolf, Rolle für sich allein) blockierend, oder werden sie wie bei BotC
   zu Hinweisen? Das ist eine bestehende Spielregel-Entscheidung und wurde hier nicht angetastet.
5. Soll das Schrittband aus dem Nachtbrett ("Vorbereitung" unten links) die neue Vorbereitung auch aus dem Spiel
   heraus öffnen?

## 7. Quellen

- Godot: `godot/app/screens/new_game/`, `godot/app/setup/` (`RoleSuggestion`, `RoleSetup`, `PlayerSetup`).
- BotC-react: `app/src/setup/SetupScreen.tsx`, `botcSetupData.ts` (`TOKEN_LIMITS`, `validateSetupSelection`).
- Werwolf: `Grimmhain/js/core/akte.js`, `Grimmhain/setup.html`.
