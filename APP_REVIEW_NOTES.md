# App Store Review Notes — Red Grid Link v1.2.1

Use these notes in **App Store Connect → App Information → App Review Information → Notes**.

---

## Review Notes (paste into ASC)

```
Red Grid Link is an offline-first MGRS navigation app with proximity team sync via Bluetooth Low Energy (BLE).

DEMO MODE:
To test without real GPS: Settings → Demo Mode → toggle ON. This provides Washington DC coordinates so all navigation features work indoors.

KEY FEATURES TO TEST:
1. Grid Tab: Shows live MGRS coordinates, compass heading, speed, altitude
2. Map Tab: Offline topo map with MGRS grid overlay
3. Tools Tab: 11 tactical calculators (Dead Reckoning, Resection, Pace Count, etc.)
4. Field Link Tab: Create Session to start BLE proximity sync (requires 2 devices for full test)

FIELD LINK TESTING:
Field Link requires two physical devices with Bluetooth enabled to demonstrate peer sync. With a single device you can:
- Create a session (host)
- See the session status card (waiting for peers)
- Verify encryption badge (AES-256-GCM)
If you only have one test device, the session will start successfully but show 0 peers.

PERMISSIONS USED:
- Location (foreground + optional background): Required for MGRS coordinate display and Field Link position sharing
- Bluetooth: Required for Field Link peer discovery and data sync
- Local Network: Used by Multipeer Connectivity for WiFi Direct/AWDL peer transport
- Camera: QR code scanning for session join (optional security tier)

BACKGROUND LOCATION:
Background location is only active during Field Link sessions and is clearly disclosed to the user before enabling. The app shows a battery drain projection when background mode is active.

ENCRYPTION:
The app uses AES-256-GCM with ECDH P-256 ephemeral keys for Field Link communication. ITSAppUsesNonExemptEncryption is set to NO because:
- Encryption is used solely for securing local device-to-device BLE communication
- No data is transmitted over the internet
- This qualifies for the exemption under Category 5 Part 2 of the EAR

SUBSCRIPTIONS:
- Pro ($3.99/mo or $29.99/yr): Display themes, unlimited map downloads, AAR export
- Pro+Link ($5.99/mo or $44.99/yr): Pro features + 8-device Field Link
- Team ($199.99/yr): Pro+Link for 8 seats
- Lifetime ($99.99): One-time Pro+Link purchase

PRIVACY:
No accounts, no analytics, no tracking, no ads, no third-party data SDKs. All data stays on-device.
```

---

## App Review Contact Information

- **Name:** [Your name]
- **Email:** redgridtactical@gmail.com
- **Phone:** [Your phone number]

## Sign-In Required?
**No** — The app has no accounts or sign-in.

## Attachment Notes
If reviewers need Field Link demonstration, consider attaching a short screen recording showing two devices syncing via BLE.
