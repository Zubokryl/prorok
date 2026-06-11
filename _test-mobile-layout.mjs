import { chromium } from 'playwright';

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 375, height: 667 } });
await page.goto('http://127.0.0.1:8765/index.html', { waitUntil: 'networkidle' });
await page.waitForTimeout(500);

const info = await page.evaluate(() => {
  const sections = ['.hero', '.symbols', '.glass-wrap', '.landing-bot-box'];
  const heights = {};
  for (const sel of sections) {
    const el = document.querySelector(sel);
    heights[sel] = el ? Math.round(el.getBoundingClientRect().height) : 0;
  }
  return {
    docH: document.documentElement.scrollHeight,
    bodyH: document.body.scrollHeight,
    sceneH: document.querySelector('.scene')?.scrollHeight,
    sceneClient: document.querySelector('.scene')?.clientHeight,
    windowH: window.innerHeight,
    heights,
    bookTop: Math.round(document.querySelector('.landing-bot-avatar')?.getBoundingClientRect().top ?? 0),
  };
});
console.log(JSON.stringify(info, null, 2));
await browser.close();
