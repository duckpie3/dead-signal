import QtQuick
import qs.theme

// 36x18 chamfered switch. The knob steps across; its colour says whether it is on.
Item {
    id: root

    property bool checked: false
    property color onColor: Theme.teal

    signal toggled()

    implicitWidth: 36
    implicitHeight: 18
    activeFocusOnTab: true

    Keys.onSpacePressed: root.toggled()
    Keys.onReturnPressed: root.toggled()
    Keys.onEnterPressed: root.toggled()

    Chamfer { anchors.fill: parent; cut: 3; fillColor: Theme.steel }
    Rectangle { x: 1; y: 1; width: parent.width - 2; height: parent.height - 2; color: Theme.bg }

    Rectangle {
        y: 3
        width: 14
        height: 12
        x: root.checked ? 19 : 3
        color: root.checked ? root.onColor : Theme.dust
        Behavior on x { NumberAnimation { duration: Theme.reduceMotion ? 0 : 100 } }
        Behavior on color { ColorAnimation { duration: Theme.reduceMotion ? 0 : 100 } }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.ivory
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
