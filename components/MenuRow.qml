import QtQuick
import QtQuick.Layouts
import qs.theme

// Popup row. Hover fills with Cold Steel; keyboard focus draws an ivory ring,
// so the two states stay distinguishable.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string glyph: ""              // SVG path from Icons
    property color tint: Theme.ash
    property color textColor: Theme.ivory
    property bool marker: false            // square radio marker instead of an icon
    property bool selected: false

    signal triggered()

    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    implicitHeight: 30
    activeFocusOnTab: true

    Keys.onReturnPressed: root.triggered()
    Keys.onEnterPressed: root.triggered()
    Keys.onSpacePressed: root.triggered()
    Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
    Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: mouse.containsMouse ? Theme.steel : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animMs } }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.ivory
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Glyph {
            visible: root.glyph !== ""
            path: root.glyph
            color: root.tint
        }

        Rectangle {
            visible: root.marker
            implicitWidth: 6
            implicitHeight: 6
            color: root.selected ? Theme.teal : "transparent"
            border.width: root.selected ? 0 : 1
            border.color: Theme.dust
        }

        Txt {
            Layout.fillWidth: true
            text: root.label
            color: root.textColor
            elide: Text.ElideRight
        }

        Lb {
            visible: root.hint !== ""
            text: root.hint
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
