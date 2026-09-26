import type { CSSProperties } from "react";
import type { ActiveAction, DialogView, SeatView } from "../adapter/types";

const transparent: CSSProperties = { background: "transparent" };
const textBright: CSSProperties = { background: "transparent", color: "var(--text-bright)" };

interface Props {
  action: ActiveAction;
  seats: SeatView[];
  night: boolean;
  onConfirm: () => void;
}

/**
 * Aktionsfenster — React overlay centered inside the seat circle, framed by
 * the production action-frame artwork (night/day variant from the snapshot
 * phase). All text/controls stay React elements INSIDE the frame's visible
 * inner area — inner padding is defined once via the CSS vars
 * --action-pad-x / --action-pad-y on .action-panel (no scattered numbers).
 */
export function ActionPanel({ action, seats, night, onConfirm }: Props) {
  const target = action.targetSeatId != null ? seats.find((s) => s.id === action.targetSeatId) : null;

  return (
    <section
      className={"action-panel " + (night ? "action-panel--night" : "action-panel--day")}
      style={transparent}
      data-testid="action-panel"
    >
      <div className="action-panel-inner" style={transparent}>
        <h2 className="action-title" style={{ background: "transparent" }}>{action.displayName}</h2>
        <div className="action-instruction" style={transparent}>{action.instruction}</div>
        <p className="action-description" style={textBright}>{action.description}</p>
        <div className="action-target" style={transparent} data-testid="action-target">
          <span className="action-target-label" style={transparent}>Ziel</span>
          <span
            className={"action-target-value" + (target ? "" : " empty")}
            style={textBright}
          >
            {target ? `${target.name} (#${target.id})` : "— Spieler antippen —"}
          </span>
        </div>
        <button
          type="button"
          className="btn btn--art btn--art-confirm action-confirm"
          style={transparent}
          disabled={!action.confirmable}
          onClick={onConfirm}
          data-testid="action-confirm"
        >
          Bestätigen
        </button>
      </div>
    </section>
  );
}

/**
 * Mirrored legacy dialog — same framed slot as the ActionPanel. The button
 * texts come 1:1 from the legacy overlay; answering presses the REAL hidden
 * legacy button via the adapter (no rule logic on this side).
 */
export function DialogPanel({
  dialog,
  night,
  onPress
}: {
  dialog: DialogView;
  night: boolean;
  onPress: (index: number) => void;
}) {
  return (
    <section
      className={"action-panel " + (night ? "action-panel--night" : "action-panel--day")}
      style={transparent}
      data-testid="dialog-panel"
    >
      <div className="action-panel-inner" style={transparent}>
        <h2 className="action-title" style={{ background: "transparent" }}>{dialog.title || "Spielleitung"}</h2>
        {dialog.body && <p className="action-description" style={textBright}>{dialog.body}</p>}
        <div className="dialog-buttons" style={transparent}>
          {dialog.buttons.map((label, i) => (
            <button
              key={i}
              type="button"
              className={"btn" + (i === dialog.buttons.length - 1 ? " btn--art btn--art-confirm" : "")}
              style={transparent}
              onClick={() => onPress(i)}
              data-testid={`dialog-btn-${i}`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
