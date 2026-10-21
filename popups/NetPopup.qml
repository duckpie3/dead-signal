import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

Popup {
    id: root

    panelWidth: 264

    readonly property bool ok: Net.link === "ok"

    function history() {
        const h = Net.pingHistory.slice(-40).map(v => Math.min(v / 150, 1));
        return new Array(Math.max(0, 40 - h.length)).fill(0).concat(h);
    }

    PopupHeader {
        title: "Network"
        tint: Theme.teal
        status: Net.link === "ok" ? "Link ok" : (Net.link === "offline" ? "Offline" : "No link")
        statusColor: Net.link === "ok" ? Theme.teal : (Net.link === "offline" ? Theme.dust : Theme.rust)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 12
        spacing: 12

        SignalBars {
            large: true
            bars: Net.bars
            failed: Net.link === "nolink"
            Layout.alignment: Qt.AlignBottom
        }

        ColumnLayout {
            spacing: 2
            Txt {
                text: root.ok ? Net.name : (Net.link === "offline" ? "Not connected" : Net.name)
                font.pixelSize: 14
                color: root.ok ? Theme.ivory : Theme.ash
            }
            Lb {
                visible: text !== ""
                text: [Net.security, Net.band].filter(s => s !== "" && s !== "--").join(" · ")
            }
        }
    }

    Divider {}

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        spacing: 7

        KvRow { key: "Type";   value: Net.type === "wifi" ? "WI-FI" : Net.type.toUpperCase() }
        KvRow { key: "Iface";  value: Net.iface }
        KvRow { key: "Addr";   value: Net.ip }
        KvRow { key: "Signal"; value: Net.type === "ethernet" ? "WIRED" : Net.strength + "%"; visible: root.ok }
        KvRow {
            key: "Ping"
            value: Net.pingMs >= 0 ? Math.round(Net.pingMs) + " MS" : "--"
            valueColor: Net.pingMs > 100 ? Theme.copper : Theme.ivory
            visible: root.ok
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 12
        spacing: 6
        visible: root.ok

        RowLayout {
            Layout.fillWidth: true
            Lb { text: "Latency 60s"; Layout.fillWidth: true }
            Lb {
                text: "Peak " + Math.round(Net.peakMs) + " ms"
                color: Net.peakMs > 100 ? Theme.copper : Theme.dust
            }
        }

        Spark {
            values: root.history()
            barW: 4
            minH: 2
            maxH: 28
            colorFn: v => v > 0.66 ? Theme.copper : Theme.teal
        }
    }

    Divider {}

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        spacing: 0

        MenuRow {
            label: "Switch network…"
            textColor: Theme.ash
            onTriggered: {
                root.dismissed();
                Quickshell.execDetached(Config.terminal.concat(["nmtui"]));
            }
        }
        MenuRow {
            label: "Disconnect"
            textColor: Theme.ash
            visible: Net.connected
            onTriggered: {
                root.dismissed();
                Net.disconnect();
            }
        }
    }
}
