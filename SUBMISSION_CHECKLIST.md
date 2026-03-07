# App Store Submission Checklist — Red Grid Link v1.2.1

## Build Status
- [x] Version: `1.2.1+4` (pubspec.yaml)
- [x] 783/783 tests passing
- [x] 0 errors, 0 warnings (flutter analyze)
- [x] Codemagic build pushed (`ef076a4` → master)
- [ ] TestFlight build received and verified on device
- [ ] Codemagic build status: check https://codemagic.io

---

## App Store Connect — App Information

### General
- [x] App Name: `Red Grid Link`
- [x] Subtitle: `Offline MGRS Nav & Team Sync` (28/30 chars)
- [x] Bundle ID: `com.redgrid.redGridLink`
- [x] SKU: (set in ASC)
- [x] Primary Category: Navigation
- [x] Secondary Category: Utilities
- [x] Content Rights: Does not contain third-party content
- [x] Age Rating: 4+

### Pricing & Availability
- [x] Price: Free
- [x] Availability: All territories (or select specific)
- [x] Pre-order: No

### App Privacy
- [x] Privacy Policy URL: `https://github.com/RedGridMGRS/RedGridLink/blob/master/PRIVACY.md`
- [ ] **Privacy Nutrition Labels** — fill out in ASC:
  - Data Types: **None collected** (select "Data Not Collected")
  - Location: Used but NOT collected/tracked (stays on device)
  - No analytics, no tracking, no third-party SDKs

### In-App Purchases (already configured)
- [x] Pro Monthly ($3.99) — auto-renewable subscription
- [x] Pro Annual ($29.99) — auto-renewable subscription
- [x] Pro+Link Monthly ($5.99) — auto-renewable subscription
- [x] Pro+Link Annual ($44.99) — auto-renewable subscription
- [x] Team Annual ($199.99) — auto-renewable subscription
- [x] Lifetime Pro+Link ($99.99) — non-consumable
- [x] Subscription Group: "Red Grid Link Pro"

---

## App Store Connect — Version Information (v1.2.1)

### Text Content
- [x] **Promotional Text** (170 chars, editable anytime):
  `Offline MGRS navigation + encrypted BLE team sync for 2-8 people. No cell towers, no accounts, no servers. 11 tactical tools, 4 display themes, zero tracking.`
- [x] **Description**: Full description in `store.config.json` and `STORE_LISTING.md`
- [x] **What's New**: v1.2.1 release notes in `store.config.json`
- [x] **Keywords** (100 chars):
  `mgrs,tactical,navigation,offline,team,sync,BLE,military,grid,SAR,hunting,backcountry,map,GPS,compass`
- [x] **Support URL**: `https://github.com/RedGridMGRS/RedGridLink/issues`
- [x] **Marketing URL**: (optional — could use GitHub repo URL)

### Screenshots (REQUIRED — must be from real device or Simulator)
**iPhone 6.7" Display (1290 x 2796)** — REQUIRED, minimum 3:
- [ ] Screenshot 1: Map with team peers + HUD overlay
- [ ] Screenshot 2: Grid view with MGRS coordinates
- [ ] Screenshot 3: Field Link session with peers
- [ ] Screenshot 4: Ghost markers on map
- [ ] Screenshot 5: Tactical tools grid
- [ ] Screenshot 6: Themes & settings (4 themes)

**iPhone 6.5" Display (1284 x 2778)** — Optional if 6.7" provided
**iPhone 5.5" Display (1242 x 2208)** — Optional but recommended
**iPad Pro 12.9" (2048 x 2732)** — Only if supporting iPad

> **How to take screenshots:**
> 1. Enable Demo Mode in Settings (DC coordinates)
> 2. Run on iPhone 14 Pro Max (6.7" display = 1290x2796)
> 3. Use Simulator: `xcrun simctl io booted screenshot filename.png`
> 4. Or physical device: press Side + Volume Up

### App Review
- [x] **Review Notes**: See `APP_REVIEW_NOTES.md` (paste into ASC)
- [ ] **Contact Info**: Fill in name and phone number
- [x] **Sign-in Required**: No
- [ ] **Demo Account**: Not needed (no accounts)
- [ ] **Attachment**: Optional screen recording of Field Link between 2 devices

### Build
- [ ] Select the TestFlight build for this version
- [x] App icon: `icon_1024.png` (1024x1024, RGB, no alpha)
- [x] `ITSAppUsesNonExemptEncryption`: NO
- [x] Export Compliance: Exempt (local BLE encryption only)

---

## Pre-Submit Verification

### On-Device Testing (TestFlight build)
- [ ] Grid screen shows correct MGRS coordinates
- [ ] Map loads with MGRS grid overlay
- [ ] Demo Mode shows DC coordinates (`18S UJ ...`)
- [ ] Field Link: Create Session works with Bluetooth enabled
- [ ] Field Link: Session shows encryption badge
- [ ] All 4 themes render correctly
- [ ] All 4 operational modes switch correctly
- [ ] Tools: All 11 tools open and function
- [ ] Waypoints: Save, rename, delete, activate
- [ ] Bearing arrow points correct relative direction
- [ ] IAP: Subscription paywall appears for Pro features
- [ ] AAR: Report generates and exports PDF
- [ ] Onboarding: First-launch flow completes
- [ ] Background location: Battery drain projection shown

### Edge Cases
- [ ] Bluetooth off → "Enable Bluetooth" dialog appears
- [ ] Location denied → Graceful fallback shown
- [ ] No network → All features work offline
- [ ] Kill app and reopen → Saved waypoints persist
- [ ] Rotate device → Landscape mode works

---

## GitHub Release

- [ ] Tag: `v1.2.1`
- [ ] Title: `Red Grid Link v1.2.1 — Reliability & Navigation`
- [ ] Release notes: From STORE_LISTING.md "What's New (v1.2.1)"
- [ ] Mark as latest release

---

## Post-Submission

- [ ] Monitor App Store Connect for review status
- [ ] Respond to any reviewer questions promptly
- [ ] Once approved: set release date (manual or automatic)
- [ ] Update GitHub release with App Store link
- [ ] Announce on social media / relevant communities
