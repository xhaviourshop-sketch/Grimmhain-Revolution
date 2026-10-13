# Classic Gruppe B: Rückfragen

Format: Rolle, Bogenstelle, gewählte Lesart, Alternative. Erwartete Kreisbilder: `godot/assets/night/role-circle/classic-fuchs.webp`, `classic-floetenspieler.webp`, `classic-baerenfuehrer.webp` (liegen in classic-akt).

## Fuchs, „einen Spieler aus … ob dieser oder einer seiner beiden Nachbarn ein Werwolf ist“
Gewählte Lesart: Er darf auch sich selbst wählen. Nachbarn sind die beiden nächsten lebenden Sitzplätze. „Werwolf“ heißt: zählt als Wolf (`counts_as_wolf`), nicht Einzelgänger. Technisch Mechanik des Spürhunds (Nachtnummer 68), aber eigene Classic-Regel (`fox`).
Alternative: Sich selbst nicht wählbar; oder auch Einzelgänger als Treffer zählen wie beim Spürhund.

## Fuchs, „verliert er seine Fähigkeit“
Gewählte Lesart: Bei Nein verliert er sie, wird aber weiter aufgerufen (Tarnaufruf), wie beim Spürhund; Wiederbelebung stellt sie wieder her.
Alternative: Nach dem Verlust nicht mehr aufrufen.

## Flötenspieler, „verzaubert in jeder Nacht zwei Spieler“
Gewählte Lesart: Mechanik des Rattenfängers (Nachtnummer 42) mit Parameter `pipe_two`: genau zwei noch Unverzauberte pro Nacht, bleibt nur eine übrig, genau diese. Sich selbst nicht. Sieg, sobald alle anderen Lebenden verzaubert sind (wörtlich „alle Spieler“, er selbst zählt nicht mit).
Alternative: 1 oder 2 wie beim Rattenfänger.

## Flötenspieler, Schritt „Alle Verzauberten“
Gewählte Lesart: Der Bogen kennt keinen Schritt, bei dem sich die Verzauberten erkennen. Er entfällt (`piper_all: false`). Die neu Verzauberten erfahren es weiter durch den privaten Hinweis (Karte).
Alternative: Alle Verzauberten wachen gemeinsam auf wie im Grundspiel.

## Bärenführer, „am Morgen unmittelbar neben einem Werwolf“
Gewählte Lesart (DA-108 Punkt 4): Jeden Morgen, nach Beginn des Tages, solange er lebt und seine Fähigkeit nicht ruht. Nachbar = nächster lebender Sitzplatz links oder rechts, „Werwolf“ = zählt als Wolf. Öffentlich nur der Hinweis „Der Spielleiter knurrt.“, Bärenführer und Wolf nur im Spielleiter-Ereignis. Kein Nachtschritt.
Alternative: Tote Plätze nicht überspringen (nur direkt benachbarte Plätze).

## Empfehlung und Reihenfolge
Fuchs und Bärenführer kommen in der Besetzungsempfehlung nach den Gruppen dazu, nur solange mindestens ein einfacher Dorfbewohner bleibt. Der Flötenspieler wird nie empfohlen. Nachtreihenfolge übernommen von der Mechanik (Fuchs 68, Flötenspieler 42).

## Hilfe zum Hinweis „Verzaubert“
Der Lexikonverweis des privaten Hinweises zeigt noch den Eintrag der Rattenfänger-Mechanik. Bei Bedarf auf den Eintrag des Flötenspielers umstellen.
