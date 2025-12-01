# Polygon Terrain Integration Plan

This plan captures the design from `docs/polygon terrain.txt` and how we will integrate it into the editor and runtime.

## Goals
- Add a polygon editing mode in the editor (panel + in-scene tools) for creating and editing polygon terrain shapes.
- Polygons are scene-only entities (no per-instance DB entry) but use reusable `PolygonTemplate` data for textures/zone widths/smoothing defaults.
- When polygon mode is off, polygons behave like regular selectable scene entities (hover/select/delete, inspector).

## Data Layer
- New category: `PolygonTemplate` (stored at `res://data/polygon_templates`).
- Resource: `PolygonTemplateData` (id, tags, border/transition/core textures, zone widths, angle range, smoothing defaults, optional material/shader ref).
- Data Editor support: list templates, edit fields, preview textures/tint, save/load via DataRegistry.

## Editor UX
- Ribbon: add a “Polygon” panel toggle (sits with Save/Load/Data/Templates). Opens a polygon panel below the ribbon.
- Polygon panel shows: template dropdown, border/transition/core textures, zone widths, smoothing N/S, angle min/max, per-polygon overrides, vertex list, add/delete buttons, bake/generate buttons.
- Hover tips: polygon summary (name/template/vertex count) under the cursor.
- Inspector (right sidebar) shows polygon transform and template choice when a polygon is selected.

## In-Scene Editing (Polygon Mode On)
- Left-click select nearest vertex/edge of the active polygon.
- Drag vertex to move (respect global snap). Shift+click on edge inserts a vertex. Delete key removes a vertex (min 3 verts).
- Visual gizmos: vertex handles, edge midpoint handles for insert, polygon outline highlight.
- Bake/preview button regenerates mesh and collision from current vertices + template.

## Runtime/Generation
- `PolygonTerrain2D` node:
  - Stores vertices (original), template_id, zone widths overrides, smoothing params (N, steps).
  - Generates visual mesh (smoothed if enabled) with material sampling border/transition/core textures by distance-to-edge.
  - Generates collision from original (or simplified) polygon.
- Angle-based template logic: optional min/max degrees per edge to choose templates (initially basic support).

## Incremental Implementation Steps
1) Data plumbing: add `PolygonTemplateData`, DataRegistry category, DataEditor controls, default template asset.
2) Node scaffolding: create `PolygonTerrain2D` with vertices/template refs, stubbed mesh/collision generation.
3) Editor mode toggle + panel: add Polygon panel, hook toggle, basic fields (template, smoothing, widths).
4) Basic editing tools: select/add/move/delete vertices with snap, outline/handles rendering, hover summary.
5) Bake mesh/collision from vertices + template; apply material/textures.
6) Angle-based template selection + smoothing refinement.
7) Entity population (future): placement rules inside polygon/edges.

This file should evolve as we implement; tick items as done and refine remaining steps.
