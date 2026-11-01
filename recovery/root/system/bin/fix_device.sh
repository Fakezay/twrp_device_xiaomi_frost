#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Hardware Support Daemon
# Provides CPU Temp, Battery status & Persistent ADB / Sideload USB guardian

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
    stop adbd 2>/dev/null
    usleep 50000 2>/dev/null || sleep 0.05
    start adbd 2>/dev/null
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

    # 3. Sideload Cancel Guardian
    if [ -f "/sideload/exit" ]; then
        killall -9 minadbd 2>/dev/null
        pkill -9 -x minadbd 2>/dev/null
        rm -f /sideload/exit 2>/dev/null
    fi

    # 4. USB Guardian: Keep ADB & Sideload alive without interfering with transitions
    CONF=$(getprop sys.usb.config)
    STATE=$(getprop sys.usb.state)
    FFS_READY=$(getprop sys.usb.ffs.ready)
    CONTROLLER="30740000.usb"

    if [ "$CONF" = "sideload" ] || [ "$CONF" = "adb,sideload" ]; then
        # Sideload mode: once descriptors are loaded (FFS ready or ep1 created), bind UDC!
        if [ "$FFS_READY" = "1" ] || [ -e /dev/usb-ffs/adb/ep1 ]; then
            if [ ! -L "/config/usb_gadget/g1/configs/b.1/f1" ]; then
                ln -sf /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
            fi
            CURRENT_UDC=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)
            if [ "$CURRENT_UDC" != "$CONTROLLER" ]; then
                echo "$CONTROLLER" > /config/usb_gadget/g1/UDC 2>/dev/null
            fi
            if [ "$STATE" != "$CONF" ]; then
                setprop sys.usb.state "$CONF"
            fi
        fi
        return 0
    elif [ "$CONF" = "none" ]; then
        return 0
    else
        # Normal recovery mode
        # If sys.usb.config was set to mtp or mtp,adb, force to adb
        if [ "$CONF" = "mtp" ] || [ "$CONF" = "mtp,adb" ] || [ -z "$CONF" ]; then
            setprop sys.usb.config adb
            CONF="adb"
        fi

        if [ "$CONF" = "adb" ]; then
            # Ensure minadbd is not running in normal mode
            if pgrep -x minadbd >/dev/null 2>&1; then
                killall -9 minadbd 2>/dev/null
                pkill -9 -x minadbd 2>/dev/null
            fi

            # In normal mode, ensure adbd process is running
            if ! pgrep -x adbd >/dev/null 2>&1; then
                start adbd 2>/dev/null
            fi

            # Ensure ffs.adb link is present
            if [ ! -L "/config/usb_gadget/g1/configs/b.1/f1" ]; then
                ln -sf /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
            fi

            if [ "$STATE" != "adb" ]; then
                setprop sys.usb.state adb
            fi

            # Ensure UDC is bound to USB controller only when FFS is ready or ep1 exists
            if [ "$FFS_READY" = "1" ] || [ -e /dev/usb-ffs/adb/ep1 ]; then
                CURRENT_UDC=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)
                if [ "$CURRENT_UDC" != "$CONTROLLER" ]; then
                    echo "$CONTROLLER" > /config/usb_gadget/g1/UDC 2>/dev/null
                fi
            fi
        fi
    fi
}

# Run immediately once
update_metrics

# Loop in background every 1 second
while true; do
    sleep 1
    update_metrics
done
