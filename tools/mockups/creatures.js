// Brainrot species: everyday object + animal + face. Each draw() works in a 200x200 box, feet at y≈190.
// Moods: happy | content | uneasy (stolen, low loyalty) | rogue (hostile at night) | sleepy.

const C = (c) => L(c);

function face(x, y, s, mood, o = {}) {
	const sp = (o.spacing || 20) * s;
	const er = (o.eye || 12) * s;
	let out = "";
	for (const side of [-1, 1]) {
		const ex = x + side * sp;
		if (mood === "sleepy") {
			out += path(`M${ex - er},${y} Q${ex},${y + er * 0.9} ${ex + er},${y}`, "none", { sw: 4 });
			continue;
		}
		if (mood === "rogue") {
			out += ellipse(ex, y, er, er * 1.05, "#2A0F2E", { sw: 4 });
			out += ellipse(ex, y + er * 0.2, er * 0.62, er * 0.42, "#FF3B3B", { stroke: "none" });
			out += ellipse(ex - er * 0.15, y + er * 0.1, er * 0.2, er * 0.14, "#FFD0D0", { stroke: "none" });
			out += path(`M${ex + side * er * 1.15},${y - er * 1.65} L${ex - side * er * 0.95},${y - er * 0.75}`, "none", { sw: 5 });
			continue;
		}
		out += ellipse(ex, y, er, er * 1.15, "#FFFFFF", { sw: 4 });
		let px = 0;
		let py = er * 0.18;
		let pr = er * 0.56;
		if (mood === "uneasy") {
			px = -er * 0.42;
			py = -er * 0.05;
			pr = er * 0.36;
		}
		out += circle(ex + px, y + py, pr, INK, { stroke: "none" });
		out += circle(ex + px + pr * 0.38, y + py - pr * 0.42, pr * 0.36, "#FFFFFF", { stroke: "none" });
		if (mood === "uneasy") {
			out += path(`M${ex + side * er * 1.05},${y - er * 1.3} L${ex - side * er * 0.85},${y - er * 1.85}`, "none", { sw: 4.5 });
		}
	}
	if (!o.noMouth) {
		const mx = o.mouthX === undefined ? x : o.mouthX;
		const my = y + er * 1.55 + (o.mouthDy || 0) * s;
		const m = 11 * s * (o.mouthScale || 1);
		if (mood === "happy") {
			out += path(`M${mx - m},${my} Q${mx},${my + m * 1.5} ${mx + m},${my} Z`, "#8A1F3A", { sw: 3.5 });
			out += path(`M${mx - m * 0.45},${my + m * 0.55} Q${mx},${my + m * 1.1} ${mx + m * 0.45},${my + m * 0.55}`, "#FF6F91", { stroke: "none" });
		} else if (mood === "content") {
			out += path(`M${mx - m * 0.8},${my} Q${mx},${my + m * 0.9} ${mx + m * 0.8},${my}`, "none", { sw: 4 });
		} else if (mood === "uneasy") {
			const q = m * 0.5;
			out += path(`M${mx - m},${my + 4} q${q / 2},${-q} ${q},0 t${q},0 t${q},0 t${q},0`, "none", { sw: 4 });
		} else if (mood === "rogue") {
			out += path(`M${mx - m},${my - 2} L${mx + m},${my - 2} L${mx + m * 0.8},${my + m * 0.9} L${mx - m * 0.8},${my + m * 0.9} Z`, "#2A0F2E", { sw: 3.5 });
			out += path(`M${mx - m * 0.8},${my - 1} l${m * 0.4},${m * 0.5} l${m * 0.4},${-m * 0.5} l${m * 0.4},${m * 0.5} l${m * 0.4},${-m * 0.5}`, "#FFFFFF", { sw: 2 });
		} else if (mood === "sleepy") {
			out += ellipse(mx, my + 2, m * 0.35, m * 0.3, "#8A1F3A", { sw: 3 });
		}
	}
	if ((mood === "happy" || mood === "content") && !o.noBlush) {
		out += ellipse(x - sp - er * 0.3, y + er * 1.35, er * 0.55, er * 0.3, "#FF8FB1", { stroke: "none", opacity: 0.75 });
		out += ellipse(x + sp + er * 0.3, y + er * 1.35, er * 0.55, er * 0.3, "#FF8FB1", { stroke: "none", opacity: 0.75 });
	}
	return out;
}

// Body fill + flat facet (no stroke) + outline on top: the low-poly two-tone look.
function faceted(d, base, facetD, facetColor) {
	return path(d, C(base), { stroke: "none" }) + path(facetD, C(facetColor || darken(base, 0.12)), { stroke: "none" }) + path(d, "none", { sw: 5 });
}

const SPECIES = {
	mugpup: {
		name: "Mugpup",
		rarity: "Common",
		blurb: "Wags its handle so hard it spills. Every single time.",
		fx: { sweat: [158, 70], bubble: [30, 30] },
		draw: (mood) => {
			let s = "";
			s += path("M144,92 C186,86 190,154 144,152 L144,134 C166,136 166,108 144,110 Z", C("#F2E6D0"), { sw: 5 });
			s += faceted("M54,70 L146,70 L140,182 L60,182 Z", "#FFF4E0", "M112,70 L146,70 L140,182 L120,182 Z", "#EADCC2");
			s += path("M57,148 L143,148 L142,164 L58,164 Z", C("#FF5C8A"), { sw: 4 });
			s += path("M64,92 C74,86 84,94 80,106 C76,116 64,112 62,104 Z", C("#C98A55"), { stroke: "none", opacity: 0.85 });
			s += ellipse(100, 70, 47, 12, C("#FFF4E0"), { sw: 5 });
			s += ellipse(100, 70, 38, 7.5, C("#6B3E1F"), { sw: 3 });
			s += path("M58,72 C34,66 22,104 32,130 C38,142 54,132 58,114 Z", C("#B5763C"), { sw: 5 });
			s += path("M142,72 C160,66 170,96 164,118 C160,130 146,124 142,110 Z", C("#B5763C"), { sw: 5 });
			s += ellipse(80, 186, 15, 7, C("#B5763C"), { sw: 4 });
			s += ellipse(120, 186, 15, 7, C("#B5763C"), { sw: 4 });
			s += face(100, 112, 1, mood, { spacing: 21, eye: 12, mouthDy: 8 });
			s += ellipse(100, 126, 6.5, 4.5, INK, { stroke: "none" });
			return s;
		},
	},
	toasturtle: {
		name: "Toasturtle",
		rarity: "Common",
		blurb: "Pops out toast when startled. Is startled constantly.",
		fx: { sweat: [26, 100], bubble: [10, 50] },
		draw: (mood) => {
			let s = "";
			for (const [x, y] of [[66, 184], [92, 188], [128, 188], [154, 184]]) s += ellipse(x, y, 13, 9, C("#6BC46B"), { sw: 4 });
			s += rect(72, 34, 30, 56, C("#E8B86D"), { sw: 5, r: 10 });
			s += rect(78, 40, 18, 40, C("#F6D9A0"), { stroke: "none", r: 6 });
			s += rect(112, 28, 30, 62, C("#E8B86D"), { sw: 5, r: 10, transform: "rotate(8 127 60)" });
			s += rect(118, 34, 18, 44, C("#F6D9A0"), { stroke: "none", r: 6, transform: "rotate(8 127 60)" });
			s += rect(50, 78, 116, 98, C("#CFD8E3"), { stroke: "none", r: 24 });
			s += path("M128,78 L142,78 C156,78 166,88 166,102 L166,152 C166,166 156,176 142,176 L118,176 Z", C("#B3BFCD"), { stroke: "none" });
			s += path("M86,112 L100,104 L114,112 L114,128 L100,136 L86,128 Z M114,112 L128,104 L142,112 L142,128 L128,136 L114,128", "none", { sw: 3, stroke: C("#8E9BB0") });
			s += rect(50, 78, 116, 98, "none", { sw: 5, r: 24 });
			s += rect(68, 80, 38, 9, C("#3A3F55"), { sw: 3, r: 4 });
			s += rect(110, 80, 38, 9, C("#3A3F55"), { sw: 3, r: 4 });
			s += rect(164, 112, 16, 9, C("#FF5C8A"), { sw: 3.5, r: 3 });
			s += path("M18,150 C10,120 30,104 50,110 L62,124 L58,160 C44,170 24,166 18,150 Z", C("#7BD957"), { sw: 5 });
			s += face(38, 132, 0.72, mood, { spacing: 13, eye: 10, mouthDy: 2 });
			return s;
		},
	},
	sockodile: {
		name: "Sockodile",
		rarity: "Common",
		blurb: "Escaped the dryer. Still holds a grudge against laundry day.",
		fx: { sweat: [100, 100], bubble: [10, 60] },
		draw: (mood) => {
			let s = "";
			const d = "M178,96 L178,166 C178,180 168,188 154,188 L50,188 C22,188 12,172 16,158 C20,142 36,136 56,136 L122,136 L122,96 Z";
			s += path(d, C("#F7F4EE"), { stroke: "none" });
			for (const x of [66, 94]) s += rect(x, 136, 13, 52, C("#FF4D4D"), { stroke: "none" });
			for (const y of [110, 134, 158]) s += rect(122, y, 56, 11, C("#FF4D4D"), { stroke: "none" });
			s += path("M140,96 L178,96 L178,166 C178,180 168,188 154,188 L140,188 Z", "#000", { stroke: "none", opacity: 0.08 });
			s += path(d, "none", { sw: 5 });
			s += rect(116, 82, 68, 20, C("#FF4D4D"), { sw: 5, r: 7 });
			s += path("M128,86 L128,98 M140,86 L140,98 M152,86 L152,98 M164,86 L164,98 M176,86 L176,98", "none", { sw: 2.5 });
			s += path("M16,164 L70,164", "none", { sw: 4 });
			s += path("M22,164 l5,8 l5,-8 l5,8 l5,-8 l5,8 l5,-8 l5,8 l5,-8 l5,8", C("#FFFFFF"), { sw: 2.5 });
			s += circle(26, 150, 2.6, INK, { stroke: "none" });
			s += circle(34, 148, 2.6, INK, { stroke: "none" });
			s += circle(54, 132, 16, C("#7BD957"), { sw: 5 });
			s += circle(86, 132, 16, C("#7BD957"), { sw: 5 });
			s += face(70, 130, 0.8, mood, { spacing: 20, eye: 11, noMouth: true, noBlush: true });
			if (mood === "happy" || mood === "content") s += path("M70,164 Q82,170 92,160", "none", { sw: 4 });
			for (const x of [44, 82, 132, 160]) s += rect(x - 7, 184, 14, 8, C("#6BC46B"), { sw: 3.5, r: 3 });
			return s;
		},
	},
	lampingo: {
		name: "Lampingo",
		rarity: "Uncommon",
		blurb: "Balances on one leg and lights up whenever it has an idea.",
		fx: { sweat: [150, 36], bubble: [150, 10] },
		draw: (mood) => {
			let s = "";
			if (NIGHT) s += glow(100, 96, 70, "#FFE88A", 0.55);
			s += path("M104,140 L100,186 M100,186 L88,190 M100,186 L112,190", "none", { sw: 9 });
			s += path("M104,140 L100,186", "none", { sw: 4.5, stroke: C("#FF8FB1") });
			s += path("M140,108 L172,96 L164,126 Z", C("#FF6F9C"), { sw: 5 });
			s += ellipse(112, 122, 44, 28, C("#FF8FB1"), { sw: 5 });
			s += path("M96,114 C112,104 136,108 146,122 C130,132 110,134 96,114 Z", C("#FF6F9C"), { sw: 4 });
			s += path("M82,108 L62,66 L94,36", "none", { sw: 15 });
			s += path("M82,108 L62,66 L94,36", "none", { sw: 8, stroke: C("#9AA3B5") });
			s += circle(62, 66, 8, C("#6E7890"), { sw: 4 });
			s += path("M84,8 L128,22 L142,74 L70,56 Z", C("#FFD23F"), { stroke: "none" });
			s += path("M110,16 L128,22 L142,74 L112,66 Z", C("#F2B92A"), { stroke: "none" });
			s += path("M84,8 L128,22 L142,74 L70,56 Z", "none", { sw: 5 });
			s += path("M70,56 Q104,80 142,74", NIGHT ? "#FFF6C2" : C("#FFF1A8"), { sw: 4 });
			s += path("M72,52 L48,66 L60,74 Z", C("#2A2752"), { sw: 4 });
			s += path("M72,52 L58,60 L64,64 Z", C("#FF8FB1"), { stroke: "none" });
			s += face(106, 38, 0.72, mood, { spacing: 14, eye: 10, mouthDy: -1 });
			return s;
		},
	},
	brollybun: {
		name: "Brollybun",
		rarity: "Uncommon",
		blurb: "Opens its ears when it rains. Refuses to go anywhere when it doesn't.",
		fx: { sweat: [150, 100], bubble: [20, 20] },
		draw: (mood) => {
			let s = "";
			s += path("M150,150 L152,176 C152,192 174,192 172,176", "none", { sw: 12 });
			s += path("M150,150 L152,176 C152,192 174,192 172,176", "none", { sw: 6, stroke: C("#B5763C") });
			s += ellipse(100, 162, 48, 30, C("#FFFFFF"), { sw: 5 });
			s += ellipse(76, 188, 17, 7, C("#FFFFFF"), { sw: 4 });
			s += ellipse(124, 188, 17, 7, C("#FFFFFF"), { sw: 4 });
			for (const x of [80, 120]) {
				s += ellipse(x, 36, 11, 30, C("#FFFFFF"), { sw: 5, transform: `rotate(${x < 100 ? -12 : 12} ${x} 36)` });
				s += ellipse(x, 38, 5, 20, C("#FFB3C8"), { stroke: "none", transform: `rotate(${x < 100 ? -12 : 12} ${x} 38)` });
			}
			s += circle(100, 116, 40, C("#FFFFFF"), { sw: 5 });
			const canopy = "M42,98 C48,50 152,50 158,98 Q144,90 129,98 Q114,90 100,98 Q86,90 71,98 Q57,90 42,98 Z";
			s += path(canopy, C("#4DA3FF"), { stroke: "none" });
			s += path("M100,58 C92,70 88,84 86,94 Q93,90 100,98 Q107,90 114,94 C112,84 108,70 100,58 Z", C("#FFD23F"), { stroke: "none" });
			s += path("M100,58 C70,62 56,80 50,94 Q57,90 64,94 C70,80 84,66 100,58 Z", C("#FFD23F"), { stroke: "none" });
			s += path("M100,58 C130,62 144,80 150,94 Q143,90 136,94 C130,80 116,66 100,58 Z", C("#FFD23F"), { stroke: "none" });
			s += path(canopy, "none", { sw: 5 });
			s += circle(100, 56, 6, C("#B5763C"), { sw: 3.5 });
			s += face(100, 122, 0.85, mood, { spacing: 17, eye: 11, mouthDy: 6 });
			s += path("M95,128 L105,128 L100,134 Z", C("#FF8FB1"), { sw: 2.5 });
			return s;
		},
	},
	fridgehog: {
		name: "Fridgehog",
		rarity: "Rare",
		blurb: "Collects fridge magnets as spikes. Gives very cold hugs.",
		fx: { sweat: [168, 120], bubble: [6, 20] },
		draw: (mood) => {
			let s = "";
			const mags = ["#FF4D4D", "#FFD23F", "#4DA3FF", "#3DDC84", "#FF5C8A", "#8B5CF6"];
			let i = 0;
			for (let x = 58; x <= 140; x += 16) s += poly([[x, 44], [x + 16, 44], [x + 8, 18 + (i % 2) * 6]], C(mags[i++ % 6]), { sw: 4 });
			for (let y = 54; y <= 160; y += 18) s += poly([[146, y], [146, y + 18], [172 - (i % 2) * 5, y + 9]], C(mags[i++ % 6]), { sw: 4 });
			s += rect(52, 40, 96, 146, C("#C9F2E3"), { stroke: "none", r: 16 });
			s += path("M120,40 L132,40 C141,40 148,47 148,56 L148,170 C148,179 141,186 132,186 L120,186 Z", C("#A9DCC9"), { stroke: "none" });
			s += rect(52, 40, 96, 146, "none", { sw: 5, r: 16 });
			s += line(52, 86, 148, 86, { sw: 4 });
			s += rect(132, 54, 7, 22, C("#8A93A8"), { sw: 3, r: 3 });
			s += rect(132, 96, 7, 34, C("#8A93A8"), { sw: 3, r: 3 });
			s += path(HEART, C("#FF5C8A"), { sw: 3, transform: "translate(80,62) scale(0.8)" });
			s += path("M58,120 L30,130 L58,142 Z", C("#E9C9A5"), { sw: 4 });
			s += circle(30, 130, 6, INK, { stroke: "none" });
			s += face(98, 118, 0.95, mood, { spacing: 19, eye: 12, mouthDy: 6 });
			s += ellipse(72, 190, 13, 6, C("#8A6A50"), { sw: 3.5 });
			s += ellipse(128, 190, 13, 6, C("#8A6A50"), { sw: 3.5 });
			return s;
		},
	},
	kettlephant: {
		name: "Kettlephant",
		rarity: "Rare",
		blurb: "Whistles when it's happy. Steams when it's ignored.",
		fx: { sweat: [170, 92], bubble: [160, 14] },
		draw: (mood) => {
			let s = "";
			s += path("M70,76 C70,30 130,30 130,76", "none", { sw: 14 });
			s += path("M70,76 C70,30 130,30 130,76", "none", { sw: 7, stroke: C("#2E3B4E") });
			for (const side of [-1, 1]) {
				const t = side < 0 ? "" : "translate(200,0) scale(-1,1)";
				s += g(path("M64,82 C14,58 0,126 26,146 C40,156 58,140 64,124 Z", C("#5FC3C8"), { sw: 5 }) + path("M58,92 C28,78 20,122 34,134 C44,140 54,128 58,118 Z", C("#FFB3C8"), { stroke: "none" }), { transform: t });
			}
			s += faceted("M50,172 C40,122 60,72 100,72 C140,72 160,122 150,172 Z", "#5FC3C8", "M118,74 C146,82 158,124 150,172 L126,172 Z", "#46AAB0");
			s += rect(46, 166, 108, 18, C("#3E9EA3"), { sw: 5, r: 7 });
			s += rect(62, 182, 18, 10, C("#2E3B4E"), { sw: 3.5, r: 3 });
			s += rect(120, 182, 18, 10, C("#2E3B4E"), { sw: 3.5, r: 3 });
			s += ellipse(100, 74, 34, 10, C("#7FD6DA"), { sw: 4.5 });
			s += circle(100, 60, 9, C("#FFD23F"), { sw: 4 });
			s += face(100, 104, 0.92, mood, { spacing: 18, eye: 11, mouthX: 128, mouthDy: 12, mouthScale: 0.7, noBlush: false });
			s += path("M100,124 C98,150 66,162 48,144 C38,134 38,118 44,110", "none", { sw: 22 });
			s += path("M100,124 C98,150 66,162 48,144 C38,134 38,118 44,110", "none", { sw: 13, stroke: C("#5FC3C8") });
			s += ellipse(44, 108, 9, 6, C("#46AAB0"), { sw: 4 });
			const steamOp = mood === "uneasy" ? 0.95 : 0.7;
			s += circle(40, 88, 9, "#FFFFFF", { sw: 3, opacity: steamOp });
			s += circle(30, 70, 7, "#FFFFFF", { sw: 3, opacity: steamOp });
			return s;
		},
	},
	cartshark: {
		name: "Cartshark",
		rarity: "Epic",
		blurb: "Circles the aisles. Always picks the trolley with the wonky wheel.",
		fx: { sweat: [150, 40], bubble: [10, 14] },
		draw: (mood) => {
			let s = "";
			s += poly([[104, 24], [134, 92], [88, 92]], C("#6E8CB3"), { sw: 5 });
			s += poly([[114, 40], [134, 92], [114, 92]], C("#58779F"), { stroke: "none" });
			s += path("M58,160 L62,176 M154,160 L142,176 M52,174 L152,174", "none", { sw: 5 });
			s += circle(62, 182, 10, C("#3A3F55"), { sw: 4 });
			s += circle(142, 182, 10, C("#3A3F55"), { sw: 4, transform: "rotate(20 142 182)" });
			s += path("M38,92 C26,64 60,46 100,52 L136,58 L134,96 Z", C("#6E8CB3"), { sw: 5 });
			s += path("M40,90 Q76,108 120,94 L134,96 L132,104 L42,104 Z", C("#EAF2FF"), { stroke: "none" });
			s += path("M44,92 Q74,108 112,94", "none", { sw: 4 });
			s += path("M50,94 l6,8 l6,-6 l6,8 l6,-6 l6,8 l6,-6 l6,8 l6,-8", C("#FFFFFF"), { sw: 2.5 });
			s += path("M118,66 L114,82 M126,66 L122,82", "none", { sw: 3 });
			s += poly([[38, 96], [174, 96], [158, 160], [56, 160]], C("#B9C3D6"), { sw: 0, stroke: "none", opacity: 0.85 });
			let grid = "";
			for (let x = 60; x <= 156; x += 16) grid += `M${x},96 L${x - (x - 106) * 0.12},160 `;
			for (let y = 112; y <= 150; y += 16) grid += `M${40 + (y - 96) * 0.27},${y} L${172 - (y - 96) * 0.25},${y} `;
			s += path(grid, "none", { sw: 2.5, stroke: C("#6E7890") });
			s += poly([[38, 96], [174, 96], [158, 160], [56, 160]], "none", { sw: 5 });
			s += path("M174,96 L188,78", "none", { sw: 6 });
			s += rect(180, 70, 18, 10, C("#FF5C8A"), { sw: 3.5, r: 4, transform: "rotate(-40 189 75)" });
			s += face(72, 72, 0.82, mood, { spacing: 15, eye: 10, noMouth: true, noBlush: true });
			return s;
		},
	},
	owlarm: {
		name: "Owlarm",
		rarity: "Epic",
		blurb: "Hoots at 6:00 sharp. Every day. Nobody asked.",
		fx: { sweat: [172, 80], bubble: [6, 16] },
		draw: (mood) => {
			let s = "";
			s += path("M96,46 L100,30 L104,46", "none", { sw: 5 });
			s += circle(100, 28, 6, C("#FFD23F"), { sw: 3.5 });
			s += path("M38,62 C34,30 70,14 86,40 Z", C("#FFD23F"), { sw: 5 });
			s += path("M162,62 C166,30 130,14 114,40 Z", C("#FFD23F"), { sw: 5 });
			s += path("M36,104 C16,124 22,156 46,162 Z", C("#E06A22"), { sw: 5 });
			s += path("M164,104 C184,124 178,156 154,162 Z", C("#E06A22"), { sw: 5 });
			s += faceted("M100,46 C140,46 166,76 166,114 C166,152 138,180 100,180 C62,180 34,152 34,114 C34,76 60,46 100,46 Z", "#FF8A3D", "M132,54 C156,70 166,92 166,114 C166,152 138,180 100,180 L120,176 C144,160 152,100 132,54 Z", "#EA7329");
			s += ellipse(100, 146, 38, 28, C("#FFE0B8"), { sw: 4 });
			s += path("M84,140 l6,6 l6,-6 M104,140 l6,6 l6,-6 M94,154 l6,6 l6,-6", "none", { sw: 3, stroke: C("#C98A55") });
			s += circle(76, 98, 25, C("#FFF4E0"), { sw: 4.5 });
			s += circle(124, 98, 25, C("#FFF4E0"), { sw: 4.5 });
			for (const cx of [76, 124]) {
				for (let k = 0; k < 12; k++) {
					const a = (k * Math.PI) / 6;
					s += line(cx + Math.cos(a) * 19, 98 + Math.sin(a) * 19, cx + Math.cos(a) * 22, 98 + Math.sin(a) * 22, { sw: 2.2 });
				}
			}
			s += face(100, 98, 1.25, mood, { spacing: 19, eye: 11, noMouth: true, noBlush: true });
			s += poly([[90, 118], [110, 118], [100, 134]], C("#FFD23F"), { sw: 4 });
			s += path("M80,182 l-6,8 M86,182 l0,9 M92,182 l6,8 M108,182 l-6,8 M114,182 l0,9 M120,182 l6,8", "none", { sw: 4, stroke: C("#E06A22") });
			return s;
		},
	},
	pianoceros: {
		name: "Pianoceros",
		rarity: "Legendary",
		blurb: "Charges at wrong notes. Will only play in C major.",
		fx: { sweat: [178, 98], bubble: [176, 20] },
		draw: (mood) => {
			let s = "";
			s += rect(46, 150, 15, 38, C("#2E2A3F"), { sw: 4, r: 4 });
			s += rect(139, 150, 15, 38, C("#2E2A3F"), { sw: 4, r: 4 });
			s += rect(94, 154, 13, 34, C("#2E2A3F"), { sw: 4, r: 4 });
			s += line(140, 94, 148, 52, { sw: 5 });
			s += poly([[30, 94], [170, 94], [156, 40], [66, 58]], C("#3A3552"), { sw: 5 });
			s += poly([[100, 50], [156, 40], [170, 94], [120, 94]], C("#4A4466"), { stroke: "none" });
			s += poly([[30, 94], [170, 94], [156, 40], [66, 58]], "none", { sw: 5 });
			s += poly([[44, 70], [30, 18], [72, 62]], C("#FFF4E0"), { sw: 5 });
			s += poly([[74, 60], [74, 38], [90, 56]], C("#FFF4E0"), { sw: 4 });
			s += poly([[150, 46], [168, 30], [164, 54]], C("#3A3552"), { sw: 4 });
			s += rect(26, 90, 148, 68, C("#2E2A3F"), { sw: 5, r: 14 });
			s += rect(34, 96, 132, 7, C("#5C5680"), { stroke: "none", r: 3 });
			s += rect(26, 148, 148, 10, C("#FFB428"), { sw: 4, r: 4 });
			s += face(100, 116, 0.9, mood, { spacing: 26, eye: 12, noMouth: true, noBlush: true });
			s += rect(56, 128, 88, 18, "#FFFFFF", { sw: 4, r: 5 });
			for (const x of [66, 78, 98, 110, 122]) s += rect(x, 128, 6, 10, INK, { stroke: "none" });
			if (mood === "happy") s += path("M58,146 Q100,160 142,146", "none", { sw: 3.5 });
			return s;
		},
	},
	spinwhale: {
		name: "Spinwhale",
		rarity: "Mythic",
		blurb: "Sings during the spin cycle. Everything nearby smells of lavender.",
		fx: { sweat: [20, 92], bubble: [4, 30] },
		draw: (mood) => {
			let s = "";
			const bubbleOp = NIGHT ? 0.9 : 0.8;
			for (const [x, y, r] of [[86, 40, 8], [100, 24, 10], [114, 42, 7], [94, 8, 6], [122, 18, 5]]) s += circle(x, y, r, "#EAF6FF", { sw: 3, opacity: bubbleOp });
			s += path("M168,112 C184,92 196,72 194,52 C184,62 176,64 164,60 C172,74 170,92 156,104 Z", C("#3B8EE6"), { sw: 5 });
			s += faceted("M18,140 C18,82 66,62 116,64 C160,66 182,102 178,140 C176,172 150,188 98,188 C48,188 18,172 18,140 Z", "#4DA3FF", "M18,140 C30,162 60,170 98,170 C140,170 170,160 178,140 C176,172 150,188 98,188 C48,188 18,172 18,140 Z", "#CDEBFF");
			s += rect(70, 58, 62, 15, C("#FFFFFF"), { sw: 4, r: 6 });
			s += circle(84, 65, 3.5, C("#FF5C8A"), { stroke: "none" });
			s += circle(96, 65, 3.5, C("#3DDC84"), { stroke: "none" });
			s += rect(104, 62, 20, 6, C("#8A93A8"), { stroke: "none", r: 3 });
			s += circle(120, 128, 36, C("#E6EEF7"), { sw: 5 });
			s += circle(120, 128, 25, C("#7FC8FF"), { sw: 4 });
			s += path("M102,128 C106,112 130,110 136,124 C140,136 124,144 116,136", "none", { sw: 3.5, stroke: "#FFFFFF" });
			s += path("M112,138 l10,-2 l2,6 l-6,4 Z", C("#FF5C8A"), { sw: 2.5 });
			s += face(52, 112, 0.82, mood, { spacing: 14, eye: 10, mouthDy: 3 });
			return s;
		},
	},
	tellama: {
		name: "Tellama",
		rarity: "Secret",
		blurb: "Only shows reruns. Spits static if you change the channel.",
		fx: { sweat: [110, 30], bubble: [140, 6] },
		draw: (mood) => {
			let s = "";
			for (const x of [66, 84, 124, 142]) {
				s += rect(x - 6, 150, 13, 34, C("#F5E6C8"), { sw: 4, r: 4 });
				s += rect(x - 7, 182, 15, 8, C("#5A3B22"), { sw: 3, r: 3 });
			}
			const wool = "M54,152 a17,17 0 0 1 6,-30 a20,20 0 0 1 32,-12 a20,20 0 0 1 36,2 a18,18 0 0 1 26,26 a16,16 0 0 1 -10,28 a18,18 0 0 1 -30,6 a20,20 0 0 1 -34,0 a17,17 0 0 1 -26,-20 Z";
			s += path(wool, C("#F5E6C8"), { sw: 5 });
			s += path("M170,124 c10,-6 18,2 12,10", "none", { sw: 5 });
			s += path("M44,74 L44,132 C44,140 76,140 76,132 L76,74 Z", C("#F5E6C8"), { sw: 5 });
			s += path("M48,96 c6,-4 10,4 16,0 c6,-4 10,4 10,0 M48,116 c6,-4 10,4 16,0 c6,-4 10,4 10,0", "none", { sw: 2.5, stroke: C("#D9C49C") });
			s += line(42, 26, 24, 2, { sw: 4 });
			s += line(78, 26, 98, 2, { sw: 4 });
			s += circle(24, 2, 5, C("#FF5C8A"), { sw: 3 });
			s += circle(98, 2, 5, C("#4DA3FF"), { sw: 3 });
			s += rect(10, 24, 102, 64, C("#B5763C"), { sw: 5, r: 12 });
			const scr = NIGHT ? "#5CFFB0" : "#3DDC84";
			if (NIGHT) s += glow(52, 56, 60, "#5CFFB0", 0.35);
			s += rect(18, 31, 72, 50, scr, { sw: 4, r: 9 });
			for (let y = 37; y < 80; y += 6) s += line(22, y, 86, y, { sw: 1.4, stroke: "#FFFFFF", opacity: 0.35 });
			s += circle(100, 44, 4.5, C("#FFD23F"), { sw: 2.5 });
			s += circle(100, 64, 4.5, C("#FFD23F"), { sw: 2.5 });
			s += pixelFace(54, 56, mood);
			return s;
		},
	},
};

// Pixel face for the TV screen.
function pixelFace(x, y, mood) {
	const px = 5;
	const P = (cx, cy, c = INK) => rect(x + cx * px, y + cy * px, px, px, c, { stroke: "none" });
	let s = "";
	if (mood === "sleepy") {
		for (const ex of [-5, 3]) for (let i = 0; i < 3; i++) s += P(ex + i, -1);
	} else if (mood === "rogue") {
		for (const ex of [-5, 3]) for (let i = 0; i < 2; i++) for (let j = 0; j < 2; j++) s += P(ex + i, -2 + j, "#FF3B3B");
	} else {
		const shift = mood === "uneasy" ? -1 : 0;
		for (const ex of [-5, 3]) for (let i = 0; i < 2; i++) for (let j = 0; j < 3; j++) s += P(ex + i + shift, -3 + j);
	}
	if (mood === "happy" || mood === "content") {
		s += P(-4, 2) + P(-3, 3) + P(-2, 3) + P(-1, 3) + P(0, 3) + P(1, 3) + P(2, 2);
	} else if (mood === "uneasy") {
		s += P(-4, 3) + P(-3, 2) + P(-2, 3) + P(-1, 2) + P(0, 3) + P(1, 2) + P(2, 3);
	} else if (mood === "rogue") {
		for (let i = -4; i <= 2; i++) s += P(i, 2, "#FF3B3B");
	}
	return s;
}

// Shared filter that turns any shape solid white (for mutation masks).
const MUTATION_DEFS = `<defs><filter id="toWhite"><feColorMatrix type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 1 0"/></filter>
<linearGradient id="rainbowGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF5C8A"/><stop offset=".25" stop-color="#FFD23F"/><stop offset=".5" stop-color="#3DDC84"/><stop offset=".75" stop-color="#4DA3FF"/><stop offset="1" stop-color="#8B5CF6"/></linearGradient>
<filter id="softBlur"><feGaussianBlur stdDeviation="8"/></filter></defs>`;

function sparkle(x, y, r, color = "#FFF6C2") {
	return path(`M${x},${y - r} L${x + r * 0.28},${y - r * 0.28} L${x + r},${y} L${x + r * 0.28},${y + r * 0.28} L${x},${y + r} L${x - r * 0.28},${y + r * 0.28} L${x - r},${y} L${x - r * 0.28},${y - r * 0.28} Z`, color, { sw: 2.5 });
}

// Full creature with mood effects and mutation overlay, in its 200x200 box.
function creatureArt(id, o = {}) {
	const def = SPECIES[id];
	const mood = o.mood || "happy";
	const body = def.draw(mood);
	let s = "";
	if (mood === "rogue") {
		s += `<ellipse cx="100" cy="110" rx="96" ry="88" fill="#8B5CF6" opacity="0.55" filter="url(#softBlur)"/>`;
	}
	s += body;
	const mut = o.mutation;
	if (mut === "Golden" || mut === "Rainbow" || mut === "Glitched") {
		const m = uid("mut");
		s += `<defs><mask id="${m}"><g filter="url(#toWhite)">${body}</g></mask></defs>`;
		if (mut === "Golden") {
			s += `<rect x="-20" y="-20" width="240" height="240" fill="#F2B400" mask="url(#${m})" style="mix-blend-mode:color"/>`;
			s += `<rect x="-20" y="-20" width="240" height="240" fill="#FFE27A" opacity="0.25" mask="url(#${m})" style="mix-blend-mode:screen"/>`;
		} else if (mut === "Rainbow") {
			s += `<rect x="-20" y="-20" width="240" height="240" fill="url(#rainbowGrad)" mask="url(#${m})" style="mix-blend-mode:color"/>`;
		} else {
			s += `<g mask="url(#${m})" style="mix-blend-mode:screen"><rect x="-20" y="60" width="240" height="10" fill="#00FFD5" opacity=".7"/><rect x="-20" y="120" width="240" height="7" fill="#FF00C8" opacity=".7"/><rect x="-20" y="150" width="240" height="5" fill="#00FFD5" opacity=".6"/></g>`;
			s = g(s, { transform: "translate(3,0)" });
		}
		if (mut !== "Glitched") s += sparkle(28, 40, 12) + sparkle(176, 70, 9) + sparkle(160, 170, 10);
	}
	const fx = def.fx || {};
	if (mood === "uneasy") {
		const [sx, sy] = fx.sweat || [160, 60];
		s += path(`M${sx},${sy - 14} C${sx + 9},${sy - 2} ${sx + 9},${sy + 8} ${sx},${sy + 8} C${sx - 9},${sy + 8} ${sx - 9},${sy - 2} ${sx},${sy - 14} Z`, "#9FDBFF", { sw: 3 });
		s += path("M-6,80 L-16,74 M-6,104 L-18,104 M-6,128 L-16,134 M206,80 L216,74 M206,104 L218,104 M206,128 L216,134", "none", { sw: 4, stroke: "#5B3FA8" });
		const [bx, by] = fx.bubble || [20, 20];
		s += circle(bx + 30, by + 34, 4, "#FFFFFF", { sw: 2.5 }) + circle(bx + 24, by + 24, 6, "#FFFFFF", { sw: 2.5 });
		s += ellipse(bx + 8, by - 2, 24, 18, "#FFFFFF", { sw: 3 });
		s += g(path("M-12,0 L0,-11 L12,0 L12,12 L-12,12 Z", "#8B5CF6", { sw: 2.5 }) + rect(-3, 4, 6, 8, "#FFFFFF", { sw: 1.5 }), {
			transform: `translate(${bx + 8},${by - 3}) scale(0.9)`,
		});
	}
	if (mood === "sleepy") {
		s += text(170, 40, "z", { size: 30, weight: 700, fill: "#FFFFFF", outline: INK, ow: 5 }) + text(186, 18, "z", { size: 22, weight: 700, fill: "#FFFFFF", outline: INK, ow: 5 });
	}
	let tr = "";
	if (mut === "Tiny") tr = "translate(100,190) scale(0.65) translate(-100,-190)";
	if (mut === "Mega") tr = "translate(100,190) scale(1.25) translate(-100,-190)";
	return tr ? g(s, { transform: tr }) : s;
}

// Place a creature with its feet at (x, y), `size` px tall box.
function creature(id, x, y, size, o = {}) {
	const k = size / 200;
	const flip = o.flip ? ` translate(200,0) scale(-1,1)` : "";
	return g(creatureArt(id, o), { transform: `translate(${x - 100 * k},${y - 190 * k}) scale(${k})${flip}` });
}

const SPECIES_ORDER = ["mugpup", "toasturtle", "sockodile", "lampingo", "brollybun", "fridgehog", "kettlephant", "cartshark", "owlarm", "pianoceros", "spinwhale", "tellama"];
