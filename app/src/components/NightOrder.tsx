import { useLayoutEffect, useRef } from "react";
import type { NightOrderEntry } from "../adapter/types";

interface Props {
  entries: NightOrderEntry[];
  /** index of the highlighted (viewed) role — a LOCAL browse cursor, decoupled
   *  from the legacy "active". Pure navigation never opens an action. */
  highlightIndex: number;
  /** move the browse cursor to a role (arrows). Never blocked. */
  onView: (index: number) => void;
  /** disable navigation while an action is open (resolve/cancel it first). */
  navDisabled?: boolean;
}

/**
 * Nachtreihenfolge-Leiste. Zeigt NUR die aktuell ausgewählte Rolle: ein großer,
 * vollständiger Rollenname mittig im verzierten Rahmen, flankiert von Pfeilen
 * zum Blättern, plus ein kleiner Fortschritt (3 / 18). Keine Chip-Reihe mehr —
 * dadurch kollidieren bei großen Runden keine Namen und es bleibt ruhig.
 *
 * Navigation und Ausführung sind GETRENNT: die Pfeile bewegen nur den lokalen
 * Browse-Cursor (highlightIndex). Während eine Aktion offen ist (navDisabled),
 * sind die Pfeile gesperrt. Zustand der aktuellen Rolle:
 *   - offen   → Name leuchtet gold
 *   - erledigt → Name gedimmt + kleines ✓
 *   - aktiv (Fähigkeit offen) → stärkerer Lichtschein in Faktionsfarbe
 */
export function NightOrder({ entries, highlightIndex, onView, navDisabled = false }: Props) {
  const hi = Math.max(0, Math.min(highlightIndex, entries.length - 1));
  const current = entries[hi];

  const goPrev = () => {
    if (!navDisabled && hi > 0) onView(hi - 1);
  };
  const goNext = () => {
    if (!navDisabled && hi < entries.length - 1) onView(hi + 1);
  };
  const canPrev = !navDisabled && hi > 0;
  const canNext = !navDisabled && hi < entries.length - 1;

  // fit-to-width: shrink the name until it sits on ONE line (never cut off while
  // there is room, never overflow the frame). Re-runs on every role change.
  const nameRef = useRef<HTMLSpanElement>(null);
  const displayName = current?.displayName ?? "";
  useLayoutEffect(() => {
    const el = nameRef.current;
    if (!el) return;
    const MAX = 40;
    const MIN = 16;
    let size = MAX;
    el.style.fontSize = `${size}px`;
    while (size > MIN && el.scrollWidth > el.clientWidth) {
      size -= 1;
      el.style.fontSize = `${size}px`;
    }
  }, [displayName]);

  if (!current) return null;

  const stateClass = navDisabled ? "is-active" : current.done ? "is-done" : "is-open";

  return (
    <nav className="night-order" data-testid="night-order" aria-label="Nachtreihenfolge">
      <div className="night-order-title">Nachtreihenfolge</div>
      <div className="night-order-row">
        <button
          type="button"
          className="night-order-arrow night-order-arrow--left"
          onClick={goPrev}
          disabled={!canPrev}
          aria-label="Vorherige Rolle"
        />
        <div className={`night-order-current faction-${current.faction} ${stateClass}`}>
          <span
            ref={nameRef}
            className="night-order-name"
            data-testid="night-order-name"
            title={current.displayName}
          >
            {current.displayName}
            {current.done && (
              <span className="night-order-done-mark" aria-hidden>
                {" "}
                ✓
              </span>
            )}
          </span>
          <span className="night-order-progress" aria-hidden>
            {hi + 1} / {entries.length}
          </span>
        </div>
        <button
          type="button"
          className="night-order-arrow night-order-arrow--right"
          onClick={goNext}
          disabled={!canNext}
          aria-label="Nächste Rolle"
        />
      </div>
    </nav>
  );
}
