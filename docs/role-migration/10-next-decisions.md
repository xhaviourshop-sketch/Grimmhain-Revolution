# 10 · Nächste Entscheidungen

**Stand:** 2026-09-27 · geprüft gegen `origin/main` `5eb5f2a` · Vorlage für den Product Owner

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

## Tatsächlich als Nächstes zu entscheiden

Vier Fragen. Jede Frage steht für sich; bitte jede einzeln beantworten.

<!-- check:next-round RM-DR-017 RM-DR-155.1 RM-DR-155.3 RM-DR-155.4 -->

### RM-DR-017 · Welche Rollen sollen als Nächstes spezifiziert werden?

- **Hintergrund:** Die Auswahl von 20, 25 oder 30 Rollen für Version 1.0 ist nicht freigegeben. Für den nächsten Schritt reicht die Entscheidung über eine kleine Einheit.
- **Beispiel:** Mit A kann eine Runde danach einen Siegreichen Wolf und einen Doppelspion enthalten; mit B nur den Siegreichen Wolf.
- **A:** Siegreicher Wolf und Doppelspion.
- **B:** nur Siegreicher Wolf.
- **C:** Siegreicher Wolf, Doppelspion und Selbstmörder.
- **Empfehlung: A.** Beide Rollen ändern nur die Siegprüfung und haben keinen Nachtschritt. Der Siegreiche Wolf braucht keine weitere Antwort, der Doppelspion nur die drei Fragen unten. Der Selbstmörder bringt eine neue Art von Sieg, die vom Moment der Hinrichtung abhängt, und braucht drei eigene Antworten. Er passt besser in einen eigenen, späteren Schritt.
- **Ohne Antwort blockiert:** jede weitere Rollenspezifikation. Bei B entfallen die drei Doppelspion-Fragen. Bei C kommen RM-DR-138.1, .3 und .4 hinzu (unten unter „Später“).

### RM-DR-155.1 · Muss der Doppelspion leben, um zu gewinnen?

- **Beispiel:** Ben ist Doppelspion und wird in Nacht 2 gefressen. Am Tag 3 wird Anna hingerichtet, die letzte Werwölfin. Clara und David (Dorf) leben.
- **A:** Ja. Ben ist tot, also gewinnt das Dorf.
- **B:** Nein. Ben gewinnt auch tot, weil alle Werwölfe tot sind.
- **Empfehlung: A.** So verhält sich die bisherige App. Die gleiche Bedingung gilt beim Manipulator („er lebt“, DR-12). Der Rollentext lässt die Frage offen.
- **Ohne Antwort blockiert:** Spezifikation des Doppelspions.

### RM-DR-155.3 · Wird das Dorf zusätzlich als Sieger vorgeschlagen, wenn der Doppelspion gewinnt?

- **Beispiel:** Anna, die letzte Werwölfin, wird hingerichtet. Ben (Doppelspion), Clara und David (Dorf) leben.
- **Schon klar ist:** Bestätigst du Bens Sieg, gewinnt nur Ben. Offen ist nur, was die App dir in diesem Moment **anbietet**.
- **A:** Die App schlägt nur „Ben gewinnt allein“ vor. „Dorf gewinnt“ erscheint nicht. Du kannst trotzdem ablehnen und selbst einen Sieger erklären.
- **B:** Die App schlägt „Dorf gewinnt“ und „Ben gewinnt“ vor. Du wählst nach dem Rollentext.
- **C:** Wie B, die App markiert „Ben gewinnt“ als die laut Rollentext zutreffende Wahl.
- **Empfehlung: A.** Der Rollentext „gewinnt alleine, wenn alle Werwölfe tot sind“ beschreibt genau diesen Moment. Mit B müsstest du jedes Mal richtig wählen, und ein Fehlgriff wäre ein falscher Sieger. A ist eine bewusste Ausnahme von der allgemeinen Regel „alle erfüllten Siege werden vorgeschlagen“ und gilt nur für das Dorf. Andere Siege, etwa der Manipulator bei drei Lebenden, werden weiter gleichzeitig vorgeschlagen.
- **Ohne Antwort blockiert:** Spezifikation des Doppelspions.

### RM-DR-155.4 · Was erfahren die Werwölfe über den Doppelspion, wenn er mit ihnen aufwacht?

- **Beispiel:** Nacht 1. Du weckst die Werwölfe Anna und Emil. Ben (Doppelspion) wacht mit auf.
- **A:** Du nennst keine Rolle. Anna und Emil sehen Ben und halten ihn vielleicht für einen Wolf.
- **B:** Du sagst Anna und Emil: „Ben ist der Doppelspion.“
- **C:** Nur Ben öffnet die Augen und sieht die Wölfe; Anna und Emil sehen ihn nicht.
- **Empfehlung: A.** So wird er zu einem echten Spion. B macht ihn für die Wölfe sofort zum Ziel. C passt nicht zu „wacht gemeinsam mit den Werwölfen auf“. Die Empfehlung ist unsicher, weil weder Rollentext noch alte App das regeln.
- **Ohne Antwort blockiert:** Regeltext und Ansage des Doppelspions. An der Siegprüfung ändert die Antwort nichts.

**Zur Kenntnis, keine Frage:** Für den **Siegreichen Wolf** gilt ohne weitere Entscheidung: Er zählt nur in der Wolfsparität als zwei Wölfe, solange er lebt.
- *Beispiel:* Emil (Siegreicher Wolf), Clara und David leben. Wölfe 2, andere 2, also sind die Wölfe Siegkandidat.
- Auf „kein Wolf lebt mehr“ und auf Siegbedingungen, die Personen zählen (Manipulator: genau drei Lebende), hat er keinen Einfluss. Er zählt nur, solange er lebt.
- Der Lehrling, der ihn erbt, zählt sofort doppelt. Das Orakel sieht ihn als „Werwolf“.
- Wenn du das anders willst, sag es bitte.

## Später zu entscheiden

Diese Fragen bleiben offen und werden erst gebraucht, wenn die genannte Rolle an der Reihe ist. Die vollständige Liste mit Status steht in [`decision-status.csv`](decision-status.csv).

| Wann | Fragen |
|---|---|
| **Selbstmörder** (sofort, falls RM-DR-017 = C; sonst im folgenden Schritt) | **RM-DR-138.1** Zählen die 5 Toten vor seiner Hinrichtung oder einschließlich ihm? · **RM-DR-138.3** Zählen nur Personen, die gerade tot sind, oder alle Todesfälle, auch wenn jemand wiederbelebt wurde? · **RM-DR-138.4** Verfällt ein abgelehnter Selbstmörder-Sieg endgültig? Details und Empfehlungen in [`08`](08-decision-request.md) RM-DR-138. |
| Informationsrollen (Charge K2, z. B. Waldläufer, Doktor) | RM-DR-002.3, RM-DR-014, RM-DR-145, RM-DR-147 |
| Sitznachbarn (K3, z. B. Ritter, Wahnsinniger Kutscher) | RM-DR-003, RM-DR-004, RM-DR-116, RM-DR-136; vorher Gerätecheck „links am Tisch“ (RM-DR-146.1, RM-DR-153.4) |
| Todes- und Hinrichtungsreaktionen (K4) | RM-DR-124, RM-DR-125, RM-DR-130, RM-DR-135 |
| Schutz (K5) | RM-DR-004, RM-DR-005, RM-DR-118, RM-DR-119, RM-DR-148, RM-DR-154 |
| Liebespaar und Bindungen (K6, K10) | RM-DR-011.2, RM-DR-101, RM-DR-110, RM-DR-113, RM-DR-132, RM-DR-137, RM-DR-157 |
| Blockaden (K8) | RM-DR-010, RM-DR-114, RM-DR-123, RM-DR-134 |
| Einzelsiege ohne Siegregel, Stimmen, Totenkarten (K9 bis K15) | RM-DR-006, RM-DR-008, RM-DR-012, RM-DR-013 und die Rollenentscheidungen dieser Chargen |
| Zeitwächter (K16) | RM-DR-150 |

Vier Fragen sind Quellenprüfungen, keine Produktentscheidungen. Zwei brauchen einen Test am Gerät (RM-DR-146.1, RM-DR-153.4). Bei zwei weiteren muss geklärt werden, ob eine Wechselwirkung der alten App gewollt war (RM-DR-103.2, RM-DR-132.3).

## Was nach deinen Antworten passiert

Grimmhain-2 schreibt die Spezifikation der gewählten Einheit (Regeltext DE/EN, Akzeptanzszenarien, Umsetzungsgrenze) nach dem Muster von `docs/specs/vertical-slice/`. Code gibt es erst danach. Vorher ist eine Abstimmung mit Grimmhain-1 nötig, weil jede neue Rolle in deren Rollen-Setup erscheint ([`06`](06-implementation-batches.md) §3.7).
