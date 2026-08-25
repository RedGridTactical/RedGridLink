# Red Grid Link - Store Listing Copy

## App Name
Red Grid Link

## Subtitle (iOS, max 30 chars)
Offline Team GPS & Map Tracker

## App Icon
Source: `docs/images/icon_1024.png` (1024x1024)
All iOS and Android sizes auto-generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` and `android/app/src/main/res/mipmap-*/`.

## Category
Navigation (primary), Utilities (secondary)

## Short Description (Play Store, max 80 chars)
Coordinate nearby teams over Bluetooth. Encrypted GPS sharing, no cell needed.

## Full Description

Coordinate nearby teams off-grid -- no cell service, no internet, no accounts.

Red Grid Link turns nearby phones into a private team awareness network using Bluetooth, with Apple Multipeer Connectivity on iOS and Google Play Services Nearby Connections on Android as higher-bandwidth peer transports when available. See everyone's position on a shared map, drop waypoints, set boundaries, and coordinate -- all without cell towers or internet during active sessions. Your operational data stays on your devices unless you share it with peers or export it.

Built by an active duty Army officer for the people who actually need it: search & rescue volunteers, hunting parties, backcountry hiking groups, and field training teams.

WHO IT'S FOR:
- Search & Rescue teams tracking searchers across sectors
- Hunting groups monitoring stand positions and property lines
- Backcountry hikers keeping tabs on a spread-out group
- Training teams running field exercises without military infrastructure

HOW IT WORKS:
Open the app, start a session, and every teammate within Bluetooth range appears on your map. No pairing, no configuration, no internet required.

- Devices discover each other automatically over Bluetooth (iOS adds Multipeer Connectivity and Android adds Google Play Services Nearby Connections where available)
- PIN and QR sessions wrap every position and marker delta in AES-256-GCM with ECDH P-256 session keys; Open mode skips encryption for trusted training and demo use
- Works on both iPhone and Android in the same session
- Battery-saver modes last all day (<2% per hour in Expedition mode)
- Ghost markers show last-known positions when someone moves out of range

OFFLINE MAPS:
Download region packs before you leave service from OpenStreetMap or OpenTopoMap, stored on your phone as MBTiles. Navigate with the MGRS grid overlay -- the same military grid system used by NATO. (Region downloads are throttled to respect public-tile-server usage policies; native USGS / Mapbox / MapTiler integrations are on the roadmap.)

TEAM COORDINATION:
- Assign roles: Lead, Scout, Medic, Comms, or custom
- Share waypoints with the whole team or keep them private
- Draw boundaries and get alerted if anyone crosses them
- Drop markers for hazards, rally points, objectives, or caches
- Hands-free NATO voice callouts announce position updates

11 NAVIGATION TOOLS:
Dead reckoning, two-point resection, pace counter, bearing calculator, coordinate converter (MGRS/lat-lon/DMS/UTM), range estimation, slope calculator, ETA calculator, magnetic declination, celestial navigation, and precision reference.

AFTER-ACTION REPORTS:
One tap generates a PDF with your team's tracks, timeline, markers, roster, and boundary events. Share it on the spot via AirDrop or Nearby Share.

4 DISPLAY THEMES:
Red Light (night vision safe), NVG Green, Day White, and Blue Force. All designed for field readability with glove-friendly controls.

PRIVACY BY DESIGN:
- No accounts, no sign-up, no login
- No cloud sync, no Red Grid servers for active sessions, no tracking, no ads
- Operational data (sessions, markers, tracks) stays on your device until you delete it, share it with nearby peers, or export it
- AES-256-GCM encryption on PIN and QR sessions (Open sessions are unencrypted by design for training / demo use)
- Optional release-only crash diagnostics (Sentry) with PII off and GPS coordinates stripped — see Privacy Policy
- In-app purchases handled by Apple or Google Play only

PRICING:
- Free: All 4 modes, 2-device team sync, 1 offline map region, Red Light theme
- Pro ($3.99/mo or $29.99/yr): All themes, unlimited maps, After-Action Reports
- Pro+Link ($5.99/mo or $44.99/yr): Everything in Pro + 8-device team sync
- Lifetime ($149.99): Full Pro+Link features, one-time purchase

Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Payment will be charged to your Apple ID or Google Play account at confirmation of purchase. Manage or cancel subscriptions in your device's subscription settings.

Terms of Use: https://redgridtactical.com/terms.html
Privacy Policy: https://redgridtactical.com/privacy.html

## Promotional Text (iOS, max 170 chars)
Coordinate nearby teams over Bluetooth -- no cell service needed. Encrypted GPS sharing with offline topo maps for SAR, hunting, and backcountry teams.

## Keywords (iOS, max 100 chars)
offline tracker,team gps,blue force,walkie talkie,hunting gps,sar,mgrs,topo map,hiking,group track

## What's New (v1.5.1)
Red Grid Link v1.5.1 -- critical fixes:

- Emergency Beacon: SOS button now correctly triggers the team alert and emergency overlay on the map screen.
- Field Link discovery: Scan/Join now actually initiates BLE discovery and surfaces nearby teammates.
- Hardened ECDH P-256 key exchange and stream cleanup during session teardown.
- Stability improvements and minor bug fixes.

If you experienced trouble starting a Field Link session or triggering the SOS in v1.5.0, this update resolves it.

## What's New (v1.5.0)
Security and communication update:
- ECDH P-256 key exchange (per-peer encryption with forward secrecy)
- Emergency beacon with one-tap SOS and team alerts
- Tactical messaging: 8 pre-canned messages + free text
- BLE Coded PHY negotiation on supported Android hardware
- Hardened stream cleanup and connection quality warnings

## What's New (v1.4.0)
Extended range and navigation update:
- BLE Long Range / Coded PHY support detection on capable devices; actual Bluetooth range depends on hardware, terrain, and interference
- Signal strength indicator for each connected teammate
- FixPhrase: share your location as 4 easy-to-remember words (~11m accuracy)
- Download OpenStreetMap or OpenTopoMap tiles for offline use
- Coordinate bar now cycles between MGRS and FixPhrase display

## What's New (v1.3.1)
Team coordination update:
- Assign team roles: Lead, Scout, Medic, Comms, or custom with callsigns
- Share waypoints with your team or keep them private
- Draw boundaries -- get alerted if anyone crosses
- Drop markers for hazards, rally points, objectives, and caches
- Hands-free NATO voice callouts for position updates
- Enhanced After-Action Report with per-member tracks
- Session export/import for backup and review
- 6 annotation colors with undo and delete

## What's New (v1.2.2)
Red Grid Link v1.2.2 -- navigation accuracy and usability update:
- Map tap-to-waypoint: tap any point on the map to name and save a waypoint
- Fixed MGRS grid zone bug: coordinates near band boundaries no longer shift to incorrect zones
- Dead reckoning compass mode: toggle between manual heading entry and live compass heading
- Terms of Use and Privacy Policy accessible from subscription screen
- Subscription auto-renewal disclosure in purchase flow

## What's New (v1.2.1)
Red Grid Link v1.2.1 -- reliability and navigation update:
- Fixed Field Link session creation: resolved iOS Bluetooth adapter state detection that prevented session start even with Bluetooth enabled
- Field Link service initialization fix: transport state listeners now properly wired at startup
- Persistent waypoint list: save, rename, and manage multiple waypoints
- Relative bearing arrow: arrow now points the direction to turn, not just compass bearing
- Resection and Dead Reckoning tools now integrate with waypoint system
- New app icon: updated network-star design with corner brackets
- BLE transport debug logging for connection troubleshooting
- Demo mode for screenshots (Washington DC coordinates)

## What's New (v1.2)
Red Grid Link v1.2 -- field hardening release:
- GPS Kalman filter for smoother, more accurate position tracking
- Peer HUD overlay: see distance and bearing to teammates on the map
- Step detector for accelerometer-based pace counting
- Ultra Expedition battery mode (<2%/hr for extended operations)
- Auto-reconnect with exponential backoff when peers go out of range
- Session history: review past sessions and team activity
- Offline map download UI with progress and region management
- Help & Getting Started guide accessible from Settings
- About screen with full disclaimers and Terms of Use
- Text contrast improvements across all themes (WCAG 4.5:1)
- Crash reporting (Sentry, privacy-safe -- no location data sent)
- Localization framework (English + Spanish)
- Bug fixes and stability improvements from QA testing

## What's New (v1.0)
Red Grid Link v1.0 -- initial release:
- Live MGRS navigation with 1-meter precision
- Field Link proximity sync (BLE plus platform peer transports where available)
- AES-256-GCM encrypted sync with ECDH key exchange
- Offline map downloads (USGS Topo + OpenTopoMap)
- Ghost markers with time-decay visualization
- 4 operational modes (SAR, Backcountry, Hunting, Training)
- 4 tactical display themes
- 11 tactical land navigation tools
- After-Action Report PDF export
- NATO phonetic voice readout

## Privacy Highlights
- No accounts, no analytics, no advertising networks
- Operational data (sessions, markers, tracks) stays on your device until you delete it, share it with nearby peers, or export it
- Location used only when the app is in foreground (and during active Field Link sessions when background mode is enabled)
- Field Link shares position only with nearby peers; PIN and QR sessions are AES-256-GCM encrypted, Open sessions are plaintext
- Optional release-only crash diagnostics via Sentry, with PII off and GPS coordinates stripped
- Map tile downloads are standard HTTPS requests to public OSM / OpenTopoMap servers (URL path only, no cookies, no identifiers)
- Red Grid does not send operational data to its servers; Field Link shares only with nearby peers, and exports happen only when you initiate them

## Privacy URL
https://redgridtactical.com/privacy.html

## Terms of Use (EULA) URL
https://redgridtactical.com/terms.html

## Marketing URL
https://redgridtactical.com/link.html

## Support URL
https://redgridtactical.com/about.html

## Age Rating
4+ / Everyone

## Price
Free (with Pro, Pro+Link, Team, and Lifetime in-app purchases)
