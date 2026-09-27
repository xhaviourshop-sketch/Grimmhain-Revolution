# skills.sh: Auswahl vor Installation

Recherche: 27.09.2026. Nachträglicher Status: Die sieben unten empfohlenen Skills wurden nach ausdrücklicher Nutzerfreigabe am selben Tag projektlokal installiert. Die ursprüngliche Auswahlbegründung bleibt erhalten. Quellstände und Datei-Hashes: `skill-sources.lock.json`; Aktivierungsregeln: Root-CLAUDE.md. Die vier bestehenden Grimmhain-Skills bleiben erhalten.

## Ergebnis

Empfehlung: sieben gezielte Ergänzungen, keine komplette Skill-Sammlung. Bei jeder Aufgabe gelten die kurzen Arbeitsregeln aus CLAUDE.md. Vollständige externe Skills werden nur beim passenden Aufgabentyp geladen. Ein Skill ist eine Anleitung, keine zusätzliche Engine, kein Bildgenerator und keine Qualitätsgarantie.

Untersucht wurden die Bereiche Kontext/Tokenkosten, Prüfung/Debugging/Review, Godot-Sprache, UI, Animation, Shader, Audio, Performance, Grafikproduktion und Export. Grundlage: skills.sh-Einträge, bei den engeren Kandidaten die originalen SKILL.md-Dateien und vorhandene Referenzdatei-Struktur. Keine vollständige Prüfung des gesamten Verzeichnisses, keine Ausführung fremden Beispielcodes und kein Einsparungsbenchmark.

## Empfohlene sieben Ergänzungen

### 1. verify-and-stop
- Quelle: [skills.sh](https://www.skills.sh/juliusbrussee/caveman/verify-and-stop), [Original](https://github.com/juliusbrussee/caveman/blob/main/skills/verify-and-stop/SKILL.md).
- Anlass: Abschlussprüfung eines Arbeitspakets oder ausdrücklicher Prüfauftrag.
- Nutzen: kleinsten ausreichenden Nachweis wählen, weiterhin gültige Ergebnisse berücksichtigen, nach erfüllten Kriterien aufhören. Verhindert unnötige Nacharbeiten und Testwiederholungen.
- Grenze: kein Ersatz für notwendige Tests. Gültige alte Ergebnisse müssen zum geprüften Stand passen. Kein vollständiger Caveman-Kommunikationsmodus erforderlich.
- Umfang: 704 Zeichen im untersuchten SKILL.md. Starkes Verhältnis von Anleitungslänge zu Nutzen.

### 2. godot-gdscript
- Quelle: [skills.sh](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-gdscript), [Original](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-gdscript/SKILL.md).
- Anlass: nichttriviale GDScript-Implementierung, Typ-/Lifecycle-/Signalfehler. Nicht bei Dokumentation, Assets oder jeder winzigen Textkorrektur.
- Nutzen: Godot-4.x-Syntax und typische Sprach-/Node-Fallen; ergänzt Grimmhains fachlichen Core-Skill.
- Grenze: Node-Beispiele nicht in den szenenfreien Regelkern übernehmen. Beispiele sind keine projektspezifisch getesteten Vorlagen.
- Umfang: etwa 5,3 k Zeichen, Referenz separat.

### 3. godot-ui-control
- Quelle: [skills.sh](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-ui-control), [Original](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-ui-control/SKILL.md).
- Anlass: neue/überarbeitete Godot-Ansicht, Container, Größenanpassung, Theme oder Fokus.
- Nutzen: konkrete Godot-UI-Technik hinter dem vorhandenen Tablet-Qualitäts-Skill.
- Grenze: erzeugt keine hochwertigen Porträts und prüft keine tatsächlichen Touch-Geräte. Bestehende Theme-/Navigationsarchitektur weiterverwenden.
- Umfang: etwa 5,8 k Zeichen, Referenz separat.

### 4. godot-animation
- Quelle: [skills.sh](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-animation), [Original](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-animation/SKILL.md).
- Anlass: Tag-/Nachtübergang, Porträt-/Dialoganimation, sichtbare Ereignisse, Tween/AnimationPlayer.
- Nutzen: passende Animationsmethode auswählen und typische Lifecycle-Probleme vermeiden.
- Grenze: für einen Dialog-Fade keinen Charakter-Animationsgraphen bauen. Animation bestätigt keine Spielregel; Tod/Geheimnisse nur gemäß freigegebenem Informationsfluss darstellen.
- Umfang: etwa 5,4 k Zeichen, Referenz separat.

### 5. godot-audio
- Quelle: [skills.sh](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-audio), [Original](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/godot/godot-audio/SKILL.md).
- Anlass: Audio-Busse, Lautstärke/Stumm, Musikübergänge, Sound-/Sprachausgabe implementieren.
- Nutzen: Godot-Knoten, Routing, Schleifen und Pegelsteuerung konkret erklären.
- Grenze: erzeugt keine Musik/Stimme. Enthält generischen kosmetischen Zufall; niemals den gespeicherten Regelzufall dafür verbrauchen oder Core-Determinismus ändern. Kein öffentlicher Sound auf geheimen Kernereignissen.
- Umfang: etwa 5,2 k Zeichen, Referenz separat.

### 6. performance-optimization
- Quelle: [skills.sh](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/performance-optimization), [Original](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/performance-optimization/SKILL.md).
- Anlass: reproduzierbares Ruckeln, Speicher-/Ladeproblem oder gezielter Tablet-Performanceauftrag.
- Nutzen: erst messen, Engpass bestimmen, klein korrigieren und erneut messen. Verhindert spekulative Architekturumbauten.
- Grenze: spart App-Ressourcen, nicht unmittelbar Claude-Tokens. Engine-neutrale Beispiele müssen auf Godot/GDScript angepasst werden; keine Unity-GC-Annahmen übertragen.
- Umfang: etwa 9 k Zeichen, deshalb kein Dauer-Skill.

### 7. art-bible
- Quelle: [skills.sh](https://www.skills.sh/mrcalderon3d/everything-game-dev-code/art-bible), [Original](https://github.com/mrcalderon3d/everything-game-dev-code/blob/main/skills/art-audio-content/art-bible/SKILL.md).
- Anlass: erste konsistente Grafikserie, ausdrückliche Stiländerung oder sichtbarer Stilbruch zwischen Assets.
- Nutzen: Bildsprache, Licht, Materialien und Lesbarkeit als überprüfbare gemeinsame Vorgaben festlegen.
- Grenze: vorhandenes BRIEFING-WAVE-1 und Produktionsdokumente gezielt ergänzen; keine zweite konkurrierende Art Bible schreiben. Genannte Related Agents/Commands sind Verweise auf dessen Ökosystem, keine hier vorhandenen Tools und kein Auftrag, sie zu installieren.
- Umfang: etwa 1,7 k Zeichen. Kein Generator/API-Abonnement enthalten.

## Aktivierung: nicht sieben Skills pro Auftrag

| Auftrag | Normaler Weg |
|---|---|
| Statusfrage, kurze Erklärung | CLAUDE.md, kein neuer externer Skill |
| neue Rolle | grimmhain-core; godot-gdscript bei relevanter Sprach-/Implementierungsarbeit |
| Setup-Bildschirm | grimmhain-tablet-ui plus godot-ui-control |
| Nachtanimation | grimmhain-tablet-ui plus godot-animation; UI-Skill nur bei zusätzlicher Layoutänderung |
| Tonsteuerung | grimmhain-assets plus godot-audio |
| Porträtserie | grimmhain-assets; art-bible für gemeinsame Stilfestlegung, nicht je Porträt neu |
| Tablet ruckelt | performance-optimization und gezielt betroffene Projektquelle |
| Übergabe/Abnahme | grimmhain-handoff; verify-and-stop für konkrete Abschlussprüfung |

Normalfall ein projektspezifischer Skill plus ein Fachskill, keine starre Obergrenze bei echten fachübergreifenden Aufgaben. Ein bereits geladener Skill wird nicht bei jedem Toolaufruf erneut gelesen. Skill-Auswahl bleibt modellgesteuert, nicht garantiert.

## Später oder nur bei konkretem Problem

| Kandidat | Entscheidung und Grund |
|---|---|
| [godot-shaders](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-shaders) | Später bei echten Shadern: Nebel, Leuchten, Auflösungseffekte. Renderer-/Tabletprüfung erforderlich. Für normale Tweens unnötig. Original gelesen. |
| [godot-gdscript-headless-testing](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-gdscript-headless-testing) | Bei Runner-/CI-Fehlern hilfreich. Grimmhain hat bereits einen Runner; keinen zweiten erzeugen. Original gelesen. |
| [godot-export](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/godot-export) | Beim ersten Windows/iPad/Android-Build. Allgemeine Exportanleitung ersetzt keine vollständige iOS-Signierungsprüfung. Original gelesen. |
| [audio-design](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/audio-design) | Erst bei bewusst beauftragter adaptiver Musik/Mischung. Aktuell starke Überlappung mit godot-audio und Medienbriefing. Original gelesen. |
| [game-ui-ux](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/game-ui-ux) | Gute Themen, aber Überschneidung mit Tablet-Skill/UI-Control; vorerst nicht zusätzlich. Beispielrechnung für Safe Areas nicht ungeprüft bei skalierten Viewports übernehmen. Original gelesen. |
| [game-feel](https://www.skills.sh/gamedev-skills/awesome-gamedev-agent-skills/game-feel) | Spätere gezielte Feedback-Politur. Actionspieltechniken wie Kameraschütteln/Hitstop passen nur eingeschränkt zum ruhigen Spielleiter-Assistenten. Verzeichniseintrag geprüft. |
| [context-compression](https://www.skills.sh/muratcankoylan/agent-skills-for-context-engineering/context-compression) | Nur bei konkreter Kontext-/Übergabediagnose. Original umfasst etwa 18 k Zeichen und behandelt auch eigene Agentensysteme. Unser Handoff reicht für den normalen Ablauf. |
| [requesting-code-review](https://www.skills.sh/obra/superpowers/requesting-code-review) | Bei kritischem Umbau und ausdrücklich gewünschtem separaten Reviewer. Automatische Reviewer nach jeder kleinen Aufgabe erhöhen Kosten. |

## Nicht zusätzlich installieren

- `systematic-debugging`, `writing-plans`, `executing-plans`, `docs-write-concisely`: bereits vorhanden. Kein zweiter Satz unter anderem Namen.
- [investigate-first](https://www.skills.sh/juliusbrussee/caveman/investigate-first): angenehm kurz, aber zusätzliche Debugging-Dopplung. Original gelesen.
- [caveman](https://www.skills.sh/juliusbrussee/caveman/caveman): komprimiert Antwortstil; eine beworbene Einsparungszahl ist keine nachgewiesene Reduktion deiner gesamten Kosten. Klare deutsche Anweisungen und vollständige Regeln sind wichtiger als Telegrammstil.
- [using-superpowers](https://www.skills.sh/obra/superpowers/using-superpowers) als pauschaler Pflicht-Einstieg: lädt Prozessregeln schon vor kleinen Antworten; hier unnötig neben gezieltem Routing.
- [verification-before-completion](https://www.skills.sh/obra/superpowers/verification-before-completion) parallel zu verify-and-stop: konkurrierende Verifikationsabläufe vermeiden. Belegpflicht bleibt in unseren Regeln erhalten.
- Komplettes Gamedev-Paket/Router: Grimmhains Engine ist bekannt; Physik-, Kampf-, Tilemap- und andere Engine-Skills sind nicht Teil dieses Auftrags.
- [generated-raster-asset-pipeline](https://www.skills.sh/mrcalderon3d/everything-game-dev-code/generated-raster-asset-pipeline): Original verlangt zusätzliches generated-assets.json und eigenen Prüfbefehl. Passt unverändert nicht zum existierenden Assetregister.
- [godot-asset-generator](https://www.skills.sh/jwynia/agent-skills/godot-asset-generator) und [imagegen](https://www.skills.sh/openai/skills/imagegen): mögliche spätere Generatoranbindung. Verzeichniseinträge geprüft, keine vollständige Werkzeug-/Kostenprüfung; Installation allein verschafft Claude keine Bildgenerierungsfähigkeit.
- Web-Audio-, React-/Next.js- und Browser-UI-Testpakete: falsche Laufzeit für die aktuelle native Godot-App.

## Grenzen und Vorschlag für die Installation nach Freigabe

1. Nur sieben einzeln ausgewählte Skillordner mit benötigten Referenzen projektlokal installieren, keine globale Komplettinstallation, keine zusätzlichen Plugins/Hooks/MCPs.
2. Festen Quellstand und Herkunft dokumentieren. Untersuchte Repository-Stände: gamedev-skills `d4b0e35550c55ae70bdfcab4ef5a0e94610438a9`, caveman `2fd153c67988e980fb0b2455c90832159a6a5a25`. Vor Installation Stand/Lizenz/mitgelieferte Dateien erneut gegen die Auswahl prüfen.
3. Bestehende Grimmhain-Skills mit den externen Fachskills abstimmen, keine doppelten vollständigen Checklisten. Kurze eindeutige Trigger in CLAUDE.md.
4. Beispiele nicht automatisch ausführen; sie sind allgemeine Orientierung und können unpassend oder fehlerhaft sein. Referenzen bedarfsgesteuert laden.
5. Nach Installation Skill-Erkennung in neuer lokaler Sitzung prüfen. Tatsächlichen Verbrauch über vergleichbare Arbeitspakete messen. Keine Prozentersparnis oder Fehlerfreiheit versprechen.

Wichtiger als ein weiterer Spar-Skill bleibt der im bisherigen Setup-Bericht dokumentierte globale Dokumentations-Hook: Er kann zusätzliche Dokumentationsaufforderungen erzeugen. Dieser Auftrag ändert ihn nicht.
