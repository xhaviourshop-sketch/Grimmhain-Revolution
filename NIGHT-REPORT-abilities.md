# NIGHT-REPORT — Phase 2: Fähigkeiten-Audit aller Rollen

Quelle der Wahrheit: `../Grimmhain/js/{core,ui}/**` (Vanilla). Klassifikation aus
`ROLE_DESCRIPTIONS` (roles.js) + den Interaktions-Mechanismen:
`startPick` = 1 Ziel, `startMulti(n)` = n Ziele, `#overlay`/`startConfirm` = Dialog/Ja-Nein,
`center()` = Info-Toast. Handler, die ich nicht einzeln geöffnet habe, sind mit **(?)** markiert.

## Interaktionstypen
- **passiv** — keine Nacht-Interaktion (Auto-/Tod-/Tag-/Lynch-Trigger)
- **1 Ziel** — ein Sitz antippen (`startPick`)
- **n Ziele** — mehrere Sitze (`startMulti`)
- **Info** — Enthüllung (oft nach Pick oder automatisch; `center`/`#overlay`)
- **Dialog** — Entweder/Oder-Auswahl (`#overlay` mit Buttons)
- **Ja/Nein** — `startConfirm`
- **bedingt** — nur unter Bedingung aktiv, dann einer der obigen Typen

## React-Flow-Deckung (aktueller Stand)
- ✅ **passiv** — nichts nötig.
- 🟡 **1 Ziel** — mechanisch da (Token-Tap → `selectPlayer` → `pickMode.onSeat`), aber ohne Prompt-/`allow`-Führung.
- 🟡 **n Ziele** — mechanisch da (n-mal tippen, `startMulti` akkumuliert), aber **kein „noch N"-Feedback** (B6).
- ❌ **Info** — Ergebnis (`center`/`#overlay`) wird in React nicht angezeigt (B1).
- ❌ **Dialog / Ja/Nein** — `DialogPanel` nicht gemountet (B1).

---

## DORF (39)

| Rolle | Nacht-Typ | React deckt? |
|---|---|---|
| Schutzengel | 1 Ziel | 🟡 |
| Korrupter Richter | 1 Ziel | 🟡 |
| Rotkäppchen | 1 Ziel | 🟡 |
| Wolfskind | 1 Ziel (1. Nacht) | 🟡 |
| Lehrling | 1 Ziel (1. Nacht) | 🟡 |
| Schutzgeist | 1 Ziel (bedingt: nach eig. Tod) | 🟡 |
| Sensenträger | 1 Ziel (Tod-Trigger) | 🟡 |
| Dorfschmied | bedingt → 1 Ziel (Nacht 6) | 🟡 |
| Henker | bedingt (3 Lynch) → 1 Ziel | 🟡 |
| Dr. Victor Frankenstein | 1 Ziel (Toten) → Folge-Aktion (?) | 🟡 |
| Doktor | **2 Ziele** → Info (Team gleich?) | 🟡/❌ |
| Seelentauscher | **2 Ziele** (Rollentausch) | 🟡 |
| Spürhund | **3 Ziele** → Info | 🟡/❌ |
| Kutscher | bedingt (10 Tote) → **3 Ziele** (?) | 🟡 |
| Loki | **Dialog** (Liebe/Hass) → **2 Ziele** | ❌ |
| Waldhexe | **Dialog** (retten ODER 1 Ziel verdammen) | ❌ |
| Verdammniswächter | **Dialog** (1 von 2 Opfern) | ❌ |
| Amalia | bedingt → **Ja/Nein-Frage** (öffentlich) | ❌ |
| Märtyrerin | bedingt → opfert sich (Ja/Nein?) (?) | ❌ |
| Zeitwächter | 1x Aktion (Nacht einfrieren) (?) | 🟡/❌ |
| Das Orakel | 1 Ziel → **Info** (Rolle) | 🟡/❌ |
| Blutpriester | 1 Ziel → **Info** (0–3 Wölfe) | 🟡/❌ |
| Kriegerin des Lichts | 1 Ziel → **Info** (Wolf?) + ggf. Selbsttod | 🟡/❌ |
| Fährtenleser | **Info** (Richtung, 1x) | ❌ |
| Waldläufer | **Info** (Anzahl Wölfe) | ❌ |
| Dorfchronistin | **Info** (Anzahl Solos, Start) | ❌ |
| Die Gebundenen | **Info** (kennen sich, 1. Nacht) | ❌ |
| Die Ewigen | **Info**/bedingt (jede Nacht prüfen) | ❌ |
| Traumdeuter | **Info** (Visionen) | ❌ |
| König | bedingt → **Info** (1 Dorf-Rolle) | ❌ |
| Kopfgeldjäger | bedingt (Wolf-Lynch) → **Info** (3) | ❌ |
| Detektiv | passiv → **Info** (auto bei Wolfstod) | ❌ |
| Der Weise | passiv | ✅ |
| Dorfbewohner | passiv | ✅ |
| Dorfwache | passiv | ✅ |
| Nachtwächter | passiv (Auto-Alarm) | ✅ |
| Ritter | passiv (Tod-Trigger) | ✅ |
| Wächter am Tor | passiv | ✅ |
| Wahnsinniger Kutscher | passiv (Lynch-Trigger) | ✅ |

## WOLF (19)

| Rolle | Nacht-Typ | React deckt? |
|---|---|---|
| Werwolf | 1 Ziel (Rudel-Opfer) | 🟡 |
| Albtraumwolf | 1 Ziel (blockt Dorf) | 🟡 |
| Dämonischer Wolf | 1 Ziel (verflucht) | 🟡 |
| Schwarze Witwe | 1 Ziel | 🟡 |
| Giftwolf | 1 Ziel (2x, bedingt) | 🟡 |
| Rachsüchtiger Wolf | 1 Ziel (jede 3. Nacht) | 🟡 |
| König Lykaon | 1 Ziel (1. Nacht) → Trugbilderwolf | 🟡 |
| Schattenwanderer | 1 Ziel (1. Nacht, Todeskette) | 🟡 |
| Spiegelwolf | 1 Ziel (Tag/bedingt: wer nominierte) | 🟡 |
| Rudelvater | passiv; bei Lynch → 1 Ziel (2. Opfer) | 🟡 |
| Besessener Wolf | 1 Ziel (Tod-Trigger: reißt 1 mit) | 🟡 |
| Schicksalswolf | **3 Ziele** (Start) + bedingt Bonus (Nacht 4) | 🟡/❌ |
| Schattenhund | 1x Aktion (blockt alle Dorf, 0 Ziel?) (?) | 🟡/❌ |
| Blutwolf | passiv | ✅ |
| Cerberus | passiv | ✅ |
| Fenrir | passiv | ✅ |
| Seuchenwolf | passiv (Tod) | ✅ |
| Siegreicher Wolf | passiv | ✅ |
| Trugbilderwolf | passiv | ✅ |

## SOLO (14)

| Rolle | Nacht-Typ | React deckt? |
|---|---|---|
| Feuerteufel | 1 Ziel | 🟡 |
| Parasit | 1 Ziel (heften) | 🟡 |
| Voodoo-Priester | 1 Ziel (Puppe) | 🟡 |
| Grabräuber | 1 Ziel (1x, Toten bestehlen) | 🟡 |
| Pestbringerin | 1 Ziel/Aktion (Seuche) (?) | 🟡 |
| Rattenfänger | **1–2 Ziele** (verzaubern) | 🟡 |
| Prophet des Untergangs | **3 Ziele** (markieren) | 🟡/❌ |
| Nekromant | bedingt → **3 Ziele** ODER **Dialog** (Kill umlenken) | 🟡/❌ |
| Hades | **Info + Aktion/Menü** (Lichter, Fähigkeiten kaufen) | ❌ |
| Todesprediger | **Info/Eingabe** (Todeszeitpunkt, 1. Nacht) | ❌ |
| Doppelspion | passiv (wacht mit Rudel) | ✅ |
| Kartenschlucker | passiv | ✅ |
| Manipulator | passiv | ✅ |
| Selbstmörder | passiv | ✅ |

---

## Lücken-Liste (was der UI fehlt), nach Interaktionstyp

1. **Info-Anzeige (❌, ~16 Rollen):** Orakel, Blutpriester, Doktor, Fährtenleser, Waldläufer, Dorfchronistin, Die Gebundenen, Die Ewigen, Traumdeuter, König, Kopfgeldjäger, Detektiv, Kriegerin des Lichts, Hades, Todesprediger, (Amalia). Legacy zeigt Ergebnisse über `center()`/`#overlay`; React surft das nicht. **Größte Lücke.**
2. **Dialog / Entweder-Oder (❌, ~4):** Loki (Liebe/Hass), Waldhexe (retten/verdammen), Verdammniswächter (1 von 2), Nekromant (Kill umlenken). Braucht gemountetes `DialogPanel` (existiert).
3. **Ja/Nein (❌, ~2):** Amalia (öffentliche Frage), Märtyrerin (?). Braucht Dialog-Anzeige.
4. **Multi-Ziel-Fortschritt (🟡, ~9):** Loki, Doktor, Seelentauscher, Spürhund, Nekromant, Prophet, Schicksalswolf, Kutscher, Rattenfänger. Mechanisch via Mehrfach-Tap da, aber ohne „noch N"-Feedback und ohne Anzeige der bereits gewählten Sitze.
5. **1-Ziel-Führung (🟡, viele):** funktioniert per Token-Tap, aber Prompt-Text/`allow`-Hervorhebung der erlaubten Sitze fehlt.

## Unsicher / braucht Markus-Entscheidung
- Genaue Ziel-Anzahl/Bedingungen bei **(?)**-Rollen (Kutscher, Frankenstein-Folge, Schattenhund, Märtyrerin, Pestbringerin, Zeitwächter) — Handler nicht einzeln verifiziert, im Zweifel nicht raten.
- **Hades** ist ein eigenes Sub-Menü (Lichter kaufen) — komplexer Sonderfall, eigene UI nötig.
- **Multi-Ziel im Legacy:** Die Ziel-Anzahl steht nur im Pickbar-Hint („noch N") — robustes Auslesen ist fragil (s. Summary).
