import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.modules
import qs.popups
import qs.services

// One bar per screen. Transparent window; the visible bar is a chamfered shape inset by Theme.margin.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: !Config.barAtBottom
        bottom: Config.barAtBottom
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight + Theme.margin * 2
    color: "transparent"

    WlrLayershell.namespace: "deadsignal"

    // Only the bar itself takes pointer input; the margin around it is click-through.
    mask: Region { item: frame }

    // Which popup is open: "", "telemetry", "notifs", "audio", "net", "battery", "clock", "session"
    property string popup: ""
    function toggle(name) { popup = (popup === name) ? "" : name }
    function close(name) { if (popup === name) popup = "" }

    Item {
        id: frame
        x: Theme.margin
        y: Theme.margin
        width: root.width - Theme.margin * 2
        height: Theme.barHeight

        // 1 px Cold Steel edge, then the Void body inside it.
        Chamfer {
            anchors.fill: parent
            cut: Theme.barCut
            fillColor: Theme.steel
        }
        Chamfer {
            anchors.fill: parent
            anchors.margins: 1
            cut: Theme.barCut - 1
            fillColor: Theme.bg
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 4
            spacing: 16

            // ── Left: navigation ──────────────────────────
            RowLayout {
                spacing: Theme.gap

                Cell {
                    hPad: 6
                    interactive: true
                    onClicked: m => LauncherState.toggle()
                    Emblem {}
                }

                Workspaces { screen: root.screen }

                Cell {
                    flat: true
                    spacing: 6
                    Lb { text: "LYT" }
                    Mono {
                        text: HyprInfo.tiling.toUpperCase()
                        color: Theme.ash
                    }
                }
            }

            // ── Center: context ───────────────────────────
            WindowTitle {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // ── Right: telemetry ──────────────────────────
            RowLayout {
                spacing: Theme.gap

                Telemetry {
                    id: telemetryCell
                    onToggle: root.toggle("telemetry")
                }

                AudioCell {
                    id: audioCell
                    onToggle: root.toggle("audio")
                }

                BrightnessCell {}

                NetCell {
                    id: netCell
                    onToggle: root.toggle("net")
                }

                BatteryCell {
                    id: batteryCell
                    onToggle: root.toggle("battery")
                }

                KeyboardCell {}

                TrayCell { bar: root }

                NotifCell {
                    id: notifCell
                    onToggle: root.toggle("notifs")
                }

                ClockCell {
                    id: clockCell
                    onToggle: root.toggle("clock")
                }

                SessionCell {
                    id: sessionCell
                    onToggle: root.toggle("session")
                }
            }
        }
    }

    // ── Popups ────────────────────────────────────────────
    TelemetryPopup {
        bar: root
        anchorItem: telemetryCell
        open: root.popup === "telemetry"
        onDismissed: root.close("telemetry")
    }

    AudioPopup {
        bar: root
        anchorItem: audioCell
        open: root.popup === "audio"
        onDismissed: root.close("audio")
    }

    NetPopup {
        bar: root
        anchorItem: netCell
        open: root.popup === "net"
        onDismissed: root.close("net")
    }

    BatteryPopup {
        bar: root
        anchorItem: batteryCell
        open: root.popup === "battery"
        onDismissed: root.close("battery")
    }

    NotifPopup {
        bar: root
        anchorItem: notifCell
        open: root.popup === "notifs"
        onDismissed: root.close("notifs")
    }

    CalendarPopup {
        bar: root
        anchorItem: clockCell
        open: root.popup === "clock"
        onDismissed: root.close("clock")
    }

    SessionPopup {
        bar: root
        anchorItem: sessionCell
        open: root.popup === "session"
        onDismissed: root.close("session")
    }
}
