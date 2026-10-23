import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import qs.theme
import qs.components

// System tray. Left click activates (or opens the menu), right click opens the menu,
// middle click is the secondary action, scroll is forwarded to the app.
Cell {
    id: root

    required property var bar

    // Items the bar already has a cell for (Config.trayHidden) are left out.
    function hidden(item) {
        const s = ((item.id || "") + " " + (item.title || "")).toLowerCase();
        return Config.trayHidden.some(n => s.indexOf(n) >= 0);
    }

    visible: SystemTray.items.values.some(i => !root.hidden(i))
    hPad: 5
    spacing: 2

    Repeater {
        model: SystemTray.items

        Item {
            id: slot

            required property var modelData

            visible: !root.hidden(modelData)
            implicitWidth: visible ? 22 : 0
            implicitHeight: 22

            Rectangle {
                anchors.fill: parent
                color: mouse.containsMouse ? Theme.steel : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animMs } }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 14
                source: slot.modelData.icon
                opacity: mouse.containsMouse ? 1.0 : 0.8
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                function openMenu() {
                    // Below the icon on a top bar; from the icon's top edge on a bottom bar
                    // (the compositor flips the menu upward when it does not fit).
                    const p = slot.mapToItem(null, 0, Config.barAtBottom ? 0 : slot.height);
                    slot.modelData.display(root.bar, p.x, Config.barAtBottom ? p.y - 6 : p.y + 6);
                }

                onClicked: m => {
                    if (m.button === Qt.LeftButton) {
                        if (slot.modelData.onlyMenu && slot.modelData.hasMenu) openMenu();
                        else slot.modelData.activate();
                    } else if (m.button === Qt.RightButton) {
                        if (slot.modelData.hasMenu) openMenu();
                    } else {
                        slot.modelData.secondaryActivate();
                    }
                }

                onWheel: w => slot.modelData.scroll(w.angleDelta.y > 0 ? 1 : -1, false)
            }
        }
    }
}
