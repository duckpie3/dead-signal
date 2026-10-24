pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import qs.theme

// MPRIS media players. `current` is the player the bar and popup show: the one you picked in the
// popup if it still exists, otherwise the first one that is playing, otherwise the first one.
Singleton {
    id: root

    // Players worth showing: not ignored, and either playing or holding a track.
    readonly property var players: Mpris.players.values.filter(p => {
        const id = ((p.dbusName || "") + " " + (p.identity || "")).toLowerCase();
        if (Config.mediaIgnore.some(x => id.indexOf(x) >= 0)) return false;
        return p.isPlaying || (p.trackTitle || "") !== "";
    })
    readonly property bool present: players.length > 0

    property string pinned: ""             // D-Bus name picked in the popup
    readonly property var current: {
        const ps = root.players;
        if (ps.length === 0) return null;
        const pin = ps.find(p => p.dbusName === root.pinned);
        if (pin) return pin;
        return ps.find(p => p.isPlaying) ?? ps[0];
    }
    function pick(p) { root.pinned = p ? p.dbusName : "" }

    readonly property bool has: current !== null
    readonly property bool playing: has && current.isPlaying
    readonly property string title: has ? (current.trackTitle || current.identity || "") : ""
    readonly property string artist: has ? (current.trackArtist || "") : ""
    readonly property string album: has ? (current.trackAlbum || "") : ""
    readonly property string art: has ? (current.trackArtUrl || "") : ""
    readonly property string player: has ? (current.identity || "") : ""

    // Seconds. `len` is 0 when the player does not know (streams).
    readonly property real pos: has && current.positionSupported ? current.position : 0
    readonly property real len: has && current.lengthSupported && current.length > 0 ? current.length : 0
    readonly property real pct: len > 0 ? Math.max(0, Math.min(1, pos / len)) : 0
    readonly property bool canSeek: has && current.canSeek && len > 0

    readonly property bool canPrev: has && current.canGoPrevious
    readonly property bool canNext: has && current.canGoNext
    readonly property bool canToggle: has && current.canTogglePlaying
    readonly property bool canRaise: has && current.canRaise
    readonly property bool shuffleSupported: has && current.shuffleSupported
    readonly property bool shuffle: shuffleSupported && current.shuffle
    readonly property bool repeatSupported: has && current.loopSupported
    readonly property string repeat: !repeatSupported ? "off"
        : current.loopState === MprisLoopState.Playlist ? "all"
        : current.loopState === MprisLoopState.Track ? "one" : "off"

    function toggle()  { if (canToggle) current.togglePlaying() }
    function next()    { if (canNext) current.next() }
    function prev()    { if (canPrev) current.previous() }
    function raise()   { if (canRaise) current.raise() }
    function seek(s)   { if (canSeek) current.position = Math.max(0, Math.min(len, s)) }
    function toggleShuffle() { if (shuffleSupported) current.shuffle = !current.shuffle }
    function cycleRepeat() {
        if (!repeatSupported) return;
        current.loopState = repeat === "off" ? MprisLoopState.Playlist
            : repeat === "all" ? MprisLoopState.Track : MprisLoopState.None;
    }

    function fmt(s) {
        s = Math.max(0, Math.round(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // MPRIS positions are not pushed, so ask for a fresh one every second while playing.
    Timer {
        interval: 1000
        repeat: true
        running: root.playing && root.current.positionSupported
        onTriggered: root.current.positionChanged()
    }
    onCurrentChanged: if (has && current.positionSupported) current.positionChanged()
}
