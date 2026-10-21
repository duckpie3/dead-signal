import Quickshell.Services.Notifications
import QtQuick

// One notification plus the shell's own state for it (read, shown as a toast, time left).
QtObject {
    id: root

    required property var n               // the Notification

    property bool read: false
    property bool toast: false            // currently shown as a toast
    property bool paused: false           // pointer is over the toast
    property real time: Date.now()        // when it arrived
    property real duration: 0             // toast lifetime in ms; 0 holds until dismissed
    property real remaining: 0

    readonly property bool critical: n.urgency === NotificationUrgency.Critical

    signal gone()

    property Connections watch: Connections {
        target: root.n
        function onClosed() { root.gone(); }
    }
}
