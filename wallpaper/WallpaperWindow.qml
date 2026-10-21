import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.theme
import qs.components
import qs.services

// Full-screen wallpaper picker. The highlighted wallpaper is previewed behind a flat dim,
// with a carousel of chamfered thumbnails in front. Enter applies; the overlay stays open.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property bool shown: Wallpapers.open
        && (Hyprland.focusedMonitor === null || Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)

    visible: shown
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "deadsignal-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ── State ─────────────────────────────────────────────
    readonly property var items: Wallpapers.items
    readonly property int count: items.length
    property int sel: 0
    property string scale: "fill"
    property bool applied: false           // shows APPLIED until the selection moves
    property bool animate: false

    readonly property var cur: count > 0 ? items[Math.min(sel, count - 1)] : null
    readonly property var scales: [{ id: "fill", label: "Fill" }, { id: "fit", label: "Fit" }, { id: "tile", label: "Tile" }]

    // Put the highlight on the wallpaper that is set, without sweeping the carousel there.
    function jumpToCurrent() {
        win.animate = false;
        let i = 0;
        for (let k = 0; k < win.count; k++)
            if (win.items[k].path === Wallpapers.current) { i = k; break; }
        win.sel = i;
        win.applied = false;
        Qt.callLater(() => { win.animate = true; });
    }

    onShownChanged: {
        if (shown) {
            win.scale = Wallpapers.fit;
            win.jumpToCurrent();
            keys.forceActiveFocus();
        }
    }
    onCountChanged: if (shown) win.jumpToCurrent()

    function go(delta) {
        if (count === 0) return;
        win.sel = ((win.sel + delta) % count + count) % count;
        win.applied = false;
    }

    function pick(i) {
        win.sel = i;
        win.applied = false;
    }

    function random() {
        if (count < 2) return;
        let i = Math.floor(Math.random() * count);
        if (i === win.sel) i = (i + 1) % count;
        win.pick(i);
    }

    function applyCurrent() {
        if (!cur) return;
        Wallpapers.apply(cur.path, win.scale);
        win.applied = true;
    }

    function cycleScale() {
        const i = scales.findIndex(s => s.id === win.scale);
        win.scale = scales[(i + 1) % scales.length].id;
    }

    // Scrubber: one segment per wallpaper, bucketed beyond 24.
    readonly property int segCount: Math.min(Math.max(count, 1), 24)
    function bucket(i) { return Math.min(segCount - 1, Math.floor(i * segCount / Math.max(count, 1))); }
    readonly property int appliedIndex: {
        for (let k = 0; k < count; k++)
            if (items[k].path === Wallpapers.current) return k;
        return -1;
    }
    readonly property real scrubW: segCount * 14 + (segCount - 1) * 5

    readonly property real cx: Math.round(width / 2)
    readonly property real cy: Math.round(height / 2 - 49)

    // ── Scene ─────────────────────────────────────────────
    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Right) win.go(1);
            else if (event.key === Qt.Key_Left) win.go(-1);
            else if (event.key === Qt.Key_Home) win.pick(0);
            else if (event.key === Qt.Key_End) win.pick(Math.max(0, win.count - 1));
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.applyCurrent();
            else if (event.key === Qt.Key_R) win.random();
            else if (event.key === Qt.Key_Tab) win.cycleScale();
            else if (event.key === Qt.Key_Escape) Wallpapers.hide();
            else return;
            event.accepted = true;
        }

        // Preview of the highlighted wallpaper, darkened flat. No blur.
        Rectangle { anchors.fill: parent; color: "#0B0B0B" }
        Image {
            anchors.fill: parent
            asynchronous: true
            cache: false
            visible: win.cur !== null
            source: win.cur ? Wallpapers.url(win.cur.path) : ""
            fillMode: win.scale === "fill" ? Image.PreserveAspectCrop
                    : win.scale === "fit" ? Image.PreserveAspectFit : Image.Tile
            sourceSize: win.scale === "tile" ? Qt.size(0, 0) : Qt.size(Math.max(win.width, win.height), Math.max(win.width, win.height))
        }
        Rectangle { anchors.fill: parent; color: Qt.rgba(0.043, 0.043, 0.043, 0.8) }

        // Click outside the cards closes.
        MouseArea {
            anchors.fill: parent
            onClicked: Wallpapers.hide()
        }

        WheelHandler {
            property real acc: 0
            onWheel: event => {
                acc += event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                if (Math.abs(acc) >= 120) {
                    win.go(acc > 0 ? -1 : 1);
                    acc = 0;
                }
            }
        }

        // ── Header ────────────────────────────────────────
        Row {
            x: 40
            y: 32
            spacing: 14

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: 6; height: 6; color: Theme.ash; anchors.verticalCenter: parent.verticalCenter }
                Lb { text: "Wallpapers"; anchors.verticalCenter: parent.verticalCenter }
            }
            Mono { text: Config.wallpaperDir; color: Theme.dust; anchors.verticalCenter: parent.verticalCenter }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 40
            y: 32 - 3
            spacing: 10

            Lb { text: "Scale"; anchors.verticalCenter: parent.verticalCenter }
            Row {
                spacing: 1
                Repeater {
                    model: win.scales
                    ModeTab {
                        required property var modelData
                        label: modelData.label
                        active: win.scale === modelData.id
                        onClicked: win.scale = modelData.id
                    }
                }
            }
        }

        // ── Carousel ──────────────────────────────────────
        Repeater {
            model: win.count

            WallCard {
                // `index` comes from the Repeater into WallCard's own required property.
                wp: win.items[index]
                slot: {
                    let v = ((index - win.sel) % win.count + win.count) % win.count;
                    if (v > win.count / 2) v -= win.count;
                    return Math.max(-5, Math.min(5, v));
                }
                animate: win.animate
                applied: wp.path === Wallpapers.current
                centerX: win.cx
                centerY: win.cy
                onPicked: win.pick(index)
                onActivated: { win.pick(index); win.applyCurrent(); }
            }
        }

        // Nothing to show.
        Column {
            visible: win.count === 0
            x: win.cx - width / 2
            y: win.cy - height / 2
            spacing: 8
            Lb {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Wallpapers.scanning ? "Looking…" : "No images found"
                color: Theme.ash
            }
            Mono {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Config.wallpaperDir
                color: Theme.dust
            }
        }

        // ── Name and details ──────────────────────────────
        Column {
            visible: win.cur !== null
            x: win.cx - width / 2
            y: win.cy + 121
            spacing: 8

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.cur ? win.cur.name : ""
                font.pixelSize: 15
                font.weight: Font.Medium
            }
            Mono {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.ash
                text: win.cur
                    ? [win.cur.res, Wallpapers.sizeText(win.cur.bytes), win.cur.path === Wallpapers.current ? "current" : ""]
                        .filter(s => s !== "").join(" · ")
                    : ""
            }
        }

        // ── Scrubber with prev / next ─────────────────────
        Row {
            visible: win.count > 0
            x: win.cx - win.scrubW / 2
            y: win.cy + 209 + 12 - height
            spacing: 5

            Repeater {
                model: win.segCount
                Rectangle {
                    required property int index
                    readonly property bool here: index === win.bucket(win.sel)
                    anchors.bottom: parent.bottom
                    width: 14
                    height: here ? 12 : 4
                    color: here ? Theme.ivory
                         : (win.appliedIndex >= 0 && index === win.bucket(win.appliedIndex)) ? Theme.teal
                         : Theme.steel
                }
            }
        }

        Repeater {
            model: win.count > 0 ? [-1, 1] : []

            Item {
                id: nav
                required property int modelData
                x: win.cx + (modelData < 0 ? -win.scrubW / 2 - 14 - 36 : win.scrubW / 2 + 14)
                y: win.cy + 197
                width: 36
                height: 36
                activeFocusOnTab: false

                Chamfer { anchors.fill: parent; cut: 6; fillColor: Theme.steel }
                Chamfer {
                    anchors.fill: parent
                    anchors.margins: 1
                    cut: 5
                    fillColor: navMouse.containsMouse ? Theme.panel : Theme.bg
                }
                Glyph {
                    anchors.centerIn: parent
                    path: nav.modelData < 0 ? Icons.chevLeft : Icons.chevRight
                    size: 14
                    stroke: 1.5
                }
                MouseArea {
                    id: navMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.go(nav.modelData)
                }
            }
        }

        // ── Position, bottom left ─────────────────────────
        Row {
            visible: win.count > 0
            x: 40
            y: parent.height - 36 - height
            spacing: 12

            DotText {
                id: idx
                text: String(win.sel + 1).padStart(String(win.count).length, "0")
                pixel: 4
                gap: 1
                lit: Theme.brass
            }
            Lb {
                text: "of " + String(win.count).padStart(2, "0")
                anchors.bottom: parent.bottom
                bottomPadding: 1
            }
        }

        // ── Keys ──────────────────────────────────────────
        Row {
            x: win.cx - width / 2
            y: parent.height - 36 - height
            spacing: 20

            Keycap { key: "←→"; label: "Browse" }
            Keycap { key: "Enter"; label: "Apply" }
            Keycap { key: "R"; label: "Random" }
            Keycap { key: "Tab"; label: "Scale" }
            Keycap { key: "Esc"; label: "Close" }
        }

        Mono {
            anchors.right: parent.right
            anchors.rightMargin: 40
            y: parent.height - 36 - height + 1
            font.pixelSize: 10
            color: win.applied ? Theme.sage : Theme.dust
            text: win.applied && win.cur ? "APPLIED · " + win.cur.name.toUpperCase() : "LIVE PREVIEW"
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 360)
            horizontalAlignment: Text.AlignRight
        }
    }
}
