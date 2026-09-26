# Grimmhain · Godot-Projekt

Phase 1 des Masterplans: headless Regelkern. Noch keine UI, keine Assets.

## Engine-Version (gepinnt)

| Feld | Wert |
|---|---|
| Version | **Godot 4.7.2-stable**, offizieller Build `4.7.2.stable.official.ed1daf0bf` |
| Sprache | GDScript, statisch typisiert (`untyped_declaration` = Fehler) |
| Renderer | Compatibility (`gl_compatibility`), für den Kern irrelevant |
| Pin | `tools/godot-version.txt`, SHA-512 in `tools/install_godot.sh` |

## Tests ausführen

```bash
godot/tests/run_all.sh
```
