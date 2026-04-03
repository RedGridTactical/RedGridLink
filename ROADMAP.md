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

## V1.5 — Security + Communication

**Target: April 2026** — PRIORITY: Fix security claims, add communication

### P0 — Security (Week 1)
- [ ] Wire ECDH P-256 key exchange into BLE connection handshake (code exists in key_exchange.dart, never called)
- [ ] Per-peer session key derivation (replace single pre-shared key)
- [ ] Wire actual BLE Coded PHY negotiation on Android (setPreferredPhy, not just isSupported)
- [ ] Track actual negotiated PHY per connection (LR badge only when Coded PHY confirmed)
- [ ] Audit all documentation claims against codebase reality

### P1 — Emergency + Messaging (Weeks 2-3)
- [ ] Emergency beacon: one-tap SOS with GPS, retransmits every 30s until cancelled
- [ ] Lead receives full-screen distress alert with sender position/distance/bearing
- [ ] Pre-canned tactical messages (8 messages + 160-char free text)
- [ ] Message display as notification banner with sender callsign
- [ ] Route messages through existing CRDT sync (SyncPayloadType.message)

### P2 — Measurement (Week 3)
- [ ] Firebase Analytics (session events, peer connections, mode usage, tool usage)
- [ ] Consent mode for EU users (disable collection until consent)
- [ ] F-Droid build flavor preparation (Firebase-free variant)
- [ ] Post-session debrief screen (duration, distance, tracks, review prompt)

---

## V1.6 — Meshtastic Bridge

**Target: May 2026** — Range multiplier + community capture

- [ ] Meshtastic BLE bridge via `meshtastic_flutter` pub.dev package
- [ ] Auto-detect Meshtastic nodes by GATT service UUID
- [ ] Translate Field Link positions to/from Meshtastic Position messages
- [ ] Bridge mode UI: "Extend range via LoRa?" prompt when radio detected
- [ ] LoRa-relayed peers shown with mesh icon (distinct from BLE peers)
- [ ] Fallback: BLE direct when no radio, LoRa when available
- [ ] Show HN post #2: "Red Grid Link now bridges to Meshtastic"

---

## V1.7 — Distribution + Production

**Target: June 2026** — Requires LLC business accounts (D-U-N-S pending)

### Store Accounts
- [ ] Convert Apple ASC to organization account (Estus Holdings LLC)
- [ ] Create Google Play organization account
- [ ] Promote iOS to production (bypasses TestFlight external review)
- [ ] Promote Android to production track

### Distribution
- [ ] F-Droid submission (Firebase-free build flavor, FLOSS-compliant)
- [ ] Android QA on physical devices (Pixel, Samsung, OnePlus minimum)
- [ ] BetaList submission for tester recruitment
- [ ] Product Hunt launch

### Retention
- [ ] Session templates (SAR Hasty Search, Hunting Party, Family Hike, Training Exercise)
- [ ] Session history with stats (creates "training log" effect)

---

## V2.0 — SAR Mode Pro + ATAK Interop

**Target: Q3 2026** — Revenue multiplier

### SAR Mode Pro ($199/yr per team, up to 20 devices)
- [ ] Sector assignment: Lead divides map into named search sectors
- [ ] Check-in scheduling: configurable timed check-ins with missed-check-in alerts
- [ ] Hasty search patterns: auto-generate parallel track patterns
- [ ] Clue logging: timestamped, geotagged entries with photo
- [ ] ICS form generation: 201, 202, 204 auto-populated from session data

### Outfitter / Guide License ($499/yr)
- [ ] Guide mode: pre-configure sessions for clients
- [ ] Client devices covered under guide license
- [ ] Post-trip AAR auto-emailed to clients

### ATAK/CoT Interoperability
- [ ] CoT XML position reports (emit valid Cursor on Target events)
- [ ] CoT bridge: Field Link peers appear on ATAK maps as SA markers
- [ ] ATAK users appear on Red Grid Link maps
- [ ] Transport via Meshtastic LoRa or shared WiFi (multicast UDP)

### Intelligence Tools
- [ ] Elevation profile along planned routes (DEM data)
- [ ] Line-of-sight calculator between two MGRS positions
- [ ] Terrain difficulty scoring for route segments

---

## V2.1 — Advanced Navigation

**Target: Q4 2026**

- [ ] Route planning with MGRS waypoint sequences
- [ ] Track recording with breadcrumb trail and statistics
- [ ] GPX/KML import/export
- [ ] Navigate-to-waypoint with bearing/distance compass
- [ ] Freehand annotation drawing mode
- [ ] Interactive team movement replay with timeline scrubber

---

## V3.0 — Connected Operations

**Target: Q1 2027**

- [ ] Cloud session relay (encrypted WebSocket via Cloudflare Workers)
- [ ] Web dashboard for team leads (browser-based, read-only)
- [ ] Multi-hop BLE mesh (relay through intermediate peers)
- [ ] Team management portal (invite, manage seats)
- [ ] Integration API (webhook on position update)

---

## V3.1 — Sensor Integration

**Target: Q2 2027**

- [ ] Garmin inReach integration (satellite messaging + position relay)
- [ ] External GPS receiver support (Bluetooth NMEA devices)
- [ ] Barometric altimeter calibration
- [ ] Heart rate monitor integration for SAR team health

---

## V4.0 — Training & Simulation

**Target: Q3 2027**

- [ ] Training scenario builder
- [ ] Real-time scoring for land navigation exercises
- [ ] Instructor mode (observe all teams, inject events)
- [ ] Performance analytics dashboard

---

## Revenue Model

### Consumer
| Tier | Price | Includes |
|------|-------|----------|
| Free | $0 | All modes, 2 devices, 1 map region, Red Light theme |
| Pro Monthly | $3.99/mo | All themes, 8 devices, unlimited maps, AAR, messaging |
| Pro Annual | $29.99/yr | Same as monthly, 37% savings |
| Lifetime | $99.99 | All Pro features forever |

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
