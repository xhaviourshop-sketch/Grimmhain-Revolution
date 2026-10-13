# Rückfragen Classic

Unklare Stellen des Charakterbogens (`Downloads/Grimmhain/Classic/charakterbogen-classic.pdf`): jeweils die wörtlichste Lesart umgesetzt, Alternative genannt. Zuerst Stellen aus Block 0 und 1, danach je Rollengruppe.

## Allgemein
- **Weißer Wolf, Name:** Der Bogen schreibt „WEIßE WOLF“ (ohne Artikel). In der App heißt die Rolle „Der Weiße Wolf“. Alternative: „Weißer Werwolf“ oder genau „Weiße Wolf“.
- **Selbstmörder, englischer Name:** Der Bogen nennt nur den deutschen Namen. In der App „The Death Seeker“ (wie im Grundspiel gewählt). Alternative: „The Suicide“.
- **Alter, Fähigkeitsverlust:** Der Bogen sagt, nach seinem Lynch verlieren alle aus Gram ihre Fähigkeiten, ohne Dauer. Umgesetzt ist die Entscheidung DA-108 Punkt 3 (wie Der Weise, 0 bis 3 Nächte und Tage). Wörtlichste Lesart wäre „dauerhaft“.
- **Nachtreihenfolge:** Der Bogen nennt keine Zahlen. Bestehende Classic-Rollen übernehmen die Reihenfolge ihrer Mechanik, neue Rollen eine begründete Nummer (siehe je Gruppe).
- **Amor:** Der Bogen kennt nur Liebende; es gibt keine Auswahl der Art, die Person darf sich selbst wählen („evtl. auch sich selbst“).
- **Hauptmann:** bewusst nicht gebaut (Phase 2).

## Rückfragen Gruppe A (Selbstmörder, wildes Kind, Ritter)

## Selbstmörder, „Nachdem 5 Spieler das Totenreich betreten haben“, gewählte Lesart, Alternative
Gewählt: Mindestens fünf Personen sind vor seiner Hinrichtung tot (er selbst zählt nicht mit), Wiederbelebte zählen nicht. Das entspricht RM-DR-138 und der Mechanik `selbstmoerder`. Alternative: Der Selbstmörder zählt als fünfter Toter mit, oder die fünf Toten müssen zusammen im Totenreich bleiben.

## Selbstmörder, „am Tage von seinem Dorf erhängt“, gewählte Lesart, Alternative
Gewählt: Jede Hinrichtung am Tag zählt, auch per Spielleiterkorrektur. Alternative: nur eine Abstimmung des Dorfes.

## Wildes Kind, „wählt sich am Anfang einer Partie“, gewählte Lesart, Alternative
Gewählt: Wahl nur in Nacht 1, Pflicht. Kommt das Kind erst später ins Spiel (Rollenwechsel), bleibt die Wahl der Spielleitung per Korrektur. Alternative: Wahl in der ersten Nacht, in der es die Rolle hat.

## Wildes Kind, „wird das wilde Kind zum Werwolf“, gewählte Lesart, Alternative
Gewählt: Rolle bleibt „Das wilde Kind“, Fraktion Werwölfe, erscheint als Classic-Werwolf, wacht ab der folgenden Nacht mit dem Rudel auf. Alternative: Die Rolle wechselt ganz zu „Der Werwolf“ (Wolfskind-Datensatz entfällt).

## Ritter, „Werwolf zu seiner Linken“, gewählte Lesart, Alternative
Gewählt: Der nächste lebende Werwolf im Uhrzeigersinn ab dem Platz des Ritters (tote Plätze übersprungen). Alternative: gegen den Uhrzeigersinn, oder nur der unmittelbare Sitznachbar (ohne Treffer, wenn dieser kein Werwolf ist).

## Ritter, „wenn er von ihnen in der Nacht gefressen wird“, gewählte Lesart, Alternative
Gewählt: Nur ein Tod durch den Rudelangriff löst aus. Wird er von der Hexe gerettet oder vom Engel geschützt, stirbt er nicht und infiziert nicht. Alternative: Auch Gift oder Hinrichtung infizieren.

## Ritter, „stirbt dann in der folgenden Nacht“, gewählte Lesart, Alternative
Gewählt: Der Tod tritt in der Morgenauflösung der nächsten Nacht ein, nach den Rudelopfern, unaufhaltbar (kein Schutz), Ursache „Tetanus“ ohne öffentliche Nennung von Ursache oder Rolle. Alternative: Der Tod tritt zu Beginn der nächsten Nacht ein, vor dem Rudelschritt. Eine Heilung durch die Hexe oder Rettung ist nicht vorgesehen.

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

## Rückfragen Classic Gruppe C (Urwolf, Weißer Wolf)

Format: Rolle, Bogenstelle, gewählte Lesart, Alternative. Gewählt ist jeweils die wörtlichste Lesart; nichts davon ist Nutzerfreigabe.

## Urwolf, „statt zu fressen in einen Werwolf verwandeln“
Gewählt: Die Verwandlung ersetzt das Fressen. Das Rudelopfer stirbt nicht und wird auch dann Werwolf, wenn Engel oder Hexe es schützen würden, denn es wird nichts angegriffen. Der Hexentrank wird nicht verbraucht, die Hexe sieht kein Opfer.
Alternative: Schutz oder Heilung verhindern die Verwandlung nicht (gewählt), oder ein geschütztes Opfer bleibt unverwandelt.

## Urwolf, Nachtreihenfolge
Gewählt: Der Schritt steht direkt hinter dem Rudelschritt (Nummer 20, gleiche Stelle), ohne eigenen Tarnaufruf. Dadurch sieht die Hexe das Opfer nicht mehr, wenn verwandelt wurde.
Alternative: Eigene Nummer nach der Hexe; dann könnte die Hexe das Opfer noch retten und die Verwandlung wäre danach wirkungslos.

## Urwolf, „einmalig“ und Ziele
Gewählt: Einmal im Spiel je Urwolf. Nur ein Opfer, das kein Werwolf ist, kann verwandelt werden (sonst entfällt der Schritt, die Fähigkeit bleibt). Der Verwandelte wird ein Classic-Werwolf ohne eigene Fähigkeit und wacht erst ab der nächsten Nacht mit dem Rudel.
Alternative: Verwandlung wird auch bei einem Werwolf als Opfer verbraucht.

## Urwolf, „geheimes Zeichen“
Gewählt: Das Zeichen ist nur die Antwort „Verwandeln“ des Spielleiters in der App; ob der Verwandelte geweckt wird, entscheidet die Spielleitung am Tisch (Hinweis im Lexikon).
Alternative: Die App fordert das Aufwecken des Opfers als eigenen Schritt.

## Weißer Wolf, Name
Bogentitel „WEIßE WOLF“. In der App „Der Weiße Wolf“, Rollen-ID `classic-weisser-wolf`.
Alternative: Titel genau wie auf dem Bogen schreiben.

## Weißer Wolf, „sein Unwesen treiben“
Gewählt: Jede zweite Nacht (2, 4, 6 …) erwacht er nach dem Rudel allein und darf eine beliebige andere lebende Person töten, mit Verzicht. Tod am Morgen, der Engel wirkt nicht (kein Rudelangriff), wie beim Rachsüchtigen Wolf.
Alternative: Nur ein anderer Werwolf darf sein Ziel sein („Selbst andere Werwölfe stehen ihm im Weg“).

## Weißer Wolf, Sieg
Gewählt: Einzelsieg nur, wenn er die einzige lebende Person ist. Er ist der einzige Wolf, aber andere leben: Es gewinnt niemand, das Spiel geht weiter. Leben außer ihm weitere Werwölfe, bleibt der Wolfssieg des Rudels (Grundverhalten, er zählt als Wolf).
Alternative: Beim Wolfssieg des Rudels gewinnt er nicht mit; oder der Sieg gilt schon, wenn nur er und Dorfbewohner leben.

## Bildzeichen
Erwartet: `godot/assets/night/role-circle/classic-urwolf.webp` und `classic-weisser-wolf.webp` (laut Koordinator bereits in classic-akt). Ohne Datei zeigt die Nachtleiste kein Zeichen.
