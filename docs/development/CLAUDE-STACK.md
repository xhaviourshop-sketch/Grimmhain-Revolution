# Claude Code lokal: schlanker Grimmhain-Stack

Stand: 27.09.2026. Geprüfter lokaler Ausgangsstand: main, `5eb5f2a`; Claude Code 2.1.283. Die drei laufenden Cloud-Arbeiten sind nicht automatisch integriert. Dieser Bericht wird nicht beim Projektstart vollständig geladen.

## Ergänzung nach Nutzerfreigabe: sieben externe Fachskills

Projektlokal installiert: `verify-and-stop`, `godot-gdscript`, `godot-ui-control`, `godot-animation`, `godot-audio`, `performance-optimization`, `art-bible`. Root-CLAUDE.md ordnet ihnen konkrete Auslöser zu. Kein pauschales Laden aller Skills pro Aufgabe.

Quellen und SHA-256/Git-Blob-Hashes stehen in `skill-sources.lock.json`, mitgelieferte Lizenz-/Hinweistexte unter `skill-sources/`. Alle 13 übernommenen Dateien wurden gegen die fest gepinnten GitHub-Quellstände geprüft und unverändert übernommen. Die Fachskills enthalten keine ausführbaren Installationsskripte; enthaltene Codebeispiele wurden nicht ausgeführt. Es wurden keine Plugins, Hooks oder globalen Einstellungen ergänzt.

Die Skill-Header und vorhandenen lokalen Referenzpfade sind geprüft; tatsächliche automatische Auswahl in Claude wurde nicht mit einer kostenpflichtigen Modellanfrage getestet. In einer neuen lokalen Sitzung im Projekt sind die insgesamt elf Projekt-Skills vorgesehen. Globale Skills können zusätzlich erscheinen.

Für diese reine Skill-/Anweisungsinstallation wurde die Godot-Suite nicht erneut ausgeführt; die unten dokumentierte frühere erfolgreiche Prüfung bleibt als solche datiert. Spielcode wurde durch die Installation nicht verändert. Noch kein Commit oder Push.

## Eingerichtet

| Bestandteil | Aktivierung | Zweck |
|---|---|---|
| Root `CLAUDE.md` | Beim Start im Repository | Kurzer Godot-Arbeitsvertrag, Kontextdisziplin, gezielte Skill-Auswahl |
| `grimmhain-core` | Passende Regeln/GDScript/Save/Replay-Aufgabe | Determinismus, Regressionstests, Windows-Prüfung |
| `grimmhain-tablet-ui` | Godot-Oberfläche und visuelle Prüfung | Touch, Typografie, Layout, Geheimhaltung, echte Ansichtsprüfung |
| `grimmhain-assets` | Grafik/Audio/Medien | Konsistente kleine Produktionswellen, Herkunft, Qualität |
| `grimmhain-handoff` | Abschluss/Wiederaufnahme/Cloud-Übernahme | Kurze belegbare Übergabe statt erneuter Vollanalyse |

Die vier Skills liegen unter `.claude/skills/`, haben kurze Beschreibungen und erlauben normale automatische Auswahl. Kein Hintergrunddienst und keine dauerhaft laufenden Agenten. Vollständige Anleitungen werden erst bei passender Aufgabe geladen. Die automatische Auswahl ist Modellverhalten, keine deterministische Ausführungsgarantie.

## Vorhandenes sinnvoll wiederverwenden

Unter `~/.claude/skills/` sind bereits `systematic-debugging`, `writing-plans`, `executing-plans`, `docs-write-concisely`, `frontend-design`, `security-review` und Web-Test-Skills vorhanden. Keine weiteren Kopien installiert.

- Debugging bei echten Fehlern; Ursachenprüfung verhindert teure Reparaturschleifen.
- Planungs-Skills für komplexe Aufgaben, nicht jeden kleinen Fix. `executing-plans` empfiehlt selbst Delegation; die projektspezifische Vorgabe verlangt dafür ausdrücklichen Auftrag.
- Frontend-Design/Playwright nur für tatsächliche Web-Arbeit. Native Godot-Szenen brauchen native Prüfungen.
- Sicherheitsreview bei beauftragter Sicherheitsprüfung; vor späterem QR-/Online-/Account-System sinnvoll. Heute keine zusätzlichen Server oder Agenten einrichten.

## Recherche und Auswahl

Geprüfte Quellen:
- [Claude Code: Kosten und Kontext](https://code.claude.com/docs/en/costs): gezielt lesen, Kontext steuern, spezialisierte Anweisungen aus dem Startkontext auslagern. Lange Sitzungen und mehrere Agenten können erheblichen Mehrverbrauch verursachen.
- [Claude Code: Skills](https://code.claude.com/docs/en/skills): kurze Beschreibung zur Auswahl, voller Inhalt bei Aufruf; Projektablage `.claude/skills/<name>/SKILL.md`.
- [Allgemeiner Godot-Code-Skill](https://github.com/alexmeckes/godot-claude-skills/blob/main/skills/godot-code-gen/SKILL.md): enthält zahlreiche Bewegungs-/Kampfbeispiele ohne Grimmhains Regelarchitektur. Nicht installiert; gezielte eigene Skills passen besser.
- [Godot Agent](https://github.com/aigengame/godot-agent): interessanter Kandidat für spätere Editor-/Laufzeitautomation. Zusätzliche CLI/Integration heute nicht installiert oder evaluiert; kein belegter Tokengewinn für diesen Workflow.

Die eigenen Skills sind projektspezifische Arbeitsanweisungen, keine übernommenen Fremd-Skill-Pakete. Weder bessere Grafik noch Fehlerfreiheit oder eine feste Tokenersparnis sind allein durch Skills garantiert. Messbare Qualität entsteht durch ausgeführte Tests, visuelle Prüfung und Nutzertests.

## Befunde zur bisherigen Konfiguration

Die alte Projektanweisung beschrieb HTML/Capacitor/Tauri, einen nicht passenden `Werwolf/ROADMAP.md`-Startpfad und wiederholte Änderungsfreigaben. Diese aktiven Vorgaben wurden durch Godot-Anweisungen ersetzt. Historische Web-Dateien bleiben erhalten; der alte Arbeitsvertrag ist zusätzlich außerhalb des Repos gesichert:
`C:/Users/Marku/.claude/backups/grimmhain-stack-20260927/CLAUDE.before.md`.

Globale Konfiguration wurde nicht verändert. Die untersuchten Settings enthalten keine explizit aktivierten Plugins; vorhandene Plugin-Caches beweisen keine aktive Nutzung. Die globale Skill-Sammlung und synchrone Kopien können weiterhin Auswahlkontext beitragen. Der tatsächliche Umfang ist in einer frischen Claude-Sitzung mit `/context` zu prüfen, nicht aus Verzeichnisgrößen abzuleiten.

### Offener globaler Hook-Befund

`~/.claude/hooks/rule15-enforcer.js` ist für SessionStart/PostToolUse/Stop konfiguriert. Der Quellcode fordert bei geänderten Git-Signaturen Dokumentationsaktualisierung und kann den Abschluss blockieren. Seine Entscheidungsdatei-Kandidaten enthalten `DECISIONS.md`, aber nicht `DECISION-LOG.md`; dadurch kann trotz vorhandener Projektentscheidungen eine zusätzliche Datei entstehen. Ein tatsächlicher Claude-Hooklauf wurde hier nicht gestartet, daher keine Aussage, wie oft er in der aktiven Installation ausgeführt wird.

Empfehlung für einen getrennten, gezielten Konfigurationsauftrag: Mapping auf die vorhandenen Projektquellen ermöglichen und Erinnerungen entprellen. Nicht alle Hooks pauschal deaktivieren. Eine CLAUDE.md-Anweisung kann technische Hook-Ausgaben nicht abschalten.

## So lokal starten

1. Neue Claude-Code-Sitzung im Ordner `C:/Users/Marku/Desktop/Grimmhain/Grimmhain - Revolution` öffnen. Alte Sitzung nicht mit einer kompletten Kopie dieses Chatverlaufs füllen.
2. Mit `/context` den tatsächlichen Startkontext prüfen. Über `/skills` prüfen, ob die vier `grimmhain-*` Skills erkannt werden. Bei fehlendem Eintrag exakten Namen/Pfad prüfen; keine kostenpflichtige Testaufgabe nötig.
3. Konkreten Auftrag, Ausgangs-Commit und passende Übergabe nennen. Noch ausstehende Cloud-Berichte gemeinsam abgleichen lassen, bevor ihre Änderungen integriert werden.
4. Ein Agent als Standard. Parallele Sitzungen sparen Zeit, aber nicht automatisch Gesamttokens. Bei Parallelität getrennte Worktrees und klaren Dateibesitz verwenden.
5. Am Ende kurze Übergabe; bei neuem Thema neue Sitzung oder gezieltes `/compact`. Innerhalb zusammenhängender Arbeit Cache nicht durch ständige Neustarts verschwenden.
6. Über `/usage` Verbrauch vergleichen; API-Dollarangaben nicht mit tatsächlich verbrauchtem Abo-/Promoguthaben gleichsetzen. Zwei ähnlich große Arbeitspakete vergleichen, keine Prozentersparnis aus Textlänge behaupten.

Keine Modell-/Effort-, Billing- oder Berechtigungseinstellung verändert. Für komplexe Regeln/Debugging nicht blind Denkbudget reduzieren. Ein günstigeres Modell für einfache Textarbeit ist eine mögliche separate Entscheidung, keine Vorgabe für alles.

## Windows-Testweg

Am Prüftag gefundene EXE:
`C:/Users/Marku/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.

In PowerShell `GODOT_BIN` für die Sitzung darauf setzen. Den dokumentierten nativen Import-/Testablauf in `.claude/skills/grimmhain-core/windows-checks.md` verwenden. Keine globale Umgebungsvariable verändert, keine zweite Engine installiert. Der Ablauf bewahrt vollständige Logs und zeigt nur Zusammenfassung/Fehler im Kontext.

## Grenzen der Einrichtung

- Lokale Anweisungen/Skills, kein Git-Commit/Push und keine Änderung der laufenden Cloud-Sitzungen.
- Kein Spielcode geändert. Vorhandene Editoränderung an `godot/project.godot` erhalten.
- Keine neuen kostenpflichtigen Claude-Modellanfragen für die Einrichtung. Skill-Erkennung/automatische Auswahl muss in der nächsten interaktiven Sitzung beobachtet werden.

## Tatsächlich geprüft

- Vier Skill-Header (Name/Beschreibung) und verlinkte Projektpfade geprüft.
- Root-Anweisung von 7.232 auf 4.951 Zeichen gekürzt, rund 32 Prozent. Das ist keine Messung des gesamten Kontext- oder Tokenverbrauchs.
- Dokumentierten PowerShell-Codeblock direkt ausgeführt: Godot `4.7.2.stable.official.ed1daf0bf`, Import erfolgreich, 387 Tests, 0 fehlgeschlagen, 0 Testdateien nicht ladbar, Exit 0. Gilt für den lokalen Stand dieses Berichts, nicht noch ausstehende Cloud-Branches.
- `git diff --check` erfolgreich; Git meldet lediglich die vorhandene LF/CRLF-Konvertierungspolitik.
- SHA-256 von `godot/project.godot` vor/nach Prüfung identisch: `65D80861B9184ADF20490663C8EC17811459035EF4174B372B0392BD5ED07521`.
- Keine Grafik-/Geräteprüfung oder bezahlte Skill-Evaluation durchgeführt. Keine Qualitäts- oder Einsparungsbenchmark behauptet.
