# Terminologie DE/EN (Entwurf)

**Status:** Entwurf, nicht freigegeben. Quell-Commit `312f5bbbbec4c218754b35a0043b51e79d80bcf5` (`audit/all-72-roles`).
Diese Liste gilt für alle Dateien in `docs/content-drafts/`. Sie ändert keine Regel und keine bestehende Übersetzungsdatei. Wo sie von `godot/content/i18n/ui.*.po` abweicht, steht die Abweichung unter "Abweichungen" und in `OPEN-ISSUES.md`.

## 1. Feste Begriffe

| Konzept | DE | EN | Bedeutung und Abgrenzung | Quelle |
|---|---|---|---|---|
| Person am Tisch | Person | person | Nie "Spieler", nie Sitzplatz. Identität ist die Person, der Sitz ist nur Anordnung. | DECISION-LOG "Personen, Sitze und Darstellung", G-ID-1 |
| Leitung | Spielleiter (Kurzform SL) | game master (GM) | Bedient das Tablet, liest an, bestätigt. | `ui.en.po` "Game master cockpit" |
| Tod (allgemein) | Tod, stirbt, gestorben | death, dies, died | Oberbegriff für jeden Tod, unabhängig von Ursache. | G-TOD-1 |
| Hinrichtung | Hinrichtung, wird hingerichtet | execution, is executed | Tod durch die Abstimmung am Tag, vom Spielleiter bestätigt. Intern `LYNCH`. Die Entwürfe verwenden auf Karten "Hinrichtung"; "gelyncht" steht in Kurztexten und im Decision Log und ist eine Formulierungsfrage. | DECISION-LOG "Regeln", G-TAG-3, G-TOD-3 |
| Rudelangriff | Rudelangriff | pack attack | Ausschließlich die gemeinsame nächtliche Wahl des Rudels (einschließlich weiterer Rudelopfer der Art des Rudelvaters). Einzeltötungen einzelner Wolfsrollen sind kein Rudelangriff. "Wolfsangriff" ist dasselbe und ebenfalls ein Begriff der Quellen (G-TOD-3); die Entwürfe schreiben "Rudelangriff" der Klarheit wegen, "Wolfsangriff" ist in Kurztexten zulässig. | DECISION-LOG "Rollenaudit · Querschnittsfragen" (RM-DR-004) |
| Rudelopfer | Rudelopfer | pack victim | Person, die das Rudel in dieser Nacht gewählt hat. | G-TOD-3, Waldhexe-Eintrag |
| Rudel | Rudel | pack | Alle lebenden Personen, die zu Beginn der Nacht als Wolf zählen und gemeinsam aufwachen. | rules-register §2 |
| Wolf (Zählung) | zählt als Wolf | counts as a wolf | Wahre Wolfszählung (`counts_as_wolf`). Eine Scheinrolle täuscht nur Rollenauskünfte, nie die Zählung. | G-ID-2, RM-DR-002.2, I-02 |
| Fraktion | Fraktion: Dorf, Werwölfe, Einzelsieg | faction: Village, Werewolves, Solo | Zieht die Siegbedingung. Der endgültige Name der dritten Gruppe ist noch nicht entschieden. | `ui.faction.*`, DECISION-LOG "Noch zu benennende Punkte" |
| Alleinsieg | Alleinsieg, gewinnt allein | solo win, wins alone | Nur diese Person gewinnt, nicht ihre Fraktion. | Rollenaudit Einzelsiegrollen |
| Mitsieg | Mitsieg, gewinnt mit | shared win, wins along with | Person gewinnt zusätzlich zu einer anderen siegreichen Seite. Beispiele: Feuerteufel, Die Ewigen. | E-08, I-12 |
| Schutz | Schutz, schützt | protection, protects | Wiederholbare oder einmalige Wirkung, die einen Tod verhindert. Nur gegen das, was die Rolle nennt. | Rollenaudit Schutzrollen (S-10, S-11) |
| Rettung | Rettung, rettet | rescue, rescues | Nur für den Heiltrank der Waldhexe und die einmalige Rettung des Weisen. | Waldhexe-Eintrag, S-02 |
| Schild | Schild | shield | Schutzwirkung des Schutzgeists oder des Nekromanten. Kein Schutz im Sinne des Schutzengels. | S-04, E-16 |
| Durchdringen | durchdringt den Schutz | pierces protection | Wirkt trotz Schutzengel, Waldhexenrettung, Dorfwache und Rettung des Weisen. Nicht gegen persönliche Schilde der Einzelsiegrollen, Umlenkungen und Ersatzopfer. | RM-DR-005 |
| Rollenwechsel | Rollenwechsel, erhält die Rolle | role change, receives the role | Oberbegriff für Erbe, Tausch, Verwandlung und Korrektur. Frische Einsätze beginnen. | Lehrling-Eintrag, V-04 |
| Erbe | erbt die Rolle | inherits the role | Nur Lehrling. | DR-11 |
| Verwandlung | verwandelt sich, wird zum Wolf | transforms, becomes a wolf | Wolfskind, König Lykaon, Kutscher. | DR-10, V-03, W-02 |
| Tausch | tauscht die Rollen | swaps roles | Nur Seelentauscher. | V-04, V-05 |
| Wiederbelebung | Wiederbelebung, wird wiederbelebt | revival, is revived | Tote Person lebt wieder. Setzt alle begrenzten Einsätze zurück. | "Rollenaudit · Wiederbelebung ..." |
| Einsatz | Einsatz, Ladung | use, charge | Begrenzter Fähigkeitseinsatz. "Einmal je Leben" gilt seit der Wiederbelebungsentscheidung. | G-ID-3, Wiederbelebungs-Eintrag |
| Blockade | blockiert, Blockade | blocks, block | Lässt nur aktive Nachtschritte von Dorfrollen entfallen. | RM-DR-010 |
| Todesmarkierung | Todesmarkierung | death marker | Person stirbt erst in der Morgenauflösung. | "Nachfrage zu F-04" |
| Fluch | Fluch, verflucht | curse, curses | Sensenträger (Tod), Dämonischer Wolf (nur Rollenauskunft), Weiser (Ruhen der Dorffähigkeiten). Immer den Rollennamen dazuschreiben, wenn Verwechslung möglich ist. | DR-09, V-02, S-01 |
| Nacht, Morgen, Tag | Nacht, Morgen, Tag | night, dawn, day | Für Karten: "Morgen" für die Morgenauflösung, "Tag" für Diskussion und Abstimmung. | `ui.phase.*`, G-PH-1 |
| Nominierung | Nominierung, nominiert | nomination, nominates | Eine Person schlägt eine andere für die Hinrichtung vor. | DR-03 |
| Spielende | Spielende, Sieg bestätigen | game over, confirm the win | App schlägt Sieg vor, Spielleiter bestätigt. | "Nachfrage zu F-11" |
| Wiederbelebungsrunde | Wiederbelebungsrunde | revival round | Runde, in der Wiederbelebung möglich ist (direkte Rollen, später Totenreichkarten). Rollen bleiben verdeckt, Tote halten nachts die Augen geschlossen. | Antwort des Product Owners vom 29.09.2026 |
| Todeseffekt | Todeseffekt | death effect | Sichtbare Folge eines Todes, die ausgespielt und mit Effekt und Rolle angesagt wird. | Antwort des Product Owners vom 29.09.2026 |

## 2. Zeichenkonventionen für die Entwürfe

- Rollen-ID in Codeschrift, deutsches ASCII-kebab-case (DR-01), zum Beispiel `das-orakel`.
- Rollennamen wie in `godot/content/i18n/ui.de.po` beziehungsweise `ui.en.po`. Bei Abweichung im Genus oder Artikel gilt: "der Weise / The Elder".
- Aufgerufene Rolle wird mit "du" angesprochen, das Rudel mit "ihr", der Tisch mit "alle" (`docs/assets/NARRATOR-SCRIPT.md` §1).
- Keine Gedankenstriche als Satzzeichen. Zahlen in Fließtext bis zwölf ausgeschrieben, Nachtnummern und Schwellen als Ziffern.
- Beispielnamen: Anna, Ben, Clara, David, Emil (wie in `docs/role-migration/10-next-decisions.md`).

## 3. Kategorien der Führungstexte

| Kennzeichen | Bedeutung | Wer darf es sehen oder hören |
|---|---|---|
| `[SL-PRIVAT]` | Anweisung oder Ergebnis nur für den Spielleiter | nur Spielleiter auf dem Tablet |
| `[PERSON-PRIVAT]` | Information nur für die betreffende Person | nur diese Person, gezeigt auf Tablet oder Smartphone |
| `[ÖFFENTLICH]` | Ansage für alle am Tisch, vorgelesen oder als Karte | alle, auch der öffentliche Bildschirm |

Regel: `[ÖFFENTLICH]` nennt nie eine geheime Rolle, ein geheimes Ziel, eine geheime Wirkung, eine Todesursache oder einen Namen, den die Regel nicht ausdrücklich veröffentlicht (G-TOD-5, DECISION-LOG "Smartphone und öffentlicher Bildschirm").

## 4. Abweichungen und Fehlalarme gegenüber bestehenden Übersetzungsdateien

Die Punkte wurden nicht in `ui.*.po` geändert, weil `godot/` und Übersetzungsdateien nicht Teil dieses Auftrags sind. Nach der fachlichen Prüfung (`OPEN-ISSUES.md`, OI-04) ist keiner davon ein Regelkonflikt.

| Stelle | Bestehender Text | Bewertung |
|---|---|---|
| Kurztexte `ui.role.*.short` (Schutzengel, Dorfwache, Weiser, Schutzgeist, Dorfschmied, Verdammniswächter, Seuchenwolf) | "Wolfsangriff", "Angriff der Werwölfe" | Kein Konflikt. "Wolfsangriff" ist ein Begriff der Quellen und bedeutet ausschließlich den Rudelangriff (RM-DR-004, G-TOD-3). Beide Wörter sind gleichbedeutend, die Angleichung ist optional. |
| EN-Kurztexte | "werewolf attack", "wolf attack", "the next attack" | Uneinheitlich innerhalb der EN-Datei. Eine Form wählen, zum Beispiel "pack attack" oder "wolf attack". Stilfrage. |
| Kurztexte Weiser und Kopfgeldjäger | "gelyncht", "lynched" | Formulierungsfrage. G-TOD-3 nennt `LYNCH` (Hinrichtung), das Decision Log verwendet beide Wörter. Die Entwürfe verwenden "Hinrichtung / execution". |
| Regelregister §7 (Regeltext Sensenträger) | "einmal pro Partie" | Überholt, ersetzt durch "einmal je Leben" (Entscheidung vom 27.09.2026, OI-05). |
| EN-Kurztexte mit Personenbezug (zum Beispiel Seuchenwolf, Schutzgeist) | "his", "her" | Stilfrage. Die Entwürfe verwenden neutrales "their", weil die Person am Tisch beliebig sein kann. |
| Schlüssel `ui.role.das_orakel.*` und weitere | Unterstrich statt Bindestrich | Kein Verstoß. Übersetzungsschlüssel sind keine Rollen-IDs. DR-01 (kebab-case) betrifft die technischen Rollen-IDs (`das-orakel`). Die Schlüsselbildung ist eine Integrationsfrage. |
