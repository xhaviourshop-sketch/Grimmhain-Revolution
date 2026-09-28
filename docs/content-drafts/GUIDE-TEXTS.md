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

1. `[ÖFFENTLICH]` nennt nie eine geheime Rolle, ein geheimes Ziel, eine geheime Wirkung oder eine Todesursache. Erlaubt sind nur Wirkungen, die eine Entscheidung ausdrücklich veröffentlicht (Detektiv, Nachtwächter, Amalia, Schutzgeist, Zeitwächter, Wiederbelebung, Nominierung) und die allgemeinen Tod-, Tag- und Siegtexte.
2. Ein Aufruf nennt nur den Rollennamen, nie Ergebnis, Ziel oder ob die Rolle lebt (`docs/assets/NARRATOR-SCRIPT.md` §1 Regel 4). Ob und wie Rollen aufgerufen werden, deren Anwesenheit dadurch bekannt würde, ist offen (OI-01).
3. Kartenlänge: höchstens 140 Zeichen je Text und Sprache, höchstens zwei kurze Sätze. Ausnahme: die Kombizeilen der Aufrufe (Aufruf und Einschlafen zusammen).
4. Platzhalter in geschweiften Klammern (`{name}`, `{names}`, `{role}`, `{roles}`, `{count}`, `{direction}`, `{n}`) sind nur für Karten gedacht. Aufgenommene Zeilen enthalten keine Platzhalter (NARRATOR-SCRIPT §1 Regel 3).
5. Anrede: aufgerufene Rolle "du", Rudel "ihr", Tisch "alle". Der Spielleiter wird als "du" angesprochen.
6. Richtung: "links" heißt der nächste Platz im Uhrzeigersinn des App-Sitzkreises. Die Gegenprüfung am Tablet steht aus (OI-06). `{direction}` ist "links", "rechts" oder "auf beiden Seiten gleich weit".
7. Übernommen wurden die Sprechertexte aus `docs/assets/NARRATOR-SCRIPT.md` wörtlich; Ergänzungen sind in der Spalte "Auslöser, Hinweis" benannt.

## 2. Allgemeine Texte

Gilt für Nachtbeginn, Morgen, Diskussion, Nominierung, Hinrichtung und Spielende. Die `narration.*`-Zeilen sind die öffentlichen Ansagen, die `gm.*`-Zeilen die privaten Anweisungen dazu.

| Schlüssel | Kategorie | DE | EN | Auslöser, Hinweis |
|---|---|---|---|---|
| `narration.night.first_begin` | `[ÖFFENTLICH]` | Die erste Nacht senkt sich über Grimmhain. Alle schließen die Augen. | The first night falls over Grimmhain. Everyone, close your eyes. | Nacht 1; übernommen aus NARRATOR-SCRIPT |
| `narration.night.begin` | `[ÖFFENTLICH]` | Die Nacht bricht herein. Alle schließen die Augen. | Night falls. Everyone, close your eyes. | ab Nacht 2; übernommen |
| `gm.night.begin` | `[SL-PRIVAT]` | Nacht {n}. Ruf die Rollen in der angezeigten Reihenfolge auf. | Night {n}. Call the roles in the order shown. | Nachtbeginn |
| `narration.dawn.begin` | `[ÖFFENTLICH]` | Der Morgen graut über Grimmhain. Alle öffnen die Augen. | Dawn breaks over Grimmhain. Everyone, open your eyes. | Morgen; übernommen |
| `narration.morning.death_single` | `[ÖFFENTLICH]` | Diese Nacht hat ein Leben gefordert. Es ist {name}. | This night has claimed a life. It is {name}. | genau ein Tod; Namensteil ergänzt |
| `narration.morning.death_multiple` | `[ÖFFENTLICH]` | Diese Nacht hat mehrere Leben gefordert. Es sind {names}. | This night has claimed several lives. They are {names}. | mehrere Tode; Namensteil ergänzt |
| `narration.morning.no_death` | `[ÖFFENTLICH]` | In dieser Nacht ist niemand gestorben. | No one died this night. | kein Tod; übernommen |
| `narration.morning.role_reveal` | `[ÖFFENTLICH]` | {name} war {role}. | {name} was {role}. | nur wenn die Setup-Option "Rolle beim Tod aufdecken" gilt |
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
| `verdammniswaechter` | Verdammniswächter / Doom Warden | Nach der Rudelwahl: Zeig das Angebot. Er darf umlenken. | After the pack choice: show the offer. They may redirect. |
| `loki` | Loki / Loki | Nur Nacht 1: Frag, welche zwei Personen Liebende oder Rivalen werden. | Night 1 only: ask which two people become lovers or rivals. |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | Frag, wen sie wählt. Gehört die Person zu einem lebenden Paar des Loki, sterben beide am Morgen. | Ask whom they choose. If the person belongs to a living pair of Loki, both die in the morning. |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | Frag, wen sie um Zuflucht bittet. Bei Zustimmung entstehen Kette und Apfel. | Ask whom they ask for refuge. On agreement chain and apple arise. |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | Frag, mit wem er sich verknüpft. Er tut es einmal. | Ask with whom they link. They do it once. |
| `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | Stirbt er, frag, wen er verflucht, oder ob er verzichtet. | If they die, ask whom they curse, or whether they decline. |
| `koenig-lykaon` | König Lykaon / King Lycaon | Frag, ob er jetzt verwandelt. Nach drei Verzichten muss er wählen. | Ask whether they transform someone now. After three refusals they must choose. |
| `seelentauscher` | Seelentauscher / Soul Swapper | Frag einmalig nach zwei Personen, lebend oder tot. Sie tauschen die Rollen. | Ask once for two people, living or dead. They swap roles. |
| `kutscher` | Kutscher / Coachman | Ab 10 Toten: Frag, welche drei zurückkehren und wer Wolf wird. | From 10 dead: ask which three return and who becomes a wolf. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | Frag einmalig nach einer toten Person und einer freien Rolle. Keine Wolfsrolle. | Ask once for a dead person and a free role. No wolf role. |
| `rattenfaenger` | Rattenfänger / Pied Piper | Frag, wen er verzaubert: eine oder zwei unverzauberte Personen. | Ask whom they enchant: one or two people not yet enchanted. |
| `pestbringerin` | Pestbringerin / Plague Bringer | Frag, wen sie infiziert. Am Morgen zieht die App die Ausbreitung. | Ask whom they infect. In the morning the app draws the spread. |
| `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | Nacht 1: drei Markierungen. Freigeschaltet: Frag jede Nacht, wen er tötet. | Night 1: three markings. Once unlocked: ask every night whom they kill. |
| `todesprediger` | Todesprediger / Death Prophet | Nur Nacht 1: Lass ihn leise eine Nacht oder einen Tag nennen. Trag sie geheim ein. | Night 1 only: let them quietly name a night or a day. Enter it secretly. |
| `feuerteufel` | Feuerteufel / Pyromaniac | Frag, ob er ein neues Ziel markiert oder die Markierung behält. | Ask whether they mark a new target or keep the marking. |
| `voodoo-priester` | Voodoo-Priester / Voodoo Priest | Ohne lebende Puppe: Frag, wen er wählt. Nur du weißt es. | Without a living doll: ask whom they choose. Only you know. |
| `nekromant` | Nekromant / Necromancer | Frag, ob er drei Tote für einen Schild opfert. Wolf benennen: geheim bei dir. | Ask whether they sacrifice three dead for a shield. Naming a wolf: secret with you. |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | In den Nächten 3, 6, 9 ...: Frag, welchen Wolf er reißt, oder ob er verzichtet. | In nights 3, 6, 9 ...: ask which wolf they tear, or whether they decline. |
| `zeitwaechter` | Zeitwächter / Time Warden | Vor allen anderen: Frag, ob er die Nacht einfriert. Dann entfallen alle Nachtschritte. | Before all others: ask whether they freeze the night. Then all night steps drop. |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | Nacht 1: drei Markierungen. Nacht 4: Zusatzopfer je Markierten unter den ersten drei Toten. | Night 1: three markings. Night 4: extra victims per marked person among the first three dead. |
| `grabraeuber` | Grabräuber / Grave Robber | Frag einmalig nach der toten Person. Danach folgt der gestohlene Schritt. | Ask once for the dead person. After that the stolen step follows. |
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
| `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Du bist Trugbilderwolf. Dein Rudel: {names}. | You are a Decoy Wolf. Your pack: {names}. |
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
| `loki` | Loki / Loki | (ungeklärt) Information der Betroffenen offen (OI-12). | (unresolved) Information of those affected is open (OI-12). |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | (ungeklärt) Information der Verketteten offen (OI-13). | (unresolved) Information of the chained person is open (OI-13). |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | (entfällt) Der verfluchten Person wird nichts gezeigt. | (not applicable) The cursed person is shown nothing. |
| `koenig-lykaon` | König Lykaon / King Lycaon | (ungeklärt) Information der verwandelten Person offen (OI-15). | (unresolved) Information of the transformed person is open (OI-15). |
| `seelentauscher` | Seelentauscher / Soul Swapper | An jede lebende betroffene Person: Deine neue Rolle: {role}. | To each living affected person: Your new role: {role}. |
| `kutscher` | Kutscher / Coachman | An jede zurückgeholte Person: Du lebst wieder. Deine Rolle: {role}. | To each returned person: You are alive again. Your role: {role}. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | An die zurückgeholte Person: Du lebst wieder. Deine neue Rolle: {role}. | To the returned person: You are alive again. Your new role: {role}. |
| `rattenfaenger` | Rattenfänger / Pied Piper | (ungeklärt) Information der Verzauberten offen (OI-17). | (unresolved) Information of the enchanted is open (OI-17). |
| `pestbringerin` | Pestbringerin / Plague Bringer | (ungeklärt) Information der Infizierten offen (OI-17). | (unresolved) Information of the infected is open (OI-17). |
| `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `todesprediger` | Todesprediger / Death Prophet | (entfällt) Die Vorhersage geht nur an den Spielleiter. | (not applicable) The prediction goes to the game master only. |
| `feuerteufel` | Feuerteufel / Pyromaniac | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `voodoo-priester` | Voodoo-Priester / Voodoo Priest | (entfällt) Die Puppe erfährt es nicht. | (not applicable) The doll does not learn of it. |
| `nekromant` | Nekromant / Necromancer | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `zeitwaechter` | Zeitwächter / Time Warden | (entfällt) Nur Frage, keine Information. | (not applicable) Question only, no information. |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | (entfällt) Nur Wahl, keine Rückmeldung. | (not applicable) Choice only, no feedback. |
| `grabraeuber` | Grabräuber / Grave Robber | Du hast die Fähigkeit von {role} gestohlen. | You stole the ability of {role}. |
| `hades` | Hades / Hades | (entfällt) Quellen nennen keine private Anzeige. | (not applicable) Sources name no private display. |

### 3.3 `[ÖFFENTLICH]` Aufruf und Einschlafen

Entwurf nach dem Muster von `docs/assets/NARRATOR-SCRIPT.md` §3. Ob Rollen mit dadurch erkennbarer Anwesenheit beim Namen aufgerufen werden, ist offen (OI-01). Handlungszeilen ("Zeige auf ...") kennt das NARRATOR-SCRIPT nur für die Slice-Rollen; für alle weiteren Rollen sind sie offen (OI-18).

| Rollen-ID | Rolle | DE | EN |
|---|---|---|---|
| `dorfbewohner` | Dorfbewohner / Villager | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `werwolf` | Werwolf / Werewolf | Die Werwölfe erwachen und erkennen einander. Sie schlafen danach wieder ein. | The werewolves wake up and recognise each other. Afterwards they go back to sleep. |
| `schutzengel` | Schutzengel / Guardian Angel | Der Schutzengel erwacht. Der Schutzengel schläft wieder ein. | The Guardian Angel wakes up. The Guardian Angel goes back to sleep. |
| `waldhexe` | Waldhexe / Witch of the Woods | Die Waldhexe erwacht. Die Waldhexe schläft wieder ein. | The Witch of the Woods wakes up. The Witch of the Woods goes back to sleep. |
| `das-orakel` | Das Orakel / The Oracle | Das Orakel erwacht. Das Orakel schläft wieder ein. | The Oracle wakes up. The Oracle goes back to sleep. |
| `wolfskind` | Wolfskind / Wolf Child | Das Wolfskind erwacht. Das Wolfskind schläft wieder ein. | The Wolf Child wakes up. The Wolf Child goes back to sleep. |
| `lehrling` | Lehrling / Apprentice | Der Lehrling erwacht. Der Lehrling schläft wieder ein. | The Apprentice wakes up. The Apprentice goes back to sleep. |
| `manipulator` | Manipulator / Manipulator | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `spiegelwolf` | Spiegelwolf / Mirror Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `sensentraeger` | Sensenträger / Reaper | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `doppelspion` | Doppelspion / Double Agent | Kein eigener Aufruf. Wacht im Rudelaufruf mit, ohne genannt zu werden. | No call of its own. Wakes within the pack call without being named. |
| `selbstmoerder` | Selbstmörder / Death Seeker | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `dorfchronistin` | Dorfchronistin / Village Chronicler | Die Dorfchronistin erwacht. Die Dorfchronistin schläft wieder ein. | The Village Chronicler wakes up. The Village Chronicler goes back to sleep. |
| `die-gebundenen` | Die Gebundenen / The Bound | Die Gebundenen erwachen. Sie schlafen wieder ein. | The Bound wake up. They go back to sleep. |
| `waldlaeufer` | Waldläufer / Ranger | Der Waldläufer erwacht. Der Waldläufer schläft wieder ein. | The Ranger wakes up. The Ranger goes back to sleep. |
| `doktor` | Doktor / Doctor | Der Doktor erwacht. Der Doktor schläft wieder ein. | The Doctor wakes up. The Doctor goes back to sleep. |
| `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `nachtwaechter` | Nachtwächter / Night Warden | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `dorfwache` | Dorfwache / Village Guard | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `besessener-wolf` | Besessener Wolf / Possessed Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `ritter` | Ritter / Knight | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `faehrtenleser` | Fährtenleser / Tracker | Der Fährtenleser erwacht. Der Fährtenleser schläft wieder ein. | The Tracker wakes up. The Tracker goes back to sleep. |
| `blutwolf` | Blutwolf / Blood Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `korrupter-richter` | Korrupter Richter / Corrupt Judge | Der Korrupte Richter erwacht. Der Korrupte Richter schläft wieder ein. | The Corrupt Judge wakes up. The Corrupt Judge goes back to sleep. |
| `waechter-am-tor` | Wächter am Tor / Gatewarden | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `spuerhund` | Spürhund / Scent Hound | Der Spürhund erwacht. Der Spürhund schläft wieder ein. | The Scent Hound wakes up. The Scent Hound goes back to sleep. |
| `parasit` | Parasit / Parasite | Der Parasit erwacht. Der Parasit schläft wieder ein. | The Parasite wakes up. The Parasite goes back to sleep. |
| `schattenhund` | Schattenhund / Shadow Hound | Der Schattenhund erwacht. Der Schattenhund schläft wieder ein. | The Shadow Hound wakes up. The Shadow Hound goes back to sleep. |
| `albtraumwolf` | Albtraumwolf / Nightmare Wolf | Der Albtraumwolf erwacht. Der Albtraumwolf schläft wieder ein. | The Nightmare Wolf wakes up. The Nightmare Wolf goes back to sleep. |
| `giftwolf` | Giftwolf / Poison Wolf | Der Giftwolf erwacht. Der Giftwolf schläft wieder ein. | The Poison Wolf wakes up. The Poison Wolf goes back to sleep. |
| `rudelvater` | Rudelvater / Packfather | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `seuchenwolf` | Seuchenwolf / Blight Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `fenrir` | Fenrir / Fenrir | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `cerberus` | Cerberus / Cerberus | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `henker` | Henker / Executioner | Der Henker erwacht. Der Henker schläft wieder ein. | The Executioner wakes up. The Executioner goes back to sleep. |
| `traumdeuter` | Traumdeuter / Dreamer | Der Traumdeuter erwacht. Der Traumdeuter schläft wieder ein. | The Dreamer wakes up. The Dreamer goes back to sleep. |
| `kopfgeldjaeger` | Kopfgeldjäger / Bounty Hunter | Der Kopfgeldjäger erwacht. Der Kopfgeldjäger schläft wieder ein. | The Bounty Hunter wakes up. The Bounty Hunter goes back to sleep. |
| `koenig` | König / King | Der König erwacht. Der König schläft wieder ein. | The King wakes up. The King goes back to sleep. |
| `kriegerin-des-lichts` | Kriegerin des Lichts / Warrior of Light | Die Kriegerin des Lichts erwacht. Die Kriegerin des Lichts schläft wieder ein. | The Warrior of Light wakes up. The Warrior of Light goes back to sleep. |
| `blutpriester` | Blutpriester / Blood Priest | Der Blutpriester erwacht. Der Blutpriester schläft wieder ein. | The Blood Priest wakes up. The Blood Priest goes back to sleep. |
| `amalia` | Amalia / Amalia | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `detektiv` | Detektiv / Detective | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `die-ewigen` | Die Ewigen / The Eternal Ones | Die Ewigen erwachen. Sie schlafen wieder ein. | The Eternal Ones wake up. They go back to sleep. |
| `der-weise` | Der Weise / The Elder | Kein Nachtschritt, kein Aufruf. | No night step, no call. |
| `maertyrerin` | Märtyrerin / Martyr | Die Märtyrerin erwacht. Die Märtyrerin schläft wieder ein. | The Martyr wakes up. The Martyr goes back to sleep. |
| `schutzgeist` | Schutzgeist / Guardian Spirit | Der Schutzgeist erwacht. Der Schutzgeist schläft wieder ein. | The Guardian Spirit wakes up. The Guardian Spirit goes back to sleep. |
| `dorfschmied` | Dorfschmied / Village Blacksmith | Der Dorfschmied erwacht. Der Dorfschmied schläft wieder ein. | The Village Blacksmith wakes up. The Village Blacksmith goes back to sleep. |
| `verdammniswaechter` | Verdammniswächter / Doom Warden | Der Verdammniswächter erwacht. Der Verdammniswächter schläft wieder ein. | The Doom Warden wakes up. The Doom Warden goes back to sleep. |
| `loki` | Loki / Loki | Loki erwacht. Loki schläft wieder ein. | Loki wakes up. Loki goes back to sleep. |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | Die Schwarze Witwe erwacht. Die Schwarze Witwe schläft wieder ein. | The Black Widow wakes up. The Black Widow goes back to sleep. |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | Rotkäppchen erwacht. Rotkäppchen schläft wieder ein. | Little Red Riding Hood wakes up. Little Red Riding Hood goes back to sleep. |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | Der Schattenwanderer erwacht. Der Schattenwanderer schläft wieder ein. | The Shadowwalker wakes up. The Shadowwalker goes back to sleep. |
| `daemonischer-wolf` | Dämonischer Wolf / Demonic Wolf | Kein eigener Aufruf. Wacht im Rudelaufruf mit. | No call of its own. Wakes within the pack call. |
| `koenig-lykaon` | König Lykaon / King Lycaon | König Lykaon erwacht. König Lykaon schläft wieder ein. | King Lycaon wakes up. King Lycaon goes back to sleep. |
| `seelentauscher` | Seelentauscher / Soul Swapper | Der Seelentauscher erwacht. Der Seelentauscher schläft wieder ein. | The Soul Swapper wakes up. The Soul Swapper goes back to sleep. |
| `kutscher` | Kutscher / Coachman | Der Kutscher erwacht. Der Kutscher schläft wieder ein. | The Coachman wakes up. The Coachman goes back to sleep. |
| `dr-victor-frankenstein` | Dr. Victor Frankenstein / Dr. Victor Frankenstein | Dr. Victor Frankenstein erwacht. Dr. Victor Frankenstein schläft wieder ein. | Dr. Victor Frankenstein wakes up. Dr. Victor Frankenstein goes back to sleep. |
| `rattenfaenger` | Rattenfänger / Pied Piper | Der Rattenfänger erwacht. Der Rattenfänger schläft wieder ein. | The Pied Piper wakes up. The Pied Piper goes back to sleep. |
| `pestbringerin` | Pestbringerin / Plague Bringer | Die Pestbringerin erwacht. Die Pestbringerin schläft wieder ein. | The Plague Bringer wakes up. The Plague Bringer goes back to sleep. |
| `prophet-des-untergangs` | Prophet des Untergangs / Prophet of Doom | Der Prophet des Untergangs erwacht. Der Prophet des Untergangs schläft wieder ein. | The Prophet of Doom wakes up. The Prophet of Doom goes back to sleep. |
| `todesprediger` | Todesprediger / Death Prophet | Der Todesprediger erwacht. Der Todesprediger schläft wieder ein. | The Death Prophet wakes up. The Death Prophet goes back to sleep. |
| `feuerteufel` | Feuerteufel / Pyromaniac | Der Feuerteufel erwacht. Der Feuerteufel schläft wieder ein. | The Pyromaniac wakes up. The Pyromaniac goes back to sleep. |
| `voodoo-priester` | Voodoo-Priester / Voodoo Priest | Der Voodoo-Priester erwacht. Der Voodoo-Priester schläft wieder ein. | The Voodoo Priest wakes up. The Voodoo Priest goes back to sleep. |
| `nekromant` | Nekromant / Necromancer | Der Nekromant erwacht. Der Nekromant schläft wieder ein. | The Necromancer wakes up. The Necromancer goes back to sleep. |
| `rachsuechtiger-wolf` | Rachsüchtiger Wolf / Lone Wolf | Der Rachsüchtige Wolf erwacht. Der Rachsüchtige Wolf schläft wieder ein. | The Lone Wolf wakes up. The Lone Wolf goes back to sleep. |
| `zeitwaechter` | Zeitwächter / Time Warden | Der Zeitwächter erwacht. Der Zeitwächter schläft wieder ein. | The Time Warden wakes up. The Time Warden goes back to sleep. |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | Der Schicksalswolf erwacht. Der Schicksalswolf schläft wieder ein. | The Fate Wolf wakes up. The Fate Wolf goes back to sleep. |
| `grabraeuber` | Grabräuber / Grave Robber | Der Grabräuber erwacht. Der Grabräuber schläft wieder ein. | The Grave Robber wakes up. The Grave Robber goes back to sleep. |
| `hades` | Hades / Hades | Hades erwacht. Hades schläft wieder ein. | Hades wakes up. Hades goes back to sleep. |

### 3.4 `[ÖFFENTLICH]` Öffentliche Wirkung

Nur Wirkungen, die eine Entscheidung ausdrücklich veröffentlicht. Alle anderen Rollen erscheinen öffentlich ausschließlich über die allgemeinen Tod-, Morgen-, Tag- und Siegtexte aus Abschnitt 2.

| Rollen-ID | Rolle | DE | EN |
|---|---|---|---|
| `dorfbewohner` | Dorfbewohner / Villager | (keine zusätzliche Ansage) | (no additional announcement) |
| `werwolf` | Werwolf / Werewolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `schutzengel` | Schutzengel / Guardian Angel | (keine zusätzliche Ansage) | (no additional announcement) |
| `waldhexe` | Waldhexe / Witch of the Woods | (keine zusätzliche Ansage) | (no additional announcement) |
| `das-orakel` | Das Orakel / The Oracle | (keine zusätzliche Ansage) | (no additional announcement) |
| `wolfskind` | Wolfskind / Wolf Child | (keine; der Aufruf hängt von der Aufrufpolitik ab (OI-01)) | (none; the call depends on the call policy (OI-01)) |
| `lehrling` | Lehrling / Apprentice | (keine; der Aufruf hängt von der Aufrufpolitik ab (OI-01)) | (none; the call depends on the call policy (OI-01)) |
| `manipulator` | Manipulator / Manipulator | (keine zusätzliche Ansage) | (no additional announcement) |
| `spiegelwolf` | Spiegelwolf / Mirror Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `trugbilderwolf` | Trugbilderwolf / Decoy Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `sensentraeger` | Sensenträger / Reaper | (keine zusätzliche Ansage) | (no additional announcement) |
| `siegreicher-wolf` | Siegreicher Wolf / Victorious Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `doppelspion` | Doppelspion / Double Agent | (keine; der Rudelaufruf nennt ihn nicht) | (none; the pack call does not name them) |
| `selbstmoerder` | Selbstmörder / Death Seeker | (keine Ansage; ein Ton bei 5 Toten würde ihn verraten (OI-07)) | (no announcement; a sound at 5 dead would reveal them (OI-07)) |
| `dorfchronistin` | Dorfchronistin / Village Chronicler | (keine zusätzliche Ansage) | (no additional announcement) |
| `die-gebundenen` | Die Gebundenen / The Bound | (keine zusätzliche Ansage) | (no additional announcement) |
| `waldlaeufer` | Waldläufer / Ranger | (keine zusätzliche Ansage) | (no additional announcement) |
| `doktor` | Doktor / Doctor | (keine zusätzliche Ansage) | (no additional announcement) |
| `wahnsinniger-kutscher` | Wahnsinniger Kutscher / Mad Coachman | (keine zusätzliche Ansage) | (no additional announcement) |
| `nachtwaechter` | Nachtwächter / Night Warden | Die Glocken läuten. Etwas stimmt nicht. | The bells ring. Something is wrong. |
| `dorfwache` | Dorfwache / Village Guard | (keine zusätzliche Ansage) | (no additional announcement) |
| `besessener-wolf` | Besessener Wolf / Possessed Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `ritter` | Ritter / Knight | (keine zusätzliche Ansage) | (no additional announcement) |
| `faehrtenleser` | Fährtenleser / Tracker | (keine zusätzliche Ansage) | (no additional announcement) |
| `blutwolf` | Blutwolf / Blood Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `korrupter-richter` | Korrupter Richter / Corrupt Judge | {name} ist nominiert. | {name} is nominated. |
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
| `detektiv` | Detektiv / Detective | Der nächste Wolf sitzt {direction} vom Platz von {name}. | The nearest wolf sits {direction} of {name}'s seat. |
| `die-ewigen` | Die Ewigen / The Eternal Ones | (keine zusätzliche Ansage) | (no additional announcement) |
| `der-weise` | Der Weise / The Elder | (keine öffentliche Ansage; Länge des Fluchs wird nicht genannt (OI-11)) | (no public announcement; the curse length is not named (OI-11)) |
| `maertyrerin` | Märtyrerin / Martyr | (keine zusätzliche Ansage) | (no additional announcement) |
| `schutzgeist` | Schutzgeist / Guardian Spirit | Der Schutzgeist hat einen Wolf gewählt. | The Guardian Spirit chose a wolf. |
| `dorfschmied` | Dorfschmied / Village Blacksmith | (keine zusätzliche Ansage) | (no additional announcement) |
| `verdammniswaechter` | Verdammniswächter / Doom Warden | (keine zusätzliche Ansage) | (no additional announcement) |
| `loki` | Loki / Loki | (keine zusätzliche Ansage) | (no additional announcement) |
| `schwarze-witwe` | Schwarze Witwe / Black Widow | (keine zusätzliche Ansage) | (no additional announcement) |
| `rotkaeppchen` | Rotkäppchen / Little Red Riding Hood | (keine zusätzliche Ansage) | (no additional announcement) |
| `schattenwanderer` | Schattenwanderer / Shadowwalker | (keine zusätzliche Ansage) | (no additional announcement) |
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
| `zeitwaechter` | Zeitwächter / Time Warden | Die Zeit stand still. Diese Nacht ist ausgefallen. | Time stood still. This night was skipped. |
| `schicksalswolf` | Schicksalswolf / Fate Wolf | (keine zusätzliche Ansage) | (no additional announcement) |
| `grabraeuber` | Grabräuber / Grave Robber | (keine zusätzliche Ansage) | (no additional announcement) |
| `hades` | Hades / Hades | (keine zusätzliche Ansage) | (no additional announcement) |

