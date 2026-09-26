import { useEffect, useRef, useState } from "react";
import type { GameAdapter } from "../adapter/GameAdapter";
import type { Faction } from "../adapter/types";
import { createLegacyAdapter } from "../adapter/legacy/legacyAdapter";
import { DomBoard } from "../components/DomBoard";
import { NightOrder } from "../components/NightOrder";
import { FactionScale } from "../components/FactionScale";
import { PlayerEditor } from "../components/PlayerEditor";
import { BottomBars } from "../components/BottomBars";
import { ActionCenter } from "../components/ActionCenter";
import { ActionPanel, DialogPanel } from "../components/ActionPanel";
import { ProtocolDrawer } from "../components/ProtocolDrawer";
import { OptionsDrawer } from "../components/OptionsDrawer";
import { MarkerLegend } from "../components/MarkerLegend";
import { PhaseControls } from "../components/PhaseControls";
import { LANG } from "../lang";
import { roleCardUrl } from "../roleCard";

const BASE = import.meta.env.BASE_URL;
const LYNCH_URL = `${BASE}assets/ui/Lynch_${LANG === "de" ? "DE" : "EN"}.webp`;

/** label + faction accent for the win banner (winner = legacy state.once.TeamWinner). */
function winnerInfo(winner: string): { text: string; faction: "dorf" | "wolf" | "solo" } {
  if (winner === "village")
    return { text: LANG === "de" ? "Das Dorf gewinnt" : "The village wins", faction: "dorf" };
  if (winner === "wolves")
    return { text: LANG === "de" ? "Die Werwölfe gewinnen" : "The werewolves win", faction: "wolf" };
  const role = winner.replace(/^solo_/, "");
  return { text: (LANG === "de" ? `${role} gewinnt` : `${role} wins`), faction: "solo" };
}

const LYNCH_LABEL = LANG === "de" ? "Lynchen" : "Lynch";

/** The morning-summary dialog TITLE is built in German in the legacy engine
 *  ("☀️ Nacht N — Morgengrauen") and is mirrored into React, bypassing the legacy
 *  runtime translator. Localize that one title in EN mode (additive, no engine
 *  edit); other dialog titles pass through unchanged. */
const localizeDialogTitle = (t: string): string =>
  LANG === "en" && t.includes("Morgengrauen")
    ? t.replace("Nacht", "Night").replace("Morgengrauen", "Dawn")
    : t;

/**
 * GameScreen — main play screen per reference layout (Spielfeld.png).
 * All data flows through the GameAdapter boundary, bound to the unchanged
 * vanilla game logic by the LegacyGameAdapter. One single run path.
 */
export function GameScreen() {
  const [adapter, setAdapter] = useState<GameAdapter | null>(null);
  const [bootError, setBootError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setAdapter(null);
    setBootError(null);
    createLegacyAdapter()
      .then((a) => {
        if (!cancelled) setAdapter(a);
      })
      .catch((e) => {
        if (!cancelled) setBootError(String(e));
      });
    return () => {
      cancelled = true;
    };
  }, []);

  // arrow-preview target (local highlight on the ring). Cleared on every adapter
  // notify so it never lingers across a role/pick change; local cycling does not
  // notify, so the preview persists while stepping with the arrows.
  const [previewSeatId, setPreviewSeatId] = useState<number | null>(null);
  const [, setTick] = useState(0);
  useEffect(() => {
    if (!adapter) return;
    return adapter.subscribe(() => {
      setTick((t) => t + 1);
      setPreviewSeatId(null);
      setCardOpen(false); // any game-state change closes a stale card
    });
  }, [adapter]);

  // 1s heartbeat so the count-up game timer advances (the adapter computes the
  // elapsed value; it freezes itself once a winner is set, so ticking is cheap).
  useEffect(() => {
    if (!adapter) return;
    const h = setInterval(() => setTick((t) => t + 1), 1000);
    return () => clearInterval(h);
  }, [adapter]);

  const [protocolOpen, setProtocolOpen] = useState(false);
  const [optionsOpen, setOptionsOpen] = useState(false);
  const [legendOpen, setLegendOpen] = useState(false);
  // Win-Banner schließbar: einmal weggeklickt bleibt das finale Brett bedienbar.
  const [winDismissed, setWinDismissed] = useState(false);
  const [editorSeatId, setEditorSeatId] = useState<number | null>(null);
  // ── single setup: the vanilla /legacy-setup is the ONLY round builder ──
  // ?from=setup → the vanilla flow just dealt a round into localStorage and
  // handed off here; adopt it. A direct entry whose localStorage already holds a
  // dealt round (seats have roles) is likewise adopted (resume). A direct entry
  // with NO round redirects to the vanilla setup — there is no React setup screen.
  const fromSetup = new URLSearchParams(location.search).get("from") === "setup";
  // role card overlay (top-level so it covers everything + click-anywhere closes)
  const [cardOpen, setCardOpen] = useState(false);
  // local browse cursor for the night order (decoupled from legacy "active"):
  // arrows/chip move this; the ActionCenter executes the viewed role explicitly.
  const [viewedIndex, setViewedIndex] = useState(0);
  // transient toast for GM guidance: phase-switch-blocked hint (Phase 2.2) and
  // the plain-text undo summary (Phase 2.7).
  const [toast, setToast] = useState<string | null>(null);

  const snap = adapter ? adapter.getSnapshot() : null;
  const hasRound = !!snap && snap.seats.some((s) => s.hasRole);
  const needsSetup = !!adapter && !fromSetup && !hasRound;

  // sobald es keinen Sieger (mehr) gibt, die Banner-Dismiss-Markierung zurücksetzen,
  // damit ein späterer/neuer Sieg das Banner wieder zeigt.
  useEffect(() => {
    if (!snap?.winner) setWinDismissed(false);
  }, [snap?.winner]);

  // Phase 1.2: a new night always begins at the first role. Reset the local
  // browse cursor when entering the night phase and on each new night counter.
  useEffect(() => {
    if (snap?.phase.phase === "night") setViewedIndex(0);
  }, [snap?.phase.phase, snap?.phase.nightCount]);

  // After an executed ability resolves, jump the browse cursor to the next role
  // that still needs the GM. Detect the active-action close transition (role →
  // null); only advance when that role is now DONE (a cancel leaves it open → no
  // skip). Keeps the Night Order name + ActionCenter on the new current role.
  const prevActiveRoleRef = useRef<string | null>(null);
  useEffect(() => {
    const ord = snap?.nightOrder ?? [];
    const active = snap?.activeAction?.role ?? null;
    const prev = prevActiveRoleRef.current;
    if (prev && !active) {
      const idx = ord.findIndex((e) => e.role === prev);
      if (idx >= 0 && ord[idx].done) {
        const next = ord.findIndex((e, i) => i > idx && !e.done);
        if (next >= 0) setViewedIndex(next);
      }
    }
    prevActiveRoleRef.current = active;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [snap?.activeAction?.role]);

  // auto-dismiss the toast after a few seconds
  useEffect(() => {
    if (!toast) return;
    const id = setTimeout(() => setToast(null), 3200);
    return () => clearTimeout(id);
  }, [toast]);

  // adopt the storage round (from=setup or an existing dealt round): clock +
  // night-1 parity. resumeRound guards itself against a double-invoke.
  useEffect(() => {
    if (adapter && !needsSetup) adapter.resumeRound();
  }, [adapter, needsSetup]);

  // no round + direct entry → hand off to the single (vanilla) setup
  useEffect(() => {
    if (needsSetup) window.location.replace(`${BASE}legacy-setup/index.html`);
  }, [needsSetup]);

  // Fraktions-Basis: lebende Spieler je Fraktion beim RUNDENSTART, EINMAL fixiert
  // (frisches Spiel ?from=setup → neu erfassen) und in localStorage für Reloads.
  // NICHT nach Toden/Konvertierungen neu berechnen. factionBaseline bewusst NICHT
  // in den Effekt-Deps → keine Re-Erfassung mitten in der Runde.
  const [factionBaseline, setFactionBaseline] = useState<Record<Faction, number> | null>(() => {
    try {
      const v = localStorage.getItem("grimmhain_faction_baseline");
      return v ? (JSON.parse(v) as Record<Faction, number>) : null;
    } catch {
      return null;
    }
  });
  useEffect(() => {
    if (!adapter || needsSetup) return;
    const live = adapter.getSnapshot();
    if (!live.seats.some((s) => s.hasRole)) return; // keine echte Runde
    if (fromSetup || !factionBaseline) {
      const base: Record<Faction, number> = { dorf: 0, wolf: 0, solo: 0 };
      live.seats.forEach((s) => {
        if (!s.dead) base[s.faction] += 1;
      });
      localStorage.setItem("grimmhain_faction_baseline", JSON.stringify(base));
      setFactionBaseline(base);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [adapter, fromSetup, needsSetup]);

  if (bootError) {
    return <div className="boot-status error">Legacy-Bridge fehlgeschlagen: {bootError}</div>;
  }
  if (!adapter || !snap) {
    return <div className="boot-status">Lade Spiellogik …</div>;
  }
  if (needsSetup) {
    return <div className="boot-status">Weiterleitung zum Setup …</div>;
  }

  // The board is DOM-only now (Pixi renderer removed). Each UI element is gated
  // by a flag below; the village-square background is a CSS layer on .game-stage.
  const showNightOrder: boolean = true;
  const showActionPanel: boolean = false;
  const showProtocol: boolean = true;
  const showOptions: boolean = true;
  const showPhaseControls: boolean = false;
  const showDomBoard: boolean = true; // DOM placeholder board (geometry test)
  const showBottomBars: boolean = true; // bottom HUD (night/timer + undo/next)
  const showActionCenter: boolean = true; // center panel for the active night role

  const editorSeat =
    editorSeatId != null ? snap.seats.find((s) => s.id === editorSeatId) ?? null : null;

  // Navigation vs. execution (Option A): a local browse cursor walks the order
  // freely; only the explicit "execute" opens an action. While an action is open
  // the display follows the acting role and navigation is disabled.
  const order = snap.nightOrder;
  const actionOpen = snap.activeAction != null;
  const execIndex = actionOpen
    ? order.findIndex((e) => e.role === snap.activeAction!.role)
    : -1;
  const clampedViewed = Math.max(0, Math.min(viewedIndex, Math.max(0, order.length - 1)));
  const currentIndex = actionOpen && execIndex >= 0 ? execIndex : clampedViewed;
  const currentEntry = order[currentIndex] ?? null;
  const goView = (idx: number) => setViewedIndex(Math.max(0, Math.min(idx, order.length - 1)));
  // 2.1: "Nächster Schritt" jumps to the next role that STILL needs the GM
  // (first not-done after the cursor), not a blind +1 onto an already-done slot.
  const goNextStep = () => {
    if (actionOpen) return;
    const next = order.findIndex((e, i) => i > currentIndex && !e.done);
    goView(next >= 0 ? next : currentIndex + 1);
  };
  // Phase 2.2: while a night ability or dialog is open, BLOCK the phase switch
  // (no silent cancel) and tell the GM why — they must resolve it or cancel via
  // the ✕ first. With nothing open, switch normally.
  const togglePhase = () => {
    if (actionOpen || snap.dialog) {
      setToast(
        LANG === "de"
          ? "Erst die offene Fähigkeit abschließen oder mit ✕ abbrechen."
          : "Finish or cancel (✕) the open ability first."
      );
      return;
    }
    setToast(null);
    adapter.setPhase(snap.phase.phase === "night" ? "day" : "night");
  };

  // Phase 2.7: undo + plain-text summary. Diff the snapshot BEFORE undo
  // (post-action) vs AFTER (reverted) — the difference is what was undone.
  // Computed React-side via getSnapshot so it never depends on internals.
  const handleUndo = () => {
    const before = adapter.getSnapshot();
    adapter.undo();
    const after = adapter.getSnapshot();
    const de = LANG === "de";
    const beforeDead = new Set(before.seats.filter((s) => s.dead).map((s) => s.id));
    const revived = after.seats.filter((s) => !s.dead && beforeDead.has(s.id)).map((s) => s.name);
    const parts: string[] = [];
    if (before.winner && !after.winner) parts.push(de ? "Sieg" : "the win");
    if (revived.length) parts.push((de ? "Tod von " : "death of ") + revived.join(", "));
    if (before.phase.phase !== after.phase.phase)
      parts.push(de ? "Phasenwechsel" : "phase change");
    setToast(
      parts.length
        ? (de ? "Rückgängig: " : "Undone: ") + parts.join(" · ") + (de ? " zurückgenommen." : " reverted.")
        : de
          ? "Letzte Aktion rückgängig gemacht."
          : "Last action undone."
    );
  };

  // Frisch ins eine (Vanilla-)Setup: die alte (ggf. GEWONNENE) Runde UND die
  // Fraktions-Basis aus localStorage räumen, sonst würde die alte Runde beim
  // nächsten Board-Aufruf wieder adoptiert (F5-/Sieg-Falle).
  const startNewGame = () => {
    try {
      localStorage.removeItem("uw_custom_v16");
      localStorage.removeItem("grimmhain_faction_baseline");
    } catch {
      /* localStorage evtl. nicht verfügbar → Navigation reicht */
    }
    window.location.href = `${BASE}legacy-setup/index.html`;
  };

  // In-App-Reset (Hard-Reset / Rollen leeren) verlässt das Board nicht, also die
  // Fraktions-Basis hier räumen — sonst bliebe die alte Baseline kleben. Eine
  // frisch ausgeteilte Runde (über das Setup, fromSetup) erfasst sie neu.
  const clearBaseline = () => {
    try {
      localStorage.removeItem("grimmhain_faction_baseline");
    } catch {
      /* localStorage evtl. nicht verfügbar */
    }
    setFactionBaseline(null);
  };

  return (
    <div className="game-screen" data-testid="game-screen">
      {/* night order is a night-only tool; in the day phase its chips would just
          show last night's stale "done"/dimmed ghosts → hide the bar by day. */}
      {showNightOrder && snap.phase.phase === "night" && (
        <NightOrder
          entries={snap.nightOrder}
          highlightIndex={currentIndex}
          onView={goView}
          navDisabled={actionOpen}
        />
      )}
      {/* Tag: an der gleichen Stelle (oben) statt der Nachtreihenfolge die Waage */}
      {snap.phase.phase === "day" && factionBaseline && (
        <FactionScale seats={snap.seats} baseline={factionBaseline} />
      )}

      <div
        className="game-stage"
        style={{
          backgroundImage: `url(${import.meta.env.BASE_URL}assets/bg/bg-village-${
            snap.phase.phase === "day" ? "day" : "night"
          }.webp)`
        }}
      >
        {showDomBoard && (
          <DomBoard
            snapshot={snap}
            wolfStep={snap.phase.phase === "night" && currentEntry?.role === "Werwolf"}
            previewSeatId={previewSeatId}
            onSeatTap={(id) => {
              // during a live pick/dialog the tap only picks the target (H3) —
              // it resolves the legacy pick and must NOT pop the inspect editor.
              // Only when truly idle (no open action/dialog AND no running pick)
              // does a tap open the player editor.
              const picking = snap.allowedSeatIds != null;
              // 2.9: a day-phase lynch tap → plain-text result toast
              const before = snap.phase.phase === "day" && picking ? adapter.getSnapshot() : null;
              adapter.selectPlayer(id);
              if (before) {
                const after = adapter.getSnapshot();
                const wasDead = new Set(before.seats.filter((s) => s.dead).map((s) => s.id));
                const killed = after.seats.filter((s) => s.dead && !wasDead.has(s.id)).map((s) => s.name);
                if (killed.length) {
                  const de = LANG === "de";
                  const won = !before.winner && !!after.winner;
                  setToast(
                    (de ? "Gelyncht: " : "Lynched: ") +
                      killed.join(", ") +
                      (won ? (de ? " · Sieg!" : " · win!") : "")
                  );
                }
              }
              if (!snap.activeAction && !snap.dialog && !picking) setEditorSeatId(id);
            }}
          />
        )}
        {/* night-only center panel: the viewed role + explicit execute, or the
            open action's controls. Hidden by day (the lynch medallion takes over). */}
        {showActionCenter && snap.phase.phase === "night" && currentEntry && (
          <ActionCenter
            entry={currentEntry}
            action={snap.activeAction}
            seats={snap.seats}
            previewSeatId={previewSeatId}
            onPreview={(id) => setPreviewSeatId(id)}
            onCommit={(id) => adapter.selectPlayer(id)}
            onClear={() => adapter.cancelPick()}
            onConfirm={() => adapter.confirmNightAction()}
            onChoice={(i) => adapter.pressDialogButton(i)}
            onExecute={() => adapter.goToNightStep(currentEntry.role)}
            onShowCard={() => setCardOpen(true)}
          />
        )}
        {showActionPanel &&
          (snap.dialog ? (
            <div className="action-panel-anchor">
              <DialogPanel
                dialog={snap.dialog}
                night={snap.phase.phase === "night"}
                onPress={(i) => adapter.pressDialogButton(i)}
              />
            </div>
          ) : snap.activeAction ? (
            <div className="action-panel-anchor">
              <ActionPanel
                action={snap.activeAction}
                seats={snap.seats}
                night={snap.phase.phase === "night"}
                onConfirm={() => adapter.confirmNightAction()}
              />
            </div>
          ) : null)}
        {showProtocol && (
          <ProtocolDrawer
            open={protocolOpen}
            entries={adapter.getProtocol()}
            onToggle={() => setProtocolOpen((o) => !o)}
          />
        )}
        {showOptions && (
          <OptionsDrawer
            open={optionsOpen}
            onToggle={() => {
              setOptionsOpen((o) => {
                if (!o) adapter.openOptions();
                return !o;
              });
            }}
            seatCount={snap.seatCount}
            onAddSeat={() => {
              // Phase 5: changing the seat count mid-round is disruptive → confirm
              const msg =
                LANG === "de"
                  ? `Sitzkreis auf ${snap.seatCount + 1} vergrößern? (laufende Runde)`
                  : `Grow the circle to ${snap.seatCount + 1} seats? (round in progress)`;
              if (window.confirm(msg)) adapter.setSeatCount(snap.seatCount + 1);
            }}
            onClearRoles={() => {
              adapter.clearRoles();
              clearBaseline();
            }}
            onHardReset={() => {
              adapter.hardReset();
              clearBaseline();
            }}
            onToggleNightMusic={() => adapter.toggleNightMusic()}
            onNewGame={startNewGame}
            onMainMenu={() => {
              window.location.href = `${BASE}legacy-setup/index.html`;
            }}
            onQuit={() => {
              window.location.href = `${BASE}legacy-setup/index.html`;
            }}
          />
        )}
      </div>

      {showPhaseControls && (
        <PhaseControls
          phase={snap.phase}
          canConfirm={!snap.dialog && snap.nightOrder.some((e) => !e.done)}
          onTogglePhase={() => adapter.setPhase(snap.phase.phase === "night" ? "day" : "night")}
          onNextStep={() => adapter.confirmNightAction()}
          onUndo={handleUndo}
        />
      )}

      {showBottomBars && (
        <BottomBars
          phase={snap.phase.phase}
          nightCount={snap.phase.nightCount}
          timer={snap.phase.timer}
          onUndo={handleUndo}
          onNext={goNextStep}
          onTogglePhase={togglePhase}
          onLegend={() => setLegendOpen(true)}
        />
      )}

      {/* transient GM toast — phase-blocked hint (2.2) + undo summary (2.7) */}
      {toast && (
        <div className="phase-hint-toast" role="status" data-testid="ui-toast">
          {toast}
        </div>
      )}

      {/* status-seal legend — dismissable dark overlay (top level so it covers all) */}
      <MarkerLegend open={legendOpen} onClose={() => setLegendOpen(false)} />

      {/* day death summary (e.g. "Niemand starb diese Nacht") — its own light
          surface so it never stacks under the ActionCenter (which is hidden by
          day). Shown only while a dialog is pending; the lynch button waits. */}
      {snap.phase.phase === "day" && snap.dialog && (
        <div className="day-dialog-overlay" data-testid="day-dialog">
          <div className="day-dialog panel-gothic">
            {snap.dialog.title && (
              <h3 className="day-dialog-title">{localizeDialogTitle(snap.dialog.title)}</h3>
            )}
            {snap.dialog.body && <p className="day-dialog-body">{snap.dialog.body}</p>}
            <div className="day-dialog-btns">
              {snap.dialog.buttons.map((b, i) => (
                <button
                  key={i}
                  type="button"
                  className="btn-gothic"
                  onClick={() => adapter.pressDialogButton(i)}
                  data-testid={`day-dialog-btn-${i}`}
                >
                  {b}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* daytime execution: only shown in the day phase, and only once no dialog
          is pending (one overlay at a time). The Lynch_{LANG}.webp medallion has
          the word baked in → it is the button face; the text label is a fallback. */}
      {snap.phase.phase === "day" && !snap.winner && !snap.dialog && (
        <button
          type="button"
          className="lynch-fab has-art"
          onClick={() => adapter.startLynch()}
          data-testid="lynch-button"
          aria-label={LYNCH_LABEL}
        >
          {/* the medallion always renders (no sticky onError state). If the asset
              ever failed to load, the alt text shows as a passive fallback. */}
          <img className="lynch-fab-art" src={LYNCH_URL} alt={LYNCH_LABEL} />
        </button>
      )}

      {editorSeat && (
        <PlayerEditor
          key={editorSeat.id}
          seat={editorSeat}
          roles={adapter.listRoles()}
          onClose={() => setEditorSeatId(null)}
          onSetName={(n) => adapter.setPlayerName(editorSeat.id, n)}
          onSetRole={(r) => adapter.setPlayerRole(editorSeat.id, r)}
          onToggleFlag={(flag, value) => adapter.setPlayerFlag(editorSeat.id, flag, value)}
        />
      )}

      {/* win banner — SCHLIESSBAR: Klick auf den Hintergrund oder "Schließen" gibt
          das finale Brett frei (bedienbar); "Neue Runde" räumt + geht ins Setup.
          Kein Dauer-Block / keine F5-Falle mehr. */}
      {snap.winner && !winDismissed && (
        <div
          className={`win-overlay faction-${winnerInfo(snap.winner).faction}`}
          data-testid="win-overlay"
          onClick={() => setWinDismissed(true)}
        >
          <div className="win-banner" onClick={(e) => e.stopPropagation()}>
            <div className="win-trophy">🏆</div>
            <div className="win-text">{winnerInfo(snap.winner).text}</div>
            <div className="win-time" data-testid="win-time">
              {snap.phase.timer}
            </div>
            <div className="win-actions">
              <button
                type="button"
                className="btn-gothic"
                data-testid="win-new-round"
                onClick={startNewGame}
              >
                {LANG === "de" ? "Neue Runde" : "New round"}
              </button>
              <button
                type="button"
                className="btn-gothic"
                data-testid="win-close"
                onClick={() => setWinDismissed(true)}
              >
                {LANG === "de" ? "Schließen" : "Close"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* role card overlay — top level so it covers the whole board; click
          anywhere closes; a missing card image (onError) closes it too. */}
      {cardOpen && currentEntry && roleCardUrl(currentEntry.role) && (
        <div
          className="role-card-overlay"
          data-testid="role-card-overlay"
          onClick={() => setCardOpen(false)}
        >
          <img
            className="role-card-img"
            src={roleCardUrl(currentEntry.role)}
            alt=""
            onError={() => setCardOpen(false)}
          />
        </div>
      )}
    </div>
  );
}
