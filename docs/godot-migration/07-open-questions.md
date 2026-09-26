# 07 · Offene Fragen an den Product Owner

**Stand:** 2026-09-26. Nur Entscheidungen, die der Code nicht beantwortet und die die Umsetzung spürbar verändern. Technische Detailfragen (Godot-Version, Dateiformat, Teststruktur) sind in `03` entschieden.

**Blockierend für den nächsten Schritt:** keine. **Blockierend für den Tablet-MVP (Slice 4):** Q1 (nur Akt-I-Zeilen), Q5, Q6, Q8 (Nachtmusik), Q9.

---

## Q1 · Was gilt bei Widerspruch zwischen Rollentext und Legacy-Verhalten?

**Kontext.** 19 Rollen sind in `04` als *widersprüchlich* markiert, 3 als *unklar*. Beispiele: Der Dämonische Wolf macht sein Opfer im Code zu einem echten Wolf (Siegparität), der Text sagt nur „wird als Wolf gesehen". Der Zeitwächter bricht im Code nur die Wolfstode ab, laut Text alle Nachtaktionen. Die Pestbringerin tötet im Code nie.

| Option | Auswirkung |
|---|---|
| A · **Text gilt** | Spiel entspricht Karten und Website; mehr Umsetzungsaufwand; Legacy-Golden-Tests für diese Rollen entfallen |
| B · **Legacy-Code gilt** | Schnell portierbar; Texte müssen angepasst werden; bekannte Bugs (z. B. Seelentauscher erzeugt zwei Wölfe) würden sonst übernommen |
| C · **Pro Rolle entscheiden** anhand der Tabelle unten | Bester Spielwert; einmalig ca. 1–2 Stunden Entscheidungsarbeit |

**Empfehlung: C**, mit Voreinstellung „Text gilt, außer der Code ist spielerisch besser und der Text wird angepasst". Offensichtliche Bugs (Tabelle Teil 2) werden in jedem Fall behoben.

**Teil 1 · Regelentscheidungen** (bitte je Zeile Text / Code / eigene Regel)

| Rolle | Text sagt | Code tut | Vorschlag |
|---|---|---|---|
| Loki | Rivalen als Fluch | Rivalen ohne Wirkung (nur Witwe) | Rivalen: sterben nicht zusammen, gewinnen aber nie gemeinsam; oder Option entfernen |
| Rachsüchtiger Wolf | will alleine gewinnen | gewinnt mit Rudel | Text |
| Schwarze Witwe | Loki wird automatisch gewählt | nur Setup-Pflicht | Code, Text anpassen |
| Der Weise | überlebt ersten Angriff | per Popup doppelt | Text (Bug beheben) |
| Verdammniswächter | umgeht alle Schutzfähigkeiten, Urteil statt Opfer | tötet sofort, Schilde greifen trotzdem | Text: Tod am Morgen, ignoriert Schutz und Schilde |
| Wahnsinniger Kutscher | DE: Nachbarn; EN: lebende Nachbarn | direkte Sitze | lebende Nachbarn |
| Pestbringerin | tödliche Seuche jede Nacht | 2 Tränke, Gift tötet nie, Ausbreitung, Sieg wenn alle vergiftet | Code, Text anpassen (Mechanik ist durchdacht) |
| Dämonischer Wolf | Verfluchter erscheint als Wolf | zählt als Wolf | Text (nur Erscheinung) |
| Schattenhund | Dorf-Fähigkeiten einer Nacht blockieren; Nacht-1-Gruppe | nicht in Nacht 1, blockiert auch Solos | Ab Nacht 2, nur Dorf |
| Fenrir | überlebt einmal jeden Tod ab Stufe 3 | nur Lynch | Text |
| Traumdeuter | Visionen über Rollen oder Zustände | 3 Namen, 1 Wolf | eigene Mechanik festlegen oder Code übernehmen und Text anpassen |
| König | einmal | jede Nacht, solange Tote > Lebende | einmal pro Nacht, solange Bedingung gilt (Code) |
| Nekromant | Schild „beliebig" | Schild schützt die nächste Person, die irgendwie stirbt; Pflicht-Umlenkung | Schild nur für sich selbst; Umlenkung optional |
| Kartenschlucker | Stapel, Sieg bei 10 | + Kill ab 2, Schild ab 5, Ansage | Text anpassen und Zusatzkräfte behalten oder streichen |
| Zeitwächter | alle Nachtaktionen abgebrochen | nur Wolfstode | Alle Tode dieser Nacht rückgängig (einfach dank Undo-Modell) |
| Schutzengel | schützt vor nächstem Wolfsangriff | Schutz wird bei Fehlklick des Wolfs verbraucht | Verbrauch erst bei Auflösung |
| Giftwolf | 2 Ladungen | beide in einer Nacht möglich | maximal 1 pro Nacht |
| Sensenträger | beim Tod | nach Tageslynch erst nach nächster Nacht | sofort |
| Reaktionen auf Sofort-Tode in der Nacht (Hexe, Hades …) | – | teils sofort, teils am Morgen | alle Reaktionen am Morgen, außer der Tote ist selbst ein Nachtschritt |

**Teil 2 · Bugs, die ohne Rückfrage behoben werden** (Einwand nur bei Absicht): Schutzgeist nie aktiv, fehlende Wolfszeile, Albtraumwolf rettet Opfer, Seelentauscher zwei Wölfe, toter Lehrling erbt, manueller Tod umgeht Folgen, zwei Siegprüfer, Detektiv `{name}`, Cerberus/Fenrir überspringen Lynchzählung, Manipulator bei Richter-Nominierung, `killedTonight` mit Überlebenden, Dorfchronistin-Zeile bleibt. Details: `04`, `01` §7.1.

---

## Q2 · Braucht der Tag eine Stimmabgabe in der App?

**Kontext.** Heute wählt der SL den Hingerichteten direkt (`night:421`). Blutwolf (Stimmgewicht), Hades (×3), Korrupter Richter (+1) und etwa 40 der 80 Totenkarten beziehen sich auf Stimmen, die die App nicht kennt.

| Option | Auswirkung |
|---|---|
| A · Direktwahl bleibt | Schnell, bewährt; Stimm-Rollen und -Karten bleiben SL-Handarbeit mit Hinweis |
| B · **Optionale Stimmerfassung** (SL tippt pro Nominiertem die Stimmen, App gewichtet und zeigt Ergebnis, SL bestätigt) | Stimm-Rollen werden automatisch, Karten später automatisierbar; +6–10 Tage; Tempo bleibt, wenn abgeschaltet |
| C · Volle Abstimmung mit Einzelstimmen pro Spieler | Maximal nachvollziehbar; langsam am Tisch; +12–18 Tage |

**Empfehlung: A im MVP, B in 1.0.**

---

## Q3 · Wie weit werden Totenkarten automatisiert, und wann wird gezogen?

**Kontext.** 80 Karten, keine automatisiert. Gezogen wird für Nicht-Wölfe beim Spielstart, dadurch greift die Gewichtung „wer liegt zurück" zum falschen Zeitpunkt (`01` §4.6).

| Option | Auswirkung |
|---|---|
| A · **Assistent ohne Automatik**: Karte zeigen, Checkliste der manuellen Schritte, „erledigt" | 5–8 Tage; alle Karten sofort nutzbar |
| B · Teilautomatik für Karten ohne Stimmbezug (~40) | +15–25 Tage; nur mit Q2 = B/C sinnvoll erweiterbar |
| C · Vollautomatik | +30–45 Tage; setzt Q2 = C voraus |

Zeitpunkt der Ziehung: **beim Tod** (Gewichtung sinnvoll) oder **beim Spielstart** (heutiges Verhalten, Karte vorab festgelegt).

**Empfehlung: A, Ziehung beim Tod.** Automatisierung einzelner Karten erst nach Pilotdaten.

---

## Q4 · Fehlende Solo-Siege und Siegpriorität

**Kontext.** Prophet des Untergangs, Feuerteufel, Voodoo-Priester, Grabräuber, Die Ewigen (Mitsieg) und Rachsüchtiger Wolf haben keinen Siegcode. Gleichzeitige Siege (z. B. Pest und Wolfsparität am selben Morgen) haben keine definierte Priorität.

| Option | Auswirkung |
|---|---|
| A · Siegbedingungen jetzt festlegen und implementieren | Vollständiges Spiel; Regeldesign-Aufwand |
| B · **Generischer Button „Sieg erklären"** (SL wählt Sieger + Grund, protokolliert) plus Implementierung, wo die Bedingung klar ist | Sofort spielbar, später verfeinerbar |
| C · Rollen ohne Siegbedingung aus 1.0 nehmen | Weniger Umfang |

Priorität bei Gleichzeitigkeit, Vorschlag: **Solo vor Wölfen vor Dorf**; innerhalb der Solos in Reihenfolge des auslösenden Ereignisses.

**Empfehlung: B**, Siegbedingungen für die sechs Rollen bis Slice 6 festlegen.

---

## Q5 · Rollenumfang des Tablet-MVP

| Option | Auswirkung |
|---|---|
| A · **Akt I (17 Rollen) automatisiert**, übrige 55 „manuell geführt" | MVP nach ca. 30–47 Tagen |
| B · Akte I + II (≈ 40 Rollen) | +15–20 Tage |
| C · Alle 72 | MVP ≈ Version 1.0 |

**Empfehlung: A.** Akt I enthält die bekanntesten Rollen; seine Widersprüche (Loki-Rivalen, Rachsüchtiger Wolf, Der Weise, Schutzengel-Zeitpunkt, Nachtwächter ohne Wirkung) sind überschaubar und in Q1 erfasst.

---

## Q6 · Sprachen zum MVP

**Kontext.** UI-Schlüssel DE/EN existieren (322), Rollentexte EN existieren, Totenkarten nur DE.

| Option | Auswirkung |
|---|---|
| A · **Nur Deutsch im MVP**, Schlüsselstruktur von Anfang an, EN in 1.0 | Schneller Pilot im deutschsprachigen Raum |
| B · DE + EN im MVP | +3–5 Tage Übersetzung und Prüfung |

**Empfehlung: A.**

---

## Q7 · Zielgeräte

| Option | Auswirkung |
|---|---|
| A · **Android-Tablets zuerst, iPad in 1.0** | Kein Mac nötig bis 1.0 |
| B · Android + iPad im MVP | Mac + Apple-Entwicklerkonto sofort nötig; doppelter Gerätetest |
| C · Nur Desktop zuerst | Widerspricht Tablet-Ziel |

**Empfehlung: A.** Bitte zusätzlich das konkrete Referenz-Tablet (schwächstes zu unterstützendes Gerät) benennen.

---

## Q8 · Herkunft und Lizenz der Assets

**Kontext.** `Nachtmusik.mp3` (60 min) ohne Herkunftsnachweis; 24 Bilder tragen OpenAI-Metadaten, Karten laut Roadmap KI-generiert; Schrift-Lizenzdateien fehlen.

| Option | Auswirkung |
|---|---|
| A · KI-Assets behalten, Herkunft protokollieren, auf Steam offenlegen | Günstig; eingeschränkter Urheberrechtsschutz |
| B · **Gemischt**: KI für Prototyp/Platzhalter, finale Schlüsselassets (Porträts, Musik, Cues) beauftragt oder selbst erstellt | Stärkere Rechte an Markenkern; Budget nötig |
| C · Alles beauftragen | Teuer, lange Vorlaufzeit |

Zur Nachtmusik: Liegt eine Lizenz vor? Falls nein, wird sie für den MVP durch eine lizenzfreie oder beauftragte Schleife ersetzt.

**Antwort zur Nachtmusik (PO, 2026-09-26):** Kein belastbarer Lizenz- oder Herkunftsnachweis; die Datei bleibt gesperrt und wird ersetzt (`../masterplan/DECISION-LOG.md`). Die Grundsatzfrage A/B/C ist weiter offen; Bestandsaufnahme in `../assets/INVENTORY.md`.

**Empfehlung: B.**

---

## Q9 · Was passiert mit der Web-App während der Migration?

| Option | Auswirkung |
|---|---|
| A · Einfrieren | Klare Konzentration; bekannte Fehler bleiben für laufende Nutzer |
| B · **Nur kritische Fehler** (Spielstandsverlust, falsche Auflösung) bis zum MVP-Go, danach Einfrieren | Nutzer bleiben versorgt; geringer Nebenaufwand |
| C · Parallel weiterentwickeln | Doppelte Arbeit, Regeldrift |

**Empfehlung: B.**

---

## Q10 · Müssen alte Web-Spielstände übernommen werden?

**Kontext.** Runden dauern einen Abend; Spielstände liegen im Browser-`localStorage`.

| Option | Auswirkung |
|---|---|
| A · **Kein Import**; nur gespeicherte Gruppen (Namen) optional per Textliste | Kein Aufwand |
| B · Import von Namen, Rollen und Sitzfolge aus einer exportierten Legacy-Datei | 2–3 Tage; Legacy braucht einen Export-Button |

**Empfehlung: A.**
