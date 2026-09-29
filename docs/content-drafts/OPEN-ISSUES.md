# Offene Punkte und Quellenprüfung (Entwurf)

**Status:** Entwurf. Stand: Quell-Commit `312f5bbbbec4c218754b35a0043b51e79d80bcf5` (`audit/all-72-roles`). Erste Fassung 29.09.2026, fachlich überarbeitet am 29.09.2026 gegen Decision Log, Regelregister, Regelkern (`godot/core/rules/`) und Tests am Quell-Commit. Diese Liste entscheidet nichts. Zeilennummern beziehen sich auf den Quell-Commit.

Kartenschlucker (`kartenschlucker`) ist ausdrücklich zurückgestellt (`11-role-audit-status.md` §0 "Einzige blockierte Rolle: Kartenschlucker"). Es gibt keinen Entwurf und keine Totenkartenregel.

## 1. Klassen

| Klasse | Bedeutung |
|---|---|
| K1 | Echter widersprüchlicher Regelinhalt (zwei gültige Quellen sagen Verschiedenes) |
| K2 | Bereits entschieden oder technisch eindeutig aus Entscheidungen, Regelkern und Tests abgeleitet |
| K3 | Bewusste spätere Erweiterung |
| K4 | Offene Produktentscheidung |
| K5 | Reine Formulierungs- oder Integrationsfrage |

## 2. Ergebnis der Prüfung

Von 19 Punkten bleibt kein einziger als echter Regelwiderspruch (K1) bestehen. Sieben Punkte sind im Kern aufgelöst (K2: OI-03, OI-05, OI-07, OI-08, OI-14, OI-15 und OI-11 a). Sieben sind bewusst spätere Erweiterung, Formulierungs- oder Integrationsfrage (K3, K5: OI-02, OI-04, OI-06, OI-09, OI-10, OI-16, OI-18). Sechs bleiben als offene Produktentscheidung (K4: OI-01, OI-11 b, OI-12, OI-13, OI-17, OI-19), davon vier mit Vorrang (Abschnitt 5). OI-11 zählt in zwei Klassen.

| ID | Thema | Vorher | Klasse jetzt | Ergebnis |
|---|---|---|---|---|
| OI-01 | Aufrufpolitik für bedingte, blockierte und fehlende Rollen | Lücke | K4 | offen, Vorrang 1 (D1) |
| OI-02 | Totenkarten (Kutscher, Frankenstein, Kartenschlucker) | Lücke | K3 | bewusst später (W-01 = A), keine Entscheidung für die Entwürfe nötig |
| OI-03 | Siegreicher Wolf zählt doppelt | Konflikt | K2 | Fehlalarm, aufgelöst; nur ein Hinweis bleibt |
| OI-04 | Begriffe in `ui.*.po` | Konflikt | K5 | kein Regelkonflikt, teilweise Fehlalarm; Angleichung ist Übersetzungsarbeit |
| OI-05 | Überholte Regelregister-Texte | Konflikt | K2 | vom Decision Log bereits ersetzt; Vermerk im Register steht aus |
| OI-06 | "Links" gleich Uhrzeigersinn | Hinweis | K5 | Tablet-Gegenprüfung steht aus |
| OI-07 | Ton bei fünf Toten | Konflikt | K2 | gewählte Ausnahme mit dokumentierter Nebenwirkung, kein erwiesener Fehler; optionale Bestätigung (D7) |
| OI-08 | Traumdeuter und Kopfgeldjäger ohne mögliche Auswahl | Lücke | K2 | aus gemeinsamer Regel, Code und Test belegt, Entwurf ergänzt |
| OI-09 | Zufallsknopf | Hinweis | K3 | entschieden (RM-DR-015.2), Umsetzung steht aus |
| OI-10 | Amalia: Format der Frage | Lücke | K5 | aufgelöst: Die App prüft die Frage nicht, Entwurf ergänzt |
| OI-11 | Öffentliche Ansagen (Schutzgeist, Weiser) | Lücke | K2 und K4 | (a) Schutzgeist aufgelöst, Entwurf geändert; (b) Weiser offen, Vorrang niedrig (D6) |
| OI-12 | Loki: Wer erfährt von der Bindung | Lücke | K4 | offen, Vorrang 2 (D2) |
| OI-13 | Rotkäppchen: Wer erfährt von Kette und Apfel | Lücke | K4 (Teil K2) | offen, Vorrang 3 (D3) |
| OI-14 | Henker: Hinrichtung am Folgetag bleibt aus | Lücke | K2 | Decision Log, Code und Test belegen: Markierung verfällt; Entwurf ergänzt |
| OI-15 | König Lykaon: Information der verwandelten Person | Lücke | K2 | Regelkern meldet privat; Rudel sieht die Person ab der Folgenacht; Entwurf ergänzt |
| OI-16 | Name der Fraktion "Einzelsieg" | Hinweis | K3, K5 | Decision Log: "folgt später"; Arbeitsbegriff bleibt |
| OI-17 | Rattenfänger, Pestbringerin: Information der Betroffenen | Lücke | K4 | offen, Vorrang 4 (D4) |
| OI-18 | Handlungszeilen für Nicht-Slice-Rollen | Lücke | K5 | Integrationsfrage (NARRATOR-SCRIPT), keine Regelfrage |
| OI-19 | Trugbilderwolf: Kennt er seine Scheinrolle | Lücke | K4 | offen, Vorrang 5 (D5) |

## 3. Aufgelöste Punkte mit Belegen

### OI-03 · Siegreicher Wolf (Fehlalarm, K2)

- **Frühere Behauptung:** Das Register zähle einfach, die Umsetzung doppelt, und ohne ausdrückliche Auswahl sei die Regel unsicher.
- **Befund:** Es gibt keinen Widerspruch. G-SIEG-2 (`rules-register.md` Zeile 78) beschreibt den Umfang des Vertical Slice ("Im Slice zählt jeder Wolf einfach (Siegreicher Wolf ist nicht enthalten)"). Damit ist der Umfang ohne diese Rolle beschrieben, nicht die Rollenregel verneint. Die Rollenregel steht im Rollentext ("As long as they live, counts as two werewolves toward the win condition", `01-canonical-role-catalog.md` §4; DE-Kurztext `ui.de.po` Zeile 468: "zählt lebend für den Wolfssieg wie zwei Wölfe") und ist widerspruchsfrei.
- **Weitere Belege:** Die Entscheidung Waldläufer (RM-DR-147.2, Decision Log Zeile 291) setzt die Sonderzählung voraus ("der Siegreiche Wolf zählt einmal"). Regelkern: `role_catalog.gd` Zeile 235 (`parity_weight` 2), `win_rules.gd` Zeilen 27 bis 33. Tests: `test_siegreicher_wolf.gd` (10). `10-next-decisions.md` Zeile 68 hat die Zählung als "Zur Kenntnis, keine Frage" mitgeteilt, ohne dass ihr widersprochen wurde.
- **Rest:** Es gibt keine ausdrückliche Einzelauswahl des Product Owners. Das macht eine widerspruchsfreie Rollenregel nicht ungültig und verlangt keine Rückfrage.
- **Entwurf:** `siegreicher-wolf` trägt den Status "aus dem widerspruchsfreien Rollentext abgeleitet, umgesetzt und getestet". Später sind nur Erweiterungen (zum Beispiel eine Setup-Zählregel) eine eigene Entscheidung.

### OI-04 · Begriffe in den Übersetzungsdateien (K5, teilweise Fehlalarm)

- **Schlüssel mit Unterstrich:** `ui.role.das_orakel.*` sind Übersetzungsschlüssel, keine Rollen-IDs. DR-01 (Decision Log Zeile 93) legt kebab-case für die technischen Rollen-IDs fest (`das-orakel`). Das ist kein Verstoß, die Schlüsselbildung ist eine Integrationsfrage.
- **"Wolfsangriff":** Der Begriff stammt aus den Quellen selbst (RM-DR-004, Decision Log Zeile 316: "Wolfsangriff ist ausschließlich der Rudelangriff"; G-TOD-3: `NIGHT_KILL` (Wolfsangriff)). Die Kurztexte in `ui.*.po` verwenden ihn für Rudelangriffe, was der Definition entspricht. Es gibt keinen Regelkonflikt. Die Entwürfe verwenden "Rudelangriff" der Klarheit wegen, beide Wörter sind gleichbedeutend.
- **"gelyncht" und "Hinrichtung":** G-TOD-3 nennt `LYNCH` (Hinrichtung nach physischer Abstimmung), das Decision Log verwendet beide Wörter. Welches Wort auf Karten steht, ist eine Formulierungsfrage. Die Entwürfe wählen "Hinrichtung".
- **EN uneinheitlich:** "wolf attack" und "werewolf attack" in `ui.en.po` sind uneinheitlich, ebenso "his" und "her" gegenüber neutralem "their". Beides ist Stilarbeit, kein Regelinhalt.
- **Zu tun später:** Kurztexte im Rahmen der Übersetzungsarbeit angleichen. Details in [`TERMINOLOGY.md`](TERMINOLOGY.md) §4.

### OI-05 · Überholte Texte im Regelregister (K2, bereits entschieden)

Die Entwürfe folgen dem jüngeren Decision Log. Im Regelregister stehen noch ältere Formulierungen ohne Änderungsvermerk:

| Stelle im Register | Älterer Text | Ersetzt durch (Decision Log) |
|---|---|---|
| `rules-register.md` Zeile 200 und 205 (Waldhexe) | "Einmal pro Partie", "für die ganze Partie (G-ID-3)" | Zeilen 301 bis 303: Einsätze gelten je Leben, jede Wiederbelebung setzt sie zurück |
| Zeile 225 (Sensenträger) | "einmal pro Partie" | Zeile 301: je Leben |
| Zeile 249 (Wolfskind) | "In seiner ersten Nacht wählt" | Zeile 183: jede Nacht, solange unverwandelt und ohne Vorbild (ein regulär gestartetes Wolfskind handelt in Nacht 1) |
| Zeile 272 (Lehrling) | "in der ersten Nacht" | Zeilen 210 bis 212: erste verfügbare Nacht ohne Bindung |
| DR-06 (Decision Log Zeile 108) | "Gift tötet sofort" | Zeilen 280 bis 283: Todesmarkierung, Tod in der Morgenauflösung |

Ebenfalls ersetzt, im Decision Log selbst und dort ausdrücklich benannt (Zeile 301): die Formulierungen zur Waldhexe (Zeile 148) und zum Spiegelwolf (Zeile 199) "eine Wiederbelebung setzt nichts zurück". Alle Einträge der Entwürfe folgen den Ersatztexten. Das Register sollte bei nächster Gelegenheit Vermerke erhalten (nicht Teil dieses Auftrags).

### OI-07 · Ton bei fünf Toten (gewählte Ausnahme, K2)

- **Entscheidung:** Decision Log Zeile 284 (Abschnitt "Nachfragen Spielende, Nachttode, Sound"): Der Ton ertönt, sobald die fünfte Person ihren Totenmarker erhält, öffentlich am Tag, und nur, wenn ein Selbstmörder in der Partie ist. Zeile 270 hatte die Nebenwirkung als noch offen benannt ("weil er sonst dessen Anwesenheit verraten kann"). `11-role-audit-status.md` führt den Punkt nur noch als Umsetzung außerhalb des Kerns.
- **Was der Ton offenlegt:** dass die Rolle `selbstmoerder` in der Partie ist, und dass die Schwelle von fünf Toten erreicht ist (also dass eine Hinrichtung des Selbstmörders jetzt seinen Sieg erfüllen würde). Er legt nicht offen, wer die Rolle hat, ob die Person lebt, und nichts über andere Rollen. Bleibt der Ton bei fünf Toten aus, weiß der Tisch, dass kein Selbstmörder in der Partie ist (oder je nach Auslegung von "in der Partie" keiner mehr).
- **Spannung zur allgemeinen Regel:** "Öffentliche Projektion erhält niemals geheime Daten" (Decision Log Zeile 45) betrifft die öffentliche Ansicht. Ein Ton ist eine bewusst öffentliche Ausgabe, und die Entscheidung liegt ausdrücklich vor. Es ist damit keine Verletzung, sondern eine gewählte, eng begrenzte Ausnahme.
- **Unklar bleibt:** ob "in der Partie" die Rolle zu Spielbeginn oder eine lebende Person mit der Rolle meint. Das ist eine Detailfrage der Umsetzung.
- **Entwurf:** Es gibt keinen Text zum Ton. `selbstmoerder` beschreibt die Entscheidung und ihre Wirkung (Lexikon) statt einer Fehlerbehauptung. Eine Änderung schlagen die Entwürfe nicht vor. Wenn der Product Owner die Nebenwirkung neu bewerten will, steht die Alternative unter D7.

### OI-08 · Traumdeuter und Kopfgeldjäger ohne mögliche Auswahl (K2)

- **Kopfgeldjäger:** Decision Log Zeile 374 (I-04): Reichen die Ziele nicht, verfällt die Liste mit Hinweis.
- **Traumdeuter:** Es gilt die gemeinsame Regel für Pflichtwahlen ohne mögliche Entscheidung: "Ein Waldhexenschritt ohne mögliche Entscheidung entfällt ebenso" (Zeile 152) und DA-20 (Zeile 535, "entfällt mit no_decision wie jede Pflichtwahl ohne Ziel"). Der Regelkern setzt das um: `step_queue.gd` Zeilen 286 und 287 (`triple_possible` falsch führt zu `no_decision`), `info_steps.gd` Zeilen 93 bis 95. Test: `test_dreamer_true_wolf_count_and_drop_without_enough_targets` (`test_info_roles.gd`).
- **Ergebnis:** Der Schritt entfällt protokolliert, der Traumdeuter erfährt nichts, in der nächsten Nacht wird neu geprüft. Der Kopfgeldjäger behält seine Zähler, die Liste verfällt mit Hinweis.
- **Entwurf:** `traumdeuter` ergänzt, Status "Randfall aus dem Regelkern abgeleitet".

### OI-10 · Amalia: Format der Frage (K5)

- **Befund:** Die Entscheidung I-09 (Decision Log Zeile 379) lautet: öffentliche Ja/Nein-Frage, der Spielleiter antwortet wahrheitsgemäß, die App protokolliert die Antwort. Der Regelkern prüft die Frage nicht: `AMALIA_ANSWERED` (`rules_engine.gd` Zeile 363) trägt nur Person, Antwort und Tag, keinen Fragetext. Eine Einschränkung der Frageart wäre eine neue Regel und ist nicht entschieden.
- **Entwurf:** `amalia` sagt, dass die App die Frage nicht prüft. Es wird nichts eingeschränkt.

### OI-11 (a) · Schutzgeist: Ansage und Rollenname (K2)

- **Herleitung:** DR-04 (Zeile 106) hält die Rolle einer gestorbenen Person geheim, sofern das Setup die Aufdeckung nicht einschaltet. S-04 (Zeile 398) verlangt die Ansage "ohne Namen". Der Regelkern meldet öffentlich nur die Nachtnummer (`GHOST_WOLF_ALERT`, `rules_engine.gd` Zeile 752). Eine Ansage mit dem Rollennamen würde bei ausgeschalteter Aufdeckung die Rolle der Toten offenlegen.
- **Entwurf geändert:** "Eine tote Person hat in der Nacht einen Wolf gewählt." Der Rollenname steht nicht in der Ansage. Er wäre nur bei eingeschalteter Rollenaufdeckung unschädlich.

### OI-14 · Henker: ausbleibende Hinrichtung (K2)

- **Regel:** Decision Log Zeile 363 (RM-DR-130.3): Die markierte Person stirbt "bei der Hinrichtung des folgenden Tages", "sonst verfällt die Markierung". Der Rollentext sagt "dies additionally after the next lynch".
- **Code:** `rules_engine.gd` Zeile 527 (`_start_night` löscht `hangman_marks`), `execution_rules.gd` Zeilen 97 bis 107 (Markierte sterben bei der Hinrichtung des Tages, wenn der Henker lebt; die Liste wird dabei geleert, auch bei Spiegelung und Cerberus-Abwehr).
- **Test:** `test_hangman_mark_expires_and_needs_living_hangman` (`test_fenrir_cerberus_henker.gd`, letzte Zeile: "Markierung verfällt ohne Hinrichtung am Folgetag").
- **Entwurf:** `henker` ergänzt (Verfall mit Beginn der nächsten Nacht).

### OI-15 · König Lykaon: Information (K2)

- **Regelkern:** `bond_steps.gd` Zeile 321 sendet `LYCAON_NOTICE` an die verwandelte Person (nur ihre Rolle, Trugbilderwolf). Der Verbündete erhält keine Mitteilung.
- **Herleitung:** Die Person wacht ab der folgenden Nacht mit dem Rudel auf (V-03, Zeile 429); damit sieht sie das Rudel und das Rudel sieht sie. Die Person ist also ohnehin informiert, und der Verbündete sieht die neue Person in der Folgenacht. Als eigene Entscheidung des Product Owners ist das nicht dokumentiert.
- **Entwurf:** `koenig-lykaon` ergänzt und ein PERSON-PRIVAT-Text "Du bist jetzt Trugbilderwolf." aufgenommen.

## 4. Bewusst später und Integration

- **OI-02 · Totenkarten (K3):** Decision Log Zeile 439 (W-01 = A): Kutscher und Dr. Victor Frankenstein werden ohne Kartenbezug umgesetzt, Kartenbedingungen (RM-DR-141.4) und Kartenschlucker folgen mit dem Totenkarten-Assistenten. `11-role-audit-status.md` §0 (Kartenschlucker blockiert: RM-DR-013, RM-DR-143.1, RM-DR-143.2). Bedingung von RM-DR-141.4 könnte später Zeitpunkt und Ziele von `dr-victor-frankenstein` ändern. Entwurf: kein Kartentext, kein Eintrag für `kartenschlucker`.
- **OI-06 · Richtung "links" (K5):** Decision Log Zeile 308: Gegenprüfung am Tablet, ob die Sitzansicht im Uhrzeigersinn läuft, bleibt offen. `faehrtenleser`, `detektiv` und `{direction}` setzen "links gleich Uhrzeigersinn" voraus. Sollte die Tablet-Ansicht gegen den Uhrzeigersinn laufen, müssen "links" und "rechts" vertauscht werden. Prüfbar erst am UI-Stand.
- **OI-09 · Zufallsknopf (K3):** RM-DR-015.2 (Zeile 320) ist entschieden. König, Traumdeuter, Kopfgeldjäger und Blutpriester nutzen bisher nur die Spielleiterwahl (`11-role-audit-status.md` §0). Sobald der Zufallsknopf umgesetzt ist, müssen die SL-Texte dieser Rollen ergänzt werden.
- **OI-16 · Name der Fraktion "Einzelsieg" (K3, K5):** Decision Log Zeilen 17 und 83: Der Name der Gruppe folgt später. `ui.faction.solo` = "Einzelsieg" (DE) und "Solo" (EN). Die Entwürfe nutzen "Einzelsieg / Solo" als Arbeitsbegriff.
- **OI-18 · Handlungszeilen (K5):** `docs/assets/NARRATOR-SCRIPT.md` §3 enthält `role.<id>.act` nur für die Slice-Rollen. Für alle weiteren Rollen fehlt der Bedienablauf (zeigt die Person, wählt der Spielleiter, oder das Smartphone). Das ist Integrations- und Sprechertextarbeit, keine Regelfrage. GUIDE-TEXTS enthält nur Aufruf und Einschlafen.

## 5. Offene Produktentscheidungen, nach Vorrang

Vorrang bedeutet: Wie viele Entwurfstexte hängen von der Antwort ab, und wie stark verändert sie sichtbares Verhalten. Alle Empfehlungen sind Empfehlungen, keine Entscheidungen. Die ersten vier stelle ich dem Product Owner zuerst.

### D1 · OI-01 Aufrufpolitik (Vorrang 1)

- **Quellen:** `docs/assets/NARRATOR-SCRIPT.md` Zeile 13 (Regel 4: Aufruf klingt gleich, egal ob die Rolle lebt) und Zeile 99 (offene Frage: "Sollen tote Rollen standardmäßig weiter aufgerufen werden?"); `docs/godot-migration/02-product-and-ux-spec.md` Zeile 76 ("Pro Runde einstellbar: 'Tote Rollen weiter aufrufen'"); Decision Log Zeile 318 (blockierte Schritte entfallen protokolliert, nichts zum Aufruf).
- **Szenario:** Der Schutzgeist ist an Tag 3 gestorben, "Rolle beim Tod aufdecken" ist aus. In Nacht 4 sagt die Stimme "Der Schutzgeist erwacht." Alle am Tisch wissen jetzt, wer die Tote war. Ebenso verrät "Der Henker erwacht" nach der dritten Hinrichtung, dass die Rolle in der Partie ist.
- **A:** Alle Rollen des Katalogs werden jede Nacht aufgerufen (maximale Tarnung, aber bei 71 Rollen viele Minuten je Nacht).
- **B:** Jede Rolle, die in der Partie vorkommt, wird jede Nacht aufgerufen, auch tot, blockiert oder noch nicht aktiv (Tarnaufruf mit fester Wartezeit, Einstellung "Tote Rollen weiter aufrufen" standardmäßig an). Der Tisch erfährt die Rollen der Partie, nicht wer sie hat und ob sie wirken.
- **C:** Nur aktuell handelnde Rollen werden aufgerufen. Das ist am schnellsten, verrät aber Zustand und Anwesenheit (Tod, Blockade, Schwellen).
- **Empfehlung: B.** Es ist der klassische Ablauf, zeitlich tragbar und verrät nur die Rollenzusammensetzung. Die frühere Empfehlung dieser Liste (A) wäre bei 71 Rollen zu lang.
- **Wirkung:** GUIDE-TEXTS §3.3 (47 Aufrufzeilen) und die Frage, ob Schutzgeist, Henker, Kopfgeldjäger, König, Kutscher, Dorfschmied, Rachsüchtiger Wolf und Schicksalswolf überhaupt einen Aufruf erhalten.

### D2 · OI-12 Loki: Wer erfährt von der Bindung (Vorrang 2)

- **Quellen:** Decision Log Zeile 411 (B-05): Wahl und Wirkung sind geregelt, nicht aber, ob Liebende oder Rivalen von der Bindung erfahren. Der Regelkern meldet `LOKI_BOUND` nur dem Spielleiter.
- **Szenario:** In Nacht 1 verbindet Loki Anna und Ben als Liebende. An Tag 2 wird Anna hingerichtet, Ben stirbt sofort an Liebeskummer. Ben wusste nichts von der Bindung.
- **A:** Nur Loki und der Spielleiter wissen es (Stand des Regelkerns). Die Liebenden merken es erst durch den Tod, Rivalen nie.
- **B:** Liebende und Rivalen erfahren privat den Namen ihres Partners und die Art der Bindung.
- **C:** Liebende erfahren einander privat, Rivalen erfahren nichts.
- **Empfehlung: C.** Liebende, die einander nicht kennen, sterben zufällig gemeinsam, was die Rolle sinnlos macht. Rivalen haben keine eigene Wirkung, sie nicht zu informieren schützt die Wahl der Schwarzen Witwe.
- **Wirkung:** PERSON-PRIVAT-Text für `loki`, Spielleitertext von `schwarze-witwe`.

### D3 · OI-13 Rotkäppchen: Wer erfährt von Kette und Apfel (Vorrang 3)

- **Quellen:** Decision Log Zeile 416 (R-01): Die gefragte Person darf ablehnen; gewährt sie Zuflucht, erhält sie einen Apfel und ist verkettet. Der Regelkern meldet `RED_REFUGE` und `APPLE_USED` nur dem Spielleiter.
- **Szenario:** Rotkäppchen fragt in Nacht 2 Ben. Ben gewährt Zuflucht. In Nacht 3 läuft sein Nachtschritt zweimal, an Tag 4 wird er hingerichtet und Rotkäppchen stirbt mit. Wusste Ben bei seiner Antwort, dass er sich damit ketten würde?
- **A:** Die gefragte Person erfährt vor ihrer Antwort Apfel und Kette. Sie entscheidet mit voller Kenntnis.
- **B:** Sie erfährt nur den Apfel (er zeigt sich ohnehin im doppelten Schritt), die Kette bleibt geheim.
- **C:** Niemand außer dem Spielleiter kennt Apfel und Kette. Die Person merkt nur den doppelten Schritt.
- **Empfehlung: A.** Weil die Regel der gefragten Person ausdrücklich das Recht zur Ablehnung gibt (auch Wölfen), ist eine Ablehnung nur sinnvoll, wenn die Folgen bekannt sind.
- **Wirkung:** PERSON-PRIVAT-Text für `rotkaeppchen`, Bedienablauf der Frage (OI-18).
- **Teilweise aufgelöst:** Dass die gefragte Person weiß, dass sie gefragt wird, folgt daraus, dass sie antwortet.

### D4 · OI-17 Rattenfänger und Pestbringerin: Information der Betroffenen (Vorrang 4)

- **Quellen:** Decision Log Zeilen 448 und 449 (E-01, E-02) regeln Wirkung und Sieg, nicht die Information. Der Regelkern meldet `INFECTED` nur dem Spielleiter.
- **Szenario:** Nacht 1: Der Rattenfänger verzaubert Anna und Ben; die Pestbringerin infiziert Clara, am Morgen steckt Clara David an. Erfahren Anna, Ben, Clara oder David davon?
- **A:** Niemand außer dem Spielleiter. Der Sieg (alle anderen verzaubert oder infiziert) kommt als Überraschung, das Dorf hat kein Gegenspiel.
- **B:** Alle Betroffenen erfahren es privat.
- **C:** Verzauberte erfahren es privat, Infizierte nicht.
- **Empfehlung: C.** Verzauberte können das Dorf warnen (Gegenspiel gegen den Rattenfänger). Die Pest lebt von der verdeckten Ausbreitung, eine Meldung würde zudem den gezogenen Nachbarn verraten. Die Empfehlung ist unsicher, weil keine Quelle das Ziel der Rolle beschreibt.
- **Wirkung:** PERSON-PRIVAT-Texte für `rattenfaenger` und `pestbringerin`.

### D5 · OI-19 Trugbilderwolf: Kennt er seine Scheinrolle (Vorrang 5)

- **Quellen:** Decision Log Zeilen 110 und 176 (DR-08): Der Spielleiter legt die Scheinrolle im Setup fest. Keine Quelle sagt, ob der Trugbilderwolf sie erfährt.
- **Szenario:** Clara ist Trugbilderwolf mit der Scheinrolle "Waldhexe". Am Tag behauptet sie, Waldhexe zu sein. Kennt sie die Scheinrolle, die das Orakel sieht?
- **A:** Ja, ihre private Karte zeigt sie.
- **B:** Nein, nur der Spielleiter kennt sie.
- **C:** Der Spielleiter entscheidet im Setup je Partie.
- **Empfehlung: A.** Sie kann dann stimmig bluffen, so wie das Orakel es bestätigen würde.
- **Wirkung:** ein Satz im PERSON-PRIVAT-Text von `trugbilderwolf`.

### D6 · OI-11 (b) Weiser: Ansage zum Fluch (Vorrang 6)

- **Quellen:** Decision Log Zeile 390 (S-01): Länge legt der Spielleiter fest. Der Regelkern meldet den Fluch nur dem Spielleiter (`SAGE_CURSED`).
- **Szenario:** Ben, der Weise, wird hingerichtet, der Spielleiter setzt 2. In den folgenden Nächten und Tagen handeln alle Dorfpersonen nicht. Der Tisch merkt nur, dass nichts geschieht.
- **A:** Keine Ansage (Stand des Regelkerns). Es verrät nichts, der Tisch rätselt.
- **B:** Öffentlich "Die Fähigkeiten des Dorfes ruhen", ohne Länge.
- **C:** Öffentlich mit Länge.
- **Empfehlung: A.** B und C würden bei ausgeschalteter Rollenaufdeckung die Rolle des Hingerichteten verraten.
- **Wirkung:** nur GUIDE-TEXTS §3.4 (`der-weise`).

### D7 · OI-07 Ton bei fünf Toten: Bestätigung der gewählten Ausnahme (nur optional)

- **Stand:** entschieden (Decision Log Zeile 284), Nebenwirkung in Abschnitt 3 beschrieben. Eine Rückfrage ist nur nötig, wenn der Product Owner die Nebenwirkung neu bewertet.
- **Szenario:** Fünf Personen sind tot. Der Ton erklingt. Alle wissen: Ein Selbstmörder ist in der Partie. Ohne Ton bei fünf Toten wissen sie: keiner.
- **A:** Wie entschieden: Ton nur mit Selbstmörder in der Partie.
- **B:** Ton bei fünf Toten in jeder Partie (verrät nichts über die Rollen).
- **C:** Kein Ton, stattdessen ein privater Hinweis an den Selbstmörder.
- **Empfehlung: A beibehalten,** solange die Runde die Rollenzusammensetzung ohnehin kennt. B ist die sichere Alternative, wenn Rollen geheim bleiben sollen.
