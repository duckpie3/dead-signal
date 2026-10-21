pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property var date: clock.date
    readonly property string hhmm: Qt.formatDateTime(clock.date, "HH:mm")
    // "SUN 18.10"
    readonly property string shortDate: Qt.formatDateTime(clock.date, "ddd dd.MM").toUpperCase()

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
