import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// Active window: app tag + title (the title scrolls when it does not fit).
Item {
    id: root

    readonly property var tl: ToplevelManager.activeToplevel
    readonly property string app: tl && tl.appId ? tl.appId.split(".").pop().toUpperCase().slice(0, 10) : "IDLE"
    readonly property string title: tl && tl.title ? tl.title : "no active window"

    RowLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, implicitWidth)
        spacing: 10

        Rectangle {
            color: "transparent"
            border.width: 1
            border.color: Theme.steel
            implicitWidth: tag.implicitWidth + 10
            implicitHeight: tag.implicitHeight + 2

            Lb {
                id: tag
                anchors.centerIn: parent
                text: root.app
            }
        }

        Marquee {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            text: root.title
            color: root.tl ? Theme.ivory : Theme.dust
        }
    }
}
