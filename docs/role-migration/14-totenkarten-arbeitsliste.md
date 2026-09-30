# Totenkarten: Arbeitsliste zur vollständigen Überarbeitung

Stand: 30.09.2026 (zweite Runde), Branch `feature/night-ui-expansion`. **Arbeitsmaterial**, keine Regelquelle: Es ersetzt den Decision Log nicht und beschließt nichts. Verbindliche Entscheidungen stehen in [`../masterplan/DECISION-LOG.md`](../masterplan/DECISION-LOG.md) (Abschnitte „Totenkarten und Kartenschlucker, Entscheidungen vom 30.09.2026“ und „Kartenschlucker, Grundregeln (zweite Antwortrunde, 30.09.2026)“). Die frühere Vorlage [`13-totenkarten-kartenschlucker-vorlage.md`](13-totenkarten-kartenschlucker-vorlage.md) bleibt die Entscheidungsvorlage. Es ist **keine Kartenmechanik, keine Kartenverteilung, kein Kartentausch und kein Kartenschlucker implementiert**, und es gibt keine vorläufigen Dummy-Regeln.

## 1. Kennzeichnung

| Marke | Bedeutung |
|---|---|
| **[R]** | Vorhandener Regeltext, unverändert aus `js/core/cards.js` übernommen (Legacy-Bestand, kein Produktbeschluss über die Karte). |
| **[B]** | Bereits bestätigte Produktentscheidung (Decision Log). |
| **[V]** | Änderungsvorschlag oder Ableitung von Claude. Nicht entschieden, nur Diskussionsgrundlage. |

Keine Karte wird hier entfernt, freigegeben, umgedeutet oder vereinfacht. Dass eine Karte aufwendig umzusetzen wäre, ist kein Grund, sie zu ändern. Stimmen werden weiterhin am Tisch gezählt; nötige Ergebnisse trägt die Spielleitung (SL) ein.

## 2. Befund zum tatsächlichen Bestand

Gelesen und mit Skript ausgewertet: `js/core/cards.js` (`TOTENKARTEN`, `ALLE_KARTEN`). Die Angabe „80 Karten“ trifft zu, wurde aber gezählt, nicht übernommen.

- **80 Karten, 80 eindeutige IDs.** Je Kategorie: SEGEN 14, SCHICKSAL 14, FLUCH 13, WENDE 12, LOKI 13, SOLO 14.
- **Textform:** 39 Karten (SEGEN, FLUCH, WENDE) haben je einen Text für Wölfe und für Dorfbewohner (`wolf`, `dorf`), 27 (SCHICKSAL, LOKI) einen neutralen Text, 14 (SOLO) einen Solo-Text. Das widerspricht Entscheidung 1A nicht: Die Vergabe (jede Person bekommt beim Tod eine Karte) und der Kartentext je Fraktion oder Rolle sind unabhängige Dinge. Offen ist nur, welche Karten für wen in Frage kommen (ÜB-1).
- **Doppelter Name „Anarchie“:** `schicksal_10` (verbrauchte Einmalfähigkeit der eigenen Fraktion kehrt zurück) und `loki_07` (alle Schutzeffekte fallen, alle Einmalfähigkeiten kehren für alle zurück). Die Wirkungen sind verschieden.
- **Kartenbedingung (`deathCardRequirements`):** 4 Karten (`segen_08`, `wende_04`, `wende_07`, `loki_10`), alle mit „lebende Person mit Rollen-Tag revive, role-return oder death-trigger-transform“. `wende_12` (Dorf-Text) nennt eine ähnliche Bedingung nur im Text.
- **Fast gleiche Karten:** `schicksal_06` Zeitsprung und `loki_03` Zeitwarp (Nacht überspringen); `schicksal_12` Totengericht und `solo_13` Das Totenreich Regiert; `schicksal_09` Stimmentausch und `loki_01` Spiegelwelt.
- **Nur deutsche Texte im Legacy-Code.** Die EN-Namen sind nur zu 46 von 80 gemappt (`docs/godot-migration/01-current-system-inventory.md` §4.6, nicht neu gezählt). Kartenbilder gibt es nicht.
- **Legacy-Automatisierung:** Kein Karteneffekt ist automatisiert (Inventar §4.6). In `godot/` gibt es keine Kartenmechanik, nur Hinweistexte zur offenen Kartenbedingung (`godot/content/i18n/ui.de.po`, `cockpit_view.gd`, `role_catalog.gd`).
- **Legacy-Ziehung (nur Herkunft, nicht verbindlich):** Nicht-Wölfe beim Start, Wölfe beim Tod, Gewichtung nach Kategorie und „wer liegt zurück“, Solo-Personen fast nur SOLO-Karten (`zieheZufallsKarte`). Entscheidung 1A ersetzt das Vergabezeitpunkt-Modell; der Rest ist offen (ÜB-1, ÜB-6).

## 3. Bereits bestätigte Entscheidungen [B]

Ausführlich mit Herkunft im Decision Log. Hier nur die Kurzfassung, damit die Fragen unten nichts Entschiedenes wiederholen.

| ID | Kern | Noch offen |
|---|---|---|
| 1A | Jede Person erhält beim Tod eine Karte, unabhängig von der Fraktion. Nach Wiederbelebung und erneutem Tod eine neue Karte. | Welche Karten für wen in Frage kommen (ÜB-1, KS-16). |
| 2C | ALLE Karten werden vor der Umsetzung gemeinsam überarbeitet. Mechanische Wirkung später im Spiel, reale Handlungen mit Anweisung, Bestätigung/Eingabe je Karte. Bis dahin kein Code. | Alles je Karte (diese Liste). |
| 3A + zweite Runde | Ein Toter darf seine Karte einmal tauschen, nur solange eine lebende Person die Rolle Kartenschlucker besitzt. Jeder zulässige Tausch gibt einen Stapel. Ersatzkarte sofort gespielt, nicht erneut tauschbar; nach Wiederbelebung und erneutem Tod wieder möglich. | Öffentlichkeit und Ablauf des Tauschs (KS-15), Zeitpunkt des Spielens (KS-09). |
| 4B + zweite Runde | Kartenschlucker wird jede Nacht geweckt und wählt genau eine Aktion: Kopf schütteln (nichts), zwei Finger (zwei Stapel abgeben, eine Person töten, freiwillig, höchstens einmal), fünf Finger (fünf Stapel abgeben, Schild kaufen), zehn Finger (zehn Stapel abgeben, Sieg auslösen). Keine Kombination, zu wenig Guthaben erlaubt die Aktion nicht. | Tötungsdetails (KS-11), Ansage-Zeitpunkt (KS-12), Sieg-Einzelfälle (KS-13), Erfassung der Wahl (KS-14). |
| Schild | Gekaufter Schild bleibt bis zum verhinderten Tod, höchstens einer, kein Gratis-Schild, keine automatische Erneuerung. | Todesarten und Zusammenspiel (KS-06, KS-21), Rollenverlust und Wiederbelebung (KS-07). |
| Sieg | Zehn Stapel allein lösen keinen Sieg aus; nur die Zehn-Finger-Aktion. Spielleiterbestätigung des Siegkandidaten bleibt (DR-02, DR-14, F-11). | KS-13. |
| Ansage | Feste Nächte 3, 6, 9 usw., sofern er lebt und die Rolle besitzt. | Inhalt (KS-08), Zeitpunkt (KS-12). |
| 5A + zweite Runde | Stapel gehören zur Person. Neuer Träger der Rolle bei null; beim bisherigen Träger ruhen sie und werden bei Rückerhalt wieder nutzbar. Tod: Stapel bleiben, tot sammelt und gewinnt er nicht; nach Wiederbelebung weiter mit dem Stand. | Schild bei Tod und Rollenverlust (KS-07). |
| 6B | Fünf-Tote-Hinweis auch bei später erhaltener Selbstmörder-Rolle, wenn schon fünf tot sind (einmalig). Umgesetzt. | Wiederbelebungsfall bleibt offen (kein Beschluss). |

„Karten abgeben“ und „Stapel ausgeben“ meinen nur das Guthaben des Kartenschluckers, nicht das Entfernen fremder Totenreichkarten. Quelle und Ersetzt-Liste: Decision Log „Kartenschlucker, Grundregeln“.

## 4. Übergreifende offene Punkte

Gelten für viele Karten und werden bei den Karten mit ihrer ID (ÜB-n) verwiesen. Alle **[V]**, keine Entscheidungen.

| ID | Thema | Frage |
|---|---|---|
| ÜB-1 | Kartentext je Person | Unterschiedliche Kartentexte für Dorf, Wölfe und Einzelsiegrollen sind mit 1A (jede Person bekommt beim Tod eine Karte) vereinbar. Offen: Welche Karten kommen für welche Rolle oder Fraktion in Frage (Legacy: Solo-Karten fast nur für Solo, Kategorien gewichtet), und nach welcher Rolle, wenn sie sich zwischen Tod und Spielen ändert? Nicht entschieden. |
| ÜB-2 | Abstimmungen am Tisch | Bestätigt: keine digitale Abstimmung. Offen je Karte: welches Ergebnis die SL einträgt (Person, Rangfolge, ja/nein), damit die App die Wirkung darstellen kann. |
| ÜB-3 | Bezugszeitpunkt | „Nächste Nacht“, „nächster Lynch“, „folgende Nacht“: ab wann zählt es, wenn eine Karte am Tag, in der Nacht oder in der Morgenauflösung gespielt wird? Wie werden „Tage“ und „Runden“ gezählt? |
| ÜB-4 | Zufall | Projektregel: Zufall nur über den gespeicherten Generator. „Zufällig“ auf einer Karte kann Generator, echten Würfel am Tisch oder SL-Wahl bedeuten. Je Karte festlegen. |
| ÜB-5 | Kartenbedingung und Wiederbelebung | Die vier deathCardRequirements-Karten und die Kutscher/Frankenstein-Bedingung RM-DR-141.4 folgen mit der Kartenüberarbeitung (W-01 = A). Offen: Bedingung behalten, streichen oder ersetzen. |
| ÜB-6 | Kartenbestand | Legacy sortiert bereits vergebene Karten aus. Offen: Darf dieselbe Karte mehrfach vorkommen? Was, wenn der Vorrat leer ist? Neue Karte bei erneutem Tod (1A). |
| ÜB-7 | Sichtbarkeit | Wer sieht die Karte und wann (Legacy: nur auf SL-Knopfdruck am toten Sitz)? Ist der Tausch öffentlich? Darf eine Karte Geheimnisse offenlegen? |
| ÜB-8 | Zeitpunkt des Spielens | Wann wird die Karte gespielt (sofort beim Tod, an einer festen Stelle des Ablaufs, auf Wunsch)? Legacy kennt nur das Flag „gespielt“. |
| ÜB-9 | Reale Handlungen | Zeigen, Schweigen, Zettel, Würfel, Zeitmessung: die App kann sie nicht ausführen. Je Karte: Anweisungstext und welche Bestätigung die SL eingibt (kein Timer in der App, Timer ist offen). |
| ÜB-10 | Namensdopplung | „Anarchie“ kommt zweimal vor; einer der Namen müsste vor der Umsetzung geändert werden (Inhaltsfrage, nicht Regel). |

## 5. Bearbeitungsgruppen und Reihenfolge

Reihenfolge nach gemeinsamen Regeln und Abhängigkeiten, jede Gruppe in einer Sitzung durcharbeitbar. Die Zuordnung ist ein **[V]** und ändert nichts an einer Karte.

| Reihenfolge | Gruppe | Karten | Warum an dieser Stelle |
|---|---|---|---|
| 1 | Tod, Rückkehr und Rollenwechsel | 7 | Wiederbelebung und Rollenübernahme berühren direkt 1A (Karte bei jedem Tod), 3A (Tausch nach erneutem Tod), 5A (Stapel bei Tod) und die Wiederbelebungsregeln W-01 bis W-04. Vier Karten tragen eine Kartenbedingung. Deshalb zuerst. |
| 2 | Schutz, Umleitung und Todesketten | 10 | Alle greifen in die Todespipeline ein (Reihenfolge mit Parasit, Rudelvater, Schattenwanderer, Nekromant, Hades, Kartenschlucker-Schild). Muss vor dem Schild des Kartenschluckers feststehen. |
| 3 | Nachtablauf und Wolfsangriff | 12 | Verändern Nachtschritte (Rudelopfer, übersprungene Nacht). Gemeinsame Frage: Bezugszeitpunkt „nächste Nacht“ und Wechselwirkung mit Nachtrollen und dem Nachtzähler des Kartenschluckers. |
| 4 | Fähigkeiten sperren, wiederholen, verdoppeln | 11 | Wirken auf Einmal- und Nachtfähigkeiten einzelner Personen (verbrauchte Zähler, Wiederbelebungsregeln). |
| 5 | Abstimmung und Lynch | 13 | Alle hängen an Stimmen am Tisch. Bestätigt: keine digitale Abstimmung, die SL trägt Ergebnisse ein. Gemeinsame Frage: welches Ergebnis die App genau braucht. |
| 6 | Tote handeln | 6 | Tote nominieren, stimmen oder zeigen. Braucht die Entscheidung, wie Tote am Tisch beteiligt und in der App abgebildet werden. |
| 7 | Tischregeln, Enthüllungen und Informationen | 10 | Überwiegend reale Handlungen am Tisch mit kleinem oder ohne Zustandseintrag. Gemeinsame Frage: was öffentlich werden darf (Geheimhaltung). |
| 8 | Solo-Karten | 11 | Eigene Siegbedingungen, Zettel, Bindungen. Am Ende, weil sie die meisten neuen Konzepte einführen (Mitsieg, posthumer Sieg, Todesband). |
| | **Summe** | **80** | |

Die Grundregeln des Kartenschluckers sind entschieden (Abschnitt 3). Für den Einstieg in Gruppe 1 blockieren noch die Fragen aus Abschnitt 8.

**Gruppe 1, gemeinsame Grundentscheidungen (Blocker):** (1) Zeitpunkt des Spielens und Bezug „nächste Nacht“ (KS-09, alle Karten); (2) Kartenbedingung `deathCardRequirements` (KS-10, `segen_08`, `wende_04`, `wende_07`, `loki_10`, `wende_12`); (3) Ablauf einer Karten-Wiederbelebung (KS-18); (4) „halbe Fähigkeit“ und Würfel (KS-19); (5) Rollenwechsel durch Karten (KS-20). Nach 1A erhält eine Wiederbelebte bei erneutem Tod eine neue Karte; die Stapelregel gilt für Wechsel von oder zum Kartenschlucker.

## 6. Karten je Gruppe

Je Karte: **[R]** Regeltext unverändert, Quelle, **[V]** mechanische Wirkung, reale Handlung, Eingabe der SL, Unklarheiten und Rolleninteraktionen, Status. Kartenspezifisch bestätigt ist bisher nichts; es gelten nur die allgemeinen Entscheidungen aus Abschnitt 3.

### Gruppe 1: Tod, Rückkehr und Rollenwechsel (7 Karten)

#### `segen_08` Zweites Leben (SEGEN)

- **[R] Regeltext:** Wolf: „Ein toter Werwolf deiner Wahl kehrt als vollwertiger Werwolf mit seiner ursprünglichen Rolle zurück.“ · Dorf: „Ein toter Dorfbewohner deiner Wahl kehrt als vollwertiger Dorfbewohner mit seiner ursprünglichen Rolle zurück.“
- **Quelle:** `js/core/cards.js`, `segen_08`; Kartenbedingung: lebende Person mit Rollen-Tag revive, role-return, death-trigger-transform
- **[V] Mechanische Wirkung im Spiel:** Eine gewählte tote Person der Fraktion kehrt als vollwertiges Mitglied mit ihrer ursprünglichen Rolle zurück.
- **[V] Handlung in der realen Welt:** SL informiert die Person; sie erhält ihre Rolle zurück und sitzt wieder am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson (Tote), Bestätigung.
- **Unklarheiten und Rolleninteraktionen:** Kartenbedingung (deathCardRequirements) vorhanden. Wiederbelebung nach W-01 bis W-04 (frischer Start, Einmal-Fähigkeiten je Person). Interaktion mit Nekromant, Kutscher, Frankenstein. ÜB-5.
- **Status:** noch nicht überarbeitet

#### `wende_04` Wiedergeburt (WENDE)

- **[R] Regeltext:** Wolf: „Der Spielleiter wählt nach eigenem Ermessen einen toten Werwolf — er kehrt mit seiner ursprünglichen Fähigkeit zurück.“ · Dorf: „Der Spielleiter wählt nach eigenem Ermessen einen toten Dorfbewohner — er kehrt mit seiner ursprünglichen Fähigkeit zurück.“
- **Quelle:** `js/core/cards.js`, `wende_04`; Kartenbedingung: lebende Person mit Rollen-Tag revive, role-return, death-trigger-transform
- **[V] Mechanische Wirkung im Spiel:** Die SL wählt eine tote Person der Fraktion; sie kehrt mit ihrer ursprünglichen Fähigkeit zurück.
- **[V] Handlung in der realen Welt:** SL informiert die Person; Person erhält ihre Rolle zurück.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson (SL nach Ermessen).
- **Unklarheiten und Rolleninteraktionen:** Kartenbedingung: nur wenn eine lebende Person mit Wiederbelebungs-Rolle im Spiel ist (Legacy-Tags revive, role-return, death-trigger-transform). Ob die Bedingung bleibt, ist offen. ÜB-5.
- **Status:** noch nicht überarbeitet

#### `wende_07` Befreiung (WENDE)

- **[R] Regeltext:** Wolf: „Ein toter Werwolf kehrt mit halber Fähigkeit zurück — er darf sie einmalig einsetzen, dann stirbt er erneut.“ · Dorf: „Ein toter Dorfbewohner kehrt mit halber Fähigkeit zurück — er darf sie einmalig einsetzen, dann stirbt er erneut.“
- **Quelle:** `js/core/cards.js`, `wende_07`; Kartenbedingung: lebende Person mit Rollen-Tag revive, role-return, death-trigger-transform
- **[V] Mechanische Wirkung im Spiel:** Eine tote Person kehrt mit halber Fähigkeit zurück und darf sie einmalig einsetzen, dann stirbt sie erneut.
- **[V] Handlung in der realen Welt:** SL informiert die Person; nach dem Einsatz stirbt sie wieder.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson, Bestätigung des Einsatzes.
- **Unklarheiten und Rolleninteraktionen:** „Halbe Fähigkeit“ nicht definiert. Erneuter Tod = neue Karte (Entscheidung 1A) und Tauschmöglichkeit (3A): Kettenwirkung. Kartenbedingung. ÜB-5.
- **Status:** noch nicht überarbeitet

#### `loki_10` Phoenix (LOKI)

- **[R] Regeltext:** Neutral: „Es werden zwei Würfel gewürfelt, der erste belebt entsprechend viele zufällige Spieler wieder, der zweite entscheidet für wie viele Runden sie am Leben bleiben.“
- **Quelle:** `js/core/cards.js`, `loki_10`; Kartenbedingung: lebende Person mit Rollen-Tag revive, role-return, death-trigger-transform
- **[V] Mechanische Wirkung im Spiel:** Zwei Würfel: der erste bestimmt, wie viele zufällige Personen wiederbelebt werden, der zweite, für wie viele Runden sie leben.
- **[V] Handlung in der realen Welt:** Würfeln am Tisch (echter Würfel) oder Generator.
- **[V] Eingabe oder Bestätigung der SL:** Würfelergebnisse (falls am Tisch gewürfelt).
- **Unklarheiten und Rolleninteraktionen:** Kartenbedingung. Wiederbelebte Personen sterben nach Ablauf erneut: Zeitzähler in Runden (Runde = ?). Zufall (Würfel am Tisch gegen gespeicherten Generator, ÜB-4). Sehr große Wirkung auf Siegprüfung.
- **Status:** noch nicht überarbeitet

#### `wende_12` Geheimrat (WENDE)

- **[R] Regeltext:** Wolf: „Die Werwölfe werden in dieser Nacht als letztes aufgerufen — du darfst für diese Nacht die Augen öffnen und ihnen Hinweise geben.“ · Dorf: „Du darfst dem Spielleiter eine Frage stellen die er wahrheitsgemäß beantworten muss. (Nur in Spielen mit Wiederbelebungs-Szenarien)“
- **Quelle:** `js/core/cards.js`, `wende_12`
- **[V] Mechanische Wirkung im Spiel:** W: Das Rudel wird in dieser Nacht als letztes aufgerufen, die Kartenträgerin darf die Augen öffnen und Hinweise geben. D: Die Person darf der SL eine Frage stellen, die wahrheitsgemäß beantwortet werden muss. (Nur in Spielen mit Wiederbelebungs-Szenarien)
- **[V] Handlung in der realen Welt:** W: Tote gibt dem Rudel Hinweise (stumm?). D: Frage an die SL.
- **[V] Eingabe oder Bestätigung der SL:** D: Antwort der SL.
- **Unklarheiten und Rolleninteraktionen:** D-Text enthält eine Szenariobedingung („nur in Spielen mit Wiederbelebung“), ohne dass die Karte eine deathCardRequirements-Angabe hat. Geheimhaltung der Antwort. ÜB-5.
- **Status:** noch nicht überarbeitet

#### `schicksal_08` Neuer Anfang (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Zwei ausgewählte lebende Spieler erhalten eine neue Rolle innerhalb ihrer Fraktion — der Spielleiter informiert beide still.“
- **Quelle:** `js/core/cards.js`, `schicksal_08`
- **[V] Mechanische Wirkung im Spiel:** Zwei ausgewählte lebende Personen erhalten eine neue Rolle innerhalb ihrer Fraktion; die SL informiert beide still.
- **[V] Handlung in der realen Welt:** SL teilt die neuen Rollen still mit.
- **[V] Eingabe oder Bestätigung der SL:** Zielpersonen und neue Rollen.
- **Unklarheiten und Rolleninteraktionen:** Rollenwechsel wie Spielleiterkorrektur set_role; welche Rollen sind erlaubt (Kartenbedingung Fraktion, Solo). Rollenabhängige Zustände (Bindungen, Schutz). Auch Rolle Selbstmörder wäre möglich (Fünf-Tote-Hinweis 6B).
- **Status:** noch nicht überarbeitet

#### `loki_06` Rollenroulette (LOKI)

- **[R] Regeltext:** Neutral: „Der Spielleiter tauscht die Rollen zweier zufälliger lebender Spieler — beide gehören derselben Fraktion an und werden still informiert.“
- **Quelle:** `js/core/cards.js`, `loki_06`
- **[V] Mechanische Wirkung im Spiel:** Die SL tauscht die Rollen zweier zufälliger lebender Personen derselben Fraktion, beide werden still informiert.
- **[V] Handlung in der realen Welt:** SL teilt die Rollen still mit.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** Tausch ist keine Wiedergeburt: Zustand (Schutz, Zähler, Einmalfähigkeiten) folgt der Person oder der Rolle? ÜB-4.
- **Status:** noch nicht überarbeitet

### Gruppe 2: Schutz, Umleitung und Todesketten (10 Karten)

#### `segen_01` Heilende Hand (SEGEN)

- **[R] Regeltext:** Wolf: „Das nächste Mal, wenn ein Werwolf sterben würde, stirbt stattdessen ein zufälliger Dorfbewohner.“ · Dorf: „Das nächste Mal, wenn ein Werwolf einen Dorfbewohner reißen würde, überlebt er und erhält ein einmaliges Schutzschild.“
- **Quelle:** `js/core/cards.js`, `segen_01`
- **[V] Mechanische Wirkung im Spiel:** W: Das nächste Mal, wenn ein Wolf sterben würde, stirbt stattdessen ein zufälliger Dorfbewohner. D: Das nächste Mal, wenn ein Wolf einen Dorfbewohner reißen würde, überlebt er und erhält ein einmaliges Schutzschild.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** Umleitung und Schild in der Todespipeline (Reihenfolge mit Rudelvater, Parasit, Schattenwanderer, Nekromant, Hades). „Nächstes Mal“ ohne Ablauf. ÜB-3, ÜB-4.
- **Status:** noch nicht überarbeitet

#### `segen_07` Blutpakt (SEGEN)

- **[R] Regeltext:** Wolf: „Die nächste Sonderfähigkeit die einen Werwolf töten würde wird negiert.“ · Dorf: „Basierend auf dem Charakter des nächsten nächtlichen Opfers deckt der Spielleiter 0 bis 2 Werwölfe auf.“
- **Quelle:** `js/core/cards.js`, `segen_07`
- **[V] Mechanische Wirkung im Spiel:** W: Die nächste Sonderfähigkeit, die einen Wolf töten würde, wird negiert. D: Die SL deckt anhand der Rolle des nächsten nächtlichen Opfers 0 bis 2 Wölfe auf.
- **[V] Handlung in der realen Welt:** D: SL nennt öffentlich 0 bis 2 Wolfsnamen.
- **[V] Eingabe oder Bestätigung der SL:** D: SL wählt, welche Wölfe.
- **Unklarheiten und Rolleninteraktionen:** D: öffentliche Enthüllung von Wölfen, Regeln zu „0 bis 2“ nicht festgelegt. W: „Sonderfähigkeit“ in der Todespipeline. Geheimhaltung.
- **Status:** noch nicht überarbeitet

#### `segen_11` Spiegelschutz (SEGEN)

- **[R] Regeltext:** Wolf: „Sollte am nächsten Tag ein Wolf gelyncht werden, stirbt stattdessen derjenige, der die Nominierung ausgesprochen hat.“ · Dorf: „Sollten die Werwölfe in der Folgenacht einen Dorfbewohner erwischen, stirbt stattdessen einer von ihnen.“
- **Quelle:** `js/core/cards.js`, `segen_11`
- **[V] Mechanische Wirkung im Spiel:** W: Wird am nächsten Tag ein Wolf gelyncht, stirbt stattdessen die nominierende Person. D: Erwischt das Rudel in der Folgenacht einen Dorfbewohner, stirbt stattdessen einer der Wölfe.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** Keine bei automatischer Ersetzung; sonst Wahl.
- **Unklarheiten und Rolleninteraktionen:** Ersetzen des Opfers in der Todespipeline; „nominierende Person“ ist im Verlauf nicht immer bekannt (Nominierung hat Nominierenden). „Einer von ihnen“: wer (Generator oder SL). ÜB-3, ÜB-4.
- **Status:** noch nicht überarbeitet

#### `wende_02` Verzweiflungsschrei (WENDE)

- **[R] Regeltext:** Wolf: „Ein Werwolf deiner Wahl kann die nächsten 2 Tage nicht gelyncht werden.“ · Dorf: „Ein Dorfbewohner deiner Wahl erhält 3 Tage lang einen Schutz gegen Werwolf-Angriffe.“
- **Quelle:** `js/core/cards.js`, `wende_02`
- **[V] Mechanische Wirkung im Spiel:** W: Ein gewählter Wolf kann die nächsten 2 Tage nicht gelyncht werden. D: Ein gewählter Dorfbewohner erhält 3 Tage Schutz gegen Wolfsangriffe.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson.
- **Unklarheiten und Rolleninteraktionen:** Schutzdauer in Tagen/Nächten gezählt (Zählbeginn ÜB-3). Verhältnis zu Schutzrollen und Ketten.
- **Status:** noch nicht überarbeitet

#### `wende_05` Notanker (WENDE)

- **[R] Regeltext:** Wolf: „Die Wölfe dürfen den nächsten Tod in den eigenen Reihen einmalig auf den übernächsten Tag verschieben — der Spielleiter vollstreckt ihn dann automatisch.“ · Dorf: „Das Dorf darf den nächsten Tod in den eigenen Reihen einmalig auf den übernächsten Tag verschieben — der Spielleiter vollstreckt ihn dann automatisch.“
- **Quelle:** `js/core/cards.js`, `wende_05`
- **[V] Mechanische Wirkung im Spiel:** W/D: Der nächste Tod in den eigenen Reihen wird einmalig auf den übernächsten Tag verschoben und dann automatisch vollstreckt.
- **[V] Handlung in der realen Welt:** Keine, SL merkt sich das Datum.
- **[V] Eingabe oder Bestätigung der SL:** Keine.
- **Unklarheiten und Rolleninteraktionen:** Verzögerter Tod (Zustand mit Zeitpunkt): neue Regelkategorie. Zwischenzeit: gilt die Person als lebend? Siegprüfung, Nachtaktionen, Abstimmung. Nicht ausschließbar bei Ketten.
- **Status:** noch nicht überarbeitet

#### `wende_11` Schicksalswende (WENDE)

- **[R] Regeltext:** Wolf: „König Lykaon erwacht in dir — verleihe einem Wolf deiner Wahl die Fähigkeit, einen Spieler in einen Trugbilderwolf zu verwandeln.“ · Dorf: „Sollte der nächste Lynch einen Dorfbewohner treffen, wird das Urteil auf einen zufälligen Wolf umgeleitet.“
- **Quelle:** `js/core/cards.js`, `wende_11`
- **[V] Mechanische Wirkung im Spiel:** W: Der Wolf erhält die Fähigkeit von König Lykaon (eine Person in einen Trugbilderwolf verwandeln). D: Trifft der nächste Lynch einen Dorfbewohner, wird das Urteil auf einen zufälligen Wolf umgeleitet.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** W: Zielperson und Wolf. D: Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** W: Rolle Trugbilderwolf und Verwandlungsregel vorhanden? (Rollenübernahme). D: Umleitung des Urteils verrät die Fraktion. ÜB-4.
- **Status:** noch nicht überarbeitet

#### `fluch_05` Gebrochener Schild (FLUCH)

- **[R] Regeltext:** Wolf: „Alle aktiven Schutz-Effekte auf Werwölfen werden für 1 bis 3 Tage aufgehoben — der Spielleiter entscheidet die Dauer.“ · Dorf: „Alle aktiven Schutz-Effekte auf Dorfbewohnern werden für 1 bis 3 Tage aufgehoben — der Spielleiter entscheidet die Dauer.“
- **Quelle:** `js/core/cards.js`, `fluch_05`
- **[V] Mechanische Wirkung im Spiel:** W: Alle aktiven Schutz-Effekte auf Wölfen werden für 1 bis 3 Tage aufgehoben. D: Dasselbe für Dorfbewohner.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** SL bestimmt die Dauer (1 bis 3 Tage).
- **Unklarheiten und Rolleninteraktionen:** Aufhebung von Schutz auf viele Rollen; „Tage“ zählen ab wann (ÜB-3). Erlischt der Schutz oder ruht er?
- **Status:** noch nicht überarbeitet

#### `fluch_08` Kettenfluch (FLUCH)

- **[R] Regeltext:** Wolf: „Stirbt heute Nacht ein Werwolf durch eine Sonderfähigkeit, stirbt der Werwolf rechts von ihm mit.“ · Dorf: „Stirbt heute Nacht ein Dorfbewohner durch die Wölfe, stirbt der Dorfbewohner links von ihm mit.“
- **Quelle:** `js/core/cards.js`, `fluch_08`
- **[V] Mechanische Wirkung im Spiel:** W: Stirbt heute Nacht ein Wolf durch eine Sonderfähigkeit, stirbt der Wolf rechts von ihm mit. D: Stirbt heute Nacht ein Dorfbewohner durch die Wölfe, stirbt der Dorfbewohner links von ihm mit.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** Keine (Nachbarschaft folgt aus Sitzordnung).
- **Unklarheiten und Rolleninteraktionen:** Todeskette mit Nachbarn (wie Wahnsinniger Kutscher), Sitzplatz ist Anordnung, Person-ID ist Identität. Tote Nachbarn überspringen? Siegprüfung nach Kette.
- **Status:** noch nicht überarbeitet

#### `fluch_12` Doppeltes Leid (FLUCH)

- **[R] Regeltext:** Wolf: „Stirbt als Nächstes ein Wolf, stirbt automatisch ein weiterer zufälliger Wolf mit ihm.“ · Dorf: „Stirbt als Nächstes ein Dorfbewohner, stirbt automatisch ein weiterer zufälliger Dorfbewohner mit ihm.“
- **Quelle:** `js/core/cards.js`, `fluch_12`
- **[V] Mechanische Wirkung im Spiel:** W: Stirbt als Nächstes ein Wolf, stirbt ein weiterer zufälliger Wolf mit. D: Dasselbe für Dorfbewohner.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** „Als Nächstes“ ohne Ablauf; Todesketten; Wolf der Fraktionsauswahl bei Wechselrollen. ÜB-3, ÜB-4.
- **Status:** noch nicht überarbeitet

#### `loki_12` Kosmisches Gleichgewicht (LOKI)

- **[R] Regeltext:** Neutral: „Stirbt heute ein Wolf, stirbt auch ein Dorfbewohner. Stirbt ein Dorfbewohner, stirbt auch ein Wolf. Der Spielleiter entscheidet die Opfer nach Rollenstärke.“
- **Quelle:** `js/core/cards.js`, `loki_12`
- **[V] Mechanische Wirkung im Spiel:** Stirbt heute ein Wolf, stirbt auch ein Dorfbewohner und umgekehrt; die SL entscheidet die Opfer nach Rollenstärke.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** SL wählt das zweite Opfer.
- **Unklarheiten und Rolleninteraktionen:** Todeskette gegen die Fraktion; „Rollenstärke“ nicht definiert; Solo und Neutrale; unbegrenzte Ketten (zwei Tode lösen weitere aus). ÜB-1.
- **Status:** noch nicht überarbeitet

### Gruppe 3: Nachtablauf und Wolfsangriff (12 Karten)

#### `segen_03` Wachsame Augen (SEGEN)

- **[R] Regeltext:** Wolf: „Die Wölfe erfahren heute Nacht die Rolle ihres gewählten Opfers bevor sie es reißen — und dürfen das Ziel danach noch wechseln.“ · Dorf: „Vor der Lynchung wird das aktuelle Opfer dem Dorf enthüllt — das Dorf entscheidet ob die Lynchung vollzogen wird oder nicht.“
- **Quelle:** `js/core/cards.js`, `segen_03`
- **[V] Mechanische Wirkung im Spiel:** W: Ziel des Rudels wird vor der Ausführung mit Rolle gezeigt, Zielwechsel möglich (Änderung im Nachtschritt Rudel). D: Lynchung wird vor Vollzug verzögert, Dorf entscheidet.
- **[V] Handlung in der realen Welt:** W: SL nennt dem Rudel leise die Rolle des Opfers. D: SL enthüllt das Opfer vor der Lynchung, Dorf stimmt am Tisch über Vollzug ab.
- **[V] Eingabe oder Bestätigung der SL:** W: neues Ziel oder Bestätigung. D: Ergebnis der Tischabstimmung (vollziehen ja/nein).
- **Unklarheiten und Rolleninteraktionen:** D-Text spricht von „Opfer“ vor der Lynchung, meint wohl den Nominierten (Auslegung offen). Öffentliche Rollenenthüllung ist eine Geheimhaltungsfrage. ÜB-1, ÜB-2.
- **Status:** noch nicht überarbeitet

#### `segen_04` Stille Nacht (SEGEN)

- **[R] Regeltext:** Wolf: „Die Wölfe dürfen heute Nacht zusätzlich zu ihrem normalen Opfer ein zweites Ziel reißen.“ · Dorf: „Die Wölfe dürfen heute Nacht kein Opfer wählen — sie schlafen.“
- **Quelle:** `js/core/cards.js`, `segen_04`
- **[V] Mechanische Wirkung im Spiel:** W: Rudel wählt in der Nacht ein zweites Ziel. D: Rudel wählt kein Opfer (Nachtschritt Rudel entfällt).
- **[V] Handlung in der realen Welt:** Keine, nur Ansage an das Rudel bzw. Übergehen des Rudels.
- **[V] Eingabe oder Bestätigung der SL:** Keine, sofern die Karte als Modus der Nacht gesetzt wird.
- **Unklarheiten und Rolleninteraktionen:** Nachtschritte wie Rudelvater, Schicksalswolf (Zusatzziele) und Schutzrollen. Bezug „heute Nacht“ nach Spielen der Karte am Tag oder in der Nacht (ÜB-3).
- **Status:** noch nicht überarbeitet

#### `segen_09` Gerechter Zorn (SEGEN)

- **[R] Regeltext:** Wolf: „Wird beim nächsten Lynch ein Werwolf gelyncht, dürfen die Wölfe in dieser Nacht zwei Opfer reißen statt einem.“ · Dorf: „Sollte beim nächsten Lynch ein Dorfbewohner gelyncht werden, wird er automatisch befreit und der Tag endet ohne Opfer.“
- **Quelle:** `js/core/cards.js`, `segen_09`
- **[V] Mechanische Wirkung im Spiel:** W: Bedingt: wird beim nächsten Lynch ein Wolf gelyncht, erhält das Rudel in der folgenden Nacht zwei Opfer. D: Bedingt: wird beim nächsten Lynch ein Dorfbewohner gelyncht, wird er befreit und der Tag endet ohne Opfer.
- **[V] Handlung in der realen Welt:** Keine; SL merkt sich die Bedingung.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn Fraktion aus Rollenkatalog folgt; sonst SL-Bestätigung.
- **Unklarheiten und Rolleninteraktionen:** Bedingungskarte über zwei Zeitpunkte. „Dorfbewohner“ und „Wolf“ bei Solo- und Wechselrollen (ÜB-1). „Automatisch befreit“ kollidiert mit Todesketten der Hinrichtung (Wahnsinniger Kutscher).
- **Status:** noch nicht überarbeitet

#### `segen_13` Schattenvorteil (SEGEN)

- **[R] Regeltext:** Wolf: „In der Folgenacht missglückt die erste Fähigkeit die einen Wolf trifft.“ · Dorf: „Die Werwölfe werden in der Folgenacht als erstes geweckt und ihr Opfer wird laut nach der Einigung angesagt.“
- **Quelle:** `js/core/cards.js`, `segen_13`
- **[V] Mechanische Wirkung im Spiel:** W: In der Folgenacht wird die erste Fähigkeit, die einen Wolf trifft, wirkungslos. D: Rudel wird in der Folgenacht zuerst geweckt, das Opfer wird nach der Einigung laut angesagt.
- **[V] Handlung in der realen Welt:** D: SL sagt das Rudelopfer laut an (Nachtgeheimnis wird öffentlich).
- **[V] Eingabe oder Bestätigung der SL:** W: Bestätigung, welche Fähigkeit „die erste“ ist (Reihenfolge der Nachtschritte).
- **Unklarheiten und Rolleninteraktionen:** „Erste Fähigkeit“ hängt an der Nachtreihenfolge. D verrät das Rudelopfer vor dem Morgen (Geheimhaltungsregel, öffentliche Ansage). Interaktion mit Schutzrollen. ÜB-3.
- **Status:** noch nicht überarbeitet

#### `fluch_02` Falsche Fährte (FLUCH)

- **[R] Regeltext:** Wolf: „Der Spielleiter lenkt den Werwolf-Angriff diese Nacht auf ein Ziel seiner Wahl um.“ · Dorf: „Der Spielleiter gibt einem Dorfbewohner seiner Wahl heute Nacht eine falsche Information.“
- **Quelle:** `js/core/cards.js`, `fluch_02`
- **[V] Mechanische Wirkung im Spiel:** W: Rudelangriff wird auf ein SL-Ziel umgelenkt. D: Eine Person erhält eine falsche Information.
- **[V] Handlung in der realen Welt:** D: SL gibt die falsche Information mündlich oder über die private Ansicht.
- **[V] Eingabe oder Bestätigung der SL:** W: Ziel. D: Ziel und Inhalt der falschen Information.
- **Unklarheiten und Rolleninteraktionen:** Falsche Information verlangt Rollen mit Informationsfähigkeit (Detektiv, Orakel). Umlenkung gegen Schutzrollen. „Der Spielleiter wählt“ ist eine bestehende SL-Freiheit (Keine Rollenbeschränkung aus Bequemlichkeit).
- **Status:** noch nicht überarbeitet

#### `fluch_04` Verrat (FLUCH)

- **[R] Regeltext:** Wolf: „Die Wölfe müssen heute Nacht zwingend einen ihrer eigenen fressen — kein Dorfbewohner kann heute sterben.“ · Dorf: „Es wird heute so lange gelyncht, bis ein Mitglied der Dorf-Fraktion getroffen wurde.“
- **Quelle:** `js/core/cards.js`, `fluch_04`
- **[V] Mechanische Wirkung im Spiel:** W: Rudel muss ein eigenes Mitglied als Opfer wählen, kein Dorfbewohner stirbt in der Nacht. D: Es wird am Tag so lange gelyncht, bis eine Person der Dorf-Fraktion getroffen wurde.
- **[V] Handlung in der realen Welt:** D: Mehrere Abstimmungen nacheinander am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** D: Ergebnis jeder Abstimmung (SL trägt ein).
- **Unklarheiten und Rolleninteraktionen:** Widerspricht der Regel „Wölfe wählen ein Opfer“ (Zwang gegen das eigene Team). D: Schleife ohne Ende, wenn nur Wölfe leben; Todesketten. Bezug „Dorf-Fraktion“ bei Solo/Wechselrollen (ÜB-1).
- **Status:** noch nicht überarbeitet

#### `fluch_07` Alptraum (FLUCH)

- **[R] Regeltext:** Wolf: „Die Wölfe schlafen so schlecht, dass sie heute Nacht kein Opfer reißen können.“ · Dorf: „Ein zufälliger Dorfbewohner wird dem Dorf als verdächtig angezeigt — der Spielleiter gibt es öffentlich bekannt.“
- **Quelle:** `js/core/cards.js`, `fluch_07`
- **[V] Mechanische Wirkung im Spiel:** W: Rudel wählt in der Nacht kein Opfer. D: Eine zufällige lebende Person wird dem Dorf öffentlich als verdächtig angezeigt.
- **[V] Handlung in der realen Welt:** D: SL gibt den Verdacht öffentlich bekannt.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn Zufall über den gespeicherten Generator läuft; sonst SL-Wahl.
- **Unklarheiten und Rolleninteraktionen:** „Zufällig“ (ÜB-4). D: öffentlicher Verdacht ohne Wirkung, nur Information; kein echter Wahrheitsgehalt (keine erfundenen Aussagen in der App). Doppelt zu segen_04 D.
- **Status:** noch nicht überarbeitet

#### `fluch_10` Schlechtes Omen (FLUCH)

- **[R] Regeltext:** Wolf: „Sollten die Wölfe heute Nacht keine starke Rolle erwischen, entscheidet der Spielleiter, ob einer von ihnen stirbt.“ · Dorf: „Sollte heute kein Werwolf gelyncht werden, stirbt ein weiterer zufälliger Dorfbewohner noch am selben Tag.“
- **Quelle:** `js/core/cards.js`, `fluch_10`
- **[V] Mechanische Wirkung im Spiel:** W: Bedingt: erwischt das Rudel keine „starke Rolle“, entscheidet die SL, ob ein Wolf stirbt. D: Bedingt: wird heute kein Wolf gelyncht, stirbt zusätzlich eine zufällige Person.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** W: SL-Entscheidung; „starke Rolle“ ist nicht definiert.
- **Unklarheiten und Rolleninteraktionen:** „Starke Rolle“ ist nicht definiert (Auslegung offen). D: „zufälliger Dorfbewohner“ (ÜB-4). Todeszeitpunkt „noch am selben Tag“.
- **Status:** noch nicht überarbeitet

#### `wende_03` Wendepunkt (WENDE)

- **[R] Regeltext:** Wolf: „Die Wölfe dürfen diese Nacht zwei Opfer reißen statt einem.“ · Dorf: „Das Dorf darf heute lynchen — trifft die Lynchung einen Dorfbewohner, schreitet der Spielleiter ein und verhindert sie. Trifft sie einen Werwolf, wird vollstreckt.“
- **Quelle:** `js/core/cards.js`, `wende_03`
- **[V] Mechanische Wirkung im Spiel:** W: Rudel wählt in der Nacht zwei Opfer. D: Lynchung ist bedingt: trifft sie einen Dorfbewohner, wird sie verhindert, trifft sie einen Wolf, wird sie vollstreckt.
- **[V] Handlung in der realen Welt:** D: Abstimmung am Tisch wie gewohnt.
- **[V] Eingabe oder Bestätigung der SL:** D: Ergebnis der Abstimmung; die Bedingung folgt aus der Rolle des Gelynchten.
- **Unklarheiten und Rolleninteraktionen:** D: Die SL „schreitet ein“ und verrät dadurch die Fraktion des Nominierten öffentlich (Geheimhaltung). Interaktion mit Hinrichtungsketten. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `wende_06` Trotz (WENDE)

- **[R] Regeltext:** Wolf: „Die Wölfe sind diese Nacht komplett geschützt — keine Sonderfähigkeit kann heute einen Wolf töten.“ · Dorf: „Das Dorf ist diese Nacht komplett geschützt — die Wölfe können heute Nacht kein Opfer reißen.“
- **Quelle:** `js/core/cards.js`, `wende_06`
- **[V] Mechanische Wirkung im Spiel:** W: In der Nacht kann keine Fähigkeit einen Wolf töten. D: In der Nacht kann das Rudel kein Opfer wählen.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** Keine.
- **Unklarheiten und Rolleninteraktionen:** W: „komplett geschützt“ gegen Sonderrollen mit Sofort-Tod (Hades, Henker) und Todesketten (offen). Doppelt zu segen_04 D und fluch_07 W.
- **Status:** noch nicht überarbeitet

#### `schicksal_06` Zeitsprung (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Diese Nacht wird vollständig übersprungen — keine Fähigkeiten, kein Wolf-Angriff, kein Tod. Direkt zum nächsten Tag.“
- **Quelle:** `js/core/cards.js`, `schicksal_06`
- **[V] Mechanische Wirkung im Spiel:** Die nächste Nacht wird übersprungen: keine Fähigkeiten, kein Rudelangriff, kein Tod.
- **[V] Handlung in der realen Welt:** SL sagt an, dass die Nacht ausfällt.
- **[V] Eingabe oder Bestätigung der SL:** Keine.
- **Unklarheiten und Rolleninteraktionen:** Wirkt auf jede Nachtrolle, Zähler wie Nachtnummer und „genau eine Nacht“-Fähigkeiten (Kartenschlucker-Ansage alle drei Nächte). Fast identisch mit loki_03 (Zeitwarp). ÜB-3.
- **Status:** noch nicht überarbeitet

#### `loki_03` Zeitwarp (LOKI)

- **[R] Regeltext:** Neutral: „Diese Nacht wird übersprungen. Alle Nacht-Fähigkeiten verfallen — kein Tod, kein Angriff, kein Schutz. Direkt zum nächsten Tag.“
- **Quelle:** `js/core/cards.js`, `loki_03`
- **[V] Mechanische Wirkung im Spiel:** Die nächste Nacht wird übersprungen, alle Nachtfähigkeiten verfallen, kein Tod, kein Angriff, kein Schutz.
- **[V] Handlung in der realen Welt:** SL sagt an, dass die Nacht ausfällt.
- **[V] Eingabe oder Bestätigung der SL:** Keine.
- **Unklarheiten und Rolleninteraktionen:** Fast identisch mit schicksal_06 (Zeitsprung). „Schutz verfällt“ ist zusätzlich. Bezug von Zählern (Nachtnummer, Kartenschlucker-Nächte). ÜB-3.
- **Status:** noch nicht überarbeitet

### Gruppe 4: Fähigkeiten sperren, wiederholen, verdoppeln (11 Karten)

#### `segen_06` Schattenmantel (SEGEN)

- **[R] Regeltext:** Wolf: „Das nächste Mal, wenn ein Werwolf vom Orakel gesehen werden würde, wird er ihr als eine zufällige noch lebende Dorfbewohnerrolle angezeigt.“ · Dorf: „Die Wölfe werden die folgende Nacht geblendet — ein zufälliges Opfer stirbt, es könnte auch ein Werwolf selbst sein.“
- **Quelle:** `js/core/cards.js`, `segen_06`
- **[V] Mechanische Wirkung im Spiel:** W: Wird ein Wolf vom Orakel gesehen, erscheint er als zufällige lebende Dorfrolle. D: Das Rudel wird in der Folgenacht „geblendet“, ein zufälliges Opfer stirbt (kann ein Wolf sein).
- **[V] Handlung in der realen Welt:** D: SL bestimmt das Zufallsopfer.
- **[V] Eingabe oder Bestätigung der SL:** W: Ergebnis der Orakel-Anzeige. D: Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** Wortlaut W „nächstes Mal“ unbestimmt lang. D: Zufallsopfer widerspricht dem Rudelschritt (ersetzt oder zusätzlich?). Orakel und Verwandte. ÜB-4.
- **Status:** noch nicht überarbeitet

#### `segen_12` Geisterhand (SEGEN)

- **[R] Regeltext:** Wolf: „Ein von dir ausgewählter Spieler erhält zusätzlich für die nächste Nacht die Fähigkeit des zuletzt verstorbenen Werwolfs.“ · Dorf: „Ein von dir ausgewählter Spieler erhält zusätzlich für die nächste Nacht die Fähigkeit des zuletzt verstorbenen Dorfbewohners.“
- **Quelle:** `js/core/cards.js`, `segen_12`
- **[V] Mechanische Wirkung im Spiel:** Eine gewählte Person erhält zusätzlich für die nächste Nacht die Fähigkeit des zuletzt gestorbenen Wolfs (W) bzw. Dorfbewohners (D).
- **[V] Handlung in der realen Welt:** SL erklärt der Person die Fähigkeit still.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson; „zuletzt Gestorbener“ folgt aus dem Protokoll.
- **Unklarheiten und Rolleninteraktionen:** Fähigkeit einer Rolle mit Bindungen (Lehrling, Rudelvater) oder Einmalfähigkeit; Wiederbelebter. Nicht jede Rolle ist übertragbar (Rollenübernahme-Regeln). Der Toten-Ablauf bei Tod in derselben Nacht.
- **Status:** noch nicht überarbeitet

#### `segen_14` Eiserner Wille (SEGEN)

- **[R] Regeltext:** Wolf: „Erhalte Einsicht ins Spiel und wähle einen Spieler aus, der seine Fähigkeit in der Folgenacht entweder erneut oder zweimal einsetzen darf.“ · Dorf: „Erhalte Einsicht ins Spiel und wähle einen Spieler aus, der seine Fähigkeit in der Folgenacht entweder erneut oder zweimal einsetzen darf.“
- **Quelle:** `js/core/cards.js`, `segen_14`
- **[V] Mechanische Wirkung im Spiel:** Die Karte gibt der Person Einsicht ins Spiel und wählt eine Person, die ihre Fähigkeit in der Folgenacht erneut oder zweimal einsetzen darf.
- **[V] Handlung in der realen Welt:** SL zeigt der toten Person Informationen (nicht festgelegt, welche).
- **[V] Eingabe oder Bestätigung der SL:** Zielperson und Wahl „erneut“ oder „zweimal“.
- **Unklarheiten und Rolleninteraktionen:** „Einsicht ins Spiel“ ist nicht definiert (Umfang, Geheimhaltung). Zweimal nutzen widerspricht Einmal-Fähigkeiten und dem Nachtablauf. Text für Wolf und Dorf identisch.
- **Status:** noch nicht überarbeitet

#### `fluch_01` Blinder Fleck (FLUCH)

- **[R] Regeltext:** Wolf: „Ein zufälliger Werwolf verliert diese Nacht seine Sonderfähigkeit — nur der Wolf-Angriff bleibt.“ · Dorf: „Ein zufälliger Dorfbewohner verliert diese Nacht seine Sonderfähigkeit.“
- **Quelle:** `js/core/cards.js`, `fluch_01`
- **[V] Mechanische Wirkung im Spiel:** Eine zufällige Person der Fraktion verliert diese Nacht ihre Sonderfähigkeit (Wolf behält den Rudelangriff).
- **[V] Handlung in der realen Welt:** Keine, SL informiert die Person nicht offen oder still (offen).
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** „Verliert“ = Nachtschritt fällt aus. Rollen mit Pflichtwirkung. ÜB-4.
- **Status:** noch nicht überarbeitet

#### `wende_01` Letzter Atemzug (WENDE)

- **[R] Regeltext:** Wolf: „Ein Werwolf deiner Wahl darf seine bereits genutzte Fähigkeit diese Nacht erneut einsetzen.“ · Dorf: „Ein Dorfbewohner deiner Wahl darf seine bereits genutzte Fähigkeit diese Nacht erneut einsetzen.“
- **Quelle:** `js/core/cards.js`, `wende_01`
- **[V] Mechanische Wirkung im Spiel:** Eine gewählte Person darf ihre bereits genutzte Fähigkeit diese Nacht erneut einsetzen (setzt „verbraucht“ zurück).
- **[V] Handlung in der realen Welt:** SL informiert die Person still.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson.
- **Unklarheiten und Rolleninteraktionen:** Einmal-Fähigkeiten je Person (Wiederbelebungsentscheidung W-01 bis W-04); verbrauchte Zähler und Mehrfachfähigkeiten. Verwandt mit schicksal_10, loki_07.
- **Status:** noch nicht überarbeitet

#### `wende_08` Auserwählt (WENDE)

- **[R] Regeltext:** Wolf: „Der Spielleiter wählt nach bestem Gewissen einen Werwolf — dieser darf seine Fähigkeit in der nächsten Nacht zweimal einsetzen.“ · Dorf: „Der Spielleiter wählt nach bestem Gewissen einen Dorfbewohner — dieser darf seine Fähigkeit in der nächsten Nacht zweimal einsetzen.“
- **Quelle:** `js/core/cards.js`, `wende_08`
- **[V] Mechanische Wirkung im Spiel:** Eine von der SL gewählte Person darf ihre Fähigkeit in der nächsten Nacht zweimal einsetzen.
- **[V] Handlung in der realen Welt:** SL informiert die Person still.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson (SL „nach bestem Gewissen“).
- **Unklarheiten und Rolleninteraktionen:** Wahl der SL, keine Regel dazu. Zweimal-Einsatz bei Rollen mit Einmal- oder Ziel-Wechselwirkung. Ähnlich segen_14.
- **Status:** noch nicht überarbeitet

#### `wende_10` Schicksalsumkehr (WENDE)

- **[R] Regeltext:** Wolf: „Die stärkste aktive Schutzfähigkeit eines Dorfbewohners wird für eine Nacht deaktiviert — der Spielleiter wählt welche.“ · Dorf: „Die stärkste aktive Fähigkeit eines Werwolfs wird für eine Nacht deaktiviert — der Spielleiter wählt welche.“
- **Quelle:** `js/core/cards.js`, `wende_10`
- **[V] Mechanische Wirkung im Spiel:** W: Stärkste aktive Schutzfähigkeit eines Dorfbewohners wird für eine Nacht deaktiviert. D: Stärkste aktive Fähigkeit eines Wolfs wird für eine Nacht deaktiviert.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** SL wählt die Fähigkeit („die stärkste“).
- **Unklarheiten und Rolleninteraktionen:** „Stärkste“ ist nicht definiert. Deaktivierte Fähigkeit im Nachtablauf.
- **Status:** noch nicht überarbeitet

#### `schicksal_07` Gleichgewicht (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Der Spielleiter beobachtet den aktuellen Spielstand, verkündet laut, wer vorne liegt, und blockiert die erste aktive gewählte Fähigkeit zugunsten des verlierenden Teams.“
- **Quelle:** `js/core/cards.js`, `schicksal_07`
- **[V] Mechanische Wirkung im Spiel:** Die SL bestimmt, wer „vorne liegt“, und blockiert die erste aktive gewählte Fähigkeit zugunsten des verlierenden Teams.
- **[V] Handlung in der realen Welt:** SL verkündet laut, wer vorne liegt.
- **[V] Eingabe oder Bestätigung der SL:** SL wählt die geblockte Fähigkeit.
- **Unklarheiten und Rolleninteraktionen:** Öffentliche Aussage „wer vorne liegt“ ist eine Spielstandsinformation (Geheimhaltung). Maßstab für „vorne“ nicht definiert (Legacy: 1:4-Regel im Ziehcode). Solo-Teams.
- **Status:** noch nicht überarbeitet

#### `schicksal_10` Anarchie (SCHICKSAL)

- **[R] Regeltext:** Neutral: „In der kommenden Nacht wird eine zufällige bereits verbrauchte Einmalfähigkeit eines lebenden Spielers deiner Fraktion wieder verfügbar.“
- **Quelle:** `js/core/cards.js`, `schicksal_10`
- **[V] Mechanische Wirkung im Spiel:** In der nächsten Nacht wird eine zufällige bereits verbrauchte Einmalfähigkeit einer lebenden Person der eigenen Fraktion wieder verfügbar.
- **[V] Handlung in der realen Welt:** SL informiert die Person still.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** Name doppelt mit loki_07 (Anarchie), Wirkung verschieden. Fraktion der Kartenträgerin bei Solo/Neutral (ÜB-1). ÜB-4, ÜB-10.
- **Status:** noch nicht überarbeitet

#### `loki_07` Anarchie (LOKI)

- **[R] Regeltext:** Neutral: „Alle aktiven Schutz-Effekte aller Spieler werden sofort aufgehoben. Alle bereits genutzten Einmal-Fähigkeiten kehren für alle zurück.“
- **Quelle:** `js/core/cards.js`, `loki_07`
- **[V] Mechanische Wirkung im Spiel:** Alle aktiven Schutzeffekte aller Personen werden aufgehoben; alle verbrauchten Einmalfähigkeiten kehren für alle zurück.
- **[V] Handlung in der realen Welt:** SL sagt es öffentlich an.
- **[V] Eingabe oder Bestätigung der SL:** Keine.
- **Unklarheiten und Rolleninteraktionen:** Name doppelt mit schicksal_10. Sehr weitreichend (alle Rollen, alle Zähler, Wiederbelebungsentscheidung). Öffentliche Ansage verrät, dass Fähigkeiten verbraucht waren. ÜB-10.
- **Status:** noch nicht überarbeitet

#### `loki_08` Verhexte Nacht (LOKI)

- **[R] Regeltext:** Neutral: „Der Spielleiter entscheidet, ob deine nächtliche Fähigkeit durchgeht oder ein anderes Ziel trifft — auch du selbst. Überlege weise, ob du deine Fähigkeit diese Nacht überhaupt einsetzen willst.“
- **Quelle:** `js/core/cards.js`, `loki_08`
- **[V] Mechanische Wirkung im Spiel:** Die SL entscheidet, ob die nächtliche Fähigkeit der Karteninhaberin durchgeht oder ein anderes Ziel trifft (auch sie selbst).
- **[V] Handlung in der realen Welt:** SL entscheidet still.
- **[V] Eingabe oder Bestätigung der SL:** SL-Entscheidung; kein Regelkriterium.
- **Unklarheiten und Rolleninteraktionen:** Die Person ist tot: welche „nächtliche Fähigkeit“ ist gemeint (Fähigkeit der Rolle im Totenreich)? Karte ist unklar für Tote. Bezug auf Wiederbelebte.
- **Status:** noch nicht überarbeitet

### Gruppe 5: Abstimmung und Lynch (13 Karten)

#### `segen_05` Wahre Stimme (SEGEN)

- **[R] Regeltext:** Wolf: „Ein Werwolf deiner Wahl erhält beim heutigen Lynch doppelte Stimmkraft.“ · Dorf: „Ein Dorfbewohner deiner Wahl erhält beim heutigen Lynch doppelte Stimmkraft.“
- **Quelle:** `js/core/cards.js`, `segen_05`
- **[V] Mechanische Wirkung im Spiel:** Eine gewählte Person der Fraktion erhält beim heutigen Lynch doppelte Stimmkraft.
- **[V] Handlung in der realen Welt:** Stimmen am Tisch zählen, SL berücksichtigt die Doppelstimme.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Abstimmung (SL trägt ein).
- **Unklarheiten und Rolleninteraktionen:** Keine digitale Abstimmung (bestätigt): Doppelstimme wirkt nur am Tisch. Stimmgewicht Hades x3, Blutwolf, Korrupter Richter. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `fluch_03` Lähmung (FLUCH)

- **[R] Regeltext:** Wolf: „Ein zufälliger Werwolf darf beim nächsten Lynch nicht abstimmen.“ · Dorf: „Ein zufälliger Dorfbewohner darf beim nächsten Lynch nicht abstimmen.“
- **Quelle:** `js/core/cards.js`, `fluch_03`
- **[V] Mechanische Wirkung im Spiel:** Eine zufällige Person der Fraktion darf beim nächsten Lynch nicht abstimmen.
- **[V] Handlung in der realen Welt:** SL sagt an, wer nicht abstimmen darf.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn der Generator zieht; Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** Wirkt nur am Tisch. ÜB-2, ÜB-4.
- **Status:** noch nicht überarbeitet

#### `fluch_09` Verlorene Stimme (FLUCH)

- **[R] Regeltext:** Wolf: „Die Werwölfe verlieren beim nächsten Lynch die Wertigkeit ihrer Stimmen — der Spielleiter hält die Anzahl geheim, offenbart jedoch wer das Opfer ist.“ · Dorf: „Die Dorfbewohner verlieren beim nächsten Lynch die Wertigkeit ihrer Stimmen — der Spielleiter hält die Anzahl geheim, offenbart jedoch wer das Opfer ist.“
- **Quelle:** `js/core/cards.js`, `fluch_09`
- **[V] Mechanische Wirkung im Spiel:** Die Stimmen der Fraktion verlieren beim nächsten Lynch ihre Wertigkeit; die SL hält die Zahl geheim, offenbart nur das Opfer.
- **[V] Handlung in der realen Welt:** SL zählt die Stimmen still.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Abstimmung; Zählung nur durch die SL.
- **Unklarheiten und Rolleninteraktionen:** Am Tisch offen gezählte Stimmen widersprechen dem Geheimhalten. Wirkung „Wertigkeit verlieren“ nicht definiert. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `fluch_13` Lähmungswelle (FLUCH)

- **[R] Regeltext:** Wolf: „Alle Wölfe können beim nächsten Lynch nicht abstimmen.“ · Dorf: „Alle Dorfbewohner mit einer aktiven Fähigkeit können beim nächsten Lynch nicht abstimmen.“
- **Quelle:** `js/core/cards.js`, `fluch_13`
- **[V] Mechanische Wirkung im Spiel:** W: Alle Wölfe können beim nächsten Lynch nicht abstimmen. D: Alle Dorfbewohner mit aktiver Fähigkeit können beim nächsten Lynch nicht abstimmen.
- **[V] Handlung in der realen Welt:** SL sagt an, wer nicht abstimmen darf.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** „Aktive Fähigkeit“ bei Dorfrollen nicht definiert. Wirkt nur am Tisch. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `wende_09` Rückenwind (WENDE)

- **[R] Regeltext:** Wolf: „Alle Wolf-Stimmen beim nächsten Lynch werden verdoppelt — der Spielleiter hält die Gesamtmenge an Stimmen geheim, offenbart jedoch wer das Opfer ist.“ · Dorf: „Alle Dorf-Stimmen beim nächsten Lynch werden verdoppelt — der Spielleiter hält die Gesamtmenge an Stimmen geheim, offenbart jedoch wer das Opfer ist.“
- **Quelle:** `js/core/cards.js`, `wende_09`
- **[V] Mechanische Wirkung im Spiel:** Alle Stimmen der Fraktion beim nächsten Lynch werden verdoppelt; die SL hält die Gesamtmenge geheim, offenbart das Opfer.
- **[V] Handlung in der realen Welt:** SL zählt still.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** Geheimhaltung der Stimmenzahl gegen Zählung am Tisch. Wirkt nur am Tisch. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `schicksal_03` Amnestie (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Die aktuelle Lynchung wird sofort abgebrochen. Alle Stimmen verfallen. Kein neuer Lynch heute — direkt in die Nacht.“
- **Quelle:** `js/core/cards.js`, `schicksal_03`
- **[V] Mechanische Wirkung im Spiel:** Die aktuelle Lynchung wird abgebrochen, alle Stimmen verfallen, kein neuer Lynch heute, direkt in die Nacht.
- **[V] Handlung in der realen Welt:** SL bricht die Abstimmung am Tisch ab.
- **[V] Eingabe oder Bestätigung der SL:** Keine (Abbruch als SL-Aktion).
- **Unklarheiten und Rolleninteraktionen:** Zeitpunkt „aktuelle Lynchung“ (nur spielbar während einer Lynchung). Ende des Tages ohne Hinrichtung. Todesketten der Hinrichtung.
- **Status:** noch nicht überarbeitet

#### `schicksal_05` Spiegel (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Alle Spieler zeigen nach einem 5-Sekunden-Countdown gleichzeitig auf einen Spieler. Wer keine einzige Stimme erhält, stirbt sofort.“
- **Quelle:** `js/core/cards.js`, `schicksal_05`
- **[V] Mechanische Wirkung im Spiel:** Alle zeigen nach einem 5-Sekunden-Countdown gleichzeitig auf eine Person. Wer keine Stimme erhält, stirbt sofort.
- **[V] Handlung in der realen Welt:** Countdown und gleichzeitiges Zeigen am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** SL trägt ein, wer keine Stimme erhielt (mehrere möglich).
- **Unklarheiten und Rolleninteraktionen:** Bei vielen Personen viele Tote (fast alle). Zeigen als Handlung in der Realität. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `schicksal_09` Stimmentausch (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Beim nächsten Lynch zählt jede Stimme für den Spieler links daneben statt für den Nominierten.“
- **Quelle:** `js/core/cards.js`, `schicksal_09`
- **[V] Mechanische Wirkung im Spiel:** Beim nächsten Lynch zählt jede Stimme für die Person links daneben statt für die nominierte.
- **[V] Handlung in der realen Welt:** Stimmen am Tisch werden umgerechnet.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** Wirkt nur am Tisch; „links daneben“ hängt an der Sitzordnung. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `schicksal_11` Kettenreaktion (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Stirbt jemand durch Lynch, stirbt auch der Spieler mit den zweitmeisten Stimmen sofort — ohne weitere Abstimmung.“
- **Quelle:** `js/core/cards.js`, `schicksal_11`
- **[V] Mechanische Wirkung im Spiel:** Stirbt jemand durch Lynch, stirbt auch die Person mit den zweitmeisten Stimmen sofort ohne weitere Abstimmung.
- **[V] Handlung in der realen Welt:** SL nennt die Person mit den zweitmeisten Stimmen.
- **[V] Eingabe oder Bestätigung der SL:** Stimmenrangfolge (SL trägt ein).
- **Unklarheiten und Rolleninteraktionen:** Gleichstand bei Platz zwei ungeregelt. Todeskette. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `schicksal_14` Richterstuhl (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Das Dorf wählt sofort einen temporären Richter — exakt wie die Bürgermeisterwahl. Dieser Richter allein verhängt das Urteil des Tages.“
- **Quelle:** `js/core/cards.js`, `schicksal_14`
- **[V] Mechanische Wirkung im Spiel:** Das Dorf wählt einen temporären Richter wie die Bürgermeisterwahl; der Richter verhängt allein das Urteil des Tages.
- **[V] Handlung in der realen Welt:** Wahl am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Wahl und das Urteil.
- **Unklarheiten und Rolleninteraktionen:** Bürgermeisterwahl vorhanden? (Referenz nicht geprüft). Der Richter kann Tote oder Lebende treffen. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `loki_01` Spiegelwelt (LOKI)

- **[R] Regeltext:** Neutral: „Alle Lynch-Stimmen heute zählen für den Spieler links daneben statt für den Nominierten. Niemand weiß, wer wirklich stirbt, bis der Spielleiter es verkündet.“
- **Quelle:** `js/core/cards.js`, `loki_01`
- **[V] Mechanische Wirkung im Spiel:** Alle Lynch-Stimmen heute zählen für die Person links daneben; niemand weiß, wer stirbt, bis die SL es verkündet.
- **[V] Handlung in der realen Welt:** SL zählt die Stimmen und verkündet.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** Ähnlich schicksal_09, aber für heute und mit Geheimhaltung. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `loki_02` Stille Abstimmung (LOKI)

- **[R] Regeltext:** Neutral: „Der Tag wird auf 60 Sekunden verkürzt. Gibt es nicht mindestens 3 Nominierungen, sterben 1-5 zufällige Spieler. Werden Nominierung und Lynchung nicht innerhalb der 60 Sekunden abgeschlossen, sterben alle 3 Nominierten.“
- **Quelle:** `js/core/cards.js`, `loki_02`
- **[V] Mechanische Wirkung im Spiel:** Der Tag wird auf 60 Sekunden verkürzt. Gibt es keine 3 Nominierungen, sterben 1 bis 5 zufällige Personen. Wird nicht rechtzeitig abgeschlossen, sterben alle 3 Nominierten.
- **[V] Handlung in der realen Welt:** Zeit am Tisch messen; Nominierungen zählen.
- **[V] Eingabe oder Bestätigung der SL:** Anzahl Nominierungen, Abschluss ja/nein, Zufallszahl 1 bis 5.
- **Unklarheiten und Rolleninteraktionen:** Hohe Härte; Zeitmessung bei Kartenspielen. Kein Timer in der App (Timer noch offen). Zufallszahl. ÜB-2, ÜB-4.
- **Status:** noch nicht überarbeitet

#### `loki_13` Verhexte Lynch (LOKI)

- **[R] Regeltext:** Neutral: „Beim heutigen Lynch stirbt der Spieler mit den wenigsten Stimmen — nicht der mit den meisten.“
- **Quelle:** `js/core/cards.js`, `loki_13`
- **[V] Mechanische Wirkung im Spiel:** Beim heutigen Lynch stirbt die Person mit den wenigsten Stimmen statt der mit den meisten.
- **[V] Handlung in der realen Welt:** SL nennt die Person mit den wenigsten Stimmen.
- **[V] Eingabe oder Bestätigung der SL:** Stimmenrangfolge.
- **Unklarheiten und Rolleninteraktionen:** Personen ohne Stimmen; Gleichstand bei den wenigsten. Wirkt nur am Tisch. ÜB-2.
- **Status:** noch nicht überarbeitet

### Gruppe 6: Tote handeln (6 Karten)

#### `segen_10` Totenurteil (SEGEN)

- **[R] Regeltext:** Wolf: „Die toten Werwölfe stimmen heimlich ab — ein Dorfbewohner ihrer Wahl stirbt noch in dieser Nacht.“ · Dorf: „Die toten Dorfbewohner stimmen heimlich ab — ein Werwolf ihrer Wahl stirbt noch in dieser Nacht.“
- **Quelle:** `js/core/cards.js`, `segen_10`
- **[V] Mechanische Wirkung im Spiel:** W: Die toten Wölfe stimmen heimlich ab, ein Dorfbewohner ihrer Wahl stirbt noch in dieser Nacht. D: Die toten Dorfbewohner stimmen heimlich ab, ein Wolf ihrer Wahl stirbt noch in dieser Nacht.
- **[V] Handlung in der realen Welt:** Geheime Abstimmung der Toten am Tisch (Augen zu, Handzeichen).
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Toten-Abstimmung (SL trägt ein).
- **Unklarheiten und Rolleninteraktionen:** Tote als Handelnde; Geheimhaltung der Toten-Abstimmung; Solo-Tote gehören zu keiner Seite. Tod „noch in dieser Nacht“ (Timing ÜB-3). Mächtig, Todesketten. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `schicksal_12` Totengericht (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Der nächste Tag wird von den Toten geleitet — nur tote Spieler dürfen nominieren und abstimmen. Lebende Spieler hören schweigend zu.“
- **Quelle:** `js/core/cards.js`, `schicksal_12`
- **[V] Mechanische Wirkung im Spiel:** Der nächste Tag wird von den Toten geleitet: nur Tote dürfen nominieren und abstimmen, Lebende schweigen.
- **[V] Handlung in der realen Welt:** Tote nominieren und stimmen am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Nominierung und Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** Tote als Handelnde; Ähnlich solo_13. Ergebnis der Abstimmung (ÜB-2). Fünf-Tote-Hinweis und Tote gehören nicht zu ihr.
- **Status:** noch nicht überarbeitet

#### `loki_05` Totenerwachen (LOKI)

- **[R] Regeltext:** Neutral: „Alle Toten zeigen gleichzeitig auf einen lebenden Spieler — der meistgenannte stirbt sofort. Bei Gleichstand sterben beide.“
- **Quelle:** `js/core/cards.js`, `loki_05`
- **[V] Mechanische Wirkung im Spiel:** Alle Toten zeigen gleichzeitig auf eine lebende Person; die meistgenannte stirbt sofort (Gleichstand: beide).
- **[V] Handlung in der realen Welt:** Zeigen am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** SL trägt die meistgenannte Person ein.
- **Unklarheiten und Rolleninteraktionen:** Tote als Handelnde. Gleichstand mit mehr als zwei? ÜB-2.
- **Status:** noch nicht überarbeitet

#### `solo_06` Geisterstimme (SOLO)

- **[R] Regeltext:** Solo: „Du agierst ab sofort vom Totenreich aus — du darfst in den folgenden drei Tagen nominieren und mit abstimmen, dazu zählt deine Stimme doppelt. Sollte es dir gelingen, dadurch jemanden zu lynchen, wirst du mit einer neuen Solo-Rolle wiederbelebt.“
- **Quelle:** `js/core/cards.js`, `solo_06`
- **[V] Mechanische Wirkung im Spiel:** Die Solo-Tote nominiert und stimmt in den folgenden drei Tagen mit, ihre Stimme zählt doppelt. Gelingt es ihr, jemanden zu lynchen, wird sie mit einer neuen Solo-Rolle wiederbelebt.
- **[V] Handlung in der realen Welt:** Nominierung und Abstimmung am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Nominierung, Ergebnis der Abstimmung, ob die Lynchung von ihr verursacht wurde.
- **Unklarheiten und Rolleninteraktionen:** Tote als Handelnde mit Doppelstimme. Wiederbelebung mit „neuer Solo-Rolle“: wer wählt die Rolle (Zufall oder SL)? Wiederbelebungsregeln W-01 bis W-04, Kartenbedingung nicht angegeben. ÜB-2, ÜB-4.
- **Status:** noch nicht überarbeitet

#### `solo_11` Richter aus dem Totenreich (SOLO)

- **[R] Regeltext:** Solo: „Nach jeder Abstimmung darfst du erneut einmal nominieren — nur wenn mindestens 50% der Spieler dafür sind, wird diese Person zusätzlich gelyncht.“
- **Quelle:** `js/core/cards.js`, `solo_11`
- **[V] Mechanische Wirkung im Spiel:** Nach jeder Abstimmung darf die Karteninhaberin erneut nominieren; sind mindestens 50% der Spielenden dafür, wird die Person zusätzlich gelyncht.
- **[V] Handlung in der realen Welt:** Zusätzliche Nominierung und Abstimmung am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Nominierung und Ergebnis.
- **Unklarheiten und Rolleninteraktionen:** Tote als Handelnde; „50% der Spielenden“ (lebend oder alle?). Zusätzliche Hinrichtung pro Tag; Todesketten. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `solo_13` Das Totenreich Regiert (SOLO)

- **[R] Regeltext:** Solo: „Die nächsten 2 Tagphasen werden von den Toten regiert — nur diese dürfen reden, nominieren und lynchen.“
- **Quelle:** `js/core/cards.js`, `solo_13`
- **[V] Mechanische Wirkung im Spiel:** Die nächsten 2 Tagphasen werden von den Toten regiert: nur diese dürfen reden, nominieren und lynchen.
- **[V] Handlung in der realen Welt:** Tote reden, nominieren, stimmen am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Nominierung und Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** Wie schicksal_12, zwei Tage. Lebende schweigen: Tischregel. Fünf-Tote-Hinweis und Siegprüfung. ÜB-2.
- **Status:** noch nicht überarbeitet

### Gruppe 7: Tischregeln, Enthüllungen und Informationen (10 Karten)

#### `schicksal_01` Nebelhorn (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Niemand darf in der nächsten Tagesphase über Rollen sprechen — nur über Verhalten und Beobachtungen. Wer es tut scheidet sofort aus der Diskussion aus.“
- **Quelle:** `js/core/cards.js`, `schicksal_01`
- **[V] Mechanische Wirkung im Spiel:** Niemand darf am nächsten Tag über Rollen sprechen; wer es tut, scheidet aus der Diskussion aus.
- **[V] Handlung in der realen Welt:** Tischregel: nicht über Rollen sprechen.
- **[V] Eingabe oder Bestätigung der SL:** SL trägt Verstoß und Ausschluss ein (optional).
- **Unklarheiten und Rolleninteraktionen:** Kontrolle nur am Tisch; „scheidet aus der Diskussion aus“ hat keinen Zustand im Spiel.
- **Status:** noch nicht überarbeitet

#### `schicksal_02` Offene Bücher (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Jeder lebende Spieler muss öffentlich sagen ob er heute Nacht eine Fähigkeit genutzt hat — lügen erlaubt. Reihenfolge bestimmt der Spielleiter.“
- **Quelle:** `js/core/cards.js`, `schicksal_02`
- **[V] Mechanische Wirkung im Spiel:** Jede lebende Person muss öffentlich sagen, ob sie heute Nacht eine Fähigkeit genutzt hat (Lügen erlaubt); Reihenfolge bestimmt die SL.
- **[V] Handlung in der realen Welt:** Reihum antworten am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Keine.
- **Unklarheiten und Rolleninteraktionen:** Nur Tischhandlung. Geheimhaltung: Wahrheitsgehalt darf nicht aus dem Zustand folgen.
- **Status:** noch nicht überarbeitet

#### `schicksal_04` Großes Schweigen (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Die gesamte nächste Tagesphase dauert exakt 2 Minuten. Danach wird sofort abgestimmt — ohne weitere Diskussion.“
- **Quelle:** `js/core/cards.js`, `schicksal_04`
- **[V] Mechanische Wirkung im Spiel:** Die nächste Tagesphase dauert exakt 2 Minuten, danach sofort Abstimmung ohne weitere Diskussion.
- **[V] Handlung in der realen Welt:** Zeit am Tisch messen.
- **[V] Eingabe oder Bestätigung der SL:** Ergebnis der Abstimmung.
- **Unklarheiten und Rolleninteraktionen:** Kein Timer in der App (Timer noch offen). ÜB-2.
- **Status:** noch nicht überarbeitet

#### `schicksal_13` Stille Wahl (SCHICKSAL)

- **[R] Regeltext:** Neutral: „Heute findet keine Diskussion statt — lediglich Nominierung und sofortige Abstimmung. Kein Spieler darf zuvor das Wort ergreifen.“
- **Quelle:** `js/core/cards.js`, `schicksal_13`
- **[V] Mechanische Wirkung im Spiel:** Heute findet keine Diskussion statt, nur Nominierung und sofortige Abstimmung.
- **[V] Handlung in der realen Welt:** Tischregel: nicht sprechen.
- **[V] Eingabe oder Bestätigung der SL:** Nominierung und Ergebnis.
- **Unklarheiten und Rolleninteraktionen:** Nur Tischhandlung. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `loki_11` Stummfilm (LOKI)

- **[R] Regeltext:** Neutral: „Heute darf niemand sprechen — nur Handzeichen und Mimik erlaubt. Wer auch nur ein Wort spricht, stirbt sofort.“
- **Quelle:** `js/core/cards.js`, `loki_11`
- **[V] Mechanische Wirkung im Spiel:** Heute darf niemand sprechen (nur Handzeichen und Mimik); wer spricht, stirbt sofort.
- **[V] Handlung in der realen Welt:** Tischregel: Schweigen; Sprechende melden.
- **[V] Eingabe oder Bestätigung der SL:** SL trägt ein, wer stirbt.
- **Unklarheiten und Rolleninteraktionen:** Kontrolle nur am Tisch; Tod durch Sprechen (neue Todesursache). Härte gegen Kinder und Anfänger (Produktentscheidung).
- **Status:** noch nicht überarbeitet

#### `loki_09` Puppenspieler (LOKI)

- **[R] Regeltext:** Neutral: „Der Spielleiter nominiert am nächsten Tag 5 Spieler, es ist mindestens einer aus jeder Fraktion darunter.“
- **Quelle:** `js/core/cards.js`, `loki_09`
- **[V] Mechanische Wirkung im Spiel:** Die SL nominiert am nächsten Tag 5 Personen, mindestens eine aus jeder Fraktion.
- **[V] Handlung in der realen Welt:** SL nennt die 5 Nominierten öffentlich.
- **[V] Eingabe oder Bestätigung der SL:** SL wählt die 5 Personen.
- **Unklarheiten und Rolleninteraktionen:** Nominierung durch die SL (Nominierungsregeln, verdeckte Nominierende); „Fraktion“ bei Solo und Neutralen; weniger als 5 Lebende; die Fraktionsverteilung verrät Geheiminformation. ÜB-1.
- **Status:** noch nicht überarbeitet

#### `segen_02` Flüsterwind (SEGEN)

- **[R] Regeltext:** Wolf: „Ein Werwolf deiner Wahl darf dem Spielleiter heute öffentlich eine Ja/Nein Frage über einen Dorfbewohner stellen.“ · Dorf: „Ein Dorfbewohner deiner Wahl darf dem Spielleiter heute öffentlich eine Ja/Nein Frage über einen Mitspieler stellen.“
- **Quelle:** `js/core/cards.js`, `segen_02`
- **[V] Mechanische Wirkung im Spiel:** Eine gewählte Person der Fraktion (W: Wolf, D: Dorfbewohner) darf der SL heute öffentlich eine Ja/Nein-Frage stellen (W: über einen Dorfbewohner, D: über einen Mitspieler).
- **[V] Handlung in der realen Welt:** Frage öffentlich an die SL; SL antwortet.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson, Frage, Antwort der SL.
- **Unklarheiten und Rolleninteraktionen:** SL antwortet wahrheitsgemäß aus dem Zustand: Auskunftsregeln (Geheimhaltung, Rollen) nicht festgelegt.
- **Status:** noch nicht überarbeitet

#### `fluch_06` Schwarzes Mal (FLUCH)

- **[R] Regeltext:** Wolf: „Der Spielleiter offenbart die Rolle eines Werwolfs seiner Wahl öffentlich dem Dorf.“ · Dorf: „Der Spielleiter offenbart die Rolle eines Dorfbewohners seiner Wahl öffentlich dem Dorf.“
- **Quelle:** `js/core/cards.js`, `fluch_06`
- **[V] Mechanische Wirkung im Spiel:** Die SL offenbart die Rolle eines Wolfs (W) bzw. eines Dorfbewohners (D) ihrer Wahl öffentlich.
- **[V] Handlung in der realen Welt:** SL nennt die Rolle öffentlich.
- **[V] Eingabe oder Bestätigung der SL:** SL wählt die Person.
- **Unklarheiten und Rolleninteraktionen:** Öffentliche Enthüllung einer Rolle (Geheimhaltungsregel, Darstellung „Rolle öffentlich“). Auswirkung auf Rollen, die verdeckt bleiben müssen.
- **Status:** noch nicht überarbeitet

#### `fluch_11` Rabe des Unheils (FLUCH)

- **[R] Regeltext:** Wolf: „Du musst einen Wolf deiner Wahl dem Dorf öffentlich enthüllen.“ · Dorf: „Du musst einen Dorfbewohner deiner Wahl dem Dorf öffentlich enthüllen.“
- **Quelle:** `js/core/cards.js`, `fluch_11`
- **[V] Mechanische Wirkung im Spiel:** Die Karteninhaberin muss einen Wolf (W) bzw. Dorfbewohner (D) ihrer Wahl öffentlich enthüllen.
- **[V] Handlung in der realen Welt:** Tote wählt eine Person; SL enthüllt die Rolle öffentlich.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson.
- **Unklarheiten und Rolleninteraktionen:** Tote kennt die Rollen? (Sichtrechte der Toten). Öffentliche Enthüllung. Ähnlich fluch_06.
- **Status:** noch nicht überarbeitet

#### `loki_04` Doppelgänger (LOKI)

- **[R] Regeltext:** Neutral: „Der Spielleiter markiert heimlich einen zufälligen Spieler als verdächtig — alle sehen den Marker, niemand weiß warum. Ob er wirklich ein Wolf ist, bleibt offen.“
- **Quelle:** `js/core/cards.js`, `loki_04`
- **[V] Mechanische Wirkung im Spiel:** Die SL markiert heimlich eine zufällige Person als verdächtig; alle sehen den Marker, niemand weiß warum; ob sie Wolf ist, bleibt offen.
- **[V] Handlung in der realen Welt:** Marker am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Keine, wenn der Generator zieht.
- **Unklarheiten und Rolleninteraktionen:** Marker ohne Aussagegehalt (keine erfundenen Informationen in der App). Ähnlich fluch_07 D. ÜB-4.
- **Status:** noch nicht überarbeitet

### Gruppe 8: Solo-Karten (11 Karten)

#### `solo_01` Todesprojektion (SOLO)

- **[R] Regeltext:** Solo: „Schreibe den Namen eines Spielers auf einen Zettel und gib ihn dem Spielleiter. Sollte dieser Spieler bei der nächsten Lynchung sterben, nimmst du seine Rolle & Fraktion an und nimmst wieder am Spielgeschehen teil.“
- **Quelle:** `js/core/cards.js`, `solo_01`
- **[V] Mechanische Wirkung im Spiel:** Auf einem Zettel steht der Name einer Person. Stirbt sie bei der nächsten Lynchung, übernimmt die Kartenträgerin ihre Rolle und Fraktion und spielt wieder mit (Wiederbelebung durch Rollenübernahme).
- **[V] Handlung in der realen Welt:** Zettel schreiben und der SL geben.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson, Ergebnis der nächsten Lynchung.
- **Unklarheiten und Rolleninteraktionen:** Rückkehr aus dem Tod mit fremder Rolle (Wiederbelebungsregeln W-01 bis W-04, Rollenübernahme). Rollen, die nicht übernehmbar sind. Zettel nicht in der App (Geheimhaltung: die SL trägt den Namen ein). ÜB-5.
- **Status:** noch nicht überarbeitet

#### `solo_02` Schwarze Prophezeiung (SOLO)

- **[R] Regeltext:** Solo: „Du tippst dem SL geheim, welches Team das Spiel gewinnt. Liegst du richtig, wirst du am Spielende als stiller Mitsieger anerkannt.“
- **Quelle:** `js/core/cards.js`, `solo_02`
- **[V] Mechanische Wirkung im Spiel:** Die Person tippt geheim, welches Team das Spiel gewinnt; bei richtigem Tipp wird sie Mitsiegerin.
- **[V] Handlung in der realen Welt:** Tipp geheim an die SL.
- **[V] Eingabe oder Bestätigung der SL:** Tipp (Team).
- **Unklarheiten und Rolleninteraktionen:** Neue Siegbedingung (Mitsieg); Endbericht und Siegprüfung. Fraktionen bei Solo-Siegen.
- **Status:** noch nicht überarbeitet

#### `solo_03` Racheschwur (SOLO)

- **[R] Regeltext:** Solo: „Der Spieler der dich zuletzt nominiert hat (oder dich nachts angegriffen hat) erhält dauerhaft +3 Startstimmen gegen sich bei jedem zukünftigen Lynch. Der Fluch endet erst, wenn er stirbt.“
- **Quelle:** `js/core/cards.js`, `solo_03`
- **[V] Mechanische Wirkung im Spiel:** Die Person, die zuletzt nominiert oder nachts angegriffen hat, erhält dauerhaft +3 Startstimmen gegen sich bei jedem künftigen Lynch, bis sie stirbt.
- **[V] Handlung in der realen Welt:** SL merkt sich +3 Stimmen und zählt am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson.
- **Unklarheiten und Rolleninteraktionen:** „Zuletzt nominiert“ oder „nachts angegriffen“: welche Person bei mehreren? Nominierender ist verdeckt (Geheimhaltung). Stimmen am Tisch. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `solo_04` Apokalyptischer Abgang (SOLO)

- **[R] Regeltext:** Solo: „Wähle 2 lebende Spieler. Sie sind ab sofort durch ein Todesband verbunden: Stirbt einer in den nächsten 4 Nächten, stirbt der andere am selben Abend sofort nach.“
- **Quelle:** `js/core/cards.js`, `solo_04`
- **[V] Mechanische Wirkung im Spiel:** Zwei lebende Personen werden per Todesband verbunden: stirbt eine in den nächsten 4 Nächten, stirbt die andere am selben Abend sofort nach.
- **[V] Handlung in der realen Welt:** Keine.
- **[V] Eingabe oder Bestätigung der SL:** Zwei Zielpersonen.
- **Unklarheiten und Rolleninteraktionen:** Zustand „Todesband“ mit 4 Nächten; Verhältnis zu Verliebten, Todesketten, Siegprüfung. ÜB-3.
- **Status:** noch nicht überarbeitet

#### `solo_05` Vermächtnis der Einsamkeit (SOLO)

- **[R] Regeltext:** Solo: „Wähle einen lebenden Spieler. Er erbt deine Fähigkeit und deine Siegbedingung zusätzlich. Sollte dieser unter den Gewinnern sein, gewinnst du mit.“
- **Quelle:** `js/core/cards.js`, `solo_05`
- **[V] Mechanische Wirkung im Spiel:** Eine lebende Person erbt Fähigkeit und Siegbedingung der Kartenträgerin zusätzlich; ist sie unter den Gewinnern, gewinnt die Kartenträgerin mit.
- **[V] Handlung in der realen Welt:** SL informiert die Person still.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson.
- **Unklarheiten und Rolleninteraktionen:** Zwei Siegbedingungen für eine Person; Mitsieg der Toten. Rollenerbe wie Lehrling oder Kutscher, Endbericht.
- **Status:** noch nicht überarbeitet

#### `solo_07` Martyrium (SOLO)

- **[R] Regeltext:** Solo: „Wähle Dorf oder Wölfe. Diese Fraktion erhält sofort einen Bonus: Dorf = die nächste Nacht findet kein Wolf-Angriff statt. Wölfe = der nächste Lynch wird annulliert.“
- **Quelle:** `js/core/cards.js`, `solo_07`
- **[V] Mechanische Wirkung im Spiel:** Die Person wählt Dorf oder Wölfe. Dorf: in der nächsten Nacht findet kein Wolfsangriff statt. Wölfe: der nächste Lynch wird annulliert.
- **[V] Handlung in der realen Welt:** Tote wählt still; SL setzt um.
- **[V] Eingabe oder Bestätigung der SL:** Wahl Dorf oder Wölfe.
- **Unklarheiten und Rolleninteraktionen:** Wirkt wie segen_04 D bzw. schicksal_03. Bezug „nächste Nacht/nächster Lynch“ (ÜB-3).
- **Status:** noch nicht überarbeitet

#### `solo_08` Stiller Zeuge (SOLO)

- **[R] Regeltext:** Solo: „Du hast das ganze Spiel beobachtet. Nenne dem SL heimlich den Spieler, den du für den gefährlichsten hältst. Sollte dieser gewinnen, gewinnst du mit ihm.“
- **Quelle:** `js/core/cards.js`, `solo_08`
- **[V] Mechanische Wirkung im Spiel:** Die Person nennt der SL heimlich den Spieler, den sie für den gefährlichsten hält; gewinnt dieser, gewinnt sie mit.
- **[V] Handlung in der realen Welt:** Tipp geheim an die SL.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson.
- **Unklarheiten und Rolleninteraktionen:** Neue Siegbedingung (Mitsieg); Endbericht. „Gefährlichster“ ist frei.
- **Status:** noch nicht überarbeitet

#### `solo_09` Chaosgeist (SOLO)

- **[R] Regeltext:** Solo: „Würfle laut einen Würfel. Die gewürfelte Zahl entspricht der Anzahl Spieler, die heute durch Lynchung sterben müssen.“
- **Quelle:** `js/core/cards.js`, `solo_09`
- **[V] Mechanische Wirkung im Spiel:** Die Person würfelt laut; die Zahl entspricht der Anzahl Personen, die heute durch Lynchung sterben müssen.
- **[V] Handlung in der realen Welt:** Würfeln am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Würfelzahl; Ergebnis mehrerer Abstimmungen.
- **Unklarheiten und Rolleninteraktionen:** Mehrere Hinrichtungen an einem Tag. Zahl größer als Lebende. Würfel (ÜB-4). ÜB-2.
- **Status:** noch nicht überarbeitet

#### `solo_10` Einsames Erbe (SOLO)

- **[R] Regeltext:** Solo: „Du hinterlässt zwei Zettel beim SL. Auf einem steht der Name des Spielers, der gewinnen wird. Auf dem anderen steht der erste Spieler, der nach dir stirbt. Beide Zettel werden zu ihrem jeweiligen Zeitpunkt geöffnet. Lagen beide richtig — du gewinnst posthum.“
- **Quelle:** `js/core/cards.js`, `solo_10`
- **[V] Mechanische Wirkung im Spiel:** Zwei Zettel: Name der siegenden Person und der ersten Person, die nach der Kartenträgerin stirbt; beide werden zum jeweiligen Zeitpunkt geöffnet. Lagen beide richtig, gewinnt sie posthum.
- **[V] Handlung in der realen Welt:** Zwei Zettel schreiben und der SL geben.
- **[V] Eingabe oder Bestätigung der SL:** Zwei Zielpersonen, später die Ergebnisse.
- **Unklarheiten und Rolleninteraktionen:** Posthumer Sieg (Endbericht, Siegprüfung); wer „gewinnt“ bei Team-Sieg? Zettel nicht in der App (SL trägt Namen ein).
- **Status:** noch nicht überarbeitet

#### `solo_12` Familienbande aus dem Totenreich (SOLO)

- **[R] Regeltext:** Solo: „Wähle einen Spieler — dieser erhält dauerhaft +3 auf seine Stimme. Er gewinnt automatisch, wenn er unter den letzten 2 Lebenden ist, und du gewinnst mit ihm.“
- **Quelle:** `js/core/cards.js`, `solo_12`
- **[V] Mechanische Wirkung im Spiel:** Eine Person erhält dauerhaft +3 auf ihre Stimme; sie gewinnt automatisch, wenn sie unter den letzten 2 Lebenden ist, und die Kartenträgerin gewinnt mit.
- **[V] Handlung in der realen Welt:** SL merkt sich +3.
- **[V] Eingabe oder Bestätigung der SL:** Zielperson.
- **Unklarheiten und Rolleninteraktionen:** Automatischer Sieg unter den letzten zwei (Siegprüfung). Stimmen am Tisch. ÜB-2.
- **Status:** noch nicht überarbeitet

#### `solo_14` Verrat oder Verbrüderung (SOLO)

- **[R] Regeltext:** Solo: „Du darfst einen deiner lebenden Nachbarn beschuldigen, böse zu sein — sollte der andere Nachbar zustimmen, stirbt der besagte Bösewicht.“
- **Quelle:** `js/core/cards.js`, `solo_14`
- **[V] Mechanische Wirkung im Spiel:** Die Person darf einen lebenden Nachbarn beschuldigen, böse zu sein; stimmt der andere Nachbar zu, stirbt der Beschuldigte.
- **[V] Handlung in der realen Welt:** Beschuldigung und Zustimmung am Tisch.
- **[V] Eingabe oder Bestätigung der SL:** Beschuldigte Person, Zustimmung ja/nein.
- **Unklarheiten und Rolleninteraktionen:** Wer sind „Nachbarn“ der Toten (Sitzordnung, tote Nachbarn)? Todesursache. Die Person ist tot: von welcher Position aus?
- **Status:** noch nicht überarbeitet

## 7. Ergebnis der ersten Fragerunde (beantwortet am 30.09.2026)

Die Antworten sind im Decision Log („Kartenschlucker, Grundregeln“) verbindlich eingetragen. Die Empfehlungen der Vorversion dieser Liste sind damit überholt; die Zuordnung zu den Fragen-IDs ist meine Zuordnung, die Antworten kamen als zusammenhängender Regeltext.

| Frage | Thema | Antwort des Product Owners (sinngemäß) |
|---|---|---|
| KS-01 | „Im Spiel“ bei Tod und Rollenverlust | Tausch nur, solange eine lebende Person die Rolle Kartenschlucker besitzt; jeder zulässige Tausch gibt einen Stapel. |
| KS-02 | Tötungsfähigkeit | Freiwillige Nachtaktion „zwei Finger“: zwei Stapel abgeben, eine Person töten, höchstens einmal pro Nacht; kein Zwang, keine Kombination. |
| KS-03 | Schild | Nachtaktion „fünf Finger“: fünf Stapel abgeben, Schild kaufen; bleibt bis zum verhinderten Tod, höchstens einer, kein Gratis-Schild, keine Erneuerung. |
| KS-04 | Zählbeginn der Ansage | Feste Nächte 3, 6, 9 usw., sofern er lebt und die Rolle besitzt. |
| KS-05 | Stapel bei Rollenwechsel | Stapel gehören zur Person; neuer Träger bei null; beim bisherigen Träger ruhen sie und werden bei Rückerhalt der Rolle wieder nutzbar. |
| KS-13 (im Kern) | Sieg bei zehn Stapeln | Kein Automatismus: nur die Nachtaktion „zehn Finger“ (zehn Stapel abgeben) löst den Sieg aus; Spielleiterbestätigung bleibt. |

## 8. Zweite Fragerunde

Nur neue Fragen; Entschiedenes wird nicht wiederholt. Jede Frage: betroffene Karte oder Fähigkeit mit unverändertem relevantem Originaltext, ein Beispiel, drei Antworten, freie Antwort D, fachlich begründete Empfehlung. Die Empfehlung ist ein Vorschlag, keine Entscheidung, und nichts davon ist implementiert.

### KS-06: Schild: Welche Todesarten verhindert der gekaufte Schild?

Originaltext:
- [R] Kein Kartentext. Der Schild steht nur in der Entscheidung (Decision Log, Kartenschlucker, Grundregeln): „Ein gekaufter Schild bleibt bestehen, bis er einen Tod verhindert.“

Beispiel: Der Kartenschlucker hat einen Schild. Am Tag wird er hingerichtet, in einer späteren Nacht greift das Rudel ihn an, dann trifft ihn ein Zusatzopfer des Rudelvaters (das sonst Schutz ignoriert).

- **A:** Jeder Tod durch Rollenwirkung oder Hinrichtung wird verhindert. Effekte, die „Schutz ignorieren“, durchdringen den Schild nicht (wie bei den persönlichen Schilden anderer Einzelsiegrollen, RM-DR-005). Spielleiterkorrekturen wirken immer.
- **B:** Nur Tode in der Nacht (Rudelangriff und Fähigkeiten). Die Hinrichtung am Tag trifft ihn trotz Schild.
- **C:** Nur der Rudelangriff wird verhindert. Fähigkeiten und Hinrichtung nicht.
- **D:** Eigene Antwort.

Empfehlung und Begründung: A ist fachlich stimmig: Der Schild kostet fünf Stapel, also mehr als das Doppelte der Tötung. B lässt die Hinrichtung ungeschützt, C wäre gegen Fähigkeiten und Hinrichtung wertlos. A passt zur vorhandenen Regel für persönliche Schilde (RM-DR-005) und braucht keine zusätzliche Ausnahme. Achtung: Was bei einer verhinderten Hinrichtung geschieht (Tag endet ohne Opfer oder neue Abstimmung), bleibt eine eigene Frage.

Reichweite: Betrifft den Kartenschlucker und die Todespipeline (Gruppe 2 der Kartenliste). Reihenfolge mit anderen Schutzwirkungen bleibt offen.

### KS-07: Schild: Was passiert mit einem vorhandenen Schild bei Rollenverlust, Tod und Wiederbelebung?

Originaltext:
- [R] Kein Kartentext. Bestätigt: „Ein gekaufter Schild bleibt bestehen, bis er einen Tod verhindert.“ Ausdrücklich nicht aus der Stapelregel abzuleiten.

Beispiel: Anna ist Kartenschlucker und hat einen Schild. Eine Spielleiterkorrektur nimmt ihr die Rolle, später bekommt sie die Rolle zurück. Oder: Ein Effekt, der den Schild durchdringt, tötet sie; später wird sie wiederbelebt.

- **A:** Der Schild gehört zur Person und bleibt in allen Fällen bestehen. Er wirkt, solange die Person lebt, auch ohne die Rolle.
- **B:** Der Schild gehört zur Person, ruht aber ohne die Rolle: Bei Rollenverlust wirkt er nicht, nach Rückerhalt wieder. Tod und Wiederbelebung ändern nichts an seinem Bestand.
- **C:** Der Schild verfällt bei Rollenverlust. Bei Tod und Wiederbelebung bleibt er bestehen.
- **D:** Eigene Antwort.

Empfehlung und Begründung: B folgt dem Wortlaut (bleibt bestehen, bis er einen Tod verhindert) und verhält sich wie die ruhenden Stapel, ohne dass eine Person ohne die Rolle plötzlich einen Rollenvorteil hat. A gäbe einem Nicht-Kartenschlucker Schutz, C vernichtet bezahlte Stapel durch eine Spielleiterkorrektur.

Reichweite: Betrifft nur den Schild, nicht Stapel (entschieden) und nicht die Todesarten (KS-06).

### KS-08: Öffentliche Ansage: Welche Zahl wird in den Nächten 3, 6, 9 genannt?

Originaltext:
- [R] Kein Kartentext. Bestätigt: Feste Nächte 3, 6, 9 usw., sofern er lebt und die Rolle besitzt. Legacy-Text (historisch): „Das Dorf erfährt: Kartenschlucker hat N Stapel.“

Beispiel: In Nacht 6 hat der Kartenschlucker 7 Stapel gesammelt und wählt „zwei Finger“ (zwei abgeben, jemanden töten). Was hört das Dorf?

- **A:** Das aktuelle Guthaben: Es zählt, was er hat (nach seiner Aktion dieser Nacht: 5).
- **B:** Die Gesamtzahl aller je gesammelten Stapel, auch der ausgegebenen (z. B. 7 plus frühere Käufe).
- **C:** Nur die Stufe: „unter 2“, „mindestens 2“, „mindestens 5“, „mindestens 10“ (ohne genaue Zahl).
- **D:** Eigene Antwort.

Empfehlung und Begründung: A nennt die Zahl, mit der er tatsächlich handeln kann (2, 5, 10). Das gibt dem Dorf faire, spielrelevante Information. B verrät auch, was er schon ausgegeben hat, und macht Rückschlüsse auf frühere Aktionen möglich. C ist geheimniswahrend, nimmt der Ansage aber den Nutzen. Der Zeitpunkt (vor oder nach der Aktion, Morgen oder Nacht) ist eine getrennte Frage und bleibt in der Liste.

Reichweite: Betrifft nur den Inhalt der Ansage.

### KS-09: Wann wird die Originalkarte eines Toten gespielt (und wann darf getauscht werden)?

Originaltext:
- [R] `segen_04` Stille Nacht (Dorf): „Die Wölfe dürfen heute Nacht kein Opfer wählen — sie schlafen.“
- [R] `segen_09` Gerechter Zorn (Wolf): „Wird beim nächsten Lynch ein Werwolf gelyncht, dürfen die Wölfe in dieser Nacht zwei Opfer reißen statt einem.“
- [R] Bestätigt: Originalkarte einmal tauschen, Ersatzkarte sofort spielen.

Beispiel: Anna stirbt in Nacht 2, ihr Tod wird am Morgen bekannt. Ihre Karte lautet „Die Wölfe dürfen heute Nacht kein Opfer wählen“. Welche Nacht ist „heute Nacht“, und bis wann kann der Kartenschlucker-Tausch stattfinden?

- **A:** Sofort, wenn der Tod öffentlich wird (Morgenauflösung oder Hinrichtung): Anna entscheidet dann tauschen oder spielen; „heute Nacht“ und „nächster Lynch“ zählen ab diesem Moment.
- **B:** Zu einem festen Zeitpunkt: zu Beginn der nächsten Phase nach dem öffentlichen Tod. Bis dahin bleibt die Karte verdeckt und kann getauscht werden.
- **C:** Der Tote wählt den Zeitpunkt selbst (Ankündigung an die Spielleitung); bis dahin bleibt die Karte verdeckt und tauschbar.
- **D:** Eigene Antwort.

Empfehlung und Begründung: A ist die klarste Ursache-Wirkung-Kette, gilt für alle 80 Karten gleich und erzeugt keinen verdeckten Kartenvorrat (den C eröffnen würde: Der Kartenschlucker müsste beliebig lange auf Tauschgelegenheiten warten). B ist möglich, macht aber Bezüge wie „heute Nacht“ je nach Todeszeit unterschiedlich. Bezüge „nächste Nacht“ (ÜB-3) sind damit für alle Karten eindeutig.

Reichweite: Betrifft alle 80 Karten und den Tauschablauf. Nicht Teil: wer die Karte ansagt und wie die Spielleitung sie bestätigt.

### KS-10: Kartenbedingung „lebende Wiederbelebungsrolle im Spiel“: behalten, verschieben oder streichen?

Originaltext:
- [R] `segen_08` Zweites Leben (Dorf): „Ein toter Dorfbewohner deiner Wahl kehrt als vollwertiger Dorfbewohner mit seiner ursprünglichen Rolle zurück.“
- [R] `wende_04` Wiedergeburt (Dorf): „Der Spielleiter wählt nach eigenem Ermessen einen toten Dorfbewohner — er kehrt mit seiner ursprünglichen Fähigkeit zurück.“
- [R] `wende_07` Befreiung (Dorf): „Ein toter Dorfbewohner kehrt mit halber Fähigkeit zurück — er darf sie einmalig einsetzen, dann stirbt er erneut.“
- [R] `loki_10` Phoenix (Neutral): „Es werden zwei Würfel gewürfelt, der erste belebt entsprechend viele zufällige Spieler wieder, der zweite entscheidet für wie viele Runden sie am Leben bleiben.“
- [R] Alle vier tragen im Legacy-Code die Bedingung: lebende Person mit Rollen-Tag revive, role-return oder death-trigger-transform. Ebenso trägt `wende_12` (Dorf) im Text: „Nur in Spielen mit Wiederbelebungs-Szenarien“.

Beispiel: In der Partie gibt es keine Kutscher-, Frankenstein- oder ähnliche Rolle. Anna zieht (oder tauscht in) die Karte „Wiedergeburt“: Ein toter Dorfbewohner kehrt zurück. Darf diese Karte überhaupt vergeben werden?

- **A:** Bedingung behalten und prüfen: Die Karte wird nur vergeben und nur gespielt, solange eine lebende Person mit einer Wiederbelebungsrolle im Spiel ist (wie im Legacy-Code).
- **B:** Bedingung nur beim Vergeben prüfen: Die Karte wird nur gezogen, wenn beim Ziehen eine solche Rolle lebt. Beim Spielen wird nicht erneut geprüft.
- **C:** Bedingung streichen: Die Karte wirkt immer. Die Wiederbelebung geschieht durch die Karte selbst, unabhängig von Rollen.
- **D:** Eigene Antwort.

Empfehlung und Begründung: A bewahrt die vorhandene Kartenidee (W-01 sah die Bedingung ausdrücklich für den Karten-Assistenten vor) und verhindert eine Wiederbelebung, die keine Rolle der Partie erklärt und die Wiederbelebungsregeln W-01 bis W-04 unbemerkt ausweitet. C wäre eine stille Änderung von vier Karten. B lässt zu, dass die Karte nach dem Tod der Rolle wirkungslos oder widersprüchlich wird.

Reichweite: Betrifft 4 (mit `wende_12` 5) Karten der Gruppe 1 und die Bedingung von Kutscher und Frankenstein (RM-DR-141.4). Wie eine Karten-Wiederbelebung genau abläuft, ist eine eigene Frage in der Liste.

## 9. Weitere offene Punkte, geordnet für die nächsten Runden

Noch nicht gestellt. Nichts davon ist beschlossen. Reihenfolge nach Abhängigkeit von den Fragen in Abschnitt 8.

| ID | Frage |
|---|---|
| KS-11 | Tötung („zwei Finger“): Ziel (auch die eigene Person?), Todesursache, Zeitpunkt (Nacht oder Morgen), Schutz und Durchdringung, Reihenfolge mit anderen Todesregeln. (Gruppe 2 und 3) |
| KS-12 | Ansage: Zeitpunkt (vor oder nach der Aktion, Nacht oder Morgen) und Verhalten bei übersprungenen Nächten. (Gruppe 3) |
| KS-13 | Sieg („zehn Finger“): Wann entsteht der Kandidat, was geschieht bei Ablehnung durch die Spielleitung oder Tod in derselben Nacht (Guthaben zurück oder verbraucht)? Regeln DR-02, DR-14, F-11 gelten. |
| KS-14 | Nachtablauf: Wie wird die Fingerwahl am Tisch erfasst und in der App eingetragen (die Wahl darf die Spielleitung wohl allein sehen)? Wecken in Nächten, die durch Karten ausfallen. (ÜB-9) |
| KS-15 | Öffentlichkeit: Ist der Tausch sichtbar, und wer sieht die Stapelzahl außerhalb der Ansage? Ablauf des Tauschs am Tisch (wer fordert, wer bestätigt). (ÜB-7) |
| KS-16 | Kartentexte je Person (ÜB-1, korrigiert): Welche Karten kommen für Wölfe, Dorf, Einzelsiegrollen und Neutrale in Frage, und nach welcher Rolle oder Fraktion, wenn sie sich zwischen Tod und Spielen ändert? |
| KS-17 | Ziehung: Zufall über den gespeicherten Generator oder Auswahl der Spielleitung, Kartenbestand, Wiederholungen, Gewichtung. (ÜB-4, ÜB-6) |
| KS-18 | Wiederbelebung durch Karten (`segen_08`, `wende_04`, `wende_07`, `loki_10`): Gelten die Wiederbelebungsregeln W-01 bis W-04 (frischer Start), und was heißt „ursprüngliche Fähigkeit“ bei Einmalfähigkeiten? (Gruppe 1) |
| KS-19 | `wende_07`: Was ist eine „halbe Fähigkeit“ (auch bei Rollen ohne aktive Fähigkeit)? `loki_10`: Würfel am Tisch oder Generator, was ist eine „Runde“? (Gruppe 1) |
| KS-20 | Rollenwechsel durch Karten (`schicksal_08`, `loki_06`): Welche Rollen sind erlaubt, folgt der Zustand der Person oder der Rolle? Wechsel von oder zum Kartenschlucker folgt der Stapelregel (entschieden); Wechsel zum Selbstmörder berührt den Fünf-Tote-Hinweis (6B). (Gruppe 1) |
| KS-21 | Schild: verhinderte Hinrichtung (Tag endet ohne Opfer oder neue Abstimmung) und Reihenfolge mit Nekromant-, Hades-, Parasit- und Rudelvater-Wirkungen. (Gruppe 2) |
