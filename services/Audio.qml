pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// PipeWire default sink (output) and source (input).
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool hasSink: sink !== null && sink !== undefined && sink.audio !== null
    readonly property bool hasSource: source !== null && source !== undefined && source.audio !== null

    // 1.0 = 100 %. PipeWire allows boosting above that.
    readonly property real maxVolume: 1.5
    readonly property real volume: hasSink ? sink.audio.volume : 0
    readonly property bool muted: hasSink ? sink.audio.muted : true
    readonly property real micVolume: hasSource ? source.audio.volume : 0
    readonly property bool micMuted: hasSource ? source.audio.muted : true

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    function clamp(v, hi) { return Math.max(0, Math.min(hi, v)) }

    function setVolume(v)   { if (hasSink)   sink.audio.volume = clamp(v, maxVolume) }
    function step(d)        { setVolume(volume + d) }
    function toggleMute()   { if (hasSink)   sink.audio.muted = !sink.audio.muted }
    function setMic(v)      { if (hasSource) source.audio.volume = clamp(v, 1.0) }
    function toggleMic()    { if (hasSource) source.audio.muted = !source.audio.muted }
    function select(node)   { Pipewire.preferredDefaultAudioSink = node }

    function label(node) {
        if (!node) return "";
        return node.description || node.nickname || node.name;
    }

    // Short connection tag for a sink, guessed from its node name.
    function kind(node) {
        const n = (node && node.name ? node.name : "").toLowerCase();
        if (n.indexOf("hdmi") >= 0 || n.indexOf("displayport") >= 0) return "HDMI";
        if (n.indexOf("bluez") >= 0) return "BT";
        if (n.indexOf("usb") >= 0) return "USB";
        if (n.indexOf("analog") >= 0) return "ANALOG";
        return "";
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(o => o !== null && o !== undefined)
    }

    PwObjectTracker {
        objects: root.sinks
    }
}
