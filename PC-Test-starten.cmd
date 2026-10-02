@echo off
setlocal
rem Grimmhain PR #3: starts the Godot project as a game window (no editor).
rem Uses GODOT_BIN if set, otherwise the pinned Godot build in the Downloads folder.
rem "PC-Test-starten.cmd --check" only validates the paths and starts nothing.

set "PROJECT=%~dp0godot"
set "GODOT=%GODOT_BIN%"
if not defined GODOT set "GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
set "PIN="
for /f "usebackq delims=" %%v in ("%PROJECT%\tools\godot-version.txt") do if not defined PIN set "PIN=%%v"

if not exist "%PROJECT%\project.godot" (
    echo Fehler: Projekt nicht gefunden: "%PROJECT%\project.godot"
    if /i not "%~1"=="--check" pause
    exit /b 1
)
if not exist "%GODOT%" (
    echo Fehler: Godot nicht gefunden: "%GODOT%"
    echo Erwartet wird Godot %PIN% ohne Installation, siehe docs\ui\pc-test-pr3.md.
    if /i not "%~1"=="--check" pause
    exit /b 1
)
echo "%GODOT%" | findstr /i /c:"%PIN%" >nul
if errorlevel 1 (
    echo Fehler: "%GODOT%" ist nicht die gepinnte Version %PIN%.
    if /i not "%~1"=="--check" pause
    exit /b 1
)

if /i "%~1"=="--check" (
    echo OK: Godot %PIN%: "%GODOT%"
    echo OK: Projekt: "%PROJECT%"
    exit /b 0
)
start "" "%GODOT%" --path "%PROJECT%"
exit /b 0
