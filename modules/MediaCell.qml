import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Now playing: state icon, title, artist, and a progress line along the bottom edge.
// Click: popup. Middle click: play / pause. Scroll: next / previous track.
// Hidden when no player is running.
Cell {
    id: root

    signal toggle()

    visible: Media.present
    interactive: true
    spacing: 8

    property real lastWheel: 0

    onClicked: m => {
        if (m.button === Qt.MiddleButton) Media.toggle();
        else root.toggle();
    }
    onWheeled: w => {
        const now = Date.now();
        if (now - root.lastWheel < 350) return;
        root.lastWheel = now;
        if (w.angleDelta.y > 0) Media.prev(); else Media.next();
    }

    Glyph {
        path: Media.playing ? Icons.pause : Icons.play
        color: Media.playing ? Theme.teal : Theme.ash
    }

    Marquee {
        Layout.preferredWidth: Math.min(150, implicitWidth)
        text: Media.title
        color: Media.playing ? Theme.ivory : Theme.ash
    }

    Marquee {
        visible: Media.artist !== ""
        Layout.preferredWidth: Math.min(96, implicitWidth)
        text: Media.artist
        color: Theme.dust
    }

    // Progress. Stops short of the cell's cut corner.
    Rectangle {
        visible: Media.len > 0
        parent: root
        x: 0
        y: root.height - 2
        width: root.width - Theme.cut
        height: 2
        color: Theme.steel

        Rectangle {
            width: parent.width * Media.pct
            height: 2
            color: Media.playing ? Theme.teal : Theme.dust
        }
    }
}
