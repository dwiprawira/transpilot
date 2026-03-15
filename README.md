# TransPilot

TransPilot is a Flutter mobile client for managing remote Transmission servers over the Transmission RPC API. It supports multiple saved server profiles, secure credential storage, adaptive phone/tablet layouts, session-aware RPC retries, torrent grouping, and live session controls for Android and iOS.

## Features

- Multiple saved Transmission server profiles
- Secure username/password storage with `flutter_secure_storage`
- Automatic `X-Transmission-Session-Id` negotiation and retry handling
- Basic auth, timeout, unreachable host, malformed endpoint, and bad certificate error handling
- Torrent list with search, filter, sort, pull-to-refresh, and periodic refresh
- Grouping by download path or tracker with persisted collapse state
- Adaptive layouts for phones, tablets, portrait, and landscape
- Torrent detail view with files, trackers, peers, transfer stats, dates, and actions
- Add torrent flow for magnet links, `.torrent` files, and clipboard paste
- Session dashboard and editable server/session settings
- Unit tests for RPC behavior, DTO mapping, grouping, sorting/filtering, controller flow, and adaptive layout logic

## Project Structure

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

## Architecture

TransPilot uses a small clean architecture split:

- `core`: shared theme, app-level errors, formatting helpers, and layout breakpoints
- `data`: Transmission RPC transport, DTO parsing, preference/profile persistence, and repository implementations
- `domain`: app entities and repository contracts
- `presentation`: Riverpod controllers, adaptive screens, and end-user flows
- `shared`: reusable list/grouping logic and UI building blocks

The RPC layer centralizes Transmission-specific behavior, especially session-id refresh and retry after `409 Conflict`. UI state is driven through Riverpod `StateNotifier` controllers for profiles, preferences, torrent lists, details, and dashboard/session data.

## Setup

### Prerequisites

- Flutter stable
- Android Studio or Xcode for device/simulator builds
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

If CocoaPods has not been initialized on the machine yet, run:

```bash
cd ios
pod install
cd ..
```

## Test and Verify

Run static analysis:

```bash
dart analyze
```

Run the test suite:

```bash
flutter test
```

## Using the App

1. Open `Servers` and add a Transmission server profile.
2. Save the profile after the built-in connection test succeeds.
3. Select the server as active if it is not already active.
4. Use `Torrents` to search, sort, filter, group, inspect, and act on torrents.
5. Use `Dashboard` for live transfer and session summary data.
6. Use `Settings` to change app preferences and Transmission session settings.

## Platform Notes

- Credentials are stored in Android encrypted shared preferences / iOS Keychain through `flutter_secure_storage`.
- Self-signed or otherwise invalid TLS certificates are surfaced as errors. This version does not include a certificate bypass or pinning UI.
- Torrent file content pre-selection before upload is not implemented yet; the add flow supports magnet links, `.torrent` files, destination selection, pause-on-add, and bandwidth priority.
- The files section is a flat list instead of a nested directory tree. File wanted/unwanted and per-file priority actions are implemented.

## Key Implementation Notes

- Tracker grouping uses a deterministic primary tracker rule: lowest tracker tier first, then tracker id, normalized to host/domain when possible.
- Download-path grouping prefers the torrent-level `downloadDir`; missing values fall back to `Unknown Path`.
- Refresh timers are owned by Riverpod controllers and are cancelled on disposal or active-profile changes.
- Grouping, sorting, filter, density, theme, refresh interval, and collapse preferences are persisted locally.

## Current Status

The repository currently passes:

- `dart analyze`
- `flutter test`
"# transpilot" 
