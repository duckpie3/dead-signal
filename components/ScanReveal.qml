import QtQuick
import qs.theme

// Opens its content with a scan line: a 2 px brass line steps down in 6 px rows and the
// content appears behind it. Only runs when `active` turns on; closing is instant.
// Put the panel's content inside it, exactly as you would inside an Item.
Item {
    id: root

    property bool active: true
    property int stepPx: 6
    property int duration: 400

    default property alias content: full.data

    readonly property int rows: Math.max(1, Math.ceil(height / stepPx))
    property real progress: 1
    readonly property bool running: progress < 1
    readonly property int row: Math.floor(progress * rows) + 1
    readonly property real revealH: running ? Math.min(height, row * stepPx + 2) : height

    function restart() {
        anim.stop();
        if (!active || Theme.reduceMotion) {
            progress = 1;
            return;
        }
        progress = 0;
        anim.start();
    }

    onActiveChanged: restart()
    Component.onCompleted: restart()

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.duration
    }

    Item {
        width: root.width
        height: root.revealH
        clip: true

        Item {
            id: full
            width: root.width
            height: root.height
        }
    }

    Rectangle {
        x: 8
        width: root.width - 16
        y: root.revealH - 4
        height: 2
        color: Theme.brass
        visible: root.running && root.row < root.rows
    }
}
