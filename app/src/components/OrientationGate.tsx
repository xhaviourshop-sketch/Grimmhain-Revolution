import { useEffect, useState, type ReactNode } from "react";

/**
 * Tablet guard: the app targets tablets in landscape only
 * (iPad 4:3, Android 16:10). Portrait or small viewports show a gate
 * instead of the shell — no smartphone support by design.
 */
const MIN_WIDTH = 900;
const MIN_HEIGHT = 600;

type GateState = "ok" | "portrait" | "tooSmall";

function evaluate(): GateState {
  const w = window.innerWidth;
  const h = window.innerHeight;
  if (h > w) return "portrait";
  if (w < MIN_WIDTH || h < MIN_HEIGHT) return "tooSmall";
  return "ok";
}

export function OrientationGate({ children }: { children: ReactNode }) {
  const [gate, setGate] = useState<GateState>(() => evaluate());

  useEffect(() => {
    const update = () => setGate(evaluate());
    window.addEventListener("resize", update);
    window.addEventListener("orientationchange", update);
    return () => {
      window.removeEventListener("resize", update);
      window.removeEventListener("orientationchange", update);
    };
  }, []);

  if (gate !== "ok") {
    return (
      <div className="orientation-gate" data-testid="orientation-gate">
        <div className="orientation-gate-icon">{gate === "portrait" ? "🔄" : "📱"}</div>
        <div className="orientation-gate-title">
          {gate === "portrait" ? "Bitte Gerät drehen" : "Nur für Tablets"}
        </div>
        <div className="orientation-gate-sub">
          {gate === "portrait"
            ? "Grimmhain läuft nur im Querformat."
            : "Grimmhain ist für Tablets im Querformat ausgelegt (iPad 4:3 / Android 16:10)."}
        </div>
      </div>
    );
  }
  return <>{children}</>;
}
