import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

Popup {
    id: root

    panelWidth: 320

    signal openFocus()

    property int monthOffset: 0
    onOpenChanged: {
        if (open) {
            monthOffset = 0;
            Weather.refresh();
        }
    }

    function rounded(v) { return Math.round(v) + "°"; }
    function hourLabel(h, i) {
        if (i === 0) return "NOW";
        return i % 3 === 0 ? String(h.hour).padStart(2, "0") : "";
    }

    readonly property var base: new Date(Time.date.getFullYear(), Time.date.getMonth() + monthOffset, 1)

    // Monday-first grid. d = 0 for padding cells.
    readonly property var cells: {
        const y = base.getFullYear();
        const m = base.getMonth();
        const off = (new Date(y, m, 1).getDay() + 6) % 7;
        const days = new Date(y, m + 1, 0).getDate();
        const n = Math.ceil((off + days) / 7) * 7;
        const now = Time.date;
        const out = [];
        for (let i = 0; i < n; i++) {
            const d = i - off + 1;
            out.push({
                d: (d >= 1 && d <= days) ? d : 0,
                today: d === now.getDate() && m === now.getMonth() && y === now.getFullYear(),
                weekend: i % 7 >= 5
            });
        }
        return out;
    }

    PopupHeader {
        title: "Date"
        tint: Theme.brass
        status: "Wk " + Time.isoWeek(Time.date)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 12
        spacing: 10

        DotClock {
            text: Time.hhmm
            pixel: 4
            gap: 2
            Layout.alignment: Qt.AlignBottom
        }

        Item { Layout.fillWidth: true }

        Lb {
            text: Qt.formatDateTime(Time.date, "dddd")
            Layout.alignment: Qt.AlignBottom
        }
    }

    Divider {}

    // ── Weather ───────────────────────────────────────────
    ColumnLayout {
        visible: Weather.enabled
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 12
        Layout.bottomMargin: 12
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            Lb { text: "Weather" }
            Item { Layout.fillWidth: true }
            Lb { text: Config.weatherPlace }
        }

        Lb {
            visible: !Weather.ok
            text: Weather.failed ? "Unavailable · check the connection" : "Loading…"
            color: Weather.failed ? Theme.rust : Theme.dust
        }

        ColumnLayout {
            visible: Weather.ok
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                WeatherIcon {
                    kind: Weather.kindOf(Weather.code)
                    night: !Weather.isDay
                    pixel: 6
                    gap: 2
                    boxW: 84
                    boxH: 54
                }

                ColumnLayout {
                    spacing: 5

                    RowLayout {
                        spacing: 2
                        Mono { text: Math.round(Weather.temp); font.pixelSize: 28; font.weight: Font.Medium }
                        Mono {
                            text: Weather.unitLabel
                            font.pixelSize: 13
                            color: Theme.dust
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 3
                        }
                    }
                    Txt { text: Weather.describe(Weather.code); color: Theme.ash }
                }

                Item { Layout.fillWidth: true }

                GridLayout {
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 4

                    Lb { text: "Feels" }
                    Mono { text: root.rounded(Weather.feels); font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
                    Lb { text: "Hum" }
                    Mono { text: Math.round(Weather.humidity) + "%"; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
                    Lb { text: "Wind" }
                    Mono { text: Math.round(Weather.wind) + " " + Weather.windLabel; font.pixelSize: 11; Layout.alignment: Qt.AlignRight }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14
                Layout.bottomMargin: 6
                spacing: 5

                Lb { text: "Next 12 h" }
                Item { Layout.fillWidth: true }
                Rectangle { implicitWidth: 4; implicitHeight: 4; color: Theme.teal }
                Lb { text: "Rain 40%+" }
            }

            // One column per hour: six segments for the temperature, a dot for likely rain.
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: Weather.hours

                    ColumnLayout {
                        id: hour
                        required property var modelData
                        required property int index
                        readonly property real span: Math.max(1, Weather.hoursMax - Weather.hoursMin)
                        readonly property int lit: 1 + Math.round((modelData.temp - Weather.hoursMin) / span * 5)

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 5

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Repeater {
                                model: 6

                                Rectangle {
                                    required property int index
                                    Layout.fillWidth: true
                                    implicitHeight: 4
                                    color: (5 - index) < hour.lit
                                        ? (hour.index === 0 ? Theme.ivory : Theme.ash)
                                        : Theme.steel
                                }
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 4
                            implicitHeight: 4
                            color: hour.modelData.rain >= 40 ? Theme.teal : Theme.steel
                        }

                        Mono {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: 9
                            text: root.hourLabel(hour.modelData, hour.index)
                            color: Theme.dust
                            font.pixelSize: 9
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6

                Mono { text: root.rounded(Weather.hoursMin); color: Theme.ash; font.pixelSize: 10 }
                Item { Layout.fillWidth: true }
                Mono { text: root.rounded(Weather.hoursMax); color: Theme.ash; font.pixelSize: 10 }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 6

                Repeater {
                    model: Weather.days

                    Item {
                        id: day
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: dayColumn.implicitHeight + 15

                        Chamfer { anchors.fill: parent; cut: 4; fillColor: Theme.bg }

                        ColumnLayout {
                            id: dayColumn
                            x: 8
                            y: 8
                            spacing: 6

                            Lb { text: day.modelData.name }
                            WeatherIcon {
                                kind: Weather.kindOf(day.modelData.code)
                                pixel: 3
                                boxW: 36
                                boxH: 28
                            }
                            RowLayout {
                                spacing: 0
                                Mono { text: day.modelData.hi + "°"; font.pixelSize: 11 }
                                Mono { text: " / " + day.modelData.lo + "°"; font.pixelSize: 11; color: Theme.dust }
                            }
                        }
                    }
                }
            }
        }
    }

    Divider {}

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.topMargin: 8
        Layout.bottomMargin: 6

        IconButton { path: Icons.chevLeft; onClicked: root.monthOffset -= 1 }
        Item { Layout.fillWidth: true }
        Mono { text: Qt.formatDate(root.base, "yyyy.MM") }
        Item { Layout.fillWidth: true }
        IconButton { path: Icons.chevRight; onClicked: root.monthOffset += 1 }
    }

    GridLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 12
        columns: 7
        columnSpacing: 2
        rowSpacing: 2

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Lb {
                required property string modelData
                Layout.preferredWidth: 30
                Layout.preferredHeight: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
            }
        }

        Repeater {
            model: root.cells

            Item {
                required property var modelData
                Layout.preferredWidth: 30
                Layout.preferredHeight: 26

                Rectangle {
                    anchors.fill: parent
                    visible: parent.modelData.today
                    color: Theme.steel
                }
                Rectangle {
                    visible: parent.modelData.today
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 2
                    color: Theme.copper
                }
                Mono {
                    anchors.centerIn: parent
                    visible: parent.modelData.d > 0
                    text: String(parent.modelData.d).padStart(2, "0")
                    color: parent.modelData.today ? Theme.brass
                         : parent.modelData.weekend ? Theme.ash
                         : Theme.ivory
                }
            }
        }
    }

    Divider {}

    // ── Focus timer ───────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        Layout.topMargin: 10
        Layout.bottomMargin: 12
        spacing: 10

        Glyph { path: Icons.tomato; size: 16; color: Pomodoro.active ? Pomodoro.ink : Theme.ash }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Txt { text: "Focus timer"; font.pixelSize: 13 }
            Lb {
                text: Pomodoro.active
                    ? Pomodoro.phaseName(Pomodoro.phase) + " · " + (Pomodoro.ended ? "ready" : Pomodoro.fmt(Pomodoro.secsLeft))
                    : Pomodoro.cfg.focus + " min · round " + Pomodoro.round + " of " + Pomodoro.rounds
            }
        }

        ActionButton {
            label: Pomodoro.active ? "Open" : "Start"
            primary: true
            onClicked: {
                if (Pomodoro.active) root.openFocus();
                else { Pomodoro.start(); root.dismissed(); }
            }
        }
    }
}
