# Densetsu Autocliff (WIP)

Editor-assisted cliff mesh placement for terrain/map authoring.

## What It Does

- Works only with a `Terrain3D` target node.
- Samples a rectangular area over the selected `Terrain3D` using downward raycasts.
- Keeps only hits in a slope range (candidate cliff surfaces).
- Selects a mesh from a user-provided pool.
- Aligns mesh orientation to surface normal with random yaw jitter.
- Pushes meshes into the surface by a configurable bury offset.
- Outputs either:
  - `MultiMeshInstance3D` (recommended for heavy instancing), or
  - individual `MeshInstance3D`.

## Usage

1. Enable plugin: `Project > Project Settings > Plugins > Densetsu Autocliff`.
2. Open the **Autocliff** dock (right dock).
3. Select your `Terrain3D` node in Scene tree and click **Use Selected**.
4. Add cliff meshes:
   - **Add Mesh Files** (`.obj`, `.tres`, `.res`) or
   - **Add Selected Node Mesh**.
5. Configure sampling/slope/density/offset options.
6. Click **Autocliff**.

## Notes

- Ray hits are always constrained to the selected Terrain3D subtree.
- `Map slope to mesh list order` lets you assign mesh pool entries from lower slope to steeper slope.
- Generated output is created under the target's parent node and tagged with group:
  - `densetsu_autocliff`

## Current Limitations

- First-pass heuristic: no biome/topology masks yet.
- No collision occlusion test for "already occupied by another cliff mesh" yet.
- No placement scoring by mesh footprint yet.

These are intended next steps for the procedural toolchain.
