# Rollenlexikon 03 · Dorf, Bindung, Wandlung, Wiederbelebung, Sonstiges (10 Rollen)

**Status:** Entwurf, nicht freigegeben. Regelquelle: `audit/all-72-roles` @ `312f5bbbbec4c218754b35a0043b51e79d80bcf5`. Begriffe siehe [`../TERMINOLOGY.md`](../TERMINOLOGY.md).
**Paket 5b (29.09.2026):** Gegen Decision Log, Kern und Tests geprüft und als `ui.role.<rolle>.lex.*` ins Programm übernommen (Rollenlexikon). Maßgeblich für das Programm ist der Wortlaut in `godot/content/i18n/ui.*.po`. Die Zeile „Offen / Open“ nennt ungeklärte, technisch abgeleitete und unbestätigte oder noch nicht umgesetzte Punkte. Redaktionelle Endabnahme ausstehend.
Kopfzeile je Rolle: Nachtstufe = `night_priority` des Katalogs geteilt durch zehn.

Enthalten: `wolfskind`, `lehrling`, `loki`, `rotkaeppchen`, `seelentauscher`, `kutscher`, `dr-victor-frankenstein`, `wahnsinniger-kutscher`, `henker`, `korrupter-richter`.

---

## `wolfskind` · Wolfskind / Wolf Child

**Fraktion / Faction:** Dorf, nach der Verwandlung Werwölfe / Village, after transformation Werewolves · **Nachtschritt / Night step:** Vorbildwahl, Stufe 0.9, nur solange ohne Vorbild / role model choice, stage 0.9, only while without a role model · **Zählt als Wolf / Counts as wolf:** erst nach der Verwandlung / only after transformation · **Status:** Regel entschieden

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Wählt ein Vorbild und wird bei dessen Tod zum Wolf. | Chooses a role model and becomes a wolf when the model dies. |
| Zeitpunkt, Limit / Timing, limit | Der Schritt kommt in jeder Nacht, solange das Wolfskind lebt, unverwandelt ist und kein Vorbild hat. Ein regulär gestartetes Wolfskind wählt in Nacht 1. Er darf nicht übersprungen werden. | The step occurs every night while the Wolf Child lives, is untransformed and has no role model. A regularly started Wolf Child chooses in night 1. It cannot be skipped. |
| Ziele / Targets | Genau eine andere lebende Person. Es darf sich nicht selbst wählen. | Exactly one other living person. The Wolf Child may not choose themself. |
| Ausnahmen / Exceptions | Stirbt das Vorbild mit Todesfolgen, verwandelt sich das Wolfskind sofort und vor der Siegprüfung dieses Todes: Fraktion Werwölfe, zählt als Wolf, erscheint als Werwolf, die Rolle bleibt Wolfskind. Am Rudel nimmt es ab der folgenden Nacht teil. Ein Tod per Spielleiterkorrektur ohne Todesfolgen verwandelt nicht. Ein totes Wolfskind verwandelt sich für diesen Tod nie, auch nicht nach einer Wiederbelebung. Ein erneuter Tod des wiederbelebten Vorbilds kann verwandeln. Ein Wächter am Tor macht es stattdessen zum Dorfbewohner. Im Fluch des Weisen ruht die Verwandlung. | If the role model dies with consequences, the Wolf Child transforms at once and before the win check of that death: faction werewolves, counts as a wolf, appears as Werewolf, the role stays Wolf Child. The Wolf Child joins the pack from the following night. A death by game master correction without consequences does not transform. A dead Wolf Child never transforms for that death, not even after revival. A renewed death of the revived role model can transform. A Gatewarden makes them a Villager instead. During the Elder's curse the transformation rests. |
| Sieg / Win | Vor der Verwandlung mit dem Dorf, danach mit den Werwölfen. | Before the transformation with the village, afterwards with the werewolves. |
| Beispiel 1 / Example 1 | In Nacht 1 wählt Clara, das Wolfskind, Ben als Vorbild. An Tag 3 wird Ben hingerichtet. Clara wird sofort zum Wolf und wacht ab der folgenden Nacht mit dem Rudel auf. | In night 1 Clara, the Wolf Child, chooses Ben as role model. On day 3 Ben is executed. Clara becomes a wolf at once and wakes with the pack from the following night. |
| Beispiel 2 / Example 2 | Der Spielleiter setzt Bens Tod per Korrektur ohne Todesfolgen. Clara bleibt Dorf. | The game master sets Ben's death by correction without consequences. Clara stays in the village. |
| Spielleitung / Game master | Das Orakel sieht vor der Verwandlung "Wolfskind", danach "Werwolf". Die Waldhexe sieht immer "Wolfskind". Wer Vorbild ist, weiß nur das Wolfskind und du. | The Oracle sees "Wolf Child" before the transformation and "Werewolf" after. The Witch always sees "Wolf Child". Only the Wolf Child and you know who the role model is. |

Quelle: DECISION-LOG DR-10, "Wolfskind · Produktionsrolle und Verwandlung", "Rollenaudit · Querschnittsfragen"; Wächter: RM-DR-149; Fluch: S-05.

---

## `lehrling` · Lehrling / Apprentice

**Fraktion / Faction:** Dorf, nach dem Erbe die der geerbten Rolle / Village, after inheritance that of the inherited role · **Nachtschritt / Night step:** Auswahl in der ersten verfügbaren Nacht ohne Bindung, Stufe 1.1 / choice in the first available night without a bond, stage 1.1 · **Zählt als Wolf / Counts as wolf:** nur bei geerbter Wolfsrolle / only with an inherited wolf role · **Status:** Regel entschieden

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Wählt einen Meister und erbt bei dessen Tod die Rolle. | Chooses a master and inherits the role when the master dies. |
| Zeitpunkt, Limit / Timing, limit | Die Auswahl kommt in der ersten verfügbaren Nacht ohne aktive Bindung. Sie darf nicht übersprungen werden. Gibt es weniger als drei andere Lebende, entfällt sie mit Protokolleintrag. | The choice appears in the first available night without an active bond. It cannot be skipped. If fewer than three other people are alive, it is dropped with a log entry. |
| Ziele / Targets | Der Spielleiter wählt drei verschiedene andere lebende Personen. Der Lehrling sieht nur deren drei aktuelle Rollen, nach Rollen-ID sortiert, nie Namen. Er wählt eine Rolle, nie eine Person. | The game master chooses three different other living people. The Apprentice sees only their three current roles, sorted by role ID, never names. They choose a role, never a person. |
| Ausnahmen / Exceptions | Stirbt der Meister mit Todesfolgen, erbt der Lehrling sofort die aktuelle Rolle: Fraktion, passive Eigenschaften, Siegbedingung und Todesreaktion gelten sofort, aktive Nachtfähigkeiten ab der folgenden Nacht, alle Einsätze frisch. Stirbt der Lehrling vor dem Erbe, verfällt die Bindung endgültig. Ein Meistertod per Korrektur ohne Todesfolgen vererbt nichts. Ein Wächter am Tor macht aus einer geerbten Wolfsrolle einen Dorfbewohner. | If the master dies with consequences, the Apprentice inherits the current role at once: faction, passive traits, win condition and death reaction apply at once, active night abilities from the following night, all uses fresh. If the Apprentice dies before the inheritance, the bond ends for good. A master's death by correction without consequences passes nothing on. A Gatewarden turns an inherited wolf role into a Villager. |
| Sieg / Win | Vor dem Erbe mit dem Dorf, danach nach der geerbten Rolle. | Before the inheritance with the village, afterwards according to the inherited role. |
| Beispiel 1 / Example 1 | Der Spielleiter wählt Ben, Clara und Emil. Der Lehrling sieht "Dorfbewohner, Waldhexe, Werwolf" und wählt "Waldhexe", die zu Clara gehört. Stirbt Clara, wird der Lehrling Waldhexe mit frischen Tränken, einsetzbar ab der folgenden Nacht. | The game master chooses Ben, Clara and Emil. The Apprentice sees "Villager, Witch of the Woods, Werewolf" and chooses "Witch of the Woods", which belongs to Clara. When Clara dies, the Apprentice becomes the Witch with fresh potions, usable from the following night. |
| Beispiel 2 / Example 2 | Der Lehrling wählt "Werwolf", die zu Emil gehört. Emil wird hingerichtet. Der Lehrling zählt sofort als Wolf und wacht ab der folgenden Nacht mit dem Rudel auf. | The Apprentice chooses "Werewolf", which belongs to Emil. Emil is executed. The Apprentice counts as a wolf at once and wakes with the pack from the following night. |
| Spielleitung / Game master | Die Bindung ist nur für dich sichtbar. Erbt der Lehrling Wolfskind, bleibt es unverwandelt, er wählt in der nächsten Nacht ein neues Vorbild. Erbt er Lehrling, folgt die neue Auswahl in der nächsten Nacht. | The bond is visible only to you. If the Apprentice inherits Wolf Child, it stays untransformed and they choose a new role model next night. If they inherit Apprentice, the new choice follows next night. |

Quelle: DECISION-LOG DR-11, "Präzisierungen zu DR-08 und DR-11", "Korrekturrunde Regelkern" (Nr. 2, 3), "Lehrling · Produktionsrolle, verdeckte Auswahl und Erbe"; Wächter: RM-DR-149.

---

## `loki` · Loki / Loki

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** nur Nacht 1, Stufe 0.4 / night 1 only, stage 0.4 · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden, Information der Betroffenen durch Antwort des Product Owners festgelegt (nicht im Decision Log)

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Verbindet in der ersten Nacht zwei Personen als Liebende oder Rivalen. | Links two people as lovers or rivals in the first night. |
| Zeitpunkt, Limit / Timing, limit | Nur in Nacht 1 der Partie, freiwillig. Verpasst Loki die Nacht, verfällt die Fähigkeit. | Night 1 of the game only, optional. If Loki misses the night, the ability expires. |
| Ziele / Targets | Zwei verschiedene lebende Personen, Loki selbst ist erlaubt. | Two different living people, Loki themself is allowed. |
| Ausnahmen / Exceptions | Stirbt ein Liebender, stirbt der andere sofort an Liebeskummer (eigene Ursache). Der Schutz gegen den Rudelangriff hilft dagegen nicht, persönliche Schilde schon. Rivalen können nicht gewinnen, solange der andere Rivale lebt; die Siegprüfung zählt sie dann nicht als Gewinner. Stirbt einer, gilt für den anderen wieder sein Team. Außerdem zählen sie für die Schwarze Witwe. Liebeskummer wirkt auch im Fluch des Weisen. Eine einmal durch Tod beendete Bindung bleibt nach einer Wiederbelebung beendet. | If one lover dies, the other dies at once of heartbreak (own cause). Protection against the pack attack does not help against it, personal shields do. Rivals cannot win while the other rival lives; the win check does not count them as winners then. If one dies, the other wins with their team again. They also matter to the Black Widow. Heartbreak also works during the Elder's curse. A bond once ended by death stays ended after a revival. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | Loki verbindet Anna und Ben als Liebende. An Tag 2 wird Anna hingerichtet. Ben stirbt sofort an Liebeskummer. | Loki links Anna and Ben as lovers. On day 2 Anna is executed. Ben dies at once of heartbreak. |
| Beispiel 2 / Example 2 | Loki verbindet Clara und David als Rivalen. Clara und David leben, das Dorf siegt: Beide stehen nicht unter den Gewinnern. Stirbt Clara, gewinnt David wieder mit dem Dorf. | Loki links Clara and David as rivals. Clara and David are alive and the village wins: neither is among the winners. If Clara dies, David wins with the village again. |
| Spielleitung / Game master | Einen echten Schritt hat Loki nur in Nacht 1. In späteren Nächten wird Loki weiter aufgerufen, aber nur angesagt, damit der Tisch nichts erfährt; die App zeigt diese Ansage. Liebende und Rivalen erfahren privat ihren Partner und die Art der Bindung. Der Tod durch Liebeskummer ist ein Todeseffekt und wird öffentlich angesagt. Die Ansage nennt Loki als Rolle, von der die Bindung stammt, nie die Rolle der sterbenden Person. | Loki has a real step only in night 1. In later nights Loki is still called, but only announced, so that the table learns nothing; the app shows this announcement. Lovers and rivals learn their partner and the kind of bond privately. The death by heartbreak is a death effect and is announced publicly. The announcement names Loki as the role the bond comes from, never the role of the dying person. |

Quelle: DECISION-LOG "Rollenaudit · Bindungsrollen" (B-01, B-02, B-05, B-08, RM-DR-011.2; RM-DR-101).

---

## `rotkaeppchen` · Rotkäppchen / Little Red Riding Hood

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** jede Nacht, Stufe 7.4 / every night, stage 7.4 · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden, Information der Gefragten festgelegt (nicht im Decision Log)

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Sucht jede Nacht Zuflucht. Wer sie gewährt, erhält einen Apfel und eine Todeskette. | Seeks refuge every night. Whoever grants it receives an apple and a death chain. |
| Zeitpunkt, Limit / Timing, limit | Jede Nacht, solange Rotkäppchen lebt. | Every night while Little Red Riding Hood lives. |
| Ziele / Targets | Eine andere lebende Person, auch ein Wolf, der ablehnen darf. Dieselbe Person darf wieder gefragt werden. | One other living person, a wolf included, who may decline. The same person may be asked again. |
| Ausnahmen / Exceptions | Gewährt die Person Zuflucht, sind sie und Rotkäppchen verkettet: Stirbt eine, stirbt die andere sofort mit. Die Kette gilt bis zur nächsten gewährten Zuflucht. Eine Ablehnung löst nichts aus. Der Apfel lässt den nächsten Nachtschritt der Person, den ihre Rolle jede Nacht hat, ein zweites Mal laufen. Er gilt nur in der folgenden Nacht, ungenutzt verfällt er, und jede Person hat höchstens einen. Für Einmal- und Ladungsfähigkeiten, passive Rollen sowie Korrupten Richter, Parasit, Verdammniswächter und Rotkäppchen ist er wirkungslos. Die Kette wirkt auch im Fluch des Weisen. | If the person grants refuge, they and Little Red Riding Hood are chained: if one dies, the other dies at once too. The chain lasts until the next granted refuge. A refusal triggers nothing. The apple lets the person's next night step, which their role has every night, run a second time. It only applies in the following night, expires if unused, and each person has at most one. It has no effect for once-only and charge abilities, passive roles, and for the Corrupt Judge, Parasite, Doom Warden and Little Red Riding Hood. The chain also works during the Elder's curse. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | Rotkäppchen fragt Ben, Ben gewährt Zuflucht. In der folgenden Nacht führt Ben, ein Doktor, den Schritt zweimal aus. An Tag 4 wird Ben hingerichtet, und Rotkäppchen stirbt sofort mit. | Little Red Riding Hood asks Ben, Ben grants refuge. In the following night Ben, a Doctor, performs the step twice. On day 4 Ben is executed and Little Red Riding Hood dies at once too. |
| Beispiel 2 / Example 2 | Rotkäppchen fragt Emil, einen Wolf. Emil lehnt ab. Es entsteht keine Kette und kein Apfel. | Little Red Riding Hood asks Emil, a wolf. Emil declines. No chain and no apple arise. |
| Spielleitung / Game master | Die gefragte Person beantwortet die Frage selbst. Fähigkeiten und ihre Effekte sind allen Personen bekannt: Die gefragte Person kennt Apfel und Kette und darf ablehnen, erfährt aber nicht, wer fragt. Ihre Karte nennt deshalb weder die Rolle noch die fragende Person. Der Tod durch die Kette ist ein Todeseffekt und wird öffentlich angesagt. Die Ansage nennt Rotkäppchen als Rolle, von der die Kette stammt, nie die Rolle der sterbenden Person. | The chosen person answers the question themself. Abilities and their effects are known to all people: the chosen person knows apple and chain and may decline, but does not learn who asks. Their card therefore names neither the role nor the person asking. The death through the chain is a death effect and is announced publicly. The announcement names Little Red Riding Hood as the role the chain comes from, never the role of the dying person. |
| Offen / Open | Wie die gefragte Person am Tisch geweckt und befragt wird, ist noch nicht festgelegt. | How the chosen person is woken and asked at the table is not yet settled. |

Quelle: DECISION-LOG "Rollenaudit · Bindungsrollen" (R-01 bis R-04, B-08; RM-DR-137).

---

## `seelentauscher` · Seelentauscher / Soul Swapper

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** jede Nacht bis zur Nutzung, Stufe 8.0 / every night until used, stage 8.0 · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Tauscht einmal die Rollen zweier Personen, lebend oder tot. | Swaps the roles of two people once, living or dead. |
| Zeitpunkt, Limit / Timing, limit | Einmal je Leben, jede Nacht bis zur Nutzung, freiwillig (Verzicht ist möglich). | Once per life, every night until used, optional (declining is allowed). |
| Ziele / Targets | Zwei verschiedene Personen, lebend oder tot. Der Seelentauscher selbst ist erlaubt. | Two different people, living or dead. The Soul Swapper themself is allowed. |
| Ausnahmen / Exceptions | Beide erhalten die neue Rolle wie beim Lehrling-Erbe: frische Einsätze, keine übernommenen Bindungen (ein Wolfskind hat kein Vorbild, eine Lehrlingsbindung endet). Eine Pflicht-Scheinrolle des Trugbilderwolfs wandert mit. Lebende Betroffene erfahren ihre neue Rolle sofort und privat. Ein lebender Wächter am Tor macht auch bei einer toten Person aus einer erhaltenen Wolfsrolle einen Dorfbewohner. Im Fluch des Weisen ruht die Fähigkeit. | Both receive the new role as with an Apprentice inheritance: fresh uses, no carried-over bonds (a Wolf Child has no role model, an Apprentice bond ends). A Decoy Wolf's mandatory false role moves along. Living people affected learn their new role at once and privately. A living Gatewarden turns a received wolf role into a Villager even for a dead person. During the Elder's curse the ability rests. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | In Nacht 3 tauscht der Seelentauscher Ben (Waldhexe) und Emil (Werwolf). Ben ist nun Werwolf, Emil Waldhexe. Beide sehen ihre neue Rolle privat. | In night 3 the Soul Swapper swaps Ben (Witch of the Woods) and Emil (Werewolf). Ben is now a Werewolf, Emil the Witch. Both see their new role privately. |
| Beispiel 2 / Example 2 | Ein Wächter am Tor lebt. Ben würde die Rolle Werwolf erhalten und wird stattdessen Dorfbewohner. Emil wird Waldhexe. | A Gatewarden is alive. Ben would receive the role Werewolf and becomes a Villager instead. Emil becomes the Witch. |
| Spielleitung / Game master | Der Tisch erfährt nichts. Ein toter Betroffener sieht keine Mitteilung, ein lebender schon. | The table learns nothing. A dead person affected sees no message, a living one does. |

Quelle: DECISION-LOG "Rollenaudit · Verwandlungsrollen" (V-04, V-05, V-06; RM-DR-127); Fluch: S-05.

---

## `kutscher` · Kutscher / Coachman

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** ab einer Nacht mit mindestens 10 Toten, Stufe 3.8 / from a night with at least 10 dead, stage 3.8 · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden, Totenkarten zurückgestellt

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Holt ab zehn Toten einmal drei Tote zurück. Einer davon wird Wolf. | With ten dead, brings back three dead once. One of them becomes a wolf. |
| Zeitpunkt, Limit / Timing, limit | Einmal je Leben, freiwillig, ab einer Nacht mit mindestens 10 Toten (alle zählen). | Once per life, optional, from a night with at least 10 dead (all count). |
| Ziele / Targets | Drei tote Personen. Der Kutscher bestimmt, wer davon Wolf wird. | Three dead people. The Coachman decides which of them becomes a wolf. |
| Ausnahmen / Exceptions | Die Wiederbelebten behalten ihre Rolle mit frischen Einsätzen, nur der bestimmte Wolf erhält die Rolle Werwolf. Ein lebender Wächter am Tor macht ihn stattdessen zum Dorfbewohner. Sie erfahren es privat, handeln ab der folgenden Nacht, und die Wiederbelebung wird am Morgen öffentlich sichtbar. | The revived keep their role with fresh uses, only the chosen wolf receives the role Werewolf. A living Gatewarden turns them into a Villager instead. They learn it privately, act from the following night, and the revival becomes publicly visible in the morning. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | In Nacht 6 sind 11 Personen tot. Der Kutscher holt Anna (Waldhexe), Ben (Dorfbewohner) und Clara (Doktor) zurück und macht Ben zum Wolf. Am Morgen wird öffentlich sichtbar, dass drei Personen zurück sind. | In night 6 11 people are dead. The Coachman brings back Anna (Witch of the Woods), Ben (Villager) and Clara (Doctor) and makes Ben a wolf. In the morning it becomes publicly visible that three people are back. |
| Beispiel 2 / Example 2 | Erst neun Personen sind tot. Der Kutscher hat keinen Schritt. | Only nine people are dead. The Coachman has no step. |
| Spielleitung / Game master | Die Wahl, wer Wolf wird, triffst nicht du, sondern der Kutscher. Der neue Wolf wacht ab der folgenden Nacht mit dem Rudel auf. | The choice of who becomes a wolf is not yours but the Coachman's. The new wolf wakes with the pack from the following night. |
| Offen / Open | Regeln zu Totenreichkarten sind noch nicht festgelegt und nicht Teil dieser Umsetzung. | Rules for underworld cards are not yet settled and not part of this implementation. |

Quelle: DECISION-LOG "Rollenaudit · Wiederbelebungsrollen" (W-01, W-02, W-03; RM-DR-126); Reset: "Rollenaudit · Wiederbelebung, Besessener Wolf, Ritter, Fährtenleser". Totenkarten: RM-DR-013 (offen, siehe OI-02).

---

## `dr-victor-frankenstein` · Dr. Victor Frankenstein / Dr. Victor Frankenstein

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** jede Nacht bis zur Nutzung, freiwillig, Stufe 3.6 / every night until used, optional, stage 3.6 · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden, Kartenbedingung zurückgestellt (OI-02)

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Belebt einmal einen Toten mit einer freien Rolle wieder. | Revives one dead person once with a free role. |
| Zeitpunkt, Limit / Timing, limit | Einmal je Leben, jede Nacht bis zur Nutzung, freiwillig. | Once per life, every night until used, optional. |
| Ziele / Targets | Eine tote Person. Sie erhält eine Rolle, die gerade niemand hat. Dorfbewohner ist immer möglich, eine Wolfsrolle nie. | One dead person. They receive a role nobody currently has. Villager is always possible, a wolf role never. |
| Ausnahmen / Exceptions | Die wiederbelebte Person startet frisch, erfährt ihre neue Rolle privat und handelt ab der folgenden Nacht. Die Wiederbelebung wird am Morgen öffentlich sichtbar. | The revived person starts fresh, learns their new role privately and acts from the following night. The revival becomes publicly visible in the morning. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | In Nacht 3 belebt Frankenstein Anna wieder und gibt ihr die freie Rolle Doktor. Anna sieht "Doktor" privat und handelt ab Nacht 4. | In night 3 Frankenstein revives Anna and gives Anna the free role Doctor. Anna sees "Doctor" privately and acts from night 4. |
| Beispiel 2 / Example 2 | Frankenstein belebt Ben wieder und wählt Dorfbewohner. Diese Rolle geht immer. | Frankenstein revives Ben and chooses Villager. That role is always possible. |
| Spielleitung / Game master | Am Morgen erscheint nur, dass jemand zurück ist, nicht die neue Rolle. | In the morning only the fact that someone is back appears, not the new role. |
| Offen / Open | Eine Kartenbedingung gehört zu den noch nicht festgelegten Totenreichkarten und ist nicht umgesetzt. | A card condition belongs to the underworld cards, which are not yet settled, and is not implemented. |

Quelle: DECISION-LOG "Rollenaudit · Wiederbelebungsrollen" (W-01, W-04; RM-DR-141.1, RM-DR-141.2); Reset: "Rollenaudit · Wiederbelebung, Besessener Wolf, Ritter, Fährtenleser".

---

## `wahnsinniger-kutscher` · Wahnsinniger Kutscher / Mad Coachman

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** keiner, passiv / none, passive · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Wird er hingerichtet, sterben seine Nachbarn mit. | If executed, their neighbours die with them. |
| Zeitpunkt, Limit / Timing, limit | Bei jeder Hinrichtung des Wahnsinnigen Kutschers, unbegrenzt oft. | At every execution of the Mad Coachman, without limit. |
| Ziele / Targets | Keine Wahl. Nachbarn sind die nächsten lebenden Personen links und rechts, tote Plätze werden übersprungen. | No choice. Neighbours are the nearest living people to the left and right; dead seats are skipped. |
| Ausnahmen / Exceptions | Nur eine echte Hinrichtung löst aus. Eine Spiegelung des Spiegelwolfs auf ihn ist keine Hinrichtung. Im Fluch des Weisen ruht die Fähigkeit. | Only a real execution triggers it. A Mirror Wolf reflection onto them is not an execution. During the Elder's curse the ability rests. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | Ben sitzt zwischen Anna und Clara und ist der Wahnsinnige Kutscher. Ben wird hingerichtet, Anna und Clara sterben mit. | Ben sits between Anna and Clara and is the Mad Coachman. Ben is executed, Anna and Clara die too. |
| Beispiel 2 / Example 2 | Der Spiegelwolf spiegelt eine Hinrichtung auf Ben, den Wahnsinnigen Kutscher. Es gibt keinen Kutscherunfall. | The Mirror Wolf reflects an execution onto Ben, the Mad Coachman. There is no coachman crash. |
| Spielleitung / Game master | Das Mitsterben der Nachbarn ist ein Todeseffekt und wird öffentlich angesagt, mit Rolle und den Namen der Mitgestorbenen. | The neighbours dying along is a death effect and is announced publicly, with the role and the names of those who died along. |

Quelle: DECISION-LOG "Rollenaudit · Waldläufer, Doktor, Sitznachbarn, Nachtwächter, Kutscher" (RM-DR-003, RM-DR-116.1, "Wahnsinniger Kutscher und Spiegelung").

---

## `henker` · Henker / Executioner

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** ab drei Hinrichtungen jede Nacht, freiwillig, Stufe 7.8 / from three executions every night, optional, stage 7.8 · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden, Randfall aus Regelkern und Test belegt

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Ab drei Hinrichtungen markiert er nachts jemanden, der bei der nächsten mitstirbt. | From three executions on, marks someone at night who dies along at the next one. |
| Zeitpunkt, Limit / Timing, limit | Jede Nacht freiwillig, sobald in der Partie mindestens drei Hinrichtungen bestätigt wurden, auch vor dem Rollenerwerb. Unbegrenzt oft. | Every night, optional, as soon as at least three executions have been confirmed in the game, even before receiving the role. Without limit. |
| Ziele / Targets | Eine Person. Sie stirbt zusätzlich bei der Hinrichtung des folgenden Tages, wenn der Henker dabei lebt. | One person. They die additionally at the following day's execution if the Executioner is alive then. |
| Ausnahmen / Exceptions | Jede bestätigte Hinrichtung zählt, auch ohne Tod (Spiegelung, Cerberus-Abwehr, Parasit). Lebt der Henker bei dieser Hinrichtung nicht mehr, verfällt die Markierung. Findet am Folgetag keine Hinrichtung statt, verfällt sie mit Beginn der nächsten Nacht. Die markierte Person stirbt auch dann mit, wenn die Hinrichtung selbst niemanden tötet (Spiegelung, Cerberus-Abwehr). Für den Selbstmörder zählt nur die Hinrichtung der Person selbst, ein zusätzlicher Henker-Tod ist keine. | Every confirmed execution counts, even without a death (reflection, Cerberus ward, Parasite). If the Executioner is not alive at that execution, the marking lapses. If no execution takes place on the following day, it lapses at the start of the next night. The marked person also dies along when the execution itself kills no one (reflection, Cerberus ward). For the Death Seeker only the execution of that person counts; an additional Executioner death is not one. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | Drei Hinrichtungen sind vorbei. In Nacht 4 markiert der Henker Clara. Am Tag 4 wird Ben hingerichtet, Clara stirbt zusammen mit Ben. | Three executions are over. In night 4 the Executioner marks Clara. On day 4 Ben is executed, Clara dies along with Ben. |
| Beispiel 2 / Example 2 | Der Henker markiert Clara und stirbt noch in derselben Nacht. Die Markierung verfällt. | The Executioner marks Clara and dies in the same night. The marking lapses. |
| Spielleitung / Game master | Die Markierung gilt nur für die Hinrichtung des folgenden Tages. Ohne Hinrichtung verfällt sie mit Beginn der nächsten Nacht. | The marking applies only to the following day's execution. Without an execution it lapses at the start of the next night. |

Quelle: DECISION-LOG "Rollenaudit · Fenrir, Cerberus, Henker" (RM-DR-130.1 bis .3, RM-DR-138.2). Ablauf ohne Hinrichtung: `rules_engine.gd` (`_start_night` löscht die Markierung), `execution_rules.gd`, Test `test_hangman_mark_expires_and_needs_living_hangman`.

---

## `korrupter-richter` · Korrupter Richter / Corrupt Judge

**Fraktion / Faction:** Dorf / Village · **Nachtschritt / Night step:** jede Nacht, freiwillig, Stufe 1.5 / every night, optional, stage 1.5 · **Zählt als Wolf / Counts as wolf:** nein / no · **Status:** Regel entschieden

| Feld / Field | DE | EN |
|---|---|---|
| Fähigkeit / Ability | Markiert nachts eine Person, die am Tag als nominiert gilt. | Marks a person at night who counts as nominated during the day. |
| Zeitpunkt, Limit / Timing, limit | Jede Nacht freiwillig. Bei Nachtbeginn wird die alte Markierung gelöscht, es gibt höchstens eine. | Every night, optional. At the start of the night the old marking is cleared, there is at most one. |
| Ziele / Targets | Eine lebende Person, der Richter selbst ist erlaubt. | One living person, the Judge themself is allowed. |
| Ausnahmen / Exceptions | Bei Tagesbeginn gilt die markierte Person als vom Richter nominiert (normale Nominierung: Tageslimit, Manipulator-Tod, Spiegelung wie sonst). Öffentlich erscheint nur die Nominierung der markierten Person, nicht der Richter. Der Apfel von Rotkäppchen wirkt hier nicht. Die Spielleiteransicht zeigt einen Hinweis "+1 Stimme auf die markierte Person", die Stimmen zählst du selbst. | At the start of the day the marked person counts as nominated by the Judge (normal nomination: daily limit, Manipulator death, reflection as usual). Only the marked person's nomination appears in public, not the Judge. Little Red Riding Hood's apple has no effect here. The game master view shows a reminder "+1 vote on the marked person"; you count the votes yourself. |
| Sieg / Win | Mit dem Dorf. | With the village. |
| Beispiel 1 / Example 1 | In Nacht 3 markiert der Richter Emil. Zu Beginn von Tag 4 ist Emil nominiert. Öffentlich heißt es nur, dass Emil nominiert ist. | In night 3 the Judge marks Emil. At the start of day 4 Emil is nominated. In public it is only said that Emil is nominated. |
| Beispiel 2 / Example 2 | Der Richter markiert sich selbst. Er ist zu Beginn des Tages nominiert. | The Judge marks themself. They are nominated at the start of the day. |
| Spielleitung / Game master | Wer nominiert hat, sagst du nie. Bei Nachtbeginn löscht die App die alte Markierung. | You never say who nominated. At the start of the night the app clears the old marking. |

Quelle: DECISION-LOG "Rollenaudit · Querschnittsfragen" (RM-DR-008, RM-DR-012); "Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor, Spürhund, Parasit" (RM-DR-117); Apfel: R-04; Hinweistext: Rollentext "automatically nominated with +1 vote" und `vote_hints.gd`.
