import type { PhaseInfo } from "../adapter/types";

interface Props {
  phase: PhaseInfo;
  canConfirm: boolean;
  onTogglePhase: () => void;
  onNextStep: () => void;
  onUndo: () => void;
}

/**
 * PhaseControls — bottom bar per reference layout:
 * left: phase chip + timer · right: Rückgängig + Nächster Schritt.
 */
export function PhaseControls({ phase, canConfirm, onTogglePhase, onNextStep, onUndo }: Props) {
  return (
    <footer className="phase-controls" data-testid="phase-controls">
      <div className="phase-controls-left">
        <button type="button" className="phase-chip" onClick={onTogglePhase} title="Phase wechseln">
          {phase.phase === "night" ? "🌙" : "☀️"} {phase.label}
        </button>
        <span className="phase-timer" aria-label="Timer">⏱ {phase.timer}</span>
      </div>
      <div className="phase-controls-right">
        <button type="button" className="btn btn--art btn--art-undo" onClick={onUndo} data-testid="undo-btn">
          Rückgängig
        </button>
        <button
          type="button"
          className="btn btn--art btn--art-next"
          onClick={onNextStep}
          disabled={!canConfirm}
          data-testid="next-step-btn"
        >
          Nächster Schritt
        </button>
      </div>
    </footer>
  );
}
