# Densetsu Geometry OBJ Export

Exports selected scene geometry to Wavefront OBJ.

## Current coverage
- `MeshInstance3D` (including nested hierarchies under selected roots)
- `CSGShape3D` trees (exports baked result from selected CSG root or top-level CSG roots)
- `MultiMeshInstance3D` (expands instances into regular geometry in OBJ)
- Per-surface material grouping (`usemtl`) + generated `.mtl`

## How to use
1. Enable plugin in Project Settings -> Plugins:
   - `Densetsu Geometry OBJ Export`
2. In the Scene tree, select one or more `Node3D` roots.
3. Use menu:
   - `Project/Tools -> Densetsu/Export Selected Scene Geometry to OBJ`
4. Choose output `.obj` path.

## Notes
- OBJ export is geometry snapshot only. It does not preserve animation/skeleton data.
- Non-triangle primitives are skipped.
- UV V coordinate is flipped by default for common DCC compatibility.
- Collision shapes are ignored during export traversal.
- The OBJ references an absolute `.mtl` path, and `.mtl` texture entries use absolute paths when resolvable.
- Winding correction is enabled by default (`enforce_outward_winding`) to reduce inside-out/face-flip conversion issues.
  - It prioritizes source normal consistency, then uses geometry heuristics against a mesh-item center.
  - For low-confidence surfaces, it applies a nearby-surface continuity pass before final face write.
  - For open/non-manifold meshes this is best-effort, not mathematically guaranteed.
- Topology cleanup is enabled by default:
  - `manifold_only`: keeps only closed 2-manifold triangle shells, dropping open/non-manifold regions.
  - `remove_enclosed_faces`: culls closed shells detected as fully enclosed by other closed shells.
  - Unused points are removed from exported surfaces after triangle filtering (vertex compaction).
