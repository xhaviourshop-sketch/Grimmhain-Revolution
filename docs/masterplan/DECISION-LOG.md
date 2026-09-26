# Grimmhain Revolution · Decision Log

**Status:** Vom Product Owner am 26. September 2026 bestätigt. Neuere datierte Einträge ersetzen ältere Entscheidungen ausdrücklich.

## Produkt

- Tablet ist das private Hauptgerät des Spielleiters; Querformat ist verbindlich.
- Grimmhain unterstützt 6 bis 24 Personen in einem festen Sitzkreis.
- Diskussion, Nominierung und Abstimmung bleiben physisch.
- Zielgruppe umfasst Einsteiger und erfahrene Spielleiter; geführter und Expertenmodus.
- Zielplattformen sind iPadOS, Android-Tablets und Windows; Geräte ungefähr ab 2020 werden angestrebt, endgültige Mindestwerte folgen aus Messungen.
- Deutsch und Englisch ab Version 1.0; weitere Sprachen technisch vorbereitet.
- Einmalkauf; spätere Inhalts- oder Atmosphärenpakete möglich; keine Pay-to-win-Mechanik.

## Regeln

- Jede Partie enthält Dorf, Werwölfe und Einzelsiegrollen; Name der dritten Gruppe folgt später.
- Bestehende Rollen werden einzeln bewertet; Text und Legacy-Code sind keine automatische Autorität.
- Bei Widerspruch entscheidet der Product Owner anhand Migrationsmatrix und Empfehlung.
- Offensichtliche Bugs werden nicht als Referenzverhalten portiert.
- Version 1.0 zielt auf 20 bis 30 vollständig geprüfte Rollen.
- Nominierung speichert Nominierende und Nominierte. Jede Person darf standardmäßig einmal nominieren und einmal nominiert werden; Regeln können dies ändern.
- Stimmen werden nicht digital gespeichert. Der Spielleiter zählt physisch und bestätigt anschließend Lynch/Kill auf der betreffenden Person.
- Todesursache, Quelle, Ziel und Zeitpunkt bleiben getrennt; Lynch, Nachtangriff, Gift, Fluch, Opfer, Kette, Wiederbelebung, Schutz und Verbannung sind unterscheidbar.
- Mögliche Siege werden erkannt, aber erst durch den Spielleiter bestätigt.
- Spielleiter darf jeden Zustand überschreiben; Warnung und Protokolleintrag sind Pflicht.
- Falsche Information ist ein modellierter Spieleffekt; Wahrheit, ermittelte und gezeigte Information bleiben getrennt.

## Personen, Sitze und Darstellung

- Zustände haften an stabiler Personen-ID, nicht am Sitzplatz.
- Sitzplätze lassen sich per Drag-and-drop tauschen.
- Tagsüber werden nur öffentliche Informationen gezeigt.
- Nachts wechselt das Cockpit zu dunkler Dorfansicht mit Vollmond, Nebel, Licht und Nachtatmosphäre.
- Ohne Smartphone zeigt eine abgesicherte Tablet-Karte genau die relevante Information oder Auswahl.
- Eigene Fotos sind optional, lokal und löschbar; festes Charakterset ist immer verfügbar.

## Smartphone und öffentlicher Bildschirm

- Smartphone ist optional und dient Rolle, Nachtaktion und Lexikon, nicht Diskussion oder Abstimmung.
- Eintritt über Sitzungs-QR-Code und sichere persönliche Zuordnung; Spielleiter bestätigt Geräte.
- Tagsüber neutrale Dorfbewohneransicht; eigene Rolle erscheint nur nach bewusster Aktion.
- Tablet bleibt autoritativ und vollständig funktionsfähig, wenn Netzwerk oder Client ausfällt.
- Öffentlicher Browserclient zeigt Sitzkreis, öffentliche Zustände, Phase, Timer, Ansagen, freigegebene Rollen, Historie und Atmosphäre.
- Öffentliche Projektion erhält niemals geheime Daten. HDMI/Spiegelung ist nur über eine sichere öffentliche Ansicht zulässig.
- Lokales WLAN oder Hotspot; kein Internetzwang.

## Technik und Produktion

- Godot 4.x und GDScript; Projekt im Unterordner `godot/`.
- Legacy-Web-App bleibt archivierte Referenz und erhält höchstens kritische Fixes bis zum MVP-Go.
- Domain-Core ohne Szenen; Commands erzeugen Events; offene Prompts sind Teil des Spielstands.
- Gespeicherter Seed, versioniertes JSON, Replay, Undo/Redo und Crash-Recovery sind Kernanforderungen.
- Schlanke Webclients; Tablet ist einzige Zustandsautorität.
- Online-Remote-Spiel wird architektonisch berücksichtigt, aber erst nach Version 1.0 spezifiziert und gebaut.
- Ein Branch pro Phase; Weiterarbeit erst nach Tests, Gerätebuild, manueller Prüfung und Dokumentation.

## Gestaltung, Audio und Assets

- Realistische Gothic-Fantasy-Welt kombiniert mit klaren stilisierten Symbolen.
- 2.5D statt vollständig freier 3D-Welt.
- Ereigniseffekte sind kurz, überspringbar und besitzen Reduced-Motion-Alternative.
- Zielrichtung ab 12, keine drastische Gewaltdarstellung.
- Adaptive Musik und Ambiente; zunächst eine DE- und eine EN-Erzählerstimme.
- KI-Assets dürfen nach dokumentierter Herkunft, kommerzieller Lizenzprüfung, Qualitätsprüfung und Product-Owner-Freigabe final verwendet werden.
- Budget bis 500 €, primär nach erfolgreichem Vertical Slice.

## Barrierefreiheit und Daten

- Große Touch-Ziele, skalierbare Schrift, hoher Kontrast, farbunabhängige Symbole, Untertitel, getrennte Lautstärken, reduzierte Bewegung und keine Pflicht zu präzisen Gesten.
- Spieler- und Bilddaten bleiben zunächst lokal; Cloud erst nach Version 1.0.
- Lokale Historie enthält Gewinner, Rollen, Dauer, Runden und Ereigniszusammenfassung.

## Veröffentlichung

- Geschlossener Pilot zuerst; danach Entscheidung Early Access oder Version 1.0.
- Direkter APK-/Windows-Vertrieb sowie Apple-/Google-Stores; Steam folgt als Desktopausbau.
- Preis wird nach Nutzertests und Marktvergleich festgelegt.
- Verpflichtende IP-, Marken- und Lizenzprüfung vor kommerziellem Release.

## Noch zu benennende, nicht blockierende Punkte

- endgültiger Name für die Gruppe der Einzelsiegrollen,
- konkrete iPad-Generation und Betriebssystemstände,
- schwaches Android-Referenztablet,
- endgültiger Produktpreis,
- finale Auswahl der 20 bis 30 Rollen nach Regelregister.

## Vertical Slice · entschiedene Detailfragen

### DR-01 · Technische Rollen-IDs · 26. September 2026

Stabile technische Rollen-IDs verwenden deutsches ASCII-`kebab-case`, beispielsweise `dorfbewohner`, `werwolf` und `das-orakel`. Anzeigenamen bleiben vollständig lokalisiert.

### DR-03 · Nominierungsregeln · 26. September 2026

Nominierungsrechte werden pro Tag zurückgesetzt. Nur lebende Personen dürfen nominieren oder nominiert werden. Standardmäßig darf jede Person einmal pro Tag nominieren und einmal pro Tag nominiert werden. Eine normale Hinrichtung ist nur für eine an diesem Tag nominierte Person zulässig. Abweichungen sind ausschließlich als Spielleiter-Übersteuerung mit Warnung, Begründung und Protokolleintrag möglich.

### Core-Slice · Rollenanzahl der Grundrollen · 26. September 2026

Der Core-Slice unterstützt jede Personenzahl von 6 bis 24 allein mit `dorfbewohner` und `werwolf`. Für diese beiden Rollen gilt keine Obergrenze; die Legacy-Grenzen aus `setup.html` (Werwolf 5, Dorfbewohner 10) werden nicht übernommen. Pflicht bleiben 6 bis 24 Personen sowie mindestens ein Werwolf und ein Dorfbewohner. Die Rollenkomposition späterer Partien wird nicht im Rollenkatalog fest verdrahtet; einzelne spätere Rollen dürfen eine eigene Obergrenze erhalten.

## Vertical Slice · Rollen- und Auflösungsentscheidungen · 26. September 2026

- **DR-02:** Treffen mehrere Siegbedingungen gleichzeitig zu, entscheidet der Spielleiter. Leben keine Personen mehr, gibt es keinen automatischen Gewinner; der Spielleiter erklärt das Ergebnis.
- **DR-04:** Der Name einer gestorbenen Person ist öffentlich. Im Setup legt `Rolle beim Tod aufdecken: Ja/Nein` fest, ob zusätzlich die Rolle öffentlich wird. Todesursache und interne Effekte bleiben privat, sofern eine Regel sie nicht ausdrücklich veröffentlicht.
- **DR-05 Schutzengel:** Wählt jede Nacht eine andere lebende Person. Schutz gilt nur in dieser Nacht gegen Wolfsangriffe, wird erst bei der Morgenauflösung angewandt und endet bei Tagesbeginn.
- **DR-06 Waldhexe:** Besitzt je einen Heil- und Gifttrank pro Partie und darf beide in derselben Nacht verwenden. Gift tötet sofort. Vor ihrer Entscheidung sieht sie den Namen des Wolfsopfers; rettet sie es, erfährt sie zusätzlich dessen Rolle.
- **DR-07 Orakel:** Sonderwölfe erscheinen als `Werwolf`; Selbstprüfung ist verboten.
- **DR-08 Trugbilderwolf:** Der Spielleiter wählt die dem Orakel gezeigte falsche Rolle.
- **DR-09 Sensenträger:** Darf auf seine Todesreaktion verzichten. Nach einem Tod am Tag reagiert er sofort; nach einem Tod in der Nacht während der Morgenauflösung.
- **DR-10 Wolfskind:** Darf sich nicht selbst als Vorbild wählen. Nach der Verwandlung wacht es ab der folgenden Nacht mit dem Rudel auf.
- **DR-11 Lehrling:** Bei seinem Nachtschritt zeigt die App drei vom Spielleiter ausgewählte Rollen, ohne die dazugehörigen Personen zu nennen. Jede Option ist intern an eine lebende Person gebunden. Der Lehrling wählt eine Rolle; stirbt die gebundene Person, erbt er die Rolle mit vollständig zurückgesetzten Nutzungen. Die geerbte Rolle wirkt ab der folgenden Nacht. Erbt er `wolfskind`, bleibt diese Rolle zunächst unverwandelt und er wählt bei seinem nächsten Nachtschritt ein neues Vorbild; erst dessen Tod aktiviert die Verwandlung.
- **DR-12 Manipulator:** Sein Einzelsieg erfordert genau drei lebende Personen.
- **DR-13 Spiegelwolf:** Fehlt eine gespeicherte Nominierung, findet keine Spiegelung statt und der Spiegelwolf stirbt normal.
- **DR-14:** Nach jedem Tod wird ein vorläufiger Siegstatus berechnet. Offene Todesreaktionen und Fähigkeiten werden zuerst vollständig abgearbeitet. Danach wird erneut geprüft; erst dann kann der Spielleiter den Sieg bestätigen.

## Vertical Slice · Präzisierungen zu DR-08 und DR-11 · 26. September 2026

- **Lehrling, Wirkung des Erbes:** Rolle, Fraktion und Berücksichtigung für Siegbedingungen wechseln sofort beim Erbe. Nachtfähigkeiten der geerbten Rolle sind erstmals in der folgenden Nacht verfügbar. *(Präzisiert durch die Korrekturrunde unten.)*
- **Lehrling, geeignete Personen:** Für die Auswahl der drei Personen ist jede lebende Person außer dem Lehrling selbst geeignet.
- **Trugbilderwolf, Scheinrolle:** Der Spielleiter legt die Scheinrolle beim Spielaufbau fest. Sie wird gespeichert und bleibt während der Partie unverändert. *(Ersetzt durch die Korrekturrunde unten: Korrektur per bestätigter GmCorrection zulässig.)*

## Korrekturrunde Regelkern · 26. September 2026

Diese Einträge ersetzen widersprechende ältere Formulierungen ausdrücklich.

1. **Trugbilderwolf:** Die gespeicherte Scheinrolle darf durch eine bestätigte Spielleiterkorrektur geändert werden. Ohne Korrektur bleibt sie während der Partie unverändert.
2. **Lehrling, sofortige Wirkung:** Mit dem Erbe gelten Rolle, Fraktion, passive Eigenschaften, Siegbedingungen und Todesreaktionen der geerbten Rolle sofort. Stirbt der Lehrling nach dem Erbe und vor der folgenden Nacht, gilt die Todesreaktion der geerbten Rolle bereits.
3. **Lehrling, aktive Nachtfähigkeiten:** Nur aktiv auszuführende Nachtfähigkeiten der geerbten Rolle sind erstmals in der folgenden Nacht verfügbar.
4. **Hinrichtung ohne Nominierung:** Sie ist als bestätigte Spielleiterkorrektur möglich; die Todesursache bleibt Hinrichtung (Lynch), Todesreaktionen und Siegprüfung laufen normal.
5. **Keine widersprüchlichen Zustände durch Korrekturen:** Eine Spielleiterkorrektur hinterlässt keinen widersprüchlichen offenen Prompt und keinen widersprüchlichen Siegzustand. Ein offener Prompt wird bei jeder Korrektur des Spielerzustands mit dem Grund `state_changed_by_gm_correction` abgebrochen und kann danach erneut begonnen werden. Ein Siegkandidat entsteht nie, solange ein Prompt oder eine Reaktion offen ist. Ein Sieger kann nur ohne offenen Prompt und ohne offene Reaktion erklärt werden.

## Randfälle Rudelangriff und Wiederbelebung · 26. September 2026

1. **Bereits totes Rudelopfer:** Stirbt ein bereits bestätigtes Rudelopfer vor der Morgenauflösung, wird die Rudelwahl nicht erneut geöffnet. Bei der Morgenauflösung findet kein weiterer Rudelangriff statt.
2. **Wiederbelebung und Todesreaktion:** Eine durch einen Tod bereits ausgelöste und eingereihte Todesreaktion bleibt bestehen, wenn die Person später wiederbelebt wird. Die Wiederbelebung entfernt oder verändert das frühere Todesereignis nicht.
3. **Sensenträger, kein Selbstziel:** Der Sensenträger darf nie sich selbst als Ziel seiner eigenen Todesreaktion wählen, auch nicht, wenn er nach seinem Tod wiederbelebt wurde und seine eingereihte Reaktion noch offen ist.

## Schutzengel · bestätigte Nachtaktionen · 26. September 2026

- Hat der Schutzengel seine Auswahl bestätigt und stirbt er später in derselben Nacht, bleibt der bestätigte Schutz bis zur Morgenauflösung bestehen.
- Allgemein: Ein späteres Ereignis entfernt keine bereits bestätigte Rollenaktion rückwirkend. Ausdrückliche Spielleiterkorrekturen bleiben davon unberührt.
- Der Schritt eines lebenden Schutzengels ist eine Pflichtauswahl genau einer anderen lebenden Person. `SkipStep` ist dafür nie zulässig, auch nicht mit Begründung; `CancelPrompt` vor der Bestätigung bleibt zulässig. Der Rudelschritt bleibt mit Begründung überspringbar, Reaktionsschritte bleiben nicht überspringbar.

## Waldhexe · Produktionsrolle im Regelkern · 26. September 2026

- Jede lebende Waldhexe mit mindestens einem unverbrauchten Trank erhält einen Nachtschritt nach dem Rudel, mehrere nach Personen-ID. Heil- und Gifttrank sind pro Person und Partie je einmal verfügbar; eine Wiederbelebung setzt sie nicht zurück, nur das spätere Lehrling-Erbe.
- Der Schritt ist eine atomare, persistente Prompt-Kette: Opfer sehen (nur Name bzw. Personen-ID, unabhängig von einem Schutz) → retten → bei Rettung Rolle des Opfers sehen → vergiften → Giftziel → Zusammenfassung und finale Bestätigung. Vor der Bestätigung wird nichts verbraucht, gespeichert oder getötet; `CancelPrompt` verwirft alle Teilantworten. `SkipStep` ist nie zulässig; die Waldhexe verzichtet ausdrücklich im Prompt.
- Bestätigung in fester Reihenfolge: Trankverbrauch und Rettung speichern, dann Gifttod (`WITCH_POISON`, Quelle Waldhexe) über die normale Tötungs-Pipeline, dann Schritt erledigt. Todesreaktionen nach Gift folgen in der Morgenauflösung (DR-09).
- Die Rettung verhindert nur den Rudelangriff dieser Nacht und wird in der Morgenauflösung angewandt. Schutzengel und Rettung auf demselben Opfer: beide werden verbraucht und protokolliert, es entsteht genau ein verhinderter Angriff. Schutz verhindert Gift nicht.
- Ein Nachtschritt einer Person, die vor ihrem Schritt gestorben ist, entfällt automatisch und protokolliert; das gilt für alle persönlichen Nachtschritte. Ein Waldhexenschritt ohne mögliche Entscheidung entfällt ebenso.
- Spielleiterkorrekturen: Trankstatus einzeln setzen; Rettung der laufenden Nacht setzen oder entfernen, nur nach bestätigtem Waldhexenschritt und vor der Morgenauflösung. Rettungskorrektur und Trankstatus sind getrennte Korrekturen. *(Rettungsziel präzisiert durch die Korrekturrunde unten.)*

## Korrekturrunde Waldhexe und Nachtplan · 26. September 2026

Diese Einträge ersetzen widersprechende ältere Formulierungen ausdrücklich.

1. **Tatsächliche Rolle nach Rettung:** Die Waldhexe erfährt nach einer bestätigten Rettung die tatsächliche Rolle (`role_id`) des Opfers. `appears_as` gilt für Informationsrollen wie das Orakel und verändert diese Offenlegung nicht.
2. **Rettung nur für das aktuelle Rudelopfer:** Eine Waldhexenrettung betrifft ausschließlich das aktuell bestätigte Rudelopfer dieser Nacht. Die Spielleiterkorrektur `set_rescue` nimmt nur dieses lebende Opfer an; ohne Rudelopfer oder bei einem anderen oder toten Ziel wird sie abgelehnt. `remove_rescue` bleibt zulässig. Ein „Ändern“ auf eine andere Person gibt es nicht.
3. **Nachtplan als Snapshot:** Der Nachtplan wird bei `StartNight` festgelegt. Wer während der Nacht eine neue Rolle erhält, bekommt in dieser Nacht keinen zusätzlichen Schritt. Verliert eine Person während der Nacht die Rolle ihres geplanten persönlichen Schritts, entfällt dieser Schritt mit Protokolleintrag; sie führt nie die Fähigkeit ihrer früheren Rolle aus. Das gilt für alle persönlichen Nachtschritte.
4. **Tränke während der Nacht:** Ein per Korrektur wieder verfügbar gemachter Trank erzeugt in einer bereits laufenden Nacht keinen zusätzlichen Schritt; er gilt spätestens ab der nächsten Nacht.

## Orakel · Produktionsrolle und Informationsmodell · 26. September 2026

- Jedes lebende Orakel erhält jede Nacht einen Pflichtschritt nach allen Waldhexenschritten (mehrere nach Personen-ID). Es prüft genau eine andere lebende Person; Selbstprüfung ist verboten. `SkipStep` ist nie zulässig, `CancelPrompt` vor „Gezeigt“ verwirft die Prüfung vollständig.
- Informationsmodell: `truth_role` ist die tatsächliche aktuelle Rolle. `determined_role` ergibt sich aus einer einzigen Regel mit dieser Priorität: eine besondere gespeicherte Erscheinung (`appears_as` weicht von `role_id` ab) → `werwolf`, wenn die Person als Wolf zählt → tatsächliche Rolle. `shown_role` ist normalerweise gleich `determined_role`.
- Der Spielleiter darf `shown_role` vor „Gezeigt“ mit Bestätigung und Begründung übersteuern; Wahrheit und ermitteltes Ergebnis bleiben unverändert, der Prompt bleibt offen.
- Mit „Gezeigt“ entsteht ein Informationsdatensatz im Spielzustand. Der Spielleiter erhält alle drei Werte; das Orakel erhält ausschließlich das gezeigte Ergebnis in einem eigenen Ereignis. Öffentliche Ereignisse enthalten keine Orakelinformation.
- Die Waldhexe erfährt nach einer Rettung weiterhin die tatsächliche Rolle und nutzt dieses Modell nicht.
- Nachtpriorität persönlicher Schritte: Schutzengel 1.3, Rudel 2.0, Waldhexe 3.4, Orakel 4.6; bei gleicher Priorität nach Personen-ID.

## Trugbilderwolf · Produktionsrolle und Scheinrolle im Setup · 26. September 2026

- Der Trugbilderwolf gehört vollständig zu den Werwölfen, zählt als Wolf, hat keinen eigenen Nachtschritt und bildet allein oder mit anderen Wölfen das Rudel.
- Seine Scheinrolle steht in `appears_as` und wird beim Spielaufbau für jede Instanz ausdrücklich festgelegt, nie zufällig. Zulässig ist jede bekannte Rolle, die nicht als Wolf zählt, auch wenn sie in der Partie nicht vorkommt.
- Bei zufälliger Verteilung werden Rolle und Scheinrolle als Einheit gemischt (`role_entries`), damit jede Scheinrolle bei ihrer Instanz bleibt; nur die Verteilung nutzt den gespeicherten RNG.
- Das Orakel ermittelt die Scheinrolle über die zentrale Informationsregel; die Waldhexe sieht bei einer Rettung die tatsächliche Rolle.
- Eine Korrektur der Scheinrolle ist nur auf Nicht-Wolf-Rollen zulässig und wirkt auf spätere Prüfungen; abgeschlossene Informationen bleiben unverändert. Wer per Korrektur zum Trugbilderwolf wird, erhält Rolle und Scheinrolle gemeinsam; wer es nicht mehr ist, erhält die normale Erscheinung seiner neuen Rolle.

## Wolfskind · Produktionsrolle und Verwandlung · 26. September 2026

- Das Wolfskind beginnt im Dorf (`counts_as_wolf` nein, Erscheinung `wolfskind`). Einen Auswahl-Schritt mit Priorität 0.9 erhält es in jeder neu berechneten Nacht, solange es lebt, unverwandelt ist und kein Vorbild hat; ein regulär gestartetes Wolfskind handelt damit in Nacht 1. Es wählt genau eine andere lebende Person; `SkipStep` ist nie zulässig.
- Stirbt das Vorbild mit Todesfolgen, während das Wolfskind lebt, verwandelt es sich sofort und vor der vorläufigen Siegprüfung dieses Todes: Rolle bleibt `wolfskind`, Fraktion Werwölfe, zählt als Wolf, Erscheinung `werwolf`. Mehrere Wolfskinder mit demselben Vorbild verwandeln sich nach Personen-ID.
- Der laufende Nachtplan bleibt unverändert; am Rudel nimmt es ab der folgenden Nacht teil. Ein totes Wolfskind verwandelt sich für diesen Tod nie, auch nicht nach Wiederbelebung; ein erneuter Tod des wiederbelebten Vorbilds kann verwandeln.
- Ein Tod per `GmCorrection kill` ohne Todesfolgen verwandelt nicht.
- Das Orakel ermittelt vor der Verwandlung `wolfskind`, danach `werwolf`; die Waldhexe sieht immer die tatsächliche Rolle `wolfskind`.
- Spielleiterkorrekturen: Vorbild setzen, ändern, entfernen; Verwandlung auslösen und zurücknehmen (das Vorbild bleibt). Die Erscheinung des Wolfskinds ist nicht einzeln korrigierbar.

## Spiegelwolf · Produktionsrolle und Hinrichtungsauflösung · 26. September 2026

Dieser Eintrag ersetzt für die tote nominierende Person die ältere Formulierung „niemand stirbt“ (Regelregister §11, AS-R30).

- Der Spiegelwolf gehört zu den Werwölfen, zählt als Wolf, hat keinen eigenen Nachtschritt und ist Teil des Rudels.
- Die erste bestätigte Hinrichtung (Ursache `LYNCH`) wird auf die Person umgeleitet, die ihn an diesem Tag nominiert hat: Sie stirbt mit `SPIEGELWOLF_RETALIATE`, Quelle Spiegelwolf; er überlebt, die Hinrichtung des Tages gilt als erfolgt. Die Spiegelung ist einmal pro Person und Partie und wird erst mit der bestätigten Hinrichtung verbraucht.
- Keine Spiegelung und normaler Tod mit `LYNCH`, ohne Verbrauch: bei bereits verbrauchter Spiegelung, ohne Nominierung dieses Tages auf ihn und wenn die nominierende Person bei der Hinrichtung tot oder unbekannt ist.
- Selbstnominierung: Die Spiegelung wird ausgelöst und verbraucht; er selbst stirbt mit `SPIEGELWOLF_RETALIATE`, genau ein Tod.
- Reguläre Hinrichtung und `GmCorrection execute` nutzen dieselbe Auflösung; mit gültiger Nominierung spiegelt auch die Übersteuerung. Schutzengel und Hexenrettung verhindern die Spiegelung nicht. Folgen des Spiegelziels (Reaktion, Wolfskind) laufen normal.
- Eine Wiederbelebung und ein Rollenwechsel setzen die Nutzung nicht zurück.

## Manipulator und Kandidatenmenge · 26. September 2026

- Der Manipulator gehört zur Einzelsiegfraktion, zählt nicht als Wolf und hat keinen Nachtschritt. Wird er nominiert, wird zuerst die Nominierung gespeichert, dann stirbt er sofort mit `MANIPULATOR_NOMINATED`, Quelle die nominierende Person; der Tag bleibt aktiv. Eine Hinrichtung ist immer `LYNCH`.
- „Jemals nominiert“ ist ein dauerhafter Personenstatus (`ever_nominated`), gesetzt bei jeder Nominierung unabhängig von der Rolle; Wiederbelebung und Rollenwechsel ändern ihn nicht. Er ist nur per Spielleiterkorrektur änderbar; gespeicherte Nominierungen bleiben dabei unverändert.
- Siegkandidat des Manipulators genau dann, wenn exakt drei Personen leben, er lebt und nie nominiert wurde; mehrere Manipulatoren sind getrennte personenbezogene Kandidaten.
- Alle gleichzeitig erfüllten Siegbedingungen bilden eine Kandidatenmenge ohne Priorität, erst aus dem endgültigen Zustand nach allen Reaktionen (DR-14). Der Spielleiter bestätigt genau einen (die übrigen gelten als nicht gewählt) oder lehnt alle gemeinsam mit Grund ab. Lebt niemand, entsteht kein Kandidat.

## Lehrling · Produktionsrolle, verdeckte Auswahl und Erbe · 26. September 2026

Dieser Eintrag ersetzt „nur Nacht 1, einmalig“ (Regelregister §9, Nachtpriorität).

- Der Lehrling beginnt im Dorf. Einen Auswahl-Schritt mit Priorität 1.1 erhält jede lebende Person mit aktueller Rolle `lehrling` ohne aktive Bindung in ihrer ersten verfügbaren Nacht, auch nach einem späteren Rollenwechsel; mehrere Lehrlinge nach Personen-ID. Der Schritt ist nicht überspringbar; bei weniger als drei anderen Lebenden entfällt er protokolliert.
- Der Spielleiter wählt genau drei verschiedene andere lebende Personen, jede aktuelle Rolle ist zulässig. Der Lehrling sieht nur die drei aktuellen Rollen, nach Rollen-ID sortiert; gleiche Rollen werden mit dem gespeicherten `SeededRng` gemischt. Er wählt eine Option, nie eine Person. Die Ziehung wird erst mit der Bestätigung übernommen; ein Abbruch vorher hinterlässt keine Bindung und keinen verbrauchten Zufall.
- Die Bindung wird dauerhaft als eigener Datensatz gespeichert (`apprentices`), sichtbar nur für den Spielleiter.
- Stirbt der Meister mit Todesfolgen, während der Lehrling lebt, erbt der Lehrling sofort dessen aktuelle Rolle: nach Wolfskind-Verwandlungen desselben Todes, vor der Todesreaktion des Meisters und vor der vorläufigen Siegprüfung. Mehrere Lehrlinge desselben Meisters nach Personen-ID. `original_role_id` und `ever_nominated` bleiben, alle begrenzten Einsätze der geerbten Rolle beginnen frisch. Aktive Nachtfähigkeiten erst ab der folgenden Nacht.
- Sonderfälle: Wolfskind unverwandelt ohne Vorbild, neuer Wolfskind-Schritt in der folgenden Nacht; Trugbilderwolf mit der Scheinrolle des Meisters; geerbtes `lehrling` verbraucht die alte Bindung, die neue Auswahl folgt in der nächsten Nacht.
- Stirbt der Lehrling vor dem Erbe, verfällt die Bindung endgültig, auch bei einem Tod ohne Todesfolgen und auch nach Wiederbelebung. Ein Tod des Meisters per `GmCorrection kill` ohne Todesfolgen löst kein Erbe aus (wie beim Wolfskind). Nach einem Erbe führt eine Wiederbelebung des Meisters zu keinem zweiten Erbe.
- Spielleiterkorrekturen: Bindung setzen oder ändern (eine Option, die aktuelle Rolle des Meisters), Bindung entfernen, Erbe auslösen, Erbe zurücknehmen. Die Rücknahme stellt exakt den beim Erbe gespeicherten Rollenzustand wieder her und aktiviert die Bindung; sie ist nur für den jüngsten Datensatz möglich, solange die Person lebt und noch die geerbte Rolle hat.
- Rollenwechsel laufen zentral über `RoleTransition` (auch `set_role`); wer die Rolle `lehrling` verliert, verliert eine aktive Bindung (`removed`).
