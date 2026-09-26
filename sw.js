// Minimal service worker: makes the PWA registration (index.html/game.html)
// resolve instead of 404ing. Intentionally NO fetch/caching logic yet — offline
// support is a separate task; an empty worker cannot serve stale files.
self.addEventListener("install", function () {
  self.skipWaiting();
});
self.addEventListener("activate", function (event) {
  event.waitUntil(self.clients.claim());
});
