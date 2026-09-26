import type { GameAdapter } from "../GameAdapter";
import type {
  ActiveAction,
  DialogView,
  Faction,
  GameSnapshot,
  LogEntry,
  MarkerKey,
  NightOrderEntry,
  Phase,
  PlayerFlag,
  RolePoolEntry,
  SeatView
} from "../types";
import { bootLegacyRuntime } from "./legacyEnv";
import { observeMirror, pressMirroredButton, readMirror } from "./domMirror";
import { LANG } from "../../lang";

/**
 * LegacyGameAdapter — binds the UNCHANGED legacy game logic (js/core, js/ui)
 * to the React shell through the GameAdapter boundary.
 *
 * Principles:
 *  - React components never touch window.* — every interaction goes through
 *    the methods below; this module is the only place that talks to legacy.
 *  - No game rule is re-implemented. The night order is read from the hidden
 *    #order that the legacy rebuildOrder() renders; dialogs/picks are
 *    mirrored from the hidden overlay/pickbar and answered by clicking the
 *    real legacy buttons.
 */

/* ── narrow runtime views of legacy structures (read-only) ── */
interface LegacySeat {
  id: number;
  name?: string;
  role?: string;
  flags: {
    dead?: boolean;
    targeted?: boolean;
    werewolf?: boolean;
    protected?: boolean;
    nominated?: boolean;
    [k: string]: boolean | undefined;
  };
  meta?: Record<string, unknown>;
}
interface LegacyState {
  seats: LegacySeat[];
  dark?: boolean;
  nightCount?: number;
  once?: Record<string, unknown>;
}
interface LegacyVmSeat {
  id: number;
  index: number;
  name: string;
  roleRaw: string;
  roleDisplay: string;
  hasRole: boolean;
  dead: boolean;
  faction: Faction;
  markers: string[];
}

type LegacyWindow = Window & {
  state?: LegacyState;
  getFieldViewModel?: () => { seats: LegacyVmSeat[] };
  rebuildOrder?: () => void;
  onNightStart?: () => void;
  onDayStart?: () => void;
  // clears the per-night "used" markers (state.once.NightUsedRoles + the
  // .night-used order slots). onNightStart does NOT call this, so it must run on
  // every night entry — otherwise night N+1 inherits night N's "done" rows.
  resetNightStars?: () => void;
  onOrderClick?: (role: string) => void;
  undoOnce?: () => void;
  pickMode?:
    | {
        onSeat: (seat: LegacySeat) => void;
        allow?: (seat: LegacySeat) => boolean;
        // additive read-surface attached by the startMulti probe below — these
        // are NOT part of the vanilla pickMode; they only mirror multi-progress.
        __max?: number;
        __chosen?: LegacySeat[];
      }
    | null;
  // wrapped read-only by installPickProbe() to expose multi target count + the
  // running selection (vanilla keeps both closure-private). Vanilla file itself
  // is never modified — only the runtime function is tapped.
  startMulti?: (
    prompt: string,
    max: number,
    allow: ((seat: LegacySeat) => boolean) | undefined,
    done: (chosen: LegacySeat[]) => void
  ) => void;
  endPick?: () => void;
  doLynchFlow?: () => void;
  gameLog?: { entries: { t: number; icon: string; text: string }[]; add?: (icon: string, text: string) => void };
  getRoleName?: (id: string) => string;
  getRoleDescription?: (id: string) => string;
  getRoleFaction?: (id: string) => string;
  __activeRole?: string | null;
  // additive write-surface globals (existing legacy functions, no rules added)
  save?: () => void;
  draw?: () => void;
  applyKill?: (seat: LegacySeat, cause: string) => void;
  isWolf?: (probe: { role: string; flags: Record<string, unknown>; meta: Record<string, unknown> }) => boolean;
  resizeSeats?: (n: number) => void;
  resetMarksOnly?: () => void;
  openPop?: (i: number, x: number, y: number, seatR: number) => void;
  // setup globals (existing legacy functions, no rules added)
  createState?: (n: number) => LegacyState;
  getAktRollen?: (aktId: string) => string[];
  ensureTotenkarten?: () => void;
  // options bridge globals (legacy-bridge.js — verbatim game.html logic)
  clearRolesNewRound?: () => void;
  hardReset?: () => void;
  toggleNightMusic?: () => boolean;
  isNightMusicPlaying?: () => boolean;
};

const w = window as unknown as LegacyWindow;

function hhmm(t: number): string {
  const d = new Date(t);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

/** elapsed game time as m:ss (count-up from game start). Pure presentation. */
function fmtElapsed(ms: number): string {
  const total = Math.max(0, Math.floor(ms / 1000));
  const m = Math.floor(total / 60);
  return `${m}:${String(total % 60).padStart(2, "0")}`;
}

/** Night order = parse of the hidden #order the legacy rebuildOrder filled
 *  (exact legacy filtering incl. 🎭 decoys — not duplicated here).
 *
 *  `actingRole` is the role of the OPEN pick/dialog (legacy __activeRole, only
 *  while an interaction is live). H1: onOrderClick marks the current role
 *  night-used immediately, so the plain "first not-done" cursor already points
 *  at the NEXT role. While an action is open we keep glow/active on the role
 *  that is really acting; only once it closes (actingRole null) does focus
 *  advance to the cursor. This keeps the ActionCenter title/instruction and the
 *  night-order glow on the acting role until its action is finished. */
function parseNightOrder(actingRole: string | null): NightOrderEntry[] {
  const rows = document.querySelectorAll<HTMLElement>("#order .slot");
  const entries: NightOrderEntry[] = [];
  rows.forEach((row) => {
    const role = row.dataset.role ?? "";
    if (!role) return;
    const name = row.querySelector(".night-order-name")?.textContent ?? role;
    entries.push({
      role,
      displayName: name,
      faction: (row.dataset.faction as Faction) ?? "dorf",
      // read-only GM instruction from the legacy role data (ROLE_DESCRIPTIONS)
      instruction: w.getRoleDescription?.(role) ?? "",
      done: row.classList.contains("night-used"),
      active: false, // computed below
      decoy: name.includes("🎭")
    });
  });
  const acting = actingRole ? entries.find((e) => e.role === actingRole) : null;
  if (acting) {
    acting.active = true;
  } else {
    const next = entries.find((e) => !e.done);
    if (next) next.active = true;
  }
  return entries;
}

export async function createLegacyAdapter(): Promise<GameAdapter> {
  const listeners = new Set<() => void>();
  const notify = () => listeners.forEach((l) => l());

  await bootLegacyRuntime(notify);
  observeMirror(notify);
  installPickProbe();

  let selectedSeatId: number | null = null;

  // count-up game clock (presentation only): startGame stamps the start; once a
  // winner is decided the elapsed value is frozen so the timer stops.
  let clockStartMs: number | null = null;
  let clockFrozenMs: number | null = null;
  let resumedFromSetup = false; // guards resumeRound against StrictMode re-invoke

  // Phase 5: manual editor changes are written to the protocol, marked ✏️ so the
  // GM can tell them apart from automatic game events. The legacy gameLog.add()
  // applies a recap filter that drops unknown icons → push the entry directly
  // (manual GM edits are deliberately important to record).
  const logManual = (text: string) => {
    try {
      const gl = w.gameLog;
      if (!gl?.entries) return;
      gl.entries.push({ t: Date.now(), icon: "✏️", text });
      if (gl.entries.length > 500) gl.entries.shift();
    } catch {
      /* tolerated */
    }
  };

  // Phase 2.7: plain-text undo. The legacy undoOnce restores a single private
  // pre-action snapshot. We diff the state RIGHT BEFORE undo (post-action) vs the
  // state RIGHT AFTER (reverted) — the difference IS what was undone. No reliance
  // on capturing at action time. Always returns a sentence (generic fallback).
  type UndoShape = {
    seats?: { id: number; name?: string; flags?: { dead?: boolean } }[];
    once?: { NightUsedRoles?: string[]; TeamWinner?: string };
  };
  const snapForUndo = (): UndoShape | null => {
    try {
      return w.state ? (JSON.parse(JSON.stringify(w.state)) as UndoShape) : null;
    } catch {
      return null;
    }
  };
  const diffUndo = (post: UndoShape | null, reverted: UndoShape | null): string => {
    const de = LANG === "de";
    const generic = de ? "Letzte Aktion rückgängig gemacht." : "Last action undone.";
    if (!post || !reverted) return generic;
    try {
      const revDead = new Set((reverted.seats ?? []).filter((s) => s.flags?.dead).map((s) => s.id));
      const deaths = (post.seats ?? [])
        .filter((s) => s.flags?.dead && !revDead.has(s.id))
        .map((s) => s.name || `#${s.id}`);
      const revUsed = new Set(reverted.once?.NightUsedRoles ?? []);
      const used = (post.once?.NightUsedRoles ?? []).filter((r) => !revUsed.has(r));
      const wonUndone = !!post.once?.TeamWinner && !reverted.once?.TeamWinner;
      const parts: string[] = [];
      if (wonUndone) parts.push(de ? "Sieg" : "the win");
      if (deaths.length) parts.push((de ? "Tod von " : "death of ") + deaths.join(", "));
      if (used.length)
        parts.push((de ? "Aktion: " : "action: ") + used.map((r) => w.getRoleName?.(r) || r).join(", "));
      if (!parts.length) return generic;
      return (de ? "Rückgängig: " : "Undone: ") + parts.join(" · ") + (de ? " zurückgenommen." : " reverted.");
    } catch {
      return generic;
    }
  };

  /** Tap window.startMulti (vanilla file untouched) so the live multi-pick
   *  exposes its target count + running selection on pickMode. The original
   *  keeps both closure-private; we wrap it once, memoizing the allow() result
   *  so allow is still evaluated exactly once per tap (no double side effects).
   *  Read-only mirror — no rule is changed, the original does all the work. */
  function installPickProbe() {
    const orig = w.startMulti;
    if (typeof orig !== "function" || (orig as { __probed?: boolean }).__probed) return;
    const wrapped: NonNullable<LegacyWindow["startMulti"]> = (prompt, max, allow, done) => {
      let lastSeat: LegacySeat | null = null;
      let lastOk = true;
      const memoAllow = allow
        ? (s: LegacySeat) => {
            lastSeat = s;
            lastOk = !!allow(s);
            return lastOk;
          }
        : allow;
      orig(prompt, max, memoAllow, done); // original builds window.pickMode
      type ProbedPick = {
        onSeat: (seat: LegacySeat) => void;
        allow?: (seat: LegacySeat) => boolean;
        __max?: number;
        __chosen?: LegacySeat[];
      };
      const pm = w.pickMode as ProbedPick | null | undefined;
      if (!pm) return;
      pm.__max = max;
      pm.__chosen = [];
      const innerOnSeat = pm.onSeat;
      pm.onSeat = (s: LegacySeat) => {
        innerOnSeat(s); // real accounting runs (memoAllow called once here)
        const ok = allow ? (lastSeat === s ? lastOk : true) : true;
        if (ok && pm.__chosen && !pm.__chosen.includes(s)) pm.__chosen.push(s);
        notify();
      };
    };
    (wrapped as { __probed?: boolean }).__probed = true;
    w.startMulti = wrapped;
  }

  function buildActiveAction(): ActiveAction | null {
    const { pick, dialog } = readMirror();
    // faction of the acting role, read read-only from the legacy getRoleFaction
    // (WOLF_ROLES_SET / SOLO_ROLES_SET membership). Empty role → dorf default.
    const factionOf = (role: string): Faction =>
      (role && (w.getRoleFaction?.(role) as Faction)) || "dorf";
    // A legacy #overlay dialog (either/or, yes/no, info modal) surfaces as a
    // choice action → ActionCenter shows its buttons, pressDialogButton clicks
    // the real legacy button. Read-only mapping, no rule logic.
    if (dialog) {
      const role = w.__activeRole ?? "";
      // center()/info modals show one button ("OK") → info mode with the revealed
      // body text; "Weiter" presses that single button (pressDialogButton(0)).
      // Multiple buttons → either/or choice.
      const isInfo = (dialog.buttons?.length ?? 0) <= 1;
      return {
        role,
        displayName: role ? w.getRoleName?.(role) ?? role : dialog.title || "Spielleitung",
        instruction: dialog.title ?? "",
        description: isInfo ? "" : dialog.body ?? "",
        targetSeatId: null,
        confirmable: false,
        mode: isInfo ? "info" : "choice",
        infoText: isInfo ? dialog.body : undefined,
        choices: dialog.buttons,
        faction: factionOf(role)
      };
    }
    if (!pick) return null;
    const role = w.__activeRole ?? "";
    // multi-pick progress comes from the probe-attached fields (closure-private
    // in vanilla startMulti); a single startPick has neither → targetCount 1.
    const pm = w.pickMode;
    const max = pm?.__max ?? 1;
    const chosenSeatIds = (pm?.__chosen ?? []).map((s) => s.id);
    return {
      role,
      displayName: role ? w.getRoleName?.(role) ?? role : pick.prompt,
      instruction: pick.prompt,
      description: role ? w.getRoleDescription?.(role) ?? "" : pick.hint,
      targetSeatId: null, // legacy picks complete on the seat tap itself
      confirmable: false,
      mode: "target",
      targetCount: max,
      chosenSeatIds,
      faction: factionOf(role)
    };
  }

  return {
    getSnapshot(): GameSnapshot {
      const st = w.state;
      const vm = w.getFieldViewModel?.();
      // "silenced" has no per-seat flag; it is the Totenrat silence list
      // (night.js names it exactly that). Authoritative source, read-only.
      const silencedIds = new Set(
        (st?.once?.TotenratFuehrerSilenced as number[] | undefined) ?? []
      );
      // context for the meaning-based marker derivation (mirrors legacy markerList):
      // the dead-vote markers only exist while a Nekromant is alive; OFFENBART only
      // after the Totenrat reveal. Computed once per snapshot, not per seat.
      const nekroAlive = (st?.seats ?? []).some(
        (x) => x.role === "Nekromant" && !x.flags.dead
      );
      const totenratRevealed = !!st?.once?.TotenratFuehrerRevealed;
      const seats: SeatView[] = (vm?.seats ?? []).map((s) => {
        const legacySeat = st?.seats.find((x) => x.id === s.id);
        // seal-icon keys derived by MEANING from the legacy flags/meta (never from
        // the emoji glyph) — same conditions as legacy markerList() in ui.js.
        const lf: Record<string, boolean | undefined> = legacySeat?.flags ?? {};
        const lmeta: Record<string, unknown> = legacySeat?.meta ?? {};
        const markerIcons: MarkerKey[] = [];
        if (lf.dead) markerIcons.push("dead");
        if (lf.dead && nekroAlive && !lf.deadVoteStripped) markerIcons.push("vote");
        if (lf.dead && nekroAlive && lf.deadVoteStripped) markerIcons.push("silenced");
        if (lf.protected) markerIcons.push("protected");
        if (lf.inlove) markerIcons.push("love");
        if (lf.rival) markerIcons.push("hate");
        if (lf.werewolf) markerIcons.push("wolf");
        if (lf.vorbild) markerIcons.push("vorbild");
        if (lf.nominated) markerIcons.push("nominated");
        if (lf.charmed) markerIcons.push("enchanted");
        if (lf.poisoned) markerIcons.push("poison");
        if (lf.burned) markerIcons.push("burned");
        if (lf.puppet) markerIcons.push("puppet");
        if (lmeta.unholy) markerIcons.push("unholy");
        if (legacySeat?.role === "Nekromant" && totenratRevealed) markerIcons.push("revealed");
        return {
          id: s.id,
          index: s.index,
          name: s.name,
          roleId: s.roleRaw,
          roleDisplay: s.roleDisplay,
          hasRole: s.hasRole,
          dead: s.dead,
          poisoned: !!legacySeat?.flags.poisoned,
          protected: !!legacySeat?.flags.protected,
          silenced: silencedIds.has(s.id),
          marked: !!legacySeat?.flags.hmark,
          faction: s.faction,
          flags: {
            dead: !!legacySeat?.flags.dead,
            protected: !!legacySeat?.flags.protected,
            nominated: !!legacySeat?.flags.nominated,
            deadVoteStripped: !!legacySeat?.flags.deadVoteStripped,
            targeted: !!legacySeat?.flags.targeted,
            poisoned: !!legacySeat?.flags.poisoned,
            burned: !!legacySeat?.flags.burned,
            charmed: !!legacySeat?.flags.charmed,
            inlove: !!legacySeat?.flags.inlove,
            rival: !!legacySeat?.flags.rival,
            puppet: !!legacySeat?.flags.puppet,
            vorbild: !!legacySeat?.flags.vorbild,
            werewolf: !!legacySeat?.flags.werewolf,
            hmark: !!legacySeat?.flags.hmark
          },
          markers: s.markers ?? [],
          markerIcons,
          targeted: !!legacySeat?.flags.targeted,
          selected: s.id === selectedSeatId
        };
      });
      const dark = !!st?.dark;
      const nightCount = st?.nightCount ?? 1;
      const { dialog, pick } = readMirror();
      const dialogView: DialogView | null = dialog;
      // __activeRole lingers after a role finishes (legacy never clears it), so
      // anchor on a LIVE interaction: only while a pick/dialog is open does the
      // acting role drive the glow/title (H1).
      const actingRole = dialog || pick ? w.__activeRole ?? null : null;
      // H4b: while a pick runs, evaluate the legacy allow-predicate read-only per
      // living seat → tappable seat ids. No allow predicate = every living seat
      // is allowed. null when no pick is active (DomBoard then dims nothing).
      const pm = w.pickMode;
      // Das Auswahl-Prädikat entscheidet, WELCHE Sitze wählbar sind — auch TOTE,
      // wenn die Rolle Tote anvisiert (Nekromant, Frankenstein-Wiederbelebung).
      // Nur ohne eigenes Prädikat fallen wir auf "lebend" zurück (sichere Vorgabe).
      const allowedSeatIds: number[] | null = pm
        ? (st?.seats ?? [])
            .filter((s) => {
              try {
                return pm.allow ? !!pm.allow(s) : !s.flags.dead;
              } catch {
                return !s.flags.dead; // wirft das Prädikat → sichere Vorgabe
              }
            })
            .map((s) => s.id)
        : null;
      // winner: authoritative legacy flag (checkTeamWin/triggerWin set it on save)
      const winner = (st?.once?.TeamWinner as string | null | undefined) ?? null;
      // count-up timer; freeze the moment a winner is decided
      if (winner && clockFrozenMs == null && clockStartMs != null) {
        clockFrozenMs = Date.now() - clockStartMs;
      }
      const elapsedMs =
        clockFrozenMs != null ? clockFrozenMs : clockStartMs != null ? Date.now() - clockStartMs : 0;
      return {
        phase: {
          phase: dark ? "night" : "day",
          nightCount,
          label: (dark ? "Nacht " : "Tag ") + nightCount,
          timer: clockStartMs != null ? fmtElapsed(elapsedMs) : "—"
        },
        seatCount: seats.length,
        seats,
        nightOrder: parseNightOrder(actingRole),
        activeAction: buildActiveAction(),
        dialog: dialogView,
        allowedSeatIds,
        winner
      };
    },

    selectPlayer(seatId: number) {
      const seat = w.state?.seats.find((s) => s.id === seatId);
      if (!seat) return;
      const pm = w.pickMode;
      if (pm) {
        // resolves the running legacy pick — allow/cleanup handled inside
        pm.onSeat(seat);
      } else {
        selectedSeatId = seatId === selectedSeatId ? null : seatId;
      }
      notify();
    },

    setPhase(next: Phase) {
      const st = w.state;
      if (!st) return;
      // Phase 1.5: once a winner is decided, freeze phase changes — no further
      // night/day may start (also covers the F5/win re-entry). The shell shows
      // the win banner; this is the authoritative backstop in the adapter.
      if (st.once?.TeamWinner) return;
      if (next === "night") {
        // game.html's start-night button relied on the setup flows having set
        // dark; the adapter owns that toggle now.
        st.dark = true;
        w.onNightStart?.();
        // NIGHT-RESET FIX (Phase 1): onNightStart resets per-night seat flags but
        // NOT the night-order "used" markers. parseNightOrder derives `done` from
        // the .night-used slot class (← state.once.NightUsedRoles). Without this,
        // every role acted in night N stays "done" in night N+1 and gets skipped.
        // Clear the markers, then rebuild the order so the cursor starts at role 1.
        w.resetNightStars?.();
        w.rebuildOrder?.();
      } else {
        w.onDayStart?.(); // resolves the night; legacy sets dark=false itself
      }
      notify();
    },

    confirmNightAction() {
      const { dialog, pick } = readMirror();
      if (dialog) return; // a pending dialog must be answered first
      if (pick) return; // a running pick wants a seat tap, not an advance
      // no live interaction here (returned above) → advance the natural cursor
      const next = parseNightOrder(null).find((e) => !e.done);
      if (!next) return;
      w.onOrderClick?.(next.role);
      notify();
    },

    undo() {
      const post = snapForUndo(); // state after the action (about to be reverted)
      w.undoOnce?.();
      const reverted = snapForUndo(); // state restored by the legacy undo
      const summary = diffUndo(post, reverted);
      // Komfort: the undo is also recorded in the protocol (marked ↩️), not just
      // shown as a toast. gameLog is separate from state, so it survives undoOnce.
      try {
        w.gameLog?.entries?.push({ t: Date.now(), icon: "↩️", text: summary });
        if ((w.gameLog?.entries?.length ?? 0) > 500) w.gameLog?.entries?.shift();
      } catch {
        /* tolerated */
      }
      notify();
      return summary;
    },

    pressDialogButton(index: number) {
      pressMirroredButton(index);
      notify();
    },

    openOptions() {
      // parity hook — legacy options surface docks here in a later phase
      notify();
    },

    // ── Additive write surface (dormant) — encapsulates EXISTING legacy logic ──
    setPlayerFlag(seatId: number, flag: PlayerFlag, value: boolean) {
      const seat = w.state?.seats.find((s) => s.id === seatId);
      if (!seat) return;
      seat.flags[flag] = value;
      // Phase 5: manual edits land in the protocol (marked ✏️)
      logManual(
        `${seat.name || "#" + seat.id} — ${flag} ${value ? (LANG === "de" ? "an" : "on") : LANG === "de" ? "aus" : "off"}`
      );
      // EXACT openPop chip side effect: Manipulator + nominated → applyKill
      if (flag === "nominated" && value && seat.role === "Manipulator") {
        const st = w.state!;
        st.once = st.once || {};
        st.once.ManipulatorWasNominated = true;
        try {
          w.applyKill?.(seat, "MANIPULATOR_NOMINATED");
        } catch {
          /* tolerated — matches the legacy try/catch */
        }
      }
      w.save?.();
      w.draw?.();
      w.rebuildOrder?.();
      notify();
    },

    setPlayerRole(seatId: number, role: string) {
      const seat = w.state?.seats.find((s) => s.id === seatId);
      if (!seat) return;
      const was = seat.role ?? "";
      seat.role = role;
      // savePop semantics, via authoritative globals (no rule duplication):
      // recompute wolf flag only on a real role change, using isWolf with a
      // clean probe so it returns pure WOLF_ROLES_SET membership.
      if (role !== was) {
        seat.flags.werewolf = !!w.isWolf?.({ role, flags: {}, meta: {} });
        logManual(`${seat.name || "#" + seat.id} → ${w.getRoleName?.(role) ?? role}`);
      }
      if (was !== "Der Weise" && role === "Der Weise") seat.flags.protected = true;
      w.save?.();
      w.draw?.();
      w.rebuildOrder?.();
      notify();
    },

    setPlayerName(seatId: number, name: string) {
      const seat = w.state?.seats.find((s) => s.id === seatId);
      if (!seat) return;
      const was = seat.name ?? "";
      seat.name = name;
      if (name !== was) logManual(`${was || "#" + seat.id} → ${name}`);
      w.save?.();
      w.draw?.();
      notify();
    },

    listRoles(): RolePoolEntry[] {
      // legacy "custom" act = ALL_ROLES; localized name + faction from the
      // authoritative legacy helpers. Role ID stays the value (no free-text).
      const ids = w.getAktRollen?.("custom") ?? [];
      return ids.map((role) => ({
        role,
        name: w.getRoleName?.(role) ?? role,
        faction: (w.getRoleFaction?.(role) as Faction) ?? "dorf"
      }));
    },

    goToNightStep(role: string) {
      // H5: while a pick/dialog is open, block jumping to another role. The legacy
      // onOrderClick would silently endPick() the running pick AND markStarUsed the
      // target → the abandoned role wrongly shows "done". The GM must resolve the
      // action or cancel it via the X (cancelPick) first. No legacy state rewritten.
      const { pick, dialog } = readMirror();
      if (pick || dialog) return;
      w.onOrderClick?.(role);
      notify();
    },

    openEditor(seatId: number) {
      // DORMANT: the legacy #pop editor (openPop) + its #pop/#stage DOM + CSS
      // are NOT loaded into the React runtime (see report for the blockers).
      // Guarded so a future, isolated port lights it up without touching any
      // caller; today it safely does nothing.
      const idx = w.state?.seats.findIndex((s) => s.id === seatId) ?? -1;
      if (idx < 0) return;
      if (typeof w.openPop === "function") w.openPop(idx, 0, 0, 0);
    },

    resetNightMarks() {
      w.resetMarksOnly?.();
      w.save?.();
      w.draw?.();
      w.rebuildOrder?.();
      notify();
    },

    setSeatCount(count: number) {
      w.resizeSeats?.(Math.max(4, count));
      w.save?.();
      w.draw?.();
      w.rebuildOrder?.();
      notify();
    },

    getRolePool(aktId: string): RolePoolEntry[] {
      const roles = w.getAktRollen?.(aktId) ?? [];
      const seen = new Set<string>();
      const out: RolePoolEntry[] = [];
      for (const role of roles) {
        if (!role || seen.has(role)) continue;
        seen.add(role);
        out.push({
          role,
          name: w.getRoleName?.(role) ?? role,
          faction: (w.getRoleFaction?.(role) as Faction) ?? "dorf"
        });
      }
      return out;
    },

    startGame(roles: string[]) {
      // Mirrors vanilla distributeAndGo via existing globals (no rules added):
      // fresh state, deal roles + wolf flag, night phase, rebuild order.
      const fresh = w.createState?.(Math.max(1, roles.length));
      if (!fresh) return;
      roles.forEach((role, i) => {
        const seat = fresh.seats[i];
        if (!seat) return;
        seat.role = role;
        seat.name = seat.name || `#${i + 1}`;
        seat.flags = seat.flags || {};
        seat.flags.werewolf = !!w.isWolf?.({ role, flags: {}, meta: {} });
        // savePop parity: Der Weise starts protected
        if (role === "Der Weise") seat.flags.protected = true;
      });
      fresh.dark = true;
      fresh.nightCount = 1;
      w.state = fresh; // swap the live round in (legacy reads window.state)
      w.ensureTotenkarten?.(); // game.html does this on load
      // start the count-up game clock at 0:00
      clockStartMs = Date.now();
      clockFrozenMs = null;
      w.save?.();
      w.rebuildOrder?.();
      w.onNightStart?.();
      notify();
    },

    startLynch() {
      // daytime execution: legacy doLynchFlow opens a seat pick (startPick); the
      // tapped seat resolves the lynch via the existing selectPlayer→pm.onSeat path.
      w.doLynchFlow?.();
      notify();
    },

    resumeRound() {
      // The vanilla legacy-setup flow already dealt the round into localStorage
      // (dark=true, nightCount=1, roles + werewolf flags) and navigated here;
      // legacyEnv loaded it via migrateState(load()). Reproduce what game.html
      // does on load + begin night 1, exactly like startGame, WITHOUT re-dealing.
      if (resumedFromSetup || !w.state) return;
      resumedFromSetup = true;
      w.ensureTotenkarten?.(); // totenkarten are assigned on game.html load
      w.rebuildOrder?.();
      // night parity only when the stored round IS in the night phase — a round
      // saved during the day must resume as day (onNightStart owns dark=true and
      // would reset per-night flags + start the night music).
      if (w.state.dark) w.onNightStart?.();
      clockStartMs = Date.now(); // start the count-up clock at 0:00
      clockFrozenMs = null;
      notify();
    },

    cancelPick() {
      // Use the legacy pickbar's own cancel button: it endPick()s AND hides the
      // bar. Raw endPick() alone leaves #pickbar visible → the mirror keeps
      // reporting a pick and the H5 guard would never release. Fallback to
      // endPick() if the button is absent.
      const cancelBtn = document.getElementById("pickcancel");
      if (cancelBtn) cancelBtn.click();
      else w.endPick?.();
      notify();
    },

    clearRoles() {
      // game.html "Rollen leeren" — clears roles + flags, resets once-state to a
      // fresh day 1, keeps the seats/names. Delegates to the verbatim bridge.
      w.clearRolesNewRound?.();
      notify();
    },

    hardReset() {
      // game.html "Hard-Reset" — fresh createState for the current seat count.
      w.hardReset?.();
      notify();
    },

    toggleNightMusic() {
      const on = w.toggleNightMusic?.() ?? false;
      notify();
      return on;
    },

    cancelOpenAction() {
      // close BOTH surfaces so nothing lingers across navigation / phase change:
      // the pickbar (via its own cancel = endPick + hide) and the dialog overlay.
      const pickbar = document.getElementById("pickbar");
      const cancelBtn = document.getElementById("pickcancel");
      if (pickbar && pickbar.style.display !== "none" && cancelBtn) cancelBtn.click();
      else w.endPick?.();
      const ov = document.getElementById("overlay");
      if (ov) ov.style.display = "none";
      w.__activeRole = null; // legacy never clears this on its own
      notify();
    },

    getProtocol(): LogEntry[] {
      return (w.gameLog?.entries ?? []).map((e) => ({
        time: hhmm(e.t),
        icon: e.icon,
        text: e.text
      }));
    },

    subscribe(l) {
      listeners.add(l);
      return () => listeners.delete(l);
    }
  };
}
