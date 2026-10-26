import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

Popup {
    id: root

    panelWidth: 340

    readonly property var phases: [
        { id: "focus", label: "Focus" },
        { id: "short", label: "Short" },
        { id: "long", label: "Long" }
    ]
    readonly property var steppers: [
        { key: "focus", label: "Focus", unit: "min", min: 5, max: 90, step: 5 },
        { key: "short", label: "Short break", unit: "min", min: 1, max: 30, step: 1 },
        { key: "long", label: "Long break", unit: "min", min: 5, max: 60, step: 5 },
        { key: "rounds", label: "Rounds before long break", unit: "", min: 2, max: 8, step: 1 }
    ]

    PopupHeader {
        title: "Focus timer"
        tint: Pomodoro.tint
        status: "Round " + Pomodoro.round + " / " + Pomodoro.rounds
        statusColor: Theme.ash
    }

    // ── Phase ─────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        spacing: 1

        Repeater {
            model: root.phases

            Item {
                id: tab
                required property var modelData
                readonly property bool on: Pomodoro.phase === modelData.id

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 28

                Rectangle {
                    anchors.fill: parent
                    color: tab.on ? Theme.steel : (tabMouse.containsMouse ? Theme.panel : Theme.bg)
                }
                Rectangle {
                    visible: tab.on
                    width: parent.width
                    height: 2
                    color: Theme.copper
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 7
                    Lb { text: tab.modelData.label; color: tab.on || tabMouse.containsMouse ? Theme.ivory : Theme.dust }
                    Lb { text: Pomodoro.cfg[tab.modelData.id]; color: Theme.dust }
                }
                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Pomodoro.pick(tab.modelData.id)
                }
            }
        }
    }

    // ── Time ──────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        spacing: 12

        DotClock {
            text: Pomodoro.fmt(Pomodoro.secsLeft)
            pixel: 6
            gap: 2
            lit: Pomodoro.ink
        }

        Item { Layout.fillWidth: true }

        GridLayout {
            columns: 2
            columnSpacing: 14
            rowSpacing: 6

            Lb { text: "State" }
            Mono {
                text: Pomodoro.stateText
                color: Pomodoro.ink
                Layout.alignment: Qt.AlignRight
            }
            Lb { text: "Ends" }
            Mono { text: Pomodoro.endsAt; Layout.alignment: Qt.AlignRight }
            Lb { text: "Today" }
            Mono { text: String(Pomodoro.doneToday).padStart(2, "0"); Layout.alignment: Qt.AlignRight }
        }
    }

    // 44-segment progress.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        spacing: 2

        Repeater {
            model: 44
            Rectangle {
                required property int index
                Layout.fillWidth: true
                implicitHeight: 10
                color: index < Math.ceil(Pomodoro.progress * 44) ? Pomodoro.tint : Theme.steel
            }
        }
    }

    // ── Rounds ────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        spacing: 12

        Lb { text: "Rounds" }

        Row {
            spacing: 4
            Repeater {
                model: Pomodoro.rounds
                Rectangle {
                    required property int index
                    readonly property int n: index + 1
                    readonly property bool done: n < Pomodoro.round
                    readonly property bool cur: n === Pomodoro.round
                    width: 8
                    height: 8
                    color: done ? Theme.teal : (cur && Pomodoro.phase === "focus" && Pomodoro.running ? Theme.brass : "transparent")
                    border.width: 1
                    border.color: done ? Theme.teal : cur ? Theme.brass : Theme.steel
                }
            }
        }

        Item { Layout.fillWidth: true }

        Lb { text: "Next: " + Pomodoro.phaseName(Pomodoro.nextPhase) + " " + Pomodoro.fmt(Pomodoro.dur(Pomodoro.nextPhase)) }
    }

    // ── Controls ──────────────────────────────────────────
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 16
        spacing: 12

        ChamferButton { path: Icons.reboot; color: Theme.ash; onClicked: Pomodoro.reset() }
        ChamferButton {
            big: true
            path: Pomodoro.running ? Icons.pause : Icons.play
            bar: Pomodoro.running ? Pomodoro.tint : Theme.copper
            onClicked: Pomodoro.toggle()
        }
        ChamferButton { path: Icons.next; onClicked: Pomodoro.skip() }
    }

    Divider {}

    Lb {
        Layout.leftMargin: 16
        Layout.topMargin: 10
        Layout.bottomMargin: 4
        text: "Durations"
    }

    Repeater {
        model: root.steppers

        RowLayout {
            id: srow
            required property var modelData
            readonly property int value: Pomodoro.cfg[modelData.key]

            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.preferredHeight: 34
            spacing: 10

            Txt { text: srow.modelData.label; font.pixelSize: 13; Layout.fillWidth: true }
            StepButton {
                path: Icons.minus
                enabled: srow.value > srow.modelData.min
                onClicked: Pomodoro.setDur(srow.modelData.key, Math.max(srow.modelData.min, srow.value - srow.modelData.step))
            }
            Row {
                Layout.preferredWidth: 56
                Layout.alignment: Qt.AlignVCenter
                spacing: 4
                leftPadding: Math.max(0, (56 - (valueText.implicitWidth + unitText.implicitWidth + 4)) / 2)
                Mono { id: valueText; text: srow.value; font.pixelSize: 12 }
                Mono { id: unitText; text: srow.modelData.unit; font.pixelSize: 10; color: Theme.dust }
            }
            StepButton {
                path: Icons.plus
                enabled: srow.value < srow.modelData.max
                onClicked: Pomodoro.setDur(srow.modelData.key, Math.min(srow.modelData.max, srow.value + srow.modelData.step))
            }
        }
    }

    Divider { Layout.topMargin: 6 }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 12
        Layout.bottomMargin: 14
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Txt { text: "Start next phase automatically"; font.pixelSize: 13 }
            Lb { text: Pomodoro.auto ? "Phases flow on without asking" : "Waits for you after each phase" }
        }
        Toggle { checked: Pomodoro.auto; onToggled: Pomodoro.setAuto(!Pomodoro.auto) }
    }
}
