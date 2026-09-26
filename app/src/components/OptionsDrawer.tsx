interface Props {
  open: boolean;
  onToggle: () => void;
  /** seat count shown next to "+ Sitzkreis" */
  seatCount: number;
  /** add one seat to the table (adapter.setSeatCount → legacy resizeSeats) */
  onAddSeat: () => void;
  /** start a fresh round via the canonical vanilla preparation flow (navigation) */
  onNewGame: () => void;
  /** clear all roles, fresh day 1, keep seats (adapter.clearRoles) */
  onClearRoles: () => void;
  /** hard reset to a fresh state for the current seat count (adapter.hardReset) */
  onHardReset: () => void;
  /** toggle night music on/off */
  onToggleNightMusic: () => void;
  /** back to the main menu / leave the game (navigation) */
  onMainMenu: () => void;
  onQuit: () => void;
}

// The app has no language setting yet → default German, English strings ready
// so the switch is trivial once a setting exists (replace LANG with it).
const LANG: "de" | "en" = "de";
const STRINGS = {
  de: {
    menu: "Hauptmenü",
    quit: "Spiel verlassen",
    close: "Schließen",
    addSeat: "+ Sitzkreis",
    newGame: "Neues Spiel",
    seats: "Sitze",
    clearRoles: "Rollen leeren",
    hardReset: "Hard-Reset",
    nightMusic: "Nachtmusik",
    confirmClear: "Alle Rollen leeren und neue Runde (Tag 1)?",
    confirmReset: "Hard-Reset: komplette Runde zurücksetzen?"
  },
  en: {
    menu: "Menu",
    quit: "Quit Game",
    close: "Close",
    addSeat: "+ Seat",
    newGame: "New Game",
    seats: "Seats",
    clearRoles: "Clear roles",
    hardReset: "Hard reset",
    nightMusic: "Night music",
    confirmClear: "Clear all roles and start a new round (Day 1)?",
    confirmReset: "Hard reset: wipe the entire round?"
  }
} as const;
const T = STRINGS[LANG];

/**
 * Optionen — right-edge drawer. Closed: the options-tab edge button. Open: the
 * options-panel art floats over the board (aspect-locked); content is mapped
 * onto the art's built-in regions:
 *   - top-right X graphic → invisible close hotspot (onToggle)
 *   - large dark field     → toggles (Nachtmusik / Rollen-Tooltips)
 *   - upper dark slot      → "Hauptmenü" button
 *   - lower red slot       → "Spiel verlassen" button
 * All state changes route through the adapter (onToggle). No window.*.
 */
export function OptionsDrawer({
  open,
  onToggle,
  seatCount,
  onAddSeat,
  onNewGame,
  onClearRoles,
  onHardReset,
  onToggleNightMusic,
  onMainMenu,
  onQuit
}: Props) {
  const confirmClear = () => {
    if (window.confirm(T.confirmClear)) onClearRoles();
  };
  const confirmReset = () => {
    if (window.confirm(T.confirmReset)) onHardReset();
  };
  return (
    <aside
      className={"drawer drawer--right options-drawer" + (open ? " open" : "")}
      data-testid="options-drawer"
    >
      <button type="button" className="drawer-tab" onClick={onToggle} aria-expanded={open}>
        <span className="drawer-tab-text">Optionen</span>
        <span aria-hidden>{open ? "▶" : "◀"}</span>
      </button>

      <div className="drawer-body options-panel-body">
        {/* built-in X graphic (top-right) → invisible close hotspot */}
        <button
          type="button"
          className="options-x-hotspot"
          onClick={onToggle}
          aria-label={T.close}
          data-testid="options-close"
        />

        {/* large dark field → adapter-backed actions */}
        <div className="options-field">
          <button
            type="button"
            className="options-action"
            onClick={onAddSeat}
            data-testid="options-add-seat"
          >
            {T.addSeat} <span className="options-action-meta">({T.seats}: {seatCount})</span>
          </button>
          <button
            type="button"
            className="options-action"
            onClick={onNewGame}
            data-testid="options-new-game"
          >
            {T.newGame}
          </button>
          <button
            type="button"
            className="options-action"
            onClick={confirmClear}
            data-testid="options-clear-roles"
          >
            {T.clearRoles}
          </button>
          <button
            type="button"
            className="options-action"
            onClick={confirmReset}
            data-testid="options-hard-reset"
          >
            {T.hardReset}
          </button>
          <button
            type="button"
            className="options-action"
            onClick={onToggleNightMusic}
            data-testid="options-night-music"
          >
            {T.nightMusic}
          </button>
        </div>

        {/* upper dark slot → Hauptmenü */}
        <button
          type="button"
          className="options-slot options-slot--menu"
          onClick={onMainMenu}
          data-testid="options-menu"
        >
          {T.menu}
        </button>

        {/* lower red slot → Spiel verlassen */}
        <button
          type="button"
          className="options-slot options-slot--quit"
          onClick={onQuit}
          data-testid="options-quit"
        >
          {T.quit}
        </button>
      </div>
    </aside>
  );
}
