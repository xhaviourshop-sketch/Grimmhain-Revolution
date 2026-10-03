# 10 · Nächste Entscheidungen

**Stand:** 2026-10-03 (Ergänzung) · geprüft gegen `origin/main` `8197ee6` · Vorlage für den Product Owner

Diese Seite enthält nur, was für die **nächste Rollenspezifikation** wirklich gebraucht wird. Alles andere bleibt vollständig in [`08-decision-request.md`](08-decision-request.md); der Status jeder Frage steht in [`decision-status.csv`](decision-status.csv).

## Bereits festgelegt

Diese Punkte musst du nicht noch einmal beantworten. Sie stehen schon im Decision Log oder im Regelregister.

- **Mehrere Sieger gleichzeitig:** Die App schlägt alle erfüllten Siege vor, ohne feste Reihenfolge. Du bestätigst einen oder lehnst alle ab. Geprüft wird erst, wenn alle Todesreaktionen abgearbeitet sind. Lebt niemand mehr, gibt es keinen automatischen Sieger. (DR-02, DR-14, Regelregister G-SIEG-1 bis G-SIEG-6)
- **Dorfsieg:** Das Dorf ist Kandidat, sobald keine lebende Person mehr als Wolf zählt. (G-SIEG-1)
- **Wolfssieg:** Die Wölfe sind Kandidat, sobald sie mindestens so viele sind wie alle anderen. Einzelsiegrollen zählen dabei zu „allen anderen“. (G-SIEG-2)
- **Fähigkeiten gehören der Person:** Einsätze und Zustände zählen je Person und Rolle. Wer eine Rolle erbt, beginnt mit frischen Einsätzen; eine Wiederbelebung setzt nichts zurück. (G-ID-3, Lehrling, Waldhexe, Spiegelwolf)
- **Erbe wirkt sofort:** Erbt der Lehrling eine Rolle, gelten deren Fraktion, passive Eigenschaften und Siegbedingung sofort. (Korrekturrunde Regelkern 2)
- **Hinrichtung durch dich:** Eine Hinrichtung per Spielleiterkorrektur ist eine normale Hinrichtung („Lynch“). (Korrekturrunde Regelkern 4)
- **Todesreaktionen mit Entscheidung:** Nach einem Tod am Tag sofort, nach einem Tod in der Nacht in der Morgenauflösung. (G-TOD-4, DR-09)
- **Orakel und Informationen über Rollen:** Besondere Erscheinung zuerst, sonst „Werwolf“ für jeden Wolf, sonst die echte Rolle. (DR-07)
- **Zufall:** Jede Zufallsentscheidung läuft über den gespeicherten Startwert (Seed). (G-RNG-1)
- **Rollenanzahl im Setup:** Es gibt keine feste Rollenkomposition. Eine einzelne Rolle darf eine eigene Obergrenze bekommen; eine allgemeine Grenze ist nicht beschlossen. (Decision Log „Rollenanzahl der Grundrollen“) Meine frühere Empfehlung „jede neue Sonderrolle höchstens einmal“ ziehe ich zurück (Begründung: [`08`](08-decision-request.md) RM-DR-016).
- **Keine digitalen Stimmen, keine Stimmgewichte.** (`implementation-boundary.md` D)
- **Nächste Einheit (3. Oktober 2026):** Siegreicher Wolf, Doppelspion und Selbstmörder, spezifiziert als K1a und K1b. (RM-DR-017 = C)
- **Siegreicher Wolf:** zählt nur in der Wolfsparität als zwei Wölfe und nur, solange er lebt.
- **Doppelspion:** muss leben, um zu gewinnen (RM-DR-155.1). Lebt er, wenn kein Wolf mehr lebt, schlägt die App nur ihn vor, nicht das Dorf; du kannst ablehnen und selbst einen Sieger erklären; andere Siege wie der Manipulator kommen weiter gleichzeitig (RM-DR-155.3). Beim Aufwachen mit den Wölfen nennst du keine Rolle (RM-DR-155.4).
- **Selbstmörder:** mindestens 5 andere Tote, er selbst zählt nicht (RM-DR-138.1); es zählt nur, wer im Moment der Prüfung tot ist (RM-DR-138.3); ein abgelehnter Sieg verfällt nicht und wird wieder vorgeschlagen, wenn er bei einer späteren Prüfung erneut erfüllt ist (RM-DR-138.4). Er gewinnt nur, wenn im Moment seiner Hinrichtung schon 5 andere tot sind; wer danach stirbt, zählt nicht (RM-DR-138.6). Eine Wiederbelebung lässt die frühere Hinrichtung verfallen (RM-DR-138.7).
- **Doppelspion bei der Opferwahl:** darf mitzeigen, seine Wahl zählt nicht; du trägst nur die Wahl der echten Wölfe ein (RM-DR-155.6). Die Ausnahme beim Dorfsieg ist bestätigt (RM-DR-155.3).

## Tatsächlich als Nächstes zu entscheiden

Für K1 ist keine Frage mehr offen. K1a (Siegreicher Wolf, Doppelspion) und K1b (Selbstmörder): **bereit zur Umsetzung, wartet auf Grimmhain-1** (Abstimmung über Katalog, UI-Tests und Übersetzungen, [`06`](06-implementation-batches.md) §3.7). Die nächste Fragerunde entsteht erst mit der nächsten Rolleneinheit.

<!-- check:next-round -->

## Später zu entscheiden

Diese Fragen bleiben offen und werden erst gebraucht, wenn die genannte Rolle an der Reihe ist. Die vollständige Liste mit Status steht in [`decision-status.csv`](decision-status.csv).

| Wann | Fragen |
|---|---|
| Informationsrollen (Charge K2, z. B. Waldläufer, Doktor) | RM-DR-002.3, RM-DR-014, RM-DR-145, RM-DR-147 |
| Sitznachbarn (K3, z. B. Ritter, Wahnsinniger Kutscher) | RM-DR-003, RM-DR-004, RM-DR-116, RM-DR-136; vorher Gerätecheck „links am Tisch“ (RM-DR-146.1, RM-DR-153.4) |
| Todes- und Hinrichtungsreaktionen (K4) | RM-DR-124, RM-DR-125, RM-DR-130, RM-DR-135 |
| Schutz (K5) | RM-DR-004, RM-DR-005, RM-DR-118, RM-DR-119, RM-DR-148, RM-DR-154 |
| Liebespaar und Bindungen (K6, K10) | RM-DR-011.2, RM-DR-101, RM-DR-110, RM-DR-113, RM-DR-132, RM-DR-137, RM-DR-157 |
| Blockaden (K8) | RM-DR-010, RM-DR-114, RM-DR-123, RM-DR-134 |
| Einzelsiege ohne Siegregel, Stimmen, Totenkarten (K9 bis K15) | RM-DR-006, RM-DR-008, RM-DR-012, RM-DR-013 und die Rollenentscheidungen dieser Chargen |
| Zeitwächter (K16) | RM-DR-150 |

Vier Fragen sind Quellenprüfungen, keine Produktentscheidungen. Zwei brauchen einen Test am Gerät (RM-DR-146.1, RM-DR-153.4). Bei zwei weiteren muss geklärt werden, ob eine Wechselwirkung der alten App gewollt war (RM-DR-103.2, RM-DR-132.3).

## Was als Nächstes passiert

Die Spezifikationen stehen in [`../specs/k1a-siegreicher-wolf-doppelspion/`](../specs/k1a-siegreicher-wolf-doppelspion/rules-register.md) und [`../specs/k1b-selbstmoerder/`](../specs/k1b-selbstmoerder/rules-register.md), ohne offene Punkte. Code gibt es erst nach Abstimmung mit Grimmhain-1, weil jede neue Rolle in deren Rollen-Setup erscheint und dort Tests und Übersetzungen ändert ([`06`](06-implementation-batches.md) §3.7).
