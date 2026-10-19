# assets/

Nothing is here yet: **the repository contains no 3D model at all** (see `docs/SETUP-REPORT.md` §1.2).
The Roadster must be added by you before Stage 2 of the plan.

## Expected layout

```
assets/
  roadster/
    roadster.glb              # glTF 2.0 binary, PBR metallic-roughness
    PROVENANCE.md             # REQUIRED — license, source URL, author, date obtained
    README.md                 # optional: polycount, materials, what is rigged/animated
  environment/                # track/props, same rule: PROVENANCE.md per source
  hdri/                       # IBL sources + PROVENANCE.md
```

## Rules

1. **glTF/GLB only** for runtime assets. FBX/BLEND belong in `assets-src/` (not shipped) and are
   converted in CI — Blender cannot be installed in this sandbox.
2. **`PROVENANCE.md` is mandatory** before anything ships. No file without a recorded license and
   source URL is allowed into a build; the asset pipeline script should fail the build if it is missing.
3. No Git LFS (CI's `actions/checkout` cannot reach LFS from this environment's constraints).
   Large binaries that must be versioned go in a release instead, or stay out of the repo.
4. Ship-ready assets are generated, never hand-authored: run `gltf-transform optimize` with
   `--compress meshopt`, LOD simplification, and KTX2/BasisU textures. Keep the authored source
   and the optimized output side by side (`roadster.glb` / `roadster_mobile.glb`).

## Interim stand-ins already verified reachable + licensed

| Asset | Size | License | Use |
| --- | --- | --- | --- |
| `ClearCoatCarPaint.glb` (Khronos glTF-Sample-Assets) | 116,948 B | **CC0-1.0** | paint/clearcoat shader gate — no attribution needed |
| `CarConcept.glb` (Khronos glTF-Sample-Assets) | 11,778,688 B | **CC-BY-4.0** | geometry/LOD/streaming trials; needs a NOTICE attribution if shipped |

Fetch either with (raw.githubusercontent is blocked here; codeload is not):

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/KhronosGroup/glTF-Sample-Assets
cd glTF-Sample-Assets && git sparse-checkout set Models/CarConcept Models/ClearCoatCarPaint
```
