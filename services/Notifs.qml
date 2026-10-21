pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import qs.theme

// Notification daemon. Every notification is kept (tracked) until the user dismisses it;
// toasts are just the recent ones still counting down.
// Only one notification daemon can run at a time: stop dunst / mako first.
Singleton {
    id: root

    property var records: []              // NotifRecord, newest first
    property bool dnd: false              // do not disturb: only critical ones pop up
    property real tick: Date.now()        // refreshed every 20 s so relative times update

    readonly property int total: records.length
    readonly property int unread: records.filter(r => !r.read).length
    readonly property int held: records.filter(r => !r.read && !r.toast).length
    readonly property var toasts: records.filter(r => r.toast).slice(0, 4)

    function categoryOf(rec) {
        const name = ((rec.n.appName || "") + " " + (rec.n.desktopEntry || "")).toLowerCase();
        for (let i = 0; i < Config.messageApps.length; i++)
            if (name.indexOf(Config.messageApps[i]) >= 0) return "MSG";
        return "SYS";
    }

    // "now", "14m", "3h", "2d"
    function ago(t) {
        const s = Math.max(0, (root.tick - t) / 1000);
        if (s < 45) return "now";
        if (s < 3600) return Math.round(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    function plain(s) { return (s || "").replace(/<[^>]*>/g, ""); }

    function receive(n) {
        n.tracked = true;

        // A replacement carries the same id: keep one entry.
        records.filter(r => r.n !== n && r.n.id === n.id).forEach(r => root.drop(r));

        let rec = records.find(r => r.n === n);
        if (!rec) {
            rec = recipe.createObject(root, { n: n });
            rec.gone.connect(() => root.drop(rec));
        }
        rec.time = Date.now();
        rec.read = false;
        rec.toast = !root.dnd || rec.critical;
        rec.duration = rec.critical ? 0 : (n.expireTimeout > 0 ? n.expireTimeout * 1000 : Config.toastSeconds * 1000);
        rec.remaining = rec.duration;
        root.records = [rec].concat(root.records.filter(r => r !== rec));
    }

    function drop(rec) {
        if (!root.records.includes(rec)) return;
        root.records = root.records.filter(r => r !== rec);
        rec.destroy();
    }

    function dismiss(rec) { rec.n.dismiss(); root.drop(rec); }
    function dismissApp(app) { records.filter(r => r.n.appName === app).forEach(r => root.dismiss(r)); }
    function clearAll() { records.slice().forEach(r => root.dismiss(r)); }
    function markAllRead() { records.forEach(r => { r.read = true; }); }

    Component {
        id: recipe
        NotifRecord {}
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: false
        imageSupported: false
        persistenceSupported: true
        onNotification: n => root.receive(n)
    }

    // After a config reload the server still holds the old ones: show them as read history.
    Component.onCompleted: {
        const old = server.trackedNotifications.values;
        for (let i = old.length - 1; i >= 0; i--) {
            const rec = recipe.createObject(root, { n: old[i] });
            rec.gone.connect(() => root.drop(rec));
            rec.read = true;
            root.records = [rec].concat(root.records);
        }
    }

    // Toast countdown. Hovering a toast pauses it.
    Timer {
        interval: 100
        repeat: true
        running: root.toasts.length > 0
        onTriggered: root.records.forEach(r => {
            if (!r.toast || r.duration <= 0 || r.paused) return;
            r.remaining -= 100;
            if (r.remaining <= 0) r.toast = false;
        })
    }

    Timer {
        interval: 20000
        repeat: true
        running: true
        onTriggered: root.tick = Date.now()
    }
}
