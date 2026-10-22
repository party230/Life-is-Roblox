// Rot Shift mockup kit: colours, day/night lighting, SVG helpers, isometric boxes, UI pieces.
// Everything returns SVG markup strings. Pages call `render()` from screens.js.

const PARAMS = new URLSearchParams(location.search);
const MODE = PARAMS.get("mode") || "day";
const NIGHT = MODE === "night";

const INK = "#1B1530";
const FONT_DISPLAY = "Fredoka, sans-serif";
const FONT_BODY = "Nunito, sans-serif";

// UI palette (unaffected by world lighting)
const UI = {
	yellow: "#FFD23F",
	green: "#3DDC84",
	blue: "#4DA3FF",
	pink: "#FF5C8A",
	purple: "#8B5CF6",
	orange: "#FF8A3D",
	red: "#FF4D4D",
	panel: "#FFF8EC",
	panelNight: "#2A2752",
	cream: "#FFF4E0",
};

// Rarity colours (Config/Rarities.luau). Secret gets an iridescent treatment instead of flat black.
const RARITY = {
	Common: "#C8C8C8",
	Uncommon: "#5AC85A",
	Rare: "#468CFF",
	Epic: "#AA50FF",
	Legendary: "#FFB428",
	Mythic: "#FF466E",
	Secret: "#141414",
};

// ---------- colour maths ----------
function hexToRgb(h) {
	h = h.replace("#", "");
	if (h.length === 3) h = h.split("").map((c) => c + c).join("");
	const n = parseInt(h, 16);
	return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}
function rgbToHex([r, g, b]) {
	const c = (v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0");
	return "#" + c(r) + c(g) + c(b);
}
function mix(a, b, t) {
	const A = hexToRgb(a);
	const B = hexToRgb(b);
	return rgbToHex(A.map((v, i) => v + (B[i] - v) * t));
}
function lighten(c, t) {
	return mix(c, "#FFFFFF", t);
}
function darken(c, t) {
	return mix(c, "#000000", t);
}

// World lighting: night pulls every world colour toward moonlit indigo but keeps it readable.
const NIGHT_TINT = "#232A66";
function L(c) {
	if (!NIGHT) return c;
	const lifted = mix(c, NIGHT_TINT, 0.44);
	return mix(lifted, "#3B4FA0", 0.08);
}

// ---------- svg helpers ----------
let _uid = 0;
const uid = (p = "id") => `${p}${++_uid}`;

const attrs = (o) =>
	Object.entries(o)
		.filter(([, v]) => v !== undefined && v !== null && v !== false)
		.map(([k, v]) => `${k}="${v}"`)
		.join(" ");

function strokeAttrs(o) {
	return {
		stroke: o.stroke === undefined ? INK : o.stroke,
		"stroke-width": o.sw === undefined ? 4 : o.sw,
		"stroke-linejoin": "round",
		"stroke-linecap": "round",
		opacity: o.opacity,
		filter: o.filter,
		style: o.style,
		transform: o.transform,
	};
}

const pts = (arr) => arr.map((p) => `${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(" ");
const poly = (points, fill, o = {}) => `<polygon ${attrs({ points: pts(points), fill, ...strokeAttrs(o) })}/>`;
const path = (d, fill, o = {}) => `<path ${attrs({ d, fill, ...strokeAttrs(o) })}/>`;
const circle = (cx, cy, r, fill, o = {}) => `<circle ${attrs({ cx, cy, r, fill, ...strokeAttrs(o) })}/>`;
const ellipse = (cx, cy, rx, ry, fill, o = {}) =>
	`<ellipse ${attrs({ cx, cy, rx, ry, fill, ...strokeAttrs(o) })}/>`;
const rect = (x, y, w, h, fill, o = {}) =>
	`<rect ${attrs({ x, y, width: w, height: h, rx: o.r || 0, fill, ...strokeAttrs(o) })}/>`;
const line = (x1, y1, x2, y2, o = {}) =>
	`<line ${attrs({ x1, y1, x2, y2, ...strokeAttrs(o) })}/>`;
const g = (inner, o = {}) => `<g ${attrs(o)}>${inner}</g>`;

function text(x, y, str, o = {}) {
	const a = {
		x,
		y,
		"font-family": o.font || FONT_DISPLAY,
		"font-size": o.size || 24,
		"font-weight": o.weight || 600,
		fill: o.fill || INK,
		"text-anchor": o.anchor || "start",
		"dominant-baseline": o.baseline || "auto",
		"letter-spacing": o.ls,
		opacity: o.opacity,
		transform: o.transform,
	};
	if (o.outline) {
		// Chunky game-style outlined text: stroke underneath, fill on top.
		const under = { ...a, fill: o.outline, stroke: o.outline, "stroke-width": o.ow || 6, "stroke-linejoin": "round" };
		return `<text ${attrs(under)}>${str}</text><text ${attrs(a)}>${str}</text>`;
	}
	return `<text ${attrs(a)}>${str}</text>`;
}

// Seeded RNG for low-poly jitter so renders are stable.
function rng(seed) {
	let s = seed >>> 0;
	return () => {
		s = (s * 1664525 + 1013904223) >>> 0;
		return s / 4294967296;
	};
}

// ---------- isometric world ----------
// cam: { ox, oy, s } maps world units to screen pixels.
const ISO_X = 0.866;
const ISO_Y = 0.5;
function iso(cam, x, y, z = 0) {
	return [cam.ox + (x - y) * ISO_X * cam.s, cam.oy + (x + y) * ISO_Y * cam.s - z * cam.s];
}

// Chunky low-poly box with a lit top, mid left face and shaded right face.
function box(cam, x, y, z, w, d, h, color, o = {}) {
	const P = (a, b, c) => iso(cam, a, b, c);
	const top = [P(x, y, z + h), P(x + w, y, z + h), P(x + w, y + d, z + h), P(x, y + d, z + h)];
	const left = [P(x, y + d, z + h), P(x + w, y + d, z + h), P(x + w, y + d, z), P(x, y + d, z)];
	const right = [P(x + w, y, z + h), P(x + w, y + d, z + h), P(x + w, y + d, z), P(x + w, y, z)];
	const sw = o.sw === undefined ? 3 : o.sw;
	const topC = o.top || lighten(color, 0.18);
	return (
		poly(left, L(color), { sw }) +
		poly(right, L(darken(color, 0.22)), { sw }) +
		poly(top, L(topC), { sw })
	);
}

// Flat iso quad on the ground (z) — for pads, puddles, paths.
function quad(cam, x, y, z, w, d, color, o = {}) {
	const P = (a, b) => iso(cam, a, b, z);
	return poly([P(x, y), P(x + w, y), P(x + w, y + d), P(x, y + d)], o.raw ? color : L(color), o);
}

// Iso ellipse (circle on the ground).
function isoEllipse(cam, x, y, z, r, fill, o = {}) {
	const [cx, cy] = iso(cam, x, y, z);
	return ellipse(cx, cy, r * cam.s * 1.22, r * cam.s * 0.7, fill, o);
}

// Radial glow, used for night lights. Returns [defs, element].
function glow(cx, cy, r, color, strength = 0.75) {
	const id = uid("glow");
	return (
		`<defs><radialGradient id="${id}"><stop offset="0" stop-color="${color}" stop-opacity="${strength}"/>` +
		`<stop offset="1" stop-color="${color}" stop-opacity="0"/></radialGradient></defs>` +
		`<circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#${id})"/>`
	);
}

// ---------- UI components ----------
// Chunky game button: coloured face, darker base ledge, ink outline.
function button(x, y, w, h, color, o = {}) {
	const r = o.r === undefined ? Math.min(22, h / 2.6) : o.r;
	const ledge = o.ledge === undefined ? 7 : o.ledge;
	let s = "";
	if (NIGHT && o.glow !== false) s += `<rect x="${x - 6}" y="${y - 6}" width="${w + 12}" height="${h + 12}" rx="${r + 6}" fill="${color}" opacity="0.18"/>`;
	s += rect(x, y + ledge, w, h - ledge, darken(color, 0.3), { r, sw: 4 });
	s += rect(x, y, w, h - ledge, color, { r, sw: 4 });
	s += rect(x + 8, y + 6, w - 16, Math.max(4, (h - ledge) * 0.22), "#FFFFFF", { r: r / 2, stroke: "none", opacity: 0.35 });
	if (o.label) {
		const cy = y + (h - ledge) / 2 + (o.size || 26) * 0.36;
		s += text(x + w / 2 + (o.dx || 0), cy, o.label, {
			anchor: "middle",
			size: o.size || 26,
			weight: 700,
			fill: o.textFill || "#FFFFFF",
			outline: o.textFill ? undefined : INK,
			ow: 6,
		});
	}
	return s;
}

// Rounded square HUD button with an icon and a caption under it.
function iconButton(x, y, size, color, icon, caption, o = {}) {
	let s = button(x, y, size, size, color, { r: 20 });
	s += g(icon, { transform: `translate(${x + size / 2},${y + (size - 7) / 2}) scale(${size / 84})` });
	if (caption) {
		s += text(x + size / 2, y + size + 20, caption, { anchor: "middle", size: 19, weight: 700, fill: "#FFFFFF", outline: INK, ow: 6 });
	}
	if (o.badge) {
		s += circle(x + size - 4, y + 4, 15, UI.red, { sw: 3.5 });
		s += text(x + size - 4, y + 11, o.badge, { anchor: "middle", size: 18, weight: 700, fill: "#fff" });
	}
	return s;
}

function panel(x, y, w, h, o = {}) {
	const fill = o.fill || (NIGHT ? UI.panelNight : UI.panel);
	let s = "";
	s += rect(x + 6, y + 10, w, h, "#000", { r: o.r || 28, stroke: "none", opacity: 0.25 });
	s += rect(x, y, w, h, fill, { r: o.r || 28, sw: 5 });
	return s;
}

function chip(x, y, label, color, o = {}) {
	const size = o.size || 18;
	const w = o.w || label.length * size * 0.62 + 28;
	const h = size + 16;
	let s = "";
	if (o.secret) {
		const id = uid("rainbow");
		s += `<defs><linearGradient id="${id}" x1="0" x2="1"><stop offset="0" stop-color="#FF5C8A"/><stop offset=".33" stop-color="#FFD23F"/><stop offset=".66" stop-color="#3DDC84"/><stop offset="1" stop-color="#4DA3FF"/></linearGradient></defs>`;
		s += rect(x - 3, y - 3, w + 6, h + 6, `url(#${id})`, { r: h / 2 + 3, stroke: "none" });
		s += rect(x, y, w, h, "#141414", { r: h / 2, sw: 3 });
		s += text(x + w / 2, y + h / 2 + size * 0.36, label, { anchor: "middle", size, weight: 700, fill: "#fff" });
		return s;
	}
	s += rect(x, y, w, h, color, { r: h / 2, sw: 3 });
	s += text(x + w / 2, y + h / 2 + size * 0.36, label, {
		anchor: "middle",
		size,
		weight: 700,
		fill: "#fff",
		outline: INK,
		ow: 5,
	});
	return s;
}

function rarityChip(x, y, rarity, o = {}) {
	return chip(x, y, rarity.toUpperCase(), RARITY[rarity], { ...o, secret: rarity === "Secret" });
}

// ---------- icons (drawn around 0,0, ~60px) ----------
const ICON = {
	coin: (r = 22) =>
		circle(0, 0, r, "#FFD23F", { sw: 4 }) +
		circle(0, 0, r * 0.65, "#FFE88A", { sw: 3 }) +
		text(0, r * 0.38, "$", { anchor: "middle", size: r * 1.05, weight: 700, fill: "#C98A00" }),
	shop: () =>
		rect(-24, -8, 48, 30, "#FFF4E0", { sw: 4, r: 4 }) +
		path("M-30,-8 L-22,-26 L22,-26 L30,-8 Z", "#FF5C8A", { sw: 4 }) +
		path("M-15,-26 L-12,-8 M0,-26 L0,-8 M15,-26 L12,-8", "none", { sw: 3 }) +
		rect(-8, 4, 16, 18, "#4DA3FF", { sw: 3, r: 2 }),
	egg: () =>
		path("M0,-28 C18,-28 26,0 24,10 C22,24 12,30 0,30 C-12,30 -22,24 -24,10 C-26,0 -18,-28 0,-28Z", "#FFF4E0", { sw: 4 }) +
		path("M-22,4 L-12,-4 L-2,6 L8,-4 L18,4 L23,0", "none", { sw: 3.5 }) +
		circle(-8, 16, 4, "#FF5C8A", { stroke: "none" }) +
		circle(10, 14, 5, "#4DA3FF", { stroke: "none" }),
	base: () =>
		path("M-28,-2 L0,-26 L28,-2 Z", "#FF8A3D", { sw: 4 }) +
		rect(-22, -4, 44, 30, "#FFF4E0", { sw: 4 }) +
		rect(-7, 8, 14, 18, "#8B5CF6", { sw: 3 }),
	trade: () =>
		path("M-24,-10 L14,-10 L14,-20 L28,-4 L14,12 L14,2 L-24,2 Z", "#3DDC84", { sw: 4 }) +
		path("M24,10 L-14,10 L-14,0 L-28,16 L-14,32 L-14,22 L24,22 Z", "#FFD23F", { sw: 4, transform: "translate(0,-8)" }),
	robux: () =>
		path("M0,-26 L23,-13 L23,13 L0,26 L-23,13 L-23,-13 Z", "#3DDC84", { sw: 4 }) +
		path("M0,-12 L10,-6 L10,6 L0,12 L-10,6 L-10,-6 Z", "#FFFFFF", { sw: 3.5 }),
	menu: () =>
		rect(-22, -18, 44, 8, "#fff", { sw: 3, r: 4 }) +
		rect(-22, -4, 44, 8, "#fff", { sw: 3, r: 4 }) +
		rect(-22, 10, 44, 8, "#fff", { sw: 3, r: 4 }),
	shield: () =>
		path("M0,-26 L22,-18 L20,6 C18,18 8,24 0,28 C-8,24 -18,18 -20,6 L-22,-18 Z", "#4DA3FF", { sw: 4 }) +
		path("M0,-16 L0,18", "none", { sw: 3, stroke: "#fff" }),
	hammer: () =>
		rect(-4, -6, 9, 38, "#C98A55", { sw: 4, r: 3, transform: "rotate(-30)" }) +
		rect(-24, -30, 44, 26, "#FF5C8A", { sw: 4, r: 9, transform: "rotate(-30)" }) +
		rect(-18, -26, 14, 18, "#FF9CB8", { stroke: "none", r: 5, transform: "rotate(-30)" }),
	turret: () =>
		rect(-18, 6, 36, 20, "#8A93A8", { sw: 4, r: 4 }) +
		path("M-6,6 L-6,-8 L-20,-14 C-26,-24 -14,-30 -8,-24 L-6,-20 L-4,-30 C-2,-36 6,-36 6,-28 L6,-18 L12,-26 C16,-32 24,-26 20,-20 L10,-6 L10,6Z", "#FFD23F", { sw: 3.5 }),
	moon: (r = 18) => {
		const id = uid("moon");
		return (
			`<defs><mask id="${id}"><rect x="${-r * 2}" y="${-r * 2}" width="${r * 4}" height="${r * 4}" fill="#fff"/><circle cx="${r * 0.55}" cy="${-r * 0.3}" r="${r * 0.85}" fill="#000"/></mask></defs>` +
			`<g mask="url(#${id})">${circle(0, 0, r, "#FFE88A", { sw: 3.5 })}</g>`
		);
	},
	sun: (r = 16) => {
		let s = "";
		for (let i = 0; i < 8; i++) {
			const a = (i * Math.PI) / 4;
			s += line(Math.cos(a) * (r + 4), Math.sin(a) * (r + 4), Math.cos(a) * (r + 11), Math.sin(a) * (r + 11), { sw: 4, stroke: "#FFB428" });
		}
		return s + circle(0, 0, r, "#FFD23F", { sw: 3.5 });
	},
	close: () => path("M-12,-12 L12,12 M12,-12 L-12,12", "none", { sw: 8, stroke: "#fff" }),
	treat: () =>
		ellipse(0, 0, 18, 14, "#E8B86D", { sw: 3.5 }) + circle(-6, -3, 3, "#7A4A21", { stroke: "none" }) + circle(5, 3, 3, "#7A4A21", { stroke: "none" }) + circle(4, -6, 2.5, "#7A4A21", { stroke: "none" }),
	hand: () =>
		path("M-14,10 L-14,-6 C-14,-10 -8,-10 -8,-6 L-8,-16 C-8,-21 -2,-21 -2,-16 L-2,-20 C-2,-25 4,-25 4,-20 L4,-16 C4,-21 10,-21 10,-16 L10,-2 L14,-8 C17,-12 22,-9 19,-4 L10,12 C8,16 4,18 0,18 L-6,18 C-10,18 -14,14 -14,10Z", "#FFD9B0", { sw: 3.5 }),
	move: () => path("M0,-24 L8,-14 L3,-14 L3,-3 L14,-3 L14,-8 L24,0 L14,8 L14,3 L3,3 L3,14 L8,14 L0,24 L-8,14 L-3,14 L-3,3 L-14,3 L-14,8 L-24,0 L-14,-8 L-14,-3 L-3,-3 L-3,-14 L-8,-14 Z", "#fff", { sw: 3 }),
	mask: () =>
		path("M-20,-6 C-10,-12 10,-12 20,-6 C22,4 14,10 6,6 L0,2 L-6,6 C-14,10 -22,4 -20,-6Z", "#2A2752", { sw: 3 }) +
		ellipse(-9, -2, 4.5, 3, "#fff", { stroke: "none" }) +
		ellipse(9, -2, 4.5, 3, "#fff", { stroke: "none" }),
	house: () => path("M-12,0 L0,-11 L12,0 L12,12 L-12,12 Z", "#fff", { sw: 3 }) + rect(-3, 4, 6, 8, "#8B5CF6", { sw: 2 }),
	info: () => circle(0, 0, 16, "#4DA3FF", { sw: 3.5 }) + text(0, 8, "i", { anchor: "middle", size: 24, weight: 700, fill: "#fff" }),
};

// ---------- loyalty hearts ----------
const HEART = "M0,9 C-13,0 -13,-11 -6.5,-12.5 C-3,-13.3 0,-10.5 0,-8 C0,-10.5 3,-13.3 6.5,-12.5 C13,-11 13,0 0,9Z";

// value 0..100 shown as 5 hearts. Low loyalty: hearts crack, row turns cold and gets shake marks.
function heartMeter(cx, cy, value, o = {}) {
	const k = o.scale || 1;
	const n = 5;
	const gap = 24;
	const w = n * gap + 16 + (o.stolen ? 28 : 0);
	const h = 32;
	const low = value < 30;
	const x0 = -w / 2;
	let s = "";
	const pillFill = low ? "#E9E3F7" : "#FFFFFF";
	s += rect(x0, -h / 2, w, h, pillFill, { r: h / 2, sw: 3.5, stroke: low ? "#5B3FA8" : INK });
	let hx = x0 + 20;
	if (o.stolen) {
		s += g(ICON.mask(), { transform: `translate(${hx + 2},1) scale(0.6)` });
		hx += 28;
	}
	const filled = (value / 100) * n;
	for (let i = 0; i < n; i++) {
		const f = Math.max(0, Math.min(1, filled - i));
		const x = hx + i * gap;
		const id = uid("hclip");
		const full = low ? "#9C8CC9" : "#FF3B5C";
		s += `<path d="${HEART}" transform="translate(${x},1)" fill="#D9D3E6" stroke="none"/>`;
		if (f > 0) {
			// clip rect is in the heart's local (transformed) space
			s += `<defs><clipPath id="${id}"><rect x="-13" y="-14" width="${26 * f}" height="28"/></clipPath></defs>`;
			s += `<path d="${HEART}" transform="translate(${x},1)" fill="${full}" clip-path="url(#${id})"/>`;
		}
		s += `<path d="${HEART}" transform="translate(${x},1)" fill="none" stroke="${INK}" stroke-width="2.6" stroke-linejoin="round"/>`;
		if (low && i === Math.floor(filled)) {
			s += path(`M${x - 1},-10 L${x + 2},-4 L${x - 2},0 L${x + 1},5`, "none", { sw: 2, stroke: INK, transform: "" });
		}
	}
	if (low) {
		// shake marks
		s += path(`M${x0 - 8},-8 L${x0 - 14},-4 M${x0 - 8},6 L${x0 - 15},8 M${-x0 + 8},-8 L${-x0 + 14},-4 M${-x0 + 8},6 L${-x0 + 15},8`, "none", {
			sw: 3,
			stroke: "#5B3FA8",
		});
	}
	return g(s, { transform: `translate(${cx},${cy}) scale(${k})` });
}

// ---------- page frame ----------
const CANVAS_W = 2160;

function pageFrame(title, subtitle, content, notes, o = {}) {
	const H = o.height || 960;
	const bg = NIGHT ? "#13122B" : "#F4EFE6";
	const fg = NIGHT ? "#F4EFE6" : INK;
	let s = rect(0, 0, CANVAS_W, H, bg, { stroke: "none" });
	s += text(48, 66, "ROT SHIFT", { size: 30, weight: 700, fill: UI.pink, ls: 2 });
	s += text(232, 66, title, { size: 40, weight: 700, fill: fg });
	s += text(48, 98, subtitle, { size: 20, weight: 600, font: FONT_BODY, fill: fg, opacity: 0.7 });
	// mode chip
	const chipX = (o.notesX || 1560) - 230;
	s += rect(chipX, 34, 190, 48, NIGHT ? "#2A2752" : "#FFFFFF", { r: 24, sw: 3.5 });
	s += g(NIGHT ? ICON.moon(14) : ICON.sun(12), { transform: `translate(${chipX + 34},58)` });
	s += text(chipX + 62, 67, NIGHT ? "NIGHT" : "DAY", { size: 26, weight: 700, fill: fg });
	s += content;
	if (notes) s += notesColumn(o.notesX || 1560, 130, CANVAS_W - (o.notesX || 1560) - 40, notes);
	return { svg: s, width: CANVAS_W, height: H };
}

function notesColumn(x, y, w, notes) {
	const fg = NIGHT ? "#F4EFE6" : INK;
	let s = rect(x, y, w, notes.height || 760, NIGHT ? "#1E1C3D" : "#FFFFFF", { r: 20, sw: 3, stroke: NIGHT ? "#3A3670" : "#E2D9C8" });
	let cy = y + 44;
	s += text(x + 22, cy, "Notes & questions", { size: 24, weight: 700, fill: fg });
	cy += 16;
	for (const item of notes.items) {
		cy += 22;
		const lines = wrap(item.text, Math.floor((w - 90) / 8.6));
		if (item.id) {
			s += rect(x + 18, cy - 19, 46, 26, item.q ? UI.pink : UI.blue, { r: 8, stroke: "none" });
			s += text(x + 41, cy, item.id, { size: 15, weight: 700, fill: "#fff", anchor: "middle" });
		}
		lines.forEach((ln, i) => {
			s += text(x + (item.id ? 74 : 22), cy + i * 23, ln, { size: 17, weight: 600, font: FONT_BODY, fill: fg });
		});
		cy += lines.length * 23;
	}
	return s;
}

function wrap(str, max) {
	const words = str.split(" ");
	const out = [];
	let cur = "";
	for (const w of words) {
		if ((cur + " " + w).trim().length > max) {
			out.push(cur.trim());
			cur = w;
		} else cur += " " + w;
	}
	if (cur.trim()) out.push(cur.trim());
	return out;
}

// Phone frame (landscape). Screen is 1440x664 (19.5:9). `screen` is drawn in screen-local coords.
const PHONE = { x: 48, y: 140, w: 1440, h: 664, bezel: 22 };
function phone(screen) {
	const { x, y, w, h, bezel } = PHONE;
	const id = uid("screen");
	let s = "";
	s += rect(x - bezel + 8, y - bezel + 14, w + bezel * 2, h + bezel * 2, "#000", { r: 64, stroke: "none", opacity: 0.25 });
	s += rect(x - bezel, y - bezel, w + bezel * 2, h + bezel * 2, "#16141F", { r: 64, sw: 4 });
	s += `<defs><clipPath id="${id}"><rect x="0" y="0" width="${w}" height="${h}" rx="44"/></clipPath></defs>`;
	s += `<g transform="translate(${x},${y})"><g clip-path="url(#${id})">${screen}</g></g>`;
	// camera notch on the left edge (landscape)
	s += rect(x - 14, y + h / 2 - 50, 8, 100, "#000", { r: 4, stroke: "none" });
	return s;
}

// Roblox's own mobile controls and top bar, drawn ghosted (not part of our UI budget).
function robloxChrome(w, h, o = {}) {
	let s = "";
	// top bar
	s += rect(16, 14, 54, 54, "#000", { r: 16, stroke: "none", opacity: 0.38 });
	s += path("M30,30 L56,30 M30,41 L56,41 M30,52 L56,52", "none", { sw: 4, stroke: "#fff", opacity: 0.9 });
	s += rect(78, 14, 54, 54, "#000", { r: 16, stroke: "none", opacity: 0.38 });
	s += path("M92,32 L118,32 L118,48 L104,48 L96,55 L96,48 L92,48 Z", "#fff", { stroke: "none", opacity: 0.9 });
	// thumbstick
	if (o.thumb !== false) {
		s += circle(170, h - 150, 82, "#000", { stroke: "#fff", sw: 3, opacity: 0.22 });
		s += circle(170, h - 150, 36, "#fff", { stroke: "none", opacity: 0.32 });
	}
	// jump
	s += circle(w - 130, h - 120, 62, "#000", { stroke: "#fff", sw: 3, opacity: 0.22 });
	s += path(`M${w - 150},${h - 108} L${w - 130},${h - 130} L${w - 110},${h - 108}`, "none", { sw: 6, stroke: "#fff", opacity: 0.6 });
	return s;
}
