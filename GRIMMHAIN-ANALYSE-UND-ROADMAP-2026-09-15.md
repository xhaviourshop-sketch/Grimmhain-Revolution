# Grimmhain: Analyse, Produktziel und Roadmap

**Stand: 15. September 2026**  
**Ziel:** Eine hochwertige Tablet-App, mit der Spielleiter reale Grimmhain-Runden zuverlässig, entspannt und atmosphärisch leiten können.  
**Art:** Bestandsanalyse und Entwicklungsvorschlag. Es wurde kein App-Code geändert.

## 1. Zusammenfassung und klare Empfehlung

Grimmhain besitzt bereits viel Substanz: eine eigene Spielwelt, 72 Rollendefinitionen, Akte, Totenkarten, Nachtabläufe, Audio, Spielprotokoll, eine React-Oberfläche und mobile Projektgerüste. Das Projekt steht nicht am Anfang.

**Die größte Lücke liegt zwischen Funktionsumfang und verlässlicher Benutzbarkeit am Spieltisch.** Speichern, Wiederherstellung, fehlerfreie Sonderaktionen, Geheimhaltung und Übersicht müssen zur tragenden Grundlage werden. Noch mehr Rollen oder Dekoration würden diese Lücke zunächst vergrößern.

Empfohlene Reihenfolge:

1. Einen verbindlichen Entwicklungsstand und identische Auslieferung schaffen.
2. Spielzustand, Wiederherstellung und kritische Rollenaktionen absichern.
3. Das Tablet-Cockpit auf Lesbarkeit, Orientierung und wenige Eingaben ausrichten.
4. Den gesamten Abend durchgängig führen: Vorbereitung, Nacht, Tag, Sonderfälle, Abschluss.
5. Mit fremden Spielleitern am echten Tisch testen.
6. Erst anhand dieser Ergebnisse Inhalt, Vermarktung und weitere Plattformen ausbauen.

**Positionierungsvorschlag:**  
„Grimmhain hält dir beim Leiten den Kopf frei: Du führst die Runde, die App behält Regeln, Effekte und nächste Schritte im Blick.“

Das ist eine Produkthypothese, keine bereits nachgewiesene Marktposition.

### Drei mögliche Entwicklungswege

| Weg | Vorteil | Nachteil | Empfehlung |
|---|---|---|---|
| Jüngeren Grimmhain-Stand schrittweise stabilisieren | Eigene Regeln und bisherige Arbeit bleiben nutzbar; Fortschritte früh testbar | Übergangsadapter muss gezielt verbessert werden | **Empfohlen** |
| BotC-App als neue Basis nehmen und Grimmhain einbauen | Einige Bedienkonzepte sind weiter | Fremde Regelannahmen, Begriffe und Zustandsmodelle erzeugen neue Fehler | Nur einzelne Konzepte oder klar abgegrenzte Komponenten übernehmen |
| Vollständiger Neubau | Freie Architektur | Hoher Aufwand, erneute Implementierung aller Sonderfälle, lange ohne nutzbares Ergebnis | Derzeit nicht gerechtfertigt |

**Grundannahme der Roadmap:** Vor-Ort-Runden auf einem Spielleiter-Tablet stehen zuerst. Das passt zum vorhandenen PLAN.md und zum aktuellen Auftrag. Öffentlich nutzbare Qualität ist das Ziel; Accounts, Online-Multiplayer und Steam sind spätere Erweiterungen.

---

## 2. Was untersucht wurde und wie belastbar die Ergebnisse sind

### Prüfmethoden

- Dateistrukturen, relevante Änderungsdaten und vorhandene Git-Historie.
- Quellcodevergleich ausgewählter App-, Website- und Referenzvarianten.
- Aktuelle Einstiegspunkte, Adapter, Zustandsspeicherung, Nachtlogik, Sonderrollen, Build-Konfiguration und Tests.
- Historische Roadmaps und Prüfberichte, jeweils als historische Aussagen eingeordnet.
- Lokaler Browserdurchlauf: Einstieg, Namenseingabe, Rollenwahl, zufällige Verteilung, Spielbrett und Beginn einer Loki-Aktion.
- Visuelle Prüfung bei 1024 × 768 CSS-Pixeln. Ein zusätzlicher 1280 × 800-Versuch wurde wegen nicht vollständig dargestellter Aufnahme nicht als verlässlicher Layoutnachweis verwendet.
- Ausführung der bestehenden Smoke-Prüfung, des DE/EN-Schlüsselvergleichs und der TypeScript-Prüfung.
- Abgleich ausgewählter Qualitätsziele mit W3C und der PWA-Dokumentation.

### Grenzen

Dies ist eine breite Produkt- und Architekturprüfung mit gezielten Code-Stichproben, **kein vollständiger Audit jeder Datei, jeder Rollenpaarung oder jedes historischen Dokuments**. Archive und mobile Altstände wurden zur Einordnung untersucht, nicht vollständig ausgeführt. Kein echter iPad-/Android-Gerätetest, keine komplette Partie, kein Store-Build und kein Offline-Neustarttest.

Die UI-Prüfung verwendete die vorhandenen lokalen Runtime-Kopien. Fünf zentrale Engine-Dateien wurden per Hash mit den Originalen verglichen und waren identisch. Das ist keine Vollständigkeitsgarantie für sämtliche Assets.

### Evidenzstufen

- **Beobachtet:** Im aktuellen lokalen Browserdurchlauf gesehen.
- **Codebelegt:** Im untersuchten Quellcode eindeutig vorhanden oder begrenzt.
- **Historisch:** In einem älteren Bericht beschrieben; kein aktueller Laufzeitnachweis.
- **Vorschlag:** Neue Produktentscheidung, die noch gebaut und getestet werden muss.

---

## 3. Ordner, Versionen und empfohlene Grundlage

Alle Pfade beziehen sich auf `C:/Users/Marku/Desktop/`.

| Ordner | Einordnung und Datumsbefund | Verwendung |
|---|---|---|
| `Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main` | Jüngerer Grimmhain-App-Stand. Root-HTML vom 13.07.2026; relevante Engine-/Adapterdateien bis 14.07.2026. React-Spielfeld mit echter Legacy-Anbindung. In diesem Verzeichnis keine Git-Historie erkannt. | **Primärer Kandidat für die weitere App-Entwicklung** |
| `Grimmhain/Grimmhain-Werwolf/Grimmhain` | Älterer Vanilla-App-Stand mit Git. Letzter ausgelesener Commit: 12.06.2026, `7040d98`; einzelne Dateien danach geändert. | Historie und Vergleichsgrundlage sichern |
| `Grimmhain/Grimmhain-Werwolf/Grimmhain Mobile` | Ältere mobile Variante; jüngste untersuchte Quelldateien Anfang Mai 2026. QA-Bericht vom April. | Referenz für mobile Erfahrungen, nicht neue Hauptbasis |
| `Grimmhain/NEw Grimmhain` | Marketing-Website, keine Spielleiter-App. Untersuchte Änderungen vom 05.07.2026. | Visuelle Markenreferenz; Funktionalität getrennt bewerten |
| `Grimmhain/NEw Grimmhain - Kopie` | Die 35 von links verglichenen TS-/TSX-/JS-/CSS-Dateien sind identisch. Kein vollständiger Vergleich aller Assets und Zusatzdateien. | Kein belegter eigenständiger Entwicklungszweig |
| `Grimmhain/Grimmhain-Werwolf/Grimmhain-Website/Grimmhain-Website` | Umfangreichere ältere Website mit Newsletter-, Forum- und Checkout-Routen sowie Tests. | Funktionale Quelle; nicht durch ein neueres Design blind ersetzen |
| `Grimmhain/Grimmhain-Werwolf/Grimmhain Assets/production-pilot` | Tatsächlich 72 WebP-Rollenporträts; zusätzlich Manifest und Oberflächenassets. Action-Art laut Pilotstatus teilweise provisorisch. | Wertvolle Produktionsgrundlage |
| `Botc-react/Botc-react` | React-Referenz mit Nachtführung, Setup, Layout- und Regelarbeit. Keine Git-Historie am untersuchten Ort erkannt. | Referenzstand |
| `Blood on the Clocktower/Botc-react` | Weiterentwickelte Referenz mit Git; letzter ausgelesener Commit 14.07.2026, `00c6a39`. Beim gerichteten Vergleich: 36 gleiche und 13 abweichende Quelldateien; zusätzliche Raumdateien vorhanden. | **Bevorzugte BotC-Referenz** |
| `Blood on the Clocktower/Botc - App` | Vanilla-/Electron-App; untersuchte zentrale Datei vom 08.06.2026. Enthält private Informationsansichten. | Bedienkonzepte und ältere Auslieferung |
| `Blood on the Clocktower/Archiv_BotC_Docs_und_Source` | Dokumente und Quell-Snapshot; untersuchte zentrale Datei vom 09.06.2026. | Historischer Vergleich |

**Wichtig:** Änderungsdatum allein beweist keine Versionsabstammung. Die Empfehlung kombiniert Datum, tatsächlich vorhandene Funktionen und Git-Informationen. Es wurde nichts gelöscht, verschoben oder zusammengeführt.

### Sofortige Organisationsentscheidung

Künftig genau ein Hauptrepository für die App verwenden. Den jüngeren Stand mit der älteren Git-Historie vergleichen und nachvollziehbar übernehmen. Alte Varianten zunächst unverändert archivieren. Kopien nicht weiter parallel entwickeln.

Website, App und Assets dürfen eigene Bereiche bleiben. Entscheidend sind ein klarer Eingang für Änderungen, dokumentierte Verantwortlichkeit und reproduzierbare Builds.

---

## 4. Was bereits gut ist

### 4.1 Eigenständiges Spielmaterial

72 Rollen stehen in `ALL_ROLES`. Akte, Fraktionen und Totenkarten schaffen deutlich mehr Eigenständigkeit als ein generischer Sitzkreis. Diese Inhalte sind ein Vermögenswert, zugleich eine große Testverpflichtung.

### 4.2 Spielleiterführung ist bereits angelegt

Der React-Stand besitzt:

- Nachtreihenfolge und aktionsbezogene Anzeige.
- Aktionsfenster für Informationen, Entscheidungen und Zielwahl.
- Spielerbearbeitung und Rollenwahl.
- Tag-/Nachtsteuerung, Laufzeitanzeige und Spielprotokoll.
- Rückgängig mit Klartext-Rückmeldung.
- Schutz vor Phasenwechsel während offener Aktionen.
- Rollenkarte und Statuslegende.

Das sind vorhandene Bausteine, keine komplett neu zu erfindenden Features.

### 4.3 Die Übergangsarchitektur ermöglicht schrittweise Arbeit

`GameAdapter` trennt die React-Oberfläche von der bisherigen Engine. Diese Naht ist nützlich. Ihre heutige interne Umsetzung über versteckte HTML-Elemente ist allerdings zu fragil, um dauerhaft alle Regeln daran zu binden.

### 4.4 Die Bildwelt ist wiedererkennbar

Dorfplatz, Nachtstimmung, Porträts und Metallrahmen bilden eine erkennbare gestalterische Richtung. Der nächste Qualitätsschritt ist eine bessere Hierarchie: Namen, Aktionen und Zustände müssen schneller erkennbar sein als die Verzierung.

---

## 5. Schwächen, Auswirkungen und Verbesserungen

**Prioritäten:** P0 = vor externer Beta lösen; P1 = wesentlich für eine hochwertige erste Veröffentlichung; P2 = nach stabiler Kernstrecke.

| ID | Prio | Befund und Evidenz | Auswirkung am Spieltisch | Verbesserung |
|---|---|---|---|---|
| W01 | P0 | Web liefert `app/dist`; Capacitor lädt `dist`, das Root-HTML/Legacy-Dateien erhält. Codebelegt. | Browser und installierte App können unterschiedliche Oberflächen und Funktionen haben. | Ein freigegebenes Web-Artefakt für beide Ziele; Versionsanzeige und Paritätstest. |
| W02 | P0 | `sw.js` hat ausdrücklich keinen Fetch-/Cache-Pfad. Codebelegt. | Offline-Start der Web-App ist nicht zuverlässig vorgesehen. | Vollständiger Offline-Pfad mit kontrollierten Updates; separat native Bündelung testen. |
| W03 | P0 | Zustand im localStorage; Speicherfehler nur als Console-Warnung, Parsefehler liefern null. Codebelegt. | Spielleiter merkt einen fehlgeschlagenen Speicherstand möglicherweise nicht; beschädigte Daten können wie fehlende Daten wirken. | Speicherstatus, letzter gültiger Stand, Wiederherstellungsdialog, versionierte Validierung. |
| W04 | P0 | Undo besteht aus einem `lastSnapshot` im Arbeitsspeicher. Protokoll liegt separat. Codebelegt. | Keine belastbare Rückkehr über mehrere Schritte oder nach Neustart. | Mehrstufige Historie plus Phasen-Sicherungspunkte; klare Regeln für Log, Timer und Folgeeffekte. |
| W05 | P0 | Frankenstein erzeugt ein `select`; der Dialog-Mirror überträgt Text und Buttons, keine Auswahlfelder. Historischer Fehler durch aktuelle Codeprüfung gestützt. | Spielleiter kann die neue Rolle im React-Dialog nicht bewusst wählen. | Typisierte Rollenauswahl; Rolle ausdrücklich bestätigen; Wiederbelebung erst vollständig übernehmen. |
| W06 | P0 | Frankenstein setzt `dead=false` vor Prüfung verfügbarer Rollen und vor finaler Rollenbestätigung. Codebelegt. | Abbruch oder fehlende Optionen können einen teilweise geänderten Zustand hinterlassen. | Aktion vorbereiten, vollständig prüfen, dann gemeinsam anwenden; Abbruch verändert nichts. |
| W07 | P1 | Namenszuordnung bei zwölf Spielern auf 1024 × 768 teilweise sehr eng, insbesondere Clara/David und Klara/Lukas. Beobachtet. | Falsches Ziel oder unnötige Suchzeit. | Kollisionsprüfung für Token UND Namen; kompaktere Rahmen; eindeutige Sitznummern. |
| W08 | P1 | Namensliste mit Zeilenumbrüchen zählt als ein Name; `split(',')` im Code. Beobachtet und codebelegt. | Vorbereitung scheitert an einer üblichen Eingabeform. | Zeilenumbrüche und Kommas unterstützen; Vorschau, Leerzeichenbereinigung, Dublettenhinweis. |
| W09 | P1 | Gate entfernt die Spielansicht bei Portrait oder unter 900 × 600. Codebelegt. | Drehen oder ein kleinerer Viewport unterbricht die Bedienung; temporärer UI-Zustand ist zu prüfen. | Spielsession unabhängig von Layout weiterhalten; Portrait mindestens als sichere Übersicht. |
| W10 | P0 | Bestehender Smoke-Test prüft Dateitext, nicht ausgeführte Regeln. Codebelegt. | Grün liefert wenig Sicherheit für Tod, Wiederbelebung und Sieg. | Ausführbare Szenarien, Adaptertests, wenige entscheidende UI-Ende-zu-Ende-Tests. |
| W11 | P1 | Aktionsdaten entstehen aus verstecktem DOM und Textinterpretation. Codebelegt. | Kleine Änderungen an Sprache oder HTML können Spielführung verändern. | Schrittweise strukturierte Aktionsdaten statt ausgelesener Darstellung. |
| W12 | P1 | Speichern löst selbst Spielfolgen aus, unter anderem Queue-/Propheten-/Siegprüfungen. Codebelegt. | Speichern ist keine rein technische Operation; Undo und Wiederholung werden schwer vorhersehbar. | Fachaktionen und Folgeeffekte zuerst abschließen, danach unveränderten Zustand speichern. |
| W13 | P1 | In der untersuchten React-Kernoberfläche kein durchgängig ausgearbeiteter privater Übergabeflow gefunden. | Gerät zeigen kann verdeckte Informationen offenlegen. | Dedizierte Spieleranzeige mit explizit freigegebenen Daten, Schutzschirm und Rückkehrsperre. |
| W14 | P1 | Root-Roadmap, App-README und tatsächlicher Stand widersprechen sich. Codevergleich. | Arbeit wird doppelt geplant; erledigte oder offene Funktionen werden falsch eingeschätzt. | Eine aktuelle Produktroadmap, eine kurze Architekturübersicht und ein überprüfbarer Release-Status. |
| W15 | P2 | Neuere Website hat beim Newsletter nur `preventDefault` plus „Bald verfügbar“. Codebelegt. | Eintragen führt nicht zum Aufbau einer Warteliste. | Erst echte Anmeldung und Bestätigung, dann damit werben. Ältere Routen als geprüfte Ausgangsbasis nutzen. |

### Keine falschen Schlussfolgerungen

- Ein vorhandener Capacitor-Ordner beweist noch keine veröffentlichungsfähige App.
- Ein bestandener TypeScript-Check beweist keine Regelkorrektheit.
- Gleich viele DE-/EN-Schlüssel beweisen weder gute Übersetzungen noch vollständige Lokalisierung der Oberfläche.
- Historische „erledigt“-Markierungen sind keine aktuelle Abnahme.
- „72 Rollen vorhanden“ bedeutet nicht „alle Kombinationen getestet“.
- Die Namensüberlagerung ist aktuell beobachtet. Frühere Layoutberichte sind nur ergänzende Evidenz.

---

## 6. Was aus BotC übernommen werden sollte

Die lokalen BotC-Projekte sind **Referenzprojekte**, keine gleichzusetzende Kopie der offiziellen BotC-App.

| Idee / Baustein | Fundort und Stand | Nutzen für Grimmhain | Übernahmegrenze |
|---|---|---|---|
| Tagesprotokoll mit Nominierungen und Abstimmungen | Jüngerer React-Adapter: `recordNomination`, `recordVote`, `getDayLog` | Tagesphase nachvollziehbar führen und korrigieren | Abstimmungsregeln aus Grimmhain ableiten |
| Eigene private Informationsansicht | `Botc - App/private-info-overlay.js` | Rollen/Informationen diskret zeigen | Geheimhaltungsgrenze neu testen; nicht nur optisch verdecken |
| An Geräteform und Spielerzahl angepasste Layouts | `displayMode.ts`, `tabletSeatLayout.ts` | Komfortansicht und kompakte Großrundenansicht | Konstanten nicht blind kopieren; tatsächlichen verfügbaren Platz messen |
| Aktivierbare Spielleiter-Hinweise | Storyteller-Token-Funktionen im Adapter | Erinnerungen, Sonderregeln, offene Pflichten | Fabled/Loric sind BotC-spezifisch; Grimmhain benötigt eigene Begriffe und Regeln |
| Versionsbezogener Import/Export | `js/core/state.js` | Sicherung und Gerätewechsel | Inhalt validieren; kein ungeprüfter Rohimport |
| Trennung lokaler Runden | `room/roomId.ts`, raumbezogene Speicherschlüssel | Mehrere gespeicherte Partien ohne Überschreiben | Eine Raum-ID ist weder Online-Synchronisation noch Zugriffsschutz |
| Zentrale Todesentscheidung | `BOTC_attemptDeath` und zugehörige Regelarbeit | Einheitliche Behandlung von Schutz und Folgeeffekten | Nur das Architekturprinzip, keine BotC-Todesregeln übernehmen |
| Benannte manuelle Entscheidungen | Funktionen für Storyteller-Aktionen | App hilft, Spielleiter behält Kontrolle | Keine verborgene Automatik bei unklaren Regeln |

### Was nicht übernommen werden sollte

1. **Write-only-Datenbankspiegel:** BotCs `idb-mirror.js` beschreibt selbst den fehlenden Restore-Pfad. Kopieren würde keine echte Wiederherstellung schaffen.
2. **Weitere globale Sonderfälle im Adapter:** Mehr Funktionen in derselben Brücke machen die Grenze nicht automatisch robuster.
3. **BotC-Regeln für tote Stimmen, Rollenregistrierung oder Sieg:** Grimmhain braucht seine eigene verbindliche Regeldefinition.
4. **Raumsystem als vorzeitigen Multiplayer-Einstieg:** Lokale Rundenverwaltung genügt zunächst.
5. **Ungeprüfte Assets, Texte und Lizenzen:** Vor einer Übernahme Herkunft und Nutzbarkeit dokumentieren; die eigene Bildwelt ist bereits vorhanden.

---

## 7. Zielbild: So sollte sich die fertige App anfühlen

### Die wichtigsten Fragen des Spielleiters sind jederzeit beantwortet

- In welcher Phase sind wir?
- Wer ist gerade dran?
- Was muss ich sagen oder entscheiden?
- Welche Ziele sind erlaubt?
- Welche Effekte verändern die Aktion?
- Was wird passieren, wenn ich bestätige?
- Was steht danach an?
- Ist der Stand sicher gespeichert?

### Hauptansicht

**Oben:** kompakte Phase, Nacht-/Tagesnummer, aktuelle Rolle, Fortschritt, Speicherstatus.  
**Mitte:** Sitzordnung mit Namen, Sitznummern, klaren Zustandsmarkierungen.  
**Anpassbares Aktionspanel:** Auftrag, erlaubte Ziele, gewählte Ziele, Konsequenz und Bestätigung.  
**Unten:** letzte Aktion rückgängig, Pause/Schutzschirm, nächste sinnvolle Aktion.  
**Bei Bedarf:** Protokoll, Regeln und Einstellungen in beschrifteten Panels.

Die aktuelle große Rollenüberschrift kann deutlich weniger Höhe beanspruchen. Das Bild der Rolle ist hilfreich, muss aber kleiner werden dürfen, wenn Spielerplätze sonst kollidieren.

### Bedienregeln

- Antippen wählt; ein klarer Bestätigungsbutton führt spielentscheidende Änderungen aus.
- Lange drücken öffnet Zusatzinformationen, aber jede wichtige Funktion hat auch einen sichtbaren Weg.
- Keine versteckten Pflichtgesten.
- Im Normalfall genau eine deutlich hervorgehobene nächste Aktion.
- Abbrechen muss den Zustand vor Beginn der offenen Aktion erhalten.
- „Rolle ansehen“, „Fähigkeit starten“, „überspringen“ und „abschließen“ sind unterschiedliche Vorgänge.
- Wiederholtes Tippen darf keine doppelte Ausführung erzeugen.
- Spielleiterkorrekturen bleiben möglich und werden verständlich protokolliert.
- Öffentliche Anzeige enthält ausschließlich freigegebene Informationen.

### Gestalterische Leitlinie

**Dunkle Märchenwelt, helle und klare Bedieninformation.**

- Dekor für Atmosphäre, sparsam an Bildschirmrändern und Übergängen.
- Ruhige Flächen hinter Regeln und Namen.
- Gut lesbare Schrift für laufende Bedienung; dekorative Schrift für Überschriften.
- Farbe plus Symbol plus Text bei kritischen Zuständen.
- Effekte und Geräusche abschaltbar.
- Keine Animation darf eine Aktion verzögern oder den Fokus verdecken.
- Linkshänderoption für das Aktionspanel.

---

## 8. Konkrete Quality-of-Life-Funktionen

### Vor der Runde

| Funktion | Konkretes Verhalten | Priorität |
|---|---|---|
| Runde fortsetzen | Letzte Runde mit Datum, Phase und Spielerzahl anzeigen | P0 |
| Teilnehmerlisten | Namen zeilen- oder kommagetrennt einfügen; Gruppe lokal wiederverwenden | P1 |
| Sitzordnung anpassen | Spieler verschieben, ohne Rolle oder stabile Spieler-ID zu verändern | P1 |
| Kuratierte Startsets | Vorschlag nach Spielerzahl und Erfahrung, mit kurzer Begründung | P1 |
| Setup-Prüfung | Fehlende Pflichtrollen, ungültige Mengen, widersprüchliche Paarungen melden | P1 |
| Komplexitätsanzeige | Zahl aktiver Nachtaktionen und schwieriger Wechselwirkungen statt unbelegtem „Balance-Score“ | P1 |
| Verteilung wählen | Zufällig, manuell oder vorbereitete Plätze; vorhandene Wege vereinheitlichen | P1 |
| Sound-/Lesbarkeitscheck | Vor Beginn kurz Lautstärke, Schrift und Sichtbarkeit prüfen | P1 |
| Vorbereitungscheckliste | „Alle kennen ihre Rolle“, „Sitzordnung stimmt“, „Sonderregeln erklärt“ | P1 |
| Regelversion fixieren | Runde bleibt während des Abends auf ihrer gestarteten Regelversion | P0 |

### Während der Nacht

| Funktion | Konkretes Verhalten | Priorität |
|---|---|---|
| Geführter Nachtmodus | „Aufwecken → Information/Aktion → Ergebnis → einschlafen → weiter“ | P1 |
| Kurzer Moderationstext | Direkt sprechbare Formulierung; Details ausklappbar | P1 |
| Erlaubte Ziele | Deutliche Markierung; bei gesperrten Zielen verständlicher Grund | P1 |
| Mehrfachauswahl | Gewählte Namen, verbleibende Anzahl, einzelne Auswahl entfernen | P1 |
| Erinnerung mit Laufzeit | „Geschützt bis Morgen, Quelle: Schutzengel“ | P1 |
| Aktionsvorschau | Vor Abschluss betroffene Spieler und Änderungen anzeigen | P0 |
| Morgenprüfung | Offene Aktionen, geplante Todesfälle und auslaufende Effekte vor Phasenwechsel | P0 |
| Wiederaufnahme | Nach Unterbrechung wissen, welche Information bereits gegeben wurde | P0 |
| Diskrete Spielerkarte | Nur ausgewählte Information zeigen; verdeckter Rückweg zur Spielleiteransicht | P1 |
| Begründung | „Warum dieses Ergebnis?“ mit relevanten Effekten und Regeltext | P1 |

### Während des Tages

| Funktion | Konkretes Verhalten | Priorität |
|---|---|---|
| Morgenbericht | Was muss öffentlich gesagt werden, was bleibt privat? | P1 |
| Diskussionstimer | Start/Pause/Verlängern; Zeitmessung über Unterbrechungen konsistent | P1 |
| Tagesassistent | Nominierung, Abstimmung, Entscheidung, Folgeeffekte, Nachtbereitschaft | P1 |
| Stimmenübersicht | Schnelle Eingabe und sichtbare Korrektur nach Grimmhain-Regeln | P1 |
| Öffentliche Anzeige | Große neutrale Anzeige von Phase, Timer und ausdrücklich freigegebenem Ergebnis | P2 |
| Manuelle Korrektur | Rolle, Status oder Ausgang ändern, mit Vorschau und protokolliertem Grund | P1 |
| „Was ist noch offen?“ | Tagesfähigkeiten, Totenkarten und Pflichtentscheidungen bündeln | P1 |

### Für Verstorbene und Sonderfälle

- Totenkarten-Assistent: verfügbare Karte, aktueller Besitzer, Einsatzfenster, Ziel und Verbrauch klar anzeigen.
- Reaktionswarteschlange: bei mehreren Todesfolgen genau zeigen, welcher Effekt als Nächstes abgearbeitet wird.
- Wiederbelebung: neue Rolle, Fraktion, verbleibende Effekte und Einmalfähigkeiten gemeinsam prüfen.
- Rollenwechsel: alter Zustand, neuer Zustand und übernommene beziehungsweise entfernte Effekte sichtbar machen.
- Sonderfälle nicht still lösen: Wenn eine Regelentscheidung beim Spielleiter liegt, ausdrücklich danach fragen.
- Hinweis „Diese Rolle erfordert noch manuelle Moderation“, solange ihre Automation nicht abgenommen ist.

### Nach der Runde

- Abschlusszusammenfassung mit Gewinner und nachvollziehbarem Auslöser.
- Private Chronik von öffentlich teilbarer Zusammenfassung trennen.
- „Gleiche Gruppe, neue Runde“ mit optionalem Erhalt der Sitzordnung.
- Runde lokal archivieren, exportieren und wiederherstellen.
- Kurzes Feedback: Wo musste der Spielleiter überlegen, suchen oder korrigieren?
- Später: Rückblick auf entscheidende Momente, erst nach ausdrücklichem Freigeben geheimer Informationen.

---

## 9. Die stärksten zusätzlichen Ideen

### 9.1 Spielleiter-Lernmodus

Eine kurze geführte Proberunde erklärt nicht alle Regeln auf einmal. Sie lässt den Nutzer typische Situationen erleben: Zielwahl, Schutz, Tod, Rückgängig, Wiederaufnahme.

**Wert:** Neue Spielleiter können die App kennenlernen, bevor zwölf Menschen auf sie warten.  
**Prüfung:** Ein neuer Nutzer erledigt die Proberunde ohne persönliche Erklärung.

### 9.2 Erfahrener Modus

Gleicher Regelkern, kompaktere Texte und weniger erklärende Zwischenschritte. Sicherheitsrelevante Bestätigungen bleiben verständlich.

**Wert:** Anfänger werden geführt, erfahrene Spielleiter werden nicht ausgebremst.  
**Abhängigkeit:** Zuerst muss der normale Ablauf klar sein.

### 9.3 Nacht-Probe vor dem Spiel

Das gewählte Setup einmal als Vorschau durchgehen: Wer wacht wann auf, welche Zusatzentscheidungen entstehen, welche Materialien fehlen?

**Wert:** Problematische Kombinationen werden vor Spielbeginn sichtbar.

### 9.4 Unterbrechungszettel

Nach Pause, Display-Sperre oder App-Wechsel steht eine kurze Zusammenfassung bereit: „Nacht 2, Orakel. Ziel gewählt, Ergebnis noch nicht gezeigt.“

**Wert:** Der Spielleiter muss sich nicht aus dem Protokoll zurückarbeiten.

### 9.5 Aufmerksamkeitsliste

Eine kleine, priorisierte Liste weist auf konkrete offene Punkte hin, beispielsweise „Zwei Totenkarten verfügbar“ oder „Ein Effekt endet am Morgen“.

**Wert:** Weniger Gedächtnislast.  
**Risiko:** Zu viele Hinweise werden ignoriert. Deshalb nur aktuelle und handlungsrelevante Punkte.

### 9.6 Erklärbare Set-Vorschläge

Statt „perfekt balanciert“: „Dieses Set hat wenige Nachtaktionen, eine Informationsrolle und keine Wiederbelebung.“

**Wert:** Spielleiter verstehen die Auswahl.  
**Grenze:** Reale Balance erst aus dokumentierten Testpartien ableiten.

### 9.7 Kontrollierter Szenario-Modus

Vorbereitete Beispielstände für Regelunterricht und reproduzierbare Fehlermeldungen.

**Wert:** Dieselbe Infrastruktur hilft Onboarding, Tests und Support.

### 9.8 Spätere Erweiterungen

Öffentlicher Zweitbildschirm, gemeinsame Moderation auf zwei Geräten, eigene Akte, Community-Sets, Druck-/Kartenbegleitung, Kampagnenchronik und optionale atmosphärische Audiopakete.

Diese Ideen gehören nach die Kernqualität. Ein KI-Assistent kann später Regeltexte auffindbar machen; spielentscheidende Regeln sollten nicht von generierten Antworten abhängen.

---

## 10. Technischer Zielzustand ohne kompletten Neubau

### 10.1 Zuständigkeiten schrittweise klarziehen

| Bereich | Aufgabe |
|---|---|
| Spielregeln | Aus Aktion und Zustand das Ergebnis bestimmen |
| Aktionsablauf | Offene Auswahl, Prüfung, Bestätigung und Reaktionen verwalten |
| Speicherung | Versionierte, gültige Zustände sichern und wiederherstellen |
| Oberfläche | Zustand anzeigen und Nutzerabsichten weitergeben |
| Inhalte | Rollen, Regeltexte, Nachtpositionen, Übersetzungen und Assets zuordnen |

Der bestehende Adapter bleibt zunächst erhalten. Neue strukturierte Schnittstellen werden jeweils an den konkret bearbeiteten Abläufen eingeführt. Kein abstraktes Universal-Regelsystem und kein kompletter Engine-Umbau vor dem ersten Fortschritt.

### 10.2 Eine Aktion ist eine abgeschlossene Einheit

Beispiel Frankenstein:

1. Fähigkeit beginnen.
2. Verstorbenen wählen.
3. Neue Rolle wählen.
4. Auswirkungen prüfen und zeigen.
5. Erst bei Bestätigung Wiederbelebung, Rolle, Fraktion, Verbrauch und Protokolleintrag gemeinsam anwenden.
6. Sicher speichern.
7. Bei Abbruch vor Schritt 5 bleibt der Ausgangszustand erhalten.

Dasselbe Prinzip gilt für Hinrichtung, Konvertierung und Totenkarteneinsatz.

### 10.3 Verlässliche Speicherung

Für den zunächst kleinen lokalen Datenbestand zählt ein getesteter Speichervertrag mehr als die Wahl einer aufwendigen Datenbank.

Mindestumfang:

- Rundendatei mit Schema- und Regelversion.
- Stabile Runden- und Spieler-IDs.
- Letzter gültiger Speicherstand und überprüfbare Sicherungspunkte.
- Sichtbarer Speicherfehler mit Exportmöglichkeit.
- Validierter Import, ohne den aktuellen Stand vor erfolgreicher Prüfung zu überschreiben.
- Dokumentierter Umfang von Undo: Zustand, offene Effekte, Verbrauch und Protokollkorrektur.
- Keine Behauptung erfolgreicher Speicherung vor tatsächlichem Erfolg.
- Migration mit Testständen aus alten Versionen.
- Aktive Runde und gespeicherte Gruppen getrennt verwalten.

IndexedDB ist bei mehreren Runden und Historien ein plausibler nächster Schritt. Ein Write-only-Mirror ist kein Ersatz für einen getesteten Restore-Pfad. Keine Cloud-Abhängigkeit für das Leiten vor Ort.

### 10.4 Rollenqualität

Pro Rolle ein verbindlicher Eintrag mit:

- stabiler ID, Anzeigenamen, Fraktion und Regelversion;
- Fähigkeit, Nachtposition, Einmal-/Mehrfachnutzung;
- erlaubten Zielen und Ausnahmen;
- erzeugten Effekten und deren Lebensdauer;
- Todes-, Wiederbelebungs- und Rollenwechselverhalten;
- Siegbedingung, sofern relevant;
- Teststatus und bekannten manuellen Entscheidungen.

Zunächst die existierenden Daten konsistent machen. Website, Karte und App dürfen keine voneinander abweichenden Fähigkeitsversprechen liefern.

### 10.5 Auslieferung

React-Build und benötigte lokale Inhalte werden das gemeinsame freigegebene Artefakt. Browser-PWA und Capacitor nutzen denselben fachlichen Stand. Updates dürfen keine laufende Runde durch unbemerkte Regel- oder Datenänderungen verändern.

Offline umfasst Start, Setup, Rollenbilder, Regeln, Nacht-/Tagesablauf, Speichern und Wiederaufnahme. Optionale Inhalte dürfen separat laden, müssen dann aber klar als optional erkennbar sein. Die technische Unterscheidung zwischen Manifest, Cache und Offline-Bereitstellung beschreibt [web.dev: Assets and data](https://web.dev/learn/pwa/assets-and-data).

---

## 11. Ausgearbeitete Roadmap

Die Phasen sind nach Abhängigkeiten geordnet. Aufwand sind **grobe Planungsbereiche in konzentrierten Entwicklungstagen**, keine Zusage. Ein Tag bedeutet etwa sechs Stunden produktive Implementierung und Prüfung. Ungeprüfte Rollenfehler können den Aufwand erheblich erhöhen.

### Phase 0: Verbindliche Grundlage

**Aufwand:** 3–5 Tage.  
**Ziel:** Jeder weiß, welcher Stand entwickelt und ausgeliefert wird.

Arbeitspakete:

- Jüngeren Grimmhain-Stand mit älterer Git-Basis vergleichen und kanonisch übernehmen.
- Altstände unverändert als Referenz sichern.
- Aktuelle Start-, Test- und Build-Kommandos dokumentieren.
- Web-/Capacitor-Auslieferung auf identischen Zielstand planen und herstellen.
- Unterstützte Tabletgrößen, Spielerzahlen und erste Rollenmenge festlegen.
- Alten Website-first-Plan durch diese App-first-Priorisierung ersetzen.
- Eine reproduzierbare Testrunde als Ausgangspunkt definieren.

**Abnahme:** Frische Arbeitskopie startet reproduzierbar. Web und App-Bündel zeigen dieselbe Versionskennung und denselben Ablauf. Kein unklarer zweiter Entwicklungsordner.

### Phase 1: Vertrauen in Spielzustand und Regeln

**Aufwand:** 12–20 Tage.  
**Abhängigkeit:** Phase 0.  
**Ziel:** Kein stiller Verlust und keine halbfertigen Regelaktionen.

Arbeitspakete:

- Frankenstein-Auswahl und vorzeitige Wiederbelebung korrigieren.
- Aktionsabbruch, Doppeltippen und Phasenwechsel bei offenen Reaktionen absichern.
- Speichervertrag, Fehleranzeige, Sicherungspunkte und validierten Import/Export umsetzen.
- Mehrstufiges Rückgängig mit nachvollziehbarer Wirkung.
- Erste ausführbare Tests für Schutz, Tod, Kettenreaktion, Sieg, Wiederbelebung und Reload.
- Wesentliche Spielfolgen aus bloßen Speicheraufrufen lösen.
- Offline-Start und sichere Updategrenze herstellen.
- Bei Unklarheit eine dokumentierte Spielleiterentscheidung verlangen.

**Abnahme:** Repräsentative Runde übersteht Neustart und Offline-Wiederaufnahme. Abgebrochene Aktionen verändern nichts. Wiederholte Bestätigung führt nur einmal aus. Ein kaputter Import zerstört keinen laufenden Stand. Kritische Szenarien laufen automatisiert.

### Phase 2: Tablet-Cockpit

**Aufwand:** 10–16 Tage.  
**Abhängigkeit:** Phase 1 für verbindliche Aktionszustände; Layoutentwürfe können früher beginnen.  
**Ziel:** Auf einen Blick erkennen, wer betroffen ist und was als Nächstes zu tun ist.

Arbeitspakete:

- Oberen Rahmen verkleinern und Aktionspanel adaptiv gestalten.
- Layout für 12, 18 und 24 Sitze prüfen; Namen und Marker in Kollisionsprüfung aufnehmen.
- Sitznummern, eindeutige Auswahl und konsistente Statusanzeige.
- Lesbare Schriftgrößen, Kontrast und große Trefferflächen.
- Linke/rechte Panelposition und reduzierte Bewegung.
- Sichere Portrait-/Resize-Behandlung ohne Verlust einer offenen Aktion.
- Namenseingabe mit üblichen Listenformaten.
- Klar beschriftete Navigation und dialogbasierte Aktionen statt technischer Begriffe wie „Hard-Reset“.

**Abnahme:** Bei den definierten Tabletgrößen keine überlappenden Namen oder verdeckten Pflichtaktionen. Die Identität jedes Ziels ist eindeutig. Bedienung klappt mit Fingern auf echten Geräten und bei geöffneter Bildschirmtastatur.

### Phase 3: Vollständiger Spielleiterabend

**Aufwand:** 12–20 Tage.  
**Abhängigkeit:** Phasen 1–2.  
**Ziel:** Durchgängiger Ablauf mit weniger Gedächtnislast.

Arbeitspakete:

- Vorbereitungscheck und nachvollziehbare Set-Vorschläge.
- Geführter Nachtmodus mit kurzen Moderationstexten.
- Kontextbezogene Erinnerungen und Effektlaufzeiten.
- Morgenprüfung mit öffentlichen und privaten Informationen.
- Tagesablauf mit Diskussionstimer, Nominierung, Abstimmung und Abschluss.
- Totenkarten und reaktive Fähigkeiten in derselben Aktionsführung.
- Spieleranzeige, Schutzschirm und kontrollierte Rückkehr.
- Unterbrechungszusammenfassung und schnelle neue Runde.

**Abnahme:** Eine komplette Standardpartie lässt sich ohne Entwicklerhilfe führen. In jeder Phase ist die nächste notwendige Handlung erkennbar. Öffentliche Ansichten zeigen keine privaten Informationen.

### Phase 4: Inhaltliche Abnahme aller vorgesehenen Rollen

**Aufwand:** zunächst 10–20 Tage; nach Erstinventur neu schätzen.  
**Abhängigkeit:** strukturierte Aktionen und Tests aus Phase 1.  
**Ziel:** Der veröffentlichte Funktionsumfang entspricht dem tatsächlichen Qualitätsstand.

Arbeitspakete:

- Rollenmatrix für alle 72 vorhandenen Definitionen erstellen.
- Einen kuratierten Akt-I-Kern zuerst vollständig abnehmen.
- Danach übrige Akte und Totenkarten systematisch freigeben.
- Kritische Kombinationen gezielt testen: Schutz/Tod, Wiederbelebung, Fraktionswechsel, Reaktionen, Solo-Sieg.
- DE-/EN-Regeltexte, Karten und App-Abbildungen abgleichen.
- Spielleiterentscheidungen und technische Grenzen offen dokumentieren.
- Für nicht abgenommene Rollen keine vollständige Automation versprechen.

**Abnahme:** Jede als unterstützt veröffentlichte Rolle hat dokumentierte Regeln, Normalfall- und Randfalltests. Es existiert eine geprüfte Abdeckung der wichtigsten Kombinationen.

**Umfangsentscheidung:** Eine öffentliche erste Version mit kleinerem, vollständig geprüftem Rollenangebot ist sinnvoller als eine vollständige Automation aller 72 Rollen ohne Nachweis. Falls alle 72 zum ersten Release Pflicht sind, wird diese Phase vollständig vor Release abgeschlossen; der Termin verschiebt sich entsprechend.

### Phase 5: Pilotbetrieb und Veröffentlichung

**Aufwand:** 8–15 Entwicklungstage plus 3–4 Kalenderwochen reale Spielabende.  
**Abhängigkeit:** Kernstrecke und veröffentlichter Rollenumfang abgenommen.  
**Ziel:** Qualität außerhalb der eigenen Testumgebung nachweisen.

Arbeitspakete:

- Pilot mit mindestens fünf unabhängigen Spielleitern.
- Mindestens zehn vollständig beobachtete oder strukturiert dokumentierte Runden.
- Mindestens ein iPad und ein Android-Tablet, einschließlich schwächerem Zielgerät.
- Neue Spielleiter ohne persönliche Einführung testen lassen.
- Fehler nach tatsächlicher Auswirkung priorisieren.
- Offline, Sperren, App-Wechsel, Rückkehr und lange Laufzeit prüfen.
- Native Pakete und PWA separat abnehmen.
- Kurze Hilfe, bekannte Grenzen, Supportweg und Versionshinweise fertigstellen.
- Kleine ehrliche Website mit Demo, unterstütztem Umfang und funktionierender Warteliste.

**Abnahme:** Keine offenen Fehler mit Spielstandsverlust, Geheimnisoffenlegung oder falscher spielentscheidender Auflösung im freigegebenen Umfang. Die definierten Gerätetests und Pilotrunden bestehen.

### Phase 6: Ausbau anhand der Nutzung

**Aufwand:** erst nach Pilotdaten schätzen.

Mögliche Reihenfolge:

1. Zusätzliche Komfortfunktionen und weitere kuratierte Sets.
2. Erweiterte Chronik und öffentlicher Zweitbildschirm.
3. Eigene Akte und Inhaltswerkzeuge.
4. Gemeinsame Moderation mit klaren Konfliktregeln.
5. Desktop-/Steam-Paket.
6. Online-Spiel nur als eigenständige Produktentscheidung.

**Abnahme:** Jede größere Erweiterung löst ein wiederholt beobachtetes Nutzerproblem und verschlechtert die lokale Kernstrecke nicht.

### Zeitliche Einordnung bis März 2027

Die alte Roadmap nennt März 2027. Vom Analysedatum aus bleiben ungefähr fünfeinhalb bis sechseinhalb Monate, abhängig vom konkreten Märztermin.

Die Phasen 0–5 ergeben grob **55–96 Entwicklungstage plus reale Testabende**, vor unbekannten großen Regelproblemen. Das ist eine erste Orientierung, keine belastbare Lieferprognose. Bei geringer wöchentlicher Kapazität muss der veröffentlichte Umfang kleiner werden.

Mögliche Meilensteine, falls die verfügbare Zeit reicht:

| Zeitraum | Ergebnis |
|---|---|
| Rest September | Hauptstand festgelegt, reproduzierbare Basis, Rollen-/Gerätescope |
| Oktober | Kritische Aktionen, Speicher-/Restore-Pfad, erste Szenariotests |
| November | Tablet-Cockpit und klare Nachtführung |
| Dezember | Tagesablauf, Geheimhaltung, erste externe Pilotabende |
| Januar | Inhaltsabnahme und echte Gerätetests |
| Februar | Fehlerbereinigung, Pakete, Hilfe und schlanke Launch-Seite |
| März | Veröffentlichung nur bei erfüllten Qualitätskriterien |

Wenn ein Gate scheitert, optionale Features verschieben. Speicherqualität, Geheimhaltung und Regelkorrektheit bleiben Pflicht.

---

## 12. Messbare Definition von „hochwertig“

Diese Zahlen sind vorgeschlagene Abnahmekriterien, keine bereits gemessenen Eigenschaften.

| Bereich | Ziel | Prüfung |
|---|---|---|
| Fortsetzen | Letzte bestätigte Aktion nach Neustart vollständig vorhanden | Prozess beenden, neu starten, Zustand vergleichen |
| Abbruch | Kein Teilzustand nach Abbruch einer mehrstufigen Aktion | Vorher-/Nachhervergleich |
| Undo | Mehrere bestätigte Aktionen samt Folgeeffekten korrekt zurücknehmen | Szenarioprüfung einschließlich Sieg und Wiederbelebung |
| Offline | Nach abgeschlossener Installation erster Start einer neuen Runde und Fortsetzung ohne Netz | Flugmodus auf beiden Zielplattformen |
| Geheimhaltung | Keine privaten Rollen/Notizen in Spieleransicht oder freigegebenem Export | Übergänge, Zurück, Rotation und App-Wechsel testen |
| Zielwahl | Mindestens 95 % korrekte Erstwahl bei vorgegebenen Aufgaben | Mit externen Spielleitern messen |
| Vorbereitung | Gespeicherte Gruppe und Set in unter zwei Minuten startbereit | Ohne Erklärung durchführen lassen |
| Wiederaufnahme | Spielleiter erkennt den nächsten Schritt in höchstens zehn Sekunden | Unterbrechungsszenario |
| Interaktion | Typische lokale Aktionen zeigen innerhalb von 100 ms eine Rückmeldung | Auf dem schwächsten Zielgerät messen |
| Layout | Keine Namensüberlagerungen bei 12/18/24 Spielern auf freigegebenen Größen | Mit langen und doppelten Namen prüfen |
| Bedienflächen | Meist mindestens 48 × 48 CSS-Pixel; nie allein kleine Icons als Pflichtweg | Größen und reale Fingernutzung prüfen |
| Lesbarkeit | Kontrast, Schrift und Statuscodes anhand WCAG 2.2 prüfen | Automatische Prüfung plus visuelle Geräteabnahme |
| Pilot | Mindestens 4 von 5 Spielleitern möchten die App erneut einsetzen | Rückfrage nach tatsächlicher Runde |
| Stabilität | Keine kritischen Fehler in den letzten zehn Pilotpartien | Fehlerprotokoll, keine bloße Erinnerung |

Die 48-Pixel-Fläche ist ein eigenes Komfortziel. W3C unterscheidet 24 × 24 CSS-Pixel mit Ausnahmen als Mindestkriterium und 44 × 44 beim erweiterten Kriterium. Siehe [W3C Mindestzielgröße](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum/) und [W3C erweiterte Zielgröße](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced/).

Zehn fehlerfreie Partien sind ein Pilot-Gate, keine statistische Garantie für Fehlerfreiheit.

---

## 13. Konkreter Testplan

### Automatisierte Szenarien

1. Schutz verhindert passenden Tod; Schutzverbrauch stimmt.
2. Tod löst erforderliche Folgeaktion genau einmal aus.
3. Zwei Folgeeffekte werden in der definierten Reihenfolge abgearbeitet.
4. Wiederbelebung plus Rollenwahl ist vollständig oder findet gar nicht statt.
5. Rollen-/Fraktionswechsel verändert korrekte Sieg- und Zielprüfungen.
6. Nachtwechsel setzt temporäre Effekte zurück, erhält dauerhafte.
7. Bereits erledigte Nachtaktion wird nicht durch erneutes Tippen doppelt ausgeführt.
8. Sieg wird korrekt erkannt; Korrektur/Undo stellt eine spielbare Runde wieder her.
9. Speichern/Laden erhält den fachlichen Zustand.
10. Beschädigter/inkompatibler Import bleibt ohne Einfluss auf die aktive Runde.
11. Geheimnisfreie Anzeige/Export enthält nur erlaubte Felder.
12. Sprache verändert Texte, aber keine Rollen-IDs oder Spielentscheidungen.

### UI- und Gerätetestmatrix

- 1024 × 768 und 1280 × 800 als feste Ausgangsgrößen, zusätzlich reale Gerätegrößen.
- 12, 18 und 24 Spieler; unterstützte kleinere Gruppen ergänzen.
- Kurze, lange und doppelte Namen.
- Deutsch und Englisch.
- Nachtaktion, Mehrfachwahl, Tagesabstimmung und mehrere Todesreaktionen.
- Geöffnete Tastatur, Rotation, App im Hintergrund, Gerätesperre.
- Kein Netz, Neustart, beschädigter Speicherstand, Update zwischen zwei Runden.
- Mehrstündige Nutzung auf schwächerer Hardware, mit und ohne Effekte/Audio.

### Rollenmatrix

Je Rolle dokumentieren: Daten vorhanden, Aktion erreichbar, erlaubte Ziele, Abbruch, Bestätigung, Wirkung, Verbrauch, Reload, Undo, Texte, mindestens eine kritische Kombination. Status: ungeprüft / manuell unterstützt / automatisiert geprüft / gesperrt wegen Fehler.

Alle Paarungen und Reihenfolgen vollständig durchzuprobieren ist bei 72 Rollen nicht praktikabel. Zuerst Risikogruppen und gemeinsame Mechaniken abdecken, dann bekannte problematische Kombinationen und echte Fehlermeldungen ergänzen.

---

## 14. Erfolg als Produkt

### Zuerst nachweisen

Grimmhain spart dem Spielleiter Aufmerksamkeit und verhindert vermeidbare Fehler. Erfolg misst sich zuerst daran, ob Menschen freiwillig eine zweite Runde damit leiten.

### Pilotgruppen

- Neue Spielleiter: Verstehen sie ohne Hilfe den Ablauf?
- Erfahrene Spielleiter: Sind Standardaktionen schnell genug und Korrekturen möglich?
- Große Gruppen: Bleibt das Brett übersichtlich?
- Unterschiedliche Tablets: Funktioniert es außerhalb des Entwicklergeräts?

### Was beobachtet werden sollte

- Wo unterbricht der Spielleiter die Moderation, um die App zu verstehen?
- Wie oft wird ein falscher Spieler angetippt?
- Welche Hinweise werden übersehen?
- Welche Aktionen werden abgebrochen oder korrigiert?
- Welche Regeln müssen extern nachgeschlagen werden?
- Bleibt die Gruppe im Spielfluss?

Diese Daten können zunächst manuell und anonymisiert erhoben werden. Ein Analytics-System ist keine Voraussetzung.

### Schlanke Veröffentlichung

- Echte Screenshots und eine kurze Aufnahme einer tatsächlichen Runde.
- Klarer unterstützter Umfang: Geräte, Spielerzahlen, Rollen, Offlineverhalten.
- Funktionierende Warteliste statt Formularattrappe.
- Ein kurzer Einstieg und eine geführte Demonstration.
- Verständlicher Feedback-/Fehlerkanal.
- Keine Zeit in ein großes Forum investieren, bevor regelmäßige Nutzer da sind.

### Monetarisierung als spätere Hypothese

Ein kostenloser Probelauf plus einmaliger Kauf könnte zum lokalen Assistenten passen. Inhalts- oder Audiopakete wären eine weitere Hypothese. Ein Abo braucht einen erkennbar fortlaufenden Nutzen. Konkrete Preise sollten erst aus Nutzerinterviews, Kosten und Zahlungsbereitschaft abgeleitet werden.

Kickstarter und physische Karten können die Welt erweitern. Sie ersetzen keine geprüfte App. Produktionsumfang und Finanzierung gehören in eine getrennte Planung, sobald Produkt und Nachfrage belastbarer sind.

---

## 15. Was vorerst nicht auf die Hauptroadmap gehört

- Vollständiger Engine-Neubau.
- Wechsel zu einer anderen Rendering-Technik allein für einen „Premium“-Eindruck.
- Online-Multiplayer, Lobbys und Accounts.
- Gleichzeitiger Steam-, Smartphone- und Tablet-Vollumfang.
- Weitere Rollen ohne Abnahme der vorhandenen.
- Umfangreiche Shop-/Forum-Entwicklung vor dem Pilotbetrieb.
- Automatisch generierte spielentscheidende KI-Regeln.
- Mehr Animation, bevor Namen, Ziele und Zustände eindeutig sind.

Das sind Verschiebungen, keine dauerhaften Verbote. Der Zweck ist ein fertiges, vertrauenswürdiges Kernprodukt.

---

## 16. Die ersten zehn konkreten Tickets

| Reihenfolge | Ticket | Fertig, wenn |
|---|---|---|
| 1 | Hauptstand und Versionsmanifest festlegen | Eine Quelle und ein dokumentierter Vergleich zu den Altständen existieren |
| 2 | Web- und Capacitor-Artefakt vereinheitlichen | Beide nutzen dieselbe freigegebene Oberfläche und Regelversion |
| 3 | Drei kritische Szenarien ausführbar testen | Tod/Schutz, Wiederbelebung und Phasenwechsel sind reproduzierbar |
| 4 | Frankenstein als vollständige Aktion reparieren | Rollenwahl bewusst möglich; Abbruch und fehlende Optionen ändern nichts |
| 5 | Speicherfehler und beschädigte Daten sichtbar behandeln | Kein stiller Neustart über einen beschädigten Stand |
| 6 | Restore und Phasen-Sicherungspunkte | Fortsetzung nach Neustart und Rückkehr zum letzten Phasenpunkt funktionieren |
| 7 | Offline-Start und Updategrenze | Neue und gespeicherte Runde starten ohne Netz nach Installation |
| 8 | Namenseingabe verbessern | Komma-/Zeilenlisten und Leerzeilen werden verständlich verarbeitet |
| 9 | 1024 × 768-Layout korrigieren | Zwölf Testspieler haben eindeutig zugeordnete Namen; 18/24 werden anschließend geprüft |
| 10 | Erste externe Probe mit kuratiertem Set | Ein fremder Spielleiter schafft die Kernstrecke; Reibungspunkte sind dokumentiert |

**Empfohlener erster Meilenstein:** Eine echte Runde mit kuratiertem Rollenangebot auf einem Tablet komplett offline leiten, gefahrlos korrigieren und nach Unterbrechung fortsetzen. Daran lässt sich Fortschritt besser messen als an der Anzahl neuer Oberflächen oder Assets.

---

## 17. Aktuelle Prüfergebnisse

| Prüfung | Ergebnis am 15.09.2026 | Aussagekraft |
|---|---|---|
| `node tests/smoke.js` im jüngeren Grimmhain-Stand | `smoke: OK` | Statische Codeinvarianten |
| `node tools/compare-i18n.js` | `missing_in_de 0`, `missing_in_en 0` | Gleichheit der geprüften Dictionary-Schlüssel |
| Lokales TypeScript `tsc --noEmit -p app/tsconfig.json` | Durchgelaufen, keine gemeldeten Fehler | Typprüfung; kein Produktions- oder Gerätetest |
| 35 ausgewählte Website-Quelldateien gegen Kopie | Identisch | Kein vollständiger Ordner-/Assetvergleich |
| 49 ausgewählte BotC-Quelldateien gegen jüngere Referenz | 36 gleich, 13 abweichend | Gerichteter Vergleich; zusätzliche Dateien separat vorhanden |
| Fünf zentrale Runtime-Kopien gegen Grimmhain-Originale | Identisch | Begrenzter Synchronisationsnachweis |
| Namensliste mit Zeilenumbrüchen | 1 / 12 erkannt | Aktuelle UX-Schwäche reproduziert |
| Dieselben Namen kommagetrennt | 12 / 12 erkannt | Erwarteter aktueller Eingabepfad funktioniert |
| Rollenwahl und zufällige Verteilung | React-Spielbrett erreicht | Setup-zu-Spiel-Übergang funktioniert in dieser Probe |
| Loki starten | Liebe-/Hass-Auswahl sichtbar | Entscheidungsschritt erreicht; keine vollständige Rollenabnahme |
| 1024 × 768 mit zwölf Spielern | Enge/überlagerte Namenszuordnung sichtbar | Tablet-Layout benötigt Überarbeitung |

Lokaler Vorschauprozess und temporärer Browsertab wurden nach der Prüfung beendet.

---

## 18. Quellen im Projekt

Die folgenden Dateien bilden die wichtigsten Belege. Historische Dokumente sind ausdrücklich keine aktuelle Freigabe.

- [Grimmhain: Root-Build und Tests](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/package.json>)
- [Grimmhain: Web-Deployment](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/vercel.json>)
- [Grimmhain: Capacitor-Ziel](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/capacitor.config.ts>)
- [Grimmhain: Legacy-Auslieferung](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/tools/copy-dist.js>)
- [Grimmhain: fehlender Offline-Cache](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/sw.js>)
- [Grimmhain: Speicherung und Undo](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/js/core/state.js:77>)
- [Grimmhain: Frankenstein-Aktion](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/js/core/abilities-roles-chunk.js:54>)
- [Grimmhain: Dialog-Mirror](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/app/src/adapter/legacy/domMirror.ts>)
- [Grimmhain: Aktions- und Nachtadapter](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/app/src/adapter/legacy/legacyAdapter.ts:145>)
- [Grimmhain: React-Spielansicht](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/app/src/screens/GameScreen.tsx>)
- [Grimmhain: Tablet-Grenzen](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/app/src/components/OrientationGate.tsx>)
- [Grimmhain: Namensparser](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/setup.html:784>)
- [Grimmhain: Smoke-Test](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/tests/smoke.js>)
- [Grimmhain: historische Stabilisierung](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/PROGRESS.md>)
- [Grimmhain: historischer Sonderrollenbericht](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/SPECIAL-ROLE-FLOW-REPORT.md:49>)
- [Grimmhain: historische Tablet-Probleme](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Spiel-main/Grimmhain-Spiel-main/TABLET-UX-REPORT.md>)
- [BotC: Tagesablauf und Spielleiteraktionen](<C:/Users/Marku/Desktop/Blood on the Clocktower/Botc-react/app/src/adapter/legacy/legacyAdapter.ts:634>)
- [BotC: Tablet-Anzeigemodi](<C:/Users/Marku/Desktop/Blood on the Clocktower/Botc-react/app/src/display/displayMode.ts>)
- [BotC: lokale Raum-IDs](<C:/Users/Marku/Desktop/Blood on the Clocktower/Botc-react/app/src/room/roomId.ts>)
- [BotC: Datenbankspiegel ohne Restore](<C:/Users/Marku/Desktop/Blood on the Clocktower/Botc-react/js/core/idb-mirror.js>)
- [BotC: private Informationsansicht](<C:/Users/Marku/Desktop/Blood on the Clocktower/Botc - App/private-info-overlay.js>)
- [Neuere Website: Newsletter-Platzhalter](<C:/Users/Marku/Desktop/Grimmhain/NEw Grimmhain/src/components/sections/NewsletterSection.tsx>)
- [Grimmhain: Asset-Produktionsstand](<C:/Users/Marku/Desktop/Grimmhain/Grimmhain-Werwolf/Grimmhain Assets/production-pilot/PILOT-STATUS.md>)

