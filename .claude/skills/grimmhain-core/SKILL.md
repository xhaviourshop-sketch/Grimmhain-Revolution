---
name: grimmhain-core
description: Use for Grimmhain Godot rule logic, roles, commands, save/load, replay and core tests. Preserve existing product decisions and deterministic behavior.
---

# Regelkern
1. Betroffenen Handler, Tests und einschlägige Entscheidung lesen. API/Schemanummer aus aktuellem Checkout, nicht alten Berichten ableiten.
2. Abnahmekriterium als beobachtbares Verhalten festhalten. Nur tatsächlich offene Spielregeln erfragen, nicht den gesamten Rollenbestand erneut untersuchen.
3. Bei neuem Verhalten/Fehler passenden Test zuerst ergänzen und erwarteten Fehler prüfen. Dann kleinste konsistente Änderung. Tests nicht auf Implementierungsdetails reduzieren.
4. Typisiertes GDScript und vorhandene Befehle/Ereignisse verwenden. Keine Nodes, globalen Zufallsaufrufe, Uhrzeit-, UI-, Audio- oder Dateizugriffe im Regelkern.
5. Betroffene Invarianten prüfen: abgelehnte Befehle unverändert/ereignisfrei; Personen-ID; individuelle Ressourcen bei Mehrfachrollen; offene Prompts/Abbruch; Tod/Wiederbelebung; gespeicherter Zufall; Save/Load-Fortsetzung; Replay. Nicht jede Kombination für jeden Tippfehler neu testen.
6. Persistierte Änderungen gegen bestehende Schema-/Migrationsstrategie prüfen. Keine nächste Schemanummer vorab aus alter Planung übernehmen.
7. Während Entwicklung betroffene Tests filtern. Vor Abschluss einer Core-Verhaltensänderung vollständige Suite einmal ausführen. Fachliche Erwartungen nicht abschwächen, um grün zu werden.
8. Eigenen Diff auf Regelabweichung, Geheimnisleck und unnötige Abstraktion prüfen. Nur belegte Probleme melden.

Windows: [windows-checks.md](windows-checks.md). Linux/WSL: `godot/tests/run_all.sh`. Bei unerklärtem Fehler vorhandenen `systematic-debugging` gezielt nutzen.

Abschluss: Änderung/Regelquelle, Testbefehle/Exit-Codes, ungetestete Grenzen. Keine Geräte- oder UI-Abnahme aus headless Tests ableiten.
