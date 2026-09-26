# 02 · Produkt- und UX-Spezifikation

**Stand:** 2026-09-26 · Kennzeichnung: **[B]** Beobachtung, **[S]** Schlussfolgerung, **[E]** Empfehlung (siehe `01`).
Diese Spezifikation beschreibt das Zielprodukt in Godot. Wo sie auf bestehendes Verhalten aufbaut, ist die Fundstelle genannt.

---

## 1. Produktversprechen

> Grimmhain hält dem Spielleiter den Kopf frei: Er führt die Runde, die App behält Regeln, Effekte und den nächsten Schritt im Blick. (Positionierung aus `GRIMMHAIN-ANALYSE-UND-ROADMAP-2026-09-15.md`, Abschnitt 1, als Hypothese übernommen.)

**Nicht-Ziele für Tablet-MVP und 1.0 [E]:** Spieler-Apps, Online-Lobbys, Accounts, KI-generierte Regelentscheidungen, Shop.

---

## 2. Zielgruppen und Kernaufgaben

| Persona | Kontext | Braucht vor allem |
|---|---|---|
| **Erstleiter** (hat Werwolf gespielt, nie geleitet) | 8–12 Freunde, abends, gedimmtes Licht | Geführter Ablauf, vorlesbare Ansagen, Schutz vor Fehlbedienung, Lernrunde |
| **Erfahrener Leiter** (leitet regelmäßig, kennt Akte) | 12–24 Spieler, schnelle Runden | Tempo, kompakte Texte, schnelle Korrektur, keine Zwangsdialoge |
| **Gruppenleiter** (Jugendgruppe, Klasse, Verein) | 15–30 Personen, unruhige Umgebung, Unterbrechungen | Wiederaufnahme, große Schrift, Pause/Schutzschirm, gespeicherte Gruppen |
| **Später: Streamer/PC-Leiter** | Desktop, zweiter Bildschirm | Öffentliche Anzeige, Maus/Tastatur |

### Kernaufgaben (Jobs to be done)

1. Runde in unter 2 Minuten vorbereiten (Gruppe, Akt, Rollen, Verteilung).
2. Jedem Spieler seine Rolle diskret zeigen.
3. Die Nacht fehlerfrei abarbeiten: wer wacht auf, was ist erlaubt, was passiert.
4. Den Morgen verkünden: was ist öffentlich, was bleibt geheim.
5. Den Tag moderieren: Diskussion, Nominierung, Entscheidung, Folgeeffekte.
6. Sonderfälle auflösen, ohne Regeln nachzuschlagen (Tod mit Folgen, Wiederbelebung, Rollenwechsel, Totenkarte).
7. Fehler korrigieren, ohne die Runde zu verlieren.
8. Nach Unterbrechung in höchstens 10 Sekunden wissen, wo man steht.
9. Das Spielende erkennen und eine Chronik zeigen.

---

## 3. Vollständiger Ablauf von Setup bis Spielende

```
Start ─┬─ Fortsetzen (letzte Runde, Datum, Phase) ──────────────────────────┐
       └─ Neue Runde                                                         │
            1 Gruppe: Namen (Liste/Zeilen/Komma), gespeicherte Gruppe, Sitzfolge ziehen
            2 Rollen: Akt wählen → Vorschlag nach Spielerzahl → anpassen → Prüfung
            3 Verteilung: zufällig | manuell | gemischt (einige fest)
            4 Rollen zeigen: Übergabe-Modus Sitz für Sitz (Schutzschirm)
            5 Bereitschaftscheck: Lautstärke, Helligkeit, Sonderregeln, "Alle kennen ihre Rolle"
                                                                              │
   ┌──────────────────────────────────────────────────────────────────────────┘
   ▼
 NACHT n ── Nachtbeginn-Ansage ── Rollenschritte (geführt) ── Nacht-Check (offene Punkte)
   ▼
 MORGEN ─── Auflösung (automatisch) ── Reaktionen abarbeiten (Warteschlange) ── Morgenbericht
   ▼
 TAG ────── Diskussion (Timer) ── Nominierung ── Entscheidung (Hinrichtung/keine) ── Folgen
   ▼
 (Sieg geprüft nach jeder Auflösung) ── bei Sieg: SPIELENDE ── Chronik ── Neue Runde (gleiche Gruppe)
```

### 3.1 Vorbereitung im Detail

| Schritt | Verhalten [E] | Heute [B] |
|---|---|---|
| Namen | Einfügen als Zeilen, Komma oder Semikolon; Vorschau mit Nummern; Dubletten markieren; leere Einträge ignorieren; Gruppe speichern | nur Komma (`setup.html:783-787`) |
| Sitzfolge | Drag-and-drop in der Vorschau; „Zufällig mischen"; Sitznummer bleibt stabil sichtbar | Mischen (`setup.html:1042-1050`), kein Umsetzen |
| Akt/Rollen | Akt I–IV und Custom (`js/core/akte.js`); Vorschlag nach Spielerzahl; Chips mit Zähler; Obergrenzen wie heute (Werwolf 5, Dorfbewohner 10, Gebundene 6) | vorhanden (`setup.html:793-798`) |
| Prüfung | Summe = Spielerzahl; mindestens 1 Wolf; Pflichtpaare (Schwarze Witwe → Loki); Hinweise statt Blockade bei Geschmacksfragen; „Komplexität": Anzahl Nachtschritte, Anzahl Reaktionsrollen | nur Summe und Witwe/Loki |
| Verteilung | Zufällig (gesäter Zufall, im Spielstand gespeichert), manuell, gemischt | zufällig oder manuell (`setup.html:1103-1162`) |
| Rollen zeigen | Übergabe-Modus: großer Schutzschirm „Gib das Tablet an **Sitz 4 · Anna**" → Tippen+Halten zeigt Rolle → Loslassen verbirgt → nächster Sitz. Keine Zurück-Navigation zu fremden Rollen | Sequenz in `gh:1208-1250` ohne Halte-Schutz |
| Bereitschaft | Checkliste, Testton, Helligkeitsprobe, Start-Button „Erste Nacht beginnen" | fehlt |

### 3.2 Nacht

- Die App zeigt **immer genau einen aktiven Rollenschritt** in der Ansagekarte (Abschnitt 6). Die Nachtleiste zeigt Vergangenes (abgehakt), Aktuelles (hervorgehoben), Kommendes (gedimmt) und Übersprungenes (mit Grund, z. B. „blockiert durch Albtraumwolf").
- **Tote Rollen bleiben als Täuschungszeile wählbar** (heute: „🎭 Tarnung", `night:42-47`), damit die Runde nicht am Schweigen erkennt, wer tot ist. [E] Pro Runde einstellbar: „Tote Rollen weiter aufrufen".
- Zielwahl: erlaubte Sitze leuchten, gesperrte sind gedimmt; Tippen auf einen gesperrten Sitz zeigt den Grund.
- **Bestätigen wendet an.** Vorher ändert sich nichts am Zustand (Gegensatz zu heute, wo z. B. der Schutz beim Antippen verbraucht wird, `chunk:162`).
- Nacht-Check vor dem Morgen: „2 Schritte übersprungen, 1 Reaktion offen" mit Sprung zum Punkt.

### 3.3 Morgen

1. Die App löst die Nacht deterministisch auf.
2. Offene Reaktionen (Sensenträger, Besessener Wolf, Dämonischer Wolf, Rudelvater, Märtyrerin) werden als Warteschlange nacheinander abgefragt. Jede Karte zeigt, warum sie erscheint.
3. **Morgenbericht** mit zwei Spalten: *öffentlich verkünden* (Tote, öffentliche Hinweise wie Detektiv) und *nur für dich* (wer wen geschützt hat, warum jemand überlebte).

### 3.4 Tag

- Diskussionstimer mit Start/Pause/+30 s; läuft über App-Wechsel korrekt weiter (Zeit aus Uhr, nicht aus Ticks).
- Nominierung: Sitz antippen → „Nominieren". Liste der Nominierten sichtbar. Manipulator-Effekt greift (heute nur über Chip, `gh:429`).
- Entscheidung: heute direkte SL-Wahl (`night:421`). [E] MVP behält Direktwahl; optionale Stimmenzählung ist Produktfrage Q2 (`07`).
- Folgen der Hinrichtung werden wie am Morgen über die Reaktions-Warteschlange abgearbeitet.
- „Keine Hinrichtung heute" als expliziter Button (heute nur implizit durch Nachtstart).

### 3.5 Spielende

- Siegbanner mit **Auslöser** („Die Wölfe erreichen Gleichstand: 3 Wölfe gegen 3 Dorfbewohner").
- Korrektur möglich („Das war falsch": Undo vor den Sieg).
- Chronik: öffentliche Zusammenfassung und private SL-Chronik getrennt; Export als Text/Bild.
- „Gleiche Gruppe, neue Runde" behält Namen und optional Sitzfolge.

---

## 4. Screen-Landkarte und Navigation

```
                     ┌──────────┐
                     │  START   │──► Einstellungen (global)
                     └────┬─────┘
          Fortsetzen ─────┤───── Neue Runde
                          ▼
   ┌───────────── SETUP-ASSISTENT (linear, Zurück erlaubt) ──────────────┐
   │ Gruppe → Rollen → Verteilung → Rollen zeigen → Bereitschaft          │
   └──────────────────────────────┬───────────────────────────────────────┘
                                  ▼
   ┌────────────────────────── SPIEL-COCKPIT ────────────────────────────┐
   │ Modus Nacht | Morgen | Tag  (ein Screen, Zustand wechselt)           │
   │ Schubladen: Protokoll · Regeln/Rollen · Spieler-Detail · Menü        │
   │ Modale: Reaktion · Bestätigung kritischer Korrektur · Schutzschirm   │
   └──────────────────────────────┬───────────────────────────────────────┘
                                  ▼
                           SPIELENDE / CHRONIK ──► Neue Runde | Start
```

**Navigationsregeln [E]**

1. Im Cockpit gibt es **keinen Zurück-Button**, der die Runde verlässt. Verlassen nur über Menü mit Bestätigung; die Runde bleibt gespeichert.
2. Schubladen überdecken das Brett höchstens zu 40 % und schließen per Wischen oder Tippen außerhalb.
3. Modale nur für Entscheidungen, die den Ablauf blockieren (Reaktionen, destruktive Korrekturen). Informationen erscheinen in der Ansagekarte, nicht als Modal.
4. Android-Zurück-Taste: schließt oberste Schublade/Modal; im Cockpit ohne offene Ebene zeigt sie „Runde pausieren?".

### 4.1 Cockpit-Layout (Referenz 1280×800 dp, Querformat) [E]

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ☾ Nacht 2 · Schritt 4/11 · Das Orakel          ● gespeichert   ⏸  ☰         │ 56 dp Kopfzeile
├────────┬──────────────────────────────────────────────┬──────────────────────┤
│ Nacht- │                                              │  ANSAGEKARTE         │
│ leiste │            Sitzkreis (Ellipse)               │  Was ist passiert    │
│ (Rollen│        Token ≥ 56 dp, Namen immer lesbar     │  Sag jetzt           │
│  als   │        Sitznummer auf jedem Token            │  Tu jetzt            │
│ Liste) │                                              │  [ Primäraktion ]    │
│ 200 dp │                                              │  Überspringen · ↶    │ 360 dp
└────────┴──────────────────────────────────────────────┴──────────────────────┘
```

- Die Ansagekarte sitzt rechts (Rechtshänder); **Spiegelung für Linkshänder** in den Einstellungen.
- Die Nachtleiste ist einklappbar; eingeklappt zeigt sie nur Fortschritt „4/11".
- Bei 18+ Spielern schrumpft die Porträtfläche, nie die Namen (Namen unter 14 sp sind unzulässig; notfalls Kürzel + Nummer).

---

## 5. Tablet-Bedienregeln

### 5.1 Touch-Ziele [E]

| Element | Mindestgröße | Abstand | Begründung |
|---|---|---|---|
| Primäraktion (Bestätigen, Weiter) | 64 dp hoch, ≥ 200 dp breit | – | Wird im Dunkeln blind getroffen |
| Sekundäraktion (Überspringen, Abbrechen) | 48×48 dp | ≥ 16 dp zur Primäraktion | Verwechslungsschutz |
| Sitz-Token (Trefferfläche) | 56 dp, bei ≤ 12 Spielern 80 dp | Trefferflächen überlappen nicht | Kollisionsprüfung für Token **und** Namen (heute: `app/src/components/DomBoard.tsx`) |
| Icon-Buttons (Kopfzeile) | 48×48 dp | 8 dp | WCAG 2.2 2.5.8 (≥ 24 px) deutlich übertroffen, Komfortziel 48 aus Analyse 15.09. |

Heutige Tokens: `--touch-min: 44px`, `--touch-primary: 52px` (`css/tokens.css`) [B]. Godot-Ziel liegt bewusst darüber.

### 5.2 Gesten [E]

- **Antippen** wählt, **Bestätigen-Button** führt aus. Keine spielentscheidende Aktion allein durch Geste.
- **Langes Drücken** (500 ms) öffnet Spieler-Detail; immer auch per sichtbarem Button erreichbar.
- **Tippen+Halten** nur im Rollen-zeigen-Modus (Sicherheitsgeste).
- Doppeltippen wird entprellt: eine Bestätigung pro 400 ms, Button nach Tippen sofort deaktiviert bis der Kern antwortet.
- Kein Pinch-Zoom im Cockpit.

### 5.3 Lesbarkeit [E]

- Fließtext der Ansagen: mind. **20 sp**, Vorlesetext **24 sp**, Namen im Kreis mind. **16 sp** (Minimum 14 sp bei 24+ Spielern).
- Zwei Schriftrollen: Zierschrift (Cinzel) nur für Überschriften und Rollennamen; Lesetext in einer gut lesbaren Serifen- oder Humanist-Schrift. [E] IM Fell English ist für lange Texte bei schwachem Licht zu unruhig; Vorschlag in `05`, Abschnitt 2.3.
- Kontrast Text/Fläche ≥ 4,5:1 (WCAG AA), Statussymbole ≥ 3:1.
- Hintergrundbilder immer hinter einer ruhigen Fläche (≥ 85 % Deckung) bei Text.

### 5.4 Barrierefreiheit [E]

- **Status nie nur über Farbe:** Symbol + Form + Text (z. B. Schutz = Schild-Symbol + blauer Ring + Tooltip „Geschützt · Schutzengel · bis Morgen").
- Farbschwäche-Modus (Wolf/Dorf/Solo zusätzlich über Muster/Symbol).
- **Bewegung reduzieren:** ersetzt Kamerafahrten und Partikel durch Überblendungen ≤ 150 ms.
- Schriftgröße 90–130 % stufenlos.
- Vibration optional als Bestätigungsfeedback.
- Bildschirm bleibt während der Runde an (`DisplayServer.screen_set_keep_on`).
- **Dunkelraum-Modus:** abgesenkte Helligkeit, warmer Farbton, keine hellen Vollflächen, damit das Tablet im abgedunkelten Raum nicht blendet und keine Gesichter anstrahlt.

### 5.5 Robustheit am Tisch [E]

- Jede bestätigte Aktion ist in < 100 ms sichtbar quittiert und in < 500 ms gespeichert (Speicheranzeige in der Kopfzeile).
- App-Wechsel, Sperre, Drehung, Tastatur: kein Verlust offener Auswahl (offene Auswahl ist Teil des gespeicherten Zustands).
- Portrait: kein Sperrbildschirm wie heute (`OrientationGate.tsx`), sondern eine vereinfachte Übersicht (Phase, Ansagekarte, Liste statt Kreis).

---

## 6. Ansagekarte und Informationshierarchie

Die Ansagekarte beantwortet in fester Reihenfolge drei Fragen. Diese Struktur gilt für **jeden** Schritt: Nachtrolle, Morgen, Tag, Reaktion, Spielende.

| Zone | Frage | Inhalt | Gestaltung |
|---|---|---|---|
| **1 Was ist passiert** | Kontext | 1–3 Fakten, die für diesen Schritt relevant sind | klein, gedämpft, mit Symbolen |
| **2 Sag jetzt** | Moderation | Vorlesetext, direkt sprechbar | groß, Zitatstil, Zierinitial; „mehr" klappt Regeldetails auf |
| **3 Tu jetzt** | Handlung | Anweisung + gewählte Ziele + **Vorschau der Folge** | deutlich, mit Zähler „noch 1 Ziel" |
| Fußzeile | Weiter | Primäraktion, Sekundäraktionen | Primär immer an derselben Stelle |

### 6.1 Beispiele [E]

**Nachtschritt Das Orakel**

```
☾ NACHT 2 · 4/11 · DAS ORAKEL
Was ist passiert   Das Orakel lebt · nicht blockiert
Sag jetzt          „Orakel, erwache. Zeige auf die Person, deren Wesen du schauen willst."
Tu jetzt           Wähle 1 Spieler.   Gewählt: Sitz 7 · Ben
                   Ergebnis (zeige dem Orakel): WERWOLF
[ Gezeigt – weiter ]                            Überspringen · ↶
```

**Morgenbericht**

```
☀ MORGEN NACH NACHT 2
Was ist passiert   Nacht aufgelöst · 1 Reaktion erledigt (Sensenträger)
Sag jetzt          „Das Dorf erwacht. Anna und Carl sind in dieser Nacht gestorben."
                   Öffentlich: Detektiv-Hinweis „Ein Wolf sitzt links neben Dora."
Nur für dich       Bert wurde vom Schutzengel gerettet.
[ Tag beginnen ]
```

**Reaktion Besessener Wolf**

```
⚠ REAKTION 1 von 2 · BESESSENER WOLF
Was ist passiert   Der Besessene Wolf (Sitz 3 · Emil) ist gestorben. Es leben noch 7.
Sag jetzt          „Emil reißt im Sterben jemanden mit sich. Emil, zeige auf dein Opfer."
Tu jetzt           Wähle 1 lebenden Spieler.   Folge: Dieser Spieler stirbt sofort.
[ Bestätigen ]                                  ↶
```

### 6.2 Regeln für Texte [E]

- Vorlesetexte liegen als eigene Übersetzungsschlüssel pro Rolle vor (`role.<id>.call`, `role.<id>.sleep`), getrennt von Regeltext und Kurzanweisung.
- **Keine Substring-Übersetzung zur Laufzeit** (heute `js/core/i18n.js:716-1106`). Jeder Text hat einen Schlüssel mit Platzhaltern.
- Erfahrener Modus kürzt Zone 1 und 2, nie Zone 3.

---

## 7. Quality-of-Life-Funktionen, priorisiert

Priorität: **P0** = Tablet-MVP, **P1** = Version 1.0, **P2** = danach. Nutzen: Zeitersparnis bzw. vermiedene Fehler am Tisch.

| # | Funktion | Nutzen | Prio | Bezug heute |
|---|---|---|---|---|
| 1 | **Automatisches Speichern jeder bestätigten Aktion + Fortsetzen nach Absturz** | verhindert Rundenverlust | P0 | nur `localStorage`, stille Fehler |
| 2 | **Mehrstufiges Undo mit Klartext** („Rückgängig: Orakel-Blick auf Ben") und Redo | Korrekturen ohne Angst | P0 | 1 Schritt |
| 3 | **Geführter Nachtmodus mit Ansagekarte** | Kernversprechen | P0 | SL-Assistent (`night:586-733`), nicht persistent |
| 4 | **Aktionsvorschau vor Bestätigen** | verhindert Fehlklicks | P0 | fehlt |
| 5 | **Reaktions-Warteschlange** mit Zähler | Sonderfälle ohne Suchen | P0 | verstreute Callbacks |
| 6 | **Morgenbericht öffentlich/privat getrennt** | Geheimhaltung | P0 | Todeszusammenfassung (`js/ui/ui.js:470`) |
| 7 | **Übergabe-Modus für Rollen zeigen** | Geheimhaltung | P0 | Sequenz ohne Halte-Schutz |
| 8 | **Namen als Zeilenliste, gespeicherte Gruppen** | Setup < 2 min | P0 | nur Komma |
| 9 | **Unterbrechungszettel** beim Fortsetzen: „Nacht 2, Orakel, Ziel gewählt, Ergebnis noch nicht gezeigt" | Wiedereinstieg ≤ 10 s | P0 | fehlt |
| 10 | **Status-Tooltips mit Quelle und Dauer** | weniger Gedächtnislast | P1 | Marker ohne Quelle |
| 11 | **Aufmerksamkeitsliste** (max. 3 Punkte: „2 Totenkarten ungespielt", „Nekromant-Schild endet") | nichts vergessen | P1 | fehlt |
| 12 | **Totenkarten-Assistent**: Karte zeigen, Checkliste der manuellen Schritte, „erledigt" | 80 Karten beherrschbar | P1 | nur Anzeige |
| 13 | **Diskussionstimer** mit Uhr-Basis, Vibration bei Ablauf | Tagesrhythmus | P1 | Timer ohne Phasenbezug |
| 14 | **Nacht-Probe** vor Spielbeginn (welche Schritte, welche Reaktionen möglich) | Setup-Fehler finden | P1 | fehlt |
| 15 | **Erfahrener Modus** (kompakte Texte, weniger Bestätigungen außer destruktiven) | Tempo | P1 | fehlt |
| 16 | **Dunkelraum-Modus, Linkshänder-Spiegelung, Schriftgröße** | Komfort | P1 | fehlt |
| 17 | **Spielleiter-Korrektur mit Grund** (Rolle/Status ändern, protokolliert) | Transparenz | P1 | Popup-Chips umgehen Regeln (`gh:429`) |
| 18 | **Chronik und Export** | Abschluss, Gesprächsstoff | P1 | Log im RAM |
| 19 | **Lernrunde** mit Beispielspielern | Onboarding | P2 | fehlt |
| 20 | **Öffentliche Zweitanzeige** (Phase, Timer, freigegebene Infos) | Streaming, große Gruppen | P2 | fehlt |
| 21 | **Optionale Stimmenerfassung** | je nach Q2 | P1/P2 | fehlt |

---

## 8. Geheimhaltung [E]

- Das Cockpit ist per Definition geheim. Jede Ansicht, die Spieler sehen dürfen (Rollen zeigen, öffentliche Anzeige, Chronik-Export), ist ein **eigener Projektionsmodus** mit Positivliste der Felder.
- **Schutzschirm-Taste** (Kopfzeile ⏸) legt sofort ein neutrales Bild über alles; Rückkehr nur über Halten.
- Übergänge (App-Wechsel, Sperre) zeigen beim Zurückkehren den Schutzschirm, wenn ein Spieler-Modus aktiv war.
- Android: `FLAG_SECURE` optional, damit Rollen nicht in der App-Übersicht als Vorschaubild auftauchen.

---

## 9. Messbare Abnahme (übernommen und geschärft aus Analyse 15.09., Abschnitt 12)

| Ziel | Messung |
|---|---|
| Letzte bestätigte Aktion übersteht Prozessabbruch | Prozess killen, neu starten, Zustands-Hash vergleichen |
| Abbruch einer mehrstufigen Aktion hinterlässt keinen Teilzustand | Hash vor/nach Abbruch identisch |
| Undo/Redo über 20 Schritte reproduzierbar | Szenario-Test |
| Rückmeldung < 100 ms auf schwächstem Zielgerät | Profiler auf Referenz-Tablet (siehe `05`, Abschnitt 6) |
| Keine Namensüberlappung bei 12/18/24 Spielern auf 1024×768 und 1280×800 | Layout-Test mit langen und doppelten Namen |
| Neuer Leiter erkennt nächsten Schritt nach Unterbrechung ≤ 10 s | Pilot-Beobachtung |
| Setup mit gespeicherter Gruppe < 2 min | Pilot-Beobachtung |
