// Screenshots an SVG to PNG with the mockup tool's playwright: node tools/preview/snap.mjs in.svg out.png
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";
const [, , input, output] = process.argv;
const root = process.env.PLAYWRIGHT_BROWSERS_PATH || "/opt/pw-browsers";
let exe = process.env.CHROMIUM_PATH;
if (!exe && fs.existsSync(root)) {
	for (const d of fs.readdirSync(root).filter((d) => d.startsWith("chromium_headless_shell"))) {
		const p = path.join(root, d, "chrome-linux", "headless_shell");
		if (fs.existsSync(p)) exe = p;
	}
}
const svg = fs.readFileSync(input, "utf8");
const [, w, h] = svg.match(/width="(\d+)" height="(\d+)"/);
const browser = await chromium.launch({ executablePath: exe });
const page = await browser.newPage({ viewport: { width: +w, height: +h } });
await page.setContent(`<html><body style="margin:0">${svg}</body></html>`);
await page.screenshot({ path: output });
await browser.close();
