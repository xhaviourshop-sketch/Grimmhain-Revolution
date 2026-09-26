import { useLayoutEffect, useRef } from "react";
import type { Phase } from "../adapter/types";
import { LANG } from "../lang";

const BASE = import.meta.env.BASE_URL;
const UNDO_URL = `${BASE}assets/ui/btn-undo.png`;
const NEXT_URL = `${BASE}assets/ui/btn-next-step.png`;
const CLOCK_URL = `${BASE}assets/ui/clock-cartouche.webp`;

/** one-line label that shrinks to fit its box width (no overflow, no wrap) */
function FitLabel({
  text,
  className = "bottom-action-label",
  max = 15
}: {
  text: string;
  className?: string;
  max?: number;
}) {
  const ref = useRef<HTMLSpanElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const MIN = 7;
    let size = max;
    el.style.fontSize = `${size}px`;
    while (size > MIN && el.scrollWidth > el.clientWidth) {
      size -= 1;
      el.style.fontSize = `${size}px`;
    }
  }, [text, max]);
  return (
    <span ref={ref} className={className}>
      {text}
    </span>
  );
}

interface Props {
  phase: Phase;
  nightCount: number;
  /** mm:ss from the snapshot; non-mm:ss values render as a marked placeholder */
  timer: string;
  onUndo: () => void;
  onNext: () => void;
  /** switch day↔night (adapter.setPhase) */
  onTogglePhase: () => void;
  /** open the status-seal legend overlay */
  onLegend: () => void;
}

/** language-dependent labels (functionality unchanged) */
const STR = {
  de: {
    night: "Nacht",
    day: "Tag",
    toDay: "Tag",
    toNight: "Nacht",
    undo: "Rückgängig",
    next: "Nächster Schritt",
    timerHint: "Timer-Platzhalter",
    legend: "Legende"
  },
  en: {
    night: "Night",
    day: "Day",
    toDay: "Day",
    toNight: "Night",
    undo: "Undo",
    next: "Next step",
    timerHint: "timer placeholder",
    legend: "Legend"
  }
}[LANG];

const isMmSs = (t: string) => /^\d{1,2}:\d{2}$/.test(t);

/**
 * BottomBars — additive bottom HUD, gothic gold-on-dark styling.
 *  - left: ornamental status panel — night/day counter + timer + phase toggle
 *  - right: Rückgängig (adapter.undo) and Nächster Schritt (confirmNightAction)
 * Pure CSS look (no art); all actions flow through the adapter.
 */
export function BottomBars({ phase, nightCount, timer, onUndo, onNext, onTogglePhase, onLegend }: Props) {
  const timerValid = isMmSs(timer);
  const isNight = phase === "night";
  return (
    <>
      <div
        className={"bottom-status" + (isNight ? " is-night" : " is-day")}
        style={{ backgroundImage: `url(${CLOCK_URL})` }}
        data-testid="bottom-status"
      >
        {/* content sits in the cartouche's inner field (% of the asset) */}
        <div className="bottom-status-inner">
          <FitLabel
            className="bottom-status-night"
            max={16}
            text={`${isNight ? STR.night : STR.day} ${nightCount}`}
          />
          <FitLabel
            className={"bottom-status-timer" + (timerValid ? "" : " placeholder")}
            max={26}
            text={timerValid ? timer : "--:--"}
          />
          <button
            type="button"
            className="bottom-status-toggle"
            onClick={onTogglePhase}
            data-testid="phase-toggle"
          >
            <FitLabel
              className="bottom-status-toggle-text"
              max={13}
              text={`→ ${isNight ? STR.toDay : STR.toNight}`}
            />
          </button>
        </div>
      </div>

      {/* legend trigger — sits next to the cartouche (bottom-left), subtle UI pill */}
      <button
        type="button"
        className="legend-btn"
        onClick={onLegend}
        data-testid="legend-button"
      >
        <span className="legend-btn-mark" aria-hidden>✦</span>
        <span className="legend-btn-text">{STR.legend}</span>
      </button>

      <div className="bottom-actions" data-testid="bottom-actions">
        <button
          type="button"
          className="bottom-action-btn bottom-action-btn--undo"
          style={{ backgroundImage: `url(${UNDO_URL})` }}
          onClick={onUndo}
        >
          <FitLabel text={STR.undo} />
        </button>
        <button
          type="button"
          className="bottom-action-btn bottom-action-btn--next"
          style={{ backgroundImage: `url(${NEXT_URL})` }}
          onClick={onNext}
        >
          <FitLabel text={STR.next} />
        </button>
      </div>
    </>
  );
}
