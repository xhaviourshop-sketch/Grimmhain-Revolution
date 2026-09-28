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

## Nachtmusik und Assetregister · 26. September 2026

> **Teilweise korrigiert** durch den Eintrag „Korrektur: Assetentscheidungen ohne belegte Nutzerzustimmung · 27. September 2026“ weiter unten. Der ursprüngliche Wortlaut bleibt zur Nachvollziehbarkeit unverändert stehen.

- Für `assets/sounds/Nachtmusik.mp3` liegt dem Product Owner kein belastbarer Lizenz- oder Herkunftsnachweis vor. Die Datei gilt als ungeklärt, bleibt gesperrt und wird für Version 1.0 durch eine neue Nachtmusik ersetzt (`../assets/PRODUCTION-PLAN.md` §6.2).
- Das Assetregister wird maschinenlesbar in `asset-register.csv` geführt und mit `node tools/check-asset-register.js` geprüft. Nur der Product Owner setzt den Status `freigegeben`.

## Assetstrategie, Budget und Legacy-Medien · 27. September 2026

> **Korrigiert** durch den Eintrag „Korrektur: Assetentscheidungen ohne belegte Nutzerzustimmung · 27. September 2026“ weiter unten. Dieser Eintrag beruhte auf Vorgaben eines Arbeitsauftrags, nicht auf einer belegten persönlichen Entscheidung des Nutzers. Der ursprüngliche Wortlaut bleibt zur Nachvollziehbarkeit unverändert stehen; maßgeblich ist die Korrektur.

Dieser Eintrag entscheidet Q8 (`../godot-migration/07-open-questions.md`) mit **Option B** und präzisiert den Eintrag „Gestaltung, Audio und Assets".

- KI-generierte Medien sind für Konzept, Platzhalter und Stilentwicklung erlaubt.
- Zentrale Schlüsselassets werden später gezielt neu produziert, selbst erstellt, beauftragt oder mit eindeutig dokumentierten kommerziellen Nutzungsrechten erzeugt.
- Kein Legacy-Asset gilt allein wegen guter Optik als releasefähig.
- Jede finale Datei braucht nachvollziehbare Herkunft, Lizenz beziehungsweise Nutzungsrecht und Product-Owner-Freigabe (Registerstatus `freigegeben`).
- KI-Verwendung wird je Asset transparent dokumentiert (Werkzeug, Tarif, Datum, Prompt, Nachbearbeitung) und für Stores offengelegt.
- Budget für externe KI-, Audio-, Sprecher-, Grafik- oder Lizenzwerkzeuge: höchstens 500 € gesamt. Konservativ planen, kostenlose Werkzeuge bevorzugen, wenn die Qualität genügt. Claude löst keine Käufe oder Abonnements aus und dokumentiert nur Empfehlungen und Kostenrahmen.
- Für Rollenkarten, UI-Grafiken, Statussiegel, Dorfplatz-Hintergründe, kurze Legacy-Sounds und die Nachtmusik liegt kein zusätzlicher Herkunftsnachweis vor. Sie bleiben `ungeklärt` beziehungsweise `gesperrt`, sind nicht releasefähig, dienen höchstens als visuelle oder akustische Referenz und werden nicht nach Godot übernommen.
- Die zehn OpenAI-Porträts (C2PA belegt die Plattform; Tarif, Prompts und Kontohistorie fehlen) bleiben `ki-nachgewiesen`, ohne Releasefreigabe. Sie sind als Stilreferenz und Entwicklungsplatzhalter dokumentierbar und werden nicht nach Godot kopiert.
- Schriften: Die ursprüngliche Downloadquelle ist unbekannt. Familie und SIL OFL 1.1 werden über die eingebetteten Font-Metadaten belegt, ergänzt um die heutige offizielle Referenzquelle (`../assets/FONTS.md`). Eine Downloadhistorie wird nicht rekonstruiert oder behauptet.

## Korrektur: Assetentscheidungen ohne belegte Nutzerzustimmung · 27. September 2026

**Anlass.** Der Nutzer hat klargestellt: Er hat einen Gesamtrahmen bis 500 € und die grundsätzliche Nutzung kostenpflichtiger KI-Werkzeuge genannt. Daraus folgt keine ausdrückliche Freigabe für Q8 Option B, für eine bestimmte Produktionsmethode oder für konkrete Käufe. Die beiden vorangehenden Asset-Einträge haben Vorgaben aus Arbeitsaufträgen als persönliche Product-Owner-Entscheidungen eingetragen. Diese Korrektur ersetzt sie, soweit sie widersprechen.

| Aussage | bisher eingetragen als | gilt jetzt als | Beleg |
|---|---|---|---|
| Budget bis 500 € | Entscheidung, Obergrenze für externe Werkzeuge | **bestätigter Planungsrahmen**; kein Einzelkauf, kein Abonnement und keine bezahlte Generierung ist genehmigt | Eintrag „Gestaltung, Audio und Assets" („Budget bis 500 €"), Klarstellung des Nutzers |
| Q8 Option B | entschieden | **Empfehlung**, Entscheidung offen | `07-open-questions.md` Q8 |
| KI für Konzept, Platzhalter, Stilentwicklung | entschieden | grundsätzliche Nutzung kostenpflichtiger KI-Werkzeuge ist vom Nutzer genannt; Umfang und Methode sind nicht entschieden. Für finale KI-Assets gilt weiter der Eintrag „Gestaltung, Audio und Assets" (Herkunft, Lizenzprüfung, Qualitätsprüfung, PO-Freigabe) | Eintrag „Gestaltung, Audio und Assets", Klarstellung des Nutzers |
| 60 € für die erste Welle, 300 € Gesamtplanung | Obergrenzen | **vorgeschlagene Teilbudgets** | `../assets/PRODUCTION-PLAN.md` §8 (Vorschlag) |
| Legacy-Rollenkarten, UI-Grafiken, Statussiegel, Dorfplatz, kurze Sounds | „nicht releasefähig", „werden nicht nach Godot übernommen" | **Herkunftsnachweis fehlt; Nutzung ist nicht freigegeben.** Keine Aussage über rechtliche Unzulässigkeit. Registerstatus `ungeklärt` | Registerbefund, `../assets/INVENTORY.md` |
| Kurze Legacy-Sounds | Status `gesperrt` | Status `ungeklärt`; für eine ausdrückliche Sperre gibt es keinen Beleg | Register korrigiert am 27. September 2026 |
| Nachtmusik | „bleibt gesperrt und wird ersetzt" | Nutzeraussage vom 26. September 2026: kein belastbarer Nachweis, als ungeklärt behandeln, nicht für eine Veröffentlichung freigegeben. Status `gesperrt` folgt aus dem Masterplan (Phase 0: „Nachtmusik bis zum Herkunftsnachweis sperren"). Ein Ersatz ist **Empfehlung**, nicht entschieden | Antwort des Nutzers 26.09., Masterplan Phase 0 |
| OpenAI-Porträts | „werden nicht nach Godot kopiert" | C2PA belegt die Plattform; Tarif, Prompts und Kontohistorie sind nicht dokumentiert. Status `ki-nachgewiesen`, **nicht freigegeben**; eine Übernahme ist nicht freigegeben | Registerbefund |
| Ursprüngliche Bezugsquelle der Schriften unbekannt | Aussage des Product Owners | Angabe aus dem Arbeitsauftrag vom 27. September 2026; im Repository gibt es ebenfalls keinen Beleg | `../assets/FONTS.md` |
| Nur der Product Owner setzt `freigegeben` | Entscheidung | Verfahrensregel aus dem Masterplan §9 („Claude darf … keinen unbekannten Assetstatus als freigegeben markieren") | Masterplan §9 |

Unverändert gilt: Jede finale Datei braucht nachvollziehbare Herkunft, Nutzungsrecht und Product-Owner-Freigabe (Eintrag „Gestaltung, Audio und Assets", Masterplan §2 und Phase 9). Offene Entscheidungen des Nutzers: Q8, Teilbudget der ersten Welle, Porträtstil und Figurenvorgaben (`../assets/BRIEFING-WAVE-1.md` §11).

## Rollenaudit · Doppelspion, Selbstmörder, Einmalfähigkeiten, Gebundene, Chronistin, Rudel · 27. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen F-01 bis F-10, `../role-migration/11-role-audit-status.md` §6). Freitextantworten sind wörtlich zitiert und ihre Auslegung ist genannt.

- **Doppelspion muss leben (RM-DR-155.1):** Antwort „Das Dorf, er verliert, weil er alleine gewinnen will“. Auslegung: Nur ein lebender Doppelspion gewinnt; ist er tot, wenn der letzte Wolf stirbt, gewinnt das Dorf.
- **Doppelspion und Dorfsieg (RM-DR-155.3):** A. Lebt mindestens ein Doppelspion, wenn kein Wolf mehr lebt, wird nur der Doppelspion-Sieg (je Person) vorgeschlagen, nicht der Dorfsieg. Ablehnen und `declare_winner` bleiben möglich.
- **Doppelspion beim Rudel (RM-DR-155.4):** A. Der Spielleiter nennt keine Rolle; die Wölfe sehen eine weitere wache Person.
- **Selbstmörder, Zählbasis (RM-DR-138.1):** Antwort „Sie wär die 6. Tote und es wird bei 5 toten Personen ein Sound ertönen“. Auslegung: Gezählt werden die Toten vor seiner Hinrichtung; bei mindestens 5 gewinnt er. Zusätzlich gewünscht: ein Sound, sobald 5 Personen tot sind (Audio-Anforderung; ob er nur bei einem Selbstmörder im Spiel und öffentlich ertönt, ist noch offen, weil er sonst dessen Anwesenheit verraten kann).
- **Selbstmörder, Wiederbelebte (RM-DR-138.3):** A. Es zählen nur Personen, die bei der Hinrichtung tot sind.
- **Selbstmörder, abgelehnter Sieg (RM-DR-138.4):** B. Ein abgelehnter Selbstmörder-Sieg wird nach jeder späteren Zustandsänderung erneut vorgeschlagen.
- **„Einmalig“ und „erste Nacht“ (RM-DR-014):** B. Fähigkeiten „zu Beginn des Spiels“ bzw. „in der ersten Nacht“ gelten strikt nur in Nacht 1 der Partie; wer dann nicht handelt oder die Rolle später erhält, hat sie nicht mehr. Wolfskind und Lehrling bleiben bei ihrer eigenen Entscheidung (DR-10, DR-11).
- **Die Gebundenen:** A. Jede lebende Gebundene sieht alle anderen lebenden Gebundenen; lebt nur eine, erfährt sie „keine anderen“.
- **Dorfchronistin:** A. Anzahl der Personen mit Einzelsiegrolle, lebend und tot; mehrere Chronistinnen erhalten die Information jeweils für sich.
- **Rudel nach Verwandlung in derselben Nacht:** A. Der Rudelschritt entfällt, wenn niemand mehr lebt, der zu Beginn der Nacht als Wolf zählte; ein in dieser Nacht verwandeltes Wolfskind wacht erst ab der folgenden Nacht.

## Rollenaudit · Nachfragen Spielende, Nachttode, Sound · 27. September 2026

Diese Einträge ersetzen widersprechende ältere Formulierungen ausdrücklich (insbesondere DR-06 „Gift tötet sofort“ und die Bestätigungsreihenfolge im Eintrag „Waldhexe · Produktionsrolle im Regelkern“).

- **Spielende (Nachfrage zu F-11):** A. Die App schlägt einen erkannten Sieg vor, der Spielleiter bestätigt mit einem Tipp, danach folgt ein großer Siegbildschirm. Ablehnen bleibt als Fehlerkorrektur. Ein einmal erfüllter Sieg wird nach einer Ablehnung weiter vorgeschlagen, auch der Selbstmörder-Sieg nach einer Wiederbelebung (F-11 = B).
- **Nachttode (Nachfrage zu F-04):** Antwort „C, sollte ein Marker gesetzt sein und die Person zu 100 % sterben, wacht sie die Nacht nicht auf, weil sie eh ihre Info am Tag nicht teilen kann“. Gift setzt eine Todesmarkierung; die Person stirbt erst in der Morgenauflösung (dann Verwandlung, Erbe, Reaktionen, Siegprüfung), verliert aber sofort ihre übrigen persönlichen Nachtschritte dieser Nacht. Ein Rudelopfer ist nachts noch nicht sicher tot (Rettung möglich) und behält seine Schritte.
- **Sound bei 5 Toten:** ertönt, sobald die fünfte Person ihren Totenmarker erhält (öffentlich, am Tag), und nur, wenn ein Selbstmörder in der Partie ist. Oberflächen-/Audio-Anforderung, nicht Regelkern.

## Rollenaudit · Waldläufer, Doktor, Sitznachbarn, Nachtwächter, Kutscher · 27. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet.

- **Waldläufer, Häufigkeit (RM-DR-147.1):** A. Eigener Schritt in jeder Nacht, solange er lebt.
- **Waldläufer, Zählung (RM-DR-147.2):** A. Gezählt werden Personen, die zum Zeitpunkt seines Schritts leben und als Wolf zählen; der Siegreiche Wolf zählt einmal, ein Rudelopfer dieser Nacht lebt noch.
- **Doktor, zwei Einzelsiegrollen (RM-DR-145.1):** B. „Einzelsieg“ gilt als ein Team; zwei Personen mit Einzelsiegrolle sind „gleich“.
- **Doktor, Trugbilderwolf:** A. Es zählt die wahre aktuelle Fraktion; die Scheinrolle täuscht nur Rollen-Informationen.
- **Doktor, Ziele:** A. Genau zwei verschiedene andere lebende Personen.
- **Sitznachbarn (RM-DR-003, RM-DR-102.1, RM-DR-116.1):** A. Nachbarn sind die nächsten lebenden Personen links und rechts im Sitzkreis; tote Plätze werden übersprungen.
- **Nachtwächter:** A. Jeden Morgen nach der Morgenauflösung: sitzt neben einem lebenden Nachtwächter jemand, der nicht zum Dorf gehört (Wolf oder Einzelsieg), läuten öffentlich die Glocken, ohne Seite oder Namen.
- **Wahnsinniger Kutscher und Spiegelung:** A. Nur ein echter Lynch des Kutschers lässt die Nachbarn mitsterben; eine Spiegelung auf ihn ist keine Hinrichtung.

## Rollenaudit · Wiederbelebung, Besessener Wolf, Ritter, Fährtenleser · 27. September 2026

Vom Product Owner in der Claude-Code-Sitzung beantwortet. Der erste Punkt ersetzt ausdrücklich ältere Formulierungen („eine Wiederbelebung setzt nichts zurück“ in G-ID-3-Erläuterungen, Waldhexe: „eine Wiederbelebung setzt sie nicht zurück“, Spiegelwolf: „Eine Wiederbelebung … setzt die Nutzung nicht zurück“, Sensenträger: „einmal pro Person und Partie“ gilt jetzt je Leben).

- **Wiederbelebung setzt Fähigkeiten zurück:** Antwort „Jede Wiederbelebung = Reset der Fähigkeit“, auf Nachfrage B „Alle Fähigkeiten“. Jede Wiederbelebung setzt alle begrenzten Einsätze der Person zurück (Tränke, Spiegelung, Todesreaktionen, einmalige Fähigkeiten). Unverändert bleiben Zustände, die keine Fähigkeit sind: Nominierungsstatus (`ever_nominated`), Wolfskind-Vorbild und -Verwandlung, Lehrling-Bindung und Erbe, erfüllte Siege, bereits eingereihte Reaktionen.
- **Besessener Wolf, Schwelle (RM-DR-124.1):** A. Mindestens 5 Lebende unmittelbar vor seinem Tod, er eingeschlossen.
- **Besessener Wolf, Mitnahme:** A. Nach seinem Tod wählt er eine andere lebende Person (auch einen Wolf) oder verzichtet; Tag sofort, Nacht in der Morgenauflösung (wie Sensenträger).
- **Ritter, Auslöser (RM-DR-136.1):** A. Nur ein Tod durch Wolfsangriff (Rudel; spätere Wolfsangriffe) löst aus, Gift nicht.
- **Ritter, Ziel:** A. Nächste lebende Person, die als Wolf zählt, Abstand in Sitzen einschließlich toter Plätze; bei Gleichstand wählt der Spielleiter.
- **Richtung „links“ (RM-DR-146.1, RM-DR-153.4):** A. Aus Sicht der Person am Tisch: links ist der nächste Platz im Uhrzeigersinn des App-Sitzkreises. Gegenprüfung am Tablet, ob die Sitzansicht im Uhrzeigersinn läuft, bleibt offen.
- **Fährtenleser, Gleichstand (RM-DR-146.2):** A. Abstand wie beim Ritter; bei Gleichstand erfährt er „beide Seiten gleich weit“.
- **Fährtenleser, Ablauf:** B. Jede Nacht ein Schritt „jetzt nutzen?“ bis zur Nutzung; danach kein Schritt mehr.

## Rollenaudit · Querschnittsfragen · 27. September 2026

Vom Product Owner in der Claude-Code-Sitzung beantwortet; Freitext wörtlich mit Auslegung.

- **Wolfsangriff (RM-DR-004):** A. Wolfsangriff ist ausschließlich der Rudelangriff (Rudelopfer, einschließlich weiterer Rudelopfer derselben Art wie beim Rudelvater). Einzeltötungen einzelner Wolfsrollen haben eigene Ursachen und sind keine Wolfsangriffe.
- **Durchdringung (RM-DR-005):** A. „Ignoriert Schutz“ durchdringt Schutzengel, Waldhexenrettung, Dorfwache-Immunität und die Rettung des Weisen; nicht die persönlichen Schilde der Einzelsiegrollen, nicht Umlenkungen und Ersatzopfer.
- **Rollenblockierung (RM-DR-010):** A. Eine Blockade lässt nur aktive Nachtschritte von Dorfrollen in der betroffenen Nacht entfallen (protokolliert); Todesreaktionen und passive Fähigkeiten wirken weiter.
- **Bindungen nach Wiederbelebung (RM-DR-011.2):** A. Eine durch einen Tod ausgelöste oder beendete Bindung (Liebespaar, Kette, Wirt) bleibt beendet; ein erneuter Tod löst sie nicht noch einmal aus. (Begrenzte Einsätze setzt die Wiederbelebung dagegen zurück, Eintrag „Wiederbelebung …“.)
- **Zufall oder Spielleiterwahl (RM-DR-015.2):** Antwort „Es gibt ein Wählen & ein Random Button.“ Auslegung: Bei Rollen mit zufälligem Ergebnis kann der Spielleiter selbst wählen oder eine Zufallsziehung auslösen; die Ziehung läuft über den gespeicherten Seed (G-RNG-1) und wird erst mit der Bestätigung übernommen.
- **Einzelsiegrollen ohne klare Siegbedingung (RM-DR-006):** A. Die Siegbedingung wird je Rolle jetzt festgelegt (Rollenfragen folgen).
- **Stimmbezug (RM-DR-008):** Antwort „Ein Reminder Text, der klar sichtbar auf dem Bildschirm des Spielleiters ist, damit er das mit einberechnen kann, da Stimmwahl physisch in der realen Welt in der ersten Version zählt und der Spielleiter das selber draufrechnen muss.“ Auslegung: Stimmboni werden nicht gezählt; der Regelkern liefert einen Hinweis, den die Spielleiteransicht deutlich anzeigt.
- **Nominierung durch den Korrupten Richter (RM-DR-012):** A. Seine Markierung ist eine normale Nominierung mit dem Richter als Nominierendem (Tageslimit, Manipulator-Tod, Spiegelung wie sonst).

## Rollenaudit · Blutwolf, Korrupter Richter, Wächter am Tor, Spürhund, Parasit · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung beantwortet; Freitext wörtlich mit Auslegung.

- **Blutwolf (RM-DR-133.1):** folgt aus RM-DR-008: Die Spielleiteransicht zeigt als Hinweis „+1 Stimme je direkt benachbartem toten Platz“, solange er lebt; nichts wird gezählt.
- **Korrupter Richter, Zeitpunkt:** Antwort „Jede Nacht am Ende des Tages bzw. zu Beginn der Nacht wird die alte Markierung gelöscht, so dass immer maximal 1 Spieler nominiert ist durch den Richter.“ Auslegung: Nachtschritt (Legacy-Stufe 1.5), freiwillig eine lebende Person markieren; bei Tagesbeginn gilt sie als vom Richter nominiert; bei Nachtbeginn wird die Markierung gelöscht.
- **Korrupter Richter, Selbstmarkierung:** B. Erlaubt.
- **Korrupter Richter, Geheimhaltung:** A. Öffentlich erscheint nur die Nominierung der markierten Person, nicht der Richter; intern ist er der Nominierende (RM-DR-012, Spiegelwolf).
- **Wächter am Tor, Umfang (RM-DR-149):** A. Jeder Weg, auf dem eine Person während der Partie zum Wolf würde (Wolfskind-Verwandlung, Lehrling erbt eine Wolfsrolle, später König Lykaon und Seelentauscher), wird blockiert; die Person wird Dorfbewohner. Spielleiterkorrekturen nicht.
- **Wächter am Tor, Mitteilung:** A. Nur die betroffene Person erfährt privat, dass sie jetzt Dorfbewohner ist.
- **Spürhund:** Antwort „Die Fähigkeit wurde falsch verstanden – Wähle 3 Spieler, sollte einer ein Wolf oder Solo-Spieler sein, kriegt er einen Haken, ist es keiner, kriegt er ein X und wird zwar weiterhin aufgerufen, aber kann seine Fähigkeit nicht mehr einsetzen.“ Auslegung: Er wählt drei Personen; ist eine davon Wolf oder Einzelsieg, erhält er ✓; sonst ✗ und verliert die Fähigkeit, wird aber weiter jede Nacht aufgerufen. Keine „falsche Spur“.
- **Spürhund, Häufigkeit:** C. Jede Nacht, freiwillig (Verzicht möglich), drei verschiedene andere lebende Personen.
- **Parasit, Sieg (RM-DR-157.1):** Antwort „Wenn 3 oder weniger Spieler am Leben sind und er darunter ist, also er + 2 andere, egal ob Wolf oder Dorf.“ Siegkandidat bei höchstens drei Lebenden, wenn er lebt; andere gleichzeitige Siege werden mit vorgeschlagen (DR-02).
- **Parasit, Unverwundbarkeit:** A. Mit lebendem Wirt überlebt er jede Todesursache; nur der Tod des Wirts tötet ihn; Spielleiterkorrekturen bleiben möglich. Ohne lebenden Wirt ist er normal verwundbar (A).
- **Parasit, Wirtwechsel:** A. Jede Nacht darf er einen neuen Wirt wählen oder beim alten bleiben.
- **Setup-Regel für Einzelsiegrollen:** Antwort „Setup auf später verschieben, dafür aber alle Rollen miteinander abgleichen und logische Konsequenz ziehen, welche Rollen nie in einer gleichen Runde sein sollten.“ Die Setup-Einschränkung ist vertagt; eine Analyse unverträglicher Rollenkombinationen wird als Vorschlag erstellt. Die bisherige Entscheidung „mehrere Manipulatoren sind getrennte Kandidaten“ bleibt bis dahin bestehen.

## Rollenaudit · Schattenhund, Albtraumwolf, Giftwolf, Rudelvater, Seuchenwolf · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung beantwortet; Freitext wörtlich mit Auslegung. Es gelten die Querschnittsentscheidungen (Wolfsangriff = Rudelangriff, Durchdringungsliste, Blockade nur aktiver Dorf-Nachtschritte).

- **Schattenhund (RM-DR-123):** A. Jede Nacht „jetzt blockieren?“, bis er es einmal genutzt hat (je Leben), auch in Nacht 1; blockiert alle Dorf-Nachtschritte dieser Nacht.
- **Reihenfolge der Blocker (RM-DR-134.3):** A. Schattenhund und Albtraumwolf handeln ganz am Anfang der Nacht vor allen Dorfrollen; die Blockade gilt für die ganze Nacht.
- **Albtraumwolf, Ziel (RM-DR-134.1/.2):** A. Jede Nacht freiwillig eine lebende Person (Wirkung nur auf Dorf-Nachtschritte dieser Person) oder Verzicht; dieselbe Person auch in aufeinanderfolgenden Nächten.
- **Giftwolf, Mitteilung (RM-DR-111.2):** Antwort „Sobald Clara vergiftet wurde, erfährt sie davon.“ Das Ziel erhält sofort eine private Mitteilung.
- **Giftwolf, Tod (RM-DR-111.3):** A. Vergiftet in Nacht N, stirbt sie in der Morgenauflösung nach Nacht N+2.
- **Giftwolf, Regeln (RM-DR-111.1):** B. Höchstens eine Giftpranke pro Nacht; nichts hebt das Gift auf außer dem früheren Tod des Ziels.
- **Giftwolf, Ablauf:** A. Eigener Nachtschritt nach dem Rudel, freiwillig; zwei Ladungen je Leben.
- **Rudelvater (RM-DR-112):** A. Nach seinem Lynch gibt es in der folgenden Nacht direkt nach dem Rudel einen zweiten Rudelschritt; dessen Opfer stirbt am Morgen und durchdringt Schutz (Liste RM-DR-005). Den ersten Tod, der weder Rudelangriff noch Lynch ist, überlebt er einmal (je Leben); Spielleitertötungen sind immer wirksam.
- **Seuchenwolf (RM-DR-108):** A. Nach seinem Tod durchdringt der nächste tatsächliche Rudelangriff Schutz (Liste RM-DR-005) und verbraucht die Wirkung, egal ob Schutz bestand; eine Nacht ohne Rudelopfer verbraucht nichts; mehrere tote Seuchenwölfe stapeln nicht.

## Rollenaudit · Fenrir, Cerberus, Henker · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet.

- **Fenrir (RM-DR-125):** A. Stufe +1 in jeder Morgenauflösung, in der er lebt; ab Stufe 3 überlebt er einmal jeden Tod außer Spielleiterkorrekturen (auch Lynch und Ritter). Eine Wiederbelebung setzt Stufe und Schutz zurück.
- **Cerberus (RM-DR-135):** A. +1 Kopf in jeder Morgenauflösung, in der er lebt (höchstens 3). Wird er mit 3 Köpfen hingerichtet, fragt die App „abwehren?“: Ja → er überlebt, Köpfe auf 0, die Hinrichtung des Tages gilt als erfolgt. Nur Hinrichtungen.
- **Henker, Zählung (RM-DR-130.1/.2):** A. Jede bestätigte Hinrichtung der Partie zählt, auch ohne Tod (Spiegelung, Cerberus-Abwehr, Parasit), auch vor dem Rollenerwerb.
- **Henker, Markierung (RM-DR-130.3):** A. Ab drei Hinrichtungen markiert er jede Nacht freiwillig eine Person; sie stirbt zusätzlich bei der Hinrichtung des folgenden Tages, wenn der Henker dabei lebt; sonst verfällt die Markierung.
- **Selbstmörder und Henker (RM-DR-138.2):** A. Nur die Hinrichtung der Person selbst zählt; ein zusätzlicher Henker-Tod ist keine Hinrichtung des Selbstmörders.

## Rollenaudit · Informationsrollen · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs I-01 bis I-15). Freitext wörtlich mit Auslegung. Es gelten die Querschnittsentscheidungen (Blockade nur aktiver Dorf-Nachtschritte, Wiederbelebung setzt begrenzte Einsätze zurück, Nachttode in der Morgenauflösung mit sofortigem Verlust weiterer Nachtschritte).

- **Traumdeuter (I-01, RM-DR-129.1/.2):** Antwort „Der Spielleiter wählt die 3 Personen aus, hat aber einen Reminder, mindestens 1 Wolf zu wählen. Anzeige wird erst freigegeben, wenn mindestens 1 Wolf drunter ist und insgesamt 3 Spieler.“ Auslegung: Jede Nacht wählt der Spielleiter genau drei andere lebende Personen; die Bestätigung ist erst möglich, wenn mindestens eine davon als Wolf zählt.
- **Traumdeuter, Anzeige (I-05):** A. Zwei oder drei Wölfe sind zulässig; der Traumdeuter erfährt nur „unter diesen dreien ist mindestens ein Wolf“, keine Anzahl.
- **Wolfsbegriff von Traumdeuter und Kopfgeldjäger (I-02, RM-DR-129.3, RM-DR-139.4):** A. Es zählt die wahre Wolfszählung (`counts_as_wolf`); die Scheinrolle des Trugbilderwolfs täuscht nur Rollenauskünfte. Verfluchte des Dämonischen Wolfs werden mit dessen Entscheidung geklärt.
- **König (I-03, RM-DR-140.1/.2):** A. Einmal je Leben in der ersten Nacht, in der strikt mehr Personen tot sind als leben; er erfährt eine andere lebende Person der aktuellen Fraktion Dorf mit ihrer wahren Rolle; der Spielleiter wählt sie aus.
- **Kopfgeldjäger (I-04, RM-DR-139.1/.2/.3):** A. Jeder Lynch-Tod einer Person, die als Wolf zählt, während er lebt und die Rolle hat, ergibt eine Liste in einer folgenden Nacht (Zähler). Spiegelung und Cerberus-Abwehr sind kein Lynch-Tod eines Wolfs. Er selbst ist nie in der Liste. Reichen die Ziele nicht, verfällt die Liste mit Hinweis.
- **Kopfgeldjäger, Liste (I-06):** A. Wie beim Traumdeuter: der Spielleiter wählt drei andere lebende Personen, Freigabe ab mindestens einem Wolf, Anzeige „mindestens ein Wolf“.
- **Kriegerin des Lichts (I-07, RM-DR-152):** A. Einmal je Leben, freiwillig, Ziel eine andere lebende Person; die App prüft die wahre Wolfszählung und nur die Kriegerin erfährt das Ergebnis. Der getroffene Wolf überlebt. Ist das Ziel kein Wolf, stirbt die Kriegerin in der Morgenauflösung.
- **Blutpriester (I-08, RM-DR-128):** A. Einmal je Leben, freiwillig; das Opfer stirbt in der Morgenauflösung (kein Wolfsangriff, Schutzengel wirkt nicht). Der Spielleiter wählt 0 bis 3 lebende Wölfe, deren Namen nur der Blutpriester erfährt.
- **Blutpriester, Opfer (I-13):** A. Nur eine andere lebende Person (auch ein Wolf).
- **Amalia (I-09, RM-DR-151):** A. Tagesaktion, solange mindestens drei lebende Personen als Wolf zählen; sie stirbt sofort, der Spielleiter beantwortet ihre öffentliche Frage wahrheitsgemäß mit Ja oder Nein, die App protokolliert die Antwort.
- **Detektiv (I-10, RM-DR-153.1–.3):** A. Stirbt eine Person, die als Wolf zählt, während ein Detektiv lebt, und lebt danach mindestens ein anderer Wolf, wird öffentlich verkündet, in welcher Richtung vom Platz des Toten der nächste lebende Wolf sitzt (Abstand einschließlich toter Plätze, links = Uhrzeigersinn, bei Gleichstand „beide Seiten gleich weit“). Tag sofort, nachts in der Morgenauflösung; ein Hinweis je Wolfstod, unabhängig von der Zahl der Detektive.
- **Detektiv und Wolfskind (I-14):** A. Maßgeblich ist der Zustand direkt nach den unmittelbaren Todesfolgen: ein durch denselben Tod verwandeltes Wolfskind zählt als anderer Wolf.
- **Die Ewigen, Prüfung (I-11, RM-DR-104.2):** A. Jede Nacht ein gemeinsamer Schritt aller lebenden Ewigen; sie prüfen eine andere lebende Person und erfahren nur Ja (Einzelsiegrolle) oder Nein.
- **Die Ewigen, Mitsieg (I-12, RM-DR-104.1/.3):** A. Sie bleiben Dorf. Gewinnt eine von ihnen mit Ja geprüfte Person einen Einzelsieg, gewinnen alle Ewigen mit, lebend oder tot.
- **Die Ewigen, Bindung (I-15):** A. Der Mitsieg gilt nur der mit Ja geprüften Person, nicht deren Rolle.

## Rollenaudit · Schutzrollen · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs S-01 bis S-14). Freitext wörtlich mit Auslegung. Es gelten die Querschnittsentscheidungen: Wolfsangriff = Rudelangriff einschließlich zweitem Rudelschritt (RM-DR-004), Durchdringung durchdringt Schutzengel, Waldhexenrettung, Dorfwache und die Rettung des Weisen, nicht Ersatzopfer (RM-DR-005), Wiederbelebung setzt begrenzte Einsätze zurück.

- **Der Weise, Fluch (S-01, RM-DR-114.1/.2):** Antwort „Alle Dorfbewohner Fähigkeiten Tag und Nacht und Spielleiter wählt 0–3 aus basierend nach seinem Ermessen.“ Auslegung: Wird der Weise gelyncht, legt der Spielleiter bei der Hinrichtung 0 bis 3 fest; so viele folgende Nächte und Tage (ab der folgenden Nacht) haben alle Personen der Fraktion Dorf keine Fähigkeiten. 0 bedeutet kein Fluch. Nur ein Lynch-Tod des Weisen löst aus.
- **Der Weise, Umfang (S-05, RM-DR-114.4):** B. Wirklich alles ruht: aktive Nacht- und Tagesfähigkeiten, passive Fähigkeiten (z. B. Dorfwache, Nachtwächter, Detektiv, Wahnsinniger Kutscher, Wächter am Tor, Rettung des Weisen), Todesreaktionen (Sensenträger, Ritter) und auch Wolfskind-Verwandlung und Lehrling-Erbe von Dorfpersonen.
- **Der Weise, ausgelöste Wirkungen im Fluch (S-09):** A. Sie entfallen endgültig und werden nicht nachgeholt.
- **Der Weise, erster Angriff (S-02, RM-DR-114.3):** A. Seine Rettung wird nur verbraucht, wenn der Rudelangriff ihn sonst getötet hätte; still, nur der Spielleiter erfährt es; einmal je Leben. Durchdringung tötet ihn (RM-DR-005).
- **Mehrere Schutzwirkungen (S-10):** Antwort „Es gibt eine Rangfolge: einmalige Schutzschilde lösen nach wiederholten aus, z. B. würde erst der Schutz des Schutzengels brechen, bevor der der Waffe oder die Passive des Weisen.“ Auslegung: Wiederholbare Schutzwirkungen (Schutzengel, Waldhexenrettung, Dorfwache) greifen zuerst und verbrauchen keine einmalige Wirkung; nur wenn keine greift, rettet genau eine einmalige Wirkung.
- **Reihenfolge einmaliger Schutzwirkungen (S-11):** A. Schmiedewaffe, dann Schild des Schutzgeists, zuletzt die Rettung des Weisen.
- **Märtyrerin (S-03, RM-DR-118.1/.3):** A. Sie wird am Ende der Nacht gefragt, nur wenn das Rudelopfer tatsächlich stürbe; opfert sie sich, stirbt sie statt des Opfers (Ersatzopfer). Blockaden verhindern das nicht; der Fluch des Weisen schon (S-05).
- **Märtyrerin, mehrere Opfer (S-14, RM-DR-118.2):** B. Nur das erste Rudelopfer (erster Rudelschritt) ist rettbar.
- **Schutzgeist (S-04, RM-DR-148.1–.4):** A. In der ersten Nacht nach ihrem Tod (ausdrückliche Ausnahme zu G-PH-2) wählt sie eine lebende Person; das Schild wirkt ab der folgenden Nacht bis zum nächsten Rudelangriff auf diese Person, nur gegen Rudelangriffe, und bricht bei Durchdringung wie der Schutzengel. Wählt sie einen Wolf (wahre Wolfszählung), wird am Morgen öffentlich ohne Namen verkündet, dass sie einen Wolf gewählt hat.
- **Dorfschmied (S-06, RM-DR-154.1–.3):** A. Ab der 6. Nacht der Partie wird er jede Nacht gefragt, ob er die Waffe jetzt einer anderen lebenden Person gibt, bis er sie gegeben hat (einmal je Leben). Die Waffe wehrt den nächsten Rudelangriff auf den Träger ab, auch einen durchdringenden, und der Spielleiter wählt einen lebenden Wolf, der dabei stirbt.
- **Gaben (S-12):** A. Schild und Waffe bleiben nach dem Tod des Gebers bestehen und wirken auch während des Fluchs des Weisen.
- **Verdammniswächter, Wirkung (S-07, RM-DR-115.1/.2):** Antwort „Es wird trotzdem als Rudelangriff behandelt; auch wenn er die andere Person wählen würde: ist auf dieser der Schutz des Schutzengels oder ist er der Weise, überlebt er.“ Auslegung: Das Urteil lenkt den Rudelangriff um. Wählt er die angebotene Person, wird sie statt des Rudelopfers vom Rudel angegriffen; alle Regeln des Rudelangriffs gelten (Schutz, Durchdringung, Ritter, Märtyrerin, Tod am Morgen). Der Rollentext „umgeht alle Schutzfähigkeiten“ gilt damit nicht.
- **Verdammniswächter, Angebot (S-08, RM-DR-115.3):** B. Die App zieht über den gespeicherten Seed eine lebende Person, die nicht als Wolf zählt, außer dem Rudelopfer und ihm selbst.
- **Verdammniswächter, zwei Rudelopfer (S-13):** A. Das Urteil betrifft nur das erste Rudelopfer.
- **Verdammniswächter als Rudelopfer (S-15, durch den Fuzztest gefunden):** B. Ist er selbst das Rudelopfer, entfällt sein Urteil in dieser Nacht; der Angriff trifft ihn.

## Rollenaudit · Bindungsrollen · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs B-01 bis B-08, R-01 bis R-04). Es gelten: Todesfolgen ohne Entscheidung wirken sofort (RM-DR-009.1 = A), eine durch einen Tod beendete Bindung bleibt nach Wiederbelebung beendet (RM-DR-011.2), Nachttode mit Markierung in der Morgenauflösung.

- **Loki, Zeitpunkt (B-01):** B. Nur in Nacht 1 der Partie (wie RM-DR-014); verpasst er sie, verfällt die Fähigkeit.
- **Loki, Wahl (B-05):** B. Freiwillig; wählt er, dann zwei verschiedene lebende Personen, er selbst erlaubt, als Liebende oder Rivalen. Stirbt ein Liebender, stirbt der andere sofort an Liebeskummer (eigene Ursache; Schutz gegen den Rudelangriff hilft nicht, persönliche Schilde schon).
- **Loki, Rivalen (B-02, RM-DR-101.1):** A. Rivalen haben keine eigene Wirkung; sie zählen nur für die Schwarze Witwe.
- **Schwarze Witwe, Wirkung (B-03):** A. Jede Nacht wählt sie eine andere lebende Person; gehört diese zu einem lebenden Liebes- oder Rivalenpaar, erhalten beide eine Todesmarkierung und sterben in der Morgenauflösung (Ursache Schwarze Witwe); sie wachen in dieser Nacht nicht mehr auf.
- **Schwarze Witwe, Setup und Paar (B-06, RM-DR-113.1):** A. Die Pflicht „Loki im Spiel“ kommt mit der vertagten Setup-Prüfung; im Regelkern wirkt ihre Wahl nur, wenn Ziel und Partner leben. RM-DR-113.2 (Zeitwächter) wird mit dem Zeitwächter entschieden.
- **Schattenwanderer (B-04, B-07, RM-DR-110):** A. Jede Nacht bis zur Nutzung (einmal je Leben) verknüpft er sich mit einer anderen lebenden Person. Stirbt einer von beiden tatsächlich (nach allen Schutzwirkungen und persönlichen Schilden), stirbt stattdessen der andere mit der ursprünglichen Ursache und Quelle; danach ist die Verknüpfung verbraucht. Spielleiterkorrekturen werden nicht umgelenkt.
- **Rotkäppchen, Zuflucht und Kette (R-01, RM-DR-137.1/.3/.4/.5):** A. Jede Nacht fragt sie eine andere lebende Person (auch Wölfe, die ablehnen dürfen); gewährt die Person Zuflucht, erhält sie einen Apfel und ist mit Rotkäppchen verkettet: stirbt eine von beiden, stirbt die andere sofort mit. Die Kette gilt bis zur nächsten gewährten Zuflucht; eine Ablehnung löst nichts; dieselbe Person darf wieder gefragt werden.
- **Rotkäppchen, Apfel (R-02, RM-DR-137.2):** B. Der nächste eigene Nachtschritt, den die Rolle jede Nacht hat, läuft direkt ein zweites Mal. Einmal- und Ladungsfähigkeiten und passive Rollen: der Apfel ist wirkungslos.
- **Rotkäppchen, Apfeldauer (R-03):** A. Der Apfel gilt nur in der folgenden Nacht; ungenutzt verfällt er; höchstens ein Apfel je Person.
- **Apfel bei Rollen mit nur einem Ergebnis (R-04):** A. Für Korrupten Richter, Parasit, Verdammniswächter und Rotkäppchen ist der Apfel wirkungslos.
- **Bindungen im Fluch des Weisen (B-08):** A. Liebeskummer und Rotkäppchens Todeskette wirken wie Gaben (S-12) auch während des Fluchs.
