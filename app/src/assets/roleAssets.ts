const BASE = import.meta.env.BASE_URL;

/** UI chrome images (React/CSS) — exposed as CSS custom properties so the
 *  stylesheet stays free of BASE_URL-dependent paths. One central place. */
const UI_ASSET_VARS: Record<string, string> = {
  "--asset-nightorder-bar": "nightorder-bar-frame.png",
  "--asset-nightorder-slot-inactive": "nightorder-slot-inactive.png",
  "--asset-nightorder-slot-active": "nightorder-slot-active.png",
  "--asset-nightorder-slot-done": "nightorder-slot-done.png",
  "--asset-arrow-left": "arrow-left.png",
  "--asset-arrow-right": "arrow-right.png",
  "--asset-action-frame-day": "action-frame-day.png",
  "--asset-action-frame-night": "action-frame-night.png",
  "--asset-btn-confirm": "btn-confirm.png",
  "--asset-btn-next-step": "btn-next-step.png",
  "--asset-btn-undo": "btn-undo.png",
  "--asset-protocol-panel": "protocol-panel.png",
  "--asset-options-tab": "options-tab.png",
  "--asset-options-panel": "options-panel.png",
  "--asset-tooltip-frame": "tooltip-frame.png"
};

export function installUiAssetCssVars(): void {
  const root = document.documentElement.style;
  for (const [varName, file] of Object.entries(UI_ASSET_VARS)) {
    // Resolve to an ABSOLUTE url against the document. The vars are consumed
    // inside the BUNDLED stylesheet (/assets/index.css); a relative path
    // (base:"./" → "./assets/ui/x") would otherwise resolve against the CSS
    // file's folder (/assets/) and double to /assets/assets/ui/x (404).
    // new URL against document.baseURI stays correct for http AND file://.
    const url = new URL(`${BASE}assets/ui/${file}`, document.baseURI).href;
    root.setProperty(varName, `url("${url}")`);
  }
}
