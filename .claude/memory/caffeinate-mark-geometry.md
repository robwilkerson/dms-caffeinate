---
name: caffeinate-mark-geometry
description: CaffeinateMark draws Lucide's coffee path data as a Shape; why it fits to ink rather than viewBox and why inkScale exists
metadata:
  type: project
---

`CaffeinateMark.qml` draws the mug from **Lucide's `coffee`** path data (ISC licensed) as a
`Shape`/`ShapePath`/`PathSvg`, not from an icon font and not from an SVG file. The pattern is
borrowed from `ProtonVpnMark.qml` in the sibling `dms-protonvpn` repo.

**Why stroke-authored matters.** Lucide authors strokes, so `strokeColor` with
`fillColor: "transparent"` yields a true outline. A *filled* icon (Font Awesome's `mug-hot`,
for instance) cannot be turned into an outline this way — its path describes a silhouette, so
stroking it traces the silhouette's contour and every feature gains a doubled edge. That turns
to mush at 16–20px. If the mark is ever reskinned, the replacement must be stroke-authored.

**Two corrections the naive approach gets wrong**, both learned by looking at the real bar:

1. **Fit to the ink, not the viewBox.** Lucide's 24 box reserves its top third for steam
   ticks. Honouring the full box leaves the mug visibly smaller than its neighbours. The
   component declares explicit `contentX/Y/W/H` bounds for the mug alone (stroke included) and
   scales those to `size`.
2. **`inkScale` (0.85) is not a fudge.** Material Symbols draw on a 24 grid with the ink
   occupying roughly 20 units, so every native bar glyph carries built-in padding. Fitting our
   ink to the full `size` made the mug read ~18% larger than everything beside it. `inkScale`
   restores that breathing room.

`strokeWeight` is in path units and is multiplied by `fitScale` when rendered, so shrinking the
mark also thins the line. Callers pass `2.0` to land near 1.7px on a default bar.

`inkWidth`/`inkHeight`/`inkTop` are exposed because both corrections inset the mug from the
item's edges. Anything positioning against the mug — the popout's animated steam anchors to
`inkTop` — must use these, not the item's own bounds, or it floats clear of the cup.

One thing this cannot reach: `ccWidgetIcon` in [[plugin-identity]] takes a Material Symbols
*name* string, so the Control Center's collapsed widget row still shows `local_cafe`. Making
that a component is upstream DMS territory.

See [[bar-pill-ring-design]] for which states show the mark and at what size.
