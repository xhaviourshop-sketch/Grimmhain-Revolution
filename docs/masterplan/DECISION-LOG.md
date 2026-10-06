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
- **Loki, Wahl (B-05, ersetzt durch DA-Nachtschritte-neu: immer genau 2):** B. Freiwillig; wählt er, dann zwei verschiedene lebende Personen, er selbst erlaubt, als Liebende oder Rivalen. Stirbt ein Liebender, stirbt der andere sofort an Liebeskummer (eigene Ursache; Schutz gegen den Rudelangriff hilft nicht, persönliche Schilde schon).
- **Loki, Rivalen (B-02, RM-DR-101.1):** A. Rivalen haben keine eigene Wirkung; sie zählen nur für die Schwarze Witwe. *Ersetzt durch DA-96: Rivalen können nicht gewinnen, solange der andere lebt.*
- **Schwarze Witwe, Wirkung (B-03):** A. Jede Nacht wählt sie eine andere lebende Person; gehört diese zu einem lebenden Liebes- oder Rivalenpaar, erhalten beide eine Todesmarkierung und sterben in der Morgenauflösung (Ursache Schwarze Witwe); sie wachen in dieser Nacht nicht mehr auf.
- **Schwarze Witwe, Setup und Paar (B-06, RM-DR-113.1):** A. Die Pflicht „Loki im Spiel“ kommt mit der vertagten Setup-Prüfung; im Regelkern wirkt ihre Wahl nur, wenn Ziel und Partner leben. RM-DR-113.2 (Zeitwächter) wird mit dem Zeitwächter entschieden.
- **Schattenwanderer (B-04, B-07, RM-DR-110):** A. Jede Nacht bis zur Nutzung (einmal je Leben) verknüpft er sich mit einer anderen lebenden Person. Stirbt einer von beiden tatsächlich (nach allen Schutzwirkungen und persönlichen Schilden), stirbt stattdessen der andere mit der ursprünglichen Ursache und Quelle; danach ist die Verknüpfung verbraucht. Spielleiterkorrekturen werden nicht umgelenkt.
- **Rotkäppchen, Zuflucht und Kette (R-01, RM-DR-137.1/.3/.4/.5):** A. Jede Nacht fragt sie eine andere lebende Person (auch Wölfe, die ablehnen dürfen); gewährt die Person Zuflucht, erhält sie einen Apfel und ist mit Rotkäppchen verkettet: stirbt eine von beiden, stirbt die andere sofort mit. Die Kette gilt bis zur nächsten gewährten Zuflucht; eine Ablehnung löst nichts; dieselbe Person darf wieder gefragt werden.
- **Rotkäppchen, Apfel (R-02, RM-DR-137.2):** B. Der nächste eigene Nachtschritt, den die Rolle jede Nacht hat, läuft direkt ein zweites Mal. Einmal- und Ladungsfähigkeiten und passive Rollen: der Apfel ist wirkungslos.
- **Rotkäppchen, Apfeldauer (R-03):** A. Der Apfel gilt nur in der folgenden Nacht; ungenutzt verfällt er; höchstens ein Apfel je Person.
- **Apfel bei Rollen mit nur einem Ergebnis (R-04):** A. Für Korrupten Richter, Parasit, Verdammniswächter und Rotkäppchen ist der Apfel wirkungslos.
- **Bindungen im Fluch des Weisen (B-08):** A. Liebeskummer und Rotkäppchens Todeskette wirken wie Gaben (S-12) auch während des Fluchs.

## Rollenaudit · Verwandlungsrollen · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs V-01 bis V-07). Es gelten: Wächter am Tor blockiert jeden Weg zu einem neuen Wolf außer Korrekturen (RM-DR-149), Scheinrollen täuschen nur Rollenauskünfte (Doktor, I-02), Todesreaktionen über die Warteschlange (DR-09), Rollenwechsel mit frischen Einsätzen wie beim Lehrling.

- **Dämonischer Wolf, Auslöser (V-01, RM-DR-122.1/.3):** A. Todesreaktion bei jedem Tod mit Todesfolgen: er wählt eine andere lebende Person (auch einen Wolf) oder verzichtet; einmal je Leben.
- **Dämonischer Wolf, Wirkung (V-02, RM-DR-122.2):** A. Nur Rollenauskünfte (Orakel) zeigen die verfluchte Person als Werwolf; Zählungen, Ja/Nein-Prüfungen, Wirkungen und Siege bleiben wahr.
- **Dämonischer Wolf, Dauer (V-07):** A. Der Fluch bleibt, bis die Person ihre Rolle wechselt (Erbe, Tausch, Lykaon, Korrektur); eine Wiederbelebung löscht ihn nicht.
- **König Lykaon (V-03, RM-DR-107.1/.2):** A (Zeitpunkt ersetzt durch V-08/V-09). Nur wenn ein anderer Wolf lebt: er nennt einen verbündeten lebenden Wolf (wird protokolliert) und wählt eine lebende Person der Fraktion Dorf; sie wird Trugbilderwolf mit ihrer alten Rolle als Scheinrolle und wacht ab der folgenden Nacht mit dem Rudel. Ein lebender Wächter am Tor macht sie stattdessen zum Dorfbewohner.
- **König Lykaon, Verzicht (V-08, V-09):** Antwort „Neue Regelung: er darf bis zu 3x verzichten und es verschieben.“ Auslegung mit V-09 = A: Ab Nacht 1 wird er jede Nacht gefragt, bis er verwandelt hat (einmal je Leben); er darf höchstens dreimal verzichten, bei seiner vierten Gelegenheit muss er wählen. Eine Nacht, in der sein Schritt mangels lebendem Verbündeten entfällt, zählt nicht.
- **Seelentauscher, Zustand (V-04, RM-DR-127.1):** A. Beide erhalten die neue Rolle wie beim Lehrling-Erbe: frische Einsätze, keine übernommenen Bindungen (Wolfskind ohne Vorbild, Lehrlingsbindung endet); eine Pflicht-Scheinrolle (Trugbilderwolf) wandert mit.
- **Seelentauscher, Ablauf (V-05, RM-DR-127.3):** A. Jede Nacht bis zur Nutzung (einmal je Leben) zwei verschiedene Personen, lebend oder tot, er selbst erlaubt; lebende Betroffene erfahren ihre neue Rolle sofort privat.
- **Seelentauscher und Wächter am Tor (V-06, RM-DR-127.2):** A. Auch eine tote Person, die eine Wolfsrolle erhielte, wird Dorfbewohner, solange ein Wächter am Tor lebt.

## Rollenaudit · Wiederbelebungsrollen · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs W-01 bis W-04). Es gelten: Wiederbelebung setzt alle begrenzten Einsätze zurück, durch Tod beendete Bindungen bleiben beendet (RM-DR-011.2), Einmal-Fähigkeiten gelten je Person (RM-DR-126.3, RM-DR-141.3), Wächter am Tor blockiert neue Wölfe (RM-DR-149).

- **Totenkarten (W-01, RM-DR-013):** A. Kutscher und Dr. Victor Frankenstein werden ohne Kartenbezug umgesetzt; Kartenbedingungen (RM-DR-141.4) und der Kartenschlucker folgen mit dem Totenkarten-Assistenten.
- **Kutscher, Rollen (W-02, RM-DR-126.1):** A. Die Wiederbelebten behalten ihre Rolle mit frischen Einsätzen; einer von ihnen wird Werwolf (ein lebender Wächter am Tor macht ihn zum Dorfbewohner).
- **Kutscher, Wahl (W-03, RM-DR-126.2):** A. Der Kutscher wählt die drei Toten und bestimmt, wer davon Wolf wird. Freiwillig, einmal je Leben, ab einer Nacht mit mindestens 10 Toten (alle zählen).
- **Dr. Victor Frankenstein (W-04, RM-DR-141.1/.2):** B. Jede Nacht bis zur Nutzung (freiwillig, einmal je Leben) belebt er eine tote Person wieder und gibt ihr eine Rolle, die gerade niemand hat (Dorfbewohner immer), keine Wolfsrolle. Die Person startet frisch, erfährt ihre Rolle privat, handelt ab der folgenden Nacht; die Wiederbelebung wird am Morgen öffentlich sichtbar. Dieselben Zeitpunkte gelten für die Wiederbelebten des Kutschers.

## Rollenaudit · Einzelsiegrollen, Teil 1 · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs E-01 bis E-04). Es gelten: Siegbedingung je Rolle (RM-DR-006 = A), gleichzeitige Siege werden gemeinsam vorgeschlagen (DR-02), ein erfüllter Sieg wird nach Ablehnung weiter vorgeschlagen (F-11), Blockaden treffen nur Dorfrollen (RM-DR-010), Zustände ohne Fähigkeitscharakter bleiben bei Wiederbelebung, der Apfel verdoppelt Jede-Nacht-Schritte (R-02).

- **Rattenfänger (E-01, RM-DR-103.1/.2):** A. Jede Nacht verzaubert er 1 oder 2 andere lebende, noch unverzauberte Personen; die Verzauberung bleibt dauerhaft, eine Voodoo-Puppe hebt nichts auf. Er gewinnt, wenn er lebt und alle anderen Lebenden verzaubert sind, bei jeder Siegprüfung (auch nach einem Tod).
- **Pestbringerin (E-02, RM-DR-120.1–.4):** A. Nicht tödlich. Jede Nacht infiziert sie eine andere lebende, noch gesunde Person; zu Beginn jeder Morgenauflösung steckt jede lebende Infizierte einen zufällig gezogenen nächsten lebenden Nachbarn an (gespeicherter Seed, tote Plätze übersprungen). Sie gewinnt, wenn sie lebt und alle anderen Lebenden infiziert sind.
- **Prophet des Untergangs (E-03, RM-DR-121.1–.3):** C. In Nacht 1 markiert er drei andere Lebende; sind alle drei tot, ist er dauerhaft freigeschaltet und darf jede Nacht freiwillig eine Person töten (Tod am Morgen, eigene Ursache, Rudelschutz wirkt nicht, persönliche Schilde schon). Lebt er freigeschaltet, wenn kein Wolf mehr lebt, gewinnt er allein statt des Dorfes.
- **Todesprediger (E-04, RM-DR-158.1–.3):** A. Nur in Nacht 1 legt er geheim beim Spielleiter eine künftige Nacht oder einen Tag fest (Tag N folgt auf Nacht N; Tode der Morgenauflösung zählen zur Nacht N). Stirbt er genau dann (jede Todesart außer Korrektur ohne Todesfolgen), ist sein Sieg erfüllt und wird wie beim Selbstmörder fortan vorgeschlagen.

## Rollenaudit · Einzelsiegrollen, Teil 2 (Feuerteufel) · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs E-05 bis E-08, jeweils die Empfehlung) und am selben Tag in einem eigenen Auswahlfenster ausdrücklich als beabsichtigte Entscheidungen bestätigt. Verbindlich sind die stabilen IDs RM-DR-131.1 bis .5; die Antworten gelten nur für den Feuerteufel, nicht für Voodoo-Priester oder Nekromant.

*Historischer Hinweis zu den Frage-IDs:* Eine abgebrochene frühere Sitzung hatte E-05 bis E-08 anders zugeschnitten vorbereitet (E-05 Feuerteufel-Wirkung, E-06 Sieg von Feuerteufel und Voodoo-Priester, E-07 Voodoo-Puppe, E-08 Nekromant-Schild). Diese Fragen wurden nie beantwortet. Ab hier bezeichnen E-05 bis E-08 ausschließlich die folgenden Feuerteufel-Fragen; Voodoo und Nekromant folgen ab E-12 (E-09 bis E-11 sind Ergänzungsfragen zum Feuerteufel).

Es gelten weiter: nächste lebende Nachbarn links und rechts (RM-DR-003, damit ist RM-DR-131.3 entschieden), „Wolfsangriff“ heißt nur Rudelangriff (RM-DR-004), Siegbedingung je Rolle (RM-DR-006), gleichzeitige Siege gemeinsam (DR-02).

- **Feuerteufel, Auslöser (E-05, RM-DR-131.1):** A. Jeder tatsächliche Tod des markierten Ziels löst den Brand aus, gleich welche Ursache (Rudel, Hinrichtung, Gift, Brand, andere Rollen, Spielleiterkorrektur mit Todesfolgen); nicht bei Korrektur ohne Todesfolgen. Überlebt das Ziel, brennt nichts (Legacy-Fehler entfällt). Es verbrennen die nächsten lebenden Nachbarn links und rechts.
- **Feuerteufel, Dauer (E-06, RM-DR-131.2):** A. Jeder Feuerteufel hat höchstens eine aktive Markierung; sie gilt, bis er ein neues Ziel wählt oder das Ziel stirbt.
- **Feuerteufel als Nachbar (E-07, RM-DR-131.4):** A. Jeder Feuerteufel (auch weitere Kopien) wird als Nachbar immer verschont; auf dieser Seite brennt niemand, kein Ersatz.
- **Feuerteufel, Sieg (E-08, RM-DR-131.5):** A. Lebt er, wenn ein Sieg erfüllt ist, gewinnt er zusätzlich zur siegreichen Seite (Mitsieg wie bei den Ewigen); kein Alleinsieg, keine eigene Siegprüfung.
- **Feuerteufel, Wahl je Nacht (E-09, RM-DR-131.6):** A. Jede Nacht darf er ein neues Ziel wählen oder die bestehende Markierung behalten; Ziel ist immer eine andere lebende Person, nie er selbst. (Ergänzungsfrage nach der Bestätigung von E-05 bis E-08.)
- **Feuerteufel, Nachwirkung (E-10, RM-DR-131.7):** A. Stirbt der Feuerteufel oder verliert er die Rolle (Seelentausch, Korrektur, andere Rollenwechsel), erlischt seine Markierung sofort.
- **Mehrere Feuerteufel, gleiches Ziel (E-11, RM-DR-131.8):** A. Der Tod einer mehrfach markierten Person löst genau einen Brand aus; alle Markierungen auf ihr sind verbraucht.

## Rollenaudit · Einzelsiegrollen, Teil 3 (Voodoo-Priester, Nekromant) · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs E-12 bis E-19, jeweils die Empfehlung). Die Antworten gelten nur für die genannte Rolle. Es gelten weiter: „Wolfsangriff“ heißt nur Rudelangriff (RM-DR-004), Durchdringung (RM-DR-005), Siegbedingung je Rolle (RM-DR-006), gleichzeitige Siege gemeinsam (DR-02), ein erfüllter Sieg wird nach Ablehnung weiter vorgeschlagen (F-11), Spielleiterkorrekturen sind von Schutz- und Umlenkregeln ausgenommen. RM-DR-132.3 ist durch E-01 entschieden (die Puppe hebt keine Verzauberung auf).

- **Voodoo-Priester, Umlenkung (E-12, RM-DR-132.1):** A. Jeder tatsächliche Tod des Priesters außer Spielleiterkorrektur trifft stattdessen die lebende Puppe (Rudel, Hinrichtung, Gift, Brand und alle übrigen Ursachen). Umgelenkt wird nur, wenn er tatsächlich stürbe, also nach allen Schutzwirkungen, wie beim Schattenwanderer (B-04, B-07).
- **Voodoo-Priester, Neuvergabe (E-13, RM-DR-132.2):** A. Keine Abklingzeit. Höchstens eine lebende Puppe je Priester; ist keine mehr da, darf er in der nächsten Nacht eine neue vergeben. Ohne lebende Puppe stirbt er selbst.
- **Voodoo-Priester, Vergabe (E-14, RM-DR-132.5):** A. Die Puppe ist eine andere lebende Person, nie er selbst. Geheim: nur der Spielleiter weiß es; die Puppe erfährt es nicht vorab.
- **Voodoo-Priester, Sieg (E-15, RM-DR-132.4):** A. Er gewinnt allein, wenn er lebt und höchstens drei Personen leben (wie der Parasit).
- **Nekromant, Schild (E-16, RM-DR-142.1):** A. Mit mindestens drei geopferten Toten (E-18) errichtet er nachts einen globalen Schild: Er verhindert den nächsten Tod irgendeiner Person, gleich welche Ursache, auch eine Hinrichtung, und verfällt ungenutzt mit Beginn der nächsten Nacht.
- **Nekromant, Umlenkung (E-17, RM-DR-142.2):** A. Nur beim Rudelangriff auf ihn darf er freiwillig drei Tote opfern und den Angriff auf eine andere lebende Person umlenken, auch auf einen Wolf; für das neue Ziel gilt es als Rudelangriff (dessen Schutz wirkt). Verzicht: Er stirbt.
- **Nekromant, Vorrat (E-18, RM-DR-142.3):** A. Jede tote Person kann insgesamt nur einmal geopfert werden, für Schild oder Umlenkung (gemeinsamer Vorrat).
- **Nekromant, Wolf benennen (E-19, RM-DR-142.4, RM-DR-142.5):** A. Höchstens ein Versuch pro Tag, geheim beim Spielleiter; ein Treffer ist jede lebende Person, die als Wolf zählt (`counts_as_wolf`, RM-DR-002.2; der Fluch des Dämonischen Wolfs betrifft nur Rollenauskünfte). Dann ist sein Alleinsieg erfüllt. Ein Fehlversuch hat keine Folgen. Die Legacy-Übungsenthüllung entfällt (RM-DR-142.5).
- **Umlenkungsketten (E-20, RM-DR-132.6):** A. Gilt für alle Umlenkungen (Voodoo-Puppe, Schattenwanderer, Nekromant). Eine Kette leitet weiter, aber nie auf eine Person, die in dieser Kette schon betroffen war; dann stirbt die aktuelle Person. Jede ausgeführte Umlenkung verbraucht ihre Verknüpfung. (Ergänzungsfrage bei der Umsetzung.)
- **Voodoo-Priester, Vergabe freiwillig (E-21, RM-DR-132.7):** A. In jeder Nacht ohne lebende Puppe darf er eine andere lebende Person wählen oder verzichten.
- **Voodoo-Priester, Rollenverlust (E-22, RM-DR-132.8):** A. Verliert der Priester die Rolle, endet seine Puppe sofort; ein neuer Priester beginnt ohne Puppe.
- **Vorrang zweier Umlenkungen (E-23, RM-DR-132.9):** A. Die eigene Fähigkeit der sterbenden Person wirkt vor einer fremden Verknüpfung: Ist ein Priester zugleich mit einem Schattenwanderer verknüpft, stirbt zuerst seine Puppe; die Verknüpfung bleibt bestehen.
- **Nekromant, Mehrere Nekromanten (E-24, RM-DR-142.6):** A. Jede tote Person kann in der ganzen Partie nur einmal geopfert werden, gleich von welchem Nekromanten; jeder errichtete Schild verhindert genau einen Tod (zwei Schilde, zwei verhinderte Tode). (Ergänzungsfrage bei der Umsetzung.)
- **Nekromant, Reihenfolge der Umlenkung (E-25, RM-DR-142.7):** A. Der Nekromant entscheidet nach dem Urteil des Verdammniswächters und vor der Märtyrerin (Legacy-Stufe 3.0); die Märtyrerin sieht das endgültige Rudelopfer. (Ergänzungsfrage bei der Umsetzung.)
- **Nekromant, Anlass der Umlenkung (E-26, RM-DR-142.8):** A. Gefragt wird nur, wenn der Rudelangriff ihn sonst töten würde; greift ein Schutz, ein persönlicher Schild oder ein aktiver Nekromanten-Schild, gibt es keine Umlenkung. (Ergänzungsfrage bei der Umsetzung.)
- **Nekromant, Schild nach Rollenverlust oder Tod (E-27, RM-DR-142.9):** A. Verliert der Nekromant die Rolle oder stirbt er, erlischt sein noch ungenutzter Schild sofort (wie Markierung E-10 und Puppe E-22). (Ergänzungsfrage bei der Umsetzung.)

## Rollenaudit · Einzelsiegrollen, Teil 4 (Hades, Grabräuber) · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (Fragen-IDs E-28 bis E-34, jeweils die Empfehlung). Die Antworten gelten nur für die genannte Rolle. Es gelten weiter: Spielleiterkorrekturen sind von Rollenwirkungen ausgenommen, Stimmen werden nicht digital gezählt (RM-DR-008), Siegbedingung je Rolle (RM-DR-006), gleichzeitige Siege gemeinsam (DR-02), ein erfüllter Sieg wird weiter vorgeschlagen (F-11).

- **Hades, Lichter (E-28, RM-DR-144.2):** A. Jeder tatsächliche Tod einer anderen Person außer Spielleiterkorrektur gibt jedem lebenden Hades 1 Licht (eigener Vorrat je Person), auch seine eigenen Tötungen; abgefangene Tode geben nichts.
- **Hades, Sieg (E-29, RM-DR-144.1):** A. Lebt er mit mindestens 10 Lichtern, ist sein Alleinsieg erfüllt und wird bei jeder Siegprüfung vorgeschlagen (F-11); kein Einlösen.
- **Hades, Tötung (E-30, RM-DR-144.4):** A. Für 2 Lichter höchstens einmal je Nacht eine andere lebende Person töten: Tod am Morgen mit eigener Ursache (wie Prophet des Untergangs), Rudelschutz wirkt nicht, persönliche Schilde schon; die Lichter sind auch bei abgefangenem Tod verbraucht.
- **Hades, Barriere (E-31, RM-DR-144.3):** A. Barriere für 3 Lichter: höchstens eine aktive, verhindert seinen nächsten Tod jeder Ursache außer Korrektur (auch Hinrichtung), kein Verfall, danach neu kaufbar. „Stimme x3“ entfällt (Stimmen werden nicht digital gezählt, RM-DR-008).
- **Grabräuber, Stehlen (E-32, RM-DR-156.1):** A. Einmalig wählt er nachts eine tote Person; ab der nächsten Nacht hat er dauerhaft deren Nachtfähigkeit (eigener Schritt, frische Einsätze) und bleibt Grabräuber mit eigener Siegbedingung.
- **Grabräuber, Sieg (E-33, RM-DR-156.2):** A. Er gewinnt allein, wenn er lebt und höchstens drei Personen leben (wie Parasit und Voodoo-Priester).
- **Grabräuber, Umfang (E-34, RM-DR-156.3):** A. Wählbar ist jede tote Person mit eigenem Nachtschritt, auch Wolfs- und Einzelsiegrollen; er beginnt mit frischen Einsätzen, ohne Zähler oder Zustände der Toten. Rollen ohne eigenen Nachtschritt sind nicht wählbar.

## Rollenaudit · Hades und Grabräuber, abgeleitete Präzisierungen · 28. September 2026

Technisch/fachlich abgeleitet unter delegierter Autorisierung (Auftrag vom 28.09.2026: kleinere Regellücken selbst entscheiden, zentrale Idee erhalten). Der Product Owner hat zu diesen Punkten **keine** Auswahlfrage beantwortet. Keine frühere Entscheidung wird ersetzt. Nachweise: `godot/tests/unit/test_hades.gd`, `test_grave_robber.gd`, `test_solo_combinations.gd`, Fuzztest.

- **DA-01 Hades, Zeitpunkt:** vorher offen (nur Legacy-Stufe 9.9); jetzt: Hades handelt als letzter Nachtschritt (Priorität 99). Begründung: Legacy-Reihenfolge, keine Wechselwirkung mit Schritten nach ihm.
- **DA-02 Hades, Tötung und Barriere in einer Nacht:** vorher offen; jetzt: in seinem Schritt zuerst keine oder eine Tötung, danach, wenn mit den übrigen Lichtern möglich und keine Barriere aktiv ist, die Frage nach der Barriere. Bezahlt wird erst mit der letzten Antwort; ein Abbruch kostet nichts. Begründung: E-30 begrenzt nur die Tötung (einmal je Nacht), E-31 nur die Zahl aktiver Barrieren.
- **DA-03 Hades, Tod und Rollenverlust:** vorher offen; jetzt: Lichter und Barriere erlöschen mit Tod oder Rollenverlust; ein neuer Hades (Lehrling, Seelentausch, Korrektur) beginnt mit 0 Lichtern. Begründung: gleiche Regel wie Markierung (E-10), Puppe (E-22) und Schild (E-27); „frische Einsätze“ (W-03).
- **DA-04 Hades, „außer Korrektur“:** jede Tötung mit Quelle Spielleiter gibt kein Licht und wird von der Barriere nicht verhindert, auch eine Spielleiter-Hinrichtung. Begründung: dieselbe Abgrenzung wie bei Voodoo-Puppe und Nekromanten-Schild.
- **DA-05 Hades, Barriere als persönlicher Schild:** Reihenfolge nach Parasit, Rudelvater und Fenrir, vor dem Nekromanten-Schild und den Umlenkungen; zählt für Märtyrerin und Nekromant als „stirbt nicht“; hält auch das durchdringende Zusatzopfer des Rudelvaters ab (E-31 „jede Ursache“; das Legacy-Verhalten `PACKFATHER_KILL` durchbricht die Barriere wird nicht übernommen). Eine von einem anderen Hades markierte Person wacht in dieser Nacht nicht mehr auf (bestehende Regel „Nachttode“), auch ein Hades.
- **DA-06 Grabräuber, stehlbare Rollen:** vorher E-34 „jede tote Person mit eigenem Nachtschritt“; präzisiert: Rollen mit wiederkehrendem eigenem Nachtschritt einer lebenden Person. Nicht wählbar: Nur-Nacht-1-Rollen (Loki, Dorfchronistin, Todesprediger) und der Prophet (markiert nur in Nacht 1), weil der Schritt nie wieder stattfände; der Schutzgeist, weil er nur tot handelt; Wolfskind und Lehrling, weil ihre Fähigkeit ein eigener Rollenwechsel ist und E-32 „bleibt Grabräuber“ widerspräche; der Grabräuber selbst (keine Schleife). Gemeinsame Schritte (Gebundene, Ewige, Rudel) sind keine eigenen Schritte. Maßgeblich ist die Rolle der toten Person zum Zeitpunkt des Diebstahls.
- **DA-07 Grabräuber, Umfang der Fähigkeit:** übernommen werden der Nachtschritt und alle Wirkungen, die er erzeugt (Puppe, Feuermarkierung samt Verschonung beim Brand, Wirt samt Immunität und Mit-Tod, Nekromanten-Schild und Umlenkung, Hades-Lichter und Barriere, Kopfgeld-Listen, Henker- und Richtermarkierung). Nicht übernommen: Siegbedingungen und Mitsiege, Fraktion, Wolfszählung, Erscheinung, Todesreaktionen und Tagesaktionen (z. B. Wolf benennen). Hades-Lichter sammelt er ab dem Diebstahl (ohne Lichter wäre der Schritt wertlos). Begründung: E-32 „Nachtfähigkeit, bleibt Grabräuber mit eigener Siegbedingung“.
- **DA-08 Grabräuber, Blockade und Fluch:** richten sich nach der handelnden Person: als Einzelsiegperson ist er weder blockierbar (RM-DR-010) noch vom Fluch des Weisen betroffen, auch mit gestohlener Dorffähigkeit. Begründung: beide Regeln sind personenbezogen formuliert („Dorfpersonen“).
- **DA-09 Grabräuber, Zeitpunkt, Tod, Rollenverlust:** der Diebstahl gilt sofort (der eigene Schritt folgt planmäßig ab der nächsten Nacht); der Grabräuber erfährt die Rolle privat. Die Fähigkeit endet mit seinem Tod oder Rollenverlust; nach einer Wiederbelebung darf er frisch erneut stehlen (frische Einsätze, W-03). Mehrere Grabräuber stehlen unabhängig, auch dieselbe Rolle.
- **DA-10 Verdammniswächter → Nekromant:** Das Urteil des Verdammniswächters bestimmt das Rudelopfer und ist kein Glied einer Umlenkungskette (E-20 nennt Puppe, Schattenwanderer, Nekromant). Wählt er den Nekromanten und würde dieser sterben, darf der Nekromant auch auf das ursprüngliche Rudelopfer umlenken. Werden Rudel- und Zusatzopfer beide auf den Nekromanten gelegt, entscheidet er einmal (sein Schritt) für den ersten Angriff, der ihn töten würde; das Zusatzopfer trifft ihn danach. Beides ist bestehendes Verhalten, jetzt durch Tests festgehalten.

## Rollenaudit · Rest-Wölfe und Zeitwächter (Rachsüchtiger Wolf, Schicksalswolf, Zeitwächter) · 28. September 2026

Vom Product Owner in der Claude-Code-Sitzung per Auswahl beantwortet (jeweils die Empfehlung):

- **Rachsüchtiger Wolf, Siegziel (E-35, RM-DR-106.1):** A. Er zählt als Wolf (Parität, Dorfsieg). Ist er beim Wolfssieg der einzige lebende Wolf, wird statt des Wolfssiegs sein Alleinsieg vorgeschlagen; leben andere Wölfe, gewinnen die Werwölfe ohne ihn.
- **Zeitwächter, Einfrieren (E-36, RM-DR-150.1–.4, RM-DR-113.2):** A. Er entscheidet als allererster Nachtschritt. Ja: alle Nachtschritte dieser Nacht entfallen für alle Rollen (auch Wölfe, Einzelsieg, Schwarze Witwe), am Morgen keine Tode aus dieser Nacht, Fenrir und Cerberus wachsen nicht. Fällige Wirkungen früherer Nächte (Giftpranke, Pest-Ausbreitung) treten ein; die Nachtnummer zählt weiter; öffentliche Meldung am Morgen.

Technisch/fachlich abgeleitet unter delegierter Autorisierung (keine Auswahlfrage des PO; Nachweise `test_fate_wolf.gd`, `test_lone_wolf_and_time_warden.gd`, `test_protection_roles.gd`, Fuzztest):

- **DA-11 Schicksalswolf, Zeitfenster (RM-DR-109.1):** vorher offen (Rollentext „in Nacht 4“, Legacy „ab Nacht 4“); jetzt: nur Nacht 4, danach verfallen (Rollentext).
- **DA-12 Schicksalswolf, erste drei Toten (RM-DR-109.3):** die ersten drei verschiedenen Personen der Partie, die sterben, jede Ursache (auch Korrektur), auch vor der Markierung; Wiederbelebte behalten ihren Platz und belegen keinen zweiten (behebt die Legacy-Doppelzählung).
- **DA-13 Schicksalswolf, Zusatzopfer (RM-DR-109.2):** Rudelangriffe am Morgen nach Rudelopfer und Zusatzopfer des Rudelvaters: Schutz wirkt, sie durchdringen nicht, der Ritter schlägt zurück, der Nekromant darf umlenken (E-17 „Rudelangriff“). Märtyrerin und Verdammniswächter betreffen weiter nur das erste Rudelopfer (S-13, S-14); die Durchdringung des Seuchenwolfs verbraucht nur das erste Rudelopfer.
- **DA-14 Schicksalswolf, Markierung und Auswahl:** nur in Nacht 1 genau drei **andere** lebende Personen (auch Wölfe; Legacy erlaubte sich selbst), eigene Markierungen je Schicksalswolf; sie erlöschen mit seinem Tod oder Rollenverlust. In Nacht 4 wählt er bis zu so viele Zusatzopfer, wie Markierte unter den ersten drei Toten sind (Verzicht möglich; Legacy verlangte genau so viele).
- **DA-15 Grabräuber:** Der Schicksalswolf ist nicht stehlbar (markiert nur in Nacht 1, wie der Prophet); Rachsüchtiger Wolf und Zeitwächter sind stehlbar.
- **DA-16 Rachsüchtiger Wolf, Rhythmus (RM-DR-106.2/.3):** vorher offen (Rollentext „jede dritte Nacht“, Legacy Abklingzeit); jetzt: feste Nächte 3, 6, 9 … (Rollentext), erste Nutzung in Nacht 3.
- **DA-17 Rachsüchtiger Wolf, Angriff:** freiwillig eine andere lebende Person, die als Wolf zählt; Tod am Morgen mit eigener Ursache `LONE_WOLF_KILL` (kein Rudelangriff: Schutzengel wirkt nicht, persönliche Schilde schon).
- **DA-18 Rachsüchtiger Wolf, mehrere:** Leben nur noch Rachsüchtige Wölfe als Wölfe (zwei oder mehr), gewinnt noch niemand; jeder will allein gewinnen.
- **DA-19 Zeitwächter, Einzelheiten:** einmal je Leben (Verzicht behält die Fähigkeit); als Dorfrolle ruht er im Fluch des Weisen; das Zusatzopfer eines gelynchten Rudelvaters gehört zur eingefrorenen Nacht und entfällt; Äpfel dieser Nacht verfallen; eine ausstehende Durchdringung des Seuchenwolfs bleibt bestehen; die öffentliche Meldung nennt keinen Namen.
- **DA-20 Schutzgeist ohne Lebende (Fehlerbehebung):** vorher öffnete der Schritt der toten Schutzgeist ohne lebende Person eine unbeantwortbare Pflichtwahl; jetzt entfällt er mit „no_decision“ wie jede Pflichtwahl ohne Ziel (Fuzzbefund, Regressionstest).

## Inhaltsentscheidungen · Wiederbelebungsrunde, Aufrufe, Todeseffekte, Hinweise · 29. September 2026

Vom Product Owner in der Claude-Code-Sitzung vom 29. September 2026 per Auswahlfenster und Freitext beantwortet. Herkunft der Fragen und Vorschläge: `docs/content-drafts/DECISIONS-TO-INTEGRATE.md` (DI-01 bis DI-09, Branch `content/rolebook-and-guide`). Freitextantworten sind wörtlich zitiert, die Auslegung ist genannt. **DI-01 und DI-03 ersetzen ältere Vorgaben ausdrücklich:** DR-04 (Rolle beim Tod nach frei wählbarer Setup-Option), G-TOD-5, B-18 (Setup-Option `reveal_role_on_death`) und den Satz „Todesursache und interne Effekte bleiben privat“ für die unten genannten Todeseffekte. Die Acceptance-Szenarien AS-M01 bis AS-M03 sind entsprechend ersetzt.

- **Wiederbelebungsrunde statt frei wählbarer Rollenaufdeckung (DI-01):** Antwort „Es gibt Charaktere und später auch totenreichkarten die spieler wiederlebe, in runden wo dies möglich ist sollen rollenakrten nicht aufgedeckt werdn und spieler müssen auch ihre augen in der nacht geschlossen halten auch wenn sie tod sind, in runden wo es keine wiederbelebung gibt müssen spieler ihre augen nachts nicht schließen und decken auch ihre rollenkarte auf.“ Auslegung: In einer Wiederbelebungsrunde wird beim Tod keine Rolle aufgedeckt und Tote schließen nachts die Augen; sonst wird die Rolle beim Tod aufgedeckt. Präzisierung durch Auswahl: „Nur direkte Rollen und Karten“. Direkte Wiederbelebungsrollen sind Kutscher und Dr. Victor Frankenstein; Totenreichkarten folgen mit dem Totenkarten-System (RM-DR-013). Erbe (Lehrling), Tausch (Seelentauscher), Diebstahl (Grabräuber) und die Spielleiterkorrektur `revive` lösen den Modus nicht aus.
- **Aufrufpolitik (DI-02):** Antwort „ES gibt zwei zenarien, bereits aufgedeckte Rollen in der Night Order werden nicht mehr aufgerufen, aufgebrauchte rollen werden trotzdem aufgerufen nur haben sie keine fähigkeiten mehr dait das dorf und die werwölfe nicht wissen was schon genutzt wurden ist und was nicht, in runden mit wiederbelebung werden auch tote rollen weiter aufgerufen damit das Dorf/Diewölfe nicht wissen wer noch lebt bzw tod ist.“ Beantwortet die offene Frage in `docs/assets/NARRATOR-SCRIPT.md` §6 Nr. 1 und ersetzt die Einstellung „Tote Rollen weiter aufrufen“ durch eine aus DI-01 abgeleitete Regel.
- **Todeseffekte werden ausgespielt und angesagt (DI-03):** Antwort zum Fluch des Weisen „Egal ob wiederbelbung oder nicht es ist ein Todeseffket alle Todeseffekt werden ausgespeilt und auch angesagt.“ Umfang durch Auswahl „Sichtbare Folgen eines Todes“, Inhalt durch Auswahl „Effekt und Rolle nennen“, auch in Wiederbelebungsrunden. Todeseffekte: Sensenträger, Ritter, Besessener Wolf, Wahnsinniger Kutscher, Fluch des Weisen, Liebeskummer, Rotkäppchen-Kette, Verknüpfung des Schattenwanderers. Geheime Wahlen ohne sichtbare Folge (Fluch des Dämonischen Wolfs, Voodoo-Puppe, Markierungen) bleiben verdeckt.
- **Loki (DI-04):** Auswahl „B: Liebende und Rivalen erfahren es“. Beide Personen des Paares erfahren privat Partner und Bindungsart.
- **Rotkäppchen (DI-05):** Antwort „Die Fähigkeiten und damit verbundenen Effekte sind allen spielern bekannt Ben darf ablehnen wenn er will denn er kennt den vorteil und nachteil“. Auswahl „Nein, anonym“: Die gefragte Person kennt Apfel und Kette und erfährt nicht, wer fragt.
- **Rattenfänger (DI-06):** Antwort „Erst gibt es eine Abfrage die NEUEN Verzauberten und dann „Alle Verzauberten““ und „Verzauberte Werden geweckt und wissen das sie von nun an verzaubert sind es gibt eine Phase nachdem Rattenfänger welche alle Neuen Verzauberten auffordert einmal kurz die augen zu öffnen“. Auswahl: In der zweiten Phase erkennen sich alle Verzauberten. Ob sie es im Dorf teilen, entscheiden sie selbst.
- **Pestbringerin (DI-07):** Antwort „beim Infizierten ebenfalls soll ein kleiner remidner kommen, das Spieler X Infiziert wurden ist und weiß was mit ihm & seinen Nachbarn geschieht wenn man ihm am Leben lässt.“ Auswahl: Jede neu infizierte Person erhält den Hinweis, auch durch die Ausbreitung am Morgen.
- **Trugbilderwolf (DI-08):** Auswahl „Nein, nur der Spielleiter“: Er erfährt seine Scheinrolle nicht.
- **Ton bei fünf Toten (DI-09):** Auswahl „Beibehalten wie entschieden“ (Eintrag „Sound bei 5 Toten“ bleibt).

Technisch/fachlich abgeleitet unter delegierter Autorisierung (keine Auswahlfrage des PO; Nachweise `test_revival_round.gd`, `test_call_policy.gd`, `test_death_effects.gd`, `test_notices.gd` und die UI-Tests):

- **DA-21 Modus im Regelkern:** `GameState.revival_round` wird bei `StartGame` aus den Startrollen abgeleitet (`RoleCatalog.REVIVAL_ROLES`) und ändert sich nie. `StartGame` lehnt `reveal_role_on_death` ab (`reveal_option_removed`). Spielstandschema 13, Regelversion 0.12; ältere Spielstände werden mit klarer Meldung abgelehnt und nicht verändert (keine Migration, wie bei jeder Schemaänderung). Das Setup zeigt den Modus nur an. Eine Setup-Warnung bei indirekten Trägern entfällt: Ohne direkte Wiederbelebungsrolle in der Besetzung kann Erbe, Tausch oder Diebstahl keine Wiederbelebung erreichen.
- **DA-22 Aufrufmenge:** Aufgerufen werden Rollen mit eigenem Nachtschritt, die eine (lebende, in Wiederbelebungsrunden auch tote) Person als Start- oder aktuelle Rolle hält, dazu Gebundene und Ewige als Gruppen. Blockierte und noch nicht aktive Rollen werden ebenfalls aufgerufen, Rollen ohne Besitzerin in der Partie nicht (abgeleitet aus DI-02, zu bestätigen). Tarnaufrufe sind reine Ansage: keine Fähigkeit, keine Ziehung, kein Verbrauch, keine gespeicherte Position (`CallPolicy`).
- **DA-23 Todeseffekt-Ereignis:** Öffentliches Ereignis `DeathEffect` direkt nach `SeatDied`, nur wenn der Tod eintritt; Positivliste Effekt, Quelle, Rolle zum Ereigniszeitpunkt, Ziel, ersetzte Person. Liebeskummer, Kette und Verknüpfung nennen keine Rolle (Mindestangabe); der Fluch des Weisen nennt seine Länge nicht. Bei einer Umlenkung durch den Schattenwanderer nennt die Wirkung die gewählte Person, danach die Verknüpfung, wer stattdessen gestorben ist.
- **DA-24 Private Hinweise:** Zustand `notices` und Befehl `AckNotice`; der Regelkern blockiert nicht, die Oberfläche zeigt offene Hinweise zuerst. Stirbt eine betroffene Person, verlässt sie den Hinweis; ohne Betrachter entfällt er. Gehört Loki selbst zum Paar, erhält auch er die Karte.
- **DA-25 Rotkäppchen-Karte:** Die Frage an die gefragte Person zeigt weder Rolle noch die fragende Person; handelnd ist die gefragte Person.

### Paket 2 (29.09.2026): technische Ableitungen, keine Nutzerantworten

Diese Einträge sind technische Umsetzungsvorgaben und Ableitungen des Auftrags „Paket 2“ (Entwicklerauftrag vom 29.09.2026). Sie sind keine früheren Antworten des Product Owners und ändern keine Rollenfähigkeit. Nachweise: `test_role_shown.gd`, `test_role_show.gd`, `test_special_corrections.gd`, `test_prompt_coverage.gd`.

- **DA-26 Persistierter Bestätigungsfortschritt der Rollenanzeige:** Befehl `ConfirmRoleShown(person_id)` und Zustand `roles_shown` (Person → Rolle zum Zeitpunkt der Bestätigung) im bestehenden Befehls- und Replay-Modell. Ein nur flüchtiger App-Zustand genügt nicht, weil der Fortschritt einen Neustart überleben muss (AS-A04). Die gespeicherte Rolle macht eine Bestätigung nach Rollenwechsel ungültig (erneut zeigbar) und verhindert eine doppelte Bestätigung derselben Rolle (`role_already_confirmed`). Unbekannte Person: `unknown_player`. Zulässig nach Spielbeginn bis Spielende, auch bei offener Reaktion oder Siegkandidat (reine Darstellung, wie `AckNotice`). Keine Pflicht vor `StartNight`, kein Zufall, keine Ressource, Ereignis nur für die Spielleitung.
- **DA-27 Schema 14, Regelversion unverändert:** Das gespeicherte Zustandsformat erhält ein neues Feld. Ohne Versionswechsel würden ältere Dateien nicht als „andere Version“ erkannt, sondern am Zustands-Hash scheitern und als beschädigt gelten. Deshalb Schema 13 auf 14, keine automatische Migration, ältere Spielstände unverändert erhalten und als inkompatibel angezeigt (bestehendes Verhalten des SaveService, zusätzlich getestet mit einem Schema-13-Stand). Die Regelversion `grimmhain-core-0.12` bleibt: Keine bestehende Regel ändert sich. Ein neuer Befehl allein hätte keinen Versionswechsel verlangt; das neue Feld tut es.
- **DA-28 Rollenkarte ohne Weitergabe des Geräts:** Die Spielleitung behält das Tablet. Neutrale Vorderseite mit Name, Rolle und Kurztext erst nach bewusster Aktion („Rolle anzeigen“ statt Halten, ohne Gerät nicht prüfbar), Bestätigung nur über „Gesehen“. Die alte Spezifikationszeile „Gib das Tablet weiter“ ist keine Pflicht. Beim Trugbilderwolf zeigt die Karte die wahre Rolle, nie die Scheinrolle (DI-08 und Entscheidung „Er erfährt seine Scheinrolle nicht“).
- **DA-29 Spezialkorrekturen nur nach Kernvorprüfung:** Die Oberfläche bietet eine Spezialkorrektur nur an, wenn `RulesEngine.check` sie für Person und Ziel im aktuellen Zustand annimmt. Keine Rollenlogik in der Oberfläche, Warnung und Pflichtbegründung wie bei jeder Korrektur, veraltete Auswahl wird verworfen.
- **DA-30 Testlebenszyklus der Abdeckungspartien (B-01):** `Array.shuffle()` nutzt den beim Start zufällig gesetzten globalen Generator. Die Abdeckungspartien mischen deshalb nur über den seedbaren Test-Generator; die Fokusrolle wird von der Test-Spielleitung nicht übersprungen, abgebrochen oder als Ziel gewählt; bedingte Nachtrollen haben feste Erreichbarkeitsszenarien statt Zufallsglück. Die Pflichtabdeckung wurde nicht entfernt.

### Paket 3 (29.09.2026): technische Ableitungen, keine Nutzerantworten

- **DA-31 Anzeige der Stimmhinweise:** RM-DR-008 legt fest, dass der Kern Boni nur als Hinweis für die physische Zählung berechnet. Die Hinweise erscheinen ausschließlich im privaten Spielleiterbereich, weil sie Rollen verraten (Blutwolf ist ein Wolf, der Richterbonus zeigt die verdeckte Nominierung). Keine Regeländerung.
- **DA-32 Nachweisgrenze der Bedientests:** Ein Rollen-Bedientest gilt nur, wenn die geprüfte Fähigkeit über Sitzplatz-Handler, Kartenbuttons und Dialog ausgelöst und danach Zustand oder Ereignis geprüft wird. Die Vorbereitung (Start, Tote per Korrektur ohne Folgen) darf Kernbefehle nutzen. Passive Rollen werden über ihren Auslöser geprüft, ohne erfundenen Fähigkeitsbutton.
- **DA-33 Kombinationsanalyse ohne Setup-Regel:** Die Analyse (`docs/role-migration/12-role-combination-analysis.md`) ordnet Befunde in A bis D ein. Balancehinweise (C) führen ohne Produktentscheidung zu keiner Setup-Warnung oder Sperre.

### Paket 4 (29.09.2026): technische Ableitungen, keine Nutzerantworten

Technische Ableitungen des Auftrags „Paket 4“ (Speichern, Wiederaufnahme, Geheimhaltung). Keine Regeländerung, kein Schemawechsel. Nachweise: `test_save_service.gd`, `test_resume_scenarios.gd`, `test_resume_every_command.gd`, `test_process_restart.gd`, `test_output_positive_lists.gd`.

- **DA-34 Erhalten und verworfen bei Unterbrechung:** Erhalten bleibt jeder angenommene Befehl (auch Stufenantworten, Nominierungen, Rollen- und Hinweisbestätigungen, eingereihte Reaktionen, Siegkandidaten). Flüchtig und beim Neustart verworfen: angetippte, nicht bestätigte Sitzplätze, aufgedeckte Prüfkarten, geöffnete Ebenen (Hinweis-, Rollen-, Spielleiterkarte) und das Weiterschalten des Morgenberichts. Nach dem Neustart ist keine private Ebene geöffnet. Tabelle in `docs/ui/save-resume.md`.
- **DA-35 Offene `.tmp` vor dem Schreiben einsetzen (B-04):** Eine vollständige `.tmp` ist immer der neueste Stand. `SaveService` setzt sie vor dem nächsten Schreiben ein (wie beim Laden), statt sie zu überschreiben. Gelingt das Einsetzen nicht, wird nicht geschrieben (`backup_failed`), damit der Stand erhalten bleibt.
- **DA-36 „Erneut speichern“ nur auf Tippen:** Nach einem Speicherfehler bietet die Phasenleiste „Erneut speichern“ an; ein Versuch je Tippen, keine automatische Wiederholung.
- **DA-37 Beenden-Rückfrage ehrlich:** Ist der letzte Stand der laufenden Partie nicht gespeichert, warnt die Rückfrage davor, statt „ist gespeichert“ zu sagen. Mobil beendet Zurück in der Wurzel weiter sofort (bestehendes Systemverhalten); dort bleibt die rote Statusanzeige der Hinweis.
- **DA-38 Rückfallmeldung nennt den älteren Stand:** Beim Laden der Sicherung sagt die Meldung, dass ein älterer Stand geladen wurde und die zuletzt ausgeführten Schritte fehlen.
- **DA-39 Nachweis von Schreibfehlern:** Kein Test über Kontorechte (unter privilegierten Konten und Windows nicht zuverlässig). Echte Fehler über eine im Pfad stehende Datei, weitere Schritte über den vorhandenen Testanschluss `simulate_failure`. Der Dienst prüft den Pfad vor dem Anlegen, damit kein Engine-Fehler entsteht.

### Restpaket vor Paket 5 (29.09.2026): technische Ableitungen, keine Nutzerantworten

Technische Ableitungen des Auftrags „Restpaket: sichere Beendigung und Zufallsknopf R-06“. Keine Regeländerung, kein Schemawechsel (Schema 14, Regelversion 0.12). Die Produktentscheidungen D-04, D-05, I-03 und R-07 sind damit nicht beantwortet. Nachweise: `test_save_service.gd`, `test_info_roles.gd`, `test_random_pick.gd`.

- **DA-40 Warnung auf allen freiwilligen Beenden-Wegen (B-06):** Ist der letzte Stand der laufenden Partie nicht gespeichert, zeigt `AppShell.request_quit` auf Desktop und Mobilgerät dieselbe Warnung. Abbrechen erhält die Sitzung, „Beenden“ beendet genau einmal. Ist der Stand gespeichert, bleibt das Plattformverhalten (Mobil sofort, Desktop mit Rückfrage). Ersetzt die Einschränkung in DA-37.
- **DA-41 Fenster schließen:** `auto_accept_quit` ist aus; `NOTIFICATION_WM_CLOSE_REQUEST` beendet gespeichert sofort wie bisher, ungespeichert erst nach der Warnung. Ein erzwungenes Beenden durch das Betriebssystem erreicht die App nicht und gilt nicht als abfangbar.
- **DA-42 Ergebnisraum des Zufallsknopfs:** Gezogen wird nur, was die Spielleitung nach den bestätigten Regeln wählen darf: Traumdeuter und Kopfgeldjäger drei andere Lebende mit mindestens einem Wolf (I-01, I-06), König eine andere lebende Person der Fraktion Dorf (I-03), Blutpriester-Aufdeckung 0 bis 3 andere lebende Wölfe (I-08). Die Opferwahl des Blutpriesters (I-13) ist seine eigene Entscheidung und hat keinen Zufallsknopf. Andere Rollen erhalten keinen.
- **DA-43 Verteilung:** Alle zulässigen Ergebnisse werden nach Personen-ID stabil aufgezählt und genau eines mit einer Ziehung gewählt; jedes Ergebnis ist gleich wahrscheinlich, unabhängig von Sitzplatz oder Reihenfolge, ohne Schleife „würfeln bis gültig“. Beim Blutpriester ist jede zulässige Wolfsmenge (auch „keiner“) ein Ergebnis; die Anzahl der genannten Wölfe folgt daraus und ist keine eigene Regel.
- **DA-44 Vorschlag und Bestätigung:** Der Vorschlag entsteht aus einer Kopie des gespeicherten Generators und ändert nichts; gleicher Zustand, gleicher Vorschlag (auch nach Laden oder Neustart). Bestätigt wird mit `AnswerPrompt` plus `random: true`; der Regelkern zieht erneut, nimmt nur exakt dieses Ergebnis an (sonst `random_mismatch`, bei anderen Stufen `random_not_supported`) und übernimmt dabei genau eine Ziehung. Die Oberfläche setzt den Generator nie selbst. Kein Neu-Würfeln: Ohne Zustandsänderung bleibt der Vorschlag gleich.
- **DA-45 Bedienzustand des Vorschlags:** Jede tatsächliche Änderung der Auswahl durch Antippen macht aus dem Vorschlag eine Spielleiterwahl ohne Ziehung. Jede Zustandsänderung (Befehl, Laden, Rückgängig) verwirft ihn. Abbrechen, Öffnen und Vorschau verbrauchen weder Fähigkeit noch Ziehung.

### Produktentscheidungen nach Paket 4 (29.09.2026): Antworten des Product Owners

Gestellt in Claude Code mit je drei Auswahlmöglichkeiten und Freitext; gewählt wurde jeweils die empfohlene Option. Umsetzung in einem eigenen, nachfolgenden Auftrag; bis dahin gilt der beschriebene Ist-Stand.

- **PE-01 Offene Reaktion für Mitlesende (Matrix I-03):** Auswahl „Neutral statt Anzahl“. Öffentlich nur ein neutraler Hinweis (etwa „Die Spielleitung bereitet den Morgen vor“) ohne Hinweis auf Reaktionen; Anzahl und Art nur im privaten Spielleiterbereich. Ist-Stand: die öffentliche Hinweiszeile nennt „{count} Reaktion(en) offen“. Noch nicht umgesetzt.
- **PE-02 Sicherungsstände (Matrix D-04):** Auswahl „Eine Sicherung reicht“. Eine `.bak` je Partie bleibt; mehrere Stände frühestens als spätere Komfortfunktion. Entspricht dem Ist-Stand.
- **PE-03 Wiederholen nach Neustart (Matrix D-05):** Auswahl „Entfällt beim Neustart“. Wiederholbare Schritte werden nicht gespeichert; Spezifikation B-12 („über Neustart“) ist in diesem Punkt überholt. Entspricht dem Ist-Stand.
- **PE-04 Problematische Besetzungen (Matrix R-07):** Auswahl „Hinweis im Setup“. Nicht blockierender Hinweistext bei der Rollenverteilung, zunächst Wahnsinniger Kutscher unter 13 Personen und viele gleichzeitig mögliche Siegkandidaten; Start bleibt sofort möglich, keine Verbote, keine neuen Siegprioritäten. Noch nicht umgesetzt.

### Umsetzung PE-01 bis PE-04 (29.09.2026): technische Ableitungen, keine Nutzerantworten

Technische Ableitungen des Auftrags „Produktentscheidungen PE-01 bis PE-04 abschließen“. Die Antworten PE-01 bis PE-04 oben bleiben unverändert; hier steht nur, wie sie umgesetzt oder nachgezogen wurden. Keine Regeländerung, kein Schemawechsel (Schema 14, Regelversion 0.12). Nachweise: `test_public_reaction_hint.gd`, `test_setup_hints.gd`, `test_role_step.gd`, `test_random_pick.gd`.

- **DA-46 Neutraler öffentlicher Hinweis (PE-01):** Die öffentliche Hinweiszeile (`CockpitView.warnings`) nennt keine offenen Reaktionen mehr. Stattdessen zeigt sie außerhalb der Nacht bei jeder verdeckten Karte denselben Text, unabhängig davon, ob eine Reaktion, ein Prompt, eine Siegentscheidung oder eine Hinweiskarte verdeckt ist: in der Morgenauflösung „Die Spielleitung bereitet den Morgen vor.“, am Tag „Die Spielleitung bereitet den nächsten Schritt vor.“ Nachts erscheint er nicht, weil dort jeder Schritt verdeckt ist. Die Karte der Spielleitung behält Anzahl, Art und Besitzer. Weiter erkennbar bleiben die Phase „Morgen“ (der Kern bleibt nur bei offener Reaktion in der Morgenauflösung) und die verdeckte Karte statt des Morgenberichts; beides ist nicht Teil von PE-01 und wurde nicht geändert. Das ist keine Garantie gegen Rückschlüsse.
- **DA-47 Kutscher statt Wahnsinniger Kutscher (PE-04):** PE-04 nennt „Wahnsinniger Kutscher“. Die beschriebene Mechanik (Wiederbelebung erst ab zehn Toten, Wiederbelebungsrunde trotz fehlender Wirkung) und die Analyse C-1 betreffen die Rolle `kutscher` („Kutscher“); `wahnsinniger-kutscher` ist eine andere Rolle ohne Wiederbelebung. Der Hinweis gilt deshalb für `kutscher` bei weniger als 13 Personen. Der Product Owner kann das korrigieren.
- **DA-48 Auslösebedingung Siegkandidaten (PE-04):** Der Hinweis erscheint bei mindestens zwei Kopien aus Parasit, Voodoo-Priester, Grabräuber und Manipulator. Deren Einzelsieg gilt bei höchstens drei Lebenden, beim Manipulator bei genau drei und nie nominiert (`WinRules`, `SoloRules.voodoo_wins`). Diese Siege können daher gleichzeitig eintreten (Analyse C-3, Test D-4). Andere Einzelsiegrollen, eine einzelne Rolle der Gruppe neben Dorf oder Wölfen und Rollenwechsel während der Partie lösen keinen Hinweis aus. Es gibt keine weiteren Balancewarnungen.
- **DA-49 Ort der Hinweise:** Beide Hinweise stehen als eigene Zeilen am Anfang der scrollbaren Rollenliste im privaten Rollenschritt. In der Seitenspalte fehlt bei 1024×768 der Platz (gemessen: Mindesthöhe 548 px bei 518 px Fläche). Sie aktualisieren sich bei jeder Änderung von Rollen oder Personenzahl. Sie haben keinen Dialog, keine Sperre und keine automatische Änderung, erscheinen nicht in Verteilung, Sitzordnung und Cockpit und sind kein Feld des StartGame-Befehls. Grenze: Wer weit gescrollt hat, sieht einen neuen Hinweis erst beim Zurückscrollen.
- **DA-50 Gesperrter Zufallsknopf nur per Testvorbereitung erreichbar:** Im regulären Ablauf gibt es keinen Prompt mit Zufallsknopf ohne zulässiges Ergebnis. Traumdeuter und Kopfgeldjäger entfallen ohne mögliche Dreiergruppe mit Wolf, der König entfällt ohne Kandidaten, und die Blutpriester-Aufdeckung erlaubt immer „keiner“. Eine Spielleiterkorrektur bricht den offenen Prompt ab. Der UI-Test stellt den Zustand deshalb durch Eingriff in den Sitzungszustand her: beide Wölfe tot bei offenem Traumdeuter-Prompt. Dieser Zustand besteht die Kernprüfung. Die Sperre bleibt eine Schutzfunktion der Oberfläche.
- **DA-51 PE-02 und PE-03 in den Vorgaben:** Masterplan Phase 3 (Checkpoint-Rotation, Gate), Spezifikation B-12, `save-resume.md`, Abschlussmatrix und Roadmap sind als durch PE-02 bzw. PE-03 ersetzt gekennzeichnet. Historische Berichte bleiben unverändert. Es gibt keine zusätzliche Rotation und keine Redo-Persistenz.
- **DA-43 unverändert:** Die Blutpriester-Verteilung (jede zulässige Wolfsmenge einschließlich „keiner“ gleich wahrscheinlich) bleibt eine technische Ableitung und ist keine ausdrückliche Nutzerentscheidung. Sie bleibt für die Inhaltsprüfung in Paket 5 vorgemerkt.

### Paket 5a (29.09.2026): technische Ableitungen, keine Nutzerantworten

Technische Ableitungen des Auftrags „Paket 5a: Einstellungen dauerhaft speichern, Übersetzungen prüfen und Inhaltsstand bereinigen“. Keine Regeländerung, kein Schemawechsel (Schema 14, Regelversion 0.12). Nachweise: `test_settings_persistence.gd`, `tests/check-godot-i18n.test.js`.

- **DA-52 Dauerhafte Geräteeinstellungen:** Eine JSON-Datei `user://settings.json` mit `format`, `version` (nur für dieses Format, nicht für Spielschema oder Regelversion), `language`, `reduced_motion` und `left_handed`, getrennt von `user://saves`. Keine Rollen, Namen, Spielstände oder Geheimnisse. Die Shell lädt sie in `_enter_tree`, also vor dem Aufbau der ersten Ansicht; Laden setzt Werte ohne Änderungssignal und schreibt nie. Fehlende Datei: Standardwerte. Ungültige Einzelwerte fallen einzeln auf den Standard zurück, unbekannte Schlüssel werden ignoriert, eine unlesbare Datei ergibt Standardwerte ohne Startabbruch. Schreiben wie beim Spielstand vereinfacht (`.tmp` prüfen, `.bak`, Rückfall auf `.bak`); ein Fehler lässt die letzte gültige Fassung lesbar, die Einstellung gilt für die laufende Sitzung weiter, und der Einstellungsscreen meldet „konnte nicht dauerhaft gespeichert werden“ statt einer Erfolgsmeldung. Kein automatischer Wiederholversuch; jede weitere Änderung speichert neu. Ein von außen übergebener Kontext (Tests, Screenshot-Werkzeug) speichert nur mit ausdrücklich gesetztem Speicher. Der Linkshänderwert wird mitgespeichert und hat weiterhin keine Wirkung (D-10 offen).
- **DA-53 Struktureller Übersetzungsprüfer:** `tools/check-godot-i18n.js` prüft die produktiven PO-Dateien mit echtem PO-Parser (Mehrzeiler, Escapes, Kopf, Markierungen) auf fehlende, doppelte, leere und „fuzzy“ Einträge, abweichende benannte Platzhalter und %-Formate, wörtliche Schlüssel im Quelltext `godot/app`, direkte `.format()`-Aufrufe mit fehlendem Platzhalter und die Rollengruppe aus `role_catalog.gd`. Dynamisch zusammengesetzte Schlüssel werden als Vorlage benannt und nur auf mindestens einen Treffer geprüft; das ist keine Vollständigkeitsaussage. Der Prüfer belegt Struktur, nicht Bedeutungsgleichheit. CI: eigener Workflow `godot-i18n.yml`, der auch bei Änderungen am Prüfer und seinen Tests läuft.
- **DA-46 und DA-47 unverändert, Einordnung:** DA-46 beschreibt die Grenze der neutralen Hinweiszeile (Rückschluss aus Phase „Morgen“ und verdeckter Karte); sie ist keine Freigabe dieser Restlücke, Matrix I-03 führt sie als offenen Teil 2. DA-47 bleibt eine redaktionelle Korrektur des Rollennamens aus PE-04 anhand der beschriebenen Mechanik (`kutscher`); daraus folgt weder eine neue Nutzerbestätigung noch eine neue Rollenregel.

### Paket 5b (29.09.2026): Antworten des Product Owners

Gestellt in Claude Code zu Beginn des Auftrags „Paket 5b: Rollenlexikon und kontextbezogene Spielleiterhilfe“, je drei Auswahlmöglichkeiten mit Beispiel und Freitext; gewählt wurde jeweils die empfohlene Option. Sie beantworten die Restfragen `docs/content-drafts/OPEN-ISSUES.md` §5 Nr. 1 und Nr. 2.

- **PE-05 Rolle in den Ansagen zu Liebeskummer, Kette und Verknüpfung (Rest von DI-03):** Auswahl „Quellrolle nennen“. Die öffentliche Ansage nennt die Rolle, von der der auslösende Effekt stammt: Liebeskummer → Loki, Rotkäppchen-Kette → Rotkäppchen, Verknüpfung → Schattenwanderer; nie die Rolle der sterbenden Person, auch nicht in Wiederbelebungsrunden. Begründung der Frage: Die Rolle der sterbenden Person würde in Wiederbelebungsrunden verdeckte Rollen aufdecken und bei Kette und Verknüpfung oft Rotkäppchen bzw. Schattenwanderer enttarnen; die Quellrolle ist durch den Effektnamen ohnehin impliziert. Die drei Effekte haben dasselbe Geheimhaltungsprofil, daher eine gemeinsame Antwort. **Umgesetzt:** `KillPipeline.PUBLIC_EFFECTS` und die Verknüpfungsansage setzen `role_id` im öffentlichen Ereignis `DeathEffect` auf die feste Quellrolle; `ui.effect.heartbreak`, `ui.effect.red_chain` und `ui.effect.shadow_link` enthalten `{role}` („Die Bindung von Loki wirkt: Aus Liebeskummer stirbt …“). Ersetzt in diesem Punkt die Mindestangabe aus DA-23. Nachweise: `test_death_effects.gd`, `test_death_effect_lines.gd` (vorher rot, danach grün).
- **PE-06 Phase „Alle Verzauberten“ ohne neu Verzauberte (Rest von DI-06):** Auswahl „Immer nach Rattenfänger“. Die Phase folgt auf jeden Aufruf des Rattenfängers, auch auf einen reinen Tarnaufruf (DI-02), solange es Verzauberte gibt; sie entfällt, wenn der Rattenfänger nicht mehr aufgerufen wird (in einer Runde ohne Wiederbelebung tot und aufgedeckt). Folge: Der Tisch kann aus der Phase nicht auf Blockade, Tod oder fehlende Ziele schließen; die Verzauberten selbst sehen weiterhin, ob jemand dazukam. **Umgesetzt** am 29.09.2026 als eigener Nachtschritt (DA-60 bis DA-64); der Hinweis im Rollenlexikon ist entfernt.

### Paket 5b (29.09.2026): technische Ableitungen, keine Nutzerantworten

Technische Ableitungen des Auftrags „Paket 5b: Rollenlexikon und kontextbezogene Spielleiterhilfe“. Kein Schemawechsel (Schema 14), Regelversion `grimmhain-core-0.12` unverändert (DA-54). Nachweise: `test_role_lexicon_content.gd`, `test_role_lexicon_ui.gd`, `test_death_effects.gd`, `test_death_effect_lines.gd`, `tests/check-godot-i18n.test.js`.

- **DA-54 PE-05 ohne Versionswechsel:** `DeathEffect` ist ein Ereignis, kein gespeicherter Zustand. Spielstände enthalten Befehle und Zustand; Ereignisse entstehen beim Laden neu durch Replay, der Zustands-Hash ändert sich nicht. Ältere Spielstände laden daher weiter und zeigen die Ansage im neuen Wortlaut. Ein Versionswechsel hätte alle Spielstände ohne Nutzen unlesbar gemacht. Grenze: Dieselbe Regelversion deckt jetzt eine geänderte öffentliche Ansage ab.
- **DA-55 PE-06 als Folgeauftrag:** Ein Hinweis (`piper_all`) für Nächte ohne neue Verzauberung ließe sich im Kern leicht erzeugen, erschiene im Cockpit aber vor der Karte, die den Tarnaufruf des Rattenfängers trägt (offene Hinweise zuerst, DA-24; Tarnaufrufe stehen auf der Karte des nächsten echten Schritts). Die Reihenfolge „Alle Verzauberten“ vor „Rattenfänger“ würde die Tarnung verraten, die PE-06 herstellen soll. Richtig ist ein eigener Nachtplan-Eintrag direkt hinter dem Rattenfänger mit Ausfallregel (keine lebenden Verzauberten, Rattenfänger nicht aufgerufen), Einordnung in die Tarnaufruf-Berechnung (`CallPolicy.decoy_calls`), privater Karte mit der Liste aller Verzauberten, Ersatz des bisherigen `piper_all`-Hinweises, Replay- und Save/Load-Tests und Regelversion 0.13 (geänderter Nachtplan im gespeicherten Zustand). Dieser Umbau überschreitet ein Inhaltspaket; er ist als nächster Kernauftrag in `CODE-COMPLETION-ROADMAP.md` eingetragen.
- **DA-56 Datenquelle des Lexikons:** Je Katalogrolle neun Pflichtfelder `ui.role.<rolle>.lex.<feld>` (`night`, `wolf`, `ability`, `timing`, `targets`, `exceptions`, `win`, `example`, `gm`) und bei 15 Rollen das Feld `open` für ungeklärte, technisch abgeleitete und noch unbestätigte oder noch nicht umgesetzte Punkte. Die Liste der Felder steht einmal in `RolePresentation.LEXICON_FIELDS`; Rollen kommen aus `RoleCatalog.ROLES`, keine zweite ID-Liste. Die Texte wurden einmalig aus `docs/content-drafts/rolebook/` in beide PO-Dateien übernommen, nach redaktioneller Prüfung; maßgeblich ist danach der Wortlaut in `ui.*.po`. Übernahme: Nachtstufen-Zahlen („Stufe 4.6“) entfallen, die App ordnet die Schritte selbst; beide Beispiele stehen im Feld `example`; gerade Anführungszeichen werden typografisch. Zur Laufzeit liest die App keine Markdown-Datei. Kartenschlucker hat keinen Eintrag.
- **DA-57 Anzeigeorte und Bedienung:** Hauptmenü: eigene Ansicht `lexicon` (Router, Zurück schließt erst den Eintrag, dann zum Hauptmenü). Setup und Cockpit: temporäre Ebene über der Ansicht (`RoleLexicon.layer`), weil ein Ansichtswechsel dort den Bedienzustand samt offener Auswahl verwerfen würde. Setup: Knopf „Regeln“ in jeder Rollenzeile neben der Kurzbeschreibung. Cockpit: Werkzeug „Lexikon“ (allgemeines Lexikon, auch ohne Partie) und „Regel nachlesen“ auf der privaten Karte (Schritt, Prompt, Hinweis). Zuordnung der Kontextrolle: Rolle der Karte; Rudel → Werwolf; anonyme Frage an die von Rotkäppchen gefragte Person → Rotkäppchen; Hinweise → Loki, Rattenfänger, Pestbringerin. Eine verdeckte Karte hat keine Hilfe (es entstehen keine Knoten), eine gezeigte Karte ersetzt das Cockpit und hat keine. Sichtschutz schließt die Ebene. Die Auswahl bleibt, bis sich der Zustand ändert; dann verwerfen die bestehenden Regeln sie. Der Sprachknopf im Lexikon setzt dieselbe Geräteeinstellung wie die Einstellungsansicht (dauerhaft gespeichert, DA-52); der geöffnete Eintrag bleibt. Suche nach dem Rollennamen der aktuellen Sprache, ohne Groß-/Kleinschreibung, Filter Alle/Dorf/Werwölfe/Einzelsieg. Keine Favoriten, keine Bearbeitung.
- **DA-58 Redaktionelle Angleichung:** Kurztexte und Ursachen: „Rudelangriff“ / „pack attack“ nur für den Rudelangriff (`NIGHT_KILL` mit Quelle Rudel, einschließlich Zusatzopfern der Rudelart), „Hinrichtung“ / „execution“ statt „gelyncht“ / „lynched“, im Englischen neutrale Pronomen („they“, „themself“). Keine Regelbedeutung verschoben. Rollenlexikon-Entwürfe: Verweise auf Planungsdokumente und Codenamen aus den Texten für die Spielleitung entfernt (Herkunft steht weiter in der Zeile „Quelle“), veraltete Aussagen korrigiert (Loki wird nach DI-02 in späteren Nächten weiter angesagt; Rotkäppchen-Karte und Fluch des Weisen nach DA-23/DA-25), Zufallsknopf-Texte auf die echten Beschriftungen („Zufällig auswählen“, „Auswahl bestätigen“).
- **DA-59 Layoutprüfung mit Scrollflächen:** Die headless Layoutprüfung wertet Inhalt in einem ScrollContainer nur mit seinem sichtbaren Teil; der ScrollContainer selbst muss weiter im Fenster und in der sicheren Fläche liegen, Überdeckungen werden mit den sichtbaren Teilen geprüft. Anlass: Das Lexikon ist die erste Ansicht mit langer Liste im Grundzustand. Die Prüfung fand dabei einen echten Fehler (umbrechende Filterknöpfe schoben die Liste bei 1024×768 fast aus dem Bild), der behoben ist.
- **DA-43 unverändert:** Die Blutpriester-Verteilung bleibt technische Ableitung; das Lexikon kennzeichnet sie im Feld „Noch nicht geklärt oder umgesetzt“.

### PE-06-Umsetzung (29.09.2026): Antwort des Product Owners

- **PE-07 Mehrere Rattenfänger:** Gefragt in Claude Code (drei Auswahlmöglichkeiten plus Freitext), wie „Alle Verzauberten“ bei mehreren Rattenfängern laufen soll. Freitextantwort: „Es gibt keine einzige Rolle Doppelt in diesem Spiel bis auf die Gebundenen“. Folge für PE-06: genau ein Rattenfänger, ein gemeinsamer Folgeschritt. **Widerspruch, offen:** Der Katalog erlaubt bisher jede Rolle mehrfach (`RoleCatalog.max_copies`, Grundrollen ausdrücklich ohne Obergrenze), E-11 regelt mehrere Feuerteufel, und Werwolf/Dorfbewohner werden für 6 bis 24 Personen mehrfach gebraucht. Ob die Antwort für alle Sonderrollen gilt und die Setup-Grenzen geändert werden, ist nicht Teil dieses Auftrags und muss vor einer Umsetzung bestätigt werden. Bis dahin legt der Kern auch bei mehreren Rattenfänger-Schritten genau einen gemeinsamen Folgeschritt hinter alle (verrät dem Tisch keine Anzahl). **Beantwortet am 30.09.2026:** Der Widerspruch ist aufgelöst, siehe „PE-07-Umsetzung (30.09.2026)“ am Ende dieser Datei. Die Angaben zu `max_copies`, „Grundrollen ohne Obergrenze“ und E-11 in älteren Einträgen beschreiben den Stand vor PE-07 und gelten für die Startbesetzung nicht mehr.

### PE-06-Umsetzung (29.09.2026): technische Ableitungen, keine Nutzerantworten

Umsetzung des Auftrags „PE-06: Den Rattenfänger-Ablauf vollständig automatisieren“. Nachweise: `test_piper_all.gd` (Kern), `test_piper_all_ui.gd` (Bedienweg), `test_resume_scenarios.gd` (Neustart), angepasst `test_notices.gd`, `test_notice_cards.gd`, `test_prompt_coverage.gd`, `test_role_lexicon_content.gd`, `test_role_lexicon_ui.gd`.

- **DA-60 Eigener Nachtschritt `piper-all`:** Der Nachtplan erhält bei StartNight einen Gruppenschritt `piper-all` mit der Nachtpriorität des Rattenfängers, sortiert hinter jeden Rattenfänger-Schritt. Er wird eingeplant, wenn der Rattenfänger nach `CallPolicy.called_roles` aufgerufen wird oder ein Rattenfänger-Schritt geplant ist (Grabräuber mit gestohlener Fähigkeit), auch ohne Verzauberte bei Nachtbeginn, weil in dieser Nacht die ersten verzaubert werden können. Er ersetzt den Hinweis `piper_all`; der Hinweis `piper_new` an die neu Verzauberten bleibt und steht als offener Hinweis vor der nächsten Karte (DA-24). Damit gilt die PE-06-Reihenfolge Rattenfänger → neu Verzauberte → alle Verzauberten → nächster Schritt ohne eigene Ablaufsteuerung.
- **DA-61 Ausfallregel und Tarnaufruf:** Der Schritt entfällt protokolliert (`StepDropped`, nur Spielleitung), wenn der Rattenfänger nicht aufgerufen wird (`not_called`; in einer Runde ohne Wiederbelebung tot und aufgedeckt) oder keine lebende verzauberte Person existiert (`no_decision`). Er ist keine Fähigkeit: Einfrieren durch den Zeitwächter (E-36), Blockaden und Todesmarkierungen des Rattenfängers lassen ihn nicht entfallen, weil der Rattenfänger dann als Tarnaufruf angesagt wird (DI-02) und PE-06 jeden Aufruf einschließt. `CallPolicy` ordnet den Schritt auf dem Platz des Rattenfängers ein; ein entfallener Rattenfänger-Schritt erscheint deshalb als Tarnaufruf auf derselben Karte vor „Alle Verzauberten“ und danach nicht noch einmal. Die Albtraumwolf-Blockade trifft den Rattenfänger nach RM-DR-010 nicht (nur Dorfrollen).
- **DA-62 Karte und Geheimhaltung:** Informationsschritt nach dem Muster der Gebundenen (`InfoSteps`, Stufe „Gezeigt“, abbrechbar, nicht überspringbar). Die Liste der lebenden Verzauberten steht nur auf der Karte der Spielleitung (`charmed_ids`, handelnde Personen); es gibt keine zeigbare Karte für die Personen, sie erkennen einander mit offenen Augen. Keine Ereignisse außer Spielleitung, keine Verzauberung, kein Zufall, kein Verbrauch. Beim Laden muss eine offene Karte genau die aktuellen lebenden Verzauberten zeigen (`InfoSteps.matches_state`). Kontexthilfe „Regel nachlesen“ führt zum Rattenfänger.
- **DA-63 Regelversion 0.13, kein Schemawechsel:** Der gespeicherte Nachtplan und die Hinweisliste ändern ihre Bedeutung (neuer Eintrag `piper-all`, Hinweisart `piper_all` entfällt), das gespeicherte Format nicht: Nachtplan-Einträge sind freie Zeichenketten, Hinweise behalten ihre Felder. Ein Stand der Regelversion 0.12 würde beim Replay einen anderen Nachtplan erzeugen und einen gespeicherten `piper_all`-Hinweis enthalten. Deshalb `grimmhain-core-0.13`, Schema 14 bleibt. Ältere Stände werden nicht migriert oder gelöscht: Der Fortsetzen-Bildschirm kennzeichnet sie als andere Version, „Fortsetzen“ ist gesperrt, die Datei bleibt unverändert (bestehender Weg, `test_save_versions`).
- **DA-64 Veraltete oder doppelte Bestätigung:** Keine neue Sperre nötig. Die Bestätigung trägt die Prompt-ID, der Beginn die Schritt-ID mit Nacht und Index; nach einer Zustandsänderung lehnt der Regelkern beide ab. Die Karte sperrt nach dem ersten Tipp (`ActionCard.lock`). Nachgewiesen im Kern und über den Bedienweg.

### PE-07-Umsetzung (30.09.2026): Antworten des Product Owners

Antworten aus dem Nachtauftrag vom 30.09.2026 (Auswahl in Claude Code: PE-07 Option B). Sie ersetzen die offene Frage im Eintrag PE-07 oben.

- **PE-07 Jede Rolle höchstens einmal bei Spielbeginn (Option B):** Die Regel gilt für jede Rolle, auch für Dorfbewohner und normalen Werwolf. Die Gebundenen sind die einzige Ausnahme und dürfen 1 bis zur Personenzahl vorkommen. Alle anderen Startbedingungen bleiben (Personenzahl 6 bis 24, mindestens eine Wolfsrolle, mindestens eine Dorfrolle, Pflicht-Scheinrolle des Trugbilderwolfs, mindestens eine Einzelsiegrolle im Setup).
- **PE-07 Spätere gleiche Rollen nicht neu geregelt:** Gleiche Rollen, die erst im Spiel durch Verwandlung (Wolfskind, Lycaon, Kutscher), Erbe (Lehrling), Tausch (Seelentauscher), Diebstahl (Grabräuber) oder Spielleiterkorrektur entstehen, sind nicht Gegenstand der Antwort. Diese Mechaniken bleiben unverändert erhalten.
- **PE-07 Automatischer Vorschlag:** Wolfsrollen 1, 2, 3, 4, 5 ab 6, 9, 13, 18, 22 Personen; genau ein Manipulator im Vorschlag; Wolfsrollen in der Reihenfolge Werwolf, Spiegelwolf, Trugbilderwolf, Blutwolf, Besessener Wolf; Dorfrollen in der Reihenfolge Schutzengel, Orakel, Dorfbewohner, Waldhexe, Dorfwache, Sensenträger, Ritter, Lehrling, Nachtwächter, Wolfskind, Waldläufer, Doktor, Detektiv, Fährtenleser, Der Weise, Dorfchronistin, Wahnsinniger Kutscher, Traumdeuter, so viele wie benötigt. Bei 6 Personen: Werwolf, Manipulator, Schutzengel, Orakel, Dorfbewohner, Waldhexe. Die Vorgabe „genau ein Manipulator“ gilt nur für den Vorschlag, nicht als Pflicht für jede manuelle Besetzung.

### PE-07-Umsetzung (30.09.2026): technische Ableitungen, keine Nutzerantworten

Umsetzung des Nachtauftrags „PE-07 vollständig abschließen“. Nachweise: `test_unique_start_roles` (Kern), `test_role_suggestion` (Vorschlag 6 bis 24), `test_role_step` (Setup-Oberfläche), `test_full_round_ui` (Weg von „Neue Partie“ bis zum ersten Tag), `test_save_service` (Spielstand der Regelversion 0.13), `test_piper_all` (Grabräuber mit gestohlenem Rattenfänger). Vollsuite 1134 Tests, 0 fehlgeschlagen.

- **DA-65 Eine Grenze im Katalog:** `RoleCatalog.max_copies` liefert 1, außer für `die-gebundenen` (`UNLIMITED`). `StartGame` (`role_limit_exceeded`), Setup (`SetupRoleCatalog.copy_limit`, `RolePoolDraft`) und Rollenwahl lesen dieselbe Zahl. Es gibt keine zweite Regelimplementierung in der Oberfläche und keinen Testmodus, der Dubletten erlaubt. Ein abgelehnter Start ändert weder Zustand noch Zufallsgenerator (`test_unique_start_roles`).
- **DA-66 Regelversion 0.14, Schema 14:** Alte Befehlsfolgen mit doppelten Startrollen würden beim Replay abgelehnt. Deshalb `grimmhain-core-0.14`; das Dateiformat bleibt (Schema 14). Ältere Stände werden wie bisher nicht migriert oder gelöscht: Der Fortsetzen-Bildschirm zeigt sie als „andere Version“ mit Schema- und Regelversion („gespeichert: Schema 14, 0.13; erwartet: Schema 14, 0.14“), „Fortsetzen“ ist gesperrt, die Datei bleibt bytegleich und wird nicht beiseitegelegt. Der echte Stand `godot/tests/saves/pe07-core-0.13-duplicate-roles.json` (7 Personen, 2 Werwölfe, 3 Dorfbewohner, mit der Regelversion 0.13 erzeugt) belegt das (`test_save_service`, `.gitattributes`: `-text`, damit die Bytes stabil bleiben). Neue 0.14-Partien lassen sich speichern, laden und reproduzieren (`test_full_round_ui`, `test_role_suggestion`).
- **DA-67 Die Grenze gilt nur beim Start:** Spätere gleiche Rollen bleiben möglich und getestet. Die Tests erreichen sie auf dem legalen Weg: gültiger Start, dann Spielleiterkorrektur „Rolle setzen“ (`Fixtures.with_copies`), so wie es auch im Spiel möglich ist. Betrifft unter anderem mehrere Feuerteufel (E-11), Chronistinnen, Lehrlinge, Waldhexen, Sensenträger und Trugbilderwölfe (mit eigener Scheinrolle). Aussagen in Lexikon und Rollenaudit über „mehrere“ Exemplare beschreiben Zustände nach dem Start.
- **DA-68 Zuordnung der Namen zu Rollen-IDs:** Orakel = `das-orakel` („Das Orakel“), Wahnsinniger Kutscher = `wahnsinniger-kutscher` (nicht `kutscher`), Sensenträger = `sensentraeger`, Nachtwächter = `nachtwaechter`, Waldläufer = `waldlaeufer`, Fährtenleser = `faehrtenleser`, Besessener Wolf = `besessener-wolf`, Der Weise = `der-weise`; die übrigen Namen entsprechen ihrer ID. Geprüft gegen die deutschen Katalognamen (`test_role_suggestion::test_answer_names_match_catalog_ids`).
- **DA-69 Vorschlag ohne Zufall und ohne geheime Wahl:** `RoleSuggestion` nimmt die ersten Wolfsrollen der festen Liste, den Manipulator und die ersten `n − Wölfe − 1` Dorfrollen; jeder Wert ist 0 oder 1. Ab 13 Personen enthält der Vorschlag den Trugbilderwolf; seine Scheinrolle bleibt offen und wird im vorhandenen Dialog gewählt (Bestätigen ist bis dahin gesperrt, keine Vorbelegung, DR-08). Die vorhandenen Setup-Prüfungen (mindestens eine Einzelsiegrolle, Besetzungshinweise, Wiederbelebungsmodus) bleiben unverändert. Für jede Personenzahl von 6 bis 24 nimmt der Regelkern den Vorschlag als Start an (`test_role_suggestion::test_every_proposal_is_a_valid_start_for_the_core`), ohne eine Nachtfähigkeit auszuführen.
- **DA-70 Setup-Oberfläche:** Eine Rolle mit Höchstzahl 1 zeigt an der Zeile „Nur einmal zu Spielbeginn“ (nicht „pro Partie“, weil spätere gleiche Rollen nicht verboten sind); nach dem Entfernen ist sie wieder wählbar. Die Gebundenen behalten „Höchstzahl erreicht“ bei der Personenzahl. Ein vorhandener Entwurf über der Höchstzahl (heute nur noch durch Zustandsvorbereitung herstellbar) wird nicht gekürzt: Die Fehlerliste meldet „Rolle zu oft gewählt“, der Kopf der scrollbaren Rollenliste nennt die betroffenen Rollen mit Namen („Nur einmal zu Spielbeginn erlaubt, bitte verringern: …“), „Bestätigen“ bleibt gesperrt, und weder Entwurf noch Zufall noch Sitzung ändern sich. Die Namen stehen im Listenkopf und nicht in der Seitenspalte, damit keine zusätzliche dauerhafte Fläche entsteht.
- **DA-71 Testdaten ohne globale Ersetzung:** `Fixtures` bietet wirkungsarme Füllrollen (Dorf: Dorfbewohner, Amalia, Detektiv, Wahnsinniger Kutscher, Wächter am Tor, Der Weise, Nachtwächter, Ritter, Dorfwache; Wolf: Werwolf, Blutwolf, Rudelvater, Seuchenwolf, Cerberus, Fenrir). Kein Füller ist neutral: Der Wahnsinnige Kutscher reißt bei Hinrichtung die Nachbarn mit, der Detektiv meldet nach dem Tod eines Wolfs, der Wächter am Tor blockiert Verwandlungen zum Wolf, Der Weise und der Ritter wirken bei Nachttoden, der Nachtwächter läutet neben Nicht-Dorf-Personen. Jeder Test, dem ein Füller Wirkung gab (Schattenwanderer-Ansage, Fate-Wolf-Opfer, Lycaon-Verwandlung, Kutscher-Wiederbelebung), wurde einzeln geprüft und die Besetzung angepasst; die Erwartungen blieben bestehen. Personenzahlen über neun Dorfrollen füllen bewusst mit Rollen mit Nachtschritt, nur für Tote oder unbeteiligte Personen.
- **DA-72 Grabräuber mit gestohlenem Rattenfänger:** Die in PE-06 abgeleitete Reihenfolge (DA-60, DA-61) ist jetzt belegt (`test_piper_all::test_robber_with_stolen_piper_runs_the_piper_phases_in_order`): legal ein Grabräuber und ein Rattenfänger; der Rattenfänger stirbt vor Nacht 1, der Grabräuber stiehlt in Nacht 1 und nutzt die Fähigkeit ab Nacht 2. Reihenfolge in Nacht 2: gestohlener Rattenfänger-Schritt, Hinweis `piper_new` an die neu Verzauberten, „Alle Verzauberten“ mit der Liste der Spielleitung, nächster Schritt. Speichern und Laden nach dem Verzaubern und bei offener Liste ergeben denselben Stand. Der verbrauchte Diebstahl des Grabräubers wird nach DI-02 weiter als Tarnaufruf des Grabräubers angesagt, nicht als Tarnaufruf des toten Rattenfängers. Keine neue Regel, kein Codewechsel.
- **Befund, kein Beschluss (Layout):** Im Rollenschritt läuft die Ansicht bei 1024×768 um 24 Pixel aus dem Fenster, sobald die Fehlerzeile der Seitenspalte zwei Zeilen braucht, zum Beispiel bei zugleich fehlender Dorf- und fehlender Einzelsiegrolle. Nachgewiesen mit dem Stand `6ff63f4` (vor PE-07, Besetzung nur mit einem Werwolf). Die Layouttests decken diesen Fall bisher nicht ab; er ist nicht Teil dieses Auftrags. Die neue Fehlerzeile für Rollen über der Höchstzahl ist deshalb kurz gehalten.


## Umsetzung Nachtauftrag Pakete B und C (30.09.2026)

Aus dem Auftrag „Pakete B, C und D“; Schema 14 und Regelversion 0.14 unverändert (reine Zusatzansichten). Technisch abgeleitete Punkte sind als solche gekennzeichnet und nicht vom Product Owner bestätigt.

- **DA-73 Layout Rollenschritt (Befund oben behoben):** Die Seitenspalte des Rollenschritts steckt in einer vertikalen Scrollfläche (`RoleSideScroll`). Wird sie durch zweizeilige Hinweise höher als das Fenster, scrollt sie, statt die Ansicht um 24 Pixel aus dem Fenster zu schieben; nichts wird gekürzt. Regressionstest `test_role_step::test_side_column_two_line_issue_stays_reachable` (vor dem Fix rot).
- **DA-74 Spielergruppen, Datenformat (technisch abgeleitet):** `user://groups.json`, Format `grimmhain-player-groups`, Version 1: Gruppen-ID als Zähler `grp-<n>` (kein Zufall, keine Wiederverwendung), Gruppenname, geordnete Namen. Namen und Grenzen wie `PersonNameRules`; 1 bis 24 Namen je Gruppe; Gruppennamen ohne Beachtung der Groß-/Kleinschreibung eindeutig. Sicheres Schreiben mit `.bak`, Schreibfehler erhalten den letzten Stand, defekte Dateien werden als `.corrupt` beiseitegelegt (`SafeJsonFile`, auch für die Partiehistorie vorgesehen). Ohne Pfad nur Speicher; die Shell setzt beim echten Start den Pfad. Beschreibung: `docs/ui/player-groups.md`.
- **DA-75 Gruppe laden ersetzt den Entwurf (technisch abgeleitet aus „neue Personenobjekte“ und „nur nach Bestätigung ersetzen“):** `PlayerSetup.replace_persons` verwirft den Entwurf vollständig (Personen-IDs ab 1, keine Rollenwahl, Verteilung oder Sitzordnung) und legt neue Personen an. Die Rückfrage nennt das ausdrücklich. Eine leere Liste braucht keine Rückfrage. „Aktualisieren“ ist nur mit gefüllter Liste möglich.
- **DA-76 Regelbuch: Inhalt (technisch abgeleitet, redaktionell abzunehmen):** Zwölf Kapitel in der vom Auftrag genannten Reihenfolge, Texte nur in den Übersetzungen (`ui.rulebook.cNN.*`), Katalog nur für Reihenfolge und Blockart. Jede genannte Beschriftung ist gegen die Übersetzungen des Programms geprüft. Nicht ausformuliert, weil offen oder abgeleitet: Aufruf blockierter und noch nicht aktiver Rollen (DI-02), Länge des Fluchs des Weisen in der Ansage (DA-23), Ton bei fünf Toten, Sitzplatztausch nach dem Start, Totenreichkarten. Das Regelbuch nennt ausdrücklich, was diese Version nicht kann (Stimmzählung, Ton, Smartphone-Ansicht, Kartenfunktionen). Beschreibung: `docs/ui/rulebook.md`.
- **DA-77 Handlungszeilen `act` (technisch abgeleitet):** Lexikonfeld „Ablauf am Tisch“ mit vier Zeilen (Aufruf, Auswählen oder ablesen, Vorlesen oder zeigen, Beenden) für alle 71 Rollen, aus den Kartentexten und dem Lexikonfeld „Nachtschritt“ zusammengesetzt; Reihenfolge der Stufen aus dem Kern (`info_steps`, `bond_steps`). Beschreibungen für Rollen ohne Nachtschritt stützen sich auf ihre Lexikoneinträge. Rotkäppchen: Wie die gefragte Person am Tisch geweckt und befragt wird, ist nicht entschieden und steht als „noch nicht festgelegt“ da (NQ-06).
- **DA-78 Werkzeug „Regelbuch“:** Wie das Lexikon eine Ebene im Cockpit (`open_rulebook`), ohne Zustandsänderung; das Werkzeug ist auf einer gezeigten Karte nicht erreichbar. `RoleLexicon.overlay` ist die gemeinsame Ebenenhülle für beide Hilfen.
- **DA-79 i18n-Prüfer:** `tools/check-godot-i18n.js` liest Breitenangaben wie `%02d` in dynamischen Schlüsselvorlagen (Regelbuch `ui.rulebook.%s.b%02d`), Regressionstest in `tests/check-godot-i18n.test.js`.
- **DA-80 Abschlussbericht und Historie (Paket D):** Der Bericht entsteht in der Anwendungsschicht (`GameReport.build`) nur bei Phase Spielende mit bestätigtem Sieger, sonst leer. Gespeichert wird sprachneutral in `user://history.json` (Format `grimmhain-game-history`, Version 1, `SafeJsonFile`), eine Partie-ID hat genau einen Eintrag (idempotent, Status `completed` oder `reopened`). Die Historie liegt außerhalb des Regelkerns und der Spielstände; Schema 14 und Regelversion bleiben.
- **DA-81 Berichtsumfang und Geheimhaltung:** Öffentliche Fassung nur mit dem, was am Tisch bekannt ist (Namen, Nächte und Tage, Todesmeldungen nach der Morgenpositivliste, Nominierungen, Hinrichtungen, Siegseite; Rolle eines Toten nur in Runden ohne Wiederbelebung). Die Spielleiterfassung ergänzt Rollen aller Personen, Ursachen, Effekte, Korrekturen und die Siegbedingung; sie öffnet nur nach Rückfrage und ist nie vorausgewählt. Der Export nennt die Fassung im Knopf, im Hinweis und im Dateinamen (`grimmhain-bericht-<id>-<oeffentlich|spielleitung>.txt` unter `user://exports`), ersetzt nie ohne Bestätigung. Der erweiterte öffentliche Umfang ist als NQ-07 offen.
- **DA-82 Rücknahme und Wiederholung:** Nimmt „Rückgängig“ die Siegbestätigung zurück, setzt die App den Eintrag auf `reopened` (Liste „Partie läuft wieder“, Export gesperrt). Ein erneuter Abschluss aktualisiert denselben Eintrag. Ein Speicherfehler der Historie beschädigt die Partie nicht; die Historienansicht wiederholt das Speichern beim Öffnen über die Karte. Keine automatische Löschfrist; Löschen nur nach Bestätigung.


## Nachtentscheidungen NQ-01 bis NQ-07 (30.09.2026)

**Herkunft:** Antwort des Product Owners im Claude-Code-Auftrag „sieben Nutzerentscheidungen umsetzen“ am 30.09.2026 auf die Fragen in `NIGHT-QUESTIONS-2026-09-30.md`. Wortlaut: „1B , 2A , 3A , 4A-Rechts/Linkshänder in den optionen mti einbauen , 5A ,wir rechecken eh später JEDE rolle noch einmal, 6A , 7C“. Die Buchstaben wählen die dort genannten Vorschläge; die Freitexte gehören zu 4 und 5. Der historische Fragebogen bleibt unverändert (er trägt oben nur einen Verweis). Alle sieben Fragen sind damit beantwortet und keine ist mehr Blocker. Ableitungen aus den Antworten stehen darunter und sind ausdrücklich nicht vom Product Owner bestätigt.

**Bestätigt (Product Owner):**

- **NQ-01 (B):** Der Hinweis bei fünf Toten ertönt nur, wenn aktuell eine lebende Person die Rolle Selbstmörder hat; auch eine gültig geerbte Rolle zählt. Der Eintrag „Sound bei 5 Toten“ und DI-09 bleiben, jetzt mit dieser Bedingung („in der Partie“ heißt: lebt mit dieser Rolle).
- **NQ-02 (A):** Die bisherige öffentliche Morgenanzeige bleibt. Das ist die bewusste Akzeptanz des verbleibenden Rückschlusses aus der Phase „Morgen“ und der verdeckten Karte (I-03 Teil 2), keine Behauptung technischer Unsichtbarkeit.
- **NQ-03 (A):** Die Sitzordnung ist nach Spielbeginn fest. Die Anforderung an Sitzplatztausch während laufender Partien (S-06, `ReorderSeats`, AS-S03) entfällt; die Sitzordnung im Setup bleibt bearbeitbar.
- **NQ-04 (A, mit Freitext „Rechts/Linkshänder in den Optionen mit einbauen“):** Rechts-/Linkshänder-Modus jetzt in den Optionen umsetzen.
- **NQ-05 (A, mit Freitext „wir rechecken eh später JEDE Rolle noch einmal“):** Die bestehenden technisch abgeleiteten Regeln (Grabräuber, Zeitwächter, Hades, Rachsüchtiger Wolf, Schicksalswolf, Der Weise) gelten vorläufig für Testpartien. Das ist keine endgültige Balance-Abnahme und keine Bestätigung der Lexikonhinweise „technisch abgeleitet und noch nicht bestätigt“; jede Rolle wird später erneut geprüft.
- **NQ-06 (A):** Rotkäppchen: Die gefragte Person wird unauffällig angetippt und die anonyme Frage auf dem Tablet gezeigt.
- **NQ-07 (C):** Nach bestätigtem Spielende dürfen alle Rollen und die Siegbedingung öffentlich werden.

**Weiter offen (nicht durch diese Antworten entschieden):** Kartenregeln (R-03 bis R-05), redaktionelle Endabnahme der Lexikon- und Regelbuchtexte, Szenarien, Beispielrunde, Expertenmodus, Timer, Rollenauswahl für Version 1.0, Geräte- und Tabletabnahme, die Einzelprüfung der Rollen aus NQ-05.

**Umsetzung und Ableitungen (technisch abgeleitet, nicht bestätigt):**

- **DA-83 Bedienseite (NQ-04):** Die vorhandene gespeicherte Einstellung `left_handed` bekommt in den Optionen die Auswahl „Rechtshändig“ / „Linkshändig“ (zwei Buttons einer Gruppe, aktuelle Auswahl gedrückt und als Zeile „Aktiv: …“ genannt). Wirkung: Im Cockpit wechselt genau die Seitenspalte (Ansagekarte mit den Aktionsbuttons und die Werkzeugleiste Protokoll, Privat, Rollen, Spielleitung, Sichtschutz, Lexikon, Regelbuch) die Seite des Sitzkreises: rechts bei „Rechtshändig“, links bei „Linkshändig“. Umgesetzt durch Umordnen des vorhandenen Knotens; Sitzkreis, offene Karte, Auswahl und Signalverbindungen bleiben unberührt, die Änderung wirkt sofort und wird wie jede Geräteeinstellung gespeichert. Unverändert: Sitzkreis, Personenreihenfolge, Sitznummern, Bedeutung von links und rechts bei Rollen, Ziele und Nachbarn, Texte, Symbole und Porträts (nicht gespiegelt), Regeln und Befehle. Andere Ansichten haben keine Seitenspalte dieser Art und bleiben gleich. Die Optionen liegen dafür in einer Scrollfläche, weil die zusätzliche Karte bei 1024×768 sonst über das Fenster hinausragte (Layouttests rot). Kein Redesign; die spätere Vorgabe von 85 bis 90 Prozent Spielfeldfläche bleibt bestehen. Beim Prüfen fiel ein bestehender Layoutfehler auf und wurde behoben: Bei sichtbarer Speicherwarnung wurde „Erneut speichern“ auf 48 Pixel Breite gequetscht und die Statusleiste wuchs über das Fenster (Button ohne Umbruch).
- **DA-84 Rotkäppchen, Ablauf am Tisch (NQ-06, ersetzt die Aussage „noch nicht festgelegt“ in DA-77):** Handlungszeile und Spielleiterkarte der Zielwahl nennen: Rotkäppchen wählt, die Spielleitung lässt Rotkäppchen die Augen wieder schließen, tippt die gewählte Person unauffällig an (ohne Namen zu nennen) und zeigt ihr die anonyme Frage auf dem Tablet (nicht laut vorlesen); die Antwort wird mit „Zuflucht gewährt“ oder „Keine Zuflucht“ erfasst; die Person schließt wieder die Augen. Die Erklärung zu Apfel, Kette und Ablehnung bleibt. Die Anleitung steht nur im Lexikon, im Regelbuch (Kapitel 5) und auf der Spielleiterkarte der Zielwahl, nicht auf der Karte der gefragten Person. Keine neue Wirkung, keine Änderung der Nachtreihenfolge. Das Lexikonfeld „offen“ von Rotkäppchen entfällt.
- **DA-85 Öffentlicher Abschlussbericht (NQ-07, ersetzt den Schlusssatz von DA-81):** Nach bestätigtem Spielende nennt die öffentliche Fassung zusätzlich alle Teilnehmenden mit ihrer Rolle zum Spielende (Sitznummer, Name, Rolle, † bei Toten), die Siegbedingung und gewinnende Personen (nur bei personenbezogenen Siegen und Mitsiegern; bei Wolfs- und Dorfsieg steht die Siegseite). Der Hinweis der Fassung sagt das. Nicht öffentlich bleiben: ursprüngliche Rollen und Rollenwechselverlauf, Todesursachen, Schutzmarkierungen, private Entscheidungen, geheime Ziele, Korrekturen, verdeckte Nominierende und alle internen Zustände (bleiben in der Spielleiterfassung). Bei Rollenwechseln zählt die Rolle zum bestätigten Spielende. Ist die Siegbestätigung zurückgenommen (Eintrag `reopened`), fehlen Rollen, Sieger und Siegbedingung in der Ansicht wieder und der Export ist gesperrt; ein neuer Abschluss ersetzt den Eintrag mit dem neuen Stand. Bildschirm und Textexport verwenden dieselbe Zeilenliste (`ReportText.lines`), also denselben Umfang. Kein Formatwechsel (Historienformat Version 1): Die Rollen standen schon im gespeicherten Bericht; fehlen sie in einem gespeicherten Bericht, erscheint keine Rollenliste. Ein offener Siegkandidat ist kein bestätigtes Spielende und erzeugt keinen Bericht. Bereits exportierte Dateien lassen sich nicht zurückrufen; der Hinweis vor dem Export sagt das.
- **DA-86 Hinweis bei fünf Toten, Auslösung (NQ-01, DI-09):** Aus den vorhandenen Entscheidungen übernommen: „fünf Tote“ zählt Personen, die aktuell tot sind (Totenmarker; Wiederbelebte zählen nicht mehr, RM-DR-138.3), der Hinweis ist öffentlich und erscheint am Tag (Tode der Nacht werden mit der Morgenauflösung öffentlich, davor nie) und genau einmal (DI-09, X-05). **Technisch abgeleitet, nicht bestätigt:** Der Hinweis gehört zum ersten Zeitpunkt, an dem fünf Personen in einer öffentlichen Phase (Morgenauflösung, Tag, Spielende) tot sind, und wird an dem Befehl gemeldet, der ihn herbeiführt. Berechtigt ist er, wenn im Zustand nach diesem Befehl eine lebende Person die Rolle Selbstmörder hat (bei Todesketten also nach der ganzen Kette). ~~Ist er zu diesem ersten Zeitpunkt nicht berechtigt, entsteht er später nicht mehr (zum Beispiel nach Wiederbelebung und erneutem fünften Toten).~~ *(Ersetzt am 30.09.2026 durch Entscheidung B, Eintrag „Fünf-Tote-Hinweis, Entscheidung B“ unten.)* Wird der auslösende Befehl zurückgenommen, gilt der Hinweis als nicht gegeben und kann beim neuen fünften Tod erneut auslösen. Laden, Wiederholen und Neuzeichnen melden nie. Das ist eine Randfallauslegung von „genau einmal“; die Alternative (auch ein späterer berechtigter Zeitpunkt löst aus) wäre eine kleine Änderung von `GameSession._track_five_dead` und ist nicht beschlossen. Der Hinweis trägt nur seine Kennung (keine Namen, keine Rolle), ist keine Regelereignisart, verbraucht keinen Zufall und ändert keinen Zustand. Umsetzung: `PresentationCue` (Auswertung), `GameSession.cue_requested`, `AudioCuePlayer` (Anschluss in der Shell). Ohne Tondatei bleibt der Anschluss stumm, die Partie ist voll bedienbar. Es liegt keine Tondatei bei und keine wurde beschafft; sie gehört nach `assets/audio/cues/five_dead.ogg`, sobald Produktion und Herkunft freigegeben sind (`docs/assets/`, `ASSET-REGISTER.md`). Das ist ein technischer Hinweis mit stummem Fallback, kein fertiger hörbarer Ton.
- **DA-87 Ressourcenwarnung „46 resources still in use at exit“ (Befund und Behebung):** Reproduzierbar bei jedem Testlauf mit Oberfläche (27 bis 46 Ressourcen je nach Umfang), nie bei reinen Regelkerntests. Ursache: `AppContext._init` verband `session.view_changed` mit einem Lambda, das `self` hält. Damit bildeten AppContext und Sitzung einen Referenzkreis; jeder erzeugte Kontext blieb samt Sitzung, Speichern, Gruppen, Historie und den Skripten dieser Klassen bis zum Programmende erhalten (im Testlauf rund 155000 Objekte). Behoben durch eine Methode statt des Lambdas; Regressionstest `test_object_lifetime` (vor dem Fix rot). Im Betrieb entstand kein sichtbarer Fehler, weil es nur einen Kontext je Programmlauf gibt; die Warnung war aber ein echter Lebenszyklusmangel und kein harmloser Ausgang.
- **DA-88 Scheinrolle des Trugbilderwolfs wird vorbelegt (Nutzerwunsch iPad-Test, 03.10.2026, ändert DA-69 und DR-08 in diesem Punkt):** Jede neue Kopie erhält vom Setup eine zufällige Dorfrolle aus dem Pool der Partie als Scheinrolle (SeededRng mit der Seed-Quelle des Setups, das Ergebnis steht in der Kopie). Der Spielleiter kann sie jederzeit ändern; eine eigene Wahl wird nie überschrieben. Vorbelegte Kopien fallen beim Verringern ohne Rückfrage weg. Steht keine Dorfrolle im Pool, bleibt die Scheinrolle offen und blockiert weiter. Die Blocker-Texte der Rollenwahl nennen jetzt in einfacher Sprache, was fehlt und warum.
- **DA-89 Neue Spielvorbereitung in drei Schritten (Nutzerentscheidung 03.10.2026 zu `docs/konzept/vorbereitung-neu.md` Abschnitt 6):** Der Ablauf „Neue Partie“ hat genau drei Schritte mit drei Medaillons: **Runde** (Spielerzahl 6 bis 24 mit Plus/Minus, Zähler Dorf/Wölfe/Einzelgänger des Vorschlags, die vier Akt-Karten, Schalter „App verteilt zufällig“ / „Echte Karten – ich weise zu“), **Namen** (Namen eintragen, einfügen oder diktieren, nummerierte Namensschilder, Reihenfolge = Sitzordnung im Uhrzeigersinn, verschiebbar, „Mischen“, Zähler „9 von 14“ mit Knopf zum Anpassen der Spielerzahl) und **Rollen** (Vorschlag des Aktes nach Team gruppiert; antippen = tauschen, entfernen, Info; „Neuer Vorschlag“; Sonderfälle als Zeile mit „ändern“). Es gibt keine Bestätigungsknöpfe mehr, nur „Weiter“ und „Zurück“; Zurück verliert nichts. Die Bestätigungen und Invalidierungsgründe des Setups (Spieler, Rollen, Verteilung, Sitzordnung) entfallen: Startbereitschaft wird aus dem Inhalt berechnet.
  1. **Rollen-Sets:** die vier Akte aus `js/core/akte.js` 1:1 als Akt-Karten (`ActCatalog`; 72 von 72 Rollen im Godot-Katalog, per Test geprüft). Freigegeben. *Technische Folge, nicht beschlossen:* Ein Akt trägt nur so viele Personen, wie er Rollen hat, weil jede Rolle höchstens einmal vorkommen darf (PE-07): Akt I bis 17, Akt II bis 27, Akt III bis 25 und Akt IV bis 26 (mit Totenreichkarten je eine mehr, wegen des Kartenschluckers). Darüber ist die Karte gesperrt und nennt die Grenze; die Rollen anderer Akte werden nie still beigemischt. Der Kartenschlucker (Akt III und IV) wird nur mit Totenreichkarten vorgeschlagen.
  2. **Namen bleiben Pflicht**, keine Platzhalter. Weiter ist erst aktiv, wenn so viele Namen da sind, wie die Spielerzahl nennt.
  3. **Der eigene Schritt „Verteilung“ entfällt.** Im Modus „App verteilt zufällig“ verteilt „Spiel starten“ mit dem gespeicherten Seed und öffnet das Nachtbrett. Im Modus „Echte Karten“ weist die Spielleitung am Sitzring zu (Platz antippen, dann Rolle); die Plätze zeigen nur „zugeordnet“, nie die Rolle; Start erst, wenn alle zugeordnet sind. `StartGame` bleibt unverändert (`assignment` „manual“, `players`, `seat_order`, `roles`, `appearances`, `death_cards`).
  4. **Blocker und Warnungen:** Nur Warnung, Start möglich: fehlende Einzelgängerrolle (vorher Blocker `missing_solo`) und die Besetzungshinweise PE-04 (Kutscher unter 13 Personen, mehrere gleichzeitige Einzelsiege). Blocker bleiben: unter 6 oder über 24 Personen, Namen fehlen, Akt trägt die Personenzahl nicht, Rollenzahl passt nicht zur Personenzahl, Rolle öfter als erlaubt, **kein Wolf**, Trugbilderwolf ohne Scheinrolle, Kartenschlucker ohne Totenreichkarten. **Abweichung von der Nutzervorgabe:** Eine fehlende Dorfrolle bleibt Blocker, weil der Regelkern den Start mit `missing_village_role` ablehnt (DECISION-LOG „mindestens ein Werwolf und ein Dorfbewohner“); „nur Warnung“ würde eine Regeländerung im Kern erfordern. Das ist als Ja/Nein-Frage an den Product Owner gemeldet und nicht entschieden.
  5. **Das Schrittband im Nachtbrett** („Vorbereitung“ unten links) bleibt unverändert.
  *Technisch gewählt, nicht beschlossen (änderbar):* Die Spielerzahl startet bei 8 und der erste Akt ist vorgewählt; der Vorschlag nimmt je Akt die Wolfsrollen nach der Staffel 1/2/3/4/5 ab 6/9/13/18/22 Personen, eine Einzelgängerrolle (die erste der Akt-Karte), den Rest Dorf in der bewährten Reihenfolge aus PE-07 und füllt bei kleinen Akten mit weiteren Einzelgänger- und Wolfsrollen des Aktes auf. Die Namensreihenfolge ist die Sitzordnung; „Mischen“ nutzt den gespeicherten Generator (Seed über die Seed-Quelle des Setups, abgeleitet je Mischung). Die Rollenaktionen und das Hain-Aussehen der Vorbereitung (kein Gold, Blutrot nur für Aktives) sind rein darstellend. Die Teamsymbole `godot/assets/night/team/` stammen aus `team-symbole.png` (`tools/build_team_symbols.py`), intern freigegeben wie die Rollensymbole.
- **DA-90 Kein Dorfbewohner im Setup, Werwolf mehrfach (Nutzerentscheidung 04.10.2026 nach dem iPad-Test, ändert PE-07 und DA-89 in diesen Punkten):** (1) Der Dorfbewohner steht in keinem der vier Akte und wird weder im Vorschlag noch unter „Rolle hinzufügen“ oder „Tauschen“ angeboten (`SetupRoleCatalog.NOT_OFFERED`); jede Person bekommt eine besondere Rolle. Die Rolle bleibt im Katalog, damit alte Spielstände laden. (2) Der Werwolf darf mehrfach vorkommen (`max_copies` UNLIMITED wie Die Gebundenen). Fehlende Plätze füllt der Vorschlag der Reihe nach mit weiteren Einzelgängerrollen, weiteren Wolfsrollen des Aktes, weiteren Werwölfen (nur bis zur Wolfsquote 1/2/3/4/5 ab 6/9/13/18/22 Personen) und zuletzt, nur in Akt I, mit weiteren Gebundenen (ebenfalls UNLIMITED). Folge: Jeder Akt trägt 24 Personen, mit und ohne Totenreichkarten (vorher Akt I bis 17, II bis 27, III bis 25, IV bis 26). Akt I bei 24 Personen: 3 Werwölfe, 7 Gebundene. Die Gebundenen als letzter Füller in Akt I sind bestätigt (Nutzerentscheidung nach der iPad-Abnahme, 04.10.2026: bleibt wie gebaut, einsteigerfreundlich). Da jeder Akt 24 trägt, ist der Blocker `act_too_small` samt Schlüsseln und der Sperre der Akt-Karten entfernt. (3) „Keine Dorfrolle“ bleibt Blocker. Der Kern zählt alle Werwölfe in Start, Siegprüfung und Speichern wie bisher je Person.
- **DA-91 Feinschliff der Vorbereitung nach der iPad-Abnahme (Nutzerauftrag 04.10.2026):** (1) Eigener Ladebildschirm: `godot/assets/app/splash-grimmhain.png` (Nachtbild abgedunkelt, Schriftzug „Grimmhain“ in Mondsilber, erzeugt mit `tools/build_splash.py`) als `boot_splash`, Web-Ladeseite `godot/web/shell.html` mit passender Hintergrundfarbe und schmalem Mondsilber-Ladebalken. (2) Hauptmenü mit Hain-Knöpfen (Hauptaktion rot, übrige dunkel). (3) Schritt 1: Überschrift „Empfohlene Aufstellung“ über den Teamzählern. (4) Auswahl wird zu einem weichen roten, pulsierenden Glühen entlang der Form des Hain-Teils (`SelectionGlow`: Schein aus den Alpha-Kanten, Shader, ca. 2 s) für Akt-Karte, Modus-Schalter, Namensschild und Rollenkachel. (5) Schritt 3 startet leer, auch im Zufallsmodus; „Neuer Vorschlag“ heißt „Empfehlung übernehmen“; Hinweise und Warnungen erscheinen erst mit der ersten Rolle. (6) Schritt 3 als Kachelraster: Kopfzeile „x / N Rollen gewählt“ mit Zählern, Kacheln nach Team (Dorf blau, Wölfe dunkelrot, Einzelgänger violett, nicht gewählt entsättigt), Antippen schaltet an und aus, Werwolf und Die Gebundenen mit „×N“, − und + (56 px), langes Drücken zeigt die Beschreibung; das Popup „Welche Rolle kommt dazu?“ und das Rollenmenü entfallen. (7) Kartenmodus: Rollenleiste etwa 40 Prozent der Bildschirmhöhe, größere Marken in Teamfarben, der Sitzring rückt nach oben.
- **DA-92 Lebendiger Startbildschirm, Teamfarben, kompakter Ring (Nutzerauftrag 04.10.2026):** (1) Startbilder `godot/assets/start/` (Hintergrund mit Mond und Wolf, Nebelband, Logo; WebP, Register `rt-start-*`), Nebel bereinigt und nahtlos (`tools/build_start_assets.py`). (2) `StartBackdrop` in Ebenen: Hintergrund (cover, langsamer Zoom 1,00 bis 1,04 in 30 s hin und zurück), atmendes Mondglühen, zwei Nebelbänder (verschieden schnell, nach links, 20 und 30 Prozent Deckkraft), zwei Wolfsaugen in der Wurzelhöhle links (erstes Aufblenden nach 3 bis 5 s, danach alle 8 bis 15 s etwa 1,5 s), seltenes dezentes Aufhellen (20 bis 40 s), kein Partikelsystem; bei reduzierter Bewegung steht alles. Startbildschirm: Logo im oberen Drittel der unteren Hälfte, „Eintreten“ als roter Hain-Knopf mit pulsierendem Glühen, beim Antippen zieht der Nebel 0,6 s zu. Hauptmenü: gleicher Hintergrund stärker abgedunkelt, ohne Augen und Schimmer, kleines Logo statt „Hauptmenü“. (3) Ladebild aus Hintergrund (abgedunkelt) und Logo (`tools/build_splash.py`). (4) Rollenkacheln glühen in Teamfarbe (Dorf Mondblau, Wölfe Blutrot, Einzelgänger Violett); Akt-Karte, Modus-Schalter und Namensschild bleiben rot. (5) Kartenmodus mit offener Rollenleiste: Mitteltext aus, der Sitzring ordnet sich als flache Ellipse in zwei gleichmäßigen Reihen über der Leiste neu an und verkleinert die Rahmen so weit, dass sich keine Porträts berühren (Test für 6 bis 24 Personen); der gewählte Platz glüht rot. (6) Bei 0 Rollen zeigt Schritt 3 die Hilfszeile „Übernimm die Empfehlung oder wähle Rollen“.

## Fünf-Tote-Hinweis, Entscheidung B (30.09.2026)

**Herkunft:** Bestätigt vom Product Owner im Claude-Code-Auftrag vom 30.09.2026 („Bestätigte Entscheidung B“) auf die in DA-86 genannte Randfallfrage. Sie wählt die dort beschriebene Alternative.

**Bestätigt (Product Owner):**

- Wird die Schwelle von fünf gleichzeitig toten Personen erreicht, ohne dass ein lebender Selbstmörder vorhanden ist, bleibt der Hinweis aus. Dieser erfolglose Versuch verbraucht den Hinweis nicht für die Partie.
- Sinkt die Zahl durch Wiederbelebung unter fünf und wird die Schwelle später erneut erreicht, darf er auslösen, sofern dann eine lebende Person die Rolle Selbstmörder hat. Auch ein Selbstmörder durch Rollenübernahme (Erbe) zählt.
- Nach einer tatsächlichen Auslösung bleibt „genau einmal“ bestehen. Öffentliche Phase, abgeschlossene Todesketten, Rückgängig, Wiederholen und Laden bleiben wie in DA-86.

**Umsetzung (Umfang):** Nur `GameSession` (Zustand `_five_dead_at` = tatsächliche Auslösung, `_five_dead_armed` = seit dem letzten Erreichen wieder unter fünf) und die Kommentare in `PresentationCue`. Kein Speicherschema, keine Regelversion, kein Audio, keine Tondatei. Ein Versuch ist das Erreichen von fünf öffentlichen Toten, nachdem die Zahl (in jeder Phase gezählt) unter fünf lag. Laden und Rückgängig bestimmen den Zustand aus der Befehlsfolge neu (gleiche Auswertung wie im Betrieb); eine zurückgenommene Auslösung gilt weiterhin als nicht gegeben. Tests: `test_five_dead_cue` (erfolgloser erster Versuch, Wiederbelebung, zweite Schwelle genau ein Hinweis, keine dritte Auslösung, geerbte Rolle, Speichern und Laden zwischen den Schwellen und nach der Auslösung, Rückgängig und Wiederholen der zweiten Schwelle); der frühere Test, der „kein Hinweis nach nicht berechtigtem ersten Erreichen“ festschrieb, wurde auf diese Entscheidung umgestellt.

**Weiter ungeklärt (nicht entschieden, Verhalten unverändert):** Ein Selbstmörder entsteht durch Rollenübernahme oder Rollenkorrektur, während schon fünf Personen tot sind und die Zahl nie unter fünf fiel. Die Entscheidung B erlaubt das nicht automatisch. Aktuell löst dieser Fall nichts aus (kein neuer Versuch ohne Absinken unter fünf); `test_open_case_role_gain_while_five_are_already_dead_is_unchanged` hält das als bisheriges Verhalten fest, ausdrücklich nicht als Regel. Frage an den Product Owner: Soll auch in diesem Fall ausgelöst werden, oder nur beim Erreichen der Schwelle? **Beantwortet am 30.09.2026 durch Entscheidung 6B (Abschnitt „Totenkarten und Kartenschlucker, Entscheidungen vom 30.09.2026“ unten); das Verhalten ist seitdem geändert, der genannte Test ist ersetzt.**

## Totenkarten und Kartenschlucker, Entscheidungen vom 30.09.2026

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 auf die Fragen 1 bis 5 der Vorlage `docs/role-migration/13-totenkarten-kartenschlucker-vorlage.md` und auf die Randfallfrage des Fünf-Tote-Hinweises (DA-86, Entscheidung B). Die Buchstaben wählen die dort genannten Vorschläge, die Präzisierungen stehen im Wortlaut des Auftrags. Die Vorlage bleibt die Entscheidungsvorlage; die Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md` ist Arbeitsmaterial und keine Regelquelle.

**Bestätigt (Product Owner):**

- **1A (Vergabe):** Jede Person erhält beim Tod eine Totenreichkarte, unabhängig von ihrer Fraktion. Nach Wiederbelebung und erneutem Tod erhält sie eine neue Karte.
- **2C (Kartenwirkung, ausdrücklich präzisiert):** ALLE Totenreichkarten werden vor ihrer Implementierung gemeinsam mit dem Product Owner überarbeitet. Mechanische Auswirkungen auf den Spielzustand sollen anschließend im Spiel umgesetzt werden. Handlungen in der realen Welt werden durch verständliche Anweisungen begleitet; die App kann sie nicht selbst ausführen. Welche Bestätigung oder Eingabe dafür nötig ist, wird je Karte festgelegt. Bis zu dieser Überarbeitung gibt es keinen Code für Kartenmechanik, Kartenverteilung, Kartentausch oder Kartenwirkungen und keine vorläufigen Dummy-Regeln. Stimmen werden weiterhin am Tisch gezählt, nötige Ergebnisse trägt die Spielleitung ein (keine digitale Abstimmung).
- **3A (Tausch, ausdrücklich eingeschränkt):** Ein Toter darf seine erhaltene Karte einmal austauschen, sofern der Kartenschlucker im Spiel ist. Die Ersatzkarte wird sofort gespielt und nicht erneut getauscht. Nach Wiederbelebung und erneutem Tod ist der Tausch der neu erhaltenen Karte wieder möglich. „Kartenschlucker im Spiel“ ist hinsichtlich Tod und Rollenverlust noch präzisierungsbedürftig und wird weder als „lebt“ noch als „war in der Startbesetzung“ ausgelegt. **Beantwortet in der zweiten Antwortrunde (Abschnitt „Kartenschlucker, Grundregeln“ unten): Tausch nur, solange eine lebende Person die Rolle besitzt.**
- **4B (Zusatzfähigkeiten):** Vorgesehen bleiben: ab zwei Stapeln nachts töten, ab fünf Stapeln ein Schild, alle drei Nächte öffentliche Ansage der Stapelzahl, Sieg bei zehn Stapeln. Kosten, Verbrauch, Zeitpunkte und Wechselwirkungen sind damit nicht entschieden. **Wortlaut teilweise ersetzt in der zweiten Antwortrunde (siehe unten): Tötung und Schild sind kostenpflichtige Nachtaktionen, der Sieg bei zehn Stapeln ist eine Aktion und kein Automatismus; die Ansage gilt in den festen Nächten 3, 6, 9.**
- **5A (Tod des Kartenschluckers):** Beim Tod bleiben seine Stapel erhalten. Solange er tot ist, sammelt er keine neuen Stapel und gewinnt nicht. Nach Wiederbelebung setzt er mit dem vorhandenen Stapelstand fort. Nicht entschieden: Zurücksetzen oder Wiederherstellen eines verbrauchten Schilds.
- **6B (Fünf-Tote-Hinweis):** Sind bereits mindestens fünf Personen gleichzeitig tot und erhält eine lebende Person anschließend die Rolle Selbstmörder, darf der Hinweis ausgelöst werden, sofern er in dieser Partie noch nicht ausgelöst wurde. Eine entsprechende Spielleiterkorrektur zählt ebenfalls. Ersetzt die offene Randfallfrage aus DA-86 und Entscheidung B.

**Weiter offen (nicht entschieden, nicht umgesetzt):** Bedeutung von „im Spiel“ bei Tod und Rollenverlust (3A); Kosten, Pflicht und Reichweite der Tötungsfähigkeit, Art und Häufigkeit des Schilds, Zählbeginn der Drei-Nächte-Ansage, Verbleib der Stapel bei Rollenwechsel, Schild bei Tod (4B, 5A); der Inhalt jeder einzelnen Karte (2C); der Kartentext für Solo- und neutrale Personen; Öffentlichkeit des Tauschs und der Stapelzahl. Die geordnete Fragenliste steht in der Arbeitsliste (Abschnitte 7 und 8). Nicht entschieden und im Verhalten unverändert: Wird ein toter Selbstmörder wiederbelebt und bleiben dabei fünf oder mehr Personen tot, löst das keinen Hinweis aus (`test_open_case_reviving_the_death_seeker_while_five_stay_dead_is_unchanged`, kein Beschluss).

**Nachtrag (dritte Antwortrunde, 30.09.2026):** Teilweise beantwortet: Schild bei Tod und Rollenverlust (unverbrauchter Schild bleibt), Inhalt der Ansage (Gesamtzahl) und Zeitpunkt des Spielens (zwei feste Kartenfenster). Siehe Abschnitt „Totenreichkarten: Kartenfenster, Schild, Stapelansage, Wiederbelebungskarten“ unten. Der Originaltext dieses Abschnitts bleibt unverändert.

**Umsetzung (Umfang):** Ausschließlich 6B. `GameSession._observe_five_dead` und `_rescan_five_dead` erhalten den Zustand vor dem Befehl; neue Funktion `PresentationCue.death_seeker_gained`. Kein Speicherschema, keine Regelversion, kein Audio, keine Tondatei, keine Kartenmechanik. Alles übrige aus diesen Entscheidungen ist reine Dokumentation.

**Ableitungen (technisch abgeleitet, nicht bestätigt):**

- Eine Rollenübernahme im Sinn von 6B ist jede Änderung, nach der eine lebende Person die Rolle Selbstmörder hat und sie im Zustand vor dem Befehl nicht hatte (Spielleiterkorrektur `set_role` und geerbte Rolle). Wiederbelebung ohne Rollenwechsel zählt nicht.
- Sie gilt als neuer Auslöseversuch, sobald mindestens fünf Personen tot sind. Geschieht sie in der Nacht, wird der Versuch erst mit der Morgenauflösung öffentlich ausgewertet; ist die Person dann nicht mehr lebende Selbstmörderin, ist es ein erfolgloser Versuch, der den Hinweis nicht verbraucht (Entscheidung B).
- Alle übrigen Regeln bleiben: öffentliche Phase, abgeschlossene Todesketten, kein Hinweis beim Laden, Wiederholen und Neuzeichnen, Rückgängig macht eine Auslösung ungeschehen, keine Namen, keine Rollen, kein Zufall, keine Wirkung auf den Zustand.
- Tests in `test_five_dead_cue`: Rollenübernahme bei fünf Toten genau ein Hinweis, tote Person und weniger als fünf Tote ohne Hinweis, Speichern und Laden vor und nach der Übernahme, Rückgängig und Wiederholen, Rollenübernahme in der Nacht, ausstehender Randfall. Mit einer künstlich wirkungslosen `death_seeker_gained` sind vier dieser Tests rot (einmal geprüft).

## Kartenschlucker, Grundregeln (zweite Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (zweite Runde) auf die Fragen KS-01 bis KS-05 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md` samt eigener Ergänzungen zu Nachtaktion, Schild und Sieg. Die Antworten kamen als zusammenhängender Regeltext ohne Buchstabenwahl; die Zuordnung zu den Fragen-IDs steht bei den Punkten und ist meine Zuordnung. Diese Entscheidungen **ersetzen** widersprechende frühere Vorschläge (Liste am Ende). Der Kartenschlucker ist weiterhin **nicht implementiert**; es gibt keinen Karten-Code.

**Bestätigt (Product Owner):**

- **Tausch (KS-01 und Ergänzung):** Totenreichkarten dürfen nur getauscht werden, solange eine lebende Person die Rolle Kartenschlucker besitzt. Jeder zulässige Tausch gibt dem Kartenschlucker einen Stapel. Weiter gilt 3A: Originalkarte einmal tauschen, Ersatzkarte sofort spielen und nicht erneut tauschen; nach Wiederbelebung und erneutem Tod gilt das für die neu erhaltene Karte wieder.
- **Nachtaktion (KS-02, ersetzt die Vorschläge kostenlos oder Pflicht):** Der Kartenschlucker wird jede Nacht geweckt und wählt genau eine Aktion: Kopf schütteln = nichts tun. Zwei Finger = zwei angesammelte Karten/Stapel abgeben und eine Person töten (freiwillig, höchstens einmal pro Nacht). Fünf Finger = fünf angesammelte Karten/Stapel abgeben und einen Schild kaufen. Zehn Finger = zehn angesammelte Karten/Stapel abgeben und seinen Sieg auslösen. Keine Kombination mehrerer Aktionen in derselben Nacht. Unzureichendes Guthaben erlaubt die jeweilige Aktion nicht.
- **Schild (KS-03, ersetzt „ab 5 Stapeln ein Schild“):** Ein gekaufter Schild bleibt bestehen, bis er einen Tod verhindert. Höchstens ein Schild gleichzeitig. Kein kostenloser Schild beim Erreichen von fünf Stapeln, keine automatische Erneuerung pro Nacht.
- **Sieg (ersetzt „Bei zehn Stapeln gewinnt er sofort“, beantwortet KS-13 im Kern):** Zehn Stapel allein lösen keinen Sieg aus. Die Person entscheidet sich bei ihrer Nachtaktion mit zehn Fingern dafür und gibt zehn Stapel ab. Die bestehende technische Spielleiterbestätigung eines Siegkandidaten bleibt erhalten (kein zusätzlicher morgendlicher Wartezeitpunkt).
- **Öffentliche Ansage (KS-04):** Feste Nächte 3, 6, 9 usw., sofern er lebt und die Rolle besitzt.
- **Stapel und Rollenwechsel (KS-05):** Stapel gehören zur Person. Ein neuer Träger der Rolle beginnt bei null. Beim bisherigen Träger ruhen die Stapel; erhält diese Person die Rolle zurück, sind ihre vorhandenen Stapel wieder nutzbar. Beim Tod bleiben Stapel erhalten, die tote Person sammelt nicht und gewinnt nicht (5A). Nach Wiederbelebung geht es mit dem gespeicherten Stapelstand weiter.
- **Begriffe:** „Karten abgeben“ und „Stapel ausgeben“ bezeichnen das angesammelte Guthaben des Kartenschluckers. Daraus folgt keine Regel zum Entfernen fremder Totenreichkarten oder zum Rückgängigmachen ihrer Wirkungen. Eine physische Darstellung des Guthabens ist nicht festgelegt.

**Ersetzt (nicht mehr gültig):**

- Rollentext „Bei 10 Stapeln gewinnt er sofort“ (`dossiers/solos-b.md`): Sieg nur durch die Zehn-Finger-Aktion mit Abgabe von zehn Stapeln.
- 4B, Wortlaut „ab zwei Stapeln nachts töten“ und „ab fünf Stapeln ein Schild“ als Schwellen ohne Kosten: jetzt kostenpflichtige Aktionen (zwei bzw. fünf Stapel werden abgegeben).
- Legacy-Verhalten (nur historisch): Tötung ab 2 Stapeln ohne Kosten (`chunk:226-233`), Schild wird ab 5 Stapeln jede Nacht neu gesetzt (`chunk:235`), Sieg automatisch bei 10 Stapeln (`ui/core.js:241-247`).
- Vorlage 13, Frage 4 Antwort A („nur sammeln und bei 10 gewinnen“) und die Empfehlungen der Fragen KS-02 bis KS-04 der Arbeitsliste (Version vom Vortag): durch die tatsächlichen Antworten überholt.
- Aussage der Arbeitsliste, Kartenvergabe bei jeder Person widerspreche unterschiedlichen Kartentexten (ÜB-1): korrigiert; siehe Arbeitsliste.

**Vorhandene Entscheidungen, die für die offenen Punkte gelten (nichts Neues beschlossen):**

- Siegkonflikte: Gleichzeitig erfüllte Siegbedingungen bilden eine Kandidatenmenge ohne Priorität, aus dem endgültigen Zustand nach allen Reaktionen; die Spielleitung bestätigt genau einen oder lehnt alle mit Grund ab (DR-02, DR-14, Zeile „Alle gleichzeitig erfüllten Siegbedingungen“); ein erfüllter Sieg wird nach Ablehnung weiter vorgeschlagen (F-11).
- Durchdringung (RM-DR-005): „Ignoriert Schutz“ durchdringt nicht die persönlichen Schilde der Einzelsiegrollen. Ob der Kartenschlucker-Schild darunter fällt und welche Todesarten er verhindert, ist **nicht entschieden**; die Aussage ist nur ein Hinweis auf die vorhandene Regel.
- Spielleiterkorrekturen sind von Rollenwirkungen ausgenommen; Stimmen werden nicht digital gezählt (RM-DR-008).

**Weiter offen (nicht entschieden, nicht erfunden):**

- Schild: welche Todesarten er verhindert, Zusammenspiel und Reihenfolge mit anderen Schutz- und Abfangwirkungen; Verhalten bei Rollenverlust, Tod und Wiederbelebung (ausdrücklich nicht aus der Stapelregel abzuleiten).
- Tötung: Ziel (auch die eigene Person?), Todesursache, Zeitpunkt (Nacht oder Morgen), Schutz und Durchdringung, Reihenfolge mit anderen Todesregeln.
- Ansage: Zeitpunkt (vor oder nach der Aktion, Morgen oder Nacht) und Inhalt (Guthaben, Gesamtzahl oder Stufe); Verhalten bei übersprungenen Nächten.
- Sieg: Wann genau der Kandidat entsteht, was geschieht, wenn die Spielleitung ihn ablehnt oder er in derselben Nacht stirbt (Guthaben zurück oder verbraucht), und wie ein Konflikt mit gleichzeitigen Siegen dargestellt wird (Regeln DR-02, DR-14 gelten; Einzelfälle offen).
- Nachtablauf: Wie die Wahl (Finger) am Tisch erfasst und in der App eingetragen wird; Wecken bei Nächten, die durch Karten ausfallen.
- Tausch: Öffentlichkeit, Ablauf am Tisch, Auslösung und Bestätigung; Öffentlichkeit der Stapelzahl außerhalb der Ansage.
- Der bekannte offene Wiederbelebungsfall des Fünf-Tote-Hinweises bleibt offen.
- Nachtrag (dritte Antwortrunde, 30.09.2026): Beantwortet sind Schild bei Rollenverlust, Tod und Wiederbelebung (bleibt, unverbrauchter Schild), Wirkung des Schilds gegen Rollenfähigkeit und Hinrichtung, Inhalt der Ansage (Gesamtzahl) und der Zeitpunkt des Spielens einer Karte (zwei Kartenfenster). Offen bleiben die übrigen Punkte dieser Liste sowie die neuen Punkte im folgenden Abschnitt.

## Totenreichkarten: Kartenfenster, Schild, Stapelansage, Wiederbelebungskarten (dritte Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (dritte Runde) auf die Fragen KS-06 bis KS-10 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md`. Die Antworten kamen als zusammenhängender Regeltext ohne Buchstabenwahl; die Zuordnung zu den Fragen-IDs ist meine Zuordnung. Diese Entscheidungen **ersetzen** widersprechende frühere Empfehlungen (Liste am Ende der bestätigten Punkte). Es ist nichts implementiert: kein Karten-Code, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der früheren Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **Schild, Wirkung (KS-06):** Der Schild verhindert einen Tod durch Rollenfähigkeit oder Hinrichtung, auch durch Angriffe, die sonst Schutz ignorieren. Eine direkte Spielleiterkorrektur bleibt möglich. Bestehende Regeln bleiben: fünf Stapel bezahlen, höchstens ein Schild gleichzeitig, Verbrauch beim Abfangen eines Todes.
- **Schild, Bindung (KS-07):** Der gekaufte Schild gehört zur Person und bleibt auch bei Rollenwechsel wirksam. Ein noch unverbrauchter Schild bleibt über Tod und Wiederbelebung erhalten. (Ersetzt die Empfehlung, der Schild ruhe bei Rollenverlust, und beantwortet den in 5A offen gelassenen Schild bei Tod für den unverbrauchten Schild.)
- **Öffentliche Stapelansage, Inhalt (KS-08):** Genannt wird die Gesamtzahl aller gesammelten Stapel, ohne Ausgaben abzuziehen. Begründung des Product Owners: Käufe sollen durch die Ansage nicht verraten werden. Verfügbares Guthaben und insgesamt gesammelte Stapel sind deshalb verschiedene Werte. Keine öffentliche Kaufmeldung und keine zusätzliche öffentliche Anzeige des Restguthabens. Das ist ausdrücklich keine Zusage, dass Spieler aus sichtbaren Spieleffekten keinerlei Rückschlüsse ziehen können. Feste Ansagenächte 3, 6, 9 bleiben (KS-04). Der genaue Ansagezeitpunkt bleibt offen (KS-12) und wird nicht beiläufig entschieden.
- **Kartenfenster (KS-09, ersetzt das Modell „sofort beim öffentlichen Tod“):** Tote werden zweimal am Tag gefragt, ob sie ihre Totenreichkarte einsetzen möchten: (1) zu Beginn des Tages, vor der Diskussion; (2) am Tagesende, nach der Hinrichtung und allen dadurch ausgelösten Todeseffekten. Im zweiten Fenster dürfen auch die gerade Verstorbenen teilnehmen. Eine Originalkarte darf aufbewahrt werden. In beiden Fenstern darf eine tote Person ihre Originalkarte einsetzen, sie unter den bestätigten Voraussetzungen tauschen oder vorerst nichts tun.
- **Tausch, Präzisierung:** Nur erlaubt, solange eine lebende Person die Rolle Kartenschlucker besitzt (KS-01). Einmal pro erhaltener Originalkarte. Die Ersatzkarte wird sofort gespielt und darf nicht erneut getauscht werden. Nach Wiederbelebung und erneutem Tod gilt die bereits bestätigte neue Kartenvergabe (1A) mit neuer Tauschmöglichkeit. Daraus folgt keine zusätzliche freie Nutzung und keine Tauschmöglichkeit außerhalb der beiden Fenster.
- **Wiederbelebungskarten (KS-10, ersetzt die Kartenbedingung „passende Rolle lebt“):** Sie gehören nur zu Partien, die bereits zu Beginn als Wiederbelebungsrunde eingerichtet sind. Grundlage ist die bestehende bestätigte Ableitung des Wiederbelebungsmodus (DI-01, `GameState.revival_round`, aus der Startbesetzung abgeleitet); es gibt keine neue frei wählbare Setup-Option. Sterben die entsprechenden Wiederbelebungsrollen später oder verlieren ihre Rolle, bleiben diese Karten weiter im Kartenbestand und nutzbar. Es gibt beim späteren Ziehen oder Spielen keine Prüfung „passende Rolle lebt noch“. Wiederbelebungskarten dürfen eine normale Partie nicht nachträglich in eine Wiederbelebungsrunde verwandeln.

**Ersetzt (nicht mehr gültig):**

- Sofortiges Spielen der Originalkarte beim öffentlichen Tod (Empfehlung A zu KS-09 der Arbeitsliste, Stand 30.09.2026): jetzt zwei feste Kartenfenster.
- Öffentliche Ansage der aktuellen Reststapelzahl (Empfehlung A zu KS-08 und Legacy-Text „Das Dorf erfährt: Kartenschlucker hat N Stapel.“): jetzt Gesamtzahl aller gesammelten Stapel.
- „Schild ruht bei Rollenverlust“ (Empfehlung B zu KS-07): jetzt bleibt er wirksam.
- Lebende Wiederbelebungsrolle als Voraussetzung beim Ziehen oder Spielen (Legacy-`deathCardRequirements`, Empfehlung A zu KS-10, Bedingung ÜB-5): entfällt als Prüfung.

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- Verfügbares Guthaben und insgesamt gesammelte Stapel sind zwei getrennte Zahlen je Person. Für die Gesamtzahl ist bei Rollenwechsel eine Behandlung analog zu den Stapeln (KS-05) naheliegend, aber nicht bestätigt.
- Das erste Kartenfenster schließt die zu Tagesbeginn bereits Toten ein, also auch Personen, die in der Nacht gestorben sind (folgt aus „Tote werden gefragt“, nicht ausdrücklich gesagt).
- Ein verbrauchter Schild wird durch eine Wiederbelebung nicht wiederhergestellt (folgt aus „Verbrauch beim Abfangen“).
- Die Ableitung `revival_round` gilt nach dem bestehenden Stand die ganze Partie. Die Frage aus RM-DR-141.4 („Totenkarten-Aktivierung nach Verbrauch“) und Dossier-Frage 6 (bleiben Wiederbelebungs-Totenkarten nach Verbrauch aktiv?) ist im Kern damit beantwortet: sie bleiben. Die Zuordnung zu RM-DR-141.4 ist meine.

**Weiter offen (nicht entschieden, nicht erfunden):**

- Reihenfolge mehrerer Toter innerhalb eines Kartenfensters.
- Neue Todesfälle oder Wiederbelebungen durch eine gerade gespielte Karte (auch: darf eine dabei Wiederbelebte im selben Fenster wieder teilnehmen?).
- Verhältnis zwischen Kartenfenster und bereits anstehender Siegprüfung (besonders am Tagesende).
- Verhalten einer aufbewahrten Karte bei Wiederbelebung, auch im Verhältnis zur neuen Karte nach erneutem Tod (1A).
- Tagesende ohne Hinrichtung: gibt es das zweite Fenster trotzdem?
- Kartenschlucker-Tötung: Ziel, Todesursache, Zeitpunkt, Schutz und Durchdringung (KS-11).
- Schild-Reihenfolge mit anderen Schutz- und Abfangwirkungen sowie verhinderte Hinrichtung (KS-21). Außerdem ungeklärt, ob Rudelangriff, Karteneffekte und Todesketten (Todeseffekte) unter „Rollenfähigkeit“ fallen, und ob „höchstens ein Schild gleichzeitig“ je Person oder insgesamt gilt, seit der Schild an die Person und nicht mehr an die Rolle gebunden ist.
- Ansagezeitpunkt und Verhalten bei übersprungenen Nächten (KS-12); Bezug „nächste Nacht“ und „nächster Lynch“ je Kartenfenster (ÜB-3).
- Welche Karten Wiederbelebungskarten sind und welcher Kartenbestand in normalen Partien gilt (ÜB-6, KS-16, KS-17).
- Öffentlichkeit von Tausch und Karte sowie Ablauf am Tisch (KS-15, ÜB-7, ÜB-9).

## Rückkehrkarten: Zweites Leben, Wiedergeburt, Befreiung (vierte Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (vierte Runde) auf die fünf Fragen in Abschnitt 10 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md` (zugleich KS-18, KS-19 und KS-28 teilweise). Die Antworten kamen als zusammenhängender Regeltext ohne Buchstabenwahl; die Zuordnung zu den Fragen ist meine Zuordnung. Diese Entscheidungen gelten nur für `segen_08`, `wende_04` und `wende_07`. Es ist nichts implementiert: kein Karten-Code, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`segen_08` Zweites Leben, Vergabebedingung:** Die Karte darf nur vergeben werden, wenn mindestens zwei ANDERE tote Personen derselben Fraktion wie der Empfänger vorhanden sind. Der Empfänger zählt nicht zu diesen zwei Personen und ist als Wiederbelebungsziel ausgeschlossen. Das gilt entsprechend für Dorf und Werwölfe. Welche Variante Einzelsiegrollen erhalten, ist damit nicht entschieden.
- **`segen_08`, Angebot und Wahl:** Die App bietet bis zu drei passende tote Personen als Namen zur Auswahl an. Gibt es mehr als drei passende Personen, wählt der gespeicherte Zufallsgenerator drei aus. Die Auswahl wird gespeichert; Neuladen erzeugt keine neuen Namen. Der Kartenbesitzer wählt durch Antippen eines angebotenen Namens.
- **`segen_08`, Sichtbarkeit:** Dass die angebotenen Namen dem Kartenbesitzer die Fraktion dieser Personen verraten, ist ausdrücklich gewollt. Diese Erlaubnis gilt für den Kartenbesitzer, nicht automatisch für eine öffentliche Anzeige.
- **`segen_08`, späteres Ausspielen:** Ist beim Ausspielen nur noch eine passende andere tote Person übrig, wird diese allein angeboten. Ist keine vorhanden, bleibt die Karte ungespielt erhalten.
- **`wende_04` Wiedergeburt:** Die Spielleitung wählt die wiederzubelebende Person innerhalb der erlaubten Fraktion. Sie darf dabei auch die Person wählen, die die Karte spielt. (Formulierung in der fünften Antwortrunde präzisiert, keine Regeländerung.)
- **`wende_07` Befreiung, Ziel:** Die Person, die die Karte spielt, wählt das Ziel innerhalb der erlaubten Fraktion.
- **`wende_07`, erneuter Tod:** Die zurückgeholte Person stirbt erst nach dem einmaligen Fähigkeitseinsatz erneut. Ohne Fähigkeitseinsatz bleibt sie am Leben. Es gibt keinen automatischen Tod am nächsten Morgen und keine neu eingeführte Frist. Rollen ohne aktiv einsetzbare Fähigkeit werden durch diese Entscheidung nicht ausgeschlossen. Welche Vorgänge bei passiven Fähigkeiten, Rudelaktionen oder mehrstufigen Fähigkeiten als Einsatz zählen, ist damit nicht pauschal entschieden.
- **Rückkehrrolle (alle drei Karten):** Die Wiederbelebung stellt die Rolle vom Todeszeitpunkt wieder her. Hat eine andere Person diese Rolle inzwischen ebenfalls, bleibt die Wiederbelebung trotzdem zulässig. Beispiel: Anna starb als Orakel, jemand erbte die Rolle; Anna kehrt als Orakel zurück, es gibt dann zwei Orakel. Kein Ersatz durch Dorfbewohner oder Werwolf allein wegen einer bereits vergebenen Rolle. Die Einmaligkeit der Startrollen (PE-07) gilt weiterhin nur für die Startbesetzung. Die bestätigten Regeln zum Zurücksetzen bei Wiederbelebung bleiben (Abschnitt „Rollenaudit · Wiederbelebungsrollen“: begrenzte Einsätze zurück, durch Tod beendete Bindungen bleiben beendet, RM-DR-011.2).
- **Abgrenzung:** Die Rückkehrrolle ist eine Kartenentscheidung. Sie wird nicht ungefragt auf abweichende Regeln anderer Wiederbelebungsfähigkeiten übertragen (Frankenstein vergibt weiter nur eine Rolle, die gerade niemand hat, W-04).

**Ersetzt (nicht mehr gültig):**

- Abschnitt 10, Frage 1 (Fehlgriff bei `segen_08`, Optionen A bis C und Empfehlung A): erledigt, weil nur passende Namen angeboten werden. Der Überarbeitungsvorschlag „SL prüft still gegen die Fraktion, sonst verfällt die Wirkung“ ist ersetzt.
- Abschnitt 10, Frage 3, Empfehlung B (feste Frist von einer Nacht): ersetzt. Option C (Rollen ohne einsetzbare Fähigkeit ausschließen) wurde ausdrücklich nicht gewählt.
- Abschnitt 10, Frage 4, Empfehlung B (Standardrolle, wenn die Rolle schon vergeben ist): ersetzt durch die doppelte Rolle.
- Abschnitt 10, Frage 5, Empfehlung C (Zufall wählt das Ziel bei `wende_07`): ersetzt durch die Wahl der Kartenspielerin.
- Offener Punkt „Darf die Kartenträgerin bei `segen_08` sich selbst wählen, und was gilt ohne passende tote Person“: für `segen_08` beantwortet (nein; Karte bleibt ungespielt erhalten). Für `wende_04` und `wende_07` gilt die Ohne-Ziel-Frage weiter als offen.
- Im Kern bestätigt, keine Ersetzung: Frage 2, Option A (die SL wählt frei und darf dabei auch die Kartenspielerin wählen).

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- Die Vergabebedingung von `segen_08` ist eine Prüfung beim Vergeben der Karte, nicht beim Ausspielen. Ist sie nicht erfüllt, wird die Karte nicht vergeben; dass stattdessen eine andere Karte gezogen wird, folgt aus 1A (jede Person erhält beim Tod eine Karte), ist aber nicht ausdrücklich gesagt.
- Dass „Fraktion des Empfängers“ die Kartenfraktion des Textes (Wolf oder Dorf) meint, ist meine Lesart.

**Weiter offen (nicht entschieden, nicht erfunden):**

- `segen_08`: Wann die zufällige Vorauswahl erstmals festgelegt wird und wie bereits angebotene, inzwischen ungültige Ziele ersetzt werden. Außerdem: Variante für Einzelsiegrollen; ob die Vergabebedingung auch für eine Ersatzkarte nach Tausch gilt; welche Fraktion zählt, wenn sich die Fraktion des Empfängers zwischen Vergabe und Ausspielen ändert (ÜB-1).
- `wende_04`, `wende_07`: Ob die Vergabebedingung „mindestens zwei andere Tote“ auch hier gilt; ob die Karte ohne passendes Ziel aufbewahrt wird oder verfällt. Bei `wende_07` zusätzlich: ob sich die Kartenspielerin selbst wählen darf, ob wie bei `segen_08` Namen angeboten werden, und was als Fähigkeitseinsatz zählt.
- Alle drei: Zeitpunkt und Sichtbarkeit der Rückkehr (ab wann die Person handelt, was öffentlich wird), Wirkung eines lebenden Wächters am Tor auf eine zurückkehrende Wölfin (RM-DR-149), Verhältnis zu den offenen Kartenfenster-Fragen (KS-22 bis KS-26).
- `wende_04`, `wende_07` und `segen_08` sind damit **nicht vollständig spezifiziert** und nicht implementiert. Die Detailfragen stehen in der Arbeitsliste als KS-38 bis KS-40.

## Rückkehr- und Rollenkarten: Phoenix, Geheimrat, Neuer Anfang, Rollenroulette (fünfte Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (fünfte Runde) auf die fünf Fragen in Abschnitt 12 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md` (KS-29 bis KS-33, zugleich KS-19, KS-20 und KS-34 teilweise). Die Antworten kamen als zusammenhängender Regeltext ohne Buchstabenwahl; die Zuordnung zu den Fragen ist meine Zuordnung. Diese Entscheidungen gelten nur für `loki_10`, `wende_12` (Dorf), `schicksal_08` und `loki_06`. Es ist nichts implementiert: kein Karten-Code, keine Würfel, keine Zufallsziehung, keine Animation, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`loki_10` Phoenix, Würfel:** Zwei sichtbare virtuelle Würfel werden in der App gerollt. Würfel 1 hat die Seiten 1, 2, 3, 4, 5, 6 und bestimmt die Anzahl der Rückkehrer. Würfel 2 hat die Seiten 1, 1, 2, 2, 3, 3 und bestimmt die Lebensdauer in Tagen.
- **`loki_10`, Lebensdauer:** Der Tag des Ausspielens zählt bereits als erster Tag. Die zurückgeholten Personen sterben am Ende des ausgewürfelten Tages erneut. Beispiel: Ausspielen an Tag 4, zweiter Würfel zeigt 2: erneuter Tod am Ende von Tag 5.
- **`loki_10`, Auswahl:** Die App wählt zufällig verschiedene tote Personen aus. Die tote Person, die Phoenix spielt, ist ausdrücklich ausgeschlossen. Gibt es weniger andere Tote als gewürfelt, kehren alle verfügbaren anderen Toten zurück. Es wird nicht erneut gewürfelt.
- **`loki_10`, Wiederbelebungsrunden:** Die bestehende Beschränkung auf Wiederbelebungsrunden bleibt bestehen.
- **`wende_12` Geheimrat, Dorfvariante:** Jede Frage ist erlaubt. Die Spielleitung muss wahrheitsgemäß antworten. Auch eine Frage wie „Wer sind alle Werwölfe?“ ist erlaubt. Es gibt keine Beschränkung auf Ja/Nein-Fragen.
- **`schicksal_08` Neuer Anfang:** Die Person, die die Karte spielt, wählt zwei lebende Personen. Die Spielleitung bestimmt deren neue Rollen. Jede neue Rolle gehört zur jeweiligen bisherigen Fraktion. Ein zufälliger Rollenvorschlag ist keine verbindliche Auswahlregel.
- **`loki_06` Rollenroulette:** Zwei zufällige lebende Personen derselben Fraktion tauschen ihre Rollen. Erlaubt sind zwei Dorfpersonen oder zwei Werwölfe. Einzelsiegrollen sind ausgeschlossen. Beide Betroffenen werden heimlich informiert.
- **Rollenwechsel durch `schicksal_08` und `loki_06`:** Die neue Rolle beginnt frisch, beispielsweise mit verfügbaren Tränken. Persönliche Zustände bleiben nach den bestehenden Regeln erhalten. Bereits bestätigte Sonderregeln, insbesondere persönliche Kartenschlucker-Stapel und gekaufte Schilde, bleiben bestehen. Es werden weder pauschal sämtliche Zustände gelöscht noch sämtliche Rollenzustände übertragen. Diese Entscheidung wird nicht ungefragt auf andere Rollenwechselmechaniken ausgeweitet.
- **Formulierungskorrektur `wende_04` Wiedergeburt (keine Regeländerung):** Die Spielleitung wählt die wiederzubelebende Person. Sie darf dabei auch die Person wählen, die die Karte spielt. Die frühere Kurzform „SL wählt, Selbstwahl erlaubt“ konnte so gelesen werden, als wähle die Kartenspielerin sich selbst; das ist nicht gemeint. Korrigiert im Abschnitt „Rückkehrkarten (vierte Antwortrunde)“ und in den Arbeitsdokumenten.

**Ersetzt (nicht mehr gültig):**

- Arbeitsliste Abschnitt 12, KS-29: Empfehlung A (Runde ist eine Nacht, Tod in der Morgenauflösung) ersetzt. Im Kern gewählt ist Option B (Runde ist ein Tag, Tod am Ende des Tages), in geänderter Form: Der Tag des Ausspielens zählt schon als erster Tag.
- KS-30: Empfehlung B (nur Ja/Nein-Frage zum Spielzustand) ersetzt; bestätigt ist Option A (jede Frage) für die Dorfvariante.
- KS-31: Empfehlung A (Generator zieht die Rollen) ersetzt; im Kern bestätigt ist Option B (Kartenspielerin wählt, Spielleitung bestimmt die Rollen), ergänzt um die Bindung an die bisherige Fraktion.
- KS-32: Empfehlung B (Einzelsiegrollen zählen als Fraktion) ersetzt; bestätigt ist Option A (nur Dorf und Werwölfe). Option C (Kartenspielerin nennt die Fraktion) nicht gewählt.
- KS-33: Empfehlung A im Kern bestätigt („wie jeder Rollenwechsel“, frischer Start, Personengebundenes bleibt), aber ausdrücklich nur für diese zwei Karten und ohne pauschales Löschen. Die Optionen B und C sind nicht gewählt.
- KS-34, Teil „Würfel: Generator oder Tisch“ und „wer zählt zu den zufälligen Spielern“ und „weniger Tote als der erste Würfel“: beantwortet (siehe oben).

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- Die App-Würfel und die Auswahl der Rückkehrer laufen über den gespeicherten Zufallsgenerator (Projektregel: Zufall nur über den gespeicherten Generator). Der Product Owner hat nur „in der App gerollt“ gesagt.
- „Sichtbar“ lese ich als: Die Würfelergebnisse werden in der App gezeigt. Für wen (nur Spielleitung oder öffentlich am Tisch), ist nicht entschieden.
- Für die Auswahl der Rückkehrer wurde keine Fraktionsbeschränkung genannt; ich habe keine ergänzt. Alle anderen Toten kommen in Frage.
- Die Lebensdauer ist ein Zähler in Tagen des App-Tageszählers.
- Die Rückkehrrolle der vierten Runde („Rolle vom Todeszeitpunkt, doppelte Rolle zulässig“) wurde für `segen_08`, `wende_04` und `wende_07` beschlossen. Für Phoenix hat der Product Owner sie nicht bestätigt; die Arbeitsliste hatte sie dort vorschnell als gegeben beschrieben und ist korrigiert.

**Weiter offen (nicht entschieden, nicht erfunden):**

- `loki_10`: Reihenfolge zwischen dem zweiten Kartenfenster am Tagesende und dem Ablauf der Lebensdauer, insbesondere Ausspielen am Tagesende mit Lebensdauer 1 (kein zusätzlicher Lebenstag wird erfunden). Verhalten ohne andere Tote. Früherer Tod und erneute Wiederbelebung während der Frist. Rückkehrrolle bei Phoenix. Für wen die Würfel und die Namen sichtbar sind. Verhältnis zu KS-23 und zur Siegprüfung.
- `wende_12`: Öffentlichkeit von Frage und Antwort der Dorfvariante (nicht festgelegt), Zeitpunkt der Frage. Die Wolfsvariante ist nicht entschieden (Ablauf, Art der Hinweise, Bezug „in dieser Nacht“, Aufrufreihenfolge, Öffentlichkeit). Ob die Szenariobedingung „nur in Spielen mit Wiederbelebungs-Szenarien“ auch für den Wolf-Text gilt.
- `schicksal_08`: Vorrat der neuen Rollen (bisherige Rolle erlaubt, Sonderrollen wie Trugbilderwolf und Selbstmörder), was „bisherige Fraktion“ für Einzelsiegrollen heißt, weniger als zwei passende Lebende, Zeitpunkt und Sichtbarkeit.
- `loki_06`: Verhalten bei weniger als zwei Lebenden in einer Fraktion, Zufall über den gespeicherten Generator (abgeleitet, nicht bestätigt), Sonderzustände beim Tausch (Scheinrolle des Trugbilderwolfs).
- Alle vier Karten sind damit **nicht vollständig spezifiziert** und nicht implementiert. Die Detailfragen stehen in der Arbeitsliste (KS-35 bis KS-37 und KS-46 bis KS-48).

## Phoenix-Tagesende, Geheimrat (Wolf), Heilende Hand, Blutpakt, Spiegelschutz (sechste Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (sechste Runde) auf die fünf Fragen in Abschnitt 14 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md` (KS-41 bis KS-45). Die Antworten kamen als zusammenhängender Regeltext, teils mit Kartenbezeichnung statt Buchstabenwahl; die Zuordnung zu den Fragen ist meine Zuordnung. Die Antworten zu `segen_01`, `segen_07` und `segen_11` betreffen ausdrücklich nur deren Dorfvarianten; unbesprochene Details der Wolfsvarianten bleiben offen. Es ist nichts implementiert: kein Karten-Code, keine Würfel, keine Zufallsziehung, kein Schild, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`loki_10` Phoenix, Reihenfolge am Tagesende (regulärer Fristablauf):** (1) Hinrichtung. (2) Dadurch ausgelöste Todeseffekte werden abgehandelt. (3) Phoenix-Rückkehrer sterben, deren Lebensdauer an diesem Tag endet. (4) Danach folgt das zweite Kartenfenster. Auch die durch den Fristablauf gerade Verstorbenen dürfen ihre neue Totenreichkarte in diesem zweiten Fenster bereits nutzen.
- **`loki_10`, Abgrenzung:** Diese Antwort regelt nur den regulären Fristablauf. Sie entscheidet nicht automatisch den Sonderfall, dass Phoenix erst im anschließenden (zweiten) Kartenfenster gespielt wird und die Lebensdauer einen Tag beträgt (der Ablaufschritt dieses Tages liegt dann schon vor dem Fenster). Dieser Fall wird weder als sofortiger Tod noch als zusätzlicher Lebenstag ausgelegt; er ist offen und als KS-55 gestellt.
- **`wende_12` Geheimrat, Wolfsvariante (Hinweise):** Hinweise an das Rudel erfolgen ausschließlich stumm, durch Gesten und Zeigen. Kein leises Sprechen. Daraus wird keine zusätzliche Tablet-Kommunikationsfunktion abgeleitet.
- **`segen_01` Heilende Hand, Dorfvariante:** Der auslösende Wolfsangriff wird verhindert. Zusätzlich erhält die betroffene Person einen persönlichen Schild nach den bereits bestätigten Schildregeln (dritte Runde). Dieser Schild verhindert einen späteren weiteren Tod, auch durch eine Hinrichtung oder einen sonst schutzignorierenden Rollenangriff. Höchstens ein solcher Schild gleichzeitig pro Person. Keine allgemeine Unsterblichkeit für die gesamte Nacht. Eine direkte Spielleiterkorrektur bleibt möglich.
- **`segen_07` Blutpakt, Dorfvariante:** Die Spielleitung bestimmt nach Ermessen, ob null, ein oder zwei Wölfe aufgedeckt werden. Keine feste Zuordnung anhand der Opferrolle und keine zufällige Zahl.
- **`segen_11` Spiegelschutz, Dorfvariante:** Die App bestimmt zufällig einen lebenden Wolf als Ersatzopfer. Es gilt die Projektregel für gespeicherten, reproduzierbaren Zufall. Keine Wahl durch Spielleitung oder Rudel.

**Ersetzt (nicht mehr gültig):**

- Arbeitsliste Abschnitt 14, KS-41: Empfehlung A (Tod aus Fristablauf als letzter Schritt des Tages, nach dem zweiten Fenster) ersetzt. Bestätigt ist der Ablauf von Option B (Tod vor dem zweiten Fenster, neue Karte im selben Fenster nutzbar). Der in Option B beschriebene Sonderfall (Phoenix im zweiten Fenster mit Lebensdauer 1 wirkt sofort) ist ausdrücklich nicht mitbestätigt.
- KS-42: Option A bestätigt (nur stumm). Option B (leises Sprechen) ausdrücklich ausgeschlossen, Option C (Tablet) nicht gewählt.
- KS-43: Im Kern Option A bestätigt (Schild nach den bestätigten Schildregeln, höchstens einer je Person). Ergänzt um die Verhinderung des auslösenden Angriffs und die Klarstellung „keine allgemeine Unsterblichkeit für die Nacht“. Optionen B (eigener Karten-Schild) und C (nur dieser eine Angriff) nicht gewählt.
- KS-44: Im Kern Option A bestätigt (Ermessen der Spielleitung, null bis zwei). Nicht bestätigt ist der Teil der Option, die Spielleitung „trage die Wölfe ein“: Wer die Wölfe auswählt, ist offen. Optionen B (feste Einteilung der Opferrollen) und C (Zufallszahl) nicht gewählt.
- KS-45: Option A bestätigt (gespeicherter Generator zieht einen lebenden Wolf). Optionen B (Spielleitung) und C (Rudel) nicht gewählt.

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- **Beschriftung „Reihenfolge A“:** Der Product Owner nannte den bestätigten Tagesend-Ablauf „Reihenfolge A“. Inhaltlich entspricht er Option B von KS-41 in Abschnitt 14 (dort ist Option A der Tod nach dem Fenster). Maßgeblich ist der beschriebene Ablauf, nicht der Buchstabe. Hinweis im Bericht, keine Regeländerung.
- Die neue Todeskarte der durch den Fristablauf Verstorbenen folgt aus 1A (jeder Tod gibt eine Karte, auch nach Wiederbelebung). Die Nutzung im zweiten Fenster ist bestätigt.
- „Ein solcher Schild“ bei `segen_01` lese ich als den bestätigten Schild. Ob dieser Schild und ein bereits gekaufter Schild sich den einen Platz je Person teilen, ist nicht ausdrücklich gesagt (KS-27).

**Weiter offen (nicht entschieden, nicht erfunden):**

- `loki_10`: Sonderfall Ausspielen im letzten Fenster mit Lebensdauer 1 (KS-55). Ohne andere Tote, früherer Tod und erneute Wiederbelebung in der Frist, Rückkehrrolle bei Phoenix, Sichtbarkeit von Würfeln und Namen, Verhältnis zu KS-23 und zur Siegprüfung (KS-46 bis KS-48).
- `wende_12`: Aufrufreihenfolge („als letztes“) und Bezugsnacht („in dieser Nacht“) der Wolfsvariante, Öffentlichkeit, Zeitpunkt, Szenariobedingung (KS-35). Die Dorfvariante bleibt wie in der fünften Runde bestätigt.
- `segen_01`: Reihenfolge des Schilds gegenüber bereits vorhandenen Schutzwirkungen (nicht ergänzt), Verhältnis zum gekauften Schild und „höchstens einer“ insgesamt (KS-27), Dauer von „nächstes Mal“ (ÜB-3), Wolf-Text (KS-49).
- `segen_07`: Ob die Information öffentlich oder privat ist und wer die betroffenen Wölfe auswählt; kein Opfer in der Nacht; Wolf-Text (KS-50).
- `segen_11`: Weitere Schutz- und Umleitungswechselwirkungen (Schild, Wächter am Tor, Heilende Hand), welche Wölfe zählen (Scheinrollen, Sonderwölfe), „Folgenacht“ (ÜB-3), Wolf-Text (KS-51).
- `loki_10`, `wende_12`, `segen_01`, `segen_07` und `segen_11` sind damit **nicht vollständig spezifiziert** und nicht implementiert.

## Verzweiflungsschrei, Notanker, Schicksalswende (Wolf), Phoenix-Ausnahme, Bezugszeitpunkt (siebte Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (siebte Runde) auf die fünf Fragen in Abschnitt 16 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md` (KS-52 bis KS-56). Die Antworten kamen als zusammenhängender Regeltext ohne Buchstabenwahl; die Zuordnung zu den Fragen ist meine Zuordnung. Die Antworten zu `wende_02`, `wende_05` und `wende_11` gelten ausdrücklich nur für diese Karten und werden nicht auf andere verhinderte Hinrichtungen, aufgeschobene Tode oder Verwandlungen übertragen. Es ist nichts implementiert: kein Karten-Code, kein Schutz, kein aufgeschobener Tod, keine Verwandlung, keine Würfel, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`wende_02` Verzweiflungsschrei, Zielwahl:** Die Person, die die Karte spielt, wählt das Ziel in der nächsten Nacht geheim. Die Wahl wird den anderen Spielern gegenüber nicht offengelegt. Die Fraktionsgrenzen bleiben: Die Wolfsvariante schützt einen Wolf, die Dorfvariante eine Dorfperson.
- **`wende_02`, Beginn und Dauer:** Der Schutz beginnt unmittelbar nach der geheimen Auswahl. Dorfvariante: gegen Wolfsangriffe in dieser Nacht und den nächsten zwei Nächten. Wolfsvariante: gegen Hinrichtung in den nächsten zwei Tagesphasen.
- **`wende_02`, verhinderte Hinrichtung:** Soll die geschützte Person hingerichtet werden, überlebt sie. Es gibt kein Ersatzopfer und keine erneute Abstimmung. Der übrige Tagesablauf, insbesondere das bestätigte Tagesend-Kartenfenster, wird dadurch nicht gestrichen.
- **`wende_02`, Geheimhaltung:** Aus der Geheimhaltung der Wahl folgt keine Garantie, dass sichtbare spätere Auswirkungen (etwa eine ausbleibende Hinrichtung) keinerlei Rückschlüsse erlauben.
- **`wende_05` Notanker (Wolf und Dorf):** Die Person mit aufgeschobenem Tod darf bis zu ihrem tatsächlichen Tod weiter Fähigkeiten einsetzen, abstimmen und normal handeln. Für Siegbedingungen zählt sie bereits als tot. Sie ist bis zum tatsächlichen Tod nicht allgemein als tot zu behandeln: daraus folgen keine vorzeitige Totenkarte, kein Tauschrecht und keine Wiederbelebungsmöglichkeit. Die bestehende Verschiebung auf den übernächsten Tag bleibt vorgesehen.
- **`wende_11` Schicksalswende, Wolfsvariante:** Der ausgewählte Wolf erhält genau eine Gelegenheit zur Verwandlung in der nächsten Nacht. Wird sie nicht genutzt, verfällt sie. Keine Verschiebung um weitere Nächte, keine dauerhaft wiederholbare Fähigkeit.
- **`loki_10` Phoenix, Ausnahme:** Wird Phoenix erst im zweiten Kartenfenster am Tagesende gespielt und beträgt die gewürfelte Lebensdauer einen Tag, bleiben die Rückkehrer bis zum Ende des nächsten Tages am Leben. Das ist eine ausdrücklich bestätigte Ausnahme von „Ausspieltag zählt als erster Tag“. Am Folgetag gilt die bestätigte Reihenfolge Hinrichtung, Todeseffekte, Phoenix-Fristablauf, zweites Kartenfenster; die dann Verstorbenen dürfen ihre neue Totenkarte in diesem Fenster nutzen. Die Ausnahme gilt nicht für andere Würfelergebnisse und nicht für das erste Kartenfenster.
- **Bezugszeitpunkt „nächste“ (ÜB-3):** „Nächste Hinrichtung“, „nächste Nacht“ und vergleichbare Angaben meinen das nächste entsprechende Ereignis nach dem Ausspielen. Eine morgens (erstes Fenster) gespielte Karte kann somit die Hinrichtung desselben Tages betreffen. Eine im zweiten Kartenfenster gespielte Karte betrifft die kommende Nacht beziehungsweise die nächste Hinrichtung des Folgetages. Ausdrücklich abweichende Kartenregeln gehen vor.

**Ersetzt (nicht mehr gültig):**

- Arbeitsliste Abschnitt 16, KS-52: Im Kern Option A bestätigt (Hinrichtung entfällt, keine neue Abstimmung, kein Ersatz). Nicht übernommen sind zwei Teile der Empfehlung: „Der Tag endet ohne Opfer“ (der Tagesablauf bleibt bestehen) und „die Spielleitung trägt ‚nicht vollstreckt‘ ein und nennt keinen Grund“. Optionen B (Neuabstimmung) und C (zweithöchste Stimmenzahl) nicht gewählt.
- KS-53: Empfehlung A (lebt in jeder Hinsicht, zählt bei der Siegprüfung als lebend) ersetzt. Bestätigt ist im Kern Option B (handelt normal, zählt für Siegbedingungen als tot), mit der Klarstellung, dass die Person sonst nicht als tot gilt. Optionen A und C nicht gewählt.
- KS-54: Empfehlung A (bestätigte Regeln der Rolle König Lykaon übernehmen, bis zu dreimal verzichten) ersetzt. Bestätigt ist Option B (genau eine Gelegenheit in der nächsten Nacht, dann verfallen). Optionen A und C nicht gewählt. Ob die übrigen Regeln der Rolle (V-03, V-08, V-09) innerhalb dieser einen Gelegenheit gelten, ist nicht gesagt.
- KS-55: Empfehlung B (Rückkehrer sterben beim Schließen des zweiten Fensters) ersetzt. Bestätigt ist inhaltlich Option C in beschränkter Form: ein zusätzlicher Lebenstag, aber nur für den Fall „zweites Fenster, Lebensdauer ein Tag“. Option A (Sofort-Tod) und Option B sind ausgeschlossen.
- KS-56: Option A (das nächste Ereignis nach dem Ausspielen) bestätigt, ergänzt um den Vorrang ausdrücklich abweichender Kartenregeln. B und C nicht gewählt. Dadurch ist ÜB-3 für den Bezug „nächste“ beantwortet; die Zählung von Dauerangaben („2 Tage“, „3 Tage“) ist bei `wende_02` durch die Antwort geregelt und bei anderen Karten weiter je Karte zu klären.
- KS-57 (Teilfragen zu `wende_02`): Beantwortet sind Zielwahl (durch die Kartenspielerin, geheim), Beginn (sofort nach der Wahl), Dauer (Dorf: diese und die nächsten zwei Nächte, Wolf: die nächsten zwei Tagesphasen) und die Beschränkung auf Wolfsangriffe (Dorf) beziehungsweise Hinrichtung (Wolf). Der Rest von KS-57 bleibt offen.

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- „Wolfsangriffe“ in der Dorfvariante von `wende_02` lese ich als Rudelangriff (RM-DR-004). Ob das für diese Karte gilt, ist nicht ausdrücklich gesagt.
- Die Wahl in der nächsten Nacht setzt einen Nachtschritt einer toten Person voraus. Ein solcher Schritt existiert bisher nicht. Seine Position in der Nachtreihenfolge ist nicht entschieden und wird nicht erfunden.
- Die Unterscheidung zwischen Zählstatus („zählt für Siegbedingungen als tot“) und Todesereignis (Todesreaktionen, Todeskarte, Wiederbelebbarkeit) ergibt sich aus der Antwort zu `wende_05`. Ihr Zusammenspiel mit Todesreaktionen, die die Siegprüfung ändern (Wolfskind, Lehrling), ist ein tatsächlicher Konflikt mit DR-14 und der Wolfskind-Regel und als KS-63 gestellt.
- Bei „bleiben bis zum Ende des nächsten Tages am Leben“ (Phoenix-Ausnahme) lese ich, dass die Rückkehrer die folgende Nacht mit allen Fähigkeiten erleben. Das ist nicht ausdrücklich gesagt, folgt aber aus „am Leben“.

**Weiter offen (nicht entschieden, nicht erfunden):**

- `wende_02`: Selbstwahl, fehlende gültige Ziele, Position der geheimen Wahl in der Nachtreihenfolge, ob der Schutz nach einem Treffer für die Restdauer bleibt, Zählung der „Tagesphasen“ bei einer Karte aus dem zweiten Fenster, Verhältnis zu Schild und anderen Schutzwirkungen (KS-27), Öffentlichkeit über die Wahl hinaus.
- `wende_05`: genauer Vollstreckungszeitpunkt am übernächsten Tag, wer das Verschieben entscheidet und wann (gestellt als KS-64), welche Todesarten und Personen zählen, Schutz und Schild bei der Vollstreckung, Tod der Person während des Aufschubs auf anderem Weg, mehrere gleichzeitige Tode, Verfall der Karte, Wechselwirkung mit konkreten Siegbedingungen und mit Todesreaktionen, die die Siegprüfung ändern (gestellt als KS-63).
- `wende_11`: Wolfsvariante: Wahl des Wolfs, gewählter Wolf ist schon König Lykaon oder hat die Fähigkeit verbraucht, kein verbündeter Wolf lebt, Verhältnis zu den Rollenregeln V-03, V-08, V-09 innerhalb der einen Gelegenheit, ob die Gelegenheit abgelehnt werden darf. **Dorfvariante: nicht entschieden** (Zufallsumleitung, Öffentlichkeit, welche Wölfe zählen; KS-59).
- `loki_10`: Ausnahme und Reihenfolge sind bestätigt; offen bleiben ohne andere Tote, früherer Tod und erneute Wiederbelebung in der Frist, Rückkehrrolle, Sichtbarkeit von Würfeln und Namen, Verhältnis zur Siegprüfung (KS-46 bis KS-48).
- `wende_02`, `wende_05`, `wende_11` und `loki_10` sind damit **nicht vollständig spezifiziert** und nicht implementiert.

## Gebrochener Schild, Kettenfluch, Doppeltes Leid, Notanker (achte Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (achte Runde) auf die fünf Fragen in Abschnitt 18 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md`. Zuordnung: 1A zu KS-60 (`fluch_05`), 2B zu KS-61 (`fluch_08`), 3A zu KS-62 (`fluch_12`), 4B zu KS-63 (`wende_05`, vorgezogene Reaktionen), 5C zu KS-64 (`wende_05`, Auslösung). Die Buchstaben verweisen auf die Optionen in Abschnitt 18; wo die Antwort Zusatzbestimmungen enthält, gelten diese und gehen der Optionsformulierung vor. Die Antworten gelten ausdrücklich nur für diese Karten und werden nicht auf andere Karten, Schutzwirkungen, Todesreaktionen oder die allgemeine Nachbarregel übertragen. Es ist nichts implementiert: kein Karten-Code, kein Schutz, keine Pause von Schutzwirkungen, kein Mittod, kein zusätzlicher Tod, kein aufgeschobener Tod, keine Verwandlung, kein Erbe, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`fluch_05` Gebrochener Schild (KS-60, 1A):** Betroffene Schutzwirkungen pausieren während der festgelegten Dauer. Danach wirken sie wieder, sofern ihre ursprüngliche Laufzeit noch nicht abgelaufen ist. Die Pause verlängert die ursprüngliche Laufzeit nicht. Ein unverbrauchter Schild bleibt erhalten und wird während der Pause nicht als wirksamer Schutz behandelt. Es gibt keine Ausnahme für gekaufte Kartenschlucker-Schilde.
- **`fluch_08` Kettenfluch (KS-61, 2B):** In der angegebenen Richtung wird die nächste lebende Person der geforderten Fraktion gesucht; tote Personen und Personen anderer Fraktionen werden übersprungen. Wolfsvariante: nach rechts zur nächsten lebenden Wolfsperson. Dorfvariante: nach links zur nächsten lebenden Dorfperson. Keine Beschränkung auf den unmittelbaren lebenden Nachbarn. Daraus folgt keine Änderung der allgemeinen Nachbarregel (RM-DR-003) für andere Fähigkeiten.
- **`fluch_12` Doppeltes Leid (KS-62, 3A):** Der zusätzliche Tod kann durch eine für diese Todesart passende Schutzwirkung verhindert werden. Ein persönlicher Schild kann ihn abfangen und wird dabei verbraucht. Nach einer erfolgreichen Abwehr wird keine andere Person als Ersatz gezogen. Nicht jede Schutzart schützt automatisch gegen diesen Tod; reiner Rudelangriffsschutz wird nicht pauschal ausgeweitet.
- **`wende_05` Notanker, vorgezogene Reaktionen (KS-63, 4B):** Die Wolfskind-Verwandlung erfolgt bereits beim Aufschub des Todes des Vorbilds. Vergleichbare Erbfolgen wie beim Lehrling erfolgen ebenfalls bereits beim Aufschub. Dadurch entstehende Rollenänderungen werden vor der anschließenden Siegprüfung berücksichtigt. Die aufgeschobene Person darf weiterhin handeln und abstimmen, zählt für Siegbedingungen aber bereits als tot. Das ist keine Freigabe, sämtliche Todesreaktionen vorzuverlegen: Totenkarte, Wiederbelebungsmöglichkeit, öffentliche Todesmeldung und andere Todeseffekte werden nicht automatisch vorgezogen. Die Abgrenzung anderer Reaktionsarten und die Vermeidung einer doppelten Auslösung beim späteren tatsächlichen Tod sind notwendige Spezifikationspunkte (KS-79). Die bestehende Lehrling-Auswahl und die Wolfskind-Regeln bleiben außerhalb dieses Kartenfalls unverändert.
- **`wende_05` Notanker, Auslösung (KS-64, 5C):** Nach dem Ausspielen der Karte wird der nächste passende Tod der betreffenden Fraktion automatisch aufgeschoben. Es gibt keine erneute Entscheidung durch Kartenbesitzer oder Fraktion im Todesmoment. Die Entscheidung zur Nutzung fällt beim Ausspielen der Karte. Der genaue spätere Vollstreckungszeitpunkt bleibt offen, soweit er nicht bereits verbindlich entschieden ist (bisher bestätigt: übernächster Tag, siebte Runde).

**Ersetzt (nicht mehr gültig):**

- KS-60: Empfehlung A ist bestätigt und um die Punkte zu Laufzeit, unverbrauchtem Schild und fehlender Ausnahme ergänzt. Option B (Schutz erlischt) und Option C (gekaufter Schild ausgenommen) sind ausdrücklich nicht gewählt.
- KS-61: Empfehlung A (nur der direkte Nachbar, nur bei passender Fraktion) ist ersetzt durch Option B. A und C nicht gewählt.
- KS-62: Empfehlung A ist im Kern bestätigt, aber enger gefasst: Nicht „Schutz und Schild wie bei jedem anderen Tod“, sondern nur eine für diese Todesart passende Schutzwirkung; der Schild ist bestätigt. B (ignoriert jeden Schutz) und C (Ziehung nur unter Ungeschützten) nicht gewählt. Die in Abschnitt 18 genannte Voraussetzung, dass Karteneffekte unter „Rollenfähigkeit“ des Schilds fallen, gilt damit nur für diese Karte; KS-27 bleibt allgemein offen.
- KS-63: Empfehlung A (Zählstatus sofort, keine Vorwegnahme) ist ersetzt durch Option B in eingeschränkter Form. Nicht übernommen: die allgemeine Fassung „Todesreaktionen, die den Zählstatus anderer Personen ändern, laufen beim Aufschub ab“ (bestätigt sind nur Wolfskind-Verwandlung und Lehrling-ähnliche Erbfolgen) und der Halbsatz „Nur ihr Handeln bleibt zurückgestellt“ (die Person darf handeln). A und C nicht gewählt.
- KS-64: Empfehlung A (die Kartenspielerin entscheidet im Todesmoment) ist ersetzt durch Option C, ergänzt um die Klarstellung, dass die Nutzungsentscheidung beim Ausspielen fällt. A und B nicht gewählt.
- Arbeitsliste Abschnitt 18, „Reihenfolge der nächsten Runden“: überholt durch Abschnitt 20.

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- `fluch_12`: Die Zufallsauswahl des zweiten Opfers läuft über den gespeicherten Generator (ÜB-4). Das ist nicht ausdrücklich gesagt.
- `fluch_08`: Ob „rechts“ und „links“ im Sitzkreis dieselbe Blickrichtung wie bei RM-DR-146.1 (links = nächster Platz im Uhrzeigersinn des App-Sitzkreises) meinen, ist nicht gesagt und nicht übernommen.
- `wende_05`: „Der nächste passende Tod der betreffenden Fraktion“ könnte auch einen Tod meinen, den die Fraktion nicht als Rudelopfer oder Hinrichtung erleidet. Was „passend“ ist, ist nicht entschieden (KS-69).

**Tatsächlicher Konflikt: vorgezogene Erbfolge beim Notanker (nicht gelöst).** Geprüft wurden nur Wolfskind und Lehrling-Erbe gegen die Antworten 4B und 5C, keine Gesamtprüfung aller Rollen. Beim Wolfskind entsteht kein Konflikt dieser Art: Es behält seine Rolle und wechselt nur die Fraktion. Beim Lehrling entstehen drei belegte Konflikte mit bestehenden Regeln (Abschnitt „Lehrling · Produktionsrolle, verdeckte Auswahl und Erbe“, Korrekturrunde dazu, DR-14):

1. Die Erbregel behandelt den Tod des Meisters: Der Lehrling erbt dessen aktuelle Rolle, Fraktion, passive Eigenschaften, Siegbedingungen und Todesreaktionen sofort, alle begrenzten Einsätze beginnen frisch. Sie setzt stillschweigend voraus, dass der Meister danach nicht mehr handelt. Beim Aufschub handelt der Meister weiter. Bis zum tatsächlichen Tod gibt es damit zwei lebende Personen mit derselben Rolle, den Lehrling mit frischen Einsätzen und den Meister mit seinem Stand. Eine Regel für zwei lebende Träger derselben Rolle nach einem Erbe gibt es nicht; die bestätigte Doppelrolle der vierten Runde gilt nur für `segen_08`, `wende_04` und `wende_07`. Gestellt als KS-74.
2. Die Erbregel legt die Reihenfolge fest: nach Wolfskind-Verwandlungen, vor der Todesreaktion des Meisters, vor der vorläufigen Siegprüfung. Todesreaktionen werden nach 4B nicht vorgezogen; die Reaktion des Meisters läuft erst beim tatsächlichen Tod, die geerbte Todesreaktion gilt beim Lehrling dagegen sofort. Die Reihenfolge lässt sich beim Aufschub nicht wörtlich anwenden. Notiert als KS-79.
3. Geregelt ist, dass eine Wiederbelebung des Meisters nach einem Erbe kein zweites Erbe auslöst. Für den späteren tatsächlichen Tod nach einem vorgezogenen Erbe (und für die vorgezogene Wolfskind-Verwandlung) fehlt die entsprechende Regel; ohne sie träfe „Stirbt der Meister mit Todesfolgen“ bei der Vollstreckung erneut zu. Notiert als KS-79, ebenso der Fall, dass die Vollstreckung nicht stattfindet, obwohl Erbe oder Verwandlung schon geschehen sind (bisher nur per Spielleiterkorrektur zurücknehmbar).

**Weiter offen (nicht entschieden, nicht erfunden):**

- `fluch_05`: Dauerzählung der „Tage“ (gestellt als KS-75); Wahl der Dauer (wer, wann, öffentlich oder privat); welche Wirkungen „Schutz“ sind; ob während der Pause neu erworbener Schutz wirkt; ob zeitlich begrenzte Schutzwirkungen in der Pause weiterlaufen (bestätigt ist nur: die Pause verlängert die Laufzeit nicht); Fraktionsbezug bei Wechselrollen (KS-65).
- `fluch_08`: Blickrichtung im Sitzkreis; Selbstbezug bei wenigen Lebenden; Umfang von „Sonderfähigkeit“ (Wolf) und „durch die Wölfe“ (Dorf); Ketten; Schutz und Schild des Mittoten; gleichzeitige Tode; Ansage (KS-66).
- `fluch_12`: welche Schutzwirkungen „für diese Todesart passend“ sind; Pool der Zufallsauswahl; kein weiterer Kandidat; Auslöser und gleichzeitige Tode; Todeskarte des Mitgerissenen; Ansage (KS-67).
- `wende_05`: Vollstreckungszeitpunkt am übernächsten Tag; welche Todesarten und Personen „passend“ sind; Schutz und Schild bei der Vollstreckung; Tod auf anderem Weg im Aufschub; mehrere gleichzeitige Tode; Verfall der Karte; Abgrenzung der vorgezogenen Reaktionen und doppelte Auslösung (KS-69, KS-79); Konflikt Lehrling-Erbe (KS-74).
- `fluch_05`, `fluch_08`, `fluch_12` und `wende_05` sind damit **nicht vollständig spezifiziert** und nicht implementiert.

## Kosmisches Gleichgewicht, Wachsame Augen, Stille Nacht, Notanker, Gebrochener Schild (neunte Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (neunte Runde) auf die fünf Fragen in Abschnitt 20 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md`. Zuordnung: 1A zu KS-71 (`loki_12`), 2B zu KS-72 (`segen_03`, Dorfvariante), 3B zu KS-73 (`segen_04`, Dorfvariante), 4A zu KS-74 (`wende_05`, Lehrling-Erbe bei handelnder Person), 5C zu KS-75 (`fluch_05`, Dauerzählung). Die Buchstaben verweisen auf die Optionen in Abschnitt 20; wo die Antwort Zusatzbestimmungen enthält, gelten diese und gehen der Optionsformulierung vor. Die Antworten gelten ausdrücklich nur für diese Karten und Fraktionsvarianten und werden nicht auf andere Karten, Schutzwirkungen, Todesreaktionen oder die allgemeine Nachbarregel übertragen; Verweise anderer Karten auf diese Regeln (etwa `fluch_07` Dorf, `wende_06` Wolf und `solo_07` auf `segen_04` Dorf) bleiben ohne eigene Entscheidung. Es ist nichts implementiert: kein Karten-Code, kein zusätzlicher Tod, keine Neuabstimmung, keine Wolfssperre, keine Schutzpause, kein Erbe, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`loki_12` Kosmisches Gleichgewicht (KS-71, 1A):** Jeder sonstige passende Tod während der Wirkungsdauer löst einen zusätzlichen Tod in der jeweils anderen Fraktion aus (Wolf löst eine Dorfperson aus, Dorfperson löst einen Wolf aus). Die Karte wirkt nicht nur einmal beim ersten Tod. Ein durch diese Karte selbst verursachter zusätzlicher Tod löst dieselbe Kartenwirkung nicht erneut aus. Die Spielleitung bestimmt die Zusatzopfer entsprechend dem vorhandenen Kartentext. Normale Reaktionen auf einen solchen Tod werden nicht pauschal ausgeschaltet.
- **`segen_03` Wachsame Augen, Dorfvariante (KS-72, 2B):** Nach der vorgesehenen Enthüllung entscheidet das Dorf, ob die Hinrichtung vollzogen wird. Lehnt es ab, findet eine neue Abstimmung statt. Es gibt kein automatisches Ersatzopfer anhand der zweithöchsten Stimmenzahl. Die Stimmen werden weiterhin am Tisch gezählt. Die Wolfsvariante wurde nicht weiter entschieden.
- **`segen_04` Stille Nacht, Dorfvariante (KS-73, 3B):** In der betroffenen Nacht finden keine Tötungen durch Wölfe statt. Das betrifft den gemeinsamen Rudelangriff und zusätzliche aktive Wolfstötungen. Andere Wolfsfähigkeiten bleiben erlaubt; alle Wolfsrollen werden nicht pauschal übersprungen. Die Wolfsvariante der Karte bleibt unberührt.
- **`wende_05` Notanker, Lehrling-Erbe (KS-74, 4A):** Der Lehrling erbt sofort vollständig, obwohl der Meister wegen des aufgeschobenen Todes noch handelt. Beide dürfen bis zum tatsächlichen Tod des Meisters dieselbe Rolle nutzen (Beispiel: Meister und Lehrling handeln gleichzeitig als Waldhexen). Beim späteren tatsächlichen Tod wird das bereits vollzogene Erbe nicht ein zweites Mal ausgelöst. Die sonstigen bestätigten Erbregeln bleiben erhalten. Es gibt keine Sperre der Fähigkeiten des Meisters und kein Aufteilen in vorgezogenen Fraktionswechsel und späteres Erbe.
- **`fluch_05` Gebrochener Schild, Dauer (KS-75, 5C):** Der Tag des Ausspielens zählt als erster Tag der Schutzpause. Die Pause endet am Ende des entsprechend gezählten Tages (Beispiel: Ausspielen an Tag 4, Dauer zwei Tage, Ende der Pause am Ende von Tag 5). Die ursprüngliche Laufzeit der pausierten Schutzwirkung läuft weiter und wird nicht verlängert. Die bestätigte Phoenix-Ausnahme bei spätem Ausspielen wird nicht automatisch auf diese Karte übertragen.

**Ersetzt (nicht mehr gültig):**

- KS-71: Option A ist bestätigt und um die Punkte zu „nicht nur beim ersten Tod“, Wahl der Zusatzopfer nach dem Kartentext und nicht pauschal abgeschalteten Reaktionen ergänzt. Option B (volle Kette) und Option C (nur der erste Tod) sind ausdrücklich nicht gewählt.
- KS-72: Empfehlung A (Hinrichtung entfällt ohne Ersatz und ohne Neuabstimmung) ist ersetzt durch Option B (Neuabstimmung). A und C nicht gewählt.
- KS-73: Empfehlung A (alle Wölfe schlafen, alle Nachtfähigkeiten der Wolfsrollen entfallen) ist ersetzt durch Option B (keine Wolfstötung, andere Wolfsfähigkeiten bleiben). A und C nicht gewählt.
- KS-74: Empfehlung A ist bestätigt. B (geteiltes Erbe) und C (Fähigkeiten des Meisters ruhen) sind ausdrücklich nicht gewählt.
- KS-75: Empfehlung A (Ende nach der n-ten folgenden Hinrichtung) ist ersetzt durch Option C (Tag des Ausspielens zählt als erster Tag). A und B nicht gewählt. Die im Optionstext C genannten Folgerungen („die Pause endet nach der Hinrichtung von Tag 5“, „bei einem Tag im zweiten Fenster bliebe die Pause ohne Wirkung“) sind nicht bestätigt; bestätigt ist nur „Ende am Ende des gezählten Tages“.
- Arbeitsliste Abschnitt 20, „Reihenfolge der nächsten Runden“: überholt durch Abschnitt 22.

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- `loki_12`: „Wirkungsdauer“ folgt dem Kartentext „heute“; was „heute“ genau umfasst (Tag, Nacht, Fenster), ist nicht entschieden (KS-76). Die Antwort verweist für die Wahl der Zusatzopfer auf den Kartentext („nach Rollenstärke“) und legt weder Zufall über den gespeicherten Generator noch eine feste Rangliste fest.
- `segen_03`: „vorgesehene Enthüllung“ wird als Enthüllung der zur Hinrichtung vorgesehenen Person gelesen; was genau gezeigt wird (Rolle) und ob es öffentlich bleibt, ist nicht entschieden (KS-77).
- `wende_05`: Frische Einsätze der geerbten Rolle und der Zeitpunkt ihrer ersten Nutzung folgen den bestätigten Erbregeln und dem Nachtplan-Snapshot; die Antwort entscheidet beides nicht neu.
- `fluch_05`: Die Zählung knüpft sprachlich an Phoenix an („Tag des Ausspielens zählt“); die Phoenix-Ausnahme ist ausdrücklich nicht übertragen.

**Tatsächlicher Konflikt: Stand nach der neunten Runde.** Der im Eintrag der achten Runde belegte Konflikt „zwei lebende Träger derselben Rolle“ (Punkt 1, KS-74) ist gelöst: Beide nutzen dieselbe Rolle bis zum tatsächlichen Tod des Meisters, das vollzogene Erbe löst nicht erneut aus. Von Punkt 3 (doppelte Auslösung) ist nur das Lehrling-Erbe beantwortet. Offen bleiben die vorgezogene Wolfskind-Verwandlung, die Reihenfolge „Erbe vor Todesreaktion des Meisters“ (Punkt 2) und eine Vollstreckung, die nicht stattfindet, obwohl Erbe oder Verwandlung geschehen sind (KS-79). Es wurde keine Gesamtprüfung aller Rollen durchgeführt.

**Weiter offen (nicht entschieden, nicht erfunden):**

- `loki_12`: Folgetode aus anderen Todesreaktionen (gestellt als KS-84); Wirkungsdauer „heute“; Bewertung „Rollenstärke“; Einzelsiegrollen und Neutrale; kein passendes Opfer; gleichzeitige Tode; Schutz und Schild des Mitgerissenen; Todeskarte; Siegprüfung; Ansage (KS-76).
- `segen_03`: Ob die Karte bei der neuen Abstimmung erneut enthüllt (gestellt als KS-83); ob die zuvor verschonte Person erneut nominiert werden darf; Deutung „Opfer“; Öffentlichkeit der gezeigten Rolle nach einem Nein; Regeln der Tischabstimmung; Wolfsvariante (echte oder Scheinrolle, Zahl der Zielwechsel, Bezug „heute Nacht“, Ansage) (KS-77).
- `segen_04`: Verzögerte Wirkungen, passive Todesreaktionen und Fraktionswechsel bei bereits vorgemerkten Angriffen; Definition von „Tötung durch Wölfe“; Öffentlichkeit einer Nacht ohne Wolfsopfer; Bezug „heute Nacht“; Wolfsvariante (KS-78).
- `wende_05`: Doppelte Auslösung bei der Wolfskind-Verwandlung; welche Erbfolgen „vergleichbar“ sind; Reihenfolge; nicht stattfindende Vollstreckung; Vollstreckungszeitpunkt; passende Todesarten und Personen; Schutz und Schild bei der Vollstreckung; Tod auf anderem Weg; gleichzeitige Tode; Verfall (KS-79, KS-69).
- `fluch_05`: Genauer Ablaufzeitpunkt am Tagesende gegenüber Hinrichtung, Todeseffekten, Fristablauf der Rückkehrer und zweitem Kartenfenster sowie die Wirkung einer Dauer von einem Tag im zweiten Fenster (KS-88); Wahl der Dauer; was „Schutz“ ist; neu erworbener Schutz in der Pause; weiterlaufende Fristen; Fraktionsbezug bei Wechselrollen (KS-65).
- `loki_12`, `segen_03`, `segen_04`, `wende_05` und `fluch_05` sind damit **nicht vollständig spezifiziert** und nicht implementiert.

**Vorbereitet (keine Entscheidung):** Arbeitsliste Abschnitte 21 und 22 mit den nächsten Karten der Gruppe 3 `segen_09`, `segen_13`, `fluch_02` (Fragen KS-80 bis KS-82), zwei Klärungen (KS-83 erneute Enthüllung bei `segen_03`, KS-84 Folgetode bei `loki_12`) und Folgepunkten KS-85 bis KS-88. Die drei neuen Karten sind nicht spezifiziert und nicht entschieden.

## Gerechter Zorn, Schattenvorteil, Falsche Fährte, Wachsame Augen, Kosmisches Gleichgewicht (zehnte Antwortrunde, 30.09.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 30.09.2026 (zehnte Runde) auf die fünf Fragen in Abschnitt 22 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md`. Zuordnung: 1A zu KS-80 (`segen_09`, Dorfvariante), 2B zu KS-81 (`segen_13`, Wolfsvariante), 3A zu KS-82 (`fluch_02`, Dorfvariante), 4A zu KS-83 (`segen_03`, Neuabstimmung), 5A zu KS-84 (`loki_12`, Folgetode). Die Buchstaben verweisen auf die Optionen in Abschnitt 22; wo die Antwort Zusatzbestimmungen enthält, gelten diese und gehen der Optionsformulierung vor. Die Antworten gelten ausdrücklich nur für diese Karten und Fraktionsvarianten und werden nicht auf andere Karten, Schutzwirkungen, Todesreaktionen oder die allgemeine Nachbarregel übertragen. Es ist nichts implementiert: kein Karten-Code, keine verhinderte Hinrichtung durch Karte, keine Scheitern-Regel für Nachtfähigkeiten, keine Falschauskunft, keine Neuabstimmung, kein zusätzlicher Tod, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`segen_09` Gerechter Zorn, Dorfvariante (KS-80, 1A):** Die Hinrichtung der betroffenen Dorfperson wird verhindert. Dadurch entsteht kein Todesereignis und keine darauf beruhende Todesreaktion. Es gibt keine neue Abstimmung und kein Ersatzopfer durch diese Karte. Der übrige Tagesablauf bleibt erhalten, einschließlich fälliger Fristen und des zweiten Kartenfensters. Andere, unabhängig eintretende Todesfälle werden dadurch nicht verhindert. Die Wolfsvariante wurde nicht weiter entschieden.
- **`segen_13` Schattenvorteil, Wolfsvariante (KS-81, 2B):** Die erste schädliche oder aufdeckende Nachtfähigkeit, die einen Wolf trifft, scheitert. Dazu gehören beispielsweise Tötung, Rollenprüfung und Sperre. Schutz und Hilfe werden dadurch nicht verhindert. Daraus folgt keine getrennte einmalige Abwehr je Wolf. Die Dorfvariante wurde nicht weiter entschieden.
- **`fluch_02` Falsche Fährte, Dorfvariante (KS-82, 3A):** Die Wirkung verfälscht eine reguläre Rollenauskunft. Die Spielleitung bestimmt die falsche Auskunft. Der tatsächliche Spielzustand und die angezeigte Information bleiben getrennt. Gibt es für die ausgewählte Person keine entsprechende Auskunft, entsteht keine Wirkung. Es gibt keinen mündlichen Ersatz und keine zusätzliche frei erfundene Nachricht. Die Wolfsvariante wurde nicht weiter entschieden.
- **`segen_03` Wachsame Augen, Neuabstimmung (KS-83, 4A):** Die Karte enthüllt und ermöglicht die Ablehnung nur beim ersten Wahlgang. Nach einer Ablehnung folgt die bereits bestätigte Neuabstimmung. Bei dieser gibt es durch die Karte keine erneute Enthüllung und kein weiteres Ablehnungsrecht. Die neue Hinrichtung unterliegt weiterhin den sonstigen Regeln und Schutzwirkungen. Ob die zuvor verschonte Person erneut nominiert werden darf, ist nicht entschieden.
- **`loki_12` Kosmisches Gleichgewicht, Folgetode (KS-84, 5A):** Ein direkt durch diese Karte verursachter zusätzlicher Tod löst die Karte nicht erneut aus. Auch indirekte Todesfolgen dieses zusätzlichen Todes lösen sie nicht erneut aus (Beispiel: Die Karte tötet Ben zusätzlich, Finn stirbt deshalb an Liebeskummer; weder Bens noch Finns Tod löst Kosmisches Gleichgewicht erneut aus). Die normalen Todesreaktionen selbst bleiben aktiv. Todesreaktionen aus unabhängig entstandenen Todesfällen sind nicht pauschal ausgeschlossen. Es wird keine allgemeine Sperre aller Todesketten eingeführt.

**Ersetzt (nicht mehr gültig):**

- KS-80, KS-82, KS-83, KS-84: Empfehlung A ist jeweils bestätigt; die übrigen Optionen sind nicht gewählt. Bei KS-82 gilt Option A ausdrücklich ohne mündlichen Ersatz.
- KS-81: Empfehlung A (jede Nachtfähigkeit, die eine Wolfsperson als Ziel hat) ist ersetzt durch Option B (nur schädliche oder aufdeckende Fähigkeiten). A und C nicht gewählt.
- Arbeitsliste Abschnitt 22, „Reihenfolge der nächsten Runden“: überholt durch Abschnitt 24.

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- `segen_09`: Dass die Karte nach der nächsten Hinrichtung verbraucht ist, folgt aus dem Bezug „nächste“ (KS-56) und der Optionsformulierung; ob sie bei nicht erfüllter Bedingung ebenfalls verfällt, ist nicht entschieden (KS-85).
- `segen_13`: Dass „die erste“ Fähigkeit der Nachtplan-Reihenfolge folgt, ist nicht bestätigt (KS-86). Die Antwort regelt weder gemischte Fähigkeiten noch mehrere Ziele noch die Behandlung einer gescheiterten Auskunft.
- `loki_12`: Wie der Ursprung eines Folgetods im Todesereignis nachverfolgt wird, ist eine technische Frage und nicht entschieden. Schutz und Schild des Mitgerissenen bleiben offen (gestellt als KS-93).

**Weiter offen (nicht entschieden, nicht erfunden):**

- `segen_09`: Wolfsvariante; Fraktionsbezug; Öffentlichkeit der Befreiung (verrät die Fraktion); Verfall bei nicht erfüllter Bedingung; Tag ohne Hinrichtung (KS-85).
- `segen_13`: Dorfvariante; gemischte Fähigkeiten; mehrere Ziele; gescheiterte Auskunft; ob der Einsatz verbraucht wird (KS-86).
- `fluch_02`: Wolfsvariante (Umlenkung); Bezug „heute Nacht“; Protokoll; Öffentlichkeit; Rollen mit mehreren Ergebnissen (KS-87).
- `segen_03`: Wolfsvariante; erneute Nominierung der verschonten Person; Ablauf bei Schutz der neuen Hinrichtung (gestellt als KS-92); Rest von KS-77.
- `loki_12`: Schutz und Schild des Mitgerissenen (KS-93); Wirkungsdauer; Bewertung „Rollenstärke“; Einzelsiegrollen; kein passendes Opfer; gleichzeitige Tode; Todeskarte; Siegprüfung; Ansage (KS-76).
- `segen_09`, `segen_13`, `fluch_02`, `segen_03` und `loki_12` sind damit **nicht vollständig spezifiziert** und nicht implementiert.

**Vorbereitet (keine Entscheidung):** Arbeitsliste Abschnitte 23 und 24 mit den nächsten Karten der Gruppe 3 `fluch_04`, `fluch_07`, `fluch_10` (Fragen KS-89 bis KS-91), zwei gemeinsamen Klärungen zu Schutz und Schild (KS-92 zu Teilen von KS-21, KS-93 zu Teilen von KS-27) und Folgepunkten KS-94 bis KS-97. Die drei neuen Karten sind nicht spezifiziert und nicht entschieden.

## Verrat, Alptraum, Schlechtes Omen, verhinderte Hinrichtung, Schild gegen Kartentode (elfte Antwortrunde, 01.10.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 01.10.2026 (elfte Runde) auf die fünf Fragen in Abschnitt 24 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md`. Zuordnung: 1A zu KS-89 (`fluch_04` Verrat, Wolfsvariante), 2B zu KS-90 (`fluch_07` Alptraum, Wolfsvariante), 3A zu KS-91 (`fluch_10` Schlechtes Omen, Wolfsvariante), 4A zu KS-92 (allgemein: durch Schild verhinderte Hinrichtung), 5A zu KS-93 (allgemein: persönlicher Schild gegen Kartentode). Die Buchstaben verweisen auf die Optionen in Abschnitt 24; wo die Antwort Zusatzbestimmungen enthält, gelten diese und gehen der Optionsformulierung vor. Die Antworten zu KS-89 bis KS-91 gelten ausdrücklich nur für die genannten Karten und Wolfsvarianten. KS-92 und KS-93 sind allgemeine Regeln für den persönlichen Schild und werden nicht auf andere Schutzwirkungen übertragen. Es ist nichts implementiert: kein Karten-Code, keine Schildänderung, keine Todespipeline-Änderung, keine Rudelzwang-Regel, keine Bewertung der Spielleitung, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema, Regelkern-Tests oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`fluch_04` Verrat, Wolfsvariante (KS-89, 1A):** Das Rudel muss als Ziel seines Angriffs eine eigene Wolfsperson wählen. Dorfpersonen sind dadurch nur vor diesem Rudelangriff verschont. Es gibt keinen allgemeinen Schutz für Dorfpersonen: Gift, andere Fähigkeiten und sonstige Todesursachen wirken weiterhin nach ihren normalen Regeln. Die Dorfvariante wurde durch diese Antwort nicht weiter entschieden.
- **`fluch_07` Alptraum, Wolfsvariante (KS-90, 2B):** Die gemeinsamen Rudelangriffe entfallen, einschließlich zusätzlicher gemeinsamer Rudelopfer. Eigene Tötungsfähigkeiten einzelner Wölfe bleiben erlaubt, andere Wolfsfähigkeiten ebenfalls. Das ist nicht dieselbe Wirkung wie bei der bestätigten Dorfvariante von `segen_04` Stille Nacht (KS-73), bei der auch zusätzliche aktive Wolfstötungen entfallen. Die Reichweiten sind bewusst verschieden und werden in den überarbeiteten Kartentexten so festgehalten (Arbeitsliste Abschnitt 25, Gegenüberstellung). Die Dorfvariante von Alptraum wurde nicht weiter entschieden.
- **`fluch_10` Schlechtes Omen, Wolfsvariante (KS-91, 3A):** Die Spielleitung beurteilt nach Ermessen, ob das Rudel eine starke Rolle erwischt hat. Ist die Bedingung „keine starke Rolle erwischt“ erfüllt, entscheidet sie, ob ein zusätzlicher Wolf stirbt. Es gibt keine feste Stärkeliste und keine zufällige Beurteilung. „Keine starke Rolle erwischt“ wird nicht durch „niemanden getötet“ ersetzt. Die Dorfvariante wurde nicht weiter entschieden.
- **Allgemein: durch Schild verhinderte Hinrichtung (KS-92, 4A):** Der persönliche Schild wird verbraucht, die betroffene Person überlebt. Es gibt kein Ersatzopfer und keine neue Abstimmung allein wegen des Schilds. Der übrige Tagesablauf einschließlich Kartenfenster und fälliger Fristen bleibt erhalten. Es entsteht kein tatsächlicher Tod und keine dadurch ausgelöste Todesreaktion. Sonderkarten, die ausdrücklich weitere Hinrichtungen verlangen, werden durch diese allgemeine Regel nicht ungeprüft überschrieben; die Bedeutung von „getroffen“ beziehungsweise „hingerichtet“ bei solchen Karten bleibt bei Bedarf gesondert zu entscheiden.
- **Allgemein: persönlicher Schild gegen Kartentode (KS-93, 5A):** Persönliche Schilde können auch durch Karten verursachte Tode verhindern, unabhängig davon, ob das Opfer zufällig, von der Spielleitung oder auf andere regelkonforme Weise bestimmt wurde (Beispiele: Zusatzopfer von Kosmisches Gleichgewicht, Kettenfluch und Schlechtes Omen). Der Schild wird verbraucht, die Person überlebt, es gibt kein Ersatzopfer. Die bereits bestätigte Regel für Doppeltes Leid bleibt bestehen. Die Antwort betrifft persönliche Schilde; reiner Rudelangriffsschutz und andere eingeschränkte Schutzwirkungen werden nicht pauschal ausgeweitet. Die bestehende Ausnahme für direkte Spielleiterkorrekturen bleibt erhalten.

**Ersetzt (nicht mehr gültig):**

- KS-90: Empfehlung A (dieselbe Wirkung wie `segen_04` Dorf, auch zusätzliche aktive Wolfstötungen entfallen) ist ersetzt durch Option B (nur gemeinsame Rudelangriffe entfallen, eigene Tötungsfähigkeiten bleiben). A und C nicht gewählt.
- KS-89, KS-91, KS-92, KS-93: Empfehlung A ist jeweils bestätigt; die übrigen Optionen sind nicht gewählt. Bei KS-91 gilt die Bedingung „keine starke Rolle erwischt“ ausdrücklich nicht als „niemanden getötet“ (Option C nicht gewählt). Bei KS-93 gilt Option A beschränkt auf persönliche Schilde; Option C (Schild nur gegen Rollenfähigkeit und Hinrichtung) ist nicht gewählt, die in KS-06 festgehaltene Reichweite ist für persönliche Schilde um Kartentode ergänzt.
- Arbeitsliste Abschnitt 24, „Reihenfolge der nächsten Runden“: überholt durch Abschnitt 26.

**Stand der Schildliste:** Entschieden sind jetzt der Ablauf nach durch Schild verhinderter Hinrichtung (KS-92, Teil von KS-21) und die Reichweite des persönlichen Schilds gegen Kartentode (KS-93, Teil von KS-27). Diese beiden Punkte gelten nicht mehr als vollständig offen. Getrennt davon bleiben offen: die Reihenfolge mehrerer Schutzwirkungen (Nekromant, Hades, Parasit, Rudelvater), Schild gegen Rudelangriff und zweiten Rudelschritt, Todesketten und „höchstens ein Schild“ je Person insgesamt (KS-97).

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- `fluch_04`: Dass „Rudelopfer“ die gemeinsame Rudelwahl meint und Zusatzopfer einzelner Wolfsrollen nicht einschließt, ist nicht entschieden (KS-94, RM-DR-004).
- `fluch_07`: Die Abgrenzung „gemeinsames Rudelopfer“ gegenüber „eigener Tötungsfähigkeit“ bei Zusatzopfern von Rudelvater und Schicksalswolf ist nicht entschieden (KS-95).
- KS-92: Dass die allgemeine Regel für andere Schutzwirkungen als den persönlichen Schild gilt, ist nicht bestätigt; `wende_02` und `segen_09` Dorf haben ihre eigenen bestätigten Regeln.

**Weiter offen (nicht entschieden, nicht erfunden):**

- `fluch_04`: Rudel mit nur einer Wolfsperson; Schutz auf dem gewählten Wolf; Verhältnis zu Zusatzopfern; Ansage; Bezug „heute Nacht“; Dorfvariante (ob eine durch Schild verhinderte Hinrichtung als „getroffen“ zählt, gestellt als KS-101; Nominierungen in Wiederholungen; Ende der Schleife; Fraktionsbezug) (KS-94).
- `fluch_07`: Abgrenzung gemeinsames Rudelopfer und eigene Tötungsfähigkeit; Bezug „heute Nacht“; Öffentlichkeit; Nachtzähler des Kartenschluckers; Dorfvariante (KS-95).
- `fluch_10`: Wer gegebenenfalls den sterbenden Wolf bestimmt; was als „erwischt“ zählt; Zeitpunkt der Bewertung; Schild des Wolfs; Ansage; Dorfvariante (Bedingung „kein Werwolf gelyncht“ bei einem Wolf, der überlebt, gestellt als KS-102; Zufall; Pool; „noch am selben Tag“) (KS-96).
- Schild: Reihenfolge mehrerer Schutzwirkungen, Rudelangriff und zweiter Rudelschritt, Todesketten, „ein Schild“ je Person (KS-97).
- `fluch_04`, `fluch_07` und `fluch_10` sind damit **nicht vollständig spezifiziert** und nicht implementiert.

**Vorbereitet (keine Entscheidung):** Arbeitsliste Abschnitte 25 und 26 mit den nächsten Karten der Gruppe 3 `wende_03`, `wende_06`, `schicksal_06` (Fragen KS-98 bis KS-100), zwei Klärungen zu bisherigen Karten (KS-101 `fluch_04` Dorf, „getroffen“ bei verhinderter Hinrichtung; KS-102 `fluch_10` Dorf, Wolf bestimmt, aber nicht hingerichtet) und Folgepunkten KS-103 bis KS-105. Die drei neuen Karten sind nicht spezifiziert und nicht entschieden.

## Wendepunkt, Trotz, Zeitsprung, Verrat, Schlechtes Omen (zwölfte Antwortrunde, 01.10.2026)

**Herkunft:** Antworten des Product Owners im Claude-Code-Auftrag vom 01.10.2026 (zwölfte Runde) auf die fünf Fragen in Abschnitt 26 der Arbeitsliste `docs/role-migration/14-totenkarten-arbeitsliste.md`. Zuordnung: 1A zu KS-98 (`wende_03` Wendepunkt, Wolfsvariante), 2A zu KS-99 (`wende_06` Trotz, Wolfsvariante), 3A zu KS-100 (`schicksal_06` Zeitsprung), 4A zu KS-101 (`fluch_04` Verrat, Dorfvariante), 5A zu KS-102 (`fluch_10` Schlechtes Omen, Dorfvariante). Die Buchstaben verweisen auf die Optionen in Abschnitt 26; wo die Antwort Zusatzbestimmungen enthält, gelten diese und gehen der Optionsformulierung vor. Alle fünf Antworten gelten ausdrücklich nur für die genannten Karten und Fraktionsvarianten. Die Antwort zu Zeitsprung wird nicht auf die separate Karte `loki_03` Zeitwarp übertragen. Es ist nichts implementiert: kein Karten-Code, keine Zielwahl des Rudels, keine Schutzänderung, keine Nachtzählung, keine Wiederholung von Wahlgängen, keine Todesbedingung, keine Kartenverteilung, kein Kartentausch, kein Kartenschlucker, keine Änderung an Speicherschema, Regelkern-Tests oder Oberfläche. Die Originaltexte der Karten und früherer Abschnitte bleiben unverändert stehen.

**Bestätigt (Product Owner):**

- **`wende_03` Wendepunkt, Wolfsvariante (KS-98, 1A):** Das Rudel wählt in einem gemeinsamen Schritt zwei verschiedene Personen. Beide Ziele werden festgelegt, bevor Ergebnisse der Angriffe bekannt werden. Schutzwirkungen werden für jedes Opfer einzeln geprüft. Es gibt keine zweite Zielwahl in Kenntnis des Ergebnisses des ersten Angriffs und keine doppelte Auswahl derselben Person. Daraus folgt keine zusätzliche Regel über die Reihenfolge der Todesauflösung. Die Dorfvariante wurde durch diese Antwort nicht weiter entschieden.
- **`wende_06` Trotz, Wolfsvariante (KS-99, 2A):** Direkte Tötungen von Wölfen durch Rollenfähigkeiten werden in der betroffenen Nacht verhindert. Gift gehört ausdrücklich dazu. Todesketten wie Liebeskummer und durch Karten verursachte Tode bleiben möglich. Es gibt keine allgemeine Unsterblichkeit der Wölfe. Die Dorfvariante wurde durch diese Antwort nicht weiter entschieden. Konkrete Grenzfälle zwischen direkter Rollenwirkung und Todesreaktion werden bei Bedarf getrennt erfasst und nicht pauschal neu entschieden.
- **`schicksal_06` Zeitsprung (KS-100, 3A):** Die übersprungene Nacht zählt als Nacht. Die Nachtnummer steigt normal weiter, und in Nächten gemessene Fristen laufen weiter. Aktionen und Ansagen der übersprungenen Nacht entfallen. Beispiel: Nach übersprungener Nacht 3 ist die nächste gespielte Nacht Nacht 4; eine auf Nacht 3 terminierte Kartenschlucker-Ansage entfällt. Das Zusammenspiel ablaufender Fristen mit „kein Tod in dieser Nacht“ ist **nicht entschieden** und wird nicht aus dieser Antwort abgeleitet. Die Entscheidung gilt nicht ungefragt für `loki_03` Zeitwarp.
- **`fluch_04` Verrat, Dorfvariante (KS-101, 4A):** Für das Ende der durch die Karte verlangten Wiederholungen genügt, dass eine Dorfperson zur Hinrichtung ausgewählt wird. Verhindert ihr persönlicher Schild den Tod, wird er verbraucht. Danach gibt es keine weitere Abstimmung aufgrund von Verrat. Ein tatsächlicher Tod der Dorfperson ist für diese Bedingung nicht erforderlich.
- **`fluch_10` Schlechtes Omen, Dorfvariante (KS-102, 5A):** Ein Wolf zählt nur dann als hingerichtet, wenn die Hinrichtung tatsächlich zu seinem Tod führt. Verhindert ein Schild seinen Tod, ist die Kartenbedingung „kein Wolf hingerichtet“ erfüllt, und der zusätzliche zufällige Dorftod wird ausgelöst. Die bereits bestätigte Schildregel für dieses Zusatzopfer bleibt bestehen: Ein persönlicher Schild kann es retten, wird verbraucht, und es gibt kein Ersatzopfer (KS-93).

**Bewusst unterschiedlicher Auslöser (nicht angleichen):**

| Karte | Wann ist die Kartenbedingung erfüllt | Bei durch Schild verhinderter Hinrichtung |
|---|---|---|
| `fluch_04` Verrat, Dorf (KS-101) | Sobald eine Dorfperson zur Hinrichtung **ausgewählt** wird (Auswahl). Ein tatsächlicher Tod ist nicht erforderlich. | Die Bedingung ist erfüllt, keine weitere Abstimmung wegen Verrat. |
| `fluch_10` Schlechtes Omen, Dorf (KS-102) | Ein Wolf zählt nur als hingerichtet, wenn die Hinrichtung tatsächlich zu seinem **Tod** führt (tatsächlicher Hinrichtungstod). | Der Wolf gilt nicht als hingerichtet, die Bedingung „kein Wolf hingerichtet“ ist erfüllt, der zusätzliche Dorftod wird ausgelöst. |

Beide Antworten konkretisieren die in KS-92 offen gelassene Frage, was „getroffen“ beziehungsweise „hingerichtet“ bei Sonderkarten bedeutet, und zwar nur für diese zwei Karten in ihrer Dorfvariante. Die allgemeine Regel aus KS-92 (kein Ersatzopfer, keine neue Abstimmung allein wegen des Schilds) wird dadurch nicht geändert.

**Ersetzt (nicht mehr gültig):**

- KS-98 bis KS-102: Empfehlung A ist jeweils bestätigt; die übrigen Optionen sind nicht gewählt. Bei KS-98 sind damit ausdrücklich ein zweiter Rudelschritt in Kenntnis des Ergebnisses (Option B) und die doppelte Auswahl derselben Person (Option C) nicht gewählt. Bei KS-99 sind „nur Tötungen auf ausdrückliche Zielwahl“ (Option B) und „alle Tode von Wölfen in dieser Nacht“ (Option C) nicht gewählt. Bei KS-100 sind „die Nacht zählt nicht“ (Option B) und „Nachtnummer steigt, Fristen pausieren“ (Option C) nicht gewählt. Bei KS-101 ist „tatsächlicher Tod verlangt, weitere Wahlgänge bis dahin“ (Option B) nicht gewählt. Bei KS-102 ist „die Auswahl zählt als gelyncht“ (Option B) nicht gewählt.
- Arbeitsliste Abschnitt 26, „Reihenfolge der nächsten Runden“: überholt durch Abschnitt 28.

**Technisch abgeleitet (nicht bestätigt, Diskussionsgrundlage):**

- `fluch_04` Dorf: Dass auch eine auf anderem Weg als durch den persönlichen Schild verhinderte Hinrichtung (zum Beispiel durch `wende_02` oder `segen_09`) als „ausgewählt“ genügt, liegt nach dem Wortlaut der Antwort nahe, ist aber nicht bestätigt. Bestätigt ist nur der persönliche Schild.
- `fluch_10` Dorf: Dass der zusätzliche Dorftod auch dann eintritt, wenn gar keine Hinrichtung stattfindet (Tag ohne Hinrichtung, Verhinderung auf anderem Weg als durch Schild), folgt aus „zählt nur bei tatsächlichem Tod“, ist aber nicht bestätigt (KS-26, KS-96).
- `wende_06` Wolf: Dass die Verhinderung im Moment der Rollenwirkung greift und keinen Schild verbraucht, entspricht der Beschreibung von Option A, die gewählt wurde; die Abgrenzung zu `fluch_05` Gebrochener Schild und zum Begriff „Schutz“ ist nicht entschieden (KS-65, KS-104).

**Weiter offen (nicht entschieden, nicht erfunden):**

- `wende_03`: Wolf: Schutz und Schild je Ziel in der Auflösung (KS-97); Verhältnis zu `segen_09` Wolf (gleicher Wortlaut „zwei Opfer“, nicht gleichgesetzt) und zu Zusatzopfern; Ansage; Bezug „diese Nacht“. Dorf: Ablauf der Verhinderung, Öffentlichkeit des Einschreitens, Fraktionsbezug, „vollstreckt“ bei einem Wolf mit Schild, „darf heute lynchen“ gegenüber Tag ohne Hinrichtung (KS-103).
- `wende_06`: Wolf: Bezug „heute“, Verhältnis zu `fluch_05` und zur Frage, was „Schutz“ ist, Grenzfälle zwischen Rollenwirkung und Todesreaktion, Ansage. Dorf: Reichweite nach dem Muster von `segen_04` Dorf oder `fluch_07` Wolf oder eigene Regel (KS-104).
- `schicksal_06`: Wechselwirkung ablaufender Fristen mit „kein Tod“ (gestellt als KS-109 für die Giftpranke des Giftwolfs und als KS-110 für die Wahl des Todespredigers); weiter Bezug „diese Nacht“ nach KS-56, nicht tödliche fällige Wirkungen (Pest-Ausbreitung), Einmal-Fenster in festen Nächten, Kartenschlucker-Aktion, Siegprüfung, Kollision mit anderen Nachtkarten, Verhältnis zu `loki_03` (KS-105, KS-106).
- `fluch_04` Dorf: Nominierungen in Wiederholungen; Ende der Schleife außer durch die Siegprüfung; Zugehörigkeit zur „Dorf-Fraktion“ bei Einzelsiegrollen und Wechselrollen (ÜB-1); Todesketten. Wolf: Rest wie zuvor (KS-94).
- `fluch_10` Dorf: Tag ohne Hinrichtung (KS-26); Zufall über den gespeicherten Generator (ÜB-4); Pool; „noch am selben Tag“ gegenüber der Tagesend-Reihenfolge; fehlende passende Person. Wolf: Rest wie zuvor (KS-96).
- Die Karten `wende_03`, `wende_06`, `schicksal_06`, `fluch_04` und `fluch_10` sind damit **nicht vollständig spezifiziert** und nicht implementiert.

**Vorbereitet (keine Entscheidung):** Arbeitsliste Abschnitte 27 und 28 mit den nächsten Karten `loki_03` Zeitwarp (letzte Karte der Gruppe 3), `segen_06` Schattenmantel (erste Karte der Gruppe 4) und `segen_12` Geisterhand (Fragen KS-106 bis KS-108), zwei Klärungen zu Zeitsprung (KS-109 Giftwolf, KS-110 Todesprediger) und Folgepunkten KS-111 bis KS-113. Die drei neuen Karten sind nicht spezifiziert und nicht entschieden.


## Totenreichkarten und Kartenschlucker: Umsetzung (01.10.2026)

**Herkunft:** Umsetzungsauftrag des Product Owners vom 01.10.2026 (alle 80 Karten, 119 Varianten und der Kartenschlucker). Die
Mechanik steht im Regelkern (`core/rules/card_*.gd`, `swallower_rules.gd`), die Bedienung in der Anwendungsschicht und im Cockpit.
Umsetzungsstand je Karte: `docs/role-migration/15-totenkarten-umsetzungsmatrix.md`.

**Bestätigt und umgesetzt (Product Owner, mit Test `test_cards_decisions`):**

- KS-106: Zeitwarp übernimmt die Zählregel von Zeitsprung (Nachtnummer und Fristen laufen weiter, Aktionen und Ansagen entfallen).
- KS-107: Schattenmantel, Dorf: ein Zufallsziel ersetzt die normale Rudelzielwahl (auch ein Wolf kann getroffen werden).
- KS-108: Geisterhand verleiht die zusätzliche Fähigkeit frisch mit verfügbaren Einsätzen.
- KS-109: Bereits fälliges Gift wirkt am Ende der durch Zeitsprung übersprungenen Nacht (ausdrückliche Ausnahme von „kein Tod“).
- KS-110: Die gewählte Nacht des Todespredigers zählt auch beim Überspringen; keine Verschiebung und keine Ersatzwahl.

**Technische bzw. redaktionelle Entscheidung innerhalb dieses Auftrags (nicht vom Product Owner bestätigt, jederzeit änderbar):**

- Variante: Die Variante einer Karte (Wolf, Dorf, neutral, Solo) richtet sich nach der Fraktion beim Tod und bleibt fest (ÜB-1).
  Neutrale Karten wirken auf die Seite der Besitzerin.
- Fenster: Die Reihenfolge der Fragen im Kartenfenster folgt der Ziehreihenfolge der Karten. Offene Reaktionen gehen dem Fenster vor.
  Ein Spielleiter-„Hinrichten“ ist bei offenem Kartenfenster nicht möglich (zuerst schließen).
- Tausch: Die Ersatzkarte nach einem Tausch wird sofort gespielt. Tauschen ist nur mit lebendem Kartenschlucker möglich.
- Phoenix (`loki_10`): Der Tag des Spielens zählt als erster Tag; die Rückkehrenden sterben nach Hinrichtung und Todeseffekten des letzten
  Tages (im zweiten Fenster mit einem Tag Lebensdauer: Ende des Folgetags). Würfel sind App-Würfel mit gespeicherten Ergebnissen.
- Befreiung (`wende_07`): Als „Einsatz der Fähigkeit“ zählt ein abgeschlossener eigener Nachtschritt mit Auswahl, Ja oder Bestätigung oder
  eine Tagesaktion (Amalia, Nekromant); ein Verzicht zählt nicht.
- Zweites Leben (`segen_08`): Das Angebot (bis zu drei Namen) wird gespeichert; ungültig gewordene Namen werden deterministisch durch die
  kleinsten noch gültigen IDs ersetzt (KS-38).
- Geisterhand-Stellvertretung (`loki_08`): Die Spielleitung bestimmt, wer die Nachtfähigkeit der Karteninhaberin in der nächsten Nacht ausführt.
- Gleichgewicht (`schicksal_07`): Blockiert wird der erste Schritt der führenden Fraktion im Nachtplan; ein bereits behandelter erster
  Schritt bleibt der blockierte, der nächste rückt nicht nach.
- Puppenspieler (`loki_09`): Die fünf Nominierten decken so viele Fraktionen ab, wie bei der Größe möglich sind; die App prüft das.
- Solo-Karten: Auslegungen in `core/rules/card_fx_solo.gd` (Kopfkommentar): Zettel und Tipps trägt die Spielleitung ein, stille Mitsieger
  erscheinen nach bestätigtem Spielende im Abschlussbericht, Stimmenzahlen werden am Tisch gezählt.
- Tischregeln (Nebelhorn, Stummfilm, Totengericht): Die App hat keinen Timer, der Tischregeln durchsetzt. (Ein rein anzeigender, von der Spielleitung einstellbarer Timer für Tagphase, Diskussion und Nacht (abschaltbar) ist separat entschieden: `DECISIONS.md`, 01.10.2026, Umsetzung in P3 der visuellen Roadmap; er ändert an dieser Regel nichts.) Regelverstöße meldet die Spielleitung als Button, die Folge
  (Ausschluss, Tod) setzt der Kern um.
- Kartenschlucker: Nur mit Totenreichkarten wählbar, keine Scheinrolle; Schild, Stapel und Ansagen wie in `swallower_rules.gd`.
- Speicherformat: Schema 15 und Regelversion 0.15; ältere Spielstände werden als „nicht kompatibel“ gemeldet und nie überschrieben.
- Oberfläche: Hauptaktionen des Kartenfensters (Spielen, Aufbewahren, Tauschen) stehen unter dem Kartentext und sind ohne Scrollen
  erreichbar; Erklärung, Zeigen, Überblick und Schließen folgen darunter. Regelbuch Kapitel 13 erklärt Fenster, Tausch und Kartenschlucker.

**Entdeckte und behobene Fehler (durch die Tests dieses Auftrags):** Reaktionen blockierten das Kartenfenster nicht (Cockpit), ein
Spielleiter-„Hinrichten“ bei offenem Fenster brach den gespeicherten Zustand, Einzelauswahlen kamen als Zahl statt als Liste an, eine
Morgenauflösung endete nicht nach der letzten Aufgabe ohne Eingabe, die Mischprüfung des Puppenspielers wurde nie aufgerufen, falsch
typisierte Antworten lösten Skriptfehler aus, „Gleichgewicht“ sperrte mehrere Schritte, neutrale Karten (Anarchie, Totale Anarchie,
Geisterhand-Stellvertretung) fanden nie ein Ziel.

**Offen und nicht entschieden (nicht erfunden):** Einzelfälle, die die Arbeitsliste ausdrücklich als offen führt, bleiben offen; dazu zählen
Kombinationen mehrerer Karten, die dort nicht beantwortet sind. Nicht geprüft: Tablet, Touch, visuelle Abnahme, Audio.

## DA-Nachtschritte-neu: Kartentext gilt, Pflichtwahlen (Markus, 04.10.2026)

Grundlage: `docs/audit/NACHTSCHRITTE-72.csv` und `docs/audit/NACHTSCHRITTE-PRINZIPIEN.md`. Diese Entscheidung ersetzt B-05 (Loki freiwillig)
und alle widersprechenden Lexikon-Einträge. Die Karte gilt: Wo sie keinen Verzicht vorsieht, gibt es keinen Verzichten-Knopf.

1. **Kein Verzicht** bei Loki (immer genau 2 Personen), Spürhund (immer genau 3), Albtraumwolf, Besessener Wolf, Dämonischer Wolf,
   Feuerteufel, Henker, Sensenträger und Voodoo-Priester. Der Kern lehnt eine leere Antwort mit `invalid_target_count` ab. Ohne mögliches
   Ziel (weniger Lebende als nötig) entfällt der Schritt (`no_decision`) beziehungsweise gibt es keine Reaktion. Beim Feuerteufel
   bedeutet dieselbe Person erneut zu wählen: Markierung behalten.
2. **Die Werwölfe töten jede Nacht ein Opfer.** Es gibt kein „Kein Opfer“. Einigen sie sich nicht, tippt der Spielleiter das Opfer an.
   Der Befehl `SkipStep` für den Rudelschritt bleibt als Ausweg der Spielleitung mit Begründung im Kern erhalten (die Oberfläche bietet
   ihn nicht an).
3. **Lehrling:** Er wählt seinen Meister direkt (genau 1 andere lebende Person, eine Stufe). Stirbt der Meister, übernimmt der Lehrling
   dessen Rolle (Erbe unverändert). Die Drei-Rollen-Auswahl und die Bestätigung entfallen; ältere Spielstände mitten in dieser Wahl
   sind nicht mehr ladbar.
4. **König Lykaon** wählt in einer der ersten drei Nächte. Er wird in jeder dieser Nächte gefragt, bis er gewählt hat, danach nie mehr.
   In Nacht 1 und 2 darf er verschieben, in Nacht 3 muss er wählen. Rollentext in der App: „in einer der ersten drei Nächte“. Markus passt
   den gedruckten Kartentext selbst an.

**Folgefehler, die dabei gefunden und behoben wurden:** Ein per Totenreichkarte für eine Nacht geliehener Feuerteufel-Schritt hinterließ
eine Markierung, die beim Laden abgelehnt wurde (die Markierung endet jetzt mit der geliehenen Fähigkeit). „Totale Anarchie“ stellte die
Einsätze eines Grabräubers zurück, sein gespeicherter Diebstahl wurde dann beim Laden abgelehnt.


## DA-93 Audit-Entscheidungen (Markus, 05.10.2026)
Antworten auf die neun Fragen aus der Morgen-Zusammenfassung der Nachtschicht (Audit-Funde in `docs/audit/AUDIT-2026-10-02.md`). Verbindlich.
1. **A-01 Seuchenwolf:** Die Durchdringung wird immer verbraucht, sobald das Rudel angreift, auch wenn das Opfer ohnehin stirbt.
2. **A-02 Schutzgeist:** Bei durchdringendem Rudelangriff bricht der Schild und das Opfer stirbt.
3. **B-06 Parasit:** Verliert er die Rolle, endet auch die Bindung an den Wirt.
4. **S-05:** Markierungen am Sitzkreis sind tagsüber verborgen und per Tipp kurz einblendbar.
5. **S-04:** Die Nachtleiste wird bei der anonymen Rotkäppchen-Frage ausgeblendet.
6. **S-06, S-07, S-09:** Verdeckte Karten zeigen einen einheitlichen Text, der nichts verrät.
7. **UI-02:** Der Beenden-Knopf entfällt im Web. **UI-03** (Exportweg auf dem iPad): nur Notiz für später.
8. **F-A03:** Ungenutzte Bilder verlassen den Export. **UI-04:** Das Favicon ist eine Klein-Fassung des Siegels.
9. **CM-05:** Nach einer Regeländerung wird `RULES_VERSION` erhöht; alte Stände erscheinen als „ältere Version“ statt „beschädigt“.

## DA-94 Fenster-Diät und Morgenbericht (Markus, 05.10.2026, Feedback iPad-Test Teil 2)

Grundsatz: Jedes Fenster, das nur ankündigt, fragt, ob es etwas sagen darf, oder nichts Neues enthält, entfällt. Liste: `docs/audit/FENSTER-DIAET.md`.

1. **Keine verdeckten Karten mehr** (ersetzt DA-93 Punkt 6 für S-06/S-07): Karten mit geheimem Inhalt erscheinen auch am Morgen und am Tag direkt; die Hinrichtungsprüfung ebenso. Schutz vor Mitlesen: Sichtschutz und „Verbergen“. S-05 (Abzeichen tagsüber verborgen, Tipp zeigt 3 s) bleibt.
2. **Nachtende automatisch:** Nach dem letzten Nachtschritt endet die Nacht ohne Karte. Tarnaufrufe danach stehen oben auf der Morgenkarte. Nach Rückgängig oder Laden bleibt die Karte „Nacht abschließen“, sonst würde Rückgängig sofort wieder beenden.
3. **Sieg automatisch:** Ein eindeutiger Sieg nach einer Handlung auf der Karte gilt sofort, danach der Siegbildschirm mit dem Gewinner-Team. Die Siegkarte bleibt bei mehreren Kandidaten und nach Rückgängig oder Laden; ein Tipp bestätigt ohne Rückfrage.
4. **Morgenbericht in zwei Teilen auf einer Karte:** „Fürs Dorf“ (vorlesen) und „Für dich“ (geheim), ein Satz pro Punkt mit Namen, nie interne Daten. Ansagekarte und „Private Details“ entfallen.
5. **Keine Rückfrage** bei „Hinrichten“, „Keine Hinrichtung“ und Sieg bestätigen.
6. **Dauer-Markierungen:** eigene Silberzeichen für Liebende, Rivalen und Verzaubert (statt eines gemeinsamen „Sonderzustand“).
7. **Gezeigte Karte im Grimmhain-Stil:** Eisenrahmen der Aktionskarte (Ornamente nur an den Ecken), Knöpfe im Hain-Stil, Titel als `GothicTitleLabel`. Die gotische Schrift (UnifrakturMaguntia, SIL OFL 1.1) liegt zur Freigabe in `Downloads/Grimmhain-Feedback-2/schrift-zur-freigabe/`; ohne Freigabe kein Eintrag ins Godot-Projekt (Assetregister), bis dahin Grundschrift.

## DA-95 Nominierung am Tag (Markus, 05.10.2026, Feedback iPad-Test Teil 3)

Bestätigt und ergänzt DR-03. Abstimmung bleibt am Tisch (RM-DR-008); die App kennt keine Stimmen, keinen Abstimmungsschritt und keine Mehrheit. Im Code gab es keine digitale Abstimmungslogik, die zu entfernen war; geändert wurden Bedienung und Texte.

1. **Nominieren:** Beliebig viele Nominierungen am Tag. Jede Person nominiert höchstens einmal und wird höchstens einmal nominiert. Die Oberfläche sperrt alles andere still (ausgegraute Sitze, „Nominierung erfassen“ gesperrt, wenn niemand mehr nominieren darf), kein Fehlerfenster. Der Regelkern lehnt Verstöße weiter ab. Eingabe: erst wer nominiert, dann wen. Ausnahme: Die verdeckte Nominierung des Korrupten Richters sperrt den Richter nicht sichtbar, sonst würde er verraten.
2. **Nominierte** tragen am Sitzkreis einen Blutrot-Ring, solange sie leben und der Tag läuft (bis zur Hinrichtung; der Tageswechsel setzt die Nominierung zurück).
3. **Verteidigung:** Unter der Nominierungsliste steht der Vorlesetext „Alle Nominierten dürfen sich jetzt nacheinander verteidigen.“ Kein eigenes Fenster.
4. **Entscheidung:** Der Spielleiter tippt nach der Handzeichen-Abstimmung am Tisch die hingerichtete Person an oder „Niemand“ (vorher „Keine Hinrichtung heute …“). Die Prüfkarte bei jeder Hinrichtung bleibt (DA-94). Die Siegprüfung läuft danach automatisch (DA-94 Punkt 3).

## DA-96 Rivalen (Markus, 05.10.2026, Feedback iPad-Test Teil 4)

Ersetzt B-02 (Rivalen ohne eigene Wirkung). Rivalen können nicht gewinnen, solange der andere Rivale lebt. Die Siegprüfung zählt eine Person mit lebendem Rivalen nie als Gewinner (`BondRules.has_living_rival`, `WinRules.winner_ids`); ein Einzelsieg einer solchen Person wird nicht erkannt. Die Rivalen zählen weiter für Wolfsparität und Dorfsieg, nur ihr persönlicher Gewinn ruht. Stirbt einer, endet das Paar und der andere gewinnt wieder normal mit seinem Team. Die Schwarze Witwe wirkt wie bisher. `RULES_VERSION` 0.18 (ältere Stände erscheinen als „andere Version“). Der Siegbildschirm nennt bei Dorf und Werwölfen die Gewinner mit Namen.

## DA-97 Gotische Titelschrift (Markus, 05.10.2026, Feedback iPad-Test Teil 4)

Statt UnifrakturMaguntia gilt **Grenze Gotisch** (Omnibus-Type, Google Fonts, SIL OFL 1.1), von Markus intern freigegeben und im Assetregister mit Lizenz eingetragen (`godot/assets/fonts/GrenzeGotisch-Variable.ttf`, Lizenztext `OFL-GrenzeGotisch.txt`). Nur für Titel und große Überschriften (`GothicTitleLabel`), nie für Fließtext oder Knöpfe (MARKE.md). UnifrakturMaguntia aus `schrift-zur-freigabe/` wird nicht eingebaut. Ersetzt den offenen Punkt aus DA-94 Punkt 7.

## DA-98 Hinrichtung in zwei Tipps (Markus, 05.10.2026, Feedback iPad-Test Teil 4)

Passt DA-94 an. Person antippen (nominierte Person im Sitzkreis, auch ohne vorheriges „Hinrichtung …“), dann „Hinrichten“. Die Prüfung des Regelkerns läuft beim Antippen im selben Schritt; ihr Ergebnis steht sofort in der Karte der Hinrichtung (Spiegelung, Pflichtfragen wie Cerberus oder Fluchdauer des Weisen). Entfallen sind „Weiter zur Prüfung“ und „Hinrichtung bestätigen“; „Hinrichten“ vollzieht, das Ergebnis (wer stirbt, ausgelöste Wirkungen) steht danach in der Tageskarte. Die Karte erscheint bei jeder Hinrichtung gleich aufgebaut, damit ihr Auftauchen nichts verrät. „Rückgängig“ (3-Sekunden-Leiste) bleibt. Die Spielleiterkorrektur „Hinrichtung ohne Nominierung“ nutzt dieselbe Karte.

## DA-99 Nominierung, gesperrte Sitze (Markus, 05.10.2026, Feedback iPad-Test Teil 4)

Ergänzt DA-95: Bei der Nominierung gesperrte Sitze sind stärker abgedunkelt und tragen ein kleines Silber-Schloss. Der Korrupte Richter bleibt verdeckt (sein Sitz wird nicht gesperrt).

## DA-100 Optik-Runde: aktive Person, Akt-Feuer, Fenster-Baustein (Markus, 05.10.2026, Feedback iPad-Test Teil 5)

(1) Die handelnde Person (bei Gruppenschritten alle) leuchtet im Sitzkreis langsam in Mondsilber auf und ab (Bildrahmen und Namensschild, `GameSeatToken.active`); der Kartentitel nennt die Namen in Klammern. Der blutrote Schein der handelnden Person entfällt, der Feuerring der Wölfe bleibt. (2) Akt-Feuer wächst linear mit der Aktstufe (Akt II doppelt, III dreifach, IV vierfach: Flammenhöhe, Fläche, Helligkeit, Bewegung, Funkenzahl), Funken langsam und treibend. Die Alternativen „blaues Geisterfeuer“ und „Glut mit Rauch“ gibt es nur als Vergleichsbilder (`FireGlow.style`); Standard bleibt das jetzige Feuer, Markus wählt. (3) Alle Fenster teilen den Baustein `GroveWindow` (Eisenrahmen, Hain-Knöpfe); Liste in `docs/audit/FENSTER-OPTIK.md`. (4) „Karte zeigen“: größere Zahl und Schrift, Knopf „Fertig“; Knopftexte mit Programmierersprache sind auf Fertig, Schließen, Weiter umgestellt. (5) Sprachflaggen DE/EN oben rechts auf dem Startbildschirm. (6) Plätze für Ladebild und Musik ohne Wirkung, solange die Dateien fehlen.

## DA-101 Mini-Nachtkarte mit Warnungen, Geisterfeuer für Akt IV (Markus, 05.10.2026, Feedback iPad-Test Teil 6)

Grundsatz: Der Spielleiter kennt das Spiel und spricht frei. (1) Die Nachtkarte ist ein kleines Fenster (höchstens ein Viertel der Bildschirmbreite, Eisenrahmen) mit Rollensymbol, Name der Person(en) und 1 bis 3 Wörtern Aktion; nur die nötigen Knöpfe. Sie steht am unteren Rand der freien Ringmitte und verdeckt keinen Sitz. Ersetzt die Regelzeilen-Regel (Prinzip 1 in `docs/audit/NACHTSCHRITTE-PRINZIPIEN.md`). (2) Regelzeilen, Vorlesesatz und Hilfesätze stehen nicht mehr auf der Nachtkarte; der Regeltext nur hinter dem "i" (Rollentext der Karte und Lexikon, nicht umformuliert). (3) Einstellung "Ansagen anzeigen" (Standard aus) zeigt den Vorlesesatz klein unter der Aktion. (4) Warnungen nur, wenn etwas Besonderes gilt: kurze rote Zeile mit Symbol, höchstens 6 Wörter, keine Kommas, keine Fachwörter, immer mit Namen, höchstens 3; aus dem Zustand im Regelkern abgeleitet (`NightWarnings`), Liste in `docs/audit/NACHT-WARNUNGEN.md`, Texte `ui.warn.*`. (5) Ergebnisse im Fenster "Karte zeigen" groß als Symbol (Haken/Kreuz, Teamsymbol) oder Zahl. (6) Akt-Feuer: Akt I bis III Standard-Feuer mit der Steigerung aus DA-100, Akt IV blaues Geisterfeuer mit den Stärkewerten der Stufe 4; das Feuer liegt in einer Ebene hinter allen Akt-Karten und überdeckt keine Nachbarkarte. (7) Flaggen dürfen ihre echten Farben haben (Ausnahme zu "Kein Gold" in MARKE.md); das Gelb der deutschen Flagge bleibt.

## DA-102 Gemalte Haut, keine Sitznummern, Rollenkarten als Bild (Markus, 05.10.2026, Feedback iPad-Test Teil 8)

Dauerregeln (auch in CLAUDE.md und allen Prüfern): kein Programmier-Text sichtbar; nie Sitzplatznummern, nur Namen; nie scrollen müssen, Text so groß wie möglich und passend; keine Standard-Kästen, jede Fläche, jeder Knopf, jede Liste und jeder Schalter aus gemalten Assets, fehlende Assets in `docs/audit/FENSTER-OPTIK.md` mit ChatGPT-Beschreibung; Knöpfe 1 bis 2 Wörter. (1) Die Rollenkarten-Bilder (`assets/cards/`, nach Godot `godot/assets/cards/{de,en}/<rollen-id>.webp`) sind Eigentum von Markus aus seinem Kartenspiel und voll freigegeben (ersetzt die Einstufung „Herkunft ungeklärt“ für diese Karten). (2) Rollen zeigen: Person antippen, dann groß ihr Kartenbild ohne Text; Antippen schließt und gilt als gesehen. Orakel und alle Ergebnisse vom Typ Rolle zeigen das Kartenbild mit dem Namen darüber. (3) Die Mini-Nachtkarte steht mittig auf dem Dorfplatz (ändert „unterer Rand“ aus DA-101). (4) Markierungen am Ring sind nur für den Spielleiter (Tablet bleibt bei ihm) und tagsüber verborgen wie S-05. (5) Ganze Bildschirme brauchen keinen Fensterrahmen, nur Fenster. (6) Hauptknöpfe tragen den roten Mittelstein links neben dem Text (aktiv glüht, gedrückt glimmt), normale Knöpfe nicht. (7) Nominierungsband vom Nominierenden (Mondblau) zum Nominierten (Blutrot) bis zur Hinrichtung, mehrere gleichzeitig; verdeckte Nominierungen erzeugen kein Band. (8) Startmusik in Schleife ab dem ersten Tippen, in den Einstellungen abschaltbar. (9) Asset-Ablage `C:/Users/Marku/Downloads/Grimmhain/`, Web-Export nach `Downloads/Grimmhain/Web`.

## DA-103 Antworten zu Feedback 8 (Markus, 06.10.2026, Feedback iPad-Test Teil 9)

Beantwortet die offenen Fragen aus Feedback-Runde 8. (1) Schalter tragen kein Wort („An“/„Aus“), das Glühen des gemalten Schalters reicht. (2) Rollenlisten (Lexikon, Rollen-Vorschau) zeigen Rollennamen in kräftigen Teamfarben: Dorf Mondblau, Wölfe Blutrot, Einzelgänger Violett, gut lesbar auf dunklem Grund. (3) Der Zusatz „(N)“ hinter nominierten Namen am Ring entfällt; roter Ring und Nominierungsband (DA-102 Punkt 7) reichen. (4) Die Rollenkarten-Bilder bleiben unverändert, auch mit ihrem gelben Titel: Gedruckte Karten sind ein eigenes Produkt (Ausnahme zu „Kein Gold“ in MARKE.md).

## DA-104 Antworten zu Feedback 9 (Markus, 06.10.2026, Feedback iPad-Test Teil 9b)

Beantwortet die offenen Fragen aus Feedback-Runde 9. (1) Schutzring und Schutzschild am Ring sind Mondblau statt Gold. (2) Kein Punkt „•“ vor dem Namen der handelnden Person; das Leuchten (DA-100) reicht. (3) Der Knopf „Nominieren“ im Tag heißt „Anklagen“ (EN „Accuse“). (4) Die Vollbildkarte bekommt keinen Hinweis „Antippen schließt“ (DA-102 Punkt 2 bleibt: Antippen schließt). (5) Am Ring wird kein Name stark gekürzt: auch bei 24 Personen ist jeder Name ganz lesbar, mindestens 14 px, notfalls zweizeilig oder mit etwas kleineren Porträts.
