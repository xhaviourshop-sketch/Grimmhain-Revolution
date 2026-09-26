import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { AppShell } from "./AppShell";
import { installUiAssetCssVars } from "./assets/roleAssets";
import "./styles/tokens.css";

// UI chrome images as CSS custom properties (BASE_URL-aware, one place)
installUiAssetCssVars();

// iPad input hardening: block pinch-zoom gestures and double-tap zoom at the
// document level (the app is a fixed tablet surface, not a zoomable page).
// Panels keep scrolling via touch-action: pan-y in CSS.
document.addEventListener(
  "gesturestart",
  (e) => e.preventDefault(),
  { passive: false }
);
document.addEventListener(
  "dblclick",
  (e) => e.preventDefault(),
  { passive: false }
);

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <AppShell />
  </StrictMode>
);
