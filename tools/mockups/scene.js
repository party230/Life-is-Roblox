// Isometric base diorama, avatar and feral sprites. Shared by HUD, shop, inspect and base-layout pages.

// ---------- sprites (200x200 box, feet at y≈190) ----------
function avatarArt(o = {}) {
	let s = "";
	s += ellipse(100, 190, 46, 9, "#000", { stroke: "none", opacity: 0.2 });
	s += rect(70, 130, 26, 58, C("#3B4A8C"), { sw: 5, r: 4 });
	s += rect(104, 130, 26, 58, C("#33427E"), { sw: 5, r: 4 });
	s += rect(66, 180, 30, 12, C("#2A2752"), { sw: 4, r: 4 });
	s += rect(104, 180, 30, 12, C("#2A2752"), { sw: 4, r: 4 });
	s += rect(40, 74, 24, 60, C("#FF8A3D"), { sw: 5, r: 6 });
	s += rect(136, 74, 24, 60, C("#E8762E"), { sw: 5, r: 6 });
	s += rect(62, 70, 76, 66, C("#FF8A3D"), { sw: 5, r: 8 });
	s += path("M102,70 L138,70 L138,136 L102,136 Z", C("#E8762E"), { stroke: "none" });
	s += rect(62, 70, 76, 66, "none", { sw: 5, r: 8 });
	s += rect(84, 104, 32, 18, C("#FFD23F"), { sw: 3.5, r: 4 });
	s += rect(42, 128, 20, 16, C("#FFD9B0"), { sw: 4, r: 5 });
	s += rect(138, 128, 20, 16, C("#FFD9B0"), { sw: 4, r: 5 });
	s += rect(68, 14, 64, 58, C("#FFD9B0"), { sw: 5, r: 10 });
	s += path("M104,14 L122,14 C128,14 132,18 132,24 L132,62 C132,68 128,72 122,72 L104,72 Z", C("#F2C495"), { stroke: "none" });
	s += rect(68, 14, 64, 58, "none", { sw: 5, r: 10 });
	s += path("M64,28 C64,4 136,4 136,28 Z", C("#4DA3FF"), { sw: 5 });
	s += rect(60, 24, 52, 9, C("#3A86D9"), { sw: 4, r: 4 });
	s += circle(88, 44, 4.5, INK, { stroke: "none" }) + circle(112, 44, 4.5, INK, { stroke: "none" });
	s += path("M88,56 Q100,64 112,56", "none", { sw: 4 });
	if (o.hammer) s += g(ICON.hammer(), { transform: "translate(170,110) scale(1.5) rotate(-20)" });
	if (o.carry) s += creature(o.carry, 100, 70, 120, { mood: o.carryMood || "uneasy" });
	return s;
}

function feralArt(o = {}) {
	let s = "";
	s += ellipse(100, 190, 60, 10, "#000", { stroke: "none", opacity: 0.25 });
	const body = "M30,186 C20,150 30,96 64,74 C84,62 116,62 136,74 C170,96 180,150 170,186 L156,174 L144,188 L128,176 L114,188 L100,176 L86,188 L72,176 L58,188 L44,174 Z";
	s += path(body, "#5B2A86", { stroke: "none" });
	s += path("M118,66 C150,78 176,120 170,186 L156,174 L144,188 L128,176 C150,150 150,100 118,66 Z", "#47206B", { stroke: "none" });
	s += path(body, "none", { sw: 5 });
	s += path("M56,84 L46,58 L72,74 Z M144,84 L154,58 L128,74 Z", "#5B2A86", { sw: 4 });
	s += glow(78, 116, 34, "#C6FF3D", 0.55) + glow(122, 116, 34, "#C6FF3D", 0.55);
	s += ellipse(78, 116, 14, 11, "#C6FF3D", { sw: 3.5 }) + ellipse(122, 116, 14, 11, "#C6FF3D", { sw: 3.5 });
	s += circle(80, 118, 4.5, INK, { stroke: "none" }) + circle(120, 118, 4.5, INK, { stroke: "none" });
	s += path("M76,142 L124,142 L118,156 L82,156 Z", "#2A0F2E", { sw: 4 });
	s += path("M80,143 l5,7 l5,-7 l5,7 l5,-7 l5,7 l5,-7 l5,7 l5,-7", "#FFFFFF", { sw: 2 });
	return s;
}

function treeArt(seed = 1) {
	const r = rng(seed);
	const h = 0.85 + r() * 0.3;
	let s = "";
	s += rect(90, 150, 20, 40, C("#8A5A34"), { sw: 4, r: 3 });
	const tiers = [[100, 40 * h, 150], [100, 80 * h, 120], [100, 116 * h, 90]];
	s += poly([[38, 160], [162, 160], [100, 60 * h]], C("#3FAF5A"), { sw: 5 });
	s += poly([[100, 160], [162, 160], [100, 60 * h]], C("#33974B"), { stroke: "none" });
	s += poly([[38, 160], [162, 160], [100, 60 * h]], "none", { sw: 5 });
	s += poly([[54, 112], [146, 112], [100, 20 * h]], C("#4CC468"), { sw: 5 });
	s += poly([[100, 112], [146, 112], [100, 20 * h]], C("#3FAF5A"), { stroke: "none" });
	s += poly([[54, 112], [146, 112], [100, 20 * h]], "none", { sw: 5 });
	void tiers;
	return s;
}

function sprite(art, x, y, size, o = {}) {
	const k = size / 200;
	const flip = o.flip ? " translate(200,0) scale(-1,1)" : "";
	return g(art, { transform: `translate(${x - 100 * k},${y - 190 * k}) scale(${k})${flip}` });
}

// ---------- the base ----------
const PLOT = { w: 48, d: 40 };

// Pedestal layout: 8 starting slots, 6 more unlocked by Extra Slots I/II/III.
const PEDESTALS = [
	{ x: 8, y: 11 }, { x: 17, y: 11 }, { x: 26, y: 11 }, { x: 35, y: 11 },
	{ x: 8, y: 18 }, { x: 17, y: 18 }, { x: 26, y: 18 }, { x: 35, y: 18 },
	{ x: 8, y: 25, lock: "I" }, { x: 17, y: 25, lock: "I" }, { x: 26, y: 25, lock: "II" }, { x: 35, y: 25, lock: "II" },
	{ x: 8, y: 31, lock: "III" }, { x: 35, y: 31, lock: "III" },
];

// Brainrots on the 8 unlocked pedestals (index-aligned).
const RESIDENTS = [
	{ id: "mugpup", loyalty: 88 },
	{ id: "fridgehog", loyalty: 86, mutation: "Golden" },
	{ id: "kettlephant", loyalty: 14, stolen: true },
	{ id: "owlarm", loyalty: 70 },
	{ id: "toasturtle", loyalty: 60 },
	{ id: "lampingo", loyalty: 95 },
	{ id: "sockodile", loyalty: 41 },
	{ id: "brollybun", loyalty: 75 },
];

function moodFor(r) {
	if (r.stolen && r.loyalty < 30) return "uneasy";
	if (r.loyalty >= 80) return "happy";
	return "content";
}

function grass(cam, x0, y0, x1, y1, step, seed) {
	const r = rng(seed);
	const jit = {};
	const J = (i, j) => {
		const k = i + "," + j;
		if (!jit[k]) jit[k] = [(r() - 0.5) * step * 0.5, (r() - 0.5) * step * 0.5];
		return jit[k];
	};
	const base = ["#7BD957", "#72D04E", "#84DE61", "#6CC94A"];
	let s = "";
	for (let i = 0; x0 + i * step < x1; i++) {
		for (let j = 0; y0 + j * step < y1; j++) {
			const P = (a, b) => {
				const jj = J(i + a, j + b);
				return iso(cam, x0 + (i + a) * step + jj[0], y0 + (j + b) * step + jj[1], 0);
			};
			const c1 = base[Math.floor(r() * 4)];
			const c2 = base[Math.floor(r() * 4)];
			s += poly([P(0, 0), P(1, 0), P(1, 1)], L(c1), { stroke: L(c1), sw: 1 });
			s += poly([P(0, 0), P(1, 1), P(0, 1)], L(c2), { stroke: L(c2), sw: 1 });
		}
	}
	return s;
}

function baseScene(cam, o = {}) {
	const night = NIGHT;
	const P = (x, y, z = 0) => iso(cam, x, y, z);
	const sz = (units) => units * cam.s;
	const items = []; // { depth, svg }
	const overlay = []; // drawn above everything (hearts, tags)
	const glows = [];
	const pts = {};
	const add = (depth, svg) => items.push({ depth, svg });

	let s = "";
	s += rect(-2000, -2000, 6000, 6000, L("#6CC94A"), { stroke: "none" });
	s += grass(cam, -60, -60, 120, 120, 7, 7);

	// Plaza path toward the left (front-left edge) and escape lane to the right.
	s += quad(cam, 20, 40, 0.05, 8, 60, "#F2D9A0", { sw: 3 });
	// escape lane: floating obby blocks heading +x from the right-wall gap
	const laneColors = ["#FF5C8A", "#FFD23F", "#4DA3FF", "#3DDC84", "#8B5CF6"];
	for (let i = 0; i < 6; i++) {
		const lx = 50 + i * 6.5;
		add(lx + 18 - 0.1, box(cam, lx, 15, 0, 4.5, 6, 0.8 + (i % 2) * 0.6, laneColors[i % 5], { sw: 3 }));
		if (i % 2 === 0) add(lx + 18, poly([P(lx + 1.5, 17, 1.6), P(lx + 3.3, 18, 1.6), P(lx + 1.5, 19, 1.6)], L("#FFFFFF"), { sw: 2.5 }));
	}
	pts.lane = P(56, 18, 2);

	// Platform
	s += box(cam, 0, 0, 0, PLOT.w, PLOT.d, 1, "#E9E2CF", { top: "#F4EEDD" });
	let grid = "";
	for (let x = 4; x < PLOT.w; x += 4) grid += `M${P(x, 0, 1).join(",")} L${P(x, PLOT.d, 1).join(",")} `;
	for (let y = 4; y < PLOT.d; y += 4) grid += `M${P(0, y, 1).join(",")} L${P(PLOT.w, y, 1).join(",")} `;
	s += path(grid, "none", { sw: 1.5, stroke: L("#DDD3BB") });

	// Back walls
	const wallC = "#4DA3FF";
	add(0, box(cam, 0, -1, 1, PLOT.w, 1, 1.6, wallC));
	add(0, box(cam, -1, -1, 1, 1, PLOT.d + 1, 1.6, wallC));
	// right wall with escape-lane gap (y 14..22)
	add(PLOT.w + 7, box(cam, PLOT.w, -1, 1, 1, 15, 1.6, wallC));
	add(PLOT.w + 40, box(cam, PLOT.w, 22, 1, 1, 18, 1.6, wallC));
	pts.exit = P(PLOT.w, 18, 3);
	if (night) {
		// Lane exits seal at Dusk: translucent barrier across the gap.
		const seal = [P(PLOT.w + 0.5, 14, 1), P(PLOT.w + 0.5, 22, 1), P(PLOT.w + 0.5, 22, 5), P(PLOT.w + 0.5, 14, 5)];
		add(PLOT.w + 22.5, poly(seal, "#7FD3FF", { sw: 3.5, opacity: 0.55 }) + path(`M${P(PLOT.w + 0.5, 15, 2).join(",")} L${P(PLOT.w + 0.5, 21, 4).join(",")} M${P(PLOT.w + 0.5, 15, 4).join(",")} L${P(PLOT.w + 0.5, 21, 2).join(",")}`, "none", { sw: 3, stroke: "#FFFFFF", opacity: 0.8 }));
		glows.push(glow(...P(PLOT.w, 18, 3), sz(6), "#7FD3FF", 0.4));
		overlay.push(chip(...P(PLOT.w + 2, 18, 7).map((v, i) => v - (i === 0 ? 50 : 0)), "SEALED", "#3A86D9", { size: 14, w: 100 }));
	}
	// front wall with gate gap (x 18..30)
	add(18 + 40, box(cam, -1, PLOT.d, 1, 19, 1, 1.6, wallC));
	add(PLOT.w + 40, box(cam, 30, PLOT.d, 1, 19, 1, 1.6, wallC));

	// Conveyor shop belt along the back
	add(3, box(cam, 5, 2, 1, 38, 4.5, 1, "#3A3F55", { top: "#4A5070" }));
	let chev = "";
	for (let x = 8; x < 42; x += 4) chev += `M${P(x, 2.8, 2).join(",")} L${P(x + 1.4, 4.25, 2).join(",")} L${P(x, 5.7, 2).join(",")} `;
	add(3.5, path(chev, "none", { sw: 3, stroke: L("#FFD23F") }));
	add(3.6, box(cam, 3.5, 1.5, 1, 1.5, 5.5, 1.6, "#FFD23F"));
	add(46, box(cam, 43, 1.5, 1, 1.5, 5.5, 1.6, "#FFD23F"));
	const belt = o.belt || [
		{ id: "toasturtle", price: "$55" },
		{ id: "lampingo", price: "$210" },
		{ id: "mugpup", price: "$48" },
		{ id: "cartshark", price: "$5.2K" },
	];
	belt.forEach((b, i) => {
		const bx = 10 + i * 8.5;
		const [sx, sy] = P(bx, 4.2, 2);
		add(bx + 4.5, sprite(creatureArt(b.id, { mood: "content" }), sx, sy, sz(4.2)));
		overlay.push(chip(sx - 30, sy - sz(4.6) - 8, b.price, UI.green, { size: 14, w: 60 }));
	});
	pts.belt = P(24, 4, 3);

	// Pedestals
	PEDESTALS.forEach((p, i) => {
		const depth = p.x + p.y + 5;
		if (p.lock) {
			const [lx, ly] = P(p.x + 2.5, p.y + 2.5, 1.05);
			add(depth - 1, quad(cam, p.x + 0.5, p.y + 0.5, 1.02, 4, 4, "#E2D9C3", { sw: 3, style: "stroke-dasharray:8 6" }));
			add(depth, g(rect(-14, -10, 28, 22, "#8A93A8", { sw: 3, r: 5 }) + path("M-8,-10 L-8,-16 C-8,-24 8,-24 8,-16 L8,-10", "none", { sw: 4 }), { transform: `translate(${lx},${ly - 8}) scale(${cam.s / 16})` }));
			pts["ped" + i] = [lx, ly];
			if (o.lockTags !== false) overlay.push(chip(lx - 44, ly + 4, `+${p.lock}`, UI.green, { size: 13, w: 40 }) + chip(lx - 2, ly + 4, "R$149", "#2BB673", { size: 13, w: 56 }));
			return;
		}
		const res = RESIDENTS[i];
		const knocked = night && o.knockout === i;
		const rc = RARITY[SPECIES[res.id].rarity];
		add(depth, box(cam, p.x + 0.5, p.y + 0.5, 1, 4, 4, 1.3, knocked ? "#9AA0AD" : "#F7F3EA", { top: knocked ? "#B4B9C4" : lighten(rc, 0.45) }));
		const [cx, cy] = P(p.x + 2.5, p.y + 2.5, 2.3);
		if (night && !knocked) glows.push(glow(cx, cy - 10, sz(3.6), rc === "#141414" ? "#8B5CF6" : rc, 0.35));
		const mood = knocked ? "sleepy" : moodFor(res);
		add(depth + 0.5, sprite(creatureArt(res.id, { mood, mutation: res.mutation }), cx, cy + sz(0.4), sz(7)));
		if (o.hearts !== false) overlay.push(heartMeter(cx, cy - sz(7.2), res.loyalty, { stolen: res.stolen, scale: Math.min(0.8, cam.s / 22) }));
		if (knocked) overlay.push(chip(cx - 62, cy - sz(8.8), "INCOME PAUSED", "#8A93A8", { size: 13, w: 124 }));
		pts["ped" + i] = [cx, cy];
	});
	pts.pedestals = P(22, 16, 2);
	pts.locked = P(22, 28, 2);

	// Cash collector pad (front, inside the gate)
	add(19 + 33, box(cam, 19, 32.5, 1, 10, 5, 0.45, "#FFD23F", { top: "#FFE27A" }));
	const [px, py] = P(24, 35, 1.5);
	add(19 + 34, text(px, py + 6, "$", { anchor: "middle", size: sz(2.6), weight: 700, fill: L("#C98A00") }));
	if (night) glows.push(glow(px, py, sz(6), "#FFD23F", 0.5));
	overlay.push(g(rect(-58, -26, 116, 44, "#FFFFFF", { r: 22, sw: 4 }) + g(ICON.coin(13), { transform: "translate(-34,-4)" }) + text(14, 6, o.collector || "$1,240", { anchor: "middle", size: 24, weight: 700, fill: "#2BB673" }), { transform: `translate(${px + sz(4)},${py - sz(3.2)})` }));
	pts.collector = [px, py];

	// Gate pillars + laser
	add(17 + 41, box(cam, 16.5, PLOT.d - 0.5, 1, 2, 2, 6, "#3A86D9"));
	add(31 + 41, box(cam, 29.5, PLOT.d - 0.5, 1, 2, 2, 6, "#3A86D9"));
	add(31 + 41.1, box(cam, 16.5, PLOT.d - 0.5, 7, 15, 2, 1.2, "#FF8A3D"));
	const gateClosed = o.gateClosed === undefined ? night : o.gateClosed;
	if (gateClosed) {
		let las = "";
		for (const z of [2, 3.5, 5]) las += `M${P(18.5, PLOT.d + 0.5, z).join(",")} L${P(29.5, PLOT.d + 0.5, z).join(",")} `;
		add(31 + 41.2, path(las, "none", { sw: 5, stroke: "#FF3B3B" }) + path(las, "none", { sw: 2, stroke: "#FFD0D0" }));
		if (night) glows.push(glow(...P(24, PLOT.d, 3.5), sz(7), "#FF3B3B", 0.45));
	}
	const [gx, gy] = P(24, PLOT.d + 1, 7.6);
	pts.gate = [gx, gy];
	add(31 + 41.3, text(gx, gy + 8, "TOASTY TOWERS", { anchor: "middle", size: sz(1.05), weight: 700, fill: "#FFFFFF", outline: INK, ow: 5 }));

	// Defence sockets (hex pads)
	const sockets = [
		{ x: 2.5, y: 11, kind: night ? "turret" : "turret" },
		{ x: 45.5, y: 11, kind: night ? "sticky" : "empty" },
		{ x: 2.5, y: 31, kind: night ? "repel" : "empty" },
		{ x: 45.5, y: 31, kind: night ? "broken" : "sticky" },
	];
	sockets.forEach((k, i) => {
		const [hx, hy] = P(k.x, k.y, 1.05);
		const hex = [];
		for (let a = 0; a < 6; a++) {
			const t = (a * Math.PI) / 3;
			hex.push(P(k.x + Math.cos(t) * 2, k.y + Math.sin(t) * 2, 1.05));
		}
		let sv = poly(hex, L("#C7CDD9"), { sw: 3 });
		if (k.kind === "empty") sv += text(hx, hy + 8, "+", { anchor: "middle", size: sz(2), weight: 700, fill: L("#8A93A8") });
		if (k.kind === "turret") {
			sv += box(cam, k.x - 1, k.y - 1, 1, 2, 2, 1.6, "#8A93A8");
			sv += g(ICON.turret(), { transform: `translate(${hx},${hy - sz(2.6)}) scale(${cam.s / 22})` });
			if (night) sv += path(`M${hx + sz(1.5)},${hy - sz(3.5)} l14,-6 M${hx + sz(1.6)},${hy - sz(2.8)} l16,0 M${hx + sz(1.5)},${hy - sz(2.1)} l14,6`, "none", { sw: 3.5, stroke: "#FFFFFF" });
		}
		if (k.kind === "sticky") sv += isoEllipse(cam, k.x, k.y, 1.1, 2.6, L("#7CFF6B"), { sw: 3, opacity: 0.85 });
		if (k.kind === "repel") {
			sv += rect(hx - sz(0.5), hy - sz(2.4), sz(1), sz(2.2), L("#8B5CF6"), { sw: 3, r: 3 });
			sv += isoEllipse(cam, k.x, k.y, 1.1, 4.5, "none", { sw: 3, stroke: "#B79CFF", style: "stroke-dasharray:6 6" });
		}
		if (k.kind === "broken") {
			sv += poly([P(k.x - 1, k.y, 1.1), P(k.x, k.y - 1, 1.6), P(k.x + 1, k.y + 0.5, 1.1)], L("#8A93A8"), { sw: 3 });
			overlay.push(chip(hx - 70, hy - sz(3.5), "REBUILDS AT DAWN", "#8A93A8", { size: 12, w: 140 }));
		}
		add(k.x + k.y + 2, sv);
		pts["socket" + i] = [hx, hy];
	});

	// Lamps
	for (const [lx, ly] of [[-1, PLOT.d], [PLOT.w, PLOT.d], [PLOT.w, -1], [-1, -1]]) {
		add(lx + ly + 1.5, box(cam, lx - 0.3, ly - 0.3, 1, 1, 1, 5, "#3A3F55") + box(cam, lx - 0.7, ly - 0.7, 6, 1.8, 1.8, 1.2, night ? "#FFE88A" : "#FFF4E0"));
		if (night) glows.push(glow(...P(lx + 0.2, ly + 0.2, 6.5), sz(8), "#FFE88A", 0.55));
	}

	// Trees around
	const trees = [[-8, 6], [-9, 22], [-7, 36], [10, -9], [30, -10], [44, -8], [56, 4], [58, 32], [-6, 48], [40, 50], [66, 40]];
	trees.forEach(([tx, ty], i) => {
		const [x, y] = P(tx, ty, 0);
		add(tx + ty, sprite(treeArt(i + 3), x, y, sz(8)));
	});

	// Avatar
	if (o.avatar !== false) {
		const av = o.avatarAt || [24, 29];
		const [ax, ay] = P(av[0], av[1], 1);
		add(av[0] + av[1] + 0.8, sprite(avatarArt({ hammer: night, carry: o.carry }), ax, ay, sz(6)));
		if (o.avatarName !== false) overlay.push(text(ax, ay - sz(6.4), o.avatarName || "You", { anchor: "middle", size: 18, weight: 700, fill: "#FFFFFF", outline: INK, ow: 5 }));
		pts.avatar = [ax, ay];
	}

	// Night: ferals + Rotter clue footprints
	if (night && o.ferals !== false) {
		const ferals = o.feralsAt || [[27, 46], [33, 49], [40, 21.5], [56, 44]];
		ferals.forEach(([fx, fy]) => {
			const [x, y] = P(fx, fy, fx < PLOT.w && fy < PLOT.d ? 1 : 0);
			add(fx + fy + 0.9, sprite(feralArt(), x, y, sz(4.4)));
		});
		let prints = "";
		for (let i = 0; i < 6; i++) {
			const [x, y] = P(5 + i * 1.6, 34 - i * 1.2 + (i % 2) * 0.6, 1.05);
			prints += ellipse(x, y, sz(0.35), sz(0.22), "#B15CFF", { stroke: "none", opacity: 0.85 });
		}
		add(30, prints);
		pts.footprints = P(9, 31, 1);
	}

	items.sort((a, b) => a.depth - b.depth);
	s += items.map((i) => i.svg).join("");
	if (night) {
		const vid = uid("vig");
		s += `<defs><radialGradient id="${vid}" cx="50%" cy="45%" r="75%"><stop offset="0.35" stop-color="#0B0D2A" stop-opacity="0"/><stop offset="1" stop-color="#0B0D2A" stop-opacity="0.7"/></radialGradient></defs>`;
		s += `<rect x="${o.vx || 0}" y="${o.vy || 0}" width="${o.vw || 1440}" height="${o.vh || 664}" fill="url(#${vid})"/>`;
		s += `<g style="mix-blend-mode:screen">${glows.join("")}</g>`;
	}
	return { svg: s, overlay: overlay.join(""), pts };
}
