# Red Grid Link — Product Roadmap

> **Platform:** iOS on the App Store. Android in closed beta (Play Store).

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

## V1.3.2 — Critical Fixes & Revenue Enablers

**Target: April 2026** — PRIORITY: Ship before any new features

Fix the blockers preventing user acquisition and revenue.

### P0 — Onboarding (ship this week)
- [ ] Fix permission request flow: Location and Bluetooth buttons must trigger native OS permission dialogs
- [ ] Add NSPhotoLibraryUsageDescription to Info.plist (Apple rejection fix)
- [ ] Verify permissions work on fresh install (iOS 16+ and Android 13+)

### User Acquisition
- [ ] In-app review prompt: trigger StoreKit/Play review dialog after first successful Field Link session
- [ ] 3-screen quick start tutorial: Create Session → Share Code → See Teammates
- [ ] QR code session join: generate QR containing session ID + PIN, scan to join instantly (zero typing)

### Free Tier Adjustment
- [ ] Free: 1 peer connection (2 devices total), 1 map region, Red Light theme
- [ ] Pro unlocks 2-7 peer connections (3-8 devices total)
- [ ] This creates upgrade pressure for the most common use case (groups of 3+)

### UI Polish
- [ ] Fix tool titles: spell out completely (no truncation)
- [ ] Fix Backcountry mode label truncation in Settings
- [ ] Screenshot carousel on product pages (single image + arrows)

---

## V1.4 — Extended Range + Android Launch

**Target: Q3 2026**

Address the #1 user objection (range) and launch Android publicly.

### BLE Long Range
- [ ] BLE Long Range (Coded PHY S=8): 3-4x range (~400m-1km) via `setPreferredPhy` (Android-only)
- [ ] Adaptive PHY selection: auto-fallback to 1M PHY when Coded PHY unavailable or on iOS
- [ ] PHY indicator on peer markers (1M vs Coded)
- [ ] Connection quality indicator (RSSI-based, color-coded green/yellow/red)
- [ ] Range test mode: RSSI, current PHY, estimated distance between two devices

### Android Launch
- [ ] Android QA on physical devices (Pixel, Samsung, OnePlus minimum)
- [ ] Play Store production release (promote from closed beta)
- [ ] F-Droid submission with reproducible builds

### Map Sources
- [ ] Add vanilla OpenStreetMap tile source
- [ ] Tile source selector in map settings

---

## V1.5 — Meshtastic Bridge

**Target: Q4 2026**

Turn the biggest competitor into a feature. Capture the Meshtastic community.

- [ ] Meshtastic BLE bridge: detect nearby Meshtastic radios via GATT service UUID
- [ ] Route Field Link CRDT traffic through LoRa mesh for multi-kilometer range
- [ ] Meshtastic auto-discovery: offer bridge mode when radio detected
- [ ] Fallback behavior: BLE direct when no radio available, LoRa when available
- [ ] Show bridge status on session info card (BLE-only vs LoRa-bridged)

---

## V2.0 — SAR Mode Pro + Enterprise

**Target: Q1 2027**

Revenue multiplier. Target SAR teams, outfitters, and military training units.

### SAR Mode Pro ($199/yr per team, up to 20 devices)
- [ ] Sector assignment: Lead divides map into named search sectors, assigns members
- [ ] Check-in scheduling: configurable timed check-ins with missed-check-in alerts
- [ ] Hasty search patterns: auto-generate parallel track patterns for a defined area
- [ ] Clue logging: timestamped, geotagged clue entries with photo attachment
- [ ] ICS-compliant form generation: ICS 201, 202, 204 auto-populated from session data

### Outfitter / Guide License ($499/yr)
- [ ] Guide mode: pre-configure sessions for clients before trip starts
- [ ] Client devices covered under guide's license (no individual Pro required)
- [ ] Branded session screen (outfitter name/logo)
- [ ] Post-trip AAR auto-emailed to clients

### Intelligence Tools
- [ ] Elevation profile along planned routes (DEM data)
- [ ] Line-of-sight calculator between two MGRS positions
- [ ] Sunrise/sunset/moonrise with bearing overlays
- [ ] Terrain difficulty scoring for route segments

### ATAK Interop
- [ ] CoT XML message format (send/receive)
- [ ] CoT SA position/callsign/team support
- [ ] CoT bridge: translate CRDT positions to/from CoT events
- [ ] Multicast UDP listener for CoT on shared WiFi/mesh networks

---

## V2.1 — Advanced Navigation

**Target: Q2 2027**

Professional-grade navigation tools.

- [ ] Route planning with MGRS waypoint sequences
- [ ] Freehand annotation drawing mode
- [ ] Interactive team movement replay with timeline scrubber
- [ ] Track recording with breadcrumb trail
- [ ] Navigate-to-waypoint with bearing/distance compass
- [ ] Track statistics: distance, elevation gain/loss, moving time, pace
- [ ] GPX import/export (Garmin, Gaia, etc.)
- [ ] KML/KMZ import for boundary/area overlays
- [ ] Coordinate format flexibility (UTM, USNG, DD, DMS alongside MGRS)

---

## V3.0 — Connected Operations

**Target: Q3 2027**

Optional cloud features for teams that need them (offline-first preserved).

- [ ] Cloud session relay for non-proximate team members (encrypted relay server)
- [ ] Web dashboard for team leads (desktop browser)
- [ ] Session scheduling and pre-planned operations
- [ ] Post-session cloud AAR sharing (encrypted link, expiring)
- [ ] Team management portal (invite members, manage seats)
- [ ] Push notifications for session invites
- [ ] Mesh networking support (relay through intermediate peers)
- [ ] Integration API for third-party tools (webhook on position update)

---

## V3.1 — Sensor Integration

**Target: Q4 2027**

External hardware and sensor support.

- [ ] Garmin inReach integration (satellite messaging + position relay)
- [ ] External GPS receiver support (Bluetooth NMEA devices)
- [ ] Barometric altimeter calibration (phone sensor fusion)
- [ ] Heart rate monitor integration for SAR team health monitoring

---

## V4.0 — Training & Simulation

**Target: Q1 2028**

Structured training and after-action capabilities.

- [ ] Training scenario builder (define objectives, boundaries, events)
- [ ] Real-time scoring for land navigation exercises
- [ ] Simulated peer positions for solo practice
- [ ] Instructor mode (observe all teams, inject events, grade performance)
- [ ] Historical session replay with annotations
- [ ] Performance analytics dashboard (accuracy, timing, route efficiency)

---

## Deferred (revisit based on user demand)

These features were deprioritized to focus on revenue-generating work:

- FixPhrase location encoding (open source what3words alternative)
- Offline gazetteer (search by place name)
- Contour line generation from DEM tiles
- Print-ready topographic map export
- Configurable map datum support
- Offline reverse geocoding
- Multi-waypoint route optimization
- Radio frequency scanning integration
- Drone position overlay (MAVLink)
- AR compass overlay
- Certification tracking for SAR/military courses
- Scenario library sharing

---

## Ongoing

Continuously improved across all versions:

- Security audits and cryptographic library updates
- Battery performance optimization
- Map tile source expansion
- Platform updates (Android API level, iOS SDK)
- Test coverage expansion
- Store listing optimization (screenshots, ASO, reviews)
- User feedback integration

---

## Revenue Model

### Consumer
| Tier | Price | Includes |
|------|-------|----------|
| Free | $0 | All modes, 1 peer (2 devices), 1 map region, Red Light theme |
| Pro Monthly | $3.99/mo | All themes, 7 peers (8 devices), unlimited maps, AAR |
| Pro Annual | $29.99/yr | Same as monthly, 37% savings |
| Lifetime | $99.99 | All Pro features forever |

### Enterprise (contact for pricing)
| Tier | Price | Includes |
|------|-------|----------|
| SAR Team | $199/yr | Up to 20 devices, ICS forms, sector management, check-in scheduling |
| Outfitter/Guide | $499/yr | Pre-configured sessions, client coverage, branded experience |
| Military Training | Custom | Instructor mode, scoring, scenario builder, volume licensing |

---

## Contributing

Red Grid Link is developed by Red Grid Tactical. Feature requests and bug reports can be submitted via GitHub Issues.

For partnership, enterprise, or integration inquiries: [redgridtactical.com](https://redgridtactical.com)
