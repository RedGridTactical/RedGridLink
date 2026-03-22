# Red Grid Link — Ad Strategy (Solo Developer Budget)

Revised 2026-03-20. Original strategy produced zero downloads over ~2 weeks. Root cause: niche keywords with near-zero search volume. Nobody types "bluetooth team tracking" into the App Store.

---

## LESSONS LEARNED

1. **Niche keywords are a trap when volume is zero.** Low competition means nothing if nobody searches the term. "Bluetooth team tracking" and "peer to peer location" got zero impressions because zero people search for those phrases.
2. **Organic alone is too slow, but paid search only works when people are searching.** Red Grid Link solves a problem most people don't know they have until they're standing in the woods with no signal. That means demand-generation (content, community, virality) matters more than demand-capture (search ads).
3. **Field Link is the viral engine.** Every user who starts a session needs 1-7 teammates to install the app. One SAR team leader = 4-8 organic installs. Invest in getting the first user in each group, not in broad acquisition.
4. **The subscription model funds growth** -- but only after people discover the app. Free tier needs to be good enough that someone keeps it installed until the next trip.

---

## CHANNEL PRIORITY (REVISED)

Ranked by expected ROI for a solo iOS developer:

1. **Community posts** (free) -- Show HN, Reddit, forums. Targets people who care about the technical problem.
2. **Apple Search Ads** (cheap) -- but only on terms people actually search.
3. **Content** (free, time cost) -- Dev.to article, 60-second demo video, landing page SEO.
4. **Reddit Ads** (paid) -- only after organic Reddit posts establish which subreddits respond.

---

## APPLE SEARCH ADS — RESTRUCTURED

The old campaign targeted terms nobody searches. The new approach uses adjacent high-volume terms where Red Grid Link is a relevant result.

### Campaign 1: High-Volume Adjacent Keywords — $5/day

Match type: **Broad match** (not exact -- let Apple find related queries)

Keywords:
- "offline map"
- "hiking gps"
- "hunting app"
- "team gps"
- "ATAK"
- "walkie talkie"
- "offline navigation"
- "search and rescue"
- "backcountry gps"
- "topo map"

Max CPT bid: $0.75 (these are competitive terms -- keep bids low and let quality score work)

Why broad match: exact match on high-volume terms would burn budget fast. Broad match lets Apple serve the ad on related long-tail queries you haven't thought of, at lower cost.

### Campaign 2: Discovery — $5/day

- Search Match enabled (Apple auto-matches to searches based on your listing metadata)
- Max CPT bid: $0.50
- This is your intelligence-gathering campaign. The search terms report tells you what real people actually type.
- Weekly: move any term with 3+ installs to Campaign 1. Negative-match junk terms.

### Campaign 3: Competitor — $3/day (add after 2 weeks)

Only if Campaign 1/2 show any signal at all.
- Exact match on competitor names: "ATAK", "goTenna", "Garmin inReach", "onX hunt", "Gaia GPS"
- Max CPT bid: $1.00
- People searching for competitors are high-intent. Your listing's "ATAK alternative" positioning should convert.

### Total: $10-13/day (~$300-400/month)

Down from the original $450. No point spending more until there's signal.

### Decision Points

**After 2 weeks:** Check the search terms report from Discovery.
- Getting impressions but no taps? Your screenshots and subtitle aren't compelling enough for that search. Revisit listing.
- Getting taps but no installs? The product page isn't converting. Look at description, screenshots, ratings.
- Getting installs? Great. Increase budget on the winning terms.
- Getting nothing? Paid search may be the wrong channel entirely. Shift budget to Reddit Ads or content.

**After 30 days:** If CPI is above $3 and free-to-paid conversion is below 5%, pause paid search entirely and go all-in on organic/community channels.

---

## ORGANIC CHANNELS — THE REAL GROWTH ENGINE

These are likely to drive more installs than paid search for this category.

### Show HN (free, do now)

Post ready in `docs/hn-post-draft.md`. Best timing: Tuesday-Thursday, 9-11am ET. Engage every comment within minutes. Be technical, be honest about limitations (BLE range, iOS background restrictions).

### Reddit (free, do this week)

Target subreddits where people have the problem Red Grid Link solves:
- r/ATAK -- "lightweight alternative for iPhone"
- r/searchandrescue -- "field-tested offline team tracker"
- r/hunting -- "hunting party coordination" (seasonal, ramp up in fall)
- r/preppers -- "off-grid team coordination, no infrastructure"
- r/SideProject -- "I built an encrypted team tracker"
- r/FlutterDev -- "BLE proximity sync engine architecture"

Rules: 90% genuine participation, 10% self-promotion. Build karma first. Stagger posts -- max 2 subreddits per day. Reply to every comment within 4 hours.

### Demo Video (free, record this week)

60-second screen recording: open app, show map, start Field Link session, show teammate appear. Upload to YouTube. Embed on landing page. Link in Reddit posts.

This single video will do more for conversion than any ad copy. The marketing strategy doc says video converts 3x better than text -- and you don't have one yet.

### Dev.to Article (free, write week 2-3)

Title: something like "Building a distributed system on top of Bluetooth that drops every 30 seconds"

Focus on the technical challenges, not the product. HN and Dev.to audiences want to learn something, not be sold to. The product link goes at the bottom.

### Landing Page SEO (free, ongoing)

The landing page at redgridtactical.com should target these Google searches:
- "ATAK alternative iOS"
- "ATAK for iPhone"
- "offline team tracking app"
- "blue force tracking civilian"

These are long-tail queries with real intent and low competition. A well-structured page with an ATAK comparison table will rank within weeks.

---

## REDDIT ADS — PHASE 2 (ONLY IF ORGANIC REDDIT POSTS WORK)

Don't run Reddit Ads until you've posted organically in at least 3 target subreddits and seen which ones respond. Then target those specific subreddits with paid.

### Setup (when ready)

- Budget: $5-10/day
- Subreddits: only the ones where organic posts got engagement
- Format: image post (map screenshot with team dots visible)
- Copy: lead with the problem, not the product. "Your group splits up on the trail. Now what?"
- CTA: App Store link
- Run 14 days. Keep subreddits with CTR above 0.8%. Kill the rest.

---

## VIRAL MECHANICS — THE MULTIPLIER

Red Grid Link has a built-in viral loop that most apps don't: Field Link requires other people to install the app. Invest in features that make this easy:

1. **Share/invite flow from Field Link session.** When someone starts a session, prompt: "Your team needs Red Grid Link to join. Share the download link?" Generate a share sheet with App Store link. This is the highest-leverage feature you can build for growth.

2. **In-app review prompt.** Trigger after: 5+ opens, 1+ Field Link session completed, 7+ days since install. Ratings drive App Store conversion rate. You don't have many ratings yet -- this matters.

3. **Onboarding that shows value in 30 seconds.** First-time users should see a fake nearby peer on the map immediately, without any setup. Show them what Field Link looks like before they have to recruit a friend.

---

## UNIT ECONOMICS

| Metric | Conservative | Optimistic |
|--------|-------------|-----------|
| Pro+Link sub | $5.99/mo | $5.99/mo |
| Avg retention | 4 months | 8 months |
| LTV per paid user | $23.96 | $47.92 |
| Free-to-paid conversion | 3% | 8% |
| LTV per install | $0.72 | $3.83 |

Your CPI must stay below LTV per install. At 5% conversion and $24 LTV, that's $1.20 per install. If CPI is above that, you're losing money on every ad-driven install.

But organic installs have zero CPI. Every organic install is pure profit potential. That's why community and virality should be the primary channels, with paid search as a supplement.

---

## BUDGET SUMMARY

| Channel | Monthly Cost | When |
|---------|-------------|------|
| Show HN + Reddit posts | $0 | Now |
| Demo video + Dev.to | $0 | This week / next week |
| Apple Search Ads (restructured) | $300-400/mo | Now (revised keywords) |
| Reddit Ads | $150-300/mo | Month 2 (only if organic posts work) |
| Scale paid | $500-800/mo | Month 3+ (only if ROAS > 1.5x) |

If paid search still produces nothing after 30 days with the new keywords, kill it entirely and put that $300/month toward micro-influencer outreach or SAR team partnership instead.

---

## WEEKLY CHECKLIST (15 MINUTES)

- [ ] Check ASA search terms report -- move winners, negative-match junk
- [ ] Pause any keyword with 50+ impressions and zero taps (listing doesn't match intent)
- [ ] Pause any keyword with 20+ taps and zero installs (product page not converting)
- [ ] Check App Store Connect analytics for organic vs paid install ratio
- [ ] Reply to any Reddit/HN comments from the past week
- [ ] Calculate CPI and compare to LTV
