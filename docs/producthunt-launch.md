# Product Hunt Launch — Red Grid Link

## Product Name

Red Grid Link

## Tagline (60 chars max)

Encrypted Bluetooth team tracking + offline MGRS maps

## Description (short, for the card — 260 chars max)

Turn your team's phones into an encrypted mesh network for position sharing — no cell towers, no servers, no accounts. Built for SAR, hunting, and backcountry teams operating beyond cell service. MGRS-native navigation with offline topo maps.

## Full Description (for the product page)

**Red Grid Link turns your team's phones into an encrypted mesh network — no cell towers, no servers, no accounts required.**

If you've ever tried to coordinate a search-and-rescue operation, a hunting party, or a backcountry trip beyond cell service, you know the problem: consumer GPS apps assume you have internet, and military-grade solutions like ATAK require a PhD in XML configuration and a dedicated IT staff.

Red Grid Link sits in the middle. It's a lightweight, privacy-first team coordination app that uses Bluetooth Low Energy and WiFi Direct to create an ad-hoc network between your team's phones. Everyone sees everyone else's position on a shared MGRS map — encrypted end-to-end, synced in real time, with zero infrastructure.

### How Field Link Works

1. One person creates a session and picks a security level (Open, PIN, or QR code).
2. Nearby devices auto-discover each other over Bluetooth.
3. An ECDH P-256 key exchange establishes a shared secret, and all position data is encrypted with AES-256-GCM.
4. Positions sync using CRDTs (conflict-free replicated data types), so there's no "master" device — the mesh is resilient to devices joining and leaving.

Range is approximately 100m line-of-sight between devices, with the mesh relaying positions across the group.

### Who It's For

- **Search & Rescue teams** coordinating grid searches in wilderness areas
- **Hunting parties** tracking members across terrain with no cell coverage
- **Backcountry hiking groups** that want accountability without carrying radios
- **Military training exercises** that need a lightweight ATAK alternative
- **Wildland fire crews** maintaining situational awareness on the fireline

### What Makes It Different

- **No servers.** Positions never leave the local mesh. There is nothing to hack, subpoena, or pay monthly hosting fees for.
- **No accounts.** Open the app, create a session, connect. That's it.
- **MGRS-native.** Built around Military Grid Reference System coordinates — not bolted on as an afterthought. Full coordinate conversion between MGRS, UTM, lat/lon, and DD/DMS.
- **Offline topo maps.** Download MBTiles map regions over WiFi before you leave, then navigate completely offline.
- **Cross-platform.** iOS and Android, connecting to each other seamlessly.
- **Lightweight.** Under 50MB installed. No background data usage. Battery-optimized with configurable update intervals down to expedition mode (60s intervals for multi-day trips).

### The Backstory

I spent years watching teams struggle with two bad options: consumer apps that die without cell service, or ATAK — which is incredible but requires a week of training and a dedicated server. I built Red Grid MGRS as a solo navigation app first, then realized the real gap was team coordination. Red Grid Link is the result: everything I wished I had in the field, built for people who need it to just work.

### Pricing

- **Free:** All 4 operational modes, 2-device Field Link, 1 offline map region, Red Light theme
- **Pro ($3.99/mo or $29.99/yr):** All themes, unlimited map downloads, after-action review
- **Pro+Link ($5.99/mo or $44.99/yr):** Pro features + 8-device Field Link mesh
- **Lifetime ($99.99):** Pro+Link forever, one purchase
- **Team ($199.99/yr):** Pro+Link for 8 seats

No ads. No data collection. No account required for the free tier.

## Maker's Comment

> Hey Product Hunt — I'm the solo dev behind Red Grid Link.
>
> Red Grid Link started as a side project called Red Grid MGRS — a simple MGRS navigation app I built because I was tired of converting grid coordinates by hand in the field. But every time I showed it to people, the first question was always the same: "Can my team see each other on the map?"
>
> So I built Field Link. The technical approach is a bit unconventional: instead of standing up a server (which defeats the purpose of an offline-first app), I went with Bluetooth Low Energy + WiFi Direct for the transport layer, AES-256-GCM for encryption with a proper ECDH key exchange, and CRDTs for state sync so there's no single point of failure in the mesh. Every device is equal — no "host" required after session creation.
>
> The hardest part was honestly making BLE reliable across iOS and Android simultaneously. Apple and Google have... different philosophies about Bluetooth, let's say. The CRDT sync engine was the fun part — position updates are delta-compressed to under 200 bytes each, so the narrow BLE pipe isn't a bottleneck.
>
> The app is live on the App Store now with Android coming shortly. I'm a one-person team, so feedback goes directly into the next sprint.
>
> Curious to hear from this community: **has anyone else tried building real-time sync over BLE? What was your experience with cross-platform Bluetooth reliability?** I'd love to compare notes.

## Topics / Categories

- **Developer Tools** (custom sync protocol, CRDT architecture)
- **Privacy** (zero-server, encrypted mesh)
- **Outdoors** (hiking, hunting, SAR)
- **Maps & Navigation**
- **Open Source** (GitHub repo is public)
- **iPhone** / **Android**
- **Made with Flutter**
- **Solo Maker**

## Launch Strategy Notes

### Best Posting Time

- **12:01 AM PT (San Francisco time)** — Product Hunt's "day" resets at midnight Pacific. Posting at 12:01 AM gives the full 24-hour window to accumulate upvotes.
- Best day: **Tuesday, Wednesday, or Thursday.** Avoid weekends (lower traffic) and Monday (crowded with weekend launches).

### Engaging with Comments

- Respond to every comment within 1 hour during the first 12 hours.
- Be technical and honest — PH audiences respect builders who speak plainly about trade-offs.
- If someone asks about ATAK, acknowledge it's the gold standard but explain the complexity gap Red Grid Link fills.
- Share specific technical details when asked (BLE throughput, CRDT implementation, encryption specifics). This community loves depth.
- Upvote thoughtful comments from others — don't just reply to your own thread.

### Cross-Promotion Links

- **Dev.to:** Publish a technical deep-dive article the same day — "Building Real-Time Team Sync Over Bluetooth with CRDTs" — and link to the PH launch.
- **Reddit:** Post in r/FlutterDev (technical build story), r/SearchandRescue (use case), r/hiking (practical angle), r/privacy (zero-server architecture). Follow each sub's self-promotion rules.
- **Hacker News:** Consider a Show HN post 1-2 days after PH launch to avoid splitting attention. Lead with the technical angle (BLE mesh + CRDTs).
- **Landing page:** https://redgridtactical.com/ — make sure the PH badge is embedded on launch day.
- **GitHub:** https://github.com/RedGridTactical/RedGridLink — pin a "Featured on Product Hunt" note in the README.

### What NOT to Do

- **Do not ask for upvotes.** Product Hunt will penalize or delist your product. This includes DMs, emails, Slack messages, and "support us on PH" posts.
- **Do not use upvote pods or engagement groups.** PH's algorithm detects coordinated voting patterns.
- **Do not spam your link in unrelated communities.** It burns goodwill and gets flagged.
- **Do not launch on the same day as a major Apple/Google event** — you'll get buried.
- **Do not pad features.** If someone asks about something not yet built, say "that's on the roadmap for V2" — honesty builds trust.
- **Do not ignore critical feedback.** A thoughtful response to criticism is worth more than ten positive replies.

## Social Media Templates

### 1. Technical Angle

> Just launched Red Grid Link on @ProductHunt. It's a mesh networking app that syncs team positions over BLE with AES-256-GCM encryption and CRDT-based state sync. No servers, no internet, no accounts. Built with Flutter + custom Dart crypto.
>
> https://apps.apple.com/app/id6760084718

### 2. Military / Outdoor Angle

> Built for people who operate beyond cell service. Red Grid Link turns your team's phones into an encrypted position-sharing mesh — works for SAR, hunting, backcountry, and training ops. MGRS-native with offline topo maps. Live on Product Hunt today.
>
> https://apps.apple.com/app/id6760084718

### 3. Privacy Angle

> What if your team tracking app had zero servers, zero accounts, and zero data collection? Red Grid Link syncs positions over encrypted Bluetooth — your location never touches the internet. Now live on Product Hunt.
>
> https://redgridtactical.com/
