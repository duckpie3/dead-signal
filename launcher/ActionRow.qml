import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import "Fuzzy.js" as Fuzzy

// One 40 px action in `>` mode. `item` = { name, desc, icon, key, idx, run }.
Item {
    id: root

    required property var item
    property bool selected: false

    signal hovered()
    signal activated()

    Layout.fillWidth: true
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        color: root.selected || mouse.containsMouse ? Theme.steel : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            color: root.selected ? Theme.copper : "transparent"
        }

        Item {
            implicitWidth: 28
            implicitHeight: 28
            Chamfer { anchors.fill: parent; cut: 4; fillColor: Theme.bg }
            Glyph {
                anchors.centerIn: parent
                path: root.item.icon
                size: 15
                color: root.selected ? Theme.ivory : Theme.ash
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Fuzzy.highlight(root.item.name, root.item.idx || [])
                color: root.selected ? Theme.ivory : Theme.ash
                font.family: Theme.sans
                font.pixelSize: 13
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.item.desc
                color: Theme.dust
                font.family: Theme.sans
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: (root.item.key || "") !== ""
            implicitWidth: cap.implicitWidth + 12
            implicitHeight: cap.implicitHeight + 4
            color: "transparent"
            border.width: 1
            border.color: Theme.steel

            Text {
                id: cap
                anchors.centerIn: parent
                text: root.item.key || ""
                color: root.selected ? Theme.ivory : Theme.ash
                font.family: Theme.mono
                font.pixelSize: 9
                font.capitalization: Font.AllUppercase
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: root.hovered()
        onClicked: root.activated()
    }
}
