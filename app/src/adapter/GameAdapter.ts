import type { GameSnapshot, LogEntry, Phase, PlayerFlag, RolePoolEntry } from "./types";

/**
 * ADAPTER BOUNDARY — the ONLY contact surface between the React shell and the
 * game. Deliberately minimal:
 *
 *   read  : getSnapshot, getProtocol
 *   write : selectPlayer, setPhase, confirmNightAction, undo, openOptions
 *   signal: subscribe
 *
 * Implemented by the LegacyGameAdapter, which delegates to the untouched vanilla
 * logic (js/core/*, js/ui/field-viewmodel.js). No game rules are ever
 * re-implemented on this side.
 */
export interface GameAdapter {
  /** complete read model for rendering */
  getSnapshot(): GameSnapshot;

  /** tap on a player token (select / target the seat) */
  selectPlayer(seatId: number): void;

  /** switch day/night */
  setPhase(phase: Phase): void;

  /** confirm the pending night action and advance to the next role */
  confirmNightAction(): void;

  /** revert the last confirmed step. Returns a short plain-text summary of what
   *  was undone (e.g. "Rückgängig: Tod von Bert zurückgenommen") for a toast,
   *  or null when nothing was reverted. */
  undo(): string | null;

  /** answer a pending dialog (GameSnapshot.dialog) by button index */
  pressDialogButton(index: number): void;

  /** the host app wants the options surface opened (parity hook for legacy) */
  openOptions(): void;

  // ── Additive write surface (Phase: editor/controls reachable, dormant) ──
  // Encapsulate EXISTING game.html/legacy logic; no rules are re-implemented.

  /** set a single editor flag on a seat. Legacy triggers the real side
   *  effects (Manipulator-nominated → applyKill). */
  setPlayerFlag(seatId: number, flag: PlayerFlag, value: boolean): void;

  /** set a seat's role. Legacy applies savePop semantics (wolf-flag recompute
   *  via the authoritative isWolf, Der Weise → protected). The `role` MUST be a
   *  legacy role ID (German), not a localized display name — use listRoles(). */
  setPlayerRole(seatId: number, role: string): void;

  /** the full list of assignable roles (legacy ALL_ROLES) with localized display
   *  names + faction, for the editor's role picker. Keeps the role ID as the
   *  value so a pick can never break role lookups (no free-text typos). */
  listRoles(): RolePoolEntry[];

  /** set a seat's display name. */
  setPlayerName(seatId: number, name: string): void;

  /** jump the night order to a specific step. `index` (the slot position) is
   *  the authoritative target when given — it lands exactly on the clicked
   *  slot even if a role name repeats; `role` is the legacy fallback key. */
  goToNightStep(role: string, index?: number): void;

  /** open the legacy per-seat editor. DORMANT: not wired to any UI and, in the
   *  current runtime, a guarded no-op (the legacy #pop editor is not loaded). */
  openEditor(seatId: number): void;

  /** reset all night marks/effect flags without ending the round
   *  (legacy resetMarksOnly). */
  resetNightMarks(): void;

  /** change the number of seats at the table (legacy resizeSeats). */
  setSeatCount(count: number): void;

  /** options: clear all roles + flags, fresh day 1, keep seats/names
   *  (game.html clearRolesNewRound, ported verbatim via the legacy bridge). */
  clearRoles(): void;
  /** options: hard reset to a fresh state for the current seat count
   *  (game.html hardReset, ported verbatim). */
  hardReset(): void;
  /** options: toggle night music on/off; returns the new on-state. */
  toggleNightMusic(): boolean;

  // ── Setup / fresh round (Phase 2) ──
  /** selectable roles for an act/preset (legacy getAktRollen + getRoleName/
   *  getRoleFaction). aktId: "akt1".."akt4" | "custom". */
  getRolePool(aktId: string): RolePoolEntry[];

  /** boot a fresh round from a fully dealt role list (one role per seat):
   *  fresh state, roles assigned (+ wolf flag), night started, order rebuilt.
   *  Mirrors the vanilla distributeAndGo via existing globals — no rules added. */
  startGame(roles: string[]): void;

  /** cancel a running seat pick (legacy endPick). */
  cancelPick(): void;

  /** close ANY open night interaction (pick + dialog overlay) and clear the
   *  acting role, so nothing lingers when navigating the order or switching
   *  phase. Used to de-stack overlays. No rule logic — just closes the surfaces. */
  cancelOpenAction(): void;

  /** start the daytime lynch flow (legacy doLynchFlow): opens a seat pick; the
   *  tapped seat is executed (LynchCount++, Henker-marked seats resolved). Only
   *  meaningful in the day phase. No rules added — delegates to the global. */
  startLynch(): void;

  /** Adopt a round already present in storage (vanilla legacy-setup wrote it and
   *  navigated here with ?from=setup). Establishes game.html-onload parity —
   *  totenkarten/order rebuilt, night begun, count-up clock started — without
   *  re-dealing. Idempotent (safe under StrictMode double-invoke). */
  resumeRound(): void;

  /** read the protocol/log */
  getProtocol(): LogEntry[];

  /** notify on state changes; returns unsubscribe */
  subscribe(listener: () => void): () => void;
}
