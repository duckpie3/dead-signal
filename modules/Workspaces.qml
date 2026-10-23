import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.theme
import qs.components

// Workspaces I–VI as flat cells. Active: steel cell + copper top bar.
// Occupied: teal pixel. Urgent: copper numeral + pixel. Empty: numeral only.
Item {
    id: root

    required property var screen

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.cellHeight

    Chamfer {
        anchors.fill: parent
        cut: Theme.cut
        fillColor: Theme.panel
    }

    Row {
        id: row
        spacing: 1

        Repeater {
            model: Config.workspaceCount

            Item {
                id: cell

                required property int index
                readonly property int n: index + 1

                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === cell.n)
                readonly property var mon: Hyprland.monitorFor(root.screen)
                readonly property var shown: mon ? mon.activeWorkspace : Hyprland.focusedWorkspace

                readonly property bool active: shown ? shown.id === n : false
                readonly property bool urgent: !active && !!ws && ws.urgent === true
                readonly property bool occupied: !active && !urgent && !!ws

                width: 30
                height: Theme.cellHeight

                Rectangle {
                    anchors.fill: parent
                    color: cell.active ? Theme.steel : (mouse.containsMouse ? Theme.steel : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.animMs } }
                }

                // active bar
                Rectangle {
                    visible: cell.active
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 2
                    color: Theme.copper
                }

                // occupied / urgent pixel
                Rectangle {
                    visible: cell.urgent || cell.occupied
                    x: parent.width - 5
                    y: 4
                    width: 2
                    height: 2
                    color: cell.urgent ? Theme.copper : Theme.teal
                }

                Mono {
                    anchors.centerIn: parent
                    text: Config.roman[cell.index]
                    font.weight: cell.active ? Font.Medium : Font.Normal
                    color: cell.active ? Theme.ivory
                         : cell.urgent ? Theme.copper
                         : mouse.containsMouse ? Theme.ivory
                         : Theme.dust
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(
                        Hyprland.usingLua
                            ? "hl.dsp.focus({ workspace = " + cell.n + " })"
                            : "workspace " + cell.n
                    )
                }
            }
        }
    }
}
