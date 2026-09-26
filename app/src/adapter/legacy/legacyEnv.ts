/**
 * Legacy runtime environment.
 *
 * The legacy scripts (js/core, js/ui) were written for game.html and expect
 * a handful of globals/DOM nodes that game.html's inline script used to
 * provide. This module recreates the MINIMUM of that environment inside the
 * React app — without modifying any legacy file:
 *
 *  - hidden DOM scaffold (#overlay/#mt/#mb/#mbtns, #pickbar/…, #order, …)
 *    the logic writes its dialogs and the night order into; the adapter
 *    mirrors them back out (domMirror.ts)
 *  - global helpers the inline script used to define ($, flash)
 *  - the global `state` (created via the legacy createState/migrateState)
 *  - post-load overrides: draw() becomes a pure change signal (the React
 *    shell renders the board itself), applyBg() becomes a no-op
 */

declare global {
  interface Window {
    state?: unknown;
    $?: (id: string) => HTMLElement | null;
    flash?: (sym: string) => void;
    draw?: () => void;
    applyBg?: (isDay: boolean) => void;
    save?: () => void;
    migrateState?: (s: unknown) => unknown;
    load?: () => unknown;
    ensureTotenkarten?: () => void;
    rebuildOrder?: () => void;
    onNightStart?: () => void;
    onDayStart?: () => void;
    onOrderClick?: (role: string) => void;
    undoOnce?: () => void;
    pickMode?: { onSeat: (seat: unknown) => void; allow?: (seat: unknown) => boolean } | null;
    endPick?: () => void;
    gameLog?: { entries: { t: number; icon: string; text: string }[] };
    getRoleName?: (id: string) => string;
    getRoleDescription?: (id: string) => string;
    __activeRole?: string | null;
    __legacyNotify?: () => void;
  }
}

const SCAFFOLD_ID = "legacy-bridge-dom";

/** Hidden nodes the legacy logic touches at runtime (all guarded reads in
 *  the legacy code tolerate the missing rest of game.html). */
const SCAFFOLD_HTML = `
  <div id="overlay" style="display:none"><h3 id="mt"></h3><div id="mb"></div><div id="mbtns"></div></div>
  <div id="pickbar" style="display:none"><span id="picktxt"></span><span id="pickhint"></span><button id="pickcancel"></button></div>
  <div id="order"></div>
  <div id="flash" style="display:none"><div id="flashSym"></div></div>
  <div id="gameLogPanel" style="display:none"><div id="gameLogBody"></div><span id="gameLogCount"></span></div>
`;

function buildScaffold(): HTMLElement {
  let host = document.getElementById(SCAFFOLD_ID);
  if (host) return host;
  host = document.createElement("div");
  host.id = SCAFFOLD_ID;
  // hidden but NOT display:none — the legacy code toggles inner display
  // values and reads them back; visibility+size keep it inert instead.
  host.style.cssText =
    "position:fixed;left:-10000px;top:0;width:1px;height:1px;overflow:hidden;visibility:hidden;pointer-events:none;";
  host.innerHTML = SCAFFOLD_HTML;
  document.body.appendChild(host);
  return host;
}

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = src;
    s.async = false; // preserve order
    s.onload = () => resolve();
    s.onerror = () => reject(new Error("Legacy-Script konnte nicht geladen werden: " + src));
    document.head.appendChild(s);
  });
}

let bootPromise: Promise<void> | null = null;

/**
 * Loads the legacy runtime exactly once (StrictMode-safe).
 * `notify` is invoked whenever the legacy logic signals a re-render
 * (every legacy draw()/save() call).
 */
export function bootLegacyRuntime(notify: () => void): Promise<void> {
  window.__legacyNotify = notify; // swappable on re-mount
  if (bootPromise) return bootPromise;

  bootPromise = (async () => {
    buildScaffold();

    // globals the game.html inline script used to provide
    window.$ = (id: string) => document.getElementById(id);
    window.flash = () => {
      /* visual flash is a board concern — handled by the React shell later */
    };

    const manifest: string[] = await fetch(
      `${import.meta.env.BASE_URL}legacy/manifest.json`
    ).then((r) => r.json());
    for (const file of manifest) {
      await loadScript(`${import.meta.env.BASE_URL}legacy/${file}`);
    }

    // options bridge: game.html-inline option actions (clearRolesNewRound,
    // hardReset, night music) copied verbatim into a React-owned classic script,
    // loaded AFTER the bundle so it shares the global scope. game.html untouched.
    await loadScript(`${import.meta.env.BASE_URL}legacy-bridge.js`);

    // Patch a missing legacy i18n key WITHOUT editing the vanilla file: the night
    // death summary calls t("noDead"), but the dictionary only defines
    // "noDeadYet", so t() returns the raw key "noDead" as the label. Provide it
    // (anzapfen). The vanilla source stays untouched.
    const i18n = (window as unknown as { I18N?: Record<string, Record<string, string>> }).I18N;
    if (i18n) {
      if (i18n.de && !i18n.de.noDead) i18n.de.noDead = "Niemand starb diese Nacht.";
      if (i18n.en && !i18n.en.noDead) i18n.en.noDead = "No one died this night.";
    }

    // global state (game.html inline used to do exactly this)
    const w = window as Window;
    if (!w.state && w.migrateState && w.load) {
      w.state = w.migrateState(w.load());
    }
    w.ensureTotenkarten?.();

    // post-load overrides — replace the DOM-rendering seams with signals
    w.draw = () => w.__legacyNotify?.();
    w.applyBg = () => {};

    // every legacy save() doubles as our change signal
    const origSave = w.save;
    if (origSave) {
      w.save = () => {
        origSave();
        w.__legacyNotify?.();
      };
    }

    // initial night order into the hidden #order
    try {
      w.rebuildOrder?.();
    } catch {
      /* tolerated: order rebuilds on the next legacy interaction */
    }
  })();

  return bootPromise;
}
