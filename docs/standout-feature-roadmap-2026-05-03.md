# Red Grid Link Standout Feature Roadmap

Date: 2026-05-03
Scope: Product strategy, market research, roadmap cross-reference, and app-family separation

## Product Rule

Red Grid Link and Red Grid MGRS should not blur into the same app.

- Red Grid MGRS owns solo navigation: MGRS coordinate work, individual land navigation, tactical calculators, solo route planning, personal waypoints, precision references, celestial/dead-reckoning depth, and solo practice.
- Red Grid Link owns team awareness and coordination: shared positions, assignments, roles, accountability, peer-to-peer sync, team safety, incident records, AARs, team training, interoperability, and organization licensing.
- A feature belongs in Link only if it answers at least one team question: who is where, who is doing what, who is safe, what changed, what needs to be shared, what must be documented, or how the team keeps operating without infrastructure.

This rule should be treated as a roadmap gate. If a proposed feature is primarily useful to one person alone, it belongs in Red Grid MGRS or a shared engine, not in Link.

## Research Summary

The market is already willing to pay for offline maps, live location, team plans, and operational recordkeeping:

- onX Hunt Elite is $99.99/year and bundles offline maps, property data, map tools, sharing, weather, lidar, and hunt-specific layers.
- CalTopo has become the default mapping backbone for many outdoor/SAR workflows because it combines collaborative maps, live team tracking, location integrations, offline mode, and team accounts.
- CalTopo Teams subscriptions start at $2,000/year for organizations up to 50 people, with volunteer-first-responder discounts.
- Avenza charges professional users from $169.99/year per device and team pricing for organizations, mainly around offline maps, geospatial PDF/GeoTIFF, data capture, export, geofences, and device/license management.
- TAK's official positioning is full situational awareness, blue-force tracking, mission data sharing, serverless CoT/chat in local networks, and TAK Server for broader storage/brokerage.
- Meshtastic validates demand for low-cost off-grid radio range, encrypted channels, phone-to-radio control, GPS position packets, and MQTT/private-broker bridging.

The gap Red Grid Link can exploit is not "more map layers than Gaia" or "more tools than TAK." It is:

> The fastest local-first team awareness app for small teams that need accountable operations without cell service, accounts, servers, or a full TAK/CalTopo deployment.

## Current Roadmap Cross-Reference

| Theme | Already planned in `ROADMAP.md` | Keep in Link? | Recommendation |
| --- | --- | --- | --- |
| Meshtastic Bridge | V1.6 | Yes | Keep. This is a standout Link feature because it extends team awareness beyond BLE. Scope to position, status, SOS, and low-bandwidth assignment updates before generic chat. |
| Android Launch | V1.6 | Yes | Keep. Cross-platform team sync is core to Link. Launch only after physical-device reliability and claims alignment. |
| Session Templates | V1.6 | Yes | Keep. Convert into "Mission Packets" that include roster, roles, assignment defaults, map region, security mode, and AAR settings. |
| Buddy System | V2.0 | Yes | Keep. This is high-value accountability, not solo nav. Add escalation and "last confirmed together" logic. |
| Check-in Timer | V2.0 | Yes | Keep. Make it a Personnel Accountability Report (PAR) workflow for SAR/training teams. |
| Status Board | V2.0 | Yes | Keep. Tie to roles, check-ins, SOS, low battery, link health, and assignment state. |
| Rally Points | V2.0 | Yes | Keep. It is team coordination. The underlying bearing/distance math can come from shared MGRS code. |
| Sector Assignment | V2.0 | Yes | Keep. This is one of the clearest Team/SAR Pro features. |
| Search Pattern Generator | V2.0 | Yes, if assignment-first | Keep in Link only as team assignment generation. Solo pattern practice belongs in MGRS/training. |
| Live Tactical Drawing | V2.0 | Yes | Keep. Add role/layer permissions so not every user sees every planning layer. |
| Photo Sharing | V2.0 | Yes, but narrow | Do not build generic photo chat. Build clue/hazard/evidence photo markers with thumbnails over mesh and full file local/export. |
| SAR Pro | V2.0 | Yes | Keep and move even more focus here. This should be the first serious Team revenue product. |
| Guide/Outfitter License | V2.0 | Yes | Keep. Reframe as "client guest seats plus trip packet plus post-trip report." |
| ATAK/CoT | V2.0 | Yes | Keep as interoperability, not replacement. Export/bridge Red Grid objects into existing command systems. |
| Task Management | V2.1 | Yes | Keep. Move an MVP into V2.0 if it powers assignments and AAR. |
| Voice Clips | V2.1 | Maybe | Delay. Bandwidth/support cost is high. Text/status/SOS is more important. |
| Freehand Annotation | V2.1 | Yes | Keep if synced and role/layer-aware. |
| Replay Timeline | V2.1 | Yes | Move earlier. Replay is a monetizable AAR/training feature and proves team value. |
| GPX/KML Import/Export | V2.1 | Shared | Keep in Link for team data exchange. Keep solo route/import depth in MGRS. |
| Elevation Profile | V2.1 | Mostly MGRS/shared | Keep in Link only when attached to team assignments, safety, or route plans. Otherwise this is MGRS territory. |
| Line-of-Sight | V2.1 | Maybe | Keep in Link only for comms/team planning, e.g. "can Lead reach Team 2 from ridge?" Solo LOS belongs in MGRS. |
| Terrain Difficulty | V2.1 | Maybe | Keep if used to estimate assignment duration and coverage confidence. Otherwise move to MGRS. |
| Cloud Relay | V3.0 | Yes, optional | Keep, but add local command-post mode first. Cloud must preserve local-first trust. |
| Web Dashboard | V3.0 | Yes | Keep. Prioritize local/LAN dashboard before cloud dashboard. |
| Multi-Team Coordination | V3.0 | Yes | Keep. Valuable for mutual aid and large training. |
| Multi-hop BLE Mesh | V3.0 | Maybe | Deprioritize behind Meshtastic and local hub. BLE mesh is platform-hard and may not outperform radio bridge. |
| Team Management Portal | V3.0 | Yes | Keep for org revenue. Add offline license files. |
| Garmin inReach | V3.0 | Yes | Keep if it feeds team awareness and command visibility. |
| External GPS | V3.1 | Shared/MGRS-first | MGRS can own solo external GPS support. Link uses it only as a higher-quality team position source. |
| Heart Rate Monitoring | V3.1 | Maybe | Delay. It is privacy-sensitive and not needed before SAR/team workflows are mature. |
| Environmental Sensors | V3.1 | Maybe | Delay unless tied to team safety or incident records. |
| Training Scenario Builder | V4.0 | Yes | Move earlier. Training budgets can monetize before full enterprise cloud. |
| Instructor Mode | V4.0 | Yes | Move earlier as V2.2/V2.3. This is differentiated and fits Link. |
| Simulated Peers | V4.0 | Split | Solo simulation belongs in MGRS. Multi-team exercise simulation belongs in Link. |

## What Should Become The Standout Strategy

### 1. Field Readiness Preflight

Status: Not explicitly planned.

Why it matters:

Every competitor has offline features, but users still worry whether the app will actually work when they lose service. CalTopo's new Offline Mode exists partly because weak signal areas make online-first behavior feel unreliable. Red Grid Link can make "ready before leaving service" a first-class workflow.

Feature:

- One-tap mission readiness check before deployment.
- Confirms downloaded AO map coverage, map provider/license status, GPS permission, background location, Bluetooth, local network, notifications, battery mode, storage, encryption mode, team roster, and last successful peer test.
- Shows each teammate as Ready, Partial, or Not Ready.
- Exports a readiness snapshot into the AAR.

Roadmap fit:

- Add to V1.6 as launch hardening.
- Supports Android launch, session templates, offline maps, and Field Link.

MGRS/Link boundary:

- Link owns team readiness.
- MGRS may get a simpler solo "offline-ready" checklist later.

Revenue:

- Free: local device readiness.
- Pro Link/Team: whole-team readiness and exported audit.

### 2. Mission Packets

Status: Partly planned as session templates.

Why it matters:

Small teams need to start fast. A Mission Packet makes Link feel operational instead of just a map with peers.

Feature:

- Build a session from a template: SAR Hasty Search, Training Lane, Hunting Party, Guide Trip, Event Safety, Family Hike.
- Packet includes operational mode, roster roles, security mode, check-in cadence, rally point, boundaries/sectors, required map region, quick messages, and AAR schema.
- Share by QR, local file, AirDrop/Nearby Share, or Field Link.
- Later: import from CalTopo/GPX/KML/CoT.

Roadmap fit:

- Extends V1.6 session templates.
- Feeds V2.0 assignments and SAR Pro.

MGRS/Link boundary:

- Link owns mission/team packets.
- MGRS can import solo waypoints/routes, but not team assignments.

Revenue:

- Pro Link: custom templates.
- Team: organization templates and admin defaults.

### 3. Coverage Confidence Engine

Status: Planned in pieces under SAR Pro track recording, coverage analysis, and gap detection. Needs to become a headline.

Why it matters:

SAR users do not just need "where did we go?" They need "what have we actually searched?" A CalTopo community feature request specifically asks for speed/modality-based track styling because manual track toggling can misrepresent searched vs transited areas.

Feature:

- Auto-classify track segments as searching, transit, stationary, vehicle, uncertain, or stale using speed, role, mode, heading variance, and user-selected modality.
- Let Team Lead set swath width per modality/person/dog team.
- Render searched area and unsearched gaps.
- Highlight "low confidence" segments where GPS accuracy, speed, or missing updates make coverage uncertain.
- Include coverage confidence in AAR and ICS-style exports.

Roadmap fit:

- Elevate into V2.0 SAR Pro.
- It makes "track recording per member, coverage analysis, gap detection" concrete and monetizable.

MGRS/Link boundary:

- Link owns team coverage and assignment completion.
- MGRS can own personal track stats.

Revenue:

- SAR Team tier anchor.
- Strong demo: show a sector filling in live as teams search.

### 4. Role-Based Layers And Need-To-Know Visibility

Status: Not explicitly planned.

Why it matters:

CalTopo users discuss workarounds for separating live tracking from search-manager-only information, including running multiple maps because item-level permissions are limited. Link can stand out by making this simple and local-first.

Feature:

- Layers: Team Visible, Lead Only, Trainers Only, Evidence/Clues, Medical/Safety, Public/Client.
- Per-marker and per-annotation visibility.
- Trainer can hide subject track/clues during exercises.
- Lead can push only the assignment layer to field teams while keeping planning notes private.
- AAR/export can include all layers or selected layers.

Roadmap fit:

- Add to V2.0 live tactical drawing, clue logging, and training mode.
- Also supports V4 instructor mode if moved earlier.

MGRS/Link boundary:

- Pure Link. Solo MGRS has no role-based team layers.

Revenue:

- Team/SAR Pro only. This is an organization feature, not a consumer feature.

### 5. Local Command Post Mode

Status: Not planned as distinct from V3.0 cloud/web dashboard.

Why it matters:

Cloud relay is useful, but the brand promise is "no infrastructure." A local command-post mode should come before cloud. Competitors often depend on a server or online sync for multi-user collaboration; Red Grid can own the small-team offline command-post niche.

Feature:

- One phone/tablet/laptop acts as local command post over BLE, AWDL/Nearby, Wi-Fi LAN, or Meshtastic gateway.
- Local dashboard displays roster, map, assignments, check-ins, SOS, track health, and AAR builder.
- No account required.
- Optional later sync when connectivity returns.

Roadmap fit:

- Add as V2.2 or early V3.0 before cloud relay.
- Web dashboard should support local-first mode first, cloud second.

MGRS/Link boundary:

- Link only.

Revenue:

- Team tier. This justifies annual organization licensing.

### 6. CalTopo Companion Mode

Status: Not planned explicitly. Related to Meshtastic, GPX/KML, and ATAK/CoT.

Why it matters:

Many SAR teams are already centered on CalTopo/SARTopo. Trying to replace it immediately is a hard sell. A companion mode lets Red Grid Link win by solving the specific off-grid field-team gap and handing structured data back to CalTopo afterward.

Feature:

- Import sectors/assignments from GPX/KML/GeoJSON, and later CalTopo Team API where appropriate.
- Export tracks, clues, assignments, and AAR data back to GPX/KML/GeoJSON/CSV.
- Optional command-post bridge: Meshtastic/APRS/CoT to CalTopo Desktop or Team tracking.
- "Field Team Mode": teams use Link offline, command staff can still use CalTopo/TAK as system of record.

Roadmap fit:

- Add GPX/KML/GeoJSON import/export to V2.0/V2.1.
- Add CalTopo bridge after Meshtastic MVP.

MGRS/Link boundary:

- Link owns team/incident data exchange.
- MGRS owns solo route/waypoint import/export.

Revenue:

- Team tier, because it reduces switching cost for real SAR teams.

### 7. CoT/TAK Bridge, Not TAK Clone

Status: Planned in V2.0.

Why it matters:

TAK already dominates the high-end situational-awareness category. Red Grid Link should be the easy field-team endpoint and local bridge, not a full clone.

Feature:

- Emit Cursor-on-Target position, marker, route, and SOS events.
- Import basic CoT positions and markers.
- Local UDP multicast on shared Wi-Fi.
- Meshtastic low-bandwidth translation for positions/status/SOS.
- Clear security labels when data leaves Field Link encryption.

Roadmap fit:

- Keep V2.0, but scope as "CoT Lite" first.
- Avoid deep TAK plugin ecosystem until after core Link is reliable.

MGRS/Link boundary:

- Link owns team/interop bridge.
- MGRS may export a single solo position/report, but not live team bridging.

Revenue:

- Pro Link for individual bridge.
- Team for command-post bridge and policy controls.

### 8. Team Accountability Pack

Status: Planned in pieces: buddy system, check-ins, status board, missed check-in escalation, emergency beacon.

Why it matters:

Accountability is more emotionally and operationally valuable than "another marker type." It also creates recurring team value.

Feature:

- Buddy pairs.
- PAR/check-in timer.
- Status board: Green, Amber, Red, Black, Moving, Stationary, Offline, Low Battery.
- Missed check-in escalation.
- Low-battery and no-motion alerts.
- Last voice/radio contact timestamp.
- "Last known good" card for every member.

Roadmap fit:

- Combine V2.0 Team Awareness and V2.1 Accountability into one earlier "Accountability Pack."

MGRS/Link boundary:

- Link only.

Revenue:

- Free: simple status and SOS for 2 devices.
- Pro Link: check-ins and buddy alerts.
- Team: PAR exports and admin defaults.

### 9. Clue, Hazard, And Evidence Workflow

Status: Planned as clue logging and photo sharing.

Why it matters:

Clues are not just markers. They are operational records with confidence, chain-of-custody-lite, visibility controls, and export value.

Feature:

- Clue marker: photo, notes, MGRS, timestamp, finder, confidence, action taken, visibility, status.
- Hazard marker: severity, radius, required action.
- Evidence marker: hidden-by-default from field teams unless Lead shares.
- Sync thumbnail and metadata over low bandwidth; keep full-resolution media local/export unless on Wi-Fi/local command-post link.
- AAR and ICS attachments.

Roadmap fit:

- Deepen V2.0 clue logging and photo sharing.

MGRS/Link boundary:

- Link owns team clue/evidence workflow.
- MGRS can keep simple solo waypoint photo notes if desired.

Revenue:

- Team/SAR Pro feature.

### 10. Training Pack Earlier Than V4

Status: Planned in V4.0, too late.

Why it matters:

Training teams have budget and can test without real incident liability. Instructor mode also showcases team awareness, replay, hidden layers, and AARs better than a consumer hike.

Feature:

- Instructor creates scenario packet.
- Hidden subject route/clues.
- Inject events during exercise.
- Observer view of all teams.
- Replay and score: check-in compliance, assignment completion, route efficiency, clue response, time to objective.
- Export training AAR/certificate.

Roadmap fit:

- Move from V4.0 to V2.2 or V2.3 after SAR Pro MVP.

MGRS/Link boundary:

- Link owns team/instructor training.
- MGRS owns solo land-nav drills and simulated solo practice.

Revenue:

- Training license or Team add-on.

### 11. Licensed Offline Map Stack And Map Health

Status: Roadmap mentions USGS/Mapbox/MapTiler; current app surfaces OSM/OpenTopo downloads. Needs explicit productization.

Why it matters:

OSM's public tile policy prohibits offline/prefetch use from `tile.openstreetmap.org`. A paid app should not depend on public tile scraping for core offline map value.

Feature:

- Provider abstraction: demo/basic online OSM, licensed offline provider, self-hosted PMTiles/vector tiles, USGS where allowed.
- Map health: downloaded AO coverage, missing zooms, stale layers, storage impact, attribution, and "will work offline" status.
- Team map parity: Lead can see whether teammates have the same AO downloaded.

Roadmap fit:

- Move from general roadmap note into V1.6/V2.0 infrastructure.

MGRS/Link boundary:

- Shared map engine can be common.
- Link-specific value is team map parity and mission AO readiness.
- MGRS-specific value is solo map catalog and route planning.

Revenue:

- Pro: licensed offline maps.
- Team: shared AO map packs and admin-defined map baselines.

### 12. Organization Licensing With Offline Entitlements

Status: Planned as V3.0 team portal. Should start earlier with minimal form.

Why it matters:

Organization revenue requires license management that works when the team is away from the internet.

Feature:

- Team license file signed by Red Grid.
- QR enrollment for devices.
- Offline grace period.
- Admin roster/callsign defaults.
- Seat export/import.
- Later: hosted portal and store/server validation.

Roadmap fit:

- Minimal offline team license in V2.0 or V2.1.
- Full portal in V3.0.

MGRS/Link boundary:

- Link owns team/org licensing.
- MGRS can keep normal individual purchase flow.

Revenue:

- Enables SAR Team, Guide, Event Safety, Training, and enterprise pilots.

## Recommended Roadmap Rewrite

### V1.6: Link Reliability + Android + Meshtastic MVP

Goal: Make team sync credible and cross-platform.

Keep:

- Meshtastic BLE bridge.
- Android production launch.
- Physical Android QA.
- Session templates.

Add:

- Field Readiness Preflight.
- Map Health and licensed/offline provider decision.
- Team diagnostics export.
- Whole-team readiness indicators.
- Hard claims gate for docs/store copy.

Delay or trim:

- Product Hunt/BetaList until radio reliability and claim alignment are proven.
- F-Droid unless the build flavor is straightforward after Android production.

Exit criteria:

- Two iPhones and two Android phones can create/join/leave/reconnect in the field.
- Meshtastic MVP passes position/status/SOS over at least one supported radio.
- Every public claim maps to tested behavior.
- A team can verify maps, permissions, radios, and battery before leaving service.

### V2.0: SAR Pro MVP

Goal: Turn Link from "team dots on a map" into "team operations with records."

Keep from roadmap:

- Buddy system.
- Check-ins.
- Status board.
- Rally points.
- Sector assignment.
- Search pattern generator.
- Clue logging.
- ICS form generation.
- Track recording, coverage analysis, gap detection.

Add:

- Mission Packets.
- Coverage Confidence Engine.
- Role-based layers.
- Team Accountability Pack.
- Clue/hazard/evidence workflow.
- Replay MVP.
- CalTopo-compatible export formats.

Exit criteria:

- A SAR/training team can run a mock hasty search from packet creation through assignment, check-ins, clue logging, coverage review, and AAR export.
- Lead can hide trainer/manager-only layers.
- AAR includes tracks, assignments, clue log, coverage gaps, roster, timeline, and map products.

### V2.1: Interoperability Pack

Goal: Fit into existing team stacks instead of demanding replacement.

Keep from roadmap:

- ATAK/CoT.
- GPX/KML import/export.
- Task management.
- Timeline replay.

Add:

- CoT Lite.
- CalTopo Companion Mode.
- GeoJSON/CSV exports.
- Local command-post bridge.
- Meshtastic/APRS/CoT translation for positions/status/SOS.

Delay:

- Voice clips unless beta teams explicitly demand them.
- Advanced terrain intelligence unless attached to assignments.

Exit criteria:

- Link can import an assignment area and export field tracks/clues in formats a SAR team can use.
- Link can bridge basic positions/status/SOS to a command-post system over local network or Meshtastic path.

### V2.2: Training And Instructor Pack

Goal: Create a paid use case that can be sold and tested without active incident risk.

Move up from V4.0:

- Scenario builder.
- Instructor mode.
- Injected events.
- Real-time scoring.
- Replay.
- Training AAR/certificate.

Add:

- Hidden subject track/clues.
- Evaluator notes.
- Team comparison.
- Reusable training lanes.

Exit criteria:

- An instructor can run a land-nav or SAR exercise with multiple teams, inject events, hide/reveal clues, replay performance, and export a training report.

### V3.0: Connected Operations

Goal: Add optional cloud without breaking local-first trust.

Keep:

- Cloud relay.
- Web dashboard.
- Multi-team bridging.
- Shift handoff.
- Team management portal.
- Integration API.
- Garmin inReach.

Revise:

- Local command-post mode ships before cloud relay.
- Cloud relay is encrypted and optional.
- Team portal manages licenses/templates/rosters, not necessarily operational data by default.

Exit criteria:

- An organization can manage seats and templates.
- Command can observe when connectivity exists.
- A field team can still run fully offline without cloud dependency.

### V3.1+: Sensors And Advanced Intelligence

Goal: Add only sensors that improve team safety or records.

Keep:

- External GPS as a shared engine capability.
- Garmin/inReach as team awareness source.

Delay:

- Heart rate unless there is clear team demand and privacy policy support.
- Environmental sensors unless they feed incident safety or AAR.

### V4.0: Advanced Simulation

Goal: Deep simulation after the earlier instructor pack is proven.

Keep:

- Larger scenario library.
- Performance analytics dashboard.
- Multi-incident exercises.
- Simulated peer swarms.

Move to MGRS:

- Solo practice and individual land-nav drills.

## Feature Priority Score

| Rank | Feature | Planned? | Differentiation | Revenue | Effort | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Field Readiness Preflight | No | Very high | Medium | Medium | Now |
| 2 | Mission Packets | Partial | High | High | Medium | V1.6/V2.0 |
| 3 | Coverage Confidence Engine | Partial | Very high | Very high | High | V2.0 |
| 4 | Team Accountability Pack | Partial | High | High | Medium | V2.0 |
| 5 | Role-Based Layers | No | Very high | High | Medium-high | V2.0 |
| 6 | Clue/Hazard/Evidence Workflow | Partial | High | High | Medium | V2.0 |
| 7 | Replay MVP | Planned later | High | High | Medium | V2.0 |
| 8 | Meshtastic MVP | Yes | Very high | High | High | V1.6 |
| 9 | CalTopo Companion Mode | No | Very high | High | Medium-high | V2.1 |
| 10 | CoT Lite | Yes | High | Medium-high | Medium | V2.1 |
| 11 | Local Command Post Mode | Partial via web/cloud | Very high | Very high | High | V2.1/V3.0 |
| 12 | Training Instructor Pack | Planned too late | High | High | High | V2.2 |
| 13 | Organization Offline Entitlements | Partial | Medium | Very high | Medium | V2.1/V3.0 |
| 14 | Licensed Offline Map Stack | Partial | Medium | High | High | V1.6/V2.0 |
| 15 | Cloud Relay | Yes | Medium | High | High | V3.0 |

## What Not To Build In Link

These may be valuable, but they should live in Red Grid MGRS or a shared package unless they directly serve team operations:

- Deep solo route planning.
- Solo terrain analysis.
- Standalone celestial/dead-reckoning expansion.
- Individual land-nav curriculum.
- Personal waypoint library depth.
- Generic map-layer catalog browsing.
- Solo AR compass.
- Generic outdoor social features.
- Personal fitness/training analytics.

Link should include enough navigation to let a team execute assignments safely, but not enough solo feature depth to confuse the app-family positioning.

## Pricing Implications

Suggested packaging after the roadmap cleanup:

- Free Link: 2-device Field Link, basic status/SOS, one mission packet/template, one offline area if licensed economics allow.
- Pro Link: 8-device encrypted team sync, readiness preflight, messaging, map health, AAR, custom mission packets.
- Team/SAR Pro: assignments, check-ins/PAR, role layers, clue/evidence workflow, coverage confidence, ICS/AAR exports, organization templates, offline entitlements.
- Training: instructor mode, hidden layers, injected events, scoring, replay, training exports.
- Guide/Event Safety: guest seats, prebuilt trip/event packets, client-safe view, post-trip/event report.

The most important pricing insight: Link should charge for coordination, accountability, and records. MGRS should charge, if needed, for solo navigation depth.

## Implementation Order

1. Lock the product boundary.
   - Update roadmap language so solo navigation depth is explicitly MGRS-owned.
   - Label Link features by team value.

2. Reframe V1.6 around reliability.
   - Add readiness preflight and team diagnostics.
   - Ship Android only when Field Link is stable on physical devices.
   - Keep Meshtastic MVP tight: position, status, SOS.

3. Build SAR Pro around one complete workflow.
   - Mission Packet -> assignment -> check-in -> clue -> coverage -> replay -> AAR/ICS export.

4. Add interoperability as adoption lubricant.
   - CalTopo/GPX/KML/GeoJSON first.
   - CoT Lite next.
   - Local command post before cloud.

5. Move training earlier.
   - Use instructor mode as a paid proving ground.
   - Let training validate role layers, replay, AARs, and hidden clues.

## Source Notes

- onX Hunt feature set and live location/offline positioning: https://www.onxmaps.com/hunt/app/features
- onX Hunt Elite pricing/features: https://www.onxmaps.com/hunt/elite
- CalTopo homepage/features: https://caltopo.com/
- CalTopo offline mode: https://blog.caltopo.com/2025/08/25/new-feature-offline-mode/
- CalTopo team accounts/pricing: https://training.caltopo.com/all_users/team-accounts
- CalTopo live team tracking: https://training.caltopo.com/all_users/team-accounts/team-tracking
- CalTopo location integrations, including Garmin/APRS/Meshtastic notes: https://training.caltopo.com/all_users/resources/integrations
- CalTopo local APRS/Meshtastic notes: https://training.caltopo.com/all_users/desktop/desktopaprs
- CalTopo community request for off-grid Meshtastic sharing: https://help.caltopo.com/hc/en-us/community/posts/43651713033499-CAlTopo-MeshTastic-integration-for-off-grid-location-tracking-and-sharing
- CalTopo community request for dynamic SAR tracking visualization: https://help.caltopo.com/hc/en-us/community/posts/38347502946075-Dynamic-Tracking-Visualization-for-SAR-Operations
- CalTopo community discussion on live tracking vs search-manager visibility: https://help.caltopo.com/hc/en-us/community/posts/13661117969563-Live-Tracking-vs-Search-Manager
- Avenza plan/features/pricing: https://store.avenza.com/pages/compare-plans
- TAK.gov overview and situational awareness positioning: https://tak.gov/
- TAK.gov products: https://tak.gov/products
- TAK.gov law-enforcement/public-safety positioning: https://tak.gov/solutions/law-enforcement
- TAK.gov emergency/public-safety positioning: https://tak.gov/solutions/emergency
- Meshtastic overview: https://meshtastic.org/docs/overview/
- Meshtastic MQTT/integration docs: https://meshtastic.org/docs/software/integrations/mqtt/
- OpenStreetMap tile policy: https://operations.osmfoundation.org/policies/tiles/
- FEMA ICS forms: https://training.fema.gov/emiweb/is/icsresource/icsforms/
- NWCG IAP map product standard: https://www.nwcg.gov/publications/pms936/map-product-standards/iap-map

## Bottom Line

Red Grid Link's standout path is not more solo navigation. That is Red Grid MGRS territory.

Link should become the local-first operations layer for small teams: readiness, team awareness, accountability, assignments, coverage confidence, clue/evidence records, interoperability, replay, and team licensing. If the roadmap is reorganized around that idea, Link becomes much easier to explain, easier to sell, and harder for generic map apps to copy.
