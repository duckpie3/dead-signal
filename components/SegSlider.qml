import QtQuick
import qs.theme

// Segmented slider: click or drag to set, scroll or arrow keys to nudge.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property color color: Theme.teal
    property real warnFrom: -1             // values above this are drawn in warnColor
    property color warnColor: Theme.copper
    property real step: (to - from) / 20

    signal moved(real v)

    implicitHeight: 18
    activeFocusOnTab: true

    readonly property int pitch: 6
    readonly property int count: Math.max(1, Math.floor((width + 2) / pitch))

    function clamp(v) { return Math.max(from, Math.min(to, v)) }

    Keys.onLeftPressed:  root.moved(clamp(value - step))
    Keys.onRightPressed: root.moved(clamp(value + step))

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            readonly property real pos: root.from + (index + 0.5) / root.count * (root.to - root.from)
            x: index * root.pitch
            anchors.verticalCenter: parent.verticalCenter
            width: 4
            height: 10
            color: pos <= root.value
                ? (root.warnFrom >= 0 && pos > root.warnFrom ? root.warnColor : root.color)
                : Theme.steel
        }
    }

    // Thumb
    Rectangle {
        width: 2
        height: 18
        color: Theme.ivory
        x: Math.max(0, Math.min(root.width - 2, (root.value - root.from) / (root.to - root.from) * root.width))
    }

    // Keyboard focus ring
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        color: "transparent"
        border.width: root.activeFocus ? 1 : 0
        border.color: Theme.ivory
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function setFrom(mx) {
            root.moved(root.from + Math.max(0, Math.min(1, mx / root.width)) * (root.to - root.from))
        }

        onPressed: m => setFrom(m.x)
        onPositionChanged: m => { if (pressed) setFrom(m.x) }
        onWheel: w => root.moved(root.clamp(root.value + (w.angleDelta.y > 0 ? 1 : -1) * root.step))
    }
}
