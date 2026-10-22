// Renders build/world.json (from world.luau) to PNGs with three.js in headless Chromium.
// Usage (repo root): node tools/preview/world.mjs build/world.json assets/previews
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const [, , input, outDir] = process.argv;

// Camera shots. Plot-local coordinates: x across the plot, y up, -z toward the gate and the plaza.
const SHOTS = [
	{ name: "world-base-day", mode: "day", camera: [26, 34, -66], target: [0, 1, 4] },
	{ name: "world-carpet-day", mode: "day", camera: [15, 10, -20], target: [0, 4, 6], fov: 50, labelDistance: 60 },
	{ name: "world-stall-day", mode: "day", stall: true },
	{ name: "world-overview-day", mode: "day", camera: [150, 170, -40], target: [0, 0, -105], fov: 50, shadowRadius: 220, labelDistance: 0 },
	{ name: "world-base-night", mode: "night", camera: [26, 34, -66], target: [0, 1, 4] },
	{ name: "world-carpet-night", mode: "night", camera: [15, 10, -20], target: [0, 4, 6], fov: 50, labelDistance: 60 },
];

const FILES = {
	"/": [path.join(here, "world.html"), "text/html"],
	"/world.js": [path.join(here, "world.js"), "text/javascript"],
	"/three.module.js": [path.join(here, "node_modules/three/build/three.module.js"), "text/javascript"],
	"/world.json": [path.resolve(input), "application/json"],
	"/Fredoka.ttf": [path.join(here, "../mockups/fonts/Fredoka-VF.ttf"), "font/ttf"],
};

// The stall faces the plaza centre; frame it from the plaza side.
function stallShot(data, shot) {
	const label = data.billboards.find((b) => b.lines.some((l) => l.text === "Egg Shop"));
	const [x, y, z] = label.pos;
	const len = Math.hypot(x, z);
	const ux = -x / len, uz = -z / len; // toward the plaza centre
	return {
		...shot,
		world: true,
		camera: [x + ux * 30 - uz * 12, 12, z + uz * 30 + ux * 12],
		target: [x, y - 6, z],
		fov: 50,
		labelDistance: 80,
	};
}

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
const page = await browser.newPage({ viewport: { width: 1600, height: 900 } });
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
for (const s of SHOTS) {
	const shot = s.stall ? stallShot(data, s) : s;
	await page.evaluate((shot) => window.renderShot(shot), shot);
	const out = path.join(outDir, `${s.name}.png`);
	await page.locator("canvas").screenshot({ path: out });
	console.log("wrote", out);
}
await browser.close();
