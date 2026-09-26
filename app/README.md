# Grimmhain — React-Migrations-Shell (Phase 0)

Technische Tablet-Shell für die schrittweise Migration des Spielleiter-Interfaces
auf React + TypeScript + Vite. **Nur Platzhalter — keine finale Gestaltung, keine
Spiellogik.** Die bestehende App im Repo-Root bleibt unverändert lauffähig.

## Starten

```bash
cd app
npm install
npm run dev        # http://localhost:5183
npm run build      # tsc --noEmit + vite build → app/dist
```

Testansichten: Toolbar-Buttons **12 / 18 / 24 Spieler** oder `?players=18` in der URL.

## Architektur

| Schicht | Technik | Inhalt |
|---|---|---|
| `src/pixi/` | PixiJS 7.4.3 (wie Legacy-Vendor) | **Ausschließlich** Dorfplatz + Spielertokens. `VillageBoard` ist isoliert: eigene PIXI.Application, liest nur das `BoardViewModel`-Prop, meldet Taps nach oben |
| `src/components/` | React | Nachtleiste, Aktionsfenster, Protokoll, Optionen, Tablet-Gate |
| `src/adapter/` | TypeScript-Interfaces | **Adaptergrenze.** Die Shell kennt die Spiellogik nur über `GameAdapter`. Phase 0: `mockAdapter`. Später: `legacyAdapter` als dünner Durchreicher zu `js/core` + `js/ui/field-viewmodel.js` — die Legacy-Logik wird dabei NICHT neu geschrieben |
| `src/pixi/boardLayout.ts` | pure TS | Sitzpositionen, 1:1-Port von `computeGeometry()` aus game.html (reine Layout-Mathematik) |

## Zielgeräte

Nur Tablets, nur Landscape: iPad 4:3 (z.B. 1024×768) und Android 16:10
(z.B. 1280×800). `OrientationGate` blockt Portrait und Viewports < 900×600.
Keine Smartphone-Unterstützung.

## Capacitor

Die Root-`capacitor.config.ts` zeigt weiterhin auf `dist` (alte App) und bleibt
während der Migration unangetastet. Wenn die Migration die alte App ersetzt:
`webDir` auf `app/dist` umstellen und `npm run build && npx cap sync` aus dem
Repo-Root fahren. Bis dahin läuft die neue Shell im Browser (`npm run dev`).

## Nächste Migrationsphasen (Ausblick)

1. `legacyAdapter` anbinden (Scripts laden, `getFieldViewModel()` durchreichen)
2. Nachtleiste/Aktionsfenster auf echte `onOrderClick`-Flows mappen
3. Setup-Flow (Namen/Akte/Rollen) als React-Screens
4. Gestaltung (Cinzel/IM Fell, echte Assets) — erst nach stabiler Shell
