import QtQuick
import qs.theme

// Small square icon button with hover fill and a keyboard focus ring.
Item {
    id: root

    property string path: ""
    property color color: Theme.ash

    signal clicked()

    implicitWidth: 24
    implicitHeight: 24
    activeFocusOnTab: true

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors.fill: parent
        color: mouse.containsMouse ? Theme.steel : "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.ivory
    }

    Glyph {
        anchors.centerIn: parent
        path: root.path
        color: root.color
        size: 12
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
