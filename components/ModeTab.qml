import QtQuick
import qs.theme
import qs.components

// APPS / CMD / CALC / WIN selector in the launcher header.
Item {
    id: root

    property string label: ""
    property bool active: false

    signal clicked()

    implicitWidth: text.implicitWidth + 18
    implicitHeight: 24

    Rectangle {
        anchors.fill: parent
        color: root.active ? Theme.steel : (mouse.containsMouse ? Theme.steel : "transparent")
        opacity: root.active ? 1 : 0.6
    }

    // Copper bar on the active tab.
    Rectangle {
        visible: root.active
        width: parent.width
        height: 2
        color: Theme.copper
    }

    Lb {
        id: text
        anchors.centerIn: parent
        text: root.label
        color: root.active ? Theme.ivory : Theme.dust
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
