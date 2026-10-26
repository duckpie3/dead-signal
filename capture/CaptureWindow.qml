import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services

// Full-screen capture overlay on the monitor that was focused when it started.
// It shows the frozen frame grim took, so what you select is what was on screen.
//   shot  region: drag an area · screen: the whole monitor · window: click a window
//   pick  a loupe follows the pointer; click copies the colour
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property var mon: Hyprland.monitorFor(modelData)
    readonly property bool shown: Capture.open
        && (Capture.monitorName === "" || (mon !== null && mon.name === Capture.monitorName))

    visible: shown
    color: "black"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "deadsignal-capture"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    readonly property bool picking: Capture.kind === "pick"
    readonly property string mode: Capture.mode
    readonly property string source: "file://" + Capture.frame
    // Physical pixels per layout pixel (2 on a 200 % screen).
    readonly property real sc: shot.status === Image.Ready && width > 0 ? shot.sourceSize.width / width : 1

    // ── Selection state ───────────────────────────────────
    property real mx: 0
    property real my: 0
    property bool dragging: false
    property real ax: 0
    property real ay: 0
    property var region: null              // { x, y, w, h }
    property var hoverWin: null

    readonly property var sel: {
        if (win.picking) return null;
        if (win.mode === "screen") return { x: 0, y: 0, w: win.width, h: win.height };
        if (win.mode === "window") return win.hoverWin;
        return win.region;
    }
    readonly property bool settled: sel !== null && !dragging

    onShownChanged: {
        if (shown) {
            win.region = null;
            win.hoverWin = null;
            win.dragging = false;
            win.mx = win.width / 2;
            win.my = win.height / 2;
            keys.forceActiveFocus();
        }
    }

    function setMode(m) {
        Capture.mode = m;
        win.region = null;
        win.hoverWin = null;
        win.dragging = false;
        win.findWindow();
    }

    function cycle(d) {
        const ms = ["region", "screen", "window"];
        win.setMode(ms[(ms.indexOf(win.mode) + d + ms.length) % ms.length]);
    }

    function findWindow() {
        win.hoverWin = null;
        if (win.mode !== "window") return;
        const w = Capture.windows;
        for (let i = 0; i < w.length; i++) {
            if (win.mx >= w[i].x && win.mx < w[i].x + w[i].w && win.my >= w[i].y && win.my < w[i].y + w[i].h) {
                win.hoverWin = { x: Math.max(0, w[i].x), y: Math.max(0, w[i].y),
                    w: Math.min(win.width, w[i].x + w[i].w) - Math.max(0, w[i].x),
                    h: Math.min(win.height, w[i].y + w[i].h) - Math.max(0, w[i].y), title: w[i].title };
                return;
            }
        }
    }

    // ── Saving ────────────────────────────────────────────
    property var job: null                 // { x, y, w, h, label } in physical pixels

    function capture() {
        const s = win.sel;
        if (win.picking || !s || s.w < 2 || s.h < 2) return;
        const k = win.sc;
        const x = Math.max(0, Math.round(s.x * k)), y = Math.max(0, Math.round(s.y * k));
        const w = Math.max(1, Math.min(shot.sourceSize.width - x, Math.round(s.w * k)));
        const h = Math.max(1, Math.min(shot.sourceSize.height - y, Math.round(s.h * k)));
        win.job = { x: x, y: y, w: w, h: h, label: win.mode === "region" ? "Region" : win.mode === "screen" ? "Screen" : "Window" };
    }

    // Renders just the selected part of the frame off screen and writes it as a PNG.
    Loader {
        active: win.job !== null
        sourceComponent: Item {
            id: crop
            readonly property var j: win.job
            x: -200000
            width: j.w
            height: j.h
            clip: true

            Image {
                id: part
                x: -crop.j.x
                y: -crop.j.y
                source: win.source
                cache: false
                asynchronous: false
                smooth: false
            }

            Component.onCompleted: Qt.callLater(() => {
                const path = Capture.nextPath();
                const j = crop.j;
                crop.grabToImage(res => {
                    const ok = res.saveToFile(path);
                    win.job = null;
                    if (ok) Capture.shotSaved(path, j.w, j.h, j.label);
                    else Capture.failed("Capture failed", "could not write " + path);
                }, Qt.size(j.w, j.h));
            })
        }
    }

    // ── Picking ───────────────────────────────────────────
    // The frame is painted once into a canvas so single pixels can be read back.
    property var cells: []                 // 81 colours, row by row, the centre one is the pointer
    property color under: "black"
    property bool canvasReady: false

    function sample() {
        if (!win.picking || !win.canvasReady) return;
        const ctx = pxLoader.item.getContext("2d");
        const cx = Math.max(0, Math.min(shot.sourceSize.width - 1, Math.round(win.mx * win.sc)));
        const cy = Math.max(0, Math.min(shot.sourceSize.height - 1, Math.round(win.my * win.sc)));
        const d = ctx.getImageData(cx - 4, cy - 4, 9, 9).data;
        const out = [];
        for (let i = 0; i < 81; i++) out.push(Qt.rgba(d[i * 4] / 255, d[i * 4 + 1] / 255, d[i * 4 + 2] / 255, 1));
        win.cells = out;
        win.under = out[40];
    }

    function pickHere() {
        if (!win.canvasReady) return;
        win.sample();
        Capture.picked(Math.round(win.under.r * 255), Math.round(win.under.g * 255), Math.round(win.under.b * 255));
    }

    Loader {
        id: pxLoader
        active: win.shown && win.picking && shot.status === Image.Ready
        sourceComponent: Canvas {
            x: -200000
            width: shot.sourceSize.width
            height: shot.sourceSize.height
            renderTarget: Canvas.Image
            Component.onCompleted: loadImage(win.source)
            onImageLoaded: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.drawImage(win.source, 0, 0);
                win.canvasReady = true;
                win.sample();
            }
        }
        onActiveChanged: if (!active) win.canvasReady = false
    }

    // ── The frozen frame ──────────────────────────────────
    Image {
        id: shot
        anchors.fill: parent
        source: win.shown ? win.source : ""
        cache: false
        smooth: false
        fillMode: Image.Stretch
    }

    // Everything outside the selection is dimmed flat.
    Item {
        anchors.fill: parent
        visible: win.sel !== null && win.mode !== "screen"
        readonly property color dim: Qt.rgba(0.043, 0.043, 0.043, 0.62)
        readonly property var s: win.sel || { x: 0, y: 0, w: 0, h: 0 }

        Rectangle { x: 0; y: 0; width: parent.width; height: parent.s.y; color: parent.dim }
        Rectangle { x: 0; y: parent.s.y + parent.s.h; width: parent.width; height: parent.height - y; color: parent.dim }
        Rectangle { x: 0; y: parent.s.y; width: parent.s.x; height: parent.s.h; color: parent.dim }
        Rectangle { x: parent.s.x + parent.s.w; y: parent.s.y; width: parent.width - x; height: parent.s.h; color: parent.dim }
    }

    // Crosshair before a drag starts.
    Item {
        anchors.fill: parent
        visible: !win.picking && win.mode === "region" && win.sel === null
        Rectangle { x: win.mx; width: 1; height: parent.height; color: Theme.ivory; opacity: 0.5 }
        Rectangle { y: win.my; height: 1; width: parent.width; color: Theme.ivory; opacity: 0.5 }

        Item {
            x: Math.min(win.mx + 16, win.width - width - 8)
            y: Math.min(win.my + 16, win.height - height - 8)
            width: coord.implicitWidth + 20
            height: 26
            Chamfer { anchors.fill: parent; cut: 5; fillColor: Theme.steel }
            Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 4; fillColor: Theme.bg }
            Mono {
                id: coord
                anchors.centerIn: parent
                text: Math.round(win.mx * win.sc) + ", " + Math.round(win.my * win.sc)
            }
        }
    }

    // Selection outline, handles, copper mark.
    Item {
        id: box
        visible: win.sel !== null
        readonly property var s: win.sel || { x: 0, y: 0, w: 0, h: 0 }
        x: s.x
        y: s.y
        width: s.w
        height: s.h

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Theme.ivory
        }
        Rectangle { x: 4; y: 4; width: 2; height: 2; color: Theme.copper }
        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            Rectangle {
                required property var modelData
                width: 5
                height: 5
                x: modelData[0] * box.width - 2
                y: modelData[1] * box.height - 2
                color: Theme.ivory
            }
        }
    }

    // Size and position readout above the selection (inside it when there is no room above).
    Item {
        visible: win.sel !== null && win.sel.w > 0
        readonly property var s: win.sel || { x: 0, y: 0, w: 0, h: 0 }
        width: readout.implicitWidth + 24
        height: 26
        x: Math.max(8, Math.min(win.width - width - 8, s.x))
        y: s.y - height - 8 >= 8 ? s.y - height - 8 : s.y + 8

        Chamfer { anchors.fill: parent; cut: 5; fillColor: Theme.steel }
        Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 4; fillColor: Theme.bg }
        RowLayout {
            id: readout
            anchors.centerIn: parent
            spacing: 10
            Mono { text: Math.round(parent.parent.s.w * win.sc) + " × " + Math.round(parent.parent.s.h * win.sc) }
            Mono { text: Math.round(parent.parent.s.x * win.sc) + ", " + Math.round(parent.parent.s.y * win.sc); color: Theme.dust }
            Lb { visible: win.mode === "window" && win.hoverWin !== null; text: win.hoverWin ? win.hoverWin.title : ""; elide: Text.ElideRight; Layout.maximumWidth: 240 }
        }
    }

    // Capture button once a region (or the screen) is settled.
    Item {
        id: go
        visible: win.settled && win.mode !== "window" && win.sel.w >= 2
        readonly property var s: win.sel || { x: 0, y: 0, w: 0, h: 0 }
        width: goRow.implicitWidth + 24
        height: 28
        x: Math.max(8, Math.min(win.width - width - 8, s.x + s.w - width))
        y: s.y + s.h + 8 + height <= win.height - 8 ? s.y + s.h + 8 : s.y + s.h - height - 8

        Chamfer { anchors.fill: parent; cut: 5; fillColor: Theme.steel }
        Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 4; fillColor: goMouse.containsMouse ? Theme.steel : Theme.panel }
        Rectangle { x: 1; y: 1; width: parent.width - 2; height: 2; color: Theme.copper }
        RowLayout {
            id: goRow
            anchors.centerIn: parent
            spacing: 8
            Lb { text: "Capture"; color: Theme.ivory }
            Glyph { path: Icons.enter; color: Theme.ash; size: 12 }
        }
        MouseArea {
            id: goMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.capture()
        }
    }

    // ── Pointer ───────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPositionChanged: m => {
            win.mx = Math.max(0, Math.min(win.width, m.x));
            win.my = Math.max(0, Math.min(win.height, m.y));
            if (win.picking) win.sample();
            else if (win.dragging) {
                win.region = {
                    x: Math.min(win.ax, win.mx), y: Math.min(win.ay, win.my),
                    w: Math.abs(win.mx - win.ax), h: Math.abs(win.my - win.ay)
                };
            } else if (win.mode === "window") win.findWindow();
        }
        onPressed: m => {
            if (m.button === Qt.RightButton) { Capture.cancel(); return; }
            if (win.mode !== "region" || win.picking) return;
            win.ax = win.mx;
            win.ay = win.my;
            win.region = { x: win.mx, y: win.my, w: 0, h: 0 };
            win.dragging = true;
        }
        onReleased: m => {
            if (win.dragging) {
                win.dragging = false;
                if (win.region && (win.region.w < 4 || win.region.h < 4)) win.region = null;
            }
        }
        onClicked: m => {
            if (m.button !== Qt.LeftButton) return;
            if (win.picking) win.pickHere();
            else if (win.mode === "window" && win.hoverWin) win.capture();
            else if (win.mode === "screen" && !goMouse.containsMouse) win.capture();
        }
    }

    // ── Mode tabs and hints ───────────────────────────────
    Item {
        visible: !win.picking
        anchors.horizontalCenter: parent.horizontalCenter
        y: 24
        width: tabs.implicitWidth + 12
        height: 36

        Chamfer { anchors.fill: parent; cut: 7; fillColor: Theme.steel }
        Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 6; fillColor: Theme.bg }
        Row {
            id: tabs
            anchors.centerIn: parent
            spacing: 1
            Repeater {
                model: [{ id: "region", label: "Region" }, { id: "screen", label: "Screen" }, { id: "window", label: "Window" }]
                ModeTab {
                    required property var modelData
                    label: modelData.label
                    active: win.mode === modelData.id
                    onClicked: win.setMode(modelData.id)
                }
            }
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - 28
        width: hints.implicitWidth + 32
        height: 34

        Chamfer { anchors.fill: parent; cut: 7; fillColor: Theme.steel }
        Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 6; fillColor: Theme.bg }
        RowLayout {
            id: hints
            anchors.centerIn: parent
            spacing: 16
            Keycap { visible: !win.picking; key: win.mode === "region" ? "Drag" : "Click"; label: "Select" }
            Keycap { visible: win.picking; key: "Click"; label: "Pick" }
            Keycap { visible: !win.picking; key: "Enter"; label: "Capture" }
            Keycap { visible: !win.picking; key: "Tab"; label: "Mode" }
            Keycap { key: "Esc"; label: "Cancel" }
        }
    }

    // ── Pick loupe ────────────────────────────────────────
    Item {
        id: loupe
        visible: win.picking && win.canvasReady
        width: 132
        height: 108 + 12 * 2 + 28 + 1
        x: win.mx + 24 + width > win.width - 8 ? win.mx - 24 - width : win.mx + 24
        y: win.my + 24 + height > win.height - 8 ? win.my - 24 - height : win.my + 24

        Chamfer { anchors.fill: parent; cut: 8; fillColor: Theme.steel }
        Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 7; fillColor: Theme.panel }

        Item {
            x: 12
            y: 12
            width: 108
            height: 108

            Repeater {
                model: 81
                Rectangle {
                    required property int index
                    x: (index % 9) * 12
                    y: Math.floor(index / 9) * 12
                    width: 12
                    height: 12
                    color: win.cells.length > index ? win.cells[index] : "black"
                }
            }
            // Ring on the pixel under the pointer.
            Rectangle { x: 48; y: 48; width: 12; height: 12; color: "transparent"; border.width: 1; border.color: Theme.ivory }
            Rectangle { x: 47; y: 47; width: 14; height: 14; color: "transparent"; border.width: 1; border.color: Theme.bg }
        }

        RowLayout {
            x: 12
            y: 108 + 12 + 10
            width: 108
            spacing: 8
            Rectangle {
                implicitWidth: 14
                implicitHeight: 14
                color: win.under
                border.width: 1
                border.color: Theme.steel
            }
            Mono {
                text: ("#" + Capture.hex2(Math.round(win.under.r * 255)) + Capture.hex2(Math.round(win.under.g * 255))
                    + Capture.hex2(Math.round(win.under.b * 255))).toUpperCase()
            }
        }
    }

    // ── Keys ──────────────────────────────────────────────
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) Capture.cancel();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.picking ? win.pickHere() : win.capture();
            else if (event.key === Qt.Key_Tab && !win.picking) win.cycle(1);
            else if (event.key === Qt.Key_Backtab && !win.picking) win.cycle(-1);
            else return;
            event.accepted = true;
        }
    }
}
