import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Focus timer in the bar, left of the clock. Hidden while idle. Click opens the focus popup.
// Teal while a focus phase runs, brass on a break, dim when paused, copper pixel when a phase
// has ended and waits for you.
Item {
    id: root

    signal toggle()

    visible: Pomodoro.active
    implicitWidth: cell.implicitWidth
    implicitHeight: cell.implicitHeight

    Cell {
        id: cell
        anchors.fill: parent
        interactive: true
        spacing: 8
        onClicked: m => root.toggle()

        Glyph { path: Icons.tomato; size: 14; color: Pomodoro.ink }
        Lb { text: Pomodoro.shortLabel }
        Mono {
            text: Pomodoro.ended ? "DONE" : Pomodoro.fmt(Pomodoro.secsLeft)
            color: Pomodoro.running || Pomodoro.ended ? Theme.ivory : Theme.ash
        }
    }

    // Progress line along the bottom edge, short of the chamfer.
    Rectangle {
        x: 0
        y: parent.height - 2
        width: parent.width - 4
        height: 2
        color: Theme.steel

        Rectangle {
            width: parent.width * Pomodoro.progress
            height: 2
            color: Pomodoro.ended ? Theme.copper : Pomodoro.running ? Pomodoro.tint : Theme.dust
        }
    }

    Rectangle {
        visible: Pomodoro.ended
        x: 3
        y: 3
        width: 2
        height: 2
        color: Theme.copper
    }
}
