const fs = require('node:fs');
const path = require('node:path');

const { expect, test } = require('@playwright/test');
const { PNG } = require('pngjs');

const baseUrl = process.env.MIND_AGORA_URL || 'http://127.0.0.1:39865';
const screenshotDir = path.join(__dirname, '..', 'test-results', 'web-smoke');

test.setTimeout(90000);

function installRuntimeGuards(page) {
  const failures = [];

  page.on('pageerror', (error) => {
    failures.push(`pageerror: ${error.message}`);
  });

  page.on('console', (message) => {
    if (message.type() !== 'error') return;
    failures.push(`console error: ${message.text()}`);
  });

  page.on('response', (response) => {
    const url = response.url();
    if (!url.startsWith(baseUrl)) return;
    if (response.status() >= 400) {
      failures.push(`HTTP ${response.status()}: ${url}`);
    }
  });

  return failures;
}

async function waitForFlutter(page) {
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForSelector('flutter-view flt-glass-pane', {
    state: 'attached',
    timeout: 60000,
  });
  await page.waitForFunction(() => {
    const view = document.querySelector('flutter-view');
    if (!view) return false;
    const rect = view.getBoundingClientRect();
    return rect.width > 100 && rect.height > 100;
  }, { timeout: 60000 });
  await page.waitForTimeout(2500);
}

async function expectPainted(page, name) {
  fs.mkdirSync(screenshotDir, { recursive: true });
  const filePath = path.join(screenshotDir, `${name}.png`);
  const buffer = await page.screenshot({ path: filePath, fullPage: true });
  const image = PNG.sync.read(buffer);

  let sampled = 0;
  let varied = 0;
  const colors = new Set();
  for (let y = 0; y < image.height; y += 8) {
    for (let x = 0; x < image.width; x += 8) {
      const offset = (image.width * y + x) * 4;
      const r = image.data[offset];
      const g = image.data[offset + 1];
      const b = image.data[offset + 2];
      const a = image.data[offset + 3];
      if (a === 0) continue;
      sampled += 1;
      colors.add(`${r >> 4},${g >> 4},${b >> 4}`);
      if (Math.max(r, g, b) - Math.min(r, g, b) > 8 || r < 245 || g < 245 || b < 245) {
        varied += 1;
      }
    }
  }

  expect(sampled, `${name} screenshot should contain pixels`).toBeGreaterThan(1000);
  expect(colors.size, `${name} screenshot should not be blank`).toBeGreaterThan(12);
  expect(varied / sampled, `${name} screenshot should contain rendered UI`).toBeGreaterThan(0.08);
}

function expectNoRuntimeFailures(failures) {
  const actionable = failures.filter((failure) => {
    return !failure.includes('favicon.ico');
  });
  expect(actionable).toEqual([]);
}

test('desktop app opens and reaches live room without runtime errors', async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  const failures = installRuntimeGuards(page);

  await waitForFlutter(page);
  await expect(page).toHaveTitle(/Mind Agora/);
  await expectPainted(page, 'desktop-home');

  await page.mouse.click(104, 198);
  await page.waitForTimeout(1400);
  await expectPainted(page, 'desktop-think-room-planner');

  await page.mouse.click(925, 568);
  await page.waitForTimeout(3000);
  await expectPainted(page, 'desktop-live-room');

  expectNoRuntimeFailures(failures);
});

test('mobile app opens without runtime errors', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const failures = installRuntimeGuards(page);

  await waitForFlutter(page);
  await expect(page).toHaveTitle(/Mind Agora/);
  await expectPainted(page, 'mobile-home');

  await page.mouse.click(195, 808);
  await page.waitForTimeout(1400);
  await expectPainted(page, 'mobile-think-room-planner');

  expectNoRuntimeFailures(failures);
});
