import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

Popup {
    id: root

    panelWidth: 264

    readonly property var dev: UPower.displayDevice
    readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
    readonly property bool charging: !!dev && (dev.state === UPowerDeviceState.Charging
                                              || dev.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: !!dev && dev.state === UPowerDeviceState.FullyCharged
    readonly property color tint: charging ? Theme.sage
                                : pct <= 10 ? Theme.rust
                                : pct <= 25 ? Theme.copper
                                : Theme.brass

    function fmt(sec) {
        if (!sec || sec <= 0) return "--";
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        return h + "h" + String(m).padStart(2, "0") + "m";
    }

    function profileName(p) {
        if (p === PowerProfile.PowerSaver) return "SAVER";
        if (p === PowerProfile.Performance) return "PERFORMANCE";
        return "BALANCED";
    }

    function cycleProfile() {
        const order = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile) order.push(PowerProfile.Performance);
        const i = order.indexOf(PowerProfiles.profile);
        PowerProfiles.profile = order[(i + 1) % order.length];
    }

    PopupHeader {
        title: "Power"
        tint: root.tint
        status: root.charging ? "Charging" : (root.full ? "Full" : "On battery")
        statusColor: root.charging ? Theme.sage : Theme.dust
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 10
        spacing: 2

        Mono {
            text: Math.round(root.pct)
            font.pixelSize: 28
            font.weight: Font.Medium
            color: root.tint
        }
        Mono {
            text: "%"
            font.pixelSize: 13
            color: Theme.dust
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 3
        }
        Item { Layout.fillWidth: true }
        Mono {
            text: root.charging ? root.fmt(root.dev.timeToFull) : root.fmt(root.dev.timeToEmpty)
            color: Theme.ash
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 3
        }
    }

    // Five wide segments
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 12
        spacing: 3

        Repeater {
            model: 5
            Rectangle {
                required property int index
                Layout.fillWidth: true
                implicitHeight: 14
                color: index < Math.ceil(root.pct / 20) ? root.tint : Theme.steel
            }
        }
        Rectangle { implicitWidth: 3; implicitHeight: 6; color: Theme.steel }
    }

    Divider {}

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.bottomMargin: 4
        spacing: 7

        KvRow {
            key: "Draw"
            value: root.dev ? Math.abs(root.dev.changeRate).toFixed(1) + " W" : "--"
        }
        KvRow {
            key: "Health"
            value: root.dev && root.dev.healthSupported ? Math.round(root.dev.healthPercentage) + "%" : "--"
            visible: !!root.dev && root.dev.healthSupported
        }
    }

    MenuRow {
        Layout.topMargin: 2
        Layout.bottomMargin: 6
        label: "Profile"
        hint: root.profileName(PowerProfiles.profile)
        textColor: Theme.ash
        onTriggered: root.cycleProfile()
    }
}
