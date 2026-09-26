import { useEffect, useRef, useState, type CSSProperties } from "react";
import type { GameSnapshot, SeatView } from "../adapter/types";
import { type BoardGeometry } from "../pixi/boardLayout";

/**
 * DomBoard — the DOM/CSS board (sole renderer; the Pixi path was removed).
 * Der Spieler-Ring wird IMMER automatisch berechnet (Auto-Fit): er füllt die
 * verfügbare Board-Fläche, berührt nie das zentrale Phasen-Medaillon (gemessen
 * zur Laufzeit) und ragt nie aus dem Board. Einzige Stellschraube ist die
 * Token-Größe (Wunsch-/Maximalwert; Auto-Fit verkleinert nur, wenn nötig).
 */

// A) Sitznummern-Badge hinter einem Flag (Default AUS). Nur Anzeige — die interne
//    seat.id / Index / Reihenfolge / Adapter bleiben davon unberührt.
const SHOW_SEAT_NUMBERS = false;

const BASE = import.meta.env.BASE_URL;
const FRAME_URL = `${BASE}assets/ui/player-frame-neutral.png`;
const SELECTED_URL = `${BASE}assets/ui/overlay-selected.png`;

// Temporary archetype portraits by faction (no gender/age in the snapshot yet,
// so we rotate through each faction's available archetypes by index). Real
// role→portrait mapping comes later.
const PORTRAITS_BY_FACTION: Record<string, string[]> = {
  wolf: ["Wolf_Male"],
  solo: ["Solo_Female", "Solo_Male", "Solo_Unhuman"],
  dorf: [
    "Village_Young_Female",
    "Village_Young_Male",
    "Village_Middleaged_Female",
    "Village_Middleaged_Male",
    "Village_Old_Female",
    "Village_Old_Male"
  ]
};
const portraitFor = (faction: string, i: number) => {
  const pool = PORTRAITS_BY_FACTION[faction] ?? PORTRAITS_BY_FACTION.dorf;
  return `${BASE}assets/portraits/${pool[i % pool.length]}.png`;
};

const RING_URL = {
  marked: `${BASE}assets/ui/ring-marked.png`,
  poisoned: `${BASE}assets/ui/ring-poisoned.png`,
  silenced: `${BASE}assets/ui/ring-silenced.png`,
  protected: `${BASE}assets/ui/overlay-protected.png`,
  active: `${BASE}assets/ui/overlay-active.png`,
  target: `${BASE}assets/ui/overlay-target.png`
};
const DEAD_OVERLAY_URL = `${BASE}assets/ui/overlay-dead.png`;
// seal icons for the semantic status markers (see adapter MarkerKey). One webp
// per status, looked up by key — additive, art dropped into assets/markers/.
const markerSealUrl = (key: string) => `${BASE}assets/markers/marker-${key}.webp`;
// the only icon-less markers kept as text on the token (Cerberus head count ×N,
// Blutwolf vote weight V<n>) — language-independent glyphs, never translated.
const isTextMarker = (m: string) => /^×/.test(m) || /^V\d/.test(m);

// ─────────────────────────────────────────────────────────────────────────────
// Statusringe sind DATENGETRIEBEN aus den strukturierten Snapshot-Flags.
type RingType = "poisoned" | "marked" | "silenced" | "protected" | "active" | "target";

/** Statusring eines Sitzes, feste Priorität (tot wird vom Dead-Overlay gezeichnet,
 *  nicht hier). Liest die echten Snapshot-Flags. Ring-Optik (CSS) unverändert. */
function ringFor(seat: SeatView): { url: string; type: RingType } | null {
  if (seat.poisoned) return { url: RING_URL.poisoned, type: "poisoned" };
  if (seat.marked) return { url: RING_URL.marked, type: "marked" };
  if (seat.silenced) return { url: RING_URL.silenced, type: "silenced" };
  if (seat.protected) return { url: RING_URL.protected, type: "protected" };
  return null;
}
// ─────────────────────────────────────────────────────────────────────────────

const MIN_TOKEN = 48; // floor (sehr viele Spieler) — gerade noch lesbar
const MAX_TOKEN = 130; // cap (wenige Spieler)
const TOKEN_GAP = 6; // Mindestlücke zwischen benachbarten Token-Mittelpunkten (zusätzl. zum Ø)
const BASE_TOKEN = 84; // Wunsch-Durchmesser bei tokenScale = 1.0
const SEAL_OUT = 16; // radialer Überstand der Status-Siegel (Reserve zum Board-/UI-Rand)

// Reservierte Ränder des Board-Rechtecks (Viewport minus fester UI):
const TOP_INSET = 220; // oben: Gefäß (Tag) / Nachtleiste (Nacht)
const SIDE_TAB = 90; // links/rechts: geschlossene Protokoll/Option-Tabs
const BOTTOM_EDGE = 14; // unten: schmaler Boardrand
const PAD = 12; // zusätzlicher innerer Puffer
const MED_CLEAR = 24; // C: fester Mindestabstand Token-Rand ↔ Medaillon-Rand
// Untere Eck-Bars (feste UI nur in den Ecken): links Nacht/Timer, rechts Undo/Next.
const CORNER = { leftW: 165, rightW: 300, height: 128 };

/** Winkel (rad) für n Sitze, GLEICHMÄSSIG nach BOGENLÄNGE auf der Ellipse verteilt,
 *  Start bei 12 Uhr (-π/2), im Uhrzeigersinn. Gleicher Winkel würde die Sitze auf
 *  einem Oval an den Enden der langen Achse häufen; gleiche Bogenlänge hält den
 *  Abstand rundum konstant. Numerische Integration des Umfangs, dann inverse Suche.
 *
 *  `gap` (optional) = ein ausgesparter Winkelbereich [lo, hi] am unteren Rand für
 *  die Bedienleiste (Undo/Next): die Sitze werden dann gleichmäßig über den REST
 *  des Kreises verteilt (von hi nach lo+2π), unten bleibt eine freie Bedienzone —
 *  der Kreis wirkt weiter rund, hat aber unten eine kleine Aussparung. */
function seatAnglesByArc(
  n: number,
  rx: number,
  ry: number,
  gap?: { lo: number; hi: number } | null
): number[] {
  const SAMPLES = 1440; // 0.25° Auflösung
  const start = gap ? gap.hi : -Math.PI / 2;
  const span = gap ? gap.lo + 2 * Math.PI - gap.hi : 2 * Math.PI;
  const cum = new Array<number>(SAMPLES + 1);
  cum[0] = 0;
  let px = rx * Math.cos(start);
  let py = ry * Math.sin(start);
  for (let k = 1; k <= SAMPLES; k++) {
    const a = start + (k / SAMPLES) * span;
    const x = rx * Math.cos(a);
    const y = ry * Math.sin(a);
    cum[k] = cum[k - 1] + Math.hypot(x - px, y - py);
    px = x;
    py = y;
  }
  const total = cum[SAMPLES] || 1;
  // geschlossener Kreis: n Punkte bei i/n. Offener Bogen (mit Lücke): n Punkte bei
  // i/(n-1), erster + letzter Sitz an den Lücken-Rändern (unten links/rechts).
  const denom = gap ? Math.max(1, n - 1) : n;
  const angles: number[] = [];
  let k = 0;
  for (let i = 0; i < n; i++) {
    const target = (i / denom) * total;
    while (k < SAMPLES && cum[k + 1] < target) k++;
    const seg = cum[k + 1] - cum[k] || 1;
    const frac = (target - cum[k]) / seg;
    angles.push(start + ((k + frac) / SAMPLES) * span);
  }
  return angles;
}

type Pt = { x: number; y: number };
type Layout = { tr: number; rx: number; ry: number; angles: number[]; pts: Pt[] };

export function DomBoard({
  snapshot,
  previewSeatId,
  onSeatTap,
  wolfStep = false
}: {
  snapshot: GameSnapshot;
  /** arrow-preview target → glowing ring highlight (Fix 5) */
  previewSeatId?: number | null;
  onSeatTap: (seatId: number) => void;
  /** C: during the Werwolf night step, ring all LIVING wolf-faction tokens with a
   *  red glow (in addition to the white active/preview glow). */
  wolfStep?: boolean;
}) {
  const hostRef = useRef<HTMLDivElement | null>(null);
  const [size, setSize] = useState({ w: 0, h: 0 });

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;
    const measure = () => setSize({ w: host.clientWidth, h: host.clientHeight });
    const ro = new ResizeObserver(measure);
    ro.observe(host);
    measure();
    return () => ro.disconnect();
  }, []);

  // Token-Größe: einzige verbleibende Ansicht-Stellschraube (Wunsch-/Maximalwert).
  // Rein visuell, persistiert in localStorage. Der Auto-Fit verkleinert nur, wenn
  // sonst Tokens das Medaillon berühren oder aus dem Board ragen würden.
  const [tokenScale, setTokenScale] = useState(() => {
    const v = Number(localStorage.getItem("dev_token_scale"));
    return v >= 0.6 && v <= 1.6 ? v : 1.0;
  });
  useEffect(() => {
    localStorage.setItem("dev_token_scale", String(tokenScale));
  }, [tokenScale]);
  // Ansicht-Panel ein-/ausklappbar; Default eingeklappt, Zustand in localStorage.
  const [devOpen, setDevOpen] = useState(() => localStorage.getItem("dev_panel_open") === "1");
  useEffect(() => {
    localStorage.setItem("dev_panel_open", devOpen ? "1" : "0");
  }, [devOpen]);

  // ── Medaillon-Clearance: das zentrale Phasen-Medaillon (Tag: Lynchen-Button,
  //    Nacht: ActionCenter) wird zur Laufzeit in Host-Koordinaten gemessen
  //    (NICHT hardcodiert). Fehlt es kurz (z.B. offener Tag-Dialog), bleibt der
  //    letzte Messwert stehen, damit der Ring nicht springt. ──
  const [med, setMed] = useState<{ cx: number; cy: number; halfW: number; halfH: number } | null>(
    null
  );
  // Untere Bedienleiste (Rückgängig/Nächster Schritt) — ein großer, mittig-rechter
  // Block. Wird gemessen, damit der Ring unten eine Aussparung dafür frei lässt
  // (Sitze nach links/rechts statt unter die Buttons).
  const [bar, setBar] = useState<{ cx: number; cy: number; halfW: number; halfH: number } | null>(
    null
  );
  // Tag-Phase: das Fraktions-Gefäß (FactionScale) sitzt oben-mittig und ragt auf
  // breiten Viewports tiefer als die starre 220px-Reserve. Wird gemessen, damit
  // die oberen Tokens darum freigehalten werden. Nur in der Tag-Phase vorhanden.
  const [vessel, setVessel] = useState<{
    cx: number;
    cy: number;
    halfW: number;
    halfH: number;
  } | null>(null);
  const phase = snapshot.phase.phase;
  const activeRole = snapshot.activeAction?.role ?? null;
  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;
    let raf = 0;
    const find = () =>
      document.querySelector<HTMLElement>(
        '[data-testid="lynch-button"], [data-testid="action-center"]'
      );
    const toBox = (el: HTMLElement, hr: DOMRect) => {
      const er = el.getBoundingClientRect();
      if (er.width < 4 || er.height < 4) return null;
      return {
        cx: er.left + er.width / 2 - hr.left,
        cy: er.top + er.height / 2 - hr.top,
        halfW: er.width / 2,
        halfH: er.height / 2
      };
    };
    const measure = () => {
      const hr = host.getBoundingClientRect();
      const el = find();
      // reale Box-Halbmaße: die Tokens weichen der ECHTEN Bounding-Box aus (das
      // ActionCenter-Panel ist breit — ein einbeschriebener Kreis würde seine
      // Ausdehnung unterschätzen und Token überlappen).
      if (el) {
        const b = toBox(el, hr);
        if (b) setMed(b);
      }
      const barEl = document.querySelector<HTMLElement>('[data-testid="bottom-actions"]');
      if (barEl) {
        const b = toBox(barEl, hr);
        if (b) setBar(b);
      }
      // Tag-Gefäß: gemessene Box, sonst null (Nacht → keine Vessel-Clearance)
      const vesselEl = document.querySelector<HTMLElement>('[data-testid="faction-scale"]');
      setVessel(vesselEl ? toBox(vesselEl, hr) : null);
    };
    raf = requestAnimationFrame(measure);
    const el = find();
    const barEl = document.querySelector<HTMLElement>('[data-testid="bottom-actions"]');
    const vesselEl = document.querySelector<HTMLElement>('[data-testid="faction-scale"]');
    const ro = new ResizeObserver(() => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(measure);
    });
    ro.observe(host);
    if (el) ro.observe(el);
    if (barEl) ro.observe(barEl);
    if (vesselEl) ro.observe(vesselEl);
    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
    };
  }, [phase, activeRole]);

  // Immer die echten Sitze aus dem Snapshot — es gibt keine Dummy-Sitze mehr.
  const seats = snapshot.seats;
  const n = Math.max(4, seats.length);
  const ready = size.w > 200 && size.h > 200;

  // ── Auto-Fit ──────────────────────────────────────────────────────────────
  let g: BoardGeometry | null = null;
  let diameter = 0;
  let seatAngles: number[] = [];
  let positions: Pt[] = [];

  if (ready) {
    // 1. Verfügbares Board-Rechteck (Viewport minus reservierte Ränder minus pad)
    const left = SIDE_TAB + PAD;
    const right = size.w - SIDE_TAB - PAD;
    const top = TOP_INSET + PAD;
    const bottom = size.h - BOTTOM_EDGE - PAD;
    // 2. Board-Mitte + Token-Radius (aus dem Regler)
    const bcx = (left + right) / 2;
    const bcy = (top + bottom) / 2;
    const halfW = (right - left) / 2;
    const halfH = (bottom - top) / 2;
    // 5. Zentral-Element (gemessen; Fallback: Board-Mitte, keine Ausdehnung)
    const medCx = med ? med.cx : bcx;
    const medCy = med ? med.cy : bcy;
    const medHW = med ? med.halfW : 0;
    const medHH = med ? med.halfH : 0;
    // untere Bedienleiste (gemessene Box; 0 falls noch nicht gemessen)
    const barCx = bar ? bar.cx : 0;
    const barCy = bar ? bar.cy : 0;
    const barHW = bar ? bar.halfW : 0;
    const barHH = bar ? bar.halfH : 0;
    // Tag-Gefäß oben (gemessene Box; 0 falls nicht vorhanden / Nacht)
    const vesselCx = vessel ? vessel.cx : 0;
    const vesselCy = vessel ? vessel.cy : 0;
    const vesselHW = vessel ? vessel.halfW : 0;
    const vesselHH = vessel ? vessel.halfH : 0;

    // Wunsch-Token-Durchmesser aus dem Regler (Maximalwert)
    const dWish = Math.max(MIN_TOKEN, Math.min(MAX_TOKEN, Math.round(BASE_TOKEN * tokenScale)));

    // Ausgesparter Winkelbereich unten für die Bedienleiste: GENAU die Winkel, bei
    // denen der Ellipsenpunkt in der (um Token-Radius + Abstand erweiterten) Box der
    // Leiste landen würde. Dadurch meiden die Sitze die Leiste exakt — unten
    // entsteht eine freie Bedienzone, die Sitze wandern nach links/rechts. Abtastung
    // statt Eckwinkel, weil der Ellipsenradius einen Eckwinkel überschießen kann.
    const barGap = (rx: number, ry: number, tr: number): { lo: number; hi: number } | null => {
      if (barHW <= 0) return null;
      const m = MED_CLEAR + tr;
      const bx0 = barCx - barHW - m;
      const bx1 = barCx + barHW + m;
      const by0 = barCy - barHH - m;
      const by1 = barCy + barHH + m;
      let lo = Infinity;
      let hi = -Infinity;
      const STEPS = 720;
      for (let i = 0; i <= STEPS; i++) {
        const a = (i / STEPS) * 2 * Math.PI; // 0..2π, Boden liegt bei π/2
        const x = bcx + Math.cos(a) * rx;
        const y = bcy + Math.sin(a) * ry;
        if (x >= bx0 && x <= bx1 && y >= by0 && y <= by1) {
          if (a < lo) lo = a;
          if (a > hi) hi = a;
        }
      }
      return lo === Infinity ? null : { lo, hi };
    };
    const inBar = (p: Pt, tr: number): boolean =>
      barHW > 0 && Math.abs(p.x - barCx) < barHW + tr && Math.abs(p.y - barCy) < barHH + tr;
    const inVessel = (p: Pt, tr: number): boolean =>
      vesselHW > 0 &&
      Math.abs(p.x - vesselCx) < vesselHW + tr &&
      Math.abs(p.y - vesselCy) < vesselHH + tr;
    // AABB-Push: schiebt einen Punkt aus der erweiterten Box (cx/cy, Halbmaße
    // ex/ey) entlang seiner Radial-Richtung an den Box-Rand. Wie die Medaillon-
    // Clearance — nur dass das Box-Zentrum übergeben wird.
    const pushOutOf = (
      x: number,
      y: number,
      cx: number,
      cy: number,
      ex: number,
      ey: number
    ): Pt => {
      if (ex <= 0 || ey <= 0) return { x, y };
      const dx = x - cx;
      const dy = y - cy;
      if (dx === 0 && dy === 0) return { x: cx, y: cy + ey }; // Vessel sitzt oben → nach unten
      const m = Math.max(Math.abs(dx) / ex, Math.abs(dy) / ey);
      return m < 1 ? { x: cx + dx / m, y: cy + dy / m } : { x, y };
    };

    // Eck-Treffer? (untere Eck-Bars: links Nacht/Timer, rechts Undo/Next)
    const cornerHit = (pts: Pt[], tr: number): boolean => {
      const reach = tr + SEAL_OUT;
      for (const p of pts) {
        if (
          p.y + reach > size.h - CORNER.height &&
          (p.x - reach < CORNER.leftW || p.x + reach > size.w - CORNER.rightW)
        )
          return true;
      }
      return false;
    };
    // Tokens auf die Ellipse setzen + Clearance gegen die reale BOX des Zentral-
    // Elements (Token-Radius + Mindestabstand außerhalb der Box). Liegt ein Token
    // innerhalb der erweiterten Box, wird er entlang seiner Radial-Richtung nach
    // außen an den Box-Rand geschoben (AABB-Push, nicht Kreis).
    const place = (angles: number[], rx: number, ry: number, tr: number): Pt[] => {
      const mx = medHW + MED_CLEAR + tr; // halbe Box-Breite + Abstand + Token-Radius
      const my = medHH + MED_CLEAR + tr; // halbe Box-Höhe + Abstand + Token-Radius
      return angles.map((a) => {
        let x = bcx + Math.cos(a) * rx;
        let y = bcy + Math.sin(a) * ry;
        if (mx > 0 && my > 0) {
          const dx = x - medCx;
          const dy = y - medCy;
          if (dx === 0 && dy === 0) {
            y = medCy - my; // exakt im Zentrum → gerade nach oben
          } else {
            // normierte Box-Distanz: <1 heißt innerhalb der erweiterten Box
            const m = Math.max(Math.abs(dx) / mx, Math.abs(dy) / my);
            if (m < 1) {
              const k = 1 / m;
              x = medCx + dx * k;
              y = medCy + dy * k;
            }
          }
        }
        // zusätzlich: Clearance gegen das Tag-Gefäß oben (gleiche Box-Logik)
        if (vesselHW > 0) {
          ({ x, y } = pushOutOf(x, y, vesselCx, vesselCy, vesselHW + MED_CLEAR + tr, vesselHH + MED_CLEAR + tr));
        }
        return { x, y };
      });
    };

    const layoutFor = (D: number): Layout => {
      const tr = D / 2;
      // 3. Basis-Ellipse füllt das Rechteck (Token-Radius + Siegel-Überstand frei)
      const rx = Math.max(20, halfW - tr - SEAL_OUT);
      let ry = Math.max(20, halfH - tr - SEAL_OUT);
      // untere Aussparung für die Bedienleiste (Sitze nach links/rechts); hängt von
      // rx/ry ab → bei jeder Abflachung neu berechnen.
      let angles = seatAnglesByArc(n, rx, ry, barGap(rx, ry, tr));
      let pts = place(angles, rx, ry, tr);
      for (let it = 0; it < 30 && ry > 40 && cornerHit(pts, tr); it++) {
        ry -= 8;
        angles = seatAnglesByArc(n, rx, ry, barGap(rx, ry, tr));
        pts = place(angles, rx, ry, tr);
      }
      return { tr, rx, ry, angles, pts };
    };

    // Kollisionsfrei? (Board-Rand inkl. Siegel-Überstand, untere Eck-Bars,
    // Nachbar-Abstand). Medaillon-Abstand ist durch den Push garantiert.
    const fits = (L: Layout, D: number): boolean => {
      const reach = L.tr + SEAL_OUT;
      for (const p of L.pts) {
        if (p.x - reach < left || p.x + reach > right || p.y - reach < top || p.y + reach > bottom)
          return false;
        if (
          p.y + reach > size.h - CORNER.height &&
          (p.x - reach < CORNER.leftW || p.x + reach > size.w - CORNER.rightW)
        )
          return false;
        // Sicherheitsnetz: kein Token in der Box der unteren Bedienleiste
        if (inBar(p, L.tr)) return false;
        // Sicherheitsnetz: kein Token in der Box des Tag-Gefäßes (oben)
        if (inVessel(p, L.tr)) return false;
      }
      for (let i = 0; i < L.pts.length; i++) {
        const p = L.pts[i];
        const q = L.pts[(i + 1) % L.pts.length];
        if (Math.hypot(p.x - q.x, p.y - q.y) < D + TOKEN_GAP) return false;
      }
      return true;
    };

    // 7. Token-Größe global nur so weit reduzieren, bis alles kollisionsfrei sitzt.
    let D = dWish;
    let L = layoutFor(D);
    let guard = 0;
    while (!fits(L, D) && D > MIN_TOKEN && guard++ < 200) {
      D = Math.max(MIN_TOKEN, D - 2);
      L = layoutFor(D);
    }
    diameter = D;
    positions = L.pts;
    seatAngles = L.angles;
    g = { cx: bcx, cy: bcy, rx: L.rx, ry: L.ry, seatR: D / 2 };
  }

  // H4b: tappable seats during a running pick. null → no pick → no dimming.
  const allowedSet = snapshot.allowedSeatIds ? new Set(snapshot.allowedSeatIds) : null;

  return (
    <div ref={hostRef} className="dom-board" data-testid="dom-board">
      {/* ── Ansicht-Panel: nur noch Token-Größe (rein visuell, persistiert in
          localStorage). Ring-Größe/Ring-Breite entfallen — der Ring ist Auto-Fit. ── */}
      <div className={"dom-dev-slider" + (devOpen ? " open" : " collapsed")}>
        <button
          type="button"
          className="dom-dev-toggle"
          onClick={() => setDevOpen((o) => !o)}
          aria-label={devOpen ? "Ansicht-Panel einklappen" : "Ansicht-Panel ausklappen"}
          aria-expanded={devOpen}
        >
          {devOpen ? "◀ Ansicht" : "▶"}
        </button>
        {devOpen && (
          <>
            <span>Token-Größe · {tokenScale.toFixed(2)}</span>
            <input
              type="range"
              min={0.6}
              max={1.6}
              step={0.01}
              value={tokenScale}
              onChange={(e) => setTokenScale(Number(e.target.value))}
            />
          </>
        )}
      </div>
      {/* ── /Ansicht-Panel ── */}

      {g &&
        seats.map((seat, i) => {
          const { x, y } = positions[i] ?? { x: g.cx, y: g.cy };
          const isDead = seat.dead;
          const ring = isDead ? null : ringFor(seat); // dead overrides all status rings
          return (
            <div
              key={seat.id}
              className={
                "dom-token" +
                (seat.selected ? " selected" : "") +
                (allowedSet && seat.id === previewSeatId ? " preview" : "") +
                (wolfStep && seat.faction === "wolf" && !seat.dead ? " wolf-glow" : "") +
                (allowedSet
                  ? allowedSet.has(seat.id)
                    ? " pick-allowed"
                    : " pick-blocked"
                  : "")
              }
              onClick={() => onSeatTap(seat.id)}
              style={{
                left: `${x}px`,
                top: `${y}px`,
                width: `${diameter}px`,
                height: `${diameter}px`
              }}
            >
              <img className="dom-token-portrait" src={portraitFor(seat.faction, i)} alt="" />
              {ring && (
                <img className={`dom-token-ring dom-token-ring--${ring.type}`} src={ring.url} alt="" />
              )}
              <img className="dom-token-frame" src={FRAME_URL} alt="" />
              {isDead && <img className="dom-token-dead" src={DEAD_OVERLAY_URL} alt="" />}
              {/* selection ring — hängt am echten selectPlayer/Klick (seat.selected) */}
              {seat.selected && <img className="dom-token-selected" src={SELECTED_URL} alt="" />}
              {SHOW_SEAT_NUMBERS && <span className="dom-token-badge">{seat.id}</span>}
              {/* B) Name als HORIZONTALE Box ober-/unterhalb des Tokens, immer zur
                  Kreis-MITTE hin (Token oberhalb der Oval-Mitte → Name darunter, sonst
                  darüber). Eine waagerechte Kante mit fester Lücke klärt den Kreis bei
                  JEDER Namensbreite; die Mitte-Richtung ist gegenüber dem außen
                  liegenden Siegel-Bogen und liegt im leeren Ring-Loch (nachbar-sicher). */}
              {(() => {
                const towardBelow = g != null && y < g.cy; // Token über Mitte → Name darunter
                const off = diameter / 2 + 9; // Kreisrand + feste Lücke zur waagerechten Kante
                const ny = towardBelow ? `${off.toFixed(0)}px` : `calc(-100% - ${off.toFixed(0)}px)`;
                // Namensschrift an die Tokengröße koppeln: kleine Tokens (viele
                // Spieler) → kleinere, kürzere Namensboxen → deutlich weniger
                // Kollisionen an den Seitenbögen; große Tokens behalten große Namen.
                const nameFont = Math.round(Math.min(16, Math.max(10, diameter * 0.2)));
                const nameMax = Math.round(diameter * 2.1); // Box-Breite an Token koppeln
                return (
                  <span
                    className="dom-token-name"
                    title={seat.name || `#${seat.id}`}
                    style={
                      { "--ny": ny, fontSize: `${nameFont}px`, maxWidth: `${nameMax}px` } as CSSProperties
                    }
                  >
                    {seat.name || `#${seat.id}`}
                  </span>
                );
              })()}
              {/* C) Status-Siegel als BOGEN knapp AUSSERHALB des Tokens, auf der
                  ÄUSSEREN Seite (vom Zentrum weg), gegenüber dem Namen. Jedes Siegel
                  sitzt einzeln auf einem Kreisbogen (Radius r + Lücke + Siegel/2);
                  der Winkelbereich ist gekappt, damit auch 3–4 Siegel im Tortenstück
                  des Tokens bleiben und nicht in den Nachbarn ragen. */}
              {(() => {
                const a = seatAngles[i] ?? -Math.PI / 2; // Außen-Richtung
                const items = [
                  ...seat.markerIcons.map((k) => ({ kind: "icon" as const, val: k })),
                  ...seat.markers.filter(isTextMarker).map((m) => ({ kind: "text" as const, val: m }))
                ];
                if (items.length === 0) return null;
                const seal = Math.min(34, Math.max(15, Math.round(diameter * 0.24)));
                // Bogenradius so groß, dass selbst die Box-ECKE (halbe Diagonale ≈
                // 0.71·seal) noch ~8px außerhalb des Kreises liegt.
                const R = diameter / 2 + 8 + 0.71 * seal;
                const stepA = (seal * 1.2) / R; // ~Siegelbreite Abstand entlang des Bogens
                const span = Math.min((items.length - 1) * stepA, 1.66); // ≤ ~95°
                const s = items.length > 1 ? span / (items.length - 1) : 0;
                return items.map((it, j) => {
                  const ang = a + (j - (items.length - 1) / 2) * s;
                  const x = Math.cos(ang) * R;
                  const y = Math.sin(ang) * R;
                  return (
                    <div
                      key={`${it.kind}${j}-${it.val}`}
                      className="dom-token-seal"
                      style={
                        {
                          "--sx": `${x.toFixed(1)}px`,
                          "--sy": `${y.toFixed(1)}px`,
                          "--seal": `${seal}px`
                        } as CSSProperties
                      }
                    >
                      {it.kind === "icon" ? (
                        <img className="dom-token-marker" src={markerSealUrl(it.val)} alt={it.val} title={it.val} />
                      ) : (
                        <span className="dom-token-marker dom-token-marker--text">{it.val}</span>
                      )}
                    </div>
                  );
                });
              })()}
            </div>
          );
        })}
    </div>
  );
}
