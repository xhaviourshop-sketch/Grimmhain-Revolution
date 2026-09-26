# Special-Role-Flow-Report — reaktive & späte Sonderrollen

Stand: 2026-06-19 · React-Shell (`app/`), Adapter `legacy`, Sprache DE.
Methode: pro Rolle ein gezielt vorbereiteter Spielstand per Skript in
`localStorage` (Tote, Lichter, Wolfsopfer …), dann im Browser (Playwright)
durchgespielt und der ActionCenter-/Dialog-/State-Zustand gemessen.

Pro Rolle beantwortet: (1) weiß der SL sofort, was passiert? (2) muss er
antippen? (3) ist klar, wer betroffen ist? (4) sichtbares Ergebnis? (5) Rolle
korrekt verbraucht? (6) Rückgängig? (7) Protokoll verständlich?

---

## 1. Märtyrerin — ✅ funktioniert (1 Fix)

Spielstand: Werwolf + Märtyrerin + Ritter. Wolf tötet „Cara" → Tag.

- Reaktiver Trigger beim Morgengrauen löst korrekt aus (kein Nachtreihen-Schritt).
- **Vorher unklar:** Der Dialog zeigte nur das Opfer „Cara" + „Opfern/Nein"; oben
  stand noch „Werwolf" → der SL sah nicht, dass die **Märtyrerin** entscheidet.
  → **Fix M1:** Das ActionCenter zeigt jetzt die handelnde Rolle als Kopfzeile
  („Märtyrerin"), wenn sie von der Nacht-Order-Rolle abweicht. Verifiziert:
  „**Märtyrerin**" + „Cara" + „Opfern/Nein".
- „Opfern": Märtyrerin (Berta) stirbt, Opfer (Cara) gerettet, `MaertyUsed=true`
  (korrekt einmalig verbraucht).
- Sichtbares Ergebnis: Morgengrauen „✝️ Märtyrerin Berta" (lesbar).
- **Rückgängig:** ✅ revertiert (Berta lebt, Märtyrerin wieder verfügbar).
- ⚠️ **Protokoll:** die Opferung erscheint NICHT im Recap-Protokoll (nur im
  Morgengrauen). Siehe „Bekannte breitere Lücke" unten.

## 2. Nekromant — ✅ funktioniert (1 Fix)

Spielstand: Nekromant + Werwolf + 3 Tote (mit Stimme).

- Frage klar (W1): „Schild gegen den nächsten Tod: Wähle drei Tote …" +
  „Schild — 3 Tote auswählen" / „Abbrechen".
- **Vorher Bug N1:** In der 3-Tote-Auswahl waren **keine** Sitze hervorgehoben
  (alle wirkten blockiert), obwohl die 3 Toten gültige Ziele sind — der SL sah
  nicht, wen er antippen soll (Antippen funktionierte „blind"). Ursache: der
  Adapter filterte tote Sitze grundsätzlich aus den hervorgehobenen Zielen.
  → **Fix N1:** Das Auswahl-Prädikat entscheidet jetzt (auch für tote Ziele).
  Verifiziert: die 3 Toten (Tom, Udo, Vera) sind als wählbar markiert.
- 3 Tote ausgewählt → Stimmen entzogen (`deadVoteStripped`), Schild aktiv
  (`TotenratDeathImmunityPending`), Info-Ergebnis sichtbar.
- Nur Tote wählbar (Prädikat erzwingt es) — keine Lebenden.
- ⚠️ Kleinigkeit: Das Ergebnis nennt „Totenrat-Führer" statt „Nekromant"
  (i18n-Benennung) — verständlich, aber leicht inkonsistent.

## 3. Dr. V. Frankenstein — 🔴 KRITISCH (kein kleiner Fix)

Spielstand: Frankenstein + Werwolf + 1 Leiche („Tina").

- Frage klar: „Möchtest du jemanden wiederbeleben?" → Ja/Nein.
- Toten-Auswahl: „Tina" jetzt korrekt als Ziel hervorgehoben (profitiert von Fix N1).
- **🔴 FK1 — der SL kann die neue Rolle NICHT wählen.** Nach Auswahl des Toten
  zeigt die Legacy ein `<select>`-Dropdown („Wähle eine neue Rolle …") + Knopf
  „Rolle vergeben". Der React-Dialog-Mirror überträgt nur **Buttons**, nicht das
  `<select>`. Folge: Es erscheint nur „Weiter", und das Drücken vergibt die
  **alphabetisch erste** verfügbare Rolle (im Test: Tina wurde als „Loki"
  wiederbelebt — vom SL ungewollt).
- Wiederbelebung an sich + Einmaligkeit korrekt (`FrankensteinUsed=true`).
- ⚠️ Die „… wiederbelebt als X"-Bestätigung erscheint im React nicht klar.
- **Kein kleiner Fix:** Erfordert, dass der Adapter `<select>`-Dialoge spiegelt
  und das ActionCenter ein Dropdown rendert + die Auswahl zurückschreibt
  (moderate Erweiterung). → eigene Aufgabe, NICHT ohne Rückfrage umgesetzt.

## 4. Hades — ✅ funktioniert

Spielstand: Hades + Werwolf, `HadesLichter=10`, einige Tote.

- Alle Optionen je Lichterstand sichtbar mit Kosten im Label: „2🕯️ Töte …",
  „3🕯️ Barriere", „5🕯️ Stimme × 3", „**10🕯️ SIEG EINLÖSEN**", „Nichts tun".
- **Siegbedingung bei 10 Lichtern:** „SIEG EINLÖSEN" → Sieg-Banner „Hades
  gewinnt" (`TeamWinner=solo_Hades`, Lichter→0). Verifiziert.
- **Keine rohen Schlüssel / unklaren Texte** (alle Buttons übersetzt).
- Verbessert (Fix M1): die **Lichterzahl** steht im Dialog-Titel („Hades — N 🕯️")
  und wird jetzt über dieselbe Kopfzeile angezeigt (vorher nur im verworfenen
  Titel). Die Button-Kosten zeigten die Optionen ohnehin an.

## 5. Verdammniswächter — ✅ funktioniert

Spielstand: Werwolf + Verdammniswächter + Ritter. Wolf tötet „Tom".

- Entscheidung klar (W1): „Wer stirbt? Wähle 1 von 2: Tom (Nachtopfer) oder Vera"
  + Knöpfe „Tom stirbt" / „Vera stirbt" — **Namen korrekt**.
- „Vera stirbt" (Umleitung): Vera tot, Tom gerettet (`targeted` zurückgesetzt).
- **Tod am Morgen korrekt:** Morgengrauen „⚖️ Verdammniswächter Vera" (lesbar).
- ⚠️ Protokoll: wie bei Märtyrerin nicht im Recap (Morgengrauen zeigt ihn).

---

## Reparierte Bugs (klein, in erlaubten Kategorien)

- **N1 — tote Zielsitze nicht hervorgehoben** (`legacyAdapter.ts`): das
  Auswahl-Prädikat entscheidet jetzt über die wählbaren Sitze (auch Tote).
  Nekromant + Frankenstein zeigen ihre toten Ziele korrekt. *Keine Regression für
  lebend-zielende Rollen (ohne eigenes Prädikat bleibt „nur lebend" die Vorgabe).*
- **M1 — handelnde Rolle/Kontext im Dialog fehlte** (`ActionCenter.tsx`): bei
  Auswahl-/Info-Dialogen wird der Dialog-Titel als Kopfzeile gezeigt, wenn er von
  der Nacht-Order-Rolle abweicht (Märtyrerin-Dawn-Dialog, Hades-Lichterzahl).

`npm run build` (tsc + vite) fehlerfrei.

---

## Zusammenfassung

**Funktionieren gut:** Märtyrerin, Nekromant, Hades, Verdammniswächter (mit den
zwei Fixes oben). Die Dialoge sind jetzt klar (handelnde Rolle, Frage, Ziele,
Ergebnis sichtbar), Rollen werden korrekt verbraucht, Rückgängig wirkt.

**Kritisch bleibt:**
- **🔴 Dr. V. Frankenstein** — Rollen-Auswahl beim Wiederbeleben ist im
  React-Shell nicht bedienbar (kein Dropdown). Funktioniert nur „blind" mit der
  ersten Rolle. Braucht einen dedizierten Fix (Dropdown-Mirroring).

**Bekannte breitere Lücke (kein Einzel-Fix):**
- Im **Recap-Protokoll** fehlen mehrere Todesursachen (Märtyrerin-Opfer,
  Verdammniswächter, auch der reine Wolfs-Nachttod). Der **Morgengrauen-Dialog
  zeigt alle Tode** korrekt und lesbar — das Protokoll ist also ein gefilterter
  Recap, kein vollständiges Sterbe-Log. Ein vollständiges SL-Logbuch wäre eine
  eigene Aufgabe (zentraler Death-Hook statt verstreuter `gameLog.add`-Aufrufe).

**Kleinere Restpunkte:**
- Nekromant-Ergebnis nennt „Totenrat-Führer" statt „Nekromant" (i18n-Benennung).

## Empfohlene nächste Aufgabe für Markus

1. **Frankenstein-Wiederbelebung bedienbar machen** (FK1): `<select>`-Dialoge im
   Adapter spiegeln + im ActionCenter ein Dropdown rendern. Klar abgegrenzte
   Aufgabe, einziger echter Blocker unter den Sonderrollen.
2. Optional danach: **vollständiges SL-Nacht-/Sterbe-Logbuch** (alle Todesursachen
   ins Protokoll, zentral).
