# Telling 📊

A **production-ready** crash reporting, error tracking, and analytics SDK for **Flutter and DartNative**. Monitor your app's health, track user behavior, and gain actionable insights with minimal setup.

Not sure which one you want? See [Which SDK?](choosing_an_sdk.md).


<br>


## ✨ Features

### Core Capabilities

- 🐛 **Automatic Crash Reporting** – Captures unhandled errors: Flutter's framework and platform handlers, or DartNative's isolate listener and error zone
- 📊 **Event Analytics** – Track custom events, user actions, and business metrics
- 📱 **Rich Device Context** – Auto-collects platform, OS version, device model, and app info
- 🔄 **Session Management** – Automatic session tracking with app lifecycle hooks
- 📍 **Screen Tracking** – Automatic on Flutter via `NavigatorObserver`; explicit `screenView()` on DartNative
- 👤 **User Context** – Associate logs with user IDs, names, and emails
- 🎯 **Widget-Level Tracking** – `.nowTelling()` extension for effortless view tracking
- ⚡ **Smart Batching** – Efficient log deduplication and batching to minimize network overhead
- 💾 **Offline Support** – Persists logs when offline, auto-sends when connection is restored
- 🛡️ **Rate Limiting** – Built-in deduplication, throttling, and flood protection
- 🌍 **Cross-Platform** – `telling_logger` runs on iOS, Android, Web, macOS, Windows and Linux; `telling_kit` targets iOS and Android


<br>


### Developer Experience

- 🚀 **5-Minute Setup** – Initialize with a single line of code
- 📝 **Production-Safe Logging** – Debug logs automatically stripped from release builds
- 🎨 **Flexible API** – Multiple log levels, types, and metadata support
