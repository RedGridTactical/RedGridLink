# Red Grid Link — Product Roadmap

> **Platform:** iOS available on the App Store. Android version planned.

## V1.0 — Foundation Release

**Status: Complete**

Core offline MGRS navigation and proximity coordination platform.

- MGRS-native navigation with 10-digit grid precision
- 4 operational modes: SAR, Backcountry, Hunting, Training
- Field Link: BLE + WiFi Direct proximity sync (2-8 devices)
- CRDT-based sync engine with delta encoding (<200 bytes/update)
- AES-256-GCM encrypted communications with ECDH key exchange
- Tiered session security: Open, PIN, QR code
- Ghost markers with opacity decay for disconnected peers
- 11 tactical tools (dead reckoning, resection, pace count, bearing/back azimuth, coordinate converter, range estimation, slope calculator, ETA/speed, declination, celestial nav, MGRS precision ref)
- MBTiles offline map downloads (USGS Topo + OpenTopo)
- After-Action Report (AAR) PDF generation and export
- 4 tactical themes: Red Light, NVG Green, Day White, Blue Force
- Mode-specific UI labels adapt to operational context
- In-app subscriptions: Free / Pro / Pro+Link / Team / Lifetime
- Android foreground service for background sync
- 783 tests, 0 warnings

---

## V1.1 — Field Hardening

**Status: Complete** — App v1.2.0

Real-world testing feedback and reliability improvements.

- [x] Field Link connection stability (exponential backoff reconnect, max 5 retries)
- [x] Battery optimization (Ultra Expedition mode: 60s BLE, <2%/hr)
- [x] GPS accuracy filtering (1D Kalman filter for lat/lon smoothing)
- [x] Step detector for accelerometer-based pace counting (sensors_plus)
- [x] Offline map download UI with progress and region management
- [x] Haptic feedback for proximity alerts and sync events
- [x] Peer distance/bearing HUD overlay on map view
- [x] Session history persistence (Drift table, DAO, schema v2 migration)
- [x] Crash reporting (Sentry, release-mode only, location data stripped)
- [x] Accessibility + contrast audit (WCAG 4.5:1 all themes, text contrast fixes)
- [x] Localization framework (ARB-based l10n, English + Spanish)
- [x] Help & Guide screen (quick start, FAQ, replay onboarding)
- [x] About screen (full app info, disclaimers, Terms/Privacy/Licenses)
- [x] Terms of Use / EULA screen (8 sections)
- [x] Settings screen UX overhaul (nav rows for Help/About, updated map text)
- [x] Bug fixes and stability improvements from QA testing

---

## V1.2.1 — Reliability & Navigation

**Status: Complete** — App v1.2.1

Bug fixes, waypoint persistence, and heading improvements.

- [x] Fixed Field Link session creation (initialize() call was missing after construction)
- [x] Persistent waypoint system: save, rename, delete multiple waypoints (SharedPreferences)
- [x] Relative bearing arrow: arrow now shows direction to turn, not just compass bearing
- [x] Demo mode: fake Washington DC coordinates for App Store screenshots
- [x] BLE transport debug logging for connection troubleshooting
- [x] Resection and Dead Reckoning tools integrated with new waypoint system
- [x] Compass heading audit: verified tilt-compensated math, low-pass filter, 0/360 wrap

---

## V1.3 — Team Features

**Status: Complete** — App v1.3.0

Enhanced team coordination for larger groups.

- [x] Team roles: Lead (session admin, can promote others), Scout, Medic, Comms + custom roles (custom callsign + icon)
- [x] Waypoint sharing: "Save to My Waypoints" (personal, persistent) or "Share with Team" (synced via CRDT, session-scoped)
- [x] Shared annotations layer: tap-to-place polyline/polygon drawing, visible to all peers
- [x] Team boundary alerts: Lead draws polygon geofence, both Lead and boundary-crosser notified (single boundary per session)
- [x] Enhanced AAR: per-member tracks, role labels, boundary events in PDF export
- [x] Custom map marker categories (hazard, rally point, objective, cache)
- [x] Voice callout queue (NATO phonetic auto-announce with correct digit pronunciation)
- [x] Export/import session data (versioned JSON backup/restore with validation)
- [x] 986 tests, 0 warnings

---

## V1.4 — Android Launch + Extended Range

**Target: Q3 2026**

Android release, BLE Long Range, and new features driven by community feedback.

### Android Launch
- [ ] Android QA: test BLE transport, Nearby Connections, foreground service on physical devices
- [ ] Play Store listing: keystore, screenshots, privacy policy, content rating
- [ ] Codemagic android-release workflow verification and Play Store publishing
- [ ] F-Droid submission with reproducible build configuration (pinned SDK versions, Gradle config)

### BLE Long Range (Android-only — Apple removed Coded PHY support in iOS 14)
- [ ] BLE Long Range (Coded PHY S=8): 3-4x range improvement (~400m-1km) via `flutter_blue_plus` `setPreferredPhy`
- [ ] Adaptive PHY selection: auto-fallback to 1M PHY when Coded PHY unavailable or on iOS
- [ ] PHY indicator on peer markers showing current connection type (1M vs Coded)

### Connectivity
- [ ] Connection quality indicator (RSSI-based signal strength on peer markers, color-coded green/yellow/red)
- [ ] Range test mode: built-in tool showing RSSI, current PHY, estimated distance between two devices

### FixPhrase — Location in Four Words
- [ ] Port FixPhrase algorithm to Dart (open source, patent-free what3words alternative)
- [ ] Display FixPhrase alongside MGRS coordinates on grid view
- [ ] FixPhrase search input: type four words to navigate to a location
- [ ] Fully offline: word list bundled as asset, no network required

### Map Sources
- [ ] Add vanilla OpenStreetMap as tile source option (alongside USGS Topo + OpenTopoMap)
- [ ] Tile source selector in map settings

---

## V2.0 — Intelligence Layer + ATAK Interop

**Target: Q4 2026**

Terrain analysis, environmental awareness, Cursor on Target (CoT) interoperability, and Meshtastic integration.

- [ ] Meshtastic BLE bridge: detect nearby Meshtastic radios and route Field Link traffic through LoRa mesh for multi-kilometer range
- [ ] Meshtastic auto-discovery: scan for Meshtastic GATT service UUID, offer bridge mode when detected
- [ ] ATAK interoperability layer (CoT XML message format — send/receive)
- [ ] CoT SA (Situational Awareness) message support (position, callsign, team)
- [ ] CoT bridge: translate Field Link CRDT positions to/from CoT events on local network
- [ ] Multicast UDP listener for CoT traffic on shared WiFi/mesh radio networks
- [ ] Elevation profile along planned routes (from DEM data)
- [ ] Slope and aspect analysis for terrain assessment
- [ ] Line-of-sight calculator between two MGRS positions
- [ ] Weather overlay integration (offline-cached NOAA data)
- [ ] Sunrise/sunset/moonrise with bearing overlays
- [ ] Magnetic declination auto-calculation by position and date
- [ ] Terrain difficulty scoring for route segments
- [ ] Offline gazetteer (search by place name, peak, trail)
- [ ] Contour line generation from DEM tiles
- [ ] Print-ready topographic map export (PDF at specified scale)

---

## V2.1 — Advanced Navigation

**Target: Q1 2027**

Professional-grade navigation tools.

- [ ] Route planning with MGRS waypoint sequences (moved from V1.3)
- [ ] Freehand annotation drawing mode (complements V1.3 tap-to-place)
- [ ] Interactive team movement replay with timeline scrubber (deferred from V1.3)
- [ ] Track recording with breadcrumb trail
- [ ] Navigate-to-waypoint with bearing/distance compass
- [ ] Track statistics: distance, elevation gain/loss, moving time, pace
- [ ] GPX import/export (interoperability with Garmin, Gaia, etc.)
- [ ] KML/KMZ import for boundary and area overlays
- [ ] Coordinate format flexibility (UTM, USNG, DD, DMS alongside MGRS)
- [ ] Configurable map datum support
- [ ] Offline reverse geocoding
- [ ] Multi-waypoint route optimization (traveling salesman)

---

## V3.0 — Connected Operations

**Target: Q2 2027**

Optional cloud features for teams that need them (offline-first principles preserved).

- [ ] Cloud session relay for non-proximate team members (encrypted relay server)
- [ ] Web dashboard for team leads (view team positions on desktop browser)
- [ ] Session scheduling and pre-planned operations
- [ ] Post-session cloud AAR sharing (encrypted link, expiring)
- [ ] Team management portal (invite members, manage seats)
- [ ] Push notifications for session invites
- [ ] Mesh networking support (relay position data through intermediate peers)
- [ ] Integration API for third-party tools (webhook on position update)

---

## V3.1 — Sensor Integration

**Target: Q3 2027**

External hardware and sensor support.

- [ ] Garmin inReach integration (satellite messaging + position relay)
- [ ] External GPS receiver support (Bluetooth NMEA devices)
- [ ] Barometric altimeter calibration (phone sensor fusion)
- [ ] Heart rate monitor integration for SAR team health monitoring
- [ ] Radio frequency scanning integration (SDR metadata tagging)
- [ ] Drone position overlay (MAVLink telemetry display)

---

## V4.0 — Training & Simulation

**Target: Q4 2027**

Structured training and after-action capabilities.

- [ ] Training scenario builder (define objectives, boundaries, events)
- [ ] Real-time scoring for land navigation exercises
- [ ] Simulated peer positions for solo practice
- [ ] Instructor mode (observe all teams, inject events, grade performance)
- [ ] Historical session replay with annotations
- [ ] Performance analytics dashboard (accuracy, timing, route efficiency)
- [ ] Certification tracking for SAR/military land nav courses
- [ ] Scenario library (share training scenarios between teams)
- [ ] AR compass overlay (camera-based bearing visualization)

---

## Ongoing

These items are continuously improved across all versions:

- Security audits and cryptographic library updates
- Battery performance optimization
- Map tile source expansion (Mapbox, custom tile servers)
- Platform updates (Android API level, iOS SDK)
- Test coverage expansion (target 90%+ line coverage)
- Store listing optimization (screenshots, ASO keywords, A/B testing)
- User feedback integration
- Documentation and onboarding improvements

---

## Pricing Evolution

| Version | Free | Pro | Pro+Link | Team | Lifetime |
|---------|------|-----|----------|------|----------|
| V1.0 | All modes, 2 devices | $3.99/mo | $5.99/mo | $199.99/yr | $99.99 |
| V2.0+ | Same | +Intelligence tools | +Intelligence tools | +Web dashboard | Same |
| V3.0+ | Same | Same | +Cloud relay | +Management portal | +Cloud relay |

---

## Contributing

Red Grid Link is developed by Red Grid. Feature requests and bug reports can be submitted via GitHub Issues.

For partnership or integration inquiries: contact via GitHub.
