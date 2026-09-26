# Role-Flow-Report — Spielleiter-Sicherheit (Grimmhain React)

Stand: 2026-06-19 · React-Shell (`app/`), Adapter `legacy`, Sprache DE getestet.
Methode: Testrunden per Skript in `localStorage` gebaut, Nachtreihenfolge im
Browser (Playwright) Schritt für Schritt ausgeführt und der ActionCenter-/
Dialog-Zustand jeweils gemessen (Modus, Zielanzeige, Ergebnis, Erledigt-Marke,
Sprung, Protokoll). Kernfrage: Kann ein SL nachts/tags nichts Wichtiges übersehen?

---

## Aufgabe 1+2: Getestete Rollen & SL-Sicherheit

Pro Rolle geprüft: (1) klar was zu tun? (2) Antippen klar? (3) Bestätigen klar?
(4) sichtbares Ergebnis? (5) Doppel-Ausführen möglich? (6) Rückgängig? (7) Protokoll?
(8) richtige nächste Rolle?

### A) Einfache Rollen mit Ziel
| Rolle | Modus | Ergebnis | Bewertung |
|---|---|---|---|
| **Schutzengel** | 1 Ziel | Schutz gesetzt (Ring) | ✅ Prompt „Wähle einen Spieler", 15 wählbar (Selbst aus), springt korrekt weiter. ⚠️ kein Protokoll-Eintrag für den Schutz. |
| **Das Orakel** | 1 Ziel → Info | zeigt die Rolle (z. B. „Fährtenleser") | ✅ Ergebnis klar sichtbar, „Weiter"-Knopf. |
| **Spürhund** | **3 Ziele** → Info | „✅ Eine Spur führt zu einem Wolf …" | ✅ funktioniert; ist faktisch eine Mehrfachziel-Rolle (gehört auch zu B). |

### B) Rollen mit mehreren Zielen
| Rolle | Ziele | Bewertung |
|---|---|---|
| **Rattenfänger** | erst „1 Ziel/2 Ziele", dann 1–2 | ✅ Zähler „noch N", gewählte Namen sichtbar, sauberer Abschluss. |
| **Spürhund** | 3 | ✅ Zähler korrekt, Ergebnis als Info. |
| (Doktor, Loki, Prophet, Nekromant nutzen dieselbe 2-/3-Ziel-Mechanik) | | per Code identisch aufgebaut. |

### C) Rollen mit Info-Ergebnis
- **Das Orakel** → Rolle des Ziels. ✅ sichtbar.
- **Fährtenleser** → „Nächster Wolf: rechts". ✅ klare Richtungsinfo.
- **Spürhund** → ✅/❌-Ergebnis. ✅

### D) Rollen mit Entscheidung (Auswahlknöpfe)
- **Waldhexe** → 3 Knöpfe „Nicht retten / Schicksal bewahren / Tödliches Schicksal",
  danach verketteter Folgedialog. ✅ Knopf-Flow + Verkettung funktionieren.
  ⚠️ Der Dialog-Kontext (Rolle des Opfers, das die Hexe „sieht") wurde im
  ActionCenter NICHT angezeigt → **repariert (W1)**.

### E) Werwolf-Schritt
- **Werwolf**: ✅ alle Wölfe (Werwolf + Albtraumwolf) mit **rotem Glow** klar
  erkennbar; Prompt „Wähle einen Spieler"; Opfer wird `targeted` (stirbt erst im
  Morgengrauen — korrekt). Tag danach startet korrekt mit Morgengrauen-Dialog.
- **Albtraumwolf**: ✅ blockt eine Dorf-Fähigkeit (14 wählbar = nur Dorf).

### F) Später kritische Rollen
| Rolle | Art | Testbarkeit / Befund |
|---|---|---|
| **Hades** | aktiv (Pick, Lichter-Ökonomie) | Erscheint in der Reihenfolge. Komplex (sammelt „Lebenslichter", Sieg bei 10). Im Freeze-Test zeigte er einen rohen i18n-Schlüssel → **repariert (F1)**. Voller Lichter-Flow nicht erschöpfend getestet (braucht Tote + mehrere Nächte). |
| **Nekromant** | aktiv (3 Tote wählen) | Schwer früh testbar: braucht **≥3 Tote mit Stimme**. Mechanik per Code ok (startMulti 3). Risiko: erst spät im Spiel prüfbar. |
| **Dr. V. Frankenstein** | aktiv, einmalig (Toten wiederbeleben) | Schwer testbar: braucht **eine Leiche**; einmalig (`FrankensteinUsed`). Nicht in Nacht 1 sinnvoll. |
| **Zeitwächter** | aktiv, einmalig (Info) | ✅ getestet: friert die Nacht ein, klare Info-Meldung. Nebenwirkung: blockt Folge-Rollen (zeigte F1-Bug, jetzt behoben). |
| **Märtyrerin** | **reaktiv** (Opfer-Dialog beim Morgengrauen) | **Keine Nachtreihen-Stufe** — löst während der Todesauflösung aus (`night.js`). Per „Fähigkeit ausführen" nicht testbar; nur über einen echten Nacht-Tod. Risiko: separater Flow, hier nicht live durchgespielt. |
| **Pestbringerin** | aktiv (Vergiften 1) | ✅ getestet: Prompt klar, max 2 Tränke, 1/Nacht. |
| **Schattenhund** | aktiv (Ja/Nein), einmalig | ✅ getestet: in **Nacht 1 gesperrt** (klare Meldung), ab Nacht 2 Ja/Nein. ⚠️ Frage fehlte → **repariert (W1)**. |
| **Verdammniswächter** | bedingt (braucht Wolfsopfer) | ✅ getestet: 2-Knopf-Wahl „X stirbt / Y stirbt" mit Namen — klar. |

---

## Aufgabe 4: Nacht → Tag → Nacht (durchgespielt, 16 Spieler)

1. Nacht 1: 8 Rollen ausgeführt (Schutzengel, Werwolf, Albtraumwolf, Waldhexe,
   Rattenfänger, Orakel, Fährtenleser, Spürhund) — alle sauber, je korrekter Sprung.
2. Tag: Morgengrauen zeigt die Tode (Wolf tötet Ritter → **Ritter-Vergeltung**
   tötet den Wolf — Logik korrekt).
3. Lynch: funktioniert, Protokoll „⚖ Lynch: … gelyncht."
4. Nacht 2:
   - ✅ Night Order startet wieder bei **Rolle 1** (`1 / 8`).
   - ✅ keine Rolle vorverbraucht (`NightUsedRoles` leer, „ausführen" aktiv).
   - ✅ tote eindeutige Rollen fallen über `hasAliveRole` raus; die „Werwolf"-Stufe
     ist die **Rudel-Tötung** und bleibt korrekt, solange **ein** Wolf lebt.
   - ✅ ActionCenter passt immer zur Rolle oben (Name + Text wechseln gemeinsam).
   - ✅ Protokoll lesbar (Tode/Lynch mit Ursache, z. B. „Bert wurde vom Ritter erschlagen").

Weitere SL-Sicherheit verifiziert:
- **Doppel-Ausführen verhindert:** erledigte Rolle zeigt „✓ bereits ausgeführt",
  Knopf deaktiviert.
- **Rückgängig:** nimmt den letzten Schritt zurück, entfernt die ✓-Marke (Rolle
  wieder ausführbar) und schreibt „↩️ Rückgängig: Aktion: … zurückgenommen." ins
  Protokoll.

---

## Aufgabe 3: Reparierte Fehler (klein, klar)

- **D1 — Morgengrauen unleserlich → behoben.** Die Toten-Liste kam als
  zusammengeklebter Text („⚔️ RitterBert🐺 WerwolfNils"). Der Adapter las den
  strukturierten Dialog-Body per `textContent`. Fix: `domMirror.ts` liest jetzt je
  Toten eine Zeile (Ursache + Name), Tag-Dialog mit `white-space: pre-line`.
  Ergebnis: „⚔️ Ritter Anton" / „🐺 Werwolf Bea" (je Zeile). Verifiziert.
- **W1 — Ja/Nein & Entscheidungen ohne Frage/Kontext → behoben.** Das ActionCenter
  zeigte bei Auswahl-Dialogen nur die Knöpfe (z. B. „Ja/Nein") ohne die Frage.
  Fix: `ActionCenter.tsx` zeigt im choice-Modus jetzt den Dialog-Text (z. B.
  „Dorf-Fähigkeiten 1 Nacht blockieren?", Waldhexe-Opferrolle). Verifiziert.
- **F1 — roher i18n-Schlüssel sichtbar → behoben.** Nach Zeitwächter-Freeze zeigte
  eine blockierte Rolle „timekeeperFrozenBlock". Schlüssel fehlte in `i18n.js`
  (DE+EN ergänzt). Jetzt: „Keine Fähigkeit — der Zeitwächter hat diese Nacht
  eingefroren." Verifiziert.

`npm run build` läuft fehlerfrei (tsc + vite).

---

## Was bleibt offen / Risiken

- **🔴 Wichtig — bodennahe Sitze unter den Undo/Next-Buttons (auf 768 px Höhe).**
  Beim Testen fing der Undo-Button echte Sitz-Taps ab („intercepts pointer
  events") → ein verdeckter Sitz ist **auf dem Brett nicht antippbar**. Das ist
  derselbe Layout-Rest wie im TABLET-UX-REPORT (Action Frame ↔ untere Leiste nur
  ~36 px Lücke). **Workaround für den SL:** die Zielwahl geht auch über die
  ◀▶-Pfeile im ActionCenter (unabhängig vom Brett-Tap). Sauberer Fix = bodennahe
  Sitze seitlich umverteilen (Layout-Umbau, bewusst zurückgestellt).
- **Protokoll zeigt keine geheimen Nachtaktionen** (Schutz, Verzauberung,
  Wolfsziel, Orakel-Blick). Tode, Lynch, Phasen und Rückgängig werden protokolliert.
  Das ist vertretbar (Recap = öffentliche Ereignisse), aber falls der SL ein
  vollständiges Nacht-Logbuch wünscht, wäre das ein separates Feature.
- **ActionCenter-Zielpfeile** können einen unerlaubten Sitz (z. B. sich selbst)
  anvisieren; „Bestätigen" tut dann still nichts. Klein, eher Verwirrung als Fehler.
- **Reaktive/bedingte Rollen nicht live erschöpfend getestet:** Märtyrerin
  (Morgengrauen-Trigger), Nekromant (≥3 Tote), Frankenstein (Leiche + einmalig),
  Hades-Lichter-Ökonomie. Code-Pfade gesichtet, aber sie brauchen vorbereitete
  Spielstände über mehrere Nächte → Restrisiko bei Sonderinteraktionen.

---

## Empfehlung: nächste Aufgabe für Markus

1. **Layout-Rest lösen (höchste Priorität):** bodennahe Sitze nicht mehr unter die
   Undo/Next-Leiste legen (kleiner gezielter Layout-Lauf), damit jeder Sitz
   antippbar ist. Das ist der einzige echte Bedien-Blocker.
2. Danach: **dedizierter Durchlauf der reaktiven Sonderrollen** (Märtyrerin,
   Nekromant, Frankenstein, Hades) mit vorbereiteten Spielständen.
3. Optional: **SL-Nacht-Logbuch** (geheime Nachtaktionen für den SL sichtbar machen).
