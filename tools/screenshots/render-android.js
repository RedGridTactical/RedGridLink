#!/usr/bin/env node
/**
 * Renders Android screenshots for Play Store:
 * - Phone: 1290x2796 (same as iPhone 6.7" composites — reuse iOS output)
 * - 7-inch tablet: 1080x1920 (resized from phone)
 * - 10-inch tablet: 1600x2560 (resized from phone)
 *
 * Uses the same composite.html as iOS (phone mockups are identical).
 * Tablet versions are resized from the phone composites.
 *
 * Usage: node tools/screenshots/render-android.js
 */
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const PROJECT_ROOT = path.join(__dirname, '..', '..');
const FRAMED_DIR = path.join(PROJECT_ROOT, 'screenshots', 'framed');
const ANDROID_PHONE = path.join(PROJECT_ROOT, 'screenshots', 'android', 'phone');
const ANDROID_TAB7 = path.join(PROJECT_ROOT, 'screenshots', 'android', 'tablet7');
const ANDROID_TAB10 = path.join(PROJECT_ROOT, 'screenshots', 'android', 'tablet10');

const FILES = [
  '01_map_team.png',
  '02_grid_mgrs.png',
  '03_field_link.png',
  '04_tools.png',
  '05_themes.png',
  '06_peer_popup.png',
  '07_dead_reckoning.png',
  '08_celestial.png',
];

[ANDROID_PHONE, ANDROID_TAB7, ANDROID_TAB10].forEach(d => fs.mkdirSync(d, { recursive: true }));

console.log('Creating Android screenshots from iOS composites...\n');

for (const f of FILES) {
  const src = path.join(FRAMED_DIR, f);
  if (!fs.existsSync(src)) {
    console.log(`  ✗ ${f} — missing from framed/`);
    continue;
  }

  // Phone: copy as-is (1290x2796 works for Play Store phone)
  fs.copyFileSync(src, path.join(ANDROID_PHONE, f));
  console.log(`  ✓ phone/${f}`);

  // 7" tablet: resize to 1080x1920
  try {
    execSync(`sips -z 1920 1080 "${src}" --out "${path.join(ANDROID_TAB7, f)}" 2>/dev/null`);
    console.log(`  ✓ tablet7/${f}`);
  } catch (e) {
    // sips might not handle aspect ratio well, try with padding
    execSync(`sips -Z 1920 "${src}" --out "${path.join(ANDROID_TAB7, f)}" 2>/dev/null`);
    console.log(`  ✓ tablet7/${f} (resized)`);
  }

  // 10" tablet: resize to 1600x2560
  try {
    execSync(`sips -z 2560 1600 "${src}" --out "${path.join(ANDROID_TAB10, f)}" 2>/dev/null`);
    console.log(`  ✓ tablet10/${f}`);
  } catch (e) {
    execSync(`sips -Z 2560 "${src}" --out "${path.join(ANDROID_TAB10, f)}" 2>/dev/null`);
    console.log(`  ✓ tablet10/${f} (resized)`);
  }
}

console.log(`\nDone. Created ${FILES.length} screenshots x 3 sizes = ${FILES.length * 3} files.`);
console.log(`  Phone:    ${ANDROID_PHONE}`);
console.log(`  7" Tab:   ${ANDROID_TAB7}`);
console.log(`  10" Tab:  ${ANDROID_TAB10}`);
