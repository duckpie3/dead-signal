import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.theme
import qs.components
import qs.services

// The lock screen picture, drawn by the lock surface and, identically, by the unlock overlay:
// wallpaper under a flat dim, a dot-matrix clock, the user, the oscilloscope and a status line.
FocusScope {
    id: root

    focus: true
    Component.onCompleted: {
        root.forceActiveFocus();
        Weather.refresh();
    }

    readonly property string ph: LockState.phase
    readonly property bool opening: ph === "opening"
    readonly property bool granted: ph === "granted" || opening
    readonly property bool lockout: ph === "lockout"
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real uiScale: Math.min(1.6, Math.max(1, height / 720))
    readonly property int ms: Theme.reduceMotion ? 0 : 1

    readonly property var stateText: ({
        idle: "Locked", typing: "Locked", checking: "Verifying", denied: "Denied", lockout: "Locked out",
        granted: "Unlocked", opening: "Unlocked"
    })
    readonly property color stateColor: ph === "checking" ? Theme.brass
        : (ph === "denied" || lockout) ? Theme.rust
        : granted ? Theme.sage
        : Theme.ash

    // ── Keys ──────────────────────────────────────────────
    Keys.onPressed: event => {
        event.accepted = true;
        if (!LockState.typing) return;
        const k = event.key;
        if (k === Qt.Key_Escape) LockState.clear();
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) LockState.submit();
        else if (k === Qt.Key_Backspace) { LockTrace.backspace(); LockState.backspace(); }
        else if (event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127
                 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            LockTrace.key(event.text.charCodeAt(0));
            LockState.type(event.text);
        } else if (k !== Qt.Key_Shift && k !== Qt.Key_Control && k !== Qt.Key_Alt && k !== Qt.Key_Meta
                 && k !== Qt.Key_CapsLock && k !== Qt.Key_Tab && k !== Qt.Key_AltGr && k !== Qt.Key_Super_L && k !== Qt.Key_Super_R)
            LockState.wake();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { LockState.wake(); root.forceActiveFocus(); }
    }

    // ── Wallpaper under a flat dim ────────────────────────
    Rectangle { anchors.fill: parent; color: "#0B0B0B" }
    Image {
        anchors.fill: parent
        asynchronous: true
        cache: false
        visible: status === Image.Ready
        source: Wallpapers.current !== "" ? Wallpapers.url(Wallpapers.current) : ""
        fillMode: Wallpapers.fit === "fit" ? Image.PreserveAspectFit
                : Wallpapers.fit === "tile" ? Image.Tile : Image.PreserveAspectCrop
        sourceSize: Wallpapers.fit === "tile" ? Qt.size(0, 0) : Qt.size(Math.max(root.width, root.height), Math.max(root.width, root.height))
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0.043, 0.043, 0.043, Config.lockDim) }

    // ── Frame ─────────────────────────────────────────────
    CornerMark { x: 24; y: 24 }
    CornerMark { x: root.width - 24 - width; y: 24; atRight: true }
    CornerMark { x: 24; y: root.height - 24 - height; atBottom: true }
    CornerMark { x: root.width - 24 - width; y: root.height - 24 - height; atRight: true; atBottom: true }

    Row {
        x: 52
        y: 36
        spacing: 8
        Rectangle { width: 6; height: 6; color: root.stateColor; anchors.verticalCenter: parent.verticalCenter }
        Lb { text: root.stateText[root.ph]; color: Theme.ash; anchors.verticalCenter: parent.verticalCenter }
    }

    // ── Centre column, scaled up a little on big screens ──
    Item {
        x: root.cx
        y: root.cy
        scale: root.uiScale
        transformOrigin: Item.TopLeft

        DotClock {
            x: -width / 2
            y: -210
            pixel: 12
            gap: 6
            text: Time.hhmm
        }

        Lb {
            x: -width / 2
            y: -108
            font.pixelSize: 11
            font.letterSpacing: 1.4
            color: Theme.ash
            text: Qt.formatDateTime(Time.date, "dddd · d MMMM yyyy")
        }

        Rectangle { x: -24; y: -70; width: 48; height: 1; color: Theme.steel }

        // Waiting: any key.
        Keycap {
            x: -width / 2
            y: 24
            key: "Any key"
            label: "to unlock"
            opacity: root.ph === "idle" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }
        }

        // The user. The dead pixel of the emblem comes alive when the password is accepted.
        Row {
            id: userRow
            x: -width / 2
            y: -24
            spacing: 14
            opacity: root.ph === "idle" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }

            Item {
                width: 40
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                readonly property var px: [[3, 0], [2, 1], [4, 1], [1, 2], [5, 2], [0, 3], [6, 3], [0, 4], [1, 4], [2, 4], [4, 4], [5, 4], [6, 4]]
                Repeater {
                    model: parent.px
                    Rectangle {
                        required property var modelData
                        x: modelData[0] * 6
                        y: modelData[1] * 6
                        width: 4
                        height: 4
                        color: Theme.ash
                    }
                }
                Rectangle {
                    x: 3 * 6
                    y: 4 * 6
                    width: 4
                    height: 4
                    color: root.granted ? Theme.sage : (root.ph === "denied" || root.lockout) ? Theme.rust : Theme.copper
                    Behavior on color { ColorAnimation { duration: 200 * root.ms } }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Txt { text: LockState.user; font.pixelSize: 15; font.weight: Font.Medium }
                Mono {
                    text: LockState.user + (LockState.host !== "" ? "@" + LockState.host : "")
                    font.pixelSize: 10
                    color: Theme.dust
                }
            }

            Rectangle {
                visible: LockState.caps
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                border.width: 1
                border.color: Theme.rust
                implicitWidth: capsText.implicitWidth + 10
                implicitHeight: capsText.implicitHeight + 4
                width: implicitWidth
                height: implicitHeight
                Lb { id: capsText; anchors.centerIn: parent; text: "Caps"; color: Theme.rust }
            }
        }

        // The trace, one burst per key.
        Trace {
            x: -153
            y: 13
            opacity: root.ph === "idle" || root.lockout ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }
        }

        // Lockout: a strip that drains, one segment per 1/24 of the wait.
        RowLayout {
            x: -153
            y: 38
            width: 306
            spacing: 2
            opacity: root.lockout ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }

            Repeater {
                model: 24
                Rectangle {
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 2
                    color: index < Math.ceil(LockState.lockLeft / LockState.lockTotal * 24) ? Theme.rust : Theme.steel
                }
            }
        }

        // Message line
        RowLayout {
            x: -153
            y: 72
            width: 306
            opacity: root.ph === "idle" ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }

            Lb {
                Layout.fillWidth: true
                text: root.ph === "checking" ? "Verifying"
                    : root.ph === "denied" ? "Access denied · attempt " + String(LockState.fails).padStart(2, "0")
                    : root.lockout ? "Locked out · " + String(Math.ceil(LockState.lockLeft / 1000)).padStart(2, "0") + " s"
                    : root.granted ? "Signal acquired"
                    : LockState.pw.length > 0 ? String(Math.min(LockState.pw.length, 64)).padStart(2, "0") + " · Enter to unlock"
                    : "Enter password"
                color: root.ph === "checking" ? Theme.brass
                     : (root.ph === "denied" || root.lockout) ? Theme.rust
                     : root.granted ? Theme.sage
                     : LockState.pw.length > 0 ? Theme.ash : Theme.dust
            }
            Keycap { visible: LockState.typing; key: "Esc"; label: "Clear" }
        }
    }

    // ── Status line, bottom centre ────────────────────────
    Row {
        id: statusLine
        x: (root.width - width) / 2
        y: root.height - 36 - height
        spacing: 14

        readonly property var dev: UPower.displayDevice
        readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
        readonly property bool showBat: !!dev && (dev.isLaptopBattery || dev.energyCapacity > 0)
        readonly property bool showNotif: Notifs.unread > 0
        readonly property bool showWx: Weather.enabled && Weather.ok

        Row {
            visible: statusLine.showBat
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter
            SegMeter {
                anchors.verticalCenter: parent.verticalCenter
                count: 10
                filled: Math.ceil(statusLine.pct / 10)
                segH: 8
                onColor: statusLine.pct <= 10 ? Theme.rust : statusLine.pct <= 25 ? Theme.copper : Theme.sage
            }
            Mono { text: Math.round(statusLine.pct) + "%"; font.pixelSize: 10; color: Theme.ash; anchors.verticalCenter: parent.verticalCenter }
        }

        Rectangle { visible: statusLine.showBat && statusLine.showNotif; width: 1; height: 10; color: Theme.steel; anchors.verticalCenter: parent.verticalCenter }

        Row {
            visible: statusLine.showNotif
            spacing: 7
            anchors.verticalCenter: parent.verticalCenter
            Glyph { path: Icons.bell; size: 12; anchors.verticalCenter: parent.verticalCenter }
            Lb { text: Notifs.unread + " waiting"; color: Theme.ash; anchors.verticalCenter: parent.verticalCenter }
        }

        Rectangle { visible: statusLine.showWx && (statusLine.showBat || statusLine.showNotif); width: 1; height: 10; color: Theme.steel; anchors.verticalCenter: parent.verticalCenter }

        Lb {
            visible: statusLine.showWx
            anchors.verticalCenter: parent.verticalCenter
            text: Config.weatherPlace + " · " + Math.round(Weather.temp) + "°"
            color: Theme.ash
        }

        Rectangle { visible: statusLine.showBat || statusLine.showNotif || statusLine.showWx; width: 1; height: 10; color: Theme.steel; anchors.verticalCenter: parent.verticalCenter }

        Lb {
            anchors.verticalCenter: parent.verticalCenter
            text: (Quickshell.env("XDG_CURRENT_DESKTOP") || "Wayland") + (LockState.host !== "" ? " · " + LockState.host : "")
        }
    }
}
