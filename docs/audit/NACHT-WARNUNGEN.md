# Nacht-Warnungen (Mini-Nachtkarte, DA-101)

Stand 05.10.2026, Branch `feat/feedback-6-7`. Warnungen stehen nur auf der Nachtkarte, wenn für den Schritt etwas Besonderes gilt: rote Zeile mit Symbol, höchstens 6 Wörter, keine Kommas, keine Fachwörter, immer mit Namen, höchstens 3 untereinander. Abgeleitet aus dem Zustand im Regelkern über vorhandene Regelabfragen (`godot/app/session/night_warnings.gd`, keine eigene Regel). Texte zentral in `godot/content/i18n/ui.de.po` und `ui.en.po` unter `ui.warn.*`. Warnungen zu Zielpersonen gelten vor der Wahl für alle wählbaren Personen (bei fester Anzahl gilt ein Tipp sofort), nach einer Wahl nur für die gewählten. "Letzte Nutzung" gibt es nicht: Alle begrenzten Fähigkeiten im Regelkern sind einmalig, die Zeile stünde bei jeder Nutzung und wäre kein Sonderfall (offen für Markus).

## Texte

| Schlüssel | Text DE | Text EN | Beispiel |
|---|---|---|---|
| `ui.warn.blocked` | {role} blockiert {name} | {role} blocks {name} | Albtraumwolf blockiert Anna / Schattenhund blockiert Anna |
| `ui.warn.repeat` | {name} handelt noch einmal | {name} acts once more | Anna handelt noch einmal |
| `ui.warn.borrowed` | {name} handelt als {role} | {name} acts as {role} | Tom handelt als Doktor |
| `ui.warn.protected` | {name} ist geschützt | {name} is protected | Anna ist geschützt |
| `ui.warn.lovers` | {a} und {b} sind Liebende | {a} and {b} are lovers | Anna und Tom sind Liebende |
| `ui.warn.cursed` | {name} ist verflucht | {name} is cursed | Tom ist verflucht |

## Für alle Rollen mit Nachtschritt

| Warnung | Auslöser | Text |
|---|---|---|
| repeat | Zweiter Durchgang durch den Apfel des Rotkäppchens (`apple_steps`). | {name} handelt noch einmal |

## Je Rolle

| Rolle | Warnung | Auslöser | Text |
|---|---|---|---|
| Schutzengel (`schutzengel`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Das Orakel (`das-orakel`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Das Orakel (`das-orakel`) | cursed | Eine mögliche Person (schaut) ist vom Dämonischen Wolf verflucht; Auskünfte zeigen „Werwolf“. | {name} ist verflucht |
| Waldhexe (`waldhexe`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Waldhexe (`waldhexe`) | lovers | Eine mögliche Person (Giftziel) ist in einem Loki-Paar „Liebende“ mit lebendem Partner. | {a} und {b} sind Liebende |
| Wolfskind (`wolfskind`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Lehrling (`lehrling`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Dorfchronistin (`dorfchronistin`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Waldläufer (`waldlaeufer`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Doktor (`doktor`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Doktor (`doktor`) | cursed | Eine mögliche Person (prüft zwei) ist vom Dämonischen Wolf verflucht; Auskünfte zeigen „Werwolf“. | {name} ist verflucht |
| Fährtenleser (`faehrtenleser`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Korrupter Richter (`korrupter-richter`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Spürhund (`spuerhund`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Spürhund (`spuerhund`) | cursed | Eine mögliche Person (prüft drei) ist vom Dämonischen Wolf verflucht; Auskünfte zeigen „Werwolf“. | {name} ist verflucht |
| Henker (`henker`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Traumdeuter (`traumdeuter`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Kopfgeldjäger (`kopfgeldjaeger`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| König (`koenig`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| König (`koenig`) | cursed | Eine mögliche Person (lernt kennen) ist vom Dämonischen Wolf verflucht; Auskünfte zeigen „Werwolf“. | {name} ist verflucht |
| Kriegerin des Lichts (`kriegerin-des-lichts`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Kriegerin des Lichts (`kriegerin-des-lichts`) | lovers | Eine mögliche Person (greift an) ist in einem Loki-Paar „Liebende“ mit lebendem Partner. | {a} und {b} sind Liebende |
| Kriegerin des Lichts (`kriegerin-des-lichts`) | cursed | Eine mögliche Person (greift an) ist vom Dämonischen Wolf verflucht; Auskünfte zeigen „Werwolf“. | {name} ist verflucht |
| Blutpriester (`blutpriester`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Die Ewigen (`die-ewigen`) | cursed | Eine mögliche Person (prüfen) ist vom Dämonischen Wolf verflucht; Auskünfte zeigen „Werwolf“. | {name} ist verflucht |
| Schutzgeist (`schutzgeist`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Dorfschmied (`dorfschmied`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Verdammniswächter (`verdammniswaechter`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Loki (`loki`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Rotkäppchen (`rotkaeppchen`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Seelentauscher (`seelentauscher`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Kutscher (`kutscher`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Dr. Victor Frankenstein (`dr-victor-frankenstein`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Zeitwächter (`zeitwaechter`) | blocked | Der Schritt dieser Person entfiel durch Blockade (Albtraumwolf: `blocked_ids`, Schattenhund: `village_blocked`). Die Warnung steht auf der nächsten Nachtkarte, weil der blockierte Schritt selbst keine Karte hat. | {role} blockiert {name} |
| Werwolf (`werwolf`) | protected | Ein mögliches Rudelopfer wäre geschützt (`KillPipeline.pack_protection`: Schutzengel, Waldhexe, Wache, Waffe, Schild, Weiser). | {name} ist geschützt |
| Werwolf (`werwolf`) | lovers | Eine mögliche Person (Rudel wählt das Opfer (auch zweites Opfer)) ist in einem Loki-Paar „Liebende“ mit lebendem Partner. | {a} und {b} sind Liebende |
| Giftwolf (`giftwolf`) | lovers | Eine mögliche Person (vergiftet) ist in einem Loki-Paar „Liebende“ mit lebendem Partner. | {a} und {b} sind Liebende |
| Schicksalswolf (`schicksalswolf`) | lovers | Eine mögliche Person (wählt Personen) ist in einem Loki-Paar „Liebende“ mit lebendem Partner. | {a} und {b} sind Liebende |
| Rachsüchtiger Wolf (`rachsuechtiger-wolf`) | lovers | Eine mögliche Person (reißt einen Wolf) ist in einem Loki-Paar „Liebende“ mit lebendem Partner. | {a} und {b} sind Liebende |
| Grabräuber (`grabraeuber`) | borrowed | Der Grabräuber handelt mit einer gestohlenen Fähigkeit (eigene Rolle ungleich Rolle des Schritts). | {name} handelt als {role} |
| Kartenschlucker (`kartenschlucker`) | lovers | Eine mögliche Person (tötet) ist in einem Loki-Paar „Liebende“ mit lebendem Partner. | {a} und {b} sind Liebende |

Rollen ohne Eintrag haben außer `repeat` keine Warnung. 33 Rollen mit mindestens einer Warnung, 41 Zeilen.
