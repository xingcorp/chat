// Import Firebase

importScripts('https://www.gstatic.com/firebasejs/9.16.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.16.0/firebase-messaging-compat.js');

const firebaseConfig_stg = {
  apiKey: "AIzaSyBvTklOwhZpokeEt5Q5U7tImUF94D1xsCI",
  authDomain: "soffice-stag.firebaseapp.com",
  projectId: "soffice-stag",
  storageBucket: "soffice-stag.appspot.com",
  messagingSenderId: "578605276145",
  appId: "1:578605276145:web:ed1cb80beb5efd6165c250",
  vapidKey: "BFSKNtiG5n6V_j-S_PG4NeYu9XfQe1DEtvXxngD881MmcafvF-LscFV_349Q6ZABOcHkU4MtKKqlq-8famCpjY8",
}
const firebaseConfig_prod = {
  apiKey: "AIzaSyBk52UadYLIe0TzIyQD1zqGNn8t0DhHmms",
  authDomain: "soffice-prod.firebaseapp.com",
  projectId: "soffice-prod",
  storageBucket: "soffice-prod.appspot.com",
  messagingSenderId: "50219916620",
  appId: "1:50219916620:web:2af253a5e3946b594003e9",
  vapidKey: "BGaqz5ZBywBqvhykKVwtuoVsG5cyo6pUjGbeYdsAtWGM7NdKCANOK1KnbBEvIqupV44gS6xdwXkkeiY9eqTDl14",
}

// Initialize Firebase
firebase.initializeApp(firebaseConfig_stg);

// Retrieve messaging
const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  let _title = payload?.notification?.title || ''
  const mentionRegex = /\[@[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\]/gm
  const data = JSON.parse(payload?.data?.data || '')
  const metaData = JSON.parse(data?.metadata || '')
  let _body = data?.body || ''
  switch (data.type) {
    case 'chat.notify':
      if (_body.match(mentionRegex)?.length) {
        const _messageMention = data?.body.replace(mentionRegex, (match) => {
          const mentionUser = metaData?.mentionTo?.find((item) => `[@${item.id}]` === match)
          return `@${mentionUser?.fullname || ''}`
        })
        _body = _messageMention
      }
      break
  }
  const notificationOptions = {
    body: _body,
    icon: '../assets/images/logo.svg'
  };
  // console.log('[firebase-messaging-sw.js] Received background message ', {notificationTitle, notificationOptions});
  self.registration.showNotification(_title,
    notificationOptions).then();
});
