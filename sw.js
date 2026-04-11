/* KID COMM 3000 — Service Worker
 * Cache-first shell so the app works offline after the first visit.
 * WebRTC / signaling traffic of course still needs network. */

const CACHE = 'kidcomm-v6';
const SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.svg',
  './icons/icon-512.svg',
  './icons/icon-maskable-512.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(SHELL)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);

  // Don't touch PeerJS signaling / WebSocket / cross-origin realtime stuff
  if (url.protocol === 'ws:' || url.protocol === 'wss:') return;
  if (url.hostname.includes('peerjs')) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);

      // Network-first for HTML / navigation so updates land immediately.
      const isHTML = req.mode === 'navigate'
        || (req.destination === '' && req.headers.get('accept')?.includes('text/html'))
        || url.pathname.endsWith('/')
        || url.pathname.endsWith('.html');

      if (isHTML && url.origin === location.origin) {
        try {
          const resp = await fetch(req, { cache: 'no-store' });
          if (resp && resp.ok) cache.put(req, resp.clone()).catch(() => {});
          return resp;
        } catch (err) {
          const shell = await cache.match('./index.html');
          if (shell) return shell;
          throw err;
        }
      }

      // Cache-first (with background revalidation) for everything else.
      const cached = await cache.match(req);
      if (cached) {
        fetch(req).then((resp) => {
          if (resp && resp.ok) cache.put(req, resp.clone()).catch(() => {});
        }).catch(() => {});
        return cached;
      }
      try {
        const resp = await fetch(req);
        if (resp && resp.ok && (url.origin === location.origin)) {
          cache.put(req, resp.clone()).catch(() => {});
        }
        return resp;
      } catch (err) {
        throw err;
      }
    })()
  );
});
