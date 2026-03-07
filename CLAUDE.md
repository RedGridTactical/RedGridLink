# CLAUDE.md — Red Grid Link Development Guide

## Project Overview

Red Grid Link is an offline-first, MGRS-native proximity coordination platform for small civilian teams (2-8 people). Built with Flutter/Dart. The canonical reference is `RED_GRID_LINK_VISION.md`.

## Quick Start

```bash
# Flutter SDK location
C:/Users/gianl/flutter/bin/flutter.bat

# Install dependencies
flutter pub get

# Run code generation (Drift)
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests (749 tests)
flutter test

# Run app
flutter run
```

## Architecture

- **State Management:** Riverpod (`flutter_riverpod`)
- **Database:** Drift (SQLite) — code generation with `build_runner`
- **Maps:** `flutter_map` + `flutter_map_mbtiles` (offline MBTiles)
- **BLE:** `flutter_blue_plus` (custom GATT transport)
- **Platform Channels:** Android Nearby Connections + iOS Multipeer Connectivity
- **PDF Export:** `pdf` + `printing` packages
- **IAP:** `in_app_purchase` package

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # MaterialApp with tactical theme (ConsumerWidget)
├── core/
│   ├── constants/            # App, BLE, sync, map constants
│   ├── errors/               # Exception hierarchy + error handler
│   ├── extensions/           # DateTime, LatLng, String extensions
│   ├── theme/                # Tactical color schemes + text styles
│   └── utils/                # MGRS, tactical, haptics, voice, geo, crypto
├── data/
│   ├── database/             # Drift tables (6) + DAOs (6) + generated code
│   ├── models/               # 14 data models (Position, Peer, Ghost, etc.)
│   └── repositories/         # 7 repositories (settings, session, peer, etc.)
├── services/
│   ├── location/             # GPS stream + permission handling
│   ├── step_detector/        # Accelerometer-based step detection (sensors_plus)
│   ├── field_link/
│   │   ├── transport/        # BLE + Android P2P + iOS P2P + manager
│   │   ├── discovery/        # BLE scan/advertise, session join
│   │   ├── sync/             # CRDT (LWW, GCounter), delta encoding, engine
│   │   ├── security/         # Tiered auth, ECDH, AES-256
│   │   ├── ghost/            # Opacity decay state machine
│   │   ├── battery/          # Expedition/Active modes
│   │   └── field_link_service.dart  # Facade
│   ├── map/                  # MBTiles, MGRS grid overlay, controller
│   ├── aar/                  # AAR compilation, PDF generation, export
│   └── iap/                  # In-app purchase, purchase handler
├── providers/                # Riverpod: location, settings, theme, field_link,
│                             #   map, aar, iap
└── ui/
    ├── common/
    │   ├── widgets/          # TacticalButton, MGRSDisplay, ProGate, etc.
    │   └── dialogs/          # Confirm, TextInput, PinEntry
    └── screens/
        ├── home/             # 5-tab scaffold (Map/Grid/Link/Tools/Settings)
        ├── map/              # flutter_map + MGRS overlay + peer/ghost/marker layers
        ├── grid/             # Solo MGRS display + wayfinder
        ├── field_link/       # Session management, peer list, ghost list
        ├── tools/            # 11 tactical tools
        ├── report/           # AAR preview + PDF export
        ├── settings/         # Theme, calibration, mode, subscriptions
        └── onboarding/       # Disclaimer, permissions, quick start
```

## Native Platform Code

```
android/app/src/main/kotlin/com/redgrid/red_grid_link/
├── MainActivity.kt              # Registers platform channels
├── NearbyConnectionsChannel.kt  # WiFi Direct via Nearby Connections API
├── BatteryChannel.kt            # Battery level/state
└── FieldLinkForegroundService.kt  # Background sync notification

ios/Runner/
├── AppDelegate.swift            # Registers platform channels
├── MultipeerChannel.swift       # AWDL via Multipeer Connectivity
└── BatteryChannel.swift         # Battery level/state
```

## Key Conventions

- **MGRS is the primary coordinate system** — always displayed, never optional
- **Offline-first** — no feature requires network connectivity
- **Glove-friendly UI** — minimum 44px touch targets
- **4 tactical themes:** Red Light (free), NVG Green (pro), Day White (pro), Blue Force (pro)
- **4 operational modes:** SAR, Backcountry, Hunting, Training — same engine, different terminology
- **Manual JSON serialization** — no freezed/json_serializable, manual toJson/fromJson
- **Compact JSON keys** for wire payloads (e.g., `lat`, `lon`, `ts`, `spd`)
- **ConsumerWidget pattern** — all screen widgets are ConsumerWidget/ConsumerStatefulWidget

## Field Link (Proximity Sync)

- Custom BLE + Platform P2P — zero licensing costs
- BLE for discovery + low-power sync; WiFi Direct/AWDL for bulk transfers
- CRDT-based sync: LWW Register for positions, G-Counter for sequences
- Delta payloads <200 bytes for position updates
- AES-256 encryption with ECDH ephemeral session keys
- Ghost markers: opacity decay 100% -> 50% (5min) -> 25% (15min) -> outline (30min)
- Tiered security: Open (auto-join), PIN (4-digit), QR (session key encoded)

## Monetization

- **Free:** All modes, 2 devices, 1 map region, Red Light theme
- **Pro ($3.99/mo or $29.99/yr):** All themes, unlimited maps, AAR export (2 devices)
- **Pro+Link ($5.99/mo or $44.99/yr):** Pro + 8-device Field Link
- **Team ($199.99/yr):** Pro+Link for 8 seats
- **Lifetime ($99.99):** Pro+Link forever

## Testing

```bash
# All tests (783 tests)
flutter test

# Specific test file
flutter test test/core/utils/mgrs_test.dart

# Integration tests (requires device/emulator)
flutter test integration_test/

# With coverage
flutter test --coverage
```

Test coverage areas:
- Core utils: MGRS, tactical, geo, voice, extensions (159 tests)
- Data models: Ghost, CRDT properties (37 tests)
- Sync engine: Delta encoding, conflict resolution, sync lifecycle (58 tests)
- Ghost manager: Opacity decay, velocity projection (28 tests)
- Battery manager: Mode switching, drain projection, ultra expedition (19 tests)
- AAR service: Compilation, PDF generation (47 tests)
- IAP service: Purchase flow, entitlement handling (56 tests)
- Repositories: Settings CRUD (21 tests)
- Providers: All settings notifiers (28 tests)
- Step detector: Accelerometer step detection, debounce, orientation (21 tests)
- Location: Kalman filter smoothing (12 tests)
- Tools: Coordinate converter, range estimation, slope calculator (36 tests)
- Widgets: TacticalButton, HomeScreen, OnboardingScreen (27 tests)
- App widget: Root app rendering (1 test)

MGRS validation reference: Fort Liberty -> 17S prefix, Washington DC -> 18S, London -> 30U.

## Ported From RedGridMGRS

These utilities were ported from the React Native RedGridMGRS app:
- `mgrs.dart` <- `RedGridMGRS/src/utils/mgrs.js` (DMA TM 8358.1 spec)
- `tactical.dart` <- `RedGridMGRS/src/utils/tactical.js`
- `haptics.dart` <- `RedGridMGRS/src/utils/haptics.js`
- `voice.dart` <- `RedGridMGRS/src/utils/voice.js`
- `tactical_colors.dart` <- `RedGridMGRS/src/hooks/useTheme.js`

## Development Phases

See the full plan at `.claude/plans/zazzy-zooming-duckling.md`.

| Phase | Status |
|-------|--------|
| 0: Foundation + Core Ports | Complete |
| 1: Data Layer (Drift) | Complete |
| 2A: Location Service | Complete |
| 2B: Map System | Complete |
| 2C: Common Widgets | Complete |
| 3A: Transport Layer | Complete |
| 3B: Sync Engine | Complete |
| 4A: Grid + Tools Screens | Complete |
| 4B: Field Link UI | Complete |
| 4C: Map + Link Integration | Complete |
| 5: Home + Navigation + Onboarding | Complete |
| 6: AAR + IAP + Export | Complete |
| 7: Polish + Integration Testing | Complete |
| V1.0: Rename + Security + Maps + IAP | Complete |
| V1.1-P1: IAP Fix + GPS Init | Complete |
| V1.1-P2: 3 Missing Tools (11 total) | Complete |
| V1.1-P3: Operational Modes Wiring | Complete |
| V1.1-P4: Store Listing Updates | Complete |
| V1.1-P5: Offline Map Download UI | Complete |
| V1.1-P6: Field Hardening (Kalman, HUD, Sentry, l10n) | Complete |
| V1.1-P7: Tester Feedback (Help, About, Terms, Contrast) | Complete |
| V1.1-P8: QA/QC Pass | In Progress |
