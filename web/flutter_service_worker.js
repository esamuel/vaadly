// Flutter Service Worker for icon font preloading
const CACHE_NAME = 'vaadly-cache-v1';
const ICON_FONT_URL = 'https://fonts.googleapis.com/icon?family=Material+Icons';

self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      // Preload Material Icons font
      return cache.addAll([
        ICON_FONT_URL,
        '/',
        '/index.html',
        '/icons.css'
      ]);
    })
  );
});

self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request).then(function(response) {
      return response || fetch(event.request);
    })
  );
});
