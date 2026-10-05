---
name: grimmhain-merge
description: Use on explicit order to merge a Grimmhain feature branch into main without squash after a green full suite, then push and deploy.
---

# Merge nach main
1. `git status --short`, Branch und HEAD prüfen; nur eigene Änderungen. `git diff --check`.
2. Vollsuite einmal, leise, auf dem finalen Stand: `node tools/test-quiet` (inkl. Fuzz; Exit 0 und Summenzeile `0 fehlgeschlagen` nötig). Bei Rot: nur das Rote beheben, Suite wiederholen. Nicht grün: nicht mergen, Stand pushen, melden.
3. `node tools/check-godot-i18n.js` und bei Medien `node tools/check-asset-register.js`.
4. Branch pushen, `git checkout main`, `git pull --ff-only`, `git merge --no-ff <branch>` (nie Squash, nie Force-Push), `git push origin main`.
5. Deploy mit Skill `grimmhain-deploy`.
6. `PROGRESS.md`: Merge-Commit, Vollsuite-Ergebnis, Deploy.
