# Mesh pipeline proposal (awaiting your decision)

The vertical slice uses part-based models built in code (`src/shared/World/Models`). They're in source
control, light and fast to iterate on, but blocky. For higher-fidelity versions, here's what I recommend.

## Recommended: Blender → FBX → Studio 3D Importer → MeshParts

1. **Model** each character in Blender, low-poly (target 1–4k triangles; Roblox caps a MeshPart at 20k)
   with a simple colour texture (a palette atlas keeps it cheap) or vertex colours baked to a texture.
2. **Rig** with a few bones (root, body, head, plus limbs where needed) so idle/walk animations look
   better than code bobbing. Our code rig (Root + Body Motor6D) maps directly onto a root/body bone pair.
3. **Export FBX** (one file per character, Y-up, forward -Z, scale 0.01, apply transforms).
4. **Import in Studio** with the 3D Importer (File → Import 3D). It creates MeshParts + SurfaceAppearance
   (PBR textures) and a rig if bones exist.
5. **Upload** the asset. Packages make updates easy: one package per character, auto-update on.
6. **Plug in**: add a builder in `Models/` that clones the package (or loads the asset id from
   `Config/Species.luau` `model = "mesh:<assetId>"`) and adds our Root, attachments (Nameplate, Vfx,
   Trail) and tags. Variants keep working: they recolour via SurfaceAppearance.Color / a swapped texture
   set (Gold, Diamond, Dark get their own texture variants; Rainbow tints).
7. **Animations**: author idle/walk in Studio's Animation Editor or Blender, upload, and reference the ids
   in Config. The client animator switches from code bobbing to `Animator:LoadAnimation`.

### What you'd do by hand
- The modelling, texturing and rigging in Blender (or commission an artist: brief + reference image +
  poly/texture budget per character).
- In Studio: import each FBX, check scale/orientation, publish as a package, paste the asset id into
  `Config/Species.luau`. Roblox moderates uploads, so expect some delay and occasional rejections.
- Upload animations (they must be owned by the experience owner: user or group).

### Why not the alternatives
- **Keep part-based forever**: cheapest, but won't hit the "looks like the meme" bar for organic shapes.
- **Creator Store models**: fast, but quality, licensing and IP provenance are unknown. Not without your
  explicit OK per model (your rule).
- **AI mesh generation** (e.g. Roblox's own generative tools or third-party text/image-to-3D): good for
  blockouts, but output usually needs cleanup and has the same IP-likeness concerns. Usable as a starting
  point inside the Blender step.

## Decision needed
1. Go with Blender → FBX → 3D Importer (recommended)?
2. Who models: you, a commissioned artist, or a mix?
3. Target style: chunky low-poly (matches the world) or smoother "toy" look?
