// field-viewmodel.js — Lese-API (State ↔ View-Naht, Phase 1)
// Liefert ein REINES Datenobjekt des Spielfelds: kein DOM, kein Renderer.
// Einzige Stelle, die für den Feld-Zeichenpfad Spiel-State/Logik/i18n liest.
// Der Renderer (renderField in ui.js) liest ausschließlich aus diesem ViewModel.
(function(){

  // Fraktion eines Sitzes (Domänenwissen, identisch zur bisherigen draw()-Logik).
  function fieldFaction(s){
    const wolfSet = (typeof WOLF_ROLES_SET !== "undefined") ? WOLF_ROLES_SET : null;
    const soloSet = (typeof SOLO_ROLES_SET !== "undefined") ? SOLO_ROLES_SET : null;
    const isWolfRole = (wolfSet && wolfSet.has(s.role)) || (s.flags && s.flags.werewolf) || (s.meta && s.meta.cursedWolfAura);
    if (isWolfRole) return "wolf";
    if (soloSet && soloSet.has(s.role)) return "solo";
    return "dorf";
  }

  function seatDisplayName(s){
    return s.name || (window.t ? window.t("freeSeat") : "— frei —");
  }

  function seatRoleDisplay(s){
    return s.role
      ? (window.getRoleName ? window.getRoleName(s.role) : s.role)
      : (window.t ? window.t("noRole") : "keine Rolle");
  }

  // Totenkarte-Button-Daten (nur für tote Sitze mit zugewiesener Karte).
  function seatDeathCard(s){
    try{
      if(!(s.flags && s.flags.dead)) return null;
      if(!(typeof state !== "undefined" && state && state.once && state.once.totenkarten)) return null;
      const data = state.once.totenkarten[s.id];
      if(!data) return null;
      const card = (typeof ALLE_KARTEN !== "undefined") ? ALLE_KARTEN.find(k => k.id === data.karteId) : null;
      const color = (typeof getKategorieColor === "function") ? getKategorieColor(card ? card.kategorie : "") : "#d4af37";
      return { color: color, played: !!data.gespielt };
    }catch(e){ return null; }
  }

  function getFieldViewModel(){
    const seatsSrc = (typeof state !== "undefined" && state && state.seats) ? state.seats : [];
    const pulseMap = window._pulseMap;

    const seats = seatsSrc.map(function(s, i){
      return {
        id: s.id,
        index: i,
        name: seatDisplayName(s),
        roleRaw: s.role || "",
        roleDisplay: seatRoleDisplay(s),
        hasRole: !!(s.role && s.role.trim()),
        dead: !!(s.flags && s.flags.dead),
        faction: fieldFaction(s),
        pulse: !!(pulseMap && pulseMap.has(s.id)),
        markers: (typeof markerList === "function") ? markerList(s) : [],
        deathCard: seatDeathCard(s)
      };
    });

    const once = (typeof state !== "undefined" && state && state.once) ? state.once : {};
    const hasLivingNekromant = seatsSrc.some(function(s){
      return s.role === "Nekromant" && !(s.flags && s.flags.dead);
    });

    return {
      dark: !!(typeof state !== "undefined" && state && state.dark),
      layout: Object.assign({ scale:100, ratio:120, offx:0, offy:0 },
        (typeof state !== "undefined" && state && state.layout) || {}),
      seatCount: Math.max(4, seatsSrc.length),
      deathCardLabel: "🎴 " + (window.t ? window.t("deathCard") : "Totenkarte"),
      hasLivingNekromant: hasLivingNekromant,
      nekromantRevealed: !!once.TotenratFuehrerRevealed,
      seats: seats
    };
  }

  window.getFieldViewModel = getFieldViewModel;
})();
