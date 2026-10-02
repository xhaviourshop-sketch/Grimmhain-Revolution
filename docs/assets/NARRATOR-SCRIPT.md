# Sprechertexte · Vertical Slice

**Stand:** 2026-09-26 · **Status:** Entwurf. Kein Text ist freigegeben, keine Zeile ist aufgenommen.
**Grundlagen:** [`../specs/vertical-slice/rules-register.md`](../specs/vertical-slice/rules-register.md) (Regeltexte, Nachtprioritäten), [`../specs/vertical-slice/vertical-slice-flow.md`](../specs/vertical-slice/vertical-slice-flow.md), [`../godot-migration/02-product-and-ux-spec.md`](../godot-migration/02-product-and-ux-spec.md) §6 (Ansagekarte, Schlüssel `role.<id>.call`/`.sleep`), [`PRODUCTION-PLAN.md`](PRODUCTION-PLAN.md) §7.

---

## 1. Regeln

1. **Ein Text, drei Verwendungen.** Jede Zeile ist zugleich Vorlesetext auf der Ansagekarte, Untertitel und Vorlage für die Aufnahme. Der Schlüssel ist identisch; die Aufnahme heißt `vo-<sprache>-<schlüssel mit Bindestrichen>.wav`.
2. **Nur Öffentliches wird gesprochen.** Die Stimme hören alle am Tisch. Alles, was nur der Spielleiter oder nur die handelnde Person erfahren darf (Orakel-Ergebnis, Wolfsopfer für die Waldhexe, Lehrlings-Auswahl, Scheinrolle, Todesursache), erscheint ausschließlich als Text auf dem Tablet.
3. **Keine Namen, keine Zahlen in Aufnahmen.** Namen liest der Spielleiter selbst vor. Aufgenommene Zeilen enthalten deshalb keine Platzhalter.
4. **Keine Aussage über Tod oder Leben einer Rolle.** Aufruf und Einschlafen klingen gleich, egal ob die Rolle lebt; so funktionieren auch Tarnaufrufe toter Rollen (`02` §3.2: „Tote Rollen weiter aufrufen").
5. **Anrede:** Die aufgerufene Rolle wird mit „du" angesprochen, das Rudel mit „ihr", der Tisch mit „alle". Rollennamen wie in `role-selection.md`.
6. **Länge:** höchstens zwei kurze Sätze, gesprochen ≤ 8 s.
7. **Ton:** ruhiger Märchenerzähler, nicht schaurig überzeichnet, keine drastische Gewalt (Zielgruppe ab 12, Decision Log).

## 2. Spielbeginn

| Schlüssel | DE | EN | Auslöser |
|---|---|---|---|
| `narration.game.intro` | Willkommen in Grimmhain. Nicht jeder in diesem Dorf ist, wer er zu sein scheint. | Welcome to Grimmhain. Not everyone in this village is who they seem to be. | Partie gestartet |
| `narration.setup.role_reveal` | Jede Person sieht sich jetzt ihre Rolle an. Zeigt sie niemandem. | Everyone, look at your role now. Show it to no one. | Rollenanzeige |

## 3. Nacht

Reihenfolge nach Nachtpriorität aus `rules-register.md`. Trugbilderwolf, Spiegelwolf und das verwandelte Wolfskind wachen im Rudelschritt und haben keine eigenen Zeilen. Dorfbewohner, Sensenträger und Manipulator haben keinen Nachtschritt.

| Schlüssel | DE | EN | Auslöser |
|---|---|---|---|
| `narration.night.first_begin` | Die erste Nacht senkt sich über Grimmhain. Alle schließen die Augen. | The first night falls over Grimmhain. Everyone, close your eyes. | `PhaseChanged → NIGHT`, Nacht 1 |
| `narration.night.begin` | Die Nacht bricht herein. Alle schließen die Augen. | Night falls. Everyone, close your eyes. | `PhaseChanged → NIGHT`, ab Nacht 2 |
| `role.wolfskind.call` | Das Wolfskind erwacht. | The Wolf Child wakes up. | Schritt 0.9, einmalig |
| `role.wolfskind.act` | Zeige auf die Person, die dein Vorbild sein soll. | Point to the person who shall be your role model. | nach Aufruf |
| `role.wolfskind.sleep` | Das Wolfskind schläft wieder ein. | The Wolf Child goes back to sleep. | Schritt bestätigt |
| `role.lehrling.call` | Der Lehrling erwacht. | The Apprentice wakes up. | Schritt 1.1, einmalig |
| `role.lehrling.act` | Du siehst drei Rollen. Wähle eine davon. | You will see three roles. Choose one of them. | nach Aufruf |
| `role.lehrling.sleep` | Der Lehrling schläft wieder ein. | The Apprentice goes back to sleep. | Schritt bestätigt |
| `role.schutzengel.call` | Der Schutzengel erwacht. | The Guardian Angel wakes up. | Schritt 1.3 |
| `role.schutzengel.act` | Zeige auf die Person, die du in dieser Nacht beschützen willst. | Point to the person you want to protect tonight. | nach Aufruf |
| `role.schutzengel.sleep` | Der Schutzengel schläft wieder ein. | The Guardian Angel goes back to sleep. | Schritt bestätigt |
| `role.werwolf.call` | Die Werwölfe erwachen und erkennen einander. | The werewolves wake up and recognise each other. | Rudelschritt 2.0 |
| `role.werwolf.act` | Einigt euch lautlos auf ein Opfer. | Silently agree on a victim. | nach Aufruf |
| `role.werwolf.sleep` | Die Werwölfe schlafen wieder ein. | The werewolves go back to sleep. | Schritt bestätigt |
| `role.waldhexe.call` | Die Waldhexe erwacht. | The Witch of the Woods wakes up. | Schritt 3.4 |
| `role.waldhexe.act` | Sieh dir das Opfer dieser Nacht an und entscheide über deine Tränke. | Look at tonight's victim and decide on your potions. | nach Aufruf |
| `role.waldhexe.sleep` | Die Waldhexe schläft wieder ein. | The Witch of the Woods goes back to sleep. | Schritt bestätigt |
| `role.das-orakel.call` | Das Orakel erwacht. | The Oracle wakes up. | Schritt 4.6 |
| `role.das-orakel.act` | Zeige auf die Person, deren Rolle du erfahren willst. | Point to the person whose role you want to learn. | nach Aufruf |
| `role.das-orakel.sleep` | Das Orakel schläft wieder ein. | The Oracle goes back to sleep. | Schritt bestätigt |

**Hinweise zu einzelnen Zeilen**

- `role.lehrling.act` sagt bewusst nicht, dass Personen hinter den Rollen stehen; die Regel verlangt, dass der Lehrling nie Namen oder Identitäten sieht. Die drei Rollen zeigt der Spielleiter auf dem Tablet.
- `role.waldhexe.act` nennt keinen Namen und sagt nicht, ob ein Opfer existiert oder welche Tränke noch da sind. Beides wäre für den Tisch hörbar.
- `role.das-orakel.act`: Das Ergebnis erscheint nur auf dem Tablet.

## 4. Morgen

| Schlüssel | DE | EN | Auslöser |
|---|---|---|---|
| `narration.dawn.begin` | Der Morgen graut über Grimmhain. Alle öffnen die Augen. | Dawn breaks over Grimmhain. Everyone, open your eyes. | `PhaseChanged → DAWN` |
| `narration.morning.death_single` | Diese Nacht hat ein Leben gefordert. | This night has claimed a life. | Morgenbericht, genau ein Tod; danach liest der Spielleiter den Namen |
| `narration.morning.death_multiple` | Diese Nacht hat mehrere Leben gefordert. | This night has claimed several lives. | Morgenbericht, mehrere Tode |
| `narration.morning.no_death` | In dieser Nacht ist niemand gestorben. | No one died this night. | Morgenbericht ohne Tod |

## 5. Tag und Spielende

| Schlüssel | DE | EN | Auslöser |
|---|---|---|---|
| `narration.day.begin` | Das Dorf versammelt sich. Beratet, wem ihr noch trauen könnt. | The village gathers. Discuss whom you can still trust. | Tagesbeginn |
| `narration.day.nominations_open` | Wer einen Verdacht hat, darf jetzt jemanden nominieren. | Anyone with a suspicion may now nominate someone. | Spielleiter öffnet Nominierungen |
| `narration.day.timer_end` | Die Zeit ist abgelaufen. | Time is up. | Diskussionstimer 0 |
| `narration.day.execution` | Das Dorf hat entschieden. Das Urteil wird vollstreckt. | The village has decided. The sentence will be carried out. | `ExecutionConfirmed`, beim Verkünden; danach liest der Spielleiter den Namen |
| `narration.day.no_execution` | Heute wird niemand hingerichtet. | No one will be executed today. | `NoExecution` |
| `narration.day.end` | Die Sonne versinkt hinter den Bäumen. | The sun sinks behind the trees. | `DayEnded` |
| `narration.win.village` | Die Werwölfe sind besiegt. Das Dorf hat gewonnen. | The werewolves are defeated. The village has won. | `WinConfirmed`, Dorf |
| `narration.win.wolves` | Die Werwölfe haben das Dorf überwältigt. Die Werwölfe haben gewonnen. | The werewolves have overrun the village. The werewolves have won. | `WinConfirmed`, Werwölfe |
| `narration.win.manipulator` | Der Manipulator hat alle gegeneinander ausgespielt und gewinnt allein. | The Manipulator has played everyone against each other and wins alone. | `WinConfirmed`, Manipulator |
| `narration.game.end` | Die Partie ist vorbei. Deckt eure Rollen auf. | The game is over. Reveal your roles. | nach Sieg-Tableau |

**Summe:** 2 + 20 + 4 + 10 = **36 Zeilen je Sprache**. Zweitvarianten (`-v2`) sind für die häufigsten sechs Zeilen vorgesehen: `narration.night.begin`, `narration.dawn.begin`, `narration.morning.no_death`, `narration.day.begin`, `role.werwolf.call`, `role.werwolf.sleep`.

## 5a. Bewusst nicht vertont

| Situation | Warum keine Stimme | Stattdessen |
|---|---|---|
| Ergebnis des Orakels, Scheinrolle des Trugbilderwolfs | nur für die handelnde Person bzw. den Spielleiter | Tablet-Anzeige |
| Name des Wolfsopfers für die Waldhexe, Heilung, Giftziel | privat | Tablet-Anzeige |
| Die drei Rollen des Lehrlings, Erbe einer Rolle | privat | Tablet-Anzeige |
| Reaktion des Sensenträgers | Ansage würde Rolle und Todesursache verraten (G-TOD-5) | Spielleiter führt die Wahl leise durch |
| Tod des Manipulators bei Nominierung | Ursache ist privat (G-TOD-5); öffentlich ist nur der Name | Spielleiter verkündet den Tod mit Namen |
| Spiegelung beim Spiegelwolf | Umleitung ist ein Spielleiter-Ereignis; öffentlich ist nur, wer stirbt | `narration.day.execution`, danach Name der tatsächlich gestorbenen Person |
| Wolfskind-Verwandlung | privat | Tablet-Anzeige |
| Rolle einer gestorbenen Person | nur in Runden ohne Wiederbelebung (29.09.2026, ersetzt `reveal_role_on_death`) | Spielleiter liest vor, wenn die Runde keine Wiederbelebung hat |

## 6. Offene Fragen an den Product Owner

1. **Tarnaufrufe:** *(beantwortet am 29.09.2026, DI-02: ohne Wiederbelebung werden aufgedeckte tote Rollen nicht mehr aufgerufen, aufgebrauchte Rollen weiter; mit Wiederbelebung auch tote Rollen)* Sollen tote Rollen standardmäßig weiter aufgerufen werden (`02` §3.2)? Falls ja: Wie lange wartet die App zwischen `call` und `sleep` bei einer Tarnung (Vorschlag: 5 s)?
2. **Ton und Register:** Passt der ruhige Märchenerzähler, oder soll es knapper und sachlicher klingen? Eine Probe beider Varianten mit je drei Zeilen wäre die schnellste Entscheidung.
3. **Einleitung:** Soll `narration.game.intro` nur bei der ersten Partie einer Sitzung laufen oder jedes Mal?
4. **Zeigen oder Tippen:** Die `act`-Zeilen sagen „Zeige auf die Person". Passt das zum geplanten Ablauf, oder tippt die handelnde Person selbst auf das Tablet?
5. **Spielende mit mehreren Siegkandidaten (DR-14):** Der Spielleiter bestätigt einen Sieger; eine eigene Zeile für mehrere Sieger oder Unentschieden ist nicht vorgesehen. Richtig so?
6. **Stimme:** eine neutrale Erzählstimme für beide Sprachen oder je eine muttersprachliche Stimme? (Empfehlung: muttersprachlich.)
