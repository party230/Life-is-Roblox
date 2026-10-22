#!/usr/bin/env python3
"""Renders build/models.json (from dump.luau) to an SVG contact sheet: each model from a front-3/4 view.

A tiny software renderer (orthographic, painter's algorithm, flat shading) so part-based models can be
checked without opening Studio. Usage: python3 tools/preview/render.py build/models.json build/models.svg
"""
import json
import math
import sys

YAW = math.radians(-35)   # look from front-left
PITCH = math.radians(18)
LIGHT = (-0.4, 0.8, -0.45)


def norm(v):
    l = math.sqrt(sum(c * c for c in v)) or 1
    return tuple(c / l for c in v)


LIGHT = norm(LIGHT)


def to_world(cf, p):
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf
    return (
        x + r00 * p[0] + r01 * p[1] + r02 * p[2],
        y + r10 * p[0] + r11 * p[1] + r12 * p[2],
        z + r20 * p[0] + r21 * p[1] + r22 * p[2],
    )


def to_view(p):
    # camera in front (-Z) of the model: rotate the world so -Z faces the viewer
    x, y, z = p
    cy, sy = math.cos(YAW), math.sin(YAW)
    x, z = x * cy - z * sy, x * sy + z * cy
    cp, sp = math.cos(PITCH), math.sin(PITCH)
    y, z = y * cp - z * sp, y * sp + z * cp
    return (x, y, z)  # larger z = farther from the viewer


def box_faces(sx, sy, sz):
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    v = [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
         (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)]
    idx = [(0, 1, 2, 3), (5, 4, 7, 6), (4, 0, 3, 7), (1, 5, 6, 2), (3, 2, 6, 7), (4, 5, 1, 0)]
    return [[v[i] for i in f] for f in idx]


def wedge_faces(sx, sy, sz):
    # Roblox wedge: tall face at back (+Z), slope down to the front (-Z) bottom edge
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    b0, b1, b2, b3 = (-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz)
    t2, t3 = (hx, hy, hz), (-hx, hy, hz)
    return [[b3, b2, b1, b0], [b2, b3, t3, t2], [b0, b1, t2, t3], [b0, t3, b3], [b1, b2, t2]]


def cyl_faces(sx, sy, sz, n=14):
    hx = sx / 2
    ry, rz = sy / 2, sz / 2
    ring = [(math.cos(2 * math.pi * i / n) * ry, math.sin(2 * math.pi * i / n) * rz) for i in range(n)]
    faces = []
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        faces.append([(-hx, a[0], a[1]), (-hx, b[0], b[1]), (hx, b[0], b[1]), (hx, a[0], a[1])])
    faces.append([(hx, y, z) for y, z in ring])
    faces.append([(-hx, y, z) for y, z in reversed(ring)])
    return faces


def sphere_faces(rx, ry, rz, seg=12, rings=8):
    pts = []
    for r in range(rings + 1):
        th = math.pi * r / rings
        row = []
        for s in range(seg):
            ph = 2 * math.pi * s / seg
            row.append((rx * math.sin(th) * math.cos(ph), ry * math.cos(th), rz * math.sin(th) * math.sin(ph)))
        pts.append(row)
    faces = []
    for r in range(rings):
        for s in range(seg):
            a, b = pts[r][s], pts[r][(s + 1) % seg]
            c, d = pts[r + 1][(s + 1) % seg], pts[r + 1][s]
            faces.append([a, d, c, b])
    return faces


def part_faces(p):
    sx, sy, sz = p["size"]
    shape = p["shape"]
    if shape == "Wedge":
        return wedge_faces(sx, sy, sz)
    if shape == "Cylinder":
        return cyl_faces(sx, sy, sz)
    if shape == "Ball":
        r = min(sx, sy, sz) / 2
        return sphere_faces(r, r, r)
    if shape == "Ellipsoid":
        return sphere_faces(sx / 2, sy / 2, sz / 2)
    return box_faces(sx, sy, sz)


def render_model(m, ox, oy, scale):
    polys = []
    for p in m["parts"]:
        if p["transparency"] >= 0.99:
            continue
        col = p["color"]
        for face in part_faces(p):
            world = [to_world(p["cf"], v) for v in face]
            view = [to_view(v) for v in world]
            # face normal in view space for culling, world normal for light
            a, b, c = view[0], view[1], view[2]
            u = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
            v = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
            nz = u[0] * v[1] - u[1] * v[0]
            wa, wb, wc = world[0], world[1], world[2]
            wu = (wb[0] - wa[0], wb[1] - wa[1], wb[2] - wa[2])
            wv = (wc[0] - wa[0], wc[1] - wa[1], wc[2] - wa[2])
            wn = norm((wu[1] * wv[2] - wu[2] * wv[1], wu[2] * wv[0] - wu[0] * wv[2], wu[0] * wv[1] - wu[1] * wv[0]))
            shade = 0.55 + 0.45 * max(0, -(wn[0] * LIGHT[0] + wn[1] * LIGHT[1] + wn[2] * LIGHT[2]))
            depth = sum(q[2] for q in view) / len(view)
            pts = " ".join(f"{ox + q[0] * scale:.1f},{oy - q[1] * scale:.1f}" for q in view)
            rgb = tuple(int(max(0, min(1, c * shade)) * 255) for c in col)
            polys.append((depth, pts, rgb, nz))
    polys.sort(key=lambda t: -t[0])
    out = []
    for depth, pts, rgb, nz in polys:
        out.append(f'<polygon points="{pts}" fill="rgb{rgb}" stroke="rgba(27,21,48,0.35)" stroke-width="0.6" stroke-linejoin="round"/>')
    return "".join(out)


def main():
    data = json.load(open(sys.argv[1]))
    variants_mode = len(sys.argv) > 3 and sys.argv[3] == "--variants"
    if variants_mode:
        data = [m for m in data if m["name"] != "placeholder"]
    else:
        data = [m for m in data if m.get("variant", "Normal") == "Normal"]
    cols = 3
    cell_w, cell_h = (360, 380) if variants_mode else (520, 520)
    rows = math.ceil(len(data) / cols)
    W, H = cols * cell_w, rows * cell_h + 60
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
           f'<rect width="{W}" height="{H}" fill="#9fd4ff"/>',
           '<text x="24" y="40" font-family="sans-serif" font-size="26" font-weight="700" fill="#1B1530">' +
           ('Normal, Rainbow, Evil (bands scroll and lightning flickers in game)' if variants_mode else 'Rot Shift: part-based character models (headless preview, Normal variant)') + '</text>']
    for i, m in enumerate(data):
        cx = (i % cols) * cell_w + cell_w / 2
        cy = (i // cols) * cell_h + 60 + cell_h - 90
        x0 = (i % cols) * cell_w
        y0 = (i // cols) * cell_h + 60
        svg.append(f'<rect x="{x0 + 10}" y="{y0 + 10}" width="{cell_w - 20}" height="{cell_h - 20}" rx="18" fill="#4CB848" opacity="0.25"/>')
        svg.append(f'<ellipse cx="{cx}" cy="{cy + 6}" rx="120" ry="22" fill="#000" opacity="0.15"/>')
        scale = 34 if variants_mode else 52
        if variants_mode:
            cy = (i // cols) * cell_h + 60 + cell_h - 60
        svg.append(render_model(m, cx, cy, scale))
        label = f'{m.get("variant", "")} {m["displayName"]}' if variants_mode else m["displayName"]
        svg.append(f'<text x="{x0 + 24}" y="{y0 + 44}" font-family="sans-serif" font-size="{18 if variants_mode else 24}" font-weight="700" fill="#1B1530">{label}</text>')
        if not variants_mode:
            svg.append(f'<text x="{x0 + 28}" y="{y0 + 74}" font-family="sans-serif" font-size="16" fill="#1B1530">{m["partCount"]} parts</text>')
    svg.append("</svg>")
    open(sys.argv[2], "w").write("".join(svg))


main()
