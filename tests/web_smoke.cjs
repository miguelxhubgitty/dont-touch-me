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
    // Measure what actually reaches the speakers: every connection to an AudioContext's
    // destination is routed through a transparent sink that is metered, so a bus graph
    // with no path to the destination reads silent (plans/web-audio-bus-order.md).
    await page.addInitScript(() => {
      const connect = AudioNode.prototype.connect;
      const disconnect = AudioNode.prototype.disconnect;
      const sinkFor = context => {
        if (context.__smokeSink) return context.__smokeSink;
        const sink = context.createGain();
        const meter = context.createScriptProcessor(2048, 2, 2);
        const silent = context.createGain();
        silent.gain.value = 0;
        meter.onaudioprocess = event => {
          for (let ch = 0; ch < event.inputBuffer.numberOfChannels; ch++) {
            for (const v of event.inputBuffer.getChannelData(ch)) window.__smokePeak = Math.max(window.__smokePeak, Math.abs(v));
          }
        };
        connect.call(sink, context.destination);
        connect.call(sink, meter);
        connect.call(meter, silent);
        connect.call(silent, context.destination);
        return (context.__smokeSink = sink);
      };
      window.__smokePeak = 0;
      AudioNode.prototype.connect = function (target, ...rest) {
        return connect.call(this, target instanceof AudioDestinationNode ? sinkFor(target.context) : target, ...rest);
      };
      AudioNode.prototype.disconnect = function (target, ...rest) {
        if (target instanceof AudioDestinationNode) target = sinkFor(target.context);
        return target === undefined ? disconnect.call(this) : disconnect.call(this, target, ...rest);
      };
    });
    const response = await page.goto(url, { waitUntil: 'networkidle', timeout: 90000 });
    assert.equal(response.status(), 200);
    await page.waitForFunction(() => {
      const status = document.getElementById('status');
      const canvas = document.getElementById('canvas');
      // Godot 4.7 removes the loading overlay; earlier shells hid it.
      return canvas && canvas.width > 0 && (!status || getComputedStyle(status).visibility === 'hidden');
    }, null, { timeout: 90000 });
    await page.waitForTimeout(700);
    const canvas = page.locator('#canvas');
    const first = await canvas.screenshot({ path: path.join(output, 'web-desktop.png') });
    assert(first.length > 5000, 'Game canvas must contain rendered graphics');
    await canvas.click({ position: { x: 216, y: 398 } });
    await page.waitForTimeout(350);
    const after = await canvas.screenshot();
    assert(!first.equals(after), 'Rendered game responds/advances after input');
    // Audio: off by default, audible after Sound On, silent again when muted.
    // HUD Sound button: (619, 60) in the 720x1280 base layout, scaled to this viewport.
    const viewport = page.viewportSize();
    const soundButton = { x: 619 * viewport.width / 720, y: 60 * viewport.height / 1280 };
    const peakAfterPokes = async count => {
      await page.evaluate(() => { window.__smokePeak = 0; });
      for (let i = 0; i < count; i++) { await canvas.click({ position: { x: 216, y: 398 } }); await page.waitForTimeout(1200); }
      return page.evaluate(() => window.__smokePeak);
    };
    const audio = { soundOff: await peakAfterPokes(1) };
    await canvas.click({ position: soundButton });
    await page.waitForTimeout(400);
    audio.soundOn = await peakAfterPokes(3);
    await canvas.click({ position: soundButton });
    await page.waitForTimeout(400);
    audio.mutedAgain = await peakAfterPokes(2);
    assert.equal(audio.soundOff, 0, 'Sound is silent before it is turned on');
    assert(audio.soundOn > 0.01, `Sound reaches the speakers after Sound On (peak ${audio.soundOn})`);
    assert.equal(audio.mutedAgain, 0, 'Sound is silent again after muting');
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
      passed: true, browser: browser.version(), desktop: '432x768', mobile: '390x844', audio,
      checks: ['HTTP files', 'WebAssembly/WebGL startup', 'rendered canvas', 'click/animation',
        'audio silent by default, audible after Sound On, silent when muted', 'resize', 'touch dispatch', 'no runtime errors'],
      limits: 'Automated desktop browser with software WebGL; not physical-device performance certification.'
    }, null, 2));
    console.log(`Web runtime smoke passed: desktop click, audio (peak ${audio.soundOn.toFixed(3)}), mobile-sized touch/resize, no errors.`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
