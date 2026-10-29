import QtQuick
import qs.theme

// 7x5 pixel emblem with one copper "dead" pixel in the baseline (centre of the second-lowest row; the cell below it stays empty).
// The only definition: the bar and the lock screen both use this component.
// Same dot:gap rule as every other dot-matrix element: pixel 2, gap 1.
Item {
    id: root

    property int pixel: 2
    property int gap: 1
    readonly property int step: pixel + gap
    implicitWidth: 7 * step - gap
    implicitHeight: 5 * step - gap

    readonly property var px: [
        [3, 0], [2, 1], [3, 1], [4, 1], [2, 2], [3, 2], [4, 2], [1, 3], [2, 3], [4, 3], [5, 3], [1, 4], [5, 4]
    ]

    Repeater {
        model: root.px
        Rectangle {
            required property var modelData
            x: modelData[0] * root.step
            y: modelData[1] * root.step
            width: root.pixel
            height: root.pixel
            color: Theme.ash
        }
    }

    Rectangle {
        x: 3 * root.step
        y: 2 * root.step
        width: root.pixel
        height: root.pixel
        color: Theme.copper
    }
}
