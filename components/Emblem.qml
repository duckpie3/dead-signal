import QtQuick
import qs.theme

// 7x5 pixel peak with one copper "dead" pixel in the baseline.
Item {
    id: root

    property int pixel: 2
    implicitWidth: 7 * pixel
    implicitHeight: 5 * pixel

    readonly property var px: [
        [3, 0], [2, 1], [4, 1], [1, 2], [5, 2], [0, 3], [6, 3],
        [0, 4], [1, 4], [2, 4], [4, 4], [5, 4], [6, 4]
    ]

    Repeater {
        model: root.px
        Rectangle {
            required property var modelData
            x: modelData[0] * root.pixel
            y: modelData[1] * root.pixel
            width: root.pixel
            height: root.pixel
            color: Theme.ash
        }
    }

    Rectangle {
        x: 3 * root.pixel
        y: 4 * root.pixel
        width: root.pixel
        height: root.pixel
        color: Theme.copper
    }
}
