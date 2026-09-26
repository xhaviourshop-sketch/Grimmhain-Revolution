/** Escaped HTML für sichere innerHTML-Nutzung (Spielernamen, Kartentexte). */
function escapeHtml(s){
  if(s==null||s==="") return "";
  return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#39;");
}
window.escapeHtml = escapeHtml;

function isWolf(seat){
  if(!seat) return false;
  const role=(seat.role||"")+"";
  const meta=seat.meta||{};
  const flags=seat.flags||{};
  if(role==="Doppelspion"||role==="Manipulator"||role==="Parasit"||role==="Grabräuber"||role==="Todesprediger") return false;
  // Authoritative: WOLF_ROLES_SET (roles.js). flags.werewolf covers transformed
  // seats (Wolfskind after trigger, Lehrling inheritance). No /wolf/i regex —
  // it misclassified Wolfskind and missed Fenrir/Cerberus/Rudelvater.
  const inSet = (typeof WOLF_ROLES_SET!=="undefined") && WOLF_ROLES_SET.has(role);
  return inSet || !!flags.werewolf || !!meta.cursedWolfAura;
}

function countLivingWolfPower(){
  const alive=(state.seats||[]).filter(s=>!s.flags.dead);
  let p=0;
  alive.forEach(s=>{
    if(!isWolf(s)) return;
    p += (s.role==="Siegreicher Wolf") ? 2 : 1;
  });
  return p;
}

function gatewardenBlocksNewWolves(){
  return (state.seats||[]).some(s=>!s.flags.dead && s.role==="Wächter am Tor");
}

function grimmLivingRoleInRound(roleName){
  if(!roleName||!state||!state.seats)return false;
  return state.seats.some(s=>s&&s.role===roleName&&s.flags&&!s.flags.dead);
}
window.grimmLivingRoleInRound=grimmLivingRoleInRound;

function applyRoleOrVillagerIfGatewardenWolf(seat, intendedRole, asWerewolf){
  if(!seat) return;
  const probe = {role:intendedRole, flags:{werewolf:!!asWerewolf}, meta:seat.meta||{}};
  const wolfish = typeof isWolf==="function" && isWolf(probe);
  if(wolfish && gatewardenBlocksNewWolves()){
    seat.role = "Dorfbewohner";
    seat.flags.werewolf = false;
    if(seat.meta) seat.meta.cursedWolfAura = false;
    try{ if(typeof center==="function") center((window.t&&window.t("gatewardenRedirectVillager"))||"Wächter am Tor: Neue Werwölfe sind blockiert. Der Spieler wird stattdessen zum Dorfbewohner.", false); }catch(e){}
    return;
  }
  seat.role = intendedRole;
  if(!!asWerewolf) seat.flags.werewolf = true;
  else if(typeof isWolf==="function" && isWolf({role:intendedRole, flags:{werewolf:false}, meta:seat.meta||{}})) seat.flags.werewolf = true;
  else seat.flags.werewolf = false;
}

function rotkppchenShelterLinkActive(a,b){
  if(!a||!b) return false;
  if(a.role==="Rotkäppchen"||b.role==="Rotkäppchen") return true;
  if(a.meta&&a.meta.appleBuff) return true;
  if(b.meta&&b.meta.appleBuff) return true;
  return false;
}

function detectiveEmitPublicClue(){
  try{
    if(!grimmLivingRoleInRound("Detektiv")) return;
    const wolves=(state.seats||[]).filter(s=>!s.flags.dead && isWolf(s));
    if(wolves.length<2) return;
    const w=wolves[Math.floor(Math.random()*wolves.length)];
    const n=state.seats.length;
    const idx=w.id-1;
    const left=wolves.filter(x=>x.id!==w.id && ((x.id-1+n)%n)===(idx-1+n)%n);
    const right=wolves.filter(x=>x.id!==w.id && ((x.id-1+n)%n)===(idx+1)%n);
    let hint="";
    if(left.length) hint=(window.t&&window.t("detectiveClueLeft"))||("Detektiv-Hinweis: Ein anderer Wolf sitzt links neben "+(w.name||("#"+w.id))+".");
    else if(right.length) hint=(window.t&&window.t("detectiveClueRight"))||("Detektiv-Hinweis: Ein anderer Wolf sitzt rechts neben "+(w.name||("#"+w.id))+".");
    else hint=(window.t&&window.t("detectiveClueParity"))||("Detektiv-Hinweis: Ein anderer lebender Wolf hat eine andere Sitz-Parität (gerade/ungerade) als "+(w.name||("#"+w.id))+".");
    if(typeof center==="function") center(hint,true);
    if(window.gameLog&&typeof gameLog.add==="function") gameLog.add("🔍",hint);
  }catch(e){}
}

function triggerWin(roleName,seat){
  const name=seat?(seat.name||("#"+seat.id)):"?";
  let shownRole = window.getRoleName ? window.getRoleName(roleName) : roleName;
  if(roleName==="Dorf") shownRole=(window.t&&window.t("villageTeam"))||"Dorfbewohner";
  if(roleName==="Werwölfe") shownRole=(window.t&&window.t("wolfTeam"))||"Werwölfe";
  try{
    state.once=state.once||{};
    if(roleName==="Dorf") state.once.TeamWinner="village";
    else if(roleName==="Werwölfe") state.once.TeamWinner="wolves";
    else state.once.TeamWinner="solo_"+roleName;
  }catch(e){}
  const winWord=(window.t&&window.t("wins"))||"gewinnt!";
  showWinBanner(shownRole+" "+winWord);
  const winBanner=(window.t&&window.t("winsBanner"))||"GEWINNT!";
  center("🏆 "+shownRole.toUpperCase()+" "+winBanner+"\n"+name,true);
}

function applyKill(seat,cause){
  if(!seat||!seat.flags||seat.flags.dead)return false;
  state.once=state.once||{};
  try{
    if(seat.role==="Parasit"){
      const hid=seat.meta&&seat.meta.parasiteHostId;
      const host=hid?state.seats.find(x=>x.id===hid):null;
      if(host&&!host.flags.dead&&cause!=="PARASITE_HOST")return false;
    }
    if(seat.role==="Rudelvater"&&!state.once.RudelvaterSavedOnce){
      if(cause!=="NIGHT_KILL"&&cause!=="LYNCH"&&cause!=="PACKFATHER_KILL"&&cause!=="GIFTWOLF_DELAY"){
        state.once.RudelvaterSavedOnce=true;
        if(typeof center==="function")center((window.t&&window.t("rudelvaterSurvived"))||"Rudelvater überlebt den ersten Tod durch eine Sonderfähigkeit.",true);
        return false;
      }
    }
    if(seat.meta&&seat.meta.shadowSwapPartnerId&&!state.once._shadowApplying){
      const partner=state.seats.find(x=>x.id===seat.meta.shadowSwapPartnerId);
      if(partner&&!partner.flags.dead){
        state.once._shadowApplying=true;
        try{return applyKill(partner,cause);}finally{delete state.once._shadowApplying;}
      }
    }
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Tod: Umlenkung/Überleben", e); }
  state.once=state.once||{};
  if(state.once.TotenratDeathImmunityPending&&cause!=="PACKFATHER_KILL"){
    state.once.TotenratDeathImmunityPending=false;
    if(typeof center==="function"){
      try{ center((window.t&&window.t("shieldTotenratDeathBlocked"))||"Nekromant: Schild wehrt den Tod ab — totale Immunität verbraucht.", true); }catch(e){}
    }
    return false;
  }
  if(seat.role==="Kartenschlucker"&&state.once.KartenschluckerShield&&cause!=="PACKFATHER_KILL"){
    state.once.KartenschluckerShield=false;
    if(typeof center==="function") center((window.t&&window.t("shieldKartenschlucker"))||"🛡️ Kartenschlucker — Schutzschild absorbiert den Tod!",true);
    return false;
  }
  if(seat.role==="Hades"&&state.once.HadesBarriere&&cause!=="PACKFATHER_KILL"){
    state.once.HadesBarriere=false;
    if(typeof center==="function") center((window.t&&window.t("shieldHades"))||"🛡️ Hades — Barriere absorbiert den Tod!",true);
    return false;
  }
  if(!seat.meta)seat.meta={};
  seat.meta.lastKillCause=cause;
  seat.flags.dead=true;
  try{
    if(seat.role==="Seuchenwolf") state.once.SeuchenwolfNextAttackPierces=true;
    state.once.FirstThreeDeadIds=state.once.FirstThreeDeadIds||[];
    if(state.once.FirstThreeDeadIds.length<3) state.once.FirstThreeDeadIds.push(seat.id);
    if((seat.role||"")==="Schutzgeist") state.once.SchutzgeistAwaitingPick=true;
    if(isWolf(seat)&&seat.role!=="Doppelspion") detectiveEmitPublicClue();
    if(seat.role==="Todesprediger"&&state.once.TodespredigerPrediction){
      const pr=state.once.TodespredigerPrediction;
      let hit=false;
      if(pr.t==="night"&&typeof state.nightCount==="number"&&pr.n===state.nightCount) hit=true;
      if(pr.t==="day"&&typeof state.once.MorningCount==="number"&&pr.n===state.once.MorningCount) hit=true;
      if(hit) triggerWin("Todesprediger",seat);
    }
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Tod: Folgeeffekte (u.a. Todesprediger-Sieg)", e); }
  try{
    state.seats.forEach(p=>{
      if(p.role==="Parasit"&&!p.flags.dead&&p.meta&&p.meta.parasiteHostId===seat.id){
        applyKill(p,"PARASITE_HOST");
      }
    });
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Tod: Parasit stirbt mit Wirt", e); }
  try{
    if(seat.meta&&seat.meta.rkLink){
      const partner=state.seats.find(x=>x.id===seat.meta.rkLink);
      if(partner&&!partner.flags.dead&&partner.meta&&partner.meta.rkLink===seat.id&&rotkppchenShelterLinkActive(seat,partner)){
        applyKill(partner,"RED_RIDING_HOOD_LINK");
      }
    }
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Tod: Rotkäppchen-Todeskette", e); }
  try {
    if(seat.role==="Besessener Wolf"){
      const aliveNow = state.seats.filter(s=>!s.flags.dead).length;
      if(aliveNow>=4){
        // Enqueue instead of opening the pick inline: during night resolution
        // several kills run synchronously (processOne chain), so an inline
        // startPick here would be overwritten by the next kill's pick and the
        // drag would be lost. The queue is drained AFTER the kill chain
        // finishes — see drainBesessenerWolf() in night.js.
        state.once.besessenerWolfPending = state.once.besessenerWolfPending || [];
        if(!state.once.besessenerWolfPending.includes(seat.id)) state.once.besessenerWolfPending.push(seat.id);
      }
    }
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Tod: Besessener Wolf reißt mit", e); }
  try {
    if (typeof zieheZufallsKarte === "function") {
      state.once = state.once || {};
      state.once.totenkarten = state.once.totenkarten || {};
      // Respect a pre-assigned, unplayed card (assignTotenkarten at round start).
      // Only draw fresh when none exists or the previous one was already played
      // (e.g. seat was revived and died again).
      const existing = state.once.totenkarten[seat.id];
      if (!existing || existing.gespielt) {
        const neueKarte = zieheZufallsKarte(seat);
        state.once.totenkarten[seat.id] = {
          karteId: neueKarte.id,
          gespielt: false,
          shown: false
        };
      }
    }
  } catch(e) { if(window.grimmReportError) window.grimmReportError("Totenkarte-Vergabe", e); }
  try{
    const hades=state.seats.find(s=>s.role==="Hades"&&!s.flags.dead);
    if(hades){ state.once.HadesLichter=(state.once.HadesLichter||0)+1; if(typeof checkHadesWin==="function") checkHadesWin(); }
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Tod: Hades-Lichter/Sieg", e); }
  try{
    if(typeof checkWinConditions==="function") checkWinConditions();
  }catch(e){}
  return true;
}

function checkWinConditions() {
  try{
    if(!state||!state.seats) return;
    state.once = state.once || {};
    if(state.once.TeamWinner) return;
    const alive = state.seats.filter(s => !s.flags.dead);
    const villagers = alive.filter(s => !isWolf(s));
    const wolfPower = countLivingWolfPower();
    const trueWolves = alive.filter(s => isWolf(s));
    if(trueWolves.length === 0){
      const da=alive.find(s=>s.role==="Doppelspion");
      if(da) triggerWin("Doppelspion", da);
      else triggerWin("Dorf", null);
      return;
    }
    if(wolfPower >= villagers.length){ triggerWin("Werwölfe", null); return; }
    const m=alive.find(s=>s.role==="Manipulator");
    if(m&&alive.length===3&&!state.once.ManipulatorWasNominated) triggerWin("Manipulator", m);
    const par=alive.find(s=>s.role==="Parasit");
    if(par&&alive.length===3) triggerWin("Parasit", par);
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Sieg-Prüfung (checkWinConditions)", e); }
}

function checkKartenschluckerWin(){
  try{ if(!state||!state.seats||state.once.TeamWinner) return;
    const ks=state.seats.find(s=>s.role==="Kartenschlucker"&&!s.flags.dead);
    if(!ks) return;
    if((state.once.KartenschluckerStapel||0)>=10) triggerWin("Kartenschlucker",ks);
  }catch(e){}
}

function checkHadesWin(){
  try{
    if(!state||!state.seats||state.once.TeamWinner) return;
    const hades=state.seats.find(s=>s.role==="Hades"&&!s.flags.dead);
    if(!hades) return;
    if((state.once.HadesLichter||0)>=10){
      triggerWin("Hades", hades);
    }
  }catch(e){}
}

function ensureHunterQueue(){
  try{ state.once=state.once||{}; if(!Array.isArray(state.once.hunterQueue)) state.once.hunterQueue=[] }catch(e){}
}

function checkPestWin(){
  if(state.once.PestWon)return;
  if(state.once.TeamWinner)return; // ein bereits entschiedener Sieg darf nicht überschrieben werden
  const alive=state.seats.filter(s=>!s.flags.dead);
  if(alive.length&&alive.every(s=>s.flags.poisoned)){
    state.once.PestWon=true;
    try{ state.once.TeamWinner="solo_Pestbringerin"; }catch(e){}
    showWinBanner((window.getRoleName?window.getRoleName("Pestbringerin"):"Pestbringerin")+" "+((window.t&&window.t("wins"))||"gewinnt!"));
  }
}

function checkFluteWin(){
  if(!state||!state.seats)return;
  if(state.once&&state.once.TeamWinner)return; // ein bereits entschiedener Sieg darf nicht überschrieben werden
  const flute=state.seats.find(s=>!s.flags.dead&&s.role==="Rattenfänger");
  if(!flute)return;
  const alive=state.seats.filter(s=>!s.flags.dead&&s!==flute);
  if(!alive.length)return;
  if(!alive.every(s=>s.flags.charmed))return;
  try{ state.once=state.once||{}; state.once.TeamWinner="solo_Rattenfänger"; }catch(e){}
  showWinBanner((window.getRoleName?window.getRoleName("Rattenfänger"):"Rattenfänger")+" "+((window.t&&window.t("wins"))||"gewinnt!"));
}

function checkTeamWin(){
  try{
    if(!state||!state.seats)return;
    state.once=state.once||{};
    if(state.once.TeamWinner) return;              // schon entschieden
    if(state.once.PestWon) return;                 // spezielle Einzelsiege haben Vorrang

    // Single source of truth: same isWolf() as checkWinConditions/applyKill
    const isWolfSeat=s=>!!s&&!s.flags.dead&&isWolf(s);
    const hasRealRole=s=>((s.role||"").trim()!=="");

    const alive=state.seats.filter(s=>!s.flags.dead);
    if(!alive.length) return;

    // Erst werten, wenn im Spielverlauf mindestens 1 Wolf- und 1 Nicht-Wolf-Rolle vergeben wurden
    const assigned=state.seats.filter(hasRealRole);
    if(!assigned.length) return;
    // hier bewusst OHNE Dead-Check: es reicht, dass diese Rollen KONFIGURIERT wurden
    const anyWolfAssigned=assigned.some(s=>isWolf(s));
    const anyOtherAssigned=assigned.some(s=>!isWolf(s));
    if(!(anyWolfAssigned && anyOtherAssigned)) return;

    const wolves=alive.filter(s=>isWolfSeat(s) && hasRealRole(s));
    const others=alive.filter(s=>!isWolfSeat(s) && hasRealRole(s));
    let wolfPower=0;
    wolves.forEach(s=>{ wolfPower += (s.role==="Siegreicher Wolf")?2:1; });

    if(wolves.length===0 && others.length>0){
      const da=others.find(s=>s.role==="Doppelspion");
      if(da){
        state.once.TeamWinner="solo_Doppelspion";
        showWinBanner((window.getRoleName?window.getRoleName("Doppelspion"):"Doppelspion")+" "+((window.t&&window.t("wins"))||"gewinnt!"));
        return;
      }
      state.once.TeamWinner="village";
      showWinBanner((window.t&&window.t("villageWins"))||"Dorfbewohner gewinnen!");
      return;
    }
    if(others.length===0 && wolves.length>0){
      state.once.TeamWinner="wolves";
      showWinBanner((window.t&&window.t("wolvesWin"))||"Werwölfe gewinnen!");
      return;
    }
    if(wolfPower>=others.length && others.length>0 && wolves.length>0){
      state.once.TeamWinner="wolves";
      showWinBanner((window.t&&window.t("wolvesWin"))||"Werwölfe gewinnen!");
      return;
    }
    try{ checkKartenschluckerWin(); }catch(e){}
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Sieg-Prüfung (checkTeamWin)", e); }
}

function resetOnceForInheritedRole(role){
  state.once = state.once || {};
  const k = role + "Used";
  if (k in state.once) delete state.once[k];

  if (role === "Waldhexe") { state.once.WaldhexeL = false; state.once.WaldhexeD = false; }
  if (role === "Wolfskind") { delete state.once.MogliVorbildId; delete state.once.MogliUsed; }
  if (role === "König Lykaon") {
    delete state.once.UrwolfUsed;
    state.once.Used = state.once.Used || {};
    try {
      delete state.once.Used[usedKey("Urwolf")];
      delete state.once.Used[usedKey("König Lykaon")];
    } catch (e) {}
  }
  if (role === "Kopfgeldjäger") { state.once.BountyHunterActive = true; delete state.once.KopfgeldjägerUsed; }
  if (role === "Seelentauscher") { delete state.once.SeelentauscherUsed; }
  if (role === "Blutpriester") { delete state.once.BlutpriesterUsed; }
  if (role === "Dr. Victor Frankenstein") { state.once.FrankensteinUsed = false; }
  if (role === "Kutscher") { delete state.once.KutscherUsed; }
}

function postDeathHooks(){
  const _preHookDeadIds=new Set((state.seats||[]).filter(s=>s.flags.dead).map(s=>s.id));
  runDeathHooks()

    let loversTriggered=false;
  (function(){
    if(typeof isOnceUsed!=="function"||!isOnceUsed("Loki")) return;
    let changed;
    do{
      changed=false;
      const deadIds = new Set(state.seats.filter(a=>a.flags.dead).map(a=>a.id));
      [...state.seats].forEach(d=>{
        if(!d.flags.dead||!d.flags.inlove||!d.meta||!d.meta.loverId) return;
        const p=state.seats.find(z=>z.id===d.meta.loverId);
        if(!p||p.flags.dead||!p.flags.inlove||!p.meta||p.meta.loverId!==d.id) return;
        applyKill(p,"LOVER_HEARTBREAK"); changed=true; loversTriggered=true;
      });
      [...state.seats].forEach(p=>{
        if(p.flags.dead||!p.flags.inlove||!p.meta||!p.meta.loverId||!deadIds.has(p.meta.loverId)) return;
        const d=state.seats.find(z=>z.id===p.meta.loverId);
        if(!d||!d.flags.dead||!d.flags.inlove||!d.meta||d.meta.loverId!==p.id) return;
        applyKill(p,"LOVER_HEARTBREAK"); changed=true; loversTriggered=true;
      });
    }while(changed);
  })();
  if(loversTriggered){ queueSfxKey("sfxLovers"); }
const mogli=state.seats.find(s=>s.role==="Wolfskind"&&!s.flags.dead)
  if(mogli&&state.once.MogliVorbildId){const v=state.seats.find(s=>s.id===state.once.MogliVorbildId);if(v&&v.flags.dead){if(typeof gatewardenBlocksNewWolves==="function"&&gatewardenBlocksNewWolves()){mogli.role="Dorfbewohner";mogli.flags.werewolf=false;mogli.flags.vorbild=false;try{ if(typeof center==="function") center((window.t&&window.t("gatewardenRedirectVillager"))||"Wächter am Tor: Neue Werwölfe sind blockiert. Der Spieler wird stattdessen zum Dorfbewohner.", false); }catch(e){}}else{mogli.flags.werewolf=true}}}
  if(state.once.LehrlingMentorId){const l=state.seats.find(s=>s.role==="Lehrling");const m=state.seats.find(s=>s.id===state.once.LehrlingMentorId);if(l&&m&&m.flags.dead&&l.role==="Lehrling"){const mentorIsWolf=isWolf(m);if(mentorIsWolf&&typeof gatewardenBlocksNewWolves==="function"&&gatewardenBlocksNewWolves()){l.role="Dorfbewohner";l.flags.werewolf=false;resetOnceForInheritedRole(l.role);rebuildOrder()}else{l.role=m.role;if(mentorIsWolf)l.flags.werewolf=true;resetOnceForInheritedRole(l.role);rebuildOrder()}}}
  try{
    if(state && state.seats && typeof window.__queueHunterOnDeath==="function"){
      state.seats.forEach(s=>{
        if(!/^Sensenträger$/i.test((s.role||"").trim())) return;
        if(!s.flags || !s.flags.dead) return;
        window.__queueHunterOnDeath(s);
      });
    }
  }catch(e){ if(window.grimmReportError) window.grimmReportError("Tod-Hook: Sensenträger", e); }
  try{ maybeShowTodenkarten(); }catch(e){}
  doBearPing()
  if(!state.once||!state.once._inNightResolution){
    try{
      const _newlyDead=(state.seats||[]).filter(s=>s.flags.dead&&!_preHookDeadIds.has(s.id));
      if(_newlyDead.length&&typeof showDeathPopup==="function") showDeathPopup(_newlyDead);
    }catch(e){}
  }
  // Refresh the night order so rows of roles whose holder just died disappear
  // immediately (the SL assistant keeps its position via the rebuild wrapper).
  try{ if(typeof rebuildOrder==="function") rebuildOrder(); }catch(e){}
  // Drain queued Besessener-Wolf drags for day/lynch deaths. During night
  // resolution the drain runs from the kill chain instead (_inNightResolution),
  // so skip it here to avoid opening the pick mid-resolution.
  try{
    if(!(state.once&&state.once._inNightResolution) && typeof drainBesessenerWolf==="function") drainBesessenerWolf();
  }catch(e){}
}

function findNearestWolf(id){
  const n=state.seats.length
  const isWolfLocal=x=>x&&!x.flags.dead&&isWolf(x)
  const ok=x=>isWolfLocal(x)&&!(x.role==="Fenrir"&&state.fenrirStage>=3)
  for(let d=1;d<n;d++){
    const L=state.seats[(id-1-d+n)%n],R=state.seats[(id-1+d)%n]
    if(ok(L)) return L
    if(ok(R)) return R
  }
  return null
}

function applyRitterRetaliationFromNight(){
  const nightCauses = new Set(["NIGHT_KILL","BLACK_WIDOW","GIFTWOLF_DELAY","BURN_SPREAD","HADES_KILL","WITCH_POISON"]);
  const knights = (state.seats||[]).filter(s =>
    s.flags.dead && s.role === "Ritter" &&
    s.meta && !s.meta.ritterRetaliated &&
    nightCauses.has(s.meta.lastKillCause)
  );
  knights.forEach(knight => {
    knight.meta.ritterRetaliated = true;
    const wolf = findNearestWolf(knight.id);
    if(wolf){
      applyKill(wolf, "RITTER_RETALIATION");
      try{
        if(window.gameLog && typeof gameLog.add === "function"){
          const wname = wolf.name || ("#"+wolf.id);
          gameLog.add("⚔️", wname + " " + ((window.t&&window.t("logRitter"))||"wurde vom Ritter erschlagen"));
        }
      }catch(e){}
    }
  });
}

function spreadPoison(){
  const alive=state.seats.filter(s=>!s.flags.dead&&s.flags.poisoned)
  alive.forEach(p=>{const n=state.seats.length,i=p.id-1;const opts=[state.seats[(i-1+n)%n],state.seats[(i+1)%n]].filter(x=>x&&!x.flags.dead&&!x.flags.poisoned);if(opts.length){opts[Math.floor(Math.random()*opts.length)].flags.poisoned=true}})
}
