/**
 * App language. Resolved ONCE at module load:
 *  - the vanilla preparation flow (legacy-setup/index.html) writes the chosen
 *    language to localStorage `grimmhain_lang`; the React board is entered via a
 *    full page load, so this read picks it up and the board matches the setup.
 *  - no value → German default.
 * Stays a compile-time-shaped const (evaluated at load), so the 5 LANG consumers
 * need no change. Flip to a real runtime setting only when a broader one lands.
 */
function detectLang(): "de" | "en" {
  try {
    const v = localStorage.getItem("grimmhain_lang");
    if (v === "de" || v === "en") return v;
  } catch {
    /* localStorage may be unavailable (file://, privacy mode) → default */
  }
  return "de";
}

export const LANG: "de" | "en" = detectLang();
