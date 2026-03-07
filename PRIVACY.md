# Privacy Policy

**Red Grid Link**
**Last updated: March 2026**

Red Grid Link is built on a simple principle: your data stays on your device. This policy describes exactly what data the app accesses and what it does with it.

---

## Data Collection Summary

Red Grid Link collects **no personal data**. There are no accounts, no analytics, no crash reporting, no advertising networks, and no third-party SDKs that collect data. All app functionality works without any server communication.

---

## Location Data

Red Grid Link requests access to your device's GPS location **while the app is in use** and optionally **in the background** (for active Field Link sessions). This location data is used solely to:

1. Calculate and display your current MGRS coordinates on the map
2. Share your position with nearby teammates during an active Field Link session

- Location data is **never sent to any server**
- Location data is **never shared with any third party**
- Location data is **stored locally only** in the active session database (Drift/SQLite)
- When a session ends, Field Link position data is discarded unless saved in an After-Action Report
- Background location is used only during active Field Link sessions and can be disabled at any time

---

## Field Link (Proximity Sync) Data

Field Link uses Bluetooth Low Energy (BLE) and WiFi Direct (Android) / AWDL (iOS) to sync position and marker data between nearby devices.

- All Field Link communication is **encrypted with AES-256-GCM** using ECDH P-256 ephemeral session keys
- Session keys are rotated on every reconnect
- Data is exchanged **only between authenticated devices** in the active session
- Session authentication is user-controlled: Open (auto-join), PIN (4-digit code), or QR code (session key encoded)
- No data passes through any server or relay -- all communication is direct device-to-device
- Field Link data is **ephemeral** -- position and marker sync data is not retained after the session ends
- Ghost markers (last-known positions of disconnected teammates) are held in local memory only and cleared when the session ends

---

## Stored Data

The following data is saved locally on your device:

**All users:**
- Session history (local SQLite database)
- Downloaded map tiles (MBTiles files, cached locally)
- App preferences (theme, mode, coordinate format, update interval)
- Magnetic declination and pace count calibration values

**Pro / Pro+Link / Team users:**
- Saved waypoints and markers
- After-Action Report data (tracks, timestamps, team roster, markers)
- Display theme and operational mode preferences

All stored data lives **on your device only**. None of it is ever transmitted to any server.

---

## Network Activity

Red Grid Link makes network requests **only** for the following purposes:

- **Map tile downloads:** Standard HTTPS requests to public tile servers (USGS National Map, OpenTopoMap) to download map packs for offline use. These are standard web requests with no authentication or tracking.
- **In-app purchases:** Processed entirely by Apple (App Store) or Google (Play Store). Red Grid Link never sees your payment details and receives no personal data from these transactions.

There is no:
- Analytics or usage tracking
- Crash reporting service
- Advertising network
- Account system or cloud sync
- Telemetry or update check

You can verify these claims by monitoring network traffic while using the app.

---

## Permissions

| Permission | Purpose | Scope |
|------------|---------|-------|
| Location (While Using App) | Display MGRS coordinates, share position via Field Link | Foreground |
| Location (Always) | Maintain Field Link sync during background operation | Optional, user-enabled |
| Bluetooth | Field Link device discovery and low-power data sync | Active sessions only |
| Nearby Devices (Android) | Field Link peer discovery via Nearby Connections API | Active sessions only |
| Local Network (iOS) | Field Link peer discovery via Multipeer Connectivity | Active sessions only |
| WiFi | High-bandwidth Field Link data transfer (map sync, AAR) | Active sessions only |
| Storage / Files | Save downloaded map packs and After-Action Reports | Local only |
| Foreground Service (Android) | Maintain Field Link sync when app is in background | Active sessions only |

No other permissions are requested.

---

## Third Parties

Red Grid Link contains **no third-party SDKs that collect data**. The app is built on the Flutter framework. In-app purchases use native Apple StoreKit and Google Play Billing APIs -- no third-party purchase SDK is included.

Map tiles are sourced from:
- **USGS National Map** (public domain, US government)
- **OpenTopoMap** (CC-BY-SA, based on OpenStreetMap)

These tile servers receive standard HTTP requests (URL path only). No cookies, tokens, or identifying information are sent.

Encryption is implemented using the `pointycastle` Dart library (open-source, no data collection).

---

## Children

This app does not knowingly collect any data from anyone, including children. No account creation is required or possible.

---

## Data Retention

- **Field Link session data:** Discarded when the session ends
- **Ghost markers:** Held in memory only, cleared on session end
- **Map tiles:** Cached locally until the user deletes them
- **After-Action Reports:** Stored locally until the user deletes them
- **Preferences:** Stored locally until the app is uninstalled

No data is retained on any server because no data is ever sent to any server.

---

## Changes

Any changes to this policy will be reflected in the GitHub repository with an updated date.

---

## Contact

For questions: redgridtactical@gmail.com
GitHub issues: https://github.com/RedGridMGRS/RedGridLink/issues
