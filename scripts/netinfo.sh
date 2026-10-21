#!/bin/sh
# Prints key=value lines describing the primary network connection.
# Used by services/Net.qml. Requires NetworkManager (nmcli).

command -v nmcli >/dev/null 2>&1 || { echo "state=offline"; exit 0; }

line=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null \
    | awk -F: '$3 == "connected" && ($2 == "wifi" || $2 == "ethernet") { print; exit }')

[ -z "$line" ] && { echo "state=offline"; exit 0; }

iface=${line%%:*}
rest=${line#*:}
type=${rest%%:*}
rest=${rest#*:}      # STATE:CONNECTION
conn=${rest#*:}

echo "state=connected"
echo "iface=$iface"
echo "type=$type"
echo "ip=$(nmcli -g IP4.ADDRESS device show "$iface" 2>/dev/null | head -n1 | cut -d/ -f1)"

if [ "$type" = "wifi" ]; then
    # IN-USE:SIGNAL:FREQ:SECURITY:SSID  (SSID last, because it may contain escaped colons)
    l=$(nmcli -t -f IN-USE,SIGNAL,FREQ,SECURITY,SSID device wifi list ifname "$iface" 2>/dev/null \
        | grep '^\*:' | head -n1)
    l=${l#*:}
    sig=${l%%:*}; l=${l#*:}
    freq=${l%%:*}; l=${l#*:}
    sec=${l%%:*}; ssid=${l#*:}
    ssid=$(printf '%s' "$ssid" | sed 's/\\:/:/g')
    echo "signal=$sig"
    echo "freq=${freq%% *}"
    echo "security=$sec"
    echo "name=${ssid:-$conn}"
else
    echo "name=$conn"
fi
