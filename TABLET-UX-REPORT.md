# Tablet-UX-Report — Grimmhain (Spielleiter-Oberfläche)

Stand: 2026-06-19 · React-Shell (`app/`), Nacht-Phase, Adapter `legacy`.

Getestet per Browser (Playwright) bei drei Tablet-Größen × drei Spielerzahlen,
mit objektiver Messung (Bounding-Box-Überlappung) statt nur Augenmaß. Testrunden
mit voll besetzten, lebenden Sitzen und absichtlich teils langen Namen
(„Maximilian", „Wilhelmina", „Konstantin", „Friederike") als Stresstest.

## Messübersicht (Nacht, alle Werte gemessen)

| Größe | Spieler | Token | Namens-Kollisionen | Namen über Frame-Inhalt | Tokens unter unteren Buttons | Night-Order |
|---|---|---|---|---|---|---|
| 1024×768 | 12 | 84 px | 0 | 0 | – | ok (40 px) |
| 1024×768 | 18 | 48 px | 4 | 0 | – | ok |
| 1024×768 | 24 | 48 px | **17** | 0 | **3** | ok |
| 1180×820 | 12 | 84 px | 0 | 0 | – | ok |
| 1180×820 | 18 | 82 px | 2 | 0 | – | ok |
| 1180×820 | 24 | 48 px | 0 | 0 | – | ok |
| 1366×768 | 12 | 50 px | 0 | 0 | **2** | ok |
| 1366×768 | 18 | 50 px | 0 | 0 | – | ok |
| 1366×768 | 24 | 48 px | 1 | 0 | – | ok |

„Namen über Frame-Inhalt" = Überlappung mit den **sichtbaren** Flächen des Action
Frames (`.ac-text` / `.ac-art` / Hauptknopf), nicht mit dem breiten transparenten
Dekorrand. „Tokens unter unteren Buttons" wurde an den kritischen Fällen
(24@1024, 12@1366) gegen die **echten** Undo/Next-Button-Rechtecke gemessen.

---

## Pro Bildschirmgröße

### 1024 × 768 (iPad quer, engster Fall)
- **Gut:** Night Order oben sauber (ein Name, 40 px, kein Abschneiden). Action
  Frame sitzt mittig, Fähigkeitstext + Hauptknopf gut lesbar. Bei 12 Spielern
  volle Token-Größe (84 px), keine Kollision.
- **Störend:** Ab 18 Spielern werden Tokens auf das Minimum (48 px) gedrückt und
  die Namen an den **linken/rechten Seitenbögen** überlappen. Bei **24 Spielern
  ist es unbrauchbar** (17 Überlappungen, Namen stapeln sich unlesbar).
- **Dringend reparieren:** Namens-Kollisionen bei 18–24 Spielern.
- **Feinschliff:** —

### 1180 × 820 (iPad 11", mehr Höhe — bester Fall)
- **Gut:** Praktisch kollisionsfrei bis 24 Spieler (0 Überlappungen bei 24, nur
  2 kleine bei 18). Die zusätzliche Höhe gibt den Seitenbögen genug Platz.
- **Störend:** Minimal (2 kleine Namensberührungen bei 18, rein durch lange Namen).
- **Dringend reparieren:** —
- **Feinschliff:** die zwei langen-Namen-Berührungen bei 18.

### 1366 × 768 (Laptop quer)
- **Gut:** Keine Namens-Kollisionen bei 12/18, nur 1 minimale bei 24. Night Order
  und Action Frame sauber.
- **Störend:** Bei wenigen Spielern (12) bleiben die Tokens klein (50 px) mit viel
  ungenutztem Boardrand — wirkt leer. Außerdem ragen 2 Tokens leicht unter die
  unteren Undo/Next-Buttons.
- **Dringend reparieren:** Tokens unter den unteren Buttons.
- **Feinschliff:** kleine Tokens / ungenutzter Platz bei wenigen Spielern.

---

## Befunde gesamt (Ursachen)

1. **KRITISCH — Namens-Kollision bei vielen Spielern auf 768 px Höhe.**
   Ursache: Auf 768 px Höhe stehen die seitlichen Sitze dicht übereinander; die
   waagerechten Namensboxen (zur Kreismitte ausgerichtet) überlappen. Lange Namen
   verschärfen es horizontal. Der Auto-Fit prüft nur Token-Abstände, nicht die
   Breite der Namensboxen — und am Token-Minimum (48 px) kann er nicht weiter
   verkleinern. → Muss in der Namens-Darstellung gelöst werden.

2. **WICHTIG — Tokens unter den unteren Undo/Next-Buttons (Priorität #5).**
   Ursache: Der Auto-Fit reserviert die unteren Ecken mit `CORNER` (rechts 300 px,
   Höhe 128 px). Die echte Undo/Next-Leiste ist aber ~514 px breit (mittig-rechts,
   nicht in der Ecke) und 167 px hoch und beginnt schon bei ~x = (Breite − 552).
   Die Reserve unterschätzt sie → bottom-nahe Tokens grenzen an die Buttons.

3. **OK (kein Problem) — Action Frame verdeckt keine Spieler.**
   Tokens werden korrekt um die gemessene Frame-Box herumgeschoben; **kein** Name
   überlappt je den sichtbaren Frame-Inhalt (über alle 9 Fälle = 0).

4. **OK — Night Order.** Immer genau ein Name, 40 px, nie abgeschnitten, nie zu hoch.

5. **FEINSCHLIFF — kleine Tokens / leerer Rand bei wenigen Spielern auf 1366×768.**
   Die unteren Buttons (große, mittig-rechte Leiste) stauchen das Oval bei 768 px
   Höhe; bei wenigen Spielern bleibt viel Rand frei. Kosmetisch, nicht störend.

---

## Reparaturplan (nur das Wichtigste, keine großen Umbauten)

- **Fix 1 (Priorität #1):** Namens-Darstellung am Token entschärfen — Breite
  begrenzen, dunkle Hinterlegung (Pille) + stärkerer Schatten für Lesbarkeit,
  Schrift bei kleinen Tokens leicht reduzieren, aktive/gewählte Namen nach vorne.
  Ziel: keine unlesbaren Stapel mehr bei 18–24 Spielern.
- **Fix 2 (Priorität #5):** untere Reserve des Auto-Fit an die echte Undo/Next-
  Leiste annähern (Höhe + rechte Breite), damit keine Tokens mehr unter den
  Buttons grenzen.

Bewusst NICHT angefasst (kein großer Umbau): vollständige Neumodellierung der
unteren Leiste als zentralem Clearance-Objekt, sowie die kleinen Tokens bei
wenigen Spielern (kosmetisch).

---

## Reparatur & Nachtest (2026-06-19)

### Umgesetzt

**Fix 1 — Namens-Kollisionen entschärft (Priorität #1).**
`app/src/components/DomBoard.tsx` + `app/src/styles/tokens.css`:
- Namensschrift + Boxbreite an die Tokengröße gekoppelt: kleine Tokens (viele
  Spieler) → kleinere, kürzere Namensboxen → weit weniger Überlappung.
- Dunkle Pille (Hinterlegung) + stärkerer Schatten: berühren sich Namen doch,
  bleibt der vordere lesbar; gewählter/Vorschau-Sitz kommt nach vorne.
- Voller Name bleibt per Tooltip (`title`) erhalten; vollständig steht er ohnehin
  oben in der Night Order.

### Nachtest (gemessen, Nacht)

| Größe | Spieler | Namens-Kollisionen vorher → nachher | Tokengröße |
|---|---|---|---|
| 1024×768 | 24 | **17 → 7** (alle als lesbare Pillen) | 48 px |
| 1024×768 | 18 | **4 → 0** | 48 px |
| 1024×768 | 12 | 0 → 0 | 84 px |
| 1180×820 | 24 | 0 → 0 | 48 px |
| 1180×820 | 18 | 2 → 0 | 82 px |
| 1366×768 | 24 | **1 → 0** | 50 px |
| 1366×768 | 12 | 0 → 0 | 50 px |

`npm run build` läuft fehlerfrei (tsc + vite). Keine Token-Größen-Regression,
keine Namen über dem sichtbaren Action-Frame-Inhalt (über alle Fälle = 0).
Browser-Screenshots geprüft: 1024×768/24 und 1366×768/24 — Namen sind kleine,
dunkle, lesbare Pillen statt unlesbarer Stapel.

### Bewusst NICHT repariert (Begründung)

**Tokens grenzen an die unteren Undo/Next-Buttons (Priorität #5) — offen.**
Auf 768 px Höhe liegen Action Frame (Unterkante ~564) und die untere Aktionsleiste
(Oberkante ~600) nur ~36 px auseinander. Die Medaillon-Clearance schiebt einen
boden-mittigen Sitz zwangsläufig in genau diese Lücke → er grenzt unten an die
Buttons (untere ~⅓ des Tokens). Betroffen sind 1–3 boden-mittige Sitze bei
768 px Höhe; visuell sind die Sitze sichtbar (nur der untere Rand grenzt an die
Plakette), aber ein Tap dort kann den Button treffen.
Mehrere getestete Schnell-Fixes (Bar als Push-Box / als Abflach-Hindernis,
größere Eck-Reserve) lösten es NICHT sauber und stauchten stattdessen die Tokens
bei wenigen Spielern (84 → 48 px) oder drückten Namen in den Frame. Eine saubere
Lösung müsste boden-mittige Sitze **seitlich umverteilen** (Layout-Algorithmus) —
das ist ein größerer Umbau und wurde daher bewusst zurückgestellt.

**Kleine Tokens / leerer Rand bei wenigen Spielern auf 1366×768 — offen
(Feinschliff).** Kosmetisch, stört die Bedienung nicht.

### Zusammenfassung

- **Repariert:** Namens-Kollisionen (Hauptproblem) — bei 18 Spielern komplett weg,
  bei 24 Spielern von unlesbar (17) auf 7 lesbare Pillen reduziert; alle übrigen
  Größen kollisionsfrei.
- **Getestet:** 3 Größen × 3 Spielerzahlen, vorher/nachher gemessen, `npm run build`
  grün, Screenshots 1024×768/24 + 1366×768/24.
- **Bleibt offen:** boden-mittige Sitze grenzen an die unteren Buttons (768 px Höhe);
  kleine Tokens bei wenigen Spielern auf 1366×768 (kosmetisch).
- **Noch kritischste Größe:** **1024×768 bei 24 Spielern** — bleibt der dichteste
  Fall (7 Rest-Pillen-Berührungen + Button-Grenzfall). Empfehlung für ein Tablet:
  Höhe ≥ 800 px (z. B. 1180×820) → praktisch kollisionsfrei.

---

## Untere Bedienzone — Aussparung für die Undo/Next-Leiste (2026-06-19)

Der letzte Bedien-Blocker: bodennahe Sitze lagen unter der unteren Undo/Next-
Leiste; der Button fing echte Sitz-Taps ab → diese Spieler waren auf dem Brett
nicht antippbar.

### Aufgabe 1 — vorheriger Zustand (gemessen, 24 Spieler, Nacht)

| Bildschirm | Tokens an/unter der Leiste | Mittelpunkte UNTER der Leiste (= nicht antippbar) | min. vertikaler Abstand zur Leiste |
|---|---|---|---|
| 1024×768 | 3 (Klaus, Lena, Maximilian) | 2 (Lena, Maximilian) | **−36 px** (Überlappung) |
| 1180×820 | 3 (Jana, Klaus, Lena) | 2 (Klaus, Lena) | **−31 px** |
| 1366×768 | 3 (Ivo, Jana, Klaus) | 2 (Jana, Klaus) | **−73 px** |

→ Auf allen drei Größen ragten ~3 boden-mittige Sitze in die Leiste, davon 2 mit
dem Mittelpunkt darunter (durch den Button verdeckt, Tap wurde abgefangen).

### Aufgabe 2 — was geändert wurde

`app/src/components/DomBoard.tsx`: Der Sitz-Ring bekommt unten eine **gemessene
Aussparung** für die Bedienleiste.
- Die untere Leiste (`[data-testid="bottom-actions"]`) wird zur Laufzeit gemessen
  (wie das zentrale Medaillon).
- `seatAnglesByArc` verteilt die Sitze jetzt optional über den Kreis **minus** einem
  unteren Winkel-Keil. Der Keil = genau die Winkel, bei denen ein Sitz in der (um
  Token-Radius + Abstand erweiterten) Leisten-Box landen würde (per Abtastung, nicht
  per Eckwinkel — der Ellipsenradius kann einen Eckwinkel überschießen).
- Folge: die unteren Sitze wandern **nach links/rechts**, bottom-center bleibt frei,
  Tokens werden **nicht** verkleinert (im Gegenteil teils größer, weil die Aussparung
  Platz schafft). Der Kreis wirkt weiter rund, hat unten nur eine kleine Aussparung.
- Sicherheitsnetz: `fits()` lehnt zusätzlich jede Lage in der Leisten-Box ab.

### Aufgaben 3+5 — nachher (gemessen, 24 Spieler)

| Bildschirm | Tokens an der Leiste | Mittelpunkte darunter | min. Abstand | Token-Größe vorher→nachher | Namens-Kollisionen vorher→nachher |
|---|---|---|---|---|---|
| 1024×768 | **0** | **0** | **+24 px** | 48 → 48 px | 7 → 1 |
| 1180×820 | **0** | **0** | **+24 px** | 48 → **62 px** | 0 → 1 |
| 1366×768 | **0** | **0** | **+23 px** | 50 → 50 px | (1) → 1 |

- **Unantippbare Sitze: vorher 2 je Größe → nachher 0.**
- Echter Brett-Tap auf den **untersten** Sitz verifiziert: setzt korrekt das Ziel
  (`targeted`) und springt weiter — **kein** Undo/Next-Button fängt den Tap mehr ab.
- Zielwahl per **ActionCenter-Pfeile** unverändert (funktioniert weiter).
- **Keine Rückschritte:** 12 Spieler bleiben bei voller Token-Größe (84 px), 18
  Spieler sogar größer (48 → 58 px); Action Frame überlappt keine Sitze; Night Order
  sauber; Namen lesbar; untere Buttons frei erreichbar.

`npm run build` läuft fehlerfrei.

### Bleibt offen
- Nichts Blockierendes mehr. Die Aussparung ist immer aktiv (auch bei wenigen
  Spielern) — das ist gewollt (feste Bedienzone unten). Rein kosmetisch könnte man
  die Aussparung bei sehr wenigen Spielern noch kleiner machen; nicht nötig.
