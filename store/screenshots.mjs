// Phone screenshots for the Play Store listing, taken from the web build.
// Run by .github/workflows/store-screenshots.yml: node store/screenshots.mjs <base url> <out dir>
import { chromium } from 'playwright';
import fs from 'node:fs';

const [base, out] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const cfg = JSON.parse(fs.readFileSync('config/data_api.json', 'utf8'));

async function areaId(name, parent) {
  const url = `${cfg.data_api_url}/api_rate?select=geo_area_id,parent_name&area_name=eq.${encodeURIComponent(name)}`;
  const rows = await (await fetch(url, { headers: { Authorization: `Bearer ${cfg.app_token}` } })).json();
  const row = rows.find((r) => !parent || r.parent_name === parent) ?? rows[0];
  if (!row) throw new Error(`no area ${name}`);
  return row.geo_area_id;
}

const whitefield = await areaId('Whitefield', 'Mahadevapura');
const jayanagar = await areaId('Jayanagar 4th Block', 'Jayanagar');
const thanisandra = await areaId('Thanisandra', 'Banaswadi');
console.log({ whitefield, jayanagar, thanisandra });

// 400×800 at 2.7× = 1080×2160, within Play's 2:1 limit
const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });

async function shot(name, { url = base, prefs = {}, steps = async () => {}, wait = 9000 } = {}) {
  const ctx = await browser.newContext({ viewport: { width: 400, height: 800 }, deviceScaleFactor: 2.7, isMobile: true, hasTouch: true });
  await ctx.addInitScript((p) => {
    for (const [k, v] of Object.entries(p)) localStorage.setItem(`flutter.${k}`, JSON.stringify(v));
  }, prefs);
  const page = await ctx.newPage();
  page.on('console', (m) => { if (m.type() === 'error') console.log(`[${name}] ${m.text()}`); });
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.waitForTimeout(wait);
  await steps(page);
  await page.screenshot({ path: `${out}/${name}.png` });
  console.log(`saved ${name}`);
  await ctx.close();
}

const tap = async (page, x, y, after = 2500) => {
  await page.touchscreen.tap(x, y);
  await page.waitForTimeout(after);
};
const scroll = async (page, dy, after = 1500) => {
  await page.mouse.move(200, 600);
  await page.mouse.wheel(0, dy);
  await page.waitForTimeout(after);
};
const saved = { saved_places: [`${whitefield}`, `${jayanagar}`, `${thanisandra}`] };

const search = (q) => async (page) => {
  await tap(page, 200, 115, 1000);
  await page.keyboard.type(q, { delay: 60 });
  await page.waitForTimeout(4000);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(800);
};
await shot('1-list', { steps: search('Jayanagar') });
await shot('2-place', { url: `${base}?area=${whitefield}`, steps: (p) => scroll(p, 120) });
await shot('3-place-more', { url: `${base}?area=${whitefield}`, steps: (p) => scroll(p, 900) });
await shot('5-saved', { prefs: saved, steps: (p) => tap(p, 333, 770, 5000) });
await shot('6-kannada', { prefs: { language: 'kn' }, steps: search('Whitefield') });
await shot('7-kannada-place', { url: `${base}?area=${jayanagar}`, prefs: { language: 'kn' }, steps: (p) => scroll(p, 120) });

// Play icon (512, square: Play rounds the corners itself) and feature graphic (1024×500)
const svg = fs.readFileSync('brand/nelabele-app-icon.svg', 'utf8').replace('rx="112" ', '');
const art = await browser.newPage({ viewport: { width: 512, height: 512 } });
await art.setContent(`<style>body{margin:0}svg{width:512px;height:512px;display:block}</style>${svg}`);
await art.screenshot({ path: `${out}/icon-512.png` });
await art.setViewportSize({ width: 1024, height: 500 });
await art.setContent(`<style>
  body { margin: 0; width: 1024px; height: 500px; background: #FBF6EE; display: flex; align-items: center;
         font-family: 'Noto Sans', 'Noto Sans Kannada', sans-serif; color: #2A2420; }
  .logo svg { width: 300px; height: 300px; margin: 0 56px 0 88px; display: block; }
  h1 { font-size: 84px; margin: 0; font-weight: 700; letter-spacing: -1px; }
  h1 span { color: #A64B24; }
  .kn { font-size: 40px; color: #A64B24; margin: 4px 0 18px; }
  p { font-size: 30px; margin: 0; color: #6B5E52; max-width: 520px; line-height: 1.3; }
</style>
<div class="logo">${fs.readFileSync('brand/nelabele-app-icon.svg', 'utf8')}</div>
<div><h1>Nela<span>Bele</span></h1><div class="kn">ನೆಲ ಬೆಲೆ</div>
<p>Land and home rates around Bengaluru, with guidance values</p></div>`);
await art.waitForTimeout(500);
await art.screenshot({ path: `${out}/feature-graphic.png` });
await browser.close();
