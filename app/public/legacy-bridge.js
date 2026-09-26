/* legacy-bridge.js — Options bridge for the React shell.
 *
 * These option actions live INLINE in the production game.html, which the React
 * runtime never loads. To expose them WITHOUT editing the vanilla source, the
 * EXACT game.html logic is copied verbatim below and loaded as a classic script
 * AFTER the bundled js/core+js/ui (same global scope → it reads `state`,
 * `createState`, `save`, `draw`, `rebuildOrder`, `assignTotenkarten`, `nightAudio`).
 * Top-level function declarations auto-register as window.* globals.
 * Production game.html stays untouched; re-copy if those originals change.
 */

/* night music — nightAudio is a lexical global in js/ui/audio.js, reachable here
   because classic scripts share the global scope. Phase already auto-controls it;
   this is a manual toggle for the options panel. */
window.toggleNightMusic = function () {
  try {
    if (typeof nightAudio === "undefined" || !nightAudio) return false;
    if (nightAudio.paused) { nightAudio.play().catch(function () {}); } else { nightAudio.pause(); }
    return !nightAudio.paused;
  } catch (e) { return false; }
};
window.isNightMusicPlaying = function () {
  try { return typeof nightAudio !== "undefined" && !!nightAudio && !nightAudio.paused; } catch (e) { return false; }
};

/* ── verbatim from game.html: hardReset ── */
function hardReset(){
  const n=state.seats.length
  state=createState(n)
  save(); draw(); rebuildOrder()
}

/* ── verbatim from game.html: clearRolesNewRound ── */
function clearRolesNewRound(){
  if(!state||!state.seats) return;
  state.seats.forEach(s=>{
    s.role="";
    s.flags=Object.assign({},s.flags||{},{dead:false,protected:false,targeted:false,inlove:false,rival:false,werewolf:false,vorbild:false,nominated:false,charmed:false,poisoned:false,burned:false,puppet:false,hmark:false,deadVoteStripped:false});
    s.meta=Object.assign({},s.meta||{},{cerbHeads:0,killedTonight:false,cursedWolfAura:false,rivalId:null,unholy:false,blockedTonight:false});
  });
  state.dark=false;
  state.nightCount=1;
  state.once=state.once||{};
  state.once.LynchCount=0; state.once.KutscherUsed=false; state.once.Used={}; state.once.WaldhexeL=false; state.once.WaldhexeD=false; state.once.MaertyUsed=false; state.once.PestTotal=0; state.once.PestUsedTonight=false; state.once.ProphetTargets=null; state.once.ProphetUnlocked=false; state.once.VoodooCooldown=0; state.once.MogliVorbildId=null; state.once.LehrlingMentorId=null; state.once.OldDebuff=0; state.once.BlockedRolesTonight=[]; state.once._nightIncremented=false; state.once.GebundenShown=false; state.once.DerWeiseFirstAttackUsed=false;
  state.once.BountyHunterActive=false; state.once.FrankensteinUsed=false;  state.once.KoenigUsed=false; state.once.KopfgeldjägerUsed=false; state.once.MogliUsed=false; state.once.SeelentauscherUsed=false; state.once.BlutpriesterUsed=false; state.once.PestWon=false; state.once.ProphetDeadCount=0; state.once.hunterQueue=[]; state.once.TeamWinner=null; state.fenrirStage=0; state.fenrirSaved=false;
  state.once.totenkarten={}; state.once.KartenschluckerStapel=0; state.once.KartenschluckerKilledTonight=false; state.once.KartenschluckerShield=false; state.once.KartenschluckerNightCount=0; state.once.TotenratFuehrerSilenced=[]; state.once.TotenratFuehrerRevealed=false; state.once.TotenratFuehrerUsedDeflect=false; state.once.TotenratDeathImmunityPending=false; state.once.HadesLichter=0; state.once.HadesBarriere=false; state.once.HadesVoteBonus=false; state.once.HadesKilledTonight=false; state.once.HadesWon=false; assignTotenkarten();
  state.once.RudelvaterSavedOnce=false; state.once.SeuchenwolfNextAttackPierces=false; state.once.FateWolfMarked=[]; state.once.TodespredigerPrediction=null; state.once.MorningCount=0; state.once.NightUsedRoles=[]; state.once.WhiteWolfCooldown=0; state.once.WhiteWolfUsedTonight=false; state.once.FirstThreeDeadIds=[]; state.once.FateWolfNight4Used=false; state.once.SchmiedForgeNights=0; state.once.SchmiedWeaponGiven=false; state.once.PackfatherExtraKillNextNight=false; state.once.PackfatherBlockNextDay=false; state.once.ManipulatorWasNominated=false; state.once.FakeNightRoles={}; state.once.besessenerWolfPending=[]; state.once._besessenerDraining=false;
  save(); draw(); rebuildOrder();
  try{ if(typeof window.__renderPhaseCounter==="function") window.__renderPhaseCounter(); }catch(e){}
  var pc=document.getElementById("phaseCounter"); if(pc) pc.textContent="☀️ " + (window.t ? window.t("day") : "Tag") + " 1";
}
