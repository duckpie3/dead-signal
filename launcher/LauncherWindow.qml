import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components
import qs.services
import "Fuzzy.js" as Fuzzy
import "Calc.js" as Calc

// Full-screen transparent overlay (click outside to close) holding a 640 px chamfered panel.
// Modes are chosen by prefix, or with Tab / the header tabs:
//   (none) apps   >  command   =  calculator   @  windows
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property bool shown: LauncherState.open
        && (Hyprland.focusedMonitor === null || Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)

    visible: shown
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "deadsignal-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ── State ─────────────────────────────────────────────
    readonly property var modes: ["apps", "cmd", "calc", "win"]
    readonly property var prefixes: ({ apps: "", cmd: "> ", calc: "= ", win: "@ " })
    readonly property var tabNames: ({ apps: "Apps", cmd: "Cmd", calc: "Calc", win: "Win" })

    readonly property string raw: input.text
    readonly property string mode: raw.startsWith(">") ? "cmd" : raw.startsWith("=") ? "calc" : raw.startsWith("@") ? "win" : "apps"
    readonly property string term: (mode === "apps" ? raw : raw.slice(1)).trim()
    property int sel: 0

    onShownChanged: {
        if (shown) {
            input.text = LauncherState.initialQuery;
            win.sel = 0;
            input.forceActiveFocus();
        }
    }

    // ── Result building ───────────────────────────────────
    function catOf(entry) {
        const c = (entry.categories || []).join(";");
        if (/Network|WebBrowser|Email|Chat|InstantMessaging|P2P|FileTransfer|News/.test(c)) return "NET";
        if (/Development|IDE|TextEditor|Debugger|Programming/.test(c)) return "DEV";
        if (/AudioVideo|Audio|Video|Graphics|Player|Recorder|Photography/.test(c)) return "MEDIA";
        return "SYS";
    }

    function appItem(e, m, rel) {
        return {
            name: e.name,
            desc: e.comment || e.genericName || "",
            cat: win.catOf(e),
            tile: e.name.charAt(0).toUpperCase(),
            idx: m ? m.idx : [],
            score: m ? m.score : 0,
            rel: rel,
            run: () => Apps.launch(e)
        };
    }

    function searchApps(q) {
        if (q === "") {
            const rec = Apps.recent(7);
            const top = rec.length ? Math.max(1, ...rec.map(e => Apps.count(e))) : 1;
            return rec.map(e => win.appItem(e, null, Math.max(1, Math.ceil(Apps.count(e) / top * 5))));
        }
        const out = [];
        const all = Apps.entries;
        for (let i = 0; i < all.length; i++) {
            const e = all[i];
            let m = Fuzzy.match(e.name, q);
            if (!m) {
                // Fall back to generic name and keywords, ranked below any name match.
                const extra = [e.genericName || "", (e.keywords || []).join(" ")].join(" ");
                const hit = extra.toLowerCase().indexOf(q.toLowerCase()) >= 0;
                if (!hit) continue;
                m = { score: 10 - e.name.length * 0.2, idx: [] };
            }
            out.push(win.appItem(e, m, 0));
        }
        out.sort((a, b) => b.score - a.score);
        const top = out.length ? Math.max(0.001, out[0].score) : 1;
        out.forEach(o => { o.rel = Math.max(1, Math.min(5, Math.round(o.score / top * 5))); });
        return out.slice(0, 7);
    }

    function searchWindows(q) {
        const list = ToplevelManager.toplevels.values;
        const out = [];
        for (let i = 0; i < list.length; i++) {
            const t = list[i];
            const title = t.title || t.appId || "";
            const m = Fuzzy.match(title, q);
            if (!m) continue;
            out.push({
                name: title,
                desc: t.appId,
                cat: "WIN",
                tile: (t.appId || title).charAt(0).toUpperCase(),
                idx: m.idx,
                score: m.score,
                rel: 0,
                run: () => t.activate()
            });
        }
        out.sort((a, b) => b.score - a.score);
        const top = out.length ? Math.max(0.001, out[0].score) : 1;
        out.forEach(o => { o.rel = Math.max(1, Math.min(5, Math.round(o.score / top * 5))); });
        return out.slice(0, 7);
    }

    readonly property var calc: mode === "calc" ? Calc.evaluate(term) : ({ ok: false, empty: true, error: "" })

    readonly property var results: {
        if (mode === "apps")
            return win.searchApps(term);
        if (mode === "win")
            return win.searchWindows(term);
        if (mode === "cmd") {
            if (term === "") return [];
            return [{
                name: "Run " + term, desc: "Shell command", cat: "CMD", tile: ">_",
                idx: [], rel: 0,
                run: () => Quickshell.execDetached(["sh", "-c", term])
            }];
        }
        // calc
        if (!calc.ok) return [];
        return [
            { name: "Copy result", desc: "", cat: "CALC", tile: "C", idx: [], rel: 0,
              run: () => Quickshell.execDetached(Config.copyCommand.concat([calc.text])) },
            { name: "Type into focused window", desc: "", cat: "CALC", tile: "T", idx: [], rel: 0,
              run: () => Quickshell.execDetached(Config.typeCommand.concat([calc.text])) }
        ];
    }

    readonly property var pins: (mode === "apps" && term === "") ? Apps.pinned(8) : []
    readonly property bool noMatch: mode === "apps" && term !== "" && results.length === 0

    function run(item) {
        LauncherState.hide();
        item.run();
    }

    function cycleMode(dir) {
        const i = (modes.indexOf(mode) + dir + modes.length) % modes.length;
        input.text = prefixes[modes[i]] + (modes[i] === "calc" ? "" : term);
        input.cursorPosition = input.text.length;
    }

    function setMode(name) {
        input.text = prefixes[name] + (name === "calc" ? "" : term);
        input.cursorPosition = input.text.length;
        input.forceActiveFocus();
    }

    // ── Click outside closes ──────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherState.hide()
    }

    Item {
        id: panel
        width: 640
        height: column.implicitHeight + 2
        x: Math.round((parent.width - width) / 2)
        y: Math.round(parent.height * 0.16)

        // Swallow clicks that land on the panel background.
        MouseArea { anchors.fill: parent }

        Chamfer { anchors.fill: parent; cut: 10; fillColor: Theme.steel }
        Chamfer { anchors.fill: parent; anchors.margins: 1; cut: 9; fillColor: Theme.panel }

        ColumnLayout {
            id: column
            x: 1
            y: 1
            width: parent.width - 2
            spacing: 0

            // ── Query ─────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 52

                Chamfer {
                    anchors.fill: parent
                    cutTL: 9
                    cutBR: 0
                    fillColor: Theme.bg
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12
                    spacing: 12

                    Glyph { path: Icons.search; size: 16 }

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.ivory
                        selectionColor: Theme.steel
                        selectedTextColor: Theme.ivory
                        font.family: Theme.mono
                        font.pixelSize: 15
                        clip: true
                        focus: true
                        cursorDelegate: Rectangle { width: 2; color: Theme.copper }
                        onTextChanged: win.sel = 0

                        Text {
                            visible: input.text === ""
                            text: "Search apps, > command, = math, @ window"
                            color: Theme.dust
                            font: input.font
                        }

                        Keys.onPressed: event => {
                            const n = win.results.length;
                            const ctrl = event.modifiers & Qt.ControlModifier;
                            if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) {
                                if (n > 0) win.sel = (win.sel + 1) % n;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) {
                                if (n > 0) win.sel = (win.sel + n - 1) % n;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab) {
                                win.cycleMode(1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Backtab) {
                                win.cycleMode(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (n > 0) win.run(win.results[Math.min(win.sel, n - 1)]);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                LauncherState.hide();
                                event.accepted = true;
                            } else if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_8) {
                                const p = win.pins[event.key - Qt.Key_1];
                                if (p) win.run({ run: () => Apps.launch(p) });
                                event.accepted = true;
                            }
                        }
                    }

                    Mono {
                        color: Theme.ash
                        text: win.mode === "apps" || win.mode === "win"
                            ? String(win.results.length).padStart(2, "0") + "/" + String(win.mode === "apps" ? Apps.entries.length : ToplevelManager.toplevels.values.length).padStart(2, "0")
                            : win.mode.toUpperCase()
                    }

                    Row {
                        spacing: 1
                        Repeater {
                            model: win.modes
                            ModeTab {
                                required property string modelData
                                label: win.tabNames[modelData]
                                active: win.mode === modelData
                                onClicked: win.setMode(modelData)
                            }
                        }
                    }
                }
            }

            // ── Calculator result ─────────────────────────
            SectionLabel {
                visible: win.mode === "calc"
                leftText: "Result"
                rightText: "Exact · base 10"
            }
            CalcView {
                visible: win.mode === "calc"
                Layout.bottomMargin: 10
                calc: win.calc
                expression: win.term
            }

            // ── Pinned (empty query) ──────────────────────
            SectionLabel {
                visible: win.pins.length > 0
                leftText: "Pinned"
                rightText: "Alt + 1–" + win.pins.length
            }
            GridLayout {
                visible: win.pins.length > 0
                Layout.fillWidth: true
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                Layout.bottomMargin: 6
                columns: 4
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: win.pins
                    PinTile {
                        required property var modelData
                        required property int index
                        number: index + 1
                        name: modelData.name
                        cat: win.catOf(modelData)
                        onActivated: win.run({ run: () => Apps.launch(modelData) })
                    }
                }
            }

            // ── Results ───────────────────────────────────
            SectionLabel {
                visible: win.mode !== "calc" && (win.results.length > 0 || win.noMatch)
                leftText: win.noMatch ? "No match"
                    : win.mode === "cmd" ? "Command"
                    : win.mode === "win" ? "Windows"
                    : win.term === "" ? "Recent" : "Matches"
                leftColor: win.noMatch ? Theme.rust : Theme.dust
                rightText: win.noMatch ? "Fallback" : win.mode === "apps" ? (win.term === "" ? "Use" : "Rel") : ""
                rightPad: win.noMatch ? 0 : 18
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 0

                Repeater {
                    model: win.results
                    ResultRow {
                        required property var modelData
                        required property int index
                        item: modelData
                        selected: index === Math.min(win.sel, win.results.length - 1)
                        onHovered: win.sel = index
                        onActivated: win.run(modelData)
                    }
                }

                // No app matched: offer the query as a command or a web search.
                ResultRow {
                    visible: win.noMatch
                    item: ({ name: "Run " + win.term + " as command", desc: "Not found in applications", cat: "CMD", tile: ">_", idx: [], rel: 0 })
                    selected: true
                    onActivated: win.run({ run: () => Quickshell.execDetached(["sh", "-c", win.term]) })
                }
            }

            // ── Keys ──────────────────────────────────────
            Item {
                Layout.fillWidth: true
                implicitHeight: 34

                Chamfer {
                    anchors.fill: parent
                    cutTL: 0
                    cutBR: 9
                    fillColor: Theme.bg
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.steel
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    Keycap { key: "↑↓"; label: "Select" }
                    Keycap { key: "Enter"; label: "Open" }
                    Keycap { key: "Tab"; label: "Mode" }
                    Keycap { key: "Esc"; label: "Close" }

                    Item { Layout.fillWidth: true }

                    Mono {
                        font.pixelSize: 10
                        color: win.mode === "calc" && win.calc.ok ? Theme.brass : Theme.dust
                        text: win.mode === "calc" ? (win.calc.ok ? win.calc.text : "")
                            : win.mode === "win" ? ToplevelManager.toplevels.values.length + " WINDOWS"
                            : win.mode === "cmd" ? "SH -C"
                            : Apps.entries.length + " APPS"
                    }
                }
            }
        }
    }
}
