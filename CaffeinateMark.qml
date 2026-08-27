// The Caffeinate mug, drawn from Lucide's `coffee` glyph.
//
// Source: https://github.com/lucide-icons/lucide, ISC licensed. The glyph is authored as
// strokes rather than a filled silhouette, so it renders as a true outline at bar size
// instead of a traced contour. Lucide's steam ticks are dropped: the mug is the whole
// mark, and state is carried by colour and by the caller's countdown ring.

import QtQuick
import QtQuick.Shapes
import qs.Common

Item {
    id: mark

    property real size: 24
    property color markColor: Theme.surfaceText
    // Lucide authors at stroke-width 2 in a 24 box. Scaling that verbatim to bar size
    // renders too heavy next to Material Symbols, so the caller can thin it.
    property real strokeWeight: 2

    width: size
    height: size

    // Material Symbols draw on a 24 grid with the ink occupying roughly 20 units, so every
    // native bar glyph carries built-in padding. Fitting this mark's ink to the full size
    // would make it read noticeably larger than its neighbours; inkScale restores the same
    // breathing room.
    property real inkScale: 0.85

    // Fit to the ink rather than to the nominal 24 viewBox, whose top third is empty once
    // the steam is gone. Bounds include the stroke.
    readonly property real contentX: 2
    readonly property real contentY: 7
    readonly property real contentW: 20
    readonly property real contentH: 15
    readonly property real fitScale: (size * inkScale) / Math.max(contentW, contentH)

    // Where the ink actually lands inside the item. inkScale and the ink-fitting both inset
    // the mug from the item's edges, so anything positioning itself against the mug — steam,
    // for instance — has to anchor to these rather than to the padded box.
    readonly property real inkWidth: contentW * fitScale
    readonly property real inkHeight: contentH * fitScale
    readonly property real inkTop: (size - inkHeight) / 2

    Shape {
        preferredRendererType: Shape.CurveRenderer

        // Scale originates at (0,0), so position the unscaled origin such that the scaled
        // content lands centred in the parent.
        x: (mark.size - mark.contentW * mark.fitScale) / 2 - mark.contentX * mark.fitScale
        y: (mark.size - mark.contentH * mark.fitScale) / 2 - mark.contentY * mark.fitScale

        transform: Scale {
            xScale: mark.fitScale
            yScale: mark.fitScale
        }

        // Mug body and handle, as one continuous stroke.
        ShapePath {
            strokeColor: mark.markColor
            strokeWidth: mark.strokeWeight
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: "M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1"
            }
        }
    }
}
