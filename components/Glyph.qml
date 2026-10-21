import QtQuick
import QtQuick.Shapes
import qs.theme

// Stroked outline icon from SVG path data (see Icons.qml).
Item {
    id: root

    property string path: ""
    property color color: Theme.ash
    property real size: 14
    property real stroke: 1.5

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.size / 24; yScale: root.size / 24 }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.stroke
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.MiterJoin
            PathSvg { path: root.path }
        }
    }
}
