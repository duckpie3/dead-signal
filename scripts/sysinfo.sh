#!/bin/sh
# Prints key=value lines for the telemetry popup:
#   freq=<average MHz>   temp=<deg C>   disk=<used bytes> <total bytes>   procs=<count>
#   top=<cpu %>|<rss KiB>|<name>      (three lines, busiest first)

# Average current frequency of all cores, in MHz.
cat /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq 2>/dev/null |
    awk '{ s += $1; n++ } END { if (n) printf "freq=%d\n", s / n / 1000 }'

# CPU temperature: first hwmon device that looks like a CPU sensor.
for h in /sys/class/hwmon/hwmon*; do
    case "$(cat "$h/name" 2>/dev/null)" in
        k10temp|coretemp|zenpower|cpu_thermal|acpitz)
            if [ -r "$h/temp1_input" ]; then
                awk '{ printf "temp=%d\n", $1 / 1000 }' "$h/temp1_input"
                break
            fi ;;
    esac
done

# Root filesystem.
df -B1 --output=used,size / 2>/dev/null | awk 'NR == 2 { printf "disk=%s %s\n", $1, $2 }'

# Process count.
ls -d /proc/[0-9]* 2>/dev/null | wc -l | awk '{ printf "procs=%d\n", $1 }'

# Busiest processes right now: the second top iteration is a real 1 s sample.
top -b -n 2 -d 1 -w 512 -o %CPU 2>/dev/null | awk '
    /^top - /      { block++; rows = 0; body = 0; next }
    block == 2 && /^ *PID/ { body = 1; next }
    block == 2 && body && rows < 3 { print $1 "|" $9; rows++ }
' | while IFS='|' read -r pid cpu; do
    rss=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ')
    name=$(ps -o comm= -p "$pid" 2>/dev/null)
    [ -n "$name" ] && printf 'top=%s|%s|%s\n' "$cpu" "${rss:-0}" "$name"
done
