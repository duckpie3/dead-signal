import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.theme
import qs.components
import qs.services

// The lock screen picture: wallpaper under 12 shutters, dot-matrix clock, and the password panel.
FocusScope {
    id: root

    focus: true
    Component.onCompleted: root.forceActiveFocus()

    readonly property string ph: LockState.phase
    readonly property bool opening: ph === "opening"
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real uiScale: Math.min(1.6, Math.max(1, height / 800))
    readonly property int ms: Theme.reduceMotion ? 0 : 1

    readonly property var stateText: ({
        idle: "Locked", typing: "Locked", checking: "Verifying", denied: "Denied",
        granted: "Unlocked", opening: "Unlocked"
    })
    readonly property color stateColor: ph === "checking" ? Theme.brass
        : ph === "denied" ? Theme.rust
        : (ph === "granted" || ph === "opening") ? Theme.sage
        : Theme.ash

    // ── Keys ──────────────────────────────────────────────
    Keys.onPressed: event => {
        event.accepted = true;
        if (!LockState.typing) return;
        const k = event.key;
        if (k === Qt.Key_Escape) LockState.clear();
        else if (k === Qt.Key_Return || k === Qt.Key_Enter) LockState.submit();
        else if (k === Qt.Key_Backspace) LockState.backspace();
        else if (event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127
                 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
            LockState.type(event.text);
        else if (k !== Qt.Key_Shift && k !== Qt.Key_Control && k !== Qt.Key_Alt && k !== Qt.Key_Meta
                 && k !== Qt.Key_CapsLock && k !== Qt.Key_Tab && k !== Qt.Key_AltGr && k !== Qt.Key_Super_L && k !== Qt.Key_Super_R)
            LockState.wake();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { LockState.wake(); root.forceActiveFocus(); }
    }

    // ── Wallpaper, full brightness ────────────────────────
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

    // ── Everything on the lock layer ──────────────────────
    Item {
        id: ui
        anchors.fill: parent
        // The shutters sit between the wallpaper and this layer, so this is added after them (see z).
        z: 2
        opacity: root.opening ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }

        // State, top left
        Row {
            x: 40
            y: 32
            spacing: 8
            Rectangle { width: 6; height: 6; color: root.stateColor; anchors.verticalCenter: parent.verticalCenter }
            Lb { text: root.stateText[root.ph]; color: Theme.ash; anchors.verticalCenter: parent.verticalCenter }
        }

        // Battery, top right
        Row {
            id: batt
            readonly property var dev: UPower.displayDevice
            readonly property real pct: dev ? (dev.percentage > 1 ? dev.percentage : dev.percentage * 100) : 0
            visible: !!dev && (dev.isLaptopBattery || dev.energyCapacity > 0)
            anchors.right: parent.right
            anchors.rightMargin: 40
            y: 30
            spacing: 10
            Lb { text: "Bat"; anchors.verticalCenter: parent.verticalCenter }
            SegMeter {
                anchors.verticalCenter: parent.verticalCenter
                count: 10
                filled: Math.ceil(batt.pct / 10)
                onColor: batt.pct <= 10 ? Theme.rust : batt.pct <= 25 ? Theme.copper : Theme.sage
            }
            Mono { text: Math.round(batt.pct) + "%"; color: Theme.ash; anchors.verticalCenter: parent.verticalCenter }
        }

        // Bottom corners
        Row {
            visible: Notifs.unread > 0
            x: 40
            y: parent.height - 36 - height
            spacing: 8
            Glyph { path: Icons.bell; size: 14; anchors.verticalCenter: parent.verticalCenter }
            Lb { text: Notifs.unread + " waiting"; anchors.verticalCenter: parent.verticalCenter }
        }
        Lb {
            anchors.right: parent.right
            anchors.rightMargin: 40
            y: parent.height - 36 - height
            text: (Quickshell.env("XDG_CURRENT_DESKTOP") || "Wayland") + (LockState.host !== "" ? " · " + LockState.host : "")
        }

        // Centre column, scaled up a little on big screens
        Item {
            x: root.cx
            y: root.cy
            scale: root.uiScale
            transformOrigin: Item.TopLeft

            DotClock {
                id: clock
                x: -width / 2
                y: -210
                pixel: 14
                gap: 3
                text: Time.hhmm
            }

            Lb {
                x: -width / 2
                y: -106
                font.pixelSize: 11
                font.letterSpacing: 1.4
                color: Theme.ash
                text: Qt.formatDateTime(Time.date, "dddd · d MMMM yyyy")
            }

            Keycap {
                x: -width / 2
                y: 24
                key: "Any key"
                label: "to unlock"
                opacity: root.ph === "idle" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }
            }

            // ── Password panel ────────────────────────────
            Item {
                id: panel
                x: -190
                y: -30
                width: 380
                height: col.implicitHeight + 32
                opacity: root.ph === "idle" ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 220 * root.ms } }

                property real shakeX: 0
                transform: Translate { x: panel.shakeX }

                SequentialAnimation {
                    running: root.ph === "denied" && !Theme.reduceMotion
                    NumberAnimation { target: panel; property: "shakeX"; to: -9; duration: 45 }
                    NumberAnimation { target: panel; property: "shakeX"; to: 8; duration: 45 }
                    NumberAnimation { target: panel; property: "shakeX"; to: -5; duration: 45 }
                    NumberAnimation { target: panel; property: "shakeX"; to: 3; duration: 45 }
                    NumberAnimation { target: panel; property: "shakeX"; to: 0; duration: 45 }
                }

                Chamfer { anchors.fill: parent; cut: 8; fillColor: Theme.steel }
                Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 7; fillColor: Theme.panel }

                ColumnLayout {
                    id: col
                    x: 19
                    y: 17
                    width: panel.width - 38
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        // Emblem: the dead pixel comes alive on success
                        Item {
                            Layout.preferredWidth: 41
                            Layout.preferredHeight: 29
                            readonly property var px: [[3, 0], [2, 1], [4, 1], [1, 2], [5, 2], [0, 3], [6, 3], [0, 4], [1, 4], [2, 4], [4, 4], [5, 4], [6, 4]]
                            Repeater {
                                model: parent.px
                                Rectangle {
                                    required property var modelData
                                    x: modelData[0] * 6
                                    y: modelData[1] * 6
                                    width: 5
                                    height: 5
                                    color: Theme.ash
                                }
                            }
                            Rectangle {
                                x: 3 * 6
                                y: 4 * 6
                                width: 5
                                height: 5
                                color: (root.ph === "granted" || root.opening) ? Theme.sage
                                     : root.ph === "denied" ? Theme.rust : Theme.copper
                                Behavior on color { ColorAnimation { duration: 200 * root.ms } }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
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
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.rust
                            implicitWidth: capsText.implicitWidth + 10
                            implicitHeight: capsText.implicitHeight + 4
                            Lb { id: capsText; anchors.centerIn: parent; text: "Caps"; color: Theme.rust }
                        }
                    }

                    // Twelve segments, one per character
                    Item {
                        Layout.topMargin: 18
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 306
                        Layout.preferredHeight: 30

                        Row {
                            spacing: 6
                            Repeater {
                                model: 12

                                Rectangle {
                                    id: slot
                                    required property int index

                                    readonly property int n: Math.min(LockState.pw.length, 12)
                                    readonly property bool filled: index < n
                                    readonly property bool newest: LockState.typing && LockState.pw.length > 0 && index === n - 1

                                    readonly property color tint: {
                                        const p = LockState.phase;
                                        if (p === "idle" || p === "typing")
                                            return filled ? Theme.ivory : Theme.steel;
                                        if (p === "checking") return filled ? Theme.ivory : Theme.ash;
                                        if (p === "denied") return Theme.rust;
                                        return Theme.sage;
                                    }

                                    function delayMs() {
                                        const p = LockState.phase;
                                        return p === "checking" ? index * 32 : p === "denied" ? index * 28 : p === "granted" ? index * 40 : 0;
                                    }
                                    function durMs() {
                                        if (LockState.typing)
                                            return filled ? 140 : (LockState.fade ? 700 : 140);
                                        return 140;
                                    }

                                    width: 20
                                    height: 30
                                    y: newest ? -4 : 0
                                    color: Theme.steel
                                    Behavior on y { NumberAnimation { duration: 80 * root.ms } }

                                    Component.onCompleted: color = tint
                                    onTintChanged: {
                                        fadeAnim.stop();
                                        pause.duration = delayMs() * root.ms;
                                        blend.duration = durMs() * root.ms;
                                        blend.from = slot.color;
                                        blend.to = slot.tint;
                                        fadeAnim.restart();
                                    }

                                    SequentialAnimation {
                                        id: fadeAnim
                                        PauseAnimation { id: pause }
                                        ColorAnimation { id: blend; target: slot; property: "color" }
                                    }

                                    Rectangle {      // copper mark on the newest segment
                                        width: parent.width
                                        height: 2
                                        color: Theme.copper
                                        visible: slot.newest
                                    }
                                }
                            }
                        }

                        Rectangle {                  // the scan line
                            id: scan
                            visible: root.ph === "checking"
                            y: -7
                            width: 2
                            height: 44
                            color: Theme.ivory
                            NumberAnimation on x {
                                running: root.ph === "checking"
                                from: -2
                                to: 304
                                duration: 400 * root.ms
                            }
                        }
                    }

                    RowLayout {
                        Layout.topMargin: 16
                        Layout.fillWidth: true
                        Lb {
                            Layout.fillWidth: true
                            text: root.ph === "checking" ? "Verifying"
                                : root.ph === "denied" ? "Access denied · attempt " + String(LockState.fails).padStart(2, "0")
                                : (root.ph === "granted" || root.opening) ? "Signal acquired"
                                : LockState.pw.length > 0 ? "Enter to unlock" : "Enter password"
                            color: root.ph === "checking" ? Theme.brass
                                 : root.ph === "denied" ? Theme.rust
                                 : (root.ph === "granted" || root.opening) ? Theme.sage
                                 : LockState.pw.length > 0 ? Theme.ash : Theme.dust
                        }
                        Keycap { key: "Esc"; label: "Clear" }
                    }
                }
            }
        }
    }

    // ── Shutters: dim the wallpaper while locked. They open in the overlay, after the session is released. ──
    Rectangle {
        z: 1
        anchors.fill: parent
        color: Qt.rgba(0.043, 0.043, 0.043, 0.9)
    }
}
