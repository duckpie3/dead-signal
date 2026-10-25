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
//   (none) apps   >  command   =  calculator   @  windows   #  clipboard   :  emoji
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
    readonly property var modes: ["apps", "cmd", "calc", "win", "clip", "emoji"]
    readonly property var prefixes: ({ apps: "", cmd: "> ", calc: "= ", win: "@ ", clip: "# ", emoji: ": " })
    readonly property var tabNames: ({ apps: "Apps", cmd: "Cmd", calc: "Calc", win: "Win", clip: "Clip", emoji: "Emoji" })

    readonly property string raw: input.text
    readonly property string mode: raw.startsWith(">") ? "cmd" : raw.startsWith("=") ? "calc" : raw.startsWith("@") ? "win"
        : raw.startsWith("#") ? "clip" : raw.startsWith(":") ? "emoji" : "apps"
    readonly property string term: (mode === "apps" ? raw : raw.slice(1)).trim()
    property int sel: 0
    property string emojiCat: "smileys"
    property string flashText: ""

    function flash(t) { win.flashText = t; flashTimer.restart() }
    Timer { id: flashTimer; interval: 1600; onTriggered: win.flashText = "" }

    onShownChanged: {
        if (shown) {
            input.text = LauncherState.initialQuery;
            win.sel = 0;
            win.emojiCat = LauncherStore.recent.length > 0 ? "recent" : "smileys";
            Clip.refresh();
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
        if (mode === "clip")
            return Clip.available ? Clip.search(term) : [];
        if (mode === "emoji")
            return Emoji.list(win.emojiCat, term);
        // calc
        if (!calc.ok) return [];
        return [
            { name: "Copy result", desc: "", cat: "CALC", tile: "C", idx: [], rel: 0,
              run: () => Quickshell.execDetached(Config.copyCommand.concat([calc.text])) },
            { name: "Type into focused window", desc: "", cat: "CALC", tile: "T", idx: [], rel: 0,
              run: () => Quickshell.execDetached(Config.typeCommand.concat([calc.text])) }
        ];
    }

    readonly property int selIdx: Math.min(sel, Math.max(0, results.length - 1))

    // Clipboard: six rows at a time, with a section heading where Pinned turns into Recent.
    readonly property int clipStart: Math.max(0, Math.min(selIdx - 5, results.length - 6))
    readonly property var clipRows: {
        if (mode !== "clip") return [];
        const out = [];
        const end = Math.min(results.length, clipStart + 6);
        const grp = e => term !== "" ? "Matches" : (e.pinned ? "Pinned" : "Recent");
        for (let i = clipStart; i < end; i++) {
            const g = grp(results[i]);
            out.push({ e: results[i], i: i, head: g, showHead: i === clipStart || g !== grp(results[i - 1]) });
        }
        return out;
    }
    readonly property var curClip: mode === "clip" && results.length > 0 ? results[selIdx] : null
    onCurClipChanged: if (curClip) Clip.want(curClip)
    readonly property var emptyClip: ({ id: "", kind: "TEXT", preview: "", text: "", pinned: false, ts: 0, size: "", w: 0, h: 0 })

    readonly property var pins: (mode === "apps" && term === "") ? Apps.pinned(8) : []
    readonly property bool noMatch: mode === "apps" && term !== "" && results.length === 0

    function run(item) {
        LauncherState.hide();
        item.run();
    }

    // Enter. Shift+Enter in clipboard mode only copies.
    function activate(item, alt) {
        if (!item) return;
        if (mode === "clip") { LauncherState.hide(); Clip.paste(item, alt); return; }
        if (mode === "emoji") { LauncherState.hide(); Emoji.insert(item); return; }
        win.run(item);
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
                            text: "Search apps, > command, = math, @ window, # clipboard, : emoji"
                            color: Theme.dust
                            font: input.font
                        }

                        Keys.onPressed: event => {
                            const n = win.results.length;
                            const ctrl = event.modifiers & Qt.ControlModifier;
                            const shift = event.modifiers & Qt.ShiftModifier;
                            if (win.mode === "emoji" && !ctrl) {
                                const step = event.key === Qt.Key_Right ? 1 : event.key === Qt.Key_Left ? -1
                                    : event.key === Qt.Key_Down ? 12 : event.key === Qt.Key_Up ? -12 : 0;
                                if (step !== 0) {
                                    if (n > 0) win.sel = Math.max(0, Math.min(n - 1, win.selIdx + step));
                                    event.accepted = true;
                                    return;
                                }
                            }
                            if (win.mode === "clip" && ctrl && (event.key === Qt.Key_P || event.key === Qt.Key_D)) {
                                const cur = n > 0 ? win.results[win.selIdx] : null;
                                if (cur && event.key === Qt.Key_P) win.flash(Clip.togglePin(cur) ? (cur.pinned ? "UNPINNED" : "PINNED") : "TEXT ONLY");
                                else if (cur) { Clip.remove(cur); win.flash("REMOVED"); }
                                event.accepted = true;
                                return;
                            }
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
                                if (n > 0) win.activate(win.results[Math.min(win.sel, n - 1)], shift);
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
                        text: win.mode === "apps" || win.mode === "win" || win.mode === "clip"
                            ? String(win.results.length).padStart(2, "0") + "/" + String(win.mode === "apps" ? Apps.entries.length
                                : win.mode === "clip" ? Clip.entries.length + LauncherStore.pins.length
                                : ToplevelManager.toplevels.values.length).padStart(2, "0")
                            : win.mode === "emoji" ? String(win.results.length).padStart(2, "0")
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
                visible: win.mode !== "calc" && win.mode !== "clip" && win.mode !== "emoji" && (win.results.length > 0 || win.noMatch)
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
                    model: win.mode === "clip" || win.mode === "emoji" ? [] : win.results
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

            // ── Clipboard ─────────────────────────────────
            ColumnLayout {
                visible: win.mode === "clip"
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 0

                Repeater {
                    model: 6
                    ColumnLayout {
                        id: clipSlot
                        required property int index
                        readonly property var row: win.clipRows[index]
                        visible: row !== undefined
                        Layout.fillWidth: true
                        spacing: 0

                        SectionLabel {
                            visible: clipSlot.row !== undefined && clipSlot.row.showHead
                            leftText: clipSlot.row ? clipSlot.row.head : ""
                            rightText: "Age"
                            rightPad: 18
                        }
                        ClipRow {
                            entry: clipSlot.row ? clipSlot.row.e : win.emptyClip
                            query: win.term
                            selected: clipSlot.row !== undefined && clipSlot.row.i === win.selIdx
                            onHovered: if (clipSlot.row) win.sel = clipSlot.row.i
                            onActivated: if (clipSlot.row) win.activate(clipSlot.row.e, false)
                        }
                    }
                }

                RowLayout {
                    visible: win.results.length === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    Item { Layout.fillWidth: true }
                    Mono {
                        text: !Clip.available ? "MISSING" : Clip.entries.length + LauncherStore.pins.length === 0 ? "EMPTY" : "NO MATCH"
                        color: Theme.rust
                    }
                    Txt {
                        text: !Clip.available ? "needs cliphist and wl-clipboard"
                            : Clip.entries.length + LauncherStore.pins.length === 0 ? "copy something and it will show up here"
                            : "nothing in history contains “" + win.term + "”"
                        color: Theme.dust
                    }
                    Item { Layout.fillWidth: true }
                }

                ClipPreview {
                    visible: win.results.length > 0
                    Layout.topMargin: 6
                    entry: win.curClip || win.emptyClip
                }
            }

            // ── Emoji ─────────────────────────────────────
            EmojiPane {
                visible: win.mode === "emoji"
                items: win.mode === "emoji" ? win.results : []
                sel: win.selIdx
                cat: win.emojiCat
                query: win.term
                onHovered: i => win.sel = i
                onActivated: i => win.activate(win.results[i], false)
                onCatPicked: id => {
                    win.emojiCat = id;
                    input.text = win.prefixes.emoji;
                    input.cursorPosition = input.text.length;
                    win.sel = 0;
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

                    Keycap { key: win.mode === "emoji" ? "↑↓←→" : "↑↓"; label: "Select" }
                    Keycap { key: "Enter"; label: win.mode === "clip" ? "Paste" : win.mode === "emoji" ? "Insert" : "Open" }
                    Keycap { visible: win.mode === "clip"; key: "Ctrl P"; label: "Pin" }
                    Keycap { visible: win.mode === "clip"; key: "Ctrl D"; label: "Remove" }
                    Keycap { visible: win.mode !== "clip"; key: "Tab"; label: "Mode" }
                    Keycap { key: "Esc"; label: "Close" }

                    Item { Layout.fillWidth: true }

                    Mono {
                        font.pixelSize: 10
                        color: win.flashText !== "" ? Theme.sage : win.mode === "calc" && win.calc.ok ? Theme.brass : Theme.dust
                        text: win.flashText !== "" ? win.flashText
                            : win.mode === "clip" ? (Clip.entries.length + LauncherStore.pins.length) + " ENTRIES"
                            : win.mode === "emoji" ? Emoji.all.length + " EMOJI"
                            : win.mode === "calc" ? (win.calc.ok ? win.calc.text : "")
                            : win.mode === "win" ? ToplevelManager.toplevels.values.length + " WINDOWS"
                            : win.mode === "cmd" ? "SH -C"
                            : Apps.entries.length + " APPS"
                    }
                }
            }
        }
    }
}
