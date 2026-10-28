import Quickshell.Wayland
import QtQuick
import qs.theme

// One per screen, created by the WlSessionLock in shell.qml.
// The screen starts out black (it is locked from the first frame) and the lock is drawn in from the
// top behind one copper line: the same line that sweeps it away again on unlock.
WlSessionLockSurface {
    id: surface

    color: "#0B0B0B"

    property real p: Theme.reduceMotion ? 1 : 0
    readonly property real cut: p * height

    NumberAnimation on p {
        running: !Theme.reduceMotion
        from: 0
        to: 1
        duration: 900
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.65, 0, 0.35, 1, 1, 1]
    }

    Item {
        x: 0
        y: 0
        width: surface.width
        height: surface.cut
        clip: true

        LockScene {
            width: surface.width
            height: surface.height
        }
    }

    Rectangle {
        visible: surface.p > 0 && surface.p < 1
        y: surface.cut
        width: surface.width
        height: 1
        color: Theme.copper
        Rectangle { y: -2; width: 6; height: 5; color: Theme.copper }
    }
}
