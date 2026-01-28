# Issue Log

A lightweight, running list of open issues and their status.

## Pinned (Low)
- [Open][Low] Step snapping sometimes requires a slight rotation/nudge when moving straight into a step, even when sensors report hits. Repro: move forward into the smallest step in `engine3d/tests/Actor3D_Test.tscn` without rotating; player may continue pushing without snapping.
- [Open][Low] Roll/crouch input behavior will need further tuning (separation of roll vs crouch, contextual rules) after core movement stabilizes.
- [Open][Low] AnimDebugOverlay hotkey toggle is unreliable; overlay stays on. (Low priority per directive.)

## Open
- [Open][Med] Player model remains in T-pose; animations not playing despite sanitized Action Adventure library (no error spam). Repro: run `engine3d/tests/Actor3D_Test.tscn`, move/idle; mesh stays in rest pose.

## Resolved
- (none)
