// touch-tooltips.js — Phase 3: Rollen-Beschreibung per Long-Press auf Touch erreichbar.
// Reine View-Interaktion: ruft nur vorhandene Funktionen (showRoleInfoPopup/getRoleDescription/getRoleName).
// Ändert KEINE Spiellogik, kein State, kein Renderer. Hover-Tooltip (Maus) bleibt unverändert.
(function () {
  "use strict";
  var LONG_MS = 480;
  var timer = null, fired = false, startX = 0, startY = 0;

  function roleInfo(role) {
    if (!role) return;
    var desc = window.getRoleDescription ? window.getRoleDescription(role)
      : ((window.ROLE_DESCRIPTIONS && window.ROLE_DESCRIPTIONS[role]) || "");
    var name = window.getRoleName ? window.getRoleName(role) : role;
    if (typeof window.showRoleInfoPopup === "function") window.showRoleInfoPopup(name, desc || "");
  }

  function slotFrom(target) {
    if (!target || !target.closest) return null;
    if (target.closest(".info-btn")) return null;          // ❓ liefert die Info bereits
    return target.closest("#order .slot[data-role]");
  }

  document.addEventListener("touchstart", function (e) {
    var slot = slotFrom(e.target);
    if (!slot) return;
    var t = e.touches && e.touches[0];
    startX = t ? t.clientX : 0; startY = t ? t.clientY : 0;
    fired = false;
    if (timer) clearTimeout(timer);
    timer = setTimeout(function () { fired = true; roleInfo(slot.getAttribute("data-role")); }, LONG_MS);
  }, { passive: true });

  document.addEventListener("touchmove", function (e) {
    if (!timer) return;
    var t = e.touches && e.touches[0];
    if (t && (Math.abs(t.clientX - startX) > 10 || Math.abs(t.clientY - startY) > 10)) {
      clearTimeout(timer); timer = null;
    }
  }, { passive: true });

  document.addEventListener("touchend", function (e) {
    if (timer) { clearTimeout(timer); timer = null; }
    if (fired) { try { e.preventDefault(); } catch (_) {} fired = false; }  // unterdrückt den Folge-Click (Fähigkeit)
  }, { passive: false });

  document.addEventListener("touchcancel", function () {
    if (timer) { clearTimeout(timer); timer = null; }
    fired = false;
  }, { passive: true });
})();
