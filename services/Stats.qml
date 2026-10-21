pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// CPU and memory utilisation from /proc, sampled once a second.
// The slower, heavier readings (frequency, temperature, disk, top processes) are only
// collected while the telemetry popup is open (`detail` = true).
Singleton {
    id: root

    // ── Always on ──────────────────────────────────────────
    property real cpu: 0                                  // 0..1
    property real mem: 0                                  // 0..1
    property var cpuHistory: new Array(60).fill(0)        // last 60 s, 0..1
    property var memHistory: new Array(60).fill(0)        // last 60 s, 0..1
    property var cores: []                                // per-thread load, 0..1

    property real prevTotal: 0
    property real prevIdle: 0
    property var prevCores: []

    // ── Popup details ──────────────────────────────────────
    property bool detail: false                           // set by the telemetry popup

    // Static, from /proc/cpuinfo
    property string cpuModel: ""
    property int threadCount: 0
    property int coreCount: 0

    // Memory, in KiB
    property real memTotal: 0
    property real memAvailable: 0
    property real memCached: 0
    property real swapTotal: 0
    property real swapFree: 0

    property real uptime: 0                               // seconds
    property var loadAvg: [0, 0, 0]

    property real freqMhz: 0                              // 0 when unknown
    property real tempC: -1                               // -1 when unknown
    property real diskUsed: 0                             // bytes
    property real diskTotal: 0
    property int procs: 0
    property var topProcs: []                             // { cpu, rss, name }

    function parseStat(t) {
        const lines = t.split("\n");

        const f = lines[0].trim().split(/\s+/).slice(1).map(Number);
        if (f.length < 5) return;
        const idle = f[3] + (f[4] || 0);
        const total = f.reduce((a, b) => a + b, 0);
        if (prevTotal > 0) {
            const dt = total - prevTotal;
            const di = idle - prevIdle;
            cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
            cpuHistory = cpuHistory.slice(1).concat([cpu]);
        }
        prevTotal = total;
        prevIdle = idle;

        // Per-thread lines: cpu0, cpu1, ...
        const nextPrev = [];
        const load = [];
        for (let i = 1; i < lines.length && lines[i].startsWith("cpu"); i++) {
            const c = lines[i].trim().split(/\s+/).slice(1).map(Number);
            const ci = c[3] + (c[4] || 0);
            const ct = c.reduce((a, b) => a + b, 0);
            const p = prevCores[i - 1];
            let v = 0;
            if (p && ct > p.total)
                v = Math.max(0, Math.min(1, 1 - (ci - p.idle) / (ct - p.total)));
            load.push(v);
            nextPrev.push({ total: ct, idle: ci });
        }
        prevCores = nextPrev;
        cores = load;
    }

    function kib(t, key) {
        const m = new RegExp(key + ":\\s+(\\d+)").exec(t);
        return m ? Number(m[1]) : 0;
    }

    function parseMem(t) {
        memTotal = kib(t, "MemTotal");
        memAvailable = kib(t, "MemAvailable");
        memCached = kib(t, "Cached") + kib(t, "SReclaimable");
        swapTotal = kib(t, "SwapTotal");
        swapFree = kib(t, "SwapFree");
        if (memTotal > 0) {
            mem = 1 - memAvailable / memTotal;
            memHistory = memHistory.slice(1).concat([mem]);
        }
    }

    // "AMD Ryzen 7 5800X 8-Core Processor" -> "AMD Ryzen 7 5800X"
    function cleanModel(s) {
        return s.replace(/\((R|TM|tm|r)\)/g, "")
                .replace(/\s+@\s+[\d.]+\s*GHz/i, "")
                .replace(/\s+\d+-Core Processor/i, "")
                .replace(/\s+(CPU|Processor)\b/gi, "")
                .replace(/\s+/g, " ")
                .trim();
    }

    function parseCpuInfo(t) {
        const model = /model name\s*:\s*(.+)/.exec(t);
        if (model) cpuModel = cleanModel(model[1]);
        const threads = (t.match(/^processor\s*:/gm) || []).length;
        threadCount = threads;

        // "cpu cores" is per package; multiply by the number of packages.
        const per = /cpu cores\s*:\s*(\d+)/.exec(t);
        const pkgs = new Set((t.match(/physical id\s*:\s*\d+/g) || []));
        coreCount = per ? Number(per[1]) * Math.max(1, pkgs.size) : threads;
    }

    function parseInfo(t) {
        const top = [];
        t.split("\n").forEach(line => {
            const eq = line.indexOf("=");
            if (eq < 0) return;
            const k = line.slice(0, eq);
            const v = line.slice(eq + 1).trim();
            if (k === "freq") freqMhz = Number(v);
            else if (k === "temp") tempC = Number(v);
            else if (k === "procs") procs = Number(v);
            else if (k === "disk") {
                const p = v.split(" ");
                diskUsed = Number(p[0]);
                diskTotal = Number(p[1]);
            } else if (k === "top") {
                const p = v.split("|");
                top.push({ cpu: Number(p[0]), rss: Number(p[1]), name: p.slice(2).join("|") });
            }
        });
        topProcs = top;
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.parseStat(text())
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.parseMem(text())
    }

    FileView {
        id: cpuinfo
        path: "/proc/cpuinfo"
        onLoaded: root.parseCpuInfo(text())
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptime = Number(text().split(" ")[0])
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        onLoaded: root.loadAvg = text().trim().split(/\s+/).slice(0, 3).map(Number)
    }

    Process {
        id: info
        command: ["sh", Quickshell.shellPath("scripts/sysinfo.sh")]
        stdout: StdioCollector {
            onStreamFinished: root.parseInfo(text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            if (root.detail) {
                uptimeFile.reload();
                loadFile.reload();
            }
        }
    }

    // top takes about a second per run, so poll gently.
    Timer {
        interval: 3000
        running: root.detail
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!info.running) info.running = true
    }
}
