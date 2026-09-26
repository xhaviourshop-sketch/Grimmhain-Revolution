/**
 * Shared view types of the adapter boundary.
 *
 * Shapes deliberately stay close to the legacy ViewModel produced by
 * `js/ui/field-viewmodel.js` (getFieldViewModel) so that the future
 * legacy adapter can be a thin pass-through and the existing game logic
 * in `js/core` / `js/ui` is never rewritten.
 */

export type Faction = "dorf" | "wolf" | "solo";

export type Phase = "day" | "night";

/** semantic status-marker keys that have a dedicated seal icon. Derived by
 *  MEANING from the legacy seat flags/meta (NOT from the emoji glyph — see
 *  legacyAdapter). Rendered as `assets/markers/marker-<key>.webp` on the token.
 *  Markers WITHOUT an icon (Cerberus ×N, Blutwolf V<n>) stay in SeatView.markers
 *  as text. */
export type MarkerKey =
  | "dead"
  | "protected"
  | "nominated"
  | "poison"
  | "love"
  | "hate"
  | "enchanted"
  | "burned"
  | "puppet"
  | "wolf"
  | "vorbild"
  | "silenced"
  | "vote"
  | "revealed"
  | "unholy";

/** All editable seat flags of the legacy player editor (game.html #pop chips).
 *  Used by GameAdapter.setPlayerFlag — additive, not yet wired to any UI. */
export type PlayerFlag =
  | "dead"
  | "protected"
  | "nominated"
  | "deadVoteStripped"
  | "targeted"
  | "poisoned"
  | "burned"
  | "charmed"
  | "inlove"
  | "rival"
  | "puppet"
  | "vorbild"
  | "werewolf"
  | "hmark";

export interface SeatView {
  id: number;
  index: number;
  name: string;
  /** internal German role id (legacy ALL_ROLES / state.seats[].role) —
   *  asset lookups MUST key on this, never on roleDisplay */
  roleId: string;
  /** localized display name (may be English) — UI text only */
  roleDisplay: string;
  hasRole: boolean;
  dead: boolean;
  /** structured status flags that drive the token rings (mirror of the legacy
   *  seat flags). dead already above; these four feed DomBoard's status ring. */
  poisoned: boolean;
  protected: boolean;
  silenced: boolean;
  marked: boolean;
  faction: Faction;
  /** emoji / short status markers, identical semantics to legacy markerList().
   *  Now only used for the icon-less text markers (Cerberus ×N, Blutwolf V<n>). */
  markers: string[];
  /** semantic seal-icon keys (see MarkerKey), rendered as marker-<key>.webp.
   *  Derived by meaning from the legacy flags/meta, never from the emoji glyph. */
  markerIcons: MarkerKey[];
  /** currently targeted by the active night action */
  targeted: boolean;
  /** currently selected/highlighted seat */
  selected: boolean;
  /** full editable flag set for the native player editor (mirror of the legacy
   *  seat flags). Read-only view; writes go through adapter.setPlayerFlag. */
  flags: Record<PlayerFlag, boolean>;
}

/** one selectable role for the setup screen (pool entry) */
export interface RolePoolEntry {
  role: string;
  name: string;
  faction: Faction;
}

export interface NightOrderEntry {
  /** internal role id (German, as in legacy ALL_ROLES) */
  role: string;
  displayName: string;
  faction: Faction;
  /** GM read-aloud instruction for this role (legacy: getRoleDescription →
   *  ROLE_DESCRIPTIONS; "" when none). Shown by the ActionCenter. */
  instruction: string;
  /** ability resolved tonight */
  done: boolean;
  /** currently awake / being processed */
  active: boolean;
  /** 🎭 decoy row: role no longer in play but kept for bluffing */
  decoy: boolean;
}

/** Night interaction shape. "target" = pick seat(s); "info" = read-only, just
 *  confirm; "choice" = either/or buttons. Optional fields default to a single
 *  target action so existing producers stay backward-compatible. */
export type ActionMode = "target" | "info" | "choice";

export interface ActiveAction {
  role: string;
  displayName: string;
  /** short imperative, e.g. "Wähle 1 Spieler" */
  instruction: string;
  /** longer flavor/help text */
  description: string;
  /** chosen target, null while none picked (single-target mode) */
  targetSeatId: number | null;
  /** action can be confirmed (target requirements met) */
  confirmable: boolean;
  /** interaction mode (default "target") */
  mode?: ActionMode;
  /** number of seats to pick in target mode (default 1) */
  targetCount?: number;
  /** seat ids already chosen (multi-target progress display) */
  chosenSeatIds?: number[];
  /** button labels for choice mode → adapter.pressDialogButton(index) */
  choices?: string[];
  /** revealed result text for info mode (e.g. Orakel: "David ist Werwolf") */
  infoText?: string;
  /** faction of the acting role (drives the center artwork + accent color);
   *  read read-only from the legacy getRoleFaction. Falls back to the night-order
   *  entry faction when absent. */
  faction?: Faction;
}

export interface PhaseInfo {
  phase: Phase;
  nightCount: number;
  /** display label, e.g. "Nacht 2" / "Tag 2" */
  label: string;
  /** mm:ss count-up timer string (from the legacy clock) */
  timer: string;
}

export interface LogEntry {
  time: string;
  icon: string;
  text: string;
}

/** A legacy modal mirrored out of the hidden overlay (answered via
 *  GameAdapter.pressDialogButton — never by re-implementing its logic). */
export interface DialogView {
  title: string;
  body: string;
  buttons: string[];
}

/** Single read model for the whole shell — one subscription, one snapshot. */
export interface GameSnapshot {
  phase: PhaseInfo;
  seatCount: number;
  seats: SeatView[];
  nightOrder: NightOrderEntry[];
  /** null when no night action is pending (e.g. day phase) */
  activeAction: ActiveAction | null;
  /** pending legacy dialog mirrored out of the hidden overlay (null when none) */
  dialog: DialogView | null;
  /** seat ids tappable for the running pick (legacy allow-predicate evaluated
   *  read-only per seat). null = no pick active → no dimming.
   *  DomBoard highlights these and dims the rest. */
  allowedSeatIds: number[] | null;
  /** winner once the game is decided (read-only from legacy state.once.TeamWinner):
   *  "village" | "wolves" | "solo_<Role>". null while the game runs. When set the
   *  shell shows the win banner and freezes inputs + timer. */
  winner: string | null;
}
