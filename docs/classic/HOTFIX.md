# Hotfix: Bedienung tot, Musik läuft weiter

Stand: 14.10.2026. Branch `hotfix-freeze` (von `main`, ein Commit `24b58f5`, nicht deployt, nicht gemerged). Dieselbe Korrektur liegt auf `classic-akt` (Commit `5c4e0cb`).

## Was passierte
Nachts fliegt ab und zu ein kleiner Fledermausschwarm über das Dorf. Ein Zeitgeber startet ihn zwischen 30 und 90 Sekunden nach Beginn der Nacht. Der Schwarm braucht dafür Bauteile, die bisher erst beim ersten Tagesbild entstanden. Wer eine Partie neu startet oder nachts fortsetzt, hat noch kein Tagesbild gesehen: Der Zeitgeber greift ins Leere, die Hauptschleife der Web-Seite bricht ab (Konsole: `RuntimeError: null function`). Danach reagiert nichts mehr, die Musik spielt aber weiter. Mit F5 geht es weiter, der Spielstand bleibt.

Das Hängen "nach der Zielwahl" bei Engel, Hexe und Seherin war Zufall: Das sind die Schritte, in denen die Nacht lange genug dauert, damit der Zeitgeber auslöst. Die Rollen selbst sind nicht schuld.

## Betrifft die Produktion?
Ja. `main` und Build `da31507` haben denselben Code. Die Korrektur ist eine Zeile (`_build()` vor dem Start des Schwarms) plus ein Test (`test_village_flock_night`). Deploy ist nicht erfolgt.

## So wurde es gefunden
Im Browser (Chrome, Vorschau) nachgespielt: Abbruch auch ohne jeden Klick, nur durch Warten in der Nacht. Eingegrenzt durch Abschalten von Heulen, Musik und Schwarm: erst ohne Schwarm lief die Nacht über 4 Minuten stabil.

Geprüft nach der Korrektur: Vorschau 3983624 im Chrome, 5 Minuten Nacht ohne Eingriff, keine Fehlermeldung in der Konsole. Vorher brach dieselbe Lage nach 35 bis 85 Sekunden ab. Der Test `test_village_flock_night` schlägt ohne die Korrektur fehl (Zugriff außerhalb des Bereichs) und läuft mit ihr durch.
