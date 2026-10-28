import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.services

// Mapped while the password is being accepted, hidden under the lock. When the session is released it is
// already showing the same picture as the lock surface (same scene, same state, opaque), so nothing
// jumps. A beat later one copper line sweeps down and clears it: the live desktop is revealed behind
// the line. Input passes straight through.
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

    property real p: 0
    readonly property real cut: p * height

    NumberAnimation {
        id: sweep
        target: win
        property: "p"
        from: 0
        to: 1
        duration: Theme.reduceMotion ? 0 : 900
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.65, 0, 0.35, 1, 1, 1]
    }

    Connections {
        target: LockState
        function onRetractChanged() {
            if (LockState.retract) sweep.restart();
            else { sweep.stop(); win.p = 0; }
        }
    }

    Item {
        x: 0
        y: win.cut
        width: win.width
        height: win.height - win.cut
        clip: true

        LockScene {
            y: -win.cut
            width: win.width
            height: win.height
        }
    }

    Rectangle {
        visible: win.p > 0 && win.p < 1
        y: win.cut
        width: win.width
        height: 1
        color: Theme.copper
        Rectangle { y: -2; width: 6; height: 5; color: Theme.copper }
    }
}
