import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// CPU and memory history plus the usual numbers. Details are only sampled while it is open.
Popup {
    id: root

    panelWidth: 340

    readonly property real cpuPeak: Math.max.apply(null, Stats.cpuHistory)
    readonly property var swapUsed: Stats.swapTotal - Stats.swapFree

    // Same ramp as the bar: dust → ash → ivory, copper only when it is nearly maxed out.
    function load(v) {
        return v >= 0.8 ? Theme.copper : v >= 0.45 ? Theme.ivory : v >= 0.2 ? Theme.ash : Theme.dust;
    }

    function pct(v) { return Math.round(v * 100); }
    function gib(kib) { return (kib / 1048576).toFixed(1); }
    function pad(n) { return String(n).padStart(2, "0"); }

    function uptime(s) {
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        return d > 0 ? d + "d " + pad(h) + "h" : h + "h " + pad(m) + "m";
    }

    function rss(kib) {
        return kib >= 1048576 ? (kib / 1048576).toFixed(1) + "G" : Math.round(kib / 1024) + "M";
    }

    function openMonitor() {
        root.dismissed();
        Quickshell.execDetached(Config.terminal.concat(Config.monitorCommand));
    }

    Binding {
        target: Stats
        property: "detail"
        value: root.open
    }

    PopupHeader {
        title: "System"
        tint: Theme.ash
        status: "Up " + root.uptime(Stats.uptime)
    }

    // ── CPU ───────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 12
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Lb {
                text: "CPU"
                Layout.preferredWidth: 28
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
            RowLayout {
                spacing: 2
                Mono {
                    text: root.pct(Stats.cpu)
                    font.pixelSize: 28
                    font.weight: Font.Medium
                }
                Mono {
                    text: "%"
                    font.pixelSize: 13
                    color: Theme.dust
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 3
                }
            }
            Item { Layout.fillWidth: true }
            Mono {
                visible: Stats.freqMhz > 0
                text: (Stats.freqMhz / 1000).toFixed(1) + " GHz"
                color: Theme.ash
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
            Mono {
                visible: Stats.tempC >= 0
                text: Stats.tempC + "°C"
                color: Stats.tempC >= 85 ? Theme.copper : Theme.ash
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
        }

        Lb {
            visible: Stats.cpuModel !== ""
            Layout.leftMargin: 38
            Layout.topMargin: 7
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: Stats.cpuModel + (Stats.threadCount > 0
                ? " · " + (Stats.coreCount > 0 && Stats.coreCount !== Stats.threadCount ? Stats.coreCount + "C / " : "") + Stats.threadCount + "T"
                : "")
        }

        Spark {
            Layout.topMargin: 10
            values: Stats.cpuHistory
            barW: 3
            minH: 2
            maxH: 36
            spacing: 2
            colorFn: root.load
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 5
            Lb { text: "-60s" }
            Item { Layout.fillWidth: true }
            Lb { text: "Peak" }
            Mono {
                text: root.pct(root.cpuPeak) + "%"
                font.pixelSize: 9
            }
            Item { Layout.fillWidth: true }
            Lb { text: "Now" }
        }

        Lb {
            text: "Cores"
            Layout.topMargin: 12
            Layout.bottomMargin: 6
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(1, Math.min(Stats.cores.length, 16))
            columnSpacing: 6
            rowSpacing: 8

            Repeater {
                model: Stats.cores

                ColumnLayout {
                    id: core

                    required property real modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 4

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            model: 6

                            Rectangle {
                                required property int index

                                Layout.fillWidth: true
                                implicitHeight: 4
                                // index 0 is the top segment
                                color: (5 - index) < Math.max(1, Math.round(core.modelData * 6))
                                    ? root.load(core.modelData)
                                    : Theme.steel
                            }
                        }
                    }

                    Mono {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.pad(core.index)
                        font.pixelSize: 9
                        color: Theme.dust
                    }
                }
            }
        }
    }

    Divider {}

    // ── Memory ────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 12
        Layout.bottomMargin: 4
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Lb {
                text: "MEM"
                Layout.preferredWidth: 28
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
            RowLayout {
                spacing: 2
                Mono {
                    text: root.pct(Stats.mem)
                    font.pixelSize: 28
                    font.weight: Font.Medium
                    color: Stats.mem > 0.85 ? Theme.copper : Theme.ivory
                }
                Mono {
                    text: "%"
                    font.pixelSize: 13
                    color: Theme.dust
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 3
                }
            }
            Item { Layout.fillWidth: true }
            Mono {
                text: root.gib(Stats.memTotal - Stats.memAvailable) + " / " + root.gib(Stats.memTotal) + " GB"
                color: Theme.ash
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
        }

        Spark {
            Layout.topMargin: 10
            values: Stats.memHistory
            barW: 3
            minH: 2
            maxH: 36
            spacing: 2
            colorFn: v => v >= 0.85 ? Theme.copper : Theme.ash
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 5
            Lb { text: "-60s" }
            Item { Layout.fillWidth: true }
            Lb { text: "Now" }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 10
        spacing: 7

        KvRow { key: "Cached"; value: root.gib(Stats.memCached) + " GB" }
        KvRow {
            key: "Swap"
            value: Stats.swapTotal > 0 ? root.gib(root.swapUsed) + " / " + root.gib(Stats.swapTotal) + " GB" : "NONE"
            valueColor: Stats.swapTotal > 0 ? Theme.ivory : Theme.dust
        }
    }

    Divider {}

    // ── System ────────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        spacing: 7

        KvRow {
            key: "Load"
            value: Stats.loadAvg.map(v => v.toFixed(2)).join(" · ")
        }
        KvRow {
            visible: Stats.diskTotal > 0
            key: "Disk /"
            value: Math.round(Stats.diskUsed / 1e9) + " / " + Math.round(Stats.diskTotal / 1e9) + " GB"
            valueColor: Stats.diskUsed / Stats.diskTotal > 0.9 ? Theme.copper : Theme.ivory
        }
        KvRow {
            visible: Stats.procs > 0
            key: "Procs"
            value: String(Stats.procs)
        }
    }

    Divider {}

    // ── Processes ─────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 10
        Layout.bottomMargin: 4

        Lb { text: "Top by CPU"; Layout.fillWidth: true }
        Lb { text: "CPU · MEM" }
    }

    Lb {
        visible: Stats.topProcs.length === 0
        text: "Sampling…"
        Layout.leftMargin: 16
        Layout.topMargin: 4
        Layout.bottomMargin: 8
    }

    Repeater {
        model: Stats.topProcs

        RowLayout {
            required property var modelData

            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.preferredHeight: 28
            spacing: 10

            Rectangle { implicitWidth: 4; implicitHeight: 4; color: Theme.ash }
            Txt {
                Layout.fillWidth: true
                text: modelData.name
                elide: Text.ElideRight
            }
            Mono {
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
                text: modelData.cpu.toFixed(1)
                color: modelData.cpu >= 90 ? Theme.copper : Theme.ivory
            }
            Mono {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: root.rss(modelData.rss)
                color: Theme.ash
            }
        }
    }

    MenuRow {
        Layout.topMargin: 4
        Layout.bottomMargin: 8
        glyph: Icons.chart
        label: "Open system monitor"
        hint: Config.monitorCommand[0]
        textColor: Theme.ash
        onTriggered: root.openMonitor()
    }
}
