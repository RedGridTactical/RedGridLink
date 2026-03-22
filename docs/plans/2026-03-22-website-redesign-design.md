# Red Grid Tactical Website Redesign

## Overview

Full redesign of redgridtactical.com from a single-page Red Grid Link landing page to a multi-page Red Grid Tactical company site with product pages for both apps, interactive roadmap, about page, and feedback form.

## Site Structure

```
docs/
├── index.html          Home — Red Grid Tactical ecosystem overview
├── link.html           Red Grid Link product page
├── mgrs.html           Red Grid MGRS product page
├── roadmap.html         Interactive roadmap (both apps)
├── about.html           Story, mission, open source
├── styles.css           Shared design system
├── script.js            Navigation, animations, form handling
├── privacy.html         Privacy policy (restyled)
├── terms.html           Terms of use (restyled)
├── sitemap.xml          SEO sitemap
├── robots.txt           Crawler config
└── images/              Screenshots, icons, assets
```

## Navigation

Hamburger menu (top left) on all pages. Expands to slide-out on mobile, horizontal bar on desktop.

```
[☰] Red Grid Tactical
├── Home
├── Our Apps ▸
│   ├── Red Grid Link
│   └── Red Grid MGRS
├── Roadmap
├── About
├── GitHub
└── Download
```

## Design System

### Typography
- Body: Inter (Google Fonts), 16px base, fluid sizing with clamp()
- Monospace accent: JetBrains Mono for MGRS coordinates and tech specs
- Headings: Inter, weight 700-800, letter-spacing -0.5px

### Color Palette (Full Dark Theme)
- --bg-primary: #0a0a0a
- --bg-secondary: #111111
- --bg-tertiary: #1a1a1a
- --accent: #cc3333
- --accent-glow: #ff4444
- --text-primary: #f0f0f0
- --text-secondary: #999999
- --border: #2a2a2a
- --success: #2e7d32

### Spacing
- 8px grid system
- Container max-width: 1200px
- Section padding: 80px vertical

### Components
- Cards: bg-secondary with 1px border, 12px radius, hover lift
- Buttons: Rounded, accent background, white text, hover glow
- Badges: Small pill-shaped indicators

## Pages

### index.html (Home)
1. Sticky nav bar with hamburger (left), logo (center-left), CTA (right)
2. Hero: "Offline-First Tactical Navigation" tagline, ecosystem pitch, two app CTAs
3. Social proof strip: HN points, GitHub stars, test count, open source badge
4. Ecosystem cards: Link (team) + MGRS (solo) side by side with feature highlights
5. Use cases: SAR, Hunting, Backcountry, Training (4 cards)
6. Technology overview: Field Link, Encryption, MGRS Engine, Offline Maps (expandable)
7. Privacy strip: Zero footprint messaging
8. Feedback form: Formspree, fields: Name, Email, Category, Message (web form only)
9. Footer: Links, ecosystem, copyright

### link.html (Red Grid Link)
- Hero with app icon, name, tagline
- Screenshot carousel
- Features grid (6 cards, expanded descriptions)
- Comparison table (vs ATAK, goTenna, Garmin, Meshtastic, Bridgefy)
- Pricing cards (Free, Pro, Pro+Link, Lifetime)
- FAQ accordion
- Download CTAs (App Store + Play Store Beta)

### mgrs.html (Red Grid MGRS)
- Hero with MGRS app icon, name, tagline
- Screenshot carousel (from MGRS store assets)
- DAGR comparison section ($2,500 military device vs free app)
- Features: 9 tools, 6 report templates, NATO voice, photo geostamp
- 4 themes showcase
- Download CTA (App Store)

### roadmap.html
- Tab toggle: Red Grid Link | Red Grid MGRS
- Timeline visualization
- Versions color-coded: green (shipped), yellow (in progress), gray (planned)
- Each version expandable with feature list
- Version dates and status badges

### about.html
- Story section: Built by active duty Army officer, problem observed in field
- Mission: Bridge the gap between military tools and civilian team needs
- Open source philosophy: Why the code is public
- Tech stack brief: Flutter, BLE, CRDT, AES-256-GCM
- No personal identifying details

## SEO Strategy

### On-Page
- Unique meta description per page
- JSON-LD: Organization, MobileApplication, FAQPage, BreadcrumbList
- Canonical URLs on every page
- Image alt text with keywords
- Semantic HTML5 (header, nav, main, section, article, footer)

### Technical
- Page load under 1s (no framework, minimal JS)
- Mobile-first responsive
- Core Web Vitals optimized (fixed image dimensions, fast LCP)
- sitemap.xml with all pages
- robots.txt allowing full crawl

### Content Keywords
- "offline team tracking app"
- "bluetooth gps tracker no cell service"
- "ATAK alternative iOS"
- "MGRS navigation app"
- "encrypted team coordination"
- "offline map hiking hunting"

## Feedback Form

Formspree endpoint (free tier, 50 submissions/month):
- Fields: Name (required), Email (required), Category dropdown (Bug Report, Feature Request, Partnership, General), Message textarea (required)
- Submissions forwarded to redgridtactical@gmail.com
- Client-side validation + success/error states
- Web form only, no email links in contact section
