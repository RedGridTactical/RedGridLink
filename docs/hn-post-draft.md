# Show HN Post — Ready to Submit

## Title
Show HN: Red Grid Link -- peer-to-peer team tracking over Bluetooth, no servers

## URL
https://github.com/RedGridTactical/RedGridLink

## Text

I kept running into the same problem on backcountry trips: my group splits up, cell service is gone, and nobody knows where anyone is. The usual answer is "buy a $200 Garmin" or "use ATAK" -- but ATAK is Android-only, expects a TAK Server, and has a learning curve that'll eat your whole weekend. I just wanted phones to talk to each other directly.

So I built Red Grid Link. It syncs GPS positions between phones over Bluetooth and WiFi Direct. No server, no internet, no extra hardware. You open the app, start a session, and anyone nearby running it shows up on your map. When someone walks out of range, their last-known position stays on the map as a ghost marker that fades over time.

The part that took the longest was the sync engine. BLE connections drop constantly -- someone walks behind a tree, a truck, a ridge. I ended up building a CRDT-based sync layer (LWW Register + G-Counter) with delta encoding so each position update is under 200 bytes. CRDTs mean there's no conflict resolution to worry about when links are intermittent. Reconnects use exponential backoff from 2s to 30s, and peers degrade gracefully: connected, then reconnecting, then ghost.

Encryption is AES-256-GCM with ECDH P-256 key exchange -- every peer pair gets a unique session key. Sessions can be open, PIN-protected, or QR-authenticated depending on how paranoid you are.

Built with Flutter. About 180 Dart files, 783 tests, and a handful of Kotlin/Swift for the platform channel bridges to Android Nearby Connections and iOS Multipeer Connectivity. The whole thing runs offline-first with downloadable topo maps and MGRS grid coordinates.

It's on the App Store now (iOS, Android coming): https://apps.apple.com/app/id6760084718

Happy to go deep on any of the BLE transport, CRDT sync, or encryption architecture if anyone's curious.
