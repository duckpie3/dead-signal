import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Bell, unread count and a copper pixel while something is waiting. Click opens the center.
Cell {
    id: root

    signal toggle()

    interactive: true
    spacing: 7
    onClicked: m => root.toggle()

    Glyph {
        path: Icons.bell
        color: Notifs.dnd ? Theme.dust : Theme.ash
    }

    Mono {
        text: String(Math.min(99, Notifs.unread)).padStart(2, "0")
        color: Notifs.unread > 0 && !Notifs.dnd ? Theme.ivory : Theme.dust
    }

    Lb {
        visible: Notifs.dnd
        text: "DND"
        color: Theme.copper
    }

    // 2x2 unread marker, top-left of the cell.
    Rectangle {
        visible: Notifs.unread > 0 && !Notifs.dnd
        parent: root
        x: 6
        y: 5
        width: 2
        height: 2
        color: Theme.copper
    }
}
