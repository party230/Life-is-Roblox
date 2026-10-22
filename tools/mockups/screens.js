// Mockup pages. Each returns { svg, width, height } via pageFrame().
const PAGES = {};

PAGES.concept = () => {
	const W = CANVAS_W;
	const H = 1420;
	const cols = 4;
	const cardW = 340;
	const cardH = 300;
	const gx = 22;
	const x0 = 48;
	const y0 = 130;
	let s = "";
	const cardFill = NIGHT ? "#1E1C3D" : "#FFFFFF";
	const fg = NIGHT ? "#F4EFE6" : INK;
	SPECIES_ORDER.forEach((id, i) => {
		const def = SPECIES[id];
		const cx = x0 + (i % cols) * (cardW + gx);
		const cy = y0 + Math.floor(i / cols) * (cardH + gx);
		const rc = RARITY[def.rarity];
		s += rect(cx + 5, cy + 8, cardW, cardH, "#000", { r: 24, stroke: "none", opacity: 0.18 });
		s += rect(cx, cy, cardW, cardH, cardFill, { r: 24, sw: 4 });
		// stage
		const stage = NIGHT ? "#2B3270" : lighten(rc === "#141414" ? "#8B5CF6" : rc, 0.72);
		s += rect(cx + 14, cy + 14, cardW - 28, 178, stage, { r: 18, stroke: "none" });
		if (NIGHT) s += glow(cx + cardW / 2, cy + 110, 110, rc === "#141414" ? "#8B5CF6" : rc, 0.45);
		s += ellipse(cx + cardW / 2, cy + 180, 62, 12, "#000", { stroke: "none", opacity: 0.18 });
		s += creature(id, cx + cardW / 2, cy + 182, 170, { mood: "happy" });
		s += rarityChip(cx + 16, cy + 22, def.rarity, { size: 15 });
		s += text(cx + 18, cy + 228, def.name, { size: 30, weight: 700, fill: fg });
		const lines = wrap(def.blurb, 40);
		lines.forEach((ln, j) => (s += text(cx + 18, cy + 256 + j * 21, ln, { size: 16, weight: 600, font: FONT_BODY, fill: fg, opacity: 0.85 })));
	});
	// Loyalty states strip
	const sy = y0 + 3 * (cardH + gx) + 6;
	s += rect(x0, sy, 4 * cardW + 3 * gx, 250, cardFill, { r: 24, sw: 4 });
	s += text(x0 + 24, sy + 42, "Loyalty reads at a glance", { size: 28, weight: 700, fill: fg });
	const states = [
		["happy", 92, false, "Loyal 80+", "bouncy, blushing, full hearts"],
		["content", 55, false, "Settling in", "calm smile, half hearts"],
		["uneasy", 14, true, "Stolen + uneasy", "sweat, shakes, looks toward home"],
		["rogue", 4, false, "Rogue", "night only: red eyes, purple aura"],
	];
	states.forEach(([mood, v, stolen, label, sub], i) => {
		const cx = x0 + 40 + i * 360;
		s += creature("kettlephant", cx + 90, sy + 214, 130, { mood });
		s += heartMeter(cx + 90, sy + 76, v, { stolen, scale: 0.9 });
		s += text(cx + 196, sy + 140, label, { size: 22, weight: 700, fill: fg });
		wrap(sub, 16).forEach((ln, j) => (s += text(cx + 196, sy + 166 + j * 21, ln, { size: 16, weight: 600, font: FONT_BODY, fill: fg, opacity: 0.8 })));
	});
	// Mutations column
	const mx = x0 + 4 * cardW + 3 * gx + 24;
	const mw = W - mx - 40;
	s += rect(mx, y0, mw, 3 * (cardH + gx) - gx + 256, cardFill, { r: 24, sw: 4 });
	s += text(mx + 22, y0 + 44, "Mutations", { size: 28, weight: 700, fill: fg });
	const muts = [["None", "x1"], ["Golden", "x2 · 5%"], ["Glitched", "x3 · 2%"], ["Rainbow", "x5 · 1%"], ["Tiny", "x0.8 · 4% · carries faster"], ["Mega", "x1.5 · 3% · carries slower"]];
	muts.forEach(([m, sub], i) => {
		const cy = y0 + 70 + i * 150;
		s += creature("mugpup", mx + 80, cy + 128, 120, { mood: "happy", mutation: m });
		s += text(mx + 156, cy + 70, m, { size: 24, weight: 700, fill: fg });
		wrap(sub, 14).forEach((ln, j) => (s += text(mx + 156, cy + 96 + j * 20, ln, { size: 16, weight: 600, font: FONT_BODY, fill: fg, opacity: 0.8 })));
	});
	const out = pageFrame("Brainrot concept sheet", "12 original species · object + animal + face · rarity colour on every card", s, null, { height: H, notesX: W - 40 });
	return out;
};

// ---------- shared HUD pieces ----------
const SW = 1440;
const SH = 664;

function cashPills(x, y) {
	let s = "";
	s += rect(x, y, 250, 58, "#FFFFFF", { r: 29, sw: 4.5 });
	s += g(ICON.coin(20), { transform: `translate(${x + 32},${y + 29})` });
	s += text(x + 62, y + 41, "$12,480", { size: 34, weight: 700 });
	s += rect(x + 10, y + 64, 150, 38, "#2BB673", { r: 19, sw: 4 });
	s += text(x + 85, y + 91, "+$84/s", { anchor: "middle", size: 24, weight: 700, fill: "#fff", outline: INK, ow: 5 });
	return s;
}

// Cycle timer: phase pill + segmented bar (Day 480 · Dusk 20 · Night 240 · Vote 30).
function cycleTimer(cx, y) {
	const w = 320;
	const x = cx - w / 2;
	let s = "";
	const fill = NIGHT ? "#2A2752" : "#FFFFFF";
	const fg = NIGHT ? "#FFFFFF" : INK;
	s += rect(x, y, w, 62, fill, { r: 31, sw: 4.5 });
	s += g(NIGHT ? ICON.moon(19) : ICON.sun(15), { transform: `translate(${x + 40},${y + 31})` });
	s += text(x + 74, y + 43, NIGHT ? "NIGHT" : "DAY", { size: 30, weight: 700, fill: fg });
	s += text(x + w - 26, y + 43, NIGHT ? "2:13" : "5:42", { anchor: "end", size: 34, weight: 700, fill: NIGHT ? UI.yellow : INK });
	// bar
	const total = 480 + 20 + 240 + 30;
	const segs = [[480, "#FFD23F"], [20, "#FF8A3D"], [240, "#5B5FC7"], [30, "#FF5C8A"]];
	const bx = x + 20;
	const bw = w - 40;
	let cur = bx;
	s += rect(bx - 3, y + 70, bw + 6, 18, INK, { r: 9, stroke: "none" });
	segs.forEach(([len, c], i) => {
		const sw = (len / total) * bw;
		s += rect(cur + 1, y + 73, sw - 2, 12, c, { r: i === 0 || i === 3 ? 6 : 2, stroke: "none" });
		cur += sw;
	});
	const t = NIGHT ? 480 + 20 + (240 - 133) : 480 - 342;
	const mx = bx + (t / total) * bw;
	s += path(`M${mx - 9},${y + 64} L${mx + 9},${y + 64} L${mx},${y + 78} Z`, "#FFFFFF", { sw: 3.5 });
	if (NIGHT) s += chip(cx - 62, y + 96, "WAVE 2 / 4", "#5B5FC7", { size: 16, w: 124 });
	return s;
}

function toast(cx, y, icon, msg, color) {
	const w = msg.length * 12.5 + 90;
	const x = cx - w / 2;
	let s = rect(x, y, w, 52, "#FFFFFF", { r: 26, sw: 4 });
	s += circle(x + 28, y + 26, 18, color, { sw: 3 });
	s += g(icon, { transform: `translate(${x + 28},${y + 27}) scale(0.55)` });
	s += text(x + 56, y + 34, msg, { size: 21, weight: 700, font: FONT_BODY });
	return s;
}

function hudButtons() {
	let s = "";
	const left = NIGHT
		? [[UI.pink, ICON.shop(), "Shop"], [UI.blue, ICON.shield(), "Defend"], [UI.orange, ICON.base(), "Base"]]
		: [[UI.pink, ICON.shop(), "Shop"], [UI.yellow, ICON.egg(), "Eggs", "1"], [UI.orange, ICON.base(), "Base"]];
	left.forEach(([c, ic, cap, badge], i) => (s += iconButton(22, 158 + i * 122, 84, c, ic, cap, { badge })));
	const right = NIGHT ? [[UI.green, ICON.robux(), "Store"], [UI.purple, ICON.menu(), "Menu"]] : [[UI.blue, ICON.trade(), "Trade"], [UI.green, ICON.robux(), "Store"], [UI.purple, ICON.menu(), "Menu"]];
	right.forEach(([c, ic, cap], i) => (s += iconButton(SW - 112 - (right.length - 1 - i) * 104, 18, 84, c, ic, cap)));
	if (NIGHT) {
		const bx = SW - 300;
		const by = SH - 128;
		s += circle(bx, by + 6, 70, darken(UI.pink, 0.3), { sw: 4.5 });
		s += circle(bx, by, 70, UI.pink, { sw: 4.5 });
		s += ellipse(bx - 14, by - 34, 34, 12, "#fff", { stroke: "none", opacity: 0.35 });
		s += g(ICON.hammer(), { transform: `translate(${bx + 4},${by - 6}) scale(1.25)` });
		s += text(bx, by + 50, "BONK", { anchor: "middle", size: 26, weight: 700, fill: "#fff", outline: INK, ow: 6 });
	}
	return s;
}

function crackedHeartIcon() {
	return path(HEART, "#FF3B5C", { sw: 3, transform: "scale(1.6)" }) + path("M-2,-16 L4,-6 L-3,2 L3,12", "none", { sw: 3.5, stroke: "#fff" });
}

function hudCam() {
	return { ox: 670, oy: 40, s: 18 };
}

PAGES.hud = () => {
	const scene = baseScene(hudCam(), { knockout: 7, lockTags: false });
	let scr = scene.svg + scene.overlay;
	scr += robloxChrome(SW, SH);
	scr += cashPills(146, 14);
	scr += cycleTimer(SW / 2, 14);
	scr += hudButtons();
	if (NIGHT) scr += toast(SW / 2, 178, ICON.house(), "Kettlephant is sneaking home! Bonk it back", UI.purple);
	else scr += toast(SW / 2, 112, crackedHeartIcon(), "Kettlephant misses home · tap to pet", UI.pink);
	const notes = {
		items: [
			{ id: "HUD-1", text: "Always visible: cash, income/s and the cycle timer. The bar under the timer shows Day → Dusk → Night → Vote." },
			{ id: "HUD-2", text: "6 buttons max. Day: Shop, Eggs, Base on the left; Trade, Store, Menu top-right. Night: Trade and Eggs swap out for Defend and a big BONK button." },
			{ id: "HUD-3", text: "One alert toast at a time under the timer. Tapping it jumps the camera to that brainrot." },
			{ id: "HUD-4", text: "Ghosted controls (thumbstick, jump, top-left menu/chat) are Roblox's own and don't count toward the 6." },
			{ id: "HUD-5", text: "Buttons are 84px here, about 48pt on a phone, above Apple's 44pt minimum." },
			{ id: "HUD-6", text: "Over each brainrot: loyalty hearts. Purple, cracked and shaking = uneasy. The mask icon = stolen." },
			{ id: "Q1", q: true, text: "Shop stays open at night (shown). OK, or should the belt pause until dawn?" },
			{ id: "Q2", q: true, text: "Camera here is an isometric illustration. In game it's the normal third-person follow cam. Want a fixed top-down cam instead?" },
		],
	};
	return pageFrame("HUD", "Main gameplay screen · phone landscape 19.5:9", phone(scr), notes);
};

function dimmedSceneWithHud(o = {}) {
	const scene = baseScene(hudCam(), { lockTags: false, hearts: o.hearts, knockout: 7 });
	let s = scene.svg;
	s += rect(0, 0, SW, SH, "#0B0A1E", { stroke: "none", opacity: 0.55 });
	s += robloxChrome(SW, SH, { thumb: false });
	s += cashPills(146, 14);
	s += cycleTimer(SW / 2, 14);
	return s;
}

function closeButton(x, y) {
	return circle(x, y + 5, 34, darken(UI.red, 0.3), { sw: 4 }) + circle(x, y, 34, UI.red, { sw: 4 }) + g(ICON.close(), { transform: `translate(${x},${y})` });
}

function header(x, y, w, title, color) {
	let s = rect(x, y, w, 70, color, { r: 24, sw: 5 });
	s += text(x + w / 2, y + 48, title, { anchor: "middle", size: 38, weight: 700, fill: "#fff", outline: INK, ow: 7 });
	return s;
}

// ---------- Conveyor shop ----------
PAGES.shop = () => {
	let scr = dimmedSceneWithHud({ hearts: false });
	const px = 190;
	const py = 132;
	const pw = 1060;
	const ph = 512;
	const fg = NIGHT ? "#FFFFFF" : INK;
	scr += panel(px, py, pw, ph);
	scr += header(px + 300, py - 34, 460, "CONVEYOR SHOP", UI.pink);
	scr += closeButton(px + pw - 10, py + 4);
	scr += g(ICON.sun(0), {}); // keeps defs order stable
	scr += text(px + 34, py + 74, "New stock in", { size: 22, weight: 600, font: FONT_BODY, fill: fg });
	scr += chip(px + 170, py + 50, "0:42", UI.blue, { size: 20, w: 82 });
	scr += text(px + pw - 34, py + 74, "6 / 8 pedestals used", { anchor: "end", size: 22, weight: 600, font: FONT_BODY, fill: fg });
	// belt
	const by = py + 104;
	scr += rect(px + 20, by + 18, pw - 40, 300, "#3A3F55", { r: 18, sw: 4.5 });
	for (let x = px + 50; x < px + pw - 40; x += 46) scr += path(`M${x},${by + 330} l14,10 l-14,10`, "none", { sw: 4, stroke: "#FFD23F", opacity: 0.8 });
	scr += rect(px + 20, by + 322, pw - 40, 36, "#2B2F42", { r: 12, sw: 4 });
	const cards = [
		{ id: "toasturtle", price: "$55", inc: "+$1.0/s", sold: true },
		{ id: "lampingo", price: "$210", inc: "+$2.6/s" },
		{ id: "fridgehog", price: "$1,050", inc: "+$6/s" },
		{ id: "cartshark", price: "$5,200", inc: "+$15/s", isNew: true },
		{ id: "pianoceros", price: "$26K", inc: "+$40/s", poor: true },
	];
	cards.forEach((c, i) => {
		const def = SPECIES[c.id];
		const cx = px + 40 + i * 200;
		const cy = by;
		const rc = RARITY[def.rarity];
		scr += rect(cx + 4, cy + 8, 182, 300, "#000", { r: 20, stroke: "none", opacity: 0.25 });
		scr += rect(cx, cy, 182, 300, "#FFFFFF", { r: 20, sw: 4.5 });
		scr += rect(cx + 10, cy + 10, 162, 140, lighten(rc, 0.7), { r: 14, stroke: "none" });
		scr += ellipse(cx + 91, cy + 138, 50, 9, "#000", { stroke: "none", opacity: 0.15 });
		scr += creature(c.id, cx + 91, cy + 142, 132, { mood: "happy" });
		scr += rarityChip(cx + 12, cy + 14, def.rarity, { size: 13 });
		scr += text(cx + 91, cy + 182, def.name, { anchor: "middle", size: 25, weight: 700 });
		scr += text(cx + 91, cy + 210, c.inc, { anchor: "middle", size: 22, weight: 700, fill: "#2BB673" });
		if (c.sold) {
			scr += button(cx + 14, cy + 226, 154, 62, "#A8AFBF", { label: "SOLD", size: 24 });
			scr += rect(cx, cy, 182, 300, "#FFFFFF", { r: 20, stroke: "none", opacity: 0.45 });
		} else if (c.poor) {
			scr += button(cx + 14, cy + 226, 154, 62, "#A8AFBF", { label: "Need $13.5K", size: 19 });
		} else {
			scr += button(cx + 14, cy + 226, 154, 62, UI.green, { label: c.price, size: 26 });
		}
		if (c.isNew) {
			scr += g(poly([[0, -26], [8, -9], [26, -9], [12, 3], [17, 22], [0, 11], [-17, 22], [-12, 3], [-26, -9], [-8, -9]], UI.yellow, { sw: 3.5 }) + text(0, 6, "NEW", { anchor: "middle", size: 12, weight: 700 }), { transform: `translate(${cx + 168},${cy + 10}) rotate(12)` });
		}
	});
	// odds footer
	scr += g(ICON.info(), { transform: `translate(${px + 54},${py + ph - 36})` });
	scr += text(px + 80, py + ph - 28, "Belt odds: Common 70% · Uncommon 22% · Rare 6% · Epic 1.6% · Legendary 0.35% · Mythic 0.05%", { size: 19, weight: 700, font: FONT_BODY, fill: fg });
	const notes = {
		items: [
			{ id: "SHOP-1", text: "A modal over the dimmed base. Cash and the timer stay visible so you can see what you can afford." },
			{ id: "SHOP-2", text: "5 cards on a moving belt. Each card has its rarity colour, income/s and a big price button (154x62)." },
			{ id: "SHOP-3", text: "States: buyable (green), can't afford (grey + how much more), sold, and a NEW sticker for this rotation." },
			{ id: "SHOP-4", text: "Odds are always shown, even though the belt only takes cash." },
			{ id: "SHOP-5", text: "Buying sends it to your next free pedestal. When you're full, the button says “Base full” instead." },
			{ id: "Q3", q: true, text: "Is the belt stock per player, or shared by the whole server so players race for a rare roll? (I'd go per player: fewer hurt feelings.)" },
			{ id: "Q4", q: true, text: "Show payback time on cards (“pays for itself in 3 min”)? It's useful, but adds text." },
		],
	};
	return pageFrame("Conveyor shop", "Opened from the Shop button or by walking up to the belt", phone(scr), notes);
};

// ---------- Brainrot inspect panel ----------
PAGES.inspect = () => {
	let scr = dimmedSceneWithHud({ hearts: false });
	const stolen = NIGHT;
	const sp = stolen
		? { id: "kettlephant", mood: "uneasy", loyalty: 14, old: 58, inc: "+$6/s", mutation: null, since: "With you 1 night" }
		: { id: "fridgehog", mood: "happy", loyalty: 86, inc: "+$12/s", mutation: "Golden", since: "Owned 3 days" };
	const def = SPECIES[sp.id];
	const rc = RARITY[def.rarity];
	const px = 150;
	const py = 116;
	const pw = 1140;
	const ph = 530;
	const fg = NIGHT ? "#FFFFFF" : INK;
	scr += panel(px, py, pw, ph);
	scr += closeButton(px + pw - 10, py + 4);
	// portrait
	scr += rect(px + 24, py + 24, 400, ph - 48, lighten(rc, NIGHT ? 0.2 : 0.65), { r: 24, sw: 4 });
	scr += glow(px + 224, py + 260, 200, "#FFFFFF", 0.55);
	scr += ellipse(px + 224, py + 430, 140, 26, "#000", { stroke: "none", opacity: 0.18 });
	scr += creature(sp.id, px + 224, py + 436, 330, { mood: sp.mood, mutation: sp.mutation });
	scr += heartMeter(px + 224, py + 70, sp.loyalty, { stolen, scale: 1.3 });
	// info
	const ix = px + 456;
	scr += text(ix, py + 76, def.name, { size: 52, weight: 700, fill: fg });
	scr += rarityChip(ix, py + 96, def.rarity, { size: 18 });
	if (sp.mutation) scr += chip(ix + 108, py + 96, "GOLDEN x2", "#E6A800", { size: 18 });
	scr += text(ix, py + 172, def.blurb, { size: 19, weight: 600, font: FONT_BODY, fill: fg, opacity: 0.8 });
	// stats row
	scr += rect(ix, py + 194, 300, 70, NIGHT ? "#1E1C3D" : "#FFFFFF", { r: 18, sw: 3.5 });
	scr += text(ix + 20, py + 222, "INCOME", { size: 15, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.6 });
	scr += text(ix + 20, py + 252, sp.inc, { size: 30, weight: 700, fill: "#2BB673" });
	scr += rect(ix + 316, py + 194, 330, 70, NIGHT ? "#1E1C3D" : "#FFFFFF", { r: 18, sw: 3.5 });
	scr += text(ix + 336, py + 222, "STEAL RESISTANCE", { size: 15, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.6 });
	scr += text(ix + 336, py + 252, stolen ? "Thieves run at 84%" : "Thieves run at 51%", { size: 26, weight: 700, fill: fg });
	// loyalty block
	const ly = py + 282;
	if (stolen) {
		scr += rect(ix, ly, 646, 128, "#3B2A6E", { r: 18, sw: 3.5 });
		scr += g(ICON.mask(), { transform: `translate(${ix + 30},${ly + 30}) scale(0.9)` });
		scr += text(ix + 56, ly + 38, "STOLEN from RotLord99", { size: 22, weight: 700, fill: "#fff" });
		scr += text(ix + 20, ly + 78, "Loyal to you", { size: 18, weight: 700, font: FONT_BODY, fill: "#fff" });
		scr += heartMeter(ix + 220, ly + 72, 14, { scale: 0.95 });
		scr += text(ix + 20, ly + 112, "Misses home", { size: 18, weight: 700, font: FONT_BODY, fill: "#fff" });
		scr += heartMeter(ix + 220, ly + 106, 58, { scale: 0.95 });
		scr += rect(ix + 362, ly + 56, 270, 60, UI.red, { r: 16, sw: 3.5 });
		scr += text(ix + 497, ly + 80, "MAY WALK HOME TONIGHT", { anchor: "middle", size: 15, weight: 700, fill: "#fff" });
		scr += text(ix + 497, ly + 106, "18% chance", { anchor: "middle", size: 24, weight: 700, fill: "#fff", outline: INK, ow: 5 });
	} else {
		scr += rect(ix, ly, 646, 128, NIGHT ? "#1E1C3D" : "#FFF0F3", { r: 18, sw: 3.5 });
		scr += text(ix + 20, ly + 40, "LOYALTY", { size: 15, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.6 });
		scr += heartMeter(ix + 120, ly + 82, 86, { scale: 1.35 });
		scr += text(ix + 262, ly + 92, "86", { size: 46, weight: 700, fill: "#FF3B5C" });
		scr += text(ix + 322, ly + 92, "/ 100 · Loyal", { size: 24, weight: 700, fill: fg });
		scr += text(ix + 20, ly + 118, "+0.5/min while you own it · decays after 60 min of neglect", { size: 15, weight: 600, font: FONT_BODY, fill: fg, opacity: 0.7 });
	}
	scr += text(ix + 646, py + 76, sp.since, { anchor: "end", size: 18, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.7 });
	// actions
	const ay = py + ph - 106;
	scr += button(ix, ay, 200, 84, UI.green, { label: "Feed", size: 28, dx: 22 });
	scr += g(ICON.treat(), { transform: `translate(${ix + 40},${ay + 38})` });
	scr += chip(ix + 140, ay - 14, "x14", UI.yellow, { size: 15, w: 56 });
	if (stolen) {
		scr += button(ix + 222, ay, 200, 84, "#A8AFBF", { label: "Pet 0:42", size: 26, dx: 22 });
	} else {
		scr += button(ix + 222, ay, 200, 84, UI.pink, { label: "Pet", size: 28, dx: 22 });
	}
	scr += g(ICON.hand(), { transform: `translate(${ix + 262},${ay + 38}) scale(1.1)` });
	scr += button(ix + 444, ay, 200, 84, UI.blue, { label: "Move", size: 28, dx: 22 });
	scr += g(ICON.move(), { transform: `translate(${ix + 484},${ay + 38}) scale(0.9)` });
	const notes = {
		items: [
			{ id: "INS-1", text: "Opened by tapping a brainrot or its hearts. Big portrait in its current mood, with its rarity colour behind it." },
			{ id: "INS-2", text: "Day shows a loyal Golden Fridgehog. Night shows a stolen Kettlephant at low loyalty: sweating, looking toward home, hearts cracked." },
			{ id: "INS-3", text: "Stolen brainrots show two meters, loyalty to you and loyalty to home, plus tonight's walk-home chance in plain words." },
			{ id: "INS-4", text: "Steal resistance shown as how fast a thief can run with it (from loyalty and rarity)." },
			{ id: "INS-5", text: "Actions: Feed (uses treats), Pet (60s cooldown shown on the button), Move. All buttons are 200x84." },
			{ id: "Q5", q: true, text: "Show the exact loyalty number, or hearts only? (Showing both, as here, helps older players and costs little.)" },
			{ id: "Q6", q: true, text: "Bond Collar (game pass) slot: put it on this panel or only in the Store? I left it off to keep the panel calm." },
		],
	};
	return pageFrame("Brainrot inspect panel", NIGHT ? "Stolen brainrot at low loyalty" : "Owned, loyal brainrot", phone(scr), notes);
};

// ---------- Base layout ----------
PAGES.base = () => {
	const ax = 48;
	const ay = 130;
	const aw = 1460;
	const ah = 790;
	const id = uid("area");
	const cam = { ox: 598 - 48 + ax, oy: 190, s: 14 };
	const scene = baseScene(cam, { knockout: 7, avatarName: "You", vx: 0, vy: 0, vw: aw + 200, vh: ah + 300 });
	let s = `<defs><clipPath id="${id}"><rect x="${ax}" y="${ay}" width="${aw}" height="${ah}" rx="28"/></clipPath></defs>`;
	let inner = scene.svg + scene.overlay;
	const P = scene.pts;
	// [number, anchor point, bubble offset]
	const callouts = [
		[1, P.belt, [0, -70]],
		[2, P.ped1, [-70, -110]],
		[3, P.ped13 || P.locked, [60, 40]],
		[4, P.collector, [110, 40]],
		[5, P.gate, [-90, -40]],
		[6, P.socket0, [-40, -80]],
		[7, P.exit, [50, -70]],
		[8, P.lane, [0, -80]],
	];
	if (NIGHT) callouts.push([9, P.footprints, [-60, 60]]);
	callouts.forEach(([n, p, off]) => {
		if (!p) return;
		const bx = p[0] + off[0];
		const by = p[1] + off[1];
		inner += line(p[0], p[1], bx, by, { sw: 6, stroke: "#FFFFFF" }) + line(p[0], p[1], bx, by, { sw: 3, stroke: UI.pink });
		inner += circle(p[0], p[1], 6, UI.pink, { sw: 3 });
		inner += circle(bx, by, 24, UI.pink, { sw: 4 }) + text(bx, by + 9, String(n), { anchor: "middle", size: 27, weight: 700, fill: "#fff" });
	});
	s += g(inner, { "clip-path": `url(#${id})` });
	s += rect(ax, ay, aw, ah, "none", { r: 28, sw: 5 });
	const notes = {
		items: [
			{ id: "1", text: "Conveyor belt shop: stock rides along the back wall. Walk up to it or use the Shop button." },
			{ id: "2", text: "8 starting pedestals in two rows of 4. The top colour shows rarity, hearts float above." },
			{ id: "3", text: "Locked pedestals for Extra Slots I, II and III (+2 each, up to 14). Dashed outline + price, so they're visible but not pushy." },
			{ id: "4", text: "Cash collector pad just inside the gate: walk over it to claim. Shows the pending amount." },
			{ id: "5", text: "Gate + your base sign. Day: open. Closing it fires laser bars for 15s (90s cooldown). Shields add a bubble on top." },
			{ id: "6", text: "4 defence sockets on the side walls. Day: empty “+” pads. Night: turret, sticky floor, repellent, and one destroyed (rebuilds at dawn)." },
			{ id: "7", text: "Side exit onto the escape lane, so a thief has one predictable way out for the owner to guard." },
			{ id: "8", text: "Escape lane: a short obby of floating blocks toward the neighbouring base." },
			...(NIGHT ? [{ id: "9", text: "Rotter clue: faint purple footprints near a sabotaged socket." }] : []),
			{ id: "Q7", q: true, text: "Should ferals be able to enter through the escape-lane exit, or only the gate? (Gate only = easier to defend for younger players.)" },
		],
		height: 790,
	};
	return pageFrame("Base layout", "One player's plot, about 48 x 40 studs, with numbered features", s, notes);
};

// ---------- Map overview (top-down) ----------
const BASE_COLORS = ["#4DA3FF", "#FF5C8A", "#3DDC84", "#FFB428", "#8B5CF6", "#FF8A3D", "#2EC4C4", "#E84DDB"];

PAGES.map = () => {
	const ax = 48;
	const ay = 130;
	const aw = 1460;
	const ah = 790;
	const cx = ax + 600;
	const cy = ay + ah / 2;
	const R_BASE = 262;
	const clip = uid("map");
	let m = "";
	// ground
	m += rect(ax, ay, aw, ah, L("#6CC94A"), { stroke: "none" });
	const r = rng(11);
	for (let i = 0; i < 260; i++) {
		const x = ax + r() * aw;
		const y = ay + r() * ah;
		const s = 30 + r() * 50;
		m += poly([[x, y], [x + s, y + r() * 20], [x + r() * 20, y + s]], L(["#7BD957", "#72D04E", "#84DE61"][i % 3]), { stroke: "none", opacity: 0.8 });
	}
	// outer fog ring = map edge
	const fog = uid("fog");
	m += `<defs><radialGradient id="${fog}" cx="${cx}" cy="${cy}" r="560" gradientUnits="userSpaceOnUse"><stop offset="0.78" stop-color="#5B2A86" stop-opacity="0"/><stop offset="1" stop-color="#5B2A86" stop-opacity="${NIGHT ? 0.85 : 0.35}"/></radialGradient></defs>`;
	m += rect(ax, ay, aw, ah, `url(#${fog})`, { stroke: "none" });
	// ring road + spokes
	m += circle(cx, cy, 172, "none", { sw: 30, stroke: L("#F2D9A0") });
	m += circle(cx, cy, 172, "none", { sw: 3, stroke: L("#D9BE84"), style: "stroke-dasharray:14 12" });
	const baseAng = (i) => ((i * 45 + 22.5 - 90) * Math.PI) / 180;
	for (let i = 0; i < 8; i++) {
		const a = baseAng(i);
		m += line(cx + Math.cos(a) * 172, cy + Math.sin(a) * 172, cx + Math.cos(a) * (R_BASE - 60), cy + Math.sin(a) * (R_BASE - 60), { sw: 26, stroke: L("#F2D9A0") });
	}
	// escape lanes between neighbouring bases (obby arcs)
	const laneR = R_BASE + 20;
	const laneColors = ["#FF5C8A", "#FFD23F", "#4DA3FF", "#3DDC84", "#8B5CF6"];
	for (let i = 0; i < 8; i++) {
		const a0 = baseAng(i) + 0.3;
		const a1 = baseAng(i + 1) - 0.3;
		const steps = 5;
		for (let k = 0; k <= steps; k++) {
			const a = a0 + ((a1 - a0) * k) / steps;
			const bx = cx + Math.cos(a) * laneR;
			const by = cy + Math.sin(a) * laneR;
			m += rect(bx - 13, by - 13, 26, 26, L(laneColors[(i + k) % 5]), { sw: 3, r: 5, transform: `rotate(${(a * 180) / Math.PI} ${bx} ${by})` });
		}
	}
	// plaza
	m += circle(cx, cy, 150, L("#EDE4D3"), { sw: 5 });
	for (let k = 0; k < 12; k++) {
		const a = (k * Math.PI) / 6;
		m += line(cx + Math.cos(a) * 70, cy + Math.sin(a) * 70, cx + Math.cos(a) * 148, cy + Math.sin(a) * 148, { sw: 2, stroke: L("#D8CDB6") });
	}
	m += circle(cx, cy, 62, L("#BFD9F2"), { sw: 4 }) + circle(cx, cy, 44, L("#4DA3FF"), { sw: 4 });
	m += creature("spinwhale", cx, cy + 22, 70, { mood: "happy" });
	// stage
	m += rect(cx - 70, cy - 140, 140, 50, L("#8B5CF6"), { sw: 4, r: 10 }) + text(cx, cy - 108, "STAGE", { anchor: "middle", size: 18, weight: 700, fill: "#fff" });
	// leaderboards
	for (let k = 0; k < 3; k++) m += rect(cx + 82 + k * 0, cy - 60 + k * 40, 56, 30, L("#2A2752"), { sw: 3, r: 5 }) + rect(cx + 88, cy - 54 + k * 40, 44, 4, ["#FFD23F", "#FF3B5C", "#3DDC84"][k], { stroke: "none" });
	m += text(cx + 110, cy + 80, "BOARDS", { anchor: "middle", size: 13, weight: 700, fill: L("#2A2752") });
	// trade booths
	for (const [dx, dy] of [[-120, -20], [-120, 30]]) m += rect(cx + dx, cy + dy, 50, 36, L("#FFF4E0"), { sw: 3, r: 4 }) + path(`M${cx + dx - 4},${cy + dy} L${cx + dx + 25},${cy + dy - 18} L${cx + dx + 54},${cy + dy}Z`, L("#3DDC84"), { sw: 3 });
	m += text(cx - 95, cy + 86, "TRADE", { anchor: "middle", size: 13, weight: 700, fill: L("#2A2752") });
	// VIP lounge
	m += rect(cx - 40, cy + 98, 80, 40, L("#FFE27A"), { sw: 3, r: 8 }) + text(cx, cy + 124, "VIP", { anchor: "middle", size: 16, weight: 700 });
	if (NIGHT) m += glow(cx, cy, 200, "#FFE88A", 0.35);
	// bases
	for (let i = 0; i < 8; i++) {
		const a = baseAng(i);
		const bx = cx + Math.cos(a) * R_BASE;
		const by = cy + Math.sin(a) * R_BASE;
		const rot = (a * 180) / Math.PI + 90;
		let b = "";
		b += rect(-56, -50, 112, 100, L("#E9E2CF"), { sw: 4, r: 10 });
		b += rect(-56, -50, 112, 100, "none", { sw: 7, r: 10, stroke: L(BASE_COLORS[i]) });
		b += rect(-56, -50, 112, 100, "none", { sw: 3, r: 10 });
		b += rect(-44, -42, 88, 10, L("#3A3F55"), { stroke: "none", r: 3 });
		for (let r2 = 0; r2 < 2; r2++) for (let c2 = 0; c2 < 4; c2++) b += rect(-40 + c2 * 22, -22 + r2 * 20, 14, 14, L(lighten(BASE_COLORS[i], 0.4)), { sw: 2.5, r: 3 });
		b += rect(-14, 44, 28, 12, L("#FF8A3D"), { sw: 3, r: 3 });
		b += rect(-14, 22, 28, 14, L("#FFD23F"), { sw: 2.5, r: 3 });
		m += g(b, { transform: `translate(${bx},${by}) rotate(${rot})` });
		if (NIGHT) m += glow(bx, by, 90, "#FFE88A", 0.25);
		const lx = cx + Math.cos(a) * (R_BASE + 96);
		const ly = cy + Math.sin(a) * (R_BASE + 96);
		const you = i === 0;
		m += chip(lx - (you ? 40 : 46), ly - 16, you ? "YOU" : `Base ${i + 1}`, you ? UI.pink : BASE_COLORS[i], { size: 16, w: you ? 80 : 92 });
	}
	// example raid route: from base 3 back to YOU (base 1) via escape lanes
	const routeA = [];
	for (let k = 0; k <= 24; k++) {
		const a = baseAng(2) - ((baseAng(2) - baseAng(0)) * k) / 24;
		routeA.push([cx + Math.cos(a) * (laneR + 36), cy + Math.sin(a) * (laneR + 36)]);
	}
	m += path("M" + routeA.map((p) => p.join(",")).join(" L"), "none", { sw: 8, stroke: "#FFFFFF", style: "stroke-dasharray:4 14" });
	const end = routeA[routeA.length - 1];
	m += circle(end[0], end[1], 10, "#FFFFFF", { sw: 3 });
	const mid = routeA[12];
	m += g(rect(-118, -22, 236, 44, "#FFFFFF", { r: 22, sw: 3.5 }) + text(0, 8, "escape run: +1 speed/sec", { anchor: "middle", size: 18, weight: 700 }), { transform: `translate(${cx + R_BASE + 200},${mid[1] + 40})` });
	// feral dens (map edge, between bases)
	const dens = [0, 90, 180, 270].map((d) => (d - 90) * (Math.PI / 180));
	dens.forEach((a, i) => {
		const dx = cx + Math.cos(a) * 445;
		const dy = cy + Math.sin(a) * 318;
		let d = "";
		if (NIGHT) d += glow(dx, dy, 110, "#B15CFF", 0.7);
		d += ellipse(dx, dy, 52, 34, NIGHT ? "#2A0F2E" : L("#5A5560"), { sw: 4 });
		d += path(`M${dx - 30},${dy} C${dx - 30},${dy - 22} ${dx + 26},${dy - 26} ${dx + 24},${dy} C${dx + 22},${dy + 16} ${dx - 10},${dy + 18} ${dx - 10},${dy + 2}`, "none", { sw: 4, stroke: NIGHT ? "#C78CFF" : L("#8A8494") });
		m += d;
		if (NIGHT) {
			// arrows toward the two nearest bases
			for (const off of [-0.39, 0.39]) {
				const ta = a + off;
				const tx = cx + Math.cos(ta) * (R_BASE + 70);
				const ty = cy + Math.sin(ta) * (R_BASE + 70);
				m += line(dx, dy, tx, ty, { sw: 7, stroke: "#B15CFF", style: "stroke-dasharray:16 10" });
				const ang = Math.atan2(ty - dy, tx - dx);
				m += g(poly([[0, -12], [22, 0], [0, 12]], "#B15CFF", { sw: 3 }), { transform: `translate(${tx},${ty}) rotate(${(ang * 180) / Math.PI})` });
				m += sprite(feralArt(), (dx + tx) / 2, (dy + ty) / 2 + 18, 48);
			}
		}
		m += chip(dx - 74, dy + 40, NIGHT ? "FERAL DEN" : "DEN · SLEEPING", NIGHT ? UI.purple : "#8A8494", { size: 14, w: 148 });
	});
	if (NIGHT) {
		const a = baseAng(5);
		const bx = cx + Math.cos(a) * R_BASE;
		const by = cy + Math.sin(a) * R_BASE;
		m += g(rect(-112, -20, 224, 40, UI.red, { r: 20, sw: 3.5 }) + text(0, 7, "LEAST DEFENDED: TARGETED", { anchor: "middle", size: 15, weight: 700, fill: "#fff" }), { transform: `translate(${bx},${by - 80})` });
		m += rect(ax, ay, aw, ah, "#0B0D2A", { stroke: "none", opacity: 0.12 });
	}
	// legend box
	const lgx = ax + aw - 300;
	const lgy = ay + ah - 254;
	const lfill = NIGHT ? "#1E1C3D" : "#FFFFFF";
	const lfg = NIGHT ? "#fff" : INK;
	m += rect(lgx, lgy, 276, 230, lfill, { r: 18, sw: 3.5 });
	m += text(lgx + 18, lgy + 36, "Legend", { size: 22, weight: 700, fill: lfg });
	const leg = [
		[rect(0, -10, 34, 20, "#F2D9A0", { sw: 2.5, r: 4 }), "Walkway (no obstacles)"],
		[rect(0, -10, 16, 20, "#FF5C8A", { sw: 2.5, r: 3 }) + rect(18, -10, 16, 20, "#FFD23F", { sw: 2.5, r: 3 }), "Escape lane (obby)"],
		[line(0, 0, 34, 0, { sw: 6, stroke: "#B9B9B9", style: "stroke-dasharray:4 8" }), "Example raid route"],
		[ellipse(17, 0, 17, 11, "#2A0F2E", { sw: 2.5 }), "Feral den (night spawns)"],
		[rect(0, -10, 34, 20, "#E9E2CF", { sw: 2.5, r: 4 }), "Player base (8)"],
	];
	leg.forEach(([icon, label], i) => {
		m += g(icon, { transform: `translate(${lgx + 18},${lgy + 70 + i * 34})` });
		m += text(lgx + 64, lgy + 76 + i * 34, label, { size: 16, weight: 700, font: FONT_BODY, fill: lfg });
	});
	let s = `<defs><clipPath id="${clip}"><rect x="${ax}" y="${ay}" width="${aw}" height="${ah}" rx="28"/></clipPath></defs>`;
	s += g(m, { "clip-path": `url(#${clip})` });
	s += rect(ax, ay, aw, ah, "none", { r: 28, sw: 5 });
	const notes = {
		items: [
			{ id: "MAP-1", text: "Central plaza: fountain, event stage, 3 leaderboards (richest, most loyal, best Rotter catcher), trade booths, VIP lounge." },
			{ id: "MAP-2", text: "8 bases in a ring, gates facing the plaza. A walkway spoke from each gate to the ring road." },
			{ id: "MAP-3", text: "Escape lanes are obby arcs between neighbouring bases. A thief runs the lanes back home while picking up +1 speed per second of movement." },
			{ id: "MAP-4", text: "4 feral dens at the map edge, between bases. Asleep by day; at night each sends waves to its two nearest bases, starting with the least defended." },
			{ id: "MAP-5", text: "Purple fog marks the playable edge. About 600 x 600 studs, so any base is under 30 s from the plaza." },
			{ id: "Q8", q: true, text: "Can a thief also cut through the plaza (shorter but crowded with defenders), or only use the lanes? I'd allow it: more drama." },
			{ id: "Q9", q: true, text: "Fixed base spots, or let players pick a free base when they join? (Fixed is simpler; picking is friendlier.)" },
		],
	};
	return pageFrame("Map overview", "Top-down · 8 bases around the central plaza", s, notes);
};

// ---------- Overview sheet ----------
PAGES.overview = () => {
	const rows = [
		["01-hud", "HUD", 960],
		["02-shop", "Conveyor shop", 960],
		["03-inspect", "Brainrot inspect panel", 960],
		["04-base", "Base layout", 960],
		["05-map", "Map overview", 960],
		["06-concept", "Brainrot concept sheet", 1420],
	];
	const W = 2160;
	const colW = 1020;
	const gap = 40;
	let y = 150;
	let s = rect(0, 0, W, 10, "#F4EFE6", { stroke: "none" });
	let body = "";
	body += text(48, 70, "ROT SHIFT", { size: 34, weight: 700, fill: UI.pink, ls: 2 });
	body += text(262, 70, "Phase 1 mockups · overview", { size: 44, weight: 700 });
	body += text(48, 112, "Left: day lighting · Right: night lighting. Full-size images are in assets/mockups/.", { size: 22, weight: 600, font: FONT_BODY, opacity: 0.7 });
	for (const [file, label, h] of rows) {
		const th = (h / 2160) * colW;
		body += text(48, y + 34, label, { size: 30, weight: 700 });
		y += 52;
		["day", "night"].forEach((m, i) => {
			const x = 48 + i * (colW + gap);
			body += rect(x + 4, y + 8, colW, th, "#000", { r: 16, stroke: "none", opacity: 0.15 });
			body += `<image href="../../assets/mockups/${file}-${m}.png" x="${x}" y="${y}" width="${colW}" height="${th}" preserveAspectRatio="xMidYMid slice"/>`;
			body += rect(x, y, colW, th, "none", { r: 16, sw: 3 });
		});
		y += th + 40;
	}
	const H = y + 20;
	s = rect(0, 0, W, H, "#F4EFE6", { stroke: "none" }) + body;
	return { svg: s, width: W, height: H };
};
