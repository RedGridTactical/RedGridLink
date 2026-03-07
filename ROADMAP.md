# Red Grid Link — Product Roadmap

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

## V1.1 — Field Hardening (Current)

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

## V1.2 — Team Features

**Target: Q3 2026**

Enhanced team coordination for larger groups.

- [ ] Team roles: Lead, Scout, Medic, Comms (custom callsign + icon)
- [ ] Waypoint sharing via Field Link (create, share, sync waypoints across team)
- [ ] Route planning with MGRS waypoint sequences
- [ ] Team boundary alerts (geofence notifications when peers exit area)
- [ ] Shared annotations layer (draw on map, visible to all peers)
- [ ] Voice callout queue (NATO phonetic auto-announce on position updates)
- [ ] Enhanced AAR: team movement replay with timeline scrubber
- [ ] Custom map marker categories (hazard, rally point, objective, cache)
- [ ] Export/import session data (JSON backup/restore)

---

## V2.0 — Intelligence Layer

**Target: Q4 2026**

Terrain analysis and environmental awareness.

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
- [ ] ATAK interoperability layer (CoT message format support)
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

Red Grid Link is developed by Red Grid Tactical. Feature requests and bug reports can be submitted via GitHub Issues.

For partnership or integration inquiries: contact via GitHub.
