import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Volume / brightness / mic / layout card, bottom centre of the focused monitor.
// It never takes input, and disappears without animation.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    visible: Osd.visible
        && (Hyprland.focusedMonitor === null || Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)

    anchors.bottom: true
    margins.bottom: Config.osdMargin
    implicitWidth: 340
    implicitHeight: 68
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "deadsignal-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    // ── What to draw ──────────────────────────────────────
    readonly property string kind: Osd.kind
    readonly property bool isVolume: kind === "volume"
    readonly property bool isMic: kind === "mic"
    readonly property bool isBright: kind === "brightness"
    readonly property bool isLayout: kind === "layout"

    readonly property bool muted: isVolume ? Audio.muted : isMic ? Audio.micMuted : false
    readonly property real fraction: isVolume ? Audio.volume / Audio.maxVolume
                                   : isMic ? Audio.micVolume
                                   : Brightness.percent / 100
    readonly property int percent: Math.round(isVolume ? Audio.volume * 100
                                   : isMic ? Audio.micVolume * 100
                                   : Brightness.percent)
    readonly property bool over: isVolume && !muted && Audio.volume > 1.0

    readonly property string label: isVolume ? "Volume" : isMic ? "Microphone" : isBright ? "Brightness" : "Layout"
    readonly property string sub: isLayout ? HyprInfo.kbCode
                                : muted ? (isMic ? "Capture off" : "Muted")
                                : over ? "Boosted"
                                : isVolume ? Audio.label(Audio.sink)
                                : isMic ? "Live"
                                : "Backlight"

    readonly property string icon: isVolume ? (muted ? Icons.volumeOff : Icons.volume)
                                 : isMic ? (muted ? Icons.micOff : Icons.mic)
                                 : isBright ? Icons.sun
                                 : Icons.keyboard
    readonly property color accent: muted ? Theme.dust
                                  : over ? Theme.copper
                                  : isBright ? Theme.brass
                                  : isLayout ? Theme.ash
                                  : Theme.teal

    readonly property string valueText: {
        if (isLayout) return HyprInfo.kbCode;
        if (muted) return "MUTE";
        return String(Math.min(999, percent)).padStart(3, "0");
    }
    readonly property int leadingZeros: {
        if (isLayout || muted) return 0;
        return valueText.search(/[1-9]/) < 0 ? 2 : valueText.search(/[1-9]/);
    }

    // ── Card ──────────────────────────────────────────────
    Chamfer { anchors.fill: parent; cut: 8; fillColor: Theme.steel }
    Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 7; fillColor: Theme.panel }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        Item {
            implicitWidth: 40
            implicitHeight: 40

            Chamfer { anchors.fill: parent; cut: 4; fillColor: Theme.bg }
            Glyph {
                anchors.centerIn: parent
                path: win.icon
                size: 18
                color: win.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                Lb { text: win.label; color: Theme.ash }
                Item { Layout.fillWidth: true }
                Lb {
                    text: win.sub
                    color: win.over ? Theme.copper : Theme.dust
                    elide: Text.ElideRight
                    Layout.maximumWidth: 140
                }
            }

            // 30-segment meter; volume goes to 150 % with a tick at 100 %.
            RowLayout {
                visible: !win.isLayout
                Layout.fillWidth: true
                Layout.preferredHeight: 12
                spacing: 2

                Repeater {
                    model: 30

                    Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12
                        color: win.muted || index >= Math.ceil(win.fraction * 30)
                            ? Theme.steel
                            : (win.isVolume && index >= 20 ? Theme.copper
                               : win.isBright ? Theme.brass : Theme.teal)

                        Rectangle {
                            visible: win.isVolume && index === 20
                            x: -2
                            y: -5
                            width: 1
                            height: 4
                            color: Theme.ash
                        }
                    }
                }
            }

            // Layout chips: the configured layouts, the active one marked.
            RowLayout {
                visible: win.isLayout
                spacing: 1

                Repeater {
                    model: Config.keyboardLayouts

                    Item {
                        required property var modelData
                        readonly property bool active: modelData.code === HyprInfo.kbCode

                        implicitWidth: chip.implicitWidth + 20
                        implicitHeight: 22

                        Rectangle { anchors.fill: parent; color: parent.active ? Theme.steel : "transparent" }
                        Rectangle {
                            visible: parent.active
                            width: parent.width
                            height: 2
                            color: Theme.copper
                        }
                        Mono {
                            id: chip
                            anchors.centerIn: parent
                            text: parent.modelData.code
                            color: parent.active ? Theme.ivory : Theme.dust
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }

        DotText {
            text: win.valueText
            pixel: 3
            gap: 1
            dimUntil: win.leadingZeros
            lit: win.muted ? Theme.dust : win.over ? Theme.copper : Theme.ivory
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
