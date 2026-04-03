# Red Grid Link - App Store Listing

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
Track your team offline over Bluetooth. Encrypted GPS sharing, no cell needed.

## Full Description

Track your team anywhere -- no cell service, no internet, no accounts.

Red Grid Link turns nearby phones into a private team GPS network using Bluetooth and WiFi Direct. See everyone's position on a shared map, drop waypoints, set boundaries, and coordinate -- all without cell towers or internet. Your data never leaves your devices.

Built by an active duty Army officer for the people who actually need it: search & rescue volunteers, hunting parties, backcountry hiking groups, and field training teams.

WHO IT'S FOR:
- Search & Rescue teams tracking searchers across sectors
- Hunting groups monitoring stand positions and property lines
- Backcountry hikers keeping tabs on a spread-out group
- Training teams running field exercises without military infrastructure

HOW IT WORKS:
Open the app, start a session, and every teammate within Bluetooth range appears on your map. No pairing, no configuration, no internet required.

- Devices discover each other automatically over Bluetooth and WiFi Direct
- Positions update every few seconds with military-grade AES-256 encryption
- Works on both iPhone and Android in the same session
- Battery-saver modes last all day (<2% per hour in Expedition mode)
- Ghost markers show last-known positions when someone moves out of range

OFFLINE MAPS:
Download topographic maps before you leave service. Full USGS Topo and OpenTopoMap coverage, stored on your phone. Navigate with MGRS grid overlay -- the same military grid system used by NATO.

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
- No cloud, no servers, no tracking, no ads
- All data stays on your device
- Session data is ephemeral -- gone when the session ends
- AES-256-GCM encryption on all team communication
- In-app purchases handled by Apple/Google only

PRICING:
- Free: All 4 modes, 2-device team sync, 1 offline map region, Red Light theme
- Pro ($3.99/mo or $29.99/yr): All themes, unlimited maps, After-Action Reports
- Pro+Link ($5.99/mo or $44.99/yr): Everything in Pro + 8-device team sync
- Lifetime ($149.99): Full Pro+Link features, one-time purchase

Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Payment will be charged to your Apple ID account at confirmation of purchase. Manage or cancel subscriptions in your device's Settings > Apple ID > Subscriptions.

Terms of Use: https://redgridtactical.com/terms.html
Privacy Policy: https://redgridtactical.com/privacy.html

## Promotional Text (iOS, max 170 chars)
Track your team offline over Bluetooth -- no cell service needed. Encrypted GPS sharing with offline topo maps for SAR, hunting, and backcountry teams.

## Keywords (iOS, max 100 chars)
offline tracker,team gps,blue force,walkie talkie,hunting gps,sar,mgrs,topo map,hiking,group track

## What's New (v1.4.0)
Extended range and navigation update:
- BLE Long Range: up to 1km range on supported devices (BLE 5.0 Coded PHY)
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
- 783 tests passing, 0 warnings

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
- 783 tests passing, 0 warnings

## What's New (v1.0)
Red Grid Link v1.0 -- initial release:
- Live MGRS navigation with 1-meter precision
- Field Link proximity sync (BLE + WiFi Direct/AWDL)
- AES-256-GCM encrypted sync with ECDH key exchange
- Offline map downloads (USGS Topo + OpenTopoMap)
- Ghost markers with time-decay visualization
- 4 operational modes (SAR, Backcountry, Hunting, Training)
- 4 tactical display themes
- 11 tactical land navigation tools
- After-Action Report PDF export
- NATO phonetic voice readout

## Privacy Highlights
- No data collected
- No tracking
- No analytics
- All data stays on device
- Location used only when app is in foreground (and for Field Link background sync)
- Field Link shares position only with nearby peers via encrypted BLE/WiFi Direct
- No server communication required for any feature

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
