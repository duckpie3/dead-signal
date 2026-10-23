import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

Popup {
    id: root

    panelWidth: 340

    PopupHeader {
        title: "Display"
        tint: Theme.brass
        status: Brightness.device
    }

    // ── Brightness ─────────────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 14
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 2
            Lb { text: "Brightness"; Layout.fillWidth: true }
            Mono { text: Brightness.percent; font.pixelSize: 28; font.weight: Font.Medium }
            Mono {
                text: "%"
                font.pixelSize: 13
                color: Theme.dust
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 3
            }
        }

        SegSlider {
            Layout.fillWidth: true
            from: 1
            to: 100
            step: 5
            value: Brightness.percent
            color: Theme.brass
            onMoved: v => Brightness.setPercent(v)
        }

        RowLayout {
            Layout.fillWidth: true
            Mono { text: "1"; font.pixelSize: 9; color: Theme.dust; Layout.fillWidth: true }
            Mono { text: "100"; font.pixelSize: 9; color: Theme.dust }
        }
    }

    Divider {}

    // ── Night light ────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 14
        Layout.bottomMargin: 12
        spacing: 12

        Glyph {
            path: Icons.moon
            size: 16
            color: NightLight.on ? Theme.brass : Theme.dust
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Txt { text: "Night light"; font.pixelSize: 13; Layout.fillWidth: true }
            Lb { text: NightLight.on ? "On · warming the screen" : "Off"; Layout.fillWidth: true }
        }
        Toggle {
            checked: NightLight.on
            onColor: Theme.brass
            onToggled: NightLight.setOn(!NightLight.on)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 16
        spacing: 4
        opacity: NightLight.on ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: Theme.reduceMotion ? 0 : 150 } }

        RowLayout {
            Layout.fillWidth: true
            Lb { text: "Temperature"; Layout.fillWidth: true }
            Mono { text: NightLight.temp; font.pixelSize: 14 }
            Mono { text: " K"; font.pixelSize: 10; color: Theme.dust }
        }

        SegSlider {
            Layout.fillWidth: true
            enabled: NightLight.on
            from: 2500
            to: 6500
            step: 100
            value: NightLight.temp
            color: Theme.brass
            onMoved: v => NightLight.setTemp(v)
        }

        RowLayout {
            Layout.fillWidth: true
            Lb { text: "Warm"; Layout.fillWidth: true }
            Lb { text: "Neutral" }
        }
    }
}
