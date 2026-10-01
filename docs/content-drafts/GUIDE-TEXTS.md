# Führungstexte DE/EN (Entwurf)

**Status:** Entwurf, nicht freigegeben. Quell-Commit `312f5bbbbec4c218754b35a0043b51e79d80bcf5` (`audit/all-72-roles`). Keine Aufnahme, keine Einbindung. Begriffe siehe [`TERMINOLOGY.md`](TERMINOLOGY.md), offene Punkte siehe [`OPEN-ISSUES.md`](OPEN-ISSUES.md).

## 1. Kategorien und Regeln

Jeder Text trägt genau eine Kategorie:

| Kennzeichen | Bedeutung | Wer sieht oder hört es |
|---|---|---|
| `[SL-PRIVAT]` | Anweisung an den Spielleiter | nur der Spielleiter auf dem Tablet |
| `[PERSON-PRIVAT]` | Information, die ausschließlich die betreffende Person sehen darf | nur diese Person |
| `[ÖFFENTLICH]` | Ansage für alle am Tisch | alle, auch der öffentliche Bildschirm |

Regeln:

1. `[ÖFFENTLICH]` nennt nie eine geheime Rolle, ein geheimes Ziel, eine geheime Wirkung oder eine Todesursache, ausgenommen die angesagten Todeseffekte (Abschnitt 4.1). Erlaubt sind nur Wirkungen, die eine Entscheidung ausdrücklich veröffentlicht (Detektiv, Nachtwächter, Amalia, Schutzgeist ohne Rollennamen, Zeitwächter, Wiederbelebung, Nominierung durch den Korrupten Richter, Ton bei fünf Toten, Todeseffekte; Zusammenstellung in Abschnitt 4) und die allgemeinen Tod-, Tag- und Siegtexte.
2. Ein Aufruf nennt nur den Rollennamen, nie Ergebnis, Ziel oder ob die Rolle lebt (`docs/assets/NARRATOR-SCRIPT.md` §1 Regel 4). Die Aufrufpolitik steht in Abschnitt 3.3 (DI-02).
3. Kartenlänge: höchstens 140 Zeichen je Text und Sprache, höchstens zwei kurze Sätze. Ausnahme: die Kombizeilen der Aufrufe (Aufruf und Einschlafen zusammen).
4. Platzhalter in geschweiften Klammern (`{name}`, `{names}`, `{role}`, `{roles}`, `{count}`, `{direction}`, `{n}`, `{target}`) sind nur für Karten gedacht. Aufgenommene Zeilen enthalten keine Platzhalter (NARRATOR-SCRIPT §1 Regel 3).
5. Anrede: aufgerufene Rolle "du", Rudel "ihr", Tisch "alle". Der Spielleiter wird als "du" angesprochen.
6. Richtung: "links" heißt der nächste Platz im Uhrzeigersinn des App-Sitzkreises. Die Gegenprüfung am Tablet steht aus (OI-06). `{direction}` ist "links", "rechts" oder "auf beiden Seiten gleich weit".
7. Übernommen wurden die Sprechertexte aus `docs/assets/NARRATOR-SCRIPT.md` wörtlich; Ergänzungen sind in der Spalte "Auslöser, Hinweis" benannt.

## 2. Allgemeine Texte

Gilt für Nachtbeginn, Morgen, Diskussion, Nominierung, Hinrichtung und Spielende. Die `narration.*`-Zeilen sind die öffentlichen Ansagen, die `gm.*`-Zeilen die privaten Anweisungen dazu.

| Schlüssel | Kategorie | DE | EN | Auslöser, Hinweis |
|---|---|---|---|---|
| `narration.night.first_begin` | `[ÖFFENTLICH]` | Die erste Nacht senkt sich über Grimmhain. Alle schließen die Augen. | The first night falls over Grimmhain. Everyone, close your eyes. | Nacht 1; übernommen aus NARRATOR-SCRIPT |
| `narration.night.begin` | `[ÖFFENTLICH]` | Die Nacht bricht herein. Alle schließen die Augen. | Night falls. Everyone, close your eyes. | ab Nacht 2, in Runden ohne Wiederbelebung; übernommen |
| `narration.night.begin_revival` | `[ÖFFENTLICH]` | Die Nacht bricht herein. Alle schließen die Augen, auch die Toten. | Night falls. Everyone, close your eyes, the dead included. | Wiederbelebungsrunden (jede Nacht, auch Nacht 1); Antwort des Product Owners vom 29.09.2026; neu |
| `gm.night.begin` | `[SL-PRIVAT]` | Nacht {n}. Ruf die Rollen in der angezeigten Reihenfolge auf. | Night {n}. Call the roles in the order shown. | Nachtbeginn |
| `narration.dawn.begin` | `[ÖFFENTLICH]` | Der Morgen graut über Grimmhain. Alle öffnen die Augen. | Dawn breaks over Grimmhain. Everyone, open your eyes. | Morgen; übernommen |
| `narration.morning.death_single` | `[ÖFFENTLICH]` | Diese Nacht hat ein Leben gefordert. Es ist {name}. | This night has claimed a life. It is {name}. | genau ein Tod; Namensteil ergänzt |
| `narration.morning.death_multiple` | `[ÖFFENTLICH]` | Diese Nacht hat mehrere Leben gefordert. Es sind {names}. | This night has claimed several lives. They are {names}. | mehrere Tode; Namensteil ergänzt |
| `narration.morning.no_death` | `[ÖFFENTLICH]` | In dieser Nacht ist niemand gestorben. | No one died this night. | kein Tod; übernommen |
| `narration.morning.role_reveal` | `[ÖFFENTLICH]` | {name} war {role}. | {name} was {role}. | nur in Runden ohne Wiederbelebung; in Wiederbelebungsrunden nie (Antwort des Product Owners vom 29.09.2026, Decision Log DI-01; ändert die bisherige frei wählbare Setup-Option) |
| `gm.morning.begin` | `[SL-PRIVAT]` | Die Morgenauflösung ist fertig. Lies die Meldungen der Reihe nach vor. | The dawn resolution is done. Read out the announcements in order. | Morgen |
| `narration.day.begin` | `[ÖFFENTLICH]` | Das Dorf versammelt sich. Beratet, wem ihr noch trauen könnt. | The village gathers. Discuss whom you can still trust. | Diskussion; übernommen |
| `gm.day.begin` | `[SL-PRIVAT]` | Starte den Timer. Nominierungen öffnest du selbst. | Start the timer. You open nominations yourself. | Diskussion |
| `narration.day.nominations_open` | `[ÖFFENTLICH]` | Wer einen Verdacht hat, darf jetzt jemanden nominieren. | Anyone with a suspicion may now nominate someone. | Nominierung; übernommen |
| `gm.day.nominations` | `[SL-PRIVAT]` | Halte fest, wer wen nominiert. Jede Person darf pro Tag einmal nominieren und einmal nominiert werden. | Record who nominates whom. Each person may nominate once and be nominated once per day. | Nominierung, DR-03 |
| `narration.day.timer_end` | `[ÖFFENTLICH]` | Die Zeit ist abgelaufen. | Time is up. | Timer 0; übernommen |
| `narration.day.execution` | `[ÖFFENTLICH]` | Das Dorf hat entschieden. Das Urteil wird vollstreckt. Es trifft {name}. | The village has decided. The sentence will be carried out. It falls on {name}. | Hinrichtung; Namensteil ergänzt |
| `narration.day.no_execution` | `[ÖFFENTLICH]` | Heute wird niemand hingerichtet. | No one will be executed today. | ohne Hinrichtung; übernommen |
| `gm.day.execution` | `[SL-PRIVAT]` | Zähl die Stimmen selbst. Bestätige eine Hinrichtung oder ausdrücklich keine. | Count the votes yourself. Confirm one execution or expressly none. | Hinrichtung, G-TAG-1, G-TAG-3 |
| `narration.day.end` | `[ÖFFENTLICH]` | Die Sonne versinkt hinter den Bäumen. | The sun sinks behind the trees. | Tagesende; übernommen |
| `narration.win.village` | `[ÖFFENTLICH]` | Die Werwölfe sind besiegt. Das Dorf hat gewonnen. | The werewolves are defeated. The village has won. | Spielende Dorf; übernommen |
| `narration.win.wolves` | `[ÖFFENTLICH]` | Die Werwölfe haben das Dorf überwältigt. Die Werwölfe haben gewonnen. | The werewolves have overrun the village. The werewolves have won. | Spielende Werwölfe; übernommen |
| `narration.win.solo` | `[ÖFFENTLICH]` | {name} hat als {role} allein gewonnen. | {name} has won alone as {role}. | Spielende Einzelsieg; neu, ersetzt die Einzelzeile für den Manipulator |
| `narration.win.shared` | `[ÖFFENTLICH]` | Mit dem Sieg gewinnen auch {names}. | Along with the win, {names} win too. | Mitsieg (Ewige, Feuerteufel); neu |
| `gm.game.win` | `[SL-PRIVAT]` | Ein Sieg ist erkannt. Bestätige ihn mit einem Tipp oder lehne ihn ab. | A win is detected. Confirm it with a tap or reject it. | Spielende, F-11 |
| `narration.game.end` | `[ÖFFENTLICH]` | Die Partie ist vorbei. Deckt eure Rollen auf. | The game is over. Reveal your roles. | nach dem Sieg; übernommen |
| `narration.setup.role_reveal` | `[PERSON-PRIVAT]` | Deine Rolle: {role}. Zeig sie niemandem. | Your role: {role}. Show it to no one. | Rollenanzeige pro Person; angelehnt an narration.setup.role_reveal |

## 3. Texte je Rolle

Je Rolle eine Zeile in jeder der vier Tabellen. Zeilen in Klammern bedeuten: kein Text, mit Begründung. Die Reihenfolge folgt `godot/core/rules/role_catalog.gd` beim Quell-Commit. Rollenwirkungen stehen in [`rolebook/`](rolebook/).

### 3.1 `[SL-PRIVAT]` Anweisung an den Spielleiter

| Rollen-ID | Rolle | DE | EN |
|---|---|---|---|
| `dorfbewohner` | Dorfbewohner / Villager | Kein Nachtschritt. Nicht aufrufen. | No night step. Do not call. |
| `werwolf` | Werwolf / Werewolf | Weck das Rudel. Es wählt lautlos ein Opfer. Trag es ein oder bestätige den Verzicht. | Wake the pack. It silently chooses a victim. Enter it or confirm that they skip. |
| `schutzengel` | Schutzengel / Guardian Angel | Weck den Schutzengel vor dem Rudel. Er muss eine andere lebende Person wählen. | Wake the Guardian Angel before the pack. They must choose another living person. |
| `waldhexe` | Waldhexe / Witch of the Woods | Nach dem Rudel: Zeig ihr das Opfer. Rettung, Gift und Verzicht bestätigt sie am Ende. | After the pack: show the victim. Rescue, poison and declining are confirmed at the end. |
| `das-orakel` | Das Orakel / The Oracle | Pflichtschritt jede Nacht. Zeig nur das gezeigte Ergebnis. Übersteuern braucht Grund. | Mandatory step every night. Show only the shown result. Overriding needs a reason. |
| `wolfskind` | Wolfskind / Wolf Child | Frag nach dem Vorbild, solange keins gewählt ist. Es darf nicht sich selbst wählen. | Ask for the role model while none is chosen. The Wolf Child may not choose themself. |
| `lehrling` | Lehrling / Apprentice | Wähle drei andere Lebende aus. Der Lehrling sieht nur deren Rollen, nie die Namen. | Choose three other living people. The Apprentice sees only their roles, never the names. |
| `manipulator` | Manipulator / Manipulator | Wird er nominiert, stirbt er sofort. Der Tag geht weiter. | If nominated, they die at once. The day continues. |
| `spiegelwolf` | Spiegelwolf / Mirror Wolf | Bei seiner Hinrichtung prüft die App die Spiegelung. Du bestätigst. | At their execution the app checks the reflection. You confirm. |
| `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Wacht im Rudel mit. Die Scheinrolle ist im Setup festgelegt. | Wakes with the pack. The false role was set in setup. |
| `sensentraeger` | Sensenträger / Reaper | Stirbt er, frag, wen er verflucht, oder ob er verzichtet. | If they die, ask whom they curse, or whether they decline. |
| `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | Wacht im Rudel mit. Er zählt für den Wolfssieg doppelt. | Wakes with the pack. They count double for the wolf win. |
| `doppelspion` | Doppelspion / Double Agent | Weck ihn mit dem Rudel, ohne seine Rolle zu nennen. | Wake them with the pack without naming the role. |
| `selbstmoerder` | Selbstmörder / Death Seeker | Wird er bei mindestens 5 Toten hingerichtet, ist sein Sieg erfüllt. Du bestätigst ihn. | If executed with at least 5 dead, their win is fulfilled. You confirm it. |
| `dorfchronistin` | Dorfchronistin / Village Chronicler | Nur Nacht 1: Zeig ihr die Zahl der Personen mit Einzelsiegrolle. | Night 1 only: show the number of people with a solo role. |
| `die-gebundenen` | Die Gebundenen / The Bound | Nur Nacht 1: Alle Gebundenen wachen gemeinsam auf und sehen sich. | Night 1 only: all the Bound wake together and see each other. |
| `waldlaeufer` | Waldläufer / Ranger | Zeig ihm die Zahl der lebenden Wölfe. | Show the number of living wolves. |
| `doktor` | Doktor / Doctor | Er wählt zwei andere Lebende. Zeig ihm: gleiches Team oder verschiedene Teams. | They choose two other living people. Show: same team or different teams. |
| `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | Bei seiner Hinrichtung sterben die nächsten lebenden Nachbarn mit. | At their execution the nearest living neighbours die too. |
| `nachtwaechter` | Nachtwächter / Night Warden | Nach der Morgenauflösung: Sitzt ein Nichtdorf-Nachbar neben ihm, läute die Glocken. | After the dawn resolution: if a non-village neighbour sits next to them, ring the bells. |
| `dorfwache` | Dorfwache / Village Guard | Kein Nachtschritt. Der Rudelangriff tötet sie nicht. | No night step. The pack attack does not kill them. |
| `besessener-wolf` | Besessener Wolf / Possessed Wolf | Stirbt er bei mindestens 5 Lebenden: Frag, wen er mitnimmt, oder ob er verzichtet. | If they die with at least 5 alive: ask whom they take along, or whether they decline. |
| `ritter` | Ritter / Knight | Stirbt er durch den Rudelangriff, stirbt der nächste Wolf mit. Bei Gleichstand wählst du. | If killed by the pack attack, the nearest wolf dies too. In a tie you choose. |
| `faehrtenleser` | Fährtenleser / Tracker | Frag, ob er jetzt nutzt. Zeig links, rechts oder beide Seiten gleich weit. | Ask whether they use it now. Show left, right or both sides equally far. |
| `blutwolf` | Blutwolf / Blood Wolf | Wacht im Rudel mit. Erinnere dich an +1 Stimme je totem Nachbarplatz. | Wakes with the pack. Remember +1 vote per dead neighbouring seat. |
| `korrupter-richter` | Korrupter Richter / Corrupt Judge | Frag, wen er markiert. Bei Tagesbeginn gilt die Person als nominiert. | Ask whom they mark. At the start of the day the person counts as nominated. |
| `waechter-am-tor` | Wächter am Tor / Gatewarden | Kein Nachtschritt. Ein neuer Wolf wird stattdessen Dorfbewohner. Die App meldet es der Person. | No night step. A new wolf becomes a Villager instead. The app tells the person. |
| `spuerhund` | Spürhund / Scent Hound | Er wählt drei andere Lebende oder verzichtet. Zeig Häkchen oder Kreuz. | They choose three other living people or decline. Show check mark or cross. |
| `parasit` | Parasit / Parasite | Frag, ob er den Wirt wechselt oder behält. | Ask whether they change or keep the host. |
| `schattenhund` | Schattenhund / Shadow Hound | Zu Beginn der Nacht: Frag, ob er jetzt blockieren will. Nur Dorfrollen sind betroffen. | At the start of the night: ask whether they want to block now. Only village roles are affected. |
| `albtraumwolf` | Albtraumwolf / Nightmare Wolf | Zu Beginn der Nacht: Frag, wen er blockiert, oder ob er verzichtet. | At the start of the night: ask whom they block, or whether they decline. |
| `giftwolf` | Giftwolf / Poison Wolf | Nach dem Rudel: Frag, ob er vergiftet und wen. Die Wirkung kommt zwei Nächte später. | After the pack: ask whether they poison and whom. The effect comes two nights later. |
| `rudelvater` | Rudelvater / Packfather | Nach seiner Hinrichtung: In der nächsten Nacht folgt direkt nach dem Rudel ein zweiter Rudelschritt. | After their execution: next night a second pack step follows right after the pack. |
| `seuchenwolf` | Seuchenwolf / Blight Wolf | Wacht im Rudel mit. Nach seinem Tod durchdringt der nächste Rudelangriff Schutz. | Wakes with the pack. After their death the next pack attack pierces protection. |
| `fenrir` | Fenrir / Fenrir | Wacht im Rudel mit. Die Stufe steigt jeden Morgen. Ab Stufe 3 überlebt er einmal. | Wakes with the pack. The stage rises every morning. From stage 3 they survive once. |
| `cerberus` | Cerberus / Cerberus | Hat er 3 Köpfe und wird hingerichtet: Frag dich selbst, ob abgewehrt wird. | If they have 3 heads and are executed: decide whether the execution is warded off. |
| `henker` | Henker / Executioner | Ab 3 Hinrichtungen: Frag, wen er markiert. Die Person stirbt bei der nächsten Hinrichtung mit. | From 3 executions: ask whom they mark. That person dies along at the next execution. |
| `traumdeuter` | Traumdeuter / Dreamer | Wähle drei andere Lebende, mindestens ein Wolf. Erst dann geht Bestätigen. | Choose three other living people, at least one wolf. Only then can you confirm. |
| `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter | Nach einem hingerichteten Wolf: Wähle drei Lebende, mindestens ein Wolf. | After an executed wolf: choose three living people, at least one wolf. |
| `koenig` | König / King | Sobald mehr Tote als Lebende: Wähle eine lebende Dorfperson für ihn. | As soon as more dead than living: choose a living village person for them. |
| `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light | Frag, ob sie prüft und wen. Ist das Ziel kein Wolf, stirbt sie am Morgen. | Ask whether they check and whom. If the target is not a wolf, they die in the morning. |
| `blutpriester` | Blutpriester / Blood Priest | Frag, wen er opfert. Wähle dann 0 bis 3 lebende Wölfe, die er erfährt. | Ask whom they sacrifice. Then choose 0 to 3 living wolves that they learn. |
| `amalia` | Amalia / Amalia | Am Tag bei mindestens 3 Wölfen: Beantworte ihre Frage wahrheitsgemäß mit Ja oder Nein. | During the day with at least 3 wolves: answer their question truthfully with yes or no. |
| `detektiv` | Detektiv / Detective | Stirbt ein Wolf und ein anderer lebt: Lies die Richtung des nächsten Wolfs vor. | When a wolf dies and another lives: read out the direction of the nearest wolf. |
| `die-ewigen` | Die Ewigen / The Eternal Ones | Alle Ewigen wachen gemeinsam auf und prüfen eine Person. Zeig Ja oder Nein. | All the Eternal Ones wake together and check one person. Show yes or no. |
| `der-weise` | Der Weise / The Elder | Wird er hingerichtet, leg fest: 0 bis 3 Nächte und Tage ohne Dorffähigkeiten. | If executed, set: 0 to 3 nights and days without village abilities. |
| `maertyrerin` | Märtyrerin / Martyr | Am Ende der Nacht: Frag nur, wenn das Rudelopfer sonst stürbe. | At the end of the night: ask only if the pack victim would otherwise die. |
| `schutzgeist` | Schutzgeist / Guardian Spirit | Nur tot: In der ersten Nacht nach ihrem Tod frag, wen sie mit dem Schild schützt. | Only when dead: in the first night after their death ask whom they shield. |
| `dorfschmied` | Dorfschmied / Village Blacksmith | Ab Nacht 6: Frag, ob er die Waffe jetzt gibt. Beim Abwehren wählst du den Wolf. | From night 6: ask whether they give the weapon now. When it blocks, you choose the wolf. |
| `verdammniswaechter` | Verdammniswächter / Doom Warden | Nach der Rudelwahl: Zeig das Angebot. Er muss zwischen Rudelopfer und Angebot entscheiden. | After the pack choice: show the offer. They must decide between the pack victim and the offer. |
| `loki` | Loki / Loki | Nur Nacht 1: Frag, welche zwei Personen Liebende oder Rivalen werden. | Night 1 only: ask which two people become lovers or rivals. |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | Frag, wen sie wählt. Gehört die Person zu einem lebenden Paar des Loki, sterben beide am Morgen. | Ask whom they choose. If the person belongs to a living pair of Loki, both die in the morning. |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | Frag, wen sie um Zuflucht bittet. Bei Zustimmung entstehen Kette und Apfel. | Ask whom they ask for refuge. On agreement chain and apple arise. |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | Frag, mit wem er sich verknüpft. Er tut es einmal. | Ask with whom they link. They do it once. |
| `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | Stirbt er, frag, wen er verflucht, oder ob er verzichtet. | If they die, ask whom they curse, or whether they decline. |
| `koenig-lykaon` | König Lykaon / King Lycaon | Frag, ob er jetzt verwandelt. Nach drei Verzichten muss er wählen. | Ask whether they transform someone now. After three refusals they must choose. |
| `seelentauscher` | Seelentauscher / Soul Swapper | Frag jede Nacht bis zur Nutzung nach zwei Personen, lebend oder tot. Sie tauschen die Rollen. | Ask every night until used for two people, living or dead. They swap roles. |
| `kutscher` | Kutscher / Coachman | Ab 10 Toten: Frag, welche drei zurückkehren und wer Wolf wird. | From 10 dead: ask which three return and who becomes a wolf. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | Frag jede Nacht bis zur Nutzung nach einer toten Person und einer freien Rolle. Keine Wolfsrolle. | Ask every night until used for a dead person and a free role. No wolf role. |
| `rattenfaenger` | Rattenfänger / Pied Piper | Frag, wen er verzaubert: eine oder zwei unverzauberte Personen. Danach zeigst du den neu Verzauberten ihren Hinweis, dann führt die App den Schritt „Alle Verzauberten“. | Ask whom they enchant: one or two people not yet enchanted. Afterwards show the newly enchanted their notice, then the app runs the step “All enchanted”. |
| `pestbringerin` | Pestbringerin / Plague Bringer | Frag, wen sie infiziert. Am Morgen zieht die App die Ausbreitung. | Ask whom they infect. In the morning the app draws the spread. |
| `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | Nacht 1: drei Markierungen. Freigeschaltet: Frag jede Nacht, wen er tötet. | Night 1: three markings. Once unlocked: ask every night whom they kill. |
| `todesprediger` | Todesprediger / Death Prophet | Nur Nacht 1: Lass ihn leise eine Nacht oder einen Tag nennen. Trag sie geheim ein. | Night 1 only: let them quietly name a night or a day. Enter it secretly. |
| `feuerteufel` | Feuerteufel / Pyromaniac | Frag, ob er ein neues Ziel markiert oder die Markierung behält. | Ask whether they mark a new target or keep the marking. |
| `voodoo-priester` | Voodoo-Priester / Voodoo Priest | Ohne lebende Puppe: Frag, wen er wählt. Nur du weißt es. | Without a living doll: ask whom they choose. Only you know. |
| `nekromant` | Nekromant / Necromancer | Frag, ob er drei Tote für einen Schild opfert. Wolf benennen: geheim bei dir. | Ask whether they sacrifice three dead for a shield. Naming a wolf: secret with you. |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | In den Nächten 3, 6, 9 ...: Frag, welchen Wolf er reißt, oder ob er verzichtet. | In nights 3, 6, 9 ...: ask which wolf they tear, or whether they decline. |
| `zeitwaechter` | Zeitwächter / Time Warden | Vor allen anderen: Frag, ob er die Nacht einfriert. Dann entfallen alle Nachtschritte. | Before all others: ask whether they freeze the night. Then all night steps drop. |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | Nacht 1: drei Markierungen. Nacht 4: Zusatzopfer je Markierten unter den ersten drei Toten. | Night 1: three markings. Night 4: extra victims per marked person among the first three dead. |
| `grabraeuber` | Grabräuber / Grave Robber | Frag jede Nacht bis zur Nutzung nach der toten Person. Danach folgt der gestohlene Schritt. | Ask every night until used for the dead person. After that the stolen step follows. |
| `kartenschlucker` | Kartenschlucker / Card Swallower | Frag, welches Handzeichen er zeigt: Kopfschütteln, zwei, fünf oder zehn Finger. Bei zwei Fingern wählt er danach die Person. | Ask which hand sign they show: head shake, two, five or ten fingers. For two fingers they then choose the person. |
| `hades` | Hades / Hades | Letzter Schritt: erst Tötung für 2 Lichter, dann Barriere für 3. Bezahlt wird am Ende. | Last step: first kill for 2 lights, then barrier for 3. Payment comes at the end. |

### 3.2 `[PERSON-PRIVAT]` Information nur für die betreffende Person

| Rollen-ID | Rolle | DE | EN |
|---|---|---|---|
| `dorfbewohner` | Dorfbewohner / Villager | Du bist Dorfbewohner. Du hast keine Fähigkeit. | You are a Villager. You have no ability. |
| `werwolf` | Werwolf / Werewolf | Du bist Werwolf. Dein Rudel: {names}. | You are a Werewolf. Your pack: {names}. |
| `schutzengel` | Schutzengel / Guardian Angel | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `waldhexe` | Waldhexe / Witch of the Woods | Opfer dieser Nacht: {name}. Nach der Rettung: {name} ist {role}. | This night's victim: {name}. After the rescue: {name} is {role}. |
| `das-orakel` | Das Orakel / The Oracle | Ergebnis: {name} ist {role}. | Result: {name} is {role}. |
| `wolfskind` | Wolfskind / Wolf Child | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `lehrling` | Lehrling / Apprentice | Wähle eine Rolle: {roles}. Du siehst keine Namen. | Choose a role: {roles}. You see no names. |
| `manipulator` | Manipulator / Manipulator | (entfällt) Keine Information, kein Nachtschritt. | (not applicable) No information, no night step. |
| `spiegelwolf` | Spiegelwolf / Mirror Wolf | (entfällt) Quellen nennen keine private Information. | (not applicable) Sources name no private information. |
| `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Du bist Trugbilderwolf. Dein Rudel: {names}. Deine Scheinrolle kennt nur der Spielleiter. | You are a Decoy Wolf. Your pack: {names}. Only the game master knows your false role. |
| `sensentraeger` | Sensenträger / Reaper | (entfällt) Nur Reaktion, keine Information. | (not applicable) Reaction only, no information. |
| `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | (entfällt) Quellen nennen keine private Information. | (not applicable) Sources name no private information. |
| `doppelspion` | Doppelspion / Double Agent | (entfällt) Keine Information über die Wölfe ausdrücklich geregelt. | (not applicable) Sources name no private information. |
| `selbstmoerder` | Selbstmörder / Death Seeker | (entfällt) Keine private Information. | (not applicable) No private information. |
| `dorfchronistin` | Dorfchronistin / Village Chronicler | Anzahl der Personen mit Einzelsiegrolle: {count}. | Number of people with a solo role: {count}. |
| `die-gebundenen` | Die Gebundenen / The Bound | Ihr seid gebunden: {names}. Wenn niemand: Keine anderen Gebundenen. | You are bound: {names}. If no one: No other Bound. |
| `waldlaeufer` | Waldläufer / Ranger | Anzahl lebender Wölfe: {count}. | Number of living wolves: {count}. |
| `doktor` | Doktor / Doctor | {name1} und {name2}: gleiches Team. Sonst: verschiedene Teams. | {name1} and {name2}: same team. Otherwise: different teams. |
| `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | (entfällt) Keine Information. | (not applicable) No information. |
| `nachtwaechter` | Nachtwächter / Night Warden | (entfällt) Die Wirkung ist öffentlich. | (not applicable) The effect is public. |
| `dorfwache` | Dorfwache / Village Guard | (entfällt) Keine Information. | (not applicable) No information. |
| `besessener-wolf` | Besessener Wolf / Possessed Wolf | (entfällt) Nur die Reaktion, keine Information. | (not applicable) Reaction only, no information. |
| `ritter` | Ritter / Knight | (entfällt) Keine Information. | (not applicable) No information. |
| `faehrtenleser` | Fährtenleser / Tracker | Der nächste Wolf sitzt {direction}. | The nearest wolf sits {direction}. |
| `blutwolf` | Blutwolf / Blood Wolf | (entfällt) Der Hinweis gehört zur Spielleiteransicht. | (not applicable) The reminder belongs to the game master view. |
| `korrupter-richter` | Korrupter Richter / Corrupt Judge | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `waechter-am-tor` | Wächter am Tor / Gatewarden | An die betroffene Person: Du bist jetzt Dorfbewohner. | To the affected person: You are now a Villager. |
| `spuerhund` | Spürhund / Scent Hound | Häkchen: Unter den drei ist ein Wolf oder eine Einzelsiegperson. Sonst Kreuz: Fähigkeit verloren. | Check mark: among the three is a wolf or a solo person. Otherwise cross: ability lost. |
| `parasit` | Parasit / Parasite | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `schattenhund` | Schattenhund / Shadow Hound | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `albtraumwolf` | Albtraumwolf / Nightmare Wolf | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `giftwolf` | Giftwolf / Poison Wolf | An die vergiftete Person: Du wurdest vergiftet. | To the poisoned person: You have been poisoned. |
| `rudelvater` | Rudelvater / Packfather | (entfällt) Quellen nennen keine private Information. | (not applicable) Sources name no private information. |
| `seuchenwolf` | Seuchenwolf / Blight Wolf | (entfällt) Quellen nennen keine private Information. | (not applicable) Sources name no private information. |
| `fenrir` | Fenrir / Fenrir | (entfällt) Die Stufe steht in der Spielleiteransicht. | (not applicable) The stage appears in the game master view. |
| `cerberus` | Cerberus / Cerberus | (entfällt) Die Frage geht an den Spielleiter. | (not applicable) The question goes to the game master. |
| `henker` | Henker / Executioner | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `traumdeuter` | Traumdeuter / Dreamer | {names}: Darunter ist mindestens ein Wolf. | {names}: At least one wolf is among them. |
| `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter | {names}: Darunter ist mindestens ein Wolf. | {names}: At least one wolf is among them. |
| `koenig` | König / King | {name} gehört zum Dorf und ist {role}. | {name} belongs to the village and is {role}. |
| `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light | {name} ist ein Wolf. Wenn nicht: {name} ist kein Wolf. | {name} is a wolf. If not: {name} is not a wolf. |
| `blutpriester` | Blutpriester / Blood Priest | Wölfe: {names}. Wenn keiner genannt wird: Keine Wölfe genannt. | Wolves: {names}. If none is named: No wolves named. |
| `amalia` | Amalia / Amalia | (entfällt) Die Wirkung ist öffentlich. | (not applicable) The effect is public. |
| `detektiv` | Detektiv / Detective | (entfällt) Die Wirkung ist öffentlich. | (not applicable) The effect is public. |
| `die-ewigen` | Die Ewigen / The Eternal Ones | {name}: Einzelsiegrolle, Ja. Sonst: Nein. | {name}: solo role, yes. Otherwise: no. |
| `der-weise` | Der Weise / The Elder | (entfällt) Die Rettung erfährt nur der Spielleiter. | (not applicable) Only the game master learns of the rescue. |
| `maertyrerin` | Märtyrerin / Martyr | (entfällt) Nur Frage, keine Information. | (not applicable) Question only, no information. |
| `schutzgeist` | Schutzgeist / Guardian Spirit | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `dorfschmied` | Dorfschmied / Village Blacksmith | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `verdammniswaechter` | Verdammniswächter / Doom Warden | (entfällt) Das Angebot ist eine Wahl, keine Information. | (not applicable) The offer is a choice, not information. |
| `loki` | Loki / Loki | Du und {name} seid Liebende: Stirbt eine Person, stirbt die andere. Wenn Rivalen: Du und {name} seid Rivalen. | You and {name} are lovers: if one dies, the other dies. If rivals: You and {name} are rivals. |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | An die gefragte Person: Du wirst um Zuflucht gebeten. Gewährst du sie, erhältst du einen Apfel und wirst verkettet: Stirbt eine Person, stirbt die andere. Du erfährst nicht, wer fragt. | To the asked person: You are asked for refuge. If you grant it, you receive an apple and are chained: if one dies, the other dies. You do not learn who asks. |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | (entfällt) Der verfluchten Person wird nichts gezeigt. | (not applicable) The cursed person is shown nothing. |
| `koenig-lykaon` | König Lykaon / King Lycaon | An die verwandelte Person: Du bist jetzt Trugbilderwolf. | To the transformed person: You are now a Decoy Wolf. |
| `seelentauscher` | Seelentauscher / Soul Swapper | An jede lebende betroffene Person: Deine neue Rolle: {role}. | To each living affected person: Your new role: {role}. |
| `kutscher` | Kutscher / Coachman | An jede zurückgeholte Person: Du lebst wieder. Deine Rolle: {role}. | To each returned person: You are alive again. Your role: {role}. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | An die zurückgeholte Person: Du lebst wieder. Deine neue Rolle: {role}. | To the returned person: You are alive again. Your new role: {role}. |
| `rattenfaenger` | Rattenfänger / Pied Piper | An die neu Verzauberten: Ihr seid verzaubert. (Alle Verzauberten erkennen einander mit offenen Augen; ihre Namen stehen nur auf der Karte der Spielleitung.) | To the newly enchanted: You are enchanted. (All enchanted recognise each other with open eyes; their names appear only on the game master's card.) |
| `pestbringerin` | Pestbringerin / Plague Bringer | An jede neu infizierte Person, auch durch die Ausbreitung: Du bist infiziert. Zu Beginn jedes Morgens steckst du eine benachbarte lebende Person an, solange du lebst. | To each newly infected person, also through the spread: You are infected. At the start of each morning you infect a neighbouring living person, as long as you live. |
| `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `todesprediger` | Todesprediger / Death Prophet | (entfällt) Die Vorhersage geht nur an den Spielleiter. | (not applicable) The prediction goes to the game master only. |
| `feuerteufel` | Feuerteufel / Pyromaniac | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `voodoo-priester` | Voodoo-Priester / Voodoo Priest | (entfällt) Die Puppe erfährt es nicht. | (not applicable) The doll does not learn of it. |
| `nekromant` | Nekromant / Necromancer | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `zeitwaechter` | Zeitwächter / Time Warden | (entfällt) Nur Frage, keine Information. | (not applicable) Question only, no information. |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `grabraeuber` | Grabräuber / Grave Robber | Du hast die Fähigkeit von {role} gestohlen. | You stole the ability of {role}. |
| `kartenschlucker` | Kartenschlucker / Card Swallower | (entfällt) Nur Handzeichen, keine Information. | (not applicable) Hand sign only, no information. |
| `hades` | Hades / Hades | (entfällt) Quellen nennen keine private Anzeige. | (not applicable) Sources name no private display. |

### 3.3 `[ÖFFENTLICH]` Aufruf und Einschlafen

**Abgleich Paket 5b (29.09.2026):** Die Spalten DE/EN geben den im Programm integrierten Vorlesetext wieder (`ui.call.*`; ohne eigenen Text der allgemeine Aufruf `ui.call.generic`). Maßgeblich ist der Wortlaut in `ui.*.po`. Das Einschlafen sagt die App nicht gesondert an. Rollen ohne Nachtschritt behalten ihre Zeile.

Entwurf nach dem Muster von `docs/assets/NARRATOR-SCRIPT.md` §3. Aufrufpolitik (Antwort des Product Owners vom 29.09.2026, Decision Log DI-02): In Runden ohne Wiederbelebung werden bereits aufgedeckte Rollen in der Nachtreihenfolge nicht mehr aufgerufen. Aufgebrauchte Rollen werden trotzdem aufgerufen, nur ohne Fähigkeit, damit Dorf und Wölfe nicht wissen, was genutzt ist. In Wiederbelebungsrunden werden auch tote Rollen weiter aufgerufen, damit niemand weiß, wer lebt. Aus der Antwort folgt, dass auch blockierte und noch nicht aktive Rollen aufgerufen werden; nicht in der Partie vorkommende Rollen werden nicht aufgerufen (beides abgeleitet, zu bestätigen). Handlungszeilen ("Zeige auf ...") kennt das NARRATOR-SCRIPT nur für die Slice-Rollen; für alle weiteren Rollen sind sie offen (OI-18).

| Rollen-ID | Rolle | DE | EN |
|---|---|---|---|
| `dorfbewohner` | Dorfbewohner / Villager | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `werwolf` | Werwolf / Werewolf | Werwölfe, erwacht. Einigt euch still auf ein Opfer und zeigt es mir. | Werewolves, wake up. Silently agree on a victim and point to them. |
| `schutzengel` | Schutzengel / Guardian Angel | Schutzengel, erwache. Zeige auf die Person, die du heute Nacht beschützen willst. | Guardian Angel, wake up. Point to the person you want to protect tonight. |
| `waldhexe` | Waldhexe / Witch of the Woods | Waldhexe, erwache. Ich zeige dir das Opfer der Nacht. Willst du einen Trank nutzen? | Forest Witch, wake up. I will show you tonight’s victim. Do you want to use a potion? |
| `das-orakel` | Das Orakel / The Oracle | Orakel, erwache. Zeige auf die Person, deren Wesen du schauen willst. | Oracle, wake up. Point to the person whose nature you want to see. |
| `wolfskind` | Wolfskind / Wolf Child | Wolfskind, erwache. Zeige auf die Person, die dein Vorbild sein soll. | Wolf Child, wake up. Point to the person who shall be your role model. |
| `lehrling` | Lehrling / Apprentice | Lehrling, erwache. Ich zeige dir gleich drei Rollen. Wähle deinen Meister. | Apprentice, wake up. I will show you three roles. Choose your master. |
| `manipulator` | Manipulator / Manipulator | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `spiegelwolf` | Spiegelwolf / Mirror Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `sensentraeger` | Sensenträger / Reaper | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `doppelspion` | Doppelspion / Double Agent | Kein eigener Aufruf. Wacht im Rudelaufruf mit, ohne genannt zu werden. | No call of its own. Wakes within the pack call without being named. |
| `selbstmoerder` | Selbstmörder / Death Seeker | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `dorfchronistin` | Dorfchronistin / Village Chronicler | Dorfchronistin, erwache. Ich zeige dir, wie viele Einzelgänger im Dorf sind. | Village Chronicler, wake up. I will show you how many loners are in the village. |
| `die-gebundenen` | Die Gebundenen / The Bound | Gebundene, erwacht und seht einander an. | Bound ones, wake up and look at each other. |
| `waldlaeufer` | Waldläufer / Ranger | Waldläufer, erwache. Ich zeige dir, wie viele Wölfe noch leben. | Ranger, wake up. I will show you how many wolves are still alive. |
| `doktor` | Doktor / Doctor | Doktor, erwache. Zeige auf zwei Personen, deren Blut du vergleichen willst. | Doctor, wake up. Point to two people whose blood you want to compare. |
| `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `nachtwaechter` | Nachtwächter / Night Warden | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `dorfwache` | Dorfwache / Village Guard | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `besessener-wolf` | Besessener Wolf / Possessed Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `ritter` | Ritter / Knight | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `faehrtenleser` | Fährtenleser / Tracker | Fährtenleser, erwache. Willst du heute die Fährte lesen? | Tracker, wake up. Do you want to read the trail tonight? |
| `blutwolf` | Blutwolf / Blood Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `korrupter-richter` | Korrupter Richter / Corrupt Judge | Korrupter Richter, erwache. Zeige auf die Person, die morgen als nominiert gilt. | Corrupt Judge, wake up. Point to the person who counts as nominated tomorrow. |
| `waechter-am-tor` | Wächter am Tor / Gatewarden | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `spuerhund` | Spürhund / Scent Hound | Spürhund, erwache. Zeige auf drei Personen, an denen du schnüffeln willst. | Sniffer Dog, wake up. Point to three people you want to sniff. |
| `parasit` | Parasit / Parasite | Parasit, erwache. Willst du einen neuen Wirt wählen? Zeige auf die Person. | Parasite, wake up. Do you want to choose a new host? Point to the person. |
| `schattenhund` | Schattenhund / Shadow Hound | Schattenhund, erwache. Willst du das Dorf heute Nacht blockieren? | Shadow Hound, wake up. Do you want to block the village tonight? |
| `albtraumwolf` | Albtraumwolf / Nightmare Wolf | Albtraumwolf, erwache. Zeige auf die Person, deren Fähigkeit du heute Nacht blockierst. | Nightmare Wolf, wake up. Point to the person whose ability you block tonight. |
| `giftwolf` | Giftwolf / Poison Wolf | Giftwolf, erwache. Willst du jemanden vergiften? Zeige auf die Person. | Poison Wolf, wake up. Do you want to poison someone? Point to the person. |
| `rudelvater` | Rudelvater / Packfather | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `seuchenwolf` | Seuchenwolf / Blight Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `fenrir` | Fenrir / Fenrir | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `cerberus` | Cerberus / Cerberus | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `henker` | Henker / Executioner | Henker, erwache. Zeige auf die Person, die bei der nächsten Hinrichtung mit stirbt. | Hangman, wake up. Point to the person who dies at the next execution as well. |
| `traumdeuter` | Traumdeuter / Dreamer | Traumdeuter, erwache. Ich zeige dir die Namen aus deinem Traum. | Dream Reader, wake up. I will show you the names from your dream. |
| `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter | Kopfgeldjäger, erwache. Hier ist deine Liste. | Bounty Hunter, wake up. Here is your list. |
| `koenig` | König / King | König, erwache. Zeige auf eine Person aus dem Dorf, deren Rolle du erfahren willst. | King, wake up. Point to a villager whose role you want to learn. |
| `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light | Kriegerin des Lichts, erwache. Willst du heute angreifen? Zeige auf die Person. | Warrior of Light, wake up. Do you want to attack tonight? Point to the person. |
| `blutpriester` | Blutpriester / Blood Priest | Blutpriester, erwache. Willst du heute ein Opfer bringen? Zeige darauf oder schüttle den Kopf. | Blood Priest, wake up. Do you want to make a sacrifice tonight? Point to them or shake your head. |
| `amalia` | Amalia / Amalia | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `detektiv` | Detektiv / Detective | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `die-ewigen` | Die Ewigen / The Eternal Ones | Ewige, erwacht. Zeigt gemeinsam auf die Person, die ihr prüfen wollt. | Eternal ones, wake up. Point together to the person you want to check. |
| `der-weise` | Der Weise / The Elder | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `maertyrerin` | Märtyrerin / Martyr | Märtyrerin, erwache. Willst du dich für das Opfer der Nacht opfern? | Martyr, wake up. Do you want to sacrifice yourself for tonight’s victim? |
| `schutzgeist` | Schutzgeist / Guardian Spirit | Schutzgeist, erwache. Zeige auf die Person, der du deinen Schild schenkst. | Guardian Spirit, wake up. Point to the person you give your shield to. |
| `dorfschmied` | Dorfschmied / Village Blacksmith | Dorfschmied, erwache. Willst du deine Waffe jetzt vergeben? Zeige auf die Person. | Village Smith, wake up. Do you want to hand over your weapon now? Point to the person. |
| `verdammniswaechter` | Verdammniswächter / Doom Warden | Verdammniswächter, erwache. Wen soll der Angriff der Wölfe treffen? | Doom Warden, wake up. Whom shall the wolves’ attack strike? |
| `loki` | Loki / Loki | Loki, erwache. Zeige auf zwei Personen, die du miteinander verbinden willst. | Loki, wake up. Point to two people you want to bind together. |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | Schwarze Witwe, erwache. Zeige auf die Person, die du umgarnen willst. | Black Widow, wake up. Point to the person you want to ensnare. |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | Rotkäppchen, erwache. Zeige auf die Person, bei der du Zuflucht suchst. | Little Red Riding Hood, wake up. Point to the person you seek refuge with. |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | Schattenwanderer, erwache. Willst du dich mit jemandem verknüpfen? Zeige auf die Person. | Shadow Walker, wake up. Do you want to link with someone? Point to the person. |
| `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `koenig-lykaon` | König Lykaon / King Lycaon | König Lykaon, erwache. Wähle einen Verbündeten und ein Opfer deiner Verwandlung. | King Lycaon, wake up. Choose an ally and a victim of your transformation. |
| `seelentauscher` | Seelentauscher / Soul Swapper | Seelentauscher, erwache. Willst du zwei Seelen tauschen? Zeige auf die beiden. | Soul Swapper, wake up. Do you want to swap two souls? Point to both. |
| `kutscher` | Kutscher / Coachman | Kutscher, erwache. Willst du drei Tote zurückholen? Zeige auf sie. | Coachman, wake up. Do you want to bring back three of the dead? Point to them. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | Doktor Frankenstein, erwache. Willst du einen Toten zurückholen? Zeige auf ihn. | Doctor Frankenstein, wake up. Do you want to bring back one of the dead? Point to them. |
| `rattenfaenger` | Rattenfänger / Pied Piper | Rattenfänger, erwache. Zeige auf eine oder zwei Personen, die du verzaubern willst. Danach: die neu Verzauberten (Hinweiskarte), dann „Alle Verzauberten, öffnet die Augen und erkennt einander.“; nach jedem Aufruf des Rattenfängers, auch einem Tarnaufruf, solange es lebende Verzauberte gibt (PE-06). | Pied Piper, wake up. Point to one or two people you want to charm. Then: the newly enchanted (notice card), then “All enchanted, open your eyes and recognise each other.”; after every call of the Pied Piper, including a decoy call, while living enchanted people exist (PE-06). |
| `pestbringerin` | Pestbringerin / Plague Bringer | Pestbringerin, erwache. Zeige auf die Person, die du infizieren willst. | Plague Bringer, wake up. Point to the person you want to infect. |
| `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | Prophet des Untergangs, erwache. Zeige auf die Personen deiner Prophezeiung. | Prophet of Doom, wake up. Point to the people of your prophecy. |
| `todesprediger` | Todesprediger / Death Prophet | Todesprediger, erwache. Sag mir leise, wann du sterben wirst. | Death Preacher, wake up. Tell me quietly when you will die. |
| `feuerteufel` | Feuerteufel / Pyromaniac | Feuerteufel, erwache. Zeige auf die Person, die du markieren willst. | Fire Devil, wake up. Point to the person you want to mark. |
| `voodoo-priester` | Voodoo-Priester / Voodoo Priest | Voodoo-Priester, erwache. Zeige auf die Person, die deine Puppe erhält. | Voodoo Priest, wake up. Point to the person who receives your doll. |
| `nekromant` | Nekromant / Necromancer | Nekromant, erwache. Willst du Tote opfern? Zeige auf drei von ihnen. | Necromancer, wake up. Do you want to sacrifice the dead? Point to three of them. |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | Rachsüchtiger Wolf, erwache. Willst du einen anderen Wolf reißen? Zeige auf ihn. | Vengeful Wolf, wake up. Do you want to tear another wolf? Point to them. |
| `zeitwaechter` | Zeitwächter / Time Warden | Zeitwächter, erwache. Willst du diese Nacht einfrieren? | Time Warden, wake up. Do you want to freeze this night? |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | Schicksalswolf, erwache. Zeige auf die Personen, die das Schicksal treffen soll. | Fate Wolf, wake up. Point to the people fate shall strike. |
| `grabraeuber` | Grabräuber / Grave Robber | Grabräuber, erwache. Willst du das Grab eines Toten plündern? Zeige auf ihn. | Grave Robber, wake up. Do you want to rob a dead person’s grave? Point to them. |
| `kartenschlucker` | Kartenschlucker / Card Swallower | Kartenschlucker, erwache. Zeige mit den Fingern, was du tun willst: Kopfschütteln heißt nichts, zwei Finger eine Tötung, fünf Finger einen Schild, zehn Finger den Sieg. | Card Swallower, wake up. Show with your fingers what you want to do: shaking your head means nothing, two fingers a kill, five fingers a shield, ten fingers the win. |
| `hades` | Hades / Hades | Hades, erwache. Willst du mit deinen Lichtern jemanden holen? Zeige auf die Person. | Hades, wake up. Do you want to use your lights to take someone? Point to the person. |

### 3.4 `[ÖFFENTLICH]` Öffentliche Wirkung

**Abgleich Paket 5b (29.09.2026):** Todeseffekte (`ui.effect.*`) und öffentliche Morgenhinweise (`ui.morning.notice.*`) im integrierten Wortlaut; `{name}`, `{role}`, `{target}`, `{replaced}` sind dessen Platzhalter. Liebeskummer, Kette und Verknüpfung nennen die Rolle, von der der Effekt stammt (PE-05). Übrige Zeilen unverändert.

Nur Wirkungen, die eine Entscheidung ausdrücklich veröffentlicht. Alle anderen Rollen erscheinen öffentlich ausschließlich über die allgemeinen Tod-, Morgen-, Tag- und Siegtexte aus Abschnitt 2.

| Rollen-ID | Rolle | DE | EN |
|---|---|---|---|
| `dorfbewohner` | Dorfbewohner / Villager | (keine zusätzliche Ansage) | (no additional announcement) |
| `werwolf` | Werwolf / Werewolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `schutzengel` | Schutzengel / Guardian Angel | (keine zusätzliche Ansage) | (no additional announcement) |
| `waldhexe` | Waldhexe / Witch of the Woods | (keine zusätzliche Ansage) | (no additional announcement) |
| `das-orakel` | Das Orakel / The Oracle | (keine zusätzliche Ansage) | (no additional announcement) |
| `wolfskind` | Wolfskind / Wolf Child | (keine; Aufruf nach der Aufrufpolitik, DI-02) | (none; call according to the call policy, DI-02) |
| `lehrling` | Lehrling / Apprentice | (keine; Aufruf nach der Aufrufpolitik, DI-02) | (none; call according to the call policy, DI-02) |
| `manipulator` | Manipulator / Manipulator | (keine zusätzliche Ansage) | (no additional announcement) |
| `spiegelwolf` | Spiegelwolf / Mirror Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `sensentraeger` | Sensenträger / Reaper | {name} war {role} und verflucht {target}. | {name} was {role} and curses {target}. |
| `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `doppelspion` | Doppelspion / Double Agent | (keine; der Rudelaufruf nennt ihn nicht) | (none; the pack call does not name them) |
| `selbstmoerder` | Selbstmörder / Death Seeker | (keine Textansage; der Ton bei fünf Toten ist entschieden, nur mit Selbstmörder in der Partie, Umsetzung offen (OI-07)) | (no text announcement; the sound at five dead is decided, only with a Death Seeker in the game, implementation open (OI-07)) |
| `dorfchronistin` | Dorfchronistin / Village Chronicler | (keine zusätzliche Ansage) | (no additional announcement) |
| `die-gebundenen` | Die Gebundenen / The Bound | (keine zusätzliche Ansage) | (no additional announcement) |
| `waldlaeufer` | Waldläufer / Ranger | (keine zusätzliche Ansage) | (no additional announcement) |
| `doktor` | Doktor / Doctor | (keine zusätzliche Ansage) | (no additional announcement) |
| `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | {name} war {role}. Die Nachbarn {target} sterben mit. | {name} was {role}. The neighbours {target} die too. |
| `nachtwaechter` | Nachtwächter / Night Warden | Die Glocken des Nachtwächters läuten. | The night watchman’s bells are ringing. |
| `dorfwache` | Dorfwache / Village Guard | (keine zusätzliche Ansage) | (no additional announcement) |
| `besessener-wolf` | Besessener Wolf / Possessed Wolf | {name} war {role} und zieht {target} mit in den Tod. | {name} was {role} and drags {target} to their death. |
| `ritter` | Ritter / Knight | {name} war {role} und reißt {target} mit in den Tod. | {name} was {role} and takes {target} down too. |
| `faehrtenleser` | Fährtenleser / Tracker | (keine zusätzliche Ansage) | (no additional announcement) |
| `blutwolf` | Blutwolf / Blood Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `korrupter-richter` | Korrupter Richter / Corrupt Judge | {name} gilt heute als nominiert. | {name} counts as nominated today. |
| `waechter-am-tor` | Wächter am Tor / Gatewarden | (keine zusätzliche Ansage) | (no additional announcement) |
| `spuerhund` | Spürhund / Scent Hound | (keine zusätzliche Ansage) | (no additional announcement) |
| `parasit` | Parasit / Parasite | (keine zusätzliche Ansage) | (no additional announcement) |
| `schattenhund` | Schattenhund / Shadow Hound | (keine zusätzliche Ansage) | (no additional announcement) |
| `albtraumwolf` | Albtraumwolf / Nightmare Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `giftwolf` | Giftwolf / Poison Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `rudelvater` | Rudelvater / Packfather | (keine zusätzliche Ansage) | (no additional announcement) |
| `seuchenwolf` | Seuchenwolf / Blight Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `fenrir` | Fenrir / Fenrir | (keine zusätzliche Ansage) | (no additional announcement) |
| `cerberus` | Cerberus / Cerberus | (keine zusätzliche Ansage) | (no additional announcement) |
| `henker` | Henker / Executioner | (keine zusätzliche Ansage) | (no additional announcement) |
| `traumdeuter` | Traumdeuter / Dreamer | (keine zusätzliche Ansage) | (no additional announcement) |
| `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter | (keine zusätzliche Ansage) | (no additional announcement) |
| `koenig` | König / King | (keine zusätzliche Ansage) | (no additional announcement) |
| `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light | (keine zusätzliche Ansage) | (no additional announcement) |
| `blutpriester` | Blutpriester / Blood Priest | (keine zusätzliche Ansage) | (no additional announcement) |
| `amalia` | Amalia / Amalia | Amalia opfert sich. Ihre Frage: {question} Die Antwort: {answer}. | Amalia sacrifices themself. Their question: {question} The answer: {answer}. |
| `detektiv` | Detektiv / Detective | Ein Hinweis: Vom Platz von {name} aus liegt der nächste Wolf {direction}. | A clue: from {name}’s seat, the nearest wolf is {direction}. |
| `die-ewigen` | Die Ewigen / The Eternal Ones | (keine zusätzliche Ansage) | (no additional announcement) |
| `der-weise` | Der Weise / The Elder | {name} war {role}. Die Fähigkeiten des Dorfes ruhen. | {name} was {role}. The village's abilities rest. |
| `maertyrerin` | Märtyrerin / Martyr | (keine zusätzliche Ansage) | (no additional announcement) |
| `schutzgeist` | Schutzgeist / Guardian Spirit | Ein Schutzgeist hat in dieser Nacht einen Wolf berührt. | A guardian spirit touched a wolf this night. |
| `dorfschmied` | Dorfschmied / Village Blacksmith | (keine zusätzliche Ansage) | (no additional announcement) |
| `verdammniswaechter` | Verdammniswächter / Doom Warden | (keine zusätzliche Ansage) | (no additional announcement) |
| `loki` | Loki / Loki | Die Bindung von {role} wirkt: Aus Liebeskummer stirbt {target}. | {role}'s bond holds: {target} dies of heartbreak. |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | (keine zusätzliche Ansage) | (no additional announcement) |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | Die Kette von {role} bricht: {target} stirbt mit {name}. | {role}'s chain breaks: {target} dies along with {name}. |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | Die Verknüpfung von {role} greift: {target} stirbt an Stelle von {replaced}. | {role}'s link takes hold: {target} dies in place of {replaced}. |
| `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `koenig-lykaon` | König Lykaon / King Lycaon | (keine zusätzliche Ansage) | (no additional announcement) |
| `seelentauscher` | Seelentauscher / Soul Swapper | (keine zusätzliche Ansage) | (no additional announcement) |
| `kutscher` | Kutscher / Coachman | Zurück im Dorf: {names}. | Back in the village: {names}. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | Zurück im Dorf: {name}. | Back in the village: {name}. |
| `rattenfaenger` | Rattenfänger / Pied Piper | (keine zusätzliche Ansage) | (no additional announcement) |
| `pestbringerin` | Pestbringerin / Plague Bringer | (keine zusätzliche Ansage) | (no additional announcement) |
| `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | (keine zusätzliche Ansage) | (no additional announcement) |
| `todesprediger` | Todesprediger / Death Prophet | (keine zusätzliche Ansage) | (no additional announcement) |
| `feuerteufel` | Feuerteufel / Pyromaniac | (keine zusätzliche Ansage) | (no additional announcement) |
| `voodoo-priester` | Voodoo-Priester / Voodoo Priest | (keine zusätzliche Ansage) | (no additional announcement) |
| `nekromant` | Nekromant / Necromancer | (keine zusätzliche Ansage) | (no additional announcement) |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `zeitwaechter` | Zeitwächter / Time Warden | In dieser Nacht stand die Zeit still. | Time stood still this night. |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `grabraeuber` | Grabräuber / Grave Robber | (keine zusätzliche Ansage) | (no additional announcement) |
| `kartenschlucker` | Kartenschlucker / Card Swallower | In den Nächten 3, 6, 9 und so weiter: Der Kartenschlucker hat insgesamt {total} Stapel gesammelt. Käufe bleiben unerwähnt. | In nights 3, 6, 9 and so on: The Card Swallower has collected {total} stacks in total. Purchases stay unmentioned. |
| `hades` | Hades / Hades | (keine zusätzliche Ansage) | (no additional announcement) |

## 4. Prüfung auf Informationsweitergabe

Geprüft wurden alle `[ÖFFENTLICH]`-Zeilen (Abschnitt 2, 3.3, 3.4), die `[SL-PRIVAT]`-Zeilen auf öffentlich vorzulesende Teile und die Spielleitungs- und Beispielzellen im Rollenlexikon. Stand: Quell-Commit `312f5bb`, Prüfung 29.09.2026.

### 4.1 Ausdrücklich erlaubte öffentliche Enthüllungen

Diese Ansagen legen bewusst etwas offen, weil eine Entscheidung es so vorsieht. Sie sind nicht als Fehler zu behandeln, aber ihre Wirkung ist genau die folgende.

| Öffentliche Ansage oder Wirkung | Was sie offenlegt | Was sie nicht offenlegt | Quelle |
|---|---|---|---|
| Tod einer Person (allgemeiner Text) | Name; Rolle nur in Runden ohne Wiederbelebung | Todesursache, interne Effekte, außer den angesagten Todeseffekten | DR-04, G-TOD-5, Antwort des Product Owners vom 29.09.2026 |
| Todeseffekt-Ansage (Sensenträger, Ritter, Besessener Wolf, Wahnsinniger Kutscher, Fluch des Weisen, Liebeskummer, Rotkäppchen-Kette, Verknüpfung des Schattenwanderers) | der Effekt und eine Rolle (auch in Wiederbelebungsrunden, in denen Rollen sonst verdeckt bleiben): bei Sensenträger, Ritter, Besessenem Wolf, Wahnsinnigem Kutscher und Fluch des Weisen die Rolle der auslösenden Person, bei Liebeskummer, Kette und Verknüpfung die Rolle, von der der Effekt stammt (PE-05), nie die der sterbenden Person und die Betroffenen | geheime Wahlen ohne sichtbare Folge (Fluch des Dämonischen Wolfs, Voodoo-Puppe, Markierungen), Ursachen anderer Tode | Antwort des Product Owners vom 29.09.2026, ändert DR-04 |
| Detektiv: "Der nächste Wolf sitzt {direction} vom Platz von {name}." | dass die gestorbene Person als Wolf zählte (auch bei ausgeschalteter Rollenaufdeckung), dass noch ein Detektiv lebt, dass mindestens ein weiterer Wolf lebt, die Richtung | Rolle der Toten, wer der Detektiv ist, wer der nächste Wolf ist | I-10, I-14 |
| Nachtwächter: "Die Glocken läuten. Etwas stimmt nicht." | dass ein Nachtwächter lebt und neben ihm eine Person sitzt, die nicht zum Dorf gehört | Seite, Namen, Rolle der Nachbarn, wer der Nachtwächter ist | Nachfrage Nachtwächter (Decision Log, Sitznachbarn) |
| Amalia: Frage und Antwort | die Fähigkeit von Amalia, ihre Frage, das Ja oder Nein | nichts über die Befragten außer dem, was Frage und Antwort selbst sagen | I-09 |
| Schutzgeist: "Eine tote Person hat in der Nacht einen Wolf gewählt." | dass die gewählte Person ein Wolf ist, und dass eine Tote diese Wahl getroffen hat | Name der Toten, Name des Gewählten, Rollenname | S-04, DR-04 |
| Zeitwächter: "Die Zeit stand still. Diese Nacht ist ausgefallen." | dass ein Zeitwächter existiert und genutzt hat | Name | E-36, DA-19 |
| Wiederbelebung: "Zurück im Dorf: {names}." | dass genannte Personen wieder leben | neue Rolle, Wolfsstatus, wer sie zurückgeholt hat | W-04 |
| Korrupter Richter: "{name} ist nominiert." | Nominierung der markierten Person | dass der Richter markiert hat | RM-DR-012, Korrupter-Richter-Entscheidung |
| Ton bei fünf Toten (entschieden, nicht umgesetzt) | dass ein Selbstmörder in der Partie ist und die Schwelle erreicht ist | wer die Rolle hat | Decision Log "Sound bei 5 Toten", OI-07 |
| Siegtexte und Spielende | Sieger; bei Alleinsieg Name und Rolle; am Ende alle Rollen | | F-11, G-SIEG |

### 4.2 Geheim zu halten (nie `[ÖFFENTLICH]`)

Rollen lebender Personen; alle Ziele und Wahlen; Todesursachen (außer den angesagten Todeseffekten, 4.1); Ergebnisse aller Informationsrollen (Orakel, Waldläufer, Doktor, Fährtenleser, Spürhund, Traumdeuter, Kopfgeldjäger, König, Kriegerin des Lichts, Blutpriester, Ewige, Chronistin, Gebundene); Schutz, Rettung, Durchdringung und verbrauchte Rettungen; Gift und Todesmarkierungen; Scheinrolle des Trugbilderwolfs; Bindungen (Loki, Rotkäppchen, Schattenwanderer, Puppe, Wirt, Markierungen von Henker, Schicksalswolf, Feuerteufel, Prophet); Vorhersage des Todespredigers; Lichter und Barriere von Hades; Schilde des Nekromanten; Länge des Fluchs des Weisen; Zufallsergebnisse (Verdammniswächter-Angebot, Pest-Nachbar). Zufall ausschließlich über den gespeicherten Generator.

### 4.3 Nicht als Text ergänzbar, aber am Tisch sichtbar

Diese Wirkungen sind physisch erkennbar, ohne dass ein Text etwas sagt. Sie dürfen nicht durch Ansagen verstärkt werden.

| Beobachtung | Was der Tisch daraus ableiten kann |
|---|---|
| Aufruf mit Rollennamen (DI-02) | dass die Rolle in der Partie ist; bei bedingten Schritten zusätzlich ihren Zustand |
| Spiegelwolf: Statt der hingerichteten Person stirbt die nominierende Person | dass die Hinrichtung umgelenkt wurde |
| Manipulator: Die nominierte Person stirbt sofort | dass eine Rolle mit dieser Wirkung im Spiel ist |
| Hinrichtung ohne Tod (Fenrir ab Stufe 3, Cerberus, Parasit) | dass die Person eine Schutzfähigkeit hat |
| Kutscher: drei Personen kehren gleichzeitig zurück | dass eine Wiederbelebungsrolle im Spiel ist |
| Mehrere Tode gleichzeitig (Feuerteufel, Wahnsinniger Kutscher, Liebeskummer, Ritter, Schwarze Witwe) | ein gemeinsames Muster; die Ursache nennt niemand |
| "Niemand gestorben" (Schutzengel, Rettung des Weisen, Zeitwächter, Rudel ohne Wahl) | nichts Eindeutiges, der Text ist neutral |
| Doppelspion wacht mit dem Rudel | Wölfe sehen eine weitere wache Person, ohne Rollenname |

### 4.4 Befund

- **Geändert:** Die öffentliche Ansage des Schutzgeists nannte den Rollennamen. Sie enthält jetzt weder Namen noch Rolle (OI-11 a). Die Selbstmörder-Zeile behauptete, der Ton "würde ihn verraten". Sie beschreibt jetzt die entschiedene Wirkung statt eines Fehlers (OI-07).
- **Ergänzt im Lexikon:** Detektiv und Amalia benennen ihre erlaubte Enthüllung; Spiegelwolf und Manipulator benennen die sichtbare Wirkung.
- **Keine geheime Information gefunden** in den übrigen `[ÖFFENTLICH]`-Zeilen. Die Beispiele im Rollenlexikon sind Spielleitungs- und Lernbeispiele, keine Ansagen.
- **Offen:** Randfälle in `OPEN-ISSUES.md` §5 und `DECISIONS-TO-INTEGRATE.md`.
- **PERSON-PRIVAT-Zeile für `koenig-lykaon`:** Sie folgt der Meldung des Regelkerns (`LYCAON_NOTICE`), ist aber keine dokumentierte Entscheidung des Product Owners (OI-15).
- **Neue Regel Todeseffekte:** Sichtbare Folgen eines Todes werden ausgespielt und angesagt, mit Effekt und Rolle, auch in Wiederbelebungsrunden. Das ist eine bewusste Ausnahme von der Verdeckung und ändert DR-04. Beantwortet am 29.09.2026 (PE-05): Bei Liebeskummer, Kette und Verknüpfung nennt die Ansage die Rolle, von der der Effekt stammt (Loki, Rotkäppchen, Schattenwanderer), nie die der sterbenden Person. Die Länge des Fluchs des Weisen nennt sie nicht (technische Ableitung DA-23, noch zu bestätigen).
