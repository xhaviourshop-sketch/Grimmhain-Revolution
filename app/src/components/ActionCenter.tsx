import { useEffect, useLayoutEffect, useRef, useState } from "react";
import type { ActiveAction, NightOrderEntry, SeatView } from "../adapter/types";
import { LANG } from "../lang";

const BASE = import.meta.env.BASE_URL;
/** new metal frame — no baked text, so it is language-independent (DE/EN share
 *  the same image + slot positions; the role name/description stay dynamic). */
const frameUrl = `${BASE}assets/ui/actionframe.webp`;
const centerArtUrl = (faction: string) => `${BASE}assets/ui/center-${faction}.webp`;
const ARROW_LEFT = `${BASE}assets/ui/arrow-left.png`;
const ARROW_RIGHT = `${BASE}assets/ui/arrow-right.png`;

/** language-dependent static UI strings (role name + description stay dynamic
 *  from the adapter); same LANG pattern as the protocol tab. */
const STR = {
  de: {
    choose1: "Wähle einen Spieler",
    chooseN: (n: number) => `Wähle ${n} Spieler`,
    tapSeats: "— Sitze antippen —",
    left: (n: number) => `noch ${n}`,
    cont: "Weiter",
    confirm: "✓ Bestätigen",
    execute: "▶ Fähigkeit ausführen",
    executed: "✓ bereits ausgeführt",
    noInstr: "— Keine Instruktion —",
    more: "▼ mehr",
    less: "▲ weniger"
  },
  en: {
    choose1: "Choose a player",
    chooseN: (n: number) => `Choose ${n} players`,
    tapSeats: "— tap seats —",
    left: (n: number) => `${n} left`,
    cont: "Continue",
    confirm: "✓ Confirm",
    execute: "▶ Use ability",
    executed: "✓ already used",
    noInstr: "— no instruction —",
    more: "▼ more",
    less: "▲ less"
  }
}[LANG];

interface Props {
  /** the currently active night-order role (name + faction fallback) */
  entry: NightOrderEntry;
  /** instruction/description + interaction mode for the active role */
  action: ActiveAction | null;
  seats: SeatView[];
  /** id of the arrow-preview target (highlighted on the ring, not yet committed) */
  previewSeatId: number | null;
  /** move the arrow preview to a seat (local highlight; commit is a direct tap) */
  onPreview: (seatId: number) => void;
  /** commit the previewed target → adapter.selectPlayer = real legacy pm.onSeat
   *  (applies the effect). Multi-pick: commits one target per press. */
  onCommit: (seatId: number) => void;
  /** clear the current target(s) (adapter.cancelPick) */
  onClear: () => void;
  /** confirm an info step (adapter.confirmNightAction) */
  onConfirm: () => void;
  /** press an either/or choice (adapter.pressDialogButton) */
  onChoice: (index: number) => void;
  /** browse mode: open the viewed role's ability (adapter.goToNightStep). Only
   *  shown when no action is open — navigation and execution are separate. */
  onExecute: () => void;
  /** click on the portrait → show the active role's full card (display only) */
  onShowCard: () => void;
}

/**
 * ActionCenter — the board's center window on the landscape template
 * (action-template-{LANG}.webp). z-stack: faction art in the portrait window +
 * faction emblem in the emblem circle BEHIND the template, the template on top,
 * then the live text (role name / prompt / description) and the target arrows
 * OVER the template. Language picks the template + the static strings; the role
 * name and description come dynamically from the adapter. All interaction flows
 * through the adapter — no window.* and no rule logic.
 */
export function ActionCenter({
  entry,
  action,
  seats,
  previewSeatId,
  onPreview,
  onCommit,
  onClear,
  onConfirm,
  onChoice,
  onExecute,
  onShowCard
}: Props) {
  // browse vs execute: with no open action we show the viewed role + an explicit
  // "execute" button; only once executed do the pick/dialog controls appear.
  const browsing = !action;
  const mode = action?.mode ?? "target";
  const targetCount = action?.targetCount ?? 1;
  const pool = seats.filter((s) => !s.dead);
  const faction = action?.faction ?? entry.faction;
  const name = entry.displayName;

  // arrows move a LOCAL preview highlight (the ring token glows); committing is a
  // direct tap on the token (existing pick flow). Cycle relative to the preview.
  const cycle = (dir: -1 | 1) => {
    if (pool.length === 0) return;
    const cur = pool.findIndex((s) => s.id === previewSeatId);
    const base = cur >= 0 ? cur : dir > 0 ? -1 : 0;
    const next = (((base + dir) % pool.length) + pool.length) % pool.length;
    onPreview(pool[next].id);
  };

  // The role name is NO LONGER shown here — it lives in the Night Order at the
  // top (see NIGHT-ORDER-REWORK). It stays in the DOM only as a visually-hidden
  // label for accessibility; the freed space goes to the description.

  // D: the info-result text never scrolls — shrink it until the box fits. The
  // role DESCRIPTION is handled separately (readable clamp + expand, see #3), so
  // it is NOT shrunk into illegibility here.
  const acTextRef = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    const box = acTextRef.current;
    if (!box) return;
    const targets = box.querySelectorAll<HTMLElement>(".action-center-result");
    if (!targets.length) return;
    const MAX = 13;
    const MIN = 8;
    let size = MAX;
    const apply = (px: number) => targets.forEach((t) => (t.style.fontSize = `${px}px`));
    apply(size);
    while (size > MIN && box.scrollHeight > box.clientHeight) {
      size -= 1;
      apply(size);
    }
  });

  // prefer the role's read-aloud instruction; fall back to the action's short
  // imperative, then to a clear placeholder if truly none.
  const description = entry.instruction || action?.instruction || STR.noInstr;

  // #3: keep the description READABLE — clamp to a few lines at a legible size and
  // offer "mehr/weniger" when it is longer (details on demand), instead of
  // shrinking long read-aloud texts into tiny print.
  const descRef = useRef<HTMLParagraphElement>(null);
  const [descExpanded, setDescExpanded] = useState(false);
  const [descTruncated, setDescTruncated] = useState(false);
  // a new role/description always starts collapsed
  useEffect(() => {
    setDescExpanded(false);
  }, [description]);
  // detect whether the clamped text overflows (→ show the toggle)
  useLayoutEffect(() => {
    const el = descRef.current;
    if (!el) {
      setDescTruncated(false);
      return;
    }
    if (descExpanded) return; // measure only in the clamped state
    setDescTruncated(el.scrollHeight - el.clientHeight > 2);
  }, [description, descExpanded]);
  const prompt = targetCount === 1 ? STR.choose1 : STR.chooseN(targetCount);

  const chosen = (action?.chosenSeatIds ?? [])
    .map((id) => seats.find((s) => s.id === id))
    .filter((s): s is SeatView => !!s);
  const remaining = Math.max(0, targetCount - chosen.length);
  const isTarget = !browsing && mode === "target";

  return (
    <section className={`action-center faction-${faction}`} data-testid="action-center">
      <div className="ac-tpl">
        {/* BELOW the frame: faction/role portrait in the capsule window (left) —
            clicking it opens the active role's full card (display only). */}
        <button
          type="button"
          className="ac-art"
          style={{ backgroundImage: `url(${centerArtUrl(faction)})` }}
          data-testid="action-center-art"
          aria-label="Rollenkarte anzeigen"
          onClick={onShowCard}
        />
        {/* the metal frame on TOP (highest z) — its open windows reveal the
            content below; the metal naturally crops any overflow + keeps the
            gems/curtains free. pointer-events:none so taps reach the controls. */}
        <img className="ac-template" src={frameUrl} alt="" aria-hidden />

        {/* OVER the frame: role name + description + target controls (rectangle) */}
        <div className="ac-text" data-testid="action-center-text" ref={acTextRef}>
          {/* role name kept for a11y only (visually hidden) — shown in Night Order */}
          <h2 className="ac-name-sr" data-testid="action-center-title">
            {name}
          </h2>
          {/* acting-role header for choice/info dialogs whose title differs from the
              role in the Night Order — e.g. a dawn dialog (Märtyrerin reacts while the
              order still shows the wolf) or Hades' candle count ("Hades — 10 🕯️"). */}
          {(mode === "choice" || mode === "info") &&
            action?.instruction &&
            action.instruction !== name && (
              <p className="ac-acting" data-testid="action-center-acting">
                {action.instruction}
              </p>
            )}
          {!browsing && mode === "target" && (
            <p className="ac-prompt" data-testid="action-center-prompt">
              {prompt}
            </p>
          )}
          <p
            ref={descRef}
            className={"ac-desc" + (descExpanded ? " expanded" : "")}
            data-testid="action-center-desc"
          >
            {description}
          </p>
          {(descTruncated || descExpanded) && (
            <button
              type="button"
              className="ac-desc-toggle"
              onClick={() => setDescExpanded((e) => !e)}
              data-testid="action-center-desc-toggle"
            >
              {descExpanded ? STR.less : STR.more}
            </button>
          )}

          {/* multi-target progress (picking happens on the board) */}
          {!browsing && mode === "target" && targetCount > 1 && (
            <div className="ac-multi" data-testid="action-center-target">
              <span className={"ac-multi-names" + (chosen.length ? "" : " empty")}>
                {chosen.length ? chosen.map((s) => s.name).join(", ") : STR.tapSeats}
              </span>
              <span className="action-center-remaining" data-testid="action-center-remaining">
                {STR.left(remaining)}
              </span>
            </div>
          )}

          {/* target selection: arrows cycle the previewed seat (highlighted on the
              ring); ✕ clears. Commit is the bottom pill button. */}
          {isTarget && (
            <div className="ac-target-row">
              <button
                type="button"
                className="ac-arrow ac-arrow-left"
                onClick={() => cycle(-1)}
                aria-label="Vorheriges Ziel"
                data-testid="action-center-prev"
                style={{ backgroundImage: `url(${ARROW_LEFT})` }}
              />
              <button
                type="button"
                className="ac-arrow ac-arrow-right"
                onClick={() => cycle(1)}
                aria-label="Nächstes Ziel"
                data-testid="action-center-next"
                style={{ backgroundImage: `url(${ARROW_RIGHT})` }}
              />
              <button
                type="button"
                className="action-center-clear"
                onClick={onClear}
                aria-label="Ziel leeren"
                data-testid="action-center-clear"
              >
                ✕
              </button>
            </div>
          )}

          {/* the dialog's own question/context (e.g. "Block village abilities?",
              the Waldhexe victim's role) — without it a bare "Yes/No" is ambiguous */}
          {mode === "choice" && action?.description && (
            <p className="ac-question" data-testid="action-center-question">
              {action.description}
            </p>
          )}

          {/* either/or choice buttons */}
          {mode === "choice" && (
            <div className="action-center-foot" data-testid="action-center-choices">
              {(action?.choices ?? []).map((label, i) => (
                <button
                  key={i}
                  type="button"
                  className="action-center-choice"
                  onClick={() => onChoice(i)}
                  data-testid={`action-center-choice-${i}`}
                >
                  {label}
                </button>
              ))}
            </div>
          )}

          {/* info result (the acknowledge button lives in the bottom pill) */}
          {mode === "info" && action?.infoText && (
            <p className="action-center-result" data-testid="action-center-result">
              {action.infoText}
            </p>
          )}
        </div>

        {/* OVER the frame: bottom pill = primary action button per mode —
            execute (browse) · confirm (target) · continue (info). */}
        <div className="ac-button-pill">
          {browsing && (
            <button
              type="button"
              className="ac-execute"
              onClick={onExecute}
              disabled={entry.done}
              data-testid="action-center-execute"
            >
              {entry.done ? STR.executed : STR.execute}
            </button>
          )}
          {!browsing && mode === "target" && (
            <button
              type="button"
              className="ac-commit"
              onClick={() => previewSeatId != null && onCommit(previewSeatId)}
              disabled={previewSeatId == null}
              data-testid="action-center-commit"
            >
              {STR.confirm}
            </button>
          )}
          {mode === "info" && (
            <button
              type="button"
              className="ac-continue"
              onClick={() => (action?.choices?.length ? onChoice(0) : onConfirm())}
              data-testid="action-center-continue"
            >
              {STR.cont}
            </button>
          )}
        </div>
      </div>
    </section>
  );
}
