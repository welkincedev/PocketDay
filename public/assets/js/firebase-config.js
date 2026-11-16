/**
 * PocketDay — Firebase Web Client Configuration
 * Project: pocketday-1679a
 * Environment: Client-facing official web portal
 */

const firebaseConfig = {
  apiKey: "AIzaSyDof-JgPasg2h6YlXDYtvh4JdsdHtg9css",
  authDomain: "pocketday-1679a.firebaseapp.com",
  projectId: "pocketday-1679a",
  storageBucket: "pocketday-1679a.firebasestorage.app",
  messagingSenderId: "104455039089",
  appId: "1:104455039089:web:16df935efd44e4f28713d0"
};

// Initialize Firebase if library is available
let app = null;
let auth = null;
let db = null;

if (typeof firebase !== 'undefined') {
  try {
    if (!firebase.apps.length) {
      app = firebase.initializeApp(firebaseConfig);
    } else {
      app = firebase.app();
    }
    auth = firebase.auth();
    db = firebase.firestore();
  } catch (err) {
    console.warn("PocketDay: Firebase initialization notice:", err.message);
  }
}
