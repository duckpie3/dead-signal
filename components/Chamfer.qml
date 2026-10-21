import QtQuick
import QtQuick.Shapes
import qs.theme

// Filled rectangle with the top-left and bottom-right corners cut at 45°.
Shape {
    id: root

    property color fillColor: Theme.panel
    property real cut: Theme.cut
    property real cutTL: cut               // top-left cut, defaults to `cut`
    property real cutBR: cut               // bottom-right cut, defaults to `cut`

    preferredRendererType: Shape.CurveRenderer

    Behavior on fillColor { ColorAnimation { duration: Theme.animMs } }

    ShapePath {
        fillColor: root.fillColor
        strokeColor: "transparent"
        strokeWidth: -1

        startX: root.cutTL
        startY: 0
        PathLine { x: root.width;              y: 0 }
        PathLine { x: root.width;              y: root.height - root.cutBR }
        PathLine { x: root.width - root.cutBR; y: root.height }
        PathLine { x: 0;                       y: root.height }
        PathLine { x: 0;                       y: root.cutTL }
        PathLine { x: root.cutTL;              y: 0 }
    }
}
