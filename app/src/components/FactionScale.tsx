import type { CSSProperties } from "react";
import type { Faction, SeatView } from "../adapter/types";

/**
 * FactionScale — animiertes Glasgefäß (capsule-frame.webp) für die Tag-Phase
 * (oben, wo nachts die Nachtreihenfolge sitzt). Drei dunkle Glaskammern; pro
 * Kammer eine halbtransparente Flüssigkeit, die das geätzte Motiv getönt
 * durchscheinen lässt. Unter dem Gefäß hängen drei Plaketten — in jede wird die
 * Zahl der Fraktion geschrieben (current/basis). Reine Anzeige, keine Spiel-Logik.
 *
 * Füllstand je Kammer = aktuell_i / basis_i (unabhängig, 100% = voll, kein Cap).
 */
const BASE = import.meta.env.BASE_URL;
const FRAME = `${BASE}assets/ui/capsule-frame.webp`;

// Boxen in % der Container-Größe (Asset 1349×601, breit/flach). box = Glaskammer
// (Flüssigkeit, einen Hauch eingerückt), plaque = Plakettenfeld (Zahl mittig).
const CHAMBERS: {
  key: Faction;
  liquid: string;
  num: string;
  box: CSSProperties;
  plaque: CSSProperties;
}[] = [
  {
    key: "dorf",
    liquid: "rgba(74, 138, 234, 0.46)",
    num: "#7fb0ff",
    box: { left: "15.6%", top: "14.6%", width: "19.6%", height: "52.7%" },
    plaque: { left: "19.2%", top: "76.0%", width: "15.0%", height: "12.2%" }
  },
  {
    key: "wolf",
    liquid: "rgba(218, 78, 66, 0.46)",
    num: "#ff7a6a",
    box: { left: "38.4%", top: "14.6%", width: "22.7%", height: "52.7%" },
    plaque: { left: "42.4%", top: "76.0%", width: "15.0%", height: "12.2%" }
  },
  {
    key: "solo",
    liquid: "rgba(158, 84, 210, 0.46)",
    num: "#c98cff",
    box: { left: "64.3%", top: "18.1%", width: "19.6%", height: "49.4%" },
    plaque: { left: "65.3%", top: "76.0%", width: "15.0%", height: "12.2%" }
  }
];

export function FactionScale({
  seats,
  baseline
}: {
  seats: SeatView[];
  baseline: Record<Faction, number>;
}) {
  const current: Record<Faction, number> = { dorf: 0, wolf: 0, solo: 0 };
  seats.forEach((s) => {
    if (!s.dead) current[s.faction] += 1;
  });

  return (
    <div className="faction-scale" data-testid="faction-scale">
      <div className="faction-vessel">
        {CHAMBERS.map((c) => {
          const base = baseline[c.key] || 0;
          const cur = current[c.key] || 0;
          // Füllstand = current/base (kein Cap; >100% wird vom Kammer-Clip beschnitten)
          const fill = base > 0 ? (cur / base) * 100 : 0;
          return (
            <div key={c.key} className="fv-chamber" data-faction={c.key} style={c.box}>
              <div
                className="fv-liquid"
                data-testid={`fv-liquid-${c.key}`}
                data-fill={fill.toFixed(1)}
                style={{ height: `${fill}%`, ["--liquid" as string]: c.liquid }}
              >
                <div className="fv-caustic" />
                <div className="fv-glow" />
                <div className="fv-surface" />
                <div className="fv-surface fv-surface--2" />
                <span className="fv-bubble fv-bubble--a" />
                <span className="fv-bubble fv-bubble--b" />
                <span className="fv-bubble fv-bubble--c" />
              </div>
            </div>
          );
        })}
        {/* Asset (Rahmen + opakes Glas + Motiv + Plaketten) als BASIS-Schicht hinten
            (z0); die halbtransparenten Flüssigkeits-Kammern liegen DAVOR (z1). */}
        <img className="fv-frame" src={FRAME} alt="" aria-hidden />
        {/* Zahl je Fraktion mittig in die zugehörige Plakette (nur die Zahl) */}
        {CHAMBERS.map((c) => {
          const base = baseline[c.key] || 0;
          const cur = current[c.key] || 0;
          return (
            <span
              key={c.key}
              className="fv-plaque"
              data-faction={c.key}
              data-testid={`fv-plaque-${c.key}`}
              style={{ ...c.plaque, color: c.num }}
            >
              {cur}/{base}
            </span>
          );
        })}
      </div>
    </div>
  );
}
