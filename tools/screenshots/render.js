#!/usr/bin/env node
/**
 * Renders each .frame from composite.html as a separate PNG
 * at exactly 1290x2796 (iPhone 6.7" / 6.9" App Store requirement).
 *
 * Adapted from the Just Start screenshot pipeline.
 *
 * Usage:
 *   node tools/screenshots/render.js
 *
 * Prerequisites:
 *   - Raw screenshots in screenshots/raw/ (from demo mode or device capture)
 *   - Google Chrome installed at /Applications/Google Chrome.app
 *   - puppeteer: npm install puppeteer (in tools/screenshots/)
 *
 * Output: screenshots/framed/*.png
 */
const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const FRAME_WIDTH = 1290;
const FRAME_HEIGHT = 2796;
const OUTPUT_DIR = path.join(__dirname, '..', '..', 'screenshots', 'framed');

const CAPTIONS = [
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

(async () => {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const browser = await puppeteer.launch({
    headless: true,
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 14000, height: FRAME_HEIGHT + 200, deviceScaleFactor: 1 });

  const htmlPath = path.join(__dirname, 'composite.html');
  await page.goto(`file://${htmlPath}`, { waitUntil: 'networkidle0', timeout: 30000 });

  // Wait for images to load
  await page.waitForFunction(() => {
    const imgs = document.querySelectorAll('.phone img');
    return Array.from(imgs).every(img => img.complete && img.naturalHeight > 0);
  }, { timeout: 15000 }).catch(() => {
    console.warn('Warning: some images may not have loaded');
  });

  const frames = await page.$$('.frame');
  console.log(`Found ${frames.length} frames`);

  for (let i = 0; i < frames.length; i++) {
    const filename = `${CAPTIONS[i] || `frame_${i + 1}`}.png`;
    const outPath = path.join(OUTPUT_DIR, filename);

    await frames[i].screenshot({
      path: outPath,
      omitBackground: false,
    });

    console.log(`  ✓ ${filename}`);
  }

  await browser.close();

  const files = fs.readdirSync(OUTPUT_DIR).filter(f => f.endsWith('.png'));
  console.log(`\nRendered ${files.length} screenshots to ${OUTPUT_DIR}`);
  files.forEach(f => {
    const stat = fs.statSync(path.join(OUTPUT_DIR, f));
    console.log(`  ${f} (${(stat.size / 1024).toFixed(0)} KB)`);
  });
})();
