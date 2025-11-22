# Telling Dashboard

An analytics dashboard built with Flutter. This application serves as the command center for monitoring logs, events, and crashes sent from the `telling_logger` SDK.

## 🚀 Features

- **Military Aesthetic**: Custom UI theme with "glitch" effects, scanlines, and tactical typography (Syne, Urbanist).
- **Real-time Monitoring**: Auto-polling for new logs and events.
- **Logs Explorer**:
  - Filter by Log Level (Debug, Info, Warning, Error, Fatal).
  - Filter by Log Type (Log, Error, Analytics, Event, Performance, Network).
  - Full-text search.
  - Detailed JSON inspection for metadata and device info.
- **Command Center**: High-level overview with real-time statistics.
- **Log Generator**: Built-in tools to simulate various log types, events, and crashes for testing.
- **Responsive Design**: Optimized for Desktop and Web, with mobile-friendly navigation.

## 🛠 Tech Stack

- **Framework**: Flutter (Web & Desktop)
- **State Management**: Riverpod (with code generation)
- **Data Modeling**: Freezed & JSON Serializable
- **Backend**: Dart Shelf Server + SQLite
- **SDK**: Custom `telling_logger` package

## 📦 Project Structure

```
telling/
├── backend/                 # Dart Shelf server & SQLite DB
├── lib/
│   ├── core/               # Core logic (Providers, Models, Repositories)
│   ├── features/           # Feature-based modules (Logs, Overview, Settings)
│   ├── shared/             # Shared widgets & UI components
│   └── main.dart           # Entry point
└── packages/
    └── telling_logger/     # Custom Logging SDK
```

## 🏃‍♂️ Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK

### 1. Start the Backend

The dashboard requires the backend server to be running.

```bash
cd backend
dart run bin/server.dart
```

The server will start on `http://localhost:8080`.

### 2. Run the Dashboard

Open a new terminal window:

```bash
flutter run -d chrome
```

## 🧪 Testing

Go to the **Settings** tab in the dashboard to access the **Log Generator**. You can trigger:
- Debug/Info/Warning/Error/Fatal logs
- Analytics Events
- Network Logs
- Forced Crashes (to test error reporting)

## 📝 License

This project is licensed under the MIT License.
