import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services

// Shown for about a second after the session is released: the same 12 dim shutters as the lock screen,
// now over the real desktop. They open from the middle outward, so windows appear gradually.
// Input passes straight through it.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    visible: LockState.curtain
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "deadsignal-unlock"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property real slatH: height / 12
    readonly property int ms: Theme.reduceMotion ? 0 : 1

    Repeater {
        model: 12

        Rectangle {
            id: slat
            required property int index
            property real p: 0
            readonly property real full: win.slatH + 1

            width: win.width
            height: full * (1 - p)
            y: index % 2 === 0 ? index * win.slatH : (index + 1) * win.slatH + 1 - height
            color: Qt.rgba(0.043, 0.043, 0.043, 0.9)
            visible: height > 0.5

            SequentialAnimation {
                id: openAnim
                PauseAnimation { duration: Math.round(Math.abs(slat.index - 5.5) * 50) * win.ms }
                NumberAnimation { target: slat; property: "p"; to: 1; duration: 460 * win.ms; easing.type: Easing.InOutCubic }
            }

            Connections {
                target: LockState
                function onRetractChanged() {
                    if (LockState.retract) {
                        openAnim.restart();
                    } else {
                        openAnim.stop();
                        slat.p = 0;
                    }
                }
            }
        }
    }

    Row {
        x: win.width / 2 - width / 2
        y: win.height / 2 - 38
        spacing: 10
        opacity: LockState.curtain && !LockState.retract ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 * win.ms } }
        Rectangle { width: 6; height: 6; color: Theme.sage; anchors.verticalCenter: parent.verticalCenter }
        Mono {
            text: "WELCOME BACK, " + LockState.user.toUpperCase()
            font.pixelSize: 12
            font.letterSpacing: 1.7
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
