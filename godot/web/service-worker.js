// Service worker of the Grimmhain web build. `tools/export-web.js` replaces Godot's generated index.service.worker.js with this file
// and sets the build id. Differences to Godot's template (which served index.html from the cache first and so kept old builds alive):
// - index.html, navigations, version.json and the manifest always come from the network; the cache is only the offline fallback.
// - Everything else (engine, wasm, pck, icons) is cache-first, but only inside the cache of THIS build ('grimmhain-' + build id).
// - A new build drops every other cache on activation. The page (web/shell.html) additionally purges stale workers before the engine starts.
const BUILD_ID = '___BUILD_ID___';
const CACHE_NAME = 'grimmhain-' + BUILD_ID;
const OFFLINE_URL = 'index.offline.html';
const ENSURE_CROSSORIGIN_ISOLATION_HEADERS = true;
// Precached on install; the large index.wasm and index.pck are cached when the page loads them.
const CACHED_FILES = ['index.html', 'index.js', 'index.offline.html', 'index.icon.png', 'index.apple-touch-icon.png', 'index.audio.worklet.js', 'index.audio.position.worklet.js'];
const NETWORK_FIRST = ['index.html', 'version.json', 'index.manifest.json', 'index.service.worker.js'];

self.addEventListener('install', (event) => {
	self.skipWaiting();
	event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES.map((name) => new Request(name, { cache: 'reload' })))));
});

self.addEventListener('activate', (event) => {
	event.waitUntil(
		caches.keys()
			.then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
			.then(() => self.clients.claim())
	);
});

function withIsolationHeaders(response) {
	if (!ENSURE_CROSSORIGIN_ISOLATION_HEADERS || response.status === 0
		|| (response.headers.get('Cross-Origin-Embedder-Policy') === 'require-corp' && response.headers.get('Cross-Origin-Opener-Policy') === 'same-origin')) {
		return response;
	}
	const headers = new Headers(response.headers);
	headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
	headers.set('Cross-Origin-Opener-Policy', 'same-origin');
	return new Response(response.body, { status: response.status, statusText: response.statusText, headers });
}

// Path relative to the worker's scope ('' for the start page), or null for foreign origins.
function localPath(request) {
	const url = new URL(request.url);
	const scope = new URL(self.registration.scope);
	if (url.origin !== scope.origin || !url.pathname.startsWith(scope.pathname)) {
		return null;
	}
	return url.pathname.slice(scope.pathname.length);
}

async function networkFirst(event, key) {
	const cache = await caches.open(CACHE_NAME);
	try {
		const response = await fetch(event.request, { cache: 'no-store' });
		if (response.ok && key !== 'version.json' && key !== 'index.service.worker.js') {
			event.waitUntil(cache.put(key, response.clone()));
		}
		return withIsolationHeaders(response);
	} catch (e) {
		const cached = await cache.match(key);
		if (cached) {
			return withIsolationHeaders(cached);
		}
		if (event.request.mode === 'navigate') {
			const offline = await cache.match(OFFLINE_URL);
			if (offline) {
				return offline;
			}
		}
		throw e;
	}
}

async function cacheFirst(event, key) {
	const cache = await caches.open(CACHE_NAME);
	const cached = await cache.match(key);
	if (cached) {
		return withIsolationHeaders(cached);
	}
	const response = await fetch(event.request);
	if (response.status === 200) {
		event.waitUntil(cache.put(key, response.clone()));
	}
	return withIsolationHeaders(response);
}

self.addEventListener('fetch', (event) => {
	if (event.request.method !== 'GET') {
		return;
	}
	const path = localPath(event.request);
	if (path === null) {
		return;
	}
	if (event.request.mode === 'navigate' || path === '') {
		event.respondWith(networkFirst(event, 'index.html'));
	} else if (NETWORK_FIRST.includes(path)) {
		event.respondWith(networkFirst(event, path));
	} else {
		event.respondWith(cacheFirst(event, path));
	}
});
