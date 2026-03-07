# Red Grid Link - App Store Listing

## App Name
Red Grid Link

## Subtitle (iOS, max 30 chars)
Offline MGRS Nav & Team Sync

## App Icon
Source: `docs/images/icon_1024.png` (1024x1024)
All iOS and Android sizes auto-generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` and `android/app/src/main/res/mipmap-*/`.

## Category
Navigation (primary), Utilities (secondary)

## Short Description (Play Store, max 80 chars)
Offline MGRS navigation with proximity team sync -- no cell service needed.

## Full Description

Your team. Your grid. No cell towers required.

Red Grid Link is an offline-first, MGRS-native coordination platform for small teams (2-8 people) operating beyond reliable cell service. It combines precision land navigation with Field Link -- zero-config proximity sync over Bluetooth and WiFi Direct. No accounts. No servers. No complexity.

FIELD LINK -- TEAM SYNC WITHOUT INFRASTRUCTURE:
Field Link is what sets Red Grid Link apart. Devices within proximity automatically discover each other and share encrypted position and marker data -- no internet, no configuration, no pairing codes. Just turn it on and your team appears on the map.
- BLE + WiFi Direct/AWDL proximity transport (cross-platform Android and iOS)
- AES-256-GCM encrypted sync with ECDH ephemeral session keys
- Compact delta payloads (<200 bytes per position update)
- Tiered session security: Open (auto-join), PIN (4-digit), or QR code
- Ghost markers: see last-known positions when teammates move out of range
- Time-decay visualization: full opacity fades to outline over 30 minutes
- Velocity vectors project teammate movement direction at disconnect
- Snap-to-live animation on reconnect
- Expedition Mode: <3% battery per hour (BLE-only, 30-second updates)
- Ultra Expedition Mode: <2% battery per hour (BLE-only, 60-second updates)
- Auto-reconnect with exponential backoff on disconnect

MGRS-NATIVE NAVIGATION:
Built on the proven MGRS engine from Red Grid MGRS -- the same coordinate system used by NATO forces worldwide.
- Live MGRS coordinates (4/6/8/10-digit precision)
- MGRS grid overlay on offline maps (GZD to 100m resolution)
- Bearing, distance, and dead reckoning tools
- Magnetic declination (WMM model)
- NATO phonetic voice readout for hands-free grid calls

11 TACTICAL TOOLS:
- Dead Reckoning plotter
- Two-point Resection
- Pace Count tracker
- Bearing calculator with back azimuth
- Coordinate Converter (MGRS, lat/lon, DMS, UTM)
- Range Estimation (mil-relation formula)
- Slope Calculator (percentage and angle)
- ETA / Speed Calculator
- Magnetic Declination converter
- Celestial Navigation (sun/moon bearing reference)
- MGRS Precision Reference

OFFLINE MAP SYSTEM:
- Downloadable map packs from USGS Topo (public domain) and OpenTopoMap
- Full offline operation -- maps cached locally as MBTiles
- MGRS grid lines rendered as a dynamic overlay at all zoom levels

4 OPERATIONAL MODES:
One engine, four presentation layers. Terminology, icons, and quick actions adapt to your mission:
- Search & Rescue -- sector assignments, clue markers, search patterns
- Backcountry -- camp, waypoint, and trail navigation
- Hunting -- stand locations, game sightings, property boundaries
- Training -- exercise objectives, rally points, phase lines

AFTER-ACTION REPORTS:
One-tap PDF export containing map snapshot, mission timeline, track data, timestamps, team roster, markers, and session log. Share via AirDrop, file share, or any local transfer method.

4 TACTICAL DISPLAY THEMES:
- Red Light: preserve night-adapted vision (free)
- NVG Green: night observation device compatibility (Pro)
- Day White: high-contrast for daylight (Pro)
- Blue Force: tactical blue display (Pro)

BUILT FOR THE FIELD:
- Glove-friendly UI with 44px+ minimum touch targets
- 3-tap maximum to any primary action
- Haptic feedback on key interactions
- Accelerometer-based step detection for hands-free pace counting
- Landscape and portrait support
- Background location updates with battery drain projection

ZERO FOOTPRINT PRIVACY:
- No accounts. No sign-up. No login.
- No cloud sync. No analytics. No tracking.
- No ads. No third-party data SDKs.
- Location data stays on your device.
- Field Link data is ephemeral -- nothing persists after the session ends.
- All Field Link communication encrypted with AES-256-GCM.
- In-app purchases processed by Apple/Google only.
- Zero data collection. Zero tracking. 100% offline capable.

PRICING:
- Free: All modes, 2-device Field Link, 1 map region, Red Light theme
- Pro ($3.99/mo or $29.99/yr): All themes, unlimited map downloads, AAR export (2 devices)
- Pro+Link ($5.99/mo or $44.99/yr): Pro + full 8-device Field Link
- Team ($199.99/yr): Pro+Link for 8 seats
- Lifetime ($99.99): Pro+Link forever, one-time purchase

## Promotional Text (iOS, max 170 chars)
Offline MGRS navigation + encrypted BLE team sync for 2-8 people. No cell towers, no accounts, no servers. 11 tactical tools, 4 display themes, zero tracking.

## Keywords (iOS, max 100 chars)
mgrs,tactical,navigation,offline,team,sync,BLE,military,grid,SAR,hunting,backcountry,map,GPS,compass

## What's New (v1.2.1)
Red Grid Link v1.2.1 -- reliability and navigation update:
- Fixed Field Link session creation: resolved iOS Bluetooth adapter state detection that prevented session start even with Bluetooth enabled
- Field Link service initialization fix: transport state listeners now properly wired at startup
- Persistent waypoint list: save, rename, and manage multiple waypoints
- Relative bearing arrow: arrow now points the direction to turn, not just compass bearing
- Resection and Dead Reckoning tools now integrate with waypoint system
- New app icon: updated network-star design with corner brackets
- BLE transport debug logging for connection troubleshooting
- Demo mode for screenshots (Washington DC coordinates)
- 783 tests passing, 0 warnings

## What's New (v1.2)
Red Grid Link v1.2 -- field hardening release:
- GPS Kalman filter for smoother, more accurate position tracking
- Peer HUD overlay: see distance and bearing to teammates on the map
- Step detector for accelerometer-based pace counting
- Ultra Expedition battery mode (<2%/hr for extended operations)
- Auto-reconnect with exponential backoff when peers go out of range
- Session history: review past sessions and team activity
- Offline map download UI with progress and region management
- Help & Getting Started guide accessible from Settings
- About screen with full disclaimers and Terms of Use
- Text contrast improvements across all themes (WCAG 4.5:1)
- Crash reporting (Sentry, privacy-safe -- no location data sent)
- Localization framework (English + Spanish)
- Bug fixes and stability improvements from QA testing
- 783 tests passing, 0 warnings

## What's New (v1.0)
Red Grid Link v1.0 -- initial release:
- Live MGRS navigation with 1-meter precision
- Field Link proximity sync (BLE + WiFi Direct/AWDL)
- AES-256-GCM encrypted sync with ECDH key exchange
- Offline map downloads (USGS Topo + OpenTopoMap)
- Ghost markers with time-decay visualization
- 4 operational modes (SAR, Backcountry, Hunting, Training)
- 4 tactical display themes
- 11 tactical land navigation tools
- After-Action Report PDF export
- NATO phonetic voice readout

## Privacy Highlights
- No data collected
- No tracking
- No analytics
- All data stays on device
- Location used only when app is in foreground (and for Field Link background sync)
- Field Link shares position only with nearby peers via encrypted BLE/WiFi Direct
- No server communication required for any feature

## Privacy URL
https://github.com/RedGridMGRS/RedGridLink/blob/master/PRIVACY.md

## Support URL
https://github.com/RedGridMGRS/RedGridLink/issues

## Age Rating
4+ / Everyone

## Price
Free (with Pro, Pro+Link, Team, and Lifetime in-app purchases)
