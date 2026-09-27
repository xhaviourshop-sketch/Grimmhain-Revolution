# Native Windows-Prüfung

Vom Repository-Wurzelordner in PowerShell. `GODOT_BIN` auf vorhandene Windows-Console-EXE setzen; nicht den Linux-Installer unter nativem Windows verwenden. `--version` gegen `godot/tools/godot-version.txt` prüfen.

```powershell
if (-not $env:GODOT_BIN -or -not (Test-Path -LiteralPath $env:GODOT_BIN)) {
    throw 'GODOT_BIN muss auf die vorhandene Godot-Console-EXE zeigen.'
}
& $env:GODOT_BIN --version
if ($LASTEXITCODE -ne 0) { throw 'Godot-Version nicht lesbar.' }
$importLog = Join-Path ([IO.Path]::GetTempPath()) ('grimmhain-import-' + [guid]::NewGuid() + '.log')
& $env:GODOT_BIN --headless --path godot --import *> $importLog
$importExit = $LASTEXITCODE
if ($importExit -ne 0 -or (Select-String -LiteralPath $importLog -Pattern 'SCRIPT ERROR|Parse Error|Failed to load script' -Quiet)) {
    Get-Content -LiteralPath $importLog -Tail 60
    throw "Import fehlgeschlagen; vollständiges Log: $importLog"
}
$testLog = Join-Path ([IO.Path]::GetTempPath()) ('grimmhain-tests-' + [guid]::NewGuid() + '.log')
& $env:GODOT_BIN --headless --path godot -s res://tests/run_tests.gd *> $testLog
$testExit = $LASTEXITCODE
Get-Content -LiteralPath $testLog -Tail 8
if ($testExit -ne 0 -or (Select-String -LiteralPath $testLog -Pattern 'SCRIPT ERROR|Parse Error|Failed to load script|^FAIL' -Quiet)) {
    Select-String -LiteralPath $testLog -Pattern 'SCRIPT ERROR|Parse Error|Failed to load script|^FAIL' -Context 0,5
    throw "Tests fehlgeschlagen; Exit $testExit; vollständiges Log: $testLog"
}
```

Gezielt: vor der Umleitung `-- --filter=replay` an den Runner-Aufruf anhängen. Filter trifft Dateinamen; ein Lauf ohne Tests zählt nicht als Erfolg. Logs bis Abschluss der Fehleranalyse behalten. Grafik und Touch benötigen separate Prüfungen.
