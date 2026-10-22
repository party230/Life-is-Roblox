// Renders the v3 UI mockups (ui.html) to PNG. Usage (repo root): node tools/mockups/v3/render.mjs assets/mockups/v3
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = process.argv[2] || "assets/mockups/v3";
const SCREENS = ["food-feasts", "food-premium", "nursery", "nursery-locked"];

let exe = process.env.CHROMIUM_PATH;
const root = process.env.PLAYWRIGHT_BROWSERS_PATH || "/opt/pw-browsers";
if (!exe && fs.existsSync(root)) {
	for (const d of fs.readdirSync(root).filter((d) => d.startsWith("chromium_headless_shell"))) {
		const p = path.join(root, d, "chrome-linux", "headless_shell");
		if (fs.existsSync(p)) exe = p;
	}
}
const browser = await chromium.launch({ executablePath: exe, args: ["--allow-file-access-from-files"] });
const page = await browser.newPage({ viewport: { width: 2000, height: 900 } });
page.on("pageerror", (e) => console.error("page error:", e.message));
fs.mkdirSync(outDir, { recursive: true });
for (const s of SCREENS) {
	await page.goto(`${pathToFileURL(path.join(here, "ui.html")).href}?screen=${s}`);
	await page.evaluate(() => document.fonts.ready);
	await page.waitForTimeout(150);
	const out = path.join(outDir, `ui-${s}.png`);
	await page.screenshot({ path: out });
	console.log("wrote", out);
}
await browser.close();
