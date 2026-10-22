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
		? [[UI.blue, ICON.shield(), "Defend"], [UI.orange, ICON.base(), "Base"]]
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
			{ id: "HUD-2", text: "6 buttons max. Day: Shop, Eggs, Base on the left; Trade, Store, Menu top-right. Night (5): Defend, Base, Store, Menu + a big BONK button. Belt, eggs and trade close at night; defences are bought from Defend." },
			{ id: "HUD-3", text: "One alert toast at a time under the timer. Tapping it jumps the camera to that brainrot." },
			{ id: "HUD-4", text: "Ghosted controls (thumbstick, jump, top-left menu/chat) are Roblox's own and don't count toward the 6." },
			{ id: "HUD-5", text: "Buttons are 84px here, about 48pt on a phone, above Apple's 44pt minimum." },
			{ id: "HUD-6", text: "Over each brainrot: hearts only, no numbers. Purple, cracked and shaking = uneasy. The mask icon = stolen." },
			{ id: "HUD-7", text: "Camera: normal third-person follow cam (this view is an illustration), with a zoom-out cap so you can't scout the whole map." },
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
	const closed = NIGHT;
	scr += panel(px, py, pw, ph);
	scr += header(px + 300, py - 34, 460, "CONVEYOR SHOP", closed ? "#8A93A8" : UI.pink);
	scr += closeButton(px + pw - 10, py + 4);
	if (closed) {
		scr += text(px + 34, py + 74, "Belt stopped for the night", { size: 22, weight: 700, font: FONT_BODY, fill: fg });
	} else {
		scr += text(px + 34, py + 74, "New stock in", { size: 22, weight: 600, font: FONT_BODY, fill: fg });
		scr += chip(px + 170, py + 50, "0:42", UI.blue, { size: 20, w: 82 });
	}
	scr += text(px + pw - 34, py + 74, "6 / 8 pedestals used", { anchor: "end", size: 22, weight: 600, font: FONT_BODY, fill: fg });
	// belt
	const by = py + 104;
	scr += rect(px + 20, by + 18, pw - 40, 300, "#3A3F55", { r: 18, sw: 4.5 });
	for (let x = px + 50; x < px + pw - 40; x += 46) scr += path(`M${x},${by + 330} l14,10 l-14,10`, "none", { sw: 4, stroke: "#FFD23F", opacity: closed ? 0.25 : 0.8 });
	scr += rect(px + 20, by + 322, pw - 40, 36, "#2B2F42", { r: 12, sw: 4 });
	const cards = [
		{ id: "toasturtle", price: "$55", inc: "+$1.0/s", pay: "Pays back in 1m", sold: true },
		{ id: "lampingo", price: "$210", inc: "+$2.6/s", pay: "Pays back in 2m" },
		{ id: "fridgehog", price: "$1,050", inc: "+$6/s", pay: "Pays back in 3m" },
		{ id: "cartshark", price: "$5,200", inc: "+$15/s", pay: "Pays back in 6m", isNew: true },
		{ id: "pianoceros", price: "$26K", inc: "+$40/s", pay: "Pays back in 11m", poor: true },
	];
	cards.forEach((c, i) => {
		const def = SPECIES[c.id];
		const cx = px + 40 + i * 200;
		const cy = by;
		const rc = RARITY[def.rarity];
		scr += rect(cx + 4, cy + 8, 182, 300, "#000", { r: 20, stroke: "none", opacity: 0.25 });
		scr += rect(cx, cy, 182, 300, "#FFFFFF", { r: 20, sw: 4.5 });
		scr += rect(cx + 10, cy + 10, 162, 132, lighten(rc, 0.7), { r: 14, stroke: "none" });
		scr += ellipse(cx + 91, cy + 130, 50, 9, "#000", { stroke: "none", opacity: 0.15 });
		scr += creature(c.id, cx + 91, cy + 134, 124, { mood: closed ? "sleepy" : "happy" });
		scr += rarityChip(cx + 12, cy + 14, def.rarity, { size: 13 });
		scr += text(cx + 91, cy + 170, def.name, { anchor: "middle", size: 24, weight: 700 });
		scr += text(cx + 91, cy + 196, c.inc, { anchor: "middle", size: 21, weight: 700, fill: "#2BB673" });
		scr += text(cx + 91, cy + 218, c.pay, { anchor: "middle", size: 15, weight: 700, font: FONT_BODY, fill: "#6B7285" });
		if (closed) {
			scr += button(cx + 14, cy + 228, 154, 62, "#A8AFBF", { label: "Dawn", size: 24 });
		} else if (c.sold) {
			scr += button(cx + 14, cy + 228, 154, 62, "#A8AFBF", { label: "SOLD", size: 24 });
			scr += rect(cx, cy, 182, 300, "#FFFFFF", { r: 20, stroke: "none", opacity: 0.45 });
		} else if (c.poor) {
			scr += button(cx + 14, cy + 228, 154, 62, "#A8AFBF", { label: "Need $13.5K", size: 19 });
		} else {
			scr += button(cx + 14, cy + 228, 154, 62, UI.green, { label: c.price, size: 26 });
		}
		if (c.isNew && !closed) {
			scr += g(poly([[0, -26], [8, -9], [26, -9], [12, 3], [17, 22], [0, 11], [-17, 22], [-12, 3], [-26, -9], [-8, -9]], UI.yellow, { sw: 3.5 }) + text(0, 6, "NEW", { anchor: "middle", size: 12, weight: 700 }), { transform: `translate(${cx + 168},${cy + 10}) rotate(12)` });
		}
	});
	if (closed) {
		scr += rect(px + 20, by + 18, pw - 40, 300, "#0B0A1E", { r: 18, stroke: "none", opacity: 0.45 });
		scr += g(
			rect(-300, -70, 600, 140, "#FFFFFF", { r: 26, sw: 5 }) +
				g(ICON.moon(22), { transform: "translate(-244,-18)" }) +
				text(-206, -12, "Closed for the night", { size: 34, weight: 700 }) +
				text(-206, 22, "Opens at dawn in 2:43 · eggs keep hatching", { size: 19, weight: 700, font: FONT_BODY, fill: "#6B7285" }),
			{ transform: `translate(${px + pw / 2},${by + 120})` },
		);
		scr += button(px + pw / 2 - 150, by + 236, 300, 70, UI.blue, { label: "Open Defend menu", size: 24 });
	} else {
		// server-wide plaza drop banner
		scr += g(
			rect(0, 0, 640, 54, UI.yellow, { r: 27, sw: 4.5 }) +
				g(sparkle(0, 0, 14, "#FFFFFF"), { transform: "translate(32,27)" }) +
				text(58, 35, "PLAZA DROP: Legendary Pianoceros · first to buy wins", { size: 19, weight: 700 }) +
				chip(560, 10, "0:45", UI.red, { size: 16, w: 66 }),
			{ transform: `translate(${px + 210},${py + ph - 60})` },
		);
	}
	// odds footer
	scr += g(ICON.info(), { transform: `translate(${px + 54},${py + ph - 33})` });
	scr += text(px + 80, py + ph - 26, closed ? "Belt odds" : "Odds", { size: 19, weight: 700, font: FONT_BODY, fill: fg });
	if (closed) scr += text(px + 180, py + ph - 26, "Common 70% · Uncommon 22% · Rare 6% · Epic 1.6% · Legendary 0.35% · Mythic 0.05%", { size: 18, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.7 });
	const notes = {
		items: [
			{ id: "SHOP-1", text: "Your own belt: 5 cards, new stock every minute. A modal over the dimmed base; cash and the timer stay visible." },
			{ id: "SHOP-2", text: "Each card: rarity, income/s, and a plain payback line (“Pays back in 2m”). No maths on screen." },
			{ id: "SHOP-3", text: "States: buyable (green), can't afford (grey + how much more), sold, NEW sticker, and night (“Dawn”)." },
			{ id: "SHOP-4", text: "Odds sit behind the “i” (tap to expand). At night the full odds line shows, since there's nothing to buy." },
			{ id: "SHOP-5", text: "Plaza drop (day): every few minutes a Rare+ appears on the plaza belt for the whole server. Everyone gets this banner, and the first to buy it at the plaza wins. Tapping the banner points the way." },
			{ id: "SHOP-6", text: "Night: the belt stops and cards sleep. A button jumps to the Defend menu, where defences stay buyable." },
		],
	};
	return pageFrame("Conveyor shop", closed ? "Night: belt and eggs closed" : "Day: your belt plus the server-wide plaza drop", phone(scr), notes);
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
	// Bond Collar: small, quiet button for Rare+ or stolen brainrots (no pop-ups)
	scr += g(
		rect(0, 0, 186, 44, NIGHT ? "#1E1C3D" : "#FFFFFF", { r: 22, sw: 3.5 }) +
			g(ICON.robux(), { transform: "translate(24,22) scale(0.55)" }) +
			text(46, 29, "Bond Collar", { size: 18, weight: 700, fill: fg }) +
			text(170, 29, "199", { anchor: "end", size: 14, weight: 700, font: FONT_BODY, fill: "#2BB673" }),
		{ transform: `translate(${ix + 460},${py + 96})` },
	);
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
			{ id: "INS-6", text: "The exact loyalty number appears only here. In the world it's hearts only." },
			{ id: "INS-7", text: "Bond Collar: a small button for Rare+ or stolen brainrots only. Tapping it opens the Store page. No pop-ups, no reminders. Once owned, it says “Collar on (1/2)”." },
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
	if (NIGHT) callouts.push([9, P.footprints, [-20, -120]]);
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
			{ id: "7", text: "Side exit onto the escape lane, so a thief has one predictable way out for the owner to guard. Seals at Dusk (night: blue barrier)." },
			{ id: "8", text: "Escape lane: a short obby of floating blocks toward the neighbouring base." },
			...(NIGHT ? [{ id: "9", text: "Rotter clue: faint purple footprints near a sabotaged socket." }] : []),
			{ id: "10", text: "Ferals only walk on open ground. They come through the gate, never along the obby lanes." },
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
			m += rect(bx - 13, by - 13, 26, 26, L(laneColors[(i + k) % 5]), { sw: 3, r: 5, opacity: NIGHT ? 0.35 : 1, transform: `rotate(${(a * 180) / Math.PI} ${bx} ${by})` });
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
	// plaza drop belt
	m += rect(cx - 138, cy - 78, 92, 26, L("#3A3F55"), { sw: 3.5, r: 6 });
	m += path(`M${cx - 126},${cy - 72} l8,7 l-8,7 M${cx - 106},${cy - 72} l8,7 l-8,7 M${cx - 86},${cy - 72} l8,7 l-8,7 M${cx - 66},${cy - 72} l8,7 l-8,7`, "none", { sw: 3, stroke: "#FFD23F" });
	m += text(cx - 92, cy - 40, "DROP BELT", { anchor: "middle", size: 13, weight: 700, fill: L("#2A2752") });
	if (!NIGHT) m += sparkle(cx - 146, cy - 82, 12, "#FFD23F");
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
	// plaza shortcut: base 3 -> spoke -> ring road -> YOU spoke (resets speed, brainrot glows)
	if (!NIGHT) {
		const sc = [];
		const a2 = baseAng(2);
		const a0 = baseAng(0);
		sc.push([cx + Math.cos(a2) * (R_BASE - 60), cy + Math.sin(a2) * (R_BASE - 60)]);
		for (let k = 0; k <= 16; k++) {
			const a = a2 + ((a0 - a2) * k) / 16;
			sc.push([cx + Math.cos(a) * 172, cy + Math.sin(a) * 172]);
		}
		sc.push([cx + Math.cos(a0) * (R_BASE - 60), cy + Math.sin(a0) * (R_BASE - 60)]);
		m += path("M" + sc.map((p) => p.join(",")).join(" L"), "none", { sw: 7, stroke: UI.orange, style: "stroke-dasharray:4 12" });
		m += g(rect(-170, -22, 340, 44, "#FFFFFF", { r: 22, sw: 3.5 }) + text(0, 8, "plaza shortcut: speed resets, it glows", { anchor: "middle", size: 17, weight: 700, fill: "#C2571A" }), {
			transform: `translate(${cx + R_BASE + 210},${cy + 150})`,
		});
	} else {
		m += g(rect(-140, -22, 280, 44, "#3A86D9", { r: 22, sw: 3.5 }) + text(0, 8, "LANE EXITS SEALED", { anchor: "middle", size: 18, weight: 700, fill: "#fff" }), {
			transform: `translate(${cx + R_BASE + 200},${cy - 60})`,
		});
	}
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
	m += rect(lgx, lgy - 34, 276, 264, lfill, { r: 18, sw: 3.5 });
	m += text(lgx + 18, lgy + 2, "Legend", { size: 22, weight: 700, fill: lfg });
	const leg = [
		[rect(0, -10, 34, 20, "#F2D9A0", { sw: 2.5, r: 4 }), "Walkway (no obstacles)"],
		[rect(0, -10, 16, 20, "#FF5C8A", { sw: 2.5, r: 3 }) + rect(18, -10, 16, 20, "#FFD23F", { sw: 2.5, r: 3 }), "Escape lane (obby)"],
		[line(0, 0, 34, 0, { sw: 6, stroke: "#B9B9B9", style: "stroke-dasharray:4 8" }), "Raid route via lanes"],
		[line(0, 0, 34, 0, { sw: 6, stroke: UI.orange, style: "stroke-dasharray:4 8" }), "Plaza shortcut"],
		[ellipse(17, 0, 17, 11, "#2A0F2E", { sw: 2.5 }), "Feral den (night spawns)"],
		[rect(0, -10, 34, 20, "#E9E2CF", { sw: 2.5, r: 4 }), "Player base (8)"],
	];
	leg.forEach(([icon, label], i) => {
		m += g(icon, { transform: `translate(${lgx + 18},${lgy + 36 + i * 32})` });
		m += text(lgx + 64, lgy + 42 + i * 32, label, { size: 16, weight: 700, font: FONT_BODY, fill: lfg });
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
			{ id: "MAP-6", text: "Plaza shortcut (orange): thieves may cut through the plaza, but it resets the +1 speed stack to base speed. The carried brainrot glows, and its owner gets an alert." },
			{ id: "MAP-7", text: "Plaza drop belt: the server-wide Rare+ drop appears here every few minutes. First to buy wins." },
			{ id: "MAP-8", text: "At Dusk every base's lane exit seals, so lanes go quiet at night. Ferals walk open ground only." },
			{ id: "MAP-9", text: "Players pick any free base when they join (see the base picker), so friends can sit side by side." },
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
		["07-picker", "Base picker", 960],
		["08-eggs", "Eggs", 960],
		["09-hatch", "Egg hatch animation", 960],
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

// ---------- Eggs ----------
const EGG_STYLE = {
	basic: { base: "#FFF4E0", band: "#4DA3FF", dots: ["#FF5C8A", "#3DDC84"] },
	fancy: { base: "#B98CFF", band: "#FFD23F", dots: ["#FFFFFF", "#FF5C8A"] },
	streak: { base: "#FFD23F", band: "#FF8A3D", dots: ["#FFFFFF", "#FFFFFF"] },
};

function eggArt(kind, cx, cy, h, o = {}) {
	const st = EGG_STYLE[kind];
	const k = h / 100;
	const id = uid("egg");
	const shape = "M0,-50 C30,-50 44,-6 42,16 C40,40 22,50 0,50 C-22,50 -40,40 -42,16 C-44,-6 -30,-50 0,-50 Z";
	let s = "";
	if (o.glow) s += glow(0, 0, 90, o.glow, 0.75);
	s += `<defs><clipPath id="${id}"><path d="${shape}"/></clipPath></defs>`;
	s += path(shape, C(st.base), { stroke: "none" });
	s += g(path("M-50,4 L-34,-8 L-18,4 L-2,-8 L14,4 L30,-8 L46,4 L46,18 L-50,18 Z", C(st.band), { stroke: "none" }) + ellipse(-16, -24, 7, 9, C(st.dots[0]), { stroke: "none" }) + ellipse(14, -30, 6, 7, C(st.dots[1]), { stroke: "none" }) + ellipse(18, 34, 7, 6, C(st.dots[0]), { stroke: "none" }) + path("M20,-50 C40,-30 46,10 30,46 L60,60 L60,-60 Z", "#000", { stroke: "none", opacity: 0.1 }), { "clip-path": `url(#${id})` });
	if (kind === "streak") s += path("M0,-22 L6,-8 L21,-8 L9,1 L13,16 L0,7 L-13,16 L-9,1 L-21,-8 L-6,-8 Z", "#FFFFFF", { sw: 3 });
	s += path(shape, "none", { sw: 5 });
	if (o.cracks) s += path("M-30,-14 L-16,-4 L-22,8 L-6,2 L2,14 L10,0 L24,6 L30,-6", "none", { sw: 4.5 });
	s += ellipse(-18, -30, 8, 14, "#FFFFFF", { stroke: "none", opacity: 0.45, transform: "rotate(20 -18 -30)" });
	return g(s, { transform: `translate(${cx},${cy}) rotate(${o.tilt || 0}) scale(${k})` });
}

PAGES.eggs = () => {
	let scr = dimmedSceneWithHud({ hearts: false });
	const px = 150;
	const py = 132;
	const pw = 1140;
	const ph = 512;
	const fg = NIGHT ? "#FFFFFF" : INK;
	const closed = NIGHT;
	scr += panel(px, py, pw, ph);
	scr += header(px + 380, py - 34, 380, "EGGS", closed ? "#8A93A8" : UI.yellow);
	scr += closeButton(px + pw - 10, py + 4);
	// shop side
	scr += text(px + 34, py + 76, closed ? "Egg shop closed at night" : "Buy an egg", { size: 24, weight: 700, fill: fg });
	const eggs = [
		{ kind: "basic", name: "Basic Egg", price: "$500", time: "Hatches in 30s", odds: [["Common", 60], ["Uncommon", 28], ["Rare", 9], ["Epic", 2.5], ["Legendary", 0.45], ["Mythic", 0.05]] },
		{ kind: "fancy", name: "Fancy Egg", price: "$10K", time: "Hatches in 2m", odds: [["Uncommon", 50], ["Rare", 32], ["Epic", 13], ["Legendary", 4], ["Mythic", 0.9], ["Secret", 0.1]], open: true },
	];
	eggs.forEach((e, i) => {
		const cx = px + 30 + i * 300;
		const cy = py + 100;
		scr += rect(cx, cy, 280, 380, NIGHT ? "#1E1C3D" : "#FFFFFF", { r: 22, sw: 4 });
		scr += eggArt(e.kind, cx + 140, cy + 88, 120);
		scr += text(cx + 140, cy + 180, e.name, { anchor: "middle", size: 28, weight: 700, fill: fg });
		scr += text(cx + 140, cy + 206, e.time, { anchor: "middle", size: 17, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.7 });
		// odds always visible (compact bar + list)
		let ox = cx + 20;
		const total = e.odds.reduce((a, [, w]) => a + w, 0);
		e.odds.forEach(([r, w]) => {
			const ww = Math.max(3, (w / total) * 240);
			scr += rect(ox, cy + 222, ww, 14, RARITY[r] === "#141414" ? "#8B5CF6" : RARITY[r], { stroke: "none" });
			ox += ww;
		});
		scr += rect(cx + 20, cy + 222, 240, 14, "none", { r: 4, sw: 2.5 });
		e.odds.slice(0, 6).forEach(([r, w], j) => {
			const tx = cx + 16 + (j % 2) * 128;
			const ty = cy + 260 + Math.floor(j / 2) * 22;
			scr += circle(tx + 6, ty - 5, 5.5, RARITY[r], { sw: 2 });
			scr += text(tx + 16, ty, `${r} ${w}%`, { size: 12.5, weight: 700, font: FONT_BODY, fill: fg });
		});
		scr += button(cx + 20, cy + 312, 240, 62, closed ? "#A8AFBF" : UI.green, { label: closed ? "Dawn" : e.price, size: 28 });
	});
	// incubators
	const ix = px + 640;
	scr += text(ix, py + 76, "Incubators", { size: 24, weight: 700, fill: fg });
	scr += text(ix + 470, py + 76, "2 / 3", { anchor: "end", size: 20, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.7 });
	const slots = [
		{ kind: "fancy", state: "ready" },
		{ kind: "basic", state: "timer", left: "0:12", pct: 0.6 },
		{ state: "empty" },
	];
	slots.forEach((sl, i) => {
		const sy = py + 100 + i * 128;
		scr += rect(ix, sy, 470, 112, NIGHT ? "#1E1C3D" : "#FFFFFF", { r: 20, sw: 4, stroke: sl.state === "ready" ? "#2BB673" : INK });
		if (sl.state === "empty") {
			scr += rect(ix + 18, sy + 16, 80, 80, "none", { r: 16, sw: 3, style: "stroke-dasharray:8 6" });
			scr += text(ix + 58, sy + 68, "+", { anchor: "middle", size: 40, weight: 700, fill: "#8A93A8" });
			scr += text(ix + 118, sy + 64, closed ? "Free slot · eggs back at dawn" : "Free slot · buy an egg", { size: 20, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.6 });
			return;
		}
		scr += eggArt(sl.kind, ix + 58, sy + 56, 82, { glow: sl.state === "ready" ? "#FFE27A" : null, tilt: sl.state === "ready" ? -8 : 0 });
		if (sl.state === "ready") {
			scr += text(ix + 118, sy + 46, "Fancy Egg is ready!", { size: 22, weight: 700, fill: fg });
			scr += button(ix + 118, sy + 56, 330, 50, UI.yellow, { label: "HATCH!", size: 26 });
		} else {
			scr += text(ix + 118, sy + 46, "Basic Egg", { size: 22, weight: 700, fill: fg });
			scr += rect(ix + 118, sy + 62, 250, 26, "#E2D9C8", { r: 13, sw: 3 });
			scr += rect(ix + 121, sy + 65, 244 * sl.pct, 20, UI.blue, { r: 10, stroke: "none" });
			scr += text(ix + 384, sy + 83, sl.left, { size: 22, weight: 700, fill: fg });
		}
	});
	const notes = {
		items: [
			{ id: "EGG-1", text: "Left: eggs for cash. Odds are always on the card as a colour bar plus a list, never hidden behind a tap." },
			{ id: "EGG-2", text: "Right: 3 incubators. Each shows a progress bar and the time left. A finished egg glows with a big HATCH! button." },
			{ id: "EGG-3", text: "Hatching plays the animation (next image) and the brainrot goes to a free pedestal, or to storage if the base is full." },
			{ id: "EGG-4", text: "Night: buying closes, but incubators keep running and you can still hatch." },
			{ id: "EGG-5", text: "Robux eggs (if we ever add them) use this same card with odds. They hide where PolicyService says paid random items are restricted." },
			{ id: "Q10", q: true, text: "3 incubators to start. Should more be buyable later (cash), or is 3 the cap?" },
		],
	};
	return pageFrame("Eggs", closed ? "Night: shop closed, incubators keep hatching" : "Buy, incubate, hatch", phone(scr), notes);
};

PAGES.hatch = () => {
	const fg = NIGHT ? "#FFFFFF" : INK;
	let s = "";
	const frames = [
		["0.0s", "Wobble", (cx, cy) => eggArt("fancy", cx, cy, 190, { tilt: -12 }) + path(`M${cx - 120},${cy - 40} l-20,-6 M${cx - 124},${cy} l-24,0 M${cx + 120},${cy - 40} l20,-6 M${cx + 124},${cy} l24,0`, "none", { sw: 5, stroke: fg })],
		["0.8s", "Crack + rarity light", (cx, cy) => {
			let r = "";
			for (let i = 0; i < 10; i++) {
				const a = (i * Math.PI) / 5;
				r += poly([[cx, cy], [cx + Math.cos(a - 0.12) * 220, cy + Math.sin(a - 0.12) * 220], [cx + Math.cos(a + 0.12) * 220, cy + Math.sin(a + 0.12) * 220]], RARITY.Epic, { stroke: "none", opacity: 0.35 });
			}
			return r + eggArt("fancy", cx, cy, 190, { cracks: true, glow: RARITY.Epic });
		}],
		["1.4s", "Pop!", (cx, cy) => {
			let r = glow(cx, cy, 200, "#FFFFFF", 0.95);
			const cr = rng(5);
			const cols = [UI.pink, UI.yellow, UI.blue, UI.green, UI.purple];
			for (let i = 0; i < 26; i++) r += rect(cx + (cr() - 0.5) * 380, cy + (cr() - 0.5) * 300, 14, 22, cols[i % 5], { sw: 2.5, transform: `rotate(${cr() * 180} ${cx} ${cy})` });
			r += path(`M${cx - 70},${cy + 60} l30,-40 l20,30 l25,-35 l20,30 l25,-30 l20,45 Z`, C("#B98CFF"), { sw: 4 });
			return r + creature("cartshark", cx, cy + 40, 180, { mood: "happy" });
		}],
		["1.8s", "Reveal card", (cx, cy) => {
			let r = rect(cx - 170, cy - 170, 340, 360, "#FFFFFF", { r: 26, sw: 5 });
			r += rect(cx - 156, cy - 156, 312, 190, lighten(RARITY.Epic, 0.65), { r: 18, stroke: "none" });
			r += creature("cartshark", cx, cy + 26, 180, { mood: "happy", mutation: "Rainbow" });
			r += rarityChip(cx - 150, cy - 150, "Epic", { size: 15 });
			r += chip(cx + 40, cy - 150, "RAINBOW x5", "#8B5CF6", { size: 15 });
			r += text(cx, cy + 74, "Cartshark!", { anchor: "middle", size: 34, weight: 700 });
			r += text(cx, cy + 102, "+$75/s · sent to pedestal 7", { anchor: "middle", size: 17, weight: 700, font: FONT_BODY, fill: "#2BB673" });
			r += button(cx - 110, cy + 120, 220, 60, UI.green, { label: "Nice!", size: 26 });
			return r;
		}],
	];
	const fw = 340;
	frames.forEach(([t, label, draw], i) => {
		const x = 48 + i * (fw + 22);
		const y = 140;
		s += rect(x, y, fw, 560, NIGHT ? "#1E1C3D" : "#FFFFFF", { r: 26, sw: 4 });
		s += g(rect(0, 0, fw, 560, NIGHT ? "#232A66" : "#FFF4E0", { r: 26, stroke: "none" }), { transform: `translate(${x},${y})`, opacity: 0.6 });
		s += `<g>${draw(x + fw / 2, y + 260)}</g>`;
		s += circle(x + 40, y + 40, 22, UI.pink, { sw: 3.5 }) + text(x + 40, y + 49, String(i + 1), { anchor: "middle", size: 24, weight: 700, fill: "#fff" });
		s += text(x + 72, y + 50, label, { size: 24, weight: 700, fill: fg });
		s += text(x + fw - 20, y + 50, t, { anchor: "end", size: 20, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.6 });
		if (i < 3) s += path(`M${x + fw + 6},${y + 280} l16,0 l-6,-8 M${x + fw + 22},${y + 280} l-6,8`, "none", { sw: 4, stroke: fg });
	});
	const notes = {
		items: [
			{ id: "HAT-1", text: "About 2 seconds total. Tap anywhere to skip straight to the reveal card." },
			{ id: "HAT-2", text: "The light colour in frame 2 is the rarity colour, so players learn rarity before they see the creature." },
			{ id: "HAT-3", text: "Mythic and Secret take 1s longer and get a server-wide announcement (no buyer name for cash hatches)." },
			{ id: "HAT-4", text: "Reveal card: name, rarity, mutation, income/s and where it went. One button closes it." },
			{ id: "HAT-5", text: "Reduced-motion setting: confetti and shakes turn off, colours stay." },
		],
	};
	return pageFrame("Egg hatch animation", "Storyboard · 4 beats", s, notes);
};

// ---------- Base picker (on join) ----------
PAGES.picker = () => {
	const bgScene = baseScene(hudCam(), { lockTags: false, hearts: false, avatar: false });
	let scr = bgScene.svg + rect(0, 0, SW, SH, "#0B0A1E", { stroke: "none", opacity: 0.6 });
	const fg = NIGHT ? "#FFFFFF" : INK;
	const cx = SW / 2;
	const cy = 352;
	scr += header(cx - 230, 18, 460, "PICK YOUR BASE", UI.blue);
	scr += g(rect(0, 0, 230, 46, "#FFFFFF", { r: 23, sw: 4 }) + text(115, 31, "Auto-pick in 0:07", { anchor: "middle", size: 21, weight: 700 }), { transform: `translate(${SW - 280},26)` });
	// plaza
	scr += circle(cx, cy, 92, L("#EDE4D3"), { sw: 5 });
	scr += circle(cx, cy, 36, L("#4DA3FF"), { sw: 4 });
	scr += text(cx, cy + 70, "PLAZA", { anchor: "middle", size: 18, weight: 700, fill: L("#2A2752") });
	const owners = [null, "Mia", "RotLord99", null, "Kai", null, "Zed", "BunnyQueen"];
	const friends = { Mia: true };
	for (let i = 0; i < 8; i++) {
		const a = ((i * 45 + 22.5 - 90) * Math.PI) / 180;
		const bx = cx + Math.cos(a) * 330;
		const by = cy + Math.sin(a) * 182;
		const owner = owners[i];
		const w = 176;
		const h = 100;
		const x = bx - w / 2;
		const y = by - h / 2;
		const nextToFriend = !owner && (friends[owners[(i + 1) % 8]] || friends[owners[(i + 7) % 8]]);
		if (owner) {
			scr += rect(x, y, w, h, NIGHT ? "#2A2752" : "#E9E2CF", { r: 18, sw: 4, stroke: BASE_COLORS[i] });
			scr += circle(x + 40, y + 46, 24, "#FFD9B0", { sw: 3.5 });
			scr += rect(x + 22, y + 24, 36, 12, BASE_COLORS[i], { sw: 3, r: 5 });
			scr += circle(x + 33, y + 48, 3, INK, { stroke: "none" }) + circle(x + 47, y + 48, 3, INK, { stroke: "none" });
			scr += text(x + 74, y + 54, owner, { size: owner.length > 7 ? 18 : 22, weight: 700, fill: fg });
			if (friends[owner]) scr += chip(x + 74, y + 66, "FRIEND", UI.yellow, { size: 13, w: 74 });
			else scr += text(x + 74, y + 82, "taken", { size: 16, weight: 700, font: FONT_BODY, fill: fg, opacity: 0.5 });
		} else {
			if (nextToFriend) scr += glow(bx, by, 120, UI.yellow, 0.55);
			scr += rect(x, y, w, h, "#FFFFFF", { r: 18, sw: 4, stroke: nextToFriend ? "#E6A800" : INK, style: "stroke-dasharray:10 6" });
			scr += button(x + 18, y + 18, w - 36, 62, UI.green, { label: "PICK", size: 28 });
			if (nextToFriend) scr += chip(x + 14, y + h - 14, "next to Mia", UI.yellow, { size: 14, w: w - 28 });
		}
	}
	scr += g(rect(0, 0, 520, 46, "#FFFFFF", { r: 23, sw: 4 }) + text(260, 31, "Tap a free spot. Friends glow yellow.", { anchor: "middle", size: 20, weight: 700, font: FONT_BODY }), { transform: `translate(${cx - 260},${SH - 62})` });
	if (NIGHT) scr += g(rect(0, 0, 330, 64, "#2A2752", { r: 20, sw: 4 }) + g(ICON.shield(), { transform: "translate(36,32) scale(0.8)" }) + text(70, 28, "Joining at night?", { size: 18, weight: 700, fill: "#fff" }) + text(70, 50, "Shielded until dawn", { size: 16, weight: 700, font: FONT_BODY, fill: "#BFD9F2" }), { transform: "translate(30,100)" });
	const notes = {
		items: [
			{ id: "PICK-1", text: "Shown on join, over the dimmed world. A ring of the 8 plots around the plaza, same layout as the real map." },
			{ id: "PICK-2", text: "Taken plots show the owner's name. Friends get a FRIEND tag, and free plots next to a friend glow yellow." },
			{ id: "PICK-3", text: "One tap on PICK claims it, no confirm step. The server re-checks it's still free; if someone beat you to it, the ring refreshes." },
			{ id: "PICK-4", text: "Countdown: if you don't pick within 10s, you get a free plot automatically, next to a friend if possible." },
			{ id: "Q11", q: true, text: "Joining during the night is rough: no defences yet. I'd shield a new arrival's base until dawn (shown on the night version). OK?" },
		],
	};
	return pageFrame("Base picker", "On join · pick any free plot", phone(scr), notes);
};
