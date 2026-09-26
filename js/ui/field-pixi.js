// field-pixi.js — Pixi-Renderer für das Spielfeld (Phase 2b: Premium-Optik).
// Liest AUSSCHLIESSLICH aus dem ViewModel (getFieldViewModel). Kein Spielzustand, keine Regeln.
// Sitz-Tokens als in Pixi gezeichnete Medaillons (keine neuen Bild-Assets), Namen umbrechend/skalierend,
// dezente Ticker-Animationen (Puls/Tod/Tag-Nacht), Vignette. Render-on-demand: Szene nur bei State-Change neu;
// der Ticker animiert nur bestehende Objekte und ruft NIE Spiel-Logik/Sieg-Check.
// Pixi lokal vendored (js/vendor/pixi.min.js), kein CDN zur Laufzeit.
(function () {
  "use strict";

  var app = null, washLayer = null, world = null, fxLayer = null, vignette = null;
  var hostEl = null, svgEl = null;
  var lastGeom = null, lastVM = null, failed = false;
  var curW = 0, curH = 0;

  // Animation
  var myTicker = null, tickerOn = false, dirty = false, time = 0, renderCount = 0;
  var tokens = [];                 // pro Render neu: animierbare Token-Refs
  var prevDeadIds = null;          // Set: welche Sitze waren beim letzten Render tot
  var prevDark = undefined;
  var washTint = 0x0a1840, washAlpha = 0.0, washTargetTint = 0x0a1840, washTargetAlpha = 0.0;
  var DEATH_DUR = 0.55;

  // Caches
  var frameTexCache = {};          // Fraktions-Rahmen-Textur je Fraktion (Gold + Bezel + Verzierung)
  var backingTexCache = {};        // Fraktions-Backing-Scheibe (Fallback ohne Portrait)
  var glowTexCache = null;         // weiße Radial-Glow-Textur (additiv getintet)
  var vignetteTex = null, vignetteSize = "";
  // Portraits (optional, später droppbar): Manifest steuert Verfügbarkeit -> kein 404-Spam.
  var portraitManifest;            // undefined=nicht angefragt, null=läuft, Set=fertig
  var portraitCache = {};          // roleKey -> Texture | null(läuft) | false(fehlt)

  // ---- Fraktionsfarben ----
  var COL_WOLF = 0xff4a4a, COL_SOLO = 0xb14cff, COL_DORF = 0x4fb4ff, COL_NONE = 0x616ff5;
  var COL_DEAD = 0xf85a7a, COL_PULSE = 0xffd54a;
  function factionColor(seat) {
    if (!seat.hasRole) return COL_NONE;
    if (seat.faction === "wolf") return COL_WOLF;
    if (seat.faction === "solo") return COL_SOLO;
    return COL_DORF;
  }

  function pixiPresent() { return typeof PIXI !== "undefined" && !failed; }
  function hexToNum(h) {
    if (typeof h === "number") return h;
    if (!h) return 0xffffff;
    return parseInt(String(h).replace("#", ""), 16) || 0xffffff;
  }
  function lerpColor(a, b, t) {
    var ar = (a >> 16) & 255, ag = (a >> 8) & 255, ab = a & 255;
    var br = (b >> 16) & 255, bg = (b >> 8) & 255, bb = b & 255;
    return ((Math.round(ar + (br - ar) * t) << 16) | (Math.round(ag + (bg - ag) * t) << 8) | Math.round(ab + (bb - ab) * t));
  }
  function smooth(t) { t = Math.max(0, Math.min(1, t)); return t * t * (3 - 2 * t); }
  function isFileProto() { try { return document.documentElement.classList.contains("grimm-file-protocol"); } catch (e) { return false; } }
  function nameFamily() { return isFileProto() ? "Cinzel" : "Fondamento"; }

  // ---- Geometrie (responsiv) ----
  function minNeighborDist(rx, ry, n) {
    var d = 2 * Math.PI / n, m = Infinity;
    for (var t = 0; t < Math.PI * 2; t += Math.PI / 90) {
      var x1 = rx * Math.cos(t), y1 = ry * Math.sin(t);
      var x2 = rx * Math.cos(t + d), y2 = ry * Math.sin(t + d);
      var dist = Math.hypot(x2 - x1, y2 - y1);
      if (dist < m) m = dist;
    }
    return m;
  }
  // Reserviert unter jedem Token Platz für die Nameplate (Überhang ~PLATE_OVER*r nach unten)
  // und vergrößert den Nachbarabstand, damit Plates sich nicht überlappen. Liefert zusätzlich
  // 'neigh' (Nachbarabstand) für die maximale Plate-Breite.
  function computeFieldGeometry(W, H, n) {
    var pad = 14, gap = 10, seatMin = 14, seatMax = 104;
    var PLATE_OVER = 1.4;      // vertikaler Reserve-Faktor: Plate-Höhe (bis 2 Zeilen) unter dem Token
    var cx = W / 2;
    var lo = seatMin, hi = seatMax, best = seatMin, rxB = 10, ryB = 10, cyB = H / 2;
    for (var step = 0; step < 28; step++) {
      var mid = (lo + hi) / 2;
      var topMargin = pad + mid;
      var botMargin = pad + mid + PLATE_OVER * mid;
      var cy = (topMargin + (H - botMargin)) / 2;
      var ry = Math.min(cy - topMargin, (H - botMargin) - cy);
      var rx = (W / 2 - pad) - mid;
      var need = 2 * mid + gap + 0.7 * mid;          // horizontaler Nachbarabstand (Plate-Raum, moderat)
      if (rx > 8 && ry > 8 && minNeighborDist(rx, ry, n) >= need) { best = mid; rxB = rx; ryB = ry; cyB = cy; lo = mid; }
      else hi = mid;
    }
    var seatR = Math.max(seatMin, Math.min(best, seatMax));
    return { cx: cx, cy: cyB, seatR: seatR, rx: rxB, ry: ryB, W: W, H: H, neigh: minNeighborDist(rxB, ryB, n) };
  }

  // ---- Texturen ----
  // Metallischer Medaillon-Rahmen + dunkler Kern (fraktionsneutral; Fraktion via Rim/Glow).
  function hexA(hex, a) { var n = parseInt(String(hex).replace("#", ""), 16); return "rgba(" + ((n >> 16) & 255) + "," + ((n >> 8) & 255) + "," + (n & 255) + "," + a + ")"; }
  function factionBezelHex(f) { return f === "wolf" ? "#ff5a5a" : f === "solo" ? "#c06bff" : f === "dorf" ? "#5ab6ff" : "#8189bd"; }
  function factionBackHex(f) { return f === "wolf" ? "#3a1414" : f === "solo" ? "#2a153f" : f === "dorf" ? "#122a4a" : "#1a1d3a"; }

  // Fraktions-Rahmen: Gold-Metallring + farbiger Innen-Bezel + Nieten-Verzierung. KERN TRANSPARENT
  // (Innenleben/Backing/Portrait wird separat dahinter gezeichnet). Eine 256px-Textur je Fraktion,
  // als Sprite auf 2*r skaliert -> max. wenige gecachte Texturen.
  function makeFrameTexture(faction) {
    var d = 256, c = document.createElement("canvas"); c.width = c.height = d;
    var ctx = c.getContext("2d"), x = d / 2, R = d / 2;
    var coreR = R * 0.78, ringMid = (coreR + R) / 2, ringW = (R - coreR);
    var fc = factionBezelHex(faction);
    // Farbiger Bezel-Glühring knapp innerhalb des Golds
    var bez = ctx.createRadialGradient(x, x, coreR * 0.80, x, x, coreR * 1.08);
    bez.addColorStop(0, hexA(fc, 0)); bez.addColorStop(0.65, hexA(fc, 0)); bez.addColorStop(1, hexA(fc, 0.55));
    ctx.fillStyle = bez; ctx.beginPath(); ctx.arc(x, x, coreR * 1.08, 0, Math.PI * 2); ctx.fill();
    ctx.lineWidth = Math.max(2, d * 0.016); ctx.strokeStyle = fc; ctx.globalAlpha = 0.9;
    ctx.beginPath(); ctx.arc(x, x, coreR + ringW * 0.12, 0, Math.PI * 2); ctx.stroke(); ctx.globalAlpha = 1;
    // Gold-Ring (Metall-Sheen)
    ctx.lineWidth = ringW; ctx.strokeStyle = "#16110a";
    ctx.beginPath(); ctx.arc(x, x, ringMid, 0, Math.PI * 2); ctx.stroke();
    var lg = ctx.createLinearGradient(0, 0, d, d);
    lg.addColorStop(0, "#f3dca0"); lg.addColorStop(0.28, "#cba85f"); lg.addColorStop(0.5, "#7e6330");
    lg.addColorStop(0.72, "#c4a258"); lg.addColorStop(1, "#4f3e1c");
    ctx.lineWidth = ringW * 0.6; ctx.strokeStyle = lg;
    ctx.beginPath(); ctx.arc(x, x, ringMid, 0, Math.PI * 2); ctx.stroke();
    // feine Kanten
    ctx.lineWidth = Math.max(1, d * 0.008); ctx.strokeStyle = "rgba(255,244,210,0.30)";
    ctx.beginPath(); ctx.arc(x, x, coreR + ringW * 0.16, 0, Math.PI * 2); ctx.stroke();
    ctx.strokeStyle = "rgba(0,0,0,0.55)";
    ctx.beginPath(); ctx.arc(x, x, R - Math.max(1, d * 0.012), 0, Math.PI * 2); ctx.stroke();
    // Glanzbogen oben links
    ctx.lineWidth = ringW * 0.5; ctx.strokeStyle = "rgba(255,248,225,0.40)";
    ctx.beginPath(); ctx.arc(x, x, ringMid, Math.PI * 1.02, Math.PI * 1.5); ctx.stroke();
    // Verzierung: Nieten rundum
    var studs = 12;
    for (var i = 0; i < studs; i++) {
      var a = (i / studs) * Math.PI * 2, sx = x + Math.cos(a) * ringMid, sy = x + Math.sin(a) * ringMid;
      ctx.beginPath(); ctx.arc(sx, sy, Math.max(1.2, d * 0.012), 0, Math.PI * 2); ctx.fillStyle = "#3a2c12"; ctx.fill();
      ctx.beginPath(); ctx.arc(sx - d * 0.004, sy - d * 0.004, Math.max(0.8, d * 0.007), 0, Math.PI * 2); ctx.fillStyle = "rgba(255,240,200,0.7)"; ctx.fill();
    }
    return PIXI.Texture.from(c);
  }
  function frameTexture(faction) {
    var k = faction || "dorf";
    if (!frameTexCache[k]) frameTexCache[k] = makeFrameTexture(k);
    return frameTexCache[k];
  }
  // Fraktions-Backing (dunkle Scheibe mit Fraktions-Tönung) — Fallback ohne Portrait.
  function makeBackingTexture(faction) {
    var d = 160, c = document.createElement("canvas"); c.width = c.height = d;
    var ctx = c.getContext("2d"), x = d / 2;
    var g = ctx.createRadialGradient(x * 0.82, x * 0.74, d * 0.05, x, x, x);
    g.addColorStop(0, "#272036"); g.addColorStop(0.55, factionBackHex(faction)); g.addColorStop(1, "#0a0815");
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, x, x, 0, Math.PI * 2); ctx.fill();
    return PIXI.Texture.from(c);
  }
  function backingTexture(faction) {
    var k = faction || "dorf";
    if (!backingTexCache[k]) backingTexCache[k] = makeBackingTexture(k);
    return backingTexCache[k];
  }

  // ---- Pro-Rollen-Portraits (optional, später ohne Code-Änderung droppbar) ----
  // SPEC: Datei  assets/portraits/<roleKey>.webp , quadratisch ~512x512, einheitlicher Ausschnitt
  // (zentrierte Büste/Gesicht, gleicher Maßstab je Rolle). Wird auf den Innenkreis maskiert.
  // roleKey = roleRaw kleingeschrieben, ä/ö/ü/ß -> ae/oe/ue/ss, alles Nicht-[a-z0-9] -> "-".
  // Beispiel: "König Lykaon" -> "koenig-lykaon".
  // Verfügbarkeit wird über  assets/portraits/manifest.json  (JSON-Array von roleKeys) gesteuert,
  // damit fehlende Portraits KEINE 404-Konsolenfehler erzeugen. Portrait hinzufügen:
  //   1) <roleKey>.webp nach assets/portraits/ legen
  //   2) "<roleKey>" in manifest.json eintragen  -> erscheint automatisch im Token.
  function roleKey(roleRaw) {
    return String(roleRaw || "").toLowerCase()
      .replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss")
      .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
  }
  function requestReRender() { if (lastVM) { try { render(lastVM); } catch (e) {} } }
  function ensurePortraitManifest() {
    if (portraitManifest !== undefined) return;
    portraitManifest = null;
    try {
      fetch("assets/portraits/manifest.json", { cache: "no-cache" })
        .then(function (r) { return r.ok ? r.json() : []; })
        .then(function (list) {
          portraitManifest = new Set((Array.isArray(list) ? list : []).map(String));
          if (portraitManifest.size) requestReRender();
        })
        .catch(function () { portraitManifest = new Set(); });
    } catch (e) { portraitManifest = new Set(); }
  }
  function getPortraitTexture(seat) {
    if (!seat.hasRole) return null;
    if (!(portraitManifest instanceof Set) || portraitManifest.size === 0) return null;
    var k = roleKey(seat.roleRaw);
    if (!portraitManifest.has(k)) return null;
    var ent = portraitCache[k];
    if (ent === undefined) {
      portraitCache[k] = null;
      var img = new Image();
      img.onload = function () { try { portraitCache[k] = PIXI.Texture.from(img); requestReRender(); } catch (e) { portraitCache[k] = false; } };
      img.onerror = function () { portraitCache[k] = false; };
      img.src = "assets/portraits/" + k + ".webp";
      return null;
    }
    return ent || null;
  }
  function whiteGlowTexture() {
    if (glowTexCache) return glowTexCache;
    var d = 128, c = document.createElement("canvas"); c.width = c.height = d;
    var ctx = c.getContext("2d");
    var g = ctx.createRadialGradient(d / 2, d / 2, d * 0.08, d / 2, d / 2, d / 2);
    g.addColorStop(0, "rgba(255,255,255,0.9)"); g.addColorStop(0.5, "rgba(255,255,255,0.32)"); g.addColorStop(1, "rgba(255,255,255,0)");
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(d / 2, d / 2, d / 2, 0, Math.PI * 2); ctx.fill();
    glowTexCache = PIXI.Texture.from(c); return glowTexCache;
  }
  function makeVignetteTexture(W, H) {
    var c = document.createElement("canvas"); c.width = Math.max(2, W); c.height = Math.max(2, H);
    var ctx = c.getContext("2d"), Rr = Math.max(W, H) * 0.78;
    var g = ctx.createRadialGradient(W / 2, H / 2, Rr * 0.42, W / 2, H / 2, Rr);
    g.addColorStop(0, "rgba(0,0,0,0)"); g.addColorStop(0.75, "rgba(0,0,0,0.10)"); g.addColorStop(1, "rgba(0,0,0,0.52)");
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
    return PIXI.Texture.from(c);
  }

  // ---- Text (Schritt 1: skalieren + bis 2 Zeilen umbrechen, Ellipse nur als Notlösung) ----
  function measureStr(str, family, weight, size, maxW, ls, wrap, brk) {
    var st = new PIXI.TextStyle({ fontFamily: family, fontWeight: String(weight), fontSize: size, letterSpacing: ls || 0, wordWrap: !!wrap, wordWrapWidth: maxW, breakWords: !!brk, align: "center" });
    return PIXI.TextMetrics.measureText(String(str || ""), st);
  }
  // Notlösung: harter Umbruch (breakWords) + Ellipse, nur wenn nichts anderes passt.
  function layoutWrapFallback(str, family, weight, maxW, maxLines, minSize, ls) {
    var size = Math.max(7, Math.round(minSize));
    var m = measureStr(str, family, weight, size, maxW, ls, true, true), text = String(str || "");
    if (m.lines.length > maxLines) {
      var kept = m.lines.slice(0, maxLines), last = kept[maxLines - 1];
      kept[maxLines - 1] = (last.length > 1 ? last.slice(0, last.length - 1) : last) + "…";
      text = kept.join("\n");
    }
    return { size: size, text: text, wrap: true };
  }
  // Bevorzugt EINE Zeile (Schrift verkleinern); mehrwortige Namen brechen sauber am Leerzeichen
  // auf 2 Zeilen, wenn das mehr Größe bringt. Wort-interner Bruch ("Nachtw/ächter") nur als Notlösung.
  function layoutLabel(str, family, weight, maxW, maxSize, minSize, ls) {
    str = String(str == null ? "" : str).trim();
    if (!str) return { size: Math.round(minSize), text: "", wrap: false };
    var m1 = measureStr(str, family, weight, maxSize, maxW, ls, false, false);
    var sizeOne = m1.width <= maxW ? Math.round(maxSize) : Math.max(Math.round(minSize), Math.floor(maxSize * maxW / Math.max(1, m1.width)));
    var hasSpace = /\s/.test(str);
    if (!hasSpace) {
      var mMin = measureStr(str, family, weight, Math.round(minSize), maxW, ls, false, false);
      if (mMin.width <= maxW) return { size: sizeOne, text: str, wrap: false };
      return layoutWrapFallback(str, family, weight, maxW, 2, minSize, ls);
    }
    var lo = Math.max(7, Math.round(minSize)), hi = Math.max(lo, Math.round(maxSize)), best2 = lo, ok2 = false;
    while (lo <= hi) {
      var mid = (lo + hi) >> 1, mm = measureStr(str, family, weight, mid, maxW, ls, true, false);
      if (mm.lines.length <= 2 && mm.width <= maxW) { best2 = mid; ok2 = true; lo = mid + 1; } else hi = mid - 1;
    }
    if (ok2 && best2 >= sizeOne * 1.18) return { size: best2, text: str, wrap: true };
    if (sizeOne >= Math.round(minSize)) return { size: sizeOne, text: str, wrap: false };
    if (ok2) return { size: best2, text: str, wrap: true };
    return layoutWrapFallback(str, family, weight, maxW, 2, minSize, ls);
  }
  function makeLabel(layout, family, weight, fill, ls, maxW) {
    return layout.wrap
      ? makeWrappedText(layout.text, family, weight, layout.size, fill, ls, maxW)
      : makeText(layout.text, family, weight, layout.size, fill, ls, 0.5, 0.5);
  }
  function makeWrappedText(str, family, weight, sizePx, fill, ls, maxW) {
    var style = new PIXI.TextStyle({
      fontFamily: family, fontWeight: String(weight), fontSize: sizePx, fill: fill,
      letterSpacing: ls || 0, align: "center", wordWrap: true, wordWrapWidth: maxW, breakWords: true
    });
    var t = new PIXI.Text(String(str == null ? "" : str), style);
    t.resolution = Math.max(2, window.devicePixelRatio || 1);
    t.anchor.set(0.5, 0.5);
    return t;
  }
  function makeText(str, family, weight, sizePx, fill, ls, ax, ay) {
    var style = new PIXI.TextStyle({ fontFamily: family, fontWeight: String(weight), fontSize: sizePx, fill: fill, letterSpacing: ls || 0, align: "center" });
    var t = new PIXI.Text(String(str == null ? "" : str), style);
    t.resolution = Math.max(2, window.devicePixelRatio || 1);
    t.anchor.set(ax == null ? 0.5 : ax, ay == null ? 0.5 : ay);
    return t;
  }

  // ---- App / Layer ----
  function ensureApp() {
    if (app) return app;
    if (typeof PIXI === "undefined") return null;
    try {
      hostEl = document.querySelector("main.stage");
      svgEl = document.getElementById("stage");
      if (!hostEl) return null;
      app = new PIXI.Application({ backgroundAlpha: 0, antialias: true, resolution: window.devicePixelRatio || 1, autoDensity: true, autoStart: false });
      var cv = app.view;
      cv.style.position = "absolute"; cv.style.pointerEvents = "auto"; cv.style.zIndex = "1";
      hostEl.appendChild(cv);
      if (svgEl) svgEl.style.pointerEvents = "none";
      washLayer = new PIXI.Graphics();
      world = new PIXI.Container();
      fxLayer = new PIXI.Container();
      app.stage.addChild(washLayer, world, fxLayer);
      myTicker = new PIXI.Ticker(); myTicker.autoStart = false; myTicker.add(tick);
      return app;
    } catch (e) {
      failed = true; app = null;
      try { console.warn("[Grimmhain] Pixi-Init fehlgeschlagen, SVG-Fallback:", e); } catch (_) {}
      return null;
    }
  }

  function placeCanvas() {
    if (!app || !svgEl || !hostEl) return { W: 0, H: 0 };
    var sb = svgEl.getBoundingClientRect(), hb = hostEl.getBoundingClientRect();
    var W = Math.max(1, Math.round(sb.width)), H = Math.max(1, Math.round(sb.height));
    var cv = app.view;
    cv.style.left = (sb.left - hb.left) + "px"; cv.style.top = (sb.top - hb.top) + "px";
    cv.style.width = W + "px"; cv.style.height = H + "px";
    if (app.renderer && (app.renderer.width !== W || app.renderer.height !== H)) app.renderer.resize(W, H);
    return { W: W, H: H };
  }

  function ensureTicker() { if (myTicker && !tickerOn) { tickerOn = true; myTicker.start(); } }
  function updateWash() { if (!washLayer) return; washLayer.clear(); if (washAlpha > 0.003) { washLayer.beginFill(washTint, washAlpha); washLayer.drawRect(0, 0, curW, curH); washLayer.endFill(); } }
  function setDayNightTarget(dark) { if (dark) { washTargetTint = 0x0a1840; washTargetAlpha = 0.22; } else { washTargetTint = 0x140d04; washTargetAlpha = 0.05; } }

  function ensureVignette() {
    if (!fxLayer) return;
    var key = curW + "x" + curH;
    if (vignetteSize !== key) {
      vignetteSize = key; vignetteTex = makeVignetteTexture(curW, curH);
      if (!vignette) { vignette = new PIXI.Sprite(vignetteTex); vignette.eventMode = "none"; fxLayer.addChild(vignette); }
      else vignette.texture = vignetteTex;
      vignette.width = curW; vignette.height = curH; vignette.position.set(0, 0);
    }
  }

  // ---- Token (Medaillon) ----
  // Verzierte Nameplate UNTER dem Token: R-Nummer + Name auf einer Banner-Plate.
  // Breite passt sich dem Text an (geclippt auf Nachbarabstand). Liefert __h (Höhe) und __strike.
  function buildNameplate(seat, g) {
    var r = g.seatR;
    var maxW = Math.max(2 * r, (g.neigh || 2.4 * r) * 0.92);
    var nameMaxW = maxW - r * 0.5;
    var nl = layoutLabel(seat.name && seat.name.trim() ? seat.name : "—", "Cinzel", 700, nameMaxW, r * 0.40, r * 0.18, 0.5);
    var nameT = makeLabel(nl, "Cinzel", 700, seat.dead ? 0xcaa9b5 : 0xf3e3b6, 0.5, nameMaxW);
    var numT = makeText("R" + seat.id, "Cinzel", 700, Math.max(9, r * 0.22), 0xcba85f, 1, 0.5, 0.5);

    var contentW = Math.max(numT.width, nameT.width);
    var plateW = Math.min(maxW, contentW + r * 0.55);
    var padV = r * 0.15;
    var plateH = padV * 2 + numT.height + nameT.height + r * 0.04;
    var rad = Math.min(plateH * 0.34, r * 0.2);

    var np = new PIXI.Container();
    var bg = new PIXI.Graphics();
    bg.beginFill(0x000000, 0.35); bg.drawRoundedRect(-plateW / 2 - 2, -plateH / 2 + 3, plateW + 4, plateH, rad); bg.endFill();
    bg.beginFill(0x0d0a18, 0.96); bg.lineStyle(Math.max(1.5, r * 0.028), 0xcba85f, 0.9);
    bg.drawRoundedRect(-plateW / 2, -plateH / 2, plateW, plateH, rad); bg.endFill();
    bg.lineStyle(Math.max(1, r * 0.012), 0x8a6e32, 0.55);
    bg.drawRoundedRect(-plateW / 2 + r * 0.06, -plateH / 2 + r * 0.06, plateW - r * 0.12, plateH - r * 0.12, Math.max(1, rad - r * 0.06));
    np.addChild(bg);
    // Ornament-Rauten an den Enden
    [-1, 1].forEach(function (sgn) {
      var orn = new PIXI.Graphics(); orn.beginFill(0xcba85f, 0.95);
      var ox = sgn * (plateW / 2), s = Math.max(3, r * 0.10);
      orn.moveTo(ox, -s); orn.lineTo(ox + sgn * s, 0); orn.lineTo(ox, s); orn.lineTo(ox - sgn * s, 0); orn.closePath(); orn.endFill();
      np.addChild(orn);
    });
    numT.position.set(0, -plateH / 2 + padV + numT.height / 2);
    nameT.position.set(0, numT.position.y + numT.height / 2 + nameT.height / 2 + r * 0.02);
    np.addChild(numT); np.addChild(nameT);

    var strike = null;
    if (seat.dead) {
      strike = new PIXI.Graphics(); strike.lineStyle(Math.max(1.5, r * 0.04), 0xf7a1b5, 0.95);
      var w2 = Math.max(8, nameT.width / 2); strike.moveTo(-w2, 0); strike.lineTo(w2, 0);
      strike.position.set(0, nameT.position.y); np.addChild(strike);
    }
    np.__h = plateH; np.__strike = strike;
    return np;
  }

  function buildSeat(seat, g) {
    var c = new PIXI.Container();
    c.eventMode = "static"; c.cursor = "pointer";
    var r = g.seatR, col = factionColor(seat), living = seat.hasRole && !seat.dead;
    var fkey = seat.hasRole ? seat.faction : "none";
    var coreR = r * 0.78;

    // Glow (additiv, hinter allem — kein Live-Filter)
    var glow = new PIXI.Sprite(whiteGlowTexture());
    glow.anchor.set(0.5); glow.width = glow.height = 2 * r * 1.5;
    glow.tint = seat.dead ? COL_DEAD : col;
    glow.blendMode = PIXI.BLEND_MODES.ADD;
    glow.alpha = living ? 0.10 : 0.0;
    c.addChild(glow);

    // Innenleben: Portrait (auf Kreis maskiert) ODER Fraktions-Backing (Scheibe, ohne Maske).
    var portraitTex = getPortraitTexture(seat);
    if (portraitTex) {
      var pf = new PIXI.Sprite(portraitTex); pf.anchor.set(0.5);
      var tw = (portraitTex.width || 1), th = (portraitTex.height || 1);
      var sc = (2 * coreR) / Math.min(tw, th);     // cover-fit auf den Kreis
      pf.scale.set(sc);
      var pmask = new PIXI.Graphics(); pmask.beginFill(0xffffff); pmask.drawCircle(0, 0, coreR); pmask.endFill();
      c.addChild(pmask); pf.mask = pmask; c.addChild(pf);
    } else {
      var back = new PIXI.Sprite(backingTexture(fkey)); back.anchor.set(0.5);
      back.width = back.height = 2 * coreR; c.addChild(back);
    }

    // Fraktions-Rahmen (Kern transparent), 256px-Textur auf 2*r skaliert
    var frame = new PIXI.Sprite(frameTexture(fkey));
    frame.anchor.set(0.5); frame.width = frame.height = 2 * r;
    c.addChild(frame);

    // Rim-Akzent: normal unsichtbar, gelb bei Puls (Auswahl)
    var rim = new PIXI.Graphics();
    rim.lineStyle(Math.max(1.5, r * 0.05), seat.pulse ? COL_PULSE : col, seat.pulse ? 0.95 : 0);
    rim.drawCircle(0, 0, coreR);
    c.addChild(rim);

    // Tod-Ring (gestrichelt)
    var deadRing = null;
    if (seat.dead) {
      deadRing = new PIXI.Graphics();
      var segs = 26, rr = coreR;
      deadRing.lineStyle(Math.max(2, r * 0.05), COL_DEAD, 0.9);
      for (var s = 0; s < segs; s++) {
        var a0 = (s / segs) * Math.PI * 2, a1 = a0 + (Math.PI * 2 / segs) * 0.55;
        deadRing.moveTo(Math.cos(a0) * rr, Math.sin(a0) * rr);
        deadRing.arc(0, 0, rr, a0, a1);
      }
      c.addChild(deadRing);
    }

    // Marker (kleine Status-Icons, zentrierte Reihe am oberen Rand)
    if (seat.markers && seat.markers.length) {
      var mk = Math.max(13, r * 0.42), step = mk * 0.62;
      var startX = -(seat.markers.length - 1) * step / 2;
      seat.markers.forEach(function (m, k) {
        var mt = makeText(m, nameFamily(), 400, mk, 0xffffff, 0, 0.5, 0.5);
        mt.position.set(startX + k * step, -r * 1.02); c.addChild(mt);
      });
    }

    // Nameplate unter dem Token
    var np = buildNameplate(seat, g);
    np.position.set(0, r + Math.max(5, r * 0.12) + np.__h / 2);
    c.addChild(np);

    c.on("pointertap", function () {
      if (typeof fieldOnSeatClick === "function") fieldOnSeatClick(seat.id, seat.index, c.__x, c.__y, r);
    });

    var tk = {
      id: seat.id, container: c, frame: frame, glow: glow, rim: rim,
      deadRing: deadRing, nameStrike: np.__strike, col: col, living: living,
      pulse: !!seat.pulse, dead: !!seat.dead, glowBase: living ? 0.10 : 0.0,
      deathT: -1
    };
    return tk;
  }

  function applyDeath(tk, e) {
    tk.container.alpha = 1 - 0.45 * e;
    if (tk.frame) tk.frame.tint = lerpColor(0xffffff, 0x6e6e78, e);
    if (tk.nameStrike) tk.nameStrike.scale.x = e;
    if (tk.deadRing) tk.deadRing.alpha = 0.9 * e;
    if (tk.rim) tk.rim.alpha = (tk.pulse ? 0.95 : 0) * (1 - e);
    if (tk.glow) tk.glow.alpha = 0.08 * (1 - e);
  }

  function buildDeathCard(seat, g, sx, sy) {
    var dc = seat.deathCard, r = g.seatR;
    var farbe = hexToNum(dc.color || "#d4af37"), played = !!dc.played;
    var dcx = g.cx - sx, dcy = g.cy - sy, dist = Math.sqrt(dcx * dcx + dcy * dcy) || 1;
    var nx = dcx / dist, ny = dcy / dist, cardDist = r * 2.5;
    var btn = new PIXI.Container();
    btn.position.set(nx * cardDist, ny * cardDist); btn.alpha = played ? 0.35 : 1;
    var w = r * 1.80, h = r * 0.48, rad = r * 0.10;
    var bg = new PIXI.Graphics();
    bg.beginFill(0x0d0820, 0.96); bg.drawRoundedRect(-w / 2, -h / 2, w, h, rad); bg.endFill();
    bg.lineStyle(Math.max(2, r * 0.03), farbe, 1); bg.drawRoundedRect(-w / 2, -h / 2, w, h, rad);
    btn.addChild(bg);
    var label = (lastVM && lastVM.deathCardLabel) ? lastVM.deathCardLabel : "🎴 Totenkarte";
    var t = makeText(label, "Cinzel", 700, Math.max(11, r * 0.19), farbe, 0, 0.5, 0.5);
    btn.addChild(t);
    if (!played) {
      btn.eventMode = "static"; btn.cursor = "pointer";
      btn.on("pointertap", function (ev) {
        if (ev && ev.stopPropagation) ev.stopPropagation();
        if (typeof fieldPlayDeathCard === "function") fieldPlayDeathCard(seat.id);
      });
    }
    return btn;
  }

  // ---- Ticker: animiert NUR bestehende Objekte (kein State, kein Sieg-Check) ----
  function tick() {
    var dt = Math.min(0.05, (myTicker.deltaMS || 16) / 1000);
    time += dt;
    var active = false;

    if (Math.abs(washAlpha - washTargetAlpha) > 0.002 || washTint !== washTargetTint) {
      washTint = washTargetTint;
      washAlpha += (washTargetAlpha - washAlpha) * Math.min(1, dt * 4);
      if (Math.abs(washAlpha - washTargetAlpha) <= 0.002) washAlpha = washTargetAlpha; else active = true;
      updateWash();
    }

    for (var i = 0; i < tokens.length; i++) {
      var tk = tokens[i];
      if (tk.deathT >= 0 && tk.deathT < 1) { tk.deathT = Math.min(1, tk.deathT + dt / DEATH_DUR); applyDeath(tk, smooth(tk.deathT)); active = true; }
      if (tk.pulse) {
        var s = 0.5 + 0.5 * Math.sin(time * 5);
        tk.glow.alpha = 0.25 + 0.55 * s;
        if (tk.rim) tk.rim.alpha = 0.55 + 0.45 * s;
        active = true;
      }
    }

    if (active || dirty) { try { app.renderer.render(app.stage); } catch (e) {} dirty = false; renderCount++; }
    if (!active && !dirty) { myTicker.stop(); tickerOn = false; }
  }

  function render(vm) {
    if (!ensureApp()) return null;
    lastVM = vm;
    var box = placeCanvas();
    curW = box.W; curH = box.H;
    var n = vm.seatCount, g = computeFieldGeometry(curW, curH, n);
    lastGeom = g;

    // Tag/Nacht-Ziel (weiche Überblendung im Ticker)
    setDayNightTarget(!!vm.dark);
    if (prevDark === undefined) { washTint = washTargetTint; washAlpha = washTargetAlpha; updateWash(); }
    prevDark = !!vm.dark;
    ensureVignette();
    ensurePortraitManifest();

    // Szene neu aufbauen
    world.removeChildren().forEach(function (ch) { try { ch.destroy({ children: true }); } catch (e) {} });
    tokens = [];

    var cen = new PIXI.Graphics(), er = Math.max(40, g.seatR * 1.2);
    cen.beginFill(0x141731, 0.16); cen.lineStyle(1, 0x5f67a8, 0.20); cen.drawEllipse(g.cx, g.cy, er, er); cen.endFill();
    cen.eventMode = "none"; world.addChild(cen);

    var startA = -Math.PI / 2;
    var nowDead = {};
    vm.seats.forEach(function (seat, i) {
      var ang = startA + i * (2 * Math.PI / n);
      var x = g.cx + Math.cos(ang) * g.rx, y = g.cy + Math.sin(ang) * g.ry;
      var tk = buildSeat(seat, g);
      tk.container.__x = x; tk.container.__y = y;
      tk.container.position.set(x, y);
      world.addChild(tk.container);
      tokens.push(tk);
      if (seat.dead) {
        nowDead[seat.id] = true;
        // Erst-Render (prevDeadIds===null): bestehende Tote ohne Animation einrasten.
        var wasDead = (prevDeadIds === null) || prevDeadIds.has(seat.id);
        tk.deathT = wasDead ? 1 : 0;          // neuer Tod -> animieren, sonst Endzustand
        applyDeath(tk, wasDead ? 1 : 0);
      }
      if (seat.deathCard) {
        var card = buildDeathCard(seat, g, x, y);
        card.position.set(x + card.position.x, y + card.position.y);
        world.addChild(card);
      }
    });
    prevDeadIds = new Set(Object.keys(nowDead).map(Number));

    dirty = true; ensureTicker();
    return g;
  }

  window.GrimmField = {
    available: function () { return pixiPresent() && !!ensureApp(); },
    render: function (vm) { try { return render(vm); } catch (e) { failed = true; try { console.warn("[Grimmhain] Pixi-Render fehlgeschlagen, SVG-Fallback:", e); } catch (_) {} return null; } },
    geometry: function () { return lastGeom; },
    resize: function () { if (lastVM) try { render(lastVM); } catch (e) {} },
    stats: function () { return { tickerOn: tickerOn, renders: renderCount }; }
  };
})();
