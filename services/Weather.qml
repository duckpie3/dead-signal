pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.theme

// Forecast from Open-Meteo, refreshed every 20 minutes. Shown in the calendar popup.
Singleton {
    id: root

    readonly property bool enabled: Config.weatherEnabled
    property var data: null
    property bool failed: false

    readonly property bool ok: data !== null
    readonly property var cur: data ? data.current : null
    readonly property bool fahrenheit: Config.weatherUnit === "fahrenheit"
    readonly property string unitLabel: fahrenheit ? "°F" : "°C"
    readonly property string windLabel: fahrenheit ? "mph" : "km/h"

    readonly property real temp: cur ? cur.temperature_2m : 0
    readonly property real feels: cur ? cur.apparent_temperature : 0
    readonly property real humidity: cur ? cur.relative_humidity_2m : 0
    readonly property real wind: cur ? cur.wind_speed_10m : 0
    readonly property bool isDay: cur ? cur.is_day === 1 : true
    readonly property int code: cur ? cur.weather_code : 0

    // WMO weather code → icon kind
    function kindOf(c) {
        if (c === 0) return "clear";
        if (c <= 2) return "partly";
        if (c === 3 || c === 45 || c === 48) return "cloudy";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow";
        if (c >= 95) return "storm";
        return "rain";
    }

    function describe(c) {
        if (c === 0) return "Clear";
        if (c === 1) return "Mostly clear";
        if (c === 2) return "Partly cloudy";
        if (c === 3) return "Overcast";
        if (c === 45 || c === 48) return "Fog";
        if (c >= 51 && c <= 57) return "Drizzle";
        if (c >= 61 && c <= 67) return "Rain";
        if (c >= 71 && c <= 77) return "Snow";
        if (c >= 80 && c <= 82) return "Showers";
        if (c === 85 || c === 86) return "Snow showers";
        if (c >= 95) return "Thunderstorm";
        return "Unknown";
    }

    // The next 12 hours, starting with the current one.
    readonly property var hours: {
        if (!data) return [];
        const h = data.hourly;
        const now = data.current.time.slice(0, 13);
        let i = h.time.findIndex(s => s.slice(0, 13) >= now);
        if (i < 0) i = 0;
        const out = [];
        for (let k = 0; k < 12 && i + k < h.time.length; k++) {
            out.push({
                temp: h.temperature_2m[i + k],
                rain: h.precipitation_probability[i + k] || 0,
                hour: Number(h.time[i + k].slice(11, 13)),
                first: k === 0
            });
        }
        return out;
    }

    readonly property real hoursMin: hours.length ? Math.min.apply(null, hours.map(h => h.temp)) : 0
    readonly property real hoursMax: hours.length ? Math.max.apply(null, hours.map(h => h.temp)) : 0

    // The three days after today.
    readonly property var days: {
        if (!data) return [];
        const d = data.daily;
        const out = [];
        for (let i = 1; i <= 3 && i < d.time.length; i++) {
            out.push({
                name: Qt.formatDate(new Date(d.time[i] + "T12:00:00"), "ddd"),
                code: d.weather_code[i],
                hi: Math.round(d.temperature_2m_max[i]),
                lo: Math.round(d.temperature_2m_min[i])
            });
        }
        return out;
    }

    function refresh() {
        if (root.enabled && !fetch.running) fetch.running = true;
    }

    Process {
        id: fetch
        command: ["sh", Quickshell.shellPath("scripts/weather.sh"),
                  String(Config.weatherLat), String(Config.weatherLon), Config.weatherUnit]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(this.text);
                    if (d && d.current) {
                        root.data = d;
                        root.failed = false;
                        return;
                    }
                } catch (e) {}
                root.failed = root.data === null;
            }
        }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
