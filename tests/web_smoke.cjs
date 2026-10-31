// Optional automated runtime check. Uses installed tools; never installs dependencies.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');

(async () => {
  const [url, output] = process.argv.slice(2);
  assert(url.startsWith('http://127.0.0.1:'), 'Only local release testing is allowed');
  const candidates = [process.env.BROWSER_EXECUTABLE,
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Google/Chrome/Application/chrome.exe', chromium.executablePath()].filter(Boolean);
  const executablePath = candidates.find(p => fs.existsSync(p));
  assert(executablePath, 'Install/configure a supported browser before runtime validation');
  const browser = await chromium.launch({ executablePath, headless: true,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--enable-webgl'] });
  try {
    const context = await browser.newContext({ viewport: { width: 432, height: 768 }, hasTouch: true });
    const page = await context.newPage();
    const errors = [];
    const failedRequests = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('requestfailed', request => failedRequests.push(request.url()));
    const response = await page.goto(url, { waitUntil: 'networkidle', timeout: 90000 });
    assert.equal(response.status(), 200);
    await page.waitForFunction(() => {
      const status = document.getElementById('status');
      const canvas = document.getElementById('canvas');
      return canvas && canvas.width > 0 && status && getComputedStyle(status).visibility === 'hidden';
    }, null, { timeout: 90000 });
    await page.waitForTimeout(700);
    const canvas = page.locator('#canvas');
    const first = await canvas.screenshot({ path: path.join(output, 'web-desktop.png') });
    assert(first.length > 5000, 'Game canvas must contain rendered graphics');
    await canvas.click({ position: { x: 216, y: 398 } });
    await page.waitForTimeout(350);
    const after = await canvas.screenshot();
    assert(!first.equals(after), 'Rendered game responds/advances after input');
    await page.setViewportSize({ width: 390, height: 844 });
    await page.waitForTimeout(350);
    const box = await canvas.boundingBox();
    assert(box && box.width <= 390 && box.height <= 844, 'Canvas fits mobile viewport');
    await page.touchscreen.tap(box.x + box.width / 2, box.y + box.height * .52);
    await page.waitForTimeout(250);
    await canvas.screenshot({ path: path.join(output, 'web-mobile.png') });
    assert.deepEqual(errors, [], 'No browser/runtime console errors');
    assert.deepEqual(failedRequests, [], 'No failed resource requests');
    fs.writeFileSync(path.join(output, 'web-smoke.json'), JSON.stringify({
      passed: true, browser: browser.version(), desktop: '432x768', mobile: '390x844',
      checks: ['HTTP files', 'WebAssembly/WebGL startup', 'rendered canvas', 'click/animation', 'resize', 'touch dispatch', 'no runtime errors'],
      limits: 'Automated desktop browser with software WebGL; not physical-device performance certification.'
    }, null, 2));
    console.log('Web runtime smoke passed: desktop click, mobile-sized touch/resize, no errors.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
