import QtQuick
import qs.theme

// Small outlined text button used under toasts and in popup rows. The first one is `primary`.
Item {
    id: root

    property string label: ""
    property bool primary: false
    property color accent: Theme.ivory

    signal clicked()

    implicitWidth: text.implicitWidth + 18
    implicitHeight: 22
    activeFocusOnTab: true

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        anchors.fill: parent
        color: mouse.containsMouse ? Theme.steel : "transparent"
        border.width: 1
        border.color: root.activeFocus ? Theme.ivory : Theme.steel
    }
    Lb {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: root.primary || mouse.containsMouse ? root.accent : Theme.ash
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
