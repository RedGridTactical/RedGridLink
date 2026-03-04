# Red Grid Link — Product Roadmap

## V1.0 — Foundation Release (Current)

**Status: Complete**

Core offline MGRS navigation and proximity coordination platform.

- MGRS-native navigation with 10-digit grid precision
- 4 operational modes: SAR, Backcountry, Hunting, Training
- Field Link: BLE + WiFi Direct proximity sync (2-8 devices)
- CRDT-based sync engine with delta encoding (<200 bytes/update)
- AES-256-GCM encrypted communications with ECDH key exchange
- Tiered session security: Open, PIN, QR code
- Ghost markers with opacity decay for disconnected peers
- 8 tactical tools (dead reckoning, resection, pace count, bearing, coordinate converter, range estimation, slope calculator, ETA/speed)
- MBTiles offline map downloads (USGS Topo + OpenTopo)
- After-Action Report (AAR) PDF generation and export
- 4 tactical themes: Red Light, NVG Green, Day White, Blue Force
- In-app subscriptions: Free / Pro / Pro+Link / Team / Lifetime
- Android foreground service for background sync
- 646 tests, 0 warnings

---

## V1.1 — Field Hardening

**Target: Q2 2026**

Real-world testing feedback and reliability improvements.

- [ ] Field Link connection stability improvements (reconnect logic, retry backoff)
- [ ] Battery optimization for extended BLE sessions (target <3%/hr in Expedition Mode)
- [ ] GPS accuracy filtering (Kalman filter for position smoothing)
- [ ] Offline map cache management (storage quota, auto-cleanup)
- [ ] Haptic feedback patterns for proximity alerts and sync events
- [ ] Peer distance/bearing HUD overlay on map view
- [ ] Session history persistence (resume interrupted sessions)
- [ ] Crash reporting integration (Sentry or equivalent, privacy-respecting)
- [ ] Accessibility audit (screen reader support, high contrast mode)
- [ ] Localization framework (English, Spanish initial)

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
