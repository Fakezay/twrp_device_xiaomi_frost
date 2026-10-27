#!/system/bin/sh
# POCO C40 (JLQ JR510) TWRP Hardware Support Daemon
# Provides CPU Temp, Battery status & Persistent ADB / Sideload USB guardian

mkdir -p /tmp/battery 2>/dev/null
chmod 0777 /tmp/battery 2>/dev/null

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
        pkill -9 minadbd 2>/dev/null
        rm -f /sideload/exit 2>/dev/null
    fi

    # 4. USB Guardian: Keep ADB & Sideload always alive
    CONF=$(getprop sys.usb.config)
    CONTROLLER="30740000.usb"

    if [ "$CONF" = "sideload" ] || [ "$CONF" = "adb,sideload" ]; then
        # Sideload mode
        if [ ! -e "/config/usb_gadget/g1/configs/b.1/f1" ]; then
            rm -f /config/usb_gadget/g1/configs/b.1/f1 /config/usb_gadget/g1/configs/b.1/f2 2>/dev/null
            ln -sf /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
        fi
        CURRENT_UDC=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)
        if [ "$CURRENT_UDC" != "$CONTROLLER" ]; then
            echo "$CONTROLLER" > /config/usb_gadget/g1/UDC 2>/dev/null
        fi
        setprop sys.usb.state "$CONF"
    else
        # Normal recovery mode
        # If sys.usb.config was set to none, mtp, or mtp,adb, revert to adb
        if [ "$CONF" = "none" ] || [ "$CONF" = "mtp" ] || [ "$CONF" = "mtp,adb" ] || [ -z "$CONF" ]; then
            setprop sys.usb.config adb
            CONF="adb"
        fi

        # Ensure adbd process is running
        if ! pgrep adbd >/dev/null 2>&1; then
            start adbd 2>/dev/null
        fi

        # Ensure ffs.adb link is present
        if [ ! -e "/config/usb_gadget/g1/configs/b.1/f1" ]; then
            rm -f /config/usb_gadget/g1/configs/b.1/f1 /config/usb_gadget/g1/configs/b.1/f2 2>/dev/null
            ln -sf /config/usb_gadget/g1/functions/ffs.adb /config/usb_gadget/g1/configs/b.1/f1 2>/dev/null
        fi

        # Ensure UDC is bound to USB controller
        CURRENT_UDC=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)
        if [ "$CURRENT_UDC" != "$CONTROLLER" ]; then
            echo "$CONTROLLER" > /config/usb_gadget/g1/UDC 2>/dev/null
        fi

        STATE=$(getprop sys.usb.state)
        if [ "$STATE" != "adb" ]; then
            setprop sys.usb.state adb
        fi
    fi
}

# Run immediately once
update_metrics

if [ "$1" = "--once" ]; then
    exit 0
fi

# Loop in background every 1 second
while true; do
    sleep 1
    update_metrics
done
