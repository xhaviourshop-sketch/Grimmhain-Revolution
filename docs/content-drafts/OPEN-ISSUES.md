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

Von 19 Punkten bleibt kein einziger als echter Regelwiderspruch (K1) bestehen. Zwölf Punkte sind aufgelöst oder beantwortet (K2: OI-01, OI-03, OI-05, OI-07, OI-08, OI-11, OI-12, OI-13, OI-14, OI-15, OI-17, OI-19). Sieben sind bewusst spätere Erweiterung, Formulierungs- oder Integrationsfrage (K3, K5: OI-02, OI-04, OI-06, OI-09, OI-10, OI-16, OI-18). Es bleibt keine offene Produktentscheidung mit Vorrang; offene Randfälle stehen in Abschnitt 5 und in `DECISIONS-TO-INTEGRATE.md`.

| ID | Thema | Vorher | Klasse jetzt | Ergebnis |
|---|---|---|---|---|
| OI-01 | Aufrufpolitik für bedingte, blockierte und fehlende Rollen | Lücke | K2 | beantwortet am 29.09.2026 (DI-02), Randfälle zu bestätigen |
| OI-02 | Totenkarten (Kutscher, Frankenstein, Kartenschlucker) | Lücke | K3 | bewusst später (W-01 = A), keine Entscheidung für die Entwürfe nötig |
| OI-03 | Siegreicher Wolf zählt doppelt | Konflikt | K2 | Fehlalarm, aufgelöst; nur ein Hinweis bleibt |
| OI-04 | Begriffe in `ui.*.po` | Konflikt | K5 | kein Regelkonflikt, teilweise Fehlalarm; Angleichung ist Übersetzungsarbeit |
| OI-05 | Überholte Regelregister-Texte | Konflikt | K2 | vom Decision Log bereits ersetzt; Vermerk im Register steht aus |
| OI-06 | "Links" gleich Uhrzeigersinn | Hinweis | K5 | Tablet-Gegenprüfung steht aus |
| OI-07 | Ton bei fünf Toten | Konflikt | K2 | gewählte Ausnahme mit dokumentierter Nebenwirkung, kein erwiesener Fehler; am 29.09.2026 bestätigt (DI-09) |
| OI-08 | Traumdeuter und Kopfgeldjäger ohne mögliche Auswahl | Lücke | K2 | aus gemeinsamer Regel, Code und Test belegt, Entwurf ergänzt |
| OI-09 | Zufallsknopf | Hinweis | K3 | entschieden (RM-DR-015.2), im Programm umgesetzt (29.09.2026); Spielleitertexte stehen aus |
| OI-10 | Amalia: Format der Frage | Lücke | K5 | aufgelöst: Die App prüft die Frage nicht, Entwurf ergänzt |
| OI-11 | Öffentliche Ansagen (Schutzgeist, Weiser) | Lücke | K2 | (a) Schutzgeist aufgelöst, Entwurf geändert; (b) Weiser durch die Regel der Todeseffekte beantwortet (DI-03) |
| OI-12 | Loki: Wer erfährt von der Bindung | Lücke | K2 | beantwortet vom Product Owner am 29.09.2026 (Chat), Decision-Log-Eintrag steht aus |
| OI-13 | Rotkäppchen: Wer erfährt von Kette und Apfel | Lücke | K2 | beantwortet vom Product Owner am 29.09.2026 (Chat), Decision-Log-Eintrag steht aus |
| OI-14 | Henker: Hinrichtung am Folgetag bleibt aus | Lücke | K2 | Decision Log, Code und Test belegen: Markierung verfällt; Entwurf ergänzt |
| OI-15 | König Lykaon: Information der verwandelten Person | Lücke | K2 | Regelkern meldet privat; Rudel sieht die Person ab der Folgenacht; Entwurf ergänzt |
| OI-16 | Name der Fraktion "Einzelsieg" | Hinweis | K3, K5 | Decision Log: "folgt später"; Arbeitsbegriff bleibt |
| OI-17 | Rattenfänger, Pestbringerin: Information der Betroffenen | Lücke | K2 | beantwortet vom Product Owner am 29.09.2026 (Chat), Decision-Log-Eintrag steht aus; ein Detail offen |
| OI-18 | Handlungszeilen für Nicht-Slice-Rollen | Lücke | K5 | Integrationsfrage (NARRATOR-SCRIPT), keine Regelfrage |
| OI-19 | Trugbilderwolf: Kennt er seine Scheinrolle | Lücke | K2 | beantwortet am 29.09.2026: nur der Spielleiter (DI-08) |

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

## 5. Entscheidungsstand

Alle Antworten des Product Owners vom 29.09.2026 sind mit Herkunft, Auswirkungen und Akzeptanztests in [`DECISIONS-TO-INTEGRATE.md`](DECISIONS-TO-INTEGRATE.md) festgehalten. Sie stehen noch nicht im Decision Log.

| Frühere Nummer | Thema | Stand |
|---|---|---|
| D1 (OI-01) | Aufrufpolitik | beantwortet (DI-02); Randfälle abgeleitet und zu bestätigen |
| D2 (OI-12) | Loki | beantwortet (DI-04) |
| D3 (OI-13) | Rotkäppchen | beantwortet (DI-05) |
| D4 (OI-17) | Rattenfänger, Pestbringerin | beantwortet (DI-06, DI-07) |
| D5 (OI-19) | Scheinrolle des Trugbilderwolfs | beantwortet (DI-08) |
| D6 (OI-11 b) | Fluch des Weisen | durch die Regel der Todeseffekte beantwortet (DI-03) |
| D7 (OI-07) | Ton bei fünf Toten | bestätigt (DI-09) |
| neu | Rollenaufdeckung und Wiederbelebungsrunde | beantwortet (DI-01), ändert die bisherige Produktvorgabe |

**Verbleibende Randfälle** (keine Blocker für die Entwürfe):
1. Nennt die Ansage bei Liebeskummer, Kette und Verknüpfung eine Rolle, und wird die Länge des Fluchs des Weisen genannt? (DI-03)
2. Findet die Phase "Alle Verzauberten" auch in Nächten ohne neu Verzauberte statt? (DI-06)
3. Bedeutung von "Selbstmörder in der Partie" für den Ton (Rolle zu Spielbeginn oder lebende Person). (DI-09)
4. Aufruf blockierter und noch nicht aktiver Rollen sowie nicht vorkommender Rollen: abgeleitet, zu bestätigen. (DI-02)
5. Ob die Setup-Anzeige der Wiederbelebungsrunde überstimmt werden darf, und Warnung bei indirekten Trägern. (DI-01)
6. Totenreichkarten sind nicht definiert (OI-02).
