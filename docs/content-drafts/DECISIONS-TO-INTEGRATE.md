# Bestätigte Entscheidungen zur Übernahme (Entwurf)

**Status:** Übergabe an die UI-Entwicklung. Stand: Quell-Commit `312f5bbbbec4c218754b35a0043b51e79d80bcf5`, Branch `content/rolebook-and-guide`. Nichts hier ist im Decision Log, im Regelkern oder in der UI umgesetzt. Alle Einträge sind Antworten des Product Owners vom 29.09.2026 in der Claude-Code-Sitzung (Auswahlfenster und Freitext). Die Wortlaute der Freitextantworten sind zitiert, die Auslegung ist benannt. Diese Datei gibt keine Produktionsfreigabe.

**Zuerst prüfen:** DI-01 und DI-03 ändern bisherige Produktvorgaben (DR-04, G-TOD-5, die Setup-Option `reveal_role_on_death` und die UI-Tests dazu).

## Übersicht

| ID | Thema | Art |
|---|---|---|
| DI-01 | Wiederbelebungsrunde statt frei wählbarer Rollenaufdeckung | **ÄNDERUNG der bisherigen Produktvorgabe** |
| DI-02 | Aufrufpolitik | neue Regel |
| DI-03 | Todeseffekte werden ausgespielt und angesagt | **ÄNDERUNG der bisherigen Produktvorgabe (DR-04)** |
| DI-04 | Loki: Information der Betroffenen | Ergänzung |
| DI-05 | Rotkäppchen: Wissen der gefragten Person | Ergänzung |
| DI-06 | Rattenfänger: zwei Phasen | Ergänzung |
| DI-07 | Pestbringerin: Hinweis für jede Infizierte | Ergänzung |
| DI-08 | Trugbilderwolf: Scheinrolle nur dem Spielleiter bekannt | Ergänzung |
| DI-09 | Ton bei fünf Toten beibehalten | Bestätigung |

---

## DI-01 · Wiederbelebungsrunde und Rollenaufdeckung (ÄNDERUNG)

- **Bisherige Vorgabe:** DR-04 (Decision Log Zeile 106) und G-TOD-5: Die Setup-Option "Rolle beim Tod aufdecken: Ja/Nein" ist frei wählbar. Acceptance-Szenarien AS-M01, AS-M02, AS-M03 (`docs/specs/vertical-slice/acceptance-scenarios.md` §6) testen beide Werte von `reveal_role_on_death`.
- **Neuer Inhalt (Auslegung):** Es gibt zwei Rundenarten.
  - **Wiederbelebungsrunde:** Wiederbelebung ist in der Runde möglich. Rollenkarten werden nicht aufgedeckt. Tote halten nachts die Augen geschlossen.
  - **Runde ohne Wiederbelebung:** Rollenkarten werden beim Tod aufgedeckt. Tote müssen nachts die Augen nicht schließen.
- **Herkunft:** Freitext auf die Frage nach der Bedeutung von "möglich": "Es gibt Charaktere und später auch totenreichkarten die spieler wiederlebe, in runden wo dies möglich ist sollen rollenakrten nicht aufgedeckt werdn und spieler müssen auch ihre augen in der nacht geschlossen halten auch wenn sie tod sind, in runden wo es keine wiederbelebung gibt müssen spieler ihre augen nachts nicht schließen und decken auch ihre rollenkarte auf." Präzisierung durch Auswahl: "Nur direkte Rollen und Karten".
- **Was "möglich" heißt:** Die Rollenbesetzung enthält eine direkte Wiederbelebung (Kutscher, Dr. Victor Frankenstein, später Totenreichkarten). Indirekte Träger (Lehrling erbt, Seelentauscher tauscht, Grabräuber stiehlt) und die Spielleiterkorrektur `revive` lösen den Modus nicht aus. Die gewählte Option nennt zusätzlich: Das Setup warnt, wenn Erbe, Tausch oder Diebstahl eine solche Rolle erreichen könnte. Das ist eine Eigenschaft der Rundenbesetzung, festgelegt im Setup, nicht im laufenden Spiel umschaltbar.
- **Betroffen:** Setup-Option `reveal_role_on_death` (wird von der Rollenbesetzung abgeleitet statt frei gewählt), Morgenbericht, Nachtansage (`narration.night.begin_revival`), Rollen Kutscher und Dr. Victor Frankenstein, später Totenreichkarten (OI-02), alle Texte mit Rollenaufdeckung (GUIDE-TEXTS `narration.morning.role_reveal`).
- **Decision-Log-Eintrag nötig:** Ja. Neuer Eintrag "Wiederbelebungsrunde", der DR-04 und G-TOD-5 ausdrücklich ersetzt (Rollenaufdeckung nicht mehr frei wählbar), samt Definition von "möglich".
- **Auswirkungen:**
  - UI: Setup zeigt keine freie Option, sondern eine abgeleitete Anzeige; Nachtansage für Tote; Warnung bei indirekten Trägern.
  - Informationsweitergabe: In Wiederbelebungsrunden darf kein Text eine Rolle Toter nennen (Ausnahme: Todeseffekt-Ansagen, DI-03).
  - Regelkern: Rundeneigenschaft im Setup-Zustand (Kern kennt die Option bisher nicht, sie liegt in der Anwendungsschicht).
- **Akzeptanztests (Vorschlag):**
  1. Besetzung mit Kutscher: Setup zeigt Wiederbelebungsrunde, Morgenbericht nennt beim Tod nur den Namen.
  2. Besetzung ohne Kutscher, Frankenstein und Karten: Morgenbericht nennt Name und Rolle (Ersatz für AS-M03).
  3. Besetzung mit Lehrling, ohne direkte Wiederbelebung: Runde ohne Wiederbelebung, Setup zeigt Warnung nur bei erreichbarer Rolle.
  4. Spielleiterkorrektur `revive` in Runde ohne Wiederbelebung: Modus bleibt, aufgedeckte Rolle bleibt aufgedeckt.
  5. Wiederbelebungsrunde: Nachtansage nennt "auch die Toten".
  6. Öffentliche Projektion (AS-M02): In Wiederbelebungsrunden keine Rollen Toter.
- **Offene Abhängigkeiten:** Totenreichkarten sind nicht definiert (OI-02). Wie die Warnung bei indirekten Trägern genau aussieht. Ob die abgeleitete Anzeige im Setup umgeschaltet werden darf (die Antwort sagt "nur direkte Rollen und Karten", nicht wer den Modus überstimmen darf). **Die alten UI-Tests und die Setup-Option müssen mit dieser Regel abgeglichen werden**, bevor PR #3 gemergt wird.

## DI-02 · Aufrufpolitik

- **Herkunft:** Freitext: "ES gibt zwei zenarien, bereits aufgedeckte Rollen in der Night Order werden nicht mehr aufgerufen, aufgebrauchte rollen werden trotzdem aufgerufen nur haben sie keine fähigkeiten mehr dait das dorf und die werwölfe nicht wissen was schon genutzt wurden ist und was nicht, in runden mit wiederbelebung werden auch tote rollen weiter aufgerufen damit das Dorf/Diewölfe nicht wissen wer noch lebt bzw tod ist."
- **Inhalt:** Runde ohne Wiederbelebung: aufgedeckte (tote) Rollen werden in der Nachtreihenfolge nicht mehr aufgerufen; aufgebrauchte Rollen werden weiter aufgerufen, ohne Fähigkeit. Wiederbelebungsrunde: auch tote Rollen werden weiter aufgerufen.
- **Abgeleitet, zu bestätigen:** Blockierte und noch nicht aktive Rollen (zum Beispiel Henker vor drei Hinrichtungen) werden ebenfalls aufgerufen, weil sonst Blockade und Schwellen sichtbar würden. Rollen, die in der Partie nicht vorkommen, werden nicht aufgerufen.
- **Betroffen:** alle Rollen mit eigenem Nachtschritt, Nachtreihenfolge, Ansagekarten (NARRATOR-SCRIPT Regel 4 und Frage 6.1), GUIDE-TEXTS §3.3, Schattenhund und Albtraumwolf (blockierte Rollen).
- **Decision-Log-Eintrag nötig:** Ja, "Aufrufpolitik". Beantwortet die offene Frage in `docs/assets/NARRATOR-SCRIPT.md` §6 Nr. 1 und ersetzt die Einstellung "Tote Rollen weiter aufrufen" (`docs/godot-migration/02-product-and-ux-spec.md` Zeile 76) durch eine von DI-01 abgeleitete Regel.
- **Auswirkungen:** UI: Nachtplan enthält auch Schritte, die ohne Fähigkeit ablaufen (Tarnschritte mit Wartezeit); Nachtleiste darf Tarnschritte nicht als Tarnung kennzeichnen, wenn sie öffentlich sichtbar ist. Informationsweitergabe: Aufruf verrät nur die Rollen der Partie. Regelkern: Tarnschritte sind kein Regelereignis, nur Ansage.
- **Akzeptanztests:**
  1. Runde ohne Wiederbelebung: Rolle X ist tot und aufgedeckt, in der folgenden Nacht kein Aufruf von X.
  2. Runde ohne Wiederbelebung: Einmalfähigkeit verbraucht, Aufruf bleibt, kein Prompt.
  3. Wiederbelebungsrunde: tote Rolle wird aufgerufen, Ansage identisch zu einer lebenden.
  4. Henker vor drei Hinrichtungen: Aufruf ohne Fähigkeit (nach der abgeleiteten Regel).
  5. Rolle außerhalb der Partie: kein Aufruf.
- **Offene Abhängigkeiten:** Wartezeit eines Tarnaufrufs (Vorschlag 5 s, NARRATOR-SCRIPT). Die abgeleiteten Punkte oben. Handlungszeilen (OI-18).

## DI-03 · Todeseffekte werden ausgespielt und angesagt (ÄNDERUNG)

- **Bisherige Vorgabe:** DR-04 und G-TOD-5: "Todesursache und interne Effekte bleiben privat, sofern eine Regel sie nicht ausdrücklich veröffentlicht."
- **Herkunft:** Freitext zu D6 (Fluch des Weisen): "Egal ob wiederbelbung oder nicht es ist ein Todeseffket alle Todeseffekt werden ausgespeilt und auch angesagt." Umfang durch Auswahl: "Sichtbare Folgen eines Todes". Inhalt durch Auswahl: "Effekt und Rolle nennen" (auch in Wiederbelebungsrunden).
- **Inhalt:** Sichtbare Folgen eines Todes werden öffentlich ausgespielt und angesagt, mit Effekt und Rolle des Toten. Zu den Todeseffekten gehören (Auslegung der Auswahl): Sensenträger, Ritter, Besessener Wolf, Wahnsinniger Kutscher, Fluch des Weisen, Liebeskummer, Rotkäppchen-Kette, Verknüpfung des Schattenwanderers. Geheime Wahlen ohne sichtbare Folge (Fluch des Dämonischen Wolfs, Voodoo-Puppe, Markierungen) bleiben verdeckt.
- **Bewusste Ausnahme:** In Wiederbelebungsrunden bleiben Rollenkarten verdeckt, aber ein Todeseffekt nennt die Rolle des Toten. Das ist gewollt.
- **Betroffen:** `sensentraeger`, `ritter`, `besessener-wolf`, `wahnsinniger-kutscher`, `der-weise`, `loki`, `rotkaeppchen`, `schattenwanderer`; GUIDE-TEXTS §3.4 (neue Ansagen), §4.1; allgemeine Regel DR-04.
- **Decision-Log-Eintrag nötig:** Ja, "Todeseffekte werden angesagt", Ersatz für "interne Effekte bleiben privat" bei diesen Effekten, mit Liste.
- **Auswirkungen:** UI: öffentliche Ansagekarte je Todeseffekt; Reihenfolge der Ansagen mit der Todesauflösung. Informationsweitergabe: öffentliche Projektion enthält diese Effekte und Rollen; AS-M02 muss die Ausnahme kennen. Regelkern: Ereignisse `SAGE_CURSED`, `LOKI_BOUND` und andere GM-Ereignisse brauchen öffentliche Gegenstücke ohne Zusatzdaten; Reaktionen (Sensenträger, Ritter, Besessener Wolf) müssen ein öffentliches Ergebnisereignis liefern.
- **Akzeptanztests:**
  1. Sensenträger verflucht X: öffentliche Ansage nennt Rolle und X. Verzicht: keine Ansage.
  2. Ritter durch Rudelangriff: Ansage nennt Ritter und den mitgerissenen Wolf.
  3. Fluch des Weisen in Wiederbelebungsrunde: Ansage nennt Weisen und "Fähigkeiten ruhen".
  4. Liebeskummer: Ansage "Aus Liebeskummer stirbt X".
  5. Fluch des Dämonischen Wolfs: keine öffentliche Ansage.
  6. Öffentliche Projektion enthält sonst keine Todesursache.
- **Offene Abhängigkeiten:** Welche Rolle bei Liebeskummer, Kette und Verknüpfung genannt wird. Ob die Länge des Fluchs des Weisen genannt wird (Entwurf: nein). Wiederbelebung durch Kutscher in der Ansage: bereits öffentlich (`PLAYER_REVIVED`). Wortlaut der Ansagen (Entwurf in GUIDE-TEXTS §3.4).

## DI-04 · Loki: Information der Betroffenen

- **Herkunft:** Auswahl "B: Liebende und Rivalen erfahren es".
- **Inhalt:** Liebende und Rivalen erfahren privat ihren Partner und die Art der Bindung.
- **Betroffen:** `loki`, `schwarze-witwe` (ihre Wahl trifft nun Personen, die von der Bindung wissen).
- **Decision-Log-Eintrag:** Ergänzung zu B-05. **Regelkern:** private Ereignisse (`actor`) für beide Personen bei `LOKI_BOUND`. **UI:** private Karte je Person.
- **Akzeptanztests:** Bindung als Liebende: beide sehen "Du und X seid Liebende"; als Rivalen: beide sehen "Rivalen"; nichts öffentlich; Loki in Nacht 2 keine Bindung.
- **Offene Abhängigkeiten:** Zeitpunkt der Karte (sofort oder beim Aufruf), Bedienablauf (OI-18).

## DI-05 · Rotkäppchen: Wissen der gefragten Person

- **Herkunft:** Freitext: "Die Fähigkeiten und damit verbundenen Effekte sind allen spielern bekannt Ben darf ablehnen wenn er will denn er kennt den vorteil und nachteil". Auswahl "Nein, anonym": Die gefragte Person erfährt nicht, wer fragt.
- **Inhalt:** Die gefragte Person kennt Apfel und Kette, entscheidet frei und weiß nicht, wer sie fragt.
- **Betroffen:** `rotkaeppchen`. **Decision-Log-Eintrag:** Ergänzung zu R-01. **Regelkern:** Frage an die Person ohne Absenderangabe. **UI:** private Frage mit Erklärung von Apfel und Kette.
- **Akzeptanztests:** Anfrage nennt Rotkäppchen nicht; Zusage setzt Kette und Apfel; Ablehnung setzt nichts; Wolf darf ablehnen.
- **Offene Abhängigkeiten:** Bedienablauf am Tisch (OI-18). Die Ansage bei Tod durch die Kette (DI-03) verrät das Paar; ob dabei Rotkäppchens Rolle genannt wird, ist offen.

## DI-06 · Rattenfänger: zwei Phasen

- **Herkunft:** Freitext: "Erst gibt es eine Abfrage die NEUEN Verzauberten und dann "Alle Verzauberten"" sowie "Verzauberte Werden geweckt und wissen das sie von nun an verzaubert sind es gibt eine Phase nachdem Rattenfänger welche alle Neuen Verzauberten auffordert einmal kurz die augen zu öffnen". Auswahl: In der zweiten Phase sehen sich alle Verzauberten.
- **Inhalt:** Nach dem Schritt des Rattenfängers öffnen zuerst die neu Verzauberten kurz die Augen und erfahren ihren Status. Danach kommt die Phase "Alle Verzauberten": Alle Verzauberten öffnen die Augen und erkennen einander. Ob sie es im Dorf teilen, entscheiden sie selbst.
- **Betroffen:** `rattenfaenger`. **Decision-Log-Eintrag:** Ergänzung zu E-01. **Regelkern:** zwei neue Schritte nach dem Rattenfänger. **UI:** zwei Ansagekarten, private Karten.
- **Akzeptanztests:** Nacht mit neu Verzauberten: Phase 1 nur für sie; Phase 2 für alle Verzauberten mit Namensliste; Nacht ohne Neue: Phase 1 entfällt; Blockade betrifft die Phasen nicht (Einzelsiegrolle).
- **Offene Abhängigkeiten:** Ob Phase 2 in Nächten ohne Neue stattfindet (nicht beantwortet). Tarnung dieser Phasen nach DI-02. Nachtpriorität.

## DI-07 · Pestbringerin: Hinweis für jede Infizierte

- **Herkunft:** Freitext: "beim Infizierten ebenfalls soll ein kleiner remidner kommen, das Spieler X Infiziert wurden ist und weiß was mit ihm & seinen Nachbarn geschieht wenn man ihm am Leben lässt. Ob sie das im Dorf teilen ist dann nichtmehr sache der Rattenfänger/Pestbringer sondern der spieler". Auswahl: Jede neu infizierte Person erhält den Hinweis, auch durch die Ausbreitung.
- **Inhalt:** Jede neu infizierte Person erhält einen privaten Hinweis mit Zustand und Folgen.
- **Betroffen:** `pestbringerin`. **Decision-Log-Eintrag:** Ergänzung zu E-02. **Regelkern:** privates Ereignis bei `INFECTED` und bei Ausbreitung. **UI:** private Karte, auch am Morgen.
- **Akzeptanztests:** Infektion in der Nacht: Hinweis an die Person; Ausbreitung am Morgen: Hinweis an den Nachbarn; kein öffentlicher Text.
- **Offene Abhängigkeiten:** Zeitpunkt der Anzeige bei Ausbreitung am Morgen (die Person schläft nicht), Bedienablauf.

## DI-08 · Trugbilderwolf: Scheinrolle nur dem Spielleiter bekannt

- **Herkunft:** Auswahl "Nein, nur der Spielleiter".
- **Inhalt:** Der Trugbilderwolf erfährt seine Scheinrolle nicht.
- **Betroffen:** `trugbilderwolf`. **Decision-Log-Eintrag:** Ergänzung zu DR-08. **Regelkern/UI:** keine Anzeige der Scheinrolle auf der privaten Karte (entspricht dem Stand).
- **Akzeptanztests:** Private Karte des Trugbilderwolfs enthält keine Scheinrolle; Spielleiteransicht zeigt sie.
- **Offene Abhängigkeiten:** keine.

## DI-09 · Ton bei fünf Toten beibehalten

- **Herkunft:** Auswahl "Beibehalten wie entschieden". Bestätigt Decision Log Zeile 284.
- **Inhalt:** Der Ton ertönt öffentlich, sobald die fünfte Person tot ist, nur wenn ein Selbstmörder in der Partie ist. Er legt die Rolle in der Partie offen, nicht wer sie hat.
- **Decision-Log-Eintrag:** kein neuer, Bestätigung genügt. **Akzeptanztests:** Ton bei fünf Toten mit Selbstmörder; kein Ton ohne.
- **Offene Abhängigkeiten:** Bedeutung von "in der Partie" (Rolle zu Spielbeginn oder lebende Person). Audio-Umsetzung.

---

## Gesamtliste der Anpassungen vor der Übernahme in PR #3

1. Setup: `reveal_role_on_death` von der Rollenbesetzung ableiten (DI-01). Alte Tests AS-M01 bis AS-M03 und alle UI-Tests, die die Option setzen, anpassen.
2. Nachtansagen: Variante für Wiederbelebungsrunden (DI-01) und Aufrufpolitik (DI-02).
3. Öffentliche Projektion: Todeseffekte mit Rolle zulassen (DI-03); AS-M02 anpassen.
4. Regelkern: private Ereignisse für Loki, Pestbringerin, Rattenfänger (DI-04, DI-06, DI-07) und öffentliche Ergebnisse der Todesreaktionen (DI-03).
5. Decision Log: Einträge DI-01 bis DI-08 nachziehen, DR-04 und G-TOD-5 ausdrücklich ersetzen.
6. Rollenkarten (`ui.role.*`) und Texte erst nach der Prüfung des gemeinsamen App-Stands übernehmen (siehe `README.md` §7).
