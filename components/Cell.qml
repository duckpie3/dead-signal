import QtQuick
import QtQuick.Layouts
import qs.theme

// A bar cell: chamfered Dead Panel surface with a centered row of content.
Item {
    id: root

    property color bg: Theme.panel
    property color hoverBg: Theme.steel
    property bool interactive: false
    property bool flat: false          // no surface (used for plain labels)
    property int hPad: Theme.pad
    property alias spacing: row.spacing
    property alias hovered: mouse.containsMouse
    default property alias content: row.data

    signal clicked(var mouse)
    signal wheeled(var wheel)

    implicitHeight: Theme.cellHeight
    implicitWidth: row.implicitWidth + hPad * 2

    Chamfer {
        anchors.fill: parent
        visible: !root.flat
        cut: Theme.cut
        fillColor: root.interactive && mouse.containsMouse ? root.hoverBg : root.bg
    }

    // Sits below the content so child MouseAreas (tray icons) win.
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheeled(w)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
    }
}
