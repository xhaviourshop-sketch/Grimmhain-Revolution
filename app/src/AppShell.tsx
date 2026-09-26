import { GameScreen } from "./screens/GameScreen";
import { OrientationGate } from "./components/OrientationGate";

/**
 * AppShell — outer frame: tablet/landscape gate + safe-area padding. One single
 * run path: the real game on the vanilla engine via the legacy adapter (the
 * vanilla /legacy-setup deals the round, this board plays it).
 */
export function AppShell() {
  return (
    <OrientationGate>
      <div className="app-shell">
        <GameScreen />
      </div>
    </OrientationGate>
  );
}
