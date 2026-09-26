import type { LogEntry } from "../adapter/types";
import { LANG } from "../lang";

interface Props {
  open: boolean;
  entries: LogEntry[];
  onToggle: () => void;
}

const BASE = import.meta.env.BASE_URL;
// Language-dependent tab art (baked-in PROTOKOLL/PROTOCOL label). Each has its
// own aspect ratio → set inline so the full art shows uncropped.
const TAB = {
  de: { img: `${BASE}assets/ui/protocol-tab-de.png`, ratio: "333 / 1440", close: "Schließen" },
  en: { img: `${BASE}assets/ui/protocol-tab-en.png`, ratio: "465 / 1698", close: "Close" }
}[LANG];

/**
 * Protokoll — left-edge drawer. Closed: the language-dependent protocol-tab
 * edge button. Open: the protocol-panel art floats over the board (aspect-
 * locked); content is mapped onto the art's built-in regions:
 *   - top-right X graphic → invisible close hotspot (onToggle)
 *   - large dark field     → the log from adapter.getProtocol() (scrollable)
 * Read-only view; all interaction routes through the adapter. No window.*.
 */
/** Group the flat log into phase sections at the night/day marker entries
 *  (🌙 "Nacht N beginnt" / ☀️ "Tag beginnt"). The marker becomes the section
 *  header; everything else (incl. ✏️ manual edits and lynches) lists under it. */
type LogGroup = { title: string | null; items: LogEntry[] };
function groupByPhase(entries: LogEntry[]): LogGroup[] {
  const groups: LogGroup[] = [];
  for (const e of entries) {
    if (e.icon === "🌙" || e.icon === "☀️") {
      groups.push({ title: `${e.icon} ${e.text}`, items: [] });
    } else {
      if (!groups.length) groups.push({ title: null, items: [] });
      groups[groups.length - 1].items.push(e);
    }
  }
  return groups;
}

export function ProtocolDrawer({ open, entries, onToggle }: Props) {
  const groups = groupByPhase(entries);
  return (
    <aside
      className={"drawer drawer--left protocol-drawer" + (open ? " open" : "")}
      data-testid="protocol-drawer"
    >
      <button
        type="button"
        className="drawer-tab"
        onClick={onToggle}
        aria-expanded={open}
        style={{ backgroundImage: `url(${TAB.img})`, aspectRatio: TAB.ratio }}
      >
        <span className="drawer-tab-text">Protokoll</span>
        <span aria-hidden>{open ? "◀" : "▶"}</span>
      </button>

      <div className="drawer-body protocol-panel-body">
        {/* built-in X graphic (top-right) → invisible close hotspot */}
        <button
          type="button"
          className="protocol-x-hotspot"
          onClick={onToggle}
          aria-label={TAB.close}
          data-testid="protocol-close"
        />

        {/* large dark field → the protocol log, grouped by phase (scrollable) */}
        <div className="protocol-log drawer-scroll game-log-list" data-testid="protocol-log">
          {groups.map((grp, gi) => (
            <section className="protocol-group" key={gi}>
              {grp.title && <h4 className="protocol-group-title">{grp.title}</h4>}
              <ul className="protocol-group-list">
                {grp.items.map((e, i) => (
                  <li
                    key={i}
                    className={
                      "game-log-entry" +
                      (e.icon === "✏️" || e.icon === "↩️" ? " is-manual" : "")
                    }
                  >
                    <span className="game-log-time">{e.time}</span>
                    <span className="game-log-icon">{e.icon}</span>
                    <span className="game-log-text">{e.text}</span>
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      </div>
    </aside>
  );
}
