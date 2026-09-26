// --- Audio & SFX ---
var SOUNDS_BASE = "assets/sounds/";
let nightAudio = new Audio();
nightAudio.loop = true;
nightAudio.preload = "auto";
let alarmAudio = new Audio();

// Role SFX disabled (2026-06-12): all character sounds are intentionally muted;
// a clean sound system will be reintegrated later. queueSfxKey stays as a no-op
// so the call sites (night.js, state.js, ui/core.js, game.html) keep working.
// Night music (nightAudio) and the timer end sound (Ruhe.mp3) remain active.
function queueSfxKey(key) {}

// --- Timer ---
let timerInterval = null;
let remainingSeconds = 0;

function parseTime(str) {
  const parts = str.split(":").map(p => parseInt(p, 10) || 0);
  return parts[0] * 60 + (parts[1] || 0);
}

function formatTime(sec) {
  const m = Math.floor(sec / 60).toString().padStart(2, "0");
  const s = (sec % 60).toString().padStart(2, "0");
  return m + ":" + s;
}

function startTimer() {
  const input = document.getElementById("timerIn");
  if (!input) return;
  if (!remainingSeconds) remainingSeconds = parseTime(input.value || "00:00");
  if (timerInterval) clearInterval(timerInterval);
  timerInterval = setInterval(() => {
    remainingSeconds--;
    if (remainingSeconds <= 0) {
      clearInterval(timerInterval);
      timerInterval = null;
      remainingSeconds = 0;
      input.value = "00:00";
      try {
        var timerSound = (typeof state !== "undefined" && state.files && state.files.alarm) ? state.files.alarm : (SOUNDS_BASE + "Ruhe.mp3");
        var a = new Audio(timerSound);
        a.volume = (typeof state !== "undefined" && state.audioVol != null) ? state.audioVol : 1;
        a.play().catch(function(){});
      } catch (e) {}
    } else {
      input.value = formatTime(remainingSeconds);
    }
  }, 1000);
}

function pauseTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}

function resetTimer() {
  const input = document.getElementById("timerIn");
  if (input) {
    input.value = "00:00";
  }
  remainingSeconds = 0;
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}
