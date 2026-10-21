import QtQuick
import qs.theme

// Row of small square segments, like a level meter.
Row {
    id: root

    property int count: 12
    property int filled: 0
    property color onColor: Theme.teal
    property color offColor: Theme.steel
    property int warnFrom: -1               // segments at or above this index use warnColor
    property color warnColor: Theme.copper
    property int segW: 3
    property int segH: 10

    spacing: 2

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            width: root.segW
            height: root.segH
            color: index < root.filled
                ? (root.warnFrom >= 0 && index >= root.warnFrom ? root.warnColor : root.onColor)
                : root.offColor
        }
    }
}
