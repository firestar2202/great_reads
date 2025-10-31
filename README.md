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
- **Firebase** - Authentication & Firestore database
- **Claude API** - AI-powered vibe analysis

## Setup Instructions

### 1. Clone and Open
```bash
git clone https://github.com/firestar2202/great_reads.git
cd great_reads
open great_reads/great_reads.xcodeproj
```

### 2. Install Dependencies

Xcode should auto-resolve packages. If not, add Firebase SDK manually:
- **File** → **Add Package Dependencies**
- URL: `https://github.com/firebase/firebase-ios-sdk`
- Select: FirebaseAuth, FirebaseFirestore, FirebaseCore

### 3. Firebase Setup

1. Create a project at [Firebase Console](https://console.firebase.google.com/)
2. Add iOS app with your bundle ID
3. Download `GoogleService-Info.plist` and drag into Xcode
4. Enable **Firestore Database** (test mode)
5. Enable **Email/Password** authentication

### 4. API Keys Setup

Create `Config.swift` in the `great_reads` folder:
```swift
import Foundation

struct Config {
    static let claudeAPIKey = "YOUR_CLAUDE_API_KEY_HERE"
}
```

Get your Claude API key from [console.anthropic.com](https://console.anthropic.com/)

**Note**: `Config.swift` is gitignored and never committed. Each developer needs their own copy.

### 5. Run

Press **Cmd + R** in Xcode!

## Project Structure
```
great_reads/
├── great_reads/
│   ├── ContentView.swift         # Main library view
│   ├── AuthView.swift            # Login/signup
│   ├── AuthManager.swift         # Auth logic
│   ├── BookManager.swift         # Firestore operations
│   └── Config.swift              # API keys (gitignored)
```
