---
name: grimmhain-handoff
description: Use when finishing Grimmhain work, resuming after compaction or reconciling cloud reports with local branches. Preserve decisions and concise evidence.
---

# Übergabe ohne Vollanalyse
- Auftrag, Branch/HEAD und Diff abgleichen. Fremde Berichte sind Hinweise, keine lokal bestandenen Tests und keine Merge-Erlaubnis.
- Drei Cloud-Berichte mit jeweiligem HEAD/Basis separat erfassen. Überschneidungen und Abhängigkeiten benennen; nicht automatisch integrieren oder lokale Editoränderungen verwerfen.
- Bestehende Statusdatei verwenden, sonst kurze `PROJECT_STATE.md` anlegen. Stand aktualisieren statt Gesprächsverlauf anhängen. Belege per Pfad/Commit verlinken.
- Produktentscheidungen bleiben in `docs/masterplan/DECISION-LOG.md`; keine widersprechende zweite Sammlung. Empfehlungen/Defaults getrennt kennzeichnen.
- Beim Fortsetzen Status und relevante Diffs prüfen. Nur geänderte oder neu relevante Quellen lesen. Vorhandene Pläne nicht erneut erzeugen.

## Abschlussformat
1. Ziel und Ergebnis in wenigen Sätzen.
2. Branch, Ausgangs-/End-HEAD, uncommittete eigene/fremde Änderungen.
3. Dateien, wesentliche Schnittstellen und Regelentscheidungen.
4. Prüfungen: Befehl, Exit-Code/Ergebnis, geprüfter Stand; ausgelassene UI-/Gerätetests.
5. Echte Blocker/Risiken/Nutzerfragen.
6. Ein nächster Auftrag mit Abnahmekriterium.

Normalfall 250–500 Wörter; bei komplexen Problemen mehr. Keine 40-Punkte-Berichte oder vollständigen Testlogs ohne Bedarf. Regelrelevante Einschränkungen nie wegkürzen.

Vor `/compact`/Sitzungswechsel Zustand sichern. Nicht selbst kostenpflichtige Zweitsitzungen/Agententeams starten. Bericht ist keine Produktabnahme.
