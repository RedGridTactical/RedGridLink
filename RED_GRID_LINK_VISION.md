# REDGRID TAC — Vision Document

**March 2026**

---

## 1. Core Product Definition

Red Grid Link is an offline-first, MGRS-native proximity coordination platform designed exclusively for small civilian teams (2–8 people) operating beyond reliable cell service.

It delivers a shared tactical map that "just works" when radios are silent and the grid is all you have.

It is a proximity-based field coordination tool for teams staying within a compact operational envelope (~150–300 m total diameter).

**It is not** a radio replacement, a wide-area mesh network, a long-range C2 system, or an enterprise command platform.

**Core promise:** ATAK-level team awareness with Tactical NAV simplicity — zero accounts, zero servers, zero complexity.

---

## 2. Strategic Positioning

Red Grid Link owns the exact gap between:

- **ATAK / CivTAK** — powerful but complex, server-heavy, plugin-dependent
- **Tactical NAV** — excellent solo MGRS tool with zero team capability
- **Consumer apps** (onX Hunt, HuntStand, Gaia) — cloud-first, no native MGRS, no offline team sync

**Target niche:** Small, field-oriented civilian teams who need real coordination but reject military bloat and hardware requirements.

---

## 3. Target Markets

Primary verticals (all share the same 2–8 person, offline, battery-conscious profile):

- Volunteer SAR teams
- Backcountry instructors & preparedness groups
- Hunting parties
- Airsoft / MilSim squads
- Rural property / ranch teams

**Market size:** 150k–300k reachable, high-intent users in the US alone.

**Revenue forecast:** Durable $3k–$12k MRR steady-state (freemium + team licensing).

---

## 4. Core Pillars (Engineered Constraints)

Every feature decision must pass these filters.

### Pillar 1: Offline First, Always

No accounts. No required backend. Full functionality in airplane mode. Maps are 100% cached. Cloud is only for optional map-pack downloads and updates — never for operation.

### Pillar 2: MGRS Native (Not an Overlay)

MGRS is the default coordinate system. The grid is always visible (toggleable). One-tap copy, bearing-to-grid guidance, and dead-reckoning tools are core. This is the inherited DNA from Red Grid MGRS.

### Pillar 3: Field Link (Proximity Sync)

**The defining differentiator.**

Red Grid Link provides zero-config local device discovery via Bluetooth + WiFi Direct / AWDL.

**Features:**

- Automatic encrypted session formation
- Delta-based position & marker sync
- Graceful disconnect / reconnect with last-known-position ghosting

**Operational envelope** (clearly communicated):

- Optimal: 2–6 devices
- Maximum supported: 8 devices
- Reliable radius: 50–100 m open terrain | 20–60 m dense woods

**Disclaimer** (displayed on first launch, store description, and settings):

> "Designed for teams staying within ~150–300 m total diameter. Works best in line-of-sight or light woods."

### Pillar 4: Battery-First Engineering

Hard targets:

- <4% battery per 8-hour session in Expedition Mode (BLE-only, 30-second updates)
- User-adjustable update interval
- Screen-off background listening
- Real-time battery projection estimate

Battery efficiency is a competitive weapon versus ATAK.

### Pillar 5: Operational Clarity via Adaptive Modes

One engine. Four presentation layers (SAR, Backcountry, Hunting, Training).

Modes dynamically adjust:

- Terminology ("rally" vs "camp")
- Marker icons and quick-action buttons
- Default overlays
- After-Action Report formatting

### Pillar 6: Professional Output

One-tap After-Action Report (PDF) containing map, tracks, timestamps, team list, markers, and photos. Exportable via AirDrop, WiFi Direct, or file share — no plugins, no servers.

---

## 5. Field Link (Proximity Sync) — Deep Technical Analysis & Implementation Structure

*March 2026 Research*

This section is grounded in live 2026 data from Google Nearby Connections API documentation, Apple Multipeer Connectivity framework, pub.dev package metrics, Ditto SDK release notes, real-world field reports (SAR forums, hunting apps, Reddit r/tacticalgear), and Flutter ecosystem benchmarks.

### Current Landscape (March 2026)

- **flutter_nearby_connections** (Android Nearby + iOS Multipeer wrapper): Last stable release 2023 (v1.1.2). Still functional for basic discovery but plagued by Android 12+ permission issues, Google Play Services breakage, and no native multi-hop. Not recommended for production in 2026.
- **Ditto SDK** (flutter package `ditto_live` v4.14+): The clear production winner. Full cross-platform offline-first mesh (BLE + WiFi Aware/AWDL + LAN switching), automatic multi-hop relay, CRDT-based delta sync, and excellent battery management. Released major Flutter improvements in 2025–2026 (Web/Mac/Windows support, Linux preview). Used in multiple offline team apps. Free tier for <10 devices; paid for scale.
- **Other options** (`flutter_p2p_connection`, `wifi_direct_plugin`): Viable for Android-only prototypes but lack mature iOS support and multi-hop.
- **Android Nearby Connections API** (v19+): Excellent high-bandwidth P2P (up to 50–100 m LOS), but discovery latency can hit 5–15 s and WiFi mode spikes battery. Supports star + limited mesh.
- **iOS Multipeer Connectivity**: Star topology by default (weaker multi-hop). Flaky on iOS 26 in some reports, but reliable for 2–8 devices within 30–80 m. Background mode requires strict Apple review.
- **Real-world performance** (2025–2026 field tests): Open terrain 50–100 m/hop; dense woods 20–60 m. 3–4 hops max before latency >2 s or battery impact. BLE-dominant mode achieves <4% drain/8 hrs with 30 s pings.

### Capabilities & Limitations (Hard Data)

- **Discovery:** Zero-config, 2–5 s (BLE advertising + WiFi beacons).
- **Sync:** Delta JSON (positions/markers <200 bytes/update). Photos/routes possible via WiFi Direct/AWDL (10–50 MB/min).
- **Multi-hop:** Supported in Ditto (relay nodes). Limited in raw Nearby/Multipeer.
- **Battery:** BLE mode = <4%/8 hrs. WiFi mode = 8–15%/hr. Screen-off background works on both platforms.
- **Cross-platform:** Full Android ↔ iOS via Ditto or hybrid wrapper.
- **Limits:** Max 8 devices (our hard cap). No video/voice. iOS background stops if app fully killed (use background modes carefully).

### Implementation Decision (March 2026)

**Custom BLE + Platform P2P** — zero licensing costs, full control, no vendor lock-in.

- **BLE Transport:** `flutter_blue_plus` for GATT-based communication (both platforms)
- **Android P2P:** Platform channel → Android Nearby Connections API (WiFi Direct)
- **iOS P2P:** Platform channel → Multipeer Connectivity framework (AWDL)
- **Sync Engine:** Custom CRDT (Last-Writer-Wins Register + G-Counter) with delta JSON encoding
- **Fallback:** Pure BLE for ultra-low-power "Expedition Mode"
- **No Ditto SDK** — Ditto's pricing ($999+/mo for Pro) is not viable for indie development. The custom approach is tractable because our data model is simple (<200 bytes per position update).

### High-Level Architecture

- **Layer 1 (Discovery):** BLE advertising with custom service UUID + platform-specific scanning.
- **Layer 2 (Transport Manager):** Auto-switch BLE (low power, discovery) ↔ WiFi Direct/Multipeer (high bandwidth, bulk sync).
- **Layer 3 (Sync Engine):** Custom CRDT-based delta replication. LWW Register for positions, G-Counter for sequence numbers. Local SQLite (Drift) cache for offline ghosting.
- **Layer 4 (UI Integration):** Riverpod providers → reactive streams to map markers/positions. Adaptive Modes filter what is broadcast.
- **Security:** AES-256 transport encryption (pointycastle) + ECDH ephemeral session key exchange (rotated every reconnect). Tiered authentication: Open (auto-join), PIN (4-digit, default), QR (encoded session key).

### Data Flow

1. App launches → starts advertising + discovering.
2. Devices auto-connect → form ephemeral session.
3. Position update → compress delta → broadcast to connected peers.
4. Peer receives → merge into local SQLite → update map in real-time.
5. Disconnect → cache last-known position as "ghost" marker.

### Battery Optimization Tactics

- User-selectable interval (5 s / 15 s / 30 s / 60 s).
- BLE-only Expedition Mode.
- Screen-off + Doze-aware background listener.
- Projection estimator: "8 hrs 12 min remaining at current rate".

### Testing & Validation Plan

- **Lab:** 8 physical devices (mixed Android/iOS).
- **Field:** Woods tests measuring range, packet loss, battery % at 30/60/120 min intervals.
- **Edge cases:** 4 hops, dense canopy, device sleep, rapid reconnects.
- **Metrics:** Sync latency <2 s, battery <4%/8 hrs, 99% packet delivery within envelope.

**Field Link is now 100% grounded in 2026 realities — reliable, defensible, and the strongest moat in the product.**

### Ghost Sync Design (Added March 2026)

When a peer disconnects, their last-known position is cached as a "ghost" marker with progressive visual decay:

| Time Since Disconnect | Opacity | Visual Indicator |
|----------------------|---------|------------------|
| 0–5 min | 100% | Full marker |
| 5–15 min | 50% | Red timestamp badge ("5m ago") |
| 15–30 min | 25% | Dim marker |
| 30+ min | Outline only | Ghost outline |

- **Velocity vector:** If the peer was moving (speed > 0.5 m/s) at disconnect, show a heading arrow indicating last-known direction of travel.
- **Manual clear:** Long-press ghost marker → "Remove" option.
- **Reconnect:** Ghost snaps to live position with smooth animation.

### Security Model (Added March 2026)

Tiered session authentication, defaulting to PIN:

- **Open:** Zero-friction auto-join. For casual use (airsoft, casual hunting).
- **PIN (Default):** Session leader sets a 4-digit PIN. Members enter PIN to join.
- **QR Code:** Session leader displays QR code. Members scan to join. Highest security.

All modes use AES-256 transport encryption + ECDH ephemeral session key exchange regardless of authentication tier.

### Map Strategy (Added March 2026)

- **Library:** `flutter_map` (BSD license, no vendor lock-in)
- **Offline tiles:** `flutter_map_mbtiles` (MIT) — pre-rendered MBTiles region packs
- **Tile sources:** USGS Topo (public domain), OpenTopoMap (CC-BY-SA)
- **Download cap:** Zoom level 16 for region packs (under ~500MB per county-sized area). Zoom 17-18 cached on-demand when connectivity available.
- **MGRS overlay:** Custom Dart implementation via PolylineLayer, density adapts to zoom level (GZD → 100km squares → 1km lines → 100m lines).
- **Self-hosted tiles:** PMTiles on S3/CloudFront (~$1-10/month at scale).

### Offline Annotation (Added March 2026)

Synced via Field Link like any other marker:

- **Polyline drawing:** Trace routes, boundaries, search patterns
- **Polygon areas:** Mark searched grid squares, danger zones, rally areas
- **Color coding:** Mode-specific defaults (red for danger, green for cleared)
- **AAR inclusion:** All annotations exported in After-Action Report

---

## 6. What Red Grid Link Will Never Be

- No plugin marketplace
- No support for 50+ users
- No server-required features
- No live video or voice comms
- No LoRa hardware dependency (future optional bridge only)

**Scope protection is non-negotiable.**

---

## 7. Monetization Architecture (Revised March 2026)

Based on competitor analysis (onX Hunt $34.99-$99.99/yr, Gaia GPS $39.99/yr, HuntStand $29.99-$99.99/yr), pricing has been restructured to align with market expectations while maintaining accessibility.

- **Free Tier:** Solo MGRS navigation + basic 2-device Field Link + 1 map region
- **Pro Tier ($29.99/year or $4.99/mo):** Full Field Link (up to 8 devices), all modes, full AAR export, all map regions, all themes
- **Team License ($149.99/year, 8 seats):** Pro for whole team + branded AARs + priority support

Revenue projection at steady-state:
- 10,000 free users × 3% conversion = 300 Pro × $29.99 = ~$9K/year
- 20 SAR team licenses × $149.99 = ~$3K/year
- Target: $12K+ ARR

---

## 8. UX Philosophy

- Maximum 3 taps to any primary action
- Large, glove-friendly buttons
- Dark-mode optimized for field use
- Minimal visual clutter — military clarity without military complexity

---

## 9. Execution Priority Order

1. Field Link reliability & battery performance
2. Clean, adaptive UI
3. One-tap AAR automation
4. Mode system polish
5. Environmental overlays & training tools
