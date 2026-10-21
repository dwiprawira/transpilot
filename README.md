# TransPilot

<p align="center">
  <img src="icon.png" alt="TransPilot icon" width="140" />
</p>

![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-47C5FB?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-4F46E5?style=for-the-badge)
![Transmission RPC](https://img.shields.io/badge/Transmission-RPC-2F855A?style=for-the-badge)
![Android](https://img.shields.io/badge/Android-Supported-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-Supported-111827?style=for-the-badge&logo=apple&logoColor=white)
[![Build](https://github.com/dwiprawira/transpilot/actions/workflows/build-release.yml/badge.svg)](https://github.com/dwiprawira/transpilot/actions/workflows/build-release.yml)

> This project was 100% created using Codex AI.

TransPilot is a production-minded Flutter mobile client for managing remote Transmission servers through the Transmission RPC API. It supports multiple saved servers, secure credential storage, adaptive phone and tablet layouts, session-aware RPC retry handling, torrent grouping, and live session controls on Android and iOS.

## 📦 Download and Install

<p align="center">
  <a href="https://github.com/dwiprawira/transpilot/releases/latest">
    <img src="https://img.shields.io/github/v/release/dwiprawira/transpilot?display_name=tag&style=for-the-badge&label=Latest%20Release&color=2F855A" alt="Latest TransPilot release" />
  </a>
</p>

<table>
  <tr>
    <td align="center" width="50%">
      <a href="https://github.com/dwiprawira/transpilot/releases/latest/download/TransPilot-android.apk">
        <img src="https://cdn.simpleicons.org/android/3DDC84" width="64" height="64" alt="Android" />
      </a>
      <br />
      <strong>Android</strong>
      <br />
      <sub>Download and install the latest release APK.</sub>
      <br /><br />
      <a href="https://github.com/dwiprawira/transpilot/releases/latest/download/TransPilot-android.apk">
        <img src="https://img.shields.io/badge/Download-APK-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Download Android APK" />
      </a>
    </td>
    <td align="center" width="50%">
      <a href="https://github.com/dwiprawira/transpilot/releases/latest/download/TransPilot-ios.ipa">
        <img src="https://cdn.simpleicons.org/apple/808080" width="64" height="64" alt="iOS" />
      </a>
      <br />
      <strong>iOS IPA</strong>
      <br />
      <sub>Download the unsigned IPA for manual sideloading.</sub>
      <br /><br />
      <a href="https://github.com/dwiprawira/transpilot/releases/latest/download/TransPilot-ios.ipa">
        <img src="https://img.shields.io/badge/Download-IPA-555555?style=for-the-badge&logo=apple&logoColor=white" alt="Download iOS IPA" />
      </a>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="https://intradeus.github.io/http-protocol-redirector?r=sidestore%3A%2F%2Fsource%3Furl%3Dhttps%3A%2F%2Fgithub.com%2Fdwiprawira%2Ftranspilot%2Freleases%2Flatest%2Fdownload%2Faltstore-source.json">
        <img src="https://sidestore.io/assets/icon.png" width="72" height="72" alt="SideStore" />
      </a>
      <br />
      <strong>SideStore</strong>
      <br />
      <sub>Add the TransPilot source for one-tap install and updates.</sub>
      <br /><br />
      <a href="https://intradeus.github.io/http-protocol-redirector?r=sidestore%3A%2F%2Fsource%3Furl%3Dhttps%3A%2F%2Fgithub.com%2Fdwiprawira%2Ftranspilot%2Freleases%2Flatest%2Fdownload%2Faltstore-source.json">
        <img src="https://img.shields.io/badge/Add_to-SideStore-5B67F1?style=for-the-badge" alt="Add TransPilot to SideStore" />
      </a>
    </td>
    <td align="center" width="50%">
      <a href="https://intradeus.github.io/http-protocol-redirector?r=altstore%3A%2F%2Fsource%3Furl%3Dhttps%3A%2F%2Fgithub.com%2Fdwiprawira%2Ftranspilot%2Freleases%2Flatest%2Fdownload%2Faltstore-source.json">
        <img src="https://raw.githubusercontent.com/altstoreio/AltStore/marketplace/AltStore/Resources/Icons.xcassets/Classic/Original.appiconset/Group%2023.png" width="72" height="72" alt="AltStore Classic" />
      </a>
      <br />
      <strong>AltStore Classic</strong>
      <br />
      <sub>Add the TransPilot source for one-tap install and updates.</sub>
      <br /><br />
      <a href="https://intradeus.github.io/http-protocol-redirector?r=altstore%3A%2F%2Fsource%3Furl%3Dhttps%3A%2F%2Fgithub.com%2Fdwiprawira%2Ftranspilot%2Freleases%2Flatest%2Fdownload%2Faltstore-source.json">
        <img src="https://img.shields.io/badge/Add_to-AltStore-6E56CF?style=for-the-badge" alt="Add TransPilot to AltStore Classic" />
      </a>
    </td>
  </tr>
</table>

<details>
  <summary><strong>Manual source installation and troubleshooting</strong></summary>

If a one-tap button does not open on iOS, copy this URL into the Sources section of SideStore or AltStore Classic:

```text
https://github.com/dwiprawira/transpilot/releases/latest/download/altstore-source.json
```

The IPA is unsigned by design. SideStore or AltStore Classic signs it with the Apple account configured on the device.
</details>

## ✨ Highlights

- Multi-server profile management with secure credential storage
- Automatic `X-Transmission-Session-Id` negotiation and retry handling
- Adaptive UI for phones, tablets, portrait, and landscape
- Torrent search, filter, sort, grouping, detail view, and actions
- Add torrent via magnet link, `.torrent` file, clipboard, or direct open/share from the OS
- Session dashboard and editable server/session settings
- Unit tests for RPC behavior, DTO mapping, grouping, filtering, and controller logic

## 🧩 Feature Set

### 📡 Connectivity

- Multiple saved Transmission server profiles
- Secure username/password storage via `flutter_secure_storage`
- HTTP basic auth support
- Optional per-server allowance for self-signed or otherwise invalid TLS certificates
- Graceful handling for invalid credentials, timeouts, malformed endpoints, unreachable hosts, and certificate issues

### 📋 Torrent Management

- Open `.torrent` files directly into the add torrent flow on Android and iOS
- Open `magnet:` links directly into the add torrent flow from supported apps and browsers
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

- Flutter stable 3.47.7 (selected through `.fvmrc`)
- Android Studio or Xcode
- A reachable Transmission RPC server

### Install dependencies

```bash
fvm flutter pub get
```

### Run on Android

```bash
fvm flutter run -d android
```

### Run on iOS

```bash
fvm flutter run -d ios
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
fvm dart analyze
```

Run tests:

```bash
fvm flutter test
```

## 🔁 Automated Builds and Releases

GitHub Actions uses Flutter 3.47.7 and Xcode 27 to run static analysis, tests, and Android/iOS builds only when a `v*` release tag is pushed. Build artifacts are retained on each workflow run for 14 days.

To publish a release, first update `version` in `pubspec.yaml`, then push a matching version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The release workflow publishes the Android APK, unsigned iOS IPA, and an AltStore/SideStore-compatible source manifest. A tag such as `v1.0.0` must match `version: 1.0.0+...` in `pubspec.yaml`.

## 📱 Usage Flow

1. Open `Servers` and add a Transmission server profile.
2. Test the connection and save the profile.
3. Set the server as active.
4. Open a `magnet:` link or `.torrent` file from another app to jump straight into `Add Torrent`, or use the add button inside `Torrents`.
5. Open `Torrents` to browse, group, sort, and manage torrents.
6. Open `Dashboard` for session and transfer overview.
7. Open `Settings` for app preferences and session settings.

## 📝 Platform Notes

- The current Flutter/Xcode toolchain supports iOS 15 and newer.
- Credentials are stored using platform-backed secure storage on Android and iOS Keychain through `flutter_secure_storage`.
- Android registers `application/x-bittorrent` files and the `magnet:` scheme so supported apps can hand torrents directly to TransPilot.
- iOS registers `.torrent` documents and the `magnet:` URL scheme so the add torrent sheet can be opened from Files and compatible browsers/apps.
- HTTPS connections can optionally allow invalid or self-signed certificates on a per-server basis. Leave this disabled unless you trust the server and network.
- Torrent pre-selection from `.torrent` contents before upload is not implemented yet.
- The files section is currently a flat list instead of a nested directory tree.

## 🔧 Implementation Notes

- Tracker grouping uses a deterministic primary tracker rule: lowest tier first, then tracker id, normalized to host/domain where possible.
- Download-path grouping prefers torrent-level `downloadDir`; missing values fall back to `Unknown Path`.
- Refresh timers are owned by Riverpod controllers and are cancelled on disposal or active-profile changes.
- Grouping, sorting, filter, theme, refresh interval, and collapse preferences are persisted locally.
- Launcher icons are generated from `icon.png` via [generate_launcher_icons.ps1](tooling/generate_launcher_icons.ps1) or [generate_launcher_icons.sh](tooling/generate_launcher_icons.sh).

## 📊 Current Status

The repository currently passes:

- `dart analyze`
- `flutter test`

## 🤖 Credits

This project was fully created using Codex AI.
