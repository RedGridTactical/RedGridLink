# Red Grid Link — Product Roadmap

> **Platform:** iOS on the App Store. Android in closed beta (Play Store).
> **Mission:** The fastest way to get a team on a shared map without infrastructure.

## V1.4 — Extended Range (COMPLETE)

**Status: Complete** — App v1.4.0+63

BLE Long Range, signal quality, FixPhrase location encoding, OSM offline tiles.

- [x] BLE Long Range capability detection (Coded PHY)
- [x] Connection quality indicator (RSSI-based, rolling 5-sample average)
- [x] FixPhrase: 4-word location encoding (~11m accuracy, order-independent)
- [x] OpenStreetMap offline tile downloads (source selector)
- [x] Coordinate bar cycles between MGRS and FixPhrase
- [x] Signal bars in peer HUD and team roster
- [x] 1,034 tests, 0 warnings

---

## V1.5 — Security + Communication (COMPLETE)

**Status: Complete** — App v1.5.0+64

Real ECDH key exchange, actual Coded PHY negotiation, emergency beacon, tactical messaging.

- [x] ECDH P-256 key exchange wired into BLE connection handshake (per-peer derived keys)
- [x] Actual BLE Coded PHY negotiation on Android (setPreferredPhy S8 after connection)
- [x] Per-connection PHY tracking (LR badge only when Coded PHY confirmed)
- [x] Emergency beacon: one-tap SOS with GPS, 30s retransmit, full-screen alert on all peers
- [x] Pre-canned tactical messages (7 types + 160-char free text) over CRDT control system
- [x] Message notification banners with sender callsign and auto-dismiss
- [x] 1,088 tests, 0 warnings

---

## V1.6 — Meshtastic Bridge + Android Launch

**Target: May-June 2026** — Range multiplier + Android production

### Meshtastic Bridge
- [ ] Meshtastic BLE bridge via `meshtastic_flutter` pub.dev package
- [ ] Auto-detect Meshtastic nodes by GATT service UUID
- [ ] Translate Field Link positions to/from Meshtastic Position messages
- [ ] Bridge mode UI: "Extend range via LoRa?" prompt when radio detected
- [ ] LoRa-relayed peers shown with mesh icon (distinct from BLE peers)
- [ ] Fallback: BLE direct when no radio, LoRa when available

### Android Launch + Distribution
- [ ] Convert Apple ASC to organization account (Estus Holdings LLC, D-U-N-S pending)
- [ ] Create Google Play organization account
- [ ] Promote Android to production track on Play Store
- [ ] Android QA on physical devices (Pixel, Samsung, OnePlus minimum)
- [ ] F-Droid submission (Firebase-free build flavor, FLOSS-compliant)
- [ ] Firebase Analytics integration
- [ ] BetaList submission + Product Hunt launch
- [ ] Session templates (SAR Hasty Search, Hunting Party, Family Hike, Training Exercise)
- [ ] Show HN post #2: "Red Grid Link now bridges to Meshtastic"

---

## V2.0 — Team Awareness + SAR Mode Pro

**Target: Q3 2026** — Hard differentiation from MGRS (solo → team)

### Team Awareness (free tier)
- [ ] Buddy system pairing: assign buddy pairs, alert if buddies separate beyond configurable distance
- [ ] Check-in timer: Lead sets interval, members tap to confirm, missed check-ins escalate (member → Lead → team)
- [ ] Status board: one-tap status broadcast (Green/Amber/Red/Black) visible on team roster
- [ ] Rally point management: designate rally points, "Rally on Bravo" shows distance/bearing/ETA for all members

### Operational Planning (Pro)
- [ ] Sector assignment: Lead draws named sectors on map, assigns members, crossing alerts
- [ ] Search pattern generator: parallel track, expanding square, sector search with waypoint sequences per member
- [ ] Live tactical drawing: Lead draws routes/arrows/circles on map, syncs to all peers in real-time
- [ ] Photo sharing: snap + broadcast with GPS coordinates, compressed for BLE/LoRa bandwidth

### SAR Mode Pro ($199/yr per team, up to 20 devices)
- [ ] Hasty search patterns: auto-generate parallel track patterns for defined area
- [ ] Clue logging: timestamped, geotagged entries with photo attachment
- [ ] ICS form generation: 201, 202, 204 auto-populated from session data
- [ ] Track recording per member: breadcrumb trails, coverage analysis, gap detection
- [ ] Geofence compliance logging: every boundary entry/exit with timestamp and member ID

### Outfitter / Guide License ($499/yr)
- [ ] Guide mode: pre-configure sessions for clients before trip
- [ ] Client devices covered under guide license (no individual Pro required)
- [ ] Post-trip AAR auto-emailed to clients

### ATAK/CoT Interoperability
- [ ] CoT XML position reports (emit valid Cursor on Target events)
- [ ] CoT bridge: Field Link peers appear on ATAK maps as SA markers
- [ ] ATAK users appear on Red Grid Link maps
- [ ] Transport via Meshtastic LoRa or shared WiFi (multicast UDP)

---

## V2.1 — Command & Control

**Target: Q4 2026** — Full C2 capability

### Task Management
- [ ] Task assignment: Lead assigns tasks to specific members with waypoint + instructions
- [ ] Task completion tracking: member marks done, Lead sees status on roster
- [ ] Route planning with MGRS waypoint sequences per member

### Communication
- [ ] Voice clips: 5-second compressed voice notes with GPS stamp, sent over BLE/LoRa
- [ ] Freehand annotation drawing mode (complements tap-to-place)
- [ ] Interactive team movement replay with timeline scrubber

### Accountability
- [ ] Time-on-task tracking: active time, distance covered, average speed per member
- [ ] Cascading alerts: missed check-in escalates (Lead → buddy → team → external contact)
- [ ] GPX/KML import/export for pre-planned routes and sector boundaries

### Intelligence Tools
- [ ] Elevation profile along planned routes (DEM data)
- [ ] Line-of-sight calculator between two MGRS positions
- [ ] Terrain difficulty scoring for route segments

---

## V3.0 — Connected Operations

**Target: Q1 2027** — Multi-team + cloud capabilities

### Cloud Relay
- [ ] Cloud session relay (encrypted WebSocket via Cloudflare Workers)
- [ ] Web dashboard for team leads and incident commanders (browser-based, read-only)
- [ ] External observer mode: read-only view for ICs or family liaisons

### Multi-Team Coordination
- [ ] Multi-team bridging: two or more Link sessions with shared Lead overlay
- [ ] Shift handoff: transfer session to incoming Lead with summary of positions/assignments/tasks
- [ ] Multi-hop BLE mesh (relay through intermediate peers)

### Enterprise
- [ ] Team management portal (invite members, manage seats, billing)
- [ ] Integration API (webhook on position update, task completion)
- [ ] Garmin inReach integration (satellite messaging + position relay)

---

## V3.1 — Sensor Integration

**Target: Q2 2027**

- [ ] External GPS receiver support (Bluetooth NMEA devices)
- [ ] Barometric altimeter calibration (phone sensor fusion)
- [ ] Heart rate monitor integration for SAR team health monitoring
- [ ] Environmental sensors (temperature, pressure for weather tracking)

---

## V4.0 — Training & Simulation

**Target: Q3 2027**

- [ ] Training scenario builder (define objectives, boundaries, events)
- [ ] Real-time scoring for land navigation exercises
- [ ] Instructor mode (observe all teams, inject events, grade performance)
- [ ] Performance analytics dashboard (accuracy, timing, route efficiency)
- [ ] Simulated peer positions for solo practice

---

## Revenue Model

### Consumer
| Tier | Price | Includes |
|------|-------|----------|
| Free | $0 | All modes, 2 devices, 1 map region, Red Light theme |
| Pro Monthly | $3.99/mo | All themes, 8 devices, unlimited maps, AAR, messaging |
| Pro Annual | $29.99/yr | Same as monthly, 37% savings |
| Lifetime | $149.99 | All Pro features forever |

### Enterprise (contact for pricing)
| Tier | Price | Includes |
|------|-------|----------|
| SAR Team | $199/yr | Up to 20 devices, ICS forms, sectors, check-ins |
| Outfitter/Guide | $499/yr | Pre-configured sessions, client coverage |
| Military Training | Custom | Instructor mode, scoring, scenarios |

---

## User Acquisition Strategy

### Organic (primary)
1. SAR team direct outreach (50 teams, offer 6-month free Pro)
2. Show HN posts (after each major feature: Meshtastic, CoT)
3. Subreddit engagement (r/SearchAndRescue, r/Meshtastic, r/hiking, r/hunting)
4. Technical articles (Dev.to, Hashnode)
5. Product Hunt launch

### Paid (only after 10+ reviews)
- Apple Search Ads: "walkie talkie", "offline map" only
- $3/day budget, measure CPI before scaling

### Retention
- Session templates reduce return friction
- Post-session debrief drives reviews
- Meshtastic hardware creates investment lock-in
- Team management creates organizational lock-in

---

## Competitive Position

| Competitor | Their Strength | Our Advantage |
|---|---|---|
| ATAK | Feature depth, military standard | Zero setup, cross-platform, no server |
| Meshtastic | Multi-km LoRa range | No hardware required (bridge for upgrade) |
| MeshCore SAR | Messaging + voice + tracking | Phone-only, no hardware purchase |
| goTenna Pro X | Professional mesh comms | $0 vs $849/device |
| Garmin inReach | Satellite coverage | Team tracking vs point-to-point |
| Paper maps + radios | No battery dependency | Real-time SA, GPS precision |

---

## Contributing

Red Grid Link is developed by Red Grid Tactical. Feature requests and bug reports welcome via GitHub Issues.

For partnership, enterprise, or integration inquiries: [redgridtactical.com](https://redgridtactical.com)
