import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.components

// Workspaces I–VI as flat cells. Active: a steel cell + copper top bar that travels to the new
// workspace in 6 px steps (0.16 s for a neighbour, up to 0.4 s), the numeral brightens on arrival.
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

    readonly property var mon: Hyprland.monitorFor(root.screen)
    readonly property var shown: mon ? mon.activeWorkspace : Hyprland.focusedWorkspace
    readonly property int activeIndex: shown && shown.id >= 1 && shown.id <= Config.workspaceCount ? shown.id - 1 : -1

    // The highlight: `goal` is where it belongs, `pos` is where it is. It is drawn on a 6 px grid
    // while it travels, so it moves in steps like the rest of the pixel system.
    readonly property real stride: 31
    readonly property real goal: Math.max(0, activeIndex) * stride
    property real pos: 0
    property bool ready: false
    readonly property bool moving: Math.abs(pos - goal) > 0.5

    onGoalChanged: {
        slide.stop();
        if (!ready || Theme.reduceMotion) {
            pos = goal;
            ready = activeIndex >= 0;
            return;
        }
        const d = Math.max(1, Math.abs(goal - pos) / stride);
        slide.from = pos;
        slide.to = goal;
        slide.duration = Math.min(400, 160 + 50 * (d - 1));
        slide.start();
    }
    Component.onCompleted: { pos = goal; ready = activeIndex >= 0; }
    onActiveIndexChanged: if (!ready && activeIndex >= 0) { pos = goal; ready = true; }

    NumberAnimation {
        id: slide
        target: root
        property: "pos"
        easing.type: Easing.Linear
    }

    Item {
        visible: root.activeIndex >= 0
        x: root.moving ? Math.round(root.pos / 6) * 6 : root.goal
        width: 30
        height: parent.height

        Rectangle { anchors.fill: parent; color: Theme.steel }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 2
            color: Theme.copper
        }
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

                readonly property bool active: root.activeIndex === index
                // the numeral lights up when the highlight has arrived
                readonly property bool lit: active && !root.moving
                readonly property bool urgent: !active && !!ws && ws.urgent === true
                readonly property bool occupied: !active && !urgent && !!ws

                width: 30
                height: Theme.cellHeight

                Rectangle {
                    anchors.fill: parent
                    color: !cell.active && mouse.containsMouse ? Theme.steel : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animMs } }
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
                    font.weight: cell.lit ? Font.Medium : Font.Normal
                    color: cell.lit ? Theme.ivory
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
