// Browser side of world.mjs: draws build/world.json (parts, labels, signs, lights) with three.js.
import * as THREE from "three";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { OutputPass } from "three/addons/postprocessing/OutputPass.js";

let W = 1600;
let H = 900;
const PX = 64; // canvas pixels per stud for labels

const srgb = (c) => new THREE.Color().setRGB(c[0], c[1], c[2], THREE.SRGBColorSpace);
const matrixOf = (cf) =>
	new THREE.Matrix4().set(cf[3], cf[4], cf[5], cf[0], cf[6], cf[7], cf[8], cf[1], cf[9], cf[10], cf[11], cf[2], 0, 0, 0, 1);

// Classic stud tile: a raised round stud with a light top-left and a shadowed bottom-right.
function studTexture() {
	const c = document.createElement("canvas");
	c.width = c.height = 64;
	const g = c.getContext("2d");
	g.fillStyle = "#e6e6e6";
	g.fillRect(0, 0, 64, 64);
	g.strokeStyle = "rgba(0,0,0,0.10)";
	g.lineWidth = 2;
	g.strokeRect(0, 0, 64, 64);
	g.fillStyle = "#b4b4b4";
	g.beginPath();
	g.arc(35, 35, 19, 0, Math.PI * 2);
	g.fill();
	g.fillStyle = "#ffffff";
	g.beginPath();
	g.arc(31, 31, 19, 0, Math.PI * 2);
	g.fill();
	g.fillStyle = "#ececec";
	g.beginPath();
	g.arc(33, 33, 15, 0, Math.PI * 2);
	g.fill();
	const t = new THREE.CanvasTexture(c);
	t.wrapS = t.wrapT = THREE.RepeatWrapping;
	t.colorSpace = THREE.SRGBColorSpace;
	t.anisotropy = 8;
	return t;
}

function wedgeGeometry(sx, sy, sz) {
	// Roblox WedgePart: full-height face at the back (+Z), slope down to the front-bottom edge (-Z)
	const hx = sx / 2, hy = sy / 2, hz = sz / 2;
	const v = [
		[-hx, -hy, -hz], [hx, -hy, -hz], [hx, -hy, hz], [-hx, -hy, hz], // bottom
		[hx, hy, hz], [-hx, hy, hz], // top back edge
	];
	const tris = [
		[0, 2, 1], [0, 3, 2], // bottom
		[3, 4, 2], [3, 5, 4], // back
		[0, 1, 4], [0, 4, 5], // slope
		[0, 5, 3], // left
		[1, 2, 4], // right
	];
	const pos = [];
	for (const t of tris) for (const i of t) pos.push(...v[i]);
	const g = new THREE.BufferGeometry();
	g.setAttribute("position", new THREE.Float32BufferAttribute(pos, 3));
	g.computeVertexNormals();
	return g;
}

function geometryFor(p) {
	const [sx, sy, sz] = p.size;
	switch (p.shape) {
		case "Ball":
			return new THREE.SphereGeometry(Math.min(sx, sy, sz) / 2, 24, 16);
		case "Ellipsoid":
			return new THREE.SphereGeometry(0.5, 24, 16).scale(sx, sy, sz);
		case "Cylinder":
			return new THREE.CylinderGeometry(Math.min(sy, sz) / 2, Math.min(sy, sz) / 2, sx, 28).rotateZ(Math.PI / 2);
		case "Wedge":
			return wedgeGeometry(sx, sy, sz);
		default:
			return new THREE.BoxGeometry(sx, sy, sz);
	}
}

const ROUGH = { Plastic: 0.75, SmoothPlastic: 0.45, Wood: 0.85, WoodPlanks: 0.85, Slate: 0.9, Concrete: 0.95, Cobblestone: 0.95, Brick: 0.9, Grass: 1, Metal: 0.35, DiamondPlate: 0.4, Foil: 0.25, Glass: 0.05, Marble: 0.3, Fabric: 1, Sand: 1 };

function materialFor(p, night) {
	const color = srgb(p.color);
	if (p.material === "Neon") {
		// Neon is unlit and glows; the bloom pass picks it up.
		return new THREE.MeshBasicMaterial({ color: color.clone().multiplyScalar(night ? 2.2 : 1.5), toneMapped: false });
	}
	const m = new THREE.MeshStandardMaterial({
		color,
		roughness: ROUGH[p.material] ?? 0.7,
		metalness: p.material === "Foil" || p.material === "Metal" ? 0.6 : 0,
	});
	if (p.transparency > 0.01) {
		m.transparent = true;
		m.opacity = 1 - p.transparency;
		m.depthWrite = false;
	}
	return m;
}

function roundRect(g, x, y, w, h, r) {
	g.beginPath();
	g.moveTo(x + r, y);
	g.arcTo(x + w, y, x + w, y + h, r);
	g.arcTo(x + w, y + h, x, y + h, r);
	g.arcTo(x, y + h, x, y, r);
	g.arcTo(x, y, x + w, y, r);
	g.closePath();
}

const hexToRgb = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
const css = (c, a = 1) => `rgba(${c.map((v) => Math.round(v * 255)).join(",")},${a})`;

// A compact bar row: optional icon on the left, rounded track, fill, black outline.
function drawBar(g, l, cw, y, lh) {
	const w = (l.width || 1) * cw;
	const x0 = (cw - w) / 2;
	const pad = lh * 0.14;
	let bx = x0;
	if (l.icon) {
		g.font = `700 ${lh * 0.95}px Fredoka`;
		g.lineWidth = lh * 0.16;
		g.strokeStyle = "#000";
		g.strokeText(l.icon, x0 + lh * 0.5, y + lh / 2);
		g.fillStyle = css(l.iconColor);
		g.fillText(l.icon, x0 + lh * 0.5, y + lh / 2);
		bx = x0 + lh * 1.05;
	}
	const bw = x0 + w - bx;
	g.fillStyle = "#000";
	roundRect(g, bx, y + pad, bw, lh - pad * 2, (lh - pad * 2) / 2);
	g.fill();
	const inset = lh * 0.09;
	g.fillStyle = css(l.back);
	roundRect(g, bx + inset, y + pad + inset, bw - inset * 2, lh - (pad + inset) * 2, (lh - (pad + inset) * 2) / 2);
	g.fill();
	const fw = Math.max(lh * 0.3, (bw - inset * 2) * Math.max(0, Math.min(1, l.value)));
	g.fillStyle = css(l.color);
	roundRect(g, bx + inset, y + pad + inset, fw, lh - (pad + inset) * 2, (lh - (pad + inset) * 2) / 2);
	g.fill();
	g.fillStyle = "rgba(255,255,255,0.35)";
	roundRect(g, bx + inset * 2, y + pad + inset * 1.6, Math.max(0, fw - inset * 2), (lh - (pad + inset) * 2) * 0.32, lh * 0.1);
	g.fill();
}

function fitFont(g, text, maxW, maxH) {
	let size = maxH * 0.86;
	g.font = `700 ${size}px Fredoka`;
	const w = g.measureText(text).width;
	if (w > maxW) {
		size *= maxW / w;
		g.font = `700 ${size}px Fredoka`;
	}
	return size;
}

// Stacked text lines (BillboardGui / SurfaceGui with TextScaled labels and a UIStroke).
function labelCanvas(lines, wStuds, hStuds, strokeScale) {
	const c = document.createElement("canvas");
	c.width = Math.max(8, Math.round(wStuds * PX));
	c.height = Math.max(8, Math.round(hStuds * PX));
	const g = c.getContext("2d");
	g.textAlign = "center";
	g.textBaseline = "middle";
	g.lineJoin = "round";
	let y = 0;
	for (const l of lines) {
		const lh = l.height * c.height;
		if (l.kind === "bar") {
			drawBar(g, l, c.width, y, lh);
			y += lh;
			continue;
		}
		if (l.background) {
			const w = (l.width || 1) * c.width;
			g.fillStyle = `rgba(${l.background.map((v) => Math.round(v * 255)).join(",")},${l.backgroundAlpha})`;
			roundRect(g, (c.width - w) / 2, y + lh * 0.06, w, lh * 0.88, lh * 0.44);
			g.fill();
		}
		const size = fitFont(g, l.text, (l.width || 1) * c.width * 0.9, l.background ? lh * 0.78 : lh);
		if (l.stroke > 0) {
			g.lineWidth = Math.max(3, size * strokeScale);
			g.strokeStyle = `rgb(${l.strokeColor.map((v) => v * 255).join(",")})`;
			g.strokeText(l.text, c.width / 2, y + lh / 2);
		}
		if (l.gradient) {
			const gr = g.createLinearGradient(0, 0, c.width, 0);
			gr.addColorStop(0, "#FF5C8A");
			gr.addColorStop(0.5, "#FFD23F");
			gr.addColorStop(1, "#4DA3FF");
			g.fillStyle = gr;
		} else {
			g.fillStyle = `rgb(${l.color.map((v) => Math.round(v * 255)).join(",")})`;
		}
		g.fillText(l.text, c.width / 2, y + lh / 2);
		y += lh;
	}
	const t = new THREE.CanvasTexture(c);
	t.colorSpace = THREE.SRGBColorSpace;
	t.anisotropy = 8;
	return t;
}

function skyTexture(night) {
	const c = document.createElement("canvas");
	c.width = 16;
	c.height = 512;
	const g = c.getContext("2d");
	const gr = g.createLinearGradient(0, 0, 0, 512);
	if (night) {
		gr.addColorStop(0, "#1a0b3d");
		gr.addColorStop(0.55, "#3b1d78");
		gr.addColorStop(1, "#7b4bd1");
	} else {
		gr.addColorStop(0, "#2f8fff");
		gr.addColorStop(0.55, "#7cc4ff");
		gr.addColorStop(1, "#dff1ff");
	}
	g.fillStyle = gr;
	g.fillRect(0, 0, 16, 512);
	const t = new THREE.CanvasTexture(c);
	t.colorSpace = THREE.SRGBColorSpace;
	return t;
}

function stars(scene) {
	const pts = [];
	let s = 7;
	const rnd = () => ((s = (s * 48271) % 2147483647) / 2147483647);
	for (let i = 0; i < 2500; i++) {
		const th = rnd() * Math.PI * 2;
		const ph = Math.acos(rnd() * 0.95);
		pts.push(Math.sin(ph) * Math.cos(th) * 1800, Math.cos(ph) * 1800 + 60, Math.sin(ph) * Math.sin(th) * 1800);
	}
	const g = new THREE.BufferGeometry();
	g.setAttribute("position", new THREE.Float32BufferAttribute(pts, 3));
	scene.add(new THREE.Points(g, new THREE.PointsMaterial({ color: 0xffffff, size: 2.2, sizeAttenuation: false, fog: false })));
}

const FACE = {
	Front: { n: [0, 0, -1], ry: Math.PI, w: (s) => s[0], h: (s) => s[1] },
	Back: { n: [0, 0, 1], ry: 0, w: (s) => s[0], h: (s) => s[1] },
	Right: { n: [1, 0, 0], ry: Math.PI / 2, w: (s) => s[2], h: (s) => s[1] },
	Left: { n: [-1, 0, 0], ry: -Math.PI / 2, w: (s) => s[2], h: (s) => s[1] },
};

let data;
const fontReady = new FontFace("Fredoka", "url(/Fredoka.ttf)", { weight: "300 700" }).load().then((f) => document.fonts.add(f));

window.renderShot = async (shot) => {
	await fontReady;
	data ??= await (await fetch("/world.json")).json();
	const night = shot.mode === "night";
	W = shot.width ?? 1600;
	H = shot.height ?? 900;

	const renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
	renderer.setSize(W, H);
	renderer.setPixelRatio(1);
	renderer.shadowMap.enabled = true;
	renderer.shadowMap.type = THREE.PCFSoftShadowMap;
	renderer.toneMapping = THREE.ACESFilmicToneMapping;
	renderer.toneMappingExposure = night ? 1.0 : 1.05;
	document.body.innerHTML = "";
	document.body.appendChild(renderer.domElement);

	const scene = new THREE.Scene();
	scene.background = skyTexture(night);
	if (!shot.ortho) scene.fog = new THREE.Fog(night ? 0x2a1460 : 0xcfe9ff, 250, 900);
	if (night) stars(scene);

	// camera/target are local to data[shot.frame ?? "plotOrigin"] unless shot.world
	const frame = data[shot.frame ?? "plotOrigin"];
	const origin = frame ? matrixOf(frame) : new THREE.Matrix4();
	const local = (v) => new THREE.Vector3(...v).applyMatrix4(origin);
	const camPos = shot.world ? new THREE.Vector3(...shot.camera) : local(shot.camera);
	const target = shot.world ? new THREE.Vector3(...shot.target) : local(shot.target);
	let camera;
	if (shot.ortho) {
		// top-down map: orthographic, north (-Z) up
		const h = shot.ortho;
		camera = new THREE.OrthographicCamera(-h * (W / H), h * (W / H), h, -h, 1, 4000);
		camera.up.set(0, 0, -1);
	} else {
		camera = new THREE.PerspectiveCamera(shot.fov ?? 55, W / H, 0.5, 4000);
	}
	camera.position.copy(camPos);
	camera.lookAt(target);

	// Lighting (mirrors CycleService's Day / Night presets in spirit)
	scene.add(new THREE.HemisphereLight(night ? 0x7a52ff : 0xd6ecff, night ? 0x1a0f33 : 0x7d8a6a, night ? 0.9 : 1.5));
	const sun = new THREE.DirectionalLight(night ? 0xa58cff : 0xfff3df, night ? 0.9 : 2.8);
	sun.position.copy(target).add(new THREE.Vector3(-120, 220, -90));
	sun.target.position.copy(target);
	sun.castShadow = true;
	sun.shadow.mapSize.set(4096, 4096);
	const r = shot.shadowRadius ?? 90;
	Object.assign(sun.shadow.camera, { left: -r, right: r, top: r, bottom: -r, near: 10, far: 700 });
	sun.shadow.bias = -0.0004;
	sun.shadow.normalBias = 0.05;
	scene.add(sun, sun.target);
	if (night) {
		// nearest lights only (WebGL has a per-shader light budget)
		const near = [...data.lights].sort(
			(a, b) => target.distanceTo(new THREE.Vector3(...a.pos)) - target.distanceTo(new THREE.Vector3(...b.pos)),
		);
		for (const l of near.slice(0, shot.maxLights ?? 12)) {
			const pl = new THREE.PointLight(srgb(l.color), l.brightness * 60, l.range * 2.2, 1.6);
			pl.position.set(...l.pos);
			scene.add(pl);
		}
	}

	// Parts
	const stud = studTexture();
	const studMats = new Map();
	for (const p of data.parts) {
		const geo = geometryFor(p);
		let mat = materialFor(p, night);
		if (p.studs && p.shape === "Block" && p.material !== "Neon") {
			const key = `${p.size[0]}|${p.size[2]}|${p.color.join(",")}`;
			let top = studMats.get(key);
			if (!top) {
				const t = stud.clone();
				t.needsUpdate = true;
				t.repeat.set(p.size[0], p.size[2]);
				top = mat.clone();
				top.map = t;
				studMats.set(key, top);
			}
			mat = [mat, mat, top, mat, mat, mat];
		}
		const mesh = new THREE.Mesh(geo, mat);
		mesh.matrixAutoUpdate = false;
		mesh.matrix.copy(matrixOf(p.cf));
		mesh.castShadow = p.material !== "Neon" && p.transparency < 0.5;
		mesh.receiveShadow = true;
		scene.add(mesh);
	}

	// BillboardGuis: world-scaled sprites (size in studs), unlit
	for (const b of data.billboards) {
		if (b.lines.length === 0) continue;
		// what other players see: the owner-only rows are simply not there, and the plate shrinks to fit
		let lines = b.lines;
		let size = b.size;
		if (shot.hideOwner && lines.some((l) => l.owner)) {
			const keep = lines.filter((l) => !l.owner);
			const frac = keep.reduce((t, l) => t + l.height, 0);
			lines = keep.map((l) => ({ ...l, height: l.height / frac }));
			size = [size[0], size[1] * frac];
		}
		const pos = new THREE.Vector3(...b.pos);
		const maxD = Math.min(shot.labelDistance ?? 140, b.maxDistance || 1e9);
		if (pos.distanceTo(camPos) > maxD) continue;
		const tex = labelCanvas(lines, size[0], size[1], 0.16);
		const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, toneMapped: false, transparent: true, fog: false }));
		sprite.scale.set(size[0], size[1], 1);
		sprite.position.copy(pos).add(new THREE.Vector3(0, b.sizeOffset[1] * size[1], 0));
		scene.add(sprite);
	}

	// Map annotations (top-down design maps only)
	if (shot.mapLabels) {
		for (const m of data.mapLabels ?? []) {
			const w = shot.mapLabelWidth ?? 48;
			const tex = labelCanvas([{ kind: "text", text: m.text, color: hexToRgb(m.color), height: 1, stroke: 4, strokeColor: [0, 0, 0] }], w / 4, 2.2, 0.18);
			const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, toneMapped: false, transparent: true, fog: false, depthTest: false }));
			sprite.scale.set(w, w * (2.2 / (w / 4)), 1);
			sprite.position.set(m.pos[0], 60, m.pos[2]);
			sprite.renderOrder = 10;
			scene.add(sprite);
		}
	}

	// SurfaceGuis: text planes on the part face
	for (const s of data.surfaces) {
		const f = FACE[s.face];
		if (!f) continue;
		const w = f.w(s.size), h = f.h(s.size);
		const tex = labelCanvas(s.lines, w, h, 0.14);
		const plane = new THREE.Mesh(
			new THREE.PlaneGeometry(w, h),
			new THREE.MeshBasicMaterial({ map: tex, transparent: true, toneMapped: false, polygonOffset: true, polygonOffsetFactor: -2 }),
		);
		const depth = Math.abs(f.n[0]) * s.size[0] + Math.abs(f.n[2]) * s.size[2];
		const local = new THREE.Matrix4().makeRotationY(f.ry).setPosition(f.n[0] * (depth / 2 + 0.02), 0, f.n[2] * (depth / 2 + 0.02));
		plane.matrixAutoUpdate = false;
		plane.matrix.copy(matrixOf(s.cf).multiply(local));
		scene.add(plane);
	}

	const composer = new EffectComposer(renderer);
	composer.addPass(new RenderPass(scene, camera));
	composer.addPass(new UnrealBloomPass(new THREE.Vector2(W, H), night ? 0.9 : 0.35, 0.5, night ? 0.75 : 0.95));
	composer.addPass(new OutputPass());
	composer.render();
	return true;
};
