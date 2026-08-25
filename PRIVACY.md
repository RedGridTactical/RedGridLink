# Privacy Policy

**Red Grid Link**
**Last updated: May 2026**

Red Grid Link is built on a simple principle: your operational data stays on your device. This policy describes exactly what data the app accesses and what it does with it.

---

## Data Collection Summary

Red Grid Link does not collect personal data, does not run analytics, has no advertising networks, requires no account, and does not cloud-sync operational data (positions, markers, sessions, tracks) or send it to Red Grid servers. Field Link shares operational data only with nearby peers in your active session, and exports happen only when you initiate them.

Other outbound activity is limited to map tile downloads you request, native store purchase flows, and optional crash diagnostics described below under **Crash Diagnostics**, which can be disabled by your IT/admin or omitted entirely from a build by your provider.

---

## Location Data

Red Grid Link requests access to your device's GPS location **while the app is in use** and optionally **in the background** (for active Field Link sessions). This location data is used solely to:

1. Calculate and display your current MGRS coordinates on the map
2. Share your position with nearby teammates during an active Field Link session

- Location data is **never sent to any server** controlled by Red Grid Link or any third party
- Location data is **stored locally only** in the active session database (Drift/SQLite)
- Position data persists locally as part of session history, saved tracks, markers, and After-Action Reports until you delete the session
- Background location is used only during active Field Link sessions and can be disabled at any time
- Crash diagnostics (if enabled in the build) explicitly strip location coordinates from any captured exception payload before transmission

---

## Field Link (Proximity Sync) Data

Field Link uses Bluetooth Low Energy (BLE) to sync position, marker, and annotation data between nearby devices. On iOS, Apple Multipeer Connectivity (which uses AWDL) runs in parallel as a higher-bandwidth secondary transport so peers stay discoverable when the app is backgrounded. On Android, Google Play Services Nearby Connections runs in parallel where Play Services is available; on devices without Play Services the stack falls back to BLE-only.

- Field Link communication is **end-to-end between paired devices** — no data passes through any server or relay
- In **PIN** and **QR** session modes, Field Link payloads are **encrypted with AES-256-GCM** using session keys derived from an ECDH P-256 key exchange between paired peers
- In **Open** session mode (auto-join, no PIN/QR), payloads are not encrypted; this mode is intended for training, demos, and trusted environments only
- Session keys are derived per session and rotated when the session restarts
- Data is exchanged **only between authenticated devices** in the active session

### What Field Link persists locally

These items are saved on your device for as long as you keep them:

- The session record (id, name, security mode, operational mode, created timestamp)
- Your peers' device IDs, callsigns, roles, and last-known positions
- Markers, annotations, and tracks created during the session
- After-Action Reports you generate from a session

### What Field Link does NOT persist

- Ephemeral keys (ECDH session secrets) are held in memory only and discarded when the session ends
- Ghost markers (last-known positions of disconnected teammates that haven't been promoted to saved markers) are held in memory only and cleared on session end

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

Stored operational data lives **on your device only** unless you share it with nearby Field Link peers or export it yourself. Red Grid does not transmit stored operational data to its servers.

---

## Network Activity

Red Grid Link makes network requests only for the following purposes:

- **Map tile downloads:** Standard HTTPS requests to the tile server you select (OpenStreetMap or OpenTopoMap by default) to download offline region packs. These are standard web requests with no authentication, cookies, or tracking. Public OpenStreetMap tile downloads are subject to that project's [Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/); for sustained heavy offline usage we recommend a licensed provider.
- **In-app purchases:** Processed entirely by Apple (App Store) or Google (Play Store). Red Grid Link never sees your payment details and receives no personal data from these transactions.
- **Crash diagnostics (optional, release-only):** If the build was compiled with a Sentry DSN supplied by your provider, uncaught exceptions and stack traces may be transmitted to Sentry to help us fix crashes. See **Crash Diagnostics** below.

There is no:
- Analytics or usage tracking
- Advertising network
- Account system or cloud sync of operational data
- Telemetry or update check

You can verify these claims by monitoring network traffic while using the app.

---

## Crash Diagnostics

Red Grid Link uses [Sentry](https://sentry.io/) for optional crash and exception reporting **in release builds only**, and only when a Sentry DSN was compiled into the build by the provider. The integration is configured to:

- Send `false` for `sendDefaultPii` so user-identifying request data is not transmitted
- Strip GPS coordinates from captured exception payloads before transmission via a `beforeSend` hook
- Sample 20% of trace events (not user-identifying)
- Operate exclusively in release mode — debug and profile builds never initialize Sentry

Crash diagnostics are not enabled in builds without a configured DSN. If you want to verify whether your build has Sentry enabled, see **Settings → Help & Support** for the build configuration display.

To opt out: use a build that was compiled without a Sentry DSN. Direct downloads from the App Store and Play Store currently include Sentry; enterprise/source builds are at your provider's discretion.

---

## Permissions

| Permission | Purpose | Scope |
|------------|---------|-------|
| Location (While Using App) | Display MGRS coordinates, share position via Field Link | Foreground |
| Location (Always) | Maintain Field Link sync during background operation | Optional, user-enabled |
| Bluetooth | Field Link device discovery and low-power data sync | Active sessions only |
| Nearby Devices (Android) | Required to scan for BLE peers and to use Google Play Services Nearby Connections as a parallel transport | Active sessions only |
| Local Network (iOS) | Field Link peer discovery via Multipeer Connectivity | Active sessions only |
| Wi-Fi (iOS) | Multipeer Connectivity uses Wi-Fi for high-bandwidth peer transport when available | Active sessions only |
| Storage / Files | Save downloaded map packs and After-Action Reports | Local only |
| Foreground Service (Android) | Maintain Field Link sync when app is in background | Active sessions only |

No other permissions are requested.

---

## Third Parties

Red Grid Link's third-party software components:

- **Sentry** — Optional crash diagnostics in release builds only, when a DSN is compiled in. PII off, location stripped, opt-out via a Sentry-less build.
- **Apple StoreKit / Google Play Billing** — Native in-app purchase APIs. Red Grid Link never sees your payment details.
- **`pointycastle`** — Open-source Dart cryptography library (no data collection).
- **OpenStreetMap / OpenTopoMap tile servers** — Receive standard HTTPS tile requests when you download an offline region pack. URL path only; no cookies, tokens, or identifying information.

The app is built on the Flutter framework.

---

## Children

This app does not knowingly collect any data from anyone, including children. No account creation is required or possible.

---

## Data Retention

- **Operational session data (markers, annotations, tracks, peers):** Stored locally until you delete the session
- **Ephemeral session secrets (encryption keys):** In-memory only, discarded on session end
- **Ghost markers (in-memory):** Discarded on session end
- **Map tiles:** Cached locally until you delete them
- **After-Action Reports:** Stored locally until you delete them
- **Preferences:** Stored locally until the app is uninstalled
- **Crash diagnostics (when enabled):** Subject to [Sentry's data retention policy](https://docs.sentry.io/security-legal-pii/security/) — typically 30 to 90 days depending on plan

No operational data is retained on Red Grid servers because the app does not send operational data to Red Grid servers.

---

## Changes

Any changes to this policy will be reflected in the GitHub repository with an updated date.

---

## Contact

For questions: support@redgridtactical.com
GitHub issues: https://github.com/RedGridTactical/RedGridLink/issues
