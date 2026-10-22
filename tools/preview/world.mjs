// Renders build/world.json (from world.luau) to PNGs with three.js in headless Chromium.
// Usage (repo root): node tools/preview/world.mjs build/world.json assets/previews [shots.json]
// shots.json overrides the default shots: [{ name, mode, camera, target, frame?, world?, ortho?, ... }]
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const [, , input, outDir, shotsFile] = process.argv;

// Camera shots. Plot-local unless `world`: x across the base, y up, -z toward the gate and the hub.
const SHOTS = [
	{ name: "world-map-topdown", mode: "day", world: true, camera: [0, 900, 0], target: [0, 0, 0], ortho: 390, width: 1600, height: 1600, labelDistance: 0, shadowRadius: 420 },
	{ name: "world-hub-day", mode: "day", world: true, camera: [-112, 56, 4], target: [34, 0, 0], labelDistance: 175, shadowRadius: 140 },
	{ name: "world-carpet-day", mode: "day", world: true, camera: [6, 13, -12], target: [54, 5, 28], fov: 60, labelDistance: 90 },
	{ name: "world-base-day", mode: "day", camera: [36, 56, -74], target: [0, 0, 6], labelDistance: 130 },
	{ name: "world-base-locked-day", mode: "day", frame: "neighbourBase", camera: [36, 56, -74], target: [0, 0, 6], labelDistance: 130 },
	{ name: "world-pedestals-day", mode: "day", camera: [-2, 12, -40], target: [0, 4, -10], fov: 62, labelDistance: 80 },
	{ name: "world-hub-night", mode: "night", world: true, camera: [-112, 56, 4], target: [34, 0, 0], labelDistance: 175, shadowRadius: 140, maxLights: 14 },
];

const FILES = {
	"/": [path.join(here, "world.html"), "text/html"],
	"/world.js": [path.join(here, "world.js"), "text/javascript"],
	"/three.module.js": [path.join(here, "node_modules/three/build/three.module.js"), "text/javascript"],
	"/world.json": [path.resolve(input), "application/json"],
	"/Fredoka.ttf": [path.join(here, "../mockups/fonts/Fredoka-VF.ttf"), "font/ttf"],
};

let exe = process.env.CHROMIUM_PATH;
const root = process.env.PLAYWRIGHT_BROWSERS_PATH || "/opt/pw-browsers";
if (!exe && fs.existsSync(root)) {
	for (const d of fs.readdirSync(root).filter((d) => d.startsWith("chromium_headless_shell"))) {
		const p = path.join(root, d, "chrome-linux", "headless_shell");
		if (fs.existsSync(p)) exe = p;
	}
}
const browser = await chromium.launch({
	executablePath: exe,
	args: ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"],
});
const page = await browser.newPage({ viewport: { width: 1600, height: 1600 } });
page.on("console", (m) => m.type() === "error" && console.error("page:", m.text()));
page.on("pageerror", (e) => console.error("page error:", e.message));
await page.route("http://preview.local/**", (route) => {
	const url = new URL(route.request().url());
	let file = FILES[url.pathname];
	if (!file && url.pathname.startsWith("/addons/")) {
		file = [path.join(here, "node_modules/three/examples/jsm", url.pathname.slice(8)), "text/javascript"];
	}
	if (!file || !fs.existsSync(file[0])) return route.fulfill({ status: 404, body: "not found" });
	route.fulfill({ body: fs.readFileSync(file[0]), contentType: file[1] });
});
await page.goto("http://preview.local/");
await page.waitForFunction(() => typeof window.renderShot === "function");
const data = JSON.parse(fs.readFileSync(input, "utf8"));
fs.mkdirSync(outDir, { recursive: true });
const shots = shotsFile ? JSON.parse(fs.readFileSync(shotsFile, "utf8")) : SHOTS;
for (const s of shots) {
	const shot = s.stall ? stallShot(data, s) : s;
	await page.evaluate((shot) => window.renderShot(shot), shot);
	const out = path.join(outDir, `${s.name}.png`);
	await page.locator("canvas").screenshot({ path: out });
	console.log("wrote", out);
}
await browser.close();
