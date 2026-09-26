import { useState } from "react";
import type { Faction, PlayerFlag, RolePoolEntry, SeatView } from "../adapter/types";

interface Props {
  seat: SeatView;
  /** all assignable roles (id + localized name + faction) for the role picker */
  roles: RolePoolEntry[];
  onClose: () => void;
  onSetName: (name: string) => void;
  onSetRole: (role: string) => void;
  onToggleFlag: (flag: PlayerFlag, value: boolean) => void;
}

const FACTION_LABEL: Record<Faction, string> = {
  dorf: "Dorf",
  wolf: "Werwölfe",
  solo: "Solo"
};

/** Flag groups mirroring the legacy game.html editor (#pop). The keys match
 *  the adapter's PlayerFlag union — every toggle writes via setPlayerFlag. */
const GROUPS: { label: string; chips: { key: PlayerFlag; label: string }[] }[] = [
  {
    label: "Status",
    chips: [
      { key: "dead", label: "☠ tot" },
      { key: "protected", label: "🛡 geschützt" },
      { key: "nominated", label: "⚖ nominiert" },
      { key: "deadVoteStripped", label: "🚫 Stimme entzogen" }
    ]
  },
  {
    label: "Nacht-Effekte",
    chips: [
      { key: "targeted", label: "🎯 anvisiert" },
      { key: "poisoned", label: "☣ vergiftet" },
      { key: "burned", label: "🔥 gebrannt" },
      { key: "charmed", label: "✨ verzaubert" }
    ]
  },
  {
    label: "Sozial",
    chips: [
      { key: "inlove", label: "❤ verliebt" },
      { key: "rival", label: "💔 Hass" },
      { key: "puppet", label: "🧸 Puppe" },
      { key: "vorbild", label: "🧟 Vorbild" }
    ]
  },
  {
    label: "Fraktion",
    chips: [
      { key: "werewolf", label: "🐺 Werwolf" },
      { key: "hmark", label: "🪃 Henker-Ziel" }
    ]
  }
];

/**
 * PlayerEditor — native React replacement for the legacy #pop seat editor.
 * Opens as a centered modal overlay (NOT bound to token pixel coordinates).
 * Reads the seat's current state from the snapshot and writes exclusively
 * through the adapter (setPlayerName/Role/Flag); no window.* access.
 *
 * Mounted with key={seat.id} so name/role local state resets per seat.
 */
export function PlayerEditor({ seat, roles, onClose, onSetName, onSetRole, onToggleFlag }: Props) {
  const [name, setName] = useState(seat.name);

  return (
    <div className="player-editor-backdrop" onClick={onClose} data-testid="player-editor-backdrop">
      <div
        className="player-editor"
        role="dialog"
        aria-label={`Sitz ${seat.id}`}
        data-testid="player-editor"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="player-editor-header">
          <span className="player-editor-title">Sitz {seat.id}</span>
          <button
            type="button"
            className="player-editor-close"
            onClick={onClose}
            aria-label="Schließen"
          >
            ✕
          </button>
        </div>

        <div className="player-editor-identity">
          <label className="player-editor-field">
            <span aria-hidden>👤</span>
            <input
              value={name}
              placeholder="Name"
              onChange={(e) => setName(e.target.value)}
              onBlur={() => onSetName(name)}
            />
          </label>
          <label className="player-editor-field">
            <span aria-hidden>🎭</span>
            {/* role PICKER (no free text): value is the legacy role ID, grouped
                by faction with localized names — a typo can't break rules. */}
            <select
              className="player-editor-role"
              value={seat.roleId}
              onChange={(e) => onSetRole(e.target.value)}
              data-testid="player-editor-role"
            >
              {/* keep the current role selectable even if absent from the list */}
              {seat.roleId && !roles.some((r) => r.role === seat.roleId) && (
                <option value={seat.roleId}>{seat.roleDisplay || seat.roleId}</option>
              )}
              {(["dorf", "wolf", "solo"] as Faction[]).map((f) => {
                const group = roles.filter((r) => r.faction === f);
                if (!group.length) return null;
                return (
                  <optgroup key={f} label={FACTION_LABEL[f]}>
                    {group.map((r) => (
                      <option key={r.role} value={r.role}>
                        {r.name}
                      </option>
                    ))}
                  </optgroup>
                );
              })}
            </select>
          </label>
        </div>

        {GROUPS.map((g) => (
          <div className="player-editor-group" key={g.label}>
            <div className="player-editor-group-label">{g.label}</div>
            <div className="player-editor-chips">
              {g.chips.map((c) => {
                const on = seat.flags[c.key];
                const handle = () => {
                  // Phase 5: marking a seat dead is consequential — confirm first
                  // and make clear this is a MANUAL mark (no auto death-resolution;
                  // use the lynch/night flow for consequences).
                  if (c.key === "dead" && !on) {
                    const ok = window.confirm(
                      "Spieler als TOT markieren?\n\n" +
                        "Manuelle Markierung — Todesfolgen und Siegprüfung werden NICHT " +
                        "automatisch ausgelöst (dafür Lynch / Nacht-Ablauf nutzen)."
                    );
                    if (!ok) return;
                  }
                  onToggleFlag(c.key, !on);
                };
                return (
                  <button
                    key={c.key}
                    type="button"
                    className={"player-editor-chip" + (on ? " active" : "")}
                    aria-pressed={on}
                    onClick={handle}
                  >
                    {c.label}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
