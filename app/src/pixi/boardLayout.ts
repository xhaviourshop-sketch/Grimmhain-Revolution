/**
 * Seat layout geometry — faithful port of computeGeometry()/minNeighborDist()
 * from the legacy game.html. Pure math, no game rules, no DOM.
 */

export interface BoardLayoutInput {
  /** width ratio in percent (legacy state.layout.ratio, default 120) */
  ratio: number;
  /** seat size scale in percent (legacy state.layout.scale, default 100) */
  scale: number;
  offx: number;
  offy: number;
}

export interface BoardGeometry {
  cx: number;
  cy: number;
  seatR: number;
  rx: number;
  ry: number;
}

export const DEFAULT_LAYOUT: BoardLayoutInput = { ratio: 200, scale: 100, offx: 0, offy: 0 };

function minNeighborDist(rx: number, ry: number, n: number): number {
  const d = (2 * Math.PI) / n;
  let m = Infinity;
  for (let t = 0; t < Math.PI * 2; t += Math.PI / 90) {
    const x1 = rx * Math.cos(t);
    const y1 = ry * Math.sin(t);
    const x2 = rx * Math.cos(t + d);
    const y2 = ry * Math.sin(t + d);
    const dist = Math.hypot(x2 - x1, y2 - y1);
    if (dist < m) m = dist;
  }
  return m;
}

export function computeGeometry(
  W: number,
  H: number,
  n: number,
  layout: BoardLayoutInput = DEFAULT_LAYOUT
): BoardGeometry {
  const pad = 8;
  const gap = 3;
  const seatMin = 16;
  const seatMax = 120;
  const k = layout.ratio / 100;
  const cx = W / 2 + layout.offx;
  const cy = H / 2 + layout.offy;
  const rxAvail = Math.max(10, Math.min(cx, W - cx) - pad);
  const ryAvail = Math.max(10, Math.min(cy, H - cy) - pad);
  let lo = seatMin;
  let hi = seatMax;
  let best = seatMin;
  let rxBest = 0;
  let ryBest = 0;
  for (let step = 0; step < 24; step++) {
    const mid = (lo + hi) / 2;
    const rxA = rxAvail - mid;
    const ryA = ryAvail - mid;
    if (rxA <= 0 || ryA <= 0) {
      hi = mid;
      continue;
    }
    const base = Math.min(ryA, rxA / k);
    const rx = Math.max(10, base * k);
    const ry = Math.max(10, base);
    const need = 2 * mid + gap;
    const minD = minNeighborDist(rx, ry, n);
    if (minD >= need) {
      best = mid;
      rxBest = rx;
      ryBest = ry;
      lo = mid;
    } else {
      hi = mid;
    }
  }
  const minD = minNeighborDist(rxBest, ryBest, n);
  const seatMaxByNeighbors = (minD - 4) / 2;
  const seatR = Math.max(seatMin, Math.min((best * layout.scale) / 100, seatMaxByNeighbors));
  return { cx, cy, seatR, rx: rxBest, ry: ryBest };
}

/** Position of seat i (0-based) of n seats, starting at 12 o'clock, clockwise. */
export function seatPosition(i: number, n: number, g: BoardGeometry): { x: number; y: number } {
  const ang = -Math.PI / 2 + i * ((2 * Math.PI) / n);
  return { x: g.cx + Math.cos(ang) * g.rx, y: g.cy + Math.sin(ang) * g.ry };
}
