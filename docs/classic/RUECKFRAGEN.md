# Rückfragen Classic

Unklare Stellen des Charakterbogens (`Downloads/Grimmhain/Classic/charakterbogen-classic.pdf`): jeweils die wörtlichste Lesart umgesetzt, Alternative genannt. Zuerst Stellen aus Block 0 und 1, danach je Rollengruppe.

## Allgemein
- **Weißer Wolf, Name:** Der Bogen schreibt „WEIßE WOLF“ (ohne Artikel). In der App heißt die Rolle „Der Weiße Wolf“. Alternative: „Weißer Werwolf“ oder genau „Weiße Wolf“.
- **Selbstmörder, englischer Name:** Der Bogen nennt nur den deutschen Namen. In der App „The Death Seeker“ (wie im Grundspiel gewählt). Alternative: „The Suicide“.
- **Alter, Fähigkeitsverlust:** Der Bogen sagt „verlieren alle aus Gram ihre Fähigkeiten“ ohne Dauer. Umgesetzt (Auftrag Markus 13.10.): dauerhaft für den Rest der Partie, für alle Personen der Dorf-Fraktion; keine Dauerfrage. Die frühere Lesart aus DA-108 Punkt 3 (0 bis 3 Nächte, wie Der Weise) gilt für die Classic-Alte nicht mehr. Alternative: auch Werwölfe und Einzelgänger verlieren ihre Fähigkeiten (der Bogen sagt „alle“).
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
Nachgelesen am 13.10.2026 im Bogen (300 dpi): Wortlaut „Jede zweite Nacht erwacht er ein zusätzliches Mal, um sein Unwesen zu treiben.“ Der Bogen nennt dort KEIN Ziel und sagt nicht, dass er einen anderen Werwolf tötet; der Satz „Selbst andere Werwölfe stehen ihm dabei im Weg“ beschreibt sein Ziel, als Einziger übrig zu bleiben, nicht die Zielwahl des Zusatzschritts. Deshalb bleibt die Lesart „jede andere lebende Person“.
Alternative: Nur ein anderer Werwolf darf sein Ziel sein. Nur umzusetzen, wenn Markus das so festlegt; Umbau ist klein (`lone_any` in `RoleCatalog.CLASSIC_ROLES` auf false setzen).

## Weißer Wolf, Sieg
Bogen: „Sein fester Wille ist es, als einziger am Ende übrig zu bleiben. Selbst andere Werwölfe stehen ihm dabei im Weg.“ Umgesetzt (Auftrag Markus 13.10.): Er spielt allein und gewinnt nur als Einziger Überlebender. Solange er lebt, gewinnt das Rudel nie (keine Wolfsparität) und das Dorf erst, wenn er tot ist. Leben nur er und weitere Werwölfe, geht das Spiel weiter, bis er sie getötet hat.
Alternative: Beim Wolfssieg des Rudels gewinnt er mit (frühere Lesart bis 13.10.); oder der Sieg gilt schon, wenn nur er und Dorfbewohner leben.

## Bildzeichen
Erwartet: `godot/assets/night/role-circle/classic-urwolf.webp` und `classic-weisser-wolf.webp` (laut Koordinator bereits in classic-akt). Ohne Datei zeigt die Nachtleiste kein Zeichen.

## Nachtrag 13.10.2026: vier Rollen nach Wortlaut des Bogens
- **Alte:** siehe „Alter, Fähigkeitsverlust“ oben. Ruht bereits ein Fluch, gibt es keinen zweiten; der Fluch der Classic-Alten hat keine Dauer und wird nie verlängert oder beendet.
- **Weißer Wolf:** siehe „Weißer Wolf, Sieg“. Das Ziel seines Zusatzschritts bleibt „jede andere lebende Person“, weil der Bogen nur „sein Unwesen treiben“ sagt.
- **Seherin:** Sie erfährt die tatsächliche Rolle (Rollen-ID der Person), auch bei Urwolf und Weißem Wolf. Das verwandelte Wilde Kind zeigt sie als „Das wilde Kind“ (die Rolle bleibt, nur die Fraktion wechselt). Alternative: als „Werwolf“, weil es nun zu den Wölfen zählt.
- **Jäger:** Der Schuss ist freiwillig. Der Bogen sagt „kann“; das Grundspiel (Sensenträger) bleibt bei Pflicht, nur Classic hat den Verzicht (Parameter `optional_shot`). Der Verzicht erscheint auf der Schusskarte als Knopf „Kein Schuss“.

## Nachtauftrag 14.10.2026 (Annahmen, Markus schlief)
- **Bestätigung bei jeder Aktion (Block 1):** Die Zusammenfassung nennt nur Namen, keine Sitzplatznummern ("Der Engel · schützt: Anna"), weil die Dauerregel "nie Sitzplatznummern zeigen" vorgeht. Sie gilt für alle Antworten der Nacht (Ziele, Ja/Nein, Optionen, Verzicht, Vorhersage) und die Tag-Aktionen Anklage, Hinrichtung, "Keine Hinrichtung", Nekromant-Benennung und Kartenmeldung. Reine Kenntnisnahmen ("Weiter", "Karte zeigen", Hinweiskarten) fragen nicht. Nach "Bestätigen" sperrt die Karte 0,6 Sekunden. "Zurück" verwirft die Auswahl. Alternative: auch die Kenntnisnahmen bestätigen lassen.
- **Hexe zeigt das Rollenbild (Block 2):** Vor der Entscheidung zeigt "Karte zeigen" die Rolle des Rudelopfers als Karte ohne Namen; nach "Heiltrank" erscheint dieselbe Karte mit dem Namen groß darunter. Das ersetzt für Classic `witch_reveal: false` (Hexe erfuhr die Rolle nach der Rettung nicht), der Parameter ist nicht mehr gesetzt. Die Classic-Kartenbilder (19 je Sprache, aus `Grimmhain-Karten-Werkstatt/out/app`) sind auf 512 px Breite verkleinert, Status "intern freigegeben" im Register (Urheber ungeklärt, Veröffentlichung gesperrt). Fehlt ein Bild, steht der Rollenname als Text. Die Seherin zeigt dadurch in Classic ebenfalls die Karte statt des Kreisbilds.
- **Flötenspieler (Block 3):** Abweichung vom Bogen ("verzaubert in jeder Nacht zwei Spieler"): Zuerst "Eine Person" oder "Zwei Personen", dann genau so viele Ziele; bei nur einer Verzauberbaren entfällt die Frage. Gilt auch für den Rattenfänger des Grundspiels. Die Siegbedingung bleibt (alle anderen Lebenden verzaubert). Die Anzahl ist reiner Bedienzustand, gespeichert wird nur die Antwort.
- **Amor, Liebe oder Hass (Block 4):** Abweichung vom Bogen (nur Liebe): Amor wählt zuerst "Liebe" oder "Hass", dann die zwei Personen. Hass bindet "Feinde" mit der Mechanik der Rivalen (keiner gewinnt, solange der andere lebt). Schalter `amor_hate_option` in `RoleCatalog.CLASSIC_ROLES` (Standard an; false = nur Liebende, keine Frage). Die Nachtleiste zeigt nur den Rollennamen; die Wahl nennen Karte, Hilfe, Lexikon und Hinweiskarten.
- **Morgenmeldung gruppiert (Block 5):** Gleiche Wirkungen auf mehrere Personen sind eine Zeile ("Anna, Ben sind verzaubert") für Verzauberte, Geschützte, Vergiftete (Giftwolf), Tetanus, Angesteckte und die roten Hinweise "geschützt" und "verflucht". Einzelne bleiben in der Einzahl. Liebende und Feinde sind ohnehin ein Paar pro Zeile. Zeilen mit Rolle, Ursache oder Grund bleiben einzeln.
- **Weißer Wolf (Block 6):** Alle Werwölfe unter den Zielen (auch der Urwolf) tragen den Feuerring, dazu die Zeile "Werwölfe tragen den Feuerring." Das Ziel bleibt jede andere lebende Person. Häufigkeit: Der Bogen sagt wörtlich "Jede zweite Nacht erwacht er ein zusätzliches Mal", das sind die Nächte 2, 4, 6 (`every: 2`). "Jede dritte Nacht" gilt nur für den Rachsüchtigen Wolf des Grundspiels; daher bleibt es bei jeder zweiten.
- **Dorfbewohner-Bild (Block 7), NICHT geändert, nicht eindeutig.** Gesucht: zwei Kapuzenfiguren vor einer Steinmauer, kleines Format. Kein Bild mit "Dorfbewohner" im Namen passt (Dorfbewohner-Kreisbild und -Rollenbild zeigen einen einzelnen Mann mit Fackel, das Classic-Kreisbild ein Piktogramm). Kandidaten:
  1. `godot/assets/night/role-circle/die-gebundenen.webp` (128 px, zwei Gestalten mit Tuch und Kapuze in einer Gasse): Rollenwahl, Lexikon, Rollenvorschau der "Gebundenen".
  2. `godot/assets/night/role-circle/nachtwaechter.webp` (128 px, Gestalt mit Kapuze vor Mauer und Wolf): dieselben Stellen für den Nachtwächter.
  3. `godot/assets/night/role-circle/dorfbewohner.webp` und `godot/assets/night/role-art/dorfbewohner.webp` (128 und 512 px, ein Mann mit Fackel vor Fachwerkhaus): Rolle "Dorfbewohner".
  4. `godot/assets/night/role-circle/classic-dorfbewohner.webp` (128 px, Piktogramm aus dem Bogen): Classic-Dorfbewohner in Listen und als Ersatz, wenn keine Karte vorliegt (jetzt gibt es eine Karte).
  Frage an Markus: In welchem Bildschirm genau sieht er das Bild (Rollenwahl, Nachtleiste, Lexikon, Karte)? Dann ist es mit einem Satz entfernt (nur die Anzeige, keine Datei).

## Ritter, neu festgelegt (Markus, 14.10.2026)
Die Tetanus-Lesart oben ist ersetzt: Stirbt der Ritter nachts durch die Werwölfe, wählt die Spielleitung am Morgen nach der Todesmeldung Links oder Rechts, der nächste lebende Wolf in dieser Richtung stirbt sofort (siehe FAEHIGKEITEN.md, Nr. 14). Offen geblieben: Bei nur einem lebenden Wolf entfällt die Frage und er stirbt (gewählt statt zwei gleicher Knöpfe).

## Überlange Listen scrollen (Markus, 14.10.2026, Block F)
Abweichung von der Dauerregel "nie scrollen müssen": Die Seiten bleiben so geschnitten, dass sie normalerweise passen und blättern ("Davor/Danach"). Ist eine Seite trotzdem höher als der Platz (Handy hochkant, lange Namen), scrollt sie, statt unten abgeschnitten zu enden. Die Tests des Regelbuchs prüfen deshalb "Ende erreichbar" statt "kein Scrollbereich".

## Dorfbewohner-Bilder abgeschaltet (14.10.2026, Auftrag Markus)

Die Anzeige ist abgeschaltet, keine Datei ist gelöscht. Rückfall ist reiner Text. Amor, Hexe, Seherin und alle anderen Rollensymbole bleiben.

Abgeschaltet:
- **Menschengruppen im Dorfleben** (Kapuzenfiguren im Kreis auf dem Pflaster, Tagbild des Dorfes): `godot/app/widgets/village/village_life.gd`, Konstante `SHOW_FOLK := false`. Das Bild `godot/assets/village/crowd.webp` bleibt liegen. Galgen und Fledermaus-/Krähenschwarm laufen weiter. Gefunden als wahrscheinlicher Ursprung deines Screenshots, ich habe das Bild gegen die Datei abgeglichen.
- **Rollenbild auf der Aktionskarte** (Medaillon), **kleines Symbol in der Nachtleiste**, **Symbol auf der Karte (Kopfzeile)**, **Symbol in der Rollenkachel der Vorbereitung und im Rollenmedaillon**, **Symbol in der Rollenvorschau**: alles für `dorfbewohner` und `classic-dorfbewohner`, zentral in `godot/app/widgets/night/night_art.gd` (`IMAGELESS_ROLES`; `role_art`, `role_symbol`, `has_emblem` liefern nichts). Betroffene Bilddateien (bleiben liegen): `godot/assets/night/role-art/dorfbewohner.webp`, `godot/assets/night/role-circle/classic-dorfbewohner.webp`, `godot/assets/night/role-circle/dorfbewohner.webp`, `godot/assets/night/emblems/dorfbewohner.png`.

Unklar, nicht abgeschaltet (bitte entscheiden):
- **Gemalte Rollenkarten** `godot/assets/cards/de|en/dorfbewohner.webp` und `classic_dorfbewohner.webp` (deine Kartenbilder, mit Text im Bild). Sie erscheinen bei „Karte zeigen“ und in der Kartenansicht (`RoleCardImage`, `cockpit_layers.gd`). Ohne sie hätte die Person keine Karte zum Vorzeigen. Alternative: für den Dorfbewohner einen reinen Textkasten statt der Karte zeigen. Kartenbilder werden nie verändert.
- **Teamsymbol „Dorf“** (`godot/assets/night/team/team-village.png`, `godot/assets/ui/team_tile_village.webp`): zeigt die Fraktion, nicht die Rolle. Unverändert.
- **Rollenbilder anderer Dorf-Rollen** (z. B. Mädchen, Bärenführer, Drei Brüder) sind eigene Rollen und bleiben.
