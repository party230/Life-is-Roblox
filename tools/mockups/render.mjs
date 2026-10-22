// Renders every mockup page to PNG: `node render.mjs [page...]`.
// Needs playwright-core and a Chromium (CHROMIUM_PATH or Playwright's default install).
import { chromium } from "playwright-core";
import { fileURLToPath, pathToFileURL } from "node:url";
import path from "node:path";
import fs from "node:fs";

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(here, "../../assets/mockups");
const PAGES = ["hud", "shop", "inspect", "base", "map", "concept", "picker", "eggs", "hatch"];
const pages = process.argv.slice(2).length ? process.argv.slice(2) : [...PAGES, "overview"];

// Prefer CHROMIUM_PATH, else a preinstalled Playwright headless shell, else Playwright's default.
function findChromium() {
	if (process.env.CHROMIUM_PATH) return process.env.CHROMIUM_PATH;
	const root = process.env.PLAYWRIGHT_BROWSERS_PATH || "/opt/pw-browsers";
	if (!fs.existsSync(root)) return undefined;
	for (const dir of fs.readdirSync(root).filter((d) => d.startsWith("chromium_headless_shell"))) {
		const exe = path.join(root, dir, "chrome-linux", "headless_shell");
		if (fs.existsSync(exe)) return exe;
	}
	return undefined;
}
const browser = await chromium.launch({ executablePath: findChromium() });
const ctx = await browser.newContext({ deviceScaleFactor: 1.5, viewport: { width: 2160, height: 1000 } });
const tab = await ctx.newPage();
tab.on("pageerror", (e) => console.error("page error:", e.message));

let n = 0;
for (const p of pages) {
	const modes = p === "overview" ? ["day"] : ["day", "night"];
	for (const mode of modes) {
		const url = pathToFileURL(path.join(here, "page.html")).href + `?page=${p}&mode=${mode}`;
		await tab.goto(url);
		await tab.waitForFunction(() => window.__done, null, { timeout: 30000 });
		const raw = await tab.evaluate(() => window.__done);
		const size = { width: Math.ceil(raw.width), height: Math.ceil(raw.height) };
		await tab.setViewportSize({ width: size.width, height: size.height });
		await tab.waitForTimeout(150);
		const name = p === "overview" ? "00-overview.png" : `${String(PAGES.indexOf(p) + 1).padStart(2, "0")}-${p}-${mode}.png`;
		await tab.screenshot({ path: path.join(outDir, name), clip: { x: 0, y: 0, width: size.width, height: size.height } });
		console.log("wrote", name);
		n++;
	}
}
await browser.close();
console.log(`${n} images`);
