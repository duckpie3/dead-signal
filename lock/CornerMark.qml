import QtQuick
import qs.theme

// 14 px registration mark in a screen corner.
Item {
    id: root

    property bool atRight: false
    property bool atBottom: false

    width: 14
    height: 14

    Rectangle { x: 0; y: root.atBottom ? 13 : 0; width: 14; height: 1; color: Theme.dust }
    Rectangle { x: root.atRight ? 13 : 0; y: 0; width: 1; height: 14; color: Theme.dust }
}
