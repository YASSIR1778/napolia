// The website's notifications: only what a customer asked for on their order
// page (confirmed for later, ready, refused). It caches nothing and never
// stands between the page and the network.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('push', (event) => {
  let msg = { title: 'Bella Napolia', body: '', tag: undefined, url: '' };
  try {
    msg = { ...msg, ...event.data.json() };
  } catch {
    if (event.data) msg.body = event.data.text();
  }
  event.waitUntil(
    self.registration.showNotification(msg.title, {
      body: msg.body,
      tag: msg.tag,
      renotify: !!msg.tag,
      icon: 'card-192.png',
      badge: 'favicon.png',
      dir: 'auto',
      vibrate: [200, 100, 200, 100, 300],
      data: { url: msg.url },
    }),
  );
});

// A tap opens the order page, in the site's tab when one is open.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = new URL(event.notification.data?.url || '', self.registration.scope).href;
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      const open = list.find((c) => c.url.startsWith(self.registration.scope));
      if (open) {
        open.navigate(url);
        return open.focus();
      }
      return self.clients.openWindow(url);
    }),
  );
});
