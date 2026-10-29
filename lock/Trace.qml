import QtQuick
import qs.theme
import qs.services

// The oscilloscope under the user name: 102 columns of 2 px pixels on a 3 px pitch, newest at the right.
// The newest three columns are ivory; older ones fade to Cold Steel, in the colour of the phase
// (teal typing, brass verifying, rust denied, sage unlocked). A copper pixel marks the probe.
Item {
    id: root

    implicitWidth: 306
    implicitHeight: 52

    readonly property color tint: {
        const p = LockState.phase;
        return p === "checking" ? Theme.brass : p === "denied" ? Theme.rust
            : (p === "granted" || p === "opening") ? Theme.sage : Theme.teal;
    }

    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }

    Rectangle { x: -12; y: 24; width: 2; height: 2; color: Theme.copper }

    Canvas {
        id: canvas
        anchors.fill: parent

        Connections {
            target: LockTrace
            function onRevChanged() { canvas.requestPaint() }
        }
        Connections {
            target: LockState
            function onPhaseChanged() { canvas.requestPaint() }
        }
        Component.onCompleted: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const W = LockTrace.wave;
            const N = W.length;
            for (let i = 0; i < N; i++) {
                const age = N - 1 - i;
                const y = W[i];
                const yp = i > 0 ? W[i - 1] : y;
                const lo = Math.min(y, yp);
                const hi = Math.max(y, yp);
                const hot = lo !== 0 || hi !== 0;
                ctx.fillStyle = age < 3 ? Theme.ivory : root.mix(root.tint, Theme.steel, Math.min(1, age / (hot ? 85 : 19)));
                for (let r = lo; r <= hi; r++)
                    ctx.fillRect(i * 3, 25 + r * 3 - 1, 2, 2);
            }
        }
    }
}
