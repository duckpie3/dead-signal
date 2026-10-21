import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import "Fuzzy.js" as Fuzzy

// One 40 px result. `item` = { name, desc, cat, tile, idx, rel, run }.
Item {
    id: root

    required property var item
    property bool selected: false
    readonly property var catColors: ({
        "NET": Theme.teal, "DEV": Theme.brass, "MEDIA": Theme.sage,
        "SYS": Theme.ash, "WIN": Theme.dust, "CMD": Theme.dust, "CALC": Theme.brass
    })

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

        // Selection marker.
        Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            color: root.selected ? Theme.copper : "transparent"
        }

        // Letter tile standing in for the app icon.
        Item {
            implicitWidth: 28
            implicitHeight: 28

            Chamfer {
                anchors.fill: parent
                cut: 4
                fillColor: Theme.bg
            }

            Text {
                anchors.centerIn: parent
                text: root.item.tile
                color: Theme.ash
                font.family: Theme.mono
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Fuzzy.highlight(root.item.name, root.item.idx)
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

        // Category: square + label.
        RowLayout {
            Layout.preferredWidth: 54
            spacing: 6

            Rectangle {
                implicitWidth: 4
                implicitHeight: 4
                color: root.catColors[root.item.cat] || Theme.ash
            }

            Lb { text: root.item.cat }
        }

        // Relevance / usage, 0-5 segments.
        SegMeter {
            count: 5
            filled: root.item.rel
            segW: 3
            segH: 10
            onColor: root.selected ? Theme.ivory : Theme.ash
        }

        Glyph {
            path: Icons.enter
            color: Theme.ash
            opacity: root.selected ? 1 : 0
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
