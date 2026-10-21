import QtQuick
import qs.theme

// Four stepped signal bars. Lit bars use `onColor`, the rest are Cold Steel.
Row {
    id: root

    property int bars: 0                         // 0..4 lit
    property color onColor: Theme.teal
    property bool large: false
    property color failColor: Theme.rust
    property bool failed: false                  // draw only the first bar, in failColor

    readonly property var heights: large ? [7, 12, 17, 22] : [4, 6, 8, 11]
    readonly property int barW: large ? 5 : 3

    spacing: large ? 2 : 2

    Repeater {
        model: 4
        Item {
            required property int index
            width: root.barW
            height: root.heights[3]

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: root.heights[parent.index]
                color: root.failed
                    ? (parent.index === 0 ? root.failColor : Theme.steel)
                    : (parent.index < root.bars ? root.onColor : Theme.steel)
            }
        }
    }
}
