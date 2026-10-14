# Classic: Fähigkeiten, wie der Code sie umsetzt

Stand: 13.10.2026, Branch `classic-akt`. Gelesen aus `godot/core/rules/role_catalog.gd` (`CLASSIC_ROLES`, `CARD_NUMBERS`), den Regelstellen der jeweiligen Mechanik, `classic_rules.gd`, `classic_wolf_rules.gd`, `win_rules.gd` und `step_queue.gd`; nichts geändert. Bogentexte zum Vergleich: `docs/classic/PDF-ROLLEN.md`. Der Hauptmann ist nicht gebaut.

Nachtreihenfolge in Nacht 1 (Kartenzahl mal 10): Amor 1, Brüder und Schwestern 5, Wildes Kind 9, Engel 13, Werwölfe 20, Urwolf direkt dahinter, Weißer Wolf 22 (nur gerade Nächte), Hexe 34, Flötenspieler 42, Seherin 46, Fuchs 68. Bei gleicher Zahl entscheidet die Personen-ID.

Allgemein gilt: Ein Schritt entfällt, wenn die Person tot ist, die Rolle gewechselt hat oder in dieser Nacht vergiftet oder todesmarkiert wurde. Ein Fluch der Alten lässt alle Schritte von Dorf-Personen ruhen.

1. **Der Dorfbewohner:** Hat keine Fähigkeit und gewinnt mit dem Dorf, sobald kein Werwolf mehr lebt. Abweichung vom Bogen: keine.

2. **Der Werwolf:** Wacht jede Nacht mit dem Rudel auf, das gemeinsam genau eine lebende Person als Opfer wählt (kein Verzicht), die am Morgen stirbt, wenn Engel, Hexe oder das erste Leben der Alten sie nicht retten; die Wölfe gewinnen, sobald sie mindestens so viele sind wie alle anderen Lebenden. Abweichung vom Bogen: keine.

3. **Die Seherin:** Wählt jede Nacht genau eine andere lebende Person (nicht sich selbst, kein Verzicht) und erfährt deren tatsächliche Rolle, auch bei Urwolf, Weißem Wolf und Werwolf (Das wilde Kind zeigt sie als „Das wilde Kind“, auch nach der Verwandlung); sie gewinnt mit dem Dorf. Abweichung vom Bogen: keine (Bogen: „die wahre Identität eines Spielers“; der Spielleiter kann die gezeigte Rolle weiter übersteuern).

4. **Die Hexe:** Wacht jede Nacht auf, solange sie noch einen Trank hat, und darf den Heiltrank (rettet das Rudelopfer dieser Nacht) und den Gifttrank (tötet eine beliebige lebende Person, auch sich selbst, am Morgen) je einmal pro Partie einsetzen, einzeln oder beide, oder verzichten; sie gewinnt mit dem Dorf. Abweichung vom Bogen: Sie sieht das Rudelopfer als große Rollenkarte (zuerst ohne Namen, nach der Rettung mit dem Namen unter der Karte; Nachtauftrag 14.10.2026, ersetzt das frühere „erfährt die Rolle nicht“), und nach einer Urwolf-Verwandlung gibt es kein Rudelopfer mehr, das sie heilen könnte; der Engel schützt nicht gegen ihr Gift.

5. **Der Jäger:** Stirbt er auf irgendeine Weise (nachts erst in der Morgenauflösung), darf er sofort eine lebende Person wählen, die ebenfalls stirbt (öffentlich mit Rolle angesagt), oder verzichten; er gewinnt mit dem Dorf. Abweichung vom Bogen: keine (Bogen: „kann ... jemanden mit ins Grab nehmen“); bei laufendem Fluch der Alten entfällt der Schuss.

6. **Der Engel:** Wählt jede Nacht genau eine andere lebende Person (nicht sich selbst, kein Verzicht), die nur in dieser Nacht vor dem Rudelangriff geschützt ist, und gewinnt mit dem Dorf. Abweichung vom Bogen: keine (der Schutz hilft nur gegen den Rudelangriff, nicht gegen Gift, den Weißen Wolf, Tetanus, Jäger, Hinrichtung, Liebeskummer oder die Urwolf-Verwandlung).

7. **Das Mädchen:** Ist mechanisch ein Dorfbewohner ohne Nachtschritt; die App zeigt der Spielleitung nur einen Hinweis im Wolfsschritt, dass das Mädchen blinzeln darf; es gewinnt mit dem Dorf. Abweichung vom Bogen: Das Spionieren und das Erwischtwerden gibt es nur als Hinweis am Tisch, die Regel kennt keine Wirkung.

8. **Der Alte:** Überlebt den ersten Rudelangriff (nur diesen, und nur wenn Engel und Hexe nicht schon schützen), stirbt aber durch alles andere sofort, und wird er von den Dorfbewohnern gehängt, verlieren alle Personen der Dorf-Fraktion ihre Fähigkeiten dauerhaft für den Rest der Partie (die Spielleitung wird nach keiner Dauer gefragt); er gewinnt mit dem Dorf. Abweichung vom Bogen: keine (Bogen: „verlieren alle aus Gram ihre Fähigkeiten“); Werwölfe, Einzelgänger und das verwandelte Wilde Kind behalten ihre Fähigkeiten.

9. **Amor:** Wählt nur in Nacht 1 (als erster Schritt) zuerst die Art, Liebe oder Hass, und dann genau zwei lebende Personen, auch sich selbst (kein Verzicht). Bei Liebe sind es Liebende: Stirbt eine der beiden, stirbt die andere sofort aus Liebeskummer mit. Bei Hass sind es Feinde (Mechanik der Rivalen): Keiner von beiden kann gewinnen, solange der andere lebt. Amor gewinnt mit dem Dorf. Abweichung vom Bogen: Der Bogen kennt nur Liebe; die Wahl Hass ist neu (Nachtauftrag 14.10.2026) und mit dem Schalter `amor_hate_option` in `CLASSIC_ROLES` abschaltbar (false = nur Liebende, keine Frage; Standard an). Der Liebeskummer greift nicht, wenn der Partner in derselben Nacht ohnehin schon todesmarkiert ist, und nicht bei Spielleiterkorrekturen ohne Todesfolgen.

10. **Die drei Brüder:** Erwachen nur in Nacht 1 gemeinsam (Zahl 5) und sehen sich, danach sind sie einfache Dorfbewohner, und sie gewinnen mit dem Dorf; die Startbesetzung muss genau drei enthalten. Abweichung vom Bogen: keine.

11. **Die zwei Schwestern:** Erwachen nur in Nacht 1 gemeinsam (Zahl 5, nach den Brüdern) und sehen sich, danach sind sie einfache Dorfbewohner, und sie gewinnen mit dem Dorf; die Startbesetzung muss genau zwei enthalten. Abweichung vom Bogen: keine.

12. **Der Selbstmörder:** Hat keinen Nachtschritt und gewinnt allein, wenn er am Tag hingerichtet wird, während mindestens fünf andere Personen tot sind (er selbst zählt nicht mit; der Spielleiter bestätigt den Sieg). Abweichung vom Bogen: keine (jede Hinrichtung am Tag zählt, auch per Spielleiterkorrektur).

13. **Das wilde Kind:** Wählt nur in Nacht 1 (Zahl 9, Pflicht) genau eine andere lebende Person als Vorbild und wird sofort zum Werwolf (Fraktion Wölfe, erscheint als Classic-Werwolf), sobald das Vorbild auf irgendeine Weise stirbt; bis dahin gewinnt es mit dem Dorf, danach mit den Wölfen. Abweichung vom Bogen: Die Wahl ist Pflicht und gibt es nur in Nacht 1 (wer erst später in die Rolle kommt, wählt nie), und die Verwandlung bleibt aus, solange ein Fluch der Alten seine Fähigkeit ruhen lässt.

14. **Der Ritter mit dem verrosteten Schwert:** Wird er in der Nacht von den Werwölfen getötet (und ruht kein Fluch), wählt die Spielleitung in der Morgenphase direkt nach seiner Todesmeldung, vor Anklage und Abstimmung, „Links“ oder „Rechts“; die Knöpfe nennen den nächsten lebenden Werwolf in der jeweiligen Richtung (Sitzreihenfolge, links = Uhrzeigersinn, der Kreis läuft rund, der Urwolf zählt mit). Dieser Wolf stirbt sofort; Folgen (Liebende, Jäger, Siegprüfung) laufen in der normalen Reihenfolge, der Sieg wird nach beiden Toden geprüft. Lebt nur ein Wolf, stirbt er ohne Frage; lebt keiner, geschieht nichts. Gift, Hexe, Hinrichtung, Jäger-Tod oder Liebestod lösen nichts aus; einmal je Leben; der Ritter gewinnt mit dem Dorf. Die frühere Tetanus-Wirkung (Tod erst in der folgenden Nacht) entfällt (Markus, 14.10.2026); nur geladene alte Stände mit offener Infektion behalten sie.

15. **Der Fuchs:** Wählt jede Nacht genau eine lebende Person (auch sich selbst, kein Verzicht) und erfährt nur „Ja“ oder „Nein“, ob sie oder einer ihrer beiden lebenden Sitznachbarn als Wolf zählt; bei „Nein“ verliert er seine Fähigkeit (er wird weiter aufgerufen, ohne Wirkung), und er gewinnt mit dem Dorf. Abweichung vom Bogen: „Werwolf“ heißt hier „zählt als Wolf“, tote Plätze werden übersprungen, und er darf sich selbst wählen.

16. **Der Flötenspieler:** Fragt zuerst „Wie viele verzaubern?“ (Eine Person oder Zwei Personen; bleibt nur eine Verzauberbare übrig, entfällt die Frage), wählt dann genau so viele andere lebende Personen, die er noch nicht verzaubert hat (kein Verzicht), die dauerhaft verzaubert bleiben und nur in dieser Nacht davon erfahren; er gewinnt allein, sobald er lebt und jede andere lebende Person von ihm verzaubert ist. Abweichung vom Bogen: Der Bogen verlangt „in jeder Nacht zwei Spieler“; hier darf die Spielleitung eine oder zwei wählen (Nachtauftrag 14.10.2026). Das gilt auch für den Rattenfänger des Grundspiels. Einen Schritt „Alle Verzauberten“ gibt es in Classic nicht.

17. **Der Bärenführer:** Hat keinen Nachtschritt; jeden Morgen, auch den ersten, knurrt der Spielleiter öffentlich ohne Namen, wenn er lebt und einer seiner beiden nächsten lebenden Nachbarn als Wolf zählt, und er gewinnt mit dem Dorf. Abweichung vom Bogen: „Unmittelbar daneben“ bedeutet die nächste lebende Person links und rechts (tote Plätze werden übersprungen), und ein Fluch der Alten schaltet das Knurren ab.

18. **Der Urwolf:** Wacht als Werwolf mit dem Rudel auf, und direkt danach fragt die App einmal im ganzen Spiel Ja oder Nein, ob das Rudelopfer statt zu sterben zum Werwolf wird (nur wenn das Opfer lebt und kein Wolf ist); er gewinnt mit den Wölfen. Abweichung vom Bogen: Auch ein vom Engel oder von der Hexe geschütztes Opfer wird verwandelt, das Rudelopfer entfällt danach für Hexe und Rudelfolgen, und die App gibt dem Opfer keinen eigenen Hinweis, das geheime Zeichen läuft am Tisch.

19. **Der Weiße Wolf:** Wacht als Werwolf mit dem Rudel auf und erwacht in jeder zweiten Nacht (2, 4, 6 …) zusätzlich allein, um eine beliebige andere lebende Person (auch einen Werwolf) zu töten oder zu verzichten, was am Morgen unaufhaltsam geschieht (kein Engel, keine Hexe, kein Ritter-Effekt); er gewinnt nur allein, als Einziger Überlebender, und das Rudel gewinnt nie, solange er lebt (auch das Dorf gewinnt erst, wenn er tot ist). Abweichung vom Bogen: keine beim Sieg (Bogen: „als einziger am Ende übrig zu bleiben“); beim Ziel nennt der Bogen keine Einschränkung („sein Unwesen treiben“), der Code erlaubt jede andere lebende Person (Rückfrage in `docs/classic/RUECKFRAGEN.md`).

## Nicht abschließend geklärt

- Ob Totenreichkarten die Zielwahl des Rudels ändern (`CardHooks.shape_pack_prompt`), nicht geprüft.
- Ob „links“ des Ritters der Uhrzeigersinn der echten Sitzordnung am Tisch ist.
- Der genaue Wortlaut des Mädchen-Hinweises steht in der Sprachdatei, nicht im Regelkern.
