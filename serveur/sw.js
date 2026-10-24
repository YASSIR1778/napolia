// The waiter's phone (served as sw.js by the waiter build): shows "the order is
// ready" even when the phone is locked or the app is in the background, and
// opens the app when the notification is tapped. On screen, the app rings by itself.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('push', (event) => {
  let msg = { title: 'Bella Napolia', body: '', tag: 'ready' };
  try {
    msg = { ...msg, ...event.data.json() };
  } catch {
    if (event.data) msg.body = event.data.text();
  }
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      if (list.some((c) => c.visibilityState === 'visible' && c.focused)) return undefined;
      return self.registration.showNotification(msg.title, {
        body: msg.body,
        tag: msg.tag,
        // The same round again: ring again, and stay until the waiter acts.
        renotify: true,
        requireInteraction: true,
        vibrate: [300, 150, 300, 150, 300],
        icon: 'waiter-192.png',
        badge: 'waiter-192.png',
        dir: 'auto',
        lang: 'ar',
      });
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      const open = list.find((c) => c.url.startsWith(self.registration.scope));
      if (open) return open.focus();
      return self.clients.openWindow(self.registration.scope);
    }),
  );
});
