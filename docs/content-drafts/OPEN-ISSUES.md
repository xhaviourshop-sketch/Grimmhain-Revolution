# Offene Punkte und Quellenkonflikte (Entwurf)

**Status:** Entwurf. Stand: Quell-Commit `312f5bbbbec4c218754b35a0043b51e79d80bcf5` (`audit/all-72-roles`), Bearbeitung 29.09.2026. Diese Liste entscheidet nichts. Sie benennt, wo Quellen sich widersprechen oder schweigen, welche Entwürfe betroffen sind und was die Entwürfe bis zur Entscheidung tun.
Typen: **Konflikt** (zwei Quellen sagen Verschiedenes), **Lücke** (keine Quelle regelt es), **Hinweis** (kein Widerspruch, aber der Abgleich mit UI- oder Regelstand steht aus).
Zeilennummern beziehen sich auf den Quell-Commit.

Kartenschlucker (`kartenschlucker`) ist ausdrücklich zurückgestellt (`11-role-audit-status.md` §0 "Einzige blockierte Rolle: Kartenschlucker"). Es gibt keinen Entwurf und keine Totenkartenregel.

## Übersicht

| ID | Typ | Thema | Betroffene Entwürfe |
|---|---|---|---|
| OI-01 | Lücke | Aufrufpolitik für Rollen mit erkennbarer Anwesenheit, blockierte und nicht vorhandene Rollen | GUIDE-TEXTS §3.3; Schattenhund, Albtraumwolf, Wolfskind, Lehrling |
| OI-02 | Lücke | Totenkarten (Kutscher, Frankenstein, Kartenschlucker) | rolebook 03 `kutscher`, `dr-victor-frankenstein` |
| OI-03 | Konflikt | Siegreicher Wolf: Register zählt einfach, Umsetzung doppelt, keine ausdrückliche Bestätigung | rolebook 04 `siegreicher-wolf` |
| OI-04 | Konflikt | Begriffe in `ui.*.po` weichen vom Decision Log ab | TERMINOLOGY; alle Kurztexte |
| OI-05 | Konflikt | Überholte Regelregister-Texte (einmal pro Partie, erste Nacht, Gift sofort) | rolebook 02, 03; alle Einmalfähigkeiten |
| OI-06 | Hinweis | "Links" gleich Uhrzeigersinn ist am Tablet nicht gegengeprüft | `faehrtenleser`, `detektiv`, GUIDE-TEXTS |
| OI-07 | Konflikt | Ton bei 5 Toten verrät den Selbstmörder trotz Geheimhaltungsregel | `selbstmoerder` |
| OI-08 | Lücke | Traumdeuter und Kopfgeldjäger ohne mögliche Auswahl | `traumdeuter`, `kopfgeldjaeger` |
| OI-09 | Hinweis | Zufallsknopf ist noch nicht umgesetzt | `koenig` und weitere |
| OI-10 | Lücke | Amalia: Format der Frage | `amalia` |
| OI-11 | Lücke | Öffentliche Ansagen und Rollenaufdeckung beim Tod | `schutzgeist`, `der-weise` |
| OI-12 | Lücke | Loki: Wer erfährt von der Bindung | `loki` |
| OI-13 | Lücke | Rotkäppchen: Wer erfährt von Kette und Apfel | `rotkaeppchen` |
| OI-14 | Lücke | Henker: Hinrichtung am Folgetag bleibt aus | `henker` |
| OI-15 | Lücke | König Lykaon: Information der verwandelten Person | `koenig-lykaon` |
| OI-16 | Hinweis | Name der Fraktion "Einzelsieg" ist nicht entschieden | rolebook 06, 07 |
| OI-17 | Lücke | Rattenfänger, Pestbringerin: Information der Betroffenen | `rattenfaenger`, `pestbringerin` |
| OI-18 | Lücke | Handlungszeilen ("Zeige auf ...") für Nicht-Slice-Rollen | GUIDE-TEXTS §3.3 |
| OI-19 | Lücke | Trugbilderwolf: Kennt er seine Scheinrolle | `trugbilderwolf` |

## Einzelne Punkte

### OI-01 · Aufrufpolitik (Lücke)

- **Quellen:** `docs/assets/NARRATOR-SCRIPT.md` Zeile 13 (Regel 4: Aufruf klingt gleich, egal ob die Rolle lebt, "Tarnaufrufe toter Rollen") und Zeile 99 (offene Frage: "Sollen tote Rollen standardmäßig weiter aufgerufen werden?"); `docs/godot-migration/02-product-and-ux-spec.md` Zeile 76 ("Pro Runde einstellbar: 'Tote Rollen weiter aufrufen'"); DECISION-LOG Zeile 318 (Blockade: Schritte entfallen "protokolliert", nichts zum Aufruf).
- **Offen:** (a) Ob Rollen, die nur bei Vorhandensein aufgerufen würden (Wolfskind und Lehrling "nur mit Auswahlbedarf", Schattenhund, Albtraumwolf, Einzelsiegrollen), namentlich aufgerufen werden dürfen, weil der Aufruf ihre Anwesenheit verrät. (b) Ob blockierte Rollen trotzdem aufgerufen werden. (c) Ob Rollen, die in der Partie nicht vorkommen, Tarnaufrufe erhalten.
- **Entwurf:** GUIDE-TEXTS §3.3 folgt dem Muster des NARRATOR-SCRIPT (Aufruf und Einschlafen mit dem Rollennamen) für alle 47 Rollen mit eigenem Schritt. Das ist ein Muster, keine Entscheidung.
- **Empfehlung:** Die Runde stellt "Tote und fehlende Rollen weiter aufrufen" ein; Aufruf für jede Rolle im Katalog oder für keine, damit die Anwesenheit nie am Aufruf erkennbar ist.

### OI-02 · Totenkarten (Lücke)

- **Quellen:** DECISION-LOG Zeilen 439 (W-01: Kutscher und Frankenstein "ohne Kartenbezug", Kartenbedingungen RM-DR-141.4 und Kartenschlucker folgen mit dem Totenkarten-Assistenten); `11-role-audit-status.md` §0 (Kartenschlucker blockiert: RM-DR-013, RM-DR-143.1, RM-DR-143.2).
- **Wirkung:** `kutscher` und `dr-victor-frankenstein` sind ohne Kartenbedingung beschrieben. Falls RM-DR-141.4 später eine Bedingung ergänzt, ändern sich Zeitpunkt und Ziele von `dr-victor-frankenstein`.
- **Entwurf:** Kein Text zu Karten, kein Eintrag für `kartenschlucker`.

### OI-03 · Siegreicher Wolf (Konflikt und fehlende Bestätigung)

- **Quellen:** `docs/specs/vertical-slice/rules-register.md` Zeile 78 (G-SIEG-2: "Im Slice zählt jeder Wolf einfach (Siegreicher Wolf ist nicht enthalten)") gegen `11-role-audit-status.md` Zeilen 74 und 139 (umgesetzt, `parity_weight` 2) und `docs/role-migration/10-next-decisions.md` Zeile 68 ("Zur Kenntnis, keine Frage ... Wenn du das anders willst, sag es bitte").
- **Befund:** Die Zählregel folgt dem Rollentext und wurde umgesetzt, der Product Owner hat sie aber nicht ausdrücklich ausgewählt. G-SIEG-2 beschreibt nur den Stand des Vertical Slice.
- **Entwurf:** `siegreicher-wolf` folgt der Umsetzung (doppelt in der Parität) und trägt den Status "Auslegung ohne ausdrückliche Bestätigung".

### OI-04 · Begriffe in den Übersetzungsdateien (Konflikt)

- **Quellen:** DECISION-LOG Zeile 316 (RM-DR-004: Wolfsangriff ist ausschließlich der Rudelangriff) und Zeilen 24 und 131 (Hinrichtung, Lynch als interne Ursache) gegen `godot/content/i18n/ui.de.po` Zeilen 414, 516, 600, 630, 672, 684, 690, 696 und `ui.en.po` Zeilen 414, 516, 600, 630, 672, 684, 690, 696 ("Wolfsangriff", "wolf attack", "werewolf attack", "gelyncht", "lynched", "his", "her"). Schlüssel wie `ui.role.das_orakel.*` nutzen Unterstriche, DR-01 legt kebab-case für Rollen-IDs fest.
- **Entwurf:** [`TERMINOLOGY.md`](TERMINOLOGY.md) §4 legt "Rudelangriff / pack attack", "Hinrichtung / execution" und neutrale Pronomen fest. Die `.po`-Dateien wurden nicht geändert.
- **Zu tun später:** Kurztexte im Rahmen der Übersetzungsarbeit angleichen. Die Schlüsselbildung ist eine Integrationsfrage.

### OI-05 · Überholte Texte im Regelregister (Konflikt, bereits entschieden)

Die Entwürfe folgen dem jüngeren Decision Log. Im Regelregister stehen noch ältere Formulierungen ohne Änderungsvermerk:

| Stelle im Register | Älterer Text | Ersetzt durch (DECISION-LOG) |
|---|---|---|
| `rules-register.md` Zeile 200 und 205 (Waldhexe) | "Einmal pro Partie", "für die ganze Partie (G-ID-3)" | Zeilen 301 bis 303: Einsätze gelten je Leben, jede Wiederbelebung setzt sie zurück |
| Zeile 225 (Sensenträger) | "einmal pro Partie" | Zeile 301: je Leben |
| Zeile 249 (Wolfskind) | "In seiner ersten Nacht wählt" | Zeile 183: jede Nacht, solange unverwandelt und ohne Vorbild (ein regulär gestartetes Wolfskind handelt in Nacht 1) |
| Zeile 272 (Lehrling) | "in der ersten Nacht" | Zeilen 210 bis 212: erste verfügbare Nacht ohne Bindung |
| DR-06 (Zeile 108) | "Gift tötet sofort" | Zeilen 280 bis 283: Todesmarkierung, Tod in der Morgenauflösung |

- **Entwurf:** Alle Einträge folgen den Ersatztexten. Das Register sollte bei nächster Gelegenheit Vermerke erhalten (nicht Teil dieses Auftrags).

### OI-06 · Richtung "links" (Hinweis)

- **Quellen:** DECISION-LOG Zeile 308 ("Gegenprüfung am Tablet, ob die Sitzansicht im Uhrzeigersinn läuft, bleibt offen"); `11-role-audit-status.md` §0 (letzter Punkt).
- **Entwurf:** `faehrtenleser`, `detektiv` und `{direction}` in GUIDE-TEXTS setzen "links gleich Uhrzeigersinn" voraus. Sollte die Tablet-Ansicht gegen den Uhrzeigersinn laufen, müssen "links" und "rechts" vertauscht werden.

### OI-07 · Ton bei 5 Toten (Konflikt)

- **Quellen:** DECISION-LOG Zeile 270 ("ob er nur bei einem Selbstmörder im Spiel und öffentlich ertönt, ist noch offen, weil er sonst dessen Anwesenheit verraten kann") und Zeile 284 (Entscheidung: ertönt, sobald die fünfte Person tot ist, öffentlich, nur wenn ein Selbstmörder in der Partie ist) gegen Zeile 45 ("Öffentliche Projektion erhält niemals geheime Daten") und Zeile 106 (DR-04).
- **Befund:** Ein Ton, der nur mit Selbstmörder in der Partie erklingt, verrät dessen Anwesenheit allen am Tisch.
- **Entwurf:** Es gibt keinen öffentlichen Text zum Ton. `selbstmoerder` weist im Lexikon auf den Punkt hin.
- **Empfehlung:** Ton bei fünf Toten in jeder Partie oder gar nicht.

### OI-08 · Traumdeuter und Kopfgeldjäger ohne mögliche Auswahl (Lücke)

- **Quellen:** DECISION-LOG Zeilen 370 (I-01: Bestätigen erst bei mindestens einem Wolf und drei Personen), 374 (I-04: bei zu wenigen Zielen verfällt die Liste mit Hinweis, nur Kopfgeldjäger). Für den Traumdeuter regelt keine Entscheidung, was gilt, wenn weniger als drei andere Personen leben oder kein Wolf lebt. Der Regelkern prüft `triple_possible` (`godot/core/rules/info_steps.gd` Zeilen 93 bis 95: mindestens drei andere Lebende, darunter ein Wolf).
- **Entwurf:** Im Lexikon steht der Verweis auf OI-08, ohne eine Regel zu erfinden.

### OI-09 · Zufallsknopf (Hinweis)

- **Quelle:** `11-role-audit-status.md` §0 vorletzter Punkt (RM-DR-015.2, DECISION-LOG Zeile 320: Wählen und Zufallsknopf); König, Traumdeuter, Kopfgeldjäger und Blutpriester nutzen bisher nur die Spielleiterwahl.
- **Entwurf:** Die Texte sprechen von "du wählst". Kommt der Zufallsknopf, müssen die SL-Texte dieser Rollen ergänzt werden.

### OI-10 · Amalia: Format der Frage (Lücke)

- **Quellen:** DECISION-LOG Zeile 379 (I-09: "öffentliche Ja/Nein-Frage", Spielleiter antwortet "wahrheitsgemäß") und Legacy-Rollentext (`js/core/roles.js`, "öffentlich eine Ja-/Nein-Frage zu stellen"). Keine Quelle sagt, ob die Frage sich nur auf Rollen, Wölfe oder beliebige Tatsachen beziehen darf, oder wie der Spielleiter "wahrheitsgemäß" bei nicht prüfbaren Fragen antwortet.
- **Entwurf:** Das Beispiel in `amalia` nennt "Ist Ben ein Wolf?" nur als Beispiel. Kein Format ist festgelegt.

### OI-11 · Öffentliche Ansagen und Rollenaufdeckung (Lücke)

- **Quellen:** DECISION-LOG Zeile 106 (DR-04: Rolle beim Tod öffentlich nur mit Setup-Option), Zeile 398 (S-04: Schutzgeist, Ansage "ohne Namen, dass sie einen Wolf gewählt hat"), Zeile 390 (S-01: Fluch des Weisen, Länge legt der Spielleiter fest). Nicht geregelt: (a) ob die Ansage des Schutzgeists den Rollennamen nennen darf, wenn die Rollenaufdeckung beim Tod ausgeschaltet ist; (b) ob die Länge des Fluchs des Weisen öffentlich genannt wird (ohne Ansage merkt der Tisch trotzdem, dass Fähigkeiten ruhen).
- **Entwurf:** `schutzgeist` nennt den Rollennamen (Entwurf). Für `der-weise` gibt es keine öffentliche Ansage.

### OI-12 · Loki: Information der Betroffenen (Lücke)

- **Quelle:** DECISION-LOG Zeile 411 (B-05): Wahl und Wirkung sind geregelt, nicht aber, ob Liebende oder Rivalen von der Bindung erfahren, und ob sie einander sehen.
- **Entwurf:** kein PERSON-PRIVAT-Text für `loki` (GUIDE-TEXTS §3.2 "ungeklärt").

### OI-13 · Rotkäppchen: Information der Verketteten (Lücke)

- **Quelle:** DECISION-LOG Zeile 416 (R-01): Person "erhält einen Apfel und ist verkettet". Ob und wie sie das erfährt, ob die gefragte Person überhaupt hört, dass Rotkäppchen fragt, steht nirgends.
- **Entwurf:** kein PERSON-PRIVAT-Text für `rotkaeppchen`.

### OI-14 · Henker: ausbleibende Hinrichtung (Lücke)

- **Quelle:** DECISION-LOG Zeile 363 (RM-DR-130.3): Markierte Person stirbt "bei der Hinrichtung des folgenden Tages". Nicht geregelt: Verfällt die Markierung, wenn am Folgetag keine Hinrichtung stattfindet, oder bleibt sie bis zur nächsten?
- **Entwurf:** Verweis auf OI-14 im Lexikon, keine Regel.

### OI-15 · König Lykaon: Information (Lücke)

- **Quelle:** DECISION-LOG Zeile 429 (V-03): Die Person wird Trugbilderwolf und wacht mit dem Rudel auf. Ob sie es privat erfährt, und ob der genannte Verbündete informiert wird, ist nicht geregelt.
- **Entwurf:** kein PERSON-PRIVAT-Text für `koenig-lykaon`.

### OI-16 · Name der Fraktion "Einzelsieg" (Hinweis)

- **Quelle:** DECISION-LOG Zeilen 17 und 83 ("Name für die Gruppe der Einzelsiegrollen folgt später"); `ui.de.po` `ui.faction.solo` = "Einzelsieg", `ui.en.po` = "Solo".
- **Entwurf:** verwendet "Einzelsieg / Solo" als Arbeitsbegriff.

### OI-17 · Rattenfänger und Pestbringerin: Information (Lücke)

- **Quelle:** DECISION-LOG Zeilen 448 und 449 (E-01, E-02): Ob Verzauberte oder Infizierte davon erfahren, steht nicht in den Entscheidungen.
- **Entwurf:** kein PERSON-PRIVAT-Text für `rattenfaenger` und `pestbringerin`.

### OI-18 · Handlungszeilen (Lücke)

- **Quelle:** `docs/assets/NARRATOR-SCRIPT.md` §3 enthält `role.<id>.act` nur für die Slice-Rollen (Wolfskind, Lehrling, Schutzengel, Werwolf, Waldhexe, Orakel). Für alle weiteren Rollen fehlt der Bedienablauf (zeigt die Person, wählt der Spielleiter, oder das Smartphone?).
- **Entwurf:** GUIDE-TEXTS enthält nur Aufruf und Einschlafen. `act`-Zeilen bleiben den Slice-Rollen im NARRATOR-SCRIPT vorbehalten.

### OI-19 · Trugbilderwolf: Kenntnis der Scheinrolle (Lücke)

- **Quellen:** DECISION-LOG Zeilen 110, 176 (DR-08: Spielleiter wählt die Scheinrolle im Setup). Nicht geregelt: ob der Trugbilderwolf seine eigene Scheinrolle erfährt.
- **Entwurf:** `trugbilderwolf` PERSON-PRIVAT nennt nur Rolle und Rudel.
