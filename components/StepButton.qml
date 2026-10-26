import QtQuick
import qs.theme

// 24 px chamfered − / + button for steppers.
Item {
    id: root

    property string path: Icons.plus
    signal clicked()

    implicitWidth: 24
    implicitHeight: 24
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Chamfer { anchors.fill: parent; cut: 3; fillColor: Theme.steel }
    Chamfer {
        anchors.fill: parent
        anchors.margins: 1
        cut: 2
        fillColor: mouse.containsMouse ? Theme.panel : Theme.bg
    }
    Glyph { anchors.centerIn: parent; path: root.path; color: Theme.ivory; size: 10; stroke: 2 }
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.ivory
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
