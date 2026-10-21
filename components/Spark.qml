import QtQuick
import qs.theme

// Bottom-aligned history bars. `values` are 0..1; colorFn(v) picks each bar's color.
Row {
    id: root

    property var values: []
    property int barW: 2
    property int minH: 2
    property int maxH: 10
    property var colorFn: function (v) { return Theme.teal }

    spacing: 1

    Repeater {
        model: root.values.length
        Item {
            required property int index
            readonly property real v: Math.max(0, Math.min(1, root.values[index]))
            width: root.barW
            height: root.maxH

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.round(root.minH + (root.maxH - root.minH) * parent.v)
                color: root.colorFn(parent.v)
            }
        }
    }
}
