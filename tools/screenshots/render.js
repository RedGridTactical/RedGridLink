#!/usr/bin/env node
/**
 * Renders each .frame from composite.html as a separate PNG at exactly
 * 1290x2796 (iPhone 6.9-inch / 6.7-inch App Store requirement) for every
 * locale defined in i18n.json.
 *
 * Localization:
 *   Headlines + subtitles are pulled from i18n.json (one entry per
 *   {locale, frame} pair). The default English text in composite.html is
 *   replaced via DOM injection before each frame is rendered. Frames are
 *   rendered one locale at a time so the same browser page can be reused.
 *
 * Output layout:
 *   screenshots/framed/<locale>/<frame>.png
 *
 * Usage:
 *   node tools/screenshots/render.js                  # all locales
 *   LOCALES=en-US,de-DE node tools/screenshots/render.js  # subset
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

const I18N = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'i18n.json'), 'utf8'),
);
const ALL_LOCALES = Object.keys(I18N).filter((k) => !k.startsWith('_'));
const LOCALES_ENV = (process.env.LOCALES || '').split(',').filter(Boolean);
const TARGET_LOCALES = LOCALES_ENV.length ? LOCALES_ENV : ALL_LOCALES;

(async () => {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const browser = await puppeteer.launch({
    headless: true,
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();
  await page.setViewport({
    width: 14000,
    height: FRAME_HEIGHT + 200,
    deviceScaleFactor: 1,
  });

  const htmlPath = path.join(__dirname, 'composite.html');
  await page.goto(`file://${htmlPath}`, {
    waitUntil: 'networkidle0',
    timeout: 30000,
  });

  // Wait for raw screenshot images to load before any frame is captured.
  await page
    .waitForFunction(
      () => {
        const imgs = document.querySelectorAll('.phone img');
        return Array.from(imgs).every(
          (img) => img.complete && img.naturalHeight > 0,
        );
      },
      { timeout: 15000 },
    )
    .catch(() => console.warn('Warning: some images may not have loaded'));

  console.log(
    `Rendering ${TARGET_LOCALES.length} locale(s) × ${CAPTIONS.length} frames`,
  );
  console.log(`  locales: ${TARGET_LOCALES.join(', ')}\n`);

  for (const locale of TARGET_LOCALES) {
    const dict = I18N[locale];
    if (!dict) {
      console.warn(`  skip ${locale} (no entry in i18n.json)`);
      continue;
    }

    // Replace headline / subtitle text on every frame for this locale.
    // The DOM is mutated in place so the next frame.screenshot() call sees
    // the localized copy.
    await page.evaluate(
      ({ dict, captions }) => {
        const frames = document.querySelectorAll('.frame');
        frames.forEach((frame, i) => {
          const key = captions[i];
          const entry = dict[key];
          if (!entry) return;
          const h = frame.querySelector('.headline');
          const s = frame.querySelector('.subtitle');
          if (h && entry.headline) h.textContent = entry.headline;
          if (s && entry.subtitle) s.textContent = entry.subtitle;
        });
      },
      { dict, captions: CAPTIONS },
    );

    const localeDir = path.join(OUTPUT_DIR, locale);
    fs.mkdirSync(localeDir, { recursive: true });

    const frames = await page.$$('.frame');
    process.stdout.write(`  ${locale}: `);
    for (let i = 0; i < frames.length; i++) {
      const filename = `${CAPTIONS[i] || `frame_${i + 1}`}.png`;
      const outPath = path.join(localeDir, filename);
      await frames[i].screenshot({ path: outPath, omitBackground: false });
      process.stdout.write('.');
    }
    process.stdout.write(' ✓\n');
  }

  await browser.close();

  // Summary.
  const localeCount = TARGET_LOCALES.length;
  let totalFiles = 0;
  for (const loc of TARGET_LOCALES) {
    const dir = path.join(OUTPUT_DIR, loc);
    if (fs.existsSync(dir)) {
      totalFiles += fs.readdirSync(dir).filter((f) => f.endsWith('.png')).length;
    }
  }
  console.log(
    `\nRendered ${totalFiles} screenshots across ${localeCount} locale(s) to ${OUTPUT_DIR}/<locale>/`,
  );
})();
