# GreatReads

A social reading tracker app with vibe analysis - like Spotify Wrapped, but for books.

## Features

- 📚 Track your reading list
- 🎨 Books categorized by "vibe"
- 👥 Add friends and see what they're reading
- 🔐 User authentication with Firebase
- ☁️ Cloud sync across devices

## Tech Stack

- **SwiftUI** - iOS interface
- **Firebase Authentication** - User accounts
- **Firebase Firestore** - Cloud database
- **Xcode** - Development environment

## Setup Instructions

### Prerequisites

- macOS with Xcode installed
- Firebase account (free tier works)

### 1. Clone the Repository

```bash
git clone https://github.com/firestar2202/great_reads.git
cd great_reads
```

### 2. Open in Xcode

```bash
open great_reads/great_reads.xcodeproj
```

### 3. Install Dependencies

Xcode should automatically resolve Swift Package dependencies when you open the project. If not:

1. Go to **File** → **Add Package Dependencies**
2. Add Firebase SDK: `https://github.com/firebase/firebase-ios-sdk`
3. Select these products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseCore

### 4. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (or use existing)
3. Add an iOS app with your bundle ID (found in Xcode project settings)
4. Download `GoogleService-Info.plist`
5. Drag it into your Xcode project (make sure "Copy items if needed" is checked)

### 5. Enable Firestore

In Firebase Console:
1. Go to **Firestore Database**
2. Click **Create database**
3. Start in **test mode** (we'll add security rules later)
4. Choose a location

### 6. Enable Authentication

In Firebase Console:
1. Go to **Authentication**
2. Click **Get started**
3. Enable **Email/Password** sign-in method

### 7. Run the App

Press **Cmd + R** or click the Play button in Xcode.

## Project Structure

```
great_reads/
├── great_reads/
│   ├── ContentView.swift         # Main book library view
│   ├── AuthView.swift            # Login/signup screen
│   ├── AuthManager.swift         # Authentication logic
│   ├── BookManager.swift         # Firestore book operations
│   ├── FirestoreBook.swift       # Book data model
│   └── great_readsApp.swift      # App entry point
```
