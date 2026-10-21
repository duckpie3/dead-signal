import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// Pinned app in the empty state. Alt+<number> launches it.
Item {
    id: root

    property int number: 1
    property string name: ""
    property string cat: "SYS"
    readonly property var catColors: ({ "NET": Theme.teal, "DEV": Theme.brass, "MEDIA": Theme.sage, "SYS": Theme.ash })

    signal activated()

    Layout.fillWidth: true
    implicitHeight: 64

    Chamfer {
        anchors.fill: parent
        cut: 4
        fillColor: mouse.containsMouse ? Theme.steel : Theme.bg
        Behavior on fillColor { ColorAnimation { duration: Theme.animMs } }
    }

    Mono {
        x: 10
        y: 8
        text: String(root.number).padStart(2, "0")
        color: Theme.dust
        font.pixelSize: 9
    }

    Rectangle {
        x: parent.width - 14
        y: 10
        width: 4
        height: 4
        color: root.catColors[root.cat] || Theme.ash
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 8
        text: root.name
        color: mouse.containsMouse ? Theme.ivory : Theme.ash
        font.family: Theme.sans
        font.pixelSize: 13
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
