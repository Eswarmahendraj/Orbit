// Firebase Cloud Messaging Service Worker — Orbit Web
// Required for background push notifications on web

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA-qXcXK9ujcMkSf0-91pAmuy5IVXhUqI8',
  authDomain: 'aura-4e337.firebaseapp.com',
  projectId: 'aura-4e337',
  storageBucket: 'aura-4e337.appspot.com',
  messagingSenderId: '500091326393',
  appId: '1:500091326393:web:cf47d49588b8ccb5',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received:', payload);

  const { title, body, icon } = payload.notification ?? {};

  self.registration.showNotification(title ?? 'Orbit', {
    body: body ?? '',
    icon: icon ?? '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data ?? {},
    vibrate: [200, 100, 200],
  });
});

// Notification click — open the app
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url && 'focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});
