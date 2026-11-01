#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Hardware Support Daemon
# Provides CPU Temp and Battery status without interfering with USB / Sideload

mkdir -p /tmp/battery 2>/dev/null
chmod 0777 /tmp/battery 2>/dev/null
mkdir -p /sideload 2>/dev/null
chmod 0777 /sideload 2>/dev/null
chmod 0666 /dev/fuse 2>/dev/null

# Force ADB authorization disabled on post-fs so TWRP ADB never shows "unauthorized"
if [ "$1" = "--once" ]; then
    if [ -x /system/bin/resetprop ]; then
        /system/bin/resetprop -n ro.adb.secure 0
        /system/bin/resetprop -n ro.debuggable 1
        /system/bin/resetprop -n ro.secure 0
    fi
    touch /adb_keys 2>/dev/null
    chmod 0644 /adb_keys 2>/dev/null
    exit 0
fi

update_metrics() {
    # 1. Update CPU Temperature
    MAX_TEMP=0
    for tz in /sys/class/thermal/thermal_zone*; do
        if [ -f "$tz/temp" ]; then
            T=$(cat "$tz/temp" 2>/dev/null || echo 0)
            if [ -n "$T" ] && [ "$T" -gt 1000 ] && [ "$T" -lt 120000 ]; then
                if [ "$T" -gt "$MAX_TEMP" ]; then
                    MAX_TEMP="$T"
                fi
            fi
        fi
    done
    if [ "$MAX_TEMP" -gt 0 ]; then
        echo "$MAX_TEMP" > /tmp/cputemp.tmp
        mv -f /tmp/cputemp.tmp /tmp/cputemp 2>/dev/null
        chmod 0666 /tmp/cputemp 2>/dev/null
    fi

    # 2. Update Battery Capacity & Status
    for b in /sys/class/power_supply/jcmbattery /sys/class/power_supply/battery /sys/class/power_supply/*; do
        if [ -f "$b/capacity" ]; then
            CAP=$(cat "$b/capacity" 2>/dev/null)
            STAT=$(cat "$b/status" 2>/dev/null || echo "Discharging")
            if [ -n "$CAP" ]; then
                echo "$CAP" > /tmp/battery/capacity.tmp
                mv -f /tmp/battery/capacity.tmp /tmp/battery/capacity 2>/dev/null
                echo "$STAT" > /tmp/battery/status.tmp
                mv -f /tmp/battery/status.tmp /tmp/battery/status 2>/dev/null
                chmod 0666 /tmp/battery/* 2>/dev/null
                break
            fi
        fi
    done
}

# Run immediately once
update_metrics

# Loop in background every 2 seconds
while true; do
    sleep 2
    update_metrics
done
