# TransPilot

![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-47C5FB?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-4F46E5?style=for-the-badge)
![Transmission RPC](https://img.shields.io/badge/Transmission-RPC-2F855A?style=for-the-badge)
![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-Supported-111827?style=for-the-badge&logo=apple&logoColor=white)

> This project was 100% created using Codex AI.

TransPilot is a production-minded Flutter mobile client for managing remote Transmission servers through the Transmission RPC API. It supports multiple saved servers, secure credential storage, adaptive phone and tablet layouts, session-aware RPC retry handling, torrent grouping, and live session controls on Android and iOS.

## ✨ Highlights

- Multi-server profile management with secure credential storage
- Automatic `X-Transmission-Session-Id` negotiation and retry handling
- Adaptive UI for phones, tablets, portrait, and landscape
- Torrent search, filter, sort, grouping, detail view, and actions
- Add torrent via magnet link, `.torrent` file, or clipboard
- Session dashboard and editable server/session settings
- Unit tests for RPC behavior, DTO mapping, grouping, filtering, and controller logic

## 🧩 Feature Set

### 📡 Connectivity

- Multiple saved Transmission server profiles
- Secure username/password storage via `flutter_secure_storage`
- HTTP basic auth support
- Graceful handling for invalid credentials, timeouts, malformed endpoints, unreachable hosts, and certificate issues

### 📋 Torrent Management

- Search torrents by name, path, or tracker
- Filter by status
- Sort by name, progress, added date, download speed, and upload speed
- Group by flat list, download path, or tracker
- Pull-to-refresh and periodic refresh
- Start, start now, pause, verify, reannounce, remove, and remove data
- Queue movement, rename path, move data, and bandwidth priority changes

### 🔎 Detail View

- General torrent info
- Files with wanted/unwanted toggle and per-file priority
- Trackers and peers
- Transfer stats, dates, and error messages

### ⚙️ Session Control

- View session summary and lifetime stats
- Update supported session settings
- View free space and alternative speed mode state

## 🏗️ Project Structure

```text
lib/
  core/
    constants/
    errors/
    theme/
    utils/
  data/
    dto/
    repositories/
    rpc/
    storage/
  domain/
    entities/
    repositories/
  presentation/
    app/
    controllers/
    screens/
  shared/
    logic/
    widgets/

test/
  core/
  data/
  presentation/
  shared/
```

## 🧠 Architecture

TransPilot follows a compact clean architecture:

- `core`: shared theme, errors, formatting helpers, breakpoints, and app infrastructure
- `data`: Transmission RPC transport, DTO parsing, persistence, and repository implementations
- `domain`: entities and repository contracts
- `presentation`: Riverpod controllers, screens, and adaptive UI flows
- `shared`: reusable business logic and UI building blocks

The RPC layer centralizes Transmission-specific behavior, especially session refresh and retry after `409 Conflict`. UI state is driven through Riverpod `StateNotifier` controllers for profiles, preferences, torrents, details, and dashboard/session data.

## 🚀 Getting Started

### Prerequisites

- Flutter stable
- Android Studio or Xcode
- A reachable Transmission RPC server

### Install dependencies

```bash
flutter pub get
```

### Run on Android

```bash
flutter run -d android
```

### Run on iOS

```bash
flutter run -d ios
```

If CocoaPods is not initialized yet:

```bash
cd ios
pod install
cd ..
```

## ✅ Verification

Run static analysis:

```bash
dart analyze
```

Run tests:

```bash
flutter test
```

## 📱 Usage Flow

1. Open `Servers` and add a Transmission server profile.
2. Test the connection and save the profile.
3. Set the server as active.
4. Open `Torrents` to browse, group, sort, and manage torrents.
5. Open `Dashboard` for session and transfer overview.
6. Open `Settings` for app preferences and session settings.

## 📝 Platform Notes

- Credentials are stored using Android encrypted shared preferences and iOS Keychain through `flutter_secure_storage`.
- Invalid or self-signed TLS certificates are surfaced as errors. This build does not provide a certificate bypass or pinning UI.
- Torrent pre-selection from `.torrent` contents before upload is not implemented yet.
- The files section is currently a flat list instead of a nested directory tree.

## 🔧 Implementation Notes

- Tracker grouping uses a deterministic primary tracker rule: lowest tier first, then tracker id, normalized to host/domain where possible.
- Download-path grouping prefers torrent-level `downloadDir`; missing values fall back to `Unknown Path`.
- Refresh timers are owned by Riverpod controllers and are cancelled on disposal or active-profile changes.
- Grouping, sorting, filter, theme, refresh interval, and collapse preferences are persisted locally.

## 📊 Current Status

The repository currently passes:

- `dart analyze`
- `flutter test`

## 🤖 Credits

This project was fully created using Codex AI.
