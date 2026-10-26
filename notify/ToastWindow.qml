import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

// Toast stack, top right of the focused monitor, just clear of the bar when it is at the top.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    visible: (Notifs.toasts.length > 0 || Capture.toast !== null)
        && (Hyprland.focusedMonitor === null || Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)

    anchors {
        top: true
        right: true
    }
    margins {
        top: Config.barAtBottom ? Theme.margin : Theme.barHeight + Theme.margin * 2 + 8
        right: Theme.margin
    }

    implicitWidth: 360
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "deadsignal-toasts"
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: 8

        // Screenshot and colour results sit on top of the notifications.
        CaptureToast {}

        Repeater {
            model: Notifs.toasts

            ToastCard {
                required property var modelData
                rec: modelData
            }
        }
    }
}
