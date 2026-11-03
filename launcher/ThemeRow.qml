import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import "Fuzzy.js" as Fuzzy

// One theme in the selector. `item` = { id, label, theme, idx, run }. The row is drawn with the
// current theme, but the little preview and the colour strip use the colours of the theme it stands for.
Item {
    id: root

    required property var item
    property bool selected: false
    readonly property var t: root.item.theme
    readonly property bool active: Themes.palette.id === root.item.id

    signal hovered()
    signal activated()

    Layout.fillWidth: true
    implicitHeight: 48

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

        // A miniature bar over the theme's backdrop: panel, active cell with its copper line, text, signal colours.
        Item {
            implicitWidth: 56
            implicitHeight: 32

            Rectangle { anchors.fill: parent; color: root.t.stage }
            Rectangle { x: 3; y: 3; width: parent.width - 6; height: 10; color: root.t.bg }
            Rectangle { x: 5; y: 5; width: 9; height: 6; color: root.t.steel }
            Rectangle { x: 5; y: 5; width: 9; height: 1; color: root.t.copper }
            Rectangle { x: 17; y: 7; width: 14; height: 2; color: root.t.ivory }
            Rectangle { x: 34; y: 6; width: 4; height: 4; color: root.t.teal }
            Rectangle { x: 40; y: 6; width: 4; height: 4; color: root.t.brass }
            Rectangle { x: 46; y: 6; width: 4; height: 4; color: root.t.sage }
            Rectangle { x: 3; y: 16; width: parent.width - 6; height: 13; color: root.t.panel }
            Rectangle { x: 6; y: 19; width: 20; height: 2; color: root.t.ivory }
            Rectangle { x: 6; y: 23; width: 32; height: 2; color: root.t.ash }
            Rectangle { x: 42; y: 19; width: 8; height: 6; color: root.t.rust }
            Rectangle { anchors.fill: parent; color: "transparent"; border.width: 1; border.color: Theme.steel }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                text: Fuzzy.highlight(root.item.label, root.item.idx || [])
                color: root.selected || root.active ? Theme.ivory : Theme.ash
                font.family: Theme.sans
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            // The palette: bg, panel, steel, ivory, ash, dust, copper, teal, brass, sage, rust.
            Row {
                spacing: 2
                Repeater {
                    model: [root.t.bg, root.t.panel, root.t.steel, root.t.ivory, root.t.ash, root.t.dust,
                            root.t.copper, root.t.teal, root.t.brass, root.t.sage, root.t.rust]
                    Rectangle {
                        required property color modelData
                        width: 14
                        height: 8
                        color: modelData
                        border.width: 1
                        border.color: Theme.steel
                    }
                }
            }
        }

        Rectangle {
            visible: root.active
            implicitWidth: tag.implicitWidth + 12
            implicitHeight: tag.implicitHeight + 4
            color: "transparent"
            border.width: 1
            border.color: Theme.steel

            Text {
                id: tag
                anchors.centerIn: parent
                text: "Active"
                color: Theme.teal
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
