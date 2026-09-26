# Grimmhain — App-Build & Installation (Capacitor)

Grimmhain ist als **Single-Device-Offline-App** mit [Capacitor](https://capacitorjs.com/) für
**iOS** und **Android** verpackt. Die Web-App bleibt unverändert; Capacitor wrappt sie nur.

- **appId:** `com.markusmuench.grimmhain`  ·  **appName:** `Grimmhain`
- **webDir:** `dist/` (schlanker Kopier-Build, kein Bundler)
- **Offline:** läuft komplett ohne Netz (alle Assets lokal, keine CDN-Fetches)

---

## 0. Der Build-Ablauf in Kürze

```bash
npm install            # einmalig: Capacitor-Tools holen
npm run build          # kopiert nur die Laufzeit-Assets nach dist/  (tools/copy-dist.js)
npx cap sync           # spiegelt dist/ in android/ und ios/
```

`npm run sync` macht `build` + `cap sync` in einem Schritt.
**Wichtig:** nach jeder Änderung an den Web-Dateien (HTML/JS/CSS/assets) erneut `npm run sync`.

> Offline-Hinweis: `tools/copy-dist.js` neutralisiert in der **Kopie** von `game.html` den
> Google-Fonts-Loader und erzwingt lokale Schrift (Cinzel). Die Quell-`game.html` bleibt
> unverändert. So wird zur Laufzeit garantiert **kein** Netz angefasst.

---

## 1. Voraussetzungen

| Ziel | Toolchain |
|---|---|
| Web-Build | Node.js (getestet mit Node 24) |
| **Android** | **JDK 17** + **Android Studio** (Android SDK Platform **36**, Build-Tools) |
| **iOS** | **macOS** + **Xcode** (Capacitor 8 nutzt Swift Package Manager, kein CocoaPods nötig) |

> Auf dem Windows-Repo-Rechner waren **JDK/Android-SDK nicht installiert**, daher wurde der
> Gradle-Build hier **nicht** ausgeführt. Projekt ist aber build-fertig (Gradle 8.14.3).

---

## 2. Android auf das Tablet bringen

### Variante A — Android Studio (empfohlen)
```bash
npm run android        # build + sync + öffnet das Projekt in Android Studio
# (oder manuell: npm run sync ; npx cap open android)
```
In Android Studio: Tablet per USB anschließen (USB-Debugging aktiv) → **Run ▶**. Studio baut,
installiert und startet die App.

### Variante B — Debug-APK + adb (ohne Studio-UI)
```bash
npm run sync
cd android
./gradlew assembleDebug          # Windows: gradlew.bat assembleDebug
# Ergebnis: android/app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```
Tablet: **Einstellungen → Über das Telefon → 7× auf Build-Nummer** (Entwickleroptionen),
dann **USB-Debugging** an. Bei „aus unbekannten Quellen“ Installation erlauben.

> Die Debug-APK ist groß (~500 MB, s. Abschnitt 5) — Sideload aufs Tablet ist ok.

---

## 3. iOS auf das iPad bringen (nur auf dem Mac)

Auf einem Mac mit Xcode:
```bash
npm install
npm run build
npx cap sync ios
npx cap open ios       # öffnet ios/App in Xcode
```
In Xcode:
1. Target **App** → **Signing & Capabilities** → eigenes **Team** wählen (Apple-ID genügt für
   Geräte-Installation; kein bezahlter Account für lokales Testen nötig).
2. iPad per Kabel verbinden, oben als Ziel auswählen.
3. **Run ▶**. Beim ersten Mal am iPad unter *Einstellungen → Allgemein → VPN & Geräteverwaltung*
   das Entwicklerzertifikat vertrauen.

> **Keine Signing-Credentials/Provisioning-Profile** liegen im Repo — die werden lokal in Xcode
> über die Apple-ID erzeugt.

---

## 4. App-Icon & Splash (noch offen)

Aktuell sind die **Capacitor-Default-Icons** gesetzt (Platzhalter). Für finale Grimmhain-Icons:
1. Lege ab: `resources/icon.png` (**1024×1024**, quadratisch) und `resources/splash.png` (**2732×2732**).
2. Generieren + einsync’en:
   ```bash
   npx capacitor-assets generate            # @capacitor/assets ist als devDependency installiert
   npx cap sync
   ```
Damit werden alle Plattform-Größen (Launcher-Icons, Splash) erzeugt und in android/ + ios/ gelegt.

---

## 5. Größe & Offline

- **Offline:** Keine Laufzeit-Netzzugriffe. Schriften (Cinzel, IM Fell English) liegen lokal in
  `assets/fonts/`; PixiJS ist lokal vendored (`js/vendor/pixi.min.js`).
- **Größe:** Die App ist ~**500 MB** (Karten-Art ~360 MB, `assets/sounds/Nachtmusik.mp3` ~83 MB).
  Für Sideload/Playtest unkritisch. Für eine **Store-Veröffentlichung** später Assets verkleinern
  (Karten als WebP, Musik komprimieren) — das ist eine separate Optimierungsaufgabe.
- `assets/sounds/Nachtmusik.mp3` ist in `.gitignore` (zu groß für Git) — auf dem Build-Rechner muss
  die Datei lokal vorhanden sein, damit sie ins Paket kommt.

---

## 6. Playtest-Gate

Erst wenn der **Tablet-Playtest grün** ist (eine Runde am Tisch durchspielen: Sitze, Nacht/Tag,
Tod, Sieg, Audio, beide Lagen), gilt der Build als verlässlich.
