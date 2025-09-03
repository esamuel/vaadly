# 🔥 Firebase Setup Guide for Vaadly App

## 🚨 **IMPORTANT: Firebase Must Be Configured Before Testing**

Your app currently has **placeholder Firebase credentials**, which is why buildings disappear when you refresh. Follow these steps to fix it:

## 📋 **Step-by-Step Setup**

### 1. **Create Firebase Project**
- Go to [Firebase Console](https://console.firebase.google.com/)
- Click **"Create a project"**
- Name it `vaadly-app` (or your preferred name)
- Follow the setup wizard (you can disable Google Analytics for now)

### 2. **Add Web App**
- In your project, click the **web icon** (</>)
- Register app with name: `Vaadly`
- Copy the **config object** that looks like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123"
};
```

### 3. **Update Configuration Files**

#### **Update `lib/firebase_options.dart`:**
Replace the placeholder values with your real config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyC...', // Your real API key
  appId: '1:123456789:web:abc123', // Your real app ID
  messagingSenderId: '123456789', // Your real sender ID
  projectId: 'your-project', // Your real project ID
  authDomain: 'your-project.firebaseapp.com', // Your real auth domain
  storageBucket: 'your-project.appspot.com', // Your real storage bucket
  measurementId: 'G-ABC123', // Your real measurement ID (optional)
);
```

#### **Update `web/index.html`:**
Replace the placeholder values in the JavaScript config:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyC...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123"
};
```

### 4. **Enable Firestore Database**
- In Firebase Console, go to **"Firestore Database"**
- Click **"Create database"**
- Choose **"Start in test mode"** (for development)
- Select a location (choose closest to your users)

### 5. **Rebuild and Test**
```bash
flutter clean
flutter build web --no-tree-shake-icons
cd build/web && python3 -m http.server 8000
```

## ✅ **What You'll See When It's Working**

- ✅ **Console shows**: "Firebase initialized successfully"
- ✅ **Console shows**: "Project: your-project-name"
- ✅ **Buildings are saved** and persist after refresh
- ✅ **Financial data appears** automatically
- ✅ **Data is stored** in Firebase Firestore

## 🚨 **Current Status**

- ❌ **Firebase not configured** (placeholder credentials)
- ❌ **Buildings disappear** on refresh
- ❌ **No data persistence**
- ❌ **Cannot test app functionality**

## 🔗 **Quick Links**

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Web Setup](https://firebase.google.com/docs/web/setup)
- [Firestore Quickstart](https://firebase.google.com/docs/firestore/quickstart)

## 📞 **Need Help?**

Once you've updated the config, rebuild the app and test. If you still have issues, check the browser console for error messages.
