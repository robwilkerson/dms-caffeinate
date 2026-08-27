---
name: bar-pill-ring-design
description: Why the bar pill keeps a countdown ring with a visible idle track, and how the pill and glyph are sized against bar config
metadata:
  type: project
---

**The ring stays.** The bar pill draws a `RadialProgressRing` countdown, not a plain `local_cafe` glyph. The ancestor project went back and forth on this (removed the bar ring, then restored it behind a `showProgressRing` toggle defaulting on); here it is unconditional. There is no toggle and no reason to add one for parity. See [[fork-origin]].

**Idle track is deliberately visible.** `backgroundOpacityInactive` is `0.4` on the bar pill (`CaffeineWidget.qml:251`, `:297`), against the `RadialProgressRing.qml:16` default of `0.05`. The low default renders a near-invisible idle track, which makes the pill look broken when nothing is counting down; `0.4` keeps the ring legible as an affordance at rest. The popout uses `0.08` (`:91`), where the surrounding surface already frames it. Treat `0.4` as intentional, not a stray tweak.

**Sizing.** `Theme.barIconSize(barThickness, offset, maximizeWidgetIcons, iconScale)` derives icon size from live bar config, so the pill tracks bar thickness and the user's icon scale instead of a hardcoded `Theme.iconSize`:

- `barPillIconSize` uses offset **`0`** — the full pill, because the ring needs the outer diameter (`CaffeineWidget.qml:229`).
- `barGlyphIconSize` shrinks the glyph inside that pill by the `Theme.iconSizeSmall / Theme.iconSize` ratio (`:230`), leaving room for the ring to orbit it.

That differs from the canonical DMS single-icon widget pattern in `/usr/share/quickshell/dms/PLUGINS/README.md`, which native widgets (NotepadButton, ColorPicker) follow: perpendicular dimension = `root.widgetThickness`, glyph `size: root.iconSize`, where `PluginComponent` already computes `iconSize` with offset **`-4`**. That pattern assumes no ring. A ring-free variant built to it lives on the inert branch `explore/scaling-without-ring`; consult it only as a reference for native parity, since the ring is not going away.

**Residual:** `local_cafe` reads slightly high next to geometric glyphs (wifi, battery) because of the font's optical center. Fixing it needs a manual vertical nudge that breaks native parity, so it is left alone.
