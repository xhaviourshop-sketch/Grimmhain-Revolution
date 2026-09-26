# Testmatrix

## Testebenen

| Ebene | Zweck | Pflichtbeispiele |
|---|---|---|
| Unit | reine Regelbausteine | Priorität, Dauer, Zielvalidierung, RNG |
| Scenario | vollständige Command-Folge | Nacht, Morgen, Nominierung, Lynch, Sieg |
| Property/Replay | Determinismus und Invarianten | gleicher Seed, keine doppelte Personen-ID, Tote handeln nur wenn erlaubt |
| Persistence | Save, Migration, Recovery | atomischer Save, beschädigte Datei, ältere Schemaversion |
| Projection Security | Geheimhaltung | Spieler sieht nur sich; TV sieht keine Rollen/Ziele |
| UI | Touchfluss und Darstellung | 6/12/18/24 Personen, lange Namen, DE/EN |
| Network | Join, Reconnect, Missbrauch | falscher Code, Gerätewechsel, alte Aktion |
| Device | reale Plattform | iPad, Android, Windows, Smart-TV, iPhone-Clients |
| Accessibility | Bedienbarkeit | große Schrift, Reduced Motion, Untertitel, Farbunabhängigkeit |

## Kritische Szenarien

- [ ] Wolfsparität meldet möglichen Wolfssieg, beendet aber nicht ohne Bestätigung.
- [ ] Tod des letzten Wolfs meldet möglichen Dorfsieg.
- [ ] Zwei gleichzeitige Siegbedingungen werden in definierter Reihenfolge präsentiert.
- [ ] Schutz wird erst bei tatsächlicher Auflösung verbraucht.
- [ ] Umlenkung bewahrt ursprüngliche Ursache und Quelle.
- [ ] Kettentod überlebt Save/Load mitten in der Reaktionswarteschlange.
- [ ] Abbruch eines mehrstufigen Prompts hinterlässt keine Teilwirkung.
- [ ] Undo/Redo reproduziert exakt dieselben Events.
- [ ] Spielerwechsel des Sitzplatzes verändert keine Rolle oder Historie.
- [ ] Nominierende und nominierte Person werden getrennt gespeichert.
- [ ] Physisch bestimmtes Ergebnis kann als Lynch/Kill bestätigt und korrigiert werden.
- [ ] Tagprojektion verrät keine geheime Rolle.
- [ ] Smartphone-Reconnect zeigt nur aktuellen Zustand.
- [ ] Öffentlicher Bildschirm enthält keine geheimen Schlüssel im Payload.
- [ ] Flugmodus blockiert keine Kernpartie.
- [ ] App-Neustart führt zum letzten bestätigten Schritt.

## Gerätematrix

| Gerät | Rolle | Status |
|---|---|---|
| vorhandenes iPad, Modell noch erfassen | Hauptgerät | offen |
| Android-Tablet ungefähr 2020 oder schwächer | Leistungsuntergrenze | beschaffen/externer Test |
| Windows-PC | Desktop/Steam-Vorbereitung | vorhanden |
| MacBook | iPad-Build und Test | vorhanden |
| iPhone 14 | Spielerclient | vorhanden |
| iPhone 15 | Spielerclient | vorhanden |
| Smart-TV-Browser | öffentliche Anzeige | vorhanden |

## Releaseblocker

Jeder reproduzierbare Fehler aus diesen Klassen blockiert die nächste Freigabe:

1. Spielstandsverlust oder nicht wiederaufnehmbare Partie.
2. Offenlegung geheimer Rolle, Ziele oder Effekte.
3. Falscher Tod, Schutz, Rollenwechsel oder Gewinner.
4. Nicht rückgängig machbare Spielleiteraktion.
5. Absturz oder unbedienbare Oberfläche im Kernablauf.
