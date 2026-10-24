import QtQuick
import qs.theme

// Chamfered icon button for transport controls. `big` is the 48 px play button with a top bar.
Item {
    id: root

    property string path: ""
    property color color: Theme.ivory
    property bool big: false
    property color mark: "transparent"      // 2x2 pixel, top left
    property color bar: "transparent"       // 2 px bar along the top (big button)
    property string badge: ""               // tiny mono label, bottom right
    property bool hovered: mouse.containsMouse

    signal clicked()

    implicitWidth: big ? 48 : 36
    implicitHeight: implicitWidth
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    Keys.onReturnPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Chamfer { anchors.fill: parent; cut: root.big ? 6 : 5; fillColor: Theme.steel }
    Chamfer {
        anchors.fill: parent
        anchors.margins: 1
        cut: root.big ? 5 : 4
        fillColor: root.big
            ? (mouse.containsMouse ? Qt.lighter(Theme.steel, 1.2) : Theme.steel)
            : (mouse.containsMouse ? Theme.panel : Theme.bg)
    }

    Rectangle { visible: root.bar.a > 0; x: 1; y: 1; width: parent.width - 2; height: 2; color: root.bar }
    Rectangle { x: 5; y: 4; width: 2; height: 2; color: root.mark; visible: root.mark.a > 0 }

    Glyph {
        anchors.centerIn: parent
        path: root.path
        color: root.color
        size: root.big ? 20 : 15
    }

    Mono {
        visible: root.badge !== ""
        text: root.badge
        font.pixelSize: 8
        color: Theme.teal
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
    }

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
