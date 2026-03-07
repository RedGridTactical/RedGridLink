<!-- screenshot banner -->

# Red Grid Link

[![Download on App Store](https://img.shields.io/badge/App%20Store-Coming%20Soon-8B0000?logo=apple)](https://github.com/RedGridTactical/RedGridLink/releases/latest)
[![Get it on Google Play](https://img.shields.io/badge/Google%20Play-Coming%20Soon-CC0000?logo=googleplay)](https://github.com/RedGridTactical/RedGridLink/releases/latest)
[![License](https://img.shields.io/badge/License-MIT%20%2B%20Commons%20Clause-8B0000)](LICENSE)
[![No Tracking](https://img.shields.io/badge/Tracking-None-CC0000)](PRIVACY.md)
[![Offline First](https://img.shields.io/badge/Offline-First-8B0000)]()
[![MGRS Native](https://img.shields.io/badge/MGRS-Native-CC0000)]()
[![AES-256](https://img.shields.io/badge/Encryption-AES--256--GCM-8B0000)]()
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-CC0000?logo=flutter)]()
[![Tests](https://img.shields.io/badge/Tests-783%20Passing-brightgreen)]()
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-8B0000)]()
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-CC0000)](https://github.com/RedGridTactical/RedGridLink/pulls)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/redgridtac0)

**Offline MGRS navigation and proximity team coordination for small teams (2-8 people). No cell service needed.**

Built on the MGRS engine from [Red Grid Tactical](https://github.com/RedGridTactical/RedGridMGRS). Field Link adds zero-config proximity sync over Bluetooth and WiFi Direct -- your team appears on the map the moment they're in range.

---

## Screenshots

| Map & Team | Field Link | Ghost Markers | AAR Export |
|:---:|:---:|:---:|:---:|
| <!-- screenshot: map view with peer markers --> | <!-- screenshot: field link session --> | <!-- screenshot: ghost marker decay --> | <!-- screenshot: AAR PDF export --> |

| Tactical Themes | Grid View | Tools | Onboarding |
|:---:|:---:|:---:|:---:|
| <!-- screenshot: theme comparison --> | <!-- screenshot: solo MGRS grid --> | <!-- screenshot: tactical tools --> | <!-- screenshot: onboarding flow --> |

---

## Features

### MGRS-Native Navigation
Live Military Grid Reference System coordinates with 1-meter precision. MGRS grid overlay on offline maps from GZD down to 100m resolution. Bearing, distance, dead reckoning, resection, pace count, declination, and coordinate conversion tools. NATO phonetic voice readout for hands-free grid calls.

### Field Link -- Team Sync Without Infrastructure
Zero-config proximity sync over BLE + WiFi Direct (Android) / AWDL (iOS). Devices within range automatically discover each other and share encrypted position and marker data. No internet required. No pairing codes. No servers.

- 2-8 devices per session
- AES-256-GCM encryption with ECDH P-256 ephemeral session keys
- Tiered session security: Open, PIN, or QR code authentication
- Delta payloads under 200 bytes per position update
- Ghost markers with time-decay visualization when teammates disconnect
- Velocity vectors project last-known movement direction
- Expedition Mode: <3% battery/hr (BLE-only, 30s updates)
- Ultra Expedition Mode: <2% battery/hr (BLE-only, 60s updates)
- Auto-reconnect with exponential backoff on disconnect

### Offline Maps
Download map packs from USGS Topo (public domain) and OpenTopoMap for full offline operation. Maps are cached locally as MBTiles with MGRS grid lines rendered as a dynamic overlay.

### 4 Operational Modes
One engine, four presentation layers. Terminology, icons, and quick actions adapt to your mission:
- **Search & Rescue** -- sector assignments, clue markers, search patterns
- **Backcountry** -- camp, waypoint, and trail navigation
- **Hunting** -- stand locations, game sightings, property boundaries
- **Training** -- exercise objectives, rally points, phase lines

### 11 Tactical Tools
Dead Reckoning, Resection, Pace Count, Bearing/Back Azimuth, Coordinate Converter (MGRS/Lat-Lon/DMS/UTM), Range Estimation, Slope Calculator, ETA/Speed Calculator, Magnetic Declination, Celestial Navigation, MGRS Precision Reference.

### After-Action Reports
One-tap PDF export: map snapshot, mission timeline, track data, timestamps, team roster, markers, and session log. Share via AirDrop, file share, or any local transfer.

### 4 Tactical Themes
Red Light (night vision, free), NVG Green (Pro), Day White (Pro), Blue Force (Pro).

---

## How It Works

### Solo Mode
Open Red Grid Link and your MGRS position appears on the offline map. Navigate using bearing, distance, and dead reckoning tools -- identical to Red Grid Tactical but with a full map view and 11 tactical tools.

### Field Link (Team Mode)
1. **Start a session** -- tap one button to begin broadcasting over BLE
2. **Set security** -- choose Open, PIN, or QR code authentication
3. **Teammates appear** -- any device running Red Grid Link within range (~50-100m open, 20-60m woods) is automatically discovered
4. **Positions sync** -- AES-256-GCM encrypted delta updates flow between all devices at configurable intervals
5. **Ghosting** -- if a teammate moves out of range, their last-known position remains on your map with time-decay opacity (100% to outline over 30 minutes)
6. **Reconnect** -- when a ghost comes back in range, their marker snaps to live position

No accounts. No servers. No cell service. No configuration. It just works.

---

## Free vs Pro

| Feature | Free | Pro | Pro+Link | Team |
|---------|:----:|:---:|:--------:|:----:|
| MGRS Navigation | Yes | Yes | Yes | Yes |
| All Operational Modes | Yes | Yes | Yes | Yes |
| 11 Tactical Tools | Yes | Yes | Yes | Yes |
| Field Link (2 devices) | Yes | Yes | Yes | Yes |
| All Themes | -- | Yes | Yes | Yes |
| Unlimited Map Downloads | -- | Yes | Yes | Yes |
| AAR Export | -- | Yes | Yes | Yes |
| Full Field Link (8 devices) | -- | -- | Yes | Yes |
| Team Management | -- | -- | -- | Yes |

**Pricing:**
- **Free** -- All modes, 2-device Field Link, 1 map region, Red Light theme
- **Pro** -- $3.99/mo or $29.99/yr
- **Pro+Link** -- $5.99/mo or $44.99/yr (Pro + full 8-device Field Link)
- **Team** -- $199.99/yr (8 seats, includes Pro+Link for all members)
- **Lifetime** -- $99.99 one-time (Pro+Link forever)

---

## Privacy

| Data | Collected | Stored | Transmitted |
|------|:---------:|:------:|:-----------:|
| GPS location | In use only | Local session DB | Field Link peers only (encrypted) |
| Field Link positions | Active session | Ephemeral | AES-256-GCM encrypted, device-to-device |
| Map tiles | Downloaded | Local MBTiles | Standard HTTPS to tile servers |
| Waypoints & markers | User-created | Local only | Field Link peers only (encrypted) |
| After-Action Reports | User-generated | Local only | Never |
| Device identifiers | Never | Never | Never |

No accounts. No analytics. No ad networks. No third-party data SDKs. Privacy-safe crash reporting (Sentry, release mode only — no location data transmitted).
In-app purchases processed by Apple/Google -- Red Grid Link never sees your payment details.
Full details in [PRIVACY.md](PRIVACY.md).

---

## Build from Source

```bash
git clone https://github.com/RedGridTactical/RedGridLink.git
cd RedGridLink
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

Requires Flutter SDK. All free features work from source. Pro features require a valid purchase through Apple or Google. Field Link requires Bluetooth and location permissions on physical devices.

---

## Roadmap

Full roadmap with feature checklists: [ROADMAP.md](ROADMAP.md)

| Version | Target | Theme | Highlights |
|---------|--------|-------|------------|
| **V1.0** | **Complete** | Foundation | MGRS nav, Field Link (BLE+WiFi Direct), 11 tools, AAR PDF, offline maps, 4 themes, IAP |
| **V1.1** | **Complete** | Field Hardening | Kalman filter, Peer HUD, Ultra Expedition, auto-reconnect, Sentry, l10n, Help/About |
| **V1.2** | Q3 2026 | Team Features | Team roles, waypoint sharing, route planning, boundary alerts, shared annotations |
| **V2.0** | Q4 2026 | Intelligence | Elevation profiles, line-of-sight, weather overlay, terrain analysis, contour lines |
| **V2.1** | Q1 2027 | Advanced Nav | Track recording, GPX import/export, navigate-to-waypoint, coordinate formats |
| **V3.0** | Q2 2027 | Connected Ops | Cloud relay, web dashboard, mesh networking, session scheduling, API |
| **V3.1** | Q3 2027 | Sensors | Garmin inReach, ATAK interop, external GPS, drone overlay |
| **V4.0** | Q4 2027 | Training | Scenario builder, instructor mode, scoring, AR compass, certification tracking |

### Ongoing

- Security audits and cryptographic library updates
- Battery performance optimization
- Map tile source expansion
- Test coverage expansion (target 90%+)
- Store listing optimization and A/B testing

---

## Contributing

Red Grid Link is built in the open. We welcome bug reports, feature requests, and pull requests.

- **Report a bug:** [Open an issue](https://github.com/RedGridTactical/RedGridLink/issues/new)
- **Request a feature:** [Start a discussion](https://github.com/RedGridTactical/RedGridLink/discussions)
- **Submit a PR:** Fork, branch, and open a pull request

See the [Roadmap](ROADMAP.md) for planned features and where help is needed.

---

## Related Projects

- [Red Grid Tactical](https://github.com/RedGridTactical/RedGridMGRS) -- solo MGRS navigator (React Native / Expo)

---

## License

[MIT + Commons Clause](LICENSE) -- free for personal non-commercial use. Commercial and organizational deployment requires written permission.

Contact: redgridtactical@gmail.com

---

*Your team. Your grid. No cell towers required.*

If Red Grid Link helps you stay coordinated in the field, give it a star and share it with your team.
