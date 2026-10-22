// Rot Shift v3 UI mockups (Food Shop, Nursery, unlock dialog). Plain DOM, rendered to PNG by render.mjs.
// Page: ui.html?screen=<food-feasts|food-premium|nursery|nursery-locked>

const FOODS = [
	// id, name, tab, cash, robux, days, loyalty, growth
	["breadstick", "Stale Breadstick", "Snacks", 50, null, 0.25, 1, 1],
	["olive", "Olive Snack", "Snacks", 150, null, 0.5, 2, 2],
	["crust", "Pizza Crust", "Snacks", 400, null, 0.75, 3, 3],
	["slice", "Pizza Slice", "Snacks", 1000, null, 1, 4, 4],
	["knots", "Garlic Knots", "Meals", 2500, null, 1.5, 6, 6],
	["spaghetti", "Spaghetti Bowl", "Meals", 6000, null, 2, 8, 8],
	["sub", "Meatball Sub", "Meals", 12000, null, 2.5, 10, 10],
	["lasagna", "Lasagna Brick", "Meals", 25000, null, 3, 12, 13],
	["risotto", "Risotto Pot", "Meals", 50000, null, 4, 15, 16],
	["gelato", "Gelato Tower", "Feasts", 100000, 2, 5, 18, 20],
	["tiramisu", "Tiramisu Slab", "Feasts", 200000, 3, 7, 22, 25],
	["cannolo", "Golden Cannolo", "Feasts", 450000, 5, 10, 28, 32],
	["truffle", "Truffle Pasta", "Feasts", 1000000, 7, 14, 35, 40],
	["banquet", "Banquet Platter", "Feasts", 2500000, 10, 20, 45, 55],
	["crate", "Snack Crate", "Premium", null, 285, 5, 20, 20],
	["royal", "Royal Feast", "Premium", null, 735, 14, 40, 45],
	["espresso", "Cosmic Espresso", "Premium", null, 1485, 30, "MAX", 80],
	["nonna", "Nonna's Secret Recipe", "Premium", null, 2985, "CAP", "MAX", "ADULT"],
].map(([id, name, tab, cash, robux, days, loyalty, growth]) => ({ id, name, tab, cash, robux, days, loyalty, growth }));

const money = (n) =>
	n >= 1e6 ? `$${+(n / 1e6).toFixed(2)}M`.replace(".00M", "M") : n >= 1e3 ? `$${+(n / 1e3).toFixed(1)}K`.replace(".0K", "K") : `$${n}`;

// Simple flat food icons (SVG, 100x100)
function icon(id) {
	const o = (s) => `<svg viewBox="0 0 100 100" class="icon">${s}</svg>`;
	const plate = `<ellipse cx="50" cy="78" rx="40" ry="11" fill="#fff" stroke="#1B1530" stroke-width="4"/>`;
	switch (id) {
		case "breadstick":
			return o(plate + `<rect x="18" y="52" width="66" height="16" rx="8" fill="#D9A55B" stroke="#1B1530" stroke-width="4" transform="rotate(-14 50 60)"/><circle cx="34" cy="62" r="2" fill="#fff"/><circle cx="52" cy="57" r="2" fill="#fff"/><circle cx="68" cy="53" r="2" fill="#fff"/>`);
		case "olive":
			return o(plate + `<ellipse cx="38" cy="62" rx="14" ry="11" fill="#6B8E23" stroke="#1B1530" stroke-width="4"/><ellipse cx="62" cy="60" rx="14" ry="11" fill="#556B2F" stroke="#1B1530" stroke-width="4"/><circle cx="62" cy="60" r="4" fill="#E0262C"/>`);
		case "crust":
			return o(plate + `<path d="M20 66 Q50 40 80 66" fill="none" stroke="#C8873A" stroke-width="12" stroke-linecap="round"/><path d="M20 66 Q50 40 80 66" fill="none" stroke="#1B1530" stroke-width="3" stroke-linecap="round" opacity=".5"/>`);
		case "slice":
			return o(`<path d="M50 88 L18 26 Q50 12 82 26 Z" fill="#FFC94A" stroke="#1B1530" stroke-width="4" stroke-linejoin="round"/><path d="M18 26 Q50 12 82 26 L78 34 Q50 22 22 34 Z" fill="#C8873A" stroke="#1B1530" stroke-width="3"/><circle cx="45" cy="45" r="7" fill="#D9442B"/><circle cx="60" cy="58" r="6" fill="#D9442B"/><circle cx="48" cy="68" r="5" fill="#D9442B"/>`);
		case "knots":
			return o(plate + [30, 50, 70].map((x) => `<circle cx="${x}" cy="62" r="11" fill="#E8B866" stroke="#1B1530" stroke-width="4"/><path d="M${x - 5} 60 q5 -6 10 0" stroke="#7A9A3A" stroke-width="3" fill="none"/>`).join(""));
		case "spaghetti":
			return o(`<path d="M14 52 h72 q-4 34 -36 34 q-32 0 -36 -34z" fill="#fff" stroke="#1B1530" stroke-width="4"/><ellipse cx="50" cy="50" rx="34" ry="12" fill="#F2D06B" stroke="#1B1530" stroke-width="4"/><circle cx="42" cy="46" r="6" fill="#8B3A2E"/><circle cx="58" cy="48" r="6" fill="#8B3A2E"/><path d="M30 50 q8 -8 16 0 q8 8 16 0 q6 -6 10 0" stroke="#D9A33B" stroke-width="3" fill="none"/>`);
		case "sub":
			return o(plate + `<rect x="14" y="48" width="72" height="22" rx="11" fill="#D9A55B" stroke="#1B1530" stroke-width="4"/>${[30, 44, 58, 72].map((x) => `<circle cx="${x}" cy="54" r="6" fill="#8B3A2E" stroke="#1B1530" stroke-width="2"/>`).join("")}<rect x="18" y="58" width="64" height="5" fill="#D9442B"/>`);
		case "lasagna":
			return o(plate + `<rect x="24" y="36" width="52" height="36" rx="4" fill="#F2C46B" stroke="#1B1530" stroke-width="4"/>${[46, 56, 64].map((y) => `<rect x="24" y="${y}" width="52" height="4" fill="#D9442B"/>`).join("")}<rect x="24" y="36" width="52" height="7" fill="#FFE9A8"/>`);
		case "risotto":
			return o(`<path d="M16 46 h68 v26 q0 12 -12 12 h-44 q-12 0 -12 -12z" fill="#5A5E66" stroke="#1B1530" stroke-width="4"/><ellipse cx="50" cy="46" rx="34" ry="10" fill="#F5E6B8" stroke="#1B1530" stroke-width="4"/><circle cx="40" cy="44" r="3" fill="#7A9A3A"/><circle cx="58" cy="47" r="3" fill="#7A9A3A"/><rect x="8" y="50" width="10" height="6" rx="3" fill="#2B2E35"/><rect x="82" y="50" width="10" height="6" rx="3" fill="#2B2E35"/>`);
		case "gelato":
			return o(`<path d="M36 52 L50 92 L64 52 Z" fill="#E8B866" stroke="#1B1530" stroke-width="4" stroke-linejoin="round"/><circle cx="50" cy="46" r="15" fill="#FFF1B5" stroke="#1B1530" stroke-width="4"/><circle cx="50" cy="30" r="13" fill="#B6F0B0" stroke="#1B1530" stroke-width="4"/><circle cx="50" cy="16" r="11" fill="#FFB3C7" stroke="#1B1530" stroke-width="4"/>`);
		case "tiramisu":
			return o(plate + `<rect x="22" y="34" width="56" height="38" rx="5" fill="#F5E6CF" stroke="#1B1530" stroke-width="4"/><rect x="22" y="48" width="56" height="6" fill="#7A4A24"/><rect x="22" y="34" width="56" height="9" fill="#5C3A1E"/>`);
		case "cannolo":
			return o(`<rect x="18" y="38" width="64" height="26" rx="13" fill="#FFD23F" stroke="#1B1530" stroke-width="4" transform="rotate(-12 50 51)"/><ellipse cx="22" cy="58" rx="8" ry="12" fill="#FFF8EC" stroke="#1B1530" stroke-width="4" transform="rotate(-12 50 51)"/><ellipse cx="80" cy="45" rx="8" ry="12" fill="#FFF8EC" stroke="#1B1530" stroke-width="4" transform="rotate(-12 50 51)"/><path d="M40 30 l4 -8 l4 8 l8 4 l-8 4 l-4 8 l-4 -8 l-8 -4z" fill="#fff"/>`);
		case "truffle":
			return o(plate + `<ellipse cx="50" cy="64" rx="34" ry="12" fill="#F2D06B" stroke="#1B1530" stroke-width="4"/><path d="M26 62 q8 -10 16 0 q8 10 16 0 q8 -10 16 0" stroke="#D9A33B" stroke-width="3" fill="none"/><circle cx="44" cy="54" r="7" fill="#2B1E14" stroke="#1B1530" stroke-width="2"/><circle cx="60" cy="56" r="5" fill="#3B2A1C"/>`);
		case "banquet":
			return o(`<ellipse cx="50" cy="74" rx="44" ry="14" fill="#FFD23F" stroke="#1B1530" stroke-width="4"/><ellipse cx="50" cy="56" rx="24" ry="17" fill="#B5651D" stroke="#1B1530" stroke-width="4"/><rect x="66" y="44" width="16" height="6" rx="3" fill="#FFF8EC" stroke="#1B1530" stroke-width="3" transform="rotate(-30 74 47)"/><circle cx="26" cy="68" r="6" fill="#D9442B"/><circle cx="76" cy="70" r="6" fill="#3DDC84"/>`);
		case "crate":
			return o(`<rect x="14" y="34" width="72" height="52" rx="6" fill="#C8873A" stroke="#1B1530" stroke-width="4"/><path d="M14 52 h72 M14 70 h72" stroke="#1B1530" stroke-width="3"/><circle cx="34" cy="28" r="10" fill="#FFB3C7" stroke="#1B1530" stroke-width="3"/><path d="M48 32 L60 12 L72 32Z" fill="#FFC94A" stroke="#1B1530" stroke-width="3"/>`);
		case "royal":
			return o(`<ellipse cx="50" cy="76" rx="44" ry="12" fill="#B98CFF" stroke="#1B1530" stroke-width="4"/><path d="M14 74 q36 -70 72 0z" fill="#E8E8F0" stroke="#1B1530" stroke-width="4"/><circle cx="50" cy="30" r="6" fill="#FFD23F" stroke="#1B1530" stroke-width="3"/><path d="M30 18 l6 8 l7 -10 l7 10 l7 -10 l7 10 l6 -8 v12 h-40z" fill="#FFD23F" stroke="#1B1530" stroke-width="3" transform="translate(0 -10)"/>`);
		case "espresso":
			return o(`<circle cx="50" cy="50" r="44" fill="#2A1B5C"/><circle cx="22" cy="24" r="2" fill="#fff"/><circle cx="80" cy="30" r="2" fill="#fff"/><circle cx="74" cy="80" r="2" fill="#fff"/><path d="M28 44 h44 v22 q0 16 -22 16 q-22 0 -22 -16z" fill="#fff" stroke="#1B1530" stroke-width="4"/><path d="M72 50 q12 0 12 8 q0 8 -12 8" fill="none" stroke="#1B1530" stroke-width="4"/><ellipse cx="50" cy="45" rx="22" ry="5" fill="#5C3A1E"/><path d="M42 36 q4 -8 0 -14 M54 36 q4 -8 0 -14" stroke="#B98CFF" stroke-width="3" fill="none"/>`);
		case "nonna":
			return o(`<rect x="22" y="16" width="56" height="70" rx="6" fill="#FFF4E0" stroke="#1B1530" stroke-width="4"/><path d="M32 32 h36 M32 44 h36 M32 56 h24" stroke="#C8873A" stroke-width="4" stroke-linecap="round"/><circle cx="66" cy="70" r="12" fill="#E0262C" stroke="#1B1530" stroke-width="3"/><path d="M60 70 l4 4 l8 -8" stroke="#fff" stroke-width="3" fill="none"/>`);
	}
	return "";
}

const robuxIcon = `<svg viewBox="0 0 24 24" class="rbx"><path d="M12 1.5 21 6.75v10.5L12 22.5 3 17.25V6.75Z" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linejoin="round"/><rect x="9" y="9" width="6" height="6" rx="1" fill="currentColor"/></svg>`;

function stat(cls, label) {
	return `<span class="stat ${cls}">${label}</span>`;
}

function statsFor(f) {
	const days = f.days === "CAP" ? "Fills timer" : `+${f.days}d`;
	const loy = f.loyalty === "MAX" ? "Max loyalty" : `+${f.loyalty}`;
	const grow = f.growth === "ADULT" ? "Instant Adult" : `+${f.growth}`;
	return `<div class="stats">${stat("time", `<b>⏱</b>${days}`)}${stat("love", `<b>♥</b>${loy}`)}${stat("grow", `<b>▲</b>${grow}`)}</div>`;
}

function foodCard(f, qty) {
	const buttons = [];
	if (f.cash != null) buttons.push(`<button class="buy cash">${money(f.cash * qty)}</button>`);
	if (f.robux != null) buttons.push(`<button class="buy robux">${robuxIcon}${f.robux * qty}</button>`);
	return `<div class="card">
		<div class="art">${icon(f.id)}</div>
		<div class="name">${f.name}</div>
		${statsFor(f)}
		<div class="buys ${buttons.length > 1 ? "two" : ""}">${buttons.join("")}</div>
	</div>`;
}

function qtyToggle(opts, active) {
	return `<div class="qty">${opts.map((q) => `<span class="${q === active ? "on" : ""}">×${q}</span>`).join("")}</div>`;
}

function hudTop(bgClass) {
	return `<div class="hud">
		<div class="cash"><span class="coin">$</span>$2,481,300</div>
		<div class="ips">+$1,240/s</div>
		<div class="phase"><span class="sun"></span>DAY <span class="t">5:42</span></div>
	</div>`;
}

function foodShop(tab) {
	const qty = tab === "Premium" ? 1 : 5;
	const list = FOODS.filter((f) => f.tab === tab);
	const tabs = ["Snacks", "Meals", "Feasts", "Premium"]
		.map((t) => `<span class="tab ${t === tab ? "on" : ""} ${t === "Premium" ? "prem" : ""}">${t === "Premium" ? robuxIcon : ""}${t}</span>`)
		.join("");
	return `${hudTop()}
	<div class="panel food">
		<div class="banner orange">FOOD SHOP</div>
		<div class="close">✕</div>
		<div class="row tabs-row"><div class="tabs">${tabs}</div>${qtyToggle(tab === "Premium" ? [1, 5] : [1, 5, 10], qty)}</div>
		<div class="grid n${list.length}">${list.map((f) => foodCard(f, qty)).join("")}</div>
		<div class="inv"><span class="inv-title">Your food</span>
			<span class="chip">${icon("slice")}<b>×12</b></span>
			<span class="chip">${icon("spaghetti")}<b>×4</b></span>
			<span class="chip">${icon("lasagna")}<b>×2</b></span>
			<span class="chip">${icon("gelato")}<b>×1</b></span>
			<span class="inv-hint">Feed at a pedestal, an incubator or from Inspect</span>
		</div>
	</div>`;
}

function stageTrack(stage, pts, need) {
	const stages = ["Baby", "Teen", "Adult"];
	return `<div class="stages">${stages
		.map((s, i) => `<div class="stage ${s === stage ? "on" : stages.indexOf(stage) > i ? "done" : ""}"><span>${s}</span><small>${["×0.4 $/s", "×0.7 $/s", "×1 $/s"][i]}</small></div>`)
		.join('<div class="arrow">›</div>')}</div>
		<div class="bar grow"><div style="width:${(pts / need) * 100}%"></div><span>${pts} / ${need} growth to Teen</span></div>`;
}

function nursery() {
	const inc = [
		{ kind: "egg", egg: "#B98CFF", label: "Fancy Egg", time: "2:14", p: 0.35 },
		{ kind: "ready", egg: "#FFD23F", label: "Golden Egg is ready!" },
		{ kind: "baby", label: "Tung Tung Tung Sahur", sub: "Baby · Mythic", sel: true },
		{ kind: "pass", label: "Incubator 4", price: 99 },
		{ kind: "pass", label: "Incubator 5", price: 149 },
		{ kind: "pass", label: "Incubator 6", price: 199 },
	];
	const slot = (s) => {
		if (s.kind === "egg")
			return `<div class="inc"><div class="egg" style="--c:${s.egg}"></div><div class="inc-body"><b>${s.label}</b><div class="bar small"><div style="width:${s.p * 100}%"></div></div><span class="muted">Hatches in ${s.time}</span></div></div>`;
		if (s.kind === "ready")
			return `<div class="inc ready"><div class="egg" style="--c:${s.egg}"></div><div class="inc-body"><b>${s.label}</b><button class="hatch">HATCH!</button></div></div>`;
		if (s.kind === "baby")
			return `<div class="inc sel"><div class="baby">${babyIcon()}</div><div class="inc-body"><b>${s.label}</b><span class="muted">${s.sub}</span></div></div>`;
		return `<div class="inc locked"><div class="lock">🔒</div><div class="inc-body"><b>${s.label}</b><button class="buy robux small">${robuxIcon}${s.price} pass</button></div></div>`;
	};
	return `${hudTop()}
	<div class="panel nursery">
		<div class="banner pink">NURSERY</div>
		<div class="close">✕</div>
		<div class="cols">
			<div class="left">
				<div class="sec">Incubators <span class="muted">3 / 6</span></div>
				<div class="incs">${inc.map(slot).join("")}</div>
				<div class="hint">Eggs from the hub Egg Shop land here. Babies can move to a pedestal at any stage.</div>
			</div>
			<div class="right">
				<div class="who"><div class="portrait">${babyIcon()}</div><div><div class="bname">Tung Tung Tung Sahur</div><div class="chips"><span class="rar mythic">Mythic</span><span class="rar stage">Baby</span><span class="income">+$48/s</span></div></div></div>
				${stageTrack("Baby", 24, 40)}
				<div class="owner">
					<div class="orow"><span class="olabel">♥ Loyalty</span><div class="bar love"><div style="width:55%"></div></div><span class="oval">55 · ×1.1 $/s</span></div>
					<div class="orow"><span class="olabel">⏱ Runs away in</span><span class="timer">2d 0h</span><span class="muted small-note">Only you can see this</span></div>
				</div>
				<div class="feed">
					<div class="pick">${icon("slice")}<div><b>Pizza Slice</b><span class="muted">You have 12</span></div><span class="caret">▾</span></div>
					<div class="stepper"><span>−</span><b>×3</b><span>+</span></div>
					<div class="gain">${stat("time", "<b>⏱</b>+3d")}${stat("love", "<b>♥</b>+12")}${stat("grow", "<b>▲</b>+12")}</div>
				</div>
				<div class="actions"><button class="btn green big">FEED ×3</button><button class="btn blue">Move to pedestal</button></div>
			</div>
		</div>
	</div>`;
}

function babyIcon() {
	return `<svg viewBox="0 0 100 100"><rect x="30" y="24" width="40" height="56" rx="8" fill="#C8955A" stroke="#1B1530" stroke-width="4"/><circle cx="42" cy="44" r="9" fill="#fff" stroke="#1B1530" stroke-width="3"/><circle cx="60" cy="44" r="9" fill="#fff" stroke="#1B1530" stroke-width="3"/><circle cx="44" cy="45" r="4"/><circle cx="62" cy="45" r="4"/><path d="M44 62 h14" stroke="#1B1530" stroke-width="3"/><rect x="74" y="20" width="8" height="40" rx="4" fill="#9A6A3A" stroke="#1B1530" stroke-width="3" transform="rotate(15 78 40)"/></svg>`;
}

function nurseryLocked() {
	return `${hudTop()}
	<div class="panel dialog">
		<div class="banner pink">NURSERY</div>
		<div class="close">✕</div>
		<div class="dlg">
			<div class="big-lock">🔒</div>
			<div class="dlg-title">Unlock your Nursery</div>
			<div class="dlg-text">Hatch eggs from the Egg Shop into Babies and feed them all the way to Adults. Starts with 3 incubators.</div>
			<div class="dlg-buttons"><button class="btn green big">UNLOCK · $250,000</button><button class="buy robux big">${robuxIcon}99 Skip</button></div>
			<div class="muted">You have $2,481,300</div>
		</div>
	</div>`;
}

const NOTES = {
	"food-feasts": [
		["FOOD-1", "Tabs: Snacks (1–4), Meals (5–9), Feasts (10–14), Premium (15–18). Stats on every card: ⏱ timer days, ♥ loyalty, ▲ growth."],
		["FOOD-2", "Feasts can be paid in cash or Robux (2–10 R$). Quantity toggle ×1/×5/×10 multiplies both prices."],
		["FOOD-3", "Food goes to your inventory (bottom strip); you feed from a pedestal or incubator prompt, or from Inspect."],
		["Q-F1", "Robux ×5 on Feasts: exactly 5× the price (one dev product per bundle), or a small bundle discount?"],
		["Q-F2", "Should the shop show a 'Best for your income' highlight? (off in this mockup)"],
	],
	"food-premium": [
		["FOOD-4", "Premium is Robux only, ×1 or ×5 bundles. Cosmic Espresso sets loyalty to 100; Nonna's Recipe fills the timer to the 60-day cap, maxes loyalty and makes it an Adult."],
		["FOOD-5", "Premium foods never stop stealing and never guarantee a catch, same as every purchase."],
		["Q-F3", "Is Nonna's 'Instant Adult' OK for brainrots already on pedestals (it just becomes an Adult there)?"],
	],
	nursery: [
		["NUR-1", "Six incubator slots: 3 free once the nursery is unlocked, 3 more from game-pass tiers (99 / 149 / 199 R$, proposed)."],
		["NUR-2", "Growth: Baby → Teen at 40 pts, Teen → Adult at 100 more. Size ×0.5 / ×0.75 / ×1, income ×0.4 / ×0.7 / ×1 (proposed, all in Config)."],
		["NUR-3", "Loyalty and the runaway timer are owner-only. The server sends them only to the owner; other players' panels have neither."],
		["NUR-4", "Feed ×N uses any food you own; the gain chips preview the total before you feed."],
		["Q-N1", "Do growth points from food also come with a slow passive trickle over time, or food only?"],
	],
	"nursery-locked": [
		["NUR-5", "Locked by default. Unlock for $250,000 (proposed: about when a player reaches their first Legendary) or skip for 99 R$."],
		["NUR-6", "The same dialog opens from the barred nursery door's prompt in your base."],
		["Q-N2", "Unlock price: OK at $250K, or should it scale with progress?"],
	],
};

const TITLES = {
	"food-feasts": ["Food Shop", "Feasts tab: cash or Robux"],
	"food-premium": ["Food Shop", "Premium tab: Robux only"],
	nursery: ["Nursery", "Incubators, growth, feeding (owner view)"],
	"nursery-locked": ["Nursery", "Locked: unlock or skip"],
};

const screen = new URLSearchParams(location.search).get("screen") || "food-feasts";
const body =
	screen === "food-feasts" ? foodShop("Feasts") : screen === "food-premium" ? foodShop("Premium") : screen === "nursery" ? nursery() : nurseryLocked();
const [title, sub] = TITLES[screen];
document.getElementById("title").textContent = title;
document.getElementById("subtitle").textContent = sub;
document.getElementById("screen").innerHTML = body;
document.getElementById("screen").classList.add(screen.startsWith("food") ? "bg-hub" : "bg-nursery");
document.getElementById("notes").innerHTML =
	`<h3>Notes &amp; questions</h3>` +
	NOTES[screen].map(([k, t]) => `<div class="note"><span class="tag ${k.startsWith("Q") ? "q" : ""}">${k}</span><span>${t}</span></div>`).join("");
