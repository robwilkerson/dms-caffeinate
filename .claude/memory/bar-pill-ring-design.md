---
name: bar-pill-ring-design
description: Why the bar mark is a bare mug with a conditional ring, no label, and a fixed footprint, and how the mug and ring are sized
metadata:
  type: project
---

**The bar pill is a fixed-size square in every state.** It never grows to hold text and its
footprint never changes, so enabling a session does not shift the rest of the bar. Both
orientations share one `barPill` component; the countdown label was the only thing that ever
differed between them, and it is gone.

**Three states, no more.** Idle is a bare mug in `surfaceText`. A timed session adds the
`RadialProgressRing` and shrinks the mug inside it. A session with no end is the mug at full
size in `primary` — no ring. A ring pinned at 360 read as a progress bar that never moves,
which is worse than no ring; the accent colour carries that state instead. This reverses an
earlier decision that kept the ring unconditional with a visible idle track at
`backgroundOpacityInactive: 0.4`. That idle track is gone: with no ring at rest there is
nothing to keep legible.

**Steam was tried and rejected on the bar.** Lucide's steam ticks live in the top third of the
viewBox, so showing them changes the mark's content bounds — the mug drops and shrinks to make
room. A glyph that moves when you toggle it is worse than one that only changes colour. Steam
stays in the popout (`animatedCoffeeCup`), where there is room and it is already animated.

**Sizing.** `Theme.barIconSize(barThickness, offset, maximizeWidgetIcons, iconScale)` derives
every size from live bar config, so the mark tracks bar thickness and the user's icon scale:

- `barPillIconSize` — offset **`0`**, the constant outer footprint the ring needs.
- `barIdleGlyphSize` — offset **`-4`**, matching what native DMS widgets use, so the idle mug
  reads as an ordinary bar glyph beside wifi and battery.
- `barActiveGlyphSize` — shrunk by the `Theme.iconSizeSmall / Theme.iconSize` ratio, leaving
  the ring room to orbit.

**The mug is [[caffeinate-mark-geometry]], not a font glyph.** It was `local_cafe` from Material
Symbols, whose ink sits high in its em box (the saucer leaves dead space below), so it rode high
next to geometric neighbours and needed a vertical fudge. Drawing from path data and fitting to
the ink removed the fudge entirely.
