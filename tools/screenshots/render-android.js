#!/usr/bin/env node
/**
 * Renders Android Play Store screenshots from real emulator captures.
 *
 * Three independent pipelines — no scaling between sizes.  Each size
 * starts from raw screenshots captured at that viewport and is composited
 * at native resolution via Puppeteer, so the phone mockup is a real phone
 * mockup, the 7" tablet mockup is a real 7" tablet mockup, and so on.
 *
 *   phone:   composite-android.html          → screenshots/android/phone/    1290×2796
 *   tablet7: composite-android-tablet7.html  → screenshots/android/tablet7/  1080×1920
 *   tablet10: composite-android-tablet10.html → screenshots/android/tablet10/ 1600×2560
 *
 * Usage:
 *   node tools/screenshots/render-android.js
 *
 * Prerequisites:
 *   - Raw phone screenshots in  screenshots/raw_android/phone/    (1080×2400 viewport)
 *   - Raw tablet7 screenshots in screenshots/raw_android/tablet7/ (1200×1920 viewport)
 *   - Raw tablet10 screenshots in screenshots/raw_android/tablet10/ (1600×2560 viewport)
 *   - Google Chrome installed at /Applications/Google Chrome.app
 *   - puppeteer: npm install  (in tools/screenshots/)
 */

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const PROJECT_ROOT = path.join(__dirname, '..', '..');

const FILES = [
  '01_map_team',
  '02_grid_mgrs',
  '03_field_link',
  '04_tools',
  '05_themes',
  '06_peer_popup',
  '07_dead_reckoning',
  '08_celestial',
  '09_search_area',
  '10_roster',
];

/**
 * Size-specific compositing pipeline.  Each entry is one pipeline.
 */
const PIPELINES = [
  {
    name: 'phone',
    htmlFile: 'composite-android.html',
    rawDir: path.join(PROJECT_ROOT, 'screenshots', 'raw_android', 'phone'),
    outDir: path.join(PROJECT_ROOT, 'screenshots', 'android', 'phone'),
    frameWidth: 1290,
    frameHeight: 2796,
  },
  {
    name: 'tablet7',
    htmlFile: 'composite-android-tablet7.html',
    rawDir: path.join(PROJECT_ROOT, 'screenshots', 'raw_android', 'tablet7'),
    outDir: path.join(PROJECT_ROOT, 'screenshots', 'android', 'tablet7'),
    frameWidth: 1080,
    frameHeight: 1920,
  },
  {
    name: 'tablet10',
    htmlFile: 'composite-android-tablet10.html',
    rawDir: path.join(PROJECT_ROOT, 'screenshots', 'raw_android', 'tablet10'),
    outDir: path.join(PROJECT_ROOT, 'screenshots', 'android', 'tablet10'),
    frameWidth: 1600,
    frameHeight: 2560,
  },
];

// ── Preflight check ────────────────────────────────────────────────────────

for (const p of PIPELINES) {
  const missing = FILES.filter(
    (f) => !fs.existsSync(path.join(p.rawDir, `${f}.png`)),
  );
  if (missing.length > 0) {
    console.error(`ERROR: Missing raw ${p.name} screenshots:`);
    missing.forEach((f) => console.error(`  ${p.rawDir}/${f}.png`));
    console.error(
      `\nCapture them with DEVICE_TARGET=raw_android/${p.name} flutter drive …`,
    );
    process.exit(1);
  }
  fs.mkdirSync(p.outDir, { recursive: true });
}

// ── Main ──────────────────────────────────────────────────────────────────

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    executablePath:
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  for (const p of PIPELINES) {
    console.log(`\nCompositing ${p.name} (${p.frameWidth}×${p.frameHeight})…\n`);

    const page = await browser.newPage();
    // Viewport wide enough to hold all 10 frames side by side;
    // height matches each frame (plus body padding).
    await page.setViewport({
      width: p.frameWidth * FILES.length + 1000, // generous margin for gaps
      height: p.frameHeight + 200,
      deviceScaleFactor: 1,
    });

    const htmlPath = path.join(__dirname, p.htmlFile);
    await page.goto(`file://${htmlPath}`, {
      waitUntil: 'networkidle0',
      timeout: 30000,
    });

    // Wait for all embedded screenshot images to finish loading.
    await page
      .waitForFunction(
        () => {
          const imgs = document.querySelectorAll('.phone img, .tablet img');
          return Array.from(imgs).every(
            (img) => img.complete && img.naturalHeight > 0,
          );
        },
        { timeout: 15000 },
      )
      .catch(() => {
        console.warn(
          `  Warning: some images in ${p.htmlFile} may not have loaded within timeout`,
        );
      });

    const frames = await page.$$('.frame');
    if (frames.length !== FILES.length) {
      console.warn(
        `  Warning: ${p.htmlFile} has ${frames.length} frames but expected ${FILES.length}`,
      );
    }

    for (let i = 0; i < frames.length; i++) {
      const name = FILES[i] ?? `frame_${i + 1}`;
      const outPath = path.join(p.outDir, `${name}.png`);
      await frames[i].screenshot({ path: outPath, omitBackground: false });
      console.log(`  ✓ ${p.name}/${name}.png`);
    }

    await page.close();
  }

  await browser.close();

  // ── Summary ──────────────────────────────────────────────────────────────

  console.log(
    `\nDone — ${FILES.length} screenshots × ${PIPELINES.length} sizes = ${FILES.length * PIPELINES.length} files.\n`,
  );
  for (const p of PIPELINES) {
    console.log(
      `  ${p.name.padEnd(8)} (${p.frameWidth}×${p.frameHeight}):  ${p.outDir}`,
    );
  }
})();
