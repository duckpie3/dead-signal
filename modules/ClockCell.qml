import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Date label plus dot-matrix time. Click opens the calendar.
Cell {
    id: root

    signal toggle()

    interactive: true
    spacing: 10
    onClicked: m => root.toggle()

    Lb { text: Time.shortDate }

    DotClock {
        text: Time.hhmm
        pixel: 2
        gap: 1
    }
}
